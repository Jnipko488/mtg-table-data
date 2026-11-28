import json, re, os, shutil
from PIL import Image, ImageDraw, ImageFilter, ImageOps
ART = 'art'
TH = 'tw/thumbs'
SC = 346/419
def rgba(p): return Image.open(p).convert('RGBA')
def card(src, out):
    im = rgba(src); bottom = im.getbbox()[3]
    w, h = im.size
    im = im.resize((round(w*SC), round(h*SC)), Image.LANCZOS)
    canvas = Image.new('RGBA', (365, 514))
    x = 8-round(46*SC); y = 512-round(bottom*SC)
    canvas.paste(im, (x, y), im)
    canvas.save(out, optimize=True)
rows=[(19,144,161),(24,126,179),(36,102,205),(48,87,221),(60,75,232),(72,65,242),(84,59,250),(96,52,256),(108,47,261),(120,43,265),(132,39,269),(144,36,271),(156,34,273),(168,33,275),(180,32,275),(192,33,275),(204,34,274),(211,35,274),(212,42,274),(216,43,273),(228,46,271),(240,50,268),(252,55,265),(256,57,263),(258,58,257),(264,60,255),(276,66,252),(288,73,244),(300,82,234),(312,92,223),(324,103,208),(336,124,187),(341,137,175),(344,149,165)]
def window(size):
    m = Image.new('L', size); outline = [(l,y) for y,l,_ in rows]+[(r,y) for y,_,r in reversed(rows)]
    ImageDraw.Draw(m).polygon(outline, fill=255); return m.filter(ImageFilter.GaussianBlur(.55))
FRAMES = {k: rgba(f'{ART}/ovals/{k}/S15_sickly_ooze.png') for k in 'ng'}
WIN = window(FRAMES['n'].size)
def oval(src, kind, out, box=(150,62,372,330)):
    frame = FRAMES[kind]; bb = WIN.getbbox()
    art = ImageOps.fit(rgba(src).crop(box), (bb[2]-bb[0], bb[3]-bb[1]), Image.LANCZOS)
    layer = Image.new('RGBA', frame.size); layer.paste(art, bb[:2])
    res = frame.copy(); res.paste(layer, (0,0), WIN); res.save(out, optimize=True)
def spell(src, out):
    im = rgba(src); bb = im.getbbox(); im = im.crop(bb)
    s = 428/im.width; im = im.resize((428, round(im.height*s)), Image.LANCZOS)
    c = Image.new('RGBA', (512, 776)); c.paste(im, (30, 72+(610-im.height)//2), im); c.save(out, optimize=True)
for d in ['cards/n','cards/g','ovals/n','ovals/g','twspells','override']:
    os.makedirs(f'{ART}/{d}', exist_ok=True)
data = json.load(open('v2/twdata.json'))
for c in data:
    files = c['files']
    n = [f for f in files if '_golden' not in f][0]
    g = ([f for f in files if '_golden' in f] or [n])[0]
    if c['kind'] == 'minion':
        card(f'{TH}/{n}', f"{ART}/cards/n/{c['id']}.png")
        card(f'{TH}/{g}', f"{ART}/cards/g/{c['id']}.png")
        oval(f'{TH}/{n}', 'n', f"{ART}/ovals/n/{c['id']}.png")
        oval(f'{TH}/{g}', 'g', f"{ART}/ovals/g/{c['id']}.png")
    else:
        spell(f'{TH}/{n}', f"{ART}/twspells/{c['id']}.png")
# overrides for changed cards (normal render; used for both normal and golden)
ch = json.load(open('v2/changed.json'))['art']
os.makedirs('tw/new', exist_ok=True)
for name, info in ch.items():
    f = info['files'][0]; i = info['ids'][0]
    src = f'tw/new/{f}'
    if not os.path.exists(src): continue
    if i.startswith('BG34_HeroPowerSpell') : spell(src, f"{ART}/override/{i}.png")
    else: card(src, f"{ART}/override/{i}.png")
print('done')
