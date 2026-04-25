ShopDisplayItem = {}
local ShopDisplayItem_mt = Class(ShopDisplayItem)
ShopDisplayItem.NO_CONCRETE_ITEM = {}

function ShopDisplayItem:new(storeItem, concreteItem, attributeIconProfiles, attributeValues, fillTypeFilenames, foodFillTypeIconFilenames, seedTypeFilenames, functionText, orderValue)
	local self = setmetatable({}, ShopDisplayItem_mt)
	self.storeItem = storeItem
	self.concreteItem = concreteItem or ShopDisplayItem.NO_CONCRETE_ITEM
	self.attributeIconProfiles = attributeIconProfiles or {}
	self.attributeValues = attributeValues or {}
	self.fillTypeFilenames = fillTypeFilenames or {}
	self.foodFillTypeIconFilenames = foodFillTypeIconFilenames or {}
	self.seedTypeFilenames = seedTypeFilenames or {}
	self.functionText = functionText
	self.orderValue = orderValue

	return self
end

function ShopDisplayItem:getSellPrice()
	if self.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
		return self.concreteItem:getSellPrice()
	else
		return self.storeItem.price
	end
end

function ShopDisplayItem:getSortId()
	if self.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
		return self.concreteItem.id
	else
		return self.storeItem.xmlFilename
	end
end
