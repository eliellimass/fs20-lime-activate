AnimalAddEvent = {}
local AnimalAddEvent_mt = Class(AnimalAddEvent, Event)

InitStaticEventClass(AnimalAddEvent, "AnimalAddEvent", EventIds.EVENT_ANIMAL_ADD)

function AnimalAddEvent:emptyNew()
	local self = Event:new(AnimalAddEvent_mt)

	return self
end

function AnimalAddEvent:new(husbandry, animals)
	local self = AnimalAddEvent:emptyNew()
	self.husbandry = husbandry
	self.animals = animals

	return self
end

function AnimalAddEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.animalIds = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		table.insert(self.animalIds, NetworkUtil.readNodeObjectId(streamId))
	end

	self:run(connection)
end

function AnimalAddEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteUIntN(streamId, #self.animals, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.animals) do
		NetworkUtil.writeNodeObject(streamId, animal)
	end
end

function AnimalAddEvent:run(connection)
	for _, animalId in ipairs(self.animalIds) do
		self.husbandry:addPendingAnimal(animalId)
	end
end
