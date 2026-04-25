source("dataS/scripts/vehicles/specializations/events/SetMotorTurnedOnEvent.lua")

Motorized = {
	DAMAGED_USAGE_INCREASE = 0.3
}

function Motorized.initSpecialization()
	g_configurationManager:addConfigurationType("motor", g_i18n:getText("configuration_motorSetup"), "motorized", nil, Motorized.getStoreAddtionalConfigData, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_storeManager:addSpecType("fuel", "shopListAttributeIconFuel", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuel)
	g_storeManager:addSpecType("maxSpeed", "shopListAttributeIconMaxSpeed", Motorized.loadSpecValueMaxSpeed, Motorized.getSpecValueMaxSpeed)
	g_storeManager:addSpecType("power", "shopListAttributeIconPower", Motorized.loadSpecValuePower, Motorized.getSpecValuePower)
	Vehicle.registerStateChange("MOTOR_TURN_ON")
	Vehicle.registerStateChange("MOTOR_TURN_OFF")
end

function Motorized.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function Motorized.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartMotor")
	SpecializationUtil.registerEvent(vehicleType, "onStopMotor")
end

function Motorized.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDifferentials", Motorized.loadDifferentials)
	SpecializationUtil.registerFunction(vehicleType, "loadMotor", Motorized.loadMotor)
	SpecializationUtil.registerFunction(vehicleType, "loadGears", Motorized.loadGears)
	SpecializationUtil.registerFunction(vehicleType, "loadExhaustEffects", Motorized.loadExhaustEffects)
	SpecializationUtil.registerFunction(vehicleType, "loadSounds", Motorized.loadSounds)
	SpecializationUtil.registerFunction(vehicleType, "loadConsumerConfiguration", Motorized.loadConsumerConfiguration)
	SpecializationUtil.registerFunction(vehicleType, "getIsMotorStarted", Motorized.getIsMotorStarted)
	SpecializationUtil.registerFunction(vehicleType, "getCanMotorRun", Motorized.getCanMotorRun)
	SpecializationUtil.registerFunction(vehicleType, "getStopMotorOnLeave", Motorized.getStopMotorOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getMotorNotAllowedWarning", Motorized.getMotorNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "startMotor", Motorized.startMotor)
	SpecializationUtil.registerFunction(vehicleType, "stopMotor", Motorized.stopMotor)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorProperties", Motorized.updateMotorProperties)
	SpecializationUtil.registerFunction(vehicleType, "updateConsumers", Motorized.updateConsumers)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorTemperature", Motorized.updateMotorTemperature)
	SpecializationUtil.registerFunction(vehicleType, "getMotor", Motorized.getMotor)
	SpecializationUtil.registerFunction(vehicleType, "getMotorStartTime", Motorized.getMotorStartTime)
	SpecializationUtil.registerFunction(vehicleType, "getMotorType", Motorized.getMotorType)
	SpecializationUtil.registerFunction(vehicleType, "getMotorRpmPercentage", Motorized.getMotorRpmPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getMotorLoadPercentage", Motorized.getMotorLoadPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getConsumerFillUnitIndex", Motorized.getConsumerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAirConsumerUsage", Motorized.getAirConsumerUsage)
end

function Motorized.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Motorized.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Motorized.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Motorized.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Motorized.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", Motorized.getDeactivateLightsOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", Motorized.getCanStartAIVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Motorized.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Motorized.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInteriorLights", Motorized.getIsActiveForInteriorLights)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForWipers", Motorized.getIsActiveForWipers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Motorized.getName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Motorized.getCanBeSelected)
end

function Motorized.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onAIEnd", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Motorized)
end

function Motorized:onLoad(savegame)
	local spec = self.spec_motorized

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.motor.animationNodes.animationNode", "motor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.differentialConfigurations", "vehicle.motorized.differentialConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motorConfigurations", "vehicle.motorized.motorConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fuelCapacity", "vehicle.fillUnit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer(with fill type 'air')#usage (is now in usage per second at full brake power)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.rpm", "vehicle.motorized.dashboards.dashboard with valueType 'rpm'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.speed", "vehicle.motorized.dashboards.dashboard with valueType 'speed'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.fuelUsage", "vehicle.motorized.dashboards.dashboard with valueType 'fuelUsage'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.fuel", "fillUnit.dashboard with valueType 'fillLevel'")

	spec.motorizedNode = nil

	for _, component in pairs(self.components) do
		if component.motorized then
			spec.motorizedNode = component.node

			break
		end
	end

	self:loadDifferentials(self.xmlFile, self.differentialIndex)
	self:loadMotor(self.xmlFile, self.configurations.motor)
	self:loadSounds(self.xmlFile, self.configurations.motor)
	self:loadConsumerConfiguration(self.xmlFile, spec.consumerConfigurationIndex)

	if self.isClient then
		self:loadExhaustEffects(self.xmlFile)
	end

	spec.stopMotorOnLeave = true
	spec.motorStartDuration = 0

	if spec.samples ~= nil and spec.samples.motorStart ~= nil then
		spec.motorStartDuration = spec.samples.motorStart.duration
	end

	spec.motorStartDuration = Utils.getNoNil(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.motorized.motorStartDuration"), spec.motorStartDuration), 0)
	spec.consumersEmptyWarning = g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.motorized#consumersEmptyWarning"), "warning_motorFuelEmpty"), self.customEnvironment)
	spec.turnOnText = g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.motorized#turnOnText"), "action_startMotor"), self.customEnvironment)
	spec.turnOffText = g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.motorized#turnOffText"), "action_stopMotor"), self.customEnvironment)
	spec.speedDisplayScale = 1
	spec.motorStartTime = 0
	spec.lastRoundPerMinute = 0
	spec.actualLoadPercentage = 0
	spec.smoothedLoadPercentage = 0
	spec.maxDecelerationDuringBrake = 0
	spec.showTurnOnMotorWarning = 0
	spec.isMotorStarted = false
	spec.motorStopTimerDuration = g_gameSettings:getValue("motorStopTimerDuration")
	spec.motorStopTimer = spec.motorStopTimerDuration
	spec.motorTemperature = {
		value = 20,
		valueSend = 20,
		valueMax = 120,
		valueMin = 20,
		heatingPerMS = 0.0015,
		coolingByWindPerMS = 0.001
	}
	spec.motorFan = {
		enabled = false,
		enableTemperature = 95,
		disableTemperature = 85,
		coolingPerMS = 0.003
	}
	spec.lastFuelUsage = 0
	spec.lastFuelUsageDisplay = 0
	spec.lastFuelUsageDisplayTime = 0
	spec.fuelUsageBuffer = ValueBuffer:new(250)
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
	spec.lastVehicleDamage = 0

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = "getMaxRpm",
			valueFunc = "getEqualizedMotorRpm",
			minFunc = 0,
			valueTypeToLoad = "rpm",
			valueObject = spec.motor
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "getLastSpeed",
			minFunc = 0,
			valueTypeToLoad = "speed",
			valueObject = self,
			maxFunc = self:getMotor():getMaximumForwardSpeed() * 3.6
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueTypeToLoad = "speedDir",
			centerFunc = 0,
			valueObject = self,
			valueFunc = Motorized.getDashboardSpeedDir,
			minFunc = -self:getMotor():getMaximumBackwardSpeed() * 3.6,
			maxFunc = self:getMotor():getMaximumForwardSpeed() * 3.6
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "lastFuelUsageDisplay",
			valueTypeToLoad = "fuelUsage",
			valueObject = spec
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = "valueMax",
			valueFunc = "value",
			minFunc = "valueMin",
			valueTypeToLoad = "motorTemperature",
			valueObject = spec.motorTemperature
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "value",
			valueTypeToLoad = "motorTemperatureWarning",
			valueObject = spec.motorTemperature,
			additionalAttributesFunc = Dashboard.warningAttributes,
			stateFunc = Dashboard.warningState
		})
	end

	spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.motorized.animationNodes", self.components, self, self.i3dMappings)
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Motorized:onPostLoad(savegame)
	local spec = self.spec_motorized

	if self.isServer then
		local moneyChange = 0

		for _, consumer in pairs(spec.consumersByFillTypeName) do
			local fillLevel = self:getFillUnitFillLevel(consumer.fillUnitIndex)
			local minFillLevel = self:getFillUnitCapacity(consumer.fillUnitIndex) * 0.1

			if fillLevel < minFillLevel then
				local fillLevelToFill = minFillLevel - fillLevel

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, fillLevelToFill, consumer.fillType, ToolType.UNDEFINED)

				local costs = fillLevelToFill * g_currentMission.economyManager:getPricePerLiter(consumer.fillType) * 2

				g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("expenses", costs)
				g_currentMission:addMoney(-costs, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL)

				moneyChange = moneyChange + costs
			end
		end

		if moneyChange > 0 then
			g_currentMission:addMoneyChange(-moneyChange, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
		end
	end
end

function Motorized:onDelete()
	local spec = self.spec_motorized

	if self.isClient then
		if spec.exhaustEffects ~= nil then
			for _, effect in pairs(spec.exhaustEffects) do
				g_i3DManager:releaseSharedI3DFile(effect.filename, self.baseDirectory, true)
			end
		end

		ParticleUtil.deleteParticleSystems(spec.exhaustParticleSystems)
		g_soundManager:deleteSamples(spec.samples)
		g_soundManager:deleteSamples(spec.motorSamples)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function Motorized:onReadStream(streamId, connection)
	local isMotorStarted = streamReadBool(streamId)

	if isMotorStarted then
		self:startMotor(true)
	else
		self:stopMotor(true)
	end
end

function Motorized:onWriteStream(streamId, connection)
	streamWriteBool(streamId, self.spec_motorized.isMotorStarted)
end

function Motorized:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local spec = self.spec_motorized

		if streamReadBool(streamId) then
			local rpm = streamReadUIntN(streamId, 11) / 2047
			local rpmRange = spec.motor:getMaxRpm() - spec.motor:getMinRpm()

			spec.motor:setEqualizedMotorRpm(rpm * rpmRange + spec.motor:getMinRpm())

			local loadPercentage = streamReadUIntN(streamId, 7)
			spec.actualLoadPercentage = loadPercentage / 127
			spec.smoothedLoadPercentage = 0.95 * spec.smoothedLoadPercentage + 0.05 * spec.actualLoadPercentage
			spec.brakeCompressor.doFill = streamReadBool(streamId)
		end
	end
end

function Motorized:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_motorized

		if streamWriteBool(streamId, self.spec_motorized.isMotorStarted) then
			local rpmRange = spec.motor:getMaxRpm() - spec.motor:getMinRpm()
			local rpm = MathUtil.clamp((spec.motor:getEqualizedMotorRpm() - spec.motor:getMinRpm()) / rpmRange, 0, 1)
			rpm = math.floor(rpm * 2047)

			streamWriteUIntN(streamId, rpm, 11)
			streamWriteUIntN(streamId, 127 * spec.actualLoadPercentage, 7)
			streamWriteBool(streamId, spec.brakeCompressor.doFill)
		end
	end
end

function Motorized:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_motorized
	local accInput = 0

	if self.getAxisForward ~= nil then
		accInput = self:getAxisForward()
	end

	if self:getIsMotorStarted() then
		spec.motor:update(dt)

		if self.getCruiseControlState ~= nil and self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
			accInput = 1
		end

		if self.isServer then
			self:updateConsumers(dt, accInput)

			local damage = self:getVehicleDamage()

			if math.abs(damage - spec.lastVehicleDamage) > 0.05 then
				self:updateMotorProperties()

				spec.lastVehicleDamage = self:getVehicleDamage()
			end
		end

		if self.isClient then
			local samples = spec.samples

			if g_soundManager:getIsSamplePlaying(spec.motorSamples[1], 1.5 * dt) then
				if samples.airCompressorStart ~= nil and samples.airCompressorStop ~= nil and samples.airCompressorRun ~= nil and spec.consumersByFillTypeName ~= nil and spec.consumersByFillTypeName.air ~= nil then
					local consumer = spec.consumersByFillTypeName.air

					if not consumer.doRefill then
						if g_soundManager:getIsSamplePlaying(samples.airCompressorRun) then
							g_soundManager:stopSample(samples.airCompressorRun)
							g_soundManager:playSample(samples.airCompressorStop)
						end
					elseif not g_soundManager:getIsSamplePlaying(samples.airCompressorRun) then
						if not g_soundManager:getIsSamplePlaying(samples.airCompressorStart, 1.5 * dt) and spec.brakeCompressor.playSampleRunTime == nil then
							g_soundManager:playSample(samples.airCompressorStart)

							spec.playSampleRunTime = g_currentMission.time + samples.airCompressorStart.duration
						end

						if not g_soundManager:getIsSamplePlaying(samples.airCompressorStart) then
							spec.brakeCompressor.playSampleRunTime = nil

							g_soundManager:stopSample(samples.airCompressorStart)
							g_soundManager:playSample(samples.airCompressorRun)
						end
					end
				end

				if spec.compressionSoundTime <= g_currentMission.time then
					g_soundManager:playSample(samples.airRelease)

					spec.compressionSoundTime = g_currentMission.time + math.random(10000, 40000)
				end

				local isBraking = self:getDecelerationAxis() > 0 and self:getLastSpeed() > 1

				if samples.compressedAir ~= nil then
					if isBraking then
						samples.compressedAir.brakeTime = samples.compressedAir.brakeTime + dt
					elseif samples.compressedAir.brakeTime > 0 then
						samples.compressedAir.lastBrakeTime = samples.compressedAir.brakeTime
						samples.compressedAir.brakeTime = 0

						g_soundManager:playSample(samples.compressedAir)
					end
				end

				if samples.brake ~= nil then
					if isBraking then
						if not spec.isBrakeSamplePlaying then
							g_soundManager:playSample(samples.brake)

							spec.isBrakeSamplePlaying = true
						end
					elseif spec.isBrakeSamplePlaying then
						g_soundManager:stopSample(samples.brake)

						spec.isBrakeSamplePlaying = false
					end
				end

				if samples.reverseDrive ~= nil and (self.getIsControlled ~= nil and self:getIsControlled() or self:getIsAIActive()) then
					local reverserDirection = self.getReverserDirection == nil and 1 or self:getReverserDirection()
					local isReverseDriving = spec.reverseDriveThreshold < self:getLastSpeed() and self.movingDirection ~= reverserDirection

					if not g_soundManager:getIsSamplePlaying(samples.reverseDrive) and isReverseDriving then
						g_soundManager:playSample(samples.reverseDrive)
					elseif not isReverseDriving then
						g_soundManager:stopSample(samples.reverseDrive)
					end
				end
			end
		end

		if self.isServer and not self:getIsAIActive() and self.lastMovedDistance > 0 then
			g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("traveledDistance", self.lastMovedDistance * 0.001)
		end

		spec.showTurnOnMotorWarning = false
	elseif self:getCanMotorRun() then
		spec.showTurnOnMotorWarning = accInput ~= 0
	end
end

function Motorized:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_motorized

	if self.isServer then
		local loadPercentage = spec.motor:getMotorAppliedTorque() / math.max(spec.motor:getMotorAvailableTorque(), 0.0001)
		spec.actualLoadPercentage = loadPercentage

		if spec.smoothedLoadPercentage < spec.actualLoadPercentage then
			spec.smoothedLoadPercentage = 0.95 * spec.smoothedLoadPercentage + 0.05 * loadPercentage
		else
			spec.smoothedLoadPercentage = 0.98 * spec.smoothedLoadPercentage + 0.02 * loadPercentage
		end

		if not g_currentMission.missionInfo.automaticMotorStartEnabled and spec.isMotorStarted and not self:getIsAIActive() then
			local isEntered = self.getIsEntered ~= nil and self:getIsEntered()
			local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

			if not isEntered and not isControlled then
				local isPlayerInRange = false

				for _, player in pairs(g_currentMission.players) do
					if player.isControlled then
						local distance = calcDistanceFrom(self.rootNode, player.rootNode)

						if distance < 250 then
							isPlayerInRange = true

							break
						end
					end
				end

				if not isPlayerInRange then
					for _, enterable in pairs(g_currentMission.enterables) do
						if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled then
							local distance = calcDistanceFrom(self.rootNode, enterable.rootNode)

							if distance < 250 then
								isPlayerInRange = true

								break
							end
						end
					end
				end

				if isPlayerInRange then
					spec.motorStopTimer = spec.motorStopTimerDuration
				else
					spec.motorStopTimer = spec.motorStopTimer - dt

					if spec.motorStopTimer <= 0 then
						self:stopMotor()
					end
				end
			end
		end

		if spec.isMotorStarted then
			self:updateMotorTemperature(dt)
		elseif g_currentMission.missionInfo.automaticMotorStartEnabled and self.getIsControlled ~= nil and self:getIsControlled() and self:getCanMotorRun() then
			self:startMotor(true)
		end
	end

	if self.isClient then
		if self:getIsMotorStarted() then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					local scale = MathUtil.lerp(spec.exhaustParticleSystems.minScale, spec.exhaustParticleSystems.maxScale, spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm())

					ParticleUtil.setEmitCountScale(spec.exhaustParticleSystems, scale)
					ParticleUtil.setParticleLifespan(ps, ps.originalLifespan * scale)
				end
			end

			if spec.exhaustFlap ~= nil then
				local minRandom = -0.1
				local maxRandom = 0.1
				local angle = MathUtil.lerp(minRandom, maxRandom, math.random()) + spec.exhaustFlap.maxRot * spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm()
				angle = MathUtil.clamp(angle, 0, spec.exhaustFlap.maxRot)

				setRotation(spec.exhaustFlap.node, angle, 0, 0)
			end

			if spec.exhaustEffects ~= nil then
				local lastSpeed = self:getLastSpeed()
				local dx, dy, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)

				if spec.lastDirection == nil then
					spec.lastDirection = {
						dx,
						dy,
						dz
					}
				end

				local x, _, z = worldDirectionToLocal(self.rootNode, spec.lastDirection[1], spec.lastDirection[2], spec.lastDirection[3])
				local dot = z
				dot = dot / MathUtil.vector2Length(x, z)
				local angle = math.acos(dot)

				if x < 0 then
					angle = -angle
				end

				local steeringPercent = math.abs(angle / dt / spec.exhaustEffectMaxSteeringSpeed)
				spec.lastDirection[3] = dz
				spec.lastDirection[2] = dy
				spec.lastDirection[1] = dx

				for _, effect in pairs(spec.exhaustEffects) do
					local rpmScale = spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm()
					local scale = MathUtil.lerp(effect.minRpmScale, effect.maxRpmScale, rpmScale)
					local forwardXRot = 0
					local forwardZRot = 0
					local steerXRot = 0
					local steerZRot = 0
					local r = MathUtil.lerp(effect.minRpmColor[1], effect.maxRpmColor[1], rpmScale)
					local g = MathUtil.lerp(effect.minRpmColor[2], effect.maxRpmColor[2], rpmScale)
					local b = MathUtil.lerp(effect.minRpmColor[3], effect.maxRpmColor[3], rpmScale)
					local a = MathUtil.lerp(effect.minRpmColor[4], effect.maxRpmColor[4], rpmScale)

					setShaderParameter(effect.effectNode, "exhaustColor", r, g, b, a, false)

					if self.movingDirection == 1 then
						local percent = MathUtil.clamp(lastSpeed / effect.maxForwardSpeed, 0, 1)
						forwardXRot = effect.xzRotationsForward[1] * percent
						forwardZRot = effect.xzRotationsForward[2] * percent
					elseif self.movingDirection == -1 then
						local percent = MathUtil.clamp(lastSpeed / effect.maxBackwardSpeed, 0, 1)
						forwardXRot = effect.xzRotationsBackward[1] * percent
						forwardZRot = effect.xzRotationsBackward[2] * percent
					end

					if angle > 0 then
						steerXRot = effect.xzRotationsRight[1] * steeringPercent
						steerZRot = effect.xzRotationsRight[2] * steeringPercent
					elseif angle < 0 then
						steerXRot = effect.xzRotationsLeft[1] * steeringPercent
						steerZRot = effect.xzRotationsLeft[2] * steeringPercent
					end

					local targetXRot = effect.xzRotationsOffset[1] + forwardXRot + steerXRot
					local targetZRot = effect.xzRotationsOffset[2] + forwardZRot + steerZRot

					if effect.xRot < targetXRot then
						effect.xRot = math.min(effect.xRot + 0.003 * dt, targetXRot)
					else
						effect.xRot = math.max(effect.xRot - 0.003 * dt, targetXRot)
					end

					if effect.xRot < targetZRot then
						effect.zRot = math.min(effect.zRot + 0.003 * dt, targetZRot)
					else
						effect.zRot = math.max(effect.zRot - 0.003 * dt, targetZRot)
					end

					setShaderParameter(effect.effectNode, "param", effect.xRot, effect.zRot, 0, scale, false)
				end
			end

			spec.lastFuelUsageDisplayTime = spec.lastFuelUsageDisplayTime + dt

			if spec.lastFuelUsageDisplayTime > 250 then
				spec.lastFuelUsageDisplayTime = 0
				spec.lastFuelUsageDisplay = spec.fuelUsageBuffer:getAverage()
			end

			spec.fuelUsageBuffer:add(spec.lastFuelUsage)
		end

		if isActiveForInputIgnoreSelection then
			if g_currentMission.missionInfo.automaticMotorStartEnabled and not self:getCanMotorRun() then
				local warning = self:getMotorNotAllowedWarning()

				if warning ~= nil then
					g_currentMission:showBlinkingWarning(warning, 2000)
				end
			end

			local actionEvent = spec.actionEvents[InputAction.TOGGLE_MOTOR_STATE]

			if actionEvent ~= nil then
				if not g_currentMission.missionInfo.automaticMotorStartEnabled then
					local text = nil

					g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)

					if self:getIsMotorStarted() then
						g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_LOW)

						text = spec.turnOffText
					else
						g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_HIGH)

						text = spec.turnOnText
					end

					g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
				else
					g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
				end
			end
		end
	end
end

function Motorized:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_motorized

	if spec.showTurnOnMotorWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_motorNotStarted"), 2000)
	end
end

function Motorized:loadDifferentials(xmlFile, configDifferentialIndex)
	local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, configDifferentialIndex, "vehicle.motorized.differentialConfigurations.differentialConfiguration", "vehicle.motorized.differentials", "differentials")
	local spec = self.spec_motorized
	spec.differentials = {}

	if self.isServer and spec.motorizedNode ~= nil then
		local i = 0

		while true do
			local key = string.format(key .. ".differentials.differential(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local torqueRatio = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#torqueRatio"), 0.5)
			local maxSpeedRatio = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxSpeedRatio"), 1.3)
			local indices = {
				-1,
				-1
			}
			local indexIsWheel = {
				false,
				false
			}

			for j = 1, 2 do
				local wheelIndex = getXMLInt(xmlFile, key .. string.format("#wheelIndex%d", j))

				if wheelIndex ~= nil then
					if self:getWheelFromWheelIndex(wheelIndex) ~= nil then
						indices[j] = wheelIndex
						indexIsWheel[j] = true
					else
						g_logManager:xmlWarning(self.configFileName, "Unable to find wheelIndex '%d' for differential '%s' (Indices start at 1)", wheelIndex, key)
					end
				else
					local diffIndex = getXMLInt(xmlFile, key .. string.format("#differentialIndex%d", j))

					if diffIndex ~= nil then
						indices[j] = diffIndex - 1
						indexIsWheel[j] = false

						if diffIndex == 0 then
							g_logManager:xmlWarning(self.configFileName, "Unable to find differentialIndex '0' for differential '%s' (Indices start at 1)", key)
						end
					end
				end
			end

			if indices[1] ~= -1 and indices[2] ~= -1 then
				table.insert(spec.differentials, {
					torqueRatio = torqueRatio,
					maxSpeedRatio = maxSpeedRatio,
					diffIndex1 = indices[1],
					diffIndex1IsWheel = indexIsWheel[1],
					diffIndex2 = indices[2],
					diffIndex2IsWheel = indexIsWheel[2]
				})
			end

			i = i + 1
		end

		if #spec.differentials == 0 then
			g_logManager:xmlWarning(self.configFileName, "No differentials defined")
		end
	end
end

function Motorized:loadMotor(xmlFile, motorId)
	local key, motorId = ConfigurationUtil.getXMLConfigurationKey(xmlFile, motorId, "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")
	local spec = self.spec_motorized
	local fallbackConfigKey = "vehicle.motorized.motorConfigurations.motorConfiguration(0)"
	local fallbackOldKey = "vehicle"
	spec.motorType = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#type", getXMLString, "vehicle", fallbackConfigKey, fallbackOldKey)
	spec.motorStartAnimation = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#startAnimationName", getXMLString, "vehicle", fallbackConfigKey, fallbackOldKey)
	spec.fuelCapacity = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".fuelCapacity", "", getXMLFloat, 500, fallbackConfigKey, fallbackOldKey)
	spec.consumerConfigurationIndex = ConfigurationUtil.getConfigurationValue(xmlFile, key, "#consumerConfigurationIndex", "", getXMLInt, 1, fallbackConfigKey, fallbackOldKey)
	local wheelKey, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, self.configurations.wheel, "vehicle.wheels.wheelConfigurations.wheelConfiguration", "vehicle.wheels", "wheels")

	ObjectChangeUtil.updateObjectChanges(xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration", motorId, self.components, self)

	local motorMinRpm = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#minRpm", getXMLFloat, 1000, fallbackConfigKey, fallbackOldKey)
	local motorMaxRpm = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxRpm", getXMLFloat, 1800, fallbackConfigKey, fallbackOldKey)
	local minSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#minSpeed", getXMLFloat, 1, fallbackConfigKey, fallbackOldKey)
	local maxForwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxForwardSpeed", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local maxBackwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxBackwardSpeed", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)

	if maxForwardSpeed ~= nil then
		maxForwardSpeed = maxForwardSpeed / 3.6
	end

	if maxBackwardSpeed ~= nil then
		maxBackwardSpeed = maxBackwardSpeed / 3.6
	end

	local maxWheelSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, wheelKey, ".wheels", "#maxForwardSpeed", getXMLFloat, nil, , "vehicle.wheels")

	if maxWheelSpeed ~= nil then
		maxForwardSpeed = maxWheelSpeed / 3.6
	end

	local accelerationLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#accelerationLimit", getXMLFloat, 2, fallbackConfigKey, fallbackOldKey)
	local brakeForce = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#brakeForce", getXMLFloat, 10, fallbackConfigKey, fallbackOldKey) * 2
	local lowBrakeForceScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#lowBrakeForceScale", getXMLFloat, 0.5, fallbackConfigKey, fallbackOldKey)
	local lowBrakeForceSpeedLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#lowBrakeForceSpeedLimit", getXMLFloat, 1, fallbackConfigKey, fallbackOldKey) / 3600
	local torqueScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#torqueScale", getXMLFloat, 1, fallbackConfigKey, fallbackOldKey)
	local ptoMotorRpmRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#ptoMotorRpmRatio", getXMLFloat, 4, fallbackConfigKey, fallbackOldKey)
	local minForwardGearRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#minForwardGearRatio", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local maxForwardGearRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#maxForwardGearRatio", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local minBackwardGearRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#minBackwardGearRatio", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local maxBackwardGearRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#maxBackwardGearRatio", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local gearChangeTime = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#gearChangeTime", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local autoGearChangeTime = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#autoGearChangeTime", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)
	local axleRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".transmission", "#axleRatio", getXMLFloat, 1, fallbackConfigKey, fallbackOldKey)

	if maxForwardGearRatio == nil or minForwardGearRatio == nil then
		minForwardGearRatio, maxForwardGearRatio = nil
	else
		minForwardGearRatio = minForwardGearRatio * axleRatio
		maxForwardGearRatio = maxForwardGearRatio * axleRatio
	end

	if minBackwardGearRatio == nil or maxBackwardGearRatio == nil then
		minBackwardGearRatio, maxBackwardGearRatio = nil
	else
		minBackwardGearRatio = minBackwardGearRatio * axleRatio
		maxBackwardGearRatio = maxBackwardGearRatio * axleRatio
	end

	local forwardGearRatios = nil

	if minForwardGearRatio == nil then
		forwardGearRatios = self:loadGears(xmlFile, "forwardGear", key, motorId, fallbackConfigKey, fallbackOldKey, motorMaxRpm, axleRatio)

		if forwardGearRatios == nil then
			print("Warning: Missing forward gear ratios for motor in '" .. self.configFileName .. "'!")

			forwardGearRatios = {
				1
			}
		end
	end

	local backwardGearRatios = nil

	if minBackwardGearRatio == nil then
		backwardGearRatios = self:loadGears(xmlFile, "backwardGear", key, motorId, fallbackConfigKey, fallbackOldKey, motorMaxRpm, axleRatio)

		if backwardGearRatios == nil then
			print("Warning: Missing backward gear ratios for motor in '" .. self.configFileName .. "'!")

			backwardGearRatios = {
				1
			}
		end
	end

	local torqueCurve = AnimCurve:new(linearInterpolator1)
	local torqueI = 0
	local torqueBase = fallbackOldKey .. ".motor.torque"

	if key ~= nil and hasXMLProperty(xmlFile, fallbackConfigKey .. ".motor.torque(0)") then
		torqueBase = fallbackConfigKey .. ".motor.torque"
	end

	if key ~= nil and hasXMLProperty(xmlFile, key .. ".motor.torque(0)") then
		torqueBase = key .. ".motor.torque"
	end

	while true do
		local torqueKey = string.format(torqueBase .. "(%d)", torqueI)
		local normRpm = getXMLFloat(xmlFile, torqueKey .. "#normRpm")
		local rpm = nil

		if normRpm == nil then
			rpm = getXMLFloat(xmlFile, torqueKey .. "#rpm")
		else
			rpm = normRpm * motorMaxRpm
		end

		local torque = getXMLFloat(xmlFile, torqueKey .. "#torque")

		if torque == nil or rpm == nil then
			break
		end

		torqueCurve:addKeyframe({
			torque * torqueScale,
			time = rpm
		})

		torqueI = torqueI + 1
	end

	spec.motor = VehicleMotor:new(self, motorMinRpm, motorMaxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGearRatios, backwardGearRatios, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)
	local rotInertia = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#rotInertia", getXMLFloat, spec.motor:getRotInertia(), fallbackConfigKey, fallbackOldKey)
	local dampingRateFullThrottle = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#dampingRateFullThrottle", getXMLFloat, spec.motor:getDampingRateFullThrottle(), fallbackConfigKey, fallbackOldKey)
	local dampingRateZeroThrottleClutchEngaged = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#dampingRateZeroThrottleClutchEngaged", getXMLFloat, spec.motor:getDampingRateZeroThrottleClutchEngaged(), fallbackConfigKey, fallbackOldKey)
	local dampingRateZeroThrottleClutchDisengaged = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#dampingRateZeroThrottleClutchDisengaged", getXMLFloat, spec.motor:getDampingRateZeroThrottleClutchDisengaged(), fallbackConfigKey, fallbackOldKey)

	spec.motor:setRotInertia(rotInertia)
	spec.motor:setDampingRateFullThrottle(dampingRateFullThrottle)
	spec.motor:setDampingRateZeroThrottleClutchEngaged(dampingRateZeroThrottleClutchEngaged)
	spec.motor:setDampingRateZeroThrottleClutchDisengaged(dampingRateZeroThrottleClutchDisengaged)
	spec.motor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
	spec.motor:setAccelerationLimit(accelerationLimit)

	local motorRotationAccelerationLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#rpmSpeedLimit", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey)

	if motorRotationAccelerationLimit ~= nil then
		motorRotationAccelerationLimit = motorRotationAccelerationLimit * math.pi / 30

		spec.motor:setMotorRotationAccelerationLimit(motorRotationAccelerationLimit)
	end

	if gearChangeTime ~= nil then
		spec.motor:setGearChangeTime(gearChangeTime * 1000)
	end

	if autoGearChangeTime ~= nil then
		spec.motor:setAutoGearChangeTime(autoGearChangeTime * 1000)
	end
end

function Motorized:loadGears(xmlFile, gearName, motorKey, motorId, fallbackConfigKey, fallbackOldKey, motorMaxRpm, axleRatio)
	local gearBase = nil

	if motorKey ~= nil and hasXMLProperty(xmlFile, string.format("%s.transmission.%s(0)", motorKey, gearName)) then
		gearBase = string.format("%s.transmission.%s", motorKey, gearName)
	elseif motorKey ~= nil and hasXMLProperty(xmlFile, string.format("%s.transmission.%s(0)", fallbackConfigKey, gearName)) then
		gearBase = string.format("%s.transmission.%s", fallbackConfigKey, gearName)
	else
		gearBase = string.format("%s.transmission.%s", fallbackOldKey, gearName)
	end

	local gearRatios = {}
	local gearI = 0

	while true do
		local gearKey = string.format(gearBase .. "(%d)", gearI)
		local gearRatio = getXMLFloat(xmlFile, gearKey .. "#gearRatio")

		if gearRatio == nil then
			break
		end

		table.insert(gearRatios, gearRatio * axleRatio)

		gearI = gearI + 1
	end

	if #gearRatios > 0 then
		return gearRatios
	end
end

function Motorized:loadExhaustEffects(xmlFile)
	local spec = self.spec_motorized
	spec.exhaustParticleSystems = {}
	local exhaustParticleSystemCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.motorized.exhaustParticleSystems#count"), 0)

	for i = 1, exhaustParticleSystemCount do
		local namei = string.format("vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem%d", i)
		local ps = {}

		ParticleUtil.loadParticleSystem(xmlFile, ps, namei, self.components, false, nil, self.baseDirectory)

		ps.minScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.exhaustParticleSystems#minScale"), 0.5)
		ps.maxScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.exhaustParticleSystems#maxScale"), 1)

		table.insert(spec.exhaustParticleSystems, ps)
	end

	if #spec.exhaustParticleSystems == 0 then
		spec.exhaustParticleSystems = nil
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, "vehicle.motorized.exhaustFlap#index", "vehicle.motorized.exhaustFlap#node")

	local exhaustFlapIndex = getXMLString(xmlFile, "vehicle.motorized.exhaustFlap#node")

	if exhaustFlapIndex ~= nil then
		spec.exhaustFlap = {
			node = I3DUtil.indexToObject(self.components, exhaustFlapIndex, self.i3dMappings),
			maxRot = MathUtil.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.exhaustFlap#maxRot"), 0))
		}
	end

	spec.exhaustEffects = {}
	local i = 0

	while true do
		local key = string.format("vehicle.motorized.exhaustEffects.exhaustEffect(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

		local linkNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)
		local filename = getXMLString(xmlFile, key .. "#filename")

		if filename ~= nil and linkNode ~= nil then
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				local node = getChildAt(i3dNode, 0)

				if getHasShaderParameter(node, "param") then
					local effect = {
						effectNode = node,
						node = linkNode,
						filename = filename
					}

					link(effect.node, effect.effectNode)
					setVisibility(effect.effectNode, false)
					delete(i3dNode)

					effect.minRpmColor = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#minRpmColor"), "0 0 0 1"), 4)
					effect.maxRpmColor = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#maxRpmColor"), "0.0384 0.0359 0.0627 2.0"), 4)
					effect.minRpmScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minRpmScale"), 0.25)
					effect.maxRpmScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxRpmScale"), 0.95)
					effect.maxForwardSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxForwardSpeed"), math.ceil(spec.motor:getMaximumForwardSpeed() * 3.6))
					effect.maxBackwardSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxBackwardSpeed"), math.ceil(spec.motor:getMaximumBackwardSpeed() * 3.6))
					effect.xzRotationsOffset = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#xzRotationsOffset"), "0 0"), 2)
					effect.xzRotationsForward = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#xzRotationsForward"), "0 0"), 2)
					effect.xzRotationsBackward = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#xzRotationsBackward"), "0 0"), 2)
					effect.xzRotationsLeft = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#xzRotationsLeft"), "0 0"), 2)
					effect.xzRotationsRight = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, key .. "#xzRotationsRight"), "0 0"), 2)
					effect.xRot = 0
					effect.zRot = 0

					table.insert(spec.exhaustEffects, effect)
				end
			end
		end

		i = i + 1
	end

	spec.exhaustEffectMaxSteeringSpeed = 0.001
end

function Motorized:loadSounds(xmlFile, motorId)
	if self.isClient then
		local spec = self.spec_motorized
		local baseString = "vehicle.motorized.sounds"
		spec.samples = {
			motorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			motorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			gearbox = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearbox", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			retarder = g_soundManager:loadSampleFromXML(xmlFile, baseString, "retarder", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.motorSamples = {}
		local i = 0

		while true do
			local sample = g_soundManager:loadSampleFromXML(xmlFile, baseString, string.format("motor(%d)", i), self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

			if sample == nil then
				break
			end

			table.insert(spec.motorSamples, sample)

			i = i + 1
		end

		spec.samples.airCompressorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.airCompressorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.airCompressorRun = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorRun", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.compressedAir = g_soundManager:loadSampleFromXML(xmlFile, baseString, "compressedAir", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

		if spec.samples.compressedAir ~= nil then
			spec.samples.compressedAir.brakeTime = 0
			spec.samples.compressedAir.lastBrakeTime = 0
		end

		spec.samples.airRelease = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airRelease", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.reverseDrive = g_soundManager:loadSampleFromXML(xmlFile, baseString, "reverseDrive", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.reverseDriveThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.reverseDriveSound#threshold"), 4)
		spec.brakeCompressor = {
			capacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.brakeCompressor#capacity"), 6)
		}
		spec.brakeCompressor.refillFilllevel = math.min(spec.brakeCompressor.capacity, Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.brakeCompressor#refillFillLevel"), spec.brakeCompressor.capacity / 2))
		spec.brakeCompressor.fillSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorized.brakeCompressor#fillSpeed"), 0.6) / 1000
		spec.brakeCompressor.fillLevel = 0
		spec.brakeCompressor.doFill = true
		spec.isBrakeSamplePlaying = false
		spec.samples.brake = g_soundManager:loadSampleFromXML(xmlFile, baseString, "brake", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.compressionSoundTime = 0
	end
end

function Motorized:loadConsumerConfiguration(xmlFile, consumerIndex)
	local key = string.format("vehicle.motorized.consumerConfigurations.consumerConfiguration(%d)", consumerIndex - 1)
	local spec = self.spec_motorized
	local fallbackConfigKey = "vehicle.motorized.consumers"
	local fallbackOldKey = nil
	spec.consumers = {}
	spec.consumersByFillTypeName = {}
	spec.consumersByFillType = {}

	if not hasXMLProperty(xmlFile, key) then
		return
	end

	local i = 0

	while true do
		local consumerKey = string.format(".consumer(%d)", i)

		if not hasXMLProperty(xmlFile, key .. consumerKey) then
			break
		end

		local consumer = {
			fillUnitIndex = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillUnitIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey)
		}
		local fillTypeName = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillType", getXMLString, "consumer", fallbackConfigKey, fallbackOldKey)
		consumer.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		local fillUnit = self:getFillUnitByIndex(consumer.fillUnitIndex)

		if fillUnit ~= nil then
			fillUnit.startFillLevel = fillUnit.capacity
			fillUnit.startFillTypeIndex = consumer.fillType
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown fillUnit '%d' for consumer '%s'", consumer.fillUnitIndex, key .. consumerKey)

			break
		end

		local usage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#usage", getXMLFloat, 1, fallbackConfigKey, fallbackOldKey)
		consumer.permanentConsumption = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#permanentConsumption", getXMLBool, true, fallbackConfigKey, fallbackOldKey)

		if consumer.permanentConsumption then
			consumer.usage = usage / 3600000
		else
			consumer.usage = usage
		end

		consumer.refillLitersPerSecond = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillLitersPerSecond", getXMLFloat, 0, fallbackConfigKey, fallbackOldKey)
		consumer.refillCapacityPercentage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillCapacityPercentage", getXMLFloat, 0, fallbackConfigKey, fallbackOldKey)

		table.insert(spec.consumers, consumer)

		spec.consumersByFillTypeName[fillTypeName] = consumer
		spec.consumersByFillType[consumer.fillType] = consumer
		i = i + 1
	end
end

function Motorized:getIsMotorStarted(isRunning)
	return self.spec_motorized.isMotorStarted and (not isRunning or self.spec_motorized.motorStartTime < g_currentMission.time)
end

function Motorized:getCanMotorRun()
	local spec = self.spec_motorized
	local canRun = true

	if spec.consumersByFillTypeName.diesel ~= nil then
		canRun = self:getFillUnitFillLevel(spec.consumersByFillTypeName.diesel.fillUnitIndex) > 0
	end

	if canRun and spec.consumersByFillTypeName.def ~= nil then
		canRun = self:getFillUnitFillLevel(spec.consumersByFillTypeName.def.fillUnitIndex) > 0
	end

	return canRun
end

function Motorized:getStopMotorOnLeave()
	if GS_IS_MOBILE_VERSION and self:getRootVehicle():getActionControllerDirection() == -1 then
		return false
	end

	return self.spec_motorized.stopMotorOnLeave
end

function Motorized:getMotorNotAllowedWarning()
	local spec = self.spec_motorized

	if spec.consumersByFillTypeName.diesel ~= nil and self:getFillUnitFillLevel(spec.consumersByFillTypeName.diesel.fillUnitIndex) <= 0 then
		return spec.consumersEmptyWarning
	end

	if spec.consumersByFillTypeName.def ~= nil and self:getFillUnitFillLevel(spec.consumersByFillTypeName.def.fillUnitIndex) <= 0 then
		return spec.consumersEmptyWarning
	end

	return nil
end

function Motorized:startMotor(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, true), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, true))
		end
	end

	local spec = self.spec_motorized

	if not spec.isMotorStarted then
		spec.isMotorStarted = true

		if self.isClient then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					ParticleUtil.setEmittingState(ps, true)
				end
			end

			if spec.exhaustEffects ~= nil then
				for _, effect in pairs(spec.exhaustEffects) do
					setVisibility(effect.effectNode, true)

					effect.xRot = effect.xzRotationsOffset[1]
					effect.zRot = effect.xzRotationsOffset[2]

					setShaderParameter(effect.effectNode, "param", effect.xRot, effect.zRot, 0, 0, false)

					local color = effect.minRpmColor

					setShaderParameter(effect.effectNode, "exhaustColor", color[1], color[2], color[3], color[4], false)
				end
			end

			g_soundManager:stopSample(spec.samples.motorStop)
			g_soundManager:playSample(spec.samples.motorStart)
			g_soundManager:playSamples(spec.motorSamples, 0, spec.samples.motorStart)
			g_soundManager:playSample(spec.samples.gearbox, 0, spec.samples.motorStart)
			g_soundManager:playSample(spec.samples.retarder, 0, spec.samples.motorStart)
			g_animationManager:startAnimations(spec.animationNodes)

			if spec.motorStartAnimation ~= nil then
				self:playAnimation(spec.motorStartAnimation, 1, nil, true)
			end
		end

		spec.motorStartTime = g_currentMission.time + spec.motorStartDuration
		spec.compressionSoundTime = g_currentMission.time + math.random(5000, 20000)
		spec.lastRoundPerMinute = 0

		SpecializationUtil.raiseEvent(self, "onStartMotor")
		self:getRootVehicle():raiseStateChange(Vehicle.STATE_CHANGE_MOTOR_TURN_ON)
	end

	if self.setDashboardsDirty ~= nil then
		self:setDashboardsDirty()
	end
end

function Motorized:stopMotor(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self, false), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent:new(self, false))
		end
	end

	local spec = self.spec_motorized

	if spec.isMotorStarted then
		spec.isMotorStarted = false

		if self.isClient then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					ParticleUtil.setEmittingState(ps, false)
				end
			end

			if spec.exhaustEffects ~= nil then
				for _, effect in pairs(spec.exhaustEffects) do
					setVisibility(effect.effectNode, false)
				end
			end

			if spec.exhaustFlap ~= nil then
				setRotation(spec.exhaustFlap.node, 0, 0, 0)
			end

			g_soundManager:stopSample(spec.samples.motorStart)
			g_soundManager:playSample(spec.samples.motorStop)
			g_soundManager:stopSamples(spec.motorSamples)
			g_soundManager:stopSample(spec.samples.gearbox)
			g_soundManager:stopSample(spec.samples.retarder)
			g_soundManager:stopSample(spec.samples.airCompressorStart)
			g_soundManager:stopSample(spec.samples.airCompressorStop)
			g_soundManager:stopSample(spec.samples.airCompressorRun)
			g_soundManager:stopSample(spec.samples.compressedAir)
			g_soundManager:stopSample(spec.samples.airRelease)
			g_soundManager:stopSample(spec.samples.reverseDrive)
			g_soundManager:stopSample(spec.samples.brake)

			spec.isBrakeSamplePlaying = false

			g_animationManager:stopAnimations(spec.animationNodes)

			if spec.motorStartAnimation ~= nil then
				self:playAnimation(spec.motorStartAnimation, -1, nil, true)
			end
		end

		SpecializationUtil.raiseEvent(self, "onStopMotor")
		self:getRootVehicle():raiseStateChange(Vehicle.STATE_CHANGE_MOTOR_TURN_OFF)
	end

	if self.setDashboardsDirty ~= nil then
		self:setDashboardsDirty()
	end
end

function Motorized:updateConsumers(dt, accInput)
	local spec = self.spec_motorized
	local idleFactor = 0.5
	local rpmPercentage = (spec.motor:getLastMotorRpm() - spec.motor:getMinRpm()) / (spec.motor:getMaxRpm() - spec.motor:getMinRpm())
	local rpmFactor = idleFactor + rpmPercentage * (1 - idleFactor)
	local loadFactor = spec.smoothedLoadPercentage * rpmPercentage
	local motorFactor = 0.5 * (0.2 * rpmFactor + 1.8 * loadFactor)
	local usageFactor = 1

	if g_currentMission.missionInfo.fuelUsageLow then
		usageFactor = 0.7
	end

	local damage = self:getVehicleDamage()

	if damage > 0 then
		usageFactor = usageFactor * (1 + damage * Motorized.DAMAGED_USAGE_INCREASE)
	end

	for _, consumer in pairs(spec.consumers) do
		if consumer.permanentConsumption and consumer.usage > 0 then
			local used = usageFactor * motorFactor * consumer.usage * dt

			if used ~= 0 then
				local fillType = self:getFillUnitLastValidFillType(consumer.fillUnitIndex)
				local stats = g_currentMission:farmStats(self:getOwnerFarmId())

				stats:updateStats("fuelUsage", used)

				if self:getIsAIActive() and (fillType == FillType.DIESEL or fillType == FillType.DEF) and g_currentMission.missionInfo.helperBuyFuel then
					if fillType == FillType.DIESEL then
						local price = used * g_currentMission.economyManager:getPricePerLiter(fillType) * 1.5

						stats:updateStats("expenses", price)
						g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
					end

					used = 0
				end

				if fillType == consumer.fillType then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -used, fillType, ToolType.UNDEFINED)
				end

				if fillType == FillType.DIESEL then
					spec.lastFuelUsage = used / dt * 1000 * 60 * 60
				elseif fillType == FillType.DEF then
					spec.lastDefUsage = used / dt * 1000 * 60 * 60
				end
			end
		end
	end

	if spec.consumersByFillTypeName.air ~= nil then
		local consumer = spec.consumersByFillTypeName.air
		local fillType = self:getFillUnitLastValidFillType(consumer.fillUnitIndex)

		if fillType == consumer.fillType then
			local usage = 0
			local forwardBrake = self.movingDirection > 0 and accInput < 0
			local backwardBrake = self.movingDirection < 0 and accInput > 0
			local brakeIsPressed = self:getLastSpeed() > 1 and (forwardBrake or backwardBrake)

			if brakeIsPressed then
				local delta = math.abs(accInput) * dt * self:getAirConsumerUsage() / 1000

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -delta, consumer.fillType, ToolType.UNDEFINED)

				usage = delta / dt * 1000
			end

			local fillLevelPercentage = self:getFillUnitFillLevelPercentage(consumer.fillUnitIndex)

			if fillLevelPercentage < consumer.refillCapacityPercentage then
				consumer.doRefill = true
			elseif fillLevelPercentage == 1 then
				consumer.doRefill = false
			end

			if consumer.doRefill then
				local delta = consumer.refillLitersPerSecond / 1000 * dt

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, delta, consumer.fillType, ToolType.UNDEFINED)

				usage = -delta / dt * 1000
			end

			spec.lastAirUsage = usage
		end
	end
end

function Motorized:updateMotorTemperature(dt)
	local spec = self.spec_motorized
	local delta = spec.motorTemperature.heatingPerMS * dt
	local factor = (1 + 4 * spec.actualLoadPercentage) / 5
	delta = delta * (factor + self:getMotorRpmPercentage())
	spec.motorTemperature.value = math.min(spec.motorTemperature.valueMax, spec.motorTemperature.value + delta)
	delta = spec.motorTemperature.coolingByWindPerMS * dt
	local speedFactor = math.pow(math.min(1, self:getLastSpeed() / 30), 2)
	spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - speedFactor * delta)

	if spec.motorFan.enableTemperature < spec.motorTemperature.value then
		spec.motorFan.enabled = true
	end

	if spec.motorFan.enabled and spec.motorTemperature.value < spec.motorFan.disableTemperature then
		spec.motorFan.enabled = false
	end

	if spec.motorFan.enabled then
		local delta = spec.motorFan.coolingPerMS * dt
		spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - delta)
	end
end

function Motorized:getMotor()
	return self.spec_motorized.motor
end

function Motorized:getMotorStartTime()
	return self.spec_motorized.motorStartTime
end

function Motorized:getMotorType()
	return self.spec_motorized.motorType
end

function Motorized:getMotorRpmPercentage()
	local motor = self.spec_motorized.motor

	return (motor:getEqualizedMotorRpm() - motor:getMinRpm()) / (motor:getMaxRpm() - motor:getMinRpm())
end

g_soundManager:registerModifierType("MOTOR_RPM", Motorized.getMotorRpmPercentage)

function Motorized:getMotorLoadPercentage()
	return self.spec_motorized.smoothedLoadPercentage * math.min(self:getMotorRpmPercentage() * 3, 1)
end

g_soundManager:registerModifierType("MOTOR_LOAD", Motorized.getMotorLoadPercentage)

function Motorized:getMotorBrakeTime()
	local sample = self.spec_motorized.samples.compressedAir

	if sample ~= nil then
		return sample.lastBrakeTime / 1000
	end

	return 0
end

g_soundManager:registerModifierType("BRAKE_TIME", Motorized.getMotorBrakeTime)

function Motorized:getConsumerFillUnitIndex(fillTypeIndex)
	local spec = self.spec_motorized
	local consumer = spec.consumersByFillType[fillTypeIndex]

	if consumer ~= nil then
		return consumer.fillUnitIndex
	end

	return nil
end

function Motorized:getAirConsumerUsage()
	local spec = self.spec_motorized
	local consumer = spec.consumersByFillTypeName.air

	if consumer ~= nil then
		return consumer.usage
	end

	return 0
end

function Motorized:getBrakeForce(superFunc)
	local brakeForce = superFunc(self)

	return math.max(brakeForce, self.spec_motorized.motor:getBrakeForce())
end

function Motorized:getCanStartAIVehicle(superFunc)
	local canStart, warning = superFunc(self)

	return canStart and self:getIsMotorStarted(), warning
end

function Motorized:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	group.isMotorStarting = getXMLBool(xmlFile, key .. "#isMotorStarting")
	group.isMotorRunning = getXMLBool(xmlFile, key .. "#isMotorRunning")

	return true
end

function Motorized:getIsDashboardGroupActive(superFunc, group)
	local spec = self.spec_motorized

	if group.isMotorRunning and group.isMotorStarting and not spec.isMotorStarted then
		return false
	end

	if group.isMotorStarting and not group.isMotorRunning and (not spec.isMotorStarted or spec.motorStartTime < g_currentMission.time) then
		return false
	end

	if group.isMotorRunning and not group.isMotorStarting and (not spec.isMotorStarted or g_currentMission.time < spec.motorStartTime) then
		return false
	end

	return superFunc(self, group)
end

function Motorized:getIsActiveForInteriorLights(superFunc)
	if self.spec_motorized.isMotorStarted then
		return true
	end

	return superFunc(self)
end

function Motorized:getIsActiveForWipers(superFunc)
	if not self.spec_motorized.isMotorStarted then
		return false
	end

	return superFunc(self)
end

function Motorized:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	if self.isServer then
		local spec = self.spec_motorized

		if spec.motorizedNode ~= nil and next(spec.differentials) ~= nil then
			for _, differential in pairs(spec.differentials) do
				local diffIndex1 = differential.diffIndex1
				local diffIndex2 = differential.diffIndex2

				if differential.diffIndex1IsWheel then
					diffIndex1 = self:getWheelFromWheelIndex(diffIndex1).wheelShape
				end

				if differential.diffIndex2IsWheel then
					diffIndex2 = self:getWheelFromWheelIndex(diffIndex2).wheelShape
				end

				addDifferential(spec.motorizedNode, diffIndex1, differential.diffIndex1IsWheel, diffIndex2, differential.diffIndex2IsWheel, differential.torqueRatio, differential.maxSpeedRatio)
			end

			self:updateMotorProperties()
			controlVehicle(spec.motorizedNode, 0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
		end
	end

	return true
end

function Motorized:updateMotorProperties()
	local spec = self.spec_motorized
	local motor = spec.motor
	local torques, rotationSpeeds = motor:getTorqueAndSpeedValues()

	setMotorProperties(spec.motorizedNode, motor:getMinRpm() * math.pi / 30, motor:getMaxRpm() * math.pi / 30, motor:getRotInertia(), motor:getDampingRateFullThrottle(), motor:getDampingRateZeroThrottleClutchEngaged(), motor:getDampingRateZeroThrottleClutchDisengaged(), rotationSpeeds, torques)
end

function Motorized:getIsOperating(superFunc)
	return superFunc(self) or self:getIsMotorStarted()
end

function Motorized:getDeactivateOnLeave(superFunc)
	return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled
end

function Motorized:getDeactivateLightsOnLeave(superFunc)
	return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled
end

function Motorized:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_motorized

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_MOTOR_STATE, self, Motorized.actionEventToggleMotorState, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventText(actionEventId, spec.turnOnText)
		end
	end
end

function Motorized:onEnterVehicle(isControlling)
	if g_currentMission.missionInfo.automaticMotorStartEnabled and self:getCanMotorRun() then
		self:startMotor(true)
	end

	local samples = self.spec_motorized.samples

	if samples.compressedAir ~= nil then
		g_soundManager:playSample(samples.compressedAir, math.random(500, 2000))
	end
end

function Motorized:onLeaveVehicle()
	local spec = self.spec_motorized

	if self:getStopMotorOnLeave() and g_currentMission.missionInfo.automaticMotorStartEnabled then
		self:stopMotor(true)
	end

	if self.isServer and spec.motorizedNode ~= nil then
		controlVehicle(spec.motorizedNode, 0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
	end
end

function Motorized:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if fillLevelDelta > 0 and fillType == FillType.DIESEL then
		local factor = self:getFillUnitFillLevel(fillUnitIndex) / self:getFillUnitCapacity(fillUnitIndex)
		local defFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DEF)

		if defFillUnitIndex ~= nil then
			local delta = self:getFillUnitCapacity(defFillUnitIndex) * factor - self:getFillUnitFillLevel(defFillUnitIndex)

			self:addFillUnitFillLevel(self:getOwnerFarmId(), defFillUnitIndex, delta, FillType.DEF, ToolType.UNDEFINED, nil)
		end
	end
end

function Motorized:onAIEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:stopMotor(true)
	end
end

function Motorized:onSetBroken()
	self:stopMotor(true)
end

function Motorized:getName(superFunc)
	local name = superFunc(self)
	local item = g_storeManager:getItemByXMLFilename(self.configFileName)

	if item ~= nil and item.configurations ~= nil then
		local configId = self.configurations.motor
		local config = item.configurations.motor[configId]

		if config.name ~= "" then
			name = config.name
		end
	end

	return name
end

function Motorized:getCanBeSelected(superFunc)
	if not g_currentMission.missionInfo.automaticMotorStartEnabled then
		local vehicles = self:getRootVehicle():getChildVehicles()

		for _, vehicle in pairs(vehicles) do
			if vehicle.spec_motorized ~= nil then
				return true
			end
		end
	end

	return superFunc(self)
end

function Motorized:getDashboardSpeedDir()
	return self:getLastSpeed() * self.movingDirection
end

function Motorized:actionEventToggleMotorState(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() then
		local spec = self.spec_motorized

		if spec.isMotorStarted then
			self:stopMotor()
		elseif self:getCanMotorRun() then
			self:startMotor()
		else
			local warning = self:getMotorNotAllowedWarning()

			if warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		end
	end
end

function Motorized.getStoreAddtionalConfigData(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.power = getXMLInt(xmlFile, baseXMLName .. "#hp")
	configItem.maxSpeed = getXMLInt(xmlFile, baseXMLName .. "#maxSpeed")
	configItem.consumerConfigurationIndex = getXMLInt(xmlFile, baseXMLName .. "#consumerConfigurationIndex")
end

function Motorized.loadSpecValueFuel(xmlFile, customEnvironment)
	local rootName = getXMLRootName(xmlFile)
	local fillUnits = {}
	local i = 0

	while true do
		local configKey = string.format(rootName .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", i)

		if not hasXMLProperty(xmlFile, configKey) then
			break
		end

		local configFillUnits = {}
		local j = 0

		while true do
			local fillUnitKey = string.format(configKey .. ".fillUnits.fillUnit(%d)", j)

			if not hasXMLProperty(xmlFile, fillUnitKey) then
				break
			end

			local fillTypes = getXMLString(xmlFile, fillUnitKey .. "#fillTypes")
			local capacity = getXMLFloat(xmlFile, fillUnitKey .. "#capacity")

			table.insert(configFillUnits, {
				fillTypes = fillTypes,
				capacity = capacity
			})

			j = j + 1
		end

		table.insert(fillUnits, configFillUnits)

		i = i + 1
	end

	local consumers = {}
	i = 0

	while true do
		local key = string.format(rootName .. ".motorized.consumerConfigurations.consumerConfiguration(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local consumer = {}
		local j = 0

		while true do
			local consumerKey = string.format(key .. ".consumer(%d)", j)

			if not hasXMLProperty(xmlFile, consumerKey) then
				break
			end

			local fillType = getXMLString(xmlFile, consumerKey .. "#fillType")
			local fillUnitIndex = getXMLInt(xmlFile, consumerKey .. "#fillUnitIndex")

			table.insert(consumer, {
				fillType = fillType,
				fillUnitIndex = fillUnitIndex
			})

			j = j + 1
		end

		table.insert(consumers, consumer)

		i = i + 1
	end

	return {
		fillUnits = fillUnits,
		consumers = consumers
	}
end

function Motorized.getSpecValueFuel(storeItem, realItem)
	local consumerIndex = 1
	local motorConfigId = 1

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		motorConfigId = realItem.configurations.motor
		consumerIndex = Utils.getNoNil(storeItem.configurations.motor[motorConfigId].consumerConfigurationIndex, consumerIndex)
	end

	local fuel, def = nil
	local fuelFillUnitIndex = 0
	local defFillUnitIndex = 0
	local consumerConfiguration = storeItem.specs.fuel.consumers[consumerIndex]

	if consumerConfiguration ~= nil then
		for _, unitConsumers in ipairs(consumerConfiguration) do
			if g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType) == FillType.DIESEL then
				fuelFillUnitIndex = unitConsumers.fillUnitIndex
			end

			if g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType) == FillType.DEF then
				defFillUnitIndex = unitConsumers.fillUnitIndex
			end
		end
	end

	local fuelConfigIndex = 1

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil then
		fuelConfigIndex = realItem.configurations.fillUnit
	end

	if storeItem.specs.fuel.fillUnits[fuelConfigIndex] ~= nil then
		local fuelFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][fuelFillUnitIndex]

		if fuelFillUnit ~= nil then
			fuel = math.max(fuelFillUnit.capacity, fuel or 0)
		end

		local defFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][defFillUnitIndex]

		if defFillUnit ~= nil then
			def = math.max(defFillUnit.capacity, def or 0)
		end
	end

	if fuel ~= nil then
		if def ~= nil and def > 0 then
			return string.format(g_i18n:getText("shop_fuelDefValue"), fuel, g_i18n:getText("unit_literShort"), def, g_i18n:getText("unit_literShort"), g_i18n:getText("fillType_def_short"))
		else
			return string.format(g_i18n:getText("shop_fuelValue"), fuel, g_i18n:getText("unit_literShort"))
		end
	end

	return nil
end

function Motorized.loadSpecValueMaxSpeed(xmlFile, customEnvironment)
	local motorKey = nil

	if hasXMLProperty(xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration(0)") then
		motorKey = "vehicle.motorized.motorConfigurations.motorConfiguration(0).motor"
	elseif hasXMLProperty(xmlFile, "vehicle.motor") then
		motorKey = "vehicle.motor"
	end

	if motorKey ~= nil then
		local maxRpm = Utils.getNoNil(getXMLFloat(xmlFile, motorKey .. "#maxRpm"), 1800)
		local forwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, motorKey .. "#forwardGearRatio"), 2)
		local minForwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, motorKey .. "#minForwardGearRatio"), nil)
		local calculatedMaxSpeed = math.ceil(VehicleMotor.calculatePhysicalMaximumSpeed(minForwardGearRatio, {
			forwardGearRatio
		}, maxRpm) * 3.6)
		local storeDataMaxSpeed = getXMLInt(xmlFile, "vehicle.storeData.specs.maxSpeed")
		local maxSpeed = getXMLInt(xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration(0)#maxSpeed")
		local maxForwardSpeed = getXMLInt(xmlFile, motorKey .. "#maxForwardSpeed")

		if storeDataMaxSpeed ~= nil then
			return storeDataMaxSpeed
		elseif maxSpeed ~= nil then
			return maxSpeed
		elseif maxForwardSpeed ~= nil then
			return math.min(maxForwardSpeed, calculatedMaxSpeed)
		else
			return calculatedMaxSpeed
		end
	end

	return nil
end

function Motorized.getSpecValueMaxSpeed(storeItem, realItem)
	local maxSpeed = nil

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		local configId = realItem.configurations.motor
		maxSpeed = Utils.getNoNil(storeItem.configurations.motor[configId].maxSpeed, maxSpeed)
	end

	if maxSpeed == nil then
		maxSpeed = storeItem.specs.maxSpeed
	end

	if maxSpeed ~= nil then
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(maxSpeed)), g_i18n:getSpeedMeasuringUnit())
	end

	return nil
end

function Motorized.loadSpecValuePower(xmlFile, customEnvironment)
	return getXMLInt(xmlFile, "vehicle.storeData.specs.power")
end

function Motorized.getSpecValuePower(storeItem, realItem)
	local power = nil

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		local configId = realItem.configurations.motor
		power = Utils.getNoNil(storeItem.configurations.motor[configId].power, power)
	end

	if power == nil then
		power = storeItem.specs.power
	end

	if power ~= nil then
		local hp, kw = g_i18n:getPower(power)

		return string.format(g_i18n:getText("shop_maxPowerValue"), MathUtil.round(kw), MathUtil.round(hp))
	end

	return nil
end
