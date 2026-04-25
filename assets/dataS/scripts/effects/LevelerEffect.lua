LevelerEffect = {}
local LevelerEffect_mt = Class(LevelerEffect, ShaderPlaneEffect)

function LevelerEffect:new(customMt)
	if customMt == nil then
		customMt = LevelerEffect_mt
	end

	self = ShaderPlaneEffect:new(customMt)

	return self
end

function LevelerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not LevelerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.speed = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "speed"), 1) * 0.001
	self.maxHeight = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "maxHeight"), 1)
	self.scrollPosition = 0
	self.depthTarget = 0
	self.fillLevel = 0
	self.lastVehicleSpeed = 0

	return true
end

function LevelerEffect:update(dt)
	LevelerEffect:superClass().update(self, dt)

	if self.state == ShaderPlaneEffect.STATE_ON then
		setVisibility(self.node, true)

		if self.depthTarget < self.fillLevel then
			self.depthTarget = math.min(self.fillLevel, self.depthTarget + 0.001 * dt)
		elseif self.fillLevel < self.depthTarget then
			self.depthTarget = math.max(self.fillLevel, self.depthTarget - 0.001 * dt)
		end

		self.scrollPosition = self.scrollPosition + self.lastVehicleSpeed * self.speed

		setShaderParameter(self.node, "VertxoffsetVertexdeformMotionUVscale", self.maxHeight, self.depthTarget, self.scrollPosition, 6, false)
	else
		setVisibility(self.node, false)
	end
end

function LevelerEffect:isRunning()
	return LevelerEffect:superClass().isRunning(self) or self.state == ShaderPlaneEffect.STATE_ON
end

function LevelerEffect:setFillLevel(fillLevel)
	self.fillLevel = fillLevel
end

function LevelerEffect:setLastVehicleSpeed(speed)
	self.lastVehicleSpeed = speed
end
