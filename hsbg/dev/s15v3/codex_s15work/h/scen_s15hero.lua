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
local seasons = {"Season 15 - a", "Season 15 - b", "Season 15 - c", "Season 15 - d"}
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
    do local g0 = T.env.bgDebugState(); if g0 and g0.players and g0.players.White then
        g0.players.White.hero = gi % 2 == 0 and "S15_HERO_vanessa" or "S15_HERO_eternus"; g0.players.White.powerHero = nil
        if g0.tribes and T.env.BG.indexOf(g0.tribes, "ABERRATION") then g0.deity = "S15_nzoth" end
        print("forced hero", g0.players.White.hero, "deity", tostring(g0.deity), "turn", g0.turn)
    end end
    local g
    for t = 1, 60 do
        g = T.env.bgDebugState()
        if not g or g.phase == "over" then break end
        if g.phase == "recruit" then
            local p = g.players.White
            if p.alive then
                    if p.hero == "S15_HERO_vanessa" and p.gold >= 2 then protected("vpower", T.env.BG.heroPower, g, "White") end
                if p.discover or p.offer then tclick("White", "pick1"); p.offer = nil end
                -- S15 injection: force Season 15 cards into the shop so their scripts run
                do
                    S15IDS = S15IDS or (function() local t = {} for id, c in pairs(T.env.BG_CARDS) do if id:sub(1,4) == "S15_" or id == "BG35_432" then t[#t+1] = id end end table.sort(t) return t end)()
                    S15SP = S15SP or {"S15S_invocation_earth","S15S_invocation_fire","S15S_invocation_air","S15S_invocation_water","S15S_command_elements","S15S_dragonstorm","S15S_goldrinns_blessing","S15S_tumultuous_growth","S15S_unholy_ritual","S15S_echoing_roar","S15S_sanctify","BG35_149","EBG_Spell_014"}
                    INJ = (INJ or 0)
                    for k = 1, math.min(3, #p.tavern) do
                        INJ = INJ + 1
                        local id = (INJ % 3 == 0 and "S15_growing_ooze" or S15IDS[(INJ % #S15IDS) + 1])
                        local okm, m = pcall(T.env.BG.newMinion, g, id, INJ % 5 == 0)
                        if okm and m then p.tavern[k] = m else ERRORS[#ERRORS+1] = "newMinion " .. id .. ": " .. tostring(m) end
                    end
                    if p.spellShop and p.spellShop[1] and T.env.BG.SPELLS then
                        local sid = S15SP[(INJ % #S15SP) + 1]
                        if T.env.BG.SPELLS[sid] then g.uid = g.uid + 1; p.spellShop[1] = {id = sid, uid = g.uid} end
                    end
                    p.gold = math.max(p.gold, 10)
                end
                -- v4.8: also buy and play minions (engine calls, as scen_soak did) so oval minions fight
                for _ = 1, 5 do
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
                tclick("White", "skip")
                if LASTT and LASTT.n and LASTT.n >= 2 then tclick("White", "pick1"); tclick("White", "b_pkconfirm") end
                tclick("White", "power")
                tclick("White", "endturn")
            end
        end
        pump(12)
        if g and g.players and g.players.White then SEEN = SEEN or {}; for _, m in ipairs(g.players.White.board or {}) do SEEN[m.id] = true end end
        if g and g.phase == "recruit" then
            LASTT = LASTT or {}
            if LASTT.turn == g.turn then LASTT.n = LASTT.n + 1 else LASTT.turn, LASTT.n = g.turn, 0 end
            if LASTT.n == 5 then local p = g.players.White; print("STUCK turn " .. g.turn .. " discover=" .. tostring(p.discover and (p.discover.kind or "?") .. " " .. tostring(p.discover.label) or nil) .. " offer=" .. tostring(p.offer) .. " ready=" .. tostring(p.ready) .. " gold " .. p.gold .. " warp=" .. tostring(p.timewarpVisit ~= nil) .. " hero=" .. tostring(p.hero)); local h = host("White"); local ks = {}; for _, bt in ipairs(h and h.buttons or {}) do ks[#ks+1] = bt.click_function end; print("  buttons: " .. table.concat(ks, ",")) end
        end
    end
    g = T.env.bgDebugState()
    COMPLETED = (COMPLETED or 0) + ((g and g.phase == "over") and 1 or 0)
    MAXB = 0
    print("GAME " .. gi .. " " .. season .. ": " .. tostring(g and g.phase) .. " turn " .. tostring(g and g.turn) .. " anomaly " .. tostring(g and g.anomaly) .. " errors so far " .. #ERRORS)
end
local ns = 0; for id in pairs(SEEN or {}) do if id:sub(1,4) == "S15_" then ns = ns + 1 end end; print("S15 minions seen on board: " .. ns)
print("spells cast " .. tostring(CASTS)); for k, v in pairs(SPELLTXT or {}) do print("TXT " .. k .. " => " .. v:gsub("\n", " | ")) end
print("ui objects " .. #getObjectsWithTag("hsbg_ui") .. ", strict spawn failures " .. #CUSTOM_FAILS)
print("games completed (phase over): " .. tostring(COMPLETED) .. " / " .. #seasons)
if (COMPLETED or 0) < #seasons then ERRORS[#ERRORS + 1] = "not every soak game reached the end" end
print("== ERRORS: " .. #ERRORS)
for i = 1, math.min(10, #ERRORS) do print(ERRORS[i]) end
