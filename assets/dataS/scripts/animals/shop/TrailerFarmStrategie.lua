TrailerFarmStrategie = {}
local TrailerFarmStrategie_mt = Class(TrailerFarmStrategie, AbstractAnimalStrategy)

function TrailerFarmStrategie:new(parent, l10n, trailer, husbandry)
	local self = AbstractAnimalStrategy:new(TrailerFarmStrategie_mt, parent, l10n)
	self.husbandry = husbandry
	self.trailer = trailer
	self.visualTrailer = VisualTrailer:new(trailer)
	self.baseSourceItems = {}
	self.baseNumSourceItems = 0
	self.baseTargetItems = {}
	self.baseNumTargetItems = 0

	return self
end

function TrailerFarmStrategie:initSourceItems()
	self.visualTrailer:load()

	self.sourceItems = {}

	for _, item in ipairs(self.visualTrailer:getAnimalItems()) do
		table.insert(self.sourceItems, item)

		self.baseSourceItems[item] = true
	end

	self.baseNumSourceItems = #self.sourceItems
end

function TrailerFarmStrategie:initTargetItems()
	self.targetItems = {}

	for _, animal in ipairs(self.husbandry:getAnimals()) do
		local name = nil

		if animal.getName ~= nil then
			name = animal:getName()
		end

		local item = AnimalItem.create(AnimalItem.STATE_STOCK, animal:getSubType(), name, NetworkUtil.getObjectId(animal))

		table.insert(self.targetItems, item)

		self.baseTargetItems[item] = true
	end

	self.baseNumTargetItems = #self.targetItems
end

function TrailerFarmStrategie:moveToSource(index)
	local item = self.targetItems[index]

	if item == nil then
		return false
	end

	if not item:getCanBeTransfered() then
		self.parent.inUseCallback()

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

	local targetItem = self:toSource(index)

	self.visualTrailer:addItem(targetItem)

	return true
end

function TrailerFarmStrategie:moveToTarget(index)
	local item = self.sourceItems[index]

	if item == nil then
		return false
	end

	if not self.husbandry:getSupportsSubType(item.subType) then
		self.parent:invalidAnimalTypeCallback(item.subType)

		return false
	end

	local maxNumAnimals = self.husbandry:getMaxNumAnimals()
	local numAnimals = #self.targetItems

	if maxNumAnimals <= numAnimals then
		self.parent:husbandryIsFullCallback()

		return false
	end

	self:toTarget(index)
	self.visualTrailer:removeItem(item)

	return true
end

function TrailerFarmStrategie:getSourceName()
	return self.trailer:getName()
end

function TrailerFarmStrategie:getPrices()
	return 0, 0, 0, 0
end

function TrailerFarmStrategie:applyChanges()
	local moveToTrailerAnimals = {}

	for _, item in ipairs(self.sourceItems) do
		if self.baseSourceItems[item] == nil then
			table.insert(moveToTrailerAnimals, NetworkUtil.getObject(item.animalId))
		end
	end

	local moveToHusbandryAnimals = {}

	for _, item in ipairs(self.targetItems) do
		if self.baseTargetItems[item] == nil then
			table.insert(moveToHusbandryAnimals, NetworkUtil.getObject(item.animalId))
		end
	end

	if g_currentMission:getIsServer() then
		FarmTrailerEvent.runLocal(self.husbandry, self.trailer, moveToTrailerAnimals, moveToHusbandryAnimals)
	else
		FarmTrailerEvent.sendEvent(self.husbandry, self.trailer, moveToTrailerAnimals, moveToHusbandryAnimals)
	end

	return true
end

function TrailerFarmStrategie:getHasChanges()
	if self.baseNumTargetItems ~= #self.targetItems or self.baseNumSourceItems ~= #self.sourceItems then
		return true
	end

	for _, item in ipairs(self.sourceItems) do
		if self.baseSourceItems[item] == nil then
			return true
		end
	end

	for _, item in ipairs(self.targetItems) do
		if self.baseTargetItems[item] == nil then
			return true
		end
	end

	return false
end
