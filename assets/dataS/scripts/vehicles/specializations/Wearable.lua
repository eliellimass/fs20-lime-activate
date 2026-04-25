source("dataS/scripts/vehicles/specializations/events/WearableRepairEvent.lua")

Wearable = {
	SEND_NUM_BITS = 6
}
Wearable.SEND_MAX_VALUE = 2^Wearable.SEND_NUM_BITS - 1
Wearable.SEND_THRESHOLD = 1 / Wearable.SEND_MAX_VALUE
Wearable.DAMAGE_CURVE = AnimCurve:new(linearInterpolator1)

Wearable.DAMAGE_CURVE:addKeyframe({
	0,
	time = 0
})
Wearable.DAMAGE_CURVE:addKeyframe({
	0,
	time = 0.3
})
Wearable.DAMAGE_CURVE:addKeyframe({
	1,
	time = 1
})

function Wearable.prerequisitesPresent(specializations)
	return true
end

function Wearable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateWearAmount", Wearable.updateWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "addWearAmount", Wearable.addWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeWearAmount", Wearable.setNodeWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "getNodeWearAmount", Wearable.getNodeWearAmount)
	SpecializationUtil.registerFunction(vehicleType, "addAllSubWearableNodes", Wearable.addAllSubWearableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addWearableNodes", Wearable.addWearableNodes)
	SpecializationUtil.registerFunction(vehicleType, "validateWearableNode", Wearable.validateWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToGlobalWearableNode", Wearable.addToGlobalWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToLocalWearableNode", Wearable.addToLocalWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "removeWearableNode", Wearable.removeWearableNode)
	SpecializationUtil.registerFunction(vehicleType, "getWearMultiplier", Wearable.getWearMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWorkWearMultiplier", Wearable.getWorkWearMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWearTotalAmount", Wearable.getWearTotalAmount)
	SpecializationUtil.registerFunction(vehicleType, "repairVehicle", Wearable.repairVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getUsageCausesWear", Wearable.getUsageCausesWear)
end

function Wearable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleDamage", Wearable.getVehicleDamage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepairPrice", Wearable.getRepairPrice)
end

function Wearable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wearable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Wearable)

	if not GS_IS_MOBILE_VERSION then
		SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wearable)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wearable)
	end
end

function Wearable:onLoad(savegame)
	local spec = self.spec_wearable
	spec.wearableNodes = {}
	spec.wearableNodesByIndex = {}

	self:addToLocalWearableNode(nil, Wearable.updateWearAmount, nil, )

	spec.wearDuration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.wearable#wearDuration"), 600) * 60 * 1000

	if spec.wearDuration ~= 0 then
		spec.wearDuration = 1 / spec.wearDuration
	end

	spec.totalAmount = 0
	spec.workMultiplier = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.wearable#workMultiplier"), 20)
	spec.fieldMultiplier = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.wearable#fieldMultiplier"), 2)
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Wearable:onPostLoad(savegame)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil then
		for _, component in pairs(self.components) do
			self:addAllSubWearableNodes(component.node)
		end

		if savegame ~= nil and Wearable.getIntervalMultiplier() ~= 0 then
			for i, nodeData in ipairs(spec.wearableNodes) do
				local nodeKey = string.format("%s.wearable.wearNode(%d)", savegame.key, i - 1)
				local amount = Utils.getNoNil(getXMLFloat(savegame.xmlFile, nodeKey .. "#amount"), 0)

				self:setNodeWearAmount(nodeData, amount, true)
			end
		else
			for _, nodeData in ipairs(spec.wearableNodes) do
				self:setNodeWearAmount(nodeData, 0, true)
			end
		end
	end
end

function Wearable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil then
		for i, nodeData in ipairs(spec.wearableNodes) do
			local nodeKey = string.format("%s.wearNode(%d)", key, i - 1)

			setXMLFloat(xmlFile, nodeKey .. "#amount", self:getNodeWearAmount(nodeData))
		end
	end
end

function Wearable:onReadStream(streamId, connection)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil then
		for _, nodeData in ipairs(spec.wearableNodes) do
			local wearAmount = streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE

			self:setNodeWearAmount(nodeData, wearAmount, true)
		end
	end
end

function Wearable:onWriteStream(streamId, connection)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil then
		for _, nodeData in ipairs(spec.wearableNodes) do
			streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
		end
	end
end

function Wearable:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_wearable

	if connection:getIsServer() and spec.wearableNodes ~= nil and streamReadBool(streamId) then
		for _, nodeData in ipairs(spec.wearableNodes) do
			local wearAmount = streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE

			self:setNodeWearAmount(nodeData, wearAmount, true)
		end
	end
end

function Wearable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_wearable

	if not connection:getIsServer() and spec.wearableNodes ~= nil and streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
		for _, nodeData in ipairs(spec.wearableNodes) do
			streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
		end
	end
end

function Wearable:onUpdateTick(dt, isActive, isActiveForInput, isSelected)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil and self.isServer then
		for _, nodeData in ipairs(spec.wearableNodes) do
			local changedAmount = nodeData.updateFunc(self, nodeData, dt)

			if changedAmount ~= 0 then
				self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + changedAmount)
			end
		end
	end
end

function Wearable:updateWearAmount(nodeData, dt)
	local spec = self.spec_wearable

	if self:getUsageCausesWear() then
		return dt * spec.wearDuration * self:getWearMultiplier(nodeData) * Wearable.getIntervalMultiplier()
	else
		return 0
	end
end

function Wearable:getUsageCausesWear()
	return self:getPropertyState() ~= Vehicle.PROPERTY_STATE_MISSION
end

function Wearable:addWearAmount(wearAmount, force)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil then
		for _, nodeData in ipairs(spec.wearableNodes) do
			self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + wearAmount, force)
		end
	end
end

function Wearable:setNodeWearAmount(nodeData, wearAmount, force)
	local spec = self.spec_wearable
	nodeData.wearAmount = MathUtil.clamp(wearAmount, 0, 1)
	local diff = nodeData.wearAmountSent - nodeData.wearAmount

	if Wearable.SEND_THRESHOLD < math.abs(diff) or force then
		for _, node in pairs(nodeData.nodes) do
			local _, y, z, w = getShaderParameter(node, "RDT")

			setShaderParameter(node, "RDT", nodeData.wearAmount, y, z, w, false)
		end

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)

			nodeData.wearAmountSent = nodeData.wearAmount
		end

		spec.totalAmount = 0

		for _, data in ipairs(spec.wearableNodes) do
			spec.totalAmount = spec.totalAmount + data.wearAmount
		end

		spec.totalAmount = spec.totalAmount / #spec.wearableNodes
	end
end

function Wearable:getNodeWearAmount(nodeData)
	return nodeData.wearAmount
end

function Wearable:getWearTotalAmount()
	return self.spec_wearable.totalAmount
end

function Wearable:repairVehicle(atSellingPoint)
	if self.isServer then
		g_currentMission:addMoney(-self:getRepairPrice(atSellingPoint), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)

		local spec = self.spec_wearable

		for _, data in ipairs(spec.wearableNodes) do
			self:setNodeWearAmount(data, 0, true)
		end

		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function Wearable:getRepairPrice(superFunc, atSellingPoint)
	local factor = 1

	if atSellingPoint ~= nil and atSellingPoint then
		factor = 1 / EconomyManager.DIRECT_SELL_MULTIPLIER
	end

	return superFunc(self) + self:getPrice() * self:getWearTotalAmount() / 100 * factor
end

function Wearable:getVehicleDamage(superFunc)
	return MathUtil.clamp(superFunc(self) + Wearable.DAMAGE_CURVE:get(self.spec_wearable.totalAmount), 0, 1)
end

function Wearable:addAllSubWearableNodes(rootNode)
	if rootNode ~= nil then
		local nodes = {}

		I3DUtil.getNodesByShaderParam(rootNode, "RDT", nodes)
		self:addWearableNodes(nodes)
	end
end

function Wearable:addWearableNodes(nodes)
	for _, node in pairs(nodes) do
		local isGlobal, updateFunc, customIndex, extraParams = self:validateWearableNode(node)

		if isGlobal then
			self:addToGlobalWearableNode(node)
		elseif updateFunc ~= nil then
			self:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
		end
	end
end

function Wearable:validateWearableNode(node)
	return true, nil
end

function Wearable:addToGlobalWearableNode(node)
	local spec = self.spec_wearable

	if spec.wearableNodes[1] ~= nil then
		table.insert(spec.wearableNodes[1].nodes, node)
	end
end

function Wearable:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
	local spec = self.spec_wearable
	local nodeData = {}

	if customIndex ~= nil then
		if spec.wearableNodesByIndex[customIndex] ~= nil then
			table.insert(spec.wearableNodesByIndex[customIndex].nodes, node)

			return
		else
			spec.wearableNodesByIndex[customIndex] = nodeData
		end
	end

	nodeData.nodes = {
		node
	}
	nodeData.updateFunc = updateFunc
	nodeData.wearAmount = 0
	nodeData.wearAmountSent = 0

	if extraParams ~= nil then
		for i, v in pairs(extraParams) do
			nodeData[i] = v
		end
	end

	table.insert(spec.wearableNodes, nodeData)
end

function Wearable:removeWearableNode(node)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil and node ~= nil then
		for _, nodeData in ipairs(spec.wearableNodes) do
			nodeData.nodes[node] = nil
		end
	end
end

function Wearable:getWearMultiplier()
	local spec = self.spec_wearable
	local multiplier = 1

	if self:getLastSpeed() < 1 then
		multiplier = 0
	end

	if self:getIsOnField() then
		multiplier = multiplier * spec.fieldMultiplier
	end

	return multiplier
end

function Wearable:getWorkWearMultiplier()
	local spec = self.spec_wearable

	return spec.workMultiplier
end

function Wearable.getIntervalMultiplier()
	return 0.5
end

function Wearable:updateDebugValues(values)
	local spec = self.spec_wearable

	if spec.wearableNodes ~= nil and self.isServer then
		for i, nodeData in ipairs(spec.wearableNodes) do
			local changedAmount = nodeData.updateFunc(self, nodeData, 3600000)

			table.insert(values, {
				name = "WearableNode" .. i,
				value = string.format("%.4f a/h (%.2f)", changedAmount, self:getNodeWearAmount(nodeData))
			})
		end
	end
end
