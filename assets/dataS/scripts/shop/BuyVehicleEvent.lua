BuyVehicleEvent = {}
local BuyVehicleEvent_mt = Class(BuyVehicleEvent, Event)
BuyVehicleEvent.STATE_SUCCESS = 0
BuyVehicleEvent.STATE_FAILED_TO_LOAD = 1
BuyVehicleEvent.STATE_NO_SPACE = 2
BuyVehicleEvent.STATE_NO_PERMISSION = 3
BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY = 4

InitStaticEventClass(BuyVehicleEvent, "BuyVehicleEvent", EventIds.EVENT_BUY_VEHICLE)

function BuyVehicleEvent:emptyNew()
	local self = Event:new(BuyVehicleEvent_mt)

	return self
end

function BuyVehicleEvent:new(filename, outsideBuy, configurations, leaseVehicle, ownerFarmId)
	local self = BuyVehicleEvent:emptyNew()
	self.filename = filename
	self.outsideBuy = outsideBuy
	self.configurations = Utils.getNoNil(configurations, {})
	self.leaseVehicle = Utils.getNoNil(leaseVehicle, false)
	self.ownerFarmId = ownerFarmId

	return self
end

function BuyVehicleEvent:newServerToClient(errorCode, filename, leaseVehicle, price)
	local self = BuyVehicleEvent:emptyNew()
	self.filename = filename
	self.errorCode = errorCode
	self.leaseVehicle = leaseVehicle
	self.price = price

	return self
end

function BuyVehicleEvent:readStream(streamId, connection)
	self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	if not connection:getIsServer() then
		self.outsideBuy = streamReadBool(streamId)
		local numConfigurations = streamReadUInt8(streamId)
		self.configurations = {}

		for i = 1, numConfigurations do
			local name = g_configurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
			local id = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
			self.configurations[name] = id
		end

		self.leaseVehicle = streamReadBool(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.leaseVehicle = streamReadBool(streamId)
		self.price = streamReadInt32(streamId)
	end

	self:run(connection)
end

function BuyVehicleEvent:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))

	if connection:getIsServer() then
		streamWriteBool(streamId, self.outsideBuy)

		local config = {}

		for name, id in pairs(Utils.getNoNil(self.configurations, {})) do
			table.insert(config, {
				nameId = g_configurationManager:getConfigurationIndexByName(name),
				configId = id
			})
		end

		streamWriteUInt8(streamId, #config)

		for i = 1, #config do
			streamWriteUIntN(streamId, config[i].nameId, ConfigurationUtil.SEND_NUM_BITS)
			streamWriteUIntN(streamId, config[i].configId, ConfigurationUtil.SEND_NUM_BITS)
		end

		streamWriteBool(streamId, self.leaseVehicle)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteBool(streamId, self.leaseVehicle)
		streamWriteInt32(streamId, self.price)
	end
end

function BuyVehicleEvent:run(connection)
	if not connection:getIsServer() then
		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
			self.filename = self.filename:lower()
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)

			if dataStoreItem ~= nil then
				local propertyState = Vehicle.PROPERTY_STATE_OWNED
				local price, _ = g_currentMission.economyManager:getBuyPrice(dataStoreItem, self.configurations)
				local payedPrice = price

				if self.leaseVehicle then
					propertyState = Vehicle.PROPERTY_STATE_LEASED
					payedPrice = g_currentMission.economyManager:getInitialLeasingPrice(price)
				end

				if payedPrice <= g_currentMission:getMoney(self.ownerFarmId) then
					if not GS_IS_CONSOLE_VERSION or fileExists(dataStoreItem.xmlFilename) then
						local asyncParams = {
							targetOwner = self,
							connection = connection,
							leaseVehicle = self.leaseVehicle,
							outsideBuy = self.outsideBuy,
							price = payedPrice,
							ownerFarmId = self.ownerFarmId,
							filename = self.filename
						}

						g_currentMission:loadVehiclesAtPlace(dataStoreItem, g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, self.configurations, price, propertyState, self.ownerFarmId, self.onVehicleBoughtCallback, self, asyncParams)
					end
				else
					connection:sendEvent(BuyVehicleEvent:newServerToClient(BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY, self.filename, self.leaseVehicle, payedPrice))
				end
			end
		else
			connection:sendEvent(BuyVehicleEvent:newServerToClient(BuyVehicleEvent.STATE_NO_PERMISSION, self.filename, self.leaseVehicle, 0))
		end
	else
		g_messageCenter:publish(BuyVehicleEvent, self.errorCode, self.leaseVehicle, self.price)
	end
end

function BuyVehicleEvent:onVehicleBoughtCallback(code, params)
	local errorCode = BuyVehicleEvent.STATE_FAILED_TO_LOAD

	if code == BaseMission.VEHICLE_LOAD_OK then
		if not params.outsideBuy then
			if not params.leaseVehicle then
				local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)
				local financeCategory = MoneyType.getMoneyTypeByName(dataStoreItem.financeCategory) or MoneyType.SHOP_VEHICLE_BUY

				g_currentMission:addMoney(-params.price, params.ownerFarmId, financeCategory, true)
			else
				g_currentMission:addMoney(-params.price, params.ownerFarmId, MoneyType.LEASING_COSTS, true)
			end
		end

		errorCode = BuyVehicleEvent.STATE_SUCCESS
	elseif code == BaseMission.VEHICLE_LOAD_NO_SPACE then
		errorCode = BuyVehicleEvent.STATE_NO_SPACE
	end

	params.connection:sendEvent(BuyVehicleEvent:newServerToClient(errorCode, params.filename, params.leaseVehicle, params.price))
end
