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
local BG = T.env.BG
click("f06d01", "toggleTableArena", "White"); pump(1)
local _, st = T.env.bgDebugState()
setTo("o_season", "s15", function() return st.season end)
setTo("o_speed", 1, function() return st.speed end)
tclick("_settings", "o_start"); pump(3)
tclick("White", "pick1"); pump(0.5); tclick("White", "b_pkconfirm"); pump(1)
local g = T.env.bgDebugState()
if g.phase == "hero" then protected("choose", BG.chooseHero, g, "White", 1); pump(2) end
for _ = 1, 20 do g = T.env.bgDebugState(); if g.phase == "recruit" then break end; pump(1) end
print("phase", g.phase, "season", g.season, "deity", g.deity)
local E = BG
local DR = T.env.bgDebugDraw and T.env.bgDebugDraw()
local CARDS, TWD, ART = T.env.BG_CARDS, T.env.BG_TIMEWARP, T.env.BG_ART
local pool
for _, s in ipairs(T.env.BG_SEASONS) do if s.key == "s15" then pool = s.pool end end
local set, kind = {}, {}
for _, id in ipairs(pool) do set[id] = true; kind[id] = "pool" end
for id, d in pairs(TWD) do if E.S15_TIMEWARP_POOL[id] then set[id] = true; kind[id] = "tw" .. d.tier .. d.kind end end
-- tokens: ids whose base is in the set
local bases = {}
for id in pairs(set) do bases[id] = true end
for id, c in pairs(CARDS) do
  if not set[id] and type(c) == "table" then
    local b = id:gsub("_G$", ""):gsub("t%d*$", ""):gsub("t%d*$", "")
    if bases[b] or id:sub(1, 4) == "S15T" or (id:sub(1,4) == "S15_" ) then set[id] = true; kind[id] = kind[id] or "token" end
  end
end
local function esc(s) s = tostring(s or ""); return (s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")) end
local out = {}
for id in pairs(set) do
  local c, d = CARDS[id], TWD[id]
  local rec = {'"id":"' .. esc(id) .. '"', '"kind":"' .. kind[id] .. '"'}
  if c then
    local art = ART and ART[id]
    local okn, n = pcall(DR.s15MinionAsset, id, false, "cards")
    local okg, gg = pcall(DR.s15MinionAsset, id, true, "cards")
    for _, f in ipairs({"name","text","gtext","gid"}) do rec[#rec+1] = '"' .. f .. '":"' .. esc(c[f]) .. '"' end
    for _, f in ipairs({"tier","atk","hp","gatk","ghp"}) do rec[#rec+1] = '"' .. f .. '":' .. tostring(tonumber(c[f]) or "null") end
    rec[#rec+1] = '"races":"' .. esc(table.concat(c.races or {}, ",")) .. (c.all and "ALL" or "") .. '"'
    rec[#rec+1] = '"fx":"' .. esc(c.fx) .. '"'
    rec[#rec+1] = '"artN":"' .. esc((okn and n) or (art and art.n) or "") .. '"'
    rec[#rec+1] = '"artG":"' .. esc((okg and gg) or (art and art.g) or "") .. '"'
    rec[#rec+1] = '"minion":true'
  else
    local s = E.SPELLS[id]
    rec[#rec+1] = '"name":"' .. esc(d and d.name or s and s.name) .. '"'
    rec[#rec+1] = '"text":"' .. esc(s and s.text) .. '"'
    local ok, a = pcall(DR.spellArt, id)
    rec[#rec+1] = '"artN":"' .. esc(ok and a or "") .. '"'
  end
  if d then rec[#rec+1] = '"twcost":' .. d.cost end
  out[#out+1] = "{" .. table.concat(rec, ",") .. "}"
end
-- S15 Tavern spells
for id, s in pairs(E.SPELLS) do
  if s.pool or s.tavern then
    local ok, a = pcall(DR.spellArt, id)
    out[#out+1] = '{"id":"' .. esc(id) .. '","kind":"spell","name":"' .. esc(s.name) .. '","text":"' .. esc(E.spellText(nil, id) or s.text) .. '","tier":' .. tostring(s.tier or "null") .. ',"artN":"' .. esc(ok and a or "") .. '","s15pool":' .. tostring(s.s15 or false) .. '}'
  end
end
local f = io and io.open and io.open("/tmp/inv.json", "w")
if f then f:write("[" .. table.concat(out, ",\n") .. "]"); f:close(); print("WROTE", #out) else
  for _, l in ipairs(out) do print("INV " .. l) end end
