AnimalLoadingTriggerEvent = {}
local AnimalLoadingTriggerEvent_mt = Class(AnimalLoadingTriggerEvent, Event)

InitStaticEventClass(AnimalLoadingTriggerEvent, "AnimalLoadingTriggerEvent", EventIds.EVENT_ANIMAL_LOADING_TRIGGER_EVENT)

function AnimalLoadingTriggerEvent:emptyNew()
	local self = Event:new(AnimalLoadingTriggerEvent_mt)

	return self
end

function AnimalLoadingTriggerEvent:new(trigger, target, animalType, numAnimalsDiff, price)
	local self = AnimalLoadingTriggerEvent:emptyNew()
	self.trigger = trigger
	self.target = target
	self.animalType = animalType
	self.numAnimalsDiff = numAnimalsDiff
	self.price = price

	return self
end

function AnimalLoadingTriggerEvent:readStream(streamId, connection)
	self.trigger = NetworkUtil.readNodeObject(streamId)
	self.target = NetworkUtil.readNodeObject(streamId)
	self.animalType = streamReadUIntN(streamId, AnimalManager.SEND_NUM_BITS)
	self.numAnimalsDiff = streamReadInt32(streamId)
	self.price = streamReadFloat32(streamId)

	self:run(connection)
end

function AnimalLoadingTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.trigger)
	NetworkUtil.writeNodeObject(streamId, self.target)
	streamWriteUIntN(streamId, self.animalType, AnimalManager.SEND_NUM_BITS)
	streamWriteInt32(streamId, self.numAnimalsDiff)
	streamWriteFloat32(streamId, self.price)
end

function AnimalLoadingTriggerEvent:run(connection)
	if not connection:getIsServer() then
		self.trigger:doAnimalLoading(self.target, self.animalType, self.numAnimalsDiff, self.price, g_currentMission.userManager:getUserIdByConnection(connection))
	else
		print("Error: AnimalLoadingTriggerEvent is a client to server only event")
	end
end
