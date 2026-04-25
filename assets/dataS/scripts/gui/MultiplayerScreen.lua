MultiplayerScreen = {
	CONTROLS = {
		NAT_WARNING = "natWarning",
		RENT_BUTTON = "rentButton"
	}
}
local MultiplayerScreen_mt = Class(MultiplayerScreen, ScreenElement)

function MultiplayerScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or MultiplayerScreen_mt)

	self:registerControls(MultiplayerScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.returnScreenClass = MainScreen

	return self
end

function MultiplayerScreen:onOpen()
	MultiplayerScreen:superClass().onOpen(self)
	self:initJoinGameScreen()
	self.rentButton:setVisible(not GS_IS_CONSOLE_VERSION)

	self.startMissionInfo.createGame = false

	if self.startMissionInfo.canStart then
		self.startMissionInfo.canStart = false

		self:changeScreen(ConnectToMasterServerScreen)
		g_connectToMasterServerScreen:connectToFront()
	end
end

function MultiplayerScreen:initJoinGameScreen()
	g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue("defaultServerPort"))
	g_connectToMasterServerScreen:setNextScreenName("JoinGameScreen")
	g_connectToMasterServerScreen:setPrevScreenName("MultiplayerScreen")
	g_selectMasterServerScreen:setPrevScreenName("MultiplayerScreen")
end

function MultiplayerScreen:onClickJoinGame()
	g_characterSelectionScreen:setIsMultiplayer(true)
	self:changeScreen(CharacterCreationScreen, MultiplayerScreen)
end

function MultiplayerScreen:onClickCreateGame()
	self.startMissionInfo.canStart = false
	g_createGameScreen.usePendingInvites = false

	self:changeScreen(CareerScreen, MainScreen)
end

function MultiplayerScreen:onRentAServerClick(element)
	if not GS_IS_STEAM_VERSION then
		openWebFile("fs19-rent-a-dedicated-server.php", "")
	else
		openWebFile("fs19-rent-a-dedicated-server-from-steam.php", "")
	end
end

function MultiplayerScreen:update(dt)
	MultiplayerScreen:superClass().update(self, dt)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			self:changeScreen(MainScreen)
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end

	self.natWarning:setVisible(getNATType() == NATType.NAT_STRICT)
end
