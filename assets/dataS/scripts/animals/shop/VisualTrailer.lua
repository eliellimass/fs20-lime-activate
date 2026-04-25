VisualTrailer = {}
local VisualTrailer_mt = Class(VisualTrailer)

function VisualTrailer:new(trailer)
	local self = setmetatable({}, VisualTrailer_mt)
	self.trailer = trailer

	return self
end

function VisualTrailer:load()
	self.maxAnimals = {}

	for _, place in ipairs(self.trailer:getAnimalPlaces()) do
		self.maxAnimals[place.animalType] = #place.slots
	end

	self.animalItems = {}

	for _, animal in ipairs(self.trailer:getAnimals()) do
		local name = nil

		if animal.getName ~= nil then
			name = animal:getName()
		end

		local item = AnimalItem.create(AnimalItem.STATE_STOCK, animal:getSubType(), name, NetworkUtil.getObjectId(animal))

		table.insert(self.animalItems, item)
	end

	self.animalType = self.trailer:getCurrentAnimalType()
end

function VisualTrailer:getSupportsItem(item)
	return self.maxAnimals[item.subType.type] ~= nil
end

function VisualTrailer:getIsFull(item)
	local maxAnimals = self.maxAnimals[item.subType.type]

	return maxAnimals <= #self.animalItems
end

function VisualTrailer:getCanAddItem(item)
	return self.animalType == nil or self.animalType == item.subType.type
end

function VisualTrailer:addItem(item)
	table.insert(self.animalItems, item)

	self.animalType = item.subType.type
end

function VisualTrailer:removeItem(itemToRemove)
	for k, item in ipairs(self.animalItems) do
		if item == itemToRemove then
			table.remove(self.animalItems, k)

			break
		end
	end

	if #self.animalItems == 0 then
		self.animalType = nil
	end
end

function VisualTrailer:getAnimalItems()
	return self.animalItems
end
