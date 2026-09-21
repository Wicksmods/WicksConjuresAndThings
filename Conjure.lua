-- Wick's Conjures and Things
-- Conjure.lua: rations, reagents and the spells that make them.
--
-- A mage's pre-pull chore is stock: water, food, a gem, and the powder and
-- runes the group spells eat. All of it is item counts and known spells,
-- which the client answers happily out of combat, so none of this runs
-- into the restrictions.
--
-- Conjured items are found by name rather than by a table of item IDs.
-- Every rank makes a differently named item and Forever may not use the
-- same IDs as Classic, but they all carry the conjured prefix.

local ADDON, ns = ...
local Core = WickCore
local D, R = Core.Dialect, Core.Restrict

local Conjure = {}
ns.Conjure = Conjure

-- The spells worth a button, in the order a mage cares about them. Names
-- rather than IDs so they bind to whatever rank is known.
Conjure.SPELLS = {
    { key = "water", name = "Conjure Water",      label = "Water" },
    { key = "food",  name = "Conjure Food",       label = "Food"  },
    { key = "gem",   name = "Conjure Mana Agate", label = "Gem"   },
}

-- Later gem ranks are separate spells; the best known one wins.
local GEM_RANKS = { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate" }

-- Reagents the group spells consume.
Conjure.REAGENTS = {
    { name = "Arcane Powder",         label = "Arcane powder", low = 5 },
    { name = "Rune of Teleportation", label = "Teleport runes", low = 1 },
    { name = "Rune of Portals",       label = "Portal runes",   low = 1 },
}

local CONJURED = "Conjured"

local function known(spellName)
    local info = D.GetSpellInfo(spellName)
    return info ~= nil
end

-- ============================================================
-- What the bags hold
-- ============================================================

-- Anything conjured, grouped by item. Water, food and gems all match.
function Conjure:Stock()
    local seen, list = {}, {}
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local slots = D.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local info = D.GetContainerItemInfo(bag, slot)
            local id = info and info.itemID
            if id and not seen[id] then
                local it = D.GetItemInfo(id)
                local name = it and it.name
                if name and name:find(CONJURED, 1, true) then
                    seen[id] = true
                    list[#list + 1] = {
                        itemID = id, name = name, icon = it and it.icon,
                        count = D.GetItemCount(id, false) or 0,
                        isGem = name:lower():find("gem") ~= nil
                            or name:lower():find("agate") ~= nil
                            or name:lower():find("jade") ~= nil
                            or name:lower():find("citrine") ~= nil
                            or name:lower():find("ruby") ~= nil,
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- One number for the strip: how many conjured consumables are carried,
-- and whether a gem is among them.
function Conjure:Summary()
    local rations, gems = 0, 0
    for _, it in ipairs(self:Stock()) do
        if it.isGem then gems = gems + it.count else rations = rations + it.count end
    end
    return { rations = rations, gems = gems }
end

function Conjure:Reagents()
    local out = {}
    for _, r in ipairs(self.REAGENTS) do
        local count = D.GetItemCount(r.name, false) or 0
        -- Only report a reagent the mage actually uses; an empty result
        -- for a rune they have never owned is noise, not a warning.
        out[#out + 1] = { name = r.name, label = r.label, count = count, low = r.low }
    end
    return out
end

-- ============================================================
-- Conjure keys
-- ============================================================

function Conjure:BestGem()
    for _, name in ipairs(GEM_RANKS) do
        if known(name) then return name end
    end
    return nil
end

function Conjure:SpellFor(key)
    if key == "gem" then return self:BestGem() end
    for _, s in ipairs(self.SPELLS) do
        if s.key == key then
            return known(s.name) and s.name or nil
        end
    end
    return nil
end

local buttons = {}

-- A button can carry two spells: the strip's rations segment is one
-- control for both halves of the job, so left conjures drink and right
-- conjures food rather than the segment quietly only ever doing one.
function Conjure:RegisterButton(key, b, altKey)
    buttons[key] = buttons[key] or {}
    table.insert(buttons[key], b)
    b._wickAltKey = altKey
    b:SetAttribute("type1", "spell")
    if altKey then b:SetAttribute("type2", "spell") end
    if not altKey then b:SetAttribute("type", "spell") end
    self:UpdateButtons()
end

function Conjure:UpdateButtons()
    if InCombatLockdown() then self.pending = true return end
    self.pending = false
    self.spell = self.spell or {}
    for key, list in pairs(buttons) do
        local spell = self:SpellFor(key)
        self.spell[key] = spell
        for _, b in ipairs(list) do
            b:SetAttribute("spell", spell or "")
            b:SetAttribute("spell1", spell or "")
            if b._wickAltKey then
                b:SetAttribute("spell2", self:SpellFor(b._wickAltKey) or "")
            end
        end
    end
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end

function Conjure:Init()
    if self.inited then return end
    self.inited = true

    for _, def in ipairs({ { "water", "WicksConjuresWaterButton" }, { "food", "WicksConjuresFoodButton" } }) do
        local b = CreateFrame("Button", def[2], UIParent, "SecureActionButtonTemplate")
        b:SetSize(1, 1)
        b:SetPoint("CENTER")
        b:SetAlpha(0)
        b:EnableMouse(false)
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:Show()
        self:RegisterButton(def[1], b)
    end

    ns.RegisterEvents({ "BAG_UPDATE_DELAYED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
        "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" })
    local function refresh() if ns.UI then ns.UI:Refresh() end end
    ns:On("BAG_UPDATE_DELAYED", refresh)
    ns:On("SPELLS_CHANGED", function() Conjure:UpdateButtons() end)
    ns:On("LEARNED_SPELL_IN_TAB", function() Conjure:UpdateButtons() end)
    ns:On("PLAYER_ENTERING_WORLD", function() Conjure:UpdateButtons() end)
    ns:On("PLAYER_REGEN_ENABLED", function()
        if Conjure.pending then Conjure:UpdateButtons() end
        refresh()
    end)
    self:UpdateButtons()
end
