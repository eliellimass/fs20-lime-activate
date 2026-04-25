TutorialScreen = {
	CONTROLS = {
		SELECTOR_RIGHT = "selectorRight",
		STATS_VALUE = "statsValue",
		SELECTOR_LEFT = "selectorLeft",
		LIST_TEMPLATE = "listItemTemplate",
		TUTORIAL_LIST = "tutorialList"
	},
	LIST_TEMPLATE_ELEMENT_NAME = {
		ICON = "icon",
		TITLE = "title",
		DESCRIPTION = "description"
	}
}
local TutorialScreen_mt = Class(TutorialScreen, ScreenElement)

function TutorialScreen:new(target, custom_mt)
	local self = ScreenElement:new(target, custom_mt or TutorialScreen_mt)

	self:registerControls(TutorialScreen.CONTROLS)

	self.selectedIndex = 0
	self.tutorials = {}
	self.tutorialElements = {}
	self.tutorialsDoneElements = {}
	self.returnScreenName = "MainScreen"

	return self
end

function TutorialScreen:onCreate(element)
	if self.listItemTemplate ~= nil then
		self.listItemTemplate.parent:removeElement(self.listItemTemplate)
	end

	self:getTutorials()

	self.selectedIndex = 1

	self.tutorialList:setSelectedIndex(self.selectedIndex)
end

function TutorialScreen:onCreateTick(element)
	if self.currentTutorial ~= nil then
		self.tutorialsDoneElements[self.currentTutorial.id] = element

		element:setVisible(g_gameSettings:getTableValue("tutorialsDone", self.currentTutorial.id))
	end
end

function TutorialScreen:onClickOk(isMouseClick)
	TutorialScreen:superClass().onClickOk(self)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self:startTutorial()
end

function TutorialScreen:onOpen()
	TutorialScreen:superClass().onOpen(self)
	self:updateFinishedTutorials()
	FocusManager:setFocus(self.tutorialList)
	self.tutorialList:setSelectedIndex(1, true)
	g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.onProfileChanged, self)
end

function TutorialScreen:onClose()
	TutorialScreen:superClass().onClose(self)
	g_messageCenter:unsubscribeAll(self)
end

function TutorialScreen:onProfileChanged()
	self:updateFinishedTutorials()
end

function TutorialScreen:updateFinishedTutorials()
	if self.tutorials ~= nil then
		local numFinished = 0

		for _, mission in pairs(self.tutorials) do
			local element = self.tutorialsDoneElements[mission.id]
			local finished = g_gameSettings:getTableValue("tutorialsDone", mission.id)

			element:setVisible(finished)

			if finished then
				numFinished = numFinished + 1
			end
		end

		self.statsValue:setText(string.format(g_i18n:getText("ui_tutorialsStatsValue"), numFinished, table.getn(self.tutorials)), true)
		self.statsValue.parent:invalidateLayout()
	end
end

function TutorialScreen:onDoubleClick()
	self:onClickOk(true)
end

function TutorialScreen:onListSelectionChanged(rowIndex)
	self.selectedIndex = rowIndex

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function TutorialScreen:getTutorials()
	if not GS_IS_MOBILE_VERSION then
		local xmlFile = loadXMLFile("tutorials.xml", "dataS/tutorials.xml")
		self.maxTitleTextSize = nil
		self.tutorialIdToTutorial = {}
		local i = 0

		while true do
			local key = string.format("tutorials.tutorial(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local tutorial = FSTutorialMissionInfo:new("", nil)

			tutorial:loadDefaults()

			if tutorial:loadFromXML(xmlFile, key) then
				table.insert(self.tutorials, tutorial)

				self.tutorialIdToTutorial[tutorial.id] = tutorial

				if self.listItemTemplate ~= nil then
					self.tutorialElements[tutorial.id] = {}
					self.currentTutorial = tutorial
					local newListItem = self.listItemTemplate:clone(self.tutorialList)

					newListItem:updateAbsolutePosition()

					local titleElement = newListItem:getDescendantByName(TutorialScreen.LIST_TEMPLATE_ELEMENT_NAME.TITLE)

					titleElement:setText(tutorial.name)

					local descriptionElement = newListItem:getDescendantByName(TutorialScreen.LIST_TEMPLATE_ELEMENT_NAME.DESCRIPTION)

					descriptionElement:setText(tutorial.description)

					local bitmapElement = newListItem:getDescendantByName(TutorialScreen.LIST_TEMPLATE_ELEMENT_NAME.ICON)

					bitmapElement:setImageFilename(tutorial.iconFilename)

					local v0, u0, v1, u1, v2, u2, v3, u3 = unpack(tutorial.iconUVs)

					bitmapElement:setImageUVs(nil, v0, u0, v1, u1, v2, u2, v3, u3)
					bitmapElement:setImageColor(nil, 1, 1, 1, 1)

					self.currentTutorial = nil
				end
			end

			i = i + 1
		end

		self.startIndex = 1
		self.selectedIndex = 1

		delete(xmlFile)
	end
end

function TutorialScreen:startTutorial(tutorialId)
	local missionInfo = self.tutorials[self.selectedIndex]

	if tutorialId ~= nil and self.tutorialIdToTutorial[tutorialId] ~= nil then
		missionInfo = self.tutorialIdToTutorial[tutorialId]
	end

	setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
	resetSplitShapes()

	local missionDynamicInfo = {
		isMultiplayer = false
	}

	self:startGame(missionInfo, missionDynamicInfo)
end

function TutorialScreen:startGame(missionInfo, missionDynamicInfo)
	g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self:changeScreen(MPLoadingScreen)
	g_mpLoadingScreen:loadGameRelatedData()
	g_mpLoadingScreen:startLocal()
end
