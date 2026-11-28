-- ===== Season 15 heroes: Vanessa the Ringleader and Eternus =====
E.S15_HEROES = {S15_HERO_vanessa = true, S15_HERO_eternus = true}
table.insert(BG_HEROES, {id = "S15_HERO_vanessa", name = "Vanessa the Ringleader", hp = 30, armor = 15,
    power = "Strategic Edge", pid = "S15_HERO_vanessa_p", cost = 2, scripted = true,
    text = "Discover a Tier 1 minion. (Improved by each minion you've bought this turn!)"})
table.insert(BG_HEROES, {id = "S15_HERO_eternus", name = "Eternus", hp = 30, armor = 10,
    power = "Dawn of the Infinite", pid = "S15_HERO_eternus_p", cost = 0, scripted = true,
    text = "Skip your first turn to visit the Major Timewarp instead. Lock cards you buy until you spend 45 Gold."})
if E._heroMap then
    for _, h in ipairs(BG_HEROES) do E._heroMap[h.id] = h end
end

local function vanessaTier(g, p)
    local bought = p.vanessaTurn == g.turn and p.vanessaBought or 0
    return math.min(g.maxTier or 6, 1 + bought)
end
HP["S15_HERO_vanessa"] = {
    buy = function(g, p)
        if p.vanessaTurn ~= g.turn then p.vanessaTurn, p.vanessaBought = g.turn, 0 end
        p.vanessaBought = p.vanessaBought + 1
    end,
    active = function(g, p)
        local tier = vanessaTier(g, p)
        if not E.startDiscover(g, p, tier, function(c) return c.tier == tier end,
            "Strategic Edge: Discover a Tier " .. tier .. " minion") then
            return false, "No Tier " .. tier .. " minions are left in the pool."
        end
        return true
    end}

-- Eternus: turn 1 is spent in the Major Timewarp; what is bought there stays locked
-- until 45 Gold has been spent this game.
E.ETERNUS_GOLD = 45
local function isEternus(p)
    local h = p and E.powerHero(p)
    return h and h.id == "S15_HERO_eternus"
end
HP["S15_HERO_eternus"] = {passive = true,
    startTurn = function(g, p)
        if g.turn == 1 and not p.eternusVisited then
            p.eternusVisited = true
            p.gold = 0
            p.eternusLocking = true
            if not E.openTimewarp(g, p, 5) then p.eternusLocking = nil end
        else
            p.eternusLocking = nil
        end
    end,
    spendGold = function(g, p) E.releaseExpeditions(g, p) end}
local timewarpPick = E.timewarpPick
function E.timewarpPick(g, color, index)
    local p = g.players[color]
    local locking = p and p.eternusLocking and isEternus(p) and (p.totalGoldSpent or 0) < E.ETERNUS_GOLD
    local minions, cards = p and #p.hand or 0, p and #p.spellHand or 0
    local ok, err = timewarpPick(g, color, index)
    if ok and locking then
        p.expeditions, p.spellExpeditions = p.expeditions or {}, p.spellExpeditions or {}
        while #p.hand > minions do
            table.insert(p.expeditions, {minion = table.remove(p.hand), gold = E.ETERNUS_GOLD, turn = g.turn + 1})
        end
        while #p.spellHand > cards do
            table.insert(p.spellExpeditions, {spell = table.remove(p.spellHand), gold = E.ETERNUS_GOLD, turn = g.turn + 1})
        end
    end
    return ok, err
end
function E.goldLocked(p, plan)
    return plan.gold and (p.totalGoldSpent or 0) < plan.gold
end

-- Season 15 hero lobby rules.
E.S15_TIMEWARP_REMOVED = {BG34_Giant_582 = true, BG34_Giant_029 = true, BG34_Giant_091 = true,
    BG34_Giant_012 = true, BG34_Giant_332 = true, BG34_HeroPowerSpell_016 = true, BG34_Treasure_620 = true,
    BG34_Treasure_608 = true, BG34_Giant_309 = true, BG34_PreMadeChamp_091 = true, BG34_Giant_674 = true,
    BG34_PreMadeChamp_020 = true, BG34_Giant_015 = true, BG34_Giant_088 = true, BG34_Giant_040 = true,
    BG34_Giant_675 = true, BG34_Giant_686 = true, BG34_Giant_599 = true, BG34_Giant_654 = true,
    BG34_Giant_034 = true, BG34_Giant_330 = true, BG34_Giant_683 = true, BG34_Treasure_302 = true,
    BG34_Treasure_951 = true}
local timewarpCards = E.timewarpCards
function E.timewarpCards(g, tier, filter)
    if g.season ~= "s15" then return timewarpCards(g, tier, filter) end
    return timewarpCards(g, tier, function(d, id)
        if E.S15_TIMEWARP_REMOVED[id] then return false end
        return not filter or filter(d, id)
    end)
end
local heroAvailable = E.heroAvailable
function E.heroAvailable(g, id)
    if E.S15_HEROES[id] and g.season ~= "s15" then return false end
    if g.season == "s15" then
        if (id == "TB_BaconShop_HERO_27" or id == "TB_BaconShop_HERO_49") and E.indexOf(g.tribes or {}, "PIRATE") then
            return false
        end
        if id == "BG34_HERO_000" or id == "BG34_HERO_004" then
            local deity = g.deity
            g.deity = nil
            local ok = heroAvailable(g, id)
            g.deity = deity
            return ok
        end
    end
    return heroAvailable(g, id)
end
for _, h in ipairs(BG_HEROES) do
    if h.id == "TB_BaconShop_HERO_38" then h.text = "At the start of each turn, get 2 Tavern Dish Bananas and give everyone else one." end
end

