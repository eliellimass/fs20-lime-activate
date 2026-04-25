BuyingStation = {}
local BuyingStation_mt = Class(BuyingStation, LoadingStation)

InitStaticObjectClass(BuyingStation, "BuyingStation", ObjectIds.OBJECT_BUYING_STATION)

function BuyingStation:new(isServer, isClient, customMt)
	self = LoadingStation:new(isServer, isClient, customMt or BuyingStation_mt)
	self.incomeName = "other"
	self.incomeNameFuel = "purchaseFuel"
	self.incomeNameLime = "other"

	return self
end

function BuyingStation:load(id, xmlFile, key, customEnv)
	if not BuyingStation:superClass().load(self, id, xmlFile, key, customEnv) then
		return false
	end

	self.lastMoneyChange = 0
	self.providedFillTypes = {}
	self.fillTypePricesScale = {}
	self.fillTypeStatsName = {}
	local i = 0

	while true do
		local fillTypeKey = string.format(key .. ".fillType(%d)", i)

		if not hasXMLProperty(xmlFile, fillTypeKey) then
			break
		end

		local fillTypeStr = getXMLString(xmlFile, fillTypeKey .. "#name")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
		local fillTypeStatsName = getXMLString(xmlFile, fillTypeKey .. "#statsName") or "other"

		if fillTypeIndex ~= nil then
			local priceScale = Utils.getNoNil(getXMLFloat(xmlFile, fillTypeKey .. "#priceScale"), 1)
			self.providedFillTypes[fillTypeIndex] = true
			self.fillTypePricesScale[fillTypeIndex] = priceScale
			self.fillTypeStatsName[fillTypeIndex] = fillTypeStatsName
		end

		i = i + 1
	end

	self.moneyChangeType = MoneyType.getMoneyType("other", "finance_other")

	return true
end

function BuyingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1

		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end

		self:raiseActive()
	end
end

function BuyingStation:addSourceStorage(storage)
	print("Error: LoadingStation '" .. tostring(self.stationName) .. "' is a buying point and does not accept any storages!")

	return false
end

function BuyingStation:getProvidedFillTypes()
	return self.providedFillTypes
end

function BuyingStation:getAllFillLevels()
	local fillLevels = {}
	local capacity = 0

	for fillType, _ in pairs(self.providedFillTypes) do
		fillLevels[fillType] = 1
	end

	capacity = 1

	return fillLevels, capacity
end

function BuyingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillTypeIndex == FillType.UNKNOWN or fillDelta == 0 or toolType == nil then
		return 0
	end

	local farmId = fillableObject:getOwnerFarmId()

	if g_currentMission:getMoney(farmId) > 0 then
		fillDelta = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)

		if fillDelta > 0 then
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local pricePerLiter = self.fillTypePricesScale[fillTypeIndex] * fillType.pricePerLiter
			local price = pricePerLiter * fillDelta
			self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
			self.moneyChangeType.statistic = self.lastIncomeName

			g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)

			self.lastMoneyChangeFarmId = farmId
			self.lastMoneyChange = 30

			self:raiseActive()
		end
	else
		fillDelta = 0
	end

	return fillDelta
end

function BuyingStation:getIncomeNameForFillType(fillType, toolType)
	if fillType == FillType.DIESEL then
		return self.incomeNameFuel
	end

	if fillType == FillType.LIME then
		return self.incomeNameLime
	end

	return self.incomeName
end

function BuyingStation:getIsFillAllowedToFarm(farmId)
	return true
end
