Placeable = {}
local Placeable_mt = Class(Placeable, Object)

InitStaticObjectClass(Placeable, "Placeable", ObjectIds.OBJECT_PLACEABLE)

Placeable.GLOW_MATERIAL = nil
Placeable.PREVIEW_STATE = {
	INVALID = 3,
	VALID = 2,
	CHECKING = 1
}
Placeable.PREVIEW_COLOR = {
	[Placeable.PREVIEW_STATE.CHECKING] = {
		1,
		1,
		0,
		1
	},
	[Placeable.PREVIEW_STATE.VALID] = {
		0,
		1,
		0,
		1
	},
	[Placeable.PREVIEW_STATE.INVALID] = {
		1,
		0,
		0,
		1
	}
}
Placeable.PREVIEW_RAMP_COLOR = {
	[Placeable.PREVIEW_STATE.CHECKING] = {
		0,
		1,
		1,
		1
	},
	[Placeable.PREVIEW_STATE.VALID] = {
		0,
		1,
		1,
		1
	},
	[Placeable.PREVIEW_STATE.INVALID] = {
		1,
		0,
		0,
		1
	}
}

function Placeable.onCreateGlowMaterial(_, id)
	if getHasShaderParameter(id, "colorScale") then
		Placeable.GLOW_MATERIAL = getMaterial(id, 0)
	end
end

function Placeable.initPlaceableType()
	g_storeManager:addSpecType("incomePerHour", "shopListAttributeIconIncomePerHour", Placeable.loadSpecValueIncomePerHour, Placeable.getSpecValueIncomePerHour)
end

function Placeable:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or Placeable_mt)
	self.nodeId = 0
	self.useRandomYRotation = false
	self.useManualYRotation = false
	self.placementSizeX = 1
	self.placementSizeZ = 1
	self.placementSizeOffsetX = 0
	self.placementSizeOffsetZ = 0
	self.placementTestSizeX = 1
	self.placementTestSizeZ = 1
	self.placementTestSizeOffsetX = 0
	self.placementTestSizeOffsetZ = 0
	self.requireLeveling = false
	self.maxSmoothDistance = 3
	self.maxSlope = MathUtil.degToRad(45)
	self.maxEdgeAngle = MathUtil.degToRad(45)
	self.smoothingGroundType = nil
	self.triggerMarkers = {}
	self.clearAreas = {}
	self.levelAreas = {}
	self.rampAreas = {}
	self.foliageAreas = {}
	self.samples = {}
	self.pickObjects = {}
	self.animatedObjects = {}
	self.triggerMarkers = {}
	self.mapHotspots = {}
	self.isolated = false
	self.isDeleted = false
	self.useMultiRootNode = false
	self.price = 0
	self.age = 0
	self.isInPreviewMode = nil
	self.placementPositionSnapSize = 0
	self.placementPositionSnapOffset = 0
	self.placementRotationSnapAngle = 0
	self.mapBoundId = nil

	registerObjectClassName(self, "Placeable")

	return self
end

function Placeable:delete()
	self.isDeleted = true

	g_currentMission:removePlaceableToDelete(self)

	if self.i3dFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.i3dFilename, nil, true)
	end

	for _, node in ipairs(self.triggerMarkers) do
		g_currentMission:removeTriggerMarker(node)
	end

	if self.writtenBlockedAreas then
		local deform = self:createDeformationObject(g_currentMission.terrainRootNode, true, false)

		deform:unblockAreas()
	end

	for _, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:delete()
	end

	for _, hotspot in ipairs(self.mapHotspots) do
		g_currentMission.hud:removeMapHotspot(hotspot)
		hotspot:delete()
	end

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:removeDayChangeListener(self)
		g_currentMission.environment:removeWeatherChangeListener(self)
		g_currentMission.environment:removeHourChangeListener(self)
	end

	unregisterObjectClassName(self)
	g_currentMission:removeItemToSave(self)
	g_currentMission:removePlaceable(self)

	for _, node in pairs(self.pickObjects) do
		g_currentMission:removeNodeObject(node)
	end

	if self.isClient then
		g_soundManager:deleteSamples(self.samples)
	end

	if self.boughtWithFarmland and self.isServer then
		g_farmlandManager:removeStateChangeListener(self)
	end

	g_currentMission:removeOwnedItem(self)

	if self.nodeId ~= 0 and entityExists(self.nodeId) then
		delete(self.nodeId)

		self.nodeId = 0
	end

	Placeable:superClass().delete(self)
end

function Placeable:setCollisionMask(nodeId, mask)
	setCollisionMask(nodeId, mask)

	local numChildren = getNumOfChildren(nodeId)

	for i = 0, numChildren - 1 do
		local childId = getChildAt(nodeId, i)

		self:setCollisionMask(childId, mask)
	end
end

function Placeable:getIsPlayerInRange(distance, player)
	if self.nodeId ~= 0 then
		distance = Utils.getNoNil(distance, 10)

		if player == nil then
			for _, player in pairs(g_currentMission.players) do
				if self:isInActionDistance(player, self.nodeId, distance) then
					return true, player
				end
			end
		else
			return self:isInActionDistance(player, self.nodeId, distance), player
		end
	end

	return false, nil
end

function Placeable:isInActionDistance(player, refNode, distance)
	local x, _, z = getWorldTranslation(refNode)
	local px, _, pz = getWorldTranslation(player.rootNode)
	local dx = px - x
	local dz = pz - z

	if dx * dx + dz * dz < distance * distance then
		return true
	end

	return false
end

function Placeable:readStream(streamId, connection)
	Placeable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local x = streamReadFloat32(streamId)
		local y = streamReadFloat32(streamId)
		local z = streamReadFloat32(streamId)
		local rx = NetworkUtil.readCompressedAngle(streamId)
		local ry = NetworkUtil.readCompressedAngle(streamId)
		local rz = NetworkUtil.readCompressedAngle(streamId)
		local isNew = self.configFileName == nil

		if isNew then
			self:load(configFileName, x, y, z, rx, ry, rz, false, false)
		end

		self.age = streamReadUInt16(streamId)
		self.price = streamReadInt32(streamId)

		if isNew then
			self:finalizePlacement()
		end

		for _, animatedObject in ipairs(self.animatedObjects) do
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end

		self:setOwnerFarmId(self.ownerFarmId, true)
	end
end

function Placeable:writeStream(streamId, connection)
	Placeable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))

		local x, y, z = getTranslation(self.nodeId)
		local x_rot, y_rot, z_rot = getRotation(self.nodeId)

		streamWriteFloat32(streamId, x)
		streamWriteFloat32(streamId, y)
		streamWriteFloat32(streamId, z)
		NetworkUtil.writeCompressedAngle(streamId, x_rot)
		NetworkUtil.writeCompressedAngle(streamId, y_rot)
		NetworkUtil.writeCompressedAngle(streamId, z_rot)
		streamWriteUInt16(streamId, self.age)
		streamWriteInt32(streamId, self.price)

		for _, animatedObject in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end
	end
end

function Placeable:readUpdateStream(streamId, timestamp, connection)
end

function Placeable:writeUpdateStream(streamId, connection, dirtyMask)
end

function Placeable:getPlacementRotation(x, y, z)
	local snapAngle = math.deg(self.placementRotationSnapAngle)

	if snapAngle ~= 0 then
		snapAngle = 1 / snapAngle
		local degAngle = math.deg(y)
		degAngle = math.floor(degAngle * snapAngle) / snapAngle
		y = math.rad(degAngle)
	end

	return x, y, z
end

function Placeable:getPlacementPosition(x, y, z)
	local snapSize = self.placementPositionSnapSize

	if snapSize ~= 0 then
		snapSize = 1 / snapSize
		x = math.floor(x * snapSize) / snapSize + self.placementPositionSnapOffset
		z = math.floor(z * snapSize) / snapSize + self.placementPositionSnapOffset
	end

	return x, y, z
end

function Placeable:getIsAreaOwned(farmId)
	local halfX = self.placementTestSizeX * 0.5
	local halfZ = self.placementTestSizeZ * 0.5
	local offsetX = self.placementTestSizeOffsetX
	local offsetZ = self.placementTestSizeOffsetZ
	local x1, _, z1 = localToWorld(self.nodeId, -halfX + offsetZ, 0, -halfZ + offsetZ)
	local x2, _, z2 = localToWorld(self.nodeId, halfX + offsetZ, 0, -halfZ + offsetZ)
	local x3, _, z3 = localToWorld(self.nodeId, -halfX + offsetZ, 0, halfZ + offsetZ)
	local x4, _, z4 = localToWorld(self.nodeId, halfX + offsetZ, 0, halfZ + offsetZ)

	return g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x1, z1) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x2, z2) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x3, z3) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x4, z4)
end

function Placeable:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local nodeRoot = g_i3DManager:loadSharedI3DFile(i3dFilename, nil, false, false)

	if nodeRoot == 0 then
		return false
	end

	if self.useMultiRootNode then
		link(getRootNode(), nodeRoot)

		self.nodeId = nodeRoot

		log("Loaded", i3dFilename, nodeRoot, getName(nodeRoot), self.nodeId, getName(self.nodeId))
	else
		local nodeId = getChildAt(nodeRoot, 0)

		if nodeId == 0 then
			delete(nodeRoot)

			return false
		end

		link(getRootNode(), nodeId)
		delete(nodeRoot)

		self.nodeId = nodeId
	end

	return true
end

function Placeable:setPreviewMaterials(node, nodeTable)
	if getHasClassId(node, ClassIds.SHAPE) then
		nodeTable[node] = node

		setMaterial(node, Placeable.GLOW_MATERIAL, 0)
	end

	local numChildren = getNumOfChildren(node)

	for i = 0, numChildren - 1 do
		self:setPreviewMaterials(getChildAt(node, i), nodeTable)
	end
end

function Placeable:setPlaceablePreviewState(state)
	if not self.isInPreviewMode then
		self.isInPreviewMode = true
		self.previewGlowingNodes = {}

		if Placeable.GLOW_MATERIAL ~= nil then
			self:setPreviewMaterials(self.nodeId, self.previewGlowingNodes)
		end
	end

	if Placeable.GLOW_MATERIAL ~= nil then
		local color = Placeable.PREVIEW_COLOR[state]

		for node in pairs(self.previewGlowingNodes) do
			setShaderParameter(node, "colorScale", color[1], color[2], color[3], color[4], false)
		end
	end
end

function Placeable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	self.configFileName = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = loadXMLFile("TempXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local i3dFilename = getXMLString(xmlFile, "placeable.filename")
	self.placementSizeX = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#sizeX"), self.placementSizeX)
	self.placementSizeZ = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#sizeZ"), self.placementSizeZ)
	self.placementSizeOffsetX = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#sizeOffsetX"), self.placementSizeOffsetX)
	self.placementSizeOffsetZ = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#sizeOffsetZ"), self.placementSizeOffsetZ)
	self.placementTestSizeX = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#testSizeX"), self.placementSizeX)
	self.placementTestSizeZ = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#testSizeZ"), self.placementSizeZ)
	self.placementTestSizeOffsetX = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#testSizeOffsetX"), self.placementTestSizeOffsetX)
	self.placementTestSizeOffsetZ = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#testSizeOffsetZ"), self.placementTestSizeOffsetZ)
	self.useRandomYRotation = Utils.getNoNil(getXMLBool(xmlFile, "placeable.placement#useRandomYRotation"), self.useRandomYRotation)
	self.useManualYRotation = Utils.getNoNil(getXMLBool(xmlFile, "placeable.placement#useManualYRotation"), self.useManualYRotation)
	self.alignToWorldY = Utils.getNoNil(getXMLBool(xmlFile, "placeable.placement#alignToWorldY"), true)
	self.placementPositionSnapSize = math.abs(Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#placementPositionSnapSize"), 0))
	self.placementPositionSnapOffset = math.abs(Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#placementPositionSnapOffset"), 0))
	self.placementRotationSnapAngle = math.rad(math.abs(Utils.getNoNil(getXMLFloat(xmlFile, "placeable.placement#placementRotationSnapAngle"), 0)))
	self.boughtWithFarmland = Utils.getNoNil(getXMLBool(xmlFile, "placeable.boughtWithFarmland"), false)
	self.incomePerHour = getXMLFloat(xmlFile, "placeable.incomePerHour" .. g_currentMission.missionInfo.economicDifficulty)

	if self.incomePerHour == nil then
		self.incomePerHour = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.incomePerHour"), 0)

		if g_currentMission.missionInfo.economicDifficulty == 1 then
			self.incomePerHour = self.incomePerHour * 1.5
		elseif g_currentMission.missionInfo.economicDifficulty == 3 then
			self.incomePerHour = self.incomePerHour / 1.5
		end
	end

	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		if self.price == 0 or self.price == nil then
			self.price = StoreItemUtil.getDefaultPrice(storeItem)
		end

		if g_currentMission ~= nil and storeItem.canBeSold then
			g_currentMission.environment:addDayChangeListener(self)
		end
	end

	if i3dFilename == nil then
		delete(xmlFile)

		return false
	end

	self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)

	if not self:createNode(self.i3dFilename) then
		delete(xmlFile)

		return false
	end

	self:initPose(x, y, z, rx, ry, rz, initRandom)

	if hasXMLProperty(xmlFile, "placeable.dayNightObjects") then
		local i = 0

		while true do
			local key = string.format("placeable.dayNightObjects.dayNightObject(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#node"))

			if node ~= nil then
				if self.dayNightObjects == nil then
					self.dayNightObjects = {}

					g_currentMission.environment:addWeatherChangeListener(self)
				end

				local visibleDay = getXMLBool(xmlFile, key .. "#visibleDay")
				local visibleNight = getXMLBool(xmlFile, key .. "#visibleNight")
				local intensityDay = getXMLFloat(xmlFile, key .. "#intensityDay")
				local intensityNight = getXMLFloat(xmlFile, key .. "#intensityNight")

				table.insert(self.dayNightObjects, {
					node = node,
					visibleDay = visibleDay,
					visibleNight = visibleNight,
					intensityDay = intensityDay,
					intensityNight = intensityNight
				})
			end

			i = i + 1
		end
	end

	self.requireLeveling = Utils.getNoNil(getXMLBool(xmlFile, "placeable.leveling#requireLeveling"), self.requireLeveling)

	if self.requireLeveling then
		self.maxSmoothDistance = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.leveling#maxSmoothDistance"), 3)
		self.maxSlope = MathUtil.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, "placeable.leveling#maxSlope"), 45))
		self.maxEdgeAngle = MathUtil.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, "placeable.leveling#maxEdgeAngle"), 45))
		self.smoothingGroundType = getXMLString(xmlFile, "placeable.leveling#smoothingGroundType")
	end

	self:loadAreasFromXML(self.clearAreas, xmlFile, "placeable.clearAreas.clearArea(%d)", false, false)
	self:loadAreasFromXML(self.levelAreas, xmlFile, "placeable.leveling.levelAreas.levelArea(%d)", false, true)
	self:loadAreasFromXML(self.rampAreas, xmlFile, "placeable.leveling.rampAreas.rampArea(%d)", true, true)
	self:loadAreasFromXML(self.foliageAreas, xmlFile, "placeable.foliageAreas.foliageArea(%d)", false, false, true)

	if hasXMLProperty(xmlFile, "placeable.tipOcclusionUpdateArea") then
		local sizeX = getXMLFloat(xmlFile, "placeable.tipOcclusionUpdateArea#sizeX")
		local sizeZ = getXMLFloat(xmlFile, "placeable.tipOcclusionUpdateArea#sizeZ")

		if sizeX ~= nil and sizeZ ~= nil then
			local centerX = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.tipOcclusionUpdateArea#centerX"), 0)
			local centerZ = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.tipOcclusionUpdateArea#centerZ"), 0)
			self.tipOcclusionUpdateArea = {
				centerX,
				centerZ,
				sizeX,
				sizeZ
			}
		end
	end

	if not self.alignToWorldY then
		self.pos1Node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.placement#pos1Node"))
		self.pos2Node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.placement#pos2Node"))
		self.pos3Node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.placement#pos3Node"))

		if self.pos1Node == nil or self.pos2Node == nil or self.pos3Node == nil then
			self.alignToWorldY = true

			print("Warning: Pos1Node, Pos2Node and Pos3Node has to be set when alignToWorldY is false!")
		end
	end

	if hasXMLProperty(xmlFile, "placeable.animatedObjects") then
		local i = 0

		while true do
			local animationKey = string.format("placeable.animatedObjects.animatedObject(%d)", i)

			if not hasXMLProperty(xmlFile, animationKey) then
				break
			end

			local animatedObject = AnimatedObject:new(self.isServer, self.isClient)

			animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)

			if not animatedObject:load(self.nodeId, xmlFile, animationKey, self.configFileName) then
				print("Error: Failed to load animated object " .. tostring(i))
			else
				animatedObject:register(true)
				table.insert(self.animatedObjects, animatedObject)
			end

			i = i + 1
		end
	end

	local i = 0

	while true do
		local triggerMarkerKey = string.format("placeable.triggerMarkers.triggerMarker(%d)", i)

		if not hasXMLProperty(xmlFile, triggerMarkerKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, triggerMarkerKey .. "#node"))

		if node ~= nil then
			table.insert(self.triggerMarkers, node)
			g_currentMission:addTriggerMarker(node)
		end

		i = i + 1
	end

	if hasXMLProperty(xmlFile, "placeable.hotspots") then
		local i = 0

		while true do
			local hotspotKey = string.format("placeable.hotspots.hotspot(%d)", i)

			if not hasXMLProperty(xmlFile, hotspotKey) then
				break
			end

			local hotspot = MapHotspot.loadFromXML(xmlFile, hotspotKey, self.nodeId, self.baseDirectory)

			hotspot:setOwnerFarmId(self:getOwnerFarmId(), false)

			if hotspot ~= nil then
				g_currentMission:addMapHotspot(hotspot)
				table.insert(self.mapHotspots, hotspot)
			end

			i = i + 1
		end
	end

	if self.isClient then
		self.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, "placeable.sounds", "idle", self.baseDirectory, self.nodeId, 1, AudioGroup.ENVIRONMENT, nil, )
	end

	delete(xmlFile)

	return true
end

function Placeable:loadAreasFromXML(areaArray, xmlFile, xmlPathTemplate, isRamp, isLeveling, isFoliage)
	local i = 0

	while true do
		local key = string.format(xmlPathTemplate, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local area = {}

		if isFoliage then
			if self:loadFoliageAreaFromXML(area, xmlFile, key) then
				table.insert(areaArray, area)
			end
		elseif self:loadAreaFromXML(area, xmlFile, key, isRamp, isLeveling) then
			table.insert(areaArray, area)
		end

		i = i + 1
	end
end

function Placeable:loadAreaFromXML(area, xmlFile, key, isRamp, isLeveling)
	local start = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#startNode"))
	local width = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#widthNode"))
	local height = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#heightNode"))

	if start ~= nil and width ~= nil and height ~= nil then
		area.root = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#rootNode"))
		area.start = start
		area.width = width
		area.height = height
		area.texture = getXMLString(xmlFile, key .. "#texture")

		if isRamp then
			local rx, ry, rz = getRotation(area.root)
			area.baseRotation = {
				rx,
				ry,
				rz
			}
			local rampSlope = getXMLFloat(xmlFile, key .. "#maxSlope")
			area.maxSlope = rampSlope and MathUtil.degToRad(rampSlope) or self.maxSlope
		end

		if isLeveling then
			area.groundType = getXMLString(xmlFile, key .. "#groundType")
		end

		return true
	end

	return false
end

function Placeable:loadFoliageAreaFromXML(area, xmlFile, key)
	local rootNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#rootNode"))
	local fruitType = getXMLString(xmlFile, key .. "#fruitType")
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(fruitType)
	local state = getXMLInt(xmlFile, key .. "#state")

	if rootNode ~= nil and fruitTypeDesc ~= nil then
		area.fruitType = fruitTypeDesc.index
		area.fieldDimensions = rootNode
		area.fruitState = Utils.getNoNil(state, fruitTypeDesc.maxHarvestingGrowthState - 1)

		return true
	end

	return false
end

function Placeable:finalizePlacement()
	if self.isInPreviewMode then
		print("Error: Can't finalize placement of preview placeables")
	end

	if not self.isolated then
		self:alignToTerrain()

		local deform = self:createDeformationObject(g_currentMission.terrainRootNode, true, false)

		deform:blockAreas()

		self.writtenBlockedAreas = true

		addToPhysics(self.nodeId)
		g_currentMission:addPlaceable(self)
		g_currentMission:addItemToSave(self)
		g_currentMission:addOwnedItem(self)
		self:collectPickObjects(self.nodeId)

		for _, node in pairs(self.pickObjects) do
			g_currentMission:addNodeObject(node, self)
		end

		local missionInfo = g_currentMission.missionInfo

		if self.isServer and (not self.isLoadedFromSavegame or missionInfo.isValid and (not missionInfo:getIsTipCollisionValid(g_currentMission) or not missionInfo:getIsPlacementCollisionValid(g_currentMission))) then
			self:setTipOcclusionAreaDirty()
		end
	end

	if self.isClient then
		g_soundManager:playSample(self.samples.idle)
	end

	self:weatherChanged()
	g_currentMission.environment:addHourChangeListener(self)

	local x, _, z = getWorldTranslation(self.nodeId)
	self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)

	if self.boughtWithFarmland then
		if self.isServer then
			self:updateOwnership(true)
		end

		g_farmlandManager:addStateChangeListener(self)
	end

	g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, {
		self:getOwnerFarmId()
	})
end

function Placeable:setTipOcclusionAreaDirty()
	if self.tipOcclusionUpdateArea ~= nil and self.nodeId ~= 0 then
		local x, z, sizeX, sizeZ = unpack(self.tipOcclusionUpdateArea)
		local x1, _, z1 = localToWorld(self.nodeId, x + sizeX * 0.5, 0, z + sizeZ * 0.5)
		local x2, _, z2 = localToWorld(self.nodeId, x - sizeX * 0.5, 0, z + sizeZ * 0.5)
		local x3, _, z3 = localToWorld(self.nodeId, x + sizeX * 0.5, 0, z - sizeZ * 0.5)
		local x4, _, z4 = localToWorld(self.nodeId, x - sizeX * 0.5, 0, z - sizeZ * 0.5)
		local minX = math.min(math.min(x1, x2), math.min(x3, x4))
		local maxX = math.max(math.max(x1, x2), math.max(x3, x4))
		local minZ = math.min(math.min(z1, z2), math.min(z3, z4))
		local maxZ = math.max(math.max(z1, z2), math.max(z3, z4))

		g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ)
	end
end

function Placeable:alignToTerrain()
	if not self.alignToWorldY and self.isServer then
		local x1, y1, z1 = getWorldTranslation(self.nodeId)
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, y1, z1)

		setTranslation(self.nodeId, x1, y1, z1)

		local x2, y2, z2 = getWorldTranslation(self.pos1Node)
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, y2, z2)
		local x3, y3, z3 = getWorldTranslation(self.pos2Node)
		y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, y3, z3)
		local x4, y4, z4 = getWorldTranslation(self.pos3Node)
		y4 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x4, y4, z4)
		local dirX = x2 - x1
		local dirY = y2 - y1
		local dirZ = z2 - z1
		local dir2X = x3 - x4
		local dir2Y = y3 - y4
		local dir2Z = z3 - z4
		local upX, upY, upZ = MathUtil.crossProduct(dir2X, dir2Y, dir2Z, dirX, dirY, dirZ)

		setDirection(self.nodeId, dirX, dirY, dirZ, upX, upY, upZ)
	end
end

function Placeable:clearFoliageAndTipAreas()
	if self.isServer then
		for _, areas in pairs({
			self.clearAreas,
			self.levelAreas
		}) do
			for _, area in pairs(areas) do
				local x, _, z = getWorldTranslation(area.start)
				local x1, _, z1 = getWorldTranslation(area.width)
				local x2, _, z2 = getWorldTranslation(area.height)

				FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2)
				FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
				FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
				DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
			end
		end

		for _, area in pairs(self.foliageAreas) do
			FieldUtil.setAreaFruit(area.fieldDimensions, area.fruitType, area.fruitState)
		end
	end
end

function Placeable:initPose(x, y, z, rx, ry, rz, initRandom)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)
end

function Placeable:collectPickObjects(node)
	if getRigidBodyType(node) ~= "NoRigidBody" then
		table.insert(self.pickObjects, node)
	end

	local numChildren = getNumOfChildren(node)

	for i = 1, numChildren do
		self:collectPickObjects(getChildAt(node, i - 1))
	end
end

function Placeable:loadFromXMLFile(xmlFile, key, resetVehicles)
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#position"))
	local xRot, yRot, zRot = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))

	if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
		return false
	end

	xRot = math.rad(xRot)
	yRot = math.rad(yRot)
	zRot = math.rad(zRot)
	local xmlFilename = getXMLString(xmlFile, key .. "#filename")

	if xmlFilename == nil then
		return false
	end

	xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFilename)

	if self:load(xmlFilename, x, y, z, xRot, yRot, zRot, false, false) then
		self.age = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#age"), 0)
		self.price = Utils.getNoNil(getXMLInt(xmlFile, key .. "#price"), self.price)

		self:setOwnerFarmId(Utils.getNoNil(getXMLInt(xmlFile, key .. "#farmId"), AccessHandler.EVERYONE), true)

		self.mapBoundId = Utils.getNoNil(getXMLString(xmlFile, key .. "#mapBoundId"), self.mapBoundId)
		self.isLoadedFromSavegame = true

		self:finalizePlacement()

		for i, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:loadFromXMLFile(xmlFile, string.format("%s.animatedObjects.animatedObject(%d)", key, i - 1))
		end

		return true
	else
		return false
	end
end

function Placeable:saveToXMLFile(xmlFile, key, usedModNames)
	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)

	setXMLString(xmlFile, key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
	setXMLString(xmlFile, key .. "#position", string.format("%.4f %.4f %.4f", x, y, z))
	setXMLString(xmlFile, key .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(xRot), math.deg(yRot), math.deg(zRot)))
	setXMLInt(xmlFile, key .. "#age", self.age)
	setXMLFloat(xmlFile, key .. "#price", self.price)
	setXMLInt(xmlFile, key .. "#farmId", self:getOwnerFarmId())

	if self.mapBoundId ~= nil then
		setXMLString(xmlFile, key .. "#mapBoundId", self.mapBoundId)
	end

	for i, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:saveToXMLFile(xmlFile, string.format("%s.animatedObjects.animatedObject(%d)", key, i - 1), usedModNames)
	end
end

function Placeable:getNeedsSaving()
	return true
end

function Placeable:update(dt)
end

function Placeable:updateTick(dt)
end

function Placeable:getPrice()
	return self.price
end

function Placeable:canBuy()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local enoughItems = storeItem.maxItemCount == nil or storeItem.maxItemCount ~= nil and g_currentMission:getNumOfItems(storeItem, g_currentMission:getFarmId()) < storeItem.maxItemCount

	return enoughItems
end

function Placeable:getCanBePlacedAt(x, y, z, distance, farmId)
	return true
end

function Placeable:canBeSold()
	return true, nil
end

function Placeable:onBuy()
end

function Placeable:onSell()
	if self.isServer then
		self:setTipOcclusionAreaDirty()
	end

	g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, {
		self:getOwnerFarmId()
	})
end

function Placeable:getDailyUpkeep()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)
		multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, nil) * multiplier
end

function Placeable:getName()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		return storeItem.name
	end

	return nil
end

function Placeable:getSellPrice()
	local priceMultiplier = 0.5
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem == nil then
		g_logManager:devWarning("Missing storeItem for placable '%s'", self.configFileName)

		return 0
	end

	local maxVehicleAge = storeItem.lifetime

	if maxVehicleAge ~= nil and maxVehicleAge ~= 0 then
		priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxVehicleAge, 1))
	end

	return math.floor(self.price * math.max(priceMultiplier, 0.05))
end

function Placeable:isMapBound()
	return self.mapBoundId ~= nil
end

function Placeable:hourChanged()
	if self.isServer and self.incomePerHour ~= 0 then
		g_currentMission:addMoney(self.incomePerHour, self:getOwnerFarmId(), MoneyType.PROPERTY_INCOME, true)
	end
end

function Placeable:dayChanged()
	self.age = self.age + 1
end

function Placeable:weatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil and self.dayNightObjects ~= nil then
		for _, dayNightObject in pairs(self.dayNightObjects) do
			if dayNightObject.visibleDay ~= nil and dayNightObject.visibleNight ~= nil then
				setVisibility(dayNightObject.node, g_currentMission.environment.isSunOn and dayNightObject.visibleDay or dayNightObject.visibleNight and not g_currentMission.environment.isSunOn and not g_currentMission.environment.weather:getIsRaining())
			elseif dayNightObject.intensityDay ~= nil and dayNightObject.intensityNight ~= nil then
				local intensity = dayNightObject.intensityNight

				if g_currentMission.environment.isSunOn then
					intensity = dayNightObject.intensityDay
				end

				local _, y, z, w = getShaderParameter(dayNightObject.node, "lightControl")

				setShaderParameter(dayNightObject.node, "lightControl", intensity, y, z, w, false)
			end
		end
	end
end

function Placeable:getPositionSnapSize()
	return self.placementPositionSnapSize
end

function Placeable:getPositionSnapOffset()
	return self.placementPositionSnapOffset
end

function Placeable:getRotationSnapAngle()
	return self.placementRotationSnapAngle
end

function Placeable:setOwnerFarmId(ownerFarmId, noEventSend)
	Placeable:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)

	for _, hotspot in ipairs(self.mapHotspots) do
		hotspot:setOwnerFarmId(ownerFarmId, true)
	end

	for _, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:setOwnerFarmId(ownerFarmId, true)
	end
end

function Placeable:createDeformationObject(terrainRootNode, forBlockingOnly, isBlocking)
	if not forBlockingOnly then
		isBlocking = false
	end

	local deform = TerrainDeformation:new(terrainRootNode)

	if forBlockingOnly and not isBlocking then
		for _, rampArea in pairs(self.rampAreas) do
			local layer = -1

			Placeable.addPlaceableRampArea(deform, rampArea, layer, rampArea.maxSlope, terrainRootNode)
		end
	end

	for _, levelArea in pairs(self.levelAreas) do
		local layer = -1

		if levelArea.groundType ~= nil then
			layer = g_groundTypeManager:getTerrainLayerByType(levelArea.groundType)
		end

		Placeable.addPlaceableLevelingArea(deform, levelArea, layer, true)
	end

	if g_densityMapHeightManager.placementCollisionMap ~= nil then
		deform:setBlockedAreaMap(g_densityMapHeightManager.placementCollisionMap, 0)
	end

	if self.smoothingGroundType ~= nil then
		deform:setOutsideAreaBrush(g_groundTypeManager:getTerrainLayerByType(self.smoothingGroundType))
	end

	deform:setOutsideAreaConstraints(self.maxSmoothDistance, self.maxSlope, self.maxEdgeAngle)
	deform:setBlockedAreaMaxDisplacement(0.001)
	deform:setDynamicObjectCollisionMask(1048543)
	deform:setDynamicObjectMaxDisplacement(0.03)

	return deform
end

function Placeable:updateOwnership(updateOwner)
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local farmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)

	if not storeItem.canBeSold and farmId == AccessHandler.EVERYONE then
		farmId = AccessHandler.NOBODY
	end

	if self.isServer and updateOwner then
		self:setOwnerFarmId(farmId)
	end
end

function Placeable:onFarmlandStateChanged(farmlandId, farmId)
	if self.boughtWithFarmland and farmlandId == self.farmlandId then
		self:updateOwnership(true)
	end
end

function Placeable.addPlaceableLevelingArea(terrainDeform, levelArea, terrainBrushId, writeBlockedAreaMap)
	local worldStartX, worldStartY, worldStartZ = getWorldTranslation(levelArea.start)
	local worldSide1X, worldSide1Y, worldSide1Z = getWorldTranslation(levelArea.width)
	local worldSide2X, worldSide2Y, worldSide2Z = getWorldTranslation(levelArea.height)
	local side1X = worldSide1X - worldStartX
	local side1Y = worldSide1Y - worldStartY
	local side1Z = worldSide1Z - worldStartZ
	local side2X = worldSide2X - worldStartX
	local side2Y = worldSide2Y - worldStartY
	local side2Z = worldSide2Z - worldStartZ

	terrainDeform:addArea(worldStartX, worldStartY, worldStartZ, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId, writeBlockedAreaMap)
end

function Placeable.addPlaceableRampArea(terrainDeform, rampArea, terrainBrushId, maxRampSlope, terrainRootNode)
	local startX, startY, startZ = getWorldTranslation(rampArea.start)
	local widthX, widthY, widthZ = getWorldTranslation(rampArea.width)
	local heightX, heightY, heightZ = getWorldTranslation(rampArea.height)
	local rampForwardX = heightX - startX
	local rampForwardY = heightY - startY
	local rampForwardZ = heightZ - startZ
	local rampLeftX = widthX - startX
	local rampLeftZ = widthZ - startZ
	local rampLength = MathUtil.vector3Length(rampForwardX, rampForwardY, rampForwardZ)
	local angle = 0
	local angleStep = 0.01
	local diff = 1
	local i = 0

	while math.abs(diff) > 0.01 and i < 50 do
		diff = 0
		local rampHeight = startY + rampLength * math.sin(angle)
		local forward = math.cos(angle)
		local scanStep = 0.5

		for scanStep = 0, 1.01, 0.25 do
			local x = startX + rampForwardX * forward + rampLeftX * scanStep
			local z = startZ + rampForwardZ * forward + rampLeftZ * scanStep
			local terrainHeight = getTerrainHeightAtWorldPos(terrainRootNode, x, 0, z)
			diff = diff + rampHeight - terrainHeight
		end

		angle = angle - angleStep * diff * 0.2
		i = i + 1
	end

	angle = MathUtil.clamp(angle, -maxRampSlope, maxRampSlope)

	setRotation(rampArea.root, rampArea.baseRotation[1], rampArea.baseRotation[2], rampArea.baseRotation[3])

	local lwX, lwY, lwZ = getTranslation(rampArea.width)

	rotateAboutLocalAxis(rampArea.root, -angle, lwX, lwY, lwZ)
	Placeable.addPlaceableLevelingArea(terrainDeform, rampArea, terrainBrushId, false)
end

function Placeable.loadSpecValueIncomePerHour(xmlFile, customEnvironment)
	if not hasXMLProperty(xmlFile, "placeable.incomePerHour1") then
		return nil
	end

	local incomePerHour = {
		Utils.getNoNil(getXMLFloat(xmlFile, "placeable.incomePerHour1"), 0),
		Utils.getNoNil(getXMLFloat(xmlFile, "placeable.incomePerHour2"), 0),
		Utils.getNoNil(getXMLFloat(xmlFile, "placeable.incomePerHour3"), 0)
	}

	return incomePerHour
end

function Placeable.getSpecValueIncomePerHour(storeItem, realItem)
	if storeItem.specs.incomePerHour == nil then
		return nil
	end

	return string.format(g_i18n:getText("shop_incomeValue"), g_i18n:formatMoney(storeItem.specs.incomePerHour[g_currentMission.missionInfo.economicDifficulty]))
end
