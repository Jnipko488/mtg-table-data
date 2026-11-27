"""Batch 22: Activate minions like HS (cost coin top-right of the portrait + green glow when usable; the round icon without
cost once used; green glow on every legal target while choosing), readable ability text from every camera angle, and
the Blood Gem / spell live text placed on the card's real text box."""
UI = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/505f29f2a8d581c0b4cabcdd96322e7a7c404572/hsbg/battlegrounds-multiplayer/s14-leaderboard/ui/"
COIN = "https://raw.githubusercontent.com/Jnipko488/mtg-table-data/1c3dbbc7887ff04e8479e3d2688070035fab0d6a/hsbg/battlegrounds-multiplayer/s14-leaderboard/hp3/coin/"

def patch(s, replace, HERE):
    # --- text readable at any angle: glyphs well above their parchment (TTS sorts close transparent decals by camera)
    s = replace(s, '                    right = x + gw / 2 - off, near = z, layer = layer, lift = lift + .01})',
                   '                    right = x + gw / 2 - off, near = z, layer = layer, lift = lift + .05})')
    s = replace(s, 'position = {-right / scale, y0 + (i == 1 and 0 or .004) / scale, near / scale},',
                   'position = {-right / scale, y0 + (i == 1 and 0 or .03) / scale, near / scale},')
    # --- the real text box of a Hearthstone Battlegrounds spell render (measured on BG20_GEM, 512x776)
    s = replace(s, 'Draw.SPELL_TEXT_BOX = {cx = .473, cy = .700, w = .545, h = .195}',
                   'Draw.SPELL_TEXT_BOX = {cx = .500, cy = .727, w = .640, h = .225}')
    # --- Activate state: coin (ready) / used icon, glow, legal targets
    s = replace(s, '''    local ok = BG.canAct(game, p)
    local enabled = ok and not used and p.gold >= cost
    return {cost = cost, used = used, enabled = enabled and true or false,
        url = Draw.season14Art("activate/" .. (enabled and "ready-" or "locked-") .. math.min(4, cost) .. ".png")}''',
    '''    local ok = BG.canAct(game, p)
    local enabled = ok and not used and p.gold >= cost and not p.discover
    return {cost = cost, used = used, enabled = enabled and true or false,
        url = used and "@UI@activate_used.png" or ("@COIN@" .. math.max(0, math.min(20, cost)) .. ".png")}'''.replace("@UI@", UI).replace("@COIN@", COIN))
    s = replace(s, '''function Draw.activateKey(info, d)
    local s = Draw.activateState(info, d)
    return s and (s.cost .. (s.enabled and "e" or "l") .. (s.used and "u" or "")) or ""
end''', '''function Draw.activateTarget(info, d)
    if not game or game.phase ~= "recruit" or d.combat then return false end
    local p = game.players[info.color]
    local c = p and p.discover
    if not c or c.kind ~= "activate_target" or not d.src then return false end
    for _, uid in ipairs(c.options or {}) do if uid == d.src.uid then return true end end
    return false
end
function Draw.activateKey(info, d)
    local s = Draw.activateState(info, d)
    local t = Draw.activateTarget(info, d) and "T" or ""
    return (s and (s.cost .. (s.enabled and "e" or "l") .. (s.used and "u" or "")) or "") .. t
end''')
    s = replace(s, '    if act then add("activate", nil, 0, -.625, 1.23 * (152 / 175) / width, 1.23 / height, act.url) end\n',
    '''    local pw = height * (300 / 372) / width
    if (act and act.enabled) or Draw.activateTarget(info, d) then
        add("actglow", nil, 0, 0, pw * 348 / 300, 420 / 372, "@UI@oval_glow_green.png")
    end
    if act then
        local cs = act.used and .30 or .27
        add("activate", nil, .33, -.40, cs, cs * width / height, act.url)
    end
'''.replace("@UI@", UI))
    # button over the coin (top-right of the portrait)
    s = replace(s, '''    local z = -.625 * 3.12 * (settings.flip and -1 or 1)
    pcall(function() obj.createButton({click_function = "bgActivateClick", function_owner = self, label = "",
        position = {0, (math.max(.12, tokenTop) + .2) / scale, z / scale}, rotation = {0, settings.flip and 180 or 0, 0},
        width = 330, height = 330,''', '''    local fx, fz = .33, -.40
    if settings.flip then fx, fz = -fx, -fz end
    if s.used then return end
    pcall(function() obj.createButton({click_function = "bgActivateClick", function_owner = self, label = "",
        position = {-fx * 2.48 / scale, (math.max(.12, tokenTop) + .2) / scale, fz * 3.12 / scale}, rotation = {0, settings.flip and 180 or 0, 0},
        width = 210, height = 210,''')
    return s
