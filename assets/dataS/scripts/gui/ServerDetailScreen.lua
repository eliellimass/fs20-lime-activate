ServerDetailScreen = {
	CONTROLS = {
		SERVER_NAME_TEXT = "serverNameElement",
		MOD_LIST = "modList",
		HEADER_TEXT = "headerText",
		MAIN_BOX = "mainBox",
		PLAYER_CIRCLE = "playerCircleElement",
		MOD_LIST_ITEM_TEMPLATE = "listItemTemplate",
		NUM_PLAYERS_TEXT = "numPlayersElement",
		MAP_TEXT = "mapElement",
		WARNING_TEXT = "warningTextElement",
		MAP_ICON = "mapIconElement",
		START_ELEMENT = "startElement",
		GET_MODS_BUTTON = "getModsButton",
		LANGUAGE_TEXT = "languageElement",
		PASSWORD_TEXT = "passwordElement",
		SHOW_PROFILE_BUTTON = "showProfileButton",
		NO_MODS_DLCS_ELEMENT = "noModsDLCsElement",
		WARNING = "warningElement"
	}
}
local ServerDetailScreen_mt = Class(ServerDetailScreen, ScreenElement)

function ServerDetailScreen:new(target, custom_mt)
	local self = ScreenElement:new(target, custom_mt or ServerDetailScreen_mt)

	self:registerControls(ServerDetailScreen.CONTROLS)

	self.returnScreenName = "JoinGameScreen"

	return self
end

function ServerDetailScreen:onCreate(element)
	self.modList:removeElement(self.listItemTemplate)
end

function ServerDetailScreen:onCreateList(element)
	self.modList = element
end

function ServerDetailScreen:onOpen()
	ServerDetailScreen:superClass().onOpen(self)
	self.serverNameElement:setText(g_joinGameScreen.serverDetailsName)
	self.headerText:setText(g_joinGameScreen.serverDetailsName)
	self.mapElement:setText(g_joinGameScreen.serverDetailsMapName)
	self.languageElement:setText(getLanguageName(g_joinGameScreen.serverDetailsLanguage))

	local map = g_mapManager:getMapById(g_joinGameScreen.serverDetailsMapId)

	if map ~= nil then
		self.mapIconElement:setImageFilename(map.iconFilename)
	end

	local passwordStr = g_i18n:getText("ui_no")

	if g_joinGameScreen.serverDetailsHasPassword then
		passwordStr = g_i18n:getText("ui_yes")
	end

	self.passwordElement:setText(passwordStr)

	if g_joinGameScreen.serverDatailsAllModsAvailable then
		self.warningElement:applyProfile("serverDetailWarningOk")
		self.warningTextElement:applyProfile("serverDetailWarningTextOk")
		self.warningTextElement:setText(g_i18n:getText("ui_allModsDLCsInstalled"))
	else
		self.warningElement:applyProfile("serverDetailWarningError")
		self.warningTextElement:applyProfile("serverDetailWarningTextError")
		self.warningTextElement:setText(g_i18n:getText("ui_notAllModsAvailable"))
	end

	if g_joinGameScreen.serverDetailsNumPlayers == 0 then
		self.playerCircleElement:applyProfile("serverDetailPlayerCircleEmpty")
	elseif g_joinGameScreen.serverDetailsNumPlayers == g_joinGameScreen.serverDetailsCapacity then
		self.playerCircleElement:applyProfile("serverDetailPlayerCircleFull")
	else
		self.playerCircleElement:applyProfile("serverDetailPlayerCircleOk")
	end

	local numPlayers = string.format("%02d/%02d", g_joinGameScreen.serverDetailsNumPlayers, g_joinGameScreen.serverDetailsCapacity)

	self.numPlayersElement:setText(numPlayers)

	local canStart = g_joinGameScreen.serverDatailsAllModsAvailable and g_joinGameScreen.serverDetailsNumPlayers < g_joinGameScreen.serverDetailsCapacity

	self.startElement:setDisabled(not canStart)
	self.modList:deleteListItems()

	for i = 1, table.getn(g_joinGameScreen.serverDetailsModTitles) do
		local newListItem = self.listItemTemplate:clone(self.modList)

		newListItem:updateAbsolutePosition()

		local modTitle, modVersion, modAuthor = ServerDetailScreen.unpackModInfo(g_joinGameScreen.serverDetailsModTitles[i])
		local modHash = g_joinGameScreen.serverDetailsModHashs[i]
		local modAvailable = g_modManager:getIsModAvailable(modHash)
		local titleElement = newListItem:getDescendantByName("title")

		titleElement:setText(string.format(g_i18n:getText("ui_modTitleVersion"), modTitle, modVersion))

		if modAvailable then
			titleElement:applyProfile("serverDetailModTitle")
		else
			titleElement:applyProfile("serverDetailModTitleMissing")
		end

		newListItem:getDescendantByName("author"):setText(string.format(g_i18n:getText("ui_modAuthor"), modAuthor))
		newListItem:getDescendantByName("hash"):setText(GS_IS_CONSOLE_VERSION and "" or modHash)
		newListItem:getDescendantByName("available"):setVisible(not modAvailable)
	end

	self.noModsDLCsElement:setVisible(table.getn(self.modList.listItems) == 0)
	self.getModsButton:setDisabled(g_joinGameScreen.serverDatailsAllModsAvailable)
	self.getModsButton:setVisible(not GS_IS_CONSOLE_VERSION)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		self.getModsButton:setDisabled(false)
		self.getModsButton:setVisible(true)
		self.getModsButton:setText(g_i18n:getText("button_showProfile"))
	end
end

function ServerDetailScreen:onClickOk()
	if g_joinGameScreen.serverDatailsAllModsAvailable and g_joinGameScreen.serverDetailsNumPlayers < g_joinGameScreen.serverDetailsCapacity then
		if not g_joinGameScreen.serverDetailsHasPassword then
			g_joinGameScreen:startGame("", g_joinGameScreen.serverDetailsId)
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

function ServerDetailScreen:onClickActivate()
	if not self.getModsButton.isDisabled and not GS_IS_CONSOLE_VERSION then
		local modListStr = ""

		for i = 1, table.getn(g_joinGameScreen.serverDetailsModTitles) do
			if not g_modManager:getIsModAvailable(g_joinGameScreen.serverDetailsModHashs[i]) then
				if modListStr == "" then
					modListStr = g_joinGameScreen.serverDetailsModHashs[i]
				else
					modListStr = modListStr .. ";" .. g_joinGameScreen.serverDetailsModHashs[i]
				end
			end
		end

		if modListStr ~= "" then
			openWebFile("fs2019MetaModSearch.php", "search=" .. modListStr)
		end
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		showUserProfile(g_joinGameScreen.serverDetailsConsoleUser)
	end
end

function ServerDetailScreen:onPasswordEntered(password, clickOk)
	if clickOk then
		g_gameSettings:setTableValue("joinGame", "password", password)
		g_gameSettings:saveToXMLFile(g_savegameXML)
		g_joinGameScreen:startGame(password, g_joinGameScreen.serverDetailsId)
	end
end

function ServerDetailScreen.packModInfo(modTitle, version, author)
	modTitle = string.gsub(modTitle, ";", " ")
	version = string.gsub(version, ";", " ")
	author = string.gsub(author, ";", " ")

	return modTitle .. ";" .. version .. ";" .. author
end

function ServerDetailScreen.unpackModInfo(str)
	local parts = StringUtil.splitString(";", str)
	local modTitle = parts[1]
	local version = parts[2]
	local author = parts[3]

	if modTitle == nil or modTitle == "" then
		modTitle = "Unknown Title"
	end

	if version == nil or version == "" then
		version = "0.0.0.1"
	end

	if author == nil then
		author = ""
	end

	return modTitle, version, author
end
