AnimalItem = {
	STATE_TEMPLATE = 0,
	STATE_NEW = 1,
	STATE_STOCK = 2
}
local AnimalItem_mt = Class(AnimalItem)

function AnimalItem:new(state, subType, name, animalId)
	local self = setmetatable({}, AnimalItem_mt)
	self.state = state
	self.subType = subType
	self.name = name
	self.animalId = animalId
	self.price = subType.storeInfo.buyPrice

	if animalId ~= nil then
		local animal = NetworkUtil.getObject(animalId)

		if animal ~= nil then
			self.price = animal:getValue()
		end
	end

	return self
end

function AnimalItem.create(state, subType, name, animalId)
	return AnimalItem:new(state, subType, name, animalId)
end

function AnimalItem:getCanBeTransfered()
	local animal = NetworkUtil.getObject(self.animalId)

	if animal ~= nil then
		return not animal:getIsInUse()
	end

	return true
end
