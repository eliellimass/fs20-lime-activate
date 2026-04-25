MountableObject = {}
local MountableObject_mt = Class(MountableObject, PhysicsObject)

InitStaticObjectClass(MountableObject, "MountableObject", ObjectIds.OBJECT_MOUNTABLE_OBJECT)

function MountableObject:new(isServer, isClient, customMt)
	local self = PhysicsObject:new(isServer, isClient, customMt or MountableObject_mt)
	self.dynamicMountSingleAxisFreeX = false
	self.dynamicMountSingleAxisFreeY = false
	self.lastMoveTime = -100000

	return self
end

function MountableObject:delete()
	if self.dynamicMountTriggerId ~= nil then
		removeTrigger(self.dynamicMountTriggerId)
	end

	if self.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(self.dynamicMountJointIndex)
		removeJoint(self.dynamicMountJointIndex)
	end

	if self.dynamicMountObject ~= nil then
		self.dynamicMountObject:removeDynamicMountedObject(self, true)
	end

	if self.mountObject ~= nil and self.mountObject.removeMountedObject ~= nil then
		self.mountObject:removeMountedObject(self, true)
	end

	MountableObject:superClass().delete(self)
end

function MountableObject:getAllowsAutoDelete()
	return self.mountObject == nil and MountableObject:superClass().getAllowsAutoDelete(self)
end

function MountableObject:testScope(x, y, z, coeff)
	if self.mountObject ~= nil then
		return self.mountObject:testScope(x, y, z, coeff)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:testScope(x, y, z, coeff)
	end

	return MountableObject:superClass().testScope(self, x, y, z, coeff)
end

function MountableObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	if self.mountObject ~= nil then
		return self.mountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	return MountableObject:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection)
end

function MountableObject:updateTick(dt)
	if self.isServer and self:updateMove() then
		self.lastMoveTime = g_currentMission.time
	end
end

function MountableObject:mount(object, node, x, y, z, rx, ry, rz)
	self:unmountDynamic(true)

	if self.mountObject == nil then
		removeFromPhysics(self.nodeId)
	end

	link(node, self.nodeId)

	local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

	self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)

	self.mountObject = object
end

function MountableObject:unmount()
	if self.mountObject ~= nil then
		self.mountObject = nil
		local x, y, z = getWorldTranslation(self.nodeId)
		local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)

		link(getRootNode(), self.nodeId)
		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		addToPhysics(self.nodeId)

		return true
	end

	return false
end

function MountableObject:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	assert(self.isServer)

	if not self:getSupportsMountDynamic() or self.mountObject ~= nil then
		return false
	end

	if object:getOwnerFarmId() ~= nil and not g_currentMission.accessHandler:canFarmAccess(object:getOwnerFarmId(), self) then
		return false
	end

	return DynamicMountUtil.mountDynamic(self, self.nodeId, object, objectActorId, jointNode, mountType, forceAcceleration * self.dynamicMountForceLimitScale)
end

function MountableObject:unmountDynamic(isDelete)
	DynamicMountUtil.unmountDynamic(self, isDelete)
end

function MountableObject:getSupportsMountDynamic()
	return true
end

function MountableObject:setNodeId(nodeId)
	MountableObject:superClass().setNodeId(self, nodeId)

	if self.isServer then
		self.dynamicMountTriggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "dynamicMountTriggerIndex"))

		if self.dynamicMountTriggerId ~= nil then
			addTrigger(self.dynamicMountTriggerId, "dynamicMountTriggerCallback", self)
		end

		self.dynamicMountTriggerForceAcceleration = Utils.getNoNil(tonumber(getUserAttribute(nodeId, "dynamicMountTriggerForceAcceleration")), 4)
		self.dynamicMountForceLimitScale = Utils.getNoNil(tonumber(getUserAttribute(nodeId, "dynamicMountForceLimitScale")), 1)
		self.dynamicMountSingleAxisFreeY = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeY") == true
		self.dynamicMountSingleAxisFreeX = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeX") == true
	end
end

function MountableObject:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter then
		if self.mountObject == nil then
			local vehicle = g_currentMission.nodeToObject[otherActorId]
			local dynamicMountAttacher = nil

			if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
				dynamicMountAttacher = vehicle.spec_dynamicMountAttacher
			end

			if dynamicMountAttacher ~= nil then
				if self.dynamicMountObjectActorId == nil then
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, self.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId ~= self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount == nil then
					self:unmountDynamic()
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, DynamicMountUtil.TYPE_FORK, self.dynamicMountTriggerForceAcceleration * dynamicMountAttacher.dynamicMountAttacherForceLimitScale)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
					self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount + 1
				end
			end
		end
	elseif onLeave and otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
		self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount - 1

		if self.dynamicMountObjectTriggerCount == 0 then
			self:unmountDynamic()

			self.dynamicMountObjectTriggerCount = nil
		end
	end
end

function MountableObject:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.dynamicMountJointIndex then
		self:unmountDynamic()
	end

	return false
end

function MountableObject:getMeshNodes()
	return nil
end
