AnimalFoodManager = {
	SEND_NUM_BITS = 4,
	FOOD_CONSUME_TYPE_SERIAL = 1,
	FOOD_CONSUME_TYPE_PARALLEL = 2
}
local AnimalFoodManager_mt = Class(AnimalFoodManager, AbstractManager)

function AnimalFoodManager:new(customMt)
	local self = AbstractManager:new(customMt or AnimalFoodManager_mt)

	return self
end

function AnimalFoodManager:initDataStructures()
	self.foodGroups = {}
	self.foodMixtures = {}
	self.animalFoodMixtures = {}
end

function AnimalFoodManager:loadMapData(xmlFile, missionInfo)
	AnimalFoodManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.husbandryFood#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load husbandry food configuration file '" .. tostring(filename) .. "'!")

		return false
	end

	local foodGroupsLoaded = false
	local mixturesLoaded = false
	local foodGroupsNormalized = false
	local mixturesNormalized = false
	local animalFoodXmlFile = loadXMLFile("animalFood", filename)

	if animalFoodXmlFile ~= nil then
		foodGroupsLoaded = self:loadFoodGroups(animalFoodXmlFile)
		mixturesLoaded = self:loadMixtures(animalFoodXmlFile)
		foodGroupsNormalized = self:normalizeFoodGroupWeights()
		mixturesNormalized = self:normalizeMixtureWeights()

		delete(animalFoodXmlFile)
	end

	return foodGroupsLoaded and mixturesLoaded and foodGroupsNormalized and mixturesNormalized
end

function AnimalFoodManager:loadFoodGroups(xmlFile)
	local i = 0

	while true do
		local animalKey = string.format("animalFood.animals.animalFoodGroups(%d)", i)

		if not hasXMLProperty(xmlFile, animalKey) then
			break
		end

		local animalType = getXMLString(xmlFile, animalKey .. "#type")

		if animalType ~= nil then
			animalType = animalType:upper()
			self.foodGroups[animalType] = {
				content = {},
				consumptionType = AnimalFoodManager.FOOD_CONSUME_TYPE_SERIAL
			}
			local foodProcessTypeString = getXMLString(xmlFile, animalKey .. "#consumptionType")
			foodProcessTypeString = foodProcessTypeString:upper()

			if foodProcessTypeString == "PARALLEL" then
				self.foodGroups[animalType].consumptionType = AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL
			end

			local j = 0

			while true do
				local groupKey = string.format("%s.foodGroup(%d)", animalKey, j)

				if not hasXMLProperty(xmlFile, groupKey) then
					break
				end

				local foodGroup = {
					title = g_i18n:convertText(Utils.getNoNil(getXMLString(xmlFile, groupKey .. "#title"), "")),
					productionWeight = Utils.getNoNil(getXMLFloat(xmlFile, groupKey .. "#productionWeight"), 0),
					eatWeight = Utils.getNoNil(getXMLFloat(xmlFile, groupKey .. "#eatWeight"), 1),
					fillTypes = {}
				}
				local fillTypesStr = Utils.getNoNil(getXMLString(xmlFile, groupKey .. "#fillTypes"), "")
				local warning = string.format("Warning: FillType '%s' undefined for foodGroups of '%s'. Ignoring it!", tostring(fillTypeName), tostring(animalType))
				foodGroup.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypesStr, warning)

				table.insert(self.foodGroups[animalType].content, foodGroup)

				j = j + 1
			end
		end

		i = i + 1
	end

	return true
end

function AnimalFoodManager:loadMixtures(xmlFile)
	local i = 0

	while true do
		local mixtureKey = string.format("animalFood.foodMixtures.foodMixture(%d)", i)

		if not hasXMLProperty(xmlFile, mixtureKey) then
			break
		end

		local mixtureFillTypeName = Utils.getNoNil(getXMLString(xmlFile, mixtureKey .. "#fillType"), "")
		local animalType = Utils.getNoNil(getXMLString(xmlFile, mixtureKey .. "#type"), "")

		if animalType ~= nil then
			animalType = animalType:upper()

			if self.animalFoodMixtures[animalType] == nil then
				self.animalFoodMixtures[animalType] = {}
			end

			local mixtureFillType = g_fillTypeManager:getFillTypeByName(mixtureFillTypeName)

			if mixtureFillType ~= nil then
				local fillType = mixtureFillType.index

				table.insert(self.animalFoodMixtures[animalType], fillType)

				self.foodMixtures[fillType] = {
					ingredients = {}
				}
				local j = 0

				while true do
					local ingredientKey = string.format("%s.ingredient(%d)", mixtureKey, j)

					if not hasXMLProperty(xmlFile, ingredientKey) then
						break
					end

					local ingredient = {}
					local warning = string.format("Warning: FillType '%s' undefined for mixture of '%s'. Ignoring it!", tostring(fillTypeName), tostring(mixtureFillTypeName))
					local fillTypesStr = Utils.getNoNil(getXMLString(xmlFile, ingredientKey .. "#fillTypes"), "")
					ingredient.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypesStr, warning)
					ingredient.weight = Utils.getNoNil(getXMLFloat(xmlFile, ingredientKey .. "#weight"), 0)

					table.insert(self.foodMixtures[fillType].ingredients, ingredient)

					j = j + 1
				end
			else
				print("Warning: FillType '" .. tostring(fillTypeName) .. "' undefined for mixtures. Ignoring it!")

				return false
			end
		end

		i = i + 1
	end

	return true
end

function AnimalFoodManager:normalizeFoodGroupWeights()
	for _, animalFoodGroup in pairs(self.foodGroups) do
		if animalFoodGroup.consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL then
			local sumWeigths = 0
			local eatWeights = 0

			for _, foodGroup in pairs(animalFoodGroup.content) do
				sumWeigths = sumWeigths + foodGroup.productionWeight
				eatWeights = eatWeights + foodGroup.eatWeight
			end

			for _, foodGroup in pairs(animalFoodGroup.content) do
				if sumWeigths > 0 then
					foodGroup.productionWeight = foodGroup.productionWeight / sumWeigths
				end

				if eatWeights > 0 then
					foodGroup.eatWeight = foodGroup.eatWeight / eatWeights
				end
			end
		end
	end

	return true
end

function AnimalFoodManager:normalizeMixtureWeights()
	for _, mixture in pairs(self.foodMixtures) do
		local sumWeigths = 0

		for _, ingredient in pairs(mixture.ingredients) do
			sumWeigths = sumWeigths + ingredient.weight
		end

		if sumWeigths > 0 then
			for _, ingredient in pairs(mixture.ingredients) do
				ingredient.weight = ingredient.weight / sumWeigths
			end
		end
	end

	return true
end

function AnimalFoodManager:getFoodGroupByAnimalIndex(animalIndex)
	if animalIndex ~= nil then
		local animalType = g_animalManager:getAnimalType(animalIndex)

		return self.foodGroups[animalType].content
	end

	return nil
end

function AnimalFoodManager:getFoodGroupByAnimalType(animalType)
	if animalType ~= nil then
		return self.foodGroups[animalType].content
	end

	return nil
end

function AnimalFoodManager:getFoodMixturesByAnimalType(animalType)
	if animalType ~= nil then
		return self.animalFoodMixtures[animalType]
	end

	return nil
end

function AnimalFoodManager:getFoodMixtureByFillType(fillTypeIndex)
	return self.foodMixtures[fillTypeIndex]
end

function AnimalFoodManager:getFoodConsumptionTypeByAnimalType(animalType)
	if animalType ~= nil then
		return self.foodGroups[animalType].consumptionType
	end

	return nil
end

function AnimalFoodManager:getFoodGroupByFillType(animalType, fillTypeIndex)
	local animalFoodGroups = self.foodGroups[animalType]

	if animalFoodGroups ~= nil then
		for _, foodGroup in pairs(animalFoodGroups.content) do
			for _, foodGroupFillTypeIndex in pairs(foodGroup.fillTypes) do
				if foodGroupFillTypeIndex == fillTypeIndex then
					return foodGroup
				end
			end
		end
	end

	return nil
end

function AnimalFoodManager:consumeFood(animalType, amountToConsume, fillLevels, consumedFood)
	local production = 0
	local animalFoodGroups = self.foodGroups[animalType]

	if animalFoodGroups ~= nil then
		if animalFoodGroups.consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_SERIAL then
			production = self:consumeFoodSerially(amountToConsume, animalFoodGroups.content, fillLevels, consumedFood)
		elseif animalFoodGroups.consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL then
			production = self:consumeFoodParallelly(amountToConsume, animalFoodGroups.content, fillLevels, consumedFood)
		end
	end

	return production
end

function AnimalFoodManager:consumeFoodSerially(amount, foodGroups, fillLevels, consumedFood)
	local productionWeight = 0
	local totalAmountToConsume = amount

	for _, foodGroup in ipairs(foodGroups) do
		local oldAmount = amount
		amount = self:consumeFoodGroup(foodGroup, amount, fillLevels, consumedFood)
		local deltaProdWeight = (oldAmount - amount) / totalAmountToConsume * foodGroup.productionWeight
		productionWeight = productionWeight + deltaProdWeight
	end

	return productionWeight
end

function AnimalFoodManager:consumeFoodParallelly(amount, foodGroups, fillLevels, consumedFood)
	local productionWeight = 0

	for _, foodGroup in pairs(foodGroups) do
		local totalFillLevelInGroup = self:getTotalFillLevelInGroup(foodGroup, fillLevels)
		local foodGroupConsume = amount * foodGroup.eatWeight
		local consumeFood = math.min(totalFillLevelInGroup, foodGroupConsume)
		local ret = self:consumeFoodGroup(foodGroup, consumeFood, fillLevels, consumedFood)
		local foodFactor = (consumeFood - ret) / foodGroupConsume
		productionWeight = productionWeight + foodFactor * foodGroup.productionWeight
	end

	return productionWeight
end

function AnimalFoodManager:consumeFoodGroup(foodGroup, amount, fillLevels, consumedFood)
	for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
		if fillLevels[fillTypeIndex] ~= nil then
			local currentFillLevel = fillLevels[fillTypeIndex]
			local amountToConsume = -math.min(amount, currentFillLevel)
			local deltaConsumed = self:changeFillLevels(amountToConsume, fillLevels, fillTypeIndex)
			amount = math.max(amount + deltaConsumed, 0)
			consumedFood[fillTypeIndex] = -deltaConsumed

			if amount == 0 then
				return amount
			end
		end
	end

	return amount
end

function AnimalFoodManager:changeFillLevels(fillDelta, fillLevels, fillTypeIndex)
	local old = fillLevels[fillTypeIndex]
	fillLevels[fillTypeIndex] = math.max(0, old + fillDelta)
	local new = fillLevels[fillTypeIndex]

	return new - old
end

function AnimalFoodManager:getTotalFillLevelInGroupByFillTypeIndex(animalType, fillLevels, fillTypeIndex)
	local foodGroup = self:getFoodGroupByFillType(animalType, fillTypeIndex)

	if foodGroup ~= nil then
		return self:getTotalFillLevelInGroup(foodGroup, fillLevels)
	end

	return 0
end

function AnimalFoodManager:getTotalFillLevelInGroup(foodGroup, fillLevels)
	local totalFillLevel = 0

	for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
		if fillLevels[fillTypeIndex] ~= nil then
			totalFillLevel = totalFillLevel + fillLevels[fillTypeIndex]
		end
	end

	return totalFillLevel
end

g_animalFoodManager = AnimalFoodManager:new()
