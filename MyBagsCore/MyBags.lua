local MBC = "MyBagsCore-1.0"
local MBC_MINOR = "2014.02.11.3"
if not LibStub then error(MBC .. " requires LibStub.") end
local MyBagsCore = LibStub:NewLibrary(MBC, MBC_MINOR)
if not MyBagsCore then return end

MyBagsCore.embeds = MyBagsCore.embeds or {} -- table containing objects MyBagsCore is embedded in. 

local AC = LibStub("AceConsole-3.0");
assert(AC, MBC .. " requires AceConsole-3.0");

local MYBAGS_BOTTOMOFFSET = 20
local MYBAGS_COLWIDTH     = 40
local MYBAGS_ROWHEIGHT    = 40

local MYBAGS_MAXBAGSLOTS  = 28

local MIN_SCALE_VAL 	= "0.2"
local MAX_SCALE_VAL 	= "2.0"

local MYBAGS_SLOTCOLOR     = { 0.5, 0.5, 0.5 }
local MYBAGS_AMMOCOLOR     = { 0.6, 0.6, 0.1 }
local MYBAGS_SHARDCOLOR    = { 0.6, 0.3, 0.6 }
local MYBAGS_ENCHANTCOLOR  = { 0.2, 0.2, 1.0 }
local MYBAGS_ENGINEERCOLOR = { 0.6, 0.0, 0.0 }
local MYBAGS_HERBCOLOR     = { 0.0, 0.6, 0.0 }
local MYBAGS_GEMCOLOR      = { 0.0, 0.6, 0.6 }
local MYBAGS_MININGCOLOR   = { 0.0, 0.0, 0.6 }

local	ACEG_MAP_ONOFF = {[0]="|cffff5050Off|r",[1]="|cff00ff00On|r"}

local L = LibStub("AceLocale-3.0"):GetLocale("MyBags")

local pcall, error, pairs = pcall, error, pairs
local strfind = string.find

local mb_options = {
	type = "group",
	args = {
	},
}

local function tostr(str)
	return tostring(str or "")
end

local function tonum(val)
	return tonumber(val or 0)
end

local function ColorConvertHexToDigit(h)
	if (strlen(h) ~= 6) then
		return 0, 0, 0
	end
	local r = {a=10, b=11, c=12, d=13, e=14, f=15}
	return ((tonumber(strsub(h,1,1)) or r[strsub(h,1,1)] or 0) * 16 + (tonumber(strsub(h,2,2)) or r[strsub(h,2,2)] or 0))/255, 
		((tonumber(strsub(h,3,3)) or r[strsub(h,3,3)] or 0) * 16 + (tonumber(strsub(h,4,4)) or r[strsub(h,4,4)] or 0))/255,
		((tonumber(strsub(h,5,5)) or r[strsub(h,5,5)] or 0) * 16 + (tonumber(strsub(h,6,6)) or r[strsub(h,6,6)] or 0))/255
end

local function GetItemInfoFromLink(l)
	if (not l) then
	    return
	end
	local c, t, id, il, n = select(3, strfind(l, "|cff(%x+)|H(%l+):(%-?%d+)([^|]+)|h%[(.-)%]|h|r"))
    return n, c, id .. il, id, t

    --[[
    print("c: " .. c .. ", t: " .. t .. ", id: " .. id .. ", il: " .. il .. ", n: " .. n)

	if (strfind(l, "Hitem")) then
	    c, id ,il, n = select(3, strfind(l, "|cff(%x+)|Hitem:(%-?%d+)([^|]+)|h%[(.-)%]|h|r"))
	    t = "item"
    else
    	if (strfind(l, "Hbattlepet")) then
    	    c, id ,il, n = select(3, strfind(l, "|cff(%x+)|Hbattlepet:(%-?%d+)([^|]+)|h%[(.-)%]|h|r"))
    	    t = "battlepet"
    	end
	end
	return n, c, id .. il, id
	]]
end


local function GetBattlePetInfoFromLink(l)
    if (not l) then
        return
    end

    local c, id, lvl, num, hp, pw, sp, u, n
    if (strfind(l, "Hbattlepet")) then
        -- "|cff0070dd|Hbattlepet:1178:1:3:152:13:10:0x0000000000000000|h[Sunreaver Micro-Sentry]|h|r"
        c, id, lvl, rar, hp, pw, sp, u, n = select(3, strfind(l, "|cff(%x+)|Hbattlepet:(%-?%d+):(%d+):(%d+):(%d+):(%d+):(%d+):([^|]+)|h%[(.-)%]|h|r"))
    end

    return tonum(id), tonum(lvl), tonum(rar), tonum(hp), tonum(pw), tonum(sp), n
end



local function IsSpecialtyBag(itype, isubtype)
	if (strlower(itype or "") == strlower(L["ACEG_TEXT_AMMO"])) then
	    return 1
	end
	if (strlower(itype or "") == strlower(L["ACEG_TEXT_QUIVER"])) then
	    return 2
	end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_SOUL"])) then
	    return 3
	end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_ENCHANT"])) then
	    return 4
	end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_ENGINEER"])) then
	    return 5
    end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_HERB"])) then
	    return 6
	end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_GEM"])) then
	    return 7
	end
	if (strlower(isubtype or "") == strlower(L["ACEG_TEXT_MINING"])) then
	    return 8
	end
end

local function IsSpecialtyBagFromLink(b)
	local i = select(4, GetItemInfoFromLink(b))
	if (not i) then return end
	local c, d = select(6, GetItemInfo(i))
	return IsSpecialtyBag(c, d)
end

local function IsSpecialtyBagFromID(i)
	if (not i) then return end
	local c, d = select(6, GetItemInfo(i))
	return IsSpecialtyBag(c, d)
end

local function ParseWords(str, pat)
	if (tostr(str) == "") then return {} end
	local list = {}
	local word
	for word in string.gmatch(str, pat or "%S+") do
		tinsert(list, word)
	end
	return list
end

function MyBagsCore:OnEmbedInitialize(addon)
	addon.GetOpt = function(var)
		local prof = addon.db:GetCurrentProfile()
		return addon.db.profiles[prof][var] or false
	end
	addon.IsSet = function(var)
		local prof = addon.db:GetCurrentProfile()
		local t = type(addon.db.profiles[prof][var])
		if t == "number" then 
			if addon.db.profiles[prof][var] == 1 then
				return true
			else
				return false
			end
		end
		if t == "boolean" then
			return addon.db.profiles[prof][var]
		else
			return true
		end
	end
	addon.SetOpt = function(var,val)
		local prof = addon.db:GetCurrentProfile()
		addon.db.profiles[prof][var] = val;
	end
	addon.TogOpt = function(var)
		local prof = addon.db:GetCurrentProfile()
		if not addon.db.profiles[prof][var] then
			addon.db.profiles[prof][var] = true
			return true
		end
		local v_ret = addon.db.profiles[prof][var]
		local t = type(v_ret)
		if t == "boolean" then
			v_ret = not v_ret
		end
		if t == "number" then
			v_ret = 1 - v_ret
		end
		addon.db.profiles[prof][var] = v_ret
		return v_ret
	end
	addon.Result = function(text, val, map)
		if val == true then
			val = 1
		end
		if( map ) then val = map[val or 0] or val end
		AC:Printf(format(L["ACE_CMD_RESULT"], addon.name, text .. " " .. L["ACEG_TEXT_NOW_SET_TO"] .. " " .. format(L["ACEG_DISPLAY_OPTION"], val or L["ACE_CMD_REPORT_NO_VAL"]))) 
	end
	addon.TogMsg = function(var,text)
		addon.Result(text, addon.TogOpt(var), ACEG_MAP_ONOFF)
	end
	addon.Error  = function(...)
		local arg = {...}
		AC:Printf(format(unpack(arg)))
	end
	addon.frame = _G[addon.frameName]
	addon.frame.self = addon
	local inOptions = false
	local key, value
	for key, value in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
		if value.name == "MyBags" then
			inOptions = true
		end
	end
	if not inOptions then
		LibStub("AceConfig-3.0"):RegisterOptionsTable("MyBags", mb_options)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MyBags", "MyBags")
	end
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.name, addon.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.name, addon.name, "MyBags")

	local charName = strtrim(UnitName("player"));
	local realmName = strtrim(GetRealmName());
--	self.atBank = false
	addon.Player = charName .. L["CHARACTER_DELIMITOR"] .. realmName
end

-- OnEnable
function MyBagsCore:OnEmbedEnable(addon)
	addon:RegisterEvents();
	addon:HookFunctions();
	if addon.GetOpt("Scale") then
		addon.frame:SetScale(addon.GetOpt("Scale"))
	end
	addon:SetUISpecialFrames()
	addon:SetFrozen()
	addon:SetLockTexture()
	local point = addon.GetOpt("Anchor")
	if point then
		addon.frame:ClearAllPoints()
		addon.frame:SetPoint(string.upper(point), addon.frame:GetParent():GetName(), string.upper(point), 0, 0)
	end
	if addon:CanSaveItems() then
		addon:LoadDropDown()
	else
		addon.SetOpt("Player")
	end
	addon:ChkCompanion()
	if addon.GetOpt("Strata") then
		addon.frame:SetFrameStrata(addon.GetOpt("Strata"))
	end
end

-- OnEnable functions
function MyBagsCore:RegisterEvents(obj)
	if (obj) then
		self = obj
	end
	self:RegisterEvent("BAG_UPDATE");
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", "LayoutFrameOnEvent")
--	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "UNIT_INVENTORY_CHANGED");
	self:RegisterEvent("ITEM_LOCK_CHANGED", "LayoutFrameOnEvent");
end

function MyBagsCore:HookFunctions(obj)
	if (obj) then
		self = obj
	end
	self:RawHook("ToggleBag", true)
	self:RawHook("OpenBag", true)
	self:RawHook("CloseBag", true)
end

function MyBagsCore:ToggleBag(bag)
	if self.GetOpt("Replace") and self:IncludeBag(bag) then
		self:Toggle()
	else
		self.hooks.ToggleBag(bag)
	end
end

function MyBagsCore:OpenBag(bag)
	if (self.GetOpt("Replace") and self:IncludeBag(bag)) then
		self:Open()
	elseif not self.isBank then
		self.hooks.OpenBag(bag)
	end
end

function MyBagsCore:CloseBag(bag)
	if not self.Freeze and (self.GetOpt("Replace") and self:IncludeBag(bag)) then
		self:Close()
	elseif not self.isBank then
		self.hooks.CloseBag(bag)
	end
end

function MyBagsCore:SetUISpecialFrames()
	local k, v
	if self.GetOpt("NoEsc") then
		for k,v in pairs( UISpecialFrames ) do
			if v == (self.frameName) then
				table.remove(UISpecialFrames, k)
			end
		end
	else
		table.insert(UISpecialFrames, self.frameName)
	end
end

function MyBagsCore:SetFrozen()
	if self.GetOpt("Freeze") == "always" then
		self.Freeze = "always"
	elseif self.GetOpt("Freeze") == "sticky" then
		self.Freeze = "sticky"
	else
		self.Freeze = nil
	end
end

function MyBagsCore:SetLockTexture()
	local button = _G[self.frameName .. "ButtonsLockButtonNormalTexture"]
	local texture = "Interface\\AddOns\\MyBags\\Skin\\LockButton-"
	if not self.GetOpt("Lock") then texture = texture .. "Un" end
	texture = texture .. "Locked-Up"
	button:SetTexture(texture)
	if self.GetOpt("Lock") and self.GetOpt("Graphics") == "none" then
		self.frame:EnableMouse(nil)
	else
		self.frame:EnableMouse(1)
	end
end

function MyBagsCore:CanSaveItems()
	local live = self:IsLive()
	self.isLive = false
	if self:GetInfoFunc() ~= self.GetInfoNone then
		self.isLive = live
		return true
	else
		self.isLive = live
		return false
	end
end

function MyBagsCore:IsLive()
	local isLive = true
	local charID = self:GetCurrentPlayer()
	if charID ~= strtrim(UnitName("player")) .. L["CHARACTER_DELIMITOR"] .. strtrim(GetRealmName()) then isLive = false end
--	if charID ~= ace.char.id then isLive = false end
	if self.isBank and not MyBank.atBank then isLive = false end
	self.isLive = isLive
	return isLive
end

function MyBagsCore:GetCurrentPlayer()
	if self and self.Player then 
		return self.Player
	end
	local charName = strtrim(UnitName("player"));
	local realmName = strtrim(GetRealmName());
	return charName .. L["CHARACTER_DELIMITOR"] .. realmName
end

function MyBagsCore:TooltipSetOwner(owner, anchor)
	if not owner then owner = UIParent end
	local parent = owner:GetParent()
	if parent and (parent == self.frame or parent:GetParent() == self.frame ) then
		local point = self.GetOpt("Anchor") or "bottomright"
		if point == "topleft" or point == "bottomleft" then
			anchor = "ANCHOR_RIGHT"
		else
			anchor = "ANCHOR_LEFT"
		end
	else
		anchor = "ANCHOR_PRESERVE"
	end
	GameTooltip:SetOwner(owner, anchor)
end

function MyBagsCore:Open()
	if not self.frame:IsVisible() then self.frame:Show() end
	local charName = strtrim(UnitName("player"));
	local realmName = strtrim(GetRealmName());
--	self.atBank = false
	self.Player = charName .. L["CHARACTER_DELIMITOR"] .. realmName

	if self.Player then
--		self.Player = ace.char.id
		local dropDown = _G[self.frameName .. "CharSelectDropDown"]
		if dropDown then
		   UIDropDownMenu_SetSelectedValue(dropDown, self.Player)
		end
	end
	self:LayoutFrame()
end

function MyBagsCore:Close()
	if self.frame:IsVisible() then self.frame:Hide() end
end

function MyBagsCore:Toggle()
	if self.frame:IsVisible() then
		self:Close()
	else
		self:Open()
	end
end

function MyBagsCore:GetHyperlink(ID)
	local link
	if (type(ID) == "string") then
		link = select(2, GetItemInfo(ID))
	else
		link = select(2, GetItemInfo("item:" .. ID))
	end
	return link
end

function MyBagsCore:GetTextLink(ID)
	local myName, myLink, myQuality = GetItemInfo("item:" .. ID)
	local myColor = select(4, GetItemQualityColor(myQuality or 0))
	local textLink = "|cff" .. (strsub(myColor,5)) ..  "|H" .. myLink .. "|h[" .. myName .. "]|h|r"
	return textLink
end

function MyBagsCore:BagIDToInvSlotID(bag, isBank)
	if bag == -1 or bag >= 5 and bag <= 11 then isBank = 1 end
	if bag < 1 or bag > 11 then return nil; end
	if isBank then return BankButtonIDToInvSlotID(bag, 1)	end
	return ContainerIDToInventoryID(bag)
end

function MyBagsCore:IncludeBag(bag)
	if self.isBank and bag == BANK_CONTAINER then return true end
	if bag < self.firstBag or bag > (self.firstBag + self.totalBags-1) then
		return false
	else
		local prof = self.db:GetCurrentProfile()
		local bs = "BagSlot" .. bag
		if self.db.profiles[prof][bs] and self.db.profiles[prof][bs]["Exclude"] then
			return false
		end
		return true
	end
end

function MyBagsCore:IsBagSlotUsable(bag)
	if not self.isBank then return true end
	local slots, _ = GetNumBankSlots()
	if (bag+1 - self.firstBag) <= slots  then return true end
	return false
end

function MyBagsCore:GetCash()
	if self.isLive then 
		return GetMoney()
	elseif IsAddOnLoaded("DataStore_Characters") then
		local DS = DataStore
		local player, realm = self:SplitString(self:GetCurrentPlayer(), L["CHARACTER_DELIMITOR"])
		local char_key = DS:GetCharacter(player, realm)
		return DS:GetMoney(char_key)
	elseif IsAddOnLoaded("MyBagsCache") then
		local charID = self:GetCurrentPlayer()
		return MyBagsCache:GetCash(charID)
	end
	return nil
end	

function MyBagsCore:SplitString(s, p, n)
	if (type(s) ~= "string") then
		error(L["SplitString must be passed a string as the first argument"], 2)
	end

	if (type(p) ~= "string") then
		p = L["CHARACTER_DELIMITOR"]
	end
	local l, sp, ep = {}, 0
	while (sp) do
		sp, ep=strfind(s, p)
		if (sp) then
			tinsert(l, strsub(s, 1, sp-1))
			s = strsub(s, ep+1)
		else
			tinsert(l, s)
			break
		end
		if (n) then
			n=n-1
		end
		if (n and (n==0)) then 
			tinsert(l, s)
			break
		end
	end
	return unpack(l)
end

function MyBagsCore:SortChars(char_a, char_b, time_a, time_b, sort_type)
	local player_a, realm_a = self:SplitString(char_a, L["CHARACTER_DELIMITOR"])
	local player_b, realm_b = self:SplitString(char_b, L["CHARACTER_DELIMITOR"])
	if (sort_type == "realm") then
		if (realm_a == realm_b) then
			return (player_a > player_b)
		else
			return (realm_a > realm_b)
		end
	elseif (sort_type == "char") then
		if (player_a == player_b) then
			return (realm_a > realm_b)
		else
			return (player_a > player_b)
		end
	else
		return time_a < time_b
	end
end

function MyBagsCore:GetInfo(bag, slot)
	local infofunc = self:GetInfoFunc()
	if infofunc then
		return infofunc(self, bag, slot)
	end
	return nil, 0, nil, nil, nil, nil, nil, nil
end

function MyBagsCore:GetInfoLive(bag, slot)
	local charName = strtrim(UnitName("player"));
	local realmName = strtrim(GetRealmName());
	self.Player = charName .. L["CHARACTER_DELIMITOR"] .. realmName
	if slot ~= nil then
		-- it's an item
		local texture, count, locked, _ , readable = GetContainerItemInfo(bag, slot)
		local itemLink = GetContainerItemLink(bag, slot)
		local name, quality, _, ID, i_type
		if itemLink then
			name, quality, _, ID, i_type = GetItemInfoFromLink(itemLink)
		end
		count = tonum(count)
		return texture, count, ID, locked, quality, readable, name or nil, i_type
	else
		-- it's a bag
		local count = GetContainerNumSlots(bag)
		local inventoryID = self:BagIDToInvSlotID(bag)
		local texture, itemLink, locked, readable
		local name, quality, _, ID
		if inventoryID then
			texture = GetInventoryItemTexture("player", inventoryID)
			itemLink = GetInventoryItemLink("player", inventoryID)
			if itemLink then
				name, quality, _, ID = GetItemInfoFromLink(itemLink)
			end
			locked = IsInventoryItemLocked(inventoryID)
			readable = IsSpecialtyBagFromLink(itemLink)
		elseif ( bag == -1 ) then
			texture = "Interface\\Buttons\\Button-Backpack-Up"
			count = 28;
		elseif ( bag == 0 ) then				
			texture = "Interface\\Buttons\\Button-Backpack-Up"
			count = 16
		end
		count = tonum(count)
		return texture, count, ID, locked, quality, readable, name or nil, "bag"
	end
end

function MyBagsCore:GetInfoDataStore(bag, slot)
	local DS = DataStore
	local player, realm = self:SplitString(self:GetCurrentPlayer(), L["CHARACTER_DELIMITOR"])
	local char_key = DS:GetCharacter(player, realm)
	local readable
	local quality

	if self.isEquipment then
		-- texture, count, id, locked, quality, _, name = GetInfo(item)
--[[
		local slotID = bag
		local texture, count, id, locked, quality, readable, name
		local slotInfo = DS:GetInventoryItem(char_key, slotID)
		if type(slotInfo) ~= "number" then
			
		else
		end
]]
	else
		if bag == -1 then
			bag = 100
		end
		local container = DS:GetContainer(char_key, bag)
		if not slot then
			local texture, ID, count, _, _ = DS:GetContainerInfo(char_key, bag)
			local name
			if ID then
				name = GetItemInfo(ID)
				readable = IsSpecialtyBagFromID(ID)
			end
			return texture, count, ID, nil, quality, readable, name
		else
			local ID, slotLink, count = DS:GetSlotInfo(container, slot)
			local name, itemLink, texture, quality, i_type
			if ID then
				name, itemLink = GetItemInfo(ID)
				texture = GetItemIcon(ID)
				if itemLink then
					quality, i_type = select(3, strfind(itemLink, "|cff(%x+)|H(%l+):.*|h|r"))
				end
			end
			if slotLink then
				ID = slotLink
			end
			return texture, count, ID, nil, quality, readable, name, i_type
		end
	end
end

function MyBagsCore:GetInfoMyBagsCache(bag,slot)
	local charID = self:GetCurrentPlayer()
	local texture, count, ID, locked, quality, readable, name, i_type
	if self.isEquipment then
		texture, count, ID, quality, name, i_type = MyBagsCache:GetInfo("equipment", bag, charID)
	else
		texture, count, ID, quality, name, i_type = MyBagsCache:GetInfo(bag, slot, charID)
		if not slot and ID then
			readable = IsSpecialtyBagFromID(ID)
		end
	end
	count = tonum(count)
	return texture, count, ID, nil, quality, readable, name, i_type
end

function MyBagsCore:GetInfoNone(bag, slot)
	return nil, 0, nil, nil, nil, nil, nil, nil
end

function MyBagsCore:GetSlotCount()
	local slots, used, displaySlots = 0, 0, 0
	local i
	local bagIndex
	if self.isBank then
		if self:CanSaveItems() or self.isLive then
			slots = 28
			displaySlots = 28
		end
		for i = 1, slots do
			if (self:GetInfo(BANK_CONTAINER, i)) then used = used + 1 end
		end
	end
	for bagIndex = 0, self.totalBags -1 do
		local bagFrame = _G[self.frameName .. "Bag" .. bagIndex]
		if bagFrame and self:IncludeBag(bagFrame:GetID()) then
			local bagID = bagFrame:GetID()
			local _, bagSlots, _, _, _, specBag = self:GetInfo(bagID)
			bagSlots = tonum(bagSlots)
			if not specBag or specBag == "" then
				slots = slots + bagSlots
				displaySlots = displaySlots + bagSlots
				for i = 1, bagSlots do
					if self:GetInfo(bagID, i) then used = used + 1 end
				end
			else
				displaySlots = displaySlots + bagSlots
			end
		end
	end
	return slots, used, displaySlots
end

--ITEMBUTTONS--
function MyBagsCore:ItemButton_OnLoad(widget)
	_G[widget:GetName().."NormalTexture"]:SetTexture("Interface\\AddOns\\MyBags\\Skin\\Button");
	ContainerFrameItemButton_OnLoad(widget)
	widget.UpdateTooltip = widget.ItemButton_OnEnter;
end

function MyBagsCore:ItemButton_OnLeave(widget)
	GameTooltip:Hide()
	local bagButton = _G[widget:GetParent():GetName() .. "Bag"]
	if bagButton then bagButton:UnlockHighlight() end
	CursorUpdate(widget)
end

function MyBagsCore:ItemButton_OnClick(widget, button)
	if self.isLive then
		if widget.hasItem then self.watchLock = 1 end
		if self.isBank and widget:GetParent():GetID() == BANK_CONTAINER then
			BankFrameItemButtonGeneric_OnClick(widget, button)
		else
			ContainerFrameItemButton_OnClick(widget, button)
		end
	end
end

function MyBagsCore:ItemButton_OnModifiedClick(widget, button)
	if self.isLive then
--		if self.isBank and widget:GetParent():GetID() == BANK_CONTAINER then
--			BankFrameItemButtonGeneric_OnModifiedClick(widget, button)
--			StackSplitFrame:SetFrameStrata("TOOLTIP");
--		else
--			ContainerFrameItemButton_OnModifiedClick(widget, button)
--			StackSplitFrame:SetFrameStrata("TOOLTIP");
--		end
	else
		if ( button == "LeftButton" ) then
			if ( IsControlKeyDown() ) then
				local ID = select(3, self:GetInfo( widget:GetParent():GetID(), widget:GetID() - 1000 ))
				if DressUpItemLink and ID and ID ~= "" then
					DressUpItemLink("item:"..ID)
				end
			elseif ( IsShiftKeyDown() ) then
				local ID = select(3, self:GetInfo( widget:GetParent():GetID(), widget:GetID() - 1000 ))
				local hyperLink
				if ID then hyperLink = self:GetHyperlink(ID) end
				if hyperLink then 
					ChatEdit_InsertLink(hyperLink)
				end
				StackSplitFrame:Hide();
			end
		end
	end
end

function MyBagsCore:ItemButton_OnEnter(widget)
	if self.GetOpt("HlBags") then
		local bagButton = _G[widget:GetParent():GetName() .. "Bag"]
		if bagButton then bagButton:LockHighlight() end
	end
	self:TooltipSetOwner(widget)
	if self.isLive then
		if widget:GetParent() == MyBankFrameBank then
			GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(widget:GetID()))
		else
		    local hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetBagItem(widget:GetParent():GetID(), widget:GetID())
		    if (speciesID and speciesID > 0) then
    		    local link = GetContainerItemLink(widget:GetParent():GetID(), widget:GetID())
    		    local id, lvl, rar, hp, pw, sp, n = GetBattlePetInfoFromLink(link)
    		    BattlePetToolTip_Show(id, lvl, rar, hp, pw, sp, n)
		    else
		        if (BattlePetTooltip) then
		            BattlePetTooltip:Hide()
		        end
    			ContainerFrameItemButton_OnEnter(widget)
		    end
		end
	else
	    -- print("self.isLive = false");
		local ID = select(3, self:GetInfo(widget:GetParent():GetID(), widget:GetID() - 1000))
		local i_type = select(8, self:GetInfo(widget:GetParent():GetID(), widget:GetID() - 1000))
		if ID and i_type ~= "battlepet" then
			local hyperlink = self:GetHyperlink(ID)
			if hyperlink then GameTooltip:SetHyperlink(hyperlink) end
		end
	end
	if ( widget.readable or (IsControlKeyDown() and widget.hasItem) ) then
		ShowInspectCursor()
	end
end

function MyBagsCore:ItemButton_OnDragStart(widget)
	if self.isLive then
		self:ItemButton_OnClick(widget, "LeftButton", 1)
	end
end

function MyBagsCore:ItemButton_OnReceiveDrag(widget)
	if self.isLive then
		self:ItemButton_OnClick(widget, "LeftButton", 1)
	end
end

--BAGBUTTONS--
function MyBagsCore:BagButton_OnEnter(widget)
	local bagFrame = widget:GetParent()
	local setTooltip = true
	self:TooltipSetOwner(widget)
	if self.isLive then
		local invSlot = self:BagIDToInvSlotID(bagFrame:GetID())
		if not invSlot or (not GameTooltip:SetInventoryItem("player", invSlot)) then
			setTooltip = false
		end
	else
		local ID = select(3, self:GetInfo(widget:GetParent():GetID()))
		if bagFrame:GetID() == 0 then
			GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0,1.0,1.0)
		elseif ID then
			hyperlink = self:GetHyperlink(ID)
			if hyperlink then
				GameTooltip:SetHyperlink(hyperlink)
			end
		else
			setTooltip = false
		end
	end
	if not setTooltip then
		local keyBinding
		if self.isBank then
			if self.isLive and not self:IsBagSlotUsable(bagFrame:GetID()) then
				GameTooltip:SetText(BANK_BAG_PURCHASE)
				if MyBank.atBank then
					local cost = GetBankSlotCost()
					GameTooltip:AddLine("Purchase:", "", 1, 1, 1)
					SetTooltipMoney(GameTooltip, cost)
					if GetMoney() > cost then
						SetMoneyFrameColor("GameTooltipMoneyFrame", 1.0, 1.0, 1.0)
					else
						SetMoneyFrameColor("GameTooltipMoneyFrame", 1.0, 0.1, 0.1)
					end
					GameTooltip:Show()
				end
				keyBinding = GetBindingKey("TOGGLEBAG"..(4-widget:GetID()))
			else
				GameTooltip:SetText(BANK_BAG)
			end
		else
			if bagFrame:GetID() == 0 then -- SetScript("OnEnter", MainMenuBarBackpackButton:GetScript("OnEnter"))
				GameTooltip:SetText(BACKPACK_TOOLTIP, 1.0,1.0,1.0)
				keyBinding = GetBindingKey("TOGGLEBACKPACK")
			else
				GameTooltip:SetText(EQUIP_CONTAINER)
			end
		end
	end
	if self.GetOpt("HlItems") then -- Highlight
		local i
		for i = 1, self.GetOpt("MAXBAGSLOTS") do
			local button = _G[bagFrame:GetName() .. "Item" .. i]
			if button then
				button:LockHighlight()
			end
		end
	end
end

function MyBagsCore:BagButton_OnLeave(widget)
	SetMoneyFrameColor("GameTooltipMoneyFrame", 1.0, 1.0, 1.0);
	GameTooltip:Hide()
	local i
	for i = 1, self.GetOpt("MAXBAGSLOTS") do
		local button = _G[widget:GetParent():GetName() .. "Item" .. i]
		if button then	button:UnlockHighlight() end
	end
end

function MyBagsCore:BagButton_OnClick(widget, button, ignoreShift)
	if self.isBank then
		widget:SetChecked(nil)
	else
		widget:SetChecked(self:IncludeBag(widget:GetID()))
	end
	if self.isLive then
		if button == "LeftButton" then
			if not self:IsBagSlotUsable(widget:GetParent():GetID()) then
				local cost = GetBankSlotCost()
				if GetMoney() > cost then
					if not StaticPopupDialogs["PURCHASE_BANKBAG"] then	return end
					StaticPopup_Show("PURCHASE_BANKBAG")
				end
				return
			end
			if (not IsShiftKeyDown()) then
				self:BagButton_OnReceiveDrag(widget)
			else
			end
		else
			if (IsShiftKeyDown()) then
				local prof = self.db:GetCurrentProfile()
				local bgnum = widget:GetParent():GetID()
				local bg = "BagSlot" .. bgnum
				if (self.db.profiles[prof][bg] and self.db.profiles[prof][bg]["Exclude"]) then
					self.db.profiles[prof][bg]["Exclude"] = false
				else
					if not self.db.profiles[prof][bg] then
						self.db.profiles[prof][bg] = {}
					end
					self.db.profiles[prof][bg]["Exclude"] = true
				end
				self.hooks.CloseBag(bgnum)
				self:LayoutFrame()
			end
		end
	end
end

function MyBagsCore:BagButton_OnDragStart(widget)
	if self.isLive then
		local bagFrame = widget:GetParent()
		local invID = self:BagIDToInvSlotID(bagFrame:GetID())
		if invID then
			PickupBagFromSlot(invID)
			PlaySound("BAGMENUBUTTONPRESS")
			self.watchLock = 1
		end
	end
end

function MyBagsCore:BagButton_OnReceiveDrag(widget)
	if self.isLive then
		local bagFrame = widget:GetParent()
		local invID = self:BagIDToInvSlotID(bagFrame:GetID())
		local hadItem
		if not invID then
			hadItem = PutItemInBackpack()
		else
			hadItem = PutItemInBag(invID)
		end
		if not hadItem then
			if not self:IncludeBag(bagFrame:GetID()) then
				self.hooks.ToggleBag(bagFrame:GetID())
			end
		end
	end
end

function MyBagsCore:LayoutOptions()
	local playerSelectFrame = _G[self.frameName .. "CharSelect"]
	local title = _G[self.frameName .. "Name"]
	local cash = _G[self.frameName .. "MoneyFrame"]
	local slots = _G[self.frameName .. "Slots"]
	local buttons = _G[self.frameName .. "Buttons"]

	local search = _G[self.frameName .. "SearchBox"]
	if search then
		if self.GetOpt("Search") then
			search:SetParent(self.frameName)
			search.anchorBag = _G[self.frameName]
			search:Show()
		else
			search:Hide()
		end
	end

	self:UpdateTitle()
	if self.GetOpt("Title") then
		title:Show()
	else
		title:Hide()
	end

	if self.GetOpt("Cash") then
		local cashvalue = self:GetCash()
		if cashvalue then
			MoneyFrame_Update(self.frameName .. "MoneyFrame", cashvalue)
			cash:Show()
		else
			cash:Hide()
		end
	else
		cash:Hide()
	end

	if self.GetOpt("Token") and ManageBackpackTokenFrame then
		local token = _G[self.frameName .. "TokenFrame"]
		if (BackpackTokenFrame_IsShown()) then
			token:SetParent(self.frameName)
			token:SetPoint("RIGHT", cash, "LEFT", -10, 0)
			local i
			for i=1, MAX_WATCHED_TOKENS do
				local name, count, icon, currencyID = GetBackpackCurrencyInfo(i);
				-- Update watched tokens
				local watchButton = _G[self.frameName .. "TokenFrameToken"..i];
				if ( name ) then
					watchButton.icon:SetTexture(icon);
					if ( count <= 99999 ) then
						watchButton.count:SetText(count);
					else
						watchButton.count:SetText("*");
					end
					watchButton.currencyID = currencyID;
					watchButton:Show();
					BackpackTokenFrame.shouldShow = 1;
					BackpackTokenFrame.numWatchedTokens = i;
				else
					watchButton:Hide();
					if ( i == 1 ) then
						BackpackTokenFrame.shouldShow = nil;
					end
				end
			end
			token:Show()
		else
			token:Hide()
		end
	else
	end

	if self.GetOpt("Buttons") then
		buttons:Show()
	else
		buttons:Hide()
	end

	if self.GetOpt("Graphics") then
		self:SetFrameMode(self.GetOpt("Graphics"))
	end

	if self.GetOpt("Player") then
		playerSelectFrame:Show()
	else
		playerSelectFrame:Hide()
	end
	playerSelectFrame:ClearAllPoints()

	if self.GetOpt("Graphics") == "art" then
		playerSelectFrame:SetPoint("TOPRIGHT", self.frameName, "TOPRIGHT", 0, -38)
		self.SetOpt("_TOPOFFSET", 32)
	elseif self.GetOpt("Title") or self.GetOpt("Buttons") then
		playerSelectFrame:SetPoint("TOPRIGHT", self.frameName, "TOPRIGHT", 0, -38)
		self.SetOpt("_TOPOFFSET", 28)
	else
		playerSelectFrame:SetPoint("TOPRIGHT", self.frameName, "TOPRIGHT", 0, -18)
		self.SetOpt("_TOPOFFSET", 8)
	end

	if self.GetOpt("Cash") or (not self.isEquipment and self.GetOpt("Count") ~= "none") then
		self.SetOpt("_BOTTOMOFFSET", 25)
	else
		self.SetOpt("_BOTTOMOFFSET", 3)
	end

	if (self.frame.isBank) then
		MYBAGS_BOTTOMOFFSET = MYBAGS_BOTTOMOFFSET+20
		cash:ClearAllPoints()
		cash:SetPoint("BOTTOMRIGHT", self.frameName, "BOTTOMRIGHT", 0, 25)
	end

	if self.GetOpt("Player") or self.GetOpt("Graphics") == "art" then
		self.curRow = self.curRow + 1
	end

	if self.GetOpt("Bag") == "bar" then
		self.curRow = self.curRow + 1
	end

	local count, used, displaySlots = nil
	if not (self.isEquipment) then
		count, used, displaySlots = self:GetSlotCount()
		count = tonum(count)
		displaySlots = tonum(displaySlots)
		used = tonum(used)
		if self.GetOpt("Count") == "free" then
			slots:Show()
			slots:SetText(format(L["MYBAGS_SLOTS_FREE"], (count - used), count ))
		elseif self.GetOpt("Count") == "used" then
			slots:Show()
			slots:SetText(format(L["MYBAGS_SLOTS_USED"], (used), count ))
		else
			slots:Hide()
		end
		if self.GetOpt("Reverse") then
			self.reverseOrder = true
		else
			self.reverseOrder = false
		end
	end

	if self.GetOpt("AIOI") then
		self.aioiOrder = true
		local columns = self.GetOpt("Columns")
		if not (self.isEquipment) and self.GetOpt("Bag") == "before" then displaySlots = displaySlots + self.totalBags end
		columns = tonum(columns)
		if self.isEquipment then displaySlots = 20 end
		self.curCol = columns - (mod(displaySlots, columns) )
		if self.curCol == columns then self.curCol = 0 end
	else
		self.aioiOrder = false
	end
end

function MyBagsCore:UpdateTitle()
	local title1 = 4
	local title2 = 7
	if self.GetOpt("Graphics") == "art" then
		title1 = 5
		title2 = 9
	end
	local columns = self.GetOpt("Columns")
	local titleString
	if columns > title2 then
		titleString = L["MYBAGS_TITLE2"]
	elseif columns > title1 then
		titleString = L["MYBAGS_TITLE1"]
	else
		titleString = L["MYBAGS_TITLE0"]
	end
	titleString = titleString .. _G[string.upper(self.frameName) .. "_TITLE"]
	local title = _G[self.frameName .. "Name"]
  local player, realm = self:SplitString(MyBagsCore:GetCurrentPlayer(self), L["CHARACTER_DELIMITOR"])
	title:SetText(format(titleString, player, realm))
end

function MyBagsCore:SetFrameMode(mode)
	local frame = self.frame
	local frameName = self.frameName

	local frameTitle					= _G[frameName .. "Name"]
	local frameButtonBar			= _G[frameName .. "Buttons"]

	local textureTopLeft			= _G[frameName .. "TextureTopLeft"]
	local textureTopCenter		= _G[frameName .. "TextureTopCenter"]
	local textureTopRight			= _G[frameName .. "TextureTopRight"]

	local textureLeft					= _G[frameName .. "TextureLeft"]
	local textureCenter				= _G[frameName .. "TextureCenter"]
	local textureRight				= _G[frameName .. "TextureRight"]

	local textureBottomLeft		= _G[frameName .. "TextureBottomLeft"]
	local textureBottomCenter	= _G[frameName .. "TextureBottomCenter"]
	local textureBottomRight	= _G[frameName .. "TextureBottomRight"]
	local texturePortrait			= _G[frameName .. "Portrait"]

	frameTitle:ClearAllPoints()
	frameButtonBar:ClearAllPoints()

	if mode == "art" then
		frameTitle:SetPoint("TOPLEFT", frameName, "TOPLEFT", 70, -10)
		frameTitle:Show()
		frameButtonBar:Show()
		frameButtonBar:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", 10, 0)
		frame:SetBackdropColor(0,0,0,0)
		frame:SetBackdropBorderColor(0,0,0,0)
		textureTopLeft:Show()
		textureTopCenter:Show()
		textureTopRight:Show()
		textureLeft:Show()
		textureCenter:Show()
		textureRight:Show()
		textureBottomLeft:Show()
		textureBottomCenter:Show()
		textureBottomRight:Show()
		texturePortrait:Show()
	else
		frameTitle:SetPoint("TOPLEFT", frameName, "TOPLEFT", 5, -6)
		frameButtonBar:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", 0, 0)
		textureTopLeft:Hide()
		textureTopCenter:Hide()
		textureTopRight:Hide()
		textureLeft:Hide()
		textureCenter:Hide()
		textureRight:Hide()
		textureBottomLeft:Hide()
		textureBottomCenter:Hide()
		textureBottomRight:Hide()
		texturePortrait:Hide()
		if mode == "default" then
			local BackColor = self.GetOpt("BackColor") or {0.7,0,0,0}
			local a, r, g, b = unpack(BackColor)
			frame:SetBackdropColor(r,g,b,a)
			frame:SetBackdropBorderColor(1,1,1,a)
		else
			frame:SetBackdropColor(0,0,0,0)
			frame:SetBackdropBorderColor(0,0,0,0)
		end
	end
end

function MyBagsCore:GetXY(row, col)
	local x = self.GetOpt("_LEFTOFFSET") + (col * MYBAGS_COLWIDTH)
	local y = 0 - self.GetOpt("_TOPOFFSET") - (row * MYBAGS_ROWHEIGHT)
	return x, y
end

function MyBagsCore:LayoutBagFrame(bagFrame)
	local bagFrameName = bagFrame:GetName()
	local bagParent = bagFrame:GetParent():GetName()
	local searchBox = _G[bagParent .. "SearchBox"]
	local searchText = searchBox:GetText()
	if searchText == SEARCH then
		searchText = ""
	else
		searchText = string.lower(strtrim(searchText))
	end
	local slot
	local itemBase = bagFrameName .. "Item"
	local bagButton = _G[bagFrameName .. "Bag"]
	local slotColor = ((self.GetOpt("SlotColor")) or MYBAGS_SLOTCOLOR)
	local ammoColor = ((self.GetOpt("AmmoColor")) or MYBAGS_AMMOCOLOR)
	local shardColor = ((self.GetOpt("ShardColor")) or MYBAGS_SHARDCOLOR)
	local enchantColor = ((self.GetOpt("EnchantColor")) or MYBAGS_ENCHANTCOLOR)
	local engColor = ((self.GetOpt("EngColor")) or MYBAGS_ENGINEERCOLOR)
	local herbColor = ((self.GetOpt("HerbColor")) or MYBAGS_HERBCOLOR)
	local gemColor = ((self.GetOpt("GemColor")) or MYBAGS_GEMCOLOR)
	local miningColor = ((self.GetOpt("MiningColor")) or MYBAGS_MININGCOLOR)
	self.watchLock = nil

	local texture, count, _, locked, _, specialty = self:GetInfo(bagFrame:GetID())
	bagFrame.size = tonum(count)
	if bagButton and bagFrame:GetID() ~= BANK_CONTAINER then
		if not texture then
			local bag_id, texture = GetInventorySlotInfo("Bag0Slot")
		end
		if not self.isLive or (self.isLive and self:IsBagSlotUsable(bagFrame:GetID())) then
			SetItemButtonTextureVertexColor(bagButton, 1.0, 1.0, 1.0)
			SetItemButtonDesaturated(bagButton, locked, 0.5, 0.5, 0.5)
		else
			SetItemButtonTextureVertexColor(bagButton, 1.0, 0.1, 0.1)
		end
		SetItemButtonTexture(bagButton, texture)
		if self.GetOpt("Bag") == "bar" then
			local col, row = 0, 0
			if self.GetOpt("Player") or self.GetOpt("Graphics") == "art" then row = 1 end
			if self.isBank then
				col = (self.GetOpt("Columns") - self.totalBags)/2
			else
				col = (self.GetOpt("Columns") - self.totalBags -.5)/2
			end
			col = col + bagFrame:GetID() - self.firstBag
			bagButton:Show()
			bagButton:ClearAllPoints()
			bagButton:SetPoint("TOPLEFT", self.frameName, "TOPLEFT", self:GetXY(row, col))
		elseif self.GetOpt("Bag") == "before" then
			if self.curCol >= self.GetOpt("Columns") then
				self.curCol  = 0
				self.curRow = self.curRow + 1
			end
			bagButton:Show()
			bagButton:ClearAllPoints()
			bagButton:SetPoint("TOPLEFT", self.frameName, "TOPLEFT", self:GetXY(self.curRow,self.curCol))
			self.curCol = self.curCol + 1
		else
			bagButton:Hide()
		end
		if not self:IncludeBag(bagFrame:GetID()) or self.isBank then
			bagButton:SetChecked(nil)
		else
			bagButton:SetChecked(1)
		end
	end
	if bagFrame.size < 1 or not self:IncludeBag(bagFrame:GetID()) then
		bagFrame.size = 0
	else
		for slot = 1, bagFrame.size do
			local itemButton = _G[itemBase .. slot] or CreateFrame("Button", itemBase .. slot, bagFrame, "MyBagsItemButtonTemplate")
			if ( self:IsLive() ) then
				itemButton:SetID(slot);
			else
				itemButton:SetID(slot + 1000);
			end
			if self.curCol >= self.GetOpt("Columns") then
				self.curCol = 0
				self.curRow = self.curRow + 1
			end
			local newItemTexture = _G[itemBase .. slot .. "NewItemTexture"]
			newItemTexture:Hide()
			itemButton:Show()
			itemButton:ClearAllPoints()
			itemButton:SetPoint("TOPLEFT", self.frame:GetName(), "TOPLEFT", self:GetXY(self.curRow, self.curCol))
			self.curCol = self.curCol + 1
			local texture, count, id, locked, quality, _, name = self:GetInfo(bagFrame:GetID(), slot)
			name = name or ""
			if id and id ~= "" then
				itemButton.hasItem = 1
				local fade = 1
				if searchText ~= "" then
					if not string.find(string.lower(name), searchText) then
						fade = 0.2
					end
				end
				itemButton:SetAlpha(fade)
			else
				quality = nil
			end
			if self.isLive then
				local start,duration, enable = GetContainerItemCooldown(bagFrame:GetID(), slot)
				local cooldown = _G[itemButton:GetName() .. "Cooldown"]
				CooldownFrame_SetTimer(cooldown,start,duration,enable)
				if duration>0 and enable==0 then
					SetItemButtonTextureVertexColor(itemButton, 0.4,0.4,0.4)
				end
			end
			SetItemButtonTexture(itemButton, (texture or ""))
			SetItemButtonCount(itemButton, count)
			SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5)
			if locked and locked ~= "" then
				itemButton:LockHighlight()
				self.watchLock =1
			else
				itemButton:UnlockHighlight()
			end
			if quality and self.GetOpt("Border") then
				SetItemButtonNormalTextureVertexColor(itemButton, ColorConvertHexToDigit(quality))
			else
				SetItemButtonNormalTextureVertexColor(itemButton, unpack(slotColor))
				if (specialty == 1 or specialty == 2) then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(ammoColor))
				elseif specialty == 3 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(shardColor))
				elseif specialty == 4 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(enchantColor))
				elseif specialty == 5 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(engColor))
				elseif specialty == 6 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(herbColor))
				elseif specialty == 7 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(gemColor))
				elseif specialty == 8 then
					SetItemButtonNormalTextureVertexColor(itemButton, unpack(miningColor))
				end
			end
		end
	end
	if(bagFrame.size) then
		local slot = bagFrame.size + 1
		local itemButton = _G[itemBase .. slot]
		while itemButton do
			itemButton:Hide()
			slot = slot + 1
			itemButton = _G[itemBase .. slot]
		end
	end
end

function MyBagsCore:LayoutFrame()
	if not self.frame:IsVisible() then return end
	self.isLive = self:IsLive()
	local bagBase = self.frameName .. "Bag"
	local bagIndex, bagFrame, bag
	self.curRow, self.curCol = 0,0
	self:LayoutOptions()
	if self.isEquipment then
		self:LayoutEquipmentFrame(self)
	else
		if self.reverseOrder then
			for bag = self.totalBags-1,0,-1  do
				bagFrame = _G[bagBase .. bag]
				if (bagFrame) then
					self:LayoutBagFrame(bagFrame)
				end
			end
			if self.isBank then
				bagFrame = _G[self.frameName .. "Bank"]
				self:LayoutBagFrame(bagFrame)
			end
		else
			if self.isBank then
				bagFrame = _G[self.frameName .. "Bank"]
				self:LayoutBagFrame(bagFrame)
			end
			for bag = 0, self.totalBags-1 do
				bagFrame = _G[bagBase .. bag]
				if (bagFrame) then
					self:LayoutBagFrame(bagFrame)
				end
			end
		end
	end
	if self.curCol == 0 then self.curRow = self.curRow - 1 end
	self.frame:SetWidth(self.GetOpt("_LEFTOFFSET") + self.GetOpt("_RIGHTOFFSET") + self.GetOpt("Columns") * MYBAGS_COLWIDTH)
	self.frame:SetHeight(self.GetOpt("_TOPOFFSET") + self.GetOpt("_BOTTOMOFFSET") + (self.curRow + 1) * MYBAGS_ROWHEIGHT)
end

function MyBagsCore:LayoutFrameOnEvent(event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
	if event == "ITEM_LOCK_CHANGED" and not self.watchLock then return end
	if self.isLive then
		self:LayoutFrame()
	end
end

function MyBagsCore:LockButton_OnClick()
	self.TogOpt("Lock")
	self:SetLockTexture()
end

function MyBagsCore:SetColumns(cols)
	cols = floor(tonum(cols))

	self.SetOpt("Columns", cols)
	self:LayoutFrame()
end

function MyBagsCore:SetReplace()
	self.TogMsg("Replace", "Replace default bags")
	self:LayoutFrame()
end

function MyBagsCore:SetBagDisplay(opt)
	self.SetOpt("Bag", opt)
	self.Result("Bag Buttons", opt)
	self:LayoutFrame()
end

function MyBagsCore:SetGraphicsDisplay(opt)
	local a, r, g, b
	opt, a, r, g, b = unpack(ParseWords(opt))
	if opt ~= "default" and opt~="art" and opt~="none" then
		return
	end
	self.SetOpt("Graphics", opt)
	if a then
		self.SetOpt("BackColor", {tonum(a), tonum(r), tonum(g), tonum(b)})
	else
		self.SetOpt("BackColor")
	end
	self.Result("Background", opt)
	self:LayoutFrame()
end

function MyBagsCore:SetHighlight(mode)
	if mode == "items" then
		self.TogMsg("HlItems", "Highlight")
	else
		self.TogMsg("HlBags", "Highlight")
	end
end

function MyBagsCore:SetFreeze(opt)
	opt = strlower(opt)
	if opt == "freeze always" then opt = "always" end
	if opt == "freeze sticky" then opt = "sticky" end
	if opt == "freeze none" then opt = "none" end
	self.Result("Freeze", opt)
	self.SetOpt("Freeze", opt)
	self:SetFrozen()
end

function MyBagsCore:SetNoEsc()
	self.TogMsg("NoEsc", "NoEsc")
	self:SetUISpecialFrames()
end

function MyBagsCore:SetLock()
	self.TogMsg("Lock", "Lock")
	self:SetLockTexture()
end

function MyBagsCore:SetSearch()
	self.TogMsg("Search", "Search")
	self:LayoutFrame()
end

function MyBagsCore:SetToken()
	self.TogMsg("Token", "Token")
	self:LayoutFrame()
end

function MyBagsCore:SetTitle()
	self.TogMsg("Title", "Frame Title")
	self:LayoutFrame()
end

function MyBagsCore:SetCash()
	self.TogMsg("Cash", "Money Display")
	self:LayoutFrame()
end

function MyBagsCore:SetButtons()
	self.TogMsg("Buttons", "Frame Buttons")
	self:LayoutFrame()
end

function MyBagsCore:SetAIOI()
	self.TogMsg("AIOI", "toggle partial row placement")
	self:LayoutFrame()
end

function MyBagsCore:SetReverse()
	self.TogMsg("Reverse", "reverse bag ordering")
	self:LayoutFrame()
end

function MyBagsCore:SetBorder()
	self.TogMsg("Border", "Quality Borders")
	self:LayoutFrame()
end

function MyBagsCore:SetPlayerSel()
	if self:CanSaveItems() then
		self.TogMsg("Player", "Player selection")
	else
		self.SetOpt("Player")
	end
	self:LayoutFrame()
end

function MyBagsCore:SetCount(mode)
	self.SetOpt("Count", mode)
	self.Result("Count", mode)
	self:LayoutFrame()
end

function MyBagsCore:SetScale(scale)
	scale = tonum(scale)
	if scale == 0 then
		self.SetOpt("Scale", 0)
		self.frame:SetScale(self.frame:GetParent():GetScale())
		self.Result("Scale", L["ACEG_TEXT_DEFAULT"])
	elseif (( scale < tonum(MIN_SCALE_VAL)) or (scale > tonum(MAX_SCALE_VAL))) then
		self.Error("Invalid Scale")
	else
		self.SetOpt("Scale", scale)
		self.frame:SetScale(scale)
		self.Result("Scale", scale)
	end
end

function MyBagsCore:SetStrata(strata)
	strata = strupper(strata)
	if strata =="BACKGROUND" or strata =="LOW" or strata =="MEDIUM" or strata =="HIGH" or strata =="DIALOG" then
		self.SetOpt("Strata", strata)
		self.frame:SetFrameStrata(strata)
		self.Result("Strata", strata)
	else
		self.Error("Invalid strata")
	end
end

function MyBagsCore:ResetSettings()
	self.db:ResetProfile()
	local prof = self.db:GetCurrentProfile()
	self.db.profiles[prof] = self.defaults
	self.Error("Settings reset to default")
	self:ResetAnchor()
	self:SetLockTexture()
	self:SetUISpecialFrames()
	self:SetFrozen()
	self:LayoutFrame()
end

function MyBagsCore:ResetAnchor()
	if not self:SetAnchor(self.defaults["Anchor"]) then return end
	local anchorframe = self.frame:GetParent()
	anchorframe:ClearAllPoints()
	anchorframe:SetPoint(self.anchorPoint, self.anchorParent, self.anchorPoint, self.anchorOffsetX, self.anchorOffsetY)
	self.frame:ClearAllPoints()
	self.frame:SetPoint(self.anchorPoint, anchorframe, self.anchorPoint, 0, 0)
	self.Error("Anchor Reset")
end

function MyBagsCore:SetAnchor(point)
	if     point == "topleft" then
	elseif point == "topright" then
	elseif point == "bottomleft" then
	elseif point == "bottomright" then
	else 
		self.Error("Invalid Entry for Anchor")
		return
	end
	local anchorframe = self.frame:GetParent()
	local top = self.frame:GetTop()
	local left = self.frame:GetLeft()
	local top1 = anchorframe:GetTop()
	local left1 = anchorframe:GetLeft()
	if not top or not left or not left1 or not top1 then
		self.Error("Frame must be open to set anchor") return
	end
	self.frame:ClearAllPoints()
	anchorframe:ClearAllPoints()
	anchorframe:SetPoint(string.upper(point), self.frameName, string.upper(point), 0, 0)
	top = anchorframe:GetTop()
	left = anchorframe:GetLeft()
	if not top or not left then
		anchorframe:ClearAllPoints()
		anchorframe:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left1, top1-10)
		point = string.upper(self.GetOpt("Anchor") or "bottomright")
		self.frame:SetPoint(point, anchorframe:GetName(), point, 0,0)
		self.Error("Frame must be open to set anchor") return
	end
	anchorframe:ClearAllPoints()
	anchorframe:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, top-10)
	self.frame:SetPoint(string.upper(point), anchorframe:GetName(), string.upper(point), 0, 0)
	self.SetOpt("Anchor", point)
	self.Result("Anchor", point)
	self.anchorPoint = string.upper(point)
	return TRUE
end

function MyBagsCore:SetCompanion()
	if self.GetOpt("Companion") then
		self:UnregisterEvent("AUCTION_HOUSE_SHOW")
		self:UnregisterEvent("AUCTION_HOUSE_CLOSED")
		self:UnregisterEvent("BANKFRAME_OPENED")
		self:UnregisterEvent("BANKFRAME_CLOSED")
		self:UnregisterEvent("MAIL_CLOSED")
		self:UnregisterEvent("TRADE_CLOSED")
		self:UnregisterEvent("TRADE_SHOW")
	end
	self.TogMsg("Companion", "Companion")
	self:ChkCompanion()
end

function MyBagsCore:ChkCompanion()
	if self.GetOpt("Companion") then
		self:RegisterEvent("AUCTION_HOUSE_SHOW","CompanionOpen")
		self:RegisterEvent("AUCTION_HOUSE_CLOSED","CompanionClose")
		self:RegisterEvent("BANKFRAME_OPENED","CompanionOpen")
		self:RegisterEvent("BANKFRAME_CLOSED","CompanionClose")
		self:RegisterEvent("MAIL_CLOSED","CompanionClose")
		self:RegisterEvent("TRADE_CLOSED","CompanionClose")
		self:RegisterEvent("TRADE_SHOW","CompanionOpen")
	end
end

--[[
function MyBagsCore:BagSearch_OnHide()
	
end
]]

function MyBagsCore:BagSearch_OnTextChanged()
	local search = _G[self.frameName .. "SearchBox"]
	local text = search:GetText()
	if ( text == SEARCH ) then
		text = "";
	end
	if (text ~= "") then
		search.clearButton:Show();
	else
		search.clearButton:Hide();
	end
	self:LayoutFrame()
end

function MyBagsCore:BagSearch_OnEditFocusGained()
	local search = _G[self.frameName .. "SearchBox"]
	search:HighlightText()
	search:SetFontObject("ChatFontSmall")
	search.searchIcon:SetVertexColor(1.0, 1.0, 1.0)
	local text = search:GetText()
	if ( text == SEARCH ) then
		text = "";
	end
	search.clearButton:Show();
	search:SetText(text)
	self:LayoutFrame()
end

local mixins = {
	"ToggleBag",
	"OpenBag",
	"CloseBag",
	"SetUISpecialFrames",
	"SetFrozen",
	"SetLockTexture",
	"CanSaveItems",
	"IsLive",
	"GetCurrentPlayer",
	"TooltipSetOwner",
	"Open",
	"Close",
	"Toggle",
	"GetHyperlink",
	"GetTextLink",
	"BagIDToInvSlotID",
	"IncludeBag",
	"IsBagSlotUsable",
	"GetCash",
	"SplitString",
	"SortChars",
	"GetInfo",
	"GetInfoLive",
	"GetInfoDataStore",
	"GetInfoMyBagsCache",
	"GetInfoNone",
	"GetSlotCount",
	"ItemButton_OnLoad",
	"ItemButton_OnLeave",
	"ItemButton_OnClick",
	"ItemButton_OnModifiedClick",
	"ItemButton_OnEnter",
	"ItemButton_OnDragStart",
	"ItemButton_OnReceiveDrag",
	"BagButton_OnEnter",
	"BagButton_OnLeave",
	"BagButton_OnClick",
	"BagButton_OnDragStart",
	"BagButton_OnReceiveDrag",
	"LayoutOptions",
	"UpdateTitle",
	"SetFrameMode",
	"GetXY",
	"LayoutBagFrame",
	"LayoutFrame",
	"LayoutFrameOnEvent",
	"LockButton_OnClick",
	"SetColumns",
	"SetReplace",
	"SetBagDisplay",
	"SetGraphicsDisplay",
	"SetHighlight",
	"SetFreeze",
	"SetNoEsc",
	"SetLock",
	"SetSearch",
	"SetToken",
	"SetTitle",
	"SetCash",
	"SetButtons",
	"SetAIOI",
	"SetReverse",
	"SetBorder",
	"SetPlayerSel",
	"SetCount",
	"SetScale",
	"SetStrata",
	"ResetSettings",
	"ResetAnchor",
	"SetAnchor",
	"SetCompanion",
	"ChkCompanion",
	"BagSearch_OnHide",
	"BagSearch_OnTextChanged",
	"BagSearch_OnEditFocusGained",
	"RegisterEvents",
	"UnregisterEvents",
} 

function MyBagsCore:Embed( target )
	local k, v
	for k, v in pairs( mixins ) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

for addon in pairs(MyBagsCore.embeds) do
	MyBagsCore:Embed(addon)
end