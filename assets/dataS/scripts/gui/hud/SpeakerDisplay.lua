SpeakerDisplay = {}
local SpeakerDisplay_mt = Class(SpeakerDisplay, HUDDisplayElement)
SpeakerDisplay.SHADOW_OFFSET_FACTOR = 0.05

function SpeakerDisplay.new(hudAtlasPath, ingameMap)
	local backgroundOverlay = SpeakerDisplay.createBackground(hudAtlasPath)
	local self = SpeakerDisplay:superClass().new(SpeakerDisplay_mt, backgroundOverlay, nil)
	self.ingameMap = ingameMap
	self.maxNumPlayers = g_serverMaxCapacity
	self.users = {}
	self.isMenuVisible = true
	self.isMenuMapVisible = false
	self.isChatVisible = false
	self.userSpeaking = {}
	self.currentSpeakers = {}
	self.speakerLineElements = {}
	self.speakerColumnElements = {}
	self.mapOffsetY = 0
	self.mapOffsetX = 0
	self.positionHorizontalY = 0
	self.positionHorizontalX = 0
	self.lineHeight = 0
	self.lineWidth = 0
	self.textLineOffsetY = 0
	self.textLineOffsetX = 0
	self.textSize = 0
	self.textOffsetY = 0
	self.shadowOffset = 0

	self:storeScaledValues()
	self:createComponents(hudAtlasPath)

	return self
end

function SpeakerDisplay:setUsers(users)
	self.users = users
	self.userSpeaking = {}
	self.currentSpeakers = {}
end

function SpeakerDisplay:onMapVisibilityChange(isMapVisible)
	self.isMenuMapVisible = isMapVisible

	self:updateVisibility()
end

function SpeakerDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.isMenuVisible = isMenuVisible and not isOverlayMenu
	self.isMenuMapVisible = self.isMenuMapVisible and isMenuVisible

	self:updateVisibility()
end

function SpeakerDisplay:onChatVisibilityChange(isChatVisible)
	self.isChatVisible = isChatVisible

	self:updateVisibility()
end

function SpeakerDisplay:getHeight()
	return #self.currentSpeakers * self.lineHeight
end

function SpeakerDisplay:updateSpeakingState()
	for _, user in pairs(self.users) do
		local wasSpeakingLastFrame = self.userSpeaking[user:getPlatformUserId()]
		local isSpeakingNow = meshNetworkGetNodeStatusForApp(user:getPlatformNodeId() or "", "voice") > 0

		if wasSpeakingLastFrame and not isSpeakingNow then
			for i, userId in ipairs(self.currentSpeakers) do
				if userId == user:getNickname() then
					table.remove(self.currentSpeakers, i)

					break
				end
			end
		elseif isSpeakingNow and not wasSpeakingLastFrame then
			table.insert(self.currentSpeakers, user:getNickname())
		end

		self.userSpeaking[user:getPlatformUserId()] = isSpeakingNow
	end
end

function SpeakerDisplay:updateVisibility()
	local useLines = not self.isMenuVisible or self.isMenuMapVisible
	local anyVisible = false

	for i = 1, self.maxNumPlayers do
		local lineVisible = i <= #self.currentSpeakers

		self.speakerLineElements[i]:setVisible(lineVisible and useLines)
		self.speakerColumnElements[i]:setVisible(lineVisible and not useLines)

		anyVisible = anyVisible or lineVisible
	end

	self:setVisible(anyVisible)

	if anyVisible then
		local color = SpeakerDisplay.COLOR.BACKGROUND

		if self.isMenuMapVisible or self.isChatVisible then
			color = SpeakerDisplay.COLOR.BACKGROUND_HIGH_CONTRAST
		end

		for _, lineElement in pairs(self.speakerLineElements) do
			lineElement:setColor(unpack(color))
		end
	end
end

function SpeakerDisplay:update(dt)
	SpeakerDisplay:superClass().update(self, dt)
	self:updateSpeakingState()
	self:updateVisibility()

	if not self.isMenuVisible or self.isMenuMapVisible then
		local mapHeight = 0
		local offsetY = (1 - self:getHeight()) * 0.5

		if not self.isMenuMapVisible then
			mapHeight = self.ingameMap:getHeight()
			offsetY = mapHeight > 0 and self.mapOffsetY or 0
		end

		local posX = g_safeFrameOffsetX + self.mapOffsetX
		local posY = math.max(0.051, g_safeFrameOffsetY + mapHeight + offsetY)

		self:setPosition(posX, posY)
	else
		local posX = math.max(0.051, self.positionHorizontalX)
		local posY = math.max(0.051, self.positionHorizontalY)

		self:setPosition(posX, posY)
	end
end

function SpeakerDisplay:draw()
	if self:getVisible() and #self.currentSpeakers > 0 then
		new2DLayer()
		SpeakerDisplay:superClass().draw(self)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local speakerElements = self.speakerLineElements
		local offX = self.textLineOffsetX
		local offY = self.textLineOffsetY

		if self.isMenuVisible and not self.isMenuMapVisible then
			speakerElements = self.speakerColumnElements
			offY = self.textColOffsetY
			offX = self.textColOffsetX
		end

		for i = 1, #self.currentSpeakers do
			local speakerElement = speakerElements[i]
			local lineX, lineY = speakerElement:getPosition()
			local lineHeight = speakerElement:getHeight()
			local posX = lineX + offX
			local posY = lineY + (lineHeight - self.textSize) * 0.5 + offY + self.textOffsetY

			setTextColor(unpack(SpeakerDisplay.COLOR.NAME_SHADOW))
			renderText(posX + self.shadowOffset, posY - self.shadowOffset, self.textSize, self.currentSpeakers[i])
			setTextColor(unpack(SpeakerDisplay.COLOR.NAME))
			renderText(posX, posY, self.textSize, self.currentSpeakers[i])
		end
	end
end

function SpeakerDisplay:setScale(uiScale)
	SpeakerDisplay:superClass().setScale(self, uiScale)
	self:storeScaledValues()
end

function SpeakerDisplay.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(SpeakerDisplay.POSITION.SELF))

	return g_safeFrameOffsetX + offX, math.max(0.51, g_safeFrameOffsetY + offY)
end

function SpeakerDisplay:storeScaledValues()
	self.mapOffsetX, self.mapOffsetY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SELF)
	self.positionHorizontalX, self.positionHorizontalY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SELF_HORIZONTAL)
	self.lineWidth, self.lineHeight = self:scalePixelToScreenVector(SpeakerDisplay.SIZE.LINE)
	self.textLineOffsetX, self.textLineOffsetY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.NAME)
	self.textColOffsetY = self.textLineOffsetY
	self.textColOffsetX = self.textLineOffsetX
	local selfLeftX = self:getPosition()
	self.textLineOffsetX = math.max(0.051 - selfLeftX, self.textLineOffsetX)
	self.textSize = self:scalePixelToScreenHeight(SpeakerDisplay.TEXT_SIZE.NAME)
	self.textOffsetY = self.textSize * 0.15
	self.shadowOffset = SpeakerDisplay.SHADOW_OFFSET_FACTOR * self.textSize
end

function SpeakerDisplay.createBackground(hudAtlasPath)
	local posX, posY = SpeakerDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(SpeakerDisplay.SIZE.SELF))
	local overlay = Overlay:new(nil, posX, posY, width, height)

	return overlay
end

function SpeakerDisplay:createSpeakerElement(hudAtlasPath, leftX, bottomY, width, height, elementArray)
	local overlay = Overlay:new(hudAtlasPath, leftX, bottomY, width, height)

	overlay:setUVs(GuiUtils.getUVs(SpeakerDisplay.UV.LINE))
	overlay:setColor(unpack(SpeakerDisplay.COLOR.BACKGROUND))

	local speakerElement = HUDElement:new(overlay)

	self:addChild(speakerElement)
	table.insert(elementArray, speakerElement)

	local offX, offY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SPEAKER_ICON)
	local iconWidth, iconHeight = self:scalePixelToScreenVector(SpeakerDisplay.SIZE.SPEAKER_ICON)
	local posX = leftX + offX
	local posY = bottomY + (height - iconHeight) * 0.5 + offY
	overlay = Overlay:new(hudAtlasPath, posX, posY, iconWidth, iconHeight)

	overlay:setUVs(GuiUtils.getUVs(SpeakerDisplay.UV.SPEAKER_ICON))
	overlay:setColor(unpack(SpeakerDisplay.COLOR.SPEAKER_ICON))

	local speakerIconElement = HUDElement:new(overlay)

	speakerElement:addChild(speakerIconElement)
end

function SpeakerDisplay:createComponents(hudAtlasPath)
	local baseX, baseY = SpeakerDisplay.getBackgroundPosition(1)
	local posY = baseY

	for i = 1, self.maxNumPlayers do
		self:createSpeakerElement(hudAtlasPath, baseX, posY, self.lineWidth, self.lineHeight, self.speakerLineElements)

		posY = posY + self.lineHeight
	end

	local posX = baseX

	for i = 1, self.maxNumPlayers do
		self:createSpeakerElement(hudAtlasPath, posX, baseY, self.lineWidth, self.lineHeight, self.speakerColumnElements)

		posX = posX + self.lineWidth
	end
end

SpeakerDisplay.UV = {
	LINE = {
		8,
		8,
		2,
		2
	},
	SPEAKER_ICON = {
		102,
		102,
		36,
		36
	}
}
SpeakerDisplay.TEXT_SIZE = {
	NAME = 13
}
SpeakerDisplay.SIZE = {
	SELF = {
		290,
		156
	},
	LINE = {
		290,
		26
	},
	SPEAKER_ICON = {
		24,
		24
	}
}
SpeakerDisplay.POSITION = {
	SELF = {
		0,
		36
	},
	SELF_HORIZONTAL = {
		130,
		942
	},
	SPEAKER_ICON = {
		0,
		0
	},
	NAME = {
		36,
		0
	}
}
SpeakerDisplay.COLOR = {
	BACKGROUND = {
		0,
		0,
		0,
		0
	},
	BACKGROUND_HIGH_CONTRAST = {
		0,
		0,
		0,
		0.8
	},
	SPEAKER_ICON = {
		0.3763,
		0.6038,
		0.0782,
		1
	},
	NAME = {
		1,
		1,
		1,
		1
	},
	NAME_SHADOW = {
		0,
		0,
		0,
		0.75
	}
}
