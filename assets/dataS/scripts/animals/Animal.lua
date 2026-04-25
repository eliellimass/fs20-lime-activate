Animal = {}
local Animal_mt = Class(Animal, Object)

InitStaticObjectClass(Animal, "Animal", ObjectIds.OBJECT_ANIMAL)

function Animal:new(isServer, isClient, owner, fillTypeIndex, customMt)
	local self = Object:new(isServer, isClient, customMt or Animal_mt)
	self.owner = owner
	self.module = nil

	if owner ~= nil then
		self.module = owner:getHusbandryModule()
	end

	self.fillTypeIndex = fillTypeIndex
	self.subType = g_animalManager:getAnimalByFillType(fillTypeIndex)
	self.dirtScaleSent = 0
	self.dirtScale = 0
	self.visualId = nil
	self.animalDirtyFlag = self:getNextDirtyFlag()

	return self
end

function Animal:setOwner(owner)
	self.owner = owner
	self.module = nil

	if owner ~= nil then
		self.module = owner:getHusbandryModule()
	end
end

function Animal:getOwner()
	return self.owner
end

function Animal:delete()
	if self.owner ~= nil then
		self.owner:removeSingleAnimal(self)
	end

	Animal:superClass().delete(self)
end

function Animal:readStream(streamId)
	Animal:superClass().readStream(self, streamId)

	self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self.dirtScale = streamReadFloat32(streamId)
	self.subType = g_animalManager:getAnimalByFillType(self.fillTypeIndex)
end

function Animal:writeStream(streamId)
	Animal:superClass().writeStream(self, streamId)
	streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
	streamWriteFloat32(streamId, self.dirtScale)

	self.dirtScaleSent = self.dirtScale
end

function Animal:readUpdateStream(streamId, timestamp, connection)
	Animal:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		self:setDirtScale(NetworkUtil.readCompressedPercentages(streamId, 7))
	end

	g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)
end

function Animal:writeUpdateStream(streamId, connection, dirtyMask)
	Animal:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.animalDirtyFlag) ~= 0) then
		NetworkUtil.writeCompressedPercentages(streamId, self.dirtScale, 7)
	end
end

function Animal:loadFromXMLFile(xmlFile, key)
	local dirtScale = getXMLFloat(xmlFile, key .. "#dirtScale") or self.dirtScale

	self:setDirtScale(dirtScale)
end

function Animal:saveToXMLFile(xmlFile, key, usedModNames)
	local fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(self.fillTypeIndex), "unknown")

	setXMLString(xmlFile, key .. "#fillType", fillTypeName)
	setXMLFloat(xmlFile, key .. "#dirtScale", self.dirtScale)
end

function Animal:getIsInUse()
	return false
end

function Animal:setVisualId(visualId)
	self.visualId = visualId
end

function Animal:getVisualId()
	return self.visualId
end

function Animal:getFillTypeIndex()
	return self.fillTypeIndex
end

function Animal:getSubType()
	return self.subType
end

function Animal:getValue()
	return math.ceil(self.subType.storeInfo.sellPrice * self:getValueScale())
end

function Animal:getValueScale()
	return 1
end

function Animal:setDirtScale(scale)
	self.dirtScale = MathUtil.clamp(scale, 0, 1)

	if math.abs(self.dirtScale - self.dirtScaleSent) > 0.01 then
		self.dirtScaleSent = self.dirtScale

		self:raiseDirtyFlags(self.animalDirtyFlag)
		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self.owner)
	end
end

function Animal:getDirtScale()
	return self.dirtScale
end

function Animal:clean(dt)
	local dirt = math.max(0, self.dirtScale - dt / self.subType.dirt.cleanDuration)

	self:setDirtScale(dirt)
end

function Animal.createFromXMLFile(xmlFile, key, isServer, isClient, husbandry)
	local fillTypeName = getXMLString(xmlFile, key .. "#fillType")
	local class, fillTypeIndex = g_animalManager:getClassObjectFromFillTypeName(fillTypeName)

	if class ~= nil then
		local animal = class:new(isServer, isClient, husbandry, fillTypeIndex)

		animal:loadFromXMLFile(xmlFile, key)

		return animal
	end

	g_logManager:warning("Could not load animal. No animal defined for fillType '%s'!", tostring(fillTypeName))

	return nil
end

function Animal.createFromFillType(isServer, isClient, husbandry, fillTypeIndex)
	local class, _ = g_animalManager:getClassObjectFromFillTypeIndex(fillTypeIndex)

	if class ~= nil then
		return class:new(isServer, isClient, husbandry, fillTypeIndex)
	end

	g_logManager:warning("Could not load animal. No animal defined for fillType '%s'!", tostring(fillTypeName))

	return nil
end
