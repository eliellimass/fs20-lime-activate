PlayerStateActivateObject = {}
local PlayerStateActivateObject_mt = Class(PlayerStateActivateObject, PlayerStateBase)

function PlayerStateActivateObject:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateActivateObject_mt)
	self.activateText = ""
	self.object = nil

	return self
end

function PlayerStateActivateObject:isAvailable()
	for key, object in pairs(g_currentMission.activatableObjects) do
		if object:getIsActivatable() then
			self.activateText = object.activateText
			self.object = object

			object:drawActivate()

			return true
		end
	end

	return false
end

function PlayerStateActivateObject:activate()
	PlayerStateActivateObject:superClass().activate(self)
	self.object:onActivateObject()

	for _, v in pairs(g_currentMission.activateListeners) do
		v:onActivateObject(self.object)
	end

	if self.object.shouldRemoveActivatable == nil or self.object:shouldRemoveActivatable() then
		g_currentMission:removeActivatableObject(self.object)
	end

	self:deactivate()
end

function PlayerStateActivateObject:deactivate()
	self.object = nil
	self.activateText = ""

	PlayerStateActivateObject:superClass().deactivate(self)
end
