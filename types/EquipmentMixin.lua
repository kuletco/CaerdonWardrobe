CaerdonEquipment = {}
CaerdonEquipmentMixin = {}

--[[static]] function CaerdonEquipment:CreateFromCaerdonItem(caerdonItem)
	if type(caerdonItem) ~= "table" or not caerdonItem.GetCaerdonItemType then
		error("Usage: CaerdonEquipment:CreateFromCaerdonItem(caerdonItem)", 2)
	end

    local itemType = CreateFromMixins(CaerdonEquipmentMixin)
    itemType.item = caerdonItem
    return itemType
end

function CaerdonEquipmentMixin:GetEquipmentSets()
    local equipmentSets

    -- Use equipment set for binding text if it's assigned to one
    if C_EquipmentSet.CanUseEquipmentSets() then
        local setIndex
        for setIndex=1, C_EquipmentSet.GetNumEquipmentSets() do
            local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs()
            local equipmentSetID = equipmentSetIDs[setIndex]
            local name, icon, setID, isEquipped, numItems, numEquipped, numInventory, numMissing, numIgnored = C_EquipmentSet.GetEquipmentSetInfo(equipmentSetID)

            local equipLocations = C_EquipmentSet.GetItemLocations(equipmentSetID)
            if equipLocations then
                local locationIndex
                for locationIndex=INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
                    local location = equipLocations[locationIndex]
                    if location ~= nil then
                        -- TODO: Keep an eye out for a new way to do this in the API
                        local isPlayer, isBank, isBags, isVoidStorage, equipSlot, equipBag, equipTab, equipVoidSlot = EquipmentManager_UnpackLocation(location)
                        equipSlot = tonumber(equipSlot)
                        equipBag = tonumber(equipBag)

                        local isFound = false

                        if isBank and not equipBag then -- main bank container
                            local foundLink = GetInventoryItemLink("player", equipSlot)
                            if foundLink == self.item:GetItemLink() then
                                isFound = true
                            end
                        elseif isBank or isBags then -- any other bag
                            local itemLocation = ItemLocation:CreateFromBagAndSlot(equipBag, equipSlot)
                            if itemLocation:HasAnyLocation() and itemLocation:IsValid() then
                                local foundLink = C_Item.GetItemLink(itemLocation)
                                if foundLink == self.item:GetItemLink() then
                                    isFound = true
                                end
                            end
                        end

                        if isFound then
                            if not equipmentSets then
                                equipmentSets = {}
                            end

                            table.insert(equipmentSets, name)

                            break
                        end
                    end
                end
            end
        end
    end

    return equipmentSets
end

-- Wowhead Transmog Guide - https://www.wowhead.com/transmogrification-overview-frequently-asked-questions
function CaerdonEquipmentMixin:GetTransmogInfo()
    local item = self.item
    local itemParamType = type(item)
    if itemParamType == "string" then
        item = gsub(item, "\124\124", "\124")
        item = CaerdonItem:CreateFromItemLink(item)
    elseif itemParamType == "number" then
        item = CaerdonItem:CreateFromItemID(item)
    elseif itemParamType ~= "table" then
        error("Must specify itemLink, itemID, or CaerdonItem for GetTransmogInfo")
    end

    local itemLink = item:GetItemLink()
    if not itemLink then
        return
    end

    if item:GetCaerdonItemType() ~= CaerdonItemType.Equipment then
        return
    end

    local isBindOnPickup = item:GetBinding() == CaerdonItemBind.BindOnPickup
    local isCompletionistItem = false
    local hasMetRequirements = true
    local needsItem = false
    local otherNeedsItem = false
    local matchesLootSpec = true
    local isTransmog = false

    -- Keep available for debug info
    local appearanceInfo, sourceInfo
    local isInfoReady, canCollect
    local shouldSearchSources
    local appearanceSources
    local currentSourceFound
    local otherSourceFound
    local sourceSpecs
    local lowestLevelFound
    local matchedSources = {}

    -- Appearance is the visual look - can have many sources
    -- Sets can have multiple appearances (normal vs mythic, etc.)
    local appearanceID, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
    if not sourceID then
        -- TODO: Not sure why this is the case?  EncounterJournal links aren't returning source info
        appearanceID, sourceID = C_TransmogCollection.GetItemInfo(item:GetItemID())
    end

    if sourceID then
        -- TODO: Look into this more - doc indicates it's an itemModifiedAppearanceID returned from C_TransmogCollection.GetItemInfo (which may also be sourceID?)
        -- PlayerKnowsSource just seems broken if that's true, though.
        -- VisualID == AppearanceID, SourceID == ItemModifiedAppearanceID
        -- Also check PlayerHasTransmog with the following
        -- print(itemLink .. ",  PlayerHasTransmogItemModifiedAppearance: " .. tostring(C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)) .. ", PlayerKnowsSource: " .. tostring(C_TransmogCollection.PlayerKnowsSource(sourceID)))
    end

    if item:GetMinLevel() and item:GetMinLevel() > UnitLevel("player") then
        hasMetRequirements = false
    end

    if sourceID and sourceID ~= NO_TRANSMOG_SOURCE_ID then
        isTransmog = true

        -- If canCollect, then the current toon can learn it.
        isInfoReady, canCollect = C_TransmogCollection.PlayerCanCollectSource(sourceID)

         -- TODO: Forcing to always for now be true because a class could have an item it knows
         -- that no other class can use, so we actually need the item rather than just completionist
        shouldSearchSources = true

        sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
        sourceSpecs = GetItemSpecInfo(itemLink)

        -- If the source is already collected, we don't need to check anything else for the source / appearance
        if sourceInfo and not sourceInfo.isCollected then
            -- Only returns for sources that can be transmogged by current toon right now
            -- appearanceInfo = C_TransmogCollection.GetAppearanceInfoBySource(sourceID)
            -- if appearanceInfo then -- Toon can learn
            -- --     needsItem = not appearanceInfo.sourceIsCollected
            -- --     isCompletionistItem = needsItem and appearanceInfo.appearanceIsCollected

            -- --     print(itemLink .. ", " .. tostring(needsItem) .. ", " .. tostring(isCompletionistItem))
            --     -- TODO: I think this logic might help with appearances but not sources?
            --     -- What are appearance non-level requirements?
            --     if appearanceInfo.appearanceHasAnyNonLevelRequirements and not appearanceInfo.appearanceMeetsNonLevelRequirements then
            --         -- TODO: Do I want to separate out level vs other requirements?
            --         hasMetRequirements = false
            --     end
            -- -- else
            -- --     shouldSearchSources = true
            -- end

            if shouldSearchSources then
                local sourceIndex, source
                local appearanceSourceIDs = C_TransmogCollection.GetAllAppearanceSources(appearanceID)
                for sourceIndex, source in pairs(appearanceSourceIDs) do
                    local info = C_TransmogCollection.GetSourceInfo(source)
                    if info then
                        if not appearanceSources then
                            appearanceSources = {}
                        end

                        table.insert(appearanceSources, info)
                    end
                end

                -- appearanceSources = C_TransmogCollection.GetAppearanceSources(appearanceID)
                currentSourceFound = false
                otherSourceFound = false

                if appearanceSources then
                    for sourceIndex, source in pairs(appearanceSources) do
                        local _, sourceType, sourceSubType, sourceEquipLoc, _, sourceTypeID, sourceSubTypeID = GetItemInfoInstant(source.itemID)
                        -- SubTypeID is returned from GetAppearanceSourceInfo, but it seems to be tied to the appearance, since it was wrong for an item that crossed over.
                        source.itemSubTypeID = sourceSubTypeID -- stuff it in here (mostly for debug)
                        source.specs = GetItemSpecInfo(source.itemID) -- also this

                        if source.sourceID == sourceID and source.isCollected then
                            currentSourceFound = true
                            break -- found the current source so don't need to learn or continue the search
                        elseif source.isCollected and (item:GetItemSubTypeID() == source.itemSubTypeID or source.itemSubTypeID == Enum.ItemArmorSubclass.Cosmetic) then 
                            -- Make sure it's the same armor type and doesn't have spec reqs
                            -- (otherwise assume we need it since we can't check for specs outside our own)
                            -- TODO: Keep an eye out for a way to get spec reqs for an item not for that class
                            local sourceMinLevel = (select(5, GetItemInfo(source.itemID)))
                            if lowestLevelFound == nil or sourceMinLevel and sourceMinLevel < lowestLevelFound then
                                lowestLevelFound = sourceMinLevel
                            end
                            local sourceSpecIndex, sourceSpec
                            if sourceSpecs and source.specs and #source.specs > 0 then
                                for sourceSpecIndex, sourceSpec in pairs(sourceSpecs) do
                                    if tContains(source.specs, sourceSpec) then
                                        otherSourceFound = true
                                        table.insert(matchedSources, source)
                                        break
                                    end
                                end
                            else
                                table.insert(matchedSources, source)
                                otherSourceFound = true
                            end
                        end
                    end

                    -- Ignore the other source if this item is lower level than what we know
                    -- TODO: Find an item to add to tests
                    local itemMinLevel = item:GetMinLevel()
                    if lowestLevelFound ~= nil and itemMinLevel ~= nil and itemMinLevel < lowestLevelFound then
                        otherSourceFound = false
                    end
                end

                if not currentSourceFound then
                    if canCollect then
                        needsItem = true
                    else
                        otherNeedsItem = true
                    end
                    
                    isCompletionistItem = otherSourceFound
                end
            end

            if canCollect then
                local playerSpecID = -1
                local playerSpec = GetSpecialization();
                if (playerSpec) then
                    playerSpecID = GetSpecializationInfo(playerSpec, nil, nil, nil, UnitSex("player"));
                end
                local playerLootSpecID = GetLootSpecialization()
                if playerLootSpecID == 0 then
                    playerLootSpecID = playerSpecID
                end
            
                if sourceSpecs then
                    for specIndex = 1, #sourceSpecs do
                        matchesLootSpec = false
    
                        local validSpecID = GetSpecializationInfo(specIndex, nil, nil, nil, UnitSex("player"));
                        if validSpecID == playerLootSpecID then
                            matchesLootSpec = true
                            break
                        end
                    end
                end
            end    
        end
    end

    return {
        isTransmog = isTransmog,
        isBindOnPickup = isBindOnPickup,
        appearanceID = appearanceID,
        sourceID = sourceID,
        canEquip = canCollect,
        needsItem = needsItem,
        hasMetRequirements = hasMetRequirements,
        otherNeedsItem = otherNeedsItem,
        isCompletionistItem = isCompletionistItem,
        matchesLootSpec = matchesLootSpec,
        forDebugUseOnly = CaerdonWardrobeConfig.Debug.Enabled and {
            matchedSources = matchedSources,
            isInfoReady = isInfoReady,
            shouldSearchSources = shouldSearchSources,
            appearanceInfo = appearanceInfo,
            sourceInfo = sourceInfo,
            appearanceSources = appearanceSources,
            itemTypeData = itemTypeData,
            currentSourceFound = currentSourceFound,
            otherSourceFound = otherSourceFound,
            sourceSpecs = sourceSpecs,
            lowestLevelFound = lowestLevelFound
        }
    }
end
