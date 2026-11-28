    -- ===== Season 15 Timewarp: the 81 new cards (Minor 37, Major 44) =====
    -- Card data comes from the 37.2 patch notes. Minion ids are S15_tw_<name>; art is hosted
    -- with the other Season 15 art (cards/, ovals/, twspells/).
    local TW = {}
    E.S15TW = TW
    TW.ART = "@@ART@@twspells/"
    TW.DEFS = @@DEFS@@
    for _, d in ipairs(TW.DEFS) do
        if d.kind == "minion" then
            local c = {id = d.id, name = d.name, tier = d.tier, atk = d.atk, hp = d.hp, races = d.races, all = d.all,
                text = d.text, gtext = d.gtext, pool = false, season = true, legend = false,
                gatk = d.atk * 2, ghp = d.hp * 2, gid = d.id, fx = "none", s15Timewarp = true}
            for key, value in pairs(d.flags) do c[key] = value end
            BG_CARDS[d.id] = c
        else
            metadata[d.id] = {name = d.name, tier = d.tier, cost = d.cost, generated = true, timewarp = true,
                text = d.text, timewarpArt = TW.ART .. d.id .. ".png"}
        end
        BG_TIMEWARP[d.id] = {tier = d.tier, cost = d.cost, kind = d.kind, tribes = d.tribes,
            immediate = d.kind == "power", name = d.name, s15 = true}
    end
    -- Timewarped Scroll (returning to the Minor Timewarp in Season 15; it was never scripted).
    TW.SCROLL = "BG34_Treasure_610"
    BG_TIMEWARP[TW.SCROLL] = {tier = 3, cost = 1, kind = "spell", tribes = {}, immediate = false, name = "Timewarped Scroll", s15 = true}
    metadata[TW.SCROLL] = {name = "Timewarped Scroll", tier = 3, cost = 1, generated = true, timewarp = true,
        text = "Each turn this is in your hand, transform into a random 2-Cost card from the Minor Timewarp.",
        timewarpArt = TW.ART .. TW.SCROLL .. ".png"}
    spell(TW.SCROLL, nil, function() return false, "This transforms at the start of your turn." end)
    -- Plant token for Timewarped Amalgadon.
    TW.PLANT = "BG_UNG_999t2t1"
    if not card(TW.PLANT) then
        BG_CARDS[TW.PLANT] = {id = TW.PLANT, name = "Plant", tier = 1, atk = 1, hp = 1, races = {}, all = false,
            text = "", gtext = "", pool = false, legend = false, gatk = 2, ghp = 2, gid = TW.PLANT .. "_G", fx = "full", noTriple = true}
    end

    -- helpers
    local act = E.registerActivation
    local function other(_, m, t) return t ~= m end
    function TW.hand(g, p, m)
        if not p or not m or E.handCount(p) >= E.MAX_HAND then return false end
        m.generated = true
        addToHand(g, p, m)
        return true
    end
    function TW.copy(g, m)
        local c = copyTable(m)
        g.uid = g.uid + 1
        c.uid, c.generated = g.uid, true
        c.activatedTurn, c.inCombat, c.src, c.side, c.dead, c.poolCopies = nil, nil, nil, nil, nil, nil
        return c
    end
    function TW.keywords(from, to)
        for _, kw in ipairs(BONUS_KW) do if from[kw] then to[kw] = true end end
    end
    function TW.absorb(m, t, k)
        buff(m, t.atk * k, t.hp * k)
        TW.keywords(t, m)
    end
    function TW.hasEndTurn(t)
        if t.id == "BG22_403" then return false end
        local f = FX[t.id]
        if f and f.endTurn then return true end
        for _, part in ipairs(t.attachments or {}) do if FX[part.id] and FX[part.id].endTurn then return true end end
        return false
    end
    function TW.endTurnOf(g, p, t)
        local f = FX[t.id]
        if f and f.endTurn then E.withElementalAura(p, t, f.endTurn, g, p, t, mult(t)) end
        E.dispatchAttached(t, "endTurn", function(fn, n, part) fn(g, p, t, n, part) end)
    end
    function TW.sharesType(c, t)
        if c.all then return true end
        for _, r in ipairs(c.races or {}) do if hasRace(t, r) then return true end end
        return false
    end
    function TW.typed(t)
        local c = card(t.id)
        return c and (c.all or #(c.races or {}) > 0) or false
    end
    function TW.queued(p)
        local q = p.discoverQueue
        return (#q > 0 and q[#q]) or p.discover
    end
    function TW.combatBlessing(C, S)
        local p = ownerOf(C, S)
        local s = E.SPELLS[GB]
        if not p or not s then return end
        local t = E.S15_SPELLS and E.S15_SPELLS[GB] or {a = 1, h = 1}
        local a, h = E.spellAmount(p, t.a or 1, t.h or 1)
        if not s.cast(C.g, p) then return end
        if C.recruit then E.recordCombatSpell(C.g, p, GB, p.board); return end
        E.recordCombatSpell(C.g, p, GB, S.list)
        for _, b in ipairs(S.list) do if b.hp > 0 and hasRace(b, "BEAST") then buff(b, a, h) end end
    end
    function TW.combatBattlecry(C, S, t)
        local p = ownerOf(C, S)
        if not p or not card(t.id).battlecry then return end
        local board = p.board
        p.board = S.list
        local ok, err = pcall(runBattlecry, C.g, p, t, 1)
        p.board = board
        if not ok then error(err) end
    end
    function TW.permanent(C, m, a, h)
        if C.recruit then buff(m, a, h) else C_.trinketPermanent(C, m, a, h) end
    end
    function TW.eachType(g, list, fn)
        local used = {}
        for _, r in ipairs(g.tribes or {}) do
            local options = {}
            for _, m in ipairs(list) do if not used[m] and m.hp > 0 and hasRace(m, r) then options[#options + 1] = m end end
            local m = pick(g, options)
            if m then used[m] = true; fn(m) end
        end
    end
    function TW.foeOf(g, p)
        for _, pair in ipairs(E.recruitPairings(g)) do
            if pair[1] == p then return pair[2] end
            if pair[2] == p then return pair[1] end
        end
    end
    TW.DRAKES = {"BG34_634t", "BG34_635t", "BG34_636t", "BG34_637t", "BG34_638t"}
    TW.BOUNTIES = {"BG33_811", "BG33_812", "BG33_813", "BG33_814", "BG33_815"}

    -- ----- Minor Timewarp minions -----
    act("S15_tw_amalgam_of_the_deep", 1, function(g, p, m, k, t)
        local found = false
        for _ = 1, k do
            if startDiscover(g, p, p.tier, function(c) return TW.sharesType(c, t) end, "Discover a minion of the same type", nil, t.id) then found = true end
        end
        if not found then return false, "No minion of that type is available." end
        return true
    end, function(_, m, t) return t ~= m and TW.typed(t) end)
    local function fodder(p, k) if p then for _ = 1, k do E.giftFodder(p, 3) end end end
    register("S15_tw_assistant", {bc = function(_, p, _, k) fodder(p, k) end,
        onAttack = function(C, S, _, k) fodder(ownerOf(C, S), k) end})
    act("S15_tw_avalanche_caller", 0, function(g, p, m, k, t)
        local i = indexOf(p.board, t)
        if not i then return false, "Choose another friendly minion." end
        local snap = {atk = t.atk, hp = t.hp}
        TW.keywords(t, snap)
        local ok, err = E.sell(g, p.color, i)
        if not ok then return false, err end
        TW.absorb(m, snap, k)
        return true
    end, other)
    local function lockbox(g, p, k) if p and FX.BG36_520 and FX.BG36_520.bc then FX.BG36_520.bc(g, p, nil, k) end end
    register("S15_tw_breakout", {bc = function(g, p, _, k) lockbox(g, p, k) end,
        dr = function(C, S, _, _, k) lockbox(C.g, ownerOf(C, S), k) end,
        onAttack = function(C, S, _, k) lockbox(C.g, ownerOf(C, S), k) end})
    act("S15_tw_clan_trainer", 2, function(g, p, m, k)
        for _ = 1, k do
            local list = {}
            for _, o in ipairs(p.board) do list[#list + 1] = o end
            table.sort(list, function(a, b) if a.atk ~= b.atk then return a.atk < b.atk end return a.uid < b.uid end)
            for i = 1, math.min(2, #list) do buff(list[i], list[i].atk, list[i].hp) end
        end
        return true
    end)
    register("S15_tw_contortionist", {onAttack = function(C, S, _, k) aerate(ownerOf(C, S), k, k) end})
    register("S15_tw_cub", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), GB, k) end})
    register("S15_tw_cutlassier", {handGained = function(g, p, m)
        mission(g, p, m, 15, 1, function(_, owner, kk) aerate(owner, 5 * kk, 5 * kk) end)
    end})
    register("S15_tw_duke", {}) -- stats come from E.updateCardAuras (see the Season 15 late block)
    act("S15_tw_fruit_vendor", 0, function(g, p, _, k) spells(g, p, "BG28_897", 3 * k); return true end)
    act("S15_tw_graverobber", 0, function(g, p, m, k, t)
        if not indexOf(p.board, t) then return false, "Choose another friendly minion." end
        local snap = TW.copy(g, t)
        E.recruitDeath(g, p, t)
        m.graveCopies = m.graveCopies or {}
        for _ = 1, k do m.graveCopies[#m.graveCopies + 1] = snap end
        m.graveTurn = g.turn
        return true
    end, other)
    register("S15_tw_graverobber", {
        startTurn = function(g, _, m) if m.graveTurn and m.graveTurn < g.turn then m.graveCopies, m.graveTurn = nil, nil end end,
        dr = function(C, S, m, pos)
            for i, snap in ipairs(m.graveCopies or {}) do
                summon(C, S, snap.id, snap.golden, pos + i - 1, function(x)
                    x.atk, x.hp = snap.atk, snap.hp
                    TW.keywords(snap, x)
                end)
            end
        end})
    act("S15_tw_holmes", 0, function(g, p, m, k)
        local foe = TW.foeOf(g, p)
        local board = type(foe) == "table" and foe.board
        if type(board) ~= "table" or #board == 0 then return false, "Your next opponent has no minions to guess." end
        for _ = 1, k do
            local answer = pick(g, board)
            local ids, seen = {answer.id}, {[answer.id] = true}
            local others = {}
            for id, n in pairs(g.pool) do if n > 0 and not seen[id] and card(id) then others[#others + 1] = id end end
            table.sort(others)
            shuffle(g, others)
            for i = 1, math.min(2, #others) do ids[#ids + 1] = others[i] end
            shuffle(g, ids)
            E.offerMinionChoice(g, p, ids, "Holmes: which minion is in your next opponent's warband?",
                {s15Effect = "holmes", holmesAnswer = answer.id, holmesCopy = TW.copy(g, answer)})
        end
        return true
    end)
    act("S15_tw_morchie", 4, function(g, p, _, k)
        local ok = false
        for _ = 1, k do if E.discoverTimewarp(g, p, 3, 2, "minion") then ok = true end end
        return ok, "No Timewarped minions are available."
    end)
    register("S15_tw_muscle_o_tron", {magnetized = function(g, p, m)
        if p.lastMagnetTarget ~= m then return end
        mission(g, p, m, 3, 1, function() buff(m, m.atk, m.hp) end)
    end})
    act("S15_tw_mycologist", 1, function(g, p, _, k)
        local ok = false
        for _ = 1, k do
            if E.discoverSpell(g, p, p.tier, false, "Discover a Tavern spell for a Murloc to teach") then
                TW.queued(p).s15Teach = true
                ok = true
            end
        end
        return ok, "No spells are available."
    end)
    act("S15_tw_necromancer", 0, function(g, p, m, k, target)
        local done = false
        for _, list in ipairs({p.hand, p.spellHand}) do
            for i, c in ipairs(list) do if c == target then done = E.discardCard(g, p, list, i); break end end
            if done then break end
        end
        if not done then return false, "That card is no longer in your hand." end
        for _, o in ipairs(p.board) do if hasRace(o, "ABERRATION") then o.reborn = true; break end end
        return true
    end, function() return true end, "hand")
    register("S15_tw_outpourer", {afterPlay = function(g, p, _, played, k)
        if not hasRace(played, "ELEMENTAL") then return end
        for _ = 1, k do if indexOf(p.board, played) then E.castSpellOnBoard(g, p, INV[rnd(g, #INV)], played) end end
    end})
    act("S15_tw_picky_eater", 0, function(g, p, m, k, t)
        local i = indexOf(p.tavern, t)
        if not i then return false, "Choose a minion in the Tavern." end
        table.remove(p.tavern, i)
        returnToPool(g, t)
        TW.absorb(m, t, k)
        return true
    end, function() return true end, "tavern")
    register("S15_tw_prophet_of_the_boar", {afterPlay = function(g, p, m, played, k)
        if not hasRace(played, "QUILBOAR") then return end
        spells(g, p, "BG20_GEM", k)
        E.applyGems(g, p, m, k)
    end})
    register("S15_tw_recyclebot", {sell = function(g, p, m)
        local s = E.newMinion(g, "BG31_171t", false)
        s.atk, s.hp = m.atk, m.hp
        TW.keywords(m, s)
        TW.hand(g, p, s)
    end})
    register("S15_tw_reflector", {spellTarget = function(g, p, m, k, target, entry)
        if p.s15Reflecting or not entry then return end
        local s = E.SPELLS[entry.id]
        if not s or not (s.tavern or not s.generated) or BG_TIMEWARP[entry.id] then return end
        local i = indexOf(p.board, target)
        local left = i and p.board[i - 1]
        if not left then return end
        p.s15Reflecting = true
        local ok, err = pcall(function()
            for _ = 1, k do if indexOf(p.board, left) then E.castSpellOnBoard(g, p, entry.id, left) end end
        end)
        p.s15Reflecting = nil
        if not ok then error(err) end
    end})
    act("S15_tw_reverber_drake", 0, function(g, p, m, k, t)
        for _ = 1, k do
            E.castSpellOnBoard(g, p, ER, m)
            E.castSpellOnBoard(g, p, ER, t)
        end
        return true
    end, other)
    register("S15_tw_rot", {spellTarget = function(g, p, m, k, target)
        if target ~= m then return end
        if m.rotTurn ~= g.turn then m.rotTurn, m.rotCount = g.turn, 0 end
        if m.rotCount >= 2 then return end
        m.rotCount = m.rotCount + 1
        E.giveGrowingOoze(g, p, k)
    end})
    register("S15_tw_rylak", {dr = function(C, S, m, pos, k)
        local list = S.list
        local i = indexOf(list, m)
        local near = i and {list[i - 1], list[i + 1]} or {list[pos - 1], list[pos]}
        for _ = 1, k do
            for j = 1, 2 do
                local t = near[j]
                if t and t ~= m and t.hp > 0 then TW.combatBattlecry(C, S, t) end
            end
        end
    end})
    local function smith(g, p, k)
        for _ = 1, k do E.keywordGems(g, p, ({"taunt", "shield", "reborn"})[rnd(g, 3)], 1) end
    end
    register("S15_tw_scrapsmith", {bc = function(g, p, _, k) smith(g, p, k) end,
        dr = function(C, S, _, _, k) smith(C.g, ownerOf(C, S), k) end})
    register("S15_tw_soldier", {gainObserved = function(p, _, _, m, target, k, a, h)
        if m == target then E.deityBless(p, a, h) end
    end})
    register("S15_tw_sr_scout", {
        startTurn = function(_, _, m) m.scoutTier = math.min(6, (m.scoutTier or 2) + 1) end,
        sell = function(g, p, m, k)
            local t = math.min(6, m.scoutTier or 2)
            for _ = 1, k do
                E.discoverDarkGift(g, p, {low = t, high = t, label = "Discover a Tier " .. t .. " minion with a Dark Gift"})
            end
        end})
    register("S15_tw_traverser", {endTurn = function(g, p, _, k)
        for _ = 1, k do
            local d = E.newMinion(g, TW.DRAKES[rnd(g, #TW.DRAKES)], false)
            if TW.hand(g, p, d) then runBattlecry(g, p, d, 1) end
        end
    end})
    register("S15_tw_tumor", {}) -- the discard hook lives in the Season 15 late block
    act("S15_tw_willbreaker", 1, function(g, p, _, k)
        for _ = 1, k do
            local got = {}
            for _ = 1, 3 do if E.getRandomSpell(g, p, p.tier, false) then got[#got + 1] = p.spellHand[#p.spellHand] end end
            if #got > 1 then
                g.uid = g.uid + 1
                for _, e in ipairs(got) do e.discardPair, e.discardAfter = g.uid, 1 end
            end
        end
        return true
    end)

    -- ----- Minor Timewarp spells and hero powers -----
    spell("S15_tw_piggy_bank", nil, function(g, p, _, _, entry)
        p.gold = math.min(99, p.gold + 2 + (entry and entry.piggy or 0))
        return true
    end)
    spell("S15_tw_telescope", nil, function(g, p)
        return E.discoverDarkGift(g, p, {low = 1, high = math.max(2, p.tier), typed = true,
            label = "Discover a minion of your most common type with a Dark Gift"})
    end)
    TW.POWERS = {{"S15_tw_power_buttons", "BG32_HERO_002"}, {"S15_tw_power_clocksworth", "BG34_HERO_002"},
        {"S15_tw_power_murozond", "BG34_HERO_000"}, {"S15_tw_power_snake_eyes", "BG28_HERO_400"},
        {"S15_tw_power_zerek", "BG31_HERO_005"}}
    for _, pair in ipairs(TW.POWERS) do
        local spellId, hero = pair[1], pair[2]
        BG_TIMEWARP[spellId].heroPower = hero
        spell(spellId, nil, function(g, p)
            if E.hasPower(p, hero) or not E.HP[hero] then return false, "You already have this power." end
            p.secondPowerHero, p.secondPowerUses = hero, 0
            if E.HP[hero].startTurn then E.HP[hero].startTurn(g, p) end
            return true
        end)
    end

    -- ----- Major Timewarp minions -----
    register("S15_tw_amalgadon", {dr = function(C, S, m, pos)
        for i = 1, 2 do summon(C, S, TW.PLANT, m.golden, pos + i - 1) end
    end})
    act("S15_tw_ball_of_minions", 3, function(_, _, m, _, t) buff(t, m.atk, m.hp); return true end, other)
    register("S15_tw_bronze_gatekeeper", {})
    register("S15_tw_bubblebot", {soc = function(C, S, m, k)
        local i = indexOf(S.list, m)
        if not i then return end
        for _, j in ipairs({i - 1, i + 1}) do
            local t = S.list[j]
            if t and t.hp > 0 then
                if t.shield then t.shieldHits = (t.shieldHits or 1) + (k > 1 and 3 or 2) else t.shield = true end
            end
        end
    end})
    register("S15_tw_cage_gnawer", {allyAttack = function(C, S, o, attacker, k)
        if attacker == o or not hasRace(attacker, "BEAST") then return end
        for _ = 1, k do TW.combatBlessing(C, S) end
    end})
    act("S15_tw_clunker", 2, function(g, p, _, k)
        local ok = false
        for _ = 1, 3 * k do
            if startDiscover(g, p, p.tier, function(c) return c.magnetic and (c.all or indexOf(c.races, "MECHANICAL") ~= nil) end,
                "Discover a Magnetic Mech") then ok = true end
        end
        return ok, "No Magnetic Mechs are available."
    end)
    register("S15_tw_concierge", {}) -- price rule: E.spellPrice below
    register("S15_tw_converter", {dr = function(C, S, _, _, k)
        local p = ownerOf(C, S)
        if p then local n = (4 + (p.discarded or 0)) * k; E.deityBless(p, n, n) end
    end})
    act("S15_tw_deliverer", 2, function(g, p, _, k)
        local ok = false
        for _ = 1, k do
            if startDiscover(g, p, 4, function(c) return c.tier == 4 end, "Discover a Golden Tier 4 minion") then
                TW.queued(p).golden = true
                ok = true
            end
        end
        return ok, "No Tier 4 minions are available."
    end)
    register("S15_tw_endurer", {spellTarget = function(g, _, m, k, target, entry)
        if not entry or entry.id ~= "BG20_GEM" or not target then return end
        if m.endurerTurn ~= g.turn then m.endurerTurn, m.endurerCount = g.turn, 0 end
        if m.endurerCount >= 3 then return end
        m.endurerCount = m.endurerCount + 1
        E.tempBuff(target, 0, 0, "resilient")
    end})
    act("S15_tw_engineer", 3, function(g, p, m, k)
        for _ = 1, k do
            local list = {}
            for _, t in ipairs(p.board) do if t ~= m and TW.hasEndTurn(t) then list[#list + 1] = t end end
            for _, t in ipairs(list) do if indexOf(p.board, t) then TW.endTurnOf(g, p, t) end end
        end
        return true
    end)
    register("S15_tw_eye_of_gorath", {soc = function(C, S, m, k)
        local p = ownerOf(C, S)
        local c = C.g.deity and card(C.g.deity)
        if not p or not c then return end
        local golden = p.goldenDeity
        buff(m, ((golden and c.gatk or c.atk) + (p.deityAtk or 0)) * k, ((golden and c.ghp or c.hp) + (p.deityHealth or 0)) * k)
    end})
    register("S15_tw_flat_tusk", {spend = function(g, p, m, n, k)
        m.tuskGold = (m.tuskGold or 0) + n
        while m.tuskGold >= 5 do
            m.tuskGold = m.tuskGold - 5
            for _, q in ipairs(p.board) do if hasRace(q, "QUILBOAR") then E.applyGems(g, p, q, k) end end
        end
    end})
    register("S15_tw_future_fighter", {}) -- price rule: E.s15MinionPrice below
    local function smuggle(g, p, m, k)
        for _, o in ipairs(p.board) do if o ~= m then E.applyGems(g, p, o, 2 * k) end end
        return true
    end
    register("S15_tw_gem_smuggler", {bc = function(g, p, m, k) smuggle(g, p, m, k) end})
    act("S15_tw_gem_smuggler", 0, function(g, p, m, k) return smuggle(g, p, m, k) end)
    register("S15_tw_hardlight", {})
    function E.s15ShieldPrevented(C, S, target, amount)
        if not amount or amount <= 0 then return end
        for _, o in ipairs(S.list) do
            if o.hp > 0 and o.id == "S15_tw_hardlight" then buff(o, amount * mult(o), 0) end
        end
    end
    register("S15_tw_huhuran", {afterPlay = function(g, p, _, played, k)
        local c = card(played.id)
        local rattle = C_.hasDeathrattle(played)
        if not rattle and not c.rally then return end
        for _ = 1, k do
            if not indexOf(p.board, played) then break end
            if rattle then E.trinketDeathrattle(g, p, played) end
            if c.rally and indexOf(p.board, played) then E.triggerRally(g, p, played, 1) end
        end
    end})
    act("S15_tw_kthir", 0, function(g, p, m, k)
        local n = 0
        for _, list in ipairs({p.hand, p.spellHand}) do
            for i = #list, 1, -1 do if list[i] and E.discardCard(g, p, list, i) then n = n + 1 end end
        end
        if n == 0 then return false, "Your hand is empty." end
        for _, o in ipairs(p.board) do buff(o, 5 * n * k, 5 * n * k) end
        return true
    end)
    register("S15_tw_looter", {}) -- Tavern rule: E.rollTavern below
    register("S15_tw_mecherel", {shieldLost = function(C, S, o, target)
        if target ~= o and o.hp > 0 then o.shield = true end
    end})
    act("S15_tw_mirror_mage", 0, function(g, p, m, k)
        local options = {}
        for _, o in ipairs(p.board) do if o ~= m and not BG_TIMEWARP[o.id] then options[#options + 1] = o end end
        local t = pick(g, options)
        if not t then return false, "You have no minion to copy." end
        for _ = 1, k do TW.hand(g, p, E.newMinion(g, t.id, t.golden)) end
        return true
    end)
    act("S15_tw_mosher", 1, function(_, _, _, k, t)
        buff(t, 0, 15 * k)
        t.resilient = true
        return true
    end, function(_, m, t) return t ~= m and hasRace(t, "DEMON") end)
    local function storm(g, p, k) spells(g, p, "S15S_dragonstorm", k) end
    register("S15_tw_mount", {bc = function(g, p, _, k) storm(g, p, k) end,
        dr = function(C, S, _, _, k) storm(C.g, ownerOf(C, S), k) end,
        onAttack = function(C, S, _, k) storm(C.g, ownerOf(C, S), k) end})
    act("S15_tw_murozond", 0, function(g, p, _, k)
        local ok = false
        for _ = 1, k do if E.discoverTimewarp(g, p, 5, 2) then ok = true end end
        return ok, "No Timewarped cards are available."
    end)
    act("S15_tw_nether_construct", 1, function(_, p, _, k)
        for _, t in ipairs(p.tavern) do for _ = 1, k do buff(t, t.atk, t.hp) end end
        return true
    end)
    FX["S15E_nightmare"] = {dr = function(C, S, _, pos, k)
        for _ = 1, k or 1 do summon(C, S, "S15_tw_nightmare", false, pos) end
    end}
    register("S15_tw_nightmare", {dr = function(C, S, m, _, k)
        local options = {}
        for _, t in ipairs(S.list) do if t ~= m and t.hp > 0 and hasRace(t, "UNDEAD") then options[#options + 1] = t end end
        for _ = 1, k do
            local t = pick(C.g, options)
            if t then attach(t, "S15E_nightmare") end
        end
    end})
    register("S15_tw_phalanx", {
        afterPlay = function(_, _, m, played)
            local c = card(played.id)
            if c and not c.all and #(c.races or {}) == 0 then m.phalanx = (m.phalanx or 0) + 1 end
        end,
        dr = function(C, S, m, _, k)
            local n = (2 + (m.phalanx or 0)) * k
            TW.eachType(C.g, S.list, function(t) if t ~= m then TW.permanent(C, t, n, n) end end)
        end})
    register("S15_tw_replicator", {dr = function(C, S, _, pos, k)
        local p = ownerOf(C, S)
        if not p then return end
        for _ = 1, k do
            local n = 0
            for _ = 1, 2 do
                local list = #p.spellHand > 0 and p.spellHand or p.hand
                if #list == 0 or not E.discardCard(C.g, p, list, #list) then break end
                n = n + 1
            end
            if n < 2 then break end
            summon(C, S, "S15_tw_replicator", false, pos)
        end
    end})
    register("S15_tw_sabercat", {friendlyDeath = function(C, S, o, dead, k)
        if dead == o or not C_.hasDeathrattle(dead) then return end
        local p = ownerOf(C, S)
        if p then p.bonusSpellAtk = (p.bonusSpellAtk or 0) + k end
    end})
    register("S15_tw_sanctifier", {endTurn = function(g, p, _, k)
        local n = 1
        for _, o in ipairs(p.board) do if o.shield then n = n + 1 end end
        for _ = 1, n * k do E.castGeneratedSpell(g, p, "S15S_sanctify") end
    end})
    register("S15_tw_sergeant", {
        gainObserved = function(_, C, _, m, target, _, a)
            if m == target and a > 0 and not C then m.sergeant = (m.sergeant or 0) + 1 end
        end,
        dr = function(C, S, m, _, k)
            local n = (3 + (m.sergeant or 0)) * k
            for _, o in ipairs(S.list) do if o ~= m and o.hp > 0 then buff(o, 0, n) end end
        end})
    register("S15_tw_slinger", {bc = function(g, p, m, k)
        for _ = 1, k do
            local options = {}
            for _, o in ipairs(p.board) do if o ~= m and not o.golden and hasRace(o, "MURLOC") then options[#options + 1] = o end end
            local t = pick(g, options)
            if not t then break end
            makeGolden(t)
        end
    end})
    register("S15_tw_spawn_of_nzoth", {dr = function(C, S, m, _, k)
        local p = ownerOf(C, S)
        if p then E.deityBless(p, m.atk * k, (m.maxhp or m.hp) * k) end
    end})
    register("S15_tw_sweet_tooth", {bc = function(g, p, _, k) spells(g, p, "BG36_303", k) end,
        dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), "BG36_303", k) end})
    register("S15_tw_terrorguard", {tavernSpell = function(_, p, _, k)
        for _ = 1, 2 * k do E.giftFodder(p, 1) end
    end})
    register("S15_tw_thunder_knight", {bc = function(g, p, _, k) spells(g, p, CMD, k) end,
        dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), CMD, k) end})
    act("S15_tw_tickatus", 3, function(g, p, _, k)
        for _ = 1, k do E.discoverDarkmoon(g, p, 3) end
        return true
    end)
    register("S15_tw_tour_group", {}) -- card-played hook lives in the Season 15 late block
    register("S15_tw_voidpriest", {}) -- discard hook lives in the Season 15 late block
    act("S15_tw_wallow", 3, function(g, p, _, k)
        local ok = false
        for _ = 1, k do
            if E.discoverDarkGift(g, p, {low = 4, high = 6, typed = true,
                label = "Discover a Tier 4+ minion of your most common type with a Dark Gift"}) then ok = true end
        end
        return ok, "No minions are available."
    end)

    -- ----- Major Timewarp spells -----
    spell("S15_tw_fuel", nil, function(g, p)
        local ok = false
        for _ = 1, 2 do
            if E.discoverDarkGift(g, p, {low = 6, high = 6, label = "Discover a Tier 6 minion with a Dark Gift"}) then ok = true end
        end
        return ok, "No Tier 6 minions are available."
    end)
    modes["S15_tw_rite_of_atrocity"] = {}
    for i = 1, 3 do
        modes["S15_tw_rite_of_atrocity"][i] = function(g, p)
            local d = p.discover
            local gift = d and d.s15Gifts and d.s15Gifts[i]
            for _, m in ipairs(p.hand) do
                if m.uid == d.s15Copy then E.applyGift(m, gift, p); return true end
            end
            return false, "That copy is no longer in your hand."
        end
    end
    function TW.giftFits(g, m, gift)
        local c = card(m.id)
        if gift.rare or (gift.minTurn or 0) > g.turn or (gift.maxTurn and gift.maxTurn < g.turn) then return false end
        if gift.race and not hasRace(m, gift.race) then return false end
        if gift.drOnly and not C_.hasDeathrattle(m) then return false end
        if gift.bcOnly and not c.battlecry then return false end
        if gift.shieldOnly and not m.shield then return false end
        return true
    end
    spell("S15_tw_rite_of_atrocity", "board", function(g, p, m)
        if not m then return false, "Choose a friendly minion." end
        local copy = E.newMinion(g, m.id, m.golden)
        if not TW.hand(g, p, copy) then return false, "Your hand is full." end
        local gifts = {}
        for _, gift in ipairs(E.DARK_GIFTS or {}) do if TW.giftFits(g, copy, gift) then gifts[#gifts + 1] = gift end end
        shuffle(g, gifts)
        local chosen, labels = {}, {}
        for i = 1, math.min(3, #gifts) do
            chosen[i] = gifts[i]
            labels[i] = gifts[i].title .. ": " .. (gifts[i].description or "")
        end
        if #chosen > 0 then
            enqueue(p, {kind = "spell_mode", label = "Choose a Dark Gift for the copy", spellId = "S15_tw_rite_of_atrocity",
                options = labels, s15Gifts = chosen, s15Copy = copy.uid})
        end
        return true
    end)
    spell("S15_tw_story", "board", function(_, _, m)
        if not m then return false, "Choose a minion." end
        for _, kw in ipairs(BONUS_KW) do m[kw] = true end
        return true
    end)
    spell("S15_tw_wisdomball", nil, function(g, p) p.s15Wisdom = g.turn; return true end)

    -- ----- price rules (Concierge, Timewarped Future Fighter) -----
    local priceBase = E.spellPrice
    function E.spellPrice(p, entry)
        local price, health = priceBase(p, entry)
        if health or not E.spellScales(entry.id) then return price, health end
        local cut = 0
        for _, m in ipairs(p.board) do if m.id == "S15_tw_concierge" then cut = cut + mult(m) end end
        return math.max(0, price - cut), health
    end
    local minionPrice = E.s15MinionPrice
    function E.s15MinionPrice(p, m)
        local price = minionPrice(p, m)
        if not card(m.id).battlecry then return price end
        local cut = 0
        for _, o in ipairs(p.board) do if o.id == "S15_tw_future_fighter" then cut = cut + mult(o) end end
        return math.max(0, price - cut)
    end

    -- ----- choices -----
    local chooseEffect = E.s15ChooseEffect
    function E.s15ChooseEffect(g, p, index)
        local d = p.discover
        if not d or d.s15Effect ~= "holmes" then return chooseEffect(g, p, index) end
        local id = d.options[index]
        if not id then return false, "That choice is unavailable." end
        if id == d.holmesAnswer then
            local copy = d.holmesCopy
            g.uid = g.uid + 1
            copy.uid = g.uid
            TW.hand(g, p, copy)
            event(g, p.color, "card_draw", "Holmes guessed right!")
        else
            event(g, p.color, "card_play", "Holmes guessed wrong.")
        end
        p.discover = table.remove(p.discoverQueue, 1)
        checkTriples(g, p)
        return true
    end
    local pickSpellChoice = E.pickSpellChoice
    function E.pickSpellChoice(g, p, i)
        local d = p.discover
        local taught = d and d.s15Teach and d.kind == "spell" and d.options[i]
        local ok, err = pickSpellChoice(g, p, i)
        if ok and taught then
            local apprentice = E.newMinion(g, "BG33_890t", false)
            apprentice.taughtSpell = taught
            TW.hand(g, p, apprentice)
        end
        return ok, err
    end

    -- ----- Looter: Tier 1-2 Tavern minions become Bounties -----
    local rollTavern = E.rollTavern
    function E.rollTavern(g, p, ...)
        local a, b, c = rollTavern(g, p, ...)
        if g.season == "s15" and p and p.board then
            local looters = 0
            for _, m in ipairs(p.board) do if m.id == "S15_tw_looter" then looters = looters + 1 end end
            if looters > 0 then
                p.spellShop = p.spellShop or {}
                for i = #p.tavern, 1, -1 do
                    local t = p.tavern[i]
                    if not t.frozen and (t.cardTier or card(t.id).tier) <= 2 then
                        table.remove(p.tavern, i)
                        returnToPool(g, t)
                        table.insert(p.spellShop, instance(g, TW.BOUNTIES[rnd(g, #TW.BOUNTIES)]))
                    end
                end
            end
        end
        return a, b, c
    end

    -- Register FX for every new minion that has no effect table yet, so the Timewarp offers it.
    for _, d in ipairs(TW.DEFS) do
        if d.kind == "minion" and not FX[d.id] then register(d.id, {}) end
        if d.kind == "minion" then card(d.id).fx = "full" end
    end
