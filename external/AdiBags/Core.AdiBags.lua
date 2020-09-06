local ADDON_NAME, namespace = ...
local L = namespace.L

local addonName = 'AdiBags'
local Version = nil
if select(4, GetAddOnInfo(addonName)) then
	if IsAddOnLoaded(addonName) then
		Version = GetAddOnMetadata(addonName, 'Version')
		CaerdonWardrobe:RegisterAddon(addonName)
	end
end

if Version then
	local AdiBags = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
	local mod = AdiBags:NewModule("CaerdonWardrobeAdiBagsUpdate", "ABEvent-1.0")
	mod.uiName = L["Caerdon Wardrobe"]
	mod.uiDesc= L["Identifies transmog appearances that still need to be learned"]

	function mod:OnEnable()
		self:RegisterMessage('AdiBags_UpdateButton', 'UpdateButton')
	end

	function mod:UpdateButton(event, button)
		local itemLink = button.itemLink
		local bag = button.bag
		local slot = button.slot

		local options = {
			showMogIcon=true, 
			showBindStatus=true,
			showSellables=true,
			iconPosition="TOPRIGHT" 
		}

		CaerdonWardrobe:UpdateButtonLink(itemLink, bag, slot, button, options)
	end

	-- local canLearnFilter = AdiBags:RegisterFilter("CanLearn", 92, 'ABEvent-1.0')
	-- canLearnFilter.uiName = L["Can Learn"]
	-- canLearnFilter.uiDesc = L['Transmog appearances that can be unlocked by the current toon']

	-- function canLearnFilter:OnInitialize()
	--   self.db = AdiBags.db:RegisterNamespace('CanLearn', {
	--     profile = { showBoE = true, showBoA = true },
	--     char = {  },
	--   })
	-- end

	-- function canLearnFilter:Filter(slotData)

	-- 	for k, v in pairs( slotData ) do
	-- 	   print(k, v)
	-- 	end

	-- 	print("--------------")

	-- 	local bag, slot
	-- 	local itemID = slotData.itemId

	-- 	if slotData.bag == BANK_CONTAINER then
	-- 		bag = "BankFrame"
	-- 		slot = slotData.slot
	-- 	else
	-- 		bag = slotData.bag
	-- 		slot = slotData.slot
	-- 	end

	-- 	local onItemProcessed = 
	-- 		function(mogStatus, bindingText)
	-- 			local section
	-- 			if mogStatus == "own" then
	-- 				section = L["Can Learn"]
	-- 			elseif mogStatus == "other" then
	-- 				section = L["Can Learn Other"]
	-- 			end
	-- 		end

	-- 	CaerdonWardrobe:UpdateButton(itemID, bag, slot, true, true, nil, onItemProcessed)

	-- 	-- for i = 1,6 do
	-- 	-- 	local t = tooltip.leftside[i]:GetText()
	-- 	-- 	if self.db.profile.enableBoE and t == ITEM_BIND_ON_EQUIP then
	-- 	-- 		return L["BoE"]
	-- 	-- 	elseif self.db.profile.enableBoA and (t == ITEM_ACCOUNTBOUND or t == ITEM_BIND_TO_BNETACCOUNT or t == ITEM_BNETACCOUNTBOUND) then
	-- 	-- 		return L["BoA"]
	-- 	-- 	end
	-- 	-- end
	-- 	-- tooltip:Hide()
	-- end

	local function OnEvent(self, event, ...)
		local handler = self[event]
		if(handler) then
			handler(self, ...)
		end
	end

	local eventFrame = CreateFrame("FRAME")
	eventFrame:RegisterEvent "ADDON_LOADED"
	eventFrame:RegisterEvent "TRANSMOG_COLLECTION_UPDATED"
	eventFrame:SetScript("OnEvent", OnEvent)

	local function RefreshItems()
		mod:SendMessage('AdiBags_FiltersChanged')
	end

	function eventFrame:ADDON_LOADED(name)
	end

	function eventFrame:TRANSMOG_COLLECTION_UPDATED()
		RefreshItems()
	end
end

