source("dataS/scripts/animals/AnimalHusbandryNoMorePalletSpaceEvent.lua")

AnimalHusbandry = {}
local AnimalHusbandry_mt = Class(AnimalHusbandry, Placeable)

InitStaticObjectClass(AnimalHusbandry, "AnimalHusbandry", ObjectIds.OBJECT_ANIMAL_HUSBANDRY)

AnimalHusbandry.NO_FILLTYPE_INFOS = {}
AnimalHusbandry.GAME_LIMIT = 10

function AnimalHusbandry.initPlaceableType()
	g_storeManager:addSpecType("numberAnimals", "shopListAttributeIconCapacity", AnimalHusbandry.loadSpecValueNumberAnimals, AnimalHusbandry.getSpecValueNumberAnimals)
	g_storeManager:addSpecType("animalFoodFillTypes", "shopListAttributeIconFillTypes", AnimalHusbandry.loadSpecValueAnimalFoodFillTypes, AnimalHusbandry.getSpecValueAnimalFoodFillTypes)
end

function AnimalHusbandry:new(isServer, isClient, mt)
	if mt == nil then
		mt = AnimalHusbandry_mt
	end

	local self = Placeable:new(isServer, isClient, mt)
	self.useMultiRootNode = true
	self.modulesByName = {}
	self.modulesById = {}
	self.updateMinutes = 0
	self.saveId = ""
	self.hasStatistics = false
	self.husbandryDirtyFlag = self:getNextDirtyFlag()
	self.globalProductionFactor = 0

	registerObjectClassName(self, "AnimalHusbandry")

	return self
end

function AnimalHusbandry:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not AnimalHusbandry:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local success = self:loadModules(xmlFilename)

	if success then
		local xmlFile = loadXMLFile("AnimalHusbandryXML", xmlFilename)
		local key = string.format("placeable.husbandry")
		self.saveId = Utils.getNoNil(getXMLString(xmlFile, key .. "#saveId"), "Animals_" .. self:getAnimalType())
		self.hasStatistics = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasStatistics"), false)

		if hasXMLProperty(xmlFile, key .. ".poiTriggers") then
			self.poiTriggers = {}
			local i = 0

			while true do
				local triggerKey = string.format("%s.poiTriggers.poiTrigger(%d)", key, i)

				if not hasXMLProperty(xmlFile, triggerKey) then
					break
				end

				local poiTrigger = POITrigger:new()

				if poiTrigger:loadFromXML(self.nodeId, xmlFile, triggerKey) then
					table.insert(self.poiTriggers, poiTrigger)
				else
					poiTrigger:delete()
				end

				i = i + 1
			end
		end

		delete(xmlFile)
	end

	return success
end

function AnimalHusbandry:loadModules(xmlFilename)
	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local key = string.format("placeable.husbandry")
	local i = 0

	if xmlFile == 0 then
		return false
	end

	while true do
		local moduleNameKey = string.format("%s.modules.module(%d)#name", key, i)

		if not hasXMLProperty(xmlFile, moduleNameKey) then
			break
		end

		local moduleName = getXMLString(xmlFile, moduleNameKey)
		local newModule = HusbandryModuleBase.createModule(moduleName)

		if newModule ~= nil then
			local moduleConfigKey = string.format("%s.modules.module(%d).config", key, i)
			local success = newModule:load(xmlFile, moduleConfigKey, self.nodeId, self)

			if not success then
				return false
			end

			self.modulesByName[moduleName] = newModule
			newModule.moduleName = moduleName

			table.insert(self.modulesById, newModule)
		end

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function AnimalHusbandry:modulesFinalizePlacement()
	for _, moduleInstance in pairs(self.modulesById) do
		local success = moduleInstance:finalizePlacement()

		if success ~= true then
			return false
		end
	end

	return true
end

function AnimalHusbandry:getCanBePlacedAt(x, y, z, distance)
	local canBePlaced = AnimalHusbandry:superClass().getCanBePlacedAt(self, x, y, z, distance)

	return canBePlaced and self:canAddMoreHusbandriesToGame()
end

function AnimalHusbandry:canBuy()
	local canBuy = AnimalHusbandry:superClass().canBuy(self)

	return canBuy and self:canAddMoreHusbandriesToGame(), g_i18n:getText("warning_tooManyHusbandries")
end

function AnimalHusbandry:canBeSold()
	for _, moduleInstance in ipairs(self.modulesById) do
		if moduleInstance:getIsInUse() then
			return false
		end
	end

	return AnimalHusbandry:superClass().canBeSold(self)
end

function AnimalHusbandry:finalizePlacement()
	AnimalHusbandry:superClass().finalizePlacement(self)

	local success = self:modulesFinalizePlacement() and self:registerHusbandryToMission()

	if not success then
		return false
	end

	if self.isServer then
		g_currentMission.environment:addMinuteChangeListener(self)
		g_currentMission.environment:addHourChangeListener(self)
		g_currentMission.environment:addDayChangeListener(self)
	end

	return true
end

function AnimalHusbandry:onSell()
	AnimalHusbandry:superClass().onSell(self)

	for i = #self.modulesById, 1, -1 do
		self.modulesById[i]:onSell()
	end

	if self.isServer then
		g_currentMission.environment:removeMinuteChangeListener(self)
		g_currentMission.environment:removeHourChangeListener(self)
		g_currentMission.environment:removeDayChangeListener(self)
	end
end

function AnimalHusbandry:delete()
	g_currentMission:removeOnCreateLoadedObjectToSave(self)
	self:unregisterHusbandryToMission()

	for _, moduleInstance in pairs(self.modulesById) do
		moduleInstance:delete()
	end

	if self.isServer and self.palletSpawnerTriggerId ~= nil then
		removeTrigger(self.palletSpawnerTriggerId)
	end

	if self.poiTriggers ~= nil then
		for _, trigger in ipairs(self.poiTriggers) do
			trigger:delete()
		end

		self.poiTriggers = nil
	end

	AnimalHusbandry:superClass().delete(self)
end

function AnimalHusbandry:loadFromXMLFile(xmlFile, key)
	AnimalHusbandry:superClass().loadFromXMLFile(self, xmlFile, key, nil)

	self.globalProductionFactor = getXMLFloat(xmlFile, key .. "#globalProductionFactor") or self.globalProductionFactor
	local i = 0

	while true do
		local moduleKey = string.format("%s.module(%d)", key, i)
		local moduleNameKey = string.format("%s#name", moduleKey)

		if not hasXMLProperty(xmlFile, moduleNameKey) then
			break
		end

		local moduleName = getXMLString(xmlFile, moduleNameKey)
		local moduleInstance = self:getModuleByName(moduleName)

		if moduleInstance ~= nil then
			moduleInstance:loadFromXMLFile(xmlFile, moduleKey)
		end

		i = i + 1
	end

	return true
end

function AnimalHusbandry:saveToXMLFile(xmlFile, key, usedModNames)
	AnimalHusbandry:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#globalProductionFactor", self.globalProductionFactor)

	local index = 0

	for moduleName, moduleInstance in pairs(self.modulesByName) do
		if moduleInstance ~= nil then
			local moduleKey = string.format("%s.module(%d)", key, index)

			setXMLString(xmlFile, moduleKey .. "#name", moduleName)
			moduleInstance:saveToXMLFile(xmlFile, moduleKey)

			index = index + 1
		end
	end
end

function AnimalHusbandry:readStream(streamId, connection)
	AnimalHusbandry:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, moduleInstance in ipairs(self.modulesById) do
			moduleInstance:readStream(streamId, connection)
		end
	end
end

function AnimalHusbandry:writeStream(streamId, connection)
	AnimalHusbandry:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, moduleInstance in ipairs(self.modulesById) do
			moduleInstance:writeStream(streamId, connection)
		end
	end
end

function AnimalHusbandry:readUpdateStream(streamId, timestamp, connection)
	AnimalHusbandry:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		for _, moduleInstance in ipairs(self.modulesById) do
			moduleInstance:readUpdateStream(streamId, timestamp, connection)
		end

		self.globalProductionFactor = streamReadFloat32(streamId)
	end
end

function AnimalHusbandry:writeUpdateStream(streamId, connection, dirtyMask)
	AnimalHusbandry:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		local isDirty = bitAND(dirtyMask, self.husbandryDirtyFlag) ~= 0

		if streamWriteBool(streamId, isDirty) then
			for _, moduleInstance in ipairs(self.modulesById) do
				moduleInstance:writeUpdateStream(streamId, connection, dirtyMask)
			end

			streamWriteFloat32(streamId, self.globalProductionFactor)
		end
	end
end

function AnimalHusbandry:update(dt)
	AnimalHusbandry:superClass().update(self, dt)

	local needsUpdate = false

	for _, moduleInstance in pairs(self.modulesById) do
		needsUpdate = needsUpdate or moduleInstance:update(dt)
	end

	if needsUpdate then
		self:raiseActive()
	end
end

function AnimalHusbandry:onIntervalModulesUpdate(dayInterval)
	for _, moduleInstance in pairs(self.modulesById) do
		moduleInstance:onIntervalUpdate(dayInterval)
	end
end

function AnimalHusbandry:minuteChanged(minute)
	if minute % 15 == 0 then
		for _, moduleInstance in pairs(self.modulesById) do
			moduleInstance:onQuarterHourChanged()
		end

		if self:getNumOfAnimals() > 0 and self.isServer then
			local dayInterval = 0.010416666666666666

			self:onIntervalModulesUpdate(dayInterval)
			self:updateGlobalProductionFactor()
			self:raiseDirtyFlags(self.husbandryDirtyFlag)
		end
	end
end

function AnimalHusbandry:hourChanged()
	for _, moduleInstance in pairs(self.modulesById) do
		moduleInstance:onHourChanged()
	end
end

function AnimalHusbandry:dayChanged()
	for _, moduleInstance in pairs(self.modulesById) do
		moduleInstance:onDayChanged()
	end
end

function AnimalHusbandry:updateGlobalProductionFactor()
	self.globalProductionFactor = 0

	if self:hasWater() then
		local foodFactor = self:getFoodProductionFactor()

		if foodFactor > 0 then
			if self:hasStraw() then
				self.globalProductionFactor = 0.1
			end

			local foodSpillageFactor = self:getFoodSpillageFactor() or 1
			self.globalProductionFactor = self.globalProductionFactor + foodSpillageFactor * 0.1 + foodFactor * 0.8
		end
	end
end

function AnimalHusbandry:getFluidStatsText(fillLevel, alwaysExact)
	fillLevel = Utils.getNoNil(fillLevel, 0)

	if self.isServer or alwaysExact or fillLevel == 0 then
		return string.format("%1.0f", math.floor(g_i18n:getFluid(fillLevel)))
	else
		return string.format("~%1.0f", math.floor(g_i18n:getFluid(fillLevel)))
	end
end

function AnimalHusbandry:collectPickObjects(node, target)
	for _, moduleInstance in pairs(self.modulesById) do
		if moduleInstance:getIsNodeUsed(node) then
			return
		end
	end

	AnimalHusbandry:superClass().collectPickObjects(self, node, target)
end

function AnimalHusbandry:getModuleById(moduleId)
	local moduleinstance = self.modulesById[moduleId]

	return moduleinstance
end

function AnimalHusbandry:getModuleByName(moduleName)
	if HusbandryModuleBase.hasModule(moduleName) then
		return self.modulesByName[moduleName]
	end

	g_logManager:warning("Animal module '%s' is not registered!", tostring(moduleName))

	return nil
end

function AnimalHusbandry:setModuleParameters(moduleName, capacity, usagePerDay)
	local moduleInstance = self:getModuleByName(moduleName)

	if moduleInstance ~= nil then
		moduleInstance:setCapacity(capacity)
		moduleInstance:setSingleAnimalUsagePerDay(usagePerDay)
	end
end

function AnimalHusbandry:getNumOfAnimals()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getNumOfAnimals()
	end

	return 0
end

function AnimalHusbandry:getAnimalType()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getAnimalType()
	end

	return nil
end

function AnimalHusbandry:getConsumedFood()
	local foodModule = self:getModuleByName("food")

	if foodModule ~= nil then
		return foodModule:getConsumedFood()
	end

	return nil
end

function AnimalHusbandry:getFoodProductionFactor()
	local foodModule = self:getModuleByName("food")

	if foodModule ~= nil then
		return foodModule:getFoodFactor()
	end

	return 0
end

function AnimalHusbandry:hasStraw()
	local strawModule = self:getModuleByName("straw")

	if strawModule ~= nil then
		return strawModule:hasStraw()
	end

	return true
end

function AnimalHusbandry:hasWater()
	local waterModule = self:getModuleByName("water")

	if waterModule ~= nil then
		return waterModule:hasWater()
	end

	return true
end

function AnimalHusbandry:getFoodFilltypeInfo()
	local foodModule = self:getModuleByName("food")

	if foodModule ~= nil then
		return foodModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getWaterFilltypeInfo()
	local waterModule = self:getModuleByName("water")

	if waterModule ~= nil then
		return waterModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getStrawFilltypeInfo()
	local strawModule = self:getModuleByName("straw")

	if strawModule ~= nil then
		return strawModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getPalletsFilltypeInfo()
	local palletsModule = self:getModuleByName("pallets")

	if palletsModule ~= nil then
		return palletsModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getLiquidManureFilltypeInfo()
	local liquidManureModule = self:getModuleByName("liquidManure")

	if liquidManureModule ~= nil then
		return liquidManureModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getManureFilltypeInfo()
	local manureModule = self:getModuleByName("manure")

	if manureModule ~= nil then
		return manureModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:getProductionFilltypeInfo()
	local manureProduction = self:getManureFilltypeInfo()
	local liquidManureProduction = self:getLiquidManureFilltypeInfo()
	local milkProduction = self:getMilkFilltypeInfo()
	local palletsProduction = self:getPalletsFilltypeInfo()
	local result = {}

	if manureProduction ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		table.insert(result, manureProduction)
	end

	if liquidManureProduction ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		table.insert(result, liquidManureProduction)
	end

	if milkProduction ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		table.insert(result, milkProduction)
	elseif palletsProduction ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		table.insert(result, palletsProduction)
	end

	return result
end

function AnimalHusbandry:getFoodSpillageFactor()
	local foodSpillageModule = self:getModuleByName("foodSpillage")

	if foodSpillageModule ~= nil then
		return foodSpillageModule:getSpillageFactor()
	end

	return nil
end

function AnimalHusbandry:getMilkFilltypeInfo()
	local milkModule = self:getModuleByName("milk")

	if milkModule ~= nil then
		return milkModule:getFilltypeInfos()
	end

	return AnimalHusbandry.NO_FILLTYPE_INFOS
end

function AnimalHusbandry:isSimilarHusbandryRegistered()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		local animalType = animalsModule:getAnimalType()

		if animalType ~= nil then
			for _, husbandry in pairs(g_currentMission.husbandries) do
				if animalType == husbandry:getAnimalType() and husbandry:getOwnerFarmId() == self:getOwnerFarmId() then
					return true
				end
			end
		end
	end

	return false
end

function AnimalHusbandry:canAddMoreHusbandriesToGame()
	return ListUtil.size(g_currentMission.husbandries) < AnimalHusbandry.GAME_LIMIT
end

function AnimalHusbandry:registerHusbandryToMission()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		local husbandryId = animalsModule.husbandryId

		g_currentMission:registerHusbandry(husbandryId, self)

		return true
	end

	return false
end

function AnimalHusbandry:unregisterHusbandryToMission()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		local husbandryId = animalsModule.husbandryId

		if husbandryId ~= nil then
			g_currentMission:unregisterHusbandry(husbandryId)

			return true
		end
	end

	return false
end

function AnimalHusbandry:getNumAnimalSubTypes()
	local count = 0
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		count = animalsModule:getNumAnimalSubTypes()
	end

	return count
end

function AnimalHusbandry:getAnimals()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getAnimals()
	end
end

function AnimalHusbandry:getTypedAnimals()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getTypedAnimals()
	end
end

function AnimalHusbandry:getSupportsSubType(subType)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getSupportsSubType(subType)
	end
end

function AnimalHusbandry:getMaxNumAnimals()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule.maxNumAnimals
	end
end

function AnimalHusbandry:getHusbandryModule()
	return self:getModuleByName("animals")
end

function AnimalHusbandry:getHusbandryId()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule.husbandryId
	end

	return nil
end

function AnimalHusbandry:addAnimals(animals)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:addAnimals(animals)
	end
end

function AnimalHusbandry:addSingleAnimal(animal)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:addSingleAnimal(animal)
	end
end

function AnimalHusbandry:addPendingAnimal(animalObjectId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:addPendingAnimal(animalObjectId)
	end
end

function AnimalHusbandry:removeAnimals(animals)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:removeAnimals(animals)
	end
end

function AnimalHusbandry:removeSingleAnimal(animal)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:removeSingleAnimal(animal)
	end
end

function AnimalHusbandry:addRideable(visualId, player)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:addRideable(visualId, player)
	end
end

function AnimalHusbandry:removeRideable(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:removeRideable(visualId)
		animalsModule:updateVisualDirt()
	end
end

function AnimalHusbandry:isRideableInOnHusbandryGround(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:isRideableInOnHusbandryGround(visualId)
	end

	return false
end

function AnimalHusbandry:getSupportsRiding(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getSupportsRiding(visualId)
	end

	return false
end

function AnimalHusbandry:getCanBeRidden(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getCanBeRidden(visualId)
	end

	return false
end

function AnimalHusbandry:cleanAnimal(visualId, dt)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:cleanAnimal(visualId, dt)
	end
end

function AnimalHusbandry:isAnimalDirty(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:isAnimalDirty(visualId)
	end

	return false
end

function AnimalHusbandry:getGlobalProductionFactor()
	return self.globalProductionFactor
end

function AnimalHusbandry:getFilltype(subTypeId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		local fillType = animalsModule:getFillType(subTypeId)

		return fillType
	end

	return nil
end

function AnimalHusbandry:getGlobalDirtFactor()
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getDirtFactor()
	end

	return 0
end

function AnimalHusbandry:setAnimalDirt(animalId, dirtScale)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:setAnimalDirt(animalId, dirtScale)
	end
end

function AnimalHusbandry:renameAnimal(animalId, name, noEventSend)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		animalsModule:renameAnimal(animalId, name, noEventSend)
	end
end

function AnimalHusbandry:getAnimalName(visualId)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getAnimalName(visualId)
	end

	return ""
end

function AnimalHusbandry:getReproductionTimePerDay(fillTypeIndex)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getReproductionTimePerDay(fillTypeIndex)
	end

	return 0
end

function AnimalHusbandry:getMinutesUntilNextAnimal(fillTypeIndex)
	local animalsModule = self:getModuleByName("animals")

	if animalsModule ~= nil then
		return animalsModule:getMinutesUntilNextAnimal(fillTypeIndex)
	end

	return nil
end

function AnimalHusbandry.loadSpecValueNumberAnimals(xmlFile, customEnvironment)
	local maxNumAnimals = nil
	local i = 0

	while true do
		local key = string.format("placeable.husbandry.modules.module(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local moduleName = getXMLString(xmlFile, key .. "#name")

		if moduleName ~= nil and string.lower(moduleName) == "animals" then
			maxNumAnimals = getXMLInt(xmlFile, key .. ".config#maxNumAnimals") or 16

			break
		end

		i = i + 1
	end

	return maxNumAnimals
end

function AnimalHusbandry.getSpecValueNumberAnimals(storeItem, realItem)
	if storeItem.specs.numberAnimals == nil then
		return nil
	end

	return storeItem.specs.numberAnimals
end

function AnimalHusbandry.loadSpecValueAnimalFoodFillTypes(xmlFile, customEnvironment)
	local animalType, waterFillTypes = nil
	local i = 0

	while true do
		local key = string.format("placeable.husbandry.modules.module(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local moduleName = getXMLString(xmlFile, key .. "#name")

		if moduleName ~= nil and string.lower(moduleName) == "animals" then
			animalType = getXMLString(xmlFile, key .. ".config#type")
		end

		if moduleName ~= nil and string.lower(moduleName) == "water" then
			waterFillTypes = getXMLString(xmlFile, key .. ".config#fillTypes")
		end

		i = i + 1
	end

	if animalType ~= nil then
		return {
			animalType = animalType,
			waterFillTypes = waterFillTypes
		}
	end

	return animalType
end

function AnimalHusbandry.getSpecValueAnimalFoodFillTypes(storeItem, realItem)
	local data = storeItem.specs.animalFoodFillTypes

	if data == nil then
		return nil
	end

	local fillTypes = {}

	if data.animalType ~= nil then
		local foodGroups = g_animalFoodManager:getFoodGroupByAnimalType(data.animalType)
		local foodMixtures = g_animalFoodManager:getFoodMixturesByAnimalType(data.animalType)

		if foodGroups ~= nil then
			for _, foodGroup in pairs(foodGroups) do
				for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
					ListUtil.addElementToList(fillTypes, fillTypeIndex)
				end
			end

			if foodMixtures ~= nil then
				for _, foodMixtureFillType in ipairs(foodMixtures) do
					ListUtil.addElementToList(fillTypes, foodMixtureFillType)
				end
			end
		end
	end

	if data.waterFillTypes ~= nil then
		local waterFillTypes = g_fillTypeManager:getFillTypesByNames(data.waterFillTypes, nil)

		for _, fillType in ipairs(waterFillTypes) do
			ListUtil.addElementToList(fillTypes, fillType)
		end
	end

	return fillTypes
end
