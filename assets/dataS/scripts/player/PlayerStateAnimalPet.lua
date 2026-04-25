PlayerStateAnimalPet = {}
local PlayerStateAnimalPet_mt = Class(PlayerStateAnimalPet, PlayerStateBase)

function PlayerStateAnimalPet:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateAnimalPet_mt)
	self.isDog = false

	return self
end

function PlayerStateAnimalPet:isAvailable()
	self.isDog = false

	if self.player.isClient and self.player.isEntered and not g_gui:getIsGuiVisible() then
		local playerHandsEmpty = self.player.baseInformation.currentHandtool == nil and not self.player.isCarryingObject
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)
		local _, playerY, _ = getWorldTranslation(self.player.rootNode)
		playerY = playerY - self.player.baseInformation.capsuleTotalHeight * 0.5
		local deltaWater = playerY - g_currentMission.waterY
		local playerInWater = deltaWater < 0

		if playerHandsEmpty and not playerInWater and dogHouse ~= nil and dogHouse.dog ~= nil and dogHouse.dog.playersInRange[self.player.rootNode] then
			self.isDog = true

			return true
		end
	end

	return false
end

function PlayerStateAnimalPet:activate()
	PlayerStateAnimalPet:superClass().activate(self)

	local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

	if dogHouse ~= nil and dogHouse.dog ~= nil then
		dogHouse.dog:pet()
	end

	self:deactivate()
end

function PlayerStateAnimalPet:deactivate()
	PlayerStateAnimalPet:superClass().deactivate(self)

	self.isDog = false
end
