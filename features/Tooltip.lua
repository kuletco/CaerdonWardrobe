local TooltipMixin, Tooltip = {}
local frame = CreateFrame("frame")
frame:RegisterEvent "ADDON_LOADED"
frame:SetScript("OnEvent", function(this, event, ...)
    Tooltip[event](Quest, ...)
end)

local SpecMap = {
    [250] = "Blood Death Knight",
    [251] = "Frost Death Knight",
    [252] = "Unholy Death Knight",

    [577] = "Havoc Demon Hunter",
    [581] = "Vengeance Demon Hunter",

    [102] = "Balance Druid",
    [103] = "Feral Druid",
    [104] = "Guardian Druid",
    [105] = "Restoration Druid",

    [253] = "Beast Mastery Hunter",
    [254] = "Marksmanship Hunter",
    [255] = "Survival Hunter",

    [62] = "Arcane Mage",
    [63] = "Fire Mage",
    [64] = "Frost Mage",

    [268] = "Brewmaster Monk",
    [270] = "Mistweaver Monk",
    [269] = "Windwalker Monk",

    [65] = "Holy Paladin",
    [66] = "Protection Paladin",
    [70] = "Retribution Paladin",

    [256] = "Discipline Priest",
    [257] = "Holy Priest",
    [258] = "Shadow Priest",

    [259] = "Assassination Rogue",
    [260] = "Outlaw Rogue",
    [261] = "Subtlety Rogue",

    [262] = "Elemental Shaman",
    [263] = "Enhancement Shaman",
    [264] = "Restoration Shamana",

    [265] = "Affliction Warlock",
    [266] = "Demonology Warlock",
    [267] = "Destruction Warlock",

    [71] = "Arms Warrior",
    [72] = "Fury Warrior",
    [73] = "Protection Warrior"
}

function TooltipMixin:ADDON_LOADED(name)
    -- Disabling for now until I can get useful info from a Trainer API
    -- if name == "Blizzard_TrainerUI" then
    --     hooksecurefunc("ClassTrainerFrame_SetServiceButton", function(...) Tooltip:OnClassTrainerFrameSetServiceButton(...) end)
	-- end
end

function TooltipMixin:OnLoad()
    -- TODO: Add Debug enable option setting

    GameTooltip:HookScript("OnTooltipSetItem", function (...) Tooltip:OnTooltipSetItem(...) end)
    ItemRefTooltip:HookScript("OnTooltipSetItem", function(...) Tooltip:OnTooltipSetItem(...) end)

    hooksecurefunc(GameTooltip, "SetBagItem", function (...) Tooltip:OnTooltipSetBagItem(...) end)
    hooksecurefunc(GameTooltip, "SetInventoryItem", function (...) Tooltip:OnTooltipSetInventoryItem(...) end)
    hooksecurefunc("BattlePetToolTip_Show", function (...) Tooltip:OnBattlePetTooltipShow(...) end)
    hooksecurefunc("FloatingBattlePet_Show", function(...) Tooltip:OnFloatingBattlePetShow(...) end)
    hooksecurefunc("GameTooltip_AddQuestRewardsToTooltip", function(...) Tooltip:OnGameTooltipAddQuestRewardsToTooltip(...) end)
    -- For embedded items (for quests, at least)
    hooksecurefunc("EmbeddedItemTooltip_OnTooltipSetItem", function(...) Tooltip:OnEmbeddedItemTooltipSetItem(...) end)

    -- hooksecurefunc("TaskPOI_OnEnter", function(...) Tooltip:OnTaskPOIOnEnter(...) end)
    
	-- Show missing info in tooltips
	-- NOTE: This causes a bug with tooltip scanning, so we disable
	--   briefly and turn it back on with each scan.
	-- C_TransmogCollection.SetShowMissingSourceInItemTooltips(true)
	SetCVar("missingTransmogSourceInItemTooltips", 1)

    -- May need this for inner items but has same item reference in current tests resulting in double
    -- ItemRefTooltip:HookScript("OnShow", function (tooltip, ...) Tooltip:OnTooltipSetItem(tooltip, ...) end)

    -- TODO: Can hook spell in same way if needed...
    -- GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
    -- ItemRefTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
end

-- function TooltipMixin:OnTaskPOIOnEnter(taskPOI, skipSetOwner)
--     if not HaveQuestData(taskPOI.questID) then
--         return -- retrieving item data
--     end

--     if C_QuestLog.IsQuestReplayable(taskPOI.questID) then
--         itemLink = QuestUtils_GetReplayQuestDecoration(taskPOI.questID)
--     else
--         itemLink = GetQuestLink(taskPOI.questID)
--     end

--     local item = CaerdonItem:CreateFromItemLink(itemLink)
--     Tooltip:ProcessTooltip(GameTooltip, item)

--     GameTooltip.recalculatePadding = true;
--     -- GameTooltip:SetHeight(GameTooltip:GetHeight() + 2)
-- end

function TooltipMixin:OnGameTooltipAddQuestRewardsToTooltip(tooltip, questID, style)
    local itemLink = GetQuestLink(questID)
    -- TODO: This happens with assault quests, at least... need to look into more
    if itemLink then
        local item = CaerdonItem:CreateFromItemLink(itemLink)
        Tooltip:ProcessTooltip(tooltip, item)
    end
end

function TooltipMixin:OnEmbeddedItemTooltipSetItem(tooltip)
    if tooltip.itemID then
        local item = CaerdonItem:CreateFromItemID(tooltip.itemID)
        Tooltip:ProcessTooltip(tooltip.Tooltip, item, true)
    end
end

local tooltipItem
function TooltipMixin:OnTooltipSetBagItem(tooltip, bag, slot)
    if bag and slot then
        tooltipItem = CaerdonItem:CreateFromBagAndSlot(bag, slot)
    else
        tooltipItem = nil
    end
end

function TooltipMixin:OnTooltipSetInventoryItem(tooltip, target, slot)
    if slot then
        tooltipItem = CaerdonItem:CreateFromEquipmentSlot(slot)
    else
        tooltipItem = nil
    end
end
function TooltipMixin:OnTooltipSetItem(tooltip)
    local itemName, itemLink = tooltip:GetItem()
    if itemLink then
        if not tooltipItem or tooltipItem:GetItemLink() ~= itemLink then
            tooltipItem = CaerdonItem:CreateFromItemLink(itemLink)
        end

        if not tooltipItem:IsItemEmpty() then
            Tooltip:ProcessTooltip(tooltip, tooltipItem)
        end
    end
end

-- This works but can't seem to do anything useful to get item info with the index (yet)
-- function TooltipMixin:OnClassTrainerFrameSetServiceButton(skillButton, skillIndex, playerMoney, selected, isTradeSkill)
--     if not skillButton.caerdonTooltipHooked then
--         skillButton.caerdonTooltipHooked = true
--         skillButton:HookScript("OnEnter", function (button, ...) 
--             print(button:GetID())
--         end)
--     end
-- end

function TooltipMixin:OnBattlePetTooltipShow(speciesID, level, quality, health, power, speed, customName)
    local item = CaerdonItem:CreateFromSpeciesInfo(speciesID, level, quality, health, power, speed, customName)
	Tooltip:ProcessTooltip(BattlePetTooltip, item)
end

function TooltipMixin:OnFloatingBattlePetShow(speciesID, level, quality, health, power, speed, customName, petID)
    -- Not sure where all this is used - definitely when hyperlinking the Pet Cage.  Maybe AH?
    -- TODO: If name comes in blank, I think there might be some logic to use it when customName isn't set.

    if not CaerdonWardrobeConfig.Debug.Enabled then
        -- Not doing anything other than debug for tooltips right now
        return
    end

    local tooltip = FloatingBattlePetTooltip
    local ownedText = tooltip.Owned:GetText() or ""
    local origHeight = tooltip.Owned:GetHeight()

    tooltip.Owned:SetWordWrap(true)

    local extraText = "Caerdon Wardrobe|n"

    local englishFaction = UnitFactionGroup("player")
    local specIndex = GetSpecialization()
    local specID, specName, specDescription, specIcon, specBackground, specRole, specPrimaryStat = GetSpecializationInfo(specIndex)

    extraText = extraText .. format("Spec: %s", SpecMap[specID] or specID)
    extraText = extraText .. format("|nLevel: %s", UnitLevel("player"))
    extraText = extraText .. format("|nFaction: %s|n", englishFaction)

    local item = CaerdonItem:CreateFromSpeciesInfo(speciesID, level, quality, health, power, speed, customName, petID)
    if item then
        local itemData = item:GetItemData()
        extraText = extraText .. format("|nIdentified Type: %s", item:GetCaerdonItemType())

        local forDebugUse = item:GetForDebugUse()
        extraText = extraText .. format("|nLink Type: %s", forDebugUse.linkType)
        extraText = extraText .. format("|nOptions: %s|n", forDebugUse.linkOptions)
        
        if item:GetCaerdonItemType() == CaerdonItemType.BattlePet then
            local petInfo = itemData and itemData:GetBattlePetInfo()
            if petInfo then
                extraText = extraText .. format("|nSpecies ID: %s", petInfo.speciesID)
                extraText = extraText .. format("|nNum Collected: %s", petInfo.numCollected)
            end
        end
    end

    local ownedLine = format("%s|n%s", ownedText, extraText)

    tooltip.Owned:SetText(ownedLine)
    tooltip:SetHeight(tooltip:GetHeight() + tooltip.Owned:GetHeight() - origHeight + 2)
    tooltip.Delimiter:ClearAllPoints();
    tooltip.Delimiter:SetPoint("TOPLEFT", tooltip.Owned, "BOTTOMLEFT", -6, -2)
end

function TooltipMixin:AddTooltipData(tooltip, title, value, valueColor)
	local noWrap = false;
    local wrap = true;

    valueColor = valueColor or HIGHLIGHT_FONT_COLOR
    
    if not title then
        GameTooltip_AddErrorLine(tooltip, format("Dev Error", "Missing Title"));
        return
    end
   
    if title and value == nil then
        GameTooltip_AddErrorLine(tooltip, format("Missing %s", title));
    elseif tooltip == BattlePetTooltip or tooltip == FloatingBattlePetTooltip then -- assuming this for now
        GameTooltip_AddColoredLine(tooltip, format("%s: %s", title, value), HIGHLIGHT_FONT_COLOR, wrap)
    else
        GameTooltip_AddColoredDoubleLine(tooltip, format("%s:", title), tostring(value), HIGHLIGHT_FONT_COLOR, valueColor, wrap);
    end
end

function TooltipMixin:AddTooltipDoubleData(tooltip, title, value, title2, value2, valueColor)
	local noWrap = false;
    local wrap = true;

    valueColor = valueColor or HIGHLIGHT_FONT_COLOR

    if not title or not title2 then
        GameTooltip_AddErrorLine(tooltip, format("Dev Error", "Missing Title"));
        return
    end
    
    if value == nil then
        GameTooltip_AddErrorLine(tooltip, format("Missing %s", title));
    end

    if value2 == nil then
        GameTooltip_AddErrorLine(tooltip, format("Missing %s", title2));
    end

    if value ~= nil and value2 ~= nil then
        if tooltip == BattlePetTooltip or tooltip == FloatingBattlePetTooltip then -- assuming this for now
            GameTooltip_AddColoredLine(tooltip, format("%s: %s", title, value), HIGHLIGHT_FONT_COLOR, wrap)
            GameTooltip_AddColoredLine(tooltip, format("%s: %s", title2, value2), HIGHLIGHT_FONT_COLOR, wrap)
        else
            GameTooltip_AddColoredDoubleLine(tooltip, format("%s / %s:", title, title2), format("%s / %s", value, value2), HIGHLIGHT_FONT_COLOR, valueColor, wrap);
        end
    elseif value ~= nil then
        if tooltip == BattlePetTooltip or tooltip == FloatingBattlePetTooltip then -- assuming this for now
            GameTooltip_AddColoredLine(tooltip, format("%s: %s", title, value), HIGHLIGHT_FONT_COLOR, wrap)
        else
            GameTooltip_AddColoredDoubleLine(tooltip, format("%s:", title), tostring(value), HIGHLIGHT_FONT_COLOR, valueColor, wrap);
        end
    elseif value2 ~= nil then
        if tooltip == BattlePetTooltip or tooltip == FloatingBattlePetTooltip then -- assuming this for now
            GameTooltip_AddColoredLine(tooltip, format("%s: %s", title, value2), HIGHLIGHT_FONT_COLOR, wrap)
        else
            GameTooltip_AddColoredDoubleLine(tooltip, format("%s:", title), tostring(value2), HIGHLIGHT_FONT_COLOR, valueColor, wrap);
        end
    end
end

-- local cancelFuncs = {}
function TooltipMixin:ProcessTooltip(tooltip, item, isEmbedded)
    -- if cancelFuncs[tooltip] then
    --     cancelFuncs[tooltip]()
    --     cancelFuncs[tooltip] = nil
    -- end

    -- function continueLoad()
        if not CaerdonWardrobeConfig.Debug.Enabled then
            -- Not doing anything other than debug for tooltips right now
            return
        end

        GameTooltip_AddBlankLineToTooltip(tooltip);
        GameTooltip_AddColoredLine(tooltip, "Caerdon Wardrobe", LIGHTBLUE_FONT_COLOR);

        if not isEmbedded then
            local specIndex = GetSpecialization()
            local specID, specName, specDescription, specIcon, specBackground, specRole, specPrimaryStat = GetSpecializationInfo(specIndex)
            self:AddTooltipData(tooltip, "Spec", SpecMap[specID] or specID)
            self:AddTooltipData(tooltip, "Level", UnitLevel("player"))

            local englishFaction = UnitFactionGroup("player")
            self:AddTooltipData(tooltip, "Faction", englishFaction)

            GameTooltip_AddBlankLineToTooltip(tooltip);
        end

        local forDebugUse = item:GetForDebugUse()
        local identifiedType = item:GetCaerdonItemType()

        local identifiedColor = GREEN_FONT_COLOR
        if identifiedType == CaerdonItemType.Unknown then
            identifiedColor = RED_FONT_COLOR
        end
            
        self:AddTooltipData(tooltip, "Identified Type", identifiedType, identifiedColor)
        self:AddTooltipDoubleData(tooltip, "Link Type", forDebugUse.linkType, "Options", forDebugUse.linkOptions)
        if item:GetItemQuality() then
            self:AddTooltipData(tooltip, "Quality", _G[format("ITEM_QUALITY%d_DESC", item:GetItemQuality())], item:GetItemQualityColor().color)
        end

        local itemLocation = item:GetItemLocation()
        if itemLocation and itemLocation:HasAnyLocation() then
            if itemLocation:IsEquipmentSlot() then
                self:AddTooltipData(tooltip, "Equipment Slot", tostring(itemLocation:GetEquipmentSlot()))
            end

            if itemLocation:IsBagAndSlot() then
                local bag, slot = itemLocation:GetBagAndSlot();
                self:AddTooltipDoubleData(tooltip, "Bag", bag, "Slot", slot)

                local canTransmog, error = C_Item.CanItemTransmogAppearance(itemLocation)
                self:AddTooltipData(tooltip, "Can Item Transmog Appearance", tostring(canTransmog))    
            end
        end

        GameTooltip_AddBlankLineToTooltip(tooltip);

        if identifiedType ~= CaerdonItemType.BattlePet and identifiedType ~= CaerdonItemType.Quest then
            self:AddTooltipData(tooltip, "Item ID", item:GetItemID())
            self:AddTooltipDoubleData(tooltip, "Item Type", item:GetItemType(), "SubType", item:GetItemSubType())
            self:AddTooltipDoubleData(tooltip, "Item Type ID", item:GetItemTypeID(), "SubType ID", item:GetItemSubTypeID())
            self:AddTooltipData(tooltip, "Binding", item:GetBinding())

            GameTooltip_AddBlankLineToTooltip(tooltip);

            self:AddTooltipData(tooltip, "Expansion ID", item:GetExpansionID())
            self:AddTooltipData(tooltip, "Is Crafting Reagent", tostring(item:GetIsCraftingReagent()))
        end
        

        -- All data from here on out should come from the API
        -- TODO: Add additional option to show item link since it's so large?
        -- self:AddTooltipData(tooltip, "Item Link", gsub(item:GetItemLink(), "\124", "\124\124"))

        if identifiedType == CaerdonItemType.BattlePet or identifiedType == CaerdonItemType.CompanionPet then
            self:AddPetInfoToTooltip(tooltip, item)
        elseif identifiedType == CaerdonItemType.Equipment then
            self:AddTransmogInfoToTooltip(tooltip, item)
        end
    -- end

    -- if item:IsItemEmpty() then
    --     continueLoad()
    -- else
    --     cancelFuncs[tooltip] = item:ContinueWithCancelOnItemLoad(continueLoad)
    -- end
end


function TooltipMixin:AddPetInfoToTooltip(tooltip, item)
    local itemType = item:GetCaerdonItemType()

    if itemType ~= CaerdonItemType.BattlePet and itemType ~= CaerdonItemType.CompanionPet then
        return
    end

    local itemData = item:GetItemData()

    if itemType == CaerdonItemType.CompanionPet then
        GameTooltip_AddBlankLineToTooltip(tooltip);

        local petInfo = itemData:GetCompanionPetInfo()
        local speciesID = petInfo.speciesID
        self:AddTooltipData(tooltip, "Species ID", speciesID)
        self:AddTooltipData(tooltip, "Num Collected", petInfo.numCollected or 0)
        self:AddTooltipData(tooltip, "Pet Type", petInfo.petType)
        self:AddTooltipData(tooltip, "Source", petInfo.sourceText)
    elseif itemType == CaerdonItemType.BattlePet then
        local petInfo = itemData:GetBattlePetInfo()
        local speciesID = petInfo.speciesID
        self:AddTooltipData(tooltip, "Species ID", petInfo.speciesID)
        self:AddTooltipData(tooltip, "Num Collected", petInfo.numCollected or 0)
    end
end

function TooltipMixin:AddTransmogInfoToTooltip(tooltip, item)
    local itemData = item:GetItemData()
    local transmogInfo = itemData:GetTransmogInfo()

    self:AddTooltipData(tooltip, "Item Equip Location", item:GetEquipLocation())

    if item:GetSetID() then
        self:AddTooltipData(tooltip, "Item Set ID", item:GetSetID())
    end

    local equipmentSets = itemData:GetEquipmentSets()
    if equipmentSets then
        local setNames = equipmentSets[1]
        for setIndex = 2, #equipmentSets do
            setNames = setNames .. ", " .. equipmentSets[setIndex]
        end

        self:AddTooltipData(tooltip, "Equipment Sets", setNames)
    end

	if transmogInfo.isTransmog then
		self:AddTooltipData(tooltip, "Appearance ID", transmogInfo.appearanceID)
        self:AddTooltipData(tooltip, "Source ID", transmogInfo.sourceID)

        GameTooltip_AddBlankLineToTooltip(tooltip);

        self:AddTooltipData(tooltip, "Needs Item", transmogInfo.needsItem)
        self:AddTooltipData(tooltip, "Other Needs Item", transmogInfo.otherNeedsItem)
        self:AddTooltipData(tooltip, "Is Completionist Item", transmogInfo.isCompletionistItem)
        self:AddTooltipData(tooltip, "Matches Loot Spec", transmogInfo.matchesLootSpec)

        local requirementsColor = (transmogInfo.hasMetRequirements == false and RED_FONT_COLOR) or nil
        self:AddTooltipData(tooltip, "Has Met Requirements", transmogInfo.hasMetRequirements, requirementsColor)
        self:AddTooltipData(tooltip, "Item Min Level", item:GetMinLevel())
        self:AddTooltipData(tooltip, "Can Equip", transmogInfo.canEquip)

        local matchedSources = transmogInfo.forDebugUseOnly.matchedSources
        self:AddTooltipData(tooltip, "Matched Source", matchedSources and #matchedSources > 0)

        local appearanceInfo = transmogInfo.forDebugUseOnly.appearanceInfo
        if appearanceInfo then
            GameTooltip_AddBlankLineToTooltip(tooltip);

            self:AddTooltipData(tooltip, "Appearance Collected", appearanceInfo.appearanceIsCollected)
            self:AddTooltipData(tooltip, "Source Collected", appearanceInfo.sourceIsCollected)
            self:AddTooltipData(tooltip, "Is Conditionally Known", appearanceInfo.sourceIsCollectedConditional)
            self:AddTooltipData(tooltip, "Is Permanently Known", appearanceInfo.sourceIsCollectedPermanent)
            self:AddTooltipData(tooltip, "Has Non-level Reqs", appearanceInfo.appearanceHasAnyNonLevelRequirements)
            self:AddTooltipData(tooltip, "Meets Non-level Reqs", appearanceInfo.appearanceMeetsNonLevelRequirements)
            self:AddTooltipData(tooltip, "Appearance Is Usable", appearanceInfo.appearanceIsUsable)
            self:AddTooltipData(tooltip, "Meets Condition", appearanceInfo.meetsTransmogPlayerCondition)
        else
        end
	end
end

Tooltip = CreateFromMixins(TooltipMixin)
Tooltip:OnLoad()
