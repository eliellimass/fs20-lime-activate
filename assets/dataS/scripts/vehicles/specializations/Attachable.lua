Attachable = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onPreAttach")
		SpecializationUtil.registerEvent(vehicleType, "onPostAttach")
		SpecializationUtil.registerEvent(vehicleType, "onPreDetach")
		SpecializationUtil.registerEvent(vehicleType, "onPostDetach")
		SpecializationUtil.registerEvent(vehicleType, "onSetLowered")
		SpecializationUtil.registerEvent(vehicleType, "onSetLoweredAll")
		SpecializationUtil.registerEvent(vehicleType, "onLeaveRootVehicle")
	end
}

function Attachable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadInputAttacherJoint", Attachable.loadInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJointByJointDescIndex", Attachable.getInputAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherVehicle", Attachable.getAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJoints", Attachable.getInputAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttachedTo", Attachable.getIsAttachedTo)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJointDescIndex", Attachable.getActiveInputAttacherJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJoint", Attachable.getActiveInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsLowering", Attachable.getAllowsLowering)
	SpecializationUtil.registerFunction(vehicleType, "loadSupportAnimationFromXML", Attachable.loadSupportAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportAnimationAllowed", Attachable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsImplementChainLowered", Attachable.getIsImplementChainLowered)
	SpecializationUtil.registerFunction(vehicleType, "getIsInWorkPosition", Attachable.getIsInWorkPosition)
	SpecializationUtil.registerFunction(vehicleType, "getAttachbleAirConsumerUsage", Attachable.getAttachbleAirConsumerUsage)
	SpecializationUtil.registerFunction(vehicleType, "isDetachAllowed", Attachable.isDetachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "isAttachAllowed", Attachable.isAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsInputAttacherActive", Attachable.getIsInputAttacherActive)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringAxleBaseVehicle", Attachable.getSteeringAxleBaseVehicle)
	SpecializationUtil.registerFunction(vehicleType, "loadSteeringAxleFromXML", Attachable.loadSteeringAxleFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSteeringAxleAllowed", Attachable.getIsSteeringAxleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "attachableAddToolCameras", Attachable.attachableAddToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "attachableRemoveToolCameras", Attachable.attachableRemoveToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "preAttach", Attachable.preAttach)
	SpecializationUtil.registerFunction(vehicleType, "postAttach", Attachable.postAttach)
	SpecializationUtil.registerFunction(vehicleType, "preDetach", Attachable.preDetach)
	SpecializationUtil.registerFunction(vehicleType, "postDetach", Attachable.postDetach)
	SpecializationUtil.registerFunction(vehicleType, "setLowered", Attachable.setLowered)
	SpecializationUtil.registerFunction(vehicleType, "setLoweredAll", Attachable.setLoweredAll)
	SpecializationUtil.registerFunction(vehicleType, "setIsAdditionalAttachment", Attachable.setIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAdditionalAttachment", Attachable.getIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "setIsSupportVehicle", Attachable.setIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportVehicle", Attachable.getIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "registerLoweringActionEvent", Attachable.registerLoweringActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "getLoweringActionEventState", Attachable.getLoweringActionEventState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowMultipleAttachments", Attachable.getAllowMultipleAttachments)
	SpecializationUtil.registerFunction(vehicleType, "resolveMultipleAttachments", Attachable.resolveMultipleAttachments)
end

function Attachable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRootVehicle", Attachable.getRootVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Attachable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Attachable.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Attachable.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Attachable.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Attachable.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Attachable.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Attachable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Attachable.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", Attachable.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Attachable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Attachable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "mountDynamic", Attachable.mountDynamic)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwner", Attachable.getOwner)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", Attachable.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUpdatePriority", Attachable.getUpdatePriority)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Attachable.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowOnMap", Attachable.getShowOnMap)
end

function Attachable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Attachable)
end

function Attachable.initSpecialization()
	g_configurationManager:addConfigurationType("inputAttacherJoint", g_i18n:getText("configuration_inputAttacherJoint"), "attachable", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function Attachable:onLoad(savegame)
	local spec = self.spec_attachable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attacherJoint", "vehicle.inputAttacherJoints.inputAttacherJoint")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.needsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#needsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.allowsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#allowsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.isDefaultLowered", "vehicle.inputAttacherJoints.inputAttacherJoint#isDefaultLowered")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.forceSelectionOnAttach#value", "vehicle.inputAttacherJoints.inputAttacherJoint#forceSelectionOnAttach")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.topReferenceNode#index", "vehicle.attacherJoint#topReferenceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attachRootNode#index", "vehicle.attacherJoint#rootNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.inputAttacherJoints", "vehicle.attachable.inputAttacherJoints")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.inputAttacherJointConfigurations", "vehicle.attachable.inputAttacherJointConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.brakeForce", "vehicle.attachable.brakeForce")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.steeringAxleAngleScale", "vehicle.attachable.steeringAxleAngleScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.support", "vehicle.attachable.support")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.lowerAnimation", "vehicle.attachable.lowerAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.toolCameras", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attachable.toolCameras#count", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attachable.toolCameras.toolCamera1", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attachable.toolCameras.toolCamera2", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.attachable.toolCameras.toolCamera3", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.foldable.foldingParts#onlyFoldOnDetach", "vehicle.attachable#allowFoldingWhileAttached")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.attachable.airConsumer#usage (is now in usage per second at full brake power)")

	spec.attacherJoint = nil
	spec.inputAttacherJoints = {}
	local i = 0

	while true do
		local key = string.format("vehicle.attachable.inputAttacherJoints.inputAttacherJoint(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local inputAttacherJoint = {}

		if self:loadInputAttacherJoint(self.xmlFile, key, inputAttacherJoint, i) then
			table.insert(spec.inputAttacherJoints, inputAttacherJoint)
		end

		i = i + 1
	end

	if self.configurations.inputAttacherJoint ~= nil then
		local attacherConfigs = string.format("vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(%d)", self.configurations.inputAttacherJoint - 1)
		local i = 0

		while true do
			local baseName = string.format(attacherConfigs .. ".inputAttacherJoint(%d)", i)

			if not hasXMLProperty(self.xmlFile, baseName) then
				break
			end

			local inputAttacherJoint = {}

			if self:loadInputAttacherJoint(self.xmlFile, baseName, inputAttacherJoint, i) then
				table.insert(spec.inputAttacherJoints, inputAttacherJoint)
			end

			i = i + 1
		end

		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration", self.configurations.inputAttacherJoint, self.components, self)
	end

	spec.brakeForce = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.attachable.brakeForce"), 0) * 10
	spec.airConsumerUsage = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.attachable.airConsumer#usage"), 0)
	spec.allowFoldingWhileAttached = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.attachable#allowFoldingWhileAttached"), true)
	spec.allowFoldingWhileLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.attachable#allowFoldingWhileLowered"), true)
	spec.updateWheels = true
	spec.updateSteeringAxleAngle = true
	spec.isSelected = false
	spec.attachTime = 0
	spec.steeringAxleAngle = 0
	spec.steeringAxleTargetAngle = 0

	self:loadSteeringAxleFromXML(spec, self.xmlFile, "vehicle.attachable.steeringAxleAngleScale")

	spec.supportAnimations = {}
	i = 0

	while true do
		local baseKey = string.format("vehicle.attachable.support(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local entry = {}

		if self:loadSupportAnimationFromXML(entry, self.xmlFile, baseKey) then
			table.insert(spec.supportAnimations, entry)
		end

		i = i + 1
	end

	spec.lowerAnimation = getXMLString(self.xmlFile, "vehicle.attachable.lowerAnimation#name")
	spec.lowerAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.attachable.lowerAnimation#speed"), 1)
	spec.lowerAnimationDirectionOnDetach = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.attachable.lowerAnimation#directionOnDetach"), 0)
	spec.lowerAnimationDefaultLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.attachable.lowerAnimation#defaultLowered"), false)
	spec.toolCameras = {}
	i = 0

	while true do
		local cameraKey = string.format("vehicle.attachable.toolCameras.toolCamera(%d)", i)

		if not hasXMLProperty(self.xmlFile, cameraKey) then
			break
		end

		local camera = VehicleCamera:new(self)

		if camera:loadFromXML(self.xmlFile, cameraKey) then
			table.insert(spec.toolCameras, camera)
		end

		i = i + 1
	end

	spec.isHardAttached = false
	spec.isAdditionalAttachment = false
end

function Attachable:onPostLoad(savegame)
	local spec = self.spec_attachable

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if not supportAnimation.delayedOnLoad and self:getIsSupportAnimationAllowed(supportAnimation) then
			self:playAnimation(supportAnimation.animationName, 1, nil, true)
			AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999)
		end
	end

	if savegame ~= nil and not savegame.resetVehicles then
		if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
			local lowerAnimTime = getXMLFloat(savegame.xmlFile, savegame.key .. ".attachable#lowerAnimTime")

			if lowerAnimTime ~= nil then
				local speed = 1

				if lowerAnimTime < 0.5 then
					speed = -1
				end

				self:playAnimation(spec.lowerAnimation, speed, nil, true)
				self:setAnimationTime(spec.lowerAnimation, lowerAnimTime)
				AnimatedVehicle.updateAnimationByName(self, spec.lowerAnimation, 9999999)

				if self.updateCylinderedInitial ~= nil then
					self:updateCylinderedInitial(false)
				end
			end
		end
	elseif spec.lowerAnimationDefaultLowered then
		self:playAnimation(spec.lowerAnimation, 1, nil, true)
		AnimatedVehicle.updateAnimationByName(self, spec.lowerAnimation, 9999999)
	end

	for _, inputAttacherJoint in pairs(spec.inputAttacherJoints) do
		if self.getMovingPartByNode ~= nil then
			if inputAttacherJoint.steeringBarLeftNode ~= nil then
				local movingPart = self:getMovingPartByNode(inputAttacherJoint.steeringBarLeftNode)

				if movingPart ~= nil then
					inputAttacherJoint.steeringBarLeftMovingPart = movingPart
				else
					inputAttacherJoint.steeringBarLeftNode = nil
				end
			end

			if inputAttacherJoint.steeringBarRightNode ~= nil then
				local movingPart = self:getMovingPartByNode(inputAttacherJoint.steeringBarRightNode)

				if movingPart ~= nil then
					inputAttacherJoint.steeringBarRightMovingPart = movingPart
				else
					inputAttacherJoint.steeringBarRightNode = nil
				end
			end
		else
			inputAttacherJoint.steeringBarLeftNode = nil
			inputAttacherJoint.steeringBarRightNode = nil
		end
	end

	if self.brake ~= nil then
		self:brake(spec.brakeForce, true)
	end

	if #spec.inputAttacherJoints > 0 then
		g_currentMission:addAttachableVehicle(self)
	end
end

function Attachable:onLoadFinished(savegame)
	local spec = self.spec_attachable

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if supportAnimation.delayedOnLoad and self:getIsSupportAnimationAllowed(supportAnimation) then
			self:playAnimation(supportAnimation.animationName, 1, nil, true)
			AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999)
		end
	end
end

function Attachable:onPreDelete()
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		spec.attacherVehicle:detachImplementByObject(self, true)
	end

	g_currentMission:removeAttachableVehicle(self)
end

function Attachable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_attachable

	if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
		local lowerAnimTime = self:getAnimationTime(spec.lowerAnimation)

		setXMLFloat(xmlFile, key .. "#lowerAnimTime", lowerAnimTime)
	end
end

function Attachable:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local object = NetworkUtil.readNodeObject(streamId)
		local inputJointDescIndex = streamReadInt8(streamId)
		local jointDescIndex = streamReadInt8(streamId)
		local moveDown = streamReadBool(streamId)
		local implementIndex = streamReadInt8(streamId)

		if object ~= nil then
			object:attachImplement(self, inputJointDescIndex, jointDescIndex, true, implementIndex)
			object:setJointMoveDown(jointDescIndex, moveDown, true)
		end
	end
end

function Attachable:onWriteStream(streamId, connection)
	local spec = self.spec_attachable

	streamWriteBool(streamId, spec.attacherVehicle ~= nil)

	if spec.attacherVehicle ~= nil then
		local attacherJointVehicleSpec = spec.attacherVehicle.spec_attacherJoints
		local implementIndex = spec.attacherVehicle:getImplementIndexByObject(self)
		local implement = attacherJointVehicleSpec.attachedImplements[implementIndex]
		local inputJointDescIndex = spec.inputAttacherJointDescIndex
		local jointDescIndex = implement.jointDescIndex
		local jointDesc = attacherJointVehicleSpec.attacherJoints[jointDescIndex]
		local moveDown = jointDesc.moveDown

		NetworkUtil.writeNodeObject(streamId, spec.attacherVehicle)
		streamWriteInt8(streamId, inputJointDescIndex)
		streamWriteInt8(streamId, jointDescIndex)
		streamWriteBool(streamId, moveDown)
		streamWriteInt8(streamId, implementIndex)
	end
end

function Attachable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attachable

	if spec.updateSteeringAxleAngle and self:getLastSpeed() > 0.1 then
		local baseVehicle = self:getSteeringAxleBaseVehicle()

		if baseVehicle ~= nil and (self.movingDirection >= 0 or spec.steeringAxleUpdateBackwards) then
			local yRot = Utils.getYRotationBetweenNodes(self.steeringAxleNode, baseVehicle.steeringAxleNode)

			if math.abs(yRot) > 1.57 then
				if yRot > 0 then
					yRot = yRot - 3.14
				else
					yRot = yRot + 3.14
				end
			end

			local startSpeed = spec.steeringAxleAngleScaleStart
			local endSpeed = spec.steeringAxleAngleScaleEnd
			local scale = MathUtil.clamp(1 + (self:getLastSpeed() - startSpeed) * 1 / (startSpeed - endSpeed), 0, 1)
			spec.steeringAxleTargetAngle = yRot * scale
		elseif self:getLastSpeed() > 0.2 then
			spec.steeringAxleTargetAngle = 0
		end

		if not self:getIsSteeringAxleAllowed() then
			spec.steeringAxleTargetAngle = 0
		end

		local dir = MathUtil.sign(spec.steeringAxleTargetAngle - spec.steeringAxleAngle)

		if dir == 1 then
			spec.steeringAxleAngle = math.min(spec.steeringAxleAngle + dir * dt * spec.steeringAxleAngleSpeed, spec.steeringAxleTargetAngle)
		else
			spec.steeringAxleAngle = math.max(spec.steeringAxleAngle + dir * dt * spec.steeringAxleAngleSpeed, spec.steeringAxleTargetAngle)
		end

		if spec.steeringAxleTargetNode ~= nil then
			local angle = MathUtil.clamp(spec.steeringAxleAngle, spec.steeringAxleAngleMinRot, spec.steeringAxleAngleMaxRot)

			setRotation(spec.steeringAxleTargetNode, 0, angle * spec.steeringAxleDirection, 0)
			self:setMovingToolDirty(spec.steeringAxleTargetNode)
		end
	end
end

function Attachable:loadInputAttacherJoint(xmlFile, key, inputAttacherJoint, index)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#indexVisual", key .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#ptoInputNode", "vehicle.powerTakeOffs.input")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#lowerDistanceToGround", key .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#upperDistanceToGround", key .. ".distanceToGround#upper")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node ~= nil then
		inputAttacherJoint.node = node
		inputAttacherJoint.heightNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".heightNode#node"), self.i3dMappings)

		if inputAttacherJoint.heightNode ~= nil then
			inputAttacherJoint.heightNodeOffset = {
				localToLocal(inputAttacherJoint.heightNode, node, 0, 0, 0)
			}
		end

		local jointTypeStr = getXMLString(xmlFile, key .. "#jointType")
		local jointType = nil

		if jointTypeStr ~= nil then
			jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]

			if jointType == nil then
				g_logManager:xmlWarning(self.configFileName, "Invalid jointType '%s' for inputAttacherJoint '%s'!", tostring(jointTypeStr), key)
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Missing jointType for inputAttacherJoint '%s'!", key)
		end

		if jointType == nil then
			local needsTrailerJoint = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsTrailerJoint"), false)
			local needsLowTrailerJoint = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsLowJoint"), false)

			if needsTrailerJoint then
				if needsLowTrailerJoint then
					jointType = AttacherJoints.JOINTTYPE_TRAILERLOW
				else
					jointType = AttacherJoints.JOINTTYPE_TRAILER
				end
			else
				jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
			end
		end

		inputAttacherJoint.jointType = jointType
		inputAttacherJoint.jointOrigTrans = {
			getTranslation(inputAttacherJoint.node)
		}
		inputAttacherJoint.jointOrigOffsetComponent = {
			localToLocal(self:getParentComponent(inputAttacherJoint.node), inputAttacherJoint.node, 0, 0, 0)
		}
		inputAttacherJoint.jointOrigDirOffsetComponent = {
			localDirectionToLocal(self:getParentComponent(inputAttacherJoint.node), inputAttacherJoint.node, 0, 0, 1)
		}
		inputAttacherJoint.topReferenceNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#topReferenceNode"), self.i3dMappings)
		inputAttacherJoint.rootNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#rootNode"), self.i3dMappings), self.components[1].node)
		inputAttacherJoint.rootNodeBackup = inputAttacherJoint.rootNode
		inputAttacherJoint.allowsDetaching = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsDetaching"), true)
		inputAttacherJoint.fixedRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fixedRotation"), false)
		inputAttacherJoint.hardAttach = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hardAttach"), false)

		if inputAttacherJoint.hardAttach and #self.components > 1 then
			g_logManager:xmlWarning(self.configFileName, "hardAttach only available for single component vehicles! InputAttacherJoint '%s'!", key)

			inputAttacherJoint.hardAttach = false
		end

		inputAttacherJoint.visualNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#nodeVisual"), self.i3dMappings)

		if inputAttacherJoint.hardAttach and inputAttacherJoint.visualNode ~= nil then
			inputAttacherJoint.visualNodeData = {
				parent = getParent(inputAttacherJoint.visualNode),
				translation = {
					getTranslation(inputAttacherJoint.visualNode)
				},
				rotation = {
					getRotation(inputAttacherJoint.visualNode)
				},
				index = getChildIndex(inputAttacherJoint.visualNode)
			}
		end

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT or jointType == AttacherJoints.JOINTTYPE_CUTTER then
			if getXMLFloat(xmlFile, key .. ".distanceToGround#lower") == nil then
				g_logManager:xmlWarning(self.configFileName, "Missing '.distanceToGround#lower' for inputAttacherJoint '%s'!", key)
			end

			if getXMLFloat(xmlFile, key .. ".distanceToGround#upper") == nil then
				g_logManager:xmlWarning(self.configFileName, "Missing '.distanceToGround#upper' for inputAttacherJoint '%s'!", key)
			end
		end

		inputAttacherJoint.lowerDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".distanceToGround#lower"), 0.7)
		inputAttacherJoint.upperDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".distanceToGround#upper"), 1)

		if inputAttacherJoint.upperDistanceToGround < inputAttacherJoint.lowerDistanceToGround then
			g_logManager:xmlWarning(self.configFileName, "distanceToGround#lower may not be larger than distanceToGround#upper for inputAttacherJoint '%s'. Switching values!", key)

			local copy = inputAttacherJoint.lowerDistanceToGround
			inputAttacherJoint.lowerDistanceToGround = inputAttacherJoint.upperDistanceToGround
			inputAttacherJoint.upperDistanceToGround = copy
		end

		inputAttacherJoint.lowerRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#lowerRotationOffset"), 0))
		local defaultUpperRotationOffset = 8

		if jointType == AttacherJoints.JOINTTYPE_CUTTER or jointType == AttacherJoints.JOINTTYPE_WHEELLOADER or jointType == AttacherJoints.JOINTTYPE_TELEHANDLER or jointType == AttacherJoints.JOINTTYPE_FRONTLOADER or jointType == AttacherJoints.JOINTTYPE_LOADERFORK then
			defaultUpperRotationOffset = 0
		end

		inputAttacherJoint.upperRotationOffset = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#upperRotationOffset"), defaultUpperRotationOffset))
		inputAttacherJoint.allowsJointRotLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsJointRotLimitMovement"), true)
		inputAttacherJoint.allowsJointTransLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsJointTransLimitMovement"), true)
		inputAttacherJoint.needsToolbar = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsToolbar"), false)

		if inputAttacherJoint.needsToolbar and jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
			g_logManager:xmlWarning(self.configFileName, "'needsToolbar' requires jointType 'implement' for inputAttacherJoint '%s'!", key)

			inputAttacherJoint.needsToolbar = false
		end

		inputAttacherJoint.steeringBarLeftNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#steeringBarLeftNode"), self.i3dMappings)
		inputAttacherJoint.steeringBarRightNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#steeringBarRightNode"), self.i3dMappings)
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#upperRotLimitScale"))
		inputAttacherJoint.upperRotLimitScale = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#lowerRotLimitScale"))

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
			inputAttacherJoint.lowerRotLimitScale = {
				Utils.getNoNil(x, 0),
				Utils.getNoNil(y, 0),
				Utils.getNoNil(z, 1)
			}
		else
			inputAttacherJoint.lowerRotLimitScale = {
				Utils.getNoNil(x, 1),
				Utils.getNoNil(y, 1),
				Utils.getNoNil(z, 1)
			}
		end

		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#upperTransLimitScale"))
		inputAttacherJoint.upperTransLimitScale = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#lowerTransLimitScale"))
		inputAttacherJoint.lowerTransLimitScale = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitSpring"))
		inputAttacherJoint.rotLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitDamping"))
		inputAttacherJoint.rotLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitForceLimit"))
		inputAttacherJoint.rotLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitSpring"))
		inputAttacherJoint.transLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitDamping"))
		inputAttacherJoint.transLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitForceLimit"))
		inputAttacherJoint.transLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		inputAttacherJoint.attacherHeight = getXMLFloat(xmlFile, key .. "#attacherHeight")

		if inputAttacherJoint.attacherHeight == nil then
			if jointType == AttacherJoints.JOINTTYPE_TRAILER then
				inputAttacherJoint.attacherHeight = 0.9
			elseif jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
				inputAttacherJoint.attacherHeight = 0.55
			end
		end

		local defaultNeedsLowering = true
		local defaultAllowsLowering = false

		if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_TRAILER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
			defaultNeedsLowering = false
		end

		if inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILER and inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERLOW then
			defaultAllowsLowering = true
		end

		inputAttacherJoint.needsLowering = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsLowering"), defaultNeedsLowering)
		inputAttacherJoint.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsLowering"), defaultAllowsLowering)
		inputAttacherJoint.isDefaultLowered = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDefaultLowered"), false)
		inputAttacherJoint.useFoldingLoweredState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useFoldingLoweredState"), false)
		inputAttacherJoint.forceSelection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceSelectionOnAttach"), true)
		inputAttacherJoint.forceAllowDetachWhileLifted = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceAllowDetachWhileLifted"), false)
		inputAttacherJoint.forcedAttachingDirection = Utils.getNoNil(getXMLInt(xmlFile, key .. "#forcedAttachingDirection"), 0)
		inputAttacherJoint.turnOnAllowed = Utils.getNoNil(getXMLBool(xmlFile, key .. "#turnOnAllowed"), true)
		inputAttacherJoint.dependentAttacherJoints = {}
		local k = 0

		while true do
			local dependentKey = string.format(key .. ".dependentAttacherJoint(%d)", k)

			if not hasXMLProperty(xmlFile, dependentKey) then
				break
			end

			local attacherJointIndex = getXMLInt(xmlFile, dependentKey .. "#attacherJointIndex")

			if attacherJointIndex ~= nil then
				table.insert(inputAttacherJoint.dependentAttacherJoints, attacherJointIndex)
			end

			k = k + 1
		end

		if inputAttacherJoint.hardAttach then
			inputAttacherJoint.needsLowering = false
			inputAttacherJoint.allowsLowering = false
			inputAttacherJoint.isDefaultLowered = false
			inputAttacherJoint.upperRotationOffset = 0
		end

		inputAttacherJoint.changeObjects = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, inputAttacherJoint.changeObjects, self.components, self)

		inputAttacherJoint.additionalObjects = {}
		local i = 0

		while true do
			local baseKey = string.format("%s.additionalObjects.additionalObject(%d)", key, i)

			if not hasXMLProperty(xmlFile, baseKey) then
				break
			end

			local entry = {
				node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#node"), self.i3dMappings),
				attacherVehiclePath = getXMLString(xmlFile, baseKey .. "#attacherVehiclePath")
			}

			if entry.node ~= nil and entry.attacherVehiclePath ~= nil then
				entry.attacherVehiclePath = NetworkUtil.convertToNetworkFilename(entry.attacherVehiclePath)

				table.insert(inputAttacherJoint.additionalObjects, entry)
			end

			i = i + 1
		end

		inputAttacherJoint.additionalAttachment = {}
		local filename = getXMLString(xmlFile, key .. ".additionalAttachment#filename")

		if filename ~= nil then
			inputAttacherJoint.additionalAttachment.filename = Utils.getFilename(filename, self.customEnvironment)
		end

		inputAttacherJoint.additionalAttachment.inputAttacherJointIndex = getXMLInt(xmlFile, key .. ".additionalAttachment#inputAttacherJointIndex") or 1
		inputAttacherJoint.additionalAttachment.needsLowering = Utils.getNoNil(getXMLBool(xmlFile, key .. ".additionalAttachment#needsLowering"), false)
		local additionalJointTypeStr = getXMLString(xmlFile, key .. ".additionalAttachment#jointType")
		local additionalJointType = nil

		if additionalJointTypeStr ~= nil then
			additionalJointType = AttacherJoints.jointTypeNameToInt[additionalJointTypeStr]

			if additionalJointType == nil then
				g_logManager:xmlWarning(self.configFileName, "Invalid jointType '%s' for additonal implement '%s'!", tostring(additionalJointTypeStr), inputAttacherJoint.additionalAttachment.filename)
			end
		end

		inputAttacherJoint.additionalAttachment.jointType = additionalJointType or AttacherJoints.JOINTTYPE_IMPLEMENT

		return true
	end

	return false
end

function Attachable:getInputAttacherJointByJointDescIndex(index)
	return self.spec_attachable.inputAttacherJoints[index]
end

function Attachable:getAttacherVehicle()
	return self.spec_attachable.attacherVehicle
end

function Attachable:getInputAttacherJoints()
	return self.spec_attachable.inputAttacherJoints
end

function Attachable:getIsAttachedTo(vehicle)
	if vehicle == self then
		return true
	end

	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		if spec.attacherVehicle == vehicle then
			return true
		end

		if spec.attacherVehicle.getIsAttachedTo ~= nil then
			return spec.attacherVehicle:getIsAttachedTo(vehicle)
		end
	end

	return false
end

function Attachable:getActiveInputAttacherJointDescIndex()
	return self.spec_attachable.inputAttacherJointDescIndex
end

function Attachable:getActiveInputAttacherJoint()
	return self.spec_attachable.attacherJoint
end

function Attachable:getAllowsLowering()
	local spec = self.spec_attachable

	if spec.isAdditionalAttachment and not spec.additionalAttachmentNeedsLowering then
		return false, nil
	end

	local inputAttacherJoint = self:getActiveInputAttacherJoint()

	if inputAttacherJoint ~= nil and not inputAttacherJoint.allowsLowering then
		return false, nil
	end

	return true, nil
end

function Attachable:loadSupportAnimationFromXML(supportAnimation, xmlFile, key)
	supportAnimation.animationName = getXMLString(xmlFile, key .. "#animationName")
	supportAnimation.delayedOnLoad = Utils.getNoNil(getXMLBool(xmlFile, key .. "#delayedOnLoad"), false)
	supportAnimation.delayedOnAttach = Utils.getNoNil(getXMLBool(xmlFile, key .. "#delayedOnAttach"), true)

	return supportAnimation.animationName ~= nil
end

function Attachable:getIsSupportAnimationAllowed(supportAnimation)
	return self.playAnimation ~= nil
end

function Attachable:getIsImplementChainLowered(defaultIsLowered)
	if not self:getIsLowered(defaultIsLowered) then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and attacherVehicle.getAllowsLowering ~= nil and attacherVehicle:getAllowsLowering() and not attacherVehicle:getIsImplementChainLowered(defaultIsLowered) then
		return false
	end

	return true
end

function Attachable:getIsInWorkPosition()
	return true
end

function Attachable:getAttachbleAirConsumerUsage()
	return self.spec_attachable.airConsumerUsage
end

function Attachable:isDetachAllowed()
	local spec = self.spec_attachable

	if spec.attacherJoint ~= nil and spec.attacherJoint.allowsDetaching == false then
		return false, nil, false
	end

	if spec.isAdditionalAttachment then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local implement = attacherVehicle:getImplementByObject(self)

		if implement ~= nil and implement.attachingIsInProgress then
			return false
		end
	end

	return true, nil
end

function Attachable:isAttachAllowed(farmId, attacherVehicle)
	if not g_currentMission.accessHandler:canFarmAccess(farmId, self) then
		return false, nil
	end

	return true, nil
end

function Attachable:getIsInputAttacherActive(inputAttacherJoint)
	return true
end

function Attachable:getSteeringAxleBaseVehicle()
	local spec = self.spec_attachable

	if spec.steeringAxleUseSuperAttachable and spec.attacherVehicle ~= nil and spec.attacherVehicle.getAttacherVehicle ~= nil then
		return spec.attacherVehicle:getAttacherVehicle()
	end

	return spec.attacherVehicle
end

function Attachable:loadSteeringAxleFromXML(spec, xmlFile, key)
	spec.steeringAxleAngleScaleStart = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#startSpeed"), 10)
	spec.steeringAxleAngleScaleEnd = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#endSpeed"), 30)
	spec.steeringAxleUpdateBackwards = Utils.getNoNil(getXMLBool(xmlFile, key .. "#backwards"), false)
	spec.steeringAxleAngleSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speed"), 0.001)
	spec.steeringAxleUseSuperAttachable = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#useSuperAttachable"), false)
	spec.steeringAxleTargetNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#targetNode"), self.i3dMappings)
	spec.steeringAxleAngleMinRot = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#minRot"), 0)
	spec.steeringAxleAngleMaxRot = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#maxRot"), 0)
	spec.steeringAxleDirection = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#direction"), 1)
end

function Attachable:getIsSteeringAxleAllowed()
	return true
end

function Attachable:attachableAddToolCameras()
	local spec = self.spec_attachable

	if #spec.toolCameras > 0 then
		local rootAttacherVehicle = self:getRootVehicle()

		if rootAttacherVehicle ~= nil and rootAttacherVehicle.addToolCameras ~= nil then
			rootAttacherVehicle:addToolCameras(spec.toolCameras)
		end
	end
end

function Attachable:attachableRemoveToolCameras()
	local spec = self.spec_attachable

	if #spec.toolCameras > 0 then
		local rootAttacherVehicle = self:getRootVehicle()

		if rootAttacherVehicle ~= nil and rootAttacherVehicle.removeToolCameras ~= nil then
			rootAttacherVehicle:removeToolCameras(spec.toolCameras)
		end
	end
end

function Attachable:preAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local spec = self.spec_attachable
	spec.attacherVehicle = attacherVehicle
	spec.attacherJoint = spec.inputAttacherJoints[inputJointDescIndex]
	spec.inputAttacherJointDescIndex = inputJointDescIndex

	for _, additionalObject in ipairs(spec.attacherJoint.additionalObjects) do
		setVisibility(additionalObject.node, additionalObject.attacherVehiclePath == NetworkUtil.convertToNetworkFilename(attacherVehicle.configFileName))
	end

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if self:getIsSupportAnimationAllowed(supportAnimation) and not supportAnimation.delayedOnAttach then
			self:playAnimation(supportAnimation.animationName, -1, nil, true)

			if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or loadFromSavegame then
				AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999)
			end
		end
	end

	local mapHotspot = self:getMapHotspot()

	if mapHotspot ~= nil then
		mapHotspot:setEnabled(false)
	end

	SpecializationUtil.raiseEvent(self, "onPreAttach", attacherVehicle, inputJointDescIndex, jointDescIndex)
end

function Attachable:postAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local spec = self.spec_attachable
	local rootVehicle = self:getRootVehicle()

	if rootVehicle ~= nil and rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then
		self:activate()
	end

	if self.setLightsTypesMask ~= nil then
		local lightsSpecAttacherVehicle = attacherVehicle.spec_lights

		if lightsSpecAttacherVehicle ~= nil then
			self:setLightsTypesMask(lightsSpecAttacherVehicle.lightsTypesMask, true, true)
			self:setBeaconLightsVisibility(lightsSpecAttacherVehicle.beaconLightsActive, true, true)
			self:setTurnLightState(lightsSpecAttacherVehicle.turnLightState, true, true)
		end
	end

	spec.attachTime = g_currentMission.time

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if self:getIsSupportAnimationAllowed(supportAnimation) and supportAnimation.delayedOnAttach then
			self:playAnimation(supportAnimation.animationName, -1, nil, true)

			if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or loadFromSavegame then
				AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999)
			end
		end
	end

	self:attachableAddToolCameras()
	ObjectChangeUtil.setObjectChanges(spec.attacherJoint.changeObjects, true, self, self.setMovingToolDirty)

	local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)

	if jointDesc.steeringBarLeftNode ~= nil and spec.attacherJoint.steeringBarLeftMovingPart ~= nil then
		for _, movingPart in pairs(self.spec_cylindered.movingParts) do
			if movingPart.referencePoint == spec.attacherJoint.steeringBarLeftMovingPart.referencePoint and movingPart ~= spec.attacherJoint.steeringBarLeftMovingPart then
				movingPart.referencePoint = jointDesc.steeringBarLeftNode
			end
		end

		spec.attacherJoint.steeringBarLeftMovingPart.referencePoint = jointDesc.steeringBarLeftNode
	end

	if jointDesc.steeringBarRightNode ~= nil and spec.attacherJoint.steeringBarRightMovingPart ~= nil then
		for _, movingPart in pairs(self.spec_cylindered.movingParts) do
			if movingPart.referencePoint == spec.attacherJoint.steeringBarRightMovingPart.referencePoint and movingPart ~= spec.attacherJoint.steeringBarRightMovingPart then
				movingPart.referencePoint = jointDesc.steeringBarRightNode
			end
		end

		spec.attacherJoint.steeringBarRightMovingPart.referencePoint = jointDesc.steeringBarRightNode
	end

	if self.getIsFoldMiddleAllowed == nil or not self:getIsFoldMiddleAllowed() then
		local inputJointDesc = self:getActiveInputAttacherJoint()

		if inputJointDesc ~= nil and inputJointDesc.needsLowering and inputJointDesc.allowsLowering and jointDesc.allowsLowering and self:getAllowsLowering() then
			spec.controlledAction = self:getRootVehicle().actionController:registerAction("lower", InputAction.LOWER_IMPLEMENT, 2)

			spec.controlledAction:setCallback(self, Attachable.actionControllerLowerImplementEvent)
			spec.controlledAction:setFinishedFunctions(self, self.getIsLowered, true, false)
			spec.controlledAction:setIsSaved(true)

			if self:getAINeedsLowering() then
				spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1)
				spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onPostAttach", attacherVehicle, inputJointDescIndex, jointDescIndex)
end

function Attachable:preDetach(attacherVehicle, implement)
	local spec = self.spec_attachable

	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end

	SpecializationUtil.raiseEvent(self, "onPreDetach", attacherVehicle, implement)
end

function Attachable:postDetach(implementIndex)
	local spec = self.spec_attachable

	self:deactivate()
	ObjectChangeUtil.setObjectChanges(spec.attacherJoint.changeObjects, false, self, self.setMovingToolDirty)

	if self.playAnimation ~= nil then
		for _, supportAnimation in ipairs(spec.supportAnimations) do
			if self:getIsSupportAnimationAllowed(supportAnimation) then
				self:playAnimation(supportAnimation.animationName, 1, nil, true)
			end
		end

		if spec.lowerAnimation ~= nil and spec.lowerAnimationDirectionOnDetach ~= 0 then
			self:playAnimation(spec.lowerAnimation, spec.lowerAnimationDirectionOnDetach, nil, true)
		end
	end

	self:attachableRemoveToolCameras()

	for _, additionalObject in ipairs(spec.attacherJoint.additionalObjects) do
		setVisibility(additionalObject.node, false)
	end

	spec.attacherVehicle = nil
	spec.attacherJoint = nil
	spec.attacherJointIndex = nil
	spec.inputAttacherJointDescIndex = nil
	local mapHotspot = self:getMapHotspot()

	if mapHotspot ~= nil then
		mapHotspot:setEnabled(true)
	end

	SpecializationUtil.raiseEvent(self, "onPostDetach")
end

function Attachable:setLowered(lowered)
	local spec = self.spec_attachable

	if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
		if lowered then
			self:playAnimation(spec.lowerAnimation, spec.lowerAnimationSpeed, nil, true)
		else
			self:playAnimation(spec.lowerAnimation, -spec.lowerAnimationSpeed, nil, true)
		end
	end

	if spec.attacherJoint ~= nil then
		for _, dependentAttacherJointIndex in pairs(spec.attacherJoint.dependentAttacherJoints) do
			if self.getAttacherJoints ~= nil then
				local attacherJoints = self:getAttacherJoints()

				if attacherJoints[dependentAttacherJointIndex] ~= nil then
					self:setJointMoveDown(dependentAttacherJointIndex, lowered, true)
				else
					g_logManager:xmlWarning(self.configFileName, "Failed to lower dependent attacher joint index '%d', No attacher joint defined!", dependentAttacherJointIndex)
				end
			else
				g_logManager:xmlWarning(self.configFileName, "Failed to lower dependent attacher joint index '%d', AttacherJoint specialization is missing!", dependentAttacherJointIndex)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onSetLowered", lowered)
end

function Attachable:setLoweredAll(doLowering, jointDescIndex)
	self:getAttacherVehicle():handleLowerImplementByAttacherJointIndex(jointDescIndex, doLowering)
	SpecializationUtil.raiseEvent(self, "onSetLoweredAll", doLowering, jointDescIndex)
end

function Attachable:setIsAdditionalAttachment(needsLowering, vehicleLoaded)
	local spec = self.spec_attachable
	spec.isAdditionalAttachment = true
	spec.additionalAttachmentNeedsLowering = needsLowering

	if vehicleLoaded then
		self:requestActionEventUpdate()

		if not needsLowering and spec.controlledAction ~= nil then
			spec.controlledAction:remove()
		end
	end
end

function Attachable:getIsAdditionalAttachment()
	return self.spec_attachable.isAdditionalAttachment
end

function Attachable:setIsSupportVehicle(state)
	local spec = self.spec_attachable

	if state == nil then
		state = true
	end

	spec.isSupportVehicle = state
end

function Attachable:getIsSupportVehicle()
	return self.spec_attachable.isSupportVehicle
end

function Attachable:registerLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	self:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Attachable:getLoweringActionEventState()
	local showLower = false
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)
		local inputJointDesc = self:getActiveInputAttacherJoint()
		showLower = jointDesc.allowsLowering and inputJointDesc.allowsLowering
	end

	local text = nil

	if self:getIsLowered() then
		text = string.format(g_i18n:getText("action_liftOBJECT"), self.typeDesc)
	else
		text = string.format(g_i18n:getText("action_lowerOBJECT"), self.typeDesc)
	end

	return showLower, text
end

function Attachable:getAllowMultipleAttachments()
	return false
end

function Attachable:resolveMultipleAttachments()
end

function Attachable:onDeactivate()
	if self.brake ~= nil then
		local spec = self.spec_attachable

		self:brake(spec.brakeForce, true)
	end
end

function Attachable:onSelect(subSelectionIndex)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		attacherVehicle:setSelectedImplementByObject(self)
	end
end

function Attachable:onUnselect()
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		attacherVehicle:setSelectedImplementByObject(nil)
	end
end

function Attachable:getRootVehicle(superFunc)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getRootVehicle()
	end

	return superFunc(self)
end

function Attachable:getIsActive(superFunc)
	if superFunc(self) then
		return true
	end

	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getIsActive()
	end

	return false
end

function Attachable:getIsOperating(superFunc)
	local spec = self.spec_attachable
	local isOperating = superFunc(self)

	if not isOperating and spec.attacherVehicle ~= nil then
		isOperating = spec.attacherVehicle:getIsOperating()
	end

	return isOperating
end

function Attachable:getBrakeForce(superFunc)
	local brakeForce = superFunc(self)

	return math.max(brakeForce, self.spec_attachable.brakeForce)
end

function Attachable:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_attachable

	if not spec.allowFoldingWhileAttached and self:getAttacherVehicle() ~= nil then
		return false
	end

	if not spec.allowFoldingWhileLowered and self:getIsLowered() then
		return false
	end

	return superFunc(self)
end

function Attachable:getAreControlledActionsAllowed(superFunc)
	local inputAttacherJoint = self:getActiveInputAttacherJoint()

	if inputAttacherJoint ~= nil and not inputAttacherJoint.turnOnAllowed then
		return false
	end

	return superFunc(self)
end

function Attachable:getCanToggleTurnedOn(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)

		if jointDesc ~= nil and not jointDesc.canTurnOnImplement then
			return false
		end
	end

	return superFunc(self)
end

function Attachable:getDeactivateOnLeave(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and not attacherVehicle:getDeactivateOnLeave() then
		return false
	end

	return superFunc(self)
end

function Attachable:getCanAIImplementContinueWork(superFunc)
	local spec = self.spec_attachable
	local isReady = true

	if spec.lowerAnimation ~= nil then
		local time = self:getAnimationTime(spec.lowerAnimation)
		isReady = time == 1 or time == 0
	end

	local jointDesc = spec.attacherVehicle:getAttacherJointDescFromObject(self)

	if jointDesc.allowsLowering and self:getAINeedsLowering() and jointDesc.moveDown and jointDesc.moveAlpha ~= jointDesc.lowerAlpha then
		isReady = jointDesc.moveAlpha == jointDesc.upperAlpha and isReady
	end

	return isReady
end

function Attachable:getActiveFarm(superFunc)
	local spec = self.spec_attachable

	if self.spec_enterable ~= nil and self.spec_enterable.controllerFarmId ~= 0 then
		return superFunc(self)
	end

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getActiveFarm()
	else
		return superFunc(self)
	end
end

function Attachable:getCanBeSelected(superFunc)
	return true
end

function Attachable:getIsLowered(superFunc, defaultIsLowered)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)

		if jointDesc.allowsLowering or jointDesc.isDefaultLowered then
			return jointDesc.moveDown
		else
			return defaultIsLowered
		end
	end

	return superFunc(self, defaultIsLowered)
end

function Attachable:mountDynamic(superFunc, object, objectActorId, jointNode, mountType, forceAcceleration)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return false
	end

	return superFunc(self, object, objectActorId, jointNode, mountType, forceAcceleration)
end

function Attachable:getOwner(superFunc)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getOwner()
	end

	return superFunc(self)
end

function Attachable:getIsInUse(superFunc, connection)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		return attacherVehicle:getIsInUse(connection)
	end

	return superFunc(self, connection)
end

function Attachable:getUpdatePriority(superFunc, skipCount, x, y, z, coeff, connection)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		return attacherVehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	return superFunc(self, skipCount, x, y, z, coeff, connection)
end

function Attachable:getCanBeReset(superFunc)
	if self:getIsAdditionalAttachment() then
		return false
	end

	if self:getIsSupportVehicle() then
		return false
	end

	return superFunc(self)
end

function Attachable:getShowOnMap(superFunc)
	if self:getIsAdditionalAttachment() then
		return false
	end

	if self:getIsSupportVehicle() then
		return false
	end

	return superFunc(self)
end

function Attachable:actionControllerLowerImplementEvent(direction)
	local spec = self.spec_attachable

	if self:getAllowsLowering() then
		local moveDown = true

		if direction < 0 then
			moveDown = false
		end

		local jointDescIndex = spec.attacherVehicle:getAttacherJointIndexFromObject(self)

		spec.attacherVehicle:setJointMoveDown(jointDescIndex, moveDown, false)

		return true
	end

	return false
end

function Attachable:onStateChange(state, data)
	if self.getAILowerIfAnyIsLowered ~= nil and self:getAILowerIfAnyIsLowered() then
		if state == Vehicle.STATE_CHANGE_AI_START_LINE then
			Attachable.actionControllerLowerImplementEvent(self, 1)
		elseif state == Vehicle.STATE_CHANGE_AI_END_LINE then
			Attachable.actionControllerLowerImplementEvent(self, -1)
		end
	end
end
