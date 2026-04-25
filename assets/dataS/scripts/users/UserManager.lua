UserManager = {}
local UserManager_mt = Class(UserManager)

function UserManager:new(isServer, customMt)
	local self = setmetatable({}, customMt or UserManager_mt)
	self.isServer = isServer
	self.users = {}
	self.masterUsers = {}
	self.masterUserIdToConnection = {}
	self.idCounter = 0

	return self
end

function UserManager:getNextUserId()
	self.idCounter = self.idCounter + 1

	return self.idCounter
end

function UserManager:addUser(user)
	table.insert(self.users, user)
	g_messageCenter:publish(MessageType.USER_ADDED, user)
end

function UserManager:removeUserByConnection(connection)
	for k, user in ipairs(self.users) do
		if user:getConnection() == connection then
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:removeUser(user)
	for k, u in ipairs(self.users) do
		if user == u then
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:removeUserById(userId)
	for k, user in ipairs(self.users) do
		if userId == user:getId() then
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:getUsers()
	return self.users
end

function UserManager:getNumberOfUsers()
	return #self.users
end

function UserManager:getUserByNickname(nickname, useLowercase)
	if useLowercase then
		nickname = nickname:lower()
	end

	for _, user in ipairs(self.users) do
		local userNickname = user:getNickname()

		if useLowercase then
			userNickname = userNickname:lower()
		end

		if userNickname == nickname then
			return user
		end
	end

	return nil
end

function UserManager:getUserByConnection(connection)
	for _, user in ipairs(self.users) do
		if user:getConnection() == connection then
			return user
		end
	end

	return nil
end

function UserManager:getUserByUniqueId(uniqueUserId)
	for _, user in ipairs(self.users) do
		if user:getUniqueUserId() == uniqueUserId then
			return user
		end
	end

	return nil
end

function UserManager:getUserIdByConnection(connection)
	local user = self:getUserByConnection(connection)

	if user ~= nil then
		return user:getId()
	end

	return -1
end

function UserManager:getUserByUserId(userId)
	if userId == nil then
		return nil
	end

	for _, user in ipairs(self.users) do
		if user:getId() == userId then
			return user
		end
	end

	return nil
end

function UserManager:getNumberOfMasterUsers()
	return #self.masterUsers
end

function UserManager:addMasterUserByConnection(connection)
	assert(self.isServer, "UserManager:addMasterUserByConnection call is only allowed on Server")

	local user = self:getUserByConnection(connection)

	if user ~= nil then
		self:addMasterUser(user)
	end
end

function UserManager:addMasterUser(user)
	ListUtil.addElementToList(self.masterUsers, user)

	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = user:getConnection()

		g_currentMission:broadcastMissionDynamicInfo()
	end

	user:setIsMasterUser(true)
	g_messageCenter:publish(MessageType.MASTERUSER_ADDED, user)
end

function UserManager:removeMasterUser(user)
	user:setIsMasterUser(false)
	ListUtil.removeElementFromList(self.masterUsers, user)

	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = nil
	end
end

function UserManager:getMasterUsers()
	return self.masterUsers
end

function UserManager:getIsUserIdMasterUser(userId)
	assert(self.isServer, "UserManager:getIsUserIdMasterUser call is only allowed on Server")

	return self.masterUserIdToConnection[userId] ~= nil
end

function UserManager:getIsConnectionMasterUser(connection)
	assert(self.isServer, "UserManager:getIsUserIdMasterUser call is only allowed on Server")

	local user = self:getUserByConnection(connection)

	return user:getIsMasterUser()
end
