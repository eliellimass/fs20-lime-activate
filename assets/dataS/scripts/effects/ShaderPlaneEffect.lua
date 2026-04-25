ShaderPlaneEffect = {}
local ShaderPlaneEffect_mt = Class(ShaderPlaneEffect, Effect)
ShaderPlaneEffect.STATE_OFF = 0
ShaderPlaneEffect.STATE_TURNING_ON = 1
ShaderPlaneEffect.STATE_ON = 2
ShaderPlaneEffect.STATE_TURNING_OFF = 3

function ShaderPlaneEffect:new(customMt)
	if customMt == nil then
		customMt = ShaderPlaneEffect_mt
	end

	local self = Effect:new(customMt)
	self.state = ShaderPlaneEffect.STATE_OFF
	self.planeFadeTime = 0

	return self
end

function ShaderPlaneEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ShaderPlaneEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.fadeInTime = Utils.getNoNil(Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeInTime"), Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeTime")), 1) * 1000
	self.fadeOutTime = Utils.getNoNil(Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeOutTime"), Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeTime")), 1) * 1000
	self.planeFadeTime = math.max(self.planeFadeTime, self.fadeInTime, self.fadeOutTime)
	self.startDelay = Utils.getNoNil(Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "startDelay"), Effect.getValue(xmlFile, key, getXMLFloat, node, "delay")), 0) * 1000
	self.stopDelay = Utils.getNoNil(Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "stopDelay"), Effect.getValue(xmlFile, key, getXMLFloat, node, "delay")), 0) * 1000
	self.currentDelay = self.startDelay
	self.alwaysVisibile = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "alwaysVisibile"), false)
	self.showOnFirstUse = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "showOnFirstUse"), false)
	local defaultFillType = Effect.getValue(xmlFile, key, getXMLString, node, "defaultFillType")

	if defaultFillType ~= nil then
		self.defaultFillType = g_fillTypeManager:getFillTypeIndexByName(defaultFillType)
	end

	self.dynamicFillType = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "dynamicFillType"), true)
	self.materialTypeId = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "materialTypeId"), 1)
	self.materialType = Effect.getValue(xmlFile, key, getXMLString, node, "materialType")
	self.alignToWorldY = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "alignToWorldY"), false)
	self.alignXAxisToWorldY = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "alignXAxisToWorldY"), false)

	if not self.dynamicFillType then
		self:setFillType(nil, true)
	end

	self.fadeXDistance = {
		Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeXMinDistance"), -1.58),
		Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeXMaxDistance"), 4.18)
	}
	self.useDistance = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "useDistance"), true)
	self.extraDistance = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "extraDistance"), -0.25)
	self.extraDistanceNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, getXMLString, node, "extraDistanceNode"), i3dMapping)
	self.fadeScale = Effect.getValue(xmlFile, key, getXMLFloat, node, "fadeScale")
	self.uvSpeed = Effect.getValue(xmlFile, key, getXMLFloat, node, "uvSpeed")
	self.fadeX = {
		-1,
		1
	}
	self.fadeY = {
		-1,
		1
	}
	self.fadeCur = {
		-1,
		1
	}
	self.fadeDir = {
		1,
		1
	}
	self.offset = 0
	self.hasValidMaterial = true

	setShaderParameter(self.node, "fadeProgress", -1, 1, 0, 0, false)

	if self.alignXAxisToWorldY then
		self.worldYReferenceFrame = createTransformGroup("worldYReferenceFrame")

		link(getParent(self.node), self.worldYReferenceFrame)
		setTranslation(self.worldYReferenceFrame, getTranslation(self.node))
		setRotation(self.worldYReferenceFrame, getRotation(self.node))
	end

	return true
end

function ShaderPlaneEffect:update(dt)
	ShaderPlaneEffect:superClass().update(self, dt)

	local isRunning = false
	self.currentDelay = self.currentDelay - dt

	if self.currentDelay <= 0 then
		local fadeTime = self.fadeInTime

		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			fadeTime = self.fadeOutTime
		end

		local valueX = self.fadeCur[1] + math.abs(self.fadeX[1] - self.fadeX[2]) * dt / fadeTime * self.fadeDir[1]
		local valueY = self.fadeCur[2] + math.abs(self.fadeY[1] - self.fadeY[2]) * dt / fadeTime * self.fadeDir[2]
		self.fadeCur[1] = MathUtil.clamp(valueX, self.fadeX[1], self.fadeX[2])
		self.fadeCur[2] = MathUtil.clamp(valueY, self.fadeY[1], self.fadeY[2])

		setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)

		if self.showOnFirstUse then
			if self.hasValidMaterial then
				setVisibility(self.node, true)
			end
		else
			local isVisible = true

			if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
				isVisible = self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[1]
			end

			setVisibility(self.node, isVisible and self.hasValidMaterial)
		end

		if (self.state ~= ShaderPlaneEffect.STATE_TURNING_ON or self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[2]) and (self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF or self.fadeCur[1] ~= self.fadeX[2] or self.fadeCur[2] ~= self.fadeY[1]) then
			isRunning = true
		end
	else
		isRunning = true
	end

	if self.alignXAxisToWorldY then
		local _, dy, dz = worldDirectionToLocal(self.worldYReferenceFrame, 0, 1, 0)
		local alpha = math.atan2(dz, dy)
		local _, ry, rz = getRotation(self.node)

		setRotation(self.node, alpha, ry, rz)
	end

	if self.alignToWorldY then
		I3DUtil.setWorldDirection(self.node, 0, 0, 1, 0, 1, 0)
	end

	if not isRunning then
		if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
			self.state = ShaderPlaneEffect.STATE_ON
		elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			self.state = ShaderPlaneEffect.STATE_OFF
		end
	end
end

function ShaderPlaneEffect:isRunning()
	return self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON
end

function ShaderPlaneEffect:start()
	if self.state ~= ShaderPlaneEffect.STATE_TURNING_ON and self.state ~= ShaderPlaneEffect.STATE_ON then
		self.state = ShaderPlaneEffect.STATE_TURNING_ON
		self.fadeCur = {
			-1,
			1
		}
		self.fadeDir = {
			1,
			1
		}
		self.currentDelay = self.startDelay

		return true
	end

	return false
end

function ShaderPlaneEffect:stop()
	if self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF and self.state ~= ShaderPlaneEffect.STATE_OFF then
		self.state = ShaderPlaneEffect.STATE_TURNING_OFF
		self.fadeDir = {
			1,
			-1
		}
		self.currentDelay = self.stopDelay

		return true
	end

	return false
end

function ShaderPlaneEffect:reset()
	self.fadeCur = {
		-1,
		1
	}
	self.fadeDir = {
		1,
		-1
	}

	setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], 0, 0, false)
	setVisibility(self.node, false)

	self.state = ShaderPlaneEffect.STATE_OFF
end

function ShaderPlaneEffect:setFillType(fillType, force)
	local success = true

	if self.dynamicFillType and self.lastFillType ~= fillType or force then
		if self.materialType ~= nil and self.materialTypeId ~= nil then
			local material = g_materialManager:getMaterial(fillType, self.materialType, self.materialTypeId)

			if material == nil and self.defaultFillType ~= nil then
				material = g_materialManager:getMaterial(self.defaultFillType, self.materialType, self.materialTypeId)
			end

			self.hasValidMaterial = material ~= nil

			if material ~= nil then
				if self.materialType == "smoke" and self.materialTypeId == 1 then
					setObjectMask(self.node, 16711807)
				end

				setMaterial(self.node, material, 0)

				if self.fadeScale ~= nil then
					local x, y, z, _ = getShaderParameter(self.node, "vSpeedFrequencyAmplitudeFadescale")

					setShaderParameter(self.node, "vSpeedFrequencyAmplitudeFadescale", x, y, z, self.fadeScale, false)
				end

				if self.uvSpeed ~= nil then
					local x, _, z, w = getShaderParameter(self.node, "UVScaleSpeed")

					setShaderParameter(self.node, "UVScaleSpeed", x, self.uvSpeed, z, w, false)
				end
			else
				success = false
			end
		end

		self.lastFillType = fillType
	end

	return success
end

function ShaderPlaneEffect:getIsFullyVisible()
	return math.abs(self.fadeCur[1] - self.fadeX[2]) < 0.05 and math.abs(self.fadeCur[2] - self.fadeY[2]) < 0.05
end

function ShaderPlaneEffect:setDelays(startDelay, stopDelay)
	if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
		self.currentDelay = math.max(0, self.currentDelay + startDelay - self.startDelay)
	elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
		self.currentDelay = math.max(0, self.currentDelay + stopDelay - self.stopDelay)
	end

	self.startDelay = startDelay
	self.stopDelay = stopDelay
end

function ShaderPlaneEffect:setOffset(offset)
	self.offset = offset
end

function ShaderPlaneEffect:setDistance(distance)
	if self.useDistance then
		distance = distance + self.extraDistance

		if self.extraDistanceNode ~= nil then
			local _, y, _ = localToLocal(self.node, self.extraDistanceNode, 0, 0, 0)
			distance = distance + y
		end

		local percent = (distance - self.fadeXDistance[1]) / (self.fadeXDistance[2] - self.fadeXDistance[1])
		self.fadeX[2] = 2 * percent - 1
	end
end
