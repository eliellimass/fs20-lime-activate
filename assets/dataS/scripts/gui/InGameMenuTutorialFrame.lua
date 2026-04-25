InGameMenuTutorialFrame = {}
local InGameMenuTutorialFrame_mt = Class(InGameMenuTutorialFrame, TabbedMenuFrameElement)
InGameMenuTutorialFrame.CONTROLS = {
	TUTORIAL_SLIDER = "tutorialSlider",
	TUTORIAL_LIST_TEMPLATE = "tutorialTemplate",
	TUTORIAL_WRAPPER = "mainFrameWrapper",
	TUTORIAL_LIST = "tutorialList"
}

function InGameMenuTutorialFrame:new(subclass_mt)
	local subclass_mt = subclass_mt or InGameMenuTutorialFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuTutorialFrame.CONTROLS)

	self.missionInfo = nil
	self.currentTutorialMessage = nil

	return self
end

function InGameMenuTutorialFrame:onOpen(element)
	InGameMenuTutorialFrame:superClass().onOpen(self)

	if self.isActive then
		self:setupTutorialScreen()
	end
end

function InGameMenuTutorialFrame:reset()
	InGameMenuTutorialFrame:superClass().reset(self)

	self.tutorialList.selectedIndex = 0
	self.tutorialSlider.sliderValue = 0
end

function InGameMenuTutorialFrame:setupTutorialScreen()
	self.tutorialList:deleteListItems()

	local lastChecked = nil

	for i, message in pairs(g_currentMission.tutorialMessages) do
		if message.text ~= nil then
			self.currentTutorialMessage = message
			local newMessage = self.tutorialTemplate:clone(self.tutorialList)

			newMessage:updateAbsolutePosition()

			if message.checked then
				lastChecked = i
			end

			self.currentTutorialMessage = nil
		end
	end

	if lastChecked ~= nil then
		self.tutorialList:setSelectedIndex(lastChecked)
	end
end

function InGameMenuTutorialFrame:setMissionInfo(isTutorial, missionInfo)
	self.isActive = isTutorial
	self.missionInfo = missionInfo
end

function InGameMenuTutorialFrame:getMainElementSize()
	return self.mainFrameWrapper.size
end

function InGameMenuTutorialFrame:getMainElementPosition()
	return self.mainFrameWrapper.absPosition
end

function InGameMenuTutorialFrame:onCreateItemText(element)
	if self.currentTutorialMessage ~= nil then
		element:setText(g_i18n:getText(self.currentTutorialMessage.text, self.missionInfo.customEnvironment))
	end
end

function InGameMenuTutorialFrame:onCreateItemTick(element)
	if self.currentTutorialMessage ~= nil then
		element:setVisible(self.currentTutorialMessage.checked)
	end
end
