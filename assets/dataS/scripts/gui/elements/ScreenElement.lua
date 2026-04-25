ScreenElement = {
	CONTROLS = {
		PAGE_SELECTOR = "pageSelector"
	}
}
local ScreenElement_mt = Class(ScreenElement, FrameElement)

function ScreenElement:new(target, custom_mt)
	local self = FrameElement:new(target, custom_mt or ScreenElement_mt)
	self.isBackAllowed = true
	self.handleCursorVisibility = true
	self.returnScreenName = nil
	self.returnScreen = nil
	self.returnScreenClass = nil
	self.isOpen = false
	self.lastMouseCursorState = false
	self.isInitialized = false
	self.nextClickSoundMuted = false

	self:registerControls(ScreenElement.CONTROLS)

	return self
end

function ScreenElement:onOpen()
	local rootElement = self:getRootElement()

	for _, child in ipairs(rootElement.elements) do
		child:onOpen()
	end

	if not self.isInitialized then
		self:initializeScreen()
	end

	self.lastMouseCursorState = g_inputBinding:getShowMouseCursor()

	g_inputBinding:setShowMouseCursor(true)

	self.isOpen = true
end

function ScreenElement:initializeScreen()
	self.isInitialized = true

	if self.pageSelector ~= nil and self.pageSelector.disableButtonSounds ~= nil then
		self.pageSelector:disableButtonSounds()
	end
end

function ScreenElement:onClose()
	local rootElement = self:getRootElement()

	for _, child in ipairs(rootElement.elements) do
		child:onClose()
	end

	if self.handleCursorVisibility then
		g_inputBinding:setShowMouseCursor(self.lastMouseCursorState)
	end

	self.isOpen = false
end

function ScreenElement:onClickOk()
	return true
end

function ScreenElement:onClickActivate()
	return true
end

function ScreenElement:onClickCancel()
	return true
end

function ScreenElement:onClickMenuExtra1()
	return true
end

function ScreenElement:onClickMenuExtra2()
	return true
end

function ScreenElement:onClickMenu()
	return true
end

function ScreenElement:onClickShop()
	return true
end

function ScreenElement:onPagePrevious()
	self.pageSelector:inputLeft(true)
end

function ScreenElement:onPageNext()
	self.pageSelector:inputRight(true)
end

function ScreenElement:onClickBack(forceBack, usedMenuButton)
	local eventUnused = true

	if self.isBackAllowed or forceBack then
		if self.returnScreenName ~= nil then
			g_gui:showGui(self.returnScreenName)

			eventUnused = false
		elseif self.returnScreenClass ~= nil then
			self:changeScreen(self.returnScreenClass)

			eventUnused = false
		end
	end

	return eventUnused
end

function ScreenElement:invalidateScreen()
end

function ScreenElement:inputEvent(action, value, eventUsed)
	eventUsed = ScreenElement:superClass().inputEvent(action, value, eventUsed)

	if self.inputDisableTime <= 0 then
		if self.pageSelector ~= nil and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
			if action == InputAction.MENU_PAGE_PREV then
				self:onPagePrevious()
			elseif action == InputAction.MENU_PAGE_NEXT then
				self:onPageNext()
			end

			eventUsed = true
		end

		if not eventUsed then
			local sampleToPlay = nil

			if action == InputAction.MENU then
				eventUsed = not self:onClickMenu()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.BACK
			elseif action == InputAction.TOGGLE_STORE then
				eventUsed = not self:onClickShop()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.BACK
			elseif action == InputAction.TOGGLE_MAP then
				eventUsed = not self:onClickMenu()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.BACK
			elseif action == InputAction.MENU_ACTIVATE then
				eventUsed = not self:onClickActivate()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			elseif action == InputAction.MENU_CANCEL then
				eventUsed = not self:onClickCancel()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			elseif action == InputAction.MENU_ACCEPT then
				eventUsed = not self:onClickOk()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			elseif action == InputAction.MENU_BACK then
				eventUsed = not self:onClickBack(false, false)
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.BACK
			elseif action == InputAction.MENU_EXTRA_1 then
				eventUsed = not self:onClickMenuExtra1()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			elseif action == InputAction.MENU_EXTRA_2 then
				eventUsed = not self:onClickMenuExtra2()
				sampleToPlay = GuiSoundPlayer.SOUND_SAMPLES.CLICK
			end

			if eventUsed and sampleToPlay ~= nil and not self.nextClickSoundMuted then
				self:playSample(sampleToPlay)
			end

			self.nextClickSoundMuted = false
		end
	end

	return eventUsed
end

function ScreenElement:setReturnScreen(screenName, screen)
	self.returnScreenName = screenName
	self.returnScreen = screen
end

function ScreenElement:setReturnScreenClass(returnScreenClass)
	self.returnScreenClass = returnScreenClass
end

function ScreenElement:getIsOpen()
	return self.isOpen
end

function ScreenElement:canReceiveFocus()
	if not self.visible then
		return false
	end

	for _, v in ipairs(self.elements) do
		if not v:canReceiveFocus() then
			return false
		end
	end

	return true
end

function ScreenElement:setNextScreenClickSoundMuted(value)
	if value == nil then
		value = true
	end

	self.nextClickSoundMuted = value
end
