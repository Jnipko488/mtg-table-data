-- Strict-ish Tabletop Simulator world for MoonSharp (TTS's own interpreter build).
LOG, ERRORS = {}, {}
FRAME, TIME = 0, 0
local START = START_OVERRIDE or 1795000000
os.time = function() return math.floor(START + TIME) end
local function log(s) LOG[#LOG + 1] = s; print(s) end
_LOG = log
local function fail(where, err)
    local msg = "LUA ERROR [" .. where .. "] " .. tostring(err)
    ERRORS[#ERRORS + 1] = msg
    print(msg)
end
function protected(where, fn, ...)
    local args = {...}
    local ok, res = xpcall(function() return fn(table.unpack(args)) end, function(e) return tostring(e) end)
    if not ok then fail(where, res) end
    return ok, res
end

-- Vector like TTS
local VMT = {}
VMT.__index = function(t, k)
    if k == 1 then return rawget(t, "x") elseif k == 2 then return rawget(t, "y") elseif k == 3 then return rawget(t, "z") end
    return nil
end
function vec(x, y, z) return Vector(x or 0, y or 0, z or 0) end
local function V(t)
    if type(t) ~= "table" then error("expected vector table, got " .. type(t), 3) end
    local x = t.x or t[1]; local y = t.y or t[2]; local z = t.z or t[3]
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then error("bad vector components", 3) end
    return vec(x, y, z)
end

-- deep copy across script boundaries (Object.call marshals values)
local function marshal(v, seen)
    if type(v) == "function" then return nil end
    if type(v) ~= "table" then return v end
    if rawget(v, "__isObject") then return v end
    seen = seen or {}
    if seen[v] then error("cyclic table passed through Object.call", 2) end
    seen[v] = true
    local out = {}
    for k, x in pairs(v) do out[k] = marshal(x, seen) end
    for i = 1, 3 do if out[i] == nil and getmetatable(v) == VMT then out[1], out[2], out[3] = v.x, v.y, v.z end end
    seen[v] = nil
    return out
end

OBJECTS, ORDER = {}, {}
local nextGuid = 0x100000
local function newGuid() nextGuid = nextGuid + 7; return string.format("%06x", nextGuid) end

local function rotY(deg, x, z)
    local r = math.rad(deg)
    return x * math.cos(r) + z * math.sin(r), -x * math.sin(r) + z * math.cos(r)
end

function makeObject(spec)
    local o = {guid = spec.guid or newGuid(), name = spec.type or "Custom_Token", nickname = spec.nickname or "",
        desc = spec.description or "", pos = V(spec.pos or {0, 1, 0}), rot = V(spec.rot or {0, 0, 0}),
        scale = V(spec.scale or {1, 1, 1}), tags = {}, memo = spec.memo, locked = spec.locked,
        buttons = {}, ctx = {}, spawning = spec.spawning or false, loading_custom = spec.loading or false,
        size = spec.size or {2, 0.2, 2}, effects = spec.effects, destroyed = false, vars = {}}
    for _, t in ipairs(spec.tags or {}) do o.tags[t] = true end
    if OBJECTS[o.guid] then error("duplicate guid " .. o.guid) end
    local proxy = {__isObject = true}
    o.proxy = proxy
    local m = {}
    m.getGUID = function() return o.guid end
    m.getName = function() return o.nickname end
    m.setName = function(n) o.nickname = n; return true end
    m.getDescription = function() return o.desc end
    m.setDescription = function(d) o.desc = d; return true end
    m.getPosition = function() return vec(o.pos.x, o.pos.y, o.pos.z) end
    m.getRotation = function() return vec(o.rot.x, o.rot.y, o.rot.z) end
    m.getScale = function() return vec(o.scale.x, o.scale.y, o.scale.z) end
    m.setScale = function(s) o.scale = V(s); return true end
    m.setPosition = function(p) o.pos = V(p); return true end
    m.setPositionSmooth = function(p) o.pos = V(p); return true end
    m.setRotation = function(r) o.rot = V(r); return true end
    m.setRotationSmooth = function(r) o.rot = V(r); return true end
    m.setLock = function(b) o.locked = b; return true end
    m.getLock = function() return o.locked end
    m.highlightOn = function() return true end
    m.highlightOff = function() return true end
    m.setColorTint = function(c) if type(c) ~= "table" then error("setColorTint: color table expected", 2) end o.tint = c; return true end
    m.setGMNotes = function() return true end
    m.getGMNotes = function() return "" end
    m.getBounds = function()
        return {center = vec(o.pos.x, o.pos.y, o.pos.z), size = vec(o.size[1] * o.scale.x, o.size[2] * o.scale.y, o.size[3] * o.scale.z), offset = vec(0, 0, 0)}
    end
    m.getBoundsNormalized = function()
        return {center = vec(o.pos.x, o.pos.y, o.pos.z), size = vec(o.size[1] * o.scale.x, o.size[2] * o.scale.y, o.size[3] * o.scale.z), offset = vec(0, 0, 0)}
    end
    m.positionToWorld = function(p)
        p = V(p)
        local x, z = rotY(o.rot.y, p.x * o.scale.x, p.z * o.scale.z)
        return vec(o.pos.x + x, o.pos.y + p.y * o.scale.y, o.pos.z + z)
    end
    m.positionToLocal = function(p)
        p = V(p)
        local x, z = rotY(-o.rot.y, p.x - o.pos.x, p.z - o.pos.z)
        return vec(x / o.scale.x, (p.y - o.pos.y) / o.scale.y, z / o.scale.z)
    end
    m.addTag = function(t) o.tags[t] = true; return true end
    m.removeTag = function(t) o.tags[t] = nil; return true end
    m.hasTag = function(t) return o.tags[t] == true end
    m.getTags = function() local r = {} for t in pairs(o.tags) do r[#r + 1] = t end return r end
    m.createButton = function(p)
        if o.destroyed then error("createButton on destroyed object", 2) end
        if type(p) ~= "table" or type(p.click_function) ~= "string" then error("createButton needs click_function string", 2) end
        if p.function_owner == nil then error("createButton needs function_owner", 2) end
        local b = {}
        for k, v in pairs(p) do b[k] = v end
        b.index = #o.buttons
        o.buttons[#o.buttons + 1] = b
        return true
    end
    m.editButton = function(p)
        local b = type(p) == "table" and type(p.index) == "number" and o.buttons[p.index + 1]
        if not b then error("editButton: no button at index " .. tostring(p and p.index), 2) end
        for k, v in pairs(p) do if k ~= "index" then b[k] = v end end
        return true
    end
    m.removeButton = function(i)
        if not o.buttons[i + 1] then error("removeButton: bad index " .. tostring(i), 2) end
        table.remove(o.buttons, i + 1)
        for j, b in ipairs(o.buttons) do b.index = j - 1 end
        return true
    end
    m.clearButtons = function() o.buttons = {}; return true end
    m.getButtons = function()
        if #o.buttons == 0 then return nil end
        local r = {}
        for i, b in ipairs(o.buttons) do local c = {} for k, v in pairs(b) do c[k] = v end r[i] = c end
        return r
    end
    m.setDecals = function(list)
        if type(list) ~= "table" then error("setDecals: table expected", 2) end
        for i, d in ipairs(list) do
            if type(d.name) ~= "string" or type(d.url) ~= "string" then error("setDecals: decal " .. i .. " needs name and url strings", 2) end
            for _, k in ipairs({"position", "rotation", "scale"}) do V(d[k]) end
        end
        checkDecals(o, list)
        o.decals = list; return true
    end
    m.getDecals = function() return o.decals end
    m.setInvisibleTo = function(list) if type(list) ~= "table" then error("setInvisibleTo: table expected", 2) end o.invisible = list; return true end
    m.setVelocity = function(v) V(v); return true end
    m.setAngularVelocity = function(v) V(v); return true end
    m.isDestroyed = function() return o.destroyed end
    m.addContextMenuItem = function(label, fn) o.ctx[#o.ctx + 1] = {label = label, fn = fn}; return true end
    m.destruct = function() o.destroyed = true; OBJECTS[o.guid] = nil
        if o.env and o.env.onDestroy then protected(o.guid .. ".onDestroy", o.env.onDestroy) end
        return true end
    m.getVar = function(n) return o.env and o.env[n] end
    m.setVar = function(n, v) if o.env then o.env[n] = v end return true end
    m.call = function(fname, params)
        if o.destroyed then error("call on destroyed object", 2) end
        if not o.env then error("Object.call: object " .. o.guid .. " has no script", 2) end
        local f = rawget(o.env, fname)
        if type(f) ~= "function" then
            fail(o.guid .. ".call", "function '" .. tostring(fname) .. "' does not exist")
            return nil
        end
        local ok, res = xpcall(function() return f(marshal(params)) end, function(e) return tostring(e) end)
        if not ok then fail(o.guid .. ".call(" .. fname .. ")", res); return nil end
        return marshal(res)
    end
    if o.effects then
        m.AssetBundle = {
            getTriggerEffects = function()
                if o.loading_custom then return nil end
                local r = {} for i, n in ipairs(o.effects) do r[i] = {index = i - 1, name = n} end return r
            end,
            playTriggerEffect = function(i) log("FX " .. o.guid .. " " .. tostring(i)); return true end,
            getLoopingEffects = function() return {} end,
            playLoopingEffect = function() return true end,
        }
    end
    setmetatable(proxy, {
        __index = function(_, k)
            if o.destroyed and k ~= "__isObject" then error("attempt to index destroyed object (" .. o.guid .. ")." .. tostring(k), 2) end
            if m[k] then return m[k] end
            if k == "spawning" then return o.spawning end
            if k == "loading_custom" then return o.loading_custom end
            if k == "memo" then return o.memo end
            if k == "held_by_color" then return o.held end
            if k == "tooltip" or k == "interactable" then return true end
            if k == "resting" then return true end
            if k == "guid" then return o.guid end
            if k == "type" then return "Generic" end
            return nil
        end,
        __newindex = function(_, k, v)
            if k == "memo" then o.memo = v elseif k == "tooltip" or k == "interactable" then o[k] = v
            else error("cannot set field " .. tostring(k) .. " on Object", 2) end
        end,
    })
    OBJECTS[o.guid] = o
    ORDER[#ORDER + 1] = o
    return o
end

function getObjectFromGUID(g)
    local o = OBJECTS[g]
    if o and not o.destroyed then return o.proxy end
    return nil
end
function getObjectsWithTag(t)
    local r = {}
    for _, o in ipairs(ORDER) do if not o.destroyed and o.tags[t] then r[#r + 1] = o.proxy end end
    return r
end
function getAllObjects() local r = {} for _, o in ipairs(ORDER) do if not o.destroyed then r[#r + 1] = o.proxy end end return r end

-- scripts
function attachScript(o, code)
    local env = setmetatable({}, {__index = function(_, k)
        local v = TTS_API[k]
        if v == nil and not MISSING[k] then MISSING[k] = o.guid; print("UNDEFINED GLOBAL READ in " .. o.guid .. ": " .. tostring(k)) end
        return v
    end})
    env._G = env
    env.self = o.proxy
    o.env = env
    local ok, err = pcall(__dostring, code, env, o.guid)
    if not ok then fail(o.guid .. " load", err) end
    return ok
end

SPAWN_FRAMES, LOAD_FRAMES = 3, 45
local spawnQueue = {}

-- v4.2 strictness. A custom object spawned with missing data makes real TTS open its import dialog;
-- a Custom Token whose image TTS can't cut a shape from fails with "[Physics.PhysX] cleaning the mesh
-- failed" and does the same. TOKEN_OK (optional, generated from the hosted manifest by
-- Tools/StrictTTS/README) lists hosted images verified as RGBA with hard alpha and a clear border.
CUSTOM_FAILS = {}
local function customFail(msg) CUSTOM_FAILS[#CUSTOM_FAILS + 1] = msg; fail("spawn", msg) end
local function https(u) return type(u) == "string" and u:sub(1, 8) == "https://" end
local function checkCustom(data)
    local n = data.Name
    if n == "Custom_Token" or n == "Custom_Tile" then
        local ci = data.CustomImage
        if type(ci) ~= "table" or not https(ci.ImageURL) then return customFail(n .. " without an https CustomImage.ImageURL") end
        if n == "Custom_Token" then
            local ct = ci.CustomToken
            if type(ct) ~= "table" or type(ct.Thickness) ~= "number" or type(ct.MergeDistancePixels) ~= "number"
                or type(ct.StandUp) ~= "boolean" or type(ct.Stackable) ~= "boolean" then
                return customFail("Custom_Token without full CustomImage.CustomToken data")
            end
            local u = ci.ImageURL
            local hosted = u:find("raw.githubusercontent.com", 1, true) and u:find("/hsbg/", 1, true)
            if TOKEN_OK and hosted and not (u:sub(1, #TOKEN_BASE) == TOKEN_BASE and TOKEN_OK[u:sub(#TOKEN_BASE + 1)]) then
                return customFail("Custom_Token image is not a verified token image (RGBA, hard alpha, clear border): " .. ci.ImageURL)
            end
        elseif type(ci.CustomTile) ~= "table" then
            return customFail("Custom_Tile without CustomImage.CustomTile data")
        end
    elseif n == "Custom_Model" then
        local cm = data.CustomMesh
        if type(cm) ~= "table" or not https(cm.MeshURL) or not https(cm.DiffuseURL) then return customFail("Custom_Model without https MeshURL/DiffuseURL") end
    elseif n == "Custom_Assetbundle" then
        local ca = data.CustomAssetbundle
        if type(ca) ~= "table" or not https(ca.AssetbundleURL) then return customFail("Custom_Assetbundle without an https AssetbundleURL") end
    end
end

-- Two custom objects spawned on the same spot (within 0.3 across, 0.1 up) is a layout bug.
local function checkOverlap(data, pos)
    if data.Name == "Custom_Assetbundle" then return end
    local p = V(pos)
    -- cards sent to a hand zone are laid out by TTS itself
    for _, c in ipairs({"White", "Brown", "Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "Grey", "Black"}) do
        local ok, t = pcall(function() return Player[c].getHandTransform(1) end)
        if ok and t and math.abs(p.x - t.position.x) <= t.scale.x / 2 and math.abs(p.z - t.position.z) <= t.scale.z / 2 then return end
    end
    for _, o in ipairs(ORDER) do
        if not o.destroyed and o.name ~= "Custom_Assetbundle" and o.name and o.name:sub(1, 7) == "Custom_" and o.spawned then
            if math.abs(o.pos.x - p.x) < 0.3 and math.abs(o.pos.z - p.z) < 0.3 and math.abs(o.pos.y - p.y) < 0.1 then
                return customFail(string.format("overlapping spawn: %s at (%.2f, %.2f, %.2f) on top of %s %s", data.Nickname or data.Name, p.x, p.y, p.z, o.guid, o.nickname or ""))
            end
        end
    end
end

-- Control art drawn on a board or the controller must not overlap (panels and badges excepted:
-- v4.3 badges, keys "b_*", are Health/Armor/cost gems drawn on the corner of their art on purpose).
DECAL_OVERLAP_OK = {panel = true, armor = true}
DECALS_SEEN = {}   -- object guid -> last decal list (for the layout previews)
function checkDecals(o, list)
    DECALS_SEEN[o.guid] = list
    if o.name ~= "Custom_Assetbundle" and o.name ~= "Custom_Model" then return end
    local rects = {}
    for _, d in ipairs(list) do
        local key = d.name:gsub("^hsbg_", "")
        if not DECAL_OVERLAP_OK[key] and key:sub(1, 2) ~= "b_" then
            local p, s = d.position, d.scale
            local px, pz = p[1] or p.x, p[3] or p.z
            local sx, sy = s[1] or s.x, s[2] or s.y
            rects[#rects + 1] = {key = key, x0 = px - sx / 2, x1 = px + sx / 2, z0 = pz - sy / 2, z1 = pz + sy / 2}
        end
    end
    for i = 1, #rects do
        for j = i + 1, #rects do
            local a, b = rects[i], rects[j]
            local ox = math.min(a.x1, b.x1) - math.max(a.x0, b.x0)
            local oz = math.min(a.z1, b.z1) - math.max(a.z0, b.z0)
            if ox > 0.02 and oz > 0.02 then
                customFail(string.format("decals overlap on %s: %s and %s (%.2f x %.2f)", o.guid, a.key, b.key, ox, oz))
            end
        end
    end
end

local function spawnFrom(data, params, kind)
    if type(params) ~= "table" then error(kind .. ": params table required", 3) end
    checkCustom(data)
    local t = data.Transform or {}
    if params.position then checkOverlap(data, params.position) end
    local isBundle = data.Name == "Custom_Assetbundle"
    local o = makeObject({type = data.Name, nickname = data.Nickname, description = data.Description,
        pos = params.position or {t.posX or 0, t.posY or 0, t.posZ or 0},
        rot = params.rotation or {t.rotX or 0, t.rotY or 0, t.rotZ or 0},
        scale = params.scale or {t.scaleX or 1, t.scaleY or 1, t.scaleZ or 1},
        tags = data.Tags, memo = data.Memo, locked = data.Locked, spawning = true, loading = true,
        size = isBundle and {28, 0.2, 24} or {2, 0.1, 2.8},
        effects = isBundle and {"normal_board", "combat_open", "victory", "defeat"} or nil})
    o.data = data
    o.spawned = true
    spawnQueue[#spawnQueue + 1] = {o = o, at = FRAME + SPAWN_FRAMES, loadAt = FRAME + (isBundle and LOAD_FRAMES or 6),
        cb = params.callback_function, script = data.LuaScript, state = data.LuaScriptState}
    return o.proxy
end
function spawnObjectData(p) if type(p) ~= "table" or type(p.data) ~= "table" then error("spawnObjectData: data table required", 2) end return spawnFrom(p.data, p, "spawnObjectData") end
function spawnObjectJSON(p)
    if type(p) ~= "table" or type(p.json) ~= "string" then error("spawnObjectJSON: json string required", 2) end
    return spawnFrom(JSON.decode(p.json), p, "spawnObjectJSON")
end

-- Wait
local waits, waitId = {}, 0
Wait = {}
local function addWait(w) waitId = waitId + 1; w.id = waitId; waits[waitId] = w; return waitId end
function Wait.frames(fn, n) if type(fn) ~= "function" then error("Wait.frames: function expected", 2) end return addWait({kind = "f", fn = fn, at = FRAME + (n or 1)}) end
function Wait.time(fn, s, reps) if type(fn) ~= "function" then error("Wait.time: function expected", 2) end return addWait({kind = "t", fn = fn, at = TIME + s, every = s, reps = reps or 1}) end
function Wait.condition(fn, cond, timeout, tofn)
    if type(fn) ~= "function" or type(cond) ~= "function" then error("Wait.condition: functions expected", 2) end
    return addWait({kind = "c", fn = fn, cond = cond, deadline = timeout and (TIME + timeout), tofn = tofn})
end
function Wait.stop(id) if type(id) ~= "number" then error("Wait.stop: id expected, got " .. type(id), 2) end waits[id] = nil; return true end
function Wait.stopAll() waits = {} end

function step()
    FRAME = FRAME + 1; TIME = TIME + 1 / 60
    for i = #spawnQueue, 1, -1 do
        local s = spawnQueue[i]
        if FRAME >= s.at and s.o.spawning then
            s.o.spawning = false
            if s.script and s.script ~= "" then
                if attachScript(s.o, s.script) and s.o.env.onLoad then protected(s.o.guid .. ".onLoad", s.o.env.onLoad, s.state or "") end
            end
        end
        if FRAME >= s.loadAt then
            s.o.loading_custom = false
            table.remove(spawnQueue, i)
            if s.cb and not s.o.destroyed then protected("spawn callback " .. s.o.guid, s.cb, s.o.proxy) end
        end
    end
    local ids = {}
    for id in pairs(waits) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local w = waits[id]
        if w then
            if w.kind == "f" and FRAME >= w.at then waits[id] = nil; protected("Wait.frames#" .. id, w.fn)
            elseif w.kind == "t" and TIME >= w.at then
                w.reps = w.reps - 1
                if w.reps == 0 then waits[id] = nil else w.at = TIME + w.every end
                protected("Wait.time#" .. id, w.fn)
            elseif w.kind == "c" then
                local ok, r = protected("Wait.condition cond#" .. id, w.cond)
                if not ok then waits[id] = nil
                elseif r then waits[id] = nil; protected("Wait.condition#" .. id, w.fn)
                elseif w.deadline and TIME >= w.deadline then waits[id] = nil; if w.tofn then protected("Wait.condition timeout#" .. id, w.tofn) end end
            end
        end
    end
end
function pump(seconds) for _ = 1, math.floor(seconds * 60) do step() end end

-- Players
local PlayerMT = {}
Player = setmetatable({}, PlayerMT)
local players = {}
local COLORS = {"White", "Brown", "Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "Grey", "Black"}
for _, c in ipairs(COLORS) do
    players[c] = {color = c, seated = false, host = false, steam_name = nil, admin = false, promoted = false,
        print = function(msg) log("PRINT->" .. c .. ": " .. tostring(msg)) end,
        broadcast = function(msg) log("BROADCAST->" .. c .. ": " .. tostring(msg)) end,
        hand = {},
        getHandObjects = function() local r = {} for _, x in ipairs(players[c].hand) do if getObjectFromGUID(x.getGUID()) then r[#r + 1] = x end end return r end,
        getHandCount = function() return 1 end,
        getHandTransform = function() return {position = vec(0, 3, -30), rotation = vec(0, 0, 0), scale = vec(12, 5, 2), forward = vec(0, 0, 1), right = vec(1, 0, 0), up = vec(0, 1, 0)} end,
        getSelectedObjects = function() return {} end,
        pointer = nil,
        getPointerPosition = function() return players[c].pointer end,
        hover = nil,   -- v4.6: guid of the object under the pointer (scenarios set it)
        getHoverObject = function() return players[c].hover and getObjectFromGUID(players[c].hover) or nil end,
    }
end
PlayerMT.__index = function(_, k)
    if players[k] then return players[k] end
    if k == "getPlayers" then return function() local r = {} for _, p in pairs(players) do if p.seated then r[#r + 1] = p end end return r end end
    if k == "getColors" then return function() return COLORS end end
    return nil
end
function seatPlayer(c, host, name) players[c].seated = true; players[c].host = host or false; players[c].steam_name = name or ("Player " .. c) end

function broadcastToAll(msg) log("BROADCAST: " .. tostring(msg)) end
function printToAll(msg) log("PRINTALL: " .. tostring(msg)) end
local rawprint = print
print = function(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end log("PRINT: " .. table.concat(t, " ")) end
_LOG = function(s) LOG[#LOG + 1] = s; rawprint(s) end
log = _LOG

-- Global XML UI: ids come from the save's XmlUI (UI_IDS, written by gen_setup.py); unknown ids are errors.
UISTATE = {}
local function uiCheck(id, where)
    if type(id) ~= "string" then error(where .. ": id must be a string", 3) end
    if UI_IDS and not UI_IDS[id] then error(where .. ": no XML element with id '" .. id .. "'", 3) end
    UISTATE[id] = UISTATE[id] or {}
    return UISTATE[id]
end
UI = {
    setAttribute = function(id, attr, value)
        local e = uiCheck(id, "UI.setAttribute")
        if type(attr) ~= "string" then error("UI.setAttribute: attribute name must be a string", 2) end
        if type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then error("UI.setAttribute: bad value type " .. type(value), 2) end
        e[attr] = tostring(value); return true
    end,
    getAttribute = function(id, attr) return uiCheck(id, "UI.getAttribute")[attr] end,
    setValue = function(id, value) uiCheck(id, "UI.setValue").text = tostring(value); return true end,
    getValue = function(id) return uiCheck(id, "UI.getValue").text end,
    show = function(id) uiCheck(id, "UI.show").active = "true"; return true end,
    hide = function(id) uiCheck(id, "UI.hide").active = "false"; return true end,
}
function uiEvent(guid, fname, color, value, id)
    local o = OBJECTS[guid]
    local f = o and o.env and rawget(o.env, fname)
    log(">>> UI " .. color .. " " .. fname .. "(" .. tostring(value) .. ", " .. tostring(id) .. ")")
    if type(f) ~= "function" then fail("ui", "UI handler " .. fname .. " missing on " .. guid); return end
    if UI_IDS and not UI_IDS[id] then fail("ui", "event from unknown id " .. tostring(id)) end
    protected("ui " .. fname, f, players[color], value, id)
end
function uiActive(id) return UISTATE[id] and UISTATE[id].active == "true" end

GLOBALVARS = {mtBusy = false}
Global = {getVar = function(n) return GLOBALVARS[n] end, setVar = function(n, v) GLOBALVARS[n] = v end,
    call = function() return nil end, __isObject = true}

function click(guid, pattern, color, alt)
    local o = OBJECTS[guid]
    if not o then error("click: no object " .. guid) end
    for _, b in ipairs(o.buttons) do
        if tostring(b.label):find(pattern) or b.click_function == pattern then
            local owner = b.function_owner
            local ownerObj = OBJECTS[owner.getGUID()]
            local f = ownerObj.env and rawget(ownerObj.env, b.click_function)
            log(">>> " .. color .. " clicks '" .. tostring(b.label):gsub("\n", " / ") .. "' (" .. b.click_function .. ") on " .. guid)
            if type(f) ~= "function" then fail("click", "click_function " .. b.click_function .. " missing on " .. owner.getGUID()); return end
            protected("click " .. b.click_function, f, o.proxy, color, alt or false)
            return true
        end
    end
    fail("click", "no button matching " .. pattern .. " on " .. guid)
end
function buttons(guid)
    local o = OBJECTS[guid]
    local r = {}
    for _, b in ipairs(o and o.buttons or {}) do r[#r + 1] = b.click_function .. "=" .. tostring(b.label):gsub("\n", " / "):sub(1, 50) end
    return table.concat(r, " | ")
end

MISSING = {}
TTS_API = {}
for _, k in ipairs({"string","table","math","bit32","coroutine","pairs","ipairs","next","type","tostring","tonumber","select",
    "error","assert","pcall","xpcall","rawget","rawset","rawequal","setmetatable","getmetatable","unpack","print","_VERSION",
    "JSON","Vector","Color","Wait","Player","Global","getObjectFromGUID","getObjectsWithTag","getAllObjects",
    "spawnObjectData","spawnObjectJSON","broadcastToAll","printToAll","UI"}) do TTS_API[k] = _G[k] end
TTS_API.os = {time = os.time, clock = os.clock, date = os.date, difftime = os.difftime}
TTS_API.log = function(...) print(...) end
TTS_API.BG_STRICT_TABLES = STRICT_SOAK
