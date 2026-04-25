SliderElement = {}
local SliderElement_mt = Class(SliderElement, GuiElement)
SliderElement.DIRECTION_X = 1
SliderElement.DIRECTION_Y = 2

function SliderElement:new(target, custom_mt)
	local self = GuiElement:new(target, custom_mt or SliderElement_mt)

	self:include(PlaySampleMixin)

	self.mouseDown = false
	self.minValue = 0
	self.maxValue = 100
	self.currentValue = 0
	self.sliderValue = 0
	self.stepSize = 1
	self.direction = SliderElement.DIRECTION_X
	self.hasButtons = true
	self.overlay = {}
	self.sliderOverlay = {}
	self.sliderOffset = -0.012
	self.sliderSize = {
		1,
		1
	}
	self.sliderPosition = {
		0,
		0
	}
	self.adjustSliderSize = true
	self.textElement = nil
	self.dataElementId = nil
	self.textElementId = nil
	self.minAbsSliderPos = 0.08
	self.maxAbsSliderPos = 0.92
	self.isSliderVisible = true
	self.needsSlider = true

	return self
end

function SliderElement:delete()
	GuiOverlay.deleteOverlay(self.sliderOverlay)
	GuiOverlay.deleteOverlay(self.overlay)
	SliderElement:superClass().delete(self)
end

function SliderElement:loadFromXML(xmlFile, key)
	SliderElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, nil, xmlFile, key)

	local direction = getXMLString(xmlFile, key .. "#direction")

	if direction ~= nil then
		if direction == "y" then
			self.direction = SliderElement.DIRECTION_Y
		elseif direction == "x" then
			self.direction = SliderElement.DIRECTION_X
		end
	end

	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onChanged", "onChangedCallback")

	self.hasButtons = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasButtons"), self.hasButtons)
	self.minValue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minValue"), self.minValue)
	self.maxValue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxValue"), self.maxValue)
	self.currentValue = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#currentValue"), self.currentValue)
	self.stepSize = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#stepSize"), self.stepSize)
	self.sliderOffset = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#sliderOffset"), {
		self.outputSize[2]
	}, {
		self.sliderOffset
	}))
	self.sliderSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#sliderSize"), self.outputSize, self.sliderSize)
	self.dataElementId = getXMLString(xmlFile, key .. "#dataElementId")
	self.dataElementName = getXMLString(xmlFile, key .. "#dataElementName")
	self.textElementId = getXMLString(xmlFile, key .. "#textElementId")

	GuiOverlay.createOverlay(self.overlay)
	GuiOverlay.createOverlay(self.sliderOverlay)
end

function SliderElement:loadProfile(profile, applyProfile)
	SliderElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, )
	GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, profile, nil, )

	local direction = profile:getValue("direction")

	if direction ~= nil then
		if direction == "y" then
			self.direction = SliderElement.DIRECTION_Y
		elseif direction == "x" then
			self.direction = SliderElement.DIRECTION_X
		end
	end

	self.hasButtons = profile:getBool("hasButtons", self.hasButtons)
	self.minValue = profile:getNumber("minValue", self.minValue)
	self.maxValue = profile:getNumber("maxValue", self.maxValue)
	self.currentValue = profile:getNumber("currentValue", self.currentValue)
	self.stepSize = profile:getNumber("stepSize", self.stepSize)
	self.sliderOffset = unpack(GuiUtils.getNormalizedValues(profile:getValue("sliderOffset"), {
		self.outputSize[2]
	}, {
		self.sliderOffset
	}))
	self.sliderSize = GuiUtils.getNormalizedValues(profile:getValue("sliderSize"), self.outputSize, self.sliderSize)

	if applyProfile then
		self:applySliderAspectScale()
	end
end

function SliderElement:copyAttributes(src)
	SliderElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	GuiOverlay.copyOverlay(self.sliderOverlay, src.sliderOverlay)

	self.direction = src.direction
	self.hasButtons = src.hasButtons
	self.minValue = src.minValue
	self.maxValue = src.maxValue
	self.currentValue = src.currentValue
	self.stepSize = src.stepSize
	self.sliderOffset = src.sliderOffset
	self.sliderSize = ListUtil.copyTable(src.sliderSize)
	self.dataElementId = src.dataElementId
	self.dataElementName = src.dataElementName
	self.textElementId = src.textElementId
	self.onClickCallback = src.onClickCallback
	self.onChangedCallback = src.onChangedCallback

	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function SliderElement:applySliderAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.sliderSize[1] = self.sliderSize[1] * xScale
	self.sliderOffset = self.sliderOffset * yScale
	self.sliderSize[2] = self.sliderSize[2] * yScale
end

function SliderElement:applyScreenAlignment()
	self:applySliderAspectScale()
	SliderElement:superClass().applyScreenAlignment(self)
end

function SliderElement:setSliderVisible(visible)
	self.isSliderVisible = visible
end

function SliderElement:onGuiSetupFinished()
	SliderElement:superClass().onGuiSetupFinished(self)

	if self.textElementId ~= nil then
		if self.target[self.textElementId] ~= nil then
			self.textElement = self.target[self.textElementId]
		else
			print("Warning: TextElementId '" .. self.textElementId .. "' not found for '" .. self.target.name .. "'!")
		end
	end

	if self.dataElementId ~= nil then
		if self.target[self.dataElementId] ~= nil then
			local dataElement = self.target[self.dataElementId]

			self:setDataElement(dataElement)
		else
			print("Warning: DataElementId '" .. self.dataElementId .. "' not found for '" .. self.target.name .. "'!")
		end
	elseif self.dataElementName ~= nil and self.parent then
		local function findDataElement(element)
			return element.name and element.name == self.dataElementName
		end

		local dataElement = self.parent:getFirstDescendant(findDataElement)

		if dataElement then
			self:setDataElement(dataElement)
		else
			print("Warning: DataElementName '" .. self.dataElementName .. "' not found as descendant of '" .. tostring(self.parent) .. "'!")
		end
	end
end

function SliderElement:addElement(element)
	SliderElement:superClass().addElement(self, element)

	if self.hasButtons then
		if table.getn(self.elements) == 1 then
			self.upButtonElement = element
			element.target = self
			element.onClickCallback = SliderElement.onScrollUp

			if self.direction == SliderElement.DIRECTION_Y then
				element.onClickCallback = SliderElement.onScrollDown
			end

			self:setDisabled(self.disabled)
		elseif table.getn(self.elements) == 2 then
			self.downButtonElement = element
			element.target = self
			element.onClickCallback = SliderElement.onScrollDown

			if self.direction == SliderElement.DIRECTION_Y then
				element.onClickCallback = SliderElement.onScrollUp
			end

			self:setDisabled(self.disabled)
		end
	end
end

function SliderElement:setDataElement(element, doNotUpdate)
	if self.dataElement ~= nil then
		self.dataElement.sliderElement = nil
		self.dataElement = nil
	end

	if element ~= nil then
		element.sliderElement = self
		self.dataElement = element

		if doNotUpdate == nil or doNotUpdate then
			self:onListUpdate(element, false)
		end
	end
end

function SliderElement:setValue(newValue, doNotUpdateDataElement)
	self.sliderValue = math.min(math.max(newValue, self.minValue), self.maxValue)

	self:updateSliderPosition()

	local rem = (newValue - self.minValue) % self.stepSize

	if rem >= self.stepSize - rem then
		newValue = newValue + self.stepSize - rem
	else
		newValue = newValue - rem
	end

	newValue = math.min(math.max(newValue, self.minValue), self.maxValue)
	local numDecimalPlaces = 5
	local mult = 10^numDecimalPlaces
	newValue = math.floor(newValue * mult + 0.5) / mult

	if newValue ~= self.currentValue then
		self.currentValue = newValue

		if self.textElement ~= nil then
			self.textElement:setText(self.currentValue)
		end

		self:callOnChanged()

		for _, element in pairs(self.elements) do
			if element.onSliderValueChanged ~= nil then
				element:onSliderValueChanged(self, newValue)
			end
		end

		if self.dataElement ~= nil and (doNotUpdateDataElement == nil or not doNotUpdateDataElement) then
			self.dataElement:onSliderValueChanged(self, newValue)
		end

		self:updateSliderButtons()

		return true
	end

	return false
end

function SliderElement:updateSliderButtons()
	if self.upButtonElement ~= nil then
		self.upButtonElement:setDisabled(self.disabled or self.currentValue == self.maxValue)
	end

	if self.downButtonElement ~= nil then
		self.downButtonElement:setDisabled(self.disabled or self.currentValue == self.minValue)
	end
end

function SliderElement:setMinValue(minValue)
	self.minValue = math.max(minValue, 1)

	if self.currentValue < self.minValue then
		self:setValue(self.minValue)
	end

	self:updateSliderPosition()
end

function SliderElement:setMaxValue(maxValue)
	self.maxValue = math.max(maxValue, 1)

	if self.maxValue < self.currentValue then
		self:setValue(self.maxValue)
	end

	self:updateSliderPosition()
end

function SliderElement:getMinValue()
	return self.minValue
end

function SliderElement:getMaxValue()
	return self.maxValue
end

function SliderElement:getValue()
	return self.currentValue
end

function SliderElement:updateAbsolutePosition()
	SliderElement:superClass().updateAbsolutePosition(self)
	self:updateSliderLimits()
end

function SliderElement:setSize(x, y)
	SliderElement:superClass().setSize(self, x, y)
	self:updateSliderLimits()
end

function SliderElement:updateSliderLimits()
	local axis = 1

	if self.direction == SliderElement.DIRECTION_Y then
		axis = 2
	end

	self.minAbsSliderPos = self.absPosition[axis]
	self.maxAbsSliderPos = self.absPosition[axis] + self.size[axis] - self.sliderSize[axis]

	self:updateSliderPosition()
end

function SliderElement:setAlpha(alpha)
	SliderElement:superClass().setAlpha(self, alpha)

	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end

	if self.sliderOverlay ~= nil then
		self.sliderOverlay.alpha = self.alpha
	end
end

function SliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if SliderElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if self.mouseDown and isUp and button == Input.MOUSE_BUTTON_LEFT then
			eventUsed = true
			self.clickedOnSlider = false
			self.mouseDown = false

			self:raiseCallback("onClickCallback", self.currentValue)
		end

		if not eventUsed and (GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) or GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2])) then
			eventUsed = true

			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
				self:setValue(self.currentValue - self.stepSize)
			end

			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
				self:setValue(self.currentValue + self.stepSize)
			end

			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				if not self.mouseDown and GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2]) then
					self.clickedOnSlider = true
					self.lastMousePosX = posX
					self.lastMousePosY = posY
					self.lastSliderPosX = self.sliderPosition[1]
					self.lastSliderPosY = self.sliderPosition[2]
				end

				self.mouseDown = true
			end
		end

		if self.mouseDown then
			eventUsed = true
			local newValue = 0
			local mousePos = posX

			if self.direction == SliderElement.DIRECTION_Y then
				mousePos = posY

				if self.clickedOnSlider then
					local deltaY = posY - self.lastMousePosY
					mousePos = self.lastSliderPosY + deltaY
					newValue = self.minValue + (1 - (mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos)) * (self.maxValue - self.minValue)
				else
					if mousePos > self.sliderPosition[2] + self.sliderSize[2] then
						mousePos = mousePos - self.sliderSize[2]
					end

					newValue = self.minValue + (1 - (mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos)) * (self.maxValue - self.minValue)
				end
			else
				if self.clickedOnSlider then
					local deltaX = posX - self.lastMousePosX
					mousePos = self.lastSliderPosX + deltaX
					newValue = self.minValue + (mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos) * (self.maxValue - self.minValue)
				elseif mousePos > self.sliderPosition[1] + self.sliderSize[1] then
					mousePos = mousePos - self.sliderSize[1]
				end

				newValue = self.minValue + (mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos) * (self.maxValue - self.minValue)
			end

			self:setValue(newValue)
		end
	end

	return eventUsed
end

function SliderElement:updateSliderPosition()
	local state = (self.sliderValue - self.minValue) / (self.maxValue - self.minValue)

	if self.direction == SliderElement.DIRECTION_Y then
		self.sliderPosition[1] = self.absPosition[1] + self.sliderOffset
		self.sliderPosition[2] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, 1 - state)
	else
		self.sliderPosition[1] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, state)
		self.sliderPosition[2] = self.absPosition[2] + self.sliderOffset
	end

	self:updateSliderButtons()
end

function SliderElement:callOnChanged()
	self:raiseCallback("onChangedCallback", self.currentValue)
end

function SliderElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if self:getIsActive() and SliderElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
		return true
	end

	return false
end

function SliderElement:draw()
	local state = GuiOverlay.STATE_NORMAL

	if self.disabled then
		state = GuiOverlay.STATE_DISABLED
	end

	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], state)

	if self.isSliderVisible and self.needsSlider then
		GuiOverlay.renderOverlay(self.sliderOverlay, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2], state)
	end

	SliderElement:superClass().draw(self)
end

function SliderElement:shouldFocusChange(direction)
	local dir1 = FocusManager.LEFT
	local dir2 = FocusManager.RIGHT

	if self.direction == SliderElement.DIRECTION_Y then
		dir1 = FocusManager.TOP
		dir2 = FocusManager.BOTTOM
	end

	if direction == dir1 then
		if self.currentValue <= self.minValue then
			return true
		else
			self:setValue(self.currentValue - self.stepSize)
			self:raiseCallback("onClickCallback", self.currentValue)

			return false
		end
	elseif direction == dir2 then
		if self.maxValue <= self.currentValue then
			return true
		else
			self:setValue(self.currentValue + self.stepSize)
			self:raiseCallback("onClickCallback", self.currentValue)

			return false
		end
	end

	return true
end

function SliderElement:canReceiveFocus()
	return self.handleFocus
end

function SliderElement:onFocusLeave()
end

function SliderElement:onFocusEnter()
end

function SliderElement:onFocusActivate()
	self:raiseCallback("onClickCallback", self.currentValue)
end

function SliderElement:onScrollUp()
	self:setValue(self.currentValue + self.stepSize)
end

function SliderElement:onScrollDown()
	self:setValue(self.currentValue - self.stepSize)
end

function SliderElement:setSliderSize(visibleItems, maxItems)
	if self.adjustSliderSize then
		local axis = 1

		if self.direction == SliderElement.DIRECTION_Y then
			axis = 2
		end

		self.sliderSize[axis] = self.size[axis] * visibleItems / maxItems

		self:updateSliderLimits()
	end
end

function SliderElement:onListUpdate(list)
	local numItems = list:getItemCount()
	local numVisibleItems = list:getVisibleItemCount()

	self:setMinValue(1)
	self:setMaxValue(math.ceil(numItems - numVisibleItems) / list:getItemFactor() + 1)
	self:setSliderSize(numVisibleItems, numItems)
	self:setValue(math.max(list.firstVisibleItem, 1), true)

	self.needsSlider = numVisibleItems < numItems
end
