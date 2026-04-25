CloudUpdater = {}
local CloudUpdater_mt = Class(CloudUpdater)

function CloudUpdater:new(index, customMt)
	local self = setmetatable({}, customMt or CloudUpdater_mt)
	self.index = index
	self.speedScale = 1
	self.weatherTypeIndex = WeatherType.SUN
	self.lastCloudTypeFrom = 0
	self.lastCloudTypeTo = 0
	self.lastCirrusCloudDensityScale = 0
	self.lastCloudCoverage = 0
	self.currentCloudTypeFrom = 0
	self.currentCloudTypeTo = 0
	self.currentCirrusCloudDensityScale = 0
	self.currentCloudCoverage = 0
	self.targetCloudTypeFrom = 0
	self.targetCloudTypeTo = 0
	self.targetCirrusCloudDensityScale = 0
	self.targetCloudCoverage = 0
	self.alpha = 1
	self.duration = 0
	self.isDirty = false
	self.windDirX = 1
	self.windDirZ = 0
	self.windVelocity = 1
	self.cirrusCloudSpeedFactor = 1

	return self
end

function CloudUpdater:delete()
end

function CloudUpdater:update(dt)
	if self.alpha ~= 1 then
		self.alpha = math.min(self.alpha + dt / self.duration, 1)
		self.currentCloudTypeFrom = MathUtil.lerp(self.lastCloudTypeFrom, self.targetCloudTypeFrom, self.alpha)
		self.currentCloudTypeTo = MathUtil.lerp(self.lastCloudTypeTo, self.targetCloudTypeTo, self.alpha)
		self.currentCirrusCloudDensityScale = MathUtil.lerp(self.lastCirrusCloudDensityScale, self.targetCirrusCloudDensityScale, self.alpha)
		self.currentCloudCoverage = MathUtil.lerp(self.lastCloudCoverage, self.targetCloudCoverage, self.alpha)
		self.isDirty = true
	end

	if self.isDirty then
		local cirrusCloudVelocityX = self.windDirX * self.windVelocity * self.cirrusCloudSpeedFactor * self.speedScale
		local cirrusCloudVelocityZ = self.windDirZ * self.windVelocity * self.cirrusCloudSpeedFactor * self.speedScale

		setGlobalCloudState(self.currentCloudTypeFrom, self.currentCloudTypeTo, self.windDirX, self.windDirZ, self.windVelocity * self.speedScale, cirrusCloudVelocityX, cirrusCloudVelocityZ, self.currentCirrusCloudDensityScale, self.currentCloudCoverage)

		self.isDirty = false
	end
end

function CloudUpdater:getCurrentValues()
	return self.currentCloudTypeFrom, self.currentCloudTypeTo, self.currentCirrusCloudDensityScale, self.currentCloudCoverage
end

function CloudUpdater:setTargetValues(cloudTypeFrom, cloudTypeTo, cloudCoverage, cirrusCloudDensityScale, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastCloudTypeFrom = self.currentCloudTypeFrom
	self.lastCloudTypeTo = self.currentCloudTypeTo
	self.lastCirrusCloudDensityScale = self.currentCirrusCloudDensityScale
	self.lastCloudCoverage = self.currentCloudCoverage
	self.targetCloudTypeFrom = cloudTypeFrom
	self.targetCloudTypeTo = cloudTypeTo
	self.targetCirrusCloudDensityScale = cirrusCloudDensityScale
	self.targetCloudCoverage = cloudCoverage
end

function CloudUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.windDirX = windDirX
	self.windDirZ = windDirZ
	self.windVelocity = windVelocity
	self.cirrusCloudSpeedFactor = cirrusCloudSpeedFactor
	self.isDirty = true
end

function CloudUpdater:setTimeScale(scale)
	self.speedScale = scale
	self.isDirty = true
end
