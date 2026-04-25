LightWildlifeStateDefault = {}
local LightWildlifeStateDefault_mt = Class(LightWildlifeStateDefault, SimpleState)

function LightWildlifeStateDefault:new(id, owner, stateMachine, custom_mt)
	local self = SimpleState:new(id, owner, stateMachine, LightWildlifeStateDefault_mt)

	return self
end

LightWildlife = {}
local LightWildlife_mt = Class(LightWildlife)

InitStaticObjectClass(LightWildlife, "LightWildlife", ObjectIds.OBJECT_ANIMAL_LIGHT_WILDLIFE)

function LightWildlife:new(customMt)
	local self = {}
	local mt = customMt

	if mt == nil then
		mt = LightWildlife_mt
	end

	setmetatable(self, mt)

	self.type = ""
	self.i3dFilename = ""
	self.animals = {}
	self.animalStates = {}
	local defaultState = {
		id = "default",
		class = LightWildlifeStateDefault
	}

	table.insert(self.animalStates, defaultState)

	self.soundsNode = createTransformGroup("lightWildlifeSounds")

	return self
end

function LightWildlife:load(xmlFilename)
	self.xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = loadXMLFile("TempXML", self.xmlFilename)

	if xmlFile == 0 then
		self.xmlFilename = nil

		return false
	end

	local key = "wildlifeAnimal"

	if hasXMLProperty(xmlFile, key) then
		self.type = getXMLString(xmlFile, key .. "#type")
		self.randomSpawnRadius = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#randomSpawnRadius"), 0)
		self.i3dFilename = getXMLString(xmlFile, key .. ".asset#filename")
		self.shaderNodeString = getXMLString(xmlFile, key .. ".animations#shaderNode")
		self.shaderParmId = getXMLString(xmlFile, key .. ".animations#shaderParameterId")
		self.shaderParmOpcode = getXMLString(xmlFile, key .. ".animations#shaderParameterOpcode")
		self.shaderParmSpeed = getXMLString(xmlFile, key .. ".animations#shaderParameterSpeed")
		self.animations = {
			default = {
				speed = 0,
				name = "default",
				transitionTimer = 0,
				opcode = 0
			}
		}
		local i = 0

		while true do
			local animkey = string.format(key .. ".animations.animation(%d)", i)

			if not hasXMLProperty(xmlFile, animkey) then
				break
			end

			local state = Utils.getNoNil(getXMLString(xmlFile, animkey .. "#conditionState"), "")
			local animation = {
				opcode = Utils.getNoNil(getXMLInt(xmlFile, animkey .. "#opcode"), 0),
				speed = Utils.getNoNil(getXMLFloat(xmlFile, animkey .. "#speed"), 0),
				transitionTimer = Utils.getNoNil(getXMLFloat(xmlFile, animkey .. "#transitionTimer"), 1) * 1000
			}
			self.animations[state] = animation
			i = i + 1
		end

		if self.type ~= nil and self.i3dFilename ~= nil then
			delete(xmlFile)

			return true
		end
	end

	delete(xmlFile)

	return false
end

function LightWildlife:createAnimals(name, spawnPosX, spawnPosY, spawnPosZ, nbAnimals)
	if #self.animals == 0 then
		for i = 1, nbAnimals do
			local nodeId = g_i3DManager:loadSharedI3DFile(self.i3dFilename, self.baseDirectory, false, false, false)

			link(getRootNode(), nodeId)

			local shaderNode = I3DUtil.indexToObject(nodeId, self.shaderNodeString)
			local animal = LightWildlifeAnimal:new(self, i, nodeId, shaderNode)

			animal:init(spawnPosX, spawnPosZ, self.randomSpawnRadius, self.animalStates)
			table.insert(self.animals, animal)
		end

		setWorldTranslation(self.soundsNode, spawnPosX, spawnPosY, spawnPosZ)

		return 1
	end

	return 0
end

function LightWildlife:delete()
	delete(self.soundsNode)
	self:removeAllAnimals()
end

function LightWildlife:removeAllAnimals()
	for _, animal in pairs(self.animals) do
		g_i3DManager:releaseSharedI3DFile(self.i3dFilename, self.baseDirectory, true)
		delete(animal.i3dNodeId)
	end

	self.animals = {}
end

function LightWildlife:update(dt)
	for _, animal in pairs(self.animals) do
		animal:update(dt)
		animal:updateAnimation(dt)
	end
end

function LightWildlife:removeFarAwayAnimals(maxDistance, refPosX, refPosY, refPosZ)
	local removeCount = 0

	for i = #self.animals, 1, -1 do
		local x, y, z = getWorldTranslation(self.animals[i].i3dNodeId)
		local deltaX = refPosX - x
		local deltaY = refPosY - y
		local deltaZ = refPosZ - z
		local distSq = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

		if distSq > maxDistance * maxDistance then
			g_i3DManager:releaseSharedI3DFile(self.i3dFilename, self.baseDirectory, false)
			delete(self.animals[i].i3dNodeId)
			table.remove(self.animals, i)

			removeCount = removeCount + 1
		end
	end

	return removeCount
end

function LightWildlife:getClosestDistance(refPosX, refPosY, refPosZ)
	local closestDistSq = nil

	for _, animal in pairs(self.animals) do
		local x, y, z = getWorldTranslation(animal.i3dNodeId)
		local deltaX = refPosX - x
		local deltaY = refPosY - y
		local deltaZ = refPosZ - z
		local distSq = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

		if closestDistSq == nil or closestDistSq ~= nil and distSq < closestDistSq then
			closestDistSq = distSq
		end
	end

	if closestDistSq == nil then
		closestDistSq = 0
	end

	return closestDistSq
end

function LightWildlife:countSpawned()
	return #self.animals
end

function LightWildlife:getIsInWater(x, y, z)
	local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

	return terrainHeight <= g_currentMission.waterY
end

function LightWildlife:getTerrainHeightWithProps(x, z)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	local offset = 5
	local distance = 5
	local collisionMask = 63
	self.groundY = -1

	raycastClosest(x, terrainY + offset, z, 0, -1, 0, "groundRaycastCallback", 5, self, collisionMask)

	return math.max(terrainY, self.groundY)
end

function LightWildlife:groundRaycastCallback(hitObjectId, x, y, z, distance)
	if hitObjectId ~= nil then
		local objectType = getRigidBodyType(hitObjectId)

		if objectType ~= "Dynamic" and objectType ~= "Kinematic" then
			self.groundY = y

			return false
		end
	end

	return true
end
