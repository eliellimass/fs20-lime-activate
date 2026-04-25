AIDriveStrategyCollision = {}
local AIDriveStrategyCollision_mt = Class(AIDriveStrategyCollision, AIDriveStrategy)

function AIDriveStrategyCollision:new(customMt)
	if customMt == nil then
		customMt = AIDriveStrategyCollision_mt
	end

	local self = AIDriveStrategy:new(customMt)
	self.setHasCollision = AIDriveStrategyCollision.setHasCollision
	self.addCollisionTrigger = AIDriveStrategyCollision.addCollisionTrigger
	self.removeCollisionTrigger = AIDriveStrategyCollision.removeCollisionTrigger
	self.setCollisionTriggerDirection = AIDriveStrategyCollision.setCollisionTriggerDirection
	self.numCollidingVehicles = {}
	self.vehicleIgnoreList = {}
	self.collisionTriggerByVehicle = {}
	self.lastHasCollision = false

	return self
end

function AIDriveStrategyCollision:delete()
	AIDriveStrategyCollision:superClass().delete(self)

	if self.vehicle.isServer then
		self:removeCollisionTrigger(self.collisionTriggerByVehicle)
	end
end

function AIDriveStrategyCollision:setAIVehicle(vehicle)
	AIDriveStrategyCollision:superClass().setAIVehicle(self, vehicle)

	if self.vehicle.isServer then
		self:addCollisionTrigger(self.collisionTriggerByVehicle, self.vehicle)
	end
end

function AIDriveStrategyCollision:update(dt)
	local colDirX = 0

	if self.vehicle.rotatedTime > 0 then
		colDirX = self.vehicle.rotatedTime / self.vehicle.maxRotTime
	elseif self.vehicle.rotatedTime < 0 then
		colDirX = -self.vehicle.rotatedTime / self.vehicle.minRotTime
	end

	colDirX = MathUtil.sign(colDirX) * colDirX * colDirX
	colDirX = math.max(-0.3, math.min(0.3, colDirX))

	if self.lastColDirX ~= colDirX then
		local dX, dY, dZ = localDirectionToWorld(self.vehicle:getAIVehicleDirectionNode(), colDirX, 0, 1)
		local uX, uY, uZ = localDirectionToWorld(self.vehicle:getAIVehicleDirectionNode(), 0, 1, 0)

		for vehicle, trigger in pairs(self.collisionTriggerByVehicle) do
			self:setCollisionTriggerDirection(trigger, dX, dY, dZ, uX, uY, uZ)
		end
	end
end

function AIDriveStrategyCollision:setCollisionTriggerDirection(trigger, dx, dy, dz, ux, uy, uz)
	if trigger ~= nil and trigger ~= 0 then
		local parent = getParent(trigger)
		local dirX, dirY, dirZ = worldDirectionToLocal(parent, dx, dy, dz)
		local upX, upY, upZ = worldDirectionToLocal(parent, ux, uy, uz)

		setDirection(trigger, dirX, dirY, dirZ, upX, upY, upZ)
	end
end

function AIDriveStrategyCollision:getDriveData(dt, vX, vY, vZ)
	if self.vehicle.movingDirection < 0 and self.vehicle:getLastSpeed(true) > 2 then
		return nil, , , , 
	end

	for _, count in pairs(self.numCollidingVehicles) do
		if count > 0 then
			local tX, _, tZ = localToWorld(self.vehicle:getAIVehicleDirectionNode(), 0, 0, 1)

			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.vehicle:addAIDebugText(" AIDriveStrategyCollision :: STOP due to collision ")
			end

			self:setHasCollision(true)

			return tX, tZ, true, 0, math.huge
		end
	end

	self:setHasCollision(false)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(" AIDriveStrategyCollision :: no collision ")
	end

	return nil, , , , 
end

function AIDriveStrategyCollision:setHasCollision(state)
	if state ~= self.lastHasCollision then
		self.lastHasCollision = state

		if g_server ~= nil then
			g_server:broadcastEvent(AIVehicleIsBlockedEvent:new(self.vehicle, state), true, nil, self.vehicle)
		end
	end
end

function AIDriveStrategyCollision:updateDriving(dt)
end

function AIDriveStrategyCollision:addCollisionTrigger(collisionTriggerByVehicle, object)
	if collisionTriggerByVehicle[object] == nil then
		local collisionTriggers = {}

		object:getAICollisionTriggers(collisionTriggers)

		if object.getAIImplementCollisionTriggers ~= nil then
			object:getAIImplementCollisionTriggers(collisionTriggers)
		end

		for vehicle, trigger in pairs(collisionTriggers) do
			addTrigger(trigger, "onTrafficCollisionTrigger", self)

			collisionTriggerByVehicle[vehicle] = trigger
			self.numCollidingVehicles[trigger] = 0
		end
	end
end

function AIDriveStrategyCollision:removeCollisionTrigger(collisionTriggerByVehicle)
	for _, trigger in pairs(collisionTriggerByVehicle) do
		if trigger ~= nil and trigger ~= 0 then
			removeTrigger(trigger)
		end

		self.numCollidingVehicles[trigger] = nil
	end
end

function AIDriveStrategyCollision:onTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		if g_currentMission.players[otherId] ~= nil then
			if onEnter then
				self.numCollidingVehicles[triggerId] = self.numCollidingVehicles[triggerId] + 1
			elseif onLeave then
				self.numCollidingVehicles[triggerId] = math.max(self.numCollidingVehicles[triggerId] - 1, 0)
			end
		else
			local vehicle = g_currentMission.nodeToObject[otherId]

			if vehicle ~= nil then
				local rootVehicle = vehicle:getRootVehicle()

				if self.collisionTriggerByVehicle[vehicle] == nil and self.collisionTriggerByVehicle[rootVehicle] == nil then
					if onEnter then
						self.numCollidingVehicles[triggerId] = self.numCollidingVehicles[triggerId] + 1
					elseif onLeave then
						self.numCollidingVehicles[triggerId] = math.max(self.numCollidingVehicles[triggerId] - 1, 0)
					end
				end
			end
		end
	end
end
