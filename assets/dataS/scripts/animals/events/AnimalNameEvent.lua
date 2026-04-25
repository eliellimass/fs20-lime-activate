AnimalNameEvent = {}
local AnimalNameEvent_mt = Class(AnimalNameEvent, Event)

InitStaticEventClass(AnimalNameEvent, "AnimalNameEvent", EventIds.EVENT_ANIMAL_NAME)

function AnimalNameEvent:emptyNew()
	local self = Event:new(AnimalNameEvent_mt)

	return self
end

function AnimalNameEvent:new(husbandry, animalId, name)
	local self = AnimalNameEvent:emptyNew()
	self.husbandry = husbandry
	self.animalId = animalId
	self.name = name

	return self
end

function AnimalNameEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.animalId = NetworkUtil.readNodeObjectId(streamId)
	self.name = streamReadString(streamId)

	self:run(connection)
end

function AnimalNameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	NetworkUtil.writeNodeObjectId(streamId, self.animalId)
	streamWriteString(streamId, self.name)
end

function AnimalNameEvent:run(connection)
	self.husbandry:renameAnimal(self.animalId, self.name, true)
	g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.husbandry)

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false)
	end
end

function AnimalNameEvent.sendEvent(husbandry, animalId, name, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(AnimalNameEvent:new(husbandry, animalId, name), false)
		else
			g_client:getServerConnection():sendEvent(AnimalNameEvent:new(husbandry, animalId, name))
		end
	end
end
