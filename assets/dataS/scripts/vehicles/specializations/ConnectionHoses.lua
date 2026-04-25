ConnectionHoses = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function ConnectionHoses.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedConnectionHoses", ConnectionHoses.updateAttachedConnectionHoses)
	SpecializationUtil.registerFunction(vehicleType, "updateConnectionHose", ConnectionHoses.updateConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngle", ConnectionHoses.getCenterPointAngle)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngleRegulation", ConnectionHoses.getCenterPointAngleRegulation)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseSkipNode", ConnectionHoses.loadHoseSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "loadToolConnectorHoseNode", ConnectionHoses.loadToolConnectorHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "addHoseTargetNodes", ConnectionHoses.addHoseTargetNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseTargetNode", ConnectionHoses.loadHoseTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseNode", ConnectionHoses.loadHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getClonedSkipHoseNode", ConnectionHoses.getClonedSkipHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionTarget", ConnectionHoses.getConnectionTarget)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionTargetUsed", ConnectionHoses.getIsConnectionTargetUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionHoseUsed", ConnectionHoses.getIsConnectionHoseUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsSkipNodeAvailable", ConnectionHoses.getIsSkipNodeAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionHosesByInputAttacherJoint", ConnectionHoses.getConnectionHosesByInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "connectHose", ConnectionHoses.connectHose)
	SpecializationUtil.registerFunction(vehicleType, "disconnectHose", ConnectionHoses.disconnectHose)
	SpecializationUtil.registerFunction(vehicleType, "updateToolConnectionHose", ConnectionHoses.updateToolConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "addHoseToDelayedMountings", ConnectionHoses.addHoseToDelayedMountings)
	SpecializationUtil.registerFunction(vehicleType, "connectHoseToSkipNode", ConnectionHoses.connectHoseToSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "connectHosesToAttacherVehicle", ConnectionHoses.connectHosesToAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "retryHoseSkipNodeConnections", ConnectionHoses.retryHoseSkipNodeConnections)
end

function ConnectionHoses.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", ConnectionHoses)
end

function ConnectionHoses:onLoad(savegame)
	local spec = self.spec_connectionHoses
	spec.hoseSkipNodes = {}
	spec.hoseSkipNodeByType = {}
	local i = 0

	while true do
		local hoseKey = string.format("vehicle.connectionHoses.skipNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, hoseKey) then
			break
		end

		local entry = {}

		if self:loadHoseSkipNode(self.xmlFile, hoseKey, entry) then
			table.insert(spec.hoseSkipNodes, entry)

			if spec.hoseSkipNodeByType[entry.type] == nil then
				spec.hoseSkipNodeByType[entry.type] = {}
			end

			table.insert(spec.hoseSkipNodeByType[entry.type], entry)
		end

		i = i + 1
	end

	spec.targetNodes = {}
	spec.targetNodesByType = {}

	self:addHoseTargetNodes(self.xmlFile, "vehicle.connectionHoses.target")

	spec.toolConnectorHoses = {}
	spec.targetNodeToToolConnection = {}
	i = 0

	while true do
		local hoseKey = string.format("vehicle.connectionHoses.toolConnectorHose(%d)", i)

		if not hasXMLProperty(self.xmlFile, hoseKey) then
			break
		end

		local entry = {}

		if self:loadToolConnectorHoseNode(self.xmlFile, hoseKey, entry) then
			table.insert(spec.toolConnectorHoses, entry)

			spec.targetNodeToToolConnection[entry.startTargetNodeIndex] = entry
			spec.targetNodeToToolConnection[entry.endTargetNodeIndex] = entry
		end

		i = i + 1
	end

	spec.hoseNodes = {}
	spec.hoseNodesByInputAttacher = {}
	i = 0

	while true do
		local hoseKey = string.format("vehicle.connectionHoses.hose(%d)", i)

		if not hasXMLProperty(self.xmlFile, hoseKey) then
			break
		end

		local entry = {}

		if self:loadHoseNode(self.xmlFile, hoseKey, entry) then
			table.insert(spec.hoseNodes, entry)

			entry.index = #spec.hoseNodes

			for _, index in pairs(entry.inputAttacherJointIndices) do
				if spec.hoseNodesByInputAttacher[index] == nil then
					spec.hoseNodesByInputAttacher[index] = {}
				end

				table.insert(spec.hoseNodesByInputAttacher[index], entry)
			end
		end

		i = i + 1
	end

	spec.localHoseNodes = {}
	i = 0

	while true do
		local hoseKey = string.format("vehicle.connectionHoses.localHose(%d)", i)

		if not hasXMLProperty(self.xmlFile, hoseKey) then
			break
		end

		local hose = {}

		if self:loadHoseNode(self.xmlFile, hoseKey .. ".hose", hose) then
			local target = {}

			if self:loadHoseTargetNode(self.xmlFile, hoseKey .. ".target", target) then
				table.insert(spec.localHoseNodes, {
					hose = hose,
					target = target
				})
			end
		end

		i = i + 1
	end

	if #spec.targetNodes > 0 then
		spec.targetNodesAvailable = true
	end

	if #spec.hoseNodes > 0 then
		spec.hoseNodesAvailable = true
	end

	spec.updateableHoses = {}

	for _, localHoseNode in ipairs(spec.localHoseNodes) do
		self:connectHose(localHoseNode.hose, self, localHoseNode.target, false)
	end
end

function ConnectionHoses:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_connectionHoses

		for index, hose in ipairs(spec.updateableHoses) do
			if self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
				self:updateConnectionHose(hose, index)
			end
		end

		if self.getAttachedImplements ~= nil then
			for _, implement in ipairs(self:getAttachedImplements()) do
				if implement.object.updateAttachedConnectionHoses ~= nil then
					implement.object:updateAttachedConnectionHoses(self)
				end
			end
		end
	end
end

function ConnectionHoses:updateAttachedConnectionHoses(attacherVehicle)
	if self.isClient then
		local spec = self.spec_connectionHoses

		for index, hose in ipairs(spec.updateableHoses) do
			if hose.connectedObject == attacherVehicle and self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
				self:updateConnectionHose(hose, index)
			end
		end
	end
end

function ConnectionHoses:updateConnectionHose(hose, index)
	local p0x = 0
	local p0y = 0
	local p0z = -hose.startStraightening
	local p3x, p3y, p3z = localToLocal(hose.targetNode, hose.hoseNode, 0, 0, 0)
	local p4x, p4y, p4z = localToLocal(hose.targetNode, hose.hoseNode, 0, 0, hose.endStraightening)
	local p2x, p2y, p2z = nil

	if hose.isWorldSpaceHose then
		local w1x, w1y, w1z = getWorldTranslation(hose.hoseNode)
		local w2x, w2y, w2z = getWorldTranslation(hose.targetNode)
		p2x = (w1x + w2x) / 2
		p2y = (w1y + w2y) / 2
		p2z = (w1z + w2z) / 2
	else
		p2x = p3x / 2
		p2y = p3y / 2
		p2z = p3z / 2
	end

	local d = MathUtil.vector3Length(p3x, p3y, p3z)
	local lengthDifference = math.max(hose.length - d, 0)
	p2y = p2y - math.max(lengthDifference, 0.04 * d)

	if hose.isWorldSpaceHose then
		if hose.minDeltaY ~= math.huge then
			local x, y, z = worldToLocal(hose.minDeltaYComponent, p2x, p2y, p2z)
			local _, yTarget, _ = localToLocal(hose.minDeltaYComponent, hose.hoseNode, 0, 0, 0)
			p2x, p2y, p2z = localToWorld(hose.minDeltaYComponent, x, math.max(y, -yTarget + hose.minDeltaY), z)
		end

		p2x, p2y, p2z = worldToLocal(hose.hoseNode, p2x, p2y, p2z)
	end

	local angle1, angle2 = self:getCenterPointAngle(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, hose.isWorldSpaceHose)
	local centerPointAngle = angle1 + angle2

	if centerPointAngle < hose.minCenterPointAngle then
		p2x, p2y, p2z = self:getCenterPointAngleRegulation(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, angle1, angle2, hose.minCenterPointAngle, hose.isWorldSpaceHose)
	end

	if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
		p2x = MathUtil.clamp(p2x, hose.minCenterPointOffset[1], hose.maxCenterPointOffset[1])
		p2y = MathUtil.clamp(p2y, hose.minCenterPointOffset[2], hose.maxCenterPointOffset[2])
		p2z = MathUtil.clamp(p2z, hose.minCenterPointOffset[3], hose.maxCenterPointOffset[3])
	end

	local newX, newY, newZ = getWorldTranslation(hose.component)

	if hose.lastComponentPosition == nil or hose.lastComponentVelocity == nil then
		hose.lastComponentPosition = {
			newX,
			newY,
			newZ
		}
		hose.lastComponentVelocity = {
			newX,
			newY,
			newZ
		}
	end

	local newVelX = newX - hose.lastComponentPosition[1]
	local newVelY = newY - hose.lastComponentPosition[2]
	local newVelZ = newZ - hose.lastComponentPosition[3]
	hose.lastComponentPosition[3] = newZ
	hose.lastComponentPosition[2] = newY
	hose.lastComponentPosition[1] = newX
	local velX = newVelX - hose.lastComponentVelocity[1]
	local velY = newVelY - hose.lastComponentVelocity[2]
	local velZ = newVelZ - hose.lastComponentVelocity[3]
	hose.lastComponentVelocity[3] = newVelZ
	hose.lastComponentVelocity[2] = newVelY
	hose.lastComponentVelocity[1] = newVelX
	local worldX, worldY, worldZ = getWorldTranslation(hose.hoseNode)
	_, velY, velZ = worldToLocal(hose.hoseNode, worldX + velX, worldY + velY, worldZ + velZ)
	velY = MathUtil.clamp(velY * -hose.dampingFactor, -hose.dampingRange, hose.dampingRange) * lengthDifference
	velZ = MathUtil.clamp(velZ * -hose.dampingFactor, -hose.dampingRange, hose.dampingRange) * lengthDifference
	velY = velY * 0.1 + hose.lastVelY * 0.9
	velZ = velZ * 0.1 + hose.lastVelZ * 0.9
	hose.lastVelY = velY
	hose.lastVelZ = velZ
	p2z = p2z + velZ
	p2y = p2y + velY
	p2x = p2x

	if hose.isTwoPointHose then
		p2z = 0
		p2y = 0
		p2x = 0
	end

	setShaderParameter(hose.hoseNode, "cv2", p2x, p2y, p2z, 0, false)
	setShaderParameter(hose.hoseNode, "cv3", p3x, p3y, p3z, 0, false)
	setShaderParameter(hose.hoseNode, "cv4", p4x, p4y, p4z, 1, false)

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS and self:getIsActiveForInput() then
		local realLength = MathUtil.vector3Length(p2x, p2y, p2z)
		realLength = realLength + MathUtil.vector3Length(p2x - p3x, p2y - p3y, p2z - p3z)

		renderText(0.5, 0.9 - index * 0.02, 0.0175, string.format("hose %s:", getName(hose.node)))
		renderText(0.62, 0.9 - index * 0.02, 0.0175, string.format("directLength: %.2f configLength: %.2f realLength: %.2f angle: %.2f minAngle: %.2f", d, hose.length, realLength, math.deg(centerPointAngle), math.deg(hose.minCenterPointAngle)))

		local x1, y1, z1 = localToWorld(hose.hoseNode, p0x, p0y, p0z)
		local x2, y2, z2 = localToWorld(hose.hoseNode, 0, 0, 0)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, 0, 0, 0)
		x2, y2, z2 = localToWorld(hose.hoseNode, p2x, p2y, p2z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
		x2, y2, z2 = localToWorld(hose.hoseNode, p3x, p3y, p3z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
		x2, y2, z2 = localToWorld(hose.hoseNode, p4x, p4y, p4z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		local x0, y0, z0 = localToWorld(hose.hoseNode, p0x, p0y, p0z)
		x1, y1, z1 = localToWorld(hose.hoseNode, 0, 0, 0)
		x2, y2, z2 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
		local x3, y3, z3 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
		local x4, y4, z4 = localToWorld(hose.hoseNode, p4x, p4y, p4z)

		drawDebugPoint(x0, y0, z0, 1, 0, 0, 1)
		drawDebugPoint(x1, y1, z1, 1, 0, 0, 1)
		drawDebugPoint(x2, y2, z2, 1, 0, 0, 1)
		drawDebugPoint(x3, y3, z3, 1, 0, 0, 1)
		drawDebugPoint(x4, y4, z4, 1, 0, 0, 1)
		DebugUtil.drawDebugNode(hose.hoseNode)
		DebugUtil.drawDebugNode(hose.targetNode)
	end
end

function ConnectionHoses:getCenterPointAngle(node, cX, cY, cZ, eX, eY, eZ, useWorldSpace)
	local lengthStartToCenter = MathUtil.vector3Length(cX, cY, cZ)
	local lengthCenterToEnd = math.abs(MathUtil.vector3Length(cX - eX, cY - eY, cZ - eZ))
	local _, sY, _ = getWorldTranslation(node)

	if useWorldSpace then
		_, cY, _ = localToWorld(node, cX, cY, cZ)
		_, eY, _ = localToWorld(node, eX, eY, eZ)
	else
		sY = 0
	end

	local lengthStartToCenter2 = sY - cY
	local lengthCenterToEnd2 = eY - cY
	local angle1 = math.acos(lengthStartToCenter2 / lengthStartToCenter)
	local angle2 = math.acos(lengthCenterToEnd2 / lengthCenterToEnd)

	return angle1, angle2
end

function ConnectionHoses:getCenterPointAngleRegulation(node, cX, cY, cZ, eX, eY, eZ, angle1, angle2, targetAngle, useWorldSpace)
	local sX, sY, sZ = getWorldTranslation(node)

	if useWorldSpace then
		cX, _, cZ = localToWorld(node, cX, cY, cZ)
		eX, _, eZ = localToWorld(node, eX, eY, eZ)
	else
		sZ = 0
		sY = 0
		sX = 0
	end

	local startCenterLength = MathUtil.vector2Length(sX - cX, sZ - cZ)
	local centerEndLength = MathUtil.vector2Length(eX - cX, eZ - cZ)
	local pct = angle1 / (angle1 + angle2)
	local alpha = math.pi * 0.5 - pct * targetAngle
	local newY1 = math.tan(alpha) * startCenterLength
	local newY2 = math.tan(alpha) * centerEndLength
	local newY = (newY1 + newY2) / 2

	if useWorldSpace then
		return worldToLocal(node, cX, sY - newY, cZ)
	else
		return cX, sY - newY, cZ
	end
end

function ConnectionHoses:loadHoseSkipNode(xmlFile, targetKey, entry)
	entry.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, targetKey .. "#node"), self.i3dMappings)

	if entry.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing node for hose skip node '%s'", targetKey)

		return false
	end

	entry.inputAttacherJointIndex = Utils.getNoNil(getXMLInt(xmlFile, targetKey .. "#inputAttacherJointIndex"), 1)
	entry.attacherJointIndex = Utils.getNoNil(getXMLInt(xmlFile, targetKey .. "#attacherJointIndex"), 1)
	entry.type = getXMLString(xmlFile, targetKey .. "#type")

	if entry.type == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing type for hose skip node '%s'", targetKey)

		return false
	end

	entry.length = getXMLFloat(xmlFile, targetKey .. "#length")
	entry.isTwoPointHose = Utils.getNoNil(getXMLBool(xmlFile, targetKey .. "#isTwoPointHose"), false)
	entry.isSkipNode = true

	return true
end

function ConnectionHoses:loadToolConnectorHoseNode(xmlFile, targetKey, entry)
	local key = string.format("%s.startTarget", targetKey)
	entry.startTargetNodeIndex = self:addHoseTargetNodes(xmlFile, key)

	if entry.startTargetNodeIndex == nil then
		g_logManager:xmlWarning(self.configFileName, "startTarget is missing for tool connection hose '%s'", targetKey)

		return false
	end

	key = string.format("%s.endTarget", targetKey)
	entry.endTargetNodeIndex = self:addHoseTargetNodes(xmlFile, key)

	if entry.endTargetNodeIndex == nil then
		g_logManager:xmlWarning(self.configFileName, "endTarget is missing for tool connection hose '%s'", targetKey)

		return false
	end

	entry.mountingNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, targetKey .. "#mountingNode"), self.i3dMappings)

	if entry.mountingNode ~= nil then
		setVisibility(entry.mountingNode, false)
	end

	return true
end

function ConnectionHoses:addHoseTargetNodes(xmlFile, key)
	local spec = self.spec_connectionHoses
	local i = 0

	while true do
		local targetKey = string.format("%s(%d)", key, i)

		if not hasXMLProperty(xmlFile, targetKey) then
			break
		end

		local entry = {}

		if self:loadHoseTargetNode(xmlFile, targetKey, entry) then
			table.insert(spec.targetNodes, entry)

			entry.index = #spec.targetNodes

			if spec.targetNodesByType[entry.type] == nil then
				spec.targetNodesByType[entry.type] = {}
			end

			table.insert(spec.targetNodesByType[entry.type], entry)
		end

		i = i + 1
	end

	if i > 0 then
		return #spec.targetNodes
	end
end

function ConnectionHoses:loadHoseTargetNode(xmlFile, targetKey, entry)
	entry.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, targetKey .. "#node"), self.i3dMappings)

	if entry.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing node for connection hose target '%s'", targetKey)

		return false
	end

	local attacherJointIndices = {
		StringUtil.getVectorFromString(getXMLString(xmlFile, targetKey .. "#attacherJointIndices"))
	}
	entry.attacherJointIndices = {}

	for _, v in ipairs(attacherJointIndices) do
		entry.attacherJointIndices[v] = v
	end

	entry.type = getXMLString(xmlFile, targetKey .. "#type")
	entry.straighteningFactor = Utils.getNoNil(getXMLFloat(xmlFile, targetKey .. "#straighteningFactor"), 1)
	local socketName = getXMLString(xmlFile, targetKey .. "#socket")

	if socketName ~= nil then
		entry.socket = g_connectionHoseManager:linkSocketToNode(socketName, entry.node)
	end

	if entry.type ~= nil then
		entry.adapterName = Utils.getNoNil(getXMLString(xmlFile, targetKey .. "#adapterType"), "DEFAULT")

		if entry.adapter == nil then
			entry.adapter = {
				node = entry.node,
				refNode = entry.node
			}
		end

		entry.objectChanges = {}

		ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, targetKey, entry.objectChanges, self.components, self)
		ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)
	else
		g_logManager:xmlWarning(self.configFileName, "Missing type for '%s'", targetKey)

		return false
	end

	return true
end

function ConnectionHoses:loadHoseNode(xmlFile, hoseKey, entry)
	local inputAttacherJointIndices = {
		StringUtil.getVectorFromString(getXMLString(xmlFile, hoseKey .. "#inputAttacherJointIndices"))
	}
	entry.inputAttacherJointIndices = {}

	for _, v in ipairs(inputAttacherJointIndices) do
		entry.inputAttacherJointIndices[v] = v
	end

	entry.type = getXMLString(xmlFile, hoseKey .. "#type")

	if entry.type == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing type attribute in '%s'", hoseKey)

		return false
	end

	entry.hoseType = Utils.getNoNil(getXMLString(xmlFile, hoseKey .. "#hoseType"), "DEFAULT")
	entry.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, hoseKey .. "#node"), self.i3dMappings)

	if entry.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing node for connection hose '%s'", hoseKey)

		return false
	end

	entry.isTwoPointHose = Utils.getNoNil(getXMLBool(xmlFile, hoseKey .. "#isTwoPointHose"), false)
	entry.isWorldSpaceHose = Utils.getNoNil(getXMLBool(xmlFile, hoseKey .. "#isWorldSpaceHose"), true)
	entry.component = self:getParentComponent(entry.node)
	entry.lastVelY = 0
	entry.lastVelZ = 0
	entry.dampingRange = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#dampingRange"), 0.05)
	entry.dampingFactor = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#dampingFactor"), 50)
	entry.length = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#length"), 3)
	entry.diameter = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#diameter"), 0.02)
	entry.straighteningFactor = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#straighteningFactor"), 1)
	entry.minCenterPointAngle = Utils.getNoNilRad(getXMLFloat(xmlFile, hoseKey .. "#minCenterPointAngle"), nil)
	entry.minCenterPointOffset = StringUtil.getVectorNFromString(getXMLString(xmlFile, hoseKey .. "#minCenterPointOffset"), 3)
	entry.maxCenterPointOffset = StringUtil.getVectorNFromString(getXMLString(xmlFile, hoseKey .. "#maxCenterPointOffset"), 3)

	if entry.minCenterPointOffset ~= nil and entry.maxCenterPointOffset ~= nil then
		for i = 1, 3 do
			if entry.minCenterPointOffset[i] == 0 then
				entry.minCenterPointOffset[i] = -math.huge
			end

			if entry.maxCenterPointOffset[i] == 0 then
				entry.maxCenterPointOffset[i] = math.huge
			end
		end
	end

	entry.minDeltaY = Utils.getNoNil(getXMLFloat(xmlFile, hoseKey .. "#minDeltaY"), math.huge)
	entry.minDeltaYComponent = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, hoseKey .. "#minDeltaYComponent"), self.i3dMappings), entry.component)
	local colorValueStr = getXMLString(xmlFile, hoseKey .. "#color")
	entry.color = g_brandColorManager:getBrandColorByName(colorValueStr)

	if entry.color == nil then
		entry.color = StringUtil.getVectorNFromString(colorValueStr, 4)
	end

	local hose, startStraightening, endStraightening, minCenterPointAngle = g_connectionHoseManager:getClonedHoseNode(entry.type, entry.hoseType, entry.length, entry.diameter, entry.color)

	if hose ~= nil then
		link(entry.node, hose)
		setTranslation(hose, 0, 0, 0)
		setRotation(hose, 0, 0, 0)

		entry.hoseNode = hose
		entry.startStraightening = startStraightening * entry.straighteningFactor
		entry.endStraightening = endStraightening
		entry.endStraighteningBase = endStraightening
		entry.minCenterPointAngle = entry.minCenterPointAngle or minCenterPointAngle

		setVisibility(entry.hoseNode, false)
	else
		g_logManager:xmlWarning(self.configFileName, "Unable to find connection hose with length '%.2f' and diameter '%.2f' in '%s'", entry.length, entry.diameter, hoseKey)

		return false
	end

	entry.adapterName = getXMLString(xmlFile, hoseKey .. "#adapterType")
	entry.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, hoseKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)

	return true
end

function ConnectionHoses:getClonedSkipHoseNode(sourceHose, skipNode)
	local clonedHose = {
		isClonedSkipNodeHose = true,
		type = sourceHose.type,
		hoseType = sourceHose.hoseType,
		node = skipNode.node,
		component = self:getParentComponent(skipNode.node),
		lastVelY = 0,
		lastVelZ = 0,
		dampingRange = 0.05,
		dampingFactor = 50,
		minDeltaYComponent = self:getParentComponent(skipNode.node),
		minDeltaY = math.huge,
		length = skipNode.length or sourceHose.length,
		diameter = sourceHose.diameter,
		isTwoPointHose = skipNode.isTwoPointHose,
		color = sourceHose.color
	}
	local hose, startStraightening, endStraightening, minCenterPointAngle = g_connectionHoseManager:getClonedHoseNode(clonedHose.type, clonedHose.hoseType, clonedHose.length, clonedHose.diameter, clonedHose.color)

	if hose ~= nil then
		link(clonedHose.node, hose)
		setTranslation(hose, 0, 0, 0)
		setRotation(hose, 0, 0, 0)

		clonedHose.hoseNode = hose
		clonedHose.startStraightening = startStraightening
		clonedHose.endStraightening = endStraightening
		clonedHose.endStraighteningBase = endStraightening
		clonedHose.minCenterPointAngle = minCenterPointAngle

		setVisibility(clonedHose.hoseNode, false)
	else
		g_logManager:xmlWarning(self.configFileName, "Unable to find connection hose with length '%.2f' and diameter '%.2f' in '%s'", clonedHose.length, clonedHose.diameter, "skipHoseClone")

		return false
	end

	clonedHose.objectChanges = {}

	return clonedHose
end

function ConnectionHoses:getConnectionTarget(attacherJointIndex, type, excludeToolConnections)
	local spec = self.spec_connectionHoses

	if #spec.targetNodes == 0 and #spec.hoseSkipNodes == 0 then
		return nil
	end

	local nodes = spec.targetNodesByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if node.attacherJointIndices[attacherJointIndex] ~= nil and not self:getIsConnectionTargetUsed(node) then
				local toolConnectionHose = spec.targetNodeToToolConnection[node.index]

				if toolConnectionHose ~= nil and excludeToolConnections ~= nil and excludeToolConnections and toolConnectionHose.delayedMounting == nil then
					return nil
				end

				return node, false
			end
		end
	end

	nodes = spec.hoseSkipNodeByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if self:getIsSkipNodeAvailable(node) then
				return node, true
			end
		end
	end

	return nil
end

function ConnectionHoses:getIsConnectionTargetUsed(desc)
	return desc.connectedObject ~= nil
end

function ConnectionHoses:getIsConnectionHoseUsed(desc)
	return desc.connectedObject ~= nil
end

function ConnectionHoses:getIsSkipNodeAvailable(skipNode)
	if self.getAttacherVehicle == nil then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)
		local implement = attacherVehicle:getImplementFromAttacherJointIndex(attacherJointIndex)

		if implement.inputJointDescIndex == skipNode.inputAttacherJointIndex then
			return attacherVehicle:getConnectionTarget(attacherJointIndex, skipNode.type, true) ~= nil or skipNode.parentHose ~= nil
		end
	end

	return false
end

function ConnectionHoses:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
	local spec = self.spec_connectionHoses

	if spec.hoseNodesByInputAttacher[inputJointDescIndex] ~= nil then
		return spec.hoseNodesByInputAttacher[inputJointDescIndex]
	end

	return {}
end

function ConnectionHoses:connectHose(sourceHose, targetObject, targetHose, updateToolConnections)
	local spec = self.spec_connectionHoses
	local doConnect = false

	if updateToolConnections ~= nil and not updateToolConnections then
		doConnect = true
	elseif targetObject:updateToolConnectionHose(self, sourceHose, targetObject, targetHose, true) then
		doConnect = true
	else
		targetObject:addHoseToDelayedMountings(self, sourceHose, targetObject, targetHose)
	end

	if doConnect then
		targetHose.connectedObject = self
		sourceHose.connectedObject = targetObject
		sourceHose.targetHose = targetHose
		local node, referenceNode = nil

		if sourceHose.adapterName ~= nil then
			if sourceHose.adapterName ~= "NONE" then
				node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, sourceHose.adapterName)
			end
		elseif targetHose.adapterName ~= "NONE" then
			node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, targetHose.adapterName)
		end

		if node ~= nil then
			link(g_connectionHoseManager:getSocketTarget(targetHose.socket, targetHose.node), node)
			setTranslation(node, 0, 0, 0)
			setRotation(node, 0, 0, 0)
			targetObject:addAllSubWashableNodes(node)

			targetHose.adapter.node = node
			targetHose.adapter.refNode = referenceNode
			targetHose.adapter.isLinked = true
		end

		sourceHose.targetNode = targetHose.adapter.refNode

		setVisibility(sourceHose.hoseNode, true)
		setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)

		sourceHose.endStraightening = sourceHose.endStraighteningBase * targetHose.straighteningFactor

		ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, true)
		ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true)
		g_connectionHoseManager:openSocket(targetHose.socket)

		if targetHose.adapter == nil or targetHose.adapter.node == targetHose.adapter.refNode then
			self:removeAllSubWashableNodes(sourceHose.hoseNode)
			targetObject:addAllSubWashableNodes(sourceHose.hoseNode)
		end

		table.insert(spec.updateableHoses, sourceHose)
	end
end

function ConnectionHoses:disconnectHose(hose)
	local spec = self.spec_connectionHoses
	local target = hose.targetHose

	if target ~= nil then
		hose.connectedObject:updateToolConnectionHose(self, hose, hose.connectedObject, target, false)

		local hoseHasSkipNodeTarget = target.isSkipNode ~= nil and target.isSkipNode
		local hoseIsFromSkipNodeTarget = hose.isClonedSkipNodeHose ~= nil and hose.isClonedSkipNodeHose

		if hoseHasSkipNodeTarget or hoseIsFromSkipNodeTarget then
			if hose.parentVehicle ~= nil and hose.parentHose ~= nil then
				hose.parentHose.childVehicle = nil
				hose.parentHose.childHose = nil

				hose.parentVehicle:disconnectHose(hose.parentHose)
			end

			if hose.childVehicle ~= nil and hose.childHose ~= nil then
				hose.childHose.parentVehicle = nil
				hose.childHose.parentHose = nil

				hose.childVehicle:disconnectHose(hose.childHose)
			end

			setVisibility(hose.hoseNode, false)

			target.parentHose = nil
		else
			if target.adapter.isLinked ~= nil and target.adapter.isLinked then
				hose.connectedObject:removeAllSubWashableNodes(target.adapter.node)
				delete(target.adapter.node)

				target.adapter.node = target.node
				target.adapter.refNode = target.node
				target.adapter.isLinked = false
			end

			setVisibility(hose.hoseNode, false)
			ObjectChangeUtil.setObjectChanges(target.objectChanges, false)
			ObjectChangeUtil.setObjectChanges(hose.objectChanges, false)
			g_connectionHoseManager:closeSocket(target.socket)
		end

		if target.adapter == nil or target.adapter.node == target.adapter.refNode then
			hose.connectedObject:removeAllSubWashableNodes(hose.hoseNode)
			self:addAllSubWashableNodes(hose.hoseNode)
		end

		target.connectedObject = nil
		hose.connectedObject = nil
		hose.targetHose = nil

		ListUtil.removeElementFromList(spec.updateableHoses, hose)
	end
end

function ConnectionHoses:updateToolConnectionHose(sourceObject, sourceHose, targetObject, targetHose, visibility)
	local spec = self.spec_connectionHoses
	local toolConnectionHose = spec.targetNodeToToolConnection[targetHose.index]

	if toolConnectionHose ~= nil then
		local opositTargetIndex = toolConnectionHose.startTargetNodeIndex

		if opositTargetIndex == targetHose.index then
			opositTargetIndex = toolConnectionHose.endTargetNodeIndex
		end

		local opositTarget = spec.targetNodes[opositTargetIndex]

		if opositTarget ~= nil then
			if visibility and toolConnectionHose.delayedMounting ~= nil then
				local differentSource = toolConnectionHose.delayedMounting.sourceObject ~= sourceObject
				local sameType = toolConnectionHose.delayedMounting.sourceHose.type == sourceHose.type

				if differentSource and sameType then
					local x, y, z = localToLocal(targetHose.node, opositTarget.node, 0, 0, 0)
					local length = MathUtil.vector3Length(x, y, z)
					local hose, _, _, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, length, sourceHose.diameter, sourceHose.color)

					if hose ~= nil then
						link(targetHose.node, hose)
						setTranslation(hose, 0, 0, 0)

						local dirX, dirY, dirZ = localToLocal(hose, opositTarget.node, 0, 0, 0)

						setDirection(hose, dirX, dirY, dirZ, 0, 0, 1)
						setShaderParameter(hose, "cv0", 0, 0, -dirZ * 0.5, 0, false)
						setShaderParameter(hose, "cv2", dirX * 0.5 + 0.003, dirY * 0.5, dirZ * 0.5, 0, false)
						setShaderParameter(hose, "cv3", dirX - 0.003, dirY, dirZ, 0, false)
						setShaderParameter(hose, "cv4", dirX - 0.003, dirY, dirZ + dirZ * 0.5, 0, false)

						local function setTargetNodeTranslation(hose)
							if hose.originalNodeTranslation == nil then
								hose.originalNodeTranslation = {
									getTranslation(hose.node)
								}
							else
								setTranslation(hose.node, unpack(hose.originalNodeTranslation))
							end

							local wx, wy, wz = localToWorld(hose.node, 0, sourceHose.diameter * 0.5, 0)
							local lx, ly, lz = worldToLocal(getParent(hose.node), wx, wy, wz)

							setTranslation(hose.node, lx, ly, lz)
						end

						setTargetNodeTranslation(targetHose)
						setTargetNodeTranslation(opositTarget)
						self:addAllSubWashableNodes(hose)

						toolConnectionHose.hoseNode = hose

						if toolConnectionHose.mountingNode ~= nil then
							setVisibility(toolConnectionHose.mountingNode, true)
						end

						if toolConnectionHose.delayedMounting ~= nil then
							toolConnectionHose.delayedUnmounting = {}

							table.insert(toolConnectionHose.delayedUnmounting, toolConnectionHose.delayedMounting)
							table.insert(toolConnectionHose.delayedUnmounting, {
								sourceObject = sourceObject,
								sourceHose = sourceHose,
								targetObject = targetObject,
								targetHose = targetHose
							})

							local delayedHose = toolConnectionHose.delayedMounting
							toolConnectionHose.delayedMounting = nil

							delayedHose.sourceObject:connectHose(delayedHose.sourceHose, delayedHose.targetObject, delayedHose.targetHose, false)
							delayedHose.sourceObject:retryHoseSkipNodeConnections(false)
						end

						return true
					else
						return false
					end
				end
			elseif toolConnectionHose.hoseNode ~= nil then
				self:removeWashableNode(toolConnectionHose.hoseNode)
				delete(toolConnectionHose.hoseNode)

				toolConnectionHose.hoseNode = nil

				if toolConnectionHose.mountingNode ~= nil then
					setVisibility(toolConnectionHose.mountingNode, false)
				end

				if toolConnectionHose.delayedUnmounting ~= nil then
					for _, hose in ipairs(toolConnectionHose.delayedUnmounting) do
						if sourceHose ~= hose.sourceHose then
							hose.sourceObject:disconnectHose(hose.sourceHose)

							if hose.sourceHose.isClonedSkipNodeHose == nil or not hose.sourceHose.isClonedSkipNodeHose then
								toolConnectionHose.delayedMounting = hose
							end
						end
					end

					toolConnectionHose.delayedUnmounting = nil
				end
			end
		end
	else
		return true
	end

	return false
end

function ConnectionHoses:addHoseToDelayedMountings(sourceObject, sourceHose, targetObject, targetHose)
	local spec = self.spec_connectionHoses
	local toolConnectionHose = spec.targetNodeToToolConnection[targetHose.index]

	if toolConnectionHose ~= nil and toolConnectionHose.delayedMounting == nil then
		toolConnectionHose.delayedMounting = {
			sourceObject = sourceObject,
			sourceHose = sourceHose,
			targetObject = targetObject,
			targetHose = targetHose
		}
		local rootVehicle = self:getRootVehicle()

		rootVehicle:retryHoseSkipNodeConnections(true, sourceObject)
	end
end

function ConnectionHoses:connectHoseToSkipNode(sourceHose, targetObject, skipNode, childHose, childVehicle)
	local spec = self.spec_connectionHoses
	skipNode.connectedObject = self
	sourceHose.connectedObject = targetObject
	sourceHose.targetHose = skipNode
	sourceHose.targetNode = skipNode.node

	setVisibility(sourceHose.hoseNode, true)
	setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
	ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true)
	self:addAllSubWashableNodes(sourceHose.hoseNode)

	sourceHose.childVehicle = childVehicle
	sourceHose.childHose = childHose

	if self.getAttacherVehicle ~= nil then
		local attacherVehicle1 = self:getAttacherVehicle()

		if attacherVehicle1.getAttacherVehicle ~= nil then
			local attacherVehicle2 = attacherVehicle1:getAttacherVehicle()

			if attacherVehicle2 ~= nil then
				local attacherJointIndex = attacherVehicle2:getAttacherJointIndexFromObject(attacherVehicle1)
				local implement = attacherVehicle1:getImplementFromAttacherJointIndex(attacherJointIndex)

				if implement.inputJointDescIndex == skipNode.inputAttacherJointIndex then
					local firstValidTarget, isSkipNode = attacherVehicle2:getConnectionTarget(attacherJointIndex, skipNode.type)

					if firstValidTarget ~= nil then
						local hose = attacherVehicle1:getClonedSkipHoseNode(sourceHose, skipNode)

						if not isSkipNode then
							attacherVehicle1:connectHose(hose, attacherVehicle2, firstValidTarget)
						else
							attacherVehicle1:connectHoseToSkipNode(hose, attacherVehicle2, firstValidTarget, sourceHose, attacherVehicle1)
						end

						if skipNode.parentHose ~= nil then
							delete(skipNode.parentHose.hoseNode)
						end

						skipNode.parentVehicle = attacherVehicle1
						skipNode.parentHose = hose
						sourceHose.parentVehicle = attacherVehicle1
						sourceHose.parentHose = hose
						hose.childVehicle = self
						hose.childHose = sourceHose
					elseif skipNode.parentHose ~= nil then
						sourceHose.parentVehicle = skipNode.parentVehicle
						sourceHose.parentHose = skipNode.parentHose
						sourceHose.parentHose.childVehicle = self
						sourceHose.parentHose.childHose = sourceHose
					end
				end
			end
		end
	end

	table.insert(spec.updateableHoses, sourceHose)
end

function ConnectionHoses:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex, updateToolConnections, excludeVehicle)
	if attacherVehicle.getConnectionTarget ~= nil then
		local hoses = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)

		for _, hose in ipairs(hoses) do
			if not self:getIsConnectionHoseUsed(hose) then
				local firstValidTarget, isSkipNode = attacherVehicle:getConnectionTarget(jointDescIndex, hose.type)

				if firstValidTarget ~= nil then
					if not isSkipNode then
						self:connectHose(hose, attacherVehicle, firstValidTarget, updateToolConnections)
					else
						self:connectHoseToSkipNode(hose, attacherVehicle, firstValidTarget)
					end
				end
			end
		end

		self:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	end
end

function ConnectionHoses:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	if self.getAttachedImplements ~= nil then
		local attachedImplements = self:getAttachedImplements()

		for _, implement in ipairs(attachedImplements) do
			local object = implement.object

			if object ~= excludeVehicle and object.connectHosesToAttacherVehicle ~= nil then
				object:connectHosesToAttacherVehicle(self, implement.inputJointDescIndex, implement.jointDescIndex, updateToolConnections, excludeVehicle)
			end
		end
	end
end

function ConnectionHoses:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
end

function ConnectionHoses:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_connectionHoses
	local hoses = self:getConnectionHosesByInputAttacherJoint(self:getActiveInputAttacherJointDescIndex())

	for _, hose in ipairs(hoses) do
		self:disconnectHose(hose)
	end

	for _, hose in ipairs(spec.updateableHoses) do
		if hose.connectedObject == attacherVehicle then
			self:disconnectHose(hose)
		end
	end

	local attacherVehicleSpec = attacherVehicle.spec_connectionHoses

	if attacherVehicleSpec ~= nil then
		for _, toolConnector in pairs(attacherVehicleSpec.toolConnectorHoses) do
			if toolConnector.delayedMounting ~= nil and toolConnector.delayedMounting.sourceObject == self then
				toolConnector.delayedMounting = nil
			end
		end
	end
end
