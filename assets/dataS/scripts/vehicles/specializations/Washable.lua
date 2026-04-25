Washable = {
	SEND_NUM_BITS = 6
}
Washable.SEND_MAX_VALUE = 2^Washable.SEND_NUM_BITS - 1
Washable.SEND_THRESHOLD = 1 / Washable.SEND_MAX_VALUE
Washable.WASHTYPE_HIGH_PRESSURE_WASHER = 1
Washable.WASHTYPE_RAIN = 2
Washable.WASHTYPE_TRIGGER = 3

function Washable.prerequisitesPresent(specializations)
	return true
end

function Washable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateDirtAmount", Washable.updateDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "addDirtAmount", Washable.addDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getDirtAmount", Washable.getDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeDirtAmount", Washable.setNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getNodeDirtAmount", Washable.getNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "addAllSubWashableNodes", Washable.addAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addWashableNodes", Washable.addWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "validateWashableNode", Washable.validateWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToGlobalWashableNode", Washable.addToGlobalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToLocalWashableNode", Washable.addToLocalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "removeAllSubWashableNodes", Washable.removeAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "removeWashableNode", Washable.removeWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "getDirtMultiplier", Washable.getDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWorkDirtMultiplier", Washable.getWorkDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWashDuration", Washable.getWashDuration)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsWashingByType", Washable.getAllowsWashingByType)
end

function Washable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Washable)
end

function Washable:onLoad(savegame)
	local spec = self.spec_washable
	spec.washableNodes = {}
	spec.washableNodesByIndex = {}

	self:addToLocalWashableNode(nil, Washable.updateDirtAmount, nil, )

	spec.globalWashableNode = spec.washableNodes[1]
	spec.dirtDuration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.washable#dirtDuration"), 90) * 60 * 1000

	if spec.dirtDuration ~= 0 then
		spec.dirtDuration = 1 / spec.dirtDuration
	end

	spec.washDuration = math.max(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.washable#washDuration"), 1) * 60 * 1000, 1e-05)
	spec.workMultiplier = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.washable#workMultiplier"), 4)
	spec.fieldMultiplier = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.washable#fieldMultiplier"), 2)
	spec.blockedWashTypes = {}
	local blockedWashTypesStr = getXMLString(self.xmlFile, "vehicle.washable#blockedWashTypes")

	if blockedWashTypesStr ~= nil then
		local blockedWashTypes = StringUtil.splitString(" ", blockedWashTypesStr)

		for _, typeStr in pairs(blockedWashTypes) do
			typeStr = "WASHTYPE_" .. typeStr

			if Washable[typeStr] ~= nil then
				spec.blockedWashTypes[Washable[typeStr]] = true
			else
				g_logManager:xmlWarning(self.configFileName, "Unknown wash type '%s' in '%s'", typeStr, "vehicle.washable#blockedWashTypes")
			end
		end
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Washable:onPostLoad(savegame)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for _, component in pairs(self.components) do
			self:addAllSubWashableNodes(component.node)
		end

		if savegame ~= nil and Washable.getIntervalMultiplier() ~= 0 then
			for i, nodeData in ipairs(spec.washableNodes) do
				local nodeKey = string.format("%s.washable.dirtNode(%d)", savegame.key, i - 1)
				local amount = Utils.getNoNil(getXMLFloat(savegame.xmlFile, nodeKey .. "#amount"), 0)

				self:setNodeDirtAmount(nodeData, amount, true)
			end
		else
			for _, nodeData in ipairs(spec.washableNodes) do
				self:setNodeDirtAmount(nodeData, 0, true)
			end
		end
	end
end

function Washable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for i, nodeData in ipairs(spec.washableNodes) do
			local nodeKey = string.format("%s.dirtNode(%d)", key, i - 1)

			setXMLFloat(xmlFile, nodeKey .. "#amount", self:getNodeDirtAmount(nodeData))
		end
	end
end

function Washable:onReadStream(streamId, connection)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for _, nodeData in ipairs(spec.washableNodes) do
			local dirtAmount = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE

			self:setNodeDirtAmount(nodeData, dirtAmount, true)
		end
	end
end

function Washable:onWriteStream(streamId, connection)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for _, nodeData in ipairs(spec.washableNodes) do
			streamWriteUIntN(streamId, math.floor(self:getNodeDirtAmount(nodeData) * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
		end
	end
end

function Washable:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_washable

	if connection:getIsServer() and spec.washableNodes ~= nil and streamReadBool(streamId) then
		for _, nodeData in ipairs(spec.washableNodes) do
			local dirtAmount = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE

			self:setNodeDirtAmount(nodeData, dirtAmount, true)
		end
	end
end

function Washable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_washable

	if not connection:getIsServer() and spec.washableNodes ~= nil and streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
		for _, nodeData in ipairs(spec.washableNodes) do
			streamWriteUIntN(streamId, math.floor(self:getNodeDirtAmount(nodeData) * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
		end
	end
end

function Washable:onUpdateTick(dt, isActive, isActiveForInput, isSelected)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil and self.isServer then
		for _, nodeData in ipairs(spec.washableNodes) do
			local changedAmount = nodeData.updateFunc(self, nodeData, dt)

			if changedAmount ~= 0 then
				self:setNodeDirtAmount(nodeData, self:getNodeDirtAmount(nodeData) + changedAmount)
			end
		end
	end
end

function Washable:updateDirtAmount(nodeData, dt)
	local spec = self.spec_washable
	local change = 0

	if self:getAllowsWashingByType(Washable.WASHTYPE_RAIN) then
		local weather = g_currentMission.environment.weather
		local rainScale = weather:getRainFallScale()
		local timeSinceLastRain = weather:getTimeSinceLastRain()

		if rainScale > 0.1 and timeSinceLastRain < 30 then
			local amount = self:getNodeDirtAmount(nodeData)

			if amount > 0.5 then
				change = -(dt / spec.washDuration)
			end
		end
	end

	local dirtMultiplier = self:getDirtMultiplier()

	if dirtMultiplier ~= 0 then
		change = dt * spec.dirtDuration * dirtMultiplier * Washable.getIntervalMultiplier()

		if GS_IS_MOBILE_VERSION and nodeData == spec.globalWashableNode then
			change = change * 2
		end
	end

	return change
end

function Washable:addDirtAmount(dirtAmount, force)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for _, nodeData in ipairs(spec.washableNodes) do
			self:setNodeDirtAmount(nodeData, self:getNodeDirtAmount(nodeData) + dirtAmount, force)
		end
	end
end

function Washable:getDirtAmount()
	local spec = self.spec_washable
	local dirtAmount = 0

	if spec.washableNodes ~= nil and #spec.washableNodes > 0 then
		for _, nodeData in ipairs(spec.washableNodes) do
			dirtAmount = dirtAmount + self:getNodeDirtAmount(nodeData)
		end

		dirtAmount = dirtAmount / #spec.washableNodes
	end

	return dirtAmount
end

function Washable:setNodeDirtAmount(nodeData, dirtAmount, force)
	local spec = self.spec_washable
	nodeData.dirtAmount = MathUtil.clamp(dirtAmount, 0, 1)
	local diff = nodeData.dirtAmountSent - nodeData.dirtAmount

	if Washable.SEND_THRESHOLD < math.abs(diff) or force then
		for _, node in pairs(nodeData.nodes) do
			local x, _, z, w = getShaderParameter(node, "RDT")

			setShaderParameter(node, "RDT", x, nodeData.dirtAmount, z, w, false)
		end

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)

			nodeData.dirtAmountSent = nodeData.dirtAmount
		end
	end
end

function Washable:getNodeDirtAmount(nodeData)
	return nodeData.dirtAmount
end

function Washable:addAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		local nodes = {}

		I3DUtil.getNodesByShaderParam(rootNode, "RDT", nodes, true)
		self:addWashableNodes(nodes)
	end

	self:addDirtAmount(0, true)
end

function Washable:addWashableNodes(nodes)
	for _, node in ipairs(nodes) do
		local isGlobal, updateFunc, customIndex, extraParams = self:validateWashableNode(node)

		if isGlobal then
			self:addToGlobalWashableNode(node)
		elseif updateFunc ~= nil then
			self:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
		end
	end
end

function Washable:validateWashableNode(node)
	return true, nil
end

function Washable:addToGlobalWashableNode(node)
	local spec = self.spec_washable

	if spec.washableNodes[1] ~= nil then
		table.insert(spec.washableNodes[1].nodes, node)
	end
end

function Washable:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
	local spec = self.spec_washable
	local nodeData = {}

	if customIndex ~= nil then
		if spec.washableNodesByIndex[customIndex] ~= nil then
			table.insert(spec.washableNodesByIndex[customIndex].nodes, node)

			return
		else
			spec.washableNodesByIndex[customIndex] = nodeData
		end
	end

	nodeData.nodes = {
		node
	}
	nodeData.updateFunc = updateFunc
	nodeData.dirtAmount = 0
	nodeData.dirtAmountSent = 0

	if extraParams ~= nil then
		for i, v in pairs(extraParams) do
			nodeData[i] = v
		end
	end

	table.insert(spec.washableNodes, nodeData)
end

function Washable:removeAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		local nodes = {}

		I3DUtil.getNodesByShaderParam(rootNode, "RDT", nodes)

		for _, node in pairs(nodes) do
			self:removeWashableNode(node)
		end
	end
end

function Washable:removeWashableNode(node)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil and node ~= nil then
		for _, nodeData in ipairs(spec.washableNodes) do
			ListUtil.removeElementFromList(nodeData.nodes, node)
		end
	end
end

function Washable:getDirtMultiplier()
	local spec = self.spec_washable
	local multiplier = 1

	if self:getLastSpeed() < 1 then
		multiplier = 0
	end

	if self:getIsOnField() then
		multiplier = multiplier * spec.fieldMultiplier
		local wetness = g_currentMission.environment.weather:getGroundWetness()

		if wetness > 0 then
			multiplier = multiplier * (1 + wetness)
		end
	end

	return multiplier
end

function Washable:getWorkDirtMultiplier()
	local spec = self.spec_washable

	return spec.workMultiplier
end

function Washable:getWashDuration()
	local spec = self.spec_washable

	return spec.washDuration
end

function Washable.getIntervalMultiplier()
	if g_currentMission.missionInfo.dirtInterval == 1 then
		return 0
	elseif g_currentMission.missionInfo.dirtInterval == 2 then
		return 0.25
	elseif g_currentMission.missionInfo.dirtInterval == 3 then
		return 0.5
	elseif g_currentMission.missionInfo.dirtInterval == 4 then
		return 1
	end
end

function Washable:getAllowsWashingByType(type)
	local spec = self.spec_washable

	return spec.blockedWashTypes[type] == nil
end

function Washable:updateDebugValues(values)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil and self.isServer then
		for i, nodeData in ipairs(spec.washableNodes) do
			local changedAmount = nodeData.updateFunc(self, nodeData, 3600000)

			table.insert(values, {
				name = "WashableNode" .. i,
				value = string.format("%.4f a/h (%.2f)", changedAmount, self:getNodeDirtAmount(nodeData))
			})
		end
	end
end
