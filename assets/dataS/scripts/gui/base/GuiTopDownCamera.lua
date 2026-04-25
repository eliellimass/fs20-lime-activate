GuiTopDownCamera = {}
local GuiTopDownCamera_mt = Class(GuiTopDownCamera)
GuiTopDownCamera.TERRAIN_BORDER = 40
GuiTopDownCamera.INPUT_MOVE_FACTOR = 0.0625
GuiTopDownCamera.MOVE_SPEED = 0.02
GuiTopDownCamera.ROTATION_SPEED = 0.0005
GuiTopDownCamera.ROTATION_MIN_X = 15
GuiTopDownCamera.ROTATION_RANGE_X = 15
GuiTopDownCamera.DISTANCE_MIN_Z = -10
GuiTopDownCamera.DISTANCE_RANGE_Z = -60
GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = 2

function GuiTopDownCamera:new(subclass_mt, messageCenter, l10n, inputManager)
	local self = setmetatable({}, subclass_mt or GuiTopDownCamera_mt)
	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.controlledPlayer = nil
	self.controlledVehicle = nil
	self.hud = nil
	self.terrainRootNode = nil
	self.waterLevelHeight = 0
	self.terrainSize = 0
	self.previousCamera = nil
	self.camera, self.cameraBaseNode = self:createCameraNodes()
	self.isActive = false
	self.cameraX = 0
	self.cameraZ = 0
	self.cameraRotY = math.rad(45)
	self.cameraTransformInitialized = false
	self.isMouseEdgeScrollingActive = true
	self.isMouseMode = false
	self.mousePosX = 0.5
	self.mousePosY = 0.5
	self.zoomFactor = 1
	self.targetZoomFactor = 1
	self.zoomFactorUpdateDt = 0
	self.lastPlayerPos = {
		0,
		0,
		0
	}
	self.lastPlayerTerrainHeight = 0
	self.inputZoom = 0
	self.inputZoomAnalog = false
	self.inputMoveSide = 0
	self.inputMoveForward = 0
	self.inputRun = 0
	self.inputRotate = 0
	self.eventMoveSide = nil
	self.eventMoveForward = nil
	self.eventRotateCamera = nil

	return self
end

function GuiTopDownCamera:createCameraNodes()
	local camera = createCamera("TopDownCamera", math.rad(60), 1, 4000)
	local cameraBaseNode = createTransformGroup("topDownCameraBaseNode")

	link(cameraBaseNode, camera)
	setRotation(camera, 0, math.rad(180), 0)
	setTranslation(camera, 0, 0, -5)
	setRotation(cameraBaseNode, 0, 0, 0)
	setTranslation(cameraBaseNode, 0, 110, 0)

	return camera, cameraBaseNode
end

function GuiTopDownCamera:delete()
	self:deactivate()
	delete(self.cameraBaseNode)

	self.cameraBaseNode = nil
	self.camera = nil
end

function GuiTopDownCamera:reset()
	self.cameraTransformInitialized = false
	self.controlledPlayer = nil
	self.controlledVehicle = nil
	self.hud = nil
	self.terrainRootNode = nil
	self.waterLevelHeight = 0
	self.terrainSize = 0
	self.previousCamera = nil
end

function GuiTopDownCamera:setTerrainRootNode(terrainRootNode)
	self.terrainRootNode = terrainRootNode
	self.terrainSize = getTerrainSize(self.terrainRootNode)
end

function GuiTopDownCamera:setHUD(hud)
	self.hud = hud
end

function GuiTopDownCamera:setWaterLevelHeight(waterLevelHeight)
	self.waterLevelHeight = waterLevelHeight
end

function GuiTopDownCamera:setControlledPlayer(player)
	self.controlledPlayer = player
	self.controlledVehicle = nil
end

function GuiTopDownCamera:setControlledVehicle(vehicle)
	self.controlledVehicle = vehicle
	self.controlledPlayer = nil
end

function GuiTopDownCamera:activate()
	self.inputManager:setShowMouseCursor(true)
	self:onInputModeChanged(self.inputManager:getLastInputMode())
	self:updatePosition()

	self.previousCamera = getCamera()

	setCamera(self.camera)

	if self.controlledPlayer ~= nil then
		local x, y, z = getTranslation(self.controlledPlayer.rootNode)
		self.lastPlayerPos[3] = z
		self.lastPlayerPos[2] = y
		self.lastPlayerPos[1] = x
		self.lastPlayerTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, x, 0, z)

		self.controlledPlayer:onLeave()
	end

	if not self.cameraTransformInitialized then
		self:resetToPlayer()

		self.cameraTransformInitialized = true
	end

	self:registerActionEvents()
	self.messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

	self.isActive = true
end

function GuiTopDownCamera:deactivate()
	self.isActive = false

	self.messageCenter:unsubscribeAll(self)
	self:removeActionEvents()

	local showCursor = self.controlledPlayer == nil and self.controlledVehicle == nil

	self.inputManager:setShowMouseCursor(showCursor)

	if self.controlledPlayer ~= nil then
		local x, y, z = unpack(self.lastPlayerPos)
		local currentPlayerTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, x, 0, z)
		local deltaTerrainHeight = currentPlayerTerrainHeight - self.lastPlayerTerrainHeight

		if deltaTerrainHeight > 0 then
			y = y + deltaTerrainHeight
		end

		self.controlledPlayer:moveRootNodeToAbsolute(x, y, z)
		self.controlledPlayer:onEnter(true)
	end

	if self.previousCamera ~= nil then
		setCamera(self.previousCamera)

		self.previousCamera = nil
	end
end

function GuiTopDownCamera:getIsActive()
	return self.isActive
end

function GuiTopDownCamera:setMapPosition(mapX, mapZ)
	self.cameraZ = mapZ
	self.cameraX = mapX

	self:updatePosition()
end

function GuiTopDownCamera:resetToPlayer()
	local playerX = 0
	local playerZ = 0

	if self.controlledPlayer ~= nil then
		playerZ = self.lastPlayerPos[3]
		playerX = self.lastPlayerPos[1]
	elseif self.controlledVehicle ~= nil then
		local _ = nil
		playerX, _, playerZ = getTranslation(self.controlledVehicle.rootNode)
	end

	self:setMapPosition(playerX, playerZ)
end

function GuiTopDownCamera:determineMapPosition()
	return self.cameraX, 0, self.cameraZ, self.cameraRotY - math.rad(180)
end

function GuiTopDownCamera:getPickRay()
	return RaycastUtil.getCameraPickingRay(self.mousePosX, self.mousePosY, self.camera)
end

function GuiTopDownCamera:hasRotationInput()
	return self.inputRotate ~= 0
end

function GuiTopDownCamera:updatePosition()
	local samplingGridStep = 2
	local cameraTargetHeight = self.waterLevelHeight

	for x = -samplingGridStep, samplingGridStep, samplingGridStep do
		for z = -samplingGridStep, samplingGridStep, samplingGridStep do
			local sampleTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, self.cameraX + x, 0, self.cameraZ + z)
			cameraTargetHeight = math.max(cameraTargetHeight, sampleTerrainHeight)
		end
	end

	local rotationX = math.rad(GuiTopDownCamera.ROTATION_MIN_X + self.zoomFactor * GuiTopDownCamera.ROTATION_RANGE_X)
	local cameraZ = GuiTopDownCamera.DISTANCE_MIN_Z + self.zoomFactor * GuiTopDownCamera.DISTANCE_RANGE_Z

	setTranslation(self.camera, 0, 0, cameraZ)
	setRotation(self.cameraBaseNode, rotationX, self.cameraRotY, 0)
	setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight, self.cameraZ)

	local cameraX, cameraY, cameraZ = getWorldTranslation(self.camera)
	local terrainHeight = self.waterLevelHeight

	for x = -samplingGridStep, samplingGridStep, samplingGridStep do
		for z = -samplingGridStep, samplingGridStep, samplingGridStep do
			local sampleTerrainHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, cameraX + x, 0, cameraZ + z)
			terrainHeight = math.max(terrainHeight, sampleTerrainHeight)
		end
	end

	if cameraY < terrainHeight + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y then
		cameraTargetHeight = cameraTargetHeight + terrainHeight - cameraY + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y

		setTranslation(self.cameraBaseNode, self.cameraX, cameraTargetHeight, self.cameraZ)
	end
end

function GuiTopDownCamera:applyMovement(moveX, moveZ, movementMultiplier, dt)
	local dirX = math.sin(self.cameraRotY) * moveZ + math.cos(self.cameraRotY) * -moveX
	local dirZ = math.cos(self.cameraRotY) * moveZ - math.sin(self.cameraRotY) * -moveX
	local limit = self.terrainSize * 0.5 - GuiTopDownCamera.TERRAIN_BORDER
	local moveFactor = dt * GuiTopDownCamera.MOVE_SPEED * movementMultiplier
	self.cameraX = MathUtil.clamp(self.cameraX + dirX * moveFactor, -limit, limit)
	self.cameraZ = MathUtil.clamp(self.cameraZ + dirZ * moveFactor, -limit, limit)
	self.zoomFactorUpdateDt = self.zoomFactorUpdateDt + dt

	while self.zoomFactorUpdateDt > 30 do
		self.zoomFactorUpdateDt = self.zoomFactorUpdateDt - 30
		self.zoomFactor = MathUtil.clamp(0, 1, self.zoomFactor * 0.9 + self.targetZoomFactor * 0.1)
	end
end

function GuiTopDownCamera:setMouseEdgeScrollingActive(isActive)
	self.isMouseEdgeScrollingActive = isActive
end

function GuiTopDownCamera:getMouseEdgeScrollingMovement()
	local moveMarginStartX = 0.1374
	local moveMarginEndX = 0.075
	local moveMarginStartY = 0.147
	local moveMarginEndY = 0.075
	local moveX = 0
	local moveZ = 0

	if self.mousePosX >= 1 - moveMarginStartX then
		moveX = math.min((moveMarginStartX - (1 - self.mousePosX)) / (moveMarginStartX - moveMarginEndX), 1)
	elseif self.mousePosX <= moveMarginStartX then
		moveX = -math.min((moveMarginStartX - self.mousePosX) / (moveMarginStartX - moveMarginEndX), 1)
	end

	if self.mousePosY >= 1 - moveMarginStartY then
		moveZ = math.min((moveMarginStartY - (1 - self.mousePosY)) / (moveMarginStartY - moveMarginEndY), 1)
	elseif self.mousePosY <= moveMarginStartY then
		moveZ = -math.min((moveMarginStartY - self.mousePosY) / (moveMarginStartY - moveMarginEndY), 1)
	end

	return moveX, moveZ
end

function GuiTopDownCamera:update(dt)
	local multiplier = math.max(5 * self.inputRun, 1)

	self:updateMovement(dt, multiplier)
	self:resetInputState()
end

function GuiTopDownCamera:updateMovement(dt, movementMultiplier)
	local zoomTimeFactor = self.inputZoomAnalog and 0.002 * dt or 0.2
	local zoomChange = self.targetZoomFactor - self.inputZoom * zoomTimeFactor

	if self.inputZoom < 0 then
		self.targetZoomFactor = math.min(zoomChange, 1)
	elseif self.inputZoom > 0 then
		self.targetZoomFactor = math.max(zoomChange, 0)
	end

	local moveX = self.inputMoveSide * dt
	local moveZ = -self.inputMoveForward * dt
	local hasViewChanged = false

	if self.inputRotate ~= 0 then
		local rotChange = dt * self.inputRotate * GuiTopDownCamera.ROTATION_SPEED * movementMultiplier
		self.cameraRotY = self.cameraRotY + rotChange
		hasViewChanged = true
	end

	if moveX == 0 and moveZ == 0 and self.isMouseEdgeScrollingActive then
		moveX, moveZ = self:getMouseEdgeScrollingMovement()
	end

	if hasViewChanged or moveX ~= 0 or moveZ ~= 0 or math.abs(self.zoomFactor - self.targetZoomFactor) > 0.001 then
		self:applyMovement(moveX, moveZ, movementMultiplier, dt)

		hasViewChanged = true
	end

	if hasViewChanged then
		self:updatePosition()
	end
end

function GuiTopDownCamera:mouseEvent(posX, posY, isDown, isUp, button)
	if self.isMouseMode then
		self.mousePosX = posX
		self.mousePosY = posY
	end
end

function GuiTopDownCamera:resetInputState()
	self.inputZoom = 0
	self.inputZoomAnalog = false
	self.inputMoveSide = 0
	self.inputMoveForward = 0
	self.inputRun = 0
	self.inputRotate = 0
end

function GuiTopDownCamera:registerActionEvents()
	local _, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onMoveSide, false, false, true, false)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.eventMoveSide = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onMoveForward, false, false, true, false)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	self.eventMoveForward = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_RUN, self, self.onInputRun, false, false, true, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.AXIS_PLACEMENT_ROTATE_CAMERA, self, self.onRotate, false, false, true, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(GuiTopDownCamera.L10N_SYMBOL.ACTION_ROTATE_CAMERA))

	self.eventRotateCamera = eventId
	_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.resetToPlayer, false, true, false, true)

	self.inputManager:setActionEventText(eventId, self.l10n:getText(GuiTopDownCamera.L10N_SYMBOL.ACTION_RESET_CAMERA))

	_, eventId = self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_IN, self, self.onZoom, false, false, true, true, 1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_OUT, self, self.onZoom, false, false, true, true, -1)

	self.inputManager:setActionEventTextVisibility(eventId, false)
end

function GuiTopDownCamera:showInputHelp()
	self.hud:addCustomInputHelpEntry(InputAction.AXIS_MOVE_SIDE_PLAYER, InputAction.AXIS_MOVE_FORWARD_PLAYER, self.l10n:getText(GuiTopDownCamera.L10N_SYMBOL.ACTION_MOVE), true)
	self.hud:addCustomInputHelpEntry(InputAction.CAMERA_ZOOM_IN, InputAction.CAMERA_ZOOM_OUT, self.l10n:getText(GuiTopDownCamera.L10N_SYMBOL.ACTION_ZOOM), true)
end

function GuiTopDownCamera:removeActionEvents()
	self.inputManager:removeActionEventsByTarget(self)
end

function GuiTopDownCamera:setMovementActive(isActive)
	self.inputManager:setActionEventActive(self.eventMoveSide, isActive)
	self.inputManager:setActionEventActive(self.eventMoveForward, isActive)
end

function GuiTopDownCamera:onZoom(_, inputValue, direction, isAnalog, isMouse)
	self.inputZoomAnalog = isAnalog

	if inputValue ~= 0 then
		local change = 0.2 * direction

		if isAnalog then
			change = change * 0.01
		elseif isMouse then
			change = change * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end

		self.inputZoom = change
	end
end

function GuiTopDownCamera:onMoveSide(_, inputValue)
	self.inputMoveSide = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR
end

function GuiTopDownCamera:onMoveForward(_, inputValue)
	self.inputMoveForward = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR
end

function GuiTopDownCamera:onInputRun(_, inputValue)
	self.inputRun = inputValue
end

function GuiTopDownCamera:onRotate(_, inputValue)
	self.inputRotate = inputValue
end

function GuiTopDownCamera:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode == GS_INPUT_HELP_MODE_KEYBOARD

	if not self.isMouseMode then
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	end
end

GuiTopDownCamera.L10N_SYMBOL = {
	ACTION_ROTATE_OBJECT = "action_rotate",
	ACTION_RESET_CAMERA = "setting_resetUICamera",
	ACTION_ZOOM = "action_cameraZoom",
	ACTION_MOVE = "ui_movePlaceable",
	ACTION_ROTATE_CAMERA = "action_rotateCamera"
}
