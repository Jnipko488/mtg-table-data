"""Batch 19 (on Codex's save 219): more heroes behave like current Hearthstone Battlegrounds."""
def patch(s, replace, HERE):
    # Cariel: share the Conviction counters with her buddy (Captain Fairmount uses carielAttack/Health/Targets, base 1)
    for a, b in [("p.carielA = (p.carielA or 0) + 1", "p.carielAttack = (p.carielAttack or 1) + 1"),
                 ("p.carielH = (p.carielH or 0) + 1", "p.carielHealth = (p.carielHealth or 1) + 1"),
                 ("p.carielN = (p.carielN or 0) + 1", "p.carielTargets = (p.carielTargets or 1) + 1"),
                 ("1 + (p.carielN or 0)", "(p.carielTargets or 1)"), ("1 + (p.carielA or 0)", "(p.carielAttack or 1)"),
                 ("1 + (p.carielH or 0)", "(p.carielHealth or 1)")]:
        if a not in s: raise SystemExit("missing " + a)
        s = s.replace(a, b)
    # Scabbs: I Spy shows your NEXT opponent's warband (recruit pairings are known), like HS
    s = replace(s, '''        local ids, seen = {}, {}
        for _, c in ipairs(g.order) do
            local o = g.players[c]
            if o ~= p and o.alive then for _, m in ipairs(o.board) do if not seen[m.id] then seen[m.id] = true; table.insert(ids, m.id) end end end
        end
        if #ids == 0 then return false, "No opponent has minions yet." end''', '''        local ids, seen = {}, {}
        local opponent
        local okP, pairs_ = pcall(E.recruitPairings, g)
        for _, pair in ipairs(okP and pairs_ or {}) do
            if pair[1] == p then opponent = pair[2] or g.eliminated[#g.eliminated] elseif pair[2] == p then opponent = pair[1] end
        end
        local pool = opponent and {opponent} or {}
        if not opponent then for _, c in ipairs(g.order) do local o = g.players[c]; if o ~= p and o.alive then pool[#pool + 1] = o end end end
        for _, o in ipairs(pool) do for _, m in ipairs(o.board or {}) do if not seen[m.id] then seen[m.id] = true; table.insert(ids, m.id) end end end
        if #ids == 0 then return false, "Your next opponent has no minions." end''')
    s = replace(s, 'NOTE["BG21_HERO_010"] = "Offers minions from any living opponent (the next opponent is not known in advance)."', 'NOTE["BG21_HERO_010"] = nil')
    # Malygos: replace a card in the Tavern or your warband
    s = replace(s, '''HP["TB_BaconShop_HERO_58"] = {target = "board", uses = 2, active = function(g, p, t) -- Malygos
    local m, i = boardTarget(p, t); if not m then return false, i end''', '''HP["TB_BaconShop_HERO_58"] = {target = "any", uses = 2, active = function(g, p, t) -- Malygos
    local list = t and t.zone == "tavern" and p.tavern or p.board
    local i = t and t.index
    local m = i and list[i]
    if not m then return false, "Choose a minion in the Tavern or your warband." end''')
    s = replace(s, '    E.returnToPool(g, m); p.board[i] = n; return true end}\nNOTE["TB_BaconShop_HERO_58"] = "Targets minions in your warband."',
                   '    E.returnToPool(g, m); list[i] = n; return true end}\nNOTE["TB_BaconShop_HERO_58"] = nil')
    # Saurfang: one counter (all buys this game) for both refresh and start of turn
    s = replace(s, '    refresh = function(g, p) local k = 1 + math.floor((p.counters.bought or 0) / 3); for _, m in ipairs(p.tavern) do E.buff(m, k, k) end end,',
                   '    refresh = function(g, p) local k = 1 + math.floor((p.counters.buysTotal or 0) / 3); for _, m in ipairs(p.tavern) do E.buff(m, k, k) end end,')
    s = replace(s, 'NOTE["BG20_HERO_102"] = "Improves by +1/+1 for every 3 minions bought this game."', 'NOTE["BG20_HERO_102"] = nil')
    # Dancin' Deryl: the hat passes to a friendly minion when sold (engine's buddyHats handles the hand-off)
    s = replace(s, 'HP["TB_BaconShop_HERO_36"] = {passive = true, play = function(g, p, m) E.buff(m, 1, 1) end} -- Dancin\' Deryl\nNOTE["TB_BaconShop_HERO_36"] = "The hat does not pass on when the minion is sold."',
                   'HP["TB_BaconShop_HERO_36"] = {passive = true, play = function(g, p, m) E.buff(m, 1, 1); m.buddyHats = (m.buddyHats or 0) + 1 end} -- Dancin\' Deryl\nNOTE["TB_BaconShop_HERO_36"] = nil')
    # Y'Shaarj: summon AND get the same minion
    s = replace(s, '''HP["TB_BaconShop_HERO_92"] = {passive = true, soc = function(C, S, enemy, g) -- Y'Shaarj
    local p = E.C.owner(C, S)
    local id
    if p then local m = E.drawFromPool(g, p.tier, p.tier); if m then id = m.id; E.returnToPool(g, m) end end
    if id then E.C.summon(C, S, id, false) end end}
NOTE["TB_BaconShop_HERO_92"] = "Summons the minion in combat but does not also add it to your hand."''', '''HP["TB_BaconShop_HERO_92"] = {passive = true, -- Y'Shaarj
    endTurn = function(g, p)
        if p.yshaarjPending then E.returnToPool(g, p.yshaarjPending) end
        p.yshaarjPending = E.drawFromPool(g, p.tier, p.tier)
    end,
    soc = function(C, S, enemy, g)
        local p = E.C.owner(C, S)
        local m = p and p.yshaarjPending
        if m then E.C.summon(C, S, m.id, false) end end,
    afterCombat = function(g, p)
        local m = p.yshaarjPending
        p.yshaarjPending = nil
        if not m then return end
        if handRoom(p) then give(g, p, m) else E.returnToPool(g, m) end
    end}
NOTE["TB_BaconShop_HERO_92"] = nil''')
    s = replace(s, 'NOTE["TB_BaconShop_HERO_10"] = "Played as a passive: each sale gives 1 Gold next turn."', 'NOTE["TB_BaconShop_HERO_10"] = nil')
    return s
