ShopConfigScreen = {}
local ShopConfigScreen_mt = Class(ShopConfigScreen, ScreenElement)
ShopConfigScreen.CONTROLS = {
	CONFIG_SLIDER_BOX = "configSliderBox",
	CONFIG_PRICES = "configPrice",
	BUYING_TOTAL_PRICE = "totalPriceText",
	LEASING_COST_PER_HOUR = "costsPerOperatingHourText",
	ATTRIBUTE_VALUES = "attrValue",
	LEASING_INITIAL_COST = "initialCostsText",
	CONFIG_SLIDER_BACKGROUND = "configSliderBackground",
	MONEY_BOX = "shopMoneyBox",
	BUYING_UPGRADES_PRICE = "upgradesPriceText",
	COLOR_PICKER_BUTTONS = "colorPicker",
	MONEY_TEXT = "shopMoney",
	CONFIG_OPTIONS = "configOption",
	LOADING_ANIMATION = "loadingAnimation",
	CONTENT = "shopConfigContent",
	LEASING_BASE_COST = "costsBaseText",
	COLOR_IMAGES = "colorImage",
	ROTATE_INPUT_GLYPH_FRAME = "rotateInputGlyphFrame",
	ITEM_NAME = "shopConfigItemName",
	BUY_BUTTON = "buyButton",
	CONFIG_NAMES = "configName",
	BUYING_BASE_PRICE = "basePriceText",
	CHANGE_COLOR_BUTTON = "changeColorButton",
	ATTRIBUTE_ICONS = "attrIcon",
	LEASING_COST_PER_DAY = "costsPerDayText",
	COLOR_PRICES = "colorPrice",
	LEASE_BUTTON = "leaseButton",
	COLOR_NAMES = "colorName",
	BUTTONS = "buttonsPC",
	BRAND_ICON = "shopConfigBrandIcon",
	CONFIG_SLIDER = "configSlider",
	ZOOM_INPUT_GLYPH_FRAME = "zoomInputGlyphFrame",
	LEFT_CONFIG_BOX = "leftConfigBox"
}
ShopConfigScreen.INPUT_CONTEXT_NAME = "MENU_SHOP_CONFIG"
ShopConfigScreen.FADE_TEXTURE_PATH = "dataS/scripts/shared/graph_pixel.png"
ShopConfigScreen.WORKSHOP_PATH = "$data/maps/textures/shared/uiStore.i3d"
ShopConfigScreen.NEAR_CLIP_DISTANCE = 0.2
ShopConfigScreen.MAX_CAMERA_HEIGHT = 11
ShopConfigScreen.MAX_CAMERA_DISTANCE = 13.5
ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR = 3
ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR = 0.8
ShopConfigScreen.CAMERA_MIN_DISTANCE_TO_X_OFFSET_FACTOR = ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR * 0.1875
ShopConfigScreen.FAR_BLUR_END_DISTANCE = 100
ShopConfigScreen.INITIAL_CAMERA_ROTATION = {
	0,
	-140,
	0
}
ShopConfigScreen.MOUSE_SPEED_MULTIPLIER = 2
ShopConfigScreen.MIN_MOUSE_DRAG_INPUT = 0.02 * InputBinding.MOUSE_MOVE_BASE_FACTOR
ShopConfigScreen.NO_VEHICLE = {
	delete = function ()
	end
}
ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG = "motor"
ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG = "fillUnit"

local function NO_CALLBACK()
end

function ShopConfigScreen:new(shopController, messageCenter, l10n, i3dManager, brandManager, configurationManager, vehicleTypeManager, inputManager, inputDisplayManager)
	local self = ScreenElement:new(nil, ShopConfigScreen_mt)
	self.currentMission = nil
	self.economyManager = nil
	self.shopController = shopController
	self.l10n = l10n
	self.i3dManager = i3dManager
	self.brandManager = brandManager
	self.configurationManager = configurationManager
	self.vehicleTypeManager = vehicleTypeManager
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager

	self:registerControls(ShopConfigScreen.CONTROLS)

	self.fadeOverlay = Overlay:new(ShopConfigScreen.FADE_TEXTURE_PATH, 0, 0, 1, 1)

	self.fadeOverlay:setColor(0, 0, 0, 0)

	self.fadeInAnimation = TweenSequence.NO_SEQUENCE
	self.fadeOutAnimation = TweenSequence.NO_SEQUENCE
	self.rotateInputGlyph = nil
	self.zoomInputGlyph = nil
	self.lastInputHelpMode = nil

	self:createInputGlyphs()

	self.configBasePrice = 0
	self.totalPrice = 0
	self.initialLeasingCosts = 0
	self.lastMoney = 0
	self.displayableOptionCount = 0
	self.displayableColorCount = 0
	self.callbackFunc = nil
	self.requestExitCallback = NO_CALLBACK
	self.workshopWorldPosition = {
		0,
		0,
		0
	}
	self.workshopRootNode = nil
	self.workshopNode = nil
	self.limitRotXDelta = 0
	self.cameraDistance = 10
	self.cameraMaxDistance = 20
	self.cameraMinDistance = 1
	self.zoomTarget = self.cameraDistance
	self.rotZ = 0
	self.rotY = 0
	self.rotX = 0
	self.rotMaxX = MathUtil.degToRad(70)
	self.rotMinX = 0
	self.focusY = 0
	self.rotateNode = nil
	self.cameraNode = nil
	self.previousCamera = nil

	self:createCamera()
	self:resetCamera()

	self.isLoadingInitial = false
	self.previewVehicleSize = 0
	self.previewVehicles = {}
	self.loadingCount = 0
	self.loadedCount = 0
	self.inputHorizontal = 0
	self.inputVertical = 0
	self.inputZoom = 0
	self.eventIdUpDownController = ""
	self.eventIdLeftRightController = ""
	self.eventIdUpDownMouse = ""
	self.eventIdLeftRightMouse = ""
	self.inputDragging = false
	self.isDragging = false
	self.accumDraggingInput = 0
	self.lastInputMode = inputManager:getLastInputMode()
	self.lastInputHelpMode = inputManager:getInputHelpMode()
	self.currentConfigSet = 1

	self:createFadeAnimations()
	messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBought, self)

	return self
end

function ShopConfigScreen:createInputGlyphs()
	local iconWidth, iconHeight = getNormalizedScreenValues(unpack(ShopConfigScreen.SIZE.INPUT_GLYPH))
	self.rotateInputGlyph = InputGlyphElement:new(self.inputDisplayManager, iconWidth, iconHeight)

	self.rotateInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)

	self.zoomInputGlyph = InputGlyphElement:new(self.inputDisplayManager, iconWidth, iconHeight)

	self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
end

function ShopConfigScreen:createFadeAnimations()
	local fadeInAnimation = TweenSequence.new(self)
	local fadeIn = Tween:new(self.fadeScreen, 1, 0, 300)

	fadeInAnimation:addTween(fadeIn)

	self.fadeInAnimation = fadeInAnimation
	local fadeOutAnimation = TweenSequence.new(self)
	local fadeOut = Tween:new(self.fadeScreen, 0, 1, 300)

	fadeOutAnimation:addTween(fadeOut)

	self.fadeOutAnimation = fadeOutAnimation
end

function ShopConfigScreen:fadeScreen(alpha)
	self.fadeOverlay:setColor(nil, , , alpha)
end

function ShopConfigScreen:createWorkshop(assetPath, posX, posY, posZ)
	self.workshopWorldPosition = {
		posX,
		posY,
		posZ
	}
	self.workshopRootNode = createTransformGroup("ShopConfigWorkshop")

	link(getRootNode(), self.workshopRootNode)
	setTranslation(self.workshopRootNode, posX, posY, posZ)
	setVisibility(self.workshopRootNode, false)
	self.i3dManager:loadSharedI3DFile(assetPath, nil, false, true, true, self.setWorkshopNode, self)
end

function ShopConfigScreen:setWorkshopNode(id)
	if id ~= 0 then
		self.workshopNode = id

		setTranslation(self.workshopNode, 0, 0, 0)
	end
end

function ShopConfigScreen:createCamera()
	self.cameraNode = createCamera("VehicleConfigCamera", math.rad(60), ShopConfigScreen.NEAR_CLIP_DISTANCE, 100)

	setTranslation(self.cameraNode, 0, 0, -self.cameraDistance)
	setRotation(self.cameraNode, 0, math.rad(180), 0)

	self.rotateNode = createTransformGroup("VehicleConfigCameraTarget")

	setRotation(self.rotateNode, 0, math.rad(180), 0)
	setTranslation(self.rotateNode, 0, 0, 0)
	link(self.rotateNode, self.cameraNode)
end

function ShopConfigScreen:resetCamera()
	local rx, ry, rz = unpack(ShopConfigScreen.INITIAL_CAMERA_ROTATION)
	self.rotZ = MathUtil.degToRad(rz)
	self.rotY = MathUtil.degToRad(ry)
	self.rotX = MathUtil.degToRad(rx)
	self.cameraDistance = (self.cameraMinDistance + self.cameraMaxDistance) * 0.5
end

function ShopConfigScreen:delete()
	self.rotateInputGlyph:delete()
	self.zoomInputGlyph:delete()
	self.fadeOverlay:delete()
	self:deletePreviewVehicles()

	if self.workshopNode ~= nil then
		delete(self.workshopNode)
	end

	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)

		self.workshopRootNode = nil
	end

	self.i3dManager:releaseSharedI3DFile(self.workshopFilename)
	ShopConfigScreen:superClass().delete(self)
end

function ShopConfigScreen:onGuiSetupFinished()
	ShopConfigScreen:superClass().onGuiSetupFinished(self)

	local baseMouseEvent = self.configSliderBox.mouseEvent

	function self.configSliderBox.mouseEvent(sliderSelf, posX, posY, isDown, isUp, button, eventUsed)
		return baseMouseEvent(sliderSelf, posX, posY, false, false, button, eventUsed)
	end
end

function ShopConfigScreen:updateBalanceText()
	local money = self.currentMission:getMoney()
	self.lastMoney = money

	self.shopMoney:setText(self.l10n:formatMoney(money, 0, true, true), true)

	if money > 0 then
		self.shopMoney:applyProfile(ShopConfigScreen.GUI_PROFILE.SHOP_MONEY)
	else
		self.shopMoney:applyProfile(ShopConfigScreen.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
	end

	self.shopMoneyBox:invalidateLayout()
end

function ShopConfigScreen:processStoreItemUpkeep(storeItem)
	local dailyUpkeep = 0

	if storeItem.dailyUpkeep ~= nil then
		dailyUpkeep = storeItem.dailyUpkeep

		for name, id in pairs(self.configurations) do
			local configs = storeItem.configurations[name]
			dailyUpkeep = dailyUpkeep + configs[id].dailyUpkeep
		end
	end

	return dailyUpkeep
end

function ShopConfigScreen:processStoreItemPowerOutput(storeItem)
	local power = 0

	if storeItem.specs ~= nil and storeItem.specs.power ~= nil then
		power = storeItem.specs.power

		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local configId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			power = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][configId].power, power)
		end
	end

	return power
end

function ShopConfigScreen:processStoreItemFuelCapacity(storeItem, fuelFillType)
	local fuel = 0

	if storeItem.specs ~= nil and storeItem.specs.fuel ~= nil then
		local consumerIndex = 1
		local motorConfigId = 1

		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			motorConfigId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			consumerIndex = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][motorConfigId].consumerConfigurationIndex, consumerIndex)
		end

		local fuelFillUnitIndex = 0
		local consumerConfiguration = storeItem.specs.fuel.consumers[consumerIndex]

		if consumerConfiguration ~= nil then
			for _, unitConsumers in ipairs(consumerConfiguration) do
				if g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType) == fuelFillType then
					fuelFillUnitIndex = unitConsumers.fillUnitIndex

					break
				end
			end
		end

		local fillUnitConfigId = 1

		if self.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG] ~= nil then
			fillUnitConfigId = self.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG]
		end

		if storeItem.specs.fuel.fillUnits[fillUnitConfigId] ~= nil then
			local fuelFillUnit = storeItem.specs.fuel.fillUnits[fillUnitConfigId][fuelFillUnitIndex]

			if fuelFillUnit ~= nil then
				fuel = math.max(fuelFillUnit.capacity, fuel or 0)
			end
		end
	end

	return fuel
end

function ShopConfigScreen:processStoreItemMaxSpeed(storeItem)
	local maxSpeed = 0

	if storeItem.specs ~= nil and storeItem.specs.maxSpeed ~= nil then
		maxSpeed = storeItem.specs.maxSpeed

		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local configId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			maxSpeed = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][configId].maxSpeed, maxSpeed)
		end
	end

	return maxSpeed
end

function ShopConfigScreen:processStoreItemCapacity(storeItem)
	if storeItem.specs ~= nil and storeItem.specs.capacity ~= nil then
		return FillUnit.getSpecValueCapacity(storeItem, nil, true, self.configurations)
	else
		return 0, ""
	end
end

function ShopConfigScreen:processStoreItemWorkingWidth(storeItem, realItem)
	if storeItem.specs ~= nil then
		if storeItem.specs.workingWidth ~= nil then
			return storeItem.specs.workingWidth
		elseif storeItem.specs.workingWidthVar ~= nil then
			return Foldable.getSpecValueWorkingWidth(storeItem, nil, , self.configurations.folding, false) or 0
		end
	end

	return 0
end

function ShopConfigScreen:processStoreItemWorkingSpeed(storeItem)
	if storeItem.specs ~= nil and storeItem.specs.speedLimit ~= nil then
		return storeItem.specs.speedLimit
	else
		return 0
	end
end

function ShopConfigScreen:processStoreItemPowerNeeded(storeItem)
	if storeItem.specs ~= nil and storeItem.specs.neededPower ~= nil then
		return storeItem.specs.neededPower
	else
		return 0
	end
end

function ShopConfigScreen:processAttributeData(storeItem, vehicle)
	local dailyUpkeep = 0
	local powerOutput = 0
	local fuelCapacity = 0
	local defCapacity = 0
	local maxSpeed = 0
	local capacity = 0
	local capacityUnit = ""
	local workingWidth = 0
	local workingSpeed = 0
	local powerNeeded = 0
	local storeItems = nil

	if storeItem.bundleInfo == nil then
		storeItems = {
			storeItem
		}
	else
		storeItems = {
			unpack(storeItem.bundleInfo.bundleItems)
		}
	end

	for _, item in ipairs(storeItems) do
		dailyUpkeep = dailyUpkeep + self:processStoreItemUpkeep(item)
		powerOutput = powerOutput + self:processStoreItemPowerOutput(item)
		fuelCapacity = fuelCapacity + self:processStoreItemFuelCapacity(item, FillType.DIESEL)
		defCapacity = defCapacity + self:processStoreItemFuelCapacity(item, FillType.DEF)
		local itemCapacity, itemCapacityUnit = self:processStoreItemCapacity(item, vehicle)

		if capacityUnit ~= "" and itemCapacityUnit ~= capacityUnit then
			print("Warning: Bundled store items have different fill capacity units. Check " .. tostring(storeItem.xmlFilename))
		end

		capacityUnit = itemCapacityUnit
		capacity = capacity + itemCapacity
		workingWidth = math.max(workingWidth, self:processStoreItemWorkingWidth(item))
		workingSpeed = math.max(workingSpeed, self:processStoreItemWorkingSpeed(item))
		maxSpeed = math.max(maxSpeed, self:processStoreItemMaxSpeed(item))
		powerNeeded = powerNeeded + self:processStoreItemPowerNeeded(item)
	end

	local values = {}

	if dailyUpkeep ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.MAINTENANCE_COST,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.MAINTENANCE_COST), self.l10n:formatMoney(dailyUpkeep, 2))
		})
	end

	if powerOutput ~= 0 then
		local hp, kw = self.l10n:getPower(powerOutput)

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.POWER,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.POWER), MathUtil.round(kw), MathUtil.round(hp))
		})
	end

	if fuelCapacity ~= 0 then
		if defCapacity == 0 then
			table.insert(values, {
				profile = ShopConfigScreen.GUI_PROFILE.FUEL,
				value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), fuelCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER))
			})
		elseif defCapacity > 0 then
			table.insert(values, {
				profile = ShopConfigScreen.GUI_PROFILE.FUEL,
				value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL_DEF), fuelCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), defCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.DEF_SHORT))
			})
		end
	end

	if maxSpeed ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.MAX_SPEED,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.MAX_SPEED), string.format("%1d", self.l10n:getSpeed(maxSpeed)), self.l10n:getSpeedMeasuringUnit())
		})
	end

	if capacity ~= 0 and capacityUnit ~= "" then
		if capacityUnit:sub(1, 6) == "$l10n_" then
			capacityUnit = capacityUnit:sub(7)
		end

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.CAPACITY,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CAPACITY), capacity, self.l10n:getText(capacityUnit))
		})
	end

	if powerNeeded ~= 0 then
		local hp, kw = self.l10n:getPower(powerNeeded)

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.POWER_REQUIREMENT,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.POWER_REQUIREMENT), MathUtil.round(kw), MathUtil.round(hp))
		})
	end

	if workingWidth ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), g_i18n:formatNumber(workingWidth, 1, true))
		})
	end

	if workingSpeed ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WORKING_SPEED,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_SPEED), string.format("%1d", self.l10n:getSpeed(workingSpeed)), self.l10n:getSpeedMeasuringUnit())
		})
	end

	for i, element in ipairs(self.attrIcon) do
		if values[i] ~= nil then
			element:applyProfile(values[i].profile)
			element:setVisible(true)
		else
			element:setVisible(false)
		end
	end

	for i, element in ipairs(self.attrValue) do
		if values[i] ~= nil then
			element:setText(values[i].value)
		else
			element:setText("")
		end
	end
end

function ShopConfigScreen:getConfigurationCostsAndChanges(storeItem, vehicle)
	local basePrice = 0
	local upgradePrice = 0
	local hasChanges = false

	if vehicle ~= nil then
		for name, id in pairs(self.configurations) do
			if vehicle.configurations[name] ~= id then
				hasChanges = true

				if not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, id) then
					local configs = storeItem.configurations[name]
					local price = math.max(configs[id].price - configs[self.vehicle.configurations[name]].price, 0)
					upgradePrice = upgradePrice + price
				end
			end
		end
	elseif storeItem ~= nil then
		hasChanges = true
		basePrice, upgradePrice = self.economyManager:getBuyPrice(storeItem, self.configurations)
		basePrice = basePrice - upgradePrice
	end

	return basePrice, upgradePrice, hasChanges
end

function ShopConfigScreen:updatePriceData(basePrice, upgradePrice)
	self.totalPrice = basePrice + upgradePrice
	self.initialLeasingCosts = 0
	self.initialLeasingCosts = self.economyManager:getInitialLeasingPrice(self.totalPrice)

	self.basePriceText:setText(self.l10n:formatMoney(basePrice, 0, true, false))
	self.upgradesPriceText:setText("+ " .. self.l10n:formatMoney(upgradePrice, 0, true, false))
	self.totalPriceText:setText(self.l10n:formatMoney(self.totalPrice, 0, true, false))
	self.costsBaseText:setText(self.l10n:formatMoney(self.totalPrice * EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR, 0, true, false))
	self.initialCostsText:setText(self.l10n:formatMoney(self.initialLeasingCosts, 0, true, false))
	self.costsPerOperatingHourText:setText(self.l10n:formatMoney(self.totalPrice * EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR, 0, true, false))
	self.costsPerDayText:setText(self.l10n:formatMoney(self.totalPrice * EconomyManager.PER_DAY_LEASING_FACTOR, 0, true, false))
end

function ShopConfigScreen:updateData(storeItem, vehicle)
	self:processAttributeData(storeItem, vehicle)

	local basePrice, upgradePrice, hasChanges = self:getConfigurationCostsAndChanges(storeItem, vehicle)

	self:updatePriceData(basePrice, upgradePrice)
	self.buyButton:setDisabled(not hasChanges)

	self.loadingCount = storeItem.bundleInfo ~= nil and #storeItem.bundleInfo.bundleItems or 1
	self.loadedCount = 0

	self:loadCurrentConfiguration(storeItem)
end

function ShopConfigScreen:overrideOptionFocus(optionElement, optionIndex, scrollValue, numVisibleConfigs, numColors, isFirstEnabled, isLastEnabled)
	local prevIndex = optionIndex - 1

	if prevIndex == 0 then
		prevIndex = #self.configOption
	end

	local nextIndex = optionIndex + 1

	if nextIndex > #self.configOption then
		nextIndex = 1
	end

	FocusManager:linkElements(optionElement, FocusManager.TOP, self.configOption[prevIndex])
	FocusManager:linkElements(optionElement, FocusManager.BOTTOM, self.configOption[nextIndex])

	if isFirstEnabled then
		if scrollValue > 1 then
			optionElement.focusChangeOverride = self:makeOptionFocusOverrideTopScrolling(scrollValue, optionElement)
		else
			optionElement.focusChangeOverride = self:makeOptionFocusOverrideTopNoScrolling(numVisibleConfigs, numColors, optionElement)
		end
	end

	if isLastEnabled then
		if scrollValue < self.configSlider:getMaxValue() then
			optionElement.focusChangeOverride = self:makeOptionFocusOverrideBottomScrolling(scrollValue, optionElement)
		else
			optionElement.focusChangeOverride = self:makeOptionFocusOverrideBottomNoScrolling(numColors, optionElement)
		end
	end
end

function ShopConfigScreen:getDefaultConfigurationColorIndex(configName, configItems, vehicle)
	local index = nil

	for k, item in pairs(configItems) do
		if item.isDefault then
			index = k

			break
		end
	end

	if vehicle ~= nil then
		index = vehicle.configurations[configName]
	end

	if index == nil then
		index = 1
	end

	return index
end

function ShopConfigScreen:disableUnusedOptions(currentOptionIndex, currentColorIndex)
	for i = currentOptionIndex, #self.configOption do
		local optionElement = self.configOption[i]
		local nameElement = self.configName[i]
		local priceElement = self.configPrice[i]

		FocusManager:unsetFocus(optionElement)
		optionElement:setDisabled(true)
		optionElement:setTexts({})
		nameElement:setText("")
		priceElement:setText("")
	end

	for i = currentColorIndex, #self.colorPicker do
		local pickerElement = self.colorPicker[i]
		local nameElement = self.colorName[i]
		local priceElement = self.colorPrice[i]
		local imageElement = self.colorImage[i]

		pickerElement:setVisible(false)
		imageElement:setVisible(false)
		nameElement:setText("")
		priceElement:setText("")
	end
end

function ShopConfigScreen:updateButtons(storeItem, vehicle)
	self.leaseButton:setVisible(vehicle == nil and storeItem.allowLeasing)

	local buyButtonText = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_BUY)
	local buyButtonProfile = ShopConfigScreen.GUI_PROFILE.BUTTON_BUY

	if vehicle ~= nil then
		buyButtonText = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_CONFIGURE)
		buyButtonProfile = ShopConfigScreen.GUI_PROFILE.BUTTON_CONFIGURE
	end

	self.buyButton:setText(buyButtonText)
	self.buyButton:applyProfile(buyButtonProfile)
	self.buttonsPC:invalidateLayout()
end

function ShopConfigScreen:loadCurrentConfiguration(storeItem, vehicleIndex, offsetVector, yRotation)
	vehicleIndex = vehicleIndex or 1

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
			self:loadCurrentConfiguration(bundleItem.item, vehicleIndex, bundleItem.offset, bundleItem.rotation)

			vehicleIndex = vehicleIndex + 1
		end

		return
	end

	local filename = storeItem.xmlFilename
	local xmlFile = loadXMLFile("TempConfig", filename)
	local typeName = getXMLString(xmlFile, "vehicle#type")

	delete(xmlFile)

	local typeDef = self.vehicleTypeManager:getVehicleTypeByName(typeName)
	local modName, _ = Utils.getModNameAndBaseDirectory(filename)

	if modName ~= nil then
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			print("Error: Mod '" .. modName .. "' of vehicle '" .. filename .. "'")
			print("       is not loaded. This vehicle will not be loaded.")
			self:onVehicleLoaded(nil, BaseMission.VEHICLE_LOAD_ERROR, vehicleIndex)

			return
		end

		if typeDef == nil then
			typeName = modName .. "." .. typeName
			typeDef = self.vehicleTypeManager:getVehicleTypeByName(typeName)
		end
	end

	if typeDef == nil then
		print(string.format("Error: Unable to find vehicle type name '%s' for '%s'", typeName, filename))

		return
	end

	local vehicleClass = ClassUtil.getClassObject(typeDef.className)
	local vehicle = vehicleClass:new(true, true)
	local placePosX, placePosY, placePosZ = unpack(self.workshopWorldPosition)

	if offsetVector ~= nil then
		placePosX = placePosX + offsetVector[1]
		placePosY = placePosY + offsetVector[2]
		placePosZ = placePosZ + offsetVector[3]
	end

	if storeItem.shopTranslationOffset ~= nil then
		placePosX = placePosX + storeItem.shopTranslationOffset[1]
		placePosY = placePosY + storeItem.shopTranslationOffset[2]
		placePosZ = placePosZ + storeItem.shopTranslationOffset[3]
	end

	local lastVehicleComponentPositions = {}

	for index, preVehicle in ipairs(self.previewVehicles) do
		if preVehicle.configFileName == storeItem.xmlFilename then
			for i, component in ipairs(preVehicle.components) do
				lastVehicleComponentPositions[i] = {
					{
						getTranslation(component.node)
					},
					{
						getWorldRotation(component.node)
					}
				}
			end
		end
	end

	local rotX = 0
	local rotY = (yRotation or 0) + storeItem.rotation
	local rotZ = 0

	if storeItem.shopRotationOffset ~= nil then
		rotX = rotX + storeItem.shopRotationOffset[1]
		rotY = rotY + storeItem.shopRotationOffset[2]
		rotZ = rotZ + storeItem.shopRotationOffset[3]
	end

	local vehicleData = {
		filename = storeItem.xmlFilename,
		isAbsolute = true,
		typeName = typeName,
		price = 0,
		propertyState = Vehicle.PROPERTY_STATE_SHOP_CONFIG,
		posX = placePosX,
		posY = placePosY,
		posZ = placePosZ,
		yOffset = 0,
		rotX = rotX,
		rotY = rotY,
		rotZ = rotZ,
		isVehicleSaved = false
	}
	local configurations = {}
	local item = g_storeManager:getItemByXMLFilename(storeItem.xmlFilename)

	for configName, value in pairs(self.configurations) do
		if item.configurations[configName] ~= nil then
			configurations[configName] = value
		end
	end

	vehicleData.configurations = configurations
	vehicleData.componentPositions = lastVehicleComponentPositions

	self.loadingAnimation:setVisible(true)

	self.previewVehicleSize = 0

	vehicle:load(vehicleData, self.onVehicleLoaded, self, {
		vehicleIndex = vehicleIndex,
		shopFoldingState = storeItem.shopFoldingState
	})
end

function ShopConfigScreen:onVehicleLoaded(vehicle, loadingState, asyncArguments)
	if loadingState == BaseMission.VEHICLE_LOAD_OK then
		if asyncArguments.shopFoldingState ~= 0 and vehicle.setFoldState ~= nil then
			Foldable.setAnimTime(vehicle, 1 - vehicle.spec_foldable.startAnimTime, true)
		end

		if self.isLoadingInitial or self.isOpen then
			local previousVehicle = self.previewVehicles[asyncArguments.vehicleIndex]

			if previousVehicle ~= nil then
				previousVehicle:delete()
			end

			self.previewVehicles[asyncArguments.vehicleIndex] = vehicle
		else
			vehicle:delete()

			self.previewVehicles[asyncArguments.vehicleIndex] = nil
		end
	else
		print("Error: Could not load vehicle defined in [" .. tostring(self.storeItem.xmlFilename) .. "]. Check vehicle configuration and mods.")

		self.callbackFunc = nil

		self:onClickBack()
	end

	self.loadedCount = self.loadedCount + 1
	local doneLoading = self.loadedCount == self.loadingCount

	if doneLoading then
		if #self.previewVehicles > 1 then
			for _, loadedVehicle in pairs(self.previewVehicles) do
				for _, component in ipairs(loadedVehicle.components) do
					setVisibility(component.node, true)
				end
			end

			if self.storeItem.bundleInfo ~= nil then
				for _, attachInfo in pairs(self.storeItem.bundleInfo.attacherInfo) do
					local v1 = self.previewVehicles[attachInfo.bundleElement0]
					local v2 = self.previewVehicles[attachInfo.bundleElement1]

					v1:attachImplement(v2, attachInfo.inputAttacherJointIndex, attachInfo.attacherJointIndex, true, nil, false, true)
				end
			end
		end

		for _, loadedVehicle in pairs(self.previewVehicles) do
			local width = loadedVehicle.sizeWidth
			local length = loadedVehicle.sizeLength
			local largestDimension = math.max(width, length, self.storeItem.shopHeight * 1.5)
			self.previewVehicleSize = self.previewVehicleSize + largestDimension
		end

		self.cameraMaxDistance = math.min(self.previewVehicleSize * ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR, ShopConfigScreen.MAX_CAMERA_DISTANCE)
		self.cameraMinDistance = self.previewVehicleSize * ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR + ShopConfigScreen.NEAR_CLIP_DISTANCE
		self.focusY = self.previewVehicleSize * 0.1

		if self.isLoadingInitial then
			self.cameraDistance = math.min(self.cameraMinDistance * 1.5, self.cameraMaxDistance)
			self.zoomTarget = self.cameraDistance
			self.rotMinX = math.asin(ShopConfigScreen.NEAR_CLIP_DISTANCE / self.cameraMinDistance)
		end
	else
		for _, loadedVehicle in pairs(self.previewVehicles) do
			for _, component in ipairs(loadedVehicle.components) do
				setVisibility(component.node, false)
			end
		end
	end

	self.isLoadingInitial = self.isLoadingInitial and not doneLoading

	self.loadingAnimation:setVisible(not doneLoading)
	self:disableAlternateBindings()
end

function ShopConfigScreen:updateSlider()
	local numOptions = self.displayableOptionCount
	local numElements = #self.configOption
	local isSliderVisible = numOptions > numElements

	self.configSlider:setMinValue(1)
	self.configSliderBox:setMinValue(1)

	if isSliderVisible then
		local maxValue = math.ceil((numOptions - numElements) / 2) + 1

		self.configSlider:setMaxValue(maxValue)
		self.configSlider:setSliderSize(numElements, numOptions)
		self.configSliderBox:setMaxValue(maxValue)
	else
		self.configSlider:setMaxValue(1)
		self.configSliderBox:setMaxValue(1)
	end

	self.configSliderBackground:setVisible(isSliderVisible)
	self.configSliderBox:setVisible(isSliderVisible)
end

function ShopConfigScreen:onSliderChanged(sliderValue)
	if self.configSlider:getValue() ~= sliderValue then
		self.configSlider:setValue(sliderValue, true)
	elseif self.configSliderBox:getValue() ~= sliderValue then
		self.configSliderBox:setValue(sliderValue, true)
	end

	self:updateDisplay(self.storeItem, self.vehicle, sliderValue, true)
end

function ShopConfigScreen:updateDisplay(storeItem, vehicle, scrollValue, doNotReload)
	local brand = self.brandManager:getBrandByIndex(storeItem.brandIndex)

	self.shopConfigBrandIcon:setImageFilename(brand.image)
	self.shopConfigItemName:setText(storeItem.name)
	self:updateConfigOptionsDisplay(scrollValue, storeItem, vehicle)
	self:updateButtons(storeItem, vehicle)

	if not doNotReload then
		self:updateData(storeItem, vehicle)
	end
end

function ShopConfigScreen:setCurrentMission(currentMission)
	self.currentMission = currentMission

	if self.shopLighting ~= nil then
		self.shopLighting:setEnvironment(self.currentMission.environment)
	end
end

function ShopConfigScreen:setEconomyManager(economyManager)
	self.economyManager = economyManager
end

function ShopConfigScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	if not GS_IS_MOBILE_VERSION then
		local shopConfigFilename = getXMLString(mapXMLFile, "map.shop#filename") or "$data/store/ui/shop.xml"
		shopConfigFilename = Utils.getFilename(shopConfigFilename, baseDirectory)
		local xmlFile = loadXMLFile("TempConfig", shopConfigFilename)
		self.workshopFilename = getXMLString(xmlFile, "shop.filename") or ShopConfigScreen.WORKSHOP_PATH
		local x = getXMLFloat(xmlFile, "shop.position#xMapPos") or 0
		local y = getXMLFloat(xmlFile, "shop.position#yMapPos") or 0
		local z = getXMLFloat(xmlFile, "shop.position#zMapPos") or 0
		self.shopLighting = Lighting:new()

		self.shopLighting:load(xmlFile, "shop")
		delete(xmlFile)
		self:createWorkshop(self.workshopFilename, x, y, z)
	end
end

function ShopConfigScreen:unloadMapData()
	if self.workshopNode ~= nil then
		delete(self.workshopNode)
	end

	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)
	end

	self.workshopNode = nil
	self.workshopRootNode = nil
end

function ShopConfigScreen:setWorkshopWorldPosition(posX, posY, posZ)
	self.workshopWorldPosition = {
		posX,
		posY,
		posZ
	}
end

function ShopConfigScreen:setCallbacks(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end

function ShopConfigScreen:deletePreviewVehicles()
	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:delete()
	end

	self.previewVehicles = {}
end

function ShopConfigScreen:setStoreItem(storeItem, vehicle, configBasePrice)
	self:deletePreviewVehicles()

	self.storeItem = storeItem
	self.vehicle = vehicle
	self.configBasePrice = Utils.getNoNil(configBasePrice, 0)
	self.configurations = {}
	self.subConfigurations = {}
	self.currentConfigSet = 1
	self.isLoadingInitial = true

	self:processStoreItemConfigurations(storeItem, vehicle)
	self:updateDisplay(storeItem, vehicle, 1)
	self:resetCamera()
end

function ShopConfigScreen:setRequestExitCallback(callback)
	self.requestExitCallback = callback or NO_CALLBACK
end

function ShopConfigScreen.shouldFocusChange(element, direction)
	return true
end

function ShopConfigScreen:setConfigPrice(configName, configIndex, priceTextElement, vehicle)
	local configItems = self.storeItem.configurations[configName]
	local price = configItems[configIndex].price

	if vehicle ~= nil then
		if ConfigurationUtil.hasBoughtConfiguration(vehicle, configName, configIndex) then
			price = 0
		else
			price = math.max(price - configItems[vehicle.configurations[configName]].price, 0)
		end
	end

	priceTextElement:setText("+" .. self.l10n:formatMoney(price) .. "")
	priceTextElement:setVisible(true)
end

function ShopConfigScreen:onPickColor(colorIndex, args, noUpdate)
	if colorIndex ~= nil then
		local configName = args.configName
		local colorOptionIndex = args.colorOptionIndex
		self.configurations[configName] = colorIndex
		local color = self.storeItem.configurations[configName][colorIndex].color
		color[4] = 1

		self.colorImage[colorOptionIndex]:setImageColor(nil, unpack(color))
		self:setConfigPrice(configName, colorIndex, self.colorPrice[colorOptionIndex], self.vehicle)

		if not noUpdate then
			self:updateData(self.storeItem, self.vehicle)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end

function ShopConfigScreen:selectFirstConfig()
	local firstElement = self.buyButton

	if self.colorPicker[1]:getIsVisible() then
		firstElement = self.colorPicker[1]
	elseif not self.configOption[1]:getIsDisabled() then
		firstElement = self.configOption[1]
	end

	self.configSlider:setValue(0, true)
	FocusManager:unsetFocus(firstElement)
	FocusManager:setFocus(firstElement)
end

function ShopConfigScreen:processStoreItemConfigurationSet(storeItem, configSet, vehicle)
	local options = {}
	local configurationTypes = self.configurationManager:getConfigurationTypes()
	local configNames = {}
	local subConfigIndex = 1

	for _, configName in ipairs(configurationTypes) do
		if self.configurationManager:getConfigurationAttribute(configName, "selectorType") ~= ConfigurationUtil.SELECTOR_COLOR then
			local items = storeItem.configurations[configName]
			local subConfigItems = storeItem.subConfigurations[configName]

			if subConfigItems ~= nil and #subConfigItems.subConfigValues > 1 then
				table.insert(configNames, subConfigIndex, configName)

				subConfigIndex = subConfigIndex + 1
			elseif items ~= nil and #items > 1 and configSet.configurations[configName] == nil then
				table.insert(configNames, configName)
			end
		end
	end

	for i, configName in ipairs(configNames) do
		local option = nil

		if i < subConfigIndex then
			option = self:processStoreItemSubConfigurationOption(storeItem, configName, vehicle)
		else
			local items = storeItem.configurations[configName]
			option = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle)
		end

		table.insert(options, option)
	end

	return options
end

function ShopConfigScreen:processStoreItemSubConfigurationOption(storeItem, configName, vehicle)
	local subConfig = storeItem.subConfigurations[configName]
	local texts = {}
	local subConfigOptions = {}
	local subConfigSelection = {
		selectedIndex = 1,
		isSubConfiguration = true,
		name = configName,
		title = self.configurationManager:getConfigurationDescByName(configName).subConfigurationTitle,
		texts = texts,
		subConfigOptions = subConfigOptions
	}
	local initialIndex = 1

	if vehicle ~= nil then
		initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, vehicle.configurations[configName])
	end

	subConfigSelection.selectedIndex = initialIndex
	self.subConfigurations[configName] = initialIndex

	for i, name in pairs(subConfig.subConfigValues) do
		table.insert(subConfigSelection.texts, name)

		local items = StoreItemUtil.getSubConfigurationItems(storeItem, configName, i)
		local subConfigOption = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, true)

		table.insert(subConfigSelection.subConfigOptions, subConfigOption)
	end

	return subConfigSelection
end

function ShopConfigScreen:processStoreItemConfigurationOption(storeItem, configName, configItems, vehicle, isSubConfigOption)
	local configOption = {
		defaultIndex = 1,
		name = configName,
		title = self.configurationManager:getConfigurationAttribute(configName, "title"),
		texts = {},
		options = {}
	}
	local initialIndex = 1
	local overwrittenTitle = nil

	for i, item in ipairs(configItems) do
		if item.isDefault then
			initialIndex = i
			configOption.defaultIndex = i
		end

		overwrittenTitle = overwrittenTitle or item.overwrittenTitle

		table.insert(configOption.texts, item.name)
		table.insert(configOption.options, item)
	end

	if vehicle ~= nil then
		local vehicleConfigIndex = vehicle.configurations[configName]

		for i, item in ipairs(configItems) do
			if item.index == vehicleConfigIndex then
				initialIndex = i

				break
			end
		end
	end

	configOption.defaultIndex = initialIndex
	configOption.title = overwrittenTitle or configOption.title

	return configOption
end

function ShopConfigScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex, vehicle)
	local defaultColorIndex = self:getDefaultConfigurationColorIndex(configName, colorItems, vehicle)
	local visibility = true

	for _, configSet in ipairs(storeItem.configurationSets) do
		for name, _ in pairs(configSet.configurations) do
			if name == configName then
				visibility = false
			end
		end
	end

	local element = self.colorPicker[colorPickerIndex]

	element:setVisible(visibility)

	function element.onClickCallback(sourceElement)
		local defaultColor = colorItems[self.configurations[configName]]

		self.inputManager:setShowMouseCursor(true)
		g_gui:showColorPickerDialog({
			colors = colorItems,
			defaultColor = defaultColor.color,
			callback = self.onPickColor,
			target = self,
			args = {
				configName = configName,
				colorOptionIndex = colorPickerIndex
			}
		})
	end

	self.colorImage[colorPickerIndex]:setVisible(true)

	local colorNameText = self.configurationManager:getConfigurationAttribute(configName, "title")

	self.colorName[colorPickerIndex]:setText(colorNameText)
	self:onPickColor(defaultColorIndex, {
		configName = configName,
		colorOptionIndex = colorPickerIndex
	}, true)
end

function ShopConfigScreen:processStoreItemConfigurations(storeItem, vehicle)
	self.configSelection = {
		title = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
		texts = {},
		prices = {},
		options = {}
	}
	self.currentConfigSet = 1
	local configSets = storeItem.configurationSets

	if #storeItem.configurationSets == 0 then
		local defaultSet = {
			name = "",
			isDefault = true,
			configurations = {}
		}
		configSets = {
			defaultSet
		}
	end

	if storeItem.configurations ~= nil then
		for i, configSet in ipairs(configSets) do
			if configSet.isDefault then
				self.currentConfigSet = i
			end

			if configSet.overwrittenTitle ~= nil then
				self.configSelection.title = configSet.overwrittenTitle
			end

			local price = 0

			for name, index in pairs(configSet.configurations) do
				if self.vehicle == nil or not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, index) then
					price = price + storeItem.configurations[name][index].price
				end
			end

			table.insert(self.configSelection.prices, price)
			table.insert(self.configSelection.texts, configSet.name)

			local setOptions = self:processStoreItemConfigurationSet(storeItem, configSet, vehicle)

			table.insert(self.configSelection.options, setOptions)
		end

		for name, index in pairs(configSets[self.currentConfigSet].configurations) do
			self.configurations[name] = index
		end

		local colorPickerIndex = 1

		for configName, configItems in pairs(storeItem.configurations) do
			local isColor = self.configurationManager:getConfigurationAttribute(configName, "selectorType") == ConfigurationUtil.SELECTOR_COLOR

			if #configItems > 1 and isColor then
				self:processStoreItemColorOption(storeItem, configName, configItems, colorPickerIndex, vehicle)

				colorPickerIndex = colorPickerIndex + 1

				if colorPickerIndex > #self.colorPicker then
					break
				end
			end
		end

		self.displayableColorCount = colorPickerIndex - 1
	else
		table.insert(self.configSelection.options, {})

		self.displayableColorCount = 0
	end
end

function ShopConfigScreen:updateConfigSetOptionElement(configElementIndex, storeItem, vehicle)
	local optionElement = self.configOption[configElementIndex]

	optionElement:setDisabled(false)
	optionElement:setTexts(self.configSelection.texts)
	optionElement:setState(self.currentConfigSet)
	FocusManager:loadElementFromCustomValues(optionElement)

	function optionElement:onClickCallback(configSetIndex)
		for name, index in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[name] = 1
		end

		for name, index in pairs(storeItem.configurationSets[configSetIndex].configurations) do
			self.configurations[name] = index
		end

		self.currentConfigSet = configSetIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateDisplay(storeItem, vehicle, self.configSlider:getMinValue())
		self:selectFirstConfig()
	end

	self.configName[configElementIndex]:setText(self.configSelection.title)

	local price = self.configSelection.prices[self.currentConfigSet]

	self.configPrice[configElementIndex]:setText("+" .. self.l10n:formatMoney(price))
end

function ShopConfigScreen:updateConfigOptionElement(configElementIndex, option, storeItem, vehicle)
	local optionElement = self.configOption[configElementIndex]

	optionElement:setDisabled(#option.options <= 1)
	optionElement:setTexts(option.texts)
	FocusManager:loadElementFromCustomValues(optionElement)

	local configName = option.name
	local configIndex = 0

	for i, item in pairs(option.options) do
		if item.index == self.configurations[configName] then
			configIndex = i

			break
		end
	end

	if configIndex == 0 or option.options[configIndex] == nil then
		configIndex = option.defaultIndex
	end

	optionElement:setState(configIndex)

	self.configurations[configName] = option.options[configIndex].index
	optionElement.shouldFocusChange = ShopConfigScreen.shouldFocusChange

	function optionElement:onClickCallback(optionIndex)
		local configIndex = option.options[optionIndex].index

		self:setConfigPrice(configName, configIndex, self.configPrice[configElementIndex], vehicle)

		self.configurations[configName] = configIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateData(storeItem, self.vehicle)
	end

	self.configName[configElementIndex]:setText(option.title)
	self:setConfigPrice(configName, option.options[configIndex].index, self.configPrice[configElementIndex], vehicle)
end

function ShopConfigScreen:updateSubConfigOptionElement(configElementIndex, option, storeItem, vehicle)
	local optionElement = self.configOption[configElementIndex]

	optionElement:setDisabled(false)
	optionElement:setTexts(option.texts)

	local configName = option.name
	local subConfigIndex = self.subConfigurations[configName] or option.defaultIndex
	self.subConfigurations[configName] = subConfigIndex
	option.selectedIndex = subConfigIndex

	optionElement:setState(subConfigIndex)

	optionElement.shouldFocusChange = ShopConfigScreen.shouldFocusChange

	function optionElement:onClickCallback(state)
		self.subConfigurations[configName] = state
		option.selectedIndex = state
		local subConfigOptionIndex = option.subConfigOptions[state].defaultIndex
		self.configurations[configName] = subConfigOptionIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateConfigOptionsDisplay(self.configSlider:getValue(), storeItem, vehicle)
		self:updateData(storeItem, self.vehicle)
		FocusManager:unsetFocus(optionElement)
		FocusManager:setFocus(optionElement)
	end

	self.configPrice[configElementIndex]:setVisible(false)
	self.configName[configElementIndex]:setText(option.title)
end

function ShopConfigScreen:updateConfigOptionsData(scrollValue, storeItem, vehicle)
	local displayableOptionCount = 0
	local optionElementCount = #self.configOption
	local configIndex = math.floor(scrollValue * optionElementCount / 2) - 1
	local visitedCount = 0
	local filledCount = 0

	if #self.configSelection.options > 1 then
		displayableOptionCount = displayableOptionCount + 1
		visitedCount = 1

		if configIndex == 1 then
			filledCount = 1

			self:updateConfigSetOptionElement(1, storeItem, vehicle)
		end
	end

	local optionData = self.configSelection.options[self.currentConfigSet]

	for _, option in ipairs(optionData) do
		displayableOptionCount = displayableOptionCount + 1
		visitedCount = visitedCount + 1

		if configIndex <= visitedCount and filledCount < optionElementCount then
			filledCount = filledCount + 1

			if option.isSubConfiguration then
				self:updateSubConfigOptionElement(filledCount, option, storeItem, vehicle)
			else
				self:updateConfigOptionElement(filledCount, option, storeItem, vehicle)
			end
		end

		if option.isSubConfiguration then
			displayableOptionCount = displayableOptionCount + 1
			visitedCount = visitedCount + 1

			if configIndex <= visitedCount and filledCount < optionElementCount then
				filledCount = filledCount + 1
				local subOption = option.subConfigOptions[option.selectedIndex]

				self:updateConfigOptionElement(filledCount, subOption, storeItem, vehicle)
			end
		end
	end

	self.displayableOptionCount = displayableOptionCount

	return filledCount
end

function ShopConfigScreen:updateConfigOptionsNavigation(scrollValue, usedConfigElementCount, usedColorElementCount)
	local firstEnabledIndex = 0
	local lastEnabledIndex = 0

	for i, optionElement in ipairs(self.configOption) do
		if not optionElement:getIsDisabled() then
			if firstEnabledIndex < 1 then
				firstEnabledIndex = i
			end

			lastEnabledIndex = i
		end
	end

	for i, optionElement in ipairs(self.configOption) do
		optionElement.focusChangeOverride = nil

		if not optionElement:getIsDisabled() and usedConfigElementCount > 0 and self.displayableOptionCount > 1 then
			local isFirst = i == firstEnabledIndex
			local isLast = i == lastEnabledIndex

			self:overrideOptionFocus(optionElement, i, scrollValue, usedConfigElementCount, usedColorElementCount, isFirst, isLast)
		end
	end
end

function ShopConfigScreen:updateConfigOptionsDisplay(scrollValue, storeItem, vehicle)
	for i = 1, #self.configPrice do
		self.configPrice[i]:setVisible(true)
	end

	local numUsedConfigElements = self:updateConfigOptionsData(scrollValue, storeItem, vehicle)

	self:disableUnusedOptions(numUsedConfigElements + 1, self.displayableColorCount + 1)
	self:updateSlider()
	self:updateConfigOptionsNavigation(scrollValue, numUsedConfigElements, self.displayableColorCount)
end

function ShopConfigScreen:update(dt)
	ShopConfigScreen:superClass().update(self, dt)

	if self.vehicle ~= nil and self.vehicle.isDeleted then
		g_gui:showGui("")

		self.vehicle = nil

		return
	end

	if not self.fadeInAnimation:getFinished() then
		self.fadeInAnimation:update(dt)
	end

	if not self.fadeOutAnimation:getFinished() then
		self.fadeOutAnimation:update()
	end

	if self.lastMoney ~= self.currentMission:getMoney() then
		self:updateBalanceText()
	end

	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:update(dt)
		vehicle:updateTick(dt)
	end

	self.shopController:update(dt)
	self:updateInput(dt)
	self:updateCamera(dt)
end

function ShopConfigScreen:updateCamera(dt)
	local screenOffX = ShopConfigScreen.CAMERA_MIN_DISTANCE_TO_X_OFFSET_FACTOR * g_screenAspectRatio
	local offDist = self.previewVehicleSize * screenOffX * self.cameraDistance / self.cameraMinDistance
	local offX = math.cos(self.rotY) * offDist
	local offZ = -math.sin(self.rotY) * offDist

	setTranslation(self.rotateNode, self.workshopWorldPosition[1] + offX, self.workshopWorldPosition[2] + self.focusY, self.workshopWorldPosition[3] + offZ)
	setRotation(self.rotateNode, self.rotX, self.rotY, 0)

	local camPosX, camPosY, camPosZ = getWorldTranslation(self.cameraNode)
	local targetPosX, targetPosY, targetPosZ = getWorldTranslation(self.rotateNode)
	local dx, dy, dz = MathUtil.vector3Normalize(targetPosX - camPosX, targetPosY - camPosY, targetPosZ - camPosZ)
	local posX = targetPosX - dx * self.cameraDistance
	local posY = targetPosY - dy * self.cameraDistance
	local posZ = targetPosZ - dz * self.cameraDistance
	local lx, ly, lz = worldToLocal(self.rotateNode, posX, posY, posZ)

	setTranslation(self.cameraNode, lx, ly, lz)
	self:updateDepthOfField()
end

function ShopConfigScreen:updateDepthOfField()
	local focusRadius = self.previewVehicleSize * 0.6
	local nearBlurEndDist = math.max(ShopConfigScreen.NEAR_CLIP_DISTANCE, self.cameraDistance - focusRadius)
	local farBlurStartDist = self.cameraDistance + focusRadius * 2
	local farCoCRadius = self.cameraMinDistance * 1.5 / self.cameraDistance

	g_depthOfFieldManager:setManipulatedParams(nil, nearBlurEndDist, farCoCRadius, farBlurStartDist, nil)
end

function ShopConfigScreen:draw()
	ShopConfigScreen:superClass().draw(self)

	if self.fadeOverlay.visible then
		self.fadeOverlay:render()
	end

	if self.shopConfigContent:getIsVisible() then
		self.zoomInputGlyph:draw()
		self.rotateInputGlyph:draw()
	end
end

function ShopConfigScreen:onOpen(element)
	ShopConfigScreen:superClass().onOpen(self)
	g_depthOfFieldManager:reset()
	setSceneBrightness(getBrightness())
	self:updateBalanceText()
	g_gameStateManager:setGameState(GameState.MENU_SHOP_CONFIG)
	self.currentMission.environment:setCustomLighting(self.shopLighting)
	setVisibility(self.workshopRootNode, true)

	self.previousCamera = getCamera()

	setCamera(self.cameraNode)
	link(self.workshopRootNode, self.workshopNode)
	self:updateInputGlyphs()
	self:toggleCustomInputContext(true, ShopConfigScreen.INPUT_CONTEXT_NAME)
	self:registerInputActions()
	self:selectFirstConfig()
end

function ShopConfigScreen:onClose()
	self.isLoadingInitial = false

	ShopConfigScreen:superClass().onClose(self)
	self.currentMission.environment:setCustomLighting(nil)
	setCamera(self.previousCamera)
	unlink(self.workshopNode)
	setVisibility(self.workshopRootNode, false)
	self:deletePreviewVehicles()
	g_currentMission:resetGameState()
	self.fadeInAnimation:reset()
	g_depthOfFieldManager:reset()
	self:toggleCustomInputContext(false)
end

function ShopConfigScreen:onClickOk()
	local _, _, hasChanges = self:getConfigurationCostsAndChanges(self.storeItem, self.vehicle)

	if not hasChanges then
		return
	end

	local enoughMoney = true

	if self.totalPrice > 0 then
		enoughMoney = self.totalPrice <= self.currentMission:getMoney()
	end

	local enoughSlots = self.currentMission:hasEnoughSlots(self.storeItem)

	self.inputManager:setShowMouseCursor(true)

	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
		})
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
		})
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

		local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), self.l10n:formatMoney(self.totalPrice, 0, true, true))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoBuy,
			target = self
		})
	end
end

function ShopConfigScreen:onClickCancel()
	if self.focusedColorElement ~= nil then
		self.focusedColorElement:onFocusActivate()
	end
end

function ShopConfigScreen:onFocusColorButton(element)
	self.focusedColorElement = element

	self:updateColorButton()
end

function ShopConfigScreen:onLeaveColorButton(element)
	self.focusedColorElement = nil

	self:updateColorButton()
end

function ShopConfigScreen:updateColorButton()
	self.changeColorButton:setVisible(self.focusedColorElement ~= nil)
	self.buttonsPC:invalidateLayout()
end

function ShopConfigScreen:onYesNoBuy(yes)
	if yes then
		self:onCallback(false, self.storeItem, self.configurations, self.totalPrice)
	end
end

function ShopConfigScreen:onVehicleBought()
	if not GS_IS_CONSOLE_VERSION then
		FocusManager:setFocus(self.buyButton)
	else
		self:selectFirstConfig()
	end
end

function ShopConfigScreen:onClickActivate()
	if self.vehicle ~= nil then
		return
	end

	if not self.storeItem.allowLeasing then
		return
	end

	local enoughMoney = self.initialLeasingCosts <= self.currentMission:getMoney()
	local enoughSlots = self.currentMission:hasEnoughSlots(self.storeItem)

	self.inputManager:setShowMouseCursor(true)

	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_LEASE)
		})
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
		})
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

		local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_LEASE), self.l10n:formatMoney(self.initialLeasingCosts, 0, true, false))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoLease,
			target = self
		})
	end
end

function ShopConfigScreen:onYesNoLease(yes)
	if yes then
		self:onCallback(true, self.storeItem, self.configurations)
	end
end

function ShopConfigScreen:onClickShop()
	local eventUnused = ShopConfigScreen:superClass().onClickShop(self)

	if eventUnused then
		self:requestExitCallback()

		eventUnused = false
	end

	return eventUnused
end

function ShopConfigScreen:onCallback(leaseItem, storeItem, configurations, price)
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, self.vehicle, leaseItem, storeItem, configurations, price)
		else
			self.callbackFunc(self.vehicle, leaseItem, storeItem, configurations, price)
		end

		self.configurations = ListUtil.copyTable(self.configurations)
	end
end

function ShopConfigScreen:updateInputGlyphs()
	local zoomFrameWidth, zoomFrameHeight = unpack(self.zoomInputGlyphFrame.size)

	self.zoomInputGlyph:setDimension(zoomFrameWidth, zoomFrameHeight)

	local rotateFrameWidth, rotateFrameHeight = unpack(self.rotateInputGlyphFrame.size)

	self.rotateInputGlyph:setDimension(rotateFrameWidth, rotateFrameHeight)
	self.zoomInputGlyph:setActions({
		InputAction.CAMERA_ZOOM_IN,
		InputAction.CAMERA_ZOOM_OUT
	}, nil, , false, true)

	local platformActions = nil

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE,
			InputAction.AXIS_LOOK_UPDOWN_VEHICLE
		}
	else
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_DRAG,
			InputAction.AXIS_LOOK_UPDOWN_DRAG
		}
	end

	self.rotateInputGlyph:setActions(platformActions, nil, , false, true)

	local posX, posY = unpack(self.zoomInputGlyphFrame.absPosition)
	posX = posX + zoomFrameWidth - self.zoomInputGlyph:getWidth()
	posY = posY + (zoomFrameHeight - self.zoomInputGlyph:getHeight()) * 0.5

	self.zoomInputGlyph:setPosition(posX, posY)

	posX, posY = unpack(self.rotateInputGlyphFrame.absPosition)
	posX = posX + rotateFrameWidth - self.rotateInputGlyph:getWidth()
	posY = posY + (rotateFrameHeight - self.rotateInputGlyph:getHeight()) * 0.5

	self.rotateInputGlyph:setPosition(posX, posY)
end

function ShopConfigScreen:toggleHUDVisible()
	self.shopConfigContent:setVisible(not self.shopConfigContent:getIsVisible())
end

function ShopConfigScreen:registerInputActions()
	local isController = self.inputManager:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD
	_, self.eventIdUpDownController = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onCameraUpDown, false, false, true, isController)
	_, self.eventIdLeftRightController = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, isController)

	self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_IN, self, self.onCameraZoom, false, false, true, true, -1)
	self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_OUT, self, self.onCameraZoom, false, false, true, true, 1)

	_, self.eventIdUpDownMouse = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_DRAG, self, self.onCameraUpDown, false, false, true, not isController)
	_, self.eventIdLeftRightMouse = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, self, self.onCameraLeftRight, false, false, true, not isController)

	self:disableAlternateBindings()
end

function ShopConfigScreen:disableAlternateBindings()
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_UP_DOWN)
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function ShopConfigScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE then
		self.inputHorizontal = inputValue * -1
	elseif not self.configSlider.mouseDown and not self.configSliderBox.mouseDown then
		local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue * g_screenAspectRatio)

		if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
			self.inputDragging = true
			self.inputHorizontal = dragValue
		else
			self.inputHorizontal = 0
		end
	end
end

function ShopConfigScreen:onCameraUpDown(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_UPDOWN_VEHICLE then
		self.inputVertical = inputValue
	elseif not self.configSlider.mouseDown and not self.configSliderBox.mouseDown then
		local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue)

		if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
			self.inputDragging = true
			self.inputVertical = dragValue
		else
			self.inputVertical = 0
		end
	end
end

function ShopConfigScreen:onCameraZoom(actionName, inputValue, direction, isAnalog, isMouse)
	if isMouse and (self.configSlider:getIsVisible() or self.configSliderBox:getIsVisible()) then
		local mouseX, mouseY = self.inputManager:getMousePosition()
		local cursorOnSlider = GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configSlider.absPosition[1], self.configSlider.absPosition[2], self.configSlider.size[1], self.configSlider.size[2])
		cursorOnSlider = cursorOnSlider or GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configSliderBox.absPosition[1], self.configSliderBox.absPosition[2], self.configSliderBox.size[1], self.configSliderBox.size[2])

		if cursorOnSlider then
			return
		end
	end

	local modifier = 0.01

	if not isAnalog then
		modifier = 0.2 * direction

		if isMouse then
			modifier = modifier * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
	end

	self.inputZoom = self.inputZoom + inputValue * modifier
end

function ShopConfigScreen:updateInput(dt)
	self:updateInputContext()

	if self.inputVertical ~= 0 then
		local value = self.inputVertical
		self.inputVertical = 0
		local rotSpeed = 0.001 * dt

		if self.limitRotXDelta > 0.001 then
			self.rotX = math.min(self.rotX - rotSpeed * value, self.rotX)
		elseif self.limitRotXDelta < -0.001 then
			self.rotX = math.max(self.rotX - rotSpeed * value, self.rotX)
		else
			self.rotX = self.rotX - rotSpeed * value
		end
	end

	if self.inputHorizontal ~= 0 then
		local value = self.inputHorizontal
		self.inputHorizontal = 0
		local rotSpeed = 0.001 * dt
		self.rotY = self.rotY - rotSpeed * value
	end

	if self.inputZoom ~= 0 then
		self.zoomTarget = self.zoomTarget + dt * self.inputZoom * 0.1
		self.zoomTarget = MathUtil.clamp(self.zoomTarget, self.cameraMinDistance, self.cameraMaxDistance)
		self.inputZoom = 0
	end

	self.cameraDistance = self.zoomTarget + math.pow(0.99579, dt) * (self.cameraDistance - self.zoomTarget)
	self.rotX = self:limitXRotation(self.rotX)
	local inputHelpMode = self.inputManager:getInputHelpMode()

	if inputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = inputHelpMode

		self:updateInputGlyphs()
	end

	if not self.isDragging and self.inputDragging then
		self.isDragging = true

		self.inputManager:setShowMouseCursor(false, true)

		for _, optionElement in pairs(self.configOption) do
			optionElement:setForceHighlight(true)
		end
	elseif self.isDragging and not self.inputDragging then
		self.isDragging = false

		self.inputManager:setShowMouseCursor(true)

		self.accumDraggingInput = 0

		for _, optionElement in pairs(self.configOption) do
			optionElement:setForceHighlight(false)
		end
	end

	self.inputDragging = false
end

function ShopConfigScreen:limitXRotation(currentXRotation)
	local camHeight = self.cameraDistance * math.sin(self.rotX) + self.focusY
	local maxHeight = math.min(camHeight, ShopConfigScreen.MAX_CAMERA_HEIGHT - self.focusY)
	local limitedRotX = self.rotMaxX

	if maxHeight <= self.cameraDistance then
		limitedRotX = math.min(self.rotMaxX, math.asin(maxHeight / self.cameraDistance))
	end

	return math.max(self.rotMinX, math.min(limitedRotX, self.rotX))
end

function ShopConfigScreen:updateInputContext()
	local currentInputMode = self.inputManager:getLastInputMode()

	if currentInputMode ~= self.lastInputMode then
		local isController = currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD

		self.inputManager:setActionEventActive(self.eventIdUpDownController, isController)
		self.inputManager:setActionEventActive(self.eventIdLeftRightController, isController)
		self.inputManager:setActionEventActive(self.eventIdUpDownMouse, not isController)
		self.inputManager:setActionEventActive(self.eventIdLeftRightMouse, not isController)

		self.lastInputMode = currentInputMode
		self.isDragging = false

		self.inputManager:setShowMouseCursor(true)
		self:disableAlternateBindings()
	end
end

function ShopConfigScreen:makeOptionFocusOverrideTopScrolling(scrollValue, element)
	return function (_, direction)
		if direction == FocusManager.TOP then
			local foundPrevious = false
			local prevElement = self.configOption[2]

			while not foundPrevious and self.configSlider:getValue() > 1 do
				self.configSlider:setValue(scrollValue - 1)
				self.configSliderBox:setValue(scrollValue - 1, true)

				prevElement = self.configOption[2]

				if prevElement:getIsDisabled() then
					prevElement = self.configOption[1]
				end

				foundPrevious = not prevElement:getIsDisabled()
			end

			FocusManager:unsetFocus(prevElement)

			return true, prevElement
		else
			return false, nil
		end
	end
end

function ShopConfigScreen:makeOptionFocusOverrideTopNoScrolling(numVisibleConfigs, numColors, element)
	return function (_, direction)
		if direction == FocusManager.TOP then
			if numColors == 0 then
				self.configSlider:setValue(self.configSlider:getMaxValue())
				self.configSliderBox:setValue(self.configSliderBox:getMaxValue(), true)

				local lastElementIndex = #self.configOption

				while lastElementIndex > 0 and self.configOption[lastElementIndex]:getIsDisabled() do
					lastElementIndex = lastElementIndex - 1
				end

				local lastElement = self.configOption[lastElementIndex]

				FocusManager:unsetFocus(lastElement)

				return true, lastElement
			else
				return true, self.colorPicker[numColors]
			end
		else
			return false, nil
		end
	end
end

function ShopConfigScreen:makeOptionFocusOverrideBottomScrolling(scrollValue, element)
	return function (_, direction)
		if direction == FocusManager.BOTTOM then
			local foundNext = false
			local nextElement = self.configOption[3]

			while not foundNext and self.configSlider:getValue() < self.configSlider:getMaxValue() do
				self.configSlider:setValue(scrollValue + 1)
				self.configSliderBox:setValue(scrollValue + 1, true)

				nextElement = self.configOption[3]

				if nextElement:getIsDisabled() then
					nextElement = self.configOption[4]
				end

				foundNext = not nextElement:getIsDisabled()
			end

			FocusManager:unsetFocus(nextElement)

			return true, nextElement
		else
			return false, nil
		end
	end
end

function ShopConfigScreen:makeOptionFocusOverrideBottomNoScrolling(numColors, element)
	return function (_, direction)
		if direction == FocusManager.BOTTOM then
			if numColors == 0 then
				self.configSlider:setValue(self.configSlider:getMinValue())
				self.configSliderBox:setValue(self.configSliderBox:getMinValue(), true)

				local firstElement = self.configOption[1]

				FocusManager:unsetFocus(firstElement)

				return true, firstElement
			else
				return true, self.colorPicker[1]
			end
		else
			return false, nil
		end
	end
end

ShopConfigScreen.GUI_PROFILE = {
	POWER = "shopListAttributeIconPower",
	MAINTENANCE_COST = "shopListAttributeIconMaintenanceCosts",
	SHOP_MONEY = "shopMoney",
	BUTTON_BUY = "buttonBuy",
	MAX_SPEED = "shopListAttributeIconMaxSpeed",
	CAPACITY = "shopListAttributeIconCapacity",
	POWER_REQUIREMENT = "shopListAttributeIconPowerReq",
	WORKING_WIDTH = "shopListAttributeIconWorkingWidth",
	WORKING_SPEED = "shopListAttributeIconWorkSpeed",
	FUEL = "shopListAttributeIconFuel",
	SHOP_MONEY_NEGATIVE = "shopMoneyNeg",
	BUTTON_CONFIGURE = "buttonConfigurate"
}
ShopConfigScreen.L10N_SYMBOL = {
	UNIT_LITER = "unit_literShort",
	BUTTON_BUY = "button_buy",
	MAINTENANCE_COST = "shop_maintenanceValue",
	CONFIRM_LEASE = "shop_doYouWantToLease",
	CONFIGURATION_LABEL = "shop_configuration",
	CAPACITY = "shop_capacityValue",
	POWER_REQUIREMENT = "shop_neededPowerValue",
	WORKING_WIDTH = "shop_workingWidthValue",
	NOT_ENOUGH_MONEY_BUY = "shop_messageNotEnoughMoneyToBuy",
	CONFIRM_BUY = "shop_doYouWantToBuy",
	NOT_ENOUGH_MONEY_LEASE = "shop_messageNotEnoughMoneyToLease",
	BUTTON_CONFIGURE = "button_configurate",
	FUEL_DEF = "shop_fuelDefValue",
	MAX_SPEED = "shop_maxSpeed",
	POWER = "shop_maxPowerValue",
	DEF_SHORT = "fillType_def_short",
	WORKING_SPEED = "shop_maxSpeed",
	FUEL = "shop_fuelValue",
	TOO_FEW_SLOTS = "shop_messageNotEnoughSlotsToBuy"
}
ShopConfigScreen.SIZE = {
	INPUT_GLYPH = {
		48,
		48
	}
}
