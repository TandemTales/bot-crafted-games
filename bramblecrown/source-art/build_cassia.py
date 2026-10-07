"""Cassia / Grovewalker: authored surface-model rebuild, Blender 5.1.
Run blender -b -P source-art/build_cassia.py. No other character is touched.
The .blend retains named construction meshes and packed PBR maps; runtime is joined.
"""
import bpy, bmesh, math, json, tempfile, sys
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi, exp, sqrt
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
TEX=ROOT/'source-art/cassia-textures'
EV=ROOT/'evidence/2026-10-07-cassia-rebuild'
EV.mkdir(exist_ok=True)
(EV/'export-temp').mkdir(exist_ok=True)
tempfile.tempdir=str(EV/'export-temp')
bpy.ops.wm.read_factory_settings(use_empty=True)
MODEL=bpy.data.collections.new('CASSIA • authored construction')
bpy.context.scene.collection.children.link(MODEL)

def mat(name,color,rough=.65,metal=0,texture=None,emit=0):
    m=bpy.data.materials.new(name); m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value=(*color,1)
    b.inputs['Roughness'].default_value=rough
    b.inputs['Metallic'].default_value=metal
    if emit:
        b.inputs['Emission Color'].default_value=(*color,1)
        b.inputs['Emission Strength'].default_value=emit
    if texture:
        for suffix,slot in [('albedo','Base Color'),('roughness','Roughness'),('normal','Normal')]:
            node=m.node_tree.nodes.new('ShaderNodeTexImage')
            node.image=bpy.data.images.load(str(TEX/(texture+'_'+suffix+'.png')),check_existing=True)
            node.image.pack()
            node.label=texture+' '+suffix
            if suffix!='albedo': node.image.colorspace_settings.name='Non-Color'
            if suffix=='normal':
                norm=m.node_tree.nodes.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.55
                m.node_tree.links.new(node.outputs['Color'],norm.inputs['Color'])
                m.node_tree.links.new(norm.outputs['Normal'],b.inputs['Normal'])
            else: m.node_tree.links.new(node.outputs['Color'],b.inputs[slot])
        b.inputs['Base Color'].default_value=(1,1,1,1)
    return m
forest=mat('Cassia | charcoal woven coat',(1,1,1),texture='forest')
sage=mat('Cassia | ember brocade',(1,1,1),texture='sage')
linen=mat('Cassia | ash linen',(1,1,1),texture='linen')
leather=mat('Cassia | smoke-dark leather',(1,1,1),texture='leather')
bark=mat('Cassia | blackened ash haft',(1,1,1),texture='bark')
skin=mat('Cassia | skin - painted face UV',(1,1,1),texture='skin')
skin.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.075
lip=mat('Cassia | lips and inner ear',(.30,.105,.075),.55)
dark=mat('Cassia | shadow seams',(.027,.018,.012),.8)
hair=mat('Cassia | swept copper hair',(1,1,1),texture='hair')
hairlight=mat('Cassia | hair ridges',(.47,.17,.035),.65)
brow=mat('Cassia | eyebrows',(.16,.05,.018),.8)
gold=mat('Cassia | aged brass',(.46,.30,.10),.43,.65)
thread=mat('Cassia | ochre embroidery',(.58,.42,.16),.82)
white=mat('Cassia | ivory sclera',(.65,.62,.48),.28)
iris=mat('Cassia | amber iris',(.32,.16,.035),.3)
seed=mat('Cassia | crown seed',(.65,.88,.26),.27,.05,emit=.6)

def mesh(name,vs,fs,material,uv=None,sub=0,solid=0):
    me=bpy.data.meshes.new(name); me.from_pydata(vs,[],fs); me.update()
    o=bpy.data.objects.new(name,me);MODEL.objects.link(o)
    me.materials.append(material)
    for p in me.polygons:p.use_smooth=True
    if uv:
        layer=me.uv_layers.new(name='Authored UV')
        for loop in me.loops: layer.data[loop.index].uv=uv[loop.vertex_index]
    else:
        active(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free()
    if sub:
        mod=o.modifiers.new('Tailored surface refinement','SUBSURF');mod.levels=sub;mod.render_levels=sub
    if solid:
        mod=o.modifiers.new('Real fabric thickness','SOLIDIFY');mod.thickness=solid;mod.offset=0
    return o
def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def grid(name,fn,nu,nv,material,sub=0,solid=0):
    vs=[];uv=[];fs=[]
    for j in range(nv+1):
        for i in range(nu+1):
            u=i/nu;v=j/nv;vs.append(fn(u,v));uv.append((u,v))
    for j in range(nv):
        for i in range(nu):
            k=j*(nu+1)+i;fs.append((k,k+1,k+nu+2,k+nu+1))
    return mesh(name,vs,fs,material,uv,sub,solid)
def interp(rows,t):
    p=t*(len(rows)-1);i=min(int(p),len(rows)-2);f=p-i
    a=np.array(rows[max(0,i-1)]);b=np.array(rows[i]);c=np.array(rows[i+1]);d=np.array(rows[min(len(rows)-1,i+2)])
    return .5*((2*b)+(-a+c)*f+(2*a-5*b+4*c-d)*f*f+(-a+3*b-3*c+d)*f*f*f)
def tube(name,points,r,material,sides=12,steps=None):
    if steps is None:steps=max(12,len(points)*6)
    pts=[np.array(p[:3],float) for p in points]
    rr=[p[3] if len(p)>3 else r for p in points]
    def fn(u,v):
        c=Vector(interp(pts,v));prev=Vector(interp(pts,max(0,v-.001)));nxt=Vector(interp(pts,min(1,v+.001)))
        tangent=(nxt-prev).normalized(); ref=Vector((0,1,0))
        if abs(tangent.dot(ref))>.94:ref=Vector((1,0,0))
        a=tangent.cross(ref).normalized();b=tangent.cross(a).normalized()
        rad=float(interp([[v] for v in rr],v)[0]);theta=u*2*pi
        return c+rad*(a*cos(theta)+b*sin(theta))
    o=grid(name,fn,sides,steps,material)
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    edges=[e for e in bm.edges if e.is_boundary]
    if edges:bmesh.ops.holes_fill(bm,edges=edges,sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free()
    return o
def ribbon(name,points,width,material):
    return grid(name,lambda u,v: Vector(interp(points,v))+Vector(((u-.5)*width,0,0)),4,32,material,1,.004)
def ellipsoid(name,center,radii,material,seg=32,rings=20):
    return grid(name,lambda u,v:(center[0]+radii[0]*sin(pi*v)*sin(2*pi*u),center[1]-radii[1]*sin(pi*v)*cos(2*pi*u),center[2]-radii[2]*cos(pi*v)),seg,rings,material)

# Face: one continuous, anatomically shaped head surface with jaw, sockets,
# cheekbones, philtrum, nose bridge, alae, chin and brow integrated into the skin.
profile=[(1.151,.018,.035),(1.17,.058,.070),(1.20,.078,.088),(1.24,.096,.103),(1.28,.112,.108),(1.32,.113,.106),(1.36,.112,.108),(1.40,.102,.100),(1.435,.063,.065),(1.447,.003,.003)]
def headfn(u,v):
    z,rx,ry=interp(profile,v);theta=(u-.5)*2*pi;x=rx*sin(theta);y=-.015-ry*cos(theta)
    front=max(0,cos(theta))**12
    def g(cx,cz,sx,sz):return exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
    displacement=(.034*g(0,1.28,.017,.038)+.017*g(0,1.314,.014,.056)
        +.013*g(-.016,1.266,.012,.012)+.013*g(.016,1.266,.012,.012)
        +.010*g(0,1.19,.040,.021)+.008*g(0,1.228,.043,.014)
        +.014*g(-.061,1.285,.036,.025)+.014*g(.061,1.285,.036,.025)
        +.013*g(-.050,1.343,.033,.015)+.013*g(.050,1.343,.033,.015)
        -.010*g(-.049,1.322,.028,.016)-.010*g(.049,1.322,.028,.016))
    y-=front*displacement
    return (x,y,z)
head=grid('01 Face • continuous sculpted anatomy',headfn,128,100,skin)
lookup=[interp(profile,t) for t in np.linspace(0,1,1001)]
def face_y(x,z):
    vv=float(np.interp(z,[p[0] for p in lookup],np.linspace(0,1,1001)))
    rx=interp(profile,vv)[1]
    theta=math.asin(max(-.999,min(.999,x/rx)))
    return headfn(.5+theta/(2*pi),vv)[1]
# Actual almond apertures let the eyes sit inside the head instead of on its surface.
bm=bmesh.new();bm.from_mesh(head.data)
remove=[]
for f in bm.faces:
    c=f.calc_center_median()
    if c.y<-.065 and any(((c.x-s*.047)/.022)**2+((c.z-1.322)/.0078)**2<1 for s in [-1,1]):remove.append(f)
bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(head.data);bm.free()
ellipsoid('Neck', (0,.006,1.142),(.062,.06,.09),skin)
# Small almond eyes and lid loops; no large ball-shaped protrusions.
for s in [-1,1]:
    cx=s*.047
    def eyefn(u,v,cx=cx):
        t=2*pi*u;rr=sin(v*pi/2)
        x=cx+.023*cos(t)*rr;z=1.322+.008*sin(t)*rr+.001*(x-cx)/.023
        y=face_y(x,z)+.001-.006*sqrt(max(0,1-rr*rr))
        return (x,y,z)
    grid('Eye almond '+str(s),eyefn,40,10,white)
    eye_y=face_y(cx,1.322)-.006
    ellipsoid('Hazel iris '+str(s),(cx,eye_y,1.322),(.0075,.001,.0075),iris,32,16)
    ellipsoid('Pupil '+str(s),(cx,eye_y-.0011,1.322),(.0032,.0007,.004),dark,24,12)
    ellipsoid('Catchlight '+str(s),(cx-.0017,eye_y-.002,1.325),(.0011,.0004,.0011),white,12,8)
    for upper in [True,False]:
        pts=[]
        for j in range(15):
            t=pi*j/14+(0 if upper else pi)
            x=cx+.024*cos(t);z=1.322+.0085*sin(t)+.001*cos(t)
            pts.append((x,face_y(x,z)-.001,z,.0017 if upper else .0012))
        tube(('Upper' if upper else 'Lower')+' eyelid '+str(s),pts,.002,skin,8,30)
    tube('Eyebrow '+str(s),[(s*.020,-.128,1.345,.002),(s*.038,-.129,1.35,.004),(s*.057,-.121,1.35,.0035),(s*.078,-.108,1.342,.0008)],.003,brow,8,24)
    ellipsoid('Ear '+str(s),(s*.108,-.002,1.289),(.020,.022,.037),skin,28,20)
    ellipsoid('Ear concha '+str(s),(s*.119,-.019,1.287),(.008,.006,.020),lip,20,16)
    ellipsoid('Nostril '+str(s),(s*.012,face_y(s*.012,1.262)-.0007,1.262),(.0025,.001,.0013),lip,16,8)
tube('Mouth line',[(-.029,-.116,1.225,.0004),(-.014,-.124,1.226,.0013),(0,-.127,1.225,.0011),(.013,-.124,1.226,.0013),(.029,-.116,1.227,.0004)],.001,lip,8,32)
tube('Lower lip',[(-.022,-.122,1.223,.0005),(0,-.13,1.220,.0025),(.022,-.122,1.224,.0005)],.002,lip,10,24)

# Copper crest: a fitted grooved scalp under overlapping swept, flattened locks.
def cap(u,v):
    t=(u-.5)*2*pi;bottom=.30+.45*max(0,cos(t))
    x,y,z=headfn(u,bottom+(1-bottom)*v)
    groove=.003*sin(2*pi*u*48+v*7)
    return(x*(1.05+groove*7),(y+.015)*(1.05+groove*7)-.015,z+.006)
grid('02 Copper hair scalp',cap,80,38,hair,0,.003)
def blade(name,points,widths,depths,material,steps=40):
    def fn(u,v):
        c=Vector(interp(points,v));prev=Vector(interp(points,max(0,v-.001)));nxt=Vector(interp(points,min(1,v+.001)))
        tangent=(nxt-prev).normalized();a=tangent.cross(Vector((0,1,0))).normalized();b=tangent.cross(a).normalized()
        w=float(interp([[q] for q in widths],v)[0]);d=float(interp([[q] for q in depths],v)[0]);t=u*2*pi
        return c+a*(w*cos(t))+b*(d*sin(t)*(1+.12*cos(5*t)))
    ob=grid(name,fn,24,steps,material)
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002)
    bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(ob.data);bm.free()
    return ob
for i in range(7):
    x=(i-3)*.029;peak=1.675-abs(i-3)*.025
    blade('Swept copper crest %02d'%i,[(x,-.025,1.395),(x-.026,-.030,1.476),(x-.09,.028,peak-.024),(x-.137,.115,peak)], [.014,.034,.021,.0005],[.010,.021,.013,.0004],hair,48)
    tube('Crest highlight %02d'%i,[(x-.006,-.035,1.40,.001),(x-.032,-.050,1.48,.0018),(x-.097,.013,peak-.025,.001),(x-.137,.115,peak,.0001)],.0015,hairlight,6,34)
for s in [-1,1]:
    for k in range(3):
        blade('Swept sideburn %d %d'%(s,k),[(s*(.095+k*.005),-.025,1.38),(s*(.105+k*.005),-.02,1.33),(s*(.11+k*.004),.025,1.27)], [.012,.012,.001],[.008,.007,.0005],hair,30)
    ellipsoid('Copper ear cuff '+str(s),(s*.124,-.009,1.269),(.006,.01,.007),gold,20,12)

# Charcoal bodice and an orange high collar, constructed around the anatomy.
def torso(u,v):
    z=.61+.53*v;t=(u-.5)*2*pi
    rx=float(np.interp(z,[.61,.72,.83,.96,1.055,1.14],[.172,.148,.141,.18,.191,.067]))
    ry=float(np.interp(z,[.61,.8,1.02,1.14],[.112,.103,.125,.06]))
    fold=.0035*sin(t*13+v*5)+.003*sin(v*40)*exp(-((z-.8)/.14)**2)
    return((rx+fold)*sin(t),-(ry+fold)*cos(t),z)
grid('03 Fitted charcoal bodice',torso,72,40,forest,1,.006)
def collar(u,v):
    t=u*2*pi;r=.073+.009*sin(v*pi)+.003*sin(13*t)
    return(r*sin(t),-r*.87*cos(t),1.103+v*.087-.01*cos(t))
grid('Wrapped ember collar',collar,64,15,sage,1,.006)
tube('Collar rolled edge',[(*collar(i/80,.98),.0025) for i in range(81)],.0025,gold,8,120)
# Broad angular shoulder mantle, with fitted curve and a scalloped pointed edge.
def mantle(u,v):
    t=(u-.5)*2*pi
    r=.08+.19*v+.075*abs(sin(t))**8*v**3
    z=1.112-.095*v+.047*sin(t)**2*v+.035*abs(sin(t))**12*v**4
    z-=.022*(.5+.5*cos(7*t))*v**4
    return(r*sin(t),-r*.68*cos(t),z)
grid('04 Pointed ember shoulder mantle',mantle,96,24,sage,1,.008)
tube('Mantle brass-woven edge',[(*mantle(i/120,.99),.0028) for i in range(121)],.0028,gold,8,160)
# A separate scorched inset follows the shoulder, leaving orange piping exposed.
def shoulder_inset(u,v):
    x,y,z=mantle(u,.30+.54*v)
    return(x,y-.0008,z+.008)
grid('Mantle stitched leather inset',shoulder_inset,96,14,leather,0,.003)
for s in [-1,1]:
    tube('Mantle ember motif '+str(s),[(s*.13,-.10,1.071),(s*.175,-.118,1.068),(s*.21,-.092,1.076)],.0028,thread,8,24)
# Buttoned front placket, miniature scorched leaf embroidery.
ribbon('Bodice front placket',[(0,-.123,.62),(0,-.119,.8),(0,-.138,.95),(0,-.126,1.025)],.033,leather)
for j in range(5):
    z=.73+j*.061
    ellipsoid('Bodice clasp %d'%j,(0,-.142,z),(.007,.003,.007),gold,16,12)
for s in [-1,1]:
    tube('Chest fire stitch '+str(s),[(s*.043,-.127,.89),(s*.066,-.145,.96),(s*.097,-.126,1.005)],.002,thread,6,26)

# Divided ash coat tails, open at the front with actual folded surface and lining.
def coat(u,v):
    t=.38+u*(2*pi-.76)
    z=.255+.41*v
    rx=.26-.085*v;ry=.16-.045*v
    fold=.012*sin(t*8+v*.7)+.004*sin(19*t-v*3)
    z-=.045*(.5+.5*cos(3*t))*(1-v)**5
    return((rx+fold)*sin(t),-(ry+fold*.8)*cos(t),z)
grid('05 Split ash coat tails',coat,96,44,forest,1,.008)
for u in [0,1]:
    tube('Coat orange facing '+str(u),[(*coat(u,i/50),.007) for i in range(51)],.007,sage,12,85)
    tube('Coat facing stitch '+str(u),[(coat(u,i/50)[0],coat(u,i/50)[1]-.006,coat(u,i/50)[2],.0015) for i in range(51)],.0015,thread,6,85)
tube('Coat bottom facing',[(*coat(i/120,.01),.005) for i in range(121)],.005,sage,10,170)
# Back scarf is a draped ribbon with a twist, rather than a round cord.
def scarf(u,v):
    c=Vector(interp([(.045,.12,1.105),(.03,.18,.92),(.08,.195,.73),(.13,.29,.56),(.08,.31,.42)],v))
    width=.075+.013*sin(v*8)
    return c+Vector(((u-.5)*width,.018*cos(u*pi*3)*sin(v*pi),.018*sin(u*pi)*sin(v*6)))
grid('06 Draped ember scarf',scarf,20,50,sage,1,.005)
for u in [.03,.97]:tube('Scarf stitched border '+str(u),[(*scarf(u,i/50),.002) for i in range(51)],.002,thread,6,90)

# Shaped legs and tall leather boots, with brass toe strips and ankle ties.
for s in [-1,1]:
    tube('Fitted trouser leg '+str(s),[(s*.091,.018,.69,.073),(s*.106,.017,.52,.068),(s*.116,-.01,.36,.05),(s*.119,.001,.18,.046)],.06,linen,32,35)
    rows=[(.019,.062,.11,-.038),(.041,.067,.116,-.042),(.082,.065,.117,-.040),(.116,.052,.084,-.025),(.177,.048,.057,.007),(.27,.054,.055,.008),(.37,.058,.055,.002)]
    def boot(u,v,s=s):
        z,rx,ry,cy=interp(rows,v);t=u*2*pi
        return(s*.114+rx*sin(t),cy-ry*cos(t),z+.0035*sin(10*t)*exp(-((z-.18)/.05)**2))
    grid('07 Tall shaped boot '+str(s),boot,48,32,leather,1,.005)
    tube('Boot sole '+str(s),[(*boot(i/64,.02),.004) for i in range(65)],.004,dark,8,100)
    tube('Boot top cuff '+str(s),[(*boot(i/64,.985),.0045) for i in range(65)],.0045,gold,8,100)
    for j in range(4):
        z=.15+j*.044
        tube('Boot lace %d %d'%(s,j),[(s*.114-.025,-.057,z),(s*.114+.027,-.059,z+.019)],.002,thread,6,12)
        tube('Boot reverse lace %d %d'%(s,j),[(s*.114+.025,-.057,z),(s*.114-.027,-.059,z+.019)],.002,thread,6,12)
    tube('Boot front brass strip '+str(s),[(s*.114,-.156,.059),(s*.114,-.141,.10),(s*.114,-.062,.19),(s*.114,-.061,.34)],.0033,gold,8,35)

# Right hand grips the staff; left hand is bent forward and open around a cinder.
for s in [-1,1]:
    if s==1:
        armpts=[(.13,.004,1.035,.058),(.212,.012,1.014,.076),(.276,-.012,.911,.062),(.321,-.078,.82,.043)]
        center=Vector((.363,-.112,.785))
    else:
        armpts=[(-.13,.004,1.035,.058),(-.226,-.002,.985,.073),(-.286,-.098,.845,.062),(-.35,-.205,.874,.043)]
        center=Vector((-.371,-.235,.881))
    sleeve=tube('08 Shaped sleeve '+str(s),armpts,.065,forest,32,40)
    for vert in sleeve.data.vertices:
        vert.co.y+=.003*sin(vert.co.z*190)*exp(-((vert.co.z-.88)/.045)**2)
    tip=Vector(armpts[-1][:3]);near=tip.lerp(center,.3)
    tube('Cuff bracer '+str(s),[(*tip,.046),(*near,.046)],.046,leather,32,10)
    for dz in [-.008,.008]:
        ellipsoid('Bracer rivet %s %s'%(s,dz),(near.x,near.y-.045,near.z+dz),(.003,.002,.003),gold,12,8)
    palm=ellipsoid('Palm '+str(s),center,(.034,.026,.04) if s==1 else (.034,.038,.020),skin,28,20)
    parts=[palm]
    for k in range(4):
        x=center.x-.018+k*.012
        if s==1:
            points=[(x,center.y-.006,center.z+.014,.0085),(x,center.y-.027,center.z-.009,.008),(x,center.y-.022,center.z-.028,.006),(x,center.y-.006,center.z-.026,.0025)]
        else:
            points=[(x,center.y-.015,center.z,.008),(x,center.y-.042,center.z+.006,.0075),(x,center.y-.055,center.z+.025,.006),(x,center.y-.047,center.z+.038,.002)]
        parts.append(tube('Finger %d %d'%(s,k),points,.008,skin,12,20))
    parts.append(tube('Thumb '+str(s),[(center.x-s*.028,center.y,center.z+.012,.011),(center.x-s*.037,center.y-.023,center.z+.028,.009),(center.x-s*.019,center.y-.033,center.z+.03,.003)],.01,skin,12,20))
    bpy.ops.object.select_all(action='DESELECT')
    for ob in parts:ob.select_set(True)
    bpy.context.view_layer.objects.active=palm;bpy.ops.object.join();palm.name='09 Anatomical hand '+str(s)
    active(palm);mod=palm.modifiers.new('Unified fingers and palm','REMESH');mod.mode='VOXEL';mod.voxel_size=.0026;bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=palm.modifiers.new('Knuckle smoothing','SMOOTH');mod.factor=.7;mod.iterations=3;bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
    for face in palm.data.polygons:face.use_smooth=True

# Buckled belt, hanging tinder horn and a stitched herb satchel.
def belt(u,v):
    t=u*2*pi;return(.164*sin(t),-.12*cos(t),.668+(v-.5)*.05)
grid('10 Double waist belt',belt,72,5,leather,0,.008)
for v in [.08,.92]:tube('Belt edge '+str(v),[(*belt(i/90,v),.0018) for i in range(91)],.0018,thread,6,130)
tube('Forged belt buckle',[(-.028,-.137,.65),(-.028,-.139,.69),(.028,-.139,.69),(.028,-.137,.65),(-.028,-.137,.65)],.004,gold,10,40)
ellipsoid('Tinder pouch',(-.183,.013,.604),(.052,.054,.068),leather,32,22)
tube('Pouch gathered cord',[(-.214,-.01,.66),(-.184,-.048,.665),(-.154,-.01,.66)],.003,thread,8,22)
blade('Tinder horn',[(.185,.02,.655),(.208,-.013,.59),(.217,-.015,.51),(.191,.005,.486)],[.03,.037,.018,.002],[.029,.033,.016,.002],linen,38)
tube('Horn retaining strap',[(.16,-.01,.692),(.21,-.054,.613),(.234,-.014,.58)],.005,leather,8,24)

# Forged brazier staff and original-compatible animated flame object.
iron=mat('Cassia | blackened forged iron',(.09,.078,.066),.52,.75)
ember=mat('Cassia | ember surface',(1,.19,.014),.4,emit=1.1)
core=mat('Cassia | flame core',(1,.59,.12),.33,emit=1.4)
staffpts=[(.393,-.117,.018,.018),(.391,-.116,.35,.017),(.385,-.116,.70,.016),(.385,-.11,1.05,.018),(.384,-.106,1.40,.018)]
tube('11 Ash staff haft',staffpts,.018,bark,24,75)
for z in [.06,.36,.70,1.02,1.37]:
    tube('Forged haft band '+str(z),[(.39,-.114,z-.009,.021),(.39,-.114,z+.009,.021)],.021,iron,24,4)
for j in range(10):
    z=.74+j*.01
    tube('Staff grip winding '+str(j),[(.385+.02*cos(t),-.114+.02*sin(t),z+.008*t/(2*pi)) for t in np.linspace(0,2*pi,20)],.0025,leather,6,22)
cx=.383;cy=-.105
for k in range(6):
    a=k*2*pi/6
    tube('Brazier iron rib %d'%k,[(cx,cy,1.37,.010),(cx+.068*cos(a),cy+.068*sin(a),1.442,.009),(cx+.075*cos(a),cy+.075*sin(a),1.531,.008),(cx+.063*cos(a),cy+.063*sin(a),1.575,.004)],.009,iron,12,40)
for z,r in [(1.43,.064),(1.525,.076)]:
    tube('Brazier copper ring '+str(z),[(cx+r*cos(t),cy+r*sin(t),z) for t in np.linspace(0,2*pi,65)],.006,gold,12,100)
ellipsoid('Brazier glowing coals',(cx,cy,1.444),(.049,.049,.027),ember,32,20)
def flame(name,center,height,radius,material,phase=0):
    def fn(u,v):
        t=u*2*pi;r=radius*sin(pi*v)**.72*(1-.45*v)*(1+.15*sin(3*t+v*5))
        return(center[0]+.023*sin(v*4+phase)*v+r*cos(t),center[1]+.008*sin(v*8)*v+r*sin(t),center[2]+height*v)
    return grid(name,fn,40,35,material)
flames=[flame('Outer flame',(cx,cy,1.45),.315,.052,ember),flame('Inner flame',(cx,cy-.013,1.45),.23,.028,core,1)]
for k in [-1,1]:flames.append(flame('Flame lick '+str(k),(cx+k*.03,cy,1.455),.19,.022,ember,k))
bpy.ops.object.select_all(action='DESELECT')
for ob in flames:ob.select_set(True)
bpy.context.view_layer.objects.active=flames[0];bpy.ops.object.join();fire=bpy.context.object;fire.name='brazier_flame'
# Animation about the base of the flame, not the scene origin.
for vert in fire.data.vertices:vert.co-=Vector((cx,cy,1.45))
fire.location=(cx,cy,1.45)
for frame,sx,sz in [(1,1.0,1.0),(7,.93,1.12),(13,1.06,.96),(19,.97,1.10),(25,1.0,1.0)]:
    fire.scale=(sx,sx,sz);fire.keyframe_insert('scale',frame=frame)
fire.animation_data.action.name='flame_flicker'
flame('Palm cinder',(-.37,-.258,.932),.095,.023,ember,1)
ellipsoid('Palm cinder core',(-.37,-.258,.945),(.013,.012,.017),core,24,16)

# Editable construction, rendering studio, and game-ready runtime assembly.
for source in MODEL.objects:
    if source == fire:
        source.location.z-=.016
    else:
        for vertex in source.data.vertices:vertex.co.z-=.016
scene=bpy.context.scene;scene.frame_start=1;scene.frame_end=25;scene.render.fps=24;scene.frame_set(1)
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=1400;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Cassia studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.075,.066,.06,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5;scene.view_settings.view_transform='AgX'
stage=bpy.data.collections.new('STUDIO • excluded from export');scene.collection.children.link(stage)
def stageobj(o):
    for c in list(o.users_collection):c.objects.unlink(o)
    stage.objects.link(o)
def lamp(name,loc,power,size,color):
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color
    o.rotation_euler=(Vector((0,0,.85))-o.location).to_track_quat('-Z','Y').to_euler();stageobj(o)
lamp('Warm key',(-2,-3,4),250,3,(1,.84,.67));lamp('Cool fill',(2,-1,2),100,2,(.68,.81,1));lamp('Copper rim',(0,2,3),280,2,(1,.54,.24))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.006));floor=bpy.context.object;floor.name='Studio floor';stageobj(floor);floor.data.materials.append(mat('Studio charcoal',(.028,.024,.023),.86))
bpy.ops.object.camera_add(location=(2.4,-6,2.8));cam=bpy.context.object;cam.name='Full character camera';stageobj(cam)
cam.rotation_euler=(Vector((.025,0,.87))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.12;scene.camera=cam
scene.render.image_settings.file_format='PNG'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source-art/cassia.blend'))
scene.render.filepath=str(EV/'cassia-full.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
cam.location=(1.5,-5,2.1);cam.rotation_euler=(Vector((0,-.025,1.37))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.80
scene.render.resolution_x=1400;scene.render.resolution_y=1400;scene.render.filepath=str(EV/'cassia-face.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
cam.location=(-3,-5,4);cam.rotation_euler=(Vector((0,0,.88))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.12
scene.render.resolution_x=1200;scene.render.resolution_y=1400;scene.render.filepath=str(EV/'cassia-high-angle.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
runtime=bpy.data.collections.new('RUNTIME • export assembly');scene.collection.children.link(runtime)
copies=[]
for source in list(MODEL.objects):
    ob=source.copy();ob.data=source.data.copy();runtime.objects.link(ob);active(ob)
    for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    if source==fire:
        runtime_fire=ob;source.name='Authored brazier flame';ob.name='brazier_flame'
    else:copies.append(ob)
bpy.ops.object.select_all(action='DESELECT')
for ob in copies:ob.select_set(True)
bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();body=bpy.context.object;body.name='cassia'
active(body);dec=body.modifiers.new('Runtime surface budget','DECIMATE');dec.ratio=.21;bpy.ops.object.modifier_apply(modifier=dec.name)
runtime_fire.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/cassia.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_materials='EXPORT',export_image_format='AUTO',export_yup=True)
report={'construction_meshes':len(MODEL.objects),'runtime_vertices':sum(len(o.data.vertices) for o in runtime.objects),'runtime_triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in runtime.objects),'body_dimensions':list(body.dimensions),'flame_action':'flame_flicker','flame_frames':[1,25],'packed_images':len([im for im in bpy.data.images if im.packed_file])}
(EV/'model-report.json').write_text(json.dumps(report,indent=2))
runtime.hide_render=True;runtime.hide_viewport=True
cam.location=(2.4,-6,2.8);cam.rotation_euler=(Vector((.025,0,.87))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=2.12
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source-art/cassia.blend'))
print('CASSIA_REBUILD_COMPLETE',json.dumps(report))
