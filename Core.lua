-- Wick's Conjures and Things
-- Core.lua: WickCore addon object, saved variables, event dispatch, slash command.
--
-- The mage kit for World of Warcraft: Forever. A mage's setup is stock:
-- water, food, a gem, an armor spell and the reagents the group spells
-- eat. All of it is item counts and known spells, readable out of combat,
-- so the kit sits comfortably inside Forever's addon rules.

local ADDON, ns = ...

local Core = WickCore
assert(Core, "Wick's Conjures and Things requires WickCore. Enable the WickCore addon.")
local D, R = Core.Dialect, Core.Restrict

ns.version = "0.1.0"

local PROFILE_DEFAULTS = {
    lowRations  = 20,     -- fewer conjured items than this reads as low
    showStrip   = true,
    stripLocked = true,
    strip       = {},
    window      = {},
    kitWindow   = {},
}

local A = Core:NewAddon("WicksConjuresAndThings", {
    title    = "Wick's Conjures and Things",
    version  = ns.version,
    savedVar = "WicksConjuresSaved",
    defaults = { profile = PROFILE_DEFAULTS, global = {} },
})
ns.A = A

-- ============================================================
-- Event dispatcher
-- ============================================================
local events = {}
function ns:On(event, fn)
    events[event] = events[event] or {}
    table.insert(events[event], fn)
end

local frame = CreateFrame("Frame", "WicksConjuresEvents")
ns.eventFrame = frame
frame:SetScript("OnEvent", function(_, event, ...)
    if not events[event] then return end
    for _, fn in ipairs(events[event]) do
        local ok, err = pcall(fn, event, ...)
        if not ok then A:Print(("error in %s: %s"):format(event, tostring(err))) end
    end
end)
function ns.RegisterEvents(list)
    for _, ev in ipairs(list) do pcall(frame.RegisterEvent, frame, ev) end
end

local _, playerClass = UnitClass("player")
ns.isMage = playerClass == "MAGE"

-- Armor spells, best first. Any one of them satisfies the checklist.
ns.ARMOR = { "Ice Armor", "Mage Armor", "Frost Armor" }

-- ============================================================
-- Lifecycle
-- ============================================================
function A:OnInitialize()
    ns.db = self.db
    self.db:On("OnProfileChanged", function()
        if ns.UI and ns.UI.ApplyStripVisibility then ns.UI:ApplyStripVisibility() end
        if ns.Conjure and ns.Conjure.UpdateButtons then ns.Conjure:UpdateButtons() end
    end)

    Core.Cooldowns:New(self, { key = "cooldownBar" })

    Core.Kit:New(self, {
        racials = true,
        checklist = {
            { label = "Armor up", aura = ns.ARMOR, cast = "Frost Armor" },
            { label = "Arcane Intellect", aura = { "Arcane Intellect", "Arcane Brilliance" },
              cast = "Arcane Intellect" },
            { label = "Water and food", check = function()
                local s = ns.Conjure:Summary()
                return s.rations >= (ns.db.profile.lowRations or 20)
            end },
            { label = "Mana gem", check = function()
                -- Only expected once the spell is learned.
                if not ns.Conjure:BestGem() then return nil end
                return ns.Conjure:Summary().gems > 0
            end },
            { label = "Arcane powder", item = "Arcane Powder", min = 5 },
        },
    })
end

function A:OnEnable()
    if not ns.isMage then
        self:Print("loaded (non-mage: viewer mode).")
    else
        self:Print("loaded. /wcj for rations and reagents, /wcj kit for talents and checklist.")
    end
    if ns.Conjure and ns.Conjure.Init then ns.Conjure:Init() end
    if ns.UI and ns.UI.Init then ns.UI:Init() end
    if self.cooldowns then self.cooldowns:Init() end

    self:RegisterLauncher({
        onClick = function(_, button)
            if button == "RightButton" then self.kit:Toggle()
            else ns.UI:Toggle() end
        end,
        tooltip = function(tt)
            tt:AddLine(Core.Chrome:TitleMarkup("Wick's Conjures and Things"))
            tt:AddLine("Left-click: rations   Right-click: talents and checklist", 0.5, 0.5, 0.5)
        end,
    })

    self:RegisterOptions(function(page, addon)
        local O = Core.Options
        local db = addon.db.profile
        local y = O:Heading(page, "Strip", 0)
        y = O:Check(page, "Show the compact strip", function() return db.showStrip ~= false end,
            function(v) db.showStrip = v; ns.UI:ApplyStripVisibility() end, y)
        y = O:Check(page, "Lock the strip", function() return db.stripLocked ~= false end,
            function(v) db.stripLocked = v end, y)
        y = O:Note(page, "One row: rations carried, your gem, and the reagents. Click a segment to conjure, right-click for the full panel.", y)
        y = O:Heading(page, "Stock", y - 6)
        y = O:Note(page, ("Rations read as low under %d. Change it with /wcj low <count>."):format(db.lowRations or 20), y)
        y = O:Button(page, "Open panel", function() ns.UI:Toggle() end, y, 100)
        y = O:Button(page, "Open kit", function() addon.kit:Toggle() end, y, 100)
        if addon.cooldowns then y = addon.cooldowns:OptionRow(page, y - 6) end
        y = O:ProfileSection(page, addon, y - 8)
    end)
end

-- Keybinding entry points
BINDING_HEADER_WICKSCONJURES = "Wick's Conjures and Things"
_G["BINDING_NAME_CLICK WicksConjuresWaterButton:LeftButton"] = "Conjure water"
_G["BINDING_NAME_CLICK WicksConjuresFoodButton:LeftButton"] = "Conjure food"
BINDING_NAME_WICKSCONJURES_TOGGLE = "Toggle rations panel"
function WicksConjuresAndThings_Toggle() if ns.UI then ns.UI:Toggle() end end

-- ============================================================
-- Slash command
-- ============================================================
A:RegisterSlash(function(_, msg)
    msg = Core.trim(msg or "")
    local lower = msg:lower()
    local db = A.db.profile
    if lower == "" or lower == "show" or lower == "toggle" then ns.UI:Toggle() return end
    if lower == "kit" or lower == "talents" or lower == "checklist" then A.kit:Toggle() return end
    if lower == "cd" or lower:match("^cd%s") then return A.cooldowns:Command(msg:match("^%a+%s*(.*)$")) end
    if lower == "options" or lower == "config" then A:OpenOptions() return end
    if lower == "strip" then
        db.showStrip = not (db.showStrip ~= false)
        ns.UI:ApplyStripVisibility()
        A:Print("strip " .. (db.showStrip and "shown" or "hidden") .. ".")
        return
    end
    if lower == "unlock" or lower == "move" then ns.UI:SetStripLocked(false) return end
    if lower == "lock" then ns.UI:SetStripLocked(true) return end
    if lower:match("^low") then
        local n = tonumber(lower:match("^low%s+(%d+)") or "")
        if not n then A:Print(("rations read as low under %d. Use /wcj low <count>."):format(db.lowRations or 20)) return end
        db.lowRations = n
        A:Print(("low mark set to %d."):format(n))
        ns.UI:Refresh()
        return
    end
    if lower == "status" or lower == "debug" then
        local s = ns.Conjure:Summary()
        A:Print(("rations %d  gems %d  low mark %d"):format(s.rations, s.gems, db.lowRations or 20))
        for _, r in ipairs(ns.Conjure:Reagents()) do
            A:Print(("%s: %d"):format(r.label, r.count))
        end
        A:Print(("spells: water %s, food %s, gem %s"):format(
            tostring(ns.Conjure:SpellFor("water")), tostring(ns.Conjure:SpellFor("food")),
            tostring(ns.Conjure:BestGem())))
        return
    end
    A:Print("commands: show | strip | lock | unlock | kit | cd | options | low <count> | status")
end, "/wcj", "/wconjures")
