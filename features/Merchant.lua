local MerchantMixin = {}

function MerchantMixin:GetName()
    return "Merchant"
end

function MerchantMixin:Init()
    hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function(...) self:OnMerchantUpdate(...) end)
    hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function(...) self:OnBuybackUpdate(...) end)

    return { "MERCHANT_UPDATE" }
end

function MerchantMixin:MERCHANT_UPDATE()
	self:Refresh()
end

function MerchantMixin:SetTooltipItem(tooltip, item, locationInfo)
    if MerchantFrame.selectedTab == 1 then
        if locationInfo.slot == "buybackbutton" then
            tooltip:SetBuybackItem(GetNumBuybackItems())
        else
            tooltip:SetMerchantItem(locationInfo.slot)
        end
    else
        tooltip:SetBuybackItem(locationInfo.slot)
    end
end

function MerchantMixin:Refresh()
    if MerchantFrame:IsShown() then 
        if MerchantFrame.selectedTab == 1 then
            self:OnMerchantUpdate()
        else
            self:OnBuybackUpdate()
        end
    end
end

function MerchantMixin:GetDisplayInfo()
	return {
		bindingStatus = {
			shouldShow = CaerdonWardrobeConfig.Binding.ShowStatus.Merchant
        },
        ownIcon = {
            shouldShow = CaerdonWardrobeConfig.Icon.ShowLearnable.Merchant
        },
        otherIcon = {
            shouldShow = CaerdonWardrobeConfig.Icon.ShowLearnableByOther.Merchant
        },
        oldExpansionIcon = {
            shouldShow = false
        },
        sellableIcon = {
            shouldShow = false
        }
	}
end

function MerchantMixin:OnMerchantUpdate()
    local bag = self:GetName()
    local options = { 
        showMogIcon=true, showBindStatus=true, showSellables=false, 
        otherIcon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        otherIconSize = 20, otherIconOffset = 10,	
    }

	for i=1, MERCHANT_ITEMS_PER_PAGE, 1 do
		local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)

		local button = _G["MerchantItem"..i.."ItemButton"];

		local slot = index

		local itemLink = GetMerchantItemLink(index)
		CaerdonWardrobe:UpdateButtonLink(itemLink, bag, { slot = slot }, button, options)
    end
    
    local numBuybackItems = GetNumBuybackItems()
    local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable = GetBuybackItemInfo(numBuybackItems)
    if buybackName then
        local itemLink = GetBuybackItemLink(numBuybackItems)
        local slot = "buybackbutton"
		CaerdonWardrobe:UpdateButtonLink(itemLink, bag, { slot = slot }, MerchantBuyBackItemItemButton, options)
    else
        CaerdonWardrobe:ClearButton(MerchantBuyBackItemItemButton)
    end
end

function MerchantMixin:OnBuybackUpdate()
	local numBuybackItems = GetNumBuybackItems();

	for index=1, BUYBACK_ITEMS_PER_PAGE, 1 do -- Only 1 actual page for buyback right now
		if index <= numBuybackItems then
			local button = _G["MerchantItem"..index.."ItemButton"];

			local slot = index

            local itemLink = GetBuybackItemLink(index)
            if itemLink then
                CaerdonWardrobe:UpdateButtonLink(itemLink, self:GetName(), { slot = slot }, button, { showMogIcon=true, showBindStatus=true, showSellables=false})
            else
                CaerdonWardrobe:ClearButton(button)
            end
		end
	end
end

CaerdonWardrobe:RegisterFeature(MerchantMixin)
