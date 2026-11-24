-- Nullgate's Totems: /ntotem check, the in-game self test (phase 0 of PLAN.md).
-- Every result goes to chat and to NullgatesTotemsDB.check, so the log can be copied from
-- WTF\Account\<account>\<realm>\<character>\SavedVariables\NullgatesTotems-Forever.lua.
--
--   1. Which calls exist, which totems and imbues are known, the Drop All macro, the active totems
--      as GetTotemInfo reports them and the party buffs the addon finds.
--   2. While the window is open: every totem update is reported with GetTotemInfo's answer, to
--      confirm the timers, and blocked actions are logged.
local _, ns = ...

local Check = {}
ns.Check = Check

local LOG_LIMIT = 400
local panel

local function Log(text)
    local db = ns.db
    if db then
        db.check = db.check or {}
        if #db.check >= LOG_LIMIT then table.remove(db.check, 1) end
        db.check[#db.check + 1] = text
    end
    print("|cff00c0ffNullgate's Totems check:|r " .. text)
    if NullgateReport then NullgateReport.Update("totems") end
end
Check.Log = Log

-- Opens the report window every Nullgate addon shares (NullgateReport.lua) with this check's log,
-- ready to copy and paste into the report form on our website.
function Check.ShowReport()
    local L = ns.L
    return NullgateReport.Show({
        slug = "totems", name = "Nullgate's Totems", addon = "NullgatesTotems-Forever", command = "/ntotem check",
        lines = function() return ns.db and ns.db.check end,
        title = L["Bug report"], selectAll = L["Select all"], selectLink = L["Select link"],
        help = L["Press Ctrl+C to copy this report, then paste it into a new report at the link below, with a few words on what happened."],
    })
end

local function Exists(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function TotemLine(element)
    local slot = ns.Totems.SLOT[element]
    local have, name, start, duration = GetTotemInfo(slot)
    return string.format("%s (slot %d): have %s, name %s, start %s, duration %s", element, slot, tostring(have),
        tostring(name), tostring(start), tostring(duration))
end

local function StaticChecks()
    local _, class = UnitClass("player")
    Log(string.format("client %s, build %s, interface %s; class %s, level %s; data build %s",
        tostring(GetBuildInfo and select(1, GetBuildInfo())), tostring(GetBuildInfo and select(2, GetBuildInfo())),
        tostring(GetBuildInfo and select(4, GetBuildInfo())), tostring(class), tostring(UnitLevel("player")),
        tostring(ns.TOTEM_DATA_BUILD)))
    local calls = {}
    for _, name in ipairs({ "GetTotemInfo", "C_UnitAuras.GetAuraDataByIndex", "UnitBuff", "UnitInRange", "GetWeaponEnchantInfo",
        "C_Spell.GetSpellName", "C_SpellBook.IsSpellKnown" }) do
        calls[#calls + 1] = name .. "=" .. (Exists(name) and "yes" or "no")
    end
    Log("calls: " .. table.concat(calls, " "))
    for _, element in ipairs(ns.Totems.ELEMENTS) do
        local known = {}
        for _, totem in ipairs(ns.Totems.KnownList(element)) do
            known[#known + 1] = string.format("%s (%d, %ds%s)", tostring(ns.Units.SpellName(totem.ranks[1][1])),
                ns.Totems.BestRank(totem), totem.duration, totem.buffSpell > 0 and (", buff " .. tostring(ns.Units.SpellName(totem.buffSpell))) or "")
        end
        Log(element .. " known: " .. (#known > 0 and table.concat(known, "; ") or "none"))
        if GetTotemInfo then Log(TotemLine(element)) end
    end
    local b = ns.Buttons.buttons
    Log("drop all macro: " .. tostring(b.dropall and b.dropall:GetAttribute("macrotext")))
    local has, secs = ns.Units.Imbue()
    Log(string.format("imbue: chosen %s, button spell %s, on weapon %s (%ss left)", tostring(ns.db.imbue),
        tostring(b.imbue and b.imbue:GetAttribute("spell")), tostring(has), tostring(secs)))
end

local function BuildPanel()
    panel = CreateFrame("Frame", "NullgatesTotemsCheck", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 110)
    panel:SetPoint("TOPLEFT", NullgateReport.Frame(), "TOPRIGHT", 4, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local title = "Totems check"
    if type(panel.SetTitle) == "function" then panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then panel.TitleText:SetText(title) end
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOP", panel, "TOP", 0, -36)
    note:SetWidth(270)
    note:SetText("Drop totems (with the buttons and Drop All) while this window is open; what the game reports goes to chat and is saved.")
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_TOTEM_UPDATE")
watcher:RegisterEvent("ADDON_ACTION_BLOCKED")
watcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
watcher:SetScript("OnEvent", function(_, event, a, b)
    if not (panel and panel:IsShown()) then return end
    if event == "PLAYER_TOTEM_UPDATE" then
        for element, slot in pairs(ns.Totems.SLOT) do
            if slot == a then Log("totem update: " .. TotemLine(element)) end
        end
    else
        Log(event .. ": " .. tostring(a) .. " tried " .. tostring(b))
    end
end)

function Check.Run()
    if ns.db then ns.db.check = {} end
    StaticChecks()
    if not panel then BuildPanel() end
    panel:Show()
    Check.ShowReport()
end
