ShakeAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local ShakeAnimation_mt = Class(ShakeAnimation, Animation)

function ShakeAnimation:new(customMt)
	local self = Animation:new(customMt or ShakeAnimation_mt)
	self.state = ShakeAnimation.STATE_OFF
	self.node = nil
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.initialTurnOnFadeTime = 1000
	self.currentAlpha = 0
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function ShakeAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not hasXMLProperty(xmlFile, key) then
		return nil
	end

	self.owner = owner
	self.node = I3DUtil.indexToObject(rootNodes, getXMLString(xmlFile, key .. "#node"), i3dMapping)

	if self.node == nil then
		g_logManager:xmlWarning(owner.configFileName, "Missing node for shake animation '%s'!", key)

		return nil
	end

	if not getHasShaderParameter(self.node, "shaking") then
		g_logManager:xmlWarning(owner.configFileName, "Node '%s' has no shader parameter 'shaking' for shake animation '%s'!", getName(self.node), key)

		return nil
	end

	self.turnOnFadeTime = math.max(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnOnFadeTime"), 2) * 1000, 1)
	self.turnOffFadeTime = math.max(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnOffFadeTime"), 2) * 1000, 1)
	self.turnOnOffVariance = getXMLFloat(xmlFile, key .. "#turnOnOffVariance")

	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end

	self.shaking = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#shaking"), "0 0 0 0"), 4)

	return self
end

function ShakeAnimation:update(dt)
	ShakeAnimation:superClass().update(self, dt)

	local lastAlpha = self.currentAlpha
	local needUpdate = false

	if self.state == ShakeAnimation.STATE_ON then
		needUpdate = self.currentAlpha < 1
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == ShakeAnimation.STATE_TURNING_OFF then
		needUpdate = self.currentAlpha > 0
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if needUpdate then
		local x = self.shaking[1] * self.currentAlpha
		local y = self.shaking[2] * self.currentAlpha
		local z = self.shaking[3] * self.currentAlpha
		local w = self.shaking[4] * self.currentAlpha

		setShaderParameter(self.node, "shaking", x, y, z, w, false)
	end

	if self.state == ShakeAnimation.STATE_TURNING_OFF and self.currentAlpha == 0 then
		self.state = ShakeAnimation.STATE_OFF
	end
end

function ShakeAnimation:isRunning()
	return self.state ~= ShakeAnimation.STATE_OFF
end

function ShakeAnimation:start()
	if self.state ~= ShakeAnimation.STATE_ON then
		if self.state == ShakeAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = ShakeAnimation.STATE_ON

		return true
	end

	return false
end

function ShakeAnimation:stop()
	if self.state ~= ShakeAnimation.STATE_OFF then
		self.state = ShakeAnimation.STATE_TURNING_OFF

		return true
	end

	return false
end

function ShakeAnimation:reset()
	self.currentAlpha = 0
	self.state = ShakeAnimation.STATE_OFF
end
