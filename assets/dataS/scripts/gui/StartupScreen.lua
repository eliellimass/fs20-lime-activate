StartupScreen = {
	EVENTTYPE_VIDEO = 1,
	EVENTTYPE_PICTURE = 2
}
local StartupScreen_mt = Class(StartupScreen, ScreenElement)

function StartupScreen:new()
	local instance = FrameElement:new({}, StartupScreen_mt)

	return instance
end

function StartupScreen:onClose()
	self.videoElement:disposeVideo()
	self.pictureElement:setImageFilename(nil)

	self.pictureTimer = 0
	self.eventList = nil
	self.currentEventId = nil

	g_gameStateManager:setGameState(GameState.MENU_MAIN)
end

function StartupScreen:onOpen()
	self.eventList = {}

	if not g_isDevelopmentVersion then
		local giantsLogo = "dataS2/videos/GIANTSLogo.ogv"
		local focusLogo = "dataS2/videos/FOCUSLogo.ogv"

		if GS_IS_MOBILE_VERSION and (g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA") then
			self:addStartupPicture("cs", "dataS2/menu/chinaDisclaimer_cs.png", 3000, 3000, false, {
				1,
				1
			})
		end

		if not g_isServerStreamingVersion and GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_ANDROID and GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_IOS then
			self:addStartupVideo("en fr es jp ru it cs ct nl pt br tr kr de cz pl hu ro ea", focusLogo, false, {
				1,
				1
			})
		end

		if GS_IS_STEAM_VERSION then
			self:addStartupVideo("de cz pl hu ro", focusLogo, false, {
				1,
				1
			})
		end

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH and getGameTerritory() == "jp" then
			self:addStartupPicture(nil, "dataS2/menu/amuzioLogo.png", 3000)
		end

		if not g_isServerStreamingVersion and not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			self:addStartupVideo("de en cz pl fr es jp ru hu it cs ct nl pt br tr ro kr ea", "dataS2/videos/NvidiaLogo.ogv", false, {
				1,
				1
			})
		end

		if GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_ANDROID and GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_IOS then
			self:addStartupVideo("de en cz pl fr es jp ru hu it cs ct nl pt br tr ro kr ea", giantsLogo, false, {
				1,
				1
			})
		end
	end

	self.currentEventId = 0

	self:showNextEvent()
end

function StartupScreen:addStartupVideo(languagesString, filename, isFullscreen, size)
	if self:shouldAddEvent(languagesString) then
		local videoEvent = {
			filename = filename,
			fullscreen = isFullscreen,
			size = size,
			eventType = StartupScreen.EVENTTYPE_VIDEO
		}

		table.insert(self.eventList, videoEvent)
	end
end

function StartupScreen:addStartupPicture(languagesString, filename, duration, minDuration, isFullscreen, size)
	if self:shouldAddEvent(languagesString) then
		local pictureEvent = {
			filename = filename,
			duration = duration,
			minDuration = minDuration,
			fullscreen = isFullscreen,
			size = size,
			eventType = StartupScreen.EVENTTYPE_PICTURE
		}

		table.insert(self.eventList, pictureEvent)
	end
end

function StartupScreen:shouldAddEvent(languagesString)
	if GS_IS_CONSOLE_VERSION or not languagesString then
		return true
	else
		local languages = ListUtil.listToSet(StringUtil.splitString(" ", languagesString))

		return languages[g_languageShort] ~= nil
	end
end

function StartupScreen:onVideoElementCreated(videoElement)
	self.videoElement = videoElement

	function self.videoElement.mouseEvent()
	end

	function self.videoElement.keyEvent()
	end

	function self.videoElement.inputEvent()
	end

	self.videoElementCallback = videoElement.onEndVideoCallback

	self.videoElement:setVisible(false)
end

function StartupScreen:onPictureElementCreated(pictureElement)
	self.pictureElement = pictureElement

	self.pictureElement:setVisible(false)
end

function StartupScreen:showNextEvent()
	self.currentEventId = self.currentEventId + 1
	local nextEvent = self.eventList[self.currentEventId]

	if not nextEvent then
		return self:onStartupEnd()
	end

	if nextEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
		self.videoElement:setVisible(true)

		self.videoElement.onEndVideoCallback = self.videoElementCallback

		self.pictureElement:setVisible(false)
		self:playVideo(nextEvent)
	else
		self.pictureElement:setVisible(true)
		self.videoElement:setVisible(false)

		self.videoElement.onEndVideoCallback = nil

		self:showPicture(nextEvent)
	end
end

function StartupScreen:playVideo(videoEvent)
	self.videoElement:changeVideo(videoEvent.filename)

	local adjustedSizeX, adjustedSizeY = nil

	if videoEvent.fullscreen then
		adjustedSizeX = 1
		adjustedSizeY = 1
	elseif videoEvent.size == nil then
		adjustedSizeX = g_aspectScaleX
		adjustedSizeY = g_aspectScaleY
	else
		adjustedSizeX = videoEvent.size[1] * g_aspectScaleX
		adjustedSizeY = videoEvent.size[2] * g_aspectScaleY
	end

	self.videoElement:setSize(adjustedSizeX, adjustedSizeY)
	self.videoElement:playVideo()

	return true
end

function StartupScreen:showPicture(pictureEvent)
	self.pictureElement:setImageFilename(pictureEvent.filename)

	local adjustedSizeX, adjustedSizeY = nil

	if pictureEvent.fullscreen then
		adjustedSizeX = 1
		adjustedSizeY = 1
	elseif pictureEvent.size == nil then
		adjustedSizeX = g_aspectScaleX
		adjustedSizeY = g_aspectScaleY
	else
		adjustedSizeX = pictureEvent.size[1] * g_aspectScaleX
		adjustedSizeY = pictureEvent.size[2] * g_aspectScaleY
	end

	self.pictureElement:setSize(adjustedSizeX, adjustedSizeY)

	self.pictureTimer = pictureEvent.duration
end

function StartupScreen:getAllowSkipCurrentEvent()
	if self.currentEventId ~= nil then
		local currentEvent = self.eventList[self.currentEventId]

		if currentEvent ~= nil and currentEvent.eventType == StartupScreen.EVENTTYPE_PICTURE and currentEvent.minDuration ~= nil and self.pictureTimer > currentEvent.duration - currentEvent.minDuration then
			return false
		end
	end

	if not isGameFullyInstalled() then
		return false
	end

	return true
end

function StartupScreen:update(dt)
	if self.currentEventId ~= nil then
		local currentEvent = self.eventList[self.currentEventId]

		if currentEvent ~= nil and currentEvent.eventType == StartupScreen.EVENTTYPE_PICTURE then
			self.pictureTimer = self.pictureTimer - dt

			if self.pictureTimer <= 0 then
				self:onStartupEndEvent()
			end
		end
	end

	if not self:getAllowSkipCurrentEvent() then
		return
	end

	local anyButtonPressed = false

	for d = 1, getNumOfGamepads() do
		for i = 1, Input.MAX_NUM_BUTTONS do
			local isDown = getInputButton(i - 1, d - 1) > 0

			if isDown then
				anyButtonPressed = true

				break
			end
		end
	end

	if not anyButtonPressed then
		self.handledButtonPress = false
	end

	if not self.handledButtonPress and anyButtonPressed then
		self.handledButtonPress = true

		self:cancelCurrentEvent()
	end
end

function StartupScreen:mouseEvent(posX, posY, isDown, isUp, button)
	if isDown and self:getAllowSkipCurrentEvent() then
		self:cancelCurrentEvent()
	end
end

function StartupScreen:keyEvent(unicode, sym, modifier, isDown)
	if isDown and self:getAllowSkipCurrentEvent() then
		self:cancelCurrentEvent()
	end
end

function StartupScreen:cancelCurrentEvent()
	local currentEvent = self.eventList[self.currentEventId]

	if currentEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
		self.videoElement:stopVideo()
	end

	self:onStartupEndEvent()
end

function StartupScreen:onStartupEndEvent()
	self:showNextEvent()
end

function StartupScreen:onStartupEnd()
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		g_gui:showGui("GamepadSigninScreen")
	elseif g_buildTypeParam == "CHINA" or g_buildTypeParam == "CHINA_GAPP" then
		g_gui:showGui("ChinaSigninScreen")
	else
		g_gui:showGui("MainScreen")
	end
end

function StartupScreen:exposeControlsAsFields()
end
