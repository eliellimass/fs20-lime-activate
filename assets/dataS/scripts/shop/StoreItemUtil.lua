StoreItemUtil = {
	getIsVehicle = function (storeItem)
		return storeItem ~= nil and (storeItem.species == nil or storeItem.species == "")
	end,
	getIsAnimal = function (storeItem)
		return storeItem ~= nil and storeItem.species ~= nil and storeItem.species ~= "" and storeItem.species ~= "placeable" and storeItem.species ~= "object" and storeItem.species ~= "handTool"
	end,
	getIsPlaceable = function (storeItem)
		return storeItem ~= nil and storeItem.species == "placeable"
	end,
	getIsObject = function (storeItem)
		return storeItem ~= nil and storeItem.species == "object"
	end,
	getIsHandTool = function (storeItem)
		return storeItem ~= nil and storeItem.species == "handTool"
	end,
	getIsConfigurable = function (storeItem)
		local hasConfigurations = storeItem ~= nil and storeItem.configurations ~= nil
		local hasMoreThanOneOption = false

		if hasConfigurations then
			for _, configItems in pairs(storeItem.configurations) do
				if #configItems > 1 then
					hasMoreThanOneOption = true

					break
				end
			end
		end

		return hasConfigurations and hasMoreThanOneOption
	end
}

function StoreItemUtil.getIsLeasable(storeItem)
	return storeItem ~= nil and storeItem.runningLeasingFactor ~= nil and not StoreItemUtil.getIsPlaceable(storeItem)
end

function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
	for k, item in pairs(storeItem.configurations[configurationName]) do
		if item.isDefault then
			return k
		end
	end

	return 1
end

function StoreItemUtil.getDefaultPrice(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "price")
end

function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end

function StoreItemUtil.getCosts(storeItem, configurations, costType)
	if storeItem ~= nil then
		local costs = storeItem[costType]

		if costs == nil then
			costs = 0
		end

		if storeItem.configurations ~= nil then
			for name, value in pairs(configurations) do
				local nameConfig = storeItem.configurations[name]

				if nameConfig ~= nil then
					local valueConfig = nameConfig[value]

					if valueConfig ~= nil then
						local costTypeConfig = valueConfig[costType]

						if costTypeConfig ~= nil then
							costs = costs + tonumber(costTypeConfig)
						end
					end
				end
			end
		end

		return costs
	end

	return 0
end

function StoreItemUtil.addConfigurationItem(configurationItems, name, desc, price, dailyUpkeep, isDefault, overwrittenTitle)
	local configItem = {
		name = name,
		desc = desc,
		price = price,
		dailyUpkeep = dailyUpkeep,
		isDefault = isDefault,
		overwrittenTitle = overwrittenTitle
	}

	table.insert(configurationItems, configItem)

	configItem.index = #configurationItems

	return configItem
end

function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
	local i = 0
	local functions = {}

	while true do
		local functionKey = string.format(storeDataXMLName .. ".functions.function(%d)", i)

		if not hasXMLProperty(xmlFile, functionKey) then
			break
		end

		local functionName = XMLUtil.getXMLI18NValue(xmlFile, functionKey, getXMLString, "", nil, customEnvironment, true)

		if functionName ~= nil then
			table.insert(functions, functionName)
		end

		i = i + 1
	end

	return functions
end

function StoreItemUtil.getSpecsFromXML(specTypes, xmlFile, customEnvironment)
	local specs = {}

	for _, specType in pairs(specTypes) do
		if specType.loadFunc ~= nil then
			specs[specType.name] = specType.loadFunc(xmlFile, customEnvironment)
		end
	end

	return specs
end

function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLName, xmlFilename)
	local brandName = Utils.getNoNil(getXMLString(xmlFile, storeDataXMLName .. ".brand"), "")
	local brand = nil

	if ClassUtil.getIsValidIndexName(brandName) then
		brand = g_brandManager:getBrandIndexByName(brandName)

		if brand == nil then
			print("Warning: '" .. brandName .. "' is an unknown brand! Using Lizard instead! (" .. xmlFilename .. ")")

			brand = Brand.LIZARD
		end
	else
		print("Warning: Invalid brand name '" .. brandName .. "' in " .. xmlFilename .. "! Only capital letters and underscores allowed. Using Lizard instead.")

		brand = Brand.LIZARD
	end

	return brand
end

function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
	local vertexBufferMemoryUsage = Utils.getNoNil(getXMLInt(xmlFile, storeDataXMLName .. ".vertexBufferMemoryUsage"), 0)
	local indexBufferMemoryUsage = Utils.getNoNil(getXMLInt(xmlFile, storeDataXMLName .. ".indexBufferMemoryUsage"), 0)
	local textureMemoryUsage = Utils.getNoNil(getXMLInt(xmlFile, storeDataXMLName .. ".textureMemoryUsage"), 0)
	local instanceVertexBufferMemoryUsage = Utils.getNoNil(getXMLInt(xmlFile, storeDataXMLName .. ".instanceVertexBufferMemoryUsage"), 0)
	local instanceIndexBufferMemoryUsage = Utils.getNoNil(getXMLInt(xmlFile, storeDataXMLName .. ".instanceIndexBufferMemoryUsage"), 0)
	local ignoreVramUsage = Utils.getNoNil(getXMLBool(xmlFile, storeDataXMLName .. ".ignoreVramUsage"), false)
	local perInstanceVramUsage = 0
	local sharedVramUsage = 0

	if GS_IS_CONSOLE_VERSION then
		perInstanceVramUsage = instanceVertexBufferMemoryUsage + instanceIndexBufferMemoryUsage
		sharedVramUsage = vertexBufferMemoryUsage + indexBufferMemoryUsage + textureMemoryUsage
	end

	return sharedVramUsage, perInstanceVramUsage, ignoreVramUsage
end

function StoreItemUtil.getConfigurationsFromXML(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	local configurations = {}
	local numConfigs = 0
	local configurationTypes = g_configurationManager:getConfigurationTypes()

	for _, name in pairs(configurationTypes) do
		local configuration = g_configurationManager:getConfigurationDescByName(name)
		local configurationItems = {}
		local i = 0
		local xmlKey = configuration.xmlKey

		if xmlKey ~= nil then
			xmlKey = "." .. xmlKey
		else
			xmlKey = ""
		end

		local baseKey = baseXMLName .. xmlKey .. "." .. name .. "Configurations"

		if configuration.preLoadFunc ~= nil then
			configuration.preLoadFunc(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems)
		end

		local overwrittenTitle = XMLUtil.getXMLI18NValue(xmlFile, baseKey .. "#title", getXMLString, nil, , customEnvironment, false)

		while true do
			if i > 2^ConfigurationUtil.SEND_NUM_BITS then
				print("Error: Maximum number of configurations are reached. Only " .. 2^ConfigurationUtil.SEND_NUM_BITS .. " configurations per type are allowed!")
			end

			local key = string.format(baseKey .. "." .. name .. "Configuration(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local name = XMLUtil.getXMLI18NValue(xmlFile, key .. "#name", getXMLString, nil, "", customEnvironment, true)
			local params = getXMLString(xmlFile, key .. "#params")

			if params ~= nil then
				local params = StringUtil.splitString("|", params)
				name = string.format(name, unpack(params))
			end

			local desc = XMLUtil.getXMLI18NValue(xmlFile, key .. "#desc", getXMLString, nil, "", customEnvironment, true)
			local price = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#price"), 0)
			local dailyUpkeep = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#dailyUpkeep"), 0)
			local isDefault = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDefault"), false)
			local configItem = StoreItemUtil.addConfigurationItem(configurationItems, name, desc, price, dailyUpkeep, isDefault, overwrittenTitle)

			if configuration.singleItemLoadFunc ~= nil then
				configuration.singleItemLoadFunc(xmlFile, key, baseDir, customEnvironment, isMod, configItem)
			end

			i = i + 1
		end

		if configuration.postLoadFunc ~= nil then
			configuration.postLoadFunc(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
		end

		if #configurationItems > 0 then
			configurations[name] = configurationItems
			numConfigs = numConfigs + 1
		end
	end

	if numConfigs == 0 then
		configurations = nil
	end

	return configurations
end

function StoreItemUtil.getConfigurationSetsFromXML(storeItem, xmlFile, baseXMLName, baseDir, customEnvironment, isMod)
	local configurationSetsKey = string.format("%s.configurationSets", baseXMLName)
	local overwrittenTitle = XMLUtil.getXMLI18NValue(xmlFile, configurationSetsKey .. "#title", getXMLString, nil, , customEnvironment, false)
	local configurationsSets = {}
	local i = 0

	while true do
		local key = string.format("%s.configurationSet(%d)", configurationSetsKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local configSet = {
			name = XMLUtil.getXMLI18NValue(xmlFile, key .. "#name", getXMLString, nil, "", customEnvironment, true)
		}
		local params = getXMLString(xmlFile, key .. "#params")

		if params ~= nil then
			local params = StringUtil.splitString("|", params)
			configSet.name = string.format(configSet.name, unpack(params))
		end

		configSet.isDefault = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDefault"), false)
		configSet.overwrittenTitle = overwrittenTitle
		configSet.configurations = {}
		local j = 0

		while true do
			local configKey = string.format("%s.configuration(%d)", key, j)

			if not hasXMLProperty(xmlFile, configKey) then
				break
			end

			local name = getXMLString(xmlFile, configKey .. "#name")

			if name ~= nil then
				if storeItem.configurations[name] ~= nil then
					local index = getXMLInt(xmlFile, configKey .. "#index")

					if index ~= nil then
						if storeItem.configurations[name][index] ~= nil then
							configSet.configurations[name] = index
						else
							print("Warning: Index '" .. index .. "' not defined for configuration '" .. name .. "'!")
						end
					end
				else
					print("Warning: Configuration name '" .. name .. "' is not defined in vehicle xml!")
				end
			else
				print("Warning: Missing name for configuration set item '" .. key .. "'!")
			end

			j = j + 1
		end

		table.insert(configurationsSets, configSet)

		i = i + 1
	end

	return configurationsSets
end

function StoreItemUtil.getSubConfigurationsFromXML(configurations)
	local subConfigurations = nil

	if configurations ~= nil then
		subConfigurations = {}

		for name, items in pairs(configurations) do
			local config = g_configurationManager:getConfigurationDescByName(name)

			if config.hasSubselection then
				local subConfigValues = config.getSubConfigurationValuesFunc(items)

				if #subConfigValues > 1 then
					local subConfigItemMapping = {}
					subConfigurations[name] = {
						subConfigValues = subConfigValues,
						subConfigItemMapping = subConfigItemMapping
					}

					for k, value in ipairs(subConfigValues) do
						subConfigItemMapping[value] = config.getItemsBySubConfigurationIdentifierFunc(items, value)
					end
				end
			end
		end
	end

	return subConfigurations
end

function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues

	for k, identifier in ipairs(subConfigValues) do
		local items = subConfigurations.subConfigItemMapping[identifier]

		for _, item in ipairs(items) do
			if item.index == configIndex then
				return k
			end
		end
	end

	return nil
end

function StoreItemUtil.getFilteredConfigurationIndex(storeItem, configName, configIndex)
	local subConfigurations = storeItem.subConfigurations[configName]

	if subConfigurations ~= nil then
		local subConfigValues = subConfigurations.subConfigValues

		for _, identifier in ipairs(subConfigValues) do
			local items = subConfigurations.subConfigItemMapping[identifier]

			for k, item in ipairs(items) do
				if item.index == configIndex then
					return k
				end
			end
		end
	end

	return configIndex
end

function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues
	local identifier = subConfigValues[state]

	return subConfigurations.subConfigItemMapping[identifier]
end

function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
	local xmlFile = loadXMLFile("VehicleXML", xmlFilename)
	local sizeWidth, sizeLength, widthOffset, lengthOffset = StoreItemUtil.getSizeValuesFromXML(xmlFile, baseName, rotationOffset, configurations)

	delete(xmlFile)

	return sizeWidth, sizeLength, widthOffset, lengthOffset
end

function StoreItemUtil.getSizeValuesFromXML(xmlFile, baseName, rotationOffset, configurations)
	local sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".base.size#width"), Vehicle.defaultWidth)
	local sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".base.size#length"), Vehicle.defaultLength)
	local widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".base.size#widthOffset"), 0)
	local lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".base.size#lengthOffset"), 0)

	if configurations ~= nil then
		for name, id in pairs(configurations) do
			local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

			if specializationKey ~= nil then
				specializationKey = "." .. specializationKey
			else
				specializationKey = ""
			end

			local key = string.format("%s%s.%sConfigurations.%sConfiguration(%d)", baseName, specializationKey, name, name, id - 1)
			local tempWidth = getXMLFloat(xmlFile, key .. ".size#width")
			local tempLength = getXMLFloat(xmlFile, key .. ".size#length")
			local tempWidthOffset = getXMLFloat(xmlFile, key .. ".size#widthOffset")
			local tempLengthOffset = getXMLFloat(xmlFile, key .. ".size#lengthOffset")

			if tempWidth ~= nil then
				sizeWidth = math.max(sizeWidth, tempWidth)
			end

			if tempLength ~= nil then
				sizeLength = math.max(sizeLength, tempLength)
			end

			if tempWidthOffset ~= nil then
				if widthOffset < 0 then
					widthOffset = math.min(widthOffset, tempWidthOffset)
				else
					widthOffset = math.max(widthOffset, tempWidthOffset)
				end
			end

			if tempLengthOffset ~= nil then
				if lengthOffset < 0 then
					lengthOffset = math.min(lengthOffset, tempLengthOffset)
				else
					lengthOffset = math.max(lengthOffset, tempLengthOffset)
				end
			end
		end
	end

	rotationOffset = math.floor(rotationOffset / math.rad(90) + 0.5) * math.rad(90)
	rotationOffset = rotationOffset % (2 * math.pi)

	if rotationOffset < 0 then
		rotationOffset = rotationOffset + 2 * math.pi
	end

	local rotationIndex = math.floor(rotationOffset / math.rad(90) + 0.5)

	if rotationIndex == 1 then
		sizeLength = sizeWidth
		sizeWidth = sizeLength
		lengthOffset = -widthOffset
		widthOffset = lengthOffset
	elseif rotationIndex == 2 then
		lengthOffset = -lengthOffset
		widthOffset = -widthOffset
	elseif rotationIndex == 3 then
		sizeLength = sizeWidth
		sizeWidth = sizeLength
		lengthOffset = widthOffset
		widthOffset = -lengthOffset
	end

	return sizeWidth, sizeLength, widthOffset, lengthOffset
end
