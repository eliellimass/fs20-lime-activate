BalerCreateBaleEvent = {}
local BalerCreateBaleEvent_mt = Class(BalerCreateBaleEvent, Event)

InitStaticEventClass(BalerCreateBaleEvent, "BalerCreateBaleEvent", EventIds.EVENT_BALER_CREATE_BALE)

function BalerCreateBaleEvent:emptyNew()
	local self = Event:new(BalerCreateBaleEvent_mt)

	return self
end

function BalerCreateBaleEvent:new(object, baleFillType, baleTime)
	local self = BalerCreateBaleEvent:emptyNew()
	self.baleFillType = baleFillType
	self.baleTime = baleTime
	self.object = object

	return self
end

function BalerCreateBaleEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.baleTime = streamReadFloat32(streamId)
	self.baleFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:run(connection)
end

function BalerCreateBaleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteFloat32(streamId, self.baleTime)
	streamWriteUIntN(streamId, self.baleFillType, FillTypeManager.SEND_NUM_BITS)
end

function BalerCreateBaleEvent:run(connection)
	self.object:createBale(self.baleFillType)
	self.object:setBaleTime(table.getn(self.object.spec_baler.bales), self.baleTime)
end
