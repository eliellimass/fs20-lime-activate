source("dataS/scripts/vehicles/specializations/events/SetFillUnitIsFillingEvent.lua")
source("dataS/scripts/vehicles/specializations/events/FillUnitUnloadEvent.lua")

FillUnit = {
	EXACTFILLROOTNODE_MASK = 1073741824,
	CAPACITY_TO_NETWORK_BITS = {}
}
FillUnit.CAPACITY_TO_NETWORK_BITS[0] = 16
FillUnit.CAPACITY_TO_NETWORK_BITS[1] = 12
FillUnit.CAPACITY_TO_NETWORK_BITS[2048] = 16

function FillUnit.initSpecialization()
	Vehicle.registerStateChange("FILLTYPE_CHANGE")
	g_configurationManager:addConfigurationType("fillUnit", g_i18n:getText("configuration_fillUnit"), "fillUnit", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_storeManager:addSpecType("capacity", "shopListAttributeIconCapacity", FillUnit.loadSpecValueCapacity, FillUnit.getSpecValueCapacity)
	g_storeManager:addSpecType("fillTypes", "shopListAttributeIconFillTypes", FillUnit.loadSpecValueFillTypes, FillUnit.getSpecValueFillTypes)
end

function FillUnit.prerequisitesPresent(specializations)
	return true
end

function FillUnit.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitFillLevelChanged")
	SpecializationUtil.registerEvent(vehicleType, "onChangedFillType")
	SpecializationUtil.registerEvent(vehicleType, "onAlarmTriggerChanged")
	SpecializationUtil.registerEvent(vehicleType, "onAddedFillUnitTrigger")
	SpecializationUtil.registerEvent(vehicleType, "onRemovedFillUnitTrigger")
	SpecializationUtil.registerEvent(vehicleType, "onFillUnitIsFillingStateChanged")
end

function FillUnit.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDrawFirstFillText", FillUnit.getDrawFirstFillText)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnits", FillUnit.getFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitByIndex", FillUnit.getFillUnitByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExists", FillUnit.getFillUnitExists)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitCapacity", FillUnit.getFillUnitCapacity)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFreeCapacity", FillUnit.getFillUnitFreeCapacity)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillLevel", FillUnit.getFillUnitFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillLevelPercentage", FillUnit.getFillUnitFillLevelPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFillType", FillUnit.getFillUnitFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitLastValidFillType", FillUnit.getFillUnitLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFirstSupportedFillType", FillUnit.getFillUnitFirstSupportedFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExactFillRootNode", FillUnit.getFillUnitExactFillRootNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitRootNode", FillUnit.getFillUnitRootNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitAutoAimTargetNode", FillUnit.getFillUnitAutoAimTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsFillType", FillUnit.getFillUnitSupportsFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsToolType", FillUnit.getFillUnitSupportsToolType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportsToolTypeAndFillType", FillUnit.getFillUnitSupportsToolTypeAndFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportedFillTypes", FillUnit.getFillUnitSupportedFillTypes)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitSupportedToolTypes", FillUnit.getFillUnitSupportedToolTypes)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitAllowsFillType", FillUnit.getFillUnitAllowsFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillTypeChangeThreshold", FillUnit.getFillTypeChangeThreshold)
	SpecializationUtil.registerFunction(vehicleType, "getFirstValidFillUnitToFill", FillUnit.getFirstValidFillUnitToFill)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillType", FillUnit.setFillUnitFillType)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillTypeToDisplay", FillUnit.setFillUnitFillTypeToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitFillLevelToDisplay", FillUnit.setFillUnitFillLevelToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitCapacity", FillUnit.setFillUnitCapacity)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitForcedMaterialFillType", FillUnit.setFillUnitForcedMaterialFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitForcedMaterialFillType", FillUnit.getFillUnitForcedMaterialFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateAlarmTriggers", FillUnit.updateAlarmTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAlarmTriggerIsActive", FillUnit.getAlarmTriggerIsActive)
	SpecializationUtil.registerFunction(vehicleType, "setAlarmTriggerState", FillUnit.setAlarmTriggerState)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitIndexFromNode", FillUnit.getFillUnitIndexFromNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitExtraDistanceFromNode", FillUnit.getFillUnitExtraDistanceFromNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillUnitFromNode", FillUnit.getFillUnitFromNode)
	SpecializationUtil.registerFunction(vehicleType, "addFillUnitFillLevel", FillUnit.addFillUnitFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitLastValidFillType", FillUnit.setFillUnitLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "loadFillUnitFromXML", FillUnit.loadFillUnitFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAlarmTrigger", FillUnit.loadAlarmTrigger)
	SpecializationUtil.registerFunction(vehicleType, "loadMeasurementNode", FillUnit.loadMeasurementNode)
	SpecializationUtil.registerFunction(vehicleType, "updateMeasurementNodes", FillUnit.updateMeasurementNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadFillPlane", FillUnit.loadFillPlane)
	SpecializationUtil.registerFunction(vehicleType, "setFillPlaneForcedFillType", FillUnit.setFillPlaneForcedFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitFillPlane", FillUnit.updateFillUnitFillPlane)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitAutoAimTarget", FillUnit.updateFillUnitAutoAimTarget)
	SpecializationUtil.registerFunction(vehicleType, "addFillUnitTrigger", FillUnit.addFillUnitTrigger)
	SpecializationUtil.registerFunction(vehicleType, "removeFillUnitTrigger", FillUnit.removeFillUnitTrigger)
	SpecializationUtil.registerFunction(vehicleType, "setFillUnitIsFilling", FillUnit.setFillUnitIsFilling)
	SpecializationUtil.registerFunction(vehicleType, "setFillSoundIsPlaying", FillUnit.setFillSoundIsPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getIsFillUnitActive", FillUnit.getIsFillUnitActive)
	SpecializationUtil.registerFunction(vehicleType, "updateFillUnitTriggers", FillUnit.updateFillUnitTriggers)
	SpecializationUtil.registerFunction(vehicleType, "emptyAllFillUnits", FillUnit.emptyAllFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "unloadFillUnits", FillUnit.unloadFillUnits)
	SpecializationUtil.registerFunction(vehicleType, "loadFillUnitUnloadingFromXML", FillUnit.loadFillUnitUnloadingFromXML)
end

function FillUnit.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", FillUnit.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", FillUnit.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", FillUnit.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", FillUnit.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", FillUnit.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", FillUnit.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", FillUnit.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", FillUnit.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", FillUnit.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", FillUnit.getIsPowerTakeOffActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", FillUnit.getCanBeTurnedOn)
end

function FillUnit.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", FillUnit)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FillUnit)
end

function FillUnit:onLoad(savegame)
	local spec = self.spec_fillUnit

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.measurementNodes.measurementNode", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.measurementNodes.measurementNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fillPlanes.fillPlane", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.fillPlane")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.foldable.foldingParts#onlyFoldOnEmpty", "vehicle.fillUnit#allowFoldingWhileFilled")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fillAutoAimTargetNode", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.autoAimTargetNode")

	local fillUnitConfigurationId = Utils.getNoNil(self.configurations.fillUnit, 1)
	local baseKey = string.format("vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d).fillUnits", fillUnitConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration", fillUnitConfigurationId, self.components, self)

	spec.removeVehicleIfEmpty = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#removeVehicleIfEmpty"), false)
	spec.allowFoldingWhileFilled = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#allowFoldingWhileFilled"), true)
	spec.allowFoldingThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#allowFoldingThreshold"), 0.0001)
	spec.fillTypeChangeThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#fillTypeChangeThreshold"), 0.05)
	spec.fillUnits = {}
	spec.exactFillRootNodeToFillUnit = {}
	spec.exactFillRootNodeToExtraDistance = {}
	spec.hasExactFillRootNodes = false
	spec.activeAlarmTriggers = {}
	spec.fillTrigger = {
		triggers = {},
		activatable = FillActivatable:new(self),
		isFilling = false,
		currentTrigger = nil,
		litersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. ".fillTrigger#litersPerSecond"), 50),
		consumePtoPower = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. ".fillTrigger#consumePtoPower"), false)
	}
	local i = 0

	while true do
		local key = string.format("%s.fillUnit(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadFillUnitFromXML(self.xmlFile, key, entry, i + 1) then
			table.insert(spec.fillUnits, entry)
		else
			g_logManager:xmlWarning(self.configFileName, "Could not load fillUnit for '%s'", key)
			self:setLoadingState(BaseMission.VEHICLE_LOAD_ERROR)

			break
		end

		i = i + 1
	end

	if hasXMLProperty(self.xmlFile, baseKey .. ".unloading") then
		spec.unloading = {}
		local i = 0

		while true do
			local unloadingKey = string.format("%s.unloading(%d)", baseKey, i)

			if not hasXMLProperty(self.xmlFile, unloadingKey) then
				break
			end

			local entry = {}

			if self:loadFillUnitUnloadingFromXML(self.xmlFile, unloadingKey, entry, i + 1) then
				table.insert(spec.unloading, entry)
			else
				g_logManager:xmlWarning(self.configFileName, "Could not load unloading node for '%s'", unloadingKey)

				break
			end

			i = i + 1
		end
	end

	if self.isClient then
		spec.samples = {
			fill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fillUnit.sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".fillEffect", self.components, self, self.i3dMappings)
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
		spec.activeFillEffects = {}
		spec.activeFillAnimations = {}
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function FillUnit:onPostLoad(savegame)
	local spec = self.spec_fillUnit

	if self.isServer then
		local fillUnitsToLoad = {}

		for i, fillUnit in ipairs(spec.fillUnits) do
			if fillUnit.startFillLevel == nil and fillUnit.startFillTypeIndex == nil then
				fillUnitsToLoad[i] = fillUnit
			end
		end

		if savegame ~= nil and hasXMLProperty(savegame.xmlFile, savegame.key .. ".fillUnit") then
			local i = 0
			local xmlFile = savegame.xmlFile

			while true do
				local key = string.format("%s.fillUnit.unit(%d)", savegame.key, i)

				if not hasXMLProperty(xmlFile, key) then
					break
				end

				local fillUnitIndex = getXMLInt(xmlFile, key .. "#index")
				local allowLoading = fillUnitsToLoad[fillUnitIndex] == nil or fillUnitsToLoad[fillUnitIndex] ~= nil and not savegame.resetVehicles

				if allowLoading then
					local fillTypeName = getXMLString(xmlFile, key .. "#fillType")
					local fillLevel = getXMLFloat(xmlFile, key .. "#fillLevel")
					local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

					self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, fillLevel, fillTypeIndex, ToolType.UNDEFINED, nil)
				end

				i = i + 1
			end
		else
			for fillUnitIndex, fillUnit in pairs(spec.fillUnits) do
				if fillUnit.startFillLevel ~= nil and fillUnit.startFillTypeIndex ~= nil then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, fillUnit.startFillLevel, fillUnit.startFillTypeIndex, ToolType.UNDEFINED, nil)
				end
			end
		end
	end
end

function FillUnit:onDelete()
	local spec = self.spec_fillUnit

	g_currentMission:removeActivatableObject(spec.fillTrigger.activatable)

	for _, trigger in pairs(spec.fillTrigger.triggers) do
		trigger:onVehicleDeleted(self)
	end

	if spec.unloadTrigger ~= nil then
		spec.unloadTrigger:delete()
	end

	if spec.loadTrigger ~= nil then
		spec.loadTrigger:delete()
	end
end

function FillUnit:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_fillUnit
	local i = 0

	for k, fillUnit in ipairs(spec.fillUnits) do
		if fillUnit.needsSaving then
			local fillUnitKey = string.format("%s.unit(%d)", key, i)
			local fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillUnit.fillType), "unknown")

			setXMLInt(xmlFile, fillUnitKey .. "#index", k)
			setXMLString(xmlFile, fillUnitKey .. "#fillType", fillTypeName)
			setXMLFloat(xmlFile, fillUnitKey .. "#fillLevel", fillUnit.fillLevel)

			i = i + 1
		end
	end
end

function FillUnit:saveStatsToXMLFile(xmlFile, key)
	local spec = self.spec_fillUnit
	local fillTypes = ""
	local fillLevels = ""
	local numFillUnits = table.getn(spec.fillUnits)

	for i, fillUnit in ipairs(spec.fillUnits) do
		local fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillUnit.fillType), "unknown")
		fillTypes = fillTypes .. HTMLUtil.encodeToHTML(tostring(fillTypeName))
		fillLevels = fillLevels .. string.format("%.3f", fillUnit.fillLevel)

		if numFillUnits > 1 and i ~= numFillUnits then
			fillTypes = fillTypes .. " "
			fillLevels = fillLevels .. " "
		end
	end

	setXMLString(xmlFile, key .. "#fillTypes", fillTypes)
	setXMLString(xmlFile, key .. "#fillLevels", fillLevels)
end

function FillUnit:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_fillUnit

		self:setFillUnitIsFilling(streamReadBool(streamId), true)

		if spec.loadTrigger ~= nil then
			local loadTriggerId = streamReadInt32(streamId)

			spec.loadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(self.loadTrigger, loadTriggerId)
		end

		if spec.unloadTrigger ~= nil then
			local unloadTriggerId = streamReadInt32(streamId)

			spec.unloadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(self.unloadTrigger, unloadTriggerId)
		end

		for i = 1, table.getn(spec.fillUnits) do
			if spec.fillUnits[i].synchronizeFillLevel then
				local fillLevel = streamReadFloat32(streamId)
				local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

				self:addFillUnitFillLevel(self:getOwnerFarmId(), i, fillLevel, fillType, ToolType.UNDEFINED, nil)

				local lastValidFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

				self:setFillUnitLastValidFillType(i, lastValidFillType, true)
			end
		end
	end
end

function FillUnit:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_fillUnit

		streamWriteBool(streamId, spec.fillTrigger.isFilling)

		if spec.loadTrigger ~= nil then
			streamWriteInt32(streamId, NetworkUtil.getObjectId(spec.loadTrigger))
			spec.loadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, spec.loadTrigger)
		end

		if spec.unloadTrigger ~= nil then
			streamWriteInt32(streamId, NetworkUtil.getObjectId(spec.unloadTrigger))
			spec.unloadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, spec.unloadTrigger)
		end

		for i = 1, table.getn(spec.fillUnits) do
			if spec.fillUnits[i].synchronizeFillLevel then
				local fillUnit = spec.fillUnits[i]

				streamWriteFloat32(streamId, fillUnit.fillLevel)
				streamWriteUIntN(streamId, fillUnit.fillType, FillTypeManager.SEND_NUM_BITS)
				streamWriteUIntN(streamId, fillUnit.lastValidFillType, FillTypeManager.SEND_NUM_BITS)
			end
		end
	end
end

function FillUnit:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_fillUnit

		if streamReadBool(streamId) then
			for i = 1, table.getn(spec.fillUnits) do
				local fillUnit = spec.fillUnits[i]

				if fillUnit.synchronizeFillLevel then
					local fillLevel = nil

					if fillUnit.synchronizeFullFillLevel then
						fillLevel = streamReadFloat32(streamId)
					else
						local maxValue = 2^fillUnit.synchronizationNumBits - 1
						fillLevel = fillUnit.capacity * streamReadUIntN(streamId, fillUnit.synchronizationNumBits) / maxValue
					end

					local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

					if fillLevel ~= fillUnit.fillLevel or fillType ~= fillUnit.fillType then
						if fillType == FillType.UNKNOWN then
							self:addFillUnitFillLevel(self:getOwnerFarmId(), i, -math.huge, self:getFillUnitFillType(i), ToolType.UNDEFINED, nil)
						else
							self:addFillUnitFillLevel(self:getOwnerFarmId(), i, fillLevel - fillUnit.fillLevel, fillType, ToolType.UNDEFINED, nil)
						end
					end

					local lastValidFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

					self:setFillUnitLastValidFillType(i, lastValidFillType, lastValidFillType ~= fillUnit.lastValidFillType)
				end
			end
		end
	end
end

function FillUnit:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_fillUnit

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for i = 1, table.getn(spec.fillUnits) do
				local fillUnit = spec.fillUnits[i]

				if fillUnit.synchronizeFillLevel then
					if fillUnit.synchronizeFullFillLevel then
						streamWriteFloat32(streamId, fillUnit.fillLevelSent)
					else
						local percent = 0

						if fillUnit.capacity > 0 then
							percent = MathUtil.clamp(fillUnit.fillLevelSent / fillUnit.capacity, 0, 1)
						end

						local value = math.floor(percent * (2^fillUnit.synchronizationNumBits - 1) + 0.5)

						streamWriteUIntN(streamId, value, fillUnit.synchronizationNumBits)
					end

					streamWriteUIntN(streamId, fillUnit.fillTypeSent, FillTypeManager.SEND_NUM_BITS)
					streamWriteUIntN(streamId, fillUnit.lastValidFillTypeSent, FillTypeManager.SEND_NUM_BITS)
				end
			end
		end
	end
end

function FillUnit:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_fillUnit

	if self.isServer and spec.fillTrigger.isFilling then
		local delta = 0
		local trigger = spec.fillTrigger.currentTrigger

		if trigger ~= nil then
			delta = spec.fillTrigger.litersPerSecond * dt * 0.001
			delta = trigger:fillVehicle(self, delta, dt)
		end

		if delta <= 0 then
			self:setFillUnitIsFilling(false)
		end
	end

	if self.isClient then
		for _, fillUnit in pairs(spec.fillUnits) do
			self:updateMeasurementNodes(fillUnit, dt, false)
		end

		self:updateAlarmTriggers(spec.activeAlarmTriggers)

		for effect, time in pairs(spec.activeFillEffects) do
			time = time - dt

			if time < 0 then
				g_effectManager:stopEffects(effect)

				spec.activeFillEffects[effect] = nil
			else
				spec.activeFillEffects[effect] = time
			end
		end

		for animationNodes, time in pairs(spec.activeFillAnimations) do
			time = time - dt

			if time < 0 then
				g_animationManager:stopAnimations(animationNodes)

				spec.activeFillAnimations[animationNodes] = nil
			else
				spec.activeFillAnimations[animationNodes] = time
			end
		end
	end
end

function FillUnit:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getDrawFirstFillText() then
		g_currentMission:addExtraPrintText(g_i18n:getText("info_firstFillTheTool"))
	end
end

function FillUnit:onDeactivate()
	local spec = self.spec_fillUnit

	if spec.fillTrigger.isFilling then
		self:setFillUnitIsFilling(false, true)
	end
end

function FillUnit:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_fillUnit

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if self.isServer and GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_NEXT, self, FillUnit.actionEventConsoleFillUnitNext, false, true, false, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_INC, self, FillUnit.actionEventConsoleFillUnitInc, false, true, false, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CONSOLE_DEBUG_FILLUNIT_DEC, self, FillUnit.actionEventConsoleFillUnitDec, false, true, false, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			end

			if spec.unloading ~= nil then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.UNLOAD, self, FillUnit.actionEventUnload, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

				spec.unloadActionEventId = actionEventId

				FillUnit.updateUnloadActionDisplay(self)
			end
		end
	end
end

function FillUnit:getDrawFirstFillText()
	return false
end

function FillUnit:getFillUnits()
	local spec = self.spec_fillUnit

	return spec.fillUnits
end

function FillUnit:getFillUnitByIndex(fillUnitIndex)
	local spec = self.spec_fillUnit

	if self:getFillUnitExists(fillUnitIndex) then
		return spec.fillUnits[fillUnitIndex]
	end

	return nil
end

function FillUnit:getFillUnitExists(fillUnitIndex)
	local spec = self.spec_fillUnit

	return fillUnitIndex ~= nil and spec.fillUnits[fillUnitIndex] ~= nil
end

function FillUnit:getFillUnitCapacity(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].capacity
	end

	return nil
end

function FillUnit:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].capacity - spec.fillUnits[fillUnitIndex].fillLevel
	end

	return nil
end

function FillUnit:getFillUnitFillLevel(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].fillLevel
	end

	return nil
end

function FillUnit:getFillUnitFillLevelPercentage(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].fillLevel / spec.fillUnits[fillUnitIndex].capacity
	end

	return nil
end

function FillUnit:getFillUnitFillType(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].fillType
	end

	return nil
end

function FillUnit:getFillUnitLastValidFillType(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].lastValidFillType
	end

	return nil
end

function FillUnit:getFillUnitFirstSupportedFillType(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return next(spec.fillUnits[fillUnitIndex].supportedFillTypes)
	end

	return nil
end

function FillUnit:getFillUnitExactFillRootNode(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].exactFillRootNode
	end

	return nil
end

function FillUnit:getFillUnitRootNode(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].fillRootNode
	end

	return nil
end

function FillUnit:getFillUnitAutoAimTargetNode(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].autoAimTarget.node
	end

	return nil
end

function FillUnit:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].supportedFillTypes[fillType]
	end

	return false
end

function FillUnit:getFillUnitSupportsToolType(fillUnitIndex, toolType)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].supportedToolTypes[toolType]
	end

	return false
end

function FillUnit:getFillUnitSupportsToolTypeAndFillType(fillUnitIndex, toolType, fillType)
	return self:getFillUnitSupportsToolType(fillUnitIndex, toolType) and self:getFillUnitSupportsFillType(fillUnitIndex, fillType)
end

function FillUnit:getFillUnitSupportedFillTypes(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].supportedFillTypes
	end

	return nil
end

function FillUnit:getFillUnitSupportedToolTypes(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].supportedToolTypes
	end

	return nil
end

function FillUnit:getFillUnitAllowsFillType(fillUnitIndex, fillType)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
		if fillType == spec.fillUnits[fillUnitIndex].fillType then
			return true
		else
			return spec.fillUnits[fillUnitIndex].fillLevel / math.max(spec.fillUnits[fillUnitIndex].capacity, 0.0001) <= self:getFillTypeChangeThreshold()
		end
	end

	return false
end

function FillUnit:getFillTypeChangeThreshold(fillUnitIndex)
	if fillUnitIndex == nil then
		return self.spec_fillUnit.fillTypeChangeThreshold
	else
		local capacity = self:getFillUnitCapacity(fillUnitIndex) or 1

		return capacity * self.spec_fillUnit.fillTypeChangeThreshold
	end
end

function FillUnit:getFirstValidFillUnitToFill(fillType, ignoreCapacity)
	local spec = self.spec_fillUnit

	for fillUnitIndex, _ in ipairs(spec.fillUnits) do
		if self:getFillUnitAllowsFillType(fillUnitIndex, fillType) and (self:getFillUnitFreeCapacity(fillUnitIndex) > 0 or ignoreCapacity ~= nil and ignoreCapacity) then
			return fillUnitIndex
		end
	end

	return nil
end

function FillUnit:setFillUnitFillType(fillUnitIndex, fillTypeIndex)
	local spec = self.spec_fillUnit
	local oldFillTypeIndex = spec.fillUnits[fillUnitIndex].fillType

	if oldFillTypeIndex ~= fillTypeIndex then
		spec.fillUnits[fillUnitIndex].fillType = fillTypeIndex

		SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	end
end

function FillUnit:setFillUnitFillTypeToDisplay(fillUnitIndex, fillTypeIndex, isPersistent)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		spec.fillUnits[fillUnitIndex].fillTypeToDisplay = fillTypeIndex
		spec.fillUnits[fillUnitIndex].fillTypeToDisplayIsPersistent = isPersistent ~= nil and isPersistent
	end
end

function FillUnit:setFillUnitFillLevelToDisplay(fillUnitIndex, fillLevel, isPersistent)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		spec.fillUnits[fillUnitIndex].fillLevelToDisplay = fillLevel
		spec.fillUnits[fillUnitIndex].fillLevelToDisplayIsPersistent = isPersistent ~= nil and isPersistent
	end
end

function FillUnit:setFillUnitCapacity(fillUnitIndex, capacity)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		spec.fillUnits[fillUnitIndex].capacity = capacity
	end
end

function FillUnit:setFillUnitForcedMaterialFillType(fillUnitIndex, forcedMaterialFillType)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		spec.fillUnits[fillUnitIndex].forcedMaterialFillType = forcedMaterialFillType
	end

	self:setFillPlaneForcedFillType(fillUnitIndex, forcedMaterialFillType)

	if self.setFillVolumeForcedFillTypeByFillUnitIndex ~= nil then
		self:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedMaterialFillType)
	end
end

function FillUnit:getFillUnitForcedMaterialFillType(fillUnitIndex)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil then
		return spec.fillUnits[fillUnitIndex].forcedMaterialFillType
	end

	return FillType.UNKNOWN
end

function FillUnit:updateAlarmTriggers(alarmTriggers)
	for _, alarmTrigger in pairs(alarmTriggers) do
		self:setAlarmTriggerState(alarmTrigger, self:getAlarmTriggerIsActive(alarmTrigger))
	end
end

function FillUnit:getAlarmTriggerIsActive(alarmTrigger)
	local ret = false
	local fillLevelPct = alarmTrigger.fillUnit.fillLevel / alarmTrigger.fillUnit.capacity

	if alarmTrigger.minFillLevel <= fillLevelPct and fillLevelPct <= alarmTrigger.maxFillLevel then
		ret = true
	end

	return ret
end

function FillUnit:setAlarmTriggerState(alarmTrigger, state)
	local spec = self.spec_fillUnit

	if state ~= alarmTrigger.isActive then
		if state then
			if alarmTrigger.sample ~= nil then
				g_soundManager:playSample(alarmTrigger.sample)
			end

			spec.activeAlarmTriggers[alarmTrigger] = alarmTrigger
		else
			if alarmTrigger.sample ~= nil then
				g_soundManager:stopSample(alarmTrigger.sample)
			end

			spec.activeAlarmTriggers[alarmTrigger] = nil
		end

		alarmTrigger.isActive = state

		SpecializationUtil.raiseEvent(self, "onAlarmTriggerChanged", alarmTrigger, state)
	end
end

function FillUnit:getFillUnitIndexFromNode(node)
	local spec = self.spec_fillUnit
	local fillUnit = spec.exactFillRootNodeToFillUnit[node]

	if fillUnit ~= nil then
		return fillUnit.fillUnitIndex
	end

	return nil
end

function FillUnit:getFillUnitExtraDistanceFromNode(node)
	local spec = self.spec_fillUnit

	return spec.exactFillRootNodeToExtraDistance[node] or 0
end

function FillUnit:getFillUnitFromNode(node)
	local spec = self.spec_fillUnit

	return spec.exactFillRootNodeToFillUnit[node]
end

function FillUnit:emptyAllFillUnits(ignoreDeleteOnEmptyFlag)
	local spec = self.spec_fillUnit
	local oldRemoveOnEmpty = spec.removeVehicleIfEmpty

	if ignoreDeleteOnEmptyFlag then
		spec.removeVehicleIfEmpty = false
	end

	for k, _ in ipairs(self:getFillUnits()) do
		local fillTypeIndex = self:getFillUnitFillType(k)

		self:addFillUnitFillLevel(self:getOwnerFarmId(), k, -math.huge, fillTypeIndex, ToolType.UNDEFINED, nil)
	end

	spec.removeVehicleIfEmpty = oldRemoveOnEmpty
end

function FillUnit:loadFillUnitUnloadingFromXML(xmlFile, key, entry, index)
	local spec = self.spec_fillUnit
	entry.node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node")) or self.rootNode
	entry.width = getXMLFloat(self.xmlFile, key .. "#width") or 15
	entry.offset = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, key .. "#offset") or "0 0 0", 3)

	return true
end

function FillUnit:unloadFillUnits(ignoreWarning)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(FillUnitUnloadEvent:new(self))
	else
		local spec = self.spec_fillUnit
		local unloadingPlaces = spec.unloading
		local places = {}

		for _, unloading in ipairs(unloadingPlaces) do
			local node = unloading.node
			local ox, oy, oz = unpack(unloading.offset)
			local x, y, z = localToWorld(node, ox - unloading.width * 0.5, oy, oz)
			local place = {
				startZ = z,
				startY = y,
				startX = x
			}
			place.rotX, place.rotY, place.rotZ = getWorldRotation(node)
			place.dirX, place.dirY, place.dirZ = localDirectionToWorld(node, 1, 0, 0)
			place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(node, 0, 0, 1)
			place.yOffset = 1
			place.maxWidth = math.huge
			place.maxLength = math.huge
			place.width = unloading.width

			table.insert(places, place)
		end

		local usedPlaces = {}
		local success = true
		local availablePallets = {}

		for k, fillUnit in ipairs(self:getFillUnits()) do
			local fillLevel = self:getFillUnitFillLevel(k)
			local fillTypeIndex = self:getFillUnitFillType(k)
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			if fillUnit.canBeUnloaded and fillLevel > 0 and fillType.palletFilename ~= nil then
				while fillLevel > 0 do
					local pallet = availablePallets[fillTypeIndex]
					local isNewPallet = false

					if pallet == nil then
						local sizeWidth, sizeLength, widthOffset, lengthOffset = StoreItemUtil.getSizeValues(fillType.palletFilename, "vehicle", 0, {})
						local x, _, z, place, width, _ = PlacementUtil.getPlace(places, sizeWidth, sizeLength, widthOffset, lengthOffset, usedPlaces, true, true, true)

						if x == nil then
							success = false

							break
						end

						PlacementUtil.markPlaceUsed(usedPlaces, place, width)

						pallet = g_currentMission:loadVehicle(fillType.palletFilename, x, nil, z, 0, place.rotY, true, 0, Vehicle.PROPERTY_STATE_OWNED, self:getOwnerFarmId(), nil, )

						if pallet ~= nil then
							pallet:emptyAllFillUnits(true)

							isNewPallet = true
						else
							g_logManager:warning("Failed to discharge fill unit into pallets '%s'. Pallet '%s' not available!", fillType.palletFilename)

							break
						end
					end

					local fillUnitIndex = pallet:getFirstValidFillUnitToFill(fillTypeIndex)

					if fillUnitIndex ~= nil then
						local appliedDelta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, fillLevel, fillTypeIndex, ToolType.UNDEFINED, nil)

						self:addFillUnitFillLevel(self:getOwnerFarmId(), k, -appliedDelta, fillTypeIndex, ToolType.UNDEFINED, nil)

						fillLevel = fillLevel - appliedDelta
					else
						if isNewPallet then
							break
						end

						availablePallets[fillTypeIndex] = nil
					end
				end
			end
		end

		if (ignoreWarning == nil or not ignoreWarning) and not success then
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("fillUnit_unload_nospace"))
		end

		return success
	end
end

function FillUnit:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local spec = self.spec_fillUnit

	if fillLevelDelta < 0 and not g_currentMission.accessHandler:canFarmAccess(farmId, self, true) then
		return 0
	end

	if self.getMountObject ~= nil then
		local mounter = self:getDynamicMountObject() or self:getMountObject()

		if mounter ~= nil and not g_currentMission.accessHandler:canFarmAccess(mounter:getActiveFarm(), self, true) then
			return 0
		end
	end

	local fillUnit = spec.fillUnits[fillUnitIndex]

	if fillUnit ~= nil then
		if not self:getFillUnitSupportsToolTypeAndFillType(fillUnitIndex, toolType, fillTypeIndex) then
			return 0
		end

		local oldFillLevel = fillUnit.fillLevel
		local capacity = fillUnit.capacity

		if capacity == 0 then
			capacity = math.huge
		end

		if fillUnit.fillType == fillTypeIndex then
			fillUnit.fillLevel = math.max(0, math.min(capacity, oldFillLevel + fillLevelDelta))
		elseif fillLevelDelta > 0 then
			local allowFillType = self:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex)

			if allowFillType then
				local oldFillTypeIndex = fillUnit.fillType

				if oldFillLevel > 0 then
					self:addFillUnitFillLevel(farmId, fillUnitIndex, -math.huge, fillUnit.fillType, toolType, fillPositionData)
				end

				oldFillLevel = 0
				fillUnit.fillLevel = math.max(0, math.min(capacity, fillLevelDelta))
				fillUnit.fillType = fillTypeIndex

				self:getRootVehicle():raiseStateChange(Vehicle.STATE_CHANGE_FILLTYPE_CHANGE)
				SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
			else
				return 0
			end
		end

		if fillUnit.fillLevel > 0 then
			fillUnit.lastValidFillType = fillUnit.fillType
		else
			SpecializationUtil.raiseEvent(self, "onChangedFillType", fillUnitIndex, FillType.UNKNOWN, fillUnit.fillType)

			fillUnit.fillType = FillType.UNKNOWN

			if not fillUnit.fillTypeToDisplayIsPersistent then
				fillUnit.fillTypeToDisplay = FillType.UNKNOWN
			end

			if not fillUnit.fillLevelToDisplayIsPersistent then
				fillUnit.fillLevelToDisplay = nil
			end
		end

		local appliedDelta = fillUnit.fillLevel - oldFillLevel

		if self.isServer and fillUnit.synchronizeFillLevel then
			local hasChanged = false

			if fillUnit.fillLevel ~= fillUnit.fillLevelSent then
				local maxValue = 2^fillUnit.synchronizationNumBits - 1
				local levelPerBit = fillUnit.capacity / maxValue
				local changedLevel = math.abs(fillUnit.fillLevel - fillUnit.fillLevelSent)

				if levelPerBit < changedLevel then
					fillUnit.fillLevelSent = fillUnit.fillLevel
					hasChanged = true
				end
			end

			if fillUnit.fillType ~= fillUnit.fillTypeSent then
				fillUnit.fillTypeSent = fillUnit.fillType
				hasChanged = true
			end

			if fillUnit.lastValidFillType ~= fillUnit.lastValidFillTypeSent then
				fillUnit.lastValidFillTypeSent = fillUnit.lastValidFillType
				hasChanged = true
			end

			if hasChanged then
				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		end

		if fillUnit.updateMass then
			self:setMassDirty()
		end

		self:updateFillUnitAutoAimTarget(fillUnit)

		if self.isClient then
			self:updateAlarmTriggers(fillUnit.alarmTriggers)
			self:updateFillUnitFillPlane(fillUnit)
			self:updateMeasurementNodes(fillUnit, 0, true)
		end

		SpecializationUtil.raiseEvent(self, "onFillUnitFillLevelChanged", fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)

		if self.isServer and spec.removeVehicleIfEmpty and fillUnit.fillLevel <= 0.3 then
			g_currentMission:removeVehicle(self)
		end

		if appliedDelta > 0 then
			if #spec.fillEffects > 0 then
				g_effectManager:setFillType(spec.fillEffects, fillUnit.fillType)
				g_effectManager:startEffects(spec.fillEffects)

				spec.activeFillEffects[spec.fillEffects] = 500
			end

			if #fillUnit.fillEffects > 0 then
				g_effectManager:setFillType(fillUnit.fillEffects, fillUnit.fillType)
				g_effectManager:startEffects(fillUnit.fillEffects)

				spec.activeFillEffects[fillUnit.fillEffects] = 500
			end

			if #spec.animationNodes > 0 then
				g_animationManager:startAnimations(spec.animationNodes)

				spec.activeFillAnimations[spec.animationNodes] = 500
			end

			if #fillUnit.animationNodes > 0 then
				g_animationManager:startAnimations(fillUnit.animationNodes)

				spec.activeFillAnimations[fillUnit.animationNodes] = 500
			end

			if fillUnit.fillAnimation ~= nil and fillUnit.fillAnimationLoadTime ~= nil then
				local animTime = self:getAnimationTime(fillUnit.fillAnimation)
				local direction = MathUtil.sign(fillUnit.fillAnimationLoadTime - animTime)

				if direction ~= 0 then
					self:playAnimation(fillUnit.fillAnimation, direction, animTime)
					self:setAnimationStopTime(fillUnit.fillAnimation, fillUnit.fillAnimationLoadTime)
				end
			end
		end

		if fillUnit.fillLevel < 0.0001 and fillUnit.fillAnimation ~= nil and fillUnit.fillAnimationEmptyTime ~= nil then
			local animTime = self:getAnimationTime(fillUnit.fillAnimation)
			local direction = Math.sign(fillUnit.fillAnimationEmptyTime - animTime)

			self:playAnimation(fillUnit.fillAnimation, direction, animTime)
			self:setAnimationStopTime(fillUnit.fillAnimation, fillUnit.fillAnimationEmptyTime)
		end

		if self.setDashboardsDirty ~= nil then
			self:setDashboardsDirty()
		end

		FillUnit.updateUnloadActionDisplay(self)

		return appliedDelta
	end

	return 0
end

function FillUnit:setFillUnitLastValidFillType(fillUnitIndex, fillType, force)
	local spec = self.spec_fillUnit
	local fillUnit = spec.fillUnits[fillUnitIndex]

	if fillUnit ~= nil and fillUnit.lastValidFillType ~= fillType then
		fillUnit.lastValidFillType = fillType
		fillUnit.lastValidFillTypeSent = fillType

		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function FillUnit:loadFillUnitFromXML(xmlFile, key, entry, index)
	local spec = self.spec_fillUnit
	entry.fillUnitIndex = index
	entry.capacity = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#capacity"), math.huge)
	entry.updateMass = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateMass"), true)
	entry.canBeUnloaded = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canBeUnloaded"), true)
	entry.needsSaving = true
	entry.fillLevel = 0
	entry.fillLevelSent = 0
	entry.fillType = FillType.UNKNOWN
	entry.fillTypeSent = FillType.UNKNOWN
	entry.fillTypeToDisplay = FillType.UNKNOWN
	entry.fillLevelToDisplay = nil
	entry.lastValidFillType = FillType.UNKNOWN
	entry.lastValidFillTypeSent = FillType.UNKNOWN

	if hasXMLProperty(xmlFile, key .. ".exactFillRootNode") then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".exactFillRootNode#index", key .. ".exactFillRootNode#node")

		entry.exactFillRootNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".exactFillRootNode#node"), self.i3dMappings)

		if entry.exactFillRootNode ~= nil then
			local colMask = getCollisionMask(entry.exactFillRootNode)

			if bitAND(FillUnit.EXACTFILLROOTNODE_MASK, colMask) == 0 then
				g_logManager:xmlWarning(self.configFileName, "Invalid collision mask for exactFillRootNode '%s'. Bit 30 needs to be set!", key)

				return false
			end

			spec.exactFillRootNodeToFillUnit[entry.exactFillRootNode] = entry
			spec.exactFillRootNodeToExtraDistance[entry.exactFillRootNode] = getXMLFloat(xmlFile, key .. ".exactFillRootNode#extraEffectDistance") or 0
			spec.hasExactFillRootNodes = true
		else
			g_logManager:xmlWarning(self.configFileName, "ExactFillRootNode not found for fillUnit '%s'!", key)
		end
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".autoAimTargetNode#index", key .. ".autoAimTargetNode#node")

	entry.autoAimTarget = {
		node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".autoAimTargetNode#node"), self.i3dMappings)
	}

	if entry.autoAimTarget.node ~= nil then
		entry.autoAimTarget.baseTrans = {
			getTranslation(entry.autoAimTarget.node)
		}
		entry.autoAimTarget.startZ = getXMLFloat(xmlFile, key .. ".autoAimTargetNode#startZ")
		entry.autoAimTarget.endZ = getXMLFloat(xmlFile, key .. ".autoAimTargetNode#endZ")
		entry.autoAimTarget.startPercentage = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".autoAimTargetNode#startPercentage"), 25) / 100
		entry.autoAimTarget.invert = Utils.getNoNil(getXMLBool(xmlFile, key .. ".autoAimTargetNode#invert"), false)

		if entry.autoAimTarget.startZ ~= nil and entry.autoAimTarget.endZ ~= nil then
			local startZ = entry.autoAimTarget.startZ

			if entry.autoAimTarget.invert then
				startZ = entry.autoAimTarget.endZ
			end

			setTranslation(entry.autoAimTarget.node, entry.autoAimTarget.baseTrans[1], entry.autoAimTarget.baseTrans[2], startZ)
		end
	end

	entry.supportedFillTypes = {}
	local fillTypes = nil
	local fillTypeCategories = getXMLString(xmlFile, key .. "#fillTypeCategories")
	local fillTypeNames = getXMLString(xmlFile, key .. "#fillTypes")

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. self.configFileName .. "' has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. self.configFileName .. "' has invalid fillType '%s'.")
	else
		g_logManager:xmlWarning(self.configFileName, "Missing 'fillTypeCategories' or 'fillTypes' for fillUnit '%s'", key)

		return false
	end

	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			entry.supportedFillTypes[fillType] = true
		end
	end

	entry.supportedToolTypes = {}

	for i = 1, g_toolTypeManager:getNumberOfToolTypes() do
		entry.supportedToolTypes[i] = true
	end

	local startFillLevel = getXMLFloat(xmlFile, key .. "#startFillLevel")
	local startFillTypeStr = getXMLString(xmlFile, key .. "#startFillType")

	if startFillTypeStr ~= nil then
		local startFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(startFillTypeStr)

		if startFillTypeIndex ~= nil then
			entry.startFillLevel = startFillLevel
			entry.startFillTypeIndex = startFillTypeIndex
		end
	end

	entry.fillRootNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".fillRootNode#node"), self.i3dMappings)

	if entry.fillRootNode == nil then
		entry.fillRootNode = self.components[1].node
	end

	entry.fillMassNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".fillMassNode#node"), self.i3dMappings)
	local updateFillLevelMass = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateFillLevelMass"), true)

	if entry.fillMassNode == nil and updateFillLevelMass then
		entry.fillMassNode = self.components[1].node
	end

	entry.synchronizeFillLevel = Utils.getNoNil(getXMLBool(xmlFile, key .. "#synchronizeFillLevel"), true)
	entry.synchronizeFullFillLevel = Utils.getNoNil(getXMLBool(xmlFile, key .. "#synchronizeFullFillLevel"), false)
	local defaultBits = 16

	for startCapacity, bits in pairs(FillUnit.CAPACITY_TO_NETWORK_BITS) do
		if startCapacity <= entry.capacity then
			defaultBits = bits
		end
	end

	entry.synchronizationNumBits = Utils.getNoNil(getXMLInt(xmlFile, key .. "#synchronizationNumBits"), defaultBits)
	entry.showOnHud = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showOnHud"), true)
	entry.blocksAutomatedTrainTravel = Utils.getNoNil(getXMLBool(xmlFile, key .. "#blocksAutomatedTrainTravel"), false)
	entry.fillAnimation = getXMLString(xmlFile, key .. "#fillAnimation")
	entry.fillAnimationLoadTime = getXMLFloat(xmlFile, key .. "#fillAnimationLoadTime")
	entry.fillAnimationEmptyTime = getXMLFloat(xmlFile, key .. "#fillAnimationEmptyTime")

	if self.isClient then
		entry.alarmTriggers = {}
		local i = 0

		while true do
			local nodeKey = key .. string.format(".alarmTriggers.alarmTrigger(%d)", i)

			if not hasXMLProperty(xmlFile, nodeKey) then
				break
			end

			local alarmTrigger = {}

			if self:loadAlarmTrigger(xmlFile, nodeKey, alarmTrigger, entry) then
				table.insert(entry.alarmTriggers, alarmTrigger)
			end

			i = i + 1
		end

		entry.measurementNodes = {}
		i = 0

		while true do
			local nodeKey = key .. string.format(".measurementNodes.measurementNode(%d)", i)

			if not hasXMLProperty(xmlFile, nodeKey) then
				break
			end

			local measurementNode = {}

			if self:loadMeasurementNode(xmlFile, nodeKey, measurementNode) then
				table.insert(entry.measurementNodes, measurementNode)
			end

			i = i + 1
		end

		entry.fillPlane = {}
		entry.lastFillPlaneType = nil

		if not self:loadFillPlane(xmlFile, key .. ".fillPlane", entry.fillPlane, entry) then
			entry.fillPlane = nil
		end

		entry.fillEffects = g_effectManager:loadEffect(xmlFile, key .. ".fillEffect", self.components, self, self.i3dMappings)
		entry.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".fillLevelHud", key .. ".dashboard")

		if self.loadDashboardsFromXML ~= nil then
			self:loadDashboardsFromXML(xmlFile, key, {
				maxFunc = "capacity",
				valueFunc = "fillLevel",
				minFunc = 0,
				valueTypeToLoad = "fillLevel",
				valueObject = entry
			})
			self:loadDashboardsFromXML(xmlFile, key, {
				maxFunc = 100,
				minFunc = 0,
				valueTypeToLoad = "fillLevelPct",
				valueObject = entry,
				valueFunc = function (fillUnit)
					return MathUtil.clamp(fillUnit.fillLevel / fillUnit.capacity, 0, 1) * 100
				end
			})
			self:loadDashboardsFromXML(xmlFile, key, {
				maxFunc = "capacity",
				valueFunc = "fillLevel",
				minFunc = 0,
				valueTypeToLoad = "fillLevelWarning",
				valueObject = entry,
				additionalAttributesFunc = Dashboard.warningAttributes,
				stateFunc = Dashboard.warningState
			})
		end
	end

	return true
end

function FillUnit:loadAlarmTrigger(xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.fillUnit = fillUnit
	alarmTrigger.isActive = false
	local success = true
	alarmTrigger.minFillLevel = getXMLFloat(xmlFile, key .. "#minFillLevel")

	if alarmTrigger.minFillLevel == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'minFillLevel' for alarmTrigger '%s'", key)

		success = false
	end

	alarmTrigger.maxFillLevel = getXMLFloat(xmlFile, key .. "#maxFillLevel")

	if alarmTrigger.maxFillLevel == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'maxFillLevel' for alarmTrigger '%s'", key)

		success = false
	end

	alarmTrigger.sample = g_soundManager:loadSampleFromXML(xmlFile, key, "alarmSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

	return success
end

function FillUnit:loadMeasurementNode(xmlFile, key, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for measurementNode '%s'", key)

		return false
	end

	entry.node = node
	entry.measurementTime = 0

	return true
end

function FillUnit:updateMeasurementNodes(fillUnit, dt, setActive)
	if fillUnit.measurementNodes ~= nil then
		for _, measurementNode in pairs(fillUnit.measurementNodes) do
			if setActive ~= nil and setActive then
				measurementNode.measurementTime = 5000
			end

			if measurementNode.measurementTime > 0 then
				measurementNode.measurementTime = math.max(measurementNode.measurementTime - dt, 0)
				local isWorking = math.min(measurementNode.measurementTime / 1000, 1)

				if measurementNode.measurementTime == 0 or fillUnit.fillLevel <= 0 then
					isWorking = 0
				end

				setShaderParameter(measurementNode.node, "fillLevel", fillUnit.fillLevel / fillUnit.capacity, isWorking, 0, 0, false)
			end
		end
	end
end

function FillUnit:loadFillPlane(xmlFile, key, fillPlane, fillUnit)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#fillType", "Material is dynamically assigned to the nodes")

	if not hasXMLProperty(xmlFile, key) then
		return false
	end

	fillPlane.nodes = {}
	local i = 0

	while true do
		local nodeKey = string.format("%s.node(%d)", key, i)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, nodeKey .. "#index", nodeKey .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, nodeKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			local defaultX, defaultY, defaultZ = getTranslation(node)
			local defaultRX, defaultRY, defaultRZ = getRotation(node)
			local animCurve = AnimCurve:new(linearInterpolatorTransRotScale)
			local j = 0

			while true do
				local animKey = string.format("%s.key(%d)", nodeKey, j)

				if not hasXMLProperty(xmlFile, animKey) then
					break
				end

				local keyTime = getXMLFloat(xmlFile, animKey .. "#time")

				if keyTime == nil then
					break
				end

				local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, animKey .. "#translation"))

				if y == nil then
					y = getXMLFloat(xmlFile, animKey .. "#y")
				end

				x = Utils.getNoNil(x, defaultX)
				y = Utils.getNoNil(y, defaultY)
				z = Utils.getNoNil(z, defaultZ)
				local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, animKey .. "#rotation"))
				rx = Utils.getNoNilRad(rx, defaultRX)
				ry = Utils.getNoNilRad(ry, defaultRY)
				rz = Utils.getNoNilRad(rz, defaultRZ)
				local sx, sy, sz = StringUtil.getVectorFromString(getXMLString(xmlFile, animKey .. "#scale"))
				sx = Utils.getNoNil(sx, 1)
				sy = Utils.getNoNil(sy, 1)
				sz = Utils.getNoNil(sz, 1)

				animCurve:addKeyframe({
					x = x,
					y = y,
					z = z,
					rx = rx,
					ry = ry,
					rz = rz,
					sx = sx,
					sy = sy,
					sz = sz,
					time = keyTime
				})

				j = j + 1
			end

			if j == 0 then
				local minY, maxY = StringUtil.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#minMaxY"))
				minY = Utils.getNoNil(minY, defaultY)
				maxY = Utils.getNoNil(maxY, defaultY)

				animCurve:addKeyframe({
					defaultX,
					minY,
					defaultZ,
					defaultRX,
					defaultRY,
					defaultRZ,
					1,
					1,
					1,
					time = 0
				})
				animCurve:addKeyframe({
					defaultX,
					maxY,
					defaultZ,
					defaultRX,
					defaultRY,
					defaultRZ,
					1,
					1,
					1,
					time = 1
				})
			end

			local alwaysVisible = Utils.getNoNil(getXMLBool(xmlFile, nodeKey .. "#alwaysVisible"), false)

			setVisibility(node, alwaysVisible)
			table.insert(fillPlane.nodes, {
				node = node,
				animCurve = animCurve,
				alwaysVisible = alwaysVisible
			})
		end

		i = i + 1
	end

	fillPlane.forcedFillType = nil
	local defaultFillTypeStr = getXMLString(xmlFile, key .. "#defaultFillType")

	if defaultFillTypeStr ~= nil then
		local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeStr)

		if defaultFillTypeIndex == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid defaultFillType '%s' for '%s'!", tostring(defaultFillTypeStr), key)

			return false
		else
			fillPlane.defaultFillType = defaultFillTypeIndex
		end
	else
		fillPlane.defaultFillType = next(fillUnit.supportedFillTypes)
	end

	return true
end

function FillUnit:setFillPlaneForcedFillType(fillUnitIndex, forcedFillType)
	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil and spec.fillUnits[fillUnitIndex].fillPlane ~= nil then
		spec.fillUnits[fillUnitIndex].fillPlane.forcedFillType = forcedFillType
	end
end

function FillUnit:updateFillUnitFillPlane(fillUnit)
	local fillPlane = fillUnit.fillPlane

	if fillPlane ~= nil then
		local t = self:getFillUnitFillLevelPercentage(fillUnit.fillUnitIndex)

		for _, node in ipairs(fillPlane.nodes) do
			local x, y, z, rx, ry, rz, sx, sy, sz = node.animCurve:get(t)

			setTranslation(node.node, x, y, z)
			setRotation(node.node, rx, ry, rz)
			setScale(node.node, sx, sy, sz)
			setVisibility(node.node, fillUnit.fillLevel > 0 or node.alwaysVisible)
		end

		if fillUnit.fillType ~= fillUnit.lastFillPlaneType then
			if fillUnit.fillType ~= FillType.UNKNOWN then
				local usedFillType = fillUnit.fillType

				if fillPlane.forcedFillType ~= nil then
					usedFillType = fillPlane.forcedFillType
				end

				local material = g_materialManager:getMaterial(usedFillType, "fillplane", 1)

				if material == nil and fillPlane.defaultFillType ~= nil then
					material = g_materialManager:getMaterial(fillPlane.defaultFillType, "fillplane", 1)
				end

				if material ~= nil then
					for _, node in ipairs(fillPlane.nodes) do
						setMaterial(node.node, material, 0)
					end
				end
			end

			fillUnit.lastFillPlaneType = fillUnit.fillType
		end
	end
end

function FillUnit:updateFillUnitAutoAimTarget(fillUnit)
	local autoAimTarget = fillUnit.autoAimTarget

	if autoAimTarget.node ~= nil and autoAimTarget.startZ ~= nil and autoAimTarget.endZ ~= nil then
		local startFillLevel = fillUnit.capacity * autoAimTarget.startPercentage
		local percent = MathUtil.clamp((fillUnit.fillLevel - startFillLevel) / (fillUnit.capacity - startFillLevel), 0, 1)

		if autoAimTarget.invert then
			percent = 1 - percent
		end

		local newZ = (autoAimTarget.endZ - autoAimTarget.startZ) * percent + autoAimTarget.startZ

		setTranslation(autoAimTarget.node, autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], newZ)
	end
end

function FillUnit:addFillUnitTrigger(trigger, fillTypeIndex, fillUnitIndex)
	local spec = self.spec_fillUnit

	if #spec.fillTrigger.triggers == 0 then
		g_currentMission:addActivatableObject(spec.fillTrigger.activatable)
		spec.fillTrigger.activatable:setFillType(fillTypeIndex)

		if self.isServer and g_platformSettingsManager:getSetting("automaticFilling", false) then
			self:setFillUnitIsFilling(true)
		end
	end

	ListUtil.addElementToList(spec.fillTrigger.triggers, trigger)
	SpecializationUtil.raiseEvent(self, "onAddedFillUnitTrigger", fillTypeIndex, fillUnitIndex, #spec.fillTrigger.triggers)
end

function FillUnit:removeFillUnitTrigger(trigger)
	local spec = self.spec_fillUnit

	ListUtil.removeElementFromList(spec.fillTrigger.triggers, trigger)

	if self.isServer and trigger == spec.fillTrigger.currentTrigger then
		self:setFillUnitIsFilling(false)
	end

	if #spec.fillTrigger.triggers == 0 then
		g_currentMission:removeActivatableObject(spec.fillTrigger.activatable)

		if self.isServer and g_platformSettingsManager:getSetting("automaticFilling", false) then
			self:setFillUnitIsFilling(false)
		end
	end

	SpecializationUtil.raiseEvent(self, "onRemovedFillUnitTrigger", #spec.fillTrigger.triggers)
end

function FillUnit:updateFillUnitTriggers()
	local spec = self.spec_fillUnit

	table.sort(spec.fillTrigger.triggers, function (t1, t2)
		local fillTypeIndex1 = t1:getCurrentFillType()
		local fillTypeIndex2 = t2:getCurrentFillType()
		local t1FillUnitIndex = self:getFirstValidFillUnitToFill(fillTypeIndex1)
		local t2FillUnitIndex = self:getFirstValidFillUnitToFill(fillTypeIndex2)

		if t1FillUnitIndex ~= nil and t2FillUnitIndex ~= nil then
			return self:getFillUnitFillLevel(t2FillUnitIndex) < self:getFillUnitFillLevel(t1FillUnitIndex)
		elseif t1FillUnitIndex ~= nil then
			return true
		end

		return false
	end)

	if #spec.fillTrigger.triggers > 0 then
		local fillTypeIndex = spec.fillTrigger.triggers[1]:getCurrentFillType()

		spec.fillTrigger.activatable:setFillType(fillTypeIndex)
	end
end

function FillUnit:setFillUnitIsFilling(isFilling, noEventSend)
	local spec = self.spec_fillUnit

	if isFilling ~= spec.fillTrigger.isFilling then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(SetFillUnitIsFillingEvent:new(self, isFilling), nil, , self)
			else
				g_client:getServerConnection():sendEvent(SetFillUnitIsFillingEvent:new(self, isFilling))
			end
		end

		spec.fillTrigger.isFilling = isFilling

		if isFilling then
			spec.fillTrigger.currentTrigger = nil

			for _, trigger in ipairs(spec.fillTrigger.triggers) do
				if trigger:getIsActivatable(self) then
					spec.fillTrigger.currentTrigger = trigger

					break
				end
			end
		end

		if self.isClient then
			self:setFillSoundIsPlaying(isFilling)

			if spec.fillTrigger.currentTrigger ~= nil then
				spec.fillTrigger.currentTrigger:setFillSoundIsPlaying(isFilling)
			end
		end

		SpecializationUtil.raiseEvent(self, "onFillUnitIsFillingStateChanged", isFilling)

		if not isFilling then
			self:updateFillUnitTriggers()
		end
	end
end

function FillUnit:setFillSoundIsPlaying(isPlaying)
	local spec = self.spec_fillUnit

	if isPlaying then
		if not g_soundManager:getIsSamplePlaying(spec.samples.fill) then
			g_soundManager:playSample(spec.samples.fill)
		end
	elseif g_soundManager:getIsSamplePlaying(spec.samples.fill) then
		g_soundManager:stopSample(spec.samples.fill)
	end
end

function FillUnit:getIsFillUnitActive(fillUnitIndex)
	return true
end

function FillUnit:getAdditionalComponentMass(superFunc, component)
	local additionalMass = superFunc(self, component)
	local spec = self.spec_fillUnit

	for _, fillUnit in ipairs(spec.fillUnits) do
		if fillUnit.updateMass and fillUnit.fillMassNode == component.node and fillUnit.fillType ~= nil and fillUnit.fillType ~= FillType.UNKNOWN then
			local desc = g_fillTypeManager:getFillTypeByIndex(fillUnit.fillType)
			local mass = fillUnit.fillLevel * desc.massPerLiter
			additionalMass = additionalMass + mass
		end
	end

	return additionalMass
end

function FillUnit:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_fillUnit

	for _, fillUnit in pairs(spec.fillUnits) do
		if fillUnit.fillRootNode ~= nil then
			list[fillUnit.fillRootNode] = self
		end

		if fillUnit.exactFillRootNode ~= nil then
			list[fillUnit.exactFillRootNode] = self
		end
	end
end

function FillUnit:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_fillUnit

	for _, fillUnit in pairs(spec.fillUnits) do
		if fillUnit.fillRootNode ~= nil then
			list[fillUnit.fillRootNode] = nil
		end

		if fillUnit.exactFillRootNode ~= nil then
			list[fillUnit.exactFillRootNode] = nil
		end
	end
end

function FillUnit:getFillLevelInformation(superFunc, fillLevelInformations)
	superFunc(self, fillLevelInformations)

	local spec = self.spec_fillUnit

	for _, fillUnit in pairs(spec.fillUnits) do
		if fillUnit.capacity > 0 and fillUnit.showOnHud then
			local fillType = fillUnit.fillType

			if fillUnit.fillTypeToDisplay ~= FillType.UNKNOWN then
				fillType = fillUnit.fillTypeToDisplay
			end

			local fillLevel = fillUnit.fillLevel

			if fillUnit.fillLevelToDisplay ~= nil then
				fillLevel = fillUnit.fillLevelToDisplay
			end

			local added = false

			for _, fillLevelInformation in pairs(fillLevelInformations) do
				if fillLevelInformation.fillType == fillType then
					fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + fillLevel
					fillLevelInformation.capacity = fillLevelInformation.capacity + fillUnit.capacity
					added = true

					break
				end
			end

			if not added then
				table.insert(fillLevelInformations, {
					fillType = fillType,
					fillLevel = fillLevel,
					capacity = fillUnit.capacity
				})
			end
		end
	end
end

function FillUnit:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_fillUnit

	if not spec.allowFoldingWhileFilled then
		for fillUnitIndex, _ in ipairs(spec.fillUnits) do
			if spec.allowFoldingThreshold < self:getFillUnitFillLevel(fillUnitIndex) then
				return false
			end
		end
	end

	return superFunc(self, direction, onAiTurnOn)
end

function FillUnit:getIsReadyForAutomatedTrainTravel(superFunc)
	local spec = self.spec_fillUnit

	for _, fillUnit in ipairs(spec.fillUnits) do
		if fillUnit.blocksAutomatedTrainTravel and fillUnit.fillLevel > 0 then
			return false
		end
	end

	return superFunc(self)
end

function FillUnit:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.fillUnitIndex = getXMLInt(xmlFile, key .. "#fillUnitIndex")
	entry.minFillLevel = getXMLFloat(xmlFile, key .. "#minFillLevel")
	entry.maxFillLevel = getXMLFloat(xmlFile, key .. "#maxFillLevel")

	return true
end

function FillUnit:getIsMovingToolActive(superFunc, movingTool)
	if movingTool.fillUnitIndex ~= nil then
		local fillLevelPct = self:getFillUnitFillLevelPercentage(movingTool.fillUnitIndex)

		if movingTool.minFillLevel < fillLevelPct or fillLevelPct < movingTool.maxFillLevel then
			return false
		end
	end

	return superFunc(self, movingTool)
end

function FillUnit:getDoConsumePtoPower(superFunc)
	local fillTrigger = self.spec_fillUnit.fillTrigger

	return superFunc(self) or fillTrigger.isFilling and fillTrigger.consumePtoPower
end

function FillUnit:getIsPowerTakeOffActive(superFunc)
	local fillTrigger = self.spec_fillUnit.fillTrigger

	return superFunc(self) or fillTrigger.isFilling and fillTrigger.consumePtoPower
end

function FillUnit:getCanBeTurnedOn(superFunc)
	local spec = self.spec_fillUnit

	for _, alarmTrigger in pairs(spec.activeAlarmTriggers) do
		if alarmTrigger.turnOffInTrigger then
			return false
		end
	end

	return superFunc(self)
end

function FillUnit.addFillTypeSources(sources, currentVehicle, excludeVehicle, fillTypes)
	if currentVehicle ~= excludeVehicle then
		local curVehicle = currentVehicle.spec_fillUnit

		if curVehicle ~= nil then
			for fillUnitIndex2, fillUnit2 in pairs(curVehicle.fillUnits) do
				for _, fillType in pairs(fillTypes) do
					if fillUnit2.supportedFillTypes[fillType] then
						if sources[fillType] == nil then
							sources[fillType] = {}
						end

						table.insert(sources[fillType], {
							vehicle = currentVehicle,
							fillUnitIndex = fillUnitIndex2
						})
					end
				end
			end
		end
	end

	if currentVehicle.getAttachedImplements ~= nil then
		local attachedImplements = currentVehicle:getAttachedImplements()

		for _, implement in pairs(attachedImplements) do
			if implement.object ~= nil then
				FillUnit.addFillTypeSources(sources, implement.object, excludeVehicle, fillTypes)
			end
		end
	end
end

function FillUnit.loadSpecValueCapacity(xmlFile, customEnvironment)
	local rootName = getXMLRootName(xmlFile)
	local fillUnitConfigurations = {}
	local overwrittenCapacity = getXMLFloat(xmlFile, rootName .. ".storeData.specs.capacity")
	local unit = getXMLString(xmlFile, rootName .. ".storeData.specs.capacity#unit")

	if overwrittenCapacity ~= nil and unit ~= nil then
		table.insert(fillUnitConfigurations, {
			{
				capacity = overwrittenCapacity,
				unit = unit
			}
		})

		return fillUnitConfigurations
	end

	local i = 0

	while true do
		local key = string.format(rootName .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local fillUnitConfiguration = {}
		local j = 0

		while true do
			local fillUnitKey = string.format(key .. ".fillUnits.fillUnit(%d)", j)

			if not hasXMLProperty(xmlFile, fillUnitKey) then
				break
			end

			local capacity = getXMLFloat(xmlFile, fillUnitKey .. "#capacity") or 0
			local unit = getXMLString(xmlFile, fillUnitKey .. "#unit")

			if getXMLBool(xmlFile, fillUnitKey .. "#showCapacityInShop") ~= false and getXMLBool(xmlFile, fillUnitKey .. "#showInShop") ~= false then
				table.insert(fillUnitConfiguration, {
					capacity = capacity,
					unit = unit
				})
			end

			j = j + 1
		end

		table.insert(fillUnitConfigurations, fillUnitConfiguration)

		i = i + 1
	end

	return fillUnitConfigurations
end

function FillUnit.getSpecValueCapacity(storeItem, realItem, returnValues, configurations)
	local configurationIndex = 1

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil then
		configurationIndex = realItem.configurations.fillUnit
	elseif configurations ~= nil and storeItem.configurations ~= nil and configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil then
		configurationIndex = configurations.fillUnit
	end

	local capacity = 0
	local unit = ""
	local fillUnitConfigurations = storeItem.specs.capacity

	if fillUnitConfigurations ~= nil then
		if realItem ~= nil or configurations ~= nil then
			if fillUnitConfigurations[configurationIndex] ~= nil then
				for _, fillUnit in ipairs(fillUnitConfigurations[configurationIndex]) do
					capacity = capacity + fillUnit.capacity
					unit = fillUnit.unit
				end
			end
		else
			for _, configuration in ipairs(fillUnitConfigurations) do
				local configCapacity = 0

				for _, fillUnit in ipairs(configuration) do
					configCapacity = configCapacity + fillUnit.capacity
					unit = fillUnit.unit
				end

				capacity = math.max(capacity, configCapacity)
			end
		end
	end

	if capacity == 0 and (returnValues == nil or not returnValues) then
		return nil
	end

	if unit ~= "" and unit:sub(1, 6) == "$l10n_" then
		unit = unit:sub(7)
	end

	if returnValues == nil or not returnValues then
		return string.format(g_i18n:getText("shop_capacityValue"), capacity, g_i18n:getText(unit or "unit_literShort"))
	else
		return capacity, unit
	end
end

function FillUnit.loadSpecValueFillTypes(xmlFile, customEnvironment)
	local fillTypeNames, fillTypeCategoryNames, fillTypes, fruitTypeNames = nil
	local rootName = getXMLRootName(xmlFile)
	local i = 0

	while true do
		local key = string.format(rootName .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local j = 0

		while true do
			local unitKey = string.format(key .. ".fillUnits.fillUnit(%d)", j)

			if not hasXMLProperty(xmlFile, unitKey) then
				break
			end

			local showInShop = getXMLBool(xmlFile, unitKey .. "#showInShop")
			local capacity = getXMLFloat(xmlFile, unitKey .. "#capacity")

			if (showInShop == nil or showInShop) and (capacity == nil or capacity > 0) then
				local currentFillTypes = getXMLString(xmlFile, unitKey .. "#fillTypes")

				if currentFillTypes ~= nil then
					if fillTypeNames == nil then
						fillTypeNames = currentFillTypes
					else
						fillTypeNames = fillTypeNames .. " " .. currentFillTypes
					end
				end

				local currentFillTypeCategories = getXMLString(xmlFile, unitKey .. "#fillTypeCategories")

				if currentFillTypeCategories ~= nil then
					if fillTypeCategoryNames == nil then
						fillTypeCategoryNames = currentFillTypeCategories
					else
						fillTypeCategoryNames = fillTypeCategoryNames .. " " .. currentFillTypeCategories
					end
				end
			end

			j = j + 1
		end

		i = i + 1
	end

	if fillTypeNames == nil then
		fillTypeNames = getXMLString(xmlFile, rootName .. ".fillTypes")
	end

	fillTypeNames = Utils.getNoNil(getXMLString(xmlFile, rootName .. ".storeData.specs.fillTypes"), fillTypeNames)

	if fillTypeNames ~= nil then
		fillTypeCategoryNames = nil
	end

	if fillTypeCategoryNames == nil then
		fillTypeCategoryNames = getXMLString(xmlFile, rootName .. ".fillTypeCategories")
	end

	if fillTypes == nil then
		fruitTypeNames = getXMLString(xmlFile, rootName .. ".fruitTypes")
	end

	if fillTypes == nil then
		fruitTypeNames = getXMLString(xmlFile, rootName .. ".cutter#fruitTypes")
	end

	local fruitTypeCategoryNames = getXMLString(xmlFile, rootName .. ".cutter#fruitTypeCategories")
	local useWindrowed = Utils.getNoNil(getXMLBool(xmlFile, rootName .. ".cutter#useWindrowed"), false)
	fillTypeCategoryNames = Utils.getNoNil(getXMLString(xmlFile, rootName .. ".storeData.specs.fillTypeCategories"), fillTypeCategoryNames)

	return {
		categoryNames = fillTypeCategoryNames,
		fillTypeNames = fillTypeNames,
		fruitTypeNames = fruitTypeNames,
		fruitTypeCategoryNames = fruitTypeCategoryNames,
		useWindrowed = useWindrowed
	}
end

function FillUnit.getSpecValueFillTypes(storeItem, realItem)
	local specs = storeItem.specs.fillTypes

	if specs ~= nil then
		if specs.categoryNames ~= nil then
			return g_fillTypeManager:getFillTypesByCategoryNames(specs.categoryNames, nil)
		elseif specs.fillTypeNames ~= nil then
			return g_fillTypeManager:getFillTypesByNames(specs.fillTypeNames, nil)
		elseif specs.fruitTypeNames ~= nil then
			return g_fruitTypeManager:getFillTypesByFruitTypeNames(specs.fruitTypeNames, nil)
		elseif specs.fruitTypeCategoryNames ~= nil then
			if specs.useWindrowed then
				local fruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames(specs.fruitTypeCategoryNames, "Warning: Cutter has invalid fruitTypeCategory '%s'.")
				local windrowFillTypes = {}

				for _, fruitType in pairs(fruitTypes) do
					table.insert(windrowFillTypes, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitType))
				end

				return windrowFillTypes
			else
				return g_fruitTypeManager:getFillTypesByFruitTypeCategoryName(specs.fruitTypeCategoryNames, nil)
			end
		end
	end

	return nil
end

function FillUnit:actionEventConsoleFillUnitNext(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local fillType = self:getFillUnitFillType(1)
		local fillUnit = self:getFillUnitByIndex(1)
		local found = false
		local nextFillType = nil

		for supportedFillType, _ in pairs(fillUnit.supportedFillTypes) do
			if not found then
				if supportedFillType == fillType then
					found = true
				end
			else
				nextFillType = supportedFillType

				break
			end
		end

		if nextFillType == nil then
			nextFillType = next(fillUnit.supportedFillTypes)
		end

		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, -math.huge, fillType, ToolType.UNDEFINED, nil)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, 100, nextFillType, ToolType.UNDEFINED, nil)
	end
end

function FillUnit:actionEventConsoleFillUnitInc(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local fillType = self:getFillUnitFillType(1)

		if fillType == FillType.UNKNOWN then
			local fillUnit = self:getFillUnitByIndex(1)
			fillType = next(fillUnit.supportedFillTypes)
		end

		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, 1000, fillType, ToolType.UNDEFINED, nil)
	end
end

function FillUnit:actionEventConsoleFillUnitDec(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSelected() then
		local fillType = self:getFillUnitFillType(1)

		self:addFillUnitFillLevel(self:getOwnerFarmId(), 1, -1000, fillType, ToolType.UNDEFINED, nil)
	end
end

function FillUnit:actionEventUnload(actionName, inputValue, callbackState, isAnalog)
	self:unloadFillUnits()
end

function FillUnit:updateUnloadActionDisplay()
	local spec = self.spec_fillUnit

	if spec.unloading ~= nil then
		local isActive = false

		for k, fillUnit in ipairs(self:getFillUnits()) do
			local fillLevel = self:getFillUnitFillLevel(k)
			local fillTypeIndex = self:getFillUnitFillType(k)
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			if fillUnit.canBeUnloaded and fillLevel > 0 and fillType.palletFilename ~= nil then
				isActive = true

				break
			end
		end

		g_inputBinding:setActionEventActive(spec.unloadActionEventId, isActive)
	end
end

FillActivatable = {}
local FillActivatable_mt = Class(FillActivatable)

function FillActivatable:new(vehicle)
	local self = {}

	setmetatable(self, FillActivatable_mt)

	self.vehicle = vehicle
	self.fillTypeIndex = FillType.UNKNOWN
	self.activateText = "unknown"

	return self
end

function FillActivatable:getIsActivatable()
	if self.vehicle:getIsActiveForInput(true) then
		local fillUnitIndex = self.vehicle:getFirstValidFillUnitToFill(self.fillTypeIndex)

		if fillUnitIndex ~= nil then
			local enoughSpace = self.vehicle:getFillUnitFillLevel(fillUnitIndex) < self.vehicle:getFillUnitCapacity(fillUnitIndex) - 1
			local allowsFilling = self.vehicle:getFillUnitAllowsFillType(fillUnitIndex, self.fillTypeIndex)

			if enoughSpace and allowsFilling then
				local spec = self.vehicle.spec_fillUnit

				for _, trigger in ipairs(spec.fillTrigger.triggers) do
					if trigger:getIsActivatable(self.vehicle) then
						self:updateActivateText(spec.fillTrigger.isFilling)

						return true
					end
				end
			end
		end
	end

	return false
end

function FillActivatable:onActivateObject()
	local spec = self.vehicle.spec_fillUnit

	self.vehicle:setFillUnitIsFilling(not spec.fillTrigger.isFilling)
	self:updateActivateText(spec.fillTrigger.isFilling)
	g_currentMission:addActivatableObject(self)
end

function FillActivatable:drawActivate()
	if self.fillTypeIndex == FillType.FUEL then
		g_currentMission:showFuelContext(self.vehicle)
	end
end

function FillActivatable:updateActivateText(isFilling)
	if isFilling then
		self.activateText = string.format(g_i18n:getText("action_stopRefillingOBJECT"), self.vehicle.typeDesc)
	else
		self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.vehicle.typeDesc)
	end
end

function FillActivatable:setFillType(fillTypeIndex)
	self.fillTypeIndex = fillTypeIndex
end
