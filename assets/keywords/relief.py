"""3D look for keyword tokens: raised, bevelled tone-on-tone glyph + bevelled face edge,
baked into the diffuse texture and exported as a normal map for TTS lighting."""
import numpy as np, importlib.util
from PIL import Image, ImageFilter, ImageDraw
spec=importlib.util.spec_from_file_location('mt','/home/claude/tok/make_tokens.py'); mt=importlib.util.module_from_spec(spec); spec.loader.exec_module(mt)
OUT=mt.OUT
N=1024; FACE_R=252
LIGHT=np.array([-0.55,-0.6,0.58]); LIGHT/=np.linalg.norm(LIGHT)   # from top-left, image space (x right, y down, z up)

def blur(a,r):
    im=Image.fromarray(np.clip(a*255,0,255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))
    return np.asarray(im).astype(np.float32)/255

def face_height(glyph_mask, size=360):
    """height map (0..1) for one face, 512x512 centred on the face"""
    g=np.zeros((512,512),np.float32)
    m=np.asarray(glyph_mask.resize((size,size),Image.LANCZOS)).astype(np.float32)/255
    o=(512-size)//2; g[o:o+size,o:o+size]=m
    yy,xx=np.mgrid[0:512,0:512]; r=np.hypot(xx-256+.5,yy-256+.5)
    # face: flat plateau with a rounded bevel down to the rim, plus a shallow groove ring
    face=np.clip((FACE_R-r)/14,0,1); face=face*face*(3-2*face)
    groove=0*r
    raised=blur(g,2.2)                       # soft shoulders on the glyph
    h=0.55*face - groove*face + 0.45*raised*face
    return h, g, face

def normals(h, strength):
    gy,gx=np.gradient(h)
    n=np.dstack([-gx*strength,-gy*strength,np.ones_like(h)])
    n/=np.linalg.norm(n,axis=2,keepdims=True)
    return n

def shade_face(bg, fg, glyph_mask):
    h,g,face=face_height(glyph_mask)
    n=normals(h,60)
    lam=np.clip((n*LIGHT).sum(2),0,1)
    flat=LIGHT[2]
    shade=(lam-flat)                           # 0 on flat areas, +/- on slopes
    bgc=np.array(bg,np.float32); fgc=np.array(fg,np.float32)
    gm=blur(g,0.8)[...,None]
    base=bgc*(1-gm)+fgc*gm
    # contact shadow at the glyph's foot (lower-right), like the moulded tokens
    sh=blur(np.roll(np.roll(g,9,0),8,1),6)*(1-g)
    col=base*(1+0.7*shade[...,None]) - 85*sh[...,None]
    # gentle top-left to bottom-right sheen across the face
    yy,xx=np.mgrid[0:512,0:512]
    sheen=1+0.03*(1-(xx+yy)/512.0)
    col=col*sheen[...,None]
    return np.clip(col,0,255), h

def glyph_colour(bg, fg):
    """tone-on-tone like the existing tokens: lighter tint of the base colour (dark tint if glyph is dark)"""
    if sum(fg)<200:
        return tuple(int(c*0.45) for c in bg)
    return tuple(int(c*0.62+255*0.38) for c in bg)

def build(key,name,icon,bg,fg):
    mask=mt.gi_mask(icon,mt.S)
    gcol=glyph_colour(bg,fg)
    face,h=shade_face(bg,gcol,mask)
    tex=np.zeros((N,N,3),np.float32); tex[:]=np.array(bg,np.float32)*0.92   # rim colour, a touch darker
    H=np.zeros((N,N),np.float32)
    yy,xx=np.mgrid[0:512,0:512]; circle=(np.hypot(xx-256+.5,yy-256+.5)<=FACE_R+2)[...,None]
    tex[0:512,0:512]=np.where(circle,face,tex[0:512,0:512]); H[0:512,0:512]=h
    tex[512:1024,0:512]=np.where(circle,face[::-1,::-1],tex[512:1024,0:512]); H[512:1024,0:512]=h[::-1,::-1]
    Image.fromarray(tex.astype(np.uint8)).save(f'{OUT}/token3dv2_{name.lower()}.png',optimize=True)
    n=normals(H,22)
    nm=((n*0.5+0.5)*255).astype(np.uint8)
    nm[...,1]=255-nm[...,1]       # image y is down; normal maps expect green = up (OpenGL/Unity)
    Image.fromarray(nm).save(f'{OUT}/token3dv2_{name.lower()}_normal.png',optimize=True)
    return tex

if __name__=='__main__':
    sheet=Image.new('RGB',(8*260,260),(30,30,30))
    for i,(key,name,des,icon,bg,fg) in enumerate(mt.KEYWORDS):
        tex=build(key,name,icon,bg,fg)
        f=Image.fromarray(tex[0:512,0:512].astype(np.uint8)).resize((240,240),Image.LANCZOS)
        cm=Image.new('L',(240,240),0); ImageDraw.Draw(cm).ellipse([2,2,237,237],fill=255)
        sheet.paste(f,(i*260+10,10),cm)
    sheet.save(f'{OUT}/preview3dv2.png'); print('ok')
