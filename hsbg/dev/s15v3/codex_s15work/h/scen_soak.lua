seatPlayer("White", true, "Nipko")
pump(8)
if ALLCARDS then click("b9a001", "bgCards", "White") end
click("f06d01", "toggleTableArena", "White")
pump(20)
local T = OBJECTS["b9a001"]
for i = 1, 80 do
    local g = T.env.bgDebugState()
    if not g or g.phase == "over" then break end
    local p = g.players.White
    if g.phase == "recruit" and p.alive then
        -- buy and play through the engine like a player would (drag paths are covered by the Lupa tests)
        for _ = 1, 3 do
            if p.discover then T.env.BG.discoverPick(g, "White", 1) end
            if p.tavern[1] and p.gold >= 3 and #p.hand < 10 then T.env.BG.buy(g, "White", 1) end
            if p.hand[1] and #p.board < 7 then T.env.BG.play(g, "White", 1, #p.board + 1) end
        end
        T.env.BG.upgrade(g, "White")
    end
    for _, bo in ipairs(getObjectsWithTag("hsbg_board")) do
        for _, bt in ipairs(OBJECTS[bo.getGUID()].buttons) do if bt.click_function == "bgReady" then protected("ready", T.env.bgReady, bo, "White", false) end end
    end
    pump(25)
end
local g = T.env.bgDebugState()
print("RESULT " .. tostring(g and g.phase) .. " turn " .. tostring(g and g.turn) .. " errors " .. #ERRORS)
