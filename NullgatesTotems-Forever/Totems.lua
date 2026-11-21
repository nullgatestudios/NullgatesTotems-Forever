-- Nullgate's Totems: totem and imbue choices, ranks, the Drop All macro and the warning rules.
-- No game calls except through Totems.IsKnown, which the tests replace.
local _, ns = ...

local Totems = {}
ns.Totems = Totems

Totems.ELEMENTS = { "earth", "fire", "water", "air" }
Totems.SLOT = { fire = 1, earth = 2, water = 3, air = 4 } -- GetTotemInfo slots

function Totems.IsKnown(spellID)
    local known = (C_SpellBook and C_SpellBook.IsSpellKnown) or IsSpellKnown or IsPlayerSpell
    return known ~= nil and known(spellID) == true
end

-- The highest rank of a totem or imbue the player knows, or nil.
function Totems.BestRank(entry)
    local best
    for _, rank in ipairs(entry and entry.ranks or {}) do
        if Totems.IsKnown(rank[1]) then best = rank[1] end
    end
    return best
end

function Totems.Find(element, key)
    for _, totem in ipairs(ns.TOTEMS[element] or {}) do
        if totem.key == key then return totem end
    end
end

-- Every totem of an element the player knows, in data order.
function Totems.KnownList(element)
    local list = {}
    for _, totem in ipairs(ns.TOTEMS[element] or {}) do
        if Totems.BestRank(totem) then list[#list + 1] = totem end
    end
    return list
end

-- The chosen totem of an element when it's known, otherwise the first one known (or nil).
function Totems.Chosen(element, key)
    local totem = Totems.Find(element, key)
    if totem and Totems.BestRank(totem) then return totem end
    return Totems.KnownList(element)[1]
end

function Totems.FindImbue(key)
    for _, imbue in ipairs(ns.IMBUES) do
        if imbue.key == key then return imbue end
    end
end

-- The chosen imbue when known, otherwise the best one known (the last learned).
function Totems.ChosenImbue(key)
    local imbue = Totems.FindImbue(key)
    if imbue and Totems.BestRank(imbue) then return imbue end
    local best
    for _, entry in ipairs(ns.IMBUES) do
        if Totems.BestRank(entry) then best = entry end
    end
    return best
end

-- The Drop All macro: one totem per press, restarting after 8 seconds or when combat ends.
-- names: the chosen totems' spell names in element order (nil entries are skipped).
function Totems.DropAllMacro(names)
    local list = {}
    for _, element in ipairs(Totems.ELEMENTS) do
        if names[element] then list[#list + 1] = names[element] end
    end
    if #list == 0 then return nil end
    return "/castsequence reset=combat/8 " .. table.concat(list, ", ")
end

-- Seconds left on a totem (0 when gone).
function Totems.Remaining(start, duration, now)
    if not start or not duration or duration <= 0 then return 0 end
    return math.max(0, start + duration - now)
end

-- 272 -> "4:32"; 9 -> "9".
function Totems.Clock(seconds)
    seconds = math.floor(seconds + 0.5)
    if seconds >= 60 then return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) end
    return tostring(seconds)
end

-- --- Warning rules -------------------------------------------------------------------

-- A totem is about to expire: warn once per drop when it gets to warnAt seconds.
function Totems.ShouldWarnExpiring(remaining, warnAt, alreadyWarned)
    return warnAt > 0 and remaining > 0 and remaining <= warnAt and not alreadyWarned
end

-- A totem vanished: it was destroyed when it still had more than two seconds to go.
function Totems.WasDestroyed(remainingBefore)
    return remainingBefore ~= nil and remainingBefore > 2
end

-- Out of range: a buff totem has been down for `grace` seconds while you don't have its buff.
function Totems.OutOfRange(hasBuff, sinceDropped, grace)
    return not hasBuff and sinceDropped >= grace
end
