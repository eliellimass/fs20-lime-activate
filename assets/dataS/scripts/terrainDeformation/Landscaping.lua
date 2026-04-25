Landscaping = {}
local Landscaping_mt = Class(Landscaping)
Landscaping.BRUSH_SHAPE_NUM_SEND_BITS = 2
Landscaping.OPERATION_NUM_SEND_BITS = 3
Landscaping.BRUSH_SHAPE = {
	SQUARE = 1,
	CIRCLE = 2
}
Landscaping.OPERATION = {
	RAISE = 1,
	LOWER = 2,
	FLATTEN = 4,
	SMOOTH = 3,
	PAINT = 5
}
Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP = {
	[Landscaping.OPERATION.RAISE] = 1,
	[Landscaping.OPERATION.LOWER] = -1,
	[Landscaping.OPERATION.SMOOTH] = 0,
	[Landscaping.OPERATION.FLATTEN] = 0,
	[Landscaping.OPERATION.PAINT] = 0
}
Landscaping.TERRAIN_UNIT = 2
Landscaping.SCULPT_BASE_COST_PER_M3 = 5
Landscaping.PAINT_BASE_COST_PER_M2 = 1

local function NO_CALLBACK()
end

function Landscaping:new(terrainDeformationQueue, farmlandManager, terrainRootNode, placementCollisionMap, playerFarm, userId, isMasterUser, validateOnly, callbackFunction, callbackFunctionTarget)
	local self = setmetatable({}, Landscaping_mt)
	self.terrainDeformationQueue = terrainDeformationQueue
	self.farmlandManager = farmlandManager
	self.terrainRootNode = terrainRootNode
	self.placementCollisionMap = placementCollisionMap
	self.playerFarm = playerFarm
	self.currentUserId = userId
	self.isMasterUser = isMasterUser
	self.validateOnly = validateOnly
	self.callbackFunction = callbackFunction or NO_CALLBACK
	self.callbackFunctionTarget = callbackFunctionTarget
	self.terrainUnit = Landscaping.TERRAIN_UNIT
	self.halfTerrainUnit = Landscaping.TERRAIN_UNIT / 2
	self.targetPosition = nil
	self.radius = 0
	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	self.smoothingDistance = 0
	self.sculptingOperation = Landscaping.OPERATION.RAISE
	self.modifiedAreas = {}
	self.modifiedAreaSize = 0

	return self
end

function Landscaping:delete()
end

function Landscaping:hasObjectOverlapInModificationArea(x, y, z)
	local range = self.radius + self.terrainUnit * 2

	for _, player in pairs(g_currentMission.players) do
		if player.isControlled then
			local pX, _, pZ = getWorldTranslation(player.rootNode)
			local dX = pX - x
			local dZ = pZ - z

			if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
				local sqrRange = range * range
				local sqrDistance = dX * dX + dZ * dZ

				if sqrRange >= sqrDistance then
					return true
				end
			elseif math.abs(dX) <= range and math.abs(dZ) <= range then
				return true
			end
		end
	end

	return false
end

function Landscaping:assignAxisAlignedArea(deform, x, y, z, width, length, terrainBrushId)
	local side1X = width - 0.002
	local side1Y = 0
	local side1Z = 0
	local side2X = 0
	local side2Y = 0
	local side2Z = length - 0.002

	deform:addArea(x + 0.001, y, z + 0.001, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId, false)
end

function Landscaping:addAxisAlignedModifiedArea(x, z, width, length)
	local addedSize = 0

	if self.sculptingOperation == Landscaping.OPERATION.RAISE or self.sculptingOperation == Landscaping.OPERATION.LOWER then
		addedSize = math.max(width, length, self.smoothingDistance) * 0.5
	end

	local startX = x - addedSize
	local startZ = z - addedSize

	table.insert(self.modifiedAreas, {
		startX,
		startZ,
		startX + width + addedSize * 2,
		startZ,
		startX,
		startZ + length + addedSize * 2
	})
end

function Landscaping:assignSquareBrushArea(deform, sideLength, heightChange, x, y, z, sculptingDirection, terrainBrushId)
	local startX = x - sideLength * 0.5
	local startY = y + heightChange * sculptingDirection
	local startZ = z - sideLength * 0.5

	self:assignAxisAlignedArea(deform, startX - self.halfTerrainUnit, startY, startZ - self.halfTerrainUnit, sideLength, sideLength, terrainBrushId)
	self:addAxisAlignedModifiedArea(startX, startZ, sideLength, sideLength)
end

local SQRT_2_DIV_FACTOR = 1 / math.sqrt(2)

function Landscaping:assignCircleBrushArea(deform, radius, heightChange, x, y, z, sculptingDirection, modificationAreaOnly)
	if radius < self.terrainUnit + self.halfTerrainUnit then
		local size = radius * 2 * SQRT_2_DIV_FACTOR

		if modificationAreaOnly then
			self:addAxisAlignedModifiedArea(x - self.halfTerrainUnit, z - self.halfTerrainUnit, size, size)
		else
			self:assignSquareBrushArea(deform, size, heightChange, x, y, z, sculptingDirection, TerrainDeformation.NO_TERRAIN_BRUSH)
		end
	else
		local sqrRadius = radius * radius
		local startRaster = math.floor(-radius / self.terrainUnit) * self.terrainUnit
		local endRaster = math.floor(radius / self.terrainUnit) * self.terrainUnit

		for rasterX = startRaster, endRaster, self.terrainUnit do
			local centerX = rasterX + self.halfTerrainUnit
			local areaStartZ = endRaster + self.terrainUnit
			local areaEndZ = startRaster - self.terrainUnit

			for rasterZ = startRaster, endRaster, self.terrainUnit do
				local centerZ = rasterZ + self.halfTerrainUnit
				local sqrRasterRadius = centerX * centerX + centerZ * centerZ

				if sqrRadius >= sqrRasterRadius then
					if rasterZ < areaStartZ then
						areaStartZ = centerZ
					end

					if areaEndZ < rasterZ then
						areaEndZ = centerZ
					end
				end
			end

			local length = areaEndZ - areaStartZ + self.terrainUnit
			local startX = x + centerX - self.terrainUnit
			local startY = y + heightChange * sculptingDirection
			local startZ = z + areaStartZ - self.terrainUnit

			if length > 0 then
				if not modificationAreaOnly then
					self:assignAxisAlignedArea(deform, startX, startY, startZ, self.terrainUnit, length, TerrainDeformation.NO_TERRAIN_BRUSH)
				end

				self:addAxisAlignedModifiedArea(startX, startZ, self.terrainUnit * 2, length + self.terrainUnit)
			end
		end
	end
end

function Landscaping:assignSmoothingParameters(deform, x, y, z, radius, strength, brushShape)
	deform:addCircle(x, z, radius)
	deform:setSmoothingAmount(strength)
	deform:enableSmoothingMode()
	self:assignCircleBrushArea(nil, radius, 0, x, y, z, 0, true)
end

function Landscaping:assignPaintingParameters(deform, x, y, z, radius, brushShape, layerIndex)
	if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		deform:addCircle(x, z, radius, layerIndex)
		self:assignCircleBrushArea(nil, radius, 0, x, y, z, 0, true)

		self.modifiedAreaSize = radius * radius * math.pi
	else
		local startX = x - radius + self.halfTerrainUnit
		local startY = y
		local startZ = z - radius + self.halfTerrainUnit
		local sideLength = radius * 2

		self:assignAxisAlignedArea(deform, startX, startY, startZ, sideLength, sideLength, layerIndex)
		self:addAxisAlignedModifiedArea(x - radius, z - radius, sideLength, sideLength)

		self.modifiedAreaSize = sideLength * sideLength
	end

	deform:enablePaintingMode()
end

function Landscaping:assignSculptingParameters(deform, x, y, z, radius, strength, brushShape, operation, smoothingDistance)
	local currentHeight = y

	if operation ~= Landscaping.OPERATION.FLATTEN then
		currentHeight = getTerrainHeightAtWorldPos(self.terrainRootNode, x, 0, z)
	end

	local heightChangeFactor = Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP[operation]

	if brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		self:assignSquareBrushArea(deform, radius * 2, strength, x, currentHeight, z, heightChangeFactor)
	else
		self:assignCircleBrushArea(deform, radius, strength, x, currentHeight, z, heightChangeFactor)
	end

	deform:setOutsideAreaConstraints(0, math.pi * 2, math.pi * 2)
	deform:enableDeformationMode()
end

function Landscaping:validateWaterLevel(positionY, strength, operation)
	if g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.water ~= nil then
		local heightChangeFactor = Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP[operation]
		local heightChange = strength * heightChangeFactor
		local _, waterLevel, _ = getWorldTranslation(g_currentMission.environment.water)

		return positionY > waterLevel and waterLevel < positionY + heightChange
	else
		return true
	end
end

function Landscaping:sculpt(x, y, z, radius, strength, brushShape, operation, smoothingDistance, terrainPaintingLayer)
	if self:validateWaterLevel(y, strength, operation) then
		self.isTerrainDeformationPending = true
		local deform = TerrainDeformation:new(self.terrainRootNode)
		self.currentTerrainDeformation = deform
		self.targetPosition = {
			x,
			y,
			z
		}
		self.radius = radius
		self.brushShape = brushShape
		self.smoothingDistance = math.max(smoothingDistance, self.terrainUnit)
		self.sculptingOperation = operation

		if operation == Landscaping.OPERATION.SMOOTH then
			self:assignSmoothingParameters(deform, x, y, z, radius, strength, brushShape)
		elseif operation == Landscaping.OPERATION.PAINT then
			self:assignPaintingParameters(deform, x, y, z, radius, brushShape, terrainPaintingLayer)
		else
			self:assignSculptingParameters(deform, x, y, z, radius, strength, brushShape, operation, self.smoothingDistance)
		end

		if operation ~= Landscaping.OPERATION.PAINT then
			deform:setBlockedAreaMaxDisplacement(0.001)
			deform:setDynamicObjectCollisionMask(RaycastUtil.MASK_TERRAIN)
			deform:setDynamicObjectMaxDisplacement(0.03)

			if self.placementCollisionMap ~= nil then
				deform:setBlockedAreaMap(self.placementCollisionMap, 0)
			end
		end

		if (operation == Landscaping.OPERATION.SMOOTH or operation == Landscaping.OPERATION.PAINT) and not self.validateOnly then
			deform:apply(true, "onSculptingValidated", self)

			if operation == Landscaping.OPERATION.PAINT then
				local paintTerrainFoliageId = g_groundTypeManager:getPaintableFoliageIdByTerrainLayer(terrainPaintingLayer)

				g_foliagePainter:apply(self.modifiedAreas, paintTerrainFoliageId)
			end
		else
			self.terrainDeformationQueue:queueJob(deform, true, "onSculptingValidated", self)
		end
	else
		self:onSculptingApplied(TerrainDeformation.STATE_FAILED_BLOCKED, 0)
	end
end

function Landscaping:onSculptingValidated(errorCode, displacedVolumeOrArea, blocked)
	if errorCode == TerrainDeformation.STATE_SUCCESS then
		local additionalChecksPassed = true
		local updatedErrorCode = errorCode

		if self.playerFarm:getBalance() < self:getCost(displacedVolumeOrArea) then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY
			additionalChecksPassed = false
		end

		local ownsTargetLand = Landscaping.isModificationAreaOnOwnedLand(self.targetPosition[1], self.targetPosition[3], self.radius, self.smoothingDistance, self.farmlandManager, self.playerFarm.farmId)

		if not ownsTargetLand then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_OWNED
			additionalChecksPassed = false
		end

		if self.sculptingOperation ~= Landscaping.OPERATION.PAINT then
			local dynamicObjectBlocking = self:hasObjectOverlapInModificationArea(unpack(self.targetPosition))

			if dynamicObjectBlocking then
				updatedErrorCode = TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT
				additionalChecksPassed = false
			end
		end

		if additionalChecksPassed and not self.validateOnly then
			self.terrainDeformationQueue:queueJob(self.currentTerrainDeformation, false, "onSculptingApplied", self)
		else
			self:onSculptingApplied(updatedErrorCode, displacedVolumeOrArea, nil)
		end
	else
		self.currentTerrainDeformation:cancel()
		self:onSculptingApplied(errorCode, 0, nil)
	end
end

function Landscaping:onSculptingApplied(errorCode, displacedVolumeOrArea, _)
	if errorCode == TerrainDeformation.STATE_SUCCESS and not self.validateOnly then
		local cost = self:getCost(displacedVolumeOrArea)

		self.playerFarm:changeBalance(-cost, MoneyType.SHOP_PROPERTY_BUY)

		for _, area in pairs(self.modifiedAreas) do
			local x, z, x1, z1, x2, z2 = unpack(area)

			FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2)
			FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
			FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
			DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
		end
	end

	if self.callbackFunctionTarget ~= nil then
		self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)
	else
		self.callbackFunction(errorCode, displacedVolumeOrArea)
	end

	self.currentTerrainDeformation = nil
end

function Landscaping:getCost(displacedVolumeOrArea)
	local cost = 0

	if self.sculptingOperation == Landscaping.OPERATION.PAINT then
		cost = math.floor(displacedVolumeOrArea * Landscaping.PAINT_BASE_COST_PER_M2)
	else
		cost = math.floor(displacedVolumeOrArea * Landscaping.SCULPT_BASE_COST_PER_M3)
	end

	return cost
end

function Landscaping.isModificationAreaOnOwnedLand(x, z, radius, smoothingDistance, farmlandManager, farmId)
	local halfSize = radius + smoothingDistance

	return farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z + halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z + halfSize)
end
