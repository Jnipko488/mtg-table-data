-- v4.3: layout measured on the board art; words and numbers baked into the art (ui2/); the settings
-- panel is the controller with its own texture; Bob hides for the hero draft and combat; the hero draft
-- shows the Hero Power card of the hero under the pointer. Prints "DUMP <screen> <json>" lines that
-- Tools/preview_layout.py turns into top-down pictures of each screen.
seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
local function S() return T.env.bgDebugState() end
local function check(cond, msg) if not cond then ERRORS[#ERRORS + 1] = "CHECK FAILED: " .. msg; print("CHECK FAILED: " .. msg) else print("ok: " .. msg) end end
local function seatsOf() local _, _, seats = S(); return seats end
local function boardOf(color)
    local seats = seatsOf()
    local g = color == "_settings" and "b9a001" or (seats[color] and seats[color].board)
    return g and OBJECTS[g] or nil
end
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
local function v3(p) return {p.x or p[1], p.y or p[2], p.z or p[3]} end
local function objDump(o)
    if not o then return nil end
    local bl = {}
    for _, b in ipairs(o.buttons or {}) do
        bl[#bl + 1] = {label = b.label, position = b.position and v3(b.position) or {0, 0, 0}, font_size = b.font_size, font_color = b.font_color,
            width = b.width, height = b.height, scale = b.scale and v3(b.scale) or {1, 1, 1}, tooltip = b.tooltip, click = b.click_function,
            color = b.color}
    end
    local dl = {}
    for _, d in ipairs(o.decals or {}) do dl[#dl + 1] = {name = d.name, url = d.url, position = v3(d.position), rotation = v3(d.rotation), scale = v3(d.scale)} end
    local url
    if o.data and o.data.CustomImage then url = o.data.CustomImage.ImageURL end
    return {guid = o.guid, name = o.nickname, pos = v3(o.pos), rot = v3(o.rot), scale = v3(o.scale), buttons = bl, decals = dl, url = url,
        invisible = o.invisible and #o.invisible or 0, tags = o.tags}
end
local function dump(screen, color)
    local seats = seatsOf()
    local s = seats[color] or {}
    local out = {screen = screen, color = color, controller = objDump(T), launcher = objDump(OBJECTS["f06d01"]),
        board = s.board and objDump(OBJECTS[s.board]) or nil, bob = s.bob and objDump(OBJECTS[s.bob]) or nil, tokens = {}}
    for _, o in ipairs(ORDER) do
        if not o.destroyed and o.tags["hsbg_card"] then
            local ok, m = pcall(JSON.decode, o.memo or "")
            if ok and type(m) == "table" and m.c == color then out.tokens[#out.tokens + 1] = objDump(o) end
        end
    end
    print("DUMP " .. screen .. " " .. JSON.encode(out))
end

check(T.pos.y < 0, "controller parked under the table")
print("-- 1 settings")
click("f06d01", "toggleTableArena", "White")
pump(1)
check(T.pos.y > 0 and #(T.invisible or {}) == 0, "controller moved onto the table and shown")
local L = OBJECTS["f06d01"]
check(math.abs(T.pos.z - (L.pos.z - 6.6)) < 0.01 and math.abs(T.pos.x - L.pos.x) < 0.01, "panel on White's side of the Setup Box")
check(decal("_settings", "panel") == nil and decal("_settings", "title") ~= nil, "no panel decal; the title is art")
local n = 0
for _, d in ipairs(T.decals or {}) do if d.name:find("^hsbg_o_") then n = n + 1 end end
check(n == 10, "10 option buttons drawn as art (" .. n .. ")")
for _, bt in ipairs(T.buttons) do
    if bt.click_function:find("^bgW_o_") then check(bt.label == "", "option click area carries no label text: " .. bt.click_function) end
end
wclick("_settings", "o_timer")     -- Default -> Short
check(decal("_settings", "o_timer").url:find("ui2/opt/timer_short.png", 1, true), "timer art follows the setting")
wclick("_settings", "o_bots")
check(decal("_settings", "o_bots").url:find("ui2/opt/bots_off.png", 1, true), "bots art follows the setting")
wclick("_settings", "o_bots")
for i = 1, 30 do if select(2, S()).season == "s14" then break end wclick("_settings", "o_season") end
check(decal("_settings", "o_season").url:find("ui2/opt/season_s14.png", 1, true), "season art follows the setting")
dump("settings", "White")
print("-- 2 hero draft")
wclick("_settings", "o_start")
pump(3)
local g = S()
check(g and g.phase == "hero", "hero draft phase")
check(#(T.invisible or {}) == 12 and #(T.decals or {}) == 0, "settings closed: controller hidden and cleared")
local picks = 0
for i = 1, 4 do if decal("White", "pick" .. i) and decal("White", "b_pkh" .. i) then picks = picks + 1 end end
check(picks == 4, "4 hero portraits, each with its Health gem")
check(decal("White", "ptitle") ~= nil, "Choose your Hero title")
local bob = OBJECTS[seatsOf().White.bob]
check(bob and #(bob.invisible or {}) == 12, "Bob hidden during the hero draft")
check(decal("White", "hcard") == nil, "no Hero Power card before pointing at a hero")
local B = boardOf("White")
local p2 = decal("White", "pick2")
Player.White.pointer = B.proxy.positionToWorld({p2.position[1], 0.3, p2.position[3]})
pump(0.6)
local hc = decal("White", "hcard")
check(hc ~= nil and hc.url:find("/ui2/hc/", 1, true), "pointing at hero 2 shows its Hero Power card")
if hc then check(math.abs(hc.position[1] - p2.position[1]) < 0.01 and hc.position[3] > p2.position[3], "the card sits right under that portrait") end
for _, d in ipairs(B.decals) do check(d.rotation[2] == 180, "art upright for the seated player: " .. d.name) end
dump("hero", "White")
pump(20)
wclick("White", "pick2")
pump(3)
g = S()
check(g.phase == "recruit" and g.turn == 1, "recruit turn 1 after picks")
check(decal("White", "pick1") == nil and decal("White", "hcard") == nil, "draft art gone")
check(#(bob.invisible or {}) == 0, "Bob back in his door for recruiting")
print("-- 3 recruit: 7 in the shop, 7 in the warband")
local p = g.players.White
local BGm = T.env.BG
local ids = {"BG20_100", "BG21_004", "BG20_104", "BG23_000", "BG23_002", "BG23_004", "BG23_007",
             "BG25_001", "BG25_008", "BG25_009", "BG25_010", "BG25_011", "BG25_013", "BG25_016"}
p.tavern, p.board = {}, {}
for i = 1, 7 do table.insert(p.tavern, BGm.newMinion(g, ids[i])) end
for i = 8, 13 do table.insert(p.board, BGm.newMinion(g, ids[i], i == 9)) end
p.board[2].taunt, p.board[3].shield, p.board[5].reborn = true, true, true
table.insert(p.board, BGm.newMinion(g, ids[14]))
p.gold, p.maxGold, p.tier, p.armor = 7, 10, 3, 5
p.hp = 27
wclick("White", "freeze"); wclick("White", "freeze")
pump(2)
local shop, band = 0, 0
for _, o in ipairs(ORDER) do
    if not o.destroyed and o.tags["hsbg_card"] then
        local ok, m = pcall(JSON.decode, o.memo or "")
        if ok and m.c == "White" then
            local _, near = T.env.bgDebugReader(B.proxy, o.proxy.getPosition())
            if near < 0 then shop = shop + 1 else band = band + 1 end
        end
    end
end
check(shop == 7 and band == 7, "7 shop cards above the middle, 7 warband cards below (" .. shop .. "/" .. band .. ")")
for _, key in ipairs({"hero", "b_hp", "b_armor", "tierup", "refresh", "freeze", "power", "gold", "endturn", "lb1"}) do
    check(decal("White", key) ~= nil, "recruit art: " .. key)
end
for _, key in ipairs({"b_tiercost", "b_refcost", "b_powcost", "goldtext"}) do
    check(decal("White", key) == nil, "v4.4: no separate badge " .. key .. " (the coin is in the button art)")
end
check(decal("White", "gold").url:find("ui2/gd/7_10.png", 1, true), "gold bar reads 7/10")
check(decal("White", "tierup").url:find("ui2/sb/tu_4_", 1, true) and decal("White", "tierup").url:find("_1.png", 1, true), "Tier Up: tier 4 banner, lit (affordable)")
check(decal("White", "refresh").url:find("ui2/sb/rf_1_1.png", 1, true), "Refresh: cost 1, lit")
check(decal("White", "freeze").url:find("ui2/sb/fz_off_1.png", 1, true), "Freeze: not frozen, lit")
check(decal("White", "tier") == nil, "no separate Tavern Tier banner (only the Tier Up button)")
check(decal("White", "power").url:find("ui2/pw/", 1, true), "Hero Power disc art")
-- minions: keyword overlays and stat numbers are decals on the card tokens
local kinds, ovals = {}, 0
for _, o in ipairs(ORDER) do
    local okm, mm = pcall(JSON.decode, o.memo or "")
    if not o.destroyed and o.tags["hsbg_card"] and okm and type(mm) == "table" and mm.c == "White" then
        local u = o.data and o.data.CustomImage and o.data.CustomImage.ImageURL or ""
        if u:find("/hsbg/o/", 1, true) then ovals = ovals + 1 end
        for _, d in ipairs(o.decals or {}) do
            local k = d.url:match("ui2/(mo/[%w_]+)%.png") or d.url:match("ui2/(mg/%a/%a)/") or d.url:match("ui2/(tb)/") or d.url:match("ui2/(kw/ic_[%w_]+)%.png")
            if d.name == "hsbg_hovercard" then k = "hovercard" end
            if k then kinds[k] = (kinds[k] or 0) + 1 end
        end
        for _, b in ipairs(o.buttons or {}) do check(false, "card token has no label buttons: " .. tostring(b.label)) end
    end
end
check(ovals == 14, "v4.6: all 14 board minions are oval portrait tokens (" .. ovals .. ")")
local na, nh = 0, 0
for _, c in ipairs({"w", "g", "r"}) do na = na + (kinds["mg/a/" .. c] or 0); nh = nh + (kinds["mg/h/" .. c] or 0) end
check(na == 14 and nh == 14, "Attack coin and Health drop on all 14 minions (" .. na .. "/" .. nh .. ")")
check((kinds["tb"] or 0) == 7, "tier badge on the 7 shop minions only (" .. tostring(kinds["tb"]) .. ")")
for _, k in ipairs({"mo/taunt", "mo/shield", "mo/reborn", "mo/gold"}) do check((kinds[k] or 0) >= 1, "minion effect " .. k) end
check((kinds["mo/sleep"] or 0) == 0, "no Zzz anywhere (BG has no summoning sickness)")
check((kinds["hovercard"] or 0) == 0, "no full card shown until hovered")
local bu = bob.data and bob.data.CustomImage and bob.data.CustomImage.ImageURL or ""
check(bu:find("ui2/bob.png", 1, true) ~= nil, "Bob is the arch portrait (ui2/bob.png)")
check(decal("White", "b_hp").url:find("ui2/hp/27.png", 1, true), "hero Health 27")
check(decal("White", "endturn").url:find("ui2/et_end.png", 1, true), "End Turn art with its words")
for _, bt in ipairs(B.buttons) do
    if bt.click_function == "arenaPhaseLabel" then check((bt.position[2] or bt.position.y) < 0, "Codex's phase label moved under the board") end
end
dump("recruit", "White")
print("-- 3b hover: the full card beside the minion")
local hv
for _, o in ipairs(ORDER) do
    if not o.destroyed and o.tags["hsbg_card"] then
        local ok, m = pcall(JSON.decode, o.memo or "")
        local _, near = T.env.bgDebugReader(B.proxy, o.proxy.getPosition())
        if ok and m.c == "White" and near > 0 and m.i == ids[10] then hv = o end
    end
end
check(hv ~= nil, "found a warband minion to hover")
Player.White.hover = hv and hv.guid
pump(0.5)
local hc
for _, d in ipairs(hv and hv.decals or {}) do if d.name == "hsbg_hovercard" then hc = d end end
check(hc ~= nil and hc.url:find("/hsbg/f/", 1, true) ~= nil, "hovering shows the full card (f/ face) as a decal")
dump("hover", "White")
Player.White.hover = nil
pump(0.5)
hc = nil
for _, d in ipairs(hv and hv.decals or {}) do if d.name == "hsbg_hovercard" then hc = d end end
check(hc == nil, "the full card goes when the pointer leaves")
print("-- 3c every keyword")
local kwset = {{taunt = true}, {shield = true}, {reborn = true}, {stealth = true}, {windfury = true}, {venom = true}, {poison = true, taunt = true, shield = true}}
for i, m in ipairs(p.board) do for k, v in pairs(kwset[i] or {}) do m[k] = v end end
-- v4.8: an unfrozen shop with keywords too
local shopset = {{taunt = true}, {shield = true}, {}, {taunt = true, shield = true}, {}, {venom = true}, {reborn = true}}
for i, m in ipairs(p.tavern) do for k, v in pairs(shopset[i] or {}) do m[k] = v end end
wclick("White", "freeze"); wclick("White", "freeze")
pump(1)
local fz = 0
for _, o in ipairs(ORDER) do
    local okm, mm = pcall(JSON.decode, o.memo or "")
    if not o.destroyed and o.tags["hsbg_card"] and okm and type(mm) == "table" and mm.c == "White" then
        for _, d in ipairs(o.decals or {}) do if d.name == "hsbg_frozen" then fz = fz + 1 end end
    end
end
check(fz == 0, "unfrozen shop: no ice (" .. fz .. ")")
dump("keywords", "White")
print("-- 3d hand cards stay full cards")
local hand0 = BGm.newMinion(g, ids[3])
table.insert(p.hand, hand0)
wclick("White", "freeze"); wclick("White", "freeze")
pump(1)
local inhand
for _, o in ipairs(ORDER) do
    if not o.destroyed and o.tags["hsbg_card"] then
        local u = o.data and o.data.CustomImage and o.data.CustomImage.ImageURL or ""
        local ok, m = pcall(JSON.decode, o.memo or "")
        if ok and m.k == "u" .. tostring(hand0.uid or hand0.u) then inhand = u end
    end
end
check(inhand and inhand:find("/hsbg/f/", 1, true) ~= nil, "a hand card is a full card (" .. tostring(inhand) .. ")")
table.remove(p.hand)
wclick("White", "freeze"); wclick("White", "freeze")
pump(1)
print("-- 4 discover")
p.discover = {options = {"BG20_100", "BG21_004", "BG20_104"}, label = "Discover a minion", golden = false}
wclick("White", "freeze"); wclick("White", "freeze")
pump(0.5)
local pk = decal("White", "pick1")
check(pk ~= nil and decal("White", "panel") == nil, "discover cards without a panel decal")
if pk then check(math.abs(pk.position[3]) > 12, "discover lies below the board") end
dump("discover", "White")
wclick("White", "pick3")
print("-- 5 combat")
g = S()
local k = 0
for _, c in ipairs(g.order) do
    local q = g.players[c]
    if c ~= "White" and q.alive then
        q.board = {}
        for i = 1, 7 do k = k + 1; table.insert(q.board, BGm.newMinion(g, ids[(k % #ids) + 1])) end
    end
end
wclick("White", "endturn")
local seen = false
for i = 1, 400 do
    pump(0.05)
    g = S()
    if g.phase == "combat" and not seen and decal("White", "opp") then
        pump(1.0)
        seen = true
        check(#(bob.invisible or {}) == 12, "Bob hidden in combat")
        check(decal("White", "tierup") == nil and decal("White", "refresh") == nil and decal("White", "freeze") == nil, "no shop buttons in combat")
        dump("combat", "White")
    end
    if g.phase == "recruit" and seen then break end
end
check(seen, "combat shows the opponent's hero in the top door")
print("== ERRORS: " .. #ERRORS)
for _, e in ipairs(ERRORS) do print(e) end
