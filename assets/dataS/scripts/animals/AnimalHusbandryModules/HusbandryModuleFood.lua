HusbandryModuleFood = {}
local HusbandryModuleFood_mt = Class(HusbandryModuleFood, HusbandryModuleBase)

HusbandryModuleBase.registerModule("food", HusbandryModuleFood)

function HusbandryModuleFood:new(customMt)
	local self = HusbandryModuleBase:new(customMt or HusbandryModuleFood_mt)
	self.foodGroupCapacities = {}

	return self
end

function HusbandryModuleFood:delete()
	if self.feedingTrough ~= nil then
		self.feedingTrough:delete()

		self.feedingTrough = nil
	end

	if self.fillPlane ~= nil then
		self.fillPlane:delete()

		self.fillPlane = nil
	end

	self.foodGroupCapacities = {}
end

function HusbandryModuleFood:initDataStructures()
	HusbandryModuleFood:superClass().initDataStructures(self)

	self.feedingTrough = nil
	self.foodFactor = 0
	self.consumedFood = {}
end

function HusbandryModuleFood:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleFood:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local foodNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

	if foodNodeId ~= nil then
		local feedingTrough = UnloadFeedingTrough:new(self.owner.isServer, self.owner.isClient)

		if feedingTrough:load(foodNodeId, xmlFile, configKey, self) then
			feedingTrough:register(true)

			self.feedingTrough = feedingTrough

			self:setupFoodGroups()

			self.fillPlane = FillPlane:new()

			self.fillPlane:load(rootNode, xmlFile, configKey .. ".fillPlane")

			return true
		else
			feedingTrough:delete()

			return false
		end
	end

	return false
end

function HusbandryModuleFood:loadFromXMLFile(xmlFile, key)
	HusbandryModuleWater:superClass().loadFromXMLFile(self, xmlFile, key)
	self:updateFillPlane()
end

function HusbandryModuleFood:readStream(streamId, connection)
	HusbandryModuleMilk:superClass().readStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		local loadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.loadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.loadPlace, loadPlaceId)
	end
end

function HusbandryModuleFood:writeStream(streamId, connection)
	HusbandryModuleMilk:superClass().writeStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadPlace))
		self.loadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.loadPlace)
	end
end

function HusbandryModuleFood:setupFoodGroups()
	if self.feedingTrough ~= nil then
		local animalType = self.owner:getAnimalType()
		local foodGroups = g_animalFoodManager:getFoodGroupByAnimalType(animalType)
		local foodMixtures = g_animalFoodManager:getFoodMixturesByAnimalType(animalType)

		if foodGroups ~= nil then
			for _, foodGroup in pairs(foodGroups) do
				for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
					self.fillLevels[fillTypeIndex] = 0
					self.providedFillTypes[fillTypeIndex] = true
				end

				table.insert(self.foodGroupCapacities, {
					capacity = 0,
					foodGroup = foodGroup
				})
			end

			if foodMixtures ~= nil then
				for _, foodMixtureFillType in ipairs(foodMixtures) do
					self.providedFillTypes[foodMixtureFillType] = true
				end
			end

			self:setCapacity(0)
			self.feedingTrough:initFillTypesFromFoodGroups(foodGroups)
		else
			print("Error: food group for animal type '" .. animalType .. "' not found")
		end
	end
end

function HusbandryModuleFood:setCapacity(newCapacity)
	self.fillCapacity = 0

	for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
		foodGroupInfo.capacity = newCapacity
	end

	self:updateFillPlane()
end

function HusbandryModuleFood:getCapacity()
	local animalType = self.owner:getAnimalType()
	local consumptionType = g_animalFoodManager:getFoodConsumptionTypeByAnimalType(animalType)
	local foodCapacity = 0

	if consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_SERIAL then
		for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
			foodCapacity = foodCapacity + foodGroupInfo.capacity
		end
	elseif consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL then
		for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
			foodCapacity = foodGroupInfo.capacity

			break
		end
	else
		foodCapacity = self.fillCapacity
	end

	return foodCapacity
end

function HusbandryModuleFood:getFreeCapacity(fillTypeIndex)
	local animalType = self.owner:getAnimalType()
	local foodMixture = g_animalFoodManager:getFoodMixtureByFillType(fillTypeIndex)

	if foodMixture ~= nil then
		local checkedFoodGroups = {}
		local capacity = 0
		local fillLevel = 0

		for _, ingredient in ipairs(foodMixture.ingredients) do
			for _, fillType in ipairs(ingredient.fillTypes) do
				local foodGroup = g_animalFoodManager:getFoodGroupByFillType(animalType, fillType)

				if checkedFoodGroups[foodGroup] == nil then
					for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
						if foodGroupInfo.foodGroup == foodGroup then
							capacity = capacity + foodGroupInfo.capacity

							break
						end
					end

					fillLevel = fillLevel + self:getFillLevel(fillType)
					checkedFoodGroups[foodGroup] = true
				end
			end
		end

		return capacity - fillLevel
	else
		local foodGroup = g_animalFoodManager:getFoodGroupByFillType(animalType, fillTypeIndex)
		local capacity = 0

		for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
			if foodGroupInfo.foodGroup == foodGroup then
				capacity = foodGroupInfo.capacity

				break
			end
		end

		return capacity - self:getFillLevel(fillTypeIndex)
	end
end

function HusbandryModuleFood:getFillLevel(fillTypeIndex)
	local animalType = self.owner:getAnimalType()
	local fillLevel = g_animalFoodManager:getTotalFillLevelInGroupByFillTypeIndex(animalType, self.fillLevels, fillTypeIndex)

	return Utils.getNoNil(fillLevel, 0)
end

function HusbandryModuleFood:getTotalFillLevel()
	local animalType = self.owner:getAnimalType()
	local consumptionType = g_animalFoodManager:getFoodConsumptionTypeByAnimalType(animalType)
	local totalFillLevel = 0

	if consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_SERIAL then
		for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
			totalFillLevel = totalFillLevel + g_animalFoodManager:getTotalFillLevelInGroup(foodGroupInfo.foodGroup, self.fillLevels)
		end
	elseif consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL and #self.foodGroupCapacities > 0 then
		local nbGroups = #self.foodGroupCapacities

		for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
			totalFillLevel = totalFillLevel + g_animalFoodManager:getTotalFillLevelInGroup(foodGroupInfo.foodGroup, self.fillLevels)
		end

		totalFillLevel = totalFillLevel / nbGroups
	else
		totalFillLevel = HusbandryModuleFood:superClass().getTotalFillLevel(self)
	end

	return totalFillLevel
end

function HusbandryModuleFood:onIntervalUpdate(dayToInterval)
	HusbandryModuleFood:superClass().onIntervalUpdate(self, dayToInterval)

	self.consumedFood = {}

	if self.singleAnimalUsagePerDay > 0 then
		local totalNumAnimals = self.owner:getNumOfAnimals()
		local foodNeeded = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval

		if foodNeeded > 0 then
			local animalType = self.owner:getAnimalType()
			self.foodFactor = g_animalFoodManager:consumeFood(animalType, foodNeeded, self.fillLevels, self.consumedFood)

			self:updateFillPlane()
		end
	end
end

function HusbandryModuleFood:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex)
	local freeCapacity = self:getFreeCapacity(fillTypeIndex)
	local changed = self:changeFillLevels(math.min(freeCapacity, deltaFillLevel), fillTypeIndex)

	if deltaFillLevel > 0 and changed ~= 0 then
		self.owner:updateGlobalProductionFactor()
	end

	if changed > 0 and self.feedingTrough ~= nil and self.feedingTrough:getIsFillTypeSupported(fillTypeIndex) then
		self.feedingTrough:raiseActive()
	end

	return changed
end

function HusbandryModuleFood:changeFillLevels(fillDelta, fillTypeIndex)
	local delta = 0

	if self.fillLevels[fillTypeIndex] ~= nil then
		local oldFillLevel = self.fillLevels[fillTypeIndex]
		local newFillLevel = oldFillLevel + fillDelta
		newFillLevel = math.max(newFillLevel, 0)
		delta = newFillLevel - oldFillLevel

		self:setFillLevel(fillTypeIndex, newFillLevel)
	end

	return delta
end

function HusbandryModuleFood:getConsumedFood()
	return self.consumedFood
end

function HusbandryModuleFood:getFoodFactor()
	return self.foodFactor
end

function HusbandryModuleFood:updateFillPlane()
	if self.fillPlane ~= nil then
		local fillPlaneFactor = 1 - math.max(0, math.abs(math.min(self:getFillProgress() - 1, 1)) * 2 - 1)^2

		self.fillPlane:setState(fillPlaneFactor)
		self:updateFillPlaneColor()
	end
end

function HusbandryModuleFood:updateFillPlaneColor()
	if self.fillPlane ~= nil and self.fillPlane.colorChange then
		local colorScale = {
			0,
			0,
			0
		}

		for filltypeIndex, state in pairs(self.feedingTrough.fillTypes) do
			if state then
				local fillType = g_fillTypeManager:getFillTypeByIndex(filltypeIndex)
				local fillLevelRatio = self.feedingTrough.target:getFillLevel(filltypeIndex) / self.feedingTrough.target:getCapacity()
				local fillPlaneColors = {
					1,
					1,
					1
				}

				if fillType.fillPlaneColors ~= nil then
					fillPlaneColors = fillType.fillPlaneColors
				end

				for i = 1, 3 do
					colorScale[i] = MathUtil.clamp(colorScale[i] + fillLevelRatio * fillPlaneColors[i], 0, 1)
				end
			end
		end

		self.fillPlane:setColorScale(colorScale)
	end
end

function HusbandryModuleFood:getFilltypeInfos()
	local result = {}

	for _, foodGroupInfo in pairs(self.foodGroupCapacities) do
		local foodGroup = foodGroupInfo.foodGroup
		local totalFillLevel = g_animalFoodManager:getTotalFillLevelInGroup(foodGroupInfo.foodGroup, self.fillLevels)
		local capacity = foodGroupInfo.capacity

		table.insert(result, {
			foodGroup = foodGroup,
			fillLevel = totalFillLevel,
			capacity = capacity
		})
	end

	return result
end

function HusbandryModuleFood:getIsNodeUsed(node)
	return node == self.feedingTrough.exactFillRootNode
end

function HusbandryModuleFood:onFillProgressChanged()
	self:updateFillPlane()
end
