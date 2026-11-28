seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
-- v4.2: widgets are decals + buttons on the board (settings: on the controller)
local function host(color)
    if color == "_settings" then return T end
    local _, _, seats = T.env.bgDebugState()
    local g = seats[color] and seats[color].board
    return g and OBJECTS[g] or nil
end
local function has(color, key)
    local h = host(color)
    for _, bt in ipairs(h and h.buttons or {}) do if bt.click_function == "bgW_" .. key then return true end end
    return false
end
local function tclick(color, key) if has(color, key) then click(host(color).guid, "bgW_" .. key, "White"); pump(0.1); return true end return false end
local function setTo(key, want, getter) for _ = 1, 40 do if getter() == want then return end tclick("_settings", key) end end
local BG = T.env.BG
click("f06d01", "toggleTableArena", "White"); pump(1)
local _, st = T.env.bgDebugState()
setTo("o_season", "s15", function() return st.season end)
setTo("o_speed", 1, function() return st.speed end)
tclick("_settings", "o_start"); pump(3)
tclick("White", "pick1"); pump(0.5); tclick("White", "b_pkconfirm"); pump(1)
local g = T.env.bgDebugState()
if g.phase == "hero" then protected("choose", BG.chooseHero, g, "White", 1); pump(2) end
for _ = 1, 20 do g = T.env.bgDebugState(); if g.phase == "recruit" then break end; pump(1) end
print("phase", g.phase, "season", g.season, "deity", g.deity)
local E = BG
DRAW = T.env.bgDebugDraw and T.env.bgDebugDraw()
print("DBG", BG.S15TW, BG.S15_TIMEWARP_POOL, BG.S15_CARD_PATCH, BG.S15_TIMEWARP_REMOVED)
local TW = E.S15TW
print("phase", g.phase, "season", g.season)
local p = g.players.White
local ALLT = {"ABERRATION","BEAST","DEMON","DRAGON","ELEMENTAL","MECHANICAL","MURLOC","NAGA","PIRATE","QUILBOAR","UNDEAD"}
local savedTribes = g.tribes
g.tribes = ALLT
-- 1. Timewarp pool
for _, tier in ipairs({3, 5}) do
    local list = E.timewarpCards(g, tier)
    local n, mins, newc = 0, 0, 0
    local seen = {}
    for _, id in ipairs(list) do n = n + 1; seen[id] = true
        if T.env.BG_TIMEWARP[id].kind == "minion" then mins = mins + 1 end
        if id:sub(1, 7) == "S15_tw_" then newc = newc + 1 end end
    local missing = {}
    for id in pairs(E.S15_TIMEWARP_POOL) do
        local d = T.env.BG_TIMEWARP[id]
        if d and d.tier == tier and not seen[id] then missing[#missing + 1] = id .. " " .. d.name end
        if not d then missing[#missing + 1] = id .. " (no BG_TIMEWARP)" end
    end
    table.sort(missing)
    print("TIMEWARP tier " .. tier .. ": cards " .. n .. " minions " .. mins .. " new " .. newc .. " missing " .. #missing)
    for _, l in ipairs(missing) do print("   MISSING " .. l); ERRORS[#ERRORS + 1] = "missing from timewarp " .. l end
end
g.season = "s14"
for _, tier in ipairs({3, 5}) do
    for _, id in ipairs(E.timewarpCards(g, tier)) do
        if T.env.BG_TIMEWARP[id].s15 then ERRORS[#ERRORS + 1] = "s15 card in s14 timewarp " .. id end
    end
end
g.season = "s15"
g.tribes = savedTribes
-- 2. Shop pool count
local pool
for _, s in ipairs(T.env.BG_SEASONS) do if s.key == "s15" then pool = s.pool end end
print("SHOP POOL " .. #pool)
-- 3. Every new minion: play it, activate it, run turn hooks, fight
local POOLM = {}
for _, id in ipairs(pool) do POOLM[#POOLM + 1] = id end
local function settle()
    for _ = 1, 8 do
        if not p.discover then break end
        local ok, r, err = pcall(E.discoverPick, g, "White", 1)
        if not ok then ERRORS[#ERRORS + 1] = "discover: " .. tostring(r); p.discover = nil end
        if ok and not r then p.discover = nil end
    end
    p.discoverQueue = {}; p.discover = nil
end
local function fresh(seed)
    p.board, p.tavern, p.hand, p.spellHand = {}, {}, {}, {}
    for i = 1, 5 do p.board[i] = E.newMinion(g, POOLM[(seed * 7 + i * 13) % #POOLM + 1], i == 2) end
    for i = 1, 4 do p.tavern[i] = E.newMinion(g, POOLM[(seed * 11 + i * 5) % #POOLM + 1], false) end
    g.uid = g.uid + 1; p.spellHand[1] = {id = "S15S_echoing_roar", uid = g.uid}
    p.hand[1] = E.newMinion(g, POOLM[(seed * 3) % #POOLM + 1], false)
    p.gold = 40; p.discover = nil; p.discoverQueue = {}; p.timewarpVisit = nil
end
local function try(label, f, ...)
    local ok, a, b = pcall(f, ...)
    if not ok then ERRORS[#ERRORS + 1] = label .. ": " .. tostring(a) end
    return ok, a, b
end
local acts, played, fought = 0, 0, 0
local realTurn = g.turn
g.turn = 9
local opp = g.players.Blue or g.players.Red
for i, d in ipairs(TW.DEFS) do
    if d.kind == "minion" then
        for _, golden in ipairs({false, true}) do
            fresh(i + (golden and 50 or 0))
            local m = E.newMinion(g, d.id, golden)
            if not m then ERRORS[#ERRORS + 1] = "newMinion " .. d.id end
            table.insert(p.hand, 1, m)
            local ok, r, err = try("play " .. d.id, E.play, g, "White", 1, #p.board + 1)
            if ok and r then played = played + 1 elseif ok then print("  play refused " .. d.id .. " " .. tostring(err)) end
            settle()
            local idx = E.indexOf(p.board, m)
            if not idx and #p.board < 7 then p.board[#p.board + 1] = m; idx = #p.board end
            if E.activation(g, m) then
                local ok2, r2, e2 = try("activate " .. d.id, E.activateMinion, g, "White", idx)
                if ok2 and r2 then acts = acts + 1 end
                if ok2 and not r2 then print("  activate refused " .. d.id .. " " .. tostring(e2)) end
                settle()
            elseif d.flags.activate then ERRORS[#ERRORS + 1] = "no activation for " .. d.id end
            try("cast " .. d.id, E.castTavernSpell, g, "White", 1, p.board[1] and {zone = "board", index = 1} or nil); settle()
            try("sell " .. d.id, function() if #p.board > 1 then E.sell(g, "White", 1) end end); settle()
            try("endTurn " .. d.id, E.hooks, g, p, "endTurn"); settle()
            try("startTurn " .. d.id, E.hooks, g, p, "startTurn"); settle()
            try("refresh " .. d.id, E.hooks, g, p, "refresh"); settle()
            local foe = {}
            for j = 1, 6 do foe[j] = E.newMinion(g, POOLM[(i * 17 + j * 3) % #POOLM + 1], j == 3) end
            local ok3, res = try("combat " .. d.id, E.simulate, g,
                {color = "White", name = "W", tier = 6, hero = p.hero, board = p.board, trinkets = p.trinkets},
                {color = opp and opp.color, name = "B", tier = 6, hero = opp and opp.hero, board = foe, trinkets = {}}, {noFrames = true})
            if ok3 then fought = fought + 1 end
            local ok4, t = pcall(DRAW.s15MinionAsset, d.id, golden, "cards")
            if not ok4 or not t or not t:find(d.id, 1, true) then ERRORS[#ERRORS + 1] = "art " .. d.id .. " " .. tostring(t) end
        end
    end
end
print("played " .. played .. " activated " .. acts .. " fought " .. fought)
-- 4. Spells and powers
local nsp = 0
for i, d in ipairs(TW.DEFS) do
    if d.kind ~= "minion" then
        fresh(i)
        if not E.SPELLS[d.id] then ERRORS[#ERRORS + 1] = "no spell " .. d.id end
        g.uid = g.uid + 1; p.spellHand = {{id = d.id, uid = g.uid}}
        local txt = E.spellText(p, d.id, p.spellHand[1])
        local tgt = E.SPELLS[d.id].target and {zone = "board", index = 1} or nil
        local ok, r, err = try("cast " .. d.id, E.castTavernSpell, g, "White", 1, tgt)
        print("  SPELL " .. d.id .. " cast " .. tostring(r) .. " " .. tostring(err) .. " :: " .. tostring(txt))
        if ok and r then nsp = nsp + 1 end
        settle()
    end
end
-- 5. Scroll and Piggy Bank
fresh(3)
g.uid = g.uid + 1; p.spellHand = {{id = TW.SCROLL, uid = g.uid}}
g.uid = g.uid + 1; p.spellHand[2] = {id = "S15_tw_piggy_bank", uid = g.uid}
try("scroll", E.SYS.startTurn, g, p)
print("scroll -> hand " .. tostring(p.hand[2] and p.hand[2].id) .. " spells " .. tostring(p.spellHand[1] and p.spellHand[1].id) .. "," .. tostring(p.spellHand[2] and p.spellHand[2].id))
for _, e in ipairs(p.spellHand) do if e.id == "S15_tw_piggy_bank" then print("piggy text: " .. E.spellText(p, e.id, e)) end end
-- 6. Changed cards text
for _, id in ipairs({"BG32_237","BG25_016","BG36_763","BG30_124","BG26_800","BG31_301","BG34_Giant_362","BG34_Giant_581","BGS_018","BG28_590"}) do
    local c = T.env.BG_CARDS[id]
    print("CHG " .. id .. " " .. tostring(c and c.name) .. " " .. tostring(c and c.atk) .. "/" .. tostring(c and c.hp) .. " t" .. tostring(c and c.tier) .. " :: " .. tostring(c and c.text))
end
-- 7. Spell power: Squirky and Battlecruiser
fresh(9)
p.bonusSpellAtk, p.bonusSpellHp = 2, 1
g.uid = g.uid + 1; local e = {id = "S15S_sanctify", uid = g.uid, s15StatBonus = 3}
print("sanctify sp(2,1)+squirky3: " .. E.spellText(p, e.id, e))
for id, s in pairs(E.SPELLS) do if id:find("^BG31_HERO_80%dpt") and s.tavern then print("cruiser " .. id .. ": " .. tostring(E.spellText(p, id))) break end end
print("gem scales: " .. tostring(E.spellScales("BG20_GEM")))
print("== ERRORS: " .. #ERRORS)
for i = 1, math.min(40, #ERRORS) do print(ERRORS[i]) end
