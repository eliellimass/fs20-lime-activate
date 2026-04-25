Doghouse = {}
local Doghouse_mt = Class(Doghouse, Placeable)

InitStaticObjectClass(Doghouse, "Doghouse", ObjectIds.OBJECT_DOGHOUSE_PLACEABLE)

function Doghouse:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or Doghouse_mt)

	registerObjectClassName(self, "Doghouse")

	self.triggerNode = nil
	self.isActivatable = false
	self.activateText = g_i18n:getText("action_doghouseFillbowl")
	self.dirtyFlag = self:getNextDirtyFlag()

	return self
end

function Doghouse:delete()
	self:unregisterDoghouseToMission()

	if self.isServer then
		if self.dogBall ~= nil and not self.dogBall.isDeleted then
			self.dogBall:delete()

			self.dogBall = nil
		end

		if self.dog ~= nil and not self.dog.isDeleted then
			self.dog:delete()

			self.dog = nil
		end
	end

	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
	end

	unregisterObjectClassName(self)
	Doghouse:superClass().delete(self)
end

function Doghouse:getCanBePlacedAt(x, y, z, distance, farmId)
	local canBePlaced = Doghouse:superClass().getCanBePlacedAt(self, x, y, z, distance, farmId)

	return canBePlaced and not self:isDoghouseRegistered()
end

function Doghouse:canBuy()
	local canBuy = AnimalHusbandry:superClass().canBuy(self)

	return canBuy and not self:isDoghouseRegistered(), g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
end

function Doghouse:finalizePlacement()
	Doghouse:superClass().finalizePlacement(self)

	local xmlFile = loadXMLFile("TempXML", self.configFileName)

	if xmlFile == 0 then
		return false
	end

	self.spawnNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.dogHouse.dog#node"))

	if self.isServer then
		local posX, posY, posZ = getWorldTranslation(self.spawnNode)
		local xmlFilename = Utils.getFilename(getXMLString(xmlFile, "placeable.dogHouse.dog#xmlFilename"), self.baseDirectory)
		self.dog = Dog:new(self.isServer, self.isClient)

		self.dog:setOwnerFarmId(self:getOwnerFarmId(), true)
		self.dog:load(self, xmlFilename, posX, posY, posZ)
		self.dog:register()
	end

	self:registerDoghouseToMission()

	self.namePlateNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.dogHouse.nameplate#node"))
	self.ballSpawnNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.dogHouse.ball#node"))

	if self.isServer then
		local dogBallFilename = Utils.getFilename(getXMLString(xmlFile, "placeable.dogHouse.ball#filename"), self.baseDirectory)
		local x, y, z = getWorldTranslation(self.ballSpawnNode)
		local rx, ry, rz = getWorldRotation(self.ballSpawnNode)
		self.dogBall = DogBall:new(self.isServer, self.isClient)

		self.dogBall:setOwnerFarmId(self:getOwnerFarmId(), true)
		self.dogBall:load(dogBallFilename, x, y, z, rx, ry, rz, self)
		self.dogBall:register()
	end

	self.triggerNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.dogHouse.playerInteractionTrigger#node"))

	if self.triggerNode ~= nil then
		addTrigger(self.triggerNode, "playerInteractionTriggerCallback", self)
	end

	self.foodNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.dogHouse.bowl#foodNode"))

	delete(xmlFile)

	if self.foodNode ~= nil then
		setVisibility(self.foodNode, false)

		return true
	end

	return false
end

function Doghouse:readStream(streamId, connection)
	Doghouse:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		self.dog = NetworkUtil.readNodeObject(streamId)

		if self.dog ~= nil then
			self.dog.spawner = self
		end

		setVisibility(self.foodNode, streamReadBool(streamId))
	end
end

function Doghouse:writeStream(streamId, connection)
	Doghouse:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.dog)
		streamWriteBool(streamId, getVisibility(self.foodNode))
	end
end

function Doghouse:readUpdateStream(streamId, timestamp, connection)
	Doghouse:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		setVisibility(self.foodNode, streamReadBool(streamId))
	end
end

function Doghouse:writeUpdateStream(streamId, connection, dirtyMask)
	Doghouse:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		streamWriteBool(streamId, getVisibility(self.foodNode))
	end
end

function Doghouse:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not Doghouse:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	return self.dog:loadFromXMLFile(xmlFile, key .. ".dog", resetVehicles)
end

function Doghouse:saveToXMLFile(xmlFile, key, usedModNames)
	Doghouse:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.dog:saveToXMLFile(xmlFile, key .. ".dog", usedModNames)
end

function Doghouse:update(dt)
	Doghouse:superClass().update(self, dt)
end

function Doghouse:setFoodVisibility(visibility)
	if self.foodNode ~= nil then
		setVisibility(self.foodNode, visibility)
		self:raiseDirtyFlags(self.dirtyFlag)
	end
end

function Doghouse:drawDogName()
	setTextColor(0.843, 0.745, 0.705, 1)
	setTextAlignment(RenderText.ALIGN_CENTER)

	local x, y, z = getWorldTranslation(self.namePlateNode)
	local rx, ry, rz = getWorldRotation(self.namePlateNode)

	renderText3D(x, y, z, rx, ry, rz, 0.04, self.dog.name)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

function Doghouse:playerInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode and g_currentMission.player.farmId == self:getOwnerFarmId() then
		if onEnter then
			self.isActivatable = true
		elseif onLeave then
			self.isActivatable = false
		end
	end
end

function Doghouse:onActivateObject()
	self:raiseActive()
end

function Doghouse:getIsActivatable()
	return self.isActivatable
end

function Doghouse:drawActivate()
	g_currentMission:showFillDogBowlContext()
end

function Doghouse:setOwnerFarmId(farmId, noEventSend)
	Doghouse:superClass().setOwnerFarmId(self, farmId, noEventSend)

	if self.isServer then
		if self.dog ~= nil then
			self.dog:setOwnerFarmId(farmId, noEventSend)
		end

		if self.dogBall ~= nil then
			self.dogBall:setOwnerFarmId(farmId, noEventSend)
		end
	end
end

function Doghouse:isDoghouseRegistered()
	local dogHouse = g_currentMission:getDoghouse(self:getOwnerFarmId())

	return dogHouse ~= nil
end

function Doghouse:registerDoghouseToMission()
	if not self:isDoghouseRegistered() then
		g_currentMission.doghouses[self] = self

		return true
	end

	return false
end

function Doghouse:unregisterDoghouseToMission()
	g_currentMission.doghouses[self] = nil

	return true
end
