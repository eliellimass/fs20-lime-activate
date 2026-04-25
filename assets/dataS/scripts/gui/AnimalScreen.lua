AnimalScreen = {
	TRANSPORTATION_FEE = 200,
	MAX_ITEMS = 1000,
	CONTROLS = {
		ITEM_TEMPLATE_SOURCE = "itemTemplateSource",
		BALANCE_TITLE = "balanceTitleElement",
		INFO_BOX = "infoBox",
		ANIMAL_ICON = "animalIcon",
		ANIMAL_PRICE = "animalPrice",
		INFO_PRICE_TITLE = "infoPriceTitle",
		HEADER_TARGET = "headerTarget",
		HEADER_SOURCE = "headerSource",
		INFO_SELL_PRICE = "infoSellPrice",
		ITEM_TEMPLATE_TARGET = "itemTemplateTarget",
		BUTTON_APPLY = "buttonApply",
		INFO_BUY_PRICE = "infoBuyPrice",
		LIST_TARGET = "listTarget",
		BALANCE_TEXT = "balanceElement",
		LIST_SOURCE = "listSource",
		INFO_TOTAL = "infoTotal",
		ANIMAL_TITLE = "animalTitle",
		INFO_FEE = "infoFee"
	},
	ITEM_STATE = "state",
	ITEM_ICON = "icon",
	ITEM_NAME = "name",
	ITEM_PRICE = "price"
}
local AnimalScreen_mt = Class(AnimalScreen, ScreenElement)

function AnimalScreen:new(target, custom_mt, animalController, l10n, messageCenter)
	local self = ScreenElement:new(target, custom_mt or AnimalScreen_mt)

	self:registerControls(AnimalScreen.CONTROLS)

	self.l10n = l10n
	self.messageCenter = messageCenter
	self.animalController = animalController

	self.animalController:setSourceUpdateCallback(self.onSourceUpdate, self)
	self.animalController:setTargetUpdateCallback(self.onTargetUpdate, self)
	self.animalController:setNoValidHusbandryCallback(self.onNoValidHusbandry, self)
	self.animalController:setHusbandryIsFullCallback(self.onHusbandryIsFull, self)
	self.animalController:setTrailerFullCallback(self.onTrailerIsFull, self)
	self.animalController:setInvalidAnimalTypeCallback(self.onInvalidAnimalType, self)
	self.animalController:setAnimalNotSupportedByTrailerCallback(self.onAnimalNotSupportedByTrailer, self)
	self.animalController:setNotEnoughMoneyCallback(self.onNotEnoughMoney, self)
	self.animalController:setCanNotAddToTrailerCallback(self.onCanNotAddToTrailer, self)
	self.animalController:setAnimalInUseCallback(self.onAnimalInUse, self)

	self.isSourceSelected = true
	self.isOpen = false
	self.lastBalance = 0
	self.sourceDataSource = GuiDataSource:new()
	self.targetDataSource = GuiDataSource:new()

	return self
end

function AnimalScreen:onOpen()
	AnimalScreen:superClass().onOpen(self)

	self.isOpen = true
	self.isUpdating = false

	g_gameStateManager:setGameState(GameState.MENU_ANIMAL_SHOP)
	g_depthOfFieldManager:setBlurState(true)
	self:updateScreen()

	if self.listSource:getItemCount() > 0 then
		self.listSource:setSelectedIndex(1)
		FocusManager:setFocus(self.listSource)
	elseif self.listTarget:getItemCount() > 0 then
		self.listTarget:setSelectedIndex(1)
		FocusManager:setFocus(self.listTarget)
	end

	self.messageCenter:subscribe(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.onAnimalsChanged, self)
end

function AnimalScreen:onClose(element)
	AnimalScreen:superClass().onClose(self)
	self.animalController:close()

	self.isOpen = false

	g_currentMission:resetGameState()
	self.messageCenter:unsubscribeAll(self)
	g_depthOfFieldManager:setBlurState(false)
end

function AnimalScreen:updateScreen()
	self.animalController:initialize()
	self:updateBalanceText()
	self.sourceDataSource:setData(self.animalController:getSourceItems())
	self:updateListData(self.listSource)
	self.targetDataSource:setData(self.animalController:getTargetItems())
	self:updateListData(self.listTarget)
	self.infoBox:setVisible(self.animalController:getIsDealer())
	self.headerSource:setText(self.animalController:getSourceName())
	self.headerTarget:setText(self.animalController:getTargetName())
	self.listTarget:clearElementSelection()
	FocusManager:unsetFocus(self.listSource)
	FocusManager:setFocus(self.listSource)
	self:updateMoneyCosts()
	self:updateButtons()
	self:updateInfoBox()
end

function AnimalScreen:onGuiSetupFinished()
	AnimalScreen:superClass().onGuiSetupFinished(self)

	function self.listSource.onFocusEnter(_)
		return self:onFocusEnterList(true, self.listSource, self.listTarget)
	end

	function self.listTarget.onFocusEnter(_)
		return self:onFocusEnterList(false, self.listTarget, self.listSource)
	end

	local function assignDataFunction(guiElement, animalItem)
		return self:applyDataToItemRow(guiElement, animalItem)
	end

	self.listSource:setDataSource(self.sourceDataSource)
	self.listSource:setAssignItemDataFunction(assignDataFunction)
	self.listTarget:setDataSource(self.targetDataSource)
	self.listTarget:setAssignItemDataFunction(assignDataFunction)
end

function AnimalScreen:onFocusEnterList(isEnteringSourceList, enteredList, previousList)
	FocusManager:unsetFocus(previousList)
	self:updateInfoBox(isEnteringSourceList)

	self.isSourceSelected = isEnteringSourceList

	if enteredList:getSelectedElementIndex() == 0 then
		enteredList:setSelectedIndex(1)
	end

	if not enteredList.mouseDown then
		enteredList:applyElementSelection()
	end

	previousList:clearElementSelection()
end

function AnimalScreen:updateChangedList(listElement, fallbackListElement, restoreSelection)
	local lastSelectedIndex = self:updateListData(listElement)

	if restoreSelection then
		listElement:setSelectedIndex(lastSelectedIndex)
	else
		listElement:clearElementSelection()
	end

	if listElement:getItemCount() == 0 then
		FocusManager:setFocus(fallbackListElement)
		fallbackListElement:setSelectedIndex(1)
	end

	self:updateInfoBox()
	self:updateMoneyCosts()
	self:updateButtons()
end

function AnimalScreen:onSourceUpdate()
	self:updateChangedList(self.listSource, self.listTarget, self.isSourceSelected)
end

function AnimalScreen:onTargetUpdate()
	self:updateChangedList(self.listTarget, self.listSource, not self.isSourceSelected)
end

function AnimalScreen:onAnimalInUse()
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_ANIMAL_IN_USE),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onNotEnoughMoney()
	if g_currentMission.shopMenu.shopController.inAppPurchaseController:getIsAvailable() then
		g_gui:showYesNoDialog({
			title = self.l10n:getText("ui_buy"),
			text = self.l10n:getText("animals_notEnoughMoney_buyCoins"),
			callback = function (self, yes)
				if yes then
					self:onClickBack()
					g_currentMission.shopMenu:showCoinShop()
				end
			end,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_NO_MONEY),
			dialogType = DialogElement.TYPE_WARNING
		})
	end
end

function AnimalScreen:onNoValidHusbandry(animalSubType)
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_NO_HUSBANDRY),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onInvalidAnimalType(animalSubType)
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_INVALID_ANIMAL),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onAnimalNotSupportedByTrailer(animalSubType)
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_NOT_SUPPORTED_BY_TRAILER),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onHusbandryIsFull()
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_HUSBANDRY_FULL),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onTrailerIsFull()
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_TRAILER_FULL),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onCanNotAddToTrailer()
	g_gui:showInfoDialog({
		text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_CANNOT_ADD_TO_TRAILER),
		dialogType = DialogElement.TYPE_WARNING
	})
end

function AnimalScreen:onVehicleLeftTrigger()
	if self.isOpen then
		g_gui:showInfoDialog({
			text = self.l10n:getText(AnimalScreen.SYMBOL_L10N.ERROR_TRAILER_LEFT),
			callback = self.onClickOkVehicleLeft,
			target = self
		})
	end
end

function AnimalScreen:onClickOkVehicleLeft()
	self:onClickBack()
end

function AnimalScreen:onAnimalsChanged()
	if not self.isUpdating then
		self:updateScreen()
	end
end

function AnimalScreen:onClickBack()
	AnimalScreen:superClass().onClickBack(self)
	self:changeScreen(nil)
end

function AnimalScreen:onClickOk()
	AnimalScreen:superClass().onClickOk(self)

	if self.isSourceSelected then
		self.animalController:moveToTarget(self.listSource.selectedIndex)
	else
		self.animalController:moveToSource(self.listTarget.selectedIndex)
	end

	self.sourceDataSource:notifyChange()
	self.targetDataSource:notifyChange()
end

function AnimalScreen:onClickActivate()
	local hasChanges = self.animalController:getHasChanges()

	if hasChanges then
		self.isUpdating = true

		if self.animalController:applyChanges() then
			self:changeScreen(nil)
		end

		return false
	end

	return true
end

function AnimalScreen:onSourceListSelectionChanged(itemIndex)
	if self.listTarget.selectedIndex ~= 0 and itemIndex ~= 0 then
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self.listSource)
		self:setSoundSuppressed(false)
	end

	self:updateInfoBox(true)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function AnimalScreen:onTargetListSelectionChanged(itemIndex)
	if self.listSource.selectedIndex ~= 0 and itemIndex ~= 0 then
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self.listTarget)
		self:setSoundSuppressed(false)
	end

	self:updateInfoBox(false)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function AnimalScreen:onSourceListDoubleClick(itemIndex)
	self.animalController:moveToTarget(itemIndex)
end

function AnimalScreen:onTargetListDoubleClick(itemIndex)
	self.animalController:moveToSource(itemIndex)
end

function AnimalScreen:update(dt)
	AnimalScreen:superClass().update(self, dt)

	local balance = self.animalController:getBalance()

	if self.lastBalance ~= balance then
		self:updateBalanceText()
	end
end

function AnimalScreen:getController()
	return self.animalController
end

function AnimalScreen:updateBalanceText()
	local balance = self.animalController:getBalance()
	self.lastBalance = balance

	self.balanceElement:setText(self.l10n:formatMoney(balance, 0, true, true), true)

	if balance > 0 then
		self.balanceElement:applyProfile(AnimalScreen.PROFILE.POSITIVE_BALANCE)
	else
		self.balanceElement:applyProfile(AnimalScreen.PROFILE.NEGATIVE_BALANCE)
	end

	if not GS_IS_MOBILE_VERSION then
		self.balanceTitleElement:setPosition(self.balanceElement.position[1] - self.balanceElement.margin[3] - self.balanceElement.size[1], nil)
	end
end

function AnimalScreen:updateMoneyCosts()
	local buyPrice, sellPrice, fee, total = self.animalController:getPrices()

	self.infoBuyPrice:setText(self.l10n:formatMoney(buyPrice, 0, true, false))
	self.infoSellPrice:setText(self.l10n:formatMoney(sellPrice, 0, true, false))
	self.infoFee:setText(self.l10n:formatMoney(fee, 0, true, false))
	self.infoTotal:setText(self.l10n:formatMoney(total, 0, true, false))
end

function AnimalScreen:updateButtons()
	local hasChanges = self.animalController:getHasChanges()

	self.buttonApply:setVisible(hasChanges)
end

function AnimalScreen:updateListData(list)
	local lastSelectedIndex = list:getSelectedDataIndex()

	list:updateItemPositions()

	return lastSelectedIndex
end

function AnimalScreen:applyDataToItemRow(listRow, animalItem)
	local subType = animalItem.subType
	local storeInfo = subType.storeInfo
	local icon = listRow:getDescendantByName(AnimalScreen.ITEM_ICON)

	icon:setImageFilename(subType.fillTypeDesc.hudOverlayFilename)

	local stateLabel = listRow:getDescendantByName(AnimalScreen.ITEM_STATE)
	local stateText = self.l10n:getText("animal_new")

	if animalItem.state == AnimalItem.STATE_STOCK then
		stateText = self.l10n:getText("animal_stock")
	end

	stateLabel:setText(stateText)

	local nameLabel = listRow:getDescendantByName(AnimalScreen.ITEM_NAME)
	local name = animalItem.name

	if animalItem.name == nil then
		name = storeInfo.shopItemName
	end

	nameLabel:setText(name)

	local priceLabel = listRow:getDescendantByName(AnimalScreen.ITEM_PRICE)

	priceLabel:setText(self.l10n:formatMoney(animalItem.price, 0, true, true))
end

function AnimalScreen:updateInfoBox(isSourceSelected)
	if isSourceSelected == nil then
		isSourceSelected = self.isSourceSelected
	end

	local animal = nil

	if isSourceSelected then
		local dataIndex = self.listSource:getSelectedDataIndex()
		animal = self.sourceDataSource:getItem(dataIndex)
	else
		local dataIndex = self.listTarget:getSelectedDataIndex()
		animal = self.targetDataSource:getItem(dataIndex)
	end

	self.animalIcon:setVisible(animal ~= nil)
	self.animalTitle:setVisible(animal ~= nil)
	self.animalPrice:setVisible(animal ~= nil)

	if animal ~= nil then
		local subType = animal.subType
		local storeInfo = subType.storeInfo

		self.animalIcon:setImageFilename(storeInfo.imageFilename)
		self.animalPrice:setText(self.l10n:formatMoney(animal.price, 0, true, true))

		local title = storeInfo.shopItemName

		if animal.name ~= nil then
			title = animal.name
		end

		self.animalTitle:setText(title)
	end
end

AnimalScreen.PROFILE = {
	LIST_ITEM_NEUTRAL = "shopCategoryItem",
	NEGATIVE_BALANCE = "shopMoneyNeg",
	POSITIVE_BALANCE = "shopMoney"
}
AnimalScreen.SYMBOL_L10N = {
	TEXT_SELL = "button_sell",
	ERROR_INVALID_ANIMAL = "animals_invalidAnimalType",
	ERROR_NO_HUSBANDRY = "animals_noHusbandryAvailable",
	TEXT_BUY = "button_buy",
	ERROR_NO_MONEY = "animals_notEnoughMoney",
	ERROR_ANIMAL_IN_USE = "animals_inUse",
	TEXT_UNLOAD = "button_unload",
	ERROR_HUSBANDRY_FULL = "animals_husbandryIsFull",
	ERROR_TRAILER_FULL = "animals_trailerIsFull",
	ERROR_NOT_SUPPORTED_BY_TRAILER = "animals_animalNotSupportedByTrailer",
	ERROR_CANNOT_ADD_TO_TRAILER = "animals_canNotAddToTrailer",
	TEXT_PIECES = "unit_pieces",
	ERROR_TRAILER_LEFT = "animals_transportTargetLeftTrigger",
	TEXT_LOAD = "button_load"
}
