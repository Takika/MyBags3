local MYBANK_DEFAULT_OPTIONS = {
    ["Columns"]       = 14,
    ["Replace"]       = true,
    ["Bag"]           = "bar",
    -- ["BagSort"]       = true,
    ["Graphics"]      = "art",
    ["Count"]         = "free",
    ["HlItems"]       = true,
    ["Sort"]          = "realm",
    ["Search"]        = true,
    ["HlBags"]        = true,
    ["Freeze"]        = "sticky",
    ["Lock"]          = false,
    ["NoEsc"]         = false,
    ["Title"]         = true,
    ["Cash"]          = true,
    ["Buttons"]       = true,
    ["AIOI"]          = false,
    ["Border"]        = true,
    ["Cache"]         = nil,
    ["Player"]        = true,
    ["Scale"]         = false,
    ["Strata"]        = "DIALOG",
    ["Anchor"]        = "bottomleft",
    ["BackColor"]     = {0.7,0,0,0},
    ["SlotColor"]     = nil,
    ["AmmoColor"]     = nil,
    ["EnchantColor"]  = nil,
    ["EngColor"]      = nil,
    ["HerbColor"]     = nil,
    ["MAXBAGSLOTS"]   = 36,
    ["_TOPOFFSET"]    = 28,
    ["_BOTTOMOFFSET"] = 20,
    ["_LEFTOFFSET"]   = 8,
    ["_RIGHTOFFSET"]  = 3,
}

MyBank = LibStub("AceAddon-3.0"):NewAddon("MyBank", "MyBagsCore-2.0", "AceHook-3.0", "AceEvent-3.0", "AceConsole-3.0")
-- local MB_Config = LibStub("AceConfig-3.0")
local MB_Dialog = LibStub("AceConfigDialog-3.0")
local MB_Cmd    = LibStub("AceConfigCmd-3.0")
local MB_Core   = LibStub("MyBagsCore-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MyBags")

-- Lua APIs
local pairs = pairs
local strtrim = strtrim

-- WoW APIs
local _G = _G
local CloseBackpack = CloseBackpack
local IsBagOpen = IsBagOpen
local MoneyFrame_Update = MoneyFrame_Update
local OpenBackpack = OpenBackpack
-- local PlaySound = PlaySound
local SetPortraitTexture = SetPortraitTexture
-- local SortBankBags = SortBankBags
local ToggleBackpack = ToggleBackpack

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: 

function MyBank:OnInitialize()
    self.name = "MyBank"
    self.frameName = "MyBankFrame"
    self.defaults = MYBANK_DEFAULT_OPTIONS
    self.totalBags = 7
    self.firstBag = 5
    self.isBank = true
    self.atBank = false
    self.saveBankFrame = BankFrame
    self.anchorPoint = "BOTTOMLEFT"
    self.anchorParent = "UIParent"
    self.anchorOffsetX = 5
    self.anchorOffsetY = 100
    self.db = LibStub("AceDB-3.0"):New("MyBankDB")
    local prof = self.db:GetCurrentProfile()
    if self.db.profiles[prof] and self.db.profiles[prof]["Columns"] and self.db.profiles[prof]["Columns"] > 0 then
    else
        self.db.profiles[prof] = self.defaults
    end

    self:RegisterChatCommand("mb", "MB_ChatCommand")
    self:RegisterChatCommand("mybank", "MB_ChatCommand")
    self.options = {
        type = "group",
        args = {
            replace = {
                type = "toggle",
                name = "Replace",
                desc = "Set replacing of default bags",
                get = function(info)
                    return MyBank.IsSet("Replace")
                end,
                set = function(info, val)
                    MyBank:SetReplace()
                end,
            },
            freeze = {
                type = "select",
                name = "Freeze",
                desc = "Keep window from closing when you leave vendors or bank",
                values = {
                    ["always"] = "Always leave the bag open",
                    ["sticky"] = "Only leave open if manually opened",
                    ["none"] = "Let the UI close the window",
                },
                get = function(info)
                    return MyBank.GetOpt("Freeze")
                end,
                set = function(info, val)
                    MyBank:SetFreeze(val)
                end,
            },
            lock = {
                type = "toggle",
                name = "Lock",
                desc = "Keep the window from moving",
                get = function(info)
                    return MyBank.IsSet("Lock")
                end,
                set = function(info, val)
                    MyBank:SetLock()
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
                    return MyBank.GetOpt("Columns")
                end,
                set = function(info, val)
                    MyBank:SetColumns(val)
                end,
            },
            bag = {
                type = "select",
                name = "Bag",
                desc = "Toggle between bag button view options",
                values = {
                    ["bar"] = "Bags are displayed as a bar on top of the frame",
                    ["before"] = "Bag icons are places in the frame before bag slots",
                    ["none"] = "Bags are hidden from the frame",
                },
                get = function(info)
                    return MyBank.GetOpt("Bag")
                end,
                set = function(info, val)
                    MyBank:SetBagDisplay(val)
                end,
            },
            --[[
            bagsort = {
                type = "toggle",
                name = "BagSort",
                desc = "Toggle bag sort button",
                get = function(info)
                    return MyBank.IsSet("BagSort")
                end,
                set = function(info, val)
                    MyBank:SetBagSort()
                end,
            },
            ]]
            back = {
                type = "select",
                name = "Background",
                desc = "Toggle window background options",
                values = {
                    ["default"] = "Semi-transparent minimalistic background",
                    ["art"] = "Blizzard style artwork",
                    ["none"] = "Disable background",
                },
                get = function(info)
                    return MyBank.GetOpt("Graphics")
                end,
                set = function(info, val)
                    MyBank:SetGraphicsDisplay(val)
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
                    return MyBank.GetOpt("Sort")
                end,
                set = function(info, val)
                    MyBank.SetOpt("Sort", val)
                    MyBank.Result("Sort: ", val)
                end,
            },
            search = {
                type = "toggle",
                name = "Search",
                desc = "Enable searchbox",
                get = function(info)
                    return MyBank.GetOpt("Search")
                end,
                set = function(info, val)
                    MyBank:SetSearch()
                end,
            },
            highlight = {
                type = "multiselect",
                name = "Hilight",
                desc = "Toggle Highlighting options",
                values = {
                    ["items"] = "Highlight items when you mouse over bag slots",
                    ["bag"] = "Highlight bag when you mouse over an item",
                },
                get = function(info, key)
                    if key == "items" then
                        return MyBank.GetOpt("HlItems")
                    end
                    if key == "bag" then
                        return MyBank.GetOpt("HlBags")
                    end
                end,
                set = function(info, key, val)
                    MyBank:SetHighlight(key)
                end,
            },
            noesc = {
                type = "toggle",
                name = "Escape",
                desc = "Remove frame from the list of UI managed files, to be used with freeze",
                get = function(info)
                    return MyBank.GetOpt("NoEsc")
                end,
                set = function(info, val)
                    MyBank:SetNoEsc()
                end,
            },
            title = {
                type = "toggle",
                name = "Title",
                desc = "Show/Hide the title",
                get = function(info)
                    return MyBank.GetOpt("Title")
                end,
                set = function(info, val)
                    MyBank:SetTitle()
                end,
            },
            cash = {
                type = "toggle",
                name = "Cash",
                desc = "Show/Hide the money display",
                get = function(info)
                    return MyBank.GetOpt("Cash")
                end,
                set = function(info, val)
                    MyBank:SetCash()
                end,
            },
            buttons = {
                type = "toggle",
                name = "Buttons",
                desc = "Show/Hide the close and lock buttons",
                get = function(info)
                    return MyBank.GetOpt("Buttons")
                end,
                set = function(info, val)
                    MyBank:SetButtons()
                end,
            },
            aioi = {
                type = "toggle",
                name = "AIOI",
                desc = "Toggle partial row placement at bottom left or upper right",
                get = function(info)
                    return MyBank.GetOpt("AIOI")
                end,
                set = function(info, val)
                    MyBank:SetAIOI()
                end,
            },
            reverse = {
                type = "toggle",
                name = "Reverse",
                desc = "Toggle order of bags (item order within bags is unchanged)",
                get = function(info)
                    return MyBank.GetOpt("Reverse")
                end,
                set = function(info, val)
                    MyBank:SetReverse()
                end,
            },
            quality = {
                type = "toggle",
                name = "Quality",
                desc = "Highlight items based on quality",
                get = function(info)
                    return MyBank.GetOpt("Border")
                end,
                set = function(info, val)
                    MyBank:SetBorder()
                end,
            },
            player = {
                type = "toggle",
                name = "Player",
                desc = "Show/Hide the offline player selection box",
                get = function(info)
                    return MyBank.GetOpt("Player")
                end,
                set = function(info, val)
                    MyBank:SetPlayerSel()
                end,
            },
            count = {
                type = "select",
                name = "Count",
                desc = "Toggles between item count display modes",
                values = {
                    ["free"] = "Count free slots",
                    ["used"] = "Count used slots",
                    ["none"] = "Disable slot display",
                },
                get = function(info)
                    return MyBank.GetOpt("Count")
                end,
                set = function(info, val)
                    MyBank:SetCount(val)
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
                    return MyBank.GetOpt("Scale")
                end,
                set = function(info, val)
                    MyBank:SetScale(val)
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
                    return MyBank.GetOpt("Strata")
                end,
                set = function(info, val)
                    MyBank:SetStrata(val)
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
                    return MyBank.GetOpt("Anchor")
                end,
                set = function(info, val)
                    MyBank:SetAnchor(val)
                end,
            },
            tog = {
                type = "execute",
                name = "Toggle",
                desc = "Toggle the frame",
                guiHidden = true,
                func = function()
                    MyBank:Toggle()
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
                        MyBank:ResetSettings()
                    end
                    if key == "anchor" then
                        MyBank:ResetAnchor()
                    end
                end
            },
        },
    }
end

function MyBank:OnEnable()
--    MyBagsCore:Enable(self)
    MyBankFrameBank.maxIndex = 28
    MyBankFrameBank:SetID(BANK_CONTAINER)
    MyBankFrameBag0:SetID(5)
    MyBankFrameBag1:SetID(6)
    MyBankFrameBag2:SetID(7)
    MyBankFrameBag3:SetID(8)
    MyBankFrameBag4:SetID(9)
    MyBankFrameBag5:SetID(10)
    MyBankFrameBag6:SetID(11)

    if self.GetOpt("Replace") then
        BankFrame:UnregisterEvent("BANKFRAME_OPENED")
        BankFrame:UnregisterEvent("BANKFRAME_CLOSED")
    end

    self:RegisterEvent("BANKFRAME_OPENED")

    MyBankFramePortrait:SetTexture("Interface\\Addons\\MyBags\\Skin\\MyBankPortrait")
    StaticPopupDialogs["PURCHASE_BANKBAG"] = {
        preferredIndex = STATICPOPUPS_NUMDIALOGS,
        text = CONFIRM_BUY_BANK_SLOT,
        button1 = YES,
        button2 = NO,
        OnAccept = function(self)
            if CT_oldPurchaseSlot then
                CT_oldPurchaseSlot()
            else
                PurchaseSlot()
            end;
        end,
        OnShow = function(self)
            MoneyFrame_Update(self:GetName() .. "MoneyFrame", GetBankSlotCost());
        end,
        showAlert = 1,
        hasMoneyFrame = 1,
        timeout = 0,
        hideOnEscape = 1,
    }
end

function MyBank:MB_ChatCommand(input)
    if not input or strtrim(input) == "" then
        MB_Dialog:Open(self.name)
    else
        input = strtrim(input)
        MB_Cmd.HandleCommand(MyBank, "mybank", self.name, input)
    end
end

function MyBank:Disable()
    BankFrame = self.saveBankFrame
    BankFrame:RegisterEvent("BANKFRAME_OPENED")
    BankFrame:RegisterEvent("BANKFRAME_CLOSED")
end

function MyBank:LoadDropDown()
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    local dropDownButton = _G[self.frameName .. "CharSelectDropDownButton"]
    if not dropDown then
        return
    end

    local last_this = _G["this"]
    _G["this"] = dropDownButton
    UIDropDownMenu_Initialize(dropDown, self.UserDropDown_Initialize)
    UIDropDownMenu_SetSelectedValue(dropDown, self:GetCurrentPlayer())
    UIDropDownMenu_SetWidth(dropDown, 140)
    _G["this"] = last_this
end

function MyBank:UserDropDown_Initialize()
    local this = self or _G.this
    local chars, char_num
    chars = MyBank:GetSortedCharList(MyBank.GetOpt("Sort"))
    char_num = #chars
    if (char_num == 0) then
        -- MyBank.GetOpt("Player")
        return
    end

    local frame = this:GetParent():GetParent()
    local selectedValue = UIDropDownMenu_GetSelectedValue(this)
    
    for i = 1, char_num do
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

function MyBank:UserDropDown_OnClick()
    local this = self or _G.this
    self = this.owner
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    self.Player = this.value
    UIDropDownMenu_SetSelectedValue(dropDown, this.value)
    self:LayoutFrame()
end

function MyBank:RegisterEvents()
    MB_Core:RegisterEvents(self)
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED",   "LayoutFrameOnEvent")
    self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED","LayoutFrameOnEvent")
    self:RegisterEvent("BANKFRAME_CLOSED")
end

function MyBank:UnregisterEvents()
    MB_Core:UnregisterEvents(self)
    self:RegisterEvent("BANKFRAME_OPENED")
end

function MyBank:HookFunctions()
    MB_Core:HookFunctions(self)
    self:RawHook("ToggleAllBags", true)
    self:RawHook("CloseAllBags", true)
end

function MyBank:ToggleAllBags(forceopen)
    if forceopen then 
        OpenBackpack()
    else
        ToggleBackpack()
    end

    local action
    if (IsBagOpen(0) or MyInventory.frame:IsVisible()) then 
        action = "OpenBag" 
    else 
        action = "CloseBag" 
    end

    for i = 1, 4, 1 do
        if not MyInventory.GetOpt("Replace") then
            self.hooks[action](i)
        end
    end

    for i = 5, 11, 1 do
        if not MyBank.GetOpt("Replace") then
            self.hooks[action](i)
        end
    end
end

function MyBank:CloseAllBags()
    MyInventory:Close()
    CloseBackpack() -- just in case backpack is not contolled by MyInventory
    for i = 1, 4, 1 do
        if not MyInventory.GetOpt("Replace") then
            self.hooks.CloseBag(i)
        end
    end

    for i = 5, 11, 1 do
        if not MyBank.GetOpt("Replace") then
            self.hooks.CloseBag(i)
        end
    end
end

function MyBank:BAG_UPDATE(event, bag)
    if self.isLive and (bag == -1 or (bag >= 5 and bag <= 11)) then
        self:LayoutFrame()
    end
end

function MyBank:BANKFRAME_OPENED()
    self:RegisterEvents()
    MyBank.atBank = true
    SetPortraitTexture(MyBankFramePortrait, "npc")
    if self.Freeze == "always" or (self.Freeze == "sticky" and self.frame:IsVisible()) then
        self.holdOpen = true
    else
        self.holdOpen = false
    end

    if self.GetOpt("Replace") then
        self:Open()
    else
        self:LayoutFrame()
    end
end

function MyBank:BANKFRAME_CLOSED()
    MyBank.atBank = false
    MyBankFramePortrait:SetTexture("Interface\\Addons\\MyBags\\Skin\\MyBankPortrait")
    if self.GetOpt("Replace") and not self.holdOpen then
        if self.frame:IsVisible() then 
            self.frame:Hide()
        end -- calling self:close() would trigger the bank closing twice
    else
        self.holdOpen = false
        if self.isLive then
            self:LayoutFrame()
        end
    end

    self:UnregisterEvents()
end

function MyBank:GetInfoFunc()
    if self.isLive then
        return self.GetInfoLive
    end

    if IsAddOnLoaded("DataStore_Containers") then
        return self.GetInfoDataStore
    end

    return self.GetInfoNone
end

function MyBank:GetSortedCharList(sorttype, realm)
    local result = {}

    if IsAddOnLoaded("DataStore_Containers") then
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
        for i = 1, realmcount do
            for charname, charkey in pairs(DataStore:GetCharacters(realmlist[i])) do
                -- charkey = DataStore:GetCharacter(charname, realmlist[i])
                if DataStore_Containers.Characters[charkey] then
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
            for i = 1, idx - 1 do
                q = result[i]
                w = result[i + 1]
                charName, realmName = self:SplitString(q)
                if (not DataStore:GetModuleLastUpdate(DataStore_Containers, charName, realmName)) then
                    x_time = 0
                else
                    x_time = DataStore:GetModuleLastUpdate(DataStore_Containers, charName, realmName)
                end

                charName, realmName = self:SplitString(w)
                if (not DataStore:GetModuleLastUpdate(DataStore_Containers, charName, realmName)) then
                    y_time = 0
                else
                    y_time = DataStore:GetModuleLastUpdate(DataStore_Containers, charName, realmName)
                end

                if self:SortChars(q, w, x_time, y_time, sorttype) then
                    result[i] = w
                    result[i + 1] = q
                    swapped = 1
                end
            end
        until swapped == 0
    else
        result[1] = self:GetCurrentPlayer()
    end

    return result
end

function MyBank:SetReplace()
    self.TogMsg("Replace", "Replace default bags")
    self:LayoutFrame()
    if self.GetOpt("Replace") then
        BankFrame:UnregisterEvent("BANKFRAME_OPENED")
        BankFrame:UnregisterEvent("BANKFRAME_CLOSED")
        _G["BankFrame"] = self.frame
    else
        _G["BankFrame"] = self.saveBankFrame
        BankFrame:RegisterEvent("BANKFRAME_OPENED")
        BankFrame:RegisterEvent("BANKFRAME_CLOSED")
    end
end

--[[
function MyBank:SortBags()
  PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
  SortBankBags()
end
]]