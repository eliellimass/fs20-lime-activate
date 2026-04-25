WoodSellEvent = {}
local WoodSellEvent_mt = Class(WoodSellEvent, Event)

InitStaticEventClass(WoodSellEvent, "WoodSellEvent", EventIds.EVENT_SELL_WOOD)

function WoodSellEvent:emptyNew()
	local self = Event:new(WoodSellEvent_mt)

	return self
end

function WoodSellEvent:new(woodSellStation, farmId)
	local self = WoodSellEvent:emptyNew()

	assert(g_server == nil, "Client->Server event")

	self.woodSellStation = woodSellStation
	self.farmId = farmId

	return self
end

function WoodSellEvent:readStream(streamId, connection)
	self.woodSellStation = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function WoodSellEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.woodSellStation)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function WoodSellEvent:run(connection)
	if not connection:getIsServer() then
		self.woodSellStation:sellWood(self.farmId)
	end
end
