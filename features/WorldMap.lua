local WorldMapMixin = {}

function WorldMapMixin:GetName()
	return "WorldMap"
end

function WorldMapMixin:Init()
	hooksecurefunc (WorldMap_WorldQuestPinMixin, "RefreshVisuals", function (...)
		if not IsModifiedClick("COMPAREITEMS") and not ShoppingTooltip1:IsShown() then
			self:UpdatePin(...);
		end
	end)
end

function WorldMapMixin:SetTooltipItem(tooltip, item, locationInfo)
	tooltip:SetHyperlink(item:GetItemLink())

	-- TODO: Ignoring the WorldMap tooltip itself for now since it's the item I care about
	-- May need to revisit if I care about the quest itself

	-- GameTooltip_AddQuestRewardsToTooltip(tooltip, locationInfo.questID)
	
	-- TODO: This was for scanning the embedded item, but I don't think I need it now.
	-- Will need to handle somehow if I do.
	-- scanTip = scanTip.ItemTooltip.Tooltip
end

function WorldMapMixin:Refresh()
end

function WorldMapMixin:UpdatePin(pin)
	QuestEventListener:AddCallback(pin.questID, function()
		local options = {
			iconOffset = -5,
			iconSize = 60,
			overridePosition = "TOPRIGHT",
			-- itemCountOffset = 10,
			-- TODO: Make text bigger?
			-- bindingScale = 1.5
		}

		local questLink = GetQuestLink(pin.questID)
		if not questLink then 
			local questName
			if isShadowlands then
				questName = C_QuestLog.GetTitleForQuestID(questID)
			else
				questName = C_QuestLog.GetQuestInfo(questID)
			end

			local questLevel = C_QuestLog.GetQuestDifficultyLevel(questID)
			questLink = format("|cff808080|Hquest:%d:%d|h[%s]|h|r", questID, questLevel, questName)
		end

		local item = CaerdonItem:CreateFromItemLink(questLink)
		local itemData = item:GetItemData()
		local questInfo = itemData:GetQuestInfo()

		-- TODO: Review if necessary to iterate through rewards and find unknown ones...
		local bestIndex, bestType = QuestUtils_GetBestQualityItemRewardIndex(pin.questID)
		local reward
		if bestType == "reward" then
			reward = questInfo.rewards[bestIndex]
		elseif bestType == "choice" then
			reward = questInfo.choices[bestIndex]
		end

		if reward then
			if reward.itemLink then
				CaerdonWardrobe:UpdateButtonLink(reward.itemLink, self:GetName(), { questID = pin.questID }, pin, options)
			elseif reward.itemID then
				local _, itemLink = GetItemInfo(reward.itemID)
				CaerdonWardrobe:UpdateButtonLink(itemLink, self:GetName(), { questID = pin.questID }, pin, options)
			else
				CaerdonWardrobe:ClearButton(pin)
			end
		else
			CaerdonWardrobe:ClearButton(pin)
		end
	end)
end

CaerdonWardrobe:RegisterFeature(WorldMapMixin)
