"""Season 15 card data from Blizzard's card library API (hearthstone.blizzard.com), reconciled with the mod.
Writes v3data.lua (E.S15_DATA = {[id] = {text=, gtext=, tier=, atk=, hp=, gatk=, ghp=}}, E.S15_POOL = {...}) and review.txt.
Rules
- API text is used when it is complete (no blank number slots). Blizzard's API leaves some numbers blank and, when a text
  has several numbers, can shift a value into the wrong slot ("Activate (2): ... gain Gold." for "Activate (0): ... gain 2
  Gold."). When the API text has a blank, the mod text is kept if it matches the API wording apart from numbers.
- Plural templates "(time, times)" are resolved from the number before them.
"""
import json, re, sys, collections
api = json.load(open('api_cards.json'))
inv = json.load(open(sys.argv[1] if len(sys.argv) > 1 else 'inv227.json'))
MANUAL = json.load(open('manual.json')) if __import__('os').path.exists('manual.json') else {}

def norm(s): return re.sub(r'[^a-z0-9]', '', (s or '').lower())
def plural(t):
    def rep(m):
        n, a, b = m.group(1), m.group(2), m.group(3)
        return n + ' ' + (a if n.strip() in ('1', 'a', 'one') else b)
    def rep2(m):
        n, mid, a, b = m.group(1), m.group(2), m.group(3), m.group(4)
        return n + mid + ' ' + (a if n.strip().lower() in ('1', 'a', 'one') else b)
    t = re.sub(r'\b(\d+|a|one|two|three|four|six)((?:\s+[A-Za-z\-]+){0,2})\s*\(([A-Za-z]+), ?([A-Za-z]+)\)', rep2, t)
    return t
def clean(t):
    t = (t or '').replace('’', "'").replace('\xa0', ' ')
    t = re.sub(r'\s+', ' ', t).strip(); t = re.sub(r'(\w)- (\w)', r'\1-\2', t)
    return plural(t)
BLANK = re.compile(r'\(\s\)|\+\s/|/\+\s|\+ (Attack|Health)|Tier minion|\( left|spend Gold|by \.|gain Gold|\+\s\.|\+ /\+')
def blank(t): return bool(BLANK.search(t)) or '  ' in t
import difflib
SLOT = [(r'\(\s\)', '( # )'), (r'\+\s/\+\s', '+ # /+ # '), (r'\+\s/\+', '+ # /+ #'), (r'/\+\s', '/+ # '), (r'\+\s(Attack|Health)', r'+ # \1'), (r'Tier (minion)', r'Tier # \1'),
        (r'\(\s(left)', r'( # \1'), (r'spend Gold', 'spend # Gold'), (r'gain Gold', 'gain # Gold'), (r'\+\s\.', '+ # .')]
def tok(t): return re.findall(r"\d+|#|[A-Za-z][A-Za-z'\-]*|[^\sA-Za-z\d]", t)
def fill(modt, apit):
    """Fill the API's blank number slots with the numbers at the same place in the mod text."""
    a = apit
    for pat, rep in SLOT: a = re.sub(pat, rep, a)
    if '#' not in a: return None
    ta, tm = tok(a), tok(modt)
    key = lambda x: '#' if (x == '#' or x.isdigit()) else x.lower()
    sm = difflib.SequenceMatcher(None, [key(x) for x in ta], [key(x) for x in tm], autojunk=False)
    m = {}
    for blk in sm.get_matching_blocks():
        for j in range(blk.size): m[blk.a + j] = blk.b + j
    out = []
    for i, x in enumerate(ta):
        if x == '#' or (x.isdigit() and i in m and tm[m[i]].isdigit()):
            if i not in m or not tm[m[i]].isdigit(): return None
            out.append(tm[m[i]])
        else: out.append(x)
    r = ' '.join(out)
    r = re.sub(r' ([.,!:;)])', r'\1', r); r = re.sub(r'\( ', '(', r); r = re.sub(r'\+ (\d)', r'+\1', r); r = re.sub(r'/ \+', '/+', r)
    r = re.sub(r'\+(\d+) /\+', r'+\1/+', r); r = re.sub(r'(\d) -(\w)', r'\1-\2', r); r = re.sub(r'" (\w)', r'"\1', r); r = re.sub(r'(\w) "', r'\1"', r)
    r = re.sub(r'(\d) - (\w)', r'\1-\2', r); r = re.sub(r'"\s*([^"]*?)\s*"', r' "\1" ', r); r = re.sub(r'\s+', ' ', r).replace(' "', ' "').replace('" .', '".').strip()
    r = re.sub(r" ' ", "'", r); r = re.sub(r"(\w) '(\w)", r"\1'\2", r); r = re.sub(r' - ', ' - ', r)
    return r
def words(t): return re.sub(r'[^a-z]', '', re.sub(r'\d+', '', t.lower()))
def punct(t):  # mod text with API punctuation style "Taunt. Reborn" vs "Taunt Reborn" ignored
    return re.sub(r'[^a-z0-9]', '', t.lower())

A = {}
for r in api:
    if r['duos']: continue
    A.setdefault(norm(r['name']), []).append(r)

out, review, pool = {}, [], []
POOLAPI = {norm(r['name']) for r in api if r['type'] == 4 and not r['duos']}
for i in inv:
    if i['kind'] == 'token': continue
    rs = A.get(norm(i['name']))
    if not rs: continue
    r = rs[0]
    rec = {}
    def pick(field, modv, apiv):
        modv, apiv = clean(modv), clean(apiv)
        if not apiv: return None
        if punct(modv) == punct(apiv): return None                  # same
        if not blank(apiv):
            if words(modv) == words(apiv) and modv:
                review.append('%-28s %-24s %s\n      mod: %s\n      api: %s' % (i['id'], i['name'], field + ' numbers', modv, apiv))
            return apiv
        if words(modv) == words(apiv) and modv: return None          # api has blanks, same wording: keep mod numbers
        f2 = fill((clean(i.get('gtext')) if clean(i.get('gtext') or '') and clean(i.get('gtext')) != clean(i['text']) else clean(i['text'])) if field == 'gtext' else modv, apiv)
        if f2:
            review.append('%-28s %-24s %s FILLED\n      mod: %s\n      new: %s' % (i['id'], i['name'], field, modv, f2))
            return f2
        review.append('%-28s %-24s %s (api has blanks)\n      mod: %s\n      api: %s' % (i['id'], i['name'], field, modv, apiv))
        return None
    if i['id'] in MANUAL:
        rec.update(MANUAL[i['id']])
    t = pick('text', i['text'], r['text'])
    if t and 'text' not in rec: rec['text'] = t
    if r['gdbf'] and r['gtext']:
        g = pick('gtext', i.get('gtext') or i['text'], r['gtext'])
        if g and 'gtext' not in rec: rec['gtext'] = g
        elif not i.get('gtext') and 'gtext' not in rec and not blank(clean(r['gtext'])): rec['gtext'] = clean(r['gtext'])
    if i.get('minion'):
        for f, af in (('tier', 'tier'), ('atk', 'atk'), ('hp', 'hp')):
            if str(i[f]) != str(r[af]) and r[af] != '': rec[f] = int(r[af])
        if r['gdbf']:
            for f, af in (('gatk', 'gatk'), ('ghp', 'ghp')):
                if str(i.get(f)) != str(r[af]) and r[af] != '': rec[f] = int(r[af])
    if rec: out[i['id']] = rec
    if i['kind'] == 'pool' and norm(i['name']) in POOLAPI: pool.append(i['id'])
# the one pool minion the mod had outside its S15 pool
pool.append('BG25_013')

def lua(v):
    if isinstance(v, str): return '"' + v.replace('\\', '\\\\').replace('"', '\\"') + '"'
    return str(v)
lines = ['E.S15_DATA = {']
for k in sorted(out):
    lines.append('  [%s] = {%s},' % (lua(k), ', '.join('%s = %s' % (f, lua(v)) for f, v in sorted(out[k].items()))))
lines.append('}')
lines.append('E.S15_POOL = {' + ','.join(lua(x) for x in sorted(set(pool))) + '}')
open('v3data.lua', 'w').write('\n'.join(lines) + '\n')
open('review.txt', 'w').write('\n'.join(review) + '\n')
print('cards changed', len(out), 'pool', len(set(pool)), 'review', len(review))
print(collections.Counter(f for v in out.values() for f in v))
