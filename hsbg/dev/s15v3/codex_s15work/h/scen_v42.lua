-- v4.2: no spawned UI objects. Controls, hero draft, Discover and the settings panel are decals with
-- invisible buttons on the board / controller; every custom spawn must carry full data.
seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
local function S() return T.env.bgDebugState() end
local function check(cond, msg) if not cond then ERRORS[#ERRORS + 1] = "CHECK FAILED: " .. msg; print("CHECK FAILED: " .. msg) else print("ok: " .. msg) end end
local function boardOf(color)
    local _, _, seats = S()
    local g = color == "_settings" and "b9a001" or (seats[color] and seats[color].board)
    return g and OBJECTS[g] or nil
end
local function w(color, key) return T.env.bgWidget(color, key) end
local function decal(color, key)
    local b = boardOf(color)
    for _, d in ipairs(b and b.decals or {}) do if d.name == "hsbg_" .. key then return d end end
    return nil
end
local function wclick(color, key, who)
    local b = boardOf(color)
    if not b then check(false, "host for " .. color); return end
    local found
    for _, bt in ipairs(b.buttons) do
        if bt.click_function == "bgW_" .. key then
            found = bt
            local c = bt.color or {}
            if (c[4] or c.a or 1) ~= 0 then check(false, key .. " click area is invisible") end
        end
    end
    if not found then check(false, "button bgW_" .. key .. " on " .. color); return end
    click(b.guid, "bgW_" .. key, who or (color == "_settings" and "White" or color))
    pump(0.2)
end
local function uiObjects() return #getObjectsWithTag("hsbg_ui") end
check(T.pos.y < 0, "controller parked under the table")
check(buttons("f06d01"):find("Play Hearthstone"), "Setup Box reads Play Hearthstone Battlegrounds")
print("-- 1 settings on the controller")
click("f06d01", "toggleTableArena", "White")
pump(1)
check(T.pos.y > 0 and #(T.invisible or {}) == 0, "controller moved onto the table and shown")
check(decal("_settings", "panel") ~= nil, "settings panel decal")
print("settings decals: " .. #(T.decals or {}) .. ", buttons " .. #T.buttons)
for _, d in ipairs(T.decals or {}) do print(string.format("  %s at %.2f,%.2f size %.2fx%.2f", d.name, d.position[1], d.position[3], d.scale[1], d.scale[2])) end
check(uiObjects() == 0, "no UI objects spawned")
for i = 1, 30 do if select(2, S()).season == "s12" then break end wclick("_settings", "o_season") end
wclick("_settings", "o_timer")     -- Default -> Short
wclick("_settings", "o_buddies"); wclick("_settings", "o_anomalies")
wclick("_settings", "o_bots", "Blue")  -- not the host
local _, st = S()
check(st.season == "s12" and st.timer == "Short" and st.buddies and st.anomalies and st.trinkets and st.bots, "settings recorded")
local lbl
for _, bt in ipairs(T.buttons) do if bt.click_function == "bgW_o_timer" then lbl = bt.label end end
check(lbl == "Timer: Short", "option label: " .. tostring(lbl))
print("-- 2 start")
wclick("_settings", "o_start")
pump(3)
local g = S()
check(g and g.phase == "hero", "hero draft phase")
check(w("_settings", "panel") == nil and T.pos.y < 0 and #(T.invisible or {}) == 12 and #(T.decals or {}) == 0 and #T.buttons == 0, "settings closed: controller parked, hidden, cleared")
local n = 0
for i = 1, 4 do
    local d, pw = decal("White", "pick" .. i), decal("White", "pw" .. i)
    if d and pw then n = n + 1 end
    print("hero " .. i .. ": " .. tostring(d and d.url:gsub("^.*/hsbg/", "")))
end
check(n == 4, "4 hero portraits with their Hero Powers on White's board")
local tip
for _, bt in ipairs(boardOf("White").buttons) do if bt.click_function == "bgW_pick2" then tip = bt.tooltip end end
check(tip and tip:find("Hero Power"), "hero tooltip shows its Hero Power")
pump(20)
wclick("White", "pick2")
pump(3)
g = S()
check(g.phase == "recruit" and g.turn == 1, "recruit turn 1 after picks")
check(decal("White", "pick1") == nil, "draft art gone")
for _, k in ipairs({"hero", "tierup", "refresh", "freeze", "power", "gold", "endturn"}) do
    local d = decal("White", k)
    check(d ~= nil, "control " .. k)
    if d then print(string.format("%s: %s at %.2f,%.2f size %.2fx%.2f", k, d.url:gsub("^.*/hsbg/", ""), d.position[1], d.position[3], d.scale[1], d.scale[2])) end
end
local p = g.players.White
p.gold = 10
local before = p.gold
wclick("White", "refresh")
g = S(); p = g.players.White
check(p.gold == before - 1, "Refresh spends 1 gold")
wclick("White", "freeze")
check(S().players.White.frozen, "Freeze freezes")
check(decal("White", "freeze").url:find("btn_freeze_on"), "frozen art")
wclick("White", "freeze", "Blue")
check(S().players.White.frozen, "Blue cannot press White's Freeze")
local tier = p.tier
wclick("White", "tierup")
check(S().players.White.tier == tier + 1, "Tier Up upgrades")
print("-- discover below the board")
p = S().players.White
p.discover = {options = {"BG20_100", "BG21_004", "BG20_104"}, label = "Discover a minion", golden = false}
wclick("White", "refresh")
pump(0.5)
local pk = decal("White", "pick1")
check(pk ~= nil and decal("White", "panel") ~= nil, "discover art")
if pk then
    print("discover pick1 local z " .. string.format("%.2f", pk.position[3]) .. " " .. pk.url:gsub("^.*/hsbg/", ""))
    check(math.abs(pk.position[3]) > 12, "discover lies below the board")
end
local hand = #p.hand
wclick("White", "pick3")
p = S().players.White
check(not p.discover and #p.hand == hand + 1, "discover picked to hand")
print("-- hero power")
wclick("White", "power")
print("-- turns")
for i = 1, 14 do
    g = S()
    if g.phase == "over" then break end
    if g.phase == "recruit" then
        p = g.players.White
        if p.offer and w("White", "pick1") then
            p.gold = 20
            wclick("White", "pick1")
            print("trinkets " .. #(p.trinkets or {}))
        end
        if p.alive and w("White", "endturn") then wclick("White", "endturn") end
    end
    pump(30)
    g = S()
    print("turn " .. g.turn .. " " .. g.phase .. " White hp " .. g.players.White.hp .. " alive " .. tostring(g.players.White.alive) .. " decals " .. #(boardOf("White").decals or {}))
end
check(uiObjects() == 0, "no UI objects spawned during the game")
print("-- save/reload")
local state = T.env.onSave()
check(not state:find("_settings"), "no settings pseudo-seat in the save")
protected("reload", T.env.onLoad, state)
pump(5)
check(decal("White", "hero") ~= nil or not S().players.White.alive, "controls redrawn after reload")
print("-- end")
click("f06d01", "toggleTableArena", "White")
pump(4)
check(S() == nil, "game ended")
check(#getObjectsWithTag("hsbg_card") == 0 and #getObjectsWithTag("hsbg_board") == 0, "table cleared")
check(w("_settings", "panel") ~= nil and T.pos.y > 0, "a finished game: the box clears it and opens the settings again")
click("f06d01", "toggleTableArena", "White")
pump(2)
wclick("_settings", "o_close")
check(w("_settings", "panel") == nil and T.pos.y < 0, "Close parks the controller")
local hsbgUi = 0
for id in pairs(UISTATE) do if id:find("^hsbg") then hsbgUi = hsbgUi + 1 end end
check(hsbgUi == 0, "no XML UI touched")
check(#CUSTOM_FAILS == 0, "no incomplete or overlapping custom spawns (" .. #CUSTOM_FAILS .. ")")
print("launcher: " .. buttons("f06d01"))
print("== ERRORS: " .. #ERRORS)
for _, e in ipairs(ERRORS) do print(e) end
