DensityMapHeightManager = {
	TIP_COL_FILENAME = "tipColMap.grle",
	PLC_COL_FILENAME = "plcColMap.grle"
}
local DensityMapHeightManager_mt = Class(DensityMapHeightManager, AbstractManager)

function DensityMapHeightManager:new(customMt)
	local self = AbstractManager:new(customMt or DensityMapHeightManager_mt)

	return self
end

function DensityMapHeightManager:initDataStructures()
	self.numHeightTypes = 0
	self.heightTypes = {}
	self.fillTypeNameToHeightType = {}
	self.fillTypeIndexToHeightType = {}
	self.heightTypeIndexToFillTypeIndex = {}
	self.fixedFillTypesAreas = {}
	self.convertingFillTypesAreas = {}
	self.tipTypeMappings = {}

	if self.terrainDetailHeightUpdater ~= nil then
		delete(self.terrainDetailHeightUpdater)

		self.terrainDetailHeightUpdater = nil
	end

	if self.collisionMap ~= nil then
		delete(self.collisionMap)

		self.collisionMap = nil
	end

	if self.placementCollisionMap ~= nil then
		delete(self.placementCollisionMap)

		self.placementCollisionMap = nil
	end

	self.tipCollisionMask = 524288
	self.placementCollisionMask = 1048543
end

function DensityMapHeightManager:loadDefaultTypes(missionInfo, baseDirectory)
	self:initDataStructures()

	local xmlFile = loadXMLFile("heightTypes", "data/maps/maps_densityMapHeightTypes.xml")

	self:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end

function DensityMapHeightManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	DensityMapHeightManager:superClass().loadMapData(self)
	self:loadDefaultTypes(missionInfo, baseDirectory)

	return XMLUtil.loadDataFromMapXML(xmlFile, "densityMapHeightTypes", baseDirectory, self, self.loadDensityMapHeightTypes, missionInfo, baseDirectory)
end

function DensityMapHeightManager:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.densityMapHeightTypes.densityMapHeightType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local fillTypeName = getXMLString(xmlFile, key .. "#fillTypeName")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			print("Error loading density map height. '" .. tostring(key) .. "' has no valid 'fillTypeName'!")

			return
		end

		local maxSurfaceAngle = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxSurfaceAngle"), 26))
		local fillToGroundScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#fillToGroundScale"), 1)
		local allowsSmoothing = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsSmoothing"), false)
		local collisionScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".collision#scale"), 1)
		local collisionBaseOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".collision#baseOffset"), 0)
		local minCollisionOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".collision#minOffset"), 0)
		local maxCollisionOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".collision#maxOffset"), 1)
		local diffuseMapFilename = Utils.getFilename(getXMLString(xmlFile, key .. ".textures#diffuse"), baseDirectory)
		local normalMapFilename = Utils.getFilename(getXMLString(xmlFile, key .. ".textures#normal"), baseDirectory)
		local distanceFilename = Utils.getFilename(getXMLString(xmlFile, key .. ".textures#distance"), baseDirectory)

		if diffuseMapFilename == nil or normalMapFilename == nil or distanceFilename == nil then
			print("Error loading density map height type. '" .. tostring(key) .. "' is missing texture(s)!")

			return
		end

		self:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, diffuseMapFilename, normalMapFilename, distanceFilename, isBaseType)

		i = i + 1
	end

	return true
end

function DensityMapHeightManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end

	local xmlFile = loadXMLFile("densitymapHeightXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	self.tipTypeMappings = {}
	local i = 0

	while true do
		local mappingKey = string.format("tipTypeMappings.tipTypeMapping(%d)", i)

		if not hasXMLProperty(xmlFile, mappingKey) then
			break
		end

		local name = getXMLString(xmlFile, mappingKey .. "#fillType")
		local index = getXMLInt(xmlFile, mappingKey .. "#index")

		if name ~= nil and index ~= nil then
			self.tipTypeMappings[name] = index
		end

		i = i + 1
	end

	delete(xmlFile)
end

function DensityMapHeightManager:saveToXMLFile(xmlFilename)
	local xmlFile = createXMLFile("densityMapHeightXML", xmlFilename, "tipTypeMappings")

	if xmlFile ~= nil then
		for k, heightType in ipairs(self.heightTypes) do
			local mappingKey = string.format("tipTypeMappings.tipTypeMapping(%d)", k - 1)

			setXMLString(xmlFile, mappingKey .. "#fillType", heightType.fillTypeName)
			setXMLInt(xmlFile, mappingKey .. "#index", heightType.index)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)

		return true
	end

	return false
end

function DensityMapHeightManager:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, diffuseMapFilename, normalMapFilename, distanceMapFilename, isBaseType)
	if isBaseType and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
		print("Warning: density height map for '" .. tostring(fillTypeName) .. "' already exists!")

		return nil
	end

	local heightType = self.fillTypeNameToHeightType[fillTypeName]

	if heightType == nil then
		self.numHeightTypes = self.numHeightTypes + 1
		heightType = {
			index = self.numHeightTypes,
			fillTypeName = fillTypeName
		}
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		heightType.fillTypeIndex = fillTypeIndex

		table.insert(self.heightTypes, heightType)

		self.fillTypeNameToHeightType[fillTypeName] = heightType
		self.fillTypeIndexToHeightType[fillTypeIndex] = heightType
		self.heightTypeIndexToFillTypeIndex[heightType.index] = fillTypeIndex
	end

	heightType.maxSurfaceAngle = maxSurfaceAngle
	heightType.collisionScale = collisionScale
	heightType.collisionBaseOffset = collisionBaseOffset
	heightType.minCollisionOffset = minCollisionOffset
	heightType.maxCollisionOffset = maxCollisionOffset
	heightType.fillToGroundScale = fillToGroundScale
	heightType.allowsSmoothing = allowsSmoothing
	heightType.diffuseMapFilename = diffuseMapFilename
	heightType.normalMapFilename = normalMapFilename
	heightType.distanceMapFilename = distanceMapFilename

	return heightType
end

function DensityMapHeightManager:getDensityMapHeightTypeByIndex(index)
	if index ~= nil then
		return self.heightTypes[index]
	end

	return nil
end

function DensityMapHeightManager:getFillTypeNameByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeName
	end

	return nil
end

function DensityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeIndex
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeName(fillTypeName)
	if fillTypeName ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName]
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex]
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeName(fillTypeName)
	if fillTypeName ~= nil and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName].index
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil and self.fillTypeIndexToHeightType[fillTypeIndex] ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex].index
	end

	return nil
end

function DensityMapHeightManager:getDensityMapHeightTypes()
	return self.heightTypes
end

function DensityMapHeightManager:getFillTypeToDensityMapHeightTypes()
	return self.fillTypeIndexToHeightType
end

function DensityMapHeightManager:setFixedFillTypesArea(area, fillTypes)
	self.fixedFillTypesAreas[area] = {
		fillTypes = fillTypes
	}
end

function DensityMapHeightManager:removeFixedFillTypesArea(area)
	self.fixedFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getFixedFillTypesAreas()
	return self.fixedFillTypesAreas
end

function DensityMapHeightManager:setConvertingFillTypeAreas(area, fillTypes, fillTypeTarget)
	self.convertingFillTypesAreas[area] = {
		fillTypes = fillTypes,
		fillTypeTarget = fillTypeTarget
	}
end

function DensityMapHeightManager:removeConvertingFillTypeAreas(area)
	self.convertingFillTypesAreas[area] = nil
end

function DensityMapHeightManager:getConvertingFillTypesAreas()
	return self.convertingFillTypesAreas
end

function DensityMapHeightManager:checkTypeMappings()
	local typeMappings = self.tipTypeMappings

	if typeMappings ~= nil and next(typeMappings) ~= nil then
		local numUsedMappings = 0

		for _, entry in ipairs(self.heightTypes) do
			local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
			local oldTypeIndex = typeMappings[name]

			if oldTypeIndex == nil or oldTypeIndex ~= entry.index then
				return false
			end

			numUsedMappings = numUsedMappings + 1
		end

		local numMappings = 0

		for _, _ in pairs(typeMappings) do
			numMappings = numMappings + 1
		end

		if numMappings ~= numUsedMappings then
			return false
		end
	end

	return true
end

function DensityMapHeightManager:initialize(isServer, collisionMapFilename, placementCollisionMapFilename)
	local id = g_currentMission.terrainDetailHeightId
	self.tipToGroundIsAllowed = true
	local densitySize = getDensityMapSize(id)
	local deform = TerrainDeformation:new(g_currentMission.terrainRootNode)
	local placementMapSize = deform:getBlockedAreaMapSize()

	deform:cancel()

	self.worldToDensityMap = densitySize / g_currentMission.terrainSize
	self.densityToWorldMap = g_currentMission.terrainSize / densitySize
	self.worldToPlacementMap = placementMapSize / g_currentMission.terrainSize
	self.placementToWorldMap = g_currentMission.terrainSize / placementMapSize
	self.pendingCollisionRecalculateAreas = {}
	self.collisionRecalculateAreaSize = 16
	self.collisionRecalculateAreaWorldSize = self.collisionRecalculateAreaSize * self.densityToWorldMap
	self.numCollisionRecalculateAreasPerSide = math.floor((densitySize + self.collisionRecalculateAreaSize - 1) / self.collisionRecalculateAreaSize)
	local litersPerMeter = 250
	local maxHeight = getDensityMapMaxHeight(id)
	local unitLength = g_currentMission.terrainSize / densitySize
	self.volumePerPixel = maxHeight * unitLength * unitLength
	self.literPerPixel = litersPerMeter * maxHeight * self.volumePerPixel
	self.fillToGroundScale = self.worldToDensityMap^2 / (litersPerMeter * maxHeight)
	local maxHeightDensityValue = 2^getDensityMapHeightNumChannels(id) - 1
	self.minValidLiterValue = self.literPerPixel / maxHeightDensityValue
	self.minValidVolumeValue = self.volumePerPixel / maxHeightDensityValue
	self.heightToDensityValue = maxHeightDensityValue / maxHeight
	local densityMapHeightCollisionMask = 10
	self.terrainDetailHeightUpdater = createDensityMapHeightUpdater("TerrainDetailHeightUpdater", id, g_currentMission.terrainDetailHeightTypeFirstChannel, g_currentMission.terrainDetailHeightTypeNumChannels, densityMapHeightCollisionMask)
	local distanceConstr = TerrainDetailDistanceConstructor:new(g_currentMission.terrainDetailHeightTypeFirstChannel, g_currentMission.terrainDetailHeightTypeNumChannels)
	local diffuseMapConstr = TextureArrayConstructor:new()
	local normalMapConstr = TextureArrayConstructor:new()
	local numUsedMappings = 0
	local heightTypes = self:getDensityMapHeightTypes()

	if heightTypes ~= nil then
		for _, entry in ipairs(heightTypes) do
			local oldTypeIndex = entry.index

			if self.tipTypeMappings ~= nil and next(self.tipTypeMappings) ~= nil then
				local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
				local fillTypeName = name:lower()
				oldTypeIndex = Utils.getNoNil(self.tipTypeMappings[fillTypeName], -1)

				if oldTypeIndex >= 0 then
					numUsedMappings = numUsedMappings + 1
				end
			end

			setDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, entry.index, oldTypeIndex, entry.maxSurfaceAngle, entry.collisionScale, entry.collisionBaseOffset, entry.minCollisionOffset, entry.maxCollisionOffset)
			diffuseMapConstr:addLayerFilename(entry.diffuseMapFilename)
			normalMapConstr:addLayerFilename(entry.normalMapFilename)

			if entry.distanceMapFilename ~= nil and entry.distanceMapFilename:len() > 0 then
				distanceConstr:addTexture(entry.index - 1, entry.distanceMapFilename, 3)
			end
		end
	end

	distanceConstr:finalize(g_currentMission.terrainDetailHeightId)

	local forceTypeConversion = false

	if self.tipTypeMappings ~= nil then
		local numMappings = 0

		for _, _ in pairs(self.tipTypeMappings) do
			numMappings = numMappings + 1
		end

		if numMappings ~= numUsedMappings then
			forceTypeConversion = true
		end
	end

	initDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, forceTypeConversion)

	local missionInfo = g_currentMission.missionInfo

	if isServer then
		self.collisionMap = createBitVectorMap("CollisionMap")
		local collisionMapValid = false

		if not GS_IS_MOBILE_VERSION and missionInfo:getIsTipCollisionValid(g_currentMission) then
			local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.TIP_COL_FILENAME

			if loadBitVectorMapFromFile(self.collisionMap, savegameFilename, 2) and setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.collisionMap, false) then
				collisionMapValid = true
			else
				print("Warning: Failed to load savegame collision map '" .. savegameFilename .. "'. Loading default collision map and recreating from placeables.")
			end
		end

		if not collisionMapValid then
			local cleanupHeights = false

			if missionInfo.isValid then
				cleanupHeights = true
			end

			if collisionMapFilename == nil or not loadBitVectorMapFromFile(self.collisionMap, collisionMapFilename, 2) or not setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.collisionMap, cleanupHeights) then
				if collisionMapFilename == nil then
					print("Warning: No collision map defined. Creating empty collision map.")
				else
					print("Warning: Failed to load collision map '" .. collisionMapFilename .. "'. Creating empty collision map.")
				end

				loadBitVectorMapNew(self.collisionMap, densitySize, densitySize, 2, false)
				setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.collisionMap, cleanupHeights)
			end
		end
	end

	self.placementCollisionMap = createBitVectorMap("PlacementCollisionMap")
	local placementCollisionMapValid = false

	if not GS_IS_MOBILE_VERSION and missionInfo:getIsPlacementCollisionValid(g_currentMission) then
		local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.PLC_COL_FILENAME

		if loadBitVectorMapFromFile(self.placementCollisionMap, savegameFilename, 1) then
			placementCollisionMapValid = true
		else
			print("Warning: Failed to load savegame placement collision map '" .. savegameFilename .. "'. Loading default placement collision map and recreating from placeables.")
		end
	end

	if not placementCollisionMapValid and (placementCollisionMapFilename == nil or not loadBitVectorMapFromFile(self.placementCollisionMap, placementCollisionMapFilename, 1)) then
		if placementCollisionMapFilename == nil then
			print("Warning: No placement collision map defined. Creating empty placement collision map.")
		else
			print("Warning: Failed to load placement collision map '" .. placementCollisionMapFilename .. "'. Creating empty placement collision map.")
		end

		loadBitVectorMapNew(self.placementCollisionMap, placementMapSize, placementMapSize, 1, false)
	end

	local diffuseMap = diffuseMapConstr:finalize(true, true, true)
	local normalMap = normalMapConstr:finalize(true, false, true)
	local numShapes = getNumOfChildren(g_currentMission.terrainDetailHeightId)

	for i = 0, numShapes - 1 do
		local detailShape = getChildAt(g_currentMission.terrainDetailHeightId, i)

		if getHasClassId(detailShape, ClassIds.SHAPE) then
			local material = getMaterial(detailShape, 0)

			if diffuseMap ~= 0 then
				setMaterialDiffuseMap(material, diffuseMap)
			end

			if normalMap ~= 0 then
				setMaterialNormalMap(material, normalMap)
			end
		end
	end

	if diffuseMap ~= 0 then
		delete(diffuseMap)
	end

	if normalMap ~= 0 then
		delete(normalMap)
	end
end

function DensityMapHeightManager:getIsValid()
	return self.terrainDetailHeightUpdater ~= nil
end

function DensityMapHeightManager:getTerrainDetailHeightUpdater()
	return self.terrainDetailHeightUpdater
end

function DensityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
	local heightType = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0
	end

	return self.minValidLiterValue / heightType.fillToGroundScale
end

function DensityMapHeightManager:update(dt)
	if not self:getIsValid() then
		return
	end

	local num = 0

	for areaIndex in pairs(self.pendingCollisionRecalculateAreas) do
		self.pendingCollisionRecalculateAreas[areaIndex] = nil
		local zi = math.floor(areaIndex / self.numCollisionRecalculateAreasPerSide)
		local xi = areaIndex - zi * self.numCollisionRecalculateAreasPerSide
		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local minX = xi * self.collisionRecalculateAreaWorldSize - terrainHalfSize
		local minZ = zi * self.collisionRecalculateAreaWorldSize - terrainHalfSize

		self:updateCollisionMap(minX, minZ, minX + self.collisionRecalculateAreaWorldSize, minZ + self.collisionRecalculateAreaWorldSize)

		num = num + 1

		if num > 6 then
			break
		end
	end
end

function DensityMapHeightManager:visualizeCollisionMap()
	if self.collisionMap ~= nil then
		local densitySize = getDensityMapSize(g_currentMission.terrainDetailHeightId)
		local x, y, z = getWorldTranslation(getCamera(0))

		if g_currentMission.controlledVehicle ~= nil then
			local object = g_currentMission.controlledVehicle

			if g_currentMission.controlledVehicle.selectedImplement ~= nil then
				object = g_currentMission.controlledVehicle.selectedImplement.object
			end

			x, y, z = getWorldTranslation(object.components[1].node)
		end

		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local xi = math.floor((x + terrainHalfSize) * self.worldToDensityMap)
		local zi = math.floor((z + terrainHalfSize) * self.worldToDensityMap)
		local minXi = math.max(xi - 20, 0)
		local minZi = math.max(zi - 20, 0)
		local maxXi = math.min(xi + 20, densitySize - 1)
		local maxZi = math.min(zi + 20, densitySize - 1)

		for zi = minZi, maxZi do
			for xi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.collisionMap, xi, zi, 0, 2)
				local r = 0
				local g = 1
				local b = 0

				if v > 1 then
					b = 0.1
					g = 0
					r = 1
				elseif v > 0 then
					b = 1
					g = 0
					r = 0
				end

				local x = xi * self.densityToWorldMap - terrainHalfSize
				local z = zi * self.densityToWorldMap - terrainHalfSize
				local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.1

				Utils.renderTextAtWorldPosition(x, y, z, tostring(v), getCorrectTextSize(0.009), 0, {
					r,
					g,
					b,
					1
				})
			end
		end
	end
end

function DensityMapHeightManager:visualizePlacementCollisionMap()
	if self.placementCollisionMap ~= nil then
		local densitySize = getDensityMapSize(g_currentMission.terrainDetailHeightId)
		local x, y, z = getWorldTranslation(getCamera(0))

		if g_currentMission.controlledVehicle ~= nil then
			local object = g_currentMission.controlledVehicle

			if g_currentMission.controlledVehicle.selectedImplement ~= nil then
				object = g_currentMission.controlledVehicle.selectedImplement.object
			end

			x, y, z = getWorldTranslation(object.components[1].node)
		end

		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		local xi = math.floor((x + terrainHalfSize) * self.worldToPlacementMap)
		local zi = math.floor((z + terrainHalfSize) * self.worldToPlacementMap)
		local minXi = math.max(xi - 20, 0)
		local minZi = math.max(zi - 20, 0)
		local maxXi = math.min(xi + 20, densitySize - 1)
		local maxZi = math.min(zi + 20, densitySize - 1)

		for zi = minZi, maxZi do
			for xi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.placementCollisionMap, xi, zi, 0, 1)
				local r = 0
				local g = 1
				local b = 0

				if v > 0 then
					b = 0
					g = 0
					r = 1
				end

				local x = xi * self.placementToWorldMap - terrainHalfSize
				local z = zi * self.placementToWorldMap - terrainHalfSize
				local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

				drawDebugLine(x, y, z, r, g, b, x, y + 1, z, r, g, b, false)
			end
		end
	end
end

function DensityMapHeightManager:saveCollisionMap(directory)
	if self.collisionMap ~= nil then
		saveBitVectorMapToFile(self.collisionMap, directory .. "/tipColMap.grle")
	end
end

function DensityMapHeightManager:prepareSaveCollisionMap(directory)
	if self.collisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.collisionMap, directory .. "/tipColMap.grle")
	end
end

function DensityMapHeightManager:savePreparedCollisionMap(callback, callbackObject)
	if self.collisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.collisionMap, callback, callbackObject)
	end
end

function DensityMapHeightManager:savePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		saveBitVectorMapToFile(self.placementCollisionMap, directory .. "/plcColMap.grle")
	end
end

function DensityMapHeightManager:prepareSavePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.placementCollisionMap, directory .. "/plcColMap.grle")
	end
end

function DensityMapHeightManager:savePreparedPlacementCollisionMap(callback, callbackObject)
	if self.placementCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.placementCollisionMap, callback, callbackObject)
	end
end

function DensityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ)
	local terrainHalfSize = g_currentMission.terrainSize * 0.5
	local minXi = math.floor((minX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local minZi = math.floor((minZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxXi = math.ceil((maxX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxZi = math.ceil((maxZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)

	for zi = minZi, maxZi do
		for xi = minXi, maxXi do
			local areaIndex = zi * self.numCollisionRecalculateAreasPerSide + xi
			self.pendingCollisionRecalculateAreas[areaIndex] = true
		end
	end
end

function DensityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ)
	if self.collisionMap ~= nil or self.placementCollisionMap ~= nil then
		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		minX = MathUtil.clamp(minX, -terrainHalfSize, terrainHalfSize)
		minZ = MathUtil.clamp(minZ, -terrainHalfSize, terrainHalfSize)
		maxX = MathUtil.clamp(maxX, -terrainHalfSize, terrainHalfSize)
		maxZ = MathUtil.clamp(maxZ, -terrainHalfSize, terrainHalfSize)

		if self.collisionMap ~= nil then
			updateTerrainCollisionMap(self.collisionMap, g_currentMission.terrainRootNode, "tipCol", 0, self.tipCollisionMask, minX, minZ, maxX, maxZ)
		end

		if self.placementCollisionMap ~= nil then
			updatePlacementCollisionMap(self.placementCollisionMap, g_currentMission.terrainRootNode, self.placementCollisionMask, minX, minZ, maxX, maxZ)
		end
	end
end

g_densityMapHeightManager = DensityMapHeightManager:new()
