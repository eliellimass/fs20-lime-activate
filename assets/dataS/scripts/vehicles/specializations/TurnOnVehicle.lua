source("dataS/scripts/vehicles/specializations/events/SetTurnedOnEvent.lua")

TurnOnVehicle = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onTurnedOn")
		SpecializationUtil.registerEvent(vehicleType, "onTurnedOff")
	end
}

function TurnOnVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsTurnedOn", TurnOnVehicle.setIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOn", TurnOnVehicle.getIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeTurnedOn", TurnOnVehicle.getCanBeTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleTurnedOn", TurnOnVehicle.getCanToggleTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "getTurnedOnNotAllowedWarning", TurnOnVehicle.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOn", TurnOnVehicle.getAIRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getRequiresTurnOn", TurnOnVehicle.getRequiresTurnOn)
	SpecializationUtil.registerFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", TurnOnVehicle.getAIRequiresTurnOffOnHeadland)
end

function TurnOnVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", TurnOnVehicle.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", TurnOnVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TurnOnVehicle.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", TurnOnVehicle.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", TurnOnVehicle.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", TurnOnVehicle.getAlarmTriggerIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", TurnOnVehicle.loadAlarmTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFillUnitActive", TurnOnVehicle.getIsFillUnitActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", TurnOnVehicle.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", TurnOnVehicle.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSeedChangeAllowed", TurnOnVehicle.getIsSeedChangeAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TurnOnVehicle.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", TurnOnVehicle.getIsPowerTakeOffActive)
end

function TurnOnVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onAlarmTriggerChanged", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", TurnOnVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", TurnOnVehicle)
end

function TurnOnVehicle:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#turnOffText", "vehicle.turnOnVehicle#turnOffText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#turnOnText", "vehicle.turnOnVehicle#turnOnText")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#needsSelection")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#isAlwaysTurnedOn", "vehicle.turnOnVehicle#isAlwaysTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#toggleButton", "vehicle.turnOnVehicle#toggleButton")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#animationName", "vehicle.turnOnVehicle.turnedAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#turnOnSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnOnSettings#turnOffSpeedScale", "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.animationNodes.animationNode", "turnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.foldable.foldingParts#turnOffOnFold", "vehicle.turnOnVehicle#turnOffIfNotAllowed")

	local spec = self.spec_turnOnVehicle
	local turnOnButtonStr = getXMLString(self.xmlFile, "vehicle.turnOnVehicle#toggleButton")

	if turnOnButtonStr ~= nil then
		spec.toggleTurnOnInputBinding = InputAction[turnOnButtonStr]
	end

	spec.toggleTurnOnInputBinding = Utils.getNoNil(spec.toggleTurnOnInputBinding, InputAction.IMPLEMENT_EXTRA)
	spec.turnOffText = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.turnOnVehicle#turnOffText"), "action_turnOffOBJECT")
	spec.turnOnText = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.turnOnVehicle#turnOnText"), "action_turnOnOBJECT")
	spec.isTurnedOn = false
	spec.isAlwaysTurnedOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#isAlwaysTurnedOn"), false)
	spec.turnedOnByAttacherVehicle = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#turnedOnByAttacherVehicle"), false)
	spec.turnOffIfNotAllowed = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#turnOffIfNotAllowed"), false)
	spec.turnOffOnDeactivate = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#turnOffOnDeactivate"), not GS_IS_MOBILE_VERSION)
	spec.requiresMotorTurnOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#requiresMotorTurnOn"), not GS_IS_MOBILE_VERSION)
	spec.motorNotStartedWarning = string.format(g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.turnOnVehicle#motorNotStartedWarning"), "warning_motorNotStarted"), self.customEnvironment), self.typeDesc)
	spec.aiRequiresTurnOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#aiRequiresTurnOn"), true)
	spec.requiresTurnOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.turnOnVehicle#requiresTurnOn"), true)

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.turnOnVehicle.animationNodes", self.components, self, self.i3dMappings)
		local turnOnAnimation = getXMLString(self.xmlFile, "vehicle.turnOnVehicle.turnedAnimation#name")

		if turnOnAnimation ~= nil then
			spec.turnOnAnimation = {
				name = turnOnAnimation,
				turnOnSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.turnOnVehicle.turnedAnimation#turnOnSpeedScale"), 1)
			}
			spec.turnOnAnimation.turnOffSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.turnOnVehicle.turnedAnimation#turnOffSpeedScale"), -spec.turnOnAnimation.turnOnSpeedScale)
		end

		spec.turnedOnAnimations = {}
		local i = 0

		while true do
			local baseKey = string.format("vehicle.turnOnVehicle.turnedOnAnimation(%d)", i)

			if not hasXMLProperty(self.xmlFile, baseKey) then
				break
			end

			local entry = {}
			local name = getXMLString(self.xmlFile, baseKey .. "#name")

			if name ~= nil then
				entry.name = name
				entry.turnOnFadeTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#turnOnFadeTime"), 1) * 1000
				entry.turnOffFadeTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#turnOffFadeTime"), 1) * 1000
				entry.speedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#speedScale"), 1)
				entry.speedDirection = 0
				entry.currentSpeed = 0

				table.insert(spec.turnedOnAnimations, entry)
			end

			i = i + 1
		end

		spec.activatableFillUnits = {}
		local i = 0

		while true do
			local key = string.format("vehicle.turnOnVehicle.activatableFillUnits.activatableFillUnit(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local fillUnitIndex = getXMLInt(self.xmlFile, key .. "#index")

			if fillUnitIndex ~= nil then
				spec.activatableFillUnits[fillUnitIndex] = true
			end

			i = i + 1
		end

		spec.samples = {
			start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.turnOnVehicle.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function TurnOnVehicle:onPostLoad(savegame)
	if not SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
		TurnOnVehicle.registerControlledAction(self)
	end
end

function TurnOnVehicle:onDelete()
	if self.isClient then
		local spec = self.spec_turnOnVehicle

		g_soundManager:deleteSamples(spec.samples)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function TurnOnVehicle:onReadStream(streamId, connection)
	local turnedOn = streamReadBool(streamId)

	self:setIsTurnedOn(turnedOn, true)
end

function TurnOnVehicle:onWriteStream(streamId, connection)
	local spec = self.spec_turnOnVehicle

	streamWriteBool(streamId, spec.isTurnedOn)
end

function TurnOnVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_turnOnVehicle
	local isTurnedOn = self:getIsTurnedOn()

	if self.isClient and not spec.isAlwaysTurnedOn and not spec.turnedOnByAttacherVehicle and spec.actionEvents ~= nil then
		local actionEvent = spec.actionEvents[spec.toggleTurnOnInputBinding]

		if actionEvent ~= nil and actionEvent.actionEventId ~= nil then
			local state = self:getCanToggleTurnedOn()

			if state then
				local text = nil

				if isTurnedOn then
					text = string.format(g_i18n:getText("action_turnOffOBJECT"), self.typeDesc)
				else
					text = string.format(g_i18n:getText("action_turnOnOBJECT"), self.typeDesc)
				end

				g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)
		end
	end

	if self.isClient and self.playAnimation ~= nil then
		for _, animation in ipairs(spec.turnedOnAnimations) do
			if animation.speedDirection ~= 0 then
				local duration = animation.turnOnFadeTime

				if animation.speedDirection == -1 then
					duration = animation.turnOffFadeTime
				end

				animation.currentSpeed = MathUtil.clamp(animation.currentSpeed + animation.speedDirection * dt / duration, 0, 1)

				self:setAnimationSpeed(animation.name, animation.currentSpeed * animation.speedScale)

				if animation.speedDirection == -1 and animation.currentSpeed == 0 then
					self:stopAnimation(animation.name, true)
				end

				if animation.currentSpeed == 1 or animation.currentSpeed == 0 then
					animation.speedDirection = 0
				end
			end
		end
	end
end

function TurnOnVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_turnOnVehicle

		if spec.turnOffIfNotAllowed and not self:getCanBeTurnedOn() then
			if self:getIsTurnedOn() then
				self:setIsTurnedOn(false)
			elseif self.getAttacherVehicle ~= nil then
				local attacherVehicle = self:getAttacherVehicle()

				if attacherVehicle ~= nil and attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
					attacherVehicle:setIsTurnedOn(false)
				end
			end
		end
	end
end

function TurnOnVehicle:setIsTurnedOn(isTurnedOn, noEventSend)
	local spec = self.spec_turnOnVehicle

	if isTurnedOn ~= spec.isTurnedOn then
		SetTurnedOnEvent.sendEvent(self, isTurnedOn, noEventSend)

		spec.isTurnedOn = isTurnedOn
		local actionEvent = spec.actionEvents[InputAction.TOGGLE_COVER]
		local text = nil

		if spec.isTurnedOn then
			SpecializationUtil.raiseEvent(self, "onTurnedOn")

			text = string.format(g_i18n:getText(spec.turnOffText, self.customEnvironment), self.typeDesc)
		else
			SpecializationUtil.raiseEvent(self, "onTurnedOff")

			text = string.format(g_i18n:getText(spec.turnOnText, self.customEnvironment), self.typeDesc)
		end

		if actionEvent ~= nil then
			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function TurnOnVehicle:onTurnedOn()
	if self.isClient then
		local spec = self.spec_turnOnVehicle

		if self.playAnimation ~= nil then
			if spec.turnOnAnimation ~= nil then
				self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOnSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
			end

			for _, animation in ipairs(spec.turnedOnAnimations) do
				animation.speedDirection = 1

				self:playAnimation(animation.name, math.max(animation.currentSpeed * animation.speedScale, 0.001), self:getAnimationTime(animation.name), true)
			end
		end

		g_soundManager:stopSamples(spec.samples)
		g_soundManager:playSample(spec.samples.start)
		g_soundManager:playSample(spec.samples.work, 0, spec.samples.start)
		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function TurnOnVehicle:onTurnedOff()
	if self.isClient then
		local spec = self.spec_turnOnVehicle

		if self.playAnimation ~= nil then
			if spec.turnOnAnimation ~= nil then
				self:playAnimation(spec.turnOnAnimation.name, spec.turnOnAnimation.turnOffSpeedScale, self:getAnimationTime(spec.turnOnAnimation.name), true)
			end

			for _, animation in ipairs(spec.turnedOnAnimations) do
				animation.speedDirection = -1
			end
		end

		g_soundManager:stopSamples(spec.samples)
		g_soundManager:playSample(spec.samples.stop)
		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function TurnOnVehicle:getIsTurnedOn()
	local spec = self.spec_turnOnVehicle

	return spec.isAlwaysTurnedOn or spec.isTurnedOn
end

function TurnOnVehicle:getCanBeTurnedOn()
	local spec = self.spec_turnOnVehicle

	if spec.isAlwaysTurnedOn then
		return false
	end

	if self.getInputAttacherJoint ~= nil then
		local inputAttacherJoint = self:getInputAttacherJoint()

		if inputAttacherJoint ~= nil and inputAttacherJoint.canBeTurnedOn ~= nil and not inputAttacherJoint.canBeTurnedOn then
			return false
		end
	end

	if spec.requiresMotorTurnOn then
		if self.getIsMotorStarted ~= nil then
			return self:getIsMotorStarted()
		else
			local rootAttacherVehicle = self:getRootVehicle()

			if rootAttacherVehicle ~= self and rootAttacherVehicle.getIsMotorStarted ~= nil then
				return rootAttacherVehicle:getIsMotorStarted()
			end
		end
	end

	return true
end

function TurnOnVehicle:getCanToggleTurnedOn()
	local spec = self.spec_turnOnVehicle

	if spec.isAlwaysTurnedOn then
		return false
	end

	if spec.turnedOnByAttacherVehicle then
		return false
	end

	return true
end

function TurnOnVehicle:getTurnedOnNotAllowedWarning()
	local spec = self.spec_turnOnVehicle

	if spec.requiresMotorTurnOn then
		if self.getIsMotorStarted ~= nil then
			if not self:getIsMotorStarted() then
				return spec.motorNotStartedWarning
			end
		else
			local rootAttacherVehicle = self:getRootVehicle()

			if rootAttacherVehicle.getIsMotorStarted ~= nil and not rootAttacherVehicle:getIsMotorStarted() then
				return spec.motorNotStartedWarning
			end
		end
	end

	return nil
end

function TurnOnVehicle:getAIRequiresTurnOn()
	return self.spec_turnOnVehicle.aiRequiresTurnOn
end

function TurnOnVehicle:getRequiresTurnOn()
	return self.spec_turnOnVehicle.requiresTurnOn
end

function TurnOnVehicle:getAIRequiresTurnOffOnHeadland()
	return false
end

function TurnOnVehicle:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end

	inputAttacherJoint.canBeTurnedOn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canBeTurnedOn"), true)

	return true
end

function TurnOnVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)
	workArea.needsSetIsTurnedOn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsSetIsTurnedOn"), true)

	return retValue
end

function TurnOnVehicle:getIsWorkAreaActive(superFunc, workArea)
	if not self:getIsTurnedOn() and workArea.needsSetIsTurnedOn then
		return false
	end

	return superFunc(self, workArea)
end

function TurnOnVehicle:getCanAIImplementContinueWork(superFunc)
	local ret = false

	if self:getCanBeTurnedOn() and self:getIsTurnedOn() then
		ret = true
	end

	if not self:getAIRequiresTurnOn() then
		ret = true
	end

	if not self:getIsAIImplementInLine() then
		ret = true
	end

	return superFunc(self) and ret
end

function TurnOnVehicle:getIsOperating(superFunc)
	if self:getIsTurnedOn() then
		return true
	end

	return superFunc(self)
end

function TurnOnVehicle:getAlarmTriggerIsActive(superFunc, alarmTrigger)
	local ret = superFunc(self, alarmTrigger)

	if alarmTrigger.needsTurnOn and not self:getIsTurnedOn() then
		ret = false
	end

	return ret
end

function TurnOnVehicle:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
	local ret = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.needsTurnOn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsTurnOn"), false)
	alarmTrigger.turnOffInTrigger = Utils.getNoNil(getXMLBool(xmlFile, key .. "#turnOffInTrigger"), false)

	return ret
end

function TurnOnVehicle:getIsFillUnitActive(superFunc, fillUnitIndex)
	local spec = self.spec_turnOnVehicle

	if spec.activatableFillUnits[fillUnitIndex] == true and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, fillUnitIndex)
end

function TurnOnVehicle:loadShovelNode(superFunc, xmlFile, key, shovelNode)
	superFunc(self, xmlFile, key, shovelNode)

	shovelNode.needsActiveVehicle = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsActivation"), false)

	return true
end

function TurnOnVehicle:getShovelNodeIsActive(superFunc, shovelNode)
	if shovelNode.needsActiveVehicle and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, shovelNode)
end

function TurnOnVehicle:getIsSeedChangeAllowed(superFunc)
	return superFunc(self) and not self:getIsTurnedOn()
end

function TurnOnVehicle:getCanBeSelected(superFunc)
	return true
end

function TurnOnVehicle:getIsPowerTakeOffActive(superFunc)
	return self:getIsTurnedOn() or superFunc(self)
end

function TurnOnVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_turnOnVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and self:getCanToggleTurnedOn() then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.toggleTurnOnInputBinding, self, TurnOnVehicle.actionEventTurnOn, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		end
	end
end

function TurnOnVehicle:onAlarmTriggerChanged(alarmTrigger, state)
	if state and alarmTrigger.turnOffInTrigger then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onSetBroken()
	self:setIsTurnedOn(false, true)
end

function TurnOnVehicle:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_MOTOR_TURN_OFF and not self:getCanBeTurnedOn() then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onDeactivate()
	local spec = self.spec_turnOnVehicle

	if spec.turnOffOnDeactivate then
		self:setIsTurnedOn(false, true)
	end
end

function TurnOnVehicle:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_turnOnVehicle

	if spec.turnedOnByAttacherVehicle and attacherVehicle.getIsTurnedOn ~= nil then
		self:setIsTurnedOn(attacherVehicle:getIsTurnedOn(), true)
	end

	TurnOnVehicle.registerControlledAction(self)
end

function TurnOnVehicle:registerControlledAction()
	local spec = self.spec_turnOnVehicle
	spec.controlledAction = self:getRootVehicle().actionController:registerAction("turnOn", spec.toggleTurnOnInputBinding, 1)

	spec.controlledAction:setCallback(self, TurnOnVehicle.actionControllerTurnOnEvent)
	spec.controlledAction:setFinishedFunctions(self, self.getIsTurnedOn, true, false)

	if self:getRequiresTurnOn() then
		spec.controlledAction:setDeactivateFunction(self, self.getCanBeTurnedOn, true)
	end

	spec.controlledAction:setIsSaved(true)

	if self:getAIRequiresTurnOn() then
		spec.controlledAction:addAIEventListener(self, "onAIStart", 1, true)
		spec.controlledAction:addAIEventListener(self, "onAIImplementStart", 1, true)
		spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1, true)
		spec.controlledAction:addAIEventListener(self, "onAIImplementContinue", 1)
		spec.controlledAction:addAIEventListener(self, "onAIImplementEnd", -1)
		spec.controlledAction:addAIEventListener(self, "onAIEnd", -1)

		if self:getAIRequiresTurnOffOnHeadland() then
			spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
		end

		spec.controlledAction:addAIEventListener(self, "onAIImplementBlock", -1)
	end
end

function TurnOnVehicle:onPreDetach(attacherVehicle, implement)
	self:setIsTurnedOn(false, true)

	local spec = self.spec_turnOnVehicle

	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function TurnOnVehicle:actionControllerTurnOnEvent(direction)
	if direction > 0 then
		if self:getCanBeTurnedOn() then
			self:setIsTurnedOn(true)

			return true
		else
			return false
		end
	else
		self:setIsTurnedOn(false)

		return not self:getIsTurnedOn()
	end
end

function TurnOnVehicle:actionEventTurnOn(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleTurnedOn() and self:getCanBeTurnedOn() then
		self:setIsTurnedOn(not self:getIsTurnedOn())
	elseif not self:getIsTurnedOn() then
		local warning = self:getTurnedOnNotAllowedWarning()

		if warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	end
end
