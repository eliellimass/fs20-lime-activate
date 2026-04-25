SellingStation = {
	PRICE_FALLING = 1,
	PRICE_CLIMBING = 2,
	PRICE_LOW = 3,
	PRICE_HIGH = 4,
	PRICE_GREAT_DEMAND = 5,
	PRICE_DROP_DELAY = 3600000
}
local SellingStation_mt = Class(SellingStation, UnloadingStation)

InitStaticObjectClass(SellingStation, "SellingStation", ObjectIds.OBJECT_SELLING_STATION)

function SellingStation:new(isServer, isClient, customMt)
	local self = UnloadingStation:new(isServer, isClient, customMt or SellingStation_mt)
	self.lastMoneyChange = -1
	self.incomeName = "harvestIncome"
	self.incomeNameWool = "soldWool"
	self.incomeNameMilk = "soldMilk"
	self.incomeNameBale = "soldBales"
	self.isSellingPoint = true

	return self
end

function SellingStation:load(id, xmlFile, key, customEnv)
	if not SellingStation:superClass().load(self, id, xmlFile, key, customEnv) then
		return false
	end

	self.appearsOnStats = Utils.getNoNil(getXMLBool(xmlFile, key .. "#appearsOnStats"), self.appearsOnPDA)
	self.suppressWarnings = Utils.getNoNil(getXMLBool(xmlFile, key .. "#suppressWarnings"), false)
	self.hasDynamic = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasDynamic"), true)
	self.supportsExtension = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsExtension"), false)
	local litersForFullPriceDrop = getXMLInt(xmlFile, key .. "#litersForFullPriceDrop")

	if litersForFullPriceDrop ~= nil then
		self.priceDropPerLiter = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / litersForFullPriceDrop
	end

	local fullPriceRecoverHours = getXMLFloat(xmlFile, key .. "#fullPriceRecoverHours")

	if fullPriceRecoverHours ~= nil then
		self.priceRecoverPerSecond = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / (fullPriceRecoverHours * 60 * 60)
	end

	self.acceptedFillTypes = {}
	self.fillTypeSupportsGreatDemand = {}
	self.priceDropDisabled = {}
	self.originalFillTypePricesUnscaled = {}
	self.originalFillTypePrices = {}
	self.fillTypePrices = {}
	self.fillTypePriceInfo = {}
	self.fillTypePriceRandomDelta = {}
	self.priceMultipliers = {}
	self.totalReceived = {}
	self.totalPaid = {}
	self.pendingPriceDrop = {}
	self.prevFillLevel = {}
	self.prevTotalReceived = {}
	self.prevTotalPaid = {}
	self.numFillTypesForSelling = 0
	self.missions = {}
	local i = 0

	while true do
		local fillTypeKey = string.format(key .. ".fillType(%d)", i)

		if not hasXMLProperty(xmlFile, fillTypeKey) then
			break
		end

		local fillTypeStr = getXMLString(xmlFile, fillTypeKey .. "#name")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex ~= nil then
			local priceScale = Utils.getNoNil(getXMLFloat(xmlFile, fillTypeKey .. "#priceScale"), 1)
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local price = fillType.pricePerLiter * priceScale
			local supportsGreatDemand = Utils.getNoNil(getXMLBool(xmlFile, fillTypeKey .. "#supportsGreatDemand"), false)
			local disablePriceDrop = Utils.getNoNil(getXMLBool(xmlFile, fillTypeKey .. "#disablePriceDrop"), false)

			self:addAcceptedFillType(fillTypeIndex, price, supportsGreatDemand, disablePriceDrop)
		end

		i = i + 1
	end

	self.moneyChangeType = MoneyType.getMoneyType("soldMaterials", "finance_other")
	self.priceDropTimer = 0
	self.pricingDynamics = {}

	self:initPricingDynamics()

	self.priceSyncTimerDuration = 30000
	self.priceSyncTimer = self.priceSyncTimerDuration
	self.unloadingStationDirtyFlag = self:getNextDirtyFlag()

	return true
end

function SellingStation:addAcceptedFillType(fillType, priceUnscaled, supportsGreatDemand, disablePriceDrop)
	if fillType ~= nil and self.acceptedFillTypes[fillType] == nil then
		self.acceptedFillTypes[fillType] = true
		self.fillTypeSupportsGreatDemand[fillType] = supportsGreatDemand

		if supportsGreatDemand then
			self.supportsGreatDemand = true
		end

		local price = priceUnscaled
		self.priceDropDisabled[fillType] = disablePriceDrop
		self.originalFillTypePricesUnscaled[fillType] = priceUnscaled
		self.originalFillTypePrices[fillType] = price
		self.fillTypePrices[fillType] = price
		self.fillTypePriceInfo[fillType] = 0
		self.fillTypePriceRandomDelta[fillType] = 0
		self.priceMultipliers[fillType] = 1
		self.totalReceived[fillType] = 0
		self.totalPaid[fillType] = 0
		self.pendingPriceDrop[fillType] = 0
		self.prevFillLevel[fillType] = 0
		self.prevTotalReceived[fillType] = 0
		self.prevTotalPaid[fillType] = 0
		self.numFillTypesForSelling = 0

		for fillType, _ in pairs(self.acceptedFillTypes) do
			if self.originalFillTypePrices[fillType] > 0 then
				self.numFillTypesForSelling = self.numFillTypesForSelling + 1
			end
		end
	end
end

function SellingStation:readStream(streamId, connection)
	SellingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local numFillTypes = streamReadUInt8(streamId)

		for i = 1, numFillTypes do
			local fillType = streamReadUInt8(streamId)
			self.fillTypePrices[fillType] = streamReadUInt16(streamId) / 1000
			self.fillTypePriceInfo[fillType] = streamReadUIntN(streamId, 6)
		end
	end
end

function SellingStation:writeStream(streamId, connection)
	SellingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.numFillTypesForSelling)

		if self.numFillTypesForSelling > 0 then
			for fillType, _ in pairs(self.acceptedFillTypes) do
				if self.originalFillTypePrices[fillType] > 0 then
					streamWriteUInt8(streamId, fillType)
					streamWriteUInt16(streamId, math.floor(self:getEffectiveFillTypePrice(fillType) * 1000 + 0.5))
					streamWriteUIntN(streamId, self:getCurrentPricingTrend(fillType), 6)
				end
			end
		end
	end
end

function SellingStation:readUpdateStream(streamId, timestamp, connection)
	SellingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		SellingStation.readStream(self, streamId, connection)
	end
end

function SellingStation:writeUpdateStream(streamId, connection, dirtyMask)
	SellingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.unloadingStationDirtyFlag) ~= 0) then
		SellingStation.writeStream(self, streamId, connection)
	end
end

function SellingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1

		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end
	end

	self:raiseActive()
end

function SellingStation:updateTick(dt)
	if self.isServer then
		self:updatePrices(dt * g_currentMission:getEffectiveTimeScale())

		if self.priceDropTimer > 0 then
			self.priceDropTimer = math.max(self.priceDropTimer - dt * g_currentMission:getEffectiveTimeScale(), 0)
		end

		if self.priceDropTimer <= 0 then
			for fillType, _ in pairs(self.acceptedFillTypes) do
				if (not self.isGreatDemandActive or self.greatDemandFillType ~= fillType) and self.pendingPriceDrop[fillType] > 0 then
					self:executePriceDrop(self.pendingPriceDrop[fillType], fillType)

					self.pendingPriceDrop[fillType] = 0
				end
			end
		end

		if self.hasDynamic then
			self.priceSyncTimer = self.priceSyncTimer - dt

			if self.priceSyncTimer < 0 then
				self:raiseDirtyFlags(self.unloadingStationDirtyFlag)

				self.priceSyncTimer = self.priceSyncTimerDuration
			end
		end
	end
end

function SellingStation:loadFromXMLFile(xmlFile, key)
	local i = 0

	while true do
		local statsKey = string.format(key .. ".stats(%d)", i)

		if not hasXMLProperty(xmlFile, statsKey) then
			break
		end

		local fillTypeStr = getXMLString(xmlFile, statsKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillType ~= nil and self.acceptedFillTypes[fillType] then
			self.totalReceived[fillType] = Utils.getNoNil(getXMLFloat(xmlFile, statsKey .. "#received"), 0)
			self.totalPaid[fillType] = Utils.getNoNil(getXMLFloat(xmlFile, statsKey .. "#paid"), 0)

			self.pricingDynamics[fillType]:loadFromXMLFile(xmlFile, statsKey)
		end

		i = i + 1
	end

	return true
end

function SellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local index = 0

	for fillTypeIndex, _ in pairs(self.acceptedFillTypes) do
		if self.originalFillTypePrices[fillTypeIndex] > 0 then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
			local statsKey = string.format("%s.stats(%d)", key, index)

			setXMLString(xmlFile, statsKey .. "#fillType", fillTypeName)
			setXMLFloat(xmlFile, statsKey .. "#received", self.totalReceived[fillTypeIndex])
			setXMLFloat(xmlFile, statsKey .. "#paid", self.totalPaid[fillTypeIndex])
			self.pricingDynamics[fillTypeIndex]:saveToXMLFile(xmlFile, statsKey, usedModNames)

			index = index + 1
		end
	end
end

function SellingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	if not self.acceptedFillTypes[fillTypeIndex] then
		return false
	end

	return true
end

function SellingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	local movedFillLevel = 0

	if deltaFillLevel > 0 and self:getIsFillTypeAllowed(fillType, extraAttributes) and self:getIsToolTypeAllowed(toolType) then
		local usedByMission = false

		for _, mission in pairs(self.missions) do
			if mission.fillSold ~= nil and mission.fillType == fillType and mission.farmId == farmId then
				mission:fillSold(deltaFillLevel)

				usedByMission = true

				break
			end
		end

		if not usedByMission then
			self:sellFillType(farmId, deltaFillLevel, fillType, toolType, extraAttributes)
		end

		movedFillLevel = deltaFillLevel
	end

	return movedFillLevel
end

function SellingStation:addTargetStorage(storage)
	print("Error: UnloadingStation '" .. tostring(self.stationName) .. "' is a selling point and does not accept any storages!")

	return false
end

function SellingStation:sellFillType(farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)
	if not self.priceDropDisabled[fillTypeIndex] then
		self:doPriceDrop(fillDelta, fillTypeIndex)
	end

	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	fillType.totalAmount = fillType.totalAmount + fillDelta
	self.totalReceived[fillTypeIndex] = self.totalReceived[fillTypeIndex] + fillDelta
	local price = fillDelta * self:getEffectiveFillTypePrice(fillTypeIndex, toolType)
	self.totalPaid[fillTypeIndex] = self.totalPaid[fillTypeIndex] + price
	self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
	self.moneyChangeType.statistic = self.lastIncomeName

	g_currentMission:addMoney(price, farmId, self.moneyChangeType, true)

	self.lastMoneyChange = 30
	self.lastMoneyChangeFarmId = farmId

	self:raiseActive()

	return price
end

function SellingStation:getEffectiveFillTypePrice(fillType, toolType)
	if self.isServer then
		return (self.fillTypePrices[fillType] + self.fillTypePriceRandomDelta[fillType]) * self.priceMultipliers[fillType] * EconomyManager.getPriceMultiplier()
	else
		return self.fillTypePrices[fillType]
	end
end

function SellingStation:getIncomeNameForFillType(fillType, toolType)
	if toolType == ToolType.BALE then
		return self.incomeNameBale
	end

	if fillType == FillType.WOOL then
		return self.incomeNameWool
	end

	if fillType == FillType.MILK then
		return self.incomeNameMilk
	end

	return self.incomeName
end

function SellingStation:initPricingDynamics()
	local timeScaling = 1
	local amp = 0.2
	local ampVar = 0.15
	local ampDist = PricingDynamics.AMP_DIST_LINEAR_DOWN
	local per = 172800000
	local perVar = 0.375 * per
	local perDist = PricingDynamics.AMP_DIST_CONSTANT
	local plateauFactor = 0.3
	local initialPlateauFraction = 0.75
	local amp2 = 0.1
	local ampVar2 = 0.02
	local ampDist2 = PricingDynamics.AMP_DIST_CONSTANT
	local per2 = 604800000
	local perVar2 = 0.2 * per2
	local perDist2 = PricingDynamics.AMP_DIST_CONSTANT
	self.levelThreshold = 0.8 * amp
	per = per / timeScaling
	perVar = perVar / timeScaling
	per2 = per2 / timeScaling
	perVar2 = perVar2 / timeScaling

	for fillType, _ in pairs(self.acceptedFillTypes) do
		self.pricingDynamics[fillType] = PricingDynamics:new(0, amp * self.originalFillTypePrices[fillType], ampVar * self.originalFillTypePrices[fillType], ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction)

		self.pricingDynamics[fillType]:addCurve(amp2 * self.originalFillTypePrices[fillType], ampVar2 * self.originalFillTypePrices[fillType], ampDist2, per2, perVar2, perDist2)
	end
end

function SellingStation:executePriceDrop(priceDrop, fillType)
	local lowestPrice = self.originalFillTypePrices[fillType] * EconomyManager.PRICE_DROP_MIN_PERCENT
	self.fillTypePrices[fillType] = math.max(self.fillTypePrices[fillType] - priceDrop, lowestPrice)
end

function SellingStation:doPriceDrop(fillLevel, fillType)
	if self.pendingPriceDrop[fillType] ~= nil then
		self.pendingPriceDrop[fillType] = self.pendingPriceDrop[fillType] + self.priceDropPerLiter * fillLevel * self.originalFillTypePrices[fillType]
		self.priceDropTimer = SellingStation.PRICE_DROP_DELAY
	end
end

function SellingStation:updatePrices(dt)
	if self.numFillTypesForSelling > 0 and self.hasDynamic then
		local priceRecoverBase = self.priceRecoverPerSecond * dt * 0.001

		for fillType, _ in pairs(self.acceptedFillTypes) do
			if not self.isGreatDemandActive or self.greatDemandFillType ~= fillType then
				self.pricingDynamics[fillType]:update(dt)

				self.fillTypePriceRandomDelta[fillType] = self.pricingDynamics[fillType]:evaluate()
				local trend = "normal"
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)

				if self.pricingDynamics[fillType]:getBaseCurveTrend() == PricingDynamics.TREND_FALLING then
					trend = "falling"
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
				elseif self.pricingDynamics[fillType]:getBaseCurveTrend() == PricingDynamics.TREND_CLIMBING then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
					trend = "climbing"
				end

				local priceRecover = priceRecoverBase * self.originalFillTypePrices[fillType]
				self.fillTypePrices[fillType] = math.min(self.fillTypePrices[fillType] + priceRecover, self.originalFillTypePrices[fillType])
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_LOW)
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_HIGH)
				local correctedDelta = self.fillTypePriceRandomDelta[fillType] - (self.originalFillTypePrices[fillType] - self.fillTypePrices[fillType])

				if self.levelThreshold < correctedDelta then
					trend = trend .. " high"
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_HIGH)
				elseif correctedDelta < -self.levelThreshold then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_LOW)
					trend = trend .. " low"
				end
			end
		end
	end
end

function SellingStation:setPriceMultiplier(fillType, priceMultiplier)
	self.priceMultipliers[fillType] = priceMultiplier
end

function SellingStation:getSupportsGreatDemand(fillType)
	if fillType == nil or self.fillTypeSupportsGreatDemand[fillType] == nil then
		return false
	end

	return self.fillTypeSupportsGreatDemand[fillType]
end

function SellingStation:setIsInGreatDemand(fillType, isInGreatDemand)
	if isInGreatDemand then
		self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_GREAT_DEMAND)
		self.isGreatDemandActive = true
		self.greatDemandFillType = fillType
	else
		if self.greatDemandFillType ~= nil and self.fillTypePriceInfo[self.greatDemandFillType] ~= nil then
			self.fillTypePriceInfo[self.greatDemandFillType] = Utils.clearBit(self.fillTypePriceInfo[self.greatDemandFillType], SellingStation.PRICE_GREAT_DEMAND)
		end

		self.isGreatDemandActive = false
		self.greatDemandFillType = FillType.UNKNOWN
	end

	self:raiseDirtyFlags(self.unloadingStationDirtyFlag)

	self.priceSyncTimer = self.priceSyncTimerDuration
end

function SellingStation:getPriceMultiplier(fillType)
	return self.priceMultipliers[fillType]
end

function SellingStation:getTotalReceived(fillType)
	return self.totalReceived[fillType]
end

function SellingStation:getTotalPaid(fillType)
	return self.totalPaid[fillType]
end

function SellingStation:getCurrentPricingTrend(fillType)
	return self.fillTypePriceInfo[fillType]
end

function SellingStation:getFreeCapacity(fillTypeIndex)
	return math.huge
end

function SellingStation:getIsFillAllowedFromFarm(farmId)
	return true
end

function SellingStation:getAppearsOnStats()
	return self.appearsOnStats
end
