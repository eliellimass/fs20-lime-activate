GreenhousePlaceable = {}

source("dataS/scripts/placeables/GreenhouseSetIsWaterTankFillingEvent.lua")

local GreenhousePlaceable_mt = Class(GreenhousePlaceable, Placeable)

InitStaticObjectClass(GreenhousePlaceable, "GreenhousePlaceable", ObjectIds.OBJECT_GREENHOUSE_PLACEABLE)

function GreenhousePlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or GreenhousePlaceable_mt)

	registerObjectClassName(self, "GreenhousePlaceable")

	self.waterTankCapacity = 1000
	self.waterTankFillLevel = 1000
	self.sentWaterTankFillLevel = self.waterTankFillLevel
	self.waterTankUsagePerHour = 0
	self.waterTankFillLitersPerSecond = 200
	self.waterTrailers = {}
	self.isFruitAlive = true
	self.displayFruit = false
	self.manureTankFillLevel = 0
	self.manureUsagePerHour = 0
	self.manureTankCapacity = 200
	self.manurePlaneMinY = 0
	self.manurePlaneMaxY = 1
	self.sentManureFillLevel = self.manureTankFillLevel
	self.vehiclesInRange = {}
	self.playerInRange = false
	self.greenhousePlaceableDirtyFlag = self:getNextDirtyFlag()
	self.playerInRange = false
	self.vehiclesInRange = {}
	self.numVehiclesInRange = 0

	return self
end

function GreenhousePlaceable:delete()
	if self.manureTankStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.manureTankStation)
		self.manureTankStation:delete()
	end

	if self.waterTankStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.waterTankStation)
		self.waterTankStation:delete()
	end

	if self.interactionTriggerNode ~= nil then
		removeTrigger(self.interactionTriggerNode)
	end

	unregisterObjectClassName(self)
	g_currentMission.environment:removeHourChangeListener(self)

	if g_client ~= nil then
		for _, sample in pairs(self.samples) do
			g_soundManager:deleteSample(sample)
		end
	end

	GreenhousePlaceable:superClass().delete(self)
end

function GreenhousePlaceable:readStream(streamId, connection)
	GreenhousePlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local waterTankFillLevel = streamReadUInt8(streamId) / 255 * self.waterTankCapacity

		self:setFillLevel(waterTankFillLevel, FillType.WATER)

		local manureFillLevel = streamReadUInt8(streamId) / 255 * self.manureTankCapacity

		self:setFillLevel(manureFillLevel, FillType.MANURE)

		local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)

		self.waterTankStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.waterTankStation, unloadTriggerId)

		local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.manureTankStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.manureTankStation, unloadingStationId)
	end
end

function GreenhousePlaceable:writeStream(streamId, connection)
	GreenhousePlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, math.floor(self.waterTankFillLevel / self.waterTankCapacity * 255))
		streamWriteUInt8(streamId, math.floor(self.manureTankFillLevel / self.manureTankCapacity * 255))
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.waterTankStation))
		self.waterTankStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.waterTankStation)
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.manureTankStation))
		self.manureTankStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.manureTankStation)
	end
end

function GreenhousePlaceable:readUpdateStream(streamId, timestamp, connection)
	GreenhousePlaceable:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		local waterTankFillLevel = streamReadUInt8(streamId) / 255 * self.waterTankCapacity

		self:setFillLevel(waterTankFillLevel, FillType.WATER)

		local manureFillLevel = streamReadUInt8(streamId) / 255 * self.manureTankCapacity

		self:setFillLevel(manureFillLevel, FillType.MANURE)
	end
end

function GreenhousePlaceable:writeUpdateStream(streamId, connection, dirtyMask)
	GreenhousePlaceable:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, math.floor(self.waterTankFillLevel / self.waterTankCapacity * 255))
		streamWriteUInt8(streamId, math.floor(self.manureTankFillLevel / self.manureTankCapacity * 255))
	end
end

function GreenhousePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not GreenhousePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local fruitAlive = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.fruit#alive"))
	local fruitDead = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.fruit#dead"))

	if fruitAlive ~= nil then
		self.fruitAlive = fruitAlive
	end

	if fruitDead ~= nil then
		self.fruitDead = fruitDead
	end

	self.interactionTriggerNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.interactionTrigger#node"))

	if self.interactionTriggerNode ~= nil then
		addTrigger(self.interactionTriggerNode, "interactionTriggerCallback", self)
	end

	self.waterTankCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.greenhouse.waterTank#capacity"), self.waterTankCapacity)
	self.waterTankUsagePerHour = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.greenhouse.waterTank#usagePerHour"), self.waterTankUsagePerHour)
	self.waterTankFillLitersPerSecond = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.greenhouse.waterTank#fillLitersPerSecond"), self.waterTankFillLitersPerSecond)
	local unloadingNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.waterTank.unloadingStation#node"))

	if unloadingNode ~= nil then
		local unloadingStation = UnloadingStation:new(self.isServer, self.isClient)

		if unloadingStation:load(unloadingNode, xmlFile, "placeable.greenhouse.waterTank.unloadingStation", self.customEnvironment) then
			self.waterTankStation = unloadingStation

			unloadingStation:addTargetStorage(self)
		else
			unloadingStation:delete()
		end
	end

	self.samples = {}

	if g_client ~= nil then
		self.samples.refuel = g_soundManager:loadSampleFromXML(xmlFile, "placeable.greenhouse.waterTank.sounds", "refuel", self.baseDirectory, self.nodeId, 0, AudioGroup.VEHICLE, nil, )
	end

	self.manurePlane = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.manureTank.manurePlane#node"))
	local unloadingNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.greenhouse.manureTank.unloadingStation#node"))

	if unloadingNode ~= nil then
		local unloadingStation = UnloadingStation:new(self.isServer, self.isClient)

		if unloadingStation:load(unloadingNode, xmlFile, "placeable.greenhouse.manureTank.unloadingStation", self.customEnvironment) then
			self.manureTankStation = unloadingStation

			unloadingStation:addTargetStorage(self)
		else
			unloadingStation:delete()
		end
	end

	local minY, maxY = StringUtil.getVectorFromString(getXMLString(xmlFile, "placeable.greenhouse.manureTank.manurePlane#minMaxY"))

	if minY ~= nil and maxY ~= nil then
		self.manurePlaneMinY = minY
		self.manurePlaneMaxY = maxY
	end

	self.manureTankCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.greenhouse.manureTank#capacity"), self.manureTankCapacity)
	self.manureUsagePerHour = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.greenhouse.manureTank#usagePerHour"), self.manureUsagePerHour)

	delete(xmlFile)
	self:setFillLevel(0, FillType.WATER)

	self.sentWaterTankFillLevel = self.waterTankFillLevel

	self:setFillLevel(0, FillType.MANURE)

	self.sentManureFillLevel = self.manureTankFillLevel

	return true
end

function GreenhousePlaceable:finalizePlacement()
	GreenhousePlaceable:superClass().finalizePlacement(self)
	g_currentMission.environment:addHourChangeListener(self)
end

function GreenhousePlaceable:register(...)
	GreenhousePlaceable:superClass().register(self, ...)
	self.manureTankStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(self.manureTankStation)
	self.waterTankStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(self.waterTankStation)
end

function GreenhousePlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not GreenhousePlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	local waterTankFillLevel = getXMLFloat(xmlFile, key .. "#waterTankFillLevel")

	if waterTankFillLevel ~= nil then
		self:setFillLevel(waterTankFillLevel, FillType.WATER)
	end

	local manureFillLevel = getXMLFloat(xmlFile, key .. "#manureFillLevel")

	if manureFillLevel ~= nil then
		self:setFillLevel(manureFillLevel, FillType.MANURE)
	end

	return true
end

function GreenhousePlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	GreenhousePlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#waterTankFillLevel", self.waterTankFillLevel)
	setXMLFloat(xmlFile, key .. "#manureFillLevel", self.manureTankFillLevel)
end

function GreenhousePlaceable:collectPickObjects(node)
	local foundNode = false

	for _, unloadTrigger in ipairs(self.manureTankStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	for _, unloadTrigger in ipairs(self.waterTankStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		GreenhousePlaceable:superClass().collectPickObjects(self, node)
	end
end

function GreenhousePlaceable:update(dt)
	GreenhousePlaceable:superClass().update(self, dt)

	if self:getCanInteract() then
		g_currentMission:addExtraPrintText(g_i18n:getText("info_waterFillLevel") .. ": " .. math.floor(self.waterTankFillLevel) .. " (" .. math.floor(100 * self.waterTankFillLevel / self.waterTankCapacity) .. "%)")
		g_currentMission:addExtraPrintText(g_i18n:getText("info_manureFillLevel") .. ": " .. math.floor(self.manureTankFillLevel) .. " (" .. math.floor(100 * self.manureTankFillLevel / self.manureTankCapacity) .. "%)")
	end

	self:raiseActive()
end

function GreenhousePlaceable:getCanInteract()
	if g_currentMission.controlPlayer and self.playerInRange then
		return true
	end

	if not g_currentMission.controlPlayer then
		for vehicle in pairs(self.vehiclesInRange) do
			if vehicle:getIsActiveForInput(true) then
				return true
			end
		end
	end

	return false
end

function GreenhousePlaceable:hourChanged()
	if self.isServer then
		self:setFillLevel(self.waterTankFillLevel - self.waterTankUsagePerHour, FillType.WATER)
		self:setFillLevel(self.manureTankFillLevel - self.manureUsagePerHour, FillType.MANURE)

		if self.isFruitAlive then
			local income = self.incomePerHour

			if self.manureTankFillLevel > 0 then
				income = income * 2
			end

			g_currentMission:addMoney(income, self:getOwnerFarmId(), MoneyType.PROPERTY_INCOME, true)
		end
	end
end

function GreenhousePlaceable:setIsWaterTankFilling(isWaterTankFilling, trailer, noEventSend)
	GreenhouseSetIsWaterTankFillingEvent.sendEvent(self, isWaterTankFilling, trailer, noEventSend)

	if self.isWaterTankFilling ~= isWaterTankFilling then
		self.isWaterTankFilling = isWaterTankFilling
		self.waterTankFillTrailer = trailer
	end

	if g_client ~= nil then
		if isWaterTankFilling then
			g_soundManager:playSample(self.samples.refuel)
		else
			g_soundManager:stopSample(self.samples.refuel)
		end
	end
end

function GreenhousePlaceable:setOwnerFarmId(ownerFarmId, noEventSend)
	GreenhousePlaceable:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)

	if self.manureTankStation ~= nil then
		self.manureTankStation:setOwnerFarmId(ownerFarmId)
	end

	if self.waterTankStation ~= nil then
		self.waterTankStation:setOwnerFarmId(ownerFarmId)
	end
end

function GreenhousePlaceable:getIsFillTypeSupported(fillTypeIndex, station)
	return fillTypeIndex == FillType.MANURE and station == self.manureTankStation or fillTypeIndex == FillType.WATER and station == self.waterTankStation
end

function GreenhousePlaceable:getFillLevel(fillTypeIndex)
	if fillTypeIndex == FillType.MANURE then
		return self.manureTankFillLevel
	else
		return self.waterTankFillLevel
	end
end

function GreenhousePlaceable:getCapacity(fillTypeIndex)
	if fillTypeIndex == FillType.MANURE then
		return self.manureTankCapacity
	else
		return self.waterTankCapacity
	end
end

function GreenhousePlaceable:setFillLevel(fillLevel, fillTypeIndex)
	if fillTypeIndex == FillType.MANURE then
		self.manureTankFillLevel = MathUtil.clamp(fillLevel, 0, self.manureTankCapacity)

		if self.manurePlane ~= nil then
			setVisibility(self.manurePlane, self.manureTankFillLevel > 0.0001)

			local x, y, z = getTranslation(self.manurePlane)
			y = self.manurePlaneMinY + self.manureTankFillLevel / self.manureTankCapacity * (self.manurePlaneMaxY - self.manurePlaneMinY)

			setTranslation(self.manurePlane, x, y, z)
		end

		if self.manureTankFillLevel ~= self.sentManureFillLevel then
			self:raiseDirtyFlags(self.greenhousePlaceableDirtyFlag)

			self.sentManureFillLevel = self.manureTankFillLevel
		end
	elseif fillTypeIndex == FillType.WATER then
		self.waterTankFillLevel = MathUtil.clamp(fillLevel, 0, self.waterTankCapacity)

		if self.waterTankFillLevel ~= self.sentWaterTankFillLevel then
			self:raiseDirtyFlags(self.greenhousePlaceableDirtyFlag)

			self.sentWaterTankFillLevel = self.waterTankFillLevel
		end

		self.isFruitAlive = self.waterTankFillLevel > 0.0001

		if self.waterTankFillLevel > 0 then
			self.displayFruit = true
		end

		if self.fruitAlive ~= nil then
			setVisibility(self.fruitAlive, self.isFruitAlive and self.displayFruit)
		end

		if self.fruitDead ~= nil then
			setVisibility(self.fruitDead, not self.isFruitAlive and self.displayFruit)
		end
	end
end

function GreenhousePlaceable:getFreeCapacity(fillTypeIndex)
	if fillTypeIndex == FillType.MANURE then
		return self.manureTankCapacity - self.manureTankFillLevel
	else
		return self.waterTankCapacity - self.waterTankFillLevel
	end
end

function GreenhousePlaceable:getSupportedFillTypes()
	return {
		FillType.MANURE,
		FillType.WATER
	}
end

function GreenhousePlaceable:addUnloadingStation(station)
end

function GreenhousePlaceable:removeUnloadingStation(station)
end

function GreenhousePlaceable:interactionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.playerInRange = true
			else
				self.playerInRange = false
			end
		else
			local vehicle = g_currentMission.nodeToObject[otherShapeId]

			if vehicle ~= nil then
				if onEnter then
					if self.vehiclesInRange[vehicle] == nil then
						self.vehiclesInRange[vehicle] = true
						self.numVehiclesInRange = self.numVehiclesInRange + 1
					end
				elseif self.vehiclesInRange[vehicle] then
					self.vehiclesInRange[vehicle] = nil
					self.numVehiclesInRange = self.numVehiclesInRange - 1
				end
			end
		end
	end
end
