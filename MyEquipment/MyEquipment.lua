local MYBAGS_SLOTCOLOR      = { 0.5, 0.5, 0.5 }
local MYEQUIPMENT_SLOT      = {}

local SLOTNAMES             = {
    "HEADSLOT",
    "NECKSLOT",
    "SHOULDERSLOT",
    "BACKSLOT",
    "CHESTSLOT",
    "SHIRTSLOT",
    "TABARDSLOT",
    "WRISTSLOT",
    "HANDSSLOT",
    "WAISTSLOT",
    "LEGSSLOT",
    "FEETSLOT",
    "FINGER0SLOT",
    "FINGER1SLOT",
    "TRINKET0SLOT",
    "TRINKET1SLOT",
    "MAINHANDSLOT",
    "SECONDARYHANDSLOT",
	"RANGEDSLOT", -- Readded in WoW Classic
	"AMMOSLOT" -- Readded in WoW Classic
}

local MYEQUIPMENT_DEFAULT_OPTIONS = {
    ["Columns"]       = 7,
    ["Graphics"]      = "art",
    ["Lock"]          = false,
    ["NoEsc"]         = false,
    ["Title"]         = true,
    ["Cash"]          = true,
    ["Sort"]          = "realm",
    ["Buttons"]       = true,
    ["Border"]        = true,
    ["Cache"]         = nil,
    ["Player"]        = true,
    ["Scale"]         = false,
    ["Strata"]        = "DIALOG",
    ["Anchor"]        = "bottomright",
    ["BackColor"]     = {0.7,0,0,0},
    ["SlotColor"]     = nil,
    ["_TOPOFFSET"]    = 28,
    ["_BOTTOMOFFSET"] = 20,
    ["_LEFTOFFSET"]   = 8,
    ["_RIGHTOFFSET"]  = 3,
}

MyEquipment = LibStub("AceAddon-3.0"):NewAddon("MyEquipment", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "MyBagsCore-1.2")
local ME_Dialog = LibStub("AceConfigDialog-3.0")
local ME_Cmd = LibStub("AceConfigCmd-3.0")
local AC = LibStub("AceConsole-3.0")

-- Lua APIs
local pairs = pairs
local strlen, strsub, strfind, strtrim = string.len, string.sub, string.find, strtrim
local select = select
local tonumber = tonumber

-- WoW APIs
local _G = _G
local ChatEdit_InsertLink = ChatEdit_InsertLink
local CursorCanGoInSlot = CursorCanGoInSlot
local CursorUpdate = CursorUpdate
local DressUpItemLink = DressUpItemLink
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemCount = GetInventoryItemCount
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventorySlotInfo = GetInventorySlotInfo
local InRepairMode = InRepairMode
local IsControlKeyDown = IsControlKeyDown
local IsInventoryItemLocked = IsInventoryItemLocked
local IsShiftKeyDown = IsShiftKeyDown
local PaperDollItemSlotButton_OnClick = PaperDollItemSlotButton_OnClick
local PaperDollItemSlotButton_OnEvent = PaperDollItemSlotButton_OnEvent
local PaperDollItemSlotButton_OnModifiedClick = PaperDollItemSlotButton_OnModifiedClick
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonDesaturated = SetItemButtonDesaturated
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor
local SetTooltipMoney = SetTooltipMoney
local ShowInspectCursor = ShowInspectCursor
local UnitHasRelicSlot = UnitHasRelicSlot

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: 

local function tonum(val)
    return tonumber(val or 0)
end

local function ColorConvertHexToDigit(h)
    if (strlen(h) ~= 6) then
        return 0, 0, 0
    end

    local r = {
        a = 10,
        b = 11,
        c = 12,
        d = 13,
        e = 14,
        f = 15
    }

    return ((tonum(strsub(h, 1, 1)) or r[strsub(h, 1, 1)] or 0) * 16 + (tonum(strsub(h, 2, 2)) or r[strsub(h, 2, 2)] or 0)) / 255, 
        ((tonum(strsub(h, 3, 3)) or r[strsub(h, 3, 3)] or 0) * 16 + (tonum(strsub(h, 4, 4)) or r[strsub(h, 4, 4)] or 0)) / 255,
        ((tonum(strsub(h, 5, 5)) or r[strsub(h, 5, 5)] or 0) * 16 + (tonum(strsub(h, 6, 6)) or r[strsub(h, 6, 6)] or 0)) / 255
end

local function GetItemInfoFromLink(l)
    if (not l) then
        return
    end

    local c, t, id, il, n = select(3, strfind(l, "|cff(%x+)|H(%l+):(%-?%d+)([^|]+)|h%[(.-)%]|h|r"))
    return n, c, id .. il, id, t
end

local function tonum(val)
    return tonumber(val or 0)
end

function MyEquipment:OnInitialize()
    self.name = "MyEquipment"
    self.frameName = "MyEquipmentFrame"
    self.defaults = MYEQUIPMENT_DEFAULT_OPTIONS
    self.isEquipment = true
    self.anchorPoint = "BOTTOM"
    self.anchorParent = "UIParent"
    self.anchorOffsetX = -5
    self.anchorOffsetY = 100
    self.db = LibStub("AceDB-3.0"):New("MyEquipmentDB")
    local prof = self.db:GetCurrentProfile()
    if self.db.profiles[prof] and self.db.profiles[prof]["Columns"] and self.db.profiles[prof]["Columns"] > 0 then
    else
        self.db.profiles[prof] = self.defaults
    end
    self:RegisterChatCommand("mq", "ME_ChatCommand")
    self:RegisterChatCommand("myequip", "ME_ChatCommand")
    self:RegisterChatCommand("myequipment", "ME_ChatCommand")
    self.options = {
        type = "group",
        args = {
            lock = {
                type = "toggle",
                name = "Lock",
                desc = "Keep the window from moving",
                get = function(info)
                    return MyEquipment.IsSet("Lock")
                end,
                set = function(info, val)
                    MyEquipment:SetLock()
                end,
            },
            back = {
                type = "select",
                name = "Background",
                desc = "Toggle window background options",
                values = {
                    ["default"] = "Semi-transparent minimalistic background",
                    ["art"] = "Blizard style artwork",
                    ["none"] = "Disable background",
                },
                get = function(info)
                    return MyEquipment.GetOpt("Graphics")
                end,
                set = function(info, val)
                    MyEquipment:SetGraphicsDisplay(val)
                end,
            },
            cols = {
                type = "range",
                name = "Columns",
                desc = "Resize the frame",
                step = 1,
                min = 2,
                max = 24,
                softMin = 2,
                softMax = 24,
                get = function(info)
                    return MyEquipment.GetOpt("Columns")
                end,
                set = function(info, val)
                    MyEquipment:SetColumns(val)
                end,
            },
            sort = {
                type = "select",
                name = "Sort",
                desc = "Sort names in character list",
                values = {
                    ["realm"] = "Sort by realm names first",
                    ["char"] = "Sort by character names first",
                    ["update"] = "Sort by update times",
                },
                get = function(info)
                    return MyEquipment.GetOpt("Sort")
                end,
                set = function(info, val)
                    MyEquipment.SetOpt("Sort", val)
                    MyEquipment.Result("Sort: ", val)
                end,
            },
            noesc = {
                type = "toggle",
                name = "Escape",
                desc = "Remove frame from the list of UI managed files, to be used with freeze",
                get = function(info)
                    return MyEquipment.GetOpt("NoEsc")
                end,
                set = function(info, val)
                    MyEquipment:SetNoEsc()
                end,
            },
            title = {
                type = "toggle",
                name = "Title",
                desc = "Show/Hide the title",
                get = function(info)
                    return MyEquipment.GetOpt("Title")
                end,
                set = function(info, val)
                    MyEquipment:SetTitle()
                end,
            },
            cash = {
                type = "toggle",
                name = "Cash",
                desc = "Show/Hide the money display",
                get = function(info)
                    return MyEquipment.GetOpt("Cash")
                end,
                set = function(info, val)
                    MyEquipment:SetCash()
                end,
            },
            buttons = {
                type = "toggle",
                name = "Buttons",
                desc = "Show/Hide the close and lock buttons",
                get = function(info)
                    return MyEquipment.GetOpt("Buttons")
                end,
                set = function(info, val)
                    MyEquipment:SetButtons()
                end,
            },
            aioi = {
                type = "toggle",
                name = "AIOI",
                desc = "Toggle partial row placement at bottom left or upper right",
                get = function(info)
                    return MyEquipment.GetOpt("AIOI")
                end,
                set = function(info, val)
                    MyEquipment:SetAIOI()
                end,
            },
            quality = {
                type = "toggle",
                name = "Quality",
                desc = "Highlight items based on quality",
                get = function(info)
                    return MyEquipment.GetOpt("Border")
                end,
                set = function(info, val)
                    MyEquipment:SetBorder()
                end,
            },
            player = {
                type = "toggle",
                name = "Player",
                desc = "Show/Hide the offline player selection box",
                get = function(info)
                    return MyEquipment.GetOpt("Player")
                end,
                set = function(info, val)
                    MyEquipment:SetPlayerSel()
                end,
            },
            scale = {
                type = "range",
                name = "Scale",
                desc = "Sets the Scale for the frame",
                min = 0.2,
                max = 2.0,
                softMin = 0.2,
                softMax = 2.0,
                get = function(info)
                    return MyEquipment.GetOpt("Scale")
                end,
                set = function(info, val)
                    MyEquipment:SetScale(val)
                end,
            },
            strata = {
                type = "select",
                name = "Strata",
                desc = "Sets the Strata for the frame",
                values = {
                    ["BACKGROUND"] = "BACKGROUND",
                    ["LOW"] = "LOW",
                    ["MEDIUM"] = "MEDIUM",
                    ["HIGH"] = "HIGH",
                    ["DIALOG"] = "DIALOG",
                },
                get = function(info)
                    return MyEquipment.GetOpt("Strata")
                end,
                set = function(info, val)
                    MyEquipment:SetStrata(val)
                end,
            },
            anchor = {
                type = "select",
                name = "Anchor",
                desc = "Sets the anchor point for the frame",
                values = {
                    ["bottomleft"] = "Frame grows from bottom left",
                    ["bottomright"] = "Frame grows from bottom right",
                    ["topleft"] = "Frame grows from top left",
                    ["topright"] = "Frame grows from top right",
                },
                get = function(info)
                    return MyEquipment.GetOpt("Anchor")
                end,
                set = function(info, val)
                    MyEquipment:SetAnchor(val)
                end,
            },
            tog = {
                type = "execute",
                name = "Toggle",
                desc = "Toggle the frame",
                guiHidden = true,
                func = function()
                    MyEquipment:Toggle()
                end,
            },
            reset = {
                type = "multiselect",
                name = "Reset",
                desc = "Resets elements of the addon",
                guiHidden = true,
                values = {
                    ["settings"] = "Reset all settings to default",
                    ["anchor"] = "Reanchors the frame to it's default position",
                },
                get = function(info, key)
                    return true
                end,
                set = function(info, key, val)
                    if key == "settings" then
                        MyEquipment:ResetSettings()
                    end
                    if key == "anchor" then
                        MyEquipment:ResetAnchor()
                    end
                end
            },
        },
    }
end

function MyEquipment:OnEnable()
    MyEquipmentFramePortrait:SetTexture("Interface\\Addons\\MyBags\\Skin\\MyEquipmentPortrait")
    for key,value in pairs(SLOTNAMES) do -- Just in case Blizzard shuffles the slot name table around
        local slotId = GetInventorySlotInfo(value)
        MYEQUIPMENT_SLOT[slotId] = value
    end
end

function MyEquipment:Disable()
end

function MyEquipment:RegisterEvents()
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "LayoutFrameOnEvent")
    self:RegisterEvent("ITEM_LOCK_CHANGED",       "LayoutFrameOnEvent")
end

function MyEquipment:HookFunctions()
end

function MyEquipment:LoadDropDown()
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    local dropDownButton = _G[self.frameName .. "CharSelectDropDownButton"]
    if not dropDown then
        return
    end

    local last_this = _G["this"]
    _G["this"] = dropDownButton
    UIDropDownMenu_Initialize(dropDown, self.UserDropDown_Initialize)
    UIDropDownMenu_SetSelectedValue(dropDown, self:GetCurrentPlayer())
--  UIDropDownMenu_SetSelectedValue(dropDown, self.Player)
    UIDropDownMenu_SetWidth(dropDown, 140)
    _G["this"] = last_this
end

function MyEquipment:UserDropDown_Initialize()
    local this = self or _G.this
    local chars, charnum
    chars = MyEquipment:GetSortedCharList(MyEquipment.GetOpt("Sort"))
    charnum = #chars
    if (charnum == 0) then
        -- self.GetOpt("Player")
        return
    end

    local frame = this:GetParent():GetParent()
    local selectedValue = UIDropDownMenu_GetSelectedValue(this)

    for i = 1, charnum do
        local info = {
            ["text"] = chars[i],
            ["value"] = chars[i],
            ["func"] = frame.self.UserDropDown_OnClick,
            ["owner"] = frame.self,
            ["checked"] = nil,
        }
        if selectedValue == info.value then
            info.checked = 1
        end

        UIDropDownMenu_AddButton(info)
    end
end

function MyEquipment:UserDropDown_OnClick()
    local this = self or _G.this
    self = this.owner
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    self.Player = this.value
    UIDropDownMenu_SetSelectedValue(dropDown, this.value)
    self:LayoutFrame()
end

function MyEquipment:BAG_UPDATE() -- no bags here, move along
end

function MyEquipment:GetRelic(charID)
    if self.isLive then
        return UnitHasRelicSlot("player")
    else
        return nil
    end
end

function MyEquipment:GetInfoFunc()
    if self.isLive then
        return self.GetEquipInfoLive
--[[
    elseif IsAddOnLoaded("DataStore_Inventory") then
        return self.GetInfoDataStore
]]
    else
        return self.GetInfoNone
    end
end

function MyEquipment:GetEquipInfoLive(itemIndex)
    local itemLink = GetInventoryItemLink("player",itemIndex)
    local texture, count, ID, quality, readable = nil
    if itemLink or itemIndex == 0 then
        texture = GetInventoryItemTexture("player",itemIndex)
        count = GetInventoryItemCount("player",itemIndex)
        if itemIndex ~= 0 then
            quality = select(2, GetItemInfoFromLink(itemLink))
            ID = select(4, GetItemInfoFromLink(itemLink))
        end
    end

    local locked = IsInventoryItemLocked(itemIndex)
    return texture, count, ID, locked, quality, readable, nil
end

function MyEquipment:MyEquipmentItemSlotButton_OnLoad(widget)
    widget:RegisterForDrag("LeftButton")
    _G[widget:GetName()]:SetNormalTexture("Interface\\AddOns\\MyBags\\Skin\\Button")
    widget.UpdateTooltip = widget.MyEquipmentItemSlotButton_OnEnter
end

function MyEquipment:MyEquipmentItemSlotButton_OnEnter(widget)
    local text
    self:TooltipSetOwner(widget)
    if self.isLive then
        local hasItem, hasCooldown, repairCost = GameTooltip:SetInventoryItem("player", widget:GetID())
        if not hasItem then
            text = _G[MYEQUIPMENT_SLOT[tonum(strsub(widget:GetName(), 21))]]
            if widget.hasRelic then
                text = _G["RELICSLOT"]
            end

            GameTooltip:SetText(text)
        end

        if (InRepairMode() and repairCost and (repairCost > 0)) then
            GameTooltip:AddLine(REPAIR_COST, "", 1, 1, 1)
            SetTooltipMoney(GameTooltip, repairCost)
            GameTooltip:Show()
        elseif hasItem and IsControlKeyDown() then
            ShowInspectCursor()
        else
            CursorUpdate(widget)
        end
    else
        local _, count, ID, _, quality, _, name = self:GetInfo(widget:GetID())
        if ID and ID ~= "" then
            local hyperlink = self:GetHyperlink(ID)
            if hyperlink then
                GameTooltip:SetHyperlink(hyperlink)
            end

            if IsControlKeyDown() and hyperlink then
                ShowInspectCursor()
            end
        else
            text = _G[MYEQUIPMENT_SLOT[tonum(strsub(widget:GetName(), 21))]]
            if widget.hasRelic then
                text = _G["RELICSLOT"]
            end

            if name then -- it's a bleeding ammo slot
                text = name
                GameTooltip:SetText(text, ColorConvertHexToDigit(quality))
                if count >= 1000 then
                    GameTooltip:AddLine(count,1,1,1)
                    GameTooltip:Show()
                end
            else
                GameTooltip:SetText(text)
            end
        end
    end
end

function MyEquipment:MyEquipmentItemSlotButton_OnClick(widget, button)
    if self.isLive then
        PaperDollItemSlotButton_OnClick(widget, button)
    end
end

function MyEquipment:MyEquipmentItemSlotButton_OnModifiedClick(widget, button)
    if self.isLive then
        PaperDollItemSlotButton_OnModifiedClick(widget, button)
    else
        if (button == "LeftButton") then
            if (IsControlKeyDown()) then
                local ID = select(3, self:GetInfo(widget:GetID()))
                if DressUpItemLink and ID and ID ~= "" then
                    DressUpItemLink("item:"..ID)
                end
            elseif (IsShiftKeyDown()) then
                local ID = select(3, self:GetInfo(widget:GetID()))
                local hyperLink
                if ID then
                    hyperLink = self:GetHyperlink(ID)
                end

                if hyperLink then 
                    ChatEdit_InsertLink(hyperLink)
                end
            end
        end
    end
end

function MyEquipment:MyEquipmentItemSlotButton_OnDragStart(widget)
    if self.isLive then
        PaperDollItemSlotButton_OnClick(widget, "LeftButton", 1)
    end
end

function MyEquipment:MyEquipmentItemSlotButton_OnEvent(widget, event)
    if self.isLive then
        PaperDollItemSlotButton_OnEvent(widget, event)
    else
        if (event == "CURSOR_UPDATE") then
            if (CursorCanGoInSlot(widget:GetID())) then
                widget:LockHighlight()
            else
                widget:UnlockHighlight()
            end

            return
        end
    end
end

function MyEquipment:MyEquipmentItemSlotButton_OnUpdate(widget, elapsed)
    if (GameTooltip:IsOwned(widget)) and self.isLive then
        self:MyEquipmentItemSlotButton_OnEnter(widget)
    end
end

function MyEquipment:LayoutEquipmentFrame(self)
    local itemBase = "MyEquipmentSlotsItem"
    local texture, count, locked, quality, id
    local slotColor = ((self.GetOpt("SlotColor")) or MYBAGS_SLOTCOLOR)
    local charID = self:GetCurrentPlayer()
    local hasRelic = self:GetRelic(charID)
    local hideAmmo = false
    self.watchLock = false
    if self.aioiOrder and (hasRelic or hideAmmo) then
        self.curCol = self.curCol + 1
    end

    for key, value in pairs(SLOTNAMES) do
        local slot = GetInventorySlotInfo(value)
        local itemButton = _G[itemBase .. slot]
        --[[
        local itemButton
        if (_G[itemBase .. slot]) then
            itemButton = _G[itemBase .. slot]
        else
            itemButton = CreateFrame("Button", itemBase .. slot, self, "MyEquipmentItemButtonTemplate")
        end
        ]]
       -- AMMOSLOT readded in WoW Classic
		if value == "AMMOSLOT" and (hasRelic or hideAmmo) then
			itemButton:Hide()
			break
		end

        if self.curCol >= self.GetOpt("Columns") then
            self.curCol = 0
            self.curRow = self.curRow + 1
        end

        itemButton:Show()
        itemButton:ClearAllPoints()
        itemButton:SetPoint("TOPLEFT", self.frame:GetName(), "TOPLEFT", self:GetXY(self.curRow, self.curCol))
        self.curCol = self.curCol + 1
        texture, count, id, locked, quality = self:GetInfo(slot)
        if id and id ~= "" then
            itemButton.hasItem = 1
        end

        if self.isLive then
            local start, duration, enable = GetInventoryItemCooldown("player", slot)
            local cooldown = _G[itemButton:GetName() .. "Cooldown"]
            CooldownFrame_Set(cooldown, start, duration, enable)
            if duration > 0 and enable == 0 then
                SetItemButtonTextureVertexColor(itemButton, 0.4,0.4,0.4)
            end
        end

        if value == "RANGEDSLOT" and hasRelic then
            itemButton.hasRelic = 1
        end

        -- itemButton:SetNormalTexture(texture or "")
        SetItemButtonTexture(itemButton, (texture or ""))
        SetItemButtonCount(itemButton, count)
        SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5)
        if locked and locked ~= "" then
            itemButton:LockHighlight()
            self.watchLock = 1
        else
            itemButton:UnlockHighlight()
        end

        if quality and self.GetOpt("Border") then
            SetItemButtonNormalTextureVertexColor(itemButton, ColorConvertHexToDigit(quality))
        else
            SetItemButtonNormalTextureVertexColor(itemButton, unpack(slotColor))
        end
    end
end

function MyEquipment:ME_ChatCommand(input)
    if not input or strtrim(input) == "" then
        ME_Dialog:Open(self.name)
    else
        ME_Cmd.HandleCommand(MyEquipment, "myequipment", self.name, input)
    end
end

function MyEquipment:GetSortedCharList(sorttype, realm)
    local result = {}
--[[
    if IsAddOnLoaded("DataStore_Inventory") then
        local realmname
        local realmlist = {}
        local realmcount = 0
        if not realm then
            for realmname in pairs(DataStore:GetRealms()) do
                realmcount = realmcount + 1
                realmlist[realmcount] = realmname
            end
        else
            realmcount = 1
            realmlist[1] = realm
        end
        local idx = 0
        local i
        local charname, charkey
        for i=1, realmcount do
            for charname, charkey in pairs(DataStore:GetCharacters(realmlist[i])) do
                -- charkey = DataStore:GetCharacter(charname, realmlist[i])
                if DataStore_Inventory.Characters[charkey] then
                    idx = idx + 1
                    result[idx] = charname .. L["CHARACTER_DELIMITOR"] .. realmlist[i]
                end
            end
        end
        local swapped
        local q, w
        local x_time, y_time
        local charName, realmName
        repeat
            swapped = 0
            for i = 1, idx-1 do
                q = result[i]
                w = result[i+1]
                charName, realmName = self:SplitString(q)
                if (not DataStore:GetModuleLastUpdate(DataStore_Inventory, charName, realmName)) then
                    x_time = 0
                else
                    x_time = DataStore:GetModuleLastUpdate(DataStore_Inventory, charName, realmName)
                end
                charName, realmName = self:SplitString(w)
                if (not DataStore:GetModuleLastUpdate(DataStore_Inventory, charName, realmName)) then
                    y_time = 0
                else
                    y_time = DataStore:GetModuleLastUpdate(DataStore_Inventory, charName, realmName)
                end
                if self:SortChars(q, w, x_time, y_time, sorttype) then
                    result[i] = w
                    result[i+1] = q
                    swapped = 1
                end
            end
        until swapped == 0
    end
]]
    result[1] = self:GetCurrentPlayer()

    return result
end
