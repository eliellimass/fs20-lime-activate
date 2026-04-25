DealerFarmStrategie = {}
local DealerFarmStrategie_mt = Class(DealerFarmStrategie, AbstractAnimalStrategy)

function DealerFarmStrategie:new(parent, l10n, husbandry)
	local self = AbstractAnimalStrategy:new(DealerFarmStrategie_mt, parent, l10n)
	self.husbandry = husbandry

	return self
end

function DealerFarmStrategie:initSourceItems()
	self.sourceItems = {}
	local animal = g_animalManager:getAnimalsByType(self.husbandry:getAnimalType())

	if animal ~= nil then
		for _, subType in ipairs(animal.subTypes) do
			local item = AnimalItem.create(AnimalItem.STATE_TEMPLATE, subType, nil, )

			table.insert(self.sourceItems, item)
		end
	end
end

function DealerFarmStrategie:initTargetItems()
	self.targetItems = {}

	for _, animal in ipairs(self.husbandry:getAnimals()) do
		local name = nil

		if animal.getName ~= nil then
			name = animal:getName()
		end

		local item = AnimalItem.create(AnimalItem.STATE_STOCK, animal:getSubType(), name, NetworkUtil.getObjectId(animal))

		table.insert(self.targetItems, item)
	end
end

function DealerFarmStrategie:moveToSource(index)
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

function DealerFarmStrategie:moveToTarget(index)
	local item = self.sourceItems[index]

	if item == nil then
		return false
	end

	local maxNumAnimals = self.husbandry:getMaxNumAnimals()
	local numAnimals = #self.targetItems

	if maxNumAnimals <= numAnimals then
		self.parent:husbandryIsFullCallback()

		return false
	end

	self:toTarget(index)

	return true
end

function DealerFarmStrategie:getIsDealer()
	return true
end

function DealerFarmStrategie:applyChanges()
	if not self:getHasEnoughMoney() then
		self.parent.notEnoughMoneyCallback()

		return false
	end

	local addAnimals = {}

	for _, item in ipairs(self.targetItems) do
		if item.state == AnimalItem.STATE_NEW then
			table.insert(addAnimals, {
				husbandry = self.husbandry,
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
				husbandry = self.husbandry,
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

	return true
end
