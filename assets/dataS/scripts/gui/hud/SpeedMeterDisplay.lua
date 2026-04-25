SpeedMeterDisplay = {}
local SpeedMeterDisplay_mt = Class(SpeedMeterDisplay, HUDDisplayElement)

function SpeedMeterDisplay.new(hudAtlasPath)
	local backgroundOverlay = SpeedMeterDisplay.createBackground(hudAtlasPath)
	local self = SpeedMeterDisplay:superClass().new(SpeedMeterDisplay_mt, backgroundOverlay, nil)
	self.uiScale = 1
	self.vehicle = nil
	self.isVehicleDrawSafe = false
	self.speedIndicatorElement = nil
	self.speedGaugeSegmentElements = nil
	self.speedGaugeSegmentPartElements = nil
	self.speedIndicatorRadiusX = 0
	self.speedIndicatorRadiusY = 0
	self.speedTextOffsetY = 0
	self.speedUnitTextOffsetY = 0
	self.speedTextSize = 0
	self.speedUnitTextSize = 0
	self.speedKmh = 0
	self.damageGaugeBackgroundElement = nil
	self.damageIndicatorElement = nil
	self.damageGaugeSegmentPartElements = nil
	self.damageGaugeIconElement = nil
	self.damageIndicatorRadiusX = 0
	self.damageIndicatorRadiusY = 0
	self.damageGaugeRadiusX = 0
	self.damageGaugeRadiusY = 0
	self.damageGaugeActive = false
	self.fuelGaugeBackgroundElement = nil
	self.fuelIndicatorElement = nil
	self.fuelGaugeSegmentPartElements = nil
	self.fuelGaugeIconElement = nil
	self.fuelIndicatorRadiusX = 0
	self.fuelIndicatorRadiusY = 0
	self.fuelGaugeRadiusX = 0
	self.fuelGaugeRadiusY = 0
	self.fuelGaugeActive = false
	self.cruiseControlElement = nil
	self.cruiseControlSpeed = 0
	self.cruiseControlColor = nil
	self.cruiseControlTextOffsetX = 0
	self.cruiseControlTextOffsetY = 0
	self.operatingTimeElement = nil
	self.operatingTimeText = ""
	self.operatingTimeTextSize = 1
	self.operatingTimeTextOffsetX = 0
	self.operatingTimeTextOffsetY = 0
	self.operatingTimeTextDrawPositionX = 0
	self.operatingTimeTextDrawPositionY = 0
	self.fadeFuelGaugeAnimation = TweenSequence.NO_SEQUENCE
	self.fadeDamageGaugeAnimation = TweenSequence.NO_SEQUENCE

	self:createComponents(hudAtlasPath)

	return self
end

local _ = nil
local HALF_PI = math.pi * 0.5

function SpeedMeterDisplay:getBasePosition()
	local offX, offY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GAUGE_BACKGROUND))
	local selfX, selfY = self:getPosition()

	return selfX + offX, selfY + offY
end

function SpeedMeterDisplay:createComponents(hudAtlasPath)
	local baseX, baseY = self:getBasePosition()

	self:storeScaledValues(baseX, baseY)

	self.speedGaugeSegmentElements, self.speedGaugeSegmentPartElements = self:createSpeedGaugeElements(hudAtlasPath, baseX, baseY)
	self.damageGaugeSegmentPartElements = self:createDamageGaugeElements(hudAtlasPath, baseX, baseY)
	self.fuelGaugeSegmentPartElements = self:createFuelGaugeElements(hudAtlasPath, baseX, baseY)
	self.gaugeBackgroundElement = self:createGaugeBackground(hudAtlasPath, baseX, baseY)
	self.damageGaugeBackgroundElement = self:createSideGaugeBackground(hudAtlasPath, baseX, baseY, false)
	self.fuelGaugeBackgroundElement = self:createSideGaugeBackground(hudAtlasPath, baseX, baseY, true)
	self.damageGaugeIconElement, self.fuelGaugeIconElement = self:createGaugeIconElements(hudAtlasPath, baseX, baseY)
	self.speedIndicatorElement = self:createSpeedGaugeIndicator(hudAtlasPath, baseX, baseY)
	self.damageIndicatorElement = self:createDamageGaugeIndicator(hudAtlasPath, baseX, baseY)
	self.fuelIndicatorElement = self:createFuelGaugeIndicator(hudAtlasPath, baseX, baseY)
	self.operatingTimeElement = self:createOperatingTimeElement(hudAtlasPath, baseX, baseY)

	self.operatingTimeElement:setVisible(false)

	self.cruiseControlElement = self:createCruiseControlElement(hudAtlasPath, baseX, baseY)

	self:createHorizontalSeparator(hudAtlasPath, baseX, baseY)
end

function SpeedMeterDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	local hasVehicle = vehicle ~= nil

	self.cruiseControlElement:setVisible(hasVehicle)

	local isMotorized = hasVehicle and vehicle.spec_motorized ~= nil
	local needFuelGauge = true

	if hasVehicle and isMotorized then
		local _, capacity = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
		needFuelGauge = capacity ~= nil
	end

	self.fuelGaugeActive = needFuelGauge

	self:animateFuelGaugeToggle(needFuelGauge)

	local needDamageGauge = hasVehicle and vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil
	self.damageGaugeActive = needDamageGauge

	self:animateDamageGaugeToggle(needDamageGauge)

	local hasOperatingTime = hasVehicle and vehicle.operatingTime ~= nil

	self.operatingTimeElement:setVisible(hasOperatingTime)

	self.isVehicleDrawSafe = false
end

function SpeedMeterDisplay:update(dt)
	SpeedMeterDisplay:superClass().update(self, dt)

	if not self.animation:getFinished() then
		local baseX, baseY = self.gaugeBackgroundElement:getPosition()

		self:storeScaledValues(baseX, baseY)
	end

	if self.vehicle ~= nil and self.vehicle.spec_motorized ~= nil then
		self:updateSpeedGauge(dt)
		self:updateDamageGauge(dt)
		self:updateFuelGauge(dt)
		self:updateCruiseControl(dt)
		self:updateOperatingTime(dt)
	end

	self.isVehicleDrawSafe = true
end

function SpeedMeterDisplay:updateOperatingTime(dt)
	if self.operatingTimeElement:getVisible() then
		local minutes = self.vehicle.operatingTime / 60000
		local hours = math.floor(minutes / 60)
		minutes = math.floor((minutes - hours * 60) / 6)
		self.operatingTimeText = string.format(g_i18n:getText("shop_operatingTime"), hours, minutes)
		local textWidth = getTextWidth(self.operatingTimeTextSize, self.operatingTimeText)
		local operatingTimeWidth = self.operatingTimeElement:getWidth() + self.operatingTimeTextOffsetX + textWidth
		local posX, _ = self:getPosition()
		local _, posY = self.operatingTimeElement:getPosition()
		posX = posX + (self:getWidth() - operatingTimeWidth) * 0.5
		self.operatingTimeTextDrawPositionX = posX + self.operatingTimeElement:getWidth() + self.operatingTimeTextOffsetX
		self.operatingTimeTextDrawPositionY = posY + self.operatingTimeTextOffsetY

		self.operatingTimeElement:setPosition(posX, nil)

		self.operatingTimeIsSafe = true
	end
end

function SpeedMeterDisplay:updateCruiseControl(dt)
	local cruiseControl = self.vehicle.spec_drivable.cruiseControl
	self.cruiseControlSpeed = cruiseControl.speed
	self.cruiseControlColor = SpeedMeterDisplay.COLOR.CRUISE_CONTROL_ON

	if cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
		self.cruiseControlSpeed = cruiseControl.maxSpeed
	elseif cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
		self.cruiseControlColor = SpeedMeterDisplay.COLOR.CRUISE_CONTROL_OFF
	end

	self.cruiseControlElement:setColor(unpack(self.cruiseControlColor))
end

function SpeedMeterDisplay:updateGaugeIndicator(indicatorElement, radiusX, radiusY, rotation)
	local pivotX, pivotY = indicatorElement:getRotationPivot()
	local cosRot = math.cos(rotation)
	local sinRot = math.sin(rotation)
	local posX = self.gaugeCenterX + cosRot * radiusX - pivotX
	local posY = self.gaugeCenterY + sinRot * radiusY - pivotY

	indicatorElement:setPosition(posX, posY)
	indicatorElement:setRotation(rotation - HALF_PI)
end

function SpeedMeterDisplay:updateGaugeFillSegments(fillSegments, gaugeValue)
	local fullSegmentCount = math.floor(gaugeValue * #fillSegments)

	for i, element in ipairs(fillSegments) do
		element:setVisible(i <= fullSegmentCount)
	end
end

local function round(x)
	return x + 0.5 - (x + 0.5) % 1
end

function SpeedMeterDisplay:updateGaugePartialSegments(partialSegments, indicatorRotation, rotationDirection, gaugeRadiusX, gaugeRadiusY, gaugeMinAngle, fullSegmentAngle, detailSegmentAngle, isPartialOnly)
	local angle = math.abs(indicatorRotation - gaugeMinAngle)
	local fullParts, rem = math.modf(angle / fullSegmentAngle)

	if isPartialOnly and fullParts > 0 then
		fullParts = 0
		rem = 1
	end

	local largestPartSegmentSize = round(rem * #partialSegments)
	local partialRotation = gaugeMinAngle - fullParts * fullSegmentAngle * rotationDirection

	if rotationDirection < 0 then
		partialRotation = partialRotation + largestPartSegmentSize * detailSegmentAngle
	end

	local cosRot = math.cos(partialRotation)
	local sinRot = math.sin(partialRotation)
	local posX = self.gaugeCenterX + cosRot * gaugeRadiusX
	local posY = self.gaugeCenterY + sinRot * gaugeRadiusY

	for i, element in ipairs(partialSegments) do
		if i == largestPartSegmentSize then
			element:setRotation(partialRotation - HALF_PI)
			element:setPosition(posX, posY)
			element:setVisible(true)
		else
			element:setVisible(false)
		end
	end
end

function SpeedMeterDisplay:updateSpeedGauge(dt)
	local kmh = math.max(0, self.vehicle:getLastSpeed() * self.vehicle.spec_motorized.speedDisplayScale)

	if kmh < 0.5 then
		kmh = 0
	end

	self.speedKmh = kmh
	local gaugeValue = MathUtil.clamp(kmh / (self.vehicle.spec_drivable.cruiseControl.maxSpeed * 1.1), 0, 1)
	local indicatorRotation = MathUtil.lerp(SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MAX, gaugeValue)

	self:updateGaugeIndicator(self.speedIndicatorElement, self.speedIndicatorRadiusX, self.speedIndicatorRadiusY, indicatorRotation)
	self:updateGaugeFillSegments(self.speedGaugeSegmentElements, gaugeValue)
	self:updateGaugePartialSegments(self.speedGaugeSegmentPartElements, indicatorRotation, 1, self.speedGaugeRadiusX, self.speedGaugeRadiusY, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_SEGMENT_SMALLEST)
end

function SpeedMeterDisplay:updateDamageGauge(dt)
	if not self.fadeDamageGaugeAnimation:getFinished() then
		self.fadeDamageGaugeAnimation:update(dt)
	end

	if self.damageGaugeActive then
		local steps = #self.damageGaugeSegmentPartElements
		local gaugeValue = 1 - self.vehicle:getWearTotalAmount()
		gaugeValue = round(gaugeValue * steps) / steps
		local indicatorRotation = MathUtil.lerp(SpeedMeterDisplay.ANGLE.DAMAGE_GAUGE_MIN, SpeedMeterDisplay.ANGLE.DAMAGE_GAUGE_MAX, gaugeValue)

		self:updateGaugeIndicator(self.damageIndicatorElement, self.damageIndicatorRadiusX, self.damageIndicatorRadiusY, indicatorRotation)

		local neededColor = SpeedMeterDisplay.COLOR.DAMAGE_GAUGE

		if gaugeValue < 0.2 then
			neededColor = SpeedMeterDisplay.COLOR.DAMAGE_GAUGE_LOW
		end

		if self.lastDamageGaugeColor ~= neededColor then
			self:setGaugePartialElementsColor(self.damageGaugeSegmentPartElements, neededColor)

			self.lastDamageGaugeColor = neededColor
		end

		self:updateGaugePartialSegments(self.damageGaugeSegmentPartElements, indicatorRotation, 1, self.damageGaugeRadiusX, self.damageGaugeRadiusY, SpeedMeterDisplay.ANGLE.DAMAGE_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SIDE_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.ANGLE.SIDE_GAUGE_SEGMENT_SMALLEST, true)
	end
end

function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
	local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
	local level = vehicle:getFillUnitFillLevel(fuelFillType)
	local capacity = vehicle:getFillUnitCapacity(fuelFillType)

	return level, capacity
end

function SpeedMeterDisplay:updateFuelGauge(dt)
	if not self.fadeFuelGaugeAnimation:getFinished() then
		self.fadeFuelGaugeAnimation:update(dt)
	end

	if self.fuelGaugeActive then
		local level, capacity = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(self.vehicle)
		local gaugeValue = 0

		if capacity ~= nil and capacity > 0 then
			local steps = #self.fuelGaugeSegmentPartElements
			gaugeValue = level / capacity
			gaugeValue = round(gaugeValue * steps) / steps
		end

		local indicatorRotation = MathUtil.lerp(SpeedMeterDisplay.ANGLE.FUEL_GAUGE_MIN, SpeedMeterDisplay.ANGLE.FUEL_GAUGE_MAX, gaugeValue)

		self:updateGaugeIndicator(self.fuelIndicatorElement, self.fuelIndicatorRadiusX, self.fuelIndicatorRadiusY, indicatorRotation)
		self:updateGaugePartialSegments(self.fuelGaugeSegmentPartElements, indicatorRotation, -1, self.fuelGaugeRadiusX, self.fuelGaugeRadiusY, SpeedMeterDisplay.ANGLE.FUEL_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SIDE_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.ANGLE.SIDE_GAUGE_SEGMENT_SMALLEST, true)
	end
end

function SpeedMeterDisplay:onAnimateVisibilityFinished(isVisible)
	SpeedMeterDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)

	local baseX, baseY = self.gaugeBackgroundElement:getPosition()

	self:storeScaledValues(baseX, baseY)
end

function SpeedMeterDisplay:draw()
	SpeedMeterDisplay:superClass().draw(self)

	if self.isVehicleDrawSafe and self:getVisible() then
		self:drawSpeedText()
		self:drawOperatingTimeText()
		self:drawCruiseControlText()
	end
end

function SpeedMeterDisplay:drawOperatingTimeText()
	if self.operatingTimeElement:getVisible() then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		renderText(self.operatingTimeTextDrawPositionX, self.operatingTimeTextDrawPositionY, self.operatingTimeTextSize, self.operatingTimeText)
	end
end

function SpeedMeterDisplay:drawCruiseControlText()
	if self.cruiseControlElement:getVisible() then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(unpack(self.cruiseControlColor))
		setTextBold(true)

		local speedText = string.format(g_i18n:getText("ui_cruiseControlSpeed"), g_i18n:getSpeed(self.cruiseControlSpeed))
		local baseX, baseY = self.cruiseControlElement:getPosition()
		local posX = baseX + self.cruiseControlElement:getWidth() + self.cruiseControlTextOffsetX
		local posY = baseY + self.cruiseControlTextOffsetY

		renderText(posX, posY, self.cruiseControlTextSize, speedText)
	end
end

function SpeedMeterDisplay:drawSpeedText()
	local speed = math.floor(self.speedKmh)

	if math.abs(self.speedKmh - speed) > 0.5 then
		speed = speed + 1
	end

	local speedI18N = string.format("%1d", g_i18n:getSpeed(speed))
	local speedUnit = utf8ToUpper(g_i18n:getSpeedMeasuringUnit())
	local posX, posY = self.gaugeBackgroundElement:getPosition()
	posX = posX + self.gaugeBackgroundElement:getWidth() * 0.5

	setTextColor(unpack(SpeedMeterDisplay.COLOR.SPEED_TEXT))
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(posX, posY + self.speedTextOffsetY, self.speedTextSize, speedI18N)
	setTextColor(unpack(SpeedMeterDisplay.COLOR.SPEED_UNIT))
	renderText(posX, posY + self.speedUnitTextOffsetY, self.speedUnitTextSize, speedUnit)
end

function SpeedMeterDisplay:fadeFuelGauge(alpha)
	self.fuelIndicatorElement:setAlpha(alpha)
	self.fuelGaugeBackgroundElement:setAlpha(alpha)
	self.fuelGaugeIconElement:setAlpha(alpha)

	local baseAlpha = SpeedMeterDisplay.COLOR.FUEL_GAUGE[4]

	for _, element in pairs(self.fuelGaugeSegmentPartElements) do
		if element:getVisible() then
			element:setAlpha(alpha * baseAlpha)
		end
	end

	local visible = alpha > 0

	if visible ~= self.fuelGaugeBackgroundElement:getVisible() then
		self.fuelIndicatorElement:setVisible(visible)
		self.fuelGaugeBackgroundElement:setVisible(visible)
		self.fuelGaugeIconElement:setVisible(visible)
	end
end

function SpeedMeterDisplay:animateFuelGaugeToggle(makeActive)
	local startAlpha = self.fuelGaugeBackgroundElement:getAlpha()
	local endAlpha = makeActive and 1 or 0

	if self.fadeFuelGaugeAnimation:getFinished() then
		local sequence = TweenSequence.new(self)
		local fade = Tween:new(self.fadeFuelGauge, startAlpha, endAlpha, HUDDisplayElement.MOVE_ANIMATION_DURATION)

		sequence:addTween(fade)
		sequence:start()

		self.fadeFuelGaugeAnimation = sequence
	else
		self.fadeFuelGaugeAnimation:stop()
		self:fadeFuelGauge(endAlpha)
	end
end

function SpeedMeterDisplay:fadeDamageGauge(alpha)
	self.damageIndicatorElement:setAlpha(alpha)
	self.damageGaugeBackgroundElement:setAlpha(alpha)
	self.damageGaugeIconElement:setAlpha(alpha)

	local baseAlpha = SpeedMeterDisplay.COLOR.DAMAGE_GAUGE[4]

	for _, element in pairs(self.damageGaugeSegmentPartElements) do
		if element:getVisible() then
			element:setAlpha(alpha * baseAlpha)
		end
	end

	local visible = alpha > 0

	if visible ~= self.damageGaugeBackgroundElement:getVisible() then
		self.damageIndicatorElement:setVisible(visible)
		self.damageGaugeBackgroundElement:setVisible(visible)
		self.damageGaugeIconElement:setVisible(visible)
	end
end

function SpeedMeterDisplay:animateDamageGaugeToggle(makeActive)
	local startAlpha = self.damageGaugeBackgroundElement:getAlpha()
	local endAlpha = makeActive and 1 or 0

	if self.fadeDamageGaugeAnimation:getFinished() then
		local sequence = TweenSequence.new(self)
		local fade = Tween:new(self.fadeDamageGauge, startAlpha, endAlpha, HUDDisplayElement.MOVE_ANIMATION_DURATION)

		sequence:addTween(fade)
		sequence:start()

		self.fadeDamageGaugeAnimation = sequence
	else
		self.fadeDamageGaugeAnimation:stop()
		self:fadeDamageGauge(endAlpha)
	end
end

function SpeedMeterDisplay:setScale(uiScale)
	SpeedMeterDisplay:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale
	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	local posX, posY = SpeedMeterDisplay.getBackgroundPosition(uiScale)

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)

	local baseX, baseY = self.gaugeBackgroundElement:getPosition()

	self:storeScaledValues(baseX, baseY)
end

function SpeedMeterDisplay:storeGaugeCenterPosition(baseX, baseY)
	local sizeRatioX = SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND[1] / SpeedMeterDisplay.UV.GAUGE_BACKGROUND[3]
	local sizeRatioY = SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND[2] / SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4]
	local centerOffsetX = SpeedMeterDisplay.POSITION.GAUGE_CENTER[1] * sizeRatioX
	local centerOffsetY = SpeedMeterDisplay.POSITION.GAUGE_CENTER[2] * sizeRatioY
	local normOffsetX, normOffsetY = getNormalizedScreenValues(centerOffsetX, centerOffsetY)
	self.gaugeCenterY = baseY + normOffsetY * self.uiScale
	self.gaugeCenterX = baseX + normOffsetX * self.uiScale
end

function SpeedMeterDisplay:storeScaledValues(baseX, baseY)
	self:storeGaugeCenterPosition(baseX, baseY)

	self.cruiseControlTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.CRUISE_CONTROL)
	self.cruiseControlTextOffsetX, self.cruiseControlTextOffsetY = self:scalePixelToScreenVector(SpeedMeterDisplay.POSITION.CRUISE_CONTROL_TEXT)
	self.operatingTimeTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.OPERATING_TIME)
	self.operatingTimeTextOffsetX, self.operatingTimeTextOffsetY = self:scalePixelToScreenVector(SpeedMeterDisplay.POSITION.OPERATING_TIME_TEXT)
	self.speedTextOffsetY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.SPEED_TEXT[2])
	self.speedUnitTextOffsetY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.SPEED_UNIT[2])
	self.speedTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.SPEED)
	self.speedUnitTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.SPEED_UNIT)
	self.speedIndicatorRadiusX, self.speedIndicatorRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_LARGE_RADIUS)
	self.speedGaugeRadiusX, self.speedGaugeRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.SPEED_GAUGE_RADIUS)
	self.damageIndicatorRadiusX, self.damageIndicatorRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_SMALL_RADIUS)
	self.damageGaugeRadiusX, self.damageGaugeRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.SIDE_GAUGE_RADIUS)
	self.fuelIndicatorRadiusX, self.fuelIndicatorRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_SMALL_RADIUS)
	self.fuelGaugeRadiusX, self.fuelGaugeRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.SIDE_GAUGE_RADIUS)
end

function SpeedMeterDisplay.getBackgroundPosition(scale)
	local gaugeWidth, gaugeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND))
	local bgWidth, bgHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.SHADOW_BACKGROUND))
	local selfOffX, selfOffY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.SPEED_METER))
	local offX = (selfOffX + (bgWidth - gaugeWidth) * 0.5) * scale
	local offY = (selfOffY + (bgHeight - gaugeHeight) * 0.5) * scale

	return 1 - g_safeFrameOffsetX - gaugeWidth * scale - offX, g_safeFrameOffsetY - offY
end

function SpeedMeterDisplay.createBackground(hudAtlasPath)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.SHADOW_BACKGROUND))
	local posX, posY = SpeedMeterDisplay.getBackgroundPosition(1)
	local background = Overlay:new(hudAtlasPath, posX, posY, width, height)

	background:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.SHADOW_BACKGROUND))
	background:setColor(unpack(SpeedMeterDisplay.COLOR.SHADOW_BACKGROUND))

	return background
end

function SpeedMeterDisplay:createGaugeBackground(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND))
	local gaugeBackgroundOverlay = Overlay:new(hudAtlasPath, baseX, baseY, width, height)

	gaugeBackgroundOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GAUGE_BACKGROUND))

	local element = HUDElement:new(gaugeBackgroundOverlay)

	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createSideGaugeBackground(hudAtlasPath, baseX, baseY, isRight)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.SIDE_GAUGE_BACKGROUND))
	local position = isRight and SpeedMeterDisplay.POSITION.GAUGE_BACKGROUND_RIGHT or SpeedMeterDisplay.POSITION.GAUGE_BACKGROUND_LEFT
	local offX, offY = getNormalizedScreenValues(unpack(position))
	local sideGaugeOverlay = Overlay:new(hudAtlasPath, baseX + offX, baseY + offY, width, height)

	sideGaugeOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.SIDE_GAUGE_BACKGROUND))
	sideGaugeOverlay:setInvertX(isRight)

	local element = HUDElement:new(sideGaugeOverlay)

	element:setVisible(false)
	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createGaugeIconElements(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.DAMAGE_LEVEL_ICON))
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.DAMAGE_LEVEL_ICON))
	local iconOverlay = Overlay:new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	iconOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.DAMAGE_LEVEL_ICON))

	local damageGaugeIconElement = HUDElement:new(iconOverlay)

	self:addChild(damageGaugeIconElement)

	posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.FUEL_LEVEL_ICON))
	width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
	iconOverlay = Overlay:new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	iconOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.FUEL_LEVEL_ICON))

	local fuelGaugeIconElement = HUDElement:new(iconOverlay)

	self:addChild(fuelGaugeIconElement)

	return damageGaugeIconElement, fuelGaugeIconElement
end

function SpeedMeterDisplay:createHorizontalSeparator(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.SEPARATOR))
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.SEPARATOR))
	local separatorOverlay = Overlay:new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	separatorOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.SEPARATOR))
	separatorOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)
	separatorOverlay:setColor(unpack(SpeedMeterDisplay.COLOR.SEPARATOR))
	self:addChild(HUDElement:new(separatorOverlay))
end

function SpeedMeterDisplay:createCruiseControlElement(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.CRUISE_CONTROL))
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.CRUISE_CONTROL))
	local cruiseControlOverlay = Overlay:new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	cruiseControlOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.CRUISE_CONTROL))

	local element = HUDElement:new(cruiseControlOverlay)

	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createOperatingTimeElement(hudAtlasPath, baseX, baseY)
	local operatingTimeWidth, operatingTimeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.OPERATING_TIME))
	local operatingTimeOffsetX, operatingTimeOffsetY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.OPERATING_TIME))
	local operatingTimeOverlay = Overlay:new(hudAtlasPath, baseX + operatingTimeOffsetX, baseY + operatingTimeOffsetY, operatingTimeWidth, operatingTimeHeight)

	operatingTimeOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.OPERATING_TIME))

	local element = HUDElement:new(operatingTimeOverlay)

	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createIndicator(hudAtlasPath, size, uvs, color, pivot)
	local width, height = getNormalizedScreenValues(unpack(size))
	local indicatorOverlay = Overlay:new(hudAtlasPath, 0, 0, width, height)

	indicatorOverlay:setUVs(GuiUtils.getUVs(uvs))
	indicatorOverlay:setColor(unpack(color))

	local indicatorElement = HUDElement:new(indicatorOverlay)
	local pivotX, pivotY = self:normalizeUVPivot(pivot, size, uvs)

	indicatorElement:setRotationPivot(pivotX, pivotY)
	self:addChild(indicatorElement)

	return indicatorElement
end

function SpeedMeterDisplay:createGaugeFillElements(hudAtlasPath, baseX, baseY, gaugeStartAngle, gaugeEndAngle, fillSegmentAngle, radius, segmentSize, segmentPivot, segmentUVs, segmentColor)
	local fullSegmentElements = {}
	local radiusX, radiusY = getNormalizedScreenValues(unpack(radius))
	local width, height = getNormalizedScreenValues(unpack(segmentSize))
	local pivotX, pivotY = self:normalizeUVPivot(segmentPivot, segmentSize, segmentUVs)
	local numFillSegmentsInGauge = round(math.abs(gaugeEndAngle - gaugeStartAngle) / fillSegmentAngle)

	for i = 1, numFillSegmentsInGauge do
		local rotation = gaugeStartAngle - fillSegmentAngle * (i - 1)
		local posX = self.gaugeCenterX + math.cos(rotation) * radiusX
		local posY = self.gaugeCenterY + math.sin(rotation) * radiusY
		local segmentOverlay = Overlay:new(hudAtlasPath, posX, posY, width, height)

		segmentOverlay:setUVs(GuiUtils.getUVs(segmentUVs))
		segmentOverlay:setColor(unpack(segmentColor))
		segmentOverlay:setRotation(rotation - HALF_PI, pivotX, pivotY)

		local segmentElement = HUDElement:new(segmentOverlay)

		segmentElement:setVisible(false)
		segmentElement:setRotationPivot(pivotX, pivotY)
		table.insert(fullSegmentElements, segmentElement)
		self:addChild(segmentElement)
	end

	return fullSegmentElements
end

function SpeedMeterDisplay:createGaugePartialElements(hudAtlasPath, baseX, baseY, fullSegmentSize, segmentPivot, segmentColor, gaugeSegmentUVs)
	local width, height = getNormalizedScreenValues(unpack(fullSegmentSize))
	local partialSegmentElements = {}

	for i = 1, #gaugeSegmentUVs do
		local segmentOverlay = Overlay:new(hudAtlasPath, 0, 0, width, height)

		segmentOverlay:setUVs(GuiUtils.getUVs(gaugeSegmentUVs[i]))
		segmentOverlay:setColor(unpack(segmentColor))

		local segmentElement = HUDElement:new(segmentOverlay)

		segmentElement:setVisible(false)

		local pivotX, pivotY = self:normalizeUVPivot(segmentPivot, fullSegmentSize, gaugeSegmentUVs[i])

		segmentElement:setRotationPivot(pivotX, pivotY)
		table.insert(partialSegmentElements, segmentElement)
		self:addChild(segmentElement)
	end

	return partialSegmentElements
end

function SpeedMeterDisplay:setGaugePartialElementsColor(elements, color)
	for _, element in ipairs(elements) do
		element:setColor(unpack(color))
	end
end

function SpeedMeterDisplay:createSpeedGaugeIndicator(hudAtlasPath, baseX, baseY)
	return self:createIndicator(hudAtlasPath, SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_LARGE, SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE, SpeedMeterDisplay.COLOR.SPEED_GAUGE_INDICATOR, SpeedMeterDisplay.PIVOT.GAUGE_INDICATOR_LARGE)
end

function SpeedMeterDisplay:createSpeedGaugeElements(hudAtlasPath, baseX, baseY)
	local fullSegmentElements = self:createGaugeFillElements(hudAtlasPath, baseX, baseY, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MAX, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.SIZE.SPEED_GAUGE_RADIUS, SpeedMeterDisplay.SIZE.SPEED_GAUGE_SEGMENT, SpeedMeterDisplay.PIVOT.SPEED_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.UV.SPEED_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.COLOR.SPEED_GAUGE)
	local partialSegmentElements = self:createGaugePartialElements(hudAtlasPath, baseX, baseY, SpeedMeterDisplay.SIZE.SPEED_GAUGE_SEGMENT, SpeedMeterDisplay.PIVOT.SPEED_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.COLOR.SPEED_GAUGE, SpeedMeterDisplay.UV.GAUGE_SEGMENT)

	return fullSegmentElements, partialSegmentElements
end

function SpeedMeterDisplay:createDamageGaugeIndicator(hudAtlasPath, baseX, baseY)
	return self:createIndicator(hudAtlasPath, SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_SMALL, SpeedMeterDisplay.UV.GAUGE_INDICATOR_SMALL, SpeedMeterDisplay.COLOR.DAMAGE_GAUGE_INDICATOR, SpeedMeterDisplay.PIVOT.GAUGE_INDICATOR_SMALL)
end

function SpeedMeterDisplay:createDamageGaugeElements(hudAtlasPath, baseX, baseY)
	return self:createGaugePartialElements(hudAtlasPath, baseX, baseY, SpeedMeterDisplay.SIZE.SIDE_GAUGE_SEGMENT, SpeedMeterDisplay.PIVOT.SIDE_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.COLOR.DAMAGE_GAUGE, SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT)
end

function SpeedMeterDisplay:createFuelGaugeIndicator(hudAtlasPath, baseX, baseY)
	return self:createIndicator(hudAtlasPath, SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_SMALL, SpeedMeterDisplay.UV.GAUGE_INDICATOR_SMALL, SpeedMeterDisplay.COLOR.FUEL_GAUGE_INDICATOR, SpeedMeterDisplay.PIVOT.GAUGE_INDICATOR_SMALL)
end

function SpeedMeterDisplay:createFuelGaugeElements(hudAtlasPath, baseX, baseY)
	return self:createGaugePartialElements(hudAtlasPath, baseX, baseY, SpeedMeterDisplay.SIZE.SIDE_GAUGE_SEGMENT, SpeedMeterDisplay.PIVOT.SIDE_GAUGE_SEGMENT_FULL, SpeedMeterDisplay.COLOR.FUEL_GAUGE, SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT)
end

SpeedMeterDisplay.UV = {
	SHADOW_BACKGROUND = {
		0,
		672,
		336,
		336
	},
	GAUGE_BACKGROUND = {
		192,
		288,
		320,
		320
	},
	SIDE_GAUGE_BACKGROUND = {
		48,
		288,
		144,
		144
	},
	FUEL_LEVEL_ICON = {
		192,
		0,
		48,
		48
	},
	DAMAGE_LEVEL_ICON = {
		144,
		0,
		48,
		48
	},
	OPERATING_TIME = {
		16,
		0,
		32,
		48
	},
	CRUISE_CONTROL = {
		96,
		146,
		42,
		42
	},
	SEPARATOR = {
		8,
		8,
		1,
		1
	},
	GAUGE_INDICATOR_LARGE = {
		0,
		288,
		48,
		96
	},
	GAUGE_INDICATOR_SMALL = {
		18,
		406,
		11,
		56
	},
	GAUGE_SEGMENT = {
		{
			629,
			869,
			64,
			48
		},
		{
			629,
			773,
			64,
			48
		},
		{
			629,
			677,
			64,
			48
		},
		{
			629,
			581,
			64,
			48
		},
		{
			629,
			485,
			64,
			48
		},
		{
			629,
			389,
			64,
			48
		},
		{
			629,
			293,
			64,
			48
		},
		{
			629,
			197,
			64,
			48
		},
		{
			629,
			101,
			64,
			48
		},
		{
			629,
			5,
			64,
			48
		},
		{
			533,
			869,
			64,
			48
		},
		{
			533,
			773,
			64,
			48
		},
		{
			533,
			677,
			64,
			48
		},
		{
			533,
			581,
			64,
			48
		},
		{
			533,
			485,
			64,
			48
		},
		{
			533,
			389,
			64,
			48
		},
		{
			533,
			293,
			64,
			48
		},
		{
			533,
			197,
			64,
			48
		},
		{
			533,
			101,
			64,
			48
		},
		{
			533,
			5,
			64,
			48
		}
	},
	SIDE_GAUGE_SEGMENT = {
		{
			867,
			480,
			141,
			96
		},
		{
			867,
			384,
			141,
			96
		},
		{
			867,
			288,
			141,
			96
		},
		{
			867,
			192,
			141,
			96
		},
		{
			867,
			96,
			141,
			96
		},
		{
			867,
			0,
			141,
			96
		},
		{
			723,
			864,
			141,
			96
		},
		{
			723,
			768,
			141,
			96
		},
		{
			723,
			672,
			141,
			96
		},
		{
			723,
			576,
			141,
			96
		},
		{
			723,
			480,
			141,
			96
		},
		{
			723,
			384,
			141,
			96
		},
		{
			723,
			288,
			141,
			96
		},
		{
			723,
			192,
			141,
			96
		},
		{
			723,
			96,
			141,
			96
		},
		{
			723,
			0,
			141,
			96
		}
	}
}
SpeedMeterDisplay.UV.SPEED_GAUGE_SEGMENT_FULL = SpeedMeterDisplay.UV.GAUGE_SEGMENT[#SpeedMeterDisplay.UV.GAUGE_SEGMENT]
SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT_FULL = SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT[#SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT]
SpeedMeterDisplay.GAUGE_TEXTURE_SCALE = 0.6
SpeedMeterDisplay.SIZE = {
	SHADOW_BACKGROUND = {
		600 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		600 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_BACKGROUND = {
		SpeedMeterDisplay.UV.GAUGE_BACKGROUND[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SIDE_GAUGE_BACKGROUND = {
		SpeedMeterDisplay.UV.SIDE_GAUGE_BACKGROUND[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.SIDE_GAUGE_BACKGROUND[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SEPARATOR = {
		144 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		3 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	FUEL_LEVEL_ICON = {
		60 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		60 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	DAMAGE_LEVEL_ICON = {
		60 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		60 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	CRUISE_CONTROL = {
		42 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		42 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	OPERATING_TIME = {
		32 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		48 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SPEED_GAUGE_SEGMENT = {
		SpeedMeterDisplay.UV.SPEED_GAUGE_SEGMENT_FULL[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.SPEED_GAUGE_SEGMENT_FULL[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SIDE_GAUGE_SEGMENT = {
		SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT_FULL[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.SIDE_GAUGE_SEGMENT_FULL[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SPEED_GAUGE_RADIUS = {
		101.5 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		101 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_INDICATOR_LARGE = {
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_INDICATOR_LARGE_RADIUS = {
		110 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		110 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_INDICATOR_SMALL = {
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_SMALL[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_SMALL[4] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_INDICATOR_SMALL_RADIUS = {
		167 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		167 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SIDE_GAUGE_RADIUS = {
		124 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		124 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	}
}
SpeedMeterDisplay.POSITION = {
	SPEED_METER = {
		0,
		0
	},
	GAUGE_BACKGROUND = {
		(SpeedMeterDisplay.SIZE.SHADOW_BACKGROUND[1] - SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND[1]) * 0.5,
		(SpeedMeterDisplay.SIZE.SHADOW_BACKGROUND[2] - SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND[2]) * 0.5
	},
	GAUGE_BACKGROUND_LEFT = {
		-26 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		(-114 + SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4]) * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_BACKGROUND_RIGHT = {
		(26 + SpeedMeterDisplay.UV.GAUGE_BACKGROUND[3] - SpeedMeterDisplay.UV.SIDE_GAUGE_BACKGROUND[3]) * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		(-114 + SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4]) * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_CENTER = {
		159,
		161
	},
	SEPARATOR = {
		SpeedMeterDisplay.UV.GAUGE_BACKGROUND[3] * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE * 0.5,
		120 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	FUEL_LEVEL_ICON = {
		178 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		(SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4] - SpeedMeterDisplay.UV.FUEL_LEVEL_ICON[4] * 0.2) * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	DAMAGE_LEVEL_ICON = {
		88 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		(SpeedMeterDisplay.UV.GAUGE_BACKGROUND[4] - SpeedMeterDisplay.UV.DAMAGE_LEVEL_ICON[4] * 0.2) * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	CRUISE_CONTROL = {
		110 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		68 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	CRUISE_CONTROL_TEXT = {
		8 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		6 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	OPERATING_TIME = {
		0,
		0 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	OPERATING_TIME_TEXT = {
		8 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		10 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SPEED_TEXT = {
		0,
		172 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	SPEED_UNIT = {
		0,
		142 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	}
}
SpeedMeterDisplay.TEXT_SIZE = {
	CRUISE_CONTROL = 24,
	OPERATING_TIME = 18,
	SPEED = 48,
	SPEED_UNIT = 16
}
SpeedMeterDisplay.COLOR = {
	SHADOW_BACKGROUND = {
		1,
		1,
		1,
		1
	},
	SPEED_TEXT = {
		1,
		1,
		1,
		1
	},
	SPEED_UNIT = {
		1,
		1,
		1,
		1
	},
	SPEED_GAUGE = {
		0.07,
		0.827,
		0.898,
		0.3
	},
	SPEED_GAUGE_INDICATOR = {
		0.07,
		0.827,
		0.898,
		1
	},
	DAMAGE_GAUGE = {
		0.3,
		0.898,
		0.07,
		0.3
	},
	DAMAGE_GAUGE_LOW = {
		0.898,
		0.3,
		0.07,
		0.4
	},
	DAMAGE_GAUGE_INDICATOR = {
		1,
		0,
		0,
		1
	},
	FUEL_GAUGE = {
		1,
		0.5,
		0,
		0.2
	},
	FUEL_GAUGE_INDICATOR = {
		1,
		0,
		0,
		1
	},
	CRUISE_CONTROL_OFF = {
		1,
		1,
		1,
		1
	},
	CRUISE_CONTROL_ON = {
		0.991,
		0.3865,
		0.01,
		1
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.1
	}
}
SpeedMeterDisplay.PIVOT = {
	SPEED_GAUGE_SEGMENT_FULL = {
		0,
		0
	},
	SIDE_GAUGE_SEGMENT_FULL = {
		0,
		0
	},
	GAUGE_INDICATOR_LARGE = {
		25,
		24
	},
	GAUGE_INDICATOR_SMALL = {
		6,
		6
	}
}
SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE = 248
SpeedMeterDisplay.SPEED_GAUGE_NUM_FULL_SEGMENTS = 10
SpeedMeterDisplay.ANGLE = {
	SPEED_GAUGE_MIN = MathUtil.degToRad(90 + SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE * 0.5 + 0.5),
	SPEED_GAUGE_MAX = MathUtil.degToRad(90 - SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE * 0.5 + 0.5),
	SPEED_GAUGE_SEGMENT_FULL = MathUtil.degToRad(SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE / SpeedMeterDisplay.SPEED_GAUGE_NUM_FULL_SEGMENTS),
	SPEED_GAUGE_SEGMENT_SMALLEST = MathUtil.degToRad(SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE / SpeedMeterDisplay.SPEED_GAUGE_NUM_FULL_SEGMENTS / 20),
	SIDE_GAUGE_SEGMENT_FULL = MathUtil.degToRad(40),
	SIDE_GAUGE_SEGMENT_SMALLEST = MathUtil.degToRad(2.5),
	FUEL_GAUGE_MIN = MathUtil.degToRad(25.6),
	FUEL_GAUGE_MAX = MathUtil.degToRad(65.6),
	DAMAGE_GAUGE_MIN = MathUtil.degToRad(154.1),
	DAMAGE_GAUGE_MAX = MathUtil.degToRad(113.9)
}
