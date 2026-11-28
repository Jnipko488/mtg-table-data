"""Season 15 completion patch, applied on top of the Codex Season 15 Gameplay save.

Input : cx/outputs/Battlegrounds Tavern - HS UI v18 - Season 15 Gameplay.json (Codex timewarp + minions, anchor fixed)
Output: /workspace/hsbg/TS_Save_226.json
"""
import json, re, sys, hashlib
from pathlib import Path

HERE = Path(__file__).resolve().parent
WORK = HERE.parent
SRC = WORK / "cx/outputs/Battlegrounds Tavern - HS UI v18 - Season 15 Gameplay.json"
DEST = Path("/workspace/hsbg/TS_Save_226.json")
ART = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/5e5931d3abec1a3ae33b0c350338c33a79b63197/hsbg/s15/"
SAVE_NAME = "Battlegrounds Tavern - HS UI v18 - Season 15 HS Cards"


class Script:
    def __init__(self, code):
        self.code = code

    def replace(self, old, new, count=1):
        n = self.code.count(old)
        if n != count:
            raise ValueError(f"Expected {count} match(es) for {old[:120]!r}, got {n}")
        self.code = self.code.replace(old, new)

    def insert_before(self, anchor, text):
        self.replace(anchor, text + anchor)

    def insert_after(self, anchor, text):
        self.replace(anchor, anchor + text)


def read(name):
    return (HERE / name).read_text(encoding="utf-8")


def spell_power(s):
    old = '''local function buffSpell(p, m, a, h)
    local extraAttack, extraHealth = E.spellBonuses(p)
    if a > 0 then a = a + extraAttack end
    if h > 0 then h = h + extraHealth end
    if p.s15SpellStatBonus and (a > 0 or h > 0) then
        a, h = a + p.s15SpellStatBonus, h + p.s15SpellStatBonus
    end
    buff(m, a, h)
end
'''
    s.replace(old, read("spellpower.lua"))
    # "this game" Tavern buffs keep the spell power they were cast with
    s.replace('''        if forever then
            local prior = p.tavBuff.all or {0, 0}
            p.tavBuff.all = {prior[1] + a, prior[2] + h}
        end''', '''        if forever then
            local prior = p.tavBuff.all or {0, 0}
            local boostedA, boostedH = E.spellAmount(p, a, h)
            p.tavBuff.all = {prior[1] + boostedA, prior[2] + boostedH}
        end''')
    s.replace('''    for _, race in ipairs(races) do
        local prior = p.tavBuff[race] or {0, 0}
        p.tavBuff[race] = {prior[1] + 3, prior[2] + 3}
    end''', '''    local boostedA, boostedH = E.spellAmount(p, 3, 3)
    for _, race in ipairs(races) do
        local prior = p.tavBuff[race] or {0, 0}
        p.tavBuff[race] = {prior[1] + boostedA, prior[2] + boostedH}
    end''')
    # attachments pass themselves to their end of turn trigger (captured spell power)
    s.replace('if f and f[hook] then invoke(f[hook], part.golden and 2 or 1) end',
              'if f and f[hook] then invoke(f[hook], part.golden and 2 or 1, part) end')
    s.replace('E.dispatchAttached(m,"endTurn",function(fn,k) fn(g,p,m,k) end)',
              'E.dispatchAttached(m,"endTurn",function(fn,k,part) fn(g,p,m,k,part) end)')
    # Blood Gems that also give a keyword
    s.replace('spell("BG20_GEM","any",function(g,p,m) E.applyGems(g,p,m,1); return true end)',
              '''spell("BG20_GEM","any",function(g,p,m,_,entry)
    E.applyGems(g,p,m,1)
    if entry and entry.gemKeyword and m and hasRace(m,"QUILBOAR") then m[entry.gemKeyword]=true end
    return true
end)''')
    # Draw: every spell text (shop, hand, hover, Discover, preview) comes from BG.spellText
    s.replace('''    local spell, m = BG.SPELLS[d.id], d.src or {}
    local text = spell.text or ""
    local status
    if d.lockTurn then status''', '''    local spell, m = BG.SPELLS[d.id], d.src or {}
    local text = BG.spellText(p, d.id, d.src) or spell.text or ""
    local status
    if d.lockGold then status = "Unlocks after " .. d.lockGold .. " more Gold spent"
    elseif d.lockTurn then status''')
    s.replace('''        text = ("Give a minion +%d/+%d."):format(p.gemA or 1, p.gemH or 1)''',
              '''        text = ("Give a minion +%d/+%d."):format(p.gemA or 1, p.gemH or 1)
        local kwName = ({taunt = "Taunt", shield = "Divine Shield", reborn = "Reborn"})[m.gemKeyword or ""]
        if kwName then text = text .. " If it's a Quilboar, also give it " .. kwName .. "." end''')
    s.replace('''    if (spell.pool or spell.s15Invocation) and text:find("%+%d+/%+%d+") then
        local a, h = BG.spellBonuses(p)
        if (a or 0) > 0 or (h or 0) > 0 then
            text = text:gsub("%+(%d+)/%+(%d+)", function(x, y) return "+" .. (x + a) .. "/+" .. (y + h) end, 1)
        end
    end
''', '''    -- Spell power is already applied to every number by Draw.spellState (BG.spellText).
''')


def season15_spells(s):
    s.replace('''    p.undeadAtk = p.undeadAtk + 8
    for _, list in ipairs({p.board, p.hand, p.tavern}) do
        for _, t in ipairs(list) do
            if hasRace(t, "UNDEAD") then buff(t, 8, 0); t.uAtk = (t.uAtk or 0) + 8 end''', '''    local gain = E.spellAmount(p, 8, 0)
    p.undeadAtk = p.undeadAtk + gain
    for _, list in ipairs({p.board, p.hand, p.tavern}) do
        for _, t in ipairs(list) do
            if hasRace(t, "UNDEAD") then buff(t, gain, 0); t.uAtk = (t.uAtk or 0) + gain end''')
    s.replace('spell("BG36_371", nil, function(_,p) E.deityBless(p,7,7); return true end)',
              'spell("BG36_371", nil, function(_,p) E.deityBless(p,E.spellAmount(p,7,7)); return true end)')
    s.insert_after('    spell("S15S_sanctify", nil, function(g, p) E.castSanctify(p); return true end)\n',
                   read("s15spells.lua"))


def cards(s):
    # Bristleback Bully (returning Tier 2 Quilboar) was missing entirely
    bully = ('BG_EXTRA["BG35_432"] = {id="BG35_432",name="Bristleback Bully",tier=2,atk=3,hp=2,races={"QUILBOAR"},'
             'all=false,text="Taunt. Deathrattle: Get a Blood Gem that also gives a Quilboar Taunt.",'
             'gtext="Taunt. Deathrattle: Get 2 Blood Gems that also give a Quilboar Taunt.",pool=false,legend=false,'
             'gatk=6,ghp=4,gid="BG35_432_G",fx="none",taunt=true,deathrattle=true,season=true}\n'
             f'BG_ART["BG35_432"] = {{n="{ART}hsjson/BG35_432.png",g="{ART}hsjson/BG35_432_G_triple.png"}}\n')
    line = re.search(r'^BG_EXTRA\["BG35_433"\] = .*\n', s.code, re.M).group(0)
    s.replace(line, line + bully)
    faces = re.search(r'^  \["BG35_433"\] = \{n=\{r=.*\n', s.code, re.M).group(0)
    s.replace(faces, faces + faces.replace('"BG35_433"', '"BG35_432"'))
    pool_line = re.search(r'^  \{key="s15",season=15,.*\n', s.code, re.M).group(0)
    assert '"BG35_432"' not in pool_line
    s.replace(pool_line, pool_line.replace('"BG35_433",', '"BG35_433","BG35_432",', 1))
    s.insert_before('    register("S15_great_wolf_cub",', read("s15cards.lua"))
    s.replace('''        if entry.id == "BG36_301t" or entry.id == "BG36_371" then
            E.castGeneratedSpell(g,p,entry.id)
            E.castGeneratedSpell(g,p,entry.id)
        end
        return true''', '''        if entry.id == "BG36_301t" or entry.id == "BG36_371" then
            E.castGeneratedSpell(g,p,entry.id)
            E.castGeneratedSpell(g,p,entry.id)
        end
        if entry.id == "S15_growing_ooze" then E.s15OozeDiscarded(g,p) end
        return true''')


def deities(s):
    s.replace('''        S.sacrificed = S.sacrificed or {}
''', '''        S.sacrificed = S.sacrificed or {}
        S.deityCount = (S.deityCount or #S.sacrificed) + 1
''')
    s.replace('if not C.g.deity or S.awoke or #(S.sacrificed or {}) < 4 or #S.list >= E.MAX_BOARD then return end',
              'if not C.g.deity or S.awoke or (S.deityCount or #(S.sacrificed or {})) < E.deityNeed(C.g.deity) or #S.list >= E.MAX_BOARD then return end')
    s.replace('local m=summon(C,S,C.g.deity,p and p.goldenDeity or false,nil,function(deity) buff(deity,a,h) end)',
              'local m=summon(C,S,C.g.deity,p and p.goldenDeity or false,C.g.season=="s15" and S.lastSacrificePos or nil,function(deity) buff(deity,a,h) end)')
    s.replace('                C_.recordSacrifice(C,S,m)\n',
              '                if hasRace(m,"ABERRATION") and not card(m.id).deity then S.lastSacrificePos=d.pos end\n'
              '                C_.recordSacrifice(C,S,m)\n')
    s.replace('for _,side in ipairs(C.sides) do sacrifices[side.n]=math.min(4,#(side.sacrificed or {})) end',
              'for _,side in ipairs(C.sides) do sacrifices[side.n]=math.min(E.deityNeed(C.g.deity),side.deityCount or #(side.sacrificed or {})) end')
    s.replace('for _,side in ipairs(C.sides) do result.final.sacrifices[side.n]=math.min(4,#(side.sacrificed or {})) end',
              'for _,side in ipairs(C.sides) do result.final.sacrifices[side.n]=math.min(E.deityNeed(g.deity),side.deityCount or #(side.sacrificed or {})) end')
    s.replace('g.deity=rnd(g,2)==1 and "BGFYM_000" or "BGFYM_011"',
              'if g.season=="s15" then g.deity=({"BGFYM_000","BGFYM_011","S15_nzoth"})[rnd(g,3)]\n'
              '            else g.deity=rnd(g,2)==1 and "BGFYM_000" or "BGFYM_011" end')
    s.replace('tip=text.."\\nFour friendly Aberration deaths awaken your Deity.",',
              'tip=text.."\\n"..BG.deityNeed(game.deity).." friendly Aberration deaths awaken your Deity.",')
    s.replace('labels={{text=count.."/4",x=deityLabel',
              'labels={{text=count.."/"..BG.deityNeed(game.deity),x=deityLabel')


def heroes(s):
    s.insert_before('HP["TB_BaconShop_HERO_16"] = {passive = true, -- A. F. Kay', read("s15heroes.lua"))
    # locked-by-Gold cards (Eternus)
    s.replace('        if plan.turn>g.turn or not handRoom(p) then spellPlans[#spellPlans+1]=plan',
              '        if plan.gold and E.goldLocked(p,plan) then plan.turn=g.turn+1 end\n'
              '        if (plan.gold and E.goldLocked(p,plan)) or (not plan.gold and plan.turn>g.turn) or not handRoom(p) then spellPlans[#spellPlans+1]=plan')
    s.replace('        if (plan.tier and plan.tier > p.tier) or (plan.turn and plan.turn > g.turn) then',
              '        if plan.gold and E.goldLocked(p, plan) then plan.turn = g.turn + 1 end\n'
              '        if (plan.gold and E.goldLocked(p, plan)) or (not plan.gold and ((plan.tier and plan.tier > p.tier) or (plan.turn and plan.turn > g.turn))) then')
    s.replace('            d.lockTier, d.lockTurn, d.combat = plan.tier, plan.turn, false',
              '            d.lockTier, d.lockTurn, d.combat = plan.tier, plan.turn, false\n'
              '            d.lockGold = plan.gold and math.max(0, plan.gold - (p.totalGoldSpent or 0)) or nil')
    s.replace('            d.spell,d.combat,d.lockTurn=true,false,plan.turn',
              '            d.spell,d.combat,d.lockTurn=true,false,plan.turn\n'
              '            d.lockGold=plan.gold and math.max(0,plan.gold-(p.totalGoldSpent or 0)) or nil')
    s.replace('    if d.lockTurn then return "Locked until Turn " .. d.lockTurn .. "\\n" .. details end',
              '    if d.lockGold then return "Locked until you spend " .. d.lockGold .. " more Gold\\n" .. details end\n'
              '    if d.lockTurn then return "Locked until Turn " .. d.lockTurn .. "\\n" .. details end')
    s.replace('        lines[#lines + 1] = d.lockTier and ("Locked until Tavern Tier " .. d.lockTier)',
              '        lines[#lines + 1] = d.lockGold and ("Locked until you spend " .. d.lockGold .. " more Gold")\n'
              '            or d.lockTier and ("Locked until Tavern Tier " .. d.lockTier)')
    s.replace('            local release = info.d.lockTier and ("Tavern Tier " .. info.d.lockTier) or ("Turn " .. info.d.lockTurn)',
              '            local release = info.d.lockGold and ("after " .. info.d.lockGold .. " more Gold is spent")\n'
              '                or info.d.lockTier and ("Tavern Tier " .. info.d.lockTier) or ("Turn " .. info.d.lockTurn)')
    # hero art, hero power medallions and hero power cards
    s.replace('local function heroArt(h)\n',
              'local function heroArt(h)\n'
              '    if h and Draw.s15Heroes[h.id] then return Draw.s15AssetRoot .. "heroes/" .. h.id .. ".png" end\n')
    s.replace('function Draw.newArt(path)\n',
              'function Draw.newArt(path)\n'
              '    local s15 = Draw.s15HeroAsset(path)\n'
              '    if s15 then return s15 end\n')
    s.replace('function Draw.powerState(g, p, h)\n',
              'function Draw.powerState(g, p, h)\n'
              '    if Draw.s15PowerText[h.id] then return Draw.s15PowerText[h.id](g, p, h) end\n')
    s.insert_before('function Draw.s15MinionAsset(id, golden, folder)\n', '''Draw.s15Heroes = {S15_HERO_vanessa = true, S15_HERO_eternus = true}
function Draw.s15HeroAsset(path)
    local dir, file = path:match("^(%a+)/(S15_HERO_.+)%.png$")
    if not dir then return nil end
    if dir == "hero" then return Draw.s15AssetRoot .. "hpcards/" .. (file:match("^(S15_HERO_%a+)") or file) .. ".png" end
    if dir == "power" then
        local hid, state, price = file:match("^(S15_HERO_%a+)_([nru])_(.+)$")
        if not hid then return nil end
        if price ~= "passive" then price = tostring(math.max(0, math.min(5, tonumber(price) or 0))) end
        return Draw.s15AssetRoot .. "powers/" .. hid .. "_" .. state .. "_" .. price .. ".png"
    end
end
Draw.s15PowerText = {
    S15_HERO_vanessa = function(g, p, h)
        local bought = p.vanessaTurn == g.turn and p.vanessaBought or 0
        local tier = math.min(g.maxTier or 6, 1 + bought)
        return "Discover a Tier " .. tier .. " minion. (Improved by each minion you've bought this turn!)", "Tier " .. tier
    end,
    S15_HERO_eternus = function(g, p, h)
        local left = math.max(0, BG.ETERNUS_GOLD - (p.totalGoldSpent or 0))
        return "Skip your first turn to visit the Major Timewarp instead. Lock cards you buy until you spend 45 Gold. ("
            .. left .. " left!)", left == 0 and "Unlocked" or (left .. " Gold left")
    end,
}
''')
    # Growing Ooze shows its current gift
    s.replace('    elseif id == "BG36_202" then',
              '    elseif id == "S15_growing_ooze" then\n'
              '        local a, h = BG.growingOoze(p)\n'
              '        lines[#lines + 1] = "If discarded: your minions and Deity +" .. a .. "/+" .. h\n'
              '    elseif id == "BG36_202" then')


def art(s):
    s.replace('Draw.s15AssetRoot = "file:///C:/Users/jadin/Documents/Codex/2026-11-27/c/outputs/Season15Art/"',
              f'Draw.s15AssetRoot = "{ART}"')


def main():
    save = json.loads(SRC.read_text(encoding="utf-8"))
    obj = next(o for o in save["ObjectStates"] if o.get("GUID") == "b9a001")
    s = Script(obj["LuaScript"])
    for step in (spell_power, season15_spells, cards, deities, heroes, art):
        step(s)
    obj["LuaScript"] = s.code
    save["SaveName"] = SAVE_NAME
    (HERE / "b9a001_226.lua").write_text(s.code, encoding="utf-8")
    DEST.write_text(json.dumps(save, indent=2, ensure_ascii=False), encoding="utf-8")
    print("wrote", DEST, len(s.code), hashlib.sha256(s.code.encode()).hexdigest()[:12])


if __name__ == "__main__":
    main()
