WashingStationPlaceable = {}
local WashingStationPlaceable_mt = Class(WashingStationPlaceable, Placeable)

InitStaticObjectClass(WashingStationPlaceable, "WashingStationPlaceable", ObjectIds.OBJECT_WASH_STATION_PLACEABLE)

function WashingStationPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or WashingStationPlaceable_mt)

	registerObjectClassName(self, "WashingStationPlaceable")

	self.vehiclesTriggerCount = {}

	return self
end

function WashingStationPlaceable:delete()
	removeTrigger(self.triggerId)
	g_effectManager:deleteEffects(self.effects)

	if self.poiTrigger ~= nil then
		self.poiTrigger:delete()
	end

	unregisterObjectClassName(self)
	WashingStationPlaceable:superClass().delete(self)
end

function WashingStationPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not WashingStationPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.appearsOnPDA = Utils.getNoNil(getXMLBool(xmlFile, "placeable.washingStation#appearsOnPDA"), false)
	local rawName = Utils.getNoNil(getXMLString(xmlFile, "placeable.washingStation#stationName"), "washingStation")
	self.stationName = g_i18n:convertText(rawName)
	local triggerId = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.washingStation#triggerNode"))

	if triggerId == nil then
		g_logManager:xmlWarning(xmlFilename, "Missing wash trigger node in 'placeable.washingStation#triggerNode'!")
		delete(xmlFile)

		return false
	end

	addTrigger(triggerId, "washTriggerCallback", self)

	self.triggerId = triggerId
	self.pricePerWash = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.washingStation#pricePerWash"), 200)
	self.effects = g_effectManager:loadEffect(xmlFile, "placeable.washingStation.effects", self.nodeId, self, self.i3dMappings)
	self.effectDropTimer = 0

	if hasXMLProperty(xmlFile, "placeable.washingStation.poiTrigger") then
		self.poiTrigger = POITrigger:new()

		if not self.poiTrigger:loadFromXML(self.nodeId, xmlFile, "placeable.washingStation.poiTrigger") then
			self.poiTrigger:delete()

			self.poiTrigger = nil
		end
	end

	delete(xmlFile)

	return true
end

function WashingStationPlaceable:update(dt)
	WashingStationPlaceable:superClass().update(self, dt)

	if self.effectDropTimer > 0 then
		self.effectDropTimer = self.effectDropTimer - dt

		if self.effectDropTimer <= 0 then
			g_effectManager:stopEffects(self.effects)
		end

		self:raiseActive()
	end

	for vehicle, count in pairs(self.vehiclesTriggerCount) do
		if count > 0 then
			if vehicle:getLastSpeed() < 0.5 and self:washVehicle(vehicle) then
				self:dropParticles(vehicle, 2000)
			end

			self:raiseActive()
		end
	end
end

function WashingStationPlaceable:washTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local vehicle = g_currentMission:getNodeObject(otherId)

		if vehicle ~= nil and vehicle.addDirtAmount ~= nil then
			local count = Utils.getNoNil(self.vehiclesTriggerCount[vehicle], 0)

			if onEnter then
				self.vehiclesTriggerCount[vehicle] = count + 1

				self:raiseActive()
			else
				self.vehiclesTriggerCount[vehicle] = count - 1

				if self.vehiclesTriggerCount[vehicle] == 0 then
					self.vehiclesTriggerCount[vehicle] = nil
				end
			end
		end
	end
end

function WashingStationPlaceable:washVehicle(vehicle)
	if vehicle:getAllowsWashingByType(Washable.WASHTYPE_TRIGGER) then
		local dirtAmount = vehicle:getDirtAmount()

		if vehicle:getDirtAmount() > 0.01 then
			vehicle:addDirtAmount(-1, true)

			local costs = dirtAmount * self.pricePerWash

			if costs >= 1 then
				g_currentMission:addMoney(-costs, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR)
				g_currentMission:addMoneyChange(-costs, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true)
			end

			return true
		end
	end

	return false
end

function WashingStationPlaceable:dropParticles(vehicle, dropTime)
	g_effectManager:setFillType(self.effects, FillType.WATER)

	local node = vehicle.components[1].node

	for _, effect in pairs(self.effects) do
		if effect.emitterShape ~= nil then
			local x, y, z = localToWorld(node, vehicle.widthOffset, 0, vehicle.lengthOffset)

			setWorldTranslation(effect.emitterShape, x, y, z)
			setWorldRotation(effect.emitterShape, getWorldRotation(node))
			setScale(effect.emitterShape, vehicle.sizeWidth, 0, vehicle.sizeLength)
			ParticleUtil.setEmitCountScale(effect.currentParticleSystem, vehicle.sizeWidth * vehicle.sizeLength * 0.05)
			ParticleUtil.setParticleLifespan(effect.currentParticleSystem, 2000)
		end
	end

	g_effectManager:startEffects(self.effects)

	self.effectDropTimer = dropTime

	self:raiseActive()
end
