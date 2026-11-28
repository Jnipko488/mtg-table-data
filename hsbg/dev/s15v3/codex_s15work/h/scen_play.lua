seatPlayer("White", true, "Nipko")
pump(6)
click("f06d01", "toggleTableArena", "White")
pump(20)
local T = OBJECTS["b9a001"]
for i = 1, 6 do
    local ok, st = protected("tavern.onSave", T.env.onSave)
    if ok then print("onSave bytes " .. #tostring(st)) end
    local ok2, st2 = protected("launcher.onSave", OBJECTS["f06d01"].env.onSave)
    local game = T.env.bgDebugState()
    print("turn " .. tostring(game and game.turn) .. " phase " .. tostring(game and game.phase) .. " tokens " .. #getObjectsWithTag("hsbg_card"))
    -- White ends turn via its board button
    local boards = getObjectsWithTag("hsbg_board")
    for _, b in ipairs(boards) do
        local o = OBJECTS[b.getGUID()]
        for _, bt in ipairs(o.buttons) do if bt.click_function == "bgReady" then protected("ready", T.env.bgReady, b, "White", false) end end
    end
    pump(40)
end
print("== ERRORS: " .. #ERRORS)
