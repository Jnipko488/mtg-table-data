"""Season 15 v2 patch: applied on top of TS_Save_226.json.
Adds the 81 new Timewarp cards, Timewarped Scroll, the changed-minion text/effects,
Eternus armor 18, Squirky +3/+3 always, spell power on Battlecruiser upgrades."""
import json, re, sys, os, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
W = os.path.dirname(HERE)
SRC = '/workspace/hsbg/TS_Save_226.json'
OUT = sys.argv[1] if len(sys.argv) > 1 else '/workspace/hsbg/TS_Save_227.json'
ART_SHA = sys.argv[2] if len(sys.argv) > 2 else 'ARTSHA'
OLD_ART = 'https://raw.githubusercontent.com/Jnipko488/mtg-table-data/5e5931d3abec1a3ae33b0c350338c33a79b63197/hsbg/s15/'
ART = f'https://raw.githubusercontent.com/Jnipko488/mtg-table-data/{ART_SHA}/hsbg/s15/'
SAVE_NAME = 'Battlegrounds Tavern - HS UI v18 - Season 15 HS Cards v2 (Timewarp)'

class Script:
    def __init__(self, code): self.code = code
    def replace(self, old, new, count=1):
        n = self.code.count(old)
        assert n == count, f'anchor matched {n} times, expected {count}: {old[:90]!r}'
        self.code = self.code.replace(old, new)
    def insert_before(self, anchor, text): self.replace(anchor, text + anchor)
    def insert_after(self, anchor, text): self.replace(anchor, anchor + text)

def lua_str(s): return json.dumps(s, ensure_ascii=False)
def double(text):
    text = re.sub(r'\+(\d+)/\+(\d+)', lambda m: f'+{2*int(m[1])}/+{2*int(m[2])}', text)
    text = re.sub(r'\+(\d+) (Attack|Health)', lambda m: f'+{2*int(m[1])} {m[2]}', text)
    return text

def defs_lua():
    data = json.load(open(os.path.join(HERE, 'twdata.json')))
    out = []
    for c in data:
        f = {}
        if c['kind'] == 'minion':
            t = c['text']
            for key, word in (('battlecry', 'Battlecry'), ('rally', 'Rally')):
                if word in t: f[key] = True
            if re.search(r'(^|\. |and )Deathrattle', t) or t.startswith('Deathrattle') or 'Deathrattle:' in t.split('"')[0]:
                f['deathrattle'] = True
            if c['id'] == 'S15_tw_graverobber': f.pop('deathrattle', None)
            f.update(c['kw'])
            if 'Activate' in t: f['activate'] = True
        flags = '{' + ','.join(f'{k}=true' for k in sorted(f)) + '}'
        if c['kind'] == 'minion':
            tribes = ['ALL'] if c['all'] else c['tribes']
            out.append('{id=%s,name=%s,tier=%d,cost=%d,kind="minion",atk=%d,hp=%d,races={%s},all=%s,tribes={%s},text=%s,gtext=%s,flags=%s}' % (
                lua_str(c['id']), lua_str(c['name']), c['pool'], c['cost'], c['atk'], c['hp'],
                ','.join(lua_str(r) for r in c['tribes']), 'true' if c['all'] else 'false',
                ','.join(lua_str(r) for r in tribes), lua_str(c['text']), lua_str(double(c['text'])), flags))
        else:
            out.append('{id=%s,name=%s,tier=%d,cost=%d,kind=%s,tribes={},text=%s,flags={}}' % (
                lua_str(c['id']), lua_str(c['name']), c['pool'], c['cost'], lua_str(c['kind']), lua_str(c['text'])))
    return '{\n        ' + ',\n        '.join(out) + '\n    }'

def pool_lua(code):
    names = json.load(open(os.path.join(W, 'tw_lists.json')))
    tw = {}
    block = code[code.index('BG_TIMEWARP = {'):]
    block = block[:block.index('\n}\n')]
    for m in re.finditer(r'\["([^"]+)"\]=\{tier=(\d),cost=\d,kind="[a-z]+",tribes=\{[^}]*\},immediate=(?:true|false),name="([^"]+)"', block):
        tw[(m[3], int(m[2]))] = m[1]
    for c in json.load(open(os.path.join(HERE, 'twdata.json'))):
        tw[(c['name'], c['pool'])] = c['id']
    tw[('Timewarped Scroll', 3)] = 'BG34_Treasure_610'
    ids, missing = [], []
    for key, tier in (('newminor', 3), ('retminor', 3), ('chgminor', 3), ('newmajor', 5), ('retmajor', 5), ('chgmajor', 5)):
        for n in names[key]:
            i = tw.get((n, tier))
            if i: ids.append(i)
            else: missing.append((key, n))
    assert not missing, missing
    assert len(ids) == len(set(ids))
    return 'E.S15_TIMEWARP_POOL = {' + ', '.join(f'{i} = true' if re.match(r'^[A-Za-z_]\w*$', i) else f'["{i}"] = true' for i in sorted(ids)) + '}\n', len(ids)

def read(name): return open(os.path.join(HERE, 'lua', name)).read()

def main():
    save = json.load(open(SRC))
    obj = next(o for o in save['ObjectStates'] if o.get('GUID') == 'b9a001')
    s = Script(obj['LuaScript'])

    # 1. Eternus: 18 Armor, live counter in the static text too
    s.replace('{id = "S15_HERO_eternus", name = "Eternus", hp = 30, armor = 10,',
              '{id = "S15_HERO_eternus", name = "Eternus", hp = 30, armor = 18,')
    s.replace('    text = "Skip your first turn to visit the Major Timewarp instead. Lock cards you buy until you spend 45 Gold."',
              '    text = "Skip your first turn to visit the Major Timewarp instead. Lock cards you buy until you spend 45 Gold. (45 left!)"')

    # 2. Spell power: per-card bonuses (Squirky) add +X/+X to every stat grant; Battlecruiser Upgrades scale.
    start = s.code.index('function E.spellPower(p, entry)')
    end = s.code.index('function E.setSpellText(id, template)')
    s.code = s.code[:start] + read('spellpower2.lua') + s.code[end:]
    s.replace('    if s then s.text = E.renderSpellTemplate(template, 0, 0) end', '    if s then s.text = E.renderSpellTemplate(template, 0, 0, 0) end')
    s.replace('--   E.spellAmount(p, a, h, entry) -> a and h after spell power (a 0 stays 0)',
              '--   E.spellAmount(p, a, h, entry) -> a and h after spell power (a 0 stays 0, except a per-card\n'
              '--                                    bonus such as Squirky\'s, which adds +X/+X to any stat grant)')
    s.replace('''    local gain = E.spellAmount(p, 8, 0)
    p.undeadAtk = p.undeadAtk + gain
    for _, list in ipairs({p.board, p.hand, p.tavern}) do
        for _, t in ipairs(list) do
            if hasRace(t, "UNDEAD") then buff(t, gain, 0); t.uAtk = (t.uAtk or 0) + gain end''',
    '''    local gain, gainHealth = E.spellAmount(p, 8, 0)
    p.undeadAtk = p.undeadAtk + gain
    for _, list in ipairs({p.board, p.hand, p.tavern}) do
        for _, t in ipairs(list) do
            if hasRace(t, "UNDEAD") then buff(t, gain, gainHealth); t.uAtk = (t.uAtk or 0) + gain end''')
    # Battlecruiser Upgrades go through spell power
    s.replace('''        if fam == "a" then buff(m, v, 0)
        elseif fam == "b" then buff(m, 0, v)
        elseif fam == "c" then m.cruiserYamato = (m.cruiserYamato or 0) + v
        elseif fam == "d" then m.cruiserRally = (m.cruiserRally or 0) + v
        elseif fam == "e" then m.cruiserDR = (m.cruiserDR or 0) + v; m.cruiserReactor = true''',
    '''        if fam == "a" then buff(m, E.spellAmount(p, v, 0))
        elseif fam == "b" then buff(m, E.spellAmount(p, 0, v))
        elseif fam == "c" then m.cruiserYamato = (m.cruiserYamato or 0) + v
        elseif fam == "d" then
            local a, h = E.spellAmount(p, v, 0)
            m.cruiserRally, m.cruiserRallyH = (m.cruiserRally or 0) + a, (m.cruiserRallyH or 0) + h
        elseif fam == "e" then
            local a, h = E.spellAmount(p, v, v)
            m.cruiserDRH = (m.cruiserDRH or m.cruiserDR or 0) + h
            m.cruiserDR = (m.cruiserDR or 0) + a; m.cruiserReactor = true''')
    s.replace('''            local v = m.cruiserRally or 0
            if v > 0 then for _, o in ipairs(alive(S.list, m)) do buff(o, v, 0) end end''',
    '''            local v, vh = m.cruiserRally or 0, m.cruiserRallyH or 0
            if v > 0 or vh > 0 then for _, o in ipairs(alive(S.list, m)) do buff(o, v, vh) end end''')
    s.replace('''            local v = m.cruiserDR or 0
            local first = alive(S.list, m)[1]
            if v > 0 and first then buff(first, v, v) end''',
    '''            local v = m.cruiserDR or 0
            local vh = m.cruiserDRH or v
            local first = alive(S.list, m)[1]
            if (v > 0 or vh > 0) and first then buff(first, v, vh) end''')

    # 3. Activations: expose registration and make Season-15-only ones season aware
    s.insert_before('    function E.activation(g, m)\n',
        '    E.registerActivation, E.registerDiscardActivation, E.ACTIVATE = activation, discardActivation, activate\n')
    s.replace('''        local def = m and activate[m.id]
        if not def then return nil end
        return def.cost, m.activatedTurn == g.turn''',
    '''        local def = m and activate[m.id]
        if not def or (def.season and def.season ~= g.season) then return nil end
        return def.cost, m.activatedTurn == g.turn''')
    # Muscle-o-Tron needs the magnetize target
    s.replace('        E.attachMagnetic(g, p, source, target, times)\n',
              '        E.attachMagnetic(g, p, source, target, times)\n        p.lastMagnetTarget = target\n')
    # Timewarped Duke: +4/+4 per card discarded this game
    s.replace('        elseif id=="BG36_524" then n,a,h=p.goldenPlayed,7,7\n',
              '        elseif id=="BG36_524" then n,a,h=p.goldenPlayed,7,7\n        elseif id=="S15_tw_duke" then n,a,h=p.discarded,4,4\n')
    # Hardlight: a Divine Shield prevented damage
    s.replace('''    if target.shield then
        if target.darkGift and target.darkGift.toreth''',
    '''    if target.shield then
        if C.g.season == "s15" and E.s15ShieldPrevented then E.s15ShieldPrevented(C, S, target, amount) end
        if target.darkGift and target.darkGift.toreth''')
    # Intrepid Botanist: +2 per choice in Season 15
    s.replace('''        function(_, p, _, k) p.bonusSpellAtk = (p.bonusSpellAtk or 0) + k end,
        function(_, p, _, k) p.bonusSpellHp = (p.bonusSpellHp or 0) + k end)''',
    '''        function(g, p, _, k) p.bonusSpellAtk = (p.bonusSpellAtk or 0) + k * (g and g.season == "s15" and 2 or 1) end,
        function(g, p, _, k) p.bonusSpellHp = (p.bonusSpellHp or 0) + k * (g and g.season == "s15" and 2 or 1) end)''')
    # Manasaber: Golden summons four 0/1 Cublings in Season 15
    s.replace('        for i = 1, 2 do summon(C, S, "BG26_800t", k > 1, pos + i - 1, function(m) m.taunt = true end) end',
              '''        if C.g.season == "s15" then
            for i = 1, 2 * k do summon(C, S, "BG26_800t", false, pos + i - 1, function(m) m.taunt = true end) end
            return
        end
        for i = 1, 2 do summon(C, S, "BG26_800t", k > 1, pos + i - 1, function(m) m.taunt = true end) end''')
    # Thundering Abomination: +6/+6 when an excess summon doesn't fit (Season 15)
    s.replace('            if o.hp > 0 and o.id == "BG30_124" then grow(o, 3 * mult(o)) end',
              '            if o.hp > 0 and o.id == "BG30_124" then grow(o, (C.g.season == "s15" and 6 or 3) * mult(o)) end')
    # New cards, changed cards, season patch (inside the Season 15 card block)
    core = read('tw_core.lua').replace('@@ART@@', ART).replace('@@DEFS@@', defs_lua())
    s.insert_before('    register("S15_great_wolf_cub", {bc = function(g, p, _, k) spells(g, p, GB, k) end})',
                    '    do\n' + core + '    end\n    do\n' + read('changed.lua') + '    end\n')
    s.insert_before('do\n    -- Recent combats for the leaderboard panel', read('late.lua'))
    # Murozond / Morchie powers also work as a second Hero Power
    s.replace('''        if g.turn==5 and id=="BG34_HERO_004" or g.turn==6 and g.timewarpEnabled and id~="BG34_HERO_004" then
            E.openTimewarp(g,p,3)
        elseif g.turn==8 and id=="BG34_HERO_000" or g.turn==9 and g.timewarpEnabled and id~="BG34_HERO_000" then''',
    '''        local morchie,murozond=E.hasPower(p,"BG34_HERO_004"),E.hasPower(p,"BG34_HERO_000")
        if g.turn==5 and morchie or g.turn==6 and g.timewarpEnabled and not morchie then
            E.openTimewarp(g,p,3)
        elseif g.turn==8 and murozond or g.turn==9 and g.timewarpEnabled and not murozond then''')
    # Season 15 Timewarp pool = the 37.2 lists
    pool, npool = pool_lua(s.code)
    s.insert_before('local timewarpCards = E.timewarpCards\n', pool)
    s.replace('''    if g.season ~= "s15" then return timewarpCards(g, tier, filter) end
    return timewarpCards(g, tier, function(d, id)''', '''    if g.season ~= "s15" then
        return timewarpCards(g, tier, function(d, id)
            if d.s15 then return false end -- Season 15 Timewarp cards
            return not filter or filter(d, id)
        end)
    end
    return timewarpCards(g, tier, function(d, id)''')
    s.replace('        if E.S15_TIMEWARP_REMOVED[id] then return false end',
              '        if not E.S15_TIMEWARP_POOL[id] then return false end')
    # Draw: Season 15 card art for changed cards
    ov = sorted(f[:-4] for f in os.listdir(os.path.join(W, 'art', 'override')))
    minions = [i for i in ov if not i.startswith('BG34_HeroPowerSpell')]
    sp = [i for i in ov if i.startswith('BG34_HeroPowerSpell')]
    s.replace('function Draw.s15MinionAsset(id, golden, folder)\n',
        'Draw.s15Override = {' + ', '.join(f'["{i}"] = true' for i in minions) + '}\n'
        'Draw.s15OverrideSpell = {' + ', '.join(f'["{i}"] = true' for i in sp) + '}\n'
        'function Draw.s15MinionAsset(id, golden, folder)\n'
        '    if folder == "cards" and id and Draw.s15Override[id] and game and game.season == "s15" then\n'
        '        return Draw.s15AssetRoot .. "override/" .. id .. ".png"\n'
        '    end\n')
    s.replace('function Draw.spellArt(id)\n',
        'function Draw.spellArt(id)\n'
        '    if Draw.s15OverrideSpell[id] and game and game.season == "s15" then return Draw.s15AssetRoot .. "override/" .. id .. ".png" end\n')
    s.replace('lines[#lines + 1] = "Beast summon bonus now +" .. (3 + (m.lev or 0)) * k .. " Attack"',
              'lines[#lines + 1] = "Beast summon bonus now +" .. ((game and game.season == "s15" and 2 or 3) + (m.lev or 0)) * k .. " Attack"')
    s.insert_after('function bgDebugReader(board, pos) return readerOf(board, pos) end   -- for tests\n',
                   'function bgDebugDraw() return Draw end   -- for tests\n')
    # Art root
    s.replace(f'Draw.s15AssetRoot = "{OLD_ART}"', f'Draw.s15AssetRoot = "{ART}"')

    obj['LuaScript'] = s.code
    save['SaveName'] = SAVE_NAME
    open(OUT, 'w').write(json.dumps(save, indent=2, ensure_ascii=False))
    open(os.path.join(HERE, 'b9a001_v2.lua'), 'w').write(s.code)
    print('wrote', OUT, 'timewarp pool', npool, 'overrides', len(minions), len(sp))

main()
