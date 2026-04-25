BaleMission = {
	REWARD_PER_HA_HAY = 3000,
	REWARD_PER_HA_SILAGE = 3300,
	SILAGE_VARIANT_CHANCE = 0.5,
	FILL_SUCCESS_FACTOR = 0.8
}
local BaleMission_mt = Class(BaleMission, AbstractFieldMission)

InitStaticObjectClass(BaleMission, "BaleMission", ObjectIds.MISSION_BALE)

function BaleMission:new(isServer, isClient, customMt)
	local self = AbstractFieldMission:new(isServer, isClient, customMt or BaleMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.MOWER] = true,
		[WorkAreaType.BALER] = true,
		[WorkAreaType.TEDDER] = true,
		[WorkAreaType.WINDROWER] = true,
		[WorkAreaType.AUXILIARY] = true
	}
	self.reimbursementPerHa = 0
	self.lastSellChange = -1
	local fruitType = FruitType.GRASS
	local ids = g_currentMission.fruits[fruitType]
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	self.completionModifier = DensityMapModifier:new(ids.id, desc.startStateChannel, desc.numStateChannels)
	self.completionFilter = DensityMapFilter:new(self.completionModifier)

	return self
end

function BaleMission:delete()
	if self.sellPoint ~= nil then
		self.sellPoint.missions[self] = nil
	end

	BaleMission:superClass().delete(self)
end

function BaleMission:saveToXMLFile(xmlFile, key)
	BaleMission:superClass().saveToXMLFile(self, xmlFile, key)

	local baleKey = string.format("%s.bale", key)
	local item = self.sellPoint.owningPlaceable

	setXMLInt(xmlFile, baleKey .. "#sellPoint", item.currentSavegameItemId)
	setXMLString(xmlFile, baleKey .. "#fillTypeName", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	setXMLFloat(xmlFile, baleKey .. "#depositedLiters", self.depositedLiters)
end

function BaleMission:loadFromXMLFile(xmlFile, key)
	if not BaleMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local baleKey = key .. ".bale(0)"
	local itemId = getXMLInt(xmlFile, baleKey .. "#sellPoint")
	local item = g_currentMission.loadItemsById[itemId]

	if item == nil then
		g_logManager:xmlError("missions.xml", "Mission sell point is not available.")

		return false
	end

	self.sellPoint = item.sellingStation
	self.sellPoint.missions[self] = self
	local fillTypeName = getXMLString(xmlFile, baleKey .. "#fillTypeName")
	self.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	self:updateRewardPerHa()

	self.depositedLiters = getXMLFloat(xmlFile, baleKey .. "#depositedLiters")
	self.expectedLiters = self:roundToWholeBales(self:getMaxCutLiters())

	if self.fillType == FillType.SILAGE then
		self.workAreaTypes[WorkAreaType.TEDDER] = false
	end

	return true
end

function BaleMission:writeStream(streamId)
	BaleMission:superClass().writeStream(self, streamId)
	NetworkUtil.writeNodeObject(streamId, self.sellPoint)
	streamWriteUInt8(streamId, self.fillType)
end

function BaleMission:readStream(streamId)
	BaleMission:superClass().readStream(self, streamId)

	self.sellPoint = NetworkUtil.readNodeObject(streamId)
	self.fillType = streamReadUInt8(streamId)

	self:updateRewardPerHa()
end

function BaleMission:init(...)
	if math.random() < BaleMission.SILAGE_VARIANT_CHANCE then
		self.fillType = FillType.SILAGE
		self.workAreaTypes[WorkAreaType.TEDDER] = false
	else
		self.fillType = FillType.DRYGRASS_WINDROW
	end

	self:updateRewardPerHa()

	if not BaleMission:superClass().init(self, ...) then
		return false
	end

	self.depositedLiters = 0
	self.expectedLiters = self:roundToWholeBales(self:getMaxCutLiters())
	local highestPrice = 0

	for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if unloadingStation.owningPlaceable ~= nil and unloadingStation.isSellingPoint and unloadingStation.acceptedFillTypes[self.fillType] == true then
			local price = unloadingStation:getEffectiveFillTypePrice(self.fillType)

			if highestPrice < price then
				highestPrice = price
				self.sellPoint = unloadingStation
			end
		end
	end

	if self.sellPoint == nil then
		return false
	end

	return true
end

function BaleMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState)
	local fruitType = FruitType.GRASS
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local maxGrowthState = FieldUtil.getMaxHarvestState(field, fruitType)

	if maxGrowthState == fruitDesc.maxHarvestingGrowthState + 1 then
		return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
	end

	return false
end

function BaleMission:start(...)
	if not BaleMission:superClass().start(self, ...) then
		return false
	end

	self.sellPoint.missions[self] = self

	return true
end

function BaleMission:completeField()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, FieldManager.FIELDSTATE_GROWING, fruitDesc.cutState + 1, 0, false, self.fieldPlowFactor)
	end
end

function BaleMission:fillSold(fillDelta)
	self.depositedLiters = math.min(self.depositedLiters + fillDelta, self.expectedLiters)
	local expected = self.expectedLiters * BaleMission.FILL_SUCCESS_FACTOR

	if expected <= self.depositedLiters then
		self.sellPoint.missions[self] = nil
	end

	self.lastSellChange = 30
end

function BaleMission:update(dt)
	BaleMission:superClass().update(self, dt)

	if self.isClient and self.status == AbstractMission.STATUS_RUNNING and not self:hasMapMarker() then
		self:createMapMarkerAtSellingStation(self.sellPoint)
	end

	if self.lastSellChange > 0 then
		self.lastSellChange = self.lastSellChange - 1

		if self.lastSellChange == 0 then
			local expected = self.expectedLiters * BaleMission.FILL_SUCCESS_FACTOR
			local percentage = math.floor(self.depositedLiters / expected * 100)

			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("fieldJob_progress_transporting_forField"), percentage, self.field.fieldId))
		end
	end
end

function BaleMission:roundToWholeBales(liters)
	local baleSize = 4000

	return math.floor(liters / baleSize) * baleSize
end

function BaleMission:updateRewardPerHa()
	if self.fillType == FillType.SILAGE then
		self.rewardPerHa = BaleMission.REWARD_PER_HA_SILAGE
	else
		self.rewardPerHa = BaleMission.REWARD_PER_HA_HAY
	end
end

function BaleMission:getVehicleVariant()
	if self.fillType == FillType.SILAGE then
		return "SILAGE"
	else
		return "HAY"
	end
end

function BaleMission:getData()
	local l10nString = nil

	if self.fillType == FillType.SILAGE then
		l10nString = "fieldJob_desc_baling_silage"
	else
		l10nString = "fieldJob_desc_baling_hay"
	end

	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_baling"),
		action = g_i18n:getText("fieldJob_desc_action_baling"),
		description = string.format(g_i18n:getText(l10nString), self.field.fieldId, self:getStationName())
	}
end

function BaleMission:getCompletion()
	local transportCompletion = math.min(1, self.depositedLiters / self.expectedLiters / BaleMission.FILL_SUCCESS_FACTOR)
	local fieldCompletion = self:getFieldCompletion()
	local mowCompletion = math.min(1, fieldCompletion / AbstractMission.SUCCESS_FACTOR)

	return 0.2 * mowCompletion + 0.8 * transportCompletion
end

function BaleMission:getStationName()
	local stationName = self.sellPoint.stationName

	if g_i18n:hasText(stationName, g_currentMission.missionInfo.customEnvironment) then
		stationName = g_i18n:getText(stationName, g_currentMission.missionInfo.customEnvironment)
	end

	return stationName
end

function BaleMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	local fruitType = FruitType.GRASS
	local ids = g_currentMission.fruits[fruitType]

	if ids ~= nil and ids.id ~= 0 then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

		if fruitDesc ~= nil then
			local densityValue = fruitDesc.cutState + 1

			self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, "pvv")
			self.completionFilter:setValueCompareParams("equal", densityValue)

			local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

			return area, totalArea
		end
	end

	return 0, 0
end

function BaleMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_HARVESTED
end

g_missionManager:registerMissionType(BaleMission, "mow_bale", MissionManager.CATEGORY_GRASS_FIELD)
