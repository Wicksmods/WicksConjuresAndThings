-- Wick's Conjures and Things
-- Portals.lua: the teleports and portals a mage actually has.
--
-- Destinations are read out of the spellbook rather than listed here.
-- Forever is Classic plus its own changes, so a table of cities written
-- into the addon is a guess that goes stale the first time the server
-- adds somewhere or moves a trainer. Reading the book also gets faction
-- right for free: an Alliance mage never had the Horde spells to find.
--
-- Naming is the one assumption left. A teleport is "Teleport: Somewhere"
-- and a portal is "Portal: Somewhere", which is how the client has
-- always named them and how the rest of this addon works too, matching
-- conjured items by name rather than by id.
--
-- Casting needs secure buttons, and a secure button's attributes cannot
-- be set in combat. That is no loss here, since neither spell is
-- castable in combat either, but the write still has to be deferred or
-- it throws: the same pending-until-regen dance Conjure.lua does.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local Core = WickCore
local D = Core.Dialect

local Portals = {}
ns.Portals = Portals

-- Which rune each kind eats. Portals take Rune of Portals, teleports
-- take Rune of Teleportation; both are already on the reagent list.
Portals.RUNE = {
    teleport = "Rune of Teleportation",
    portal   = "Rune of Portals",
}

local PREFIX = {
    teleport = "^Teleport:%s*(.+)$",
    portal   = "^Portal:%s*(.+)$",
}

-- ============================================================
-- Reading the book
-- ============================================================

local cache

-- Destinations, alphabetical, each with whichever of the two spells the
-- character knows. A mage below level 40 has teleports and no portals,
-- so a destination with only one half is normal, not an error.
function Portals:List()
    if cache then return cache end
    local byDest, order = {}, {}
    for _, spell in ipairs(D.SpellBookSpells()) do
        local name = spell.name
        if name then
            for kind, pattern in pairs(PREFIX) do
                local dest = name:match(pattern)
                if dest then
                    local row = byDest[dest]
                    if not row then
                        row = { dest = dest }
                        byDest[dest] = row
                        order[#order + 1] = dest
                    end
                    row[kind] = { name = name, icon = spell.icon, spellID = spell.spellID }
                end
            end
        end
    end
    table.sort(order)
    local out = {}
    for _, dest in ipairs(order) do out[#out + 1] = byDest[dest] end
    cache = out
    return out
end

-- The book only changes when something is learned or unlearned, so the
-- scan is cached until it does.
function Portals:Invalidate()
    cache = nil
    self:UpdateButtons()
    if ns.UI and ns.UI.RefreshPortals then ns.UI:RefreshPortals() end
end

function Portals:Any()
    return #self:List() > 0
end

-- Whether the character knows any spell of this kind. Teleports come at
-- twenty and portals at forty, so the two answers differ for most of a
-- mage's levelling.
function Portals:Knows(kind)
    for _, row in ipairs(self:List()) do
        if row[kind] then return true end
    end
    return false
end

-- How many of the rune this kind of spell eats. Counted per kind rather
-- than per destination: one rune stack covers every city.
function Portals:Runes(kind)
    local item = self.RUNE[kind]
    if not item then return 0 end
    return D.GetItemCount(item, false) or 0
end

-- Whether a rune is carried for this kind of spell. Reported rather
-- than enforced: the button stays clickable and the client gives the
-- real refusal, which is the one the player will recognise.
function Portals:HasRune(kind)
    return self:Runes(kind) > 0
end

-- ============================================================
-- Secure buttons
-- ============================================================
--
-- One button per destination row, left-click teleports and right-click
-- opens the portal, so a row is one control for both halves of the same
-- destination rather than two buttons that differ by one word.

local buttons = {}

function Portals:RegisterButton(dest, b)
    buttons[#buttons + 1] = { dest = dest, button = b }
    b:SetAttribute("type1", "spell")
    b:SetAttribute("type2", "spell")
    self:UpdateButtons()
end

-- Rows are pooled, so a button can be pointed at a different city as
-- the list is redrawn.
function Portals:Retarget(b, dest)
    for _, e in ipairs(buttons) do
        if e.button == b then e.dest = dest break end
    end
    self:UpdateButtons()
end

function Portals:Find(dest)
    for _, row in ipairs(self:List()) do
        if row.dest == dest then return row end
    end
end

function Portals:UpdateButtons()
    if InCombatLockdown() then self.pending = true return end
    self.pending = false
    for _, e in ipairs(buttons) do
        local row = e.dest and self:Find(e.dest)
        e.button:SetAttribute("spell1", (row and row.teleport and row.teleport.name) or "")
        e.button:SetAttribute("spell2", (row and row.portal and row.portal.name) or "")
    end
end

-- ============================================================
-- Lifecycle
-- ============================================================

function Portals:Init()
    if self.inited then return end
    self.inited = true
    -- Its own registration rather than relying on Conjure having gone
    -- first. LEARNED_SPELL_IN_TAB does not exist on Forever, where the
    -- register call is refused and SPELLS_CHANGED carries the news; on
    -- the legacy client both arrive.
    ns.RegisterEvents({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
        "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "BAG_UPDATE_DELAYED" })
    ns:On("SPELLS_CHANGED", function() Portals:Invalidate() end)
    ns:On("LEARNED_SPELL_IN_TAB", function() Portals:Invalidate() end)
    ns:On("PLAYER_ENTERING_WORLD", function() Portals:Invalidate() end)
    ns:On("PLAYER_REGEN_ENABLED", function()
        if Portals.pending then Portals:UpdateButtons() end
        -- Rows the panel could not build during the fight.
        if ns.UI and ns.UI.portalsPending then ns.UI:RefreshPortals() end
    end)
    ns:On("BAG_UPDATE_DELAYED", function()
        -- Rune counts, not the spell list, so no rescan.
        if ns.UI and ns.UI.RefreshPortals then ns.UI:RefreshPortals() end
    end)
end
