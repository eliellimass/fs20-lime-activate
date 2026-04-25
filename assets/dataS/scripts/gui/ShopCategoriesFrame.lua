ShopCategoriesFrame = {}
local ShopCategoriesFrame_mt = Class(ShopCategoriesFrame, TabbedMenuFrameElement)
ShopCategoriesFrame.CONTROLS = {
	CATEGORY_TEMPLATE = "categoryTemplate",
	CATEGORY_LIST = "categoryList",
	BUTTON_LEFT = "buttonLeft",
	BUTTON_RIGHT = "buttonRight",
	CATEGORY_HEADER_ICON = "categoryHeaderIcon",
	CATEGORY_HEADER_TEXT = "categoryHeaderText"
}
ShopCategoriesFrame.ICON_ELEMENT_NAME = "categoryImage"
ShopCategoriesFrame.LABEL_ELEMENT_NAME = "categoryText"

local function NO_CALLBACK()
end

function ShopCategoriesFrame:new(subclass_mt, shopController, isConsoleVersion)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or ShopCategoriesFrame_mt)

	self:registerControls(ShopCategoriesFrame.CONTROLS)

	self.shopController = shopController
	self.isConsoleVersion = isConsoleVersion
	self.notifyActivatedCategoryCallback = NO_CALLBACK
	self.categoryElementToCategory = {}
	self.headerLabelText = ""
	self.headerIconUVs = {}

	return self
end

function ShopCategoriesFrame:copyAttributes(src)
	ShopCategoriesFrame:superClass().copyAttributes(self, src)

	self.shopController = src.shopController
	self.isConsoleVersion = src.isConsoleVersion
end

function ShopCategoriesFrame:reset()
	self.categoryList:deleteListItems()

	for k in pairs(self.categoryElementToCategory) do
		self.categoryElementToCategory[k] = nil
	end
end

function ShopCategoriesFrame:initialize(categories, categoryClickedCallback, headerIconUVs, headerText, iconHeightWidthRatio)
	self.categoryTemplate:unlinkElement()

	self.headerLabelText = headerText
	self.headerIconUVs = headerIconUVs
	self.categories = categories

	for i, cat in ipairs(categories) do
		local categoryElement = self.categoryTemplate:clone(self.categoryList)
		local iconElement = categoryElement:getDescendantByName(ShopCategoriesFrame.ICON_ELEMENT_NAME)
		local labelElement = categoryElement:getDescendantByName(ShopCategoriesFrame.LABEL_ELEMENT_NAME)

		iconElement:setImageFilename(cat.iconFilename)
		iconElement:setSize(nil, iconElement.size[2] * (iconHeightWidthRatio or 1))
		labelElement:setText(cat.label)

		self.categoryElementToCategory[categoryElement] = cat
	end

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(math.ceil(#self.categories / (self.categoryList.itemsPerRow * self.categoryList.itemsPerCol)))
	end

	self.categoryList:updateItemPositions()

	if #self.categoryList.listItems > 0 then
		self.categoryList:setSelectedIndex(1, true)
	end

	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK

	if self.categoryHeaderText ~= nil then
		self.categoryHeaderIcon:setImageUVs(nil, unpack(headerIconUVs))
		self.categoryHeaderText:setText(headerText)
		self.categoryHeaderText:updateAbsolutePosition()
	end

	self:setTitle(headerText)
	self:updateScrollButtons()
end

function ShopCategoriesFrame:onFrameOpen()
	ShopCategoriesFrame:superClass().onFrameOpen(self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.categoryList)
	self:setSoundSuppressed(false)
end

function ShopCategoriesFrame:onFrameClose()
	ShopCategoriesFrame:superClass().onFrameClose(self)
	self:setSoundSuppressed(true)
end

function ShopCategoriesFrame:getMainElementSize()
	return self.categoryList.size
end

function ShopCategoriesFrame:getMainElementPosition()
	return self.categoryList.absPosition
end

function ShopCategoriesFrame:updateScrollButtons()
	if self.categories ~= nil and not GS_IS_MOBILE_VERSION then
		local needButtons = #self.categories > self.categoryList.itemsPerRow * self.categoryList.itemsPerCol

		self.buttonLeft:setVisible(needButtons and self.categoryList.firstVisibleItem ~= 1)

		local lastFirstVisibleIndex = math.max(#self.categories - self.categoryList.itemsPerRow * self.categoryList.itemsPerCol + 1, 1)

		self.buttonRight:setVisible(needButtons and self.categoryList.firstVisibleItem <= lastFirstVisibleIndex)
	end
end

function ShopCategoriesFrame:onClickCategory(_, clickedElement)
	self:onDoubleClickCategory(_, clickedElement)
end

function ShopCategoriesFrame:onDoubleClickCategory(_, clickedElement)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

	local category = self.categoryElementToCategory[clickedElement]

	if category ~= nil then
		self.notifyActivatedCategoryCallback(category.id, self.headerIconUVs, self.headerLabelText, category.label)
	end
end

function ShopCategoriesFrame:onCategorySelected(itemIndex)
	for _, element in pairs(self.categoryList.listItems) do
		local category = self.categoryElementToCategory[element]

		if category.id == "COINS" then
			element:applyProfile(ShopCategoriesFrame.PROFILE.LIST_ITEM_COINS)
		else
			element:applyProfile(ShopCategoriesFrame.PROFILE.LIST_ITEM_NEUTRAL)
		end
	end

	local selectedElement = self.categoryList.listItems[itemIndex]

	if selectedElement ~= nil then
		local category = self.categoryElementToCategory[selectedElement]

		if category.id == "COINS" then
			selectedElement:applyProfile(ShopCategoriesFrame.PROFILE.LIST_ITEM_COINS_SELECTED)
		else
			selectedElement:applyProfile(ShopCategoriesFrame.PROFILE.LIST_ITEM_SELECTED)
		end
	end

	if self:getIsVisible() then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end

	self:updateScrollButtons()
end

function ShopCategoriesFrame:onClickLeft()
	self.categoryList:scrollTo(self.categoryList.firstVisibleItem - self.categoryList.itemsPerCol)
end

function ShopCategoriesFrame:onClickRight()
	self.categoryList:scrollTo(self.categoryList.firstVisibleItem + self.categoryList.itemsPerCol)
end

function ShopCategoriesFrame:onScroll()
	self:updateScrollButtons()
end

function ShopCategoriesFrame:onPageChanged(page, fromPage)
	ShopCategoriesFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * self.categoryList.itemsPerRow * self.categoryList.itemsPerCol + 1

	self.categoryList:scrollTo(firstIndex)
end

ShopCategoriesFrame.PROFILE = {
	LIST_ITEM_SELECTED = "shopCategoryItemSelected",
	LIST_ITEM_NEUTRAL = "shopCategoryItem",
	LIST_ITEM_COINS_SELECTED = "shopCategoryItemCoinsSelected",
	LIST_ITEM_COINS = "shopCategoryItemCoins"
}
