Bga = {}
local Bga_mt = Class(Bga, Object)

InitStaticObjectClass(Bga, "Bga", ObjectIds.OBJECT_BGA)

function Bga:onCreate(id)
	g_logManager:error("BGA onCreate is deprecated!")
end

function Bga:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or Bga_mt)
	self.nodeId = 0
	self.digestateSilo = {}
	self.bunker = {
		updateTimer = 0,
		money = 0
	}
	self.bgaDirtyFlag = self:getNextDirtyFlag()

	return self
end

function Bga:load(id, xmlFile, key, customEnvironment)
	self.nodeId = id
	local siloKey = key .. ".digestateSilo"
	local loadingNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, siloKey .. ".loadingStation#node"))

	if loadingNode ~= nil then
		local loadingStation = LoadingStation:new(self.isServer, self.isClient)

		if loadingStation:load(loadingNode, xmlFile, siloKey .. ".loadingStation", customEnvironment) then
			self.digestateSilo.loadingStation = loadingStation
		end
	end

	if self.digestateSilo.loadingStation == nil then
		g_logManager:warning("Could not load loading station for '%s.loadingStation'!", siloKey)

		return false
	end

	local storages = {}
	local i = 0

	while true do
		local storageKey = string.format("%s.storages.storage(%d)", siloKey, i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local storageNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, storageKey .. "#node"))

		if storageNode ~= nil then
			local storage = Storage:new(self.isServer, self.isClient)

			if storage:load(storageNode, xmlFile, storageKey) then
				table.insert(storages, storage)
				storage:setOwnerFarmId(self:getOwnerFarmId(), true)
			else
				g_logManager:warning("Could not load storage for '%s'!", storageKey)
			end
		else
			g_logManager:warning("Missing 'node' for storage '%s'!", storageKey)
		end

		i = i + 1
	end

	if #storages == 0 then
		g_logManager:warning("Missing digestate silo storages for bga!")

		return false
	end

	self.digestateSilo.storages = storages
	local bunkerKey = "placeable.bga.bunker"
	local unloadingNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, bunkerKey .. ".unloadingStation#node"))

	if unloadingNode ~= nil then
		local unloadingStation = BgaSellStation:new(self.isServer, self.isClient, self)

		if unloadingStation:load(unloadingNode, xmlFile, customEnvironment, bunkerKey .. ".unloadingStation") then
			self.bunker.unloadingStation = unloadingStation

			unloadingStation:addTargetStorage(self)
		end
	end

	if self.bunker.unloadingStation == nil then
		g_logManager:warning("Could not load unloading station for '%s.unloadingStation'!", bunkerKey)

		return false
	end

	self.bunker.slots = {}
	self.bunker.fillTypeToSlot = {}
	local i = 0

	while true do
		local slotKey = string.format("%s.slot(%d)", bunkerKey, i)

		if not hasXMLProperty(xmlFile, slotKey) then
			break
		end

		local slot = {
			capacity = getXMLInt(xmlFile, slotKey .. "#capacity") or 40000,
			litersPerSecond = getXMLFloat(xmlFile, slotKey .. "#litersPerSecond") or 1,
			fillTypes = {},
			fillLevel = 0,
			display = DigitalDisplay:new()
		}

		if not slot.display:load(self.nodeId, xmlFile, slotKey .. ".display") then
			slot.display = nil
		else
			slot.display:setValue(0)
		end

		local found = false
		local j = 0

		while true do
			local fillTypeKey = string.format("%s.fillType(%d)", slotKey, j)

			if not hasXMLProperty(xmlFile, fillTypeKey) then
				break
			end

			local fillTypeCategories = getXMLString(xmlFile, fillTypeKey .. "#fillTypeCategories")
			local fillTypeNames = getXMLString(xmlFile, fillTypeKey .. "#fillTypes")
			local fillTypes = nil

			if fillTypeCategories ~= nil and fillTypeNames == nil then
				fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. tostring(key) .. "' has invalid fillTypeCategory '%s'.")
			elseif fillTypeCategories == nil and fillTypeNames ~= nil then
				fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. tostring(key) .. "' has invalid fillType '%s'.")
			else
				g_logManager:warning("Missing fillTypeCategories or fillTypes attribute for bga slot '%s'!", slotKey)
			end

			for _, fillTypeIndex in pairs(fillTypes) do
				if self.bunker.fillTypeToSlot[fillTypeIndex] == nil then
					self.bunker.fillTypeToSlot[fillTypeIndex] = slot

					if slot.fillTypes[fillTypeIndex] == nil then
						found = true
						slot.fillTypes[fillTypeIndex] = {
							fillLevel = 0,
							scale = getXMLFloat(xmlFile, fillTypeKey .. "#scale") or 1,
							pricePerLiter = getXMLFloat(xmlFile, fillTypeKey .. "#pricePerLiter") or 1
						}
					else
						g_logManager:warning("'%s' already used for '%s'!", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), fillTypeKey)
					end
				else
					g_logManager:warning("'%s' already used by another slot for '%s'!", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), slotKey)
				end
			end

			j = j + 1
		end

		if found then
			table.insert(self.bunker.slots, slot)
		else
			g_logManager:warning("No fillTypes defined for slot '%s'!", slotKey)
		end

		i = i + 1
	end

	self.samples = {}

	if self.isClient then
		self.samples.work = g_soundManager:loadSampleFromXML(xmlFile, "placeable.bga.sounds", "work", self.baseDirectory, self.nodeId, 0, AudioGroup.ENVIRONMENT, nil, )
	end

	g_currentMission.environment:addDayChangeListener(self)

	return true
end

function Bga:register(...)
	Bga:superClass().register(self, ...)

	local storageSystem = g_currentMission.storageSystem

	self.digestateSilo.loadingStation:register(true)
	storageSystem:addLoadingStation(self.digestateSilo.loadingStation)

	for _, storage in ipairs(self.digestateSilo.storages) do
		storage:register(true)
		storageSystem:addStorage(storage)
		storageSystem:addStorageToLoadingStations(storage, {
			self.digestateSilo.loadingStation
		})
	end

	self.bunker.unloadingStation:register(true)
	storageSystem:addUnloadingStation(self.bunker.unloadingStation)
end

function Bga:delete()
	if self.digestateSilo.loadingStation ~= nil then
		self.digestateSilo.loadingStation:delete()
	end

	local storageSystem = g_currentMission.storageSystem

	for _, storage in ipairs(self.digestateSilo.storages) do
		storageSystem:removeStorage(storage)
		storage:delete()
	end

	if self.bunker.unloadingStation ~= nil then
		storageSystem:removeUnloadingStation(self.bunker.unloadingStation)
		self.bunker.unloadingStation:delete()
	end

	if self.isClient then
		for _, sample in pairs(self.samples) do
			g_soundManager:deleteSample(sample)
		end
	end

	g_currentMission.environment:removeDayChangeListener(self)
	g_messageCenter:unsubscribeAll(self)
	Bga:superClass().delete(self)
end

function Bga:setOwnerFarmId(ownerFarmId, noEventSend)
	local oldOwnerFarmId = self:getOwnerFarmId()

	Bga:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)

	if ownerFarmId == AccessHandler.NOBODY then
		if self.isServer and oldOwnerFarmId ~= AccessHandler.EVERYONE and oldOwnerFarmId ~= AccessHandler.NOBODY then
			g_currentMission:addMoney(self.bunker.money, oldOwnerFarmId, MoneyType.INCOME_BGA, true, true)
		end

		self.bunker.money = 0

		for _, slot in ipairs(self.bunker.slots) do
			slot.fillLevel = 0

			for _, data in pairs(slot.fillTypes) do
				data.fillLevel = 0
			end

			if slot.display ~= nil then
				slot.display:setValue(0)
			end
		end

		local loadingStation = self.digestateSilo.loadingStation
		local storages = loadingStation:getSourceStorages()

		for _, targetStorage in pairs(storages) do
			targetStorage:empty()
		end

		if self.isServer then
			self:raiseDirtyFlags(self.bgaDirtyFlag)
		end

		if self.isClient then
			g_soundManager:stopSample(self.samples.work)
		end
	end

	self.digestateSilo.loadingStation:setOwnerFarmId(ownerFarmId)
	self.bunker.unloadingStation:setOwnerFarmId(ownerFarmId)

	for _, storage in ipairs(self.digestateSilo.storages) do
		storage:setOwnerFarmId(ownerFarmId, true)
	end
end

function Bga:readStream(streamId, connection)
	if connection:getIsServer() then
		local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.digestateSilo.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.digestateSilo.loadingStation, loadingStationId)

		for _, storage in ipairs(self.digestateSilo.storages) do
			local storageId = NetworkUtil.readNodeObjectId(streamId)

			storage:readStream(streamId, connection)
			g_client:finishRegisterObject(storage, storageId)
		end

		local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.bunker.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.bunker.unloadingStation, unloadingStationId)

		for _, slot in ipairs(self.bunker.slots) do
			slot.fillLevel = streamReadInt32(streamId)

			if slot.display ~= nil then
				slot.display:setValue(slot.fillLevel)
			end
		end
	end
end

function Bga:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.digestateSilo.loadingStation))
		self.digestateSilo.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.digestateSilo.loadingStation)

		for _, storage in ipairs(self.digestateSilo.storages) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(storage))
			storage:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, storage)
		end

		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.bunker.unloadingStation))
		self.bunker.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.bunker.unloadingStation)

		for _, slot in ipairs(self.bunker.slots) do
			streamWriteInt32(streamId, slot.fillLevel)
		end
	end
end

function Bga:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local fillLevel = 0

		for _, slot in ipairs(self.bunker.slots) do
			slot.fillLevel = streamReadInt32(streamId)
			fillLevel = fillLevel + slot.fillLevel

			if slot.display ~= nil then
				slot.display:setValue(slot.fillLevel)
			end
		end

		if self.isClient then
			if fillLevel > 0 then
				if not g_soundManager:getIsSamplePlaying(self.samples.work) then
					g_soundManager:playSample(self.samples.work)
				end
			elseif g_soundManager:getIsSamplePlaying(self.samples.work) then
				g_soundManager:stopSample(self.samples.work)
			end
		end
	end
end

function Bga:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		for _, slot in ipairs(self.bunker.slots) do
			streamWriteInt32(streamId, slot.fillLevel)
		end
	end
end

function Bga:loadFromXMLFile(xmlFile, key)
	self.bunker.money = getXMLFloat(xmlFile, key .. "#money") or 0

	if not self.digestateSilo.loadingStation:loadFromXMLFile(xmlFile, key .. ".digestateSilo.loadingStation") then
		return false
	end

	local i = 0

	while true do
		local storageKey = string.format("%s.digestateSilo.storage(%d)", key, i)

		if not hasXMLProperty(xmlFile, storageKey) then
			break
		end

		local index = getXMLInt(xmlFile, storageKey .. "#index")

		if index ~= nil then
			if self.digestateSilo.storages[index] ~= nil then
				if not self.digestateSilo.storages[index]:loadFromXMLFile(xmlFile, storageKey) then
					return false
				end
			else
				g_logManager:warning("Could not load digestateSilo storage. Given 'index' '%d' is not defined!", index)
			end
		end

		i = i + 1
	end

	local i = 0

	while true do
		local slotKey = string.format("%s.slot(%d)", key, i)

		if not hasXMLProperty(xmlFile, slotKey) then
			break
		end

		local index = getXMLInt(xmlFile, slotKey .. "#index")

		if index ~= nil then
			local slot = self.bunker.slots[index]

			if slot ~= nil then
				local j = 0

				while true do
					local fillTypeKey = string.format("%s.fillType(%d)", slotKey, j)

					if not hasXMLProperty(xmlFile, fillTypeKey) then
						break
					end

					local fillTypeName = getXMLString(xmlFile, fillTypeKey .. "#fillType")
					local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

					if fillTypeIndex ~= nil and slot.fillTypes[fillTypeIndex] ~= nil then
						slot.fillTypes[fillTypeIndex].fillLevel = getXMLFloat(xmlFile, fillTypeKey .. "#fillLevel") or 0
						slot.fillLevel = slot.fillLevel + slot.fillTypes[fillTypeIndex].fillLevel
					end

					j = j + 1
				end
			end

			if slot.fillLevel > 0 then
				self.bunker.isFilled = true

				self:raiseActive()

				if slot.display ~= nil then
					slot.display:setValue(slot.fillLevel)
				end
			end
		end

		i = i + 1
	end

	return true
end

function Bga:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#money", self.bunker.money)
	self.digestateSilo.loadingStation:saveToXMLFile(xmlFile, key .. ".digestateSilo.loadingStation", usedModNames)

	for k, storage in ipairs(self.digestateSilo.storages) do
		local storageKey = string.format("%s.digestateSilo.storage(%d)", key, k - 1)

		setXMLInt(xmlFile, storageKey .. "#index", k)
		storage:saveToXMLFile(xmlFile, storageKey, usedModNames)
	end

	for k, slot in ipairs(self.bunker.slots) do
		local slotKey = string.format("%s.slot(%d)", key, k - 1)

		setXMLInt(xmlFile, slotKey .. "#index", k)

		local i = 0

		for fillTypeIndex, data in pairs(slot.fillTypes) do
			local fillTypeKey = string.format("%s.fillType(%d)", slotKey, i)

			setXMLString(xmlFile, fillTypeKey .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
			setXMLFloat(xmlFile, fillTypeKey .. "#fillLevel", data.fillLevel)

			i = i + 1
		end
	end
end

function Bga:update(dt)
	if self.bunker.isFilled then
		self:raiseActive()
	end

	if self.isClient then
		if self.bunker.isFilled then
			if not g_soundManager:getIsSamplePlaying(self.samples.work) then
				g_soundManager:playSample(self.samples.work)
			end
		elseif g_soundManager:getIsSamplePlaying(self.samples.work) then
			g_soundManager:stopSample(self.samples.work)
		end
	end
end

function Bga:updateTick(dt)
	if self.isServer and self.bunker.isFilled then
		self.bunker.updateTimer = self.bunker.updateTimer + dt

		if self.bunker.updateTimer > 1000 then
			self.bunker.isFilled = false

			for _, slot in ipairs(self.bunker.slots) do
				slot.fillLevel = 0

				for _, data in pairs(slot.fillTypes) do
					if data.fillLevel > 0 then
						local deltaLiters = math.min(slot.litersPerSecond * g_currentMission:getEffectiveTimeScale(), data.fillLevel)
						data.fillLevel = data.fillLevel - deltaLiters
						local converted = deltaLiters * data.scale

						if converted > 0 then
							self:addDigestate(converted)
						end

						if deltaLiters > 0 then
							self:raiseDirtyFlags(self.bgaDirtyFlag)
						end
					end

					slot.fillLevel = slot.fillLevel + data.fillLevel
				end

				if slot.fillLevel > 0 then
					self.bunker.isFilled = true
				end

				if slot.display ~= nil then
					slot.display:setValue(slot.fillLevel)
				end
			end

			self.bunker.updateTimer = 0
		end
	end
end

function Bga:addDigestate(deltaFillLevel)
	local loadingStation = self.digestateSilo.loadingStation
	local storages = loadingStation:getSourceStorages()
	local fillType = FillType.DIGESTATE

	for _, targetStorage in pairs(storages) do
		if loadingStation:hasFarmAccessToStorage(self:getOwnerFarmId(), targetStorage) and targetStorage:getFreeCapacity(fillType) > 0 then
			local oldFillLevel = targetStorage:getFillLevel(fillType)

			targetStorage:setFillLevel(oldFillLevel + deltaFillLevel, fillType)

			local newFillLevel = targetStorage:getFillLevel(fillType)
			deltaFillLevel = deltaFillLevel - (newFillLevel - oldFillLevel)
		end
	end
end

function Bga:dayChanged()
	if self.isServer and self:getOwnerFarmId() ~= AccessHandler.EVERYONE then
		g_currentMission:addMoney(self.bunker.money, self:getOwnerFarmId(), MoneyType.INCOME_BGA, true, true)

		self.bunker.money = 0
	end
end

function Bga:getIsFillTypeSupported(fillTypeIndex)
	return self.bunker.fillTypeToSlot[fillTypeIndex] ~= nil
end

function Bga:getFillLevel(fillTypeIndex)
	local slot = self.bunker.fillTypeToSlot[fillTypeIndex]

	if slot == nil then
		return 0
	end

	return slot.fillLevel
end

function Bga:getCapacity(fillTypeIndex)
	local slot = self.bunker.fillTypeToSlot[fillTypeIndex]

	if slot == nil then
		return 0
	end

	return slot.capacity
end

function Bga:setFillLevel(fillLevel, fillTypeIndex)
	local oldFillLevel = self:getFillLevel(fillTypeIndex)
	fillLevel = MathUtil.clamp(fillLevel, 0, self:getCapacity(fillTypeIndex))
	local delta = fillLevel - oldFillLevel

	if delta == 0 then
		return
	end

	local slot = self.bunker.fillTypeToSlot[fillTypeIndex]

	if slot == nil then
		return
	end

	slot.fillLevel = fillLevel
	local data = slot.fillTypes[fillTypeIndex]
	data.fillLevel = data.fillLevel + delta

	if self.isServer then
		self:raiseDirtyFlags(self.bgaDirtyFlag)

		local price = delta * self:getFillTypeLiterPrice(fillTypeIndex) * EconomyManager.getPriceMultiplier()
		self.bunker.money = self.bunker.money + price
	end

	if slot.fillLevel > 0 then
		self.bunker.isFilled = true

		self:raiseActive()
	end

	if slot.display ~= nil then
		slot.display:setValue(slot.fillLevel)
	end
end

function Bga:getFillTypeLiterPrice(fillTypeIndex)
	local slot = self.bunker.fillTypeToSlot[fillTypeIndex]

	if slot == nil then
		return 0
	end

	local data = slot.fillTypes[fillTypeIndex]

	return data.pricePerLiter
end

function Bga:getFreeCapacity(fillTypeIndex)
	return self:getCapacity(fillTypeIndex) - self:getFillLevel(fillTypeIndex)
end

function Bga:getSupportedFillTypes()
	return self.fillTypes
end

function Bga:addUnloadingStation(station)
end

function Bga:removeUnloadingStation(station)
end
