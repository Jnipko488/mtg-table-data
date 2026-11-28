-- Golden vs normal differential test (Season 15).
-- For every card in GOLDEN_IDS: identical fixture + identical random seed, run each recruit-phase step for the normal and the
-- golden copy and print the state change of each step. Flags steps where the golden change is not bigger than the normal one.
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
setTo("o_speed", 1, function() return st.speed end)
tclick("_settings", "o_start"); pump(3)
tclick("White", "pick1"); pump(0.5); tclick("White", "b_pkconfirm"); pump(1)
local g = T.env.bgDebugState()
if g.phase == "hero" then protected("choose", E.chooseHero, g, "White", 1); pump(2) end
for _ = 1, 20 do g = T.env.bgDebugState(); if g.phase == "recruit" then break end; pump(1) end
local p = g.players.White
local CARDS = T.env.BG_CARDS
g.tribes = {"ABERRATION","BEAST","DEMON","DRAGON","ELEMENTAL","MECHANICAL","MURLOC","PIRATE","QUILBOAR","UNDEAD"}
g.turn = 9; g.maxTier = 6; p.tier = 6
local seed = 1
local realRand = g.rand
local function reseed(s) seed = s; g.rand = function(n) seed = (seed * 1103515245 + 12345) % 2147483648; return (seed % n) + 1 end end
local BOARD = BOARD or {"BG_CFM_315t", "BGS_115t", "BG_ICC_026t", "BG_BOT_312t", "BG22_HERO_305t", "S15T_tentacle"}
local HAND = HAND or {"BG_BRM_006t", "BGS_061t", "BG_KAR_005a"}
local TAV = TAV or {"BG_CFM_316t", "BG_DMF_533t", "BG_EX1_556t", "BG_CS2_200"}
local PSAVE = {}
for k, v in pairs(p) do if type(v) ~= "table" and type(v) ~= "function" then PSAVE[k] = v end end
local function fresh(id, golden)
    reseed(12345)
    for k, v in pairs(p) do if type(v) ~= "table" and type(v) ~= "function" and PSAVE[k] == nil then p[k] = nil end end
    for k, v in pairs(PSAVE) do p[k] = v end
    p.pending = nil; p.missions = nil; p.counters = nil
    p.board, p.tavern, p.hand, p.spellHand = {}, {}, {}, {}
    for i, b in ipairs(BOARD) do p.board[i] = E.newMinion(g, b, false) end
    for i, b in ipairs(TAV) do p.tavern[i] = E.newMinion(g, b, false) end
    for i, b in ipairs(HAND) do p.hand[i] = E.newMinion(g, b, false) end
    g.uid = g.uid + 1; p.spellHand[1] = {id = "BG28_897", uid = g.uid}
    p.gold = 30; p.maxGold = 10; p.discover = nil; p.discoverQueue = {}; p.timewarpVisit = nil
    p.spellAtk, p.spellHp = 0, 0; p.gemAtk, p.gemHp = 0, 0
    if p.deity then p.deity.atk, p.deity.hp = 2, 2 end
    local m = E.newMinion(g, id, golden)
    return m
end
local SELF = nil
local function sum(list) local a, h, n, kw, gold = 0, 0, 0, 0, 0
    for _, m in ipairs(list or {}) do if m.atk and m ~= SELF then a = a + m.atk; h = h + (m.hp or 0); n = n + 1
        for _, k in ipairs({"taunt", "shield", "reborn", "windfury", "venom", "resilient"}) do if m[k] then kw = kw + 1 end end
        if m.golden then gold = gold + 1 end end end
    return a, h, n, kw, gold
end
local function snap()
    local s = {}
    s.bA, s.bH, s.bN, s.bKW, s.bG = sum(p.board)
    s.hA, s.hH, s.hN, s.hKW, s.hG = sum(p.hand)
    s.tA, s.tH, s.tN = sum(p.tavern)
    s.spells = #p.spellHand
    s.gold, s.maxGold = p.gold or 0, p.maxGold or 0
    s.disc = (p.discover and 1 or 0) + #(p.discoverQueue or {})
    s.discOpts = p.discover and p.discover.options and #p.discover.options or 0
    s.spA, s.spH = p.spellAtk or 0, p.spellHp or 0
    s.gemA, s.gemH = p.gemAtk or 0, p.gemHp or 0
    s.beastA, s.beastH = p.beastA or 0, p.beastH or 0
    s.dA, s.dH = p.deity and p.deity.atk or 0, p.deity and p.deity.hp or 0
    s.undA = p.undeadAtk or 0
    if SELF then s.sA, s.sH = SELF.atk or 0, SELF.hp or 0
        local kw = 0; for _, k in ipairs({"taunt", "shield", "reborn", "windfury", "venom", "resilient"}) do if SELF[k] then kw = kw + 1 end end
        s.sKW = kw end
    s.tavA, s.tavH = p.tavernAtk or 0, p.tavernHp or 0
    return s
end
local KEYS = {"sA","sH","sKW","bA","bH","bN","bKW","bG","hA","hH","hN","hKW","hG","tA","tH","tN","spells","gold","maxGold","disc","discOpts","spA","spH","gemA","gemH","beastA","beastH","dA","dH","undA","tavA","tavH"}
local function delta(a, b) local d = {} for _, k in ipairs(KEYS) do local v = (b[k] or 0) - (a[k] or 0); if v ~= 0 then d[k] = v end end return d end
local function fmt(d) local o = {} for _, k in ipairs(KEYS) do if d[k] then o[#o + 1] = k .. "=" .. d[k] end end return table.concat(o, " ") end
local function settle()
    for _ = 1, 10 do
        if not p.discover then break end
        local ok, r = pcall(E.discoverPick, g, "White", 1)
        if not ok or not r then p.discover = nil end
    end
    p.discover = nil; p.discoverQueue = {}
end
local function run(id, golden)
    local res = {}
    local m = fresh(id, golden)
    if not m then return nil end
    SELF = m
    local function step(name, f)
        local before = snap()
        local ok, err = pcall(f)
        if not ok then ERRORS[#ERRORS + 1] = id .. (golden and " G " or " N ") .. name .. ": " .. tostring(err) end
        local mid = snap()
        settle()
        local after = snap(); after.disc, after.discOpts = mid.disc, mid.discOpts
        res[name] = delta(before, after)
    end
    table.insert(p.hand, 1, m)
    step("play", function() E.play(g, "White", 1, 4) end)
    local idx = E.indexOf(p.board, m)
    if not idx then table.insert(p.board, 4, m); idx = 4 end
    if E.activation(g, m) then step("activate", function() local ok, e = E.activateMinion(g, "White", E.indexOf(p.board, m)); if p.discover and p.discover.kind == "activate_target" then E.discoverPick(g, "White", 1) end end) end
    step("spell", function() g.uid = g.uid + 1; table.insert(p.spellHand, 1, {id = "BG28_897", uid = g.uid}); E.castTavernSpell(g, "White", 1, {zone = "board", index = E.indexOf(p.board, m) or 1}) end)
    step("endTurn", function() E.hooks(g, p, "endTurn") end)
    step("startTurn", function() E.hooks(g, p, "startTurn") end)
    step("refresh", function() E.hooks(g, p, "refresh") end)
    step("combat", function()
        local opp = g.players.Blue or g.players.Red
        local foe = {}
        for j = 1, 7 do foe[j] = E.newMinion(g, "BG_CS2_200", false) end
        local i = E.indexOf(p.board, m)
        if i then table.remove(p.board, i); table.insert(p.board, 1, m) end
        E.simulate(g, {color = "White", name = "W", tier = 6, hero = p.hero, board = p.board, trinkets = p.trinkets or {}},
            {color = opp and opp.color, name = "B", tier = 6, hero = opp and opp.hero, board = foe, trinkets = {}}, {noFrames = true})
    end)
    step("sell", function() local i = E.indexOf(p.board, m); if i then E.sell(g, "White", i) end end)
    SELF = nil
    return res
end
local BASE = {[false] = run("BG_CFM_315t", false), [true] = run("BG_CFM_315t", true)}
local function minus(a, b) local d = {} for _, k in ipairs(KEYS) do local v = ((a or {})[k] or 0) - ((b or {})[k] or 0); if v ~= 0 then d[k] = v end end return d end
local flagged, checked = 0, 0
for _, id in ipairs(GOLDEN_IDS) do
    if CARDS[id] then
        checked = checked + 1
        local n, gd = run(id, false), run(id, true)
        local lines = {}
        local suspicious = false
        for _, stp in ipairs({"play", "activate", "spell", "endTurn", "startTurn", "refresh", "combat", "sell"}) do
            local a, b = n and minus(n[stp], BASE[false][stp]), gd and minus(gd[stp], BASE[true][stp])
            if stp == "activate" and a and b and a.gold and a.gold == b.gold and a.gold < 0 then a.gold = nil; b.gold = nil end
            if a or b then
                local fa, fb = fmt(a or {}), fmt(b or {})
                if fa ~= "" or fb ~= "" then
                    local same = fa == fb and fa ~= ""
                    if same then suspicious = true end
                    lines[#lines + 1] = string.format("   %-9s N: %s\n   %-9s G: %s%s", stp, fa, "", fb, same and "   <== SAME" or "")
                end
            end
        end
        print(string.format("%s %s %s", suspicious and "FLAG" or "ok  ", id, CARDS[id].name))
        if suspicious or VERBOSE then for _, l in ipairs(lines) do print(l) end end
        if suspicious then flagged = flagged + 1 end
    else
        print("MISSING " .. id)
    end
end
g.rand = realRand
print("GOLDEN checked " .. checked .. " flagged " .. flagged)
