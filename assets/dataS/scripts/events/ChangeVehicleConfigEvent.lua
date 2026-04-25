ChangeVehicleConfigEvent = {}
local ChangeVehicleConfigEvent_mt = Class(ChangeVehicleConfigEvent, Event)

InitStaticEventClass(ChangeVehicleConfigEvent, "ChangeVehicleConfigEvent", EventIds.EVENT_CHANGE_VEHICLE_CONFIG)

function ChangeVehicleConfigEvent:emptyNew()
	local self = Event:new(ChangeVehicleConfigEvent_mt)

	return self
end

function ChangeVehicleConfigEvent:new(vehicle, price, farmId, configurations)
	local self = ChangeVehicleConfigEvent:emptyNew()
	self.vehicle = vehicle
	self.farmId = farmId
	self.configurations = configurations
	self.price = price

	return self
end

function ChangeVehicleConfigEvent:newServerToClient(successful)
	local self = ChangeVehicleConfigEvent:emptyNew()
	self.successful = successful

	return self
end

function ChangeVehicleConfigEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.vehicle = NetworkUtil.readNodeObject(streamId)
		self.price = streamReadFloat32(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local numConfigurations = streamReadUInt8(streamId)
		self.configurations = {}

		for i = 1, numConfigurations do
			local name = g_configurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
			local id = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
			self.configurations[name] = id
		end
	else
		self.successful = streamReadBool(streamId)
	end

	self:run(connection)
end

function ChangeVehicleConfigEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
		streamWriteFloat32(streamId, self.price)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

		local numConfigurations = 0

		for _, _ in pairs(self.configurations) do
			numConfigurations = numConfigurations + 1
		end

		streamWriteUInt8(streamId, numConfigurations)

		for configName, configId in pairs(self.configurations) do
			streamWriteUIntN(streamId, g_configurationManager:getConfigurationIndexByName(configName), ConfigurationUtil.SEND_NUM_BITS)
			streamWriteUIntN(streamId, configId, ConfigurationUtil.SEND_NUM_BITS)
		end
	else
		streamWriteBool(streamId, self.successful)
	end
end

function ChangeVehicleConfigEvent:run(connection)
	if not connection:getIsServer() then
		local success = false
		local vehicle = self.vehicle

		if vehicle ~= nil and vehicle.isVehicleSaved and not vehicle.isControlled and g_currentMission:getHasPlayerPermission("buyVehicle", connection) then
			for configName, configId in pairs(self.configurations) do
				ConfigurationUtil.addBoughtConfiguration(vehicle, configName, configId)
				ConfigurationUtil.setConfiguration(vehicle, configName, configId)
			end

			vehicle.isReconfigurating = true

			vehicle:removeFromPhysics()

			local xmlFile = Vehicle.getReloadXML(vehicle)
			local key = "vehicles.vehicle(0)"
			local ret, newVehicle = g_currentMission:loadVehicleFromXML(xmlFile, key, false, false)

			if ret == nil or ret == BaseMission.VEHICLE_LOAD_OK then
				g_currentMission:addMoney(-self.price, self.farmId, MoneyType.SHOP_VEHICLE_BUY, true)
				g_currentMission:removeVehicle(vehicle)

				success = true
			elseif ret == BaseMission.VEHICLE_LOAD_NO_SPACE and newVehicle ~= nil then
				g_currentMission:removeVehicle(newVehicle)
				vehicle:addToPhysics()
			end

			delete(xmlFile)
		end

		connection:sendEvent(ChangeVehicleConfigEvent:newServerToClient(success))
	else
		g_directSellDialog:onVehicleChanged(self.successful)
	end
end
