source("dataS/scripts/vehicles/specializations/events/SetSeedIndexEvent.lua")

SowingMachine = {
	DAMAGED_USAGE_INCREASE = 0.3
}

function SowingMachine.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("sowingMachine", true)
	g_storeManager:addSpecType("seedFillTypes", "shopListAttributeIconSeeds", SowingMachine.loadSpecValueSeedFillTypes, SowingMachine.getSpecValueSeedFillTypes)
end

function SowingMachine.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end

function SowingMachine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedFruitType", SowingMachine.setSeedFruitType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedIndex", SowingMachine.setSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "changeSeedIndex", SowingMachine.changeSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsSeedChangeAllowed", SowingMachine.getIsSeedChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getSowingMachineFillUnitIndex", SowingMachine.getSowingMachineFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSeedTypeIcon", SowingMachine.getCurrentSeedTypeIcon)
	SpecializationUtil.registerFunction(vehicleType, "processSowingMachineArea", SowingMachine.processSowingMachineArea)
	SpecializationUtil.registerFunction(vehicleType, "getUseSowingMachineAIRquirements", SowingMachine.getUseSowingMachineAIRquirements)
	SpecializationUtil.registerFunction(vehicleType, "setFillTypeSourceDisplayFillType", SowingMachine.setFillTypeSourceDisplayFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateMissionSowingWarning", SowingMachine.updateMissionSowingWarning)
end

function SowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", SowingMachine.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SowingMachine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", SowingMachine.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", SowingMachine.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowFillFromAir", SowingMachine.getAllowFillFromAir)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", SowingMachine.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", SowingMachine.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SowingMachine.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SowingMachine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SowingMachine.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", SowingMachine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", SowingMachine.getCanBeSelected)
end

function SowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", SowingMachine)
end

function SowingMachine:onLoad(savegame)
	local spec = self.spec_sowingMachine

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.sowingMachine.animationNodes.animationNode", "sowingMachine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnScrollers", "vehicle.sowingMachine.scrollerNodes.scrollerNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.useDirectPlanting", "vehicle.sowingMachine.useDirectPlanting#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.needsActivation#value", "vehicle.sowingMachine.needsActivation#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.sowingEffects", "vehicle.sowingMachine.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.sowingEffectsWithFixedFillType", "vehicle.sowingMachine.fixedEffects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.sowingMachine#supportsAiWithoutSowingMachine", "vehicle.turnOnVehicle.aiRequiresTurnOn")

	spec.allowFillFromAirWhileTurnedOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value"), true)
	spec.directionNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.sowingMachine.directionNode#index"), self.i3dMappings), self.components[1].node)
	spec.useDirectPlanting = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sowingMachine.useDirectPlanting#value"), false)
	spec.isWorking = false
	spec.isProcessing = false
	spec.seeds = {}
	local fruitTypes = {}
	local fruitTypeCategories = getXMLString(self.xmlFile, "vehicle.sowingMachine.seedFruitTypeCategories")
	local fruitTypeNames = getXMLString(self.xmlFile, "vehicle.sowingMachine.seedFruitTypes")

	if fruitTypeCategories ~= nil and fruitTypeNames == nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames(fruitTypeCategories, "Warning: '" .. self.configFileName .. "' has invalid fruitTypeCategory '%s'.")
	elseif fruitTypeCategories == nil and fruitTypeNames ~= nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByNames(fruitTypeNames, "Warning: '" .. self.configFileName .. "' has invalid fruitType '%s'.")
	else
		print("Warning: '" .. self.configFileName .. "' a sowingMachine needs either the 'seedFruitTypeCategories' or 'seedFruitTypes' element.")
	end

	if fruitTypes ~= nil then
		for _, fruitType in pairs(fruitTypes) do
			table.insert(spec.seeds, fruitType)
		end
	end

	spec.needsActivation = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sowingMachine.needsActivation#value"), false)
	spec.requiresFilling = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sowingMachine.requiresFilling#value"), true)

	if self.isClient then
		spec.isWorkSamplePlaying = false
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			airBlower = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "airBlower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.sampleFillEnabled = false
		spec.sampleFillStopTime = -1
		spec.lastFillLevel = -1
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sowingMachine.animationNodes", self.components, self, self.i3dMappings)

		g_animationManager:setFillType(spec.animationNodes, FillType.UNKNOWN)

		local changeSeedInputButtonStr = getXMLString(self.xmlFile, "vehicle.sowingMachine.changeSeedInputButton")

		if changeSeedInputButtonStr ~= nil then
			spec.changeSeedInputButton = InputAction[changeSeedInputButtonStr]
		end

		spec.changeSeedInputButton = Utils.getNoNil(spec.changeSeedInputButton, InputAction[g_platformSettingsManager:getSetting("changeSeedButton", "IMPLEMENT_EXTRA3")])
	end

	spec.currentSeed = 1
	spec.allowsSeedChanging = true
	spec.showFruitCanNotBePlantedWarning = false
	spec.showWrongFruitForMissionWarning = false
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.sowingMachine#fillUnitIndex"), 1)
	spec.unloadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.sowingMachine#unloadInfoIndex"), 1)
	spec.loadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.sowingMachine#loadInfoIndex"), 1)
	spec.fillTypeSources = {}

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sowingMachine.effects", self.components, self, self.i3dMappings)
	end

	spec.workAreaParameters = {
		seedsFruitType = nil,
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastArea = 0
	}

	self:setSeedIndex(1, true)

	if savegame ~= nil then
		local selectedSeedFruitType = getXMLString(savegame.xmlFile, savegame.key .. ".sowingMachine#selectedSeedFruitType")

		if selectedSeedFruitType ~= nil then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(selectedSeedFruitType)

			if fruitTypeDesc ~= nil then
				self:setSeedFruitType(fruitTypeDesc.index, true)
			end
		end
	end
end

function SowingMachine:onPostLoad(savegame)
	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onDelete()
	local spec = self.spec_sowingMachine

	if self.isClient then
		for _, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end

		g_effectManager:deleteEffects(spec.effects)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function SowingMachine:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_sowingMachine
	local selectedSeedFruitTypeName = "unknown"
	local selectedSeedFruitType = spec.seeds[spec.currentSeed]

	if selectedSeedFruitType ~= nil and selectedSeedFruitType ~= FruitType.UNKNOWN then
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(selectedSeedFruitType)
		selectedSeedFruitTypeName = fruitType.name
	end

	setXMLString(xmlFile, key .. "#selectedSeedFruitType", selectedSeedFruitTypeName)
end

function SowingMachine:onReadStream(streamId, connection)
	local seedIndex = streamReadUInt8(streamId)

	self:setSeedIndex(seedIndex, true)
end

function SowingMachine:onWriteStream(streamId, connection)
	local spec = self.spec_sowingMachine

	streamWriteUInt8(streamId, spec.currentSeed)
end

function SowingMachine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_sowingMachine

	if self.isClient then
		if spec.isProcessing then
			local fillType = self:getFillUnitForcedMaterialFillType(spec.fillUnitIndex)

			if fillType ~= nil then
				g_effectManager:setFillType(spec.effects, fillType)
				g_effectManager:startEffects(spec.effects)
			end
		else
			g_effectManager:stopEffects(spec.effects)
		end
	end
end

function SowingMachine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_sowingMachine
	local actionEvent = spec.actionEvents[spec.changeSeedInputButton]

	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsSeedChangeAllowed())
	end
end

function SowingMachine:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_sowingMachine

	if self.isClient then
		if spec.showFruitCanNotBePlantedWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_theSelectedFruitTypeIsNotAvailableOnThisMap"))
		elseif spec.showWrongFruitForMissionWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_theSelectedFruitTypeIsWrongForTheMission"))
		end
	end
end

function SowingMachine:setSeedIndex(seedIndex, noEventSend)
	local spec = self.spec_sowingMachine

	SetSeedIndexEvent.sendEvent(self, seedIndex, noEventSend)

	spec.currentSeed = math.min(math.max(seedIndex, 1), table.getn(spec.seeds))
	local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed])

	self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, fillType, true)
	self:setFillTypeSourceDisplayFillType(fillType)
	SowingMachine.updateAiParameters(self)
	SowingMachine.updateChooseSeedActionEvent(self)
end

function SowingMachine:changeSeedIndex()
	local spec = self.spec_sowingMachine
	local seed = spec.currentSeed + 1

	if table.getn(spec.seeds) < seed then
		seed = 1
	end

	self:setSeedIndex(seed)
end

function SowingMachine:setSeedFruitType(fruitType, noEventSend)
	local spec = self.spec_sowingMachine

	for i, v in ipairs(spec.seeds) do
		if v == fruitType then
			self:setSeedIndex(i, noEventSend)

			break
		end
	end
end

function SowingMachine:getIsSeedChangeAllowed()
	return self.spec_sowingMachine.allowsSeedChanging
end

function SowingMachine:getSowingMachineFillUnitIndex()
	return self.spec_sowingMachine.fillUnitIndex
end

function SowingMachine:getCurrentSeedTypeIcon()
	local spec = self.spec_sowingMachine
	local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(spec.seeds[spec.currentSeed])

	if fillType ~= nil then
		return fillType.hudOverlayFilenameSmall
	end

	return nil
end

function SowingMachine:processSowingMachineArea(workArea, dt)
	local spec = self.spec_sowingMachine
	local changedArea = 0
	local totalArea = 0
	spec.isWorking = self:getLastSpeed() > 0.5

	if not spec.workAreaParameters.isActive then
		return changedArea, totalArea
	end

	if (not self:getIsAIActive() or not g_currentMission.missionInfo.helperBuySeeds) and spec.workAreaParameters.seedsVehicle == nil then
		if self:getIsAIActive() then
			local rootVehicle = self:getRootVehicle()

			rootVehicle:stopAIVehicle(AIVehicle.STOP_REASON_OUT_OF_FILL)
		end

		return changedArea, totalArea
	end

	if not spec.workAreaParameters.canFruitBePlanted then
		return changedArea, totalArea
	end

	local sx, _, sz = getWorldTranslation(workArea.start)
	local wx, _, wz = getWorldTranslation(workArea.width)
	local hx, _, hz = getWorldTranslation(workArea.height)
	spec.isProcessing = spec.isWorking

	if not spec.useDirectPlanting then
		local area, _ = FSDensityMapUtil.updateSowingArea(spec.workAreaParameters.seedsFruitType, sx, sz, wx, wz, hx, hz, spec.workAreaParameters.angle, nil)
		changedArea = changedArea + area
	else
		local area, _ = FSDensityMapUtil.updateDirectSowingArea(spec.workAreaParameters.seedsFruitType, sx, sz, wx, wz, hx, hz, spec.workAreaParameters.angle, nil)
		changedArea = changedArea + area
	end

	spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
	spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
	spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea

	FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
	self:updateMissionSowingWarning(sx, sz)

	return changedArea, totalArea
end

function SowingMachine:updateMissionSowingWarning(x, z)
	local spec = self.spec_sowingMachine
	spec.showWrongFruitForMissionWarning = false

	if self:getLastTouchedFarmlandFarmId() == 0 then
		local mission = g_missionManager:getMissionAtWorldPosition(x, z)

		if mission ~= nil and mission.type.name == "sow" and mission.fruitType ~= spec.workAreaParameters.seedsFruitType then
			spec.showWrongFruitForMissionWarning = true
		end
	end
end

function SowingMachine:getUseSowingMachineAIRquirements()
	return self:getAIRequiresTurnOn() or self:getIsTurnedOn()
end

function SowingMachine:setFillTypeSourceDisplayFillType(fillType)
	local spec = self.spec_sowingMachine

	if spec.fillTypeSources[FillType.SEEDS] ~= nil then
		for _, src in ipairs(spec.fillTypeSources[FillType.SEEDS]) do
			local vehicle = src.vehicle

			if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == FillType.SEEDS then
				vehicle:setFillUnitFillTypeToDisplay(src.fillUnitIndex, fillType)

				break
			end
		end
	end
end

function SowingMachine:getDrawFirstFillText(superFunc)
	local spec = self.spec_sowingMachine

	if self.isClient and self:getIsActiveForInput() and self:getIsSelected() and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return true
	end

	return superFunc(self)
end

function SowingMachine:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_sowingMachine

	if spec.requiresFilling and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return false, g_i18n:getText("info_firstFillTheTool")
	end

	return superFunc(self)
end

function SowingMachine:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	if superFunc(self, fillUnitIndex, fillType) then
		return true
	end

	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, fillType) and (fillType == FillType.SEEDS or spec.fillUnits[fillUnitIndex].fillType == FillType.SEEDS) then
		return true
	end

	return false
end

function SowingMachine:getCanToggleTurnedOn(superFunc)
	local spec = self.spec_sowingMachine

	if not spec.needsActivation then
		return false
	end

	return superFunc(self)
end

function SowingMachine:getAllowFillFromAir(superFunc)
	local spec = self.spec_sowingMachine

	if self:getIsTurnedOn() and not spec.allowFillFromAirWhileTurnedOn then
		return false
	end

	return superFunc(self)
end

function SowingMachine:getDirectionSnapAngle(superFunc)
	local spec = self.spec_sowingMachine
	local seedsFruitType = spec.seeds[spec.currentSeed]
	local desc = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)
	local snapAngle = 0

	if desc ~= nil then
		snapAngle = desc.directionSnapAngle
	end

	return math.max(snapAngle, superFunc(self))
end

function SowingMachine:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
	local spec = self.spec_sowingMachine

	if fillUnitIndex == spec.fillUnitIndex then
		if self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
			fillType = FillType.SEEDS

			self:setFillUnitForcedMaterialFillType(fillUnitIndex, fillType)
		end

		local fruitType = spec.seeds[spec.currentSeed]

		if fruitType ~= nil then
			local seedsFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)

			if seedsFillType ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, seedsFillType) then
				self:setFillUnitForcedMaterialFillType(fillUnitIndex, seedsFillType)
			end
		end
	end

	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
end

function SowingMachine:doCheckSpeedLimit(superFunc)
	local spec = self.spec_sowingMachine

	return superFunc(self) or self:getIsImplementChainLowered() and (not spec.needsActivation or self:getIsTurnedOn())
end

function SowingMachine:getDirtMultiplier(superFunc)
	local spec = self.spec_sowingMachine
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function SowingMachine:getWearMultiplier(superFunc)
	local spec = self.spec_sowingMachine
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function SowingMachine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SOWINGMACHINE
	end

	return retValue
end

function SowingMachine:getCanBeSelected(superFunc)
	return true
end

function SowingMachine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_sowingMachine

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and table.getn(spec.seeds) > 1 then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.changeSeedInputButton, self, SowingMachine.actionEventToggleSeedType, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			SowingMachine.updateChooseSeedActionEvent(self)
		end
	end
end

function SowingMachine:updateChooseSeedActionEvent()
	local spec = self.spec_sowingMachine
	local actionEvent = spec.actionEvents[spec.changeSeedInputButton]

	if actionEvent ~= nil then
		local additionalText = ""
		local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed]))

		if fillType ~= nil and fillType ~= FillType.UNKNOWN then
			additionalText = string.format(" (%s)", fillType.title)
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format("%s%s", g_i18n:getText("action_chooseSeed"), additionalText))
	end
end

function SowingMachine:onTurnedOn()
	if self.isClient then
		local spec = self.spec_sowingMachine

		g_soundManager:playSample(spec.samples.airBlower)
		g_animationManager:startAnimations(spec.animationNodes)
	end

	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onTurnedOff()
	if self.isClient then
		local spec = self.spec_sowingMachine

		g_soundManager:stopSample(spec.samples.airBlower)
		g_animationManager:stopAnimations(spec.animationNodes)
	end

	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onStartWorkAreaProcessing(dt)
	local spec = self.spec_sowingMachine
	spec.isWorking = false
	spec.isProcessing = false
	local seedsFruitType = spec.seeds[spec.currentSeed]
	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)

	if desc ~= nil and desc.directionSnapAngle ~= 0 then
		angleRad = math.floor(angleRad / desc.directionSnapAngle + 0.5) * desc.directionSnapAngle
	end

	local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.terrainDetailAngleMaxValue)
	local seedsVehicle, seedsVehicleFillUnitIndex = nil

	if self:getFillUnitFillLevel(spec.fillUnitIndex) > 0 then
		seedsVehicle = self
		seedsVehicleFillUnitIndex = spec.fillUnitIndex
	elseif spec.fillTypeSources[FillType.SEEDS] ~= nil then
		for _, src in ipairs(spec.fillTypeSources[FillType.SEEDS]) do
			local vehicle = src.vehicle

			if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == FillType.SEEDS then
				seedsVehicle = vehicle
				seedsVehicleFillUnitIndex = src.fillUnitIndex

				break
			end
		end
	end

	if seedsVehicle ~= nil and seedsVehicle ~= self then
		local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(seedsFruitType)

		seedsVehicle:setFillUnitFillTypeToDisplay(seedsVehicleFillUnitIndex, fillType)
	end

	local canFruitBePlanted = false

	if g_currentMission.fruits ~= nil and g_currentMission.fruits[seedsFruitType] ~= nil and g_currentMission.fruits[seedsFruitType].id ~= nil and g_currentMission.fruits[seedsFruitType].id ~= 0 then
		canFruitBePlanted = true
	end

	if spec.showWrongFruitForMissionWarning then
		spec.showWrongFruitForMissionWarning = false
	end

	spec.showFruitCanNotBePlantedWarning = not canFruitBePlanted
	spec.workAreaParameters.isActive = not spec.needsActivation or self:getIsTurnedOn()
	spec.workAreaParameters.canFruitBePlanted = canFruitBePlanted
	spec.workAreaParameters.seedsFruitType = seedsFruitType
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.seedsVehicle = seedsVehicle
	spec.workAreaParameters.seedsVehicleFillUnitIndex = seedsVehicleFillUnitIndex
	spec.workAreaParameters.lastTotalArea = 0
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
end

function SowingMachine:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_sowingMachine

	if self.isServer then
		local stats = g_farmManager:getFarmById(self:getLastTouchedFarmlandFarmId()).stats

		if spec.workAreaParameters.lastChangedArea > 0 then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.seedsFruitType)
			local lastHa = MathUtil.areaToHa(spec.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
			local usage = fruitDesc.seedUsagePerSqm * lastHa * 10000
			local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local damage = self:getVehicleDamage()

			if damage > 0 then
				usage = usage * (1 + damage * SowingMachine.DAMAGED_USAGE_INCREASE)
			end

			stats:updateStats("seedUsage", usage)
			stats:updateStats("sownHectares", ha)
			stats:updateStats("workedHectares", ha)

			if not self:getIsAIActive() or not g_currentMission.missionInfo.helperBuySeeds then
				local vehicle = spec.workAreaParameters.seedsVehicle
				local fillUnitIndex = spec.workAreaParameters.seedsVehicleFillUnitIndex
				local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
				local unloadInfo = nil

				vehicle:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, -usage, fillType, ToolType.UNDEFINED, unloadInfo)
			else
				local price = usage * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.PURCHASE_SEEDS)
			end
		end

		stats:updateStats("sownTime", dt / 60000)
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

function SowingMachine:onDeactivate()
	local spec = self.spec_sowingMachine

	if self.isClient then
		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function SowingMachine:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH or Vehicle.STATE_CHANGE_FILLTYPE_CHANGE then
		local spec = self.spec_sowingMachine
		spec.fillTypeSources = {}

		if FillType.SEEDS ~= nil then
			spec.fillTypeSources[FillType.SEEDS] = {}
			local root = self:getRootVehicle()

			FillUnit.addFillTypeSources(spec.fillTypeSources, root, self, {
				FillType.SEEDS
			})

			local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed])

			self:setFillTypeSourceDisplayFillType(fillType)
		end
	end
end

function SowingMachine:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local spec = self.spec_sowingMachine

	if fillUnitIndex == spec.fillUnitIndex then
		g_animationManager:setFillType(spec.animationNodes, fillTypeIndex)
	end
end

function SowingMachine:updateAiParameters()
	local spec = self.spec_sowingMachine

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:clearAITerrainDetailRequiredRange()
		self:clearAITerrainDetailProhibitedRange()

		local isCultivatorAttached = false
		local rootVehicle = self:getRootVehicle()

		if rootVehicle.getAttachedAIImplements ~= nil then
			for _, implement in ipairs(rootVehicle:getAttachedAIImplements()) do
				if SpecializationUtil.hasSpecialization(Cultivator, implement.object.specializations) then
					isCultivatorAttached = true
				end
			end
		end

		if SpecializationUtil.hasSpecialization(Cultivator, self.specializations) or isCultivatorAttached then
			self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

			if self:getUseSowingMachineAIRquirements() then
				self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			end
		elseif SpecializationUtil.hasSpecialization(Weeder, self.specializations) then
			self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

			if self:getUseSowingMachineAIRquirements() then
				self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
				self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			end
		else
			self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

			if spec.useDirectPlanting then
				self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
				self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
				self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			end
		end

		if self:getUseSowingMachineAIRquirements() then
			local fruitTypeIndex = spec.seeds[spec.currentSeed]
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

			if fruitTypeDesc ~= nil then
				self:setAIFruitProhibitions(fruitTypeIndex, 0, fruitTypeDesc.maxHarvestingGrowthState)
			end
		else
			self:clearAIFruitProhibitions()
		end
	end
end

function SowingMachine.getDefaultSpeedLimit()
	return 15
end

function SowingMachine:actionEventToggleSeedType(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSeedChangeAllowed() then
		self:changeSeedIndex()
	end
end

function SowingMachine.loadSpecValueSeedFillTypes(xmlFile, customEnvironment)
	local categories = Utils.getNoNil(getXMLString(xmlFile, "vehicle.storeData.specs.seedFruitTypeCategories"), getXMLString(xmlFile, "vehicle.sowingMachine.seedFruitTypeCategories"))
	local names = Utils.getNoNil(getXMLString(xmlFile, "vehicle.storeData.specs.seedFruitTypes"), getXMLString(xmlFile, "vehicle.sowingMachine.seedFruitTypes"))

	return {
		categories = categories,
		names = names
	}
end

function SowingMachine.getSpecValueSeedFillTypes(storeItem, realItem)
	local fruitTypes = nil

	if storeItem.specs.seedFillTypes ~= nil then
		local fruits = storeItem.specs.seedFillTypes

		if fruits.categories ~= nil and fruits.names == nil then
			fruitTypes = g_fruitTypeManager:getFillTypesByFruitTypeCategoryName(fruits.categories, nil)
		elseif fruits.categories == nil and fruits.names ~= nil then
			fruitTypes = g_fruitTypeManager:getFillTypesByFruitTypeNames(fruits.names, nil)
		end

		if fruitTypes ~= nil then
			return fruitTypes
		end
	end

	return nil
end
