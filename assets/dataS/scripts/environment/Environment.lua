Environment = {}
local Environment_mt = Class(Environment)

function Environment:onCreateSunLight(id)
	g_currentMission.environment.sunLightId = id
end

function Environment:onCreateWater(id)
	if Utils.getNoNil(getUserAttribute(id, "isMainWater"), false) then
		if g_currentMission.environment.water == nil then
			g_currentMission.environment.water = id
		else
			g_logManager:error("Main water plane already set. Delete user-attribute 'isMainWater' for '%s'!", getName(id))
		end
	end

	if not Utils.getNoNil(getUserAttribute(id, "useShapeObjectMask"), false) then
		setObjectMask(id, bitAND(getObjectMask(id), 4294967167.0))
	end

	local profileId = Utils.getPerformanceClassId()

	if profileId <= GS_PROFILE_MEDIUM or GS_IS_CONSOLE_VERSION then
		setReflectionMapScaling(id, 0, true)
	elseif profileId <= GS_PROFILE_HIGH then
		setReflectionMapObjectMasks(id, 512, 33554432, true)
	else
		setReflectionMapObjectMasks(id, 256, 16777216, true)
	end
end

function Environment:new(xmlFilename)
	local self = setmetatable({}, Environment_mt)

	g_messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChanged, self)

	self.xmlFilename = xmlFilename
	local xmlFile = loadXMLFile("TempConfig", xmlFilename)
	self.dayChangeListeners = {}
	self.hourChangeListeners = {}
	self.minuteChangeListeners = {}
	self.realHourChangeListeners = {}
	self.weatherChangeListeners = {}
	self.sunLightId = nil
	self.currentDay = 1
	self.dayLength = 86400000
	self.realHourLength = 3600000
	self.realHourTimer = self.realHourLength
	local startHour = Utils.getNoNil(getXMLFloat(xmlFile, "environment#startHour"), 8)
	local dayTime = 0

	if startHour ~= nil then
		dayTime = startHour * 60 * 60 * 1000
	end

	self:setEnvironmentTime(1, dayTime, false)

	self.dayNightCycle = Utils.getNoNil(getXMLBool(xmlFile, "environment#dayNightCycle"), true)
	self.nightStart = getXMLFloat(xmlFile, "environment#nightStart") or 21
	self.nightStartMinutes = self.nightStart * 60
	self.nightEnd = getXMLFloat(xmlFile, "environment#nightEnd") or 5.5
	self.nightEndMinutes = self.nightEnd * 60

	if self.dayNightCycle then
		self.lightUpdateInterval = 10000
		self.lastLightUpdate = 0
	end

	self.nightTimeScaleMultiplier = getXMLFloat(xmlFile, "environment#nightTimeScaleMultiplier") or 1

	self:loadSettings(xmlFile)

	self.timeUpdateInterval = 60000
	self.timeUpdateTime = 0
	self.isSunOn = true
	self.lightScale = 1
	self.rainSkyScale = 0
	self.visualRainScale = 0
	self.fogScale = 0
	self.firstTimeRun = false
	self.weather = Weather:new(xmlFilename, self)

	self.weather:setIsRainAllowed(not g_currentMission.isTutorialMission)
	self.weather:load(xmlFile, "environment")

	self.groundWetness = 0

	if g_currentMission:getIsServer() then
		addConsoleCommand("gsSetDayTime", "Sets the day time in hours", "consoleCommandSetDayTime", self)
		addConsoleCommand("gsReloadEnvironment", "Reloads environment", "consoleCommandReloadEnvironment", self)
	end

	addConsoleCommand("gsSetFixedExposureSettings", "Sets fixed exposure settings", "consoleCommandSetFixedExposureSettings", self)
	delete(xmlFile)

	return self
end

function Environment:loadSettings(xmlFile)
	self.sunHeightAngle = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "environment#sunHeightAngle"), -70))
	self.lastLightUpdate = 0

	if self.dayNightCycle then
		local function radLoadFunc(xmlFile, key)
			local frame = loadInterpolator1Curve(xmlFile, key)
			frame[1] = math.rad(frame[1])

			return frame
		end

		self.sunRotCurve = AnimCurve:new(linearInterpolator1)

		self.sunRotCurve:loadCurveFromXML(xmlFile, "environment.sunRotation", radLoadFunc)

		local heightAngleLimitRotation = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "environment.sunRotation#heightAngleLimitRotation"), 60))
		local heightAngleLimitRotationStart = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "environment.sunRotation#heightAngleLimitRotationStart"), 56))
		local heightAngleLimitRotationEnd = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "environment.sunRotation#heightAngleLimitRotationEnd"), 80))
		_, self.sunHeightLimit, _ = mathEulerRotateVector(self.sunHeightAngle, 0, heightAngleLimitRotation, 0, 0, 1)
		_, self.sunHeightLimitStart, _ = mathEulerRotateVector(self.sunHeightAngle, 0, heightAngleLimitRotationStart, 0, 0, 1)
		_, self.sunHeightLimitEnd, _ = mathEulerRotateVector(self.sunHeightAngle, 0, heightAngleLimitRotationEnd, 0, 0, 1)
		self.lighting = Lighting:new(self)

		self.lighting:load(xmlFile, "environment")

		self.baseLighting = self.lighting
	end
end

function Environment:delete()
	self.weather:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsSetDayTime")
	removeConsoleCommand("gsReloadEnvironment")
	removeConsoleCommand("gsSetFixedExposureSettings")
end

function Environment:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key .. ".dayTime", self.dayTime / 60000)
	setXMLInt(xmlFile, key .. ".currentDay", self.currentDay)
	setXMLInt(xmlFile, key .. ".realHourTimer", self.realHourTimer)
	self.weather:saveToXMLFile(xmlFile, key .. ".weather")
end

function Environment:loadFromXMLFile(xmlFile, key)
	local dayTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".dayTime"), 400)
	local currentDay = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentDay"), 1)

	self:setEnvironmentTime(currentDay, dayTime * 1000 * 60, false)

	self.realHourTimer = Utils.getNoNil(getXMLInt(xmlFile, key .. ".realHourTimer"), 3600000)

	self.weather:loadFromXMLFile(xmlFile, key .. ".weather")
end

function Environment:update(dt)
	self.weather:update(dt)

	self.groundWetness = self.weather:getGroundWetness()
	local speedUp = 1
	self.dayTime = self.dayTime + dt * g_currentMission:getEffectiveTimeScale() * speedUp
	local timeHoursF = self.dayTime / 3600000 + 0.0001
	local timeHours = math.floor(timeHoursF)
	local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
	local dtMinutes = dt / 60000 * g_currentMission:getEffectiveTimeScale() * speedUp

	if timeMinutes ~= self.currentMinute then
		while timeMinutes ~= self.currentMinute do
			self.currentMinute = self.currentMinute + 1

			if self.currentMinute >= 60 then
				self.currentMinute = 0
			end

			for _, listener in ipairs(self.minuteChangeListeners) do
				listener:minuteChanged(self.currentMinute)
			end

			g_currentMission:onMinuteChanged(self.currentMinute)
		end
	end

	if timeHours ~= self.currentHour then
		self.currentHour = timeHours

		if self.currentHour == 24 then
			self.currentHour = 0
		end

		for _, listener in ipairs(self.hourChangeListeners) do
			listener:hourChanged()
		end

		g_messageCenter:publish(MessageType.HOUR_CHANGED, self.currentHour)
		g_currentMission:onHourChanged()
	end

	if self.dayTime > 86400000 then
		self.dayTime = self.dayTime - 86400000
		self.currentDay = self.currentDay + 1

		for _, listener in ipairs(self.dayChangeListeners) do
			listener:dayChanged()
		end

		g_messageCenter:publish(MessageType.DAY_CHANGED, self.currentDay)
		g_currentMission:onDayChanged()
	end

	self.realHourTimer = self.realHourTimer - dt

	if self.realHourTimer <= 0 then
		for _, listener in ipairs(self.realHourChangeListeners) do
			listener:realHourChanged()
		end

		self.realHourTimer = self.realHourLength
	end

	if self.lighting ~= nil then
		self.lighting:setCloudCoverage(self.weather:getGlobalCloudCoverate())
		self.lighting:update(dt)
	end

	self:updateSceneParameters()

	if g_server ~= nil then
		self.timeUpdateTime = self.timeUpdateTime + dt

		if self.timeUpdateInterval < self.timeUpdateTime then
			g_server:broadcastEvent(EnvironmentTimeEvent:new(self.currentDay, self.dayTime))

			self.timeUpdateTime = 0
		end

		if GS_IS_MOBILE_VERSION then
			local dayMinutes = self.dayTime / 60000
			local isNight = self.nightStartMinutes <= dayMinutes or dayMinutes < self.nightEndMinutes

			if isNight ~= self.lastNightState then
				g_currentMission:setTimeScaleMultiplier(isNight and self.nightTimeScaleMultiplier or 1)
			end

			self.lastNightState = isNight
		end
	end
end

function Environment:updateSceneParameters()
	if self.dayNightCycle and self.sunLightId ~= nil then
		local dayMinutes = self.dayTime / 60000

		if self.lightUpdateInterval < math.abs(self.dayTime - self.lastLightUpdate) then
			local sunRotation = self.sunRotCurve:get(dayMinutes)
			local dx, dy, dz = mathEulerRotateVector(self.sunHeightAngle, 0, sunRotation, 0, 0, 1)

			if dy < self.sunHeightLimitStart then
				if dy <= self.sunHeightLimitEnd then
					dy = self.sunHeightLimit
				else
					local limitAlpha = (dy - self.sunHeightLimitEnd) / (self.sunHeightLimitStart - self.sunHeightLimitEnd)
					dy = self.sunHeightLimit + limitAlpha * (self.sunHeightLimitStart - self.sunHeightLimit)
				end

				local scale = math.sqrt((1 - dy * dy) / (dx * dx + dz * dz))
				dx = dx * scale
				dz = dz * scale
			end

			setDirection(self.sunLightId, dx, dy, dz, 0, 1, 0)

			local x = 0
			local y = 0

			if dayMinutes < 360 then
				y = 4.713 + 1.571 * dayMinutes / 360
			elseif dayMinutes < 1080 then
				y = 3.142 + 3.142 * (1 - (dayMinutes - 360) / 720)
			else
				y = 3.142 + 1.571 * (dayMinutes - 1080) / 360
			end

			if dayMinutes < 480 then
				x = x + 1.571 * (1 - dayMinutes / 480)
			elseif dayMinutes > 960 then
				x = x + 1.571 * (dayMinutes - 960) / 480
			end

			for index, entry in pairs(g_currentMission.fruits) do
				if entry ~= nil and entry.id ~= nil then
					local fruitType = g_fruitTypeManager:getFruitTypeByIndex(index)

					if fruitType ~= nil and fruitType.alignsToSun then
						setShaderParameter(getChildAt(entry.id, 0), "plantRotate", x, y, 0, 0)
					end
				end
			end

			self.lastLightUpdate = self.dayTime
		end

		local newIsSunOn = self.nightStartMinutes > dayMinutes and dayMinutes >= self.nightEndMinutes

		if self.isSunOn ~= newIsSunOn then
			self.isSunOn = newIsSunOn

			for _, listener in ipairs(self.weatherChangeListeners) do
				listener:weatherChanged()
			end
		end
	end
end

function Environment:setCustomLighting(lighting)
	if self.lighting ~= nil then
		self.lighting:reset()
	end

	self.lighting = lighting or self.baseLighting

	self.lighting:setCloudCoverage(self.weather:getGlobalCloudCoverate())
	self.lighting:update(1, true)

	self.lastLightUpdate = -99999999
end

function Environment:getDayAndDayTime(dayTime, dayOffset)
	local newDayOffset, newDayTime = math.modf(dayTime / self.dayLength)

	return dayOffset + newDayOffset, newDayTime * self.dayLength
end

function Environment:setEnvironmentTime(currentDay, dayTime, isDelta)
	self.currentDay = currentDay
	self.dayTime = dayTime

	if not isDelta then
		while self.dayTime > 86400000 do
			self.dayTime = self.dayTime - 86400000
			self.currentDay = self.currentDay + 1
		end

		local timeHoursF = self.dayTime / 3600000 + 0.0001
		self.currentHour = math.floor(timeHoursF)
		self.currentMinute = math.floor((timeHoursF - self.currentHour) * 60)
	end
end

function Environment:getEnvironmentTime()
	local minutesString = string.format("%02d", self.currentMinute)

	return tonumber(self.currentHour .. "." .. minutesString)
end

function Environment:addDayChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.dayChangeListeners, listener)
	end
end

function Environment:removeDayChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.dayChangeListeners, listener)
	end
end

function Environment:addHourChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.hourChangeListeners, listener)
	end
end

function Environment:removeHourChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.hourChangeListeners, listener)
	end
end

function Environment:addRealHourChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.realHourChangeListeners, listener)
	end
end

function Environment:removeRealHourChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.realHourChangeListeners, listener)
	end
end

function Environment:addMinuteChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.minuteChangeListeners, listener)
	end
end

function Environment:removeMinuteChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.minuteChangeListeners, listener)
	end
end

function Environment:addWeatherChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.weatherChangeListeners, listener)
	end
end

function Environment:removeWeatherChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.weatherChangeListeners, listener)
	end
end

function Environment:onGameStateChanged(newGameState, oldGameState)
	if newGameState == GameState.MENU_SHOP_CONFIG then
		if self.sunLightId ~= nil then
			setVisibility(self.sunLightId, false)
		end
	elseif self.sunLightId ~= nil then
		setVisibility(self.sunLightId, true)
	end
end

function Environment:consoleCommandSetDayTime(dayTime)
	if g_currentMission:getIsServer() then
		dayTime = tonumber(dayTime)

		if dayTime ~= nil then
			self:setEnvironmentTime(self.currentDay, math.floor(dayTime * 1000 * 60 * 60), false)

			self.lastLightUpdate = 0

			g_server:broadcastEvent(EnvironmentTimeEvent:new(self.currentDay, self.dayTime))

			return "DayTime = " .. dayTime
		else
			return "Invalid arguments. Arguments: dayTime[h]"
		end
	end
end

function Environment:consoleCommandReloadEnvironment()
	local xmlFile = loadXMLFile("TempConfig", self.xmlFilename)
	local a = self.lighting.colorGradingFileCurve
	local b = self.lighting.envMapBasePath
	local c = self.lighting.envMapTimes

	self:loadSettings(xmlFile)

	self.lighting.envMapTimes = c
	self.lighting.envMapBasePath = b
	self.lighting.colorGradingFileCurve = a

	delete(xmlFile)

	return "reloaded environment"
end

function Environment:consoleCommandSetFixedExposureSettings(keyValue, minExposure, maxExposure)
	keyValue = tonumber(keyValue)
	minExposure = tonumber(minExposure)
	maxExposure = tonumber(maxExposure)
	local ret = nil

	if keyValue ~= nil then
		if minExposure ~= nil then
			if maxExposure == nil then
				maxExposure = minExposure
			end

			local minLuminance = keyValue / math.pow(2, maxExposure)
			local maxLuminance = keyValue / math.pow(2, minExposure)
			ret = string.format("Enabled fixed exposure settings (key %.2f exposure [%.2f %.2f] [%.4f %.4f])", keyValue, minExposure, maxExposure, minLuminance, maxLuminance)
		else
			maxExposure = nil
			ret = string.format("Enabled fixed exposure key %.2f", keyValue)
		end
	else
		minExposure, maxExposure = nil
		ret = "Disabled fixed exposure settings"
	end

	self.baseLighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)

	if self.lighting == self.baseLighting then
		self.baseLighting:updateExposureSettings()
	end

	return ret
end
