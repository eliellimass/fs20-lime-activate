ModHubItemsFrame = {}
local ShopItemsFrame_mt = Class(ModHubItemsFrame, TabbedMenuFrameElement)
ModHubItemsFrame.CONTROLS = {
	MOD_ATTRIBUTE_SIZE_SPACE = "modAttributeInfoSizeSpace",
	MOD_ATTRIBUTE_NAME = "modAttributeName",
	NO_MODS = "noModsElement",
	BUTTON_LEFT = "buttonLeft",
	MOD_ATTRIBUTE_BOX = "modAttributeBox",
	BUTTON_RIGHT = "buttonRight",
	MOD_ATTRIBUTE_PRICE = "modAttributePrice",
	MOD_ATTRIBUTE_RATING_BOX = "modAttributeRatingBox",
	MOD_ATTRIBUTE_AUTHOR = "modAttributeInfoAuthor",
	MOD_ATTRIBUTE_RATING_SPACE = "modAttributeInfoRatingSpace",
	MOD_ATTRIBUTE_PRICE_SPACE = "modAttributeInfoPriceSpace",
	MOD_INFO_BOX = "modInfoBox",
	CATEGORY_LABEL = "categoryLabel",
	MOD_ATTRIBUTE_VERSION = "modAttributeInfoVersion",
	ITEMS_LIST = "itemsList",
	NAVIGATION_HEADER = "breadcrumbs",
	ITEMS_LIST_TEMPLATE = "itemTemplate",
	DISCLAIMER = "disclaimerLabel",
	MOD_ATTRIBUTE_RATING_STAR = "modAttributeRatingStar",
	BASE_CATEGORY_LABEL = "baseCategoryLabel",
	MOD_ATTRIBUTE_FILESIZE = "modAttributeInfoSize"
}
ModHubItemsFrame.NUM_ATTRIBUTES_PER_ROW = ModHubController.MAX_ATTRIBUTES_PER_ROW
ModHubItemsFrame.ITEM_IMAGE_NAME = "itemIcon"
ModHubItemsFrame.ITEM_TITLE_LABEL_NAME = "itemNameLabel"
ModHubItemsFrame.ITEM_STATUS_BOX = "itemStatusBox"
ModHubItemsFrame.ITEM_STATUS_BAR = "itemStatusBar"
ModHubItemsFrame.ITEM_STATUS_TEXT = "itemStatusLabel"
ModHubItemsFrame.MARKER_ELEMENT_NAME = "itemMarker"
ModHubItemsFrame.MARKER_TEXT_ELEMENT_NAME = "itemMarkerText"

local function NO_CALLBACK()
end

function ModHubItemsFrame:new(subclass_mt, modHubController, l10n, isConsoleVersion)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or ShopItemsFrame_mt)

	self:registerControls(ModHubItemsFrame.CONTROLS)

	self.modHubController = modHubController
	self.l10n = l10n
	self.isConsoleVersion = isConsoleVersion
	self.categoryName = ""
	self.updateModIntervall = 1000
	self.updateModTimer = self.updateModIntervall
	self.notifyActivatedModItemCallback = NO_CALLBACK
	self.notifySelectedModItemCallback = NO_CALLBACK
	self.notifySearchCallback = NO_CALLBACK
	self.notifyToggleBetaCallback = NO_CALLBACK
	self.setModItems = nil
	self.modItems = {}
	self.elementToModItem = {}
	self.modIdToStatusElement = {}

	return self
end

function ModHubItemsFrame:copyAttributes(src)
	ModHubItemsFrame:superClass().copyAttributes(self, src)

	self.modHubController = src.modHubController
	self.l10n = src.l10n
	self.isConsoleVersion = src.isConsoleVersion
end

function ModHubItemsFrame:delete()
	self.itemTemplate:delete()
	ModHubItemsFrame:superClass().delete(self)
end

function ModHubItemsFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.detailsButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_DETAILS),
		callback = function ()
			self:onButtonDetails()
		end
	}
	self.searchButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_SEARCH),
		callback = function ()
			self:onButtonSearch()
		end
	}
	self.toggleTopButtonInfo = {
		text = "",
		inputAction = InputAction.MENU_EXTRA_1,
		callback = function ()
			self:onButtonShowToggle()
		end
	}

	if self.l10n:hasText("modHub_authorDisclaimer") then
		self.disclaimerLabel:setText(self.l10n:getText("modHub_abuse") .. " " .. self.l10n:getText("modHub_authorDisclaimer"))
	end

	self.itemTemplate:unlinkElement()
end

function ModHubItemsFrame:onFrameOpen()
	ModHubItemsFrame:superClass().onFrameOpen(self)
	self:setSoundSuppressed(true)
	self:updateList()
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
end

function ModHubItemsFrame:update(dt)
	ModHubItemsFrame:superClass().update(self, dt)

	self.updateModTimer = self.updateModTimer - dt

	if self.updateModTimer <= 0 then
		self:updateDownloadStates()
	end
end

function ModHubItemsFrame:getMenuButtonInfo()
	local buttons = {}

	if #self.modItems > 0 then
		table.insert(buttons, self.detailsButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	if self.notifySearchCallback ~= NO_CALLBACK then
		table.insert(buttons, self.searchButtonInfo)
	end

	if self.notifyToggleBetaCallback ~= NO_CALLBACK and self.forcedModItems == nil then
		self.toggleTopButtonInfo.text = self.getBetaToggleText()

		table.insert(buttons, self.toggleTopButtonInfo)
	end

	return buttons
end

function ModHubItemsFrame:setItemClickCallback(itemClickedCallback)
	self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end

function ModHubItemsFrame:setItemSelectCallback(itemSelectedCallback)
	self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ModHubItemsFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubItemsFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubItemsFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubItemsFrame:setCategory(categoryName)
	self.categoryName = categoryName
	self.selectedIndex = 1
	self.title = self.modHubController:getCategory(categoryName).label
end

function ModHubItemsFrame:setCategoryId(categoryId)
	self.categoryId = categoryId
end

function ModHubItemsFrame:setModItems(modItems)
	self.forcedModItems = modItems
end

function ModHubItemsFrame:setListSizeLimit(limit)
	self.listSizeLimit = limit
end

function ModHubItemsFrame:setBreadcrumbs(list)
	self.breadcrumbs:setBreadcrumbs(list)
end

function ModHubItemsFrame:reload()
	self:updateList()
end

function ModHubItemsFrame:updateList()
	self.modIdToStatusElement = {}
	self.elementToModItem = {}
	local oldSelectedIndex = self.selectedIndex

	if self.forcedModItems ~= nil then
		self.modItems = self.forcedModItems
	else
		self.modItems = self.modHubController:getModsByCategory(self.categoryId)
	end

	self.itemsList:deleteListItems()

	local num = 0

	for _, modInfo in ipairs(self.modItems) do
		if not modInfo:getIsDLC() or modInfo:getPriceString():len() > 1 or modInfo:getIsInstalled() then
			local listItem = self.itemTemplate:clone()
			self.elementToModItem[listItem] = modInfo:getId()

			self.itemsList:addElement(listItem)
			listItem:setVisible(true)

			local itemImage = listItem:getDescendantByName(ModHubItemsFrame.ITEM_IMAGE_NAME)
			local itemNameLabel = listItem:getDescendantByName(ModHubItemsFrame.ITEM_TITLE_LABEL_NAME)
			local itemStatusBox = listItem:getDescendantByName(ModHubItemsFrame.ITEM_STATUS_BOX)
			local itemStatusBar = listItem:getDescendantByName(ModHubItemsFrame.ITEM_STATUS_BAR)
			local itemStatusText = listItem:getDescendantByName(ModHubItemsFrame.ITEM_STATUS_TEXT)
			local markerElement = listItem:getDescendantByName(ModHubItemsFrame.MARKER_ELEMENT_NAME)
			local markerElementText = listItem:getDescendantByName(ModHubItemsFrame.MARKER_TEXT_ELEMENT_NAME)
			self.modIdToStatusElement[modInfo:getId()] = {
				itemStatusBox = itemStatusBox,
				itemStatusBar = itemStatusBar,
				maxWidth = itemStatusBar.size[1],
				itemStatusText = itemStatusText
			}
			local numUpdates = modInfo:getNumUpdates()
			local numNew = modInfo:getNumNew()
			local numConflicts = modInfo:getNumConflicts()

			markerElement:setVisible(numUpdates > 0 or numNew > 0 or numConflicts > 0)

			if numNew > 0 then
				markerElement:applyProfile(ModHubItemsFrame.PROFILE.MARKER_NEW)
			end

			if numUpdates > 0 then
				markerElement:applyProfile(ModHubItemsFrame.PROFILE.MARKER_UPDATE)
			end

			if numConflicts > 0 then
				markerElement:applyProfile(ModHubItemsFrame.PROFILE.MARKER_CONFLICT)
			end

			markerElementText:setText(numUpdates + numNew + numConflicts)
			itemImage:setIsWebOverlay(not modInfo:getIsIconLocal())
			itemNameLabel:setText(modInfo:getName())

			num = num + 1

			if self.listSizeLimit ~= nil and num == self.listSizeLimit then
				break
			end
		end
	end

	self.itemsList:updateItemPositions()

	if num > 0 then
		if oldSelectedIndex == nil or oldSelectedIndex == 0 or oldSelectedIndex > #self.modItems then
			self.itemsList:setSelectedIndex(1, true)

			self.selectedIndex = 1
		else
			self.itemsList:setSelectedIndex(oldSelectedIndex, true)
		end
	end

	self.modInfoBox:setVisible(num > 0)
	self.noModsElement:setVisible(num == 0)
	self:updateDownloadStates()
	self:updateScrollButtons()
	self:setMenuButtonInfoDirty()
end

function ModHubItemsFrame:getMainElementSize()
	return self.modInfoBox.size
end

function ModHubItemsFrame:getMainElementPosition()
	return self.modInfoBox.absPosition
end

function ModHubItemsFrame:updateDownloadStates()
	for i = self.itemsList.firstVisibleItem, math.min(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol * self.itemsList.itemsPerRow - 1, #self.itemsList.listItems) do
		local modId = self.elementToModItem[self.itemsList.listItems[i]]

		self:updateModDownloadState(modId)
	end

	self.updateModTimer = self.updateModIntervall
end

function ModHubItemsFrame:updateModDownloadState(modId)
	local statusElements = self.modIdToStatusElement[modId]

	if statusElements ~= nil then
		local modInfo = self.modHubController:getModInfo(modId)
		local isDownloading = modInfo:getIsDownloading()
		local isInstalled = modInfo:getIsInstalled()
		local isDownload = modInfo:getIsDownload()
		local isFailed = modInfo:getIsFailed()
		local isUpdate = modInfo:getIsUpdate()

		statusElements.itemStatusBox:setVisible(isDownloading or isInstalled or isDownload or isFailed or isUpdate)

		local percent = 0

		if isDownloading or isDownload then
			local downloaded = modInfo:getDownloadedBytes()
			local fileSize = modInfo:getFilesize()
			percent = MathUtil.clamp(downloaded / fileSize, 0, 1)
		elseif isInstalled then
			percent = 1
		end

		statusElements.itemStatusBar:setSize(statusElements.maxWidth * percent, nil)

		local text = ""

		if isDownloading or isDownload and percent == 1 then
			text = string.format("%.0f %%", percent * 100)
		elseif isDownload then
			text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_PENDING)
		elseif isUpdate then
			text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_UPDATE)
		elseif isInstalled then
			text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_INSTALLED)
		elseif isFailed then
			text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_FAILED)
		end

		statusElements.itemStatusText:setText(text)
	end
end

function ModHubItemsFrame:updateScrollButtons()
	if self.modItems ~= nil then
		local needButtons = #self.modItems > self.itemsList.itemsPerRow * self.itemsList.itemsPerCol

		self.buttonLeft:setVisible(needButtons and self.itemsList.firstVisibleItem ~= 1)

		local lastFirstVisibleIndex = math.max(#self.modItems - self.itemsList.itemsPerRow * self.itemsList.itemsPerCol + 1, 1)

		self.buttonRight:setVisible(needButtons and self.itemsList.firstVisibleItem <= lastFirstVisibleIndex)
	end
end

function ModHubItemsFrame:loadImageForElement(element)
	local itemImage = element:getDescendantByName(ModHubItemsFrame.ITEM_IMAGE_NAME)
	local modId = self.elementToModItem[element]

	if modId ~= nil then
		local modInfo = self.modHubController:getModInfo(modId)

		itemImage:setIsWebOverlay(not modInfo:getIsIconLocal())
		itemImage:setImageFilename(modInfo:getIconFilename())
		itemImage:setImageUVs(nil, unpack(GuiUtils.getUVs({
			0,
			0,
			1,
			1
		}, {
			1,
			1
		})))
	end
end

function ModHubItemsFrame:onClickItem(_, clickedElement)
	self:onDoubleClickItem(_, clickedElement)
end

function ModHubItemsFrame:onDoubleClickItem(_, clickedElement)
	local modId = self.elementToModItem[clickedElement]

	self:notifyActivatedModItemCallback(modId, self.categoryName)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

function ModHubItemsFrame:onButtonDetails()
	self:onDoubleClickItem(nil, self.itemsList.listItems[self.selectedIndex])
end

function ModHubItemsFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ModHubItemsFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

function ModHubItemsFrame:onItemSelected(itemIndex)
	self.selectedIndex = itemIndex

	for _, element in pairs(self.itemsList.listItems) do
		element:applyProfile(ModHubItemsFrame.PROFILE.LIST_ITEM_NEUTRAL)
	end

	local selectedElement = self.itemsList.listItems[itemIndex]

	if selectedElement ~= nil then
		selectedElement:applyProfile(ModHubItemsFrame.PROFILE.LIST_ITEM_SELECTED)
	end

	local modId = self.elementToModItem[selectedElement]

	if modId ~= nil then
		self:notifySelectedModItemCallback(modId, selectedElement)
	end

	self:updateDownloadStates()
	self:updateScrollButtons()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function ModHubItemsFrame:onScroll()
	self:updateDownloadStates()
	self:updateScrollButtons()
end

function ModHubItemsFrame:setModInfo(modInfo)
	self.modAttributeName:setText(modInfo:getName(), true)
	self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
	self.modAttributeInfoVersion:setText(modInfo:getVersionString(), true)

	local isDLC = modInfo:getIsDLC()
	local isTop = modInfo:getIsTop()
	local priceVisible = false

	if not isDLC then
		local size = modInfo:getFilesize() / 1024 / 1024

		self.modAttributeInfoSize:setText(string.format("%.02f MB", size), true)

		local ratingScore = modInfo:getRatingScore() / 100

		for i = 1, 5 do
			self.modAttributeRatingStar[i].elements[1]:setVisible(ratingScore >= i - 0.75 and ratingScore < i - 0.25)

			if ratingScore >= i - 0.25 then
				self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR_ACTIVE)
			else
				self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR)
			end
		end

		self.modAttributePrice:setText(self.l10n:getText("modHub_flag_highEnd"), true)

		priceVisible = isTop
	else
		local priceString = modInfo:getPriceString()

		self.modAttributePrice:setText(priceString, true)

		priceVisible = priceString:len() > 1
	end

	self.modAttributeInfoSize:setVisible(not isDLC)
	self.modAttributeInfoSizeSpace:setVisible(not isDLC)
	self.modAttributeRatingBox:setVisible(not isDLC)
	self.modAttributeInfoRatingSpace:setVisible(not isDLC)
	self.modAttributePrice:setVisible(priceVisible)
	self.modAttributeInfoPriceSpace:setVisible(priceVisible)
	self.modAttributeBox:invalidateLayout()
end

function ModHubItemsFrame:onListItemAppear(element)
	if not element.modImageLoaded then
		self:loadImageForElement(element)

		element.modImageLoaded = true
	end
end

function ModHubItemsFrame:onButtonSearch()
	self.notifySearchCallback(self.categoryId)
end

function ModHubItemsFrame:onButtonShowToggle()
	self:notifyToggleBetaCallback()
end

ModHubItemsFrame.PROFILE = {
	LIST_ITEM_NEUTRAL = "modHubItemsListItem",
	LIST_ITEM_SELECTED = "modHubItemsListItemSelected",
	MARKER_NEW = "modHubMarkerNew",
	MARKER_UPDATE = "modHubMarkerUpdate",
	RATING_STAR = "modHubAttributeRatingStar",
	RATING_STAR_ACTIVE = "modHubAttributeRatingStarActive",
	MARKER_CONFLICTED = "modHubMarkerConflict"
}
ModHubItemsFrame.L10N_SYMBOL = {
	STATUS_PENDING = "modHub_pending",
	BUTTON_DETAILS = "button_detail",
	STATUS_UPDATE = "modHub_update",
	BUTTON_SEARCH = "modHub_search",
	STATUS_INSTALLED = "modHub_installed",
	BUTTON_SHOW_ALL = "button_modHubShowAll",
	BUTTON_SHOW_TOP = "button_modHubShowTop",
	STATUS_FAILED = "modHub_failed"
}
