
    -- Season 15 Tavern spell numbers. Edit a number here and both the card text and the
    -- effect change; spell power is added on top of a/h (see E.spellAmount).
    E.S15_SPELLS = {
        S15S_goldrinns_blessing = {text = "Your Beasts have +{a}/+{h} this game (wherever they are).", a = 1, h = 1},
        S15S_invocation_earth = {text = "Give a minion +{a}/+{h}. If it's an Elemental, also give it Taunt until next turn.", a = 3, h = 3, kw = "taunt"},
        S15S_invocation_fire = {text = "Give a minion +{a}/+{h}. If it's an Elemental, also give it Reborn until next turn.", a = 4, h = 4, kw = "reborn"},
        S15S_invocation_air = {text = "Give a minion +{a}/+{h}. If it's an Elemental, also give it Windfury until next turn.", a = 5, h = 5, kw = "windfury"},
        S15S_invocation_water = {text = "Give a minion +{a}/+{h}. If it's an Elemental, also give it Divine Shield until next turn.", a = 6, h = 6, kw = "shield"},
        S15S_dragonstorm = {text = "Give your Dragons \"At the end of your turn, gain +{a}/+{h}.\"", a = 2, h = 2},
        S15S_echoing_roar = {text = "Give a friendly minion \"At the end of your turn, gain +{a}/+{h}.\"", a = 3, h = 3},
        S15S_sanctify = {text = "Give your minions with Divine Shield +{a} Attack.", a = 4, h = 0},
    }
    for id, t in pairs(E.S15_SPELLS) do E.setSpellText(id, t) end
    local function s15Spell(id) return E.S15_SPELLS[id] end
    for _, id in ipairs(INV) do
        E.SPELLS[id].cast = function(g, p, m)
            if not m then return false, "Choose a friendly minion." end
            local t = s15Spell(id)
            buffSpell(p, m, t.a, t.h)
            if t.kw and hasRace(m, "ELEMENTAL") then E.tempBuff(m, 0, 0, t.kw) end
            return true
        end
    end
    E.SPELLS.S15S_goldrinns_blessing.cast = function(g, p)
        local t = s15Spell("S15S_goldrinns_blessing")
        E.beastAura(p, E.spellAmount(p, t.a, t.h))
        return true
    end
    -- Dragonstorm and Echoing Roar keep the spell power they were cast with.
    local function growth(m, id, a, h)
        m.attachments = m.attachments or {}
        m.magnetizedCount = m.magnetizedCount or #m.attachments
        table.insert(m.attachments, {id = id, atk = 0, hp = 0, enchant = true, s15a = a, s15h = h})
    end
    local function growthTrigger(spellId)
        return function(g, p, m, k, part)
            local t = s15Spell(spellId)
            k = k or 1
            buff(m, (part and part.s15a or t.a) * k, (part and part.s15h or t.h) * k)
        end
    end
    FX["S15E_dragonstorm"] = {endTurn = growthTrigger("S15S_dragonstorm")}
    FX["S15E_echo"] = {endTurn = growthTrigger("S15S_echoing_roar")}
    function E.castDragonstorm(p)
        local t = s15Spell("S15S_dragonstorm")
        local a, h = E.spellAmount(p, t.a, t.h)
        for _, m in ipairs(p.board) do if hasRace(m, "DRAGON") then growth(m, "S15E_dragonstorm", a, h) end end
    end
    E.SPELLS.S15S_echoing_roar.cast = function(g, p, m)
        if not m then return false, "Choose a minion." end
        local t = s15Spell("S15S_echoing_roar")
        local a, h = E.spellAmount(p, t.a, t.h)
        growth(m, "S15E_echo", a, h)
        return true
    end
    function E.castSanctify(p)
        local t = s15Spell("S15S_sanctify")
        for _, m in ipairs(p.board) do if m.shield then buffSpell(p, m, t.a, t.h) end end
    end
    -- Season 15 Tavern spell rotation: the 9 new spells (all four Invocations and Command
    -- the Elements included, as the patch notes list them with a Tier and Cost) plus the
    -- returning Pointy Arrow and Deepwater Clan (now Tier 4).
    E.SPELLS.S15S_command_elements.tavern = true
    if E.SPELLS.BG35_149 then E.SPELLS.BG35_149.tier = 4 end
    for _, id in ipairs({"S15S_invocation_earth", "S15S_invocation_fire", "S15S_invocation_air",
        "S15S_invocation_water", "S15S_command_elements", "EBG_Spell_014", "BG35_149"}) do
        if E.SPELLS[id] then E.seasonSpells.s15[id] = true end
    end
