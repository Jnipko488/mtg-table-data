import hashlib
import json
from pathlib import Path


SLOT = Path("/nonexistent")
BACKUP = Path("work/TS_Save_225.before-season15-gameplay.json")
DEST = Path("outputs/Battlegrounds Tavern - HS UI v18 - Season 15 Gameplay.json")


class Script:
    def __init__(self, code):
        self.code = code

    def replace(self, old, new):
        if self.code.count(old) != 1:
            raise ValueError(f"Expected one match for {old[:110]!r}, got {self.code.count(old)}")
        self.code = self.code.replace(old, new, 1)

    def insert_before(self, anchor, text):
        self.replace(anchor, text + anchor)


def timewarp(s):
    s.replace('    return def.kind == "minion" and Draw.HSOVAL and Draw.HSOVAL[id] and true or false',
              '    return def.kind == "minion"')
    s.replace('    return (Draw.HSTWSPELL[id] or Draw.HSTWPOWER[id]) and true or false',
              '    return true')
    slug = '    return "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/d9038fe6b7334ddaa6d30362a070e4c4db634236/hsbg/battlegrounds-multiplayer/s14-leaderboard/spellshop/" .. id .. "_tw.png"'
    s.replace(slug, '    if Draw.HSTWSPELL[id] then\n    ' + slug + '\n    end')
    s.replace('d.combat, d.warpIndex = false, i\n                    list', 'd.combat, d.warpIndex, d.warpVisit = false, i, visit\n                    list')
    s.replace('d.combat, d.warpIndex, d.spell, d.warp = false, i, true, true',
              'd.combat, d.warpIndex, d.warpVisit, d.spell, d.warp = false, i, visit, true, true')
    start = s.code.index('        local c = BG_CARDS[o.id]\n', s.code.index('function Draw.timewarpRow('))
    stop = s.code.index('    ensureTile(color,"skip"', start)
    s.replace(s.code[start:stop], '''        if not o.taken then
            ensureTile(color, "b_pkcoin" .. i, {url = Draw.patchArt("timewarp/chronum-" .. o.cost), face = {r = 1}, size = .56,
                right = right, near = near - .49 * UNIT_H - .62, layer = 9, lift = lift + .45,
                tip = o.canBuy and "Drag to your hand to buy" or ("Requires " .. o.cost .. " Chronum")})
        end
    end
''')
    s.insert_before('local function resolveDrop(color, obj, info, releasePosition, viaHand)\n', '''-- A Timewarp visit blocks ordinary recruit actions. Its own offers remain draggable.
function Draw.activeWarpOffer(p, info)
    local visit, d = p and p.timewarpVisit, info.d
    local slot = visit and d and d.warpVisit == visit and visit.slots[d.warpIndex]
    return slot and not slot.taken and slot.id == d.id
end

''')
    s.replace('''    local p = actorFor(color, owner)
    if not p then return syncSeat(owner, guid) end
    local board, bob = boardOf(owner), bobOf(owner)''',
              '''    local warp = info.key:sub(1, 1) == "w"
    local p
    if warp then
        p = color == owner and game.players[owner]
        if not p or p.bot or not p.alive or not Draw.activeWarpOffer(p, info) then return syncSeat(owner, guid) end
    else
        p = actorFor(color, owner)
        if not p then return syncSeat(owner, guid) end
    end
    local board, bob = boardOf(owner), bobOf(owner)''')
    s.replace('    if kind == "w" then\n        if info.d and info.d.warpIndex and (inPlayerHand or (onBoard and near > -0.6)) then',
              '    if warp then\n        if inPlayerHand or (onBoard and near > -0.6) then')
    s.replace('            if Draw.pendingChoice(p) and not Draw.activationTargetIndex(p, info) then return false end',
              '''            if Draw.pendingChoice(p) and not Draw.activeWarpOffer(p, info)
                and not Draw.activationTargetIndex(p, info) then return false end''')
    s.replace('    if not current or current.held_by_color or (location ~= "tavern" and location ~= "spellshop") then return end',
              '''    local p = game.players[info.color]
    if not current or current.held_by_color then return end
    if location ~= "tavern" and location ~= "spellshop" and not Draw.activeWarpOffer(p, info) then return end''')
    s.replace('    local details=cardText(d.id,d.golden,d.atk,d.hp)',
              '    local details=cardText(d.id,d.golden,d.atk,d.hp)\n    if d.warpIndex then details = "Buy by dragging toward your hand.\\n" .. details end')


def minions(s):
    cards = Path("work/s15_minions.lua").read_text(encoding="utf-8")
    s.insert_before('    register("S15_great_wolf_cub",', cards)
    s.insert_before('    activation("S15_graveyard_skulker"', '''    activation("S15_crooked_banker", 1, function(_, p, _, k)
        E.s15DiscountShop(p, k)
        return true
    end)
    activation("S15_cunning_chameleon", 2, E.s15ChooseDeathrattle)
    activation("S15_shambling_shadowfiend", 0, function(g, p, _, k, target)
        return E.s15DiscardNeighbors(g, p, target, k)
    end, function() return true end, "hand")
    activation("S15_squirky", 0, function(_, _, _, k, target)
        target.s15StatBonus = (target.s15StatBonus or 0) + 3 * k
        return true
    end, function(_, _, target) return E.s15CanImproveSpell(target) end, "hand")
''')
    s.replace('    activation("S15_cunning_chameleon", 2, E.s15ChooseDeathrattle)',
              '    activation("S15_cunning_chameleon", 2, function(...) return E.s15ChooseDeathrattle(...) end)')
    s.insert_before('    if p.discover.kind == "activate_target" then return E.pickActivation(g,p,i) end',
                    '    if p.discover.s15Effect then return E.s15ChooseEffect(g, p, i) end\n')
    s.replace('    local cost=E.trinketMinionCost(p,m,(card(m.id).fixedCost or E.buyCost(p)),g.turn)',
              '    local cost = E.s15MinionPrice(p, m, g.turn)')
    s.insert_before('    E.purchaseCardActions(g, p, m)\n', '''    m.s15Discount = nil
    if card(m.id).battlecry then p.s15NextBattlecry = nil end
''')
    s.replace('    return math.max(0,s.cost-(p.spellDiscount or 0)-(p.darkmoonSpellCut or 0)-E.timewarpSpellDiscount(p)),false',
              '''    return math.max(0, (entry.s15PriceOverride or s.cost) - (entry.s15Discount or 0)
        - (p.spellDiscount or 0) - (p.darkmoonSpellCut or 0) - E.timewarpSpellDiscount(p)), false''')
    s.insert_before('    table.insert(p.spellHand, entry)\n    E.raiseHandGained(g, p)\n    if p.doubleHeader',
                    '    entry.s15Discount, entry.s15PriceOverride = nil, nil\n')
    s.insert_before('        optional("start of turn effect", p, hooks, "startTurn")',
                    '        E.s15AfterShopRoll(g, p)\n')
    s.insert_before('        p.counters.bought, p.counters.piratesBought, p.counters.elementals = 0, 0, 0',
                    '        p.s15TavernSpellsTurn = 0\n')
    s.insert_before('        for _,m in ipairs(p.tavern) do clearTemp(m);E.expireAshen(m) end',
                    '        for _, m in ipairs(p.board) do m.s15Deathrattles = nil; E.s15MarkKeywords(m) end\n')
    s.insert_before('        E.spellStartTurn(g, p)\n', '        E.s15ObserveKeywords(g, p)\n')
    s.insert_before('    E.expireSpellcraft(g,p)\n    for _=1,p.darkmoonReturnCoin', '    E.s15ObserveKeywords(g, p)\n')
    s.insert_before('    if id=="BG36_360" then E.initParadox(g,m) end\n    return m',
                    '    if g.season == "s15" then E.s15MarkKeywords(m) end\n')
    s.insert_before('    table.insert(p.board,pos,m)\n    E.bindStatCard(p,m)',
                    '    if g.season == "s15" then E.s15MarkKeywords(m) end\n')
    s.replace('    return m\nend\n\nE.shopSummon = shopSummon',
              '    E.s15Summon(g, p, m)\n    return m\nend\n\nE.shopSummon = shopSummon')
    s.insert_before('    E.recordMinionPlayed(g,p,m)\n', '    E.s15ObserveKeywords(g, p)\n')
    s.insert_before('        p.battlecries=(p.battlecries or 0)+1\n        E.refreshGiftAuras',
                    '        E.s15ObserveKeywords(g, p)\n')
    s.replace('    if #S.list >= E.MAX_BOARD then return nil end\n    local fresh=E.newMinion(C.g,id,golden)',
              '    if #S.list >= E.MAX_BOARD then E.s15ExcessSummon(C, S); return nil end\n    local fresh=E.newMinion(C.g,id,golden)')
    s.insert_before('    pos = math.max(1, math.min(pos or (#S.list + 1), #S.list + 1))\n',
                    '    if C.g.season == "s15" then E.s15MarkKeywords(m) end\n')
    s.replace('    return m\nend\nC_.summon = summon',
              '    E.s15Summon(C.g, p, m, C, S)\n    return m\nend\nC_.summon = summon')
    s.insert_before('    if m.id=="BG21_015" then C_.keep(C,m,mult(m)) end\n',
                    '    if C.g.season == "s15" then E.s15MarkKeywords(m) end\n')
    s.insert_before('        target.shield = false\n        C.fx="shield_break"',
                    '        E.s15ObserveKeywords(C.g, ownerOf(C,S), C, S)\n')
    s.insert_before('        return 0\n    end\n    target.hp = target.hp - amount',
                    '        E.s15ObserveKeywords(C.g, ownerOf(C,S), C, S)\n')
    s.replace('    if f and f.damaged then f.damaged(C, S, target, mult(target)) end',
              '    if f and f.damaged then f.damaged(C, S, target, mult(target), amount) end')
    s.insert_before('    dealDamage(C, enemy, target, target.resilient and math.ceil(aAtk / 2) or aAtk, attacker)',
                    '    E.s15ObserveKeywords(C.g, ownerOf(C,S), C, S)\n    E.s15ObserveKeywords(C.g, ownerOf(C,enemy), C, enemy)\n')
    s.replace('    local aAtk,tAtk=attacker.atk,target.atk\n    local hpBefore, hadShield',
              '    local hpBefore, hadShield')
    s.insert_before('    dealDamage(C, enemy, target, target.resilient', '    local aAtk,tAtk=attacker.atk,target.atk\n')
    start_end = '''        resolveDeaths(C)
    end
    while #C.immediate > 0 do'''
    s.replace(start_end, '''        E.s15ObserveKeywords(g, ownerOf(C,S), C, S)
        resolveDeaths(C)
    end
    C.s15StartComplete = true
    for _, S in ipairs(C.sides) do E.s15CombatSpace(C, S) end
    while #C.immediate > 0 do''')
    s.insert_before('            local added = #S.list - before\n', '            if not C.recruit then E.s15CombatSpace(C, S) end\n')
    s.insert_before('        if not C.recruit then for _, S in ipairs(C.sides) do E.spellSummons(C,S) end end\n    end\nend\nC_.resolveDeaths = resolveDeaths',
                    '        if not C.recruit then for _, S in ipairs(C.sides) do E.s15CombatSpace(C, S) end end\n')
    s.replace('or m.frogRattles or m.timewarpDeathrattles or m.earthInvocation',
              'or m.frogRattles or m.timewarpDeathrattles or m.s15Deathrattles or m.earthInvocation')
    s.insert_before('        if extra then fire(C_.giftDeathrattle,1) end',
                    '        for _, part in ipairs(m.s15Deathrattles or {}) do fire(FX[part.id].dr, part.k) end\n')
    s.insert_before('                        gold.darkGift = gold.darkGift or m.darkGift',
                    '''                        if m.resilient then gold.resilient = true end
                        if m.missionProgress then
                            gold.missionProgress = (gold.missionProgress or 0) + m.missionProgress
                        end
                        if m.artisan then gold.artisan = (gold.artisan or 0) + m.artisan end
''')
    s.insert_before('    if g.phase~="recruit" then E.refreshCardAuras(p,"BG36_372");return end',
                    '''    if g.season == "s15" then
        p.s15HeroDamage = (p.s15HeroDamage or 0) + n
        E.refreshCardAuras(p, "S15_pain_promoter")
    end
''')
    s.insert_before('        elseif id=="BG36_372" then n,a,h=p.hp<=15 and 1 or 0,30,30',
                    '        elseif id=="S15_pain_promoter" then n,a,h=p.s15HeroDamage,1,2\n')
    s.insert_before('    if h > 0 then h = h + extraHealth end\n    buff(m, a, h)',
                    '')
    s.replace('    if h > 0 then h = h + extraHealth end\n    buff(m, a, h)',
              '''    if h > 0 then h = h + extraHealth end
    if p.s15SpellStatBonus and (a > 0 or h > 0) then
        a, h = a + p.s15SpellStatBonus, h + p.s15SpellStatBonus
    end
    buff(m, a, h)''')
    s.insert_before('        p.lastSpell, p.tavernSpellsCast = id, (p.tavernSpellsCast or 0) + 1',
                    '        if g.season == "s15" then p.s15TavernSpellsTurn = (p.s15TavernSpellsTurn or 0) + 1 end\n')
    s.replace('ok, err = s.cast(g, p, m, target, castEntry)', 'ok, err = E.s15Cast(g, p, s, m, target, castEntry)')
    s.replace('if not s.cast(g, p, m, target, castEntry) then break end',
              'if not E.s15Cast(g, p, s, m, target, castEntry) then break end')
    s.insert_before('    hooks(g,p,"castFromHand",entry.id)\n',
                    '    E.s15ObserveKeywords(g, p)\n')
    s.insert_before('        checkTriples(g, p)\n        return true\n    end\n\n    local function activationTargets',
                    '        E.s15ObserveKeywords(g, p)\n')
    s.replace('function E.autoCast(g,p,id,preferred)', 'function E.autoCast(g,p,id,preferred,entry)')
    s.replace('    if not spell.target then return E.castGeneratedSpell(g,p,id) end\n    local function attempt',
              '''    if not spell.target then
        if not E.s15Cast(g, p, spell, nil, nil, entry) then return false end
        castTrigger(g, p, id, entry)
        E.s15ObserveKeywords(g, p)
        return true
    end
    local function attempt''')
    s.replace('        if not i or not spell.cast(g,p,m,{zone=zone,index=i}) then return false end\n        castTrigger(g,p,id)\n        E.afterTargetedSpell(g,p,m,{id=id})',
              '''        if not i or not E.s15Cast(g, p, spell, m, {zone=zone,index=i}, entry) then return false end
        castTrigger(g, p, id, entry)
        E.afterTargetedSpell(g, p, m, entry or {id=id})
        E.s15ObserveKeywords(g, p)''')
    s.insert_before('    E.afterTargetedSpell(g,p,m,{id=id})\n    return true\nend\n\nfunction E.recastTrinketSpell',
                    '    E.s15ObserveKeywords(g, p)\n')
    s.replace('    for _, kw in ipairs(BONUS_KW) do if not m[kw] then table.insert(opts, kw) end end\n    local kw = pick(g, opts)',
              '''    for _, kw in ipairs(BONUS_KW) do
        local candidate = g.season == "s15" and kw == "stealth" and "resilient" or kw
        if not m[candidate] then table.insert(opts, candidate) end
    end
    local kw = pick(g, opts)''')
    s.insert_before('    register("S15_ambitious_recruit"', '''    BG_CARDS.S15T_monkey = {id="S15T_monkey",name="Monkey",tier=1,atk=2,hp=2,gatk=4,ghp=4,
        races={"BEAST"},pool=false,fx="full",noTriple=true}
    BG_CARDS.S15T_tentacle = {id="S15T_tentacle",name="Tentacle",tier=1,atk=1,hp=1,gatk=2,ghp=2,
        races={"ABERRATION"},pool=false,fx="full",noTriple=true}
''')
    s.insert_before('    if not id or id:sub(1, 4) ~= "S15_" or not BG_CARDS[id] then return nil end',
                    '''    if id == "S15T_monkey" then id = "S15_flying_monkey" end
    if id == "S15T_tentacle" then id = "S15_underrot_infestor" end
''')
    s.replace('    local hs = not d.spell and (Draw.HSOVAL[d.id] or d.id:sub(1, 4) == "S15_")',
              '    local hs = not d.spell and (Draw.HSOVAL[d.id] or Draw.s15MinionAsset(d.id, false, "ovals"))')
    s.insert_before('    local details=cardText(d.id,d.golden,d.atk,d.hp)',
                    '')  # keep the call site matched when incorporating the token descriptions
    s.insert_before('    local m=d.src or {}\n    local magnetic=Draw.magneticDetails(m)', '''    if d.zone == "tavern" and not d.warpIndex and game and game.season == "s15" then
        local owner = d.color and game.players[d.color]
        if owner then details = details .. "\\nCost: " .. BG.s15MinionPrice(owner, d.src, game.turn) .. " Gold" end
    end
''')
    s.replace('e.frozen, e.count = (p.frozen or (e.src and e.src.timewarpFrozen)) and true or false, count end)',
              'e.frozen, e.count, e.color = (p.frozen or (e.src and e.src.timewarpFrozen)) and true or false, count, color end)')


def build():
    raw = BACKUP.read_bytes() if BACKUP.exists() else SLOT.read_bytes()
    if not BACKUP.exists():
        BACKUP.write_bytes(raw)
    data = json.loads(raw)
    assert data["SaveName"] == "Battlegrounds Tavern - HS UI v18 - Season 15 Art"
    controller, = (o for o in data["ObjectStates"] if o.get("GUID") == "b9a001")
    script = Script(controller["LuaScript"])
    timewarp(script)
    if Path("work/s15_minions.lua").exists():
        minions(script)
    controller["LuaScript"] = script.code
    data["SaveName"] = "Battlegrounds Tavern - HS UI v18 - Season 15 Gameplay"
    DEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    Path("work/225-gameplay.lua").write_text(script.code, encoding="utf-8")
    print("Original:", hashlib.sha256(raw).hexdigest())
    print("Candidate:", hashlib.sha256(DEST.read_bytes()).hexdigest())


if __name__ == "__main__":
    build()
