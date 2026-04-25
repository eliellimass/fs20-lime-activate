User = {}
local User_mt = Class(User)

function User:new(customMt)
	local self = setmetatable({}, customMt or User_mt)
	self.id = -1
	self.connection = nil
	self.state = FSBaseMission.USER_STATE_LOADING
	self.nickname = ""
	self.uniqueUserId = ""
	self.languageIndex = 1
	self.isMasterUser = false
	self.connectedTime = 0
	self.platformIndex = 0
	self.platformUserId = 0
	self.platformNodeId = 0
	self.financesVersionCounter = -1
	self.financeUpdateSendTime = 0
	self.playerStyle = nil

	return self
end

function User:readStream(streamId, connection)
	self.id = streamReadInt32(streamId)
	self.nickname = streamReadString(streamId)
	self.uniqueUserId = streamReadString(streamId)
	self.languageIndex = streamReadUInt8(streamId)
	self.isMasterUser = streamReadBool(streamId)
	local playtime = streamReadInt32(streamId)
	self.connectedTime = g_currentMission.time - playtime
	self.platformIndex = streamReadUInt8(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformNodeId = streamReadString(streamId)
end

function User:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.id)
	streamWriteString(streamId, self.nickname)
	streamWriteString(streamId, self.uniqueUserId)
	streamWriteUInt8(streamId, self.languageIndex)
	streamWriteBool(streamId, self.isMasterUser)
	streamWriteInt32(streamId, g_currentMission.time - self.connectedTime)
	streamWriteUInt8(streamId, self.platformIndex)
	streamWriteString(streamId, self.platformUserId)
	streamWriteString(streamId, self.platformNodeId)
end

function User:setId(id)
	self.id = id
end

function User:getId()
	return self.id
end

function User:setState(state)
	self.state = state
end

function User:getState()
	return self.state
end

function User:setUniqueUserId(uniqueUserId)
	self.uniqueUserId = uniqueUserId
end

function User:getUniqueUserId()
	return self.uniqueUserId
end

function User:setConnection(connection)
	self.connection = connection
end

function User:getConnection()
	return self.connection
end

function User:setNickname(name)
	self.nickname = name
end

function User:getNickname()
	return self.nickname
end

function User:setLanguageIndex(index)
	self.languageIndex = index
end

function User:getLanguageIndex()
	return self.languageIndex
end

function User:setIsMasterUser(isMasterUser)
	self.isMasterUser = isMasterUser
end

function User:getIsMasterUser()
	return self.isMasterUser
end

function User:setConnectedTime(connectedTime)
	self.connectedTime = connectedTime
end

function User:getConnectedTime(connectedTime)
	return self.connectedTime
end

function User:setPlatformIndex(platformIndex)
	self.platformIndex = platformIndex
end

function User:getPlatformIndex()
	return self.platformIndex
end

function User:setPlatformUserId(platformUserId)
	self.platformUserId = platformUserId
end

function User:getPlatformUserId()
	return self.platformUserId
end

function User:setPlatformNodeId(platformNodeId)
	self.platformNodeId = platformNodeId
end

function User:getPlatformNodeId()
	return self.platformNodeId
end

function User:setFinancesVersionCounter(financesVersionCounter)
	self.financesVersionCounter = financesVersionCounter
end

function User:getFinancesVersionCounter()
	return self.financesVersionCounter
end

function User:setFinanceUpdateSendTime(financeUpdateSendTime)
	self.financeUpdateSendTime = financeUpdateSendTime
end

function User:getFinanceUpdateSendTime()
	return self.financeUpdateSendTime
end

function User:setPlayerStyle(playerStyle)
	self.playerStyle = playerStyle
end

function User:getPlayerStyle()
	return self.playerStyle
end
