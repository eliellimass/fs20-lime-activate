JoinGameScreen = {
	DATA_BINDING_FRIENDS = "dbFriends",
	DATA_BINDING_MODS_OK = "dbModsOk",
	DATA_BINDING_INTERNET = "dbInternet",
	DATA_BINDING_GAME_NAME = "dbGameName",
	DATA_BINDING_SLOTS_FULL = "dbSlotsFull",
	DATA_BINDING_MODS_MISSING = "dbModsMissing",
	DATA_BINDING_MAP_NAME = "dbMapName",
	DATA_BINDING_LANGUAGE = "dbLanguage",
	DATA_BINDING_PLAYERS = "dbPlayers",
	DATA_BINDING_PASSWORD = "dbPassword",
	DATA_BINDING_LAN = "dbLan",
	PROFILE_FILTER_OUT_SUFFIX = "FilterOut",
	DATA_BINDING_SLOTS_AVAILABLE = "dbSlotsAvailable",
	CONTROLS = {
		MAIN_BOX = "mainBox",
		PASSWORD_ELEMENT = "passwordElement",
		NUM_SERVERS_TEXT = "numServersText",
		BUTTON_BOX = "buttonBox",
		SERVER_LIST = "serverList",
		MOD_DLC_ELEMENT = "modDlcElement",
		START_BUTTON = "startButtonElement",
		SORT_BUTON = "sortButton",
		CHANGE_BUTTON = "changeButton",
		SERVER_NAME_ELEMENT = "serverNameElement",
		DETAIL_BUTTON = "detailButtonElement",
		SLIDER_ELEMENT = "sliderElement",
		CAPACITY_ELEMENT = "capacityElement"
	}
}
local JoinGameScreen_mt = Class(JoinGameScreen, ScreenElement)

function JoinGameScreen:new(target, custom_mt, startMissionInfo, messageCenter, inputManager)
	local self = ScreenElement:new(target, custom_mt or JoinGameScreen_mt)

	self:registerControls(JoinGameScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.servers = {}
	self.serverBuffer = {}
	self.requestedDetailsServerId = -1
	self.serverDetailsPending = false
	self.totalNumServers = 0
	self.numServers = 0
	self.maxNumPlayersStates = {}
	self.maxNumPlayersNumbers = {}

	for i = g_serverMinCapacity, g_serverMaxCapacity do
		table.insert(self.maxNumPlayersStates, tostring(i))
		table.insert(self.maxNumPlayersNumbers, i)
	end

	self.maxNumPlayersState = table.getn(self.maxNumPlayersNumbers)
	self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[self.maxNumPlayersState]
	self.hasNoPassword = false
	self.isNotFull = false
	self.onlyWithAllModsAvailable = false
	self.selectedMap = ""
	self.selectedLanguageId = 255
	self.serverName = ""
	self.lastUserName = ""
	self.returnScreenClass = MultiplayerScreen
	self.needTableUpdate = false
	self.needTableRebuild = false
	self.lastClickedHeader = nil
	self.canShowSortButton = GS_IS_CONSOLE_VERSION or inputManager:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
	self.focusedHeaderElement = nil
	self.dataBindings = {}
	self.dataBindingProfiles = {}

	return self
end

function JoinGameScreen:onDataBindGameName(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_GAME_NAME] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_GAME_NAME] = element.profile
end

function JoinGameScreen:onDataBindMapName(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_MAP_NAME] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_MAP_NAME] = element.profile
end

function JoinGameScreen:onDataBindIconServerPassword(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_PASSWORD] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_PASSWORD] = element.profile
end

function JoinGameScreen:onDataBindIconServerLan(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_LAN] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_LAN] = element.profile
end

function JoinGameScreen:onDataBindIconServerInternet(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_INTERNET] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_INTERNET] = element.profile
end

function JoinGameScreen:onDataBindIconFriends(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_FRIENDS] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_FRIENDS] = element.profile
end

function JoinGameScreen:onDataBindIconModsMissing(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_MODS_MISSING] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_MODS_MISSING] = element.profile
end

function JoinGameScreen:onDataBindIconModsOk(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_MODS_OK] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_MODS_OK] = element.profile
end

function JoinGameScreen:onDataBindPlayers(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_PLAYERS] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_PLAYERS] = element.profile
end

function JoinGameScreen:onDataBindIconSlotsAvailable(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_SLOTS_AVAILABLE] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_SLOTS_AVAILABLE] = element.profile
end

function JoinGameScreen:onDataBindIconSlotsFull(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_SLOTS_FULL] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_SLOTS_FULL] = element.profile
end

function JoinGameScreen:onDataBindLanguage(element)
	self.dataBindings[JoinGameScreen.DATA_BINDING_LANGUAGE] = element.name
	self.dataBindingProfiles[JoinGameScreen.DATA_BINDING_LANGUAGE] = element.profile
end

function JoinGameScreen:onCreateLanguage(element)
	self.languageElement = element
	local languageTable = {}

	table.insert(languageTable, g_i18n:getText("ui_allLanguages"))

	local numL = getNumOfLanguages()

	for i = 1, numL do
		table.insert(languageTable, getLanguageName(i - 1))
	end

	element:setTexts(languageTable)
end

function JoinGameScreen:onCreateMaxNumPlayers(element)
	element:setTexts(self.maxNumPlayersStates)

	self.maxNumPlayersElement = element
end

function JoinGameScreen:onCreateMap(element)
	self.mapSelectionElement = element
end

function JoinGameScreen:onOpen()
	JoinGameScreen:superClass().onOpen(self)

	self.mapTable = {}
	self.mapIds = {}

	table.insert(self.mapTable, g_i18n:getText("ui_anyMap"))
	table.insert(self.mapIds, "")

	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)
		local title = map.title
		title = Utils.limitTextToWidth(title, 0.025, 0.245, false, "..")

		table.insert(self.mapTable, title)
		table.insert(self.mapIds, map.title)
	end

	self.mapSelectionElement:setTexts(self.mapTable)

	if self.showingDeepLinkingPassword then
		self.showingDeepLinkingPassword = nil
		g_deepLinkingInfo = nil
	end

	g_gui:showMessageDialog({
		visible = g_deepLinkingInfo ~= nil,
		text = g_i18n:getText("ui_connectingPleaseWait"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.mainBox:setVisible(g_deepLinkingInfo == nil)

	local reloadSettings = not self.settingsLoaded

	if GS_IS_CONSOLE_VERSION and self.lastUserName ~= g_gameSettings:getValue("nickname") then
		self.lastUserName = g_gameSettings:getValue("nickname")
		reloadSettings = true
	end

	if reloadSettings then
		self:loadSettings()
	end

	self.isRequestPending = false

	g_masterServerConnection:setCallbackTarget(self)
	self.startButtonElement:setDisabled(true)
	self.detailButtonElement:setDisabled(true)
	self.numServersText:setText("")
	self.serverList:clearData(true)

	if g_deepLinkingInfo ~= nil then
		masterServerRequestServerDetails(g_deepLinkingInfo.serverId)
	else
		self:getServers()
	end

	self.messageCenter:subscribe(MessageType.INPUT_HELP_MODE_CHANGED, self.onInputModeChanged, self)
	self:showSortButton(false)
end

function JoinGameScreen:onClose()
	JoinGameScreen:superClass().onClose(self)
	self.messageCenter:unsubscribeAll(self)
end

function JoinGameScreen:onClickOk(isMouseClick)
	if self.selectedInputElement ~= nil then
		self.serverNameElement:onFocusActivate()

		return
	end

	JoinGameScreen:superClass().onClickOk(self)

	if self.serverList.selectedIndex > 0 then
		if self:isSelectedServerValid() then
			local server = self:getSelectedServer()

			if server ~= nil and server.allModsAvailable then
				if not server.hasPassword then
					self:startGame("", server.id)
				else
					local password = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "password"), "")

					g_gui:showPasswordDialog({
						callback = self.onPasswordEntered,
						target = self,
						defaultPassword = password
					})
				end
			end
		end

		if isMouseClick then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		end
	end

	self:saveFilterSettings()
end

function JoinGameScreen:onClickActivate()
	JoinGameScreen:superClass().onClickActivate(self)

	local server = self:getSelectedServer()

	if server ~= nil then
		self.requestedDetailsServerId = server.id
		self.serverDetailsPending = true

		masterServerRequestServerDetails(server.id)
	end
end

function JoinGameScreen:onClickBack()
	self.startMissionInfo.canStart = false

	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	self:saveFilterSettings()

	return JoinGameScreen:superClass().onClickBack(self)
end

function JoinGameScreen:onDoubleClick()
	self:onClickOk(true)
end

function JoinGameScreen:onFocusGameName(element)
	self.selectedInputElement = element

	self.startButtonElement:setText(g_i18n:getText("button_change"))
	self.startButtonElement:setDisabled(false)
end

function JoinGameScreen:onLeaveGameName(element)
	self.selectedInputElement = nil

	self.startButtonElement:setText(g_i18n:getText("button_start"))
	self:setStartButtonState()
end

function JoinGameScreen:onClickHeader(element)
	self.needTableUpdate = true
	self.lastClickedHeader = element
end

function JoinGameScreen:onFocusHeader(headerElement)
	self.focusedHeaderElement = headerElement

	self:showSortButton(self.canShowSortButton)
end

function JoinGameScreen:onLeaveHeader(_)
	self.focusedHeaderElement = nil

	self:showSortButton(false)
end

function JoinGameScreen:onClickCancel()
	local eventUnused = JoinGameScreen:superClass().onClickMenuExtra1(self)

	if eventUnused then
		if self.focusedHeaderElement ~= nil then
			self:onClickHeader(self.focusedHeaderElement)
		end

		eventUnused = false
	end

	return eventUnused
end

function JoinGameScreen:triggerRebuildOnFilterChange()
	self.serverList:setSelectedIndex(0)

	self.needTableRebuild = true
end

function JoinGameScreen:onClickLanguage(state)
	local languageId = state

	if state == 1 then
		languageId = 255
	elseif state > 1 and state ~= 255 then
		languageId = state - 2
	end

	self.selectedLanguageId = languageId

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickMaxNumPlayers(state)
	self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[state]

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickMap(state)
	self.selectedMap = self.mapIds[self.mapSelectionElement.state]

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickPassword(element)
	self.hasNoPassword = self.passwordElement:getIsChecked()

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickCapacity(element)
	self.isNotFull = self.capacityElement:getIsChecked()

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onClickModsDlcs(element)
	self.onlyWithAllModsAvailable = self.modDlcElement:getIsChecked()

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onServerNameChanged(element, text)
	self.serverName = text

	self:triggerRebuildOnFilterChange()
end

function JoinGameScreen:onListSelectionChanged(selectedIndex)
	self:setStartButtonState()
end

function JoinGameScreen:onServerListRefresh()
	self:getServers()
end

function JoinGameScreen:onInputModeChanged(inputMode)
	local requireSortButton = GS_IS_CONSOLE_VERSION or inputMode == GS_INPUT_HELP_MODE_GAMEPAD
	self.canShowSortButton = requireSortButton

	self:showSortButton(requireSortButton and self.focusedHeaderElement ~= nil)
end

function JoinGameScreen:loadSettings()
	self.settingsLoaded = true
	local selectedMapState = 1
	self.hasNoPassword = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "hasNoPassword"), false)
	self.isNotFull = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "isNotFull"), false)
	self.onlyWithAllModsAvailable = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "onlyWithAllModsAvailable"), false)
	self.serverName = Utils.getNoNil(g_gameSettings:getTableValue("joinGame", "serverName"), "")

	if g_autoDevMP ~= nil then
		self.serverName = g_autoDevMP.serverName
	end

	self.maxNumPlayersState = table.getn(self.maxNumPlayersNumbers)
	self.selectedLanguageId = 255
	local mapId = g_gameSettings:getTableValue("joinGame", "mapId")

	if mapId ~= nil then
		for i, m in pairs(self.mapIds) do
			if m == mapId then
				selectedMapState = i

				break
			end
		end
	end

	local capacity = g_gameSettings:getTableValue("joinGame", "capacity")

	if capacity ~= nil then
		for i, c in pairs(self.maxNumPlayersNumbers) do
			if c == capacity then
				self.maxNumPlayersState = i

				break
			end
		end
	end

	local selectedLanguageId = g_gameSettings:getTableValue("joinGame", "language")

	if selectedLanguageId ~= nil and (selectedLanguageId == 255 or selectedLanguageId >= 0 and selectedLanguageId < getNumOfLanguages()) then
		self.selectedLanguageId = selectedLanguageId
	end

	self.mapSelectionElement:setState(selectedMapState)

	self.selectedMap = self.mapIds[self.mapSelectionElement.state]

	self.passwordElement:setIsChecked(self.hasNoPassword)
	self.capacityElement:setIsChecked(self.isNotFull)
	self.modDlcElement:setIsChecked(self.onlyWithAllModsAvailable)
	self.serverNameElement:setText(self.serverName)
	self.maxNumPlayersElement:setState(self.maxNumPlayersState)

	self.selectedMaxNumPlayers = self.maxNumPlayersNumbers[self.maxNumPlayersElement.state]
	local languageIndex = 1

	if self.selectedLanguageId >= 0 and self.selectedLanguageId < getNumOfLanguages() then
		languageIndex = self.selectedLanguageId + 2
	end

	self.languageElement:setState(languageIndex)
end

function JoinGameScreen:saveFilterSettings()
	g_gameSettings:setTableValue("joinGame", "hasNoPassword", self.passwordElement:getIsChecked())
	g_gameSettings:setTableValue("joinGame", "isNotEmpty", self.capacityElement:getIsChecked())
	g_gameSettings:setTableValue("joinGame", "onlyWithAllModsAvailable", self.modDlcElement:getIsChecked())
	g_gameSettings:setTableValue("joinGame", "serverName", self.serverName)
	g_gameSettings:setTableValue("joinGame", "language", self.selectedLanguageId)
	g_gameSettings:setTableValue("joinGame", "capacity", self.maxNumPlayersNumbers[self.maxNumPlayersElement.state])
	g_gameSettings:setTableValue("joinGame", "mapId", self.mapIds[self.mapSelectionElement.state])
	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function JoinGameScreen:showSortButton(show)
	if show ~= self.sortButton:getIsVisible() then
		self.sortButton:setVisible(show)
		self.buttonBox:invalidateLayout()
	end
end

function JoinGameScreen:getSelectedServer()
	local selectedServer = nil

	if self.serverList.selectedIndex > 0 then
		local row = self.serverList:getSelectedElement()

		if row ~= nil then
			local serverId = row.id

			for _, server in pairs(self.servers) do
				if server.id == serverId then
					selectedServer = server

					break
				end
			end
		end
	end

	return selectedServer
end

function JoinGameScreen:setStartButtonState()
	if self.startButtonElement ~= nil then
		local isValid = self:isSelectedServerValid()

		self.detailButtonElement:setDisabled(false)

		if isValid then
			self.startButtonElement:setDisabled(false)
		else
			self.startButtonElement:setDisabled(true)
		end
	end
end

function JoinGameScreen:isSelectedServerValid()
	local selectedServer = self:getSelectedServer()

	return selectedServer and selectedServer.allModsAvailable and selectedServer.numPlayers < selectedServer.capacity
end

function JoinGameScreen:onPasswordEntered(password, clickOk)
	if clickOk then
		self.showingDeepLinkingPassword = nil

		if g_deepLinkingInfo ~= nil then
			g_deepLinkingInfo.password = password

			self:startGame(g_deepLinkingInfo.password, g_deepLinkingInfo.serverId)
		else
			g_gameSettings:setTableValue("joinGame", "password", password)
			g_gameSettings:saveToXMLFile(g_savegameXML)

			local server = self:getSelectedServer()

			self:startGame(password, server.id)
		end
	end
end

function JoinGameScreen:onServerInfoDetails(id, ip, port, name, language, capacity, numPlayers, mapName, mapId, hasPassword_isLanServer, consoleUser, modTitles, modHashs)
	if g_deepLinkingInfo ~= nil then
		if g_deepLinkingInfo.serverId == id then
			if hasPassword and g_deepLinkingInfo.password == "" then
				self.showingDeepLinkingPassword = true

				g_gui:showPasswordDialog({
					defaultPassword = "",
					callback = self.onPasswordEntered,
					target = self
				})
			else
				self:startGame(g_deepLinkingInfo.password, g_deepLinkingInfo.serverId)
			end
		end
	else
		local hasPassword = false
		local isLanServer = false

		if hasPassword_isLanServer > 1 then
			hasPassword_isLanServer = hasPassword_isLanServer - 2
			isLanServer = true
		end

		if hasPassword_isLanServer > 0 then
			hasPassword = true
		end

		if id == self.requestedDetailsServerId then
			self.serverDetailsId = id
			self.serverDetailsIP = ip
			self.serverDetailsPort = port
			self.serverDetailsName = name
			self.serverDetailsLanguage = language
			self.serverDetailsCapacity = capacity
			self.serverDetailsNumPlayers = numPlayers
			self.serverDetailsMapName = mapName
			self.serverDetailsMapId = mapId
			self.serverDetailsHasPassword = hasPassword
			self.serverDetailsIsLanServer = isLanServer
			self.serverDetailsModTitles = modTitles
			self.serverDetailsModHashs = modHashs
			self.serverDatailsAllModsAvailable = g_modManager:getAreAllModsAvailable(modHashs)
			self.serverDetailsConsoleUser = consoleUser

			g_gui:showGui("ServerDetailScreen")
		end
	end

	self.serverDetailsPending = false
end

function JoinGameScreen:onServerInfoDetailsFailed()
	if g_deepLinkingInfo ~= nil then
		g_deepLinkingInfo = nil

		g_gui:showConnectionFailedDialog({
			text = g_i18n:getText("ui_failedToConnectToGame"),
			callback = g_connectionFailedDialog.onOkCallback,
			target = g_connectionFailedDialog,
			args = {
				"JoinGameScreen"
			}
		})
	else
		self.requestedDetailsServerId = -1
	end

	self.serverDetailsPending = false

	self:getServers()
end

function JoinGameScreen:onMasterServerConnectionReady()
end

function JoinGameScreen:onMasterServerConnectionFailed(reason)
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "MultiplayerScreen")
end

function JoinGameScreen:onServerInfoStart(numServers, totalNumServers)
	self.totalNumServers = totalNumServers
	self.numServers = numServers
	self.serverBuffer = {}
end

function JoinGameScreen:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer, isFriendServer)
	local server = {
		id = id,
		name = name,
		hasPassword = hasPassword,
		language = language,
		capacity = capacity,
		numPlayers = numPlayers,
		mapName = mapName,
		allModsAvailable = allModsAvailable,
		isLanServer = isLanServer,
		isFriendServer = isFriendServer
	}

	table.insert(self.serverBuffer, server)
end

function JoinGameScreen:onServerInfoEnd()
	local selectedServer = self:getSelectedServer()

	if selectedServer then
		local serverPresent = false

		for _, server in pairs(self.servers) do
			if server.id == selectedServer.id and server.name == selectedServer.name then
				serverPresent = true

				break
			end
		end

		if not serverPresent then
			table.insert(self.serverBuffer, selectedServer)
		end
	end

	self.servers = self.serverBuffer
	self.isRequestPending = false
	self.needTableRebuild = true
end

function JoinGameScreen:filterServer(server)
	local pwOk = not self.hasNoPassword or not server.hasPassword
	local notFullOk = not self.isNotFull or server.numPlayers < server.capacity
	local mapOk = self.selectedMap == "" or server.mapName == self.selectedMap
	local modsOk = not self.onlyWithAllModsAvailable or server.allModsAvailable
	local languageOk = self.selectedLanguageId == 255 or server.language == self.selectedLanguageId
	local capOk = server.capacity <= self.selectedMaxNumPlayers
	local serverNameOk = self.serverName and server.name and (self.serverName == "" or string.find(server.name:lower(), self.serverName:lower()) ~= nil)

	return pwOk and notFullOk and mapOk and modsOk and languageOk and capOk and serverNameOk
end

function JoinGameScreen:setTableFiltersAndSorting()
	local filteredIds = {}

	for _, s in pairs(self.servers) do
		if s and self:filterServer(s) then
			filteredIds[s.id] = true
		end
	end

	local function noFilterMatchPredicate(dataRow)
		return not filteredIds[dataRow.id]
	end

	self.serverList:setProfileOverrideFilterFunction(noFilterMatchPredicate)

	local function sortFilterServerFunc(server1, server2)
		local inFiltered1 = not noFilterMatchPredicate(server1)
		local inFiltered2 = not noFilterMatchPredicate(server2)

		if inFiltered1 and not inFiltered2 then
			return 1
		elseif not inFiltered1 and inFiltered2 then
			return -1
		elseif server1.isLanServer and not server2.isLanServer then
			return 1
		elseif not server1.isLanServer and server2.isLanServer then
			return -1
		elseif server1.isFriendServer and not server2.isFriendServer then
			return 1
		elseif not server1.isFriendServer and server2.isFriendServer then
			return -1
		else
			return 0
		end
	end

	local function sortFilterFunc(sortCell1, sortCell2)
		local server1 = self.servers[sortCell1.dataRowIndex]
		local server2 = self.servers[sortCell2.dataRowIndex]

		return sortFilterServerFunc(server1, server2)
	end

	self.serverList:setCustomSortFunction(sortFilterFunc, true, true)

	local function preFilter(s1, s2)
		local eval = sortFilterServerFunc(s1, s2)

		if eval == 0 then
			return s1.id < s2.id
		else
			return eval > 0
		end
	end

	table.sort(self.servers, preFilter)
end

function JoinGameScreen:startGame(password, serverId)
	g_maxUploadRate = 30.72
	local missionInfo = FSCareerMissionInfo:new("", nil, 0)

	missionInfo:loadDefaults()

	missionInfo.playerModelIndex = self.startMissionInfo.playerModelIndex
	missionInfo.playerStyle = self.startMissionInfo.playerStyle
	local missionDynamicInfo = {
		serverId = serverId,
		isMultiplayer = true,
		isClient = true,
		password = password,
		allowOnlyFriends = false
	}

	g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_gui:showGui("MPLoadingScreen")
	g_mpLoadingScreen:startClient()
end

function JoinGameScreen:getServers()
	if self.isRequestPending then
		return
	end

	masterServerAddAvailableModStart()

	for _, mod in ipairs(g_modManager:getMultiplayerMods()) do
		masterServerAddAvailableMod(mod.fileHash)
	end

	masterServerAddAvailableModEnd()

	self.isRequestPending = true

	masterServerRequestFilteredServers("", false, 16, false, "", false, 255, getIsBadUserReputation())
end

function JoinGameScreen:rebuildServerList()
	if GS_IS_CONSOLE_VERSION then
		self.numServersText:setText(string.format("%d / %d %s", self.numServers, self.totalNumServers, g_i18n:getText("ui_games")))
	else
		local masterServerName = "Germany"
		local masterServer = g_selectMasterServerScreen.masterServers[g_selectMasterServerScreen.serverList.selectedIndex]

		if masterServer ~= nil then
			masterServerName = masterServer.name
		end

		self.numServersText:setText(string.format("%s: %d / %d %s", masterServerName, self.numServers, self.totalNumServers, g_i18n:getText("ui_games")))
	end

	self.serverList:clearData()

	for i, server in ipairs(self.servers) do
		local dataRow = self:buildServerDataRow(server)

		self.serverList:addRow(dataRow)
	end

	self:setStartButtonState()

	if self.requestedDetailsServerId >= 0 and not self.serverDetailsPending then
		for i, server in ipairs(self.servers) do
			if server.id == self.requestedDetailsServerId then
				self.serverList:setSelectedIndex(i)

				break
			end
		end

		self.requestedDetailsServerId = -1
	end

	if g_autoDevMP ~= nil then
		for k, server in pairs(self.servers) do
			if server.name == g_autoDevMP.serverName then
				self.serverList:setSelectedIndex(k)
				self:onClickOk(true)

				break
			end
		end
	end
end

function JoinGameScreen:buildServerDataRow(server)
	local dataRow = TableElement.DataRow:new(server.id, self.dataBindings)
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_PASSWORD]].isVisible = server.hasPassword
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_FRIENDS]].isVisible = server.isFriendServer
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_LAN]].isVisible = server.isLanServer
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_INTERNET]].isVisible = not server.isLanServer
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_MODS_MISSING]].isVisible = not server.allModsAvailable
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_GAME_NAME]].text = server.name
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_MAP_NAME]].text = server.mapName
	local numPlayers = string.format("%02d/%02d", server.numPlayers, server.capacity)
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_PLAYERS]].text = numPlayers
	local isFull = server.numPlayers == server.capacity
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_SLOTS_AVAILABLE]].isVisible = not isFull
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_SLOTS_FULL]].isVisible = isFull
	dataRow.columnCells[self.dataBindings[JoinGameScreen.DATA_BINDING_LANGUAGE]].text = getLanguageCode(server.language):upper()

	for db, _ in pairs(self.dataBindings) do
		dataRow.columnCells[self.dataBindings[db]].profileName = self.dataBindingProfiles[db]
		dataRow.columnCells[self.dataBindings[db]].overrideProfileName = self.dataBindingProfiles[db] .. JoinGameScreen.PROFILE_FILTER_OUT_SUFFIX
	end

	return dataRow
end

function JoinGameScreen:update(dt)
	JoinGameScreen:superClass().update(self, dt)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("MainScreen")
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end

	if not self.requestPending and #self.servers > 0 then
		if self.needTableRebuild or self.needTableUpdate then
			self:setTableFiltersAndSorting()
		end

		if self.needTableRebuild then
			self:rebuildServerList()

			self.needTableRebuild = false
			self.needTableUpdate = true
		end

		if self.needTableUpdate then
			local refocus = false

			if self.lastClickedHeader then
				self.serverList:onClickHeader(self.lastClickedHeader)

				self.lastClickedHeader = nil
				refocus = true
			end

			self.serverList:updateView(refocus)

			self.needTableUpdate = false
		end
	elseif not self.requestPending and self.needTableRebuild then
		self:rebuildServerList()

		self.needTableRebuild = false
		self.needTableUpdate = true
	end
end
