local MYINVENTORY_DEFAULT_OPTIONS = {
    ["Columns"]       = 12,
    ["Replace"]       = true,
    ["Bag"]           = "bar",
    -- ["BagSort"]       = true,
    ["Graphics"]      = "art",
    ["Count"]         = "free",
    ["HlItems"]       = true,
    ["Sort"]          = "realm",
    ["Search"]        = true,
    ["Token"]         = true,
    ["HlBags"]        = true,
    ["Freeze"]        = "sticky",
    ["NoEsc"]         = false,
    ["Lock"]          = false,
    ["Title"]         = true,
    ["Cash"]          = true,
    ["Buttons"]       = true,
    ["AIOI"]          = false,
    ["Reverse"]       = false,
    ["Border"]        = true,
    ["Cache"]         = nil,
    ["Player"]        = true,
    ["Scale"]         = false,
    ["Strata"]        = "DIALOG",
    ["Anchor"]        = "bottomright",
    ["BackColor"]     = {0.7,0,0,0},
    ["SlotColor"]     = nil,
    ["AmmoColor"]     = nil,
    ["EnchantColor"]  = nil,
    ["EngColor"]      = nil,
    ["HerbColor"]     = nil,
    ["KeyRingColor"]  = nil,
    ["Companion"]     = nil,
    ["MAXBAGSLOTS"]   = 36,
    ["_TOPOFFSET"]    = 28,
    ["_BOTTOMOFFSET"] = 20,
    ["_LEFTOFFSET"]   = 8,
    ["_RIGHTOFFSET"]  = 3,
}

MyInventory = LibStub("AceAddon-3.0"):NewAddon("MyInventory", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "MyBagsCore-2.0")
local MI_Dialog = LibStub("AceConfigDialog-3.0")
local MI_Cmd = LibStub("AceConfigCmd-3.0")
local MB_Core       = LibStub("MyBagsCore-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("MyBags")

function MyInventory:OnInitialize()
    self.name = "MyInventory"
    self.frameName = "MyInventoryFrame"
    self.defaults = MYINVENTORY_DEFAULT_OPTIONS
    self.totalBags = 5
    self.firstBag = 0
    self.anchorPoint = "BOTTOMRIGHT"
    self.anchorParent = "UIParent"
    self.anchorOffsetX = -5
    self.anchorOffsetY = 100
    self.isBank = false
    self.version = MB_Core:GetCoreVersion()
    self.db = LibStub("AceDB-3.0"):New("MyInventoryDB")
    local prof = self.db:GetCurrentProfile()
    if self.db.profiles[prof] and self.db.profiles[prof]["Columns"] and self.db.profiles[prof]["Columns"] > 0 then
    else
        self.db.profiles[prof] = self.defaults
    end
    self:RegisterChatCommand("mi", "MI_ChatCommand")
    self:RegisterChatCommand("myinventory", "MI_ChatCommand")
    self.options = {
        type = "group",
        args = {
            replace = {
                type = "toggle",
                name = "Replace",
                desc = "Set replacing of default bags",
                get = function(info)
                    return MyInventory.IsSet("Replace")
                end,
                set = function(info, val)
                    MyInventory:SetReplace()
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
                    return MyInventory.GetOpt("Freeze")
                end,
                set = function(info, val)
                    MyInventory:SetFreeze(val)
                end,
            },
            lock = {
                type = "toggle",
                name = "Lock",
                desc = "Keep the window from moving",
                get = function(info)
                    return MyInventory.IsSet("Lock")
                end,
                set = function(info, val)
                    MyInventory:SetLock()
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
                    return MyInventory.GetOpt("Columns")
                end,
                set = function(info, val)
                    MyInventory:SetColumns(val)
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
                    return MyInventory.GetOpt("Bag")
                end,
                set = function(info, val)
                    MyInventory:SetBagDisplay(val)
                end
            },
            --[[
            bagsort = {
                type = "toggle",
                name = "BagSort",
                desc = "Toggle bag sort button",
                get = function(info)
                    return MyInventory.IsSet("BagSort")
                end,
                set = function(info, val)
                    MyInventory:SetBagSort()
                end,
            },
            ]]
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
                    return MyInventory.GetOpt("Graphics")
                end,
                set = function(info, val)
                    MyInventory:SetGraphicsDisplay(val)
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
                    return MyInventory.GetOpt("Sort")
                end,
                set = function(info, val)
                    MyInventory.SetOpt("Sort", val)
                    MyInventory.Result("Sort: ", val)
                end,
            },
            search = {
                type = "toggle",
                name = "Search",
                desc = "Enable searchbox",
                get = function(info)
                    return MyInventory.GetOpt("Search")
                end,
                set = function(info, val)
                    MyInventory:SetSearch()
                end,
            },
            token = {
                type = "toggle",
                name = "Token",
                desc = "Show token frame",
                get = function(info)
                    return MyInventory.GetOpt("Token")
                end,
                set = function(info, val)
                    MyInventory:SetToken()
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
                        return MyInventory.GetOpt("HlItems")
                    end
                    if key == "bag" then
                        return MyInventory.GetOpt("HlBags")
                    end
                end,
                set = function(info, key, val)
                    MyInventory:SetHighlight(key)
                end,
            },
            noesc = {
                type = "toggle",
                name = "Escape",
                desc = "Remove frame from the list of UI managed files, to be used with freeze",
                get = function(info)
                    return MyInventory.GetOpt("NoEsc")
                end,
                set = function(info, val)
                    MyInventory:SetNoEsc()
                end,
            },
            title = {
                type = "toggle",
                name = "Title",
                desc = "Show/Hide the title",
                get = function(info)
                    return MyInventory.GetOpt("Title")
                end,
                set = function(info, val)
                    MyInventory:SetTitle()
                end,
            },
            cash = {
                type = "toggle",
                name = "Cash",
                desc = "Show/Hide the money display",
                get = function(info)
                    return MyInventory.GetOpt("Cash")
                end,
                set = function(info, val)
                    MyInventory:SetCash()
                end,
            },
            buttons = {
                type = "toggle",
                name = "Buttons",
                desc = "Show/Hide the close and lock buttons",
                get = function(info)
                    return MyInventory.GetOpt("Buttons")
                end,
                set = function(info, val)
                    MyInventory:SetButtons()
                end,
            },
            aioi = {
                type = "toggle",
                name = "AIOI",
                desc = "Toggle partial row placement at bottom left or upper right",
                get = function(info)
                    return MyInventory.GetOpt("AIOI")
                end,
                set = function(info, val)
                    MyInventory:SetAIOI()
                end,
            },
            reverse = {
                type = "toggle",
                name = "Reverse",
                desc = "Toggle order of bags (item order within bags is unchanged)",
                get = function(info)
                    return MyInventory.GetOpt("Reverse")
                end,
                set = function(info, val)
                    MyInventory:SetReverse()
                end,
            },
            quality = {
                type = "toggle",
                name = "Quality",
                desc = "Highlight items based on quality",
                get = function(info)
                    return MyInventory.GetOpt("Border")
                end,
                set = function(info, val)
                    MyInventory:SetBorder()
                end,
            },
            player = {
                type = "toggle",
                name = "Player",
                desc = "Show/Hide the offline player selection box",
                get = function(info)
                    return MyInventory.GetOpt("Player")
                end,
                set = function(info, val)
                    MyInventory:SetPlayerSel()
                end,
            },
            companion = {
                type = "toggle",
                name = "Companion",
                desc = "Open/close MyInventory with bank, mail and trade windows",
                get = function(info)
                    return MyInventory.GetOpt("Companion")
                end,
                set = function(info, val)
                    MyInventory:SetCompanion()
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
                    return MyInventory.GetOpt("Count")
                end,
                set = function(info, val)
                    MyInventory:SetCount(val)
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
                    return MyInventory.GetOpt("Scale")
                end,
                set = function(info, val)
                    MyInventory:SetScale(val)
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
                    return MyInventory.GetOpt("Strata")
                end,
                set = function(info, val)
                    MyInventory:SetStrata(val)
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
                    return MyInventory.GetOpt("Anchor")
                end,
                set = function(info, val)
                    MyInventory:SetAnchor(val)
                end,
            },
            tog = {
                type = "execute",
                name = "Toggle",
                desc = "Toggle the frame",
                guiHidden = true,
                func = function()
                    MyInventory:Toggle()
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
                        MyInventory:ResetSettings()
                    end
                    if key == "anchor" then
                        MyInventory:ResetAnchor()
                    end
                end
            },
--[[
            back = {
                type = "select",
                name = "back",
                desc = "Toggle window background options",
                values = {
                    ["default"] = "Semi-transparent minimalistic background",
                    ["art"] = "Blizzard style artwork",
                    ["none"] = "Disable background",
                },
                get = function(info)
                    return MyInventory.GetOpt("")
                end
            },
]]
        },
    }
end

function MyInventory:LoadDropDown()
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    if not dropDown then
        return
    end

    local dropDownButton = _G[self.frameName .. "CharSelectDropDownButton"]
    local last_this = _G["this"]
    _G["this"] = dropDownButton
    UIDropDownMenu_Initialize(dropDown, self.UserDropDown_Initialize)
    UIDropDownMenu_SetSelectedValue(dropDown, self:GetCurrentPlayer())
    UIDropDownMenu_SetWidth(dropDown, 140)
    _G["this"] = last_this
end

function MyInventory:UserDropDown_Initialize()
    local this = self or _G.this
    local chars = MyInventory:GetSortedCharList(MyInventory.GetOpt("Sort"))
    local frame = this:GetParent():GetParent()
    local selectedValue = MyInventory:GetCurrentPlayer()

    for i = 1, getn(chars) do
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

function MyInventory:UserDropDown_OnClick()
    local this = self or _G.this
    self = this.owner
    local dropDown = _G[self.frameName .. "CharSelectDropDown"]
    self.Player = this.value
    UIDropDownMenu_SetSelectedValue(dropDown, this.value)
    self:LayoutFrame()
end

function MyInventory:HookFunctions()
    MB_Core:HookFunctions(self)
    self:RawHook("ToggleBackpack", true)
    self:RawHook("OpenBackpack", true)
    self:RawHook("CloseBackpack", true)
end

function MyInventory:ToggleBackpack()
    if not self.GetOpt("Replace") then
        self.hooks.ToggleBackpack()
    else
        self:Toggle()
    end
end

function MyInventory:OpenBackpack()
    if not self.GetOpt("Replace") then
        self.hooks["OpenBackpack"]()
    else
        if MailFrame:IsVisible() then self.Companion = 1 end
        if self.frame:IsVisible() then self.holdOpen = 1 end
        self:Open()
    end
end

function MyInventory:CloseBackpack()
    if not self.GetOpt("Replace") then
        self.hooks.CloseBackpack()
    elseif not self.Freeze then
        self:Close()
    elseif self.Freeze == "sticky" then
        if self.holdOpen then
            self.holdOpen = nil
        else
            self:Close()
        end
    end
end

function MyInventory:CompanionOpen()
    self.Companion = 1
    self:OpenBackpack()
end

function MyInventory:CompanionClose()
    if self.Companion then -- if not true it is a duplicate event
        self.Companion = nil
        self:CloseBackpack()
    end
end

function MyInventory:BAG_UPDATE(event, bag)
    if self.isLive and (bag == -2 or (bag >= 0 and bag <= 4)) then
        self:LayoutFrame()
    end
end

function MyInventory:GetInfoFunc()
    if self.isLive then
        return self.GetInfoLive
    end
    if IsAddOnLoaded("DataStore_Containers") then
        return self.GetInfoDataStore
    end

    return self.GetInfoNone
end

function MyInventory:BagIDToInvSlotID(bag)
    if bag < 1 or bag > 4 then return nil end
    return ContainerIDToInventoryID(bag)
end

function MyInventory:IsBagSlotUsable(slot)
    if (slot >= 0 and slot <= 4 or slot == KEYRING_CONTAINER) then
        return true
    end
    return false
end

function MyInventory:MI_ChatCommand(input)
    if not input or input:trim() == "" then
        MI_Dialog:Open(self.name)
    else
        MI_Cmd.HandleCommand(MyInventory, "myinventory", self.name, input)
    end
end

function MyInventory:GetSortedCharList(sorttype, realm)
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
            for charname, _ in pairs(DataStore:GetCharacters(realmlist[i])) do
                if DataStore_Containers.Characters[DataStore:GetCharacter(charname, realmlist[i])] then
                    idx = idx + 1
                    result[idx] = charname .. L["CHARACTER_DELIMITOR"] .. realmlist[i]
                end
            end
        end
        local swapped
        local q, w
        local x_time, y_time;
        local max = idx - 1;
        local charName, realmName
        repeat
            swapped = 0
            for i = 1, max do
                q = result[i]
                w = result[i+1]
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
                    result[i+1] = q
                    swapped = 1
                end
            end
        until swapped == 0
    else
        result[1] = self:GetCurrentPlayer()
    end

    return result
end
