AnimalDealerEvent = {}
local AnimalDealerEvent_mt = Class(AnimalDealerEvent, Event)

InitStaticEventClass(AnimalDealerEvent, "AnimalDealerEvent", EventIds.EVENT_ANIMAL_DEALER)

function AnimalDealerEvent:emptyNew()
	local self = Event:new(AnimalDealerEvent_mt)

	return self
end

function AnimalDealerEvent:new(buyAnimals, sellAnimals, buyPrice, sellPrice, feePrice)
	local self = AnimalDealerEvent:emptyNew()
	self.buyAnimals = buyAnimals
	self.sellAnimals = sellAnimals
	self.buyPrice = buyPrice
	self.sellPrice = sellPrice
	self.feePrice = feePrice

	return self
end

function AnimalDealerEvent:readStream(streamId, connection)
	self.buyAnimals = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		local husbandry, trailer = nil

		if streamReadBool(streamId) then
			husbandry = NetworkUtil.readNodeObject(streamId)
		else
			trailer = NetworkUtil.readNodeObject(streamId)
		end

		local data = {
			fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		}

		if streamReadBool(streamId) then
			data.name = streamReadString(streamId)
		end

		data.husbandry = husbandry
		data.trailer = trailer

		table.insert(self.buyAnimals, data)
	end

	self.sellAnimals = {}
	local numAnimals = streamReadUIntN(streamId, HusbandryModuleAnimal.SEND_NUM_BITS)

	for i = 1, numAnimals do
		local husbandry, trailer = nil

		if streamReadBool(streamId) then
			husbandry = NetworkUtil.readNodeObject(streamId)
		else
			trailer = NetworkUtil.readNodeObject(streamId)
		end

		local animalId = NetworkUtil.readNodeObjectId(streamId)

		table.insert(self.sellAnimals, {
			husbandry = husbandry,
			trailer = trailer,
			animalId = animalId
		})
	end

	self.buyPrice = -streamReadInt32(streamId)
	self.sellPrice = streamReadInt32(streamId)
	self.feePrice = -streamReadInt32(streamId)

	self:run(connection)
end

function AnimalDealerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, #self.buyAnimals, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.buyAnimals) do
		if streamWriteBool(streamId, animal.husbandry ~= nil) then
			NetworkUtil.writeNodeObject(streamId, animal.husbandry)
		else
			NetworkUtil.writeNodeObject(streamId, animal.trailer)
		end

		streamWriteUIntN(streamId, animal.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)

		if streamWriteBool(streamId, animal.name ~= nil) then
			streamWriteString(streamId, animal.name)
		end
	end

	streamWriteUIntN(streamId, #self.sellAnimals, HusbandryModuleAnimal.SEND_NUM_BITS)

	for _, animal in ipairs(self.sellAnimals) do
		if streamWriteBool(streamId, animal.husbandry ~= nil) then
			NetworkUtil.writeNodeObject(streamId, animal.husbandry)
		else
			NetworkUtil.writeNodeObject(streamId, animal.trailer)
		end

		NetworkUtil.writeNodeObjectId(streamId, animal.animalId)
	end

	streamWriteInt32(streamId, math.abs(self.buyPrice))
	streamWriteInt32(streamId, self.sellPrice)
	streamWriteInt32(streamId, math.abs(self.feePrice))
end

function AnimalDealerEvent:run(connection)
	AnimalDealerEvent.runLocal(self.buyAnimals, self.sellAnimals, self.buyPrice, self.sellPrice, self.feePrice)
end

function AnimalDealerEvent.sendEvent(buyAnimals, sellAnimals, buyPrice, sellPrice, feePrice)
	if not g_currentMission:getIsServer() then
		g_client:getServerConnection():sendEvent(AnimalDealerEvent:new(buyAnimals, sellAnimals, buyPrice, sellPrice, feePrice))
	end
end

function AnimalDealerEvent.runLocal(buyAnimals, sellAnimals, buyPrice, sellPrice, feePrice)
	local husbandry, trailer = nil

	for _, data in ipairs(sellAnimals) do
		local animal = NetworkUtil.getObject(data.animalId)

		if data.husbandry ~= nil then
			data.husbandry:removeSingleAnimal(animal)

			husbandry = data.husbandry or husbandry
		else
			data.trailer:removeAnimal(animal)

			trailer = data.trailer or trailer
		end

		animal:delete()
	end

	if buyAnimals ~= nil then
		local sendAnimals = {}

		for _, data in ipairs(buyAnimals) do
			local animal = Animal.createFromFillType(g_currentMission:getIsServer(), g_currentMission:getIsClient(), data.husbandry, data.fillTypeIndex)

			if data.name ~= nil then
				animal:setName(data.name)
			end

			animal:register()

			if data.husbandry ~= nil then
				if sendAnimals[data.husbandry] == nil then
					sendAnimals[data.husbandry] = {}
				end

				table.insert(sendAnimals[data.husbandry], animal)

				husbandry = data.husbandry or husbandry
			else
				trailer = data.trailer or trailer

				data.trailer:addAnimal(animal)
			end
		end

		for husbandry, animals in pairs(sendAnimals) do
			husbandry:addAnimals(animals)
		end
	end

	local ownerFarmId = nil

	if husbandry ~= nil then
		ownerFarmId = husbandry:getOwnerFarmId()
	elseif trailer ~= nil then
		ownerFarmId = trailer:getActiveFarm()
	end

	if ownerFarmId ~= nil then
		if sellPrice > 0 then
			g_currentMission:addMoney(sellPrice, ownerFarmId, MoneyType.SOLD_ANIMALS, true, true)
		end

		if buyPrice < 0 then
			g_currentMission:addMoney(buyPrice, ownerFarmId, MoneyType.NEW_ANIMALS_COST, true, true)
		end

		if feePrice < 0 then
			g_currentMission:addMoney(feePrice, ownerFarmId, MoneyType.OTHER, true, true)
		end
	end
end
