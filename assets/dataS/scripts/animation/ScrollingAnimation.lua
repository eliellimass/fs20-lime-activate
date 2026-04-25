ScrollingAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local ScrollingAnimation_mt = Class(ScrollingAnimation, Animation)

function ScrollingAnimation:new(customMt)
	local self = Animation:new(customMt or ScrollingAnimation_mt)
	self.state = ScrollingAnimation.STATE_OFF
	self.node = nil
	self.shaderParameterName = nil
	self.scrollPosition = 0
	self.scrollSpeed = 0
	self.scrollLength = 1
	self.shaderParameterComponent = 1
	self.currentAlpha = 0
	self.initialTurnOnFadeTime = 1000
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function ScrollingAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not hasXMLProperty(xmlFile, key) then
		return nil
	end

	self.owner = owner
	self.node = I3DUtil.indexToObject(rootNodes, getXMLString(xmlFile, key .. "#node"), i3dMapping)

	if self.node == nil then
		g_logManager:xmlWarning(owner.configFileName, "Missing node for scrolling animation '%s'!", key)

		return nil
	end

	self.shaderParameterName = getXMLString(xmlFile, key .. "#shaderParameterName") or "offsetUV"

	if not getHasShaderParameter(self.node, self.shaderParameterName) then
		g_logManager:xmlWarning(owner.configFileName, "Node '%s' has no shader parameter '%s' for animationNode '%s'!", getName(self.node), self.shaderParameterName, key)

		return nil
	end

	local fillTypeStr = getXMLString(xmlFile, key .. "#type")

	if fillTypeStr ~= nil then
		self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
	end

	self.scrollSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#scrollSpeed"), 1) * 0.001
	self.scrollLength = getXMLFloat(xmlFile, key .. "#scrollLength") or 1
	self.shaderParameterComponent = getXMLInt(xmlFile, key .. "#shaderParameterComponent") or 1
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
			g_logManager:xmlWarning(self.configFileName, "Could not find speed function '%s' for scrolling animation '%s'!", speedFuncStr, key)
		end
	end

	return self
end

function ScrollingAnimation:update(dt)
	ScrollingAnimation:superClass().update(self, dt)

	if self.state == ScrollingAnimation.STATE_ON then
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == ScrollingAnimation.STATE_TURNING_OFF then
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if self.currentAlpha > 0 then
		local speedFactor = self.speedFunc(self.speedFuncTarget)
		local x, y, z, w = getShaderParameter(self.node, self.shaderParameterName)

		if self.shaderParameterComponent == 1 then
			x = self:updateScrollPosition(x, dt, speedFactor)
		elseif self.shaderParameterComponent == 2 then
			y = self:updateScrollPosition(y, dt, speedFactor)
		elseif self.shaderParameterComponent == 3 then
			z = self:updateScrollPosition(z, dt, speedFactor)
		else
			w = self:updateScrollPosition(w, dt, speedFactor)
		end

		setShaderParameter(self.node, self.shaderParameterName, x, y, z, w, false)

		if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
			self.owner:setMovingToolDirty(self.node)
		end
	else
		self.state = ScrollingAnimation.STATE_OFF
	end
end

function ScrollingAnimation:isRunning()
	return self.state ~= ScrollingAnimation.STATE_OFF
end

function ScrollingAnimation:start()
	if self.state ~= ScrollingAnimation.STATE_ON then
		if self.state == ScrollingAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = ScrollingAnimation.STATE_ON

		return true
	end

	return false
end

function ScrollingAnimation:stop()
	if self.state ~= ScrollingAnimation.STATE_OFF then
		self.state = ScrollingAnimation.STATE_TURNING_OFF

		return true
	end

	return false
end

function ScrollingAnimation:reset()
	self.currentAlpha = 0
	self.state = ScrollingAnimation.STATE_OFF
end

function ScrollingAnimation:setFillType(fillTypeIndex)
	if self.fillTypeIndex ~= nil then
		setVisibility(self.node, self.fillTypeIndex == fillTypeIndex)
	end
end

function ScrollingAnimation:updateScrollPosition(scrollPosition, dt, speedFactor)
	return (scrollPosition + self.currentAlpha * dt * self.scrollSpeed * speedFactor) % self.scrollLength
end
