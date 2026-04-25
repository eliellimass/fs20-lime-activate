PhysicsObject = {}
local PhysicsObject_mt = Class(PhysicsObject, Object)

InitStaticObjectClass(PhysicsObject, "PhysicsObject", ObjectIds.OBJECT_PHYSICS_OBJECT)

function PhysicsObject:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or PhysicsObject_mt)
	self.nodeId = 0
	self.networkTimeInterpolator = InterpolationTime:new(1.2)
	self.forcedClipDistance = 60
	self.physicsObjectDirtyFlag = self:getNextDirtyFlag()

	return self
end

function PhysicsObject:delete()
	self:removeWakeUpReports(self.nodeId)
	g_currentMission:removeNodeObject(self.nodeId)
	delete(self.nodeId)

	self.nodeId = 0

	PhysicsObject:superClass().delete(self)
end

function PhysicsObject:getAllowsAutoDelete()
	return true
end

function PhysicsObject:loadOnCreate(nodeId)
	self:setNodeId(nodeId)

	if not self.isServer then
		self:onGhostRemove()
	end
end

function PhysicsObject:setNodeId(nodeId)
	self.nodeId = nodeId

	setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
	addToPhysics(self.nodeId)

	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)
	self.sendPosZ = z
	self.sendPosY = y
	self.sendPosX = x
	self.sendRotZ = zRot
	self.sendRotY = yRot
	self.sendRotX = xRot

	if not self.isServer then
		local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)
		self.positionInterpolator = InterpolatorPosition:new(x, y, z)
		self.quaternionInterpolator = InterpolatorQuaternion:new(quatX, quatY, quatZ, quatW)
	end

	self:addChildsToNodeObject(self.nodeId)
end

function PhysicsObject:readStream(streamId, connection)
	assert(self.nodeId ~= 0)

	if connection:getIsServer() then
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local xRot = NetworkUtil.readCompressedAngle(streamId)
		local yRot = NetworkUtil.readCompressedAngle(streamId)
		local zRot = NetworkUtil.readCompressedAngle(streamId)
		local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)

		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		self.networkTimeInterpolator:reset()
	end
end

function PhysicsObject:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local x, y, z = getTranslation(self.nodeId)
		local xRot, yRot, zRot = getRotation(self.nodeId)
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams

		NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
		NetworkUtil.writeCompressedAngle(streamId, xRot)
		NetworkUtil.writeCompressedAngle(streamId, yRot)
		NetworkUtil.writeCompressedAngle(streamId, zRot)
	end
end

function PhysicsObject:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local xRot = NetworkUtil.readCompressedAngle(streamId)
		local yRot = NetworkUtil.readCompressedAngle(streamId)
		local zRot = NetworkUtil.readCompressedAngle(streamId)
		local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)

		self.positionInterpolator:setTargetPosition(x, y, z)
		self.quaternionInterpolator:setTargetQuaternion(quatX, quatY, quatZ, quatW)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end

function PhysicsObject:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.physicsObjectDirtyFlag) ~= 0) then
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams

		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, paramsXZ)
		NetworkUtil.writeCompressedAngle(streamId, self.sendRotX)
		NetworkUtil.writeCompressedAngle(streamId, self.sendRotY)
		NetworkUtil.writeCompressedAngle(streamId, self.sendRotZ)
	end
end

function PhysicsObject:update(dt)
	if not self.isServer then
		self.networkTimeInterpolator:update(dt)

		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		local posX, posY, posZ = self.positionInterpolator:getInterpolatedValues(interpolationAlpha)
		local quatX, quatY, quatZ, quatW = self.quaternionInterpolator:getInterpolatedValues(interpolationAlpha)

		self:setWorldPositionQuaternion(posX, posY, posZ, quatX, quatY, quatZ, quatW, false)

		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	elseif not getIsSleeping(self.nodeId) then
		self:raiseActive()
	end
end

function PhysicsObject:updateMove()
	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)
	local hasMoved = math.abs(self.sendPosX - x) > 0.005 or math.abs(self.sendPosY - y) > 0.005 or math.abs(self.sendPosZ - z) > 0.005 or math.abs(self.sendRotX - xRot) > 0.02 or math.abs(self.sendRotY - yRot) > 0.02 or math.abs(self.sendRotZ - zRot) > 0.02

	if hasMoved then
		self:raiseDirtyFlags(self.physicsObjectDirtyFlag)

		self.sendPosZ = z
		self.sendPosY = y
		self.sendPosX = x
		self.sendRotZ = zRot
		self.sendRotY = yRot
		self.sendRotX = xRot
	end

	return hasMoved
end

function PhysicsObject:updateTick(dt)
	if self.isServer then
		self:updateMove()
	end
end

function PhysicsObject:testScope(x, y, z, coeff)
	local x1, y1, z1 = getWorldTranslation(self.nodeId)
	local dist = (x1 - x) * (x1 - x) + (y1 - y) * (y1 - y) + (z1 - z) * (z1 - z)
	local clipDist = math.min(getClipDistance(self.nodeId) * coeff, self.forcedClipDistance)

	if dist < clipDist * clipDist then
		return true
	else
		return false
	end
end

function PhysicsObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	local x1, y1, z1 = getWorldTranslation(self.nodeId)
	local dist = math.sqrt((x1 - x) * (x1 - x) + (y1 - y) * (y1 - y) + (z1 - z) * (z1 - z))
	local clipDist = math.min(getClipDistance(self.nodeId) * coeff, self.forcedClipDistance)

	return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end

function PhysicsObject:onGhostRemove()
	setVisibility(self.nodeId, false)
	removeFromPhysics(self.nodeId)
end

function PhysicsObject:onGhostAdd()
	setVisibility(self.nodeId, true)
	addToPhysics(self.nodeId)
end

function PhysicsObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if not self.isServer and changeInterp then
		self.positionInterpolator:setPosition(x, y, z)
		self.quaternionInterpolator:setQuaternion(quatX, quatY, quatZ, quatW)
	end

	setTranslation(self.nodeId, x, y, z)
	setQuaternion(self.nodeId, quatX, quatY, quatZ, quatW)
end

function PhysicsObject:getDefaultRigidBodyType()
	if self.isServer then
		return "Dynamic"
	else
		return "Kinematic"
	end
end

function PhysicsObject:addChildsToNodeObject(nodeId)
	for i = 0, getNumOfChildren(nodeId) - 1 do
		self:addChildsToNodeObject(getChildAt(nodeId, i))
	end

	local rigidBodyType = getRigidBodyType(nodeId)

	if rigidBodyType ~= "NoRigidBody" then
		g_currentMission:addNodeObject(nodeId, self)

		if self.isServer then
			addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
		end
	end
end

function PhysicsObject:removeWakeUpReports(nodeId)
	if self.isServer then
		for i = 0, getNumOfChildren(nodeId) - 1 do
			self:removeWakeUpReports(getChildAt(nodeId, i))
		end

		local rigidBodyType = getRigidBodyType(nodeId)

		if rigidBodyType ~= "NoRigidBody" then
			removeWakeUpReport(nodeId)
		end
	end
end

function PhysicsObject:onPhysicObjectWakeUpCallback(id)
	self:raiseActive()
end
