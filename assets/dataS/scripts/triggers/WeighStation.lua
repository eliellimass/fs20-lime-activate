WeighStation = {}
local WeighStation_mt = Class(WeighStation)

function WeighStation:onCreate(id)
	g_currentMission:addNonUpdateable(WeighStation:new(id))
end

function WeighStation:new(triggerId)
	local self = {}

	setmetatable(self, WeighStation_mt)

	local nodeId = triggerId
	self.triggerId = triggerId

	addTrigger(triggerId, "triggerCallback", self)

	self.isEnabled = true
	self.triggerVehicles = {}
	local weightDisplayIndex = getUserAttribute(nodeId, "weightDisplayIndex")

	if weightDisplayIndex ~= nil then
		self.displayNumbers = I3DUtil.indexToObject(nodeId, weightDisplayIndex)
	end

	return self
end

function WeighStation:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)

		self.triggerId = nil
	end
end

function WeighStation:updateDisplayNumbers(mass)
	if self.displayNumbers ~= nil then
		I3DUtil.setNumberShaderByValue(self.displayNumbers, math.floor(mass), 0)
	end
end

function WeighStation:updateWeight()
	local mass = 0

	for vehicle, _ in pairs(self.triggerVehicles) do
		mass = mass + vehicle:getTotalMass()
	end

	self:updateDisplayNumbers(mass * 1000)
end

function WeighStation:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local vehicle = g_currentMission.nodeToObject[otherId]

		if onEnter then
			if vehicle ~= nil then
				if self.triggerVehicles[vehicle] == nil then
					self.triggerVehicles[vehicle] = 0
				end

				self.triggerVehicles[vehicle] = self.triggerVehicles[vehicle] + 1
			end
		elseif vehicle ~= nil then
			self.triggerVehicles[vehicle] = self.triggerVehicles[vehicle] - 1

			if self.triggerVehicles[vehicle] == 0 then
				self.triggerVehicles[vehicle] = nil
			end
		end

		self:updateWeight()
	end
end
