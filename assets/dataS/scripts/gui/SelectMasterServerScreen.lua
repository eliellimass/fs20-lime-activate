SelectMasterServerScreen = {
	CONTROLS = {
		SERVER_LIST = "serverList",
		MAIN_BOX = "mainBox",
		SERVER_LIST_ITEM_TEMPLATE = "listTemplate"
	}
}
local SelectMasterServerScreen_mt = Class(SelectMasterServerScreen, ScreenElement)

function SelectMasterServerScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or SelectMasterServerScreen_mt)

	self:registerControls(SelectMasterServerScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.masterServers = {}
	self.serverElements = {}

	return self
end

function SelectMasterServerScreen:onCreateServer(element)
	if self.currentServer ~= nil then
		self.serverElements[self.currentServer.id].name = element
	end
end

function SelectMasterServerScreen:onOpen()
	SelectMasterServerScreen:superClass().onOpen(self)

	self.masterServers = {}

	g_masterServerConnection:setCallbackTarget(self)
	self.mainBox:setVisible(g_deepLinkingInfo == nil)
	g_gui:showMessageDialog({
		visible = g_deepLinkingInfo ~= nil,
		text = g_i18n:getText("ui_connectingPleaseWait"),
		dialogType = DialogElement.TYPE_LOADING
	})
end

function SelectMasterServerScreen:onClickBack()
	self.startMissionInfo.canStart = false

	ConnectToMasterServerScreen.goBackCleanup()
	SelectMasterServerScreen:superClass().onClickBack(self)
end

function SelectMasterServerScreen:onClickOk()
	SelectMasterServerScreen:superClass().onClickOk(self)

	if self.serverList.selectedIndex > 0 then
		g_gui:showGui("ConnectToMasterServerScreen")
		g_connectToMasterServerScreen:connectToBack(self.serverList.selectedIndex - 1)
	end
end

function SelectMasterServerScreen:onMasterServerList(name, id)
	local lowerName = string.lower(name)
	local newServer = {
		id = table.getn(self.masterServers),
		name = name,
		masterServerId = id
	}

	table.insert(self.masterServers, newServer)
end

function SelectMasterServerScreen:onMasterServerListEnd()
	self:updateServersGraphics()
	self.serverList:setSelectedIndex(1)

	local masterServerInfo = g_deepLinkingInfo or g_dedicatedServerInfo or g_autoDevMP
	local serverIndex = nil

	if masterServerInfo ~= nil then
		local data = masterServerInfo
		serverIndex = 1

		for i, server in ipairs(self.masterServers) do
			if server.masterServerId == data.masterServerId then
				data.masterServerName = server.name
				serverIndex = i

				break
			end

			i = i + 1
		end
	end

	if serverIndex ~= nil then
		self.serverList:setSelectedIndex(serverIndex)
		self:onClickOk()
	end
end

function SelectMasterServerScreen:onMasterServerConnectionReady()
	local gui = g_gui:showGui(self.nextScreenName)

	gui.target:onMasterServerConnectionReady()
end

function SelectMasterServerScreen:onMasterServerConnectionFailed(reason)
	ConnectToMasterServerScreen.goBackCleanup()
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, self.returnScreenName)
end

function SelectMasterServerScreen:setNextScreenName(nextScreenName)
	self.nextScreenName = nextScreenName
end

function SelectMasterServerScreen:setPrevScreenName(prevScreenName)
	self:setReturnScreen(prevScreenName)
end

function SelectMasterServerScreen:updateServersGraphics()
	self.serverList:deleteListItems()

	for i = 1, table.getn(self.masterServers) do
		self.currentServer = self.masterServers[i]
		self.currentServer.index = i

		if self.listTemplate ~= nil then
			self.serverElements[self.currentServer.id] = {}
			local new = self.listTemplate:clone(self.serverList)

			new:updateAbsolutePosition()

			local elements = self.serverElements[self.currentServer.id]

			if elements.name ~= nil then
				elements.name:setText(self.currentServer.name)
			end
		end

		self.currentServer = nil
	end
end

function SelectMasterServerScreen:onDoubleClick()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self:onClickOk()
end

function SelectMasterServerScreen:onListSelectionChanged()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
