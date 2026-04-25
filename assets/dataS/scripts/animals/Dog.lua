Dog = {}
local Dog_mt = Class(Dog, Object)

InitStaticObjectClass(Dog, "Dog", ObjectIds.OBJECT_DOG)

function Dog:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or Dog_mt)
	self.dogInstance = 0
	self.animalId = 0
	self.spawner = nil
	self.xmlFilename = nil
	self.entityFollow = nil
	self.entityThrower = nil
	self.playersInRange = {}
	self.isStaying = false
	self.abandonTimer = 0
	self.abandonTimerDuration = 6000
	self.abandonRange = 100
	self.name = ""
	self.spawnX = 0
	self.spawnY = 0
	self.spawnZ = 0
	self.forcedClipDistance = 80

	registerObjectClassName(self, "Dog")

	self.dirtyFlag = self:getNextDirtyFlag()

	return self
end

function Dog:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)
	self.spawner = spawner
	self.animalId = 0
	self.spawnX = spawnX
	self.spawnY = spawnY
	self.spawnZ = spawnZ
	self.xmlFilename = xmlFilename
	self.dogInstance = createAnimalCompanionManager("dog", xmlFilename, "dog", spawnX, spawnY, spawnZ, g_currentMission.terrainRootNode, self.isServer, self.isClient, 1)

	setCompanionWaterLevel(self.dogInstance, g_currentMission.waterY)
	setCompanionTrigger(self.dogInstance, self.animalId, "playerInteractionTriggerCallback", self)
	setCompanionCommonSteeringParameters(self.dogInstance, self.animalId, 1.5, 2.5, MathUtil.degToRad(3), 0.25)
	setCompanionWanderSteeringParameters(self.dogInstance, self.animalId, spawnX, spawnY, spawnZ, 1, 0.2, 0.01)
	setCompanionArriveSteeringParameters(self.dogInstance, self.animalId, 1, 0.5)
	setCompanionBehaviorWanderParameters(self.dogInstance, self.animalId, 10)

	self.name = g_animalNameManager:getRandomName()

	if self.isServer then
		g_currentMission.environment:addHourChangeListener(self)
		g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Dog.playerFarmChanged, self)
	end
end

function Dog:delete()
	self.isDeleted = true

	if self.dogInstance ~= 0 then
		delete(self.dogInstance)
	end

	if self.isServer then
		g_messageCenter:unsubscribeAll(self)
		g_currentMission.environment:removeHourChangeListener(self)
	end

	unregisterObjectClassName(self)
	Dog:superClass().delete(self)
end

function Dog:loadFromXMLFile(xmlFile, key, resetVehicles)
	self:setName(getXMLString(xmlFile, key .. "#name") or "")

	return true
end

function Dog:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(self.name))
end

function Dog:readStream(streamId, connection)
	if connection:getIsServer() then
		local spawner = NetworkUtil.readNodeObject(streamId)
		local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		local spawnX = streamReadFloat32(streamId)
		local spawnY = streamReadFloat32(streamId)
		local spawnZ = streamReadFloat32(streamId)
		local name = streamReadString(streamId)
		local isNew = self.xmlFilename == nil

		if isNew then
			self:load(spawner, xmlFilename, spawnX, spawnY, spawnZ)

			if spawner ~= nil then
				spawner.dog = self
			end
		end

		self:setName(name)
	end

	Dog:superClass().readStream(self, streamId, connection)
end

function Dog:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.spawner)
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.xmlFilename))
		streamWriteFloat32(streamId, self.spawnX)
		streamWriteFloat32(streamId, self.spawnY)
		streamWriteFloat32(streamId, self.spawnZ)
		streamWriteString(streamId, self.name)
	end

	Dog:superClass().writeStream(self, streamId, connection)
end

function Dog:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		writeAnimalCompanionManagerToStream(self.dogInstance, streamId)
	end
end

function Dog:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		readAnimalCompanionManagerFromStream(self.dogInstance, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
	end
end

function Dog:update(dt)
	if self.isServer then
		if self.isStaying and self:isAbandoned(dt) then
			self:teleportToSpawn()
		end

		if self.foodPending and not getVisibility(self.spawner.foodNode) then
			self.spawner:setFoodVisibility(false)

			self.foodPending = false
		end

		self:raiseActive()
	end

	Dog:superClass().update(self, dt)
end

function Dog:updateTick(dt)
	if self.isServer and getAnimalCompanionNeedNetworkUpdate(self.dogInstance) then
		self:raiseDirtyFlags(self.dirtyFlag)
	end

	Dog:superClass().updateTick(self, dt)
end

function Dog:testScope(x, y, z, coeff)
	local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
	local clipDist = math.min(clipDistance * coeff, self.forcedClipDistance)

	return distance < clipDist
end

function Dog:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	local distance, clipDistance = getCompanionClosestDistance(self.dogInstance, x, y, z)
	local clipDist = math.min(clipDistance * coeff, self.forcedClipDistance)
	local result = (1 - distance / clipDist) * 0.8 + 0.5 * skipCount * 0.2

	return result
end

function Dog:onGhostRemove()
	self:setVisibility(false)
end

function Dog:onGhostAdd()
	self:setVisibility(true)
end

function Dog:hourChanged()
	if not self.isServer then
		return
	end

	setCompanionDaytime(self.dogInstance, g_currentMission.environment.dayTime)
end

function Dog:setName(name)
	self.name = name or ""
end

function Dog:setVisibility(state)
	setCompanionsVisibility(self.dogInstance, state)
	setCompanionsPhysicsUpdate(self.dogInstance, state)
end

function Dog:playerInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local player = g_currentMission.players[otherId]

	if player ~= nil then
		if onEnter then
			if g_currentMission.accessHandler:canFarmAccess(player.farmId, self, false) then
				self.playersInRange[otherId] = true
			end
		elseif onLeave then
			self.playersInRange[otherId] = nil
		end
	end
end

function Dog:followEntity(player)
	self.entityFollow = player.rootNode
	self.entityThrower = nil

	if not self.isServer then
		g_client:getServerConnection():sendEvent(DogFollowEvent:new(self, player))
	else
		setCompanionBehaviorIdleWander(self.dogInstance, self.animalId)
		setCompanionFollowEntity(self.dogInstance, self.animalId, self.entityFollow, 3, 2, 4)

		self.isStaying = false

		if self.foodPending then
			self.spawner:setFoodVisibility(false)

			self.foodPending = false
		end
	end
end

function Dog:goToSpawn()
	self.entityFollow = nil
	self.entityThrower = nil

	if not self.isServer then
		g_client:getServerConnection():sendEvent(DogFollowEvent:new(self, nil))
	else
		setCompanionBehaviorIdleWander(self.dogInstance, self.animalId)
		setCompanionGotoEntity(self.dogInstance, self.animalId, self.spawner.spawnNode, 3, 2, 2.5)

		if self.foodPending then
			self.spawner:setFoodVisibility(false)

			self.foodPending = false
		end
	end
end

function Dog:feed()
	self.entityFollow = nil
	self.entityThrower = nil

	if not self.isServer then
		g_client:getServerConnection():sendEvent(DogFeedEvent:new(self))
	else
		self.spawner:setFoodVisibility(true)

		self.foodPending = true

		setCompanionFeed(self.dogInstance, self.animalId, self.spawner.foodNode, 1, 0.55, 1.5)
	end
end

function Dog:fetchItem(player, ball)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(DogFetchItemEvent:new(self, player, ball))
	else
		local x, y, z = getWorldTranslation(ball.nodeId)
		ball.throwPos = {
			x,
			y,
			z
		}

		setCompanionFetch(self.dogInstance, self.animalId, ball.nodeId, 1, 0.5, player.rootNode, 3, 2, 3, 4)

		self.entityThrower = player.rootNode
	end
end

function Dog:pet()
	if not self.isServer then
		g_client:getServerConnection():sendEvent(DogPetEvent:new(self))
	else
		setCompanionPet(self.dogInstance, self.animalId)

		if self.foodPending then
			self.spawner:setFoodVisibility(false)

			self.foodPending = false
		end
	end
end

function Dog:idleStay()
	self.entityFollow = nil
	self.entityThrower = nil

	setCompanionBehaviorIdleStay(self.dogInstance, self.animalId)

	self.isStaying = true

	if self.foodPending then
		self.spawner:setFoodVisibility(false)

		self.foodPending = false
	end
end

function Dog:idleWander()
	setCompanionBehaviorIdleWander(self.dogInstance, self.animalId)

	if self.foodPending then
		self.spawner:setFoodVisibility(false)

		self.foodPending = false
	end
end

function Dog:isAbandoned(dt)
	local isEntityInRange = false

	for _, player in pairs(g_currentMission.players) do
		if player.isControlled then
			local entityX, entityY, entityZ = getWorldTranslation(player.rootNode)
			local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)

			if distance < self.abandonRange then
				isEntityInRange = true

				break
			end
		end
	end

	if not isEntityInRange then
		for _, enterable in pairs(g_currentMission.enterables) do
			if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled then
				local entityX, entityY, entityZ = getWorldTranslation(enterable.rootNode)
				local distance, _ = getCompanionClosestDistance(self.dogInstance, entityX, entityY, entityZ)

				if distance < self.abandonRange then
					isEntityInRange = true

					break
				end
			end
		end
	end

	if isEntityInRange then
		self.abandonTimer = self.abandonTimerDuration
	else
		self.abandonTimer = self.abandonTimer - dt

		if self.abandonTimer <= 0 then
			return true
		end
	end

	return false
end

function Dog:resetSteeringParms()
	setCompanionCommonSteeringParameters(self.dogInstance, self.animalId, 1.5, 2.5, MathUtil.degToRad(3), 0.25)
	setCompanionWanderSteeringParameters(self.dogInstance, self.animalId, self.spawnX, self.spawnY, self.spawnZ, 1, 0.2, 0.01)
	setCompanionArriveSteeringParameters(self.dogInstance, self.animalId, 1, 0.5)
end

function Dog:teleportToSpawn()
	if self.isServer then
		setCompanionPosition(self.dogInstance, self.animalId, self.spawnX, self.spawnY, self.spawnZ)
		self:idleWander()
		self:resetSteeringParms()

		self.isStaying = false
		self.entityFollow = nil
		self.entityThrower = nil

		if self.foodPending then
			self.spawner:setFoodVisibility(false)

			self.foodPending = false
		end

		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_dogInDogHouse"))
	end
end

function Dog:playerFarmChanged(player)
	if self.isServer and (self.entityFollow == player.rootNode or self.entityThrower == player.rootNode) then
		self:idleStay()
	end
end

function Dog:onPlayerLeave(player)
	if self.isServer then
		if self.entityFollow == player.rootNode or self.entityThrower == player.rootNode then
			self:idleStay()
		end

		if self.playersInRange[player.rootNode] ~= nil then
			self.playersInRange[player.rootNode] = nil
		end
	end
end
