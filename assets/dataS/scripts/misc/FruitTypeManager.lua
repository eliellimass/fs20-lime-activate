FruitType = nil
FruitTypeCategory = nil
FruitTypeConverter = nil
FruitTypeManager = {
	SEND_NUM_BITS = 6,
	GROUND_TYPE_NONE = 0,
	GROUND_TYPE_CULTIVATOR = 1,
	GROUND_TYPE_PLOW = 2,
	GROUND_TYPE_SOWING = 3,
	GROUND_TYPE_SOWING_WIDTH = 4,
	GROUND_TYPE_GRASS = 5
}
local FruitTypeManager_mt = Class(FruitTypeManager, AbstractManager)

function FruitTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or FruitTypeManager_mt)

	return self
end

function FruitTypeManager:initDataStructures()
	self.fruitTypes = {}
	self.indexToFruitType = {}
	self.nameToIndex = {}
	self.nameToFruitType = {}
	self.fruitTypeIndexToFillType = {}
	self.fillTypeIndexToFruitTypeIndex = {}
	self.fruitTypeConverters = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.windrowFillTypes = {}
	self.fruitTypeIndexToWindrowFillTypeIndex = {}
	self.numCategories = 0
	self.categories = {}
	self.indexToCategory = {}
	self.categoryToFruitTypes = {}
	self.weedFruitType = nil
	FruitType = self.nameToIndex
	FruitType.UNKNOWN = 0
	FruitTypeCategory = self.categories
	FruitTypeConverter = self.converterNameToIndex
end

function FruitTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")

	self:loadFruitTypes(xmlFile, nil, true)
	delete(xmlFile)
end

function FruitTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FruitTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "fruitTypes", baseDirectory, self, self.loadFruitTypes, missionInfo)
end

function FruitTypeManager:loadFruitTypes(xmlFile, missionInfo, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.fruitTypes.fruitType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local shownOnMap = getXMLBool(xmlFile, key .. "#shownOnMap")
		local useForFieldJob = getXMLBool(xmlFile, key .. "#useForFieldJob")
		local missionMultiplier = getXMLFloat(xmlFile, key .. "#missionMultiplier")
		local fruitType = self:addFruitType(name, shownOnMap, useForFieldJob, missionMultiplier, isBaseType)

		if fruitType ~= nil then
			local success = true
			success = success and self:loadFruitTypeGeneral(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeWindrow(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeGrowth(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeHarvest(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeCultivation(fruitType, xmlFile, key)
			success = success and self:loadFruitTypePreparing(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeOptions(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeMapColors(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeDestruction(fruitType, xmlFile, key)

			if self.weedFruitType == nil and self:loadFruitTypeWeedData(fruitType, xmlFile, key) then
				self.weedFruitType = fruitType
			end

			if success and self.indexToFruitType[fruitType.index] == nil then
				table.insert(self.fruitTypes, fruitType)

				self.nameToFruitType[fruitType.name] = fruitType
				self.nameToIndex[fruitType.name] = fruitType.index
				self.indexToFruitType[fruitType.index] = fruitType
				self.fillTypeIndexToFruitTypeIndex[fruitType.fillType.index] = fruitType.index
				self.fruitTypeIndexToFillType[fruitType.index] = fruitType.fillType
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fruitTypeCategories.fruitTypeCategory(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local fruitTypesStr = getXMLString(xmlFile, key)
		local fruitTypeCategoryIndex = self:addFruitTypeCategory(name, isBaseType)

		if fruitTypeCategoryIndex ~= nil then
			local fruitTypeNames = StringUtil.splitString(" ", fruitTypesStr)

			for _, fruitTypeName in ipairs(fruitTypeNames) do
				local fruitType = self:getFruitTypeByName(fruitTypeName)

				if fruitType ~= nil then
					if not self:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
						print("Warning: Could not add fruitType '" .. tostring(fruitTypeName) .. "' to fruitTypeCategory '" .. tostring(name) .. "'!")
					end
				else
					print("Warning: FruitType '" .. tostring(fruitTypeName) .. "' not defined in fruitTypeCategory '" .. tostring(name) .. "'!")
				end
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fruitTypeConverters.fruitTypeConverter(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local converter = self:addFruitTypeConverter(name, isBaseType)

		if converter ~= nil then
			local j = 0

			while true do
				local converterKey = string.format("%s.converter(%d)", key, j)

				if not hasXMLProperty(xmlFile, converterKey) then
					break
				end

				local from = getXMLString(xmlFile, converterKey .. "#from")
				local to = getXMLString(xmlFile, converterKey .. "#to")
				local factor = getXMLFloat(xmlFile, converterKey .. "#factor")
				local windrowFactor = getXMLFloat(xmlFile, converterKey .. "#windrowFactor")
				local fruitType = self:getFruitTypeByName(from)
				local fillType = g_fillTypeManager:getFillTypeByName(to)

				if fruitType ~= nil and fillType ~= nil and factor ~= nil then
					self:addFruitTypeConversion(converter, fruitType.index, fillType.index, factor, windrowFactor)
				end

				j = j + 1
			end
		end

		i = i + 1
	end

	return true
end

function FruitTypeManager:addFruitType(name, shownOnMap, useForFieldJob, missionMultiplier, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitType. Ignoring fruitType!")

		return nil
	end

	local upperName = name:upper()
	local fillType = g_fillTypeManager:getFillTypeByName(upperName)

	if fillType == nil then
		print("Warning: Missing fillType '" .. tostring(name) .. "' for fruitType definition. Ignoring fruitType!")

		return nil
	end

	if isBaseType and self.nameToFruitType[upperName] ~= nil then
		print("Warning: FillType '" .. tostring(name) .. "' already exists. Ignoring fillType!")

		return nil
	end

	local fruitType = self.nameToFruitType[upperName]

	if fruitType == nil then
		fruitType = {
			layerName = name,
			name = upperName,
			index = #self.fruitTypes + 1,
			fillType = fillType,
			defaultMapColor = {
				1,
				1,
				1,
				1
			},
			colorBlindMapColor = {
				1,
				1,
				1,
				1
			}
		}
	end

	fruitType.shownOnMap = Utils.getNoNil(shownOnMap, Utils.getNoNil(fruitType.shownOnMap, true))
	fruitType.useForFieldJob = Utils.getNoNil(useForFieldJob, Utils.getNoNil(fruitType.useForFieldJob, true))
	fruitType.missionMultiplier = Utils.getNoNil(missionMultiplier, Utils.getNoNil(fruitType.missionMultiplier, 1))

	return fruitType
end

function FruitTypeManager:loadFruitTypeGeneral(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.startStateChannel = Utils.getNoNil(getXMLInt(xmlFile, key .. ".general#startStateChannel"), Utils.getNoNil(fruitType.startStateChannel, 0))
		fruitType.numStateChannels = Utils.getNoNil(getXMLInt(xmlFile, key .. ".general#numStateChannels"), Utils.getNoNil(fruitType.numStateChannels, 4))
	end

	return true
end

function FruitTypeManager:loadFruitTypeWindrow(fruitType, xmlFile, key)
	if fruitType ~= nil then
		local windrowName = getXMLString(xmlFile, key .. ".windrow#name")
		local windrowLitersPerSqm = getXMLFloat(xmlFile, key .. ".windrow#litersPerSqm")

		if windrowName == nil or windrowLitersPerSqm == nil then
			return true
		end

		local windrowFillType = g_fillTypeManager:getFillTypeByName(windrowName)

		if windrowFillType == nil then
			print("Warning: Mission fillType '" .. tostring(windrowName) .. "' for windrow definition. Ignoring windrow!")

			return false
		end

		fruitType.hasWindrow = true
		fruitType.windrowName = windrowFillType.name
		fruitType.windrowLiterPerSqm = windrowLitersPerSqm
		self.windrowFillTypes[windrowFillType.index] = true
		self.fruitTypeIndexToWindrowFillTypeIndex[fruitType.index] = windrowFillType.index
		self.fillTypeIndexToFruitTypeIndex[windrowFillType.index] = fruitType.index
	end

	return true
end

function FruitTypeManager:loadFruitTypeGrowth(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.witheringNumGrowthStates = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#witheringNumGrowthStates"), Utils.getNoNil(fruitType.witheringNumGrowthStates, 0))
		fruitType.numGrowthStates = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#numGrowthStates"), Utils.getNoNil(fruitType.numGrowthStates, 0))
		fruitType.growthStateTime = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#growthStateTime"), Utils.getNoNil(fruitType.growthStateTime, 0))
		fruitType.resetsSpray = Utils.getNoNil(getXMLBool(xmlFile, key .. ".growth#resetsSpray"), Utils.getNoNil(fruitType.resetsSpray, true))
		fruitType.groundTypeChangeGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#groundTypeChangeGrowthState"), Utils.getNoNil(fruitType.groundTypeChangeGrowthState, -1))
		fruitType.growthRequiresLime = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#requiresLime"), Utils.getNoNil(fruitType.growthRequiresLime, true))
		local groundTypeStr = getXMLString(xmlFile, key .. ".growth#groundTypeChanged")

		if groundTypeStr == nil then
			return true
		end

		local groundTypeKey = string.format("GROUND_TYPE_%s", groundTypeStr:upper())

		if not ClassUtil.getIsValidIndexName(groundTypeKey) or not FruitTypeManager[groundTypeKey] == nil then
			print("Warning: Invalid groundTypeChanged name. Ignoring growth data!")

			return false
		end

		fruitType.groundTypeChanged = FruitTypeManager[groundTypeKey]
		fruitType.groundTypeChangeMask = 0
		local groundTypeChangeMaskString = getXMLString(xmlFile, key .. ".growth#groundTypeChangeMask")

		if groundTypeChangeMaskString ~= nil then
			local groundTypeChangeMaskList = StringUtil.splitString(" ", groundTypeChangeMaskString)

			for _, v in ipairs(groundTypeChangeMaskList) do
				local groundTypeKey = string.format("GROUND_TYPE_%s", v:upper())

				if not ClassUtil.getIsValidIndexName(groundTypeKey) or not FruitTypeManager[groundTypeKey] == nil then
					print("Warning: Invalid groundTypeChangeMask name. Ignoring growth data!")

					return false
				end

				fruitType.groundTypeChangeMask = bitOR(fruitType.groundTypeChangeMask, bitShiftLeft(1, FruitTypeManager[groundTypeKey]))
			end
		else
			fruitType.groundTypeChangeMask = bitNOT(0)
		end

		fruitType.regrows = Utils.getNoNil(getXMLBool(xmlFile, key .. ".growth#regrows"), Utils.getNoNil(fruitType.regrows, false))

		if fruitType.regrows then
			fruitType.firstRegrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#firstRegrowthState"), Utils.getNoNil(fruitType.firstRegrowthState, 1))
		end

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeHarvest(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.minHarvestingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#minHarvestingGrowthState"), Utils.getNoNil(fruitType.minHarvestingGrowthState, 0))
		fruitType.maxHarvestingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#maxHarvestingGrowthState"), Utils.getNoNil(fruitType.maxHarvestingGrowthState, 0))
		fruitType.minForageGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#minForageGrowthState"), Utils.getNoNil(fruitType.minForageGrowthState, fruitType.minHarvestingGrowthState))
		fruitType.cutState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#cutState"), Utils.getNoNil(fruitType.cutState, 0))
		fruitType.allowsPartialGrowthState = Utils.getNoNil(getXMLBool(xmlFile, key .. ".harvest#allowsPartialGrowthState"), Utils.getNoNil(fruitType.allowsPartialGrowthState, false))
		fruitType.literPerSqm = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".harvest#literPerSqm"), Utils.getNoNil(fruitType.literPerSqm, 0))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeCultivation(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.needsSeeding = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#needsSeeding"), Utils.getNoNil(fruitType.needsSeeding, true))
		fruitType.allowsSeeding = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#allowsSeeding"), Utils.getNoNil(fruitType.allowsSeeding, true))
		fruitType.useSeedingWidth = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#useSeedingWidth"), Utils.getNoNil(fruitType.useSeedingWidth, true))
		fruitType.directionSnapAngle = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. ".cultivation#directionSnapAngle"), Utils.getNoNil(fruitType.directionSnapAngle, 0))
		fruitType.alignsToSun = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#alignsToSun"), Utils.getNoNil(fruitType.alignsToSun, false))
		fruitType.seedUsagePerSqm = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".cultivation#seedUsagePerSqm"), Utils.getNoNil(fruitType.seedUsagePerSqm, 0.1))
		fruitType.plantsWeed = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#plantsWeed"), Utils.getNoNil(fruitType.plantsWeed, true))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypePreparing(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.preparingOutputName = Utils.getNoNil(getXMLString(xmlFile, key .. ".preparing#outputName"), fruitType.preparingOutputName)
		fruitType.minPreparingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#minGrowthState"), Utils.getNoNil(fruitType.minPreparingGrowthState, -1))
		fruitType.maxPreparingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#maxGrowthState"), Utils.getNoNil(fruitType.maxPreparingGrowthState, -1))
		fruitType.preparedGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#preparedGrowthState"), Utils.getNoNil(fruitType.preparedGrowthState, -1))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeOptions(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.increasesSoilDensity = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#increasesSoilDensity"), Utils.getNoNil(fruitType.increasesSoilDensity, false))
		fruitType.lowSoilDensityRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#lowSoilDensityRequired"), Utils.getNoNil(fruitType.lowSoilDensityRequired, true))
		fruitType.consumesLime = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#consumesLime"), Utils.getNoNil(fruitType.consumesLime, true))
		fruitType.startSprayState = math.max(Utils.getNoNil(getXMLInt(xmlFile, key .. ".options#startSprayState"), Utils.getNoNil(fruitType.startSprayState, 0)), 0)
		fruitType.destroyedByRoller = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#destroyedByRoller"), Utils.getNoNil(fruitType.destroyedByRoller, true))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeWeedData(fruitType, xmlFile, key)
	if fruitType ~= nil and hasXMLProperty(xmlFile, key .. ".weedGrowth") then
		local weed = fruitType.weed

		if weed == nil then
			weed = {
				herbicideReplaces = {}
			}
		end

		weed.minValue = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#minGrowthState"), Utils.getNoNil(weed.minValue, 0))
		weed.maxValue = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#maxGrowthState"), Utils.getNoNil(weed.maxValue, 1))
		weed.updateDelta = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#updateDelta"), Utils.getNoNil(weed.updateDelta, 1))
		weed.availFirstChannel = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#availFirstChannel"), Utils.getNoNil(weed.availFirstChannel, fruitType.startStateChannel))
		weed.availNumChannels = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#availNumChannels"), Utils.getNoNil(weed.availNumChannels, fruitType.numStateChannels))
		weed.availMinValue = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#availMinValue"), Utils.getNoNil(weed.availMinValue, weed.minValue))
		weed.growthStateTime = Utils.getNoNil(getXMLInt(xmlFile, key .. ".weedGrowth#growthStateTime"), Utils.getNoNil(weed.growthStateTime, 24000000))
		local i = 0

		while true do
			local replKey = string.format("%s.herbicideReplace(%d)", key, i)

			if not hasXMLProperty(xmlFile, replKey) then
				break
			end

			local src = Utils.getNoNil(getXMLInt(xmlFile, replKey .. "#source"), 0)
			local target = Utils.getNoNil(getXMLInt(xmlFile, replKey .. "#target"), 0)

			if src ~= target then
				table.insert(weed.herbicideReplaces, {
					src = src,
					target = target
				})
			end

			i = i + 1
		end

		fruitType.weed = weed

		return true
	end

	return false
end

function FruitTypeManager:getWeedFruitType()
	return self.weedFruitType
end

function FruitTypeManager:loadFruitTypeMapColors(fruitType, xmlFile, key)
	if fruitType ~= nil then
		local defaultColorString = getXMLString(xmlFile, key .. ".mapColors#default") or "1 1 1 1"
		local defaultColorBlindString = getXMLString(xmlFile, key .. ".mapColors#colorBlind") or "1 1 1 1"
		fruitType.defaultMapColor = GuiUtils.getColorArray(defaultColorString) or fruitType.defaultMapColor
		fruitType.colorBlindMapColor = GuiUtils.getColorArray(defaultColorBlindString) or fruitType.colorBlindMapColor

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeDestruction(fruitType, xmlFile, key)
	if fruitType ~= nil then
		if hasXMLProperty(xmlFile, key .. ".destruction") then
			local destruction = {}
			destruction.onlyOnField = Utils.getNoNil(getXMLBool(xmlFile, key .. ".destruction#onlyOnField"), Utils.getNoNil(destruction.onlyOnField, true))
			local filterStart = getXMLInt(xmlFile, key .. ".destruction#filterStart")

			if filterStart ~= nil then
				filterStart = filterStart + 1
			end

			local filterEnd = getXMLInt(xmlFile, key .. ".destruction#filterEnd")

			if filterEnd ~= nil then
				filterEnd = filterEnd + 1
			end

			local state = getXMLInt(xmlFile, key .. ".destruction#state")

			if state ~= nil then
				state = state + 1
			end

			destruction.filterStart = filterStart or fruitType.filterStart or 2
			destruction.filterEnd = filterEnd or fruitType.filterEnd or fruitType.cutState + 1
			destruction.state = state or fruitType.state or fruitType.cutState + 1
			fruitType.destruction = destruction
		end

		local defaultColorString = getXMLString(xmlFile, key .. ".mapColors#default") or "1 1 1 1"
		local defaultColorBlindString = getXMLString(xmlFile, key .. ".mapColors#colorBlind") or "1 1 1 1"
		fruitType.defaultMapColor = GuiUtils.getColorArray(defaultColorString) or fruitType.defaultMapColor
		fruitType.colorBlindMapColor = GuiUtils.getColorArray(defaultColorBlindString) or fruitType.colorBlindMapColor

		return true
	end

	return false
end

function FruitTypeManager:getFruitTypeByIndex(index)
	if index ~= nil then
		return self.indexToFruitType[index]
	end

	return nil
end

function FruitTypeManager:getFruitTypeNameByIndex(index)
	if index ~= nil and self.indexToFruitType[index] ~= nil then
		return self.indexToFruitType[index].name
	end

	return nil
end

function FruitTypeManager:getFruitTypeByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToFruitType[name]
	end

	return nil
end

function FruitTypeManager:getFruitTypes()
	return self.fruitTypes
end

function FruitTypeManager:getFruitTypeIndexByFillTypeIndex(index)
	if index ~= nil then
		return self.fillTypeIndexToFruitTypeIndex[index]
	end

	return nil
end

function FruitTypeManager:getFruitTypeByFillTypeIndex(index)
	if index ~= nil then
		local fruitTypeIndex = self.fillTypeIndexToFruitTypeIndex[index]

		return self.fruitTypes[fruitTypeIndex]
	end

	return nil
end

function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
	if index ~= nil then
		local fillType = self.fruitTypeIndexToFillType[index]

		if fillType ~= nil then
			return fillType.index
		end
	end

	return nil
end

function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
	if index ~= nil then
		return self.fruitTypeIndexToFillType[index]
	end

	return nil
end

function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.categories[name] ~= nil then
		print("Warning: FruitTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fruitTypeCategory!")

		return nil
	end

	local index = self.categories[name]

	if index == nil then
		self.numCategories = self.numCategories + 1
		self.categories[name] = self.numCategories
		self.indexToCategory[self.numCategories] = name
		self.categoryToFruitTypes[self.numCategories] = {}
		index = self.numCategories
	end

	return index
end

function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
	if categoryIndex ~= nil and fruitTypeIndex ~= nil then
		table.insert(self.categoryToFruitTypes[categoryIndex], fruitTypeIndex)

		return true
	end

	return false
end

function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local categories = StringUtil.splitString(" ", names)

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local categoryIndex = self.categories[categoryName]
		local categoryFruitTypes = self.categoryToFruitTypes[categoryIndex]

		if categoryFruitTypes ~= nil then
			for _, fruitType in ipairs(categoryFruitTypes) do
				if alreadyAdded[fruitType] == nil then
					table.insert(fruitTypes, fruitType)

					alreadyAdded[fruitType] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fruitTypes
end

function FruitTypeManager:getFruitTypesByNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = StringUtil.splitString(" ", names)

	for _, name in pairs(fruitTypeNames) do
		name = name:upper()
		local fruitTypeIndex = self.nameToIndex[name]

		if fruitTypeIndex ~= nil then
			if alreadyAdded[fruitTypeIndex] == nil then
				table.insert(fruitTypes, fruitTypeIndex)

				alreadyAdded[fruitTypeIndex] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fruitTypes
end

function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = StringUtil.splitString(" ", names)

	for _, name in pairs(fruitTypeNames) do
		local fillType = nil
		local fruitType = self:getFruitTypeByName(name)

		if fruitType ~= nil then
			fillType = self:getFillTypeByFruitTypeIndex(fruitType.index)
		end

		if fillType ~= nil then
			if alreadyAdded[fillType.index] == nil then
				table.insert(fillTypes, fillType.index)

				alreadyAdded[fillType.index] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fillTypes
end

function FruitTypeManager:getFillTypesByFruitTypeCategoryName(fruitTypeCategories, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local categories = StringUtil.splitString(" ", fruitTypeCategories)

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local category = self.categories[categoryName]

		if category ~= nil then
			for _, fruitTypeIndex in ipairs(self.categoryToFruitTypes[category]) do
				local fillType = self:getFillTypeByFruitTypeIndex(fruitTypeIndex)

				if fillType ~= nil and alreadyAdded[fillType.index] == nil then
					table.insert(fillTypes, fillType.index)

					alreadyAdded[fillType.index] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fillTypes
end

function FruitTypeManager:isFillTypeWindrow(index)
	if index ~= nil then
		return self.windrowFillTypes[index] == true
	end

	return false
end

function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
	if index ~= nil then
		return self.fruitTypeIndexToWindrowFillTypeIndex[index]
	end

	return nil
end

function FruitTypeManager:getFillTypeLiterPerSqm(fillType, defaultValue)
	local fruitTypeIndex = self:getFruitTypeIndexByFillTypeIndex(fillType)

	if fruitTypeIndex ~= nil then
		local fruitType = self.fruitTypes[fruitTypeIndex]

		if fruitType.hasWindrow then
			return fruitType.windrowLiterPerSqm
		else
			return fruitType.literPerSqm
		end
	end

	return defaultValue
end

function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.converterNameToIndex[name] ~= nil then
		print("Warning: FruitTypeConverter '" .. tostring(name) .. "' already exists. Ignoring fruitTypeConverter!")

		return nil
	end

	local index = self.converterNameToIndex[name]

	if index == nil then
		local converter = {}

		table.insert(self.fruitTypeConverters, converter)

		self.converterNameToIndex[name] = #self.fruitTypeConverters
		self.nameToConverter[name] = converter
		index = #self.fruitTypeConverters
	end

	return index
end

function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeIndex, fillTypeIndex, conversionFactor, windrowConversionFactor)
	if converter ~= nil and self.fruitTypeConverters[converter] ~= nil and fruitTypeIndex ~= nil and fillTypeIndex ~= nil then
		self.fruitTypeConverters[converter][fruitTypeIndex] = {
			fillTypeIndex = fillTypeIndex,
			conversionFactor = conversionFactor,
			windrowConversionFactor = windrowConversionFactor
		}
	end
end

function FruitTypeManager:getConverterDataByName(converterName)
	if converterName ~= nil then
		return self.nameToConverter[converterName:upper()]
	end

	return nil
end

g_fruitTypeManager = FruitTypeManager:new()
