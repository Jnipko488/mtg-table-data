local seats = {
    {guid="7af774", color="Yellow", yaw=0},
    {guid="73652b", color="Blue", yaw=0},
    {guid="d203fb", color="Red", yaw=180},
    {guid="1184c1", color="White", yaw=180},
    {guid="25b273", color="Purple", yaw=0},
    {guid="8be353", color="Orange", yaw=180},
    {guid="90759f", color="Teal", yaw=0},
    {guid="869678", color="Pink", yaw=180}
}
local boardData = [==[{"Name":"Custom_Assetbundle","Nickname":"Tabletop Arena","Transform":{"posX":0,"posY":1.22,"posZ":0,"rotX":0,"rotY":0,"rotZ":0,"scaleX":1,"scaleY":1,"scaleZ":1},"Locked":true,"Grid":false,"Snap":false,"Hands":false,"Tooltip":false,"CustomAssetbundle":{"AssetbundleURL":"https://raw.githubusercontent.com/Jnipko488/mtg-table-data/4c0f8adafde8c9c01b4a566008d0729fc4890b08/hsbg/tts/tabletop-arena-media-v2.unity3d","AssetbundleSecondaryURL":"","TypeIndex":0,"MaterialIndex":0,"LoopingEffectIndex":0},"AttachedSnapPoints":[{"Position":{"x":-9.3,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":-6.2,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":-3.1,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":0.0,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":3.1,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":6.2,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":9.3,"y":0.105,"z":-2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":-9.3,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":-6.2,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":-3.1,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":0.0,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":3.1,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":6.2,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]},{"Position":{"x":9.3,"y":0.105,"z":2.15},"Rotation":{"x":0,"y":0,"z":0},"RotationSnap":false,"Tags":[]}],"LuaScript":"local phases = {\n    setup = {label = \"Setup\", color = {0.22, 0.23, 0.28}},\n    recruit = {label = \"Recruit\", color = {0.14, 0.36, 0.28}},\n    combat = {label = \"Combat\", color = {0.51, 0.20, 0.13}},\n    results = {label = \"Results\", color = {0.40, 0.31, 0.11}},\n}\nlocal current = \"setup\"\nlocal displayReady = false\nlocal queuedMedia\n\nlocal function playMedia(phase)\n    if not self.AssetBundle then\n        return\n    end\n    local name = phase == \"combat\" and \"combat_open\" or \"normal_board\"\n    for _, effect in ipairs(self.AssetBundle.getTriggerEffects() or {}) do\n        if effect.name == name then\n            self.AssetBundle.playTriggerEffect(effect.index)\n            return\n        end\n    end\nend\n\nlocal function refresh()\n    if displayReady then\n        local phase = phases[current]\n        self.editButton({index = 0, label = phase.label, color = phase.color})\n    end\nend\n\nfunction setArenaPhase(request)\n    if type(request) ~= \"table\" or not phases[request.phase] then\n        return false\n    end\n    if current == request.phase then\n        return false\n    end\n    current = request.phase\n    refresh()\n    if displayReady then\n        playMedia(current)\n    else\n        queuedMedia = current\n    end\n    return true\nend\n\nfunction onSave()\n    return current\nend\n\nfunction onLoad(saved)\n    if phases[saved] then\n        current = saved\n    end\n    Wait.condition(function()\n        local phase = phases[current]\n        self.createButton({\n            click_function = \"arenaPhaseLabel\",\n            function_owner = self,\n            label = phase.label,\n            position = {0, 0.17, 10.98},\n            width = 1900,\n            height = 485,\n            font_size = 290,\n            color = phase.color,\n            font_color = {1, 0.96, 0.83},\n        })\n        displayReady = true\n        if queuedMedia then\n            playMedia(queuedMedia)\n            queuedMedia = nil\n        end\n    end, function()\n        return not self.loading_custom and not self.spawning\n    end, 30, function()\n        print(\"Tabletop Arena board did not finish loading.\")\n    end)\nend\n\nfunction arenaPhaseLabel() end\n\nlocal launcherGuid = \"f06d01\"\nlocal gameView\nlocal timer\nlocal controlColor = {0.12, 0.18, 0.24}\nlocal textColor = {1, 0.94, 0.82}\n\nlocal function press(action, index, color, altClick)\n    if altClick or not gameView or color ~= gameView.seat then\n        return\n    end\n    local launcher = getObjectFromGUID(launcherGuid)\n    if launcher then\n        launcher.call(\"tableArenaAction\", {\n            seat = gameView.seat, color = color, action = action, index = index,\n        })\n    end\nend\n\nfor slot = 1, 4 do\n    local index = slot\n    _G[\"arenaMarket\" .. index] = function(_, color, altClick)\n        press(\"buy\", index, color, altClick)\n    end\n    _G[\"arenaLane\" .. index] = function(_, color, altClick)\n        press(\"lane\", index, color, altClick)\n    end\nend\n\nfunction arenaScout(_, color, altClick)\n    press(\"scout\", nil, color, altClick)\nend\n\nfunction arenaRelease(_, color, altClick)\n    press(\"release\", nil, color, altClick)\nend\n\nfunction arenaReady(_, color, altClick)\n    press(\"ready\", nil, color, altClick)\nend\n\nfunction arenaGameNoop() end\nfunction arenaGameClock() end\n\nlocal function button(callback, label, x, z, width, height, size, color, tooltip)\n    self.createButton({\n        click_function = callback, function_owner = self, label = label,\n        position = {x, 0.18, z}, width = width, height = height, font_size = size,\n        color = color or controlColor, font_color = textColor, tooltip = tooltip or \"\",\n    })\nend\n\nlocal function unitButton(callback, unit, x, z, empty, prefix, selected)\n    local label, tint, tip = empty, {0.19, 0.22, 0.26}, nil\n    if unit then\n        local aid = unit.aid and \"    +\" .. unit.aid .. \" Aid\" or \"\"\n        label = unit.name .. \"\\n\" .. unit.force .. \" Force   \" .. unit.ward .. \" Ward\" .. aid\n        tint = unit.aid and {0.29, 0.17, 0.38} or {0.16, 0.31, 0.31}\n        tip = unit.aid and (\"Adds \" .. unit.aid .. \" Force to each adjacent allied unit.\") or unit.name\n    end\n    if prefix then\n        label = prefix .. \"\\n\" .. label\n    end\n    if selected then\n        tint = {0.48, 0.34, 0.13}\n    end\n    button(callback, label, x, z, 2350, 1275, 249, tint, tip)\nend\n\nlocal function timeLabel(view)\n    local now = math.floor(os.time())\n    return tostring(math.max(0, (view.deadline or now) - now)) .. \"s\"\nend\n\nlocal function tickClock()\n    for _, info in ipairs(self.getButtons() or {}) do\n        if info.click_function == \"arenaGameClock\" then\n            self.editButton({index = info.index, label = timeLabel(gameView)})\n            return\n        end\n    end\nend\n\nlocal function drawGame()\n    if not displayReady or not gameView then\n        return\n    end\n    if timer then\n        Wait.stop(timer)\n        timer = nil\n    end\n    local buttons = self.getButtons() or {}\n    for index = #buttons, 1, -1 do\n        if buttons[index].click_function ~= \"arenaPhaseLabel\" then\n            self.removeButton(buttons[index].index)\n        end\n    end\n\n    local view = gameView\n    local status = view.seat .. \"  |  \" .. view.captain.name .. (view.bot and \" (Bot)\" or \"\")\n    button(\"arenaGameNoop\", status, 0, -10.95, 4770, 535, 305, nil, view.captain.bonus)\n    local summary = \"Round \" .. view.round .. \"/\" .. view.rounds .. \"  |  \" .. view.supply\n        .. \" Supply  |  \" .. view.renown .. \" Renown\"\n    button(\"arenaGameNoop\", summary, 0, -8.95, 5100, 495, 265, nil, view.captain.bonus)\n\n    for lane = 1, 4 do\n        local x = (lane - 2.5) * 5.65\n        if view.phase == \"recruit\" then\n            local unit = view.market[lane]\n            unitButton(\"arenaMarket\" .. lane, unit, x, -3.34, \"Sold\", unit and unit.cost .. \" Supply\")\n        elseif view.phase == \"results\" and view.result and view.result.lanes then\n            local score = view.result.lanes[lane]\n            button(\"arenaGameNoop\", score[1] .. \" : \" .. score[2], x, -3.34, 1600, 590, 350)\n        end\n        local callback = view.phase == \"recruit\" and \"arenaLane\" .. lane or \"arenaGameNoop\"\n        unitButton(callback, view.formation[lane], x, 2.8, \"Empty\", \"Lane \" .. lane, view.selected == lane)\n    end\n\n    if view.phase == \"recruit\" then\n        button(\"arenaScout\", view.freeScout and \"Scout (Free)\" or \"Scout (1)\", -8.5, 7.52, 2050, 615, 260,\n            nil, \"Replace all market offers.\")\n        button(\"arenaRelease\", \"Release (+1)\", -3.5, 7.52, 1950, 615, 260, nil,\n            \"Select a formation unit to release it.\")\n        button(\"arenaReady\", view.ready and \"Unready\" or \"Ready\", 4.0, 7.52, 2050, 615, 260)\n        button(\"arenaGameClock\", timeLabel(view), 9.4, 7.52, 950, 615, 250)\n        local now = math.floor(os.time())\n        timer = Wait.time(tickClock, 1, math.max(1, math.min(75, (view.deadline or now) - now)))\n    elseif view.phase == \"results\" and view.winners then\n        button(\"arenaGameNoop\", \"Winners: \" .. table.concat(view.winners, \", \"), 0, 7.6, 7500, 640, 280)\n    elseif view.phase == \"results\" and view.result then\n        local result = view.result\n        local label = result.bye and \"Bye  |  +1 Renown\"\n            or (\"vs \" .. result.opponent .. \"  |  Lanes \" .. result.own .. \"-\" .. result.other .. \"  |  +\" .. result.score .. \" Renown\")\n        button(\"arenaGameNoop\", label, 0, 7.6, 7500, 640, 280)\n    elseif view.phase == \"combat\" then\n        button(\"arenaGameNoop\", view.next and (\"Clash with \" .. view.next) or \"Bye this round\", 0, 7.6, 6200, 580, 280)\n    end\nend\n\nfunction setTableArenaView(view)\n    gameView = view\n    setArenaPhase({phase = view.phase})\n    drawGame()\nend\n\nlocal loadMedia = onLoad\nfunction onLoad(saved)\n    loadMedia(saved)\n    Wait.condition(function()\n        local launcher = getObjectFromGUID(launcherGuid)\n        local seat = self.getName():match(\"^Tabletop Arena %- (.+)$\")\n        if launcher and seat then\n            local view = launcher.call(\"getTableArenaView\", {seat = seat})\n            if view then\n                setTableArenaView(view)\n                return\n            end\n        end\n        drawGame()\n    end, function()\n        return displayReady\n    end, 30)\nend\n\nfunction onDestroy()\n    if timer then\n        Wait.stop(timer)\n    end\nend\n","LuaScriptState":"","XmlUI":""}]==]
local Arena = (function()
local roster = {
    {name = "Marsh Guard", cost = 2, force = 1, ward = 3},
    {name = "Wind Scout", cost = 2, force = 3, ward = 0},
    {name = "Torch Runner", cost = 2, force = 2, ward = 1},
    {name = "Bell Keeper", cost = 2, force = 1, ward = 1, aid = 1},
    {name = "Dune Rider", cost = 3, force = 4, ward = 1},
    {name = "Stone Warden", cost = 3, force = 2, ward = 4},
    {name = "Ferry Guide", cost = 3, force = 2, ward = 2, aid = 1},
    {name = "Hawk Sentry", cost = 3, force = 5, ward = 0},
    {name = "Iron Elk", cost = 4, force = 4, ward = 3},
    {name = "Lantern Mage", cost = 4, force = 2, ward = 2, aid = 2},
    {name = "Ridge Giant", cost = 4, force = 6, ward = 1},
    {name = "Bridge Knight", cost = 4, force = 3, ward = 5},
}

local captains = {
    {name = "Stonewatch", bonus = "Inner lanes gain 1 Ward."},
    {name = "Reedwake", bonus = "Outer lanes gain 1 Force."},
    {name = "Copperhand", bonus = "Gain 1 extra Supply every round."},
    {name = "Beacon", bonus = "Lanes next to an empty lane gain 1 Ward."},
    {name = "Highwind", bonus = "Lanes next to a friendly unit gain 1 Force."},
    {name = "Harbor Run", bonus = "The first Scout each round is free."},
    {name = "Lamplighter", bonus = "Units that cost 2 gain 1 Ward."},
    {name = "Red Fox", bonus = "Lane 1 gains 2 Force."},
}

local Rules = {roster = roster, captains = captains, lanes = 4}

local function captainStats(index, lane, unit, adjacent, open)
    local inner = lane == 2 or lane == 3
    local force = (index == 2 and not inner or index == 5 and adjacent) and 1 or 0
    local ward = (index == 1 and inner or index == 4 and open or index == 7 and unit.cost == 2) and 1 or 0
    if index == 8 and lane == 1 then
        force = force + 2
    end
    return force, ward
end

local function randomUnit(state)
    state.rng = (state.rng * 48271) % 2147483647
    return 1 + state.rng % #roster
end

local function restock(state, player)
    player.market = {}
    local shown = {}
    for slot = 1, Rules.lanes do
        local id = randomUnit(state)
        while shown[id] do
            id = id % #roster + 1
        end
        shown[id] = true
        player.market[slot] = id
    end
end

function Rules.new(colors, seed)
    assert(#colors >= 2 and #colors <= 8, "The arena supports 2 to 8 seats.")
    local order, players = {}, {}
    for index, color in ipairs(colors) do
        assert(not players[color], "Duplicate arena seat.")
        order[index] = color
        players[color] = {
            captain = index, formation = {0, 0, 0, 0}, supply = 0, renown = 0, margin = 0,
        }
    end
    if #order % 2 == 1 then
        order[#order + 1] = false
    end
    return {
        order = order, players = players, round = 0, rounds = math.max(5, #order - 1),
        rng = math.floor(seed or 1) % 2147483646 + 1, phase = "setup", report = {},
    }
end

function Rules.beginRecruit(state)
    assert(state.phase == "setup" or state.phase == "results", "Recruit is out of sequence.")
    assert(state.round < state.rounds, "The match has already ended.")
    state.round = state.round + 1
    state.phase = "recruit"
    for _, color in ipairs(state.order) do
        if color then
            local player = state.players[color]
            local captainSupply = player.captain == 3 and 1 or 0
            player.supply = 5 + math.min(state.round, 3) + math.min(player.supply, 2) + captainSupply
            player.ready = false
            player.freeScout = player.captain == 6
            player.selected = 0
            restock(state, player)
        end
    end
end

local function isLane(index)
    return type(index) == "number" and index % 1 == 0 and index >= 1 and index <= Rules.lanes
end

function Rules.act(state, color, action, index)
    local player = state.players[color]
    if not player or state.phase ~= "recruit" then
        return false, "Wait for Recruit."
    end
    if action == "ready" then
        player.ready = not player.ready
        player.selected = 0
        return true
    end
    if player.ready then
        return false, "Click Unready to edit your formation."
    end
    if action == "buy" and isLane(index) then
        local id = player.market[index]
        local unit = roster[id]
        if not unit or unit.cost > player.supply then
            return false, "That unit is sold or costs more Supply than you have."
        end
        for lane = 1, Rules.lanes do
            if player.formation[lane] == 0 then
                player.formation[lane], player.market[index] = id, 0
                player.supply = player.supply - unit.cost
                return true
            end
        end
        return false, "Release a unit to make room."
    elseif action == "lane" and isLane(index) then
        local previous = player.selected
        player.selected = 0
        if previous == 0 then
            if player.formation[index] ~= 0 then
                player.selected = index
            end
        elseif previous ~= index then
            player.formation[previous], player.formation[index] = player.formation[index], player.formation[previous]
        end
        return true
    elseif action == "release" and player.selected > 0 then
        player.formation[player.selected] = 0
        player.supply = player.supply + 1
        player.selected = 0
        return true
    elseif action == "scout" then
        local cost = player.freeScout and 0 or 1
        if player.supply < cost then
            return false, "Scouting costs 1 Supply."
        end
        player.supply = player.supply - cost
        player.freeScout = false
        restock(state, player)
        return true
    end
    return false, "Select a unit in your formation first."
end

local function strength(unit)
    return unit.force + unit.ward + (unit.aid or 0) * 1.5
end

function Rules.runBot(state, color)
    local player = state.players[color]
    local weakestLane, weakest, open = 1, math.huge, false
    for lane, id in ipairs(player.formation) do
        local score = id == 0 and 0 or strength(roster[id])
        if score < weakest then
            weakestLane, weakest = lane, score
        end
        open = open or id == 0
    end
    if not open then
        for _, id in ipairs(player.market) do
            local unit = roster[id]
            if unit and unit.cost <= player.supply + 1 and strength(unit) > weakest then
                Rules.act(state, color, "lane", weakestLane)
                Rules.act(state, color, "release")
                break
            end
        end
    end
    for _ = 1, Rules.lanes do
        local bestSlot, bestScore = 0, -1
        for slot, id in ipairs(player.market) do
            local unit = roster[id]
            if unit and unit.cost <= player.supply then
                local score = strength(unit) / unit.cost
                if score > bestScore then
                    bestSlot, bestScore = slot, score
                end
            end
        end
        if bestSlot == 0 or not Rules.act(state, color, "buy", bestSlot) then
            break
        end
    end
    player.ready = true
end

function Rules.pairings(state)
    local order = {}
    for index, color in ipairs(state.order) do
        order[index] = color
    end
    for _ = 1, (state.round - 1) % (#order - 1) do
        table.insert(order, 2, table.remove(order))
    end
    local pairings = {}
    for index = 1, #order / 2 do
        pairings[index] = {order[index], order[#order + 1 - index]}
    end
    return pairings
end

local function laneStats(player, lane)
    local formation = player.formation
    local unit = roster[formation[lane]]
    if not unit then
        return 0, 0
    end
    local left, right = roster[formation[lane - 1]], roster[formation[lane + 1]]
    local open = lane > 1 and left == nil or lane < Rules.lanes and right == nil
    local force, ward = captainStats(player.captain, lane, unit, left or right, open)
    return unit.force + force + (left and left.aid or 0) + (right and right.aid or 0), unit.ward + ward
end

function Rules.resolve(state)
    assert(state.phase == "combat", "Combat is out of sequence.")
    local report = {}
    for _, pair in ipairs(Rules.pairings(state)) do
        local first, second = pair[1], pair[2]
        local a, b = state.players[first], state.players[second]
        if a and b then
            local winsA, winsB, margin, lanesA, lanesB = 0, 0, 0, {}, {}
            for lane = 1, Rules.lanes do
                local forceA, wardA = laneStats(a, lane)
                local forceB, wardB = laneStats(b, lane)
                local netA, netB = math.max(0, forceA - wardB), math.max(0, forceB - wardA)
                winsA = winsA + (netA > netB and 1 or 0)
                winsB = winsB + (netB > netA and 1 or 0)
                margin = margin + netA - netB
                lanesA[lane], lanesB[lane] = {netA, netB}, {netB, netA}
            end
            local scoreA = winsA > winsB and 3 or (winsA == winsB and 1 or 0)
            local scoreB = winsB > winsA and 3 or (winsB == winsA and 1 or 0)
            a.renown, b.renown = a.renown + scoreA, b.renown + scoreB
            a.margin, b.margin = a.margin + margin, b.margin - margin
            report[first] = {opponent = second, own = winsA, other = winsB, score = scoreA, lanes = lanesA}
            report[second] = {opponent = first, own = winsB, other = winsA, score = scoreB, lanes = lanesB}
        else
            local seat = first or second
            local player = state.players[seat]
            player.renown = player.renown + 1
            report[seat] = {score = 1, bye = true}
        end
    end
    state.phase, state.report = "results", report
end

function Rules.winners(state)
    local winners, renown, margin = {}, -1, -math.huge
    for _, color in ipairs(state.order) do
        if color then
            local player = state.players[color]
            if player.renown > renown or player.renown == renown and player.margin > margin then
                winners, renown, margin = {}, player.renown, player.margin
            end
            if player.renown == renown and player.margin == margin then
                winners[#winners + 1] = color
            end
        end
    end
    return winners
end

return Rules

end)()

local match
local waitId, deadline
local opening = false
local openGeneration = 0
local recruitSeconds, combatSeconds, resultsSeconds = 75, 8, 6
local runPhase

local function boardTag()
    return "table_arena_board_" .. self.getGUID()
end

local function boards()
    return getObjectsWithTag(boardTag())
end

local function seatFor(board)
    return board.getName():match("^Tabletop Arena %- (.+)$")
end

local function isHost(color)
    return Player[color] and Player[color].host
end

local function isSeated(color)
    return type(color) == "string" and Player[color] and Player[color].seated
end

local function syncLauncher()
    local label = opening and "Opening..." or (#boards() == 0 and "Begin Setup" or "Close Setup")
    for _, button in ipairs(self.getButtons() or {}) do
        if button.click_function == "toggleTableArena" then
            self.editButton({index = button.index, label = label})
            return
        end
    end
    self.createButton({
        click_function = "toggleTableArena", function_owner = self, label = label,
        tooltip = "Host only. Start or clear the Tabletop Arena match.",
        position = {0, 1.27, 1.4}, width = 1720, height = 370, font_size = 156,
        color = {0.14, 0.22, 0.17}, font_color = {1, 0.91, 0.71},
    })
end

local function activeSeats()
    local targets = {}
    for _, seat in ipairs(seats) do
        local mat = getObjectFromGUID(seat.guid)
        if mat then
            local center = mat.getPosition()
            if center.y > -20 then
                local bounds = mat.getBounds()
                local surface = math.max(center.y, bounds.center.y + bounds.size.y / 2)
                targets[#targets + 1] = {
                    color = seat.color, position = {center.x, surface + 0.125, center.z},
                    rotation = {0, seat.yaw, 0},
                }
            end
        end
    end
    return targets
end

local function clearBoards()
    for _, board in ipairs(boards()) do
        board.destruct()
    end
end

local function cancelPhase()
    if waitId then
        Wait.stop(waitId)
    end
    waitId, deadline = nil, nil
end

local function schedule(seconds)
    cancelPhase()
    deadline = math.floor(os.time()) + seconds
    waitId = Wait.time(function()
        waitId, deadline = nil, nil
        runPhase()
    end, math.max(seconds, 0.1))
end

function getTableArenaView(request)
    local seat = request and request.seat
    local player = match and match.players[seat]
    if not player then
        return nil
    end
    local upcoming
    for _, pair in ipairs(Arena.pairings(match)) do
        if pair[1] == seat or pair[2] == seat then
            upcoming = pair[1] == seat and pair[2] or pair[1]
            if upcoming == seat then
                upcoming = nil
            end
            break
        end
    end
    local lineup, market = {}, {}
    for lane, id in ipairs(player.formation) do
        lineup[lane] = Arena.roster[id] or false
        market[lane] = Arena.roster[player.market[lane]] or false
    end
    return {
        seat = seat, captain = Arena.captains[player.captain], bot = not isSeated(seat),
        supply = player.supply, renown = player.renown, phase = match.phase,
        round = match.round, rounds = match.rounds, deadline = deadline,
        ready = player.ready, freeScout = player.freeScout, selected = player.selected,
        formation = lineup, market = market, next = upcoming, result = match.report[seat],
        winners = match.phase == "results" and match.round == match.rounds and Arena.winners(match) or nil,
    }
end

local function updateBoards(onlySeat)
    for _, board in ipairs(boards()) do
        local seat = seatFor(board)
        if seat and (not onlySeat or onlySeat == seat) then
            local view = getTableArenaView({seat = seat})
            if view then
                board.call("setTableArenaView", view)
            end
        end
    end
end

local function beginRound()
    Arena.beginRecruit(match)
    for _, color in ipairs(match.order) do
        if color and not isSeated(color) then
            Arena.runBot(match, color)
        end
    end
    schedule(recruitSeconds)
end

runPhase = function()
    if not match then
        return
    end
    if match.phase == "recruit" then
        for _, color in ipairs(match.order) do
            if color and not isSeated(color) and not match.players[color].ready then
                Arena.runBot(match, color)
            end
        end
        match.phase = "combat"
        schedule(combatSeconds)
    elseif match.phase == "combat" then
        Arena.resolve(match)
        if match.round < match.rounds then
            schedule(resultsSeconds)
        else
            cancelPhase()
            broadcastToAll("Tabletop Arena winners: " .. table.concat(Arena.winners(match), ", "), {1, 0.92, 0.65})
        end
    elseif match.phase == "results" and match.round < match.rounds then
        beginRound()
    end
    updateBoards()
end

function tableArenaAction(request)
    if not match or type(request) ~= "table" or request.color ~= request.seat or not isSeated(request.color) then
        return false
    end
    local ok, reason = Arena.act(match, request.seat, request.action, request.index)
    if not ok then
        Player[request.color].print(reason)
        return false
    end
    if request.action == "ready" then
        for _, player in pairs(match.players) do
            if not player.ready then
                updateBoards(request.seat)
                return true
            end
        end
        runPhase()
    else
        updateBoards(request.seat)
    end
    return true
end

local function openBoards(targets, host)
    opening, openGeneration = true, openGeneration + 1
    local generation = openGeneration
    local pending, colors = #targets, {}
    syncLauncher()

    local function abort()
        if generation ~= openGeneration then
            return
        end
        opening, openGeneration = false, openGeneration + 1
        clearBoards()
        host.print("A board failed to load. Try Begin Setup again.")
        Wait.frames(syncLauncher, 1)
    end
    local timeout = Wait.time(abort, 25)

    for index, target in ipairs(targets) do
        local seat = target
        colors[index] = seat.color
        local ok, object = pcall(spawnObjectJSON, {
            json = boardData, position = seat.position, rotation = seat.rotation, sound = false,
            callback_function = function(board)
                if generation ~= openGeneration then
                    board.destruct()
                    return
                end
                board.addTag(boardTag())
                board.setName("Tabletop Arena - " .. seat.color)
                board.setLock(true)
                pending = pending - 1
                if pending == 0 then
                    Wait.stop(timeout)
                    Wait.frames(function()
                        opening = false
                        match = Arena.new(colors, os.time())
                        beginRound()
                        updateBoards()
                        syncLauncher()
                    end, 1)
                end
            end,
        })
        if not ok or not object then
            Wait.stop(timeout)
            abort()
            return
        end
    end
end

function toggleTableArena(_, color, altClick)
    if altClick or opening or not isHost(color) then
        return
    end
    if #boards() > 0 then
        cancelPhase()
        match = nil
        clearBoards()
        Wait.frames(syncLauncher, 1)
        return
    end
    if Global.getVar("mtBusy") then
        Player[color].print("Wait for the MTG mats to finish moving, then try again.")
        return
    end
    local targets = activeSeats()
    if #targets < 2 then
        Player[color].print("Open at least two MTG player mats first.")
        return
    end
    openBoards(targets, Player[color])
end

function onSave()
    if match then
        return JSON.encode({version = 1, match = match,
            remaining = deadline and math.max(0, deadline - math.floor(os.time()))})
    end
    return ""
end

function onLoad(saved)
    local remaining
    if saved and saved ~= "" then
        local ok, data = pcall(JSON.decode, saved)
        if ok and data and data.version == 1 then
            match, remaining = data.match, data.remaining
        end
    end
    Wait.condition(function()
        syncLauncher()
        if match and remaining then
            schedule(remaining)
        end
        updateBoards()
    end, function()
        return not self.loading_custom and not self.spawning
    end, 30, function()
        print("Tabletop Arena setup box did not finish loading.")
    end)
end

-- Battlegrounds bridge (appended by Tools/build_battlegrounds.py to the Tabletop Arena Setup Box).
-- v4: the Setup Box button reads "Play Hearthstone Battlegrounds"; clicking it opens the settings HUD
-- (season, timer, Buddies, Trinkets, Anomalies, Start) owned by the hidden Battlegrounds Tavern
-- (b9a001). While a game runs the button reads "End Battlegrounds". Codex's original lane game stays available from this
-- box's right-click menu ("Arena lane game (original)").
-- Calls into the Tavern are deferred by one frame so the two scripts never call each other re-entrantly.
local bgIdleLabel = "Play Hearthstone\nBattlegrounds"

function bgActiveSeats()
    local colors = {}
    for _, target in ipairs(activeSeats()) do table.insert(colors, target.color) end
    return colors
end

function bgActiveTargets()
    return activeSeats()
end

function bgClearArenaBoards()
    if opening then return "busy" end
    if #boards() == 0 then return "clear" end
    cancelPhase()
    match = nil
    clearBoards()
    Wait.frames(syncLauncher, 1)
    Wait.frames(function() bgSetLabel({label = bgIdleLabel}) end, 2)
    return "cleared"
end

local function bgTavern() return getObjectFromGUID("b9a001") end

local function bgSay(color, msg)
    if Player[color] and Player[color].seated then
        Player[color].broadcast(msg, {1, 0.5, 0.4})
    else
        broadcastToAll(msg, {1, 0.5, 0.4})
    end
end

local function bgAlive(tavern)
    local ok, answer = pcall(function() return tavern.call("bgPing") end)
    return ok and answer == "pong"
end

local function bgRunning()
    local tavern = bgTavern()
    if not tavern then return false end
    local ok, running = pcall(function() return tavern.call("bgIsRunning") end)
    return ok and running == true
end

function bgSetLabel(params)
    local label = type(params) == "table" and params.label or tostring(params)
    for _, button in ipairs(self.getButtons() or {}) do
        if button.click_function == "toggleTableArena" then
            label = (label == "Play Hearthstone Battlegrounds") and bgIdleLabel or label
            self.editButton({index = button.index, label = label, font_size = label:find("\n") and 124 or 140,
                tooltip = (type(params) == "table" and params.tooltip ~= "" and params.tooltip) or "Host only. Open the Hearthstone Battlegrounds settings, or end the game."})
            return true
        end
    end
    return false
end

local arenaToggle = toggleTableArena
function toggleTableArena(obj, color, altClick)
    if altClick then return end
    if not isHost(color) then
        bgSay(color, "Only the host can start Battlegrounds.")
        return
    end
    local tavern = bgTavern()
    if not tavern then
        bgSay(color, "The Battlegrounds Tavern (b9a001) is missing from this table, so Battlegrounds cannot start.")
        return
    end
    if not bgAlive(tavern) then
        bgSay(color, "The Battlegrounds Tavern script is not running. Reload the save and allow scripts to run, then try again.")
        bgSetLabel({label = "Start failed - click to retry", tooltip = "The Battlegrounds Tavern script did not answer."})
        return
    end
    if opening then
        bgSay(color, "The Setup Box is still opening its lane-game boards. Try again in a moment.")
        return
    end
    local running = bgRunning()
    if not running and #boards() > 0 then
        bgClearArenaBoards() -- the button reads "Close Setup" while Codex's lane game is open
        return
    end
    Wait.frames(function()
        local ok = pcall(function() tavern.call("bgLauncherToggle", {color = color}) end)
        if not ok then
            bgSay(color, "Battlegrounds could not be reached. See the Tavern panel for details.")
            bgSetLabel({label = "Start failed - click to retry"})
        end
        Wait.time(bgSyncLabel, 2)
    end, 1)
end

function bgSyncLabel()
    if opening then return end
    if bgRunning() then
        bgSetLabel({label = "End Battlegrounds", tooltip = "Host only. End the Battlegrounds game."})
    elseif #boards() == 0 then
        for _, button in ipairs(self.getButtons() or {}) do
            if button.click_function == "toggleTableArena" and button.label ~= bgIdleLabel
                    and button.label ~= "Start failed - click to retry" and button.label ~= "Starting..." then
                bgSetLabel({label = bgIdleLabel, tooltip = "Host only. Open the Battlegrounds settings (season, timer, Buddies, Trinkets, Anomalies)."})
            end
        end
    end
end

function bgOpenLaneGame(color)
    if bgRunning() then
        bgSay(color, "End the Battlegrounds game first.")
        return
    end
    local result = arenaToggle(self, color, false)
    Wait.frames(syncLauncher, 2)
    return result
end

local arenaLoad = onLoad
function onLoad(saved)
    arenaLoad(saved)
    pcall(function() self.clearContextMenu() end)
    Wait.time(bgSyncLabel, 3)
    Wait.time(bgSyncLabel, 8)
end
