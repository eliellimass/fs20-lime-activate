source("dataS/scripts/vehicles/specializations/events/SendLocomotiveToSplinePositionEvent.lua")

Locomotive = {
	STATE_NONE = 0,
	STATE_MANUAL_TRAVEL_ACTIVE = 1,
	STATE_MANUAL_TRAVEL_INACTIVE = 2,
	STATE_WAIT_FOR_AUTOMATIC_TRAVEL = 3,
	STATE_AUTOMATIC_TRAVEL_ACTIVE = 4,
	STATE_REQUESTED_POSITION = 5,
	STATE_REQUESTED_POSITION_BRAKING = 6,
	AUTOMATIC_DRIVE_DELAY = 1500000,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(SplineVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onAutomatedTrainTravelActive")
	end
}

function Locomotive.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDownhillForce", Locomotive.getDownhillForce)
	SpecializationUtil.registerFunction(vehicleType, "setRequestedSplinePosition", Locomotive.setRequestedSplinePosition)
	SpecializationUtil.registerFunction(vehicleType, "setLocomotiveState", Locomotive.setLocomotiveState)
end

function Locomotive.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMotorStarted", Locomotive.getIsMotorStarted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", Locomotive.updateVehiclePhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Locomotive.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "alignToSplineTime", Locomotive.alignToSplineTime)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setTrainSystem", Locomotive.setTrainSystem)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFullName", Locomotive.getFullName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreSurfaceSoundsActive", Locomotive.getAreSurfaceSoundsActive)
end

function Locomotive.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Locomotive)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Locomotive)
end

function Locomotive:onLoad(savegame)
	local spec = self.spec_locomotive
	spec.powerArm = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.locomotive.powerArm#node"), self.i3dMappings)
	spec.lastElectricitySplineTime = 0
	spec.lastSplineTime = 0
	spec.splineDiff = 0
	spec.electricitySpline = nil
	spec.lastVirtualRpm = self:getMotor():getMinRpm()
	spec.speed = 0
	spec.lastAcceleration = 0
	spec.nextMovingDirection = 0

	self:setLocomotiveState(Locomotive.STATE_NONE)

	spec.doStartCheck = true
end

function Locomotive:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_locomotive

	if spec.doStartCheck then
		if self:getIsReadyForAutomatedTrainTravel() then
			spec.automaticTravelStartTime = g_time

			self:setLocomotiveState(Locomotive.STATE_WAIT_FOR_AUTOMATIC_TRAVEL)
			self:raiseActive()

			if self.setRandomVehicleCharacter ~= nil then
				self:setRandomVehicleCharacter()
			end
		else
			self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
		end

		spec.doStartCheck = false
	end

	if self.isServer then
		if spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
			self:raiseActive()
			self:updateVehiclePhysics(1, 0, 0, dt)
			SpecializationUtil.raiseEvent(self, "onAutomatedTrainTravelActive", dt)
		elseif spec.state == Locomotive.STATE_REQUESTED_POSITION then
			if spec.requestedSplinePosition ~= nil then
				local currentPosition = self:getCurrentSplinePosition()
				local requestedPosition = spec.requestedSplinePosition

				if spec.requestedSplinePosition < currentPosition then
					requestedPosition = requestedPosition + 1
				end

				local brakeAcceleration = Locomotive.getBrakeAcceleration(self)
				local brakeDistance = math.abs(spec.speed^2 / (2 * brakeAcceleration))
				local brakePoint = requestedPosition - brakeDistance / self.trainSystem.splineLength

				if currentPosition > brakePoint then
					self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION_BRAKING)
				else
					self:updateVehiclePhysics(1, 0, 0, dt)
				end

				self:raiseActive()
			end
		elseif spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING then
			self:updateVehiclePhysics(-1, 0, 0, dt)
			self:raiseActive()

			if spec.speed == 0 then
				self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
			end
		elseif spec.state == Locomotive.STATE_WAIT_FOR_AUTOMATIC_TRAVEL then
			self:raiseActive()
		elseif spec.state == Locomotive.STATE_MANUAL_TRAVEL_INACTIVE then
			if self.movingDirection > 0 then
				self:updateVehiclePhysics(-1, 0, 0, dt)
			else
				self:updateVehiclePhysics(1, 0, 0, dt)
			end

			self:raiseActive()

			if spec.speed == 0 and self:getIsReadyForAutomatedTrainTravel() then
				self:setLocomotiveState(Locomotive.STATE_WAIT_FOR_AUTOMATIC_TRAVEL)
			end
		end
	end
end

function Locomotive:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_locomotive

		if spec.state == Locomotive.STATE_WAIT_FOR_AUTOMATIC_TRAVEL and spec.automaticTravelStartTime < g_time then
			self:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)
			self:startMotor()
		end
	end
end

function Locomotive:setTrainSystem(superFunc, trainSystem)
	superFunc(self, trainSystem)

	local spec = self.spec_locomotive

	if spec.powerArm ~= nil then
		local spline = trainSystem:getElectricitySpline()

		if spline ~= nil then
			local electricitySplineLength = trainSystem:getElectricitySplineLength()
			local splineLength = trainSystem:getSplineLength()
			spec.splineDiff = math.abs(electricitySplineLength - splineLength)
			spec.electricitySplineSearchTime = spec.splineDiff * 4 / electricitySplineLength
			spec.electricitySpline = spline
		end
	end
end

function Locomotive:getFullName(superFunc)
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	return storeItem.name
end

function Locomotive:getAreSurfaceSoundsActive(superFunc)
	return self:getLastSpeed() > 0.1
end

function Locomotive:setRequestedSplinePosition(splinePosition, noEventSend)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(SendLocomotiveToSplinePositionEvent:new(self, splinePosition))
	end

	local spec = self.spec_locomotive
	spec.requestedSplinePosition = splinePosition

	self:setLocomotiveState(Locomotive.STATE_REQUESTED_POSITION)
	self:startMotor()
end

function Locomotive:setLocomotiveState(state)
	self.state = state
end

function Locomotive:onLeaveVehicle()
	local spec = self.spec_locomotive

	if self:getIsReadyForAutomatedTrainTravel() then
		spec.automaticTravelStartTime = g_time + Locomotive.AUTOMATIC_DRIVE_DELAY
	end

	self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
	self:raiseActive()

	spec.requestedSplinePosition = nil
end

function Locomotive:onEnterVehicle()
	local spec = self.spec_locomotive
	spec.requestedSplinePosition = nil
	spec.automaticTravelStartTime = nil

	if not g_currentMission.missionInfo.automaticMotorStartEnabled and (spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or spec.state == Locomotive.STATE_REQUESTED_POSITION or spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING) then
		self:startMotor(true)
	end

	self:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_ACTIVE)
end

function Locomotive:getIsReadyForAutomatedTrainTravel(superFunc)
	if self:getIsControlled() then
		return false
	end

	return superFunc(self)
end

function Locomotive:getIsMotorStarted(superFunc)
	local spec = self.spec_locomotive

	return superFunc(self) or spec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE or spec.state == Locomotive.STATE_REQUESTED_POSITION or spec.state == Locomotive.STATE_REQUESTED_POSITION_BRAKING
end

function Locomotive:getDownhillForce()
	local mass = self:getTotalMass(false)
	local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
	local angleX = math.acos(dirY / MathUtil.vector3Length(dirX, dirY, dirZ)) - 0.5 * math.pi

	return mass * 9.81 * math.sin(-angleX)
end

function Locomotive:getBrakeAcceleration()
	local spec = self.spec_locomotive
	local downhillForce = spec:getDownhillForce()
	local totalMass = self:getTotalMass(false)
	local maxBrakeForce = totalMass * 9.81 * 0.18
	local brakeForce = maxBrakeForce

	if math.abs(spec.speed) < 0.3 or not self:getIsControlled() then
		brakeForce = maxBrakeForce
	else
		brakeForce = maxBrakeForce * 0.05
	end

	brakeForce = brakeForce * MathUtil.sign(spec.speed)

	return 1 / totalMass * (-brakeForce - downhillForce)
end

function Locomotive:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
	local spec = self.spec_locomotive
	local specDrivable = self.spec_drivable
	local acceleration = superFunc(self, axisForward, axisSide, doHandbrake, dt)
	local interpDt = g_physicsDt

	if g_server == nil then
		interpDt = g_physicsDtUnclamped
	end

	local totalMass = self:getTotalMass(false)
	local tractiveEffort = 300000
	local maxBrakeForce = totalMass * 9.81 * 0.18
	local brakeForce = maxBrakeForce
	local downhillForce = spec:getDownhillForce()
	tractiveEffort = math.min(tractiveEffort, maxBrakeForce)

	if self:getIsMotorStarted() and self:getMotorStartTime() <= g_currentMission.time then
		local reverserDirection = specDrivable == nil and 1 or specDrivable.reverserDirection

		if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
			if spec.speed < reverserDirection * self:getCruiseControlSpeed() / 3.6 then
				acceleration = 1
			elseif spec.speed > reverserDirection * self:getCruiseControlSpeed() / 3.6 then
				acceleration = -1
			end
		end
	else
		tractiveEffort = maxBrakeForce
	end

	if math.abs(acceleration) < 0.001 then
		local a = Locomotive.getBrakeAcceleration(self)

		if spec.speed > 0 then
			spec.speed = math.max(0, spec.speed + a * dt / 1000)
		elseif spec.speed < 0 then
			spec.speed = math.min(0, spec.speed + a * dt / 1000)
		elseif maxBrakeForce < math.abs(downhillForce) then
			spec.speed = spec.speed + a * dt / 1000
		end

		if spec.speed == 0 then
			spec.hasStopped = true
		else
			spec.hasStopped = false
		end
	else
		if math.abs(spec.speed) > 0.1 then
			spec.hasStopped = false
		elseif math.abs(spec.speed) == 0 then
			spec.hasStopped = true
		end

		if spec.hasStopped == nil or spec.hasStopped and math.abs(acceleration) > 0.01 then
			spec.nextMovingDirection = MathUtil.sign(acceleration)
		end

		local a = 0

		if spec.nextMovingDirection == nil or spec.nextMovingDirection * acceleration > 0 then
			tractiveEffort = acceleration * tractiveEffort
			brakeForce = 0
			a = 1 / totalMass * (tractiveEffort - brakeForce - downhillForce)
		else
			tractiveEffort = 0
			brakeForce = MathUtil.sign(spec.speed) * math.abs(acceleration) * maxBrakeForce

			if math.abs(spec.speed) < 0.1 then
				spec.speed = 0
			else
				a = 1 / totalMass * (tractiveEffort - brakeForce - downhillForce)
			end
		end

		spec.speed = spec.speed + a * interpDt / 1000
	end

	if spec.speed > 0 then
		spec.speed = math.min(spec.speed, self:getMotor():getMaximumForwardSpeed())
	elseif spec.speed < 0 then
		spec.speed = math.max(spec.speed, -self:getMotor():getMaximumBackwardSpeed())
	end

	if spec.speed ~= 0 then
		self.trainSystem:updateTrainPositionByLocomotiveSpeed(interpDt, spec.speed)
	end

	local motor = self:getMotor()
	local minRpm = motor:getMinRpm()
	local maxRpm = motor:getMaxRpm()

	if spec.lastAcceleration * spec.nextMovingDirection > 0 then
		spec.lastVirtualRpm = math.min(maxRpm, spec.lastVirtualRpm + 0.0005 * dt * (maxRpm - minRpm))
	else
		spec.lastVirtualRpm = math.max(minRpm, spec.lastVirtualRpm - 0.001 * dt * (maxRpm - minRpm))
	end

	motor:setEqualizedMotorRpm(spec.lastVirtualRpm)

	spec.lastAcceleration = acceleration
end

function Locomotive:alignToSplineTime(superFunc, spline, yOffset, tFront)
	local retValue = superFunc(self, spline, yOffset, tFront)

	if retValue ~= nil then
		local spec = self.spec_locomotive

		if spec.powerArm ~= nil and spec.electricitySpline ~= nil then
			retValue = SplineUtil.getValidSplineTime(retValue)
			local dif = retValue - spec.lastSplineTime
			local electricityTime = spec.lastElectricitySplineTime + dif
			local x, y, z = getWorldTranslation(spec.powerArm)
			local x, y, z, newTime = getLocalClosestSplinePosition(spec.electricitySpline, electricityTime, spec.electricitySplineSearchTime, x, y, z, 0.01)
			_, y, _ = worldToLocal(getParent(spec.powerArm), x, y, z)
			local x, _, z = getTranslation(spec.powerArm)

			setTranslation(spec.powerArm, x, y, z)

			if spec.powerArm ~= nil then
				self:setMovingToolDirty(spec.powerArm)
			end

			spec.lastElectricitySplineTime = newTime
			spec.lastSplineTime = retValue
		end
	end

	return retValue
end
