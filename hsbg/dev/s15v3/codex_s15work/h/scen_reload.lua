seatPlayer("White", true, "Nipko")
pump(10)
click("f06d01", "toggleTableArena", "White")
pump(20)
local T = OBJECTS["b9a001"]
for _, bo in ipairs(getObjectsWithTag("hsbg_board")) do
  for _, bt in ipairs(OBJECTS[bo.getGUID()].buttons) do if bt.click_function == "bgReady" then T.env.bgReady(bo, "White") end end
end
pump(30)
local st = T.env.onSave()
print("saved " .. #st .. " cards " .. #getObjectsWithTag("hsbg_card"))
-- simulate a reload of the controller script with its saved state (world objects stay)
T.buttons = {}
attachScript(T, __readfile("scripts/b9a001.lua"))
protected("reload onLoad", T.env.onLoad, st)
pump(10)
local g = T.env.bgDebugState()
print("after reload: " .. tostring(g and g.phase) .. " turn " .. tostring(g and g.turn) .. " cards " .. #getObjectsWithTag("hsbg_card"))
for _, bo in ipairs(getObjectsWithTag("hsbg_board")) do if bo.getName():find("White") then print(buttons(bo.getGUID())) end end
print("== ERRORS: " .. #ERRORS)
