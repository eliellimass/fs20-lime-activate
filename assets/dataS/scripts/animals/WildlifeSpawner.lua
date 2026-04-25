WildlifeSpawner = {}
local WildlifeSpawner_mt = Class(WildlifeSpawner)
WildlifeSpawner.DEBUGSHOWIDSTATES = {
	ALL = 2,
	SINGLE = 3,
	MAX = 3,
	NONE = 1
}

function WildlifeSpawner:new(customMt)
	local mt = customMt

	if mt == nil then
		mt = WildlifeSpawner_mt
	end

	local self = {}

	setmetatable(self, mt)

	self.collisionDetectionMask = 4096
	self.maxCost = 0
	self.checkTimeInterval = 0
	self.nextCheckTime = 0
	self.areas = {}
	self.areasOfInterest = {}
	self.totalCost = 0
	self.treeCount = 0
	self.debugAnimalList = {}
	self.debugShow = false
	self.debugShowId = WildlifeSpawner.DEBUGSHOWIDSTATES.NONE
	self.debugShowSteering = false
	self.debugShowAnimation = false

	addConsoleCommand("gsToggleShowWildlife", "Toggle shows/hide all wildlife debug information.", "consoleCommandToggleShowWildlife", self)
	addConsoleCommand("gsToggleShowWildlifeId", "Toggle shows/hide all wildlife animal id.", "consoleCommandToggleShowWildlifeId", self)
	addConsoleCommand("gsToggleShowWildlifeSteering", "Toggle shows/hide animal steering information.", "consoleCommandToggleShowWildlifeSteering", self)
	addConsoleCommand("gsToggleShowWildlifeAnimation", "Toggle shows/hide animal animation information.", "consoleCommandToggleShowWildlifeAnimation", self)
	addConsoleCommand("gsAddWildlifeAnimalToDebug", "Adds an animal to a debug list.", "consoleCommandAddWildlifeAnimalToDebug", self)
	addConsoleCommand("gsRemoveWildlifeAnimalToDebug", "Removes an animal to a debug list.", "consoleCommandRemoveWildlifeAnimalToDebug", self)

	return self
end

function WildlifeSpawner:delete()
	self:removeAllAnimals()
	removeConsoleCommand("gsToggleShowWildlife")
	removeConsoleCommand("gsToggleShowWildlifeId")
	removeConsoleCommand("gsToggleShowWildlifeSteering")
	removeConsoleCommand("gsToggleShowWildlifeAnimation")
	removeConsoleCommand("gsAddWildlifeAnimalToDebug")
	removeConsoleCommand("gsRemoveWildlifeAnimalToDebug")
end

function WildlifeSpawner:onConnectionClosed()
	self:removeAllAnimals()
end

function WildlifeSpawner:removeAllAnimals()
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			for i = #species.spawned, 1, -1 do
				if species.classType == "companionAnimal" then
					local spawn = species.spawned[i]

					if spawn.spawnId ~= nil then
						delete(spawn.spawnId)

						spawn.spawnId = nil
					end
				elseif species.classType == "lightWildlife" and species.lightWildlife ~= nil then
					species.lightWildlife:removeAllAnimals()
				end

				table.remove(species.spawned, i)
			end
		end
	end

	self.totalCost = 0
end

function WildlifeSpawner:loadMapData(xmlFile)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.wildlife#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load wildlife config file '" .. tostring(filename) .. "'!")

		return false
	end

	local wildlifeXmlFile = loadXMLFile("wildlife", filename)

	if wildlifeXmlFile ~= nil then
		self.maxCost = Utils.getNoNil(getXMLInt(wildlifeXmlFile, "wildlifeSpawner#maxCost"), 0)
		self.checkTimeInterval = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#checkTimeInterval"), 1) * 1000
		self.maxAreaOfInterest = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#maxAreaOfInterest"), 1)
		self.areaOfInterestliveTime = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, "wildlifeSpawner#areaOfInterestliveTime"), 1) * 1000
		self.bypassRules = Utils.getNoNil(getXMLBool(wildlifeXmlFile, "wildlifeSpawner#bypassRules"), false)
		local i = 0

		while true do
			local areaBaseString = string.format("wildlifeSpawner.area(%d)", i)

			if not hasXMLProperty(wildlifeXmlFile, areaBaseString) then
				break
			end

			local newArea = {
				areaSpawnRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#areaSpawnRadius"), 1),
				areaMaxRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#areaMaxRadius"), 1),
				spawnCircleRadius = Utils.getNoNil(getXMLFloat(wildlifeXmlFile, areaBaseString .. "#spawnCircleRadius"), 1),
				species = {}
			}
			local j = 0

			while true do
				local speciesBaseString = string.format("%s.species(%d)", areaBaseString, j)

				if not hasXMLProperty(wildlifeXmlFile, speciesBaseString) then
					break
				end

				local classTypeString = getXMLString(wildlifeXmlFile, speciesBaseString .. "#classType")
				local classType = nil

				if classTypeString ~= nil then
					if string.lower(classTypeString) == "companionanimal" then
						classType = "companionAnimal"
					elseif string.lower(classTypeString) == "lightwildlife" then
						classType = "lightWildlife"
					end
				end

				if classType ~= nil then
					local newSpecies = {
						classType = classType,
						name = getXMLString(wildlifeXmlFile, speciesBaseString .. "#name"),
						configFilename = getXMLString(wildlifeXmlFile, speciesBaseString .. "#config"),
						spawnRule = {}
					}
					newSpecies.spawnRule.hours = self:parseHours(getXMLString(wildlifeXmlFile, speciesBaseString .. ".spawnRules#hours"))
					newSpecies.spawnRule.onField = getXMLBool(wildlifeXmlFile, speciesBaseString .. ".spawnRules#onField")
					newSpecies.spawnRule.hasTrees = getXMLBool(wildlifeXmlFile, speciesBaseString .. ".spawnRules#hasTrees")
					newSpecies.spawnRule.inWater = getXMLBool(wildlifeXmlFile, speciesBaseString .. ".spawnRules#inWater")
					newSpecies.cost = getXMLFloat(wildlifeXmlFile, speciesBaseString .. ".cost")
					newSpecies.minCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".minCount")
					newSpecies.maxCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".maxCount")
					newSpecies.currentCount = 0
					newSpecies.spawnCount = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".spawnCount")
					newSpecies.groupSpawnRadius = getXMLInt(wildlifeXmlFile, speciesBaseString .. ".groupSpawnRadius")
					newSpecies.spawned = {}
					newSpecies.lightWildlife = nil

					if classType == "lightWildlife" and newSpecies.name == "crow" then
						newSpecies.lightWildlife = CrowsWildlife:new()

						newSpecies.lightWildlife:load(Utils.getNoNil(getXMLString(wildlifeXmlFile, speciesBaseString .. "#config"), ""))
					end

					table.insert(newArea.species, newSpecies)
				end

				j = j + 1
			end

			table.insert(self.areas, newArea)

			i = i + 1
		end

		delete(wildlifeXmlFile)

		return true
	end

	return false
end

function WildlifeSpawner:unloadMapData()
	self:removeAllAnimals()

	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.lightWildlife ~= nil then
				species.lightWildlife:delete()
			end
		end
	end

	self.areas = {}
end

function WildlifeSpawner:parseHours(input)
	local hoursResult = {}

	if input ~= nil then
		input = input:gsub("[^-,0-9]", "")
		local hourRangesStrings = StringUtil.splitString(",", input)
		local num = table.getn(hourRangesStrings)

		for i = 1, num do
			local hourFromStartString = StringUtil.splitString("-", hourRangesStrings[i])
			local num2 = table.getn(hourFromStartString)
			local fromVal = 0
			local toVal = 0

			if num2 == 1 then
				fromVal = tonumber(hourFromStartString[1])
				toVal = tonumber(hourFromStartString[1])
			elseif num2 == 2 then
				fromVal = tonumber(hourFromStartString[1])
				toVal = tonumber(hourFromStartString[2])
			end

			if (num2 == 1 or num2 == 2) and fromVal <= toVal and fromVal >= 0 and fromVal <= 24 and toVal >= 0 and toVal <= 24 then
				table.insert(hoursResult, {
					from = fromVal,
					to = toVal
				})
			end
		end
	end

	return hoursResult
end

function WildlifeSpawner:onGhostRemove()
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId ~= nil then
						setCompanionsVisibility(spawn.spawnId, false)
						setCompanionsPhysicsUpdate(spawn.spawnId, false)
					end
				end
			end
		end
	end
end

function WildlifeSpawner:onGhostAdd()
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId ~= nil then
						setCompanionsVisibility(spawn.spawnId, true)
						setCompanionsPhysicsUpdate(spawn.spawnId, true)
					end
				end
			end
		end
	end
end

function WildlifeSpawner:update(dt)
	self:updateAreaOfInterest(dt)

	self.nextCheckTime = self.nextCheckTime - dt

	if self.nextCheckTime < 0 then
		self.nextCheckTime = self.checkTimeInterval

		self:updateSpawner()
	end

	self:removeFarAwayAnimals()

	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId ~= nil then
						setCompanionDaytime(spawn.spawnId, g_currentMission.environment.dayTime)
					end
				end
			elseif species.classType == "lightWildlife" then
				species.lightWildlife:update(dt)
			end
		end
	end

	if self.debugShow then
		self:debugDraw()
	end
end

function WildlifeSpawner:removeFarAwayAnimals()
	local passedTest, originX, originY, originZ = self:getPlayerCenter()

	if passedTest then
		for _, area in pairs(self.areas) do
			for _, species in pairs(area.species) do
				if species.classType == "companionAnimal" then
					for i = #species.spawned, 1, -1 do
						local spawn = species.spawned[i]

						if spawn.spawnId ~= nil then
							local distance, _ = getCompanionClosestDistance(spawn.spawnId, originX, originY, originZ)

							if area.areaMaxRadius < distance then
								delete(spawn.spawnId)

								spawn.spawnId = nil
								species.currentCount = species.currentCount - spawn.count
								self.totalCost = self.totalCost - species.cost * spawn.count

								table.remove(species.spawned, i)
							end
						end
					end
				elseif species.classType == "lightWildlife" and species.lightWildlife ~= nil then
					local removedAnimalsCount = species.lightWildlife:removeFarAwayAnimals(area.areaMaxRadius, originX, originY, originZ)

					if removedAnimalsCount > 0 then
						species.currentCount = species.currentCount - removedAnimalsCount
						self.totalCost = self.totalCost - species.cost * removedAnimalsCount

						for i = #species.spawned, 1, -1 do
							if species.lightWildlife:countSpawned() == 0 then
								table.remove(species.spawned, i)
							end
						end
					end
				end
			end
		end
	end
end

function WildlifeSpawner:getPlayerCenter()
	if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
		local x, y, z = getWorldTranslation(g_currentMission.player.rootNode)

		return true, x, y, z
	elseif g_currentMission.controlledVehicle ~= nil then
		local x, y, z = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)

		return true, x, y, z
	end

	return false, 0, 0, 0
end

function WildlifeSpawner:updateSpawner()
	local passedTest, x, y, z = self:getPlayerCenter()

	if passedTest then
		self:checkAreas(x, y, z)
	end
end

function WildlifeSpawner:trySpawnAtArea(species, spawnCircleRadius, testX, testY, testZ)
	for _, animalType in pairs(species) do
		if self:checkArea(testX, testY, testZ, animalType.spawnRule, spawnCircleRadius) then
			local spawnPosX = testX + math.random() * spawnCircleRadius
			local spawnPosZ = testZ + math.random() * spawnCircleRadius
			local spawnPosY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, spawnPosX, 0, spawnPosZ) + 0.5

			if self:spawnAnimals(animalType, spawnPosX, spawnPosY, spawnPosZ) then
				return true
			end
		end
	end

	return false
end

function WildlifeSpawner:checkAreas(x, y, z)
	local testX = x
	local testZ = z
	local testY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, testX, 0, testZ) + 0.5

	for _, area in pairs(self.areas) do
		local hasSpawned = false

		for _, interestArea in pairs(self.areasOfInterest) do
			local distSq = (testX - interestArea.positionX) * (testX - interestArea.positionX) + (testZ - interestArea.positionZ) * (testZ - interestArea.positionZ)

			if distSq < area.areaSpawnRadius * area.areaSpawnRadius then
				hasSpawned = self:trySpawnAtArea(area.species, interestArea.radius, testX, testY, testZ)

				if hasSpawned then
					break
				end
			end
		end

		if not hasSpawned then
			local angle = math.rad(math.random(0, 360))
			testX = x + area.areaSpawnRadius * math.cos(angle) - area.areaSpawnRadius * math.sin(angle)
			testZ = z + area.areaSpawnRadius * math.cos(angle) + area.areaSpawnRadius * math.sin(angle)
			testY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, testX, 0, testZ) + 0.5

			self:trySpawnAtArea(area.species, area.spawnCircleRadius, testX, testY, testZ)
		end
	end
end

function WildlifeSpawner:checkArea(x, y, z, rules, radius)
	local nbTrees = self:countTrees(x, y, z, radius)
	local isOnField = self:getIsOnField(x, y, z)
	local isInWater = self:getIsInWater(x, y, z)
	local hoursTest = self:checkHours(rules)
	local onFieldTest = rules.onField and isOnField or not rules.onField and not isOnField
	local hasTreesTest = rules.hasTrees and nbTrees > 0 or not rules.hasTrees and nbTrees == 0
	local inWaterTest = rules.inWater and isInWater or not rules.inWater and not isInWater

	if self.bypassRules or hoursTest and onFieldTest and hasTreesTest and inWaterTest then
		return true
	end

	return false
end

function WildlifeSpawner:countTrees(x, y, z, radius)
	self.treeCount = 0

	overlapSphere(x, y, z, radius, "treeCountTestCallback", self, 2, false, true, false)

	return self.treeCount
end

function WildlifeSpawner:treeCountTestCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local object = getParent(transformId)

		if object ~= nil and getSplitType(transformId) ~= 0 then
			self.treeCount = self.treeCount + 1
		end
	end

	return true
end

function WildlifeSpawner:getIsOnField(x, y, z)
	local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, y, z)

	return densityBits ~= 0
end

function WildlifeSpawner:getIsInWater(x, y, z)
	local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

	return terrainHeight <= g_currentMission.waterY
end

function WildlifeSpawner:checkHours(rules)
	local currentHour = math.floor(g_currentMission.environment.dayTime / 3600000)

	for _, hours in pairs(rules.hours) do
		if hours.from <= currentHour and currentHour <= hours.to then
			return true
		end
	end

	return false
end

function WildlifeSpawner:countAnimalsTobeSpawned(species)
	local remainingAnimal = math.floor((self.maxCost - self.totalCost) / species.cost)

	if remainingAnimal < species.minCount then
		return 0
	end

	local deltaNbAnimals = species.maxCount - species.minCount
	local nbAnimals = species.minCount + math.random(1, deltaNbAnimals)
	nbAnimals = math.min(remainingAnimal, nbAnimals)

	return nbAnimals
end

function WildlifeSpawner:spawnAnimals(species, spawnPosX, spawnPosY, spawnPosZ)
	local xmlFilename = Utils.getFilename(species.configFilename, g_currentMission.loadingMapBaseDirectory)

	if species.name == nil or xmlFilename == nil or g_currentMission.terrainRootNode == nil or species.maxCount <= species.currentCount then
		return false
	end

	local nbAnimals = self:countAnimalsTobeSpawned(species)

	if nbAnimals == 0 then
		return false
	end

	local id = nil

	if species.classType == "companionAnimal" then
		id = createAnimalCompanionManager(species.name, xmlFilename, "wildlifeAnimal", spawnPosX, spawnPosY, spawnPosZ, g_currentMission.terrainRootNode, g_currentMission:getIsServer(), g_currentMission:getIsClient(), nbAnimals)

		setCompanionWaterLevel(id, g_currentMission.waterY)

		for animalId = 0, nbAnimals - 1 do
			setCompanionCommonSteeringParameters(id, animalId, 0.5, 3, MathUtil.degToRad(20), 0.2)
			setCompanionWanderSteeringParameters(id, animalId, spawnPosX, spawnPosY, spawnPosZ, 10, 12, 0.01)
		end
	elseif species.classType == "lightWildlife" then
		id = species.lightWildlife:createAnimals(species.name, spawnPosX, spawnPosY, spawnPosZ, nbAnimals)
	end

	if id ~= nil and id ~= 0 then
		table.insert(species.spawned, {
			spawnId = id,
			posX = spawnPosX,
			posY = spawnPosY,
			posZ = spawnPosZ,
			count = nbAnimals
		})

		species.currentCount = species.currentCount + nbAnimals
		self.totalCost = self.totalCost + species.cost * nbAnimals

		return true
	end

	return false
end

function WildlifeSpawner:debugDraw()
	renderText(0.02, 0.95, 0.02, string.format("Wildlife Info\nCost(%d / %d)", self.totalCost, self.maxCost))

	local passedTest, originX, originY, originZ = self:getPlayerCenter()

	if passedTest then
		for _, area in pairs(self.areas) do
			for _, species in pairs(area.species) do
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId ~= nil then
						local distance = 0

						if species.classType == "companionAnimal" then
							distance, _ = getCompanionClosestDistance(spawn.spawnId, originX, originY, originZ)
						elseif species.classType == "lightWildlife" then
							distance = species.lightWildlife:getClosestDistance(originX, originY, originZ)
							distance = math.sqrt(distance)
						end

						local text = string.format("[%s][%d]\n- nearest player distance (%.3f)", species.name, spawn.spawnId, distance)

						Utils.renderTextAtWorldPosition(spawn.posX, spawn.posY + 0.12, spawn.posZ, text, getCorrectTextSize(0.012), 0)
						DebugUtil.drawDebugCubeAtWorldPos(spawn.posX, spawn.posY, spawn.posZ, 1, 0, 0, 0, 1, 0, 0.05, 0.05, 0.05, 1, 1, 0)
						DebugUtil.drawDebugCircle(spawn.posX, spawn.posY, spawn.posZ, species.groupSpawnRadius, 10, {
							1,
							1,
							0
						})
					end
				end
			end
		end
	end

	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					for animalId = 0, spawn.count - 1 do
						local showAdditionalInfo = self:isInDebugList(spawn.spawnId, animalId)
						local showId = self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.SINGLE and showAdditionalInfo or self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.ALL

						companionDebugDraw(spawn.spawnId, animalId, showId, showAdditionalInfo and self.debugShowSteering, showAdditionalInfo and self.debugShowAnimation)
					end
				end
			end
		end
	end
end

function WildlifeSpawner:updateAreaOfInterest(dt)
	for key, area in pairs(self.areasOfInterest) do
		area.timeToLive = area.timeToLive - dt

		if area.timeToLive <= 0 then
			table.remove(self.areasOfInterest, key)
		end
	end
end

function WildlifeSpawner:addAreaOfInterest(liveTime, posX, posZ, radius)
	if #self.areasOfInterest <= self.maxAreaOfInterest then
		local info = {
			liveTime = liveTime,
			positionX = posX,
			positionZ = posZ,
			radius = radius,
			timeToLive = self.areaOfInterestliveTime
		}

		table.insert(self.areasOfInterest, info)
	end
end

function WildlifeSpawner:consoleCommandToggleShowWildlife()
	self.debugShow = not self.debugShow

	return string.format("-- show Wildlife debug = %s", tostring(self.debugShow))
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeId()
	self.debugShowId = self.debugShowId + 1

	if WildlifeSpawner.DEBUGSHOWIDSTATES.MAX < self.debugShowId then
		self.debugShowId = WildlifeSpawner.DEBUGSHOWIDSTATES.NONE
	end

	local state = ""

	if self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.NONE then
		state = "NONE"
	elseif self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.SINGLE then
		state = "SINGLE"
	elseif self.debugShowId == WildlifeSpawner.DEBUGSHOWIDSTATES.ALL then
		state = "ALL"
	end

	return string.format("-- show Wildlife Id = %s", state)
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeSteering()
	self.debugShowSteering = not self.debugShowSteering

	return string.format("-- show Wildlife Steering = %s", tostring(self.debugShowSteering))
end

function WildlifeSpawner:consoleCommandToggleShowWildlifeAnimation()
	self.debugShowAnimation = not self.debugShowAnimation

	return string.format("-- show Wildlife Animation = %s", tostring(self.debugShowAnimation))
end

function WildlifeSpawner:animalExists(spawnId, animalId)
	for _, area in pairs(self.areas) do
		for _, species in pairs(area.species) do
			if species.classType == "companionAnimal" then
				for _, spawn in pairs(species.spawned) do
					if spawn.spawnId == spawnId and animalId < spawn.count then
						return true
					end
				end
			end
		end
	end

	return false
end

function WildlifeSpawner:isInDebugList(spawnId, animalId)
	for key, entry in pairs(self.debugAnimalList) do
		if entry.spawnId == spawnId and entry.animalId == animalId then
			return true
		end
	end

	return false
end

function WildlifeSpawner:consoleCommandAddWildlifeAnimalToDebug(spawnId, animalId)
	local argsTest = true
	spawnId = tonumber(spawnId)

	if spawnId == nil then
		argsTest = false
	end

	animalId = tonumber(animalId)

	if animalId == nil then
		argsTest = false
	end

	if argsTest and self:animalExists(spawnId, animalId) then
		table.insert(self.debugAnimalList, {
			spawnId = spawnId,
			animalId = animalId
		})

		return string.format("-- added [spawn(%d)][animal(%d)] to debug list.", spawnId, animalId)
	else
		return string.format("-- gsAddWildlifeAnimalToDebug [spawnId][animalId]")
	end
end

function WildlifeSpawner:consoleCommandRemoveWildlifeAnimalToDebug(spawnId, animalId)
	local argsTest = true
	spawnId = tonumber(spawnId)

	if spawnId == nil then
		argsTest = false
	end

	animalId = tonumber(animalId)

	if animalId == nil then
		argsTest = false
	end

	if argsTest then
		for key, entry in pairs(self.debugAnimalList) do
			if entry.spawnId == spawnId and entry.animalId == animalId then
				table.remove(self.debugAnimalList, key)

				return string.format("-- removed [spawn(%d)][animal(%d)] from debug list.", spawnId, animalId)
			end
		end
	end

	return string.format("-- gsRemoveWildlifeAnimalToDebug [spawnId][animalId]")
end

g_wildlifeSpawnerManager = WildlifeSpawner:new()
