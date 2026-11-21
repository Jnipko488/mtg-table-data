"""Build real 3D keyword tokens: the table's disc token mesh + the game-icons.net glyph extruded
out of the top face (like the moulded keyword tokens). Writes OBJ + matching texture per keyword."""
import json, re, math, importlib.util
import numpy as np
from svgpathtools import parse_path
from shapely.geometry import Polygon, MultiPolygon
from shapely.geometry.polygon import orient
from shapely.ops import unary_union
import mapbox_earcut as earcut
from PIL import Image, ImageDraw, ImageFilter

spec = importlib.util.spec_from_file_location('mt', '/home/claude/tok/make_tokens.py'); mt = importlib.util.module_from_spec(spec); spec.loader.exec_module(mt)
spec = importlib.util.spec_from_file_location('rl', '/home/claude/tok/relief.py'); rl = importlib.util.module_from_spec(spec); spec.loader.exec_module(rl)
ICONS = json.load(open('/home/claude/gi/pkg/package/icons.json'))
OUT = mt.OUT
BASE_OBJ = '/home/claude/tok/ref/token.obj'

TOP_Y = 0.068898          # flat top face of the disc
FACE_R = 0.738            # flat face radius (mesh units)
PX_R = 252.0              # face radius in texture pixels (1024 texture)
GLYPH_PX = 360            # glyph box size on the 512 face crop (matches relief.py)
HEIGHT = 0.068            # how far the icon stands out of the face
SIDE_UV = (0.62, 0.25)    # solid patch in the texture used for the icon's side walls
TOP_UV = (0.62, 0.75)     # solid patch for the icon's top


def icon_polys(name):
    """game-icons path -> shapely geometry in 512 svg units (even-odd fill)"""
    body = ICONS['icons'][name]['body']
    d = ' '.join(re.findall(r'\sd="([^"]+)"', body))
    path = parse_path(d)
    rings = []
    for sub in path.continuous_subpaths():
        L = max(sub.length(), 1e-6)
        n = max(12, int(L / 2.0))
        pts = [sub.point(t) for t in np.linspace(0, 1, n, endpoint=False)]
        ring = [(p.real, p.imag) for p in pts]
        if len(ring) >= 3:
            poly = Polygon(ring).buffer(0)
            if poly.area > 1.0: rings.append(poly)
    geom = None
    for r in rings:  # even-odd: xor every ring
        geom = r if geom is None else geom.symmetric_difference(r)
    geom = geom.buffer(0).simplify(0.6, preserve_topology=True)
    return geom


def to_mesh_xz(px, py):
    """svg units -> face texture pixel -> mesh x,z (see UV fit: u = .25 + x*k, v = .75 - z*k)"""
    o = (512 - GLYPH_PX) / 2.0
    fx = o + px * GLYPH_PX / 512.0
    fy = o + py * GLYPH_PX / 512.0
    return (fx - 256) * FACE_R / PX_R, (fy - 256) * FACE_R / PX_R


def uv_of(x, z):
    k = PX_R / 1024.0 / FACE_R
    return 0.25 + x * k, 0.75 - z * k


class Mesh:
    def __init__(self):
        self.v = []; self.vt = []; self.vn = []; self.f = []

    def add_v(self, p): self.v.append(p); return len(self.v)
    def add_vt(self, t): self.vt.append(t); return len(self.vt)
    def add_vn(self, n): self.vn.append(n); return len(self.vn)

    def tri(self, a, b, c):  # each a=(v,vt,vn)
        self.f.append((a, b, c))


def load_base(m):
    off_v = off_vt = off_vn = 0
    faces = []
    for line in open(BASE_OBJ):
        p = line.split()
        if not p: continue
        if p[0] == 'v': m.v.append(tuple(map(float, p[1:4])))
        elif p[0] == 'vt': m.vt.append(tuple(map(float, p[1:3])))
        elif p[0] == 'vn': m.vn.append(tuple(map(float, p[1:4])))
        elif p[0] == 'f':
            idx = [tuple(int(x) for x in q.split('/')) for q in p[1:]]
            for i in range(1, len(idx) - 1):
                m.f.append((idx[0], idx[i], idx[i + 1]))


def add_glyph(m, geom):
    polys = list(geom.geoms) if isinstance(geom, MultiPolygon) else [geom]
    y0, y1 = TOP_Y - 0.004, TOP_Y + HEIGHT
    up = m.add_vn((0, 1, 0))
    side_t = m.add_vt(SIDE_UV)
    for poly in polys:
        poly = orient(poly, 1.0)
        # svg y goes down; mesh z = svg y, so CCW in svg (x,y) is CW seen from +Y: fix winding per triangle
        rings = [list(poly.exterior.coords)[:-1]] + [list(r.coords)[:-1] for r in poly.interiors]
        flat = []; ends = []
        for r in rings:
            for (sx, sy) in r: flat.append(to_mesh_xz(sx, sy))
            ends.append(len(flat))
        arr = np.array(flat, dtype=np.float64)
        tris = earcut.triangulate_float64(arr, np.array(ends, dtype=np.uint32)).reshape(-1, 3)
        vid = [m.add_v((x, y1, z)) for (x, z) in flat]
        top_t = m.add_vt(TOP_UV)
        tid = [top_t for _ in flat]
        for a, b, c in tris:
            pa, pb, pc = arr[a], arr[b], arr[c]
            # normal of (b-a)x(c-a) in 3D with y up: ny = (bz-az)*(cx-ax) - (bx-ax)*(cz-az)
            ny = (pb[1] - pa[1]) * (pc[0] - pa[0]) - (pb[0] - pa[0]) * (pc[1] - pa[1])
            if ny < 0: b, c = c, b
            m.tri((vid[a], tid[a], up), (vid[b], tid[b], up), (vid[c], tid[c], up))
        # side walls
        start = 0
        for r_end in ends:
            ring = list(range(start, r_end)); start = r_end
            for i in range(len(ring)):
                ia, ib = ring[i], ring[(i + 1) % len(ring)]
                ax, az = arr[ia]; bx, bz = arr[ib]
                ex, ez = bx - ax, bz - az
                L = math.hypot(ex, ez)
                if L < 1e-9: continue
                nx, nz = ez / L, -ex / L
                mx, mz = (ax + bx) / 2 + nx * 1e-4, (az + bz) / 2 + nz * 1e-4
                # outward = pointing out of the solid
                from shapely.geometry import Point
                sx = (mx * PX_R / FACE_R + 256 - (512 - GLYPH_PX) / 2) * 512 / GLYPH_PX
                sy = (mz * PX_R / FACE_R + 256 - (512 - GLYPH_PX) / 2) * 512 / GLYPH_PX
                if poly.contains(Point(sx, sy)): nx, nz = -nx, -nz
                n = m.add_vn((nx, 0, nz))
                a0 = m.add_v((ax, y0, az)); b0 = m.add_v((bx, y0, bz))
                a1 = m.add_v((ax, y1, az)); b1 = m.add_v((bx, y1, bz))
                quad = [(a0, side_t, n), (b0, side_t, n), (b1, side_t, n), (a1, side_t, n)]
                # wind so that geometric normal matches n
                P = {a0: (ax, y0, az), b0: (bx, y0, bz), b1: (bx, y1, bz), a1: (ax, y1, az)}
                A, B, C = [np.array(P[q[0]]) for q in quad[:3]]
                g = np.cross(B - A, C - A)
                if g[0] * nx + g[2] * nz < 0: quad = quad[::-1]
                m.tri(quad[0], quad[1], quad[2]); m.tri(quad[0], quad[2], quad[3])


def write_obj(m, path):
    with open(path, 'w') as fh:
        fh.write('# Keyword token: table disc mesh + extruded game-icons.net glyph (CC BY 3.0)\n')
        for p in m.v: fh.write('v %.6f %.6f %.6f\n' % p)
        for t in m.vt: fh.write('vt %.6f %.6f\n' % t)
        for n in m.vn: fh.write('vn %.6f %.6f %.6f\n' % n)
        for f in m.f: fh.write('f ' + ' '.join('%d/%d/%d' % q for q in f) + '\n')


def glyph_tone(bg, fg):
    """flat tone-on-tone colour like the moulded tokens: a lighter shade of the disc (darker if the glyph was dark)"""
    if sum(fg) < 200:
        return tuple(int(c * 0.55) for c in bg)
    return tuple(int(c + (255 - c) * 0.32) for c in bg)


def texture(name, icon, bg, fg):
    """flat colours only: the game's lighting does all the shading (no painted shadows)"""
    g = glyph_tone(bg, fg)
    tex = Image.new('RGB', (1024, 1024), bg)
    d = ImageDraw.Draw(tex)
    for (u, v) in (TOP_UV, SIDE_UV):
        cx, cy = u * 1024, (1 - v) * 1024
        d.rectangle([cx - 70, cy - 70, cx + 70, cy + 70], fill=g)
    # underside keeps a flat printed icon so a flipped token is still readable
    m = mt.gi_mask(icon, 1024).resize((GLYPH_PX, GLYPH_PX), Image.LANCZOS).rotate(180)
    o = (512 - GLYPH_PX) // 2
    tex.paste(Image.new('RGB', (GLYPH_PX, GLYPH_PX), g), (o, 512 + o), m)
    tex.save(f'{OUT}/token3dm2_{name.lower()}.png', optimize=True)


if __name__ == '__main__':
    for key, name, des, icon, bg, fg in mt.KEYWORDS:
        m = Mesh(); load_base(m)
        add_glyph(m, icon_polys(icon))
        write_obj(m, f'{OUT}/token3dm2_{name.lower()}.obj')
        texture(name, icon, bg, fg)
        print(name, len(m.v), 'verts', len(m.f), 'tris')
