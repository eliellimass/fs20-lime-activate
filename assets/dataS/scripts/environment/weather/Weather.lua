Weather = {
	DEBUG_ENABLED = false,
	TEMPERATURE_STABLE_CHANGE = 2,
	SEND_BITS_NUM_OBJECTS = 8,
	SEND_BITS_OBJECT_INDEX = 3,
	SEND_BITS_OBJECT_VARIATION_INDEX = 4,
	SEND_BITS_WIND_INDEX = 4,
	SEND_BITS_TEMPERATURE = 6,
	SEND_BITS_DURATION = 6,
	SEND_BITS_STARTTIME = 11,
	CHANGE_DURATION = 7200000,
	MIN_WEATHER_DURATION = 5
}
local Weather_mt = Class(Weather)

function Weather:new(xmlFilename, owner, customMt)
	local self = setmetatable({}, customMt or Weather_mt)
	self.owner = owner
	self.xmlFilename = xmlFilename
	self.isRainAllowed = false
	self.typeToWeatherObject = {}
	self.weatherObjects = {}
	self.weightedWeatherObjects = {}
	self.forecastItems = {}
	self.cloudUpdater = CloudUpdater:new()
	self.temperatureUpdater = TemperatureUpdater:new(owner.dayLength)
	self.fogUpdater = FogUpdater:new()

	if getCloudQuality() == 0 then
		self.skyBoxUpdater = SkyBoxUpdater:new()
	end

	self.windObjects = {}
	self.windDuration = MathUtil.hoursToMs(8)
	self.windTimer = self.windDuration
	self.currentWindObjectIndex = 0
	self.windUpdater = WindUpdater:new()

	self.windUpdater:addWindChangedListener(self.cloudUpdater)

	self.weatherFrontUpdater = WeatherFrontUpdater:new(self.windUpdater)
	self.timeSinceLastRain = 9999999
	self.fog = {
		height = 200,
		minMieScale = 1,
		maxMieScale = 100,
		rainMieScale = 100,
		startHour = 4,
		endHour = 10,
		fadeOut = 4,
		fadeIn = 2,
		nightFactor = 0,
		dayFactor = 0
	}
	self.temperatureDebugGraph = Graph:new(24, 0.58, 0.5, 0.4, 0.4, 0, 40, true, "°", Graph.STYLE_LINES)

	self.temperatureDebugGraph:setColor(1, 0, 0, 1)
	self.temperatureDebugGraph:setBackgroundColor(0, 0, 0, 0.6)
	self.temperatureDebugGraph:setHorizontalLine(5, true, 1, 1, 1, 0.4)
	self.temperatureDebugGraph:setVerticalLine(6, true, 1, 1, 1, 0.3)

	self.temperatureDebugOverlayCurrent = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

	setOverlayColor(self.temperatureDebugOverlayCurrent, 0, 1, 0, 1)

	if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
		addConsoleCommand("gsWeatherToggleDebug", "Toggles weather debug", "consoleCommandWeatherToggleDebug", self)
		addConsoleCommand("gsWeatherReload", "Reloads weather data", "consoleCommandWeatherReloadData", self)
		addConsoleCommand("gsWeatherAdd", "Adds a weather object by type", "consoleCommandWeatherAdd", self)
		addConsoleCommand("gsWeatherSetWindState", "Sets wind state", "consoleCommandWeatherSetWindState", self)
		addConsoleCommand("gsWeatherSetFog", "Sets fog", "consoleCommandWeatherSetFog", self)
		addConsoleCommand("gsWeatherSetCloudFront", "Sets global cloud front", "consoleCommandWeatherSetCloudFront", self)
		addConsoleCommand("gsWeatherSetDebugWind", "Sets wind data", "consoleCommandWeatherSetDebugWind", self)
		addConsoleCommand("gsWeatherSetClouds", "Sets cloud data", "consoleCommandWeatherSetClouds", self)
	end

	return self
end

function Weather:load(xmlFile, key)
	self.forecastItems = {}
	self.weatherObjects = {}
	self.weightedWeatherObjects = {}
	self.typeToWeatherObject = {}
	local maxObjects = 2^Weather.SEND_BITS_OBJECT_INDEX - 1
	local i = 0

	while true do
		local objectKey = string.format("%s.weather.object(%d)", key, i)

		if not hasXMLProperty(xmlFile, objectKey) then
			break
		end

		if maxObjects < #self.weatherObjects then
			g_logManager:warning("Weather object limit (%d) readed at '%s'", maxObjects, objectKey)

			break
		end

		local typeName = getXMLString(xmlFile, objectKey .. "#typeName")
		local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

		if weatherType ~= nil then
			if self.isRainAllowed or weatherType.index ~= WeatherType.RAIN then
				if self.typeToWeatherObject[weatherType.index] == nil then
					local className = getXMLString(xmlFile, objectKey .. "#class")
					local classObject = ClassUtil.getClassObject(className)

					if classObject ~= nil then
						if classObject:isa(WeatherObject) then
							local instance = classObject:new(weatherType, self.cloudUpdater, self.temperatureUpdater, self.windUpdater)

							if instance:load(xmlFile, objectKey) then
								if getXMLBool(xmlFile, objectKey .. "#isFirstWeather") then
									self.firstWeatherType = weatherType
								end

								table.insert(self.weatherObjects, instance)

								instance.index = #self.weatherObjects
								self.typeToWeatherObject[weatherType.index] = instance

								for i = 1, instance.weight do
									table.insert(self.weightedWeatherObjects, instance.index)
								end
							end
						else
							g_logManager:warning("Given class '%s' is not a WeatherObject in '%s'", tostring(className), objectKey)
						end
					else
						g_logManager:warning("Class '%s' not found in '%s'", tostring(className), objectKey)
					end
				else
					g_logManager:warning("WeatherObject for type '%s' already defined in '%s'", typeName, objectKey)
				end
			end
		else
			g_logManager:warning("Invalid weather type '%s' in '%s'", typeName, objectKey)
		end

		i = i + 1
	end

	self.firstWeatherType = self.firstWeatherType or WeatherType.SUN or WeatherType.CLOUDY or WeatherType.RAIN
	self.windObjects = {}
	local i = 0

	while true do
		local windKey = string.format("%s.weather.wind.object(%d)", key, i)

		if not hasXMLProperty(xmlFile, windKey) then
			break
		end

		local windObject = WindObject:new()

		if windObject:load(xmlFile, windKey) then
			table.insert(self.windObjects, windObject)
		else
			windObject:delete()
		end

		i = i + 1
	end

	self.fog.height = getXMLFloat(xmlFile, key .. ".weather.fog#height") or self.fog.height

	if self.fog.height < 200 then
		self.fog.height = 200

		g_logManager:xmlWarning(self.xmlFilename, "Fog height may not be smaller than 200 for '%s'!", key .. ".weather.fog#height")
	end

	self.fog.minMieScale = getXMLFloat(xmlFile, key .. ".weather.fog#minMieScale") or self.fog.minMieScale

	if self.fog.minMieScale < 1 then
		self.fog.minMieScale = 1

		g_logManager:xmlWarning(self.xmlFilename, "Fog minMieScale may not be smaller than 1 for '%s'!", key .. ".weather.fog#minMieScale")
	end

	self.fog.maxMieScale = getXMLFloat(xmlFile, key .. ".weather.fog#maxMieScale") or self.fog.maxMieScale

	if self.fog.maxMieScale < 1 then
		self.fog.maxMieScale = 1

		g_logManager:xmlWarning(self.xmlFilename, "Fog maxMieScale may not be smaller than 1 for '%s'!", key .. ".weather.fog#maxMieScale")
	end

	if self.fog.maxMieScale < self.fog.minMieScale then
		local oldMin = self.fog.minMieScale
		self.fog.minMieScale = self.fog.maxMieScale
		self.fog.maxMieScale = oldMin

		g_logManager:xmlWarning(self.xmlFilename, "Fog maxMieScale has to be greater than minMieScale for '%s'!", key .. ".weather.fog#maxMieScale")
	end

	self.fog.startHour = getXMLFloat(xmlFile, key .. ".weather.fog#startHour") or self.fog.startHour
	self.fog.endHour = getXMLFloat(xmlFile, key .. ".weather.fog#endHour") or self.fog.endHour
	self.fog.fadeIn = getXMLFloat(xmlFile, key .. ".weather.fog#fadeIn") or self.fog.fadeIn
	self.fog.fadeOut = getXMLFloat(xmlFile, key .. ".weather.fog#fadeOut") or self.fog.fadeOut
	self.fog.rainMieScale = getXMLFloat(xmlFile, key .. ".weather.fog#rainMieScale") or self.fog.rainMieScale

	self.fogUpdater:setHeight(self.fog.height)
	self.fogUpdater:setTargetValues(self.fog.minMieScale, 0)

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:load(xmlFile, key .. ".skyBox")
	end

	if g_server ~= nil then
		self:addStartWeather()
		self:fillWeatherForecast()
		self:setWindObjectIndex(1, 0)
		self:init()
	end

	self.owner:addHourChangeListener(self)
	g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimeScaleChanged, self)
end

function Weather:delete()
	removeConsoleCommand("gsWeatherAdd")
	removeConsoleCommand("gsWeatherToggleDebug")
	removeConsoleCommand("gsWeatherSetWindState")
	removeConsoleCommand("gsWeatherSetFog")
	removeConsoleCommand("gsWeatherReload")
	removeConsoleCommand("gsWeatherSetCloudFront")
	removeConsoleCommand("gsWeatherSetDebugWind")
	removeConsoleCommand("gsWeatherSetClouds")
	delete(self.temperatureDebugOverlayCurrent)
	self.temperatureDebugGraph:delete()
	self.windUpdater:removeWindChangedListener(self.cloudUpdater)

	for _, object in ipairs(self.weatherObjects) do
		object:delete()
	end

	self.weatherObjects = {}

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:delete()
	end

	self.owner:removeHourChangeListener()
	g_messageCenter:unsubscribeAll(self)
end

function Weather:saveToXMLFile(xmlFile, key)
	for k, instance in ipairs(self.forecastItems) do
		local key = string.format("%s.forecast.instance(%d)", key, k - 1)

		if k == 1 then
			local durationLeft = instance.duration
			local nextInstance = instance

			if self.forecastItems[2] ~= nil then
				nextInstance = self.forecastItems[2]
			end

			local currentDay = self.owner.currentDay

			if currentDay < nextInstance.startDay then
				currentDay = currentDay + 1
				durationLeft = 86400000 - self.owner.dayTime
				durationLeft = durationLeft + math.max(0, nextInstance.startDay - currentDay - 1) * 24 * 60 * 60 * 1000
				durationLeft = durationLeft + nextInstance.startDayTime
			else
				durationLeft = nextInstance.startDayTime - self.owner.dayTime
			end

			setXMLFloat(xmlFile, key .. "#durationLeft", durationLeft / 3600000)
		end

		local weatherObject = self:getWeatherObjectByIndex(instance.objectIndex)

		setXMLString(xmlFile, key .. "#typeName", weatherObject.weatherType.name)
		setXMLInt(xmlFile, key .. "#variationIndex", instance.variationIndex)
		setXMLFloat(xmlFile, key .. "#duration", instance.duration / 3600000)
	end

	self.fogUpdater:saveToXMLFile(xmlFile, key .. ".fog")
	setXMLFloat(xmlFile, key .. ".fog#nightFactor", self.fog.nightFactor)
	setXMLFloat(xmlFile, key .. ".fog#dayFactor", self.fog.dayFactor)
	setXMLInt(xmlFile, key .. "#timeSinceLastRain", MathUtil.msToMinutes(self.timeSinceLastRain))
end

function Weather:loadFromXMLFile(xmlFile, key)
	local currentInstance = self.forecastItems[1]
	local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.objectIndex)

	currentWeatherObject:deactivate(1)

	self.forecastItems = {}
	local i = 0
	local startDay = self.owner.currentDay
	local startDayTime = self.owner.dayTime

	while true do
		local instanceKey = string.format("%s.forecast.instance(%d)", key, i)

		if not hasXMLProperty(xmlFile, instanceKey) then
			break
		end

		local typeName = getXMLString(xmlFile, instanceKey .. "#typeName")
		local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

		if weatherType ~= nil and self.typeToWeatherObject[weatherType.index] ~= nil then
			local weatherObject = self.typeToWeatherObject[weatherType.index]
			local weatherObjectIndex = weatherObject.index
			local weatherObjectVariationIndex = getXMLInt(xmlFile, instanceKey .. "#variationIndex")
			local variation = weatherObject:getVariationByIndex(weatherObjectVariationIndex)

			if variation ~= nil then
				local duration = math.max(variation.minHours, getXMLFloat(xmlFile, instanceKey .. "#duration") or 1) * 3600000
				local durationLeft = getXMLFloat(xmlFile, instanceKey .. "#durationLeft")

				if durationLeft ~= nil then
					duration = durationLeft * 3600000
				end

				local instance = WeatherInstance.createInstance(weatherObjectIndex, weatherObjectVariationIndex, startDay, startDayTime, duration)

				self:addWeatherForecast(instance)

				startDay, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
			else
				g_logManager:warning("Failed to load forecast instance. WeatherObject variationIndex '%s' not defined!", tostring(weatherObjectVariationIndex))
			end
		else
			g_logManager:warning("Failed to load forecast instance. WeatherObject '%s' not defined!", tostring(typeName))
		end

		i = i + 1
	end

	self.fogUpdater:loadFromXMLFile(xmlFile, key .. ".fog")

	self.fog.nightFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fog#nightFactor"), 0)
	self.fog.dayFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fog#dayFactor"), 0)
	self.timeSinceLastRain = MathUtil.minutesToMs(Utils.getNoNil(getXMLInt(xmlFile, key .. "#timeSinceLastRain"), 0)) or self.timeSinceLastRain

	self:fillWeatherForecast()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
	self:init()
end

function Weather:update(dt)
	local scaledDt = dt * g_currentMission:getEffectiveTimeScale()

	if #self.forecastItems >= 2 then
		local nextInstance = self.forecastItems[2]
		local currentInstance = self.forecastItems[1]
		local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.objectIndex)

		if nextInstance.startDay < self.owner.currentDay or self.owner.currentDay == nextInstance.startDay and nextInstance.startDayTime < self.owner.dayTime then
			local duration = Weather.CHANGE_DURATION

			currentWeatherObject:deactivate(duration)

			local nextWeatherObject = self:getWeatherObjectByIndex(nextInstance.objectIndex)

			nextWeatherObject:activate(nextInstance.variationIndex, duration)

			if nextWeatherObject.weatherType.index == WeatherType.RAIN then
				self:toggleFog(true, MathUtil.hoursToMs(0.5), self.fog.rainMieScale)
				self.weatherFrontUpdater:endWeatherFront(duration, duration)
			elseif nextWeatherObject.weatherType.index == WeatherType.SUN then
				self:toggleFog(false, MathUtil.hoursToMs(0.5))

				local thirdInstance = self.forecastItems[3]

				if thirdInstance ~= nil then
					local object = self:getWeatherObjectByIndex(thirdInstance.objectIndex)

					if object.weatherType.index == WeatherType.RAIN then
						self.weatherFrontUpdater:startWeatherFront(thirdInstance.duration + duration)
					end
				end
			end

			table.remove(self.forecastItems, 1)

			if g_server ~= nil then
				self:fillWeatherForecast()
			end
		end

		if currentWeatherObject.weatherType.index ~= WeatherType.RAIN then
			self.timeSinceLastRain = self.timeSinceLastRain + dt * g_currentMission:getEffectiveTimeScale()
		else
			self.timeSinceLastRain = 0
		end
	elseif g_server ~= nil then
		self:fillWeatherForecast()
	end

	for _, object in ipairs(self.weatherObjects) do
		object:update(scaledDt)
	end

	self.cloudUpdater:update(scaledDt)
	self.temperatureUpdater:update(scaledDt)
	self.windUpdater:update(scaledDt)
	self.fogUpdater:update(scaledDt)
	self.weatherFrontUpdater:update(scaledDt)

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:update(scaledDt, self.owner.dayTime, self:getRainFallScale(), self:getTimeUntilRain())
	end

	if g_server ~= nil then
		self.windTimer = self.windTimer - scaledDt

		if self.windTimer < 0 then
			self.windTimer = self.windDuration
			local nextWindIndex = math.random(1, #self.windObjects)

			self:setWindObjectIndex(nextWindIndex, self.windDuration * 0.3)
		end
	end

	if Weather.DEBUG_ENABLED then
		local data = {}
		local currentMin, currentMax = self.temperatureUpdater:getCurrentValues(self.owner.dayTime)
		local current = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)

		table.insert(data, {
			value = "",
			name = "TEMPERATURE"
		})
		table.insert(data, {
			name = "current",
			value = string.format("%.2f°", current)
		})
		table.insert(data, {
			name = "currentMin",
			value = string.format("%.2f°", currentMin)
		})
		table.insert(data, {
			name = "currentMax",
			value = string.format("%.2f°", currentMax)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		local currentPosX, currentPosZ, currentInnerRadius, currentOuterRadius, currentDistance = self.weatherFrontUpdater:getCurrentValues()

		table.insert(data, {
			value = "",
			name = "WEATHERFRONT"
		})
		table.insert(data, {
			name = "currentPosX",
			value = string.format("%.2f", currentPosX)
		})
		table.insert(data, {
			name = "currentPosZ",
			value = string.format("%.2f", currentPosZ)
		})
		table.insert(data, {
			name = "currentInnerRadius",
			value = string.format("%.2f", currentInnerRadius)
		})
		table.insert(data, {
			name = "currentOuterRadius",
			value = string.format("%.2f", currentOuterRadius)
		})
		table.insert(data, {
			name = "currentDistance",
			value = string.format("%.2f", currentDistance)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()

		table.insert(data, {
			value = "",
			name = "WIND"
		})
		table.insert(data, {
			name = "dirX",
			value = string.format("%.3f", windDirX)
		})
		table.insert(data, {
			name = "dirZ",
			value = string.format("%.3f", windDirZ)
		})
		table.insert(data, {
			name = "velocity",
			value = MathUtil.mpsToKmh(windVelocity)
		})
		table.insert(data, {
			name = "cirrusSpeedFactor",
			value = cirrusCloudSpeedFactor
		})
		table.insert(data, {
			value = "",
			name = ""
		})
		table.insert(data, {
			value = "",
			name = "RAIN"
		})
		table.insert(data, {
			name = "timeSince",
			value = string.format("%.2f", self:getTimeSinceLastRain())
		})
		table.insert(data, {
			name = "rainFallScale",
			value = string.format("%.2f", self:getRainFallScale())
		})
		table.insert(data, {
			value = "",
			name = "",
			columnOffset = 0.12
		})

		local cloudTypeFrom, cloudTypeTo, cirrusCloudDensityScale, cloudCoverage = self.cloudUpdater:getCurrentValues()

		table.insert(data, {
			value = "",
			name = "CLOUDS"
		})
		table.insert(data, {
			name = "typeFrom",
			value = string.format("%.3f", cloudTypeFrom)
		})
		table.insert(data, {
			name = "typeTo",
			value = string.format("%.3f", cloudTypeTo)
		})
		table.insert(data, {
			name = "cirrusDensityScale",
			value = string.format("%.3f", cirrusCloudDensityScale)
		})
		table.insert(data, {
			name = "coverage",
			value = string.format("%.3f", cloudCoverage)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		local mieScale = self.fogUpdater:getCurrentValues()
		local height = self.fogUpdater:getHeight()

		table.insert(data, {
			value = "",
			name = "FOG"
		})
		table.insert(data, {
			name = "height",
			value = string.format("%.1f", height)
		})
		table.insert(data, {
			name = "mieScale",
			value = string.format("%.3f", mieScale)
		})
		table.insert(data, {
			name = "nightFactor",
			value = string.format("%.2f", self.fog.nightFactor)
		})
		table.insert(data, {
			name = "dayFactor",
			value = string.format("%.2f", self.fog.dayFactor)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		if self.skyBoxUpdater ~= nil then
			self.skyBoxUpdater:addDebugValues(data)
		end

		table.insert(data, {
			value = "",
			name = "",
			columnOffset = 0.12
		})

		for k, instance in ipairs(self.forecastItems) do
			local dayDif = instance.startDay - self.owner.currentDay
			local text = string.format("Var %d | Active | Duration %d", instance.variationIndex, instance.duration / 3600000)

			if k > 1 then
				if dayDif == 0 then
					text = string.format("Var %d | In %d minutes | Duration %d", instance.variationIndex, (instance.startDayTime - self.owner.dayTime) / 60000, instance.duration / 3600000)
				else
					text = string.format("Var %d | In %d days | Duration %d", instance.variationIndex, dayDif, instance.duration / 3600000)
				end
			end

			local weatherObject = self:getWeatherObjectByIndex(instance.objectIndex)

			table.insert(data, {
				name = weatherObject.weatherType.name,
				value = text
			})
		end

		DebugUtil.renderTable(0.61, 0.46, 0.011, data)

		local graph = self.temperatureDebugGraph

		for h = 1, 24 do
			local temperature = self.temperatureUpdater:getTemperatureAtTime(h * 60 * 60 * 1000)

			graph:setValue(h, temperature)
		end

		graph:draw()

		local factor = self.owner.dayTime / self.owner.dayLength

		renderOverlay(self.temperatureDebugOverlayCurrent, graph.left + factor * graph.width, graph.bottom, 1 / g_screenWidth, graph.height)
	end
end

function Weather:setIsRainAllowed(isRainAllowed)
	self.isRainAllowed = isRainAllowed
end

function Weather:init()
	local currentInstance = self.forecastItems[1]
	local weatherObject = self:getWeatherObjectByIndex(currentInstance.objectIndex)

	weatherObject:activate(currentInstance.variationIndex, 0)

	if weatherObject.weatherType.index == WeatherType.SUN then
		local nextInstance = self.forecastItems[2]

		if nextInstance ~= nil then
			local object = self:getWeatherObjectByIndex(nextInstance.objectIndex)

			if object.weatherType.index == WeatherType.RAIN then
				self.weatherFrontUpdater:startWeatherFront(nextInstance.duration + Weather.CHANGE_DURATION)
			end
		end
	end
end

function Weather:getRandomWeatherObjectVariation(firstWeather)
	local weatherObject = self.typeToWeatherObject[self.firstWeatherType]

	if weatherObject == nil or not firstWeather then
		local weatherObjectIndex = self.weightedWeatherObjects[math.random(1, #self.weightedWeatherObjects)]
		weatherObject = self.weatherObjects[weatherObjectIndex]
	end

	local weatherObjectVariationIndex = weatherObject:getRandomVariationIndex()

	return weatherObject.index, weatherObjectVariationIndex
end

function Weather:getWeatherObjectByIndex(index)
	return self.weatherObjects[index]
end

function Weather:getForcaseInstanceVariation(instance)
	return self.weatherObjects[instance.objectIndex]:getVariationByIndex(instance.variationIndex)
end

function Weather:addStartWeather()
	local startDay = self.owner.currentDay
	local startDayTime = self.owner.dayTime
	local endDay, endDayTime = self.owner:getDayAndDayTime(startDayTime, startDay)
	local weatherInstance = self:createRandomWeatherInstance(endDay, endDayTime, true)

	self:addWeatherForecast(weatherInstance)
end

function Weather:fillWeatherForecast()
	local newObjects = {}
	local lastItem = self.forecastItems[#self.forecastItems]
	local maxNumOfforecastItemsItems = 2^Weather.SEND_BITS_NUM_OBJECTS - 1

	while (lastItem == nil or lastItem.startDay < self.owner.currentDay + 7) and maxNumOfforecastItemsItems > #self.forecastItems do
		local startDay = self.owner.currentDay
		local startDayTime = self.owner.dayTime

		if lastItem ~= nil then
			startDay = lastItem.startDay
			startDayTime = lastItem.startDayTime + lastItem.duration
		end

		local endDay, endDayTime = self.owner:getDayAndDayTime(startDayTime, startDay)
		local weatherInstance = self:createRandomWeatherInstance(endDay, endDayTime, false)

		self:addWeatherForecast(weatherInstance)
		table.insert(newObjects, weatherInstance)

		lastItem = self.forecastItems[#self.forecastItems]
	end

	if #newObjects > 0 then
		g_server:broadcastEvent(WeatherAddObjectEvent:new(newObjects, false))
	end
end

function Weather:createRandomWeatherInstance(startDay, startDayTime, firstWeather)
	local weatherObjectIndex, weatherObjectVariationIndex = self:getRandomWeatherObjectVariation(firstWeather)
	local weatherObject = self:getWeatherObjectByIndex(weatherObjectIndex)
	local variation = weatherObject:getVariationByIndex(weatherObjectVariationIndex)
	local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))

	return WeatherInstance.createInstance(weatherObjectIndex, weatherObjectVariationIndex, startDay, startDayTime, duration)
end

function Weather:addWeatherForecast(weatherInstance)
	table.insert(self.forecastItems, weatherInstance)
end

function Weather:onTimeScaleChanged()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
end

function Weather:getRainFallScale()
	local instance = self.forecastItems[1]

	if instance ~= nil then
		local object = self:getWeatherObjectByIndex(instance.objectIndex)

		if object.getRainFallScale ~= nil then
			return object:getRainFallScale()
		end
	end

	return 0
end

function Weather:getTimeUntilRain()
	for k, instance in ipairs(self.forecastItems) do
		local object = self:getWeatherObjectByIndex(instance.objectIndex)

		if instance.startDay == self.owner.currentDay and object.weatherType.index == WeatherType.RAIN and self.owner.dayTime < instance.startDayTime then
			return instance.startDayTime - self.owner.dayTime
		end
	end

	return math.huge
end

function Weather:getTimeSinceLastRain()
	return MathUtil.msToMinutes(self.timeSinceLastRain)
end

function Weather:getGroundWetness()
	local timeSinceLastRain = self:getTimeSinceLastRain()

	if timeSinceLastRain >= 30 then
		return 0
	end

	if self:getIsRaining() then
		return self:getRainFallScale()
	end

	return (30 - timeSinceLastRain) / 30 * 0.6
end

function Weather:getIsRaining()
	local instance = self.forecastItems[1]

	if instance ~= nil then
		local object = self:getWeatherObjectByIndex(instance.objectIndex)

		if object.getRainFallScale ~= nil then
			return object:getRainFallScale() > 0
		end
	end

	return false
end

function Weather:getWeatherTypeAtTime(day, dayTime)
	if g_client ~= nil and #self.forecastItems == 0 then
		return WeatherType.SUN
	end

	local instance = self.forecastItems[1]

	for _, object in ipairs(self.forecastItems) do
		if object.startDay < day or object.startDay == day and object.startDayTime < dayTime then
			instance = object
		else
			break
		end
	end

	local object = self:getWeatherObjectByIndex(instance.objectIndex)

	return object.weatherType.index
end

function Weather:getCurrentMinMaxTemperatures()
	return self.temperatureUpdater:getCurrentValues()
end

function Weather:getCurrentTemperatureTrend()
	local currentVariation = self:getForcaseInstanceVariation(self.forecastItems[1])
	local nextVariation = self:getForcaseInstanceVariation(self.forecastItems[2])
	local avgCurrent = (currentVariation.minTemperature + currentVariation.maxTemperature) * 0.5
	local avgNext = (nextVariation.minTemperature + nextVariation.maxTemperature) * 0.5
	local change = avgCurrent - avgNext
	local trend = 0

	if Weather.TEMPERATURE_STABLE_CHANGE < math.abs(change) then
		trend = MathUtil.sign(change)
	end

	return trend
end

function Weather:setWindObjectIndex(windIndex, duration)
	self.currentWindObjectIndex = windIndex
	local windObject = self.windObjects[windIndex]
	local windDirectionX, windDirectionZ, windVelocity, cirrusSpeedFactor = windObject:getValues()
	windDirectionX = self.debugWindDirX or windDirectionX
	windDirectionZ = self.debugWindDirZ or windDirectionZ
	windVelocity = self.debugWindVelocity or windVelocity
	cirrusSpeedFactor = self.debugWindCirrusSpeedFactor or cirrusSpeedFactor

	self.windUpdater:setTargetValues(windDirectionX, windDirectionZ, windVelocity, cirrusSpeedFactor, duration)

	if self.currentWindObjectIndex ~= windIndex and g_server then
		g_server:broadcastEvent(WindObjectChangedEvent:new(windIndex, false))
	end
end

function Weather:hourChanged()
	local currentHour = self.owner.currentHour
	local fog = self.fog

	if self.timeSinceLastRain ~= 0 then
		if currentHour == fog.startHour then
			self:toggleFog(true, MathUtil.hoursToMs(self.fog.fadeIn))
		elseif currentHour == fog.endHour then
			self:toggleFog(false, MathUtil.hoursToMs(self.fog.fadeOut))
		end
	end

	if #self.forecastItems > 0 then
		local currentWeatherObject = self:getWeatherObjectByIndex(self.forecastItems[1].objectIndex)
		local scaleFactor = 0

		if currentWeatherObject.weatherType.index == WeatherType.SUN then
			scaleFactor = 1
		elseif currentWeatherObject.weatherType.index == WeatherType.CLOUDY then
			scaleFactor = 0.25
		elseif currentWeatherObject.weatherType.index == WeatherType.RAIN then
			scaleFactor = -0.5
		end

		if currentHour == 0 then
			fog.nightFactor = scaleFactor
		elseif currentHour == 15 then
			fog.dayFactor = scaleFactor
		end
	end
end

function Weather:toggleFog(active, duration, mieScale)
	if active then
		local scale = MathUtil.clamp((self.fog.nightFactor + self.fog.dayFactor) / 2, 0, 1)
		mieScale = mieScale or MathUtil.lerp(self.fog.minMieScale, self.fog.maxMieScale, scale)

		self.fogUpdater:setTargetValues(mieScale, duration)
	else
		self.fogUpdater:setTargetValues(self.fog.minMieScale, duration)
	end
end

function Weather:consoleCommandWeatherAdd(typeName)
	local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

	if weatherType ~= nil then
		local weatherObject = self.typeToWeatherObject[weatherType.index]

		if weatherObject ~= nil then
			local variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
			local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
			local index = 3
			local currentInstance = self.forecastItems[2]

			if currentInstance == nil then
				currentInstance = self.forecastItems[1]
				index = 2

				if currentInstance == nil then
					index = 1
				end
			end

			local startDay = self.owner.currentDay
			local startDayTime = self.owner.dayTime

			if currentInstance ~= nil then
				startDayTime = currentInstance.startDayTime
				startDay = currentInstance.startDay
			end

			startDay, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
			local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, startDay, startDayTime, duration)
			local timeDif = (instance.startDayTime - self.owner.dayTime) / 60000 + (startDay - self.owner.currentDay) * 24 * 60

			table.insert(self.forecastItems, index, instance)

			local lastDuration = duration
			local lastStartDayTime = startDayTime
			local lastStartDay = startDay

			for i = index + 1, #self.forecastItems do
				local forecastItem = self.forecastItems[i]
				forecastItem.startDay, forecastItem.startDayTime = self.owner:getDayAndDayTime(lastStartDayTime + lastDuration, lastStartDay)
				lastDuration = forecastItem.duration
				lastStartDayTime = forecastItem.startDayTime
				lastStartDay = forecastItem.startDay
			end

			return string.format("Added state %s. Starts in %d minutes...", typeName, timeDif)
		end
	end

	local typeNames = ""

	for weatherTypeIndex, _ in pairs(self.typeToWeatherObject) do
		local weatherType = g_weatherTypeManager:getWeatherTypeByIndex(weatherTypeIndex)
		typeNames = typeNames .. weatherType.name .. " "
	end

	return "Invalid state: gsWeatherAdd <typeNames> (<startInHours>) | Available typeNames: " .. typeNames
end

function Weather:consoleCommandWeatherSetWindState(objectIndex, duration)
	objectIndex = tonumber(objectIndex)

	if objectIndex == 0 then
		objectIndex = math.random(1, #self.windObjects)
	end

	if objectIndex ~= nil and self.windObjects[objectIndex] ~= nil then
		duration = duration or 10

		self:setWindObjectIndex(objectIndex, duration * 1000)
	else
		return "Invalid state: gsWeatherSetWindState <state> [<duration>] (state = 0(random) or 1-" .. #self.windObjects
	end
end

function Weather:consoleCommandWeatherSetFog(height, mieScale, duration)
	height = tonumber(height) or 200
	mieScale = tonumber(mieScale) or 5
	duration = (tonumber(duration) or 5) * 60 * 60 * 1000

	self.fogUpdater:setHeight(height)
	self.fogUpdater:setTargetValues(mieScale, duration)
end

function Weather:consoleCommandWeatherToggleDebug()
	Weather.DEBUG_ENABLED = not Weather.DEBUG_ENABLED

	return "Weather Debug Enabled: " .. tostring(Weather.DEBUG_ENABLED)
end

function Weather:consoleCommandWeatherReloadData()
	local xmlFile = loadXMLFile("TempConfig", self.xmlFilename)
	local currentWeatherObject = self:getWeatherObjectByIndex(self.forecastItems[1].objectIndex)

	currentWeatherObject:deactivate(1)
	currentWeatherObject:update(9999999)

	for _, object in ipairs(self.weatherObjects) do
		object:delete()
	end

	self.weatherObjects = {}

	self:load(xmlFile, "environment")
	delete(xmlFile)

	return "Reloaded weather data"
end

function Weather:consoleCommandWeatherSetCloudFront(weatherFrontPosX, weatherFrontPosY, weatherFrontInnerRadius, weatherFrontOuterRadius)
	weatherFrontPosX = tonumber(weatherFrontPosX)
	weatherFrontPosY = tonumber(weatherFrontPosY)
	weatherFrontInnerRadius = tonumber(weatherFrontInnerRadius)
	weatherFrontOuterRadius = tonumber(weatherFrontOuterRadius)

	setCloudFront(weatherFrontPosX, weatherFrontPosY, weatherFrontInnerRadius, weatherFrontOuterRadius)

	return "Set cloud front! Command: gsWeatherSetCloudFront <weatherFrontPosX> <weatherFrontPosY> <weatherFrontInnerRadius> <weatherFrontOuterRadius>"
end

function Weather:consoleCommandWeatherSetDebugWind(xDir, zDir, speed, cirrusSpeedFactor)
	if g_client ~= nil then
		speed = tonumber(speed) or 1
		xDir = tonumber(xDir) or 1
		zDir = tonumber(zDir) or 1

		if speed > 0 then
			self.debugWindVelocity = speed
			self.debugWindDirX = xDir
			self.debugWindDirZ = zDir
			self.debugWindCirrusSpeedFactor = cirrusSpeedFactor
		else
			self.debugWindVelocity = nil
			self.debugWindDirX = nil
			self.debugWindDirZ = nil
			self.debugWindCirrusSpeedFactor = nil
		end

		self:setWindObjectIndex(self.currentWindObjectIndex, 0)

		return "Set debug wind speed " .. speed .. ". Set it to 0 to disable debugging again! Command: gsWeatherSetDebugWind <xDir> <zDir> <speed>"
	end
end

function Weather:consoleCommandWeatherSetClouds(typeFrom, typeTo, cloudDensityScale, cirrusCloudDensityScale)
	typeFrom = tonumber(typeFrom)
	typeTo = tonumber(typeTo)
	cloudDensityScale = tonumber(cloudDensityScale)
	cirrusCloudDensityScale = tonumber(cirrusCloudDensityScale)

	if typeFrom ~= nil and typeTo ~= nil then
		local currentInstance = self.forecastItems[1]
		local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.objectIndex)
		local varIndex = currentInstance.variationIndex
		local variation = currentWeatherObject.variations[varIndex]
		variation.clouds.cloudTypeFrom = typeFrom
		variation.clouds.cloudTypeTo = typeTo
		variation.clouds.cloudCoverage = cloudDensityScale or variation.clouds.cloudCoverage
		variation.clouds.cirrusCloudDensityScale = cirrusCloudDensityScale or variation.clouds.cirrusCloudDensityScale

		currentWeatherObject:activate(varIndex, 0.0001)

		return "Set cloud settings..."
	end

	return "Invalid usage. Command: gsWeatherSetClouds <typeFrom> <typeTo> <cloudDensityScale> <cirrusCloudDensityScale>"
end

function Weather:getGlobalCloudCoverate()
	local currentCloudTypeFrom, currentCloudTypeTo, currentCirrusCloudDensityScale, currentCloudCoverage = self.cloudUpdater:getCurrentValues()

	return currentCloudCoverage
end
