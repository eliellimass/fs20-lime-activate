TerrainDeformation = {}
local TerrainDeformation_mt = Class(TerrainDeformation)
TerrainDeformation.STATE_SUCCESS = 0
TerrainDeformation.STATE_FAILED_BLOCKED = 1
TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT = 2
TerrainDeformation.STATE_FAILED_TO_DEFORM = 3
TerrainDeformation.STATE_CANCELLED = 4
TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY = 5
TerrainDeformation.STATE_FAILED_NOT_OWNED = 6
TerrainDeformation.STATE_SEND_NUM_BITS = 3
TerrainDeformation.LAYER_SEND_NUM_BITS = 8
TerrainDeformation.NO_TERRAIN_BRUSH = -1

function TerrainDeformation:new(terrainNode)
	local self = {}

	setmetatable(self, TerrainDeformation_mt)

	self.terrainDeformationId = createTerrainDeformation(terrainNode)
	self.terrainNode = terrainNode

	return self
end

function TerrainDeformation:enableDeformationMode()
	enableTerrainDeformationMode(self.terrainDeformationId)
end

function TerrainDeformation:enableSmoothingMode()
	enableTerrainDeformationSmoothingMode(self.terrainDeformationId)
end

function TerrainDeformation:enablePaintingMode()
	enableTerrainDeformationPaintingMode(self.terrainDeformationId)
end

function TerrainDeformation:clearAreas()
	clearTerrainDeformationAreas(self.terrainDeformationId)
end

function TerrainDeformation:addArea(x, y, z, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId, writeBlockedAreaMap)
	addTerrainDeformationArea(self.terrainDeformationId, x, y, z, side1X, side1Y, side1Z, side2X, side2Y, side2Z, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH, writeBlockedAreaMap)
end

function TerrainDeformation:addCircle(x, y, r, terrainBrushId)
	addTerrainDeformationCircle(self.terrainDeformationId, x, y, r, terrainBrushId or TerrainDeformation.NO_TERRAIN_BRUSH)
end

function TerrainDeformation:setOutsideAreaBrush(brushId)
	setTerrainDeformationOutsideAreaBrush(self.terrainDeformationId, brushId or TerrainDeformation.NO_TERRAIN_BRUSH)
end

function TerrainDeformation:setOutsideAreaConstraints(maxSmoothDistance, maxSlope, maxEdgeAngle)
	setTerrainDeformationOutsideAreaConstraints(self.terrainDeformationId, maxSmoothDistance, maxSlope, maxEdgeAngle)
end

function TerrainDeformation:setSmoothingAmount(amount)
	setTerrainDeformationSmoothingAmount(self.terrainDeformationId, amount)
end

function TerrainDeformation:getBlockedAreaMapSize()
	return getTerrainDeformationBlockedAreaMapSize(self.terrainDeformationId)
end

function TerrainDeformation:setDynamicObjectCollisionMask(collisionMask)
	setTerrainDeformationDynamicObjectCollisionMask(self.terrainDeformationId, collisionMask)
end

function TerrainDeformation:setDynamicObjectMaxDisplacement(maxDisplacement)
	setTerrainDeformationDynamicObjectMaxDisplacement(self.terrainDeformationId, maxDisplacement)
end

function TerrainDeformation:setBlockedAreaMap(bitVectorMapId, channel)
	setTerrainDeformationBlockedAreaMap(self.terrainDeformationId, bitVectorMapId, channel)
end

function TerrainDeformation:setBlockedAreaMaxDisplacement(maxDisplacement)
	setTerrainDeformationBlockedAreaMaxDisplacement(self.terrainDeformationId, maxDisplacement)
end

function TerrainDeformation:apply(previewOnly, callbackFunc, callbackObject)
	applyTerrainDeformation(self.terrainDeformationId, previewOnly, callbackFunc, callbackObject)
end

function TerrainDeformation:cancel()
	cancelTerrainDeformation(self.terrainDeformationId)
end

function TerrainDeformation:blockAreas()
	writeTerrainDeformationBlockedAreas(self.terrainDeformationId, 1)
end

function TerrainDeformation:unblockAreas()
	writeTerrainDeformationBlockedAreas(self.terrainDeformationId, 0)
end
