StorageSystem = {}
local StorageSystem_mt = Class(StorageSystem)

function StorageSystem:new(accessHandler, customMt)
	local self = setmetatable({}, customMt or StorageSystem_mt)
	self.accessHandler = accessHandler
	self.loadingStations = {}
	self.unloadingStations = {}
	self.storages = {}

	return self
end

function StorageSystem:addStorage(storage)
	if storage ~= nil then
		self.storages[storage] = storage

		return true
	end

	return false
end

function StorageSystem:removeStorage(storage)
	if storage ~= nil then
		self.storages[storage] = nil

		return true
	end

	return false
end

function StorageSystem:hasStorage(storage)
	if storage ~= nil then
		return self.storages[storage] ~= nil
	end

	return false
end

function StorageSystem:getStorages()
	return self.storages
end

function StorageSystem:getStoragesInRange(station, storages, farmId)
	storages = storages or self.storages
	local storagesInRange = {}

	for storage, _ in pairs(storages) do
		if self:getIsStationCompatible(station, storage, farmId) then
			table.insert(storagesInRange, storage)
		end
	end

	return storagesInRange
end

function StorageSystem:addLoadingStation(station)
	if station ~= nil then
		self.loadingStations[station] = station

		return true
	end

	return false
end

function StorageSystem:removeLoadingStation(station)
	if station ~= nil then
		self.loadingStations[station] = nil

		return true
	end

	return false
end

function StorageSystem:getLoadingStations()
	return self.loadingStations
end

function StorageSystem:addStorageToLoadingStations(storage, loadingStations, farmId)
	local success = false

	for _, loadingStation in pairs(loadingStations) do
		if loadingStation:addSourceStorage(storage) then
			success = true
		end
	end

	return success
end

function StorageSystem:removeStorageFromLoadingStations(storage, loadingStations)
	local success = false

	for _, loadingStation in pairs(loadingStations) do
		if loadingStation:removeSourceStorage(storage) then
			success = true
		end
	end

	return success
end

function StorageSystem:getLoadingStationsInRange(stations, storage, farmId)
	stations = stations or self.loadingStations
	local stationsInRange = {}

	for station, _ in pairs(stations) do
		if self:getIsStationCompatible(station, storage, farmId) and not station.isBuyingPoint then
			table.insert(stationsInRange, station)
		end
	end

	return stationsInRange
end

function StorageSystem:addUnloadingStation(station)
	if station ~= nil then
		self.unloadingStations[station] = station

		g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)

		return true
	end

	return false
end

function StorageSystem:removeUnloadingStation(station)
	if station ~= nil then
		self.unloadingStations[station] = nil

		g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)

		return true
	end

	return false
end

function StorageSystem:getUnloadingStations()
	return self.unloadingStations
end

function StorageSystem:getSellingStations()
	local res = {}

	for _, station in pairs(self.unloadingStations) do
		if not station.hideFromPricesMenu then
			res[#res + 1] = station
		end
	end

	return res
end

function StorageSystem:addStorageToUnloadingStations(storage, unloadingStations)
	local success = false

	for _, unloadingStation in pairs(unloadingStations) do
		if unloadingStation:addTargetStorage(storage) then
			success = true
		end
	end

	return success
end

function StorageSystem:removeStorageFromUnloadingStations(storage, unloadingStations)
	local success = false

	for _, unloadingStation in pairs(unloadingStations) do
		if unloadingStation:removeTargetStorage(storage) then
			success = true
		end
	end

	return success
end

function StorageSystem:getUnloadingStationsInRange(stations, storage, farmId)
	stations = stations or self.unloadingStations
	local stationsInRange = {}

	for station, _ in pairs(stations) do
		if self:getIsStationCompatible(station, storage, farmId) then
			table.insert(stationsInRange, station)
		end
	end

	return stationsInRange
end

function StorageSystem:getIsStationCompatible(station, storage, farmId)
	local hasRadius = station.storageRadius ~= nil
	local supportsExtension = station.supportsExtension == nil or station.supportsExtension
	local canAccessTarget = self.accessHandler:canFarmAccess(farmId, station)

	if hasRadius and supportsExtension and canAccessTarget then
		local distance = calcDistanceFrom(storage.rootNode, station.rootNode)

		if distance < station.storageRadius then
			return true
		end
	end

	return false
end
