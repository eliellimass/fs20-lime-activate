InGameMenuAnimalsFrame = {}
local InGameMenuAnimalsFrame_mt = Class(InGameMenuAnimalsFrame, TabbedMenuFrameElement)
InGameMenuAnimalsFrame.CONTROLS = {
	FITNESS_VALUE_TEXT = "fitnessValueText",
	HEALTH_VALUE_TEXT = "healthValueText",
	HEALTH_BAR = "healthStatusBar",
	ANIMAL_TYPE_NAME_TEXT = "animalDetailTypeNameText",
	ANIMAL_TYPE_COUNT_TEXT = "animalDetailTypeCountText",
	REQUIREMENT_ROWS = "requirementRow",
	LIVESTOCK_ATTRIBUTE_LABELS = "animalProductLabel",
	REPRODUCTION_RATE_TEXT = "animalReproductionRateText",
	DETAIL_OUTPUT_BOX = "detailOutputBox",
	PRODUCTIVIY_VALUE_TEXT = "productivityValueText",
	CONDITION_ROWS = "conditionRow",
	CONDITION_VALUE_TEXTS = "conditionValue",
	FOOD_HEADER = "foodHeader",
	NO_HUSBANDRIES_TEXT = "noHusbandriesBox",
	REQUIREMENT_BARS = "requirementStatusBar",
	LIVESTOCK_ATTRIBUTE_VALUES = "animalProductText",
	REQUIREMENTS_LAYOUT = "requirementsLayout",
	DESCRIPTION_TEXT = "detailDescriptionText",
	TIME_UNTIL_REPRODUCTION_TEXT = "animalTimeTillNextAnimalText",
	DETAILS_BOX = "detailsBox",
	FITNESS_BAR = "fitnessStatusBar",
	ANIMAL_DETAIL_LIVESTOCK = "animalDetailLivestockBox",
	LIVESTOCK_ATTRIBUTES_LAYOUT = "livestockAttributesLayout",
	ANIMAL_TYPE_VALUE_TEXT = "animalDetailTypeValueText",
	ANIMAL_TYPE_IMAGE = "animalDetailTypeImage",
	REQUIREMENT_VALUE_TEXTS = "requirementValue",
	ANIMAL_LIST = "animalList",
	ANIMAL_VALUE_TEXT = "animalProductValue",
	CONDITIONS_HEADER = "conditionsHeader",
	ANIMAL_BOX_TEMPLATE = "animalTemplate",
	CLEANLINESS_VALUE_TEXT = "cleanlinessValueText",
	ANIMAL_DETAIL_HORSE = "animalDetailHorseBox",
	DETAIL_INPUT_BOX = "detailInputBox",
	ANIMAL_LIST_HEADER_TEMPLATE = "animalListHeaderTemplate",
	CONDITION_BARS = "conditionStatusBar",
	CONDITION_LABEL_TEXTS = "conditionLabel",
	DETAIL_DESCRIPTION_BOX = "detailDescriptionBox",
	ANIMAL_LIST_ROW_TEMPLATE = "animalListItemTemplate",
	CLEANLINESS_BAR = "cleanlinessStatusBar",
	LIVESTOCK_ATTRIBUTES = "animalProductAttribute",
	REQUIREMENT_LABEL_TEXTS = "requirementLabel",
	PRODUCTIVITY_BAR = "productivityStatusBar",
	ANIMAL_LIST_BOX = "animalsListBox",
	ANIMALS_CONTAINER = "animalsContainer"
}
InGameMenuAnimalsFrame.ELEMENT_NAME = {
	ANIMAL_STATUS_VALUE_TEXT = "animalStatusValue",
	ANIMAL_NAME_TEXT = "animalName",
	ANIMAL_COUNT_TEXT = "animalCount",
	HUSBANDRY_NAME_TEXT = "husbandryName",
	ANIMAL_STATUS_LABEL_TEXT = "animalStatusLabel",
	ANIMAL_TYPE_ICON = "animalTypeIcon"
}
InGameMenuAnimalsFrame.UPDATE_INTERVAL = 5000
InGameMenuAnimalsFrame.HORSE_TYPE = "HORSE"
InGameMenuAnimalsFrame.CHICKEN_TYPE = "CHICKEN"
InGameMenuAnimalsFrame.ANIMAL_PRODUCT_FILL_TYPES = {
	EGG = "EGG",
	MILK = "MILK",
	WOOL = "WOOL"
}
InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH = 16

function InGameMenuAnimalsFrame:new(subclass_mt, messageCenter, l10n, animalManager, animalFoodManager, fillTypeManager)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or InGameMenuAnimalsFrame_mt)

	self:registerControls(InGameMenuAnimalsFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.animalManager = animalManager
	self.animalFoodManager = animalFoodManager
	self.fillTypeManager = fillTypeManager
	self.animalsDataSource = GuiDataSource:new()
	self.selectedHorse = nil
	self.selectedHusbandry = nil
	self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
	self.hasCustomMenuButtons = true
	self.renameButtonInfo = {}

	return self
end

function InGameMenuAnimalsFrame:copyAttributes(src)
	InGameMenuAnimalsFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.animalManager = src.animalManager
	self.animalFoodManager = src.animalFoodManager
	self.fillTypeManager = src.fillTypeManager
end

function InGameMenuAnimalsFrame:onGuiSetupFinished()
	InGameMenuAnimalsFrame:superClass().onGuiSetupFinished(self)

	local function assignDataFunction(guiElement, animalData)
		self:assignAnimalData(guiElement, animalData)
	end

	self.animalList:setDataSource(self.animalsDataSource)
	self.animalList:setAssignItemDataFunction(assignDataFunction)
	self.animalsDataSource:addChangeListener(self, self.onAnimalDataSourceChanged)
end

function InGameMenuAnimalsFrame:onFrameOpen()
	InGameMenuAnimalsFrame:superClass().onFrameOpen(self)
	self:updateAnimalData()
	FocusManager:setFocus(self.animalList)
	self.animalList:setSelectedIndex(1, true)
end

function InGameMenuAnimalsFrame:initialize()
	self.renameButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME),
		callback = function ()
			self:onButtonRename()
		end
	}
	self.hotspotButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function ()
			self:onButtonHotspot()
		end
	}

	self.messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalDataChanged, self)
end

function InGameMenuAnimalsFrame:delete()
	InGameMenuAnimalsFrame:superClass().delete(self)
end

function InGameMenuAnimalsFrame:onAnimalDataChanged()
	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:setHusbandries(husbandries)
	self.husbandries = husbandries

	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm

	self:updateAnimalData()
end

function InGameMenuAnimalsFrame:update(dt)
	InGameMenuAnimalsFrame:superClass().update(self, dt)

	if self.selectedHusbandry ~= nil then
		self.animalDataUpdateTime = self.animalDataUpdateTime - dt

		if self.animalDataUpdateTime < 0 then
			self:updateAnimalData()

			if self.selectedHorse ~= nil then
				self:displayHorse(self.selectedHorse, self.selectedHusbandry)
			elseif self.selectedAnimals ~= nil then
				self:displayLivestock(self.selectedAnimals, self.selectedHusbandry)
				self:updateLivestockHusbandryProductionDisplay(self.selectedHusbandry)
			end

			self:updateHusbandryConditionsDisplay(self.selectedHusbandry)
			self:updateHusbandryFoodDisplay(self.selectedHusbandry)

			self.animalDataUpdateTime = InGameMenuAnimalsFrame.UPDATE_INTERVAL
		end
	end
end

local function sortHusbandries(a, b)
	local aX, aZ, bX, bZ, _ = nil
	local aType = a:getAnimalType()
	local bType = b:getAnimalType()

	if aType ~= bType then
		if aType == InGameMenuAnimalsFrame.HORSE_TYPE then
			return false
		elseif bType == InGameMenuAnimalsFrame.HORSE_TYPE then
			return true
		end
	end

	if next(a.mapHotspots) ~= nil then
		aZ = a.mapHotspots[1].zMapPos
		aX = a.mapHotspots[1].xMapPos
	else
		aX, _, aZ = getWorldTranslation(a.nodeId)
	end

	if next(b.mapHotspots) ~= nil then
		bZ = b.mapHotspots[1].zMapPos
		bX = b.mapHotspots[1].xMapPos
	else
		bX, _, bZ = getWorldTranslation(b.nodeId)
	end

	if aX == bX then
		return aZ < bZ
	end

	return aX < bX
end

function InGameMenuAnimalsFrame:getSortedFarmHusbandries()
	local farmHusbandries = {}

	if self.husbandries ~= nil and next(self.husbandries) ~= nil and self.playerFarm ~= nil then
		for _, husbandry in pairs(self.husbandries) do
			if husbandry:getOwnerFarmId() == self.playerFarm.farmId then
				table.insert(farmHusbandries, husbandry)
			end
		end
	end

	table.sort(farmHusbandries, sortHusbandries)

	return farmHusbandries
end

local function makeHorseData(horse, husbandry)
	local subType = horse:getSubType()

	return {
		count = 1,
		isHeader = false,
		isHorse = true,
		statusValue = MathUtil.clamp(horse:getTodaysRidingTime() / Horse.DAILY_TARGET_RIDING_TIME, 0, 1),
		iconFilename = subType.fillTypeDesc.hudOverlayFilenameSmall,
		nameText = horse:getName(),
		husbandry = husbandry,
		horse = horse
	}
end

local function makeLivestockData(animals, husbandry)
	local count = #animals
	local animal = animals[1]
	local subType = animal:getSubType()

	return {
		isHeader = false,
		isHorse = false,
		count = count,
		statusValue = husbandry:getGlobalProductionFactor(),
		iconFilename = subType.fillTypeDesc.hudOverlayFilename,
		nameText = subType.storeInfo.shopItemName,
		husbandry = husbandry,
		animals = animals
	}
end

function InGameMenuAnimalsFrame:updateAnimalData()
	local data = {}
	local husbandries = self:getSortedFarmHusbandries()

	for _, husbandry in ipairs(husbandries) do
		if husbandry:getNumOfAnimals() > 0 and not GS_IS_MOBILE_VERSION then
			local headerData = {
				isHeader = true,
				nameText = husbandry:getName()
			}

			table.insert(data, headerData)
		end

		if husbandry:getAnimalType() == InGameMenuAnimalsFrame.HORSE_TYPE then
			local horses = husbandry:getAnimals()

			for _, horse in ipairs(horses) do
				table.insert(data, makeHorseData(horse, husbandry))
			end
		else
			local typedAnimals = husbandry:getTypedAnimals()

			for fillTypeIndex, animals in pairs(typedAnimals) do
				if #animals > 0 then
					table.insert(data, makeLivestockData(animals, husbandry))
				end
			end
		end
	end

	self.animalsDataSource:setData(data)
end

function InGameMenuAnimalsFrame:onAnimalDataSourceChanged()
	local hasAnimals = self.animalsDataSource:getCount() > 0
	self.selectedHusbandry = nil
	self.selectedHorse = nil

	self.animalsListBox:setVisible(hasAnimals)
	self.detailsBox:setVisible(hasAnimals)
	self.noHusbandriesBox:setVisible(not hasAnimals)

	if hasAnimals then
		local selectedIndex = self.animalList:getSelectedDataIndex()

		self.animalList:updateAlternatingBackground()
		self.animalList:updateItemPositions()
		self.animalList:setSelectedIndex(selectedIndex, true)
	end
end

function InGameMenuAnimalsFrame:assignAnimalData(listItem, animalData)
	local icon = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.ANIMAL_TYPE_ICON)
	local nameText = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.ANIMAL_NAME_TEXT)
	local countText = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.ANIMAL_COUNT_TEXT)
	local statusLabelText = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.ANIMAL_STATUS_LABEL_TEXT)
	local statusValueText = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.ANIMAL_STATUS_VALUE_TEXT)
	local headerText = listItem:getDescendantByName(InGameMenuAnimalsFrame.ELEMENT_NAME.HUSBANDRY_NAME_TEXT)
	listItem.doNotAlternate = animalData.isHeader

	if animalData.isHeader then
		listItem:applyProfile(InGameMenuAnimalsFrame.PROFILE.HEADER_LIST_ITEM)

		listItem.allowFocus = false

		headerText:setText(animalData.nameText)
		icon:setVisible(false)
		nameText:setText("")
		countText:setText("")
		statusLabelText:setText("")
		statusValueText:setText("")
	else
		listItem.allowFocus = true

		icon:setVisible(true)
		icon:setImageFilename(animalData.iconFilename)
		nameText:setText(animalData.nameText)
		statusValueText:setText(self.l10n:formatNumber(animalData.statusValue * 100, 0) .. "%")

		if animalData.isHorse then
			countText:setText("")
			statusLabelText:setText(self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.HORSE_DAILY_RIDING) .. ":")
		else
			countText:setText(tostring(animalData.count))
			statusLabelText:setText(self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.LIVESTOCK_PRODUCTIVITY) .. ":")
		end

		headerText:setText("")
	end
end

function InGameMenuAnimalsFrame:getMainElementSize()
	return self.animalsContainer.size
end

function InGameMenuAnimalsFrame:getMainElementPosition()
	return self.animalsContainer.absPosition
end

function InGameMenuAnimalsFrame:setStatusBarValue(statusBarElement, value, startOffset, profiles, overrideStatusValue)
	local profile = profiles.LOW
	local testValue = overrideStatusValue or value

	if InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM < testValue and testValue <= InGameMenuAnimalsFrame.STATUS_BAR_HIGH then
		profile = profiles.MEDIUM
	elseif InGameMenuAnimalsFrame.STATUS_BAR_HIGH < testValue then
		profile = profiles.HIGH
	end

	statusBarElement:applyProfile(profile)

	local fullWidth = statusBarElement.parent.size[1] - statusBarElement.margin[1] * 2
	local offX = statusBarElement.margin[1] + fullWidth * startOffset

	statusBarElement:setSize(fullWidth * math.min(1, value), nil)
	statusBarElement:setPosition(offX, statusBarElement.position[2])
end

function InGameMenuAnimalsFrame:displayRequirement(requirementRowIndex, labelText, valueText, normalizedValue, statusBarStartOffset, overrideStatusValue)
	local isVisible = labelText ~= nil

	self.requirementRow[requirementRowIndex]:setVisible(isVisible)

	if isVisible then
		self.requirementLabel[requirementRowIndex]:setText(labelText)
		self.requirementValue[requirementRowIndex]:setText(valueText)
		self:setStatusBarValue(self.requirementStatusBar[requirementRowIndex], normalizedValue, statusBarStartOffset or 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_SMALL, overrideStatusValue)
	end
end

function InGameMenuAnimalsFrame:displayCondition(conditionRowIndex, labelText, valueText, normalizedValue)
	local isVisible = labelText ~= nil

	self.conditionRow[conditionRowIndex]:setVisible(isVisible)

	if isVisible then
		self.conditionLabel[conditionRowIndex]:setText(labelText)
		self.conditionValue[conditionRowIndex]:setText(valueText)
		self:setStatusBarValue(self.conditionStatusBar[conditionRowIndex], normalizedValue, 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_SMALL)
	end
end

function InGameMenuAnimalsFrame:sumFillLevelInfos(fillLevelInfos)
	local level = 0
	local capacity = 0
	local label = ""

	for _, fillLevelInfo in pairs(fillLevelInfos) do
		level = level + fillLevelInfo.fillLevel
		capacity = capacity + fillLevelInfo.capacity

		if label == "" then
			label = fillLevelInfo.fillType.title
		end
	end

	return level, capacity, label
end

function InGameMenuAnimalsFrame:updateLivestockHusbandryProductionDisplay(livestockHusbandry)
	local productionInfos = livestockHusbandry:getProductionFilltypeInfo()
	local productIndex = 1

	for _, infoGroup in ipairs(productionInfos) do
		local level, _, label = self:sumFillLevelInfos(infoGroup)

		self.animalProductLabel[productIndex]:setText(label)

		local valueText = self.l10n:formatVolume(level, 0)

		self.animalProductText[productIndex]:setText(valueText)

		productIndex = productIndex + 1
	end

	for i = productIndex, #self.animalProductLabel do
		self.animalProductLabel[i]:setText("")
		self.animalProductText[i]:setText("")
	end
end

function InGameMenuAnimalsFrame:updateHusbandryConditionsDisplay(husbandry)
	local conditionIndex = 1
	local value = husbandry:getFoodSpillageFactor()

	if value ~= nil then
		local labelText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.CLEANLINESS)
		local valueText = self.l10n:formatNumber(value * 100, 0) .. " %"

		self:displayCondition(conditionIndex, labelText, valueText, value)

		conditionIndex = conditionIndex + 1
	end

	local waterInfos = husbandry:getWaterFilltypeInfo()

	if waterInfos ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		local volume, maxVolume, label = self:sumFillLevelInfos(waterInfos)
		local fillValue = volume / maxVolume
		local valueText = self.l10n:formatVolume(volume, 0)

		self:displayCondition(conditionIndex, label, valueText, fillValue)

		conditionIndex = conditionIndex + 1
	end

	local strawInfos = husbandry:getStrawFilltypeInfo()

	if strawInfos ~= AnimalHusbandry.NO_FILLTYPE_INFOS then
		local volume, maxVolume, label = self:sumFillLevelInfos(strawInfos)
		local fillValue = volume / maxVolume
		local valueText = self.l10n:formatVolume(volume, 0)

		self:displayCondition(conditionIndex, label, valueText, fillValue)

		conditionIndex = conditionIndex + 1
	end

	for i = conditionIndex, #self.conditionRow do
		self:displayCondition(i)
	end
end

function InGameMenuAnimalsFrame:updateHusbandryFoodDisplay(husbandry)
	local animalType = husbandry:getAnimalType()
	local foodGroups = self.animalFoodManager:getFoodGroupByAnimalType(animalType)
	local foodInfos = husbandry:getFoodFilltypeInfo()
	local totalFillLevel = 0
	local capacity = 1
	local groupDisplayValues = {}

	for _, foodGroupInfos in pairs(foodInfos) do
		local groupFillTypesLabel = ""
		local groupTotalFillLevel = foodGroupInfos.fillLevel

		for i, foodFillTypeIndex in ipairs(foodGroupInfos.foodGroup.fillTypes) do
			local filltype = g_fillTypeManager:getFillTypeByIndex(foodFillTypeIndex)
			groupFillTypesLabel = groupFillTypesLabel .. filltype.title

			if i < #foodGroupInfos.foodGroup.fillTypes then
				groupFillTypesLabel = groupFillTypesLabel .. InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR
			end
		end

		capacity = foodGroupInfos.capacity

		table.insert(groupDisplayValues, {
			groupWeight = foodGroupInfos.foodGroup.productionWeight,
			fillTypeLabel = groupFillTypesLabel,
			fillRatio = math.min(groupTotalFillLevel / capacity, 1),
			valueText = self.l10n:formatVolume(groupTotalFillLevel, 0)
		})
	end

	local totalFillRatio = math.min(totalFillLevel / capacity, 1)
	local consumptionType = self.animalFoodManager:getFoodConsumptionTypeByAnimalType(animalType)
	local requirementIndex = 1
	local statusOffset = 0

	for _, displayValues in ipairs(groupDisplayValues) do
		if consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL then
			local maxDiff = 1 - displayValues.groupWeight
			local mixRatio = displayValues.fillRatio / totalFillRatio
			local ratioDiff = math.abs(mixRatio - displayValues.groupWeight) / maxDiff
		end

		self:displayRequirement(requirementIndex, displayValues.fillTypeLabel, displayValues.valueText, displayValues.fillRatio, statusOffset)

		requirementIndex = requirementIndex + 1
	end

	for i = requirementIndex, #self.requirementRow do
		self:displayRequirement(i)
	end
end

function InGameMenuAnimalsFrame:displayHorse(animal, horseHusbandry)
	self.animalDetailTypeNameText:setText(animal:getName())
	self.animalDetailTypeCountText:setText("")

	local horseValue = animal:getValue()
	local horseValueText = self.l10n:formatMoney(horseValue, 0, true, true)

	self.animalDetailTypeValueText:setText(horseValueText)

	local storeInfo = animal:getSubType().storeInfo

	self.animalDetailTypeImage:setImageFilename(storeInfo.imageFilename)
	self:setStatusBarValue(self.fitnessStatusBar, animal:getFitnessScale(), 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_LARGE)
	self.fitnessValueText:setText(string.format("%d %%", animal:getFitnessScale() * 100))
	self:setStatusBarValue(self.healthStatusBar, animal:getHealthScale(), 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_LARGE)
	self.healthValueText:setText(string.format("%d %%", animal:getHealthScale() * 100))

	local cleanliness = 1 - animal:getDirtScale()

	self:setStatusBarValue(self.cleanlinessStatusBar, cleanliness, 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_LARGE)
	self.cleanlinessValueText:setText(string.format("%d %%", cleanliness * 100))
	self:updateHusbandryConditionsDisplay(horseHusbandry)
	self:updateHusbandryFoodDisplay(horseHusbandry)

	local horseInfoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_HORSE)
	local foodText = self:getFoodDescription(horseHusbandry:getAnimalType())

	self.detailDescriptionText:setText(horseInfoText .. " " .. foodText)
end

function InGameMenuAnimalsFrame:displayLivestock(animals, livestockHusbandry)
	local animal = animals[1]
	local subType = animal:getSubType()
	local storeInfo = animal:getSubType().storeInfo

	self.animalDetailTypeNameText:setText(storeInfo.shopItemName)
	self.animalDetailTypeCountText:setText(tostring(#animals))
	self.animalDetailTypeValueText:setText("")
	self.animalDetailTypeImage:setImageFilename(storeInfo.imageFilename)

	local productivity = livestockHusbandry:getGlobalProductionFactor()
	local valueText = self.l10n:formatNumber(productivity * 100, 0) .. " %"

	self.productivityValueText:setText(valueText)
	self:setStatusBarValue(self.productivityStatusBar, productivity, 0, InGameMenuAnimalsFrame.PROFILE.STATUS_BAR_SMALL)

	local rate = livestockHusbandry:getReproductionTimePerDay(subType.fillType)

	self.animalReproductionRateText:setText(self.l10n:formatMinutes(rate))

	local minutesUntilNextAnimal = livestockHusbandry:getMinutesUntilNextAnimal(animal:getFillTypeIndex())

	self.animalTimeTillNextAnimalText:setText(self.l10n:formatMinutes(minutesUntilNextAnimal))
	self:updateLivestockHusbandryProductionDisplay(livestockHusbandry)
	self:updateHusbandryConditionsDisplay(livestockHusbandry)
	self:updateHusbandryFoodDisplay(livestockHusbandry)

	local infoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_LIVESTOCK)

	if subType.type == InGameMenuAnimalsFrame.CHICKEN_TYPE then
		infoText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.DESC_CHICKEN)
	end

	local foodText = self:getFoodDescription(livestockHusbandry:getAnimalType())

	self.detailDescriptionText:setText(infoText .. " " .. foodText)
end

function InGameMenuAnimalsFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	if self.selectedHorse ~= nil then
		table.insert(self.menuButtonInfo, self.renameButtonInfo)
	end

	if self.selectedHusbandry ~= nil and #self.selectedHusbandry.mapHotspots > 0 then
		if self.selectedHusbandry.mapHotspots[1] == g_currentMission.currentMapTargetHotspot then
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.REMOVE_MARKER)
		else
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.SET_MARKER)
		end

		table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuAnimalsFrame:renameCurrentHorse(newName, hasConfirmed)
	if hasConfirmed and self.selectedHorse ~= nil then
		self.selectedHusbandry:renameAnimal(NetworkUtil.getObjectId(self.selectedHorse), newName)
	end
end

function InGameMenuAnimalsFrame:getFoodDescription(forAnimalType)
	local consumptionType = self.animalFoodManager:getFoodConsumptionTypeByAnimalType(forAnimalType)
	local foodGroups = self.animalFoodManager:getFoodGroupByAnimalType(forAnimalType)
	local foodDescription = ""

	if consumptionType == AnimalFoodManager.FOOD_CONSUME_TYPE_PARALLEL then
		foodDescription = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_PARALLEL)
	else
		foodDescription = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_DESCRIPTION_SERIAL)
	end

	foodDescription = foodDescription .. "\n"
	local weightLabel = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.FOOD_MIX_EFFECTIVENESS)
	local line = ""

	for i, group in ipairs(foodGroups) do
		local fillTypeNames = ""

		for j, fillTypeIndex in ipairs(group.fillTypes) do
			local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			fillTypeNames = fillTypeNames .. fillType.title

			if j < #group.fillTypes then
				fillTypeNames = fillTypeNames .. InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR
			end
		end

		line = "- " .. fillTypeNames
		line = line .. string.format(" (%s: %.0f%%)", weightLabel, group.productionWeight * 100)
		foodDescription = foodDescription .. line

		if i < #foodGroups then
			foodDescription = foodDescription .. "\n"
		end
	end

	return foodDescription
end

function InGameMenuAnimalsFrame:onButtonRename()
	local promptText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.PROMPT_RENAME)
	local imePromptText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.IME_PROMPT_RENAME)
	local confirmText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_CONFIRM)
	local activateInputText = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_RENAME)

	g_gui:showTextInputDialog({
		target = self,
		callback = self.renameCurrentHorse,
		defaultText = self.selectedHorse:getName(),
		dialogPrompt = promptText,
		imePrompt = imePromptText,
		confirmText = confirmText,
		maxCharacters = InGameMenuAnimalsFrame.MAX_ANIMAL_NAME_LENGTH,
		activateInputText = activateInputText
	})
end

function InGameMenuAnimalsFrame:onButtonHotspot()
	local husbandry = self.selectedHusbandry

	if husbandry and next(husbandry.mapHotspots) ~= nil then
		if self.selectedHusbandry.mapHotspots[1] == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
		else
			g_currentMission:setMapTargetHotspot(husbandry.mapHotspots[1])
		end

		self:updateMenuButtons()
	end
end

function InGameMenuAnimalsFrame:onListSelectionChanged(selectedIndex)
	self.selectedHorse = nil
	self.selectedAnimals = nil

	if self.animalsDataSource:getCount() > 0 then
		local selectedData = self.animalsDataSource:getItem(selectedIndex)

		if selectedData ~= nil then
			if selectedData.isHorse then
				self.selectedHorse = selectedData.horse
			else
				self.selectedAnimals = selectedData.animals
			end

			if GS_IS_MOBILE_VERSION then
				self.animalDetailLivestockBox:setVisible(true)
			else
				self.animalDetailHorseBox:setVisible(selectedData.isHorse)
				self.animalDetailLivestockBox:setVisible(not selectedData.isHorse)
			end

			self.selectedHusbandry = selectedData.husbandry

			if selectedData.husbandry ~= nil then
				if selectedData.isHorse then
					self:displayHorse(self.selectedHorse, selectedData.husbandry)
				else
					self:displayLivestock(self.selectedAnimals, selectedData.husbandry)
				end
			end

			self.livestockAttributesLayout:invalidateLayout()
		end
	end

	self:updateMenuButtons()
end

InGameMenuAnimalsFrame.FILL_TYPE_SEPARATOR = " / "
InGameMenuAnimalsFrame.L10N_SYMBOL = {
	LIVESTOCK_PRODUCTIVITY = "statistic_productivity",
	BUTTON_CONFIRM = "button_confirm",
	REMOVE_MARKER = "action_untag",
	HORSE_DAILY_RIDING = "ui_horseDailyRiding",
	HORSE_FITNESS = "ui_horseFitness",
	IME_PROMPT_RENAME = "ui_horseName",
	BUTTON_HOTSPOT = "button_showOnMap",
	FOOD_MIX_EFFECTIVENESS = "animals_foodMixEffectiveness",
	FOOD_MIX_QUANITITY = "animals_foodMixQuantity",
	FOOD_DESCRIPTION_PARALLEL = "animals_foodMixDescriptionParallel",
	PROMPT_RENAME = "ui_enterHorseName",
	DESC_HORSE = "animals_descriptionHorse",
	BUTTON_RENAME = "button_rename",
	SET_MARKER = "action_tag",
	FOOD_DESCRIPTION_SERIAL = "animals_foodMixDescriptionSerial",
	DESC_CHICKEN = "animals_descriptionChicken",
	WATER = "statistic_water",
	DESC_LIVESTOCK = "animals_descriptionGeneric",
	CLEANLINESS = "statistic_cleanliness",
	STRAW = "statistic_strawStorage"
}
InGameMenuAnimalsFrame.STATUS_BAR_HIGH = 0.66
InGameMenuAnimalsFrame.STATUS_BAR_MEDIUM = 0.33
InGameMenuAnimalsFrame.PROFILE = {
	HEADER_LIST_ITEM = "ingameMenuAnimalsListHeader",
	STATUS_BAR_LARGE = {
		HIGH = "ingameMenuAnimalsLargeStatusBar",
		LOW = "ingameMenuAnimalsLargeStatusBarLow",
		MEDIUM = "ingameMenuAnimalsLargeStatusBarMedium"
	},
	STATUS_BAR_SMALL = {
		HIGH = "ingameMenuAnimalsSmallStatusBar",
		LOW = "ingameMenuAnimalsSmallStatusBarLow",
		MEDIUM = "ingameMenuAnimalsSmallStatusBarMedium"
	}
}
