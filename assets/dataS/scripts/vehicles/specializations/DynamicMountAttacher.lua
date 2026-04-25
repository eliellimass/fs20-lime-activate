DynamicMountAttacher = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function DynamicMountAttacher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountObjects", DynamicMountAttacher.getAllowDynamicMountObjects)
	SpecializationUtil.registerFunction(vehicleType, "dynamicMountTriggerCallback", DynamicMountAttacher.dynamicMountTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", DynamicMountAttacher.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", DynamicMountAttacher.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "setDynamicMountAnimationState", DynamicMountAttacher.setDynamicMountAnimationState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", DynamicMountAttacher.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicMountGrabFromXML", DynamicMountAttacher.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicMountGrabOpened", DynamicMountAttacher.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountTimeToMount", DynamicMountAttacher.getDynamicMountTimeToMount)
	SpecializationUtil.registerFunction(vehicleType, "getHasDynamicMountedObjects", DynamicMountAttacher.getHasDynamicMountedObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceDynamicMountPendingObjects", DynamicMountAttacher.forceDynamicMountPendingObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceUnmountDynamicMountedObjects", DynamicMountAttacher.forceUnmountDynamicMountedObjects)
end

function DynamicMountAttacher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", DynamicMountAttacher.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", DynamicMountAttacher.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", DynamicMountAttacher.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", DynamicMountAttacher.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", DynamicMountAttacher.updateExtraDependentParts)
end

function DynamicMountAttacher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", DynamicMountAttacher)
end

function DynamicMountAttacher:onLoad(savegame)
	local spec = self.spec_dynamicMountAttacher

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.dynamicMountAttacher#index", "vehicle.dynamicMountAttacher#node")

	spec.dynamicMountAttacherNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher#node"), self.i3dMappings)
	spec.dynamicMountAttacherForceLimitScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMountAttacher#forceLimitScale"), 1)
	spec.dynamicMountAttacherTimeToMount = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMountAttacher#timeToMount"), 1000)
	spec.numObjectBits = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMountAttacher#numObjectBits"), 5)
	local grabKey = "vehicle.dynamicMountAttacher.grab"

	if hasXMLProperty(self.xmlFile, grabKey) then
		spec.dynamicMountAttacherGrab = {}

		self:loadDynamicMountGrabFromXML(self.xmlFile, grabKey, spec.dynamicMountAttacherGrab)
	end

	if self.isServer then
		spec.dynamicMountCollisionMasks = {}
		local i = 0

		while true do
			local key = string.format("vehicle.dynamicMountAttacher.mountCollisionMask(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

			local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
			local mask = getXMLInt(self.xmlFile, key .. "#collisionMask")

			if node ~= nil and mask ~= nil then
				table.insert(spec.dynamicMountCollisionMasks, {
					node = node,
					mountedCollisionMask = mask,
					unmountedCollisionMask = getCollisionMask(node)
				})
			end

			i = i + 1
		end

		local attacherTriggerTriggerNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher#triggerNode"), self.i3dMappings)
		local attacherTriggerRootNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher#rootNode"), self.i3dMappings)
		local attacherTriggerJointNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher#jointNode"), self.i3dMappings)

		if attacherTriggerTriggerNode ~= nil and attacherTriggerRootNode ~= nil and attacherTriggerJointNode ~= nil then
			local forceAcceleration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMountAttacher#forceAcceleration"), 30)

			addTrigger(attacherTriggerTriggerNode, "dynamicMountTriggerCallback", self)

			local mountTypeString = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher#mountType"), "TYPE_AUTO_ATTACH_XZ")
			local mountType = Utils.getNoNil(DynamicMountUtil[mountTypeString], DynamicMountUtil.TYPE_AUTO_ATTACH_XZ)
			spec.dynamicMountAttacherTrigger = {
				triggerNode = attacherTriggerTriggerNode,
				rootNode = attacherTriggerRootNode,
				jointNode = attacherTriggerJointNode,
				forceAcceleration = forceAcceleration,
				mountType = mountType,
				mountTypeClosed = mountTypeClosed,
				currentMountType = mountType
			}
		end

		spec.pendingDynamicMountObjects = {}
	end

	spec.animationName = getXMLString(self.xmlFile, "vehicle.dynamicMountAttacher.animation#name")
	spec.animationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMountAttacher.animation#speed"), 1)

	if spec.animationName ~= nil then
		self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	end

	spec.dynamicMountedObjects = {}
	spec.dynamicMountedObjectsDirtyFlag = self:getNextDirtyFlag()
end

function DynamicMountAttacher:onDelete()
	local spec = self.spec_dynamicMountAttacher

	if self.isServer then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			object:unmountDynamic()
		end
	end

	if spec.dynamicMountAttacherTrigger ~= nil then
		removeTrigger(spec.dynamicMountAttacherTrigger.triggerNode)
	end
end

function DynamicMountAttacher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_dynamicMountAttacher

		if streamReadBool(streamId) then
			local sum = streamReadUIntN(streamId, spec.numObjectBits)
			spec.dynamicMountedObjects = {}

			for i = 1, sum do
				local object = NetworkUtil.readNodeObject(streamId)

				if object ~= nil then
					spec.dynamicMountedObjects[object] = object
				end
			end

			self:setDynamicMountAnimationState(sum > 0)
		end
	end
end

function DynamicMountAttacher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_dynamicMountAttacher

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dynamicMountedObjectsDirtyFlag) ~= 0) then
			local num = 0

			for object, _ in pairs(spec.dynamicMountedObjects) do
				num = num + 1
			end

			streamWriteUIntN(streamId, num, spec.numObjectBits)

			local objectIndex = 0

			for object, _ in pairs(spec.dynamicMountedObjects) do
				objectIndex = objectIndex + 1

				if num >= objectIndex then
					NetworkUtil.writeNodeObject(streamId, object)
				else
					g_logManager:xmlWarning(self.configFileName, "Not enough bits to send all mounted objects. Please increase '%s'", "vehicle.dynamicMountAttacher#numObjectBits")
				end
			end
		end
	end
end

function DynamicMountAttacher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_dynamicMountAttacher

		if self:getAllowDynamicMountObjects() then
			for object, _ in pairs(spec.pendingDynamicMountObjects) do
				if spec.dynamicMountedObjects[object] == nil and object.lastMoveTime + self:getDynamicMountTimeToMount() < g_currentMission.time then
					local doAttach = false

					if object.components ~= nil then
						if object.getCanByMounted ~= nil then
							doAttach = object:getCanByMounted()
						elseif entityExists(object.components[1].node) then
							doAttach = true
						end
					end

					if object.nodeId ~= nil then
						if object.getCanByMounted ~= nil then
							doAttach = object:getCanByMounted()
						elseif entityExists(object.nodeId) then
							doAttach = true
						end
					end

					if doAttach then
						local trigger = spec.dynamicMountAttacherTrigger
						local couldMount = object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration)

						if couldMount then
							self:addDynamicMountedObject(object)
						end
					else
						spec.pendingDynamicMountObjects[object] = nil
					end
				end
			end
		else
			for object, _ in pairs(spec.dynamicMountedObjects) do
				self:removeDynamicMountedObject(object, false)
				object:unmountDynamic()
			end
		end

		if spec.dynamicMountAttacherGrab ~= nil then
			for object, _ in pairs(spec.dynamicMountedObjects) do
				local usedMountType = spec.dynamicMountAttacherGrab.closedMountType

				if self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab) then
					usedMountType = spec.dynamicMountAttacherGrab.openMountType
				end

				if spec.dynamicMountAttacherGrab.currentMountType ~= usedMountType then
					spec.dynamicMountAttacherGrab.currentMountType = usedMountType
					local x, y, z = getWorldTranslation(spec.dynamicMountAttacherNode)

					setJointPosition(object.dynamicMountJointIndex, 1, x, y, z)

					if usedMountType == DynamicMountUtil.TYPE_FORK then
						setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)

						if object.dynamicMountSingleAxisFreeX then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
						else
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
						end

						if object.dynamicMountSingleAxisFreeY then
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
						else
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
						end

						setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
					else
						setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)

						if usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or usedMountType == DynamicMountUtil.TYPE_FIX_ATTACH then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
						end
					end
				end
			end
		end
	end
end

function DynamicMountAttacher:addDynamicMountedObject(object)
	local spec = self.spec_dynamicMountAttacher
	spec.dynamicMountedObjects[object] = object

	for _, info in pairs(spec.dynamicMountCollisionMasks) do
		setCollisionMask(info.node, info.mountedCollisionMask)
	end

	self:setDynamicMountAnimationState(true)
	self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end

function DynamicMountAttacher:removeDynamicMountedObject(object, isDeleting)
	local spec = self.spec_dynamicMountAttacher
	spec.dynamicMountedObjects[object] = nil

	if isDeleting then
		spec.pendingDynamicMountObjects[object] = nil
	end

	if next(spec.dynamicMountedObjects) == nil and next(spec.pendingDynamicMountObjects) == nil then
		for _, info in pairs(spec.dynamicMountCollisionMasks) do
			setCollisionMask(info.node, info.unmountedCollisionMask)
		end
	end

	self:setDynamicMountAnimationState(false)
	self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end

function DynamicMountAttacher:setDynamicMountAnimationState(state)
	local spec = self.spec_dynamicMountAttacher

	if state then
		self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	else
		self:playAnimation(spec.animationName, -spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	end
end

function DynamicMountAttacher:getAllowDynamicMountObjects()
	return true
end

function DynamicMountAttacher:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_dynamicMountAttacher

	if onEnter then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object == nil then
			object = g_currentMission.nodeToObject[otherActorId]
		end

		if object == self:getRootVehicle() or self.spec_attachable ~= nil and self.spec_attachable.attacherVehicle == object then
			object = nil
		end

		if object ~= nil and object ~= self then
			local isObject = object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() and object.lastMoveTime ~= nil
			local isVehicle = object.getSupportsTensionBelts ~= nil and object:getSupportsTensionBelts() and object.lastMoveTime ~= nil

			if isObject or isVehicle then
				spec.pendingDynamicMountObjects[object] = Utils.getNoNil(spec.pendingDynamicMountObjects[object], 0) + 1
			end
		end
	elseif onLeave then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object == nil then
			object = g_currentMission.nodeToObject[otherActorId]
		end

		if object ~= nil and spec.pendingDynamicMountObjects[object] ~= nil then
			local count = spec.pendingDynamicMountObjects[object] - 1

			if count == 0 then
				spec.pendingDynamicMountObjects[object] = nil

				if spec.dynamicMountedObjects[object] ~= nil then
					self:removeDynamicMountedObject(object, false)
					object:unmountDynamic()
				end
			else
				spec.pendingDynamicMountObjects[object] = count
			end
		end
	end
end

function DynamicMountAttacher:getAllowDynamicMountFillLevelInfo()
	return true
end

function DynamicMountAttacher:loadDynamicMountGrabFromXML(xmlFile, key, entry)
	local openMountType = getXMLString(self.xmlFile, key .. "#openMountType")
	entry.openMountType = Utils.getNoNil(DynamicMountUtil[openMountType], DynamicMountUtil.TYPE_FORK)
	local closedMountType = getXMLString(self.xmlFile, key .. "#closedMountType")
	entry.closedMountType = Utils.getNoNil(DynamicMountUtil[closedMountType], DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ)
	entry.currentMountType = entry.openMountType

	return true
end

function DynamicMountAttacher:getIsDynamicMountGrabOpened(grab)
	return true
end

function DynamicMountAttacher:getDynamicMountTimeToMount()
	return self.spec_dynamicMountAttacher.dynamicMountAttacherTimeToMount
end

function DynamicMountAttacher:getHasDynamicMountedObjects()
	return next(self.spec_dynamicMountAttacher.dynamicMountedObjects) ~= nil
end

function DynamicMountAttacher:forceDynamicMountPendingObjects(onlyBales)
	if self:getAllowDynamicMountObjects() then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.pendingDynamicMountObjects) do
			if spec.dynamicMountedObjects[object] == nil and (not onlyBales or object:isa(Bale)) then
				local trigger = spec.dynamicMountAttacherTrigger
				local couldMount = object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration)

				if couldMount then
					self:addDynamicMountedObject(object)
				end
			end
		end
	end
end

function DynamicMountAttacher:forceUnmountDynamicMountedObjects()
	local spec = self.spec_dynamicMountAttacher

	if spec ~= nil then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			self:removeDynamicMountedObject(object, false)
			object:unmountDynamic()
		end
	end
end

function DynamicMountAttacher:getFillLevelInformation(superFunc, fillLevelInformations)
	superFunc(self, fillLevelInformations)

	if self:getAllowDynamicMountFillLevelInfo() then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.dynamicMountedObjects) do
			if object.getFillLevelInformation ~= nil then
				object:getFillLevelInformation(fillLevelInformations)
			elseif object.getFillLevel ~= nil and object.getFillType ~= nil then
				local added = false

				for _, fillLevelInformation in pairs(fillLevelInformations) do
					if fillLevelInformation.fillType == object:getFillType() then
						fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + object:getFillLevel()

						if object.getCapacity ~= nil then
							fillLevelInformation.capacity = fillLevelInformation.capacity + object:getCapacity()
						else
							fillLevelInformation.capacity = fillLevelInformation.capacity + object:getFillLevel()
						end

						added = true

						break
					end
				end

				if not added then
					if object.getCapacity ~= nil then
						table.insert(fillLevelInformations, {
							fillType = object:getFillType(),
							fillLevel = object:getFillLevel(),
							capacity = object:getCapacity()
						})
					else
						table.insert(fillLevelInformations, {
							fillType = object:getFillType(),
							fillLevel = object:getFillLevel(),
							capacity = object:getFillLevel()
						})
					end
				end
			end
		end
	end
end

function DynamicMountAttacher:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_dynamicMountAttacher

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = self
	end
end

function DynamicMountAttacher:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_dynamicMountAttacher

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = nil
	end
end

function DynamicMountAttacher:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	entry.updateDynamicMountAttacher = getXMLBool(xmlFile, baseName .. ".dynamicMountAttacher#value")

	return true
end

function DynamicMountAttacher:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if self.isServer and part.updateDynamicMountAttacher ~= nil and part.updateDynamicMountAttacher then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.dynamicMountedObjects) do
			setJointFrame(object.dynamicMountJointIndex, 0, object.dynamicMountJointNode)
		end
	end
end

function DynamicMountAttacher:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex)
	local objSpec = object.spec_dynamicMountAttacher

	if objSpec ~= nil and self.isServer then
		objSpec.pendingDynamicMountObjects[self] = nil

		if objSpec.dynamicMountedObjects[self] ~= nil then
			object:removeDynamicMountedObject(self, false)
			self:unmountDynamic()
		end
	end
end

function DynamicMountAttacher:updateDebugValues(values)
	local spec = self.spec_dynamicMountAttacher
	local timeToMount = self.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time

	table.insert(values, {
		name = "timeToMount:",
		value = string.format("%d", timeToMount)
	})

	for object, _ in pairs(spec.pendingDynamicMountObjects) do
		table.insert(values, {
			name = "pendingDynamicMountObject:",
			value = string.format("%s timeToMount: %d", object.configFileName or object, math.max(object.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time, 0))
		})
	end

	for object, _ in pairs(spec.dynamicMountedObjects) do
		table.insert(values, {
			name = "dynamicMountedObjects:",
			value = string.format("%s", object.configFileName or object)
		})
	end

	table.insert(values, {
		name = "allowMountObjects:",
		value = string.format("%s", self:getAllowDynamicMountObjects())
	})

	if spec.dynamicMountAttacherGrab ~= nil then
		table.insert(values, {
			name = "grabOpened:",
			value = string.format("%s", self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab))
		})
	end
end
