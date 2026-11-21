"""Render keyword token textures (for the disc mesh) and card icons (for πKeywords decals).
Icons: game-icons.net (Lorc, Delapouite and contributors), CC BY 3.0."""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
sys.path.insert(0, '/home/claude/gi')
from render import mask as gi_mask  # game-icons.net (CC BY 3.0) via @iconify-json/game-icons

S = 2048  # glyph canvas (supersampled)
OUT = '/home/claude/tok/out'
os.makedirs(OUT, exist_ok=True)


def P(x, y):
    return (x * S, y * S)


def blank():
    return Image.new('L', (S, S), 0)


def poly(d, pts, fill=255):
    d.polygon([P(*p) for p in pts], fill=fill)


def ell(d, cx, cy, r, fill=255, ry=None):
    ry = r if ry is None else ry
    d.ellipse([P(cx - r, cy - ry), P(cx + r, cy + ry)], fill=fill)


def ring(d, cx, cy, r, w):
    ell(d, cx, cy, r, 255)
    ell(d, cx, cy, r - w, 0)


def arc_band(d, cx, cy, r, w, a0, a1, fill=255, steps=90):
    """thick arc from angle a0 to a1 (degrees, 0=right, clockwise in image space)"""
    outer = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
             for a in [a0 + (a1 - a0) * i / steps for i in range(steps + 1)]]
    inner = [(cx + (r - w) * math.cos(math.radians(a)), cy + (r - w) * math.sin(math.radians(a)))
             for a in [a1 - (a1 - a0) * i / steps for i in range(steps + 1)]]
    poly(d, outer + inner, fill)


def rounded_rect(d, x0, y0, x1, y1, rad, fill=255):
    d.rounded_rectangle([P(x0, y0), P(x1, y1)], radius=rad * S, fill=fill)


# ---------------------------------------------------------------- glyphs (white = shape)
def g_ward():
    m = blank(); d = ImageDraw.Draw(m)
    ring(d, .5, .5, .34, .075)
    for a in range(0, 360, 45):  # eight rune spikes around the ring
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        L = .47 if a % 90 == 0 else .42
        w = .045 if a % 90 == 0 else .03
        px, py = -sa, ca
        poly(d, [(.5 + ca * .3 + px * w, .5 + sa * .3 + py * w), (.5 + ca * L, .5 + sa * L),
                 (.5 + ca * .3 - px * w, .5 + sa * .3 - py * w)])
    # inner diamond with a cut-out core
    poly(d, [(.5, .3), (.66, .5), (.5, .7), (.34, .5)])
    poly(d, [(.5, .42), (.56, .5), (.5, .58), (.44, .5)], 0)
    return m


def g_shroud():
    m = blank(); d = ImageDraw.Draw(m)
    # hood / veil arching over a closed eye
    arc_band(d, .5, .62, .36, .07, 180, 360)
    poly(d, [(.14, .62), (.21, .62), (.17, .82), (.1, .82)])
    poly(d, [(.79, .62), (.86, .62), (.9, .82), (.83, .82)])
    # closed eye: lower lid curve + lashes
    arc_band(d, .5, .46, .2, .055, 20, 160)
    for a in (40, 65, 90, 115, 140):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        bx, by = .5 + ca * .2, .46 + sa * .2
        px, py = -sa, ca
        w = .018
        poly(d, [(bx + px * w, by + py * w), (bx + ca * .11, by + sa * .11), (bx - px * w, by - py * w)])
    return m


def shield_pts(cx, top, w, h, steps=40):
    pts = [(cx - w, top), (cx + w, top), (cx + w, top + h * .38)]
    for i in range(steps + 1):
        t = i / steps
        a = math.radians(t * 90)
        pts.append((cx + w * math.cos(a), top + h * .38 + (h * .62) * math.sin(a)))
    for i in range(steps + 1):
        t = i / steps
        a = math.radians(90 + t * 90)
        pts.append((cx + w * math.cos(a), top + h * .38 + (h * .62) * math.sin(a)))
    pts.append((cx - w, top + h * .38))
    return pts


def g_protection():
    m = blank(); d = ImageDraw.Draw(m)
    poly(d, shield_pts(.5, .14, .3, .74))
    poly(d, shield_pts(.5, .2, .235, .62), 0)
    # cross inside
    poly(d, [(.455, .26), (.545, .26), (.545, .74), (.455, .74)])
    poly(d, [(.31, .4), (.69, .4), (.69, .49), (.31, .49)])
    return m


def drop(d, cx, cy, r, fill=255):
    ell(d, cx, cy, r, fill)
    poly(d, [(cx - r * .97, cy - r * .25), (cx, cy - r * 2.3), (cx + r * .97, cy - r * .25)], fill)


def g_infect():
    m = blank(); d = ImageDraw.Draw(m)
    drop(d, .46, .6, .22)
    ell(d, .4, .64, .065, 0)          # bubble
    ell(d, .52, .52, .035, 0)
    drop(d, .77, .4, .075)
    drop(d, .74, .74, .055)
    return m


def star4(d, cx, cy, R, r, fill=255, rot=0):
    pts = []
    for i in range(8):
        a = math.radians(rot + i * 45 - 90)
        rr = R if i % 2 == 0 else r
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    poly(d, pts, fill)


def g_prowess():
    m = blank(); d = ImageDraw.Draw(m)
    star4(d, .44, .55, .34, .085)
    star4(d, .76, .25, .14, .04)
    star4(d, .78, .72, .09, .028)
    return m


def tombstone(d, fill=255):
    rounded = [(.24, .86), (.24, .4)]
    steps = 40
    for i in range(steps + 1):
        a = math.radians(180 + 180 * i / steps)
        rounded.append((.5 + .26 * math.cos(a), .4 + .26 * math.sin(a)))
    rounded += [(.76, .4), (.76, .86)]
    poly(d, rounded, fill)
    poly(d, [(.16, .82), (.84, .82), (.84, .9), (.16, .9)], fill)  # base slab


def g_undying():
    m = blank(); d = ImageDraw.Draw(m)
    tombstone(d)
    # up arrow cut out
    poly(d, [(.5, .22), (.65, .42), (.56, .42), (.56, .72), (.44, .72), (.44, .42), (.35, .42)], 0)
    return m


def g_persist():
    m = blank(); d = ImageDraw.Draw(m)
    tombstone(d)
    # circular return arrow cut out
    arc_band(d, .5, .52, .17, .06, 200, 470, 0)
    a = math.radians(200)
    bx, by = .5 + .14 * math.cos(a), .52 + .14 * math.sin(a)
    poly(d, [(bx - .09, by - .02), (bx + .07, by - .03), (bx - .01, by + .12)], 0)
    return m


def g_shield():
    m = blank(); d = ImageDraw.Draw(m)
    ring(d, .5, .5, .38, .07)
    ring(d, .5, .5, .26, .04)
    ell(d, .5, .5, .1)
    for a in range(0, 360, 60):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        ell(d, .5 + ca * .345, .5 + sa * .345, .022, 0)
    return m


KEYWORDS = [
    # key, name, description, glyph, token bg, token glyph colour
    ('mtg_wardcounter', 'Ward', "Whenever this becomes the target of a spell or ability an opponent controls, counter it unless that player pays the ward cost.", "magic-palm", (25, 163, 154), (255, 255, 255)),
    ('mtg_shroudcounter', 'Shroud', "This permanent can't be the target of spells or abilities.", "hood", (91, 95, 107), (238, 238, 238)),
    ('mtg_protectioncounter', 'Protection', "Protection from a quality: can't be blocked, targeted, dealt damage, enchanted or equipped by anything with that quality.", "cross-shield", (238, 186, 36), (255, 255, 255)),
    ('mtg_infectcounter', 'Infect', "This deals damage to creatures in the form of -1/-1 counters and to players in the form of poison counters.", "biohazard", (128, 194, 26), (24, 24, 24)),
    ('mtg_prowesscounter', 'Prowess', "Whenever you cast a noncreature spell, this creature gets +1/+1 until end of turn.", "fist", (214, 64, 141), (255, 255, 255)),
    ('mtg_undyingcounter', 'Undying', "When this creature dies, if it had no +1/+1 counters on it, return it to the battlefield with a +1/+1 counter on it.", "raise-zombie", (74, 52, 38), (243, 231, 201)),
    ('mtg_persistcounter', 'Persist', "When this creature dies, if it had no -1/-1 counters on it, return it to the battlefield with a -1/-1 counter on it.", "cycle", (82, 62, 116), (233, 224, 248)),
    ('mtg_shieldcounter', 'Shield', "If this would be dealt damage or destroyed, instead remove a shield counter from it.", "round-shield", (98, 132, 168), (255, 255, 255)),
]


def glyph_layer(mask, size, color, shadow=True, shadow_off=(0.018, 0.022), shadow_blur=0.012, shadow_alpha=200):
    """RGBA image of the glyph in colour with a soft dark drop shadow, size x size"""
    m = mask.resize((size, size), Image.LANCZOS)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if shadow:
        sh = Image.new('L', (size, size), 0)
        sh.paste(m, (int(shadow_off[0] * size), int(shadow_off[1] * size)))
        sh = sh.filter(ImageFilter.GaussianBlur(shadow_blur * size))
        sh = sh.point(lambda v: v * shadow_alpha // 255)
        out.paste(Image.new('RGBA', (size, size), (0, 0, 0, 255)), (0, 0), sh)
    col = Image.new('RGBA', (size, size), color + (255,))
    out.alpha_composite(Image.composite(col, Image.new('RGBA', (size, size), (0, 0, 0, 0)), m))
    return out


def token_texture(mask, bg, fg, size=330):
    tex = Image.new('RGBA', (1024, 1024), bg + (255,))
    g = glyph_layer(mask, size, fg)
    # top face: circle centred (256,256) r=252; bottom face centred (256,768), same art turned 180°
    tex.alpha_composite(g, (256 - size // 2, 256 - size // 2))
    tex.alpha_composite(g.rotate(180), (256 - size // 2, 768 - size // 2))
    return tex.convert('RGB')


def icon_image(mask, bg):
    dark = tuple(int(c * .5 + 30 * .5) for c in bg)
    light = tuple(int(c * .3 + 255 * .7) for c in bg)
    img = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    sq = Image.new('L', (512 * 4, 512 * 4), 0)
    ImageDraw.Draw(sq).rounded_rectangle([0, 0, 512 * 4 - 1, 512 * 4 - 1], radius=48 * 4, fill=255)
    sq = sq.resize((512, 512), Image.LANCZOS)
    img.paste(Image.new('RGBA', (512, 512), dark + (255,)), (0, 0), sq)
    g = glyph_layer(mask, 400, light, shadow_alpha=170)
    img.alpha_composite(g, (56, 56))
    return img


if __name__ == '__main__':
    sheet = Image.new('RGB', (8 * 260, 3 * 260), (45, 45, 45))
    for i, (key, name, des, fn, bg, fg) in enumerate(KEYWORDS):
        mask = gi_mask(fn, S)
        slug = name.lower()
        tex = token_texture(mask, bg, fg)
        tex.save(f'{OUT}/token_{slug}.png', optimize=True)
        icon = icon_image(mask, bg)
        icon.save(f'{OUT}/icon_{slug}.png', optimize=True)
        # preview: round token face, bottom face, icon
        face = tex.crop((4, 4, 508, 508)).resize((240, 240), Image.LANCZOS)
        cm = Image.new('L', (240, 240), 0); ImageDraw.Draw(cm).ellipse([0, 0, 239, 239], fill=255)
        sheet.paste(face, (i * 260 + 10, 10), cm)
        bface = tex.crop((4, 516, 508, 1020)).resize((240, 240), Image.LANCZOS)
        sheet.paste(bface, (i * 260 + 10, 270), cm)
        sheet.paste(icon.resize((240, 240), Image.LANCZOS), (i * 260 + 10, 530), icon.resize((240, 240), Image.LANCZOS))
    sheet.save(f'{OUT}/preview.png')
    print('done')
