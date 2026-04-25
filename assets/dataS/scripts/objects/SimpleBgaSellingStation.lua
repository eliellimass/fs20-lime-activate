SimpleBgaSellingStation = {}
local SimpleBgaSellingStation_mt = Class(SimpleBgaSellingStation, SellingStation)

InitStaticObjectClass(SimpleBgaSellingStation, "SimpleBgaSellingStation", ObjectIds.OBJECT_SIMPLE_BGA_SELLING_STATION)

function SimpleBgaSellingStation:new(isServer, isClient, customMt)
	local self = SellingStation:new(isServer, isClient, customMt or SimpleBgaSellingStation_mt)

	return self
end

function SimpleBgaSellingStation:load(id, xmlFile, key, customEnvironment)
	if not SimpleBgaSellingStation:superClass().load(self, id, xmlFile, key, customEnvironment) then
		return false
	end

	self.consumePerMs = (getXMLFloat(xmlFile, key .. ".bunkerSilos#consumePerDay") or 100000) / 24 / 60 / 60 / 1000
	self.manurePercentage = getXMLFloat(xmlFile, key .. "#manurePercentage") or 0.2
	self.sortedBunkerSilos = {}
	self.bunkerSilos = {}
	local i = 0

	while true do
		local bunkerKey = string.format("%s.bunkerSilos.bunkerSilo(%d)", key, i)

		if not hasXMLProperty(xmlFile, bunkerKey) then
			break
		end

		local bunkerSilo = {
			unloadingTriggerIndex = getXMLInt(xmlFile, bunkerKey .. "#unloadingTriggerIndex") or 1,
			capacity = getXMLFloat(xmlFile, bunkerKey .. "#capacity") or 1,
			consumeTimer = 0,
			consumeDelay = getXMLFloat(xmlFile, bunkerKey .. "#consumeDelay") or 60000,
			fillLevel = 0,
			fillLevelSend = 0,
			fillPlanes = {}
		}
		local j = 0

		while true do
			local fillPlaneKey = string.format("%s.fillPlane(%d)", bunkerKey, j)

			if not hasXMLProperty(xmlFile, fillPlaneKey) then
				break
			end

			local entry = {
				node = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, fillPlaneKey .. "#node")),
				minY = getXMLFloat(xmlFile, fillPlaneKey .. "#minY") or 0,
				maxY = getXMLFloat(xmlFile, fillPlaneKey .. "#maxY") or 1
			}

			if entry.node ~= nil then
				table.insert(bunkerSilo.fillPlanes, entry)
			else
				g_logManager:warning("Failed to load fill plane node for '%s'", fillPlaneKey)
			end

			j = j + 1
		end

		if self.bunkerSilos[bunkerSilo.unloadingTriggerIndex] == nil then
			self.bunkerSilos[bunkerSilo.unloadingTriggerIndex] = bunkerSilo

			table.insert(self.sortedBunkerSilos, bunkerSilo)
		end

		i = i + 1
	end

	self.loadingNode = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, key .. ".loadingStation#node"))

	if self.loadingNode ~= nil then
		local loadingStation = LoadingStation:new(self.isServer, self.isClient)

		if loadingStation:load(self.loadingNode, xmlFile, key .. ".loadingStation", customEnvironment) then
			self.loadingStation = loadingStation
		end
	end

	self.storages = {}
	i = 0

	while true do
		local storageKey = string.format("%s.storages.storage(%d)", key, i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local storageNode = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, storageKey .. "#node"))

		if storageNode ~= nil then
			local storage = Storage:new(self.isServer, self.isClient)

			if storage:load(storageNode, xmlFile, storageKey) then
				self.loadingStation:addSourceStorage(storage)
				table.insert(self.storages, storage)
				storage:setOwnerFarmId(self:getOwnerFarmId(), true)
			else
				g_logManager:warning("Could not load storage for '%s'!", storageKey)
			end
		else
			g_logManager:warning("Missing 'node' for storage '%s'!", storageKey)
		end

		i = i + 1
	end

	if #self.storages == 0 then
		g_logManager:warning("Missing storages for simple bga!")

		return false
	end

	self.dirtyFlag = self:getNextDirtyFlag()

	return true
end

function SimpleBgaSellingStation:register(...)
	SimpleBgaSellingStation:superClass().register(self, ...)

	local storageSystem = g_currentMission.storageSystem

	self.loadingStation:register(true)
	storageSystem:addLoadingStation(self.loadingStation)

	for _, storage in ipairs(self.storages) do
		storage:register(true)
		storageSystem:addStorage(storage)
		storageSystem:addStorageToLoadingStations(storage, {
			self.loadingStation
		})
	end
end

function SimpleBgaSellingStation:delete()
	local storageSystem = g_currentMission.storageSystem

	for _, storage in ipairs(self.storages) do
		self.loadingStation:removeSourceStorage(storage)
		storageSystem:removeStorage(storage)
		storage:delete()
	end

	if self.loadingStation ~= nil then
		self.loadingStation:delete()
	end

	SimpleBgaSellingStation:superClass().delete(self)
end

function SimpleBgaSellingStation:setOwnerFarmId(ownerFarmId, noEventSend)
	SimpleBgaSellingStation:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	self.loadingStation:setOwnerFarmId(ownerFarmId)

	for _, storage in ipairs(self.storages) do
		storage:setOwnerFarmId(ownerFarmId, true)
	end
end

function SimpleBgaSellingStation:readStream(streamId, connection)
	if connection:getIsServer() then
		local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.loadingStation, loadingStationId)

		for _, storage in ipairs(self.storages) do
			local storageId = NetworkUtil.readNodeObjectId(streamId)

			storage:readStream(streamId, connection)
			g_client:finishRegisterObject(storage, storageId)
		end

		for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
			self:addBunkerSiloFillLevel(bunkerSilo.unloadingTriggerIndex, bunkerSilo.fillLevel - streamReadInt32(streamId))
		end
	end
end

function SimpleBgaSellingStation:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadingStation))
		self.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.loadingStation)

		for _, storage in ipairs(self.storages) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(storage))
			storage:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, storage)
		end

		for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
			streamWriteInt32(streamId, bunkerSilo.fillLevel)
		end
	end
end

function SimpleBgaSellingStation:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
			self:addBunkerSiloFillLevel(bunkerSilo.unloadingTriggerIndex, bunkerSilo.fillLevel - streamReadInt32(streamId))
		end
	end
end

function SimpleBgaSellingStation:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
			streamWriteInt32(streamId, bunkerSilo.fillLevel)
		end
	end
end

function SimpleBgaSellingStation:loadFromXMLFile(xmlFile, key)
	if not SimpleBgaSellingStation:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
		self:addBunkerSiloFillLevel(i, getXMLFloat(xmlFile, string.format("%s.bunkerSilo(%d)#fillLevel", key, i - 1)) or 0)
	end

	if not self.loadingStation:loadFromXMLFile(xmlFile, key .. ".loadingStation") then
		return false
	end

	local i = 0

	while true do
		local storageKey = string.format("%s.storage(%d)", key, i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local index = getXMLInt(xmlFile, storageKey .. "#index")

		if index ~= nil then
			if self.storages[index] ~= nil then
				if not self.storages[index]:loadFromXMLFile(xmlFile, storageKey) then
					return false
				end
			else
				g_logManager:warning("Could not load storage. Given 'index' '%d' is not defined!", index)
			end
		end

		i = i + 1
	end

	return true
end

function SimpleBgaSellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	SimpleBgaSellingStation:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
		setXMLFloat(xmlFile, string.format("%s.bunkerSilo(%d)#fillLevel", key, i - 1), bunkerSilo.fillLevel)
	end

	self.loadingStation:saveToXMLFile(xmlFile, key .. ".loadingStation", usedModNames)

	for k, storage in ipairs(self.storages) do
		local storageKey = string.format("%s.storage(%d)", key, k - 1)

		setXMLInt(xmlFile, storageKey .. "#index", k)
		storage:saveToXMLFile(xmlFile, storageKey, usedModNames)
	end
end

function SimpleBgaSellingStation:updateTick(dt)
	SimpleBgaSellingStation:superClass().updateTick(self, dt)

	for i, bunkerSilo in ipairs(self.sortedBunkerSilos) do
		if bunkerSilo.consumeTimer > 0 then
			bunkerSilo.consumeTimer = bunkerSilo.consumeTimer - dt
		elseif self:addBunkerSiloFillLevel(i, -self.consumePerMs * dt * g_currentMission:getEffectiveTimeScale()) < 0 then
			break
		end
	end
end

function SimpleBgaSellingStation:sellFillType(farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)
	local price = SimpleBgaSellingStation:superClass().sellFillType(self, farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)

	self:addBunkerSiloFillLevel(extraAttributes.unloadingTriggerIndex, fillDelta)

	return price
end

function SimpleBgaSellingStation:getFreeCapacity(fillUnitIndex, farmId, extraAttributes)
	if extraAttributes ~= nil then
		local bunkerSilo = self.bunkerSilos[extraAttributes.unloadingTriggerIndex]

		if bunkerSilo ~= nil then
			return bunkerSilo.capacity - bunkerSilo.fillLevel
		end
	end

	return SimpleBgaSellingStation:superClass().getFreeCapacity(self, fillUnitIndex, farmId, extraAttributes)
end

function SimpleBgaSellingStation:getIncomeNameForFillType(fillType, toolType)
	return "incomeBga"
end

function SimpleBgaSellingStation:addBunkerSiloFillLevel(unloadingTriggerIndex, fillDelta)
	local bunkerSilo = self.bunkerSilos[unloadingTriggerIndex]

	if bunkerSilo ~= nil then
		local oldFillLevel = bunkerSilo.fillLevel
		bunkerSilo.fillLevel = MathUtil.clamp(bunkerSilo.fillLevel + fillDelta, 0, bunkerSilo.capacity)
		local realDelta = bunkerSilo.fillLevel - oldFillLevel

		if realDelta ~= 0 then
			local alpha = bunkerSilo.fillLevel / bunkerSilo.capacity

			for _, fillPlane in ipairs(bunkerSilo.fillPlanes) do
				local y = MathUtil.lerp(fillPlane.minY, fillPlane.maxY, alpha)
				local x, _, z = getTranslation(fillPlane.node)

				setTranslation(fillPlane.node, x, y, z)
			end
		end

		if fillDelta > 0 then
			bunkerSilo.consumeTimer = bunkerSilo.consumeDelay
		end

		if realDelta < 0 then
			self:addLiquidManure(-realDelta * self.manurePercentage)
		end

		if math.abs(bunkerSilo.fillLevelSend - bunkerSilo.fillLevel) > 100 then
			self:raiseDirtyFlags(self.dirtyFlag)

			bunkerSilo.fillLevelSend = bunkerSilo.fillLevel
		end

		return realDelta
	end
end

function SimpleBgaSellingStation:addLiquidManure(deltaFillLevel)
	local fillType = FillType.LIQUIDMANURE

	for _, targetStorage in pairs(self.loadingStation:getSourceStorages()) do
		if targetStorage:getFreeCapacity(fillType) > 0 then
			local oldFillLevel = targetStorage:getFillLevel(fillType)

			targetStorage:setFillLevel(oldFillLevel + deltaFillLevel, fillType)

			local newFillLevel = targetStorage:getFillLevel(fillType)
			deltaFillLevel = deltaFillLevel - (newFillLevel - oldFillLevel)
		end
	end

	return deltaFillLevel
end
