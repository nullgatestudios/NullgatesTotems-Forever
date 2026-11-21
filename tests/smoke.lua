-- Nullgate's Totems: smoke test of the whole addon with stand-in game API.
-- Loads the files in .toc order, logs in as a level 60 shaman in a party and drives the element
-- buttons, Drop All, the choice menu, combat, timers, party buffs, every warning, sets and check.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesTotems-Forever"
local root = repo .. "/" .. folder .. "/"

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; io.write("FAIL " .. name .. "\n") end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, _, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    setmetatable(f, { __index = function(_, key) if type(key) == "string" and key:match("^%u") then return function() return nil end end end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:HookScript(k, fn) local old = self.scripts[k]; self.scripts[k] = function(...) if old then old(...) end fn(...) end end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(v) self.shown = v and true or false end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:CreateFontString() return NewFrame("FontString") end
    function f:CreateTexture() return NewFrame("Texture") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
UISpecialFrames = {}
print = function(text) printed[#printed + 1] = tostring(text) end
local function Printed(fragment)
    for _, line in ipairs(printed) do if line:find(fragment, 1, true) then return true end end
    return false
end

local inCombat, now = false, 1000
function UnitClass() return "SHAMAN", "SHAMAN" end
function UnitLevel() return 60 end
function UnitName(unit) return ({ player = "Me", party1 = "Tank", party2 = "Far" })[unit] end
function UnitIsConnected() return true end
function UnitIsDeadOrGhost() return false end
function UnitInRange(unit) if unit == "party2" then return false, true end return true, true end
function IsInRaid() return false end
function GetNumSubgroupMembers() return 2 end
function InCombatLockdown() return inCombat end
function GetTime() return now end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
function PlaySound() end
C_Timer = { After = function(_, fn) fn() end, NewTicker = function() end }

-- Spells: every rank the data has is known; names come from the data.
local spellNames = {}
assert(loadfile(root .. "Data/Totems.lua"))(folder, { })
local data = {}
assert(loadfile(root .. "Data/Totems.lua"))(folder, data)
for _, list in pairs(data.TOTEMS) do
    for _, totem in ipairs(list) do
        for _, rank in ipairs(totem.ranks) do spellNames[rank[1]] = totem.name end
        if totem.buffSpell > 0 then spellNames[totem.buffSpell] = totem.name:gsub(" Totem$", "") end
    end
end
for _, imbue in ipairs(data.IMBUES) do for _, rank in ipairs(imbue.ranks) do spellNames[rank[1]] = imbue.name end end
local known = {}
for id in pairs(spellNames) do known[id] = true end
known[16190], known[17354], known[17359], known[1325256] = nil, nil, nil, nil -- Mana Tide is a talent we don't have
C_SpellBook = { IsSpellKnown = function(id) return known[id] == true end }
C_Spell = { GetSpellName = function(id) return spellNames[id] end, GetSpellTexture = function(id) return "tex" .. id end }

local totems = {} -- [slot] = { name, start, duration }
function GetTotemInfo(slot) local t = totems[slot]; if t then return true, t[1], t[2], t[3] end return false, "", 0, 0 end
local buffs = {} -- [unit] = { name = true }
C_UnitAuras = { GetAuraDataByIndex = function(unit, i)
    local list = {}
    for name in pairs(buffs[unit] or {}) do list[#list + 1] = name end
    table.sort(list)
    return list[i] and { name = list[i] } or nil
end }
local imbue = { false, 0 }
function GetWeaponEnchantInfo() return imbue[1], imbue[2] end

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        assert(loadfile(root .. line:gsub("\\", "/")))(folder, ns)
    end
end
local core
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then core = f end end
local function Fire(event, ...) core.scripts.OnEvent(core, event, ...) end
Fire("ADDON_LOADED", folder)
local db = NullgatesTotemsDB
OK(db.choice.earth == "strengthofearth" and db.imbue == "rockbiter", "saved data gets its defaults")
OK(SLASH_NULLGATESTOTEMS1 == "/ntotem" and SLASH_NULLGATESTOTEMS2 == "/totems", "slash commands /ntotem and /totems")
OK(_G["BINDING_NAME_CLICK NullgatesTotemsDropAll:LeftButton"] ~= nil, "the Drop All key binding has a name")

-- --- Login --------------------------------------------------------------------------
Fire("PLAYER_LOGIN")
local earth, water, dropall, imb = NullgatesTotemsEarth, NullgatesTotemsWater, NullgatesTotemsDropAll, NullgatesTotemsImbue
local soe = ns.Totems.Find("earth", "strengthofearth")
OK(earth.template == "SecureActionButtonTemplate" and earth.attributes.type == "spell", "element buttons are secure spell buttons")
OK(earth.attributes.spell == soe.ranks[#soe.ranks][1], "Earth casts Strength of Earth at the highest rank")
OK(dropall.attributes.type == "macro" and dropall.attributes.macrotext ==
    "/castsequence reset=combat/8 Strength of Earth Totem, Searing Totem, Healing Stream Totem, Grace of Air Totem",
    "Drop All drops the four chosen totems")
local rockbiter = ns.Totems.FindImbue("rockbiter")
OK(imb.attributes.spell == rockbiter.ranks[#rockbiter.ranks][1], "the imbue button casts Rockbiter Weapon")
OK(Printed("Your weapon has no imbue."), "no imbue: a reminder")

-- --- Right-click menu -------------------------------------------------------------------
water.scripts.OnClick(water, "RightButton", false)
OK(NullgatesTotemsMenu and NullgatesTotemsMenu.shown, "right-click opens the totem menu")
local manaspring
for _, row in ipairs(NullgatesTotemsMenu.entries) do if row.key == "manaspring" and row:IsShown() then manaspring = row end end
OK(manaspring ~= nil, "Mana Spring is listed")
for _, row in ipairs(NullgatesTotemsMenu.entries) do OK(row.key ~= "manatide" or not row:IsShown(), "Mana Tide (not known) isn't listed") end
manaspring.scripts.OnClick(manaspring)
OK(db.choice.water == "manaspring" and dropall.attributes.macrotext:find("Mana Spring Totem", 1, true), "choosing Mana Spring updates the button and Drop All")

-- --- Combat ----------------------------------------------------------------------------
inCombat = true
db.choice.water = "healingstream"
ns.Buttons.Update()
OK(water.stale and not dropall.attributes.macrotext:find("Healing Stream", 1, true), "in combat the buttons don't change and are marked")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
OK(not water.stale and dropall.attributes.macrotext:find("Healing Stream", 1, true), "after combat the change applies")

-- --- An active totem: timer, party buffs ---------------------------------------------------
totems[2] = { "Strength of Earth Totem V", now, 300 }
buffs.player = { ["Strength of Earth"] = true }
buffs.party1 = { ["Strength of Earth"] = true }
printed = {}
Fire("PLAYER_TOTEM_UPDATE", 2)
OK(earth.timer.text == "5:00", "the Earth button shows 5:00")
OK(earth.party.text == "2/3", "two of three have the buff (one is out of range)")

-- --- Expiring ------------------------------------------------------------------------------
now = now + 291
ns.Buttons.Tick()
OK(Printed("Strength of Earth Totem V expires in 9 seconds."), "a warning 10 seconds before it expires")
printed = {}
ns.Buttons.Tick()
OK(#printed == 0 or not Printed("expires"), "only once")

-- --- Destroyed --------------------------------------------------------------------------------
totems[2] = { "Strength of Earth Totem V", now, 300 }
Fire("PLAYER_TOTEM_UPDATE", 2)
now = now + 30
totems[2] = nil
printed = {}
Fire("PLAYER_TOTEM_UPDATE", 2)
OK(Printed("Strength of Earth Totem V was destroyed."), "a totem gone early was destroyed")
OK(earth.timer.text == "", "and its timer clears")

-- --- Out of range --------------------------------------------------------------------------------
totems[4] = { "Grace of Air Totem III", now, 300 }
buffs.player = {}
Fire("PLAYER_TOTEM_UPDATE", 4)
printed = {}
now = now + 5
ns.Buttons.Tick()
OK(Printed("You're out of range of your Grace of Air Totem III."), "no buff five seconds after dropping: out of range")

-- --- Imbue ------------------------------------------------------------------------------------
imbue = { true, 1800000 }
printed = {}
ns.Buttons.Tick()
OK(not imb.glow.shown and imb.timer.text == "30:00", "imbued: no glow, time shown")
imbue = { true, 120000 }
ns.Buttons.Tick()
OK(Printed("Your weapon imbue is running low (2:00 left)."), "under 5 minutes: a reminder")

-- --- Sets -----------------------------------------------------------------------------------------
SlashCmdList.NULLGATESTOTEMS("save Raid melee")
db.choice.earth = "stoneskin"
SlashCmdList.NULLGATESTOTEMS("set Raid melee")
OK(db.choice.earth == "strengthofearth", "/ntotem set restores a saved set")
SlashCmdList.NULLGATESTOTEMS("set Nope")
OK(Printed("There's no set called \"Nope\"."), "an unknown set says so")

-- --- Settings and /ntotem check ------------------------------------------------------------------
SlashCmdList.NULLGATESTOTEMS("")
OK(NullgatesTotemsOptions and NullgatesTotemsOptions.shown, "/ntotem opens the settings")
SlashCmdList.NULLGATESTOTEMS("check")
local log = table.concat(db.check or {}, "\n")
OK(log:find("GetTotemInfo=yes", 1, true), "check reports which calls exist")
OK(log:find("drop all macro: /castsequence", 1, true), "check reports the Drop All macro")
OK(NullgatesTotemsCheck and NullgatesTotemsCheck.shown, "the check window opens")

io.write(string.format("smoke: %d checks, %d failure(s)\n", checks, failures))
if failures > 0 then os.exit(1) end
