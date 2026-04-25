JigglingParts = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function JigglingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadJigglingPartsFromXML", JigglingParts.loadJigglingPartsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "isJigglingPartActive", JigglingParts.isJigglingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "updateJigglingPart", JigglingParts.updateJigglingPart)
end

function JigglingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", JigglingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", JigglingParts)
end

function JigglingParts:onLoad(savegame)
	local spec = self.spec_jigglingParts
	spec.parts = {}
	local i = 0

	while true do
		local key = string.format("vehicle.jigglingParts.jigglingPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local jigglingPart = {}

		if self:loadJigglingPartsFromXML(jigglingPart, self.xmlFile, key) then
			table.insert(spec.parts, jigglingPart)
		end

		i = i + 1
	end
end

function JigglingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_jigglingParts

	for _, jigglingPart in ipairs(spec.parts) do
		if self:isJigglingPartActive(jigglingPart) then
			self:updateJigglingPart(jigglingPart, dt, true)
		elseif jigglingPart.currentAmplitudeScale > 0 then
			self:updateJigglingPart(jigglingPart, dt, false)
		end
	end
end

function JigglingParts:loadJigglingPartsFromXML(jigglingPart, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	jigglingPart.currentTime = 0
	jigglingPart.currentAmplitudeScale = 0
	jigglingPart.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if jigglingPart.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Failed to load node for jiggling part '%s'", key)

		return false
	end

	jigglingPart.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speedScale"), 1)
	jigglingPart.shaderParameter = Utils.getNoNil(getXMLString(xmlFile, key .. "#shaderParameter"), "amplFreq")
	jigglingPart.shaderParameterComponentSpeed = Utils.getNoNil(getXMLInt(xmlFile, key .. "#shaderParameterComponentSpeed"), 4)
	jigglingPart.shaderParameterComponentAmplitude = Utils.getNoNil(getXMLInt(xmlFile, key .. "#shaderParameterComponentAmplitude"), 1)
	jigglingPart.amplitudeScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#amplitudeScale"), 4)
	jigglingPart.refNodeIndex = getXMLInt(xmlFile, key .. "#refNodeIndex")

	return true
end

function JigglingParts:isJigglingPartActive(jigglingPart)
	if jigglingPart.refNodeIndex ~= nil and jigglingPart.refNode == nil then
		if self.getGroundReferenceNodeFromIndex ~= nil then
			local refNode = self:getGroundReferenceNodeFromIndex(jigglingPart.refNodeIndex)

			if refNode ~= nil then
				jigglingPart.refNode = refNode
			end
		end

		if jigglingPart.refNode == nil then
			g_logManager:xmlWarning(self.configFileName, "Unable to find ground reference node '%d' for jiggling part '%s'", jigglingPart.refNodeIndex, getName(jigglingPart.node))
		end

		jigglingPart.refNodeIndex = nil
	end

	if jigglingPart.refNode ~= nil and not self:getIsGroundReferenceNodeActive(jigglingPart.refNode) then
		return false
	end

	return true
end

function JigglingParts:updateJigglingPart(jigglingPart, dt, groundContact)
	local curValues = {
		getShaderParameter(jigglingPart.node, jigglingPart.shaderParameter)
	}
	local t = dt / 1000 * jigglingPart.speedScale * self:getLastSpeed() / 20
	jigglingPart.currentTime = jigglingPart.currentTime + t
	curValues[jigglingPart.shaderParameterComponentSpeed] = jigglingPart.currentTime

	if groundContact and jigglingPart.currentAmplitudeScale < 1 then
		jigglingPart.currentAmplitudeScale = math.min(jigglingPart.currentAmplitudeScale + dt / 100, 1)
	elseif not groundContact and jigglingPart.currentAmplitudeScale > 0 then
		jigglingPart.currentAmplitudeScale = math.max(jigglingPart.currentAmplitudeScale - dt / 100, 0)
	end

	curValues[jigglingPart.shaderParameterComponentAmplitude] = jigglingPart.currentAmplitudeScale * jigglingPart.amplitudeScale

	setShaderParameter(jigglingPart.node, jigglingPart.shaderParameter, curValues[1], curValues[2], curValues[3], curValues[4], false)
end
