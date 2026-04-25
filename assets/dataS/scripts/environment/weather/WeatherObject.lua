WeatherObject = {}
local WeatherObject_mt = Class(WeatherObject)

function WeatherObject:new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, customMt)
	local self = setmetatable({}, customMt or WeatherObject_mt)
	self.weatherType = weatherType
	self.temperatureUpdater = temperatureUpdater
	self.cloudUpdater = cloudUpdater
	self.windUpdater = windUpdater
	self.variations = {}
	self.weightedVariations = {}

	return self
end

function WeatherObject:load(xmlFile, key)
	self.weight = getXMLInt(xmlFile, key .. "#weight") or 1
	local maxVariations = 2^Weather.SEND_BITS_OBJECT_VARIATION_INDEX - 1
	local i = 0

	while true do
		local variationKey = string.format("%s.variation(%d)", key, i)

		if not hasXMLProperty(xmlFile, variationKey) then
			break
		end

		if maxVariations < #self.variations then
			g_logManager:warning("Weather object variation limit (%d) readed at '%s'", maxVariations, variationKey)

			break
		end

		local variation = {}

		if self:loadVariation(xmlFile, variationKey, variation) then
			table.insert(self.variations, variation)

			variation.index = #self.variations

			for i = 1, variation.weight do
				table.insert(self.weightedVariations, variation.index)
			end
		end

		i = i + 1
	end

	return true
end

function WeatherObject:loadVariation(xmlFile, key, variation)
	variation.weight = getXMLInt(xmlFile, key .. "#weight") or 1
	variation.minHours = MathUtil.clamp(getXMLInt(xmlFile, key .. "#minHours") or 5, 1, 2^Weather.SEND_BITS_DURATION - 1)

	if variation.minHours < Weather.MIN_WEATHER_DURATION then
		g_logManager:warning("MinHours needs to be greater than %.1f hours for variation '%s'!", Weather.MIN_WEATHER_DURATION, key)

		variation.minHours = Weather.MIN_WEATHER_DURATION
	end

	variation.maxHours = MathUtil.clamp(getXMLInt(xmlFile, key .. "#maxHours") or 10, 3, 2^Weather.SEND_BITS_DURATION - 1)

	if variation.maxHours < variation.minHours then
		g_logManager:warning("MaxHours needs to be greater than minHours! for variation '%s'", key)

		variation.maxHours = variation.minHours
	end

	local minTemperature = math.max(getXMLInt(xmlFile, key .. "#minTemperature") or 15, 1)
	local maxTemperature = math.max(getXMLInt(xmlFile, key .. "#maxTemperature") or 25, 1)
	local maxSendTemp = 2^Weather.SEND_BITS_TEMPERATURE

	if minTemperature > maxSendTemp then
		minTemperature = maxSendTemp

		g_logManager:warning("Min temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	elseif maxSendTemp < maxTemperature then
		maxTemperature = maxSendTemp

		g_logManager:warning("Max temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	end

	if maxTemperature < minTemperature then
		local minCopy = minTemperature
		minTemperature = maxTemperature
		maxTemperature = minCopy
	end

	variation.minTemperature = minTemperature
	variation.maxTemperature = maxTemperature
	variation.clouds = {
		cloudTypeFrom = getXMLFloat(xmlFile, key .. ".cloudTypes#from") or 0,
		cloudTypeTo = getXMLFloat(xmlFile, key .. ".cloudTypes#to") or 1
	}

	if variation.clouds.cloudTypeFrom < 0 or variation.clouds.cloudTypeFrom > 1 then
		variation.clouds.cloudTypeFrom = MathUtil.clamp(variation.clouds.cloudTypeFrom, 0, 1)

		g_logManager:warning("CloudType-From is out of range for variation '%s'. Value range is 0-1", key)
	end

	if variation.clouds.cloudTypeTo < 0 or variation.clouds.cloudTypeTo > 1 then
		variation.clouds.cloudTypeTo = MathUtil.clamp(variation.clouds.cloudTypeTo, 0, 1)

		g_logManager:warning("CloudType-To is out of range for variation '%s'. Value range is 0-1", key)
	end

	if variation.clouds.cloudTypeTo < variation.clouds.cloudTypeFrom then
		g_logManager:warning("CloudType-From is bigger than cloudType-To. Flipping values for variation '%s'", key)

		local oldTo = variation.clouds.cloudTypeTo
		variation.clouds.cloudTypeTo = variation.clouds.cloudTypeFrom
		variation.clouds.cloudTypeFrom = oldTo
	end

	variation.clouds.cloudCoverage = getXMLFloat(xmlFile, key .. ".clouds#densityScale") or 1
	variation.clouds.cirrusCloudDensityScale = getXMLFloat(xmlFile, key .. ".cirrusClouds#densityScale") or 1

	return true
end

function WeatherObject:getRandomVariationIndex()
	return self.weightedVariations[math.random(1, #self.weightedVariations)]
end

function WeatherObject:getVariationByIndex(index)
	if index == nil then
		return nil
	end

	return self.variations[index]
end

function WeatherObject:delete()
end

function WeatherObject:update(dt)
end

function WeatherObject:activate(variationIndex, duration)
	local variation = self.variations[variationIndex]
	local clouds = self.variations[variationIndex].clouds

	self.cloudUpdater:setTargetValues(clouds.cloudTypeFrom, clouds.cloudTypeTo, clouds.cloudCoverage, clouds.cirrusCloudDensityScale, duration)
	self.temperatureUpdater:setTargetValues(variation.minTemperature, variation.maxTemperature, duration == 0)
end

function WeatherObject:deactivate(duration)
end
