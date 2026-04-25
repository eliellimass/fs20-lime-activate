GroundReference = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
	end
}

function GroundReference.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundReferenceNode", GroundReference.loadGroundReferenceNode)
	SpecializationUtil.registerFunction(vehicleType, "updateGroundReferenceNode", GroundReference.updateGroundReferenceNode)
	SpecializationUtil.registerFunction(vehicleType, "getGroundReferenceNodeFromIndex", GroundReference.getGroundReferenceNodeFromIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsGroundReferenceNodeActive", GroundReference.getIsGroundReferenceNodeActive)
end

function GroundReference.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerMultiplier", GroundReference.getPowerMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", GroundReference.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", GroundReference.getIsSpeedRotatingPartActive)
end

function GroundReference.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", GroundReference)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", GroundReference)
end

function GroundReference:onLoad(savegame)
	local spec = self.spec_groundReference
	spec.hasForceFactors = false
	spec.groundReferenceNodes = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.groundReferenceNodes.groundReferenceNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local entry = {}

		if self:loadGroundReferenceNode(self.xmlFile, baseName, entry) then
			table.insert(spec.groundReferenceNodes, entry)
		end

		i = i + 1
	end

	local totalCharge = 0

	for _, refNode in pairs(spec.groundReferenceNodes) do
		totalCharge = totalCharge + refNode.chargeValue
	end

	if totalCharge > 0 then
		for _, refNode in pairs(spec.groundReferenceNodes) do
			refNode.chargeValue = refNode.chargeValue / totalCharge
		end
	end

	local forceFactorSum = 0

	for _, refNode in pairs(spec.groundReferenceNodes) do
		forceFactorSum = forceFactorSum + refNode.forceFactor
	end

	if forceFactorSum > 0 then
		for _, refNode in pairs(spec.groundReferenceNodes) do
			refNode.forceFactor = refNode.forceFactor / forceFactorSum
		end
	end
end

function GroundReference:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_groundReference

	if connection:getIsServer() then
		for _, groundReferenceNode in ipairs(spec.groundReferenceNodes) do
			groundReferenceNode.isActive = streamReadBool(streamId)
		end
	end
end

function GroundReference:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_groundReference

	if not connection:getIsServer() then
		for _, groundReferenceNode in ipairs(spec.groundReferenceNodes) do
			streamWriteBool(streamId, groundReferenceNode.isActive)
		end
	end
end

function GroundReference:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_groundReference

	for _, groundReferenceNode in ipairs(spec.groundReferenceNodes) do
		self:updateGroundReferenceNode(groundReferenceNode)
	end
end

function GroundReference:loadGroundReferenceNode(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#index", baseName .. "#node")

	local spec = self.spec_groundReference
	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#node"), self.i3dMappings)

	if node ~= nil then
		entry.node = node
		entry.threshold = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#threshold"), 0)
		entry.chargeValue = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#chargeValue"), 1)
		entry.forceFactor = getXMLFloat(xmlFile, baseName .. "#forceFactor")

		if entry.forceFactor ~= nil then
			spec.hasForceFactors = true
		end

		entry.forceFactor = entry.forceFactor or 1
		entry.maxActivationDepth = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#maxActivationDepth"), 10)
		entry.isActive = false

		return true
	end

	return false
end

function GroundReference:updateGroundReferenceNode(groundReferenceNode)
	if self.isServer then
		local x, y, z = getWorldTranslation(groundReferenceNode.node)
		local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
		local terrainDiff = terrainHeight + groundReferenceNode.threshold - y
		local terrainActiv = terrainDiff > 0 and terrainDiff < groundReferenceNode.maxActivationDepth
		local densityHeight, _ = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
		local densityDiff = densityHeight + groundReferenceNode.threshold - y
		local densityActiv = densityDiff > 0 and densityDiff < groundReferenceNode.maxActivationDepth
		groundReferenceNode.isActive = terrainActiv or densityActiv
	end
end

function GroundReference:getGroundReferenceNodeFromIndex(refNodeIndex)
	local spec = self.spec_groundReference

	return spec.groundReferenceNodes[refNodeIndex]
end

function GroundReference:getIsGroundReferenceNodeActive(groundReferenceNode)
	return groundReferenceNode.isActive
end

function GroundReference:getPowerMultiplier(superFunc)
	local powerMultiplier = superFunc(self)
	local spec = self.spec_groundReference

	if #spec.groundReferenceNodes > 0 then
		local factor = 0

		if spec.hasForceFactors then
			for _, refNode in ipairs(spec.groundReferenceNodes) do
				if refNode.isActive then
					factor = factor + refNode.forceFactor
				end
			end
		else
			for _, refNode in ipairs(spec.groundReferenceNodes) do
				if refNode.isActive then
					factor = refNode.chargeValue
				end
			end
		end

		powerMultiplier = powerMultiplier * factor
	end

	return powerMultiplier
end

function GroundReference:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#refNodeIndex", key .. "#groundReferenceNodeIndex")

	speedRotatingPart.groundReferenceNodeIndex = getXMLInt(xmlFile, key .. "#groundReferenceNodeIndex")

	if speedRotatingPart.groundReferenceNodeIndex ~= nil and speedRotatingPart.groundReferenceNodeIndex == 0 then
		g_logManager:xmlWarning(self.configFileName, "Unknown ground reference node index '%d' in '%s'! Indices start with 1!", speedRotatingPart.groundReferenceNodeIndex, key)
	end

	return true
end

function GroundReference:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.groundReferenceNodeIndex ~= nil then
		local spec = self.spec_groundReference

		if spec.groundReferenceNodes[speedRotatingPart.groundReferenceNodeIndex] ~= nil then
			if not spec.groundReferenceNodes[speedRotatingPart.groundReferenceNodeIndex].isActive then
				return false
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown ground reference node index '%d' for speed rotating part '%s'! Indices start with 1!", speedRotatingPart.groundReferenceNodeIndex, getName(speedRotatingPart.repr or speedRotatingPart.shaderNode))

			speedRotatingPart.groundReferenceNodeIndex = nil
		end
	end

	return superFunc(self, speedRotatingPart)
end
