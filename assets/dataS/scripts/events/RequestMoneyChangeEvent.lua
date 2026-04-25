RequestMoneyChangeEvent = {}
local RequestMoneyChangeEvent_mt = Class(RequestMoneyChangeEvent, Event)

InitStaticEventClass(RequestMoneyChangeEvent, "RequestMoneyChangeEvent", EventIds.EVENT_MONEY_CHANGE)

function RequestMoneyChangeEvent:emptyNew()
	local self = Event:new(RequestMoneyChangeEvent_mt)

	return self
end

function RequestMoneyChangeEvent:new(moneyType)
	local self = RequestMoneyChangeEvent:emptyNew()
	self.moneyType = moneyType

	return self
end

function RequestMoneyChangeEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.moneyType.id)
end

function RequestMoneyChangeEvent:readStream(streamId, connection)
	self.moneyType = MoneyType.getMoneyTypeById(streamReadUInt8(streamId))

	self:run(connection)
end

function RequestMoneyChangeEvent:run(connection)
	local farmId = g_currentMission:getPlayerByConnection(connection).farmId

	g_currentMission:broadcastNotifications(self.moneyType, farmId)
end
