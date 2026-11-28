seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
local function tile(color, key)
    local _, _, seats = T.env.bgDebugState()
    local g = seats[color] and seats[color].tiles and seats[color].tiles[key]
    return g and OBJECTS[g] or nil
end
local function tclick(color, key) local o = tile(color, key); if o then click(o.proxy.getGUID(), "bgTileClick", "White"); pump(0.1) end return o ~= nil end
local function setTo(key, want, getter) for _ = 1, 40 do if getter() == want then return end tclick("_settings", key) end end
local seasons = {"Current", "Season 14 - x", "Season 11 - x", "Season 8 - x", "Season 6 - x", "Season 13 - x"}
for gi, season in ipairs(seasons) do
    click("f06d01", "toggleTableArena", "White")
    pump(1)
    local _, st = T.env.bgDebugState()
    local skey = ({["Season 14 - x"] = "s14", ["Season 11 - x"] = "s11", ["Season 8 - x"] = "s8", ["Season 6 - x"] = "s6", ["Season 13 - x"] = "s13"})[season]
    setTo("o_season", skey, function() return st.season end)
    setTo("o_speed", 1, function() return st.speed end)
    setTo("o_timer", gi % 2 == 0 and "Short" or "Default", function() return st.timer end)
    for _, k in ipairs({"buddies", "trinkets", "anomalies"}) do setTo("o_" .. k, true, function() return st[k] end) end
    setTo("o_whole", gi > 3, function() return st.allCards or false end)
    tclick("_settings", "o_start")
    pump(3)
    tclick("White", "pick" .. (gi % 4 + 1))
    pump(1)
    local g
    for t = 1, 60 do
        g = T.env.bgDebugState()
        if not g or g.phase == "over" then break end
        if g.phase == "recruit" then
            local p = g.players.White
            if p.alive then
                if p.discover or p.offer then tclick("White", "pick1"); p.offer = nil end
                local pw = tile("White", "power")
                if pw then for _, bt in ipairs(pw.buttons) do if bt.click_function == "bgTileClick" then tclick("White", "power") break end end end
                tclick("White", "endturn")
            end
        end
        pump(12)
    end
    g = T.env.bgDebugState()
    print("GAME " .. gi .. " " .. season .. ": " .. tostring(g and g.phase) .. " turn " .. tostring(g and g.turn) .. " anomaly " .. tostring(g and g.anomaly) .. " errors so far " .. #ERRORS)
end
print("== ERRORS: " .. #ERRORS)
for i = 1, math.min(10, #ERRORS) do print(ERRORS[i]) end
