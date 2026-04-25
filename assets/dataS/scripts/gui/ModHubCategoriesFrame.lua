ModHubCategoriesFrame = {}
local ModHubCategoriesFrame_mt = Class(ModHubCategoriesFrame, TabbedMenuFrameElement)
ModHubCategoriesFrame.CONTROLS = {
	NAV_HEADER = "breadcrumbs",
	BUTTON_LEFT = "buttonLeft",
	BUTTON_RIGHT = "buttonRight",
	CATEGORY_LIST = "categoryList",
	CATEGORY_TEMPLATE = "categoryTemplate"
}
ModHubCategoriesFrame.ICON_ELEMENT_NAME = "categoryImage"
ModHubCategoriesFrame.LABEL_ELEMENT_NAME = "categoryText"
ModHubCategoriesFrame.MARKER_BOX_ELEMENT = "categoryMarkerBox"
ModHubCategoriesFrame.MARKER_NEW_ELEMENT_NAME = "categoryMarkerNew"
ModHubCategoriesFrame.MARKER_NEW_TEXT_ELEMENT_NAME = "categoryMarkerNewText"
ModHubCategoriesFrame.MARKER_CONFLICT_ELEMENT_NAME = "categoryMarkerConflict"
ModHubCategoriesFrame.MARKER_CONFLICT_TEXT_ELEMENT_NAME = "categoryMarkerConflictText"
ModHubCategoriesFrame.MARKER_UPDATE_ELEMENT_NAME = "categoryMarkerUpdate"
ModHubCategoriesFrame.MARKER_UPDATE_TEXT_ELEMENT_NAME = "categoryMarkerUpdateText"

local function NO_CALLBACK()
end

function ModHubCategoriesFrame:new(subclass_mt, modHubController, isConsoleVersion)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or ModHubCategoriesFrame_mt)

	self:registerControls(ModHubCategoriesFrame.CONTROLS)

	self.modHubController = modHubController
	self.isConsoleVersion = isConsoleVersion
	self.notifyActivatedCategoryCallback = NO_CALLBACK
	self.notifySearchCallback = NO_CALLBACK
	self.notifyToggleBetaCallback = NO_CALLBACK
	self.categoryElementToCategory = {}

	return self
end

function ModHubCategoriesFrame:copyAttributes(src)
	ModHubCategoriesFrame:superClass().copyAttributes(self, src)

	self.modHubController = src.modHubController
	self.isConsoleVersion = src.isConsoleVersion
end

function ModHubCategoriesFrame:reset()
	self.categoryList:deleteListItems()

	for k in pairs(self.categoryElementToCategory) do
		self.categoryElementToCategory[k] = nil
	end
end

function ModHubCategoriesFrame:initialize(categories, categoryClickedCallback, headerText, iconHeightWidthRatio)
	self.categoryTemplate:unlinkElement()

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.detailsButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_DETAILS),
		callback = function ()
			self:onButtonDetails()
		end
	}
	self.searchButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(ModHubCategoriesFrame.L10N_SYMBOL.BUTTON_SEARCH),
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
	self.title = headerText
	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK

	self:setCategories(categories)
end

function ModHubCategoriesFrame:setCategories(categories)
	self.categoryElementToCategory = {}

	self.categoryList:deleteListItems()

	self.numVisibleCategories = 0
	self.categories = categories

	for i, cat in ipairs(categories) do
		if not cat.isHidden and cat:getNumMods() > 0 then
			local categoryElement = self.categoryTemplate:clone(self.categoryList)
			local iconElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.ICON_ELEMENT_NAME)
			local labelElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.LABEL_ELEMENT_NAME)
			local markerBoxElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_BOX_ELEMENT)
			local markerNewElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_NEW_ELEMENT_NAME)
			local markerNewTextElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_NEW_TEXT_ELEMENT_NAME)
			local markerUpdateElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_UPDATE_ELEMENT_NAME)
			local markerUpdateTextElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_UPDATE_TEXT_ELEMENT_NAME)
			local markerConflictElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_CONFLICT_ELEMENT_NAME)
			local markerConflictTextElement = categoryElement:getDescendantByName(ModHubCategoriesFrame.MARKER_CONFLICT_TEXT_ELEMENT_NAME)

			markerNewElement:setVisible(cat.numNewItems > 0)
			markerUpdateElement:setVisible(cat.numAvailableUpdates > 0)
			markerConflictElement:setVisible(cat.numConflictedItems > 0)
			markerNewTextElement:setText(cat.numNewItems)
			markerUpdateTextElement:setText(cat.numAvailableUpdates)
			markerConflictTextElement:setText(cat.numConflictedItems)
			markerBoxElement:invalidateLayout()
			iconElement:setImageFilename(cat.iconFilename)
			iconElement:setSize(nil, iconElement.size[2] * (iconHeightWidthRatio or 1))
			labelElement:setText(cat.label)

			self.categoryElementToCategory[categoryElement] = cat
			self.numVisibleCategories = self.numVisibleCategories + 1
		end
	end

	self.categoryList:updateItemPositions()

	if #self.categoryList.listItems > 0 then
		self.categoryList:setSelectedIndex(1, true)
	end

	self:updateScrollButtons()
	self:setMenuButtonInfoDirty()
end

function ModHubCategoriesFrame:onFrameOpen()
	ModHubCategoriesFrame:superClass().onFrameOpen(self)
	self:setMenuButtonInfoDirty()
end

function ModHubCategoriesFrame:reload()
end

function ModHubCategoriesFrame:getMainElementSize()
	return self.categoryList.size
end

function ModHubCategoriesFrame:getMainElementPosition()
	return self.categoryList.absPosition
end

function ModHubCategoriesFrame:updateScrollButtons()
	if self.categories ~= nil then
		local needButtons = self.numVisibleCategories > self.categoryList.itemsPerRow * self.categoryList.itemsPerCol

		self.buttonLeft:setVisible(needButtons and self.categoryList.firstVisibleItem ~= 1)

		local lastFirstVisibleIndex = math.max(self.numVisibleCategories - self.categoryList.itemsPerRow * self.categoryList.itemsPerCol + 1, 1)

		self.buttonRight:setVisible(needButtons and self.categoryList.firstVisibleItem <= lastFirstVisibleIndex)
	end
end

function ModHubCategoriesFrame:getMenuButtonInfo()
	local buttons = {}

	if #self.categories > 0 then
		table.insert(buttons, self.detailsButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.searchButtonInfo)

	self.toggleTopButtonInfo.text = self.getBetaToggleText()

	table.insert(buttons, self.toggleTopButtonInfo)

	return buttons
end

function ModHubCategoriesFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubCategoriesFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubCategoriesFrame:setBreadcrumbs(list)
	self.breadcrumbs:setBreadcrumbs(list)
end

function ModHubCategoriesFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubCategoriesFrame:onClickCategory(_, clickedElement)
	self:onDoubleClickCategory(_, clickedElement)
end

function ModHubCategoriesFrame:onDoubleClickCategory(_, clickedElement)
	local category = self.categoryElementToCategory[clickedElement]

	self.notifyActivatedCategoryCallback(category.id, category.name)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

function ModHubCategoriesFrame:onCategorySelected(itemIndex)
	for _, element in pairs(self.categoryList.listItems) do
		element:applyProfile(ModHubCategoriesFrame.PROFILE.LIST_ITEM_NEUTRAL)
	end

	local selectedElement = self.categoryList.listItems[itemIndex]

	if selectedElement ~= nil then
		selectedElement:applyProfile(ModHubCategoriesFrame.PROFILE.LIST_ITEM_SELECTED)
	end

	self:updateScrollButtons()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function ModHubCategoriesFrame:onClickLeft()
	self.categoryList:scrollTo(self.categoryList.firstVisibleItem - self.categoryList.itemsPerCol)
end

function ModHubCategoriesFrame:onClickRight()
	self.categoryList:scrollTo(self.categoryList.firstVisibleItem + self.categoryList.itemsPerCol)
end

function ModHubCategoriesFrame:onScroll()
	self:updateScrollButtons()
end

function ModHubCategoriesFrame:onButtonDetails()
	self:onDoubleClickCategory(nil, self.categoryList.listItems[self.categoryList.selectedIndex])
end

function ModHubCategoriesFrame:onButtonSearch()
	self.notifySearchCallback()
end

function ModHubCategoriesFrame:onButtonShowToggle()
	self:notifyToggleBetaCallback()
end

ModHubCategoriesFrame.PROFILE = {
	LIST_ITEM_SELECTED = "modHubCategoryItemSelected",
	LIST_ITEM_NEUTRAL = "modHubCategoryItem"
}
ModHubCategoriesFrame.L10N_SYMBOL = {
	BUTTON_DETAILS = "button_detail",
	BUTTON_SEARCH = "modHub_search"
}
