AnimalRidingEvent = {}
local AnimalRidingEvent_mt = Class(AnimalRidingEvent, Event)

InitStaticEventClass(AnimalRidingEvent, "AnimalRidingEvent", EventIds.EVENT_ANIMAL_RIDING)

function AnimalRidingEvent:emptyNew()
	local self = Event:new(AnimalRidingEvent_mt)

	return self
end

function AnimalRidingEvent:new(animal, isActive, player)
	local self = AnimalRidingEvent:emptyNew()
	self.animal = animal
	self.isActive = isActive
	self.player = player

	return self
end

function AnimalRidingEvent:readStream(streamId, connection)
	self.animal = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)

	if self.isActive then
		self.player = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function AnimalRidingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.animal)
	streamWriteBool(streamId, self.isActive)

	if self.isActive then
		NetworkUtil.writeNodeObject(streamId, self.player)
	end
end

function AnimalRidingEvent:run(connection)
	if self.isActive then
		self.animal:activateRiding(self.player, true)
	else
		self.animal:deactivateRiding(true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimalRidingEvent:new(self.animal, self.isActive, self.player), nil, connection, self.animal)
	end
end

function AnimalRidingEvent.sendEvent(animal, isActive, player, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(AnimalRidingEvent:new(animal, isActive, player), false)
		else
			g_client:getServerConnection():sendEvent(AnimalRidingEvent:new(animal, isActive, player))
		end
	end
end
