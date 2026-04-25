TrainPlaceable = {}
local TrainPlaceable_mt = Class(TrainPlaceable, Placeable)

InitStaticObjectClass(TrainPlaceable, "TrainPlaceable", ObjectIds.OBJECT_TRAIN_PLACEABLE)

function TrainPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or TrainPlaceable_mt)

	registerObjectClassName(self, "TrainPlaceable")

	return self
end

function TrainPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not TrainPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.splineTime = -1
	self.splineTimeSent = self.splineTime
	self.splineEndTime = 0
	self.trainLengthSplineTime = 0
	self.splinePositionUpdateListener = {}
	self.startSplineTime = 0
	self.railroadVehicles = {}
	self.trainLength = 0
	self.dirtyFlag = self:getNextDirtyFlag()
	self.networkTimeInterpolator = InterpolationTime:new(1.2)
	self.networkSplineTimeInterpolator = InterpolatorValue:new(0)
	self.spline = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.trainSystem.spline#node"))

	if self.spline == nil then
		g_logManager:xmlError(self.configFileName, "Missing spline node!")
		delete(xmlFile)

		return false
	end

	if not getHasClassId(getGeometry(self.spline), ClassIds.SPLINE) then
		g_logManager:xmlError(self.configFileName, "Given node is not a spline!")
		delete(xmlFile)

		return false
	end

	if not getIsSplineClosed(self.spline) then
		self.spline = nil

		g_logManager:xmlError(self.configFileName, "Train spline is not closed. Open splines are not supported!")
		delete(xmlFile)

		return false
	end

	self.splineLength = getSplineLength(self.spline)
	self.splineYOffset = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.trainSystem.spline#splineYOffset"), 0)
	self.electricitySpline = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.trainSystem.electricitySpline#node"))

	if self.electricitySpline ~= nil then
		if getHasClassId(getGeometry(self.electricitySpline), ClassIds.SPLINE) then
			if getIsSplineClosed(self.electricitySpline) then
				local sx, _, sz = getSplinePosition(self.spline, 0)
				local esx, _, esz = getSplinePosition(self.spline, 0)

				if MathUtil.vector2Length(sx - esx, sz - esz) < 5 then
					self.electricitySplineLength = getSplineLength(self.electricitySpline)
					self.electricitySplineYOffset = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.trainSystem.electricitySpline#splineYOffset"), 0)
				else
					g_logManager:xmlError(self.configFileName, "Railroad and electricity spline should almost start at the same x and z positions. Ignoring electricity spline!")

					self.electricitySpline = nil
				end
			else
				g_logManager:xmlError(self.configFileName, "Railroad electricity spline has to be closed. Ignoring electricity spline!")

				self.electricitySpline = nil
			end
		else
			g_logManager:xmlError(self.configFileName, "Given electricitySpline node is not a spline. Ignoring electricity spline!")

			self.electricitySpline = nil
		end
	end

	self.vehiclesToLoad = {}
	self.vehicleIdsToLoad = {}

	if self.isServer then
		local i = 0

		while true do
			local baseString = string.format("placeable.trainSystem.train.vehicle(%d)", i)

			if not hasXMLProperty(xmlFile, baseString) then
				break
			end

			local filename = getXMLString(xmlFile, baseString .. "#xmlFilename")

			if filename ~= nil then
				table.insert(self.vehiclesToLoad, filename)
			end

			i = i + 1
		end
	end

	self.railroadObjects = {}
	self.railroadCrossings = {}
	local i = 0

	while true do
		local key = string.format("placeable.trainSystem.railroadCrossings.railroadCrossing(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local railroadCrossing = RailroadCrossing:new(self.isServer, self.isClient, self, self.nodeId)

		if railroadCrossing:loadFromXML(xmlFile, key) then
			table.insert(self.railroadCrossings, railroadCrossing)
			table.insert(self.railroadObjects, railroadCrossing)
		else
			railroadCrossing:delete()
		end

		i = i + 1
	end

	self.railroadCallers = {}
	local i = 0

	while true do
		local key = string.format("placeable.trainSystem.railroadCallers.railroadCaller(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local railroadCaller = RailroadCaller:new(self.isServer, self.isClient, self, self.nodeId)

		if railroadCaller:loadFromXML(xmlFile, key) then
			table.insert(self.railroadCallers, railroadCaller)
			table.insert(self.railroadObjects, railroadCaller)
		end

		i = i + 1
	end

	for i = 0, 1, 0.5 / self.splineLength do
		local x, y, z = getSplinePosition(self.spline, i)

		for _, object in pairs(self.railroadObjects) do
			local x1, y1, z1 = getWorldTranslation(object.rootNode)
			x1, y1, z1 = localToWorld(getParent(object.rootNode), x1, y1, z1)
			local distance = MathUtil.vector3Length(x - x1, y - y1, z - z1)

			if object.nearestDistance == nil then
				object.nearestDistance = distance
				object.nearestTime = i
			elseif distance < object.nearestDistance then
				object.nearestDistance = distance
				object.nearestTime = i
			end
		end
	end

	for _, object in pairs(self.railroadObjects) do
		if object.setSplineTimeByPosition ~= nil then
			object:setSplineTimeByPosition(object.nearestTime, self.splineLength)
		end

		if object.onSplinePositionTimeUpdate ~= nil then
			object:onSplinePositionTimeUpdate(self.splineTime, self.splineEndTime)
		end
	end

	g_currentMission:addTrainSystem(self)
	g_currentMission:addLoadFinishedListener(self)
	delete(xmlFile)

	return true
end

function TrainPlaceable:onLoadFinished()
	if #self.vehicleIdsToLoad > 0 then
		for _, id in ipairs(self.vehicleIdsToLoad) do
			local vehicle = g_currentMission.loadVehiclesById[id]

			if vehicle ~= nil then
				vehicle:setTrainSystem(self)
				table.insert(self.railroadVehicles, vehicle)
			end
		end
	else
		local lastVehicle = nil

		for _, filename in ipairs(self.vehiclesToLoad) do
			g_deferredLoadingManager:addSubtask(function ()
				filename = Utils.getFilename(filename, self.baseDirectory)
				local vehicle = g_currentMission:loadVehicle(filename, 0, nil, 0, 0, 0, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, )

				if vehicle ~= nil then
					vehicle:setTrainSystem(self)
					table.insert(self.railroadVehicles, vehicle)

					if lastVehicle ~= nil then
						lastVehicle:attachImplement(vehicle, 1, 1, true)
					end

					lastVehicle = vehicle
				else
					g_logManager:xmlWarning(filename, "Could not create trainsystem vehicle!")
				end
			end)
		end
	end

	g_deferredLoadingManager:addSubtask(function ()
		self:updateTrainLength(self.startSplineTime)
		self:setIsTrainTabbable(g_gameSettings:getValue("isTrainTabbable"))

		for _, railroadVehicle in pairs(self.railroadVehicles) do
			railroadVehicle:addDeleteListener(self)
		end
	end)
end

function TrainPlaceable:delete()
	for _, object in ipairs(self.railroadObjects) do
		object:delete()
	end

	g_currentMission:removeTrainSystem(self)
	unregisterObjectClassName(self)
	TrainPlaceable:superClass().delete(self)
end

function TrainPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	TrainPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#splineTime", SplineUtil.getValidSplineTime(self.splineTime))

	for k, railroadVehicle in ipairs(self.railroadVehicles) do
		local railroadKey = string.format("%s.railroadVehicle(%d)", key, k - 1)

		setXMLInt(xmlFile, railroadKey .. "#vehicleId", railroadVehicle.currentSavegameVehicleId)
	end

	for k, railroadObject in ipairs(self.railroadObjects) do
		local railroadKey = string.format("%s.railroadObjects(%d)", key, k - 1)

		if railroadObject.saveToXMLFile ~= nil then
			setXMLInt(xmlFile, railroadKey .. "#index", k)
			railroadObject.saveToXMLFile(xmlFile, railroadKey, usedModNames)
		end
	end
end

function TrainPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not TrainPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	self.startSplineTime = SplineUtil.getValidSplineTime(getXMLFloat(xmlFile, key .. "#splineTime") or 0)
	local i = 0

	while true do
		local vehicleKey = string.format("%s.railroadVehicle(%d)", key, i)

		if not hasXMLProperty(xmlFile, vehicleKey) then
			break
		end

		local vehicleId = getXMLString(xmlFile, vehicleKey .. "#vehicleId")

		if vehicleId ~= nil then
			table.insert(self.vehicleIdsToLoad, vehicleId)
		end

		i = i + 1
	end

	i = 0

	while true do
		local railroadKey = string.format("%s.railroadObjects(%d)", key, i)

		if not hasXMLProperty(xmlFile, railroadKey) then
			break
		end

		local index = getXMLInt(xmlFile, railroadKey .. "#index")

		if index ~= nil then
			local object = self.railroadObjects[index]

			if object ~= nil then
				object:loadFromXMLFile(xmlFile, railroadKey)
			end
		end

		i = i + 1
	end

	return true
end

function TrainPlaceable:readStream(streamId, connection)
	TrainPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		self.railroadVehicleIds = {}
		local numVehicles = streamReadInt8(streamId)

		for i = 1, numVehicles do
			self.railroadVehicleIds[i] = NetworkUtil.readNodeObjectId(streamId)
		end

		local splineTime = streamReadFloat32(streamId)

		self.networkSplineTimeInterpolator:setValue(splineTime)
		self.networkTimeInterpolator:reset()

		self.splineTime = splineTime

		for _, railroadObject in ipairs(self.railroadObjects) do
			if railroadObject.readStream ~= nil then
				railroadObject:readStream(streamId, connection)
			end
		end
	end
end

function TrainPlaceable:writeStream(streamId, connection)
	TrainPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		local numVehicles = #self.railroadVehicles

		streamWriteInt8(streamId, numVehicles)

		for i = 1, numVehicles do
			NetworkUtil.writeNodeObject(streamId, self.railroadVehicles[i])
		end

		streamWriteFloat32(streamId, self.splineTimeSent)

		for _, railroadObject in ipairs(self.railroadObjects) do
			if railroadObject.writeStream ~= nil then
				railroadObject:writeStream(streamId, connection)
			end
		end
	end
end

function TrainPlaceable:readUpdateStream(streamId, timestamp, connection)
	TrainPlaceable:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		local splineTime = streamReadFloat32(streamId)

		self.networkTimeInterpolator:startNewPhaseNetwork()
		self.networkSplineTimeInterpolator:setTargetValue(splineTime)

		for _, railroadObject in ipairs(self.railroadObjects) do
			if railroadObject.readUpdateStream ~= nil then
				railroadObject:readUpdateStream(streamId, timestamp, connection)
			end
		end
	end
end

function TrainPlaceable:writeUpdateStream(streamId, connection, dirtyMask)
	TrainPlaceable:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.splineTimeSent)

		for _, railroadObject in ipairs(self.railroadObjects) do
			if railroadObject.writeUpdateStream ~= nil then
				railroadObject:writeUpdateStream(streamId, connection, dirtyMask)
			end
		end
	end
end

function TrainPlaceable:update(dt)
	TrainPlaceable:superClass().update(self, dt)

	for _, railroadObject in pairs(self.railroadObjects) do
		if railroadObject.update ~= nil then
			railroadObject:update(dt)
		end
	end

	if not self.isServer and self.isClient then
		if self.railroadVehicleIds ~= nil then
			for index, id in pairs(self.railroadVehicleIds) do
				local vehicle = NetworkUtil.getObject(id)

				if vehicle ~= nil then
					vehicle:setTrainSystem(self)

					self.trainLength = self.trainLength + vehicle:getFrontToBackDistance()
					self.trainLengthSplineTime = self.trainLength / self.splineLength

					table.insert(self.railroadVehicles, index, vehicle)
				end

				self.railroadVehicleIds[index] = nil
			end

			if next(self.railroadVehicleIds) == nil then
				self.railroadVehicleIds = nil

				self:setIsTrainTabbable(g_gameSettings:getValue("isTrainTabbable"))
			end
		end

		self.networkTimeInterpolator:update(dt)

		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		local splineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(interpolationAlpha)
		splineTime = SplineUtil.getValidSplineTime(splineTime)

		self:updateTrainPositionByLocomotiveSplinePosition(splineTime)
	end

	self:raiseActive()
end

function TrainPlaceable:setIsTrainTabbable(isTabbable)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		isTabbable = false
	end

	for _, railroadVehicle in ipairs(self.railroadVehicles) do
		if railroadVehicle.setIsTabbable ~= nil then
			railroadVehicle:setIsTabbable(isTabbable)
		end
	end
end

function TrainPlaceable:getSplineTime()
	return self.splineTime
end

function TrainPlaceable:setSplineTime(startTime, endTime)
	if startTime ~= self.splineTime then
		local t1 = SplineUtil.getValidSplineTime(startTime)

		for _, railroadVehicle in ipairs(self.railroadVehicles) do
			t1 = railroadVehicle:alignToSplineTime(self.spline, self.splineYOffset, t1)
		end

		for _, listener in ipairs(self.splinePositionUpdateListener) do
			listener:onSplinePositionTimeUpdate(startTime, endTime)
		end

		self.splineTime = startTime
		self.splineEndTime = endTime

		if self.isServer then
			local threshold = 0.02 / self.splineLength

			if threshold < math.abs(self.splineTime - self.splineTimeSent) then
				self.splineTimeSent = self.splineTime

				self:raiseDirtyFlags(self.dirtyFlag)
			end
		end
	end
end

function TrainPlaceable:addSplinePositionUpdateListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.splinePositionUpdateListener, listener)
	end
end

function TrainPlaceable:removeSplinePositionUpdateListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.splinePositionUpdateListener, listener)
	end
end

function TrainPlaceable:updateTrainPositionByLocomotiveSpeed(dt, speed)
	local distance = speed * dt / 1000
	local increment = distance / self.splineLength
	local splineTime = self:getSplineTime() + increment

	self:setSplineTime(splineTime, splineTime - self.trainLengthSplineTime)
end

function TrainPlaceable:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
	local splineTime = splinePosition

	self:setSplineTime(splineTime, splineTime - self.trainLengthSplineTime)
end

function TrainPlaceable:updateTrainLength(splinePosition)
	for _, railroadVehicle in ipairs(self.railroadVehicles) do
		self.trainLength = self.trainLength + railroadVehicle:getFrontToBackDistance()
	end

	self.trainLengthSplineTime = self.trainLength / self.splineLength

	self:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
end

function TrainPlaceable:setRequestedSplinePosition(position)
	for _, railroadVehicle in ipairs(self.railroadVehicles) do
		if railroadVehicle.setRequestedSplinePosition ~= nil then
			railroadVehicle:setRequestedSplinePosition(position)

			break
		end
	end
end

function TrainPlaceable:onDeleteObject(object)
	if ListUtil.removeElementFromList(self.railroadVehicles, object) then
		self:updateTrainLength(self.splineTime)
	end
end

function TrainPlaceable:getSplineLength()
	return self.splineLength
end

function TrainPlaceable:getElectricitySpline()
	return self.electricitySpline
end

function TrainPlaceable:getElectricitySplineLength()
	return self.electricitySplineLength or 0
end
