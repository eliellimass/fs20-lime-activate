AnimalController = {}
local AnimalController_mt = Class(AnimalController)
AnimalController.MODE_DEALER_TRAILER = 1
AnimalController.MODE_DEALER_FARM = 2
AnimalController.MODE_FARM_TRAILER = 3

function AnimalController:new(l10n)
	local self = setmetatable({}, AnimalController_mt)
	self.l10n = l10n
	self.trailer = nil
	self.husbandry = nil
	self.loadingTrigger = nil
	self.lockAnimalCallback = nil
	self.transferData = {}
	self.selectedAnimalIndex = 0
	self.animalList = nil
	self.sourceAnimals = {}
	self.targetAnimals = {}

	return self
end

function AnimalController:close()
	if self.loadingTrigger ~= nil then
		self.loadingTrigger:updateActivatableObject()
	end

	self:reset()
end

function AnimalController:reset()
	self.trailer = nil
	self.husbandry = nil
	self.loadingTrigger = nil
end

function AnimalController:initialize()
	if self.husbandry == nil and self.trailer == nil then
		self.strategy = DealerStrategie:new(self, self.l10n)
	elseif self.husbandry ~= nil and self.trailer == nil then
		self.strategy = DealerFarmStrategie:new(self, self.l10n, self.husbandry)
	elseif self.husbandry == nil and self.trailer ~= nil then
		self.strategy = DealerTrailerStrategie:new(self, self.l10n, self.trailer)
	else
		self.strategy = TrailerFarmStrategie:new(self, self.l10n, self.trailer, self.husbandry)
	end

	self:initSourceItems()
	self:initTargetItems()
end

function AnimalController:getBalance()
	local money = 10000

	if g_currentMission ~= nil then
		money = g_currentMission:getMoney()
	end

	return money
end

function AnimalController:getHasChanges()
	return self.strategy:getHasChanges()
end

function AnimalController:applyChanges()
	return self.strategy:applyChanges()
end

function AnimalController:setTrailer(trailer)
	self.trailer = trailer
end

function AnimalController:setHusbandry(husbandry)
	self.husbandry = husbandry
end

function AnimalController:setLoadingTrigger(loadingTrigger)
	self.loadingTrigger = loadingTrigger
end

function AnimalController:getIsDealer()
	return self.strategy:getIsDealer()
end

function AnimalController:getSourceName()
	return self.strategy:getSourceName()
end

function AnimalController:getTargetName()
	return self.strategy:getTargetName()
end

function AnimalController:initTargetItems()
	self.strategy:initTargetItems()
end

function AnimalController:initSourceItems()
	self.strategy:initSourceItems()
end

function AnimalController:getSourceItems()
	return self.strategy:getSourceItems()
end

function AnimalController:getTargetItems()
	return self.strategy:getTargetItems()
end

function AnimalController:moveToTarget(index)
	local success = self.strategy:moveToTarget(index)

	if success then
		self.sourceUpdateCallback()
		self.targetUpdateCallback()
	end
end

function AnimalController:moveToSource(index)
	local success = self.strategy:moveToSource(index)

	if success then
		self.sourceUpdateCallback()
		self.targetUpdateCallback()
	end
end

function AnimalController:getPrices()
	return self.strategy:getPrices()
end

function AnimalController:setSourceUpdateCallback(callback, target)
	function self.sourceUpdateCallback()
		callback(target)
	end
end

function AnimalController:setNotEnoughMoneyCallback(callback, target)
	function self.notEnoughMoneyCallback()
		callback(target)
	end
end

function AnimalController:setAnimalInUseCallback(callback, target)
	function self.inUseCallback()
		callback(target)
	end
end

function AnimalController:setTargetUpdateCallback(callback, target)
	function self.targetUpdateCallback()
		callback(target)
	end
end

function AnimalController:setNoValidHusbandryCallback(callback, target)
	function self.noValidHusbandryCallback(subType)
		callback(target, subType)
	end
end

function AnimalController:setInvalidAnimalTypeCallback(callback, target)
	function self.invalidAnimalTypeCallback(subType)
		callback(target, subType)
	end
end

function AnimalController:setHusbandryIsFullCallback(callback, target)
	function self.husbandryIsFullCallback()
		callback(target)
	end
end

function AnimalController:setTrailerFullCallback(callback, target)
	function self.trailerFullCallback()
		callback(target)
	end
end

function AnimalController:setAnimalNotSupportedByTrailerCallback(callback, target)
	function self.animalNotSupportedByTrailerCallback()
		callback(target)
	end
end

function AnimalController:setCanNotAddToTrailerCallback(callback, target)
	function self.canNotAddToTrailerCallback()
		callback(target)
	end
end

AnimalController.SYMBOL_L10N = {
	FARM = "ui_farm",
	DEALER = "animals_dealer"
}
