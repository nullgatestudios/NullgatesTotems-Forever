-- Nullgate's Totems: reading buffs, party members, active totems and the weapon imbue.
local _, ns = ...

local Units = {}
ns.Units = Units

function Units.SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return GetSpellInfo and (GetSpellInfo(spellID)) or nil
end

-- Whether a unit has a helpful aura with this name.
function Units.HasBuff(unit, name)
    if not name then return false end
    for i = 1, 40 do
        local auraName
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not aura then return false end
            auraName = aura.name
        else
            auraName = UnitBuff(unit, i)
            if not auraName then return false end
        end
        -- Forever can hide aura names from addons (secret values); those can't be compared.
        if auraName and not (issecretvalue and issecretvalue(auraName)) and auraName == name then return true end
    end
    return false
end

-- You and your party members: { unit = "player" | "partyN" }.
function Units.Party()
    local list = { "player" }
    if not IsInRaid() then
        for i = 1, GetNumSubgroupMembers() do list[#list + 1] = "party" .. i end
    end
    return list
end

-- How a party member stands for a buff totem: "yes", "no" or "far" (out of range, dead or offline,
-- so the buff can't be checked fairly).
function Units.BuffState(unit, buffName)
    if Units.HasBuff(unit, buffName) then return "yes" end
    if unit ~= "player" then
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return "far" end
        -- Forever can return the range as secret values, which can't be tested: then it's unknown.
        local inRange, checked = UnitInRange(unit)
        local secret = issecretvalue and (issecretvalue(inRange) or issecretvalue(checked))
        if not secret and checked and not inRange then return "far" end
    end
    return "no"
end

-- The active totem in an element's slot: name, start, duration, or nil.
function Units.Totem(element)
    if not GetTotemInfo then return nil end
    local have, name, start, duration = GetTotemInfo(ns.Totems.SLOT[element])
    if have and name and name ~= "" and duration and duration > 0 then return name, start, duration end
end

-- The main-hand imbue: has it, and seconds left.
function Units.Imbue()
    local has, expiration = GetWeaponEnchantInfo()
    return has and true or false, math.floor((expiration or 0) / 1000)
end
