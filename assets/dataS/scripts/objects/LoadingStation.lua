LoadingStation = {}
local LoadingStation_mt = Class(LoadingStation, Object)

InitStaticObjectClass(LoadingStation, "LoadingStation", ObjectIds.OBJECT_LOADING_STATION)

function LoadingStation:new(isServer, isClient, customMt)
	return Object:new(isServer, isClient, customMt or LoadingStation_mt)
end

function LoadingStation:load(id, xmlFile, key, customEnv)
	self.rootNode = id
	self.rootNodeName = getName(self.rootNode)
	self.appearsOnPDA = Utils.getNoNil(getXMLBool(xmlFile, key .. "#appearsOnPDA"), false)
	local rawName = Utils.getNoNil(getXMLString(xmlFile, key .. "#stationName"), "LoadingStation")
	self.stationName = g_i18n:convertText(rawName, customEnv)
	self.storageRadius = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#storageRadius"), 50)
	self.sourceStorages = {}
	self.loadTriggers = {}
	local i = 0

	while true do
		local loadTriggerKey = string.format("%s.loadTrigger(%d)", key, i)

		if not hasXMLProperty(xmlFile, loadTriggerKey) then
			break
		end

		local loadTrigger = LoadTrigger:new(self.isServer, self.isClient)

		if loadTrigger:load(self.rootNode, xmlFile, loadTriggerKey) then
			loadTrigger:setSource(self)
			loadTrigger:register(true)
			table.insert(self.loadTriggers, loadTrigger)
		else
			loadTrigger:delete()
		end

		i = i + 1
	end

	if self.appearsOnPDA then
		local mapPosition = self.rootNode
		local mapPositionIndex = getUserAttribute(self.rootNode, "mapPositionIndex")

		if mapPositionIndex ~= nil then
			mapPosition = I3DUtil.indexToObject(self.rootNode, mapPositionIndex)

			if mapPosition == nil then
				mapPosition = self.rootNode
			end
		end

		self.mapHotspot = MapHotspot.loadFromXML(xmlFile, key .. ".mapHotspot", mapPosition, self.baseDirectory)

		g_currentMission:addMapHotspot(self.mapHotspot)
	end

	if hasXMLProperty(xmlFile, key .. ".poiTriggers") then
		self.poiTriggers = {}
		i = 0

		while true do
			local triggerKey = string.format("%s.poiTriggers.poiTrigger(%d)", key, i)

			if not hasXMLProperty(xmlFile, triggerKey) then
				break
			end

			local poiTrigger = POITrigger:new()

			if poiTrigger:loadFromXML(self.rootNode, xmlFile, triggerKey) then
				table.insert(self.poiTriggers, poiTrigger)
			else
				poiTrigger:delete()
			end

			i = i + 1
		end
	end

	return true
end

function LoadingStation:delete()
	if self.poiTriggers ~= nil then
		for _, trigger in ipairs(self.poiTriggers) do
			trigger:delete()
		end

		self.poiTriggers = nil
	end

	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end

	if self.loadTriggers ~= nil then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			loadTrigger:delete()
		end
	end

	LoadingStation:superClass().delete(self)
end

function LoadingStation:readStream(streamId, connection)
	LoadingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			local loadTriggerId = NetworkUtil.readNodeObjectId(streamId)

			loadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(loadTrigger, loadTriggerId)
		end
	end
end

function LoadingStation:writeStream(streamId, connection)
	LoadingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(loadTrigger))
			loadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, loadTrigger)
		end
	end
end

function LoadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function LoadingStation:saveToXMLFile(xmlFile, key, usedModNames)
end

function LoadingStation:addSourceStorage(storage)
	if storage ~= nil then
		if storage.getIsFillTypeSupported ~= nil and storage.setFillLevel ~= nil and storage.getFillLevel ~= nil and storage.getSupportedFillTypes ~= nil then
			self.sourceStorages[storage] = storage

			storage:addLoadingStation(self)
			self:updateProvidedFillTyes()

			return true
		else
			print("Error: LoadingStation '" .. tostring(self.stationName) .. "' can't add storage, because it is not a valid storage object!")
		end
	end
end

function LoadingStation:removeSourceStorage(storage)
	if storage ~= nil and storage.getIsFillTypeSupported ~= nil and storage.setFillLevel ~= nil and storage.getFillLevel ~= nil then
		storage:removeLoadingStation(self)

		self.sourceStorages[storage] = nil

		self:updateProvidedFillTyes()
	end
end

function LoadingStation:updateProvidedFillTyes()
	self.providedFillTypes = {}

	for _, sourceStorage in pairs(self.sourceStorages) do
		local sourceFillTypes = sourceStorage:getSupportedFillTypes()

		for fillType, _ in pairs(sourceFillTypes) do
			self.providedFillTypes[fillType] = true
		end
	end
end

function LoadingStation:getProvidedFillTypes()
	return self.providedFillTypes
end

function LoadingStation:getAllFillLevels(farmId)
	local fillLevels = {}
	local capacity = 0

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			for fillType, fillLevel in pairs(sourceStorage.fillLevels) do
				fillLevels[fillType] = Utils.getNoNil(fillLevels[fillType], 0) + fillLevel
			end

			capacity = capacity + sourceStorage:getCapacity()
		end
	end

	return fillLevels, capacity
end

function LoadingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillTypeIndex == FillType.UNKNOWN or fillDelta == 0 or toolType == nil then
		return 0
	end

	local farmId = fillableObject:getOwnerFarmId()

	if fillableObject:isa(Vehicle) then
		farmId = fillableObject:getActiveFarm()
	end

	local availableFillLevel = 0

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			availableFillLevel = availableFillLevel + Utils.getNoNil(sourceStorage:getFillLevel(fillTypeIndex), 0)
		end
	end

	fillDelta = math.min(fillDelta, availableFillLevel)

	if fillDelta == 0 then
		return 0
	end

	local usedFillLevel = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)
	local appliedFillLevel = usedFillLevel

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			local oldFillLevel = sourceStorage:getFillLevel(fillTypeIndex)

			if oldFillLevel > 0 then
				sourceStorage:setFillLevel(oldFillLevel - usedFillLevel, fillTypeIndex)
			end

			local newFillLevel = sourceStorage:getFillLevel(fillTypeIndex)
			usedFillLevel = usedFillLevel - (oldFillLevel - newFillLevel)

			if usedFillLevel < 0.0001 then
				usedFillLevel = 0

				break
			end
		end
	end

	fillDelta = appliedFillLevel - usedFillLevel

	return fillDelta
end

function LoadingStation:getSourceStorages()
	return self.sourceStorages
end

function LoadingStation:getIsFillAllowedToFarm(farmId)
	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			return true
		end
	end

	return false
end

function LoadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage)
	end
end
