Ropes = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function Ropes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAdjusterNode", Ropes.loadAdjusterNode)
	SpecializationUtil.registerFunction(vehicleType, "updateRopes", Ropes.updateRopes)
	SpecializationUtil.registerFunction(vehicleType, "updateAdjusterNodes", Ropes.updateAdjusterNodes)
end

function Ropes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Ropes)
end

function Ropes:onLoad(savegame)
	local spec = self.spec_ropes

	if self.isClient then
		spec.ropes = {}
		local i = 0

		while true do
			local key = string.format("vehicle.ropes.rope(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local entry = {
				baseNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#baseNode"), self.i3dMappings),
				targetNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#targetNode"), self.i3dMappings),
				baseParameters = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, key .. "#baseParameters", 4)),
				targetParameters = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, key .. "#targetParameters", 4))
			}

			setShaderParameter(entry.baseNode, "cv0", entry.baseParameters[1], entry.baseParameters[2], entry.baseParameters[3], entry.baseParameters[4], false)
			setShaderParameter(entry.baseNode, "cv1", 0, 0, 0, 0, false)

			local x, y, z = localToLocal(entry.targetNode, entry.baseNode, entry.targetParameters[1], entry.targetParameters[2], entry.targetParameters[3])

			setShaderParameter(entry.baseNode, "cv3", x, y, z, 0, false)

			entry.baseParameterAdjusters = {}
			local j = 0

			while true do
				local adjusterKey = string.format("%s.baseParameterAdjuster(%d)", key, j)

				if not hasXMLProperty(self.xmlFile, adjusterKey) then
					break
				end

				local adjusterNode = {}

				if self:loadAdjusterNode(adjusterNode, self.xmlFile, adjusterKey) then
					table.insert(entry.baseParameterAdjusters, adjusterNode)
				end

				j = j + 1
			end

			entry.targetParameterAdjusters = {}
			j = 0

			while true do
				local adjusterKey = string.format("%s.targetParameterAdjuster(%d)", key, j)

				if not hasXMLProperty(self.xmlFile, adjusterKey) then
					break
				end

				local adjusterNode = {}

				if self:loadAdjusterNode(adjusterNode, self.xmlFile, adjusterKey) then
					table.insert(entry.targetParameterAdjusters, adjusterNode)
				end

				j = j + 1
			end

			table.insert(spec.ropes, entry)

			i = i + 1
		end
	end
end

function Ropes:onLoadFinished(savegame)
	if self.isClient then
		self:updateRopes(9999)
	end
end

function Ropes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		self:updateRopes(dt)
	end
end

function Ropes:loadAdjusterNode(adjusterNode, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node ~= nil then
		adjusterNode.node = node
		adjusterNode.rotationAxis = Utils.getNoNil(getXMLInt(xmlFile, key .. "#rotationAxis"), 1)
		adjusterNode.rotationRange = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotationRange"), 2)
		adjusterNode.translationAxis = Utils.getNoNil(getXMLInt(xmlFile, key .. "#translationAxis"), 1)
		adjusterNode.translationRange = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#translationRange"), 2)
		adjusterNode.minTargetParameters = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#minTargetParameters"), 4)

		if adjusterNode.minTargetParameters == nil then
			g_logManager:xmlWarning(self.configFileName, "Missing minTargetParameters attribute in '%s'", key)

			return false
		end

		adjusterNode.maxTargetParameters = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#maxTargetParameters"), 4)

		if adjusterNode.maxTargetParameters == nil then
			g_logManager:xmlWarning(self.configFileName, "Missing maxTargetParameters attribute in '%s'", key)

			return false
		end

		return true
	else
		g_logManager:xmlWarning(self.configFileName, "Missing node attribute in '%s'", key)
	end

	return false
end

function Ropes:updateRopes(dt)
	local spec = self.spec_ropes

	for _, rope in pairs(spec.ropes) do
		local x, y, z = self:updateAdjusterNodes(rope.baseParameterAdjusters)

		setShaderParameter(rope.baseNode, "cv0", rope.baseParameters[1] + x, rope.baseParameters[2] + y, rope.baseParameters[3] + z, 0, false)

		x, y, z = localToLocal(rope.targetNode, rope.baseNode, 0, 0, 0)

		setShaderParameter(rope.baseNode, "cv2", 0, 0, 0, 0, false)
		setShaderParameter(rope.baseNode, "cv3", x, y, z, 0, false)

		x, y, z = self:updateAdjusterNodes(rope.targetParameterAdjusters)
		x, y, z = localToLocal(rope.targetNode, rope.baseNode, rope.targetParameters[1] + x, rope.targetParameters[2] + y, rope.targetParameters[3] + z)

		setShaderParameter(rope.baseNode, "cv4", x, y, z, 0, false)
	end
end

function Ropes:updateAdjusterNodes(adjusterNodes)
	local xRet = 0
	local yRet = 0
	local zRet = 0

	for _, adjusterNode in pairs(adjusterNodes) do
		if adjusterNode.rotationAxis ~= nil and adjusterNode.rotationRange ~= nil then
			local rotations = {
				getRotation(adjusterNode.node)
			}
			local rot = rotations[adjusterNode.rotationAxis]
			local alpha = math.max(0, math.min(1, (rot - adjusterNode.rotationRange[1]) / (adjusterNode.rotationRange[2] - adjusterNode.rotationRange[1])))
			local x, y, z = MathUtil.vector3ArrayLerp(adjusterNode.minTargetParameters, adjusterNode.maxTargetParameters, alpha)
			zRet = zRet + z
			yRet = yRet + y
			xRet = xRet + x
		elseif adjusterNode.translationAxis ~= nil and adjusterNode.translationRange ~= nil then
			local translations = {
				getTranslation(adjusterNode.node)
			}
			local trans = translations[adjusterNode.translationAxis]
			local alpha = math.max(0, math.min(1, (trans - adjusterNode.translationRange[1]) / (adjusterNode.translationRange[2] - adjusterNode.translationRange[1])))
			local x, y, z = MathUtil.vector3ArrayLerp(adjusterNode.minTargetParameters, adjusterNode.maxTargetParameters, alpha)
			zRet = zRet + z
			yRet = yRet + y
			xRet = xRet + x
		end
	end

	return xRet, yRet, zRet
end
