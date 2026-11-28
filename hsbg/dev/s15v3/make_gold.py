import json, re, os
from PIL import Image
TH = '/tmp/unf/HSBG_Season15_Unfinished/s15work/v3/thumbs/'
OUT = '/tmp/s15g/'
SC = 346/419
def card(src, out):  # same layout as s15work/v2/make_tw_art.py card()
    im = Image.open(src).convert('RGBA'); bottom = im.getbbox()[3]
    w, h = im.size
    im = im.resize((round(w*SC), round(h*SC)), Image.LANCZOS)
    canvas = Image.new('RGBA', (365, 514))
    x = 8-round(46*SC); y = 512-round(bottom*SC)
    canvas.paste(im, (x, y), im)
    canvas.save(out, optimize=True)
th = json.load(open('/tmp/unf/HSBG_Season15_Unfinished/s15work/v3/thumbs.json'))
api = json.load(open('api_cards.json'))
inv = {i['id']: i for i in json.load(open('inv227.json'))}
norm = lambda s: re.sub(r'[^a-z0-9]', '', s.lower())
bydbf = {}
for k, v in th.items():
    if v.get('g'): bydbf[str(v['dbf'])] = v['g']
api_by_name = {}
for r in api:
    if not r['duos']: api_by_name.setdefault(norm(r['name']), r)
s = open('b9a001_227.lua').read()
override = re.findall(r'\["([^"]+)"\] = true', s.split('Draw.s15Override = {')[1].split('}')[0])
made, missing = [], []
os.makedirs(OUT + 'cards/g', exist_ok=True); os.makedirs(OUT + 'override/g', exist_ok=True)
targets = [(cid, 'cards') for cid in inv if cid.startswith('S15_') and not cid.startswith('S15_tw_') and inv[cid].get('minion')]
targets += [(cid, 'override') for cid in override]
for cid, folder in targets:
    name = inv[cid]['name'] if cid in inv else None
    if not name:
        m = re.search(r'\["%s"\] = \{id="%s",name="([^"]+)"' % (re.escape(cid), re.escape(cid)), s); name = m and m.group(1)
    r = api_by_name.get(norm(name or ''))
    g = r and bydbf.get(str(r['dbf']))
    if not g or not os.path.exists(TH + g):
        missing.append((cid, name, r and r['gdbf'])); continue
    card(TH + g, OUT + folder + '/g/' + cid + '.png')
    made.append(folder + '/' + cid)
open('s15g_files.txt', 'w').write('\n'.join(made) + '\n')
print('made', len(made), 'missing', missing)
