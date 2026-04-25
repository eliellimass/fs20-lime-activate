Mountable = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function Mountable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsMountDynamic", Mountable.getSupportsMountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "onDynamicMountJointBreak", Mountable.onDynamicMountJointBreak)
	SpecializationUtil.registerFunction(vehicleType, "mountableTriggerCallback", Mountable.mountableTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "mount", Mountable.mount)
	SpecializationUtil.registerFunction(vehicleType, "unmount", Mountable.unmount)
	SpecializationUtil.registerFunction(vehicleType, "mountDynamic", Mountable.mountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "unmountDynamic", Mountable.unmountDynamic)
	SpecializationUtil.registerFunction(vehicleType, "getMountObject", Mountable.getMountObject)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountObject", Mountable.getDynamicMountObject)
end

function Mountable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Mountable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRootVehicle", Mountable.getRootVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwner", Mountable.getOwner)
end

function Mountable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Mountable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Mountable)
end

function Mountable:onLoad(savegame)
	local spec = self.spec_mountable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.dynamicMount#triggerIndex", "vehicle.dynamicMount#triggerNode")

	spec.dynamicMountJointIndex = nil
	spec.dynamicMountObject = nil
	spec.dynamicMountObjectActorId = nil
	spec.dynamicMountForceLimitScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMount#forceLimitScale"), 1)
	spec.mountObject = nil

	if self.isServer then
		spec.dynamicMountTriggerId = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.dynamicMount#triggerNode"), self.i3dMappings)

		if spec.dynamicMountTriggerId ~= nil then
			addTrigger(spec.dynamicMountTriggerId, "mountableTriggerCallback", self)
		end

		spec.dynamicMountTriggerForceAcceleration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.dynamicMount#triggerForceAcceleration"), 4)
		spec.dynamicMountSingleAxisFreeY = getXMLBool(self.xmlFile, "vehicle.dynamicMount#singleAxisFreeY")
		spec.dynamicMountSingleAxisFreeX = getXMLBool(self.xmlFile, "vehicle.dynamicMount#singleAxisFreeX")
	end
end

function Mountable:onDelete()
	local spec = self.spec_mountable

	if spec.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(spec.dynamicMountJointIndex)
		removeJoint(spec.dynamicMountJointIndex)
	end

	if spec.dynamicMountObject ~= nil then
		spec.dynamicMountObject:removeDynamicMountedObject(self, true)
	end

	if spec.dynamicMountTriggerId ~= nil then
		removeTrigger(spec.dynamicMountTriggerId)
	end
end

function Mountable:getSupportsMountDynamic()
	local spec = self.spec_mountable

	return spec.dynamicMountForceLimitScale ~= nil
end

function Mountable:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	local spec = self.spec_mountable

	if jointIndex == spec.dynamicMountJointIndex then
		self:unmountDynamic()
	end

	return false
end

function Mountable:mountableTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_mountable

	if onEnter then
		if spec.mountObject == nil then
			local vehicle = g_currentMission.nodeToObject[otherActorId]

			if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
				local dynamicMountAttacher = vehicle.spec_dynamicMountAttacher

				if dynamicMountAttacher ~= nil and dynamicMountAttacher.dynamicMountAttacherNode ~= nil then
					if spec.dynamicMountObjectActorId == nil then
						self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, spec.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)

						spec.dynamicMountObjectTriggerCount = 1
					elseif otherActorId ~= spec.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount == nil then
						self:unmountDynamic()
						self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, spec.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)

						spec.dynamicMountObjectTriggerCount = 1
					elseif otherActorId == spec.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount ~= nil then
						spec.dynamicMountObjectTriggerCount = spec.dynamicMountObjectTriggerCount + 1
					end
				end
			end
		end
	elseif onLeave and otherActorId == spec.dynamicMountObjectActorId and spec.dynamicMountObjectTriggerCount ~= nil then
		spec.dynamicMountObjectTriggerCount = spec.dynamicMountObjectTriggerCount - 1

		if spec.dynamicMountObjectTriggerCount == 0 then
			self:unmountDynamic()

			spec.dynamicMountObjectTriggerCount = nil
		end
	end
end

function Mountable:mount(object, node, x, y, z, rx, ry, rz)
	local spec = self.spec_mountable

	self:unmountDynamic(true)

	if spec.mountObject == nil then
		removeFromPhysics(self.rootNode)
	end

	link(node, self.rootNode)

	local wx, wy, wz = localToWorld(node, x, y, z)
	local wqx, wqy, wqz, wqw = mathEulerToQuaternion(localRotationToWorld(node, rx, ry, rz))

	self:setWorldPositionQuaternion(wx, wy, wz, wqx, wqy, wqz, wqw, 1, true)

	spec.mountObject = object
end

function Mountable:unmount()
	local spec = self.spec_mountable

	if spec.mountObject ~= nil then
		spec.mountObject = nil
		local x, y, z = getWorldTranslation(self.rootNode)
		local qx, qy, qz, qw = getWorldQuaternion(self.rootNode)

		link(getRootNode(), self.rootNode)
		self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, 1, true)
		addToPhysics(self.rootNode)

		return true
	end

	return false
end

function Mountable:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	local spec = self.spec_mountable

	if not self:getSupportsMountDynamic() or spec.mountObject ~= nil then
		return false
	end

	local dynamicMountSpec = self.spec_dynamicMountAttacher

	if dynamicMountSpec ~= nil then
		for _, mountedObject in pairs(dynamicMountSpec.dynamicMountedObjects) do
			if mountedObject:isa(Vehicle) and mountedObject:getRootVehicle() == object:getRootVehicle() then
				return false
			end
		end
	end

	if object:getRootVehicle() == self:getRootVehicle() then
		return false
	end

	return DynamicMountUtil.mountDynamic(self, self.rootNode, object, objectActorId, jointNode, mountType, forceAcceleration * spec.dynamicMountForceLimitScale)
end

function Mountable:unmountDynamic(isDelete)
	DynamicMountUtil.unmountDynamic(self, isDelete)
end

function Mountable:getIsActive(superFunc)
	if superFunc(self) then
		return true
	end

	local spec = self.spec_mountable

	if spec.dynamicMountObject ~= nil and spec.dynamicMountObject.getIsActive ~= nil then
		return spec.dynamicMountObject:getIsActive()
	end
end

function Mountable:getMountObject()
	local spec = self.spec_mountable

	return spec.mountObject
end

function Mountable:getDynamicMountObject()
	local spec = self.spec_mountable

	return self.dynamicMountObject
end

function Mountable:getOwner(superFunc)
	local spec = self.spec_mountable

	if spec.dynamicMountObject ~= nil and spec.dynamicMountObject.getOwner ~= nil then
		return spec.dynamicMountObject:getOwner()
	end

	return superFunc(self)
end

function Mountable:getRootVehicle(superFunc)
	local spec = self.spec_mountable
	local rootAttacherVehicle = superFunc(self)

	if (rootAttacherVehicle == nil or rootAttacherVehicle == self) and spec.dynamicMountObject ~= nil and spec.dynamicMountObject.getRootVehicle ~= nil then
		rootAttacherVehicle = spec.dynamicMountObject:getRootVehicle()
	end

	if rootAttacherVehicle == nil then
		rootAttacherVehicle = self
	end

	return rootAttacherVehicle
end

function Mountable:onEnterVehicle(isControlling)
	self:unmountDynamic()
end

function Mountable:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:unmountDynamic()
end
