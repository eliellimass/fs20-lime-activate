Sprayer = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("sprayer", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onSprayTypeChange")
	end
}

function Sprayer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processSprayerArea", Sprayer.processSprayerArea)
	SpecializationUtil.registerFunction(vehicleType, "getExternalFill", Sprayer.getExternalFill)
	SpecializationUtil.registerFunction(vehicleType, "getAreEffectsVisible", Sprayer.getAreEffectsVisible)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerUsage", Sprayer.getSprayerUsage)
	SpecializationUtil.registerFunction(vehicleType, "getUseSprayerAIRequirements", Sprayer.getUseSprayerAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", Sprayer.setSprayerAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFillUnitIndex", Sprayer.getSprayerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "loadSprayTypeFromXML", Sprayer.loadSprayTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayType", Sprayer.getActiveSprayType)
	SpecializationUtil.registerFunction(vehicleType, "getIsSprayTypeActive", Sprayer.getIsSprayTypeActive)
end

function Sprayer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIMarkers", Sprayer.getAIMarkers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAISizeMarkers", Sprayer.getAISizeMarkers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementCollisionTriggers", Sprayer.getAIImplementCollisionTriggers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", Sprayer.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Sprayer.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Sprayer.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Sprayer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Sprayer.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Sprayer.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Sprayer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillVolumeUVScrollSpeed", Sprayer.getFillVolumeUVScrollSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", Sprayer.getAIRequiresTurnOffOnHeadland)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Sprayer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Sprayer.getWearMultiplier)
end

function Sprayer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSprayTypeChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Sprayer)
end

function Sprayer:onLoad(savegame)
	local spec = self.spec_sprayer

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.sprayParticles.emitterShape", "vehicle.sprayer.effects.effectNode#effectClass='ParticleEffect'")

	spec.allowsSpraying = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sprayer#allowsSpraying"), true)
	spec.needsTankActivation = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sprayer#needsTankActivation"), false)
	spec.activateTankOnLowering = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sprayer#activateTankOnLowering"), false)
	spec.activateOnLowering = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.sprayer#activateOnLowering"), false)
	spec.usageScale = {
		default = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.sprayer.usageScales#scale"), 1),
		workingWidth = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.sprayer.usageScales#workingWidth"), 12),
		fillTypeScales = {}
	}
	local i = 0

	while true do
		local key = string.format("vehicle.sprayer.usageScales.sprayUsageScale(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local fillTypeStr = getXMLString(self.xmlFile, key .. "#fillType")
		local scale = getXMLFloat(self.xmlFile, key .. "#scale")

		if fillTypeStr ~= nil and scale ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

			if fillTypeIndex ~= nil then
				spec.usageScale.fillTypeScales[fillTypeIndex] = scale
			else
				print("Warning: Invalid spray usage scale fill type '" .. fillTypeStr .. "' in '" .. self.configFileName .. "'")
			end
		end

		i = i + 1
	end

	spec.sprayTypes = {}
	i = 0

	while true do
		local key = string.format("vehicle.sprayer.sprayTypes.sprayType(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local sprayType = {}

		if self:loadSprayTypeFromXML(self.xmlFile, key, sprayType) then
			table.insert(spec.sprayTypes, sprayType)

			sprayType.index = #spec.sprayTypes
		end

		i = i + 1
	end

	spec.lastActiveSprayType = nil

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sprayer.effects", self.components, self, self.i3dMappings)
		spec.animationName = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.sprayer.animation#name"), "")
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sprayer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.sampleFillEnabled = false
		spec.sampleFillStopTime = -1
		spec.lastFillLevel = -1
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sprayer.animationNodes", self.components, self, self.i3dMappings)
	end

	if self.sowingMachineGroundContactFlag == nil and self.cultivatorGroundContactFlag == nil and self.addAITerrainDetailRequiredRange ~= nil then
		self:addAITerrainDetailRequiredRange(g_currentMission.plowValue, g_currentMission.plowValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	end

	spec.supportedSprayTypes = {}
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.sprayer#fillUnitIndex"), 1)
	spec.unloadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.sprayer#unloadInfoIndex"), 1)
	spec.fillVolumeIndex = getXMLInt(self.xmlFile, "vehicle.sprayer#fillVolumeIndex")
	spec.dischargeUVScrollSpeed = {
		StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.sprayer#fillVolumeDischargeScrollSpeed"), "0 0 0"))
	}
	spec.needsToBeFilledToTurnOn = true
	spec.useSpeedLimit = true
	spec.isWorking = false
	spec.workAreaParameters = {
		sprayVehicle = nil,
		sprayVehicleFillUnitIndex = nil,
		lastChangedArea = 0,
		lastTotalArea = 0
	}
end

function Sprayer:onDelete()
	if self.isClient then
		local spec = self.spec_sprayer

		g_effectManager:deleteEffects(spec.effects)

		for _, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end

		g_animationManager:deleteAnimations(spec.animationNodes)

		for _, sprayType in ipairs(spec.sprayTypes) do
			g_effectManager:deleteEffects(sprayType.effects)
			g_soundManager:deleteSamples(sprayType.samples)
			g_animationManager:deleteAnimations(sprayType.animationNodes)
		end
	end
end

function Sprayer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local activeSprayType = self:getActiveSprayType()

	if activeSprayType ~= nil then
		local spec = self.spec_sprayer

		if activeSprayType ~= spec.lastActiveSprayType then
			SpecializationUtil.raiseEvent(self, "onSprayTypeChange", activeSprayType)

			spec.lastActiveSprayType = activeSprayType
		end
	end
end

function Sprayer:processSprayerArea(workArea, dt)
	local spec = self.spec_sprayer

	if self:getIsAIActive() and self.isServer and (spec.workAreaParameters.sprayFillType == nil or spec.workAreaParameters.sprayFillType == FillType.UNKNOWN) then
		local rootVehicle = self:getRootVehicle()

		rootVehicle:stopAIVehicle(AIVehicle.STOP_REASON_OUT_OF_FILL)

		return 0, 0
	end

	if spec.workAreaParameters.sprayFillLevel <= 0 then
		return 0, 0
	end

	local sx, _, sz = getWorldTranslation(workArea.start)
	local wx, _, wz = getWorldTranslation(workArea.width)
	local hx, _, hz = getWorldTranslation(workArea.height)
	local changedArea, totalArea = FSDensityMapUtil.updateSprayArea(sx, sz, wx, wz, hx, hz, spec.workAreaParameters.sprayType)
	spec.workAreaParameters.isActive = true
	spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
	spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
	spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea

	if self:getLastSpeed() > 1 then
		spec.isWorking = true
	end

	return changedArea, totalArea
end

function Sprayer:getExternalFill(fillType, dt)
	local found = false
	local isUnknownFillType = fillType == FillType.UNKNOWN
	local allowLiquidManure = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDMANURE)
	local allowDigestate = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.DIGESTATE)
	local allowManure = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.MANURE)
	local allowLiquidFertilizer = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDFERTILIZER)
	local allowFertilizer = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.FERTILIZER)
	local allowsLiquidManureDigistate = allowLiquidManure or allowDigestate
	local usage = 0
	local farmId = self:getActiveFarm()
	local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

	if fillType == FillType.LIQUIDMANURE or fillType == FillType.DIGESTATE or isUnknownFillType and allowsLiquidManureDigistate then
		if g_currentMission.missionInfo.helperSlurrySource == 2 then
			found = true

			if g_currentMission.economyManager:getCostPerLiter(FillType.LIQUIDMANURE, false) then
				fillType = FillType.LIQUIDMANURE
			else
				fillType = FillType.DIGESTATE
			end

			usage = self:getSprayerUsage(fillType, dt)

			if self.isServer then
				local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperSlurrySource > 2 then
			local info = g_currentMission.liquidManureTriggers[g_currentMission.missionInfo.helperSlurrySource - 2]

			if info ~= nil then
				local fillLevel = info.silo:getFillLevel(FillType.LIQUIDMANURE)

				if fillLevel > 0 then
					found = true
					usage = self:getSprayerUsage(FillType.LIQUIDMANURE, dt)

					if self.isServer then
						info.silo:setFillLevel(FillType.LIQUIDMANURE, fillLevel - usage)
					end
				end
			end
		end
	elseif fillType == FillType.MANURE or fillType == FillType.UNKNOWN and allowManure then
		if g_currentMission.missionInfo.helperManureSource == 2 then
			found = true
			fillType = FillType.MANURE
			usage = self:getSprayerUsage(fillType, dt)

			if self.isServer then
				local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperManureSource > 2 then
			local info = g_currentMission.manureHeaps[g_currentMission.missionInfo.helperManureSource - 2]

			if info ~= nil then
				usage = self:getSprayerUsage(FillType.MANURE, dt)

				if self.isServer and info.manureHeap:removeManure(usage) > 0 then
					found = true
					fillType = FillType.MANURE
				end
			end
		end
	elseif (fillType == FillType.FERTILIZER or fillType == FillType.LIQUIDFERTILIZER or fillType == FillType.HERBICIDE or fillType == FillType.LIME or fillType == FillType.UNKNOWN and (allowLiquidFertilizer or allowFertilizer)) and g_currentMission.missionInfo.helperBuyFertilizer then
		found = true

		if fillType == FillType.UNKNOWN then
			if self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDFERTILIZER) then
				fillType = FillType.LIQUIDFERTILIZER
			else
				fillType = FillType.FERTILIZER
			end
		end

		usage = self:getSprayerUsage(fillType, dt)

		if self.isServer then
			local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

			stats:updateStats("expenses", price)
			g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
		end
	end

	if found then
		return fillType, usage
	end

	return FillType.UNKNOWN, 0
end

function Sprayer:getAreEffectsVisible()
	return true
end

function Sprayer:getSprayerUsage(fillType, dt)
	if fillType == FillType.UNKNOWN then
		return 0
	end

	local spec = self.spec_sprayer
	local scale = Utils.getNoNil(spec.usageScale.fillTypeScales[fillType], spec.usageScale.default)
	local litersPerSecond = 1
	local sprayType = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

	if sprayType ~= nil then
		litersPerSecond = sprayType.litersPerSecond
	end

	local activeSprayType = self:getActiveSprayType()
	local workWidth = spec.usageScale.workingWidth

	if activeSprayType ~= nil then
		workWidth = activeSprayType.usageScale.workingWidth or workWidth
	end

	return scale * litersPerSecond * self.speedLimit * workWidth * dt * 0.001
end

function Sprayer:getUseSprayerAIRequirements()
	return true
end

function Sprayer:setSprayerAITerrainDetailProhibitedRange(fillType)
	if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailProhibitedRange()
		self:clearAIFruitRequirements()
		self:clearAIFruitProhibitions()

		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

		if sprayTypeDesc ~= nil then
			if sprayTypeDesc.isHerbicide then
				local fruitType = g_fruitTypeManager:getFruitTypeByName("weed")

				if fruitType ~= nil then
					self:setAIFruitRequirements(fruitType.index, 1, 2)
				end
			else
				self:addAITerrainDetailProhibitedRange(sprayTypeDesc.groundType, sprayTypeDesc.groundType, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
				self:addAITerrainDetailProhibitedRange(g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
			end

			if sprayTypeDesc.isHerbicide or sprayTypeDesc.isFertilizer then
				for index, entry in pairs(g_currentMission.fruits) do
					local fruitType = g_fruitTypeManager:getFruitTypeByIndex(index)

					if fruitType.name:lower() ~= "grass" and fruitType.minHarvestingGrowthState ~= nil and fruitType.maxHarvestingGrowthState ~= nil and fruitType.weed == nil then
						self:addAIFruitProhibitions(fruitType.index, fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState)
					end
				end
			end
		end
	end
end

function Sprayer:getSprayerFillUnitIndex()
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil then
		return sprayType.fillUnitIndex
	end

	return self.spec_sprayer.fillUnitIndex
end

function Sprayer:loadSprayTypeFromXML(xmlFile, key, sprayType)
	sprayType.fillUnitIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#fillUnitIndex"), 1)
	sprayType.unloadInfoIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#unloadInfoIndex"), 1)
	sprayType.fillVolumeIndex = getXMLInt(xmlFile, key .. "#fillVolumeIndex")
	sprayType.samples = {
		work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	}
	sprayType.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings)
	sprayType.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	sprayType.turnedAnimation = getXMLString(self.xmlFile, key .. ".turnedAnimation#name") or ""
	sprayType.ai = {
		leftMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.areaMarkers#leftNode"), self.i3dMappings),
		rightMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.areaMarkers#rightNode"), self.i3dMappings),
		backMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.areaMarkers#backNode"), self.i3dMappings),
		sizeLeftMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.sizeMarkers#leftNode"), self.i3dMappings),
		sizeRightMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.sizeMarkers#rightNode"), self.i3dMappings),
		sizeBackMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.sizeMarkers#backNode"), self.i3dMappings),
		collisionTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. ".ai.collisionTrigger#node"), self.i3dMappings)
	}

	if sprayType.ai.collisionTrigger ~= nil then
		local rigidBodyType = getRigidBodyType(sprayType.ai.collisionTrigger)

		if rigidBodyType ~= "Kinematic" then
			g_logManager:xmlWarning(self.configFileName, "'aiCollisionTrigger' is not a kinematic body type")
		end
	end

	local fillTypesStr = getXMLString(xmlFile, key .. "#fillTypes")

	if fillTypesStr ~= nil then
		sprayType.fillTypes = StringUtil.splitString(" ", fillTypesStr)
	end

	sprayType.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, sprayType.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, false)

	sprayType.usageScale = {
		workingWidth = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. ".usageScales#workingWidth"), 12)
	}

	return true
end

function Sprayer:getActiveSprayType()
	local spec = self.spec_sprayer

	for _, sprayType in ipairs(spec.sprayTypes) do
		if self:getIsSprayTypeActive(sprayType) then
			return sprayType
		end
	end

	return nil
end

function Sprayer:getIsSprayTypeActive(sprayType)
	if sprayType.fillTypes ~= nil then
		local retValue = false
		local currentFillType = self:getFillUnitFillType(sprayType.fillUnitIndex or self.spec_sprayer.fillUnitIndex)

		for _, fillType in ipairs(sprayType.fillTypes) do
			if currentFillType == g_fillTypeManager:getFillTypeIndexByName(fillType) then
				retValue = true
			end
		end

		if not retValue then
			return false
		end
	end

	return true
end

function Sprayer:getAIMarkers(superFunc)
	local spec = self.spec_aiImplement
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and not spec.useAttributesOfAttachedImplement and sprayType.ai.rightMarker ~= nil then
		if spec.aiMarkersInverted then
			return sprayType.ai.rightMarker, sprayType.ai.leftMarker, sprayType.ai.backMarker, true
		else
			return sprayType.ai.leftMarker, sprayType.ai.rightMarker, sprayType.ai.backMarker, false
		end
	end

	return superFunc(self)
end

function Sprayer:getAISizeMarkers(superFunc)
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and sprayType.ai.sizeLeftMarker ~= nil then
		return sprayType.ai.sizeLeftMarker, sprayType.ai.sizeRightMarker, sprayType.ai.sizeBackMarker
	end

	return superFunc(self)
end

function Sprayer:getAIImplementCollisionTriggers(superFunc, collisionTriggers)
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and sprayType.ai.collisionTrigger ~= nil then
		collisionTriggers[self] = sprayType.ai.collisionTrigger
	end

	return superFunc(self, collisionTriggers)
end

function Sprayer:getDrawFirstFillText(superFunc)
	if self.isClient then
		local spec = self.spec_sprayer

		if spec.needsToBeFilledToTurnOn and self:getIsActiveForInput() and self:getIsSelected() and not self.isAlwaysTurnedOn and not self:getCanBeTurnedOn() and self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) > 0 then
			return true
		end
	end

	return superFunc(self)
end

function Sprayer:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_sprayer

	if spec.needsToBeFilledToTurnOn and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return false, g_i18n:getText("info_firstFillTheTool")
	end

	return superFunc(self)
end

function Sprayer:getCanToggleTurnedOn(superFunc)
	if self.isClient then
		local spec = self.spec_sprayer

		if spec.needsToBeFilledToTurnOn and not self:getCanBeTurnedOn() and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) <= 0 then
			return false
		end
	end

	return superFunc(self)
end

function Sprayer:getCanBeTurnedOn(superFunc)
	local spec = self.spec_sprayer

	if not spec.allowsSpraying then
		return false
	end

	if self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and spec.needsToBeFilledToTurnOn and not self:getIsAIActive() then
		local sprayVehicle = nil

		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle

				if vehicle:getFillUnitFillType(src.fillUnitIndex) == supportedSprayType and vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 then
					sprayVehicle = vehicle

					break
				end
			end
		end

		if sprayVehicle == nil then
			return false
		end
	end

	return superFunc(self)
end

function Sprayer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SPRAYER
	end

	workArea.sprayType = getXMLInt(xmlFile, key .. "#sprayType")

	return retValue
end

function Sprayer:getIsWorkAreaActive(superFunc, workArea)
	if workArea.sprayType ~= nil then
		local sprayType = self:getActiveSprayType()

		if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Sprayer:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self.spec_sprayer.useSpeedLimit
end

function Sprayer:getFillVolumeUVScrollSpeed(superFunc, fillVolumeIndex)
	local spec = self.spec_sprayer
	local sprayerFillVolumeIndex = spec.fillVolumeIndex
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil then
		sprayerFillVolumeIndex = sprayType.fillVolumeIndex
	end

	if fillVolumeIndex == sprayerFillVolumeIndex then
		return spec.dischargeUVScrollSpeed[1], spec.dischargeUVScrollSpeed[2], spec.dischargeUVScrollSpeed[3]
	end

	return superFunc(self, fillVolumeIndex)
end

function Sprayer:getAIRequiresTurnOffOnHeadland(superFunc)
	return true
end

function Sprayer:getDirtMultiplier(superFunc)
	local spec = self.spec_sprayer

	if spec.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Sprayer:getWearMultiplier(superFunc)
	local spec = self.spec_sprayer

	if spec.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Sprayer:onTurnedOn()
	local spec = self.spec_sprayer

	if self.isClient then
		local sprayType = self:getActiveSprayType()

		if self:getAreEffectsVisible() then
			local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())

			if fillType == FillType.UNKNOWN then
				fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
			end

			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)

			if sprayType ~= nil then
				g_effectManager:setFillType(sprayType.effects, fillType)
				g_effectManager:startEffects(sprayType.effects)
				g_animationManager:startAnimations(sprayType.animationNodes)
			end

			g_animationManager:startAnimations(spec.animationNodes)
		end

		if spec.animationName ~= "" and self.playAnimation ~= nil then
			self:playAnimation(spec.animationName, 1, self:getAnimationTime(spec.animationName), true)
		end

		g_soundManager:playSample(spec.samples.work)

		if sprayType ~= nil then
			g_soundManager:playSample(sprayType.samples.work)
			self:playAnimation(sprayType.turnedAnimation, 1, self:getAnimationTime(sprayType.turnedAnimation), true)
		end
	end
end

function Sprayer:onTurnedOff()
	local spec = self.spec_sprayer

	if self.isClient then
		g_effectManager:stopEffects(spec.effects)
		g_animationManager:stopAnimations(spec.animationNodes)

		if spec.animationName ~= "" and self.stopAnimation ~= nil then
			self:stopAnimation(spec.animationName, true)
		end

		g_soundManager:stopSample(spec.samples.work)

		for _, sprayType in ipairs(spec.sprayTypes) do
			g_effectManager:stopEffects(sprayType.effects)
			g_animationManager:stopAnimations(sprayType.animationNodes)
			g_soundManager:stopSample(sprayType.samples.work)
			self:playAnimation(sprayType.turnedAnimation, -1, self:getAnimationTime(sprayType.turnedAnimation), true)
		end
	end
end

function Sprayer:onPreDetach(attacherVehicle, jointDescIndex)
	if attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		attacherVehicle:setIsTurnedOn(false)
	end
end

function Sprayer:onStartWorkAreaProcessing(dt)
	local spec = self.spec_sprayer
	local sprayVehicle, sprayVehicleFillUnitIndex = nil
	local fillType = self:getFillUnitFillType(self:getSprayerFillUnitIndex())
	local usage = self:getSprayerUsage(fillType, dt)
	local sprayFillLevel = self:getFillUnitFillLevel(self:getSprayerFillUnitIndex())

	if sprayFillLevel > 0 then
		sprayVehicle = self
		sprayVehicleFillUnitIndex = self:getSprayerFillUnitIndex()
	else
		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle

				if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
					local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
					local vehicleFillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)

					if vehicleFillLevel > 0 and vehicleFillType == supportedSprayType then
						sprayVehicle = vehicle
						sprayVehicleFillUnitIndex = src.fillUnitIndex
						fillType = sprayVehicle:getFillUnitFillType(sprayVehicleFillUnitIndex)
						usage = self:getSprayerUsage(fillType, dt)
						sprayFillLevel = vehicleFillLevel

						break
					end
				elseif self:getIsAIActive() and vehicle.setIsTurnedOn ~= nil and not vehicle:getIsTurnedOn() then
					vehicle:setIsTurnedOn(true)
				end
			end
		end
	end

	if self:getIsAIActive() then
		local isSlurryTanker = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.DIGESTATE)
		local isManureSpreader = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.MANURE)
		local isFertilizerSprayer = not isSlurryTanker and not isManureSpreader
		local isBuying = isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource > 1 or isManureSpreader and g_currentMission.missionInfo.helperManureSource > 1 or isFertilizerSprayer and g_currentMission.missionInfo.helperBuyFertilizer

		if isBuying and self:getIsTurnedOn() then
			fillType, usage = self:getExternalFill(fillType, dt)
			sprayFillLevel = usage
			sprayVehicle, sprayVehicleFillUnitIndex = nil
		end
	end

	if self.isServer and fillType ~= FillType.UNKNOWN and fillType ~= spec.workAreaParameters.sprayFillType then
		self:setSprayerAITerrainDetailProhibitedRange(fillType)
	end

	spec.workAreaParameters.sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(fillType)
	spec.workAreaParameters.sprayFillType = fillType
	spec.workAreaParameters.sprayFillLevel = sprayFillLevel
	spec.workAreaParameters.usage = usage
	spec.workAreaParameters.sprayVehicle = sprayVehicle
	spec.workAreaParameters.sprayVehicleFillUnitIndex = sprayVehicleFillUnitIndex
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastTotalArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.isActive = false
	spec.isWorking = false
end

function Sprayer:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_sprayer

	if self.isServer and spec.workAreaParameters.isActive then
		local sprayVehicle = spec.workAreaParameters.sprayVehicle
		local usage = spec.workAreaParameters.usage

		if sprayVehicle ~= nil then
			local sprayVehicleFillUnitIndex = spec.workAreaParameters.sprayVehicleFillUnitIndex
			local sprayFillType = spec.workAreaParameters.sprayFillType
			local unloadInfoIndex = spec.unloadInfoIndex
			local sprayType = self:getActiveSprayType()

			if sprayType ~= nil then
				unloadInfoIndex = sprayType.unloadInfoIndex
			end

			local unloadInfo = self:getFillVolumeUnloadInfo(unloadInfoIndex)

			sprayVehicle:addFillUnitFillLevel(self:getOwnerFarmId(), sprayVehicleFillUnitIndex, -usage, sprayFillType, ToolType.UNDEFINED, unloadInfo)
		end

		local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
		local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

		stats:updateStats("workedHectares", ha)
		stats:updateStats("fertilizedHectares", ha)
		stats:updateStats("fertilizedTime", dt / 60000)
		stats:updateStats("sprayUsage", usage)
	end
end

function Sprayer:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH or Vehicle.STATE_CHANGE_FILLTYPE_CHANGE then
		local spec = self.spec_sprayer
		spec.fillTypeSources = {}
		local supportedFillTypes = self:getFillUnitSupportedFillTypes(self:getSprayerFillUnitIndex())
		spec.supportedSprayTypes = {}

		if supportedFillTypes ~= nil then
			for fillType, state in pairs(supportedFillTypes) do
				if state then
					spec.fillTypeSources[fillType] = {}

					table.insert(spec.supportedSprayTypes, fillType)
				end
			end
		end

		local root = self:getRootVehicle()

		FillUnit.addFillTypeSources(spec.fillTypeSources, root, self, spec.supportedSprayTypes)
	end
end

function Sprayer:onSetLowered(isLowered)
	local spec = self.spec_sprayer

	if spec.activateOnLowering then
		self:setIsTurnedOn(isLowered, true)
	end
end

function Sprayer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

	if fillLevel == 0 and self:getIsTurnedOn() and not self:getIsAIActive() then
		local spec = self.spec_sprayer
		local hasValidSource = false

		if spec.fillTypeSources[fillType] ~= nil then
			for _, src in ipairs(spec.fillTypeSources[fillType]) do
				local vehicle = src.vehicle

				if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
					local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
					local vehicleFillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)

					if vehicleFillLevel > 0 and vehicleFillType == fillType then
						hasValidSource = true
					end
				end
			end
		end

		if not hasValidSource then
			self:setIsTurnedOn(false)
		end
	end
end

function Sprayer:onSprayTypeChange(activeSprayType)
	local spec = self.spec_sprayer

	for _, sprayType in ipairs(spec.sprayTypes) do
		ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, sprayType == activeSprayType)
	end
end

function Sprayer:onAIImplementEnd()
	local spec = self.spec_sprayer

	for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
		for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
			local vehicle = src.vehicle

			if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
				vehicle:setIsTurnedOn(false, true)
			end
		end
	end
end

function Sprayer.getDefaultSpeedLimit()
	return 15
end
