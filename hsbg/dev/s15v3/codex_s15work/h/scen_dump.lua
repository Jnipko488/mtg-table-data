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
local p = g.players.White
local ids = {"BG30_103","BG22_402","BG26_800","BGS_078","BG32_891","BG32_892","BG28_590","BG31_301","BG24_003","BG28_595","BGS_121","BG33_809","BG34_175","BG33_893","BG25_032","BG33_826","BG33_884","BG30_124","BG30_129","BG32_237","BG25_016","BG36_763","BG32_821","BG36_098","BG36_116","BG36_113","BGFYM_005","BG35_602","BGS_018","BG36_762","BG26_523","BG35_814","BG34_950","BG_BOT_911","BG36_854","BG31_149","BG32_860","BG31_148","BG32_235","BG36_344",
 "BG34_Giant_001","BG34_Giant_583","BG34_Giant_305","BG34_Giant_581","BG34_Giant_066","BG34_Giant_300","BG34_Giant_202","BG34_Giant_209","BG34_Giant_604","BG34_Giant_064","BG34_PreMadeChamp_078","BG34_PreMadeChamp_076","BG34_Giant_618","BG34_Giant_680","BG34_Giant_362","BG34_PreMadeChamp_013","BG34_Giant_608","BG34_Giant_205","BG34_Giant_032","BG34_Giant_319","BG34_PreMadeChamp_022"}
for _, id in ipairs(ids) do
  local c = T.env.BG_CARDS[id]
  local tw = T.env.BG_TIMEWARP[id]
  print("CARD", id, c and c.name, c and c.tier, c and c.atk, c and c.hp, c and table.concat(c.races or {}, ","), c and c.all, c and c.fx, tw and tw.cost, tw and tw.tier, "|", c and c.text, "||", c and c.gtext)
end
for _, id in ipairs({"BG34_HeroPowerSpell_006","BG34_HeroPowerSpell_015"}) do local tw = T.env.BG_TIMEWARP[id]; print("TW", id, tw and tw.cost, tw and tw.name) end
