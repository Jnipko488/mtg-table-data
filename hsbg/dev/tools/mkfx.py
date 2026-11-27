from PIL import Image
import numpy as np, os, math
S=256
def load(n):
    a=np.array(Image.open(f'/tmp/fxsrc/GenFX_{n}.png').convert('RGBA')).astype(np.float32)/255
    rgb=a[...,:3]; al=a[...,3]
    lum=rgb.max(-1)
    # additive textures: black = transparent. Use luminance*alpha as coverage.
    base=lum*al if al.mean()<0.98 else lum
    cov=np.clip((base-0.07)/0.93,0,1)**1.25
    return rgb, cov
TEX={}
def tex(n):
    if n not in TEX: TEX[n]=load(n)
    return TEX[n]
def place(n, scale, opacity, tint=(1,1,1), rot=0):
    rgb,cov=tex(n)
    im=Image.fromarray((np.dstack([rgb,cov])*255).astype(np.uint8))
    if rot: im=im.rotate(rot, resample=Image.BICUBIC)
    sz=max(2,int(S*scale)); im=im.resize((sz,sz),Image.LANCZOS)
    can=Image.new('RGBA',(max(S,sz),max(S,sz)),(0,0,0,0)); off=(can.width-sz)//2; can.paste(im,(off,off))
    if can.width>S: c=(can.width-S)//2; can=can.crop((c,c,c+S,c+S))
    a=np.array(can).astype(np.float32)/255
    yy,xx=np.mgrid[0:S,0:S]; r=np.hypot(xx-S/2+.5,yy-S/2+.5)/(S/2)
    vig=np.clip((1.0-r)/0.25,0,1)
    lum=np.maximum(a[...,:3].max(-1),1e-3)
    col=(np.clip(a[...,:3]/lum[...,None],0,1) if tuple(tint)==(1,1,1) else np.ones_like(a[...,:3]))*np.array(tint,np.float32); cv=a[...,3]*opacity*vig
    return col,cv
def frame(layers):
    C=np.zeros((S,S,3),np.float32); keep=np.ones((S,S),np.float32)
    for col,cv in layers:
        C+=col*cv[...,None]; keep*=(1-np.clip(cv,0,1))
    A=1-keep
    rgb=np.where(A[...,None]>1e-4, C/np.maximum(A[...,None],1e-4),0)
    rgb=np.clip(rgb,0,1)
    return Image.fromarray((np.dstack([rgb,np.clip(A*1.15,0,1)])*255).astype(np.uint8))
def ease(t): return 1-(1-t)**2
def save(kind, frames):
    os.makedirs(f'/tmp/up20/fx/{kind}',exist_ok=True)
    for i,f in enumerate(frames,1): f.save(f'/tmp/up20/fx/{kind}/{i}.png')
GOLD=(1.0,.82,.38); WARM=(1.0,.9,.7); PURP=(.75,.3,1.0); SMOKE=(.78,.74,.8)
# hit: white blast + shockwave + flash
fr=[]
for i in range(8):
    t=i/7
    fr.append(frame([place('BlastWhite',.45+.55*ease(t),(1-t)**1.5,WARM,rot=i*7),
                     place('Shockwave8',.3+1.0*ease(t),(1-t)*.9,WARM),
                     place('FlareStarWhite2',.9-.3*t,max(0,1-2.2*t))]))
save('hit',fr)
# shield break: golden ring burst + starburst + sparkle
fr=[]
for i in range(9):
    t=i/8
    fr.append(frame([place('glow_ring2b',.55+.75*ease(t),(1-t)**1.2,GOLD),
                     place('Starburst_ThinLines',.6+.5*t,(1-t)*.8,GOLD,rot=i*4),
                     place('FlareStarGold2',.8,max(0,1-1.8*t)),
                     place('Flare_White2',.5+.2*t,max(0,1-1.5*t))]))
save('shield',fr)
# death: smoke ring + puff
fr=[]
for i in range(10):
    t=i/9
    fr.append(frame([place('Smoke03',.45+.65*ease(t),min(1,(1-t)**1.2*1.4),SMOKE,rot=i*6),
                     place('CloudPuff1',.5+.6*ease(t),min(1,(1-t)*1.5),SMOKE,rot=-i*5),
                     place('Smoke6',.4+.5*ease(t),min(1,(1-t)*1.3),(.85,.82,.86),rot=i*9)]))
save('death',fr)
# golden (triple): rotating gold starburst + spin ring + flare pulses
fr=[]
for i in range(12):
    t=i/11; pulse=.5+.5*math.sin(t*math.pi)
    fr.append(frame([place('Starburst_ThinLines',.8+.3*t,pulse,GOLD,rot=i*9),
                     place('SpinRing4',.4+.8*ease(t),(1-t)*.9,GOLD,rot=i*15),
                     place('FlareStarGold2',.7+.3*pulse,pulse),
                     place('MiniMotes1',1.0,(1-t)*.8,GOLD)]))
save('golden',fr)
# tierup: gold ring + light flare
fr=[]
for i in range(10):
    t=i/9
    fr.append(frame([place('glow_ring2b',.4+.9*ease(t),(1-t),GOLD),
                     place('SpinRing4',.5+.6*ease(t),(1-t)*.8,GOLD,rot=-i*12),
                     place('FlareStarGold2',.9,max(0,1-1.4*t))]))
save('tierup',fr)
# coin: small gold sparkle
fr=[]
for i in range(8):
    t=i/7
    fr.append(frame([place('FlareStarGold2',.55+.25*math.sin(t*math.pi),math.sin(t*math.pi)),
                     place('Flare_White2',.5,max(0,1-1.6*abs(t-.35)*2),rot=i*10),
                     place('MiniMotes1',.8,(1-t)*.7,GOLD)]))
save('coin',fr)
# darkgift: purple flames + warlock flare + embers
fr=[]
for i in range(12):
    t=i/11; pulse=math.sin(t*math.pi)
    fr.append(frame([place('CloudFireBW_Alpha',.7+.3*t,pulse*.9,PURP,rot=i*12),
                     place('FlareWarlock1',.8+.4*pulse,pulse,(.7,.25,1)),
                     place('embers02',.9,pulse*.8,(1,.45,.9)),
                     place('FlareWarlock1',.4+.9*ease(t),max(0,.9-1.1*t),(.85,.4,1))]))
save('darkgift',fr)
print('ok')
