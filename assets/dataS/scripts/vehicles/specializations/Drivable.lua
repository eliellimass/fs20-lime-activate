source("dataS/scripts/vehicles/specializations/events/SetCruiseControlStateEvent.lua")
source("dataS/scripts/vehicles/specializations/events/SetCruiseControlSpeedEvent.lua")

Drivable = {
	CRUISECONTROL_STATE_OFF = 0,
	CRUISECONTROL_STATE_ACTIVE = 1,
	CRUISECONTROL_STATE_FULL = 2,
	CRUISECONTROL_FULL_TOGGLE_TIME = 500,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations)
	end
}

function Drivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringWheel", Drivable.updateSteeringWheel)
	SpecializationUtil.registerFunction(vehicleType, "setCruiseControlState", Drivable.setCruiseControlState)
	SpecializationUtil.registerFunction(vehicleType, "setCruiseControlMaxSpeed", Drivable.setCruiseControlMaxSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlState", Drivable.getCruiseControlState)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlSpeed", Drivable.getCruiseControlSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlMaxSpeed", Drivable.getCruiseControlMaxSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getAxisForward", Drivable.getAxisForward)
	SpecializationUtil.registerFunction(vehicleType, "getAccelerationAxis", Drivable.getAccelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getDecelerationAxis", Drivable.getDecelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getCruiseControlAxis", Drivable.getCruiseControlAxis)
	SpecializationUtil.registerFunction(vehicleType, "getAcDecelerationAxis", Drivable.getAcDecelerationAxis)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardSteeringAxis", Drivable.getDashboardSteeringAxis)
	SpecializationUtil.registerFunction(vehicleType, "setReverserDirection", Drivable.setReverserDirection)
	SpecializationUtil.registerFunction(vehicleType, "getReverserDirection", Drivable.getReverserDirection)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringDirection", Drivable.getSteeringDirection)
	SpecializationUtil.registerFunction(vehicleType, "getIsDrivingForward", Drivable.getIsDrivingForward)
	SpecializationUtil.registerFunction(vehicleType, "getIsDrivingBackward", Drivable.getIsDrivingBackward)
	SpecializationUtil.registerFunction(vehicleType, "getDrivingDirection", Drivable.getDrivingDirection)
	SpecializationUtil.registerFunction(vehicleType, "getIsVehicleControlledByPlayer", Drivable.getIsVehicleControlledByPlayer)
	SpecializationUtil.registerFunction(vehicleType, "updateVehiclePhysics", Drivable.updateVehiclePhysics)
	SpecializationUtil.registerFunction(vehicleType, "setAccelerationPedalInput", Drivable.setAccelerationPedalInput)
	SpecializationUtil.registerFunction(vehicleType, "setBrakePedalInput", Drivable.setBrakePedalInput)
	SpecializationUtil.registerFunction(vehicleType, "setTargetSpeedAndDirection", Drivable.setTargetSpeedAndDirection)
	SpecializationUtil.registerFunction(vehicleType, "setSteeringInput", Drivable.setSteeringInput)
	SpecializationUtil.registerFunction(vehicleType, "brakeToStop", Drivable.brakeToStop)
end

function Drivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Drivable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Drivable)
end

function Drivable:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.steering#index", "vehicle.drivable.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.steering#node", "vehicle.drivable.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cruiseControl", "vehicle.drivable.cruiseControl")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.cruiseControl", "vehicle.drivable.dashboards.dashboard with valueType 'cruiseControl'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.showChangeToolSelectionHelp")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.maxRotatedTimeSpeed#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.speedRotScale#scale", "vehicle.drivable.speedRotScale#scale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.speedRotScale#offset", "vehicle.drivable.speedRotScale#offset")

	local spec = self.spec_drivable
	spec.showToolSelectionHud = true
	spec.doHandbrake = false
	spec.doHandbrakeSend = false
	spec.reverserDirection = 1
	spec.lastInputValues = {
		axisAccelerate = 0,
		axisBrake = 0,
		axisSteer = 0,
		axisSteerIsAnalog = false,
		axisSteerDeviceCategory = InputDevice.CATEGORY.UNKNOWN,
		cruiseControlValue = 0,
		cruiseControlState = 0
	}
	spec.axisForward = 0
	spec.axisForwardSend = 0
	spec.axisSide = 0
	spec.axisSideSend = 0
	spec.axisSideLast = 0
	spec.speedRotScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.drivable.speedRotScale#scale"), 80)
	spec.speedRotScaleOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.drivable.speedRotScale#offset"), 0.7)
	local motor = self:getMotor()
	spec.cruiseControl = {
		maxSpeed = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.drivable.cruiseControl#maxSpeed"), math.ceil(motor:getMaximumForwardSpeed() * 3.6))
	}
	spec.cruiseControl.minSpeed = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.drivable.cruiseControl#minSpeed"), math.min(1, spec.cruiseControl.maxSpeed))
	spec.cruiseControl.speed = spec.cruiseControl.maxSpeed
	spec.cruiseControl.isActive = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.drivable.cruiseControl#enabled"), true)
	spec.cruiseControl.state = Drivable.CRUISECONTROL_STATE_OFF
	spec.cruiseControl.topSpeedTime = 2000
	spec.cruiseControl.changeDelay = 250
	spec.cruiseControl.changeCurrentDelay = 0
	spec.cruiseControl.changeMultiplier = 1
	spec.cruiseControl.speedSent = spec.cruiseControl.speed
	local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.drivable.steeringWheel#node"), self.i3dMappings)

	if node ~= nil then
		spec.steeringWheel = {
			node = node
		}
		local _, ry, _ = getRotation(spec.steeringWheel.node)
		spec.steeringWheel.lastRotation = ry
		spec.steeringWheel.indoorRotation = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.drivable.steeringWheel#indoorRotation"), 0))
		spec.steeringWheel.outdoorRotation = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.drivable.steeringWheel#outdoorRotation"), 0))
	end

	if self.loadDashboardsFromXML ~= nil then
		local dashKey = "vehicle.drivable.dashboards"

		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "speed",
			valueTypeToLoad = "cruiseControl",
			valueObject = spec.cruiseControl
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "getIsDrivingForward",
			valueTypeToLoad = "directionForward",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "getIsDrivingBackward",
			valueTypeToLoad = "directionBackward",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			maxFunc = 1,
			valueFunc = "getDrivingDirection",
			minFunc = -1,
			valueTypeToLoad = "movingDirection",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "state",
			valueTypeToLoad = "cruiseControlActive",
			valueObject = spec.cruiseControl,
			valueCompare = Drivable.CRUISECONTROL_STATE_ACTIVE
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "getAccelerationAxis",
			valueTypeToLoad = "accelerationAxis",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "getDecelerationAxis",
			valueTypeToLoad = "decelerationAxis",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			valueFunc = "getAcDecelerationAxis",
			valueTypeToLoad = "ac_decelerationAxis",
			valueObject = self
		})
		self:loadDashboardsFromXML(self.xmlFile, dashKey, {
			maxFunc = 1,
			valueFunc = "getDashboardSteeringAxis",
			minFunc = -1,
			valueTypeToLoad = "steeringAngle",
			valueObject = self
		})
	end

	if self.isClient then
		spec.samples = {
			waterSplash = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.drivable.sounds", "waterSplash", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}

		if self.isClient and g_isDevelopmentVersion and spec.samples.waterSplash == nil then
			g_logManager:xmlDevWarning(self.configFileName, "Missing drivable waterSplash sound")
		end
	end

	if savegame ~= nil then
		local maxSpeed = getXMLInt(savegame.xmlFile, savegame.key .. ".drivable#cruiseControl")

		self:setCruiseControlMaxSpeed(maxSpeed)
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Drivable:onDelete()
	if self.isClient then
		local spec = self.spec_drivable

		for _, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end
	end
end

function Drivable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_drivable

	setXMLFloat(xmlFile, key .. "#cruiseControl", spec.cruiseControl.speed)
end

function Drivable:onReadStream(streamId, connection)
	local spec = self.spec_drivable

	if spec.cruiseControl.isActive then
		self:setCruiseControlState(streamReadUIntN(streamId, 2), true)

		local speed = streamReadUInt8(streamId)

		self:setCruiseControlMaxSpeed(speed)

		spec.cruiseControl.speedSent = speed
	end
end

function Drivable:onWriteStream(streamId, connection)
	local spec = self.spec_drivable

	if spec.cruiseControl.isActive then
		streamWriteUIntN(streamId, spec.cruiseControl.state, 2)
		streamWriteUInt8(streamId, spec.cruiseControl.speed)
	end
end

function Drivable:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_drivable

	if streamReadBool(streamId) then
		spec.axisForward = streamReadUIntN(streamId, 10) / 1023 * 2 - 1

		if math.abs(spec.axisForward) < 0.00099 then
			spec.axisForward = 0
		end

		spec.axisSide = streamReadUIntN(streamId, 10) / 1023 * 2 - 1

		if math.abs(spec.axisSide) < 0.00099 then
			spec.axisSide = 0
		end

		spec.doHandbrake = streamReadBool(streamId)
	end
end

function Drivable:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_drivable

	if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
		local axisForward = (spec.axisForward + 1) / 2 * 1023

		streamWriteUIntN(streamId, axisForward, 10)

		local axisSide = (spec.axisSide + 1) / 2 * 1023

		streamWriteUIntN(streamId, axisSide, 10)
		streamWriteBool(streamId, spec.doHandbrake)
	end
end

function Drivable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_drivable

	if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() then
		if self:getIsActiveForInput(true, true) then
			if self:getIsVehicleControlledByPlayer() then
				spec.doHandbrake = false
				local axisForward = MathUtil.clamp(spec.lastInputValues.axisAccelerate - spec.lastInputValues.axisBrake, -1, 1)
				spec.axisForward = axisForward

				if spec.brakeToStop then
					spec.lastInputValues.targetSpeed = 0.51
					spec.lastInputValues.targetDirection = 1

					if self:getLastSpeed() < 1 then
						spec.brakeToStop = false
						spec.lastInputValues.targetSpeed = nil
						spec.lastInputValues.targetDirection = nil
					end
				end

				if spec.lastInputValues.targetSpeed ~= nil then
					local currentSpeed = self:getLastSpeed() * self.movingDirection
					local targetSpeed = spec.lastInputValues.targetSpeed * spec.lastInputValues.targetDirection
					local speedDifference = targetSpeed - currentSpeed

					if math.abs(speedDifference) > 0.1 and math.abs(targetSpeed) > 0.5 then
						spec.axisForward = MathUtil.clamp(speedDifference * 0.1, -1, 1)
					end
				end

				local speedFactor = 1
				local sensitivitySetting = g_gameSettings:getValue(GameSettings.SETTING.STEERING_SENSITIVITY)
				local axisSteer = spec.lastInputValues.axisSteer

				if spec.lastInputValues.axisSteerIsAnalog then
					local isArticulatedSteering = self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil
					speedFactor = isArticulatedSteering and 1.5 or 2.5

					if GS_IS_MOBILE_VERSION then
						speedFactor = speedFactor * 1.5
						axisSteer = math.pow(math.abs(axisSteer), 1 / sensitivitySetting) * (axisSteer >= 0 and 1 or -1)
					elseif spec.lastInputValues.axisSteerDeviceCategory == InputDevice.CATEGORY.GAMEPAD then
						speedFactor = speedFactor * sensitivitySetting
					end
				elseif spec.lastInputValues.axisSteer == 0 then
					local rotateBackSpeedSetting = g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10

					if rotateBackSpeedSetting < 1 and self.speedDependentRotateBack then
						local speed = self:getLastSpeed() / 36
						local setting = rotateBackSpeedSetting / 0.5
						speedFactor = speedFactor * math.min(speed * setting, 1)
					end

					speedFactor = speedFactor * (self.autoRotateBackSpeed or 1) / 1.5
				else
					speedFactor = math.min(1 / (self.lastSpeed * spec.speedRotScale + spec.speedRotScaleOffset), 1)
					speedFactor = speedFactor * sensitivitySetting
				end

				local steeringDuration = (self.wheelSteeringDuration or 1) * 1000
				local rotDelta = dt / steeringDuration * speedFactor

				if spec.axisSide < axisSteer then
					spec.axisSide = math.min(axisSteer, spec.axisSide + rotDelta)
				elseif axisSteer < spec.axisSide then
					spec.axisSide = math.max(axisSteer, spec.axisSide - rotDelta)
				end
			else
				spec.axisForward = 0

				if self.rotatedTime < 0 then
					spec.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
				else
					spec.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
				end
			end
		else
			spec.doHandbrake = true
			spec.axisForward = 0
		end

		spec.lastInputValues.axisAccelerate = 0
		spec.lastInputValues.axisBrake = 0
		spec.lastInputValues.axisSteer = 0

		if spec.axisForward ~= spec.axisForwardSend or spec.axisSide ~= spec.axisSideSend or spec.doHandbrake ~= spec.doHandbrakeSend then
			spec.axisForwardSend = spec.axisForward
			spec.axisSideSend = spec.axisSide
			spec.doHandbrakeSend = spec.doHandbrake

			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end

	if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() then
		local inputValue = spec.lastInputValues.cruiseControlState
		spec.lastInputValues.cruiseControlState = 0

		if inputValue == 1 then
			if spec.cruiseControl.topSpeedTime == Drivable.CRUISECONTROL_FULL_TOGGLE_TIME then
				if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
				else
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
				end
			end

			if spec.cruiseControl.topSpeedTime > 0 then
				spec.cruiseControl.topSpeedTime = spec.cruiseControl.topSpeedTime - dt

				if spec.cruiseControl.topSpeedTime < 0 then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_FULL)
				end
			end
		else
			spec.cruiseControl.topSpeedTime = Drivable.CRUISECONTROL_FULL_TOGGLE_TIME
		end

		local lastCruiseControlValue = spec.lastInputValues.cruiseControlValue
		spec.lastInputValues.cruiseControlValue = 0

		if lastCruiseControlValue ~= 0 then
			spec.cruiseControl.changeCurrentDelay = spec.cruiseControl.changeCurrentDelay - dt * spec.cruiseControl.changeMultiplier
			spec.cruiseControl.changeMultiplier = math.min(spec.cruiseControl.changeMultiplier + dt * 0.003, 10)

			if spec.cruiseControl.changeCurrentDelay < 0 then
				spec.cruiseControl.changeCurrentDelay = spec.cruiseControl.changeDelay
				local dir = MathUtil.sign(lastCruiseControlValue)
				local speed = spec.cruiseControl.speed + dir

				self:setCruiseControlMaxSpeed(speed)

				if spec.cruiseControl.speed ~= spec.cruiseControl.speedSent then
					if g_server ~= nil then
						g_server:broadcastEvent(SetCruiseControlSpeedEvent:new(self, spec.cruiseControl.speed), nil, , self)
					else
						g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, spec.cruiseControl.speed))
					end

					spec.cruiseControl.speedSent = spec.cruiseControl.speed
				end
			end
		else
			spec.cruiseControl.changeCurrentDelay = 0
			spec.cruiseControl.changeMultiplier = 1
		end
	end

	local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

	if self:getIsVehicleControlledByPlayer() and self.isServer and isControlled then
		local speed, _ = self:getSpeedLimit(true)

		if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
			speed = math.min(speed, spec.cruiseControl.speed)
		end

		self:getMotor():setSpeedLimit(speed)
		self:updateVehiclePhysics(spec.axisForward, spec.axisSide, spec.doHandbrake, dt)
	end

	if self.isClient and isControlled then
		self:updateSteeringWheel(spec.steeringWheel, dt, 1)
	end

	if self:getIsActiveForInput(true) then
		local inputHelpMode = g_inputBinding:getInputHelpMode()

		if (inputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH) and g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
			local dx, dy, dz = getGravityDirection()
			local steeringValue = MathUtil.getSteeringAngleFromDeviceGravity(dx, dy, dz)

			self:setSteeringInput(steeringValue, true, InputDevice.CATEGORY.WHEEL)
		end
	end
end

function Drivable:setCruiseControlState(state, noEventSend)
	local spec = self.spec_drivable

	if spec.cruiseControl.state ~= state then
		spec.cruiseControl.state = state

		if noEventSend == nil or not noEventSend then
			if not self.isServer then
				g_client:getServerConnection():sendEvent(SetCruiseControlStateEvent:new(self, state))
			else
				local owner = self:getOwner()

				if owner ~= nil then
					owner:sendEvent(SetCruiseControlStateEvent:new(self, state))
				end
			end
		end

		if spec.toggleCruiseControlEvent ~= nil then
			local text = nil

			if state ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
				text = g_i18n:getText("action_activateCruiseControl")
			else
				text = g_i18n:getText("action_deactivateCruiseControl")
			end

			g_inputBinding:setActionEventText(spec.toggleCruiseControlEvent, text)
		end
	end
end

function Drivable:setCruiseControlMaxSpeed(speed)
	local spec = self.spec_drivable

	if speed ~= nil then
		speed = MathUtil.clamp(speed, spec.cruiseControl.minSpeed, spec.cruiseControl.maxSpeed)

		if spec.cruiseControl.speed ~= speed then
			spec.cruiseControl.speed = speed

			if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
				spec.cruiseControl.state = Drivable.CRUISECONTROL_STATE_ACTIVE
			end
		end

		if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
			if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
				local speed, _ = self:getSpeedLimit(true)
				speed = math.min(speed, spec.cruiseControl.speed)

				self:getMotor():setSpeedLimit(speed)
			else
				self:getMotor():setSpeedLimit(math.huge)
			end
		end
	end
end

function Drivable:updateSteeringWheel(steeringWheel, dt, direction)
	if steeringWheel ~= nil then
		local maxRotation = steeringWheel.outdoorRotation

		if g_currentMission.controlledVehicle == self and self.getActiveCamera ~= nil then
			local activeCamera = self:getActiveCamera()

			if activeCamera ~= nil and activeCamera.isInside then
				maxRotation = steeringWheel.indoorRotation
			end
		end

		local rotation = self.rotatedTime * maxRotation

		if steeringWheel.lastRotation ~= rotation then
			steeringWheel.lastRotation = rotation

			setRotation(steeringWheel.node, 0, rotation * direction, 0)

			if self.getVehicleCharacter ~= nil then
				local vehicleCharacter = self:getVehicleCharacter()

				if vehicleCharacter ~= nil then
					vehicleCharacter:setDirty(true)
				end
			end
		end
	end
end

function Drivable:getCruiseControlState()
	return self.spec_drivable.cruiseControl.state
end

function Drivable:getCruiseControlSpeed()
	local spec = self.spec_drivable

	if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then
		return spec.cruiseControl.maxSpeed
	end

	return spec.cruiseControl.speed
end

function Drivable:getCruiseControlMaxSpeed()
	return self.spec_drivable.cruiseControl.maxSpeed
end

function Drivable:getAxisForward()
	return self.spec_drivable.axisForward
end

function Drivable:getAccelerationAxis()
	if self.lastSpeedReal > 0.0001 then
		return math.max(self.spec_drivable.axisForward * self.movingDirection * self:getReverserDirection(), 0)
	end

	return 0
end

g_soundManager:registerModifierType("ACCELERATE", Drivable.getAccelerationAxis)

function Drivable:getDecelerationAxis()
	if self.lastSpeedReal > 0.0001 and (self.movingDirection == MathUtil.sign(self.spec_drivable.axisForward) or self.lastSpeedReal > 0.002) then
		return math.abs(math.min(self.spec_drivable.axisForward * self.movingDirection * self:getReverserDirection(), 0))
	end

	return 0
end

g_soundManager:registerModifierType("DECELERATE", Drivable.getDecelerationAxis)

function Drivable:getCruiseControlAxis()
	return self.spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF and 1 or 0
end

g_soundManager:registerModifierType("CRUISECONTROL", Drivable.getCruiseControlAxis)

function Drivable:getAcDecelerationAxis()
	return self.spec_drivable.axisForward * self:getReverserDirection()
end

function Drivable:getDashboardSteeringAxis()
	return self.rotatedTime * self:getReverserDirection()
end

function Drivable:setReverserDirection(reverserDirection)
	self.spec_drivable.reverserDirection = reverserDirection
end

function Drivable:getReverserDirection()
	return self.spec_drivable.reverserDirection
end

function Drivable:getSteeringDirection()
	return 1
end

function Drivable:getIsDrivingForward()
	return self:getDrivingDirection() >= 0
end

function Drivable:getIsDrivingBackward()
	return self:getDrivingDirection() < 0
end

function Drivable:getDrivingDirection()
	if self:getLastSpeed() < 0.2 then
		return 0
	end

	return self.movingDirection
end

function Drivable:getIsVehicleControlledByPlayer()
	return true
end

function Drivable:onCameraChanged(camera, camIndex)
end

function Drivable:stopMotor(noEventSend)
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
end

function Drivable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_drivable
		spec.toggleCruiseControlEvent = nil

		self:clearActionEventsTable(spec.actionEvents)

		local entered = true

		if self.getIsEntered ~= nil then
			entered = self:getIsEntered()
		end

		local _, actionEventId = nil

		if self:getIsActiveForInput(true, true) and entered then
			if not self:getIsAIActive() then
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_ACCELERATE_VEHICLE, self, Drivable.actionEventAccelerate, false, false, true, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_BRAKE_VEHICLE, self, Drivable.actionEventBrake, false, false, true, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_MOVE_SIDE_VEHICLE, self, Drivable.actionEventSteer, false, false, true, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
				g_inputBinding:setActionEventTextVisibility(actionEventId, false)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlState, false, true, true, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)

				spec.toggleCruiseControlEvent = actionEventId
			end

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_CRUISE_CONTROL, self, Drivable.actionEventCruiseControlValue, false, true, true, true, nil)

			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_changeCruiseControlLevel"))
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
		end
	end
end

function Drivable:onLeaveVehicle()
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)

	if self.brake ~= nil then
		self:brake(1)
	end
end

function Drivable:onSetBroken()
	if self.isClient then
		local spec = self.spec_drivable

		g_soundManager:playSample(spec.samples.waterSplash)
	end
end

function Drivable:updateVehiclePhysics(axisForward, axisSide, doHandbrake, dt)
	local spec = self.spec_drivable
	axisSide = self:getSteeringDirection() * axisSide
	local acceleration = 0

	if self:getIsMotorStarted() and self:getMotorStartTime() <= g_currentMission.time then
		acceleration = axisForward

		if math.abs(acceleration) > 0 then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
		end

		if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
			acceleration = 1
		end
	end

	if not self:getCanMotorRun() then
		acceleration = 0

		if self:getIsMotorStarted() then
			self:stopMotor()
		end
	end

	if self.getIsControlled ~= nil and self:getIsControlled() then
		local targetRotatedTime = 0

		if self.maxRotTime ~= nil and self.minRotTime ~= nil then
			if axisSide < 0 then
				targetRotatedTime = math.min(-self.maxRotTime * axisSide, self.maxRotTime)
			else
				targetRotatedTime = math.max(self.minRotTime * axisSide, self.minRotTime)
			end
		end

		self.rotatedTime = targetRotatedTime
	end

	if self.firstTimeRun and self.spec_wheels ~= nil then
		WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acceleration, doHandbrake, g_currentMission.missionInfo.stopAndGoBraking)
	end

	return acceleration
end

function Drivable:setAccelerationPedalInput(inputValue)
	local spec = self.spec_drivable
	spec.lastInputValues.axisAccelerate = MathUtil.clamp(inputValue, 0, 1)

	if spec.lastInputValues.targetSpeed ~= nil then
		spec.lastInputValues.targetSpeed = nil
		spec.lastInputValues.targetDirection = nil
	end
end

function Drivable:setBrakePedalInput(inputValue)
	local spec = self.spec_drivable
	spec.lastInputValues.axisBrake = MathUtil.clamp(inputValue, 0, 1)

	if spec.lastInputValues.targetSpeed ~= nil then
		spec.lastInputValues.targetSpeed = nil
		spec.lastInputValues.targetDirection = nil
	end
end

function Drivable:setTargetSpeedAndDirection(speed, direction)
	local spec = self.spec_drivable

	if direction > 0 then
		speed = speed * self:getMotor():getMaximumForwardSpeed() * 3.6
	elseif direction < 0 then
		speed = speed * self:getMotor():getMaximumBackwardSpeed() * 3.6
	end

	spec.lastInputValues.targetSpeed = speed
	spec.lastInputValues.targetDirection = direction
end

function Drivable:setSteeringInput(inputValue, isAnalog, deviceCategory)
	local spec = self.spec_drivable
	spec.lastInputValues.axisSteer = inputValue

	if inputValue ~= 0 then
		spec.lastInputValues.axisSteerIsAnalog = isAnalog
		spec.lastInputValues.axisSteerDeviceCategory = deviceCategory
	end
end

function Drivable:brakeToStop()
	local spec = self.spec_drivable
	spec.brakeToStop = true
end

function Drivable:actionEventAccelerate(actionName, inputValue, callbackState, isAnalog)
	if inputValue ~= 0 then
		self:setAccelerationPedalInput(inputValue)
	end
end

function Drivable:actionEventBrake(actionName, inputValue, callbackState, isAnalog)
	if inputValue ~= 0 then
		self:setBrakePedalInput(inputValue)
	end
end

function Drivable:actionEventSteer(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory)
	if inputValue ~= 0 then
		self:setSteeringInput(inputValue, isAnalog, deviceCategory)
	end
end

function Drivable:actionEventCruiseControlState(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_drivable
	spec.lastInputValues.cruiseControlState = 1
end

function Drivable:actionEventCruiseControlValue(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_drivable
	spec.lastInputValues.cruiseControlValue = inputValue
end
