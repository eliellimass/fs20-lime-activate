FillLevelsDisplay = {}
local FillLevelsDisplay_mt = Class(FillLevelsDisplay, HUDDisplayElement)

function FillLevelsDisplay.new(hudAtlasPath)
	local backgroundOverlay = FillLevelsDisplay.createBackground()
	local self = FillLevelsDisplay:superClass().new(FillLevelsDisplay_mt, backgroundOverlay, nil)
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.fillLevelBuffer = {}
	self.fillLevelTextBuffer = {}
	self.fillTypeTextBuffer = {}
	self.fillTypeFrames = {}
	self.fillTypeLevelBars = {}
	self.frameHeight = 0
	self.fillLevelTextSize = 0
	self.fillLevelTextOffsetX = 0
	self.fillLevelTextOffsetY = 0

	return self
end

local function clearTable(table)
	for k in pairs(table) do
		table[k] = nil
	end
end

function FillLevelsDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

function FillLevelsDisplay:updateFillLevelBuffers()
	clearTable(self.fillLevelTextBuffer)
	clearTable(self.fillLevelBuffer)
	clearTable(self.fillTypeTextBuffer)

	for _, frame in pairs(self.fillTypeFrames) do
		frame:setVisible(false)
	end

	self.vehicle:getFillLevelInformation(self.fillLevelBuffer)
end

function FillLevelsDisplay:updateFillLevelFrames()
	local _, yOffset = self:getPosition()

	for i, fillLevelInformation in pairs(self.fillLevelBuffer) do
		local value = 0

		if fillLevelInformation.capacity > 0 then
			value = fillLevelInformation.fillLevel / fillLevelInformation.capacity
		end

		local frame = self.fillTypeFrames[fillLevelInformation.fillType]

		frame:setVisible(true)

		local fillBar = self.fillTypeLevelBars[fillLevelInformation.fillType]
		local _, yScale = fillBar:getScale()

		fillBar:setScale(value * self.uiScale, yScale)

		local posX, posY = frame:getPosition()

		frame:setPosition(posX, yOffset)

		local fillText = string.format("%d (%d%%)", MathUtil.round(fillLevelInformation.fillLevel), 100 * value)

		table.insert(self.fillLevelTextBuffer, fillText)

		if fillLevelInformation.fillType ~= FillType.UNKNOWN then
			local fillTypeText = g_fillTypeManager:getFillTypeByIndex(fillLevelInformation.fillType).title
			self.fillTypeTextBuffer[#self.fillLevelTextBuffer] = fillTypeText
		end

		yOffset = yOffset + self.frameHeight
	end
end

function FillLevelsDisplay:update(dt)
	FillLevelsDisplay:superClass().update(self, dt)

	if self.vehicle ~= nil then
		self:updateFillLevelBuffers()

		if #self.fillLevelBuffer > 0 then
			if not self:getVisible() and self.animation:getFinished() then
				self:setVisible(true, true)
			end

			self:updateFillLevelFrames()
		elseif self:getVisible() and self.animation:getFinished() then
			self:setVisible(false, true)
		end
	end
end

function FillLevelsDisplay:draw()
	FillLevelsDisplay:superClass().draw(self)

	if self:getVisible() then
		local baseX, baseY = self:getPosition()
		local width = self:getWidth()

		for i, fillLevelText in ipairs(self.fillLevelTextBuffer) do
			local posX = baseX + width - self.fillLevelTextOffsetX
			local posY = baseY + (i - 1) * self.frameHeight + self.fillLevelTextOffsetY

			setTextColor(unpack(FillLevelsDisplay.COLOR.FILL_LEVEL_TEXT))
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(posX, posY, self.fillLevelTextSize, fillLevelText)

			if self.fillTypeTextBuffer[i] ~= nil then
				local posY = baseY + (i - 1) * self.frameHeight + self.fillTypeTextOffsetY

				renderText(posX, posY, self.fillLevelTextSize, self.fillTypeTextBuffer[i])
			end
		end
	end
end

function FillLevelsDisplay:setScale(uiScale)
	FillLevelsDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = FillLevelsDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	self:storeScaledValues()
end

function FillLevelsDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.BACKGROUND))

	return 1 - g_safeFrameOffsetX - width - offX * scale, g_safeFrameOffsetY - offY * scale
end

function FillLevelsDisplay:storeScaledValues()
	self.fillLevelTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.fillLevelTextOffsetX, self.fillLevelTextOffsetY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_LEVEL_TEXT)
	self.fillTypeTextOffsetX, self.fillTypeTextOffsetY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_TYPE_TEXT)
	self.frameHeight = self:scalePixelToScreenVector(FillLevelsDisplay.SIZE.FILL_TYPE_FRAME) * 0.8
end

function FillLevelsDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.BACKGROUND))
	local posX, posY = FillLevelsDisplay.getBackgroundPosition(1, width)

	return Overlay:new(nil, posX, posY, width, height)
end

function FillLevelsDisplay:refreshFillTypes(fillTypeManager)
	for _, v in pairs(self.fillTypeFrames) do
		v:delete()
	end

	clearTable(self.fillTypeFrames)
	clearTable(self.fillTypeLevelBars)

	local posX, posY = self:getPosition()

	self:createFillTypeFrames(fillTypeManager, self.hudAtlasPath, posX, posY)
end

function FillLevelsDisplay:createFillTypeFrames(fillTypeManager, hudAtlasPath, baseX, baseY)
	for _, fillType in ipairs(fillTypeManager:getFillTypes()) do
		local frame = self:createFillTypeFrame(hudAtlasPath, baseX, baseY, fillType)
		self.fillTypeFrames[fillType.index] = frame

		frame:setScale(self.uiScale, self.uiScale)
		self:addChild(frame)
	end
end

function FillLevelsDisplay:createFillTypeFrame(hudAtlasPath, baseX, baseY, fillType)
	local frameWidth, frameHeight = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.FILL_TYPE_FRAME))
	local frameX, frameY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.FILL_TYPE_FRAME))
	local posX = baseX + frameX
	local posY = baseY + frameY
	local frameOverlay = Overlay:new(nil, posX, posY, frameWidth, frameHeight)
	local frame = HUDElement:new(frameOverlay)

	frame:setVisible(false)
	self:createFillTypeIcon(frame, posX, posY, fillType)
	self:createFillTypeBar(hudAtlasPath, frame, posX, posY, fillType)

	return frame
end

function FillLevelsDisplay:createFillTypeIcon(frame, baseX, baseY, fillType)
	if fillType.hudOverlayFilenameSmall ~= "" then
		local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.FILL_TYPE_ICON))
		local posX, posY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.FILL_TYPE_ICON))
		local iconOverlay = Overlay:new(fillType.hudOverlayFilenameSmall, baseX + posX, baseY + posY, width, height)

		iconOverlay:setColor(unpack(FillLevelsDisplay.COLOR.FILL_TYPE_ICON))
		frame:addChild(HUDElement:new(iconOverlay))
	end
end

function FillLevelsDisplay:createFillTypeBar(hudAtlasPath, frame, baseX, baseY, fillType)
	local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.BAR))
	local barX, barY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.BAR))
	local posX = baseX + barX
	local posY = baseY + barY
	local bgOverlay = Overlay:new(hudAtlasPath, posX, posY, width, height)

	bgOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	bgOverlay:setColor(unpack(FillLevelsDisplay.COLOR.BAR_BACKGROUND))
	frame:addChild(HUDElement:new(bgOverlay))

	local fillOverlay = Overlay:new(hudAtlasPath, posX, posY, width, height)

	fillOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	fillOverlay:setColor(unpack(FillLevelsDisplay.COLOR.BAR_FILLED))

	local fillBarElement = HUDElement:new(fillOverlay)

	frame:addChild(fillBarElement)

	self.fillTypeLevelBars[fillType.index] = fillBarElement
end

FillLevelsDisplay.SIZE = {
	BACKGROUND = {
		180,
		450
	},
	FILL_TYPE_FRAME = {
		180,
		40
	},
	BAR = {
		144,
		10
	},
	FILL_TYPE_ICON = {
		33,
		33
	}
}
FillLevelsDisplay.POSITION = {
	BACKGROUND = {
		225,
		-30
	},
	FILL_TYPE_FRAME = {
		0,
		0
	},
	BAR = {
		36,
		6
	},
	FILL_TYPE_ICON = {
		0,
		0
	},
	FILL_LEVEL_TEXT = {
		0,
		24
	},
	FILL_TYPE_TEXT = {
		36,
		-14
	}
}
FillLevelsDisplay.COLOR = {
	BAR_BACKGROUND = {
		1,
		1,
		1,
		0.2
	},
	BAR_FILLED = {
		0.991,
		0.3865,
		0.01,
		1
	},
	FILL_TYPE_ICON = {
		1,
		1,
		1,
		1
	},
	FILL_LEVEL_TEXT = {
		1,
		1,
		1,
		1
	}
}
