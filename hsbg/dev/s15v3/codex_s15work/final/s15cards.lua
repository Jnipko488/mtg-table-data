    -- ===== Season 15 handoff: missing cards and returning minions that had no script =====
    -- Blood Gems that also give a Quilboar a keyword (Bristleback Bully, Hog Watcher, Redtusk Thornraiser).
    local function keywordGems(g, p, keyword, count)
        if not p then return end
        for _ = 1, count do
            local before = #p.spellHand
            if not E.giveSpell(g, p, "BG20_GEM") then break end
            for i = before + 1, #p.spellHand do p.spellHand[i].gemKeyword = keyword end
        end
    end
    E.keywordGems = keywordGems
    register("BG35_432", {dr = function(C, S, _, _, k) keywordGems(C.g, ownerOf(C, S), "taunt", k) end})
    register("BG33_888", {bc = function(g, p, _, k) keywordGems(g, p, "shield", k) end})
    register("BG35_433", {endTurn = function(g, p, _, k) keywordGems(g, p, "reborn", k) end})

    -- Growing Ooze (token) and the Oozes that make it.
    BG_CARDS.S15_growing_ooze = {id = "S15_growing_ooze", name = "Growing Ooze", tier = 1, atk = 2, hp = 1,
        races = {"ABERRATION"}, all = false, gatk = 4, ghp = 2, gid = "S15_growing_ooze", pool = false, season = true,
        legend = false, fx = "full", noTriple = true,
        text = "If you discard this, give your minions and Deity +2/+1. Improve future Growing Oozes. (Can't be tripled.)",
        gtext = "If you discard this, give your minions and Deity +2/+1. Improve future Growing Oozes. (Can't be tripled.)"}
    -- Base gift and the improvement each discard adds to the next Growing Ooze.
    E.S15_OOZE = {a = 2, h = 1, stepA = 2, stepH = 1}
    function E.growingOoze(p)
        local n = p and p.oozeLevel or 0
        return E.S15_OOZE.a + n * E.S15_OOZE.stepA, E.S15_OOZE.h + n * E.S15_OOZE.stepH
    end
    function E.giveGrowingOoze(g, p, count)
        if not p then return end
        for _ = 1, count do
            if E.handCount(p) >= E.MAX_HAND then return end
            local m = E.newMinion(g, "S15_growing_ooze", false)
            m.generated = true
            addToHand(g, p, m)
        end
    end
    register("S15_growing_ooze", {})
    register("S15_sickly_ooze", {onAttack = function(C, S, _, k) E.giveGrowingOoze(C.g, ownerOf(C, S), k) end})
    register("S15_ominous_ooze", {bc = function(g, p, _, k) E.giveGrowingOoze(g, p, k) end,
        dr = function(C, S, _, _, k) E.giveGrowingOoze(C.g, ownerOf(C, S), k) end})
    -- called by E.discardCard when a Growing Ooze is discarded
    function E.s15OozeDiscarded(g, p)
        local a, h = E.growingOoze(p)
        for _, m in ipairs(p.board) do buff(m, a, h) end
        E.deityBless(p, a, h)
        p.oozeLevel = (p.oozeLevel or 0) + 1
    end

    -- N'Zoth, the Season 15 Deity: needs 3 Aberration deaths, sleeps again when it dies.
    BG_CARDS.S15_nzoth = {id = "S15_nzoth", name = "N'Zoth", tier = 1, atk = 1, hp = 1, gatk = 2, ghp = 2,
        gid = "S15_nzoth", races = {"ABERRATION"}, all = false, deity = true, fx = "full", deathrattle = true,
        taunt = true, pool = false, season = true, legend = false,
        text = "Deity (3), Taunt. Deathrattle: Return to sleep. Reawakens after 3 friendly Aberrations die (except Deities).",
        gtext = "Deity (3), Taunt. Deathrattle: Return to sleep. Reawakens after 3 friendly Aberrations die (except Deities)."}
    FX.S15_nzoth = {dr = function(C, S) S.awoke, S.deityCount = nil, 0 end}
    E.DEITY_NEED = {BGFYM_000 = 4, BGFYM_011 = 4, S15_nzoth = 3}
    function E.deityNeed(id) return E.DEITY_NEED[id or ""] or 4 end

    -- Returning Season 15 minions that were in the pool without a script.
    BG_CARDS.BG26_800t = BG_CARDS.BG26_800t or {id = "BG26_800t", name = "Cubling", tier = 1, atk = 0, hp = 1,
        gatk = 0, ghp = 2, gid = "", races = {"BEAST"}, all = false, text = "Taunt", gtext = "Taunt", pool = false,
        legend = false, fx = "full", taunt = true, noTriple = true}
    register("BG26_800", {dr = function(C, S, _, pos, k)
        for i = 1, 2 do summon(C, S, "BG26_800t", k > 1, pos + i - 1, function(m) m.taunt = true end) end
    end})
    register("BG26_159", {bc = function(_, p, _, k) p.gemH = (p.gemH or 1) + k end})
    register("BG26_160", {dr = function(C, S, _, _, k)
        local p = ownerOf(C, S)
        if p then p.gemA = (p.gemA or 1) + k end
    end})
    register("BG26_867", {dr = function(C, S, _, _, k)
        for _, o in ipairs(S.list) do if o.hp > 0 and hasRace(o, "QUILBOAR") then C_.gem(C, S, o, 3 * k) end end
    end})
    register("BG32_891", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), "BG28_886", k) end})
    register("BG33_809", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), "S15S_sanctify", k) end})
    register("BG34_694", {dr = function(C, S, _, _, k) spells(C.g, ownerOf(C, S), "BG34_888", k) end})
    register("BG25_032", {handGained = function(g, p, m, k)
        for _ = 1, k do
            local options = {}
            for _, o in ipairs(p.board) do if o ~= m and hasRace(o, "PIRATE") then options[#options + 1] = o end end
            local target = pick(g, options)
            if target then buff(target, 2, 1) end
        end
    end})
    card("BG24_003").text = "At the end of your turn, give your Dragons +1 Attack and improve this."
    register("BG24_003", {endTurn = function(_, p, m, k)
        local amount = m.netherDrake or 1
        friendly(p, amount * k, 0, "DRAGON")
        m.netherDrake = amount + 1
    end})
    register("BG23_016", {bc = function(g, p, m, k)
        local have = {}
        for _, o in ipairs(p.board) do
            if o ~= m then
                local c = card(o.id)
                for _, r in ipairs(c.all and (g.tribes or {}) or c.races or {}) do have[r] = true end
            end
        end
        for _ = 1, k do
            startDiscover(g, p, p.tier, function(c)
                if c.all then return false end
                for _, r in ipairs(c.races or {}) do if not have[r] then return true end end
                return false
            end, "Reef Explorer: Discover a minion of a type you don't control")
        end
    end})
    local function randomBonusKeyword(g, m)
        local options = {}
        for _, kw in ipairs(BONUS_KW) do if not m[kw] then options[#options + 1] = kw end end
        local kw = pick(g, options)
        if kw then m[kw] = true end
    end
    card("BG22_402").text = "Venomous. Start of Combat: For each of your minion types, gain +5/+5 and a random Bonus Keyword."
    register("BG22_402", {soc = function(C, S, m, k)
        local types = {}
        for _, o in ipairs(S.list) do
            if o.hp > 0 then
                local c = card(o.id)
                for _, r in ipairs(c.all and (C.g.tribes or {}) or c.races or {}) do types[r] = true end
            end
        end
        local n = 0
        for _ in pairs(types) do n = n + 1 end
        for _ = 1, n * k do
            buff(m, 5, 5)
            randomBonusKeyword(C.g, m)
        end
    end})
    register("BG32_332", {endTurn = function(g, _, m, k)
        buff(m, 2 * k, 2 * k)
        for _ = 1, k do randomBonusKeyword(g, m) end
    end})
    register("BG35_431", {endTurn = function(g, p, m, k)
        local times = 1
        for _, kw in ipairs(BONUS_KW) do if m[kw] then times = times + 1 end end
        for _ = 1, times do for _, o in ipairs(p.board) do E.applyGems(g, p, o, k) end end
    end})
    card("BG33_884").text = "Whenever a friendly Rally minion attacks, this plays 3 Blood Gems on all your minions."
    register("BG33_884", {allyAttack = function(C, S, _, attacker, k)
        if not attacker or not card(attacker.id) or not card(attacker.id).rally then return end
        for _, ally in ipairs(S.list) do if ally.hp > 0 then C_.gem(C, S, ally, 3 * k) end end
    end})
    register("BG34_175", {magnetized = function(_, p, _, k) friendly(p, 5 * k, 5 * k) end})
    register("BG32_892", {tavernSpell = function(g, p, _, k)
        for _ = 1, k do
            damageHero(g, p, 1)
            friendly(p, 1, 1, "DEMON")
        end
    end})
    register("BG31_871", {tavernSpell = function(g, p, m, k)
        local demons = {}
        for _, o in ipairs(p.board) do if o ~= m and hasRace(o, "DEMON") then demons[#demons + 1] = o end end
        local demon = pick(g, demons)
        if not demon or #p.tavern == 0 then return end
        local victim = table.remove(p.tavern, rnd(g, #p.tavern))
        buff(demon, victim.atk * k, victim.hp * k)
        E.observeConsumption(g, p, victim)
        returnToPool(g, victim)
    end})
    register("BG31_300", {bc = function(g, p, m, k)
        local dragons = {}
        for _, o in ipairs(p.board) do if o ~= m and hasRace(o, "DRAGON") then dragons[#dragons + 1] = o end end
        local target = pick(g, dragons) or m
        for _ = 1, k do E.castSpellOnBoard(g, p, "S15S_echoing_roar", target) end
    end}, "Casts Echoing Roar on a random other friendly Dragon (itself if it is your only Dragon).")
    register("BG31_301", {bc = function(g, p, m, k)
        local options = {}
        for _, o in ipairs(p.board) do
            if o ~= m and o.id ~= "BG22_403" then
                local f = FX[o.id]
                local has = f and f.endTurn and true or false
                for _, part in ipairs(o.attachments or {}) do
                    if FX[part.id] and FX[part.id].endTurn then has = true end
                end
                if has then options[#options + 1] = o end
            end
        end
        local target = pick(g, options)
        if not target then return end
        for _ = 1, k do
            local f = FX[target.id]
            if f and f.endTurn then E.withElementalAura(p, target, f.endTurn, g, p, target, mult(target)) end
            E.dispatchAttached(target, "endTurn", function(fn, n, part) fn(g, p, target, n, part) end)
        end
    end}, "Triggers a random friendly minion that has an end of turn effect.")
    card("BG30_103").text = "Mission: Once this minion survives combat, get a Triple Reward."
    register("BG30_103", {startTurn = function(g, p, m, k)
        if m.missionDone or m.lastSurvived ~= g.turn - 1 then return end
        m.missionDone = true
        for _ = 1, k do E.discoverTriple(g, p) end
    end})
    register("BG30_124", {summon = function(o, m, combat)
        if combat then buff(m, 3 * mult(o), 3 * mult(o)) end
    end})
    register("BG30_129", {})
    local excessSummon = E.s15ExcessSummon
    function E.s15ExcessSummon(C, S)
        excessSummon(C, S)
        local function grow(m, n)
            if C.recruit then buff(m, n, n) else C_.trinketPermanent(C, m, n, n) end
        end
        for _, o in ipairs(S.list) do
            if o.hp > 0 and o.id == "BG30_124" then grow(o, 3 * mult(o)) end
        end
        for _, o in ipairs(S.list) do
            if o.hp > 0 and o.id == "BG30_129" then
                for _, ally in ipairs(S.list) do if ally.hp > 0 then grow(ally, 2 * mult(o)) end end
            end
        end
    end

