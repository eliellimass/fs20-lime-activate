PlayerStateAnimalInteract = {}
local PlayerStateAnimalInteract_mt = Class(PlayerStateAnimalInteract, PlayerStateBase)

function PlayerStateAnimalInteract:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateAnimalInteract_mt)
	self.isDog = false
	self.husbandryInfo = {}
	self.castDistance = 1.5
	self.interactText = ""

	return self
end

function PlayerStateAnimalInteract:isAvailable()
	self.isDog = false

	if self.player.isClient and self.player.isEntered and not g_gui:getIsGuiVisible() then
		local playerHandsEmpty = self.player.baseInformation.currentHandtool == nil and not self.player.isCarryingObject
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

		if playerHandsEmpty and dogHouse ~= nil and dogHouse.dog ~= nil and dogHouse.dog.playersInRange[self.player.rootNode] then
			self.isDog = true

			if dogHouse.dog.entityFollow == self.player.rootNode then
				self.interactText = g_i18n:getText("action_interactAnimalStopFollow")
			else
				self.interactText = g_i18n:getText("action_interactAnimalFollow")
			end

			return true
		end
	end

	self:detectAnimal()

	if self.husbandryInfo.husbandryId ~= nil then
		local husbandry = g_currentMission.husbandries[self.husbandryInfo.husbandryId]

		if husbandry ~= nil and husbandry:getCanBeRidden(self.husbandryInfo.visualId) and husbandry:isAnimalDirty(self.husbandryInfo.visualId) then
			self.interactText = string.format(g_i18n:getText("action_interactAnimalClean"), husbandry:getAnimalName(self.husbandryInfo.visualId))

			return true
		end
	end

	self.interactText = ""

	return false
end

function PlayerStateAnimalInteract:activate()
	PlayerStateAnimalInteract:superClass().activate(self)

	if self.isDog then
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

		if dogHouse.dog ~= nil then
			if dogHouse.dog.entityFollow == self.player.rootNode then
				dogHouse.dog:goToSpawn()
			else
				dogHouse.dog:followEntity(self.player)
			end
		end

		self:deactivate()
	elseif self.husbandryInfo.husbandryId ~= nil then
		g_soundManager:playSample(self.player.soundInformation.samples.horseBrush)
	end
end

function PlayerStateAnimalInteract:deactivate()
	PlayerStateAnimalInteract:superClass().deactivate(self)
	g_soundManager:stopSample(self.player.soundInformation.samples.horseBrush)

	self.isDog = false
	self.husbandryInfo = {}
end

function PlayerStateAnimalInteract:detectAnimal()
	local collisionMask = 268435456
	local cameraX, cameraY, cameraZ = localToWorld(self.player.cameraNode, 0, 0, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)
	self.husbandryInfo.husbandryId = nil

	raycastClosest(cameraX, cameraY, cameraZ, dirX, dirY, dirZ, "animalRaycastCallback", self.castDistance, self, collisionMask)
end

function PlayerStateAnimalInteract:update(dt)
	self:detectAnimal()

	if self.husbandryInfo.husbandryId ~= nil and self.player.inputInformation.interactState == Player.BUTTONSTATES.PRESSED then
		local husbandry = g_currentMission.husbandries[self.husbandryInfo.husbandryId]

		husbandry:cleanAnimal(self.husbandryInfo.visualId, dt)
	else
		self:deactivate()
	end
end

function PlayerStateAnimalInteract:animalRaycastCallback(hitObjectId, x, y, z, distance)
	local husbandryId, visualId = getAnimalFromCollisionNode(hitObjectId)

	if husbandryId ~= 0 then
		local husbandry = g_currentMission.husbandries[husbandryId]

		if husbandry ~= nil and g_currentMission.accessHandler:canFarmAccess(self.player.farmId, husbandry) then
			self.husbandryInfo.husbandryId = husbandryId
			self.husbandryInfo.visualId = visualId

			return true
		end
	end

	return false
end
