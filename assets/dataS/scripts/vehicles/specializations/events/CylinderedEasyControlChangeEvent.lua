CylinderedEasyControlChangeEvent = {}
local CylinderedEasyControlChangeEvent_mt = Class(CylinderedEasyControlChangeEvent, Event)

InitStaticEventClass(CylinderedEasyControlChangeEvent, "CylinderedEasyControlChangeEvent", EventIds.EVENT_CYLINDERED_EASY_CONTROL_CHANGE)

function CylinderedEasyControlChangeEvent:emptyNew()
	local self = Event:new(CylinderedEasyControlChangeEvent_mt)

	return self
end

function CylinderedEasyControlChangeEvent:new(vehicle, isEasyControlActive)
	local self = CylinderedEasyControlChangeEvent:emptyNew()
	self.vehicle = vehicle
	self.isEasyControlActive = isEasyControlActive

	return self
end

function CylinderedEasyControlChangeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isEasyControlActive = streamReadBool(streamId)

	self:run(connection)
end

function CylinderedEasyControlChangeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isEasyControlActive)
end

function CylinderedEasyControlChangeEvent:run(connection)
	if self.vehicle ~= nil then
		self.vehicle:setIsEasyControlActive(self.isEasyControlActive, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(CylinderedEasyControlChangeEvent:new(self.vehicle, self.isEasyControlActive), nil, connection, self.vehicle)
	end
end

function CylinderedEasyControlChangeEvent.sendEvent(vehicle, isEasyControlActive, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(CylinderedEasyControlChangeEvent:new(vehicle, isEasyControlActive), nil, , vehicle)
		elseif g_client ~= nil then
			g_client:getServerConnection():sendEvent(CylinderedEasyControlChangeEvent:new(vehicle, isEasyControlActive))
		end
	end
end
