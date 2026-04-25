RideableAnimal = {}
local RideableAnimal_mt = Class(RideableAnimal, Animal)

InitStaticObjectClass(RideableAnimal, "RideableAnimal", ObjectIds.OBJECT_RIDEABLE_ANIMAL)

function RideableAnimal:new(isServer, isClient, owner, fillTypeIndex, customMt)
	local self = Animal:new(isServer, isClient, owner, fillTypeIndex, customMt or RideableAnimal_mt)
	self.rideableVehicle = nil
	self.enterNextRidable = true
	self.loadAnimalId = nil

	return self
end

function RideableAnimal:delete()
	RideableAnimal:superClass().delete(self)

	if self.owner ~= nil and self.owner.isServer and self.rideableVehicle ~= nil then
		self.owner:removeRideable(self.visualId)
	end
end

function RideableAnimal:readStream(streamId)
	RideableAnimal:superClass().readStream(self, streamId)

	local id = NetworkUtil.readNodeObjectId(streamId)

	if id ~= 0 then
		self.loadAnimalId = id
	end
end

function RideableAnimal:writeStream(streamId)
	RideableAnimal:superClass().writeStream(self, streamId)

	local id = 0

	if self.rideableVehicle ~= nil then
		id = NetworkUtil.getObjectId(self.rideableVehicle)
	end

	NetworkUtil.writeNodeObjectId(streamId, id)
end

function RideableAnimal:tryToFinishRideable()
	if self.loadAnimalId ~= nil then
		local object = NetworkUtil.getObject(self.loadAnimalId)

		if object ~= nil then
			self:finishRideable(object)

			return true
		else
			return false
		end
	end

	self.loadAnimalId = nil

	return true
end

function RideableAnimal:getIsRideableSetupDone()
	return self.loadAnimalId == nil
end

function RideableAnimal:loadFromXMLFile(xmlFile, key)
	RideableAnimal:superClass().loadFromXMLFile(self, xmlFile, key)

	local isRidingActive = getXMLBool(xmlFile, key .. "#isRidingActive")

	if isRidingActive then
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#position"))
		local xRot, yRot, zRot = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))
		xRot = math.rad(xRot or 0)
		yRot = math.rad(yRot or 0)
		zRot = math.rad(zRot or 0)
		self.loadedRidingData = {
			position = {
				x,
				y,
				z
			},
			rotation = {
				xRot,
				yRot,
				zRot
			}
		}
	end
end

function RideableAnimal:saveToXMLFile(xmlFile, key, usedModNames)
	RideableAnimal:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLBool(xmlFile, key .. "#isRidingActive", self.rideableVehicle ~= nil)

	if self.rideableVehicle ~= nil then
		local x, y, z = self.rideableVehicle:getPosition()
		local xRot, yRot, zRot = self.rideableVehicle:getRotation()

		setXMLString(xmlFile, key .. "#position", string.format("%.4f %.4f %.4f", x, y, z))
		setXMLString(xmlFile, key .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(xRot), math.deg(yRot), math.deg(zRot)))
	end
end

function RideableAnimal:activateRiding(player, noEventSend)
	AnimalRidingEvent.sendEvent(self, true, player, noEventSend)

	if self.owner.isServer then
		local posX, posY, posZ, rotX, rotY, rotZ = nil

		if self.loadedRidingData ~= nil then
			local pos = self.loadedRidingData.position
			posZ = pos[3] or 0
			posY = pos[2] or nil
			posX = pos[1] or 0
			rotZ = self.loadedRidingData.rotation[3]
			rotY = self.loadedRidingData.rotation[2]
			rotX = self.loadedRidingData.rotation[1]
		else
			local visualId = self.visualId
			local husbandryId = self.module.husbandryId
			posX, posY, posZ = getAnimalPosition(husbandryId, visualId)
			rotX, rotY, rotZ = getAnimalRotation(husbandryId, visualId)
		end

		local dx, dy, dz = mathEulerRotateVector(rotX, rotY, rotZ, 0, 0, 1)
		rotY = MathUtil.getYRotationFromDirection(dx, dz)
		self.ridingPlayer = player
		local ownerFarmId = self.module.owner:getOwnerFarmId()

		g_currentMission:loadVehicle(self.subType.rideableFileName, posX, posY, posZ, 0, rotY, true, 0, Vehicle.PROPERTY_STATE_OWNED, ownerFarmId, {}, nil, self.onLoadedRideable, self)
	else
		self.module:hideAnimal(self.visualId)
	end
end

function RideableAnimal:deactivateRiding(noEventSend)
	AnimalRidingEvent.sendEvent(self, false, nil, noEventSend)

	if self.rideableVehicle ~= nil then
		self.rideableVehicle:setDirtChangedCallback(nil, )

		self.dirtScale = self.rideableVehicle:getDirtScale()

		if self.owner.isServer and not self.rideableVehicle.isDeleted then
			g_currentMission:removeVehicle(self.rideableVehicle)
		end

		self.rideableVehicle = nil
	end

	self.ridingPlayer = nil

	self.module:showAnimal(self.visualId)
end

function RideableAnimal:onLoadedRideable(rideableVehicle, vehicleLoadState, arguments)
	if rideableVehicle ~= nil then
		self:finishRideable(rideableVehicle)
	end
end

function RideableAnimal:finishRideable(rideableVehicle)
	self.rideableVehicle = rideableVehicle

	self.module:hideAnimal(self.visualId)
	rideableVehicle:setDirtScale(self.dirtScale)
	rideableVehicle:setDirtChangedCallback(self.onDirtChangedCallback, self)
	rideableVehicle:setAnimal(self)
	rideableVehicle:setPlayerToEnter(self.ridingPlayer)
	rideableVehicle:raiseActive()
end

function RideableAnimal:setVisualId(visualId)
	RideableAnimal:superClass().setVisualId(self, visualId)

	if visualId ~= nil and self.loadedRidingData ~= nil then
		self.enterNextRidable = false

		self.owner:addRideable(self.visualId)

		self.loadedRidingData = nil
	end
end

function RideableAnimal:getIsInUse()
	if self.rideableVehicle ~= nil then
		return true
	end

	return RideableAnimal:superClass().getIsInUse(self)
end

function RideableAnimal:getCanBeRidden()
	return self.rideableVehicle == nil
end

function RideableAnimal:onDirtChangedCallback(dirtScale)
	self:setDirtScale(dirtScale)
end

function RideableAnimal:setDirtScale(dirtScale)
	RideableAnimal:superClass().setDirtScale(self, dirtScale)

	if self.rideableVehicle ~= nil then
		self.rideableVehicle:setDirtScale(dirtScale)
	end
end

function RideableAnimal:isOnHusbandyGround()
	if self.rideableVehicle ~= nil then
		return self.rideableVehicle:isOnHusbandyGround(self.module.rideableDeliveryArea)
	end

	return false
end
