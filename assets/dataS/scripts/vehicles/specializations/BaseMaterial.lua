BaseMaterial = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function BaseMaterial.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBaseMaterialFromXML", BaseMaterial.loadBaseMaterialFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBaseMaterialParameterFromXML", BaseMaterial.loadBaseMaterialParameterFromXML)
	SpecializationUtil.registerFunction(vehicleType, "applyBaseMaterialConfiguration", BaseMaterial.applyBaseMaterialConfiguration)
	SpecializationUtil.registerFunction(vehicleType, "applyBaseMaterial", BaseMaterial.applyBaseMaterial)
	SpecializationUtil.registerFunction(vehicleType, "setBaseMaterial", BaseMaterial.setBaseMaterial)
	SpecializationUtil.registerFunction(vehicleType, "setBaseMaterialColor", BaseMaterial.setBaseMaterialColor)
end

function BaseMaterial.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaseMaterial)
end

function BaseMaterial.initSpecialization()
	g_configurationManager:addConfigurationType("baseMaterial", g_i18n:getText("configuration_baseColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("designMaterial", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
end

function BaseMaterial:onLoad(savegame)
	local spec = self.spec_baseMaterial
	spec.baseMaterials = {}
	spec.nameToMaterial = {}
	local i = 0

	while true do
		local key = string.format("vehicle.baseMaterial.material(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local baseMaterial = {}

		if self:loadBaseMaterialFromXML(self.xmlFile, key, baseMaterial) then
			spec.nameToMaterial[baseMaterial.name] = baseMaterial

			table.insert(spec.baseMaterials, baseMaterial)
		end

		i = i + 1
	end

	if self.configurations.baseMaterial ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "baseMaterial", self.configurations.baseMaterial)
	end

	if self.configurations.designMaterial ~= nil then
		self:applyBaseMaterialConfiguration(self.xmlFile, "designMaterial", self.configurations.designMaterial)
	end

	self:applyBaseMaterial()
end

function BaseMaterial:loadBaseMaterialFromXML(xmlFile, key, material)
	local name = getXMLString(xmlFile, key .. "#name")

	if name == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing material name for base material '%s'", key)

		return false
	end

	if not ClassUtil.getIsValidIndexName(name) then
		g_logManager:xmlWarning(self.configFileName, "Given material name '%s' is not valid for material '%s'", name, key)

		return false
	end

	local baseNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#baseNode"), self.i3dMappings)

	if baseNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing baseNode base material '%s'", key)

		return false
	elseif not getHasClassId(baseNode, ClassIds.SHAPE) then
		g_logManager:xmlWarning(self.configFileName, "Material baseNode is not a shape '%s'", key)

		return false
	end

	material.name = name
	material.baseNode = baseNode
	material.materialId = getMaterial(baseNode, 0)
	material.nameToShaderParameter = {}
	material.shaderParameters = {}
	local i = 0

	while true do
		local parameterKey = string.format("%s.shaderParameter(%d)", key, i)

		if not hasXMLProperty(xmlFile, parameterKey) then
			break
		end

		local shaderParameter = {}

		if self:loadBaseMaterialParameterFromXML(xmlFile, parameterKey, shaderParameter, material.baseNode) then
			if material.nameToShaderParameter[shaderParameter.name] == nil then
				material.nameToShaderParameter[shaderParameter.name] = shaderParameter

				table.insert(material.shaderParameters, shaderParameter)
			else
				g_logManager:xmlWarning(self.configFileName, "shaderParameter '%s' already defined for material '%s'!", shaderParameter.name, key)
			end
		end

		i = i + 1
	end

	if #material.shaderParameters == 0 then
		g_logManager:xmlWarning(self.configFileName, "Missing shaderParameters for base material '%s'", key)

		return false
	end

	return true
end

function BaseMaterial:loadBaseMaterialParameterFromXML(xmlFile, key, shaderParameter, node)
	local name = getXMLString(xmlFile, key .. "#name")

	if name == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing shader parameter name for base material '%s'", key)

		return false
	end

	if not ClassUtil.getIsValidIndexName(name) then
		g_logManager:xmlWarning(self.configFileName, "Given shader parameter name '%s' is not valid for base material '%s'", name, key)

		return false
	end

	local value = g_brandColorManager:loadColorAndMaterialFromXML(self.configFileName, node, name, xmlFile, key)

	if value == nil then
		g_logManager:xmlWarning(self.configFileName, "Failed to load shader parameter value or material for base material '%s'", key)

		return false
	end

	shaderParameter.name = name
	shaderParameter.value = value

	return true
end

function BaseMaterial:applyBaseMaterial()
	local spec = self.spec_baseMaterial

	for _, material in ipairs(spec.baseMaterials) do
		for _, component in ipairs(self.components) do
			self:setBaseMaterial(component.node, material)
		end
	end
end

function BaseMaterial:setBaseMaterial(node, material)
	if getHasClassId(node, ClassIds.SHAPE) then
		local nodeMaterialId = getMaterial(node, 0)

		if material.materialId == nodeMaterialId then
			for i = #material.shaderParameters, 1, -1 do
				local parameter = material.shaderParameters[i]

				if getHasShaderParameter(node, parameter.name) then
					setShaderParameter(node, parameter.name, parameter.value[1], parameter.value[2], parameter.value[3], parameter.value[4], false)
				else
					g_logManager:xmlWarning(self.configFileName, "ShaderParameter '%s' not found for material '%s'!", parameter.name, material.name)
					table.remove(material.shaderParameters, i)
				end
			end
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			self:setBaseMaterial(getChildAt(node, i), material)
		end
	end
end

function BaseMaterial:applyBaseMaterialConfiguration(xmlFile, configName, configId)
	local spec = self.spec_baseMaterial
	local baseKey = string.format("vehicle.%sConfigurations", configName)
	local i = 0

	while true do
		local key = string.format("%s.material(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")

		if not ClassUtil.getIsValidIndexName(name) then
			g_logManager:xmlWarning(self.configFileName, "Given material name '%s' is not valid for material '%s'", name, key)

			return false
		end

		local shaderParameterName = getXMLString(xmlFile, key .. "#shaderParameter")

		if not ClassUtil.getIsValidIndexName(shaderParameterName) then
			g_logManager:xmlWarning(self.configFileName, "Given shader parameter '%s' is not valid for material '%s'", name, key)

			return false
		end

		local material = spec.nameToMaterial[name]

		if material == nil then
			g_logManager:xmlWarning(self.configFileName, "Given material name '%s' not found for material configuration '%s'", name, key)

			return false
		end

		local shaderParameter = material.nameToShaderParameter[shaderParameterName]

		if shaderParameter == nil then
			g_logManager:xmlWarning(self.configFileName, "Given shader parameter '%s' not found for material configuration '%s'", shaderParameterName, key)

			return false
		end

		local color = nil
		local colorStr = getXMLString(xmlFile, key .. "#color")

		if colorStr ~= nil then
			color = g_brandColorManager:getBrandColorByName(colorStr)

			if color == nil then
				color = ConfigurationUtil.getColorFromString(colorStr)
			end
		else
			color = ConfigurationUtil.getColorByConfigId(self, configName, configId)

			if color == nil then
				g_logManager(self.configFileName, "Color not found for configId '%d' for material configuration '%s'", configId, key)

				return false
			end
		end

		local materialId = getXMLInt(xmlFile, key .. "#material")
		materialId = materialId or ConfigurationUtil.getMaterialByConfigId(self, configName, configId)
		shaderParameter.value[1] = color[1]
		shaderParameter.value[2] = color[2]
		shaderParameter.value[3] = color[3]
		shaderParameter.value[4] = materialId or shaderParameter.value[4]

		if Utils.getNoNil(getXMLBool(xmlFile, key .. "#useContrastColor"), false) then
			local brightness = MathUtil.getBrightnessFromColor(color[1], color[2], color[3])
			local threshold = getXMLFloat(xmlFile, key .. "#contrastThreshold") or 0.5
			brightness = brightness > threshold and 1 or 0
			shaderParameter.value[1] = 1 - brightness
			shaderParameter.value[2] = 1 - brightness
			shaderParameter.value[3] = 1 - brightness
		end

		i = i + 1
	end
end

function BaseMaterial:setBaseMaterialColor(materialName, shaderParameterName, color, materialId)
	local spec = self.spec_baseMaterial
	local material = spec.nameToMaterial[materialName]

	if material ~= nil then
		local shaderParameter = material.nameToShaderParameter[shaderParameterName]

		if shaderParameter ~= nil then
			shaderParameter.value[1] = color[1]
			shaderParameter.value[2] = color[2]
			shaderParameter.value[3] = color[3]
			shaderParameter.value[4] = materialId or shaderParameter.value[4]
		end
	end

	self:applyBaseMaterial()
end
