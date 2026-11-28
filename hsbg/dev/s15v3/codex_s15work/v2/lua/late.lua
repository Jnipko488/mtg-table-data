do
    -- ===== Season 15 Timewarp: game-wide hooks (discard, card played, refresh, start of turn) =====
    local TW = E.S15TW
    local function count(p, id)
        local n = 0
        for _, m in ipairs(p.board) do if m.id == id then n = n + (m.golden and 2 or 1) end end
        return n
    end
    local function chain(name, fn)
        local base = E.SYS[name]
        E.SYS[name] = function(g, p, ...)
            if base then base(g, p, ...) end
            if g.season == "s15" and p and p.board then fn(g, p, ...) end
        end
    end
    chain("discard", function(g, p, entry, isSpell)
        E.refreshCardAuras(p, "S15_tw_duke")
        if not entry then return end
        for _, m in ipairs(p.board) do
            local k = m.golden and 2 or 1
            if m.id == "S15_tw_tumor" and not isSpell and entry.atk then
                TW.absorb(m, entry, k)
            elseif m.id == "S15_tw_voidpriest" then
                if m.voidTurn ~= g.turn then m.voidTurn, m.voidCount = g.turn, 0 end
                if m.voidCount < 3 then
                    m.voidCount = m.voidCount + 1
                    if isSpell then E.giveSpell(g, p, entry.id) else TW.hand(g, p, TW.copy(g, entry)) end
                end
            end
        end
    end)
    -- Timewarped Tour Group: whenever you play a card, buff minions of its Tier or higher.
    chain("cardPlayed", function(g, p, played)
        local n = count(p, "S15_tw_tour_group")
        if n == 0 or not played then return end
        local tier
        if E.SPELLS[played.id] then tier = E.SPELLS[played.id].tier
        else tier = played.cardTier or (BG_CARDS[played.id] and BG_CARDS[played.id].tier) end
        if not tier then return end
        for _, m in ipairs(p.board) do
            if (m.cardTier or BG_CARDS[m.id].tier) >= tier then E.buff(m, 2 * n, 2 * n) end
        end
    end)
    -- Timewarped Wisdomball: Refreshes this turn are sometimes helpful.
    chain("refresh", function(g, p)
        if p.s15Wisdom ~= g.turn or p.s15WisdomBusy then return end
        if g.rand(3) ~= 1 then return end
        p.s15WisdomBusy = true
        local ok, err = pcall(E.helpfulRefresh, g, p)
        p.s15WisdomBusy = nil
        if not ok then error(err) end
    end)
    -- Piggy Bank grows; Timewarped Scroll transforms.
    chain("startTurn", function(g, p)
        for i = #p.spellHand, 1, -1 do
            local entry = p.spellHand[i]
            if entry.id == "S15_tw_piggy_bank" then
                entry.piggy = (entry.piggy or 0) + 1
            elseif entry.id == TW.SCROLL and entry.scrollTurn ~= g.turn then
                local options = E.timewarpCards(g, 3, function(d) return d.cost == 2 end)
                if #options > 0 then
                    local id = options[g.rand(#options)]
                    if BG_TIMEWARP[id].kind == "minion" then
                        table.remove(p.spellHand, i)
                        local m = E.newMinion(g, id, false)
                        m.generated = true
                        E.updateCardAuras(p, m)
                        E.bindStatCard(p, m)
                        p.hand[#p.hand + 1] = m
                    else
                        g.uid = g.uid + 1
                        p.spellHand[i] = {id = id, uid = g.uid}
                    end
                end
            end
        end
    end)
    local spellText = E.spellText
    function E.spellText(p, id, entry)
        if id == "S15_tw_piggy_bank" then
            return "Gain " .. (2 + (entry and entry.piggy or 0)) .. " Gold. (Upgrades each turn!)"
        end
        return spellText(p, id, entry)
    end
end
