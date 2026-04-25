ConfigurationUtil = {
	SEND_NUM_BITS = 6,
	SELECTOR_MULTIOPTION = 0,
	SELECTOR_COLOR = 1,
	addBoughtConfiguration = function (object, name, id)
		if g_configurationManager:getConfigurationIndexByName(name) ~= nil then
			if object.boughtConfigurations[name] == nil then
				object.boughtConfigurations[name] = {}
			end

			object.boughtConfigurations[name][id] = true
		end
	end,
	hasBoughtConfiguration = function (object, name, id)
		if object.boughtConfigurations[name] ~= nil and object.boughtConfigurations[name][id] then
			return true
		end

		return false
	end,
	setConfiguration = function (object, name, id)
		object.configurations[name] = id
	end,
	getColorByConfigId = function (object, configName, configId)
		local configId = object.configurations[configName]

		if configId ~= nil then
			local item = g_storeManager:getItemByXMLFilename(object.configFileName)
			local config = item.configurations[configName][configId]

			if config ~= nil then
				local r, g, b = unpack(config.color)

				return {
					r,
					g,
					b,
					config.material
				}
			end
		end

		return nil
	end,
	getMaterialByConfigId = function (object, configName, configId)
		local configId = object.configurations[configName]

		if configId ~= nil then
			local item = g_storeManager:getItemByXMLFilename(object.configFileName)
			local config = item.configurations[configName][configId]

			if config ~= nil then
				return config.material
			end
		end

		return nil
	end
}

function ConfigurationUtil.applyDesign(object, xmlFile, configDesignId)
	local designKey = string.format("vehicle.designConfigurations.designConfiguration(%d)", configDesignId - 1)

	if not hasXMLProperty(xmlFile, designKey) then
		print("Warning: Invalid design configuration " .. configDesignId)

		return
	end

	local i = 0

	while true do
		local materialKey = string.format(designKey .. ".material(%d)", i)

		if not hasXMLProperty(xmlFile, materialKey) then
			break
		end

		local baseMaterialNode = I3DUtil.indexToObject(object.components, getXMLString(xmlFile, materialKey .. "#node"), object.i3dMappings)
		local refMaterialNode = I3DUtil.indexToObject(object.components, getXMLString(xmlFile, materialKey .. "#refNode"), object.i3dMappings)

		if baseMaterialNode ~= nil and refMaterialNode ~= nil then
			local oldMaterial = getMaterial(baseMaterialNode, 0)
			local newMaterial = getMaterial(refMaterialNode, 0)

			for _, component in pairs(object.components) do
				ConfigurationUtil.replaceMaterialRec(object, component.node, oldMaterial, newMaterial)
			end
		end

		local materialName = getXMLString(xmlFile, materialKey .. "#name")

		if materialName ~= nil then
			local shaderParameterName = getXMLString(xmlFile, materialKey .. "#shaderParameter")

			if shaderParameterName ~= nil then
				local colorStr = getXMLString(xmlFile, materialKey .. "#color")

				if colorStr ~= nil then
					local color = g_brandColorManager:getBrandColorByName(colorStr)

					if color == nil then
						color = ConfigurationUtil.getColorFromString(colorStr)
					end

					if color ~= nil then
						local materialId = getXMLInt(xmlFile, materialKey .. "#materialId")

						if object.setBaseMaterialColor ~= nil then
							object:setBaseMaterialColor(materialName, shaderParameterName, color, materialId)
						end
					end
				end
			end
		end

		i = i + 1
	end

	ObjectChangeUtil.updateObjectChanges(xmlFile, "vehicle.designConfigurations.designConfiguration", configDesignId, object.components, object)
end

function ConfigurationUtil.replaceMaterialRec(object, node, oldMaterial, newMaterial)
	if getHasClassId(node, ClassIds.SHAPE) then
		local nodeMaterial = getMaterial(node, 0)

		if nodeMaterial == oldMaterial then
			setMaterial(node, newMaterial, 0)
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			ConfigurationUtil.replaceMaterialRec(object, getChildAt(node, i), oldMaterial, newMaterial)
		end
	end
end

function ConfigurationUtil.setColor(object, xmlFile, configName, configColorId)
	local color = ConfigurationUtil.getColorByConfigId(object, configName, configColorId)

	if color ~= nil then
		local r, g, b, mat = unpack(color)
		local i = 0

		while true do
			local colorKey = string.format("vehicle.%sConfigurations.colorNode(%d)", configName, i)

			if not hasXMLProperty(xmlFile, colorKey) then
				break
			end

			local node = I3DUtil.indexToObject(object.components, getXMLString(xmlFile, colorKey .. "#node"), object.i3dMappings)

			if node ~= nil then
				if getHasClassId(node, ClassIds.SHAPE) then
					if mat == nil then
						_, _, _, mat = getShaderParameter(node, "colorScale")
					end

					if Utils.getNoNil(getXMLBool(xmlFile, colorKey .. "#recursive"), false) then
						I3DUtil.setShaderParameterRec(node, "colorScale", r, g, b, mat)
					else
						setShaderParameter(node, "colorScale", r, g, b, mat, false)
					end
				else
					print("Warning: Could not set vehicle color to '" .. getName(node) .. "' because node is not a shape!")
				end
			end

			i = i + 1
		end
	end
end

function ConfigurationUtil.getConfigurationValue(xmlFile, key, subKey, param, xmlFunc, defaultValue, fallbackConfigKey, fallbackOldKey)
	if type(subKey) == "table" then
		printCallstack()
	end

	local value = nil

	if key ~= nil then
		value = xmlFunc(xmlFile, key .. subKey .. param)
	end

	if value == nil and fallbackConfigKey ~= nil then
		value = xmlFunc(xmlFile, fallbackConfigKey .. subKey .. param)
	end

	if value == nil and fallbackOldKey ~= nil then
		value = xmlFunc(xmlFile, fallbackOldKey .. subKey .. param)
	end

	return Utils.getNoNil(value, defaultValue)
end

function ConfigurationUtil.getXMLConfigurationKey(xmlFile, index, key, defaultKey, configurationKey)
	local configIndex = Utils.getNoNil(index, 1)
	local configKey = string.format(key .. "(%d)", configIndex - 1)

	if index ~= nil and not hasXMLProperty(xmlFile, configKey) then
		print("Warning: Invalid " .. configurationKey .. " index '" .. tostring(index) .. "' in '" .. key .. "'. Using default " .. configurationKey .. " settings instead!")
	end

	if not hasXMLProperty(xmlFile, configKey) then
		configKey = key .. "(0)"
	end

	if not hasXMLProperty(xmlFile, configKey) then
		configKey = defaultKey
	end

	return configKey, configIndex
end

function ConfigurationUtil.getConfigColorSingleItemLoad(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	local colorStr = Utils.getNoNil(getXMLString(xmlFile, baseXMLName .. "#color"), "1 1 1 1")
	local color = g_brandColorManager:getBrandColorByName(colorStr)

	if color == nil then
		color = ConfigurationUtil.getColorFromString(colorStr)
	end

	configItem.color = color
	configItem.material = getXMLInt(xmlFile, baseXMLName .. "#material")
	configItem.name = XMLUtil.getXMLI18NValue(xmlFile, baseXMLName .. "#name", getXMLString, "", "", customEnvironment, false)
end

function ConfigurationUtil.getConfigColorPostLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	local defaultColorIndex = getXMLInt(xmlFile, baseKey .. "#defaultColorIndex")

	if Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#useDefaultColors"), false) then
		local price = Utils.getNoNil(getXMLInt(xmlFile, baseKey .. "#price"), 1000)

		for i, color in pairs(g_vehicleColors) do
			local configItem = StoreItemUtil.addConfigurationItem(configurationItems, "", "", price, 0, false)

			if color.r ~= nil and color.g ~= nil and color.b ~= nil then
				configItem.color = {
					color.r,
					color.g,
					color.b,
					1
				}
			elseif color.brandColor ~= nil then
				configItem.color = g_brandColorManager:getBrandColorByName(color.brandColor)

				if configItem.color == nil then
					configItem.color = {
						1,
						1,
						1,
						1
					}

					g_logManager:warning("Unable to find brandColor '%s' in g_vehicleColors", color.brandColor)
				end
			end

			configItem.name = g_i18n:convertText(color.name)

			if i == defaultColorIndex then
				configItem.isDefault = true
				configItem.price = 0
			end
		end
	end

	if defaultColorIndex == nil then
		local defaultIsDefined = false

		for _, item in ipairs(configurationItems) do
			if item.isDefault ~= nil and item.isDefault then
				defaultIsDefined = true
			end
		end

		if not defaultIsDefined and #configurationItems > 0 then
			configurationItems[1].isDefault = true
			configurationItems[1].price = 0
		end
	end
end

function ConfigurationUtil.getConfigMaterialSingleItemLoad(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.color = ConfigurationUtil.getColorFromString(Utils.getNoNil(getXMLString(xmlFile, baseXMLName .. "#color"), "1 1 1 1"))
	configItem.material = getXMLInt(xmlFile, baseXMLName .. "#material")
end

function ConfigurationUtil.getStoreAddtionalConfigData(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.vehicleType = getXMLString(xmlFile, baseXMLName .. "#vehicleType")
end

function ConfigurationUtil.getColorFromString(colorString)
	if colorString ~= nil then
		if not g_brandColorManager:getBrandColorByName(colorString) then
			local colorVector = {
				StringUtil.getVectorFromString(colorString)
			}
		end

		if colorVector == nil or #colorVector < 3 or #colorVector > 4 then
			print("Error: Invalid color string '" .. colorString .. "'")

			return nil
		end

		return colorVector
	end

	return nil
end
