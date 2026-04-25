Object = {}
local Object_mt = Class(Object)

InitStaticObjectClass(Object, "Object", ObjectIds.OBJECT_OBJECT)

Object.nextObjectId = 1

function Object.resetObjectIds()
	assert(g_server == nil or next(g_server.objects) == nil)

	Object.nextObjectId = 1
end

function Object:new(isServer, isClient, customMt)
	local self = {}

	setmetatable(self, customMt or Object_mt)

	self.id = Object.nextObjectId
	Object.nextObjectId = Object.nextObjectId + 1

	if g_isDevelopmentVersion and not isServer then
		self.id = math.random(1, 99999999)
	end

	self.isRegistered = false
	self.isServer = isServer
	self.isClient = isClient
	self.owner = nil
	self.ownerFarmId = AccessHandler.EVERYONE
	self.nextDirtyFlag = 1
	self.dirtyMask = 0
	self.deleteListeners = {}

	return self
end

function Object:delete()
	for _, listener in ipairs(self.deleteListeners) do
		listener.object[listener.callbackName](listener.object, self)
	end

	if self.isRegistered then
		self:unregister()
	end
end

function Object:register(alreadySent)
	if self.isServer then
		if g_server ~= nil then
			g_server:registerObject(self, alreadySent)
		end
	elseif g_client ~= nil then
		g_client:registerObject(self, alreadySent)
	end
end

function Object:unregister(alreadySent)
	if self.isServer then
		if g_server ~= nil then
			g_server:unregisterObject(self, alreadySent)
		end
	elseif g_client ~= nil then
		g_client:unregisterObject(self, alreadySent)
	end
end

function Object:raiseActive()
	if self.isServer then
		if g_server ~= nil then
			g_server:addObjectToUpdateLoop(self)
		end
	elseif g_client ~= nil then
		g_client:addObjectToUpdateLoop(self)
	end
end

function Object:readStream(streamId)
	self:setOwnerFarmId(streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS), true)
end

function Object:writeStream(streamId)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function Object:readUpdateStream(streamId, timestamp, connection)
end

function Object:writeUpdateStream(streamId, connection, dirtyMask)
end

function Object:mouseEvent(posX, posY, isDown, isUp, button)
end

function Object:update(dt)
end

function Object:updateTick(dt)
end

function Object:updateEnd(dt)
end

function Object:draw()
end

function Object:setOwner(owner)
	if self.isServer then
		self.owner = owner
	else
		print("Error: setOwner only allowed on Server")
	end
end

function Object:testScope(x, y, z, coeff)
	return true
end

function Object:onGhostRemove()
end

function Object:onGhostAdd()
end

function Object:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	return skipCount * 0.5
end

function Object:getNextDirtyFlag()
	if self.nextDirtyFlag >= 2147483648.0 then
		print(" self.nextDirtyFlag = " .. tostring(self.nextDirtyFlag))
		printCallstack()
	end

	assert(self.nextDirtyFlag < 2147483648.0, "Object:getNextDirtyFlag(), too many dirty flags")

	local nextFlag = self.nextDirtyFlag
	self.nextDirtyFlag = self.nextDirtyFlag * 2

	return nextFlag
end

function Object:raiseDirtyFlags(flag)
	self.dirtyMask = bitOR(self.dirtyMask, flag)
end

function Object:clearDirtyFlags(flag)
	self.dirtyMask = bitAND(self.dirtyMask, bitNOT(flag))
end

function Object:onMissionStarted()
end

function Object:setOwnerFarmId(farmId, noEventSend)
	if self.ownerFarmId ~= farmId then
		self.ownerFarmId = farmId

		if self.isServer and (noEventSend == nil or not noEventSend) then
			g_server:broadcastEvent(ObjectFarmChangeEvent:new(self, farmId), nil, , self)
		end
	end
end

function Object:getOwnerFarmId()
	return self.ownerFarmId
end

function Object:addDeleteListener(object, callbackName)
	if callbackName == nil then
		callbackName = "onDeleteObject"
	end

	for _, listener in ipairs(self.deleteListeners) do
		if listener.object == object and listener.callbackName == callbackName then
			return
		end
	end

	table.insert(self.deleteListeners, {
		object = object,
		callbackName = callbackName
	})
end

function Object:removeDeleteListener(object, callbackName)
	if callbackName == nil then
		callbackName = "onDeleteObject"
	end

	local indexToRemove = -1

	for i, listener in ipairs(self.deleteListeners) do
		if listener.object == object and listener.callbackName == callbackName then
			indexToRemove = i
		end
	end

	if indexToRemove > 0 then
		table.remove(self.deleteListeners, indexToRemove)
	end
end
