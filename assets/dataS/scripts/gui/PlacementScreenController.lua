PlacementScreenController = {}
local PlacementScreenController_mt = Class(PlacementScreenController)
PlacementScreenController.PLACEMENT_COLLISION_MASK = 4576
PlacementScreenController.MESSAGE = {
	NOT_ENOUGH_SLOTS = 4,
	NOT_ENOUGH_MONEY = 3,
	TOO_MANY_TREES = 5,
	SELL_ITEM = 2,
	SELL_WARNING_INFO = 1
}
PlacementScreenController.MOVE_FACTOR = 0.0625
PlacementScreenController.SNAP_ANGLE = math.rad(7.5)
PlacementScreenController.SNAP_SIZE = 10
PlacementScreenController.SNAP_MOVE_TIME = 1000
PlacementScreenController.DISPLACEMENT_COST_PER_M3 = 5
PlacementScreenController.PLACEMENT_REASON_SUCCESS = 1
PlacementScreenController.PLACEMENT_REASON_NOT_OWNED_FARMLAND = 2
PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_BOUGHT = 3
PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_PLACED_AT_POSITION = 4
PlacementScreenController.PLACEMENT_REASON_PLAYER_COLLISION = 5
PlacementScreenController.PLACEMENT_REASON_OBJECT_COLLISION = 6
PlacementScreenController.PLACEMENT_REASON_RESTRICTED_AREA = 7
PlacementScreenController.PLACEMENT_REASON_SPAWN_PLACE = 8
PlacementScreenController.PLACEMENT_REASON_STORE_PLACE = 9
PlacementScreenController.PLACEMENT_REASON_BLOCKED = 10
PlacementScreenController.PLACEMENT_REASON_DEFORM_FAILED = 11
PlacementScreenController.PLACEMENT_REASON_UNKNOWN = 12
PlacementScreenController.INPUT_CONTEXT_NAME = "PLACEMENT"

local function NO_CALLBACK()
end

function PlacementScreenController:new(l10n, inputManager, placeableTypeManager, topDownCamera)
	local self = setmetatable({}, PlacementScreenController_mt)
	self.l10n = l10n
	self.inputManager = inputManager
	self.placeableTypeManager = placeableTypeManager
	self.camera = topDownCamera
	self.client = nil
	self.currentMission = nil
	self.hud = nil
	self.ingameMap = nil
	self.setMouseModeCallback = NO_CALLBACK
	self.messageDispatchCallback = NO_CALLBACK
	self.exitCallback = NO_CALLBACK
	self.isPaused = false
	self.placeableType = nil
	self.placementItem = nil
	self.placementObj = nil
	self.isSellMode = false
	self.isBuying = false
	self.isSelling = false
	self.mousePosX = 0.5
	self.mousePosY = 0.5
	self.zoomFactor = 1
	self.targetZoomFactor = 1
	self.zoomFactorUpdateDt = 0
	self.placeableRotY = 0
	self.placeableRotationSpeed = 0.0005
	self.placeableMovementSpeed = 0.02
	self.placeableHeightFactor = 1
	self.placeableHeightFactorSpeed = 0.002
	self.cameraRotationSpeed = 0.0005
	self.modifyingTerrain = false
	self.terrainDeform = nil
	self.lastPreviewPosition = {}
	self.isTerrainDeformationPending = false
	self.blockingMap = nil
	self.blockingMapSize = 0
	self.displacementCosts = 0
	self.inputRun = 0
	self.inputSnap = 0
	self.inputRotatePlaceable = 0
	self.inputHeight = 0
	self.inputRotateTime = 0
	self.eventAccept = nil
	self.eventBack = nil
	self.eventRotatePlaceable = nil
	self.eventChangeHeight = nil
	self.eventRun = nil

	return self
end

function PlacementScreenController:setMessageDispatchCallback(callback)
	self.messageDispatchCallback = callback or NO_CALLBACK
end

function PlacementScreenController:setExitCallback(callback)
	self.exitCallback = callback or NO_CALLBACK
end

function PlacementScreenController:setClient(client)
	self.client = client
end

function PlacementScreenController:setCurrentMission(currentMission)
	self.currentMission = currentMission
end

function PlacementScreenController:setHUD(hud)
	self.hud = hud
	self.ingameMap = hud:getIngameMap()
end

function PlacementScreenController:activate()
	self.inputManager:setShowMouseCursor(true)

	self.placeablePositionValid = false

	self:updateSlots()

	if self.placementItem ~= nil and not self.isSellMode then
		local xmlFile = loadXMLFile("TempXML", self.placementItem.xmlFilename)
		self.placeableType = getXMLString(xmlFile, "placeable.placeableType")

		delete(xmlFile)

		if self.placeableType ~= nil then
			self.placeable = PlacementUtil.loadPlaceable(self.placeableType, self.placementItem.xmlFilename, 0, -500, 0, 0, 0, 0, true, AccessHandler.EVERYONE)

			self.placeable:setPlaceablePreviewState(Placeable.PREVIEW_STATE.INVALID)
			self.placeable:setOwnerFarmId(self.currentMission.player.farmId)

			if self.placeable ~= nil then
				if self.placeable.useRandomYRotation then
					self.placeableRotY = math.random() * math.pi * 2

					setRotation(self.placeable.nodeId, 0, self.placeableRotY, 0)
				else
					self.placeableRotY = 0
				end
			end
		end
	end

	self.blockingMap = g_densityMapHeightManager.placementCollisionMap
	self.blockingMapSize = getBitVectorMapSize(self.blockingMap)

	self:registerActionEvents()
	self:initializeCamera()
	self.ingameMap:setTopDownCamera(self.camera)
end

function PlacementScreenController:initializeCamera()
	self.camera:activate()

	if self.placementObj ~= nil and self.isSellMode then
		local x, _, z = getTranslation(self.placementObj.nodeId)

		self.camera:setMapPosition(x, z)
	end
end

function PlacementScreenController:clearPlaceable()
	if self.placeable ~= nil then
		self:cancelTerrainDeformation()
		self.placeable:delete()

		self.placeable = nil
	end
end

function PlacementScreenController:deactivate()
	self.camera:deactivate()
	self.ingameMap:setTopDownCamera(nil)
	self:removeActionEvents()
	self:clearPlaceable()
end

function PlacementScreenController:reset()
	self.camera:reset()
	self.clearPlaceable()
end

function PlacementScreenController:setIsGamePaused(isPaused)
	self.isPaused = isPaused

	if isPaused then
		self.camera:resetInputState()
	end
end

function PlacementScreenController:update(dt)
	if not self.isPaused then
		local raycastSent = false

		if self.camera:hasRotationInput() and not self.isTerrainDeformationPending and self.placeable ~= nil then
			self:raycastPlacement()

			raycastSent = true
		end

		self.camera:update(dt)

		if self.isSellMode then
			self:findSellObjectAt(self.mousePosX, self.mousePosY)
		end

		if not self.isTerrainDeformationPending and self.placeable ~= nil then
			local multiplier = math.max(5 * self.inputRun, 1)

			self:updatePreviewRotation(dt, multiplier)
			self:updatePreviewHeight(dt)

			if not raycastSent then
				self:raycastPlacement()
			end
		end

		self:updateActionEvents()
	end

	self:resetInputState()
end

function PlacementScreenController:updatePreviewRotation(dt, movementMultiplier)
	if self.inputRotateTime > 0 then
		self.inputRotateTime = self.inputRotateTime - dt
	end

	if self.placeable.useManualYRotation and self.inputRotatePlaceable ~= 0 then
		local snapAngle = self.placeable:getRotationSnapAngle()

		if self.inputRotateTime <= 0 then
			if self.inputSnap == 0 and snapAngle == 0 then
				self.placeableRotY = self.placeableRotY - dt * self.inputRotatePlaceable * self.placeableRotationSpeed * movementMultiplier
			else
				if snapAngle == 0 then
					snapAngle = PlacementScreenController.SNAP_ANGLE
				end

				local snapAngle = 1 / math.deg(snapAngle)
				local func = math.floor

				if self.inputRotatePlaceable < 0 then
					func = math.ceil
				end

				local degAngle = math.deg(self.placeableRotY) - self.inputRotatePlaceable * snapAngle
				degAngle = func(degAngle * snapAngle) / snapAngle
				self.placeableRotY = math.rad(degAngle)
				self.inputRotateTime = PlacementScreenController.SNAP_MOVE_TIME
			end
		end

		local _, y, _ = self.placeable:getPlacementRotation(0, self.placeableRotY, 0)
		self.placeableRotY = y

		setRotation(self.placeable.nodeId, 0, self.placeableRotY, 0)
	end
end

function PlacementScreenController:updatePreviewHeight(dt)
	if not self.isSellMode and self.placeable.alignToWorldY and self.inputHeight ~= 0 then
		self.placeableHeightFactor = MathUtil.clamp(self.placeableHeightFactor - dt * self.inputHeight * self.placeableHeightFactorSpeed, 0, 1)
	end
end

function PlacementScreenController:raycastPlacement()
	local previewState = Placeable.PREVIEW_STATE.INVALID
	local positionChecking = not self.placeablePositionValid and self.isTerrainValidationPending

	if positionChecking then
		previewState = Placeable.PREVIEW_STATE.CHECKING
	elseif self.placeablePositionValid then
		previewState = Placeable.PREVIEW_STATE.VALID
	end

	self.placeable:setPlaceablePreviewState(previewState)

	local camX, camY, camZ, dirX, dirY, dirZ = self.camera:getPickRay()

	raycastClosest(camX, camY, camZ, dirX, dirY, dirZ, "onPlacementRaycastHit", 500, self, RaycastUtil.MASK_TERRAIN_PICKING)
end

function PlacementScreenController:acceptSelection()
	if not self.isPaused then
		if self.isSellMode then
			self:findSellObjectAt(self.mousePosX, self.mousePosY)

			if self.foundSellObject ~= nil then
				self.sellObject = self.foundSellObject

				if self.foundSellObjectWarning == nil then
					self:sellWarningInfoOk()
				else
					self.messageDispatchCallback(PlacementScreenController.MESSAGE.SELL_WARNING_INFO, self.foundSellObjectWarning, self.sellWarningInfoOk, self)
				end
			end
		else
			self:buyPlaceable()
		end
	end
end

function PlacementScreenController:sellWarningInfoOk()
	self.messageDispatchCallback(PlacementScreenController.MESSAGE.SELL_ITEM, "", self.onSellCallback, self, self.foundSellObject)

	self.isSelling = true
end

function PlacementScreenController:onSellCallback(yes)
	if yes then
		self:sellPlaceable(self.sellObject)
	else
		self.isSelling = false
	end

	self.sellObject = nil
end

function PlacementScreenController:updateSlots()
	self.currentMission:calculateSlotUsage()

	local price = self.currentMission.economyManager:getBuyPrice(self.placementItem)

	if self.isSellMode then
		price = self.currentMission.economyManager:getSellPrice(self.placementObj)
	end

	self.currentPrice = price
	self.basePrice = price
end

function PlacementScreenController:onPlaceableBought()
	self:updateSlots()

	self.isBuying = false
end

function PlacementScreenController:onPlaceableBuyFailed(hasNoSpace)
	self.isBuying = false
end

function PlacementScreenController:onPlaceableSold(sellPrice)
	self.isSelling = false
end

function PlacementScreenController:onPlaceableSellFailed()
	self.isSelling = false
end

function PlacementScreenController:buyPlaceable()
	if self.isTerrainDeformationPending then
		return
	end

	if self.placeable ~= nil and self.placeablePositionValid and not self.isBuying and not self.isSelling then
		local enoughMoney = self.currentPrice <= g_currentMission:getMoney()
		local enoughSlots = self.currentMission:hasEnoughSlots(self.placementItem)

		if GS_IS_CONSOLE_VERSION and self.placeable:isa(TreePlaceable) and not g_treePlantManager:canPlantTree() then
			self.messageDispatchCallback(PlacementScreenController.MESSAGE.TOO_MANY_TREES, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.WARNING_TOO_MANY_TREES))

			return
		end

		if not enoughMoney then
			self.messageDispatchCallback(PlacementScreenController.MESSAGE.NOT_ENOUGH_MONEY, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY))

			return
		end

		if not enoughSlots then
			self.messageDispatchCallback(PlacementScreenController.MESSAGE.NOT_ENOUGH_SLOTS, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.WARNING_NOT_ENOUGH_SLOTS))

			return
		end

		self.isBuying = true
		local x, y, z = getTranslation(self.placeable.nodeId)
		local rx, ry, rz = getRotation(self.placeable.nodeId)

		if self.placeable.useRandomYRotation then
			self.placeableRotY = math.random() * math.pi * 2

			setRotation(self.placeable.nodeId, 0, self.placeableRotY, 0)
		end

		self.client:getServerConnection():sendEvent(BuyPlaceableEvent:new(self.placementItem.xmlFilename, x, y, z, rx, ry, rz, self.displacementCosts, self.currentMission:getFarmId(), self.modifyingTerrain))

		self.terrainDeform = nil
		self.modifyingTerrain = false
	end
end

function PlacementScreenController:findSellObjectAt(posX, posY)
	self.foundSellObject = nil
	self.foundSellObjectWarning = nil
	local camX, camY, camZ, dirX, dirY, dirZ = self.camera:getPickRay()

	raycastClosest(camX, camY, camZ, dirX, dirY, dirZ, "onSellObjectRaycast", 500, self, PlacementScreenController.PLACEMENT_COLLISION_MASK)
end

function PlacementScreenController:sellPlaceable(placeable)
	if not self.isBuying and self.isSelling then
		self.client:getServerConnection():sendEvent(SellPlaceableEvent:new(placeable))
	end
end

function PlacementScreenController:setPlacementItem(item, isSellMode, obj)
	if self.placeable ~= nil then
		self:cancelTerrainDeformation()
		self.placeable:delete()

		self.placeable = nil
	end

	self.placeableType = nil
	self.placementItem = item
	self.placementObj = obj
	self.isSellMode = isSellMode
	self.lastPreviewPosition[3] = nil
	self.lastPreviewPosition[2] = nil
	self.lastPreviewPosition[1] = nil
end

function PlacementScreenController:calculatePlacementHeight(x, y, z)
	local distX = self.placeable.placementSizeX * 0.5
	local distZ = self.placeable.placementSizeZ * 0.5
	local cosRot = math.cos(self.placeableRotY)
	local sinRot = math.sin(self.placeableRotY)
	local hMax = y
	local hMin = y

	for xi = -distX, distX, distX * 0.25 do
		for zi = -distZ, distZ, distZ * 0.25 do
			local xi2 = cosRot * xi + sinRot * zi
			local zi2 = -sinRot * xi + cosRot * zi
			local h1 = getTerrainHeightAtWorldPos(self.currentMission.terrainRootNode, x + xi2, 0, z + zi2)
			hMax = math.max(hMax, h1)
			hMin = math.min(hMin, h1)
		end
	end

	return MathUtil.lerp(hMin, hMax, self.placeableHeightFactor)
end

function PlacementScreenController:isPlacementValid(placeable, x, y, z, yRot, distance)
	if not placeable:getIsAreaOwned(self.currentMission:getFarmId()) then
		return false, PlacementScreenController.PLACEMENT_REASON_NOT_OWNED_FARMLAND
	end

	if not placeable:canBuy() then
		return false, PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_BOUGHT
	end

	if not placeable:getCanBePlacedAt(x, y, z, distance, self.currentMission:getFarmId()) then
		return false, PlacementScreenController.PLACEMENT_REASON_CANNOT_BE_PLACED_AT_POSITION
	end

	if self.lastPlayerPos ~= nil and PlacementUtil.hasOverlapWithPoint(placeable, x, y, z, yRot, self.lastPlayerPos[1], self.lastPlayerPos[3]) then
		return false, PlacementScreenController.PLACEMENT_REASON_PLAYER_COLLISION
	end

	if PlacementUtil.hasObjectOverlap(placeable, x, y, z, yRot) then
		return false, PlacementScreenController.PLACEMENT_REASON_OBJECT_COLLISION
	end

	if PlacementUtil.isInsideRestrictedZone(self.currentMission.restrictedZones, placeable, x, y, z) then
		return false, PlacementScreenController.PLACEMENT_REASON_RESTRICTED_AREA
	end

	if PlacementUtil.isInsidePlacementPlaces(self.currentMission.loadSpawnPlaces, placeable, x, y, z) then
		return false, PlacementScreenController.PLACEMENT_REASON_SPAWN_PLACE
	end

	if PlacementUtil.isInsidePlacementPlaces(self.currentMission.storeSpawnPlaces, placeable, x, y, z) then
		return false, PlacementScreenController.PLACEMENT_REASON_STORE_PLACE
	end

	return true, PlacementScreenController.PLACEMENT_REASON_SUCCESS
end

function PlacementScreenController:onPlacementRaycastHit(hitObjectId, x, y, z, distance)
	local limit = self.currentMission.terrainSize * 0.5 - GuiTopDownCamera.TERRAIN_BORDER
	z = MathUtil.clamp(z, -limit, limit)
	x = MathUtil.clamp(x, -limit, limit)
	local snapSize = self.placeable:getPositionSnapSize()
	local snapOffset = self.placeable:getPositionSnapOffset()

	if self.inputSnap ~= 0 then
		if snapSize == 0 then
			snapSize = PlacementScreenController.SNAP_SIZE
		end

		snapSize = 1 / snapSize
		x = math.floor(x * snapSize) / snapSize + snapOffset
		z = math.floor(z * snapSize) / snapSize + snapOffset
	end

	local h = self:calculatePlacementHeight(x, y, z)
	x, h, z = self.placeable:getPlacementPosition(x, h, z)
	self.modifyingTerrain = false

	if hitObjectId == self.currentMission.terrainRootNode then
		local isValid, reason = self:isPlacementValid(self.placeable, x, h, z, self.placeableRotY, distance)

		if isValid then
			if not self.placeable.requireLeveling then
				self.placeablePositionValid = true
			else
				self.modifyingTerrain = true
			end
		else
			self.placeablePositionValid = false
			self.invalidPositionReason = reason
		end
	else
		self.placeablePositionValid = false
		self.invalidPositionReason = nil
	end

	local positionChanged = self.lastPreviewPosition[1] ~= x or self.lastPreviewPosition[2] ~= h or self.lastPreviewPosition[3] ~= z

	if positionChanged then
		self.lastPreviewPosition[3] = z
		self.lastPreviewPosition[2] = h
		self.lastPreviewPosition[1] = x

		setTranslation(self.placeable.nodeId, x, h, z)

		if self.modifyingTerrain then
			self.placeablePositionValid = false
			self.invalidPositionReason = nil

			self:startPlacementTerrainValidation()
		end
	end
end

function PlacementScreenController:startPlacementTerrainValidation()
	if self.terrainDeform then
		self.terrainDeform:cancel()

		self.terrainDeform = nil
	end

	local deform = self.placeable:createDeformationObject(self.currentMission.terrainRootNode)
	self.terrainDeform = deform
	self.isTerrainValidationPending = true

	g_terrainDeformationQueue:queueJob(deform, true, "onTerrainValidationFinished", self)
end

function PlacementScreenController:onTerrainValidationFinished(errorCode, displacedVolume, blockedObjectName)
	self.placeablePositionValid = errorCode == TerrainDeformation.STATE_SUCCESS

	if errorCode == TerrainDeformation.STATE_FAILED_BLOCKED then
		self.invalidPositionReason = PlacementScreenController.PLACEMENT_REASON_BLOCKED
	elseif errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT then
		self.invalidPositionReason = PlacementScreenController.PLACEMENT_REASON_OBJECT_COLLISION
	elseif errorCode == TerrainDeformation.STATE_FAILED_TO_DEFORM then
		self.invalidPositionReason = PlacementScreenController.PLACEMENT_REASON_DEFORM_FAILED
	elseif errorCode ~= TerrainDeformation.STATE_SUCCESS then
		self.invalidPositionReason = PlacementScreenController.PLACEMENT_REASON_UNKNOWN
	end

	self.currentPrice = self.basePrice + displacedVolume * PlacementScreenController.DISPLACEMENT_COST_PER_M3
	self.displacementCosts = displacedVolume * PlacementScreenController.DISPLACEMENT_COST_PER_M3

	if errorCode ~= TerrainDeformation.STATE_SUCCESS then
		self.terrainDeform = nil
	end

	self.isTerrainValidationPending = false
end

function PlacementScreenController:cancelTerrainDeformation()
	if self.terrainDeform then
		self.terrainDeform:cancel()

		self.terrainDeform = nil
		self.isTerrainDeformationPending = false
		self.isTerrainValidationPending = false
	end
end

function PlacementScreenController:onSellObjectRaycast(hitObjectId, x, y, z, distance)
	local object = self.currentMission:getNodeObject(hitObjectId)

	if object ~= nil and object.configFileName ~= nil and object.configFileName:lower() == self.placementItem.xmlFilename:lower() then
		local canBeSold, warning = object:canBeSold()

		if canBeSold then
			if warning ~= nil then
				self.foundSellObjectWarning = warning
			end

			if g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), object, false) then
				self.foundSellObject = object
			else
				self.foundSellObjectWarning = self.l10n:getText(PlacementScreenController.L10N_SYMBOL.WARNING_NOT_OWNED)
			end
		end
	end
end

function PlacementScreenController:canBuy()
	if self.placeable == nil then
		return false
	end

	return self.placeable:canBuy()
end

function PlacementScreenController:canPlace()
	return self.placeablePositionValid, self.invalidPositionReason
end

function PlacementScreenController:mouseEvent(posX, posY, isDown, isUp, button)
	if not self.isPaused then
		self.camera:mouseEvent(posX, posY, isDown, isUp, button)
	end
end

function PlacementScreenController:resetInputState()
	self.inputRun = 0
	self.inputRotatePlaceable = 0
	self.inputHeight = 0
end

function PlacementScreenController:registerActionEvents()
	self.inputManager:setContext(PlacementScreenController.INPUT_CONTEXT_NAME)

	local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.acceptSelection, false, true, false, true)

	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_HIGH)

	self.eventAccept = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_BACK, self, self.onMenuBack, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.BUTTON_BACK))
	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_HIGH)

	self.eventBack = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_RUN, self, self.onInputRun, false, false, true, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_PLACEMENT_ROTATE_OBJECT, self, self.onRotatePlaceable, true, true, true, false)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.ACTION_ROTATE_OBJECT))

	self.eventRotatePlaceable = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.SNAP_PLACEABLE, self, self.onInputSnap, false, false, true, true)
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_PLACEMENT_CHANGE_HEIGHT, self, self.onChangePlaceableHeight, false, false, true, false)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(PlacementScreenController.L10N_SYMBOL.ACTION_PLACEMENT_HEIGHT))
	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_LOW)

	self.eventChangeHeight = eventId

	self.inputManager:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onToggleInputHelp, false, true, false, true)
	self.camera:showInputHelp()
	self.ingameMap:registerInput()
end

function PlacementScreenController:removeActionEvents()
	self.hud:clearCustomInputHelpEntries()
	self.inputManager:revertContext(true)
end

function PlacementScreenController:updateActionEvents()
	local isAcceptVisible = false

	if self.isSellMode then
		if self.foundSellObject ~= nil then
			local price = self.currentMission.economyManager:getSellPrice(self.foundSellObject)
			local sellText = self.l10n:getText(PlacementScreenController.L10N_SYMBOL.BUTTON_SELL) .. " (" .. self.l10n:formatMoney(price) .. ")"

			self.inputManager:setActionEventText(self.eventAccept, sellText)

			isAcceptVisible = true
		end
	elseif self.placeablePositionValid or self.isTerrainValidationPending then
		local buyText = self.l10n:getText(PlacementScreenController.L10N_SYMBOL.BUTTON_BUY) .. " (" .. self.l10n:formatMoney(self.currentPrice) .. ")"

		self.inputManager:setActionEventText(self.eventAccept, buyText)

		isAcceptVisible = true
	end

	self.inputManager:setActionEventTextVisibility(self.eventAccept, isAcceptVisible)

	local rotationAllowed = not self.isSellMode and self.placeable ~= nil and not not self.placeable.useManualYRotation

	self.inputManager:setActionEventActive(self.eventRotatePlaceable, rotationAllowed)

	local changeHeightAllowed = not self.isSellMode and self.placeable ~= nil and self.placeable.alignToWorldY

	self.inputManager:setActionEventActive(self.eventChangeHeight, changeHeightAllowed)
	self.camera:setMovementActive(not self.isSelling and not self.isBuying)
end

function PlacementScreenController:onMenuBack()
	self.exitCallback()
end

function PlacementScreenController:onToggleInputHelp()
	local isVisible = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)

	g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, isVisible)
end

function PlacementScreenController:onInputRun(_, inputValue)
	self.inputRun = inputValue

	self.camera:onInputRun(_, inputValue)
end

function PlacementScreenController:onInputSnap(_, inputValue)
	self.inputSnap = inputValue
end

function PlacementScreenController:onRotatePlaceable(_, inputValue)
	self.inputRotatePlaceable = inputValue

	if inputValue == 0 then
		self.inputRotateTime = 0
	end
end

function PlacementScreenController:onChangePlaceableHeight(_, inputValue)
	self.inputHeight = inputValue
end

PlacementScreenController.L10N_SYMBOL = {
	ACTION_ROTATE_CAMERA = "action_rotateCamera",
	ACTION_ROTATE_OBJECT = "action_rotate",
	ACTION_RESET_CAMERA = "setting_resetUICamera",
	WARNING_TOO_MANY_TREES = "warning_tooManyTrees",
	ACTION_PLACEMENT_HEIGHT = "action_changePlacementHeight",
	WARNING_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuy",
	ACTION_MOVE = "ui_movePlaceable",
	ACTION_ZOOM = "action_cameraZoom",
	BUTTON_BUY = "button_buy",
	WARNING_NOT_ENOUGH_SLOTS = "shop_messageNotEnoughSlotsToBuy",
	WARNING_NOT_OWNED = "warning_youDontOwnThisItem",
	BUTTON_SELL = "button_sell",
	BUTTON_BACK = "button_back"
}
