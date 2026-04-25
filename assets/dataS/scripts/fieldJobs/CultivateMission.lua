CultivateMission = {
	REWARD_PER_HA = 600
}
local CultivateMission_mt = Class(CultivateMission, AbstractFieldMission)

InitStaticObjectClass(CultivateMission, "CultivateMission", ObjectIds.MISSION_CULTIVATE)

function CultivateMission:new(isServer, isClient, customMt)
	local self = AbstractFieldMission:new(isServer, isClient, customMt or CultivateMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.CULTIVATOR] = true
	}
	self.rewardPerHa = CultivateMission.REWARD_PER_HA
	self.reimbursementPerHa = 0
	local detailId = g_currentMission.terrainDetailId
	self.completionModifier = DensityMapModifier:new(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	self.completionFilter = DensityMapFilter:new(self.completionModifier)

	self.completionFilter:setValueCompareParams("equal", g_currentMission.cultivatorValue)

	return self
end

function CultivateMission:finish(...)
	CultivateMission:superClass().finish(self, ...)

	self.field.fruitType = FruitType.UNKNOWN
end

function CultivateMission:completeField()
	local sprayLevel = self.sprayFactor * g_currentMission.sprayLevelMaxValue

	if self.field.fruitType == FruitType.OILSEEDRADISH then
		sprayLevel = math.min(sprayLevel + 1, g_currentMission.sprayLevelMaxValue)
	end

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_CULTIVATED, 0, sprayLevel, self.fieldSpraySet, self.fieldPlowFactor)
	end
end

function CultivateMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local x, z = field:getCenterOfFieldWorldPosition()

	if fruitDesc == nil then
		return false
	end

	if fruitDesc.minHarvestingGrowthState == 2 and fruitDesc.maxHarvestingGrowthState == 2 and fruitDesc.cutState == 3 then
		local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, 1, 2, 0, 0, 0, false)

		if area > 0 then
			return true, FieldManager.FIELDSTATE_GROWING, 2
		end
	end

	local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)

	if area > 0 then
		return true, FieldManager.FIELDSTATE_HARVESTED
	end

	local state = fruitDesc.numGrowthStates
	local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, state, state, 0, 0, 0, false)

	if area > 0 then
		return true, FieldManager.FIELDSTATE_GROWING, state + 1
	end

	return false
end

function CultivateMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_cultivating"),
		action = g_i18n:getText("fieldJob_desc_action_cultivating"),
		description = string.format(g_i18n:getText("fieldJob_desc_cultivating"), self.field.fieldId)
	}
end

function CultivateMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, "pvv")

	local density, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function CultivateMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_PLOWED and event ~= FieldManager.FIELDEVENT_CULTIVATED
end

g_missionManager:registerMissionType(CultivateMission, "cultivate")
