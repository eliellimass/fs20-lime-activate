ShopMenu = {}
local ShopMenu_mt = Class(ShopMenu, TabbedMenuWithDetails)
ShopMenu.CONTROLS = {
	PAGE_SHOP_TOOLS = "pageShopTools",
	PAGE_SHOP_VEHICLES = "pageShopVehicles",
	PAGE_SHOP_LANDSCAPING = "pageShopLandscaping",
	PAGE_SHOP_ITEM_DETAILS = "pageShopItemDetails",
	PAGE_SHOP_GARAGE_OWNED = "pageShopGarageOwned",
	PAGE_SHOP_PLACEABLES = "pageShopPlaceables",
	PAGE_SHOP_OBJECTS = "pageShopObjects",
	PAGE_SHOP_GARAGE_LEASED = "pageShopGarageLeased",
	PAGE_SHOP_BRANDS = "pageShopBrands"
}

local function NO_CALLBACK()
end

function ShopMenu:new(target, customMt, messageCenter, l10n, inputManager, fruitTypeManager, fillTypeManager, storeManager, shopController, shopConfigScreen, placementScreen, isConsoleVersion, inAppPurchaseController)
	local self = TabbedMenuWithDetails:new(target, customMt or ShopMenu_mt, messageCenter, l10n, inputManager)

	self:registerControls(ShopMenu.CONTROLS)

	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.storeManager = storeManager
	self.shopController = shopController
	self.shopConfigScreen = shopConfigScreen
	self.placementScreen = placementScreen
	self.isConsoleVersion = isConsoleVersion
	self.inAppPurchaseController = inAppPurchaseController
	self.hud = nil
	self.performBackgroundBlur = true
	self.gameState = GameState.MENU_SHOP
	self.restorePageIndex = 2
	self.useStack = true
	self.playerFarm = nil
	self.playerFarmId = 0
	self.currentUserId = -1
	self.lastGaragePage = nil
	self.paused = false
	self.isMissionTourActive = false
	self.client = nil
	self.server = nil
	self.isMasterUser = false
	self.isServer = false
	self.currentBalanceValue = 0
	self.timeSinceLastMoneyUpdate = 0
	self.needMoneyUpdate = true
	self.selectedItemElement = nil
	self.selectedDisplayElement = nil
	self.currentDisplayItems = nil
	self.defaultMenuButtonInfo = {}
	self.shopMenuButtonInfo = {}
	self.buyButtonInfo = {}
	self.shopDetailsButtonInfo = {}
	self.garageMenuButtonInfo = {}
	self.switchOwnedLeasedButtonInfo = {}
	self.sellButtonInfo = {}
	self.backButtonInfo = {}
	self.repairButtonInfo = {}

	self.shopConfigScreen:setRequestExitCallback(self:makeSelfCallback(self.exitMenuFromConfig))

	return self
end

function ShopMenu:setClient(client)
	self.client = client
end

function ShopMenu:setServer(server)
	self.server = server
	self.isServer = server ~= nil
end

function ShopMenu:setHUD(hud)
	self.hud = hud
end

function ShopMenu:updateGarageItems()
	if self:getIsDetailMode() then
		local detail = self:getTopFrame()

		self:updateGarageButtonInfo(detail, detail == self.pageShopGarageOwned, 0, false)
	end

	self.pageShopGarageOwned:setDisplayItems(self.shopController:getOwnedItems(), true)
	self.pageShopGarageLeased:setDisplayItems(self.shopController:getLeasedVehicles(), true)
end

function ShopMenu:onLoadMapFinished()
	self:initializePages()
	self:onMissionTourStateChanged(false)
end

function ShopMenu:initializePages()
	self.inAppPurchaseController:load()

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	self.shopController:setCurrentMission(g_currentMission)
	self.shopController:setClient(g_client)
	self.shopController:setUpdateShopItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
	self.shopController:setUpdateAllItemsCallback(self:makeSelfCallback(self.updateGarageItems))
	self.shopController:setStartPlacementModeCallback(self.startPlacementMode, self)
	self.shopController:setSwitchToConfigurationCallback(self.showConfigurationScreen, self)
	self.shopController:load()
	self.pageShopBrands:initialize(self.shopController:getBrands(), self:makeSelfCallback(self.onClickBrand), GuiUtils.getUVs(ShopMenu.TAB_UV.BRANDS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), ShopMenu.BRAND_IMAGE_HEIGHT_WIDTH_RATIO)

	local clickItemCategoryCallback = self:makeSelfCallback(self.onClickItemCategory)

	self.pageShopVehicles:initialize(self.shopController:getVehicleCategories(), clickItemCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.VEHICLES), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES))
	self.pageShopTools:initialize(self.shopController:getToolCategories(), clickItemCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.TOOLS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_TOOLS))
	self.pageShopObjects:initialize(self.shopController:getObjectCategories(), clickItemCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.OBJECTS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_OBJECTS))
	self.pageShopPlaceables:initialize(self.shopController:getPlaceableCategories(), clickItemCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.PLACEABLES), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_PLACEABLES))
	self.pageShopLandscaping:initialize(self:makeStartLandscapingModeCallback())

	local clickBuyItemCallback = self:makeClickBuyItemCallback()

	self.pageShopItemDetails:initialize()
	self.pageShopItemDetails:setItemClickCallback(clickBuyItemCallback)
	self.pageShopItemDetails:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))

	local clickSellItemCallback = self:makeClickSellItemCallback()
	local selectSellItemCallback = self:makeSelfCallback(self.onSelectItemSellDetail)

	self.pageShopGarageOwned:initialize()
	self.pageShopGarageOwned:setHeader(GuiUtils.getUVs(ShopMenu.TAB_UV.GARAGE), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_GARAGE_OWNED))
	self.pageShopGarageOwned:setItemClickCallback(clickSellItemCallback)
	self.pageShopGarageOwned:setItemSelectCallback(selectSellItemCallback)
	self.pageShopGarageLeased:initialize()
	self.pageShopGarageLeased:setHeader(GuiUtils.getUVs(ShopMenu.TAB_UV.GARAGE), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_GARAGE_LEASED))
	self.pageShopGarageLeased:setItemClickCallback(clickSellItemCallback)
	self.pageShopGarageLeased:setItemSelectCallback(selectSellItemCallback)

	self.lastGaragePage = self.pageShopGarageOwned
end

function ShopMenu:setupMenuPages()
	local shopEnabledPredicate = self:makeIsShopEnabledPredicate()
	local shopDetailsEnabledPredicate = self:makeIsShopItemsEnabledPredicate()
	local orderedDefaultPages = {
		{
			self.pageShopBrands,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.BRANDS
		},
		{
			self.pageShopVehicles,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		},
		{
			self.pageShopTools,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.TOOLS
		},
		{
			self.pageShopObjects,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.OBJECTS
		},
		{
			self.pageShopPlaceables,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.PLACEABLES
		},
		{
			self.pageShopLandscaping,
			self:makeIsLandscapingEnabledPredicate(),
			ShopMenu.TAB_UV.LANDSCAPING
		},
		{
			self.pageShopItemDetails,
			shopDetailsEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		},
		{
			self.pageShopGarageOwned,
			shopDetailsEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		},
		{
			self.pageShopGarageLeased,
			shopDetailsEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		}
	}

	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local imageFilename = g_baseUIFilename
		local normalizedUVs = nil

		if page == self.pageShopLandscaping then
			imageFilename = ShopMenu.LANDSCAPING_ICON_PATH
			normalizedUVs = GuiUtils.getUVs(iconUVs, ShopMenu.LANDSCAPING_ICON_SIZE)
		else
			normalizedUVs = GuiUtils.getUVs(iconUVs)
		end

		self:addPageTab(page, imageFilename, normalizedUVs)
	end
end

function ShopMenu:setupMenuButtonInfo()
	ShopMenu:superClass().setupMenuButtonInfo(self)

	local onButtonBackFunction = self.clickBackCallback
	local onButtonQuitFunction = self:makeSelfCallback(self.onButtonQuit)
	local onButtonSaveGameFunction = self:makeSelfCallback(self.onButtonSaveGame)
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = onButtonBackFunction
	}
	self.defaultMenuButtonInfo = {
		self.backButtonInfo,
		self.saveButtonInfo,
		self.quitButtonInfo
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction,
		[InputAction.MENU_CANCEL] = onButtonQuitFunction,
		[InputAction.MENU_ACTIVATE] = onButtonSaveGameFunction
	}
	local onButtonGarageFunction = self:makeSelfCallback(self.onButtonGarage)
	local onBrandSwitchFunction = self:makeSelfCallback(self.onButtonBrands)
	local onButtonInfoFunction = self:makeSelfCallback(self.onButtonInfo)

	if GS_IS_MOBILE_VERSION then
		self.brandsSwitchButton = {
			profile = "buttonSwitchGarage",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BRANDS),
			callback = onBrandSwitchFunction,
			clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
		}
		self.shopMenuButtonInfo = {
			self.backButtonInfo,
			self.brandsSwitchButton
		}
	else
		self.shopMenuButtonInfo = {
			self.backButtonInfo,
			{
				inputAction = InputAction.MENU_CANCEL,
				text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_GARAGE),
				callback = onButtonGarageFunction,
				clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
			}
		}
	end

	self.buyButtonInfo = {
		profile = "buttonBuy",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY),
		callback = self:makeSelfCallback(self.onButtonAcceptItem)
	}

	if GS_IS_MOBILE_VERSION then
		self.shopDetailsButtonInfo = {
			self.backButtonInfo,
			self.buyButtonInfo,
			{
				profile = "buttonShowInfo",
				inputAction = InputAction.MENU_CANCEL,
				text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_INFO),
				callback = onButtonInfoFunction,
				clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
			}
		}
	else
		self.shopDetailsButtonInfo = {
			self.buyButtonInfo,
			self.backButtonInfo,
			{
				inputAction = InputAction.MENU_CANCEL,
				text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_GARAGE),
				callback = onButtonGarageFunction,
				clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
			}
		}
	end

	self.switchOwnedLeasedButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.LEASED_ITEMS),
		callback = self:makeSelfCallback(self.onButtonSwitchOwnedLeased)
	}
	self.sellButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL),
		callback = self:makeSelfCallback(self.onButtonAcceptItem)
	}
	self.repairButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_REPAIR),
		callback = self:makeSelfCallback(self.onButtonRepair)
	}
	self.garageMenuButtonInfo = {
		self.backButtonInfo,
		self.switchOwnedLeasedButtonInfo
	}

	self.pageShopGarageOwned:setMenuButtonInfo(self.garageMenuButtonInfo)
	self.pageShopGarageLeased:setMenuButtonInfo(self.garageMenuButtonInfo)
end

function ShopMenu:onGuiSetupFinished()
	ShopMenu:superClass().onGuiSetupFinished(self)
	self.messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairEvent, self)
	self.messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChanged, self)
	self.messageCenter:subscribe(MessageType.MISSION_TOUR_STARTED, self.onMissionTourStateChanged, self, true)
	self.messageCenter:subscribe(MessageType.MISSION_TOUR_FINISHED, self.onMissionTourStateChanged, self, false)
	self:setupMenuPages()
end

function ShopMenu:setPlayerFarm(farm)
	self.playerFarm = farm
	self.playerFarmId = farm.farmId

	self.shopController:setPlayerFarm(farm)

	if self:getIsOpen() then
		self:updatePages()
	end
end

function ShopMenu:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
end

function ShopMenu:exitMenuFromConfig()
	self.shopConfigScreen:changeScreen(ShopMenu)
	self:exitMenu()
end

function ShopMenu:reset()
	ShopMenu:superClass().reset(self)
	self.shopController:reset()

	self.isMasterUser = false
	self.isServer = false
	self.selectedItemElement = nil
	self.selectedDisplayElement = nil

	if GS_IS_MOBILE_VERSION then
		self.restorePageIndex = 2
	end
end

function ShopMenu:onOpen()
	ShopMenu:superClass().onOpen(self)
	self:onMoneyChanged(self.playerFarm.farmId, self.playerFarm:getBalance())
	self.hud:onMenuVisibilityChange(true, false)
end

function ShopMenu:onClose(element)
	ShopMenu:superClass().onClose(self)

	self.mouseDown = false
	self.alreadyClosed = true

	if not self.closingForConfigurationScreen then
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
		g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY)
		g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
	end

	self.closingForConfigurationScreen = false
end

function ShopMenu:onMissionTourStateChanged(isMissionTourActive)
	self.isMissionTourActive = isMissionTourActive
end

function ShopMenu:onButtonGarage()
	self:updateGarageItems()

	local goToOwnedItems = self.lastGaragePage == self.pageShopGarageOwned

	if goToOwnedItems then
		self.switchOwnedLeasedButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.LEASED_ITEMS)
	else
		self.switchOwnedLeasedButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.OWNED_ITEMS)
	end

	self:updateGarageButtonInfo(self.lastGaragePage, goToOwnedItems, 0, false)
	self:pushDetail(self.lastGaragePage)
end

function ShopMenu:onButtonBrands()
	if self.currentPage == self.pageShopVehicles then
		self.brandsSwitchButton.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_CATEGORIES)

		self:goToPage(self.pageShopBrands)
	else
		self.brandsSwitchButton.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BRANDS)

		self:goToPage(self.pageShopVehicles)
	end
end

function ShopMenu:onButtonInfo()
	g_gui:showInfoDialog({
		text = self.selectedDisplayElement.functionText
	})
end

function ShopMenu:onButtonShop()
	self:popDetail()
end

function ShopMenu:onButtonRepair()
	local concreteItem = self.selectedDisplayElement.concreteItem
	local repairPrice = concreteItem:getRepairPrice(false)

	if repairPrice > 0 then
		if g_currentMission:getMoney() < repairPrice then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
			g_gui:showInfoDialog({
				text = self.l10n:getText(ShopMenu.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
			})
		else
			local repairText = g_i18n:formatMoney(repairPrice)

			g_gui:showYesNoDialog({
				text = string.format(self.l10n:getText(ShopMenu.L10N_SYMBOL.REPAIR_DIALOG), repairText),
				callback = self.onYesNoRepairDialog,
				target = self
			})
		end
	end
end

function ShopMenu:onYesNoRepairDialog(yes)
	if yes then
		g_client:getServerConnection():sendEvent(WearableRepairEvent:new(self.selectedDisplayElement.concreteItem, false))
	end
end

function ShopMenu:onVehicleRepairEvent(vehicle, _)
	if self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem == vehicle then
		self:updateGarageButtonInfo(self:getTopFrame(), true, 1, false)
	end
end

function ShopMenu:onButtonAcceptItem()
	if self.selectedItemElement ~= nil and self:getIsDetailMode() then
		self:getTopFrame():onClickItem(nil, self.selectedItemElement)
	end
end

function ShopMenu:onButtonSwitchOwnedLeased()
	local ownedMode = self:getTopFrame() == self.pageShopGarageOwned

	if ownedMode then
		self.switchOwnedLeasedButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.OWNED_ITEMS)
		self.sellButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RETURN)

		self:updateGarageButtonInfo(self.pageShopGarageLeased, false, 0, false)
		self:replaceDetail(self.pageShopGarageLeased)

		self.lastGaragePage = self.pageShopGarageLeased
	else
		self.switchOwnedLeasedButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.LEASED_ITEMS)
		self.sellButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL)

		self:updateGarageButtonInfo(self.pageShopGarageOwned, true, 0, false)
		self:replaceDetail(self.pageShopGarageOwned)

		self.lastGaragePage = self.pageShopGarageOwned
	end
end

function ShopMenu:setIsGamePaused(paused)
	self.paused = paused

	if self.currentPage ~= nil then
		self:updateButtonsPanel(self.currentPage)
	end
end

function ShopMenu:startPlacementMode(storeItem, isSellingMode, obj)
	local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)
	local canSell = isSellingMode and userPermissions[Farm.PERMISSION.SELL_PLACEABLE] or self.isMasterUser
	local canBuy = not isSellingMode and userPermissions[Farm.PERMISSION.BUY_PLACEABLE] or self.isMasterUser

	if canSell or canBuy then
		self.placementScreen:setPlacementItem(storeItem, isSellingMode, obj)
		self:changeScreen(PlacementScreen)
		self.hud:onMenuVisibilityChange(true, true)
	else
		local text = self.l10n:getText(ShopMenu.L10N_SYMBOL.MESSAGE_NO_PERMISSION)

		g_gui:showInfoDialog({
			text = text
		})
	end
end

function ShopMenu:startLandscapingMode()
	local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)
	local hasPermission = userPermissions[Farm.PERMISSION.LANDSCAPING] or self.isMasterUser

	if hasPermission then
		self:changeScreen(LandscapingScreen)
		self.hud:onMenuVisibilityChange(true, true)
	else
		local text = self.l10n:getText(ShopMenu.L10N_SYMBOL.MESSAGE_NO_PERMISSION)

		g_gui:showInfoDialog({
			text = text
		})
	end
end

function ShopMenu:onDetailClosed(detailPage)
	self.updateCurrentDisplayItems = nil
end

function ShopMenu:update(dt)
	ShopMenu:superClass().update(self, dt)
	self.shopController:update(dt)
	self.inAppPurchaseController:update(dt)
	self:updateCurrentBalanceDisplay(dt)
end

function ShopMenu:setConfigurations(vehicle, leaseItem, storeItem, configs, configSetIndex)
	self.shopController:setConfigurations(vehicle, leaseItem, storeItem, configs, configSetIndex)
end

function ShopMenu:showConfigurationScreen(storeItem)
	self.shopConfigScreen:setReturnScreen(self.name)
	self.shopConfigScreen:setStoreItem(storeItem)
	self.shopConfigScreen:setCallbacks(self.setConfigurations, self)

	self.closingForConfigurationScreen = true

	self:changeScreen(ShopConfigScreen)
end

function ShopMenu:updateCurrentBalanceDisplay(dt)
	self.timeSinceLastMoneyUpdate = self.timeSinceLastMoneyUpdate + dt

	if self.needMoneyUpdate and TabbedMenu.MONEY_UPDATE_INTERVAL <= self.timeSinceLastMoneyUpdate then
		local balanceMoneyText = self.l10n:formatMoney(self.currentBalanceValue, 0, false) .. " " .. self.l10n:getCurrencySymbol(true)

		self.pageShopItemDetails:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)
		self.pageShopGarageOwned:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)
		self.pageShopGarageLeased:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)

		self.timeSinceLastMoneyUpdate = 0
		self.needMoneyUpdate = false
	end
end

function ShopMenu:updateCurrentDisplayItems()
	if self.currentDisplayItems ~= nil then
		local updatedDisplayItems = self.shopController:updateDisplayItems(self.currentDisplayItems)

		self.pageShopItemDetails:setDisplayItems(updatedDisplayItems, false)
	end
end

function ShopMenu:inputEvent(action, value, eventUsed)
	local eventUsed = ShopMenu:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and action == InputAction.TOGGLE_STORE then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
		self:exitMenu()

		eventUsed = true
	end

	return eventUsed
end

function ShopMenu:onClickMenu()
	self:exitMenu()

	return true
end

function ShopMenu:onMoneyChanged(farmId, newMoneyValue)
	if farmId == self.playerFarmId and self:getIsVisible() then
		self.currentBalanceValue = newMoneyValue
		self.needMoneyUpdate = true
	end
end

function ShopMenu:onSlotUsageChanged(currentSlotUsage, maxSlotUsage)
	if GS_IS_CONSOLE_VERSION then
		self.pageShopItemDetails:setSlotsUsage(currentSlotUsage, maxSlotUsage)
		self.pageShopGarageOwned:setSlotsUsage(currentSlotUsage, maxSlotUsage)
		self.pageShopGarageLeased:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	end
end

function ShopMenu:onSelectItemBuyDetail(displayItem, selectedElement)
	self.selectedItemElement = selectedElement
	self.selectedDisplayElement = displayItem
	local isVehicle = StoreItemUtil.getIsVehicle(displayItem.storeItem)
	local isConfigurable = StoreItemUtil.getIsConfigurable(displayItem.storeItem)

	if isVehicle and isConfigurable and not GS_IS_MOBILE_VERSION then
		self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_CUSTOMIZE)
	else
		local isHandTool = StoreItemUtil.getIsHandTool(displayItem.storeItem)

		if not isConfigurable and not isHandTool and not GS_IS_MOBILE_VERSION then
			self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_DETAILS)
		else
			self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY)
		end
	end

	if isVehicle and GS_IS_MOBILE_VERSION and displayItem.storeItem.canBeRecovered then
		self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RECOVER)
		self.buyButtonInfo.profile = "buttonRecover"
	else
		self.buyButtonInfo.profile = "buttonBuy"
	end

	self:assignMenuButtonInfo(self.shopDetailsButtonInfo)
end

function ShopMenu:onSelectItemSellDetail(displayItem, selectedElement)
	self.selectedItemElement = selectedElement
	self.selectedDisplayElement = displayItem
	local concreteItem = displayItem.concreteItem
	local itemPropertyState = concreteItem.propertyState
	local isOwned = itemPropertyState == nil or itemPropertyState ~= Vehicle.PROPERTY_STATE_LEASED
	local canRepair = false

	if concreteItem.specializations ~= nil and SpecializationUtil.hasSpecialization(Wearable, concreteItem.specializations) then
		canRepair = concreteItem:getVehicleDamage() > 0
	end

	self:updateGarageButtonInfo(self:getTopFrame(), isOwned, 1, canRepair)
end

function ShopMenu:getPageButtonInfo(page)
	local buttonInfo = ShopMenu:superClass().getPageButtonInfo(self, page)

	if self:getIsDetailMode() then
		if page == self.pageShopGarageOwned or page == self.pageShopGarageLeased then
			buttonInfo = self.garageMenuButtonInfo
		else
			buttonInfo = self.shopDetailsButtonInfo
		end
	elseif self.currentPage ~= self.pageShopLandscaping then
		buttonInfo = self.shopMenuButtonInfo
	end

	return buttonInfo
end

function ShopMenu:onClickBrand(brandId, _, _, categoryDisplayName)
	local brandItems = self.shopController:getItemsByBrand(brandId)
	self.currentDisplayItems = brandItems

	self.pageShopItemDetails:setDisplayItems(brandItems, false)
	self.pageShopItemDetails:setCategory(GuiUtils.getUVs(ShopMenu.TAB_UV.BRANDS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), categoryDisplayName)
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:onClickItemCategory(categoryName, baseCategoryIconUVs, baseCategoryDisplayName, categoryDisplayName)
	local categoryItems = self.shopController:getItemsByCategory(categoryName)
	self.currentDisplayItems = categoryItems

	self.pageShopItemDetails:setDisplayItems(categoryItems, false)

	local isSpecial = false

	if categoryName == ShopController.COINS_CATEGORY then
		isSpecial = true

		if not self.inAppPurchaseController:getIsAvailable() then
			g_gui:showInfoDialog({
				dialogType = DialogElement.TYPE_INFO,
				text = self.l10n:getText("ui_iap_notAvailable")
			})

			return
		else
			self.inAppPurchaseController:setPendingPurchaseCallback(function ()
				if self:getTopFrame() ~= self.pageShopItemDetails or not self.currentDisplayItems[1].storeItem.isInAppPurchase then
					self.inAppPurchaseController:setPendingPurchaseCallback(nil)

					return
				end

				self.currentDisplayItems = self.shopController:getCoinItems()

				self.pageShopItemDetails:setDisplayItems(self.currentDisplayItems, false)
			end)
		end
	end

	self.pageShopItemDetails:setCategory(baseCategoryIconUVs, baseCategoryDisplayName, categoryDisplayName, isSpecial)
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:updateGarageButtonInfo(detailPage, isOwned, numItems, canRepair)
	if detailPage ~= nil then
		local pageButtonInfo = detailPage:getMenuButtonInfo()

		for k in pairs(pageButtonInfo) do
			pageButtonInfo[k] = nil
		end

		if numItems > 0 then
			table.insert(pageButtonInfo, self.sellButtonInfo)
		end

		table.insert(pageButtonInfo, self.backButtonInfo)
		table.insert(pageButtonInfo, self.switchOwnedLeasedButtonInfo)

		if canRepair then
			table.insert(pageButtonInfo, self.repairButtonInfo)
		end

		self:updateButtonsPanel(detailPage)
	end
end

function ShopMenu:buyItem(displayItem)
	if GS_IS_MOBILE_VERSION then
		local storeItem = displayItem.storeItem

		if storeItem.isInAppPurchase then
			return self:purchaseInAppProduct(storeItem.product)
		end

		local enoughMoney = true
		local price = g_currentMission.economyManager:getBuyPrice(storeItem)

		if price > 0 then
			enoughMoney = price <= g_currentMission:getMoney()
		end

		local enoughSlots = g_currentMission:hasEnoughSlots(storeItem)

		if not enoughMoney then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)

			if self.inAppPurchaseController:getIsAvailable() then
				g_gui:showYesNoDialog({
					title = self.l10n:getText("ui_buy"),
					text = self.l10n:getText("shop_messageNotEnoughMoneyToBuy_buyCoins"),
					callback = function (self, yes)
						if yes then
							self:showCoinShop()
						end
					end,
					target = self
				})
			else
				g_gui:showInfoDialog({
					text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
				})
			end
		elseif not enoughSlots then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
			g_gui:showInfoDialog({
				text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
			})
		else
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

			local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), self.l10n:formatMoney(price, 0, true, true))
			self.currentBuyDialogItem = displayItem

			g_gui:showYesNoDialog({
				text = text,
				callback = self.onYesNoBuy,
				target = self
			})
		end
	else
		self.shopController:buy(displayItem.storeItem, false)
	end
end

function ShopMenu:onYesNoBuy(yes)
	if yes then
		self.shopController:buy(self.currentBuyDialogItem.storeItem, false)
	end

	self.currentBuyDialogItem = nil
end

function ShopMenu:purchaseInAppProduct(product)
	if not self.inAppPurchaseController:tryPerformPendingPurchase(product, function ()
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = self.l10n:getText("ui_iap_purchaseComplete")
		})

		self.currentDisplayItems = self.shopController:getCoinItems()

		self.pageShopItemDetails:setDisplayItems(self.currentDisplayItems, false)
	end) then
		self.inAppPurchaseController:purchase(product, function (success, cancelled, error)
			if success then
				g_gui:showInfoDialog({
					dialogType = DialogElement.TYPE_INFO,
					text = self.l10n:getText("ui_iap_purchaseComplete")
				})
			elseif cancelled then
				return
			else
				g_gui:showInfoDialog({
					dialogType = DialogElement.TYPE_INFO,
					text = self.l10n:getText(error)
				})
			end
		end)
	end
end

function ShopMenu:showCoinShop()
	self:changeScreen(ShopMenu)
	self:goToPage(self.pageShopVehicles)
	self:onClickItemCategory(ShopController.COINS_CATEGORY, nil, , self.l10n:getText("ui_coins"))
end

function ShopMenu:makeIsShopEnabledPredicate()
	return function ()
		return not self:getIsDetailMode()
	end
end

function ShopMenu:makeIsShopItemsEnabledPredicate()
	return function ()
		return self:getIsDetailMode()
	end
end

function ShopMenu:makeIsLandscapingEnabledPredicate()
	return function ()
		local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)
		local hasPermission = userPermissions[Farm.PERMISSION.LANDSCAPING] or self.isMasterUser

		return not self.isMissionTourActive and hasPermission
	end
end

function ShopMenu:makeClickBuyItemCallback()
	return function (displayItem)
		self:buyItem(displayItem)
	end
end

function ShopMenu:makeClickSellItemCallback()
	return function (displayItem)
		self.shopController:sell(displayItem.storeItem, displayItem.concreteItem)
	end
end

function ShopMenu:makeStartLandscapingModeCallback()
	return function ()
		self:startLandscapingMode()
	end
end

ShopMenu.LANDSCAPING_ICON_PATH = "data/store/ui/icon_shovel.png"
ShopMenu.LANDSCAPING_ICON_SIZE = {
	64,
	64
}
ShopMenu.TAB_UV = {
	VEHICLES = {
		130,
		144,
		65,
		65
	},
	ANIMALS = {
		195,
		144,
		65,
		65
	},
	BRANDS = {
		780,
		144,
		65,
		65
	},
	TOOLS = {
		715,
		144,
		65,
		65
	},
	OBJECTS = {
		650,
		144,
		65,
		65
	},
	PLACEABLES = {
		585,
		144,
		65,
		65
	},
	LANDSCAPING = {
		0,
		0,
		64,
		64
	},
	GARAGE = {
		128,
		144,
		65,
		65
	}
}
ShopMenu.L10N_SYMBOL = {
	BUTTON_SHOP = "ui_shop",
	LEASED_ITEMS = "shop_leasedItems",
	BUTTON_BUY = "button_buy",
	BUTTON_REPAIR = "button_repair",
	BUTTON_BRANDS = "button_shop_brands",
	BUTTON_CATEGORIES = "button_shop_categories",
	HEADER_TOOLS = "ui_tools",
	HEADER_BRANDS = "ui_brands",
	NOT_ENOUGH_MONEY_BUY = "shop_messageNotEnoughMoneyToBuy",
	BUTTON_RECOVER = "button_recover",
	HEADER_GARAGE_LEASED = "ui_garageLeased",
	HEADER_SALES = "category_sales",
	BUTTON_CUSTOMIZE = "button_configurate",
	BUTTON_SELL = "button_sell",
	BUTTON_BACK = "button_back",
	BUTTON_INFO = "button_detail",
	HEADER_OBJECTS = "ui_objects",
	MESSAGE_NO_PERMISSION = "shop_messageNoPermissionGeneral",
	HEADER_PLACEABLES = "category_placeables",
	OWNED_ITEMS = "shop_ownedItems",
	BUTTON_GARAGE = "button_garage",
	HEADER_ANIMALS = "category_animals",
	HEADER_GARAGE_OWNED = "ui_garageOwned",
	BUTTON_RETURN = "button_return",
	BUTTON_DETAILS = "button_detail",
	REPAIR_DIALOG = "ui_repairDialog",
	HEADER_VEHICLES = GS_IS_MOBILE_VERSION and "ui_categories" or "ui_vehicles"
}
ShopMenu.BRAND_IMAGE_HEIGHT_WIDTH_RATIO = 0.5
