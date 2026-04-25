Farm = {
	MIN_LOAN = 500000,
	MAX_LOAN = 3000000,
	EQUITY_LOAN_RATIO = 0.8,
	LOAN_INTEREST_RATE = 100,
	PERMISSION = {
		MANAGE_CONTRACTS = "manageContracts",
		SELL_PLACEABLE = "sellPlaceable",
		CREATE_FIELDS = "createFields",
		BUY_VEHICLE = "buyVehicle",
		BUY_PLACEABLE = "buyPlaceable",
		SELL_VEHICLE = "sellVehicle",
		HIRE_ASSISTANT = "hireAssistant",
		RESET_VEHICLE = "resetVehicle",
		TRANSFER_MONEY = "transferMoney",
		MANAGE_CONTRACTING = "manageContracting",
		TRADE_ANIMALS = "tradeAnimals",
		LANDSCAPING = "landscaping",
		UPDATE_FARM = "updateFarm",
		MANAGE_RIGHTS = "manageRights"
	}
}
Farm.PERMISSIONS = {
	Farm.PERMISSION.BUY_VEHICLE,
	Farm.PERMISSION.SELL_VEHICLE,
	Farm.PERMISSION.BUY_PLACEABLE,
	Farm.PERMISSION.SELL_PLACEABLE,
	Farm.PERMISSION.MANAGE_CONTRACTS,
	Farm.PERMISSION.TRADE_ANIMALS,
	Farm.PERMISSION.CREATE_FIELDS,
	Farm.PERMISSION.LANDSCAPING,
	Farm.PERMISSION.HIRE_ASSISTANT,
	Farm.PERMISSION.RESET_VEHICLE,
	Farm.PERMISSION.MANAGE_RIGHTS,
	Farm.PERMISSION.TRANSFER_MONEY,
	Farm.PERMISSION.MANAGE_CONTRACTS,
	Farm.PERMISSION.UPDATE_FARM,
	Farm.PERMISSION.MANAGE_CONTRACTING
}
Farm.NO_PERMISSIONS = {}
Farm.DEFAULT_PERMISSIONS = {}
Farm.COLORS = {
	{
		0.25,
		1,
		0.25,
		1
	},
	{
		0,
		0.0446,
		0.187,
		1
	},
	{
		0.9386,
		0.4678,
		0.0123,
		1
	},
	{
		0.8832,
		0.1636,
		0.0046,
		1
	},
	{
		0.5732,
		0.005,
		0.005,
		1
	},
	{
		0,
		0.2348,
		0.7969,
		1
	},
	{
		0.8879,
		0.0545,
		0.3005,
		1
	},
	{
		0.0908,
		0.004,
		0.1301,
		1
	}
}
Farm.COLOR_SEND_NUM_BITS = 4
Farm.COLOR_SPECTATOR = {
	0,
	0,
	0,
	0
}
local Farm_mt = Class(Farm, Object)

InitStaticObjectClass(Farm, "Farm", ObjectIds.FARM)

function Farm:new(isServer, isClient, customMt, spectator)
	local self = Object:new(isServer, isClient, customMt or Farm_mt)
	self.farmId = nil
	self.name = ""
	self.color = 0
	self.isSpectator = spectator or false

	self:setInitialEconomy()

	self.players = {}
	self.uniqueUserIdToPlayer = {}
	self.userIdToPlayer = {}
	self.activeUsers = {}
	self.contractingFor = {}
	self.handTools = {}
	self.stats = FarmStats:new()

	g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.farmPropertyChanged, self)

	if self.isServer then
		g_currentMission.environment:addDayChangeListener(self)
	end

	self.farmMoneyDirtyFlag = self:getNextDirtyFlag()
	self.lastMoneySent = self.money

	return self
end

function Farm:setInitialEconomy()
	local difficulty = g_currentMission.missionInfo.difficulty
	self.loanMax = 0

	self:updateMaxLoan()

	self.loanAnnualInterestRate = 100 + 100 * (difficulty - 1)

	if self.isSpectator then
		self.money = 0
		self.loan = 0
	else
		self.money = g_currentMission.missionInfo.initialMoney
		self.loan = g_currentMission.missionInfo.initialLoan

		if g_isPresentationVersion then
			self.money = 1000000
		end

		if difficulty == 1 and (g_addTestCommands or GS_IS_MOBILE_VERSION and g_buildTypeParam == "CHINA_GAPP") then
			self.money = 100000000

			print("WARNING: Money Cheat active")
		end
	end
end

function Farm:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.isServer then
		g_currentMission.environment:removeDayChangeListener(self)
	end

	Farm:superClass().delete(self)
end

function Farm:loadFromXMLFile(xmlFile, key)
	self.farmId = getXMLInt(xmlFile, key .. "#farmId")
	self.name = getXMLString(xmlFile, key .. "#name")
	self.color = getXMLInt(xmlFile, key .. "#color")
	self.password = getXMLString(xmlFile, key .. "#password")
	self.loan = getXMLFloat(xmlFile, key .. "#loan")
	self.money = getXMLFloat(xmlFile, key .. "#money")
	self.loanAnnualInterestRate = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#loanAnnualInterestRate"), 100)
	local i = 0

	while true do
		local playerKey = string.format("%s.players.player(%d)", key, i)

		if not hasXMLProperty(xmlFile, playerKey) then
			break
		end

		local player = {
			uniqueUserId = getXMLString(xmlFile, playerKey .. "#uniqueUserId"),
			isFarmManager = Utils.getNoNil(getXMLBool(xmlFile, playerKey .. "#farmManager"), false),
			lastNickname = Utils.getNoNil(getXMLString(xmlFile, playerKey .. "#lastNickname"), ""),
			permissions = {}
		}

		for _, permission in ipairs(Farm.PERMISSIONS) do
			player.permissions[permission] = Utils.getNoNil(getXMLBool(xmlFile, playerKey .. "#" .. permission), false) or player.isFarmManager
		end

		table.insert(self.players, player)

		self.uniqueUserIdToPlayer[player.uniqueUserId] = player
		i = i + 1
	end

	local i = 0

	while true do
		local toolKey = string.format("%s.handTools.handTool(%d)", key, i)

		if not hasXMLProperty(xmlFile, toolKey) then
			break
		end

		local filename = getXMLString(xmlFile, toolKey .. "#filename")

		table.insert(self.handTools, filename)

		i = i + 1
	end

	local i = 0

	while true do
		local contractKey = string.format("%s.contracting.farm(%d)", key, i)

		if not hasXMLProperty(xmlFile, contractKey) then
			break
		end

		local farmId = getXMLInt(xmlFile, contractKey .. "#farmId")
		self.contractingFor[farmId] = true
		i = i + 1
	end

	self.stats:loadFromXMLFile(xmlFile, key)

	return true
end

function Farm:saveToXMLFile(xmlFile, key)
	setXMLInt(xmlFile, key .. "#farmId", self.farmId)
	setXMLString(xmlFile, key .. "#name", self.name)
	setXMLInt(xmlFile, key .. "#color", self.color)

	if self.password ~= nil then
		setXMLString(xmlFile, key .. "#password", self.password)
	end

	setXMLFloat(xmlFile, key .. "#loan", self.loan)
	setXMLFloat(xmlFile, key .. "#money", self.money)
	setXMLFloat(xmlFile, key .. "#loanAnnualInterestRate", self.loanAnnualInterestRate)

	for i, player in ipairs(self.players) do
		local playerKey = string.format("%s.players.player(%d)", key, i - 1)

		setXMLString(xmlFile, playerKey .. "#uniqueUserId", player.uniqueUserId)
		setXMLBool(xmlFile, playerKey .. "#farmManager", player.isFarmManager)
		setXMLString(xmlFile, playerKey .. "#lastNickname", player.lastNickname or "")

		for _, permission in ipairs(Farm.PERMISSIONS) do
			local value = player.permissions[permission]

			if value == nil then
				value = false
			end

			setXMLBool(xmlFile, playerKey .. "#" .. permission, value)
		end
	end

	for i, filename in ipairs(self.handTools) do
		local toolKey = string.format("%s.handTools.handTool(%d)", key, i - 1)

		setXMLString(xmlFile, toolKey .. "#filename", filename)
	end

	local i = 0

	for farmId, set in pairs(self.contractingFor) do
		local contractKey = string.format("%s.contracting.farm(%d)", key, i)

		setXMLInt(xmlFile, contractKey .. "#farmId", farmId)

		i = i + 1
	end

	self.stats:saveToXMLFile(xmlFile, key)
end

function Farm:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteString(streamId, self.name)
	streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
	streamWriteFloat32(streamId, self.money)
	streamWriteFloat32(streamId, self.loan)
	streamWriteBool(streamId, self.isSpectator)

	local numPlayers = table.getn(self.activeUsers)

	streamWriteUInt8(streamId, numPlayers)

	for _, player in ipairs(self.activeUsers) do
		NetworkUtil.writeNodeObjectId(streamId, player.userId)
		streamWriteBool(streamId, player.isFarmManager)

		for _, permission in ipairs(Farm.PERMISSIONS) do
			streamWriteBool(streamId, player.permissions[permission] or player.isFarmManager)
		end
	end

	streamWriteUInt8(streamId, ListUtil.size(self.contractingFor))

	for farmId, set in pairs(self.contractingFor) do
		streamWriteUIntN(streamId, farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end

	streamWriteUInt8(streamId, table.getn(self.handTools))

	for _, filename in ipairs(self.handTools) do
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(filename))
	end
end

function Farm:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.name = streamReadString(streamId)
	self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
	self.money = streamReadFloat32(streamId)
	self.loan = streamReadFloat32(streamId)
	self.isSpectator = streamReadBool(streamId)

	if self.farmId == FarmManager.SPECTATOR_FARM_ID then
		self.isSpectator = true
	end

	local numPlayers = streamReadUInt8(streamId)
	self.players = {}
	self.activeUsers = {}

	for i = 1, numPlayers do
		local player = {
			userId = NetworkUtil.readNodeObjectId(streamId),
			isFarmManager = streamReadBool(streamId),
			permissions = {}
		}

		for _, permission in ipairs(Farm.PERMISSIONS) do
			player.permissions[permission] = streamReadBool(streamId)
		end

		self.userIdToPlayer[player.userId] = player

		table.insert(self.players, player)
		table.insert(self.activeUsers, player)
	end

	local numContracting = streamReadUInt8(streamId)

	for i = 1, numContracting do
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.contractingFor[farmId] = true
	end

	local num = streamReadUInt8(streamId)

	for i = 1, num do
		local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		table.insert(self.handTools, filename)
	end
end

function Farm:writeUpdateStream(streamId, connection, dirtyMask)
	Farm:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if streamWriteBool(streamId, bitAND(dirtyMask, self.farmMoneyDirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.money)

		self.lastMoneySent = self.money
	end
end

function Farm:readUpdateStream(streamId, timestamp, connection)
	Farm:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if streamReadBool(streamId) then
		self.money = streamReadFloat32(streamId)

		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
	end
end

function Farm:merge(other)
	self.money = self.money + other.money
	self.loan = self.loan + other.loan
	self.loanAnnualInterestRate = math.min(self.loanAnnualInterestRate, other.loanAnnualInterestRate)

	self.stats:merge(other.stats)
end

function Farm:resetToSingleplayer()
	local player = {
		uniqueUserId = FarmManager.SINGLEPLAYER_UUID,
		isFarmManager = true,
		permissions = {}
	}

	for _, permission in ipairs(Farm.PERMISSIONS) do
		player.permissions[permission] = true
	end

	self.players = {
		player
	}
	self.color = 1
	self.uniqueUserIdToPlayer[player.uniqueUserId] = player
end

function Farm:getFarmhouse()
	for _, placeable in ipairs(g_currentMission.placeables) do
		if placeable:isa(FarmhousePlaceable) and placeable:getOwnerFarmId() == self.farmId then
			return placeable
		end
	end

	return nil
end

function Farm:getSpawnPoint()
	if not self.isSpectator then
		local farmhouse = self:getFarmhouse()

		if farmhouse ~= nil then
			return farmhouse:getSpawnPoint()
		end
	end

	return g_mission00StartPoint
end

function Farm:getSleepCamera()
	if not self.isSpectator then
		local farmhouse = self:getFarmhouse()

		if farmhouse ~= nil then
			return farmhouse:getSleepCamera()
		end
	end

	return 0
end

function Farm:getNumActivePlayers()
	return table.getn(self.activeUsers)
end

function Farm:getNumPlayers()
	return table.getn(self.players)
end

function Farm:getActiveUsers()
	return self.activeUsers
end

function Farm:isUserFarmManager(userId)
	local player = self.userIdToPlayer[userId]

	return player ~= nil and player.isFarmManager
end

function Farm:getUserPermissions(userId)
	local player = self.userIdToPlayer[userId]

	return player ~= nil and player.permissions or Farm.NO_PERMISSIONS
end

function Farm:setUserPermission(userId, permission, hasPermission)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		player.permissions[permission] = hasPermission

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent:new(userId, player.permissions, player.isFarmManager))
	end
end

function Farm:promoteUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		local fullPermissions = {}

		for _, permissionKey in ipairs(Farm.PERMISSIONS) do
			fullPermissions[permissionKey] = true
		end

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent:new(userId, fullPermissions, true))
	end
end

function Farm:demoteUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		local fullPermissions = {}

		for _, permissionKey in ipairs(Farm.PERMISSIONS) do
			fullPermissions[permissionKey] = false
		end

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent:new(userId, fullPermissions, false))
	end
end

function Farm:canBeDestroyed()
	if #self.activeUsers > 0 then
		return false, "ui_farmDeleteHasPlayers"
	end

	return true
end

function Farm:getColor()
	if self.isSpectator then
		return Farm.COLOR_SPECTATOR
	else
		return Farm.COLORS[self.color]
	end
end

function Farm:getIsContractingFor(farmId)
	return self.contractingFor[farmId] or false
end

function Farm:setIsContractingFor(farmId, isContracting, noSendEvent)
	if self.isServer or noSendEvent then
		if isContracting then
			self.contractingFor[farmId] = true
		else
			self.contractingFor[farmId] = nil
		end

		if self.isServer and not noSendEvent then
			g_server:broadcastEvent(ContractingStateEvent:new(self.farmId, farmId, isContracting))
		end

		g_messageCenter:publish(ContractingStateEvent, self.farmId, farmId, isContracting)
	elseif not noSendEvent then
		g_client:getServerConnection():sendEvent(ContractingStateEvent:new(self.farmId, farmId, isContracting))
	end
end

function Farm:farmPropertyChanged(farmId)
	if farmId == self.farmId and not self.isSpectator then
		self:updateMaxLoan()
	end
end

function Farm:getEquity()
	local equity = 0
	local farmlands = g_farmlandManager:getOwnedFarmlandIdsByFarmId(self.farmId)

	for _, farmlandId in pairs(farmlands) do
		local farmland = g_farmlandManager:getFarmlandById(farmlandId)
		equity = equity + farmland.price
	end

	for _, placeable in pairs(g_currentMission.placeables) do
		if placeable:getOwnerFarmId() == self.farmId then
			equity = equity + placeable:getSellPrice()
		end
	end

	return equity
end

function Farm:updateMaxLoan()
	local roundedTo5000 = math.floor(Farm.EQUITY_LOAN_RATIO * self:getEquity() / 5000) * 5000
	self.loanMax = MathUtil.clamp(roundedTo5000, Farm.MIN_LOAN, Farm.MAX_LOAN)
end

function Farm:calculateDailyLoanInterest()
	local annualInterest = self.loanAnnualInterestRate / 100 * self.loan

	return math.floor(annualInterest / 356)
end

function Farm:changeBalance(amount, moneyType)
	self.money = self.money + amount
	local statistic = moneyType ~= nil and moneyType.statistic or nil

	self.stats:changeFinanceStats(amount, statistic)

	if amount > 0 then
		self.stats:addHeroStat("moneyEarned", amount)
	end

	if math.abs(self.lastMoneySent - self.money) >= 1 then
		self:raiseDirtyFlags(self.farmMoneyDirtyFlag)
		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
	end
end

function Farm:addPurchasedCoins(amount)
	self.money = self.money + amount

	g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
end

function Farm:getBalance()
	return self.money
end

function Farm:getLoan()
	return self.loan
end

function Farm:dayChanged()
	self.stats:archiveFinances()
end

function Farm:getHandTools()
	return self.handTools
end

function Farm:hasHandtool(xmlFilename)
	return ListUtil.hasListElement(self.handTools, xmlFilename:lower())
end

function Farm:addHandTool(xmlFilename)
	ListUtil.addElementToList(self.handTools, xmlFilename:lower())
end

function Farm:removeHandTool(xmlFilename)
	ListUtil.removeElementFromList(self.handTools, xmlFilename:lower())
end

function Farm:addUser(userId, uniqueUserId, isFarmManager, user)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		return
	end

	local player = {}
	isFarmManager = isFarmManager or false
	player.isFarmManager = isFarmManager
	player.userId = userId

	self:updateLastNickname(player, userId, user)

	player.permissions = {}

	for _, permission in ipairs(Farm.PERMISSIONS) do
		player.permissions[permission] = isFarmManager
	end

	if not isFarmManager then
		for _, permission in pairs(Farm.DEFAULT_PERMISSIONS) do
			player.permissions[permission] = true
		end
	end

	if self.isServer then
		player.uniqueUserId = uniqueUserId
		self.uniqueUserIdToPlayer[uniqueUserId] = player
	end

	table.insert(self.players, player)
	table.insert(self.activeUsers, player)

	self.userIdToPlayer[userId] = player
end

function Farm:removeUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		ListUtil.removeElementFromList(self.players, player)
		ListUtil.removeElementFromList(self.activeUsers, player)

		self.userIdToPlayer[userId] = nil

		if self.isServer then
			self.uniqueUserIdToPlayer[player.uniqueUserId] = nil
		end
	end
end

function Farm:onUserJoinGame(uniqueUserId, userId, user)
	local player = self.uniqueUserIdToPlayer[uniqueUserId]

	if self.isSpectator and player == nil then
		self:addUser(userId, uniqueUserId, nil, user)

		return true
	elseif self.userIdToPlayer[userId] == nil then
		player.userId = userId
		self.userIdToPlayer[userId] = player

		self:updateLastNickname(player, userId, user)
		table.insert(self.activeUsers, player)

		return true
	end

	return false
end

function Farm:onUserQuitGame(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		player.userId = nil
		self.userIdToPlayer[userId] = nil

		ListUtil.removeElementFromList(self.activeUsers, player)
	end
end

function Farm:updateLastNickname(player, userId, user)
	if user == nil then
		user = g_currentMission.userManager:getUserByUserId(userId)
	end

	if user ~= nil then
		player.lastNickname = user:getNickname()
	end
end
