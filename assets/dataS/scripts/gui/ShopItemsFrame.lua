ShopItemsFrame = {}
local ShopItemsFrame_mt = Class(ShopItemsFrame, TabbedMenuFrameElement)
ShopItemsFrame.CONTROLS = {
	ATTRIBUTE_BOXES = "attrBox",
	ITEM_BASE_INFO_TITLE = "itemInfoTitle",
	ITEMS_LIST = "itemsList",
	ITEMS_HEADER_TEXT = "itemsHeaderText",
	ATTRIBUTE_VALUES = "attrValue",
	ITEM_BASE_INFO_DESCRIPTION = "itemInfoDescription",
	SHOP_SLOTS_ICON = "shopSlotsIcon",
	FILL_TYPE_ICON_TEMPLATE = "fruitIconTemplate",
	PRICE_BOX = "priceBox",
	ATTRIBUTE_ROW_LAYOUTS = "attrRow",
	CURRENT_BALANCE_LABEL = "currentBalanceLabel",
	ITEM_FUNCTION_ICON = "shopListAttributeInfoIcon",
	CATEGORY_LABEL = "categoryLabel",
	BUTTON_LEFT = "buttonLeft",
	ITEMS_HEADER_ICON = "itemsHeaderIcon",
	NAVIGATION_HEADER = "navHeader",
	ITEM_BASE_INFO_LAYOUT = "baseInfoLayout",
	CURRENT_BALANCE_TEXT = "currentBalanceText",
	BUTTON_RIGHT = "buttonRight",
	DETAIL_BOX = "detailBox",
	ITEMS_LIST_TEMPLATE = "itemTemplate",
	ATTR_VEHICLE_VALUE = "attrVehicleValue",
	ATTRIBUTE_ICONS = "attrIcon",
	ITEM_FUNCTION_TEXT = "shopListAttributeInfo",
	BASE_CATEGORY_LABEL = "baseCategoryLabel",
	SHOP_SLOTS_TEXT = "shopSlotsText"
}
ShopItemsFrame.NUM_ATTRIBUTES_PER_ROW = ShopController.MAX_ATTRIBUTES_PER_ROW
ShopItemsFrame.SLOTS_USAGE_CRITICAL_THRESHOLD = 0.9
ShopItemsFrame.ITEM_IMAGE_NAME = "itemIcon"
ShopItemsFrame.ITEM_BRAND_IMAGE_NAME = "itemBrandIcon"
ShopItemsFrame.ITEM_TITLE_LABEL_NAME = "itemNameLabel"
ShopItemsFrame.ITEM_PRICE_LABEL_NAME = "itemValueLabel"
ShopItemsFrame.ITEM_MODDLC_LABEL_NAME = "itemModDlcLabel"

local function NO_CALLBACK()
end

function ShopItemsFrame:new(subclass_mt, shopController, l10n, brandManager, isConsoleVersion)
	local subclass_mt = subclass_mt or ShopItemsFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(ShopItemsFrame.CONTROLS)

	self.shopController = shopController
	self.l10n = l10n
	self.brandManager = brandManager
	self.isConsoleVersion = isConsoleVersion
	self.notifyActivatedDisplayItemCallback = NO_CALLBACK
	self.notifySelectedDisplayItemCallback = NO_CALLBACK
	self.selectedIndex = 1
	self.displayItems = {}
	self.itemElementToDisplayItem = {}
	self.clonedElements = {}

	return self
end

function ShopItemsFrame:copyAttributes(src)
	ShopItemsFrame:superClass().copyAttributes(self, src)

	self.shopController = src.shopController
	self.l10n = src.l10n
	self.brandManager = src.brandManager
	self.isConsoleVersion = src.isConsoleVersion
end

function ShopItemsFrame:delete()
	self.itemTemplate:delete()
	ShopItemsFrame:superClass().delete(self)
end

function ShopItemsFrame:initialize()
	self.itemTemplate:unlinkElement()

	if not GS_IS_MOBILE_VERSION then
		self.shopSlotsIcon:setVisible(GS_IS_CONSOLE_VERSION)
		self.shopSlotsText:setVisible(GS_IS_CONSOLE_VERSION)
	end
end

function ShopItemsFrame:onFrameOpen()
	ShopItemsFrame:superClass().onFrameOpen(self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self.itemsList:setSelectedIndex(self.selectedIndex, true)
	self:setSoundSuppressed(false)

	if self.navHeader ~= nil then
		self.navHeader:invalidateLayout()
	end
end

function ShopItemsFrame:setItemClickCallback(itemClickedCallback)
	self.notifyActivatedDisplayItemCallback = itemClickedCallback or NO_CALLBACK
end

function ShopItemsFrame:setItemSelectCallback(itemSelectedCallback)
	self.notifySelectedDisplayItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ShopItemsFrame:setHeader(headerIconUVs, headerText)
	if not GS_IS_MOBILE_VERSION then
		self.itemsHeaderIcon:setImageUVs(nil, unpack(headerIconUVs))
		self.itemsHeaderText:setText(headerText)
		self.itemsHeaderText:updateAbsolutePosition()
	end
end

function ShopItemsFrame:setCategory(categoryIconUVs, rootName, categoryName, isSpecial)
	if self.categoryLabel.text ~= categoryName then
		self.selectedIndex = 1
		self.currentPage = 1

		self.baseCategoryLabel:setText(rootName)
		self.categoryLabel:setText(categoryName)
		self:setHeader(categoryIconUVs, categoryName)

		if self.navHeader ~= nil then
			self.navHeader:invalidateLayout()
		end
	end

	self:setTitle(categoryName)
end

function ShopItemsFrame:setShowBalance(doShowBalance)
	self.currentBalanceLabel:setVisible(doShowBalance)
	self.currentBalanceText:setVisible(doShowBalance)
end

function ShopItemsFrame:setShowNavigation(doShowNavigation)
	if self.navHeader ~= nil then
		self.navHeader:setVisible(doShowNavigation)
	end
end

function ShopItemsFrame:setCurrentBalance(balance, balanceString)
	local balanceProfile = ShopItemsFrame.PROFILE.BALANCE_POSITIVE

	if math.floor(balance) <= -1 then
		balanceProfile = ShopItemsFrame.PROFILE.BALANCE_NEGATIVE
	end

	if self.currentBalanceText.profile ~= balanceProfile then
		self.currentBalanceText:applyProfile(balanceProfile)
	end

	self.currentBalanceText:setText(balanceString)
end

function ShopItemsFrame:setSlotsUsage(slotsUsage, maxSlots)
	if GS_IS_CONSOLE_VERSION then
		local text = string.format("%0d / %0d", slotsUsage, maxSlots)
		local profile = ShopItemsFrame.PROFILE.BALANCE_POSITIVE

		if ShopItemsFrame.SLOTS_USAGE_CRITICAL_THRESHOLD <= slotsUsage / maxSlots then
			profile = ShopItemsFrame.PROFILE.BALANCE_NEGATIVE
		end

		self.shopSlotsText:applyProfile(profile)
		self.shopSlotsText:setText(text)
	end
end

function ShopItemsFrame:setDisplayItems(displayItems, areItemsOwned)
	self:setSoundSuppressed(true)

	self.displayItems = displayItems or {}
	self.areItemsOwned = areItemsOwned

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(math.ceil(#displayItems / (self.itemsList.itemsPerRow * self.itemsList.itemsPerCol)))
	end

	for k in pairs(self.itemElementToDisplayItem) do
		self.itemElementToDisplayItem[k] = nil
	end

	local currentIndex = self.selectedIndex

	self.itemsList:deleteListItems()

	for _, displayItem in ipairs(displayItems) do
		local listItem = self.itemTemplate:clone(self.itemsList)

		listItem:setVisible(true)

		self.itemElementToDisplayItem[listItem] = displayItem
		local itemImage = listItem:getDescendantByName(ShopItemsFrame.ITEM_IMAGE_NAME)
		local itemBrandImage = listItem:getDescendantByName(ShopItemsFrame.ITEM_BRAND_IMAGE_NAME)
		local itemNameLabel = listItem:getDescendantByName(ShopItemsFrame.ITEM_TITLE_LABEL_NAME)
		local itemPriceLabel = listItem:getDescendantByName(ShopItemsFrame.ITEM_PRICE_LABEL_NAME)
		local modDlcLabel = listItem:getDescendantByName(ShopItemsFrame.ITEM_MODDLC_LABEL_NAME)
		local storeItem = displayItem.storeItem

		if storeItem.isInAppPurchase then
			itemImage:setImageFilename(storeItem.imageFilename)

			if storeItem.canBeRecovered then
				itemNameLabel:setText(self.l10n:getText("ui_iap_recoverable"))
			else
				itemNameLabel:setText(storeItem.priceText)
			end

			itemPriceLabel:setText(storeItem.title)
			itemPriceLabel:setVisible(true)
			itemBrandImage:setVisible(false)
		else
			itemImage:setImageFilename(storeItem.imageFilename)

			local itemBrand = self.brandManager:getBrandByIndex(storeItem.brandIndex)

			itemBrandImage:setImageFilename(itemBrand.image)
			itemBrandImage:setVisible(true)

			local itemName = storeItem.name

			if displayItem.concreteItem.getName ~= nil then
				itemName = displayItem.concreteItem:getName()
			end

			itemNameLabel:setText(itemName)

			local concreteItem = nil

			if areItemsOwned and displayItem.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
				concreteItem = displayItem.concreteItem
			end

			if GS_IS_MOBILE_VERSION then
				itemPriceLabel:setVisible(false)
			else
				itemPriceLabel:setText(self:getStoreItemDisplayPrice(storeItem, concreteItem, areItemsOwned))
			end

			if storeItem.isMod then
				modDlcLabel:setText("Mod")
			elseif storeItem.dlcTitle ~= nil then
				modDlcLabel:setText(storeItem.dlcTitle)
			else
				modDlcLabel:setText("")
			end
		end
	end

	self.itemsList:updateItemPositions()

	if #displayItems > 0 then
		self.selectedIndex = MathUtil.clamp(currentIndex, 1, #displayItems)

		self.itemsList:setSelectedIndex(self.selectedIndex, self:getIsVisible())
	end

	self:updateScrollButtons()
	self:onPageChanged(self.currentPage, self.currentPage)
	self.detailBox:setVisible(#displayItems > 0)
end

function ShopItemsFrame:updateScrollButtons()
	if not GS_IS_MOBILE_VERSION then
		local needButtons = #self.displayItems > self.itemsList.itemsPerRow * self.itemsList.itemsPerCol

		self.buttonLeft:setVisible(needButtons and self.itemsList.firstVisibleItem ~= 1)

		local lastFirstVisibleIndex = math.max(#self.displayItems - self.itemsList.itemsPerRow + 1, 1)

		self.buttonRight:setVisible(needButtons and self.itemsList.firstVisibleItem ~= lastFirstVisibleIndex)
	end
end

function ShopItemsFrame:getStoreItemDisplayPrice(storeItem, item, isSellingOrReturning)
	local priceStr = "-"
	local isHandTool = StoreItemUtil.getIsHandTool(storeItem)

	if isSellingOrReturning then
		if item ~= nil and item.propertyState ~= Vehicle.PROPERTY_STATE_LEASED or isHandTool then
			local price, _ = g_currentMission.economyManager:getSellPrice(item or storeItem)
			priceStr = g_i18n:formatMoney(price, 0, true, true)
		end
	elseif storeItem.isInAppPurchase then
		priceStr = storeItem.price
	else
		local price, _, _ = g_currentMission.economyManager:getBuyPrice(storeItem)
		priceStr = g_i18n:formatMoney(price, 0, true, true)
	end

	return priceStr
end

function ShopItemsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames, attributeIndex)
	local baseIconTemplate = self.fruitIconTemplate
	local baseIconWidth = baseIconTemplate.size[1] + baseIconTemplate.margin[1] + baseIconTemplate.margin[3]

	if attributeIndex <= ShopItemsFrame.NUM_ATTRIBUTES_PER_ROW then
		attributeIndex = ShopItemsFrame.NUM_ATTRIBUTES_PER_ROW + 1
	end

	if attributeIndex > #self.attrBox or #iconFilenames == 0 then
		return attributeIndex
	end

	local parentBox = self.attrBox[attributeIndex]
	local widthLimit = self.detailBox.absPosition[1] + self.detailBox.size[1]
	local posX = 0

	if #iconFilenames > 0 then
		local baseIcon = self.fruitIconTemplate:clone(parentBox)

		table.insert(self.clonedElements, baseIcon)
		baseIcon:applyProfile(baseIconProfile)
		baseIcon:setVisible(true)

		posX = posX + baseIconWidth

		for i = 1, #iconFilenames do
			local icon = self.fruitIconTemplate:clone(parentBox)

			icon:setVisible(true)
			icon:setPosition(posX, nil)
			table.insert(self.clonedElements, icon)

			if widthLimit <= parentBox.absPosition[1] + posX + baseIconWidth * 2 then
				icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FILL_TYPES_PLUS)
				icon:setImageFilename(g_baseUIFilename)

				break
			else
				icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
				icon:setImageFilename(iconFilenames[i])
			end

			posX = posX + baseIconWidth
		end
	end

	local box = self.attrBox[1]
	local attrBoxWidth = box.size[1] + box.margin[1] + box.margin[3]

	return attributeIndex + math.ceil((posX + baseIconWidth) / attrBoxWidth)
end

function ShopItemsFrame:assignItemTextData(displayItem)
	if self.attrVehicleValue ~= nil then
		local storeItem = displayItem.storeItem
		local concreteItem = nil

		if self.areItemsOwned and displayItem.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
			concreteItem = displayItem.concreteItem
		end

		self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(storeItem, concreteItem, self.areItemsOwned))
		self.priceBox:setVisible(not storeItem.isInAppPurchase)
	end

	local numAttributesUsed = 0

	for i = 1, #self.attrValue do
		local attributeVisible = false

		if i <= #displayItem.attributeValues then
			local value = displayItem.attributeValues[i]
			local profile = displayItem.attributeIconProfiles[i]

			self.attrValue[i]:setText(value)
			self.attrValue[i]:updateAbsolutePosition()

			if profile ~= nil and profile ~= "" then
				self.attrIcon[i]:applyProfile(profile)
			end

			attributeVisible = value ~= nil and value ~= ""
		end

		self.attrValue[i]:setVisible(attributeVisible)
		self.attrIcon[i]:setVisible(attributeVisible)

		if attributeVisible then
			numAttributesUsed = numAttributesUsed + 1
		end
	end

	return numAttributesUsed
end

function ShopItemsFrame:assignItemAttributeData(displayItem)
	for k, clone in pairs(self.clonedElements) do
		clone:delete()

		self.clonedElements[k] = nil
	end

	local numAttributesUsed = self:assignItemTextData(displayItem)
	local nextAttributeIndex = self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeFilenames, numAttributesUsed + 1)
	nextAttributeIndex = self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames, nextAttributeIndex)

	self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeFilenames, nextAttributeIndex)

	local visible = not GS_IS_MOBILE_VERSION or displayItem.storeItem.isInAppPurchase

	self.shopListAttributeInfo:setText(displayItem.functionText)
	self.shopListAttributeInfo:setVisible(visible)
	self.shopListAttributeInfoIcon:setVisible(displayItem.functionText ~= "" and visible)

	for _, rowLayout in pairs(self.attrRow) do
		rowLayout:invalidateLayout()
	end
end

function ShopItemsFrame:getMainElementSize()
	return self.detailBox.size
end

function ShopItemsFrame:getMainElementPosition()
	return self.detailBox.absPosition
end

function ShopItemsFrame:onClickItem(_, clickedElement)
	self:onDoubleClickItem(_, clickedElement)
end

function ShopItemsFrame:onDoubleClickItem(_, clickedElement)
	local displayItem = self.itemElementToDisplayItem[clickedElement]

	if displayItem ~= nil then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		self.notifyActivatedDisplayItemCallback(displayItem)
	end
end

function ShopItemsFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ShopItemsFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

function ShopItemsFrame:onScroll()
	self:updateScrollButtons()
end

function ShopItemsFrame:onItemSelected(itemIndex)
	self.selectedIndex = itemIndex

	for _, element in pairs(self.itemsList.listItems) do
		element:applyProfile(ShopItemsFrame.PROFILE.LIST_ITEM_NEUTRAL)
	end

	local selectedElement = self.itemsList.listItems[itemIndex]

	if selectedElement ~= nil then
		selectedElement:applyProfile(ShopItemsFrame.PROFILE.LIST_ITEM_SELECTED)
	end

	local displayItem = self.itemElementToDisplayItem[selectedElement]

	if displayItem ~= nil and self:getIsVisible() then
		self:assignItemAttributeData(displayItem)
		self.notifySelectedDisplayItemCallback(displayItem, selectedElement)
	end

	if self:getIsVisible() then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end

	self:updateScrollButtons()
end

function ShopItemsFrame:onPageChanged(page, fromPage)
	ShopItemsFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * self.itemsList.itemsPerRow * self.itemsList.itemsPerCol + 1

	self.itemsList:scrollTo(firstIndex)
end

ShopItemsFrame.PROFILE = {
	ICON_FRUIT_TYPE = "shopListAttributeFruitIcon",
	ICON_FILL_TYPES = "shopListAttributeIconFillTypes",
	ICON_SEED_FILL_TYPES = "shopListAttributeIconSeeds",
	LIST_ITEM_NEUTRAL = "shopItemsListItem",
	LIST_ITEM_SELECTED = "shopItemsListItemSelected",
	ICON_FILL_TYPES_PLUS = "shopListAttributeIconPlus",
	BALANCE_POSITIVE = "shopMoney",
	BALANCE_NEGATIVE = "shopMoneyNeg"
}
