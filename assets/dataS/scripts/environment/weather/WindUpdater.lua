WindUpdater = {
	MAX_SPEED = 27
}
local WindUpdater_mt = Class(WindUpdater)

function WindUpdater:new(customMt)
	local self = setmetatable({}, customMt or WindUpdater_mt)
	self.listeners = {}
	self.isDirty = false
	self.alpha = 1
	self.duration = 1
	self.currentDirX = 1
	self.currentDirZ = 0
	self.currentVelocity = 1
	self.currentCirrusSpeedFactor = 1
	self.lastDirX = 1
	self.lastDirZ = 0
	self.lastVelocity = 1
	self.lastCirrusSpeedFactor = 1
	self.targetDirX = 1
	self.targetDirZ = 0
	self.targetVelocity = 1
	self.targetCirrusSpeedFactor = 1

	return self
end

function WindUpdater:delete()
end

function WindUpdater:update(dt)
	if self.alpha ~= 1 then
		self.alpha = math.min(self.alpha + dt / self.duration, 1)
		self.currentDirX = MathUtil.lerp(self.lastDirX, self.targetDirX, self.alpha)
		self.currentDirZ = MathUtil.lerp(self.lastDirZ, self.targetDirZ, self.alpha)
		self.currentVelocity = MathUtil.lerp(self.lastVelocity, self.targetVelocity, self.alpha)
		self.currentCirrusSpeedFactor = MathUtil.lerp(self.lastCirrusSpeedFactor, self.targetCirrusSpeedFactor, self.alpha)
		self.isDirty = true
	end

	if self.isDirty then
		setSharedShaderParameter(Shader.PARAM_SHARED_WIND_SPEED, MathUtil.clamp(self.currentVelocity / WindUpdater.MAX_SPEED, 0, 1))
		setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_X, self.currentDirX)
		setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_Z, self.currentDirZ)

		for _, listener in ipairs(self.listeners) do
			listener:setWindValues(self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor)
		end

		self.isDirty = false
	end
end

function WindUpdater:getCurrentValues()
	return self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor
end

function WindUpdater:setTargetValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastDirX = self.currentDirX
	self.lastDirZ = self.currentDirZ
	self.lastVelocity = self.currentVelocity
	self.lastCirrusSpeedFactor = self.currentCirrusSpeedFactor
	self.targetDirX = windDirX
	self.targetDirZ = windDirZ
	self.targetVelocity = windVelocity
	self.targetCirrusSpeedFactor = cirrusCloudSpeedFactor
end

function WindUpdater:addWindChangedListener(listener)
	ListUtil.addElementToList(self.listeners, listener)
end

function WindUpdater:removeWindChangedListener(listener)
	ListUtil.removeElementFromList(self.listeners, listener)
end
