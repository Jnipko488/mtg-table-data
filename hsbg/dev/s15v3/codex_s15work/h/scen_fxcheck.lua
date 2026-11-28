seatPlayer("White", true, "Nipko")
pump(5)
local T = OBJECTS["b9a001"]
local BG, CARDS = T.env.BG, T.env.BG_CARDS
local pool
for _, s in ipairs(T.env.BG_SEASONS) do if s.key == "s15" then pool = s.pool end end
pcall(BG.activateSeason, "s15")
local miss = {}
for _, id in ipairs(pool) do
  local c = CARDS[id]
  local f = BG.FX and BG.FX[id]
  if not c then miss[#miss+1] = id .. " (NO CARD)"
  elseif not f and c.fx == "none" then miss[#miss+1] = id .. " " .. c.name .. " :: " .. (c.text or "") end
end
print("UNSCRIPTED " .. #miss .. " / " .. #pool)
for _, l in ipairs(miss) do print("  " .. l) end
