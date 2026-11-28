from PIL import Image, ImageDraw, ImageOps, ImageFont, ImageFilter
import numpy as np, os
T='/tmp'
OUT='art/powers'; os.makedirs(OUT,exist_ok=True)
base={s:Image.open(f'{T}/a_{s}_1.png').convert('RGBA') for s in 'nru'}
passive=Image.open(f'{T}/p_pass.png').convert('RGBA')
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',27)
cx,cy,r=128,160,69
disc=Image.new('L',(256,286)); ImageDraw.Draw(disc).ellipse((cx-r,cy-r,cx+r,cy+r),fill=255); disc=disc.filter(ImageFilter.GaussianBlur(1))
# coin: rows 0..62 from passive, only where the coin differs from the frame
coinmask=Image.new('L',(256,286)); ImageDraw.Draw(coinmask).ellipse((96,0,160,62),fill=255)
def art_disc(src, box):
    a=ImageOps.fit(Image.open(src).convert('RGBA').crop(box),(2*r,2*r),Image.LANCZOS)
    layer=Image.new('RGBA',(256,286)); layer.paste(a,(cx-r,cy-r)); return layer
def lock_layer():
    u=np.asarray(base['u']).astype(int)
    rgb=u[:,:,:3]; sat=rgb.max(2)-rgb.min(2)
    m=np.zeros(sat.shape,np.uint8)
    ys,xs=np.mgrid[0:286,0:256]
    inside=((xs-cx)**2+(ys-cy)**2)<(r-4)**2
    m[(sat>40)&inside]=255
    return base['u'], Image.fromarray(m).filter(ImageFilter.MaxFilter(3))
lockimg,lockmask=lock_layer()
def make(hid, src, box, prices, passive_only=False):
    layer=art_disc(src,box)
    states = ['n'] if passive_only else ['n','r','u']
    for s in states:
        img=base[s].copy()
        a=layer.copy()
        if s=='u': a=ImageOps.grayscale(a.convert('RGB')).convert('RGBA'); a.putalpha(layer.getchannel('A'))
        img.paste(a,(0,0),disc)
        if s=='u': img.paste(lockimg,(0,0),lockmask)
        if passive_only: img.paste(passive,(0,0),coinmask)
        for price in (['passive'] if passive_only else prices):
            out=img.copy()
            if price!='passive':
                d=ImageDraw.Draw(out)
                # hide the passive diamond and print the cost
                d.ellipse((117,29,139,55),fill=(222,168,58,255))
                d.text((128,42),str(price),font=font,anchor='mm',fill='white',stroke_width=3,stroke_fill=(40,25,10))
            out.save(f'{OUT}/{hid}_{s}_{price}.png',optimize=True)
make('S15_HERO_vanessa','hc/added-136100-strategic-edge.png',(176,148,336,308),range(0,6))
make('S15_HERO_eternus','hc/added-136237-dawn-of-the-infinite.png',(176,148,336,308),[],passive_only=True)
# hero power cards (300x430, like hover-rope/hero/<id>.png)
os.makedirs('art/hpcards',exist_ok=True)
for hid,src in [('S15_HERO_vanessa','hc/added-136100-strategic-edge.png'),('S15_HERO_eternus','hc/added-136237-dawn-of-the-infinite.png')]:
    im=Image.open(src).convert('RGBA'); im=im.crop(im.getbbox()); im=ImageOps.contain(im,(300,430),Image.LANCZOS)
    c=Image.new('RGBA',(300,430)); c.paste(im,((300-im.width)//2,(430-im.height)//2),im); c.save(f'art/hpcards/{hid}.png',optimize=True)
print(sorted(os.listdir(OUT)))
