GreenhouseSetIsWaterTankFillingEvent = {}
local GreenhouseSetIsWaterTankFillingEvent_mt = Class(GreenhouseSetIsWaterTankFillingEvent, Event)

InitStaticEventClass(GreenhouseSetIsWaterTankFillingEvent, "GreenhouseSetIsWaterTankFillingEvent", EventIds.EVENT_GREENHOUSE_SET_WATER_TANK_FILLING)

function GreenhouseSetIsWaterTankFillingEvent:emptyNew()
	local self = Event:new(GreenhouseSetIsWaterTankFillingEvent_mt)

	return self
end

function GreenhouseSetIsWaterTankFillingEvent:new(object, isFilling, trailer)
	local self = GreenhouseSetIsWaterTankFillingEvent:emptyNew()
	self.object = object
	self.isFilling = isFilling
	self.trailer = trailer

	return self
end

function GreenhouseSetIsWaterTankFillingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isFilling = streamReadBool(streamId)

	if self.isFilling and not connection:getIsServer() then
		self.trailer = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function GreenhouseSetIsWaterTankFillingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isFilling)

	if self.isFilling and connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.trailer)
	end
end

function GreenhouseSetIsWaterTankFillingEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	self.object:setIsWaterTankFilling(self.isFilling, self.trailer, true)
end

function GreenhouseSetIsWaterTankFillingEvent.sendEvent(object, isFilling, trailer, noEventSend)
	if isFilling ~= object.isWaterTankFilling and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(GreenhouseSetIsWaterTankFillingEvent:new(object, isFilling, trailer), nil, , object)
		else
			assert(not isFilling or trailer ~= nil)
			g_client:getServerConnection():sendEvent(GreenhouseSetIsWaterTankFillingEvent:new(object, isFilling, trailer))
		end
	end
end
