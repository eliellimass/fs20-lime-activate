DynamicallyLoadedParts = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function DynamicallyLoadedParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicallyPartsFromXML", DynamicallyLoadedParts.loadDynamicallyPartsFromXML)
end

function DynamicallyLoadedParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicallyLoadedParts)
end

function DynamicallyLoadedParts:onLoad(savegame)
	local spec = self.spec_dynamicallyLoadedParts
	spec.parts = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local part = {}

		if self:loadDynamicallyPartsFromXML(part, self.xmlFile, baseName) then
			table.insert(spec.parts, part)
		end

		i = i + 1
	end
end

function DynamicallyLoadedParts:onDelete()
	local spec = self.spec_dynamicallyLoadedParts

	for _, part in pairs(spec.parts) do
		if part.filename ~= nil then
			g_i3DManager:releaseSharedI3DFile(part.filename, self.baseDirectory, true)
		end
	end
end

function DynamicallyLoadedParts:loadDynamicallyPartsFromXML(dynamicallyLoadedPart, xmlFile, key)
	local filename = getXMLString(xmlFile, key .. "#filename")

	if filename ~= nil then
		dynamicallyLoadedPart.filename = filename
		local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

		if i3dNode ~= 0 then
			local node = I3DUtil.indexToObject(i3dNode, Utils.getNoNil(getXMLString(xmlFile, key .. "#node"), "0|0"), self.i3dMappings)
			local linkNode = I3DUtil.indexToObject(self.components, Utils.getNoNil(getXMLString(xmlFile, key .. "#linkNode"), "0>"), self.i3dMappings)

			if linkNode == nil then
				g_logManager:xmlWarning(self.configFileName, "Failed to load dynamicallyLoadedPart '%s'. Unable to find linkNode", key)

				return false
			end

			local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#position"))

			if x ~= nil and y ~= nil and z ~= nil then
				setTranslation(node, x, y, z)
			end

			local rotationNode = I3DUtil.indexToObject(i3dNode, getXMLString(xmlFile, key .. "#rotationNode"), self.i3dMappings) or node
			local rotX, rotY, rotZ = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))

			if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
				rotX = MathUtil.degToRad(rotX)
				rotY = MathUtil.degToRad(rotY)
				rotZ = MathUtil.degToRad(rotZ)

				setRotation(rotationNode, rotX, rotY, rotZ)
			end

			local shaderParameterName = getXMLString(xmlFile, key .. "#shaderParameterName")
			local x, y, z, w = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#shaderParameter"))

			if shaderParameterName ~= nil and x ~= nil and y ~= nil and z ~= nil and w ~= nil then
				setShaderParameter(node, shaderParameterName, x, y, z, w, false)
			end

			link(linkNode, node)
			delete(i3dNode)

			return true
		end
	end

	return false
end
