ChatDialog = {
	CONTROLS = {
		CHAT_INPUT_ELEMENT = "textElement"
	},
	SCROLL_DELAY = 100
}
local ChatDialog_mt = Class(ChatDialog, ScreenElement)

function ChatDialog:new(target, custom_mt)
	local self = ScreenElement:new(target, custom_mt or ChatDialog_mt)

	self:registerControls(ChatDialog.CONTROLS)

	self.lastScrollTime = 0
	self.returnScreenName = ""

	return self
end

function ChatDialog:onOpen(element)
	ChatDialog:superClass().onOpen(self)

	g_currentMission.isPlayerFrozen = true

	self.textElement:setForcePressed(true)
	self.textElement:setText("")
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN, self, self.onMenuAxisUpDown, false, true, true, true)
	g_currentMission:setLastChatMessageTime()
end

function ChatDialog:onClose(element)
	ChatDialog:superClass().onClose(self)

	if g_currentMission ~= nil then
		g_currentMission:scrollChatMessages(-9999999)
		g_currentMission:toggleChat(false)

		g_currentMission.isPlayerFrozen = false
	end

	self.textElement:setForcePressed(false)
end

function ChatDialog:onCreateTextInput(element)
	self.textElement = element
end

function ChatDialog:onSendClick()
	if self.textElement.text ~= "" then
		local nickname = g_currentMission.player.visualInformation.playerName

		if g_server ~= nil then
			g_server:broadcastEvent(ChatEvent:new(self.textElement.text, nickname))
		else
			g_client:getServerConnection():sendEvent(ChatEvent:new(self.textElement.text, nickname))
		end

		g_currentMission:addChatMessage(nickname, self.textElement.text)
		self.textElement:setText("")
	end

	g_gui:showGui("")
end

function ChatDialog:onMenuAxisUpDown(actionName, inputValue)
	local delta = 0

	if inputValue > 0 then
		delta = 1
	elseif inputValue < 0 then
		delta = -1
	end

	if delta ~= 0 and self.lastScrollTime + ChatDialog.SCROLL_DELAY <= g_time then
		g_currentMission:scrollChatMessages(delta)

		self.lastScrollTime = g_time
	end
end

function ChatDialog:update(dt)
	ChatDialog:superClass().update(self, dt)
	g_currentMission:setLastChatMessageTime()
end

function ChatDialog:onEnterPressed()
	self:onSendClick()
end

function ChatDialog:onEscPressed()
	self.textElement:setText("")
	g_gui:showGui("")
end
