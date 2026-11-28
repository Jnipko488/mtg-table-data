seatPlayer("White", true, "Nipko")
pump(10)
local L = OBJECTS["f06d01"]
for _, c in ipairs(L.ctx) do if c.label:find("original") then c.fn("White") end end
pump(5)
print("lane boards " .. #getObjectsWithTag("table_arena_board_f06d01") .. " launcher: " .. buttons("f06d01"))
click("f06d01", "toggleTableArena", "White")
pump(3)
print("after click: lane boards " .. #getObjectsWithTag("table_arena_board_f06d01") .. " launcher: " .. buttons("f06d01"))
click("f06d01", "toggleTableArena", "White")
pump(20)
print("bg boards " .. #getObjectsWithTag("hsbg_board") .. " launcher: " .. buttons("f06d01"))
for _, c in ipairs(L.ctx) do if c.label:find("original") then c.fn("White") end end
pump(3)
print("lane boards while BG running: " .. #getObjectsWithTag("table_arena_board_f06d01"))
GLOBALVARS.mtBusy = true
click("b9a001", "bgStop", "White"); pump(1)
click("b9a001", "bgStart", "White"); pump(1)
GLOBALVARS.mtBusy = false
click("b9a001", "bgBots", "White")
click("b9a001", "bgStart", "White"); pump(1)
print("== ERRORS: " .. #ERRORS)
