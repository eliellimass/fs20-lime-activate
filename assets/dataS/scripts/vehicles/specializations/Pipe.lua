source("dataS/scripts/vehicles/specializations/events/SetPipeStateEvent.lua")

Pipe = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
}

function Pipe.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadUnloadingTriggers", Pipe.loadUnloadingTriggers)
	SpecializationUtil.registerFunction(vehicleType, "loadPipeNodes", Pipe.loadPipeNodes)
	SpecializationUtil.registerFunction(vehicleType, "getIsPipeStateChangeAllowed", Pipe.getIsPipeStateChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setPipeState", Pipe.setPipeState)
	SpecializationUtil.registerFunction(vehicleType, "updatePipeNodes", Pipe.updatePipeNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateBendingRegulationNodes", Pipe.updateBendingRegulationNodes)
	SpecializationUtil.registerFunction(vehicleType, "unloadingTriggerCallback", Pipe.unloadingTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateNearestObjectInTriggers", Pipe.updateNearestObjectInTriggers)
	SpecializationUtil.registerFunction(vehicleType, "updateActionEventText", Pipe.updateActionEventText)
	SpecializationUtil.registerFunction(vehicleType, "onDeletePipeObject", Pipe.onDeletePipeObject)
	SpecializationUtil.registerFunction(vehicleType, "getPipeDischargeNodeIndex", Pipe.getPipeDischargeNodeIndex)
end

function Pipe.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", Pipe.getIsDischargeNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Pipe.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Pipe.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Pipe.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", Pipe.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", Pipe.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", Pipe.getCanToggleDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", Pipe.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", Pipe.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCoverFromXML", Pipe.loadCoverFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Pipe.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Pipe.getCanBeSelected)
end

function Pipe.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Pipe)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", Pipe)
end

function Pipe.initSpecialization()
	g_configurationManager:addConfigurationType("pipe", g_i18n:getText("configuration_pipe"), "pipe", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function Pipe:onLoad(savegame)
	local spec = self.spec_pipe
	local pipeConfigurationId = Utils.getNoNil(self.configurations.pipe, 1)
	local baseKey = string.format("vehicle.pipe.pipeConfigurations.pipeConfiguration(%d)", pipeConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.pipe.pipeConfigurations.pipeConfiguration", pipeConfigurationId, self.components, self)

	if not hasXMLProperty(self.xmlFile, baseKey) then
		baseKey = "vehicle.pipe"
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipeEffect.effectNode", baseKey .. ".pipeEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.overloading.trailerTriggers.trailerTrigger(0)#index", baseKey .. ".unloadingTriggers.unloadingTrigger(0)#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#raycastNodeIndex", baseKey .. ".raycast#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#raycastDistance", baseKey .. ".raycast#maxDistance")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#effectExtraDistanceOnTrailer", baseKey .. ".raycast#extraDistance")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#animName", baseKey .. ".animation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#animSpeedScale", baseKey .. ".animation#speedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#animSpeedScale", baseKey .. ".animation#speedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe.node#node", baseKey .. ".node#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#numStates", baseKey .. ".states#num")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#unloadingStates", baseKey .. ".states#unloading")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#autoAimingStates", baseKey .. ".states#autoAiming")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.pipe#turnOnAllowed", baseKey .. ".states#turnOnAllowed")

	spec.turnOnStateWarning = string.format(g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. "#turnOnStateWarning"), "warning_firstSetPipeState"), self.customEnvironment), self.typeDesc)
	spec.dischargeNodeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, baseKey .. "#dischargeNodeIndex"), 1)

	self:setCurrentDischargeNodeIndex(spec.dischargeNodeIndex)

	spec.unloadingTriggers = {}
	spec.objectsInTriggers = {}
	spec.unloadTriggersInTriggers = {}
	spec.numObjectsInTriggers = 0
	spec.numUnloadTriggersInTriggers = 0
	spec.nearestObjectInTriggers = {
		fillUnitIndex = 0
	}
	spec.nearestObjectInTriggersSent = {
		fillUnitIndex = 0
	}

	self:loadUnloadingTriggers(spec.unloadingTriggers, self.xmlFile, baseKey .. ".unloadingTriggers.unloadingTrigger")

	if table.getn(spec.unloadingTriggers) == 0 then
		g_logManager:xmlWarning(self.configFileName, "No 'unloadingTriggers' defined for pipe 'vehicle.pipe'!")
	else
		for _, trigger in pairs(spec.unloadingTriggers) do
			addTrigger(trigger.node, "unloadingTriggerCallback", self)
		end
	end

	spec.animation = {
		name = getXMLString(self.xmlFile, baseKey .. ".animation#name"),
		speedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. ".animation#speedScale"), 1)
	}
	spec.currentState = 1
	spec.targetState = 1
	spec.numStates = Utils.getNoNil(getXMLInt(self.xmlFile, baseKey .. ".states#num"), 0)
	spec.nodes = {}

	self:loadPipeNodes(spec.nodes, self.xmlFile, baseKey .. ".pipeNodes.pipeNode")

	spec.hasMovablePipe = table.getn(spec.nodes) > 0 or spec.animation.name ~= nil

	local function loadState(target, xmlFile, key)
		local i = 0
		local states = StringUtil.getVectorNFromString(getXMLString(xmlFile, key))

		if states ~= nil then
			for _, state in ipairs(states) do
				target[state] = true
				i = i + 1
			end
		end

		return i
	end

	spec.unloadingStates = {}
	spec.autoAimingStates = {}
	spec.turnOnAllowedStates = {}
	spec.numUnloadingStates = loadState(spec.unloadingStates, self.xmlFile, baseKey .. ".states#unloading")
	spec.numAutoAimingStates = loadState(spec.autoAimingStates, self.xmlFile, baseKey .. ".states#autoAiming")
	spec.numTurnOnAllowedStates = loadState(spec.turnOnAllowedStates, self.xmlFile, baseKey .. ".states#turnOnAllowed")
	spec.dischargeNodeMapping = {}
	local i = 0

	while true do
		local stateKey = string.format("%s.states.state(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, stateKey) then
			break
		end

		local stateIndex = getXMLInt(self.xmlFile, stateKey .. "#stateIndex")
		local dischargeNodeIndex = getXMLInt(self.xmlFile, stateKey .. "#dischargeNodeIndex")

		if stateIndex ~= nil and dischargeNodeIndex ~= nil then
			spec.dischargeNodeMapping[stateIndex] = dischargeNodeIndex
		end

		i = i + 1
	end

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.pipe.animationNodes", self.components, self, self.i3dMappings)
	end

	spec.foldMinTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#foldMinLimit"), 0)
	spec.foldMaxTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#foldMaxLimit"), 1)
	spec.foldMinState = Utils.getNoNil(getXMLInt(self.xmlFile, baseKey .. "#foldMinState"), 1)
	spec.foldMaxState = Utils.getNoNil(getXMLInt(self.xmlFile, baseKey .. "#foldMaxState"), spec.numStates)
	spec.aiFoldedPipeUsesTrailerSpace = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#aiFoldedPipeUsesTrailerSpace"), false)
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.lastFillTime = -1000
	spec.lastEmptyTime = -1000
end

function Pipe:onPostLoad(savegame)
	local spec = self.spec_pipe

	if savegame ~= nil and not savegame.resetVehicles then
		local pipeState = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. ".pipe#state"), spec.currentState)

		self:setPipeState(pipeState, true)
		self:updatePipeNodes(999999, nil)

		if spec.animation.name ~= nil then
			local targetTime = 0

			if pipeState ~= 1 then
				targetTime = 1
			end

			self:setAnimationTime(spec.animation.name, targetTime, true)
		end
	end
end

function Pipe:onDelete()
	local spec = self.spec_pipe

	for _, unloadingTrigger in pairs(spec.unloadingTriggers) do
		removeTrigger(unloadingTrigger.node)
	end

	if self.isClient then
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function Pipe:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_pipe

	setXMLInt(xmlFile, key .. "#state", MathUtil.clamp(spec.currentState, 1, spec.numStates))
end

function Pipe:onReadStream(streamId, connection)
	local spec = self.spec_pipe
	local pipeState = streamReadUIntN(streamId, 2)

	self:setPipeState(pipeState, true)

	if streamReadBool(streamId) then
		spec.nearestObjectInTriggers.objectId = NetworkUtil.readNodeObjectId(streamId)
		spec.nearestObjectInTriggers.fillUnitIndex = streamReadUIntN(streamId, 4)
	end
end

function Pipe:onWriteStream(streamId, connection)
	local spec = self.spec_pipe

	streamWriteUIntN(streamId, spec.targetState, 2)

	if streamWriteBool(streamId, spec.nearestObjectInTriggersSent.objectId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, spec.nearestObjectInTriggersSent.objectId)
		streamWriteUIntN(streamId, spec.nearestObjectInTriggersSent.fillUnitIndex, 4)
	end
end

function Pipe:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_pipe

		if streamReadBool(streamId) then
			spec.nearestObjectInTriggers.objectId = NetworkUtil.readNodeObjectId(streamId)
			spec.nearestObjectInTriggers.fillUnitIndex = streamReadUIntN(streamId, 4)
		else
			spec.nearestObjectInTriggers.objectId = nil
			spec.nearestObjectInTriggers.fillUnitIndex = 0
		end
	end
end

function Pipe:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_pipe

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) and streamWriteBool(streamId, spec.nearestObjectInTriggersSent.objectId ~= nil) then
			NetworkUtil.writeNodeObjectId(streamId, spec.nearestObjectInTriggersSent.objectId)
			streamWriteUIntN(streamId, spec.nearestObjectInTriggersSent.fillUnitIndex, 4)
		end
	end
end

function Pipe:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_pipe

	self:updateActionEventText()

	if spec.hasMovablePipe then
		self:updatePipeNodes(dt, spec.nearestObjectInTriggers)
	end
end

function Pipe:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		self:updateNearestObjectInTriggers()

		local spec = self.spec_pipe
		local objectChanged = spec.nearestObjectInTriggers.objectId ~= spec.nearestObjectInTriggersSent.objectId
		local fillUnitChanged = spec.nearestObjectInTriggers.fillUnitIndex ~= spec.nearestObjectInTriggersSent.fillUnitIndex

		if objectChanged or fillUnitChanged then
			spec.nearestObjectInTriggersSent.objectId = spec.nearestObjectInTriggers.objectId
			spec.nearestObjectInTriggersSent.fillUnitIndex = spec.nearestObjectInTriggers.fillUnitIndex

			self:raiseDirtyFlags(spec.dirtyFlag)
		end

		if g_platformSettingsManager:getSetting("automaticPipeUnfolding", false) and not self:getIsAIActive() then
			local unfoldPipe = spec.nearestObjectInTriggers.objectId ~= nil or spec.numUnloadTriggersInTriggers > 0
			local dischargeNode = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())

			if dischargeNode ~= nil then
				local capacity = self:getFillUnitCapacity(dischargeNode.fillUnitIndex)
				local fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)
				unfoldPipe = unfoldPipe and (capacity == math.huge and self.getIsTurnedOn ~= nil and self:getIsTurnedOn() or fillLevel > 0)
			end

			if unfoldPipe then
				if spec.targetState == 1 then
					for state, _ in pairs(spec.unloadingStates) do
						self:setPipeState(state)

						break
					end
				end
			elseif spec.targetState > 1 then
				self:setPipeState(1)
			end
		end
	end
end

function Pipe:loadUnloadingTriggers(unloadingTriggers, xmlFile, baseKey)
	local i = 0

	while true do
		local key = string.format("%s(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

		if node ~= nil then
			local colMask = getCollisionMask(node)

			if bitAND(FillUnit.EXACTFILLROOTNODE_MASK, colMask) ~= 0 then
				table.insert(unloadingTriggers, {
					node = node
				})
			else
				g_logManager:xmlWarning(self.configFileName, "Invalid collision mask for unloading trigger '%s'. Bit 30 needs to be set!", key)
			end
		end

		i = i + 1
	end
end

function Pipe:loadPipeNodes(pipeNodes, xmlFile, baseKey)
	local spec = self.spec_pipe
	local maxPriority = 0
	local i = 0

	while true do
		local key = string.format("%s(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

		if node ~= nil then
			local entry = {
				node = node,
				autoAimXRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimXRotation"), false),
				autoAimYRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimYRotation"), false),
				autoAimInvertZ = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoAimInvertZ"), false),
				states = {}
			}

			for state = 1, spec.numStates do
				local stateKey = key .. string.format(".state%d", state)
				entry.states[state] = {}
				local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, stateKey .. "#translation"))

				if x == nil or y == nil or z == nil then
					x, y, z = getTranslation(node)
				elseif state == 1 then
					setTranslation(node, x, y, z)
				end

				entry.states[state].translation = {
					x,
					y,
					z
				}
				x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, stateKey .. "#rotation"))

				if x == nil or y == nil or z == nil then
					x, y, z = getRotation(node)
				else
					z = math.rad(z)
					y = math.rad(y)
					x = math.rad(x)

					if state == 1 then
						setRotation(node, x, y, z)
					end
				end

				entry.states[state].rotation = {
					x,
					y,
					z
				}
			end

			local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#translationSpeeds"))

			if x ~= nil and y ~= nil and z ~= nil then
				z = z * 0.001
				y = y * 0.001
				x = x * 0.001

				if x ~= 0 or y ~= 0 or z ~= 0 then
					entry.translationSpeeds = {
						x,
						y,
						z
					}
				end
			end

			x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotationSpeeds"))

			if x ~= nil and y ~= nil and z ~= nil then
				z = math.rad(z) * 0.001
				y = math.rad(y) * 0.001
				x = math.rad(x) * 0.001

				if x ~= 0 or y ~= 0 or z ~= 0 then
					entry.rotationSpeeds = {
						x,
						y,
						z
					}
				end
			end

			x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#minRotationLimits"))

			if x ~= nil or y ~= nil or z ~= nil then
				x = x ~= nil and math.rad(x) or nil
				y = y ~= nil and math.rad(y) or nil
				z = z ~= nil and math.rad(z) or nil
				entry.minRotationLimits = {
					x,
					y,
					z
				}
			end

			x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#maxRotationLimits"))

			if x ~= nil or y ~= nil or z ~= nil then
				x = x ~= nil and math.rad(x) or nil
				y = y ~= nil and math.rad(y) or nil
				z = z ~= nil and math.rad(z) or nil
				entry.maxRotationLimits = {
					x,
					y,
					z
				}
			end

			entry.foldPriority = Utils.getNoNil(getXMLInt(xmlFile, key .. "#foldPriority"), 0)
			maxPriority = math.max(entry.foldPriority, maxPriority)
			x, y, z = getTranslation(node)
			entry.curTranslation = {
				x,
				y,
				z
			}
			x, y, z = getRotation(node)
			entry.curRotation = {
				x,
				y,
				z
			}
			entry.lastTargetRotation = {
				x,
				y,
				z
			}
			entry.bendingRegulation = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#bendingRegulation"), 0)
			entry.regulationNodes = {}
			local j = 0

			while true do
				local regKey = string.format("%s.bendingRegulationNode(%d)", key, j)

				if not hasXMLProperty(xmlFile, regKey) then
					break
				end

				local regulationNode = {
					node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, regKey .. "#node"), self.i3dMappings)
				}

				if regulationNode.node ~= nil then
					regulationNode.startRotation = {
						getRotation(regulationNode.node)
					}
					local axis = Utils.getNoNil(getXMLInt(xmlFile, regKey .. "#axis"), 1)
					local direction = Utils.getNoNil(getXMLInt(xmlFile, regKey .. "#direction"), 1)
					regulationNode.weights = {
						0,
						0,
						0,
						[MathUtil.clamp(axis, 1, 3)] = direction
					}

					table.insert(entry.regulationNodes, regulationNode)
				else
					g_logManager:xmlWarning(self.configFileName, "Failed to load bendingRegulationNode '%s'", regKey)
				end

				j = j + 1
			end

			table.insert(pipeNodes, entry)
		end

		i = i + 1
	end

	for _, pipeNode in ipairs(pipeNodes) do
		pipeNode.inverseFoldPriority = maxPriority - pipeNode.foldPriority
	end
end

function Pipe:getIsPipeStateChangeAllowed(pipeState)
	local spec = self.spec_pipe
	local foldAnimTime = nil

	if self.getFoldAnimTime ~= nil then
		foldAnimTime = self:getFoldAnimTime()
	end

	if foldAnimTime ~= nil and (foldAnimTime < spec.foldMinTime or spec.foldMaxTime < foldAnimTime) then
		return false
	end

	return true
end

function Pipe:setPipeState(pipeState, noEventSend)
	local spec = self.spec_pipe
	pipeState = math.min(pipeState, spec.numStates)

	if spec.targetState ~= pipeState then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(SetPipeStateEvent:new(self, pipeState))
			else
				g_client:getServerConnection():sendEvent(SetPipeStateEvent:new(self, pipeState), nil, , self)
			end
		end

		spec.targetState = pipeState
		spec.currentState = 0

		if spec.animation ~= nil then
			if pipeState == 1 then
				self:playAnimation(spec.animation.name, -spec.animation.speedScale, self:getAnimationTime(spec.animation.name), true)
			else
				self:playAnimation(spec.animation.name, spec.animation.speedScale, self:getAnimationTime(spec.animation.name), true)
			end
		end

		self:setCurrentDischargeNodeIndex(self:getPipeDischargeNodeIndex(pipeState))
	end
end

function Pipe:updatePipeNodes(dt, nearestObjectInTrigger)
	local spec = self.spec_pipe
	local object = nil

	if nearestObjectInTrigger ~= nil then
		object = NetworkUtil.getObject(nearestObjectInTrigger.objectId)
	end

	local doAutoAiming = object ~= nil and entityExists(object.components[1].node) and spec.autoAimingStates[spec.currentState]

	if spec.currentState ~= spec.targetState or doAutoAiming then
		local priority = spec.targetState ~= spec.numStates and "foldPriority" or "inverseFoldPriority"
		local fillAutoAimTargetNode, autoAimX, autoAimY, autoAimZ = nil

		if doAutoAiming then
			fillAutoAimTargetNode = object:getFillUnitAutoAimTargetNode(nearestObjectInTrigger.fillUnitIndex)

			if fillAutoAimTargetNode == nil then
				fillAutoAimTargetNode = object:getFillUnitExactFillRootNode(nearestObjectInTrigger.fillUnitIndex)
			end

			autoAimX, autoAimY, autoAimZ = getWorldTranslation(fillAutoAimTargetNode)
		end

		local moved = false

		for i = 1, table.getn(spec.nodes) do
			local nodeMoved = false
			local pipeNode = spec.nodes[i]

			if pipeNode.bendingRegulation > 0 and fillAutoAimTargetNode ~= nil then
				local distance = calcDistanceFrom(pipeNode.node, fillAutoAimTargetNode)
				local regulation = self:updateBendingRegulationNodes(pipeNode, distance)
				autoAimY = autoAimY - regulation
			end

			local state = pipeNode.states[spec.targetState]

			if pipeNode.translationSpeeds ~= nil then
				for i = 1, 3 do
					if math.abs(pipeNode.curTranslation[i] - state.translation[i]) > 1e-06 then
						nodeMoved = true

						if pipeNode.curTranslation[i] < state.translation[i] then
							pipeNode.curTranslation[i] = math.min(pipeNode.curTranslation[i] + dt * pipeNode.translationSpeeds[i], state.translation[i])
						else
							pipeNode.curTranslation[i] = math.max(pipeNode.curTranslation[i] - dt * pipeNode.translationSpeeds[i], state.translation[i])
						end
					end
				end

				setTranslation(pipeNode.node, pipeNode.curTranslation[1], pipeNode.curTranslation[2], pipeNode.curTranslation[3])
			end

			if pipeNode.rotationSpeeds ~= nil then
				local changed = false

				for i = 1, 3 do
					local targetRotation = state.rotation[i]

					if doAutoAiming then
						if pipeNode.autoAimXRotation and i == 1 then
							local x, y, z = getWorldTranslation(pipeNode.node)
							local _, y, z = worldDirectionToLocal(getParent(pipeNode.node), autoAimX - x, autoAimY - y, autoAimZ - z)
							targetRotation = -math.atan2(y, z)

							if pipeNode.autoAimInvertZ then
								targetRotation = targetRotation + math.pi
							end

							targetRotation = MathUtil.normalizeRotationForShortestPath(targetRotation, pipeNode.curRotation[i])
						elseif pipeNode.autoAimYRotation and i == 2 then
							local x, y, z = getWorldTranslation(pipeNode.node)
							local x, _, z = worldDirectionToLocal(getParent(pipeNode.node), autoAimX - x, autoAimY - y, autoAimZ - z)
							targetRotation = math.atan2(x, z)

							if pipeNode.autoAimInvertZ then
								targetRotation = targetRotation + math.pi
							end

							targetRotation = MathUtil.normalizeRotationForShortestPath(targetRotation, pipeNode.curRotation[i])
						end
					end

					if pipeNode.minRotationLimits ~= nil and pipeNode.maxRotationLimits ~= nil then
						if math.pi < math.abs(targetRotation) then
							targetRotation = targetRotation % math.pi
						end

						if pipeNode.minRotationLimits[i] ~= nil then
							targetRotation = math.max(targetRotation, pipeNode.minRotationLimits[i])
						end

						if pipeNode.maxRotationLimits[i] ~= nil then
							targetRotation = math.min(targetRotation, pipeNode.maxRotationLimits[i])
						end
					end

					if math.abs(pipeNode.curRotation[i] - targetRotation) > 1e-05 then
						changed = true
						local rotationAllowed = true

						for j = 1, table.getn(spec.nodes) do
							local pipeNodeToCheck = spec.nodes[j]

							if pipeNode[priority] < pipeNodeToCheck[priority] then
								for l = 1, 3 do
									if pipeNodeToCheck.curRotation[l] ~= pipeNodeToCheck.lastTargetRotation[l] then
										rotationAllowed = false

										break
									end
								end
							end
						end

						if rotationAllowed then
							nodeMoved = true

							if pipeNode.curRotation[i] < targetRotation then
								pipeNode.curRotation[i] = math.min(pipeNode.curRotation[i] + dt * pipeNode.rotationSpeeds[i], targetRotation)
							else
								pipeNode.curRotation[i] = math.max(pipeNode.curRotation[i] - dt * pipeNode.rotationSpeeds[i], targetRotation)
							end

							if pipeNode.curRotation[i] > 2 * math.pi then
								pipeNode.curRotation[i] = pipeNode.curRotation[i] - 2 * math.pi
							elseif pipeNode.curRotation[i] < -2 * math.pi then
								pipeNode.curRotation[i] = pipeNode.curRotation[i] + 2 * math.pi
							end

							pipeNode.lastTargetRotation[i] = targetRotation
						end
					end
				end

				if changed then
					setRotation(pipeNode.node, pipeNode.curRotation[1], pipeNode.curRotation[2], pipeNode.curRotation[3])
				end
			end

			moved = moved or nodeMoved

			if nodeMoved and self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(pipeNode.node)
			end
		end

		if table.getn(spec.nodes) == 0 and spec.animation.name ~= nil and self:getIsAnimationPlaying(spec.animation.name) then
			moved = true
		end

		if not moved then
			spec.currentState = spec.targetState
		end
	elseif self:getDischargeState() == Dischargeable.DISCHARGE_STATE_GROUND then
		local dischargeNode = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())

		if dischargeNode ~= nil then
			for _, pipeNode in ipairs(spec.nodes) do
				if pipeNode.bendingRegulation > 0 then
					self:updateBendingRegulationNodes(pipeNode, dischargeNode.dischargeDistance)
				end
			end
		end
	end
end

function Pipe:updateBendingRegulationNodes(pipeNode, distance)
	local _, dirY, _ = localDirectionToWorld(pipeNode.node, 0, 1, 0)

	for _, regulationNode in ipairs(pipeNode.regulationNodes) do
		local regulationAngle = dirY * pipeNode.bendingRegulation
		local weights = regulationNode.weights
		local startRotation = regulationNode.startRotation

		setRotation(regulationNode.node, startRotation[1] + weights[1] * regulationAngle, startRotation[2] + weights[2] * regulationAngle, startRotation[3] + weights[3] * regulationAngle)
	end

	return math.sin(dirY * pipeNode.bendingRegulation) * distance
end

function Pipe:unloadingTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object ~= self and object:isa(Vehicle) then
			if object.getFillUnitIndexFromNode ~= nil then
				local fillUnitIndex = object:getFillUnitIndexFromNode(otherId)

				if fillUnitIndex ~= nil then
					local spec = self.spec_pipe
					local dischargeNode = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())

					if dischargeNode ~= nil then
						local fillTypes = self:getFillUnitSupportedFillTypes(dischargeNode.fillUnitIndex)
						local objectSupportsFillType = false

						for fillType, _ in pairs(fillTypes) do
							if object:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
								objectSupportsFillType = true

								break
							end
						end

						if objectSupportsFillType then
							if onEnter then
								if spec.objectsInTriggers[object] == nil then
									spec.objectsInTriggers[object] = 0
									spec.numObjectsInTriggers = spec.numObjectsInTriggers + 1

									if object.addDeleteListener ~= nil then
										object:addDeleteListener(self, "onDeletePipeObject")
									end
								end

								spec.objectsInTriggers[object] = spec.objectsInTriggers[object] + 1
							else
								spec.objectsInTriggers[object] = spec.objectsInTriggers[object] - 1

								if spec.objectsInTriggers[object] == 0 then
									spec.objectsInTriggers[object] = nil
									spec.numObjectsInTriggers = spec.numObjectsInTriggers - 1

									if object.removeDeleteListener ~= nil then
										object:removeDeleteListener(self)
									end
								end
							end
						end
					end
				end
			end
		elseif object ~= nil and object ~= self and object:isa(UnloadTrigger) then
			local spec = self.spec_pipe

			if onEnter then
				if spec.unloadTriggersInTriggers[object] == nil then
					spec.unloadTriggersInTriggers[object] = 0
					spec.numUnloadTriggersInTriggers = spec.numUnloadTriggersInTriggers + 1

					if object.addDeleteListener ~= nil then
						object:addDeleteListener(self, "onDeletePipeObject")
					end
				end

				spec.unloadTriggersInTriggers[object] = spec.unloadTriggersInTriggers[object] + 1
			else
				spec.unloadTriggersInTriggers[object] = spec.unloadTriggersInTriggers[object] - 1

				if spec.unloadTriggersInTriggers[object] == 0 then
					spec.unloadTriggersInTriggers[object] = nil
					spec.numUnloadTriggersInTriggers = spec.numUnloadTriggersInTriggers - 1

					if object.removeDeleteListener ~= nil then
						object:removeDeleteListener(self)
					end
				end
			end
		end
	end
end

function Pipe:updateNearestObjectInTriggers()
	local spec = self.spec_pipe
	spec.nearestObjectInTriggers.objectId = nil
	spec.nearestObjectInTriggers.fillUnitIndex = 0
	local minDistance = math.huge
	local dischargeNode = self:getDischargeNodeByIndex(self:getPipeDischargeNodeIndex())

	if dischargeNode ~= nil then
		local checkNode = Utils.getNoNil(dischargeNode.node, self.components[1].node)

		for object, _ in pairs(spec.objectsInTriggers) do
			local outputFillType = self:getFillUnitLastValidFillType(dischargeNode.fillUnitIndex)

			for fillUnitIndex, _ in ipairs(object.spec_fillUnit.fillUnits) do
				local allowedToFillByPipe = object:getFillUnitSupportsToolType(fillUnitIndex, ToolType.DISCHARGEABLE)
				local supportsFillType = object:getFillUnitSupportsFillType(fillUnitIndex, outputFillType) or outputFillType == FillType.UNKNOWN
				local fillLevel = object:getFillUnitFreeCapacity(fillUnitIndex, outputFillType, self:getOwnerFarmId())

				if allowedToFillByPipe and supportsFillType and fillLevel > 0 then
					local targetPoint = object:getFillUnitAutoAimTargetNode(fillUnitIndex)
					local exactFillRootNode = object:getFillUnitExactFillRootNode(fillUnitIndex)

					if targetPoint == nil then
						targetPoint = exactFillRootNode
					end

					if targetPoint ~= nil then
						local distance = calcDistanceFrom(checkNode, targetPoint)

						if distance < minDistance then
							minDistance = distance
							spec.nearestObjectInTriggers.objectId = NetworkUtil.getObjectId(object)
							spec.nearestObjectInTriggers.fillUnitIndex = fillUnitIndex

							break
						end
					end
				end
			end
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Unable to find discharge node index '%d' for pipe", self:getPipeDischargeNodeIndex())
	end
end

function Pipe:updateActionEventText()
	local spec = self.spec_pipe
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_PIPE]

	if actionEvent ~= nil then
		local showAction = false

		if spec.targetState == spec.numStates then
			if self:getIsPipeStateChangeAllowed(1) then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_pipeIn"))

				showAction = true
			end
		else
			local nextState = spec.targetState + 1

			if self:getIsPipeStateChangeAllowed(nextState) then
				local pipeStateName = ""

				if spec.numUnloadingStates > 1 and spec.numUnloadingStates ~= spec.numStates then
					pipeStateName = string.format(" [%d]", nextState - 1)
					local dischargeNodeIndex = self:getPipeDischargeNodeIndex(nextState)
					local dischargeNode = self:getDischargeNodeByIndex(dischargeNodeIndex)
					local fillTypeIndex = self:getFillUnitFillType(dischargeNode.fillUnitIndex)

					if fillTypeIndex ~= FillType.UNKNOWN then
						local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

						if fillType ~= nil then
							pipeStateName = string.format(" [%d, %s]", nextState - 1, fillType.title)
						end
					end
				end

				g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText("action_pipeOut"), pipeStateName))

				showAction = true
			end
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
	end
end

function Pipe:getIsDischargeNodeActive(superFunc, dischargeNode)
	local spec = self.spec_pipe

	if dischargeNode.index == self:getPipeDischargeNodeIndex() then
		return spec.unloadingStates[spec.currentState] == true
	end

	return superFunc(self, dischargeNode)
end

function Pipe:getCanBeTurnedOn(superFunc)
	local spec = self.spec_pipe

	if spec.hasMovablePipe and table.getn(spec.turnOnAllowedStates) > 0 then
		local isAllowed = false

		for pipeState, _ in pairs(spec.turnOnAllowedStates) do
			if pipeState == spec.currentState then
				isAllowed = true

				break
			end
		end

		if not isAllowed then
			return false
		end
	end

	return superFunc(self)
end

function Pipe:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_pipe

	if spec.hasMovablePipe and table.getn(spec.turnOnAllowedStates) > 0 then
		local isAllowed = false

		for pipeState, _ in pairs(spec.turnOnAllowedStates) do
			if pipeState == spec.currentState then
				isAllowed = true

				break
			end
		end

		if not isAllowed then
			return spec.turnOnStateWarning
		end
	end

	return superFunc(self)
end

function Pipe:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_pipe

	if spec.hasMovablePipe and (spec.foldMaxState < spec.currentState or spec.currentState < spec.foldMinState) then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Pipe:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local spec = self.spec_pipe

	if dischargeNode.index ~= self:getPipeDischargeNodeIndex() then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function Pipe:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local stopDischarge = false

	if hitObject ~= nil then
		local fillType = self:getDischargeFillType(dischargeNode)
		local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)

		if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, fillType, self:getOwnerFarmId()) > 0 then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
		else
			stopDischarge = true
		end
	else
		stopDischarge = true
	end

	if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function Pipe:getCanToggleDischargeToObject(superFunc)
	return false
end

function Pipe:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local freezingPipeStatesStr = getXMLString(xmlFile, key .. "#freezingPipeStates")

	if freezingPipeStatesStr ~= nil then
		entry.freezingPipeStates = {
			StringUtil.getVectorFromString(freezingPipeStatesStr)
		}
	end

	return true
end

function Pipe:getIsMovingToolActive(superFunc, movingTool)
	local spec = self.spec_pipe

	if movingTool.freezingPipeStates ~= nil then
		for _, state in pairs(movingTool.freezingPipeStates) do
			if spec.currentState == state or spec.targetState == state or spec.currentState == 0 then
				return false
			end
		end
	end

	return superFunc(self, movingTool)
end

function Pipe:loadCoverFromXML(superFunc, xmlFile, key, cover)
	cover.minPipeState = getXMLInt(xmlFile, key .. "#minPipeState") or 0
	cover.maxPipeState = getXMLInt(xmlFile, key .. "#maxPipeState") or math.huge

	return superFunc(self, xmlFile, key, cover)
end

function Pipe:getIsNextCoverStateAllowed(superFunc, nextState)
	if not superFunc(self, nextState) then
		return false
	end

	local spec = self.spec_pipe
	local cover = self.spec_cover.covers[nextState]

	if nextState ~= 0 and (spec.currentState < cover.minPipeState or cover.maxPipeState < spec.currentState) then
		return false
	end

	return true
end

function Pipe:onDeletePipeObject(object)
	local spec = self.spec_pipe

	if spec.objectsInTriggers[object] ~= nil then
		spec.objectsInTriggers[object] = nil
		spec.numObjectsInTriggers = spec.numObjectsInTriggers - 1
	end

	if spec.unloadTriggersInTriggers[object] ~= nil then
		spec.unloadTriggersInTriggers[object] = nil
		spec.numUnloadTriggersInTriggers = spec.numUnloadTriggersInTriggers - 1
	end
end

function Pipe:getPipeDischargeNodeIndex(state)
	local spec = self.spec_pipe

	if state == nil then
		state = spec.currentState
	end

	if spec.dischargeNodeMapping[state] ~= nil then
		return spec.dischargeNodeMapping[state]
	end

	return spec.dischargeNodeIndex
end

function Pipe:getCanBeSelected(superFunc)
	return true
end

function Pipe:onMovingToolChanged(tool, transSpeed, dt)
	local spec = self.spec_pipe

	for _, pipeNode in ipairs(spec.nodes) do
		if pipeNode.node == tool.node then
			pipeNode.curTranslation = {
				tool.curTrans[1],
				tool.curTrans[2],
				tool.curTrans[3]
			}
			pipeNode.curRotation = {
				tool.curRot[1],
				tool.curRot[2],
				tool.curRot[3]
			}
		end
	end
end

function Pipe:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_pipe

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.hasMovablePipe then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_PIPE, self, Pipe.actionEventTogglePipe, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			self:updateActionEventText()
		end
	end
end

function Pipe:onDischargeStateChanged(state)
	if self.isClient then
		local spec = self.spec_pipe
		local dischargeNode = self:getCurrentDischargeNode()
		local dischargeNodeIndex = nil

		if dischargeNode ~= nil then
			dischargeNodeIndex = dischargeNode.index
		end

		if dischargeNodeIndex == spec.dischargeNodeIndex then
			if state == Dischargeable.DISCHARGE_STATE_OFF then
				g_animationManager:stopAnimations(spec.animationNodes)
			else
				g_animationManager:startAnimations(spec.animationNodes)
				g_animationManager:setFillType(spec.animationNodes, self:getFillUnitLastValidFillType(dischargeNode.fillUnitIndex))
			end
		end
	end
end

function Pipe:actionEventTogglePipe(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_pipe

	if spec.hasMovablePipe then
		local nextState = spec.targetState + 1

		if spec.numStates < nextState then
			nextState = 1
		end

		if self:getIsPipeStateChangeAllowed(nextState) then
			self:setPipeState(nextState)
		elseif nextState ~= 1 and self:getIsPipeStateChangeAllowed(1) then
			self:setPipeState(1)
		end
	end
end
