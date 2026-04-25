AttacherJointControl = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Attachable, specializations)
	end
}

function AttacherJointControl.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJoint", AttacherJointControl.controlAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointHeight", AttacherJointControl.controlAttacherJointHeight)
	SpecializationUtil.registerFunction(vehicleType, "controlAttacherJointTilt", AttacherJointControl.controlAttacherJointTilt)
	SpecializationUtil.registerFunction(vehicleType, "getControlAttacherJointDirection", AttacherJointControl.getControlAttacherJointDirection)
end

function AttacherJointControl.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", AttacherJointControl.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", AttacherJointControl.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getLoweringActionEventState", AttacherJointControl.getLoweringActionEventState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", AttacherJointControl.getCanBeSelected)
end

function AttacherJointControl.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AttacherJointControl)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AttacherJointControl)
end

function AttacherJointControl:onLoad(savegame)
	local spec = self.spec_attacherJointControl

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attacherJointControl.control1", "vehicle.attacherJointControl.control with #controlFunction 'controlAttacherJointHeight'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attacherJointControl.control2", "vehicle.attacherJointControl.control with #controlFunction 'controlAttacherJointTilt'")

	local baseKey = "vehicle.attacherJointControl"
	spec.maxTiltAngle = Utils.getNoNilRad(getXMLFloat(self.xmlFile, baseKey .. "#maxTiltAngle"), math.rad(25))
	spec.heightTargetAlpha = -1
	spec.controls = {}
	spec.nameToControl = {}
	local i = 0

	while true do
		local key = string.format("%s.control(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local control = {}
		local controlFunc = getXMLString(self.xmlFile, key .. "#controlFunction")

		if controlFunc ~= nil and self[controlFunc] ~= nil then
			control.func = self[controlFunc]

			if control.func == self.controlAttacherJointHeight then
				spec.heightController = control
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown control function '%s' for attacher joint control '%s'", tostring(controlFunc), key)

			break
		end

		local actionBindingName = getXMLString(self.xmlFile, key .. "#controlAxis")

		if actionBindingName ~= nil and InputAction[actionBindingName] ~= nil then
			control.controlAction = InputAction[actionBindingName]
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown control axis '%s' for attacher joint control '%s'", tostring(actionBindingName), key)

			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#controlAxisIcon", key .. "#iconName")

		local iconName = getXMLString(self.xmlFile, key .. "#iconName") or ""

		if InputHelpElement.AXIS_ICON[iconName] == nil then
			iconName = (self.customEnvironment or "") .. iconName
		end

		control.axisActionIcon = iconName
		control.invertAxis = Utils.getNoNil(getXMLString(self.xmlFile, key .. "#invertControlAxis"), false)
		control.mouseSpeedFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#mouseSpeedFactor"), 1)
		control.moveAlpha = 0
		spec.nameToControl[actionBindingName] = control

		table.insert(spec.controls, control)

		i = i + 1
	end

	if self.isClient then
		spec.lastMoveTime = 0
		spec.samples = {
			hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.jointDesc = nil
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function AttacherJointControl:onDelete()
	if self.isClient then
		local spec = self.spec_attacherJointControl

		g_soundManager:deleteSample(spec.samples.hydraulic)
	end
end

function AttacherJointControl:onReadStream(streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_attacherJointControl

		for _, control in ipairs(spec.controls) do
			local moveAlpha = streamReadFloat32(streamId)

			self:controlAttacherJoint(control, moveAlpha)
		end
	end
end

function AttacherJointControl:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_attacherJointControl

		if streamWriteBool(streamId, spec.jointDesc ~= nil) then
			for _, control in ipairs(spec.controls) do
				streamWriteFloat32(streamId, control.moveAlpha)
			end
		end
	end
end

function AttacherJointControl:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_attacherJointControl

		for _, control in ipairs(spec.controls) do
			local moveAlpha = streamReadFloat32(streamId)

			self:controlAttacherJoint(control, moveAlpha)
		end
	end
end

function AttacherJointControl:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_attacherJointControl

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for _, control in ipairs(spec.controls) do
				streamWriteFloat32(streamId, control.moveAlpha)
			end
		end
	end
end

function AttacherJointControl:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJointControl
	local control = spec.heightController

	if control ~= nil and spec.jointDesc ~= nil and spec.heightTargetAlpha ~= -1 then
		local diff = spec.heightTargetAlpha - control.moveAlpha + 0.0001
		local moveTime = diff / (spec.jointDesc.upperAlpha - spec.jointDesc.lowerAlpha) * spec.jointDesc.moveTime
		local moveStep = dt / moveTime * diff

		if diff > 0 then
			moveStep = -moveStep
		end

		local newAlpha = control.moveAlpha + moveStep

		self:controlAttacherJoint(control, newAlpha)

		if math.abs(spec.heightTargetAlpha - newAlpha) < 0.01 then
			spec.heightTargetAlpha = -1
		end
	end

	if g_time < spec.lastMoveTime + 100 then
		if not g_soundManager:getIsSamplePlaying(spec.samples.hydraulic) then
			g_soundManager:playSample(spec.samples.hydraulic)
		end
	elseif g_soundManager:getIsSamplePlaying(spec.samples.hydraulic) then
		g_soundManager:stopSample(spec.samples.hydraulic)
	end
end

function AttacherJointControl:controlAttacherJoint(control, moveAlpha)
	local spec = self.spec_attacherJointControl
	local jointDesc = spec.jointDesc

	if jointDesc ~= nil then
		moveAlpha = control.func(self, moveAlpha)
		local attacherVehicle = self:getAttacherVehicle()

		attacherVehicle:updateAttacherJointRotation(jointDesc, self)

		if self.isServer and jointDesc.jointIndex ~= 0 then
			setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
		end
	end

	spec.lastMoveTime = g_time
	control.moveAlpha = moveAlpha

	self:raiseDirtyFlags(spec.dirtyFlag)
end

function AttacherJointControl:controlAttacherJointHeight(moveAlpha)
	local spec = self.spec_attacherJointControl
	local jointDesc = spec.jointDesc

	if moveAlpha == nil then
		moveAlpha = jointDesc.moveAlpha
	end

	moveAlpha = MathUtil.clamp(moveAlpha, jointDesc.upperAlpha, jointDesc.lowerAlpha)

	if jointDesc.rotationNode ~= nil then
		setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, moveAlpha))
	end

	if jointDesc.rotationNode2 ~= nil then
		setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, moveAlpha))
	end

	spec.lastHeightAlpha = moveAlpha

	return moveAlpha
end

function AttacherJointControl:controlAttacherJointTilt(moveAlpha)
	local spec = self.spec_attacherJointControl

	if moveAlpha == nil then
		moveAlpha = 0.5
	end

	moveAlpha = MathUtil.clamp(moveAlpha, 0, 1)
	local angle = spec.maxTiltAngle * -(moveAlpha - 0.5)
	spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup + angle
	spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup + angle

	return moveAlpha
end

function AttacherJointControl:getControlAttacherJointDirection()
	local spec = self.spec_attacherJointControl

	if spec.heightTargetAlpha ~= -1 then
		return spec.heightTargetAlpha == spec.jointDesc.upperAlpha
	end

	local lastAlpha = spec.heightController.moveAlpha

	return math.abs(lastAlpha - spec.jointDesc.upperAlpha) < math.abs(lastAlpha - spec.jointDesc.lowerAlpha)
end

function AttacherJointControl:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end

	inputAttacherJoint.isControllable = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isControllable"), false)

	return true
end

function AttacherJointControl:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	local spec = self.spec_attacherJointControl

	if spec.heightController then
		local _, actionEventId = self:addActionEvent(actionEventsTable, InputAction.LOWER_IMPLEMENT, self, AttacherJointControl.actionEventAttacherJointControlSetPoint, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)

		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

		if inputAction == InputAction.LOWER_IMPLEMENT then
			return
		end
	end

	superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function AttacherJointControl:getLoweringActionEventState(superFunc)
	local spec = self.spec_attacherJointControl

	if spec.heightController then
		local showText = spec.jointDesc ~= nil
		local text = nil

		if showText then
			if self:getControlAttacherJointDirection() then
				text = string.format(g_i18n:getText("action_lowerOBJECT"), self.typeDesc)
			else
				text = string.format(g_i18n:getText("action_liftOBJECT"), self.typeDesc)
			end
		end

		return showText, text
	end

	return superFunc(self)
end

function AttacherJointControl:getCanBeSelected(superFunc)
	return true
end

function AttacherJointControl:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_attacherJointControl

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInput and spec.jointDesc ~= nil then
			for _, control in ipairs(spec.controls) do
				local _, actionEventId = self:addActionEvent(spec.actionEvents, control.controlAction, self, AttacherJointControl.actionEventAttacherJointControl, false, false, true, true, nil, control.axisActionIcon)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			end
		end
	end
end

function AttacherJointControl:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_attacherJointControl
	local inputAttacherJoints = self:getInputAttacherJoints()

	if inputAttacherJoints[inputJointDescIndex] ~= nil and inputAttacherJoints[inputJointDescIndex].isControllable then
		local attacherJoints = attacherVehicle:getAttacherJoints()
		local jointDesc = attacherJoints[jointDescIndex]
		jointDesc.allowsLoweringBackup = jointDesc.allowsLowering
		jointDesc.allowsLowering = false
		jointDesc.upperRotationOffsetBackup = jointDesc.upperRotationOffset
		jointDesc.lowerRotationOffsetBackup = jointDesc.lowerRotationOffset
		spec.jointDesc = jointDesc

		for _, control in ipairs(spec.controls) do
			control.moveAlpha = control.func(self)
		end

		spec.heightTargetAlpha = spec.jointDesc.upperAlpha

		self:requestActionEventUpdate()
	end
end

function AttacherJointControl:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_attacherJointControl

	if spec.jointDesc ~= nil then
		spec.jointDesc.allowsLowering = spec.jointDesc.allowsLoweringBackup
		spec.jointDesc.upperRotationOffset = spec.jointDesc.upperRotationOffsetBackup
		spec.jointDesc.lowerRotationOffset = spec.jointDesc.lowerRotationOffsetBackup
		spec.jointDesc = nil
	end
end

function AttacherJointControl:actionEventAttacherJointControl(actionName, inputValue, callbackState, isAnalog)
	if math.abs(inputValue) > 0 then
		local spec = self.spec_attacherJointControl
		local control = spec.nameToControl[actionName]
		local changedAlpha = inputValue * control.mouseSpeedFactor * 0.025

		if control.invertAxis then
			changedAlpha = -changedAlpha
		end

		self:controlAttacherJoint(control, control.moveAlpha + changedAlpha)
	end
end

function AttacherJointControl:actionEventAttacherJointControlSetPoint(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_attacherJointControl

	if spec.jointDesc ~= nil then
		if self:getControlAttacherJointDirection() then
			spec.heightTargetAlpha = spec.jointDesc.lowerAlpha
		else
			spec.heightTargetAlpha = spec.jointDesc.upperAlpha
		end
	end
end
