CutterEffect = {}
local CutterEffect_mt = Class(CutterEffect, Effect)

function CutterEffect:new(customMt)
	if customMt == nil then
		customMt = CutterEffect_mt
	end

	self = Effect:new(customMt)
	self.minValue = 0
	self.maxValue = 0

	return self
end

function CutterEffect:load(xmlFile, baseName, rootNodes, parent, fruitTypeIndex, i3dMappings)
	self.fruitTypeIndex = fruitTypeIndex
	self.currentGrowthState = 0

	CutterEffect:superClass().load(self, xmlFile, baseName, rootNodes, parent, i3dMappings)
end

function CutterEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	local isThreshing = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "isThreshing"), true)
	local effectTypeName = Effect.getValue(xmlFile, key, getXMLString, node, "effectType")
	local effectType = g_cutterEffectManager:getCutterEffectTypeByName(effectTypeName)
	self.linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, getXMLString, node, "linkNode"), i3dMapping)
	self.growthStateNodes = {}
	local effects = g_cutterEffectManager:getCutterEffects(self.fruitTypeIndex, effectType, isThreshing)

	if effects ~= nil then
		self.node = createTransformGroup("effects")

		link(self.linkNode, self.node)
		setTranslation(self.node, 0, 0, 0)
		setRotation(self.node, 0, 0, 0)

		local loadedEffects = {}

		for growthState, effect in pairs(effects) do
			local currentEffect = loadedEffects[effect]

			if currentEffect == nil then
				currentEffect = clone(effect, false, false, true)

				setTranslation(currentEffect, 0, 0, 0)
				setScale(currentEffect, 1, 1, 1)
				setRotation(currentEffect, 0, 0, 0)
				link(self.node, currentEffect)
				setVisibility(currentEffect, false)

				local lengthAndRadius = StringUtil.getVectorNFromString(Effect.getValue(xmlFile, key, getXMLString, node, "lengthAndRadius"), 4)

				if lengthAndRadius ~= nil then
					setShaderParameter(currentEffect, "lengthAndRadius", lengthAndRadius[1], lengthAndRadius[2], lengthAndRadius[3], lengthAndRadius[4], false)
				end

				loadedEffects[effect] = currentEffect
			end

			self.growthStateNodes[growthState] = currentEffect
		end
	else
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(self.fruitTypeIndex)

		print("Warning: Could not load cutter effect '" .. effectTypeName .. "' (Threshing: " .. tostring(isThreshing) .. ") for fruitType '" .. fruitType.name .. "'!")
	end

	self.speedScale = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "speedScale"), 0.002)
	self.changeSpeedScale = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "changeSpeedScale"), self.speedScale)
	self.useInterpolation = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "useInterpolation"), false)
	self.useMaxValue = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "useMaxValue"), false)
	self.minOffset = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "minOffset"), 0)
	self.offset = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "offset"), 0)
	self.currentOffset = 0
	self.effectMinValue = 0
	self.effectMaxValue = 0
	self.effectAlpha = 1

	return true
end

function CutterEffect:transformEffectNode(xmlFile, key, node)
	if self.node ~= nil then
		CutterEffect:superClass().transformEffectNode(self, xmlFile, key, node)
		setVisibility(self.node, true)
	end
end

function CutterEffect:update(dt)
	CutterEffect:superClass().update(self, dt)

	self.currentOffset = self.currentOffset + dt * self.speedScale

	if self.useInterpolation then
		if self.useMaxValue then
			self.effectMinValue = math.min(self.effectMinValue + self.changeSpeedScale * dt, -self.maxValue, 0)
		else
			self.effectMinValue = math.min(self.effectMinValue + self.changeSpeedScale * dt, self.minValue, 0)
		end
	else
		if self.minValue < 0 then
			self.effectMinValue = math.max(self.effectMinValue - self.changeSpeedScale * dt, self.minValue)
		else
			self.effectMinValue = math.min(self.effectMinValue + self.changeSpeedScale * dt, self.minValue)
		end

		if self.maxValue < 0 then
			self.effectMaxValue = math.max(self.effectMaxValue - self.changeSpeedScale * dt, self.maxValue)
		else
			self.effectMaxValue = math.min(self.effectMaxValue + self.changeSpeedScale * dt, self.maxValue)
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		local x1, y1, z1 = localToWorld(self.growthStateNodes[self.currentGrowthState], self.minValue, 0, 0)
		local x2, y2, z2 = localToWorld(self.growthStateNodes[self.currentGrowthState], self.maxValue, 0, 0)

		drawDebugLine(x1, y1, z1, 0, 1, 0, x1, y1 + 2, z1, 0, 1, 0)
		drawDebugLine(x2, y2, z2, 0, 1, 0, x2, y2 + 2, z2, 0, 1, 0)
	end

	if self.effectMinValue == 0 and self.effectMaxValue == 0 then
		self.effectAlpha = 0
	else
		self.effectAlpha = MathUtil.clamp(self.effectAlpha + dt * 0.0025, 0, 1)
	end

	if self.growthStateNodes[self.currentGrowthState] ~= nil then
		setVisibility(self.growthStateNodes[self.currentGrowthState], self.effectAlpha ~= 0)
		setShaderParameter(self.growthStateNodes[self.currentGrowthState], "scrollPosition", self.currentOffset, self.effectAlpha, self.minOffset + self.effectMinValue, self.effectMaxValue, false)
	end
end

function CutterEffect:isRunning()
	return self.effectMinValue ~= 0 or self.effectMaxValue ~= 0
end

function CutterEffect:start()
	return true
end

function CutterEffect:stop()
	return true
end

function CutterEffect:reset()
	self.effectMinValue = 0
	self.effectMaxValue = 0
	self.effectAlpha = 0

	if self.growthStateNodes[self.currentGrowthState] ~= nil then
		setVisibility(self.growthStateNodes[self.currentGrowthState], false)
	end
end

function CutterEffect:setGrowthState(growthState)
	if self.growthStateNodes[self.currentGrowthState] ~= nil then
		setVisibility(self.growthStateNodes[self.currentGrowthState], false)
	end

	self.currentGrowthState = growthState
end

function CutterEffect:setMinMaxWidth(minValue, maxValue, reset)
	self.minValue = minValue + self.offset
	self.maxValue = maxValue + self.offset

	if reset and not self.useInterpolation then
		self.effectMinValue = minValue
		self.effectMaxValue = maxValue
	end

	if minValue ~= 0 or maxValue ~= 0 then
		g_effectManager:startEffect(self)
	end
end
