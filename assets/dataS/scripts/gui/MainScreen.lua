MainScreen = {}
local MainScreen_mt = Class(MainScreen, ScreenElement)
MainScreen.IMAGES = {
	{
		sizeFactor = 1,
		filename = "dataS2/menu/menuTractors/menuTractor_01.png"
	}
}
MainScreen.CONTROLS = {
	NOTIFICATION_INDEX_STATE = "indexState",
	TUTORIALSBUTTON = "tutorialsButton",
	CHANGEUSERBUTTON = "changeUserButton",
	DOWNLOADMODSBUTTON = "downloadModsButton",
	NOTIFICATION_DATE = "notificationDate",
	MULTIPLAYERBUTTON = "multiplayerButton",
	BACKGROUND_BLURRY = "backgroundBlurImage",
	NOTIFICATION_TITLE = "notificationTitle",
	CAREERBUTTON = "careerButton",
	ACHIEVEMENTSBUTTON = "achievementsButton",
	LOGO = "logo",
	SETTINGSBUTTON = "settingsButton",
	GAMER_TAG_ELEMENT = "gamerTagElement",
	NOTIFICATION_BOX = "notificationElement",
	NOTIFICATION_IMAGE = "notificationImage",
	BUTTON_NOTIFICATION_RIGHT = "notificationButtonRight",
	QUITBUTTON = "quitButton",
	GOOGLE_PLAY_BUTTON = "googlePlayButton",
	CREDITSBUTTON = "creditsButton",
	CHINA_AGE_RATING = "chinaAgeRating",
	BUTTON_BOX = "buttonBox",
	BUTTON_NOTIFICATION_OPEN = "notificationButtonOpen",
	BUTTON_NOTIFICATION_LEFT = "notificationButtonLeft",
	BACKGROUND_GLASSEDGE = "glassEdgeOverlay",
	BACKGROUND_IMAGE = "backgroundImage",
	NOTIFICATION_MESSAGE = "notificationMessage",
	BACKGROUND_TRACTOR = "backgroundTractor",
	STOREBUTTON = "storeButton"
}
MainScreen.NOTIFICATION_ANIMATION_DURATION = 500
MainScreen.NOTIFICATION_CHECK_DELAY = 500
MainScreen.NOTIFICATION_ANIM_DELAY = 2000

function MainScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or MainScreen_mt)
	self.startMissionInfo = startMissionInfo
	self.firstTimeOpened = true
	self.lastActiveButton = nil
	self.blendDir = 0
	self.blendingAlpha = 1
	self.disableMultiplayer = false
	self.showGamepadModeDialog = true
	self.showHeadTrackingDialog = true
	self.notificationShowAnimation = TweenSequence.NO_SEQUENCE
	self.notificationsHidePosition = {
		2,
		0
	}

	self:registerControls(MainScreen.CONTROLS)

	return self
end

function MainScreen:onCreate()
	self.lastButtonPressed = nil
	self.isBackAllowed = false
	local imageIndex = math.random(1, #MainScreen.IMAGES)

	self.backgroundTractor:setImageFilename(MainScreen.IMAGES[imageIndex].filename)
	self.backgroundTractor:setSize(self.backgroundTractor.size[1] * MainScreen.IMAGES[imageIndex].sizeFactor, self.backgroundTractor.size[2] * MainScreen.IMAGES[imageIndex].sizeFactor)
	self:setupNotifications()
end

function MainScreen:onClickBack(forceBack, usedMenuButton)
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_youWantToQuitGame"),
			callback = self.onYesNoQuitGame,
			target = self
		})

		return false
	else
		return MainScreen:superClass().onClickBack(self)
	end
end

function MainScreen:onYesNoQuitGame(yes)
	if yes then
		requestExit()
	end
end

function MainScreen:onCreateGameVersion(element)
	if g_isServerStreamingVersion then
		element:setText("")
	else
		local gameVersionTxt = g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")"

		element:setText(gameVersionTxt)
	end
end

function MainScreen:onHighlight(element)
	if not GS_IS_CONSOLE_VERSION then
		FocusManager:setFocus(element)
	end
end

function MainScreen:onClose()
	MainScreen:superClass().onClose(self)
	g_inputBinding:removeActionEventsByTarget(self)
	GuiOverlay.deleteOverlay(self.notificationImage.overlay)
	g_messageCenter:unsubscribe(MessageType.USER_PROFILE_CHANGED, self)
end

function MainScreen:onOpen()
	MainScreen:superClass().onOpen(self)
	setPresenceMode(PresenceModes.PRESENCE_IDLE)
	flushWebCache()
	self.chinaAgeRating:setVisible(g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP")
	self:resetNotifications()

	local buttonSetup = {
		self.careerButton,
		self.multiplayerButton,
		self.tutorialsButton,
		self.downloadModsButton,
		self.achievementsButton,
		self.settingsButton,
		self.creditsButton,
		self.quitButton
	}

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		buttonSetup = {
			self.careerButton,
			self.multiplayerButton,
			self.tutorialsButton,
			self.downloadModsButton,
			self.achievementsButton,
			self.storeButton,
			self.settingsButton,
			self.creditsButton,
			self.changeUserButton
		}
	elseif GS_IS_CONSOLE_VERSION then
		buttonSetup = {
			self.careerButton,
			self.multiplayerButton,
			self.tutorialsButton,
			self.downloadModsButton,
			self.achievementsButton,
			self.storeButton,
			self.settingsButton,
			self.creditsButton
		}
	elseif g_isServerStreamingVersion then
		buttonSetup = {
			self.careerButton,
			self.achievementsButton,
			self.storeButton,
			self.creditsButton
		}
	elseif GS_IS_MOBILE_VERSION then
		if g_buildTypeParam == "CHINA_GAPP" then
			buttonSetup = {
				self.careerButton,
				self.achievementsButton
			}
		else
			buttonSetup = {
				self.careerButton,
				self.achievementsButton,
				self.creditsButton
			}
		end
	end

	if g_isPresentationVersionHideMenuButtons then
		self.multiplayerButton:setDisabled(true)
		self.downloadModsButton:setDisabled(true)
		self.tutorialsButton:setDisabled(true)
		self.achievementsButton:setDisabled(true)

		if not GS_IS_CONSOLE_VERSION then
			self.settingsButton:setDisabled(true)
		end

		self.quitButton:setDisabled(true)
		self.storeButton:setDisabled(true)
	end

	for k, button in pairs(buttonSetup) do
		button:setVisible(true)

		local topButton, bottomButton = nil

		for i = 1, table.getn(buttonSetup) - 1 do
			local candidateI = k - i

			if candidateI < 1 then
				candidateI = candidateI + table.getn(buttonSetup)
			end

			if not buttonSetup[candidateI].disabled then
				topButton = buttonSetup[candidateI]

				break
			end
		end

		for i = 1, table.getn(buttonSetup) - 1 do
			local candidateI = k + i

			if table.getn(buttonSetup) < candidateI then
				candidateI = candidateI - table.getn(buttonSetup)
			end

			if not buttonSetup[candidateI].disabled then
				bottomButton = buttonSetup[candidateI]

				break
			end
		end
	end

	self.buttonBox:invalidateLayout()

	if self.firstTimeOpened then
		self.firstTimeOpened = false

		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		end
	end

	if not g_menuMusicIsPlayingStarted then
		g_menuMusicIsPlayingStarted = true

		playStreamedSample(g_menuMusic, 0)
	end

	if g_isServerStreamingVersion then
		self.notificationElement.visible = false
		self.notificationElement.disabled = true
	end

	FocusManager:lockFocusInput(InputAction.MENU_ACCEPT, 150)
	self:setSoundSuppressed(true)

	if self.lastActiveButton ~= nil then
		FocusManager:unsetFocus(self.lastActiveButton)
		FocusManager:setFocus(self.lastActiveButton)
	end

	self:setSoundSuppressed(false)
	self:updateGooglePlayState()

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID then
		g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.updateGooglePlayState, self)
	end

	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	g_messageCenter:publish(MessageType.GUI_MAIN_SCREEN_OPEN)
end

function MainScreen:setupNotifications()
	local showPosition = {
		self.notificationElement.position[1],
		self.notificationElement.position[2]
	}
	self.notificationsHidePosition = {
		self.notificationElement.position[1] + self.notificationElement.size[1],
		self.notificationElement.position[2]
	}
	local anim = TweenSequence.new(self)

	anim:addInterval(MainScreen.NOTIFICATION_ANIM_DELAY)

	local moveIn = MultiValueTween:new(self.notificationElement.setPosition, self.notificationsHidePosition, showPosition, MainScreen.NOTIFICATION_ANIMATION_DURATION)

	anim:addTween(moveIn)
	moveIn:setTarget(self.notificationElement)
	anim:addCallback(self.setNotificationButtonsDisabled, false)

	self.notificationShowAnimation = anim

	self:resetNotifications()
end

function MainScreen:setNotificationButtonsDisabled(isDisabled)
	local leftRightDisabled = isDisabled or #self.notifications < 2

	self.notificationButtonLeft:setDisabled(leftRightDisabled)
	self.notificationButtonRight:setDisabled(leftRightDisabled)
	self.notificationButtonOpen:setDisabled(isDisabled)
end

function MainScreen:resetNotifications()
	self.notificationsReady = false
	self.notificationsCheckTimer = 0
	self.notifications = {}
	self.activeNotification = 0

	self.notificationShowAnimation:reset()
	self:setNotificationButtonsDisabled(true)
	self.indexState:setVisible(false)
	self.notificationElement:setPosition(unpack(self.notificationsHidePosition))
end

function MainScreen:onYesNoUseGamepadMode(yes)
	g_gameSettings:setValue("gamepadEnabledSetByUser", true)
	g_gameSettings:setValue("isGamepadEnabled", yes)
	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function MainScreen:onYesNoUseHeadTracking(yes)
	g_gameSettings:setValue("headTrackingEnabledSetByUser", true)
	g_gameSettings:setValue("isHeadTrackingEnabled", yes)
	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function MainScreen:onMultiplayerClick(element)
	self.lastActiveButton = element

	resetMultiplayerChecks()
	self:onMultiplayerClickPerform()
end

function MainScreen:onMultiplayerClickPerform()
	if not isGameFullyInstalled() then
		showGameInstallProgress()

		return
	end

	if masterServerConnectFront == nil then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
		restartApplication("")
	else
		if not PlatformPrivilegeUtil.checkMultiplayer(self.onMultiplayerClickPerform, self) then
			return
		end

		self.startMissionInfo:reset()
		g_gui:setIsMultiplayer(true)
		g_gui:showGui("MultiplayerScreen")
	end
end

function MainScreen:onCareerClick(element)
	self.lastActiveButton = element

	if not isGameFullyInstalled() then
		showGameInstallProgress()

		return
	end

	self.startMissionInfo:reset()
	g_gui:setIsMultiplayer(false)
	self:changeScreen(CareerScreen)
end

function MainScreen:onTutorialsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("TutorialScreen")
end

function MainScreen:onDownloadModsClick(element)
	self.lastActiveButton = element

	resetMultiplayerChecks()
	self:onDownloadModsClickPerform()
end

function MainScreen:onDownloadModsClickPerform()
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		if not PlatformPrivilegeUtil.checkModDownload(self.onDownloadModsClickPerform, self) then
			return
		end

		modDownloadManagerUpdateSync(true)
		g_gui:showGui("ModHubScreen")
	end
end

function MainScreen:onAchievementsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("AchievementsScreen")
end

function MainScreen:onStoreClick(element)
	self.lastActiveButton = element

	if storeHasNativeGUI() and (getNetworkError() ~= nil or not storeShow("")) then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcStoreNotConnected"),
			callback = MainScreen.onStoreFailedOk,
			target = self
		})
	end
end

function MainScreen:onStoreFailedOk()
	g_gui:showGui("MainScreen")
end

function MainScreen:onSettingsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("SettingsScreen")
end

function MainScreen:onCreditsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("CreditsScreen")
end

function MainScreen:onChangeUserClick()
	g_gamepadSigninScreen.forceShowSigninGui = true

	g_gui:showGui("GamepadSigninScreen")
end

function MainScreen:onQuitClick()
	doExit()
end

function MainScreen:cycleNotification(signedDelta)
	self.activeNotification = self.activeNotification + signedDelta

	if self.activeNotification > #self.notifications then
		self.activeNotification = 1
	elseif self.activeNotification < 1 then
		self.activeNotification = #self.notifications
	end

	self:assignNotificationData()
end

function MainScreen:onClickMenuExtra1()
	local eventUnused = MainScreen:superClass().onClickMenuExtra1(self)

	if eventUnused then
		self:onClickOpenNotification()

		eventUnused = false
	end

	return eventUnused
end

function MainScreen:onClickNextNotification(element)
	self:cycleNotification(1)
end

function MainScreen:onClickPreviousNotification(element)
	self:cycleNotification(-1)
end

function MainScreen:onClickOpenNotification()
	if #self.notifications > 0 then
		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			g_gui:showGui("SettingsScreen")
			g_settingsScreen:showDisplaySettings()
		elseif storeHasNativeGUI() then
			if not storeShow(self.notifications[self.activeNotification].url) then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_dlcStoreNotConnected"),
					callback = MainScreen.onStoreFailedOk,
					target = self
				})
			end
		else
			openWebFile(self.notifications[self.activeNotification].url, "")
		end
	end
end

function MainScreen:onDlcCorruptClick()
	g_gui:showGui("MainScreen")
end

function MainScreen:onClickChinaAgeRating()
	g_gui:showChinaAgeRatingDialog({
		text = g_i18n:getText("info_chinaAgeRating")
	})
end

function MainScreen:updateNotifications(dt)
	if self.notificationsReady and #self.notifications > 0 and not self.notificationShowAnimation:getFinished() then
		self.notificationShowAnimation:update(dt)
	end

	if not self.notificationsReady then
		self.notificationsCheckTimer = self.notificationsCheckTimer + dt

		if MainScreen.NOTIFICATION_CHECK_DELAY < self.notificationsCheckTimer then
			self.notificationsCheckTimer = 0
			self.notificationsReady = notificationsLoaded()

			if self.notificationsReady then
				local notificationCount = getNumOfNotifications()

				for i = 0, notificationCount - 1 do
					local notification = {
						url = "",
						message = "",
						image = "",
						date = "",
						title = ""
					}
					notification.title, notification.message, notification.url, notification.image, notification.date = getNotification(i)

					if notification.title ~= "" and notification.message ~= "" then
						table.insert(self.notifications, notification)
					end
				end

				if #self.notifications > 0 then
					self.activeNotification = 1

					self.indexState:setPageCount(#self.notifications, self.activeNotification)
					self.indexState:setVisible(#self.notifications > 1)
					self:assignNotificationData()
					self.notificationShowAnimation:start()
				else
					self.indexState:setPageCount(0)
				end
			end
		end
	end
end

function MainScreen:updateFading(dt)
	if self.blendDir ~= 0 then
		self.blendingAlpha = MathUtil.clamp(self.blendingAlpha + self.blendDir * dt / 500, 0, 1)
		local state = 0.1 + 0.9 * self.blendingAlpha

		self.backgroundImage:setImageColor(nil, state, state, state, 1)
		self.backgroundTractor:setImageColor(nil, state, state, state, 1)
		self.backgroundBlurImage:setImageColor(nil, state, state, state, 1)
		self.glassEdgeOverlay:setImageColor(nil, state, state, state, nil)

		if self.blendingAlpha == 1 or self.blendingAlpha == 0 then
			self.blendDir = 0

			if self.blendingAlpha == 1 then
				FocusManager:setFocus(self.lastActiveButton)
			end
		end
	end
end

function MainScreen:update(dt)
	MainScreen:superClass().update(self, dt)
	modDownloadManagerUpdateSync(false)

	if self.showGamepadModeDialog and not GS_IS_CONSOLE_VERSION and not g_gameSettings:getValue("gamepadEnabledSetByUser") and getNumOfGamepads() > 0 and not GS_IS_MOBILE_VERSION then
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_activateGamepadsTitle"),
			text = g_i18n:getText("ui_activateGamepads"),
			callback = self.onYesNoUseGamepadMode,
			target = self
		})

		self.showGamepadModeDialog = false
	end

	if self.showHeadTrackingDialog and not GS_IS_CONSOLE_VERSION and not g_gameSettings:getValue("headTrackingEnabledSetByUser") and isHeadTrackingAvailable() then
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_activateHeadTrackingTitle"),
			text = g_i18n:getText("ui_activateHeadTracking"),
			callback = self.onYesNoUseHeadTracking,
			target = self
		})

		self.showHeadTrackingDialog = false
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		self.gamerTagElement:setText(g_gameSettings:getValue("nickname"))
	end

	if GS_IS_CONSOLE_VERSION and not g_isPresentationVersion then
		if getNetworkError() then
			if self.storeButton:getIsActive() then
				self.storeButton:setDisabled(true)
			end
		elseif not self.storeButton:getIsActive() then
			self.storeButton:setDisabled(false)
		end
	end

	if self.isFirstOpen == nil then
		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		end

		self.isFirstOpen = true
	end

	if not g_isServerStreamingVersion and not g_isPresentationVersion then
		self:updateNotifications(dt)
	end

	if GS_IS_CONSOLE_VERSION then
		if storeHaveDlcsChanged() or haveModsChanged() or g_forceNeedsDlcsAndModsReload then
			g_forceNeedsDlcsAndModsReload = false

			reloadDlcsAndMods()
			self:resetNotifications()
		end
	elseif haveModsChanged() and not self.restartModDialogShown then
		self.restartModDialogShown = true

		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_modsChangedTitle"),
			text = g_i18n:getText("ui_modsChangedText") .. "\n\n" .. g_i18n:getText("ui_modsChangedRestartQuestion"),
			callback = self.onRestartModDialog,
			target = self
		})
	end

	if storeAreDlcsCorrupted() then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcsCorruptRedownload"),
			callback = self.onDlcCorruptClick,
			target = self
		})
	end

	self:updateFading(dt)
end

function MainScreen:onRestartModDialog(yes)
	if yes then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
		restartApplication("")
	end
end

function MainScreen:assignNotificationData()
	if self.activeNotification > 0 and self.activeNotification <= #self.notifications then
		if not GS_IS_CONSOLE_VERSION then
			self.notificationMessage:setText(self.notifications[self.activeNotification].message)
		else
			self.notificationMessage:setText(g_i18n:getText("notification_nowAvailable"))
		end

		self.notificationTitle:setText(self.notifications[self.activeNotification].title)

		local imageFile = self.notifications[self.activeNotification].image

		if imageFile == "graphicsOptionsImage" then
			imageFile = "dataS2/menu/notification_dummy.png"
		end

		self.notificationImage:setImageFilename(imageFile)

		local dateStr = self.notifications[self.activeNotification].date

		if g_languageShort ~= "en" and dateStr ~= "" then
			local dateParts = StringUtil.splitString("-", self.notifications[self.activeNotification].date)

			if g_languageShort == "de" then
				dateStr = string.format("%s.%s.%s", dateParts[3], dateParts[2], dateParts[1])
			else
				dateStr = string.format("%s/%s/%s", dateParts[3], dateParts[2], dateParts[1])
			end
		end

		self.notificationDate:setText(dateStr)

		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			self.notificationButtonOpen:setText(g_i18n:getText("button_settings"))
		elseif storeHasNativeGUI() then
			self.notificationButtonOpen:setText(g_i18n:getText("button_dlcStore"))
		else
			self.notificationButtonOpen:setText(g_i18n:getText("button_visitWebsite"))
		end

		self.indexState:setPageIndex(self.activeNotification)
	end
end

function MainScreen:onClickGooglePlayButton()
	if getIsUserSignedIn() then
		userSignout()
	else
		requestUserSignin()
	end

	g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
end

function MainScreen:updateGooglePlayState()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID and g_buildTypeParam ~= "CHINA_GAPP" and g_buildTypeParam ~= "CHINA" then
		if getIsUserSignedIn() then
			self.googlePlayButton:setText(getUserName())
			self.achievementsButton:setDisabled(false)
		else
			self.googlePlayButton:setText("")
			self.achievementsButton:setDisabled(true)
		end
	else
		self.googlePlayButton:setVisible(false)
	end
end
