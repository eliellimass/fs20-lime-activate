UnloadFeedingTrough = {}
local UnloadFeedingTrough_mt = Class(UnloadFeedingTrough, UnloadTrigger)

InitStaticObjectClass(UnloadFeedingTrough, "UnloadFeedingTrough", ObjectIds.OBJECT_UNLOAD_FEEDING_TROUGH)

function UnloadFeedingTrough:new(isServer, isClient, customMt)
	local self = UnloadTrigger:new(isServer, isClient, customMt or UnloadFeedingTrough_mt)
	self.animalPlaces = {}
	self.notAllowedWarningText = string.format(g_i18n:getText("warning_inAdvanceFeedingLimitReached"), HusbandryModuleAnimal.TROUGH_CAPACITY)

	return self
end

function UnloadFeedingTrough:load(rootNode, xmlFile, xmlNode, target)
	local returnValue = UnloadFeedingTrough:superClass().load(self, rootNode, xmlFile, xmlNode, target)

	if returnValue then
		self:loadAnimalPlaces(rootNode, xmlFile, xmlNode)
	end

	return returnValue
end

function UnloadFeedingTrough:loadAnimalPlaces(rootNode, xmlFile, xmlNode)
	local animalPlacesNode = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "animalPlacesNode", getXMLString, rootNode)

	if animalPlacesNode ~= nil then
		local animalPlaces = I3DUtil.indexToObject(rootNode, animalPlacesNode)

		if animalPlaces ~= nil and self.target ~= nil and self.target.husbandryId ~= nil then
			for i = 1, getNumOfChildren(animalPlaces) do
				local animalPlaceId = getChildAt(animalPlaces, i - 1)
				local animalPlace = addFeedingPlace(self.target.husbandryId, animalPlaceId, 0)

				table.insert(self.animalPlaces, animalPlace)
			end
		end
	end
end

function UnloadFeedingTrough:loadFillTypes(rootNode, xmlFile, xmlNode)
end

function UnloadFeedingTrough:initFillTypesFromFoodGroups(foodGroups)
	self.fillTypes = {}

	for _, foodGroup in pairs(foodGroups) do
		for _, fillTypeIndex in pairs(foodGroup.fillTypes) do
			self.fillTypes[fillTypeIndex] = true
		end
	end
end

function UnloadFeedingTrough:addFoodMixtureFillType(foodMixtureFillType)
	self.fillTypes[foodMixtureFillType] = true
end

function UnloadFeedingTrough:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local foodMixture = g_animalFoodManager:getFoodMixtureByFillType(fillTypeIndex)
	local delta = 0

	if foodMixture ~= nil then
		for _, ingredient in ipairs(foodMixture.ingredients) do
			local ingredientFillType = ingredient.fillTypes[1]
			local ingredientFillLevel = fillLevelDelta * ingredient.weight
			delta = delta + UnloadFeedingTrough:superClass().addFillUnitFillLevel(self, farmId, fillUnitIndex, ingredientFillLevel, ingredientFillType, toolType, fillPositionData)
		end
	else
		delta = UnloadFeedingTrough:superClass().addFillUnitFillLevel(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	end

	self:updateAnimalPlaces(delta)

	return delta
end

function UnloadFeedingTrough:updateAnimalPlaces(delta)
	if delta ~= nil and delta > 0 then
		for _, animalPlace in pairs(self.animalPlaces) do
			updateFeedingPlace(self.target.husbandryId, animalPlace, delta)
		end
	end
end
