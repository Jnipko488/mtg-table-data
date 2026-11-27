"""Batch 23: Season 15 'Warped Empire' (selectable; Season 14 stays the default), Five Tribes default, scripted minions only,
Resilient keyword, new-minion data (66) with the first scripted set, season stat updates, placeholder art for new cards."""
import sys
sys.path.insert(0, '/home/claude/s15')
DEFS = open('/home/claude/s15/defs.lua').read()
SEASON = open('/home/claude/s15/season.lua').read()
STATS = open('/home/claude/s15/stats.lua').read()
OV = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/4da08918fde0b6981041f98d0e96aa8e41949514/hsbg/battlegrounds-multiplayer/s14-leaderboard/s15ov/"

IMPL = r'''
    -- ===== Season 15 (Warped Empire) minions =====
    E.seasonSpells.s15 = E.seasonSpells.s15 or E.seasonSpells.s14
    local BONUS_KW = {"taunt", "shield", "reborn", "windfury", "venom", "resilient"}
    local function distinctBonus(p)
        local seen, n = {}, 0
        for _, m in ipairs(p.board) do for _, kw in ipairs(BONUS_KW) do if m[kw] and not seen[kw] then seen[kw] = true; n = n + 1 end end end
        return n
    end
    function E.beastAura(p, a, h)
        if not p then return end
        p.beastA, p.beastH = (p.beastA or 0) + a, (p.beastH or 0) + h
        E.applyUndead(p)
    end
    register("S15_hardy_felhound", {})
    register("S15_cutrate_crewman", {})
    register("S15_young_mukla", {bc = function(g, p, _, k) spells(g, p, "BG28_897", 2 * k) end})
    register("S15_flying_monkey", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), "BG28_897", 2 * k) end})
    register("S15_eclectic_musician", {endTurn = function(g, p, m, k)
        local bonus, used = m.musician or 3, {}
        local races = {}
        for _, o in ipairs(p.board) do for _, r in ipairs(card(o.id).all and (g.tribes or {}) or card(o.id).races) do races[r] = true end end
        for r in pairs(races) do
            local opts = {}
            for _, o in ipairs(p.board) do if hasRace(o, r) and not used[o] then opts[#opts + 1] = o end end
            local t = pick(g, opts)
            if t then used[t] = true; buff(t, bonus * k, bonus * k) end
        end
        m.musician = bonus + 1
    end})
    register("S15_wave_watcher", {endTurn = function(g, p, m, k)
        local times = 1 + distinctBonus(p)
        friendly(p, 3 * k * times, 3 * k * times, "ELEMENTAL")
    end})
    register("S15_gorloc_gardener", {afterPlay = function(g, p, m, played, k)
        m.gardener = (m.gardener or 0) + 1
        if m.gardener >= 3 then m.gardener = 0; for _ = 1, k do E.getRandomSpell(g, p, 3, true) end end
    end})
    register("S15_defense_mechanism", {beAttacked = function(C, S, self)
        local opts = {}
        for _, o in ipairs(S.list) do if o ~= self and o.hp > 0 and not o.shield then opts[#opts + 1] = o end end
        for _ = 1, mult(self) do
            local t = pick(C.g, opts)
            if t then t.shield = true; for i, o in ipairs(opts) do if o == t then table.remove(opts, i) break end end end
        end
    end})
    register("S15_nonchalant_napper", {beAttacked = function(C, S, self)
        local p = ownerOf(C, S)
        if p then for _ = 1, mult(self) do E.getRandomSpell(C.g, p, p.tier) end end
    end})
    register("S15_merciless_warden", {avenge = {n = 4, fn = function(C, S, o, k)
        local enemy = otherSide(C, S)
        for _ = 1, k do
            local best
            for _, t in ipairs(enemy.list) do if t.hp > 0 and (not best or t.hp > best.hp) then best = t end end
            if best then C_.dealDamage(C, enemy, best, o.atk) end
        end
    end}})
    register("S15_vindictive_preacher", {avenge = {n = 3, fn = function(C, S, o, k)
        local p = ownerOf(C, S)
        if p and E.deityBless then E.deityBless(p, 7 * k, 7 * k) end
    end}})
    register("S15_ribbiting_magician", {avenge = {n = 4, fn = function(C, S, o, k) aerate(ownerOf(C, S), k, 2 * k) end}})
    register("S15_light_generator", {shieldLost = function(C, S, self) aerate(ownerOf(C, S), mult(self), 0) end})
    register("S15_hammer_hero", {shieldLost = function(C, S, self)
        local a = (self.hammer or 1) * mult(self)
        for _, o in ipairs(S.list) do if o.hp > 0 then buff(o, a, a) end end
    end, magnetized = function(g, p, m) m.hammer = (m.hammer or 1) + 1 end})
    register("S15_shackled_shade", {friendlyDeath = function(C, S, o, dead, k)
        if not card(dead.id).deathrattle then return end
        local p = ownerOf(C, S)
        if p then p.undeadAtk = (p.undeadAtk or 0) + 2 * k end
        for _, u in ipairs(S.list) do if u.hp > 0 and hasRace(u, "UNDEAD") then u.atk = u.atk + 2 * k end end
    end})
    register("S15_elder_moonbeast", {spellTarget = function(g, p, m, k, target) if target == m then E.beastAura(p, 2 * k, 2 * k) end end})
    register("S15_ossifier", {spellTarget = function(g, p, m, k, target)
        if target ~= m then return end
        if m.ossTurn ~= g.turn then m.ossTurn, m.ossN = g.turn, 0 end
        if m.ossN >= 3 then return end
        m.ossN = m.ossN + 1
        for _ = 1, k do
            if #p.board >= E.MAX_BOARD then break end
            local i = indexOf(p.board, m) or #p.board
            E.shopSummon(g, p, E.newMinion(g, "BG_ICC_026t", false), i + 1)
        end
    end})
    register("S15_freedom_fighter", {afterPurchase = function(g, p, m, k, entry, isSpell, price)
        if (price or 99) <= 2 then friendly(p, 4 * k, 4 * k, "PIRATE") end
    end})
    local function gatherer(g, p, m, k)
        if m.missionDone or #p.board < E.MAX_BOARD then return end
        m.missionDone = true
        friendly(p, 2 * k, k)
    end
    register("S15_patron_gatherer", {bc = function(g, p, m, k) gatherer(g, p, m, k) end,
        afterPlay = function(g, p, m, played, k) gatherer(g, p, m, k) end})
    register("S15_obsessive_artisan", {afterPurchase = function(g, p, m, k)
        if m.missionDone then return end
        m.artisan = (m.artisan or 0) + 1
        if m.artisan >= 5 then
            m.missionDone = true
            for _ = 1, k do startDiscover(g, p, 4, function(c) return c.tier == 4 end, "Obsessive Artisan: Discover a Tier 4 minion") end
        end
    end})
    register("S15_ambitious_cannoneer", {endTurn = function(g, p, m, k)
        if m.missionDone or m.atk < 7 then return end
        m.missionDone = true
        p.extraMaxGold = (p.extraMaxGold or 0) + k
    end})
    register("S15_brutal_bristlethorn", {spend = function(g, p, m, n, k)
        m.bristle = (m.bristle or 0) + n
        while m.bristle >= 5 do
            m.bristle = m.bristle - 5
            for _ = 1, k do
                local opts = {}
                for _, kw in ipairs(BONUS_KW) do if not m[kw] then opts[#opts + 1] = kw end end
                local kw = pick(g, opts)
                if kw then E.tempBuff(m, 0, 0, kw) end
            end
        end
    end})
'''

ACT = r'''
    -- Season 15 activations
    activation("S15_graveyard_skulker", 0, function(g, p, m, k, target)
        E.recruitDeath(g, p, target)
        p.gold = p.gold + 2 * k
        return true
    end, function(_, m, t) return t ~= m and hasRace(t, "UNDEAD") end)
    activation("S15_temple_keeper", 0, function(g, p, m, k, target)
        for _ = 1, 2 * k do
            local opts = {}
            for _, kw in ipairs({"taunt", "shield", "reborn", "windfury", "venom", "resilient"}) do if not target[kw] then opts[#opts + 1] = kw end end
            local kw = E.pick(g, opts)
            if kw then E.tempBuff(target, 0, 0, kw) end
        end
        return true
    end, another)
'''

def patch(s, replace, HERE):
    # --- data
    s = replace(s, "BG_SEASONS = {\n", DEFS + "BG_SEASONS = {\n" + SEASON)
    s = replace(s, "    function E.activateSeason(key)\n", STATS.replace("E.seasonStats", "    E.seasonStats") + "    function E.activateSeason(key)\n")
    # --- keywords: Resilient on new minions; halves attack damage (rounded up)
    s = replace(s, "    for _, k in ipairs(KEYWORDS) do if c[k] then m[k] = true end end\n    if id==\"BG36_360\" then E.initParadox(g,m) end",
                   "    for _, k in ipairs(KEYWORDS) do if c[k] then m[k] = true end end\n    if c.resilient then m.resilient = true end\n    if id==\"BG36_360\" then E.initParadox(g,m) end")
    s = replace(s, "    dealDamage(C, enemy, target, aAtk, attacker)\n",
                "    if FX[target.id] and FX[target.id].beAttacked then FX[target.id].beAttacked(C, enemy, target, attacker) end\n"
                "    dealDamage(C, enemy, target, target.resilient and math.ceil(aAtk / 2) or aAtk, attacker)\n")
    s = replace(s, 'E.KEYWORD_NAMES = {taunt="Taunt",', 'E.KEYWORD_NAMES = {resilient="Resilient",taunt="Taunt",')
    # --- "Your Beasts have +X/+Y this game (wherever they are)" alongside the Undead aura
    s = replace(s, '''            if hasRace(m, "UNDEAD") then
                local d = (p.undeadAtk or 0) - (m.uAtk or 0)
                if d ~= 0 then m.atk = m.atk + d; m.uAtk = p.undeadAtk end
            end''', '''            if hasRace(m, "UNDEAD") then
                local d = (p.undeadAtk or 0) - (m.uAtk or 0)
                if d ~= 0 then m.atk = m.atk + d; m.uAtk = p.undeadAtk end
            end
            if hasRace(m, "BEAST") and ((p.beastA or 0) ~= (m.bA or 0) or (p.beastH or 0) ~= (m.bH or 0)) then
                m.atk, m.hp = m.atk + (p.beastA or 0) - (m.bA or 0), m.hp + (p.beastH or 0) - (m.bH or 0)
                m.bA, m.bH = p.beastA, p.beastH
            end''')
    # --- fixed minion costs (Cut-rate Crewman)
    s = replace(s, "    local cost=E.trinketMinionCost(p,m,E.buyCost(p),g.turn)\n",
                "    local cost=E.trinketMinionCost(p,m,(card(m.id).fixedCost or E.buyCost(p)),g.turn)\n")
    # --- scripted minions
    s = replace(s, '    register("BG36_369", {sell = function(g,p,m)', IMPL + '    register("BG36_369", {sell = function(g,p,m)')
    s = replace(s, "    function E.activation(g, m)\n", ACT + "    function E.activation(g, m)\n")
    # --- art for the new cards (placeholders until the real art ships)
    s = replace(s, 'function Draw.ovalArt(d)\n    if not d or d.zone == "hand" then return nil end\n',
                'function Draw.ovalArt(d)\n    if not d or d.zone == "hand" then return nil end\n'
                '    if d.id and d.id:sub(1, 4) == "S15_" and not d.spell then return "' + OV + '" .. (d.golden and "g/" or "n/") .. d.id .. ".png" end\n')
    s = replace(s, "local function onlineArt(id, golden)\n",
                "local function onlineArt(id, golden)\n    if id and id:sub(1, 4) == \"S15_\" then return \"" + OV + "\" .. (golden and \"g/\" or \"n/\") .. id .. \".png\" end\n")
    # --- settings: Season 15 selectable (Season 14 default), Five Tribes default, scripted minions only
    s = replace(s, 'local settings = {season = "s14", roster = "full",', 'local settings = {season = "s14", roster = "rotation",')
    s = replace(s, 'local ROSTER_MODES = {"full", "rotation", "scripted"}', 'local ROSTER_MODES = {"rotation", "full"}')
    s = replace(s, 'local ROSTER_LABELS = {full = "Full Roster", rotation = "Five Tribes", scripted = "Scripted Minions"}',
                   'local ROSTER_LABELS = {full = "Full Roster", rotation = "Five Tribes"}')
    s = replace(s, "Draw.verifiedSeasons = {s14 = true}", "Draw.verifiedSeasons = {s14 = true, s15 = true}\nDraw.SEASON_CYCLE = {\"s14\", \"s15\"}")
    s = replace(s, '''            ensureTile(SET, "o_season", {size = 1, right = r[2], near = r[3],
                labels = {{text = Draw.optionLabel(key), x = 0, z = 0, width = 10.35, height = .85, font = .35}}})''',
    '''            ensureTile(SET, "o_season", {size = 1, right = r[2], near = r[3], cw = 10.35, ch = 0.85, font = 0.32,
                buttonText = Draw.optionLabel(key), buttonColor = {0.13, 0.14, 0.16, 1}, click = true, action = "set_season",
                tip = "Click to change the season (Season 14 is the default)"})''')
    s = replace(s, '    elseif action == "set_whole" then\n',
                '    elseif action == "set_season" then\n        settings.season = cycle(Draw.SEASON_CYCLE, settings.season)\n    elseif action == "set_whole" then\n')
    s = replace(s, 'local g = BG.new({fullMinions = roster ~= "scripted", tierSeven = roster == "full", allTribes = roster == "full",',
                   'local s15 = s and s.key == "s15"\n    local g = BG.new({fullMinions = false, tierSeven = roster == "full", allTribes = roster == "full",')
    s = replace(s, '''        trinkets=settings.trinkets,buddies=settings.buddies,anomalies=settings.anomalies,
        timewarp=settings.timewarp,quests=settings.quests,heroChoices=4})
    g.darkGiftsEnabled=settings.darkgifts~=false''', '''        trinkets=settings.trinkets and not s15,buddies=settings.buddies,anomalies=settings.anomalies,
        timewarp=settings.timewarp or s15,quests=settings.quests,heroChoices=4})
    g.darkGiftsEnabled=settings.darkgifts~=false and not s15''')
    # an old save may still hold the removed "scripted" roster
    s = replace(s, "local function launchGame(hostColor)\n", "local function launchGame(hostColor)\n    if not ROSTER_LABELS[settings.roster] then settings.roster = \"rotation\" end\n")
    return s
