Animals = nil
AnimalManager = {
	SEND_NUM_BITS = 4
}
local AnimalManager_mt = Class(AnimalManager, AbstractManager)

function AnimalManager:new(customMt)
	local self = AbstractManager:new(customMt or AnimalManager_mt)

	return self
end

function AnimalManager:initDataStructures()
	self.numAnimals = 0
	self.animals = {}
	self.typeToAnimal = {}
	self.indexToAnimal = {}
	self.fillTypeToAnimal = {}
end

function AnimalManager:loadMapData(xmlFile, missionInfo)
	AnimalManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.husbandryAnimals#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		g_logManager:error("Could not load husbandry config file '%s'!", tostring(filename))

		return false
	end

	local animalXmlFile = loadXMLFile("husbandry", filename)

	if animalXmlFile ~= nil then
		self:loadAnimals(animalXmlFile, g_currentMission.baseDirectory)
		delete(animalXmlFile)

		return self.numAnimals ~= 0
	end

	return false
end

function AnimalManager:loadAnimals(xmlHandle, baseDirectory)
	if xmlHandle == 0 then
		return false
	end

	self.animals = {}
	self.typeToAnimal = {}
	local i = 0

	while true do
		local animalKey = string.format("animals.animal(%d)", i)

		if not hasXMLProperty(xmlHandle, animalKey) then
			break
		end

		local animal = {
			type = getXMLString(xmlHandle, animalKey .. "#type"),
			class = getXMLString(xmlHandle, animalKey .. "#class")
		}

		if not ClassUtil.getIsValidClassName(animal.class) then
			g_logManager:error("Invalid animal class name '%s'!", tostring(animal.class))

			return false
		end

		if ClassUtil.getClassObject(animal.class) == nil then
			g_logManager:error("Animal class '%s' not defined !", tostring(animal.class))

			return false
		end

		local hasName = Utils.getNoNil(getXMLBool(xmlHandle, animalKey .. "#hasName"), false)
		animal.stats = {
			breeding = Utils.getNoNil(getXMLString(xmlHandle, animalKey .. "#statsBreeding"), "")
		}
		animal.subTypes = {}

		if animal.type ~= nil then
			animal.type = animal.type:upper()
			local j = 0

			while true do
				local subTypeKey = string.format("%s.subType(%d)", animalKey, j)

				if not hasXMLProperty(xmlHandle, subTypeKey) then
					break
				end

				local animalSubType = {}
				local fillTypeName = getXMLString(xmlHandle, subTypeKey .. "#fillTypeName")
				local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

				if fillType ~= nil then
					animalSubType.storeInfo = {}
					animalSubType.output = {}
					animalSubType.input = {}
					animalSubType.breeding = {}
					animalSubType.texture = {}
					animalSubType.dirt = {}
					animalSubType.dummy = {}
					self.numAnimals = self.numAnimals + 1
					animalSubType.index = self.numAnimals
					animalSubType.type = animal.type
					animalSubType.hasName = hasName
					animalSubType.subTypeId = j + 1
					animalSubType.fillType = fillType.index
					animalSubType.fillTypeDesc = fillType
					animalSubType.subTypeName = g_i18n:convertText(Utils.getNoNil(getXMLString(xmlHandle, subTypeKey .. "#name"), ""))
					animalSubType.storeInfo.shopItemName = g_i18n:convertText(Utils.getNoNil(getXMLString(xmlHandle, subTypeKey .. ".store#itemName"), ""))
					animalSubType.storeInfo.canBeBought = Utils.getNoNil(getXMLBool(xmlHandle, subTypeKey .. ".store#canBeBought"), false)
					animalSubType.storeInfo.imageFilename = Utils.getNoNil(getXMLString(xmlHandle, subTypeKey .. ".store#image"), "")
					animalSubType.storeInfo.imageFilename = Utils.getFilename(animalSubType.storeInfo.imageFilename, baseDirectory)
					animalSubType.storeInfo.buyPrice = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".store#buyPrice"), 0)
					animalSubType.storeInfo.sellPrice = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".store#sellPrice"), 0)
					animalSubType.storeInfo.transportPrice = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".store#transportPrice"), 200)
					animalSubType.output.milkPerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".output#milkPerDay"), 0)
					animalSubType.output.manurePerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".output#manurePerDay"), 0)
					animalSubType.output.liquidManurePerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".output#liquidManurePerDay"), 0)
					animalSubType.output.palletsPerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".output#palletsPerDay"), 0)
					animalSubType.output.foodSpillagePerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".output#foodSpillagePerDay"), 0)
					animalSubType.input.strawPerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".input#strawPerDay"), 0)
					animalSubType.input.waterPerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".input#waterPerDay"), 0)
					animalSubType.input.foodPerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".input#foodPerDay"), 0)
					animalSubType.texture.tileUIndex = getXMLInt(xmlHandle, subTypeKey .. ".texture#tileUIndex")
					animalSubType.texture.tileVIndex = getXMLInt(xmlHandle, subTypeKey .. ".texture#tileVIndex")
					animalSubType.dirt.cleanDuration = (getXMLFloat(xmlHandle, subTypeKey .. ".dirt#cleanDuration") or 0.5) * 1000
					animalSubType.dummy.filename = Utils.getFilename(Utils.getNoNil(getXMLString(xmlHandle, subTypeKey .. ".dummy#filename"), baseDirectory))
					animalSubType.dummy.meshNodeStr = getXMLString(xmlHandle, subTypeKey .. ".dummy#meshNode") or "0"
					animalSubType.dummy.hairNodeStr = getXMLString(xmlHandle, subTypeKey .. ".dummy#hairNode")
					animalSubType.breeding.birthRatePerDay = Utils.getNoNil(getXMLFloat(xmlHandle, subTypeKey .. ".breeding#birthRatePerDay"), 0)
					animalSubType.rideableFileName = Utils.getFilename(Utils.getNoNil(getXMLString(xmlHandle, subTypeKey .. ".rideable#filename"), ""))
					self.indexToAnimal[animalSubType.index] = animalSubType
					self.fillTypeToAnimal[animalSubType.fillType] = animalSubType

					table.insert(animal.subTypes, animalSubType)
				else
					g_logManager:warning("FillType '%s' for animal '%s' not defined. Ignoring animal!", tostring(fillTypeName), animal.subTypeName)
				end

				j = j + 1
			end

			if #animal.subTypes > 0 then
				self.typeToAnimal[animal.type] = animal

				table.insert(self.animals, animal)
			else
				g_logManager:error("No sub types defined for animal '%s'. Ignoring animal!", animal.type)
			end
		else
			g_logManager:warning("Animal '%d' has no type. Ignoring animal!", i)
		end

		i = i + 1
	end
end

function AnimalManager:getAnimals()
	return self.animals
end

function AnimalManager:getAnimalByIndex(index)
	if index ~= nil then
		return self.indexToAnimal[index]
	end

	return nil
end

function AnimalManager:getAnimalsByType(animalType)
	if ClassUtil.getIsValidIndexName(animalType) then
		animalType = animalType:upper()

		return self.typeToAnimal[animalType]
	end

	return nil
end

function AnimalManager:getAnimalByFillType(fillType)
	if fillType ~= nil then
		return self.fillTypeToAnimal[fillType]
	end

	return nil
end

function AnimalManager:getAnimalType(animalIndex)
	for _, animal in pairs(self.typeToAnimal) do
		for _, animalSubtype in pairs(animal.subTypes) do
			if animalSubtype.index == animalIndex then
				return animal.type
			end
		end
	end

	return nil
end

function AnimalManager:getFillType(animalIndex, subtypeIndex)
	local animal = self.indexToAnimal[animalIndex]

	if animal ~= nil then
		local animalSubType = animal.subTypes[subtypeIndex]

		if animalSubType ~= nil then
			local fillType = g_fillTypeManager:getFillTypeByIndex(animalSubType.fillType)

			if fillType ~= nil then
				return fillType
			end
		end
	end

	g_logManager:devWarning("Warning: could not find fillType for animal id(%d) subTypeId(%d)!", animalIndex, subtypeIndex)

	return nil
end

function AnimalManager:getStoreInfo(animalIndex, subtypeIndex)
	local animal = self.indexToAnimal[animalIndex]

	if animal ~= nil then
		local animalSubType = animal.subTypes[subtypeIndex]

		return animalSubType.storeInfo
	end

	return nil
end

function AnimalManager:getClassObjectFromFillTypeName(fillTypeName)
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	return self:getClassObjectFromFillTypeIndex(fillTypeIndex)
end

function AnimalManager:getClassObjectFromFillTypeIndex(fillTypeIndex)
	local animalType = self:getAnimalByFillType(fillTypeIndex)

	if animalType == nil then
		return nil
	end

	local animal = self:getAnimalsByType(animalType.type)

	if animal ~= nil then
		return ClassUtil.getClassObject(animal.class), fillTypeIndex
	end

	return nil
end

g_animalManager = AnimalManager:new()
