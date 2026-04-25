UnloadingStation = {}
local UnloadingStation_mt = Class(UnloadingStation, Object)

InitStaticObjectClass(UnloadingStation, "UnloadingStation", ObjectIds.OBJECT_UNLOADING_STATION)

function UnloadingStation:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or UnloadingStation_mt)

	return self
end

function UnloadingStation:load(id, xmlFile, key, customEnv)
	self.rootNode = id
	self.rootNodeName = getName(self.rootNode)
	self.appearsOnPDA = Utils.getNoNil(getXMLBool(xmlFile, key .. "#appearsOnPDA"), false)
	local rawName = Utils.getNoNil(getXMLString(xmlFile, key .. "#stationName"), "UnloadingStation")
	self.stationName = g_i18n:convertText(rawName, customEnv)
	self.storageRadius = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#storageRadius"), 50)
	self.hideFromPricesMenu = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideFromPricesMenu"), false)
	self.targetStorages = {}
	self.unloadTriggers = {}
	local i = 0

	while true do
		local unloadTriggerKey = string.format("%s.unloadTrigger(%d)", key, i)

		if not hasXMLProperty(xmlFile, unloadTriggerKey) then
			break
		end

		local unloadTrigger = UnloadTrigger:new(self.isServer, self.isClient)

		if unloadTrigger:load(self.rootNode, xmlFile, unloadTriggerKey, self, {
			unloadingTriggerIndex = i + 1
		}) then
			unloadTrigger:setTarget(self)
			unloadTrigger:register(true)
			table.insert(self.unloadTriggers, unloadTrigger)
		else
			unloadTrigger:delete()
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

function UnloadingStation:delete()
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

	if self.unloadTriggers ~= nil then
		for _, unloadTrigger in pairs(self.unloadTriggers) do
			unloadTrigger:delete()
		end
	end

	UnloadingStation:superClass().delete(self)
end

function UnloadingStation:readStream(streamId, connection)
	UnloadingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, unloadTrigger in ipairs(self.unloadTriggers) do
			local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)

			unloadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(unloadTrigger, unloadTriggerId)
		end
	end
end

function UnloadingStation:writeStream(streamId, connection)
	UnloadingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, unloadTrigger in ipairs(self.unloadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(unloadTrigger))
			unloadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, unloadTrigger)
		end
	end
end

function UnloadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function UnloadingStation:saveToXMLFile(xmlFile, key, usedModNames)
end

function UnloadingStation:addTargetStorage(storage)
	if storage ~= nil then
		if storage.getIsFillTypeSupported ~= nil and storage.setFillLevel ~= nil and storage.getFillLevel ~= nil then
			self.targetStorages[storage] = storage

			storage:addUnloadingStation(self)

			return true
		else
			print("Error: UnloadingStation '" .. tostring(self.stationName) .. "' can't add storage, because it is not a valid storage object!")
		end
	end
end

function UnloadingStation:removeTargetStorage(storage)
	if storage ~= nil and storage.getIsFillTypeSupported ~= nil and storage.setFillLevel ~= nil and storage.getFillLevel ~= nil then
		storage:removeUnloadingStation(self)

		self.targetStorages[storage] = nil
	end
end

function UnloadingStation:getIsFillTypeSupported(fillTypeIndex)
	for _, targetStorage in pairs(self.targetStorages) do
		if targetStorage:getIsFillTypeSupported(fillTypeIndex, self) then
			return true
		end
	end

	return false
end

function UnloadingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	for _, targetStorage in pairs(self.targetStorages) do
		if targetStorage:getIsFillTypeSupported(fillTypeIndex, self) then
			return true
		end
	end

	return false
end

function UnloadingStation:getFreeCapacity(fillTypeIndex, farmId)
	local freeCapacity = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if farmId == nil or self:hasFarmAccessToStorage(farmId, targetStorage) then
			freeCapacity = freeCapacity + targetStorage:getFreeCapacity(fillTypeIndex)
		end
	end

	return freeCapacity
end

function UnloadingStation:getCapacity(fillTypeIndex, farmId)
	local capacity = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) then
			capacity = capacity + targetStorage:getCapacity(fillTypeIndex)
		end
	end

	return capacity
end

function UnloadingStation:getFillLevel(fillTypeIndex, farmId)
	local fillLevel = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) then
			fillLevel = fillLevel + targetStorage:getFillLevel(fillTypeIndex)
		end
	end

	return fillLevel
end

function UnloadingStation:getIsToolTypeAllowed(toolType)
	return true
end

function UnloadingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	assert(deltaFillLevel >= 0)

	local movedFillLevel = 0

	if self:getIsFillTypeAllowed(fillType) and self:getIsToolTypeAllowed(toolType) then
		for _, targetStorage in pairs(self.targetStorages) do
			if self:hasFarmAccessToStorage(farmId, targetStorage) then
				if targetStorage:getFreeCapacity(fillType) > 0 then
					local oldFillLevel = targetStorage:getFillLevel(fillType)

					targetStorage:setFillLevel(oldFillLevel + deltaFillLevel, fillType)

					local newFillLevel = targetStorage:getFillLevel(fillType)
					movedFillLevel = movedFillLevel + newFillLevel - oldFillLevel
				end

				if movedFillLevel >= deltaFillLevel - 0.001 then
					movedFillLevel = deltaFillLevel

					break
				end
			end
		end
	end

	return movedFillLevel
end

function UnloadingStation:getIsFillAllowedFromFarm(farmId)
	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) then
			return true
		end
	end

	return false
end

function UnloadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage)
	end
end
