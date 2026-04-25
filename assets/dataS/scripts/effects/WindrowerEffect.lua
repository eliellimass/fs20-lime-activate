WindrowerEffect = {}
local WindrowerEffect_mt = Class(WindrowerEffect, MorphPositionEffect)

function WindrowerEffect:new(customMt)
	if customMt == nil then
		customMt = WindrowerEffect_mt
	end

	local self = MorphPositionEffect:new(customMt)

	return self
end

function WindrowerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not WindrowerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.unloadDirection = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "unloadDirection"), 0)
	self.width = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "width"), 0)
	self.dropOffset = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "dropOffset"), 0)
	self.turnOffRequiredEffect = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "turnOffRequiredEffect"), 0)
	self.testAreas = {}
	local i = 0

	while true do
		local areaKey = key .. string.format(".testArea(%d)", i)

		if not hasXMLProperty(xmlFile, areaKey) then
			break
		end

		local start = I3DUtil.indexToObject(self.rootNodes, Effect.getValue(xmlFile, areaKey, getXMLString, node, "startNode"), i3dMapping)
		local width = I3DUtil.indexToObject(self.rootNodes, Effect.getValue(xmlFile, areaKey, getXMLString, node, "widthNode"), i3dMapping)
		local height = I3DUtil.indexToObject(self.rootNodes, Effect.getValue(xmlFile, areaKey, getXMLString, node, "heightNode"), i3dMapping)

		table.insert(self.testAreas, {
			start = start,
			width = width,
			height = height
		})

		i = i + 1
	end

	self.particleSystems = {}
	i = 0

	while true do
		local particleKey = key .. string.format(".particleSystem(%d)", i)

		if not hasXMLProperty(xmlFile, particleKey) then
			break
		end

		local emitterShape = I3DUtil.indexToObject(self.rootNodes, getXMLString(xmlFile, particleKey .. "#emitterShape"), i3dMapping)
		local particleType = getXMLString(xmlFile, particleKey .. "#particleType")
		local fillTypeNames = Utils.getNoNil(getXMLString(xmlFile, particleKey .. "#fillTypes"), "grass_windrow dryGrass_windrow straw")
		local fadeInRange = StringUtil.getVectorNFromString(getXMLString(xmlFile, particleKey .. "#fadeInRange"), 2)
		local fadeOutRange = StringUtil.getVectorNFromString(getXMLString(xmlFile, particleKey .. "#fadeOutRange"), 2)

		if emitterShape ~= nil then
			local x, y, z = getWorldTranslation(emitterShape)
			local xOffset, _, _ = worldToLocal(self.node, x, y, z)
			local particleSystems = {}
			local fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames)

			for _, fillType in pairs(fillTypes) do
				local particleSystem = g_particleSystemManager:getParticleSystem(fillType, particleType)

				if particleSystem ~= nil then
					local ps = ParticleUtil.copyParticleSystem(xmlFile, particleKey, particleSystem, emitterShape)
					ps.fillType = fillType

					table.insert(particleSystems, ps)
				end
			end

			table.insert(self.particleSystems, {
				xOffset = xOffset,
				fadeInRange = fadeInRange,
				fadeOutRange = fadeOutRange,
				particleSystems = particleSystems
			})
		end

		i = i + 1
	end

	self.lastChargeTime = 0
	self.updateTick = 0
	self.scrollUpdate = false
	self.particleSystemsTurnedOff = false

	return true
end

function WindrowerEffect:delete()
	WindrowerEffect:superClass().delete(self)

	for _, particleSystemData in ipairs(self.particleSystems) do
		ParticleUtil.deleteParticleSystems(particleSystemData.particleSystems)
	end
end

function WindrowerEffect:update(dt)
	WindrowerEffect:superClass().update(self, dt)

	if self.updateTick > 5 and self.state ~= ShaderPlaneEffect.STATE_OFF then
		local minX, maxX, foundFillType = WindrowerEffect.getCurrentTestAreaWidth(self)

		setShaderParameter(self.node, "offsetUV", self.scrollPosition, 0, minX, maxX, false)

		for _, particleSystemData in ipairs(self.particleSystems) do
			local inFadeInRange = particleSystemData.fadeInRange[1] <= self.fadeCur[1] and self.fadeCur[1] <= particleSystemData.fadeInRange[2]
			local inFadeOutRange = particleSystemData.fadeOutRange[1] <= self.fadeCur[2] and self.fadeCur[2] <= particleSystemData.fadeOutRange[2]
			local inXRange = minX <= particleSystemData.xOffset and particleSystemData.xOffset <= maxX

			if inXRange and inFadeInRange and inFadeOutRange and self.state ~= ShaderPlaneEffect.STATE_OFF then
				for _, ps in ipairs(particleSystemData.particleSystems) do
					ParticleUtil.setEmittingState(ps, ps.fillType == foundFillType)
				end
			else
				for _, ps in ipairs(particleSystemData.particleSystems) do
					ParticleUtil.setEmittingState(ps, false)
				end
			end
		end

		self.updateTick = 0
		self.particleSystemsTurnedOff = false
	elseif not self.particleSystemsTurnedOff then
		for _, particleSystemData in ipairs(self.particleSystems) do
			for _, ps in ipairs(particleSystemData.particleSystems) do
				ParticleUtil.setEmittingState(ps, false)
			end
		end

		self.particleSystemsTurnedOff = true
	end

	local _, y, z, w = getShaderParameter(self.node, "offsetUV")
	self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength

	setShaderParameter(self.node, "offsetUV", self.scrollPosition, y, z, w, false)

	self.updateTick = self.updateTick + 1
end

function WindrowerEffect:start()
	local success = WindrowerEffect:superClass().start(self)

	if success and self.unloadDirection ~= 0 then
		local minX, fade = WindrowerEffect.getCurrentTestAreaWidth(self, true)

		if self.unloadDirection < 0 then
			fade = minX
		end

		fade = fade / (self.width / 2)
		fade = (fade + 1) / 2
		self.fadeCur[2] = MathUtil.clamp(fade, 0, 1)

		if self.unloadDirection < 0 then
			self.fadeCur[2] = math.abs(1 - self.fadeCur[2])
		end
	end

	return success
end

function WindrowerEffect:stop()
	local success = WindrowerEffect:superClass().stop(self)

	if success and self.unloadDirection ~= 0 and self.fadeCur[1] == 0 then
		local _, _, fade, maxX = getShaderParameter(self.node, "offsetUV")

		if self.unloadDirection < 0 then
			fade = maxX
		end

		fade = fade / (self.width / 2)
		fade = (fade + 1) / 2
		self.fadeCur[1] = MathUtil.clamp(fade, 0, 1)

		if self.unloadDirection < 0 then
			self.fadeCur[1] = math.abs(1 - self.fadeCur[1])
		end
	end

	return success
end

function WindrowerEffect:getCurrentTestAreaWidth(real)
	local minX = self.width / 2 + self.dropOffset
	local maxX = -self.width / 2 - self.dropOffset
	local foundFillType = FillType.UNKNOWN

	for _, testArea in ipairs(self.testAreas) do
		local x0, y0, z0 = getWorldTranslation(testArea.start)
		local x1, y1, z1 = getWorldTranslation(testArea.width)
		local x2, _, z2 = getWorldTranslation(testArea.height)
		local fillType = DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)

		if fillType ~= FillType.UNKNOWN then
			local xStart, _, _ = worldToLocal(self.node, x0, y0, z0)
			local xWidth, _, _ = worldToLocal(self.node, x1, y1, z1)

			if xStart < minX then
				minX = xStart
			end

			if maxX < xWidth then
				maxX = xWidth
			end

			foundFillType = fillType
		end
	end

	if (not real or real == nil) and self.unloadDirection ~= 0 then
		if self.unloadDirection < 0 then
			minX = -self.width / 2 - self.dropOffset
		end

		if self.unloadDirection > 0 then
			maxX = self.width / 2 + self.dropOffset
		end
	end

	return minX, maxX, foundFillType
end
