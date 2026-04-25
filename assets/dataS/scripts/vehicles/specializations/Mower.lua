source("dataS/scripts/vehicles/specializations/events/MowerToggleWindrowDropEvent.lua")

Mower = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("mower", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
}

function Mower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processMowerArea", Mower.processMowerArea)
	SpecializationUtil.registerFunction(vehicleType, "processDropArea", Mower.processDropArea)
	SpecializationUtil.registerFunction(vehicleType, "getDropArea", Mower.getDropArea)
	SpecializationUtil.registerFunction(vehicleType, "setDropEffectEnabled", Mower.setDropEffectEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setUseMowerWindrowDropAreas", Mower.setUseMowerWindrowDropAreas)
end

function Mower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Mower.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Mower.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Mower.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Mower.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Mower.getWearMultiplier)
end

function Mower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Mower)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Mower)
end

function Mower:onLoad(savegame)
	local spec = self.spec_mower

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mowerEffects.mowerEffect", "vehicle.mower.dropEffects.dropEffect")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mowerEffects.mowerEffect#mowerCutArea", "vehicle.mower.dropEffects.dropEffect#dropAreaIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.mower.turnOnNodes.turnOnNode", "mower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mowerStartSound", "vehicle.turnOnVehicle.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mowerStopSound", "vehicle.turnOnVehicle.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mowerSound", "vehicle.turnOnVehicle.sounds.work")

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mower.animationNodes", self.components, self, self.i3dMappings)
		spec.dropEffects = {}
		local i = 0

		while true do
			local key = string.format("vehicle.mower.dropEffects.dropEffect(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local effects = g_effectManager:loadEffect(self.xmlFile, key, self.components, self, self.i3dMappings)

			if effects ~= nil then
				local dropEffect = {
					effects = effects,
					dropAreaIndex = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#dropAreaIndex"), 1),
					workAreaIndex = getXMLInt(self.xmlFile, key .. "#workAreaIndex")
				}

				if self.spec_workArea.workAreas[dropEffect.dropAreaIndex] == nil then
					g_logManager:xmlWarning(self.configFileName, "Invalid dropAreaIndex '%s' in '%s'", dropEffect.dropAreaIndex, key)

					dropEffect.dropAreaIndex = nil
				end

				dropEffect.activeTime = -1
				dropEffect.activeTimeDuration = 750
				dropEffect.isActive = false
				dropEffect.isActiveSent = false

				table.insert(spec.dropEffects, dropEffect)
			end

			i = i + 1
		end
	end

	if spec.dropAreas == nil then
		spec.dropAreas = {}
	end

	spec.fruitTypeConverters = {}
	local converter = getXMLString(self.xmlFile, "vehicle.mower#fruitTypeConverter")

	if converter ~= nil then
		local data = g_fruitTypeManager:getConverterDataByName(converter)

		if data ~= nil then
			for input, converted in pairs(data) do
				spec.fruitTypeConverters[input] = converted
			end
		end
	else
		print(string.format("Warning: Missing fruit type converter in '%s'", self.configFileName))
	end

	spec.fillUnitIndex = getXMLFloat(self.xmlFile, "vehicle.mower#fillUnitIndex")
	spec.pickupFillScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.mower#pickupFillScale"), 1)
	spec.toggleWindrowDropEnableText = getXMLString(self.xmlFile, "vehicle.mower.toggleWindrowDrop#enableText")
	spec.toggleWindrowDropDisableText = getXMLString(self.xmlFile, "vehicle.mower.toggleWindrowDrop#disableText")

	if spec.toggleWindrowDropEnableText ~= nil then
		spec.toggleWindrowDropEnableText = g_i18n:convertText(spec.toggleWindrowDropEnableText, self.customEnvironment)
	end

	if spec.toggleWindrowDropDisableText ~= nil then
		spec.toggleWindrowDropDisableText = g_i18n:convertText(spec.toggleWindrowDropDisableText, self.customEnvironment)
	end

	spec.toggleWindrowDropAnimation = getXMLString(self.xmlFile, "vehicle.mower.toggleWindrowDrop#animationName")
	spec.enableWindrowDropAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.mower.toggleWindrowDrop#animationEnableSpeed"), 1)
	spec.disableWindrowDropAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.mower.toggleWindrowDrop#animationDisableSpeed"), -spec.enableWindrowDropAnimationSpeed)
	spec.useWindrowDropAreas = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.mower.toggleWindrowDrop#startEnabled"), false)
	spec.workAreaParameters = {
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastTotalArea = 0,
		lastUsedAreas = 0,
		lastUsedAreasSum = 0,
		lastUsedAreasPct = 0,
		lastUsedAreasTime = 0
	}
	spec.isWorking = false
	spec.dirtyFlag = self:getNextDirtyFlag()

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	end

	if self.addAIFruitRequirement ~= nil then
		for inputFruitType, _ in pairs(spec.fruitTypeConverters) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)

			self:addAIFruitRequirement(desc.index, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
		end
	end
end

function Mower:onDelete()
	if self.isClient then
		local spec = self.spec_mower

		for _, dropEffect in pairs(spec.dropEffects) do
			g_effectManager:deleteEffects(dropEffect.effects)
		end

		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function Mower:onReadStream(streamId, connection)
	local spec = self.spec_mower

	if spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil then
		local useMowerWindrowDropAreas = streamReadBool(streamId)

		self:setUseMowerWindrowDropAreas(useMowerWindrowDropAreas, true)
	end
end

function Mower:onWriteStream(streamId, connection)
	local spec = self.spec_mower

	if spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil then
		streamWriteBool(streamId, spec.useWindrowDropAreas)
	end
end

function Mower:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_mower

		if #spec.dropEffects > 0 and streamReadBool(streamId) then
			for _, dropEffect in ipairs(spec.dropEffects) do
				dropEffect.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

				self:setDropEffectEnabled(dropEffect, streamReadBool(streamId))
			end
		end
	end
end

function Mower:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_mower

		if #spec.dropEffects > 0 and streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for _, dropEffect in ipairs(spec.dropEffects) do
				streamWriteUIntN(streamId, dropEffect.fillType or FillType.UNKNOWN, FillTypeManager.SEND_NUM_BITS)
				streamWriteBool(streamId, dropEffect.isActiveSent)
			end
		end
	end
end

function Mower:processMowerArea(workArea, dt)
	local spec = self.spec_mower

	if self:getLastSpeed() > 1 then
		spec.isWorking = true
	end

	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)

	for inputFruitType, converterData in pairs(spec.fruitTypeConverters) do
		local changedArea, totalArea, sprayFactor, plowFactor, limeFactor, weedFactor, _, _ = FSDensityMapUtil.cutFruitArea(inputFruitType, xs, zs, xw, zw, xh, zh, true, true, false)

		if changedArea > 0 then
			local multiplier = g_currentMission:getHarvestScaleMultiplier(inputFruitType, sprayFactor, plowFactor, limeFactor, weedFactor)
			changedArea = changedArea * multiplier
			local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
			local sqm = changedArea * pixelToSqm
			local litersToDrop = sqm * g_fruitTypeManager:getFillTypeLiterPerSqm(converterData.fillTypeIndex, 1)
			workArea.lastPickupLiters = litersToDrop
			local dropArea = self:getDropArea(workArea)

			if dropArea ~= nil then
				dropArea.litersToDrop = dropArea.litersToDrop + litersToDrop
				dropArea.fillType = converterData.fillTypeIndex
				dropArea.workAreaIndex = workArea.index
			elseif spec.fillUnitIndex ~= nil and self.isServer then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, litersToDrop, converterData.fillTypeIndex, ToolType.UNDEFINED)
			end

			spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
			spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
			spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea
			spec.workAreaParameters.lastUsedAreas = spec.workAreaParameters.lastUsedAreas + 1
		end
	end

	spec.workAreaParameters.lastUsedAreasSum = spec.workAreaParameters.lastUsedAreasSum + 1

	return spec.workAreaParameters.lastChangedArea, spec.workAreaParameters.lastTotalArea
end

function Mower:processDropArea(dropArea, dt)
	local spec = self.spec_mower
	local dropped = 0
	local lineOffset = nil

	if g_densityMapHeightManager:getMinValidLiterValue(dropArea.fillType) < dropArea.litersToDrop then
		local xs, _, zs = getWorldTranslation(dropArea.start)
		local xw, _, zw = getWorldTranslation(dropArea.width)
		local xh, _, zh = getWorldTranslation(dropArea.height)
		local f = math.random()
		local sx = xs + f * (xh - xs)
		local sz = zs + f * (zh - zs)
		local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
		local f = math.random()
		local ex = xw + f * (xh - xs)
		local ez = zw + f * (zh - zs)
		local ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)
		dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, dropArea.litersToDrop, dropArea.fillType, sx, sy, sz, ex, ey, ez, 0, nil, dropArea.dropLineOffset, false, nil, false)
		dropArea.litersToDrop = dropArea.litersToDrop - dropped
		dropArea.dropLineOffset = lineOffset
	end

	for _, dropEffect in pairs(spec.dropEffects) do
		if dropEffect.dropAreaIndex == dropArea.index and dropped > 0 and (dropEffect.workAreaIndex == nil or dropEffect.workAreaIndex == dropArea.workAreaIndex) then
			if dropEffect.fillType ~= dropArea.fillType then
				dropEffect.fillType = dropArea.fillType

				g_effectManager:setFillType(dropEffect.effects, dropEffect.fillType)
			end

			dropEffect.activeTime = dropEffect.activeTimeDuration
			dropEffect.isActive = true
		else
			dropEffect.activeTime = math.max(dropEffect.activeTime - dt, 0)

			if dropEffect.activeTime > 0 then
				dropEffect.isActive = true
			end
		end
	end
end

function Mower:getDropArea(workArea)
	if workArea.dropWindrow then
		local dropArea = workArea

		if workArea.dropAreaIndex ~= nil then
			dropArea = self.spec_workArea.workAreas[workArea.dropAreaIndex]

			if dropArea == nil then
				print("Warning: Invalid dropAreaIndex '" .. tostring(workArea.dropAreaIndex) .. "' in '" .. tostring(self.configFileName) .. "'!")

				workArea.dropAreaIndex = nil
			end
		end

		return dropArea
	end

	return nil
end

function Mower:setDropEffectEnabled(dropEffect, isActive)
	dropEffect.isActive = isActive

	if self.isClient then
		if isActive then
			g_effectManager:setFillType(dropEffect.effects, dropEffect.fillType)
			g_effectManager:startEffects(dropEffect.effects)
		else
			g_effectManager:stopEffects(dropEffect.effects)
		end
	end
end

function Mower:setUseMowerWindrowDropAreas(useMowerWindrowDropAreas, noEventSend)
	local spec = self.spec_mower

	if useMowerWindrowDropAreas ~= spec.useWindrowDropAreas then
		MowerToggleWindrowDropEvent.sendEvent(self, useMowerWindrowDropAreas, noEventSend)

		spec.useWindrowDropAreas = useMowerWindrowDropAreas

		if spec.toggleWindrowDropAnimation ~= nil and self.playAnimation ~= nil then
			local speed = spec.enableWindrowDropAnimationSpeed

			if not useMowerWindrowDropAreas then
				speed = spec.disableWindrowDropAnimationSpeed
			end

			self:playAnimation(spec.toggleWindrowDropAnimation, speed, nil, true)
		end
	end
end

function Mower:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.MOWER
	end

	if workArea.type == WorkAreaType.MOWER then
		workArea.dropWindrow = Utils.getNoNil(getXMLBool(xmlFile, key .. ".mower#dropWindrow"), true)
		workArea.dropAreaIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. ".mower#dropAreaIndex"), 1)
		workArea.lastPickupLiters = 0
	end

	if workArea.type == WorkAreaType.AUXILIARY then
		workArea.litersToDrop = 0

		if self.spec_mower.dropAreas == nil then
			self.spec_mower.dropAreas = {}
		end

		table.insert(self.spec_mower.dropAreas, workArea)
	end

	return retValue
end

function Mower:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_mower

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.toggleWindrowDropEnableText ~= nil and spec.toggleWindrowDropDisableText ~= nil then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Mower.actionEventToggleDrop, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			Mower.updateActionEventToggleDrop(self)
		end
	end
end

function Mower:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and (self.getIsLowered == nil or self:getIsLowered())
end

function Mower:getCanBeSelected(superFunc)
	return true
end

function Mower:getDirtMultiplier(superFunc)
	local spec = self.spec_mower
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Mower:getWearMultiplier(superFunc)
	local spec = self.spec_mower
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Mower:onTurnedOn()
	if self.isClient then
		local spec = self.spec_mower

		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function Mower:onTurnedOff()
	if self.isClient then
		local spec = self.spec_mower

		for _, dropEffect in pairs(spec.dropEffects) do
			self:setDropEffectEnabled(dropEffect, false)
		end

		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function Mower:onStartWorkAreaProcessing(dt)
	local spec = self.spec_mower

	if self.isServer then
		for _, dropEffect in pairs(spec.dropEffects) do
			if dropEffect.isActive ~= dropEffect.isActiveSent then
				dropEffect.isActiveSent = dropEffect.isActive

				self:setDropEffectEnabled(dropEffect, dropEffect.isActiveSent)
				self:raiseDirtyFlags(spec.dirtyFlag)
			end

			dropEffect.isActive = false
		end
	end

	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastTotalArea = 0
	spec.isWorking = false
end

function Mower:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_mower

	for _, dropArea in ipairs(spec.dropAreas) do
		if dropArea.litersToDrop > 0 then
			self:processDropArea(dropArea, dt)
		end
	end

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea
		local lastTotalArea = spec.workAreaParameters.lastTotalArea

		if lastStatsArea > 0 then
			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("threshedHectares", ha)
			stats:updateStats("workedHectares", ha)
		end
	end

	spec.workAreaParameters.lastUsedAreasTime = spec.workAreaParameters.lastUsedAreasTime + dt

	if spec.workAreaParameters.lastUsedAreasTime > 500 then
		spec.workAreaParameters.lastUsedAreasPct = spec.workAreaParameters.lastUsedAreas / math.max(spec.workAreaParameters.lastUsedAreasSum, 0.01)
		spec.workAreaParameters.lastUsedAreas = 0
		spec.workAreaParameters.lastUsedAreasSum = 0
		spec.workAreaParameters.lastUsedAreasTime = 0
	end
end

function Mower:getMowerLoadPercentage()
	if self.spec_mower ~= nil then
		return self.spec_mower.workAreaParameters.lastUsedAreasPct
	end

	return 0
end

g_soundManager:registerModifierType("MOWER_LOAD", Mower.getMowerLoadPercentage)

function Mower.getDefaultSpeedLimit()
	return 20
end

function Mower:actionEventToggleDrop(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_mower

	self:setUseMowerWindrowDropAreas(not spec.useWindrowDropAreas)
end

function Mower:updateActionEventToggleDrop()
	local spec = self.spec_mower
	local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

	if actionEvent ~= nil then
		local text = string.format(spec.toggleWindrowDropDisableText, self.typeDesc)

		if not spec.useWindrowDropAreas then
			text = string.format(spec.toggleWindrowDropEnableText, self.typeDesc)
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
	end
end
