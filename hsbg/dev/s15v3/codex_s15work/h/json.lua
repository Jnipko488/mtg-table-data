JSON = {}
local function esc(s) return (s:gsub('[%c"\\]', function(c)
    local m = {['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'}
    return m[c] or string.format("\\u%04x", c:byte()) end)) end
local function enc(v, out)
    local t = type(v)
    if t == "nil" then out[#out + 1] = "null"
    elseif t == "boolean" then out[#out + 1] = tostring(v)
    elseif t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = "0"
        elseif v == math.floor(v) and math.abs(v) < 1e15 then out[#out + 1] = string.format("%d", v)
        else out[#out + 1] = string.format("%.14g", v) end
    elseif t == "string" then out[#out + 1] = '"' .. esc(v) .. '"'
    elseif t == "table" then
        local n = #v
        local isArr = n > 0 or next(v) == nil
        if isArr then for k in pairs(v) do if type(k) ~= "number" or k < 1 or k > n or k ~= math.floor(k) then isArr = false break end end end
        if isArr then
            out[#out + 1] = "["
            for i = 1, n do if i > 1 then out[#out + 1] = "," end enc(v[i], out) end
            out[#out + 1] = "]"
        else
            out[#out + 1] = "{"
            local first = true
            for k, x in pairs(v) do
                if type(x) ~= "function" then
                    if not first then out[#out + 1] = "," end
                    first = false
                    out[#out + 1] = '"' .. esc(tostring(k)) .. '":'
                    enc(x, out)
                end
            end
            out[#out + 1] = "}"
        end
    elseif t == "function" then out[#out + 1] = "null"
    else error("JSON.encode: cannot encode " .. t) end
end
function JSON.encode(v) local out = {} enc(v, out) return table.concat(out) end
function JSON.decode(s)
    if type(s) ~= "string" then error("JSON.decode: string expected") end
    local i = 1
    local function ws() i = s:find("[^ \t\r\n]", i) or #s + 1 end
    local val
    local function str()
        i = i + 1
        local buf = {}
        while true do
            local c = s:sub(i, i)
            if c == "" then error("JSON: unterminated string") end
            if c == '"' then i = i + 1 break end
            if c == "\\" then
                local n = s:sub(i + 1, i + 1)
                local map = {n = "\n", r = "\r", t = "\t", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/"}
                if n == "u" then
                    local code = tonumber(s:sub(i + 2, i + 5), 16)
                    buf[#buf + 1] = code < 128 and string.char(code) or "?"
                    i = i + 6
                else buf[#buf + 1] = map[n] or n; i = i + 2 end
            else buf[#buf + 1] = c; i = i + 1 end
        end
        return table.concat(buf)
    end
    val = function()
        ws()
        local c = s:sub(i, i)
        if c == "{" then
            i = i + 1; local t = {}
            ws(); if s:sub(i, i) == "}" then i = i + 1 return t end
            while true do
                ws(); local k = str(); ws()
                if s:sub(i, i) ~= ":" then error("JSON: ':' expected at " .. i) end
                i = i + 1; t[k] = val(); ws()
                local d = s:sub(i, i); i = i + 1
                if d == "}" then return t elseif d ~= "," then error("JSON: ',' expected at " .. i) end
            end
        elseif c == "[" then
            i = i + 1; local t = {}
            ws(); if s:sub(i, i) == "]" then i = i + 1 return t end
            while true do
                t[#t + 1] = val(); ws()
                local d = s:sub(i, i); i = i + 1
                if d == "]" then return t elseif d ~= "," then error("JSON: ',' expected at " .. i) end
            end
        elseif c == '"' then return str()
        elseif s:sub(i, i + 3) == "true" then i = i + 4 return true
        elseif s:sub(i, i + 4) == "false" then i = i + 5 return false
        elseif s:sub(i, i + 3) == "null" then i = i + 4 return nil
        else
            local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
            if not num or num == "" then error("JSON: bad value at " .. i) end
            i = i + #num
            return tonumber(num)
        end
    end
    return val()
end
