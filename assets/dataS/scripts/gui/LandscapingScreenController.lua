LandscapingScreenController = {}
local LandscapingScreenController_mt = Class(LandscapingScreenController)
LandscapingScreenController.INPUT_CONTEXT_NAME = "LANDSCAPING"
LandscapingScreenController.GLOW_MATERIAL_HOLDER_PATH = "$data/shared/materialHolders/glowEffectMaterialHolder.i3d"
LandscapingScreenController.CUBE_INDICATOR_PATH = "$data/store/ui/cube.i3d"
LandscapingScreenController.SPHERE_INDICATOR_PATH = "$data/store/ui/sphere.i3d"
LandscapingScreenController.INDICATOR_SHADER_COLOR_PARAMETER = "colorScale"
LandscapingScreenController.SETTINGS = {
	MODE = 1,
	BRUSH_STRENGTH = 4,
	TERRAIN_MATERIAL = 5,
	BRUSH_SIZE = 3,
	BRUSH_SHAPE = 2
}
LandscapingScreenController.MODE = {
	SCULPTING = "SCULPTING",
	PAINTING = "PAINTING"
}
LandscapingScreenController.START_INPUT_DELAY = 500
LandscapingScreenController.MIN_SCULPT_INTERVAL = 100
LandscapingScreenController.MIN_MOUSE_INPUT_DURATION = 200
LandscapingScreenController.MIN_INPUT_INTERVAL = 100
LandscapingScreenController.SCULPT_STRENGTH_STEP = 0.1
LandscapingScreenController.STRENGTH_STEPS_MIN = 1
LandscapingScreenController.STRENGTH_STEPS_MAX = 30
LandscapingScreenController.RADIUS_STEP = 1
LandscapingScreenController.RADIUS_STEPS_MIN = 1
LandscapingScreenController.RADIUS_STEPS_MAX = 10
LandscapingScreenController.MOUSE_REPOSITION_THRESHOLD = 5
LandscapingScreenController.HIT_MOVE_THRESHOLD = 0.05
LandscapingScreenController.DEFAULT_SCULPTING_OPERATION = Landscaping.OPERATION.SMOOTH
LandscapingScreenController.INDICATOR_COLOR = {
	VALID = {
		0,
		1,
		0,
		1
	},
	INVALID = {
		1,
		0,
		0,
		1
	}
}

function LandscapingScreenController.NO_CALLBACK()
end

function LandscapingScreenController:new(messageCenter, l10n, inputManager, topDownCamera, i3dManager, farmlandManager, groundTypeManager)
	local self = setmetatable({}, LandscapingScreenController_mt)
	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.camera = topDownCamera
	self.i3dManager = i3dManager
	self.farmlandManager = farmlandManager
	self.groundTypeManager = groundTypeManager
	self.hud = nil
	self.ingameMap = nil
	self.terrainRootNode = nil
	self.playerFarm = nil
	self.currentUserId = nil
	self.isMasterUser = false
	self.exitCallback = LandscapingScreenController.NO_CALLBACK
	self.showMessageCallback = LandscapingScreenController.NO_CALLBACK
	self.isPaused = false
	self.mode = LandscapingScreenController.MODE.SCULPTING
	self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
	self.terrainUnit = Landscaping.TERRAIN_UNIT
	self.halfTerrainUnit = Landscaping.TERRAIN_UNIT / 2
	self.groundTypes = {}
	self.combinedTerrainLayers = {}
	self.paintTerrainLayer = 0
	self.isTerrainDeformationPending = false
	self.isValidationPending = false
	self.startInputCooldown = LandscapingScreenController.START_INPUT_DELAY
	self.sculptingCooldown = LandscapingScreenController.MIN_SCULPT_INTERVAL
	self.changeStrengthCooldown = LandscapingScreenController.MIN_INPUT_INTERVAL
	self.radiusSteps = 3
	self.strengthSteps = 1
	self.paintGroundTypeIndex = 1
	self.sculptingOperation = LandscapingScreenController.DEFAULT_SCULPTING_OPERATION
	self.currentRadius = self.radiusSteps * LandscapingScreenController.RADIUS_STEP
	self.currentStrength = self.strengthSteps * LandscapingScreenController.SCULPT_STRENGTH_STEP
	self.currentOutsideSmoothingDistance = self:getOutsideSmoothingDistance()
	self.canModify = true
	self.paintUnlock = false
	self.mouseThresholdX = LandscapingScreenController.MOUSE_REPOSITION_THRESHOLD / g_screenWidth
	self.mouseThresholdY = LandscapingScreenController.MOUSE_REPOSITION_THRESHOLD / g_screenHeight
	self.lastMouseY = 0
	self.lastMouseX = 0
	self.sculptMouseY = 0
	self.sculptMouseX = 0
	self.lastCameraPosition = {
		0,
		0,
		0
	}
	self.lastCameraRotation = 0
	self.positionRaycastUnlock = false
	self.lastHitPosition = {
		0,
		0,
		0
	}
	self.flattenHeight = 0
	self.glowMaterial = nil
	self.indicatorNode = nil
	self.cubeNode = nil
	self.cubeShapeNode = nil
	self.cubeLightNode = nil
	self.sphereNode = nil
	self.sphereShapeNode = nil
	self.sphereLightNode = nil
	self.currentIndicatorShapeNode = nil
	self.currentIndicatorLightNode = nil
	self.inputHelpMode = g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE)
	self.currentInputMode = GS_IS_CONSOLE_VERSION and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD
	self.mousePressedTime = 0
	self.mouseLeftDown = false
	self.mouseRightDown = false
	self.mouseMiddleDown = false
	self.addEventId = nil
	self.subtractEventId = nil
	self.smoothEventId = nil
	self.flattenEventId = nil
	self.flattenReleaseEventId = nil
	self.nextTextureEventId = nil
	self.prevTextureEventId = nil
	self.changeRadiusEventId = nil
	self.changeStrengthEventId = nil

	return self
end

function LandscapingScreenController:delete()
	self:deleteIndicator()

	if self.terrainLayerTextureOverlay ~= nil then
		delete(self.terrainLayerTextureOverlay)
	end
end

function LandscapingScreenController:setClient(client)
	self.client = client
end

function LandscapingScreenController:setHUD(hud)
	self.hud = hud
	self.ingameMap = hud:getIngameMap()
end

function LandscapingScreenController:setTerrainRootNode(terrainRootNode)
	self.terrainRootNode = terrainRootNode
end

function LandscapingScreenController:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

function LandscapingScreenController:setCurrentUserId(userId)
	self.currentUserId = userId
end

function LandscapingScreenController:createTerrainLayerOverlay()
	local terrainLayerTexture = createTerrainLayerTexture(self.terrainRootNode)
	local terrainLayerTextureOverlay = createImageOverlayWithTexture(terrainLayerTexture)

	delete(terrainLayerTexture)

	return terrainLayerTextureOverlay
end

function LandscapingScreenController:onMasterUserAdded(masterUser)
	if masterUser:getId() == self.currentUserId then
		self.isMasterUser = true
	end
end

function LandscapingScreenController:activate()
	self.startInputCooldown = LandscapingScreenController.START_INPUT_DELAY
	self.currentInputMode = self.inputManager:getLastInputMode()
	self.inputHelpMode = self.inputManager:getInputHelpMode()

	self:registerActionEvents()
	self.camera:activate()
	self.camera:setMovementActive(true)

	self.paintUnlock = true

	self:updateIndicatorShape()
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.MODE, self.mode, false)
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_SHAPE, self.brushShape, false)
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_SIZE, self.currentRadius, false)
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_STRENGTH, self.currentStrength, false)
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.TERRAIN_MATERIAL, self.paintTerrainLayer, false)
	self.settingsDataSource:notifyChange()
	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
	self.messageCenter:subscribe(MessageType.INPUT_HELP_MODE_CHANGED, self.onInputHelpModeChanged, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(LandscapingSculptEvent, self.onSculptingFinished, self)
	setVisibility(self.indicatorNode, true)
	self.ingameMap:setTopDownCamera(self.camera)
end

function LandscapingScreenController:activatePostOverlayCreation()
	self:notifyCurrentDisplayLayerChange()
end

function LandscapingScreenController:deactivate()
	self.camera:deactivate()
	self.ingameMap:setTopDownCamera(nil)
	self:removeActionEvents()
	self.messageCenter:unsubscribeAll(self)
	self:updateIndicatorColor(true)

	self.isTerrainDeformationPending = false
	self.isValidationPending = false
	self.sculptingCooldown = LandscapingScreenController.MIN_SCULPT_INTERVAL

	setVisibility(self.indicatorNode, false)
end

function LandscapingScreenController:reset()
	self.camera:reset()
end

function LandscapingScreenController:setExitCallback(callback)
	self.exitCallback = callback or LandscapingScreenController.NO_CALLBACK
end

function LandscapingScreenController:setShowErrorMessageCallback(callback)
	self.showMessageCallback = callback or LandscapingScreenController.NO_CALLBACK
end

function LandscapingScreenController:setSettingsDataSource(dataSource)
	self.settingsDataSource = dataSource
end

function LandscapingScreenController:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self:createIndicator()

	self.groundTypes = {}

	for typeName, layerName in pairs(self.groundTypeManager.groundTypeMappings) do
		table.insert(self.groundTypes, typeName)
	end

	table.sort(self.groundTypes)

	self.combinedTerrainLayers = {}
	local knownLayers = {}

	for _, typeName in ipairs(self.groundTypes) do
		local layer = self.groundTypeManager:getTerrainLayerByType(typeName)

		if not knownLayers[layer] then
			table.insert(self.combinedTerrainLayers, layer)

			knownLayers[layer] = true
		end
	end

	self:notifyCurrentDisplayLayerChange()
end

function LandscapingScreenController:unloadMapData()
	self:deleteIndicator()
end

function LandscapingScreenController:setIsGamePaused(isPaused)
	self.isPaused = isPaused

	if isPaused then
		self.camera:resetInputState()
	end
end

function LandscapingScreenController:hasPlayerPermission()
	local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)

	return userPermissions[Farm.PERMISSION.LANDSCAPING] or self.isMasterUser
end

function LandscapingScreenController:updateCamera(dt)
	self.camera:update(dt)

	local camX, camY, camZ, camRot = self.camera:determineMapPosition()
	local hasCameraMoved = camX ~= self.lastCameraPosition[1] or camY ~= self.lastCameraPosition[2] or camZ ~= self.lastCameraPosition[3] or camRot ~= self.lastCameraRotation
	self.positionRaycastUnlock = self.positionRaycastUnlock or hasCameraMoved
	self.lastCameraRotation = camRot
	self.lastCameraPosition[3] = camZ
	self.lastCameraPosition[2] = camY
	self.lastCameraPosition[1] = camX
end

function LandscapingScreenController:updateIndicatorColor(isValid)
	local color = LandscapingScreenController.INDICATOR_COLOR.VALID

	if not isValid then
		color = LandscapingScreenController.INDICATOR_COLOR.INVALID
	end

	setShaderParameter(self.currentIndicatorShapeNode, LandscapingScreenController.INDICATOR_SHADER_COLOR_PARAMETER, color[1], color[2], color[3], color[4], false)
end

function LandscapingScreenController:update(dt)
	if not self:hasPlayerPermission() then
		g_gui:showInfoDialog({
			text = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_LOST_PERMISSION),
			callback = self.exitCallback
		})

		return
	end

	self.startInputCooldown = self.startInputCooldown - dt
	self.sculptingCooldown = self.sculptingCooldown - dt
	self.changeStrengthCooldown = self.changeStrengthCooldown - dt

	if not self.isPaused then
		self:raycastPosition()
		self:updateCamera(dt)
		self:updateInput(dt)
	end
end

function LandscapingScreenController:onInputModeChanged(inputMode)
	self.currentInputMode = inputMode

	self:updateActionEvents()
end

function LandscapingScreenController:onInputHelpModeChanged(inputHelpMode)
	self.inputHelpMode = inputHelpMode

	self:onInputModeChanged(inputHelpMode)
end

function LandscapingScreenController:updateIndicatorShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		self.currentIndicatorShapeNode = self.cubeShapeNode
		self.currentIndicatorLightNode = self.cubeLightNode

		setVisibility(self.sphereNode, false)
		setVisibility(self.cubeNode, true)
	else
		self.currentIndicatorShapeNode = self.sphereShapeNode
		self.currentIndicatorLightNode = self.sphereLightNode

		setVisibility(self.cubeNode, false)
		setVisibility(self.sphereNode, true)
	end

	local height = self.currentStrength * 2
	local width = self.currentRadius * 2

	setScale(self.cubeShapeNode, width, height, width)
	setScale(self.sphereShapeNode, width, width, width)
	setLightRange(self.currentIndicatorLightNode, width * 2)
end

function LandscapingScreenController:adjustHitPosition(x, y, z)
	local hitX = x
	local hitY = y
	local hitZ = z

	if self.brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		local centerCompensation = self.halfTerrainUnit

		if self.radiusSteps % 2 == 0 then
			centerCompensation = 0
		end

		hitX = math.floor(x / self.terrainUnit) * self.terrainUnit + centerCompensation
		hitY = y
		hitZ = math.floor(z / self.terrainUnit) * self.terrainUnit + centerCompensation
	end

	return hitX, hitY, hitZ
end

function LandscapingScreenController:raycastPosition()
	if not self.isTerrainDeformationPending then
		local camX, camY, camZ, dirX, dirY, dirZ = self.camera:getPickRay()

		raycastClosest(camX, camY, camZ, dirX, dirY, dirZ, "onPositionRaycastHit", 500, self, RaycastUtil.MASK_TERRAIN_PICKING)
	end
end

function LandscapingScreenController:onPositionRaycastHit(hitObjectId, x, y, z, _)
	local hitX, hitY, hitZ = self:adjustHitPosition(x, y, z)

	if hitObjectId == self.terrainRootNode and not self.isTerrainDeformationPending then
		local xMove = self.mouseThresholdX <= math.abs(self.sculptMouseX - self.lastMouseX)
		local yMove = self.mouseThresholdY <= math.abs(self.sculptMouseY - self.lastMouseY)

		if xMove or yMove or self.positionRaycastUnlock then
			self.sculptMouseY = self.lastMouseY
			self.sculptMouseX = self.lastMouseX
			self.positionRaycastUnlock = false
			local hitDelta = math.abs(self.lastHitPosition[1] - hitX) + math.abs(self.lastHitPosition[2] - hitY) + math.abs(self.lastHitPosition[3] - hitZ)
			local hasHitMoved = LandscapingScreenController.HIT_MOVE_THRESHOLD < hitDelta
			self.paintUnlock = self.paintUnlock or hasHitMoved
			self.lastHitPosition[1] = hitX
			self.lastHitPosition[2] = hitY
			self.lastHitPosition[3] = hitZ

			if not self.isValidationPending and self.startInputCooldown <= 0 then
				self:sendSculptingEvent(true, self.sculptingOperation)
			end
		end
	end

	setWorldTranslation(self.indicatorNode, unpack(self.lastHitPosition))
end

function LandscapingScreenController:onSculptingFinished(isValidation, errorCode, displacedVolumeOrArea)
	local success = errorCode == TerrainDeformation.STATE_SUCCESS

	self:updateIndicatorColor(success)

	self.isValidationPending = false
	self.canModify = success

	if not isValidation then
		self.isTerrainDeformationPending = false
		self.sculptingCooldown = success and LandscapingScreenController.MIN_SCULPT_INTERVAL or 0
	end

	if success then
		if not isValidation then
			local currentHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, unpack(self.lastHitPosition))
			self.lastHitPosition[2] = currentHeight

			setWorldTranslation(self.indicatorNode, unpack(self.lastHitPosition))
		end

		self.showMessageCallback("")
	else
		local errorText = ""

		if errorCode == TerrainDeformation.STATE_FAILED_TO_DEFORM then
			errorText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_MODIFICATION_TOO_STEEP)
		elseif errorCode == TerrainDeformation.STATE_FAILED_BLOCKED then
			errorText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_MODIFICATION_BLOCKED)
		elseif errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT then
			errorText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_MODIFICATION_OBSTRUCTED)
		elseif errorCode == TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY then
			errorText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_MODIFICATION_NOT_ENOUGH_MONEY)
		elseif errorCode == TerrainDeformation.STATE_FAILED_NOT_OWNED then
			errorText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.MESSAGE_MODIFICATION_DO_NOT_OWN_LAND)
		end

		self.showMessageCallback(errorText)
	end
end

function LandscapingScreenController:getOutsideSmoothingDistance()
	return self.terrainUnit
end

function LandscapingScreenController:sendSculptingEvent(validateOnly, operation)
	local canValidate = validateOnly and not self.isValidationPending
	local canDeform = self.canModify and self.sculptingCooldown <= 0

	if not self.isTerrainDeformationPending and (canDeform or canValidate) then
		local x, y, z = unpack(self.lastHitPosition)
		local strength = self.currentStrength

		if operation == Landscaping.OPERATION.FLATTEN then
			y = self.flattenHeight
		elseif operation == Landscaping.OPERATION.SMOOTH then
			local min = LandscapingScreenController.STRENGTH_STEPS_MIN
			local max = LandscapingScreenController.STRENGTH_STEPS_MAX
			local normalizedStrength = (self.strengthSteps - min) / (max - min)
			strength = 0.2 + normalizedStrength * 0.8
		end

		self.isTerrainDeformationPending = self.isTerrainDeformationPending or not validateOnly
		self.isValidationPending = self.isValidationPending or validateOnly
		local requestLandscaping = LandscapingSculptEvent:new(validateOnly, operation, x, y, z, self.currentRadius, strength, self.brushShape, self.currentOutsideSmoothingDistance, self.paintTerrainLayer)

		self.client:getServerConnection():sendEvent(requestLandscaping)
	end
end

function LandscapingScreenController:mouseEvent(posX, posY, isDown, isUp, button)
	if not self.isPaused then
		local hasMovedCursor = self.lastMouseX ~= posX or self.lastMouseY ~= posY
		self.lastMouseY = posY
		self.lastMouseX = posX

		if button == Input.MOUSE_BUTTON_LEFT then
			self.mouseLeftDown = not isUp and self.mouseLeftDown or isDown
		end

		if button == Input.MOUSE_BUTTON_RIGHT then
			self.mouseRightDown = not isUp and self.mouseRightDown or isDown
		end

		if button == Input.MOUSE_BUTTON_MIDDLE then
			self.mouseMiddleDown = not isUp and self.mouseMiddleDown or isDown
		end

		self.camera:mouseEvent(posX, posY, isDown, isUp, button)
	else
		self.mouseLeftDown = false
		self.mouseRightDown = false
		self.mouseMiddleDown = false
		self.mousePressedTime = 0
	end

	if isUp then
		if self.mode == LandscapingScreenController.MODE.SCULPTING then
			self.sculptingOperation = LandscapingScreenController.DEFAULT_SCULPTING_OPERATION
		else
			self.sculptingOperation = Landscaping.OPERATION.PAINT
		end

		self.mousePressedTime = 0
	end

	self.camera:setMouseEdgeScrollingActive(not self.mouseLeftDown and not self.mouseRightDown and not self.mouseMiddleDown)

	return true
end

function LandscapingScreenController:updateInput(dt)
	if self.canModify then
		if self.mode == LandscapingScreenController.MODE.SCULPTING then
			if self.mouseRightDown then
				if self.mouseLeftDown and LandscapingScreenController.MIN_MOUSE_INPUT_DURATION <= self.mousePressedTime then
					self:onFlatten()
				elseif LandscapingScreenController.MIN_MOUSE_INPUT_DURATION <= self.mousePressedTime then
					self:onSubtract()
				end
			end

			if self.mouseMiddleDown and LandscapingScreenController.MIN_MOUSE_INPUT_DURATION <= self.mousePressedTime then
				self:onSmooth()
			end
		end

		if self.mouseLeftDown and not self.mouseRightDown then
			local canSculpt = self.mode == LandscapingScreenController.MODE.SCULPTING and LandscapingScreenController.MIN_MOUSE_INPUT_DURATION <= self.mousePressedTime

			if canSculpt or self.mode == LandscapingScreenController.MODE.PAINTING then
				self:onAdd()
			end
		end
	end

	if self.mouseLeftDown or self.mouseRightDown or self.mouseMiddleDown then
		self.mousePressedTime = self.mousePressedTime + dt
	end
end

function LandscapingScreenController:registerActionEvents()
	self.inputManager:setContext(LandscapingScreenController.INPUT_CONTEXT_NAME)

	local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU_BACK, self, self.onMenuBack, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.BUTTON_BACK))
	self.inputManager:setActionEventTextPriority(eventId, GS_PRIO_HIGH)

	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onAdd, false, true, true, true)

	self.inputManager:setActionEventText(eventId, "")

	self.addEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onSubtract, false, true, true, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_SUBTRACT))

	self.subtractEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.SNAP_PLACEABLE, self, self.onFlatten, false, true, true, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_FLATTEN))

	self.flattenEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.SNAP_PLACEABLE, self, self.onFlatten, true, false, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.flattenReleaseEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_CANCEL, self, self.onSmooth, false, true, true, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_SMOOTH))

	self.smoothEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onCycleTexture, false, true, false, true, 1)

	self.inputManager:setActionEventTextVisibility(eventId, true)
	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_CYCLE_TEXTURE))

	self.nextTextureEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onCycleTexture, false, true, false, true, -1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.prevTextureEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_PLACEMENT_ROTATE_OBJECT, self, self.onChangeRadius, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_CHANGE_RADIUS))

	self.changeRadiusEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_PLACEMENT_CHANGE_HEIGHT, self, self.onChangeStrength, false, true, true, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_CHANGE_STRENGTH))

	self.changeStrengthEventId = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_EXTRA_1, self, self.onSwitchMode, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_CHANGE_MODE))

	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_EXTRA_2, self, self.onSwitchShape, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_CHANGE_SHAPE))
	self.inputManager:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onToggleInputHelp, false, true, false, true)
	self.ingameMap:registerInput()
	self:updateActionEvents()
end

function LandscapingScreenController:updateActionEvents()
	local showSculpting = self.mode == LandscapingScreenController.MODE.SCULPTING

	self.inputManager:beginActionEventsModification(LandscapingScreenController.INPUT_CONTEXT_NAME)

	local addText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_ADD)

	if not showSculpting then
		addText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_PAINT)
	end

	self.inputManager:setActionEventText(self.addEventId, addText)

	local activateSculptingButtons = showSculpting and self.currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD

	self.inputManager:setActionEventActive(self.subtractEventId, activateSculptingButtons)
	self.inputManager:setActionEventActive(self.smoothEventId, activateSculptingButtons)
	self.inputManager:setActionEventActive(self.flattenEventId, activateSculptingButtons)
	self.inputManager:setActionEventActive(self.flattenReleaseEventId, activateSculptingButtons)
	self.inputManager:setActionEventActive(self.changeStrengthEventId, showSculpting)
	self.inputManager:setActionEventActive(self.nextTextureEventId, not showSculpting)
	self.inputManager:endActionEventsModification()
	self:updateInputHelp(self.currentInputMode)
end

function LandscapingScreenController:updateInputHelp(currentInputHelpMode)
	self.hud:clearCustomInputHelpEntries()

	local showMouseButtons = self.inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD
	local addText = ""
	local cycleText = ""

	if self.mode == LandscapingScreenController.MODE.SCULPTING then
		addText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_ADD)
	else
		addText = self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_PAINT)
	end

	if showMouseButtons then
		self.hud:addCustomInputHelpEntry(InputAction.MOUSE_ALT_COMMAND_BUTTON, nil, addText, false)

		if self.mode == LandscapingScreenController.MODE.SCULPTING then
			self.hud:addCustomInputHelpEntry(InputAction.MOUSE_ALT_COMMAND2_BUTTON, nil, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_SUBTRACT), false)
			self.hud:addCustomInputHelpEntry(InputAction.MOUSE_ALT_COMMAND3_BUTTON, nil, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_SMOOTH), false)
			self.hud:addCustomInputHelpEntry(InputAction.MOUSE_ALT_COMMAND4_BUTTON, nil, self.l10n:getText(LandscapingScreenController.L10N_SYMBOL.ACTION_FLATTEN), false)
		end
	end

	self.inputManager:beginActionEventsModification(LandscapingScreenController.INPUT_CONTEXT_NAME)
	self.inputManager:setActionEventTextVisibility(self.addEventId, not showMouseButtons)
	self.inputManager:setActionEventTextVisibility(self.subtractEventId, not showMouseButtons and self.mode == LandscapingScreenController.MODE.SCULPTING)
	self.inputManager:setActionEventTextVisibility(self.smoothEventId, not showMouseButtons and self.mode == LandscapingScreenController.MODE.SCULPTING)
	self.inputManager:setActionEventTextVisibility(self.flattenEventId, not showMouseButtons and self.mode == LandscapingScreenController.MODE.SCULPTING)
	self.inputManager:endActionEventsModification()
	self.camera:showInputHelp()
end

function LandscapingScreenController:removeActionEvents()
	self.hud:clearCustomInputHelpEntries()
	self.inputManager:revertContext(true)
end

function LandscapingScreenController:onMenuBack()
	self.isTerrainDeformationPending = false

	self.exitCallback()
end

function LandscapingScreenController:onToggleInputHelp()
	local isVisible = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)

	g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, isVisible)
end

function LandscapingScreenController:onAdd()
	if self.startInputCooldown <= 0 then
		if self.mode == LandscapingScreenController.MODE.SCULPTING then
			self.sculptingOperation = Landscaping.OPERATION.RAISE

			self:sendSculptingEvent(false, Landscaping.OPERATION.RAISE)
		elseif self.paintUnlock then
			self.paintUnlock = false
			self.sculptingOperation = Landscaping.OPERATION.PAINT

			self:sendSculptingEvent(false, Landscaping.OPERATION.PAINT)
		end
	end
end

function LandscapingScreenController:onSubtract()
	if self.startInputCooldown <= 0 then
		self.sculptingOperation = Landscaping.OPERATION.LOWER

		self:sendSculptingEvent(false, Landscaping.OPERATION.LOWER)
	end
end

function LandscapingScreenController:onSmooth()
	if self.startInputCooldown <= 0 then
		self.sculptingOperation = Landscaping.OPERATION.SMOOTH

		self:sendSculptingEvent(false, Landscaping.OPERATION.SMOOTH)
	end
end

function LandscapingScreenController:onFlatten(_, inputValue)
	if inputValue == nil then
		inputValue = 1
	end

	if inputValue == 0 and self.sculptingOperation == Landscaping.OPERATION.FLATTEN then
		self.sculptingOperation = LandscapingScreenController.DEFAULT_SCULPTING_OPERATION
	elseif self.startInputCooldown <= 0 then
		if self.sculptingOperation ~= Landscaping.OPERATION.FLATTEN then
			self.flattenHeight = self.lastHitPosition[2]
		end

		self.sculptingOperation = Landscaping.OPERATION.FLATTEN

		self:sendSculptingEvent(false, Landscaping.OPERATION.FLATTEN)
	end
end

function LandscapingScreenController:onCycleTexture(_, _, direction)
	self.paintGroundTypeIndex = self.paintGroundTypeIndex + direction

	if self.paintGroundTypeIndex > #self.combinedTerrainLayers then
		self.paintGroundTypeIndex = 1
	elseif self.paintGroundTypeIndex < 1 then
		self.paintGroundTypeIndex = #self.combinedTerrainLayers
	end

	self:notifyCurrentDisplayLayerChange()

	self.paintUnlock = true
end

function LandscapingScreenController:notifyCurrentDisplayLayerChange()
	local layer = self.combinedTerrainLayers[self.paintGroundTypeIndex]
	self.paintTerrainLayer = layer
	local displayLayer = getTerrainLayerSubLayer(self.terrainRootNode, layer, 0)

	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.TERRAIN_MATERIAL, displayLayer, true)
end

function LandscapingScreenController:getStepsChangeFromInput(inputValue, currentSteps, minSteps, maxSteps)
	local direction = 0

	if inputValue > 0 then
		direction = 1
	elseif inputValue < 0 then
		direction = -1
	end

	return MathUtil.clamp(currentSteps + direction, minSteps, maxSteps)
end

function LandscapingScreenController:onChangeRadius(_, inputValue)
	self.radiusSteps = self:getStepsChangeFromInput(inputValue, self.radiusSteps, LandscapingScreenController.RADIUS_STEPS_MIN, LandscapingScreenController.RADIUS_STEPS_MAX)
	self.currentRadius = self.radiusSteps * LandscapingScreenController.RADIUS_STEP
	self.currentOutsideSmoothingDistance = self:getOutsideSmoothingDistance()
	self.positionRaycastUnlock = true
	self.paintUnlock = true

	self:updateIndicatorShape()
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_SIZE, self.currentRadius, true)
end

function LandscapingScreenController:onChangeStrength(_, inputValue)
	if self.changeStrengthCooldown <= 0 then
		self.changeStrengthCooldown = LandscapingScreenController.MIN_INPUT_INTERVAL
		self.strengthSteps = self:getStepsChangeFromInput(-inputValue, self.strengthSteps, LandscapingScreenController.STRENGTH_STEPS_MIN, LandscapingScreenController.STRENGTH_STEPS_MAX)
		self.currentStrength = self.strengthSteps * LandscapingScreenController.SCULPT_STRENGTH_STEP
		self.currentOutsideSmoothingDistance = self:getOutsideSmoothingDistance()

		self:updateIndicatorShape()
		self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_STRENGTH, self.currentStrength, true)
	end
end

function LandscapingScreenController:onSwitchShape()
	if self.brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		self.brushShape = Landscaping.BRUSH_SHAPE.CIRCLE
	else
		self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	end

	self:updateIndicatorShape()
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.BRUSH_SHAPE, self.brushShape, true)
end

function LandscapingScreenController:onSwitchMode()
	if self.mode == LandscapingScreenController.MODE.SCULPTING then
		self.mode = LandscapingScreenController.MODE.PAINTING
		self.sculptingOperation = Landscaping.OPERATION.PAINT
	elseif self.mode == LandscapingScreenController.MODE.PAINTING then
		self.mode = LandscapingScreenController.MODE.SCULPTING
		self.sculptingOperation = Landscaping.OPERATION.RAISE
	end

	self:updateActionEvents()
	self.settingsDataSource:setItem(LandscapingScreenController.SETTINGS.MODE, self.mode, true)
end

function LandscapingScreenController:createIndicator()
	self.indicatorNode = createTransformGroup("Indicator")

	link(getRootNode(), self.indicatorNode)
	self.i3dManager:loadSharedI3DFile(LandscapingScreenController.GLOW_MATERIAL_HOLDER_PATH, nil, false, true, true, self.onGlowMaterialLoaded, self)
	self.i3dManager:loadSharedI3DFile(LandscapingScreenController.CUBE_INDICATOR_PATH, nil, false, true, true, self.onCubeLoaded, self)
	self.i3dManager:loadSharedI3DFile(LandscapingScreenController.SPHERE_INDICATOR_PATH, nil, false, true, true, self.onSphereLoaded, self)
end

function LandscapingScreenController:deleteIndicator()
	if self.indicatorNode ~= nil then
		delete(self.indicatorNode)

		self.indicatorNode = nil

		self.i3dManager:releaseSharedI3DFile(LandscapingScreenController.CUBE_INDICATOR_PATH)
		self.i3dManager:releaseSharedI3DFile(LandscapingScreenController.SPHERE_INDICATOR_PATH)
		self.i3dManager:releaseSharedI3DFile(LandscapingScreenController.GLOW_MATERIAL_HOLDER_PATH)
	end
end

function LandscapingScreenController:onGlowMaterialLoaded(holderId)
	if holderId ~= 0 then
		local shapeNode = getChildAt(holderId, 0)

		if getHasShaderParameter(shapeNode, LandscapingScreenController.INDICATOR_SHADER_COLOR_PARAMETER) then
			self.glowMaterial = getMaterial(shapeNode, 0)
		else
			g_logManager:devError("Could not get material with required shader parameter '%s' from material holder asset '%s'.", LandscapingScreenController.INDICATOR_SHADER_COLOR_PARAMETER, LandscapingScreenController.GLOW_MATERIAL_HOLDER_PATH)
		end
	end
end

function LandscapingScreenController:setUpIndicator(loadedIndicatorNode, assignAsDefault)
	setTranslation(loadedIndicatorNode, 0, 0, 0)
	link(self.indicatorNode, loadedIndicatorNode)
	setVisibility(loadedIndicatorNode, assignAsDefault)

	local shapeNode = LandscapingScreenController.getIndicatorComponent(loadedIndicatorNode, ClassIds.SHAPE)
	local lightNode = LandscapingScreenController.getIndicatorComponent(loadedIndicatorNode, ClassIds.LIGHT_SOURCE)

	setMaterial(shapeNode, self.glowMaterial, 0)

	local color = LandscapingScreenController.INDICATOR_COLOR.VALID

	setShaderParameter(shapeNode, LandscapingScreenController.INDICATOR_SHADER_COLOR_PARAMETER, color[1], color[2], color[3], color[4], false)
	setLightRange(lightNode, self.currentRadius)

	if assignAsDefault then
		self.currentIndicatorShapeNode = shapeNode
		self.currentIndicatorLightNode = lightNode
	end

	return shapeNode, lightNode
end

function LandscapingScreenController:onCubeLoaded(cubeNodeId)
	self.cubeNode = cubeNodeId
	self.cubeShapeNode, self.cubeLightNode = self:setUpIndicator(cubeNodeId, self.brushShape == Landscaping.BRUSH_SHAPE.SQUARE)
end

function LandscapingScreenController:onSphereLoaded(sphereNodeId)
	self.sphereNode = sphereNodeId
	self.sphereShapeNode, self.sphereLightNode = self:setUpIndicator(sphereNodeId, self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE)
end

function LandscapingScreenController.getIndicatorComponent(indicatorNode, componentClassId)
	if getHasClassId(indicatorNode, componentClassId) then
		return indicatorNode
	else
		local numChildren = getNumOfChildren(indicatorNode)
		local childShapeNode = nil

		for i = 0, numChildren - 1 do
			local childNode = getChildAt(indicatorNode, i)
			childShapeNode = LandscapingScreenController.getIndicatorComponent(childNode, componentClassId)

			if childShapeNode ~= nil then
				return childShapeNode
			end
		end
	end

	return nil
end

LandscapingScreenController.L10N_SYMBOL = {
	ACTION_FLATTEN = "action_terrainFlatten",
	ACTION_CHANGE_MODE = "action_terrainChangeMode",
	ACTION_CHANGE_SHAPE = "action_terrainChangeShape",
	MESSAGE_MODIFICATION_BLOCKED = "ui_landscaping_cannotModifyHere",
	ACTION_CHANGE_STRENGTH = "action_terrainChangeStrength",
	MESSAGE_MODIFICATION_TOO_STEEP = "ui_landscaping_tooSteep",
	ACTION_ADD = "action_terrainRaise",
	MESSAGE_MODIFICATION_NOT_ENOUGH_MONEY = "ui_landscaping_notEnoughMoney",
	BUTTON_BACK = "button_back",
	ACTION_SMOOTH = "action_terrainSmooth",
	ACTION_CYCLE_TEXTURE = "action_terrainCycleGroundType",
	MESSAGE_LOST_PERMISSION = "ui_permissions_lostLandscaping",
	MESSAGE_MODIFICATION_OBSTRUCTED = "ui_landscaping_objectObstructed",
	MESSAGE_MODIFICATION_DO_NOT_OWN_LAND = "ui_landscaping_doNotOwnLand",
	ACTION_SUBTRACT = "action_terrainLower",
	ACTION_CHANGE_RADIUS = "action_terrainChangeRadius",
	ACTION_PAINT = "action_terrainPaint"
}
