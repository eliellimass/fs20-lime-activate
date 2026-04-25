LivestockTrailer = {}

function LivestockTrailer.initSpecialization()
	g_storeManager:addSpecType("numAnimalsCow", "shopListAttributeIconCow", LivestockTrailer.loadSpecValueNumberAnimalsCow, LivestockTrailer.getSpecValueNumberAnimalsCow)
	g_storeManager:addSpecType("numAnimalsPig", "shopListAttributeIconPig", LivestockTrailer.loadSpecValueNumberAnimalsPig, LivestockTrailer.getSpecValueNumberAnimalsPig)
	g_storeManager:addSpecType("numAnimalsSheep", "shopListAttributeIconSheep", LivestockTrailer.loadSpecValueNumberAnimalsSheep, LivestockTrailer.getSpecValueNumberAnimalsSheep)
	g_storeManager:addSpecType("numAnimalsHorse", "shopListAttributeIconHorse", LivestockTrailer.loadSpecValueNumberAnimalsHorse, LivestockTrailer.getSpecValueNumberAnimalsHorse)
end

function LivestockTrailer.prerequisitesPresent(specializations)
	return true
end

function LivestockTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addAnimal", LivestockTrailer.addAnimal)
	SpecializationUtil.registerFunction(vehicleType, "addAnimals", LivestockTrailer.addAnimals)
	SpecializationUtil.registerFunction(vehicleType, "removeAnimal", LivestockTrailer.removeAnimal)
	SpecializationUtil.registerFunction(vehicleType, "removeAnimals", LivestockTrailer.removeAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentAnimalType", LivestockTrailer.getCurrentAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalType", LivestockTrailer.getSupportsAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getAnimals", LivestockTrailer.getAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getAnimalPlaces", LivestockTrailer.getAnimalPlaces)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingTrigger", LivestockTrailer.setLoadingTrigger)
end

function LivestockTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", LivestockTrailer.getAdditionalComponentMass)
end

function LivestockTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", LivestockTrailer)
end

function LivestockTrailer:onLoad(savegame)
	local spec = self.spec_livestockTrailer
	spec.animalPlaces = {}
	spec.animalTypeToPlaces = {}
	local i = 0

	while true do
		local key = string.format("vehicle.livestockTrailer.animal(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local place = {
			numUsed = 0
		}
		local animalTypeStr = getXMLString(self.xmlFile, key .. "#type")
		local animalType = g_animalManager:getAnimalsByType(animalTypeStr)

		if animalType == nil then
			g_logManager:xmlWarning(self.configFileName, "Animal type '%s' could not be found!", animalTypeStr)

			break
		end

		place.animalType = animalType.type

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

		place.slots = {}
		local parent = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
		local numSlots = math.abs(getXMLInt(self.xmlFile, key .. "#numSlots") or 0)

		if getNumOfChildren(parent) < numSlots then
			g_logManager:xmlWarning(self.configFileName, "numSlots is greater than available children for '%s'", key)

			numSlots = getNumOfChildren(parent)
		end

		for j = 0, numSlots - 1 do
			local slotNode = getChildAt(parent, j)

			table.insert(place.slots, {
				linkNode = slotNode,
				place = place
			})
		end

		table.insert(spec.animalPlaces, place)

		spec.animalTypeToPlaces[place.animalType] = place
		i = i + 1
	end

	spec.loadedAnimals = {}
	spec.loadedAnimalsIds = {}
	spec.animalToSlots = {}
	spec.animalsToLoad = nil
	spec.loadingTrigger = nil
	spec.currentAnimalType = nil
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function LivestockTrailer:onLoadFinished(savegame)
	local spec = self.spec_livestockTrailer

	if savegame ~= nil and not savegame.resetVehicles then
		local key = string.format("%s.livestockTrailer", savegame.key)
		local i = 0
		local xmlFile = savegame.xmlFile

		while true do
			local slotKey = string.format("%s.animal(%d)", key, i)

			if not hasXMLProperty(xmlFile, slotKey) then
				break
			end

			local animal = Animal.createFromXMLFile(xmlFile, slotKey, self.isServer, self.isClient, nil)

			animal:register()
			self:addAnimal(animal)

			i = i + 1
		end
	end
end

function LivestockTrailer:onDelete()
	local spec = self.spec_livestockTrailer

	if spec.loadingTrigger ~= nil then
		spec.loadingTrigger:setLoadingTrailer(nil)
	end
end

function LivestockTrailer:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_livestockTrailer
	local num = 0

	for _, animal in ipairs(spec.loadedAnimals) do
		local animalKey = string.format("%s.animal(%d)", key, num)

		animal:saveToXMLFile(xmlFile, animalKey, usedModNames)

		num = num + 1
	end
end

function LivestockTrailer:onReadStream(streamId, connection)
	local spec = self.spec_livestockTrailer
	spec.animalsToLoad = {}
	local numAnimals = streamReadUInt8(streamId)

	for i = 1, numAnimals do
		local animalId = NetworkUtil.readNodeObjectId(streamId)

		table.insert(spec.animalsToLoad, animalId)
	end
end

function LivestockTrailer:onWriteStream(streamId, connection)
	local spec = self.spec_livestockTrailer

	streamWriteUInt8(streamId, #spec.loadedAnimals)

	for _, animal in ipairs(spec.loadedAnimals) do
		NetworkUtil.writeNodeObject(streamId, animal)
	end
end

function LivestockTrailer:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_livestockTrailer

		if streamReadBool(streamId) then
			local numAnimals = streamReadUInt8(streamId)
			local currentAnimalIds = {}

			if spec.animalsToLoad == nil then
				spec.animalsToLoad = {}
			end

			for i = 1, numAnimals do
				local animalId = NetworkUtil.readNodeObjectId(streamId)

				if spec.loadedAnimalsIds[animalId] == nil then
					table.insert(spec.animalsToLoad, animalId)
				end

				currentAnimalIds[animalId] = true
			end

			for i = #spec.loadedAnimals, 1, -1 do
				local animal = spec.loadedAnimals[i]
				local animalId = NetworkUtil.getObjectId(animal)

				if animalId == nil or currentAnimalIds[animalId] == nil then
					self:removeAnimal(animal)
				end
			end
		end
	end
end

function LivestockTrailer:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_livestockTrailer

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteUInt8(streamId, #spec.loadedAnimals)

			for _, animal in ipairs(spec.loadedAnimals) do
				NetworkUtil.writeNodeObject(streamId, animal)
			end
		end
	end
end

function LivestockTrailer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_livestockTrailer

	if spec.animalsToLoad ~= nil then
		for i = #spec.animalsToLoad, 1, -1 do
			local animalId = spec.animalsToLoad[i]
			local animal = NetworkUtil.getObject(animalId)

			if animal ~= nil then
				self:addAnimal(animal)
				table.remove(spec.animalsToLoad, i)
			end
		end

		if #spec.animalsToLoad == 0 then
			spec.animalsToLoad = nil
		end
	end
end

function LivestockTrailer:getSupportsAnimalType(animalType)
	return self.spec_livestockTrailer.animalTypeToPlaces[animalType]
end

function LivestockTrailer:addAnimals(animals)
	for _, animal in ipairs(animals) do
		self:addAnimal(animal)
	end
end

function LivestockTrailer:addAnimal(animal)
	local spec = self.spec_livestockTrailer
	local success, _ = ListUtil.addElementToList(spec.loadedAnimals, animal)

	if success then
		spec.currentAnimalType = animal:getSubType().type
		spec.loadedAnimalsIds[NetworkUtil.getObjectId(animal)] = true
		spec.animalToSlots[animal] = {}
		local place = spec.animalTypeToPlaces[animal.subType.type]

		for _, slot in ipairs(place.slots) do
			if slot.loadedMesh == nil then
				local animalMeshRoot = g_i3DManager:loadSharedI3DFile(animal.subType.dummy.filename)
				local animalRoot = getChildAt(animalMeshRoot, 0)
				local animalMesh = I3DUtil.indexToObject(animalMeshRoot, animal.subType.dummy.meshNodeStr)
				local animalHairMesh = I3DUtil.indexToObject(animalMeshRoot, animal.subType.dummy.hairNodeStr)

				link(slot.linkNode, animalRoot)
				delete(animalMeshRoot)

				local x, y, z, w = getShaderParameter(animalMesh, "RDT")
				local dirt = animal:getDirtScale()

				setShaderParameter(animalMesh, "RDT", x, dirt, z, w, false)

				local x, y, _, _ = getShaderParameter(animalMesh, "atlasInvSizeAndOffsetUV")
				local numTilesU = 1 / x
				local numTilesV = 1 / y
				local subType = animal:getSubType()
				local tileUIndex = subType.texture.tileUIndex
				local tileVIndex = subType.texture.tileVIndex
				local tileU = tileUIndex / numTilesU
				local tileV = tileVIndex / numTilesV

				setShaderParameter(animalMesh, "atlasInvSizeAndOffsetUV", x, y, tileU, tileV, false)

				if animalHairMesh ~= nil then
					local x, y, _, _ = getShaderParameter(animalHairMesh, "atlasInvSizeAndOffsetUV")

					setShaderParameter(animalHairMesh, "atlasInvSizeAndOffsetUV", x, y, tileU, tileV, false)
				end

				slot.loadedMesh = animalRoot

				table.insert(spec.animalToSlots[animal], slot)

				place.numUsed = place.numUsed + 1

				break
			end
		end

		self:setMassDirty()

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end
end

function LivestockTrailer:removeAnimals(animals)
	for _, animal in ipairs(animals) do
		self:removeAnimal(animal)
	end
end

function LivestockTrailer:removeAnimal(animal)
	local spec = self.spec_livestockTrailer
	local success = ListUtil.removeElementFromList(spec.loadedAnimals, animal)

	if success then
		local animalId = NetworkUtil.getObjectId(animal)

		if animalId ~= nil then
			spec.loadedAnimalsIds[animalId] = nil
		end

		for _, slot in ipairs(spec.animalToSlots[animal]) do
			delete(slot.loadedMesh)

			slot.loadedMesh = nil

			g_i3DManager:releaseSharedI3DFile(animal.subType.dummy.filename, nil, true)

			slot.place.numUsed = slot.place.numUsed - 1
		end

		spec.animalToSlots[animal] = nil

		self:setMassDirty()

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)
		end

		if #spec.loadedAnimals == 0 then
			spec.currentAnimalType = nil
		end
	end
end

function LivestockTrailer:getCurrentAnimalType()
	return self.spec_livestockTrailer.currentAnimalType
end

function LivestockTrailer:getAnimals()
	return self.spec_livestockTrailer.loadedAnimals
end

function LivestockTrailer:getAnimalPlaces()
	return self.spec_livestockTrailer.animalPlaces
end

function LivestockTrailer:setLoadingTrigger(trigger)
	self.spec_livestockTrailer.loadingTrigger = trigger
end

function LivestockTrailer:getAdditionalComponentMass(superFunc, component)
	local additionalMass = superFunc(self, component)
	local spec = self.spec_livestockTrailer

	for _, animal in ipairs(spec.loadedAnimals) do
		local fillTypeIndex = animal:getFillTypeIndex()
		local desc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		additionalMass = additionalMass + desc.massPerLiter
	end

	return additionalMass
end

function LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, animalTypeName)
	local maxNumAnimals = nil
	local i = 0
	local root = getXMLRootName(xmlFile)

	while true do
		local key = string.format("%s.livestockTrailer.animal(%d)", root, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local typeName = getXMLString(xmlFile, key .. "#type")

		if typeName ~= nil and string.lower(typeName) == string.lower(animalTypeName) then
			maxNumAnimals = getXMLInt(xmlFile, key .. "#numSlots") or 0

			break
		end

		i = i + 1
	end

	return maxNumAnimals
end

function LivestockTrailer.loadSpecValueNumberAnimalsCow(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "cow")
end

function LivestockTrailer.loadSpecValueNumberAnimalsPig(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "pig")
end

function LivestockTrailer.loadSpecValueNumberAnimalsSheep(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "sheep")
end

function LivestockTrailer.loadSpecValueNumberAnimalsHorse(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "horse")
end

function LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, specName)
	if storeItem.specs[specName] == nil then
		return nil
	end

	return string.format("%d %s", storeItem.specs[specName], g_i18n:getText("unit_pieces"))
end

function LivestockTrailer.getSpecValueNumberAnimalsCow(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsCow")
end

function LivestockTrailer.getSpecValueNumberAnimalsPig(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsPig")
end

function LivestockTrailer.getSpecValueNumberAnimalsSheep(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsSheep")
end

function LivestockTrailer.getSpecValueNumberAnimalsHorse(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsHorse")
end
