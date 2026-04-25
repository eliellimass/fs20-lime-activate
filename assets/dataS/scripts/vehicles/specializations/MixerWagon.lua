source("dataS/scripts/vehicles/specializations/events/MixerWagonBaleNotAcceptedEvent.lua")

MixerWagon = {}

source("dataS/scripts/gui/hud/MixerWagonHUDExtension.lua")

function MixerWagon.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Trailer, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end

function MixerWagon.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "mixerWagonBaleTriggerCallback", MixerWagon.mixerWagonBaleTriggerCallback)
end

function MixerWagon.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", MixerWagon.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", MixerWagon.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeFillType", MixerWagon.getDischargeFillType)
end

function MixerWagon.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", MixerWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", MixerWagon)
end

function MixerWagon:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonBaleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagon.baleTrigger#index", "vehicle.mixerWagon.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonPickupStartSound", "vehicle.turnOnVehicle.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonPickupStopSound", "vehicle.turnOnVehicle.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonPickupSound", "vehicle.turnOnVehicle.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.mixAnimationNodes.animationNode", "mixerWagonMix")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonRotatingParts.mixerWagonRotatingPart#type", "vehicle.mixerWagon.pickupAnimationNodes.animationNode", "mixerWagonPickup")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.mixerWagonRotatingParts.mixerWagonScroller", "vehicle.mixerWagon.pickupAnimationNodes.pickupAnimationNode")

	local spec = self.spec_mixerWagon

	if self.isClient then
		spec.mixAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.mixAnimationNodes", self.components, self, self.i3dMappings)
		spec.pickupAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.mixerWagon.pickupAnimationNodes", self.components, self, self.i3dMappings)
	end

	if self.isServer then
		spec.baleTriggerNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.mixerWagon.baleTrigger#node"), self.i3dMappings)

		if spec.baleTriggerNode ~= nil then
			addTrigger(spec.baleTriggerNode, "mixerWagonBaleTriggerCallback", self)
		end
	end

	spec.activeTimerMax = 5000
	spec.activeTimer = 0
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.mixerWagon#fillUnitIndex"), 1)
	local fillUnit = self:getFillUnitByIndex(spec.fillUnitIndex)

	if fillUnit ~= nil then
		fillUnit.needsSaving = false

		if fillUnit.supportedFillTypes[FillType.GRASS_WINDROW] then
			fillUnit.supportedFillTypes[FillType.GRASS_WINDROW] = nil
		end
	end

	fillUnit.synchronizeFillLevel = false
	spec.mixerWagonFillTypes = {}
	spec.fillTypeToMixerWagonFillType = {}
	local sumRatio = 0
	local i = 0

	while true do
		local baseName = string.format("vehicle.mixerWagon.mixerWagonFillTypes.mixerWagonFillType(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local entry = {
			fillTypes = {}
		}
		local j = 0

		while true do
			local fillTypeKey = baseName .. string.format(".fillType(%d)", j)

			if not hasXMLProperty(self.xmlFile, fillTypeKey) then
				break
			end

			local fillTypeStr = getXMLString(self.xmlFile, fillTypeKey .. "#fillType")

			if fillTypeStr ~= nil then
				local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

				if fillTypeIndex ~= nil and fillTypeIndex ~= FillType.GRASS_WINDROW then
					if spec.fillTypeToMixerWagonFillType[fillTypeIndex] == nil then
						entry.fillTypes[fillTypeIndex] = true
						spec.fillTypeToMixerWagonFillType[fillTypeIndex] = entry
					else
						g_logManager:xmlWarning(self.configFileName, "MixerWagonFillType '%s' in '%s' already used! Ignoring it!", fillTypeKey, fillTypeStr)
					end
				else
					g_logManager:xmlWarning(self.configFileName, "FillType '%s' not defined for mixerWagonFillType '%s'!", fillTypeStr, fillTypeKey)
				end
			end

			j = j + 1
		end

		entry.name = Utils.getNoNil(getXMLString(self.xmlFile, baseName .. "#name"), "unknown")
		entry.minPercentage = Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. "#minPercentage"), 0) * 0.01
		entry.maxPercentage = Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. "#maxPercentage"), 100) * 0.01
		entry.ratio = entry.maxPercentage - entry.minPercentage
		entry.fillLevel = 0

		if next(entry.fillTypes) ~= nil then
			sumRatio = sumRatio + entry.ratio

			table.insert(spec.mixerWagonFillTypes, entry)
		end

		i = i + 1
	end

	for i, entry in ipairs(spec.mixerWagonFillTypes) do
		entry.ratio = entry.ratio / sumRatio
	end

	spec.dirtyFlag = self:getNextDirtyFlag()

	if savegame ~= nil then
		for i, entry in ipairs(spec.mixerWagonFillTypes) do
			local fillTypeKey = savegame.key .. string.format(".mixerWagon.fillType(%d)#fillLevel", i - 1)
			local fillLevel = Utils.getNoNil(getXMLFloat(savegame.xmlFile, fillTypeKey), 0)

			if fillLevel > 0 then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, fillLevel, next(entry.fillTypes), ToolType.UNDEFINED, nil)
			end
		end
	end
end

function MixerWagon:onDelete()
	local spec = self.spec_mixerWagon

	if self.isServer and spec.baleTriggerNode ~= nil then
		removeTrigger(spec.baleTriggerNode)
	end

	if self.isClient then
		g_animationManager:deleteAnimations(spec.mixAnimationNodes)
		g_animationManager:deleteAnimations(spec.pickupAnimationNodes)
	end
end

function MixerWagon:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_mixerWagon

	for i, fillType in ipairs(spec.mixerWagonFillTypes) do
		local fillTypeKey = string.format("%s.fillType(%d)", key, i - 1)

		setXMLFloat(xmlFile, fillTypeKey .. "#fillLevel", fillType.fillLevel)
	end
end

function MixerWagon:onReadStream(streamId, connection)
	local spec = self.spec_mixerWagon

	for _, entry in ipairs(spec.mixerWagonFillTypes) do
		local fillLevel = streamReadFloat32(streamId)

		if fillLevel > 0 then
			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, fillLevel, next(entry.fillTypes), ToolType.UNDEFINED, nil)
		end
	end
end

function MixerWagon:onWriteStream(streamId, connection)
	local spec = self.spec_mixerWagon

	for _, entry in ipairs(spec.mixerWagonFillTypes) do
		streamWriteFloat32(streamId, entry.fillLevel)
	end
end

function MixerWagon:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_mixerWagon

		for _, entry in ipairs(spec.mixerWagonFillTypes) do
			local fillLevel = streamReadFloat32(streamId)
			local delta = fillLevel - entry.fillLevel

			if delta ~= 0 then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, next(entry.fillTypes), ToolType.UNDEFINED, nil)
			end
		end
	end
end

function MixerWagon:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_mixerWagon

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for _, entry in ipairs(spec.mixerWagonFillTypes) do
				streamWriteFloat32(streamId, entry.fillLevel)
			end
		end
	end
end

function MixerWagon:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_mixerWagon
	local tipState = self:getTipState()
	local isTurnedOn = self:getIsTurnedOn()
	local isDischarging = tipState == Trailer.TIPSTATE_OPENING or tipState == Trailer.TIPSTATE_OPEN

	if spec.activeTimer > 0 or isTurnedOn or isDischarging then
		spec.activeTimer = spec.activeTimer - dt

		g_animationManager:startAnimations(spec.mixAnimationNodes)
	else
		g_animationManager:stopAnimations(spec.mixAnimationNodes)
	end
end

function MixerWagon:mixerWagonBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter and otherActorId ~= 0 then
		local bale = g_currentMission:getNodeObject(otherActorId)

		if bale ~= nil and bale:isa(Bale) then
			local spec = self.spec_mixerWagon
			local fillLevel = bale:getFillLevel()
			local fillTypeIndex = bale:getFillType()

			if self:getFillUnitSupportsFillType(spec.fillUnitIndex, fillTypeIndex) and self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, fillLevel, fillTypeIndex, ToolType.BALE, nil)
				bale:delete()

				spec.activeTimer = spec.activeTimerMax

				self:raiseDirtyFlags(spec.dirtyFlag)
			else
				if self.isClient then
					g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("warning_baleNotSupported"))
				end

				g_server:broadcastEvent(MixerWagonBaleNotAcceptedEvent:new(self), nil, , self)
			end
		end
	end
end

function MixerWagon:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local spec = self.spec_mixerWagon

	if fillUnitIndex ~= spec.fillUnitIndex then
		return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	end

	local oldFillLevel = self:getFillUnitFillLevel(fillUnitIndex)
	local mixerWagonFillType = spec.fillTypeToMixerWagonFillType[fillTypeIndex]

	if fillTypeIndex == FillType.FORAGE and fillLevelDelta > 0 then
		for _, entry in pairs(spec.mixerWagonFillTypes) do
			local delta = fillLevelDelta * entry.ratio

			self:addFillUnitFillLevel(farmId, fillUnitIndex, delta, next(entry.fillTypes), toolType, fillPositionData)
		end

		return fillLevelDelta
	end

	if mixerWagonFillType == nil then
		if fillLevelDelta < 0 and oldFillLevel > 0 then
			fillLevelDelta = math.max(fillLevelDelta, -oldFillLevel)
			local newFillLevel = 0

			for _, entry in pairs(spec.mixerWagonFillTypes) do
				local entryDelta = fillLevelDelta * entry.fillLevel / oldFillLevel
				entry.fillLevel = math.max(entry.fillLevel + entryDelta, 0)
				newFillLevel = newFillLevel + entry.fillLevel
			end

			if newFillLevel < 0.1 then
				for _, entry in pairs(spec.mixerWagonFillTypes) do
					entry.fillLevel = 0
				end

				fillLevelDelta = -oldFillLevel
			end

			self:raiseDirtyFlags(spec.dirtyFlag)

			local ret = superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)

			return ret
		end

		return 0
	end

	local capacity = self:getFillUnitCapacity(fillUnitIndex)
	local free = capacity - oldFillLevel

	if fillLevelDelta > 0 then
		mixerWagonFillType.fillLevel = mixerWagonFillType.fillLevel + math.min(free, fillLevelDelta)
		spec.activeTimer = spec.activeTimerMax
	else
		mixerWagonFillType.fillLevel = math.max(0, mixerWagonFillType.fillLevel + fillLevelDelta)
	end

	local newFillLevel = 0

	for _, mixerWagonFillType in pairs(spec.mixerWagonFillTypes) do
		newFillLevel = newFillLevel + mixerWagonFillType.fillLevel
	end

	newFillLevel = MathUtil.clamp(newFillLevel, 0, self:getFillUnitCapacity(fillUnitIndex))
	local newFillType = FillType.UNKNOWN
	local isSingleFilled = false
	local isForageOk = false

	for _, mixerWagonFillType in pairs(spec.mixerWagonFillTypes) do
		if newFillLevel == mixerWagonFillType.fillLevel then
			isSingleFilled = true
			newFillType = next(mixerWagonFillType.fillTypes)

			break
		end
	end

	if not isSingleFilled then
		isForageOk = true

		for _, mixerWagonFillType in pairs(spec.mixerWagonFillTypes) do
			if mixerWagonFillType.fillLevel < mixerWagonFillType.minPercentage * newFillLevel - 0.01 or mixerWagonFillType.fillLevel > mixerWagonFillType.maxPercentage * newFillLevel + 0.01 then
				isForageOk = false

				break
			end
		end
	end

	if isForageOk then
		newFillType = FillType.FORAGE
	elseif not isSingleFilled then
		newFillType = FillType.FORAGE_MIXING
	end

	self:raiseDirtyFlags(spec.dirtyFlag)
	self:setFillUnitFillType(fillUnitIndex, newFillType)

	return superFunc(self, farmId, fillUnitIndex, newFillLevel - oldFillLevel, newFillType, toolType, fillPositionData)
end

function MixerWagon:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillTypeIndex)
	local spec = self.spec_mixerWagon

	if spec.fillUnitIndex == fillUnitIndex then
		local mixerWagonFillType = spec.fillTypeToMixerWagonFillType[fillTypeIndex]

		if mixerWagonFillType ~= nil then
			return true
		end
	end

	return superFunc(self, fillUnitIndex, fillTypeIndex)
end

function MixerWagon:getDischargeFillType(superFunc, dischargeNode)
	local spec = self.spec_mixerWagon
	local fillUnitIndex = dischargeNode.fillUnitIndex

	if fillUnitIndex == spec.fillUnitIndex then
		local currentFillType = self:getFillUnitFillType(fillUnitIndex)
		local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

		if currentFillType == FillType.FORAGE_MIXING and fillLevel > 0 then
			for _, entry in pairs(spec.mixerWagonFillTypes) do
				if entry.fillLevel > 0 then
					currentFillType = next(entry.fillTypes)

					break
				end
			end
		end

		return currentFillType
	end

	return superFunc(self, dischargeNode)
end

function MixerWagon:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_mixerWagon

	if spec.fillUnitIndex == fillUnitIndex then
		local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

		if fillLevel == 0 then
			for _, entry in pairs(spec.mixerWagonFillTypes) do
				entry.fillLevel = 0
			end
		end
	end
end

function MixerWagon:onTurnedOn()
	if self.isClient then
		local spec = self.spec_mixerWagon

		g_animationManager:startAnimations(spec.pickupAnimationNodes)
	end
end

function MixerWagon:onTurnedOff()
	if self.isClient then
		local spec = self.spec_mixerWagon

		g_animationManager:stopAnimations(spec.pickupAnimationNodes)
	end
end

function MixerWagon:updateDebugValues(values)
	local spec = self.spec_mixerWagon

	table.insert(values, {
		name = "Forage isOK",
		value = tostring(self:getFillUnitFillType(spec.fillUnitIndex) == FillType.FORAGE)
	})

	for _, mixerWagonFillType in ipairs(spec.mixerWagonFillTypes) do
		local fillTypes = ""

		for fillTypeIndex, _ in pairs(mixerWagonFillType.fillTypes) do
			fillTypes = fillTypes .. " " .. tostring(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
		end

		table.insert(values, {
			name = fillTypes,
			value = mixerWagonFillType.fillLevel
		})
	end
end
