Storage = {}
local Storage_mt = Class(Storage, Object)

InitStaticObjectClass(Storage, "Storage", ObjectIds.OBJECT_STORAGE)

function Storage:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or Storage_mt)
	self.unloadingStations = {}
	self.loadingStations = {}
	self.rootNode = 0
	self.foreignSilo = false

	return self
end

function Storage:load(id, xmlFile, key)
	self.rootNode = id
	self.capacityPerFillType = getXMLFloat(xmlFile, key .. "#capacityPerFillType") or 100000
	self.costsPerFillLevelAndDay = getXMLFloat(xmlFile, key .. "#costsPerFillLevelAndDay") or 0
	self.fillTypes = {}
	self.fillLevels = {}
	self.sortedFillTypes = {}
	local fillTypeCategories = getXMLString(xmlFile, key .. "#fillTypeCategories")
	local fillTypeNames = getXMLString(xmlFile, key .. "#fillTypes")
	local fillTypes = nil

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. tostring(key) .. "' has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. tostring(key) .. "' has invalid fillType '%s'.")
	else
		print("Warning: '" .. tostring(key) .. "' a 'Storage' entry needs either the 'fillTypeCategories' or 'fillTypes' attribute.")

		return false
	end

	for _, fillType in pairs(fillTypes) do
		self.fillTypes[fillType] = true
	end

	for fillType, _ in pairs(self.fillTypes) do
		table.insert(self.sortedFillTypes, fillType)

		self.fillLevels[fillType] = 0
	end

	table.sort(self.sortedFillTypes)

	self.storageDirtyFlag = self:getNextDirtyFlag()

	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)

	return true
end

function Storage:delete()
	if self.rootNode ~= 0 and entityExists(self.rootNode) then
		delete(self.rootNode)
	end

	g_currentMission.environment:removeHourChangeListener(self)
	g_messageCenter:unsubscribeAll(self)
	Storage:superClass().delete(self)
end

function Storage:readStream(streamId, connection)
	Storage:superClass().readStream(self, streamId, connection)

	for _, fillType in ipairs(self.sortedFillTypes) do
		local fillLevel = 0

		if streamReadBool(streamId) then
			fillLevel = streamReadFloat32(streamId)
		end

		self:setFillLevel(fillLevel, fillType)
	end
end

function Storage:writeStream(streamId, connection)
	Storage:superClass().writeStream(self, streamId, connection)

	for _, fillType in ipairs(self.sortedFillTypes) do
		local fillLevel = self.fillLevels[fillType]

		if streamWriteBool(streamId, fillLevel > 0) then
			streamWriteFloat32(streamId, fillLevel)
		end
	end
end

function Storage:readUpdateStream(streamId, timestamp, connection)
	Storage:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		for _, fillType in ipairs(self.sortedFillTypes) do
			local fillLevel = 0

			if streamReadBool(streamId) then
				fillLevel = streamReadFloat32(streamId)
			end

			self:setFillLevel(fillLevel, fillType)
		end
	end
end

function Storage:writeUpdateStream(streamId, connection, dirtyMask)
	Storage:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.storageDirtyFlag) ~= 0) then
		for _, fillType in ipairs(self.sortedFillTypes) do
			local fillLevel = self.fillLevels[fillType]

			if streamWriteBool(streamId, fillLevel > 0) then
				streamWriteFloat32(streamId, fillLevel)
			end
		end
	end
end

function Storage:loadFromXMLFile(xmlFile, key)
	self:setOwnerFarmId(Utils.getNoNil(getXMLInt(xmlFile, key .. "#farmId"), AccessHandler.EVERYONE), true)

	local i = 0

	while true do
		local siloKey = string.format(key .. ".node(%d)", i)

		if not hasXMLProperty(xmlFile, siloKey) then
			break
		end

		local fillTypeStr = getXMLString(xmlFile, siloKey .. "#fillType")
		local fillLevel = math.max(Utils.getNoNil(getXMLFloat(xmlFile, siloKey .. "#fillLevel"), 0), 0)
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex ~= nil then
			if self.fillLevels[fillTypeIndex] ~= nil then
				self:setFillLevel(fillLevel, fillTypeIndex, nil)
			else
				print("Warning: Filltype '" .. fillTypeStr .. "' not supported by Storage " .. getName(self.rootNode))
			end
		else
			print("Error: Invalid filltype '" .. fillTypeStr .. "'")
		end

		i = i + 1
	end

	return true
end

function Storage:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLInt(xmlFile, key .. "#farmId", self:getOwnerFarmId())

	local index = 0

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		if fillLevel > 0 then
			local fillLevelKey = string.format("%s.node(%d)", key, index)
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)

			setXMLString(xmlFile, fillLevelKey .. "#fillType", fillTypeName)
			setXMLFloat(xmlFile, fillLevelKey .. "#fillLevel", fillLevel)

			index = index + 1
		end
	end
end

function Storage:empty()
	for fillType, _ in pairs(self.fillLevels) do
		self.fillLevels[fillType] = 0

		if self.isServer then
			self:raiseDirtyFlags(self.storageDirtyFlag)
		end
	end
end

function Storage:getIsFillTypeSupported(fillType)
	return self.fillTypes[fillType] == true
end

function Storage:getFillLevel(fillType)
	return self.fillLevels[fillType] or 0
end

function Storage:getCapacity(fillType)
	return self.capacityPerFillType
end

function Storage:setFillLevel(fillLevel, fillType)
	fillLevel = MathUtil.clamp(fillLevel, 0, self.capacityPerFillType)

	if self.fillLevels[fillType] ~= nil and fillLevel ~= self.fillLevels[fillType] then
		self.fillLevels[fillType] = fillLevel

		if self.isServer then
			self:raiseDirtyFlags(self.storageDirtyFlag)
		end
	end
end

function Storage:getFreeCapacity(fillType)
	if self.fillLevels[fillType] ~= nil then
		return math.max(self.capacityPerFillType - self.fillLevels[fillType], 0)
	end

	return 0
end

function Storage:getSupportedFillTypes()
	return self.fillTypes
end

function Storage:hourChanged()
	if self.isServer then
		local difficultyMultiplier = g_currentMission.missionInfo.buyPriceMultiplier
		local fillLevelFactor = difficultyMultiplier * self.costsPerFillLevelAndDay / 24
		local costs = 0

		for _, fillLevel in pairs(self.fillLevels) do
			costs = costs + fillLevel * fillLevelFactor
		end

		g_currentMission:addMoney(-costs, self:getOwnerFarmId(), MoneyType.PROPERTY_MAINTENANCE, true)
	end
end

function Storage:addUnloadingStation(station)
	self.unloadingStations[station] = station
end

function Storage:removeUnloadingStation(station)
	self.unloadingStations[station] = nil
end

function Storage:addLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = loadingStation
end

function Storage:removeLoadingStation(loadingStation)
	self.loadingStations[loadingStation] = nil
end

function Storage:farmDestroyed(farmId)
	if self:getOwnerFarmId() == farmId then
		for fillType, accepted in pairs(self.fillTypes) do
			if accepted then
				self:setFillLevel(0, fillType)
			end
		end
	end
end
