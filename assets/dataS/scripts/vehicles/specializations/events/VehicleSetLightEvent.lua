VehicleSetLightEvent = {}
local VehicleSetLightEvent_mt = Class(VehicleSetLightEvent, Event)

InitStaticEventClass(VehicleSetLightEvent, "VehicleSetLightEvent", EventIds.EVENT_VEHICLE_SET_LIGHT)

function VehicleSetLightEvent:emptyNew()
	local self = Event:new(VehicleSetLightEvent_mt)

	return self
end

function VehicleSetLightEvent:new(object, lightsTypesMask)
	local self = VehicleSetLightEvent:emptyNew()
	self.lightsTypesMask = lightsTypesMask
	self.object = object

	return self
end

function VehicleSetLightEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.lightsTypesMask = streamReadInt32(streamId)

	self:run(connection)
end

function VehicleSetLightEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt32(streamId, self.lightsTypesMask)
end

function VehicleSetLightEvent:run(connection)
	self.object:setLightsTypesMask(self.lightsTypesMask, true, true)

	if not connection:getIsServer() then
		g_server:broadcastEvent(VehicleSetLightEvent:new(self.object, self.lightsTypesMask), nil, connection, self.object)
	end
end
