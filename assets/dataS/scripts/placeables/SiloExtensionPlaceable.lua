SiloExtensionPlaceable = {}
local SiloExtensionPlaceable_mt = Class(SiloExtensionPlaceable, Placeable)

InitStaticObjectClass(SiloExtensionPlaceable, "SiloExtensionPlaceable", ObjectIds.OBJECT_SILO_EXTENSION_PLACEABLE)

SiloExtensionPlaceable.PRICE_SELL_FACTOR = 0.6

function SiloExtensionPlaceable.initPlaceableType()
	g_storeManager:addSpecType("siloExtensionVolume", "shopListAttributeIconCapacity", SiloExtensionPlaceable.loadSpecValueVolume, SiloExtensionPlaceable.getSpecValueVolume)
end

function SiloExtensionPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or SiloExtensionPlaceable_mt)

	registerObjectClassName(self, "SiloExtensionPlaceable")

	return self
end

function SiloExtensionPlaceable:delete()
	local storageSystem = g_currentMission.storageSystem

	if storageSystem:hasStorage(self.storage) then
		storageSystem:removeStorageFromUnloadingStations(self.storage, self.storage.unloadingStations)
		storageSystem:removeStorageFromLoadingStations(self.storage, self.storage.loadingStations)
		storageSystem:removeStorage(self.storage)
	end

	self.storage:delete()
	unregisterObjectClassName(self)
	SiloExtensionPlaceable:superClass().delete(self)
end

function SiloExtensionPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not SiloExtensionPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local storageKey = "placeable.storage"
	self.foreignSilo = Utils.getNoNil(getXMLBool(xmlFile, storageKey .. "#foreignSilo"), false)

	if hasXMLProperty(xmlFile, storageKey) then
		local storageNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, storageKey .. "#node"))

		if storageNode ~= nil then
			self.storage = Storage:new(self.isServer, self.isClient)

			self.storage:load(storageNode, xmlFile, storageKey)

			self.storage.foreignSilo = self.foreignSilo
		else
			g_logManager:xmlWarning(xmlFilename, "Missing 'node' for storage '%s'!", storageKey)
		end
	else
		g_logManager:xmlWarning(xmlFilename, "Missing 'storage' for siloExtension '%s'!", xmlFilename)
	end

	delete(xmlFile)

	return true
end

function SiloExtensionPlaceable:finalizePlacement()
	SiloExtensionPlaceable:superClass().finalizePlacement(self)

	local storageSystem = g_currentMission.storageSystem
	local ownerFarmId = self:getOwnerFarmId()
	local lastFoundUnloadingStations = storageSystem:getUnloadingStationsInRange(nil, self.storage, ownerFarmId)
	local lastFoundLoadingStations = storageSystem:getLoadingStationsInRange(nil, self.storage, ownerFarmId)

	self.storage:setOwnerFarmId(self:getOwnerFarmId(), true)
	storageSystem:addStorage(self.storage)
	self.storage:register(true)
	storageSystem:addStorageToUnloadingStations(self.storage, lastFoundUnloadingStations)
	storageSystem:addStorageToLoadingStations(self.storage, lastFoundLoadingStations)
end

function SiloExtensionPlaceable:readStream(streamId, connection)
	SiloExtensionPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local storageId = NetworkUtil.readNodeObjectId(streamId)

		self.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(self.storage, storageId)
	end
end

function SiloExtensionPlaceable:writeStream(streamId, connection)
	SiloExtensionPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.storage))
		self.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.storage)
	end
end

function SiloExtensionPlaceable:setOwnerFarmId(farmId, noEventSend)
	SiloExtensionPlaceable:superClass().setOwnerFarmId(self, farmId, noEventSend)

	if self.isServer and self.storage ~= nil then
		self.storage:setOwnerFarmId(farmId, true)
	end
end

function SiloExtensionPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not SiloExtensionPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	if not self.storage:loadFromXMLFile(xmlFile, key .. ".storage") then
		return false
	end

	return true
end

function SiloExtensionPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	SiloExtensionPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
end

function SiloExtensionPlaceable:onSell()
	SiloExtensionPlaceable:superClass().onSell(self)

	if self.isServer and self.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(self.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

function SiloExtensionPlaceable:getCanBePlacedAt(x, y, z, distance, farmId)
	local canBePlaced = SiloExtensionPlaceable:superClass().getCanBePlacedAt(self, x, y, z, distance, farmId)
	self.lastFoundUnloadingStations = nil
	self.lastFoundLoadingStations = nil

	if canBePlaced then
		local a, b, c = getTranslation(self.nodeId)

		setTranslation(self.nodeId, x, y, z)

		local storageSystem = g_currentMission.storageSystem
		self.lastFoundUnloadingStations = storageSystem:getUnloadingStationsInRange(nil, self.storage, farmId)

		if table.getn(self.lastFoundUnloadingStations) ~= 0 then
			self.lastFoundLoadingStations = storageSystem:getLoadingStationsInRange(nil, self.storage, farmId)

			if table.getn(self.lastFoundLoadingStations) == 0 then
				canBePlaced = false
			end
		else
			canBePlaced = false
		end

		setTranslation(self.nodeId, a, b, c)
	end

	return canBePlaced
end

function SiloExtensionPlaceable:canBeSold()
	local warning = g_i18n:getText("info_siloExtensionNotEmpty")
	local totalFillLevel = 0
	self.totalFillTypeSellPrice = 0

	for fillTypeIndex, fillLevel in pairs(self.storage.fillLevels) do
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

			local price = fillLevel * lowestSellPrice * SiloExtensionPlaceable.PRICE_SELL_FACTOR
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			warning = string.format("%s%s (%d %s) - %s: %s\n", warning, fillType.nameI18N, g_i18n:getFluid(fillLevel), g_i18n:getText("unit_literShort"), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(price, 0, true, true))
			self.totalFillTypeSellPrice = self.totalFillTypeSellPrice + price
		end
	end

	if totalFillLevel > 0 then
		return true, warning
	end

	return true, nil
end

function SiloExtensionPlaceable.loadSpecValueVolume(xmlFile, customEnvironment)
	return getXMLInt(xmlFile, "placeable.storage#capacityPerFillType")
end

function SiloExtensionPlaceable.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloExtensionVolume == nil then
		return nil
	end

	return g_i18n:formatVolume(storeItem.specs.siloExtensionVolume)
end
