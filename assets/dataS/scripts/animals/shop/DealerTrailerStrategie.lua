DealerTrailerStrategie = {}
local DealerTrailerStrategie_mt = Class(DealerTrailerStrategie, AbstractAnimalStrategy)

function DealerTrailerStrategie:new(parent, l10n, trailer)
	local self = AbstractAnimalStrategy:new(DealerTrailerStrategie_mt, parent, l10n)
	self.trailer = trailer
	self.visualTrailer = VisualTrailer:new(trailer)

	return self
end

function DealerTrailerStrategie:initSourceItems()
	self.visualTrailer:load()

	self.sourceItems = {}
	local animals = self.parent.loadingTrigger:getAnimals()

	if animals == nil then
		animals = g_animalManager:getAnimals()
	end

	for _, animal in ipairs(animals) do
		for _, subType in ipairs(animal.subTypes) do
			local item = AnimalItem.create(AnimalItem.STATE_TEMPLATE, subType, nil, )

			table.insert(self.sourceItems, item)
		end
	end
end

function DealerTrailerStrategie:initTargetItems()
	self.targetItems = {}

	for _, item in ipairs(self.visualTrailer:getAnimalItems()) do
		table.insert(self.targetItems, item)
	end
end

function DealerTrailerStrategie:getTargetName()
	return self.trailer:getName()
end

function DealerTrailerStrategie:moveToSource(index)
	local item = self.targetItems[index]

	if item == nil then
		return false
	end

	self:toSource(index)
	self.visualTrailer:removeItem(item)

	return true
end

function DealerTrailerStrategie:moveToTarget(index)
	local item = self.sourceItems[index]

	if item == nil then
		return false
	end

	local supported = self.visualTrailer:getSupportsItem(item)

	if not supported then
		self.parent:animalNotSupportedByTrailerCallback(item.subType)

		return false
	end

	local canBeAdded = self.visualTrailer:getCanAddItem(item)

	if not canBeAdded then
		self.parent:canNotAddToTrailerCallback(item.subType)

		return false
	end

	local isFull = self.visualTrailer:getIsFull(item)

	if isFull then
		self.parent:trailerFullCallback()

		return false
	end

	local targetItem = self:toTarget(index)

	self.visualTrailer:addItem(targetItem)

	return true
end

function DealerTrailerStrategie:getIsDealer()
	return true
end

function DealerTrailerStrategie:applyChanges()
	if not self:getHasEnoughMoney() then
		self.parent.notEnoughMoneyCallback()

		return false
	end

	local addAnimals = {}

	for _, item in ipairs(self.targetItems) do
		if item.state == AnimalItem.STATE_NEW then
			table.insert(addAnimals, {
				trailer = self.trailer,
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
				trailer = self.trailer,
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
