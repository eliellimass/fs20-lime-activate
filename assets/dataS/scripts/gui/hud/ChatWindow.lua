ChatWindow = {}
local ChatWindow_mt = Class(ChatWindow, HUDDisplayElement)
ChatWindow.MAX_NUM_MESSAGES = 10
ChatWindow.DISPLAY_DURATION = 10000
ChatWindow.SHADOW_OFFSET_FACTOR = 0.05

function ChatWindow.new(hudAtlasPath, speakerDisplay)
	local backgroundOverlay = ChatWindow.createBackground(hudAtlasPath)
	local self = ChatWindow:superClass().new(ChatWindow_mt, backgroundOverlay, nil)
	self.speakerDisplay = speakerDisplay
	self.maxLines = ChatWindow.MAX_NUM_MESSAGES
	self.messages = {}
	self.chatMessagesShowOffset = 0
	self.hideTime = 0
	self.messageOffsetY = 0
	self.messageOffsetX = 0
	self.textSize = 0
	self.textOffsetY = 0
	self.lineOffset = 0
	self.shadowOffset = 0

	self:storeScaledValues()

	return self
end

function ChatWindow:setChatMessages(messages)
	self.messages = messages
end

function ChatWindow:setVisible(isVisible, animate)
	if isVisible then
		self.speakerDisplay:onChatVisibilityChange(true)
		ChatWindow:superClass().setVisible(self, true, false)

		if animate then
			self.hideTime = ChatWindow.DISPLAY_DURATION
		else
			self.hideTime = -1
		end
	else
		self.hideTime = self:getVisible() and ChatWindow.DISPLAY_DURATION or 0
	end
end

function ChatWindow:scrollChatMessages(delta, numMessages)
	self.chatMessagesShowOffset = MathUtil.clamp(self.chatMessagesShowOffset + delta, 0, numMessages - self.maxLines)
end

function ChatWindow:onMenuVisibilityChange(isMenuVisible)
	self.isMenuVisible = isMenuVisible
end

function ChatWindow:update(dt)
	ChatWindow:superClass().update(self, dt)

	if self.hideTime >= 0 then
		self.hideTime = self.hideTime - dt

		if self.hideTime <= 0 then
			self.speakerDisplay:onChatVisibilityChange(false)
			ChatWindow:superClass().setVisible(self, false, false)
		end
	end
end

function ChatWindow:draw()
	if self:getVisible() and (not self.isMenuVisible or g_gui.currentGuiName == "ChatDialog") and #self.messages > 0 then
		ChatWindow:superClass().draw(self)
		setTextWrapWidth(self:getWidth())
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local currentLine = 0
		local baseX, baseY = self:getPosition()
		local posX = baseX + self.messageOffsetX
		local posY = baseY + self.messageOffsetY
		local lineHeight = self.textSize + self.lineOffset
		local maxLineShown = self.maxLines + self.chatMessagesShowOffset

		for i = #self.messages, 1, -1 do
			local text = self.messages[i].sender .. ": " .. self.messages[i].msg
			local _, numLines = getTextHeight(self.textSize, text)
			currentLine = currentLine + numLines

			if self.chatMessagesShowOffset < currentLine then
				local lineShowOffset = math.max(currentLine - maxLineShown, 0)
				local numLinesShow = math.min(numLines, currentLine - self.chatMessagesShowOffset)
				numLinesShow = numLinesShow - lineShowOffset

				setTextLineBounds(lineShowOffset, numLinesShow)
				setTextColor(unpack(ChatWindow.COLOR.MESSAGE_SHADOW))
				renderText(posX + self.shadowOffset, posY + (currentLine - lineShowOffset - self.chatMessagesShowOffset - 1) * lineHeight - self.shadowOffset, self.textSize, text)
				setTextColor(unpack(ChatWindow.COLOR.MESSAGE))
				renderText(posX, posY + (currentLine - lineShowOffset - self.chatMessagesShowOffset - 1) * lineHeight, self.textSize, text)
				setTextLineBounds(0, 0)

				if lineShowOffset > 0 then
					break
				end
			end
		end

		setTextWrapWidth(0)
	end
end

function ChatWindow:setScale(uiScale)
	ChatWindow:superClass().setScale(self, uiScale)
	self:storeScaledValues()
end

function ChatWindow.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(ChatWindow.POSITION.SELF))

	return g_safeFrameOffsetX + offX, g_safeFrameOffsetY + offY
end

function ChatWindow:storeScaledValues()
	self.messageOffsetX, self.messageOffsetY = self:scalePixelToScreenVector(ChatWindow.POSITION.MESSAGE)
	self.textSize = self:scalePixelToScreenHeight(ChatWindow.TEXT_SIZE.MESSAGE)
	self.textOffsetY = self.textSize * 0.15
	self.lineOffset = self.textSize * 0.3
	self.shadowOffset = ChatWindow.SHADOW_OFFSET_FACTOR * self.textSize
end

function ChatWindow.createBackground(hudAtlasPath)
	local posX, posY = ChatWindow.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(ChatWindow.SIZE.SELF))
	local overlay = Overlay:new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(ChatWindow.UV.BACKGROUND))
	overlay:setColor(unpack(ChatWindow.COLOR.BACKGROUND))

	overlay.visible = false

	return overlay
end

ChatWindow.UV = {
	BACKGROUND = {
		168,
		840,
		152,
		1
	}
}
ChatWindow.TEXT_SIZE = {
	MESSAGE = 21
}
ChatWindow.SIZE = {
	SELF = {
		640,
		ChatWindow.MAX_NUM_MESSAGES * ChatWindow.TEXT_SIZE.MESSAGE * 1.33
	}
}
ChatWindow.POSITION = {
	SELF = {
		0,
		300
	},
	MESSAGE = {
		8,
		8
	}
}
ChatWindow.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		1
	},
	MESSAGE = {
		1,
		1,
		1,
		1
	},
	MESSAGE_SHADOW = {
		0,
		0,
		0,
		0.75
	}
}
