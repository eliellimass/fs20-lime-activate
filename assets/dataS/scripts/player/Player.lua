Player = {}
local Player_mt = Class(Player, Object)

InitStaticObjectClass(Player, "Player", ObjectIds.OBJECT_PLAYER)

Player.COLLISIONMASK_TRIGGER = 1048576
Player.kinematicCollisionMask = 2148532228.0
Player.movementCollisionMask = 2148532255.0
Player.MAX_PICKABLE_OBJECT_MASS = 0.2
Player.MAX_PICKABLE_OBJECT_DISTANCE = 3
Player.PICKED_UP_OBJECTS = {}
Player.INPUT_CONTEXT_NAME = "PLAYER"
Player.BUTTONSTATES = {
	JUST_PRESSED = 1,
	RELEASED = 3,
	PRESSED = 2
}
Player.INPUT_ACTIVE_TYPE = {
	STARTS_ENABLED = 2,
	IS_CARRYING = 4,
	IS_MOVEMENT = 3,
	STARTS_DISABLED = 1,
	IS_DEBUG = 5
}

function Player:new(isServer, isClient)
	local self = Object:new(isServer, isClient, Player_mt)
	self.isControlled = false
	self.isOwner = false
	self.isEntered = false
	self.debugFlightModeWalkingSpeed = 0.016
	self.debugFlightModeRunningFactor = 1
	self.networkInformation = {
		creatorConnection = nil,
		history = {},
		index = 0
	}

	if self.isServer then
		self.networkInformation.sendIndex = 0
	end

	self.networkInformation.interpolationTime = InterpolationTime:new(1.2)
	self.networkInformation.interpolatorPosition = InterpolatorPosition:new(0, 0, 0)
	self.networkInformation.interpolatorQuaternion = InterpolatorQuaternion:new(0, 0, 0, 1)
	self.networkInformation.interpolatorOnGround = InterpolatorValue:new(0)
	self.networkInformation.tickTranslation = {
		0,
		0,
		0
	}
	self.networkInformation.dirtyFlag = self:getNextDirtyFlag()
	self.networkInformation.updateTargetTranslationPhysicsIndex = -1
	self.networkInformation.rotateObject = false
	self.networkInformation.rotateObjectInputV = 0
	self.networkInformation.rotateObjectInputH = 0
	self.motionInformation = {
		damping = 0.8,
		mass = 80,
		maxAcceleration = 50,
		maxDeceleration = 50
	}
	self.motionInformation.inverseMass = 1 / self.motionInformation.mass
	self.motionInformation.gravity = -9.8
	self.motionInformation.maxIdleSpeed = 0.1
	self.motionInformation.maxWalkingSpeed = 4
	self.motionInformation.maxRunningSpeed = 9
	self.motionInformation.maxSwimmingSpeed = 3
	self.motionInformation.maxCrouchingSpeed = 2
	self.motionInformation.maxFallingSpeed = 6
	self.motionInformation.maxCheatRunningSpeed = 34
	self.motionInformation.maxPresentationRunningSpeed = 128
	self.motionInformation.maxSpeedDelay = 0.1
	self.motionInformation.brakeDelay = 0.001
	self.motionInformation.brakeForce = {
		0,
		0,
		0
	}
	self.motionInformation.currentGroundSpeed = 0
	self.motionInformation.minimumFallingSpeed = -1e-05
	self.motionInformation.coveredGroundDistance = 0
	self.motionInformation.currentCoveredGroundDistance = 0
	self.motionInformation.justMoved = false
	self.motionInformation.isBraking = false
	self.motionInformation.lastSpeed = 0
	self.motionInformation.currentSpeed = 0
	self.motionInformation.currentSpeedY = 0
	self.motionInformation.isReverse = false
	self.motionInformation.desiredSpeed = 0
	self.motionInformation.jumpHeight = 1.5
	self.motionInformation.currentWorldDirX = 0
	self.motionInformation.currentWorldDirZ = 1
	self.motionInformation.currentSpeedX = 0
	self.motionInformation.currentSpeedZ = 0
	self.baseInformation = {
		lastPositionX = 0,
		lastPositionZ = 0,
		isOnGround = true,
		isOnGroundPhysics = true,
		isCloseToGround = true,
		isInWater = false,
		wasInWater = false,
		waterLevel = -1.4,
		waterCameraOffset = 0.3,
		currentWaterCameraOffset = 0,
		plungedInWater = false,
		plungedYVelocityThreshold = -2,
		isInDebug = false,
		capsuleHeight = 0,
		capsuleRadius = 0,
		tagOffset = {
			0,
			1.9,
			0
		},
		translationAlphaDifference = 0,
		animDt = 0,
		isCrouched = false,
		isUsingChainsawHorizontal = false,
		isUsingChainsawVertical = false,
		currentHandtool = nil,
		capsuleTotalHeight = 0,
		headBobTime = 0,
		lastCameraAmplitudeScale = 0
	}
	self.lastEstimatedForwardVelocity = 0
	self.inputInformation = {
		moveForward = 0,
		moveRight = 0,
		moveUp = 0,
		pitchCamera = 0,
		yawCamera = 0,
		runAxis = 0,
		crouchState = Player.BUTTONSTATES.RELEASED,
		interactState = Player.BUTTONSTATES.RELEASED,
		registrationList = {}
	}
	self.inputInformation.registrationList[InputAction.AXIS_MOVE_SIDE_PLAYER] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputMoveSide,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.AXIS_MOVE_FORWARD_PLAYER] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputMoveForward,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputLookLeftRight,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.AXIS_LOOK_UPDOWN_PLAYER] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputLookUpDown,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.AXIS_RUN] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputRun,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.JUMP] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		triggerUp = false,
		callback = self.onInputJump,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT,
		textVisibility = GS_IS_CONSOLE_VERSION
	}
	self.inputInformation.registrationList[InputAction.CROUCH] = {
		text = "",
		triggerAlways = true,
		triggerDown = true,
		eventId = "",
		triggerUp = false,
		callback = self.onInputCrouch,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT,
		textVisibility = GS_IS_CONSOLE_VERSION
	}
	self.inputInformation.registrationList[InputAction.ACTIVATE_OBJECT] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = true,
		triggerUp = false,
		callback = self.onInputActivateObject,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT
	}
	self.inputInformation.registrationList[InputAction.ROTATE_OBJECT_LEFT_RIGHT] = {
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = true,
		triggerUp = false,
		callback = self.onInputRotateObjectHorizontally,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_CARRYING,
		text = g_i18n:getText("action_rotateObjectHorizontally")
	}
	self.inputInformation.registrationList[InputAction.ROTATE_OBJECT_UP_DOWN] = {
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = true,
		triggerUp = false,
		callback = self.onInputRotateObjectVertically,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_CARRYING,
		text = g_i18n:getText("action_rotateObjectVertically")
	}
	self.inputInformation.registrationList[InputAction.ENTER] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputEnter,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_ENABLED
	}
	self.inputInformation.registrationList[InputAction.TOGGLE_LIGHTS_FPS] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputToggleLight,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_ENABLED
	}
	self.inputInformation.registrationList[InputAction.THROW_OBJECT] = {
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = true,
		triggerUp = false,
		callback = self.onInputThrowObject,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED,
		text = g_i18n:getText("input_THROW_OBJECT")
	}
	self.inputInformation.registrationList[InputAction.INTERACT] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = true,
		triggerUp = true,
		callback = self.onInputInteract,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED
	}
	self.inputInformation.registrationList[InputAction.NEXT_HANDTOOL] = {
		triggerAlways = false,
		textVisibility = false,
		eventId = "",
		triggerUp = false,
		callbackState = 1,
		triggerDown = true,
		callback = self.onInputCycleHandTool,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED,
		text = g_i18n:getText("input_NEXT_HANDTOOL")
	}
	self.inputInformation.registrationList[InputAction.PREVIOUS_HANDTOOL] = {
		triggerAlways = false,
		textVisibility = false,
		eventId = "",
		triggerUp = false,
		callbackState = -1,
		triggerDown = true,
		callback = self.onInputCycleHandTool,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED,
		text = g_i18n:getText("input_PREVIOUS_HANDTOOL")
	}
	self.inputInformation.registrationList[InputAction.DEBUG_PLAYER_ENABLE] = {
		text = "",
		triggerAlways = false,
		triggerDown = true,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputDebugFlyToggle,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_DEBUG
	}
	self.inputInformation.registrationList[InputAction.DEBUG_PLAYER_UP_DOWN] = {
		text = "",
		triggerAlways = true,
		triggerDown = false,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputDebugFlyUpDown,
		activeType = Player.INPUT_ACTIVE_TYPE.IS_DEBUG
	}
	self.inputInformation.registrationList[InputAction.ACTIVATE_HANDTOOL] = {
		triggerAlways = true,
		triggerDown = true,
		eventId = "",
		textVisibility = false,
		triggerUp = false,
		callback = self.onInputActivateHandtool,
		activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED,
		text = g_i18n:getText("input_ACTIVATE_HANDTOOL")
	}
	self.soundInformation = {
		samples = {}
	}
	self.soundInformation.samples.swim = {}
	self.soundInformation.samples.plunge = {}
	self.soundInformation.samples.horseBrush = {}
	self.soundInformation.samples.handtoolStop = {}
	self.soundInformation.deleteHandtoolStopSampleAfterPlay = false
	self.soundInformation.distancePerFootstep = {
		crouch = 0.5,
		walk = 0.75,
		run = 1.5
	}
	self.soundInformation.distanceSinceLastFootstep = 0
	self.particleSystemsInformation = {
		systems = {}
	}
	self.particleSystemsInformation.systems.swim = {}
	self.particleSystemsInformation.systems.plunge = {}
	self.particleSystemsInformation.swimNode = 0
	self.particleSystemsInformation.plungeNode = 0
	self.animationInformation = {
		player = 0,
		parameters = {}
	}
	self.animationInformation.parameters.forwardVelocity = {
		value = 0,
		id = 1,
		type = 1
	}
	self.animationInformation.parameters.verticalVelocity = {
		value = 0,
		id = 2,
		type = 1
	}
	self.animationInformation.parameters.yawVelocity = {
		value = 0,
		id = 3,
		type = 1
	}
	self.animationInformation.parameters.absYawVelocity = {
		value = 0,
		id = 4,
		type = 1
	}
	self.animationInformation.parameters.onGround = {
		value = false,
		id = 5,
		type = 0
	}
	self.animationInformation.parameters.inWater = {
		value = false,
		id = 6,
		type = 0
	}
	self.animationInformation.parameters.isCrouched = {
		value = false,
		id = 7,
		type = 0
	}
	self.animationInformation.parameters.absForwardVelocity = {
		value = 0,
		id = 8,
		type = 1
	}
	self.animationInformation.parameters.isCloseToGround = {
		value = false,
		id = 9,
		type = 0
	}
	self.animationInformation.parameters.isUsingChainsawHorizontal = {
		value = false,
		id = 10,
		type = 0
	}
	self.animationInformation.parameters.isUsingChainsawVertical = {
		value = false,
		id = 11,
		type = 0
	}
	self.visualInformation = nil
	self.animationInformation.oldYaw = 0
	self.animationInformation.newYaw = 0
	self.animationInformation.estimatedYawVelocity = 0
	self.walkingIsLocked = false
	self.canRideAnimal = false
	self.canEnterVehicle = false
	self.isLightActive = false
	self.rotX = 0
	self.rotY = 0
	self.cameraRotY = 0
	self.graphicsRotY = 0
	self.targetGraphicsRotY = 0
	self.camera = 0
	self.time = 0
	self.lightNode = nil
	self.clipDistance = 500
	self.lastAnimPosX = 0
	self.lastAnimPosY = 0
	self.lastAnimPosZ = 0
	self.walkDistance = 0
	self.animUpdateTime = 0
	self.debugFlightMode = false
	self.debugFlightCoolDown = 0
	self.requestedFieldData = false
	self.playerStateMachine = PlayerStateMachine:new(self)
	self.farmId = FarmManager.SPECTATOR_FARM_ID

	return self
end

function Player:loadVisuals(xmlFilename, playerStyle, linkNode, isRealPlayer, ikChains, getParentFunc, getParentFuncTarget, parentObj)
	self.xmlFilename = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = loadXMLFile("TempXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local filename = getXMLString(xmlFile, "player.filename")
	self.filename = Utils.getFilename(filename, self.baseDirectory)
	local rootNode = g_i3DManager:loadSharedI3DFile(self.filename, nil, , true)
	self.graphicsRootNode = createTransformGroup("player_graphicsRootNode")

	if isRealPlayer then
		self.cameraNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.camera#index"))

		if self.cameraNode == nil then
			g_logManager:devError("Error: Failed to find player camera in '%s'", self.filename)
		end

		self.camX, self.camY, self.camZ = getTranslation(self.cameraNode)

		setNearClip(self.cameraNode, 0.15)
		setFarClip(self.cameraNode, 6000)

		self.fovY = calculateFovY(self.cameraNode)

		setFovY(self.cameraNode, self.fovY)

		self.animRootThirdPerson = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#animRootNode"))

		if self.animRootThirdPerson == nil then
			g_logManager:devError("Error: Failed to find animation root node in '%s'", self.filename)
		end

		self.baseInformation.capsuleHeight = getXMLFloat(xmlFile, "player.character#physicsCapsuleHeight")
		self.baseInformation.capsuleRadius = getXMLFloat(xmlFile, "player.character#physicsCapsuleRadius")
		self.baseInformation.capsuleTotalHeight = self.baseInformation.capsuleHeight + 2 * self.baseInformation.capsuleRadius
		self.cuttingCameraNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.firstPerson#cuttingCameraNode"))

		setNearClip(self.cuttingCameraNode, 0.15)
		setFarClip(self.cuttingCameraNode, 6000)

		self.fovY = calculateFovY(self.cuttingCameraNode)

		setFovY(self.cuttingCameraNode, self.fovY)
	end

	self.visualInformation = PlayerStyle:new()

	self.visualInformation:copySelection(playerStyle)
	self.visualInformation:loadXML(self, rootNode, xmlFile, "player.character")

	self.skeletonThirdPerson = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#skeleton"))

	if self.skeletonThirdPerson == nil then
		g_logManager:devError("Error: Failed to find skeleton root node in '%s'", self.filename)
	end

	self.meshThirdPerson = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#mesh"))

	if self.meshThirdPerson == nil then
		g_logManager:devError("Error: Failed to find player mesh in '%s'", self.filename)
	end

	if self.meshThirdPerson ~= nil then
		setVisibility(self.meshThirdPerson, false)
		setClipDistance(self.meshThirdPerson, 200)
	end

	self.thirdPersonSpineNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#spine"))
	self.thirdPersonSuspensionNode = Utils.getNoNil(I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#suspension")), self.thirdPersonSpineNode)
	self.thirdPersonRightHandNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#rightHandNode"))
	self.thirdPersonLeftHandNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#leftHandNode"))
	self.thirdPersonHeadNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#headNode"))
	self.lightNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.light#index"))

	if self.lightNode ~= nil then
		setVisibility(self.lightNode, false)
	end

	self.pickUpKinematicHelperNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.pickUpKinematicHelper#index"))

	if self.pickUpKinematicHelperNode ~= nil then
		self.pickUpKinematicHelperNodeChild = createTransformGroup("pickUpKinematicHelperNodeChild")

		link(self.pickUpKinematicHelperNode, self.pickUpKinematicHelperNodeChild)
	end

	local i = 0

	while true do
		local key = string.format("player.ikChains.ikChain(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		IKUtil.loadIKChain(xmlFile, key, rootNode, rootNode, ikChains)

		i = i + 1
	end

	IKUtil.setIKChainInactive(ikChains, "spine")

	if isRealPlayer then
		IKUtil.deleteIKChain(ikChains, "rightFoot")
		IKUtil.deleteIKChain(ikChains, "leftFoot")
		IKUtil.deleteIKChain(ikChains, "rightArm")
		IKUtil.deleteIKChain(ikChains, "leftArm")
		IKUtil.deleteIKChain(ikChains, "spine")
	end

	if self.meshThirdPerson ~= nil then
		link(getRootNode(), self.meshThirdPerson)
	end

	if isRealPlayer then
		self.chainsawCameraFocus = createTransformGroup("player_chainsawCameraFocus")
		self.chainsawSplitShapeFocus = createTransformGroup("player_chainsawSplitShapeFocus")

		link(self.cameraNode, self.chainsawCameraFocus)
		link(self.chainsawCameraFocus, self.chainsawSplitShapeFocus)

		local cutFocusOffset = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.firstPerson#cutFocusOffset"), "0 0 -1"), 3)

		setTranslation(self.chainsawSplitShapeFocus, unpack(cutFocusOffset))

		local cutFocusRotation = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.firstPerson#cutFocusRotation"), "0 0 0"), 3)
		local rotX2, rotY2, rotZ2 = unpack(cutFocusRotation)

		setRotation(self.chainsawSplitShapeFocus, math.rad(rotX2), math.rad(rotY2), math.rad(rotZ2))

		self.minCutDistance = Utils.getNoNil(getXMLFloat(xmlFile, "player.character.firstPerson#minCutDistance"), 0.5)
		self.maxCutDistance = Utils.getNoNil(getXMLFloat(xmlFile, "player.character.firstPerson#maxCutDistance"), 1)
		self.cutDetectionDistance = Utils.getNoNil(getXMLFloat(xmlFile, "player.character.firstPerson#cutDetectionDistance"), 10)
	end

	if isRealPlayer then
		self.skeletonRootNode = createTransformGroup("player_skeletonRootNode")
		self.foliageBendingNode = createTransformGroup("player_foliageBendingNode")

		link(getRootNode(), self.graphicsRootNode)
		link(self.graphicsRootNode, self.cameraNode)
		link(self.graphicsRootNode, self.skeletonRootNode)
		link(self.graphicsRootNode, self.foliageBendingNode)

		if self.animRootThirdPerson ~= nil then
			link(self.skeletonRootNode, self.animRootThirdPerson)

			if self.skeletonThirdPerson ~= nil then
				link(self.animRootThirdPerson, self.skeletonThirdPerson)
			end
		end

		self.visualInformation:linkProtectiveWear(self.skeletonRootNode)

		if self.skeletonThirdPerson ~= nil and getNumOfChildren(self.skeletonThirdPerson) > 0 then
			local animNode = g_animCache:getNode(AnimationCache.CHARACTER)

			cloneAnimCharacterSet(animNode, getParent(self.skeletonThirdPerson))

			local animCharsetId = getAnimCharacterSet(getChildAt(self.skeletonThirdPerson, 0))
			self.animationInformation.player = createConditionalAnimation()

			for key, parameter in pairs(self.animationInformation.parameters) do
				conditionalAnimationRegisterParameter(self.animationInformation.player, parameter.id, parameter.type, key)
			end

			initConditionalAnimation(self.animationInformation.player, animCharsetId, self.xmlFilename, "player.conditionalAnimation")
			setConditionalAnimationSpecificParameterIds(self.animationInformation.player, self.animationInformation.parameters.absForwardVelocity.id, self.animationInformation.parameters.yawVelocity.id)
		end

		self.leftArmToolNode = createTransformGroup("leftArmToolNode")
		self.rightArmToolNode = createTransformGroup("rightArmToolNode")

		if self.isOwner then
			local toolRotation = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#firstPersonRotation"), "0 0 0"), 3)
			local rotX, rotY, rotZ = unpack(toolRotation)

			setRotation(self.rightArmToolNode, math.rad(rotX), math.rad(rotY), math.rad(rotZ))

			local toolTranslate = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#firstPersonTranslation"), "0 0 0"), 3)
			local transX, transY, transZ = unpack(toolTranslate)

			setTranslation(self.rightArmToolNode, transX, transY, transZ)
			link(self.cuttingCameraNode, self.rightArmToolNode)
		else
			local toolRotationR = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonRightNodeRotation"), "0 0 0"), 3)
			local rotRX, rotRY, rotRZ = unpack(toolRotationR)

			setRotation(self.rightArmToolNode, math.rad(rotRX), math.rad(rotRY), math.rad(rotRZ))

			local toolTranslateR = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonRightNodeTranslation"), "0 0 0"), 3)
			local transRX, transRY, transRZ = unpack(toolTranslateR)

			setTranslation(self.rightArmToolNode, transRX, transRY, transRZ)
			link(self.thirdPersonRightHandNode, self.rightArmToolNode)

			local toolRotationL = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonLeftNodeRotation"), "0 0 0"), 3)
			local rotLX, rotLY, rotLZ = unpack(toolRotationL)

			setRotation(self.leftArmToolNode, math.rad(rotLX), math.rad(rotLY), math.rad(rotLZ))

			local toolTranslateL = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonLeftNodeTranslation"), "0 0 0"), 3)
			local transLX, transLY, transLZ = unpack(toolTranslateL)

			setTranslation(self.leftArmToolNode, transLX, transLY, transLZ)
			link(self.thirdPersonLeftHandNode, self.leftArmToolNode)
			link(self.thirdPersonHeadNode, self.lightNode)

			local lightRotation = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.light#thirdPersonRotation"), "0 0 0"), 3)
			local lightRotX, lightRotY, lightRotZ = unpack(lightRotation)
			local lightTranslate = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "player.light#thirdPersonTranslation"), "0 0 0"), 3)
			local lightTransX, lightTransY, lightTransZ = unpack(lightTranslate)

			setRotation(self.lightNode, math.rad(lightRotX), math.rad(lightRotY), math.rad(lightRotZ))
			setTranslation(self.lightNode, lightTransX, lightTransY, lightTransZ)
		end

		self.particleSystemsInformation.swimNode = createTransformGroup("swimFXNode")

		link(getRootNode(), self.particleSystemsInformation.swimNode)

		self.particleSystemsInformation.plungeNode = createTransformGroup("plungeFXNode")

		link(getRootNode(), self.particleSystemsInformation.plungeNode)
		ParticleUtil.loadParticleSystem(xmlFile, self.particleSystemsInformation.systems.swim, "player.particleSystems.swim", self.particleSystemsInformation.swimNode, false, nil, self.baseDirectory)
		ParticleUtil.loadParticleSystem(xmlFile, self.particleSystemsInformation.systems.plunge, "player.particleSystems.plunge", self.particleSystemsInformation.plungeNode, false, nil, self.baseDirectory)
		self.visualInformation:applySelection()

		if self.isOwner then
			self.visualInformation:setVisibility(false)
		else
			self.visualInformation:setVisibility(true)
		end
	else
		link(linkNode, self.skeletonThirdPerson)
		self.visualInformation:linkProtectiveWear(linkNode)

		if self.pickUpKinematicHelperNode ~= nil then
			delete(self.pickUpKinematicHelperNode)

			self.pickUpKinematicHelperNode = nil
		end

		if self.lightNode ~= nil then
			delete(self.lightNode)

			self.lightNode = nil
		end

		if self.cameraNode ~= nil then
			delete(self.cameraNode)

			self.cameraNode = nil
		end

		local offset = {
			localToLocal(self.thirdPersonSpineNode, self.skeletonThirdPerson, 0, 0, 0)
		}

		setTranslation(self.skeletonThirdPerson, -offset[1], -offset[2], -offset[3])
		self.visualInformation:applySelection()
		self.visualInformation:setVisibility(true)
	end

	if isRealPlayer then
		self.soundInformation.surfaceSounds = {}
		self.soundInformation.surfaceIdToSound = {}
		self.soundInformation.surfaceNameToSound = {}
		self.soundInformation.currentSurfaceSound = nil

		if not self.isOwner then
			for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
				if surfaceSound.type == "footstep" and surfaceSound.sample ~= nil then
					local sample = g_soundManager:cloneSample(surfaceSound.sample, self.rootNode, self)
					sample.sampleName = surfaceSound.name

					table.insert(self.soundInformation.surfaceSounds, sample)

					self.soundInformation.surfaceIdToSound[surfaceSound.materialId] = sample
					self.soundInformation.surfaceNameToSound[surfaceSound.name] = sample
				end
			end

			self.soundInformation.samples.swim = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "swim", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
			self.soundInformation.samples.swimIdle = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "swimIdle", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
			self.soundInformation.samples.plunge = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "plunge", self.baseDirectory, self.rootNode, 1, AudioGroup.ENVIRONMENT, nil, )
			self.soundInformation.samples.flashlight = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.tools", "flashlight", self.baseDirectory, self.rootNode, 1, AudioGroup.ENVIRONMENT, nil, )
			self.soundInformation.samples.horseBrush = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.tools", "horseBrush", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
		else
			for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
				if surfaceSound.type == "footstep" and surfaceSound.sample ~= nil then
					local sample = g_soundManager:cloneSample2D(surfaceSound.sample, self)
					sample.sampleName = surfaceSound.name

					table.insert(self.soundInformation.surfaceSounds, sample)

					self.soundInformation.surfaceIdToSound[surfaceSound.materialId] = sample
					self.soundInformation.surfaceNameToSound[surfaceSound.name] = sample
				end
			end

			self.soundInformation.samples = {
				swim = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "swim", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
				swimIdle = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "swimIdle", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
				plunge = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "plunge", self.baseDirectory, 1, AudioGroup.ENVIRONMENT),
				flashlight = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.tools", "flashlight", self.baseDirectory, 1, AudioGroup.ENVIRONMENT),
				horseBrush = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.tools", "horseBrush", self.baseDirectory, 0, AudioGroup.ENVIRONMENT)
			}
		end

		self.soundInformation.distancePerFootstep.crouch = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepCrouch"), 0.5)
		self.soundInformation.distancePerFootstep.walk = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepWalk"), 0.75)
		self.soundInformation.distancePerFootstep.run = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepRun"), 1.5)
	end

	IKUtil.updateAlignNodes(ikChains, getParentFunc, getParentFuncTarget, parentObj)
	delete(xmlFile)
	delete(rootNode)

	return true
end

function Player:load(xmlFilename, playerStyle, creatorConnection, isOwner)
	self.networkInformation.creatorConnection = creatorConnection
	self.isOwner = isOwner
	self.rootNode = createTransformGroup("PlayerCCT")

	link(getRootNode(), self.rootNode)

	self.ikChains = {}

	Player.loadVisuals(self, xmlFilename, playerStyle, nil, true, self.ikChains, self.getParentComponent, self, nil)
	self.playerStateMachine:load()

	self.isObjectInRange = false
	self.isCarryingObject = false
	self.pickedUpObject = nil
	local uiScale = g_gameSettings:getValue("uiScale")
	self.pickedUpObjectWidth, self.pickedUpObjectHeight = getNormalizedScreenValues(80 * uiScale, 80 * uiScale)
	self.pickedUpObjectOverlay = Overlay:new(g_baseHUDFilename, 0.5, 0.5, self.pickedUpObjectWidth, self.pickedUpObjectHeight)

	self.pickedUpObjectOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)

	self.pickedUpObjectHandUVs = GuiUtils.getUVs({
		0,
		138,
		80,
		80
	})
	self.pickedUpObjectAimingUVs = GuiUtils.getUVs({
		0,
		48,
		48,
		48
	})
	self.pickedUpObjectAimingWidth, self.pickedUpObjectAimingHeight = getNormalizedScreenValues(20 * uiScale, 20 * uiScale)

	self.pickedUpObjectOverlay:setUVs(self.pickedUpObjectAimingUVs)
	self.pickedUpObjectOverlay:setColor(1, 1, 1, 0.3)
	self:moveToAbsoluteInternal(0, -200, 0)

	self.controllerIndex = createCCT(self.rootNode, self.baseInformation.capsuleRadius, self.baseInformation.capsuleHeight, 0.6, 45, 0.1, Player.kinematicCollisionMask, self.motionInformation.mass)
	self.lockedInput = false

	if self.isOwner then
		addConsoleCommand("gsToggleFlightAndNoHUDMode", "Enables/disables the flight (J) and no HUD (O) toggle keys", "consoleCommandToggleFlightAndNoHUDMode", self)
		addConsoleCommand("gsToggleWoodCuttingMaker", "Enables/disables chainsaw woodcutting marker", "Player.consoleCommandToggleWoodCuttingMaker", nil)
		addConsoleCommand("gsTogglePlayerDebug", "Enables/disables player debug information", "consoleCommandTogglePlayerDebug", self)

		if g_addTestCommands then
			addConsoleCommand("gsReloadIKChains", "Reloads IKChains", "Player.consoleCommandReloadIKChains", nil)
			addConsoleCommand("gsToggleSuperStrength", "Enables/disables player super strength", "consoleCommandToggleSuperStrongMode", self)
		end
	end
end

function Player:getParentComponent(node)
	return self.graphicsRootNode
end

function Player:deleteVisuals(ikChains)
	if self.filename ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.filename, nil, false)

		self.filename = nil
	end

	for chainId, _ in pairs(ikChains) do
		IKUtil.deleteIKChain(ikChains, chainId)
	end

	if self.particleSystemsInformation ~= nil then
		if self.particleSystemsInformation.swimNode ~= nil then
			delete(self.particleSystemsInformation.swimNode)
		end

		if self.particleSystemsInformation.plungeNode ~= nil then
			delete(self.particleSystemsInformation.plungeNode)
		end

		ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.swim)
		ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.plunge)
	end

	self.visualInformation:unlinkProtectiveWear()

	if self.thirdPersonSpineNode ~= nil then
		delete(self.thirdPersonSpineNode)

		self.thirdPersonSpineNode = nil
	end

	if self.skeletonThirdPerson ~= nil then
		delete(self.skeletonThirdPerson)

		self.skeletonThirdPerson = nil
	end

	if self.meshThirdPerson ~= nil then
		delete(self.meshThirdPerson)

		self.meshThirdPerson = nil
	end

	if self.graphicsRootNode ~= nil then
		delete(self.graphicsRootNode)

		self.graphicsRootNode = nil
	end
end

function Player:delete()
	if self.isOwner then
		g_messageCenter:unsubscribeAll(self)
		self:removeActionEvents()
	end

	if self.isCarryingObject and g_server ~= nil then
		self:pickUpObject(false)
	end

	if self.pickedUpObjectOverlay ~= nil then
		self.pickedUpObjectOverlay:delete()
	end

	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool:onDeactivate()
		self.baseInformation.currentHandtool:delete()

		self.baseInformation.currentHandtool = nil
	end

	for _, sample in pairs(self.soundInformation.samples) do
		g_soundManager:deleteSample(sample)
	end

	g_soundManager:deleteSamples(self.soundInformation.surfaceSounds)

	if self.animationInformation.player ~= 0 then
		delete(self.animationInformation.player)

		self.animationInformation.player = 0
	end

	Player.deleteVisuals(self, self.ikChains)
	removeCCT(self.controllerIndex)
	delete(self.rootNode)
	self.playerStateMachine:delete()
	self:deleteStartleAnimalData()

	self.lightNode = nil

	if self.foliageBendingId ~= nil then
		g_currentMission.foliageBendingSystem:destroyObject(self.foliageBendingId)

		self.foliageBendingId = nil
	end

	if self.isOwner then
		removeConsoleCommand("gsToggleFlightAndNoHUDMode")
		removeConsoleCommand("gsToggleWoodCuttingMaker")
		removeConsoleCommand("gsTogglePlayerDebug")
		removeConsoleCommand("gsReloadIKChains")
		removeConsoleCommand("gsToggleSuperStrength")
	end

	Player:superClass().delete(self)
end

function Player:setCuttingAnim(isCutting, isHorizontalCut)
	if not isCutting and (self.baseInformation.isUsingChainsawHorizontal or self.baseInformation.isUsingChainsawVertical) then
		self.baseInformation.isUsingChainsawHorizontal = false
		self.baseInformation.isUsingChainsawVertical = false
	elseif isCutting then
		if isHorizontalCut then
			self.baseInformation.isUsingChainsawHorizontal = true
			self.baseInformation.isUsingChainsawVertical = false
		else
			self.baseInformation.isUsingChainsawHorizontal = false
			self.baseInformation.isUsingChainsawVertical = true
		end
	end
end

function Player:readStream(streamId, connection)
	Player:superClass().readStream(self, streamId)

	local isOwner = streamReadBool(streamId)
	local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)
	local isControlled = streamReadBool(streamId)

	if self.visualInformation == nil then
		self.visualInformation = PlayerStyle:new()
	end

	self.visualInformation:readStream(streamId, connection)

	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if self.filename == nil then
		self:load(filename, self.visualInformation, connection, isOwner)
	end

	self:moveToAbsoluteInternal(x, y, z)
	self:setLightIsActive(streamReadBool(streamId), true)

	if isControlled ~= self.isControlled then
		if isControlled then
			self:onEnter(false)
		else
			self:onLeave()
		end
	end

	local hasHandtool = streamReadBool(streamId)

	if hasHandtool then
		local handtoolFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		self:equipHandtool(handtoolFilename, true, true)
	end
end

function Player:writeStream(streamId, connection)
	Player:superClass().writeStream(self, streamId)
	streamWriteBool(streamId, connection == self.networkInformation.creatorConnection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))

	local x, y, z = getTranslation(self.rootNode)

	streamWriteFloat32(streamId, x)
	streamWriteFloat32(streamId, y)
	streamWriteFloat32(streamId, z)
	streamWriteBool(streamId, self.isControlled)
	self.visualInformation:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteBool(streamId, self.isLightActive)

	local hasHandtool = self:hasHandtoolEquipped()

	streamWriteBool(streamId, hasHandtool)

	if hasHandtool then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.baseInformation.currentHandtool.configFileName))
	end
end

function Player:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local alpha = streamReadFloat32(streamId)
		self.cameraRotY = alpha
		self.isObjectInRange = streamReadBool(streamId)

		if self.isObjectInRange then
			self.lastFoundObjectMass = streamReadFloat32(streamId)
		else
			self.lastFoundObjectMass = nil
		end

		self.isCarryingObject = streamReadBool(streamId)
		local isOnGround = streamReadBool(streamId)

		if self.isOwner then
			local index = streamReadInt32(streamId)

			while self.networkInformation.history[1] ~= nil and self.networkInformation.history[1].index <= index do
				table.remove(self.networkInformation.history, 1)
			end

			setCCTPosition(self.controllerIndex, x, y, z)

			local history = self.networkInformation.history
			local numHistory = #history

			if numHistory <= 5 then
				for i = 1, numHistory do
					moveCCT(self.controllerIndex, history[i].movementX, history[i].movementY, history[i].movementZ, Player.movementCollisionMask)
				end
			else
				local accumSizeSmall = math.floor(numHistory / 5)
				local numSmall = 5 - numHistory + accumSizeSmall * 5
				local startI = 1

				for i = 1, 5 do
					local endI = nil

					if i <= numSmall then
						endI = startI + accumSizeSmall - 1
					else
						endI = startI + accumSizeSmall
					end

					local movementX = 0
					local movementY = 0
					local movementZ = 0

					for j = startI, endI do
						movementX = movementX + history[j].movementX
						movementY = movementY + history[j].movementY
						movementZ = movementZ + history[j].movementZ
					end

					moveCCT(self.controllerIndex, movementX, movementY, movementZ, Player.movementCollisionMask)

					startI = endI + 1
				end
			end

			self.networkInformation.updateTargetTranslationPhysicsIndex = getPhysicsUpdateIndex()
			self.baseInformation.isCrouched = streamReadBool(streamId)
		else
			local isControlled = streamReadBool(streamId)

			if isControlled ~= self.isControlled then
				self:moveToAbsoluteInternal(x, y, z)

				if isControlled then
					self:onEnter(false)
				else
					self:onLeave()
				end
			else
				setTranslation(self.rootNode, x, y, z)
				self.networkInformation.interpolatorPosition:setTargetPosition(x, y, z)

				if isOnGround then
					self.networkInformation.interpolatorOnGround:setTargetValue(1)
				else
					self.networkInformation.interpolatorOnGround:setTargetValue(0)
				end

				self.networkInformation.updateTargetTranslationPhysicsIndex = -1

				self.networkInformation.interpolationTime:startNewPhaseNetwork()
				self:raiseActive()
			end

			self.baseInformation.isCrouched = streamReadBool(streamId)
		end
	elseif connection == self.networkInformation.creatorConnection then
		local movementX = streamReadFloat32(streamId)
		local movementY = streamReadFloat32(streamId)
		local movementZ = streamReadFloat32(streamId)
		local qx = streamReadFloat32(streamId)
		local qy = streamReadFloat32(streamId)
		local qz = streamReadFloat32(streamId)
		local qw = streamReadFloat32(streamId)
		local index = streamReadInt32(streamId)
		local isControlled = streamReadBool(streamId)

		moveCCT(self.controllerIndex, movementX, movementY, movementZ, Player.movementCollisionMask)
		self.networkInformation.interpolationTime:startNewPhaseNetwork()
		self.networkInformation.interpolatorQuaternion:setTargetQuaternion(qx, qy, qz, qw)

		local physicsIndex = getPhysicsUpdateIndex()

		table.insert(self.networkInformation.history, {
			index = index,
			physicsIndex = physicsIndex
		})

		self.networkInformation.updateTargetTranslationPhysicsIndex = physicsIndex

		self:raiseActive()

		if isControlled ~= self.isControlled then
			if isControlled then
				self:onEnter(false)
			else
				self:onLeave()
			end
		end

		self.baseInformation.isCrouched = streamReadBool(streamId)

		if self.isCarryingObject then
			self.networkInformation.rotateObject = streamReadBool(streamId)

			if self.networkInformation.rotateObject then
				self.networkInformation.rotateObjectInputH = streamReadFloat32(streamId)
				self.networkInformation.rotateObjectInputV = streamReadFloat32(streamId)
			end
		end
	end
end

function Player:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local x, y, z = getTranslation(self.rootNode)

		streamWriteFloat32(streamId, x)
		streamWriteFloat32(streamId, y)
		streamWriteFloat32(streamId, z)

		local x, _, z = localDirectionToLocal(self.cameraNode, getParent(self.cameraNode), 0, 0, 1)
		local alpha = math.atan2(x, z)

		streamWriteFloat32(streamId, alpha)
		streamWriteBool(streamId, self.isObjectInRange)

		if self.isObjectInRange then
			streamWriteFloat32(streamId, self.lastFoundObjectMass)
		end

		streamWriteBool(streamId, self.isCarryingObject)
		streamWriteBool(streamId, self.baseInformation.isOnGroundPhysics)

		local isOwner = connection == self.networkInformation.creatorConnection

		if isOwner then
			streamWriteInt32(streamId, self.networkInformation.sendIndex)

			local isCrouching = self.baseInformation.isCrouched

			streamWriteBool(streamId, isCrouching)
		else
			streamWriteBool(streamId, self.isControlled)

			local isCrouching = self.baseInformation.isCrouched or self.playerStateMachine:isActive("crouch")

			streamWriteBool(streamId, isCrouching)
		end
	elseif self.isOwner then
		streamWriteFloat32(streamId, self.networkInformation.tickTranslation[1])
		streamWriteFloat32(streamId, self.networkInformation.tickTranslation[2])
		streamWriteFloat32(streamId, self.networkInformation.tickTranslation[3])

		self.networkInformation.tickTranslation[1] = 0
		self.networkInformation.tickTranslation[2] = 0
		self.networkInformation.tickTranslation[3] = 0
		local x, y, z, w = getQuaternion(self.cameraNode)

		streamWriteFloat32(streamId, x)
		streamWriteFloat32(streamId, y)
		streamWriteFloat32(streamId, z)
		streamWriteFloat32(streamId, w)
		streamWriteInt32(streamId, self.networkInformation.index)
		streamWriteBool(streamId, self.isControlled)

		local isCrouching = self.playerStateMachine:isActive("crouch")

		streamWriteBool(streamId, isCrouching)

		if self.isCarryingObject then
			streamWriteBool(streamId, self.networkInformation.rotateObject)

			if self.networkInformation.rotateObject then
				streamWriteFloat32(streamId, self.networkInformation.rotateObjectInputH)
				streamWriteFloat32(streamId, self.networkInformation.rotateObjectInputV)
			end
		end
	end
end

function Player:mouseEvent(posX, posY, isDown, isUp, button)
end

function Player:getIsInputAllowed()
	return self.isEntered and self.isClient and not g_gui:getIsGuiVisible()
end

function Player:updateAnimationParameters(dt)
	local dx = self.networkInformation.interpolatorPosition.targetPositionX - self.networkInformation.interpolatorPosition.lastPositionX
	local dy = self.networkInformation.interpolatorPosition.targetPositionY - self.networkInformation.interpolatorPosition.lastPositionY
	local dz = self.networkInformation.interpolatorPosition.targetPositionZ - self.networkInformation.interpolatorPosition.lastPositionZ
	local vx = dx / (self.networkInformation.interpolationTime.interpolationDuration * 0.001)
	local vy = dy / (self.networkInformation.interpolationTime.interpolationDuration * 0.001)
	local vz = dz / (self.networkInformation.interpolationTime.interpolationDuration * 0.001)
	local dirX = math.sin(self.graphicsRotY)
	local dirZ = math.cos(self.graphicsRotY)
	local estimatedForwardVelocity = vx * dirX + vz * dirZ

	if self.baseInformation.animDt ~= nil and self.baseInformation.animDt ~= 0 then
		self.animationInformation.oldYaw = self.animationInformation.newYaw
		self.animationInformation.newYaw = self.cameraRotY
		self.animationInformation.estimatedYawVelocity = MathUtil.getAngleDifference(self.animationInformation.newYaw, self.animationInformation.oldYaw) / (self.baseInformation.animDt * 0.001)
		self.baseInformation.animDt = 0
	end

	local params = self.animationInformation.parameters
	params.forwardVelocity.value = self.lastEstimatedForwardVelocity
	params.verticalVelocity.value = vy
	params.yawVelocity.value = self.animationInformation.estimatedYawVelocity
	params.absYawVelocity.value = math.abs(self.animationInformation.estimatedYawVelocity)
	params.onGround.value = self.baseInformation.isOnGround
	params.inWater.value = self.baseInformation.isInWater
	params.isCrouched.value = self.baseInformation.isCrouched
	params.absForwardVelocity.value = math.abs(self.lastEstimatedForwardVelocity)
	params.isCloseToGround.value = self.baseInformation.isCloseToGround
	params.isUsingChainsawHorizontal.value = self.baseInformation.isUsingChainsawHorizontal
	params.isUsingChainsawVertical.value = self.baseInformation.isUsingChainsawVertical

	for _, parameter in pairs(self.animationInformation.parameters) do
		if parameter.type == 0 then
			setConditionalAnimationBoolValue(self.animationInformation.player, parameter.id, parameter.value)
		elseif parameter.type == 1 then
			setConditionalAnimationFloatValue(self.animationInformation.player, parameter.id, parameter.value)
		end
	end
end

function Player:updateWaterParms()
	local _, y, _ = getWorldTranslation(self.rootNode)
	local deltaWater = y - g_currentMission.waterY - self.baseInformation.capsuleTotalHeight * 0.5
	local waterLevel = self.baseInformation.waterLevel
	local velocityY = 0

	if deltaWater < -50 then
		return
	end

	if not self.isEntered then
		velocityY = self.animationInformation.parameters.verticalVelocity.value
	else
		velocityY = self.motionInformation.currentSpeedY
	end

	self.baseInformation.wasInWater = self.baseInformation.isInWater
	self.baseInformation.isInWater = deltaWater <= waterLevel

	if not self.baseInformation.wasInWater and self.baseInformation.isInWater and velocityY < self.baseInformation.plungedYVelocityThreshold then
		self.baseInformation.plungedInWater = true
	else
		self.baseInformation.plungedInWater = false
	end
end

function Player:update(dt)
	self.time = self.time + dt

	if not self.isEntered and self.isClient and self.isControlled then
		self:updateFX()
	end

	if self.isServer or self.isEntered then
		local _, _, isOnGround = getCCTCollisionFlags(self.controllerIndex)
		self.baseInformation.isOnGroundPhysics = isOnGround
	end

	if self.isClient and self.isControlled then
		self:updateWaterParms()
		self:updateSound()
	end

	if self.isEntered and self.isClient and not g_gui:getIsGuiVisible() and not g_currentMission.isPlayerFrozen then
		self:updatePlayerStates()
		self.playerStateMachine:update(dt)
		self:recordPositionInformation()
		self:cameraBob(dt)
		self:debugDraw()
		self.playerStateMachine:debugDraw(dt)

		if not self.walkingIsLocked then
			self.rotX = self.rotX - self.inputInformation.pitchCamera * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
			self.rotY = self.rotY - self.inputInformation.yawCamera * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
			self.rotX = math.min(1.2, math.max(-1.5, self.rotX))

			setRotation(self.cameraNode, self.rotX, self.rotY, 0)
			setRotation(self.foliageBendingNode, 0, self.rotY, 0)
		end

		self:updateActionEvents()
	end

	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool:update(dt, self:getIsInputAllowed())

		if self.playerStateMachine:isActive("swim") then
			self:unequipHandtool()
		end
	end

	self:updateInterpolation()

	if self.isClient and self.isControlled then
		self:updateRotation(dt)
	end

	if self.isClient and self.isControlled and not self.isEntered then
		self:updateAnimationParameters(dt)
		updateConditionalAnimation(self.animationInformation.player, dt)
	end

	if not GS_IS_MOBILE_VERSION then
		self:checkObjectInRange()
	end

	if self.isEntered or self.networkInformation.interpolationTime.isDirty then
		self:raiseActive()
	end

	if self.isClient and self.isControlled and not self.isEntered and self.networkInformation.rotateObject then
		self:rotateObject(self.networkInformation.rotateObjectInputV, 1, 0, 0)
		self:rotateObject(self.networkInformation.rotateObjectInputH, 0, 1, 0)
	end

	self:resetCameraInputsInformation()
end

function Player:checkObjectInRange()
	if self.isControlled and self.isServer then
		if not self.isCarryingObject then
			local x, y, z = localToWorld(self.cameraNode, 0, 0, 1)
			local dx, dy, dz = localDirectionToWorld(self.cameraNode, 0, 0, -1)
			self.lastFoundObject = nil
			self.lastFoundObjectHitPoint = nil

			raycastAll(x, y, z, dx, dy, dz, "pickUpObjectRaycastCallback", Player.MAX_PICKABLE_OBJECT_DISTANCE, self)

			self.isObjectInRange = self.lastFoundObject ~= nil
		elseif self.pickedUpObject ~= nil and not entityExists(self.pickedUpObject) then
			Player.PICKED_UP_OBJECTS[self.pickedUpObject] = false
			self.pickedUpObject = nil
			self.pickedUpObjectJointId = nil
			self.isCarryingObject = false
		end
	end
end

function Player:updateTick(dt)
	if self.isEntered and not g_gui:getIsGuiVisible() and not g_currentMission.isPlayerFrozen then
		self:updateKinematic(dt)
	end

	self.playerStateMachine:updateTick(dt)

	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool:updateTick(dt, self:getIsInputAllowed())
	end

	self:updateNetworkMovementHistory()
	self:updateInterpolationTick()
	self:resetInputsInformation()

	if self.isServer and self.isControlled and GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_PC then
		local x, y, z = getTranslation(self.rootNode)
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams

		if not NetworkUtil.getIsWorldPositionInCompressionRange(x, paramsXZ) or not NetworkUtil.getIsWorldPositionInCompressionRange(z, paramsXZ) or getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z) > y + 20 then
			self:moveTo(g_currentMission.playerStartX, g_currentMission.playerStartY, g_currentMission.playerStartZ, g_currentMission.playerStartIsAbsolute, false)

			return
		end
	end
end

function Player:enableInput(inputAction)
	local id = self.inputInformation.registrationList[inputAction].eventId

	g_inputBinding:setActionEventActive(id, true)
	g_inputBinding:setActionEventTextVisibility(id, true)
end

function Player:disableInput(inputAction)
	local id = self.inputInformation.registrationList[inputAction].eventId

	g_inputBinding:setActionEventActive(id, false)
	g_inputBinding:setActionEventTextVisibility(id, false)
end

function Player:updateActionEvents()
	local isDark = g_currentMission.environment.currentHour > g_currentMission.environment.nightStart - 0.5 or g_currentMission.environment.currentHour < g_currentMission.environment.nightEnd + 0.5
	local eventIdToggleLight = self.inputInformation.registrationList[InputAction.TOGGLE_LIGHTS_FPS].eventId

	if self.playerStateMachine:isAvailable("useLight") and isDark then
		g_inputBinding:setActionEventTextVisibility(eventIdToggleLight, isDark and self.lightNode ~= nil)
	end

	self:disableInput(InputAction.NEXT_HANDTOOL)
	self:disableInput(InputAction.PREVIOUS_HANDTOOL)
	self:disableInput(InputAction.ACTIVATE_HANDTOOL)
	self:disableInput(InputAction.INTERACT)
	self:disableInput(InputAction.ACTIVATE_OBJECT)
	self:disableInput(InputAction.ENTER)
	self:disableInput(InputAction.THROW_OBJECT)
	self:disableInput(InputAction.ROTATE_OBJECT_LEFT_RIGHT)
	self:disableInput(InputAction.ROTATE_OBJECT_UP_DOWN)

	if self.playerStateMachine:isAvailable("cycleHandtool") then
		self:enableInput(InputAction.NEXT_HANDTOOL)
		self:enableInput(InputAction.PREVIOUS_HANDTOOL)
	end

	if self:hasHandtoolEquipped() then
		self:enableInput(InputAction.ACTIVATE_HANDTOOL)

		local eventIdActivateObject = self.inputInformation.registrationList[InputAction.ACTIVATE_OBJECT].eventId

		if self.playerStateMachine:isAvailable("activateObject") then
			self:enableInput(InputAction.ACTIVATE_OBJECT)

			local activateObjectState = self.playerStateMachine:getState("activateObject")

			g_inputBinding:setActionEventText(eventIdActivateObject, activateObjectState.activateText)
		end
	else
		if self.playerStateMachine:isAvailable("throw") then
			self:enableInput(InputAction.THROW_OBJECT)
		end

		local eventIdObjectRotateHorizontally = self.inputInformation.registrationList[InputAction.ROTATE_OBJECT_LEFT_RIGHT].eventId
		local eventIdObjectRotateVertically = self.inputInformation.registrationList[InputAction.ROTATE_OBJECT_UP_DOWN].eventId

		if self.isCarryingObject then
			self:enableInput(InputAction.ROTATE_OBJECT_LEFT_RIGHT)
			self:enableInput(InputAction.ROTATE_OBJECT_UP_DOWN)
		end

		local eventIdActivateObject = self.inputInformation.registrationList[InputAction.ACTIVATE_OBJECT].eventId

		if self.playerStateMachine:isAvailable("activateObject") then
			self:enableInput(InputAction.ACTIVATE_OBJECT)

			local activateObjectState = self.playerStateMachine:getState("activateObject")

			g_inputBinding:setActionEventText(eventIdActivateObject, activateObjectState.activateText)
		elseif self.playerStateMachine:isAvailable("animalFeed") then
			self:enableInput(InputAction.ACTIVATE_OBJECT)
			g_inputBinding:setActionEventText(eventIdActivateObject, g_i18n:getText("action_feedAnimal"))
		elseif self.playerStateMachine:isAvailable("animalPet") then
			self:enableInput(InputAction.ACTIVATE_OBJECT)
			g_inputBinding:setActionEventText(eventIdActivateObject, g_i18n:getText("action_petAnimal"))
		end

		local eventIdInteract = self.inputInformation.registrationList[InputAction.INTERACT].eventId

		if self.playerStateMachine:isAvailable("drop") then
			g_inputBinding:setActionEventText(eventIdInteract, g_i18n:getText("action_dropObject"))
			self:enableInput(InputAction.INTERACT)
		elseif self.playerStateMachine:isAvailable("pickup") then
			g_inputBinding:setActionEventText(eventIdInteract, g_i18n:getText("action_pickUpObject"))
			self:enableInput(InputAction.INTERACT)
		elseif self.playerStateMachine:isAvailable("animalInteract") or self.playerStateMachine:isActive("animalInteract") then
			local animalInteractState = self.playerStateMachine:getState("animalInteract")
			local animalInteractText = string.format(g_i18n:getText("action_interactAnimal"), animalInteractState.interactText)

			g_inputBinding:setActionEventText(eventIdInteract, animalInteractText)
			self:enableInput(InputAction.INTERACT)
		elseif self.inputInformation.interactState == Player.BUTTONSTATES.RELEASED then
			self:disableInput(InputAction.INTERACT)
		end
	end

	self.canRideAnimal = self.playerStateMachine:isAvailable("animalRide")
	self.canEnterVehicle = g_currentMission.interactiveVehicleInRange and g_currentMission.interactiveVehicleInRange:getIsEnterable()
	local vehicleIsRideable = self.canEnterVehicle and SpecializationUtil.hasSpecialization(Rideable, g_currentMission.interactiveVehicleInRange.specializations)
	local eventIdEnter = self.inputInformation.registrationList[InputAction.ENTER].eventId

	if self.canEnterVehicle and not vehicleIsRideable then
		g_inputBinding:setActionEventText(eventIdEnter, g_i18n:getText("button_enterVehicle"))
		self:enableInput(InputAction.ENTER)
	elseif self.canRideAnimal or vehicleIsRideable then
		local rideableName = ""

		if self.canRideAnimal then
			local rideState = self.playerStateMachine:getState("animalRide")
			rideableName = rideState:getRideableName()
		elseif vehicleIsRideable then
			rideableName = g_currentMission.interactiveVehicleInRange:getFullName()
		end

		g_inputBinding:setActionEventText(eventIdEnter, string.format(g_i18n:getText("action_rideAnimal"), rideableName))
		self:enableInput(InputAction.ENTER)
	end

	local eventIdDebugFlyToggle = self.inputInformation.registrationList[InputAction.DEBUG_PLAYER_ENABLE].eventId

	g_inputBinding:setActionEventActive(eventIdDebugFlyToggle, g_flightAndNoHUDKeysEnabled)

	local eventIdDebugFlyUpDown = self.inputInformation.registrationList[InputAction.DEBUG_PLAYER_UP_DOWN].eventId

	g_inputBinding:setActionEventActive(eventIdDebugFlyUpDown, g_flightAndNoHUDKeysEnabled)
end

function Player:updateInterpolationTick()
	if self.isEntered then
		local xt, yt, zt = getTranslation(self.rootNode)
		local interpPos = self.networkInformation.interpolatorPosition

		if math.abs(xt - interpPos.targetPositionX) < 0.001 and math.abs(yt - interpPos.targetPositionY) < 0.001 and math.abs(zt - interpPos.targetPositionZ) < 0.001 then
			zt = interpPos.targetPositionZ
			yt = interpPos.targetPositionY
			xt = interpPos.targetPositionX
		end

		self.networkInformation.interpolatorPosition:setTargetPosition(xt, yt, zt)

		if self.baseInformation.isOnGroundPhysics then
			self.networkInformation.interpolatorOnGround:setTargetValue(1)
		else
			self.networkInformation.interpolatorOnGround:setTargetValue(0)
		end

		self.networkInformation.interpolationTime:startNewPhase(75)
	elseif self.networkInformation.updateTargetTranslationPhysicsIndex >= 0 then
		local xt, yt, zt = getTranslation(self.rootNode)

		if getIsPhysicsUpdateIndexSimulated(self.networkInformation.updateTargetTranslationPhysicsIndex) then
			self.networkInformation.updateTargetTranslationPhysicsIndex = -1
		else
			local interpPos = self.networkInformation.interpolatorPosition

			if math.abs(xt - interpPos.targetPositionX) < 0.001 and math.abs(yt - interpPos.targetPositionY) < 0.001 and math.abs(zt - interpPos.targetPositionZ) < 0.001 then
				zt = interpPos.targetPositionZ
				yt = interpPos.targetPositionY
				xt = interpPos.targetPositionX
			end
		end

		self.networkInformation.interpolatorPosition:setTargetPosition(xt, yt, zt)

		if self.baseInformation.isOnGroundPhysics then
			self.networkInformation.interpolatorOnGround:setTargetValue(1)
		else
			self.networkInformation.interpolatorOnGround:setTargetValue(0)
		end

		self.networkInformation.interpolatorQuaternion:setTargetQuaternion(self.networkInformation.interpolatorQuaternion.targetQuaternionX, self.networkInformation.interpolatorQuaternion.targetQuaternionY, self.networkInformation.interpolatorQuaternion.targetQuaternionZ, self.networkInformation.interpolatorQuaternion.targetQuaternionW)
		self.networkInformation.interpolationTime:startNewPhase(75)
	end
end

function Player:updateInterpolation()
	if self.isControlled then
		local needsCameraInterp = self.isServer and not self.isEntered
		local needsPositionInterp = self.isClient

		if (needsCameraInterp or needsPositionInterp) and self.networkInformation.interpolationTime.isDirty then
			self.networkInformation.interpolationTime:update(g_physicsDtUnclamped)

			if needsCameraInterp then
				local qx, qy, qz, qw = self.networkInformation.interpolatorQuaternion:getInterpolatedValues(self.networkInformation.interpolationTime.interpolationAlpha)

				setQuaternion(self.cameraNode, qx, qy, qz, qw)
			end

			if needsPositionInterp then
				local x, y, z = self.networkInformation.interpolatorPosition:getInterpolatedValues(self.networkInformation.interpolationTime.interpolationAlpha)

				setTranslation(self.graphicsRootNode, x, y - self.baseInformation.capsuleTotalHeight * 0.5, z)

				local isOnGroundFloat = self.networkInformation.interpolatorOnGround:getInterpolatedValue(self.networkInformation.interpolationTime.interpolationAlpha)
				self.baseInformation.isOnGround = isOnGroundFloat > 0.9
				self.baseInformation.isCloseToGround = isOnGroundFloat > 0.5
			end
		end
	end
end

function Player:updateNetworkMovementHistory()
	if self.isEntered and self.isClient then
		self:raiseDirtyFlags(self.networkInformation.dirtyFlag)
	elseif self.isServer and not self.isEntered and self.isControlled then
		local latestSimulatedIndex = -1

		while self.networkInformation.history[1] ~= nil and getIsPhysicsUpdateIndexSimulated(self.networkInformation.history[1].physicsIndex) do
			latestSimulatedIndex = self.networkInformation.history[1].index

			table.remove(self.networkInformation.history, 1)
		end

		if latestSimulatedIndex >= 0 then
			self.networkInformation.sendIndex = latestSimulatedIndex

			self:raiseDirtyFlags(self.networkInformation.dirtyFlag)
		end
	end
end

function Player:updateRotation(dt)
	if not self.isEntered then
		local animDt = 60
		self.animUpdateTime = self.animUpdateTime + dt

		if animDt < self.animUpdateTime then
			if self.isServer then
				local x, _, z = localDirectionToLocal(self.cameraNode, getParent(self.cameraNode), 0, 0, 1)
				local alpha = math.atan2(x, z)
				self.cameraRotY = alpha
			end

			local x, y, z = getTranslation(self.graphicsRootNode)
			local dx = x - self.lastAnimPosX
			local _ = y - self.lastAnimPosY
			local dz = z - self.lastAnimPosZ
			local dirX = -math.sin(self.cameraRotY)
			local dirZ = -math.cos(self.cameraRotY)
			local movementDist = dx * dirX + dz * dirZ

			if dx * dx + dz * dz < 0.001 then
				self.targetGraphicsRotY = self.cameraRotY + math.rad(180)
			elseif movementDist > -0.001 then
				self.targetGraphicsRotY = math.atan2(dx, dz)
			else
				self.targetGraphicsRotY = math.atan2(-dx, -dz)
			end

			dirZ = -math.cos(self.targetGraphicsRotY)
			dirX = -math.sin(self.targetGraphicsRotY)
			movementDist = dx * dirX + dz * dirZ
			movementDist = self.walkDistance * 0.2 + movementDist * 0.8
			self.walkDistance = movementDist
			self.lastEstimatedForwardVelocity = -movementDist / (self.animUpdateTime * 0.001)
			self.lastAnimPosX = x
			self.lastAnimPosY = y
			self.lastAnimPosZ = z
			self.baseInformation.animDt = self.animUpdateTime
			self.animUpdateTime = 0
		end

		self.targetGraphicsRotY = MathUtil.normalizeRotationForShortestPath(self.targetGraphicsRotY, self.graphicsRotY)
		local maxDeltaRotY = math.rad(0.5) * dt
		self.graphicsRotY = math.min(math.max(self.targetGraphicsRotY, self.graphicsRotY - maxDeltaRotY), self.graphicsRotY + maxDeltaRotY)

		setRotation(self.skeletonRootNode, 0, self.graphicsRotY, 0)
	end
end

function Player:getPositionData()
	local posX, posY, posZ = getTranslation(self.rootNode)

	if self.isClient and self.isControlled and self.isEntered then
		return posX, posY, posZ, self.rotY
	else
		return posX, posY, posZ, self.graphicsRotY
	end
end

function Player:setIKDirty()
	IKUtil.setIKChainDirty(self.ikChains, "rightFoot")
	IKUtil.setIKChainDirty(self.ikChains, "leftFoot")
	IKUtil.setIKChainDirty(self.ikChains, "rightArm")
	IKUtil.setIKChainDirty(self.ikChains, "leftArm")
	IKUtil.setIKChainDirty(self.ikChains, "spine")
end

function Player:lockInput(locked)
	self.lockedInput = locked
end

function Player:getCanEnterVehicle()
	return self.canEnterVehicle and not self:getCanEnterRideable()
end

function Player:getCanEnterRideable()
	if self.canEnterVehicle then
		local vehicle = g_currentMission.interactiveVehicleInRange

		if vehicle ~= nil and SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
			return true
		end
	end

	return false
end

function Player:moveTo(x, y, z, isAbsolute, isRootNode)
	self:unequipHandtool()

	if not self.isServer and self.isOwner then
		g_client:getServerConnection():sendEvent(PlayerTeleportEvent:new(x, y, z, isAbsolute, isRootNode))
	end

	if not isAbsolute then
		local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
		y = terrainHeight + y
	end

	if not isRootNode then
		y = y + self.baseInformation.capsuleTotalHeight * 0.5
	end

	self:moveToAbsoluteInternal(x, y, z)
end

function Player:moveToAbsolute(x, y, z)
	self:moveTo(x, y, z, true, false)
end

function Player:moveRootNodeToAbsolute(x, y, z)
	self:moveTo(x, y, z, true, true)
end

function Player:moveToExitPoint(exitVehicle)
	local exitPoint = nil

	if exitVehicle.getExitNode ~= nil then
		exitPoint = exitVehicle:getExitNode()
	end

	local x, y, z = getWorldTranslation(exitPoint)
	local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
	y = math.max(terrainHeight + 0.1, y + 0.9)

	self:moveToAbsolute(x, y, z)

	local dx, _, dz = localDirectionToWorld(exitPoint, 0, 0, -1)
	self.rotY = MathUtil.getYRotationFromDirection(dx, dz)

	setRotation(self.cameraNode, self.rotX, self.rotY, 0)
end

function Player:setRotation(rotX, rotY)
	self.rotX = math.min(1.2, math.max(-1.5, rotX))
	self.rotY = rotY
	self.graphicsRotY = rotY
	self.cameraRotY = rotY
	self.targetGraphicsRotY = rotY
end

function Player:moveToAbsoluteInternal(x, y, z)
	setTranslation(self.rootNode, x, y, z)
	setTranslation(self.graphicsRootNode, x, y - self.baseInformation.capsuleTotalHeight * 0.5, z)
	self.networkInformation.interpolationTime:reset()
	self.networkInformation.interpolatorPosition:setPosition(x, y, z)

	self.networkInformation.updateTargetTranslationPhysicsIndex = -1
	self.lastAnimPosX = x
	self.lastAnimPosY = y
	self.lastAnimPosZ = z
	self.walkDistance = 0
	self.baseInformation.lastPositionX, _, self.baseInformation.lastPositionZ = getTranslation(self.graphicsRootNode)
end

function Player:drawUIInfo()
	if self.isClient and self.isControlled and not self.isEntered and not g_gui:getIsGuiVisible() and not g_flightAndNoHUDKeysEnabled then
		local x, y, z = getTranslation(self.graphicsRootNode)
		local x1, y1, z1 = getWorldTranslation(getCamera())
		local diffX = x - x1
		local diffY = y - y1
		local diffZ = z - z1
		local dist = MathUtil.vector3LengthSq(diffX, diffY, diffZ)

		if dist <= 10000 then
			y = y + self.baseInformation.tagOffset[2]

			Utils.renderTextAtWorldPosition(x, y, z, self.visualInformation.playerName, getCorrectTextSize(0.02), 0)
		end
	end
end

function Player:draw()
	if self:getIsInputAllowed() then
		if self:hasHandtoolEquipped() then
			self.baseInformation.currentHandtool:draw()
		elseif not self.isCarryingObject and self.isObjectInRange and not self:hasHandtoolEquipped() then
			if not g_flightAndNoHUDKeysEnabled and self.pickedUpObjectOverlay ~= nil then
				self.pickedUpObjectOverlay:setDimension(self.pickedUpObjectWidth, self.pickedUpObjectHeight)
				self.pickedUpObjectOverlay:setUVs(self.pickedUpObjectHandUVs)
				self.pickedUpObjectOverlay:render()
			end
		elseif not g_flightAndNoHUDKeysEnabled and self.pickedUpObjectOverlay ~= nil then
			self.pickedUpObjectOverlay:setDimension(self.pickedUpObjectAimingWidth, self.pickedUpObjectAimingHeight)
			self.pickedUpObjectOverlay:setUVs(self.pickedUpObjectAimingUVs)
			self.pickedUpObjectOverlay:render()
		end
	end
end

function Player:onInputBindingsChanged()
	if self.isControlled then
		self:removeActionEvents()
		self:registerActionEvents()
		self:updateActionEvents()
	end
end

function Player:onEnter(isControlling)
	self:raiseActive()

	if self.foliageBendingNode ~= nil and self.foliageBendingId == nil and g_currentMission.foliageBendingSystem then
		self.foliageBendingId = g_currentMission.foliageBendingSystem:createRectangle(-0.5, 0.5, -0.5, 0.5, 0.4, self.foliageBendingNode)
	end

	if self.isServer then
		self:setOwner(self.networkInformation.creatorConnection)
	end

	if isControlling or self.isServer then
		self:raiseDirtyFlags(self.networkInformation.dirtyFlag)
	end

	self.isControlled = true

	if isControlling then
		g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.onInputBindingsChanged, self)
		g_currentMission:addPauseListeners(self, Player.onPausGame)
		setRotation(self.cameraNode, 0, 0, 0)
		setCamera(self.cameraNode)

		self.isEntered = true

		self:setVisibility(false)
		self:registerActionEvents()
	else
		self:setVisibility(true)
	end

	if self.isServer and not self.isEntered and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
		addTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.graphicsRootNode)
	end

	self.isLightActive = false
end

function Player:onLeaveVehicle()
	self.playerStateMachine:deactivateState("animalRide")
	self.playerStateMachine:deactivateState("jump")
end

function Player:onLeave()
	if self.isControlled then
		g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
	end

	g_soundManager:stopSamples(self.soundInformation.samples)
	self:removeActionEvents()

	for husbandryId, _ in pairs(g_currentMission.husbandries) do
		setAnimalInteressNode(husbandryId, 0)
	end

	if self.foliageBendingId ~= nil then
		g_currentMission.foliageBendingSystem:destroyObject(self.foliageBendingId)

		self.foliageBendingId = nil
	end

	if self.isServer then
		self:setOwner(nil)
	end

	if self.isEntered or self.isServer then
		self:raiseDirtyFlags(self.networkInformation.dirtyFlag)
	end

	if self.isServer and not self.isEntered and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
		removeTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.graphicsRootNode)
	end

	g_currentMission:addPauseListeners(self)

	self.networkInformation.history = {}
	self.isControlled = false
	self.isEntered = false

	self:setVisibility(false)

	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool:onDeactivate()
		self.baseInformation.currentHandtool:delete()

		self.baseInformation.currentHandtool = nil
	end

	local dogHouse = g_currentMission:getDoghouse(self.farmId)

	if dogHouse ~= nil and dogHouse.dog ~= nil then
		dogHouse.dog:onPlayerLeave(self)
	end

	if self.lightNode ~= nil then
		setVisibility(self.lightNode, false)
	end

	self:moveToAbsoluteInternal(0, -200, 0)
end

function Player:setVisibility(visibility)
	if self.meshThirdPerson ~= nil then
		setVisibility(self.meshThirdPerson, visibility)
		self.visualInformation:setVisibility(visibility)
	end
end

function Player:setWoodWorkVisibility(state, uvs)
	if self.isEntered then
		self.visualInformation:setProtectiveVisibility(false)
	end

	self.visualInformation:setProtectiveVisibility(state)
end

function Player:testScope(x, y, z, coeff)
	local x1, y1, z1 = getTranslation(self.rootNode)
	local dist = MathUtil.vector3Length(x1 - x, y1 - y, z1 - z)
	local clipDist = self.clipDistance

	if dist < clipDist * clipDist then
		return true
	else
		return false
	end
end

function Player:onGhostRemove()
	self:delete()
end

function Player:onGhostAdd()
end

function Player:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	if self.owner == connection then
		return 50
	end

	local x1, y1, z1 = getTranslation(self.rootNode)
	local dist = MathUtil.vector3Length(x1 - x, y1 - y, z1 - z)
	local clipDist = self.clipDistance

	return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end

function Player:consoleCommandToggleFlightAndNoHUDMode()
	g_flightAndNoHUDKeysEnabled = not g_flightAndNoHUDKeysEnabled

	if not g_flightAndNoHUDKeysEnabled then
		self.debugFlightMode = false
	end

	if GS_IS_MOBILE_VERSION then
		g_currentMission:onLeaveVehicle()
	end

	return "PlayerFlightAndNoHUDMode = " .. tostring(g_flightAndNoHUDKeysEnabled)
end

function Player.consoleCommandToggleWoodCuttingMaker(unusedSelf)
	g_woodCuttingMarkerEnabled = not g_woodCuttingMarkerEnabled

	return "WoodCuttingMarker = " .. tostring(g_woodCuttingMarkerEnabled)
end

function Player:consoleCommandToggleSuperStrongMode()
	if self.superStrengthEnabled then
		self.superStrengthEnabled = false
		Player.MAX_PICKABLE_OBJECT_MASS = 0.2

		return "Player now has normal strength"
	else
		self.superStrengthEnabled = true
		Player.MAX_PICKABLE_OBJECT_MASS = 25

		return "Player now has super-strength"
	end
end

function Player:deleteStartleAnimalData()
	if self.startleAnimalSoundTimerId then
		removeTimer(self.startleAnimalSoundTimerId)

		self.startleAnimalSoundTimerId = nil
	end

	self:deleteStartleAnimalSound()
end

function Player:deleteStartleAnimalSound()
	if self.startleAnimalSoundNode then
		delete(self.startleAnimalSoundNode)

		self.startleAnimalSoundNode = nil
	end

	self.startleAnimalSoundTimerId = nil
end

function Player.consoleCommandReloadIKChains(unusedSelf)
	local xmlFile = loadXMLFile("TempXML", g_currentMission.player.xmlFilename)
	local i = 0

	while true do
		local key = string.format("player.ikChains.ikChain(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local id = getXMLString(xmlFile, key .. "#id")
		local chain = g_currentMission.player.ikChains[id]

		if chain ~= nil then
			for k, node in pairs(chain.nodes) do
				local nodeKey = key .. string.format(".node(%d)", k - 1)
				node.minRx = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRx"), -180))
				node.maxRx = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRx"), 180))
				node.minRy = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRy"), -180))
				node.maxRy = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRy"), 180))
				node.minRz = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#minRz"), -180))
				node.maxRz = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#maxRz"), 180))
				node.damping = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, nodeKey .. "#damping"), 0))

				chain.ikChainSolver:setJointTransformGroup(k - 1, node.node, node.minRx, node.maxRx, node.minRy, node.maxRy, node.minRz, node.maxRz, node.damping)
			end
		end

		i = i + 1
	end

	g_currentMission.player:setIKDirty()
	delete(xmlFile)
end

function Player:groundRaycastCallback(hitObjectId, x, y, z, distance)
	self.belowPlayerObject = hitObjectId

	return false
end

function Player:pickUpObjectRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= g_currentMission.terrainDetailId and Player.PICKED_UP_OBJECTS[hitObjectId] ~= true and getRigidBodyType(hitObjectId) == "Dynamic" then
		local mass = getMass(hitObjectId)
		local canBePickedUp = true
		local object = g_currentMission:getNodeObject(hitObjectId)

		if object ~= nil then
			if object.dynamicMountObject ~= nil then
				canBePickedUp = false
			end

			if object.getTotalMass ~= nil then
				mass = object:getTotalMass()
			end

			if object.getCanBePickedUp ~= nil and not object:getCanBePickedUp(self) then
				canBePickedUp = false
			end
		end

		if canBePickedUp then
			self.lastFoundObject = hitObjectId
			self.lastFoundObjectMass = mass
			self.lastFoundObjectHitPoint = {
				x,
				y,
				z
			}
		end

		return false
	end

	return true
end

function Player:pickUpObject(state, noEventSend)
	PlayerPickUpObjectEvent.sendEvent(self, state, noEventSend)

	if self.isServer then
		if state and self.isObjectInRange and self.lastFoundObject ~= nil and not self.isCarryingObject then
			local constr = JointConstructor:new()
			self.pickedUpObjectCollisionMask = getCollisionMask(self.lastFoundObject)
			local newPickedUpObjectCollisionFlag = bitXOR(bitAND(self.pickedUpObjectCollisionMask, Player.movementCollisionMask), self.pickedUpObjectCollisionMask)

			setCollisionMask(self.lastFoundObject, newPickedUpObjectCollisionFlag)
			constr:setActors(self.pickUpKinematicHelperNode, self.lastFoundObject)

			for i = 0, 2 do
				constr:setRotationLimit(i, 0, 0)
				constr:setTranslationLimit(i, true, 0, 0)
			end

			local mx, my, mz = getCenterOfMass(self.lastFoundObject)
			local wx, wy, wz = localToWorld(self.lastFoundObject, mx, my, mz)

			constr:setJointWorldPositions(wx, wy, wz, wx, wy, wz)

			local nx, ny, nz = localDirectionToWorld(self.lastFoundObject, 1, 0, 0)

			constr:setJointWorldAxes(nx, ny, nz, nx, ny, nz)

			local yx, yy, yz = localDirectionToWorld(self.lastFoundObject, 0, 1, 0)

			constr:setJointWorldNormals(yx, yy, yz, yx, yy, yz)
			constr:setEnableCollision(false)
			setWorldTranslation(self.pickUpKinematicHelperNodeChild, wx, wy, wz)
			setWorldRotation(self.pickUpKinematicHelperNodeChild, getWorldRotation(self.lastFoundObject))

			local dampingRatio = 1
			local mass = getMass(self.lastFoundObject)
			local rotationLimitSpring = {}
			local rotationLimitDamper = {}

			for i = 1, 3 do
				rotationLimitSpring[i] = mass * 60
				rotationLimitDamper[i] = dampingRatio * 2 * math.sqrt(mass * rotationLimitSpring[i])
			end

			constr:setRotationLimitSpring(rotationLimitSpring[1], rotationLimitDamper[1], rotationLimitSpring[2], rotationLimitDamper[2], rotationLimitSpring[3], rotationLimitDamper[3])

			local translationLimitSpring = {}
			local translationLimitDamper = {}

			for i = 1, 3 do
				translationLimitSpring[i] = mass * 60
				translationLimitDamper[i] = dampingRatio * 2 * math.sqrt(mass * translationLimitSpring[i])
			end

			constr:setTranslationLimitSpring(translationLimitSpring[1], translationLimitDamper[1], translationLimitSpring[2], translationLimitDamper[2], translationLimitSpring[3], translationLimitDamper[3])

			local forceAcceleration = 4
			local forceLimit = forceAcceleration * mass * 40

			constr:setBreakable(forceLimit, forceLimit)

			self.pickedUpObjectJointId = constr:finalize()

			addJointBreakReport(self.pickedUpObjectJointId, "onPickedUpObjectJointBreak", self)

			self.pickedUpObject = self.lastFoundObject
			self.isCarryingObject = true
			Player.PICKED_UP_OBJECTS[self.pickedUpObject] = true
			local object = g_currentMission:getNodeObject(self.pickedUpObject)

			if object ~= nil then
				object.thrownFromPosition = nil
			end
		elseif self.pickedUpObjectJointId ~= nil then
			removeJoint(self.pickedUpObjectJointId)

			self.pickedUpObjectJointId = nil
			self.isCarryingObject = false
			Player.PICKED_UP_OBJECTS[self.pickedUpObject] = false

			if entityExists(self.pickedUpObject) then
				local vx, vy, vz = getLinearVelocity(self.pickedUpObject)
				vx = MathUtil.clamp(vx, -5, 5)
				vy = MathUtil.clamp(vy, -5, 5)
				vz = MathUtil.clamp(vz, -5, 5)

				setLinearVelocity(self.pickedUpObject, vx, vy, vz)
				setCollisionMask(self.pickedUpObject, self.pickedUpObjectCollisionMask)

				self.pickedUpObjectCollisionMask = 0
			end

			local object = g_currentMission:getNodeObject(self.pickedUpObject)

			if object ~= nil then
				object.thrownFromPosition = nil
			end

			self.pickedUpObject = nil
		end
	end
end

function Player:setLightIsActive(isActive, noEventSend)
	if isActive ~= self.isLightActive then
		self.isLightActive = isActive

		PlayerToggleLightEvent.sendEvent(self, isActive, noEventSend)
		setVisibility(self.lightNode, isActive)
		g_soundManager:playSample(self.soundInformation.samples.flashlight)
	end
end

function Player:loadHandTool(xmlFilename)
	if GS_IS_CONSOLE_VERSION and not fileExists(xmlFilename) then
		return nil
	end

	local dataStoreItem = g_storeManager:getItemByXMLFilename(xmlFilename)

	if dataStoreItem ~= nil then
		local storeItemXmlFilename = dataStoreItem.xmlFilename
		local xmlFile = loadXMLFile("TempXML", storeItemXmlFilename)
		local handToolType = getXMLString(xmlFile, "handTool.handToolType")

		delete(xmlFile)

		if handToolType ~= nil then
			local classObject = HandTool.handToolTypes[handToolType]

			if classObject == nil then
				local modName, _ = Utils.getModNameAndBaseDirectory(storeItemXmlFilename)

				if modName ~= nil then
					handToolType = modName .. "." .. handToolType
					classObject = HandTool.handToolTypes[handToolType]
				end
			end

			local handTool = nil

			if classObject ~= nil then
				handTool = classObject:new(self.isServer, self.isClient)
			else
				g_logManager:devError("Error: Invalid handtool type '%s'", handToolType)
			end

			if handTool ~= nil and not handTool:load(storeItemXmlFilename, self) then
				g_logManager:devError("Error: Failed to load handtool '%s'", storeItemXmlFilename)
				handTool:delete()

				handTool = nil
			end

			return handTool
		end
	end

	return nil
end

function Player:equipHandtool(handtoolFilename, force, noEventSend)
	if self.isOwner then
		if handtoolFilename == nil or handtoolFilename == "" then
			g_depthOfFieldManager:reset()
		else
			g_depthOfFieldManager:setManipulatedParams(0.8, 0.6, nil, , )
		end
	end

	PlayerSetHandToolEvent.sendEvent(self, handtoolFilename, force, noEventSend)

	if self:hasHandtoolEquipped() then
		if self.baseInformation.currentHandtool.configFileName:lower() ~= handtoolFilename:lower() or handtoolFilename == "" or force then
			self.baseInformation.currentHandtool:onDeactivate()
			self.baseInformation.currentHandtool:delete()

			self.baseInformation.currentHandtool = nil
		end

		if handtoolFilename ~= "" then
			self.baseInformation.currentHandtool = self:loadHandTool(handtoolFilename)
		end
	elseif handtoolFilename ~= "" then
		self.baseInformation.currentHandtool = self:loadHandTool(handtoolFilename)
	end

	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool:onActivate(self:getIsInputAllowed())
		self.baseInformation.currentHandtool:setHandNode(self.rightArmToolNode)

		local ikTargets = self.baseInformation.currentHandtool.targets

		if ikTargets ~= nil then
			for ikChainId, target in pairs(ikTargets) do
				IKUtil.setTarget(self.ikChains, ikChainId, target)
			end

			self:setIKDirty()
		end
	end
end

function Player:unequipHandtool()
	self:equipHandtool("", true)
end

function Player:hasHandtoolEquipped()
	return self.baseInformation.currentHandtool ~= nil
end

function Player:getEquippedHandtoolFilename()
	return self.baseInformation.currentHandtool ~= nil and self.baseInformation.currentHandtool.configFileName or ""
end

function Player:loadHandToolStopSample(xmlFile, xmlPath, xmlNode)
	if self.soundInformation.samples.handtoolStop.soundSample ~= nil then
		self:deleteHandToolStopSample()
	end

	local sample = g_soundManager:loadSampleFromXML(xmlFile, xmlPath, xmlNode, self.baseDirectory, self.rightArmToolNode, 1, AudioGroup.VEHICLE, nil, )
	self.soundInformation.samples.handtoolStop = sample
end

function Player:deleteHandToolStopSample()
	if self.soundInformation.samples.handtoolStop.soundSample ~= nil then
		g_soundManager:deleteSample(self.soundInformation.samples.handtoolStop)

		self.soundInformation.samples.handtoolStop = {}
		self.soundInformation.deleteHandtoolStopSampleAfterPlay = false
	end
end

function Player:playHandToolStopSample()
	if self.soundInformation.samples.handtoolStop.soundSample ~= nil then
		g_soundManager:playSample(self.soundInformation.samples.handtoolStop)

		self.soundInformation.deleteHandtoolStopSampleAfterPlay = true
	end
end

function Player:updatePlayHandToolStopSample()
	if self.soundInformation.deleteHandtoolStopSampleAfterPlay and self.soundInformation.samples.handtoolStop.soundSample ~= nil and not g_soundManager:getIsSamplePlaying(self.soundInformation.samples.handtoolStop) then
		self:deleteHandToolStopSample()
	end
end

function Player:onEnterFarmhouse()
	if self.isServer then
		local dogHouse = g_currentMission:getDoghouse(self.farmId)

		if dogHouse ~= nil and dogHouse.dog ~= nil and dogHouse.dog.entityFollow == self.rootNode then
			dogHouse.dog:teleportToSpawn()
		end
	end
end

function Player:throwObject(noEventSend)
	PlayerThrowObjectEvent.sendEvent(self, noEventSend)

	if self.pickedUpObject ~= nil and self.pickedUpObjectJointId ~= nil then
		local pickedUpObject = self.pickedUpObject

		self:pickUpObject(false)

		local mass = getMass(pickedUpObject)
		local v = 8 * (1.1 - mass / Player.MAX_PICKABLE_OBJECT_MASS)
		local vx, vy, vz = localDirectionToWorld(self.cameraNode, 0, 0, -v)

		setLinearVelocity(pickedUpObject, vx, vy, vz)

		local object = g_currentMission:getNodeObject(pickedUpObject)

		if object ~= nil then
			object.thrownFromPosition = {
				getWorldTranslation(self.rootNode)
			}

			if object:isa(DogBall) then
				local dogHouse = g_currentMission:getDoghouse(self.farmId)

				if dogHouse ~= nil and dogHouse.dog ~= nil and dogHouse.dog.playersInRange[self.rootNode] then
					dogHouse.dog:fetchItem(self, object)
				end
			end
		end
	elseif self.isObjectInRange and self.lastFoundObject ~= nil and not self.isCarryingObject then
		local mass = getMass(self.lastFoundObject)

		if mass <= Player.MAX_PICKABLE_OBJECT_MASS then
			local v = 8 * (1.1 - mass / Player.MAX_PICKABLE_OBJECT_MASS)
			local halfSqrt = 0.707106781
			local vx, vy, vz = localDirectionToWorld(self.cameraNode, 0, halfSqrt * v, -halfSqrt * v)

			setLinearVelocity(self.lastFoundObject, vx, vy, vz)
		end
	end
end

function Player:onPickedUpObjectJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.pickedUpObjectJointId then
		self:pickUpObject(false)
	end

	return false
end

function Player:getCurrentSurfaceSound(x, y, z)
	local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, y, z)
	self.belowPlayerObject = nil

	raycastClosest(x, y, z, 0, -1, 0, "groundRaycastCallback", 10, self, Player.kinematicCollisionMask)

	local hitTerrain = self.belowPlayerObject == g_currentMission.terrainRootNode
	local posY = y - self.baseInformation.capsuleTotalHeight * 0.5
	local deltaWater = posY - g_currentMission.waterY
	local waterLevel = self.baseInformation.waterLevel
	local shallowWater = waterLevel < deltaWater and deltaWater < 0

	if hitTerrain then
		local isOnField = densityBits ~= 0

		if isOnField then
			return self.soundInformation.surfaceNameToSound.field, shallowWater
		elseif shallowWater then
			return self.soundInformation.surfaceNameToSound.shallowWater, shallowWater
		else
			local _, _, _, _, materialId = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, x, y, z, true, true, true, true, false)

			return self.soundInformation.surfaceIdToSound[materialId], shallowWater
		end
	else
		return self.soundInformation.surfaceNameToSound.asphalt, shallowWater
	end
end

function Player:updateSound()
	local distanceToCheck = -1
	local forwardVel = 0

	if not self.isEntered then
		forwardVel = getConditionalAnimationFloatValue(self.animationInformation.player, self.animationInformation.parameters.absForwardVelocity.id)

		if self.playerStateMachine:isActive("crouch") then
			distanceToCheck = self.soundInformation.distancePerFootstep.crouch
		elseif math.abs(forwardVel) <= self.motionInformation.maxWalkingSpeed then
			distanceToCheck = self.soundInformation.distancePerFootstep.walk
		elseif self.motionInformation.maxWalkingSpeed < math.abs(forwardVel) then
			distanceToCheck = self.soundInformation.distancePerFootstep.run
		end
	else
		forwardVel = math.abs(self.motionInformation.currentSpeed)

		if self.playerStateMachine:isActive("crouch") then
			distanceToCheck = self.soundInformation.distancePerFootstep.crouch
		elseif self.playerStateMachine:isActive("walk") then
			distanceToCheck = self.soundInformation.distancePerFootstep.walk
		elseif self.playerStateMachine:isActive("run") then
			distanceToCheck = self.soundInformation.distancePerFootstep.run
		end
	end

	local isSwimming = self.playerStateMachine:isActive("swim")

	if distanceToCheck > 0 or isSwimming then
		local delta = self.motionInformation.coveredGroundDistance - self.soundInformation.distanceSinceLastFootstep
		delta = delta - distanceToCheck

		if delta > 0 or isSwimming then
			local wx, wy, wz = getWorldTranslation(self.rootNode)
			local sample, shallowWater = self:getCurrentSurfaceSound(wx, wy, wz)

			if not self.baseInformation.isInWater then
				if g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swim) then
					g_soundManager:stopSample(self.soundInformation.samples.swim)
				end

				if g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swimIdle) then
					g_soundManager:stopSample(self.soundInformation.samples.swimIdle)
				end
			end

			if self.baseInformation.isInWater and not shallowWater then
				if math.abs(forwardVel) < self.motionInformation.maxSwimmingSpeed * 0.75 then
					if g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swim) then
						g_soundManager:stopSample(self.soundInformation.samples.swim)
					end

					if not g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swimIdle) then
						g_soundManager:playSample(self.soundInformation.samples.swimIdle)
					end
				else
					if g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swimIdle) then
						g_soundManager:stopSample(self.soundInformation.samples.swimIdle)
					end

					if not g_soundManager:getIsSamplePlaying(self.soundInformation.samples.swim) then
						g_soundManager:playSample(self.soundInformation.samples.swim)
					end
				end
			elseif sample ~= nil then
				g_soundManager:playSample(sample)
			end

			self.soundInformation.distanceSinceLastFootstep = self.motionInformation.coveredGroundDistance + delta
		end
	end

	if self.baseInformation.plungedInWater then
		g_soundManager:playSample(self.soundInformation.samples.plunge)
	end

	self:updatePlayHandToolStopSample()
end

function Player:updateFX()
	if self.baseInformation.plungedInWater then
		local x, _, z = getWorldTranslation(self.rootNode)

		setWorldTranslation(self.particleSystemsInformation.plungeNode, x, g_currentMission.waterY, z)
		ParticleUtil.resetNumOfEmittedParticles(self.particleSystemsInformation.systems.plunge)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.plunge, true)
	end
end

function Player:movePlayer(dt, movementX, movementY, movementZ)
	self.debugFlightCoolDown = self.debugFlightCoolDown - 1

	if self.debugFlightMode then
		movementY = self.inputInformation.moveUp * dt
	end

	self.networkInformation.tickTranslation[1] = self.networkInformation.tickTranslation[1] + movementX
	self.networkInformation.tickTranslation[2] = self.networkInformation.tickTranslation[2] + movementY
	self.networkInformation.tickTranslation[3] = self.networkInformation.tickTranslation[3] + movementZ

	moveCCT(self.controllerIndex, movementX, movementY, movementZ, Player.movementCollisionMask)

	self.networkInformation.index = self.networkInformation.index + 1

	if not self.isServer then
		while table.getn(self.networkInformation.history) > 100 do
			table.remove(self.networkInformation.history, 1)
		end

		table.insert(self.networkInformation.history, {
			index = self.networkInformation.index,
			movementX = movementX,
			movementY = movementY,
			movementZ = movementZ
		})
	end
end

function Player:cameraBob(dt)
	local amplitude = 0
	local isSwimming = self.playerStateMachine:isActive("swim")
	local isWalking = self.playerStateMachine:isActive("walk")
	local isCrouching = self.playerStateMachine:isActive("crouch")
	local isRunning = self.playerStateMachine:isActive("run")
	local targetCameraOffset = 0
	local dtInSec = dt * 0.001

	if isSwimming then
		amplitude = 0.045
		targetCameraOffset = self.baseInformation.waterCameraOffset
	elseif isCrouching then
		amplitude = 0.045
	elseif isWalking or isRunning then
		amplitude = 0.025
	end

	if self.baseInformation.currentWaterCameraOffset ~= targetCameraOffset then
		local deltaOffset = targetCameraOffset - self.baseInformation.currentWaterCameraOffset

		if math.abs(deltaOffset) > 0.001 then
			self.baseInformation.currentWaterCameraOffset = self.baseInformation.currentWaterCameraOffset + deltaOffset * dtInSec / 0.75
		else
			self.baseInformation.currentWaterCameraOffset = self.baseInformation.currentWaterCameraOffset + deltaOffset
		end

		if math.abs(targetCameraOffset) > 0.001 then
			self.baseInformation.currentWaterCameraOffset = MathUtil.clamp(self.baseInformation.currentWaterCameraOffset, 0, targetCameraOffset)
		else
			self.baseInformation.currentWaterCameraOffset = math.max(self.baseInformation.currentWaterCameraOffset, 0)
		end
	end

	local delta = 0

	if amplitude ~= 0 then
		local actualSpeed = self.motionInformation.currentCoveredGroundDistance / dtInSec
		local dtInSecClamped = math.min(dtInSec, 0.06)
		local timeOffset, amplitudeScale = nil

		if isSwimming then
			timeOffset = math.min(math.max(self.motionInformation.currentCoveredGroundDistance * 1, 0.6 * dtInSecClamped), 3 * dtInSecClamped * 1)
			amplitudeScale = math.min(math.max(actualSpeed / 3, 0.5), 1)
		else
			timeOffset = math.min(self.motionInformation.currentCoveredGroundDistance, 3 * dtInSecClamped) * 3
			amplitudeScale = math.min(actualSpeed / 3, 1)
		end

		self.baseInformation.headBobTime = self.baseInformation.headBobTime + timeOffset
		amplitudeScale = (self.baseInformation.lastCameraAmplitudeScale + amplitudeScale) * 0.5
		delta = amplitudeScale * amplitude * math.sin(self.baseInformation.headBobTime) + self.baseInformation.currentWaterCameraOffset
		self.baseInformation.lastCameraAmplitudeScale = amplitudeScale
	else
		delta = self.baseInformation.currentWaterCameraOffset
	end

	local cameraY = self.camY
	local currentCamX, _, currentCamZ = getTranslation(self.cameraNode)

	if not isCrouching then
		setTranslation(self.cameraNode, currentCamX, cameraY + delta, currentCamZ)
	else
		local crouchState = self.playerStateMachine:getState("crouch")
		local crouchCamY = crouchState.crouchCameraY

		setTranslation(self.cameraNode, currentCamX, crouchCamY + delta, currentCamZ)
	end
end

function Player:resetInputsInformation()
	self.inputInformation.moveRight = 0
	self.inputInformation.moveForward = 0
	self.inputInformation.moveUp = 0
	self.inputInformation.runAxis = 0
end

function Player:resetCameraInputsInformation()
	self.inputInformation.pitchCamera = 0
	self.inputInformation.yawCamera = 0
	self.inputInformation.crouchState = Player.BUTTONSTATES.RELEASED
end

function Player:debugDraw()
	if self.baseInformation.isInDebug then
		setTextColor(1, 0, 0, 1)

		local line = 0.96

		renderText(0.05, line, 0.02, "[motion]")

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("isOnGround(%s) ", tostring(self.baseInformation.isOnGround)))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("lastPosition(%3.4f, %3.4f)", self.baseInformation.lastPositionX, self.baseInformation.lastPositionZ))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("distanceCovered(%.2f)", self.motionInformation.coveredGroundDistance))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("inWater(%s)", tostring(self.baseInformation.isInWater)))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("currentSpeed(%.3f) speedY(%.3f)", self.motionInformation.currentSpeed, self.motionInformation.currentSpeedY))

		line = line - 0.02

		setTextColor(0, 1, 0, 1)

		line = line - 0.02

		renderText(0.05, line, 0.02, "[input]")

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("right(%3.4f)", self.inputInformation.moveRight))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("forward(%3.4f)", self.inputInformation.moveForward))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("pitch(%3.4f)", self.inputInformation.pitchCamera))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("yaw(%3.4f)", self.inputInformation.yawCamera))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("runAxis(%3.4f)", self.inputInformation.runAxis))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("crouchState(%s)", tostring(self.inputInformation.crouchState)))

		line = line - 0.02

		renderText(0.05, line, 0.02, string.format("interactState(%s)", tostring(self.inputInformation.interactState)))

		line = line - 0.02
	end
end

function Player:getDesiredSpeed()
	local inputRight = self.inputInformation.moveRight
	local inputForward = self.inputInformation.moveForward

	if inputForward ~= 0 or inputRight ~= 0 then
		local isSwimming = self.playerStateMachine:isActive("swim")
		local isCrouching = self.playerStateMachine:isActive("crouch")
		local isFalling = self.playerStateMachine:isActive("fall")
		local isUsingHandtool = self:hasHandtoolEquipped()
		local maxSpeed = self.motionInformation.maxWalkingSpeed

		if isFalling then
			maxSpeed = self.motionInformation.maxFallingSpeed
		elseif isSwimming then
			maxSpeed = self.motionInformation.maxSwimmingSpeed
		elseif isCrouching then
			maxSpeed = self.motionInformation.maxCrouchingSpeed
		end

		local inputRun = self.inputInformation.runAxis

		if inputRun > 0 and not isSwimming and not isCrouching and not isUsingHandtool then
			local runningSpeed = self.motionInformation.maxRunningSpeed

			if g_addTestCommands and not g_isPresentationVersion then
				runningSpeed = self.motionInformation.maxPresentationRunningSpeed
			elseif g_addCheatCommands and not g_isPresentationVersion and (g_currentMission.isMasterUser or g_currentMission:getIsServer()) then
				runningSpeed = self.motionInformation.maxCheatRunningSpeed
			end

			maxSpeed = math.max(maxSpeed + (runningSpeed - maxSpeed) * math.min(inputRun, 1), maxSpeed)
		end

		local magnitude = math.sqrt(inputRight * inputRight + inputForward * inputForward)
		local desiredSpeed = MathUtil.clamp(magnitude, 0, 1) * maxSpeed

		return desiredSpeed
	end

	return 0
end

function Player:recordPositionInformation()
	local currentPositionX, _, currentPositionZ = getTranslation(self.graphicsRootNode)
	local deltaPosX = currentPositionX - self.baseInformation.lastPositionX
	local deltaPosZ = currentPositionZ - self.baseInformation.lastPositionZ
	self.baseInformation.lastPositionX = currentPositionX
	self.baseInformation.lastPositionZ = currentPositionZ
	local groundDistanceCovered = MathUtil.vector2Length(deltaPosX, deltaPosZ)
	self.motionInformation.justMoved = groundDistanceCovered > 0

	if self.baseInformation.isOnGround then
		self.motionInformation.currentCoveredGroundDistance = groundDistanceCovered
		self.motionInformation.coveredGroundDistance = self.motionInformation.coveredGroundDistance + groundDistanceCovered
	end
end

function Player:calculate2DDotProductAgainstVelocity(velocity, currentSpeed, vector)
	local normalizedVelX = velocity[1] / currentSpeed
	local normalizedVelZ = velocity[3] / currentSpeed
	local vectorMagnitude = math.sqrt(vector[1] * vector[1] + vector[3] * vector[3])
	local normalizedVectorX = vector[1] / vectorMagnitude
	local normalizedVectorZ = vector[3] / vectorMagnitude
	local dot = normalizedVelX * normalizedVectorX + normalizedVelZ * normalizedVectorZ

	return dot
end

function Player:resetBrake()
	self:setVelocityToMotion(0, 0, 0)
	self:setAccelerationToMotion(0, 0, 0)

	self.motionInformation.brakeForce = {
		0,
		0,
		0
	}
	self.motionInformation.isBraking = false
end

function Player:updateKinematic(dt)
	local dtInSec = dt * 0.001
	local inputX = self.inputInformation.moveRight
	local inputZ = self.inputInformation.moveForward

	if inputX ~= 0 or inputZ ~= 0 then
		local normInputX, normInputZ = MathUtil.vector2Normalize(inputX, inputZ)
		self.motionInformation.currentWorldDirX, _, self.motionInformation.currentWorldDirZ = localDirectionToWorld(self.cameraNode, normInputX, 0, normInputZ)
		self.motionInformation.currentWorldDirX, self.motionInformation.currentWorldDirZ = MathUtil.vector2Normalize(self.motionInformation.currentWorldDirX, self.motionInformation.currentWorldDirZ)
	end

	local desiredSpeed = self:getDesiredSpeed()
	local desiredSpeedX = self.motionInformation.currentWorldDirX * desiredSpeed
	local desiredSpeedZ = self.motionInformation.currentWorldDirZ * desiredSpeed
	local speedChangeX = desiredSpeedX - self.motionInformation.currentSpeedX
	local speedChangeZ = desiredSpeedZ - self.motionInformation.currentSpeedZ

	if not self.baseInformation.isOnGround then
		speedChangeX = speedChangeX * 0.2
		speedChangeZ = speedChangeZ * 0.2
	end

	self.motionInformation.currentSpeedX = self.motionInformation.currentSpeedX + speedChangeX
	self.motionInformation.currentSpeedZ = self.motionInformation.currentSpeedZ + speedChangeZ
	self.motionInformation.currentSpeed = math.sqrt(self.motionInformation.currentSpeedX * self.motionInformation.currentSpeedX + self.motionInformation.currentSpeedZ * self.motionInformation.currentSpeedZ)
	local movementX = self.motionInformation.currentSpeedX * dtInSec
	local movementY = 0
	local movementZ = self.motionInformation.currentSpeedZ * dtInSec
	local _, y, _ = getWorldTranslation(self.rootNode)
	local deltaWater = y - g_currentMission.waterY - self.baseInformation.capsuleTotalHeight * 0.5
	local waterLevel = self.baseInformation.waterLevel
	local distToWaterLevel = deltaWater - waterLevel

	if distToWaterLevel > 0.001 then
		local gravityFactor = 3
		local gravitySpeedChange = gravityFactor * self.motionInformation.gravity * dtInSec
		self.motionInformation.currentSpeedY = math.max(self.motionInformation.currentSpeedY + gravitySpeedChange, self.motionInformation.gravity * 7)

		if distToWaterLevel < self.baseInformation.capsuleTotalHeight * 0.5 then
			movementY = math.max(self.motionInformation.currentSpeedY * dtInSec, -distToWaterLevel * 0.5)
		else
			movementY = math.max(self.motionInformation.currentSpeedY * dtInSec, -distToWaterLevel)
		end

		self.motionInformation.currentSpeedY = movementY / math.max(dtInSec, 1e-06)
	elseif distToWaterLevel < -0.01 then
		local buoyancySpeed = -self.motionInformation.gravity
		movementY = math.min(buoyancySpeed * dtInSec, -distToWaterLevel)
		self.motionInformation.currentSpeedY = movementY / math.max(dtInSec, 1e-06)
	else
		self.motionInformation.currentSpeedY = 0
	end

	self:movePlayer(dt, movementX, movementY, movementZ)
end

function Player:updatePlayerStates()
	if self.playerStateMachine:isAvailable("fall") then
		self.playerStateMachine:activateState("fall")
	end

	if self.baseInformation.isInWater and self.playerStateMachine:isAvailable("swim") then
		self.playerStateMachine:activateState("swim")
		self.playerStateMachine:deactivateState("crouch")
	end

	if self.inputInformation.moveForward ~= 0 or self.inputInformation.moveRight ~= 0 then
		if self.inputInformation.runAxis > 0 and self.playerStateMachine:isAvailable("run") then
			self.playerStateMachine:activateState("run")
		elseif self.playerStateMachine:isAvailable("walk") then
			self.playerStateMachine:activateState("walk")
		end
	else
		self.playerStateMachine:activateState("idle")
	end
end

function Player:setWalkingLock(isLocked)
	self.walkingIsLocked = isLocked

	for _, inputRegistration in pairs(self.inputInformation.registrationList) do
		if inputRegistration.activeType == Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT then
			g_inputBinding:setActionEventActive(inputRegistration.eventId, not isLocked)
		end
	end

	if not isLocked then
		self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, Player.touchEventLookUpDown, self)
		self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, Player.touchEventLookLeftRight, self)
	else
		g_touchHandler:removeGestureListener(self.touchListenerY)
		g_touchHandler:removeGestureListener(self.touchListenerX)
	end
end

function Player:consoleCommandTogglePlayerDebug()
	self.baseInformation.isInDebug = not self.baseInformation.isInDebug

	return "Player Debug = " .. tostring(self.baseInformation.isInDebug)
end

function Player:setFarm(farmId)
	if self.isServer then
		self.farmId = farmId

		PlayerSetFarmEvent.sendEvent(self, farmId)
	else
		g_logManager:devError("Error: setFarm only allowed on Server")
	end
end

function Player:onFarmChange()
	self:updateHandTools()
end

function Player:updateHandTools()
	if self:hasHandtoolEquipped() then
		local farm = g_farmManager:getFarmById(self.farmId)

		if not ListUtil.hasListElement(farm.handTools, self.baseInformation.currentHandtool.configFileName) then
			self.baseInformation.currentHandtool:onDeactivate()
			self.baseInformation.currentHandtool:delete()

			self.baseInformation.currentHandtool = nil
		end
	end
end

function Player:registerActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)

	for actionId, inputRegisterEntry in pairs(self.inputInformation.registrationList) do
		local eventAdded = false
		local startActive = false

		if inputRegisterEntry.activeType == Player.INPUT_ACTIVE_TYPE.STARTS_ENABLED then
			startActive = true
		elseif inputRegisterEntry.activeType == Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED then
			startActive = false
		elseif inputRegisterEntry.activeType == Player.INPUT_ACTIVE_TYPE.IS_MOVEMENT then
			startActive = not self.walkingIsLocked
		elseif inputRegisterEntry.activeType == Player.INPUT_ACTIVE_TYPE.IS_CARRYING then
			startActive = self.isCarryingObject
		elseif inputRegisterEntry.activeType == Player.INPUT_ACTIVE_TYPE.IS_DEBUG then
			startActive = self.baseInformation.isInDebug
		end

		eventAdded, inputRegisterEntry.eventId = g_inputBinding:registerActionEvent(actionId, self, inputRegisterEntry.callback, inputRegisterEntry.triggerUp, inputRegisterEntry.triggerDown, inputRegisterEntry.triggerAlways, startActive, inputRegisterEntry.callbackState, true)

		if inputRegisterEntry.text ~= nil and inputRegisterEntry.text ~= "" then
			g_inputBinding:setActionEventText(inputRegisterEntry.eventId, inputRegisterEntry.text)
		end

		g_inputBinding:setActionEventTextVisibility(inputRegisterEntry.eventId, inputRegisterEntry.textVisibility)
	end

	if not self.walkingIsLocked then
		self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, Player.touchEventLookUpDown, self)
		self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, Player.touchEventLookLeftRight, self)
	else
		g_touchHandler:removeGestureListener(self.touchListenerY)
		g_touchHandler:removeGestureListener(self.touchListenerX)
	end

	g_inputBinding:endActionEventsModification()
end

function Player:removeActionEvents()
	g_inputBinding:resetActiveActionBindings()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)

	for _, inputRegisterEntry in pairs(self.inputInformation.registrationList) do
		inputRegisterEntry.eventId = ""
	end

	g_inputBinding:endActionEventsModification()
end

function Player:touchEventLookLeftRight(value)
	if self:getIsInputAllowed() then
		local factor = g_screenWidth / g_screenHeight * 100

		Player.onInputLookLeftRight(self, nil, value * factor, nil, , false)
	end
end

function Player:onInputLookLeftRight(_, inputValue, _, _, isMouse)
	if not self.lockedInput then
		if isMouse then
			inputValue = inputValue * 0.001 * 16.666
		else
			inputValue = inputValue * g_currentDt * 0.001
		end

		self.inputInformation.yawCamera = self.inputInformation.yawCamera + inputValue
	end

	self.inputInformation.isMouseRotation = isMouse
end

function Player:touchEventLookUpDown(value)
	if self:getIsInputAllowed() then
		local factor = g_screenHeight / g_screenWidth * -100

		Player.onInputLookUpDown(self, nil, value * factor, nil, , false)
	end
end

function Player:onInputLookUpDown(_, inputValue, _, _, isMouse)
	if not self.lockedInput then
		local pitchValue = g_gameSettings:getValue("invertYLook") and -inputValue or inputValue

		if isMouse then
			pitchValue = pitchValue * 0.001 * 16.666
		else
			pitchValue = pitchValue * g_currentDt * 0.001
		end

		self.inputInformation.pitchCamera = self.inputInformation.pitchCamera + pitchValue
	end
end

function Player:onInputMoveSide(_, inputValue)
	if not self.lockedInput then
		self.inputInformation.moveRight = self.inputInformation.moveRight + inputValue
	end
end

function Player:onInputMoveForward(_, inputValue)
	if not self.lockedInput then
		self.inputInformation.moveForward = self.inputInformation.moveForward + inputValue
	end
end

function Player:onInputRun(_, inputValue)
	self.inputInformation.runAxis = inputValue

	if self.debugFlightMode then
		if inputValue > 0 and self.debugFlightModeRunningFactor ~= 4 then
			self.debugFlightModeRunningFactor = 4
		elseif inputValue == 0 and self.debugFlightModeRunningFactor ~= 1 then
			self.debugFlightModeRunningFactor = 1
		end
	end
end

function Player:onInputCrouch(_, inputValue)
	if self.playerStateMachine:isAvailable("crouch") then
		self.playerStateMachine:activateState("crouch")
	end

	self.inputInformation.crouchState = Player.BUTTONSTATES.PRESSED
end

function Player:onInputRotateObjectHorizontally(_, inputValue)
	if self.pickedUpObjectJointId ~= nil and math.abs(inputValue) > 0 then
		self:rotateObject(inputValue, 0, 1, 0)
	elseif self.isCarryingObject and self.isClient and self.isControlled then
		if inputValue ~= 0 then
			self.networkInformation.rotateObject = true
		else
			self.networkInformation.rotateObject = false
		end

		self.networkInformation.rotateObjectInputH = inputValue
	end
end

function Player:onInputRotateObjectVertically(_, inputValue)
	if self.pickedUpObjectJointId ~= nil and math.abs(inputValue) > 0 then
		self:rotateObject(inputValue, 1, 0, 0)
	elseif self.isCarryingObject and self.isClient and self.isControlled then
		if inputValue ~= 0 then
			self.networkInformation.rotateObject = true
		else
			self.networkInformation.rotateObject = false
		end

		self.networkInformation.rotateObjectInputV = inputValue
	end
end

function Player:rotateObject(inputValue, axisX, axisY, axisZ)
	local jointIndex = self.pickedUpObjectJointId
	local actor = 0
	local objectTransform = self.pickUpKinematicHelperNodeChild
	local rotX, rotY, rotZ = localDirectionToLocal(self.cameraNode, objectTransform, axisX, axisY, axisZ)
	local dtInSec = g_physicsDt * 0.001
	local rotation = math.rad(90) * dtInSec * inputValue

	rotateAboutLocalAxis(objectTransform, rotation, rotX, rotY, rotZ)
	setJointFrame(jointIndex, actor, objectTransform)
end

function Player:onInputJump(_, inputValue)
	if self.playerStateMachine:isAvailable("jump") then
		self.playerStateMachine:activateState("jump")
	end
end

function Player:onInputInteract(_, inputValue)
	if self.inputInformation.interactState ~= Player.BUTTONSTATES.PRESSED and inputValue ~= 0 then
		if self.playerStateMachine:isAvailable("drop") then
			self.playerStateMachine:activateState("drop")
		elseif self.playerStateMachine:isAvailable("pickup") then
			self.playerStateMachine:activateState("pickup")
		elseif self.playerStateMachine:isAvailable("animalInteract") then
			self.playerStateMachine:activateState("animalInteract")
		end

		self.inputInformation.interactState = Player.BUTTONSTATES.PRESSED
	else
		self.inputInformation.interactState = Player.BUTTONSTATES.RELEASED
	end
end

function Player:onInputActivateObject(_, inputValue)
	if self.playerStateMachine:isAvailable("activateObject") then
		self.playerStateMachine:activateState("activateObject")
	elseif self.playerStateMachine:isAvailable("animalFeed") then
		self.playerStateMachine:activateState("animalFeed")
	elseif self.playerStateMachine:isAvailable("animalPet") then
		self.playerStateMachine:activateState("animalPet")
	end
end

function Player:onInputToggleLight()
	if self.playerStateMachine:isAvailable("useLight") then
		self.playerStateMachine:activateState("useLight")
	end
end

function Player:onInputCycleHandTool(_, _, direction)
	if self.playerStateMachine:isAvailable("cycleHandtool") then
		local cycleHandtoolState = self.playerStateMachine:getState("cycleHandtool")
		cycleHandtoolState.cycleDirection = direction

		self.playerStateMachine:activateState("cycleHandtool")
	end
end

function Player:onInputThrowObject(_, inputValue)
	if self.playerStateMachine:isAvailable("throw") then
		self.playerStateMachine:activateState("throw")
	end
end

function Player:onInputDebugFlyToggle()
	if not self.walkingIsDisabled and self.debugFlightCoolDown <= 0 and g_flightAndNoHUDKeysEnabled then
		self.debugFlightMode = not self.debugFlightMode
		self.debugFlightCoolDown = 10
	end
end

function Player:onInputDebugFlyUpDown(_, inputValue)
	if not self.walkingIsDisabled then
		local move = inputValue * 0.5 * self.debugFlightModeWalkingSpeed * self.debugFlightModeRunningFactor
		self.inputInformation.moveUp = self.inputInformation.moveUp + move
	end
end

function Player:onInputEnter(_, inputValue)
	if g_time > g_currentMission.lastInteractionTime + 200 then
		local enterVehicle = false

		if g_currentMission.interactiveVehicleInRange and g_currentMission.accessHandler:canFarmAccess(self.farmId, g_currentMission.interactiveVehicleInRange) then
			g_currentMission.interactiveVehicleInRange:interact()

			enterVehicle = true
		elseif self.canRideAnimal then
			self.playerStateMachine:activateState("animalRide")

			enterVehicle = true
		end
	end
end

function Player:onInputActivateHandtool(_, inputValue)
	if self:hasHandtoolEquipped() then
		self.baseInformation.currentHandtool.activatePressed = inputValue ~= 0
	end
end

function Player:getIsRideStateAvailable()
	if not self.playerStateMachine:isActive("animalRide") then
		return self.playerStateMachine:isAvailable("animalRide")
	end

	return false
end

function Player:activateRideState()
	if not self.playerStateMachine:isActive("animalRide") then
		self.playerStateMachine:activateState("animalRide")
	end
end

function Player:onPausGame(isPaused)
	self:lockInput(isPaused)
end
