-- v4.1: no XML/HUD. Settings, hero draft, Discover and every control are art tiles with invisible buttons.
seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
local function S() return T.env.bgDebugState() end
local function check(cond, msg) if not cond then ERRORS[#ERRORS + 1] = "CHECK FAILED: " .. msg; print("CHECK FAILED: " .. msg) else print("ok: " .. msg) end end
local function tile(color, key)
    local _, _, seats = S()
    local g = seats[color] and seats[color].tiles and seats[color].tiles[key]
    return g and OBJECTS[g] or nil
end
local function seen(o, color)
    if not o or o.pos.y < 0 then return false end
    for _, c in ipairs(o.invisible or {}) do if c == color then return false end end
    return true
end
local function tclick(color, key, who)
    local o = tile(color, key)
    if not o then check(false, "tile " .. color .. "/" .. key .. " exists"); return end
    for _, b in ipairs(o.buttons) do
        if b.click_function == "bgTileClick" then
            local c = b.color or {}
            if (c[4] or c.a or 1) ~= 0 then check(false, key .. " click area is invisible") end
        end
    end
    click(o.proxy.getGUID(), "bgTileClick", who or (color == "_settings" and "White" or color))
    pump(0.2)
end
local function uiCount() local n = 0; for _ in pairs(UISTATE) do n = n + 1 end; return n end
check(T.pos.y < 0, "controller parked under the table")
check(buttons("f06d01"):find("Play Hearthstone"), "Setup Box reads Play Hearthstone Battlegrounds")
print("-- 1 settings on the table")
click("f06d01", "toggleTableArena", "White")
pump(1)
local panel = tile("_settings", "panel")
check(panel ~= nil, "settings panel tile on the table")
print("panel url " .. tostring(panel and panel.data and panel.data.CustomImage and panel.data.CustomImage.ImageURL))
print("panel buttons: " .. (panel and buttons(panel.proxy.getGUID()) or ""))
for i = 1, 30 do if select(2, S()).season == "s12" then break end tclick("_settings", "o_season") end
tclick("_settings", "o_timer")     -- Default -> Short
tclick("_settings", "o_buddies"); tclick("_settings", "o_anomalies")
tclick("_settings", "o_bots", "Blue")  -- not the host
local _, st = S()
check(st.season == "s12" and st.timer == "Short" and st.buddies and st.anomalies and st.trinkets and st.bots, "settings recorded")
print("o_timer: " .. buttons(tile("_settings", "o_timer").proxy.getGUID()))
print("-- 2 start")
tclick("_settings", "o_start")
pump(3)
local g = S()
check(g and g.phase == "hero", "hero draft phase")
check(tile("_settings", "panel") == nil, "settings closed")
local n = 0
for i = 1, 4 do
    local o = tile("White", "pick" .. i)
    if seen(o, "White") and not seen(o, "Blue") then n = n + 1 end
    print("hero " .. i .. ": " .. tostring(o and o.proxy.getName()) .. " | " .. tostring(o and o.data.CustomImage.ImageURL))
end
check(n == 4, "4 private hero tiles for White")
check(not seen(tile("White", "pw2"), "White"), "hero power hidden before hover")
protected("hover", T.env.onObjectHover, "White", tile("White", "pick2").proxy)
pump(0.2)
check(seen(tile("White", "pw2"), "White") and not seen(tile("White", "pw1"), "White"), "hover shows that hero's power")
print("power: " .. tostring(tile("White", "pw2").proxy.getName()) .. " | " .. buttons(tile("White", "pw2").proxy.getGUID()))
pump(20)
tclick("White", "pick2")
pump(3)
g = S()
check(g.phase == "recruit" and g.turn == 1, "recruit turn 1 after picks")
check(tile("White", "pick1") == nil, "draft tiles gone")
for _, k in ipairs({"hero", "tierup", "refresh", "freeze", "power", "gold", "endturn"}) do
    local o = tile("White", k)
    check(o ~= nil, "control " .. k)
    if o then print(k .. ": " .. o.data.CustomImage.ImageURL:gsub("^.*/hsbg/", "") .. " | " .. buttons(o.proxy.getGUID())) end
end
local p = g.players.White
p.gold = 10
local before = p.gold
tclick("White", "refresh")
g = S(); p = g.players.White
check(p.gold == before - 1, "Refresh tile spends 1 gold")
tclick("White", "freeze")
check(S().players.White.frozen, "Freeze tile freezes")
check(tile("White", "freeze").data.CustomImage.ImageURL:find("btn_freeze_on"), "frozen art")
tclick("White", "freeze", "Blue")
check(S().players.White.frozen, "Blue cannot press White's Freeze")
local tier = p.tier
tclick("White", "tierup")
check(S().players.White.tier == tier + 1, "Tier Up tile upgrades")
print("-- discover below the board")
p = S().players.White
p.discover = {options = {"BG20_100", "BG21_004", "BG20_104"}, label = "Discover a minion", golden = false}
tclick("White", "refresh")
pump(0.5)
local bw
for _, b in ipairs(getObjectsWithTag("hsbg_board")) do if b.getName():find("White") then bw = b end end
local pk = tile("White", "pick1")
check(pk ~= nil and tile("White", "panel") ~= nil, "discover tiles")
if pk then
    local l = bw.positionToLocal(pk.proxy.getPosition())
    print("discover pick1 local z " .. string.format("%.2f", l.z) .. " name " .. pk.proxy.getName())
    check(math.abs(l.z) > 12, "discover lies below the board")
end
local hand = #p.hand
tclick("White", "pick3")
p = S().players.White
check(not p.discover and #p.hand == hand + 1, "discover picked to hand")
print("-- hero power tile")
tclick("White", "power")
print("-- turns")
for i = 1, 14 do
    g = S()
    if g.phase == "over" then break end
    if g.phase == "recruit" then
        p = g.players.White
        if p.offer and tile("White", "pick1") then
            print("trinket offer: " .. tile("White", "pick1").proxy.getName())
            p.gold = 20
            tclick("White", "pick1")
            print("trinkets " .. #(p.trinkets or {}))
        end
        if p.alive and tile("White", "endturn") then tclick("White", "endturn") end
    end
    pump(30)
    g = S()
    print("turn " .. g.turn .. " " .. g.phase .. " White hp " .. g.players.White.hp .. " alive " .. tostring(g.players.White.alive) .. " ui tiles " .. #getObjectsWithTag("hsbg_ui"))
end
print("-- save/reload")
local state = T.env.onSave()
check(not state:find("_settings"), "no settings pseudo-seat in the save")
protected("reload", T.env.onLoad, state)
pump(5)
check(tile("White", "hero") ~= nil or not S().players.White.alive, "controls rebuilt after reload")
print("-- end")
click("f06d01", "toggleTableArena", "White")
pump(4)
check(S() == nil, "game ended")
check(#getObjectsWithTag("hsbg_card") == 0 and #getObjectsWithTag("hsbg_board") == 0, "table cleared")
local others = 0
for _, o in ipairs(getObjectsWithTag("hsbg_ui")) do if JSON.decode(o.getMemo and o.getMemo() or OBJECTS[o.getGUID()].memo).c ~= "_settings" then others = others + 1 end end
check(others == 0 and tile("_settings", "panel") ~= nil, "a finished game: the box clears it and opens the settings again")
click("f06d01", "toggleTableArena", "White")
pump(2)
tclick("_settings", "o_close")
check(#getObjectsWithTag("hsbg_ui") == 0, "Close removes the settings panel")
local hsbgUi = 0
for id in pairs(UISTATE) do if id:find("^hsbg") then hsbgUi = hsbgUi + 1 end end
check(hsbgUi == 0, "no XML UI touched")
print("launcher: " .. buttons("f06d01"))
print("== ERRORS: " .. #ERRORS)
for _, e in ipairs(ERRORS) do print(e) end
