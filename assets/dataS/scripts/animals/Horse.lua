Horse = {}
local Horse_mt = Class(Horse, RideableAnimal)

InitStaticObjectClass(Horse, "Horse", ObjectIds.OBJECT_HORSE)

Horse.DAILY_MINIMUM_RIDING_TIME = GS_IS_MOBILE_VERSION and 30000 or 60000
Horse.DAILY_TARGET_RIDING_TIME = GS_IS_MOBILE_VERSION and 120000 or 300000

function Horse:new(isServer, isClient, owner, fillTypeIndex, customMt)
	local self = RideableAnimal:new(isServer, isClient, owner, fillTypeIndex, customMt or Horse_mt)
	self.name = g_animalNameManager:getRandomName()
	self.fitnessScale = 0.05
	self.fitnessScaleSent = 0
	self.healthScale = 1
	self.healthScaleSent = 1
	self.ridingTimer = 0
	self.ridingTimerSent = 0
	self.ridingScale = 0
	self.ridingScaleSent = 0
	self.horseDirtyFlag = self:getNextDirtyFlag()

	return self
end

function Horse:readStream(streamId)
	Horse:superClass().readStream(self, streamId)

	self.name = streamReadString(streamId)
	self.fitnessScale = streamReadFloat32(streamId)
	self.healthScale = streamReadFloat32(streamId)
	self.ridingScale = streamReadFloat32(streamId)
end

function Horse:writeStream(streamId)
	Horse:superClass().writeStream(self, streamId)
	streamWriteString(streamId, self.name)
	streamWriteFloat32(streamId, self.fitnessScale)
	streamWriteFloat32(streamId, self.healthScale)
	streamWriteFloat32(streamId, self.ridingScale)

	self.fitnessScaleSent = self.fitnessScale
	self.healthScaleSent = self.healthScale
	self.ridingScaleSent = self.ridingScale
end

function Horse:readUpdateStream(streamId, timestamp, connection)
	Horse:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		self.fitnessScale = NetworkUtil.readCompressedPercentages(streamId, 7)
		self.healthScale = NetworkUtil.readCompressedPercentages(streamId, 7)
		self.ridingScale = NetworkUtil.readCompressedPercentages(streamId, 7)
	end
end

function Horse:writeUpdateStream(streamId, connection, dirtyMask)
	Horse:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.horseDirtyFlag) ~= 0) then
		NetworkUtil.writeCompressedPercentages(streamId, self.fitnessScaleSent, 7)
		NetworkUtil.writeCompressedPercentages(streamId, self.healthScaleSent, 7)
		NetworkUtil.writeCompressedPercentages(streamId, self.ridingScaleSent, 7)
	end
end

function Horse:loadFromXMLFile(xmlFile, key)
	Horse:superClass().loadFromXMLFile(self, xmlFile, key)

	self.name = getXMLString(xmlFile, key .. "#name") or self.name
	self.fitnessScale = getXMLFloat(xmlFile, key .. "#fitnessScale") or self.fitnessScale
	self.healthScale = getXMLFloat(xmlFile, key .. "#healthScale") or self.healthScale
	self.ridingTimer = getXMLFloat(xmlFile, key .. "#ridingTimer") or self.ridingTimer
	self.ridingScale = self.ridingTimer / Horse.DAILY_TARGET_RIDING_TIME
end

function Horse:saveToXMLFile(xmlFile, key, usedModNames)
	Horse:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLString(xmlFile, key .. "#name", self.name)
	setXMLFloat(xmlFile, key .. "#fitnessScale", self.fitnessScale)
	setXMLFloat(xmlFile, key .. "#healthScale", self.healthScale)
	setXMLFloat(xmlFile, key .. "#ridingTimer", self.ridingTimer)
end

function Horse:setName(name)
	if self.name ~= nil and self.name ~= name then
		self.name = name

		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)
	end
end

function Horse:getName()
	return self.name
end

function Horse:getValueScale()
	return 0.99 * self.fitnessScale * self.healthScale + 0.01 * (1 - self.dirtScale)
end

function Horse:setFitnessScale(scale, noEventSend)
	self.fitnessScale = scale

	if math.abs(self.fitnessScaleSent - self.fitnessScale) > 0.01 then
		self.fitnessScaleSent = self.fitnessScale

		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)

		if noEventSend == nil or not noEventSend then
			self:raiseDirtyFlags(self.horseDirtyFlag)
		end
	end
end

function Horse:getFitnessScale()
	return self.fitnessScale
end

function Horse:setHealthScale(scale, noEventSend)
	self.healthScale = scale

	if math.abs(self.healthScaleSent - self.healthScale) > 0.01 then
		self.healthScaleSent = self.healthScale

		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)

		if noEventSend == nil or not noEventSend then
			self:raiseDirtyFlags(self.horseDirtyFlag)
		end
	end
end

function Horse:getHealthScale()
	return self.healthScale
end

function Horse:getTodaysRidingTime()
	if self.owner.isServer then
		return self.ridingTimer
	else
		return self.ridingScale * Horse.DAILY_TARGET_RIDING_TIME
	end
end

function Horse:deactivateRiding(noEventSend)
	if self.rideableVehicle ~= nil then
		self.rideableVehicle:setFitnessChangedCallback(nil, )
	end

	Horse:superClass().deactivateRiding(self, noEventSend)
end

function Horse:onLoadedRideable(rideableVehicle, vehicleLoadState, arguments)
	Horse:superClass().onLoadedRideable(self, rideableVehicle, vehicleLoadState, arguments)

	if self.rideableVehicle ~= nil then
		self.rideableVehicle:setFitnessChangedCallback(self.onFitnessChangedCallback, self)
		self.rideableVehicle:setRidingHorse(self)
	end
end

function Horse:onFitnessChangedCallback(deltaTime)
	self.ridingTimer = self.ridingTimer + deltaTime
	self.ridingScale = self.ridingTimer / Horse.DAILY_TARGET_RIDING_TIME

	if math.abs(self.ridingScaleSent - self.ridingScale) > 0.01 then
		self.ridingScaleSent = self.ridingScale

		self:raiseDirtyFlags(self.horseDirtyFlag)
	end
end

function Horse:updateFitness(productionFactor)
	if self.isServer then
		local fitness = self:getFitnessScale()

		if self.ridingTimer < Horse.DAILY_MINIMUM_RIDING_TIME then
			fitness = fitness - 0.02
		else
			local fitnessGain = math.min(0.1, 0.1 * self.ridingTimer / Horse.DAILY_TARGET_RIDING_TIME)
			fitnessGain = fitnessGain * productionFactor
			fitness = fitness + fitnessGain
		end

		fitness = MathUtil.clamp(fitness, 0, 1)

		self:setFitnessScale(fitness)

		self.ridingTimer = 0

		if self.ridingScale ~= 0 then
			self.ridingScale = 0
			self.ridingScaleSent = 0

			self:raiseDirtyFlags(self.horseDirtyFlag)
		end
	end
end
