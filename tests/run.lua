-- Nullgate's Totems: tests for the totem data, choices, the Drop All macro and the warning rules.
-- Run from the repository root:  lua tests/run.lua   (Lua 5.1 or newer)

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/run.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local root = (scriptDir:match("^(.*)[/\\][^/\\]*$") or ".") .. "/NullgatesTotems-Forever/"

local ns = {}
local function Load(file) assert(loadfile(root .. file), "cannot load " .. file)("NullgatesTotems-Forever", ns) end
Load("Data/Totems.lua")
Load("Totems.lua")
local T = ns.Totems

local checks, failures = 0, 0
local function EQ(got, want, name)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: expected %s, got %s", name, tostring(want), tostring(got)))
    end
end

-- --- The data ---------------------------------------------------------------------
EQ(type(ns.TOTEM_DATA_BUILD), "string", "the data names its client build")
for _, element in ipairs(T.ELEMENTS) do
    EQ(#ns.TOTEMS[element] >= 4, true, element .. ": at least four totems")
    for _, totem in ipairs(ns.TOTEMS[element]) do
        EQ(#totem.ranks >= 1 and totem.duration > 0, true, totem.name .. " is complete")
    end
end
EQ(T.Find("earth", "strengthofearth").duration, 300, "Forever: Strength of Earth lasts 5 minutes")
EQ(T.Find("water", "manaspring").duration, 300, "Forever: Mana Spring lasts 5 minutes")
EQ(T.Find("earth", "earthbind").buffSpell, 0, "Earthbind puts no buff on the party")
EQ(T.Find("air", "graceofair").buffSpell > 0, true, "Grace of Air does")
EQ(T.Find("fire", "frostresistance") ~= nil, true, "Frost Resistance is a Fire totem")
EQ(T.Find("water", "fireresistance") ~= nil, true, "Fire Resistance is a Water totem")
EQ(#ns.IMBUES, 4, "four weapon imbues")

-- --- Choices --------------------------------------------------------------------------
local known = {}
T.IsKnown = function(id) return known[id] == true end
EQ(T.Chosen("earth", "strengthofearth"), nil, "nothing known: nothing chosen")
local soe = T.Find("earth", "strengthofearth")
local stoneskin = T.Find("earth", "stoneskin")
known[stoneskin.ranks[1][1]], known[stoneskin.ranks[2][1]] = true, true
EQ(T.Chosen("earth", "strengthofearth"), stoneskin, "the chosen totem isn't known: the first known one")
known[soe.ranks[1][1]], known[soe.ranks[2][1]], known[soe.ranks[3][1]] = true, true, true
EQ(T.Chosen("earth", "strengthofearth"), soe, "once known, the chosen one")
EQ(T.BestRank(soe), soe.ranks[3][1], "at the highest rank known")
EQ(#T.KnownList("earth"), 2, "two Earth totems known")
known[ns.IMBUES[1].ranks[1][1]] = true -- Rockbiter
known[ns.IMBUES[2].ranks[1][1]] = true -- Flametongue
EQ(T.ChosenImbue("windfury").key, "flametongue", "Windfury not known: the best imbue known (the last learned)")
EQ(T.ChosenImbue("rockbiter").key, "rockbiter", "a known choice is kept")

-- --- Drop All ---------------------------------------------------------------------------
EQ(T.DropAllMacro({ earth = "Strength of Earth Totem", water = "Mana Spring Totem", air = "Grace of Air Totem" }),
    "/castsequence reset=combat/8 Strength of Earth Totem, Mana Spring Totem, Grace of Air Totem",
    "Drop All: the chosen totems in element order, skipping an element with none")
EQ(T.DropAllMacro({}), nil, "nothing known: no macro")

-- --- Timers and warnings ----------------------------------------------------------------
EQ(T.Remaining(100, 300, 160), 240, "4 minutes left")
EQ(T.Remaining(100, 300, 500), 0, "gone")
EQ(T.Clock(272), "4:32", "minutes and seconds")
EQ(T.Clock(9.4), "9", "seconds")
EQ(T.ShouldWarnExpiring(8, 10, false), true, "10 seconds to go: warn")
EQ(T.ShouldWarnExpiring(8, 10, true), false, "once per drop")
EQ(T.ShouldWarnExpiring(40, 10, false), false, "not yet")
EQ(T.ShouldWarnExpiring(8, 0, false), false, "off")
EQ(T.WasDestroyed(120), true, "vanished with two minutes left: destroyed")
EQ(T.WasDestroyed(1), false, "vanished at the end: expired")
EQ(T.WasDestroyed(nil), false, "no totem before")
EQ(T.OutOfRange(false, 5, 3), true, "no buff five seconds after dropping: out of range")
EQ(T.OutOfRange(false, 1, 3), false, "but give it a moment after dropping")
EQ(T.OutOfRange(true, 60, 3), false, "buff present: in range")

print(string.format("%d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
