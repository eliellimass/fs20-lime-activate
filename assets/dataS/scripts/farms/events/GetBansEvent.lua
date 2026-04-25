GetBansEvent = {}
local GetBansEvent_mt = Class(GetBansEvent, Event)

InitStaticEventClass(GetBansEvent, "GetBansEvent", EventIds.EVENT_GET_BANS)

function GetBansEvent:emptyNew()
	local self = Event:new(GetBansEvent_mt)

	return self
end

function GetBansEvent:new(bans)
	local self = GetBansEvent:emptyNew()
	self.bans = bans or {}

	return self
end

function GetBansEvent:readStream(streamId, connection)
	local num = streamReadUInt16(streamId)
	self.bans = {}

	for i = 1, num do
		local ban = {
			lastNickname = streamReadString(streamId),
			orderId = streamReadUInt16(streamId),
			time = streamReadString(streamId)
		}

		table.insert(self.bans, ban)
	end

	self:run(connection)
end

function GetBansEvent:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.bans)

	for i, ban in ipairs(self.bans) do
		streamWriteString(streamId, ban.lastNickname)
		streamWriteUInt16(streamId, i)
		streamWriteString(streamId, ban.time)
	end
end

function GetBansEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission.userManager:getIsConnectionMasterUser(connection) then
			print("Connection is not a master user")

			return
		end

		local bans = g_currentMission.bans:getBans()

		connection:sendEvent(GetBansEvent:new(bans))
	else
		g_currentMission.bans:setBansFromEvent(self.bans)
		g_messageCenter:publish(GetBansEvent)
	end
end
