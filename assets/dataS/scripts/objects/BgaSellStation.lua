BgaSellStation = {}
local BgaSellStation_mt = Class(BgaSellStation, UnloadingStation)

InitStaticObjectClass(BgaSellStation, "BgaSellStation", ObjectIds.OBJECT_BGA_SELLING_STATION)

function BgaSellStation:new(isServer, isClient, bga, customMt)
	local self = UnloadingStation:new(isServer, isClient, customMt or BgaSellStation_mt)
	self.bga = bga

	return self
end

function BgaSellStation:load(id, xmlFile, customEnvironment, key)
	if not BgaSellStation:superClass().load(self, id, xmlFile, key, customEnvironment) then
		return false
	end

	self.appearsOnStats = Utils.getNoNil(getXMLBool(xmlFile, key .. "#appearsOnStats"), self.appearsOnPDA)

	return true
end

function BgaSellStation:getEffectiveFillTypePrice(fillTypeIndex)
	return self.bga:getFillTypeLiterPrice(fillTypeIndex) * EconomyManager.getPriceMultiplier()
end

function BgaSellStation:getSupportsGreatDemand(fillType)
	return false
end

function BgaSellStation:getCurrentPricingTrend(fillType)
	return 0
end

function BgaSellStation:getAppearsOnStats()
	if g_currentMission:getFarmId() ~= self:getOwnerFarmId() then
		return false
	end

	return self.appearsOnStats
end
