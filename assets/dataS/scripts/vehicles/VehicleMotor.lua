g_manualGearShift = false
VehicleMotor = {}
local VehicleMotor_mt = Class(VehicleMotor)
VehicleMotor.DAMAGE_TORQUE_REDUCTION = 0.3

function VehicleMotor:new(vehicle, minRpm, maxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGearRatios, backwardGearRatios, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
	local self = {}

	setmetatable(self, VehicleMotor_mt)

	self.vehicle = vehicle
	self.minRpm = minRpm
	self.maxRpm = maxRpm
	self.minSpeed = minSpeed
	self.maxForwardSpeed = maxForwardSpeed
	self.maxBackwardSpeed = maxBackwardSpeed
	self.maxClutchTorque = 5
	self.torqueCurve = torqueCurve
	self.brakeForce = brakeForce
	self.gear = 0
	self.minGearRatio = 0
	self.maxGearRatio = 0
	self.forwardGearRatios = forwardGearRatios
	self.backwardGearRatios = backwardGearRatios
	self.minForwardGearRatio = minForwardGearRatio
	self.maxForwardGearRatio = maxForwardGearRatio
	self.minBackwardGearRatio = minBackwardGearRatio
	self.maxBackwardGearRatio = maxBackwardGearRatio
	self.manualTargetGear = nil
	self.targetGear = 0
	self.previousGear = 0
	self.gearChangeTimer = -1
	self.gearChangeTime = 250
	self.autoGearChangeTimer = -1
	self.autoGearChangeTime = 1000
	self.lastRealMotorRpm = 0
	self.lastMotorRpm = 0
	self.rpmLimit = math.huge
	self.speedLimit = math.huge
	self.speedLimitAcc = math.huge
	self.accelerationLimit = 2
	self.motorRotationAccelerationLimit = (maxRpm - minRpm) * math.pi / 30 / 2
	self.equalizedMotorRpm = 0
	self.requiredMotorPower = 0

	if self.maxForwardSpeed == nil then
		self.maxForwardSpeed = self:calculatePhysicalMaximumForwardSpeed()
	end

	if self.maxBackwardSpeed == nil then
		self.maxBackwardSpeed = self:calculatePhysicalMaximumBackwardSpeed()
	end

	self.peakMotorTorque = self.torqueCurve:getMaximum()
	self.peakMotorPower = 0
	self.peakMotorPowerRotSpeed = 0
	local numKeyFrames = #self.torqueCurve.keyframes

	if numKeyFrames >= 2 then
		for i = 2, numKeyFrames do
			local v0 = self.torqueCurve.keyframes[i - 1]
			local v1 = self.torqueCurve.keyframes[i]
			local torque0 = self.torqueCurve:getFromKeyframes(v0, v0, i - 1, i - 1, 0)
			local torque1 = self.torqueCurve:getFromKeyframes(v1, v1, i, i, 0)
			local rpm, torque = nil

			if math.abs(torque0 - torque1) > 0.0001 then
				rpm = (v1.time * torque0 - v0.time * torque1) / (2 * (torque0 - torque1))
				rpm = math.min(math.max(rpm, v0.time), v1.time)
				torque = self.torqueCurve:getFromKeyframes(v0, v1, i - 1, i, (v1.time - rpm) / (v1.time - v0.time))
			else
				rpm = v0.time
				torque = torque0
			end

			local power = torque * rpm

			if self.peakMotorPower < power then
				self.peakMotorPower = power
				self.peakMotorPowerRotSpeed = rpm
			end
		end

		self.peakMotorPower = self.peakMotorPower * math.pi / 30
		self.peakMotorPowerRotSpeed = self.peakMotorPowerRotSpeed * math.pi / 30
	else
		local v = self.torqueCurve.keyframes[1]
		local rotSpeed = v.time * math.pi / 30
		local torque = self.torqueCurve:getFromKeyframes(v, v, i, i, 0)
		self.peakMotorPower = rotSpeed * torque
		self.peakMotorPowerRotSpeed = rotSpeed
	end

	self.ptoMotorRpmRatio = ptoMotorRpmRatio
	self.rotInertia = self.peakMotorTorque / 600
	self.dampingRateFullThrottle = 0.00015
	self.dampingRateZeroThrottleClutchEngaged = 0.001
	self.dampingRateZeroThrottleClutchDisengaged = 0.001
	self.gearRatio = 0
	self.motorRotSpeed = 0
	self.motorRotAcceleration = 0
	self.motorRotAccelerationSmoothed = 0
	self.motorAvailableTorque = 0
	self.motorAppliedTorque = 0
	self.motorExternalTorque = 0
	self.differentialRotSpeed = 0
	self.differentialRotAcceleration = 0
	self.differentialRotAccelerationSmoothed = 0

	return self
end

function VehicleMotor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
	self.lowBrakeForceScale = lowBrakeForceScale
	self.lowBrakeForceSpeedLimit = lowBrakeForceSpeedLimit
end

function VehicleMotor:getMaxClutchTorque()
	return self.maxClutchTorque
end

function VehicleMotor:getRotInertia()
	return self.rotInertia
end

function VehicleMotor:setRotInertia(rotInertia)
	self.rotInertia = rotInertia
end

function VehicleMotor:getDampingRateFullThrottle()
	return self.dampingRateFullThrottle
end

function VehicleMotor:getDampingRateZeroThrottleClutchEngaged()
	return self.dampingRateZeroThrottleClutchEngaged
end

function VehicleMotor:getDampingRateZeroThrottleClutchDisengaged()
	return self.dampingRateZeroThrottleClutchDisengaged
end

function VehicleMotor:setDampingRateFullThrottle(dampingRate)
	self.dampingRateFullThrottle = dampingRate
end

function VehicleMotor:setDampingRateZeroThrottleClutchEngaged(dampingRate)
	self.dampingRateZeroThrottleClutchEngaged = dampingRate
end

function VehicleMotor:setDampingRateZeroThrottleClutchDisengaged(dampingRate)
	self.dampingRateZeroThrottleClutchDisengaged = dampingRate
end

function VehicleMotor:setGearChangeTime(gearChangeTime)
	self.gearChangeTime = gearChangeTime
	self.gearChangeTimer = math.min(self.gearChangeTimer, gearChangeTime)
end

function VehicleMotor:setAutoGearChangeTime(autoGearChangeTime)
	self.autoGearChangeTime = autoGearChangeTime
	self.autoGearChangeTimer = math.min(self.autoGearChangeTimer, autoGearChangeTime)
end

function VehicleMotor:getPeakTorque()
	return self.peakMotorTorque
end

function VehicleMotor:getBrakeForce()
	return self.brakeForce
end

function VehicleMotor:getMinRpm()
	return self.minRpm
end

function VehicleMotor:getMaxRpm()
	return self.maxRpm
end

function VehicleMotor:getRequiredMotorRpmRange()
	local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio, self.maxRpm)

	if motorPtoRpm ~= 0 then
		return motorPtoRpm, motorPtoRpm
	end

	return self.minRpm, self.maxRpm
end

function VehicleMotor:getLastMotorRpm()
	return self.lastMotorRpm
end

function VehicleMotor:getLastRealMotorRpm()
	return self.lastRealMotorRpm
end

function VehicleMotor:setLastRpm(lastRpm)
	self.lastRealMotorRpm = lastRpm
	self.lastMotorRpm = self.lastMotorRpm * 0.95 + self.lastRealMotorRpm * 0.05
end

function VehicleMotor:getMotorAppliedTorque()
	return self.motorAppliedTorque
end

function VehicleMotor:getMotorExternalTorque()
	return self.motorExternalTorque
end

function VehicleMotor:getMotorAvailableTorque()
	return self.motorAvailableTorque
end

function VehicleMotor:getEqualizedMotorRpm()
	return self.equalizedMotorRpm
end

function VehicleMotor:setEqualizedMotorRpm(rpm)
	self.equalizedMotorRpm = rpm

	self:setLastRpm(rpm)
end

function VehicleMotor:getPtoMotorRpmRatio()
	return self.ptoMotorRpmRatio
end

function VehicleMotor:getNonClampedMotorRpm()
	return self.motorRotSpeed * 30 / math.pi
end

function VehicleMotor:getMotorRotSpeed()
	return self.motorRotSpeed
end

function VehicleMotor:getClutchRotSpeed()
	return self.differentialRotSpeed * self.gearRatio
end

function VehicleMotor:getTorqueCurve()
	return self.torqueCurve
end

function VehicleMotor:getTorque(acceleration)
	local torque = self:getTorqueCurveValue(MathUtil.clamp(self.motorRotSpeed * 30 / math.pi, self.minRpm, self.maxRpm))
	torque = torque * math.abs(acceleration)

	return torque
end

function VehicleMotor:getTorqueCurveValue(rpm)
	local damage = 1 - self.vehicle:getVehicleDamage() * VehicleMotor.DAMAGE_TORQUE_REDUCTION

	return self:getTorqueCurve():get(rpm) * damage
end

function VehicleMotor:getTorqueAndSpeedValues()
	local rotationSpeeds = {}
	local torques = {}

	for _, v in ipairs(self:getTorqueCurve().keyframes) do
		table.insert(rotationSpeeds, v.time * math.pi / 30)
		table.insert(torques, self:getTorqueCurveValue(v.time))
	end

	return torques, rotationSpeeds
end

function VehicleMotor:getMaximumForwardSpeed()
	return self.maxForwardSpeed
end

function VehicleMotor:getMaximumBackwardSpeed()
	return self.maxBackwardSpeed
end

function VehicleMotor:calculatePhysicalMaximumForwardSpeed()
	return VehicleMotor.calculatePhysicalMaximumSpeed(self.minForwardGearRatio, self.forwardGearRatios, self.maxRpm)
end

function VehicleMotor:calculatePhysicalMaximumBackwardSpeed()
	return VehicleMotor.calculatePhysicalMaximumSpeed(self.minBackwardGearRatio, self.backwardGearRatios, self.maxRpm)
end

function VehicleMotor.calculatePhysicalMaximumSpeed(minGearRatio, gearRatios, maxRpm)
	local minRatio = nil

	if minGearRatio ~= nil then
		minRatio = minGearRatio
	else
		minRatio = math.huge

		for _, ratio in pairs(gearRatios) do
			minRatio = math.min(minRatio, ratio)
		end
	end

	return maxRpm * math.pi / (30 * minRatio)
end

function VehicleMotor:update(dt)
	local vehicle = self.vehicle

	if next(vehicle.spec_motorized.differentials) ~= nil and vehicle.spec_motorized.motorizedNode ~= nil then
		if g_physicsDtNonInterpolated > 0 then
			local lastMotorRotSpeed = self.motorRotSpeed
			local lastDiffRotSpeed = self.differentialRotSpeed
			self.motorRotSpeed, self.differentialRotSpeed, self.gearRatio = getMotorRotationSpeed(vehicle.spec_motorized.motorizedNode)
			self.motorAvailableTorque, self.motorAppliedTorque, self.motorExternalTorque = getMotorTorque(vehicle.spec_motorized.motorizedNode)
			local motorRotAcceleration = (self.motorRotSpeed - lastMotorRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
			self.motorRotAcceleration = motorRotAcceleration
			self.motorRotAccelerationSmoothed = 0.8 * self.motorRotAccelerationSmoothed + 0.2 * motorRotAcceleration
			local diffRotAcc = (self.differentialRotSpeed - lastDiffRotSpeed) / (g_physicsDtNonInterpolated * 0.001)
			self.differentialRotAcceleration = diffRotAcc
			self.differentialRotAccelerationSmoothed = 0.8 * self.differentialRotAccelerationSmoothed + 0.2 * diffRotAcc
		end

		self.requiredMotorPower = math.huge
	else
		local _, gearRatio = self:getMinMaxGearRatio()
		self.differentialRotSpeed = WheelsUtil.computeDifferentialRotSpeedNonMotor(vehicle)
		self.motorRotSpeed = math.max(math.abs(self.differentialRotSpeed * gearRatio), 0)
		self.gearRatio = gearRatio
	end

	if self.lastPtoRpm == nil then
		self.lastPtoRpm = self.minRpm
	end

	local ptoRpm = PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio

	if self.lastPtoRpm < ptoRpm then
		self.lastPtoRpm = math.min(ptoRpm, self.lastPtoRpm + self.maxRpm * dt / 2000)
	elseif ptoRpm < self.lastPtoRpm then
		self.lastPtoRpm = math.max(self.minRpm, self.lastPtoRpm - self.maxRpm * dt / 1000)
	end

	local ptoRpm = math.min(self.lastPtoRpm, self.maxRpm)
	local clampedMotorRpm = math.max(self.motorRotSpeed * 30 / math.pi, ptoRpm, self.minRpm)

	self:setLastRpm(clampedMotorRpm)

	if self.vehicle.isServer then
		self.equalizedMotorRpm = clampedMotorRpm
	end
end

function VehicleMotor:getBestGearRatio(wheelSpeedRpm, minRatio, maxRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if requiredMotorRpm ~= 0 then
		local gearRatio = math.max(requiredMotorRpm - accSafeMotorRpm, requiredMotorRpm * 0.8) / math.max(wheelSpeedRpm, 0.001)
		gearRatio = MathUtil.clamp(gearRatio, minRatio, maxRatio)

		return gearRatio
	end

	wheelSpeedRpm = math.max(wheelSpeedRpm, 0.0001)
	local bestMotorPower = 0
	local bestGearRatio = minRatio

	for gearRatio = minRatio, maxRatio, 0.5 do
		local motorRpm = wheelSpeedRpm * gearRatio

		if motorRpm > self.maxRpm - accSafeMotorRpm then
			break
		end

		local motorPower = self:getTorqueCurveValue(math.max(motorRpm, self.minRpm)) * motorRpm * math.pi / 30

		if bestMotorPower < motorPower then
			bestMotorPower = motorPower
			bestGearRatio = gearRatio
		end

		if requiredMotorPower <= motorPower then
			break
		end
	end

	return bestGearRatio
end

function VehicleMotor:getBestGear(acceleration, wheelSpeedRpm, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)
	if math.abs(acceleration) < 0.001 then
		acceleration = 1

		if wheelSpeedRpm < 0 then
			acceleration = -1
		end
	end

	if acceleration > 0 then
		if self.minForwardGearRatio ~= nil then
			local wheelSpeedRpm = math.max(wheelSpeedRpm, 0)
			local bestGearRatio = self:getBestGearRatio(wheelSpeedRpm, self.minForwardGearRatio, self.maxForwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)

			return 1, bestGearRatio
		else
			return 1, self.forwardGearRatios[1]
		end
	elseif self.minBackwardGearRatio ~= nil then
		local wheelSpeedRpm = math.max(-wheelSpeedRpm, 0)
		local bestGearRatio = self:getBestGearRatio(wheelSpeedRpm, self.minBackwardGearRatio, self.maxBackwardGearRatio, accSafeMotorRpm, requiredMotorPower, requiredMotorRpm)

		return -1, -bestGearRatio
	else
		return -1, -self.backwardGearRatios[1]
	end
end

function VehicleMotor:findGearChangeTargetGear(curGear, prevGear, gearRatios, gearSign, acceleratorPedal, dt)
	local newGear = curGear
	local minAllowedRpm, maxAllowedRpm = self:getRequiredMotorRpmRange()
	local differentialRpm = math.max(self.differentialRotSpeed * 30 / math.pi * gearSign, 0.0001)
	local maxPower = 0
	local maxPowerGear = 0

	for gear = 1, #gearRatios do
		local rpm = differentialRpm * gearRatios[gear]

		if maxAllowedRpm >= rpm and minAllowedRpm <= rpm then
			local power = self:getTorqueCurveValue(rpm) * rpm

			if maxPower <= power then
				maxPower = power
				maxPowerGear = gear
			end
		end
	end

	if maxPowerGear ~= 0 then
		local bestTradeoff = 0

		for gear = #gearRatios, 1, -1 do
			local nextRpm = differentialRpm * gearRatios[gear]

			if maxAllowedRpm >= nextRpm and minAllowedRpm <= nextRpm then
				local nextPower = self:getTorqueCurveValue(nextRpm) * nextRpm

				if nextPower >= maxPower * 0.8 then
					local powerFactor = (nextPower - 0.8 * maxPower) / (maxPower * 0.2)
					local rpmFactor = (maxAllowedRpm - nextRpm) / math.max(maxAllowedRpm - minAllowedRpm, 0.001)

					if acceleratorPedal == 0 then
						rpmFactor = 1 - rpmFactor
					else
						rpmFactor = rpmFactor * 3
					end

					local newGearFactor = gear ~= prevGear and 0.5 or 0
					local tradeoff = powerFactor + rpmFactor + newGearFactor

					if bestTradeoff < tradeoff then
						bestTradeoff = tradeoff
						newGear = gear
					end
				end
			end
		end
	else
		local minDiffGear = 0
		local minDiff = math.huge

		for gear = 1, #gearRatios do
			local rpm = differentialRpm * gearRatios[gear]
			local diff = math.max(rpm - maxAllowedRpm, minAllowedRpm - rpm)

			if diff < minDiff then
				minDiff = diff
				minDiffGear = gear
			end
		end

		newGear = minDiffGear
	end

	return newGear
end

function VehicleMotor:findGearChangeTargetGearPrediction(curGear, gearRatios, gearSign, gearChangeTimer, acceleratorPedal, dt)
	local newGear = curGear
	local minAllowedRpm, maxAllowedRpm = self:getRequiredMotorRpmRange()
	local gearRatio = gearRatios[curGear]
	local differentialRotSpeed = math.max(self.differentialRotSpeed * gearSign, 0.0001)
	local differentialRpm = differentialRotSpeed * 30 / math.pi
	local clutchRpm = differentialRpm * gearRatio
	local diffSpeedAfterChange = nil

	if math.abs(acceleratorPedal) < 0.0001 then
		local brakeAcc = math.min(self.differentialRotAccelerationSmoothed * gearSign * 0.8, 0)
		diffSpeedAfterChange = math.max(differentialRotSpeed + brakeAcc * self.gearChangeTime * 0.001, 0)
	else
		local lastMotorRotSpeed = self.motorRotSpeed - self.motorRotAcceleration * g_physicsDtLastValidNonInterpolated * 0.001
		local lastDampedMotorRotSpeed = lastMotorRotSpeed / (1 + self.dampingRateFullThrottle / self.rotInertia * g_physicsDtLastValidNonInterpolated * 0.001)
		local neededInertiaTorque = (self.motorRotSpeed - lastDampedMotorRotSpeed) / (g_physicsDtLastValidNonInterpolated * 0.001) * self.rotInertia
		local lastMotorTorque = self.motorAppliedTorque - self.motorExternalTorque - neededInertiaTorque
		local totalMass = self.vehicle:getTotalMass()
		local expectedAcc = lastMotorTorque * gearRatio / totalMass
		local uncalculatedAccFactor = 0.9
		local gravityAcc = math.max(expectedAcc * uncalculatedAccFactor - math.max(self.differentialRotAcceleration * gearSign, 0), 0)
		diffSpeedAfterChange = math.max(differentialRotSpeed - gravityAcc * self.gearChangeTime * 0.001, 0)
	end

	local maxPower = 0
	local maxPowerGear = 0

	for gear = 1, #gearRatios do
		local rpm = nil

		if gear == curGear then
			rpm = clutchRpm
		else
			rpm = diffSpeedAfterChange * gearRatios[gear] * 30 / math.pi
		end

		if maxAllowedRpm >= rpm and minAllowedRpm <= rpm then
			local power = self:getTorqueCurveValue(rpm) * rpm

			if maxPower <= power then
				maxPower = power
				maxPowerGear = gear
			end
		end
	end

	if maxPowerGear ~= 0 then
		local bestTradeoff = 0

		for gear = #gearRatios, 1, -1 do
			local nextRpm = nil

			if gear == curGear then
				nextRpm = clutchRpm
			else
				nextRpm = diffSpeedAfterChange * gearRatios[gear] * 30 / math.pi
			end

			if maxAllowedRpm >= nextRpm and minAllowedRpm <= nextRpm then
				local nextPower = self:getTorqueCurveValue(nextRpm) * nextRpm

				if nextPower >= maxPower * 0.8 then
					local powerFactor = (nextPower - maxPower * 0.8) / (maxPower * 0.2)
					local curSpeedRpm = differentialRpm * gearRatios[gear]
					local rpmFactor = MathUtil.clamp((maxAllowedRpm - curSpeedRpm) / math.max(maxAllowedRpm - minAllowedRpm, 0.001), 0, 1)
					local gearChangeFactor = nil

					if gear == curGear then
						gearChangeFactor = 1
					else
						gearChangeFactor = math.min(-gearChangeTimer / 2000, 0.9)
					end

					if math.abs(acceleratorPedal) < 0.0001 then
						rpmFactor = 1 - rpmFactor
					else
						rpmFactor = rpmFactor * 3
					end

					local tradeoff = powerFactor + rpmFactor + gearChangeFactor

					if bestTradeoff < tradeoff then
						bestTradeoff = tradeoff
						newGear = gear
					end
				end
			end
		end
	else
		local minDiffGear = 0
		local minDiff = math.huge

		for gear = 1, #gearRatios do
			local rpm = diffSpeedAfterChange * gearRatios[gear] * 30 / math.pi
			local diff = math.max(rpm - maxAllowedRpm, minAllowedRpm - rpm)

			if diff < minDiff then
				minDiff = diff
				minDiffGear = gear
			end
		end

		newGear = minDiffGear
	end

	return newGear
end

function VehicleMotor:updateGear(acceleratorPedal, dt)
	local adjAcceleratorPedal = acceleratorPedal

	if self.gearChangeTimer >= 0 then
		self.gearChangeTimer = self.gearChangeTimer - dt

		if self.gearChangeTimer < 0 then
			if self.targetGear > 0 then
				self.gear = self:findGearChangeTargetGear(self.targetGear, self.previousGear, self.forwardGearRatios, 1, acceleratorPedal, dt)
				self.minGearRatio = self.forwardGearRatios[self.gear]
			else
				self.gear = -self:findGearChangeTargetGear(-self.targetGear, -self.previousGear, self.backwardGearRatios, -1, acceleratorPedal, dt)
				self.minGearRatio = -self.backwardGearRatios[-self.gear]
			end

			self.maxGearRatio = self.minGearRatio
		end

		adjAcceleratorPedal = 0
	else
		local gearSign = 0

		if acceleratorPedal > 0 then
			if self.minForwardGearRatio ~= nil then
				self.minGearRatio = self.minForwardGearRatio
				self.maxGearRatio = self.maxForwardGearRatio
			else
				gearSign = 1
			end
		elseif acceleratorPedal < 0 then
			if self.minBackwardGearRatio ~= nil then
				self.minGearRatio = -self.minBackwardGearRatio
				self.maxGearRatio = -self.maxBackwardGearRatio
			else
				gearSign = -1
			end
		elseif self.maxGearRatio > 0 then
			if self.minForwardGearRatio == nil then
				gearSign = 1
			end
		elseif self.maxGearRatio < 0 and self.minBackwardGearRatio == nil then
			gearSign = -1
		end

		self.autoGearChangeTimer = self.autoGearChangeTimer - dt
		local newGear = self.gear

		if g_manualGearShift then
			if self.manualTargetGear ~= nil then
				newGear = self.manualTargetGear
				self.manualTargetGear = nil
			end
		elseif gearSign > 0 then
			if self.gear <= 0 then
				newGear = 1
			else
				if self.autoGearChangeTimer <= 0 then
					newGear = self:findGearChangeTargetGearPrediction(self.gear, self.forwardGearRatios, 1, self.autoGearChangeTimer, acceleratorPedal, dt)
				end

				newGear = math.min(math.max(newGear, 1), #self.forwardGearRatios)
			end
		elseif gearSign < 0 then
			if self.gear >= 0 then
				newGear = -1
			else
				if self.autoGearChangeTimer <= 0 then
					newGear = -self:findGearChangeTargetGearPrediction(-self.gear, self.backwardGearRatios, -1, self.autoGearChangeTimer, acceleratorPedal, dt)
				end

				newGear = math.max(math.min(newGear, -1), -(#self.backwardGearRatios))
			end
		end

		if newGear ~= self.gear then
			self.targetGear = newGear
			self.previousGear = self.gear
			self.gear = 0
			self.minGearRatio = 0
			self.maxGearRatio = 0
			self.autoGearChangeTimer = self.autoGearChangeTime
			self.gearChangeTimer = self.gearChangeTime
			adjAcceleratorPedal = 0
		end
	end

	return adjAcceleratorPedal
end

function VehicleMotor:getMinMaxGearRatio()
	return self.minGearRatio, self.maxGearRatio
end

function VehicleMotor:getGearRatio()
	return self.gearRatio
end

function VehicleMotor:getCurMaxRpm()
	local maxRpm = self.maxRpm
	local gearRatio = self:getGearRatio()

	if gearRatio ~= 0 then
		local speedLimit = math.min(self.speedLimit, math.max(self.speedLimitAcc, self.vehicle.lastSpeedReal * 3600)) * 0.277778

		if gearRatio > 0 then
			speedLimit = math.min(speedLimit, self.maxForwardSpeed)
		else
			speedLimit = math.min(speedLimit, self.maxBackwardSpeed)
		end

		maxRpm = math.min(maxRpm, speedLimit * 30 / math.pi * math.abs(gearRatio))
	end

	maxRpm = math.min(maxRpm, self.rpmLimit)

	return maxRpm
end

function VehicleMotor:setSpeedLimit(limit)
	self.speedLimit = math.max(limit, self.minSpeed)
end

function VehicleMotor:getSpeedLimit()
	return self.speedLimit
end

function VehicleMotor:setAccelerationLimit(accelerationLimit)
	self.accelerationLimit = accelerationLimit
end

function VehicleMotor:getAccelerationLimit()
	return self.accelerationLimit
end

function VehicleMotor:setRpmLimit(rpmLimit)
	self.rpmLimit = rpmLimit
end

function VehicleMotor:setMotorRotationAccelerationLimit(limit)
	self.motorRotationAccelerationLimit = limit
end

function VehicleMotor:getMotorRotationAccelerationLimit()
	return self.motorRotationAccelerationLimit
end
