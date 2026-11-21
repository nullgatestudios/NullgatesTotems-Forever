-- Nullgate's Totems: saved data, events, totem sets, the out-of-combat queue and slash commands.
local addonName, ns = ...

local L = ns.L

ns.DEFAULTS = {
    locked = false,
    vertical = false,
    scale = 1,
    choice = { earth = "strengthofearth", fire = "searing", water = "healingstream", air = "graceofair" },
    imbue = "rockbiter",
    showDropAll = true,
    showImbue = true,
    sets = {},  -- [name] = { earth =, fire =, water =, air = }
    warn = { expiring = true, expireAt = 10, destroyed = true, range = true, imbue = true, imbueMinutes = 5,
             chat = true, sound = false },
    language = "auto",
}

local function Merge(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            if next(value) then Merge(target[key], value) end
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.Print(text)
    print("|cff00c0ffTotems:|r " .. tostring(text))
end

function ns.IsShaman()
    local _, class = UnitClass("player")
    return class == "SHAMAN"
end

local pending = {}
function ns.WhenSafe(key, fn)
    if InCombatLockdown() then
        pending[key] = fn
        return false
    end
    pending[key] = nil
    fn()
    return true
end

-- --- Totem sets -----------------------------------------------------------------------

function ns.SaveSet(name)
    local set = {}
    for _, element in ipairs(ns.Totems.ELEMENTS) do set[element] = ns.db.choice[element] end
    ns.db.sets[name] = set
end

-- Returns false when there's no set with that name.
function ns.UseSet(name)
    local set = ns.db.sets[name]
    if not set then return false end
    for _, element in ipairs(ns.Totems.ELEMENTS) do
        if set[element] then ns.db.choice[element] = set[element] end
    end
    ns.Buttons.Update()
    return true
end

function ns.SetNames()
    local names = {}
    for name in pairs(ns.db.sets) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- --- Events -----------------------------------------------------------------------------

BINDING_HEADER_NULLGATESTOTEMS = "Nullgate's Totems"
local function NameBindings()
    _G["BINDING_NAME_CLICK NullgatesTotemsEarth:LeftButton"] = L["Drop your Earth totem"]
    _G["BINDING_NAME_CLICK NullgatesTotemsFire:LeftButton"] = L["Drop your Fire totem"]
    _G["BINDING_NAME_CLICK NullgatesTotemsWater:LeftButton"] = L["Drop your Water totem"]
    _G["BINDING_NAME_CLICK NullgatesTotemsAir:LeftButton"] = L["Drop your Air totem"]
    _G["BINDING_NAME_CLICK NullgatesTotemsDropAll:LeftButton"] = L["Drop all four totems (one per press)"]
    _G["BINDING_NAME_CLICK NullgatesTotemsImbue:LeftButton"] = L["Imbue your weapon"]
end

local events = CreateFrame("Frame")
local active = false

local function OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if type(NullgatesTotemsDB) ~= "table" then NullgatesTotemsDB = {} end
            Merge(NullgatesTotemsDB, ns.DEFAULTS)
            ns.db = NullgatesTotemsDB
            ns.SetLanguage(ns.db.language)
            NameBindings()
        end
        if arg1 == addonName or arg1 == "NullgatesAddonConfig-Forever" then ns.Options.RegisterHub() end
    elseif event == "PLAYER_LOGIN" then
        active = ns.IsShaman()
        if active then
            ns.Buttons.Create()
            C_Timer.NewTicker(1, ns.Buttons.Tick)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for key, fn in pairs(pending) do
            pending[key] = nil
            fn()
        end
    elseif not active then
        return
    elseif event == "PLAYER_TOTEM_UPDATE" or event == "UNIT_INVENTORY_CHANGED" then
        ns.Buttons.Tick()
    else -- spells learned or level-up
        ns.Buttons.Update()
    end
end

events:SetScript("OnEvent", OnEvent)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP",
    "PLAYER_TOTEM_UPDATE", "UNIT_INVENTORY_CHANGED" }) do
    events:RegisterEvent(event)
end

local function Help()
    ns.Print(L["commands:"])
    print("  /ntotem - " .. L["open the settings"])
    print("  /ntotem save <" .. L["name"] .. "> - " .. L["save your four totem choices as a set"])
    print("  /ntotem set <" .. L["name"] .. "> - " .. L["switch to a saved set"])
    print("  /ntotem delete <" .. L["name"] .. "> - " .. L["delete a saved set"])
    print("  /ntotem sets - " .. L["list your saved sets"])
    print("  /ntotem lock | unlock - " .. L["lock or unlock the bar"])
    print("  /ntotem reset - " .. L["reset the bar's position"])
    print("  /ntotem check - " .. L["test what the addon needs in this client (results are saved)"])
end

SLASH_NULLGATESTOTEMS1 = "/ntotem"
SLASH_NULLGATESTOTEMS2 = "/totems"
SlashCmdList["NULLGATESTOTEMS"] = function(msg)
    msg = msg or ""
    local command, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "check" then
        ns.Check.Run()
    elseif command == "help" then
        Help()
    elseif not active then
        ns.Print(L["This addon is for shamans; only /ntotem check works on other classes."])
    elseif command == "" or command == "options" or command == "config" then
        ns.Options.Open()
    elseif command == "save" and rest ~= "" then
        ns.SaveSet(rest)
        ns.Print(string.format(L["Saved the set \"%s\"."], rest))
    elseif command == "set" and rest ~= "" then
        if ns.UseSet(rest) then
            ns.Print(string.format(L["Switched to the set \"%s\"."], rest))
        else
            ns.Print(string.format(L["There's no set called \"%s\"."], rest))
        end
    elseif command == "delete" and rest ~= "" then
        ns.db.sets[rest] = nil
        ns.Print(string.format(L["Deleted the set \"%s\"."], rest))
    elseif command == "sets" then
        local names = ns.SetNames()
        ns.Print(#names > 0 and table.concat(names, ", ") or L["No saved sets yet: use /ntotem save <name>."])
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Buttons.Layout()
    elseif command == "reset" then
        ns.Buttons.ResetPosition()
    else
        Help()
    end
end
