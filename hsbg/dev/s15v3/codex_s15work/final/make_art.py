from PIL import Image, ImageDraw, ImageFilter, ImageOps
import shutil, os
ART='art'
HC='hc'
def rgba(p): return Image.open(p).convert('RGBA')
# --- full cards (365x514 like Codex' S15 cards) ---
SC=346/419
def card(src, out, bottom):
    im=rgba(src); w,h=im.size
    im=im.resize((round(w*SC),round(h*SC)),Image.LANCZOS)
    canvas=Image.new('RGBA',(365,514))
    x=8-round(46*SC); y=512-round(bottom*SC)
    canvas.alpha_composite(im,(x,y)) if x>=0 and y>=0 else canvas.paste(im,(x,y),im)
    canvas.save(out,optimize=True)
os.makedirs(f'{ART}/cards/n',exist_ok=True)
card(f'{HC}/added-132156-growing-ooze.png',f'{ART}/cards/n/S15_growing_ooze.png',629)
shutil.copy(f'{ART}/cards/n/S15_growing_ooze.png',f'{ART}/cards/g/S15_growing_ooze.png')
card(f'{HC}/added-132510-nzoth.png',f'{ART}/cards/n/S15_nzoth.png',646)
card(f'{HC}/added-132510-nzoth_golden.png',f'{ART}/cards/g/S15_nzoth.png',646)
# --- ovals: reuse Codex' frame aperture on an existing S15 oval ---
rows=[(19,144,161),(24,126,179),(36,102,205),(48,87,221),(60,75,232),(72,65,242),(84,59,250),(96,52,256),(108,47,261),(120,43,265),(132,39,269),(144,36,271),(156,34,273),(168,33,275),(180,32,275),(192,33,275),(204,34,274),(211,35,274),(212,42,274),(216,43,273),(228,46,271),(240,50,268),(252,55,265),(256,57,263),(258,58,257),(264,60,255),(276,66,252),(288,73,244),(300,82,234),(312,92,223),(324,103,208),(336,124,187),(341,137,175),(344,149,165)]
def window(size):
    m=Image.new('L',size); outline=[(l,y) for y,l,_ in rows]+[(r,y) for y,_,r in reversed(rows)]
    ImageDraw.Draw(m).polygon(outline,fill=255); return m.filter(ImageFilter.GaussianBlur(.55))
def oval(src, frame_src, out, box):
    frame=rgba(frame_src); win=window(frame.size)
    bb=win.getbbox()
    art=ImageOps.fit(rgba(src).crop(box),(bb[2]-bb[0],bb[3]-bb[1]),Image.LANCZOS)
    layer=Image.new('RGBA',frame.size); layer.paste(art,bb[:2])
    res=frame.copy(); res.paste(layer,(0,0),win); res.save(out,optimize=True)
# portrait boxes in the 512-wide hsbg.cards renders (oval artwork area)
oval(f'{HC}/added-132156-growing-ooze.png',f'{ART}/ovals/n/S15_sickly_ooze.png',f'{ART}/ovals/n/S15_growing_ooze.png',(150,70,372,330))
shutil.copy(f'{ART}/ovals/n/S15_growing_ooze.png',f'{ART}/ovals/g/S15_growing_ooze.png')
oval(f'{HC}/added-132510-nzoth.png',f'{ART}/ovals/n/S15_sickly_ooze.png',f'{ART}/ovals/n/S15_nzoth.png',(150,88,372,348))
oval(f'{HC}/added-132510-nzoth_golden.png',f'{ART}/ovals/g/S15_sickly_ooze.png',f'{ART}/ovals/g/S15_nzoth.png',(150,88,372,348))
# --- hero portraits 300x352 like polished/hero ---
for src,name in [('added-136099-vanessa-the-ringleader.png','S15_HERO_vanessa'),('added-136236-eternus.png','S15_HERO_eternus')]:
    im=rgba(f'{HC}/{src}'); im=im.crop(im.getbbox())
    im=ImageOps.contain(im,(300,352),Image.LANCZOS)
    c=Image.new('RGBA',(300,352)); c.paste(im,((300-im.width)//2,(352-im.height)//2),im)
    c.save(f'{ART}/heroes/{name}.png',optimize=True)
print('ok')
