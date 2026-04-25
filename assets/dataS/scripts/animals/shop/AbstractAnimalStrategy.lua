AbstractAnimalStrategy = {
	new = function (self, customMt, parent, l10n)
		local self = setmetatable({}, customMt or Class(AbstractAnimalStrategy))
		self.parent = parent
		self.l10n = l10n
		self.sourceItems = {}
		self.targetItems = {}

		return self
	end,
	initSourceItems = function (self)
	end,
	initTargetItems = function (self)
	end,
	getSourceItems = function (self)
		return self.sourceItems
	end,
	getTargetItems = function (self)
		return self.targetItems
	end,
	getSourceName = function (self)
		return self.l10n:getText(AnimalController.SYMBOL_L10N.DEALER)
	end,
	getTargetName = function (self)
		return self.l10n:getText(AnimalController.SYMBOL_L10N.FARM)
	end,
	getHasChanges = function (self)
		return self.hasChanges
	end,
	applyChanges = function (self)
	end,
	getIsDealer = function (self)
		return false
	end,
	getHasEnoughMoney = function (self)
		local _, _, _, totalPrice = self:getPrices()

		return -totalPrice < self.parent:getBalance()
	end,
	getPrices = function (self)
		local buyPrice = 0
		local sellPrice = 0
		local fee = 0

		for _, item in ipairs(self.targetItems) do
			if item.state == AnimalItem.STATE_NEW then
				local subType = item.subType
				buyPrice = buyPrice - item.price
				fee = fee + subType.storeInfo.transportPrice
			end
		end

		for _, item in ipairs(self.sourceItems) do
			if item.state == AnimalItem.STATE_STOCK then
				local subType = item.subType
				sellPrice = sellPrice + item.price
				fee = fee + subType.storeInfo.transportPrice
			end
		end

		local feePrice = 0

		if self.trailer == nil then
			feePrice = -fee
		end

		local totalPrice = buyPrice + sellPrice + feePrice

		return buyPrice, sellPrice, feePrice, totalPrice
	end,
	toSource = function (self, index, state)
		local item = self.targetItems[index]

		if item == nil then
			return false
		end

		local target = nil
		local item = table.remove(self.targetItems, index)

		if item.state ~= AnimalItem.STATE_NEW then
			target = item

			table.insert(self.sourceItems, item)
		end

		return target
	end,
	toTarget = function (self, index, state)
		local item = self.sourceItems[index]

		if item == nil then
			return false
		end

		local target = item

		if item.state == AnimalItem.STATE_TEMPLATE then
			local name = nil

			if item.subType.hasName then
				name = g_animalNameManager:getRandomName()
			end

			target = AnimalItem.create(AnimalItem.STATE_NEW, item.subType, name, item.animalId)
		else
			table.remove(self.sourceItems, index)
		end

		table.insert(self.targetItems, target)

		return target
	end,
	getHasChanges = function (self)
		for _, item in ipairs(self.sourceItems) do
			if item.state == AnimalItem.STATE_STOCK then
				return true
			end
		end

		for _, item in ipairs(self.targetItems) do
			if item.state == AnimalItem.STATE_NEW then
				return true
			end
		end
	end
}
