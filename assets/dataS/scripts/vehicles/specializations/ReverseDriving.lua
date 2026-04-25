source("dataS/scripts/vehicles/specializations/events/ReverseDrivingSetStateEvent.lua")

ReverseDriving = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onStartReverseDirectionChange")
		SpecializationUtil.registerEvent(vehicleType, "onReverseDirectionChanged")
	end
}

function ReverseDriving.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "reverseDirectionChanged", ReverseDriving.reverseDirectionChanged)
	SpecializationUtil.registerFunction(vehicleType, "setIsReverseDriving", ReverseDriving.setIsReverseDriving)
end

function ReverseDriving.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateSteeringWheel", ReverseDriving.updateSteeringWheel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSteeringDirection", ReverseDriving.getSteeringDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCharacterVisibilityUpdate", ReverseDriving.getAllowCharacterVisibilityUpdate)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", ReverseDriving.getCanStartAIVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", ReverseDriving.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", ReverseDriving.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", ReverseDriving.getCanBeSelected)
end

function ReverseDriving.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", ReverseDriving)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ReverseDriving)
end

function ReverseDriving:onLoad(savegame)
	local spec = self.spec_reverseDriving

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseDriving.steering#reversedIndex", "vehicle.reverseDriving.steeringWheel#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseDriving.steering#reversedNode", "vehicle.reverseDriving.steeringWheel#node")

	spec.reversedCharacterTargets = {}

	IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.reverseDriving", self.components, spec.reversedCharacterTargets, self.i3dMappings)

	local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.reverseDriving.steeringWheel#node"), self.i3dMappings)

	if node ~= nil then
		spec.steeringWheel = {
			node = node
		}
		local _, ry, _ = getRotation(spec.steeringWheel.node)
		spec.steeringWheel.lastRotation = ry
		spec.steeringWheel.indoorRotation = math.rad(Utils.getNoNil(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.reverseDriving.steeringWheel#indoorRotation"), getXMLFloat(self.xmlFile, "vehicle.drivable.steeringWheel#indoorRotation")), 0))
		spec.steeringWheel.outdoorRotation = math.rad(Utils.getNoNil(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.reverseDriving.steeringWheel#outdoorRotation"), getXMLFloat(self.xmlFile, "vehicle.drivable.steeringWheel#outdoorRotation")), 0))
	end

	spec.reverseDrivingAnimation = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.reverseDriving#animationName"), "reverseDriving")

	if not self:getAnimationExists(spec.reverseDrivingAnimation) then
		g_logManager:xmlError(self.configFileName, "ReverseDriving requires a animation in 'vehicle.reverseDriving#animationName'!")
	end

	spec.isChangingDirection = false
	spec.isReverseDriving = false
	spec.isSelectable = true
	spec.smoothReverserDirection = 1
end

function ReverseDriving:onPostLoad(savegame)
	local spec = self.spec_reverseDriving
	local character = self:getVehicleCharacter()

	if character ~= nil then
		spec.defaultCharacterTargets = character:getIKChainTargets()
	end

	local isReverseDriving = false

	if savegame ~= nil then
		isReverseDriving = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. ".reverseDriving#isActive"), false)
	end

	self:setIsReverseDriving(isReverseDriving, true)

	spec.updateAnimationOnEnter = isReverseDriving
end

function ReverseDriving:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_reverseDriving

	setXMLBool(xmlFile, key .. "#isActive", spec.isReverseDriving)
end

function ReverseDriving:onReadStream(streamId, connection)
	self:setIsReverseDriving(Utils.getNoNil(streamReadBool(streamId), false))
end

function ReverseDriving:onWriteStream(streamId, connection)
	streamWriteBool(streamId, self.spec_reverseDriving.isReverseDriving)
end

function ReverseDriving:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_reverseDriving

	if spec.isChangingDirection then
		local character = self:getVehicleCharacter()

		if character ~= nil then
			character:setCharacterVisibility(false)
		end

		if not self:getIsEntered() and spec.updateAnimationOnEnter then
			AnimatedVehicle.updateAnimations(self, 99999999)

			spec.updateAnimationOnEnter = false
		end

		if not self:getIsAnimationPlaying(spec.reverseDrivingAnimation) then
			self:reverseDirectionChanged(spec.reverserDirection)
		end

		local direction = spec.isReverseDriving and 1 or -1
		spec.smoothReverserDirection = MathUtil.clamp(spec.smoothReverserDirection - 0.001 * dt * direction, -1, 1)
	end
end

function ReverseDriving:reverseDirectionChanged(direction)
	local spec = self.spec_reverseDriving
	spec.isChangingDirection = false

	if spec.isReverseDriving then
		self:setReverserDirection(-1)

		spec.smoothReverserDirection = -1
	else
		self:setReverserDirection(1)

		spec.smoothReverserDirection = 1
	end

	local character = self:getVehicleCharacter()

	if character ~= nil then
		if spec.isReverseDriving and next(spec.reversedCharacterTargets) ~= nil then
			character:setIKChainTargets(spec.reversedCharacterTargets)
		else
			character:setIKChainTargets(spec.defaultCharacterTargets)
		end

		if character.meshThirdPerson ~= nil and not self:getIsEntered() then
			character:updateVisibility()
		end

		character:setAllowCharacterUpdate(true)
	end

	if self.setLightsTypesMask ~= nil then
		self:setLightsTypesMask(self.spec_lights.lightsTypesMask, true, true)
	end

	SpecializationUtil.raiseEvent(self, "onReverseDirectionChanged", direction)
end

function ReverseDriving:setIsReverseDriving(isReverseDriving, noEventSend)
	local spec = self.spec_reverseDriving

	if isReverseDriving ~= spec.isReverseDriving then
		spec.isChangingDirection = true
		spec.isReverseDriving = isReverseDriving
		local dir = isReverseDriving and 1 or -1

		self:playAnimation(spec.reverseDrivingAnimation, dir, self:getAnimationTime(spec.reverseDrivingAnimation), true)

		local character = self:getVehicleCharacter()

		if character ~= nil then
			character:setAllowCharacterUpdate(false)
		end

		self:setReverserDirection(0)
		SpecializationUtil.raiseEvent(self, "onStartReverseDirectionChange")
		ReverseDrivingSetStateEvent.sendEvent(self, isReverseDriving, noEventSend)
	end
end

function ReverseDriving:updateSteeringWheel(superFunc, steeringWheel, dt, direction)
	local spec = self.spec_reverseDriving

	if spec.isReverseDriving then
		if spec.steeringWheel ~= nil then
			steeringWheel = spec.steeringWheel
		end

		direction = -direction
	end

	superFunc(self, steeringWheel, dt, direction)
end

function ReverseDriving:getSteeringDirection(superFunc)
	local spec = self.spec_reverseDriving

	if spec.reverseDrivingAnimation ~= nil then
		return spec.smoothReverserDirection
	end

	return superFunc(self)
end

function ReverseDriving:getAllowCharacterVisibilityUpdate(superFunc)
	return superFunc(self) and not self.spec_reverseDriving.isChangingDirection
end

function ReverseDriving:getCanStartAIVehicle(superFunc)
	local spec = self.spec_reverseDriving

	if spec.isReverseDriving then
		return false
	end

	if spec.isChangingDirection then
		return false
	end

	return superFunc(self)
end

function ReverseDriving:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	group.isReverseDriving = getXMLBool(xmlFile, key .. "#isReverseDriving")

	return true
end

function ReverseDriving:getIsDashboardGroupActive(superFunc, group)
	if group.isReverseDriving ~= nil and self.spec_reverseDriving.isReverseDriving ~= group.isReverseDriving then
		return false
	end

	return superFunc(self, group)
end

function ReverseDriving:getCanBeSelected(superFunc)
	return true
end

function ReverseDriving:onVehicleCharacterChanged(character)
	local spec = self.spec_reverseDriving

	if spec.updateAnimationOnEnter then
		AnimatedVehicle.updateAnimations(self, 99999999)

		spec.updateAnimationOnEnter = false
	end

	if spec.isReverseDriving and next(spec.reversedCharacterTargets) ~= nil then
		character:setIKChainTargets(spec.reversedCharacterTargets, true)
	else
		character:setIKChainTargets(spec.defaultCharacterTargets, true)
	end
end

function ReverseDriving:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_reverseDriving

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CHANGE_DRIVING_DIRECTION, self, ReverseDriving.actionEventToggleReverseDriving, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("input_CHANGE_DRIVING_DIRECTION"))
		end
	end
end

function ReverseDriving:actionEventToggleReverseDriving(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_reverseDriving

	self:setIsReverseDriving(not spec.isReverseDriving)
end
