VehicleSellingPoint = {}
local VehicleSellingPoint_mt = Class(VehicleSellingPoint)

function VehicleSellingPoint:new(id)
	local self = {}

	setmetatable(self, VehicleSellingPoint_mt)

	self.id = id
	self.vehicleInRange = {}
	self.currentVehicle = nil
	self.currentVehicleId = 0
	self.activateText = g_i18n:getText("action_configSellSpecificVehicle")
	self.isEnabled = true
	self.objectActivated = false

	return self
end

function VehicleSellingPoint:load(xmlFile, key)
	self.playerTrigger = I3DUtil.indexToObject(self.id, getXMLString(xmlFile, key .. "#playerTriggerNode"))
	self.sellIcon = I3DUtil.indexToObject(self.id, getXMLString(xmlFile, key .. "#iconNode"))
	self.sellTriggerNode = I3DUtil.indexToObject(self.id, getXMLString(xmlFile, key .. "#sellTriggerNode"))
	self.ownWorkshop = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ownWorkshop"), false)

	addTrigger(self.playerTrigger, "triggerCallback", self)
	addTrigger(self.sellTriggerNode, "sellAreaTriggerCallback", self)
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.PLAYER_CREATED, self.playerFarmChanged, self)
	self:updateIconVisibility()
end

function VehicleSellingPoint:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.playerTrigger ~= nil then
		removeTrigger(self.playerTrigger)

		self.playerTrigger = nil
	end

	if self.sellTriggerNode ~= nil then
		removeTrigger(self.sellTriggerNode)

		self.sellTriggerNode = nil
	end

	g_currentMission:removeActivatableObject(self)

	self.sellIcon = nil
end

function VehicleSellingPoint:getIsActivatable()
	return self.isEnabled and g_currentMission.controlPlayer and (self:getOwnerFarmId() == 0 or g_currentMission:getFarmId() == self:getOwnerFarmId())
end

function VehicleSellingPoint:drawActivate()
end

function VehicleSellingPoint:onActivateObject()
	self:determineCurrentVehicle()
	g_gui:showDirectSellDialog({
		vehicle = self.currentVehicle,
		owner = self,
		ownWorkshop = self.ownWorkshop
	})
end

function VehicleSellingPoint:shouldRemoveActivatable()
	return false
end

function VehicleSellingPoint:update(dt)
end

function VehicleSellingPoint:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			if not self.objectActivated then
				g_currentMission:addActivatableObject(self)

				self.objectActivated = true
			end
		elseif self.objectActivated then
			g_currentMission:removeActivatableObject(self)

			self.objectActivated = false
		end
	end
end

function VehicleSellingPoint:sellAreaTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherShapeId ~= nil and (onEnter or onLeave) then
		if onEnter then
			self.vehicleInRange[otherShapeId] = true
		elseif onLeave then
			self.vehicleInRange[otherShapeId] = nil
		end

		self:determineCurrentVehicle()
	end
end

function VehicleSellingPoint:determineCurrentVehicle()
	self.currentVehicle = nil

	for vehicleId, inRange in pairs(self.vehicleInRange) do
		if inRange ~= nil then
			self.currentVehicle = g_currentMission.nodeToObject[vehicleId]

			if self.currentVehicle ~= nil and (not SpecializationUtil.hasSpecialization(Rideable, self.currentVehicle.specializations) or self.currentVehicle:getOwnerFarmId() ~= self:getOwnerFarmId()) then
				break
			end
		end

		self.vehicleInRange[vehicleId] = nil
	end
end

function VehicleSellingPoint:updateIconVisibility()
	if self.sellIcon ~= nil then
		local hideMission = g_isPresentationVersion and not g_isPresentationVersionShopEnabled or not g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		local farmId = g_currentMission:getFarmId()
		local visibleForFarm = farmId ~= FarmManager.SPECTATOR_FARM_ID and (self:getOwnerFarmId() == AccessHandler.EVERYONE or farmId == self:getOwnerFarmId())

		setVisibility(self.sellIcon, not hideMission and visibleForFarm)
	end
end

function VehicleSellingPoint:playerFarmChanged(player)
	if player == g_currentMission.player then
		self:updateIconVisibility()
	end
end

function VehicleSellingPoint:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId

	self:updateIconVisibility()
end

function VehicleSellingPoint:getOwnerFarmId()
	return self.ownerFarmId
end
