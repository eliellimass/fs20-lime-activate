FillType = nil
FillTypeCategory = nil
FillTypeManager = {
	FILLTYPE_START_TOTAL_AMOUNT = 50000,
	SEND_NUM_BITS = 8,
	MASS_SCALE = 0.5
}
local FillTypeManager_mt = Class(FillTypeManager, AbstractManager)

function FillTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or FillTypeManager_mt)

	return self
end

function FillTypeManager:initDataStructures()
	self.fillTypes = {}
	self.nameToFillType = {}
	self.indexToFillType = {}
	self.nameToIndex = {}
	self.indexToName = {}
	self.fillTypeConverters = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.categories = {}
	self.nameToCategoryIndex = {}
	self.categoryIndexToFillTypes = {}
	self.categoryNameToFillTypes = {}
	self.fillTypeSamples = {}
	self.fillTypeToSample = {}
	FillType = self.nameToIndex
	FillTypeCategory = self.categories
end

function FillTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")

	self:loadFillTypes(xmlFile, nil, , true)
	delete(xmlFile)
end

function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FillTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, missionInfo, baseDirectory)
end

function FillTypeManager:unloadMapData()
	for _, sample in ipairs(self.fillTypeSamples) do
		g_soundManager:deleteSample(sample.sample)
	end

	FillTypeManager:superClass().unloadMapData(self)
end

function FillTypeManager:loadFillTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	self:addFillType("UNKNOWN", "Unknown", false, 0, 0, 0, "", "", baseDirectory, nil, )

	local i = 0

	while true do
		local key = string.format("map.fillTypes.fillType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local title = getXMLString(xmlFile, key .. "#title")
		local showOnPriceTable = getXMLBool(xmlFile, key .. "#showOnPriceTable")
		local pricePerLiter = getXMLFloat(xmlFile, key .. "#pricePerLiter")
		local fillPlaneColorsString = getXMLString(xmlFile, key .. "#fillPlaneColors")
		local fillPlaneColors = {
			1,
			1,
			1
		}

		if fillPlaneColorsString ~= nil then
			fillPlaneColors = StringUtil.getVectorNFromString(fillPlaneColorsString, 3)
		end

		local massPerLiter = getXMLFloat(xmlFile, key .. ".physics#massPerLiter") / 1000
		local maxPhysicalSurfaceAngle = getXMLFloat(xmlFile, key .. ".physics#maxPhysicalSurfaceAngle")
		local hudFilename = getXMLString(xmlFile, key .. ".image#hud")
		local hudSmallFilename = getXMLString(xmlFile, key .. ".image#hudSmall")
		local palletFilename = getXMLString(xmlFile, key .. ".pallet#filename")
		local customEnv = nil

		if missionInfo ~= nil then
			customEnv = missionInfo.customEnvironment
		end

		self:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudFilename, hudSmallFilename, baseDirectory, customEnv, fillPlaneColors, palletFilename, isBaseType or false)

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fillTypeCategories.fillTypeCategory(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local fillTypesStr = getXMLString(xmlFile, key)
		local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)

		if fillTypeCategoryIndex ~= nil then
			local fillTypeNames = StringUtil.splitString(" ", fillTypesStr)

			for _, fillTypeName in ipairs(fillTypeNames) do
				local fillType = self:getFillTypeByName(fillTypeName)

				if fillType ~= nil then
					if not self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
						print("Warning: Could not add fillType '" .. tostring(fillTypeName) .. "' to fillTypeCategory '" .. tostring(name) .. "'!")
					end
				else
					print("Warning: FillType '" .. tostring(fillTypeName) .. "' not defined in fillTypeCategory '" .. tostring(name) .. "'!")
				end
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fillTypeConverters.fillTypeConverter(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local converter = self:addFillTypeConverter(name, isBaseType)

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
				local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
				local targetFillType = g_fillTypeManager:getFillTypeByName(to)

				if sourceFillType ~= nil and targetFillType ~= nil and factor ~= nil then
					self:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
				end

				j = j + 1
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fillTypeSounds.fillTypeSound(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local sample = g_soundManager:loadSampleFromXML(xmlFile, key, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, )

		if sample ~= nil then
			local entry = {
				sample = sample,
				fillTypes = {}
			}
			local fillTypesStr = getXMLString(xmlFile, key .. "#fillTypes")

			if fillTypesStr ~= nil then
				local fillTypeNames = StringUtil.splitString(" ", fillTypesStr)

				for _, fillTypeName in ipairs(fillTypeNames) do
					local fillType = self:getFillTypeIndexByName(fillTypeName)

					if fillType ~= nil then
						table.insert(entry.fillTypes, fillType)

						self.fillTypeToSample[fillType] = sample
					else
						g_logManager:warning("Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, key)
					end
				end
			end

			if getXMLBool(xmlFile, key .. "#isDefault") then
				for fillType, _ in ipairs(self.fillTypes) do
					if self.fillTypeToSample[fillType] == nil then
						self.fillTypeToSample[fillType] = sample
					end
				end
			end

			table.insert(self.fillTypeSamples, entry)
		end

		i = i + 1
	end

	return true
end

function FillTypeManager:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudOverlayFilename, hudOverlayFilenameSmall, baseDirectory, customEnv, fillPlaneColors, palletFilename, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fillType. Ignoring fillType!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToFillType[name] ~= nil then
		print("Warning: FillType '" .. tostring(name) .. "' already exists. Ignoring fillType!")

		return nil
	end

	local fillType = self.nameToFillType[name]

	if fillType == nil then
		if #self.fillTypes >= 256 then
			print("Error: FillTypeManager.addFillType too many fill types. Only 256 fill types are supported")

			return
		end

		fillType = {
			name = name,
			index = #self.fillTypes + 1,
			title = g_i18n:convertText(title, customEnv)
		}
		self.nameToFillType[name] = fillType
		self.nameToIndex[name] = fillType.index
		self.indexToName[fillType.index] = name

		table.insert(self.fillTypes, fillType)
	end

	fillType.showOnPriceTable = Utils.getNoNil(showOnPriceTable, Utils.getNoNil(fillType.showOnPriceTable, false))
	fillType.pricePerLiter = Utils.getNoNil(pricePerLiter, Utils.getNoNil(fillType.pricePerLiter, 0))
	fillType.massPerLiter = Utils.getNoNil(massPerLiter, Utils.getNoNil(fillType.massPerLiter, 0.0001)) * FillTypeManager.MASS_SCALE
	fillType.maxPhysicalSurfaceAngle = Utils.getNoNilRad(maxPhysicalSurfaceAngle, Utils.getNoNil(fillType.maxPhysicalSurfaceAngle, math.rad(30)))
	fillType.hudOverlayFilename = Utils.getFilename(hudOverlayFilename, baseDirectory) or fillType.hudOverlayFilename
	fillType.hudOverlayFilenameSmall = Utils.getFilename(hudOverlayFilenameSmall, baseDirectory) or fillType.hudOverlayFilenameSmall

	if fillType.index ~= FillType.UNKNOWN then
		if fillType.hudOverlayFilename == nil or fillType.hudOverlayFilename == "" then
			g_logManager:warning("FillType '%s' has no valid image assigned!", name)
		end

		if fillType.hudOverlayFilenameSmall == nil or fillType.hudOverlayFilenameSmall == "" then
			g_logManager:warning("FillType '%s' has no valid small image assigned!", name)
		end
	end

	if palletFilename ~= nil then
		fillType.palletFilename = Utils.getFilename(palletFilename, baseDirectory) or fillType.palletFilename
	end

	fillType.previousHourPrice = fillType.pricePerLiter
	fillType.startPricePerLiter = fillType.pricePerLiter
	fillType.totalAmount = FillTypeManager.FILLTYPE_START_TOTAL_AMOUNT
	fillType.fillPlaneColors = {}

	if fillPlaneColors ~= nil then
		fillType.fillPlaneColors[1] = fillPlaneColors[1] or fillType.fillPlaneColors[1]
		fillType.fillPlaneColors[2] = fillPlaneColors[2] or fillType.fillPlaneColors[2]
		fillType.fillPlaneColors[3] = fillPlaneColors[3] or fillType.fillPlaneColors[3]
	else
		fillType.fillPlaneColors[1] = fillType.fillPlaneColors[1] or 1
		fillType.fillPlaneColors[2] = fillType.fillPlaneColors[2] or 1
		fillType.fillPlaneColors[3] = fillType.fillPlaneColors[3] or 1
	end

	return fillType
end

function FillTypeManager:getFillTypeByIndex(index)
	if index ~= nil then
		return self.fillTypes[index]
	end

	return nil
end

function FillTypeManager:getFillTypeNameByIndex(index)
	if index ~= nil then
		return self.indexToName[index]
	end

	return nil
end

function FillTypeManager:getFillTypeIndexByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToIndex[name]
	end

	return nil
end

function FillTypeManager:getFillTypeByName(name)
	if ClassUtil.getIsValidIndexName(name) then
		name = name:upper()

		return self.nameToFillType[name]
	end

	return nil
end

function FillTypeManager:getFillTypes()
	return self.fillTypes
end

function FillTypeManager:addFillTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToCategoryIndex[name] ~= nil then
		print("Warning: FillTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fillTypeCategory!")

		return nil
	end

	local index = self.nameToCategoryIndex[name]

	if index == nil then
		local categoryFillTypes = {}
		index = #self.categories + 1

		table.insert(self.categories, name)

		self.categoryNameToFillTypes[name] = categoryFillTypes
		self.categoryIndexToFillTypes[index] = categoryFillTypes
		self.nameToCategoryIndex[name] = index
	end

	return index
end

function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
	if categoryIndex ~= nil and fillTypeIndex ~= nil and self.categoryIndexToFillTypes[categoryIndex] ~= nil then
		self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true

		return true
	end

	return false
end

function FillTypeManager:getFillTypesByCategoryNames(names, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local categories = StringUtil.splitString(" ", names)

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local categoryFillTypes = self.categoryNameToFillTypes[categoryName]

		if categoryFillTypes ~= nil then
			for fillType, _ in pairs(categoryFillTypes) do
				if alreadyAdded[fillType] == nil then
					table.insert(fillTypes, fillType)

					alreadyAdded[fillType] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fillTypes
end

function FillTypeManager:getFillTypesByNames(names, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local fillTypeNames = StringUtil.splitString(" ", names)

	for _, name in pairs(fillTypeNames) do
		name = name:upper()
		local fillTypeIndex = self.nameToIndex[name]

		if fillTypeIndex ~= nil then
			if alreadyAdded[fillTypeIndex] == nil then
				table.insert(fillTypes, fillTypeIndex)

				alreadyAdded[fillTypeIndex] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fillTypes
end

function FillTypeManager:getFillTypesFromXML(configFileName, xmlFile, categoryKey, namesKey, requiresFillTypes)
	local fillTypes = {}
	local fillTypeCategories = getXMLString(xmlFile, categoryKey)
	local fillTypeNames = getXMLString(xmlFile, namesKey)

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. configFileName .. "' has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. configFileName .. "' has invalid fillType '%s'.")
	elseif requiresFillTypes ~= nil and requiresFillTypes then
		print(string.format("Warning: '" .. configFileName .. "' needs either the '%s' or '%s' attribute.", categoryKey, namesKey))
	end

	return fillTypes
end

function FillTypeManager:addFillTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToConverter[name] ~= nil then
		print("Warning: FillTypeConverter '" .. tostring(name) .. "' already exists. Ignoring FillTypeConverter!")

		return nil
	end

	local index = self.converterNameToIndex[name]

	if index == nil then
		local converter = {}

		table.insert(self.fillTypeConverters, converter)

		self.converterNameToIndex[name] = #self.fillTypeConverters
		self.nameToConverter[name] = converter
		index = #self.fillTypeConverters
	end

	return index
end

function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
	if converter ~= nil and self.fillTypeConverters[converter] ~= nil and sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil then
		self.fillTypeConverters[converter][sourceFillTypeIndex] = {
			targetFillTypeIndex = targetFillTypeIndex,
			conversionFactor = conversionFactor
		}
	end
end

function FillTypeManager:getConverterDataByName(converterName)
	if converterName ~= nil then
		return self.nameToConverter[converterName:upper()]
	end

	return nil
end

function FillTypeManager:getSampleByFillType(fillType)
	if fillType ~= nil then
		return self.fillTypeToSample[fillType]
	end

	return nil
end

g_fillTypeManager = FillTypeManager:new()
