MultiTextOptionElement = {}
local MultiTextOptionElement_mt = Class(MultiTextOptionElement, GuiElement)

function MultiTextOptionElement:new(target, custom_mt)
	local self = GuiElement:new(target, custom_mt or MultiTextOptionElement_mt)

	self:include(IndexChangeSubjectMixin)
	self:include(PlaySampleMixin)

	self.isChecked = false
	self.mouseEntered = false
	self.buttonLRChange = false
	self.canChangeState = true
	self.state = 1
	self.wrap = true
	self.texts = {}
	self.scrollDelayDuration = 200
	self.leftDelayTime = 0
	self.rightDelayTime = 0
	self.forceHighlight = false
	self.leftButtonElement = nil
	self.rightButtonElement = nil
	self.textElement = nil
	self.labelElement = nil

	return self
end

function MultiTextOptionElement:loadFromXML(xmlFile, key)
	MultiTextOptionElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")

	self.wrap = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrap"), self.wrap)
	self.buttonLRChange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#buttonLRChange"), self.buttonLRChange)
	local text = getXMLString(xmlFile, key .. "#texts")

	if text ~= nil then
		local texts = StringUtil.splitString("|", text)

		for _, text in pairs(texts) do
			if text:sub(1, 6) == "$l10n_" then
				text = g_i18n:getText(text:sub(7))
			end

			table.insert(self.texts, text)
		end
	end
end

function MultiTextOptionElement:loadProfile(profile, applyProfile)
	MultiTextOptionElement:superClass().loadProfile(self, profile, applyProfile)

	self.wrap = profile:getBool("wrap", self.wrap)
	self.buttonLRChange = profile:getBool("buttonLRChange", self.buttonLRChange)
	local text = profile:getValue("texts")

	if text ~= nil then
		local texts = StringUtil.splitString("|", text)

		for _, text in pairs(texts) do
			if text:sub(1, 6) == "$l10n_" then
				text = g_i18n:getText(text:sub(7))
			end

			table.insert(self.texts, text)
		end
	end
end

function MultiTextOptionElement:copyAttributes(src)
	MultiTextOptionElement:superClass().copyAttributes(self, src)

	self.isChecked = src.isChecked
	self.buttonLRChange = src.buttonLRChange
	self.state = src.state
	self.wrap = src.wrap
	self.scrollDelayDuration = src.scrollDelayDuration
	self.canChangeState = src.canChangeState
	self.onClickCallback = src.onClickCallback
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback

	for _, text in pairs(src.texts) do
		self:addText(text)
	end

	GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function MultiTextOptionElement:setState(state, forceEvent)
	local numTexts = #self.texts
	self.state = math.max(math.min(state, numTexts), 1)

	self:updateTextElement()

	if forceEvent then
		self:raiseCallback("onClickCallback", self.state, self, true)
	end

	self:notifyIndexChange(self.state, numTexts)
end

function MultiTextOptionElement:setForceHighlight(needForceHighlight)
	self.forceHighlight = needForceHighlight
end

function MultiTextOptionElement:addElement(element)
	MultiTextOptionElement:superClass().addElement(self, element)

	if table.getn(self.elements) == 1 then
		self.leftButtonElement = element
		self.leftButtonElement.forceHighlight = true

		element:setHandleFocus(false)

		element.target = self
		element.onClickCallback = self.onLeftButtonClicked

		self:setDisabled(self.disabled)
	elseif table.getn(self.elements) == 2 then
		self.rightButtonElement = element
		self.rightButtonElement.forceHighlight = true
		element.target = self

		element:setHandleFocus(false)

		element.onClickCallback = self.onRightButtonClicked

		self:setDisabled(self.disabled)
	elseif table.getn(self.elements) == 3 then
		self.textElement = element

		self:updateTextElement()
	elseif table.getn(self.elements) == 4 then
		self.labelElement = element
	end
end

function MultiTextOptionElement:disableButtonSounds()
	if self.leftButtonElement ~= nil then
		self.leftButtonElement:disablePlaySample()
	end

	if self.rightButtonElement ~= nil then
		self.rightButtonElement:disablePlaySample()
	end
end

function MultiTextOptionElement:addText(text, i)
	if i == nil then
		table.insert(self.texts, text)
	else
		table.insert(self.texts, i, text)
	end

	self:updateTextElement()
	self:notifyIndexChange(self.state, #self.texts)
end

function MultiTextOptionElement:setTexts(texts)
	self.texts = texts or {}
	self.state = math.min(self.state, #self.texts)

	self:updateTextElement()
	self:notifyIndexChange(self.state, #self.texts)
end

function MultiTextOptionElement:setLabel(labelString)
	self.labelElement:setText(labelString)
end

function MultiTextOptionElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if not eventUsed and not self.forceHighlight and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then
			if not self.mouseEntered and not self.focusActive then
				FocusManager:setHighlight(self)

				self.mouseEntered = true
			end
		elseif self.mouseEntered and not self.focusActive then
			FocusManager:unsetHighlight(self)

			self.mouseEntered = false
		end
	end

	return eventUsed
end

function MultiTextOptionElement:inputEvent(action, value, eventUsed)
	eventUsed = MultiTextOptionElement:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed then
		if action == InputAction.MENU_AXIS_LEFT_RIGHT then
			if value < -g_analogStickHTolerance then
				eventUsed = true

				self:inputLeft(false)
			elseif g_analogStickHTolerance < value then
				eventUsed = true

				self:inputRight(false)
			end
		elseif action == InputAction.MENU_PAGE_PREV then
			eventUsed = true

			self:inputLeft(true)
		elseif action == InputAction.MENU_PAGE_NEXT then
			eventUsed = true

			self:inputRight(true)
		end
	end

	return eventUsed
end

function MultiTextOptionElement:inputLeft(isShoulderButton)
	if self.leftDelayTime <= g_time and (isShoulderButton and self:getIsVisible() and self.buttonLRChange or self.leftButtonElement:isFocused()) then
		self:onLeftButtonClicked(nil, true)

		if not GS_IS_CONSOLE_VERSION then
			FocusManager:setFocus(self)
		end

		self.leftDelayTime = g_time + self.scrollDelayDuration
		self.rightDelayTime = 0

		return true
	else
		return false
	end
end

function MultiTextOptionElement:inputRight(isShoulderButton)
	if self.rightDelayTime <= g_time and (isShoulderButton and self:getIsVisible() and self.buttonLRChange or self.rightButtonElement:isFocused()) then
		self:onRightButtonClicked(nil, true)

		if not GS_IS_CONSOLE_VERSION then
			FocusManager:setFocus(self)
		end

		self.rightDelayTime = g_time + self.scrollDelayDuration
		self.leftDelayTime = 0

		return true
	else
		return false
	end
end

function MultiTextOptionElement:onRightButtonClicked(steps, noFocus)
	if self:getCanChangeState() then
		if steps == nil then
			steps = 1
		end

		if steps ~= nil and type(steps) ~= "number" then
			steps = 1
		end

		for i = 1, steps do
			if self.wrap then
				self.state = self.state + 1

				if table.getn(self.texts) < self.state then
					self.state = 1
				end
			else
				self.state = math.min(self.state + 1, table.getn(self.texts))
			end
		end

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.SLIDER)
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self)
		self:setSoundSuppressed(false)
		self:updateTextElement()
		self:raiseCallback("onClickCallback", self.state, self, false)
		self:notifyIndexChange(self.state, #self.texts)

		if noFocus == nil or not noFocus then
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end

			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
	end
end

function MultiTextOptionElement:onLeftButtonClicked(steps, noFocus)
	if self:getCanChangeState() then
		if steps == nil then
			steps = 1
		end

		if steps ~= nil and type(steps) ~= "number" then
			steps = 1
		end

		for i = 1, steps do
			if self.wrap then
				self.state = self.state - 1

				if self.state < 1 then
					self.state = table.getn(self.texts)
				end
			else
				self.state = math.max(self.state - 1, 1)
			end
		end

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.SLIDER)
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self)
		self:setSoundSuppressed(false)
		self:updateTextElement()
		self:raiseCallback("onClickCallback", self.state, self, true)
		self:notifyIndexChange(self.state, #self.texts)

		if noFocus == nil or not noFocus then
			if self.leftButtonElement ~= nil then
				self.leftButtonElement:onFocusEnter()
			end

			if self.rightButtonElement ~= nil then
				self.rightButtonElement:onFocusEnter()
			end
		end
	end
end

function MultiTextOptionElement:getCanChangeState()
	return self.canChangeState
end

function MultiTextOptionElement:setCanChangeState(canChangeState)
	self.canChangeState = canChangeState
end

function MultiTextOptionElement:canReceiveFocus(element, direction)
	return not self.disabled and self:getIsVisible() and self.handleFocus
end

function MultiTextOptionElement:onFocusLeave()
	MultiTextOptionElement:superClass().onFocusLeave(self)
	self:raiseCallback("onLeaveCallback", self)

	if self.rightButtonElement ~= nil and self.rightButtonElement.state ~= GuiOverlay.STATE_NORMAL then
		self.rightButtonElement:onFocusLeave()
	end

	if self.leftButtonElement ~= nil and self.leftButtonElement.state ~= GuiOverlay.STATE_NORMAL then
		self.leftButtonElement:onFocusLeave()
	end
end

function MultiTextOptionElement:onFocusEnter()
	MultiTextOptionElement:superClass().onFocusEnter(self)

	if self.rightButtonElement ~= nil and self.rightButtonElement.state ~= GuiOverlay.STATE_FOCUSED then
		self.rightButtonElement:onFocusEnter()
	end

	if self.leftButtonElement ~= nil and self.leftButtonElement.state ~= GuiOverlay.STATE_FOCUSED then
		self.leftButtonElement:onFocusEnter()
	end

	self:raiseCallback("onFocusCallback", self)
end

function MultiTextOptionElement:onHighlight()
	MultiTextOptionElement:superClass().onHighlight(self)

	if self.rightButtonElement ~= nil and self.rightButtonElement:getOverlayState() == GuiOverlay.STATE_NORMAL then
		self.rightButtonElement:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
	end

	if self.leftButtonElement ~= nil and self.leftButtonElement:getOverlayState() == GuiOverlay.STATE_NORMAL then
		self.leftButtonElement:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
	end
end

function MultiTextOptionElement:onHighlightRemove()
	MultiTextOptionElement:superClass().onHighlightRemove(self)

	if self.rightButtonElement ~= nil and self.rightButtonElement:getOverlayState() == GuiOverlay.STATE_HIGHLIGHTED then
		self.rightButtonElement:setOverlayState(GuiOverlay.STATE_NORMAL)
	end

	if self.leftButtonElement ~= nil and self.leftButtonElement:getOverlayState() == GuiOverlay.STATE_HIGHLIGHTED then
		self.leftButtonElement:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function MultiTextOptionElement:updateTextElement()
	if self.textElement ~= nil then
		if self.texts[self.state] ~= nil then
			self.textElement:setText(self.texts[self.state])
		else
			self.textElement:setText("")
		end
	end
end

function MultiTextOptionElement:getState()
	return self.state
end
