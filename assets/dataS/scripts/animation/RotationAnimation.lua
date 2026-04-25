RotationAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local RotationAnimation_mt = Class(RotationAnimation, Animation)

function RotationAnimation:new(customMt)
	local self = Animation:new(customMt or RotationAnimation_mt)
	self.state = RotationAnimation.STATE_OFF
	self.node = nil
	self.shaderParameterName = nil
	self.shaderComponentScale = {
		1,
		0,
		0,
		0
	}
	self.rotSpeed = 0
	self.currentAlpha = 0
	self.initialTurnOnFadeTime = 1000
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.rotAxis = 1
	self.currentRot = 1
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function RotationAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not hasXMLProperty(xmlFile, key) then
		return nil
	end

	self.owner = owner
	self.node = I3DUtil.indexToObject(rootNodes, getXMLString(xmlFile, key .. "#node"), i3dMapping)

	if self.node == nil then
		g_logManager:xmlWarning(owner.configFileName, "Missing node for rotation animation '%s'!", key)

		return nil
	end

	self.shaderParameterName = getXMLString(xmlFile, key .. "#shaderParameterName")

	if self.shaderParameterName ~= nil and not getHasShaderParameter(self.node, self.shaderParameterName) then
		g_logManager:xmlWarning(owner.configFileName, "Node '%s' has no shader parameter '%s' for animationNode '%s'!", getName(self.node), self.shaderParameterName, key)

		return nil
	end

	self.shaderComponentScale = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#shaderComponentScale"), "1 0 0 0"), 4)
	self.rotSpeed = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#rotSpeed"), 1) * 0.001)
	self.rotAxis = Utils.getNoNil(getXMLInt(xmlFile, key .. "#rotAxis"), 2)
	self.turnOnFadeTime = math.max(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnOnFadeTime"), 2) * 1000, 1)
	self.turnOffFadeTime = math.max(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnOffFadeTime"), 2) * 1000, 1)
	self.turnOnOffVariance = getXMLFloat(xmlFile, key .. "#turnOnOffVariance")

	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end

	local speedFuncStr = getXMLString(xmlFile, key .. "#speedFunc")

	if speedFuncStr ~= nil then
		if owner[speedFuncStr] ~= nil then
			self.speedFunc = owner[speedFuncStr]
			self.speedFuncTarget = self.owner
		else
			g_logManager:xmlWarning(self.configFileName, "Could not find speed function '%s' for rotation animation '%s'!", speedFuncStr, key)
		end
	end

	return self
end

function RotationAnimation:update(dt)
	RotationAnimation:superClass().update(self, dt)

	if self.state == RotationAnimation.STATE_ON then
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == RotationAnimation.STATE_TURNING_OFF then
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if self.currentAlpha > 0 then
		local speedFactor = self.speedFunc(self.speedFuncTarget)
		local rot = self.currentAlpha * dt * self.rotSpeed * speedFactor

		if self.shaderParameterName == nil then
			if self.rotAxis == 2 then
				rotate(self.node, 0, rot, 0)
			elseif self.rotAxis == 1 then
				rotate(self.node, rot, 0, 0)
			else
				rotate(self.node, 0, 0, rot)
			end
		else
			self.currentRot = self.currentRot + rot

			setShaderParameter(self.node, self.shaderParameterName, self.currentRot * self.shaderComponentScale[1], self.currentRot * self.shaderComponentScale[2], self.currentRot * self.shaderComponentScale[3], self.currentRot * self.shaderComponentScale[4], false)
		end

		if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
			self.owner:setMovingToolDirty(self.node)
		end
	else
		self.state = RotationAnimation.STATE_OFF
	end
end

function RotationAnimation:isRunning()
	return self.state ~= RotationAnimation.STATE_OFF
end

function RotationAnimation:start()
	if self.state ~= RotationAnimation.STATE_ON then
		if self.state == RotationAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = RotationAnimation.STATE_ON

		return true
	end

	return false
end

function RotationAnimation:stop()
	if self.state ~= RotationAnimation.STATE_OFF then
		self.state = RotationAnimation.STATE_TURNING_OFF

		return true
	end

	return false
end

function RotationAnimation:reset()
	self.currentAlpha = 0
	self.state = RotationAnimation.STATE_OFF
end
