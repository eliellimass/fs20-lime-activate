GetAdminEvent = {}
local GetAdminEvent_mt = Class(GetAdminEvent, Event)

InitStaticEventClass(GetAdminEvent, "GetAdminEvent", EventIds.EVENT_GET_ADMIN)

function GetAdminEvent:emptyNew()
	local self = Event:new(GetAdminEvent_mt)

	return self
end

function GetAdminEvent:new(password)
	local self = GetAdminEvent:emptyNew()
	self.password = password

	return self
end

function GetAdminEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer())

	self.password = streamReadString(streamId)

	if g_currentMission:getIsServer() and not connection:getIsServer() then
		local state = GetAdminAnswerEvent.NOT_SUPPORTED

		if g_dedicatedServerInfo ~= nil then
			if g_dedicatedServerInfo.adminPassword == self.password then
				state = GetAdminAnswerEvent.ACCESS_GRANTED

				g_currentMission.userManager:addMasterUserByConnection(connection)
			else
				state = GetAdminAnswerEvent.ACCESS_DENIED
			end
		end

		local userId = g_currentMission.userManager:getUserIdByConnection(connection)

		connection:sendEvent(GetAdminAnswerEvent:new(state))
	end
end

function GetAdminEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.password)
end

function GetAdminEvent:run(connection)
	print("Error: GetAdminEvent is a client to server only event")
end
