EconomyManager = {}

source("dataS/scripts/economy/GreatDemandsEvent.lua")
source("dataS/scripts/economy/PricingDynamics.lua")

local EconomyManager_mt = Class(EconomyManager)
EconomyManager.sendNumBits = 2
EconomyManager.MAX_GREAT_DEMANDS = 2^EconomyManager.sendNumBits - 1
EconomyManager.PER_DAY_LEASING_FACTOR = 0.01
EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR = 0.021
EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR = 0.02
EconomyManager.PRICE_DROP_MIN_PERCENT = 0.6
EconomyManager.PRICE_MULTIPLIER = {
	3,
	1.8,
	1
}
EconomyManager.COST_MULTIPLIER = {
	0.4,
	0.7,
	1
}
EconomyManager.LIFETIME_OPERATINGTIME_RATIO = 0.08333
EconomyManager.CONFIG_CHANGE_PRICE = 1000
EconomyManager.DIRECT_SELL_MULTIPLIER = 1.2
EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER = 4

function EconomyManager:new(customMt)
	local self = {}

	setmetatable(self, customMt or EconomyManager_mt)

	self.minuteUpdateInterval = 5
	self.minuteTimer = self.minuteUpdateInterval
	self.showMoneyChangeNextMinute = false
	self.greatDemands = {}
	self.numberOfConcurrentDemands = EconomyManager.MAX_GREAT_DEMANDS

	for i = 1, self.numberOfConcurrentDemands do
		local greatDemand = GreatDemandSpecs:new()

		greatDemand:setUpRandomDemand(true, self.greatDemands)
		table.insert(self.greatDemands, greatDemand)
	end

	g_currentMission.environment:addDayChangeListener(self)
	g_currentMission.environment:addHourChangeListener(self)
	g_currentMission.environment:addMinuteChangeListener(self)

	return self
end

function EconomyManager:delete()
	if g_currentMission.environment ~= nil then
		g_currentMission.environment:removeDayChangeListener(self)
		g_currentMission.environment:removeHourChangeListener(self)
		g_currentMission.environment:removeMinuteChangeListener(self)
	end
end

function EconomyManager:dayChanged()
	if g_currentMission:getIsServer() then
		for _, farm in ipairs(g_farmManager.farms) do
			local farmId = farm.farmId

			if farmId ~= FarmManager.SPECTATOR_FARM_ID then
				local money = -farm:calculateDailyLoanInterest()

				g_currentMission:addMoney(money, farmId, MoneyType.LOAN_INTEREST, true)

				local perDayLeasingCosts = 0

				for _, item in pairs(g_currentMission.leasedVehicles) do
					for _, vehicle in pairs(item.items) do
						if vehicle:getOwnerFarmId() == farmId then
							perDayLeasingCosts = perDayLeasingCosts + vehicle:getPrice() * EconomyManager.PER_DAY_LEASING_FACTOR
						end
					end
				end

				if perDayLeasingCosts > 0 then
					g_currentMission:addMoney(-perDayLeasingCosts, farmId, MoneyType.LEASING_COSTS, true)
				end

				local vehicleUpkeep = 0
				local facilityUpkeep = 0

				for storeItem, item in pairs(g_currentMission.ownedItems) do
					if StoreItemUtil.getIsVehicle(storeItem) then
						for _, realItem in pairs(item.items) do
							if realItem:getOwnerFarmId() == farmId then
								vehicleUpkeep = vehicleUpkeep + realItem:getDailyUpkeep()
							end
						end
					else
						for _, realItem in pairs(item.items) do
							if realItem:getOwnerFarmId() == farmId then
								facilityUpkeep = facilityUpkeep + realItem:getDailyUpkeep()
							end
						end
					end
				end

				if vehicleUpkeep > 0 then
					g_currentMission:addMoney(-vehicleUpkeep, farmId, MoneyType.VEHICLE_RUNNING_COSTS, true)
				end

				if facilityUpkeep > 0 then
					g_currentMission:addMoney(-facilityUpkeep, farmId, MoneyType.PROPERTY_MAINTENANCE, true)
				end
			end
		end

		self.showMoneyChangeNextMinute = true
	end
end

function EconomyManager:hourChanged()
	if g_currentMission:getIsServer() then
		self:manageGreatDemands()
	end
end

function EconomyManager:vehicleOperatingHourChanged(vehicle)
	if g_currentMission:getIsServer() then
		local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		local vehicleRunningLeasingCosts = storeItem.runningLeasingFactor * vehicle:getPrice()

		if vehicleRunningLeasingCosts > 0 then
			g_currentMission:addMoney(-vehicleRunningLeasingCosts, vehicle:getOwnerFarmId(), MoneyType.LEASING_COSTS, true)
		end
	end
end

function EconomyManager:minuteChanged()
	if self.showMoneyChangeNextMinute then
		g_currentMission:showMoneyChange(MoneyType.LOAN_INTEREST)
		g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS)
		g_currentMission:showMoneyChange(MoneyType.VEHICLE_RUNNING_COSTS)
		g_currentMission:showMoneyChange(MoneyType.PROPERTY_MAINTENANCE)
		g_currentMission:showMoneyChange(MoneyType.PROPERTY_INCOME)
		g_currentMission:showMoneyChange(MoneyType.ANIMAL_UPKEEP)

		self.showMoneyChangeNextMinute = false
	end
end

function EconomyManager:updateGreatDemandsPDASpots()
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid and greatDemand.isRunning then
			local station = greatDemand.sellStation

			if station ~= nil and station.mapHotspot ~= nil and not station.mapHotspot.blinking then
				station.mapHotspot:setBlinking(true)
				station.mapHotspot:setPersistent(true)
				station.mapHotspot:setIconColor({
					0.0742,
					0.4341,
					0.6939,
					1
				})
			end
		end
	end
end

function EconomyManager:restartGreatDemands()
	self:finalizeGreatDemandLoading()

	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid and greatDemand.isRunning then
			local station = greatDemand.sellStation

			if station ~= nil and station:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
				station:setIsInGreatDemand(greatDemand.fillTypeIndex, true)

				if station.mapHotspot ~= nil then
					station.mapHotspot:setBlinking(true)
					station.mapHotspot:setPersistent(true)
					station.mapHotspot:setIconColor({
						0.0742,
						0.4341,
						0.6939,
						1
					})
				end

				station:setPriceMultiplier(greatDemand.fillTypeIndex, greatDemand.demandMultiplier)
			end
		end
	end
end

function EconomyManager:manageGreatDemands()
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid then
			if greatDemand.isRunning then
				greatDemand.demandDuration = greatDemand.demandDuration - 1

				if greatDemand.demandDuration <= 0 then
					self:stopGreatDemand(greatDemand)
				end
			elseif not greatDemand.isRunning and greatDemand.demandStart.day == g_currentMission.environment.currentDay and greatDemand.demandStart.hour <= g_currentMission.environment.currentHour then
				self:startGreatDemand(greatDemand)
			end
		end
	end

	g_server:broadcastEvent(GreatDemandsEvent:new(self.greatDemands))

	for _, greatDemand in pairs(self.greatDemands) do
		if not greatDemand.isValid or not greatDemand.isRunning and greatDemand.demandStart.day < g_currentMission.environment.currentDay then
			greatDemand:setUpRandomDemand(true, self.greatDemands)
		end
	end
end

function EconomyManager:stopGreatDemand(greatDemand)
	greatDemand.isRunning = false
	greatDemand.isValid = false
	local sellStation = greatDemand.sellStation

	if sellStation ~= nil and sellStation:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
		sellStation:setIsInGreatDemand(greatDemand.fillTypeIndex, false)

		if sellStation.mapHotspot ~= nil then
			sellStation.mapHotspot:setBlinking(false)
			sellStation.mapHotspot:setPersistent(false)
			sellStation.mapHotspot:setIconColor(nil)
		end

		sellStation:setPriceMultiplier(greatDemand.fillTypeIndex, 1)
	end
end

function EconomyManager:startGreatDemand(greatDemand)
	greatDemand.isRunning = true
	local fillTypeName = "Unknown"
	local fillType = g_fillTypeManager:getFillTypeByIndex(greatDemand.fillTypeIndex)

	if fillType ~= nil then
		fillTypeName = fillType.title
	end

	local sellStation = greatDemand.sellStation

	if sellStation ~= nil then
		g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_GREATDEMAND, string.format(g_i18n:getText("notification_greatDemand"), sellStation.stationName), 40000)

		if sellStation:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
			sellStation:setIsInGreatDemand(greatDemand.fillTypeIndex, true)

			if sellStation.mapHotspot ~= nil then
				sellStation.mapHotspot:setBlinking(true)
				sellStation.mapHotspot:setPersistent(true)
				sellStation.mapHotspot:setIconColor({
					0.0742,
					0.4341,
					0.6939,
					1
				})
			end

			sellStation:setPriceMultiplier(greatDemand.fillTypeIndex, greatDemand.demandMultiplier)
		end
	end
end

function EconomyManager:getGreatDemandById(id)
	return self.greatDemands[id]
end

function EconomyManager:getGreatDemandId(greatDemand)
	for k, demand in pairs(self.greatDemands) do
		if greatDemand == demand then
			return k
		end
	end

	return 0
end

function EconomyManager:getCurrentGreatDemand(stationName, fillTypeIndex)
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid and greatDemand.isRunning and greatDemand.stationName == stationName and greatDemand.fillTypeIndex == fillTypeIndex then
			return greatDemand
		end
	end

	return nil
end

function EconomyManager:getPricePerLiter(fillTypeIndex, useMultiplier)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local multiplier = EconomyManager.getPriceMultiplier()

	if useMultiplier ~= nil and not useMultiplier then
		multiplier = 1
	end

	return fillType.pricePerLiter * multiplier
end

function EconomyManager:getCostPerLiter(fillTypeIndex, useMultiplier)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local multiplier = EconomyManager.getCostMultiplier()

	if useMultiplier ~= nil and not useMultiplier then
		multiplier = 1
	end

	return fillType.pricePerLiter * multiplier
end

function EconomyManager:getBuyPrice(storeItem, configurations)
	local price = storeItem.price
	local upgradePrice = 0

	if configurations ~= nil then
		for name, id in pairs(configurations) do
			local configs = storeItem.configurations[name]

			if configs ~= nil then
				upgradePrice = upgradePrice + configs[id].price
				price = price + configs[id].price
			end
		end
	end

	return price, upgradePrice
end

function EconomyManager:getSellPrice(object)
	if object.getSellPrice ~= nil then
		return object:getSellPrice()
	end

	return math.floor(object.price * 0.5)
end

function EconomyManager:getInitialLeasingPrice(price)
	return price * (EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR + EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
end

function EconomyManager:saveToXMLFile(xmlFile, key)
	local index = 0

	for _, greatDemand in ipairs(self.greatDemands) do
		local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(greatDemand.fillTypeIndex)

		if fillTypeName ~= nil then
			local demandKey = string.format("%s.greatDemands.greatDemand(%d)", key, index)
			local itemId = greatDemand.sellStation.owningPlaceable.currentSavegameItemId

			setXMLInt(xmlFile, demandKey .. "#itemId", itemId)
			setXMLString(xmlFile, demandKey .. "#fillTypeName", fillTypeName)
			setXMLFloat(xmlFile, demandKey .. "#demandMultiplier", greatDemand.demandMultiplier)
			setXMLInt(xmlFile, demandKey .. "#demandStartDay", greatDemand.demandStart.day)
			setXMLInt(xmlFile, demandKey .. "#demandStartHour", greatDemand.demandStart.hour)
			setXMLInt(xmlFile, demandKey .. "#demandDuration", greatDemand.demandDuration)
			setXMLBool(xmlFile, demandKey .. "#isRunning", greatDemand.isRunning)
			setXMLBool(xmlFile, demandKey .. "#isValid", greatDemand.isValid)

			index = index + 1
		end
	end
end

function EconomyManager:loadFromXMLFile(xmlFile, key)
	self.greatDemandToLoad = {}
	local greatDemandNumber = 0

	while true do
		local demandKey = string.format("%s.greatDemands.greatDemand(%d)", key, greatDemandNumber)
		local itemId = getXMLInt(xmlFile, demandKey .. "#itemId")

		if itemId == nil then
			break
		end

		local fillTypeName = getXMLString(xmlFile, demandKey .. "#fillTypeName")
		local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
		local fillTypeIndex = nil

		if fillType ~= nil then
			fillTypeIndex = fillType.index
		end

		if fillTypeIndex == nil then
			break
		end

		local greatDemand = {
			itemId = itemId,
			fillTypeIndex = fillTypeIndex,
			demandMultiplier = getXMLFloat(xmlFile, demandKey .. "#demandMultiplier"),
			day = getXMLInt(xmlFile, demandKey .. "#demandStartDay"),
			hour = getXMLInt(xmlFile, demandKey .. "#demandStartHour"),
			demandDuration = getXMLInt(xmlFile, demandKey .. "#demandDuration"),
			isRunning = Utils.getNoNil(getXMLBool(xmlFile, demandKey .. "#isRunning"), false),
			isValid = Utils.getNoNil(getXMLBool(xmlFile, demandKey .. "#isValid"), false)
		}

		table.insert(self.greatDemandToLoad, greatDemand)

		greatDemandNumber = greatDemandNumber + 1
	end
end

function EconomyManager:finalizeGreatDemandLoading()
	if self.greatDemandToLoad ~= nil then
		local i = 1

		for _, greatDemandToLoad in ipairs(self.greatDemandToLoad) do
			local item = g_currentMission.loadItemsById[greatDemandToLoad.itemId]

			if item ~= nil then
				local station = item.sellingStation

				if station ~= nil and station.getSupportsGreatDemand and station:getSupportsGreatDemand(greatDemandToLoad.fillTypeIndex) then
					local greatDemand = self.greatDemands[i]
					greatDemand.sellStation = station
					greatDemand.fillTypeIndex = greatDemandToLoad.fillTypeIndex
					greatDemand.demandMultiplier = greatDemandToLoad.demandMultiplier
					greatDemand.demandStart.day = greatDemandToLoad.day
					greatDemand.demandStart.hour = greatDemandToLoad.hour
					greatDemand.demandDuration = greatDemandToLoad.demandDuration
					greatDemand.isRunning = greatDemandToLoad.isRunning
					greatDemand.isValid = greatDemandToLoad.isValid
					i = i + 1
				end
			end
		end

		self.greatDemandToLoad = nil
	end
end

function EconomyManager.getPriceMultiplier()
	return EconomyManager.PRICE_MULTIPLIER[g_currentMission.missionInfo.economicDifficulty]
end

function EconomyManager.getCostMultiplier()
	return EconomyManager.COST_MULTIPLIER[g_currentMission.missionInfo.economicDifficulty]
end
