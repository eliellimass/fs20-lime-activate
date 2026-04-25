StableListElement = {}
local StableListElement_mt = Class(StableListElement, ListElement)

local function NO_ASSIGNMENT_FUNCTION()
end

function StableListElement:new(target, custom_mt)
	local self = ListElement:new(target, custom_mt or StableListElement_mt)

	self:include(IndexChangeSubjectMixin)

	self.dataSource = GuiDataSource.EMPTY_SOURCE
	self.assignItemDataFunction = NO_ASSIGNMENT_FUNCTION
	self.allowChildModification = true
	self.isLoaded = false

	return self
end

function StableListElement:loadFromXML(xmlFile, key)
	StableListElement:superClass().loadFromXML(self, xmlFile, key)

	self.itemTemplateId = getXMLString(xmlFile, key .. "#itemTemplateId") or ""
end

function StableListElement:clone(parent, includeId, suppressOnCreate)
	local cloned = StableListElement:superClass().clone(self, parent, includeId, suppressOnCreate)

	cloned:updateAlternatingBackground(true)
	StableListElement:superClass().updateItemPositionsInRange(cloned, 1, #cloned.elements)

	cloned.allowChildModification = cloned.allowChildModification or self.allowChildModification

	return cloned
end

function StableListElement:copyAttributes(src)
	StableListElement:superClass().copyAttributes(self, src)

	self.dataSource = src.dataSource
	self.assignItemDataFunction = src.assignItemDataFunction
	self.isLoaded = src.isLoaded
end

function StableListElement:onGuiSetupFinished()
	StableListElement:superClass().onGuiSetupFinished(self)

	if self.itemTemplateId ~= "" and not self.isLoaded then
		self:buildListItems()

		self.allowChildModification = false
		self.isLoaded = true
	end
end

function StableListElement:buildListItems()
	local itemTemplate = self:getDescendantById(self.itemTemplateId)

	if itemTemplate ~= nil then
		self:removeElement(itemTemplate)
		self:deleteListItems()

		self.selectedIndex = 0

		for i = 1, self.visibleItems do
			local listItem = itemTemplate:clone()

			self:addElement(listItem)
		end

		itemTemplate:delete()
		StableListElement:superClass().updateItemPositionsInRange(self, 1, #self.elements)
	else
		g_logManager:devWarning("Cannot find StableListElement item template with ID '%s', check configuration.", self.itemTemplateId)
	end
end

function StableListElement:delete()
	self.allowChildModification = true

	self.dataSource:removeChangeListener(self)
	StableListElement:superClass().delete(self)
end

function StableListElement:setDataSource(guiDataSource)
	self.dataSource:removeChangeListener(self)

	self.dataSource = guiDataSource or GuiDataSource.EMPTY_SOURCE

	self.dataSource:addChangeListener(self, self.onDataSourceChanged)
	self:raiseSliderUpdateEvent()
end

function StableListElement:getItemCount()
	return self.dataSource:getCount()
end

function StableListElement:getSelectedDataIndex()
	return self.selectedIndex
end

function StableListElement:setAssignItemDataFunction(assignItemDataFunction)
	self.assignItemDataFunction = assignItemDataFunction or NO_ASSIGNMENT_FUNCTION
end

function StableListElement:onDataSourceChanged()
	self.handleFocus = self.dataSource:getCount() > 0

	self:raiseSliderUpdateEvent()
end

function StableListElement:getSelectedElementIndex()
	return self.selectedIndex - self.firstVisibleItem + 1
end

function StableListElement:addElement(element)
	if self.allowChildModification then
		StableListElement:superClass().addElement(self, element)
	end
end

function StableListElement:removeElement(element)
	if self.allowChildModification then
		StableListElement:superClass().removeElement(self, element)
	end
end

function StableListElement:getSelectedElement()
	local elementIndex = self.selectedIndex - self.firstVisibleItem + 1

	return self.elements[elementIndex], elementIndex
end

function StableListElement:setSelectedIndex(index, forceChangeEvent, direction)
	local numItems = self.dataSource:getCount()
	local newIndex = MathUtil.clamp(index, 0, numItems)

	if newIndex ~= self.selectedIndex then
		self.lastClickTime = nil
	end

	local nextItem = self.elements[newIndex - self.firstVisibleItem + 1]

	if nextItem ~= nil and (nextItem.disabled or not nextItem.allowFocus) then
		local anySelectable = false

		for _, element in pairs(self.elements) do
			if not element.disabled and element.allowFocus then
				anySelectable = true

				break
			end
		end

		if anySelectable then
			newIndex = newIndex + (direction or 1)

			if numItems < newIndex or newIndex < 1 then
				if newIndex == 0 then
					self:scrollTo(1)
				end

				return
			end

			if direction == 0 then
				return
			end

			return self:setSelectedIndex(newIndex, forceChangeEvent, direction or 1)
		end
	end

	local hasChanged = self.selectedIndex ~= newIndex
	self.selectedIndex = newIndex
	local newFirstVisibleItem = self:calculateFirstVisibleItem(newIndex)

	if hasChanged or newFirstVisibleItem ~= self.firstVisibleItem then
		self:scrollTo(newFirstVisibleItem)
	end

	if hasChanged and self.isLoaded or forceChangeEvent then
		self:notifyIndexChange(newIndex, numItems)
		self:raiseCallback("onSelectionChangedCallback", newIndex)
	end

	self:applyElementSelection()
end

function StableListElement:updateItemPositionsInRange(startIndex, endIndex)
	local topPos = self.size[2] - self.listItemStartYOffset - self.listItemHeight
	local leftPos = self.listItemStartXOffset

	for i, element in pairs(self.elements) do
		element:setVisible(false)
	end

	local dataStartIndex = self.firstVisibleItem
	local dataEndIndex = self.firstVisibleItem + endIndex - startIndex
	local elementIndex = 1

	for _, dataEntry in self.dataSource:iterateRange(dataStartIndex, dataEndIndex) do
		local element = self.elements[elementIndex]

		if element == nil then
			break
		end

		element:reset()
		element:setVisible(true)
		element:fadeIn()
		self.assignItemDataFunction(element, dataEntry)

		elementIndex = elementIndex + 1
	end

	if self.dataSource:getCount() > 0 then
		self:updateAlternatingBackground()

		local selectedElement = self:getSelectedElement()

		if selectedElement ~= nil and (selectedElement.disabled or not selectedElement.allowFocus) then
			self:setSelectedIndex(self.selectedIndex)
		end

		self:applyElementSelection()

		for i, element in ipairs(self.elements) do
			local xPos, yPos = self:getItemPosition(leftPos, topPos, i - 1, element)

			element:setPosition(xPos, yPos)
		end
	end
end

function StableListElement:notifyDoubleClick(clickedElementIndex)
	self:raiseCallback("onDoubleClickCallback", self.selectedIndex, self.elements[clickedElementIndex])
end

function StableListElement:notifyClick(clickedElementIndex)
	self:raiseCallback("onClickCallback", self.selectedIndex, self.elements[clickedElementIndex])
end
