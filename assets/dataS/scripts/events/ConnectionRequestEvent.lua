ConnectionRequestEvent = {}
local ConnectionRequestEvent_mt = Class(ConnectionRequestEvent, Event)

InitStaticEventClass(ConnectionRequestEvent, "ConnectionRequestEvent", EventIds.EVENT_CONNECTION_REQUEST)

function ConnectionRequestEvent:emptyNew()
	local self = Event:new(ConnectionRequestEvent_mt)

	return self
end

function ConnectionRequestEvent:new(playerStyle, language, password, platform, platformUserId, platformNodeId)
	local self = ConnectionRequestEvent:emptyNew()
	self.playerStyle = playerStyle
	self.language = language
	self.password = password
	self.platform = platform
	self.platformUserId = platformUserId
	self.platformNodeId = platformNodeId
	self.uniqueUserId = getUniqueUserId()

	return self
end

function ConnectionRequestEvent:readStream(streamId, connection)
	if self.playerStyle == nil then
		self.playerStyle = PlayerStyle:new()
	end

	self.playerStyle:readStream(streamId, connection)

	self.language = streamReadUInt8(streamId)
	self.password = streamReadString(streamId)
	self.platform = streamReadUInt8(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformNodeId = streamReadString(streamId)
	self.uniqueUserId = streamReadString(streamId)

	self:run(connection)
end

function ConnectionRequestEvent:writeStream(streamId, connection)
	self.playerStyle:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.language)
	streamWriteString(streamId, self.password)
	streamWriteUInt8(streamId, self.platform)
	streamWriteString(streamId, self.platformUserId)
	streamWriteString(streamId, self.platformNodeId)
	streamWriteString(streamId, self.uniqueUserId)
end

function ConnectionRequestEvent:run(connection)
	g_currentMission:onConnectionRequest(connection, self.playerStyle, self.language, self.password, self.platform, self.platformUserId, self.platformNodeId, self.uniqueUserId)
end
