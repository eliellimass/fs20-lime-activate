DebugGizmo = {}
local DebugGizmo_mt = Class(DebugGizmo)

function DebugGizmo:new(customMt)
	local self = setmetatable({}, customMt or DebugGizmo_mt)
	self.z = 0
	self.y = 0
	self.x = 0
	self.normZ = 0
	self.normY = 0
	self.normX = 1
	self.upZ = 0
	self.upY = 1
	self.upX = 0
	self.dirZ = 1
	self.dirY = 0
	self.dirX = 0
	self.text = nil
	self.alignToGround = false

	return self
end

function DebugGizmo:delete()
end

function DebugGizmo:update(dt)
end

function DebugGizmo:draw()
	local x = self.x
	local y = self.y
	local z = self.z
	local normX = self.normX
	local normY = self.normY
	local normZ = self.normZ
	local upX = self.upX
	local upY = self.upY
	local upZ = self.upZ
	local dirX = self.dirX
	local dirY = self.dirY
	local dirZ = self.dirZ

	drawDebugLine(x, y, z, 1, 0, 0, x + normX, y + normY, z + normZ, 1, 0, 0)
	drawDebugLine(x, y, z, 0, 1, 0, x + upX, y + upY, z + upZ, 0, 1, 0)
	drawDebugLine(x, y, z, 0, 0, 1, x + dirX, y + dirY, z + dirZ, 0, 0, 1)

	if self.text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, tostring(self.text), getCorrectTextSize(0.012), 0)
	end
end

function DebugGizmo:createWithNode(node, text, alignToGround)
	local x, y, z = getWorldTranslation(node)
	local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)

	self:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround)
end

function DebugGizmo:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround)
	if alignToGround and g_currentMission.terrainRootNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.1
	end

	self.z = z
	self.y = y
	self.x = x
	self.dirZ = dirZ
	self.dirY = dirY
	self.dirX = dirX
	self.upZ = upZ
	self.upY = upY
	self.upX = upX
	self.normX, self.normY, self.normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	self.text = text
	self.alignToGround = alignToGround
end
