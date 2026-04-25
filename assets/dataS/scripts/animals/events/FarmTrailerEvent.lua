FarmTrailerEvent = {}
local FarmTrailerEvent_mt = Class(FarmTrailerEvent, Event)

InitStaticEventClass(FarmTrailerEvent, "FarmTrailerEvent", EventIds.EVENT_ANIMAL_FARM_TRAILER)

function FarmTrailerEvent:emptyNew()
	local self = Event:new(FarmTrailerEvent_mt)

	return self
end

function FarmTrailerEvent:new(husbandry, trailer, moveToTrailer, moveToHusbandry)
	local self = FarmTrailerEvent:emptyNew()
	self.trailer = trailer
	self.husbandry = husbandry
	self.moveToTrailer = moveToTrailer
	self.moveToHusbandry = moveToHusbandry

	return self
end

function FarmTrailerEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.trailer = NetworkUtil.readNodeObject(streamId)
	self.moveToTrailer = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		table.insert(self.moveToTrailer, NetworkUtil.readNodeObject(streamId))
	end

	self.moveToHusbandry = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		table.insert(self.moveToHusbandry, NetworkUtil.readNodeObject(streamId))
	end

	self:run(connection)
end

function FarmTrailerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	NetworkUtil.writeNodeObject(streamId, self.trailer)
	streamWriteUIntN(streamId, #self.moveToTrailer, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.moveToTrailer) do
		NetworkUtil.writeNodeObject(streamId, animal)
	end

	streamWriteUIntN(streamId, #self.moveToHusbandry, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.moveToHusbandry) do
		NetworkUtil.writeNodeObject(streamId, animal)
	end
end

function FarmTrailerEvent:run(connection)
	FarmTrailerEvent.runLocal(self.husbandry, self.trailer, self.moveToTrailer, self.moveToHusbandry)
end

function FarmTrailerEvent.sendEvent(husbandry, trailer, moveToTrailer, moveToHusbandry)
	if not g_currentMission:getIsServer() then
		g_client:getServerConnection():sendEvent(FarmTrailerEvent:new(husbandry, trailer, moveToTrailer, moveToHusbandry))
	end
end

function FarmTrailerEvent.runLocal(husbandry, trailer, moveToTrailer, moveToHusbandry)
	husbandry:removeAnimals(moveToTrailer)
	husbandry:addAnimals(moveToHusbandry)
	trailer:removeAnimals(moveToHusbandry)
	trailer:addAnimals(moveToTrailer)
end
