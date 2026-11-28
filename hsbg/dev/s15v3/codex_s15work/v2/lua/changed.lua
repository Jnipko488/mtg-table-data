    -- ===== Season 15 card changes (text, effects, Timewarp costs) =====
    -- E.S15_CARD_PATCH[id] = {fields = {...}, fx = {...}, tw = {...}}
    --   fields: BG_CARDS fields for Season 15 (stats are in E.seasonStats.s15)
    --   fx:     hooks that replace this card's hooks in Season 15 (false removes a hook)
    --   tw:     BG_TIMEWARP fields for Season 15 (cost, tribes)
    -- E.activateSeason applies the patch for "s15" and puts the old values back for any other season.
    local P = {}
    E.S15_CARD_PATCH = P
    local function patch(id, fields, fx, tw) P[id] = {fields = fields, fx = fx, tw = tw} end
    local function each(list, race, fn) for _, m in ipairs(list) do if m.hp > 0 and (not race or hasRace(m, race)) then fn(m) end end end
    local function gems(g, p, n) if p then for _ = 1, n do if not E.giveSpell(g, p, "BG20_GEM") then break end end end end
    local NO_KW = {"taunt", "shield", "reborn", "windfury", "venom", "resilient", "stealth"}

    -- Changed minions
    patch("BG32_237", {text = "Choose One - Your Tavern spells give an extra +2 Attack this game; or +2 Health.",
        gtext = "Choose One - Your Tavern spells give an extra +4 Attack this game; or +4 Health."})
    patch("BG25_016", {text = "Divine Shield, Windfury Rally: Remove all Bonus Keywords from the target.",
        gtext = "Divine Shield, Windfury Rally: Remove all Bonus Keywords from the target."},
        {onAttack = function(_, _, _, _, target)
            if target then for _, kw in ipairs(NO_KW) do target[kw] = false end; target.shieldHits = nil end
        end})
    patch("BG36_763", {text = "Mission: Once this deals 35 damage, get a Golden Touch. (35 left!)",
        gtext = "Mission: Once this deals 35 damage, get 2 Golden Touches. (35 left!)"})
    patch("BG36_098", {text = "When you sell this, get a 1/1 Tentacle.", gtext = "When you sell this, get two 1/1 Tentacles."},
        {sell = function(g, p, _, k)
            for _ = 1, k do E.S15TW.hand(g, p, E.newMinion(g, "S15T_tentacle", false)) end
        end})
    patch("BG36_116", {text = "Deathrattle: Summon a 1/1 Tentacle. Give your minions +1 Attack.",
        gtext = "Deathrattle: Summon two 1/1 Tentacles. Give your minions +2 Attack."},
        {dr = function(C, S, _, pos, k)
            for i = 1, k do summon(C, S, "S15T_tentacle", false, pos + i - 1) end
            for _, m in ipairs(livingOf(S)) do buff(m, k, 0) end
        end})
    patch("BG36_113", {taunt = true, text = "Taunt. Reborn Deathrattle: Give your Deity +2/+1.",
        gtext = "Taunt. Reborn Deathrattle: Give your Deity +4/+2."})
    patch("BGFYM_005", {text = "Whenever you discard a card, give your Deity +1/+1 and improve this.",
        gtext = "Whenever you discard a card, give your Deity +2/+2 and improve this."},
        {discard = function(_, p, m, k)
            local times = m.appearanceCount or 0
            E.deityBless(p, (1 + times) * k, (1 + times) * k)
            m.appearanceCount = times + 1
        end})
    patch("BG35_602", {text = "Whenever you summon a Beast, give it +2 Attack and improve this permanently.",
        gtext = "Whenever you summon a Beast, give it +4 Attack and improve this permanently."},
        {summon = function(self, s, combat)
            if not hasRace(s, "BEAST") then return end
            self.lev = self.lev or 0
            buff(s, (2 + self.lev) * mult(self), 0)
            if not combat then self.lev = self.lev + 1 end
        end})
    patch("BGS_018", {text = "Deathrattle: Your Beasts have +5/+5 this game (wherever they are).",
        gtext = "Deathrattle: Your Beasts have +10/+10 this game (wherever they are)."},
        {dr = function(C, S, _, _, k)
            local p = ownerOf(C, S)
            if p then E.beastAura(p, 5 * k, 5 * k) end
            if not C.recruit then each(S.list, "BEAST", function(m) buff(m, 5 * k, 5 * k) end) end
        end})
    patch("BG36_762", {text = "Whenever you cast a spell on this, give minions in the Tavern +1/+1 this game.",
        gtext = "Whenever you cast a spell on this, give minions in the Tavern +2/+2 this game."},
        {spellTarget = function(_, p, m, k, target) if m == target then tavernAura(p, "all", k, k) end end})
    patch("BG26_523", {text = "After your hero takes damage, give your Demons +2/+2. At the end of your turn, improve this.",
        gtext = "After your hero takes damage, give your Demons +4/+4. At the end of your turn, improve this."},
        {heroDamaged = function(_, p, m, k)
            local n = (2 + (m.tich or 0)) * k
            for _, o in ipairs(p.board) do if hasRace(o, "DEMON") then buff(o, n, n) end end
        end,
        endTurn = function(_, _, m) m.tich = (m.tich or 0) + 1 end})
    patch("BG35_814", {text = "Mission: Once this reaches 6 Attack, gain Divine Shield permanently.",
        gtext = "Mission: Once this reaches 6 Attack, gain Divine Shield permanently."})
    patch("BG34_950", {text = "Activate (0): Give the next minion you buy this turn +20/+20 and double its stats.",
        gtext = "Activate (0): Give the next minion you buy this turn +40/+40 and double its stats twice."},
        {afterBuyMinion = function(g, _, m, k, bought)
            if m.slabArmed ~= g.turn then return end
            m.slabArmed = nil
            buff(bought, 20 * k, 20 * k)
            for _ = 1, k do buff(bought, bought.atk, bought.hp) end
        end})
    patch("BG36_854", {battlecry = true, text = "Taunt Battlecry and Deathrattle: Get a Repair Job.",
        gtext = "Taunt Battlecry and Deathrattle: Get 2 Repair Jobs."},
        {bc = function(g, p, _, k) spells(g, p, "BG36_624", k) end})
    patch("BG31_148", {text = "Battlecry: Give your other minions +3/+2. Repeat for each different Bonus Keyword in your warband.",
        gtext = "Battlecry: Give your other minions +6/+4. Repeat for each different Bonus Keyword in your warband."},
        {bc = function(_, p, m, k)
            local seen, n = {}, 0
            for _, o in ipairs(p.board) do
                for _, kw in ipairs(BONUS_KW) do if o[kw] and not seen[kw] then seen[kw] = true; n = n + 1 end end
            end
            for _ = 1, 1 + n do
                for _, o in ipairs(p.board) do if o ~= m then buff(o, 3 * k, 2 * k) end end
            end
        end})
    patch("BG32_235", {text = "At the end of your turn, give adjacent minions +2 Attack. Repeat for each friendly Golden minion.",
        gtext = "At the end of your turn, give adjacent minions +4 Attack. Repeat for each friendly Golden minion."},
        {endTurn = function(_, p, m, k)
            local reps = 1
            for _, o in ipairs(p.board) do if o.golden and o ~= m then reps = reps + 1 end end
            for _ = 1, reps do
                local i = indexOf(p.board, m)
                if not i then return end
                for _, j in ipairs({i - 1, i + 1}) do if p.board[j] then buff(p.board[j], 2 * k, 0) end end
            end
        end})
    patch("BG36_344", {text = "After you Discover a card, give your other Pirates +2/+2. (Improved by Golden minions you played this game!)",
        gtext = "After you Discover a card, give your other Pirates +4/+4. (Improved by Golden minions you played this game!)"},
        {discovered = function(_, p, self, k)
            local n = (2 + (p.goldenPlayed or 0)) * k
            for _, m in ipairs(p.board) do if m ~= self and hasRace(m, "PIRATE") then buff(m, n, n) end end
        end})

    -- Returning minions with changes
    patch("BG28_590", {text = "At the end of your turn, gain +1/+1.", gtext = "At the end of your turn, gain +2/+2."},
        {endTurn = function(_, _, m, k) buff(m, k, k) end})
    patch("BG31_301", {battlecry = false, text = "Activate (1): Trigger another friendly minion's end of turn effects.",
        gtext = "Activate (1): Trigger another friendly minion's end of turn effects twice.", note = false, fx = "full"},
        {bc = false})
    patch("BG24_003", {text = "At the end of your turn, give your Dragons +2/+2 and improve this.",
        gtext = "At the end of your turn, give your Dragons +4/+4 and improve this."},
        {endTurn = function(_, p, m, k)
            local amount = m.s15NetherDrake or 2
            for _, o in ipairs(p.board) do if hasRace(o, "DRAGON") then buff(o, amount * k, amount * k) end end
            m.s15NetherDrake = amount + 1
        end})
    patch("BGS_121", {battlecry = false, text = "Taunt Deathrattle: Get a random Elemental.",
        gtext = "Taunt Deathrattle: Get 2 random Elementals."}, {bc = false})
    local function paint(p, k, tier)
        if tier and tier <= 3 then for _, m in ipairs(p.board) do if hasRace(m, "MURLOC") then buff(m, 4 * k, 4 * k) end end end
    end
    patch("BG33_893", {text = "After you play a card from Tier 3 or below, give your Murlocs +4/+4.",
        gtext = "After you play a card from Tier 3 or below, give your Murlocs +8/+8."},
        {afterPlay = function(_, p, _, m, k) paint(p, k, m.cardTier or card(m.id).tier) end,
         anySpell = function(_, p, _, k, definition) paint(p, k, definition and definition.tier) end})
    patch("BG25_032", {text = "Whenever a card is added to your hand, give another friendly Pirate +2/+2.",
        gtext = "Whenever a card is added to your hand, give another friendly Pirate +2/+2 twice."},
        {handGained = function(g, p, m, k)
            for _ = 1, k do
                local options = {}
                for _, o in ipairs(p.board) do if o ~= m and hasRace(o, "PIRATE") then options[#options + 1] = o end end
                local target = pick(g, options)
                if target then buff(target, 2, 2) end
            end
        end})
    patch("BG33_826", {text = "Whenever you cast a Tavern spell, give your Pirates +3/+2.",
        gtext = "Whenever you cast a Tavern spell, give your Pirates +6/+4."},
        {tavernSpell = function(_, p, _, k) for _, o in ipairs(p.board) do if hasRace(o, "PIRATE") then buff(o, 3 * k, 2 * k) end end end})
    patch("BG30_124", {text = "Whenever you summon an Undead, gain +2/+2 permanently. (+6/+6 if it doesn't fit!)",
        gtext = "Whenever you summon an Undead, gain +4/+4 permanently. (+12/+12 if it doesn't fit!)"},
        {summon = false,
         recruitSummon = function(_, _, o, k, m) if m ~= o and hasRace(m, "UNDEAD") then buff(o, 2 * k, 2 * k) end end,
         combatSummon = function(C, _, o, k, m) if m ~= o and hasRace(m, "UNDEAD") then E.S15TW.permanent(C, o, 2 * k, 2 * k) end end})
    patch("BG30_129", {text = "Whenever you would summon an excess minion, give your minions +2/+2 permanently.",
        gtext = "Whenever you would summon an excess minion, give your minions +4/+4 permanently."})

    -- Minor Timewarp returning with changes
    patch("BG34_HeroPowerSpell_006", nil, nil, {cost = 1})
    patch("BG34_HeroPowerSpell_015", nil, nil, {cost = 1})
    patch("BG34_Giant_001", {atk = 6, hp = 4, gatk = 12, ghp = 8})
    patch("BG34_Giant_583", {text = "Activate (0): Consume another friendly minion to gain its stats and 3 Gold.",
        gtext = "Activate (0): Consume another friendly minion to gain twice its stats and 6 Gold."}, {startTurn = false})
    patch("BG34_Giant_305", {gtext = "Avenge (5): Get 2 Blood Gems. Your Blood Gems give an extra +2/+2 this game."},
        {avenge = {n = 5, fn = function(C, S, _, k)
            local p = ownerOf(C, S)
            if p then p.gemA, p.gemH = p.gemA + k, p.gemH + k; gems(C.g, p, k) end
        end}})
    patch("BG34_Giant_581", {text = "Whenever a friendly Beast dies, gain +2/+3 permanently.",
        gtext = "Whenever a friendly Beast dies, gain +4/+6 permanently."},
        {friendlyDeath = function(C, _, m, dead, k) if hasRace(dead, "BEAST") then C_.trinketPermanent(C, m, 2 * k, 3 * k) end end})
    patch("BG34_Giant_066", {text = "The Tavern always offers 1 extra Tavern spell. Your Tavern spells give an extra +2/+2.",
        gtext = "The Tavern always offers 2 extra Tavern spells. Your Tavern spells give an extra +4/+4."}, {spellAura = {2, 2}})
    patch("BG34_Giant_300", {atk = 5, hp = 6, gatk = 10, ghp = 12,
        text = "After your hero takes damage, rewind it and give your Demons +2 Health.",
        gtext = "After your hero takes damage, rewind it and give your Demons +4 Health."},
        {rewind = function(_, p, _, k) each(p.board, "DEMON", function(m) buff(m, 0, 2 * k) end) end})
    patch("BG34_Giant_202", {atk = 4, hp = 3, gatk = 8, ghp = 6,
        text = "After you trigger a Deathrattle, gain +4/+3 permanently.",
        gtext = "After you trigger a Deathrattle, gain +8/+6 permanently."},
        {afterDeathrattle = function(C, _, m, k) C_.trinketPermanent(C, m, 4 * k, 3 * k) end})
    patch("BG34_Giant_209", {text = "At the end of your turn, cast Repair Job on adjacent Mechs.",
        gtext = "At the end of your turn, cast Repair Job on adjacent Mechs twice."},
        {endTurn = function(g, p, m, k)
            local i = indexOf(p.board, m)
            if not i then return end
            local near = {p.board[i - 1], p.board[i + 1]}
            for j = 1, 2 do
                local t = near[j]
                if t and hasRace(t, "MECHANICAL") then for _ = 1, k do E.castSpellOnBoard(g, p, "BG36_624", t) end end
            end
        end}, {cost = 2})
    patch("BG34_Giant_604", {text = "Activate (1): Increase your maximum Gold by 1.",
        gtext = "Activate (1): Increase your maximum Gold by 2."}, {endTurn = false})
    patch("BG34_Giant_064", {races = {"DRAGON"}}, nil, {tribes = {"DRAGON"}})

    -- Major Timewarp returning with changes
    patch("BG34_PreMadeChamp_078", {text = "Activate (0): Discard a card for this to play 4 Blood Gems on all your minions.",
        gtext = "Activate (0): Discard a card for this to play 8 Blood Gems on all your minions."}, {startTurn = false})
    patch("BG34_PreMadeChamp_076", {text = "Activate (0): Get 5 Blood Gems. They also count as Tavern spells.",
        gtext = "Activate (0): Get 10 Blood Gems. They also count as Tavern spells."}, {startTurn = false})
    patch("BG34_Giant_618", nil, nil, {cost = 1})
    patch("BG34_Giant_680", {text = "Also damages adjacent minions. Rally: If you control another Golden minion, gain Divine Shield.",
        gtext = "Also damages adjacent minions. Rally: If you control another Golden minion, gain Divine Shield."},
        {onAttack = function(_, S, m)
            for _, t in ipairs(livingOf(S)) do if t ~= m and t.golden then m.shield = true; return end end
        end})
    patch("BG34_Giant_362", {atk = 12, hp = 12, gatk = 24, ghp = 24, text = "Deathrattle: Cast Goldrinn's Blessing twice.",
        gtext = "Deathrattle: Cast Goldrinn's Blessing 4 times."},
        {dr = function(C, S, _, _, k) for _ = 1, 2 * k do E.S15TW.combatBlessing(C, S) end end}, {cost = 1})
    patch("BG34_PreMadeChamp_013", {text = "After you spend 7 Gold, give minions in the Tavern +3/+3 this game. (7 Gold left!)",
        gtext = "After you spend 7 Gold, give minions in the Tavern +6/+6 this game. (7 Gold left!)"},
        {spend = function(_, p, m, n, k)
            m.timewarpCount = (m.timewarpCount or 0) + n
            while m.timewarpCount >= 7 do m.timewarpCount = m.timewarpCount - 7; tavernAura(p, "all", 3 * k, 3 * k) end
        end})
    patch("BG34_Giant_608", nil, nil, {cost = 1})
    patch("BG34_Giant_205", {races = {}, all = true, atk = 13, hp = 13, gatk = 26, ghp = 26,
        text = "At the end of your turn, give a friendly minion of each type +3/+3. (Improved by each Tavern spell you've cast this turn!)",
        gtext = "At the end of your turn, give a friendly minion of each type +6/+6. (Improved by each Tavern spell you've cast this turn!)"},
        {anySpell = false,
         endTurn = function(g, p, _, k)
             local n = (3 + (p.s15TavernSpellsTurn or 0)) * k
             E.S15TW.eachType(g, p.board, function(m) buff(m, n, n) end)
         end}, {tribes = {"ALL"}})
    patch("BG34_Giant_032", {races = {"ELEMENTAL"}, text = "After you play an Elemental, give minions in the Tavern +5/+5 this game.",
        gtext = "After you play an Elemental, give minions in the Tavern +10/+10 this game."},
        {afterPlay = function(_, p, _, played, k) if hasRace(played, "ELEMENTAL") then tavernAura(p, "all", 5 * k, 5 * k) end end},
        {tribes = {"ELEMENTAL"}})
    patch("BG34_Giant_319", {text = "At the end of your turn, give your minions +1/+1. After you play a card from Tier 3 or below, improve this.",
        gtext = "At the end of your turn, give your minions +2/+2. After you play a card from Tier 3 or below, improve this."},
        {endTurn = function(_, p, m, k)
            local n = (1 + (m.timewarpGrowth or 0)) * k
            for _, o in ipairs(p.board) do buff(o, n, n) end
        end})
    patch("BG34_PreMadeChamp_022", {text = "At the end of your turn, cast Azerite Empowerment twice.",
        gtext = "At the end of your turn, cast Azerite Empowerment 4 times."},
        {avenge = false, endTurn = function(g, p, _, k) for _ = 1, 2 * k do E.castGeneratedSpell(g, p, "BG28_169") end end})

    -- Season 15 activations on cards that had none before (only active in Season 15 lobbies).
    local function s15act(id, cost, effect, accepts, zone)
        E.registerActivation(id, cost, effect, accepts, zone, true)
        E.ACTIVATE[id].season = "s15"
    end
    s15act("BG34_950", 0, function(g, _, m) m.slabArmed = g.turn; return true end)
    s15act("BG31_301", 1, function(g, p, m, k, t)
        for _ = 1, k do if indexOf(p.board, t) then E.S15TW.endTurnOf(g, p, t) end end
        return true
    end, function(_, m, t) return t ~= m and E.S15TW.hasEndTurn(t) end)
    s15act("BG34_Giant_583", 0, function(g, p, m, k, t)
        local i = indexOf(p.board, t)
        if not i then return false, "Choose another friendly minion." end
        table.remove(p.board, i)
        buff(m, t.atk * k, t.hp * k)
        returnToPool(g, t)
        p.gold = math.min(99, p.gold + 3 * k)
        return true
    end, function(_, m, t) return t ~= m end)
    s15act("BG34_Giant_604", 1, function(_, p, _, k) p.extraMaxGold = (p.extraMaxGold or 0) + k; return true end)
    s15act("BG34_PreMadeChamp_078", 0, function(g, p, _, k, target)
        local done = false
        for _, list in ipairs({p.hand, p.spellHand}) do
            for i, c in ipairs(list) do if c == target then done = E.discardCard(g, p, list, i); break end end
            if done then break end
        end
        if not done then return false, "That card is no longer in your hand." end
        for _, m in ipairs(p.board) do E.applyGems(g, p, m, 4 * k) end
        return true
    end, function() return true end, "hand")
    s15act("BG34_PreMadeChamp_076", 0, function(g, p, _, k)
        for _ = 1, 5 * k do
            if E.giveSpell(g, p, "BG20_GEM") then p.spellHand[#p.spellHand].alsoTavern = true end
        end
        return true
    end)

    -- Season switch: apply the patch for "s15", undo it for every other season.
    do
        local savedCard, savedFx, savedTw = {}, {}, {}
        local NONE = {}
        local baseActivate = E.activateSeason
        function E.activateSeason(key)
            for id, def in pairs(savedCard) do BG_CARDS[id] = def end
            for id, fx in pairs(savedFx) do FX[id] = fx ~= NONE and fx or nil end
            for id, fields in pairs(savedTw) do
                for field, value in pairs(fields) do BG_TIMEWARP[id][field] = value ~= NONE and value or nil end
            end
            savedCard, savedFx, savedTw = {}, {}, {}
            baseActivate(key)
            if key ~= "s15" then return end
            for id, change in pairs(P) do
                local def = BG_CARDS[id]
                if change.fields and def then
                    local version = {}
                    for field, value in pairs(def) do version[field] = value end
                    for field, value in pairs(change.fields) do
                        if value == false and field ~= "battlecry" and field ~= "taunt" then version[field] = nil else version[field] = value end
                    end
                    savedCard[id] = def
                    BG_CARDS[id] = version
                end
                if change.fx then
                    local old = FX[id]
                    local fx = {}
                    for hook, fn in pairs(old or {}) do fx[hook] = fn end
                    for hook, fn in pairs(change.fx) do if fn == false then fx[hook] = nil else fx[hook] = fn end end
                    savedFx[id] = old or NONE
                    FX[id] = fx
                end
                if change.tw and BG_TIMEWARP[id] then
                    savedTw[id] = {}
                    for field, value in pairs(change.tw) do
                        local before = BG_TIMEWARP[id][field]
                        savedTw[id][field] = before == nil and NONE or before
                        BG_TIMEWARP[id][field] = value
                    end
                end
            end
        end
    end
