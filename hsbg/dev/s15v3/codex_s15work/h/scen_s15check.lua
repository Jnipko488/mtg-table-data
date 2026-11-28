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
local p = g.players.White
local Draw = T.env.bgDebugDraw and T.env.bgDebugDraw()
local function stats(list) local a, h = 0, 0 for _, m in ipairs(list) do a = a + m.atk; h = h + m.hp end return a, h end
local base = {}
for i = 1, 3 do base[i] = BG.newMinion(g, "S15_great_wolf_cub", false) end
local function fresh()
    p.board = {}
    for i = 1, 3 do local m = BG.newMinion(g, "S15_great_wolf_cub", false); p.board[i] = m end
    p.tavern = {}
    for i = 1, 3 do p.tavern[i] = BG.newMinion(g, "S15_great_wolf_cub", false) end
    p.hand = {}; p.spellHand = {}; p.discover = nil; p.gold = 10; p.tavBuff = {}
end
local ids = {}
for id, s in pairs(BG.SPELLS) do if BG.spellScales(id) then ids[#ids + 1] = id end end
table.sort(ids)
local bad = 0
for _, id in ipairs(ids) do
    local res = {}
    for k, bonus in ipairs({{0, 0}, {2, 3}}) do
        fresh(); p.spellAtk, p.spellHp = bonus[1], bonus[2]
        local text = BG.spellText(p, id)
        local shown = Draw and select(2, pcall(Draw.spellCardText, p, {id = id, spell = true})) or "-"
        local a0, h0 = stats(p.board); local ta0, th0 = stats(p.tavern)
        local ok, r = pcall(BG.autoCast, g, p, id, p.board[1])
        local a1, h1 = stats(p.board); local ta1, th1 = stats(p.tavern)
        if not ok then ERRORS[#ERRORS + 1] = "cast " .. id .. ": " .. tostring(r) end
        res[k] = {text = text, shown = tostring(shown):gsub("\n", " | "), da = a1 - a0 + ta1 - ta0, dh = h1 - h0 + th1 - th0, ok = ok and r}
    end
    print(("%s | %s => %s | d0 +%d/+%d d1 +%d/+%d"):format(id, res[1].text, res[2].text, res[1].da, res[1].dh, res[2].da, res[2].dh))
    print("      shown: " .. res[2].shown)
end
p.spellAtk, p.spellHp = 0, 0
-- Squirky style bonus on one entry
local entry = {id = "S15S_dragonstorm", s15StatBonus = 1}
print("entry bonus text: " .. BG.spellText(p, "S15S_dragonstorm", entry))
-- heroes
for _, hid in ipairs({"S15_HERO_vanessa", "S15_HERO_eternus"}) do print(hid, BG.heroAvailable(g, hid), BG.heroById(hid) and BG.heroById(hid).name) end
print("Sindragosa avail", BG.heroAvailable(g, "TB_BaconShop_HERO_27"), "tribes", table.concat(g.tribes or {}, ","))
-- Vanessa
p.hero = "S15_HERO_vanessa"; p.powerHero = nil; fresh(); p.vanessaBought = nil
BG.HP.S15_HERO_vanessa.buy(g, p); BG.HP.S15_HERO_vanessa.buy(g, p)
local ok, r, e = pcall(BG.HP.S15_HERO_vanessa.active, g, p)
print("vanessa active", ok, r, e, p.discover and p.discover.label)
if p.discover then for i, o in ipairs(p.discover.options or {}) do print("   option", o.id or (o.m and o.m.id), BG_CARDS and "" or "", T.env.BG_CARDS[o.id or (o.m and o.m.id) or ""] and T.env.BG_CARDS[o.id or o.m.id].tier) end end
if Draw then local ok2, t = pcall(Draw.powerState, g, p, BG.heroById("S15_HERO_vanessa")); print("vanessa text", ok2, t) end
-- Eternus
p.discover = nil; p.hero = "S15_HERO_eternus"; p.totalGoldSpent = 0; p.eternusVisited = nil
local gt = g.turn; g.turn = 1
local ok3, e3 = pcall(BG.HP.S15_HERO_eternus.startTurn, g, p)
print("eternus start", ok3, e3, "gold", p.gold, "visit", p.timewarpVisit ~= nil, "locking", p.eternusLocking)
if p.timewarpVisit then
    p.gold = 20
    local okp, rp, ep; for si = 1, #p.timewarpVisit.slots do okp, rp, ep = pcall(BG.timewarpPick, g, "White", si); if rp then break end end
    print("eternus pick", okp, rp, ep, "exp", #(p.expeditions or {}), "spellexp", #(p.spellExpeditions or {}), "hand", #p.hand, #p.spellHand)
    local function locked() local n = 0 for _, l in ipairs({p.expeditions or {}, p.spellExpeditions or {}}) do for _, e in ipairs(l) do if e.gold then n = n + 1 end end end return n end
    g.turn = 3; p.timewarpVisit = nil; pcall(BG.releaseExpeditions, g, p); print("locked after turn 3, 0 gold", locked(), "hand", #p.hand, #p.spellHand)
    p.totalGoldSpent = 45; local okr, er = pcall(BG.releaseExpeditions, g, p); print("after 45 gold", okr, er, "locked", locked(), "hand", #p.hand, #p.spellHand)
end
g.turn = gt
if Draw then local ok4, t = pcall(Draw.powerState, g, p, BG.heroById("S15_HERO_eternus")); print("eternus text", ok4, t) end
-- Growing ooze & N'Zoth
print("ooze", BG.growingOoze(p))
fresh(); p.hand = {BG.newMinion(g, "S15_growing_ooze", false)}
local before = p.board[1].atk
local okd, ed = pcall(BG.discardCard, g, p, p.hand, 1)
print("ooze discard", okd, ed, "board atk", before, "->", p.board[1].atk, "next ooze", BG.growingOoze(p)); print("deity need nzoth", BG.deityNeed("S15_nzoth"), "drake", BG.deityNeed("BGFYM_000"))
print("bully", T.env.BG_CARDS.BG35_432 and T.env.BG_CARDS.BG35_432.name, BG.FX.BG35_432 ~= nil)
print("== ERRORS: " .. #ERRORS); for i = 1, math.min(10, #ERRORS) do print(ERRORS[i]) end
