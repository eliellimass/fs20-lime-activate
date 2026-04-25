FoliageBending = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function FoliageBending.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeFromXML", FoliageBending.loadBendingNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeModifierFromXML", FoliageBending.loadBendingNodeModifierFromXML)
	SpecializationUtil.registerFunction(vehicleType, "activateBendingNodes", FoliageBending.activateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "deactivateBendingNodes", FoliageBending.deactivateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "getFoliageBendingNodeByIndex", FoliageBending.getFoliageBendingNodeByIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateFoliageBendingAttributes", FoliageBending.updateFoliageBendingAttributes)
end

function FoliageBending.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimationPart", FoliageBending.loadAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "initializeAnimationPart", FoliageBending.initializeAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "postInitializeAnimationPart", FoliageBending.postInitializeAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateAnimationPart", FoliageBending.updateAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "resetAnimationPartValues", FoliageBending.resetAnimationPartValues)
end

function FoliageBending.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishedWheelLoading", FoliageBending)
end

function FoliageBending:onLoad(savegame)
	local spec = self.spec_foliageBending
	spec.bendingNodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.foliageBending.bendingNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local bendingNode = {}

		if self:loadBendingNodeFromXML(self.xmlFile, key, bendingNode) then
			table.insert(spec.bendingNodes, bendingNode)

			bendingNode.index = #spec.bendingNodes
		end

		i = i + 1
	end
end

function FoliageBending:onPostLoad(savegame)
	local spec = self.spec_foliageBending

	if spec.bendingModifiers ~= nil then
		for _, modifier in ipairs(spec.bendingModifiers) do
			local index = modifier.index
			local bendingNode = spec.bendingNodes[index]

			if bendingNode ~= nil then
				bendingNode.minX = math.min(bendingNode.minX, modifier.minX or bendingNode.minX)
				bendingNode.maxX = math.max(bendingNode.maxX, modifier.maxX or bendingNode.maxX)
				bendingNode.minZ = math.min(bendingNode.minZ, modifier.minZ or bendingNode.minZ)
				bendingNode.maxZ = math.max(bendingNode.maxZ, modifier.maxZ or bendingNode.maxZ)
				bendingNode.yOffset = math.max(bendingNode.yOffset, modifier.yOffset or bendingNode.yOffset)
			else
				g_logManager:xmlWarning(self.configFileName, "Undefined bendingNode index '%d' for bending modifier '%s'!", index, modifier.key)
			end
		end

		spec.bendingModifiers = nil
	end
end

function FoliageBending:onDelete()
	self:deactivateBendingNodes()
end

function FoliageBending:loadBendingNodeFromXML(xmlFile, key, bendingNode)
	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		node = self.rootNode
	end

	bendingNode.node = node
	bendingNode.key = key
	bendingNode.minX = getXMLFloat(xmlFile, key .. "#minX") or -1
	bendingNode.maxX = getXMLFloat(xmlFile, key .. "#maxX") or 1
	bendingNode.minZ = getXMLFloat(xmlFile, key .. "#minZ") or -1
	bendingNode.maxZ = getXMLFloat(xmlFile, key .. "#maxZ") or 1
	bendingNode.yOffset = getXMLFloat(xmlFile, key .. "#yOffset") or 0

	return true
end

function FoliageBending:loadBendingNodeModifierFromXML(xmlFile, key)
	local modifier = {
		index = getXMLInt(xmlFile, key .. "#index")
	}

	if modifier.index == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing bending node index for bending modifier '%s'", key)

		return
	end

	modifier.minX = getXMLFloat(xmlFile, key .. "#minX")
	modifier.maxX = getXMLFloat(xmlFile, key .. "#maxX")
	modifier.minZ = getXMLFloat(xmlFile, key .. "#minZ")
	modifier.maxZ = getXMLFloat(xmlFile, key .. "#maxZ")
	modifier.yOffset = getXMLFloat(xmlFile, key .. "#yOffset")
	local spec = self.spec_foliageBending

	if spec.bendingModifiers == nil then
		spec.bendingModifiers = {}
	end

	table.insert(spec.bendingModifiers, modifier)
end

function FoliageBending:activateBendingNodes()
	local spec = self.spec_foliageBending

	for _, bendingNode in ipairs(spec.bendingNodes) do
		if bendingNode.id == nil and g_currentMission.foliageBendingSystem then
			bendingNode.id = g_currentMission.foliageBendingSystem:createRectangle(bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset, bendingNode.node)
		end
	end
end

function FoliageBending:deactivateBendingNodes()
	local spec = self.spec_foliageBending

	for _, bendingNode in ipairs(spec.bendingNodes) do
		if bendingNode.id ~= nil then
			g_currentMission.foliageBendingSystem:destroyObject(bendingNode.id)

			bendingNode.id = nil
		end
	end
end

function FoliageBending:getFoliageBendingNodeByIndex(index)
	return self.spec_foliageBending.bendingNodes[index]
end

function FoliageBending:updateFoliageBendingAttributes(index)
	local bendingNode = self:getFoliageBendingNodeByIndex(index)

	if bendingNode ~= nil and bendingNode.id ~= nil then
		g_currentMission.foliageBendingSystem:setRectangleAttributes(bendingNode.id, bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset)
	end
end

function FoliageBending:onActivate()
	self:activateBendingNodes()
end

function FoliageBending:onDeactivate()
	self:deactivateBendingNodes()
end

function FoliageBending:onFinishedWheelLoading(xmlFile, key)
	local i = 0

	while true do
		local bendingKey = string.format("%s.foliageBendingModifier(%d)", key, i)

		if not hasXMLProperty(xmlFile, bendingKey) then
			break
		end

		self:loadBendingNodeModifierFromXML(xmlFile, bendingKey)

		i = i + 1
	end
end

function FoliageBending:loadAnimationPart(superFunc, xmlFile, partKey, part)
	if not superFunc(self, xmlFile, partKey, part) then
		return false
	end

	local foliageBendingIndex = getXMLInt(xmlFile, partKey .. "#foliageBendingIndex")
	local startMinX = getXMLFloat(xmlFile, partKey .. "#startMinX")
	local endMinX = getXMLFloat(xmlFile, partKey .. "#endMinX")
	local startMaxX = getXMLFloat(xmlFile, partKey .. "#startMaxX")
	local endMaxX = getXMLFloat(xmlFile, partKey .. "#endMaxX")
	local startMinZ = getXMLFloat(xmlFile, partKey .. "#startMinZ")
	local endMinZ = getXMLFloat(xmlFile, partKey .. "#endMinZ")
	local startMaxZ = getXMLFloat(xmlFile, partKey .. "#startMaxZ")
	local endMaxZ = getXMLFloat(xmlFile, partKey .. "#endMaxZ")
	local startYOffset = getXMLFloat(xmlFile, partKey .. "#startYOffset")
	local endYOffset = getXMLFloat(xmlFile, partKey .. "#endYOffset")

	if foliageBendingIndex ~= nil then
		part.foliageBendingIndex = foliageBendingIndex

		if startMinX ~= nil then
			part.startMinX = startMinX
			part.endMinX = endMinX
		end

		if startMaxX ~= nil then
			part.startMaxX = startMaxX
			part.endMaxX = endMaxX
		end

		if startMinZ ~= nil then
			part.startMinZ = startMinZ
			part.endMinZ = endMinZ
		end

		if startMaxZ ~= nil then
			part.startMaxZ = startMaxZ
			part.endMaxZ = endMaxZ
		end

		if startYOffset ~= nil then
			part.startYOffset = startYOffset
			part.endYOffset = endYOffset
		end
	end

	return true
end

function FoliageBending:initializeAnimationPart(superFunc, animation, part, i, numParts)
	superFunc(self, animation, part, i, numParts)

	local function initializeParts(startName, endName, nextPartName, prevPartName)
		if part[endName] ~= nil then
			for j = i + 1, numParts do
				local part2 = animation.parts[j]

				if part.node == part2.node and part2[endName] ~= nil then
					if part.direction == part2.direction and part.startTime + part.duration > part2[startName] + 0.001 then
						g_logManager:xmlWarning(self.configFileName, "Overlapping foliagebending parts for node '%s' in animation '%s'", getName(part.node), animation.name)
					end

					part[nextPartName] = part2
					part2[prevPartName] = part

					if part2[startName] == nil then
						part2[startName] = part[endName]
					end

					break
				end
			end
		end
	end

	initializeParts("startMinX", "endMinX", "nextMinXPart", "prevMinXPart")
	initializeParts("startMaxX", "endMaxX", "nextMaxXPart", "prevMaxXPart")
	initializeParts("startMinZ", "endMinZ", "nextMinZPart", "prevMinZPart")
	initializeParts("startMaxZ", "endMaxZ", "nextMaxZPart", "prevMaxZPart")
	initializeParts("startYOffset", "endYOffset", "nextYOffsetPart", "prevYOffsetPart")
end

function FoliageBending:postInitializeAnimationPart(superFunc, animation, part, i, numParts)
	superFunc(self, animation, part, i, numParts)

	if part.foliageBendingIndex ~= nil then
		local defaultMinX = part.endMinX or 0
		local defaultMaxX = part.endMaxX or 0
		local defaultMinZ = part.endMinZ or 0
		local defaultMaxZ = part.endMaxZ or 0
		local defaultYOffset = part.endYOffset or 0
		local bendingNode = self:getFoliageBendingNodeByIndex(part.foliageBendingIndex)

		if bendingNode ~= nil then
			defaultMinX = bendingNode.minX
			defaultMaxX = bendingNode.maxX
			defaultMinZ = bendingNode.minZ
			defaultMaxZ = bendingNode.maxZ
			defaultYOffset = bendingNode.yOffset
		end

		if part.endMinX ~= nil and part.startMinX == nil then
			part.startMinX = defaultMinX
		end

		if part.endMaxX ~= nil and part.startMaxX == nil then
			part.startMaxX = defaultMaxX
		end

		if part.endMinZ ~= nil and part.startMinZ == nil then
			part.startMinZ = defaultMinZ
		end

		if part.endMaxZ ~= nil and part.startMaxZ == nil then
			part.startMaxZ = defaultMaxZ
		end

		if part.endYOffset ~= nil and part.startYOffset == nil then
			part.startYOffset = defaultYOffset
		end
	end
end

function FoliageBending:updateAnimationPart(superFunc, animation, part, durationToEnd, dtToUse, realDt)
	local hasPartChanged = superFunc(self, animation, part, durationToEnd, dtToUse, realDt)

	if part.foliageBendingIndex ~= nil then
		local function updatePart(currentName, startName, endName, nextPartName, prevPartName)
			if part[startName] ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part[nextPartName], part[prevPartName], animation, true)) then
				local destFactor = part[endName]

				if animation.currentSpeed < 0 then
					destFactor = part[startName]
				end

				if part.foliageBendingNode == nil then
					local foliageBendingNode = self:getFoliageBendingNodeByIndex(part.foliageBendingIndex)

					if foliageBendingNode == nil then
						g_logManager:xmlWarning(self.configFileName, "Could not update foliage bending node. No bending node defined for node '%s'!", getName(part.node))

						part[startName] = nil
						part.foliageBendingIndex = nil

						return hasPartChanged
					end

					part.foliageBendingNode = foliageBendingNode
					local invDuration = 1 / math.max(durationToEnd, 0.001)
					part.speedFoliageBending = (destFactor - foliageBendingNode[currentName]) * invDuration
				end

				local newValue = AnimatedVehicle.getMovedLimitedValue(part.foliageBendingNode[currentName], destFactor, part.speedFoliageBending, dtToUse)

				if newValue then
					part.foliageBendingNode[currentName] = newValue
					hasPartChanged = true
				end
			end
		end

		updatePart("minX", "startMinX", "endMinX", "nextMinXPart", "prevMinXPart")
		updatePart("maxX", "startMaxX", "endMaxX", "nextMaxXPart", "prevMaxXPart")
		updatePart("minZ", "startMinZ", "endMinZ", "nextMinZPart", "prevMinZPart")
		updatePart("maxZ", "startMaxZ", "endMaxZ", "nextMaxZPart", "prevMaxZPart")
		updatePart("yOffset", "startYOffset", "endYOffset", "nextYOffsetPart", "prevYOffsetPart")
		self:updateFoliageBendingAttributes(part.foliageBendingIndex)
	end

	return hasPartChanged
end

function FoliageBending:resetAnimationPartValues(superFunc, part)
	superFunc(self, part)

	part.foliageBendingNode = nil
end
