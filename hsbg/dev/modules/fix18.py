"""Batch 24: Season 15 spells (Goldrinn's Blessing, Elemental Invocations, Command the Elements, Dragonstorm, Tumultuous
Growth, returning Echoing Roar and Sanctify) + the minions that use them; S15 spell rotation; placeholder spell art."""
import sys
sys.path.insert(0, '/home/claude/s15')
from spells import SPELLS
SP = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/fd109990eee559e287482839e253b0b8ca54bd46/hsbg/battlegrounds-multiplayer/s14-leaderboard/s15sp/"
ROT = [l.strip() for l in open('/home/claude/s15/spell_s15.txt') if l.strip()]

def lua_str(t): return '"' + t.replace('\\', '\\\\').replace('"', '\\"') + '"'

def patch(s, replace, HERE):
    meta = "\n".join('    metadata["S15S_%s"] = {name=%s,tier=%d,cost=%d,pool=%s,generated=%s,text=%s}' % (k, lua_str(n), t, c, "true" if pl else "false", "false" if pl else "true", lua_str(tx))
                     for k, n, t, c, pl, tx, _ in SPELLS)
    rot = ",".join('["%s"]=true' % i for i in ROT) + "," + ",".join('["S15S_%s"]=true' % k for k, n, t, c, pl, tx, _ in SPELLS if pl)
    code = r'''
    -- ===== Season 15 spells =====
@META@
    E.seasonSpells.s15 = {@ROT@}
    local INV = {"S15S_invocation_earth", "S15S_invocation_fire", "S15S_invocation_air", "S15S_invocation_water"}
    local function invocation(a, kw)
        return function(g, p, m)
            if not m or not hasRace(m, "ELEMENTAL") then return false, "Choose an Elemental." end
            E.tempBuff(m, a, a, kw)
            return true
        end
    end
    spell("S15S_invocation_earth", "board", invocation(3, "taunt"))
    spell("S15S_invocation_fire", "board", invocation(4, "reborn"))
    spell("S15S_invocation_air", "board", invocation(5, "windfury"))
    spell("S15S_invocation_water", "board", invocation(6, "shield"))
    spell("S15S_command_elements", nil, function(g, p)
        if E.handCount(p) >= E.MAX_HAND then return false, "Your hand is full." end
        for _, id in ipairs(INV) do E.giveSpell(g, p, id, true) end
        return true
    end)
    spell("S15S_goldrinns_blessing", nil, function(g, p) E.beastAura(p, 1, 1); return true end)
    FX["S15E_dragonstorm"] = {endTurn = function(g, p, m) buff(m, 2, 2) end}
    FX["S15E_echo"] = {endTurn = function(g, p, m) buff(m, 3, 3) end}
    local function attach(m, id)
        m.attachments = m.attachments or {}
        m.magnetizedCount = m.magnetizedCount or #m.attachments
        table.insert(m.attachments, {id = id, atk = 0, hp = 0, enchant = true})
    end
    function E.castDragonstorm(p) for _, m in ipairs(p.board) do if hasRace(m, "DRAGON") then attach(m, "S15E_dragonstorm") end end end
    function E.castSanctify(p) for _, m in ipairs(p.board) do if m.shield then buffSpell(p, m, 4, 0) end end end
    spell("S15S_dragonstorm", nil, function(g, p) E.castDragonstorm(p); return true end)
    spell("S15S_tumultuous_growth", "board", function(g, p, m)
        if not m then return false, "Choose a minion." end
        for _ = 1, 2 do for _ = 1, 12 do if E.castRandomTavern(g, p, m) then break end end end
        return true
    end)
    spell("S15S_echoing_roar", "board", function(g, p, m) if not m then return false, "Choose a minion." end; attach(m, "S15E_echo"); return true end)
    spell("S15S_sanctify", nil, function(g, p) E.castSanctify(p); return true end)

    -- ===== Season 15 minions that use them =====
    local GB, ER, CMD = "S15S_goldrinns_blessing", "S15S_echoing_roar", "S15S_command_elements"
    register("S15_great_wolf_cub", {bc = function(g, p, _, k) spells(g, p, GB, k) end})
    register("S15_great_direwolf", {onAttack = function(C, S, _, k) spells(C.g, ownerOf(C, S), GB, k) end})
    register("S15_timeless_mount", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), ER, k) end,
        onAttack = function(C, S, _, k) spells(C.g, ownerOf(C, S), ER, k) end})
    register("S15_effusive_dancer", {bc = function(g, p, _, k) for _ = 1, k do spells(g, p, pick(g, INV), 1) end end,
        dr = function(C, S, _, _, k) for _ = 1, k do spells(C.g, ownerOf(C, S), pick(C.g, INV), 1) end end})
    register("S15_tsunami_surfer", {endTurn = function(g, p, _, k) for _ = 1, k do spells(g, p, pick(g, INV), 1) end end})
    register("S15_thunder_knight", {sell = function(g, p, _, k) spells(g, p, CMD, k) end})
    register("S15_twilight_traverser", {endTurn = function(g, p, _, k) E.chromadrakeReward(g, p, k) end})
    register("S15_surging_sanctifier", {spellTarget = function(g, p, m, k, target) if target == m then for _ = 1, k do E.castSanctify(p) end end end})
    register("S15_dauntless_adventurer", {bc = function(g, p, m, k)
        local opts = {}
        for _, o in ipairs(p.board) do if hasRace(o, "QUILBOAR") then opts[#opts + 1] = o end end
        local t = pick(g, opts)
        if t then E.applyGems(g, p, t, (2 + distinctBonus(p)) * k) end
    end})
    register("S15_land_upheaver", {dr = function(C, S, m, _, k)
        local p = ownerOf(C, S)
        local n = (2 + (p and p.elementalsPlayed or 0)) * k
        for _, o in ipairs(S.list) do if o.hp > 0 and o ~= m and hasRace(o, "ELEMENTAL") then buff(o, n, n) end end
    end}, "Improves by +1/+1 for each Elemental played this game.")
    register("S15_scaled_sovereign", {afterPlay = function(g, p, m, played) if hasRace(played, "DRAGON") then m.activatedTurn = nil end end})
'''.replace("@META@", meta).replace("@ROT@", rot)
    s = replace(s, '    register("BG36_369", {sell = function(g,p,m)', code + '    register("BG36_369", {sell = function(g,p,m)')
    s = replace(s, "    function E.activation(g, m)\n", '''    activation("S15_scaled_sovereign", 2, function(g, p, m, k) for _ = 1, k do E.castDragonstorm(p) end; return true end)
    activation("S15_faceless_necromancer", 0, function(g, p, m, k, target)
        for _, list in ipairs({p.hand, p.spellHand}) do
            for i, c in ipairs(list) do if c == target then E.discardCard(g, p, list, i) break end end
        end
        for _, o in ipairs(p.board) do if hasRace(o, "ABERRATION") then E.tempBuff(o, 0, 0, "reborn"); break end end
        return true
    end, function() return true end, "hand")
    function E.activation(g, m)
''')
    # placeholder art for the new spells (hand cards and tavern)
    s = replace(s, 'function Draw.spellArt(id)\n', 'function Draw.spellArt(id)\n    if id and id:sub(1, 5) == "S15S_" then return "' + SP + '" .. id .. ".png" end\n')
    s = replace(s, 'function Draw.shopSpellArt(id, price)\n', 'function Draw.shopSpellArt(id, price)\n    if id and id:sub(1, 5) == "S15S_" then return "' + SP + '" .. id .. "_shop.png" end\n')
    for key in ["great_wolf_cub", "great_direwolf", "timeless_mount", "effusive_dancer", "tsunami_surfer", "thunder_knight", "twilight_traverser",
                "surging_sanctifier", "dauntless_adventurer", "land_upheaver", "scaled_sovereign", "faceless_necromancer"]:
        s = replace(s, 'BG_CARDS["S15_%s"] = {' % key, 'BG_CARDS["S15_%s"] = {' % key)
        i = s.index('BG_CARDS["S15_%s"] = {' % key); j = s.index('\n', i)
        s = s[:i] + s[i:j].replace('fx="none"', 'fx="full"') + s[j:]
    s = replace(s, """    for _,part in ipairs(m.attachments or {}) do
        local c=BG_CARDS[part.id]
        if c then""", """    for _,part in ipairs(m.attachments or {}) do
        local c=BG_CARDS[part.id]
        local en=Draw.ENCHANT_TEXT[part.id]
        if en then
            if not counts[en] then counts[en]=0; order[#order+1]=en end
            counts[en]=counts[en]+1
        elseif c then""")
    s = replace(s, "function Draw.magneticDetails(m)\n", 'Draw.ENCHANT_TEXT = {S15E_dragonstorm = "Dragonstorm: At the end of your turn, gain +2/+2.", S15E_echo = "Echoing Roar: At the end of your turn, gain +3/+3."}\nfunction Draw.magneticDetails(m)\n')
    return s
