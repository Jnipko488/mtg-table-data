"""Batch 20: VFX player (flipbooks built from Hearthstone's own GenFX textures) for combat hits, Divine Shield pops,
deaths, triples, Tavern upgrades, buys/sells and Dark Gifts; Activate button drawn on the minion itself (moves with it)
with a real object button for the click."""
FX = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/0b2598b64641f565928b9450e207f63a12232cd2/hsbg/battlegrounds-multiplayer/s14-leaderboard/fx/"

FXLUA = r'''
-- ---------------------------------------------------------------- VFX player
Draw.FX_BASE = "@FX@"
Draw.FXDEF = {hit = {n = 8, size = 3.4}, shield = {n = 9, size = 4.2}, death = {n = 10, size = 4.0}, golden = {n = 12, size = 5.2},
    tierup = {n = 10, size = 4.2}, coin = {n = 8, size = 2.2}, darkgift = {n = 12, size = 4.6}}
Draw.fxPool = Draw.fxPool or {}
local FX_S, FX_SINK = 0.1, 1.2
function Draw.fxUrls()
    local list = {}
    for kind, def in pairs(Draw.FXDEF) do for i = 1, def.n do list[#list + 1] = Draw.FX_BASE .. kind .. "/" .. i .. ".png" end end
    return list
end
local function fxCarrier()
    for _, c in ipairs(Draw.fxPool) do
        if not c.busy and c.obj and not c.obj.isDestroyed() then return c end
    end
    if #Draw.fxPool >= 14 then return nil end
    -- A built-in block (never a custom import, so no import dialog can ever appear), kept out of sight; only its decal shows.
    local c = {busy = false}
    c.obj = spawnObject({type = "BlockSquare", position = {0, -30, 0}, rotation = {0, 0, 0}, scale = {FX_S, FX_S, FX_S}, sound = false,
        callback_function = function(o)
            pcall(function() o.setLock(true); o.interactable = false; o.setGMNotes("hsbg_fx"); o.setName(""); o.tooltip = false end)
        end})
    Draw.fxPool[#Draw.fxPool + 1] = c
    return c
end
function Draw.fx(kind, pos)
    local def = Draw.FXDEF[kind]
    if not def or not pos then return end
    local c = fxCarrier()
    if not c then return end
    c.busy = true
    local obj = c.obj
    local x, y, z = pos.x or pos[1], pos.y or pos[2], pos.z or pos[3]
    local yaw = Draw.decalYaw()
    local function run()
        if obj.isDestroyed() then c.busy = false; return end
        obj.setPosition({x, y - FX_SINK, z})
        obj.setRotation({0, 0, 0})
        local i = 0
        local function step()
            if obj.isDestroyed() then c.busy = false; return end
            i = i + 1
            if i > def.n then
                pcall(function() obj.setDecals({}) end); obj.setPosition({0, -30, 0}); c.busy = false
                return
            end
            pcall(function() obj.setDecals({{name = "fx", url = Draw.FX_BASE .. kind .. "/" .. i .. ".png",
                position = {0, (FX_SINK + 0.4) / FX_S, 0}, rotation = {90, yaw, 0}, scale = {def.size / FX_S, def.size / FX_S, 1}}}) end)
            Wait.frames(step, 3)
        end
        step()
    end
    if obj.spawning then Wait.condition(run, function() return obj.isDestroyed() or not obj.spawning end, 5, function() c.busy = false end)
    else run() end
end
function Draw.fxBoard(color, kind, right, near)
    local board = boardOf(color)
    if not board then return end
    local ok, p = pcall(boardPoint, board, right, near, 0.3)
    if ok and p then Draw.fx(kind, p) end
end
function Draw.fxCleanup()
    for _, o in ipairs(getAllObjects()) do
        local ok, notes = pcall(function() return o.getGMNotes() end)
        if ok and notes == "hsbg_fx" then pcall(function() o.destruct() end) end
    end
    Draw.fxPool = {}
end
function Draw.eventFx(e)
    if not e or not e.color or not game then return end
    local p = game.players[e.color]
    if not p or p.bot then return end
    if e.fx == "upgrade" then Draw.fxBoard(e.color, "tierup", SPOT.tierup[1], SPOT.tierup[2])
    elseif e.fx == "combine" then Draw.fxBoard(e.color, "golden", 0, ROW_WARBAND + 4.4)
    elseif e.fx == "buy" then Draw.fxBoard(e.color, "coin", 0, ROW_WARBAND + 4.4)
    elseif e.fx == "sell" then Draw.fxBoard(e.color, "coin", 0, ROW_TAVERN) end
end
'''

ACTLUA = r'''
-- Activate: the button art rides on the minion token; a transparent object button takes the click.
function Draw.activateState(info, d)
    if not game or game.phase ~= "recruit" or d.zone ~= "warband" or d.combat then return nil end
    local p = game.players[info.color]
    local m = d.src
    if not p or not m or p.bot then return nil end
    local cost, used = BG.activation(game, m)
    if not cost then return nil end
    local ok = BG.canAct(game, p)
    local enabled = ok and not used and p.gold >= cost
    return {cost = cost, used = used, enabled = enabled and true or false,
        url = Draw.season14Art("activate/" .. (enabled and "ready-" or "locked-") .. math.min(4, cost) .. ".png")}
end
function Draw.activateKey(info, d)
    local s = Draw.activateState(info, d)
    return s and (s.cost .. (s.enabled and "e" or "l") .. (s.used and "u" or "")) or ""
end
function Draw.activateButton(obj, d, info)
    local s = Draw.activateState(info, d)
    local key = s and Draw.activateKey(info, d) or ""
    if info.actKey == key then return end
    info.actKey = key
    pcall(function() obj.clearButtons() end)
    if not s then return end
    local scale = obj.getScale().x
    local z = -.625 * 3.12 * (settings.flip and -1 or 1)
    pcall(function() obj.createButton({click_function = "bgActivateClick", function_owner = self, label = "",
        position = {0, (math.max(.12, tokenTop) + .2) / scale, z / scale}, rotation = {0, settings.flip and 180 or 0, 0},
        width = 330, height = 330, scale = {1 / scale, 1, 1 / scale}, color = {0, 0, 0, 0}, hover_color = {1, 1, 1, 0.08},
        press_color = {1, 1, 1, 0.18}, font_size = 1,
        tooltip = s.used and "Activate used this turn" or ("Activate · " .. s.cost .. " Gold\n" .. (BG_CARDS[d.id] and BG_CARDS[d.id].text or ""))}) end)
end
'''

CLICK = r'''
function bgActivateClick(obj, color, alt)
    if alt or not game then return end
    local info = tokenInfo[obj.getGUID()]
    if not info or not info.d or not info.d.src then return end
    local owner = info.color
    local p = actorFor(color, owner)
    if not p then return end
    local uid = info.d.src.uid
    guard("activate", function()
        for i, m in ipairs(p.board) do
            if m.uid == uid then
                local ok, err = BG.activateMinion(game, owner, i)
                after(p, ok, err)
                return
            end
        end
    end)
end
'''

HP4 = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/1b6d2900037f9d1bff7b816b03bf845fd26cf06c/hsbg/battlegrounds-multiplayer/s14-leaderboard/hp4/"
HP4B = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/bc1d2f6100135874c8be93eb518429bbf40455fc/hsbg/battlegrounds-multiplayer/s14-leaderboard/hp4b/"
MISSING_TRIPLE = ["BG24_300_G", "BG27_009_G", "BG28_404_G", "BG28_597_G", "BGFYM_002t_G", "BG_CS2_200_G", "TB_BaconShop_HERO_43_Buddy_G"]
def patch(s, replace, HERE):
    # HearthstoneJSON has no golden render for these: use the normal render instead of a broken image
    miss = ",".join('["%s"]=true' % g for g in MISSING_TRIPLE)
    s = replace(s, '        url = "https://art.hearthstonejson.com/v1/bgs/latest/enUS/512x/" .. (gid and (gid .. "_triple") or id) .. ".png"',
                '        if gid and ({' + miss + '})[gid] then gid = nil end\n        url = "https://art.hearthstonejson.com/v1/bgs/latest/enUS/512x/" .. (gid and (gid .. "_triple") or id) .. ".png"')
    s = replace(s, '        medallion = "' + HP4 + '" .. h.id .. "_" .. (active and state or "n") .. ".png"\n',
                '        medallion = ((active and cost) and "' + HP4 + '" or "' + HP4B + '") .. h.id .. "_" .. (active and state or "n") .. ".png"\n')
    s = replace(s, 'ensureTile(color,"power2",{url=hs2 and ("' + HP4 + '" .. second.id',
                'ensureTile(color,"power2",{url=hs2 and ("' + HP4B + '" .. second.id')
    # FX player after SPOT (needs SPOT, boardOf, boardPoint)
    s = replace(s, "}\n\n-- TTS labels never Draw.wrap: break long text into lines of about",
                "}\n" + FXLUA.replace("@FX@", FX) + "\n-- TTS labels never Draw.wrap: break long text into lines of about")
    # events -> FX
    s = replace(s, '        if e.fx ~= "hero_select" and e.msg then broadcastToAll(e.msg, {0.95, 0.85, 0.6}) end\n',
                   '        if e.fx ~= "hero_select" and e.msg then broadcastToAll(e.msg, {0.95, 0.85, 0.6}) end\n        if Draw.eventFx then pcall(Draw.eventFx, e) end\n')
    # combat: hit / Divine Shield pop
    s = replace(s, '''            if info then
                if d.combat and previous and previous.hp then
                    local amount = previous.hp - d.hp
                    info.splat = amount > 0 and amount or nil
                end''', '''            if info then
                if d.combat and previous and previous.hp then
                    local amount = previous.hp - d.hp
                    info.splat = amount > 0 and amount or nil
                    if amount > 0 and Draw.fx then pcall(Draw.fx, "hit", ready.getPosition()) end
                    if previous.shield and not d.shield and Draw.fx then pcall(Draw.fx, "shield", ready.getPosition()) end
                end''')
    # combat: deaths
    s = replace(s, '    for _, key in ipairs(gone) do destroyToken(color, key) end\n',
                '''    for _, key in ipairs(gone) do
        if inCombat and Draw.fx then
            local dying = tokenFor(color, key)
            local dinfo = dying and tokenInfo[dying.getGUID()]
            if dinfo and dinfo.d and dinfo.d.combat then pcall(Draw.fx, "death", dying.getPosition()) end
        end
        destroyToken(color, key)
    end
''')
    # Dark Gift purchase
    s = replace(s, '''            if action == "darkgift" then
                ok, err = BG.buyDarkGift(game, owner)
''', '''            if action == "darkgift" then
                ok, err = BG.buyDarkGift(game, owner)
                local dg = ok and tileOf(owner, "darkgift")
                if dg and Draw.fxBoard then pcall(Draw.fxBoard, owner, "darkgift", dg.right, dg.near) end
''')
    # Activate: decal + object button on the token; the old fixed tile is gone
    s = replace(s, '''local function overlay(obj, d)
    local info = tokenInfo[obj.getGUID()]
    if not info or info.retiring then return end''', ACTLUA + '''local function overlay(obj, d)
    local info = tokenInfo[obj.getGUID()]
    if not info or info.retiring then return end
    pcall(Draw.activateButton, obj, d, info)''')
    s = replace(s, 'tostring(m.poison or m.p), tostring(m.darkmoonTicket)\n    }, "|")',
                   'tostring(m.poison or m.p), tostring(m.darkmoonTicket), Draw.activateKey and Draw.activateKey(info, d) or ""\n    }, "|")')
    s = replace(s, '    if d.zone == "tavern" and m.darkmoonTicket then',
                '''    local act = Draw.activateState and Draw.activateState(info, d)
    if act then add("activate", nil, 0, -.625, 1.23 * (152 / 175) / width, 1.23 / height, act.url) end
    if d.zone == "tavern" and m.darkmoonTicket then''')
    s = replace(s, '''            ensureTile(color,"activate"..i,{url=Draw.season14Art(path),face={r=152/175},size=1.23,fit="h",''',
                   '''            if false then ensureTile(color,"activate"..i,{url=Draw.season14Art(path),face={r=152/175},size=1.23,fit="h",''')
    s = replace(s, '''                tip=used and "Activate used this turn" or ("Activate · "..cost.." Gold\\n"..BG_CARDS[m.id].text)})
        end
    end''', '''                tip=used and "Activate used this turn" or ("Activate · "..cost.." Gold\\n"..BG_CARDS[m.id].text)}) end
        end
    end''')
    s = replace(s, "local function widgetClick(obj, color, key)", CLICK + "local function widgetClick(obj, color, key)")
    # preload the FX frames with the game's one-time download; clean stray FX carriers on load
    s = replace(s, "    printToAll(\"Downloading Hearthstone Cards for better Performance. Please wait.\", {1, 0.85, 0.4})\n",
                "    if Draw.fxUrls then for _, u in ipairs(Draw.fxUrls()) do list[#list + 1] = u end end\n"
                "    printToAll(\"Downloading Hearthstone Cards for better Performance. Please wait.\", {1, 0.85, 0.4})\n")
    s = replace(s, "function onLoad(saved)\n", "function onLoad(saved)\n    Wait.time(function() if Draw.fxCleanup then pcall(Draw.fxCleanup) end end, 1)\n")
    return s
