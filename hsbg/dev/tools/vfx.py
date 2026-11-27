"""Render Hearthstone particle-system prefabs (top-down view, as on the board) into flipbook PNGs.
usage: vfx.py OUTDIR FRAMES FPS EXTENT_HS ROOT_GO [ROOT_GO...]  (bundle list inside)"""
import UnityPy, sys, os, glob, pickle, math, random
import numpy as np
from PIL import Image
UnityPy.config.FALLBACK_UNITY_VERSION = "6000.3.11f1"
W = '/mnt/user-data/uploads/Hearthstone/Data/Win/'
PREFABS = [W + 'initial_base_global-2ebe64b8-prefab-4.unity3d']
out, NF, FPS, EXT = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
roots = sys.argv[5:]
files = PREFABS + sorted(glob.glob(W + '*material*'))
env = UnityPy.load(*files)
TEX = pickle.load(open('/tmp/texidx.pkl', 'rb'))
texcache = {}
def texture(pid, name=None):
    if pid in texcache: return texcache[pid]
    im = None
    if pid in TEX:
        f, n = TEX[pid]
        e = UnityPy.load(f)
        for o in e.objects:
            if o.path_id == pid: im = o.read().image.convert('RGBA'); break
    texcache[pid] = im
    return im

# ---------- curves ----------
def hermite(keys, t):
    if not keys: return 1.0
    if t <= keys[0]['time']: return keys[0]['value']
    if t >= keys[-1]['time']: return keys[-1]['value']
    for a, b in zip(keys, keys[1:]):
        if a['time'] <= t <= b['time']:
            dt = b['time'] - a['time'] or 1e-6
            s = (t - a['time']) / dt
            m0, m1 = a.get('outSlope', 0) * dt, b.get('inSlope', 0) * dt
            if not all(map(math.isfinite, (m0, m1))): return a['value']
            h00, h10, h01, h11 = 2*s**3-3*s**2+1, s**3-2*s**2+s, -2*s**3+3*s**2, s**3-s**2
            return h00*a['value'] + h10*m0 + h01*b['value'] + h11*m1
    return keys[-1]['value']
def mmc(c, t=0.0, r=None):
    """MinMaxCurve sample: t in [0,1] normalized, r random in [0,1]."""
    if c is None: return 0.0
    st = c.get('minMaxState', 0); sc = c.get('scalar', 1.0)
    r = random.random() if r is None else r
    if st == 0: return sc
    if st == 3: lo = c.get('minScalar', sc); return lo + (sc - lo) * r
    mx = hermite(c['maxCurve']['m_Curve'], t) * sc
    if st == 1: return mx
    mn = hermite(c['minCurve']['m_Curve'], t) * sc
    return mn + (mx - mn) * r
def grad_eval(g, t):
    nc, na = g.get('m_NumColorKeys', 2), g.get('m_NumAlphaKeys', 2)
    ck = [(g['ctime%d' % i] / 65535, g['key%d' % i]) for i in range(nc)]
    ak = [(g['atime%d' % i] / 65535, g['key%d' % i]['a']) for i in range(na)]
    def lerp(keys, t, f):
        if t <= keys[0][0]: return f(keys[0][1])
        for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
            if t0 <= t <= t1:
                s = (t - t0) / ((t1 - t0) or 1e-6)
                a, b = np.array(f(v0)), np.array(f(v1)); return a + (b - a) * s
        return f(keys[-1][1])
    rgb = lerp(ck, t, lambda k: [k['r'], k['g'], k['b']]) if isinstance(ck[0][1], dict) else np.ones(3)
    a = lerp(ak, t, lambda v: v)
    return np.array(list(np.ravel(rgb)) + [float(np.ravel([a])[0])])
def mmg(g, t=0.0, r=None):
    st = g.get('minMaxState', 0); r = random.random() if r is None else r
    col = lambda c: np.array([c['r'], c['g'], c['b'], c['a']])
    if st == 0: return col(g['maxColor'])
    if st == 2: return col(g['minColor']) + (col(g['maxColor']) - col(g['minColor'])) * r
    if st == 1: return grad_eval(g['maxGradient'], t)
    if st == 3: return grad_eval(g['minGradient'], t) + (grad_eval(g['maxGradient'], t) - grad_eval(g['minGradient'], t)) * r
    return grad_eval(g['maxGradient'], r)

# ---------- prefab walk ----------
def comp(g, typ):
    for c in g.m_Component:
        ptr = c.component if hasattr(c, 'component') else c
        try:
            ob = ptr.deref()
            if ob.type.name == typ: return ob
        except Exception: pass
def systems(goname):
    res = []
    for o in env.objects:
        if o.type.name == 'GameObject' and o.peek_name() == goname:
            def walk(g, pos, scl, active=True):
                t = comp(g, 'Transform').read()
                lp, ls = t.m_LocalPosition, t.m_LocalScale
                p = pos + scl * np.array([lp.x, lp.y, lp.z]); s = scl * np.array([ls.x, ls.y, ls.z])
                ps = comp(g, 'ParticleSystem')
                if ps is not None and g.m_IsActive:
                    rr = comp(g, 'ParticleSystemRenderer')
                    res.append((g.m_Name, p, s, ps.read_typetree(), rr.read() if rr else None, rr.read_typetree() if rr else None))
                for ch in t.m_Children:
                    try: walk(ch.read().m_GameObject.read(), p, s)
                    except Exception: pass
            g = o.read(); walk(g, np.zeros(3), np.ones(3)); break
    return res

def material(r):
    if r is None: return None
    for m in r.m_Materials:
        try: mm = m.read()
        except Exception: continue
        tex = None
        for k, v in mm.m_SavedProperties.m_TexEnvs:
            if k == '_MainTex' and v.m_Texture.path_id: tex = v.m_Texture.path_id
        cols = {k: np.array([c.r, c.g, c.b, c.a]) for k, c in mm.m_SavedProperties.m_Colors}
        tint = cols.get('_TintColor', cols.get('_Color', np.ones(4)))
        if '_TintColor' in cols: tint = tint * 2.0   # legacy particle shaders double the tint
        return {'name': mm.m_Name, 'tex': tex, 'tint': np.clip(tint, 0, 4)}

# ---------- simulation ----------
def simulate(ps, pos, scl, mat, tt_r, frames, fps, rng):
    I, E, S = ps['InitialModule'], ps['EmissionModule'], ps['ShapeModule']
    dur = ps.get('lengthInSec', 1.0); delay = mmc(ps.get('startDelay'), 0, 0.5) if isinstance(ps.get('startDelay'), dict) else 0
    parts = []
    spawn_times = []
    if E.get('enabled', True):
        for b in E.get('m_Bursts', []):
            n = int(round(mmc(b.get('countCurve'), 0, rng.random()))) if 'countCurve' in b else int(b.get('minCount', 0))
            cyc = max(1, b.get('cycleCount', 1)); rep = b.get('repeatInterval', 0.01)
            for c in range(cyc): spawn_times += [b.get('time', 0) + c * rep] * n
        rate = mmc(E.get('rateOverTime'), 0, 0.5)
        if rate > 0:
            total = frames / fps
            k = 0.0
            while k < min(dur, total): spawn_times.append(k); k += 1.0 / rate
    maxp = I.get('maxNumParticles', 1000)
    spawn_times = sorted(spawn_times)[:maxp]
    shape_on = S.get('enabled', False); radius = S.get('radius', {}).get('value', S.get('radius', 1.0)) if isinstance(S.get('radius'), dict) else S.get('radius', 1.0)
    for st in spawn_times:
        t0 = st + delay
        tn = (st / dur) if dur else 0
        life = max(0.02, mmc(I['startLifetime'], tn, rng.random()))
        speed = mmc(I['startSpeed'], tn, rng.random())
        size = mmc(I['startSize'], tn, rng.random())
        col = mmg(I['startColor'], tn, rng.random())
        rot = mmc(I.get('startRotation'), tn, rng.random())
        ang = rng.random() * 2 * math.pi
        rad = (radius if shape_on else 0) * math.sqrt(rng.random())
        p0 = np.array([math.cos(ang) * rad, 0, math.sin(ang) * rad])
        d = np.array([math.cos(ang), 0, math.sin(ang)]) if shape_on else np.array([rng.uniform(-1, 1), 0, rng.uniform(-1, 1)])
        if not shape_on or S.get('type', 0) in (4, 8, 9):   # cone-ish: mostly upward (toward camera) with a spread
            spread = math.radians(S.get('angle', 25)) if shape_on else 0.3
            d = d * math.sin(spread * rng.random())
        parts.append(dict(t0=t0, life=life, p0=p0, v=d * speed, size=size, col=col, rot=rot, r=rng.random(), r2=rng.random()))
    SZ, CO, RO, UV = ps['SizeModule'], ps['ColorModule'], ps['RotationModule'], ps['UVModule']
    grav = mmc(I.get('gravityModifier'), 0, 0.5) if isinstance(I.get('gravityModifier'), dict) else 0
    res = []
    for f in range(frames):
        t = f / fps; layer = []
        for q in parts:
            age = t - q['t0']
            if age < 0 or age > q['life']: continue
            n = age / q['life']
            s = q['size'] * (mmc(SZ['curve'], n, q['r']) if SZ.get('enabled') else 1)
            c = q['col'] * (mmg(CO['gradient'], n, q['r']) if CO.get('enabled') else 1)
            a = q['rot'] + (mmc(RO['curve'], n, q['r2']) * age if RO.get('enabled') else 0)
            fr = None
            if UV.get('enabled'):
                tiles = UV.get('tilesX', 1) * UV.get('tilesY', 1)
                fr = int(mmc(UV['frameOverTime'], n, q['r']) * tiles) % max(1, tiles)
            p = pos + scl * (q['p0'] + q['v'] * age)
            layer.append((p[0], p[2], s * float(np.mean(scl[[0, 2]])), c, a, fr, UV.get('tilesX', 1), UV.get('tilesY', 1)))
        res.append(layer)
    return res

def splat(canvas, tex, x, z, size, col, ang, fr, tx, ty, tint):
    N = canvas.shape[0]
    px = int(size / EXT * N)
    if px < 2: return
    im = tex
    if fr is not None and (tx > 1 or ty > 1):
        w, h = im.width // tx, im.height // ty
        cx, cy = fr % tx, fr // tx
        im = im.crop((cx * w, cy * h, cx * w + w, cy * h + h))
    im = im.resize((px, px), Image.BILINEAR)
    if ang: im = im.rotate(math.degrees(ang), resample=Image.BILINEAR)
    a = np.asarray(im).astype(np.float32) / 255
    rgb = a[..., :3] * col[:3] * tint[:3]
    al = a[..., 3] * col[3] * min(1.0, tint[3])
    # additive: luminance carries coverage
    cx = int((x / EXT + .5) * N - px / 2); cy = int((.5 - z / EXT) * N - px / 2)
    x0, y0, x1, y1 = max(cx, 0), max(cy, 0), min(cx + px, N), min(cy + px, N)
    if x0 >= x1 or y0 >= y1: return
    sub = (slice(y0 - cy, y1 - cy), slice(x0 - cx, x1 - cx))
    canvas[y0:y1, x0:x1, :3] += rgb[sub] * al[sub][..., None]

os.makedirs(out, exist_ok=True)
rng = random.Random(7); random.seed(7)
layers = []
for rootname in roots:
    for name, pos, scl, ps, r, rt in systems(rootname):
        mat = material(r)
        tex = texture(mat['tex']) if mat and mat['tex'] else None
        if tex is None: print('skip (no texture)', name, mat and mat['name']); continue
        print('system', name, mat['name'], 'tex', TEX.get(mat['tex'], ('', '?'))[1], 'dur', ps.get('lengthInSec'))
        layers.append((simulate(ps, pos, scl, mat, rt, NF, FPS, rng), tex, mat['tint']))
N = 256
for f in range(NF):
    canvas = np.zeros((N, N, 3), np.float32)
    for sim, tex, tint in layers:
        for (x, z, s, c, a, fr, tx, ty) in sim[f]:
            splat(canvas, tex, x, z, s, c, a, fr, tx, ty, tint)
    lum = np.clip(canvas.max(-1), 0, None)
    alpha = np.clip(lum, 0, 1)
    rgb = np.where(lum[..., None] > 1e-4, canvas / np.maximum(lum[..., None], 1e-4), 0)
    rgb = np.clip(rgb, 0, 1)
    Image.fromarray((np.dstack([rgb, alpha]) * 255).astype(np.uint8)).save(f'{out}/{f + 1}.png')
print('frames', NF)
