PlayerStateAnimalFeed = {}
local PlayerStateAnimalFeed_mt = Class(PlayerStateAnimalFeed, PlayerStateBase)

function PlayerStateAnimalFeed:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateAnimalFeed_mt)
	self.isDog = false

	return self
end

function PlayerStateAnimalFeed:isAvailable()
	self.isDog = false

	if self.player.isClient and self.player.isEntered and not g_gui:getIsGuiVisible() then
		local playerHandsEmpty = self.player.baseInformation.currentHandtool == nil and not self.player.isCarryingObject
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

		if playerHandsEmpty and dogHouse ~= nil and dogHouse.isActivatable and dogHouse.dog ~= nil and not getVisibility(dogHouse.foodNode) then
			self.isDog = true

			return true
		end
	end

	return false
end

function PlayerStateAnimalFeed:activate()
	PlayerStateAnimalFeed:superClass().activate(self)

	local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

	if dogHouse ~= nil and dogHouse.dog ~= nil then
		dogHouse.dog:feed()
	end

	self:deactivate()
end

function PlayerStateAnimalFeed:deactivate()
	PlayerStateAnimalFeed:superClass().deactivate(self)

	self.isDog = false
end
