PlayerStateAnimalRide = {}
local PlayerStateAnimalRide_mt = Class(PlayerStateAnimalRide, PlayerStateBase)
PlayerStateAnimalRide.INPUT_CONTEXT_EMPTY = "ANIMAL_LOAD_EMPTY"

function PlayerStateAnimalRide:new(player, stateMachine)
	local self = PlayerStateBase:new(player, stateMachine, PlayerStateAnimalRide_mt)
	self.testedHusbandryInfo = nil
	self.castDistance = 1.5
	self.timeFadeToBlack = 250

	return self
end

function PlayerStateAnimalRide:isAvailable()
	local cameraX, cameraY, cameraZ = localToWorld(self.player.cameraNode, 0, 0, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)
	local collisionMask = 268435456
	self.testedHusbandryInfo = nil

	raycastClosest(cameraX, cameraY, cameraZ, dirX, dirY, dirZ, "animalRaycastCallback", self.castDistance, self, collisionMask)

	if self.testedHusbandryInfo ~= nil then
		return true
	end

	return false
end

function PlayerStateAnimalRide:activate()
	PlayerStateAnimalRide:superClass().activate(self)
	g_currentMission:fadeScreen(1, self.timeFadeToBlack, self.endFadeToBlack, self)
	g_inputBinding:setContext(PlayerStateAnimalRide.INPUT_CONTEXT_EMPTY, true, false)
end

function PlayerStateAnimalRide:endFadeToBlack()
	local husbandry = g_currentMission.husbandries[self.testedHusbandryInfo.husbandryId]

	if husbandry ~= nil then
		husbandry:addRideable(self.testedHusbandryInfo.visualId, self.player)
	end
end

function PlayerStateAnimalRide:animalRaycastCallback(hitObjectId, x, y, z, distance)
	local husbandryId, visualId = getAnimalFromCollisionNode(hitObjectId)

	if husbandryId ~= 0 then
		local husbandry = g_currentMission.husbandries[husbandryId]

		if husbandry ~= nil and husbandry:getSupportsRiding(visualId) and husbandry:getCanBeRidden(visualId) and g_currentMission.accessHandler:canFarmAccess(self.player.farmId, husbandry) then
			self.testedHusbandryInfo = {
				husbandryId = husbandryId,
				visualId = visualId
			}

			return true
		end
	end

	return false
end

function PlayerStateAnimalRide:getRideableName()
	local rideableName = ""

	if self.testedHusbandryInfo ~= nil then
		local husbandry = g_currentMission.husbandries[self.testedHusbandryInfo.husbandryId]

		if husbandry ~= nil then
			rideableName = husbandry:getAnimalName(self.testedHusbandryInfo.visualId)
		end
	end

	return rideableName
end
