UnbanEvent = {}
local UnbanEvent_mt = Class(UnbanEvent, Event)

InitStaticEventClass(UnbanEvent, "UnbanEvent", EventIds.EVENT_UNBAN)

function UnbanEvent:emptyNew()
	local self = Event:new(UnbanEvent_mt)

	return self
end

function UnbanEvent:new(lastNickname, orderId)
	local self = UnbanEvent:emptyNew()
	self.lastNickname = lastNickname
	self.orderId = orderId

	return self
end

function UnbanEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer(), "UnbanEvent is a client to server only event")

	self.lastNickname = streamReadString(streamId)
	self.orderId = streamReadUInt16(streamId)

	self:run(connection)
end

function UnbanEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.lastNickname)
	streamWriteUInt16(streamId, self.orderId)
end

function UnbanEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")

			return
		end

		g_currentMission.bans:removeUserFromClient(self.lastNickname, self.orderId)
	else
		print("Error: UnbanEvent is a client to server only event")
	end
end
