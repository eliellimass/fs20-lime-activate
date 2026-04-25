GroundAdjustedNodes = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function GroundAdjustedNodes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAdjustedNodeFromXML", GroundAdjustedNodes.loadGroundAdjustedNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAdjustedRaycastNodeFromXML", GroundAdjustedNodes.loadGroundAdjustedRaycastNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsGroundAdjustedNodeActive", GroundAdjustedNodes.getIsGroundAdjustedNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "groundAdjustRaycastCallback", GroundAdjustedNodes.groundAdjustRaycastCallback)
end

function GroundAdjustedNodes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", GroundAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", GroundAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", GroundAdjustedNodes)
end

function GroundAdjustedNodes:onLoad(savegame)
	local spec = self.spec_groundAdjustedNodes
	spec.groundAdjustedNodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.groundAdjustedNodes.groundAdjustedNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local node = {}

		if self:loadGroundAdjustedNodeFromXML(self.xmlFile, key, node) then
			table.insert(spec.groundAdjustedNodes, node)
		end

		i = i + 1
	end
end

function GroundAdjustedNodes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_groundAdjustedNodes

	for _, adjustedNode in pairs(spec.groundAdjustedNodes) do
		if adjustedNode.targetY ~= adjustedNode.curY then
			if adjustedNode.curY < adjustedNode.targetY then
				adjustedNode.curY = math.min(adjustedNode.curY + adjustedNode.moveSpeed * dt, adjustedNode.targetY)
			else
				adjustedNode.curY = math.max(adjustedNode.curY - adjustedNode.moveSpeed * dt, adjustedNode.targetY)
			end

			setTranslation(adjustedNode.node, adjustedNode.x, adjustedNode.curY, adjustedNode.z)

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(adjustedNode.node)
			end
		end
	end
end

function GroundAdjustedNodes:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_groundAdjustedNodes

	for _, adjustedNode in ipairs(spec.groundAdjustedNodes) do
		if self:getIsGroundAdjustedNodeActive(adjustedNode) then
			local newY = adjustedNode.minY

			for _, raycastNode in ipairs(adjustedNode.raycastNodes) do
				local x, y, z = getWorldTranslation(raycastNode.node)
				local dx, dy, dz = localDirectionToWorld(raycastNode.node, 0, -1, 0)
				self.lastRaycastDistance = 0

				raycastClosest(x, y, z, dx, dy, dz, "groundAdjustRaycastCallback", 4, self)

				if self.lastRaycastDistance ~= 0 then
					newY = math.max(newY, adjustedNode.y - self.lastRaycastDistance + raycastNode.yDiff - adjustedNode.yOffset)
				end

				newY = MathUtil.clamp(newY, adjustedNode.minY, adjustedNode.maxY)
				adjustedNode.targetY = newY
				_, adjustedNode.curY, _ = getTranslation(adjustedNode.node)
			end
		end
	end
end

function GroundAdjustedNodes:loadGroundAdjustedNodeFromXML(xmlFile, key, adjustedNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for groundAdjustedNode '%s'!", key)

		return false
	end

	local x, y, z = getTranslation(node)
	adjustedNode.node = node
	adjustedNode.x = x
	adjustedNode.y = y
	adjustedNode.z = z
	adjustedNode.raycastNodes = {}
	local j = 0

	while true do
		local raycastKey = string.format("%s.raycastNode(%d)", key, j)

		if not hasXMLProperty(self.xmlFile, raycastKey) then
			break
		end

		local raycastNode = {}

		if self:loadGroundAdjustedRaycastNodeFromXML(xmlFile, raycastKey, adjustedNode, raycastNode) then
			table.insert(adjustedNode.raycastNodes, raycastNode)
		end

		j = j + 1
	end

	if #adjustedNode.raycastNodes > 0 then
		adjustedNode.minY = getXMLFloat(self.xmlFile, key .. "#minY") or y - 1
		adjustedNode.maxY = getXMLFloat(self.xmlFile, key .. "#maxY") or adjustedNode.minY + 1
		adjustedNode.yOffset = getXMLFloat(self.xmlFile, key .. "#yOffset") or 0
		adjustedNode.moveSpeed = (getXMLFloat(self.xmlFile, key .. "#moveSpeed") or 1) / 1000
		adjustedNode.targetY = y
		adjustedNode.curY = y
	else
		g_logManager:xmlWarning(self.configFileName, "No raycastNodes defined for groundAdjustedNode '%s'!", key)

		return false
	end

	return true
end

function GroundAdjustedNodes:loadGroundAdjustedRaycastNodeFromXML(xmlFile, key, groundAdjustedNode, raycastNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for groundAdjustedNodes raycast '%s'!", key)

		return false
	end

	if getParent(groundAdjustedNode.node) ~= getParent(node) then
		g_logManager:xmlWarning(self.configFileName, "Raycast node is not on the same hierarchy level as the groundAdjustedNode (%s)!", key)

		return false
	end

	local _, y1, _ = getTranslation(node)
	raycastNode.node = node
	raycastNode.yDiff = y1 - groundAdjustedNode.y

	return true
end

function GroundAdjustedNodes:getIsGroundAdjustedNodeActive(groundAdjustedNode)
	return true
end

function GroundAdjustedNodes:groundAdjustRaycastCallback(transformId, x, y, z, distance)
	self.lastRaycastDistance = distance
end
