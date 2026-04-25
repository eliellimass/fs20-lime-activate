StartSleepStateEvent = {}
local StartSleepStateEvent_mt = Class(StartSleepStateEvent, Event)

InitStaticEventClass(StartSleepStateEvent, "StartSleepStateEvent", EventIds.EVENT_SLEEP_START)

function StartSleepStateEvent:emptyNew()
	local self = Event:new(StartSleepStateEvent_mt)

	return self
end

function StartSleepStateEvent:new(duration)
	local self = StartSleepStateEvent:emptyNew()
	self.duration = duration

	return self
end

function StartSleepStateEvent:readStream(streamId, connection)
	self.duration = streamReadFloat32(streamId)

	self:run(connection)
end

function StartSleepStateEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.duration)
end

function StartSleepStateEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:startSleep(self.duration, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(StartSleepStateEvent:new(self.duration), false)
	end
end

function StartSleepStateEvent.sendEvent(duration, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(StartSleepStateEvent:new(duration), false)
		else
			g_client:getServerConnection():sendEvent(StartSleepStateEvent:new(duration))
		end
	end
end
