Rideable = {}

source("dataS/scripts/vehicles/specializations/events/JumpEvent.lua")

Rideable.GAITTYPES = {
	GALLOP = 6,
	MIN = 1,
	TROT = 4,
	MAX = 6,
	BACKWARDS = 1,
	WALK = 3,
	CANTER = 5,
	STILL = 2
}
Rideable.HOOVES = {
	BACK_RIGHT = 4,
	BACK_LEFT = 3,
	FRONT_RIGHT = 2,
	FRONT_LEFT = 1
}
Rideable.GROUND_RAYCAST_OFFSET = 1.2
Rideable.GROUND_RAYCAST_MAXDISTANCE = 5
Rideable.GROUND_RAYCAST_COLLISIONMASK = 59

function Rideable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(CCTDrivable, specializations)
end

function Rideable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsRideableJumpAllowed", Rideable.getIsRideableJumpAllowed)
	SpecializationUtil.registerFunction(vehicleType, "jump", Rideable.jump)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentGait", Rideable.setCurrentGait)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentGait", Rideable.getCurrentGait)
	SpecializationUtil.registerFunction(vehicleType, "setRideableSteer", Rideable.setRideableSteer)
	SpecializationUtil.registerFunction(vehicleType, "resetInputs", Rideable.resetInputs)
	SpecializationUtil.registerFunction(vehicleType, "updateKinematic", Rideable.updateKinematic)
	SpecializationUtil.registerFunction(vehicleType, "testCCTMove", Rideable.testCCTMove)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimation", Rideable.updateAnimation)
	SpecializationUtil.registerFunction(vehicleType, "updateSound", Rideable.updateSound)
	SpecializationUtil.registerFunction(vehicleType, "updateFitness", Rideable.updateFitness)
	SpecializationUtil.registerFunction(vehicleType, "updateDirt", Rideable.updateDirt)
	SpecializationUtil.registerFunction(vehicleType, "calculateLegsDistance", Rideable.calculateLegsDistance)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuat", Rideable.setWorldPositionQuat)
	SpecializationUtil.registerFunction(vehicleType, "setShaderParameter", Rideable.setShaderParameter)
	SpecializationUtil.registerFunction(vehicleType, "getShaderParameter", Rideable.getShaderParameter)
	SpecializationUtil.registerFunction(vehicleType, "updateFootsteps", Rideable.updateFootsteps)
	SpecializationUtil.registerFunction(vehicleType, "getPosition", Rideable.getPosition)
	SpecializationUtil.registerFunction(vehicleType, "getRotation", Rideable.getRotation)
	SpecializationUtil.registerFunction(vehicleType, "setDirtScale", Rideable.setDirtScale)
	SpecializationUtil.registerFunction(vehicleType, "getDirtScale", Rideable.getDirtScale)
	SpecializationUtil.registerFunction(vehicleType, "setFitnessChangedCallback", Rideable.setFitnessChangedCallback)
	SpecializationUtil.registerFunction(vehicleType, "setRidingHorse", Rideable.setRidingHorse)
	SpecializationUtil.registerFunction(vehicleType, "getHorseRidingScale", Rideable.getHorseRidingScale)
	SpecializationUtil.registerFunction(vehicleType, "setDirtChangedCallback", Rideable.setDirtChangedCallback)
	SpecializationUtil.registerFunction(vehicleType, "isOnHusbandyGround", Rideable.isOnHusbandyGround)
	SpecializationUtil.registerFunction(vehicleType, "setEquipmentVisibility", Rideable.setEquipmentVisibility)
	SpecializationUtil.registerFunction(vehicleType, "abandonCheck", Rideable.abandonCheck)
	SpecializationUtil.registerFunction(vehicleType, "getHoofSurfaceSound", Rideable.getHoofSurfaceSound)
	SpecializationUtil.registerFunction(vehicleType, "removeRideable", Rideable.removeRideable)
	SpecializationUtil.registerFunction(vehicleType, "setAnimal", Rideable.setAnimal)
	SpecializationUtil.registerFunction(vehicleType, "groundRaycastCallback", Rideable.groundRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "unlinkReins", Rideable.unlinkReins)
	SpecializationUtil.registerFunction(vehicleType, "updateInputText", Rideable.updateInputText)
	SpecializationUtil.registerFunction(vehicleType, "setPlayerToEnter", Rideable.setPlayerToEnter)
	SpecializationUtil.registerFunction(vehicleType, "endFade", Rideable.endFade)
end

function Rideable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadPositionUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onWritePositionUpdateStream", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Rideable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Rideable)
end

function Rideable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPosition", Rideable.setWorldPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Rideable.setWorldPositionQuaternion)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehicleSpeed", Rideable.updateVehicleSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Rideable.getName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", Rideable.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Rideable.getCanBeReset)
end

function Rideable:onLoad(savegame)
	local spec = self.spec_rideable
	self.highPrecisionPositionSynchronization = true
	self.isVehicleSaved = false
	spec.currentDirtScale = 0
	spec.abandonTimerDuration = g_gameSettings:getValue("horseAbandonTimerDuration")
	spec.abandonTimer = spec.abandonTimerDuration
	spec.fadeDuration = 400
	spec.isRideableRemoved = false
	spec.justSpawned = true
	spec.meshNode = nil
	spec.hairNode = nil
	spec.animationNode = nil
	spec.charsetId = nil
	spec.animationPlayer = 0
	spec.animationParameters = {
		forwardVelocity = {
			value = 0,
			id = 1,
			type = 1
		},
		verticalVelocity = {
			value = 0,
			id = 2,
			type = 1
		},
		yawVelocity = {
			value = 0,
			id = 3,
			type = 1
		},
		absForwardVelocity = {
			value = 0,
			id = 4,
			type = 1
		},
		onGround = {
			value = false,
			id = 5,
			type = 0
		},
		inWater = {
			value = false,
			id = 6,
			type = 0
		},
		closeToGround = {
			value = false,
			id = 7,
			type = 0
		},
		leftRightWeight = {
			value = 0,
			id = 8,
			type = 1
		},
		absYawVelocity = {
			value = 0,
			id = 9,
			type = 1
		},
		halted = {
			value = false,
			id = 10,
			type = 0
		},
		smoothedForwardVelocity = {
			value = 0,
			id = 11,
			type = 1
		},
		absSmoothedForwardVelocity = {
			value = 0,
			id = 12,
			type = 1
		}
	}
	spec.acceletateEventId = ""
	spec.brakeEventId = ""
	spec.steerEventId = ""
	spec.jumpEventId = ""
	spec.currentTurnAngle = 0
	spec.currentTurnSpeed = 0
	spec.currentSpeed = 0
	spec.currentSpeedY = 0
	spec.isInWater = false
	spec.cctMoveQueue = {}
	spec.currentCCTPosX = 0
	spec.currentCCTPosY = 0
	spec.currentCCTPosZ = 0
	spec.lastCCTPosX = 0
	spec.lastCCTPosY = 0
	spec.lastCCTPosZ = 0
	spec.topSpeeds = {
		[Rideable.GAITTYPES.BACKWARDS] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#speedBackwards"), -1),
		[Rideable.GAITTYPES.STILL] = 0,
		[Rideable.GAITTYPES.WALK] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#speedWalk"), 2.5),
		[Rideable.GAITTYPES.CANTER] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#speedCanter"), 3.5),
		[Rideable.GAITTYPES.TROT] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#speedTrot"), 5),
		[Rideable.GAITTYPES.GALLOP] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#speedGallop"), 10)
	}
	spec.minTurnRadius = {
		[Rideable.GAITTYPES.BACKWARDS] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#minTurnRadiusBackwards"), 1),
		[Rideable.GAITTYPES.STILL] = 1,
		[Rideable.GAITTYPES.WALK] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#minTurnRadiusWalk"), 1),
		[Rideable.GAITTYPES.CANTER] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#minTurnRadiusCanter"), 2.5),
		[Rideable.GAITTYPES.TROT] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#minTurnRadiusTrot"), 5),
		[Rideable.GAITTYPES.GALLOP] = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#minTurnRadiusGallop"), 10)
	}
	spec.groundRaycastResult = {
		y = 0,
		object = nil,
		distance = 0
	}
	spec.haltTimer = 0
	spec.smoothedLeftRightWeight = 0
	spec.interpolationDt = 16
	spec.maxAcceleration = 5
	spec.maxDeceleration = 10
	spec.gravity = -18.8
	spec.frontCheckDistance = 0
	spec.backCheckDistance = 0
	spec.isOnGround = true
	spec.isCloseToGround = true

	assert(spec.topSpeeds[Rideable.GAITTYPES.MIN] < spec.topSpeeds[Rideable.GAITTYPES.MAX])

	spec.maxTurnSpeed = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#turnSpeed"), 45))
	spec.jumpHeight = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable#jumpHeight"), 2)

	local function loadHoof(target, index, key)
		local hoof = {
			node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings),
			onGround = false,
			psSlow = {}
		}

		ParticleUtil.loadParticleSystem(self.xmlFile, hoof.psSlow, key .. ".particleSystemSlow", getRootNode(), false, nil, self.baseDirectory)

		hoof.psFast = {}

		ParticleUtil.loadParticleSystem(self.xmlFile, hoof.psFast, key .. ".particleSystemFast", getRootNode(), false, nil, self.baseDirectory)

		target[index] = hoof
	end

	spec.hooves = {}

	loadHoof(spec.hooves, Rideable.HOOVES.FRONT_LEFT, "vehicle.rideable.modelInfo.hoofFrontLeft")
	loadHoof(spec.hooves, Rideable.HOOVES.FRONT_RIGHT, "vehicle.rideable.modelInfo.hoofFrontRight")
	loadHoof(spec.hooves, Rideable.HOOVES.BACK_LEFT, "vehicle.rideable.modelInfo.hoofBackLeft")
	loadHoof(spec.hooves, Rideable.HOOVES.BACK_RIGHT, "vehicle.rideable.modelInfo.hoofBackRight")

	spec.frontCheckDistance = self:calculateLegsDistance(spec.hooves[Rideable.HOOVES.FRONT_LEFT].node, spec.hooves[Rideable.HOOVES.FRONT_RIGHT].node)
	spec.backCheckDistance = self:calculateLegsDistance(spec.hooves[Rideable.HOOVES.BACK_LEFT].node, spec.hooves[Rideable.HOOVES.BACK_RIGHT].node)
	spec.animationNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#animationNode"), self.i3dMappings)
	spec.meshNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#meshNode"), self.i3dMappings)
	spec.hairNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#hairNode"), self.i3dMappings)
	spec.equipmentNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#equipmentNode"), self.i3dMappings)
	spec.reinsNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#reinsNode"), self.i3dMappings)
	spec.leftReinNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#reinLeftNode"), self.i3dMappings)
	spec.rightReinNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.rideable.modelInfo#reinRightNode"), self.i3dMappings)
	spec.leftReinParentNode = getParent(spec.leftReinNode)
	spec.rightReinParentNode = getParent(spec.rightReinNode)

	if spec.animationNode ~= nil then
		spec.charsetId = getAnimCharacterSet(spec.animationNode)
		spec.animationPlayer = createConditionalAnimation()

		for key, parameter in pairs(spec.animationParameters) do
			conditionalAnimationRegisterParameter(spec.animationPlayer, parameter.id, parameter.type, key)
		end

		initConditionalAnimation(spec.animationPlayer, spec.charsetId, self.configFileName, "vehicle.conditionalAnimation")
		setConditionalAnimationSpecificParameterIds(spec.animationPlayer, spec.animationParameters.absForwardVelocity.id, spec.animationParameters.absYawVelocity.id)
	end

	spec.surfaceSounds = {}
	spec.surfaceIdToSound = {}
	spec.surfaceNameToSound = {}
	spec.currentSurfaceSound = nil

	for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
		if surfaceSound.type == "hoofstep" and surfaceSound.sample ~= nil then
			local sample = g_soundManager:cloneSample(surfaceSound.sample, self.components[1].node, self)
			sample.sampleName = surfaceSound.name

			table.insert(spec.surfaceSounds, sample)

			spec.surfaceIdToSound[surfaceSound.materialId] = sample
			spec.surfaceNameToSound[surfaceSound.name] = sample
		end
	end

	spec.horseStopSound = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "halt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathSoundsNoEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingNoEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathSoundsEffort = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.rideable.sounds", "breathingEffort", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.horseBreathIntervalNoEffort = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable.sounds#breathIntervalNoEffort"), 1) * 1000
	spec.horseBreathIntervalEffort = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable.sounds#breathIntervalEffort"), 1) * 1000
	spec.horseBreathMinIntervalIdle = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable.sounds#minBreathIntervalIdle"), 1) * 1000
	spec.horseBreathMaxIntervalIdle = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.rideable.sounds#maxBreathIntervalIdle"), 1) * 1000
	spec.currentBreathTimer = 0
	spec.inputValues = {
		axisSteer = 0,
		axisSteerSend = 0,
		currentGait = Rideable.GAITTYPES.STILL
	}

	self:resetInputs()

	spec.interpolatorIsOnGround = InterpolatorValue:new(0)

	if self.isServer then
		spec.interpolatorTurnAngle = InterpolatorAngle:new(0)
	end

	if self.isServer then
		self.networkTimeInterpolator.maxInterpolationAlpha = 1.2
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Rideable:setWorldPosition(superFunc, x, y, z, xRot, yRot, zRot, i, changeInterp)
	superFunc(self, x, y, z, xRot, yRot, zRot, i, changeInterp)

	if self.isServer and i == 1 then
		local spec = self.spec_rideable
		local dx, dy, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
		spec.currentTurnAngle = MathUtil.getYRotationFromDirection(dx, dz)

		if changeInterp then
			spec.interpolatorTurnAngle:setAngle(spec.currentTurnAngle)
		end
	end
end

function Rideable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)

	if self.isServer and i == 1 then
		local spec = self.spec_rideable
		local dx, dy, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
		spec.currentTurnAngle = MathUtil.getYRotationFromDirection(dx, dz)

		if changeInterp then
			spec.interpolatorTurnAngle:setAngle(spec.currentTurnAngle)
		end
	end
end

function Rideable:updateVehicleSpeed(superFunc, dt)
	if self.isServer then
		local spec = self.spec_rideable

		superFunc(self, spec.interpolationDt)
	else
		local spec = self.spec_rideable

		superFunc(self, dt)
	end
end

function Rideable:calculateLegsDistance(leftLegNode, rightLegNode)
	local distance = 0

	if leftLegNode ~= nil and rightLegNode ~= nil then
		local dxL, dyL, dzL = localToLocal(leftLegNode, self.rootNode, 0, 0, 0)
		local dxR, dyR, dzR = localToLocal(rightLegNode, self.rootNode, 0, 0, 0)
		distance = (dzL + dzR) * 0.5
	end

	return distance
end

function Rideable:onDelete()
	local spec = self.spec_rideable

	g_soundManager:deleteSamples(spec.surfaceSounds)
	g_soundManager:deleteSample(spec.horseStopSound)
	g_soundManager:deleteSample(spec.horseBreathSoundsNoEffort)
	g_soundManager:deleteSample(spec.horseBreathSoundsEffort)

	for _, d in pairs(spec.hooves) do
		ParticleUtil.deleteParticleSystem(d.psSlow)
		ParticleUtil.deleteParticleSystem(d.psFast)
	end

	if spec.animationPlayer ~= 0 then
		delete(spec.animationPlayer)

		spec.animationPlayer = 0
	end
end

function Rideable:onReadStream(streamId, connection)
	local spec = self.spec_rideable

	if connection:getIsServer() then
		local isOnGround = streamReadBool(streamId)

		if isOnGround then
			spec.interpolatorIsOnGround:setValue(1)
		else
			spec.interpolatorIsOnGround:setValue(0)
		end
	end

	if streamReadBool(streamId) then
		local animal = NetworkUtil.readNodeObject(streamId)

		self:setAnimal(animal)
	end

	if streamReadBool(streamId) then
		local player = NetworkUtil.readNodeObject(streamId)

		self:setPlayerToEnter(player)
	end
end

function Rideable:onWriteStream(streamId, connection)
	local spec = self.spec_rideable

	if not connection:getIsServer() then
		streamWriteBool(streamId, spec.isOnGround)
	end

	if streamWriteBool(streamId, spec.animal ~= nil) then
		NetworkUtil.writeNodeObject(streamId, spec.animal)
	end

	if streamWriteBool(streamId, spec.playerToEnter ~= nil) then
		NetworkUtil.writeNodeObject(streamId, spec.playerToEnter)
	end
end

function Rideable:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_rideable

	if not connection:getIsServer() then
		spec.inputValues.axisSteer = streamReadFloat32(streamId)
		spec.inputValues.currentGait = streamReadUInt8(streamId)
	else
		spec.haltTimer = streamReadFloat32(streamId)

		if spec.haltTimer > 0 then
			spec.inputValues.currentGait = Rideable.GAITTYPES.STILL
			spec.inputValues.axisSteerSend = 0
		end
	end
end

function Rideable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_rideable

	if connection:getIsServer() then
		streamWriteFloat32(streamId, spec.inputValues.axisSteerSend)
		streamWriteUInt8(streamId, spec.inputValues.currentGait)
	else
		streamWriteFloat32(streamId, spec.haltTimer)
	end
end

function Rideable:onReadPositionUpdateStream(streamId, connection)
	local spec = self.spec_rideable
	local isOnGround = streamReadBool(streamId)

	if isOnGround then
		spec.interpolatorIsOnGround:setValue(1)
	else
		spec.interpolatorIsOnGround:setValue(0)
	end
end

function Rideable:onWritePositionUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_rideable

	streamWriteBool(streamId, spec.isOnGround)
end

function Rideable:endFade()
end

function Rideable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_rideable

	if spec.playerToEnter ~= nil and spec.checkPlayerToEnter and spec.playerToEnter == g_currentMission.player then
		g_currentMission:requestToEnterVehicle(self)

		spec.checkPlayerToEnter = false
	end

	local isEntered = self:getIsEntered()
	local isControlled = self:getIsControlled()

	if isEntered then
		if isActiveForInputIgnoreSelection then
			self:updateInputText()
		end

		if not self.isServer then
			spec.inputValues.axisSteerSend = spec.inputValues.axisSteer

			self:raiseDirtyFlags(spec.dirtyFlag)
			self:resetInputs()
		end
	end

	if spec.isOnGround and spec.justSpawned then
		spec.justSpawned = false

		if not spec.checkPlayerToEnter and isEntered or spec.checkPlayerToEnter and spec.playerToEnter == g_currentMission.player then
			g_currentMission:fadeScreen(-1, spec.fadeDuration, self.endFade, self)
		end
	end

	self:updateAnimation(dt)

	if self.isClient then
		self:updateSound(dt)
	end

	if self.isServer then
		self:updateFitness(dt)
		self:updateDirt(dt)
	end

	if spec.haltTimer > 0 then
		self:setCurrentGait(Rideable.GAITTYPES.STILL)

		spec.haltTimer = spec.haltTimer - dt
	end

	if self.isServer and not isEntered and not isControlled and spec.playerToEnter == nil then
		self:abandonCheck(dt)
	end

	if self:getIsActiveForInput(true) then
		local inputHelpMode = g_inputBinding:getInputHelpMode()

		if (inputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
			local dx, dy, dz = getGravityDirection()
			local steeringValue = MathUtil.getSteeringAngleFromDeviceGravity(dx, dy, dz)

			self:setRideableSteer(steeringValue)
		end
	end

	self:raiseActive()
end

function Rideable:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_rideable

	if self.isServer then
		if not self:getIsControlled() then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)
		end

		local interpolationDt = dt
		local oldestMoveInfo = spec.cctMoveQueue[1]

		if oldestMoveInfo ~= nil and getIsPhysicsUpdateIndexSimulated(oldestMoveInfo.physicsIndex) then
			interpolationDt = oldestMoveInfo.dt
		end

		spec.interpolationDt = interpolationDt

		self:testCCTMove(interpolationDt)
		self:updateKinematic(dt)

		if self:getIsEntered() then
			self:resetInputs()
		end

		local component = self.components[1]
		local x, y, z = self:getCCTWorldTranslation()

		component.networkInterpolators.position:setTargetPosition(x, y, z)
		spec.interpolatorTurnAngle:setTargetAngle(spec.currentTurnAngle)
		spec.interpolatorIsOnGround:setTargetValue(self:getIsCCTOnGround() and 1 or 0)

		local phaseDuration = interpolationDt + 30

		self.networkTimeInterpolator:startNewPhase(phaseDuration)
		self.networkTimeInterpolator:update(interpolationDt)

		local x, y, z = component.networkInterpolators.position:getInterpolatedValues(self.networkTimeInterpolator.interpolationAlpha)

		setTranslation(self.rootNode, x, y, z)

		local turnAngle = spec.interpolatorTurnAngle:getInterpolatedValue(self.networkTimeInterpolator.interpolationAlpha)
		local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		dirZ = math.cos(turnAngle)
		dirX = math.sin(turnAngle)
		local scale = math.sqrt(1 - math.min(dirY * dirY, 0.9))
		dirX = dirX * scale
		dirZ = dirZ * scale

		setDirection(self.rootNode, dirX, dirY, dirZ, 0, 1, 0)

		if self.networkTimeInterpolator.isDirty then
			self:raiseActive()
		end
	end

	local isOnGroundFloat = spec.interpolatorIsOnGround:getInterpolatedValue(self.networkTimeInterpolator:getAlpha())
	spec.isOnGround = isOnGroundFloat > 0.9
	spec.isCloseToGround = false

	if spec.isOnGround and (math.abs(spec.currentSpeed) > 0.001 or math.abs(spec.currentTurnSpeed) > 0.001) then
		local posX, posY, posZ = getWorldTranslation(self.rootNode)
		local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local fx = posX + dirX * spec.frontCheckDistance
		local fy = posY + dirY * spec.frontCheckDistance
		local fz = posZ + dirZ * spec.frontCheckDistance
		spec.groundRaycastResult.y = fy + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE

		raycastClosest(fx, fy + Rideable.GROUND_RAYCAST_OFFSET, fz, 0, -1, 0, "groundRaycastCallback", Rideable.GROUND_RAYCAST_MAXDISTANCE, self, Rideable.GROUND_RAYCAST_COLLISIONMASK)

		fy = spec.groundRaycastResult.y
		local bx = posX + dirX * spec.backCheckDistance
		local by = posY + dirY * spec.backCheckDistance
		local bz = posZ + dirZ * spec.backCheckDistance
		spec.groundRaycastResult.y = by + Rideable.GROUND_RAYCAST_OFFSET - Rideable.GROUND_RAYCAST_MAXDISTANCE

		raycastClosest(bx, by + Rideable.GROUND_RAYCAST_OFFSET, bz, 0, -1, 0, "groundRaycastCallback", Rideable.GROUND_RAYCAST_MAXDISTANCE, self, Rideable.GROUND_RAYCAST_COLLISIONMASK)

		by = spec.groundRaycastResult.y
		local dx = fx - bx
		local dy = fy - by
		local dz = fz - bz

		setDirection(self.rootNode, dx, dy, dz, 0, 1, 0)
	else
		local posX, posY, posZ = getWorldTranslation(self.rootNode)
		spec.groundRaycastResult.distance = Rideable.GROUND_RAYCAST_MAXDISTANCE

		raycastClosest(posX, posY, posZ, 0, -1, 0, "groundRaycastCallback", Rideable.GROUND_RAYCAST_MAXDISTANCE, self, Rideable.GROUND_RAYCAST_COLLISIONMASK)

		spec.isCloseToGround = spec.groundRaycastResult.distance < 1.25
	end
end

function Rideable:onSetBroken()
	self:removeRideable()
	self:unlinkReins()

	local spec = self.spec_rideable

	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), spec.animal:getName()))
end

function Rideable:testCCTMove(dt)
	local spec = self.spec_rideable
	spec.lastCCTPosZ = spec.currentCCTPosZ
	spec.lastCCTPosY = spec.currentCCTPosY
	spec.lastCCTPosX = spec.currentCCTPosX
	spec.currentCCTPosX, spec.currentCCTPosY, spec.currentCCTPosZ = getWorldTranslation(self.spec_cctdrivable.cctNode)
	local expectedMovementX = 0
	local expectedMovementZ = 0

	while spec.cctMoveQueue[1] ~= nil and getIsPhysicsUpdateIndexSimulated(spec.cctMoveQueue[1].physicsIndex) do
		expectedMovementX = expectedMovementX + spec.cctMoveQueue[1].moveX
		expectedMovementZ = expectedMovementZ + spec.cctMoveQueue[1].moveZ

		table.remove(spec.cctMoveQueue, 1)
	end

	local expectedMovement = math.sqrt(expectedMovementX * expectedMovementX + expectedMovementZ * expectedMovementZ)

	if expectedMovement > 0.001 * dt then
		local movementX = spec.currentCCTPosX - spec.lastCCTPosX
		local movementZ = spec.currentCCTPosZ - spec.lastCCTPosZ
		local movement = math.sqrt(movementX * movementX + movementZ * movementZ)

		if movement <= expectedMovement * 0.7 and spec.haltTimer <= 0 then
			self:setCurrentGait(Rideable.GAITTYPES.STILL)

			spec.haltTimer = 900

			if spec.horseStopSound ~= nil then
				g_soundManager:playSample(spec.horseStopSound)
			end
		end
	end
end

function Rideable:getIsRideableJumpAllowed(allowWhileJump)
	local spec = self.spec_rideable

	if not spec.isOnGround and not allowWhileJump then
		return false
	end

	if spec.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
		return false
	end

	if spec.isInWater then
		return false
	end

	return true
end

function Rideable:jump()
	local spec = self.spec_rideable

	if not self.isServer then
		g_client:getServerConnection():sendEvent(JumpEvent:new(self))
	end

	local velY = math.sqrt(-2 * spec.gravity * spec.jumpHeight)
	spec.currentSpeedY = velY
end

function Rideable:setCurrentGait(gait)
	local spec = self.spec_rideable
	spec.inputValues.currentGait = gait
end

function Rideable:getCurrentGait()
	return self.spec_rideable.inputValues.currentGait
end

function Rideable:setRideableSteer(axisSteer)
	local spec = self.spec_rideable

	if axisSteer ~= 0 then
		spec.inputValues.axisSteer = -axisSteer
	end
end

function Rideable:resetInputs()
	local spec = self.spec_rideable
	spec.inputValues.axisSteer = 0
end

function Rideable:updateKinematic(dt)
	local spec = self.spec_rideable
	local dtInSec = dt * 0.001
	local desiredSpeed = spec.topSpeeds[spec.inputValues.currentGait]
	local maxSpeedChange = spec.maxAcceleration

	if desiredSpeed == 0 then
		maxSpeedChange = spec.maxDeceleration
	end

	maxSpeedChange = maxSpeedChange * dtInSec

	if not spec.isOnGround then
		maxSpeedChange = maxSpeedChange * 0.2
	end

	local speedChange = desiredSpeed - spec.currentSpeed
	speedChange = MathUtil.clamp(speedChange, -maxSpeedChange, maxSpeedChange)

	if spec.haltTimer <= 0 then
		spec.currentSpeed = spec.currentSpeed + speedChange
	else
		spec.currentSpeed = 0
	end

	local movement = spec.currentSpeed * dtInSec
	local gravitySpeedChange = spec.gravity * dtInSec
	spec.currentSpeedY = spec.currentSpeedY + gravitySpeedChange
	local movementY = spec.currentSpeedY * dtInSec
	local slowestSpeed = spec.topSpeeds[Rideable.GAITTYPES.WALK]
	local fastestSpeed = spec.topSpeeds[Rideable.GAITTYPES.MAX]
	local maxTurnSpeedChange = MathUtil.clamp((fastestSpeed - spec.currentSpeed) / (fastestSpeed - slowestSpeed), 0, 1) * 0.4 + 0.8
	maxTurnSpeedChange = maxTurnSpeedChange * dtInSec

	if not spec.isOnGround then
		maxTurnSpeedChange = maxTurnSpeedChange * 0.25
	end

	if self.isServer and not self:getIsEntered() and not self:getIsControlled() and spec.inputValues.axisSteer ~= 0 then
		spec.inputValues.axisSteer = 0
	end

	local desiredTurnSpeed = spec.maxTurnSpeed * spec.inputValues.axisSteer
	local turnSpeedChange = desiredTurnSpeed - spec.currentTurnSpeed
	turnSpeedChange = MathUtil.clamp(turnSpeedChange, -maxTurnSpeedChange, maxTurnSpeedChange)
	spec.currentTurnSpeed = spec.currentTurnSpeed + turnSpeedChange
	spec.currentTurnAngle = spec.currentTurnAngle + spec.currentTurnSpeed * dtInSec * (movement >= 0 and 1 or -1)
	local movementX = math.sin(spec.currentTurnAngle) * movement
	local movementZ = math.cos(spec.currentTurnAngle) * movement

	self:moveCCT(movementX, movementY, movementZ, true)
	table.insert(spec.cctMoveQueue, {
		physicsIndex = getPhysicsUpdateIndex(),
		moveX = movementX,
		moveY = movementY,
		moveZ = movementZ,
		dt = dt
	})
end

function Rideable:groundRaycastCallback(hitObjectId, x, y, z, distance)
	local spec = self.spec_rideable

	if hitObjectId == self.spec_cctdrivable.cctNode then
		return true
	end

	spec.groundRaycastResult.y = y
	spec.groundRaycastResult.object = hitObjectId
	spec.groundRaycastResult.distance = distance

	return false
end

function Rideable:updateAnimation(dt)
	local spec = self.spec_rideable
	local params = spec.animationParameters
	local speed = self.lastSignedSpeedReal * 1000
	local smoothedSpeed = self.lastSignedSpeed * 1000
	speed = MathUtil.clamp(speed, spec.topSpeeds[Rideable.GAITTYPES.BACKWARDS], spec.topSpeeds[Rideable.GAITTYPES.MAX])
	smoothedSpeed = MathUtil.clamp(smoothedSpeed, spec.topSpeeds[Rideable.GAITTYPES.BACKWARDS], spec.topSpeeds[Rideable.GAITTYPES.MAX])
	local turnSpeed = nil

	if self.isServer then
		turnSpeed = (spec.interpolatorTurnAngle.targetValue - spec.interpolatorTurnAngle.lastValue) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	else
		local interpQuat = self.components[1].networkInterpolators.quaternion
		local lastDirX, lastDirY, lastDirZ = mathQuaternionRotateVector(interpQuat.lastQuaternionX, interpQuat.lastQuaternionY, interpQuat.lastQuaternionZ, interpQuat.lastQuaternionW, 0, 0, 1)
		local targetDirX, targetDirY, targetDirZ = mathQuaternionRotateVector(interpQuat.targetQuaternionX, interpQuat.targetQuaternionY, interpQuat.targetQuaternionZ, interpQuat.targetQuaternionW, 0, 0, 1)
		local lastTurnAngle = MathUtil.getYRotationFromDirection(lastDirX, lastDirZ)
		local targetTurnAngle = MathUtil.getYRotationFromDirection(targetDirX, targetDirZ)
		local turnAngleDiff = targetTurnAngle - lastTurnAngle

		if math.pi < turnAngleDiff then
			turnAngleDiff = turnAngleDiff - 2 * math.pi
		elseif turnAngleDiff < -math.pi then
			turnAngleDiff = turnAngleDiff + 2 * math.pi
		end

		turnSpeed = turnAngleDiff / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	end

	local interpPos = self.components[1].networkInterpolators.position
	local speedY = (interpPos.targetPositionY - interpPos.lastPositionY) / (self.networkTimeInterpolator.interpolationDuration * 0.001)
	local leftRightWeight = 0

	if math.abs(speed) > 0.01 then
		local closestGait = Rideable.GAITTYPES.STILL
		local closestDiff = math.huge

		for i = 1, Rideable.GAITTYPES.MAX do
			local diff = math.abs(speed - spec.topSpeeds[i])

			if diff < closestDiff then
				closestGait = i
				closestDiff = diff
			end
		end

		local minTurnRadius = spec.minTurnRadius[closestGait]
		leftRightWeight = minTurnRadius * turnSpeed / speed
	else
		leftRightWeight = turnSpeed / spec.maxTurnSpeed
	end

	if leftRightWeight < spec.smoothedLeftRightWeight then
		spec.smoothedLeftRightWeight = math.max(leftRightWeight, spec.smoothedLeftRightWeight - 0.002 * dt, -1)
	else
		spec.smoothedLeftRightWeight = math.min(leftRightWeight, spec.smoothedLeftRightWeight + 0.002 * dt, 1)
	end

	params.forwardVelocity.value = speed
	params.absForwardVelocity.value = math.abs(speed)
	params.verticalVelocity.value = speedY
	params.yawVelocity.value = turnSpeed
	params.absYawVelocity.value = math.abs(turnSpeed)
	params.leftRightWeight.value = spec.smoothedLeftRightWeight
	params.onGround.value = spec.isOnGround or spec.justSpawned
	params.closeToGround.value = spec.isCloseToGround
	params.inWater.value = spec.isInWater
	params.halted.value = spec.haltTimer > 0
	params.smoothedForwardVelocity.value = smoothedSpeed
	params.absSmoothedForwardVelocity.value = math.abs(smoothedSpeed)

	if spec.animationPlayer ~= 0 then
		for _, parameter in pairs(params) do
			if parameter.type == 0 then
				setConditionalAnimationBoolValue(spec.animationPlayer, parameter.id, parameter.value)
			elseif parameter.type == 1 then
				setConditionalAnimationFloatValue(spec.animationPlayer, parameter.id, parameter.value)
			end
		end

		updateConditionalAnimation(spec.animationPlayer, dt)
	end

	local isEntered = self.getIsEntered ~= nil and self:getIsEntered()
	local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

	if isEntered or isControlled then
		local character = self:getVehicleCharacter()

		if character ~= nil and character.animationCharsetId ~= 0 and character.animationPlayer ~= nil then
			for _, parameter in pairs(params) do
				if parameter.type == 0 then
					setConditionalAnimationBoolValue(character.animationPlayer, parameter.id, parameter.value)
				elseif parameter.type == 1 then
					setConditionalAnimationFloatValue(character.animationPlayer, parameter.id, parameter.value)
				end
			end

			updateConditionalAnimation(character.animationPlayer, dt)
		end
	end

	self:updateFootsteps(dt, math.abs(speed))
end

function Rideable:updateSound(dt)
	local spec = self.spec_rideable

	if spec.horseBreathSoundsEffort ~= nil and spec.horseBreathSoundsNoEffort ~= nil and spec.isOnGround then
		spec.currentBreathTimer = spec.currentBreathTimer - dt
		spec.currentBreathTimer = math.max(spec.currentBreathTimer, 0)

		if spec.currentBreathTimer == 0 then
			if spec.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
				g_soundManager:playSample(spec.horseBreathSoundsEffort)

				spec.currentBreathTimer = spec.horseBreathIntervalEffort
			else
				g_soundManager:playSample(spec.horseBreathSoundsNoEffort)

				if spec.inputValues.currentGait == Rideable.GAITTYPES.STILL then
					spec.currentBreathTimer = spec.horseBreathMinIntervalIdle + math.random() * (spec.horseBreathMaxIntervalIdle - spec.horseBreathMinIntervalIdle)
				else
					spec.currentBreathTimer = spec.horseBreathIntervalNoEffort
				end
			end
		end
	end
end

function Rideable:setWorldPositionQuat(x, y, z, qx, qy, qz, qw, changeInterp)
	setWorldTranslation(self.rootNode, x, y, z)
	setWorldQuaternion(self.rootNode, qx, qy, qz, qw)

	if changeInterp then
		local spec = self.spec_rideable

		spec.networkInterpolators.position:setPosition(x, y, z)
		spec.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	end
end

function Rideable:setShaderParameter(x, y, z, w, parameterName)
	local spec = self.spec_rideable

	I3DUtil.setShaderParameterRec(spec.meshNode, parameterName, x, y, z, w)
	I3DUtil.setShaderParameterRec(spec.hairNode, parameterName, x, y, z, w)
end

function Rideable:getShaderParameter(parameterName)
	local spec = self.spec_rideable
	local x, y, z, w = getShaderParameter(spec.meshNode, parameterName)

	return x, y, z, w
end

function Rideable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_rideable

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local actionEventId = nil
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Rideable.actionEventAccelerate, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			spec.acceletateEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Rideable.actionEventBrake, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			spec.brakeEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Rideable.actionEventSteer, false, false, true, true, nil)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			spec.steerEventId = actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.JUMP, self, Rideable.actionEventJump, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventTextVisibility(actionEventId, false)

			spec.jumpEventId = actionEventId
		end
	end
end

function Rideable:onEnterVehicle(isControlling)
	if self.isClient then
		local spec = self.spec_rideable
		spec.playerToEnter = nil
		spec.checkPlayerToEnter = false
		spec.currentSpeed = 0
		spec.currentTurnSpeed = 0

		self:setCurrentGait(Rideable.GAITTYPES.STILL)

		spec.isOnGround = false
		local character = self:getVehicleCharacter()

		if character ~= nil and character.animationCharsetId ~= 0 and character.animationPlayer ~= 0 then
			for key, parameter in pairs(spec.animationParameters) do
				conditionalAnimationRegisterParameter(character.animationPlayer, parameter.id, parameter.type, key)
			end

			initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.riderConditionalAnimation")
			setConditionalAnimationSpecificParameterIds(character.animationPlayer, spec.animationParameters.absForwardVelocity.id, spec.animationParameters.absYawVelocity.id)
			link(character.thirdPersonLeftHandNode, spec.leftReinNode)
			link(character.thirdPersonRightHandNode, spec.rightReinNode)
			setVisibility(spec.reinsNode, true)
			self:setEquipmentVisibility(true)
			conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
			conditionalAnimationZeroiseTrackTimes(spec.animationPlayer)
		end
	end
end

function Rideable:onLeaveVehicle()
	if self.isClient then
		local spec = self.spec_rideable
		spec.inputValues.currentGait = Rideable.GAITTYPES.STILL

		self:resetInputs()

		if g_currentMission.hud.fadeScreenElement:getAlpha() > 0 then
			g_currentMission:fadeScreen(-1, spec.fadeDuration, self.endFade, self)
		end
	end
end

function Rideable:unlinkReins()
	if self.isClient then
		local spec = self.spec_rideable

		link(spec.leftReinParentNode, spec.leftReinNode)
		link(spec.rightReinParentNode, spec.rightReinNode)
		setVisibility(spec.reinsNode, false)
	end
end

function Rideable:setEquipmentVisibility(val)
	if self.isClient then
		local spec = self.spec_rideable

		if spec.equipmentNode ~= nil then
			setVisibility(spec.equipmentNode, val)
			setVisibility(spec.reinsNode, val)
		end
	end
end

function Rideable:actionEventAccelerate(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable
	local enterable = self.spec_enterable

	if enterable.isEntered and enterable.isControlled and spec.haltTimer <= 0 and spec.isOnGround then
		self:setCurrentGait(math.min(self:getCurrentGait() + 1, Rideable.GAITTYPES.MAX))
	end
end

function Rideable:actionEventBrake(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable

	if self:getIsEntered() and spec.haltTimer <= 0 and spec.isOnGround then
		self:setCurrentGait(math.max(self:getCurrentGait() - 1, 1))
	end
end

function Rideable:actionEventSteer(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_rideable

	if self:getIsEntered() and spec.haltTimer <= 0 then
		self:setRideableSteer(inputValue)
	end
end

function Rideable:actionEventJump(actionName, inputValue, callbackState, isAnalog)
	if self:getIsRideableJumpAllowed() then
		self:jump()
	end
end

function Rideable:updateFootsteps(dt, speed)
	local spec = self.spec_rideable
	local epsilon = 0.001

	if speed > epsilon then
		for k, hoofInfo in pairs(spec.hooves) do
			local posX, posY, posZ = getWorldTranslation(hoofInfo.node)
			spec.groundRaycastResult.object = 0
			spec.groundRaycastResult.y = posY - 1

			raycastClosest(posX, posY + Rideable.GROUND_RAYCAST_OFFSET, posZ, 0, -1, 0, "groundRaycastCallback", Rideable.GROUND_RAYCAST_MAXDISTANCE, self, Rideable.GROUND_RAYCAST_COLLISIONMASK)

			local hitTerrain = spec.groundRaycastResult.object == g_currentMission.terrainRootNode
			local terrainY = spec.groundRaycastResult.y
			local onGround = posY - terrainY < 0.05

			if onGround and not hoofInfo.onGround then
				local r, g, b, _, _ = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, posX, posY, posZ, true, true, true, true, false)
				hoofInfo.onGround = true

				if spec.inputValues.currentGait < Rideable.GAITTYPES.CANTER then
					ParticleUtil.resetNumOfEmittedParticles(hoofInfo.psSlow)
					ParticleUtil.setEmittingState(hoofInfo.psSlow, true)
					setTranslation(hoofInfo.psSlow.emitterShape, posX, terrainY, posZ)
					setShaderParameter(hoofInfo.psSlow.shape, "psColor", r, g, b, 1, false)
				else
					ParticleUtil.resetNumOfEmittedParticles(hoofInfo.psFast)
					ParticleUtil.setEmittingState(hoofInfo.psFast, true)
					setTranslation(hoofInfo.psFast.emitterShape, posX, terrainY, posZ)
					setShaderParameter(hoofInfo.psFast.shape, "psColor", r, g, b, 1, false)
				end

				local sample = self:getHoofSurfaceSound(posX, posY, posZ, hitTerrain)

				if sample ~= nil then
					hoofInfo.sampleDebug = string.format("%s - %s", sample.sampleName, sample.filename)

					g_soundManager:playSample(sample)
				end
			elseif not onGround and hoofInfo.onGround then
				hoofInfo.onGround = false

				ParticleUtil.setEmittingState(hoofInfo.psSlow, false)
				ParticleUtil.setEmittingState(hoofInfo.psFast, false)
			end
		end
	end
end

function Rideable:updateDirt(dt)
	local spec = self.spec_rideable

	if spec.dirtChangedCallbackFunc ~= nil and spec.inputValues.currentGait ~= Rideable.GAITTYPES.STILL then
		local delta = dt / 600000
		local newScale = MathUtil.clamp(spec.currentDirtScale + delta, 0, 1)

		self:setDirtScale(newScale)
		spec.dirtChangedCallbackFunc(spec.dirtChangedCallbackTarget, newScale)
	end
end

function Rideable:updateFitness(dt)
	local spec = self.spec_rideable

	if spec.fitnessChangedCallbackFunc ~= nil and spec.currentSpeed ~= 0 then
		spec.fitnessChangedCallbackFunc(spec.fitnessChangedCallbackTarget, dt)
	end
end

function Rideable:getHoofSurfaceSound(x, y, z, hitTerrain)
	local spec = self.spec_rideable
	local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, y, z)
	local hitTerrain = hitTerrain
	local inWater = y < g_currentMission.waterY

	if hitTerrain then
		local isOnField = densityBits ~= 0

		if isOnField then
			return spec.surfaceNameToSound.field
		elseif inWater then
			return spec.surfaceNameToSound.shallowWater
		else
			local _, _, _, _, materialId = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, x, y, z, true, true, true, true, false)

			return spec.surfaceIdToSound[materialId]
		end
	else
		return spec.surfaceNameToSound.asphalt
	end
end

function Rideable:getPosition()
	return getWorldTranslation(self.rootNode)
end

function Rideable:getRotation()
	return getWorldRotation(self.rootNode)
end

function Rideable:setDirtScale(scale)
	local spec = self.spec_rideable
	spec.currentDirtScale = scale
	local x, _, z, w = getShaderParameter(spec.meshNode, "RDT")

	I3DUtil.setShaderParameterRec(spec.meshNode, "RDT", x, spec.currentDirtScale, z, w)
	I3DUtil.setShaderParameterRec(spec.hairNode, "RDT", x, spec.currentDirtScale, z, w)
end

function Rideable:getDirtScale()
	local spec = self.spec_rideable

	return spec.currentDirtScale
end

function Rideable:setDirtChangedCallback(dirtChangedCallbackFunc, dirtChangedCallbackTarget)
	local spec = self.spec_rideable
	spec.dirtChangedCallbackFunc = dirtChangedCallbackFunc
	spec.dirtChangedCallbackTarget = dirtChangedCallbackTarget
end

function Rideable:setFitnessChangedCallback(fitnessChangedCallbackFunc, fitnessChangedCallbackTarget)
	local spec = self.spec_rideable
	spec.fitnessChangedCallbackFunc = fitnessChangedCallbackFunc
	spec.fitnessChangedCallbackTarget = fitnessChangedCallbackTarget
end

function Rideable:setRidingHorse(horse)
	local spec = self.spec_rideable
	spec.horse = horse
end

function Rideable:getHorseRidingScale()
	local spec = self.spec_rideable

	if spec.horse ~= nil then
		return spec.horse.ridingScale
	end

	return 0
end

function Rideable:isOnHusbandyGround(deliveryArea)
	if deliveryArea ~= nil and deliveryArea.startNode ~= nil and deliveryArea.heightNode ~= nil and deliveryArea.heightNode ~= nil then
		local x, y, z = getWorldTranslation(self.rootNode)
		local xl, _, zl = worldToLocal(deliveryArea.startNode, x, y, z)
		local xw, _, _ = getTranslation(deliveryArea.widthNode)
		local _, _, zh = getTranslation(deliveryArea.heightNode)
		local result = xl >= 0 and zl >= 0 and xl < xw and zl < zh

		return result
	end

	return false
end

function Rideable:abandonCheck(dt)
	local spec = self.spec_rideable

	if spec.animal == nil then
		return
	end

	local isOnHusbandry = spec.animal:isOnHusbandyGround()

	if isOnHusbandry then
		self:removeRideable()
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), spec.animal:getName()))

		return
	end

	local range = 250
	local isPlayerInRange = false

	for _, player in pairs(g_currentMission.players) do
		if player.isControlled then
			local distance = calcDistanceFrom(self.rootNode, player.rootNode)

			if distance < range then
				isPlayerInRange = true

				break
			end
		end
	end

	if not isPlayerInRange then
		for _, enterable in pairs(g_currentMission.enterables) do
			if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled then
				local distance = calcDistanceFrom(self.rootNode, enterable.rootNode)

				if distance < range then
					isPlayerInRange = true

					break
				end
			end
		end
	end

	if isPlayerInRange then
		spec.abandonTimer = spec.abandonTimerDuration
	else
		spec.abandonTimer = spec.abandonTimer - dt

		if spec.abandonTimer <= 0 then
			self:removeRideable()
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), spec.animal:getName()))
		end
	end

	if spec.abandonTimer > 0 then
		self:raiseActive()
	end
end

function Rideable:setAnimal(animal)
	local spec = self.spec_rideable
	spec.animal = animal

	if animal ~= nil then
		local x, y, z, w = getShaderParameter(spec.meshNode, "RDT")
		local dirt = animal:getDirtScale()

		setShaderParameter(spec.meshNode, "RDT", x, dirt, z, w, false)

		local x, y, _, _ = getShaderParameter(spec.meshNode, "atlasInvSizeAndOffsetUV")
		local numTilesU = 1 / x
		local numTilesV = 1 / y
		local subType = animal:getSubType()
		local tileUIndex = subType.texture.tileUIndex
		local tileVIndex = subType.texture.tileVIndex
		local tileU = tileUIndex / numTilesU
		local tileV = tileVIndex / numTilesV

		setShaderParameter(spec.meshNode, "atlasInvSizeAndOffsetUV", x, y, tileU, tileV, false)

		if spec.hairNode ~= nil then
			local x, y, _, _ = getShaderParameter(spec.hairNode, "atlasInvSizeAndOffsetUV")

			setShaderParameter(spec.hairNode, "atlasInvSizeAndOffsetUV", x, y, tileU, tileV, false)
		end
	end
end

function Rideable:setPlayerToEnter(player)
	local spec = self.spec_rideable
	spec.playerToEnter = player
	spec.checkPlayerToEnter = true

	self:raiseActive()
end

function Rideable:removeRideable()
	local spec = self.spec_rideable

	if not spec.isRideableRemoved then
		spec.isRideableRemoved = true
		local husbandry = spec.animal:getOwner()

		husbandry:removeRideable(spec.animal:getVisualId())
	end
end

function Rideable:getName(superFunc)
	local spec = self.spec_rideable

	return spec.animal:getName()
end

function Rideable:getFullName(superFunc)
	return self:getName()
end

function Rideable:getCanBeReset(superFunc)
	return false
end

function Rideable:updateDebugValues(values)
	local spec = self.spec_rideable

	for k, hoofInfo in pairs(spec.hooves) do
		table.insert(values, {
			name = "hoof sample " .. k,
			value = hoofInfo.sampleDebug
		})
	end
end

function Rideable:updateInputText()
	local spec = self.spec_rideable

	if spec.inputValues.currentGait == Rideable.GAITTYPES.BACKWARDS then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventActive(spec.brakeEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, false)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.STILL then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_walkBackwards"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.WALK then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_stop"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.TROT then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_canter"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_walk"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventActive(spec.jumpEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, false)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.CANTER then
		g_inputBinding:setActionEventText(spec.acceletateEventId, g_i18n:getText("action_gallop"))
		g_inputBinding:setActionEventActive(spec.acceletateEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, true)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_trot"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventText(spec.jumpEventId, g_i18n:getText("input_JUMP"))
		g_inputBinding:setActionEventActive(spec.jumpEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, true)
	elseif spec.inputValues.currentGait == Rideable.GAITTYPES.GALLOP then
		g_inputBinding:setActionEventActive(spec.acceletateEventId, false)
		g_inputBinding:setActionEventTextVisibility(spec.acceletateEventId, false)
		g_inputBinding:setActionEventText(spec.brakeEventId, g_i18n:getText("action_canter"))
		g_inputBinding:setActionEventActive(spec.brakeEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.brakeEventId, true)
		g_inputBinding:setActionEventText(spec.jumpEventId, g_i18n:getText("input_JUMP"))
		g_inputBinding:setActionEventActive(spec.jumpEventId, true)
		g_inputBinding:setActionEventTextVisibility(spec.jumpEventId, true)
	end
end
