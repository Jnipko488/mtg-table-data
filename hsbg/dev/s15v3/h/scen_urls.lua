seatPlayer("White", true, "Nipko")
pump(10)
local T = OBJECTS["b9a001"]
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
local E = T.env.BG
click("f06d01", "toggleTableArena", "White"); pump(1)
local _, st = T.env.bgDebugState()
setTo("o_season", "s15", function() return st.season end)
tclick("_settings", "o_start"); pump(3)
tclick("White", "pick1"); pump(0.5); tclick("White", "b_pkconfirm"); pump(1)
local g = T.env.bgDebugState()
if g.phase == "hero" then protected("choose", E.chooseHero, g, "White", 1); pump(2) end
for _ = 1, 20 do g = T.env.bgDebugState(); if g.phase == "recruit" then break end; pump(1) end
local D = T.env.bgDebugDraw()
local CARDS = T.env.BG_CARDS
local urls, seen = {}, {}
local function add(tag, u) if type(u) == "string" and u ~= "" and not seen[u] then seen[u] = true; print("URL\t" .. tag .. "\t" .. u) end end
local pool
for _, s in ipairs(T.env.BG_SEASONS) do if s.key == "s15" then pool = s.pool end end
local ids = {}
for _, id in ipairs(pool) do ids[#ids + 1] = id end
for id in pairs(E.S15_TIMEWARP_POOL) do if CARDS[id] then ids[#ids + 1] = id end end
for _, t in ipairs({"S15T_monkey", "S15T_tentacle", "S15_growing_ooze", "BG26_800t", "BG19_010t", "BG35_150t", "BG_UNG_999t2t1", "BG_TTN_401", "BG_ICC_026t"}) do if CARDS[t] then ids[#ids + 1] = t end end
for _, id in ipairs(ids) do
    for _, gold in ipairs({false, true}) do
        local ok, u = pcall(D.previewCard, {id = id, golden = gold})
        if ok then add(id .. (gold and " G card" or " card"), u) else print("ERR preview " .. id .. " " .. tostring(u)) end
        local ok2, o = pcall(D.ovalArt, {id = id, golden = gold, zone = "board"})
        if ok2 then add(id .. (gold and " G oval" or " oval"), o) else print("ERR oval " .. id .. " " .. tostring(o)) end
    end
end
local spells = {}
for id in pairs(E.seasonSpells.s15 or {}) do spells[#spells + 1] = id end
for id, sp in pairs(E.SPELLS) do if id:find("^S15") or (T.env.BG_TIMEWARP[id] and E.S15_TIMEWARP_POOL[id]) then spells[#spells + 1] = id end end
for _, id in ipairs(spells) do
    add(id .. " spell", D.spellArt(id))
    for price = 0, 5 do local ok, u = pcall(D.shopSpellArt, id, price); if ok then add(id .. " shop" .. price, u) end end
end
print("DONE ids " .. #ids .. " spells " .. #spells)
