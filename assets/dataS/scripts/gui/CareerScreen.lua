CareerScreen = {}
local CareerScreen_mt = Class(CareerScreen, ScreenElement)
CareerScreen.CONTROLS = {
	SAVEGAME_LIST = "savegameList",
	BUTTON_START_PC = "buttonStartPC",
	BUTTON_ACHIEVEMENTS = "achievementsButton",
	LIST_ITEM_TEMPLATE = "listItemTemplate",
	BUTTON_DELETE_PC = "buttonDeletePC",
	BUTTON_CREDITS = "creditsButton",
	LIST_SLIDER = "listSlider"
}
CareerScreen.LIST_TEMPLATE_ELEMENT_NAME = {
	MONEY = "money",
	CHARACTER = "character",
	TIME_PLAYED = "timePlayed",
	STATUS = "status",
	GAME_NAME = "gameName",
	INFO_TEXT = "infoText",
	DIFFICULTY = "difficulty",
	DATA_BOX = "dataBox",
	STATUS_ICON = "statusIcon",
	TITLE = "title",
	PLAYER_NAME = "playerName",
	GAME_ICON = "gameIcon",
	MAP_NAME = "mapName",
	CREATE_DATE = "createDate",
	TEXT_BOX = "textBox"
}
CareerScreen.MISSING_MAP_ICON_PATH = "dataS2/menu/hud/missingMap.png"
CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY = 100
CareerScreen.SAVEGAME_UPDATE_TIME = 20000
CareerScreen.SAVEGAME_REFRESH_TIME = 3000

function CareerScreen:new(target, custom_mt, savegameController, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or CareerScreen_mt)

	self:registerControls(CareerScreen.CONTROLS)

	self.savegameController = savegameController
	self.startMissionInfo = startMissionInfo
	self.isMultiplayer = false
	self.selectedIndex = 1
	self.mapNameTexts = {}
	self.playerNameTexts = {}
	self.playerCharacterTexts = {}
	self.savegameNameTexts = {}
	self.moneyTexts = {}
	self.timePlayedTexts = {}
	self.difficultyTexts = {}
	self.dateTexts = {}
	self.statusTexts = {}
	self.statusIcons = {}
	self.listItemData = {}
	self.listItemTexts = {}
	self.listItemInfoText = {}
	self.savegames = {}
	self.tempIsSliderScrolling = false
	self.ignoreCorruptOnNextUpdate = false
	self.gameIcons = {}
	self.currentIndex = 0
	self.oldSelectedIndex = 0
	self.selectedIndexToRestore = 0
	self.recreateListOnOpen = true
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameLoadingDialogDelay = -1

	return self
end

function CareerScreen:onOpen()
	CareerScreen:superClass().onOpen(self)

	local canStart = self.startMissionInfo.canStart

	if canStart then
		self:startCurrentSavegame(true)
	else
		g_messageCenter:subscribe(MessageType.SAVEGAMES_LOADED, self.onSavegamesLoaded, self)

		self.selectedIndexToRestore = 0
		self.ignoreCorruptOnNextUpdate = false

		flushPhysicsCaches()

		if self.recreateListOnOpen then
			self.savegameController:resetStorageDeviceSelection()
			self:setSoundSuppressed(true)
			self:deleteSavegameListElements()
			self:recreateSavegameList()
			self:setSoundSuppressed(false)
		end

		self:updateButtons()
	end

	if g_isPresentationVersionHideMenuButtons then
		self.achievementsButton:setDisabled(true)
	end

	if GS_IS_MOBILE_VERSION and g_buildTypeParam == "CHINA_GAPP" then
		self.creditsButton:setVisible(false)
	end

	g_messageCenter:publish(MessageType.GUI_CAREER_SCREEN_OPEN, canStart)
	self.achievementsButton:setDisabled(g_mainScreen.achievementsButton:getIsDisabled())

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		self:updateAchievementsButtonState()
		g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.updateAchievementsButtonState, self)
	end
end

function CareerScreen:onClose()
	g_messageCenter:unsubscribe(MessageType.USER_PROFILE_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.SAVEGAMES_LOADED, self)
	CareerScreen:superClass().onClose(self)

	self.oldSelectedIndex = self.selectedIndex
end

function CareerScreen:update(dt)
	CareerScreen:superClass().update(self, dt)

	if self.savegameUpdateTimer >= 0 and not self.savegameController:getIsWaitingForSavegameInfo() and not g_gui:getIsDialogVisible() then
		self.savegameUpdateTimer = self.savegameUpdateTimer - dt

		if self.savegameUpdateTimer <= 0 then
			self.savegameUpdateTimer = -1

			self:recreateSavegameList()
		end
	end

	if self.savegameRefreshTimer >= 0 and not self.savegameController:getIsWaitingForSavegameInfo() then
		self.savegameRefreshTimer = self.savegameRefreshTimer - dt

		if self.savegameRefreshTimer <= 0 then
			self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME

			self.savegameController:loadSavegames()
		end
	end

	if not g_messageDialog:getIsOpen() and not self.savegameController:getIsWaitingForSavegameInfo() and self.savegameController:isStorageDeviceUnavailable() then
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_savegamesScanSelectDevice"),
			callback = self.onYesNoSavegameSelectDevice,
			target = self
		})
	end

	if self.isMultiplayer and GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			self:changeScreen(MainScreen)
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end

	if self.savegameController:getIsWaitingForSavegameInfo() then
		if self.savegameLoadingDialogDelay <= 0 then
			self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY
		end
	elseif self.loadingDialog ~= nil then
		self.loadingDialog.target:close()

		self.loadingDialog = nil
	end

	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt

		if self.savegameLoadingDialogDelay <= 0 then
			self.loadingDialog = g_gui:showDialog("InfoDialog")

			self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegames"))
			self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
			self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
		end
	end
end

function CareerScreen:onSavegamesLoaded()
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	local oldSelection = math.max(math.min(self.selectedIndex, #self.savegameList.listItems), 1)

	self:updateSavegameListElements()
	self:calculateTotalPlaytime()
	self.savegameList:setSelectedIndex(oldSelection, true)
end

function CareerScreen:inputEvent(action, value, eventUsed)
	eventUsed = CareerScreen:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
		local curIndex = self.savegameList.selectedIndex

		if action == InputAction.MENU_PAGE_PREV then
			self.savegameList:setSelectedIndex(math.max(curIndex - 1, 1))
		else
			self.savegameList:setSelectedIndex(curIndex + 1)
		end

		eventUsed = true
	end

	return eventUsed
end

function CareerScreen:onClickOk(isMouseClick)
	local eventUnused = CareerScreen:superClass().onClickOk(self)

	if not FocusManager:hasFocus(self.savegameList) then
		return true
	end

	self.savegameController:tryToResolveConflict(self.selectedIndex, {
		target = self,
		callback = self.onClickOk,
		extraAttributes = {
			isMouseClick
		}
	}, {
		target = self,
		callback = self.recreateSavegameList,
		extraAttributes = {}
	})

	if eventUnused and self.savegameController:getCanStartGame(self.selectedIndex, false) then
		local savegame = self.savegameController:getSavegame(self.selectedIndex)

		self:startSavegame(savegame)

		eventUnused = false
	end

	return eventUnused
end

function CareerScreen:onDoubleClick()
	self:onClickOk(true)
end

function CareerScreen:onClickCancel()
	local eventUnused = CareerScreen:superClass().onClickCancel(self)

	if g_isPresentationVersion then
		return true
	end

	if self.savegameController:getIsSavegameConflicted(self.selectedIndex) then
		self.savegameController:tryToResolveConflict(self.selectedIndex, {
			target = self,
			callback = self.recreateSavegameList,
			extraAttributes = {}
		}, nil, false)

		return true
	end

	if self.savegameController:getCanDeleteGame(self.selectedIndex) then
		self.currentSavegame = self.savegameController:getSavegame(self.selectedIndex)

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_IOS or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_youWantToDeleteSavegameMobile"),
				callback = self.onYesNoDeleteSavegame,
				target = self
			})
		else
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_youWantToDeleteSavegame"),
				callback = self.onYesNoDeleteSavegame,
				target = self
			})
		end

		eventUnused = false
	end

	return eventUnused
end

function CareerScreen:deleteSavegameListElements()
	self.savegameList:deleteListItems()
end

function CareerScreen:updateSavegameListElements()
	self:deleteSavegameListElements()

	for i = 1, SavegameController.NUM_SAVEGAMES do
		local newListItem = self.listItemTemplate:clone(self.savegameList)

		newListItem:updateAbsolutePosition()

		local titleElement = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.TITLE)

		if GS_IS_MOBILE_VERSION then
			if g_languageShort == "cs" or g_languageShort == "ct" or g_languageShort == "jp" or g_languageShort == "kr" or g_languageShort == "tr" or g_languageShort == "ru" then
				titleElement:setText(string.format("%d", i))
			else
				local letters = "ABC"

				titleElement:setText(letters:sub(i, i))
			end
		else
			titleElement:setText(g_i18n:getText("ui_savegame") .. " " .. tostring(i))
		end

		self.gameIcons[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.GAME_ICON)
		self.mapNameTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.MAP_NAME)
		self.playerNameTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.PLAYER_NAME)
		self.playerCharacterTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.CHARACTER)
		self.savegameNameTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.GAME_NAME)
		self.moneyTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.MONEY)
		self.timePlayedTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.TIME_PLAYED)
		self.difficultyTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.DIFFICULTY)
		self.dateTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.CREATE_DATE)
		self.statusTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.STATUS)
		self.statusIcons[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.STATUS_ICON)
		self.listItemInfoText[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.INFO_TEXT)
		self.listItemTexts[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.TEXT_BOX)
		self.listItemData[i] = newListItem:getDescendantByName(CareerScreen.LIST_TEMPLATE_ELEMENT_NAME.DATA_BOX)

		self:updateSavegameText(i)
	end

	self.selectedIndex = 1

	if self.selectedIndexToRestore ~= 0 then
		self.selectedIndex = self.selectedIndexToRestore
		self.selectedIndexToRestore = 0
	end

	self.savegameList:setSelectedIndex(self.selectedIndex + 1, true)
	self:updateButtons()
end

function CareerScreen:onSaveGameUpdateComplete(errorCode)
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	local ignoreCorruptOnNextUpdate = self.ignoreCorruptOnNextUpdate
	self.ignoreCorruptOnNextUpdate = false

	if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
		self.savegameController:loadSavegames()

		if errorCode == Savegame.ERROR_DATA_CORRUPT and not ignoreCorruptOnNextUpdate and g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_someSavegamesCorrupt"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode == Savegame.ERROR_SCAN_IN_PROGRESS then
		self.savegameUpdateTimer = 0
	elseif errorCode == Savegame.ERROR_SCAN_FAILED then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegamesScanFailed"),
				callback = self.onOkSavegameScanFailed,
				target = self
			})
		end
	elseif errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegamesScanNoDevice"),
				callback = self.onOkSavegameScanFailed,
				target = self
			})
		end
	elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
		self:changeScreen(MainScreen)
	end

	if self.savegameUpdateTimer > 0 then
		self.savegameLoadingDialogDelay = -1

		if self.loadingDialog ~= nil then
			self.loadingDialog.target:close()

			self.loadingDialog = nil
		end
	end
end

function CareerScreen:calculateTotalPlaytime()
	local total = 0

	for i = 1, SavegameController.NUM_SAVEGAMES do
		local savegame = self.savegameController:getSavegame(i)

		if savegame.isValid then
			total = total + math.floor(savegame.playTime / 60 + 0.0001)
		end
	end

	self.totalPlayedHours = total
end

function CareerScreen:onYesNoSavegameCorrupted(yes)
	if yes then
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen, MainScreen)

		self.recreateListOnOpen = true
	else
		self:changeScreen(MainScreen)
	end
end

function CareerScreen:onOkSavegameScanFailed()
	self:changeScreen(MainScreen)
end

function CareerScreen:onSaveComplete(errorCode)
	if errorCode == Savegame.ERROR_OK then
		self:updateSavegameText(self.currentSavegame.savegameIndex)
	end
end

function CareerScreen:onCancelSavegameLoading()
	self.savegameController:cancelSavegameUpdate()
end

function CareerScreen:recreateSavegameList()
	if not self.savegameController:getIsWaitingForSavegameInfo() then
		self.savegameUpdateTimer = -1
		self.savegameRefreshTimer = -1
		self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY

		self.savegameController:updateSavegames(self.onSaveGameUpdateComplete, self)
	elseif self.savegameUpdateTimer > 0 then
		self.savegameUpdateTimer = 0
	end
end

function CareerScreen:onYesNoDeleteSavegame(yes)
	if yes then
		self:deleteCurrentSavegame()
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen, MainScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:onCreateGameIcon(element)
	if self.currentIndex > 0 then
		self.gameIcons[self.currentIndex] = element
	end
end

function CareerScreen:onCreateTitle(element)
	if self.currentIndex > 0 then
		element:setText(g_i18n:getText("ui_savegame") .. " " .. self.currentIndex)
	end
end

function CareerScreen:onCreateMapName(element)
	if self.currentIndex > 0 then
		self.mapNameTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreatePlayerName(element)
	if self.currentIndex > 0 then
		self.playerNameTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreatePlayerCharacter(element)
	if self.currentIndex > 0 then
		self.playerCharacterTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateName(element)
	if self.currentIndex > 0 then
		self.savegameNameTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateMoney(element)
	if self.currentIndex > 0 then
		self.moneyTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateTimePlayed(element)
	if self.currentIndex > 0 then
		self.timePlayedTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateDifficulty(element)
	if self.currentIndex > 0 then
		self.difficultyTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateDate(element)
	if self.currentIndex > 0 then
		self.dateTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateListItemInfoText(element)
	if self.currentIndex > 0 then
		self.listItemInfoText[self.currentIndex] = element
	end
end

function CareerScreen:onCreateListItemText(element)
	if self.currentIndex > 0 then
		self.listItemTexts[self.currentIndex] = element
	end
end

function CareerScreen:onCreateListItemData(element)
	if self.currentIndex > 0 then
		self.listItemData[self.currentIndex] = element
	end
end

function CareerScreen:onListSelectionChanged(rowIndex)
	self.selectedIndex = rowIndex

	self:updateButtons()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function CareerScreen:updateButtons()
	local canDeleteGame = self.savegameController:getCanDeleteGame(self.selectedIndex)

	if self.buttonDeletePC then
		self.buttonDeletePC:setDisabled(not canDeleteGame)
	end

	local canStartGame = self.savegameController:getCanStartGame(self.selectedIndex, true)

	if self.buttonStartPC then
		self.buttonStartPC:setDisabled(not canStartGame)
	end
end

function CareerScreen:updateSavegameText(index)
	local savegame = self.savegameController:getSavegame(index)

	self.listItemTexts[index]:setVisible(not savegame.isValid)
	self.listItemData[index]:setVisible(savegame.isValid)

	if savegame.isValid then
		local playTimeHoursF = savegame.playTime / 60 + 0.0001
		local playTimeHours = math.floor(playTimeHoursF)
		local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)

		self.savegameNameTexts[index]:setText(savegame.savegameName)

		if savegame.map ~= nil then
			self.mapNameTexts[index]:setText(savegame.map.title)

			if not GS_IS_MOBILE_VERSION then
				self.gameIcons[index]:setImageFilename(savegame.map.iconFilename)
			end
		else
			self.mapNameTexts[index]:setText(Utils.getNoNil(savegame.mapTitle, savegame.mapId))
			self.gameIcons[index]:setImageFilename(CareerScreen.MISSING_MAP_ICON_PATH)
		end

		self.moneyTexts[index]:setText(g_i18n:formatMoney(savegame.money, 0, not GS_IS_MOBILE_VERSION))
		self.timePlayedTexts[index]:setText(string.format("%02d:%02d", playTimeHours, playTimeMinutes))
		self.difficultyTexts[index]:setText(g_i18n:getText("ui_difficulty" .. savegame.difficulty))
		self.dateTexts[index]:setText(savegame.saveDate)

		local state = ""

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_IOS or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
			state = g_i18n:getText(savegame:getStateI18NKey())
		end

		self.statusTexts[index]:setText(state)
		self.statusIcons[index]:setVisible(state ~= "")
	elseif savegame.isInvalidUser then
		self.listItemInfoText[index]:setText(g_i18n:getText("ui_savegameBelongsToAnotherUser"))
	elseif savegame.isCorruptFile then
		self.listItemInfoText[index]:setText(g_i18n:getText("ui_savegameIsCorrupted"))
	else
		local text = nil

		if GS_IS_MOBILE_VERSION then
			text = g_i18n:getText("ui_newGame")
		else
			text = g_i18n:getText("ui_savegameIsCurrentlyUnused")
		end

		self.listItemInfoText[index]:setText(text)
	end
end

function CareerScreen:onYesNoSavegameSelectDevice(yes)
	if yes then
		self:changeScreen(CareerScreen)
	else
		self:changeScreen(MainScreen)
	end
end

function CareerScreen:startSavegame(savegame)
	self.currentSavegame = savegame

	if not savegame.isValid then
		if savegame.isInvalidUser then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameInvalidUser"),
				callback = self.onYesNoSavegameInvalidUser,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		elseif savegame.isCorruptFile then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameCorrupt"),
				callback = self.onYesNoSavegameInvalidUser,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		else
			self:onYesNoSavegameInvalidUser(true)
		end
	elseif savegame.map and not savegame.map.isMultiplayerSupported and self.isMultiplayer then
		g_gui:showInfoDialog({
			text = string.format(g_i18n:getText("ui_modsZipOnly"), savegame.map.title)
		})
	else
		local missingModTitles = {}
		local hasRequiredMissing = false
		local hasNoMpMods = false

		for _, modInfo in pairs(savegame.mods) do
			local mod = g_modManager:getModByName(modInfo.modName)

			if mod == nil then
				if modInfo.required then
					table.insert(missingModTitles, 1, modInfo.title)

					hasRequiredMissing = true
				else
					table.insert(missingModTitles, modInfo.title)
				end
			elseif not mod.isMultiplayerSupported and self.isMultiplayer then
				if not hasRequiredMissing and not GS_IS_CONSOLE_VERSION then
					hasNoMpMods = true

					table.insert(missingModTitles, 1, mod.title)
				else
					table.insert(missingModTitles, mod.title)
				end
			end
		end

		if #missingModTitles > 0 and g_dedicatedServerInfo == nil then
			local numMissing = math.min(#missingModTitles, 4)
			local modsText = missingModTitles[1]

			for i = 2, numMissing do
				modsText = modsText .. ", " .. missingModTitles[i]
			end

			if hasRequiredMissing then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_savegameHasMissingDlcs") .. "\n" .. modsText
				})
			elseif hasNoMpMods then
				g_gui:showInfoDialog({
					text = string.format(g_i18n:getText("ui_modsZipOnly"), missingModTitles[1]),
					callback = CareerScreen.onOkZipModsOptional,
					target = self
				})
			else
				g_gui:showYesNoDialog({
					text = g_i18n:getText("ui_savegameHasMissingDlcsOptional") .. "\n" .. modsText .. "\n\n" .. g_i18n:getText("ui_continueQuestion"),
					callback = self.onYesNoInstallMissingModsOptional,
					target = self,
					yesButton = g_i18n:getText("button_continue"),
					noButton = g_i18n:getText("button_cancel")
				})
			end
		else
			self:startCurrentSavegame()
		end
	end
end

function CareerScreen:onYesNoNotEnoughSpaceForNewSaveGame(yes)
	self.startMissionInfo.createGame = yes

	if yes then
		self:changeScreen(DifficultyScreen, CareerScreen)
	else
		self:changeScreen(CareerScreen)
	end
end

function CareerScreen:onYesNoSavegameInvalidUser(yes)
	if yes then
		if saveGetHasSpaceForSaveGame(self.currentSavegame.savegameIndex, FSCareerMissionInfo.MaxSavegameSize) then
			self:onYesNoNotEnoughSpaceForNewSaveGame(true)
		else
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_notEnoughSpaceForNewSavegame"),
				callback = self.onYesNoNotEnoughSpaceForNewSaveGame,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:onYesNoInstallMissingModsOptional(yes)
	if yes then
		self:startCurrentSavegame()
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:onOkZipModsOptional()
	self:startCurrentSavegame()
end

function CareerScreen:startCurrentSavegame(useStartMissionInfo)
	local savegame = self.currentSavegame

	if useStartMissionInfo then
		savegame.playerStyle = self.startMissionInfo.playerStyle

		savegame:setMapId(self.startMissionInfo.mapId)
		savegame:setDifficulty(self.startMissionInfo.difficulty)
	end

	savegame.isNewSPCareer = false

	if not savegame.isValid then
		savegame.startSiloAmounts = {}

		if not g_isPresentationVersion then
			if savegame.difficulty == 1 then
				local low = 8000
				local high = 16000
				savegame.startSiloAmounts.wheat = math.random(low, high)
				savegame.startSiloAmounts.barley = math.random(low, high)
				savegame.startSiloAmounts.canola = math.random(low, high)
				savegame.startSiloAmounts.maize = math.random(low, high)
				savegame.startSiloAmounts.oat = math.random(low, high)
				savegame.startSiloAmounts.soybean = math.random(low, high)
				savegame.startSiloAmounts.sunflower = math.random(low, high)
			end
		else
			savegame.startSiloAmounts.wheat = 40000
		end

		savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
		savegame.itemsXMLLoad = savegame.defaultItemsXMLFilename
		savegame.onCreateObjectsXMLLoad = nil
		savegame.environmentXML = nil
		savegame.economyXMLLoad = nil
		savegame.farmlandXMLLoad = nil
		savegame.npcXMLLoad = nil
		savegame.npcXMLLoad = nil
		savegame.densityMapHeightXMLLoad = nil
		savegame.treePlantXMLLoad = nil
		savegame.timeScale = g_platformSettingsManager:getSetting("defaultTimeScale", 5)
		savegame.dirtInterval = 3
		savegame.trafficEnabled = true
		savegame.fieldJobMissionCount = 0
		savegame.fieldJobMissionByNPC = 0
		savegame.transportMissionCount = 0
		savegame.eastState1 = 0
		savegame.eastState2 = 0

		if g_isPresentationVersion then
			savegame.isNewSPCareer = false
		else
			savegame.isNewSPCareer = true
		end
	end

	local missionInfo = savegame
	local missionDynamicInfo = {
		isMultiplayer = self.isMultiplayer,
		autoSave = false
	}

	if self.isMultiplayer and g_modManager:getNumOfValidMods() > 0 or not self.isMultiplayer and g_modManager:getNumOfMods() > 0 then
		g_modSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)

		self.startMissionInfo.canStart = false

		self:changeScreen(ModSelectionScreen, CareerScreen)
	else
		missionDynamicInfo.mods = {}

		self:startGame(missionInfo, missionDynamicInfo)
	end
end

function CareerScreen:startGame(missionInfo, missionDynamicInfo)
	if self.isMultiplayer then
		self.startMissionInfo.createGame = true

		g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		self:changeScreen(CreateGameScreen)
	else
		g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		self:changeScreen(MPLoadingScreen)
		g_mpLoadingScreen:loadSavegameAndStart()
	end

	self.startMissionInfo:reset()
end

function CareerScreen:onSavegameDeleted(errorCode)
	self.recreateListOnOpen = false

	self:changeScreen(CareerScreen)

	self.recreateListOnOpen = true

	g_gui:showMessageDialog({
		visible = false
	})

	self.selectedIndexToRestore = self.currentSavegame.savegameIndex
	self.currentSavegame = nil
	self.ignoreCorruptOnNextUpdate = not self.savegameController:isStorageDeviceUnavailable()

	self:recreateSavegameList()
end

function CareerScreen:deleteCurrentSavegame()
	g_gui:showMessageDialog({
		isCloseAllowed = false,
		visible = true,
		text = g_i18n:getText("ui_deletingSavegame"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.savegameController:deleteSavegame(self.selectedIndex, self.onSavegameDeleted, self)
end

function CareerScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer

	if self.isMultiplayer then
		self:setReturnScreen("MultiplayerScreen")
	else
		self:setReturnScreen("MainScreen")
	end
end

function CareerScreen:onAchievementsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.achievementsButton)
	g_mainScreen:onAchievementsClick(element)
end

function CareerScreen:onCreditsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.creditsButton)
	g_mainScreen:onCreditsClick(element)
end

function CareerScreen:updateAchievementsButtonState()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		self.achievementsButton:setDisabled(not getIsUserSignedIn())
	end
end
