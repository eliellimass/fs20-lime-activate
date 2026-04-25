DirectSellDialog = {
	CONTROLS = {
		NAME_ELEMENT = "dialogName",
		OPERATING_HOURS_TEXT = "operatingHoursText",
		PRICE_ELEMENT = "priceText",
		VEHICLE_INFO_BOX = "vehicleInfoBox",
		REPAIR_BUTTON = "repairButton",
		HEADER_TEXT = "headerText",
		SELL_BUTTON = "sellButton",
		AGE_TEXT = "ageText",
		CONFIG_BUTTON = "configButton",
		INFO_ELEMENT = "dialogInfo",
		CONDITION_BAR_BG = "conditionBarBg",
		IMAGE_ELEMENT = "dialogImage",
		TEXT_ELEMENT = "dialogText",
		CONDITION_BAR = "conditionBar",
		NAME_SEPARATOR_ELEMENT = "dialogSeparator"
	}
}
local DirectSellDialog_mt = Class(DirectSellDialog, MessageDialog)

function DirectSellDialog:new(target, custom_mt, shopConfigScreen, messageCenter)
	local self = MessageDialog:new(target, custom_mt or DirectSellDialog_mt)
	self.shopConfigScreen = shopConfigScreen
	self.isBackAllowed = false
	self.inputDelay = 250

	self:registerControls(DirectSellDialog.CONTROLS)

	return self
end

function DirectSellDialog:onOpen()
	DirectSellDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250

	g_messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairEvent, self)
end

function DirectSellDialog:onClose()
	DirectSellDialog:superClass().onClose(self)

	self.vehicle = nil

	g_messageCenter:unsubscribeAll(self)
end

function DirectSellDialog:onClickOk()
	if self.inputDelay < self.time and self.vehicle ~= nil and not self.ownWorkshop and self.vehicle.propertyState ~= Vehicle.PROPERTY_STATE_MISSION and self.canBeSold then
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_youWantToSellVehicle"),
			callback = self.sellVehicleYesNo,
			target = self
		})

		return false
	end

	return true
end

function DirectSellDialog:sellVehicleYesNo(yes)
	if yes then
		g_client:getServerConnection():sendEvent(SellVehicleEvent:new(self.vehicle, EconomyManager.DIRECT_SELL_MULTIPLIER, true))

		self.vehicle = nil
	end
end

function DirectSellDialog:onClickActivate()
	if self.inputDelay < self.time and self.canBeConfigurated then
		self.shopConfigScreen:setReturnScreen("")

		local changePrice = EconomyManager.CONFIG_CHANGE_PRICE

		if self.ownWorkshop then
			changePrice = 0
		end

		self.shopConfigScreen:setStoreItem(self.storeItem, self.vehicle, changePrice)
		self.shopConfigScreen:setCallbacks(self.setConfigurations, self)
		self:close()
		g_gui:showGui("ShopConfigScreen")

		return false
	end

	return true
end

function DirectSellDialog:setConfigurations(vehicle, buyItem, storeItem, configs, price)
	self.vehicle = vehicle

	if not buyItem and storeItem ~= nil and configs ~= nil then
		local areChangesMade = false
		local newConfigs = {}

		for configName, configValue in pairs(configs) do
			if self.vehicle.configurations[configName] ~= configValue then
				newConfigs[configName] = configs[configName]
				areChangesMade = true
			end
		end

		if areChangesMade then
			if not g_currentMission.controlPlayer and g_currentMission.controlledVehicle ~= nil and self.vehicle == g_currentMission.controlledVehicle then
				g_currentMission:onLeaveVehicle()
			end

			g_client:getServerConnection():sendEvent(ChangeVehicleConfigEvent:new(self.vehicle, price, g_currentMission:getFarmId(), newConfigs))
		end
	else
		self:onClickBack()

		if self.owner ~= nil then
			self.owner:onActivateObject()
		end
	end
end

function DirectSellDialog:onClickBack(forceBack)
	if self.inputDelay < self.time then
		self:close()

		return false
	else
		return true
	end
end

function DirectSellDialog:onClickCancel()
	if self.vehicle ~= nil and self.vehicle:getRepairPrice(true) >= 1 then
		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_repairDialog"), self.vehicle:getRepairPrice(true)),
			callback = self.onYesNoRepairDialog,
			target = self
		})

		return true
	else
		return false
	end
end

function DirectSellDialog:onYesNoRepairDialog(yes)
	if yes then
		g_client:getServerConnection():sendEvent(WearableRepairEvent:new(self.vehicle, true))
	end
end

function DirectSellDialog:onVehicleRepairEvent(vehicle, atSellingPoint)
	if vehicle == self.vehicle then
		self:setVehicle(vehicle)
	end
end

function DirectSellDialog:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned, ownerFarmId)
	if not isDirectSell then
		return
	end

	if errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end

function DirectSellDialog:update(dt)
	DirectSellDialog:superClass().update(self, dt)

	if self.vehicle ~= nil and self.vehicle.isDeleted then
		self:close()
	end
end

function DirectSellDialog:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	local text = g_i18n:getText("shop_messageSoldVehicle")

	if not isOwned then
		text = g_i18n:getText("shop_messageReturnedVehicle")
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onInfoDialogCallback,
		target = self
	})
end

function DirectSellDialog:onVehicleSellFailed(isOwned, errorCode)
	local text = ""

	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			text = g_i18n:getText("shop_messageNoPermissionToSellVehicleText")
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			text = g_i18n:getText("shop_messageSellVehicleInUse")
		else
			text = g_i18n:getText("shop_messageFailedToSellVehicle")
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		text = g_i18n:getText("shop_messageNoPermissionToReturnVehicleText")
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		text = g_i18n:getText("shop_messageReturnVehicleInUse")
	else
		text = g_i18n:getText("shop_messageFailedToReturnVehicle")
	end

	g_gui:showInfoDialog({
		text = text
	})
end

function DirectSellDialog:onVehicleChanged(success)
	if success then
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageConfigurationChanged"),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onInfoDialogCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageConfigurationChangeFailed"),
			callback = self.onInfoDialogCallback,
			target = self
		})
	end
end

function DirectSellDialog:onInfoDialogCallback()
	g_gui:showGui("")
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end

function DirectSellDialog:setVehicle(vehicle, owner, ownWorkshop)
	local imageFilename = "dataS2/menu/blank.png"
	local name = "unknown"
	local sellPrice = 0
	local age = 0
	local operatingTime = 0
	self.owner = owner
	self.ownWorkshop = ownWorkshop
	self.storeItem = nil
	self.canBeConfigurated = false

	self.headerText:setText(g_i18n:getText("ui_sellOrCustomizeVehicleTitle"))

	self.canBeSold = true

	if vehicle ~= nil then
		self.vehicle = vehicle
		self.storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)

		if self.storeItem ~= nil then
			self.canBeConfigurated = self.storeItem.configurations ~= nil and vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED
			self.canBeSold = self.storeItem.canBeSold
			imageFilename = self.storeItem.imageFilename
			local brand = g_brandManager:getBrandByIndex(self.storeItem.brandIndex)
			name = brand.name .. " " .. self.storeItem.name
		end

		operatingTime = vehicle:getOperatingTime()
		age = vehicle.age

		self.sellButton:setDisabled(false)

		if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
			if not self.canBeConfigurated then
				self.headerText:setText(g_i18n:getText("ui_sellItem"))
			end

			self:setButtonText(g_i18n:getText("button_sell"))

			sellPrice = math.min(math.floor(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER), vehicle:getPrice())

			self.priceText:setText(g_i18n:formatMoney(sellPrice))
		elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
			self.headerText:setText(g_i18n:getText("ui_returnThis"))
			self:setButtonText(g_i18n:getText("button_return"))
			self.priceText:setText("-")
		elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_MISSION then
			self.sellButton:setDisabled(true)
			self.priceText:setText("-")
		end

		if vehicle.getWearTotalAmount ~= nil then
			local value = 1 - vehicle:getWearTotalAmount()
			local fullWidth = self.conditionBarBg.size[1] - self.conditionBar.margin[1] * 2

			self.conditionBar:setSize(fullWidth * math.min(value, 1), nil)
		end

		self.repairButton:setDisabled(self.vehicle:getRepairPrice(true) < 1)
	else
		self.repairButton:setDisabled(true)
	end

	self.configButton:setDisabled(not self.canBeConfigurated)
	self.sellButton:setDisabled(vehicle == nil or ownWorkshop or self.vehicle.propertyState == Vehicle.PROPERTY_STATE_MISSION or not self.canBeSold)
	self.vehicleInfoBox:setVisible(vehicle ~= nil)
	self.dialogInfo:setVisible(vehicle == nil)
	self.dialogImage:setImageFilename(imageFilename)
	self.dialogName:setText(name)

	local minutes = operatingTime / 60000
	local hours = math.floor(minutes / 60)
	minutes = math.floor((minutes - hours * 60) / 6) * 10

	self.operatingHoursText:setText(string.format(g_i18n:getText("shop_operatingTime"), hours, minutes))
	self.ageText:setText(string.format(g_i18n:getText("shop_age"), string.format("%d", age)))
end

function DirectSellDialog:setButtonText(text)
	self.sellButton:setText(text)
end
