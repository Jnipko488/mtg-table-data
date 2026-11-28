    do
    -- ===== Season 15 v3: Blizzard card data, exact pool, golden effects that are not "do it twice" =====
    local P = E.S15_CARD_PATCH
    local TW = E.S15TW
    local function patchOf(id) P[id] = P[id] or {}; return P[id] end
    local function fields(id) local c = patchOf(id); c.fields = c.fields or {}; return c.fields end
    local function fx(id, hooks) local c = patchOf(id); c.fx = c.fx or {}; for k, v in pairs(hooks) do c.fx[k] = v end end

    -- 1. Card text, golden text, tier and stats from Blizzard's 37.2 card library (E.S15_DATA, generated).
    E.S15_SPELL_TEXT = {}
    for id, rec in pairs(E.S15_DATA) do
        if BG_CARDS[id] then
            local f = fields(id)
            for k, v in pairs(rec) do f[k] = v end
        elseif E.SPELLS[id] and rec.text then
            E.S15_SPELL_TEXT[id] = rec.text
        end
    end
    -- Sewer Rat itself has no Taunt (only its Turtle does).
    fields("BG19_010").taunt = false
    -- 2. Shop pool: exactly the 251 Season 15 solo minions (Naga rotated out; Rot Hide Gnoll is in).
    for _, s in ipairs(BG_SEASONS) do if s.key == "s15" then s.pool = E.S15_POOL end end

    -- Spell texts follow the season too.
    local activateSeason = E.activateSeason
    local savedSpellText = {}
    function E.activateSeason(key)
        for id, t in pairs(savedSpellText) do E.SPELLS[id].text = t end
        savedSpellText = {}
        activateSeason(key)
        if key ~= "s15" then return end
        for id, t in pairs(E.S15_SPELL_TEXT) do
            if E.SPELLS[id] then savedSpellText[id] = E.SPELLS[id].text or ""; E.SPELLS[id].text = t end
        end
    end

    -- 3. Golden effects whose golden text is not simply "twice".
    -- Stone Age Slab: +20/+20 and double (golden: +20/+20 and triple).
    fx("BG34_950", {afterBuyMinion = function(g, _, m, k, bought)
        if m.slabArmed ~= g.turn then return end
        m.slabArmed = nil
        buff(bought, 20, 20)
        buff(bought, bought.atk * k, bought.hp * k)
    end})
    -- Prototype Builder: golden summons one Golden Ancestral Automaton.
    function E.s15CombatSpace(C, S)
        if C.g.season ~= "s15" or not C.s15StartComplete or #S.list >= E.MAX_BOARD then return end
        local sources = {}
        for _, m in ipairs(S.list) do
            if m.hp > 0 and m.id == "S15_prototype_builder" and not m.s15Built then sources[#sources + 1] = m end
        end
        for _, m in ipairs(sources) do
            if #S.list >= E.MAX_BOARD then break end
            m.s15Built = true
            summon(C, S, "BG_TTN_401", m.golden and true or false, nil, function(created)
                for _, kw in ipairs({"taunt", "shield", "reborn", "windfury", "venom", "resilient"}) do if m[kw] then created[kw] = true end end
            end)
        end
    end
    -- Ruthless Pursuer: golden adds four Bounties.
    FX["S15_ruthless_pursuer"].sell = function(g, p, _, k)
        p.frozen = false
        E.rollTavern(g, p)
        local bounties = {"BG33_811", "BG33_812", "BG33_813", "BG33_814", "BG33_815"}
        for _ = 1, 2 * k do
            if #p.spellShop >= 6 then break end
            local entry = instance(g, pick(g, bounties))
            entry.s15PriceOverride = 1
            p.spellShop[#p.spellShop + 1] = entry
        end
    end
    -- Faceless Necromancer / Timewarped Necromancer: golden gives your 2 left-most Aberrations Reborn.
    local function leftAberrations(p, k, temp)
        local n = 0
        for _, o in ipairs(p.board) do
            if n >= k then break end
            if hasRace(o, "ABERRATION") then
                if temp then E.tempBuff(o, 0, 0, "reborn") else o.reborn = true end
                n = n + 1
            end
        end
    end
    local function discardTarget(g, p, target)
        for _, list in ipairs({p.hand, p.spellHand}) do
            for i, c in ipairs(list) do if c == target then return E.discardCard(g, p, list, i) end end
        end
        return false
    end
    E.registerActivation("S15_faceless_necromancer", 0, function(g, p, m, k, target)
        if not discardTarget(g, p, target) then return false, "That card is no longer in your hand." end
        leftAberrations(p, k, true)
        return true
    end, function() return true end, "hand")
    E.registerActivation("S15_tw_necromancer", 0, function(g, p, m, k, target)
        if not discardTarget(g, p, target) then return false, "That card is no longer in your hand." end
        leftAberrations(p, k, false)
        return true
    end, function() return true end, "hand")
    -- Cunning Chameleon: golden Discovers 2 Deathrattle minions (and copies both Deathrattles).
    E.registerActivation("S15_cunning_chameleon", 2, function(g, p, m, k)
        local ok, err
        for _ = 1, k do ok, err = E.s15ChooseDeathrattle(g, p, m, 1) end
        return ok, err
    end)
    -- Timewarped Holmes: one guess; golden gets 2 copies of the right answer.
    E.registerActivation("S15_tw_holmes", 0, function(g, p, m, k)
        local foe = TW.foeOf(g, p)
        local board = type(foe) == "table" and foe.board
        if type(board) ~= "table" or #board == 0 then return false, "Your next opponent has no minions to guess." end
        local answer = pick(g, board)
        local ids, seen = {answer.id}, {[answer.id] = true}
        local others = {}
        for id, n in pairs(g.pool) do if n > 0 and not seen[id] and card(id) then others[#others + 1] = id end end
        table.sort(others)
        shuffle(g, others)
        for i = 1, math.min(2, #others) do ids[#ids + 1] = others[i] end
        shuffle(g, ids)
        local copies = {}
        for i = 1, k do copies[i] = TW.copy(g, answer) end
        E.offerMinionChoice(g, p, ids, "Holmes: which minion is in your next opponent's warband?",
            {s15Effect = "holmes", holmesAnswer = answer.id, holmesCopy = copies[1], holmesCopies = copies})
        return true
    end)
    local holmesChoose = E.s15ChooseEffect
    function E.s15ChooseEffect(g, p, index)
        local d = p.discover
        if d and d.s15Effect == "holmes" and d.holmesCopies and d.options[index] == d.holmesAnswer then
            for i = 2, #d.holmesCopies do
                local copy = d.holmesCopies[i]
                g.uid = g.uid + 1
                copy.uid = g.uid
                TW.hand(g, p, copy)
            end
        end
        return holmesChoose(g, p, index)
    end
    -- Timewarped Soldier: golden gives double the stats to your Deity.
    FX["S15_tw_soldier"].gainObserved = function(p, _, _, m, target, k, a, h)
        if m == target then E.deityBless(p, a * mult(m), h * mult(m)) end
    end
    -- Timewarped Nightmare: golden gives "Deathrattle: Summon a Golden Timewarped Nightmare" (once).
    FX["S15E_nightmare_g"] = {dr = function(C, S, _, pos) summon(C, S, "S15_tw_nightmare", true, pos) end}
    FX["S15_tw_nightmare"].dr = function(C, S, m)
        local options = {}
        for _, t in ipairs(S.list) do if t ~= m and t.hp > 0 and hasRace(t, "UNDEAD") then options[#options + 1] = t end end
        local t = pick(C.g, options)
        if t then attach(t, m.golden and "S15E_nightmare_g" or "S15E_nightmare") end
    end
    -- Timewarped Replicator: discard your 2 right-most cards (Tavern spells sit right of minions in hand) to
    -- summon a Timewarped Replicator (golden: a Golden one).
    FX["S15_tw_replicator"].dr = function(C, S, m, pos)
        local p = ownerOf(C, S)
        if not p then return end
        local n = 0
        for _ = 1, 2 do
            local list = #p.spellHand > 0 and p.spellHand or p.hand
            if #list == 0 or not E.discardCard(C.g, p, list, #list) then break end
            n = n + 1
        end
        if n == 2 then summon(C, S, "S15_tw_replicator", m.golden and true or false, pos) end
    end
    -- Timewarped Muscle-o-Tron: Mission: double this minion's stats (golden: triple).
    FX["S15_tw_muscle_o_tron"].magnetized = function(g, p, m)
        if p.lastMagnetTarget ~= m then return end
        mission(g, p, m, 3, 1, function() local f = m.golden and 2 or 1; buff(m, m.atk * f, m.hp * f) end)
    end
    -- Timewarped Amalgadon: Deathrattle: Summon two 1/1 Plants (golden: four).
    FX["S15_tw_amalgadon"].dr = function(C, S, m, pos)
        for i = 1, 2 * mult(m) do summon(C, S, TW.PLANT, false, pos + i - 1) end
    end
    -- Timewarped Ball of Minions: give a different friendly minion this minion's stats (golden: double).
    E.registerActivation("S15_tw_ball_of_minions", 3, function(_, _, m, k, t)
        if not t or t == m then return false, "Choose a different friendly minion." end
        buff(t, m.atk * k, m.hp * k)
        return true
    end, function(_, m, t) return t ~= m end)
    -- Timewarped Looter: golden also replaces Tier 3 offers.
    local looterRoll = E.rollTavern
    function E.rollTavern(g, p, ...)
        local a, b, c = looterRoll(g, p, ...)
        if g.season == "s15" and p and p.board then
            local cap = 0
            for _, m in ipairs(p.board) do if m.id == "S15_tw_looter" then cap = math.max(cap, m.golden and 3 or 2) end end
            if cap == 3 then
                p.spellShop = p.spellShop or {}
                for i = #p.tavern, 1, -1 do
                    local t = p.tavern[i]
                    if not t.frozen and (t.cardTier or card(t.id).tier) == 3 then
                        table.remove(p.tavern, i)
                        returnToPool(g, t)
                        table.insert(p.spellShop, instance(g, TW.BOUNTIES[rnd(g, #TW.BOUNTIES)]))
                    end
                end
            end
        end
        return a, b, c
    end
    -- Timewarped Sergeant: improves permanently after this gains Attack, in combat too.
    FX["S15_tw_sergeant"].gainObserved = function(p, C, _, m, target, _, a)
        if m ~= target or not a or a <= 0 then return end
        m.sergeant = (m.sergeant or 0) + 1
        if C and p then
            for _, o in ipairs(p.board) do
                if o.uid == m.src or o.uid == m.uid then o.sergeant = (o.sergeant or 0) + 1; break end
            end
        end
    end
    -- Timewarped Graverobber counts as having a Deathrattle only while it holds a destroyed minion.
    if C_.hasDeathrattle then
        local hasDr = C_.hasDeathrattle
        function C_.hasDeathrattle(m, ...)
            if m and m.id == "S15_tw_graverobber" then return m.graveCopies ~= nil and #m.graveCopies > 0 end
            return hasDr(m, ...)
        end
    end
    end
