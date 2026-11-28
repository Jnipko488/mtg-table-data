function E.spellPower(p, entry)
    if not p then return 0, 0, 0 end
    local a, h = E.spellBonuses(p)
    local extra = entry and entry.s15StatBonus or p.s15SpellStatBonus or 0
    return a, h, extra
end

-- Spell power raises a stat the spell already gives. A per-card bonus (Squirky)
-- always adds +X/+X on top, even to a spell that gives only Attack or only Health.
function E.spellAmount(p, a, h, entry)
    local extraAttack, extraHealth, extra = E.spellPower(p, entry)
    if a <= 0 and h <= 0 then return a, h end
    if a > 0 then a = a + extraAttack end
    if h > 0 then h = h + extraHealth end
    return a + extra, h + extra
end

local function buffSpell(p, m, a, h)
    a, h = E.spellAmount(p, a, h)
    buff(m, a, h)
end

function E.spellScales(id)
    local s = spells[id]
    if not s or E.SPELL_POWER_EXEMPT[id] or s.spellcraft or s.timewarp then return false end
    if E.SPELL_TEXT[id] then return true end
    if (s.text or ""):find("spells give") then return false end
    return (s.pool or s.tavern or s.s15Invocation or not s.generated) and true or false
end

local function boosted(n, extra)
    n = tonumber(n) or 0
    if n > 0 then return n + extra end
    return n
end

-- "+5 Attack" becomes "+5/+3" when a per-card bonus of 3 is on the spell.
local function withExtra(text, e)
    if not e or e <= 0 then return text end
    local out = text:gsub("%+(%d+) Attack and %+(%d+) Health", "\1%1\2%2\3")
    out = out:gsub("%+(%d+) Attack", function(x) return "+" .. x .. "/+" .. e end)
    out = out:gsub("%+(%d+) Health", function(x) return "+" .. e .. "/+" .. x end)
    return (out:gsub("\1(%d+)\2(%d+)\3", "+%1 Attack and +%2 Health"))
end

function E.renderSpellTemplate(t, a, h, e)
    e = e or 0
    local text = ((t.text or ""):gsub("{(%a):?(%d*)}", function(kind, n)
        local base = n ~= "" and tonumber(n) or t[kind] or 0
        if kind == "a" then
            if base <= 0 then return tostring(base) end
            return tostring(base + (a or 0) + e)
        end
        if kind == "h" then
            if base <= 0 then return tostring(base) end
            return tostring(base + (h or 0) + e)
        end
        return tostring(base)
    end))
    return withExtra(text, e)
end

function E.spellText(p, id, entry)
    local s, t = spells[id], E.SPELL_TEXT[id]
    if not s then return nil end
    local a, h, e = 0, 0, 0
    if p and E.SPELL_POWER_TEXT and E.spellScales(id) then a, h, e = E.spellPower(p, entry) end
    if t then return E.renderSpellTemplate(t, a, h, e) end
    local text = s.text or ""
    if a == 0 and h == 0 and e == 0 then return text end
    text = text:gsub("%+(%d+)/%+(%d+)", function(x, y) return "+" .. boosted(x, a + e) .. "/+" .. boosted(y, h + e) end)
    text = text:gsub("%+(%d+) Attack", function(x) return "+" .. boosted(x, a + e) .. " Attack" end)
    text = text:gsub("%+(%d+) Health", function(x) return "+" .. boosted(x, h + e) .. " Health" end)
    return withExtra(text, e)
end

