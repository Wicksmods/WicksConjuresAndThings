-- Wick's Conjures and Things
-- UI.lua: the compact strip and the details panel.
--
-- The strip is three segments: rations carried, the mana gem, and the
-- reagents. Clicking rations or the gem conjures more, using the same
-- secure buttons the keybinds drive. Everything else is in the tooltips
-- and in the panel a right-click opens.

local ADDON, ns = ...
if not WickCore then return end   -- said once in Core.lua
local Core = WickCore
local Chrome, R = Core.Chrome, Core.Restrict
local C = Chrome.Colors

local UI = {}
ns.UI = UI

local RED   = { 0.80, 0.30, 0.30, 1 }
local AMBER = { 0.85, 0.65, 0.25, 1 }
local BLANK = "Interface\\Icons\\INV_Misc_QuestionMark"

local function tint(fs, c) fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end

local function rationsColor(count, low)
    if count <= 0 then return RED end
    if count < low then return AMBER end
    return C.fel
end

local function rationLines(tt)
    local s = ns.Conjure:Summary()
    local low = ns.db and ns.db.profile.lowRations or 20
    tt:AddLine("Rations", 1, 1, 1)
    local c = rationsColor(s.rations, low)
    tt:AddLine(("%d conjured item%s carried"):format(s.rations, s.rations == 1 and "" or "s"), c[1], c[2], c[3])
    local stock = ns.Conjure:Stock()
    if #stock > 0 then
        tt:AddLine(" ")
        for i, it in ipairs(stock) do
            if i > 8 then tt:AddLine(("and %d more"):format(#stock - 8), 0.6, 0.6, 0.6) break end
            tt:AddDoubleLine(it.name, tostring(it.count), 0.83, 0.78, 0.63, 1, 1, 1)
        end
    end
    tt:AddLine(" ")
    local water = ns.Conjure:SpellFor("water")
    local food  = ns.Conjure:SpellFor("food")
    if water then tt:AddLine("Click to cast " .. water, 0.6, 0.6, 0.6, true) end
    if food then
        tt:AddLine("Right-click to cast " .. food, 0.6, 0.6, 0.6, true)
    elseif water then
        tt:AddLine("Right-click conjures food once you have learned it.", 0.6, 0.6, 0.6, true)
    end
    if not water and not food then
        tt:AddLine("You have not learned a conjure yet.", 0.6, 0.6, 0.6, true)
    end
end

local function gemLines(tt)
    local s = ns.Conjure:Summary()
    local spell = ns.Conjure:BestGem()
    tt:AddLine("Mana gem", 1, 1, 1)
    if not spell then
        tt:AddLine("Not learned yet.", 0.6, 0.6, 0.6)
        return
    end
    if s.gems > 0 then
        tt:AddLine(("%d carried"):format(s.gems), C.fel[1], C.fel[2], C.fel[3])
    else
        tt:AddLine("None carried", RED[1], RED[2], RED[3])
    end
    tt:AddLine(" ")
    tt:AddLine("Click to cast " .. spell, 0.6, 0.6, 0.6, true)
end

local function reagentLines(tt)
    tt:AddLine("Reagents", 1, 1, 1)
    local any = false
    for _, r in ipairs(ns.Conjure:Reagents()) do
        if r.count > 0 or r.name == "Arcane Powder" then
            any = true
            local c = r.count < r.low and AMBER or C.text
            tt:AddDoubleLine(r.label, tostring(r.count), 0.83, 0.78, 0.63, c[1], c[2], c[3])
        end
    end
    if not any then tt:AddLine("None carried", 0.6, 0.6, 0.6) end
end

-- ============================================================
-- Compact strip
-- ============================================================

local STRIP_H  = 26
local RATION_W = 84
local GEM_W    = 26
local REAGENT_W = 70
local PAD      = 6

function UI:BuildStrip()
    if self.strip then return self.strip end
    local db = ns.db and ns.db.profile
    local f = CreateFrame("Frame", "WicksConjuresStrip", UIParent)
    self.strip = f
    f:SetSize(PAD + RATION_W + GEM_W + REAGENT_W + 8 + PAD, STRIP_H)
    f:SetPoint("CENTER", 0, -280)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(s)
        -- A lock stops a nudge, not a deliberate move: shift overrides it.
        if Chrome:DragAllowed(db and db.stripLocked) then s:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        if db then db.strip = db.strip or {}; Chrome:SavePosition(s, db.strip) end
    end)
    f:SetScript("OnMouseUp", function(_, btn) if btn == "RightButton" then UI:Toggle() end end)
    if db and db.strip and db.strip.point then
        local w, h = f:GetWidth(), f:GetHeight()
        Chrome:RestorePosition(f, db.strip)
        f:SetSize(w, h)
    end
    f:Hide()

    local bg = Chrome:Texture(f, "BACKGROUND", C.voidBG); bg:SetAllPoints()
    Chrome:AddBorder(f)
    Chrome:AddBrackets(f)

    -- Rations: a secure button so a click conjures.
    local rations = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    rations:SetPoint("TOPLEFT", PAD, -2)
    rations:SetSize(RATION_W, STRIP_H - 4)
    rations:RegisterForClicks("AnyUp", "AnyDown")
    ns.Conjure:RegisterButton("water", rations, "food")
    rations.icon = rations:CreateTexture(nil, "ARTWORK")
    rations.icon:SetSize(16, 16); rations.icon:SetPoint("LEFT", 2, 0)
    rations.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    rations.text = Chrome:Text(rations, 11)
    rations.text:SetPoint("LEFT", rations.icon, "RIGHT", 5, 0)
    rations.text:SetPoint("RIGHT", -2, 0)
    rations.text:SetJustifyH("LEFT")
    rations.hl = rations:CreateTexture(nil, "HIGHLIGHT"); rations.hl:SetAllPoints()
    rations.hl:SetColorTexture(1, 1, 1, 0.10)
    rations:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP"); rationLines(GameTooltip); GameTooltip:Show()
    end)
    rations:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.rations = rations

    local gem = CreateFrame("Button", nil, f, "SecureActionButtonTemplate")
    gem:SetPoint("LEFT", rations, "RIGHT", 4, 0)
    gem:SetSize(GEM_W - 4, STRIP_H - 4)
    gem:RegisterForClicks("AnyUp", "AnyDown")
    ns.Conjure:RegisterButton("gem", gem)
    gem.icon = gem:CreateTexture(nil, "ARTWORK")
    gem.icon:SetAllPoints(); gem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    gem.count = Chrome:Text(gem, 9); gem.count:SetPoint("BOTTOMRIGHT", -1, 1)
    gem.hl = gem:CreateTexture(nil, "HIGHLIGHT"); gem.hl:SetAllPoints()
    gem.hl:SetColorTexture(1, 1, 1, 0.10)
    gem:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP"); gemLines(GameTooltip); GameTooltip:Show()
    end)
    gem:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.gem = gem

    local reagents = CreateFrame("Frame", nil, f)
    reagents:SetPoint("LEFT", gem, "RIGHT", 4, 0)
    reagents:SetSize(REAGENT_W, STRIP_H - 4)
    reagents:EnableMouse(true)
    reagents.text = Chrome:Text(reagents, 11)
    reagents.text:SetAllPoints()
    reagents.text:SetJustifyH("LEFT")
    reagents:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP"); reagentLines(GameTooltip); GameTooltip:Show()
    end)
    reagents:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.reagents = reagents

    f:SetScript("OnShow", function() UI:RefreshStrip() end)
    R:OnChange(function() if f:IsShown() then UI:RefreshStrip() end end)
    return f
end

function UI:ApplyStripVisibility()
    local db = ns.db and ns.db.profile
    local want = ns.isMage and db and db.showStrip ~= false
    if want then
        self:BuildStrip()
        self.strip:Show()
        self:RefreshStrip()
    elseif self.strip then
        self.strip:Hide()
    end
end

function UI:SetStripLocked(locked)
    local db = ns.db and ns.db.profile
    if db then db.stripLocked = locked and true or false end
    ns.A:Print(locked and "strip locked." or "strip unlocked: drag it into place, then /wcj lock.")
end

function UI:RefreshStrip()
    local f = self.strip
    if not f or not f.rations or not f:IsShown() then return end
    local s = ns.Conjure:Summary()
    local low = ns.db and ns.db.profile.lowRations or 20
    local stock = ns.Conjure:Stock()

    local firstRation
    for _, it in ipairs(stock) do
        if not it.isGem then firstRation = it break end
    end
    f.rations.icon:SetTexture((firstRation and firstRation.icon) or BLANK)
    f.rations.icon:SetDesaturated(s.rations == 0)
    f.rations.text:SetText(("%d ration%s"):format(s.rations, s.rations == 1 and "" or "s"))
    tint(f.rations.text, rationsColor(s.rations, low))

    local gemItem
    for _, it in ipairs(stock) do
        if it.isGem then gemItem = it break end
    end
    f.gem.icon:SetTexture((gemItem and gemItem.icon) or "Interface\\Icons\\INV_Misc_Gem_Sapphire_02")
    f.gem.icon:SetDesaturated(s.gems == 0)
    f.gem.icon:SetAlpha(s.gems > 0 and 1 or 0.4)
    f.gem.count:SetText(s.gems > 0 and tostring(s.gems) or "")
    f.gem:SetShown(ns.Conjure:BestGem() ~= nil)

    local powder
    for _, r in ipairs(ns.Conjure:Reagents()) do
        if r.name == "Arcane Powder" then powder = r end
    end
    if powder then
        f.reagents.text:SetText(("Powder %d"):format(powder.count))
        tint(f.reagents.text, powder.count < powder.low and AMBER or C.muted)
    else
        f.reagents.text:SetText("")
    end
end

-- ============================================================
-- Details panel
-- ============================================================

function UI:Build()
    if self.panel then return self.panel end
    local db = ns.db and ns.db.profile
    local p = Chrome:NewPanel("WicksConjuresPanel", {
        title = "Wick's Conjures and Things", width = 340, height = 260,
        closable = true, strata = "MEDIUM", db = db and db.window,
    })
    self.panel = p
    local ct = p.content

    local y = 0
    local head = Chrome:Heading(ct, "Carried"); head:SetPoint("TOPLEFT", 0, y)
    y = y - 20
    p.stockTop = y
    p.rows = {}
    p.empty = Chrome:Text(ct, 11, C.muted)
    p.empty:SetPoint("TOPLEFT", 0, y)
    p.empty:SetText("Nothing conjured yet.")

    p.reagentHead = Chrome:Heading(ct, "Reagents")
    p.reagentText = Chrome:Text(ct, 11, C.muted)
    p.reagentText:SetWidth(300)
    p.reagentText:SetJustifyH("LEFT")

    local kitBtn = Chrome:Button(ct, "Kit", 70, 20)
    kitBtn:SetPoint("BOTTOMRIGHT", 0, 0)
    kitBtn:SetScript("OnClick", function() ns.A.kit:Toggle() end)
    local optBtn = Chrome:Button(ct, "Options", 70, 20)
    optBtn:SetPoint("RIGHT", kitBtn, "LEFT", -6, 0)
    optBtn:SetScript("OnClick", function() ns.A:OpenOptions() end)
    local portalBtn = Chrome:Button(ct, "Portals", 70, 20)
    portalBtn:SetPoint("BOTTOMLEFT", 0, 0)
    portalBtn:SetScript("OnClick", function() UI:TogglePortals() end)
    local stripBtn = Chrome:Button(ct, "Strip", 70, 20)
    stripBtn:SetPoint("RIGHT", optBtn, "LEFT", -6, 0)
    stripBtn:SetScript("OnClick", function()
        if db then db.showStrip = not (db.showStrip ~= false) end
        UI:ApplyStripVisibility()
    end)

    p:SetScript("OnShow", function() UI:Refresh() end)
    R:OnChange(function() if p:IsShown() then UI:Refresh() end end)
    return p
end

-- ============================================================
-- Portals
-- ============================================================
--
-- A row per destination, left-click to teleport and right-click for the
-- portal, so one row is one place rather than two entries that differ
-- by a word. Rows are pooled and retargeted, since learning a city
-- mid-session reorders the list.

local ROW_H = 22

local function portalLines(tt, dest)
    local row = ns.Portals:Find(dest)
    if not row then return end
    tt:AddLine(row.dest, 1, 1, 1)
    for _, kind in ipairs({ "teleport", "portal" }) do
        local spell = row[kind]
        if spell then
            local runes = ns.Portals:Runes(kind)
            local c = runes > 0 and C.text or RED
            tt:AddDoubleLine(spell.name, ("%d rune%s"):format(runes, runes == 1 and "" or "s"),
                0.83, 0.78, 0.63, c[1], c[2], c[3])
        end
    end
    tt:AddLine(" ")
    if row.teleport then tt:AddLine("Click to teleport", 0.6, 0.6, 0.6, true) end
    if row.portal then
        tt:AddLine("Right-click to open a portal", 0.6, 0.6, 0.6, true)
    else
        tt:AddLine("Portals are learned at a higher level.", 0.6, 0.6, 0.6, true)
    end
end

function UI:BuildPortals()
    if self.portals then return self.portals end
    local db = ns.db and ns.db.profile
    local p = Chrome:NewPanel("WicksConjuresPortals", {
        title = "Wick's Portals", width = 260, height = 240,
        closable = true, strata = "MEDIUM", db = db and db.portalWindow,
    })
    self.portals = p
    local ct = p.content

    p.runes = Chrome:Text(ct, 11, C.muted)
    p.runes:SetPoint("TOPLEFT", 0, 0)
    p.rowTop = -20
    p.rows = {}
    p.empty = Chrome:Text(ct, 11, C.muted)
    p.empty:SetPoint("TOPLEFT", 0, p.rowTop)
    p.empty:SetWidth(220)
    p.empty:SetJustifyH("LEFT")

    p:SetScript("OnShow", function() UI:RefreshPortals() end)
    R:OnChange(function() if p:IsShown() then UI:RefreshPortals() end end)
    return p
end

function UI:TogglePortals()
    self:BuildPortals()
    self.portals:Toggle()
end

function UI:RefreshPortals()
    local p = self.portals
    if not p or not p:IsShown() then return end
    self.portalsPending = false
    local list = ns.Portals:List()

    p.runes:SetText(("Teleport runes %d   Portal runes %d")
        :format(ns.Portals:Runes("teleport"), ns.Portals:Runes("portal")))

    p.empty:SetShown(#list == 0)
    if #list == 0 then
        p.empty:SetText(ns.isMage
            and "No teleports learned yet. A mage picks the first up at level 20."
            or "Teleports and portals are a mage thing.")
    end

    local y = p.rowTop
    for i, row in ipairs(list) do
        local r = p.rows[i]
        if not r then
            -- A row is a secure button, and a secure button's attributes
            -- are locked for the duration of a fight. Neither a teleport
            -- nor a portal is castable in combat, so a row that cannot
            -- be built yet loses nothing by waiting for the fight to
            -- end; building it anyway throws.
            if InCombatLockdown() then
                UI.portalsPending = true
                break
            end
            r = CreateFrame("Button", nil, p.content, "SecureActionButtonTemplate")
            r:SetSize(220, ROW_H)
            r:RegisterForClicks("AnyUp", "AnyDown")
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 0, 0)
            r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            r.name = Chrome:Text(r, 11)
            r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
            r.right = Chrome:Text(r, 10, C.muted)
            r.right:SetPoint("RIGHT", 0, 0)
            r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints()
            r.hl:SetColorTexture(1, 1, 1, 0.10)
            r:SetScript("OnEnter", function(sf)
                GameTooltip:SetOwner(sf, "ANCHOR_RIGHT")
                portalLines(GameTooltip, sf.dest)
                GameTooltip:Show()
            end)
            r:SetScript("OnLeave", function() GameTooltip:Hide() end)
            p.rows[i] = r
            ns.Portals:RegisterButton(row.dest, r)
        end
        -- Pooled, so a row can be pointed somewhere else on a redraw.
        if r.dest ~= row.dest then
            r.dest = row.dest
            ns.Portals:Retarget(r, row.dest)
        end

        local art = (row.teleport and row.teleport.icon) or (row.portal and row.portal.icon)
        r.icon:SetTexture(art or BLANK)
        r.name:SetText(row.dest)

        -- What this row can do right now. A destination whose rune has
        -- run out is dimmed, because that is what stops the cast.
        local tele = row.teleport ~= nil and ns.Portals:HasRune("teleport")
        local port = row.portal ~= nil and ns.Portals:HasRune("portal")
        local parts = {}
        if row.teleport then parts[#parts + 1] = tele and "tele" or "|cff7f5555tele|r" end
        if row.portal then parts[#parts + 1] = port and "portal" or "|cff7f5555portal|r" end
        r.right:SetText(table.concat(parts, "  "))
        local live = tele or port
        r.icon:SetDesaturated(not live)
        r.icon:SetAlpha(live and 1 or 0.4)
        tint(r.name, live and C.text or C.muted)

        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, y)
        r:Show()
        y = y - ROW_H
    end
    for i = #list + 1, #p.rows do p.rows[i]:Hide() end
end

function UI:Init()
    self:ApplyStripVisibility()
end

function UI:Toggle()
    self:Build()
    self.panel:Toggle()
end

function UI:RefreshPanel()
    local p = self.panel
    if not p or not p.rows or not p:IsShown() then return end
    local stock = ns.Conjure:Stock()
    p.empty:SetShown(#stock == 0)
    local y = p.stockTop
    for i, it in ipairs(stock) do
        local r = p.rows[i]
        if not r then
            r = CreateFrame("Frame", nil, p.content)
            r:SetSize(300, 20)
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 0, 0)
            r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            r.name = Chrome:Text(r, 11)
            r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
            r.count = Chrome:Text(r, 11)
            r.count:SetPoint("RIGHT", 0, 0)
            p.rows[i] = r
        end
        r.icon:SetTexture(it.icon or BLANK)
        r.name:SetText(it.name)
        r.count:SetText(tostring(it.count))
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 0, y)
        r:Show()
        y = y - 20
    end
    for i = #stock + 1, #p.rows do p.rows[i]:Hide() end

    p.reagentHead:ClearAllPoints()
    p.reagentHead:SetPoint("TOPLEFT", 0, y - 8)
    p.reagentText:ClearAllPoints()
    p.reagentText:SetPoint("TOPLEFT", 0, y - 28)
    local parts = {}
    for _, r in ipairs(ns.Conjure:Reagents()) do
        parts[#parts + 1] = ("%s %d"):format(r.label, r.count)
    end
    p.reagentText:SetText(table.concat(parts, ", "))
end

function UI:Refresh()
    self:RefreshPanel()
    self:RefreshStrip()
end
