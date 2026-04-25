SetCruiseControlSpeedEvent = {}
local SetCruiseControlSpeedEvent_mt = Class(SetCruiseControlSpeedEvent, Event)

InitStaticEventClass(SetCruiseControlSpeedEvent, "SetCruiseControlSpeedEvent", EventIds.EVENT_CRUISECONTROL_SET_SPEED)

function SetCruiseControlSpeedEvent:emptyNew()
	local self = Event:new(SetCruiseControlSpeedEvent_mt)

	return self
end

function SetCruiseControlSpeedEvent:new(vehicle, speed)
	local self = SetCruiseControlSpeedEvent:emptyNew()
	self.speed = speed
	self.vehicle = vehicle

	return self
end

function SetCruiseControlSpeedEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.speed = streamReadUInt8(streamId)

	self:run(connection)
end

function SetCruiseControlSpeedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.speed)
end

function SetCruiseControlSpeedEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end

	self.vehicle:setCruiseControlMaxSpeed(self.speed)
end
