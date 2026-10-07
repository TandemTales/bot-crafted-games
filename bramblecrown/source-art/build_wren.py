"""Wren / Grovewalker: authored surface-model rebuild, Blender 5.1.
Run blender -b -P source-art/build_wren.py. No other character is touched.
The .blend retains named construction meshes and packed PBR maps; runtime is joined.
"""
import bpy, bmesh, math, json, tempfile, sys
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi, exp, sqrt
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
TEX=ROOT/'source-art/wren-textures'
EV=ROOT/'evidence/2026-10-07-wren-rebuild'
EV.mkdir(exist_ok=True)
(EV/'export-temp').mkdir(exist_ok=True)
tempfile.tempdir=str(EV/'export-temp')
bpy.ops.wm.read_factory_settings(use_empty=True)
MODEL=bpy.data.collections.new('WREN • authored construction')
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
forest=mat('Wren | forest dyed wool',(1,1,1),texture='forest')
sage=mat('Wren | sage linen',(1,1,1),texture='sage')
linen=mat('Wren | warm undyed linen',(1,1,1),texture='linen')
leather=mat('Wren | weathered chestnut leather',(1,1,1),texture='leather')
bark=mat('Wren | living ash wood',(1,1,1),texture='bark')
skin=mat('Wren | skin - painted face UV',(1,1,1),texture='skin')
skin.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.075
lip=mat('Wren | lips and inner ear',(.30,.105,.075),.55)
dark=mat('Wren | shadow seams',(.027,.018,.012),.8)
hair=mat('Wren | auburn hair',(1,1,1),texture='hair')
hairlight=mat('Wren | hair ridges',(.21,.088,.029),.5)
gold=mat('Wren | aged brass',(.46,.30,.10),.43,.65)
thread=mat('Wren | ochre embroidery',(.58,.42,.16),.82)
white=mat('Wren | ivory sclera',(.65,.62,.48),.28)
iris=mat('Wren | hazel iris',(.11,.20,.08),.3)
seed=mat('Wren | crown seed',(.65,.88,.26),.27,.05,emit=.6)

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
profile=[(1.151,.018,.035),(1.17,.058,.070),(1.20,.087,.088),(1.24,.104,.103),(1.28,.112,.108),(1.32,.113,.106),(1.36,.112,.108),(1.40,.102,.100),(1.435,.063,.065),(1.447,.003,.003)]
def headfn(u,v):
    z,rx,ry=interp(profile,v);theta=(u-.5)*2*pi;x=rx*sin(theta);y=-.015-ry*cos(theta)
    front=max(0,cos(theta))**12
    def g(cx,cz,sx,sz):return exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
    displacement=(.042*g(0,1.28,.018,.038)+.017*g(0,1.314,.014,.056)
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
    tube('Eyebrow '+str(s),[(s*.020,-.128,1.345,.002),(s*.038,-.129,1.35,.004),(s*.057,-.121,1.35,.0035),(s*.078,-.108,1.342,.0008)],.003,hair,8,24)
    ellipsoid('Ear '+str(s),(s*.108,-.002,1.289),(.020,.022,.037),skin,28,20)
    ellipsoid('Ear concha '+str(s),(s*.119,-.019,1.287),(.008,.006,.020),lip,20,16)
    ellipsoid('Nostril '+str(s),(s*.012,face_y(s*.012,1.262)-.0007,1.262),(.0025,.001,.0013),lip,16,8)
tube('Mouth line',[(-.029,-.116,1.225,.0004),(-.014,-.124,1.226,.0013),(0,-.127,1.225,.0011),(.013,-.124,1.226,.0013),(.029,-.116,1.227,.0004)],.001,lip,8,32)
tube('Lower lip',[(-.022,-.122,1.223,.0005),(0,-.13,1.220,.0025),(.022,-.122,1.224,.0005)],.002,lip,10,24)

# Hair cap inside hood and sculpted flowing locks with tapered longitudinal ridges.
def haircap(u,v):
    t=(u-.5)*2*pi;front=max(0,cos(t))
    vv=(.43+.31*front)+(1-(.43+.31*front))*v
    x,y,z=headfn(u,vv)
    groove=.0025*sin(2*pi*u*52+sin(v*8))
    return (x*(1.05+groove*8),(y+.015)*(1.05+groove*8)-.015,z+.005)
grid('Hair scalp • fitted shell',haircap,96,40,hair,0,.003)
def fringe(u,v):
    x=-.102+.204*u+.009*sin(pi*v)
    low=1.357+.025*u+.006*cos(u*12*pi)
    high=1.438-.051*(x/.112)**2
    z=low+(high-low)*v
    yy=face_y(x,z)-.005-.0035*sin(pi*v)*(.5+.5*cos(u*22*pi))
    return(x,yy,z)
grid('Swept fringe • continuous sculpted hairline',fringe,96,35,hair,1,.003)
for k in range(21):
    u=(k+.5)/21
    tube('Fine swept hair ridge %02d'%k,[(fringe(u,j/30)[0],fringe(u,j/30)[1]-.001,fringe(u,j/30)[2],.0005*sin(pi*j/30)+.0001) for j in range(1,30)],.0006,hairlight,6,40)
for s in [-1,1]:
    for k in range(3):
        tube('Temple lock %d %d'%(s,k),[(s*(.095+k*.007),-.05,1.383,.009),(s*(.104+k*.006),-.075,1.32,.009),(s*(.103+k*.007),-.060,1.255,.006),(s*(.108+k*.007),-.04,1.222,.0005)],.009,hair,12,32)

# Tailored robe: fitted waist, chest volume, flared hem, tension and gravity folds.
def robe(u,v):
    z=.22+.925*v;t=(u-.5)*2*pi
    rx=float(np.interp(z,[.22,.35,.58,.80,.9,1.04,1.11,1.145],[.235,.24,.205,.145,.161,.201,.178,.07]))
    ry=float(np.interp(z,[.22,.55,.80,1.04,1.145],[.152,.144,.106,.13,.063]))
    fold=(.012+.009*(1-v))*sin(12*t+.5*sin(v*5))+ .005*sin(23*t-v*4)
    fold*=.3+.7*max(0,min(1,(.84-z)*6))
    hem=.01*sin(5*t)+.006*sin(9*t)
    return ((rx+fold)*sin(t),-(ry+fold*.75)*cos(t),z+hem*(1-v)**5)
robeobj=grid('02 Robe • fitted wool with radial folds',robe,96,55,forest,1,.007)
# Hem piping follows the actual scalloped folded contour.
pts=[(*robe(i/96,.015),.0025) for i in range(97)]
tube('Robe lower hem stitched roll',pts,.0025,thread,8,192)
# Narrow divided over-tunic with draped center panel, 3D hem and decorative border.
def apron(u,v):
    z=.285+.77*v;x=(u-.5)*(.255-.075*v)
    y=-float(np.interp(z,[.28,.55,.81,1.055],[.171,.158,.128,.149]))-.009*cos((u-.5)*6*pi)*(1-v)
    z-=.045*(1-abs(u-.5)*2)*(1-v)**7
    return(x,y,z)
grid('03 Sage apron • shaped front panel',apron,32,42,sage,1,.005)
for u in [.025,.975]:
    tube('Apron woven border '+str(u),[(*apron(u,v/40),.0025) for v in range(41)],.0025,thread,8,90)
# Botanical front embroidery, readable as a sprig at selection scale.
tube('Chest embroidered stem',[(0,-.154,1.026),(-.012,-.153,.99),(.008,-.15,.954),(0,-.146,.925)],.0023,thread,8,24)
for i in range(5):
    z=.945+i*.014;s=(-1)**i
    tube('Chest fern stitching '+str(i),[(0,-.155,z),(s*.014,-.157,z+.006),(s*.028,-.154,z+.018)],.0019,thread,6,12)

# Layered warm leather shoulder cape: asymmetric scallops, weight over shoulders.
def mantle(u,v):
    t=(u-.5)*2*pi;r=.079+v*.227
    z=1.153-.135*v+.017*sin(t*2)*v-.025*(.5+.5*cos(5*t))*v**4+.061*sin(t)**2*v
    return (r*sin(t),-r*.69*cos(t),z)
grid('04 Chestnut shoulder cape',mantle,80,20,leather,1,.010)
tube('Cape scalloped ochre seam',[(*mantle(i/100,.97),.003) for i in range(101)],.003,thread,8,200)
for i in range(16):
    t=i/16
    tube('Cape radial seam '+str(i),[(*mantle(t,j/12),.0012) for j in range(3,13)],.0012,dark,6,20)
# Hood is an open shell, not a solid ball covering the face.
hoodrows=[(1.12,.093,.091,.0,.68),(1.18,.137,.128,.012,.93),(1.27,.15,.139,.025,1.04),(1.37,.145,.133,.028,.98),(1.455,.113,.114,.035,.68),(1.49,.065,.073,.06,.34),(1.51,.006,.008,.075,.02)]
def hoodfn(u,v):
    z,rx,ry,cy,a=interp(hoodrows,v);t=a+u*(2*pi-2*a)
    wrinkle=.003*sin(t*9+v*4)*sin(pi*v)
    return ((rx+wrinkle)*sin(t),cy-(ry+wrinkle)*cos(t),z+.003*cos(t*5)*sin(pi*v))
grid('05 Hood • open lined shell',hoodfn,64,38,forest,1,.008)
for u in [0,1]:
    tube('Hood rolled opening '+str(u),[(*hoodfn(u,j/60),.006) for j in range(61)],.006,sage,10,100)
    tube('Hood hand sewn seam '+str(u),[(hoodfn(u,j/60)[0],hoodfn(u,j/60)[1]-.004,hoodfn(u,j/60)[2],.0014) for j in range(61)],.0014,thread,6,100)

# Bent sleeves have a continuous elbow and small compression folds.
for s in [-1,1]:
    points=[(s*.125,.004,1.036,.060),(s*.205,.015,1.022,.077),(s*.244,.015,.974,.073),(s*.277,-.002,.909,.066),(s*.31,-.069,.864 if s==1 else .822,.05),(s*.337,-.106,.882 if s==1 else .79,.044)]
    sleeve=tube('06 Tailored sleeve '+str(s),points,.06,forest,32,38)
    # Compression creases modelled into sleeve surface.
    for vtx in sleeve.data.vertices:
        z=vtx.co.z
        vtx.co.y+=.0035*sin(z*180)*exp(-((z-.91)/.06)**2)
    cuff=points[-1];cx,cy,cz=cuff[:3]
    tube('Linen cuff '+str(s),[(s*.324,-.096,cz+.008,.046),(s*.347,-.119,cz-.004,.045)],.045,linen,32,6)
    # Palm and individually bent digits are joined/remeshed into one continuous hand.
    handparts=[]
    palm=ellipsoid('Palm '+str(s),(s*.352,-.123,cz-.025),(.037,.023,.043),skin,24,18);handparts.append(palm)
    for k in range(4):
        xx=s*(.334+k*.012);zz=cz-.033+(1-abs(k-1.5)/2)*.009
        pp=[(xx,-.133,zz,.0085),(xx,-.153,zz-.026,.008),(xx,-.147,zz-.043,.0065),(xx,-.133,zz-.042,.003)]
        handparts.append(tube('Finger '+str(s)+' '+str(k),pp,.008,skin,10,16))
    handparts.append(tube('Thumb '+str(s),[(s*.328,-.121,cz-.008,.012),(s*.319,-.144,cz-.018,.010),(s*.331,-.153,cz-.028,.004)],.011,skin,12,18))
    bpy.ops.object.select_all(action='DESELECT')
    for ob in handparts:ob.select_set(True)
    bpy.context.view_layer.objects.active=palm;bpy.ops.object.join();palm.name='07 Anatomical hand '+str(s)
    mod=palm.modifiers.new('Unified palm and fingers','REMESH');mod.mode='VOXEL';mod.voxel_size=.0028
    active(palm);bpy.ops.object.modifier_apply(modifier=mod.name)
    mod=palm.modifiers.new('Smooth knuckles','SMOOTH');mod.factor=.7;mod.iterations=3;bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
    for f in palm.data.polygons:f.use_smooth=True

# Boots: heel, ankle, instep and extended toe share a shaped upper surface.
for s in [-1,1]:
    cx=s*.097
    bootrows=[(.022,.065,.105,-.039),(.04,.07,.115,-.044),(.072,.068,.119,-.046),(.101,.058,.104,-.038),(.14,.047,.060,-.005),(.21,.046,.047,.009),(.29,.053,.051,.012)]
    def bootfn(u,v,cx=cx):
        z,rx,ry,cy=interp(bootrows,v);t=u*2*pi
        return(cx+rx*sin(t),cy-ry*cos(t),z+.003*cos(t*8)*exp(-((z-.15)/.04)**2))
    grid('08 Sculpted boot upper '+str(s),bootfn,48,30,leather,1,.005)
    tube('Boot sole welt '+str(s),[(*bootfn(i/64,.035),.0045) for i in range(65)],.0045,dark,8,100)
    tube('Boot top roll '+str(s),[(*bootfn(i/64,.99),.004) for i in range(65)],.004,linen,8,90)
    for j in range(4):
        z=.123+j*.025
        tube('Boot crossed lace %d %d'%(s,j),[(cx-.027,-.052,z),(cx+.026,-.055,z+.017)],.0025,thread,8,12)
        tube('Boot crossed lace back %d %d'%(s,j),[(cx+.027,-.052,z),(cx-.026,-.055,z+.017)],.0025,thread,8,12)

# Belt, diagonal harness, buckle, seed pouches. Belts conform to torso surface.
def beltfn(u,v):
    t=u*2*pi;return(.154*sin(t),-.119*cos(t),.816+(v-.5)*.038)
grid('09 Broad waist belt',beltfn,80,4,leather,0,.009)
for v in [.08,.92]:tube('Belt stitching '+str(v),[(*beltfn(i/80,v),.0014) for i in range(81)],.0014,thread,6,160)
ribbon('Diagonal leather harness',[(-.153,-.119,1.065),(-.09,-.166,1.012),(-.018,-.17,.931),(.074,-.148,.829)],.032,leather)
for dx in [-.012,.012]:tube('Harness seam '+str(dx),[(-.153+dx,-.123,1.063),(-.09+dx,-.169,1.012),(-.018+dx,-.173,.931),(.074+dx,-.151,.829)],.0012,thread,6,44)
tube('Belt buckle',[(-.023,-.134,.796),(-.027,-.137,.833),(.025,-.138,.833),(.025,-.137,.796),(-.023,-.134,.796)],.004,gold,10,40)
tube('Buckle tongue',[(0,-.142,.802),(0,-.142,.830)],.0025,gold,8,10)
for s in [-1,1]:
    x=s*.168
    ellipsoid('Gathered seed pouch '+str(s),(x,-.032,.745),(.051,.051,.068),leather,32,24)
    tube('Pouch drawstring '+str(s),[(x-.03,-.031,.795),(x,-.081,.798),(x+.03,-.032,.795)],.003,thread,8,20)
    tube('Pouch tie '+str(s),[(x,-.083,.797),(x-.013,-.09,.759),(x+.005,-.095,.743)],.002,thread,8,20)

# Leaf-shaped wooden buckler; carved radial veins and brass rim.
def shieldfn(u,v):
    t=u*2*pi;r=v
    x=-.36+.121*sin(t)*r
    z=.725+.155*cos(t)*r
    y=-.189-.033*(1-r*r)
    return (x,y,z)
grid('10 Carved leaf buckler',shieldfn,64,18,bark,0,.011)
tube('Buckler brass edge',[(*shieldfn(i/96,1),.004) for i in range(97)],.004,gold,10,160)
tube('Buckler central leaf vein',[(-.36,-.22,.585),(-.364,-.232,.72),(-.36,-.21,.86)],.004,thread,8,36)
for i in range(5):
    z=.635+i*.039
    for s in [-1,1]:
        tube('Buckler leaf vein %d %d'%(i,s),[(-.362,-.23,z),(-.36+s*.045,-.22,z+.021),(-.36+s*.087,-.202,z+.041)],.002,thread,6,24)

# Staff: irregular grown wood, wrapped grip, split cradle and luminous crown seed.
staffpts=[(.403,-.131,.018,.020),(.399,-.133,.28,.018),(.388,-.134,.58,.017),(.377,-.136,.88,.017),(.383,-.125,1.11,.020),(.400,-.116,1.31,.017),(.407,-.114,1.42,.009)]
tube('11 Living ash staff',staffpts,.018,bark,20,95)
for j in range(12):
    z=.798+j*.01
    tube('Leather wrapped grip '+str(j),[(.378+.021*cos(t),-.136+.021*sin(t),z+.005*t/(2*pi)) for t in np.linspace(0,2*pi,25)],.003,leather,6,30)
for s in [-1,1]:
    tube('Staff growing crown '+str(s),[(.398,-.114,1.29,.013),(.4+s*.042,-.12,1.365,.014),(.4+s*.058,-.113,1.44,.010),(.4+s*.027,-.112,1.51,.005),(.405,-.11,1.547,.0008)],.012,bark,14,52)
ellipsoid('Crown seed',(.401,-.117,1.434),(.036,.031,.068),seed,40,28)
for s in [-1,1]:
    def leaffn(u,v,s=s):
        w=sin(pi*v)*.034;return(.408+s*(v*.092)+(u-.5)*w,-.115-.022*sin(pi*u),1.315+v*.025+.03*sin(pi*v))
    grid('Fresh staff leaf '+str(s),leaffn,10,18,sage,1,.002)
    tube('Leaf rib '+str(s),[(.408,-.128,1.315),(.408+s*.05,-.14,1.358),(.408+s*.092,-.115,1.34)],.0015,thread,6,20)
# Small collar fastening and hanging crown charm.
ellipsoid('Collar brass brooch',(.028,-.100,1.139),(.018,.006,.018),gold,24,16)
tube('Pendant cord',[(-.025,-.117,1.132),(0,-.184,1.083),(.051,-.143,1.128)],.0025,leather,8,32)
ellipsoid('Pendant seed',(.002,-.183,1.079),(.009,.007,.019),gold,24,16)

# Set a consistent planted ground origin.
for ob in MODEL.objects:
    for vertex in ob.data.vertices:vertex.co.z-=.018
# Save editable construction first. Stage lights/cameras are excluded from GLB.
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=48
scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=1400;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Wren studio');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.082,.073,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
scene.view_settings.view_transform='AgX'
stage=bpy.data.collections.new('STUDIO • excluded from export');scene.collection.children.link(stage)
def stageobj(o):
    for c in list(o.users_collection):c.objects.unlink(o)
    stage.objects.link(o)
def lamp(name,loc,power,size,color):
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color
    o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler();stageobj(o)
lamp('Warm softbox',(-2,-3,4),250,3,(1,.85,.67))
lamp('Cool fill',(2,-1,2),100,2,(.68,.82,1))
lamp('Rim light',(0,2,3),300,2,(.74,1,.81))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.008));floor=bpy.context.object;floor.name='Studio floor';stageobj(floor)
floor.data.materials.append(mat('Studio charcoal',(.022,.033,.029),.86))
bpy.ops.object.camera_add(location=(2.4,-6,2.8));cam=bpy.context.object;cam.name='Full character camera';stageobj(cam)
cam.rotation_euler=(Vector((.04,0,.80))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=1.91;scene.camera=cam
scene.render.image_settings.file_format='PNG'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source-art/grovewalker.blend'))
# Render meaningful checkpoint before runtime integration.
scene.render.filepath=str(EV/'wren-full.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
cam.location=(1.5,-5,2.1);cam.rotation_euler=(Vector((0,-.025,1.285))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.56
scene.render.resolution_x=1400;scene.render.resolution_y=1400
scene.render.filepath=str(EV/'wren-face.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
cam.location=(-3,-5,3.7);cam.rotation_euler=(Vector((0,0,.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=1.95
scene.render.resolution_x=1200;scene.render.resolution_y=1400
scene.render.filepath=str(EV/'wren-high-angle.png')
if '--skip-render' not in sys.argv:bpy.ops.render.render(write_still=True)
# Apply modifiers on copied construction meshes and combine draw-call batches.
runtime=bpy.data.collections.new('RUNTIME • export assembly');scene.collection.children.link(runtime)
copies=[]
for source in list(MODEL.objects):
    ob=source.copy();ob.data=source.data.copy();runtime.objects.link(ob);active(ob)
    for mod in list(ob.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
    copies.append(ob)
bpy.ops.object.select_all(action='DESELECT')
for ob in copies:ob.select_set(True)
bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();ob=bpy.context.object;ob.name='grovewalker'
# Preserve detailed editable surfaces while reducing the runtime tessellation.
active(ob)
dec=ob.modifiers.new('Runtime surface budget','DECIMATE');dec.ratio=.22
bpy.ops.object.modifier_apply(modifier=dec.name)
# Sculpted construction meshes stay editable in source. Runtime breathing is a mild
# shape animation, preserving planted feet/staff and the game's root animation.
ob.shape_key_add(name='Basis');breath=ob.shape_key_add(name='Breathing')
for i,v in enumerate(ob.data.vertices):
    x,y,z=v.co
    if abs(x)<.29 and .55<z<1.145:
        w=sin(pi*(z-.55)/.595)**2
        breath.data[i].co.y-=.0035*w*max(0,-y/.16)
        breath.data[i].co.z+=.0015*w
for frame,value in [(1,0),(46,1),(91,0),(121,0)]:
    breath.value=value;breath.keyframe_insert('value',frame=frame)
ob.data.shape_keys.animation_data.action.name='Wren_Breathe'
scene.render.fps=30;scene.frame_start=1;scene.frame_end=121;scene.frame_set(1)
active(ob)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/grovewalker.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_morph=True,export_materials='EXPORT',export_image_format='AUTO',export_yup=True)
report={'construction_meshes':len(MODEL.objects),'runtime_vertices':len(ob.data.vertices),'runtime_polygons':len(ob.data.polygons),'runtime_triangles':sum(len(p.vertices)-2 for p in ob.data.polygons),'materials':[m.name for m in ob.data.materials],'dimensions':list(ob.dimensions),'animation':'Wren_Breathe, 4 seconds, cloth-only gentle breathing','packed_images':len([im for im in bpy.data.images if im.packed_file])}
(EV/'model-report.json').write_text(json.dumps(report,indent=2))
# Save runtime collection hidden so reopening shows the editable model without overlap.
runtime.hide_render=True;runtime.hide_viewport=True
cam.location=(2.4,-6,2.8);cam.rotation_euler=(Vector((.04,0,.8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=1.91
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source-art/grovewalker.blend'))
print('WREN_REBUILD_COMPLETE',json.dumps(report))
