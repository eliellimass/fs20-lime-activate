SiloPlaceable = {}
local SiloPlaceable_mt = Class(SiloPlaceable, Placeable)
SiloPlaceable.PRICE_SELL_FACTOR = 0.7

InitStaticObjectClass(SiloPlaceable, "SiloPlaceable", ObjectIds.OBJECT_SILO_PLACEABLE)

function SiloPlaceable.initPlaceableType()
	g_storeManager:addSpecType("siloVolume", "shopListAttributeIconCapacity", SiloPlaceable.loadSpecValueVolume, SiloPlaceable.getSpecValueVolume)
end

function SiloPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or SiloPlaceable_mt)

	registerObjectClassName(self, "SiloPlaceable")

	return self
end

function SiloPlaceable:delete()
	local storageSystem = g_currentMission.storageSystem

	for _, storage in ipairs(self.storages) do
		if self.unloadingStation ~= nil then
			storageSystem:removeStorageFromUnloadingStations(storage, {
				self.unloadingStation
			})
		end

		if self.loadingStation ~= nil then
			storageSystem:removeStorageFromLoadingStations(storage, {
				self.loadingStation
			})
		end

		storageSystem:removeStorage(storage)
	end

	for _, storage in ipairs(self.storages) do
		storage:delete()
	end

	if self.unloadingStation ~= nil then
		storageSystem:removeUnloadingStation(self.unloadingStation)
		self.unloadingStation:delete()
	end

	if self.loadingStation ~= nil then
		storageSystem:removeLoadingStation(self.loadingStation)
		self.loadingStation:delete()
	end

	unregisterObjectClassName(self)
	SiloPlaceable:superClass().delete(self)
end

function SiloPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not SiloPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.storagePerFarm = Utils.getNoNil(getXMLBool(xmlFile, "placeable.storages#perFarm"), false)
	self.foreignSilo = Utils.getNoNil(getXMLBool(xmlFile, "placeable.storages#foreignSilo"), self.storagePerFarm)
	self.unloadingStation = UnloadingStation:new(self.isServer, self.isClient)

	self.unloadingStation:load(self.nodeId, xmlFile, "placeable.unloadingStation")

	self.unloadingStation.owningPlaceable = self
	self.unloadingStation.hasStoragePerFarm = self.storagePerFarm
	self.loadingStation = LoadingStation:new(self.isServer, self.isClient)

	self.loadingStation:load(self.nodeId, xmlFile, "placeable.loadingStation")

	self.loadingStation.owningPlaceable = self
	self.loadingStation.hasStoragePerFarm = self.storagePerFarm
	local numStorageSets = self.storagePerFarm and FarmManager.MAX_NUM_FARMS or 1

	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		numStorageSets = 1
	end

	self.storages = {}
	local i = 0

	while true do
		local storageKey = string.format("placeable.storages.storage(%d)", i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local storageNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, storageKey .. "#node"))

		if storageNode ~= nil then
			for i = 1, numStorageSets do
				local storage = Storage:new(self.isServer, self.isClient)

				if storage:load(storageNode, xmlFile, storageKey) then
					storage.ownerFarmId = i
					storage.foreignSilo = self.foreignSilo

					table.insert(self.storages, storage)
				end
			end
		else
			g_logManager:xmlWarning(xmlFilename, "Missing 'node' for storage '%s'!", storageKey)
		end

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function SiloPlaceable:finalizePlacement()
	SiloPlaceable:superClass().finalizePlacement(self)

	local storageSystem = g_currentMission.storageSystem

	self.unloadingStation:register(true)
	storageSystem:addUnloadingStation(self.unloadingStation)
	self.loadingStation:register(true)
	storageSystem:addLoadingStation(self.loadingStation)

	for _, storage in ipairs(self.storages) do
		if not self.storagePerFarm then
			storage:setOwnerFarmId(self:getOwnerFarmId(), true)
		end

		storageSystem:addStorage(storage)
		storage:register(true)
		storageSystem:addStorageToUnloadingStations(storage, {
			self.unloadingStation
		})
		storageSystem:addStorageToLoadingStations(storage, {
			self.loadingStation
		})
	end

	local storagesInRange = storageSystem:getStoragesInRange(self.unloadingStation, nil, self:getOwnerFarmId())

	for _, storage in ipairs(storagesInRange) do
		if self.unloadingStation.targetStorages[storage] == nil then
			storageSystem:addStorageToUnloadingStations(storage, {
				self.unloadingStation
			})
		end
	end

	storagesInRange = storageSystem:getStoragesInRange(self.loadingStation, nil, self:getOwnerFarmId())

	for _, storage in ipairs(storagesInRange) do
		if self.loadingStation.sourceStorages[storage] == nil then
			storageSystem:addStorageToLoadingStations(storage, {
				self.loadingStation
			})
		end
	end

	if not self.storagePerFarm then
		local num = 0

		for _, placeable in pairs(g_currentMission.placeables) do
			if placeable:getOwnerFarmId() == self:getOwnerFarmId() and placeable:isa(SiloPlaceable) then
				num = num + 1
			end
		end

		if num == 1 and g_currentMission.missionInfo.difficulty == 1 and g_currentMission.missionInfo.startSiloAmounts ~= nil and not g_currentMission.missionInfo:getIsLoadedFromSavegame() and not g_currentMission.missionInfo.hasLoadedFirstFilledSilo then
			g_currentMission.missionInfo.hasLoadedFirstFilledSilo = true

			for fillTypeName, amount in pairs(g_currentMission.missionInfo.startSiloAmounts) do
				local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

				self:setAmount(fillTypeIndex, amount)
			end
		end
	end
end

function SiloPlaceable:readStream(streamId, connection)
	SiloPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadingStation, unloadingStationId)

		local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.loadingStation, loadingStationId)

		for _, storage in ipairs(self.storages) do
			local storageId = NetworkUtil.readNodeObjectId(streamId)

			storage:readStream(streamId, connection)
			g_client:finishRegisterObject(storage, storageId)
		end
	end
end

function SiloPlaceable:writeStream(streamId, connection)
	SiloPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadingStation))
		self.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadingStation)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadingStation))
		self.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.loadingStation)

		for _, storage in ipairs(self.storages) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(storage))
			storage:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, storage)
		end
	end
end

function SiloPlaceable:setOwnerFarmId(farmId, noEventSend)
	SiloPlaceable:superClass().setOwnerFarmId(self, farmId, noEventSend)

	if self.isServer and not self.storagePerFarm and self.storages ~= nil then
		for _, storage in ipairs(self.storages) do
			storage:setOwnerFarmId(farmId, true)
		end
	end
end

function SiloPlaceable:collectPickObjects(node)
	local foundNode = false

	for _, unloadTrigger in ipairs(self.unloadingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		for _, loadTrigger in ipairs(self.loadingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				foundNode = true

				break
			end
		end
	end

	if not foundNode then
		SiloPlaceable:superClass().collectPickObjects(self, node)
	end
end

function SiloPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not SiloPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	if not self.unloadingStation:loadFromXMLFile(xmlFile, key .. ".unloadingStation") then
		return false
	end

	local i = 0

	while true do
		local storageKey = string.format("%s.storage(%d)", key, i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local index = getXMLInt(xmlFile, storageKey .. "#index")

		if index ~= nil and self.storages[index] ~= nil and not self.storages[index]:loadFromXMLFile(xmlFile, storageKey) then
			return false
		end

		i = i + 1
	end

	return true
end

function SiloPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	SiloPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.unloadingStation:saveToXMLFile(xmlFile, key .. ".unloadingStation", usedModNames)

	for k, storage in ipairs(self.storages) do
		local storageKey = string.format("%s.storage(%d)", key, k - 1)

		setXMLInt(xmlFile, storageKey .. "#index", k)
		storage:saveToXMLFile(xmlFile, storageKey, usedModNames)
	end
end

function SiloPlaceable:setAmount(fillType, amount)
	for _, storage in ipairs(self.storages) do
		local capacity = storage:getFreeCapacity(fillType)

		if capacity > 0 then
			local moved = math.min(amount, capacity)

			storage:setFillLevel(moved, fillType)

			amount = amount - moved
		end

		if amount <= 0.001 then
			break
		end
	end
end

function SiloPlaceable:onSell()
	SiloPlaceable:superClass().onSell(self)

	if self.isServer and self.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(self.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

function SiloPlaceable:canBeSold()
	if self.storagePerFarm then
		return false, nil
	end

	local warning = g_i18n:getText("info_siloExtensionNotEmpty") .. "\n"
	local totalFillLevel = 0
	self.totalFillTypeSellPrice = 0

	for fillTypeIndex, fillLevel in pairs(self.storages[1].fillLevels) do
		totalFillLevel = totalFillLevel + fillLevel

		if fillLevel > 0 then
			local lowestSellPrice = math.huge

			for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
				if unloadingStation.owningPlaceable ~= nil and unloadingStation.isSellingPoint and unloadingStation.acceptedFillTypes[fillTypeIndex] then
					local price = unloadingStation:getEffectiveFillTypePrice(fillTypeIndex)

					if price > 0 then
						lowestSellPrice = math.min(lowestSellPrice, price)
					end
				end
			end

			if lowestSellPrice == math.huge then
				lowestSellPrice = 0.5
			end

			local price = fillLevel * lowestSellPrice * SiloPlaceable.PRICE_SELL_FACTOR
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			warning = string.format("%s%s (%s) - %s: %s\n", warning, fillType.title, g_i18n:formatVolume(fillLevel), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(price, 0, true, true))
			self.totalFillTypeSellPrice = self.totalFillTypeSellPrice + price
		end
	end

	if totalFillLevel > 0 then
		return true, warning
	end

	return true, nil
end

function SiloPlaceable.loadSpecValueVolume(xmlFile, customEnvironment)
	return getXMLInt(xmlFile, "placeable.storages.storage(0)#capacityPerFillType")
end

function SiloPlaceable.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloVolume == nil then
		return nil
	end

	return g_i18n:formatVolume(storeItem.specs.siloVolume)
end
