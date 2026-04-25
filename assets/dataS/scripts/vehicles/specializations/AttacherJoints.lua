AttacherJoints = {
	MAX_ATTACH_DISTANCE_SQ = 1,
	MAX_ATTACH_ANGLE = 0.34202,
	NUM_JOINTTYPES = 0,
	jointTypeNameToInt = {},
	initSpecialization = function ()
		g_configurationManager:addConfigurationType("attacherJoint", g_i18n:getText("configuration_attacherJoint"), "attacherJoints", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
		Vehicle.registerStateChange("ATTACH")
		Vehicle.registerStateChange("DETACH")
		Vehicle.registerStateChange("LOWER_ALL_IMPLEMENTS")
	end
}

function AttacherJoints.registerJointType(name)
	local key = "JOINTTYPE_" .. string.upper(name)

	if AttacherJoints[key] == nil then
		AttacherJoints.NUM_JOINTTYPES = AttacherJoints.NUM_JOINTTYPES + 1
		AttacherJoints[key] = AttacherJoints.NUM_JOINTTYPES
		AttacherJoints.jointTypeNameToInt[name] = AttacherJoints.NUM_JOINTTYPES
	end
end

AttacherJoints.registerJointType("implement")
AttacherJoints.registerJointType("trailer")
AttacherJoints.registerJointType("trailerLow")
AttacherJoints.registerJointType("telehandler")
AttacherJoints.registerJointType("frontloader")
AttacherJoints.registerJointType("loaderFork")
AttacherJoints.registerJointType("semitrailer")
AttacherJoints.registerJointType("semitrailerHook")
AttacherJoints.registerJointType("attachableFrontloader")
AttacherJoints.registerJointType("wheelLoader")
AttacherJoints.registerJointType("manureBarrel")
AttacherJoints.registerJointType("cutter")
AttacherJoints.registerJointType("cutterHarvester")
AttacherJoints.registerJointType("cutterTrailer")
AttacherJoints.registerJointType("skidSteer")
AttacherJoints.registerJointType("conveyor")
AttacherJoints.registerJointType("hookLift")
AttacherJoints.registerJointType("train")

function AttacherJoints.prerequisitesPresent(specializations)
	return true
end

function AttacherJoints.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPreDetachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostDetachImplement")
end

function AttacherJoints.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "saveAttachmentsToXMLFile", AttacherJoints.saveAttachmentsToXMLFile)
	SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFromXMLFile", AttacherJoints.loadAttachmentsFromXMLFile)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementEvent", AttacherJoints.handleLowerImplementEvent)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementByAttacherJointIndex", AttacherJoints.handleLowerImplementByAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedImplements", AttacherJoints.getAttachedImplements)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJoints", AttacherJoints.getAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByJointDescIndex", AttacherJoints.getAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementFromAttacherJointIndex", AttacherJoints.getImplementFromAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromObject", AttacherJoints.getAttacherJointIndexFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointDescFromObject", AttacherJoints.getAttacherJointDescFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromImplementIndex", AttacherJoints.getAttacherJointIndexFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "getObjectFromImplementIndex", AttacherJoints.getObjectFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointGraphics", AttacherJoints.updateAttacherJointGraphics)
	SpecializationUtil.registerFunction(vehicleType, "calculateAttacherJointMoveUpperLowerAlpha", AttacherJoints.calculateAttacherJointMoveUpperLowerAlpha)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotation", AttacherJoints.updateAttacherJointRotation)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotationNodes", AttacherJoints.updateAttacherJointRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "attachImplementFromInfo", AttacherJoints.attachImplementFromInfo)
	SpecializationUtil.registerFunction(vehicleType, "attachImplement", AttacherJoints.attachImplement)
	SpecializationUtil.registerFunction(vehicleType, "postAttachImplement", AttacherJoints.postAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "createAttachmentJoint", AttacherJoints.createAttachmentJoint)
	SpecializationUtil.registerFunction(vehicleType, "hardAttachImplement", AttacherJoints.hardAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "hardDetachImplement", AttacherJoints.hardDetachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplement", AttacherJoints.detachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplementByObject", AttacherJoints.detachImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "playAttachSound", AttacherJoints.playAttachSound)
	SpecializationUtil.registerFunction(vehicleType, "playDetachSound", AttacherJoints.playDetachSound)
	SpecializationUtil.registerFunction(vehicleType, "detachingIsPossible", AttacherJoints.detachingIsPossible)
	SpecializationUtil.registerFunction(vehicleType, "attachAdditionalAttachment", AttacherJoints.attachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "detachAdditionalAttachment", AttacherJoints.detachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByJointDescIndex", AttacherJoints.getImplementIndexByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByJointDescIndex", AttacherJoints.getImplementByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByObject", AttacherJoints.getImplementIndexByObject)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByObject", AttacherJoints.getImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "callFunctionOnAllImplements", AttacherJoints.callFunctionOnAllImplements)
	SpecializationUtil.registerFunction(vehicleType, "activateAttachments", AttacherJoints.activateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachments", AttacherJoints.deactivateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachmentsLights", AttacherJoints.deactivateAttachmentsLights)
	SpecializationUtil.registerFunction(vehicleType, "setJointMoveDown", AttacherJoints.setJointMoveDown)
	SpecializationUtil.registerFunction(vehicleType, "getIsHardAttachAllowed", AttacherJoints.getIsHardAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointFromXML", AttacherJoints.loadAttacherJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedImplementByObject", AttacherJoints.setSelectedImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedImplement", AttacherJoints.getSelectedImplement)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAttach", AttacherJoints.getCanToggleAttach)
	SpecializationUtil.registerFunction(vehicleType, "getShowDetachAttachedImplement", AttacherJoints.getShowDetachAttachedImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachAttachedImplement", AttacherJoints.detachAttachedImplement)
	SpecializationUtil.registerFunction(vehicleType, "startAttacherJointCombo", AttacherJoints.startAttacherJointCombo)
	SpecializationUtil.registerFunction(vehicleType, "registerSelfLoweringActionEvent", AttacherJoints.registerSelfLoweringActionEvent)
end

function AttacherJoints.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "raiseActive", AttacherJoints.raiseActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerActionEvents", AttacherJoints.registerActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", AttacherJoints.removeActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJoints.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", AttacherJoints.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addChildVehicles", AttacherJoints.addChildVehicles)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAirConsumerUsage", AttacherJoints.getAirConsumerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AttacherJoints.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", AttacherJoints.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAICollisionTriggers", AttacherJoints.getAICollisionTriggers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", AttacherJoints.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddToolCameras", AttacherJoints.attachableAddToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveToolCameras", AttacherJoints.attachableRemoveToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelectableObjects", AttacherJoints.registerSelectableObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", AttacherJoints.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", AttacherJoints.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", AttacherJoints.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", AttacherJoints.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", AttacherJoints.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", AttacherJoints.getIsWheelFoliageDestructionAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AttacherJoints.getAreControlledActionsAllowed)
end

function AttacherJoints.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLightsTypesMaskChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnLightStateChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrakeLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrake", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", AttacherJoints)
end

function AttacherJoints:onLoad(savegame)
	local spec = self.spec_attacherJoints
	spec.attacherJointCombos = {
		duration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.attacherJoints#comboDuration"), 2) * 1000,
		currentTime = 0,
		direction = -1,
		isRunning = false,
		joints = {}
	}
	spec.attacherJoints = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local attacherJoint = {}

		if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
			table.insert(spec.attacherJoints, attacherJoint)

			attacherJoint.index = #spec.attacherJoints
		end

		i = i + 1
	end

	if self.configurations.attacherJoint ~= nil then
		local attacherConfigs = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		local i = 0

		while true do
			local baseName = string.format(attacherConfigs .. ".attacherJoint(%d)", i)

			if not hasXMLProperty(self.xmlFile, baseName) then
				break
			end

			local attacherJoint = {}

			if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
				table.insert(spec.attacherJoints, attacherJoint)
			end

			i = i + 1
		end

		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration", self.configurations.attacherJoint, self.components, self)
	end

	spec.attachedImplements = {}
	spec.selectedImplement = nil
	spec.attachableInfo = {
		attacherVehicle = nil,
		attacherVehicleJointDescIndex = nil,
		attachable = nil,
		attachableJointDescIndex = nil
	}

	if self.isClient then
		spec.samples = {}
		spec.isHydraulicSamplePlaying = false
		spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.attach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "attach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	if self.isClient and g_isDevelopmentVersion then
		for k, attacherJoint in ipairs(spec.attacherJoints) do
			if spec.samples.attach == nil and attacherJoint.sampleAttach == nil then
				g_logManager:xmlDevWarning(self.configFileName, "Missing attach sound for attacherjoint '%d'", k)
			end

			if attacherJoint.rotationNode ~= nil and spec.samples.hydraulic == nil then
				g_logManager:xmlDevWarning(self.configFileName, "Missing hydraulic sound for attacherjoint '%d'", k)
			end
		end
	end

	spec.showAttachNotAllowedText = 0
	spec.wasInAttachRange = false
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function AttacherJoints:onPostLoad(savegame)
	local spec = self.spec_attacherJoints

	for _, attacherJoint in pairs(spec.attacherJoints) do
		attacherJoint.jointOrigRot = {
			getRotation(attacherJoint.jointTransform)
		}
		attacherJoint.jointOrigTrans = {
			getTranslation(attacherJoint.jointTransform)
		}

		if attacherJoint.transNode ~= nil then
			attacherJoint.transNodeMinY = Utils.getNoNil(attacherJoint.transNodeMinY, attacherJoint.jointOrigTrans[2])
			attacherJoint.transNodeMaxY = Utils.getNoNil(attacherJoint.transNodeMaxY, attacherJoint.jointOrigTrans[2])
			_, attacherJoint.transNodeOffsetY, _ = localToLocal(attacherJoint.jointTransform, attacherJoint.transNode, 0, 0, 0)
			_, attacherJoint.transNodeMinY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMinY, 0)
			_, attacherJoint.transNodeMaxY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMaxY, 0)
		end

		if attacherJoint.bottomArm ~= nil then
			setRotation(attacherJoint.bottomArm.rotationNode, attacherJoint.bottomArm.rotX, attacherJoint.bottomArm.rotY, attacherJoint.bottomArm.rotZ)

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(attacherJoint.bottomArm.rotationNode)
			end
		end

		if attacherJoint.rotationNode ~= nil then
			setRotation(attacherJoint.rotationNode, attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ)
		end
	end

	if savegame ~= nil and not savegame.resetVehicles and spec.attacherJointCombos ~= nil then
		local comboDirection = getXMLInt(savegame.xmlFile, savegame.key .. ".attacherJoints#comboDirection")

		if comboDirection ~= nil then
			spec.attacherJointCombos.direction = comboDirection

			if comboDirection == 1 then
				spec.attacherJointCombos.currentTime = spec.attacherJointCombos.duration
			end
		end
	end
end

function AttacherJoints:onPreDelete()
	local spec = self.spec_attacherJoints

	for i = table.getn(spec.attachedImplements), 1, -1 do
		self:detachImplement(1, true)
	end
end

function AttacherJoints:onDelete()
	local spec = self.spec_attacherJoints

	if self.isClient then
		for _, jointDesc in pairs(spec.attacherJoints) do
			g_soundManager:deleteSample(jointDesc.sampleAttach)
		end

		g_soundManager:deleteSample(spec.samples.hydraulic)
		g_soundManager:deleteSample(spec.samples.attach)
	end
end

function AttacherJoints:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_attacherJoints

	if spec.attacherJointCombos ~= nil then
		setXMLInt(xmlFile, key .. "#comboDirection", spec.attacherJointCombos.direction)
	end
end

function AttacherJoints:saveAttachmentsToXMLFile(xmlFile, key, vehiclesToId)
	local spec = self.spec_attacherJoints
	local added = false
	local id = vehiclesToId[self]

	if id ~= nil then
		local i = 0

		for _, implement in ipairs(spec.attachedImplements) do
			local object = implement.object

			if object ~= nil and vehiclesToId[object] ~= nil then
				local attachmentKey = string.format("%s.attachment(%d)", key, i)
				local jointDescIndex = implement.jointDescIndex
				local jointDesc = spec.attacherJoints[jointDescIndex]
				local inputJointDescIndex = object:getActiveInputAttacherJointDescIndex()

				setXMLInt(xmlFile, attachmentKey .. "#attachmentId", vehiclesToId[object])
				setXMLInt(xmlFile, attachmentKey .. "#inputJointDescIndex", inputJointDescIndex)
				setXMLInt(xmlFile, attachmentKey .. "#jointIndex", jointDescIndex)
				setXMLBool(xmlFile, attachmentKey .. "#moveDown", jointDesc.moveDown)

				added = true
				i = i + 1
			end
		end

		if added then
			setXMLInt(xmlFile, key .. "#rootVehicleId", id)
		end
	end

	return added
end

function AttacherJoints:onReadStream(streamId, connection)
	local numImplements = streamReadInt8(streamId)

	for i = 1, numImplements do
		local object = NetworkUtil.readNodeObject(streamId)
		local inputJointDescIndex = streamReadInt8(streamId)
		local jointDescIndex = streamReadInt8(streamId)
		local moveDown = streamReadBool(streamId)

		if object ~= nil then
			self:attachImplement(object, inputJointDescIndex, jointDescIndex, true, i)
			self:setJointMoveDown(jointDescIndex, moveDown, true)
		end
	end
end

function AttacherJoints:onWriteStream(streamId, connection)
	local spec = self.spec_attacherJoints

	streamWriteInt8(streamId, table.getn(spec.attachedImplements))

	for i = 1, table.getn(spec.attachedImplements) do
		local implement = spec.attachedImplements[i]
		local inputJointDescIndex = implement.object.spec_attachable.inputAttacherJointDescIndex
		local jointDescIndex = implement.jointDescIndex
		local jointDesc = spec.attacherJoints[jointDescIndex]
		local moveDown = jointDesc.moveDown

		NetworkUtil.writeNodeObject(streamId, implement.object)
		streamWriteInt8(streamId, inputJointDescIndex)
		streamWriteInt8(streamId, jointDescIndex)
		streamWriteBool(streamId, moveDown)
	end
end

function AttacherJoints:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil and (self.isServer or self.updateLoopIndex == implement.object.updateLoopIndex) then
			self:updateAttacherJointGraphics(implement, dt)
		end
	end

	if not self.isServer and self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil and self.updateLoopIndex == attacherVehicle.updateLoopIndex then
			local implement = attacherVehicle:getImplementByObject(self)

			if implement ~= nil then
				attacherVehicle:updateAttacherJointGraphics(implement, dt)
			end
		end
	end

	if self.isClient then
		spec.showAttachNotAllowedText = math.max(spec.showAttachNotAllowedText - dt, 0)

		if spec.showAttachNotAllowedText > 0 then
			g_currentMission:addExtraPrintText(g_i18n:getText("info_attach_not_allowed"))
		end
	end
end

function AttacherJoints:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if not implement.attachingIsInProgress then
			local attacherJoint = implement.object:getActiveInputAttacherJoint()

			if attacherJoint ~= nil then
				if spec.attacherJoints[implement.jointDescIndex].steeringBarLeftNode ~= nil and attacherJoint.steeringBarLeftMovingPart ~= nil then
					Cylindered.updateMovingPart(self, attacherJoint.steeringBarLeftMovingPart, nil, true)
				end

				if spec.attacherJoints[implement.jointDescIndex].steeringBarRightNode ~= nil and attacherJoint.steeringBarRightMovingPart ~= nil then
					Cylindered.updateMovingPart(self, attacherJoint.steeringBarRightMovingPart, nil, true)
				end
			end
		end
	end
end

function AttacherJoints:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints
	local playHydraulicSound = false

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			local jointDesc = spec.attacherJoints[implement.jointDescIndex]

			if not implement.object.isHardAttached then
				if self.isServer and implement.attachingIsInProgress then
					local done = true

					for i = 1, 3 do
						local lastRotLimit = implement.attachingRotLimit[i]
						local lastTransLimit = implement.attachingTransLimit[i]
						implement.attachingRotLimit[i] = math.max(0, implement.attachingRotLimit[i] - implement.attachingRotLimitSpeed[i] * dt)
						implement.attachingTransLimit[i] = math.max(0, implement.attachingTransLimit[i] - implement.attachingTransLimitSpeed[i] * dt)

						if implement.attachingRotLimit[i] > 0 or implement.attachingTransLimit[i] > 0 or lastRotLimit > 0 or lastTransLimit > 0 then
							done = false
						end
					end

					implement.attachingIsInProgress = not done

					if done then
						if implement.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(implement.jointDescIndex) then
							self:hardAttachImplement(implement)
						end

						self:postAttachImplement(implement)
					end
				end

				if not implement.attachingIsInProgress then
					local jointFrameInvalid = false

					if jointDesc.allowsLowering then
						local moveAlpha = Utils.getMovedLimitedValue(jointDesc.moveAlpha, jointDesc.lowerAlpha, jointDesc.upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)

						if moveAlpha ~= jointDesc.moveAlpha then
							playHydraulicSound = true
							jointDesc.moveAlpha = moveAlpha
							jointDesc.moveLimitAlpha = 1 - (moveAlpha - jointDesc.lowerAlpha) / (jointDesc.upperAlpha - jointDesc.lowerAlpha)
							jointFrameInvalid = true

							self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
							self:updateAttacherJointRotation(jointDesc, implement.object)
						end
					end

					jointFrameInvalid = jointFrameInvalid or jointDesc.jointFrameInvalid

					if jointFrameInvalid then
						jointDesc.jointFrameInvalid = false

						if self.isServer then
							setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
						end
					end
				end

				if self.isServer then
					local force = implement.attachingIsInProgress

					if (force or jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement) and jointDesc.jointIndex ~= nil and jointDesc.jointIndex ~= 0 then
						if force or implement.object.spec_attachable.attacherJoint.allowsJointRotLimitMovement then
							for i = 1, 3 do
								local newRotLimit = MathUtil.lerp(math.max(implement.attachingRotLimit[i], implement.upperRotLimit[i]), math.max(implement.attachingRotLimit[i], implement.lowerRotLimit[i]), jointDesc.moveLimitAlpha)

								if force or math.abs(newRotLimit - implement.jointRotLimit[i]) > 0.0005 then
									local rotLimitDown = -newRotLimit
									local rotLimitUp = newRotLimit

									if i == 3 then
										if jointDesc.lockDownRotLimit then
											rotLimitDown = math.min(-implement.attachingRotLimit[i], 0)
										end

										if jointDesc.lockUpRotLimit then
											rotLimitUp = math.max(implement.attachingRotLimit[i], 0)
										end
									end

									setJointRotationLimit(jointDesc.jointIndex, i - 1, true, rotLimitDown, rotLimitUp)

									implement.jointRotLimit[i] = newRotLimit
								end
							end
						end

						if force or implement.object.spec_attachable.attacherJoint.allowsJointTransLimitMovement then
							for i = 1, 3 do
								local newTransLimit = MathUtil.lerp(math.max(implement.attachingTransLimit[i], implement.upperTransLimit[i]), math.max(implement.attachingTransLimit[i], implement.lowerTransLimit[i]), jointDesc.moveLimitAlpha)

								if force or math.abs(newTransLimit - implement.jointTransLimit[i]) > 0.0005 then
									local transLimitDown = -newTransLimit
									local transLimitUp = newTransLimit

									if i == 2 then
										if jointDesc.lockDownTransLimit then
											transLimitDown = math.min(-implement.attachingTransLimit[i], 0)
										end

										if jointDesc.lockUpTransLimit then
											transLimitUp = math.max(implement.attachingTransLimit[i], 0)
										end
									end

									setJointTranslationLimit(jointDesc.jointIndex, i - 1, true, transLimitDown, transLimitUp)

									implement.jointTransLimit[i] = newTransLimit
								end
							end
						end
					end
				end
			end
		end
	end

	if self.isClient and spec.samples.hydraulic ~= nil then
		if playHydraulicSound then
			if not spec.isHydraulicSamplePlaying then
				g_soundManager:playSample(spec.samples.hydraulic)

				spec.isHydraulicSamplePlaying = true
			end
		elseif spec.isHydraulicSamplePlaying then
			g_soundManager:stopSample(spec.samples.hydraulic)

			spec.isHydraulicSamplePlaying = false
		end
	end

	local combos = spec.attacherJointCombos

	if combos ~= nil and combos.isRunning then
		for _, joint in pairs(combos.joints) do
			local doLowering = nil

			if combos.direction == 1 and joint.time <= combos.currentTime then
				doLowering = true
			elseif combos.direction == -1 and combos.currentTime <= combos.duration - joint.time then
				doLowering = false
			end

			if doLowering ~= nil then
				local implement = self:getImplementFromAttacherJointIndex(joint.jointIndex)

				if implement ~= nil and implement.object.setLoweredAll ~= nil then
					implement.object:setLoweredAll(doLowering, joint.jointIndex)
				end
			end
		end

		if combos.direction == -1 and combos.currentTime == 0 or combos.direction == 1 and combos.currentTime == combos.duration then
			combos.isRunning = false
		end

		combos.currentTime = MathUtil.clamp(combos.currentTime + dt * combos.direction, 0, combos.duration)
	end

	local info = spec.attachableInfo
	info.attacherVehicle = nil

	if self.isClient and spec.actionEvents ~= nil then
		local attachActionEvent = spec.actionEvents[InputAction.ATTACH]

		if attachActionEvent ~= nil then
			local visible = false

			if self:getCanToggleAttach() then
				info.attacherVehicle, info.attacherVehicleJointDescIndex, info.attachable, info.attachableJointDescIndex = AttacherJoints.findVehicleInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE)
				local text = ""
				local prio = GS_PRIO_VERY_LOW
				local selectedVehicle = self:getSelectedVehicle()

				if selectedVehicle ~= nil and not selectedVehicle.isDeleted and selectedVehicle.isDetachAllowed ~= nil and selectedVehicle:isDetachAllowed() and selectedVehicle:getAttacherVehicle() ~= nil then
					visible = true
					text = g_i18n:getText("action_detach")
				end

				if info.attacherVehicle ~= nil then
					if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), info.attachable) then
						visible = true
						text = g_i18n:getText("action_attach")

						g_currentMission:showAttachContext(info.attachable)

						prio = GS_PRIO_VERY_HIGH
					else
						spec.showAttachNotAllowedText = 100
					end
				end

				g_inputBinding:setActionEventText(attachActionEvent.actionEventId, text)
				g_inputBinding:setActionEventTextPriority(attachActionEvent.actionEventId, prio)
			end

			g_inputBinding:setActionEventTextVisibility(attachActionEvent.actionEventId, visible)
		end

		local lowerActionEvent = spec.actionEvents[InputAction.LOWER_IMPLEMENT]

		if lowerActionEvent ~= nil then
			local showLower = false
			local text = ""
			local selectedImplement = self:getSelectedImplement()

			for _, attachedImplement in pairs(spec.attachedImplements) do
				if attachedImplement == selectedImplement then
					showLower, text = attachedImplement.object:getLoweringActionEventState()

					break
				end
			end

			g_inputBinding:setActionEventActive(lowerActionEvent.actionEventId, showLower)
			g_inputBinding:setActionEventText(lowerActionEvent.actionEventId, text)
			g_inputBinding:setActionEventTextPriority(lowerActionEvent.actionEventId, GS_PRIO_NORMAL)
		end
	end

	if g_platformSettingsManager:getSetting("automaticAttach", false) then
		info.attacherVehicle = nil

		if self.isServer and self:getCanToggleAttach() then
			info.attacherVehicle, info.attacherVehicleJointDescIndex, info.attachable, info.attachableJointDescIndex = AttacherJoints.findVehicleInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE)

			if info.attachable ~= nil and not spec.wasInAttachRange and info.attacherVehicle == self then
				local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)

				if attachAllowed then
					if spec.wasInAttachRange == nil then
						spec.wasInAttachRange = true
					else
						self:attachImplementFromInfo(info)
					end
				elseif warning ~= nil then
					g_currentMission:showBlinkingWarning(warning, 2000)
				end
			elseif info.attachable == nil and spec.wasInAttachRange then
				spec.wasInAttachRange = false
			end
		end
	end
end

function AttacherJoints:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints

	if self == g_currentMission.controlledVehicle then
		for _, implement in ipairs(spec.attachedImplements) do
			local object = implement.object

			if object ~= nil and object.draw ~= nil then
				object:draw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
			end
		end
	end
end

function AttacherJoints:loadAttachmentsFromXMLFile(xmlFile, key, idsToVehicle)
	local spec = self.spec_attacherJoints
	local i = 0

	while true do
		local attachmentKey = string.format("%s.attachment(%d)", key, i)

		if not hasXMLProperty(xmlFile, attachmentKey) then
			break
		end

		local attachmentId = getXMLString(xmlFile, attachmentKey .. "#attachmentId")
		local jointIndex = getXMLInt(xmlFile, attachmentKey .. "#jointIndex")
		local inputJointDescIndex = Utils.getNoNil(getXMLInt(xmlFile, attachmentKey .. "#inputJointDescIndex"), 1)

		if attachmentId ~= nil and jointIndex ~= nil then
			local attachment = idsToVehicle[attachmentId]
			local inputAttacherJoints = nil

			if attachment ~= nil and attachment.getInputAttacherJoints ~= nil then
				inputAttacherJoints = attachment:getInputAttacherJoints()
			end

			local inputAttacherJoint = nil

			if inputAttacherJoints ~= nil then
				inputAttacherJoint = inputAttacherJoints[inputJointDescIndex]
			end

			if inputAttacherJoint ~= nil and spec.attacherJoints[jointIndex] ~= nil and spec.attacherJoints[jointIndex].jointIndex == 0 then
				local moveDown = getXMLBool(xmlFile, attachmentKey .. "#moveDown")

				self:attachImplement(attachment, inputJointDescIndex, jointIndex, true, nil, moveDown, true, true)

				if moveDown ~= nil then
					self:setJointMoveDown(jointIndex, moveDown, true)
				end
			end
		end

		i = i + 1
	end
end

function AttacherJoints:handleLowerImplementEvent()
	local implement = self:getImplementByObject(self:getSelectedVehicle())

	if implement ~= nil then
		local object = implement.object

		if object ~= nil and object.getAttacherVehicle ~= nil then
			local attacherVehicle = object:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)

				attacherVehicle:handleLowerImplementByAttacherJointIndex(attacherJointIndex)
			end
		end
	end
end

function AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
	if attacherJointIndex ~= nil then
		local implement = self:getImplementByJointDescIndex(attacherJointIndex)

		if implement ~= nil then
			local object = implement.object
			local attacherJoints = self:getAttacherJoints()
			local attacherJoint = attacherJoints[attacherJointIndex]
			local allowsLowering, warning = object:getAllowsLowering()

			if allowsLowering and attacherJoint.allowsLowering then
				if direction == nil then
					direction = not attacherJoint.moveDown
				end

				self:setJointMoveDown(implement.jointDescIndex, direction, false)
			elseif not allowsLowering and warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		end
	end
end

function AttacherJoints:getAttachedImplements()
	return self.spec_attacherJoints.attachedImplements
end

function AttacherJoints:getAttacherJoints()
	return self.spec_attacherJoints.attacherJoints
end

function AttacherJoints:getAttacherJointByJointDescIndex(jointDescIndex)
	return self.spec_attacherJoints.attacherJoints[jointDescIndex]
end

function AttacherJoints:getImplementFromAttacherJointIndex(attacherJointIndex)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.jointDescIndex == attacherJointIndex then
			return attachedImplement
		end
	end
end

function AttacherJoints:getAttacherJointIndexFromObject(object)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.object == object then
			return attachedImplement.jointDescIndex
		end
	end
end

function AttacherJoints:getAttacherJointDescFromObject(object)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.object == object then
			return spec.attacherJoints[attachedImplement.jointDescIndex]
		end
	end
end

function AttacherJoints:getAttacherJointIndexFromImplementIndex(implementIndex)
	local spec = self.spec_attacherJoints
	local attachedImplement = spec.attachedImplements[implementIndex]

	if attachedImplement ~= nil then
		return attachedImplement.jointDescIndex
	end

	return nil
end

function AttacherJoints:getObjectFromImplementIndex(implementIndex)
	local spec = self.spec_attacherJoints
	local attachedImplement = spec.attachedImplements[implementIndex]

	if attachedImplement ~= nil then
		return attachedImplement.object
	end

	return nil
end

function AttacherJoints:updateAttacherJointGraphics(implement, dt)
	local spec = self.spec_attacherJoints

	if implement.object ~= nil then
		local jointDesc = spec.attacherJoints[implement.jointDescIndex]
		local attacherJoint = implement.object:getActiveInputAttacherJoint()

		if jointDesc.topArm ~= nil and attacherJoint.topReferenceNode ~= nil then
			local ax, ay, az = getWorldTranslation(jointDesc.topArm.rotationNode)
			local bx, by, bz = getWorldTranslation(attacherJoint.topReferenceNode)
			local x, y, z = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), bx - ax, by - ay, bz - az)
			local distance = MathUtil.vector3Length(x, y, z)
			local _ = 0
			local upY = 1
			local upZ = 0

			if math.abs(y) > 0.99 * distance then
				upY = 0
				upZ = y > 0 and 1 or -1
			end

			local alpha = math.rad(-90)
			local px, py, pz = getWorldTranslation(jointDesc.topArm.rotationNode)
			local _, _, lz = worldToLocal(self.components[1].node, px, py, pz)

			if lz < 0 then
				alpha = math.rad(90)
			end

			local dx, dy, dz = localDirectionToWorld(jointDesc.topArm.rotationNode, 0, 0, 1)
			dx, dy, dz = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), dx, dy, dz)
			local upX = dx
			local upY = math.cos(alpha) * dy - math.sin(alpha) * dz
			local upZ = math.sin(alpha) * dy + math.cos(alpha) * dz

			setDirection(jointDesc.topArm.rotationNode, x * jointDesc.topArm.zScale, y * jointDesc.topArm.zScale, z * jointDesc.topArm.zScale, upX, upY, upZ)

			if jointDesc.topArm.translationNode ~= nil and not implement.attachingIsInProgress then
				local translation = distance - jointDesc.topArm.referenceDistance

				setTranslation(jointDesc.topArm.translationNode, 0, 0, translation * jointDesc.topArm.zScale)

				if jointDesc.topArm.scaleNode ~= nil then
					setScale(jointDesc.topArm.scaleNode, 1, 1, math.max((translation + jointDesc.topArm.scaleReferenceDistance) / jointDesc.topArm.scaleReferenceDistance, 0))
				end
			end
		end

		if jointDesc.bottomArm ~= nil then
			local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
			local bx, by, bz = getWorldTranslation(attacherJoint.node)
			local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx - ax, by - ay, bz - az)
			local distance = MathUtil.vector3Length(x, y, z)
			local upX = 0
			local upY = 1
			local upZ = 0

			if math.abs(y) > 0.99 * distance then
				upY = 0
				upZ = y > 0 and 1 or -1
			end

			local dirX = 0

			if not jointDesc.bottomArm.lockDirection then
				dirX = x * jointDesc.bottomArm.zScale
			end

			if math.abs(jointDesc.bottomArm.lastDirection[1] - dirX) > 0.001 or math.abs(jointDesc.bottomArm.lastDirection[2] - y * jointDesc.bottomArm.zScale) > 0.001 or math.abs(jointDesc.bottomArm.lastDirection[3] - z * jointDesc.bottomArm.zScale) > 0.001 then
				setDirection(jointDesc.bottomArm.rotationNode, dirX, y * jointDesc.bottomArm.zScale, z * jointDesc.bottomArm.zScale, upX, upY, upZ)

				jointDesc.bottomArm.lastDirection[1] = dirX
				jointDesc.bottomArm.lastDirection[2] = y * jointDesc.bottomArm.zScale
				jointDesc.bottomArm.lastDirection[3] = z * jointDesc.bottomArm.zScale
			end

			if jointDesc.bottomArm.translationNode ~= nil and not implement.attachingIsInProgress then
				setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance - jointDesc.bottomArm.referenceDistance) * jointDesc.bottomArm.zScale)
			end

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(jointDesc.bottomArm.rotationNode)
			end

			if attacherJoint.needsToolbar and jointDesc.bottomArm.toolbar ~= nil then
				local parent = getParent(jointDesc.bottomArm.toolbar)
				local _, yDir, zDir = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 1, 0, 0)
				local xDir, yDir, zDir = localDirectionToLocal(jointDesc.rootNode, parent, 0, yDir, zDir)
				local _, yUp, zUp = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 0, 1, 0)
				local xUp, yUp, zUp = localDirectionToLocal(jointDesc.rootNode, parent, 0, yUp, zUp)

				setDirection(jointDesc.bottomArm.toolbar, xDir, yDir, zDir, xUp, yUp, zUp)
			end
		end
	end
end

function AttacherJoints:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object)
	local objectAtttacherJoint = object.spec_attachable.attacherJoint

	if jointDesc.allowsLowering then
		local lowerDistanceToGround = jointDesc.lowerDistanceToGround
		local upperDistanceToGround = jointDesc.upperDistanceToGround

		if objectAtttacherJoint.heightNode ~= nil and jointDesc.rotationNode ~= nil then
			self:updateAttacherJointRotationNodes(jointDesc, 1)
			setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))

			local x, y, z = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
			local delta = jointDesc.lowerDistanceToGround - y
			local hx, hy, hz = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, objectAtttacherJoint.heightNodeOffset[1], objectAtttacherJoint.heightNodeOffset[2], objectAtttacherJoint.heightNodeOffset[3])
			lowerDistanceToGround = hy + delta

			self:updateAttacherJointRotationNodes(jointDesc, 0)

			x, y, z = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
			delta = jointDesc.upperDistanceToGround - y
			hx, hy, hz = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, objectAtttacherJoint.heightNodeOffset[1], objectAtttacherJoint.heightNodeOffset[2], objectAtttacherJoint.heightNodeOffset[3])
			upperDistanceToGround = hy + delta
		end

		local upperAlpha = MathUtil.clamp((objectAtttacherJoint.upperDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
		local lowerAlpha = MathUtil.clamp((objectAtttacherJoint.lowerDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)

		if objectAtttacherJoint.allowsLowering and jointDesc.allowsLowering then
			return upperAlpha, lowerAlpha
		elseif objectAtttacherJoint.isDefaultLowered then
			return lowerAlpha, lowerAlpha
		else
			return upperAlpha, upperAlpha
		end
	end

	if objectAtttacherJoint.isDefaultLowered then
		return 1, 1
	else
		return 0, 0
	end
end

function AttacherJoints:updateAttacherJointRotation(jointDesc, object)
	local objectAtttacherJoint = object.spec_attachable.attacherJoint
	local targetRot = MathUtil.lerp(objectAtttacherJoint.upperRotationOffset, objectAtttacherJoint.lowerRotationOffset, jointDesc.moveAlpha)
	local curRot = MathUtil.lerp(jointDesc.upperRotationOffset, jointDesc.lowerRotationOffset, jointDesc.moveAlpha)
	local rotDiff = targetRot - curRot

	setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
	rotateAboutLocalAxis(jointDesc.jointTransform, rotDiff, 0, 0, 1)
end

function AttacherJoints:updateAttacherJointRotationNodes(jointDesc, alpha)
	if jointDesc.rotationNode ~= nil then
		setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, alpha))
	end

	if jointDesc.rotationNode2 ~= nil then
		setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, alpha))
	end
end

function AttacherJoints:attachImplementFromInfo(info)
	if info.attachable ~= nil then
		local attacherJoints = info.attacherVehicle.spec_attacherJoints.attacherJoints

		if attacherJoints[info.attacherVehicleJointDescIndex].jointIndex == 0 and info.attachable.isAddedToMission then
			if info.attachable:getActiveInputAttacherJointDescIndex() ~= nil and info.attachable:getAllowMultipleAttachments() then
				info.attachable:resolveMultipleAttachments()
			end

			if GS_IS_MOBILE_VERSION then
				local attacherJointDirection = attacherJoints[info.attacherVehicleJointDescIndex].additionalAttachment.attacherJointDirection

				if attacherJointDirection ~= nil then
					local attachedImplements = info.attacherVehicle:getAttachedImplements()

					for i = 1, #attachedImplements do
						local jointDesc = attacherJoints[attachedImplements[i].jointDescIndex]

						if attacherJointDirection == jointDesc.additionalAttachment.attacherJointDirection then
							return false
						end
					end
				end
			end

			info.attacherVehicle:attachImplement(info.attachable, info.attachableJointDescIndex, info.attacherVehicleJointDescIndex)

			return true
		end
	end

	return false
end

function AttacherJoints:attachImplement(object, inputJointDescIndex, jointDescIndex, noEventSend, index, startLowered, noSmoothAttach, loadFromSavegame)
	local spec = self.spec_attacherJoints
	local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]

	SpecializationUtil.raiseEvent(self, "onPreAttachImplement", object, inputJointDescIndex, jointDescIndex)
	object:preAttach(self, inputJointDescIndex, jointDescIndex, loadFromSavegame)

	local jointDesc = spec.attacherJoints[jointDescIndex]

	ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)

	local upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object)
	jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)

	if startLowered == nil then
		startLowered = true

		if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
			self:updateAttacherJointRotationNodes(jointDesc, upperAlpha)

			local distanceSqUpper = calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node)

			self:updateAttacherJointRotationNodes(jointDesc, lowerAlpha)

			local distanceSqLower = calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node)

			if distanceSqUpper < distanceSqLower * 1.1 then
				startLowered = false
			end

			if objectAttacherJoint.useFoldingLoweredState then
				startLowered = object:getIsLowered()
			end

			if GS_IS_MOBILE_VERSION and jointDesc.jointType == AttacherJoints.JOINTTYPE_CUTTER and object.spec_supportVehicle ~= nil and object.spec_supportVehicle.filename ~= nil then
				startLowered = false
			end
		elseif not objectAttacherJoint.isDefaultLowered then
			startLowered = false
		end
	end

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VehicleAttachEvent:new(self, object, inputJointDescIndex, jointDescIndex, startLowered), nil, , self)
		else
			g_client:getServerConnection():sendEvent(VehicleAttachEvent:new(self, object, inputJointDescIndex, jointDescIndex, startLowered))
		end
	end

	if jointDesc.transNode ~= nil and objectAttacherJoint.attacherHeight ~= nil then
		local minYHeight = jointDesc.transNodeMinY
		local maxYHeight = jointDesc.transNodeMaxY
		local lowerDistanceToGround = jointDesc.lowerDistanceToGround
		local upperDistanceToGround = jointDesc.upperDistanceToGround
		local attacherHeight = objectAttacherJoint.attacherHeight

		if self.getOutputPowerTakeOffsByJointDescIndex ~= nil then
			local ptoOutputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)

			if ptoOutputs ~= nil and #ptoOutputs > 0 then
				local ptoOutput = ptoOutputs[1]
				local ptoInput = ptoOutput.connectedInput

				if ptoInput ~= nil then
					local _, y, _ = localToLocal(ptoOutput.outputNode, getParent(jointDesc.transNode), 0, 0, 0)
					local ptoYFactor = (y - minYHeight) / (maxYHeight - minYHeight)
					local ptoRealHeight = MathUtil.lerp(lowerDistanceToGround, upperDistanceToGround, ptoYFactor)
					local ptoSize = (ptoInput.size + jointDesc.transNodeHeight) * 0.5

					if ptoInput.aboveAttacher then
						attacherHeight = MathUtil.clamp(attacherHeight, lowerDistanceToGround, ptoRealHeight - ptoSize)
					else
						attacherHeight = MathUtil.clamp(attacherHeight, ptoRealHeight + ptoSize, upperDistanceToGround)
					end
				end
			end
		end

		attacherHeight = MathUtil.clamp(attacherHeight - jointDesc.transNodeOffsetY, lowerDistanceToGround, upperDistanceToGround)
		local factor = (attacherHeight - lowerDistanceToGround) / (upperDistanceToGround - lowerDistanceToGround)
		local y = MathUtil.lerp(minYHeight, maxYHeight, factor)
		local x, _, z = getTranslation(jointDesc.transNode)
		_, y, _ = localToLocal(self.rootNode, getParent(jointDesc.transNode), 0, y, 0)

		setTranslation(jointDesc.transNode, x, y, z)
	end

	if objectAttacherJoint.topReferenceNode ~= nil and jointDesc.topArm ~= nil and jointDesc.topArm.toggleVisibility then
		setVisibility(jointDesc.topArm.rotationNode, true)
	end

	if jointDesc.bottomArm ~= nil then
		if jointDesc.bottomArm.toggleVisibility then
			setVisibility(jointDesc.bottomArm.rotationNode, true)
		end

		if objectAttacherJoint.needsToolbar and jointDesc.bottomArm.toolbar ~= nil then
			setVisibility(jointDesc.bottomArm.toolbar, true)
		end
	end

	local implement = {
		object = object,
		jointDescIndex = jointDescIndex,
		inputJointDescIndex = inputJointDescIndex,
		loadFromSavegame = loadFromSavegame
	}
	jointDesc.upperAlpha = upperAlpha
	jointDesc.lowerAlpha = lowerAlpha
	jointDesc.moveAlpha = upperAlpha
	jointDesc.moveLimitAlpha = 0

	if startLowered then
		jointDesc.moveAlpha = lowerAlpha
		jointDesc.moveLimitAlpha = 1
	end

	self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
	self:updateAttacherJointRotation(jointDesc, object)
	self:createAttachmentJoint(implement, noSmoothAttach)

	local moveDown = objectAttacherJoint.isDefaultLowered or jointDesc.isDefaultLowered

	if objectAttacherJoint.useFoldingLoweredState then
		moveDown = startLowered
	end

	jointDesc.moveDown = moveDown

	object:setLowered(jointDesc.moveDown)

	if index == nil then
		table.insert(spec.attachedImplements, implement)
	else
		spec.attachedImplements[index] = implement
	end

	self:updateAttacherJointGraphics(implement, 0)
	self:playAttachSound(jointDesc)

	if not implement.attachingIsInProgress then
		self:postAttachImplement(implement)
	end

	self:attachAdditionalAttachment(jointDesc, objectAttacherJoint, object)
	self:getRootVehicle():updateSelectableObjects()
	self:updateChildVehicles()

	local inputAttacherJoint = implement.object:getActiveInputAttacherJoint()
	local selectedVehicle = nil

	if inputAttacherJoint.forceSelection then
		selectedVehicle = implement.object
	end

	self:getRootVehicle():setSelectedVehicle(selectedVehicle)

	return true
end

function AttacherJoints:postAttachImplement(implement)
	local object = implement.object
	local inputJointDescIndex = implement.inputJointDescIndex
	local jointDescIndex = implement.jointDescIndex

	SpecializationUtil.raiseEvent(self, "onPostAttachImplement", object, inputJointDescIndex, jointDescIndex)
	object:postAttach(self, inputJointDescIndex, jointDescIndex, implement.loadFromSavegame)

	local data = {
		attacherVehicle = self,
		attachedVehicle = implement.object
	}
	local rootVehicle = self:getRootVehicle()

	rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_ATTACH, data)
end

function AttacherJoints:createAttachmentJoint(implement, noSmoothAttach)
	local spec = self.spec_attacherJoints
	local jointDesc = spec.attacherJoints[implement.jointDescIndex]
	local objectAtttacherJoint = implement.object.spec_attachable.attacherJoint

	if self.isServer and objectAtttacherJoint ~= nil then
		if getRigidBodyType(jointDesc.rootNode) ~= "Dynamic" or getRigidBodyType(objectAtttacherJoint.rootNode) ~= "Dynamic" then
			return
		end

		local xNew = jointDesc.jointOrigTrans[1] + jointDesc.jointPositionOffset[1]
		local yNew = jointDesc.jointOrigTrans[2] + jointDesc.jointPositionOffset[2]
		local zNew = jointDesc.jointOrigTrans[3] + jointDesc.jointPositionOffset[3]
		local x, y, z = localToWorld(getParent(jointDesc.jointTransform), xNew, yNew, zNew)
		local x1, y1, z1 = worldToLocal(jointDesc.jointTransform, x, y, z)

		setTranslation(jointDesc.jointTransform, xNew, yNew, zNew)

		x, y, z = localToWorld(objectAtttacherJoint.node, x1, y1, z1)
		local x2, y2, z2 = worldToLocal(getParent(objectAtttacherJoint.node), x, y, z)

		setTranslation(objectAtttacherJoint.node, x2, y2, z2)

		local constr = JointConstructor:new()

		constr:setActors(jointDesc.rootNode, objectAtttacherJoint.rootNode)
		constr:setJointTransforms(jointDesc.jointTransform, objectAtttacherJoint.node)

		implement.jointRotLimit = {}
		implement.jointTransLimit = {}
		implement.lowerRotLimit = {}
		implement.lowerTransLimit = {}
		implement.upperRotLimit = {}
		implement.upperTransLimit = {}

		if noSmoothAttach == nil or not noSmoothAttach then
			local dx, dy, dz = localToLocal(objectAtttacherJoint.node, jointDesc.jointTransform, 0, 0, 0)
			local _, y, z = localDirectionToLocal(objectAtttacherJoint.node, jointDesc.jointTransform, 0, 1, 0)
			local rX = math.atan2(z, y)
			local x, _, z = localDirectionToLocal(objectAtttacherJoint.node, jointDesc.jointTransform, 0, 0, 1)
			local rY = math.atan2(x, z)
			local x, y, _ = localDirectionToLocal(objectAtttacherJoint.node, jointDesc.jointTransform, 1, 0, 0)
			local rZ = math.atan2(y, x)
			implement.attachingTransLimit = {
				math.abs(dx),
				math.abs(dy),
				math.abs(dz)
			}
			implement.attachingRotLimit = {
				math.abs(rX),
				math.abs(rY),
				math.abs(rZ)
			}
			implement.attachingTransLimitSpeed = {}
			implement.attachingRotLimitSpeed = {}

			for i = 1, 3 do
				implement.attachingTransLimitSpeed[i] = implement.attachingTransLimit[i] / 500
				implement.attachingRotLimitSpeed[i] = implement.attachingRotLimit[i] / 500
			end

			implement.attachingIsInProgress = true
		else
			implement.attachingTransLimit = {
				0,
				0,
				0
			}
			implement.attachingRotLimit = {
				0,
				0,
				0
			}
		end

		for i = 1, 3 do
			local lowerRotLimit = jointDesc.lowerRotLimit[i] * objectAtttacherJoint.lowerRotLimitScale[i]
			local upperRotLimit = jointDesc.upperRotLimit[i] * objectAtttacherJoint.upperRotLimitScale[i]

			if objectAtttacherJoint.fixedRotation then
				lowerRotLimit = 0
				upperRotLimit = 0
			end

			local upperTransLimit = jointDesc.lowerTransLimit[i] * objectAtttacherJoint.lowerTransLimitScale[i]
			local lowerTransLimit = jointDesc.upperTransLimit[i] * objectAtttacherJoint.upperTransLimitScale[i]
			implement.lowerRotLimit[i] = lowerRotLimit
			implement.upperRotLimit[i] = upperRotLimit
			implement.lowerTransLimit[i] = upperTransLimit
			implement.upperTransLimit[i] = lowerTransLimit

			if not jointDesc.allowsLowering then
				implement.upperRotLimit[i] = lowerRotLimit
				implement.upperTransLimit[i] = upperTransLimit
			end

			local rotLimit = lowerRotLimit
			local transLimit = upperTransLimit

			if jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement then
				if objectAtttacherJoint.allowsJointRotLimitMovement then
					rotLimit = MathUtil.lerp(upperRotLimit, lowerRotLimit, jointDesc.moveAlpha)
				end

				if objectAtttacherJoint.allowsJointTransLimitMovement then
					transLimit = MathUtil.lerp(lowerTransLimit, upperTransLimit, jointDesc.moveAlpha)
				end
			end

			local limitRot = rotLimit
			local limitTrans = transLimit

			if noSmoothAttach == nil or not noSmoothAttach then
				limitRot = math.max(rotLimit, implement.attachingRotLimit[i])
				limitTrans = math.max(transLimit, implement.attachingTransLimit[i])
			end

			constr:setRotationLimit(i - 1, -limitRot, limitRot)

			implement.jointRotLimit[i] = limitRot

			constr:setTranslationLimit(i - 1, true, -limitTrans, limitTrans)

			implement.jointTransLimit[i] = limitTrans
		end

		if jointDesc.enableCollision then
			constr:setEnableCollision(true)
		else
			for _, component in pairs(self.components) do
				if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
					setPairCollision(component.node, objectAtttacherJoint.rootNode, false)
				end
			end
		end

		local springX = math.max(jointDesc.rotLimitSpring[1], objectAtttacherJoint.rotLimitSpring[1])
		local springY = math.max(jointDesc.rotLimitSpring[2], objectAtttacherJoint.rotLimitSpring[2])
		local springZ = math.max(jointDesc.rotLimitSpring[3], objectAtttacherJoint.rotLimitSpring[3])
		local dampingX = math.max(jointDesc.rotLimitDamping[1], objectAtttacherJoint.rotLimitDamping[1])
		local dampingY = math.max(jointDesc.rotLimitDamping[2], objectAtttacherJoint.rotLimitDamping[2])
		local dampingZ = math.max(jointDesc.rotLimitDamping[3], objectAtttacherJoint.rotLimitDamping[3])
		local forceLimitX = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[1], objectAtttacherJoint.rotLimitForceLimit[1])
		local forceLimitY = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[2], objectAtttacherJoint.rotLimitForceLimit[2])
		local forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[3], objectAtttacherJoint.rotLimitForceLimit[3])

		constr:setRotationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
		constr:setRotationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

		local springX = math.max(jointDesc.transLimitSpring[1], objectAtttacherJoint.transLimitSpring[1])
		local springY = math.max(jointDesc.transLimitSpring[2], objectAtttacherJoint.transLimitSpring[2])
		local springZ = math.max(jointDesc.transLimitSpring[3], objectAtttacherJoint.transLimitSpring[3])
		local dampingX = math.max(jointDesc.transLimitDamping[1], objectAtttacherJoint.transLimitDamping[1])
		local dampingY = math.max(jointDesc.transLimitDamping[2], objectAtttacherJoint.transLimitDamping[2])
		local dampingZ = math.max(jointDesc.transLimitDamping[3], objectAtttacherJoint.transLimitDamping[3])
		local forceLimitX = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[1], objectAtttacherJoint.transLimitForceLimit[1])
		local forceLimitY = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[2], objectAtttacherJoint.transLimitForceLimit[2])
		local forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[3], objectAtttacherJoint.transLimitForceLimit[3])

		constr:setTranslationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
		constr:setTranslationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

		jointDesc.jointIndex = constr:finalize()

		setTranslation(objectAtttacherJoint.node, unpack(objectAtttacherJoint.jointOrigTrans))
	else
		jointDesc.jointIndex = 1
	end
end

function AttacherJoints:hardAttachImplement(implement)
	local spec = self.spec_attacherJoints
	local implements = {}
	local attachedImplements = nil

	if implement.object.getAttachedImplements ~= nil then
		attachedImplements = implement.object:getAttachedImplements()
	end

	if attachedImplements ~= nil then
		for i = table.getn(attachedImplements), 1, -1 do
			local impl = attachedImplements[i]
			local object = impl.object
			local jointDescIndex = impl.jointDescIndex
			local jointDesc = implement.object.spec_attacherJoints.attacherJoints[jointDescIndex]
			local inputJointDescIndex = object.spec_attachable.inputAttacherJointDescIndex
			local moveDown = jointDesc.moveDown

			table.insert(implements, 1, {
				object = object,
				implementIndex = i,
				jointDescIndex = jointDescIndex,
				inputJointDescIndex = inputJointDescIndex,
				moveDown = moveDown
			})
			implement.object:detachImplement(1, true)
		end
	end

	local attacherJoint = spec.attacherJoints[implement.jointDescIndex]
	local implementJoint = implement.object.spec_attachable.attacherJoint
	local baseVehicleComponentNode = self:getParentComponent(attacherJoint.jointTransform)
	local attachedVehicleComponentNode = implement.object:getParentComponent(implement.object.spec_attachable.attacherJoint.node)
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:removeFromPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	implement.object:removeFromPhysics()

	if spec.attacherVehicle == nil then
		setIsCompound(baseVehicleComponentNode, true)
	end

	setIsCompoundChild(attachedVehicleComponentNode, true)

	local dirX, dirY, dirZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 1)
	local upX, upY, upZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 1, 0)

	setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)

	local x, y, z = localToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 0)

	setTranslation(attachedVehicleComponentNode, x, y, z)
	link(attacherJoint.jointTransform, attachedVehicleComponentNode)

	if implementJoint.visualNode ~= nil and attacherJoint.jointTransformVisual ~= nil then
		local dirX, dirY, dirZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 1)
		local upX, upY, upZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 1, 0)

		setDirection(implementJoint.visualNode, dirX, dirY, dirZ, upX, upY, upZ)

		local x, y, z = localToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 0)

		setTranslation(implementJoint.visualNode, x, y, z)
		link(attacherJoint.jointTransformVisual, implementJoint.visualNode)
	end

	implement.object.isHardAttached = true
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:addToPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		attacherJoint.rootNode = self.rootNode
	end

	for _, impl in pairs(implements) do
		implement.object:attachImplement(impl.object, impl.inputJointDescIndex, impl.jointDescIndex, true, impl.implementIndex, impl.moveDown, true)
	end

	if self.isServer then
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end

	return true
end

function AttacherJoints:hardDetachImplement(implement)
	for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		attacherJoint.rootNode = attacherJoint.rootNodeBackup
	end

	local implementJoint = implement.object.spec_attachable.attacherJoint
	local attachedVehicleComponentNode = implement.object:getParentComponent(implementJoint.node)
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:removeFromPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	setIsCompound(attachedVehicleComponentNode, true)

	local x, y, z = getWorldTranslation(attachedVehicleComponentNode)

	setTranslation(attachedVehicleComponentNode, x, y, z)

	local dirX, dirY, dirZ = localDirectionToWorld(implement.object.rootNode, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(implement.object.rootNode, 0, 1, 0)

	setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)
	link(getRootNode(), attachedVehicleComponentNode)

	if implementJoint.visualNode ~= nil and getParent(implementJoint.visualNode) ~= implementJoint.visualNodeData.parent then
		link(implementJoint.visualNodeData.parent, implementJoint.visualNode, implementJoint.visualNodeData.index)
		setRotation(implementJoint.visualNode, implementJoint.visualNodeData.rotation[1], implementJoint.visualNodeData.rotation[2], implementJoint.visualNodeData.rotation[3])
		setTranslation(implementJoint.visualNode, implementJoint.visualNodeData.translation[1], implementJoint.visualNodeData.translation[2], implementJoint.visualNodeData.translation[3])
	end

	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:addToPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	implement.object:addToPhysics()

	implement.object.isHardAttached = false

	if self.isServer then
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end

	return true
end

function AttacherJoints:detachImplement(implementIndex, noEventSend)
	local spec = self.spec_attacherJoints

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VehicleDetachEvent:new(self, spec.attachedImplements[implementIndex].object), nil, , self)
		else
			local implement = spec.attachedImplements[implementIndex]

			if implement.object ~= nil then
				g_client:getServerConnection():sendEvent(VehicleDetachEvent:new(self, implement.object))
			end

			return
		end
	end

	local implement = spec.attachedImplements[implementIndex]

	SpecializationUtil.raiseEvent(self, "onPreDetachImplement", implement)
	implement.object:preDetach(self, implement)

	local jointDesc = nil

	if implement.object ~= nil then
		jointDesc = spec.attacherJoints[implement.jointDescIndex]

		if jointDesc.transNode ~= nil then
			setTranslation(jointDesc.transNode, unpack(jointDesc.transNodeOrgTrans))
		end

		if not implement.object.isHardAttached and self.isServer then
			if jointDesc.jointIndex ~= 0 then
				removeJoint(jointDesc.jointIndex)
			end

			if not jointDesc.enableCollision then
				for _, component in pairs(self.components) do
					if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
						local attacherJoint = implement.object:getActiveInputAttacherJoint()

						setPairCollision(component.node, attacherJoint.rootNode, true)
					end
				end
			end
		end

		jointDesc.jointIndex = 0
	end

	ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)

	if implement.object ~= nil then
		local object = implement.object

		if object.isHardAttached then
			self:hardDetachImplement(implement)
		end

		if self.isClient then
			if jointDesc.topArm ~= nil then
				setRotation(jointDesc.topArm.rotationNode, jointDesc.topArm.rotX, jointDesc.topArm.rotY, jointDesc.topArm.rotZ)

				if jointDesc.topArm.translationNode ~= nil then
					setTranslation(jointDesc.topArm.translationNode, 0, 0, 0)
				end

				if jointDesc.topArm.scaleNode ~= nil then
					setScale(jointDesc.topArm.scaleNode, 1, 1, 1)
				end

				if jointDesc.topArm.toggleVisibility then
					setVisibility(jointDesc.topArm.rotationNode, false)
				end
			end

			if jointDesc.bottomArm ~= nil then
				setRotation(jointDesc.bottomArm.rotationNode, jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ)

				if jointDesc.bottomArm.translationNode ~= nil then
					setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
				end

				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(jointDesc.bottomArm.rotationNode)
				end

				if jointDesc.bottomArm.toolbar ~= nil then
					setVisibility(jointDesc.bottomArm.toolbar, false)
				end

				if jointDesc.bottomArm.toggleVisibility then
					setVisibility(jointDesc.bottomArm.rotationNode, false)
				end
			end
		end

		setTranslation(jointDesc.jointTransform, unpack(jointDesc.jointOrigTrans))

		local attacherJoint = object:getActiveInputAttacherJoint()

		setTranslation(attacherJoint.node, unpack(attacherJoint.jointOrigTrans))

		if jointDesc.rotationNode ~= nil then
			setRotation(jointDesc.rotationNode, jointDesc.rotX, jointDesc.rotY, jointDesc.rotZ)
		end

		SpecializationUtil.raiseEvent(self, "onPostDetachImplement", implementIndex)
		object:postDetach(implementIndex)
		self:detachAdditionalAttachment(jointDesc, attacherJoint)
	end

	table.remove(spec.attachedImplements, implementIndex)
	self:playDetachSound(jointDesc)

	spec.wasInAttachRange = nil
	local data = {
		attacherVehicle = self,
		attachedVehicle = implement.object
	}

	implement.object:raiseStateChange(Vehicle.STATE_CHANGE_DETACH, data)

	local rootVehicle = self:getRootVehicle()

	rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_DETACH, data)
	self:getRootVehicle():updateSelectableObjects()

	if GS_IS_MOBILE_VERSION then
		local nextImplement = next(spec.attachedImplements)

		if spec.attachedImplements[nextImplement] ~= nil then
			self:getRootVehicle():setSelectedVehicle(spec.attachedImplements[nextImplement].object, nil, true)
		else
			self:getRootVehicle():setSelectedVehicle(self, nil, true)
		end
	else
		self:getRootVehicle():setSelectedVehicle(self, nil, true)
	end

	self:getRootVehicle():requestActionEventUpdate()
	implement.object:updateSelectableObjects()
	implement.object:setSelectedVehicle(implement.object, nil, true)
	implement.object:requestActionEventUpdate()
	self:updateChildVehicles()

	return true
end

function AttacherJoints:detachImplementByObject(object, noEventSend)
	local spec = self.spec_attacherJoints

	for i, implement in ipairs(spec.attachedImplements) do
		if implement.object == object then
			self:detachImplement(i, noEventSend)

			break
		end
	end

	return true
end

function AttacherJoints:setSelectedImplementByObject(object)
	self.spec_attacherJoints.selectedImplement = self:getImplementByObject(object)
end

function AttacherJoints:getSelectedImplement()
	local spec = self.spec_attacherJoints

	if spec.selectedImplement ~= nil and spec.selectedImplement.object:getAttacherVehicle() ~= self then
		return nil
	end

	return spec.selectedImplement
end

function AttacherJoints:getCanToggleAttach()
	return true
end

function AttacherJoints:getShowDetachAttachedImplement()
	if self:getIsAIActive() then
		return false
	end

	local spec = self.spec_attacherJoints
	local info = spec.attachableInfo
	info.attacherVehicle, info.attacherVehicleJointDescIndex, info.attachable, info.attachableJointDescIndex = AttacherJoints.findVehicleInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE)

	if info.attacherVehicle == nil then
		local selectedVehicle = self:getSelectedVehicle()

		if selectedVehicle ~= nil and not selectedVehicle.isDeleted and selectedVehicle.getAttacherVehicle ~= nil and selectedVehicle:getAttacherVehicle() ~= nil then
			return true
		end
	end

	return false
end

function AttacherJoints:detachAttachedImplement()
	if self:getCanToggleAttach() then
		AttacherJoints.actionEventAttach(self)
	end
end

function AttacherJoints:startAttacherJointCombo(force)
	local spec = self.spec_attacherJoints

	if not spec.attacherJointCombos.isRunning or force then
		spec.attacherJointCombos.direction = -spec.attacherJointCombos.direction
		spec.attacherJointCombos.isRunning = true
	end
end

function AttacherJoints:registerSelfLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function AttacherJoints:playAttachSound(jointDesc)
	local spec = self.spec_attacherJoints

	if self.isClient then
		if jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
			g_soundManager:playSample(jointDesc.sampleAttach)
		else
			g_soundManager:playSample(spec.samples.attach)
		end
	end

	return true
end

function AttacherJoints:playDetachSound(jointDesc)
	local spec = self.spec_attacherJoints

	if self.isClient then
		if jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
			g_soundManager:playSample(jointDesc.sampleAttach)
		else
			g_soundManager:playSample(spec.samples.attach)
		end
	end

	return true
end

function AttacherJoints:detachingIsPossible()
	local implement = self:getImplementByObject(self:getSelectedVehicle())

	if implement ~= nil then
		local object = implement.object

		if object ~= nil and object.attacherVehicle ~= nil and object:isDetachAllowed() then
			local implementIndex = object.attacherVehicle:getImplementIndexByObject(object)

			if implementIndex ~= nil then
				return true
			end
		end
	end

	return false
end

function AttacherJoints:attachAdditionalAttachment(jointDesc, inputJointDesc, object)
	if jointDesc.additionalAttachment.attacherJointDirection ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local storeItem = g_storeManager:getItemByXMLFilename(inputJointDesc.additionalAttachment.filename)

		if storeItem ~= nil then
			local targetDirection = -jointDesc.additionalAttachment.attacherJointDirection
			local attacherJoint, attacherJointIndex = nil

			for index, attacherJointToCheck in ipairs(self:getAttacherJoints()) do
				if attacherJointToCheck.additionalAttachment.attacherJointDirection == targetDirection then
					if attacherJointToCheck.jointIndex ~= 0 then
						attacherJoint = nil

						break
					elseif attacherJointToCheck.jointType == inputJointDesc.additionalAttachment.jointType then
						attacherJoint = attacherJointToCheck
						attacherJointIndex = index
					end
				end
			end

			if attacherJoint ~= nil then
				local x, y, z = localToWorld(attacherJoint.jointTransform, 0, 0, 0)
				local dirX, _, dirZ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
				local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
				jointDesc.additionalAttachment.currentAttacherJointIndex = attacherJointIndex
				local asyncCallbackArguments = {
					attacherJointIndex,
					inputJointDesc.additionalAttachment.inputAttacherJointIndex,
					attacherJoint.jointTransform,
					inputJointDesc.additionalAttachment.needsLowering,
					object
				}
				local vehicle = g_currentMission:loadVehicle(storeItem.xmlFilename, x, y, z, 0, yRot, false, 0, Vehicle.PROPERTY_STATE_NONE, self:getActiveFarm(), {}, nil, AttacherJoints.additionalAttachmentLoaded, self, asyncCallbackArguments)

				if vehicle ~= nil and vehicle.setIsAdditionalAttachment ~= nil then
					vehicle:setIsAdditionalAttachment(inputJointDesc.additionalAttachment.needsLowering, false)
				else
					g_logManager:warning("Failed to load additional attachment '%s'.", storeItem.xmlFilename)
				end
			end
		end
	end
end

function AttacherJoints:detachAdditionalAttachment(jointDesc, inputJointDesc)
	if jointDesc.additionalAttachment.currentAttacherJointIndex ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local implement = self:getImplementByJointDescIndex(jointDesc.additionalAttachment.currentAttacherJointIndex)

		if implement ~= nil and implement.object:getIsAdditionalAttachment() and not g_currentMission.isExitingGame then
			g_currentMission:removeVehicle(implement.object)
		end
	end
end

function AttacherJoints:additionalAttachmentLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	local offset = {
		0,
		0,
		0
	}

	if vehicle.getInputAttacherJoints ~= nil then
		local inputAttacherJoints = vehicle:getInputAttacherJoints()

		if inputAttacherJoints[asyncCallbackArguments[2]] ~= nil then
			offset = inputAttacherJoints[asyncCallbackArguments[2]].jointOrigOffsetComponent
		end
	end

	local x, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
	local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], 1, 0, 0)
	local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

	vehicle:setAbsolutePosition(x, math.max(y, terrainY + 0.05), z, 0, yRot, 0)
	self:attachImplement(vehicle, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, , true)
	vehicle:setIsAdditionalAttachment(asyncCallbackArguments[4], true)

	if vehicle.addDirtAmount ~= nil and asyncCallbackArguments[5] ~= nil and asyncCallbackArguments[5].getDirtAmount ~= nil then
		vehicle:addDirtAmount(asyncCallbackArguments[5]:getDirtAmount())
	end

	self:getRootVehicle():updateSelectableObjects()
	self:getRootVehicle():setSelectedVehicle(asyncCallbackArguments[5] or self)
end

function AttacherJoints:getImplementIndexByJointDescIndex(jointDescIndex)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.jointDescIndex == jointDescIndex then
			return i
		end
	end

	return nil
end

function AttacherJoints:getImplementByJointDescIndex(jointDescIndex)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.jointDescIndex == jointDescIndex then
			return implement
		end
	end

	return nil
end

function AttacherJoints:getImplementIndexByObject(object)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.object == object then
			return i
		end
	end

	return nil
end

function AttacherJoints:getImplementByObject(object)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.object == object then
			return implement
		end
	end

	return nil
end

function AttacherJoints:callFunctionOnAllImplements(functionName, ...)
	for _, implement in pairs(self:getAttachedImplements()) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle[functionName] ~= nil then
			vehicle[functionName](vehicle, ...)
		end
	end
end

function AttacherJoints:activateAttachments()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil then
			v.object:activate()
		end
	end
end

function AttacherJoints:deactivateAttachments()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil then
			v.object:deactivate()
		end
	end
end

function AttacherJoints:deactivateAttachmentsLights()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil and v.object.deactivateLights ~= nil then
			v.object:deactivateLights()
		end
	end
end

function AttacherJoints:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
	local spec = self.spec_attacherJoints

	VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)

	local jointDesc = spec.attacherJoints[jointDescIndex]
	jointDesc.moveDown = moveDown
	local implementIndex = self:getImplementIndexByJointDescIndex(jointDescIndex)

	if implementIndex ~= nil then
		local implement = spec.attachedImplements[implementIndex]

		if implement.object ~= nil then
			implement.object:setLowered(moveDown)
		end
	end

	return true
end

function AttacherJoints:getIsHardAttachAllowed(jointDescIndex)
	local spec = self.spec_attacherJoints

	return spec.attacherJoints[jointDescIndex].supportsHardAttach
end

function AttacherJoints:loadAttacherJointFromXML(attacherJoint, xmlFile, baseName, index)
	local spec = self.spec_attacherJoints

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#index", baseName .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#indexVisual", baseName .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#ptoOutputNode", "vehicle.powerTakeOffs.output")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#lowerDistanceToGround", baseName .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#upperDistanceToGround", baseName .. ".distanceToGround#upper")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#rotationNode", baseName .. ".rotationNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#upperRotation", baseName .. ".rotationNode#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#lowerRotation", baseName .. ".rotationNode#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#startRotation", baseName .. ".rotationNode#startRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#rotationNode2", baseName .. ".rotationNode2#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#upperRotation2", baseName .. ".rotationNode2#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#lowerRotation2", baseName .. ".rotationNode2#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#transNode", baseName .. ".transNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#transNodeMinY", baseName .. ".transNode#minY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#transNodeMaxY", baseName .. ".transNode#maxY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#transNodeHeight", baseName .. ".transNode#height")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing node for attacherJoint '%s'", baseName)

		return false
	end

	attacherJoint.jointTransform = node
	attacherJoint.jointTransformVisual = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#nodeVisual"), self.i3dMappings)
	attacherJoint.supportsHardAttach = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#supportsHardAttach"), true)
	attacherJoint.jointOrigOffsetComponent = {
		localToLocal(self:getParentComponent(attacherJoint.jointTransform), attacherJoint.jointTransform, 0, 0, 0)
	}
	attacherJoint.jointOrigDirOffsetComponent = {
		localDirectionToLocal(self:getParentComponent(attacherJoint.jointTransform), attacherJoint.jointTransform, 0, 0, 1)
	}
	local jointTypeStr = getXMLString(xmlFile, baseName .. "#jointType")
	local jointType = nil

	if jointTypeStr ~= nil then
		jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]

		if jointType == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid jointType '%s' for attacherJoint '%s'!", tostring(jointTypeStr), baseName)
		end
	end

	if jointType == nil then
		jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
	end

	attacherJoint.jointType = jointType
	attacherJoint.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsJointLimitMovement"), true)
	attacherJoint.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsLowering"), true)
	attacherJoint.isDefaultLowered = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#isDefaultLowered"), false)
	attacherJoint.allowDetachingWhileLifted = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowDetachingWhileLifted"), true)
	attacherJoint.allowFoldingWhileAttached = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowFoldingWhileAttached"), true)

	if jointType == AttacherJoints.JOINTTYPE_TRAILER or jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
		attacherJoint.allowsLowering = false
	end

	attacherJoint.canTurnOnImplement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#canTurnOnImplement"), true)
	local rotationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".rotationNode#node"), self.i3dMappings)

	if rotationNode ~= nil then
		attacherJoint.rotationNode = rotationNode
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. ".rotationNode#lowerRotation"))
		attacherJoint.lowerRotation = {
			math.rad(Utils.getNoNil(x, 0)),
			math.rad(Utils.getNoNil(y, 0)),
			math.rad(Utils.getNoNil(z, 0))
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. ".rotationNode#upperRotation"))
		local rx, ry, rz = getRotation(rotationNode)
		attacherJoint.upperRotation = {
			Utils.getNoNilRad(x, rx),
			Utils.getNoNilRad(y, ry),
			Utils.getNoNilRad(z, rz)
		}
		local startRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, baseName .. ".rotationNode#startRotation"), 3)

		if startRot ~= nil then
			attacherJoint.rotZ = startRot[3]
			attacherJoint.rotY = startRot[2]
			attacherJoint.rotX = startRot[1]
		else
			attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ = getRotation(rotationNode)
		end

		local lowerValues = {
			attacherJoint.lowerRotation[1],
			attacherJoint.lowerRotation[2],
			attacherJoint.lowerRotation[3]
		}
		local upperValues = {
			attacherJoint.upperRotation[1],
			attacherJoint.upperRotation[2],
			attacherJoint.upperRotation[3]
		}

		for i = 1, 3 do
			local l = lowerValues[i]
			local u = upperValues[i]

			if u < l then
				upperValues[i] = l
				lowerValues[i] = u
			end
		end

		attacherJoint.rotX = MathUtil.clamp(attacherJoint.rotX, lowerValues[1], upperValues[1])
		attacherJoint.rotY = MathUtil.clamp(attacherJoint.rotY, lowerValues[2], upperValues[2])
		attacherJoint.rotZ = MathUtil.clamp(attacherJoint.rotZ, lowerValues[3], upperValues[3])
	end

	local rotationNode2 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".rotationNode2#node"), self.i3dMappings)

	if rotationNode2 ~= nil then
		attacherJoint.rotationNode2 = rotationNode2
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. ".rotationNode2#lowerRotation"))

		if x ~= nil and y ~= nil and z ~= nil then
			attacherJoint.lowerRotation2 = {
				math.rad(Utils.getNoNil(x, 0)),
				math.rad(Utils.getNoNil(y, 0)),
				math.rad(Utils.getNoNil(z, 0))
			}
		else
			attacherJoint.lowerRotation2 = {
				-attacherJoint.lowerRotation[1],
				-attacherJoint.lowerRotation[2],
				-attacherJoint.lowerRotation[3]
			}
		end

		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. ".rotationNode2#upperRotation"))

		if x ~= nil and y ~= nil and z ~= nil then
			attacherJoint.upperRotation2 = {
				math.rad(Utils.getNoNil(x, 0)),
				math.rad(Utils.getNoNil(y, 0)),
				math.rad(Utils.getNoNil(z, 0))
			}
		else
			attacherJoint.upperRotation2 = {
				-attacherJoint.upperRotation[1],
				-attacherJoint.upperRotation[2],
				-attacherJoint.upperRotation[3]
			}
		end
	end

	attacherJoint.transNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".transNode#node"), self.i3dMappings)

	if attacherJoint.transNode ~= nil then
		attacherJoint.transNodeOrgTrans = {
			getTranslation(attacherJoint.transNode)
		}
		attacherJoint.transNodeHeight = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".transNode#height"), 0.12)
		attacherJoint.transNodeMinY = getXMLFloat(xmlFile, baseName .. ".transNode#minY")
		attacherJoint.transNodeMaxY = getXMLFloat(xmlFile, baseName .. ".transNode#maxY")
	end

	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and getXMLFloat(xmlFile, baseName .. ".distanceToGround#lower") == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing '.distanceToGround#lower' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
	end

	attacherJoint.lowerDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".distanceToGround#lower"), 0.7)

	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and getXMLFloat(xmlFile, baseName .. ".distanceToGround#upper") == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing '.distanceToGround#upper' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
	end

	attacherJoint.upperDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".distanceToGround#upper"), 1)

	if attacherJoint.upperDistanceToGround < attacherJoint.lowerDistanceToGround then
		g_logManager:xmlWarning(self.configFileName, "distanceToGround#lower may not be larger than distanceToGround#upper for attacherJoint '%s'. Switching values!", baseName)

		local copy = attacherJoint.lowerDistanceToGround
		attacherJoint.lowerDistanceToGround = attacherJoint.upperDistanceToGround
		attacherJoint.upperDistanceToGround = copy
	end

	attacherJoint.lowerRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#lowerRotationOffset"), 0))
	attacherJoint.upperRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#upperRotationOffset"), 0))
	attacherJoint.lockDownRotLimit = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#lockDownRotLimit"), false)
	attacherJoint.lockUpRotLimit = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#lockUpRotLimit"), false)
	attacherJoint.lockDownTransLimit = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#lockDownTransLimit"), true)
	attacherJoint.lockUpTransLimit = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#lockUpTransLimit"), false)
	local lowerRotLimitStr = "20 20 20"

	if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
		lowerRotLimitStr = "0 0 0"
	end

	local lx, ly, lz = StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, baseName .. "#lowerRotLimit"), lowerRotLimitStr))
	attacherJoint.lowerRotLimit = {
		math.rad(math.abs(Utils.getNoNil(lx, 20))),
		math.rad(math.abs(Utils.getNoNil(ly, 20))),
		math.rad(math.abs(Utils.getNoNil(lz, 20)))
	}
	local ux, uy, uz = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#upperRotLimit"))
	attacherJoint.upperRotLimit = {
		math.rad(math.abs(Utils.getNoNil(Utils.getNoNil(ux, lx), 20))),
		math.rad(math.abs(Utils.getNoNil(Utils.getNoNil(uy, ly), 20))),
		math.rad(math.abs(Utils.getNoNil(Utils.getNoNil(uz, lz), 20)))
	}
	local lowerTransLimitStr = "0.5 0.5 0.5"

	if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
		lowerTransLimitStr = "0 0 0"
	end

	local lx, ly, lz = StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, baseName .. "#lowerTransLimit"), lowerTransLimitStr))
	attacherJoint.lowerTransLimit = {
		math.abs(Utils.getNoNil(lx, 0)),
		math.abs(Utils.getNoNil(ly, 0)),
		math.abs(Utils.getNoNil(lz, 0))
	}
	local ux, uy, uz = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#upperTransLimit"))
	attacherJoint.upperTransLimit = {
		math.abs(Utils.getNoNil(Utils.getNoNil(ux, lx), 0)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uy, ly), 0)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uz, lz), 0))
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#jointPositionOffset"))
	attacherJoint.jointPositionOffset = {
		Utils.getNoNil(x, 0),
		Utils.getNoNil(y, 0),
		Utils.getNoNil(z, 0)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#rotLimitSpring"))
	attacherJoint.rotLimitSpring = {
		Utils.getNoNil(x, 0),
		Utils.getNoNil(y, 0),
		Utils.getNoNil(z, 0)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#rotLimitDamping"))
	attacherJoint.rotLimitDamping = {
		Utils.getNoNil(x, 1),
		Utils.getNoNil(y, 1),
		Utils.getNoNil(z, 1)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#rotLimitForceLimit"))
	attacherJoint.rotLimitForceLimit = {
		Utils.getNoNil(x, -1),
		Utils.getNoNil(y, -1),
		Utils.getNoNil(z, -1)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#transLimitSpring"))
	attacherJoint.transLimitSpring = {
		Utils.getNoNil(x, 0),
		Utils.getNoNil(y, 0),
		Utils.getNoNil(z, 0)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#transLimitDamping"))
	attacherJoint.transLimitDamping = {
		Utils.getNoNil(x, 1),
		Utils.getNoNil(y, 1),
		Utils.getNoNil(z, 1)
	}
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, baseName .. "#transLimitForceLimit"))
	attacherJoint.transLimitForceLimit = {
		Utils.getNoNil(x, -1),
		Utils.getNoNil(y, -1),
		Utils.getNoNil(z, -1)
	}
	attacherJoint.moveDefaultTime = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#moveTime"), 0.5) * 1000
	attacherJoint.moveTime = attacherJoint.moveDefaultTime
	attacherJoint.enableCollision = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#enableCollision"), false)
	local topArmFilename = getXMLString(xmlFile, baseName .. ".topArm#filename")

	if topArmFilename ~= nil then
		local baseNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".topArm#baseNode"), self.i3dMappings)

		if baseNode ~= nil then
			local i3dNode = g_i3DManager:loadSharedI3DFile(topArmFilename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				local rootNode = getChildAt(i3dNode, 0)

				link(baseNode, rootNode)
				delete(i3dNode)
				setTranslation(rootNode, 0, 0, 0)

				local translationNode = getChildAt(rootNode, 0)
				local referenceNode = getChildAt(translationNode, 0)
				local topArm = {
					rotationNode = rootNode,
					rotZ = 0,
					rotY = 0,
					rotX = 0,
					translationNode = translationNode
				}
				local _, _, referenceDistance = getTranslation(referenceNode)
				topArm.referenceDistance = referenceDistance
				topArm.zScale = 1
				local zScale = MathUtil.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".topArm#zScale"), 1))

				if zScale < 0 then
					topArm.rotY = math.pi

					setRotation(rootNode, topArm.rotX, topArm.rotY, topArm.rotZ)
				end

				if getNumOfChildren(rootNode) > 1 then
					topArm.scaleNode = getChildAt(rootNode, 1)
					local scaleReferenceNode = getChildAt(topArm.scaleNode, 0)
					local _, _, scaleReferenceDistance = getTranslation(scaleReferenceNode)
					topArm.scaleReferenceDistance = scaleReferenceDistance
				end

				topArm.toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseName .. ".topArm#toggleVisibility"), false)

				if topArm.toggleVisibility then
					setVisibility(topArm.rotationNode, false)
				end

				local colorValueStr = getXMLString(xmlFile, baseName .. ".topArm#color")
				local colorValue = g_brandColorManager:getBrandColorByName(colorValueStr)

				if colorValue == nil then
					colorValue = StringUtil.getVectorNFromString(colorValueStr, 3)
				end

				local colorValue2Str = getXMLString(xmlFile, baseName .. ".topArm#color2")
				local colorValue2 = g_brandColorManager:getBrandColorByName(colorValue2Str)

				if colorValue2 == nil then
					colorValue2 = StringUtil.getVectorNFromString(colorValue2Str, 3)
				end

				local decalColorStr = getXMLString(xmlFile, baseName .. ".topArm#decalColor")
				local decalColor = g_brandColorManager:getBrandColorByName(decalColorStr)

				if decalColor == nil then
					decalColor = StringUtil.getVectorNFromString(decalColorStr, 3)
				end

				if decalColor == nil and colorValue ~= nil then
					local brightness = MathUtil.getBrightnessFromColor(colorValue[1], colorValue[2], colorValue[3])
					brightness = brightness > 0.075 and 1 or 0
					decalColor = {
						1 - brightness,
						1 - brightness,
						1 - brightness
					}
				end

				if colorValue ~= nil then
					local material = getXMLInt(xmlFile, baseName .. ".topArm#material")

					I3DUtil.setShaderParameterRec(rootNode, "colorMat0", colorValue[1], colorValue[2], colorValue[3], material or colorValue[4])
				end

				if colorValue2 ~= nil then
					local material2 = getXMLInt(xmlFile, baseName .. ".topArm#material2")

					I3DUtil.setShaderParameterRec(rootNode, "colorMat1", colorValue2[1], colorValue2[2], colorValue2[3], material2 or colorValue2[4])
				end

				if decalColor ~= nil then
					I3DUtil.setShaderParameterRec(rootNode, "colorMat2", decalColor[1], decalColor[2], decalColor[3], 1)
				end

				attacherJoint.topArm = topArm
			end
		end
	else
		local rotationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".topArm#rotationNode"), self.i3dMappings)
		local translationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".topArm#translationNode"), self.i3dMappings)
		local referenceNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".topArm#referenceNode"), self.i3dMappings)

		if rotationNode ~= nil then
			local topArm = {
				rotationNode = rotationNode
			}
			topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode)

			if translationNode ~= nil and referenceNode ~= nil then
				topArm.translationNode = translationNode
				local x, y, z = getTranslation(translationNode)

				if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
					g_logManager:xmlWarning(self.configFileName, "TopArm translation of attacherJoint '%s' is not 0/0/0!", baseName)
				end

				topArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
			end

			topArm.zScale = MathUtil.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".topArm#zScale"), 1))
			topArm.toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseName .. ".topArm#toggleVisibility"), false)

			if topArm.toggleVisibility then
				setVisibility(topArm.rotationNode, false)
			end

			attacherJoint.topArm = topArm
		end
	end

	local rotationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".bottomArm#rotationNode"), self.i3dMappings)
	local translationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".bottomArm#translationNode"), self.i3dMappings)
	local referenceNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".bottomArm#referenceNode"), self.i3dMappings)

	if rotationNode ~= nil then
		local bottomArm = {
			rotationNode = rotationNode,
			lastDirection = {
				0,
				0,
				0
			}
		}
		local startRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, baseName .. ".bottomArm#startRotation"), 3)

		if startRot ~= nil then
			bottomArm.rotZ = startRot[3]
			bottomArm.rotY = startRot[2]
			bottomArm.rotX = startRot[1]
		else
			bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(rotationNode)
		end

		if translationNode ~= nil and referenceNode ~= nil then
			bottomArm.translationNode = translationNode
			local x, y, z = getTranslation(translationNode)

			if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
				g_logManager:xmlWarning(self.configFileName, "BottomArm translation of attacherJoint '%s' is not 0/0/0!", baseName)
			end

			bottomArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
		end

		bottomArm.zScale = MathUtil.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".bottomArm#zScale"), 1))
		bottomArm.lockDirection = Utils.getNoNil(getXMLBool(xmlFile, baseName .. ".bottomArm#lockDirection"), true)
		bottomArm.toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseName .. ".bottomArm#toggleVisibility"), false)

		if bottomArm.toggleVisibility then
			setVisibility(bottomArm.rotationNode, false)
		end

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
			local toolbarFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. ".toolbar#filename"), "$data/shared/assets/toolbar.i3d")
			local i3dNode = g_i3DManager:loadSharedI3DFile(toolbarFilename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				local rootNode = getChildAt(i3dNode, 0)

				link(referenceNode, rootNode)
				delete(i3dNode)
				setTranslation(rootNode, 0, 0, 0)

				bottomArm.toolbar = rootNode

				setVisibility(rootNode, false)
			end
		end

		attacherJoint.bottomArm = bottomArm
	end

	if self.isClient then
		attacherJoint.sampleAttach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "attachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	attacherJoint.steeringBarLeftNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".steeringBars#leftNode"), self.i3dMappings)
	attacherJoint.steeringBarRightNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. ".steeringBars#rightNode"), self.i3dMappings)
	attacherJoint.changeObjects = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, attacherJoint.changeObjects, self.components, self)

	attacherJoint.additionalAttachment = {
		attacherJointDirection = getXMLInt(xmlFile, baseName .. ".additionalAttachment#attacherJointDirection")
	}
	attacherJoint.rootNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#rootNode"), self.i3dMappings), self.components[1].node)
	attacherJoint.rootNodeBackup = attacherJoint.rootNode
	attacherJoint.jointIndex = 0
	local t = getXMLFloat(xmlFile, baseName .. "#comboTime")

	if t ~= nil then
		table.insert(spec.attacherJointCombos.joints, {
			jointIndex = index + 1,
			time = MathUtil.clamp(t, 0, 1) * spec.attacherJointCombos.duration
		})
	end

	local schemaKey = baseName .. ".schema"

	if hasXMLProperty(xmlFile, schemaKey) then
		local x, y = StringUtil.getVectorFromString(getXMLString(xmlFile, schemaKey .. "#position"))
		local liftedOffsetX, liftedOffsetY = StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, schemaKey .. "#liftedOffset"), "0 5"))

		self.schemaOverlay:addAttacherJoint(x, y, math.rad(Utils.getNoNil(getXMLFloat(xmlFile, schemaKey .. "#rotation"), 0)), Utils.getNoNil(getXMLBool(xmlFile, schemaKey .. "#invertX"), false), liftedOffsetX, liftedOffsetY)
	else
		g_logManager:xmlWarning(self.configFileName, "Missing schema overlay attacherJoint '%s'!", baseName)
	end

	return true
end

function AttacherJoints:raiseActive(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:raiseActive()
		end
	end
end

function AttacherJoints:registerActionEvents(superFunc, excludedVehicle)
	local spec = self.spec_attacherJoints

	superFunc(self, excludedVehicle)

	if self ~= excludedVehicle then
		local selectedObject = self:getSelectedObject()

		if selectedObject ~= nil and self ~= selectedObject.vehicle and excludedVehicle ~= selectedObject.vehicle then
			selectedObject.vehicle:registerActionEvents()
		end

		for _, implement in pairs(spec.attachedImplements) do
			if implement.object ~= nil then
				implement.object:registerActionEvents(selectedObject.vehicle)
			end
		end
	end
end

function AttacherJoints:removeActionEvents(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:removeActionEvents()
		end
	end
end

function AttacherJoints:addToPhysics(superFunc)
	local spec = self.spec_attacherJoints

	if not superFunc(self) then
		return false
	end

	for _, implement in pairs(spec.attachedImplements) do
		if not implement.object.isHardAttached then
			self:createAttachmentJoint(implement)
		end
	end

	return true
end

function AttacherJoints:getTotalMass(superFunc, onlyGivenVehicle)
	local spec = self.spec_attacherJoints
	local mass = superFunc(self)

	if onlyGivenVehicle == nil or not onlyGivenVehicle then
		for _, implement in pairs(spec.attachedImplements) do
			local object = implement.object
			mass = mass + object:getTotalMass(onlyGivenVehicle)
		end
	end

	return mass
end

function AttacherJoints:addChildVehicles(superFunc, vehicles)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		implement.object:addChildVehicles(vehicles)
	end

	return superFunc(self, vehicles)
end

function AttacherJoints:getAirConsumerUsage(superFunc)
	local spec = self.spec_attacherJoints
	local usage = superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getAttachbleAirConsumerUsage ~= nil then
			usage = usage + object:getAttachbleAirConsumerUsage()
		end
	end

	return usage
end

function AttacherJoints:addVehicleToAIImplementList(superFunc, list)
	superFunc(self, list)

	for _, implement in pairs(self:getAttachedImplements()) do
		implement.object:addVehicleToAIImplementList(list)
	end
end

function AttacherJoints:getDirectionSnapAngle(superFunc)
	local spec = self.spec_attacherJoints
	local maxAngle = superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getDirectionSnapAngle ~= nil then
			maxAngle = math.max(maxAngle + object:getDirectionSnapAngle())
		end
	end

	return maxAngle
end

function AttacherJoints:getAICollisionTriggers(superFunc, collisionTriggers)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getAIImplementCollisionTriggers ~= nil then
			object:getAIImplementCollisionTriggers(collisionTriggers)
		end

		if object.getAICollisionTriggers ~= nil then
			object:getAICollisionTriggers(collisionTriggers)
		end
	end

	return superFunc(self)
end

function AttacherJoints:getFillLevelInformation(superFunc, fillLevelInformations)
	local spec = self.spec_attacherJoints

	superFunc(self, fillLevelInformations)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:getFillLevelInformation(fillLevelInformations)
		end
	end
end

function AttacherJoints:attachableAddToolCameras(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:attachableAddToolCameras()
		end
	end
end

function AttacherJoints:attachableRemoveToolCameras(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:attachableRemoveToolCameras()
		end
	end
end

function AttacherJoints:registerSelectableObjects(superFunc, selectableObjects)
	superFunc(self, selectableObjects)

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil then
			object:registerSelectableObjects(selectableObjects)
		end
	end
end

function AttacherJoints:getIsReadyForAutomatedTrainTravel(superFunc)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil and implement.object.getIsReadyForAutomatedTrainTravel ~= nil and not implement.object:getIsReadyForAutomatedTrainTravel() then
			return false
		end
	end

	return superFunc(self)
end

function AttacherJoints:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	local attacherJointIndicesString = Utils.getNoNil(getXMLString(xmlFile, key .. "#attacherJointIndices"), "")
	group.attacherJointIndices = {
		StringUtil.getVectorFromString(attacherJointIndicesString)
	}

	return true
end

function AttacherJoints:getIsDashboardGroupActive(superFunc, group)
	local hasAttachment = #group.attacherJointIndices == 0

	for _, jointIndex in ipairs(group.attacherJointIndices) do
		if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
			hasAttachment = true
		end
	end

	return superFunc(self, group) and hasAttachment
end

function AttacherJoints:isDetachAllowed(superFunc)
	local detachAllowed, warning, showWarning = superFunc(self)

	if not detachAllowed then
		return detachAllowed, warning, showWarning
	end

	local spec = self.spec_attacherJoints

	for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
		if not attacherJoint.allowDetachingWhileLifted and not attacherJoint.moveDown then
			local implement = self:getImplementByJointDescIndex(attacherJointIndex)

			if implement ~= nil then
				local inputAttacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)

				if inputAttacherJoint ~= nil and not inputAttacherJoint.forceAllowDetachWhileLifted then
					return false, string.format(g_i18n:getText("warning_lowerImplementFirst"), implement.object.typeDesc)
				end
			end
		end
	end

	return true
end

function AttacherJoints:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_attacherJoints

	for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
		if not attacherJoint.allowFoldingWhileAttached and attacherJoint.jointIndex ~= 0 then
			return false
		end
	end

	return superFunc(self, direction, onAiTurnOn)
end

function AttacherJoints:getIsWheelFoliageDestructionAllowed(superFunc, wheel)
	if not superFunc(self, wheel) then
		return false
	end

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil and object.getBlockFoliageDestruction ~= nil and object:getBlockFoliageDestruction() then
			return false
		end
	end

	return true
end

function AttacherJoints:getAreControlledActionsAllowed(superFunc)
	local allowed, warning = superFunc(self)

	if not allowed then
		return false, warning
	end

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil and object.getAreControlledActionsAllowed ~= nil then
			allowed, warning = object:getAreControlledActionsAllowed()

			if not allowed then
				return false, warning
			end
		end
	end

	return true, warning
end

function AttacherJoints:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_attacherJoints

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if table.getn(spec.attacherJoints) > 0 then
				local selectedImplement = self:getSelectedImplement()

				if selectedImplement ~= nil and selectedImplement.object ~= self then
					for _, attachedImplement in pairs(spec.attachedImplements) do
						if attachedImplement == selectedImplement then
							selectedImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, selectedImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)
						end
					end
				end

				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.LOWER_ALL_IMPLEMENTS, self, AttacherJoints.actionEventLowerAllImplements, false, true, false, true, nil, , true)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end

			if self:getSelectedVehicle() == self then
				local state, _ = self:registerSelfLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, self, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)

				if (state == nil or not state) and #spec.attachedImplements == 1 then
					local firstImplement = spec.attachedImplements[1]

					if firstImplement ~= nil then
						firstImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, firstImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)
					end
				end
			end

			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ATTACH, self, AttacherJoints.actionEventAttach, false, true, false, true, nil, , true)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
		end
	end
end

function AttacherJoints:onActivate()
	self:activateAttachments()
end

function AttacherJoints:onDeactivate()
	self:deactivateAttachments()

	if self.isClient then
		local spec = self.spec_attacherJoints

		g_soundManager:stopSample(spec.samples.hydraulic)

		spec.isHydraulicSamplePlaying = false
	end
end

function AttacherJoints:onReverseDirectionChanged(direction)
	local spec = self.spec_attacherJoints

	if spec.attacherJointCombos ~= nil then
		for _, joint in pairs(spec.attacherJointCombos.joints) do
			joint.time = math.abs(joint.time - spec.attacherJointCombos.duration)
		end
	end
end

function AttacherJoints:onDeactivateLights()
	self:deactivateAttachmentsLights()
end

function AttacherJoints:onStateChange(state, data)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:raiseStateChange(state, data)
		end
	end

	if state == Vehicle.STATE_CHANGE_LOWER_ALL_IMPLEMENTS and table.getn(spec.attacherJoints) > 0 then
		self:startAttacherJointCombo()
	end
end

function AttacherJoints:onLightsTypesMaskChanged(lightsTypesMask)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setLightsTypesMask ~= nil then
			vehicle:setLightsTypesMask(lightsTypesMask, true, true)
		end
	end
end

function AttacherJoints:onTurnLightStateChanged(state)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setTurnLightState ~= nil then
			vehicle:setTurnLightState(state, true, true)
		end
	end
end

function AttacherJoints:onBrakeLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setBrakeLightsVisibility ~= nil then
			vehicle:setBrakeLightsVisibility(visibility)
		end
	end
end

function AttacherJoints:onReverseLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setReverseLightsVisibility ~= nil then
			vehicle:setReverseLightsVisibility(visibility)
		end
	end
end

function AttacherJoints:onBeaconLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setBeaconLightsVisibility ~= nil then
			vehicle:setBeaconLightsVisibility(visibility, true, true)
		end
	end
end

function AttacherJoints:onBrake(brakePedal)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.brake ~= nil then
			vehicle:brake(brakePedal)
		end
	end
end

function AttacherJoints:onTurnedOn()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle

			if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
				vehicle:setIsTurnedOn(true, true)
			end
		end
	end
end

function AttacherJoints:onTurnedOff()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle

			if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
				vehicle:setIsTurnedOn(false, true)
			end
		end
	end
end

function AttacherJoints:onLeaveVehicle()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			SpecializationUtil.raiseEvent(vehicle, "onLeaveRootVehicle")
		end
	end
end

function AttacherJoints.findVehicleInAttachRange(vehicle, maxDistanceSq, maxAngle)
	local spec = vehicle.spec_attacherJoints

	if spec ~= nil then
		local minDist = math.huge
		local minDistY = math.huge
		local attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex = nil

		if vehicle.getAttachedImplements ~= nil then
			local implements = vehicle:getAttachedImplements()

			for _, implement in pairs(implements) do
				if implement.object ~= nil then
					attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex = AttacherJoints.findVehicleInAttachRange(implement.object, maxDistanceSq, maxAngle)

					if attacherVehicle ~= nil then
						return attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex
					end
				end
			end
		end

		for attacherJointIndex, attacherJoint in pairs(spec.attacherJoints) do
			if spec.attacherJoints[attacherJointIndex].jointIndex == 0 then
				for _, vehicle2 in pairs(g_currentMission.vehicles) do
					if vehicle2 ~= vehicle and vehicle2.getInputAttacherJoints ~= nil and (vehicle2:getActiveInputAttacherJointDescIndex() == nil or vehicle2:getAllowMultipleAttachments()) then
						local inputAttacherJoints = vehicle2:getInputAttacherJoints()

						if inputAttacherJoints ~= nil then
							for inputAttacherJointIndex, inputAttacherJoint in pairs(inputAttacherJoints) do
								if attacherJoint.jointType == inputAttacherJoint.jointType then
									local correctDirection = true

									if inputAttacherJoint.forcedAttachingDirection ~= 0 and attacherJoint.additionalAttachment.attacherJointDirection ~= nil then
										correctDirection = inputAttacherJoint.forcedAttachingDirection == attacherJoint.additionalAttachment.attacherJointDirection
									end

									if correctDirection then
										local x, y, z = localToLocal(inputAttacherJoint.node, attacherJoint.jointTransform, 0, 0, 0)
										local distSq = MathUtil.vector2LengthSq(x, z)
										local distSqY = y * y

										if distSq < maxDistanceSq and distSq < minDist and distSqY < maxDistanceSq * 2 and distSqY < minDistY then
											local dx, _, _ = localDirectionToLocal(inputAttacherJoint.node, attacherJoint.jointTransform, 1, 0, 0)

											if maxAngle < dx then
												minDist = distSq
												minDistY = distSqY
												attacherVehicle = vehicle
												attacherVehicleJointDescIndex = attacherJointIndex
												attachable = vehicle2
												attachableJointDescIndex = inputAttacherJointIndex
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		return attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex
	end

	return nil, , , 
end

function AttacherJoints:actionEventAttach(actionName, inputValue, callbackState, isAnalog)
	local info = self.spec_attacherJoints.attachableInfo

	if info.attachable ~= nil then
		local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)

		if attachAllowed then
			self:attachImplementFromInfo(info)
		elseif warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	else
		local object = self:getSelectedVehicle()

		if object ~= nil and object ~= self and object.isDetachAllowed ~= nil then
			local detachAllowed, warning, showWarning = object:isDetachAllowed()

			if detachAllowed then
				if object.getAttacherVehicle ~= nil then
					local attacherVehicle = object:getAttacherVehicle()

					if attacherVehicle ~= nil then
						attacherVehicle:detachImplementByObject(object)
					end
				end
			elseif showWarning == nil or showWarning then
				g_currentMission:showBlinkingWarning(warning or g_i18n:getText("warning_detachNotAllowed"), 2000)
			end
		end
	end
end

function AttacherJoints:actionEventLowerImplement(actionName, inputValue, callbackState, isAnalog)
	if self.getAttacherVehicle ~= nil then
		self:getAttacherVehicle():handleLowerImplementEvent()
	end
end

function AttacherJoints:actionEventLowerAllImplements(actionName, inputValue, callbackState, isAnalog)
	self:startAttacherJointCombo(true)
	self:getRootVehicle():raiseStateChange(Vehicle.STATE_CHANGE_LOWER_ALL_IMPLEMENTS)
end
