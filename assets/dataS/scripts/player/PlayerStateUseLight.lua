PlayerStateUseLight = {}
local PlayerStateUseLight_mt = Class(PlayerStateUseLight, PlayerStateBase)

function PlayerStateUseLight:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateUseLight_mt)

	return self
end

function PlayerStateUseLight:isAvailable()
	if self.player.lightNode ~= nil and not g_currentMission:isInGameMessageActive() then
		return true
	end

	return false
end

function PlayerStateUseLight:activate()
	PlayerStateUseLight:superClass().activate(self)
	self.player:setLightIsActive(not self.player.isLightActive)
	self:deactivate()
end
