DifficultyScreen = {
	CONTROLS = {
		DIFFICULTY_LIST = "difficultyList",
		LIST_ITEM_TEMPLATE = "listItemTemplate"
	},
	LIST_TEMPLATE_ELEMENT_NAME = {
		ICON = "icon",
		TITLE = "title",
		DESCRIPTION = "description"
	}
}
local DifficultyScreen_mt = Class(DifficultyScreen, ScreenElement)

function DifficultyScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or DifficultyScreen_mt)

	self:registerControls(DifficultyScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.isMultiplayer = false
	self.selectedDifficulty = startMissionInfo.difficulty

	return self
end

function DifficultyScreen:onCreate()
	if self.listItemTemplate ~= nil then
		self.listItemTemplate.parent:removeElement(self.listItemTemplate)
	end

	self:createItems()
end

function DifficultyScreen:onOpen()
	DifficultyScreen:superClass().onOpen(self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.difficultyList)

	local selectedIndex = 1

	if g_isPresentationVersion then
		self.difficultyList.listItems[2]:setDisabled(true)
		self.difficultyList.listItems[3]:setDisabled(true)

		function self.difficultyList.shouldFocusChange(...)
		end
	end

	if self.isMultiplayer then
		selectedIndex = 2
	end

	self.difficultyList.listItems[1]:setDisabled(self.isMultiplayer)
	self:onListSelectionChanged(selectedIndex)

	if self.difficulties ~= nil then
		self.difficultyList:setSelectedIndex(selectedIndex)
	end

	self:setSoundSuppressed(false)
	self.difficultyList:updateAbsolutePosition()

	-- if GS_IS_MOBILE_VERSION then
	-- 	self:onClickOk()
	-- end
end

function DifficultyScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer

	self.difficultyList.listItems[1]:setDisabled(self.isMultiplayer)
end

function DifficultyScreen:onDoubleClick()
	self:onClickOk(true)
end

function DifficultyScreen:onClick(rowIndex)
	if g_isPresentationVersion and rowIndex > 1 then
		self.difficultyList.lastClickTime = g_time - 1000

		self.difficultyList:setSelectedIndex(1)
	end
end

function DifficultyScreen:onListSelectionChanged(rowIndex)
	self.selectedDifficulty = rowIndex

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function DifficultyScreen:onClickOk(isMouseClick)
	if g_isPresentationVersion and self.selectedDifficulty ~= 1 then
		return
	end

	self.startMissionInfo.difficulty = self.selectedDifficulty

	self:changeScreen(MapSelectionScreen, DifficultyScreen)
end

function DifficultyScreen:createItems()
	local levels = {
		"easy",
		"normal",
		"hard"
	}
	self.difficulties = {}

	for i, level in ipairs(levels) do
		local difficulty = {
			id = i
		}
		local newListItem = self.listItemTemplate:clone(self.difficultyList)

		newListItem:updateAbsolutePosition()

		local titleElement = newListItem:getDescendantByName(DifficultyScreen.LIST_TEMPLATE_ELEMENT_NAME.TITLE)

		titleElement:setText(g_i18n:getText("ui_difficulty" .. i))

		local descriptionElement = newListItem:getDescendantByName(DifficultyScreen.LIST_TEMPLATE_ELEMENT_NAME.DESCRIPTION)

		descriptionElement:setText(g_i18n:getText("ui_difficulty_" .. level .. "_description"))

		local bitmapElement = newListItem:getDescendantByName(DifficultyScreen.LIST_TEMPLATE_ELEMENT_NAME.ICON)

		bitmapElement:setImageFilename(string.format("dataS2/menu/difficultyIcon_%s.png", level))
		bitmapElement:setImageUVs(nil, 0, 0, 0, 1, 1, 0, 1, 1)
		bitmapElement:setImageColor(nil, 1, 1, 1, 1)
		table.insert(self.difficulties, difficulty)
	end
end

function DifficultyScreen:selectDifficulty(difficulty)
	self.selectedDifficulty = difficulty
end

function DifficultyScreen:update(dt)
	DifficultyScreen:superClass().update(self, dt)

	if self.isMultiplayer and GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("MainScreen")
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end
end
