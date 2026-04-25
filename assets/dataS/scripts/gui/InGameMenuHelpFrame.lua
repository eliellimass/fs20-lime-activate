InGameMenuHelpFrame = {}
local InGameMenuHelpFrame_mt = Class(InGameMenuHelpFrame, TabbedMenuFrameElement)
InGameMenuHelpFrame.CONTROLS = {
	HELP_CONTAINER = "helpContainer",
	HELP_LINE_TEXT = "helpLineTextElement",
	HELP_LINE_IMAGE = "helpLineImageElement",
	HELP_LINE_CONTENT_BOX = "helpLineContentBox",
	HELP_LINE_LIST_ITEM_TEMPLATE = "helpLineListItemTemplate",
	CATEGORY_TEMPLATE = "helpLineListCategoryTemplate",
	HELP_LINE_LIST = "helpLineList",
	HELP_LINE_TITLE_TEXT = "helpLineTitleElement"
}
InGameMenuHelpFrame.LIST_ITEM_TEXT_NAME = "listItemText"
InGameMenuHelpFrame.CATEGORY_CYCLE_COOLDOWN = 300

function InGameMenuHelpFrame:new(subclass_mt, l10n, helpLineManager)
	local subclass_mt = subclass_mt or InGameMenuHelpFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuHelpFrame.CONTROLS)

	self.l10n = l10n
	self.helpLineManager = helpLineManager
	self.baseDirectory = ""
	self.isHelpLineInitialized = false
	self.rows = {}

	return self
end

function InGameMenuHelpFrame:copyAttributes(src)
	InGameMenuHelpFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
	self.helpLineManager = src.helpLineManager
end

function InGameMenuHelpFrame:onOpen()
	InGameMenuHelpFrame:superClass().onOpen(self)
	self:loadHelpLine()
end

function InGameMenuHelpFrame:onFrameOpen()
	InGameMenuHelpFrame:superClass().onFrameOpen(self)
	self:updateContents(self.helpLineList.selectedIndex)
end

function InGameMenuHelpFrame:reset()
	InGameMenuHelpFrame:superClass().reset(self)

	self.isHelpLineInitialized = false
end

function InGameMenuHelpFrame:setMissionBaseDirectory(baseDirectory)
	self.baseDirectory = baseDirectory
end

function InGameMenuHelpFrame:createList()
	self.helpLineList:deleteListItems()

	for _, item in ipairs(self.rows) do
		local new = nil

		if item.isHeader then
			if self.helpLineListCategoryTemplate ~= nil then
				new = self.helpLineListCategoryTemplate:clone(self.helpLineList)

				new:applyProfile("ingameMenuHelpListCategory")

				new.doNotAlternate = true
			end
		elseif self.helpLineListItemTemplate ~= nil then
			new = self.helpLineListItemTemplate:clone(self.helpLineList)
		end

		if new ~= nil then
			local itemText = new:getDescendantByName(InGameMenuHelpFrame.LIST_ITEM_TEXT_NAME)

			itemText:setText(self.l10n:convertText(item.title))
			new:updateAbsolutePosition()
		end
	end

	self.helpLineList:setSelectedIndex(2)
	self:onHelpLineListSelectionChanged(2)
end

function InGameMenuHelpFrame:loadHelpLine()
	if self.isHelpLineInitialized or self.baseDirectory == nil then
		return
	end

	self.isHelpLineInitialized = true
	self.rows = {}

	for categoryIndex, category in ipairs(self.helpLineManager:getCategories()) do
		table.insert(self.rows, {
			isHeader = true,
			title = category.title
		})

		if category ~= nil then
			for pageIndex, page in ipairs(category.pages) do
				table.insert(self.rows, {
					title = page.title,
					category = categoryIndex,
					item = pageIndex
				})
			end
		end
	end

	self:createList()
end

function InGameMenuHelpFrame:getMainElementSize()
	return self.helpContainer.size
end

function InGameMenuHelpFrame:getMainElementPosition()
	return self.helpContainer.absPosition
end

function InGameMenuHelpFrame:updateContents(rowIndex)
	for i = #self.helpLineContentBox.elements, 1, -1 do
		self.helpLineContentBox.elements[i]:delete()
	end

	local item = self.rows[rowIndex]

	if item == nil or item.isHeader then
		return
	end

	local category = self.helpLineManager:getCategory(item.category)

	if category ~= nil then
		local page = category.pages[item.item]

		if page ~= nil then
			self.helpLineTitleElement:setText(self.helpLineManager:convertText(page.title))
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)

			for _, item in pairs(page.items) do
				if item.type == HelpLineManager.ITEM_TYPE.TEXT then
					local textElem = self.helpLineTextElement:clone(self.helpLineContentBox)

					textElem:setText(self.helpLineManager:convertText(item.value))

					local height = textElem:getTextHeight()

					textElem:setSize(nil, height)
				elseif item.type == HelpLineManager.ITEM_TYPE.IMAGE then
					local imageElem = self.helpLineImageElement:clone(self.helpLineContentBox)

					imageElem:setSize(nil, self.helpLineImageElement.size[2] * item.heightScale)

					local filename = Utils.getFilename(item.value, self.baseDirectory)

					imageElem:setImageFilename(filename)
					imageElem:setImageUVs(nil, unpack(item.imageUVs))
				end
			end

			self.helpLineContentBox:invalidateLayout(true)
		end
	end
end

function InGameMenuHelpFrame:onHelpLineListSelectionChanged(rowIndex)
	self:updateContents(rowIndex)
end
