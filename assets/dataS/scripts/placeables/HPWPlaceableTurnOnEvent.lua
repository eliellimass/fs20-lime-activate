HPWPlaceableTurnOnEvent = {}
local HPWPlaceableTurnOnEvent_mt = Class(HPWPlaceableTurnOnEvent, Event)

InitStaticEventClass(HPWPlaceableTurnOnEvent, "HPWPlaceableTurnOnEvent", EventIds.EVENT_HIGHPRESSURE_WASHER_TURN_ON)

function HPWPlaceableTurnOnEvent:emptyNew()
	local self = Event:new(HPWPlaceableTurnOnEvent_mt)

	return self
end

function HPWPlaceableTurnOnEvent:new(object, isTurnedOn, player)
	local self = HPWPlaceableTurnOnEvent:emptyNew()
	self.object = object
	self.isTurnedOn = isTurnedOn
	self.player = player

	return self
end

function HPWPlaceableTurnOnEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isTurnedOn = streamReadBool(streamId)

	if self.isTurnedOn then
		self.player = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function HPWPlaceableTurnOnEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isTurnedOn)

	if self.isTurnedOn then
		NetworkUtil.writeNodeObject(streamId, self.player)
	end
end

function HPWPlaceableTurnOnEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setIsTurnedOn(self.isTurnedOn, self.player, true)
end

function HPWPlaceableTurnOnEvent.sendEvent(object, isTurnedOn, player, noEventSend)
	if isTurnedOn ~= object.isTurnedOn and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(HPWPlaceableTurnOnEvent:new(object, isTurnedOn, player), nil, , object)
		else
			g_client:getServerConnection():sendEvent(HPWPlaceableTurnOnEvent:new(object, isTurnedOn, player))
		end
	end
end
