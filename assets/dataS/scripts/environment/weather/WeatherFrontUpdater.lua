WeatherFrontUpdater = {
	DISABLED_DISTANCE = 40000,
	INNER_RADIUS = 20000,
	OUTER_RADIUS = 25000
}
local WeatherFrontUpdater_mt = Class(WeatherFrontUpdater)

function WeatherFrontUpdater:new(windUpdater, customMt)
	local self = setmetatable({}, customMt or WeatherFrontUpdater_mt)
	self.windUpdater = windUpdater
	self.endDuration = 1
	self.endTime = 0
	self.isDirty = false
	self.alpha = 1
	self.duration = 1
	self.lastInnerRadius = 0
	self.lastOuterRadius = 0
	self.lastDistance = WeatherFrontUpdater.DISABLED_DISTANCE
	self.currentInnerRadius = 0
	self.currentOuterRadius = 0
	self.currentDistance = WeatherFrontUpdater.DISABLED_DISTANCE
	self.targetInnerRadius = 0
	self.targetOuterRadius = 0
	self.targetDistance = 0
	self.currentPosX = 0
	self.currentPosZ = 0

	return self
end

function WeatherFrontUpdater:delete()
end

function WeatherFrontUpdater:update(dt)
	if self.endTime > 0 then
		self.endTime = math.max(self.endTime - dt, 0)

		if self.endTime == 0 then
			self:setTargetValues(0, 0, WeatherFrontUpdater.DISABLED_DISTANCE, self.endDuration)
		end
	end

	if self.alpha ~= 1 then
		self.alpha = math.min(self.alpha + dt / self.duration, 1)
		local windDirX, windDirZ, _, _ = self.windUpdater:getCurrentValues()
		self.currentDistance = MathUtil.lerp(self.lastDistance, self.targetDistance, self.alpha)
		self.currentPosX = windDirX * self.currentDistance
		self.currentPosZ = windDirZ * self.currentDistance
		self.currentInnerRadius = MathUtil.lerp(self.lastInnerRadius, self.targetInnerRadius, self.alpha)
		self.currentOuterRadius = MathUtil.lerp(self.lastOuterRadius, self.targetOuterRadius, self.alpha)
		self.isDirty = true
	end

	if self.isDirty then
		setCloudFront(self.currentPosX, self.currentPosZ, self.currentInnerRadius, self.currentOuterRadius)

		self.isDirty = false
	end
end

function WeatherFrontUpdater:getCurrentValues()
	return self.currentPosX, self.currentPosZ, self.currentInnerRadius, self.currentOuterRadius, self.currentDistance
end

function WeatherFrontUpdater:setTargetValues(innerRadius, outerRadius, distance, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastDistance = self.currentDistance
	self.lastInnerRadius = self.currentInnerRadius
	self.lastOuterRadius = self.currentOuterRadius
	self.targetDistance = distance
	self.targetInnerRadius = innerRadius
	self.targetOuterRadius = outerRadius
end

function WeatherFrontUpdater:startWeatherFront(duration, startDistance)
	self:setTargetValues(WeatherFrontUpdater.INNER_RADIUS, WeatherFrontUpdater.OUTER_RADIUS, 0, duration, true)
end

function WeatherFrontUpdater:endWeatherFront(endTime, duration)
	self.endTime = endTime
	self.endDuration = duration
end
