seatPlayer("White", true, "Nipko")
pump(5)
local T = OBJECTS["b9a001"]
local pool
for _, s in ipairs(T.env.BG_SEASONS) do if s.key == "s15" then pool = s.pool end end
local bully, seen, dup = false, {}, 0
for _, id in ipairs(pool) do if id == "BG35_432" then bully = true end; if seen[id] then dup = dup + 1 end; seen[id] = true end
print("POOL", #pool, "bully", bully, "dups", dup)
