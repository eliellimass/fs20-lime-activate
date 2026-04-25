Weeder = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("weeder", true)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end
}

function Weeder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processWeederArea", Weeder.processWeederArea)
end

function Weeder.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Weeder.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Weeder.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Weeder.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Weeder.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Weeder.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundParticleMapping", Weeder.loadGroundParticleMapping)
end

function Weeder.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Weeder)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Weeder)
end

function Weeder:onLoad(savegame)
	local spec = self.spec_weeder

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.weeder.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
	end

	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.maxGrowthState = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.weeder.maxGrowthState"), 2)
	spec.workAreaParameters = {
		lastArea = 0,
		lastStatsArea = 0
	}
	spec.isWorking = false

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	end

	local fruitType = g_fruitTypeManager:getFruitTypeByName("weed")

	if fruitType ~= nil then
		self:setAIFruitRequirements(fruitType.index, 1, 1)
	end
end

function Weeder:onDelete()
	if self.isClient then
		local spec = self.spec_weeder

		g_soundManager:deleteSamples(spec.samples)
	end
end

function Weeder:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_weeder

	if spec.isWorking and spec.colorParticleSystems ~= nil then
		for _, mapping in ipairs(spec.colorParticleSystems) do
			local wx, wy, wz = getWorldTranslation(mapping.node)
			local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, wx, wy, wz)
			local isOnField = densityBits ~= 0

			if isOnField then
				mapping.lastColor[1], mapping.lastColor[2], mapping.lastColor[3], _ = FSDensityMapUtil.getTireTrackColorFromDensityBits(densityBits)
			else
				mapping.lastColor[1], mapping.lastColor[2], mapping.lastColor[3], _, _ = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz, true, true, true, true, false)
			end

			if mapping.targetColor == nil then
				mapping.targetColor = {
					mapping.lastColor[1],
					mapping.lastColor[2],
					mapping.lastColor[3]
				}
				mapping.currentColor = {
					mapping.lastColor[1],
					mapping.lastColor[2],
					mapping.lastColor[3]
				}
				mapping.alpha = 1
			end

			if mapping.alpha ~= 1 then
				mapping.alpha = math.min(mapping.alpha + dt / 1000, 1)
				mapping.currentColor = {
					MathUtil.vector3ArrayLerp(mapping.lastColor, mapping.targetColor, mapping.alpha)
				}

				if mapping.alpha == 1 then
					mapping.lastColor = {
						mapping.currentColor[1],
						mapping.currentColor[2],
						mapping.currentColor[3]
					}
				end
			end

			if mapping.alpha == 1 and mapping.lastColor[1] ~= mapping.targetColor[1] and mapping.lastColor[2] ~= mapping.targetColor[2] and mapping.lastColor[3] ~= mapping.targetColor[3] then
				mapping.alpha = 0
				mapping.targetColor = {
					mapping.lastColor[1],
					mapping.lastColor[2],
					mapping.lastColor[3]
				}
			end

			setShaderParameter(mapping.particleSystem.shape, "psColor", mapping.currentColor[1], mapping.currentColor[2], mapping.currentColor[3], 1, false)
		end
	end
end

function Weeder:processWeederArea(workArea, dt)
	local spec = self.spec_weeder
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local area = FSDensityMapUtil.updateWeederArea(xs, zs, xw, zw, xh, zh, spec.maxGrowthState)
	spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + area
	spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + area
	spec.isWorking = self:getLastSpeed() > 0.5

	return area, area
end

function Weeder:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.WEEDER
	end

	return superFunc(self, workArea, xmlFile, key)
end

function Weeder:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.WEEDER then
		local isActive = true

		if workArea.requiresGroundContact and workArea.groundReferenceNode ~= nil then
			isActive = isActive and self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode)
		end

		if isActive and workArea.disableBackwards then
			isActive = isActive and self.movingDirection > 0
		end

		return isActive
	end

	return superFunc(self, workArea)
end

function Weeder:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

function Weeder:getDirtMultiplier(superFunc)
	local spec = self.spec_weeder
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Weeder:getWearMultiplier(superFunc)
	local spec = self.spec_weeder
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Weeder:loadGroundParticleMapping(superFunc, xmlFile, key, mapping, index, i3dNode)
	if not superFunc(self, xmlFile, key, mapping, index, i3dNode) then
		return false
	end

	mapping.adjustColor = Utils.getNoNil(getXMLBool(xmlFile, key .. "#adjustColor"), false)

	if mapping.adjustColor then
		local spec = self.spec_weeder

		if spec.colorParticleSystems == nil then
			spec.colorParticleSystems = {}
		end

		mapping.lastColor = {}

		table.insert(spec.colorParticleSystems, mapping)
	end

	return true
end

function Weeder:onStartWorkAreaProcessing(dt)
	local spec = self.spec_weeder
	spec.isWorking = false
	spec.workAreaParameters.lastArea = 0
	spec.workAreaParameters.lastStatsArea = 0
end

function Weeder:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_weeder

	if self.isServer and spec.workAreaParameters.lastStatsArea > 0 then
		local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
		local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

		stats:updateStats("workedHectares", ha)
		stats:updateStats("workedTime", dt / 60000)
	end

	if self.isClient then
		if spec.isWorking then
			if not spec.isWorkSamplePlaying then
				g_soundManager:playSample(spec.samples.work)

				spec.isWorkSamplePlaying = true
			end
		elseif spec.isWorkSamplePlaying then
			g_soundManager:stopSample(spec.samples.work)

			spec.isWorkSamplePlaying = false
		end
	end
end

function Weeder:onDeactivate()
	if self.isClient then
		local spec = self.spec_weeder

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function Weeder:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_weeder
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function Weeder.getDefaultSpeedLimit()
	return 15
end
