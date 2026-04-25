source("dataS/scripts/vehicles/specializations/events/SetDischargeStateEvent.lua")

Dischargeable = {
	DISCHARGE_STATE_OFF = 0,
	DISCHARGE_STATE_OBJECT = 1,
	DISCHARGE_STATE_GROUND = 2,
	DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED = 1,
	DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED = 2,
	DISCHARGE_REASON_NO_FREE_CAPACITY = 3,
	DISCHARGE_WARNINGS = {}
}
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED] = "warning_notAcceptedHere"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED] = "warning_notAcceptedTool"
Dischargeable.DISCHARGE_WARNINGS[Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY] = "warning_noMoreFreeCapacity"

function Dischargeable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(FillVolume, specializations)
end

function Dischargeable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDischargeNode", Dischargeable.loadDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentDischargeNodeIndex", Dischargeable.setCurrentDischargeNodeIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentDischargeNode", Dischargeable.getCurrentDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeTargetObject", Dischargeable.getDischargeTargetObject)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentDischargeObject", Dischargeable.getCurrentDischargeObject)
	SpecializationUtil.registerFunction(vehicleType, "discharge", Dischargeable.discharge)
	SpecializationUtil.registerFunction(vehicleType, "dischargeToGround", Dischargeable.dischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "dischargeToObject", Dischargeable.dischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeState", Dischargeable.setDischargeState)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeState", Dischargeable.getDischargeState)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeFillType", Dischargeable.getDischargeFillType)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToGround", Dischargeable.getCanDischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeAtPosition", Dischargeable.getCanDischargeAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToLand", Dischargeable.getCanDischargeToLand)
	SpecializationUtil.registerFunction(vehicleType, "getCanDischargeToObject", Dischargeable.getCanDischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNotAllowedWarning", Dischargeable.getDischargeNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleDischargeToObject", Dischargeable.getCanToggleDischargeToObject)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleDischargeToGround", Dischargeable.getCanToggleDischargeToGround)
	SpecializationUtil.registerFunction(vehicleType, "getIsDischargeNodeActive", Dischargeable.getIsDischargeNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeEmptyFactor", Dischargeable.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeByNode", Dischargeable.getDischargeNodeByNode)
	SpecializationUtil.registerFunction(vehicleType, "updateRaycast", Dischargeable.updateRaycast)
	SpecializationUtil.registerFunction(vehicleType, "updateDischargeInfo", Dischargeable.updateDischargeInfo)
	SpecializationUtil.registerFunction(vehicleType, "raycastCallbackDischargeNode", Dischargeable.raycastCallbackDischargeNode)
	SpecializationUtil.registerFunction(vehicleType, "finishDischargeRaycast", Dischargeable.finishDischargeRaycast)
	SpecializationUtil.registerFunction(vehicleType, "getDischargeNodeByIndex", Dischargeable.getDischargeNodeByIndex)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeOnEmpty", Dischargeable.handleDischargeOnEmpty)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeNodeChanged", Dischargeable.handleDischargeNodeChanged)
	SpecializationUtil.registerFunction(vehicleType, "handleDischarge", Dischargeable.handleDischarge)
	SpecializationUtil.registerFunction(vehicleType, "handleDischargeRaycast", Dischargeable.handleDischargeRaycast)
	SpecializationUtil.registerFunction(vehicleType, "handleFoundDischargeObject", Dischargeable.handleFoundDischargeObject)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeEffectDistance", Dischargeable.setDischargeEffectDistance)
	SpecializationUtil.registerFunction(vehicleType, "setDischargeEffectActive", Dischargeable.setDischargeEffectActive)
	SpecializationUtil.registerFunction(vehicleType, "updateDischargeSound", Dischargeable.updateDischargeSound)
	SpecializationUtil.registerFunction(vehicleType, "dischargeTriggerCallback", Dischargeable.dischargeTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteDischargeTriggerObject", Dischargeable.onDeleteDischargeTriggerObject)
	SpecializationUtil.registerFunction(vehicleType, "dischargeActivationTriggerCallback", Dischargeable.dischargeActivationTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteActivationTriggerObject", Dischargeable.onDeleteActivationTriggerObject)
	SpecializationUtil.registerFunction(vehicleType, "setForcedFillTypeIndex", Dischargeable.setForcedFillTypeIndex)
end

function Dischargeable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresTipOcclusionArea", Dischargeable.getRequiresTipOcclusionArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Dischargeable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Dischargeable.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", Dischargeable.getIsPowerTakeOffActive)
end

function Dischargeable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onDischargeStateChanged")
end

function Dischargeable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Dischargeable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Dischargeable)
end

function Dischargeable:onLoad(savegame)
	local spec = self.spec_dischargeable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipeEffect", "vehicle.dischargeable.dischargeNode.effects")

	spec.dischargeNodes = {}
	spec.fillUnitDischargeNodeMapping = {}
	spec.dischargNodeMapping = {}
	spec.triggerToDischargeNode = {}
	spec.activationTriggerToDischargeNode = {}
	spec.requiresTipOcclusionArea = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.dischargeable#requiresTipOcclusionArea"), true)
	spec.stopDischargeOnDeactivate = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.dischargeable#stopDischargeOnDeactivate"), true)
	spec.dischargedLiters = 0
	local i = 0

	while true do
		local key = string.format("vehicle.dischargeable.dischargeNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadDischargeNode(self.xmlFile, key, entry) then
			local canBeAdded = true

			if spec.dischargNodeMapping[entry.node] ~= nil then
				g_logManager:xmlWarning(self.configFileName, "DischargeNode '%s' already defined. Discharge nodes need to be unique. Ignoring it!", getName(entry.node))

				canBeAdded = false
			end

			if entry.trigger.node ~= nil and spec.triggerToDischargeNode[entry.trigger.node] ~= nil then
				g_logManager:xmlWarning(self.configFileName, "DischargeNode trigger '%s' already defined. DischargeNode triggers need to be unique. Ignoring it!", getName(entry.trigger.node))

				canBeAdded = false
			end

			if entry.activationTrigger.node ~= nil and spec.activationTriggerToDischargeNode[entry.activationTrigger.node] ~= nil then
				g_logManager:xmlWarning(self.configFileName, "DischargeNode activationTrigger '%s' already defined. DischargeNode activationTriggers need to be unique. Ignoring it!", getName(entry.activationTrigger.node))

				canBeAdded = false
			end

			if canBeAdded then
				table.insert(spec.dischargeNodes, entry)

				entry.index = #spec.dischargeNodes
				spec.fillUnitDischargeNodeMapping[entry.fillUnitIndex] = entry
				spec.dischargNodeMapping[entry.node] = entry

				if entry.trigger.node ~= nil then
					spec.triggerToDischargeNode[entry.trigger.node] = entry
				end

				if entry.activationTrigger.node ~= nil then
					spec.activationTriggerToDischargeNode[entry.activationTrigger.node] = entry
				end
			end
		end

		i = i + 1
	end

	spec.currentDischargeState = Dischargeable.DISCHARGE_STATE_OFF
	spec.currentRaycast = nil
	spec.forcedFillTypeIndex = nil
	spec.isAsyncRaycastActive = false
	spec.currentRaycast = {}

	self:setCurrentDischargeNodeIndex(1)

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Dischargeable:onDelete()
	local spec = self.spec_dischargeable

	for _, dischargeNode in ipairs(spec.dischargeNodes) do
		g_effectManager:deleteEffects(dischargeNode.effects)

		if self.isClient then
			g_soundManager:deleteSample(dischargeNode.sample)
		end

		if dischargeNode.trigger.node ~= nil then
			removeTrigger(dischargeNode.trigger.node)
		end

		if dischargeNode.activationTrigger.node ~= nil then
			removeTrigger(dischargeNode.activationTrigger.node)
		end
	end
end

function Dischargeable:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_dischargeable

		for _, dischargeNode in ipairs(spec.dischargeNodes) do
			if streamReadBool(streamId) then
				local distance = streamReadUIntN(streamId, 8) * dischargeNode.maxDistance / 255
				dischargeNode.dischargeDistance = distance

				self:setDischargeEffectActive(dischargeNode, true)
				self:setDischargeEffectDistance(dischargeNode, distance)
			else
				self:setDischargeEffectActive(dischargeNode, false)
			end
		end
	end
end

function Dischargeable:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_dischargeable

		for _, dischargeNode in ipairs(spec.dischargeNodes) do
			if streamWriteBool(streamId, dischargeNode.isEffectActiveSent) then
				streamWriteUIntN(streamId, MathUtil.clamp(math.floor(dischargeNode.dischargeDistanceSent / dischargeNode.maxDistance * 255), 1, 255), 8)
			end
		end
	end
end

function Dischargeable:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_dischargeable

		if streamReadBool(streamId) then
			for _, dischargeNode in ipairs(spec.dischargeNodes) do
				if streamReadBool(streamId) then
					local distance = streamReadUIntN(streamId, 8) * dischargeNode.maxDistance / 255
					dischargeNode.dischargeDistance = distance

					self:setDischargeEffectActive(dischargeNode, true)
					self:setDischargeEffectDistance(dischargeNode, distance)
				else
					self:setDischargeEffectActive(dischargeNode, false)
				end
			end
		end
	end
end

function Dischargeable:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_dischargeable

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for _, dischargeNode in ipairs(spec.dischargeNodes) do
				if streamWriteBool(streamId, dischargeNode.isEffectActiveSent) then
					streamWriteUIntN(streamId, MathUtil.clamp(math.floor(dischargeNode.dischargeDistanceSent / dischargeNode.maxDistance * 255), 1, 255), 8)
				end
			end
		end
	end
end

function Dischargeable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_dischargeable
	local dischargeNode = spec.currentDischargeNode

	if dischargeNode ~= nil and (dischargeNode.activationTrigger.numObjects > 0 or spec.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF) then
		self:raiseActive()
	end
end

function Dischargeable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_dischargeable
	local dischargeNode = spec.currentDischargeNode

	if dischargeNode ~= nil then
		if self.isClient then
			Dischargeable.updateActionEvents(self)
		end

		if self:getIsDischargeNodeActive(dischargeNode) then
			local trigger = dischargeNode.trigger

			if trigger.numObjects > 0 then
				dischargeNode.dischargeObject = nil
				dischargeNode.dischargeHitTerrain = false
				dischargeNode.dischargeShape = nil
				dischargeNode.dischargeDistance = 0
				dischargeNode.dischargeFillUnitIndex = nil
				dischargeNode.dischargeHit = false
				local nearestDistance = math.huge

				for object, data in pairs(trigger.objects) do
					local fillType = spec.forcedFillTypeIndex

					if fillType == nil then
						fillType = self:getDischargeFillType(dischargeNode)
					end

					dischargeNode.dischargeFailedReason = nil
					dischargeNode.dischargeFailedReasonShowAuto = false
					dischargeNode.customNotAllowedWarning = nil

					if object:getFillUnitSupportsFillType(data.fillUnitIndex, fillType) then
						local allowFillType = object:getFillUnitAllowsFillType(data.fillUnitIndex, fillType)
						local allowToolType = object:getFillUnitSupportsToolType(data.fillUnitIndex, ToolType.TRIGGER)
						local freeSpace = object:getFillUnitFreeCapacity(data.fillUnitIndex, fillType, self:getActiveFarm()) > 0

						if allowFillType and allowToolType and freeSpace then
							local exactFillRootNode = object:getFillUnitExactFillRootNode(data.fillUnitIndex)

							if exactFillRootNode ~= nil and entityExists(exactFillRootNode) then
								local distance = calcDistanceFrom(dischargeNode.node, exactFillRootNode)

								if distance < nearestDistance then
									dischargeNode.dischargeObject = object
									dischargeNode.dischargeHitTerrain = false
									dischargeNode.dischargeShape = data.shape
									dischargeNode.dischargeDistance = distance
									dischargeNode.dischargeFillUnitIndex = data.fillUnitIndex
									nearestDistance = distance
								end
							end
						elseif not allowFillType then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
						elseif not allowToolType then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED
						elseif not freeSpace then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY
						end
					elseif fillType ~= FillType.UNKNOWN then
						dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
					end

					if (dischargeNode.dischargeFailedReason == Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED or dischargeNode.dischargeFailedReason == Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY) and (object.isa == nil or not object:isa(Vehicle)) then
						dischargeNode.dischargeFailedReasonShowAuto = true
					end

					if dischargeNode.dischargeFailedReason ~= nil and dischargeNode.dischargeFailedReason ~= Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED and object.getCustomDischargeNotAllowedWarning ~= nil then
						dischargeNode.customNotAllowedWarning = object:getCustomDischargeNotAllowedWarning()
					end

					dischargeNode.dischargeHit = true
				end
			elseif not spec.isAsyncRaycastActive then
				self:updateRaycast(dischargeNode)
			end
		else
			if spec.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
			end

			dischargeNode.dischargeObject = nil
			dischargeNode.dischargeHitTerrain = false
			dischargeNode.dischargeShape = nil
			dischargeNode.dischargeDistance = 0
			dischargeNode.dischargeFillUnitIndex = nil
			dischargeNode.dischargeHit = false
		end

		self:updateDischargeSound(dischargeNode, dt)

		if self.isServer then
			if VehicleDebug.state == VehicleDebug.DEBUG then
				local info = dischargeNode.info
				local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
				local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

				drawDebugLine(sx, sy + info.yOffset, sz, 1, 0, 0, ex, ey + info.yOffset, ez, 1, 0, 0)
			end

			if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
				if dischargeNode.dischargeObject ~= nil then
					self:handleFoundDischargeObject(dischargeNode)
				end
			else
				local fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
				local emptySpeed = self:getDischargeNodeEmptyFactor(dischargeNode)
				local canDischargeToObject = self:getCanDischargeToObject(dischargeNode) and spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT
				local canDischargeToGround = self:getCanDischargeToGround(dischargeNode) and spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND
				local canDischarge = canDischargeToObject or canDischargeToGround
				local allowedToDischarge = dischargeNode.dischargeObject ~= nil or self:getCanDischargeToLand(dischargeNode) and self:getCanDischargeAtPosition(dischargeNode)
				local isReadyToStartDischarge = fillLevel > 0.0001 and emptySpeed > 0 and allowedToDischarge and canDischarge

				self:setDischargeEffectActive(dischargeNode, isReadyToStartDischarge)
				self:setDischargeEffectDistance(dischargeNode, dischargeNode.dischargeDistance)

				local isReadyForDischarge = dischargeNode.lastEffect == nil or dischargeNode.lastEffect:getIsFullyVisible()

				if isReadyForDischarge and allowedToDischarge and canDischarge then
					local emptyLiters = math.min(fillLevel, dischargeNode.emptySpeed * emptySpeed * dt)
					local dischargedLiters, minDropReached, hasMinDropFillLevel = self:discharge(dischargeNode, emptyLiters)
					spec.dischargedLiters = dischargedLiters

					self:handleDischarge(dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
				end
			end

			if dischargeNode.isEffectActive ~= dischargeNode.isEffectActiveSent or math.abs(dischargeNode.dischargeDistanceSent - dischargeNode.dischargeDistance) > 0.05 then
				self:raiseDirtyFlags(spec.dirtyFlag)

				dischargeNode.dischargeDistanceSent = dischargeNode.dischargeDistance
				dischargeNode.isEffectActiveSent = dischargeNode.isEffectActive
			end
		end
	end

	if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
		local currentDischargeNode = spec.currentDischargeNode

		if self:getIsActiveForInput() and self:getCanDischargeToObject(currentDischargeNode) and self:getCanToggleDischargeToObject() then
			g_currentMission:showTipContext(self:getFillUnitFillType(dischargeNode.fillUnitIndex))
		end
	end

	if isActiveForInputIgnoreSelection and dischargeNode ~= nil and dischargeNode.canStartDischargeAutomatically and dischargeNode.dischargeHit and dischargeNode.dischargeFailedReasonShowAuto and dischargeNode.dischargeFailedReason ~= nil then
		local warning = self:getDischargeNotAllowedWarning(dischargeNode)

		g_currentMission:showBlinkingWarning(warning, 5000)
	end

	for _, dischargeNode in ipairs(spec.dischargeNodes) do
		if dischargeNode.stopEffectTime ~= nil and dischargeNode.stopEffectTime < g_time then
			self:setDischargeEffectActive(dischargeNode, false, true)

			dischargeNode.stopEffectTime = nil
		end
	end
end

function Dischargeable:loadDischargeNode(xmlFile, key, entry)
	entry.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if entry.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing discharge 'node' for dischargeNode '%s'", key)

		return false
	end

	entry.fillUnitIndex = getXMLInt(xmlFile, key .. "#fillUnitIndex")

	if entry.fillUnitIndex == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'fillUnitIndex' for dischargeNode '%s'", key)

		return false
	end

	entry.unloadInfoIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#unloadInfoIndex"), 1)
	entry.stopDischargeOnEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#stopDischargeOnEmpty"), true)
	entry.canDischargeToGround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canDischargeToGround"), true)
	entry.canDischargeToObject = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canDischargeToObject"), true)
	entry.canStartDischargeAutomatically = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canStartDischargeAutomatically"), g_platformSettingsManager:getSetting("automaticDischarge", false))
	entry.stopDischargeIfNotPossible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#stopDischargeIfNotPossible"), false)
	entry.emptySpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#emptySpeed"), self:getFillUnitCapacity(entry.fillUnitIndex)) / 1000
	entry.lineOffset = 0
	entry.litersToDrop = 0
	entry.info = {
		node = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".info#node"), self.i3dMappings), entry.node)
	}

	if entry.info.node == entry.node then
		entry.info.node = createTransformGroup("dischargeInfoNode")

		link(entry.node, entry.info.node)
	end

	entry.info.width = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".info#width"), 1) / 2
	entry.info.length = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".info#length"), 1) / 2
	entry.info.zOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".info#zOffset"), 0)
	entry.info.yOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".info#yOffset"), 2)
	entry.info.limitToGround = Utils.getNoNil(getXMLBool(xmlFile, key .. ".info#limitToGround"), true)
	entry.info.useRaycastHitPosition = Utils.getNoNil(getXMLBool(xmlFile, key .. ".info#useRaycastHitPosition"), false)
	entry.raycast = {
		node = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".raycast#node"), self.i3dMappings), entry.node),
		useWorldNegYDirection = Utils.getNoNil(getXMLBool(xmlFile, key .. ".raycast#useWorldNegYDirection"), false),
		yOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".raycast#yOffset"), 0)
	}
	local raycastMaxDistance = getXMLFloat(xmlFile, key .. ".raycast#maxDistance")
	entry.maxDistance = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDistance"), raycastMaxDistance), 10)
	entry.dischargeObject = nil
	entry.dischargeHitTerrain = false
	entry.dischargeShape = nil
	entry.dischargeDistance = 0
	entry.dischargeDistanceSent = 0
	entry.dischargeFillUnitIndex = nil
	entry.dischargeHit = false
	entry.trigger = {
		node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".trigger#node"), self.i3dMappings)
	}

	if entry.trigger.node ~= nil then
		addTrigger(entry.trigger.node, "dischargeTriggerCallback", self)
	end

	entry.trigger.objects = {}
	entry.trigger.numObjects = 0
	entry.activationTrigger = {
		node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".activationTrigger#node"), self.i3dMappings)
	}

	if entry.activationTrigger.node ~= nil then
		addTrigger(entry.activationTrigger.node, "dischargeActivationTriggerCallback", self)
	end

	entry.activationTrigger.objects = {}
	entry.activationTrigger.numObjects = 0
	entry.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings)

	if self.isClient then
		entry.playSound = Utils.getNoNil(getXMLBool(xmlFile, key .. "#playSound"), true)
		entry.soundNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#soundNode"), self.i3dMappings)

		if entry.playSound then
			entry.dischargeSample = g_soundManager:loadSampleFromXML(self.xmlFile, key, "dischargeSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		end

		if Utils.getNoNil(getXMLBool(xmlFile, key .. ".dischargeSound#overwriteSharedSound"), false) then
			entry.playSound = false
		end
	end

	entry.sentHitDistance = 0
	entry.isEffectActive = false
	entry.isEffectActiveSent = false
	entry.lastEffect = entry.effects[#entry.effects]

	return true
end

function Dischargeable:setCurrentDischargeNodeIndex(dischargeNodeIndex)
	local spec = self.spec_dischargeable

	if spec.currentDischargeNode ~= nil then
		self:setDischargeEffectActive(spec.currentDischargeNode, false, true)
		self:updateDischargeSound(spec.currentDischargeNode, 99999)
	end

	spec.currentDischargeNode = spec.dischargeNodes[dischargeNodeIndex]

	self:handleDischargeNodeChanged()
end

function Dischargeable:getCurrentDischargeNode()
	local spec = self.spec_dischargeable

	return spec.currentDischargeNode
end

function Dischargeable:getDischargeTargetObject(dischargeNode)
	return dischargeNode.dischargeObject, dischargeNode.dischargeFillUnitIndex
end

function Dischargeable:getCurrentDischargeObject(dischargeNode)
	return dischargeNode.currentDischargeObject
end

function Dischargeable:getRequiresTipOcclusionArea()
	local spec = self.spec_dischargeable

	return spec.requiresTipOcclusionArea
end

function Dischargeable:getCanBeSelected(superFunc)
	return true
end

function Dischargeable:getDoConsumePtoPower(superFunc)
	return self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF or superFunc(self)
end

function Dischargeable:getIsPowerTakeOffActive(superFunc)
	return self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF or superFunc(self)
end

function Dischargeable:discharge(dischargeNode, emptyLiters)
	local spec = self.spec_dischargeable
	local dischargedLiters = 0
	local minDropReached = true
	local hasMinDropFillLevel = true
	local object, fillUnitIndex = self:getDischargeTargetObject(dischargeNode)
	dischargeNode.currentDischargeObject = nil

	if object ~= nil then
		if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
			dischargedLiters = self:dischargeToObject(dischargeNode, emptyLiters, object, fillUnitIndex)
		end
	elseif dischargeNode.dischargeHitTerrain and spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		dischargedLiters, minDropReached, hasMinDropFillLevel = self:dischargeToGround(dischargeNode, emptyLiters)
	end

	return dischargedLiters, minDropReached, hasMinDropFillLevel
end

function Dischargeable:dischargeToGround(dischargeNode, emptyLiters)
	local fillType = self:getDischargeFillType(dischargeNode)
	local fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
	local minLiterToDrop = g_densityMapHeightManager:getMinValidLiterValue(fillType)
	dischargeNode.litersToDrop = math.min(dischargeNode.litersToDrop + emptyLiters, math.max(dischargeNode.emptySpeed * 250, minLiterToDrop))
	local minDropReached = minLiterToDrop < dischargeNode.litersToDrop
	local hasMinDropFillLevel = minLiterToDrop < fillLevel
	local info = dischargeNode.info
	local dischargedLiters = 0
	local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
	local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)
	sy = sy + info.yOffset
	ey = ey + info.yOffset

	if info.limitToGround then
		sy = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + 0.1, sy)
		ey = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez) + 0.1, ey)
	end

	local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, dischargeNode.litersToDrop, fillType, sx, sy, sz, ex, ey, ez, info.length, nil, dischargeNode.lineOffset, true, nil, true)
	dischargeNode.lineOffset = lineOffset
	dischargeNode.litersToDrop = dischargeNode.litersToDrop - dropped

	if dropped > 0 then
		local unloadInfo = self:getFillVolumeUnloadInfo(dischargeNode.unloadInfoIndex)
		dischargedLiters = self:addFillUnitFillLevel(self:getOwnerFarmId(), dischargeNode.fillUnitIndex, -dropped, fillType, ToolType.UNDEFINED, unloadInfo)
	end

	fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)

	if fillLevel > 0 and fillLevel <= minLiterToDrop then
		dischargeNode.litersToDrop = minLiterToDrop
	end

	return dischargedLiters, minDropReached, hasMinDropFillLevel
end

function Dischargeable:dischargeToObject(dischargeNode, emptyLiters, object, targetFillUnitIndex)
	local fillType = self:getDischargeFillType(dischargeNode)
	local supportsFillType = object:getFillUnitSupportsFillType(targetFillUnitIndex, fillType)
	local dischargedLiters = 0

	if supportsFillType then
		local allowFillType = object:getFillUnitAllowsFillType(targetFillUnitIndex, fillType)

		if allowFillType then
			dischargeNode.currentDischargeObject = object
			local delta = object:addFillUnitFillLevel(self:getActiveFarm(), targetFillUnitIndex, emptyLiters, fillType, ToolType.DISCHARGEABLE, dischargeNode.info)
			local unloadInfo = self:getFillVolumeUnloadInfo(dischargeNode.unloadInfoIndex)
			dischargedLiters = self:addFillUnitFillLevel(self:getOwnerFarmId(), dischargeNode.fillUnitIndex, -delta, fillType, ToolType.UNDEFINED, unloadInfo)
		end
	end

	return dischargedLiters
end

function Dischargeable:setDischargeState(state, noEventSend)
	local spec = self.spec_dischargeable

	if state ~= spec.currentDischargeState then
		SetDischargeStateEvent.sendEvent(self, state, noEventSend)

		spec.currentDischargeState = state
		local dischargeNode = spec.currentDischargeNode

		if state == Dischargeable.DISCHARGE_STATE_OFF then
			self:setDischargeEffectActive(dischargeNode, false)

			dischargeNode.isEffectActiveSent = false
		end

		SpecializationUtil.raiseEvent(self, "onDischargeStateChanged", state)
	end
end

function Dischargeable:getDischargeState()
	return self.spec_dischargeable.currentDischargeState
end

function Dischargeable:getDischargeFillType(dischargeNode)
	return self:getFillUnitFillType(dischargeNode.fillUnitIndex)
end

function Dischargeable:getCanDischargeToGround(dischargeNode)
	if dischargeNode == nil then
		return false
	end

	if not dischargeNode.dischargeHitTerrain then
		return false
	end

	if self:getFillUnitFillLevel(dischargeNode.fillUnitIndex) > 0 then
		local fillTypeIndex = self:getDischargeFillType(dischargeNode)

		if not DensityMapHeightUtil.getCanTipToGround(fillTypeIndex) then
			return false
		end
	end

	if not self:getCanDischargeToLand(dischargeNode) then
		return false
	end

	if not self:getCanDischargeAtPosition(dischargeNode) then
		return false
	end

	return true
end

function Dischargeable:getCanDischargeToLand(dischargeNode)
	if dischargeNode == nil then
		return false
	end

	local info = dischargeNode.info
	local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
	local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)
	local activeFarm = self:getActiveFarm()

	if not g_currentMission.accessHandler:canFarmAccessLand(activeFarm, sx, sz) then
		return false
	end

	if not g_currentMission.accessHandler:canFarmAccessLand(activeFarm, ex, ez) then
		return false
	end

	return true
end

function Dischargeable:getCanDischargeAtPosition(dischargeNode)
	if dischargeNode == nil then
		return false
	end

	if self:getFillUnitFillLevel(dischargeNode.fillUnitIndex) > 0 then
		local info = dischargeNode.info
		local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
		local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)
		local spec = self.spec_dischargeable

		if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF or spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
			sy = sy + info.yOffset
			ey = ey + info.yOffset

			if info.limitToGround then
				sy = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + 0.1, sy)
				ey = math.max(getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez) + 0.1, ey)
			end

			local fillType = self:getDischargeFillType(dischargeNode)
			local testDrop = g_densityMapHeightManager:getMinValidLiterValue(fillType)

			if not DensityMapHeightUtil.getCanTipToGroundAroundLine(self, testDrop, fillType, sx, sy, sz, ex, ey, ez, info.length, nil, dischargeNode.lineOffset, true, nil, true) then
				return false
			end
		end
	end

	return true
end

function Dischargeable:getCanDischargeToObject(dischargeNode)
	if dischargeNode == nil then
		return false
	end

	local object = dischargeNode.dischargeObject

	if object == nil then
		return false
	end

	local fillType = self:getDischargeFillType(dischargeNode)

	if not object:getFillUnitSupportsFillType(dischargeNode.dischargeFillUnitIndex, fillType) then
		return false
	end

	local allowFillType = object:getFillUnitAllowsFillType(dischargeNode.dischargeFillUnitIndex, fillType)

	if not allowFillType then
		return false
	end

	if object.getFillUnitFreeCapacity ~= nil and object:getFillUnitFreeCapacity(dischargeNode.dischargeFillUnitIndex, fillType, self:getActiveFarm()) <= 0 then
		return false
	end

	if object.getIsFillAllowedFromFarm ~= nil and not object:getIsFillAllowedFromFarm(self:getActiveFarm()) then
		return false
	end

	if self.getMountObject ~= nil then
		local mounter = self:getDynamicMountObject() or self:getMountObject()

		if mounter ~= nil and not g_currentMission.accessHandler:canFarmAccess(mounter:getActiveFarm(), self, true) then
			return false
		end
	end

	return true
end

function Dischargeable:getDischargeNotAllowedWarning(dischargeNode)
	local text = g_i18n:getText(Dischargeable.DISCHARGE_WARNINGS[dischargeNode.dischargeFailedReason or 1] or "warning_notAcceptedHere")

	if dischargeNode.customNotAllowedWarning ~= nil then
		text = dischargeNode.customNotAllowedWarning
	end

	local fillType = self:getDischargeFillType(dischargeNode)
	local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)

	return string.format(text, fillTypeDesc.title)
end

function Dischargeable:getCanToggleDischargeToObject()
	local spec = self.spec_dischargeable
	local dischargeNode = spec.currentDischargeNode

	return dischargeNode ~= nil and dischargeNode.canDischargeToObject
end

function Dischargeable:getCanToggleDischargeToGround()
	local spec = self.spec_dischargeable
	local dischargeNode = spec.currentDischargeNode

	return dischargeNode ~= nil and dischargeNode.canDischargeToGround
end

function Dischargeable:getIsDischargeNodeActive(dischargeNode)
	return true
end

function Dischargeable:getDischargeNodeEmptyFactor(dischargeNode)
	return 1
end

function Dischargeable:getDischargeNodeByNode(node)
	return self.spec_dischargeable.dischargNodeMapping[node]
end

function Dischargeable:updateRaycast(dischargeNode)
	local spec = self.spec_dischargeable
	local raycast = dischargeNode.raycast

	if raycast.node == nil then
		return
	end

	dischargeNode.dischargeObject = nil
	dischargeNode.dischargeHitTerrain = false
	dischargeNode.dischargeShape = nil
	dischargeNode.dischargeDistance = math.huge
	dischargeNode.dischargeFillUnitIndex = nil
	dischargeNode.dischargeHit = false
	local x, y, z = getWorldTranslation(raycast.node)
	local dx = 0
	local dy = -1
	local dz = 0
	y = y + raycast.yOffset

	if not raycast.useWorldNegYDirection then
		dx, dy, dz = localDirectionToWorld(raycast.node, 0, -1, 0)
	end

	spec.currentRaycastDischargeNode = dischargeNode
	spec.currentRaycast = raycast
	spec.isAsyncRaycastActive = true

	raycastAll(x, y, z, dx, dy, dz, "raycastCallbackDischargeNode", dischargeNode.maxDistance, self, nil, false)
	self:raycastCallbackDischargeNode(nil)
end

function Dischargeable:updateDischargeInfo(dischargeNode, x, y, z)
	if dischargeNode.info.useRaycastHitPosition then
		setWorldTranslation(dischargeNode.info.node, x, y, z)
	end
end

function Dischargeable:raycastCallbackDischargeNode(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
	if hitActorId ~= nil then
		local spec = self.spec_dischargeable
		local dischargeNode = spec.currentRaycastDischargeNode
		local object = g_currentMission:getNodeObject(hitActorId)
		distance = distance - dischargeNode.raycast.yOffset

		if VehicleDebug.state == VehicleDebug.DEBUG then
			DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, nil)
		end

		local validObject = object ~= nil and object ~= self

		if validObject and distance < 0 and object.getFillUnitIndexFromNode ~= nil then
			validObject = validObject and object:getFillUnitIndexFromNode(hitShapeId) ~= nil
		end

		if validObject then
			if object.getFillUnitIndexFromNode ~= nil then
				local fillUnitIndex = object:getFillUnitIndexFromNode(hitShapeId)

				if fillUnitIndex ~= nil then
					local fillType = spec.forcedFillTypeIndex

					if fillType == nil then
						fillType = self:getDischargeFillType(dischargeNode)
					end

					dischargeNode.dischargeFailedReason = nil
					dischargeNode.dischargeFailedReasonShowAuto = false
					dischargeNode.customNotAllowedWarning = nil

					if object:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
						local allowFillType = object:getFillUnitAllowsFillType(fillUnitIndex, fillType)
						local allowToolType = object:getFillUnitSupportsToolType(fillUnitIndex, ToolType.DISCHARGEABLE)
						local freeSpace = object:getFillUnitFreeCapacity(fillUnitIndex, fillType, self:getActiveFarm()) > 0

						if allowFillType and allowToolType and freeSpace then
							dischargeNode.dischargeObject = object
							dischargeNode.dischargeShape = hitShapeId
							dischargeNode.dischargeDistance = distance
							dischargeNode.dischargeFillUnitIndex = fillUnitIndex

							if object.getFillUnitExtraDistanceFromNode ~= nil then
								dischargeNode.dischargeExtraDistance = object:getFillUnitExtraDistanceFromNode(hitShapeId)
							end
						elseif not allowFillType then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
						elseif not allowToolType then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_TOOLTYPE_NOT_SUPPORTED
						elseif not freeSpace then
							dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY
						end
					elseif fillType ~= FillType.UNKNOWN then
						dischargeNode.dischargeFailedReason = Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED
					end

					if (dischargeNode.dischargeFailedReason == Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED or dischargeNode.dischargeFailedReason == Dischargeable.DISCHARGE_REASON_NO_FREE_CAPACITY) and (object.isa == nil or not object:isa(Vehicle)) then
						dischargeNode.dischargeFailedReasonShowAuto = true
					end

					if dischargeNode.dischargeFailedReason ~= nil and dischargeNode.dischargeFailedReason ~= Dischargeable.DISCHARGE_REASON_FILLTYPE_NOT_SUPPORTED and object.getCustomDischargeNotAllowedWarning ~= nil then
						dischargeNode.customNotAllowedWarning = object:getCustomDischargeNotAllowedWarning()
					end

					dischargeNode.dischargeHit = true
				elseif dischargeNode.dischargeHit then
					dischargeNode.dischargeDistance = distance + (dischargeNode.dischargeExtraDistance or 0)
					dischargeNode.dischargeExtraDistance = nil

					self:updateDischargeInfo(dischargeNode, x, y, z)

					return false
				end
			end
		elseif hitActorId == g_currentMission.terrainRootNode then
			dischargeNode.dischargeDistance = math.min(dischargeNode.dischargeDistance, distance)
			dischargeNode.dischargeHitTerrain = true

			self:updateDischargeInfo(dischargeNode, x, y, z)

			return false
		end

		return true
	else
		self:finishDischargeRaycast()
	end
end

function Dischargeable:finishDischargeRaycast()
	local spec = self.spec_dischargeable
	local dischargeNode = spec.currentRaycastDischargeNode

	self:handleDischargeRaycast(dischargeNode, dischargeNode.dischargeObject, dischargeNode.dischargeShape, dischargeNode.dischargeDistance, dischargeNode.dischargeFillUnitIndex, dischargeNode.dischargeHitTerrain)

	spec.isAsyncRaycastActive = false
end

function Dischargeable:getDischargeNodeByIndex(index)
	local spec = self.spec_dischargeable

	return spec.dischargeNodes[index]
end

function Dischargeable:handleDischargeOnEmpty(dischargeNode)
	local spec = self.spec_dischargeable

	if spec.currentDischargeNode.stopDischargeOnEmpty then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function Dischargeable:handleDischargeNodeChanged()
end

function Dischargeable:handleDischarge(dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local spec = self.spec_dischargeable

	if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		local canDrop = not minDropReached and hasMinDropFillLevel

		if dischargeNode.stopDischargeIfNotPossible and dischargedLiters == 0 and not canDrop then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
	end
end

function Dischargeable:handleDischargeRaycast(dischargeNode, object, shape, distance, illUnitIndex, hitTerrain)
	local spec = self.spec_dischargeable

	if object == nil and spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
	end
end

function Dischargeable:handleFoundDischargeObject(dischargeNode)
	if dischargeNode.canStartDischargeAutomatically then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
	end
end

function Dischargeable:setDischargeEffectDistance(dischargeNode, distance)
	if dischargeNode.isEffectActive and dischargeNode.effects ~= nil and distance ~= math.huge then
		for _, effect in pairs(dischargeNode.effects) do
			if effect.setDistance ~= nil then
				effect:setDistance(distance, g_currentMission.terrainRootNode)
			end
		end
	end
end

function Dischargeable:setDischargeEffectActive(dischargeNode, isActive, force)
	if isActive then
		if not dischargeNode.isEffectActive then
			g_effectManager:setFillType(dischargeNode.effects, self:getFillUnitLastValidFillType(dischargeNode.fillUnitIndex))
			g_effectManager:startEffects(dischargeNode.effects)

			dischargeNode.isEffectActive = true
		end

		dischargeNode.stopEffectTime = nil
	elseif force == nil or not force then
		if dischargeNode.stopEffectTime == nil then
			dischargeNode.stopEffectTime = g_time + 500
		end
	elseif dischargeNode.isEffectActive then
		g_effectManager:stopEffects(dischargeNode.effects)

		dischargeNode.isEffectActive = false
	end
end

function Dischargeable:updateDischargeSound(dischargeNode, dt)
	if self.isClient then
		local fillType = self:getDischargeFillType(dischargeNode)
		local isInDischargeState = self.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF
		local isEmptying = dischargeNode.isEffectActive and fillType ~= FillType.UNKNOWN

		if isInDischargeState and isEmptying then
			local sharedSample = g_fillTypeManager:getSampleByFillType(fillType)

			if sharedSample ~= nil then
				if sharedSample ~= dischargeNode.sharedSample then
					if dischargeNode.sample ~= nil then
						g_soundManager:deleteSample(dischargeNode.sample)
					end

					dischargeNode.sample = g_soundManager:cloneSample(sharedSample, dischargeNode.node or dischargeNode.soundNode, self)
					dischargeNode.sharedSample = sharedSample

					g_soundManager:playSample(dischargeNode.sample)
				elseif not g_soundManager:getIsSamplePlaying(dischargeNode.sample) then
					g_soundManager:playSample(dischargeNode.sample)
				end
			end

			if dischargeNode.dischargeSample ~= nil and not g_soundManager:getIsSamplePlaying(dischargeNode.dischargeSample) then
				g_soundManager:playSample(dischargeNode.dischargeSample)
			end

			dischargeNode.turnOffSoundTimer = 500
		elseif dischargeNode.turnOffSoundTimer ~= nil and dischargeNode.turnOffSoundTimer > 0 then
			dischargeNode.turnOffSoundTimer = dischargeNode.turnOffSoundTimer - dt

			if dischargeNode.turnOffSoundTimer <= 0 then
				if g_soundManager:getIsSamplePlaying(dischargeNode.sample) then
					g_soundManager:stopSample(dischargeNode.sample)
				end

				if dischargeNode.dischargeSample ~= nil and g_soundManager:getIsSamplePlaying(dischargeNode.dischargeSample) then
					g_soundManager:stopSample(dischargeNode.dischargeSample)
				end

				dischargeNode.turnOffSoundTimer = 0
			end
		end
	end
end

function Dischargeable:dischargeTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_dischargeable

	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and object ~= self and object.getFillUnitIndexFromNode ~= nil then
			local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)
			local dischargeNode = spec.triggerToDischargeNode[triggerId]

			if dischargeNode ~= nil and fillUnitIndex ~= nil then
				local trigger = dischargeNode.trigger

				if onEnter then
					if trigger.objects[object] == nil then
						trigger.objects[object] = {
							count = 0,
							fillUnitIndex = fillUnitIndex,
							shape = otherShapeId
						}
						trigger.numObjects = trigger.numObjects + 1

						object:addDeleteListener(self, "onDeleteDischargeTriggerObject")
					end

					trigger.objects[object].count = trigger.objects[object].count + 1

					self:raiseActive()
				elseif onLeave then
					trigger.objects[object].count = trigger.objects[object].count - 1

					if trigger.objects[object].count == 0 then
						trigger.objects[object] = nil
						trigger.numObjects = trigger.numObjects - 1

						object:removeDeleteListener(self, "onDeleteDischargeTriggerObject")
					end
				end
			end
		end
	end
end

function Dischargeable:onDeleteDischargeTriggerObject(object)
	local spec = self.spec_dischargeable

	for _, dischargeNode in pairs(spec.triggerToDischargeNode) do
		local trigger = dischargeNode.trigger

		if trigger.objects[object] ~= nil then
			trigger.objects[object] = nil
			trigger.numObjects = trigger.numObjects - 1
		end
	end
end

function Dischargeable:dischargeActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_dischargeable

	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and object ~= self and object.getFillUnitIndexFromNode ~= nil then
			local fillUnitIndex = object:getFillUnitIndexFromNode(otherShapeId)
			local dischargeNode = spec.activationTriggerToDischargeNode[triggerId]

			if dischargeNode ~= nil and fillUnitIndex ~= nil then
				local trigger = dischargeNode.activationTrigger

				if onEnter then
					if trigger.objects[object] == nil then
						trigger.objects[object] = {
							count = 0,
							fillUnitIndex = fillUnitIndex,
							shape = otherShapeId
						}
						trigger.numObjects = trigger.numObjects + 1

						object:addDeleteListener(self, "onDeleteActivationTriggerObject")
					end

					trigger.objects[object].count = trigger.objects[object].count + 1

					self:raiseActive()
				elseif onLeave then
					trigger.objects[object].count = trigger.objects[object].count - 1

					if trigger.objects[object].count == 0 then
						trigger.objects[object] = nil
						trigger.numObjects = trigger.numObjects - 1

						object:removeDeleteListener(self, "onDeleteActivationTriggerObject")
					end
				end
			end
		end
	end
end

function Dischargeable:onDeleteActivationTriggerObject(object)
	local spec = self.spec_dischargeable

	for _, dischargeNode in pairs(spec.activationTriggerToDischargeNode) do
		local trigger = dischargeNode.activationTrigger

		if trigger.objects[object] ~= nil then
			trigger.objects[object] = nil
			trigger.numObjects = trigger.numObjects - 1
		end
	end
end

function Dischargeable:setForcedFillTypeIndex(fillTypeIndex)
	self.spec_dischargeable.forcedFillTypeIndex = fillTypeIndex
end

function Dischargeable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_dischargeable

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if self:getCanToggleDischargeToGround() then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TIPSTATE_GROUND, self, Dischargeable.actionEventToggleDischargeToGround, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			end

			if self:getCanToggleDischargeToObject() then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TIPSTATE, self, Dischargeable.actionEventToggleDischarging, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			end
		end
	end
end

function Dischargeable:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_dischargeable
	local dischargeNode = spec.fillUnitDischargeNodeMapping[fillUnitIndex]

	if dischargeNode ~= nil then
		local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

		if fillLevel == 0 then
			self:handleDischargeOnEmpty(dischargeNode)
		end
	end
end

function Dischargeable:onDeactivate()
	local spec = self.spec_dischargeable

	if spec.stopDischargeOnDeactivate and spec.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function Dischargeable:updateDebugValues(values)
	local spec = self.spec_dischargeable
	local currentDischargeNode = spec.currentDischargeNode
	local state = "OFF"

	if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT then
		state = "OBJECT"
	elseif spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		state = "GROUND"
	end

	table.insert(values, {
		name = "state",
		value = state
	})
	table.insert(values, {
		name = "getCanDischargeToObject",
		value = tostring(self:getCanDischargeToObject(currentDischargeNode))
	})
	table.insert(values, {
		name = "getCanDischargeToGround",
		value = tostring(self:getCanDischargeToGround(currentDischargeNode))
	})
	table.insert(values, {
		name = "dischargedLiters",
		value = tostring(spec.dischargedLiters)
	})
	table.insert(values, {
		name = "currentNode",
		value = tostring(currentDischargeNode)
	})

	for _, dischargeNode in ipairs(spec.dischargeNodes) do
		table.insert(values, {
			name = "--->",
			value = tostring(dischargeNode)
		})

		local object = nil

		if dischargeNode.dischargeObject ~= nil then
			object = tostring(dischargeNode.dischargeObject.configFileName)
		end

		table.insert(values, {
			name = "object",
			value = tostring(object)
		})
		table.insert(values, {
			name = "distance",
			value = dischargeNode.dischargeDistance
		})
		table.insert(values, {
			name = "effect",
			value = tostring(dischargeNode.isEffectActive)
		})
		table.insert(values, {
			name = "fillLevel",
			value = tostring(self:getFillUnitFillLevel(dischargeNode.fillUnitIndex))
		})
		table.insert(values, {
			name = "litersToDrop",
			value = tostring(dischargeNode.litersToDrop)
		})
		table.insert(values, {
			name = "emptyFactor",
			value = tostring(self:getDischargeNodeEmptyFactor(dischargeNode))
		})
		table.insert(values, {
			name = "emptySpeed",
			value = tostring(self:getDischargeNodeEmptyFactor(dischargeNode))
		})
		table.insert(values, {
			name = "readyForDischarge",
			value = tostring(dischargeNode.lastEffect == nil or dischargeNode.lastEffect:getIsFullyVisible())
		})
		table.insert(values, {
			name = "objectsInTrigger",
			value = tostring(dischargeNode.trigger.numObjects)
		})
		table.insert(values, {
			name = "objectsInActivationTrigger",
			value = tostring(dischargeNode.activationTrigger.numObjects)
		})
	end
end

function Dischargeable:actionEventToggleDischargeToGround(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleDischargeToGround() then
		local spec = self.spec_dischargeable
		local currentDischargeNode = spec.currentDischargeNode

		if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
			if self:getCanDischargeToGround(currentDischargeNode) then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND)
			elseif not self:getCanDischargeToLand(currentDischargeNode) then
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 5000)
			elseif not self:getCanDischargeAtPosition(currentDischargeNode) then
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"), 5000)
			end
		else
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
	end
end

function Dischargeable:actionEventToggleDischarging(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleDischargeToObject() then
		local spec = self.spec_dischargeable
		local currentDischargeNode = spec.currentDischargeNode

		if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
			if self:getCanDischargeToObject(currentDischargeNode) then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
			elseif currentDischargeNode.dischargeHit and self:getDischargeFillType(currentDischargeNode) ~= FillType.UNKNOWN then
				local warning = self:getDischargeNotAllowedWarning(currentDischargeNode)

				g_currentMission:showBlinkingWarning(warning, 5000)
			end
		else
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
		end
	end
end

function Dischargeable:updateActionEvents()
	local spec = self.spec_dischargeable
	local actionEventTip = spec.actionEvents[InputAction.TOGGLE_TIPSTATE]
	local actionEventTipGround = spec.actionEvents[InputAction.TOGGLE_TIPSTATE_GROUND]
	local showTip = false
	local showTipGround = false

	if spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OFF then
		local currentDischargeNode = spec.currentDischargeNode

		if self:getIsDischargeNodeActive(currentDischargeNode) then
			if self:getCanDischargeToObject(currentDischargeNode) and self:getCanToggleDischargeToObject() then
				if actionEventTip ~= nil then
					g_inputBinding:setActionEventText(actionEventTip.actionEventId, g_i18n:getText("action_startOverloading"))

					showTip = true
				end
			elseif self:getCanDischargeToGround(currentDischargeNode) and self:getCanToggleDischargeToGround() and actionEventTipGround ~= nil then
				g_inputBinding:setActionEventText(actionEventTipGround.actionEventId, g_i18n:getText("action_startTipToGround"))

				showTipGround = true
			end
		end
	elseif spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then
		if actionEventTipGround ~= nil then
			g_inputBinding:setActionEventText(actionEventTipGround.actionEventId, g_i18n:getText("action_stopTipToGround"))

			showTipGround = true
		end
	elseif actionEventTip ~= nil then
		g_inputBinding:setActionEventText(actionEventTip.actionEventId, g_i18n:getText("action_stopOverloading"))

		showTip = true
	end

	if actionEventTip ~= nil then
		g_inputBinding:setActionEventTextVisibility(actionEventTip.actionEventId, showTip)
	end

	if actionEventTipGround ~= nil then
		g_inputBinding:setActionEventTextVisibility(actionEventTipGround.actionEventId, showTipGround)
	end
end
