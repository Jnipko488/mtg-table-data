# Art routing for v3 (exec'd by build_v3.py; defines patch(s, replace)).
# 1. Every art.hearthstonejson.com fallback goes through Draw.hsjsonArt, which serves the copy mirrored in
#    Jnipko488/mtg-table-data (commit f98c7043, hsbg/hsjson/v1/...) when there is one.
# 2. Golden Season 15 art (real gold-frame renders) from the S15G commit, for new minions, Timewarp minions and changed cards.
import os
HERE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals() else '/home/claude/s15v3'
MIRROR = 'https://raw.githubusercontent.com/Jnipko488/mtg-table-data/fbcf3fa0ff59ecdf80b374e0b864c63204a47301/hsbg/hsjson/v1/'
S15G = open('/home/claude/s15v3/s15g_commit.txt').read().strip() if os.path.exists('/home/claude/s15v3/s15g_commit.txt') else None

def patch(s, replace):
    files = [l.strip() for l in open('/home/claude/s15v3/mirror_files.txt') if l.strip()]
    groups = {}
    for f in files:
        d, name = f.rsplit('/', 1)
        groups.setdefault(d, []).append(name)
    tbl = ',\n'.join('    [%r] = %r' % (d, ','.join(sorted(v))) for d, v in sorted(groups.items())).replace("'", '"')
    helper = '''Draw.HSJ_MIRROR_ROOT = "%s"
Draw.HSJ_MIRROR_LISTS = {
%s
}
Draw.HSJ_MIRROR = {}
for dir, names in pairs(Draw.HSJ_MIRROR_LISTS) do
    for name in names:gmatch("[^,]+") do Draw.HSJ_MIRROR[dir .. "/" .. name] = true end
end
Draw.HSJ_MIRROR_LISTS = nil
-- Card art from HearthstoneJSON, served from the copy in Jnipko488/mtg-table-data when it is mirrored there.
function Draw.hsjsonArt(rel)
    if Draw.HSJ_MIRROR[rel] then return Draw.HSJ_MIRROR_ROOT .. rel end
    return "https://art.hearthstonejson.com/v1/" .. rel
end
''' % (MIRROR, tbl)
    s = replace(s, 'function Draw.s15MinionAsset(id, golden, folder)\n', helper + 'function Draw.s15MinionAsset(id, golden, folder)\n')
    H = '"https://art.hearthstonejson.com/v1/bgs/latest/enUS/512x/" .. '
    s = replace(s, 'else return ' + H + '(hid or file:gsub("%.png$", "")) .. "p.png" end',
                'else return Draw.hsjsonArt("bgs/latest/enUS/512x/" .. (hid or file:gsub("%.png$", "")) .. "p.png") end')
    s = replace(s, '            return ' + H + 'file\n', '            return Draw.hsjsonArt("bgs/latest/enUS/512x/" .. file)\n')
    s = replace(s, '    return ' + H + 'id .. ".png"\nend\nfunction Draw.spellFaceFor(id)',
                '    return Draw.hsjsonArt("bgs/latest/enUS/512x/" .. id .. ".png")\nend\nfunction Draw.spellFaceFor(id)')
    s = replace(s, '    if Draw.HAVE_SHOP[key] then return Draw.recruitArt("shop/" .. key) end\n    return ' + H + 'id .. ".png"\n',
                '    if Draw.HAVE_SHOP[key] then return Draw.recruitArt("shop/" .. key) end\n    return Draw.spellArt(id)\n')
    s = replace(s, '(cloudArt("h", h.id) or ("https://art.hearthstonejson.com/v1/256x/" .. h.id .. ".jpg"))',
                '(cloudArt("h", h.id) or Draw.hsjsonArt("256x/" .. h.id .. ".jpg"))')
    s = replace(s, '        url = ' + H + '(gid and (gid .. "_triple") or id) .. ".png"\n',
                '        url = Draw.hsjsonArt("bgs/latest/enUS/512x/" .. (gid and (gid .. "_triple") or id) .. ".png")\n')
    s = replace(s, 'function Draw.questPainting(id) return "https://art.hearthstonejson.com/v1/512x/" .. id .. ".jpg" end',
                'function Draw.questPainting(id) return Draw.hsjsonArt("512x/" .. id .. ".jpg") end')
    if S15G:
        root = 'https://raw.githubusercontent.com/Jnipko488/mtg-table-data/%s/hsbg/s15/' % S15G
        s = replace(s, '''function Draw.s15MinionAsset(id, golden, folder)
    if folder == "cards" and id and Draw.s15Override[id] and game and game.season == "s15" then
        return Draw.s15AssetRoot .. "override/" .. id .. ".png"
    end''', '''Draw.s15GoldRoot = "%s"
Draw.s15Gold = Draw.s15Gold or {}
function Draw.s15MinionAsset(id, golden, folder)
    if folder == "cards" and id and Draw.s15Override[id] and game and game.season == "s15" then
        if golden and Draw.s15Gold["override/" .. id] then return Draw.s15GoldRoot .. "override/g/" .. id .. ".png" end
        return Draw.s15AssetRoot .. "override/" .. id .. ".png"
    end
    if golden and id and Draw.s15Gold[folder .. "/" .. id] then return Draw.s15GoldRoot .. folder .. "/g/" .. id .. ".png" end''' % root)
        listing = [l.strip() for l in open('/home/claude/s15v3/s15g_files.txt') if l.strip()]
        s = replace(s, 'Draw.s15GoldRoot = "%s"\n' % root,
                    'Draw.s15GoldRoot = "%s"\nDraw.s15Gold = {%s}\n' % (root, ','.join('["%s"]=true' % x for x in listing)))
    return s
