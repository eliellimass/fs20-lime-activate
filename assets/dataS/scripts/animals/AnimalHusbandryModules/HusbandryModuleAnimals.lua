HusbandryModuleAnimal = {
	SEND_NUM_BITS = 9,
	TROUGH_CAPACITY = 10,
	HEALTH_DECREASE_AT_INTERVAL = -0.0075,
	HEALTH_DECREASE_FOR_PRODUCTION = 0.015
}
local HusbandryModuleAnimal_mt = Class(HusbandryModuleAnimal, HusbandryModuleBase)

HusbandryModuleBase.registerModule("animals", HusbandryModuleAnimal)

function HusbandryModuleAnimal:new(customMt)
	local self = HusbandryModuleBase:new(customMt or HusbandryModuleAnimal_mt)

	return self
end

function HusbandryModuleAnimal:delete()
	for i = #self.animals, 1, -1 do
		local animal = self.animals[i]

		self:removeSingleAnimal(animal, true, false)
		animal:delete()
	end

	self:updateVisualAnimals()

	if self.animalLoadingTrigger ~= nil then
		self.animalLoadingTrigger:delete()

		self.animalLoadingTrigger = nil
	end

	if self.husbandryId ~= 0 then
		delete(self.husbandryId)

		self.husbandryId = nil
	end
end

function HusbandryModuleAnimal:initDataStructures()
	HusbandryModuleAnimal:superClass().initDataStructures(self)

	self.animalType = ""
	self.updateVisuals = false
	self.animalsToAdd = nil
	self.renamingTasks = nil
	self.animals = {}
	self.typedAnimals = {}
	self.reproductionRatesPerDay = {}
	self.newAnimalPercentages = {}
	self.visualIdToAnimal = {}
	self.visualAnimals = {}
	self.maxNumAnimals = 0
	self.carryingCapacity = 0
	self.navMeshNode = nil
	self.animalHusbandryXMLFilename = ""
	self.placementRaycastDistance = 2
	self.husbandryId = 0
	self.animalLoadingTrigger = nil
	self.rideableDeliveryArea = {
		startNode = nil,
		widthNode = nil,
		heightNode = nil
	}
	self.isDirtyFlag = 0
end

function HusbandryModuleAnimal:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleAnimal:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	self.animalType = getXMLString(xmlFile, configKey .. "#type")

	if self.animalType == nil then
		g_logManager:error("Missing animal type for husbandry!")

		return false
	end

	if self.animalType ~= nil then
		local animals = g_animalManager:getAnimalsByType(self.animalType)

		if animals == nil then
			g_logManager:error("Animal type '%s' not found!", self.animalType)

			return false
		end

		for _, subType in ipairs(animals.subTypes) do
			self.reproductionRatesPerDay[subType.fillType] = 0
			self.newAnimalPercentages[subType.fillType] = 0
		end
	end

	self.navMeshNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#navmeshNode"))

	if self.navMeshNode == nil then
		g_logManager:error("Invalid navMeshIndex in '%s'!", getName(rootNode))

		return false
	end

	self.rideableDeliveryArea = {
		startNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#rideableDeliveryStartNode")),
		widthNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#rideableDeliveryWidthNode")),
		heightNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#rideableDeliveryHeightNode"))
	}
	self.animalHusbandryXMLFilename = Utils.getNoNil(getXMLString(xmlFile, configKey .. "#husbandryFileName"), "")
	self.animalHusbandryXMLFilename = Utils.getFilename(self.animalHusbandryXMLFilename, g_currentMission.baseDirectory)

	if self.animalHusbandryXMLFilename == "" then
		g_logManager:error("Missing animal husbandry xml filename!")

		return false
	end

	self.placementRaycastDistance = Utils.getNoNil(getXMLFloat(xmlFile, configKey .. "#placementRaycastDistance"), 2)
	self.maxNumAnimals = Utils.getNoNil(getXMLInt(xmlFile, configKey .. "#maxNumAnimals"), 16)
	self.carryingCapacity = Utils.getNoNil(getXMLInt(xmlFile, configKey .. "#carryingCapacity"), 16)
	local animalLoadTriggerId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#animalLoadTriggerNode"))

	if animalLoadTriggerId ~= nil then
		self.animalLoadingTrigger = AnimalLoadingTrigger:new(self.owner.isServer, self.owner.isClient)

		if self.animalLoadingTrigger ~= nil then
			self.animalLoadingTrigger:load(animalLoadTriggerId, self.owner)
			self.animalLoadingTrigger:register(true)
		end
	end

	if self.animalType == "HORSE" then
		self.maxNumVisualAnimals = math.min(self.maxNumAnimals, 16)
		self.maxNumAnimals = math.min(self.maxNumAnimals, 16)
	else
		local profileClass = Utils.getPerformanceClassId()

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE or profileClass == GS_PROFILE_LOW then
			self.maxNumVisualAnimals = 10
		elseif GS_PROFILE_VERY_HIGH <= profileClass then
			self.maxNumVisualAnimals = 25
		elseif GS_PROFILE_HIGH <= profileClass then
			self.maxNumVisualAnimals = 20
		else
			self.maxNumVisualAnimals = 16
		end
	end

	local maxAnimals = 2^HusbandryModuleAnimal.SEND_NUM_BITS - 1

	if maxAnimals < self.maxNumAnimals then
		g_logManager:warning("Maximum number of animals reached! Maximum is '%d'!", maxAnimals)

		self.maxNumAnimals = maxAnimals
	end

	if GS_IS_MOBILE_VERSION then
		self.maxNumVisualAnimals = math.min(self.maxNumVisualAnimals, 8)
	end

	self.isDirtyFlag = self.owner:getNextDirtyFlag()
	self.animalCleanSendTimer = 0
	self.animalCleanSendId = 0

	self:updateAnimalParameters()

	return true
end

function HusbandryModuleAnimal:finalizePlacement()
	if not HusbandryModuleAnimal:superClass().finalizePlacement(self) then
		return false
	end

	local collisionMaskFilter = 4294967295.0

	if g_currentMission.missionDynamicInfo.isMultiplayer then
		collisionMaskFilter = 268435456
	end

	self.husbandryId = createAnimalHusbandry(self.animalType, self.navMeshNode, self.animalHusbandryXMLFilename, self.placementRaycastDistance, collisionMaskFilter)

	if self.husbandryId == 0 then
		g_logManager:error("Could not create animal husbandry!")

		return false
	end

	g_currentMission:registerObjectToCallOnMissionStart(self)

	return true
end

function HusbandryModuleAnimal:readStream(streamId, connection)
	HusbandryModuleAnimal:superClass().readStream(self, streamId, connection)

	self.animalsToAdd = {}
	local numAnimals = streamReadUInt16(streamId)

	for i = 1, numAnimals do
		local animalObjectId = NetworkUtil.readNodeObjectId(streamId)

		table.insert(self.animalsToAdd, animalObjectId)
	end

	local animals = g_animalManager:getAnimalsByType(self.animalType)

	for _, subType in ipairs(animals.subTypes) do
		self.reproductionRatesPerDay[subType.fillType] = streamReadFloat32(streamId)
		self.newAnimalPercentages[subType.fillType] = streamReadFloat32(streamId)
	end

	self:updateAnimalParameters()
end

function HusbandryModuleAnimal:writeStream(streamId, connection)
	HusbandryModuleAnimal:superClass().writeStream(self, streamId, connection)
	streamWriteUInt16(streamId, #self.animals)

	for _, animal in ipairs(self.animals) do
		local animalObjectId = NetworkUtil.getObjectId(animal)

		NetworkUtil.writeNodeObjectId(streamId, animalObjectId)
	end

	local animals = g_animalManager:getAnimalsByType(self.animalType)

	for _, subType in ipairs(animals.subTypes) do
		streamWriteFloat32(streamId, self.reproductionRatesPerDay[subType.fillType])
		streamWriteFloat32(streamId, self.newAnimalPercentages[subType.fillType])
	end
end

function HusbandryModuleAnimal:readUpdateStream(streamId, timestamp, connection)
	HusbandryModuleAnimal:superClass().readUpdateStream(self, streamId, timestamp, connection)

	local animals = g_animalManager:getAnimalsByType(self.animalType)

	for _, subType in ipairs(animals.subTypes) do
		self.reproductionRatesPerDay[subType.fillType] = streamReadFloat32(streamId)
		self.newAnimalPercentages[subType.fillType] = streamReadFloat32(streamId)
	end
end

function HusbandryModuleAnimal:writeUpdateStream(streamId, connection, dirtyMask)
	HusbandryModuleAnimal:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	local animals = g_animalManager:getAnimalsByType(self.animalType)

	for _, subType in ipairs(animals.subTypes) do
		streamWriteFloat32(streamId, self.reproductionRatesPerDay[subType.fillType])
		streamWriteFloat32(streamId, self.newAnimalPercentages[subType.fillType])
	end
end

function HusbandryModuleAnimal:loadFromXMLFile(xmlFile, key)
	HusbandryModuleAnimal:superClass().loadFromXMLFile(self, xmlFile, key)

	self.animalsToAdd = {}
	local i = 0

	while true do
		local animalKey = string.format("%s.animal(%d)", key, i)

		if not hasXMLProperty(xmlFile, animalKey) then
			break
		end

		local animal = Animal.createFromXMLFile(xmlFile, animalKey, self.owner.isServer, self.owner.isClient, self.owner)

		if animal ~= nil then
			animal:register()
			table.insert(self.animalsToAdd, NetworkUtil.getObjectId(animal))
		end

		i = i + 1
	end

	local i = 0

	while true do
		local animalKey = string.format("%s.breeding(%d)", key, i)

		if not hasXMLProperty(xmlFile, animalKey) then
			break
		end

		local fillTypeName = getXMLString(xmlFile, animalKey .. "#fillType")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex ~= nil then
			self.newAnimalPercentages[fillTypeIndex] = getXMLFloat(xmlFile, animalKey .. "#percentage") or 0
		end

		i = i + 1
	end
end

function HusbandryModuleAnimal:saveToXMLFile(xmlFile, key, usedModNames)
	HusbandryModuleAnimal:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	for i, animal in ipairs(self.animals) do
		local animalKey = string.format("%s.animal(%d)", key, i - 1)

		animal:saveToXMLFile(xmlFile, animalKey, usedModNames)
	end

	local i = 0

	for fillTypeIndex, percentage in pairs(self.newAnimalPercentages) do
		if percentage > 0 then
			local animalKey = string.format("%s.breeding(%d)", key, i)

			setXMLString(xmlFile, animalKey .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
			setXMLFloat(xmlFile, animalKey .. "#percentage", percentage)

			i = i + 1
		end
	end
end

function HusbandryModuleAnimal:update(dt)
	HusbandryModuleAnimal:superClass().update(self, dt)

	local needsUpdate = self.updateVisuals or self.animalsToAdd ~= nil or self.renamingTasks ~= nil or self.pendingRideables ~= nil or self.animalCleanSendTimer > 0

	if self.husbandryId ~= 0 and isHusbandryReady(self.husbandryId) then
		self:processAnimalChanges()

		needsUpdate = needsUpdate or self.animalsToAdd ~= nil
	end

	if self.animalCleanSendTimer > 0 then
		self.animalCleanSendTimer = self.animalCleanSendTimer - dt

		if self.animalCleanSendTimer <= 0 then
			local animal = self.visualIdToAnimal[self.animalCleanSendId]

			if animal ~= nil and animal.getDirtScale ~= nil then
				AnimalCleanEvent.sendEvent(self.owner, self.animalCleanSendId, animal:getDirtScale())
			end
		end
	end

	return needsUpdate
end

function HusbandryModuleAnimal:onMissionStarted()
	self:processAnimalChanges()
end

function HusbandryModuleAnimal:processAnimalChanges()
	if self.animalsToAdd ~= nil then
		for i = #self.animalsToAdd, 1, -1 do
			local id = self.animalsToAdd[i]
			local animal = NetworkUtil.getObject(id)

			if animal ~= nil then
				self:addSingleAnimal(animal, true)
				table.remove(self.animalsToAdd, i)
			end
		end

		if #self.animalsToAdd == 0 then
			self.animalsToAdd = nil

			self:updateBreeding(0)
		end
	end

	if self.renamingTasks ~= nil then
		for i = #self.renamingTasks, 1, -1 do
			local data = self.renamingTasks[i]
			local animal = NetworkUtil.getObject(data.animalId)

			if animal ~= nil then
				animal:setName(data.name)
				table.remove(self.renamingTasks, i)
			end
		end

		if #self.renamingTasks == 0 then
			self.renamingTasks = nil
		end
	end

	if self.updateVisuals then
		self:updateVisualAnimals()

		self.updateVisuals = false
	end

	if self.pendingRideables ~= nil then
		for i = #self.pendingRideables, 1, -1 do
			local animal = self.pendingRideables[i]

			if animal:tryToFinishRideable() then
				table.remove(self.pendingRideables, i)
			end
		end

		if #self.pendingRideables == 0 then
			self.pendingRideables = nil
		end
	end
end

function HusbandryModuleAnimal:onQuarterHourChanged()
	if self.husbandryId ~= 0 then
		setAnimalDaytime(self.husbandryId, g_currentMission.environment.dayTime)
	end

	self:updateBreeding(0.010416666666666666)
end

function HusbandryModuleAnimal:onHourChanged()
	self:updateHealth(false)
end

function HusbandryModuleAnimal:onDayChanged()
	local productionFactor = self.owner:getGlobalProductionFactor()

	self:updateFitness(productionFactor)
end

function HusbandryModuleAnimal:getSupportsSubType(subType)
	return subType.type == self.animalType
end

function HusbandryModuleAnimal:addAnimals(animals, noEventSend)
	local sendAnimals = {}

	for _, animal in ipairs(animals) do
		if self:addSingleAnimal(animal, true) then
			table.insert(sendAnimals, animal)
		end
	end

	if self.owner.isServer and noEventSend == nil or not noEventSend then
		g_server:broadcastEvent(AnimalAddEvent:new(self.owner, sendAnimals), nil, , , true)
	end
end

function HusbandryModuleAnimal:addSingleAnimal(animal, noEventSend)
	if self.maxNumAnimals <= #self.animals then
		return false
	end

	if not self:getSupportsSubType(animal:getSubType()) then
		return false
	end

	table.insert(self.animals, animal)

	local fillTypeIndex = animal:getFillTypeIndex()

	if self.typedAnimals[fillTypeIndex] == nil then
		self.typedAnimals[fillTypeIndex] = {}
	end

	table.insert(self.typedAnimals[fillTypeIndex], animal)
	animal:setOwner(self.owner)

	if self.owner.isServer and noEventSend == nil or not noEventSend then
		g_server:broadcastEvent(AnimalAddEvent:new(self.owner, {
			animal
		}), nil, , , true)
	end

	g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)
	self:updateAnimalParameters()

	self.updateVisuals = true

	self.owner:raiseActive()

	if animal:isa(RideableAnimal) and not animal:getIsRideableSetupDone() then
		if self.pendingRideables == nil then
			self.pendingRideables = {}
		end

		table.insert(self.pendingRideables, animal)
		self.owner:raiseActive()
	end

	return true
end

function HusbandryModuleAnimal:addPendingAnimal(animalObjectId)
	if self.animalsToAdd == nil then
		self.animalsToAdd = {}
	end

	table.insert(self.animalsToAdd, animalObjectId)
	self.owner:raiseActive()
end

function HusbandryModuleAnimal:removeAnimals(animals, noEventSend)
	local sendAnimals = {}

	for _, animal in ipairs(animals) do
		if self:removeSingleAnimal(animal, true) then
			table.insert(sendAnimals, animal)
		end
	end

	if self.owner.isServer and (noEventSend == nil or not noEventSend) then
		g_server:broadcastEvent(AnimalRemoveEvent:new(self.owner, sendAnimals), nil, , , true)
	end
end

function HusbandryModuleAnimal:removeSingleAnimal(animal, noEventSend, updateParameters)
	local found = false

	for i, storedAnimal in ipairs(self.animals) do
		if storedAnimal == animal then
			if self.owner.isServer and (noEventSend == nil or not noEventSend) then
				g_server:broadcastEvent(AnimalRemoveEvent:new(self.owner, {
					animal
				}), nil, , , true)
			end

			table.remove(self.animals, i)

			local fillTypeIndex = animal:getFillTypeIndex()

			table.remove(self.typedAnimals[fillTypeIndex], 1)

			found = true

			break
		end
	end

	if found then
		local visualId = animal:getVisualId()

		if visualId ~= nil then
			removeHusbandryAnimal(self.husbandryId, visualId)

			self.visualIdToAnimal[visualId] = nil

			animal:setVisualId(nil)

			local fillType = animal:getFillTypeIndex()

			for k, visual in ipairs(self.visualAnimals[fillType].visuals) do
				if visual.id == visualId then
					table.remove(self.visualAnimals[fillType].visuals, k)

					break
				end
			end

			if #self.visualAnimals[fillType].visuals == 0 then
				self.visualAnimals[fillType] = nil
			end
		end

		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)

		if updateParameters == nil or updateParameters then
			self:updateAnimalParameters()
		end

		self.updateVisuals = true

		self.owner:raiseActive()
		animal:setOwner(nil)

		return true
	end

	return false
end

function HusbandryModuleAnimal:updateVisualAnimals()
	local numAnimals = #self.animals
	local maxVisualAnimals = math.min(numAnimals, self.maxNumVisualAnimals)
	local usableAnimals = {}
	local percentages = {}

	for _, animal in ipairs(self.animals) do
		local fillType = animal:getFillTypeIndex()

		if percentages[fillType] == nil then
			percentages[fillType] = 0
			usableAnimals[fillType] = {}
		end

		percentages[fillType] = percentages[fillType] + 1

		if animal:getVisualId() == nil then
			table.insert(usableAnimals[fillType], animal)
		end
	end

	local instances = {}
	local fillTypeToIntance = {}
	local numInstances = 0

	for fillType, num in pairs(percentages) do
		local percentage = 0

		if #self.animals > 0 then
			percentage = num / numAnimals
		end

		local instance = {
			fillType = fillType,
			count = math.max(1, math.floor(maxVisualAnimals * percentage))
		}

		table.insert(instances, instance)

		fillTypeToIntance[fillType] = instance
		numInstances = numInstances + instance.count
	end

	local function sort(a1, a2)
		return a1.count < a2.count
	end

	table.sort(instances, sort)

	local dif = maxVisualAnimals - numInstances
	local i = 1

	while dif ~= 0 do
		local delta = MathUtil.sign(dif)
		instances[i].count = instances[i].count + delta
		dif = dif - delta
		i = i + 1

		if i > #instances then
			i = 1
		end
	end

	for k, visualAnimal in pairs(self.visualAnimals) do
		if fillTypeToIntance[visualAnimal.fillType] == nil then
			for i = 1, #visualAnimal.visuals do
				local visual = table.remove(visualAnimal.visuals, 1)

				removeHusbandryAnimal(self.husbandryId, visual.id)
				visual.animal:setVisualId(nil)

				self.visualIdToAnimal[visual.id] = nil
			end

			self.visualAnimals[k] = nil
		end
	end

	for _, instance in ipairs(instances) do
		local visualAnimal = self.visualAnimals[instance.fillType]

		if visualAnimal == nil then
			visualAnimal = {
				fillType = instance.fillType,
				visuals = {}
			}
			self.visualAnimals[instance.fillType] = visualAnimal
		end

		local dif = instance.count - #visualAnimal.visuals

		if dif < 0 then
			for j = 1, math.abs(dif) do
				local visual = table.remove(visualAnimal.visuals, 1)

				if visual == nil then
					break
				end

				removeHusbandryAnimal(self.husbandryId, visual.id)
				visual.animal:setVisualId(nil)

				self.visualIdToAnimal[visual.id] = nil
			end
		end
	end

	for _, instance in ipairs(instances) do
		local visualAnimal = self.visualAnimals[instance.fillType]

		if visualAnimal == nil then
			visualAnimal = {
				fillType = instance.fillType,
				visuals = {}
			}
			self.visualAnimals[instance.fillType] = visualAnimal
		end

		local dif = instance.count - #visualAnimal.visuals

		if dif > 0 then
			for i = 1, dif do
				local nextAnimal = table.remove(usableAnimals[visualAnimal.fillType], 1)

				if nextAnimal == nil then
					break
				end

				local subType = nextAnimal:getSubType()
				local id = addHusbandryAnimal(self.husbandryId, subType.subTypeId - 1)

				if id ~= 0 then
					setAnimalTextureTile(self.husbandryId, id, subType.texture.tileUIndex, subType.texture.tileVIndex)

					self.visualIdToAnimal[id] = nextAnimal

					nextAnimal:setVisualId(id)
					table.insert(visualAnimal.visuals, {
						animal = nextAnimal,
						id = id
					})
				end
			end
		end
	end

	self:updateVisualDirt()
end

function HusbandryModuleAnimal:updateAnimalParameters()
	local averageWaterUsagePerDay = 0
	local averageStrawUsagePerDay = 0
	local averageFoodUsagePerDay = 0
	local averageFoodSpillageProductionPerDay = 0
	local averagePalletsProductionPerDay = 0
	local averageManureProductionPerDay = 0
	local averageLiquidManureProductionPerDay = 0
	local averageMilkProductionPerDay = 0

	for _, animal in ipairs(self.animals) do
		local subType = animal:getSubType()
		local input = subType.input
		local output = subType.output
		averageWaterUsagePerDay = averageWaterUsagePerDay + input.waterPerDay
		averageStrawUsagePerDay = averageStrawUsagePerDay + input.strawPerDay
		averageFoodUsagePerDay = averageFoodUsagePerDay + input.foodPerDay
		averageFoodSpillageProductionPerDay = averageFoodSpillageProductionPerDay + output.foodSpillagePerDay
		averagePalletsProductionPerDay = averagePalletsProductionPerDay + output.palletsPerDay
		averageManureProductionPerDay = averageManureProductionPerDay + output.manurePerDay
		averageLiquidManureProductionPerDay = averageLiquidManureProductionPerDay + output.liquidManurePerDay
		averageMilkProductionPerDay = averageMilkProductionPerDay + output.milkPerDay
	end

	local numAnimals = #self.animals

	if self.animalsToAdd ~= nil then
		numAnimals = numAnimals + #self.animalsToAdd
	end

	if numAnimals > 0 then
		averageWaterUsagePerDay = averageWaterUsagePerDay / numAnimals
		averageStrawUsagePerDay = averageStrawUsagePerDay / numAnimals
		averageFoodUsagePerDay = averageFoodUsagePerDay / numAnimals
		averageFoodSpillageProductionPerDay = averageFoodSpillageProductionPerDay / numAnimals
		averagePalletsProductionPerDay = averagePalletsProductionPerDay / numAnimals
		averageManureProductionPerDay = averageManureProductionPerDay / numAnimals
		averageLiquidManureProductionPerDay = averageLiquidManureProductionPerDay / numAnimals
		averageMilkProductionPerDay = averageMilkProductionPerDay / numAnimals
	end

	local nbDays = HusbandryModuleAnimal.TROUGH_CAPACITY
	local usageMultiplier = nbDays * math.max(1, numAnimals)
	local waterCapacity = math.max(averageWaterUsagePerDay * usageMultiplier, 250)
	local strawCapacity = math.max(averageStrawUsagePerDay * usageMultiplier, 500)
	local foodCapacity = math.max(averageFoodUsagePerDay * usageMultiplier, 1000)
	local foodSpillageCapacity = averageFoodSpillageProductionPerDay * self.maxNumAnimals
	local defaultMaxCapacity = 800000

	self.owner:setModuleParameters("water", waterCapacity, averageWaterUsagePerDay)
	self.owner:setModuleParameters("straw", strawCapacity, averageStrawUsagePerDay)
	self.owner:setModuleParameters("food", foodCapacity, averageFoodUsagePerDay)
	self.owner:setModuleParameters("foodSpillage", foodSpillageCapacity, averageFoodSpillageProductionPerDay)
	self.owner:setModuleParameters("pallets", defaultMaxCapacity, averagePalletsProductionPerDay)
	self.owner:setModuleParameters("manure", defaultMaxCapacity, averageManureProductionPerDay)
	self.owner:setModuleParameters("liquidManure", defaultMaxCapacity, averageLiquidManureProductionPerDay)
	self.owner:setModuleParameters("milk", defaultMaxCapacity, averageMilkProductionPerDay)
end

function HusbandryModuleAnimal:addRideable(visualId, player)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal:isa(RideableAnimal) and animal:getCanBeRidden() then
		animal:activateRiding(player, false)
	end
end

function HusbandryModuleAnimal:removeRideable(visualId)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil then
		animal:deactivateRiding()
	end
end

function HusbandryModuleAnimal:isRideableInOnHusbandryGround(visualId)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal:isa(RideableAnimal) then
		return animal:isOnHusbandyGround()
	end

	return false
end

function HusbandryModuleAnimal:getSupportsRiding(visualId)
	local animal = self.visualIdToAnimal[visualId]

	return animal ~= nil and animal:isa(RideableAnimal)
end

function HusbandryModuleAnimal:getCanBeRidden(visualId)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal:isa(RideableAnimal) then
		return animal:getCanBeRidden()
	end

	return false
end

function HusbandryModuleAnimal:hideAnimal(visualId)
	if visualId ~= nil and visualId ~= 0 then
		hideAnimal(self.husbandryId, visualId)
	end
end

function HusbandryModuleAnimal:showAnimal(visualId)
	if visualId ~= nil and visualId ~= 0 then
		showAnimal(self.husbandryId, visualId)
	end
end

function HusbandryModuleAnimal:cleanAnimal(visualId, dt)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal.clean ~= nil then
		animal:clean(dt)

		self.animalCleanSendTimer = 250
		self.animalCleanSendId = visualId

		self.owner:raiseActive()
	end

	self:updateVisualDirt()
end

function HusbandryModuleAnimal:setAnimalDirt(visualId, dirtScale)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal.setDirtScale ~= nil then
		animal:setDirtScale(dirtScale)
	end

	self:updateVisualDirt()
end

function HusbandryModuleAnimal:isAnimalDirty(visualId)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil then
		return animal:getDirtScale() > 0
	end

	return false
end

function HusbandryModuleAnimal:updateFitness(productionFactor)
	for _, animal in ipairs(self.animals) do
		if animal ~= nil and animal:isa(Horse) then
			animal:updateFitness(productionFactor)
		end
	end
end

function HusbandryModuleAnimal:updateVisualDirt()
	for visualId, animal in pairs(self.visualIdToAnimal) do
		local rough, _, tiling, x = getAnimalShaderParameter(self.husbandryId, visualId, "RDT")

		setAnimalShaderParameter(self.husbandryId, visualId, "RDT", rough, animal:getDirtScale(), tiling, x)
	end
end

function HusbandryModuleAnimal:updateBreeding(dayToInterval)
	local totalAnimals = #self.animals

	if self.owner.isServer then
		for fillTypeIndex, animals in pairs(self.typedAnimals) do
			local numAnimals = #animals

			if numAnimals > 0 and totalAnimals < self.maxNumAnimals then
				local subType = animals[1]:getSubType()
				local birthRatePerDay = subType.breeding.birthRatePerDay

				if birthRatePerDay > 0 then
					local deltaTime = dayToInterval
					local birthIncrease = self.owner:getGlobalProductionFactor() * numAnimals * deltaTime * birthRatePerDay
					self.newAnimalPercentages[fillTypeIndex] = self.newAnimalPercentages[fillTypeIndex] + birthIncrease

					if self.newAnimalPercentages[fillTypeIndex] > 1 then
						local numNewAnimals = math.floor(self.newAnimalPercentages[fillTypeIndex])
						self.newAnimalPercentages[fillTypeIndex] = self.newAnimalPercentages[fillTypeIndex] - numNewAnimals

						for i = 1, numNewAnimals do
							if self.maxNumAnimals <= #self.animals then
								break
							end

							local desc = g_animalManager:getAnimalsByType(subType.type)
							local newAnimal = Animal.createFromFillType(self.owner.isServer, self.owner.isClient, self.owner, fillTypeIndex)

							newAnimal:register()
							self:addSingleAnimal(newAnimal)

							if desc.stats.breeding ~= "" then
								g_currentMission:farmStats(self.owner:getOwnerFarmId()):updateStats(desc.stats.breeding, 1)
							end
						end
					end

					self.reproductionRatesPerDay[fillTypeIndex] = self.owner:getGlobalProductionFactor() * numAnimals * birthRatePerDay
				else
					self.reproductionRatesPerDay[fillTypeIndex] = 0
				end
			else
				self.reproductionRatesPerDay[fillTypeIndex] = 0
			end
		end
	end
end

function HusbandryModuleAnimal:getNumOfAnimals()
	return #self.animals
end

function HusbandryModuleAnimal:getMaxNumOfAnimals()
	return self.maxNumAnimals
end

function HusbandryModuleAnimal:getNumAnimalSubTypes()
	local animal = g_animalManager:getAnimalsByType(self.animalType)

	return #animal.subTypes
end

function HusbandryModuleAnimal:getAnimalType()
	return self.animalType
end

function HusbandryModuleAnimal:getDirtFactor()
	local dirt = 0

	for _, animal in ipairs(self.animals) do
		dirt = dirt + animal:getDirtScale()
	end

	return dirt / #self.animals
end

function HusbandryModuleAnimal:getFillType(subTypeId)
	local animals = g_animalManager:getAnimalsByType(self.animalType)

	if animals ~= nil then
		for _, animal in pairs(animals.subTypes) do
			if animal.subTypeId == subTypeId then
				local fillType = g_fillTypeManager:getFillTypeByIndex(animal.fillType)

				if fillType ~= nil then
					return fillType
				end
			end
		end
	end

	return nil
end

function HusbandryModuleAnimal:getAnimals()
	return self.animals
end

function HusbandryModuleAnimal:getTypedAnimals()
	return self.typedAnimals
end

function HusbandryModuleAnimal:renameAnimal(animalId, name, noEventSend)
	if self.renamingTasks == nil then
		self.renamingTasks = {}
	end

	table.insert(self.renamingTasks, {
		animalId = animalId,
		name = name
	})
	self.owner:raiseActive()
	AnimalNameEvent.sendEvent(self.owner, animalId, name, noEventSend)
end

function HusbandryModuleAnimal:updateHealth(noEventSend)
	for _, animal in ipairs(self.animals) do
		if animal.setHealthScale ~= nil then
			local healthScale = animal:getHealthScale()
			local productionFactor = self.owner:getGlobalProductionFactor()
			local healthChange = HusbandryModuleAnimal.HEALTH_DECREASE_AT_INTERVAL + HusbandryModuleAnimal.HEALTH_DECREASE_FOR_PRODUCTION * productionFactor
			healthScale = healthScale + healthChange
			healthScale = MathUtil.clamp(healthScale, 0, 1)

			animal:setHealthScale(healthScale, noEventSend)
		end
	end
end

function HusbandryModuleAnimal:getMinutesUntilNextAnimal(fillTypeIndex)
	local newAnimalPercentage = self.newAnimalPercentages[fillTypeIndex]
	local reproductionRatePerDay = self.reproductionRatesPerDay[fillTypeIndex]

	if newAnimalPercentage == nil or reproductionRatePerDay == nil or reproductionRatePerDay == 0 then
		return nil
	end

	local reproductionDuration = 1 / reproductionRatePerDay
	local percentageMissing = math.max(0, 1 - newAnimalPercentage)
	local reproMins = reproductionDuration * 24 * 60
	local timeMissing = percentageMissing * reproMins
	timeMissing = math.ceil(timeMissing / 15) * 15

	return timeMissing
end

function HusbandryModuleAnimal:getReproductionTimePerDay(fillTypeIndex)
	local reproductionRatePerDay = self.reproductionRatesPerDay[fillTypeIndex]

	if reproductionRatePerDay == nil or reproductionRatePerDay == 0 then
		return nil
	end

	local reproductionDuration = 1 / reproductionRatePerDay
	local reproMins = reproductionDuration * 24 * 60
	reproMins = math.ceil(reproMins / 15) * 15

	return reproMins
end

function HusbandryModuleAnimal:getAnimalName(visualId)
	local animal = self.visualIdToAnimal[visualId]

	if animal ~= nil and animal:isa(Horse) then
		return animal:getName()
	end

	return ""
end

function HusbandryModuleAnimal:getIsInUse()
	if #self.animals > 0 then
		return true
	end

	return HusbandryModuleAnimal:superClass().getIsInUse(self)
end
