DebugCube = {}
local DebugCube_mt = Class(DebugCube)

function DebugCube:new(customMt)
	local self = setmetatable({}, customMt or DebugCube_mt)
	self.color = {
		1,
		1,
		1
	}
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
	self.positionNodes = {
		{
			-1,
			-1,
			-1
		},
		{
			1,
			-1,
			-1
		},
		{
			1,
			-1,
			1
		},
		{
			-1,
			-1,
			1
		},
		{
			-1,
			1,
			-1
		},
		{
			1,
			1,
			-1
		},
		{
			1,
			1,
			1
		},
		{
			-1,
			1,
			1
		}
	}

	return self
end

function DebugCube:delete()
end

function DebugCube:update(dt)
end

function DebugCube:draw()
	local r, g, b = unpack(self.color)
	local pos = self.positionNodes

	drawDebugLine(pos[1][1], pos[1][2], pos[1][3], r, g, b, pos[2][1], pos[2][2], pos[2][3], r, g, b)
	drawDebugLine(pos[2][1], pos[2][2], pos[2][3], r, g, b, pos[3][1], pos[3][2], pos[3][3], r, g, b)
	drawDebugLine(pos[3][1], pos[3][2], pos[3][3], r, g, b, pos[4][1], pos[4][2], pos[4][3], r, g, b)
	drawDebugLine(pos[4][1], pos[4][2], pos[4][3], r, g, b, pos[1][1], pos[1][2], pos[1][3], r, g, b)
	drawDebugLine(pos[5][1], pos[5][2], pos[5][3], r, g, b, pos[6][1], pos[6][2], pos[6][3], r, g, b)
	drawDebugLine(pos[6][1], pos[6][2], pos[6][3], r, g, b, pos[7][1], pos[7][2], pos[7][3], r, g, b)
	drawDebugLine(pos[7][1], pos[7][2], pos[7][3], r, g, b, pos[8][1], pos[8][2], pos[8][3], r, g, b)
	drawDebugLine(pos[8][1], pos[8][2], pos[8][3], r, g, b, pos[5][1], pos[5][2], pos[5][3], r, g, b)
	drawDebugLine(pos[1][1], pos[1][2], pos[1][3], r, g, b, pos[5][1], pos[5][2], pos[5][3], r, g, b)
	drawDebugLine(pos[2][1], pos[2][2], pos[2][3], r, g, b, pos[6][1], pos[6][2], pos[6][3], r, g, b)
	drawDebugLine(pos[3][1], pos[3][2], pos[3][3], r, g, b, pos[7][1], pos[7][2], pos[7][3], r, g, b)
	drawDebugLine(pos[4][1], pos[4][2], pos[4][3], r, g, b, pos[8][1], pos[8][2], pos[8][3], r, g, b)

	local x = self.x
	local y = self.y
	local z = self.z
	local sideX = self.normX
	local sideY = self.normY
	local sideZ = self.normZ
	local upX = self.upX
	local upY = self.upY
	local upZ = self.upZ
	local dirX = self.dirX
	local dirY = self.dirY
	local dirZ = self.dirZ

	drawDebugLine(x, y, z, 1, 0, 0, x + sideX, y + sideY, z + sideZ, 1, 0, 0)
	drawDebugLine(x, y, z, 0, 1, 0, x + upX, y + upY, z + upZ, 0, 1, 0)
	drawDebugLine(x, y, z, 0, 0, 1, x + dirX, y + dirY, z + dirZ, 0, 0, 1)
end

function DebugCube:setColor(r, g, b)
	self.color = {
		r,
		g,
		b
	}
end

function DebugCube:createSimple(x, y, z, size)
	self:createWithWorldPosAndRot(x, y, z, 0, 0, 0, size, size, size)
end

function DebugCube:createWithPlacementSize(node, sizeWidth, sizeLength, widthOffset, lengthOffset, updatePosition)
	local rotX, rotY, rotZ = getWorldRotation(node)
	local x, y, z = localToWorld(node, widthOffset, 0, lengthOffset)

	self:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, sizeWidth * 0.5, 1, sizeLength * 0.5)
end

function DebugCube:createWithNode(node, sizeX, sizeY, sizeZ)
	local x, y, z = getWorldTranslation(node)
	local normX, normY, normZ = localDirectionToWorld(node, 1, 0, 0)
	local upX, upY, upZ = localDirectionToWorld(node, 0, 1, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, 0, 1)
	self.z = z
	self.y = y
	self.x = x
	self.normZ = normZ * sizeX
	self.normY = normY * sizeX
	self.normX = normX * sizeX
	self.upZ = upZ * sizeY
	self.upY = upY * sizeY
	self.upX = upX * sizeY
	self.dirZ = dirZ * sizeZ
	self.dirY = dirY * sizeZ
	self.dirX = dirX * sizeZ
	local pos = self.positionNodes
	pos[1] = {
		x - self.normX - self.upX - self.dirX,
		y - self.normY - self.upY - self.dirY,
		z - self.normZ - self.upZ - self.dirZ
	}
	pos[2] = {
		x + self.normX - self.upX - self.dirX,
		y + self.normY - self.upY - self.dirY,
		z + self.normZ - self.upZ - self.dirZ
	}
	pos[3] = {
		x + self.normX - self.upX + self.dirX,
		y + self.normY - self.upY + self.dirY,
		z + self.normZ - self.upZ + self.dirZ
	}
	pos[4] = {
		x - self.normX - self.upX + self.dirX,
		y - self.normY - self.upY + self.dirY,
		z - self.normZ - self.upZ + self.dirZ
	}
	pos[5] = {
		x - self.normX + self.upX - self.dirX,
		y - self.normY + self.upY - self.dirY,
		z - self.normZ + self.upZ - self.dirZ
	}
	pos[6] = {
		x + self.normX + self.upX - self.dirX,
		y + self.normY + self.upY - self.dirY,
		z + self.normZ + self.upZ - self.dirZ
	}
	pos[7] = {
		x + self.normX + self.upX + self.dirX,
		y + self.normY + self.upY + self.dirY,
		z + self.normZ + self.upZ + self.dirZ
	}
	pos[8] = {
		x - self.normX + self.upX + self.dirX,
		y - self.normY + self.upY + self.dirY,
		z - self.normZ + self.upZ + self.dirZ
	}
end

function DebugCube:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ)
	local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")

	link(getRootNode(), temp)
	setTranslation(temp, x, y, z)
	setDirection(temp, dirX, dirY, dirZ, upX, upY, upZ)
	self:createWithNode(temp, sizeX, sizeY, sizeZ)
	delete(temp)
end

function DebugCube:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, sizeX, sizeY, sizeZ)
	local temp = createTransformGroup("temp_drawDebugCubeAtWorldPos")

	link(getRootNode(), temp)
	setTranslation(temp, x, y, z)
	setRotation(temp, rotX, rotY, rotZ)
	self:createWithNode(temp, sizeX, sizeY, sizeZ)
	delete(temp)
end
