SplitTypeManager = {
	COLLISIONMASK_TRIGGER = 16777216
}
local SplitTypeManager_mt = Class(SplitTypeManager, AbstractManager)

function SplitTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or SplitTypeManager_mt)

	return self
end

function SplitTypeManager:initDataStructures()
	self.typesByIndex = {}
end

function SplitTypeManager:loadMapData()
	SplitTypeManager:superClass().loadMapData(self)
	self:addSplitType("spruce", 1, 0.7, 3, true)
	self:addSplitType("pine", 2, 0.7, 3, true)
	self:addSplitType("larch", 3, 0.7, 3, true)
	self:addSplitType("birch", 4, 0.85, 3.2, false)
	self:addSplitType("beech", 5, 0.9, 3.4, false)
	self:addSplitType("maple", 6, 0.9, 3.4, false)
	self:addSplitType("oak", 7, 0.9, 3.4, false)
	self:addSplitType("ash", 8, 0.9, 3.4, false)
	self:addSplitType("locust", 9, 1, 3.8, false)
	self:addSplitType("mahogany", 10, 1.1, 3, false)
	self:addSplitType("poplar", 11, 0.7, 7.5, false)

	return true
end

function SplitTypeManager:addSplitType(name, splitType, pricePerLiter, woodChipsPerLiter, allowsWoodHarvester)
	if self.typesByIndex[splitType] == nil then
		local desc = {
			name = name,
			splitType = splitType,
			pricePerLiter = pricePerLiter,
			woodChipsPerLiter = woodChipsPerLiter,
			allowsWoodHarvester = allowsWoodHarvester
		}
		self.typesByIndex[splitType] = desc
	end
end

function SplitTypeManager:getSplitTypeByIndex(index)
	if self.typesByIndex[index] ~= nil then
		return self.typesByIndex[index]
	end
end

g_splitTypeManager = SplitTypeManager:new()
