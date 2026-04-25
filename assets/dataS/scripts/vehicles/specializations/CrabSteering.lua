source("dataS/scripts/vehicles/specializations/events/SetCrabSteeringEvent.lua")

CrabSteering = {
	STEERING_SEND_NUM_BITS = 3,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Wheels, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function CrabSteering.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setCrabSteering", CrabSteering.setCrabSteering)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngle", CrabSteering.updateSteeringAngle)
	SpecializationUtil.registerFunction(vehicleType, "updateArticulatedAxisRotation", CrabSteering.updateArticulatedAxisRotation)
end

function CrabSteering.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", CrabSteering.getCanBeSelected)
end

function CrabSteering.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CrabSteering)
end

function CrabSteering:onLoad(savegame)
	local spec = self.spec_crabSteering
	spec.state = 1
	spec.stateMax = -1
	spec.distFromCompJointToCenterOfBackWheels = getXMLFloat(self.xmlFile, "vehicle.crabSteering#distFromCompJointToCenterOfBackWheels")
	spec.aiSteeringModeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.crabSteering#aiSteeringModeIndex"), 1)
	spec.toggleSpeedFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.crabSteering#toggleSpeedFactor"), 1)
	spec.currentArticulatedAxisOffset = 0
	spec.articulatedAxisOffsetChanged = false
	spec.articulatedAxisLastAngle = 0
	spec.articulatedAxisChangingTime = 0
	local baseKey = "vehicle.crabSteering"
	spec.steeringModes = {}
	local i = 0

	while true do
		local key = string.format("%s.steeringMode(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {
			name = g_i18n:getText(getXMLString(self.xmlFile, key .. "#name"), self.customEnvironment)
		}
		local inputBindingName = getXMLString(self.xmlFile, key .. "#inputBindingName")

		if inputBindingName ~= nil then
			if InputAction[inputBindingName] ~= nil then
				entry.inputAction = InputAction[inputBindingName]
			else
				g_logManager:xmlWarning(self.configFileName, "Invalid inputBindingname '%s' for '%s'", tostring(inputBindingName), key)
			end
		end

		entry.wheels = {}
		local j = 0

		while true do
			local wheelKey = string.format("%s.wheel(%d)", key, j)

			if not hasXMLProperty(self.xmlFile, wheelKey) then
				break
			end

			local wheelEntry = {
				wheelIndex = getXMLInt(self.xmlFile, wheelKey .. "#index"),
				offset = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, wheelKey .. "#offset"), 0)),
				locked = Utils.getNoNil(getXMLBool(self.xmlFile, wheelKey .. "#locked"), false)
			}
			local wheels = self:getWheels()

			if wheels[wheelEntry.wheelIndex] ~= nil then
				wheels[wheelEntry.wheelIndex].steeringOffset = 0
				wheels[wheelEntry.wheelIndex].rotSpeedBackUp = wheels[wheelEntry.wheelIndex].rotSpeed
			else
				g_logManager:xmlError(self.configFileName, "Invalid wheelIndex '%s' for '%s'", tostring(wheelEntry.wheelIndex), wheelKey)
			end

			table.insert(entry.wheels, wheelEntry)

			j = j + 1
		end

		local specArticulatedAxis = self.spec_articulatedAxis

		if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
			entry.articulatedAxis = {
				rotSpeedBackUp = specArticulatedAxis.rotSpeed,
				offset = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. ".articulatedAxis#offset"), 0)),
				locked = Utils.getNoNil(getXMLBool(self.xmlFile, key .. ".articulatedAxis#locked"), false),
				wheelIndices = {
					StringUtil.getVectorFromString(getXMLString(self.xmlFile, key .. ".articulatedAxis#wheelIndices"))
				}
			}
		end

		entry.animations = {}
		j = 0

		while true do
			local animKey = string.format("%s.animation(%d)", key, j)

			if not hasXMLProperty(self.xmlFile, animKey) then
				break
			end

			local animName = getXMLString(self.xmlFile, animKey .. "#name")
			local animSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey .. "#speed"), 1)
			local stopTime = getXMLFloat(self.xmlFile, animKey .. "#stopTime")

			if animName ~= nil and self:getAnimationExists(animName) then
				table.insert(entry.animations, {
					animName = animName,
					animSpeed = animSpeed,
					stopTime = stopTime
				})
			else
				g_logManager:xmlWarning(self.configFileName, "Invalid animation '%s' for '%s'", tostring(animName), animKey)
			end

			j = j + 1
		end

		table.insert(spec.steeringModes, entry)

		i = i + 1
	end

	spec.stateMax = table.getn(spec.steeringModes)

	if spec.stateMax > 2^CrabSteering.STEERING_SEND_NUM_BITS - 1 then
		g_logManager:xmlError(self.configFileName, "CrabSteering only supports %d steering modes!", 2^CrabSteering.STEERING_SEND_NUM_BITS - 1)
	end

	if spec.stateMax > 0 then
		self:setCrabSteering(1, true)
	end
end

function CrabSteering:onReadStream(streamId, connection)
	local spec = self.spec_crabSteering

	if spec.stateMax == 0 then
		return
	end

	spec.state = streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS)
end

function CrabSteering:onWriteStream(streamId, connection)
	local spec = self.spec_crabSteering

	if spec.stateMax == 0 then
		return
	end

	streamWriteUIntN(streamId, spec.state, CrabSteering.STEERING_SEND_NUM_BITS)
end

function CrabSteering:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_crabSteering

	if spec.stateMax == 0 then
		return
	end

	local specArticulatedAxis = self.spec_articulatedAxis

	if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
		specArticulatedAxis.curRot = streamReadFloat32(streamId)
	end
end

function CrabSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_crabSteering

	if spec.stateMax == 0 then
		return
	end

	local specArticulatedAxis = self.spec_articulatedAxis

	if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
		streamWriteFloat32(streamId, specArticulatedAxis.curRot)
	end
end

function CrabSteering:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_crabSteering

	if spec.stateMax == 0 then
		return
	else
		local mode = spec.steeringModes[spec.state]

		g_currentMission:addExtraPrintText(string.format(g_i18n:getText("action_steeringModeSelected"), mode.name))
	end
end

function CrabSteering:setCrabSteering(state, noEventSend)
	local spec = self.spec_crabSteering

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCrabSteeringEvent:new(self, state), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetCrabSteeringEvent:new(self, state))
		end
	end

	if state ~= spec.state then
		local currentMode = spec.steeringModes[spec.state]

		if currentMode.animations ~= nil then
			for _, anim in pairs(currentMode.animations) do
				local curTime = self:getAnimationTime(anim.animName)

				if anim.stopTime == nil then
					self:playAnimation(anim.animName, -anim.animSpeed, curTime, noEventSend)
				end
			end
		end

		local newMode = spec.steeringModes[state]

		if newMode.animations ~= nil then
			for _, anim in pairs(newMode.animations) do
				local curTime = self:getAnimationTime(anim.animName)

				if anim.stopTime ~= nil then
					self:setAnimationStopTime(anim.animName, anim.stopTime)

					local speed = 1

					if anim.stopTime < curTime then
						speed = -1
					end

					self:playAnimation(anim.animName, speed, curTime, noEventSend)
				else
					self:playAnimation(anim.animName, anim.animSpeed, curTime, noEventSend)
				end
			end
		end
	end

	spec.state = state
end

function CrabSteering:updateSteeringAngle(wheel, dt, steeringAngle)
	local spec = self.spec_crabSteering
	local specWheels = self.spec_wheels
	local specDriveable = self.spec_drivable

	if spec.stateMax == 0 then
		return steeringAngle
	end

	local currentMode = spec.steeringModes[spec.state]

	if currentMode.wheels == nil or table.getn(currentMode.wheels) == 0 then
		return steeringAngle
	end

	for _, wheelProperties in pairs(currentMode.wheels) do
		if specWheels.wheels[wheelProperties.wheelIndex] == wheel then
			local rotScale = math.min(1 / (self.lastSpeed * specDriveable.speedRotScale + specDriveable.speedRotScaleOffset), 1)
			local delta = dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor

			if wheel.steeringOffset < wheelProperties.offset then
				wheel.steeringOffset = math.min(wheelProperties.offset, wheel.steeringOffset + delta)
			elseif wheelProperties.offset < wheel.steeringOffset then
				wheel.steeringOffset = math.max(wheelProperties.offset, wheel.steeringOffset - delta)
			end

			if not wheelProperties.locked then
				local rotSpeed = nil

				if self.rotatedTime > 0 then
					rotSpeed = (wheel.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration

					if wheel.rotSpeedBackUp < 0 then
						rotSpeed = (wheel.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
					end
				else
					rotSpeed = -(wheel.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration

					if wheel.rotSpeedBackUp < 0 then
						rotSpeed = -(wheel.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
					end
				end

				if wheel.rotSpeed < wheel.rotSpeedBackUp then
					wheel.rotSpeed = math.min(wheel.rotSpeedBackUp, wheel.rotSpeed + delta)
				elseif wheel.rotSpeedBackUp < wheel.rotSpeed then
					wheel.rotSpeed = math.max(wheel.rotSpeedBackUp, wheel.rotSpeed - delta)
				end

				local f = wheel.rotSpeed / wheel.rotSpeedBackUp
				steeringAngle = wheel.steeringOffset + self.rotatedTime * f * rotSpeed
			else
				if wheel.steeringOffset < wheel.steeringAngle or wheel.steeringOffset < steeringAngle then
					steeringAngle = math.max(wheel.steeringOffset, math.min(wheel.steeringAngle, steeringAngle) - delta)
				elseif wheel.steeringAngle < wheel.steeringOffset or steeringAngle < wheel.steeringOffset then
					steeringAngle = math.min(wheel.steeringOffset, math.max(wheel.steeringAngle, steeringAngle) + delta)
				end

				if steeringAngle == wheel.steeringOffset then
					wheel.rotSpeed = 0
				elseif wheel.rotSpeed < 0 then
					wheel.rotSpeed = math.min(0, wheel.rotSpeed + delta)
				elseif wheel.rotSpeed > 0 then
					wheel.rotSpeed = math.max(0, wheel.rotSpeed - delta)
				end
			end

			steeringAngle = MathUtil.clamp(steeringAngle, wheel.rotMin, wheel.rotMax)

			break
		end
	end

	return steeringAngle
end

function CrabSteering:updateArticulatedAxisRotation(steeringAngle, dt)
	local spec = self.spec_crabSteering
	local specArticulatedAxis = self.spec_articulatedAxis
	local specDriveable = self.spec_drivable

	if spec.stateMax == 0 then
		return steeringAngle
	end

	if not self.isServer then
		return specArticulatedAxis.curRot
	end

	local currentMode = spec.steeringModes[spec.state]

	if currentMode.articulatedAxis == nil then
		return steeringAngle
	end

	local rotScale = math.min(1 / (self.lastSpeed * specDriveable.speedRotScale + specDriveable.speedRotScaleOffset), 1)
	local delta = dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor

	if spec.currentArticulatedAxisOffset < currentMode.articulatedAxis.offset then
		spec.currentArticulatedAxisOffset = math.min(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset + delta)
	elseif currentMode.articulatedAxis.offset < spec.currentArticulatedAxisOffset then
		spec.currentArticulatedAxisOffset = math.max(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset - delta)
	end

	if currentMode.articulatedAxis.locked then
		if specArticulatedAxis.rotSpeed > 0 then
			specArticulatedAxis.rotSpeed = math.max(0, specArticulatedAxis.rotSpeed - delta)
		elseif specArticulatedAxis.rotSpeed < 0 then
			specArticulatedAxis.rotSpeed = math.min(0, specArticulatedAxis.rotSpeed + delta)
		end
	elseif currentMode.articulatedAxis.rotSpeedBackUp < specArticulatedAxis.rotSpeed then
		specArticulatedAxis.rotSpeed = math.max(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed - delta)
	elseif specArticulatedAxis.rotSpeed < currentMode.articulatedAxis.rotSpeedBackUp then
		specArticulatedAxis.rotSpeed = math.min(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed + delta)
	end

	local rotSpeed = nil

	if self.rotatedTime * currentMode.articulatedAxis.rotSpeedBackUp > 0 then
		rotSpeed = (specArticulatedAxis.rotMax - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	else
		rotSpeed = (specArticulatedAxis.rotMin - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	end

	local f = math.abs(specArticulatedAxis.rotSpeed) / math.abs(currentMode.articulatedAxis.rotSpeedBackUp)
	rotSpeed = rotSpeed * f
	steeringAngle = spec.currentArticulatedAxisOffset + math.abs(self.rotatedTime) * rotSpeed

	if table.getn(currentMode.articulatedAxis.wheelIndices) > 0 and spec.distFromCompJointToCenterOfBackWheels ~= nil and self.movingDirection >= 0 then
		local wheels = self:getWheels()
		local curRot = MathUtil.sign(currentMode.articulatedAxis.rotSpeedBackUp) * specArticulatedAxis.curRot
		local alpha = 0
		local count = 0

		for _, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do
			alpha = alpha + wheels[wheelIndex].steeringAngle
			count = count + 1
		end

		alpha = alpha / count
		alpha = alpha - curRot
		local v = 0
		count = 0

		for _, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do
			local wheel = wheels[wheelIndex]
			local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)

			if wheel.hasGroundContact then
				local longSlip, _ = getWheelShapeSlip(wheel.node, wheel.wheelShape)
				local fac = 1 - math.min(1, longSlip)
				v = v + fac * axleSpeed * wheel.radius
				count = count + 1
			end
		end

		v = v / count
		local h = v * 0.001 * dt
		local g = math.sin(alpha) * h
		local a = math.cos(alpha) * h
		local ls = spec.distFromCompJointToCenterOfBackWheels
		local beta = math.atan2(g, ls - a)
		steeringAngle = MathUtil.sign(currentMode.articulatedAxis.rotSpeedBackUp) * (curRot + beta)
		spec.articulatedAxisOffsetChanged = true
		spec.articulatedAxisLastAngle = steeringAngle
	else
		local changingTime = spec.articulatedAxisChangingTime

		if spec.articulatedAxisOffsetChanged then
			changingTime = 2500
			spec.articulatedAxisOffsetChanged = false
		end

		if changingTime > 0 then
			local pos = changingTime / 2500
			steeringAngle = steeringAngle * (1 - pos) + spec.articulatedAxisLastAngle * pos
			spec.articulatedAxisChangingTime = changingTime - dt
		end
	end

	steeringAngle = math.max(specArticulatedAxis.rotMin, math.min(specArticulatedAxis.rotMax, steeringAngle))

	return steeringAngle
end

function CrabSteering:getCanBeSelected(superFunc)
	return self.spec_crabSteering.stateMax > 0 or superFunc(self)
end

function CrabSteering:onAIImplementStart()
	local spec = self.spec_crabSteering

	if spec.stateMax > 0 then
		self:setCrabSteering(spec.aiSteeringModeIndex, true)
	end
end

function CrabSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_crabSteering

		if spec.stateMax > 0 then
			self:clearActionEventsTable(spec.actionEvents)

			if isActiveForInputIgnoreSelection then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CRABSTEERING, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

				for _, mode in pairs(spec.steeringModes) do
					if mode.inputAction ~= nil then
						_, actionEventId = self:addActionEvent(spec.actionEvents, mode.inputAction, self, CrabSteering.actionEventSetCrabSteeringMode, false, true, false, true, nil)

						g_inputBinding:setActionEventTextVisibility(actionEventId, false)
						g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					end
				end
			end
		end
	end
end

function CrabSteering:actionEventToggleCrabSteeringModes(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_crabSteering
	local state = spec.state
	state = state + 1

	if spec.stateMax < state then
		state = 1
	end

	if state ~= spec.state then
		self:setCrabSteering(state)
	end
end

function CrabSteering:actionEventSetCrabSteeringMode(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_crabSteering
	local state = spec.state

	for i, mode in pairs(spec.steeringModes) do
		if mode.inputAction == InputAction[actionName] then
			state = i

			break
		end
	end

	if state ~= spec.state then
		self:setCrabSteering(state)
	end
end
