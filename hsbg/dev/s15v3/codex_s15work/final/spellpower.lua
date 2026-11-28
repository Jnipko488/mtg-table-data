-- ===== Spell power (Season 15) ===========================================
-- A Tavern spell's numbers have one source. Its effect and its card text both
-- go through E.spellAmount, so the number the text shows is the number it gives.
--   E.spellPower(p, entry)        -> extra Attack, extra Health for this player
--                                    (spell auras, trinkets, bonuses on that card such as Squirky)
--   E.spellAmount(p, a, h, entry) -> a and h after spell power (a 0 stays 0)
--   E.SPELL_TEXT[id]              -> editable text template for one spell, e.g.
--       {text = "Give a minion +{a}/+{h}.", a = 3, h = 3}
--       {a} and {h} are the template's a/h plus spell power, {a:N} and {h:N} are N plus
--       spell power, and {n:N} is N with no bonus. E.setSpellText(id, template) swaps one in.
--   Spells without a template get every "+X/+Y", "+X Attack" and "+X Health" in their
--   printed text raised by spell power. E.SPELL_POWER_EXEMPT lists spells left alone.
E.SPELL_TEXT = E.SPELL_TEXT or {}
E.SPELL_POWER_TEXT = true
E.SPELL_POWER_EXEMPT = {BG20_GEM = true, BG34_689 = true}

function E.spellPower(p, entry)
    if not p then return 0, 0 end
    local a, h = E.spellBonuses(p)
    local extra = entry and entry.s15StatBonus or p.s15SpellStatBonus or 0
    return a + extra, h + extra
end

function E.spellAmount(p, a, h, entry)
    local extraAttack, extraHealth = E.spellPower(p, entry)
    if a > 0 then a = a + extraAttack end
    if h > 0 then h = h + extraHealth end
    return a, h
end

local function buffSpell(p, m, a, h)
    a, h = E.spellAmount(p, a, h)
    buff(m, a, h)
end

function E.spellScales(id)
    local s = spells[id]
    if not s or E.SPELL_POWER_EXEMPT[id] or s.spellcraft or s.timewarp then return false end
    if id:find("^BG31_HERO_80%dpt") then return false end -- Battlecruiser Upgrades are hero cards, not Tavern spells
    if E.SPELL_TEXT[id] then return true end
    if (s.text or ""):find("spells give") then return false end
    return (s.pool or s.tavern or s.s15Invocation or not s.generated) and true or false
end

local function boosted(n, extra)
    n = tonumber(n) or 0
    if n > 0 then return n + extra end
    return n
end

function E.renderSpellTemplate(t, a, h)
    return ((t.text or ""):gsub("{(%a):?(%d*)}", function(kind, n)
        local base = n ~= "" and tonumber(n) or t[kind] or 0
        if kind == "a" then return tostring(boosted(base, a or 0)) end
        if kind == "h" then return tostring(boosted(base, h or 0)) end
        return tostring(base)
    end))
end

function E.spellText(p, id, entry)
    local s, t = spells[id], E.SPELL_TEXT[id]
    if not s then return nil end
    local a, h = 0, 0
    if p and E.SPELL_POWER_TEXT and E.spellScales(id) then a, h = E.spellPower(p, entry) end
    if t then return E.renderSpellTemplate(t, a, h) end
    local text = s.text or ""
    if a == 0 and h == 0 then return text end
    text = text:gsub("%+(%d+)/%+(%d+)", function(x, y) return "+" .. boosted(x, a) .. "/+" .. boosted(y, h) end)
    text = text:gsub("%+(%d+) Attack", function(x) return "+" .. boosted(x, a) .. " Attack" end)
    text = text:gsub("%+(%d+) Health", function(x) return "+" .. boosted(x, h) .. " Health" end)
    return text
end

function E.setSpellText(id, template)
    E.SPELL_TEXT[id] = template
    local s = spells[id] or metadata[id]
    if s then s.text = E.renderSpellTemplate(template, 0, 0) end
end
