PlacementScreen = {}
local PlacementScreen_mt = Class(PlacementScreen, ScreenElement)
PlacementScreen.CONTROLS = {
	CROSSHAIR_ELEMENT = "crossHairElement",
	MESSAGE_TEXT = "messageText"
}

function PlacementScreen:new(target, custom_mt, messageCenter, inputManager, placementController)
	local self = ScreenElement:new(target, custom_mt or PlacementScreen_mt)

	self:registerControls(PlacementScreen.CONTROLS)

	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.controller = placementController

	local function messageDispatchCallback(messageId, text, callback, callbackTarget, object)
		self:handleControllerMessage(messageId, text, callback, callbackTarget, object)
	end

	local function exitCallback()
		self:onClickBack()
	end

	self.controller:setMessageDispatchCallback(messageDispatchCallback)
	self.controller:setExitCallback(exitCallback)

	self.returnScreenClass = ShopMenu
	self.isDown = false
	self.messageTextSpeed = 500
	self.messageTextTime = 0
	self.messageTextColorDirection = 1
	self.messageTextColor1 = {
		1,
		1,
		1,
		1
	}
	self.messageTextColor2 = {
		1,
		1,
		1,
		1
	}
	self.placementReasonTexts = {
		[PlacementScreenController.PLACEMENT_REASON_SUCCESS] = "",
		[PlacementScreenController.PLACEMENT_REASON_NOT_OWNED_FARMLAND] = g_i18n:getText("warning_youDontOwnThisLand"),
		[PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_BOUGHT] = g_i18n:getText("warning_placeable_error_cannotBeBought"),
		[PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_PLACED_AT_POSITION] = g_i18n:getText("warning_placeable_error_cannotBePlacedAtPosition"),
		[PlacementScreenController.PLACEMENT_REASON_PLAYER_COLLISION] = g_i18n:getText("warning_placeable_error_collisionWithPlayer"),
		[PlacementScreenController.PLACEMENT_REASON_OBJECT_COLLISION] = g_i18n:getText("warning_placeable_error_collisionWithObject"),
		[PlacementScreenController.PLACEMENT_REASON_RESTRICTED_AREA] = g_i18n:getText("warning_placeable_error_restrictedArea"),
		[PlacementScreenController.PLACEMENT_REASON_SPAWN_PLACE] = g_i18n:getText("warning_placeable_error_spawnPlace"),
		[PlacementScreenController.PLACEMENT_REASON_STORE_PLACE] = g_i18n:getText("warning_placeable_error_storePlace"),
		[PlacementScreenController.PLACEMENT_REASON_BLOCKED] = g_i18n:getText("warning_placeable_error_blockedTerrain"),
		[PlacementScreenController.PLACEMENT_REASON_DEFORM_FAILED] = g_i18n:getText("warning_placeable_error_deformationFailed"),
		[PlacementScreenController.PLACEMENT_REASON_UNKNOWN] = g_i18n:getText("warning_placeable_error_unkown")
	}
	self.placeablePositionInvalidWarningTime = 0
	self.showMessageForceTime = 0

	messageCenter:subscribe(BuyPlaceableEvent, self.onPlaceableBuyEvent, self)
	messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableSellEvent, self)

	return self
end

function PlacementScreen:mouseEvent(posX, posY, isDown, isUp, button)
	PlacementScreen:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)

	if button == Input.MOUSE_BUTTON_LEFT then
		if isDown then
			self.isDown = true
		end

		if self.isDown and isUp then
			self.isDown = false

			self:onClickOk()
		end
	end

	self.controller:mouseEvent(posX, posY, isDown, isUp, button)
end

function PlacementScreen:updateMessageText(dt)
	if self.messageText.text ~= "" then
		self.messageTextTime = self.messageTextTime + self.messageTextColorDirection * dt

		if self.messageTextSpeed < self.messageTextTime then
			self.messageTextTime = self.messageTextSpeed
			self.messageTextColorDirection = -self.messageTextColorDirection
		end

		if self.messageTextTime < 0 then
			self.messageTextTime = 0
			self.messageTextColorDirection = -self.messageTextColorDirection
		end

		local messageTextColorAlpha = self.messageTextTime / self.messageTextSpeed

		for i = 1, 4 do
			self.messageText.textColor[i] = (1 - messageTextColorAlpha) * self.messageTextColor1[i] + self.messageTextColor2[i] * messageTextColorAlpha
		end
	end

	self.showMessageForceTime = self.showMessageForceTime - dt
	local placeablePositionInvalidWarningTimeLimit = 2000
	local canBuy, reason = self.controller:canBuy()

	if not canBuy then
		self.messageTextColor1 = {
			1,
			1,
			0.25,
			1
		}
		self.messageTextColor2 = {
			0.75,
			0,
			0,
			1
		}

		self.messageText:setText(reason or g_i18n:getText("warning_tooManyPlaceables"))
	else
		local canBePlaced, reason = self.controller:canPlace()

		if not canBePlaced then
			self.placeablePositionInvalidWarningTime = self.placeablePositionInvalidWarningTime + dt

			if placeablePositionInvalidWarningTimeLimit < self.placeablePositionInvalidWarningTime then
				self.messageTextColor1 = {
					1,
					1,
					0.25,
					1
				}
				self.messageTextColor2 = {
					0.75,
					0,
					0,
					1
				}

				self.messageText:setText(self.placementReasonTexts[reason or PlacementScreenController.PLACEMENT_REASON_UNKNOWN])
			end
		else
			if self.showMessageForceTime <= 0 then
				self.messageText:setText("")
			end

			self.placeablePositionInvalidWarningTime = 0
		end
	end
end

function PlacementScreen:update(dt)
	PlacementScreen:superClass().update(self, dt)

	if not self.isSellMode then
		self:updateMessageText(dt)
	end

	self.controller:update(dt)
end

function PlacementScreen:draw()
	PlacementScreen:superClass().draw(self)
	g_currentMission:addHelpButtonText(g_i18n:getText("button_back"), InputAction.MENU_CANCEL)

	if self.isSellMode then
		if self.foundSellObject ~= nil then
			local price = g_currentMission.economyManager:getSellPrice(self.foundSellObject)
			local sellText = g_i18n:getText("button_sell") .. " (" .. g_i18n:formatMoney(price) .. ")"

			g_currentMission:addHelpButtonText(sellText, InputAction.MENU_ACCEPT)
		end
	elseif self.placeablePositionValid then
		local buyText = g_i18n:getText("button_buy") .. " (" .. g_i18n:formatMoney(self.currentPrice) .. ")"

		g_currentMission:addHelpButtonText(buyText, InputAction.MENU_ACCEPT)
	end
end

function PlacementScreen:setPlacementItem(item, isSellMode, obj)
	self.isSellMode = isSellMode

	self.controller:setPlacementItem(item, isSellMode, obj)
end

function PlacementScreen:onOpen(element)
	PlacementScreen:superClass().onOpen(self, element)
	self.messageText:setText("")
	self.controller:activate()
	self:onInputModeChanged(self.inputManager:getLastInputMode())
	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
end

function PlacementScreen:onClose(element)
	PlacementScreen:superClass().onClose(self, element)
	self.messageCenter:unsubscribe(MessageType.INPUT_MODE_CHANGED, self)
	self.controller:deactivate()
end

function PlacementScreen:reset()
	PlacementScreen:superClass().reset(self)
	self.controller:reset()
end

function PlacementScreen:onClickOk()
	PlacementScreen:superClass().onClickOk(self)
	self.controller:acceptSelection()
end

function PlacementScreen:onPlaceableBuyEvent(errorCode)
	if errorCode == BuyPlaceableEvent.STATE_SUCCESS then
		self:onPlaceableBought()
	else
		self:onPlaceableBuyFailed(errorCode == BuyPlaceableEvent.STATE_NO_SPACE)
	end
end

function PlacementScreen:onPlaceableBought()
	self.controller:onPlaceableBought()
end

function PlacementScreen:onPlaceableBuyFailed(hasNoSpace)
	self.messageTextColor1 = {
		1,
		1,
		0.25,
		1
	}
	self.messageTextColor2 = {
		0.75,
		0,
		0,
		1
	}
	self.showMessageForceTime = 1000

	if hasNoSpace then
		self.messageText:setText(self.placementReasonTexts[PlacementScreenController.PLACEMENT_REASON_UNKNOWN])
	else
		self.messageText:setText(g_i18n:getText("shop_messageFailedToLoadObject"))
	end

	self.controller:onPlaceableBuyFailed(hasNoSpace)
end

function PlacementScreen:onPlaceableSellEvent(errorCode, sellPrice)
	if errorCode == SellPlaceableEvent.STATE_SUCCESS then
		self:onPlaceableSold(sellPrice)
	else
		self:onPlaceableSellFailed()
	end
end

function PlacementScreen:onPlaceableSold(sellPrice)
	if g_gui.currentGuiName == "PlacementScreen" then
		self.controller:onPlaceableSold(sellPrice)
	end
end

function PlacementScreen:onPlaceableSellFailed()
	if g_gui.currentGuiName == "PlacementScreen" then
		self.controller:onPlaceableSellFailed()
	end
end

function PlacementScreen:onInfoDialogClick()
end

function PlacementScreen:onInputModeChanged(inputMode)
	local isMouseMode = inputMode == GS_INPUT_HELP_MODE_KEYBOARD

	self.crossHairElement:setVisible(not isMouseMode)
end

function PlacementScreen:handleControllerMessage(messageId, text, callback, callbackTarget, object)
	local dialogArguments = {
		text = text or "",
		callback = callback or self.onInfoDialogClick,
		target = callbackTarget or self
	}

	if messageId == PlacementScreenController.MESSAGE.SELL_WARNING_INFO then
		g_gui:showInfoDialog(dialogArguments)
	elseif messageId == PlacementScreenController.MESSAGE.SELL_ITEM then
		dialogArguments.item = object
		dialogArguments.price = g_currentMission.economyManager:getSellPrice(object)

		g_gui:showSellItemDialog(dialogArguments)
	elseif messageId == PlacementScreenController.MESSAGE.NOT_ENOUGH_MONEY then
		g_gui:showInfoDialog(dialogArguments)
	elseif messageId == PlacementScreenController.MESSAGE.NOT_ENOUGH_SLOTS then
		g_gui:showInfoDialog(dialogArguments)
	elseif messageId == PlacementScreenController.MESSAGE.TOO_MANY_TREES then
		g_gui:showInfoDialog(dialogArguments)
	end
end
