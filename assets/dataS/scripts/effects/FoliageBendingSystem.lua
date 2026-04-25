FoliageBendingSystem = {}
local FoliageBendingSystem_mt = Class(FoliageBendingSystem)
FoliageBendingSystem.maxNumObjects = 64

function FoliageBendingSystem:new(customMt)
	local self = setmetatable({}, customMt or FoliageBendingSystem_mt)
	self.systemId = createFoliageBendingSystem(FoliageBendingSystem.maxNumObjects, 32)

	return self
end

function FoliageBendingSystem:delete()
	if self.systemId ~= 0 then
		delete(self.systemId)
	end
end

function FoliageBendingSystem:setTerrainTransformGroup(terrainTransformGroup)
	setFoliageBendingSystem(terrainTransformGroup, self.systemId)
end

function FoliageBendingSystem:createRectangle(minX, maxX, minZ, maxZ, yOffset, parentTransformGroup)
	return createFoliageBendingRectangle(self.systemId, minX, maxX, minZ, maxZ, yOffset, parentTransformGroup)
end

function FoliageBendingSystem:destroyObject(id)
	destroyFoliageBendingObject(self.systemId, id)
end

function FoliageBendingSystem:getRectangleAttributes(id)
	return getFoliageBendingRectangleAttributes(self.systemId, id)
end

function FoliageBendingSystem:setRectangleAttributes(id, minX, maxX, minZ, maxZ, yOffset)
	local curMinX, curMaxX, curMinZ, curMaxZ, curYOffset = getFoliageBendingRectangleAttributes(self.systemId, id)
	minX = minX or curMinX
	maxX = maxX or curMaxX
	minZ = minZ or curMinZ
	maxZ = maxZ or curMaxZ
	yOffset = yOffset or curYOffset

	return setFoliageBendingRectangleAttributes(self.systemId, id, minX, maxX, minZ, maxZ, yOffset)
end
