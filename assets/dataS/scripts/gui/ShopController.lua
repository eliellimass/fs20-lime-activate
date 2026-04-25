ShopController = {}
local ShopController_mt = Class(ShopController)
ShopController.MAX_ATTRIBUTES_PER_ROW = 5
ShopController.COINS_CATEGORY = "COINS"

function ShopController:new(messageCenter, l10n, storeManager, brandManager, fillTypeManager, inAppPurchaseController)
	local self = setmetatable({}, ShopController_mt)
	self.l10n = l10n
	self.storeManager = storeManager
	self.brandManager = brandManager
	self.fillTypeManager = fillTypeManager
	self.inAppPurchaseController = inAppPurchaseController
	self.client = nil
	self.currentMission = nil
	self.playerFarm = nil
	self.isInitialized = false
	self.isBuying = false
	self.isSelling = false
	self.buyVehicleNow = 0
	self.buyObjectNow = 0
	self.buyHandToolNow = 0
	self.displayBrands = {}
	self.displayVehicleCategories = {}
	self.displayToolCategories = {}
	self.displayObjectCategories = {}
	self.displayPlaceableCategories = {}
	self.ownedFarmItems = {}
	self.leasedFarmItems = {}
	self.currentSellStoreItem = nil
	self.currentSellItem = nil
	self.buyItemFilename = nil
	self.buyItemPrice = 0
	self.buyItemIsOutsideBuy = false
	self.buyItemConfigurations = nil
	self.buyItemIsLeasing = false
	self.updateShopItemsCallback = nil
	self.updateAllItemsCallback = nil
	self.switchToConfigurationCallback = nil
	self.startPlacementModeCallback = nil

	self:subscribeEvents(messageCenter)

	return self
end

function ShopController:reset()
	self.isInitialized = false
	self.displayBrands = {}
	self.displayVehicleCategories = {}
	self.displayToolCategories = {}
	self.displayObjectCategories = {}
	self.displayPlaceableCategories = {}
	self.ownedFarmItems = {}
	self.leasedFarmItems = {}
	self.isBuying = false
	self.isSelling = false
end

function ShopController:subscribeEvents(messageCenter)
	messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
	messageCenter:subscribe(BuyObjectEvent, self.onObjectBuyEvent, self)
	messageCenter:subscribe(BuyHandToolEvent, self.onHandToolBuyEvent, self)
	messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableSellEvent, self)
	messageCenter:subscribe(SellHandToolEvent, self.onHandToolSellEvent, self)
end

function ShopController:addBrandForDisplay(brand)
	table.insert(self.displayBrands, {
		id = brand.index,
		iconFilename = brand.imageShopOverview,
		label = brand.title,
		sortValue = brand.name
	})
end

function ShopController:addCategoryForDisplay(category)
	local categories = nil

	if category.type == StoreManager.CATEGORY_TYPE.VEHICLE then
		categories = self.displayVehicleCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.TOOL then
		categories = self.displayToolCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.OBJECT then
		categories = self.displayObjectCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.PLACEABLE then
		categories = self.displayPlaceableCategories
	end

	if categories ~= nil then
		table.insert(categories, {
			id = category.name,
			iconFilename = category.image,
			label = category.title,
			sortValue = category.orderId
		})
	end
end

function ShopController:load()
	if not self.isInitialized then
		local foundBrands = {}
		local foundCategory = {}

		for _, storeItem in ipairs(self.storeManager:getItems()) do
			if storeItem.categoryName ~= "" and storeItem.showInStore then
				local brand = self.brandManager:getBrandByIndex(storeItem.brandIndex)

				if brand ~= nil and not foundBrands[storeItem.brandIndex] then
					foundBrands[storeItem.brandIndex] = true

					self:addBrandForDisplay(brand)
				end

				local category = self.storeManager:getCategoryByName(storeItem.categoryName)

				if category ~= nil and not foundCategory[storeItem.categoryName] then
					foundCategory[storeItem.categoryName] = true

					self:addCategoryForDisplay(category)
				end
			end
		end

		if (GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_IOS or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID and g_buildTypeParam ~= "CHINA_GAPP" and g_buildTypeParam ~= "CHINA") and not GS_IS_APPLE_ARCADE_VERSION then
			self:addCategoryForDisplay(self.storeManager:getCategoryByName(ShopController.COINS_CATEGORY))
		end

		table.sort(self.displayBrands, ShopController.brandSortFunction)
		table.sort(self.displayToolCategories, ShopController.categorySortFunction)
		table.sort(self.displayObjectCategories, ShopController.categorySortFunction)
		table.sort(self.displayPlaceableCategories, ShopController.categorySortFunction)
		table.sort(self.displayVehicleCategories, ShopController.categorySortFunction)

		self.isInitialized = true
	end
end

function ShopController:setClient(client)
	self.client = client
end

function ShopController:setCurrentMission(currentMission)
	self.currentMission = currentMission

	self.inAppPurchaseController:setMission(currentMission)
end

function ShopController:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
	self.playerFarmId = playerFarm.farmId
end

function ShopController:setUpdateShopItemsCallback(callback, target)
	function self.updateShopItemsCallback()
		callback(target)
	end
end

function ShopController:setUpdateAllItemsCallback(callback, target)
	function self.updateAllItemsCallback()
		callback(target)
	end
end

function ShopController:setSwitchToConfigurationCallback(callback, target)
	function self.switchToConfigurationCallback(storeItem)
		callback(target, storeItem)
	end
end

function ShopController:setStartPlacementModeCallback(callback, target)
	function self.startPlacementModeCallback(storeItem, isSelling, sellItem)
		callback(target, storeItem, isSelling, sellItem)
	end
end

function ShopController.filterOwnedItemsByFarmId(ownedFarmItems, farmId)
	local filteredItems = {}

	for storeItem, itemInfos in pairs(ownedFarmItems) do
		for _, concreteItem in pairs(itemInfos.items) do
			if concreteItem:getOwnerFarmId() == farmId then
				local filteredItemInfos = filteredItems[storeItem]

				if filteredItemInfos == nil then
					filteredItemInfos = {}
					filteredItems[storeItem] = filteredItemInfos
					filteredItemInfos.storeItem = storeItem
					filteredItemInfos.numItems = 0
					filteredItemInfos.items = {}
				end

				filteredItemInfos.numItems = filteredItemInfos.numItems + 1
				filteredItemInfos.items[concreteItem] = concreteItem
			end
		end
	end

	return filteredItems
end

function ShopController:setOwnedFarmItems(ownedFarmItems, playerFarmId)
	self.ownedFarmItems = ShopController.filterOwnedItemsByFarmId(ownedFarmItems, playerFarmId)
end

function ShopController:setLeasedFarmItems(leasedFarmItems, playerFarmId)
	self.leasedFarmItems = ShopController.filterOwnedItemsByFarmId(leasedFarmItems, playerFarmId)
end

function ShopController:update(dt)
	if self.buyVehicleNow > 0 then
		if self.buyVehicleNow == 2 then
			self.buyVehicleNow = 0

			self.client:getServerConnection():sendEvent(BuyVehicleEvent:new(self.buyItemFilename, self.buyItemIsOutsideBuy, self.buyItemConfigurations, self.buyItemIsLeasing, self.playerFarmId))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyVehicleNow = self.buyVehicleNow + 1
		end
	end

	if self.buyObjectNow > 0 then
		if self.buyObjectNow == 2 then
			self.buyObjectNow = 0

			self.client:getServerConnection():sendEvent(BuyObjectEvent:new(self.buyItemFilename, self.buyItemIsOutsideBuy, self.playerFarmId))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyObjectNow = self.buyObjectNow + 1
		end
	end

	if self.buyHandToolNow > 0 then
		if self.buyHandToolNow == 2 then
			self.buyHandToolNow = 0

			self.client:getServerConnection():sendEvent(BuyHandToolEvent:new(self.buyItemFilename, self.playerFarmId))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyHandToolNow = self.buyHandToolNow + 1
		end
	end
end

local function addAttribute(profiles, values, profile, value)
	table.insert(profiles, profile)
	table.insert(values, value)
end

function ShopController:makeDisplayItem(storeItem, concreteItem)
	local attributeIconProfiles = {}
	local attributeValues = {}
	local fillTypeIconFilenames = {}
	local foodFillTypeIconFilenames = {}
	local seedTypeIconFilenames = {}
	local item = storeItem
	local realItem = concreteItem
	local values = {}
	local usedSpecs = {}
	local fillTypes = {}
	local foodFillTypes = {}
	usedSpecs.animalFoodFillTypes = true
	usedSpecs.fillTypes = true
	usedSpecs.seedFillTypes = true
	local seedFillTypes = nil

	local function addSpec(specName, specs, usedSpecs, storeItem, realItem)
		local desc = self.storeManager:getSpecTypeByName(specName)

		if desc ~= nil then
			local value = desc.getValueFunc(storeItem, realItem, realItem ~= nil)

			if value ~= nil then
				addAttribute(attributeIconProfiles, attributeValues, desc.profile, value)

				usedSpecs[specName] = true
			end
		end
	end

	if realItem == nil or realItem.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		addSpec("dailyUpkeep", values, usedSpecs, item, realItem)
	else
		usedSpecs.dailyUpkeep = true
	end

	if item.lifetime ~= 0 then
		addSpec("age", values, usedSpecs, item, realItem)
	end

	addSpec("operatingTime", values, usedSpecs, item, realItem)
	addSpec("power", values, usedSpecs, item, realItem)
	addSpec("fuel", values, usedSpecs, item, realItem)
	addSpec("maxSpeed", values, usedSpecs, item, realItem)
	addSpec("neededPower", values, usedSpecs, item, realItem)
	addSpec("incomePerHour", values, usedSpecs, item, realItem)
	addSpec("capacity", values, usedSpecs, item, realItem)

	if realItem == nil and g_currentMission ~= nil then
		if StoreItemUtil.getIsLeasable(item) then
			local numOwned = g_currentMission:getNumOwnedItems(item, g_currentMission:getFarmId())

			addAttribute(attributeIconProfiles, attributeValues, ShopController.PROFILE.ICON_OWNED, numOwned)

			if not GS_IS_MOBILE_VERSION then
				local numLeased = g_currentMission:getNumLeasedItems(item, g_currentMission:getFarmId())

				addAttribute(attributeIconProfiles, attributeValues, ShopController.PROFILE.ICON_LEASED, numLeased)
			end
		elseif not StoreItemUtil.getIsObject(item) then
			local numOwned = g_currentMission:getNumOfItems(item, self.playerFarmId)

			addAttribute(attributeIconProfiles, attributeValues, ShopController.PROFILE.ICON_OWNED, numOwned)
		end
	end

	if GS_IS_CONSOLE_VERSION then
		addSpec("slots", values, usedSpecs, item, realItem)
	else
		usedSpecs.slots = true
	end

	for _, specDesc in pairs(self.storeManager:getSpecTypes()) do
		if #values == 2 * ShopController.MAX_ATTRIBUTES_PER_ROW - 2 and item.specs.fillTypes ~= nil then
			break
		end

		if usedSpecs[specDesc.name] == nil then
			addSpec(specDesc.name, values, usedSpecs, item, realItem)
		end
	end

	local seedFillTypeSpec = self.storeManager:getSpecTypeByName("seedFillTypes")
	local fillTypesSpec = self.storeManager:getSpecTypeByName("fillTypes")
	local foodFillTypesSpec = self.storeManager:getSpecTypeByName("animalFoodFillTypes")

	if seedFillTypeSpec ~= nil then
		seedFillTypes = Utils.getNoNil(seedFillTypeSpec.getValueFunc(item, realItem), {})
	end

	if fillTypesSpec ~= nil then
		fillTypes = Utils.getNoNil(fillTypesSpec.getValueFunc(item, realItem), {})
	end

	if foodFillTypesSpec ~= nil then
		foodFillTypes = Utils.getNoNil(foodFillTypesSpec.getValueFunc(item, realItem), {})
	end

	if fillTypes ~= nil then
		for _, fillTypeIndex in pairs(fillTypes) do
			local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			if fillType ~= nil then
				table.insert(fillTypeIconFilenames, fillType.hudOverlayFilenameSmall)
			end
		end
	end

	if foodFillTypes ~= nil then
		for _, fillTypeIndex in pairs(foodFillTypes) do
			local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			if fillType ~= nil then
				table.insert(foodFillTypeIconFilenames, fillType.hudOverlayFilenameSmall)
			end
		end
	end

	if seedFillTypes ~= nil then
		for _, fillTypeIndex in pairs(seedFillTypes) do
			local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			if fillType ~= nil then
				table.insert(seedTypeIconFilenames, fillType.hudOverlayFilenameSmall)
			end
		end
	end

	local text = ""

	for _, item in pairs(item.functions) do
		text = text .. item .. " "
	end

	local category = self.storeManager:getCategoryByName(storeItem.categoryName)

	return ShopDisplayItem:new(storeItem, concreteItem, attributeIconProfiles, attributeValues, fillTypeIconFilenames, foodFillTypeIconFilenames, seedTypeIconFilenames, text, category.orderId)
end

function ShopController:updateDisplayItems(displayItems)
	local newDisplayItems = {}

	for _, oldDisplayItem in ipairs(displayItems) do
		local newDisplayItem = self:makeDisplayItem(oldDisplayItem.storeItem, nil)

		table.insert(newDisplayItems, newDisplayItem)
	end

	return newDisplayItems
end

function ShopController:getOwnedItems()
	local displayItems = {}

	for storeItem, itemInfos in pairs(self.ownedFarmItems) do
		for concreteItem in pairs(itemInfos.items) do
			if storeItem.canBeSold then
				local displayItem = self:makeDisplayItem(storeItem, concreteItem)

				table.insert(displayItems, displayItem)
			end
		end
	end

	local farmHandTools = self.playerFarm:getHandTools()

	for _, handToolFileName in ipairs(farmHandTools) do
		local handToolStoreItem = self.storeManager:getItemByXMLFilename(handToolFileName)

		if handToolStoreItem ~= nil then
			local displayItem = self:makeDisplayItem(handToolStoreItem)

			table.insert(displayItems, displayItem)
		end
	end

	table.sort(displayItems, ShopController.displayItemSortFunction)

	return displayItems
end

function ShopController:getLeasedVehicles()
	local displayItems = {}

	for storeItem, itemInfos in pairs(self.leasedFarmItems) do
		for concreteItem in pairs(itemInfos.items) do
			local displayItem = self:makeDisplayItem(storeItem, concreteItem)

			table.insert(displayItems, displayItem)
		end
	end

	table.sort(displayItems, ShopController.displayItemSortFunction)

	return displayItems
end

function ShopController:getOwnedFarmItems()
	return self.ownedFarmItems
end

function ShopController:getLeasedFarmItems()
	return self.leasedFarmItems
end

function ShopController:getBrands()
	return self.displayBrands
end

function ShopController:getVehicleCategories()
	return self.displayVehicleCategories
end

function ShopController:getToolCategories()
	return self.displayToolCategories
end

function ShopController:getObjectCategories()
	return self.displayObjectCategories
end

function ShopController:getPlaceableCategories()
	return self.displayPlaceableCategories
end

function ShopController:getItemsByBrand(brandId)
	local items = {}
	local salesCategory = self.storeManager:getCategoryByName("sales")
	local brand = self.brandManager:getBrandByIndex(brandId)

	for _, storeItem in pairs(self.storeManager:getItems()) do
		local sale = nil

		if g_currentMission ~= nil then
			_, _, sale = g_currentMission.economyManager:getBuyPrice(storeItem)
		end

		if not storeItem.isBundleItem and storeItem.showInStore and (storeItem.brandIndex == brandId or sale ~= nil and brand.title == salesCategory.title) then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getItemsByCategory(categoryName)
	if categoryName == ShopController.COINS_CATEGORY then
		return self:getCoinItems()
	end

	local items = {}

	for _, storeItem in pairs(self.storeManager:getItems()) do
		local sale = nil

		if g_currentMission ~= nil then
			_, _, sale = g_currentMission.economyManager:getBuyPrice(storeItem)
		end

		local salesCategory = self.storeManager:getCategoryByName("sales")

		if not storeItem.isBundleItem and storeItem.showInStore and (storeItem.categoryName == categoryName or categoryName == salesCategory.name and sale ~= nil) then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:canBeBought(storeItem, price)
	local enoughMoney = true

	if self.currentMission ~= nil then
		enoughMoney = price <= g_currentMission:getMoney()
	end

	local enoughSlots = self.currentMission:hasEnoughSlots(storeItem)

	if not enoughMoney then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
		})
	elseif not enoughSlots then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_SLOTS)
		})
	end

	local enoughItems = storeItem.maxItemCount == nil or storeItem.maxItemCount ~= nil and self.currentMission:getNumOfItems(storeItem, self.playerFarmId) < storeItem.maxItemCount

	if not enoughItems then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PLACEABLES)
		})
	end

	return enoughSlots and enoughMoney and enoughItems
end

function ShopController:buy(storeItem, outsideBuy)
	if self.isSelling then
		return
	end

	local price = 0

	if not outsideBuy then
		price = self.currentMission.economyManager:getBuyPrice(storeItem)
	end

	if StoreItemUtil.getIsVehicle(storeItem) then
		self:buyVehicle(storeItem, price, outsideBuy)
	elseif self:canBeBought(storeItem, price) then
		if StoreItemUtil.getIsPlaceable(storeItem) then
			self.startPlacementModeCallback(storeItem, false)
		elseif StoreItemUtil.getIsObject(storeItem) then
			self:buyObject(storeItem, price, outsideBuy)
		elseif StoreItemUtil.getIsHandTool(storeItem) then
			self:buyHandTool(storeItem, price, outsideBuy)
		end
	end
end

function ShopController:buyVehicle(vehicleStoreItem, price, outsideBuy)
	self.buyItemFilename = vehicleStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsOutsideBuy = outsideBuy or false
	self.buyItemConfigurations = nil
	self.buyItemIsLeasing = false

	if StoreItemUtil.getIsLeasable(vehicleStoreItem) and not GS_IS_MOBILE_VERSION then
		self.switchToConfigurationCallback(vehicleStoreItem)
	elseif self:canBeBought(vehicleStoreItem, price) then
		self:finalizeBuy()
	end
end

function ShopController:onYesNoBuyObject(yes)
	if yes then
		self.isBuying = true
		self.buyObjectNow = 1
	end
end

function ShopController:buyObject(objectStoreItem, price, outsideBuy)
	local text = string.format(self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), self.l10n:formatMoney(price, 0, true, true))

	g_gui:showYesNoDialog({
		text = text,
		callback = self.onYesNoBuyObject,
		target = self
	})

	self.buyItemFilename = objectStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsOutsideBuy = outsideBuy
	self.buyItemConfigurations = nil
	self.buyItemIsLeasing = false
end

function ShopController:onYesNoBuyHandtool(yes)
	if yes then
		self.isBuying = true
		self.buyHandToolNow = 1
	end
end

function ShopController:buyHandTool(handToolStoreItem, price, outsideBuy)
	if not self.playerFarm:hasHandtool(handToolStoreItem.xmlFilename) then
		local text = string.format(self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), self.l10n:formatMoney(price, 0, true, true))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoBuyHandtool,
			target = self
		})

		self.buyItemFilename = handToolStoreItem.xmlFilename
		self.buyItemPrice = price
		self.buyItemIsOutsideBuy = outsideBuy
		self.buyItemConfigurations = nil
		self.buyItemIsLeasing = false
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_ALREADY_OWNED)
		})
	end
end

function ShopController:sell(storeItem, concreteItem)
	if self.currentMission.tourIconsBase ~= nil and self.currentMission.tourIconsBase.visible then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.CANNOT_SELL_TOUR_ITEMS)
		})
		self.updateShopItemsCallback()

		return
	end

	self.isSelling = true
	self.currentSellStoreItem = storeItem
	self.currentSellItem = concreteItem

	if StoreItemUtil.getIsPlaceable(storeItem) then
		if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) == 1 then
			local canBeSold, warning = concreteItem:canBeSold()

			if warning ~= nil then
				if canBeSold then
					g_gui:showInfoDialog({
						text = warning,
						callback = self.sellPlaceableWarningInfoClickOk,
						target = self
					})
				else
					g_gui:showInfoDialog({
						text = warning
					})

					self.isSelling = false
				end
			else
				self:sellPlaceableWarningInfoClickOk()
			end
		elseif self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) > 1 then
			self:onSellCallback(true)
		end
	else
		local sellPrice = 0
		local sellItem = nil

		if concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
			sellPrice = self.currentMission.economyManager:getSellPrice(concreteItem)
			sellItem = concreteItem
		else
			sellPrice = self.currentMission.economyManager:getSellPrice(storeItem)
			sellItem = storeItem
		end

		g_gui:showSellItemDialog({
			item = concreteItem,
			price = sellPrice,
			storeItem = storeItem,
			callback = self.onSellCallback,
			target = self
		})
	end
end

function ShopController:sellPlaceableWarningInfoClickOk()
	g_gui:showSellItemDialog({
		item = self.currentSellItem,
		price = g_currentMission.economyManager:getSellPrice(self.currentSellItem),
		callback = self.onSellCallback,
		target = self
	})
end

function ShopController:onSellCallback(yes)
	self.isSelling = false

	if yes then
		self:onSellItem(self.currentSellStoreItem, self.currentSellItem)
	end
end

function ShopController:onSellItem(storeItem, concreteItem)
	if self.isSelling then
		return
	end

	if StoreItemUtil.getIsPlaceable(storeItem) then
		self:sellPlaceable(storeItem, concreteItem)
	elseif StoreItemUtil.getIsHandTool(storeItem) then
		self:sellHandTool(storeItem)
	else
		self:sellVehicle(concreteItem)
	end
end

function ShopController:sellPlaceable(placeableStoreItem, placeable)
	if self.currentMission:getNumOwnedItems(placeableStoreItem, g_currentMission:getFarmId()) == 1 then
		self.isSelling = true

		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})

		if NetworkUtil.getObjectId(placeable) ~= nil then
			self.client:getServerConnection():sendEvent(SellPlaceableEvent:new(placeable))
		else
			self:onPlaceableSellFailed()
		end
	elseif self.currentMission:getNumOwnedItems(placeableStoreItem, g_currentMission:getFarmId()) > 1 then
		self.startPlacementModeCallback(placeableStoreItem, true, placeable)
	end
end

function ShopController:sellHandTool(handToolStoreItem)
	self.soldItem = handToolStoreItem

	if self.playerFarm:hasHandtool(handToolStoreItem.xmlFilename) then
		self.isSelling = true

		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})
		self.client:getServerConnection():sendEvent(SellHandToolEvent:new(handToolStoreItem.xmlFilename, self.playerFarmId))
	else
		self:onHandToolSellFailed()
	end
end

function ShopController:sellVehicle(vehicle)
	self.soldItem = vehicle
	self.isSelling = true

	if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and vehicle == self.currentMission.controlledVehicle then
		self.currentMission:onLeaveVehicle()
	end

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})
	else
		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURNING_VEHICLE)
		})
	end

	if NetworkUtil.getObjectId(vehicle) ~= nil then
		self.client:getServerConnection():sendEvent(SellVehicleEvent:new(vehicle))
	else
		self:onVehicleSellFailed(vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED, SellVehicleEvent.SELL_NO_PERMISSION)
	end
end

function ShopController:setConfigurations(vehicle, leaseItem, storeItem, configs, configSetIndex)
	if configs ~= nil then
		local price, _, _ = self.currentMission.economyManager:getBuyPrice(storeItem, configs)
		self.buyItemFilename = storeItem.xmlFilename
		self.buyItemPrice = price
		self.buyItemConfigurations = configs
		self.buyItemIsLeasing = leaseItem

		self:finalizeBuy()
	end
end

function ShopController:finalizeBuy()
	self.isBuying = true
	self.buyVehicleNow = 1
	local text = self.l10n:getText(ShopController.L10N_SYMBOL.BUYING_VEHICLE)

	if self.buyItemIsLeasing then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.LEASING_VEHICLE)
	end

	g_gui:showMessageDialog({
		visible = true,
		text = text
	})
end

function ShopController:onHandToolSellEvent(errorCode)
	if errorCode == SellHandToolEvent.STATE_SUCCESS then
		self:onHandToolSold()
	else
		self:onHandToolSellFailed(errorCode)
	end
end

function ShopController:onHandToolSold()
	g_gui:closeAllDialogs()

	if self.soldItem ~= nil then
		self.soldItem = nil
	end

	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onHandToolSellFailed(state)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)

	if state == SellHandToolEvent.STATE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
	elseif state == SellHandToolEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onVehicleBuyEvent(errorCode, leaseVehicle, price)
	if errorCode == BuyVehicleEvent.STATE_SUCCESS then
		self:onVehicleBought(leaseVehicle, price)
	else
		self:onVehicleBuyFailed(leaseVehicle, errorCode)
	end
end

function ShopController:onVehicleBought(leaseVehicle, price)
	g_gui:closeAllDialogs()

	if not leaseVehicle then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.LEASE_VEHICLE_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	end

	self.updateShopItemsCallback()
end

function ShopController:onVehicleBuyFailed(leaseVehicle, errorCode)
	g_gui:closeAllDialogs()

	local text = ""

	if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
	elseif errorCode == BuyVehicleEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	else
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_FAILED_TO_LOAD)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onObjectBuyEvent(errorCode, price)
	if errorCode == BuyObjectEvent.STATE_SUCCESS then
		self:onObjectBought(price)
	else
		self:onObjectBuyFailed(errorCode)
	end
end

function ShopController:onObjectBought(price)
	g_gui:closeAllDialogs()
	self.currentMission:addMoneyChange(-price, self.playerFarmId, MoneyType.SHOP_VEHICLE_BUY)
	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_OBJECT_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onObjectBuyFailed(errorCode)
	g_gui:closeAllDialogs()

	if errorCode == BuyObjectEvent.STATE_NO_SPACE then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE),
			callback = self.onBoughtCallback,
			target = self
		})
	elseif errorCode == BuyObjectEvent.STATE_LIMIT_REACHED then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS),
			callback = self.onBoughtCallback,
			target = self
		})
	elseif errorCode == BuyObjectEvent.STATE_NOT_ENOUGH_MONEY then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY),
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED),
			callback = self.onBoughtCallback,
			target = self
		})
	end
end

function ShopController:onHandToolBuyEvent(success, errorCode, price)
	if success then
		self:onHandToolBought(price)
	else
		self:onHandToolBuyFailed(errorCode)
	end
end

function ShopController:onHandToolBought(price)
	g_gui:closeAllDialogs()

	if GS_IS_CONSOLE_VERSION then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CHAINSAW_THANKS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CHAINSAW_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	end
end

function ShopController:onHandToolBuyFailed(errorCode)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED)

	if errorCode == BuyHandToolEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned)
	if isDirectSell then
		return
	end

	if errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end

function ShopController:onVehicleSold(sellPrice, isOwned)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS)

	if not isOwned then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_SUCCESS)
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onVehicleSellFailed(isOwned, errorCode)
	g_gui:closeAllDialogs()

	local text = ""

	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
		elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_LAST_VEHICLE_FAILED)
		else
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_NO_PERMISSION)
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_IN_USE)
	elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_LAST_VEHICLE_FAILED)
	else
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_FAILED)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onPlaceableSellEvent(errorCode, sellPrice)
	if errorCode == SellPlaceableEvent.STATE_SUCCESS then
		self:onPlaceableSold(sellPrice)
	else
		self:onPlaceableSellFailed(errorCode)
	end
end

function ShopController:onPlaceableSold(sellPrice)
	g_gui:closeAllDialogs()

	if self.soldItem ~= nil then
		self.soldItem = nil
	end

	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onPlaceableSellFailed(state)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)

	if state == SellPlaceableEvent.STATE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
	elseif state == SellPlaceableEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.NO_PERMISSION)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onBoughtCallback()
	self.isBuying = false

	self.updateAllItemsCallback()
	self.currentMission:calculateSlotUsage()
end

function ShopController:onSoldCallback()
	self.isSelling = false

	self.updateAllItemsCallback()
	self.currentMission:calculateSlotUsage()
end

function ShopController.brandSortFunction(item1, item2)
	return utf8ToUpper(item1.sortValue) < utf8ToUpper(item2.sortValue)
end

function ShopController.categorySortFunction(item1, item2)
	return item1.sortValue < item2.sortValue
end

function ShopController.displayItemSortFunction(item1, item2)
	if item1.orderValue == item2.orderValue then
		local sellPrice1 = item1:getSellPrice()
		local sellPrice2 = item2:getSellPrice()

		if sellPrice1 == sellPrice2 then
			return item2:getSortId() < item1:getSortId()
		else
			return sellPrice2 < sellPrice1
		end
	else
		return item1.orderValue < item2.orderValue
	end
end

function ShopController:getCoinItems()
	local list = {}

	if not self.inAppPurchaseController:getIsAvailable() then
		return list
	end

	for _, product in ipairs(self.inAppPurchaseController:getProducts()) do
		local storeItem = {
			isInAppPurchase = true,
			name = product:getId(),
			priceText = product:getPriceText(),
			title = product:getTitle(),
			imageFilename = product:getImageFilename(),
			product = product,
			canBeRecovered = self.inAppPurchaseController:getHasPendingPurchase(product)
		}
		local displayItem = ShopDisplayItem:new(storeItem, nil, , , , , , self.l10n:getText("function_coins"), #list)

		table.insert(list, displayItem)
	end

	return list
end

ShopController.PROFILE = {
	ICON_LEASED = "shopListAttributeIconLeased",
	ICON_OWNED = "shopListAttributeIconOwned"
}
ShopController.L10N_SYMBOL = {
	BUY_VEHICLE_FAILED_TO_LOAD = "shop_messageFailedToLoadVehicle",
	RETURN_LAST_VEHICLE_FAILED = "shop_messageFailedToReturnLastVehicleText",
	SELLING_VEHICLE = "shop_messageSellingVehicle",
	RETURNING_VEHICLE = "shop_messageReturningVehicle",
	SELL_VEHICLE_SUCCESS = "shop_messageSoldVehicle",
	WARNING_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuy",
	BUYING_VEHICLE = "shop_messageBuyingVehicle",
	BUY_OBJECT_SUCCESS = "shop_messageGardenCenterPurchaseReady",
	WARNING_TOO_MANY_PLACEABLES = "warning_tooManyPlaceables",
	LOAD_OBJECT_FAILED = "shop_messageFailedToLoadObject",
	WARNING_NOT_ENOUGH_SLOTS = "shop_messageNotEnoughSlotsToBuy",
	LEASING_VEHICLE = "shop_messageLeasingVehicle",
	WARNING_TOO_MANY_PALLETS = "warning_tooManyPallets",
	RETURN_VEHICLE_SUCCESS = "shop_messageReturnedVehicle",
	SELL_LAST_VEHICLE_FAILED = "shop_messageFailedToSellLastVehicleText",
	BUY_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToBuyVehicleText",
	BUY_CHAINSAW_SUCCESS = "shop_messageBoughtChainsaw",
	RETURN_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToReturnVehicleText",
	BUY_CONFIRMATION = "shop_doYouWantToBuy",
	SELL_VEHICLE_FAILED = "shop_messageFailedToSellVehicle",
	SELL_VEHICLE_IN_USE = "shop_messageSellVehicleInUse",
	BUY_ALREADY_OWNED = "shop_messageAlreadyOwned",
	CANNOT_SELL_TOUR_ITEMS = "shop_messageTourItemsCannotBeSold",
	SELL_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToSellVehicleText",
	RETURN_VEHICLE_FAILED = "shop_messageFailedToReturnVehicle",
	LEASE_VEHICLE_SUCCESS = "shop_messageLeasingReady",
	WARNING_NO_SPACE = "shop_messageNoSpace",
	NO_PERMISSION = "shop_messageNoPermissionGeneral",
	BUY_CHAINSAW_THANKS = "shop_messageThanksForBuying",
	BUY_VEHICLE_SUCCESS = "shop_messagePurchaseReady",
	RETURN_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse"
}
