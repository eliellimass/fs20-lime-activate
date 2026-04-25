HarvestMission = {
	REWARD_PER_HA_WIDE = 1500,
	REWARD_PER_HA_SMALL = 4800,
	FAILURE_COST_FACTOR = 0.1,
	FAILURE_COST_OF_TOTAL = 0.95,
	SUCCESS_FACTOR = 0.93
}
local HarvestMission_mt = Class(HarvestMission, AbstractFieldMission)

InitStaticObjectClass(HarvestMission, "HarvestMission", ObjectIds.MISSION_HARVEST)

function HarvestMission:new(isServer, isClient, customMt)
	local self = AbstractFieldMission:new(isServer, isClient, customMt or HarvestMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.CUTTER] = true,
		[WorkAreaType.COMBINECHOPPER] = true,
		[WorkAreaType.COMBINESWATH] = true,
		[WorkAreaType.FRUITPREPARER] = true
	}
	self.reimbursementPerHa = 0
	self.lastSellChange = -1

	return self
end

function HarvestMission:delete()
	if self.sellPoint ~= nil then
		self.sellPoint.missions[self] = nil
	end

	HarvestMission:superClass().delete(self)
end

function HarvestMission:saveToXMLFile(xmlFile, key)
	HarvestMission:superClass().saveToXMLFile(self, xmlFile, key)

	local harvestKey = string.format("%s.harvest", key)
	local item = self.sellPoint.owningPlaceable

	setXMLInt(xmlFile, harvestKey .. "#sellPoint", item.currentSavegameItemId)
	setXMLFloat(xmlFile, harvestKey .. "#expectedLiters", self.expectedLiters)
	setXMLFloat(xmlFile, harvestKey .. "#depositedLiters", self.depositedLiters)
end

function HarvestMission:loadFromXMLFile(xmlFile, key)
	if not HarvestMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local harvestKey = key .. ".harvest(0)"
	local itemId = getXMLInt(xmlFile, harvestKey .. "#sellPoint")
	local item = g_currentMission.loadItemsById[itemId]

	if item == nil then
		g_logManager:xmlError("missions.xml", "Mission sell point is not available.")

		return false
	end

	self.sellPoint = item.sellingStation
	self.sellPoint.missions[self] = self
	self.expectedLiters = getXMLFloat(xmlFile, harvestKey .. "#expectedLiters")
	self.depositedLiters = getXMLFloat(xmlFile, harvestKey .. "#depositedLiters")
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	if not fruitDesc then
		g_logManager:xmlError("missions.xml", "Harvest mission has no fruit type.")

		return false
	end

	self.fillType = fruitDesc.fillType.index

	self:updateRewardPerHa()

	if self.status == AbstractMission.STATUS_RUNNING then
		self:createModifiers()
	end

	return true
end

function HarvestMission:writeStream(streamId)
	HarvestMission:superClass().writeStream(self, streamId)
	NetworkUtil.writeNodeObject(streamId, self.sellPoint)
	streamWriteUInt8(streamId, self.fillType)
end

function HarvestMission:readStream(streamId)
	HarvestMission:superClass().readStream(self, streamId)

	self.sellPoint = NetworkUtil.readNodeObject(streamId)
	self.fillType = streamReadUInt8(streamId)

	self:updateRewardPerHa()
end

function HarvestMission:init(field, ...)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
	self.fillType = fruitDesc.fillType.index

	self:updateRewardPerHa()

	if not HarvestMission:superClass().init(self, field, ...) then
		return false
	end

	self.depositedLiters = 0
	self.expectedLiters = self:getMaxCutLiters()
	self.sellPoint, _ = self:getHighestSellPointPrice()

	if self.sellPoint == nil then
		return false
	end

	return true
end

function HarvestMission:start(...)
	if not HarvestMission:superClass().start(self, ...) then
		return false
	end

	self.sellPoint.missions[self] = self

	self:createModifiers()

	return true
end

function HarvestMission:finish(success)
	HarvestMission:superClass().finish(self, success)

	self.sellPoint.missions[self] = nil
end

function HarvestMission:calculateStealingCost()
	if not self.success and self.isServer then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)
		local multiplier = g_currentMission:getHarvestScaleMultiplier(self.fruitType, self.sprayFactor, self.fieldPlowFactor, self.limeFactor, self.weedFactor)
		local area = self.field.fieldArea * multiplier
		local harvestedArea = self.fieldPercentageDone * area
		local litersHarvested = fruitDesc.literPerSqm * harvestedArea * 10000
		litersHarvested = litersHarvested - self:getFruitInVehicles()
		local diff = litersHarvested - self.depositedLiters

		if diff > litersHarvested * HarvestMission.FAILURE_COST_FACTOR then
			local _, pricePerLiter = self:getHighestSellPointPrice()
			local farmReimbursement = diff * HarvestMission.FAILURE_COST_OF_TOTAL * pricePerLiter

			return farmReimbursement
		end
	end

	return 0
end

function HarvestMission:getFruitInVehicles()
	local totalLiters = 0

	for _, vehicle in pairs(self.vehicles) do
		if vehicle.spec_fillUnit ~= nil then
			for index, unit in pairs(vehicle:getFillUnits()) do
				local fillType = vehicle:getFillUnitFillType(index)

				if fillType == self.fillType then
					local level = vehicle:getFillUnitFillLevel(index)
					totalLiters = totalLiters + level
				end
			end
		end
	end

	return totalLiters
end

function HarvestMission:getHighestSellPointPrice()
	local highestPrice = 0
	local sellPoint = nil

	for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if unloadingStation.owningPlaceable ~= nil and unloadingStation.isSellingPoint and unloadingStation.acceptedFillTypes[self.fillType] then
			local price = unloadingStation:getEffectiveFillTypePrice(self.fillType)

			if highestPrice < price then
				highestPrice = price
				sellPoint = unloadingStation
			end
		end
	end

	return sellPoint, highestPrice
end

function HarvestMission:completeField()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, FieldManager.FIELDSTATE_HARVESTED, fruitDesc.cutState, 0, false, self.fieldPlowFactor)
	end
end

function HarvestMission:fillSold(fillDelta)
	self.depositedLiters = math.min(self.depositedLiters + fillDelta, self.expectedLiters)
	local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR

	if expected <= self.depositedLiters then
		self.sellPoint.missions[self] = nil
	end

	self.lastSellChange = 30
end

function HarvestMission:update(dt)
	HarvestMission:superClass().update(self, dt)

	if not self:hasMapMarker() and self.status == AbstractMission.STATUS_RUNNING then
		self:createMapMarkerAtSellingStation(self.sellPoint)
	end

	if self.lastSellChange > 0 then
		self.lastSellChange = self.lastSellChange - 1

		if self.lastSellChange == 0 then
			local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
			local percentage = math.floor(self.depositedLiters / expected * 100)

			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("fieldJob_progress_transporting_forField"), percentage, self.field.fieldId))
		end
	end
end

function HarvestMission:getVehicleVariant()
	local fruitType = self.field.fruitType

	if fruitType == FruitType.SUNFLOWER or fruitType == FruitType.MAIZE then
		return "MAIZE"
	elseif fruitType == FruitType.SUGARBEET then
		return "SUGARBEET"
	elseif fruitType == FruitType.POTATO then
		return "POTATO"
	elseif fruitType == FruitType.COTTON then
		return "COTTON"
	elseif fruitType == FruitType.SUGARCANE then
		return "SUGARCANE"
	else
		return "GRAIN"
	end
end

function HarvestMission:updateRewardPerHa()
	if self.fillType == FillType.SUGARCANE or self.fillType == FillType.POTATO or self.fillType == FillType.SUGARBEET then
		self.rewardPerHa = HarvestMission.REWARD_PER_HA_SMALL
	else
		self.rewardPerHa = HarvestMission.REWARD_PER_HA_WIDE
	end
end

function HarvestMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState)
	local fruitType = field.fruitType
	local maxGrowthState = FieldUtil.getMaxHarvestState(field, fruitType)

	if maxGrowthState == nil then
		return false
	end

	if fruitType == FruitType.COTTON and field.fieldArea < 0.4 then
		return false
	end

	return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
end

function HarvestMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_harvesting"),
		action = g_i18n:getText("fieldJob_desc_action_harvesting"),
		description = string.format(g_i18n:getText("fieldJob_desc_harvesting"), g_fillTypeManager:getFillTypeByIndex(self.fillType).title, self.field.fieldId, self:getStationName())
	}
end

function HarvestMission:getCompletion()
	local sellCompletion = self.depositedLiters / self.expectedLiters / HarvestMission.SUCCESS_FACTOR
	local fieldCompletion = self:getFieldCompletion()
	local harvestCompletion = fieldCompletion / AbstractMission.SUCCESS_FACTOR

	return math.min(1, 0.8 * harvestCompletion + 0.2 * sellCompletion)
end

function HarvestMission:getStationName()
	local stationName = self.sellPoint.stationName

	if g_i18n:hasText(stationName, g_currentMission.missionInfo.customEnvironment) then
		stationName = g_i18n:getText(stationName, g_currentMission.missionInfo.customEnvironment)
	end

	return stationName
end

function HarvestMission:getExtraProgressText()
	if self.completion >= 0.1 then
		local title = self:getStationName()

		return string.format(g_i18n:getText("fieldJob_progress_harvesting_nextUnloadDesc"), g_fillTypeManager:getFillTypeByIndex(self.fillType).title, title)
	else
		return ""
	end
end

function HarvestMission:createModifiers()
	local ids = g_currentMission.fruits[self.field.fruitType]

	if ids ~= nil and ids.id ~= 0 then
		local id = ids.id
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

		if fruitDesc ~= nil then
			self.completionModifier = DensityMapModifier:new(id, fruitDesc.startStateChannel, fruitDesc.numStateChannels)
			self.completionFilter = DensityMapFilter:new(self.completionModifier)

			self.completionFilter:setValueCompareParams("equal", fruitDesc.cutState + 1)
		end
	end
end

function HarvestMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, "pvv")

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function HarvestMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_HARVESTED and event ~= FieldManager.FIELDEVENT_WITHERED and event ~= FieldManager.FIELDEVENT_CULTIVATED
end

g_missionManager:registerMissionType(HarvestMission, "harvest")
