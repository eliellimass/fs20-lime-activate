EnvironmentTimeEvent = {}
local EnvironmentTimeEvent_mt = Class(EnvironmentTimeEvent, Event)

InitStaticEventClass(EnvironmentTimeEvent, "EnvironmentTimeEvent", EventIds.EVENT_ENVIRONMENT_TIME)

function EnvironmentTimeEvent:emptyNew()
	local self = Event:new(EnvironmentTimeEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function EnvironmentTimeEvent:new(currentDay, dayTime)
	local self = EnvironmentTimeEvent:emptyNew()
	self.currentDay = currentDay
	self.dayTime = dayTime

	return self
end

function EnvironmentTimeEvent:readStream(streamId, connection)
	self.currentDay = streamReadInt32(streamId)
	self.dayTime = streamReadFloat32(streamId)

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:setEnvironmentTime(self.currentDay, self.dayTime, false)
	end
end

function EnvironmentTimeEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.currentDay)
	streamWriteFloat32(streamId, self.dayTime)
end

function EnvironmentTimeEvent:run(connection)
	print("The server should not receive a dayTime update")
end
