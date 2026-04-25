WeatherInstance = {}
local WeatherInstance_mt = Class(WeatherInstance)

function WeatherInstance:new(customMt)
	local self = setmetatable({}, customMt or WeatherInstance_mt)
	self.objectIndex = nil
	self.variationIndex = nil
	self.startDay = 0
	self.startDayTime = 0
	self.duration = 0

	return self
end

function WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration)
	startDayTime = math.floor(startDayTime / 60000) * 60000
	duration = math.floor(duration / 3600000) * 3600000
	local weatherInstance = WeatherInstance:new()
	weatherInstance.objectIndex = objectIndex
	weatherInstance.variationIndex = variationIndex
	weatherInstance.startDay = startDay
	weatherInstance.startDayTime = startDayTime
	weatherInstance.duration = duration

	return weatherInstance
end
