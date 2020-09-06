local MailMixin, Mail = {}

function MailMixin:OnLoad()
    hooksecurefunc("OpenMailFrame_UpdateButtonPositions", function(...) Mail:OnMailFrameUpdateButtonPositions(...) end)
    hooksecurefunc("SendMailFrame_Update", function(...) Mail:OnSendMailFrameUpdate(...) end)
    hooksecurefunc("InboxFrame_Update", function(...) Mail:OnInboxFrameUpdate(...) end)
end

function MailMixin:OnMailFrameUpdateButtonPositions(letterIsTakeable, textCreated, stationeryIcon, money)
	for i=1, ATTACHMENTS_MAX_RECEIVE do
		local attachmentButton = OpenMailFrame.OpenMailAttachments[i];
		if HasInboxItem(InboxFrame.openMailID, i) then
			-- local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(InboxFrame.openMailID, i);
			local itemLink = GetInboxItemLink(InboxFrame.openMailID, i)
			CaerdonWardrobe:UpdateButtonLink(itemLink, "OpenMailFrame", i, attachmentButton, nil)
		else
            CaerdonWardrobe:ClearButton(attachmentButton)
		end
	end
end

function MailMixin:OnSendMailFrameUpdate()
	for i=1, ATTACHMENTS_MAX_SEND do
		local attachmentButton = SendMailFrame.SendMailAttachments[i];

		if HasSendMailItem(i) then
			local itemLink = GetSendMailItemLink(i)
			CaerdonWardrobe:UpdateButtonLink(itemLink, "SendMailFrame", i, attachmentButton, nil)
		else
            CaerdonWardrobe:ClearButton(attachmentButton)
		end
	end
end

function MailMixin:OnInboxFrameUpdate()
	local numItems, totalItems = GetInboxNumItems();

	for i=1, INBOXITEMS_TO_DISPLAY do
		local index = ((InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY) + i;

		button = _G["MailItem"..i.."Button"];
		if ( index <= numItems ) then
			-- Setup mail item
			local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity, firstItemLink = GetInboxHeaderInfo(index);
			CaerdonWardrobe:UpdateButtonLink(firstItemLink, "InboxFrame", index, button, nil)
		else
            CaerdonWardrobe:ClearButton(button)
		end
	end
end

Mail = CreateFromMixins(MailMixin)
Mail:OnLoad()
