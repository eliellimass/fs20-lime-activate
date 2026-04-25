AchievementMessage = {}
local AchievementMessage_mt = Class(AchievementMessage, HUDDisplayElement)

function AchievementMessage.new(hudAtlasPath, inputManager, guiSoundPlayer, contextActionDisplay)
	local backgroundOverlay = AchievementMessage.createBackground()
	local self = AchievementMessage:superClass().new(AchievementMessage_mt, backgroundOverlay, nil)
	self.inputManager = inputManager
	self.guiSoundPlayer = guiSoundPlayer
	self.contextActionDisplay = contextActionDisplay
	self.messages = {}
	self.currentMessage = nil
	self.message = ""
	self.queueShow = false
	self.time = 0
	self.playedSample = false
	self.labelTextOffsetY = 0
	self.labelTextOffsetX = 0
	self.labelTextSize = 0
	self.titleTextOffsetY = 0
	self.titleTextOffsetX = 0
	self.titleTextSize = 0
	self.messageTextOffsetY = 0
	self.messageTextOffsetX = 0
	self.messageTextSize = 0

	self:createComponents(hudAtlasPath)

	return self
end

function AchievementMessage:onMenuVisibilityChange(isVisible)
	self.isMenuVisible = isVisible
end

function AchievementMessage:showMessage(title, description, iconFilename, iconUVs, duration)
	if g_dedicatedServerInfo ~= nil then
		return
	end

	table.insert(self.messages, {
		title = title,
		description = description,
		iconFilename = iconFilename,
		iconUVs = iconUVs,
		duration = duration
	})

	if self.currentMessage == nil then
		self:nextMessage()
	end
end

function AchievementMessage:nextMessage()
	if self.currentMessage == nil and #self.messages > 0 then
		local message = self.messages[1]
		self.title = message.title
		self.message = message.description

		self.iconElement:setImage(message.iconFilename)
		self.iconElement:setUVs(message.iconUVs)

		self.visibleTime = message.duration
		self.time = 0
		self.playedSample = false
		self.queueShow = true

		table.remove(self.messages, 1)

		self.currentMessage = message
	end
end

function AchievementMessage:getAllowDisplay()
	if self.isMenuVisible then
		return false
	end

	if self.contextActionDisplay ~= nil and self.contextActionDisplay:getVisible() then
		return false
	end

	return true
end

function AchievementMessage:update(dt)
	if self:getAllowDisplay() then
		if self.queueShow then
			self:beginShowMessage()

			self.queueShow = false
		end

		if self:getVisible() then
			AchievementMessage:superClass().update(self, dt)

			if not self.playedSample then
				self.guiSoundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.ACHIEVEMENT)

				self.playedSample = true
			end

			self.time = self.time + dt

			if self.visibleTime < self.time and self.animation:getFinished() then
				self:hideMessage()

				self.time = 0
			end
		end
	end
end

function AchievementMessage:beginShowMessage()
	self:animateShow()

	local _, eventId = self.inputManager:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.hideMessage, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.hideMessage, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)
end

function AchievementMessage:hideMessage()
	if self.animation:getFinished() then
		self:animateHide()
	end

	self.inputManager:removeActionEventsByTarget(self)
end

function AchievementMessage:onAnimateVisibilityFinished(isVisible)
	AchievementMessage:superClass().onAnimateVisibilityFinished(self, isVisible)

	if not isVisible then
		self.currentMessage = nil

		self:nextMessage()
	end
end

function AchievementMessage:draw()
	if self:getVisible() and self:getAllowDisplay() then
		AchievementMessage:superClass().draw(self)

		local leftX, bottomY = self:getPosition()
		local topY = bottomY + self:getHeight()
		local achievementLabel = utf8ToUpper(g_i18n:getText("message_achievementUnlocked"))

		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextColor(unpack(AchievementMessage.COLOR.ACHIEVEMENT_TEXT))
		renderText(leftX + self.labelTextOffsetX, topY + self.labelTextOffsetY, self.labelTextSize, achievementLabel)
		setTextBold(true)
		setTextColor(unpack(AchievementMessage.COLOR.TITLE_TEXT))
		renderText(leftX + self.titleTextOffsetX, topY + self.titleTextOffsetY, self.titleTextSize, self.title)
		setTextBold(false)
		setTextColor(unpack(AchievementMessage.COLOR.MESSAGE_TEXT))
		setTextWrapWidth(self.messageTextWidth)

		local _, numLines = getTextHeight(self.messageTextSize, self.message)

		if numLines == 1 then
			topY = topY - self.messageTextSize * 0.5
		end

		for i = 0, numLines - 1 do
			setTextLineBounds(i, numLines - 1)

			local posY = topY + self.messageTextOffsetY - i * self.messageTextSize

			renderText(leftX + self.messageTextOffsetX, posY, self.messageTextSize, self.message)
		end

		setTextWrapWidth(0)
		setTextLineBounds(0, 0)
	end
end

function AchievementMessage:storeScaledValues()
	self.labelTextOffsetX, self.labelTextOffsetY = self:scalePixelToScreenVector(AchievementMessage.POSITION.ACHIEVEMENT_TEXT)
	self.labelTextSize = self:scalePixelToScreenHeight(AchievementMessage.TEXT_SIZE.ACHIEVEMENT)
	self.titleTextOffsetX, self.titleTextOffsetY = self:scalePixelToScreenVector(AchievementMessage.POSITION.TITLE_TEXT)
	self.titleTextSize = self:scalePixelToScreenHeight(AchievementMessage.TEXT_SIZE.TITLE)
	self.messageTextOffsetX, self.messageTextOffsetY = self:scalePixelToScreenVector(AchievementMessage.POSITION.MESSAGE_TEXT)
	self.messageTextSize = self:scalePixelToScreenHeight(AchievementMessage.TEXT_SIZE.MESSAGE)
	self.messageTextWidth = self:scalePixelToScreenWidth(AchievementMessage.SIZE.MESSAGE[1])
end

function AchievementMessage:setScale(uiScale)
	AchievementMessage:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	local posX, posY = AchievementMessage.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	self:storeScaledValues()
end

function AchievementMessage.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(AchievementMessage.POSITION.SELF))

	return 0.5 - width * 0.5 - offX * scale, g_safeFrameOffsetY - offY * scale
end

function AchievementMessage:createBackground()
	local width, height = getNormalizedScreenValues(unpack(AchievementMessage.SIZE.SELF))
	local posX, posY = AchievementMessage.getBackgroundPosition(1, width)

	return Overlay:new(nil, posX, posY, width, height)
end

function AchievementMessage:createComponents(hudAtlasPath)
	local baseX, baseY = self:getPosition()

	self:createFrame(hudAtlasPath, baseX, baseY)

	self.iconElement = self:createIcon(baseX, baseY)
end

function AchievementMessage:createFrame(hudAtlasPath, posX, posY)
	local frame = HUDFrameElement:new(hudAtlasPath, posX, posY, self:getWidth(), self:getHeight())

	self:addChild(frame)
end

function AchievementMessage:createIcon(leftX, bottomY)
	local width, height = self:scalePixelToScreenVector(AchievementMessage.SIZE.ICON)
	local offX, offY = self:scalePixelToScreenVector(AchievementMessage.POSITION.ICON)
	local posX = leftX + offX
	local posY = bottomY + (self:getHeight() - height) * 0.5 + offY
	local iconOverlay = Overlay:new(nil, posX, posY, width, height)
	local iconElement = HUDElement:new(iconOverlay)

	self:addChild(iconElement)

	return iconElement
end

AchievementMessage.SIZE = {
	SELF = {
		750,
		102
	},
	ICON = {
		84,
		84
	},
	MESSAGE = {
		500,
		0
	}
}
AchievementMessage.TEXT_SIZE = {
	ACHIEVEMENT = 22.5,
	TITLE = 30,
	MESSAGE = 22.5
}
AchievementMessage.POSITION = {
	SELF = {
		0,
		-150
	},
	ACHIEVEMENT_TEXT = {
		0,
		6
	},
	ICON = {
		12,
		6
	},
	TITLE_TEXT = {
		120,
		-34.5
	},
	MESSAGE_TEXT = {
		120,
		-61.5
	}
}
AchievementMessage.COLOR = {
	ICON = {
		1,
		1,
		1,
		1
	},
	ACHIEVEMENT_TEXT = {
		1,
		1,
		1,
		1
	},
	TITLE_TEXT = {
		1,
		1,
		1,
		1
	},
	MESSAGE_TEXT = {
		1,
		1,
		1,
		1
	}
}
