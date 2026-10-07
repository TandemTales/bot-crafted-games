"""Deterministic authored PBR surfaces for Cassia. Run with Python + Pillow + NumPy.
All images are original procedural artwork; no external asset dependencies.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
OUT=Path(__file__).parent/'cassia-textures'
OUT.mkdir(exist_ok=True)
rng=np.random.default_rng(4119)

def save(name, rgb):
    Image.fromarray(np.uint8(np.clip(rgb,0,1)*255)).save(OUT/name)

def surface(name, base, size=2048, kind='cloth'):
    y,x=np.mgrid[0:size,0:size].astype(float)/size
    grain=rng.normal(0,1,(size,size))
    broad=np.zeros_like(x)
    for f,a in [(3,.4),(9,.2),(31,.08),(73,.04)]:
        broad+=a*np.sin(x*f*6.283+np.sin(y*f*4.1))*np.cos(y*f*5.2)
    if kind=='cloth':
        weave=(np.sin(x*size*1.53)*np.cos(y*size*1.53))*.012
        height=weave+.006*grain+.035*broad
        var=.10*broad+.015*grain+weave
        # Worn warp strands and subtle dyed yarn structure.
        var+=.018*np.sin(x*size*.39)+.012*np.sin(y*size*.44)
        rough=.84+.045*broad+.025*grain
    elif kind=='leather':
        height=.013*grain+.02*broad+.009*np.sin(55*x+19*np.sin(y*43))
        var=.18*broad+.024*grain
        rough=.70+.06*broad+.035*grain
    elif kind=='hair':
        strand=np.sin(2*np.pi*(x*110+.4*np.sin(y*9+x*7)))
        height=.08*strand+.008*grain
        var=.22*strand+.13*broad+.03*grain
        rough=.69+.04*broad
    elif kind=='bark':
        veins=np.sin(x*280+np.sin(y*34)*2+np.sin(y*11+x*17))
        height=.09*veins+.024*grain+.04*broad
        var=.055*veins+.10*broad+.025*grain
        rough=.79+.065*broad
    else:
        height=.005*grain+.007*broad
        var=.07*broad+.009*grain
        rough=.63+.025*broad+.02*grain
    rgb=np.array(base)[None,None,:]*(1+var[:,:,None])
    save(name+'_albedo.png',rgb)
    save(name+'_roughness.png',np.repeat(np.clip(rough,0,1)[:,:,None],3,axis=2))
    dy,dx=np.gradient(height)
    strength=2 if kind=='bark' else 1.4
    normal=np.dstack([-dx*strength,-dy*strength,np.ones_like(x)])
    normal/=np.linalg.norm(normal,axis=2)[:,:,None]
    save(name+'_normal.png',normal*.5+.5)

surface('forest',(0.20,.185,.18))
surface('sage',(.57,.205,.055))
surface('linen',(.42,.38,.32))
surface('leather',(.20,.105,.062),1024,'leather')
surface('bark',(.16,.115,.082),1024,'bark')
surface('skin',(.71,.47,.33),2048,'skin')
surface('hair',(.63,.235,.055),1024,'hair')
# Face-map painting: UV u=.5 is the face, v follows height of the head.
n=2048
yy,xx=np.mgrid[0:n,0:n].astype(float)/n
v=1-yy
base=np.asarray(Image.open(OUT/'skin_albedo.png')).astype(float)/255
def gauss(u,z,wu,wz): return np.exp(-((xx-u)/wu)**2-((v-z)/wz)**2)
blush=gauss(.435,.48,.027,.09)+gauss(.565,.48,.027,.09)+.5*gauss(.5,.46,.012,.07)
base+=blush[:,:,None]*np.array([.05,-.03,-.022])
# Warm forehead and chin, cool beard-free jaw shadows.
base+=gauss(.5,.78,.11,.13)[:,:,None]*np.array([.045,.025,.012])
base-=gauss(.5,.14,.17,.075)[:,:,None]*np.array([.02,.024,.020])
im=Image.fromarray(np.uint8(np.clip(base,0,1)*255)); d=ImageDraw.Draw(im)
for _ in range(48):
    u=float(rng.uniform(.411,.589)); z=float(rng.normal(.52,.035))
    if abs(u-.5)<.013: continue
    r=float(rng.uniform(.5,1.8)); px=u*n; py=(1-z)*n
    d.ellipse((px-r,py-r,px+r,py+r),fill=(123,73,44))
im.save(OUT/'skin_albedo.png')
print('Cassia PBR texture set:',OUT)
