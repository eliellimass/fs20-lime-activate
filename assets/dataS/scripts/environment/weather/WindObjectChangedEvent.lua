WindObjectChangedEvent = {}
local WeatherInitEvent_mt = Class(WindObjectChangedEvent, Event)

InitStaticEventClass(WindObjectChangedEvent, "WindObjectChangedEvent", EventIds.EVENT_WIND_OBJECT_CHANGED_EVENT)

function WindObjectChangedEvent:emptyNew()
	return Event:new(WeatherInitEvent_mt, NetworkNode.CHANNEL_SECONDARY)
end

function WindObjectChangedEvent:new(index, isInitialSync)
	local self = WindObjectChangedEvent:emptyNew()
	self.index = index
	self.isInitialSync = isInitialSync or false

	return self
end

function WindObjectChangedEvent:readStream(streamId, connection)
	self.isInitialSync = streamReadBool(streamId)
	self.index = streamReadUIntN(streamId, Weather.SEND_BITS_WIND_INDEX) + 1

	self:run(connection)
end

function WindObjectChangedEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isInitialSync)
	streamWriteUIntN(streamId, self.index - 1, Weather.SEND_BITS_WIND_INDEX)
end

function WindObjectChangedEvent:run(connection)
	local duration = g_currentMission.environment.weather.windDuration * 0.3

	if self.isInitialSync then
		duration = 0
	end

	g_currentMission.environment.weather:setWindObjectIndex(self.index, duration)
end
