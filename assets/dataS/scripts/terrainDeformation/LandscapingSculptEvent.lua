LandscapingSculptEvent = {}
local LandscapingSculptEvent_mt = Class(LandscapingSculptEvent, Event)

InitStaticEventClass(LandscapingSculptEvent, "LandscapingSculptEvent", EventIds.EVENT_LANDSCAPING_SCULPT)

function LandscapingSculptEvent:emptyNew()
	local self = Event:new(LandscapingSculptEvent_mt)

	return self
end

function LandscapingSculptEvent:new(validateOnly, operation, x, y, z, radius, strength, brushShape, smoothingDistance, terrainPaintingLayer)
	local self = LandscapingSculptEvent:emptyNew()
	self.runConnection = nil
	self.validateOnly = validateOnly
	self.operation = operation
	self.x = x
	self.y = y
	self.z = z
	self.radius = radius
	self.strength = strength
	self.smoothingDistance = smoothingDistance
	self.brushShape = brushShape
	self.terrainPaintingLayer = terrainPaintingLayer

	return self
end

function LandscapingSculptEvent:newServerToClient(validateOnly, errorCode, displacedVolumeOrArea)
	local self = LandscapingSculptEvent:emptyNew()
	self.validateOnly = validateOnly
	self.errorCode = errorCode
	self.displacedVolumeOrArea = displacedVolumeOrArea

	return self
end

function LandscapingSculptEvent:delete()
end

function LandscapingSculptEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.radius)
		streamWriteFloat32(streamId, self.strength)
		streamWriteFloat32(streamId, self.smoothingDistance)
		streamWriteUIntN(streamId, self.operation, Landscaping.OPERATION_NUM_SEND_BITS)
		streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		streamWriteBool(streamId, self.validateOnly)

		if streamWriteBool(streamId, self.operation == Landscaping.OPERATION.PAINT) then
			streamWriteUIntN(streamId, self.terrainPaintingLayer, TerrainDeformation.LAYER_SEND_NUM_BITS)
		end
	else
		streamWriteUIntN(streamId, self.errorCode, TerrainDeformation.STATE_SEND_NUM_BITS)
		streamWriteBool(streamId, self.validateOnly)

		if streamWriteBool(streamId, self.errorCode == TerrainDeformation.STATE_SUCCESS) then
			streamWriteFloat32(streamId, self.displacedVolumeOrArea)
		end
	end
end

function LandscapingSculptEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.radius = streamReadFloat32(streamId)
		self.strength = streamReadFloat32(streamId)
		self.smoothingDistance = streamReadFloat32(streamId)
		self.operation = streamReadUIntN(streamId, Landscaping.OPERATION_NUM_SEND_BITS)
		self.brushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
		self.validateOnly = streamReadBool(streamId)

		if streamReadBool(streamId) then
			self.terrainPaintingLayer = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)
		end
	else
		self.errorCode = streamReadUIntN(streamId, TerrainDeformation.STATE_SEND_NUM_BITS)
		self.validateOnly = streamReadBool(streamId)

		if streamReadBool(streamId) then
			self.displacedVolumeOrArea = streamReadFloat32(streamId)
		else
			self.displacedVolumeOrArea = 0
		end
	end

	self:run(connection)
end

function LandscapingSculptEvent:run(connection)
	if not connection:getIsServer() and g_currentMission ~= nil then
		self.runConnection = connection
		local terrainRootNode = g_currentMission.terrainRootNode
		local serverUserManager = g_currentMission.userManager
		local userId = serverUserManager:getUserIdByConnection(connection)
		local playerFarm = g_farmManager:getFarmByUserId(userId)
		local isMasterUser = serverUserManager:getIsUserIdMasterUser(userId)
		local landscaping = Landscaping:new(g_terrainDeformationQueue, g_farmlandManager, terrainRootNode, g_densityMapHeightManager.placementCollisionMap, playerFarm, userId, isMasterUser, self.validateOnly, self.onSculptingFinished, self)

		landscaping:sculpt(self.x, self.y, self.z, self.radius, self.strength, self.brushShape, self.operation, self.smoothingDistance, self.terrainPaintingLayer)
	else
		g_messageCenter:publish(LandscapingSculptEvent, self.validateOnly, self.errorCode, self.displacedVolumeOrArea)
	end
end

function LandscapingSculptEvent:onSculptingFinished(errorCode, displacedVolumeOrArea, _)
	if self.runConnection ~= nil and self.runConnection.isConnected then
		local response = LandscapingSculptEvent:newServerToClient(self.validateOnly, errorCode, displacedVolumeOrArea)

		self.runConnection:sendEvent(response)
	end
end
