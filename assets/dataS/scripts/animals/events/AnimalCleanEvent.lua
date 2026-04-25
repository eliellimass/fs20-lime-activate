AnimalCleanEvent = {}
local AnimalCleanEvent_mt = Class(AnimalCleanEvent, Event)

InitStaticEventClass(AnimalCleanEvent, "AnimalCleanEvent", EventIds.EVENT_ANIMAL_CLEAN)

function AnimalCleanEvent:emptyNew()
	local self = Event:new(AnimalCleanEvent_mt)

	return self
end

function AnimalCleanEvent:new(husbandry, animalId, dirtScale)
	local self = AnimalCleanEvent:emptyNew()
	self.husbandry = husbandry
	self.animalId = animalId
	self.dirtScale = dirtScale

	return self
end

function AnimalCleanEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.animalId = NetworkUtil.readNodeObjectId(streamId)
	self.dirtScale = NetworkUtil.readCompressedPercentages(streamId, 8)

	self:run(connection)
end

function AnimalCleanEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	NetworkUtil.writeNodeObjectId(streamId, self.animalId)
	NetworkUtil.writeCompressedPercentages(streamId, self.dirtScale, 8)
end

function AnimalCleanEvent:run(connection)
	self.husbandry:setAnimalDirt(self.animalId, self.dirtScale)
end

function AnimalCleanEvent.sendEvent(husbandry, animalId, dirtScale, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(AnimalCleanEvent:new(husbandry, animalId, dirtScale), false)
		else
			g_client:getServerConnection():sendEvent(AnimalCleanEvent:new(husbandry, animalId, dirtScale))
		end
	end
end
