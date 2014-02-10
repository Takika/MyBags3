MyBagsCache = LibStub("AceAddon-3.0"):NewAddon("MyBagsCache", "AceEvent-3.0");

local L	= LibStub("AceLocale-3.0"):GetLocale("MyBagsCache")

local select, tinsert, type = select, table.insert, type
local strfind, strsub, strtrim = string.find, string.sub, strtrim
local error, unpack = error, unpack
local tonumber, pairs = tonumber, pairs

local function GetItemInfoFromLink(l)
	if (not l) then
		return
	end
	local c, id, il, n = select(3, strfind(l, "|cff(%x+)|Hitem:(%-?%d+)([^|]+)|h%[(.-)%]|h|r"))
	return n, c, id .. il, id
end

local function SplitString(s, p, n)
	if (type(s) ~= "string") then
		error(L["SplitString must be passed a string as the first argument"], 2)
	end

	local l, sp, ep = {}, 0
	while (sp) do
		sp, ep = strfind(s, p)
		if (sp) then
			tinsert(l, strsub(s, 1, sp - 1))
			s = strsub(s, ep + 1)
		else
			tinsert(l, s)
			break
		end
		if (n) then
			n = n - 1
		end
		if (n and (n == 0)) then
			tinsert(l, s)
			break
		end
	end
	return unpack(l)
end

local function SortChars(a, b, a_time, b_time, t)
	local a_player, a_realm = SplitString(a, L["CHARACTER_DELIMITOR"])
	local b_player, b_realm = SplitString(b, L["CHARACTER_DELIMITOR"])
	if (t == "realm") then
		if (a_realm == b_realm) then
			return (a_player > b_player)
		else
			return (a_realm > b_realm)
		end
	elseif (t == "char") then
		if (a_player == b_player) then
			return (a_realm > b_realm)
		else
			return (a_player > b_player)
		end
	elseif (t == "update") then
		return a_time < b_time
	end
end

function MyBagsCache:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MyBagsCacheDB");
	local charName = strtrim(UnitName("player"));
	local realmName = strtrim(GetRealmName());
--	self.atBank = false
	self.Player = charName .. L["CHARACTER_DELIMITOR"] .. realmName

	if not self.db.global[self.Player] then
		self.db.global[self.Player]={}
	end
end

function MyBagsCache:OnEnable()
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	
	self:RegisterEvent("VOID_STORAGE_CONTENTS_UPDATE")
	self:RegisterEvent("VOID_TRANSFER_DONE")
--	self:RegisterEvent("INVENTORY_SEARCH_UPDATE")
	self:RegisterEvent("VOID_STORAGE_OPEN")
	self:RegisterEvent("VOID_STORAGE_CLOSE")

	if not self.db.global[self.Player][0] then
		self:SaveItems()
	end
end

function MyBagsCache:VOID_STORAGE_CONTENTS_UPDATE()
	-- Move item in Void OR
	-- Move item from Void to Withdraw
	if (CanUseVoidStorage()) then
		self.atVoid = true
		self:SaveItems()
		self:SaveUpdateTime()
	end
end

function MyBagsCache:VOID_TRANSFER_DONE()
	-- Move items between bags and void
	if (CanUseVoidStorage()) then
		self.atVoid = true
		self:SaveItems()
		self:SaveUpdateTime()
	end
end

--[[
function MyBagsCache:INVENTORY_SEARCH_UPDATE()
	-- Search box change
end
]]

function MyBagsCache:VOID_STORAGE_OPEN()
	-- Open Void
	if (CanUseVoidStorage()) then
		self.atVoid = true
		self:SaveItems()
		self:SaveUpdateTime()
	end
end

function MyBagsCache:VOID_STORAGE_CLOSE()
	-- Close Void
	self.atVoid = false
end

function MyBagsCache:PLAYER_MONEY()
	self.db.global[self.Player].cash = GetMoney();
	self:SaveUpdateTime()
end

function MyBagsCache:PLAYERBANKBAGSLOTS_CHANGED()
	local numSlots, full = GetNumBankSlots()
	local cost = GetBankSlotCost(numSlots)
	if not self.db.global[self.Player].BankSlots then
		self.db.global[self.Player].BankSlots = {}
	end
	self.db.global[self.Player].BankSlots = {
		["Number"] = numSlots,
		["Cost"] = cost,
		["Full"] = full
	}
	self:SaveUpdateTime()
end

function MyBagsCache:PLAYERBANKSLOTS_CHANGED()
	local itemIndex
	for itemIndex = 1, 28 do
		self:SaveItemInfo(BANK_CONTAINER, itemIndex)	
	end
	self:SaveUpdateTime()
end

function MyBagsCache:BAG_UPDATE(event, bagIndex)
	if not self.atBank and bagIndex > 4 and bagIndex <= 11 then
		return
	end
	local slots = self:SaveBagInfo(bagIndex)
	local itemIndex
	for itemIndex = 1, slots do
		self:SaveItemInfo(bagIndex, itemIndex)
	end
	self:SaveUpdateTime()
end

function MyBagsCache:UNIT_INVENTORY_CHANGED(event, unit)
	if (unit == "player") then
		self:SaveEquipment()
		self:SaveUpdateTime()
	end
end

function MyBagsCache:BANKFRAME_OPENED()
	self.atBank = true
	self:SaveItems()
	self:SaveUpdateTime()
end

function MyBagsCache:BANKFRAME_CLOSED()
	self.atBank = false
end

function MyBagsCache:SaveUpdateTime()
	self.db.global[self.Player].updateTime = GetTime()
end

function MyBagsCache:SaveItems()
	self:SaveVoid()
	self:SaveInventory()
	self:SaveBank()
	self:SaveEquipment()
	self:PLAYER_MONEY()
end

function MyBagsCache:SaveVoid()
	if not self.atVoid then return end
	if not self.db.global[self.Player]["Void"] then
		self.db.global[self.Player]["Void"] = {}
	end
	local itemIndex
	local VOID_STORAGE_SIZE = 80
	for itemIndex = 1, VOID_STORAGE_SIZE do
		local	itemID, texture = GetVoidItemInfo(itemIndex);
		if (itemID) then
			local myName, myLink = GetItemInfo(itemID)
			local myColor = select(2, GetItemInfoFromLink(myLink))
			self.db.global[self.Player]["Void"][itemIndex] = {
				["Name"] = myName,
				["Color"] = myColor,
				["Link"] = myLink,
				["Count"] = 1,
				["Texture"] = texture,
			}
		else
			self.db.global[self.Player]["Void"][itemIndex] = nil
		end
	end
end

function MyBagsCache:SaveInventory()
	local bagIndex
	for bagIndex = 0, 4 do
		local slots = self:SaveBagInfo(bagIndex)
		local itemIndex
		for itemIndex = 1, slots do
			self:SaveItemInfo(bagIndex, itemIndex)
		end
	end
end

function MyBagsCache:SaveBank()
	if not self.atBank then return end
	if not self.db.global[self.Player][BANK_CONTAINER] then
		self.db.global[self.Player][BANK_CONTAINER] = {}
	end
	if not self.db.global[self.Player][BANK_CONTAINER][0] then
		self.db.global[self.Player][BANK_CONTAINER][0] = {}
	end
	self.db.global[self.Player][BANK_CONTAINER][0] = {
		["Count"] = 28
	}
	local itemIndex, bagIndex
	for itemIndex = 1, 28 do
		self:SaveItemInfo(BANK_CONTAINER, itemIndex)	
	end
	for bagIndex = 5, 11 do
		local slots = self:SaveBagInfo(bagIndex)
		for itemIndex = 1, slots do
			self:SaveItemInfo(bagIndex, itemIndex)
		end
	end
end

function MyBagsCache:SaveEquipment()
	if not self.db.global[self.Player].equipment then
		self.db.global[self.Player].equipment = {}
	end
	local itemIndex
	for itemIndex = 0, 19 do
		self:SaveEquipmentInfo(itemIndex)
	end
	local hasRelic = UnitHasRelicSlot("player")
	self.db.global[self.Player].equipment.hasRelic = hasRelic
end

function MyBagsCache:SaveBagInfo(bagIndex)
	local invID -- get Inventory ID
	if bagIndex >= 1 and bagIndex <=4 then
		invID = ContainerIDToInventoryID(bagIndex)
	elseif bagIndex >= 5 and bagIndex <= 11 then
		invID = BankButtonIDToInvSlotID(bagIndex, 1)
	else
		invID = nil;
	end
	if bagIndex == 0 then  -- Set Count to 16
		if not self.db.global[self.Player][bagIndex] then
			self.db.global[self.Player][bagIndex]= {}
		end
		self.db.global[self.Player][bagIndex][0] = {
			["Count"] = 16,
			["Texture"] = "Interface\\Buttons\\Button-Backpack-Up"
		}
		return 16
	end
	local bagSize = GetContainerNumSlots(bagIndex)
	local itemLink = GetInventoryItemLink("player", invID)
	if itemLink then
		local name, myColor, myLink = GetItemInfoFromLink(itemLink)
		local soulbound, madeBy = nil
		local texture = GetInventoryItemTexture("player", invID)
		if not self.db.global[self.Player][bagIndex] then
			self.db.global[self.Player][bagIndex] = {}
		end
		self.db.global[self.Player][bagIndex][0] = {
			["Name"] = name,
			["Color"] = myColor,
			["Link"] = myLink,
			["Count"] = bagSize,
			["Texture"] = texture,
			["Soulbound"] = soulbound,
			["MadeBy"] = madeBy
		}
	end
	if bagSize > 0 then
		return bagSize
	else
		self.db.global[self.Player][bagIndex] = nil
		return 0
	end
end

function MyBagsCache:SaveEquipmentInfo(itemIndex)
	local itemLink = GetInventoryItemLink("player", itemIndex)
	if itemLink or itemIndex == 0 then
--		local myColor, myLink, myName, soulbound, madeBy = nil
		local texture = GetInventoryItemTexture("player", itemIndex)
		local count = GetInventoryItemCount("player", itemIndex)
		local myName, myColor, myLink = GetItemInfoFromLink(itemLink)
		if not self.db.global[self.Player].equipment[itemIndex] then
			self.db.global[self.Player].equipment[itemIndex] = {}
		end
		self.db.global[self.Player].equipment[itemIndex] = {
			["Name"] = myName,
			["Color"] = myColor,
			["Link"] = myLink,
			["Count"] = count,
			["Texture"] = texture,
			["Soulbound"] = nil,
			["MadeBy"] = nil,
		}
	else
		self.db.global[self.Player].equipment[itemIndex] = nil
	end
end

function MyBagsCache:SaveItemInfo(bagIndex, itemIndex)
	local itemLink = GetContainerItemLink(bagIndex, itemIndex)
	if itemLink then
		local myName, myColor, myLink = GetItemInfoFromLink(itemLink)
		local texture, itemCount = GetContainerItemInfo(bagIndex, itemIndex)
		self.db.global[self.Player][bagIndex][itemIndex] = {
			["Name"] = myName,
			["Color"] = myColor,
			["Link"] = myLink,
			["Count"] = itemCount,
			["Texture"] = texture,
			["Soulbound"] = nil,
			["MadeBy"] = nil,
		}
	else
		self.db.global[self.Player][bagIndex][itemIndex] = nil
	end
end

function MyBagsCache:GetInfo(bagIndex, slotIndex, charID)
	slotIndex = tonumber(slotIndex or 0)
	if not self.db.global[charID] or not self.db.global[charID][bagIndex] or not self.db.global[charID][bagIndex][slotIndex] then
		return nil, 0, nil, nil, nil
	else
		local data = self.db.global[charID][bagIndex][slotIndex]
		return data.Texture, data.Count, data.Link, data.Color, data.Name
	end
end

function MyBagsCache:GetRelic(charID)
	if not self.db.global[charID] or not self.db.global[charID].equipment or not self.db.global[charID].equipment.hasRelic then
		return nil
	else 
		return self.db.global[charID].equipment.hasRelic
	end
end

function MyBagsCache:GetCash(charID)
	if not self.db.global[charID] or not self.db.global[charID].cash then
		return nil
	else
		return self.db.global[charID].cash
	end
end

function MyBagsCache:GetCharList(realm)
	local result = {}
	local cache = self.db.global
	local index, value
	for index, value in pairs(cache) do
		if index ~= "profiles" then
			local charName, realmID = SplitString(index, L["CHARACTER_DELIMITOR"])
			if (not realm or realmID == realm) then
				result[index] = {
					name = charName,
					realm = realmID,
				}
			end
		end
	end
	return result
end

function MyBagsCache:GetSortedCharList(sorttype, realm)
	local result = {}
	local idx = 0
	local cache = self.db.global
	local index, value
	for index, value in pairs(cache) do
		if index ~= "profiles" then
			local realmID = select(2, SplitString(index, L["CHARACTER_DELIMITOR"]))
			if (not realm or realmID == realm) then
				idx = idx + 1
				result[idx] = index
			end
		end
	end
	local swapped
	local x_time, y_time
	local q, w, i
	repeat
		swapped = 0
		for i = 1, idx-1 do
			q = result[i]
			w = result[i+1]
			if (not self.db.global[q].updateTime) then
				x_time = 0
			else
				x_time = self.db.global[q].updateTime
			end
			if (not self.db.global[w].updateTime) then
				y_time = 0
			else
				y_time = self.db.global[w].updateTime
			end
			if SortChars(q, w, x_time, y_time, sorttype) then
				result[i] = w
				result[i+1] = q
				swapped = 1
			end
		end
	until swapped == 0
	return result
end
