DealerStrategie = {}
local DealerStrategie_mt = Class(DealerStrategie, AbstractAnimalStrategy)

function DealerStrategie:new(parent, l10n)
	local self = AbstractAnimalStrategy:new(DealerStrategie_mt, parent, l10n)
	self.validHusbandrySubTypes = {}
	self.subTypeToHusbandry = {}

	return self
end

function DealerStrategie:initSourceItems()
	self.validHusbandrySubTypes = {}
	self.sourceItems = {}
	local animals = self.parent.loadingTrigger:getAnimals()

	if animals == nil then
		animals = g_animalManager:getAnimals()
	end

	for _, animal in ipairs(animals) do
		local husbandry = g_currentMission:getHusbandryByAnimalType(animal.type)

		for _, subType in ipairs(animal.subTypes) do
			local item = AnimalItem.create(AnimalItem.STATE_TEMPLATE, subType, nil, )

			table.insert(self.sourceItems, item)

			if husbandry ~= nil then
				self.subTypeToHusbandry[subType] = husbandry
				self.validHusbandrySubTypes[subType] = true
			end
		end
	end
end

function DealerStrategie:initTargetItems()
	self.targetItems = {}

	for _, animal in ipairs(g_animalManager:getAnimals()) do
		local husbandry = g_currentMission:getHusbandryByAnimalType(animal.type)

		if husbandry ~= nil then
			for _, animal in ipairs(husbandry:getAnimals()) do
				local name = nil

				if animal.getName ~= nil then
					name = animal:getName()
				end

				self.subTypeToHusbandry[animal.subType] = husbandry
				local item = AnimalItem.create(AnimalItem.STATE_STOCK, animal:getSubType(), name, NetworkUtil.getObjectId(animal))

				table.insert(self.targetItems, item)
			end
		end
	end
end

function DealerStrategie:moveToSource(index)
	local item = self.targetItems[index]

	if item == nil then
		return false
	end

	if not item:getCanBeTransfered() then
		self.parent.inUseCallback()

		return false
	end

	self:toSource(index)

	return true
end

function DealerStrategie:moveToTarget(index)
	local item = self.sourceItems[index]

	if item == nil then
		return false
	end

	if self.validHusbandrySubTypes[item.subType] == nil then
		self.parent:noValidHusbandryCallback(item.subType)

		return false
	end

	local husbandry = self.subTypeToHusbandry[item.subType]
	local maxNumAnimals = husbandry:getMaxNumAnimals()
	local numAnimals = 0

	for _, targetItem in ipairs(self.targetItems) do
		if self.subTypeToHusbandry[targetItem.subType] == husbandry then
			numAnimals = numAnimals + 1
		end
	end

	if maxNumAnimals <= numAnimals then
		self.parent:husbandryIsFullCallback()

		return false
	end

	local state = item.state

	if item.state == AnimalItem.STATE_TEMPLATE then
		state = AnimalItem.STATE_NEW
	end

	self:toTarget(index)

	return true
end

function DealerStrategie:getIsDealer()
	return true
end

function DealerStrategie:applyChanges()
	if not self:getHasEnoughMoney() then
		self.parent.notEnoughMoneyCallback()

		return false
	end

	local addAnimals = {}

	for _, item in ipairs(self.targetItems) do
		if item.state == AnimalItem.STATE_NEW then
			table.insert(addAnimals, {
				husbandry = self.subTypeToHusbandry[item.subType],
				fillTypeIndex = item.subType.fillType,
				name = item.name,
				price = item.price
			})
		end
	end

	local removeAnimals = {}

	for _, item in ipairs(self.sourceItems) do
		if item.state == AnimalItem.STATE_STOCK then
			table.insert(removeAnimals, {
				husbandry = self.subTypeToHusbandry[item.subType],
				animalId = item.animalId,
				price = item.price
			})
		end
	end

	local buy, sell, fee, _ = self:getPrices()

	if g_currentMission:getIsServer() then
		AnimalDealerEvent.runLocal(addAnimals, removeAnimals, buy, sell, fee)
	else
		AnimalDealerEvent.sendEvent(addAnimals, removeAnimals, buy, sell, fee)
	end
end
