Cultivator = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("cultivator", true)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Cultivator.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processCultivatorArea", Cultivator.processCultivatorArea)
end

function Cultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cultivator.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", Cultivator.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cultivator.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cultivator.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cultivator.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cultivator.getIsWorkAreaActive)
end

function Cultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cultivator)
end

function Cultivator:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cultivator.directionNode#index", "vehicle.cultivator.directionNode#node")

	if self:getGroundReferenceNodeFromIndex(1) == nil then
		print("Warning: No ground reference nodes in  " .. self.configFileName)
	end

	local spec = self.spec_cultivator

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cultivator.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
	end

	spec.directionNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.cultivator.directionNode#node"), self.i3dMappings), self.components[1].node)
	spec.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cultivator.onlyActiveWhenLowered#value"), true)
	spec.isSubsoiler = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cultivator#isSubsoiler"), false)

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	end

	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.hasGroundContact = false
	spec.isWorking = false
	spec.limitToField = false
	spec.forceLimitToField = true
	spec.workAreaParameters = {
		limitToField = spec.limitToField,
		forceLimitToField = spec.forceLimitToField,
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastTotalArea = 0
	}
end

function Cultivator:onDelete()
	if self.isClient then
		local spec = self.spec_cultivator

		g_soundManager:deleteSamples(spec.samples)
	end
end

function Cultivator:processCultivatorArea(workArea, dt)
	local spec = self.spec_cultivator
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local params = spec.workAreaParameters
	local realArea, area = FSDensityMapUtil.updateCultivatorArea(xs, zs, xw, zw, xh, zh, not params.limitToField, not params.limitGrassDestructionToField, params.angle, nil)
	params.lastChangedArea = params.lastChangedArea + realArea
	params.lastStatsArea = params.lastStatsArea + realArea
	params.lastTotalArea = params.lastTotalArea + area

	if spec.isSubsoiler then
		FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
	end

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return realArea, area
end

function Cultivator:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

function Cultivator:getDoGroundManipulation(superFunc)
	local spec = self.spec_cultivator

	if not spec.isWorking then
		return false
	end

	return superFunc(self)
end

function Cultivator:getDirtMultiplier(superFunc)
	local spec = self.spec_cultivator
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / spec.speedLimit
	end

	return multiplier
end

function Cultivator:getWearMultiplier(superFunc)
	local spec = self.spec_cultivator
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / spec.speedLimit
	end

	return multiplier
end

function Cultivator:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.CULTIVATOR
	end

	return retValue
end

function Cultivator:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.CULTIVATOR then
		local spec = self.spec_cultivator

		if g_currentMission.time < spec.startActivationTime then
			return false
		end

		if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Cultivator:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_cultivator
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function Cultivator:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_cultivator
	spec.limitToField = false
end

function Cultivator:onDeactivate()
	if self.isClient then
		local spec = self.spec_cultivator

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function Cultivator:onStartWorkAreaProcessing(dt)
	local spec = self.spec_cultivator
	spec.isWorking = false
	local limitToField = spec.limitToField or spec.forceLimitToField
	local limitGrassDestructionToField = spec.limitToField or spec.forceLimitToField

	if not g_currentMission:getHasPlayerPermission("createFields", self:getOwner()) then
		limitToField = true
		limitGrassDestructionToField = true
	end

	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)
	spec.workAreaParameters.limitToField = limitToField
	spec.workAreaParameters.limitGrassDestructionToField = limitGrassDestructionToField
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastTotalArea = 0
end

function Cultivator:onEndWorkAreaProcessing(dt)
	local spec = self.spec_cultivator

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea

		if lastStatsArea > 0 then
			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("workedHectares", ha)
			stats:updateStats("cultivatedHectares", ha)
			stats:updateStats("workedTime", dt / 60000)
			stats:updateStats("cultivatedTime", dt / 60000)
		end
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

function Cultivator.getDefaultSpeedLimit()
	return 15
end
