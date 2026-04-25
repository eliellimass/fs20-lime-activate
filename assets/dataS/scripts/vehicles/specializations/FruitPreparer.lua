FruitPreparer = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("fruitPreparer", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
}

function FruitPreparer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processFruitPreparerArea", FruitPreparer.processFruitPreparerArea)
end

function FruitPreparer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", FruitPreparer.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", FruitPreparer.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", FruitPreparer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCutterAIFruitRequirements", FruitPreparer.getAllowCutterAIFruitRequirements)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", FruitPreparer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", FruitPreparer.getWearMultiplier)
end

function FruitPreparer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", FruitPreparer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", FruitPreparer)
end

function FruitPreparer:onLoad(savegame)
	local spec = self.spec_fruitPreparer

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnAnimation#name", "vehicle.turnOnVehicle.turnedAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnAnimation#speed", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fruitPreparer#useReelStateToTurnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fruitPreparer#onlyActiveWhenLowered")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.vehicle.fruitPreparerSound", "vehicle.fruitPreparer.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.fruitPreparer.animationNodes.animationNode", "fruitPreparer")

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fruitPreparer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.fruitPreparer.animationNodes", self.components, self, self.i3dMappings)
	end

	spec.fruitType = FruitType.UNKNOWN
	local fruitType = getXMLString(self.xmlFile, "vehicle.fruitPreparer#fruitType")

	if fruitType ~= nil then
		local desc = g_fruitTypeManager:getFruitTypeByName(fruitType)

		if desc ~= nil then
			spec.fruitType = desc.index

			if self.setAIFruitRequirements ~= nil then
				self:setAIFruitRequirements(desc.index, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)

				local aiUsePreparedState = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.fruitPreparer#aiUsePreparedState"), self.spec_cutter ~= nil)

				if aiUsePreparedState then
					self:addAIFruitRequirement(desc.index, desc.preparedGrowthState, desc.preparedGrowthState)
				end
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Unable to find fruitType '%s' in fruitPreparer", fruitType)
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Missing fruitType in fruitPreparer")
	end

	spec.isWorking = false
end

function FruitPreparer:onDelete()
	if self.isClient then
		local spec = self.spec_fruitPreparer

		g_soundManager:deleteSamples(spec.samples)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function FruitPreparer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_fruitPreparer
		spec.isWorking = streamReadBool(streamId)
	end
end

function FruitPreparer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_fruitPreparer

		streamWriteBool(streamId, spec.isWorking)
	end
end

function FruitPreparer:onTurnedOn()
	if self.isClient then
		local spec = self.spec_fruitPreparer

		g_soundManager:playSample(spec.samples.work)
		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function FruitPreparer:onTurnedOff()
	if self.isClient then
		local spec = self.spec_fruitPreparer

		g_soundManager:stopSamples(spec.samples)
		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function FruitPreparer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.FRUITPREPARER then
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#dropStartIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#dropWidthIndex", key .. ".fruitPreparer#dropWorkAreaIndex")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#dropHeightIndex", key .. ".fruitPreparer#dropWorkAreaIndex")

		workArea.dropWorkAreaIndex = getXMLInt(xmlFile, key .. ".fruitPreparer#dropWorkAreaIndex")
	end

	return retValue
end

function FruitPreparer:getDoGroundManipulation(superFunc)
	local spec = self.spec_fruitPreparer

	return superFunc(self) and spec.isWorking
end

function FruitPreparer:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and (self.getIsImplementChainLowered == nil or self:getIsImplementChainLowered())
end

function FruitPreparer:getAllowCutterAIFruitRequirements(superFunc)
	return false
end

function FruitPreparer:getDirtMultiplier(superFunc)
	local spec = self.spec_fruitPreparer

	if spec.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function FruitPreparer:getWearMultiplier(superFunc)
	local spec = self.spec_fruitPreparer

	if spec.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function FruitPreparer.getDefaultSpeedLimit()
	return 15
end

function FruitPreparer:onStartWorkAreaProcessing(dt)
	local spec = self.spec_fruitPreparer
	spec.isWorking = false
end

function FruitPreparer:processFruitPreparerArea(workArea)
	local spec = self.spec_fruitPreparer
	local workAreaSpec = self.spec_workArea
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local dxs = xs
	local dzs = zs
	local dxw = xw
	local dzw = zw
	local dxh = xh
	local dzh = zh

	if workArea.dropWorkAreaIndex ~= nil then
		local dropArea = workAreaSpec.workAreas[workArea.dropWorkAreaIndex]

		if dropArea ~= nil then
			dxs, _, dzs = getWorldTranslation(dropArea.start)
			dxw, _, dzw = getWorldTranslation(dropArea.width)
			dxh, _, dzh = getWorldTranslation(dropArea.height)
		end
	end

	local area = FSDensityMapUtil.updateFruitPreparerArea(spec.fruitType, xs, zs, xw, zw, xh, zh, dxs, dzs, dxw, dzw, dxh, dzh)

	if area > 0 then
		spec.isWorking = true
	end

	return 0, area
end
