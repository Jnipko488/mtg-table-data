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
local seasons = {"Season 14 - x", "Season 11 - x", "Season 13 - x", "Season 8 - x"}
for gi, season in ipairs(seasons) do
    click("f06d01", "toggleTableArena", "White")
    pump(1)
    local _, st = T.env.bgDebugState()
    local skey = ({["Season 15 - a"]="s15",["Season 15 - b"]="s15",["Season 15 - c"]="s15",["Season 15 - d"]="s15",["Season 14 - x"] = "s14", ["Season 11 - x"] = "s11", ["Season 8 - x"] = "s8", ["Season 6 - x"] = "s6", ["Season 13 - x"] = "s13"})[season]
    setTo("o_season", skey, function() return st.season end)
    setTo("o_speed", 1, function() return st.speed end)
    setTo("o_timer", gi % 2 == 0 and "Short" or "Default", function() return st.timer end)
    for _, k in ipairs({"buddies", "trinkets", "anomalies"}) do setTo("o_" .. k, true, function() return st[k] end) end
    setTo("o_whole", gi > 3, function() return st.allCards or false end)
    tclick("_settings", "o_start")
    pump(3)
    tclick("White", "pick" .. (gi % 4 + 1))
    pump(0.5)
    tclick("White", "b_pkconfirm")
    pump(1)
    do local g0 = T.env.bgDebugState(); if g0 and g0.phase == "hero" then protected("choose", T.env.BG.chooseHero, g0, "White", 1); pump(2) end end
    local g
    for t = 1, 60 do
        g = T.env.bgDebugState()
        if not g or g.phase == "over" then break end
        if g.phase == "recruit" then
            local p = g.players.White
            if p.alive then
                if p.discover or p.offer then tclick("White", "pick1"); p.offer = nil end
                -- v4.8: also buy and play minions (engine calls, as scen_soak did) so oval minions fight
                for _ = 1, 3 do
                    if p.discover then protected("disc", T.env.BG.discoverPick, g, "White", 1) end
                    if p.tavern[1] and p.gold >= 3 and #p.hand < 10 then protected("buy", T.env.BG.buy, g, "White", 1) end
                    if p.hand[1] and #p.board < 7 and not p.discover then protected("play", T.env.BG.play, g, "White", 1, #p.board + 1) end
                    if p.spellShop and p.spellShop[1] and p.gold >= 2 and #p.spellHand < 10 then protected("buyspell", T.env.BG.buyTavernSpell, g, "White", 1) end
                    if p.spellHand and p.spellHand[1] and not p.discover then
                        SPELLTXT = SPELLTXT or {}
                        local e = p.spellHand[1]
                        if T.env.Draw and T.env.Draw.spellCardText then local ok, t = pcall(T.env.Draw.spellCardText, p, {id = e.id, entry = e, spell = true}); if ok and t then SPELLTXT[e.id] = t elseif not ok then ERRORS[#ERRORS+1] = "spelltext " .. e.id .. ": " .. tostring(t) end end
                        local ok, r, err = pcall(T.env.BG.castTavernSpell, g, "White", 1, p.board[1] and {zone = "board", index = 1} or nil)
                        if not ok then ERRORS[#ERRORS+1] = "cast " .. e.id .. ": " .. tostring(r) end
                        CASTS = (CASTS or 0) + ((ok and r) and 1 or 0)
                    end
                end
                if p.gold >= 6 then protected("up", T.env.BG.upgrade, g, "White") end
                tclick("White", "power")
                tclick("White", "endturn")
            end
        end
        pump(12)
    end
    g = T.env.bgDebugState()
    COMPLETED = (COMPLETED or 0) + ((g and g.phase == "over") and 1 or 0)
    MAXB = 0
    print("GAME " .. gi .. " " .. season .. ": " .. tostring(g and g.phase) .. " turn " .. tostring(g and g.turn) .. " anomaly " .. tostring(g and g.anomaly) .. " errors so far " .. #ERRORS)
end
print("spells cast " .. tostring(CASTS)); for k, v in pairs(SPELLTXT or {}) do print("TXT " .. k .. " => " .. v:gsub("\n", " | ")) end
print("ui objects " .. #getObjectsWithTag("hsbg_ui") .. ", strict spawn failures " .. #CUSTOM_FAILS)
print("games completed (phase over): " .. tostring(COMPLETED) .. " / " .. #seasons)
if (COMPLETED or 0) < #seasons then ERRORS[#ERRORS + 1] = "not every soak game reached the end" end
print("== ERRORS: " .. #ERRORS)
for i = 1, math.min(10, #ERRORS) do print(ERRORS[i]) end
