-- Nullgate's Totems: the bar. Four element buttons (each casts its chosen totem at your highest
-- rank), Drop All (a cast sequence of the four), and the weapon imbue button. Right-click a button to
-- choose its totem or imbue. Once a second the bar updates timers, party buff counts and warnings.
local _, ns = ...

local L = ns.L
local Buttons = {}
ns.Buttons = Buttons

local SIZE, GAP = 36, 4
local ICONS = {
    earth = "Interface\\Icons\\Spell_Nature_EarthBindTotem", fire = "Interface\\Icons\\Spell_Fire_SearingTotem",
    water = "Interface\\Icons\\INV_Spear_04", air = "Interface\\Icons\\Spell_Nature_InvisibilityTotem",
    dropall = "Interface\\Icons\\Spell_Totem_WardOfDraining", imbue = "Interface\\Icons\\Spell_Nature_RockBiter",
}
local ORDER = { "earth", "fire", "water", "air", "dropall", "imbue" }
local bar, menu
local buttons = {}
Buttons.buttons = buttons
local watch = {} -- [element] = { start, remaining, warned, outWarned, droppedAt }
local imbueWarned = false

local function ElementName(element)
    return (element == "earth" and L["Earth"]) or (element == "fire" and L["Fire"]) or (element == "water" and L["Water"])
        or (element == "air" and L["Air"]) or element
end

-- A totem's or imbue's name in the game's language (its spell name), English as a fallback.
local function EntryName(entry)
    return entry and (ns.Units.SpellName(entry.ranks[1][1]) or entry.name) or nil
end

local function SpellIcon(spellID)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellID) end
    return GetSpellTexture and GetSpellTexture(spellID) or nil
end

-- The data entry for an active totem, from its name (which may carry a rank numeral).
local function ActiveEntry(element, name)
    for _, totem in ipairs(ns.TOTEMS[element]) do
        local base = ns.Units.SpellName(totem.ranks[1][1])
        if base and name:find(base, 1, true) == 1 then return totem end
    end
end

local function PartyBuffs(totem)
    local buffName = totem and totem.buffSpell > 0 and ns.Units.SpellName(totem.buffSpell)
    if not buffName then return nil end
    local rows, have, total = {}, 0, 0
    for _, unit in ipairs(ns.Units.Party()) do
        local state = ns.Units.BuffState(unit, buffName)
        rows[#rows + 1] = { name = UnitName(unit), state = state }
        total = total + 1
        if state == "yes" then have = have + 1 end
    end
    return rows, have, total
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local kind = button.kind
    if kind == "dropall" then
        GameTooltip:AddLine(L["Drop All"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Press once per totem to drop all four chosen totems."], 1, 1, 1, true)
    elseif kind == "imbue" then
        local imbue = button.entry
        GameTooltip:AddLine(EntryName(imbue) or L["Weapon imbue"], 1, 0.82, 0)
        local has, secs = ns.Units.Imbue()
        if has then
            GameTooltip:AddLine(string.format(L["On your weapon: %s left."], ns.Totems.Clock(secs)), 1, 1, 1, true)
        else
            GameTooltip:AddLine(L["No imbue on your weapon."], 1, 0.4, 0.3, true)
        end
        GameTooltip:AddLine(L["Right-click: choose the imbue."], 0.6, 0.6, 0.6)
    else
        local totem = button.entry
        GameTooltip:AddLine(ElementName(kind) .. ": " .. (EntryName(totem) or L["none known"]), 1, 0.82, 0)
        local name, start, duration = ns.Units.Totem(kind)
        if name then
            GameTooltip:AddLine(string.format(L["%s: %s left."], name, ns.Totems.Clock(ns.Totems.Remaining(start, duration, GetTime()))), 1, 1, 1)
            local rows = PartyBuffs(ActiveEntry(kind, name))
            for _, row in ipairs(rows or {}) do
                local color = (row.state == "yes" and "|cff40ff40") or (row.state == "far" and "|cff808080") or "|cffff5050"
                local text = (row.state == "yes" and L["has it"]) or (row.state == "far" and L["out of range"]) or L["missing"]
                GameTooltip:AddLine(color .. tostring(row.name) .. ": " .. text .. "|r")
            end
        end
        GameTooltip:AddLine(L["Right-click: choose the totem."], 0.6, 0.6, 0.6)
    end
    if button.stale then GameTooltip:AddLine(L["In combat: updates when combat ends."], 1, 0.3, 0.3, true) end
    GameTooltip:Show()
end

-- The right-click menu: the totems known for an element, or the imbues known.
local function ShowMenu(button)
    if not menu then
        menu = CreateFrame("Frame", "NullgatesTotemsMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetToplevel(true)
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        if menu.SetBackdrop then
            menu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
            menu:SetBackdropColor(0.05, 0.06, 0.08, 0.95)
        end
        menu.entries = {}
        if UISpecialFrames then table.insert(UISpecialFrames, "NullgatesTotemsMenu") end
    end
    local list = button.kind == "imbue" and {} or ns.Totems.KnownList(button.kind)
    if button.kind == "imbue" then
        for _, imbue in ipairs(ns.IMBUES) do
            if ns.Totems.BestRank(imbue) then list[#list + 1] = imbue end
        end
    end
    if #list == 0 then return end
    local current = button.kind == "imbue" and ns.db.imbue or ns.db.choice[button.kind]
    for i, entry in ipairs(list) do
        local row = menu.entries[i]
        if not row then
            row = CreateFrame("Button", nil, menu)
            row:SetSize(200, 20)
            row:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -8 - (i - 1) * 20)
            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(row)
            hl:SetColorTexture(1, 1, 1, 0.15)
            row:SetScript("OnClick", function(self)
                if menu.kind == "imbue" then ns.db.imbue = self.key else ns.db.choice[menu.kind] = self.key end
                menu:Hide()
                Buttons.Update()
            end)
            menu.entries[i] = row
        end
        row.key = entry.key
        row.text:SetText((entry.key == current and "|cffffd100> |r" or "   ") .. EntryName(entry))
        row:Show()
    end
    for i = #list + 1, #menu.entries do menu.entries[i]:Hide() end
    menu.kind = button.kind
    menu:SetSize(216, 16 + #list * 20)
    menu:ClearAllPoints()
    menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
    menu:Show()
end
Buttons.ShowMenu = ShowMenu

local function NewButton(kind)
    local names = { earth = "Earth", fire = "Fire", water = "Water", air = "Air", dropall = "DropAll", imbue = "Imbue" }
    local button = CreateFrame("Button", "NullgatesTotems" .. names[kind], bar, "SecureActionButtonTemplate")
    button.kind = kind
    button:SetSize(SIZE, SIZE)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(ICONS[kind])
    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetPoint("TOPLEFT", -4, 4)
    button.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    button.glow:SetColorTexture(1, 0.6, 0.1, 0.35)
    button.glow:Hide()
    button.timer = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.timer:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    button.party = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.party:SetPoint("TOPRIGHT", -2, -2)
    button.staleMark = button:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    button.staleMark:SetPoint("TOPLEFT", 2, -2)
    button.staleMark:SetText("*")
    button.staleMark:Hide()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if kind ~= "dropall" then
        button:HookScript("OnClick", function(self, mouse, down)
            if mouse == "RightButton" and not down then ShowMenu(self) end
        end)
    end
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function() bar:GetScript("OnDragStart")(bar) end)
    button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    buttons[kind] = button
    return button
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    bar:ClearAllPoints()
    local p = ns.db.point
    if p and p.point then
        bar:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    end
end

function Buttons.Create()
    if bar then return end
    bar = CreateFrame("Frame", "NullgatesTotemsBar", UIParent)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not ns.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints(bar)
    bar.background:SetColorTexture(0.08, 0.1, 0.13, 0.75)
    for _, kind in ipairs(ORDER) do NewButton(kind) end
    RestorePosition()
    Buttons.Layout()
    Buttons.Update()
end

function Buttons.Shown()
    local shown = {}
    for _, kind in ipairs(ORDER) do
        if (kind ~= "dropall" or ns.db.showDropAll) and (kind ~= "imbue" or ns.db.showImbue) then shown[#shown + 1] = buttons[kind] end
    end
    return shown
end

function Buttons.Layout()
    if not bar then return end
    ns.WhenSafe("layout", function()
        for _, b in pairs(buttons) do b:Hide() end
        local shown = Buttons.Shown()
        for i, button in ipairs(shown) do
            button:ClearAllPoints()
            local offset = GAP + (i - 1) * (SIZE + GAP)
            if ns.db.vertical then button:SetPoint("TOP", bar, "TOP", 0, -offset)
            else button:SetPoint("LEFT", bar, "LEFT", offset, 0) end
            button:Show()
        end
        local long, short = GAP + #shown * (SIZE + GAP), SIZE + 2 * GAP
        if ns.db.vertical then bar:SetSize(short, long) else bar:SetSize(long, short) end
        bar:SetScale(ns.db.scale or 1)
        bar.background:SetShown(not ns.db.locked)
        bar:Show()
    end)
end

-- Sets what each button casts, out of combat.
function Buttons.Update()
    if not bar then return end
    local applied = ns.WhenSafe("buttons", function()
        local names = {}
        for _, element in ipairs(ns.Totems.ELEMENTS) do
            local button = buttons[element]
            local totem = ns.Totems.Chosen(element, ns.db.choice[element])
            local spell = ns.Totems.BestRank(totem)
            button.entry = totem
            button:SetAttribute("type", spell and "spell" or nil)
            button:SetAttribute("spell", spell)
            button.icon:SetTexture((spell and SpellIcon(spell)) or ICONS[element])
            button.icon:SetDesaturated(spell == nil)
            names[element] = spell and ns.Units.SpellName(spell) or nil
        end
        local macro = ns.Totems.DropAllMacro(names)
        buttons.dropall:SetAttribute("type", macro and "macro" or nil)
        buttons.dropall:SetAttribute("macrotext", macro)
        buttons.dropall.icon:SetDesaturated(macro == nil)

        local imbue = ns.Totems.ChosenImbue(ns.db.imbue)
        local imbueSpell = ns.Totems.BestRank(imbue)
        buttons.imbue.entry = imbue
        buttons.imbue:SetAttribute("type", imbueSpell and "spell" or nil)
        buttons.imbue:SetAttribute("spell", imbueSpell)
        buttons.imbue.icon:SetTexture((imbueSpell and SpellIcon(imbueSpell)) or ICONS.imbue)
        buttons.imbue.icon:SetDesaturated(imbueSpell == nil)
        for _, b in pairs(buttons) do
            b.stale = false
            b.staleMark:Hide()
        end
    end)
    if not applied then
        for _, b in pairs(buttons) do
            b.stale = true
            b.staleMark:Show()
        end
    end
    Buttons.Tick()
end

local function Warn(text)
    if ns.db.warn.chat then ns.Print(text) end
    if ns.db.warn.sound and PlaySound then PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
end

-- Timers, party counts and warnings (none of this is protected). Runs once a second.
function Buttons.Tick()
    if not bar then return end
    local now, w = GetTime(), ns.db.warn
    for _, element in ipairs(ns.Totems.ELEMENTS) do
        local button, state = buttons[element], watch[element]
        local name, start, duration = ns.Units.Totem(element)
        if name then
            if not state or state.start ~= start then
                state = { start = start, droppedAt = now }
                watch[element] = state
            end
            local remaining = ns.Totems.Remaining(start, duration, now)
            state.remaining, state.name = remaining, name
            button.timer:SetText(ns.Totems.Clock(remaining))
            if ns.Totems.ShouldWarnExpiring(remaining, w.expiring and w.expireAt or 0, state.warned) then
                state.warned = true
                Warn(string.format(L["%s expires in %d seconds."], name, math.floor(remaining + 0.5)))
            end
            local totem = ActiveEntry(element, name)
            local rows, have, total = PartyBuffs(totem)
            button.party:SetText(rows and (have .. "/" .. total) or "")
            if rows and w.range and not state.outWarned then
                local mine = ns.Units.HasBuff("player", ns.Units.SpellName(totem.buffSpell))
                if ns.Totems.OutOfRange(mine, now - state.droppedAt, 3) then
                    state.outWarned = true
                    Warn(string.format(L["You're out of range of your %s."], name))
                end
            end
        else
            if state and w.destroyed and ns.Totems.WasDestroyed(state.remaining) and not UnitIsDeadOrGhost("player") then
                Warn(string.format(L["%s was destroyed."], state.name))
            end
            watch[element] = nil
            button.timer:SetText("")
            button.party:SetText("")
        end
    end
    local has, secs = ns.Units.Imbue()
    local low = ns.db.showImbue and w.imbue and buttons.imbue.entry ~= nil
        and (not has or (w.imbueMinutes > 0 and secs < w.imbueMinutes * 60)) or false
    buttons.imbue.timer:SetText(has and ns.Totems.Clock(secs) or "")
    buttons.imbue.glow:SetShown(low)
    if low and not imbueWarned then
        Warn(has and string.format(L["Your weapon imbue is running low (%s left)."], ns.Totems.Clock(secs)) or L["Your weapon has no imbue."])
    end
    imbueWarned = low
end

function Buttons.ResetPosition()
    if not bar then return end
    ns.db.point = nil
    ns.WhenSafe("position", RestorePosition)
end
