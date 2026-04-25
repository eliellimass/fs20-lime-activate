Can = {}
local Can_mt = Class(Can)

function Can:onCreate(id)
	g_currentMission:addUpdateable(Can:new(id))
end

function Can:new(id)
	local self = {}

	setmetatable(self, Can_mt)

	self.customEnvironment = g_currentMission.loadingMapModName
	self.id = id
	self.time = 0
	self.xpGain = 1
	self.pickupName = "Unknown"
	local pickupName = getUserAttribute(id, "pickupName")

	if pickupName ~= nil then
		self.pickupName = g_i18n:getText(pickupName, self.customEnvironment)
	end

	self.drinkSound = createSample("SoftDrink")

	loadSample(self.drinkSound, "data/maps/sounds/softDrink.wav", false)

	self.triggerId = getChildAt(self.id, 0)

	if self.triggerId ~= 0 then
		addTrigger(self.triggerId, "onCanPickupTrigger", self)
	end

	self.deleteTimer = 0
	self.activateText = g_i18n:getText("action_pickupSodaCan", self.customEnvironment)
	self.isEnabled = true

	return self
end

function Can:delete()
	if self.triggerId ~= 0 then
		removeTrigger(self.triggerId)

		self.triggerId = 0
	end

	g_currentMission:removeActivatableObject(self)
	delete(self.id)

	self.id = 0

	delete(self.drinkSound)

	self.drinkSound = 0

	g_currentMission:removeUpdateable(self)
end

function Can:update(dt)
	self.time = self.time + dt

	if self.deleteTimer ~= 0 and self.deleteTimer < self.time then
		self:delete()
	end
end

function Can:getIsActivatable()
	return self.isEnabled
end

function Can:drawActivate()
end

function Can:onActivateObject()
	playSample(self.drinkSound, 1, 1, 0, 0, 0)
	setVisibility(self.id, false)

	self.deleteTimer = self.time + getSampleDuration(self.drinkSound) + 200

	if self.triggerId ~= 0 then
		removeTrigger(self.triggerId)

		self.triggerId = 0
	end

	g_currentMission:removeActivatableObject(self)
end

function Can:onCanPickupTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and self.isEnabled and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission:addActivatableObject(self)
		else
			g_currentMission:removeActivatableObject(self)
		end
	end
end
