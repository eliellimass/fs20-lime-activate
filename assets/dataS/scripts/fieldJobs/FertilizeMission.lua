FertilizeMission = {
	REWARD_PER_HA = 400,
	REIMBURSEMENT_PER_HA = 1150
}
local FertilizeMission_mt = Class(FertilizeMission, AbstractFieldMission)

InitStaticObjectClass(FertilizeMission, "FertilizeMission", ObjectIds.MISSION_FERTILIZE)

function FertilizeMission:new(isServer, isClient, customMt)
	local self = AbstractFieldMission:new(isServer, isClient, customMt or FertilizeMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.SPRAYER] = true
	}
	self.rewardPerHa = FertilizeMission.REWARD_PER_HA
	self.reimbursementPerHa = FertilizeMission.REIMBURSEMENT_PER_HA
	self.reimbursementPerDifficulty = true
	self.completionModifier = DensityMapModifier:new(g_currentMission.terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	self.completionFilter = DensityMapFilter:new(self.completionModifier)
	self.completionMaskFilter = DensityMapFilter:new(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	self.completionMaskFilter:setValueCompareParams("greater", 0)

	return self
end

function FertilizeMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, math.min(self.sprayFactor * g_currentMission.sprayLevelMaxValue + 1, g_currentMission.sprayLevelMaxValue), true, self.fieldPlowFactor)
	end
end

function FertilizeMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local x, z = field:getCenterOfFieldWorldPosition()
	local sprayLevel = sprayFactor * g_currentMission.sprayLevelMaxValue

	if fruitDesc == nil then
		return false
	end

	if fruitDesc.minHarvestingGrowthState == 2 and fruitDesc.maxHarvestingGrowthState == 2 and fruitDesc.cutState == 3 then
		return false
	end

	if fieldSpraySet then
		return false
	end

	if g_currentMission.sprayLevelMaxValue <= sprayLevel then
		return false
	end

	if maxWeedState == 2 or maxWeedState == 3 then
		return false
	end

	local maxGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)

	if maxGrowthState == 0 or fruitDesc.minHarvestingGrowthState <= maxGrowthState then
		return false
	end

	return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
end

function FertilizeMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_fertilizing"),
		action = g_i18n:getText("fieldJob_desc_action_fertilizing"),
		description = string.format(g_i18n:getText("fieldJob_desc_fertilizing"), self.field.fieldId),
		extraText = string.format(g_i18n:getText("fieldJob_desc_fillTheUnit"), g_fillTypeManager:getFillTypeByIndex(FillType.FERTILIZER).title)
	}
end

function FertilizeMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	local detailId = g_currentMission.terrainDetailId
	local density, area, totalArea = nil
	local ids = g_currentMission.fruits[self.field.fruitType]

	if ids ~= nil and ids.id ~= 0 then
		self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, "pvv")

		local newSprayFactor = self.sprayFactor * g_currentMission.sprayLevelMaxValue

		self.completionFilter:setValueCompareParams("greater", newSprayFactor)

		density, area, totalArea = self.completionModifier:executeGet(self.completionFilter, self.completionMaskFilter)
	end

	return area, totalArea
end

function FertilizeMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_GROWN
end

g_missionManager:registerMissionType(FertilizeMission, "fertilize")
