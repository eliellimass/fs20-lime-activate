AnimalRemoveEvent = {}
local AnimalRemoveEvent_mt = Class(AnimalRemoveEvent, Event)

InitStaticEventClass(AnimalRemoveEvent, "AnimalRemoveEvent", EventIds.EVENT_ANIMAL_REMOVE)

function AnimalRemoveEvent:emptyNew()
	local self = Event:new(AnimalRemoveEvent_mt)

	return self
end

function AnimalRemoveEvent:new(husbandry, animals)
	local self = AnimalRemoveEvent:emptyNew()
	self.husbandry = husbandry
	self.animals = animals

	return self
end

function AnimalRemoveEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.animals = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		table.insert(self.animals, NetworkUtil.readNodeObject(streamId))
	end

	self:run(connection)
end

function AnimalRemoveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteUIntN(streamId, #self.animals, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.animals) do
		NetworkUtil.writeNodeObject(streamId, animal)
	end
end

function AnimalRemoveEvent:run(connection)
	self.husbandry:removeAnimals(self.animals)
end
