FSDensityMapUtil = {}
local PARAM_BETWEEN = "between"
local PARAM_GREATER = "greater"
local PARAM_EQUAL = "equal"
local MODIFIER_3POINTS = "ppp"
FSDensityMapUtil.DEBUG_ENABLED = false

function FSDensityMapUtil.initTerrain(terrainDetailId)
	local modifiers = g_currentMission.densityMapModifiers
	modifiers.cutFruitArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifiers.cutFruitArea.filter1 = DensityMapFilter:new(modifiers.cutFruitArea.modifier)
	modifiers.cutFruitArea.filter2 = DensityMapFilter:new(modifiers.cutFruitArea.modifier)
	modifiers.updateDestroyCommonArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifiers.updateDestroyCommonArea.filter1 = DensityMapFilter:new(modifiers.updateDestroyCommonArea.modifier)
	modifiers.updateDestroyCommonArea.filter2 = DensityMapFilter:new(modifiers.updateDestroyCommonArea.modifier)
	modifiers.updateDestroyCommonArea.filter3 = DensityMapFilter:new(modifiers.updateDestroyCommonArea.modifier)
	modifiers.updateDestroyCommonArea.multiModifiers = {}
	modifiers.getFruitArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.getFruitArea.filter = DensityMapFilter:new(modifiers.getFruitArea.modifier)
	modifiers.setGroundTypeLayerArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.setGroundTypeLayerArea.filter1 = DensityMapFilter:new(modifiers.setGroundTypeLayerArea.modifier)
	modifiers.setGroundTypeLayerArea.filter2 = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateFruitPreparerArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateFruitPreparerArea.filter = DensityMapFilter:new(modifiers.updateFruitPreparerArea.modifier)
	modifiers.updateRollerArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateRollerArea.filter1 = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateRollerArea.filter2 = DensityMapFilter:new(modifiers.updateRollerArea.modifier)
	modifiers.updateDirectSowingArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifiers.updateDirectSowingArea.filter1 = DensityMapFilter:new(modifiers.updateDirectSowingArea.modifier)
	modifiers.updateDirectSowingArea.filter2 = DensityMapFilter:new(modifiers.updateDirectSowingArea.modifier)
	modifiers.updateSowingArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateSowingArea.filter1 = DensityMapFilter:new(modifiers.updateSowingArea.modifier)
	modifiers.updateSowingArea.filter2 = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getStatus.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getStatus.filter1 = DensityMapFilter:new(modifiers.getStatus.modifier)
	modifiers.getStatus.filter2 = DensityMapFilter:new(modifiers.getStatus.modifier)
	modifiers.getFieldStatus.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getFieldStatus.filter1 = DensityMapFilter:new(modifiers.getFieldStatus.modifier)
	modifiers.getFieldStatus.filter2 = DensityMapFilter:new(modifiers.getFieldStatus.modifier)

	modifiers.getFieldStatus.filter2:setValueCompareParams(PARAM_GREATER, 0)

	modifiers.updateFertilizerArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.updateFertilizerArea.filter = DensityMapFilter:new(modifiers.updateFertilizerArea.modifier)
	modifiers.updateFertilizerArea.maskFilter = DensityMapFilter:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifiers.updateLimeArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.updateLimeArea.filter1 = DensityMapFilter:new(terrainDetailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
	modifiers.updateLimeArea.filter2 = DensityMapFilter:new(terrainDetailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
	modifiers.resetSprayArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.resetSprayArea.filter1 = DensityMapFilter:new(modifiers.resetSprayArea.modifier)
	modifiers.resetSprayArea.filter2 = DensityMapFilter:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)

	modifiers.resetSprayArea.filter2:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.sprayLevelMaxValue)

	modifiers.removeSprayArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.removeSprayArea.filter = DensityMapFilter:new(modifiers.removeSprayArea.modifier)
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local ids = g_currentMission.fruits[weedType.index]
		modifiers.setWeedArea.modifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.setWeedArea.filter = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		modifiers.removeWeedArea.modifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.removeWeedArea.filter = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		modifiers.getWeedFactor.modifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.getWeedFactor.filter = DensityMapFilter:new(modifiers.getWeedFactor.modifier)
		modifiers.getWeedFactor.maskFilter = DensityMapFilter:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.updateHerbicideArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
		modifiers.updateHerbicideArea.weedFilter = DensityMapFilter:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.updateHerbicideArea.maskFilter = DensityMapFilter:new(modifiers.updateHerbicideArea.modifier)
		modifiers.updateWeederArea.modifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		modifiers.updateWeederArea.filter1 = DensityMapFilter:new(modifiers.updateWeederArea.modifier)
		modifiers.updateWeederArea.filter2 = DensityMapFilter:new(modifiers.updateWeederArea.modifier)
	end

	modifiers.updateSubsoilerArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
	modifiers.updateSubsoilerArea.filter = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateCultivatorArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updateCultivatorArea.filter1 = DensityMapFilter:new(modifiers.updateCultivatorArea.modifier)
	modifiers.updateCultivatorArea.filter2 = DensityMapFilter:new(modifiers.updateCultivatorArea.modifier)
	modifiers.updatePlowArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.updatePlowArea.filter = DensityMapFilter:new(modifiers.updatePlowArea.modifier)
	modifiers.getFieldValue.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getFieldValue.filter = DensityMapFilter:new(modifiers.getFieldValue.modifier)
	modifiers.getAreaDensity.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getAreaDensity.filter = DensityMapFilter:new(modifiers.getFieldValue.modifier)
	modifiers.getFieldDensity.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getFieldDensity.filter = DensityMapFilter:new(modifiers.getFieldDensity.modifier)
	modifiers.updateWheelDestructionArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifiers.updateWheelDestructionArea.multiModifier = nil
	modifiers.updateWheelDestructionArea.filter1 = DensityMapFilter:new(modifiers.updateWheelDestructionArea.modifier)
	modifiers.updateWheelDestructionArea.filter2 = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	modifiers.updateWheelDestructionArea.filter2:setValueCompareParams("greater", 0)

	modifiers.getAIDensityHeightArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifiers.getAIDensityHeightArea.filter = DensityMapFilter:new(modifiers.getAIDensityHeightArea.modifier)
	modifiers.removeFieldArea.modifier = DensityMapModifier:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
end

function FSDensityMapUtil.getFieldValue(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = g_currentMission.densityMapModifiers.getFieldValue
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter:setValueCompareParams("greater", 0)

	local density, area, _ = modifier:executeGet(filter)

	return density, area
end

function FSDensityMapUtil.cutFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, destroySeedingWidth, useMinForageState, excludedSprayType, setsWeeds)
	local ids = g_currentMission.fruits[fruitIndex]

	if ids == nil or ids.id == 0 then
		return 0
	end

	local modifiers = g_currentMission.densityMapModifiers.cutFruitArea
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2
	local detailId = g_currentMission.terrainDetailId
	local id = ids.id
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	local value = desc.cutState + 1
	local minState = desc.minHarvestingGrowthState

	if useMinForageState then
		minState = desc.minForageGrowthState
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter1:resetDensityMapAndChannels(id, desc.startStateChannel, desc.numStateChannels)
	filter1:setValueCompareParams(PARAM_BETWEEN, minState + 1, desc.maxHarvestingGrowthState + 1)

	local sprayPixelsSum, _, _ = modifier:executeGet(filter1)

	if destroySpray then
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
		modifier:executeSet(0, filter1)
	end

	if desc.startSprayState > 0 then
		modifier:executeSet(math.min(desc.startSprayState, g_currentMission.sprayLevelMaxValue), filter1)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
	end

	local plowTotalDelta = 0
	local limeTotalDelta = 0
	local weedFactor = 1
	local missionInfo = g_currentMission.missionInfo

	if missionInfo.weedsEnabled and desc.plantsWeed then
		weedFactor = FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)

		if setsWeeds then
			FSDensityMapUtil.setWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		else
			FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		end
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	if desc.lowSoilDensityRequired then
		modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
		filter2:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
		filter2:setValueCompareParams(PARAM_GREATER, 0)

		_, plowTotalDelta, _ = modifier:executeGet(filter1, filter2)
	end

	if desc.increasesSoilDensity and missionInfo.plowingRequiredEnabled then
		modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)

		_, _, _, _ = modifier:executeAdd(-1, filter1)
	end

	if desc.consumesLime and missionInfo.limeRequired then
		modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)

		_, _, limeTotalDelta, _ = modifier:executeAdd(-1, filter1)
	end

	if desc.useSeedingWidth and (destroySeedingWidth == nil or destroySeedingWidth) then
		modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		modifier:executeSet(g_currentMission.sowingValue, filter1)
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	local terrainDetailPixelsSum, _, _ = modifier:executeGet(filter1)

	modifier:resetDensityMapAndChannels(id, desc.startStateChannel, desc.numStateChannels)
	modifier:setReturnValueShift(-1)
	filter2:resetDensityMapAndChannels(id, desc.startStateChannel, desc.numStateChannels)

	local maxArea = 0
	local growthState = minState

	for i = minState, desc.maxHarvestingGrowthState do
		filter2:setValueCompareParams(PARAM_EQUAL, i + 1)

		local _, area = modifier:executeGet(filter2)

		if maxArea < area then
			growthState = i
			maxArea = area
		end
	end

	local density, numPixels, totalNumPixels = modifier:executeSet(value, filter1)
	local plowFactor = 0
	local limeFactor = 0
	local sprayFactor = 0

	if numPixels > 0 then
		if desc.lowSoilDensityRequired and missionInfo.plowingRequiredEnabled then
			plowFactor = math.abs(plowTotalDelta) / numPixels
		else
			plowFactor = 1
		end

		if desc.growthRequiresLime and missionInfo.limeRequired then
			limeFactor = math.abs(limeTotalDelta) / numPixels
		else
			limeFactor = 1
		end

		sprayFactor = sprayPixelsSum / (numPixels * g_currentMission.sprayLevelMaxValue)
	end

	if desc.allowsPartialGrowthState then
		return density / desc.maxHarvestingGrowthState, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, growthState, maxArea, terrainDetailPixelsSum
	else
		return numPixels, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, growthState, maxArea, terrainDetailPixelsSum
	end
end

function FSDensityMapUtil.getFruitArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, allowPreparing, useMinForageState)
	if allowPreparing == nil then
		allowPreparing = false
	end

	local ids = g_currentMission.fruits[fruitId]

	if ids == nil or ids.id == 0 then
		return 0, 0
	end

	local id = ids.id
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local minState = desc.minHarvestingGrowthState

	if useMinForageState then
		minState = desc.minForageGrowthState
	end

	local modifiers = g_currentMission.densityMapModifiers.getFruitArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:resetDensityMapAndChannels(id, desc.startStateChannel, desc.numStateChannels)
	filter:resetDensityMapAndChannels(id, desc.startStateChannel, desc.numStateChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	modifier:setReturnValueShift(-1)
	filter:setValueCompareParams(PARAM_BETWEEN, minState + 1, desc.maxHarvestingGrowthState + 1)

	local ret, numPixels, totalNumPixels = modifier:executeGet(filter)

	if allowPreparing and desc.minPreparingGrowthState >= 0 and desc.maxPreparingGrowthState >= 0 then
		filter:setValueCompareParams(PARAM_BETWEEN, desc.minPreparingGrowthState + 1, desc.maxPreparingGrowthState + 1)

		local ret2, numPixels2, totalNumPixels2 = modifier:executeGet(filter)
		ret = ret + ret2
		numPixels = numPixels + numPixels2
		totalNumPixels = totalNumPixels + totalNumPixels2
	end

	local maxArea = 0
	local growthState = minState

	for i = minState, desc.maxHarvestingGrowthState do
		filter:setValueCompareParams(PARAM_EQUAL, i + 1)

		local _, area = modifier:executeGet(filter)

		if maxArea < area then
			growthState = i
			maxArea = area
		end
	end

	return ret, numPixels, totalNumPixels, growthState
end

function FSDensityMapUtil.updateRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local detailId = g_currentMission.terrainDetailId
	local modifiers = g_currentMission.densityMapModifiers.updateRollerArea
	local modifier = modifiers.modifier
	local noGrassFilter = modifiers.filter1
	local filter = modifiers.filter2
	local terrainDetailTypeFirstChannel = g_currentMission.terrainDetailTypeFirstChannel
	local terrainDetailTypeNumChannels = g_currentMission.terrainDetailTypeNumChannels

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	noGrassFilter:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.grassValue - 1)

	for index, entry in pairs(g_currentMission.fruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

		if desc.destroyedByRoller then
			modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter:setValueCompareParams(PARAM_GREATER, 0)
			modifier:setNewTypeIndexMode("zero")
			modifier:executeSet(0, filter, noGrassFilter)
		end
	end

	modifier:setNewTypeIndexMode("keep")
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
		local id = g_currentMission.dynamicFoliageLayers[i]
		local numChannels = getTerrainDetailNumChannels(id)

		modifier:resetDensityMapAndChannels(id, 0, numChannels)
		modifier:executeSet(0)
	end

	modifier:resetDensityMapAndChannels(detailId, terrainDetailTypeFirstChannel, terrainDetailTypeNumChannels)
	filter:resetDensityMapAndChannels(detailId, terrainDetailTypeFirstChannel, terrainDetailTypeNumChannels)
	filter:setValueCompareParams(PARAM_EQUAL, 0)

	local _, areaBefore, _ = modifier:executeGet(filter)

	modifier:executeSet(0, noGrassFilter)

	local _, areaAfter, _ = modifier:executeGet(filter)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
	local entry = g_currentMission.fruits[desc.index]

	modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
	filter:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
	filter:setValueCompareParams(PARAM_GREATER, 1)
	modifier:executeSet(desc.cutState + 1, filter)

	return areaAfter - areaBefore
end

function FSDensityMapUtil.removeFieldArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = g_currentMission.densityMapModifiers.removeFieldArea
	local modifier = modifiers.modifier
	local detailId = g_currentMission.terrainDetailId

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifier:executeSet(0)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifier:executeSet(0)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
	modifier:executeSet(0)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	modifier:executeSet(0)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
	modifier:executeSet(0)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
	modifier:executeSet(0)

	for index, entry in pairs(g_currentMission.fruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

		modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
		modifier:setNewTypeIndexMode("zero")
		modifier:executeSet(0)
	end

	modifier:setNewTypeIndexMode("keep")

	for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
		local id = g_currentMission.dynamicFoliageLayers[i]
		local numChannels = getTerrainDetailNumChannels(id)

		modifier:resetDensityMapAndChannels(id, 0, numChannels)
		modifier:executeSet(0)
	end
end

function FSDensityMapUtil.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, commonForced, angle, blockedSprayTypeIndex, setsWeeds)
	local modifiers = g_currentMission.densityMapModifiers.updateCultivatorArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter1
	local cultivatorValue = g_currentMission.cultivatorValue
	createField = Utils.getNoNil(createField, true)
	commonForced = Utils.getNoNil(commonForced, true)
	angle = angle or 0

	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, not commonForced, false)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter:setValueCompareParams(PARAM_EQUAL, cultivatorValue)

	local _, areaBefore, _ = modifier:executeGet(filter)

	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)

	local totalArea = 0
	local changedArea = 0
	local filter2 = nil

	if createField then
		filter2 = nil
	else
		filter2 = g_currentMission.densityMapModifiers.updateCultivatorArea.filter2

		filter2:setValueCompareParams(PARAM_GREATER, cultivatorValue)
	end

	_, _, totalArea = modifier:executeSet(cultivatorValue, filter2)

	modifier:setDensityMapChannels(g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
	modifier:executeSet(angle, filter)
	modifier:setDensityMapChannels(g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	local _, areaAfter, _ = modifier:executeGet(filter)
	changedArea = areaAfter - areaBefore

	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	if g_currentMission.missionInfo.weedsEnabled then
		if setsWeeds then
			FSDensityMapUtil.setWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		else
			FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		end
	end

	return changedArea, totalArea
end

function FSDensityMapUtil.updateSubsoilerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced)
	local changedArea, totalArea = nil
	forced = forced or true
	local modifier = g_currentMission.densityMapModifiers.updateSubsoilerArea.modifier

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

	if forced then
		_, changedArea, totalArea = modifier:executeSet(g_currentMission.plowCounterMaxValue)
	else
		local filter = g_currentMission.densityMapModifiers.updateSubsoilerArea.filter

		filter:setValueCompareParams(PARAM_GREATER, 0)

		_, changedArea, totalArea = modifier:executeSet(g_currentMission.plowCounterMaxValue, filter)
	end

	return changedArea, totalArea
end

function FSDensityMapUtil.updatePlowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle, resetPlowCounter)
	local value = g_currentMission.plowValue
	local detailId = g_currentMission.terrainDetailId
	local modifiers = g_currentMission.densityMapModifiers.updatePlowArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter
	forced = Utils.getNoNil(forced, true)
	commonForced = Utils.getNoNil(commonForced, true)
	angle = angle or 0
	resetPlowCounter = Utils.getNoNil(resetPlowCounter, true)

	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, not commonForced)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter:setValueCompareParams(PARAM_EQUAL, value)

	local _, areaBefore, _ = modifier:executeGet(filter)
	local totalArea = 0

	if forced then
		_, _, totalArea = modifier:executeSet(value)

		if resetPlowCounter then
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			modifier:executeSet(g_currentMission.plowCounterMaxValue)
		end

		modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
		modifier:executeSet(angle)
	else
		filter:setValueCompareParams(PARAM_GREATER, 0)

		_, _, totalArea = modifier:executeSet(value, filter)

		if resetPlowCounter then
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			modifier:executeSet(g_currentMission.plowCounterMaxValue, filter)
		end

		modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
		modifier:executeSet(angle, filter)
	end

	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false)
	filter:setValueCompareParams(PARAM_EQUAL, value)

	local _, areaAfter, _ = modifier:executeGet(filter)
	local changedArea = areaAfter - areaBefore

	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return changedArea, totalArea
end

function FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField, addFertilizerLock)
	limitToField = Utils.getNoNil(limitToField, false)
	addFertilizerLock = Utils.getNoNil(addFertilizerLock, true)
	local detailId = g_currentMission.terrainDetailId
	local modifiers = g_currentMission.densityMapModifiers.updateDestroyCommonArea
	local modifier = modifiers.modifier
	local multiModifiers = modifiers.multiModifiers

	if multiModifiers[limitToField] == nil then
		multiModifiers[limitToField] = {}
	end

	local multiModifier = multiModifiers[limitToField][addFertilizerLock]
	local filter = modifiers.filter1
	local maskFilter = modifiers.filter2
	local preparingFilter = modifiers.filter3

	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier:new()
		multiModifiers[limitToField][addFertilizerLock] = multiModifier

		filter:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
		filter:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.sprayLevelMaxValue - 1)

		local firstEntry, firstDesc = nil

		for index, entry in pairs(g_currentMission.fruits) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

			if firstEntry == nil then
				firstEntry = entry
				firstDesc = desc
			end

			if desc.weed == nil then
				maskFilter:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
				maskFilter:setValueCompareParams(PARAM_BETWEEN, 2, desc.cutState - 1)
				modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
				multiModifier:addExecuteAdd(1, modifier, filter, maskFilter)

				if addFertilizerLock then
					modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
					multiModifier:addExecuteSet(1, modifier, maskFilter)
				end
			end

			if entry.preparingOutputId ~= 0 then
				preparingFilter:resetDensityMapAndChannels(entry.preparingOutputId, 0, 1)
				preparingFilter:setValueCompareParams(PARAM_GREATER, 0)
				modifier:resetDensityMapAndChannels(entry.preparingOutputId, 0, 1)
				multiModifier:addExecuteSet(0, modifier, preparingFilter)
			end
		end

		filter:resetDensityMapAndChannels(firstEntry.id, firstDesc.startStateChannel, firstDesc.numStateChannels)
		filter:setTypeIndexCompareMode("none")
		maskFilter:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		maskFilter:setValueCompareParams(PARAM_GREATER, 0)
		modifier:resetDensityMapAndChannels(firstEntry.id, firstDesc.startStateChannel, firstDesc.numStateChannels)
		modifier:setNewTypeIndexMode("zero")

		if limitToField then
			multiModifier:addExecuteSet(0, modifier, filter, maskFilter)
		else
			multiModifier:addExecuteSet(0, modifier, filter)
		end

		for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)

			modifier:resetDensityMapAndChannels(id, 0, numChannels)

			if limitToField then
				multiModifier:addExecuteSet(0, modifier, maskFilter)
			else
				multiModifier:addExecuteSet(0, modifier)
			end
		end
	end

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	multiModifier:execute(false)
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, nil)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end

function FSDensityMapUtil.updateWheelDestructionArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = g_currentMission.densityMapModifiers.updateWheelDestructionArea
	local modifier = modifiers.modifier
	local multiModifier = modifiers.multiModifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2

	for _, updater in pairs(g_currentMission.fieldCropsUpdaters) do
		if updater.updater ~= nil then
			setCropsIgnoreDensityChanges(updater.updater, true)
		end
	end

	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier:new()
		modifiers.multiModifier = multiModifier

		for index, entry in pairs(g_currentMission.fruits) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

			if desc.destruction ~= nil then
				modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
				filter1:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)

				local onlyOnFieldFilter = nil

				if desc.destruction.onlyOnField then
					onlyOnFieldFilter = filter2
				end

				filter1:setValueCompareParams("between", desc.destruction.filterStart, desc.destruction.filterEnd)
				multiModifier:addExecuteSet(desc.destruction.state, modifier, filter1, onlyOnFieldFilter)
			end
		end

		for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)

			modifier:resetDensityMapAndChannels(id, 0, numChannels)
			multiModifier:addExecuteSet(0, modifier)
		end
	end

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, "ppp")
	multiModifier:execute(false)

	for _, updater in pairs(g_currentMission.fieldCropsUpdaters) do
		if updater.updater ~= nil then
			setCropsIgnoreDensityChanges(updater.updater, false)
		end
	end
end

function FSDensityMapUtil.setGroundTypeLayerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local modifiers = g_currentMission.densityMapModifiers.setGroundTypeLayerArea
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter1:setValueCompareParams(PARAM_BETWEEN, 0, value - 1)
	filter2:setValueCompareParams(PARAM_GREATER, 0)

	local _, numPixels, totalNumPixels = modifier:executeSet(value, filter1, filter2)

	filter1:setValueCompareParams(PARAM_GREATER, value)

	local _, numPixels2, totalNumPixels2 = modifier:executeSet(value, filter1, filter2)

	return numPixels + numPixels2, totalNumPixels + totalNumPixels2
end

function FSDensityMapUtil.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayTypeIndex)
	local numPixels = 0
	local totalNumPixels = 0
	local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)

	if desc ~= nil then
		if desc.isLime then
			numPixels, totalNumPixels = FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.groundType)
		elseif desc.isFertilizer then
			numPixels, totalNumPixels = FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.groundType)
		elseif desc.isHerbicide then
			numPixels, totalNumPixels = FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.groundType)
		end
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	local modifiers = g_currentMission.densityMapModifiers.removeSprayArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

	if blockedSprayTypeIndex ~= nil then
		local sprayType = g_sprayTypeManager:getSprayTypeByIndex(blockedSprayTypeIndex)

		if sprayType.groundType > 0 then
			filter:setValueCompareParams(PARAM_GREATER, sprayType.groundType)
			modifier:executeSet(0, filter)

			if sprayType.groundType > 0 then
				filter:setValueCompareParams(PARAM_BETWEEN, 0, sprayType.groundType - 1)
				modifier:executeSet(0, filter)
			end
		end
	else
		filter:setValueCompareParams(PARAM_GREATER, 0)
		modifier:executeSet(0, filter)
	end
end

function FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local detailId = g_currentMission.terrainDetailId
	local modifiers = g_currentMission.densityMapModifiers.updateFertilizerArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter
	local maskFilter = modifiers.maskFilter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	maskFilter:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.sprayLevelMaxValue - 1)

	local maskValue = g_currentMission.sprayMaxValue

	if g_currentMission.sprayNumChannels == 1 then
		groundType = 1
	end

	filter:setValueCompareParams(PARAM_GREATER, groundType)
	modifier:executeSet(maskValue, filter, maskFilter)

	if groundType > 0 then
		filter:setValueCompareParams(PARAM_BETWEEN, 0, groundType - 1)
		modifier:executeSet(maskValue, filter, maskFilter)
	end

	filter:setValueCompareParams(PARAM_EQUAL, maskValue)
	maskFilter:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	maskFilter:setValueCompareParams(PARAM_EQUAL, 0)
	modifier:executeSet(0, filter, maskFilter)

	for index, entry in pairs(g_currentMission.fruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

		if desc.weed == nil then
			maskFilter:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			maskFilter:setValueCompareParams(PARAM_BETWEEN, desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState)
			modifier:executeSet(0, filter, maskFilter)
		end
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	maskFilter:resetDensityMapAndChannels(modifier)
	maskFilter:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.sprayLevelMaxValue - 1)

	local _, _, numPixels, totalNumPixels = modifier:executeAdd(1, filter, maskFilter)

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	modifier:executeSet(groundType, filter)

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local modifiers = g_currentMission.densityMapModifiers.updateLimeArea
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2
	local detailId = g_currentMission.terrainDetailId
	local limeCounterFirstChannel = g_currentMission.limeCounterFirstChannel
	local limeCounterNumChannels = g_currentMission.limeCounterNumChannels
	local limeCounterMaxValue = g_currentMission.limeCounterMaxValue
	local terrainDetailTypeFirstChannel = g_currentMission.terrainDetailTypeFirstChannel
	local terrainDetailTypeNumChannels = g_currentMission.terrainDetailTypeNumChannels

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter2:setValueCompareParams(PARAM_BETWEEN, 0, limeCounterMaxValue - 1)

	local numPixels = 0
	local totalNumPixels = 0

	for index, entry in pairs(g_currentMission.fruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

		if desc.weed == nil then
			filter1:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter1:setValueCompareParams(PARAM_BETWEEN, 1, desc.minHarvestingGrowthState)
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

			local _, _, _ = modifier:executeSet(groundType, filter1)

			modifier:resetDensityMapAndChannels(detailId, limeCounterFirstChannel, limeCounterNumChannels)

			local _, numP, _ = modifier:executeSet(limeCounterMaxValue, filter1, filter2)
			numPixels = numPixels + numP

			filter1:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter1:setValueCompareParams(PARAM_EQUAL, desc.cutState + 1)
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

			local _, _, _ = modifier:executeSet(groundType, filter1)

			modifier:resetDensityMapAndChannels(detailId, limeCounterFirstChannel, limeCounterNumChannels)

			local _, numP, _ = modifier:executeSet(limeCounterMaxValue, filter1, filter2)
			numPixels = numPixels + numP
		end
	end

	filter1:resetDensityMapAndChannels(detailId, terrainDetailTypeFirstChannel, terrainDetailTypeNumChannels)
	filter1:setValueCompareParams(PARAM_BETWEEN, g_currentMission.cultivatorValue, g_currentMission.plowValue)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

	local _, _, _ = modifier:executeSet(groundType, filter1)

	modifier:resetDensityMapAndChannels(detailId, limeCounterFirstChannel, limeCounterNumChannels)

	local _, numP, totalNumP = modifier:executeSet(limeCounterMaxValue, filter1, filter2)
	numPixels = numPixels + numP
	totalNumPixels = totalNumP

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local numPixels = 0
	local totalNumPixels = 0
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local modifiers = g_currentMission.densityMapModifiers.updateHerbicideArea
		local modifier = modifiers.modifier
		local weedFilter = modifiers.weedFilter
		local maskFilter = modifiers.maskFilter

		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

		local weedFruitId = g_currentMission.fruits[weedType.index]
		local weed = weedType.weed
		local detailId = g_currentMission.terrainDetailId

		for _, data in ipairs(weed.herbicideReplaces) do
			weedFilter:setValueCompareParams(PARAM_EQUAL, data.src)

			for index, entry in pairs(g_currentMission.fruits) do
				local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

				if desc.weed == nil then
					maskFilter:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
					maskFilter:setValueCompareParams(PARAM_BETWEEN, 1, desc.minHarvestingGrowthState)
					modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

					local _, _, _ = modifier:executeSet(groundType, maskFilter, weedFilter)

					modifier:resetDensityMapAndChannels(weedFruitId.id, weedType.startStateChannel, weedType.numStateChannels)

					local _, numP, totalNumP = modifier:executeSet(data.target, weedFilter, maskFilter)
					numPixels = numPixels + numP
					totalNumPixels = totalNumPixels + totalNumP

					maskFilter:setValueCompareParams(PARAM_EQUAL, desc.cutState + 1)
					modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

					local _, _, _ = modifier:executeSet(groundType, maskFilter, weedFilter)

					modifier:resetDensityMapAndChannels(weedFruitId.id, weedType.startStateChannel, weedType.numStateChannels)

					_, numP, totalNumP = modifier:executeSet(data.target, weedFilter, maskFilter)
					numPixels = numPixels + numP
					totalNumPixels = totalNumPixels + totalNumP

					if desc.destruction ~= nil and desc.destruction.state ~= desc.cutState + 1 then
						maskFilter:setValueCompareParams(PARAM_BETWEEN, desc.destruction.state, desc.destruction.state)
						modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

						local _, _, _ = modifier:executeSet(groundType, maskFilter, weedFilter)

						modifier:resetDensityMapAndChannels(weedFruitId.id, weedType.startStateChannel, weedType.numStateChannels)

						_, numP, totalNumP = modifier:executeSet(data.target, weedFilter, maskFilter)
						numPixels = numPixels + numP
						totalNumPixels = totalNumPixels + totalNumP
					end
				end
			end

			maskFilter:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			maskFilter:setValueCompareParams(PARAM_EQUAL, g_currentMission.cultivatorValue)
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

			local _, _, _ = modifier:executeSet(groundType, maskFilter, weedFilter)

			modifier:resetDensityMapAndChannels(weedFruitId.id, weedType.startStateChannel, weedType.numStateChannels)

			local _, numP, totalNumP = modifier:executeSet(data.target, weedFilter, maskFilter)
			numPixels = numPixels + numP
			totalNumPixels = totalNumPixels + totalNumP

			maskFilter:setValueCompareParams(PARAM_EQUAL, g_currentMission.plowValue)
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)

			local _, _, _ = modifier:executeSet(groundType, maskFilter, weedFilter)

			modifier:resetDensityMapAndChannels(weedFruitId.id, weedType.startStateChannel, weedType.numStateChannels)

			local _, numP, totalNumP = modifier:executeSet(data.target, weedFilter, maskFilter)
			numPixels = numPixels + numP
			totalNumPixels = totalNumPixels + totalNumP
		end
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateWeederArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, maxGrowthState)
	local weedType = g_fruitTypeManager:getWeedFruitType()
	local numPixels = 0
	local totalNumPixels = 0

	if weedType ~= nil then
		local modifiers = g_currentMission.densityMapModifiers.updateWeederArea
		local modifier = modifiers.modifier
		local filter1 = modifiers.filter1
		local filter2 = modifiers.filter2
		local detailId = g_currentMission.terrainDetailId
		local weed = weedType.weed
		maxGrowthState = maxGrowthState or weed.maxValue

		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
		filter1:setValueCompareParams(PARAM_BETWEEN, 2, math.min(maxGrowthState, weed.maxValue))

		for index, entry in pairs(g_currentMission.fruits) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

			if desc.weed == nil then
				filter2:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
				filter2:setValueCompareParams(PARAM_BETWEEN, 1, 3)

				local _, numP, totalNumP = modifier:executeSet(0, filter1, filter2)
				numPixels = numPixels + numP
				totalNumPixels = totalNumPixels + totalNumP
			end
		end

		filter2:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		filter2:setValueCompareParams(PARAM_BETWEEN, g_currentMission.cultivatorValue, g_currentMission.plowValue)

		local _, numP, totalNumP = modifier:executeSet(0, filter1, filter2)
		numPixels = numPixels + numP
		totalNumPixels = totalNumPixels + totalNumP
	end

	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.GRASS_WINDROW)
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.DRYGRASS_WINDROW)

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, maxGrowthState)
	local weedType = g_fruitTypeManager:getWeedFruitType()
	local numPixels = 0
	local totalNumPixels = 0

	if weedType ~= nil then
		local modifiers = g_currentMission.densityMapModifiers.removeWeedArea
		local weed = weedType.weed
		maxGrowthState = maxGrowthState or weed.maxValue
		local modifier = modifiers.modifier

		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

		_, numPixels, totalNumPixels = modifier:executeSet(0)
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.setWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local modifier = g_currentMission.densityMapModifiers.setWeedArea.modifier
		local filter = g_currentMission.densityMapModifiers.setWeedArea.filter

		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
		filter:setValueCompareParams(PARAM_GREATER, 0)
		modifier:executeSet(Utils.getNoNil(value, 1), filter)
	end
end

function FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force, excludeType)
	local modifiers = g_currentMission.densityMapModifiers.resetSprayArea
	local modifier = modifiers.modifier

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

	local filter2 = nil

	if not force then
		filter2 = modifiers.filter2
	end

	if excludeType == nil then
		modifier:executeSet(0, filter2)
	else
		local filter1 = modifiers.filter1

		filter1:setValueCompareParams(PARAM_GREATER, excludeType)
		modifier:executeSet(0, filter1, filter2)

		if excludeType > 0 then
			filter1:setValueCompareParams(PARAM_BETWEEN, 0, excludeType - 1)
			modifier:executeSet(0, filter1, filter2)
		end
	end
end

function FSDensityMapUtil.updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, growthState, blockedSprayTypeIndex)
	local ids = g_currentMission.fruits[fruitId]

	if ids == nil or ids.id == 0 then
		return 0, 0
	end

	angle = angle or 0
	growthState = growthState or 1
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local detailId = g_currentMission.terrainDetailId
	local sowingValue = nil

	if desc.useSeedingWidth then
		sowingValue = g_currentMission.sowingWidthValue
	else
		sowingValue = g_currentMission.sowingValue
	end

	local modifiers = g_currentMission.densityMapModifiers.updateSowingArea
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	modifier:resetDensityMapAndChannels(ids.id, desc.startStateChannel, desc.numStateChannels)
	filter1:resetDensityMapAndChannels(ids.id, desc.startStateChannel, desc.numStateChannels)
	filter2:setValueCompareParams(PARAM_BETWEEN, g_currentMission.firstSowableValue, g_currentMission.lastSowableValue)
	filter1:setValueCompareParams(PARAM_GREATER, growthState)

	local _, numPixels1, _ = modifier:executeSet(growthState, filter1, filter2)

	filter1:setValueCompareParams(PARAM_EQUAL, 0)

	local _, numPixels2, _ = modifier:executeSet(growthState, filter1, filter2)

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	local _, _, totalArea = modifier:executeSet(sowingValue, filter2)

	filter2:setValueCompareParams(PARAM_BETWEEN, g_currentMission.firstSowingValue, g_currentMission.lastSowingValue)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
	modifier:executeSet(angle, filter2)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)

	if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
		FSDensityMapUtil.setWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	local changedArea = numPixels1 + numPixels2

	return changedArea, totalArea
end

function FSDensityMapUtil.updateDirectSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle, growthState, blockedSprayTypeIndex)
	local ids = g_currentMission.fruits[fruitId]

	if ids == nil or ids.id == 0 then
		return 0, 0
	end

	local detailId = g_currentMission.terrainDetailId
	local cultivatorValue = g_currentMission.cultivatorValue
	local modifiers = g_currentMission.densityMapModifiers.updateDirectSowingArea
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local sowingValue = g_currentMission.sowingValue

	if desc.useSeedingWidth then
		sowingValue = g_currentMission.sowingWidthValue
	end

	angle = angle or 0
	growthState = growthState or 1

	for index, entry in pairs(g_currentMission.fruits) do
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(index)

		if fruitDesc.weed == nil then
			filter2:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)

			if fruitDesc.cutState > 1 then
				filter2:setValueCompareParams(PARAM_BETWEEN, 2, fruitDesc.cutState)
				modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
				filter1:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
				filter1:setValueCompareParams(PARAM_BETWEEN, 0, g_currentMission.sprayLevelMaxValue - 1)
				modifier:executeAdd(1, filter1, filter2)
				modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
				modifier:executeSet(1, filter1, filter2)
			end

			if fruitDesc.allowsSeeding then
				modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
				filter1:resetDensityMapAndChannels(modifier)
				filter1:setValueCompareParams(PARAM_GREATER, 0)

				if index ~= fruitId then
					filter2:setValueCompareParams(PARAM_GREATER, 0)
					modifier:executeSet(cultivatorValue, filter1, filter2)
				else
					if growthState > 2 then
						filter2:setValueCompareParams(PARAM_BETWEEN, 1, math.min(2, growthState - 1))
						modifier:executeSet(cultivatorValue, filter1, filter2)
					end

					filter2:setValueCompareParams(PARAM_BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState) + 1)
					modifier:executeSet(cultivatorValue, filter1, filter2)
				end
			end

			modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter1:resetDensityMapAndChannels(modifier)

			if index ~= fruitId then
				filter1:setValueCompareParams(PARAM_BETWEEN, 2, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState) + 1)
			else
				filter1:setValueCompareParams(PARAM_BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState) + 1)
			end

			filter2:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			filter2:setValueCompareParams(PARAM_GREATER, 0)
			modifier:executeSet(0, filter1, filter2)
		end
	end

	filter2:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	filter2:setValueCompareParams(PARAM_BETWEEN, g_currentMission.firstSowableValue, g_currentMission.lastSowableValue)
	modifier:resetDensityMapAndChannels(ids.id, desc.startStateChannel, desc.numStateChannels)

	local _, changedArea, totalArea = modifier:executeSet(growthState, filter2)

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifier:executeSet(sowingValue, filter2)
	filter2:setValueCompareParams(PARAM_BETWEEN, g_currentMission.firstSowingValue, g_currentMission.lastSowingValue)
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
	modifier:executeSet(angle, filter2)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
		FSDensityMapUtil.setWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	return changedArea, totalArea
end

function FSDensityMapUtil.updateFruitPreparerArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ)
	local ids = g_currentMission.fruits[fruitId]

	if ids == nil or ids.id == 0 then
		return 0
	end

	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local modifiers = g_currentMission.densityMapModifiers.updateFruitPreparerArea
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	modifier:resetDensityMapAndChannels(ids.id, desc.startStateChannel, desc.numStateChannels)
	filter:resetDensityMapAndChannels(ids.id, desc.startStateChannel, desc.numStateChannels)
	filter:setValueCompareParams(PARAM_BETWEEN, desc.minPreparingGrowthState + 1, desc.maxPreparingGrowthState + 1)

	local _, numChangedPixels = modifier:executeSet(desc.preparedGrowthState + 1, filter)

	if ids.preparingOutputId ~= 0 and numChangedPixels > 0 then
		modifier:resetDensityMapAndChannels(ids.preparingOutputId, 0, 1)
		modifier:setParallelogramWorldCoords(startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, MODIFIER_3POINTS)
		filter:setValueCompareParams(PARAM_GREATER, 0)
		modifier:executeSet(1, filter)
	end

	return numChangedPixels
end

function FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if g_currentMission.tireTrackSystem ~= nil then
		g_currentMission.tireTrackSystem:eraseParallelogram(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
end

function FSDensityMapUtil.getAreaDensity(id, firstChannel, numChannels, value, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = g_currentMission.densityMapModifiers.getAreaDensity
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:resetDensityMapAndChannels(id, firstChannel, numChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter:setValueCompareParams(PARAM_EQUAL, value)

	return modifier:executeGet(filter)
end

function FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = g_currentMission.densityMapModifiers.getFieldDensity
	local modifier = modifiers.modifier
	local filter = modifiers.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)
	filter:setValueCompareParams(PARAM_GREATER, 0)

	return modifier:executeGet(filter)
end

function FSDensityMapUtil.convertToDensityMapAngle(angle, maxDensityValue)
	local value = math.floor(angle / math.pi * (maxDensityValue + 1) + 0.5)

	while maxDensityValue < value do
		value = value - (maxDensityValue + 1)
	end

	while value < 0 do
		value = value + maxDensityValue + 1
	end

	return value
end

function FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
	local weedFactor = 1
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local weedWS1Pixels, weedWS2Pixels, weedWS2KilledPixels, totalPixels = nil
		local modifiers = g_currentMission.densityMapModifiers.getWeedFactor
		local modifier = modifiers.modifier
		local filter = modifiers.filter

		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

		if fruitIndex == nil then
			filter:setValueCompareParams(PARAM_EQUAL, 2)

			_, weedWS1Pixels, totalPixels = modifier:executeGet(filter)

			filter:setValueCompareParams(PARAM_EQUAL, 3)

			_, weedWS2Pixels, _ = modifier:executeGet(filter)

			filter:setValueCompareParams(PARAM_EQUAL, 5)

			_, weedWS2KilledPixels, _ = modifier:executeGet(filter)
		else
			local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
			local fruitId = g_currentMission.fruits[fruitIndex].id
			local maskFilter = modifiers.maskFilter

			maskFilter:resetDensityMapAndChannels(fruitId, desc.startStateChannel, desc.numStateChannels)
			maskFilter:setValueCompareParams(PARAM_BETWEEN, desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState + 1)

			_, totalPixels, _ = modifier:executeGet(maskFilter)

			filter:setValueCompareParams(PARAM_EQUAL, 2)

			_, weedWS1Pixels, _ = modifier:executeGet(filter, maskFilter)

			filter:setValueCompareParams(PARAM_EQUAL, 3)

			_, weedWS2Pixels, _ = modifier:executeGet(filter, maskFilter)

			filter:setValueCompareParams(PARAM_EQUAL, 5)

			_, weedWS2KilledPixels, _ = modifier:executeGet(filter, maskFilter)
		end

		if totalPixels > 0 then
			weedFactor = weedFactor - weedWS2Pixels / totalPixels
			weedFactor = weedFactor - (weedWS1Pixels + weedWS2KilledPixels) / totalPixels * 0.5
		end
	end

	return weedFactor
end

function FSDensityMapUtil.getTireTrackColorFromDensityBits(densityBits)
	return 0.138, 0.082, 0.045, 1
end

function FSDensityMapUtil.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, callbackFunc, callbackTarget)
	g_asyncManager:addTask(function ()
		local detailId = g_currentMission.terrainDetailId
		local modifiers = g_currentMission.densityMapModifiers.getFieldStatus
		local modifier = modifiers.modifier
		local filter1 = modifiers.filter1
		local filter2 = modifiers.filter2

		modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

		local _, fieldArea, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		if fieldArea == 0 then
			callbackFunc(callbackTarget, nil)

			return
		end

		local data = {
			fieldArea = fieldArea,
			farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((startWorldX + widthWorldX + heightWorldX) / 3, (startWorldZ + widthWorldZ + heightWorldZ) / 3)
		}
		data.ownerFarmId = g_farmlandManager:getFarmlandOwner(data.farmlandId)

		g_asyncManager:addSubtask(function ()
			local _, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.cultivatorValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			data.cultivatorFactor = numPixels / fieldArea
		end)
		g_asyncManager:addSubtask(function ()
			local _, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.plowValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			data.plowFactor = numPixels / fieldArea
		end)
		g_asyncManager:addSubtask(function ()
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
			filter1:resetDensityMapAndChannels(modifier)
			filter1:setValueCompareParams(PARAM_EQUAL, 0)

			local _, numPixels, _ = modifier:executeGet(filter1, filter2)
			data.needsLimeFactor = numPixels / fieldArea
		end)
		g_asyncManager:addSubtask(function ()
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			filter1:resetDensityMapAndChannels(modifier)
			filter1:setValueCompareParams(PARAM_EQUAL, 0)

			local _, numPixels, _ = modifier:executeGet(filter1, filter2)
			data.needsPlowFactor = numPixels / fieldArea
		end)
		g_asyncManager:addSubtask(function ()
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
			filter1:resetDensityMapAndChannels(modifier)

			data.fertilizerFactor = 0

			for i = 1, g_currentMission.sprayLevelMaxValue do
				filter1:setValueCompareParams(PARAM_EQUAL, i)

				local _, numPixels, _ = modifier:executeGet(filter1, filter2)
				data.fertilizerFactor = data.fertilizerFactor + i * numPixels
			end

			data.fertilizerFactor = data.fertilizerFactor / (g_currentMission.sprayLevelMaxValue * fieldArea)
		end)

		data.fruits = {}
		data.fruitPixels = {}

		for index, entry in pairs(g_currentMission.fruits) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

			if desc.weed == nil then
				g_asyncManager:addSubtask(function ()
					modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
					filter1:resetDensityMapAndChannels(modifier)

					local maxState = 0
					local maxPixels = 0

					for i = 0, 2^desc.numStateChannels - 1 do
						filter1:setValueCompareParams(PARAM_EQUAL, i)

						local _, numPixels, _ = modifier:executeGet(filter1, filter2)

						if maxPixels < numPixels then
							maxState = i
							maxPixels = numPixels
						end
					end

					data.fruits[desc.index] = maxState
					data.fruitPixels[desc.index] = maxPixels
				end)
			end
		end

		local weedType = g_fruitTypeManager:getWeedFruitType()

		if weedType ~= nil then
			g_asyncManager:addSubtask(function ()
				local ids = g_currentMission.fruits[weedType.index]

				modifier:resetDensityMapAndChannels(ids.id, weedType.startStateChannel, weedType.numStateChannels)
				filter1:resetDensityMapAndChannels(modifier)

				data.weedFactor = 0

				for i = 2, 3 do
					filter1:setValueCompareParams(PARAM_EQUAL, i)

					local _, numPixels, _ = modifier:executeGet(filter1, filter2)
					data.weedFactor = data.weedFactor + numPixels
				end

				data.weedFactor = data.weedFactor / fieldArea
			end)
		end

		g_asyncManager:addSubtask(function ()
			callbackFunc(callbackTarget, data)
		end)
	end)
end

function FSDensityMapUtil.getFieldStatus(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end

function FSDensityMapUtil.getStatus(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local detailId = g_currentMission.terrainDetailId
	local modifiers = g_currentMission.densityMapModifiers.getStatus
	local modifier = modifiers.modifier
	local filter1 = modifiers.filter1
	local filter2 = modifiers.filter2

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, MODIFIER_3POINTS)

	local status = {}
	local _, numPixels, totalPixels = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.cultivatorValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	table.insert(status, {
		name = "TotalPixels",
		value = totalPixels
	})
	table.insert(status, {
		value = "",
		name = ""
	})
	table.insert(status, {
		name = "cultivator",
		value = numPixels
	})

	_, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.plowValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	table.insert(status, {
		name = "plow",
		value = numPixels
	})

	_, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.sowingValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	table.insert(status, {
		name = "sowingValue",
		value = numPixels
	})

	_, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.sowingWidthValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	table.insert(status, {
		name = "sowingWidthValue",
		value = numPixels
	})

	_, numPixels, _ = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.grassValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	table.insert(status, {
		name = "grassValue",
		value = numPixels
	})
	modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
	filter1:resetDensityMapAndChannels(modifier)
	table.insert(status, {
		value = "",
		name = ""
	})

	for i = 0, g_currentMission.limeCounterMaxValue do
		filter1:setValueCompareParams(PARAM_EQUAL, i)

		_, numPixels, _ = modifier:executeGet(filter1)

		table.insert(status, {
			name = "lime " .. i,
			value = numPixels
		})
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
	filter1:resetDensityMapAndChannels(modifier)
	table.insert(status, {
		value = "",
		name = ""
	})

	for i = 0, g_currentMission.plowCounterMaxValue do
		filter1:setValueCompareParams(PARAM_EQUAL, i)

		_, numPixels, _ = modifier:executeGet(filter1)

		table.insert(status, {
			name = "plow " .. i,
			value = numPixels
		})
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	filter1:resetDensityMapAndChannels(modifier)
	table.insert(status, {
		value = "",
		name = ""
	})

	for i = 0, 2^g_currentMission.sprayLevelNumChannels - 1 do
		filter1:setValueCompareParams(PARAM_EQUAL, i)

		_, numPixels, _ = modifier:executeGet(filter1)

		table.insert(status, {
			name = "fertilizer " .. i,
			value = numPixels
		})
	end

	modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
	filter1:resetDensityMapAndChannels(modifier)
	table.insert(status, {
		value = "",
		name = ""
	})

	for i = 0, g_currentMission.sprayMaxValue do
		filter1:setValueCompareParams(PARAM_EQUAL, i)

		_, numPixels, _ = modifier:executeGet(filter1)

		table.insert(status, {
			name = "sprayType " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = "",
		newColumn = true
	})

	local foundFruits = {}
	local foundFruitsTotalPixels = {}
	local numFruit = 0

	for index, entry in pairs(g_currentMission.fruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

		if desc.weed == nil then
			modifier:resetDensityMapAndChannels(entry.id, desc.startStateChannel, desc.numStateChannels)
			filter1:resetDensityMapAndChannels(modifier)
			table.insert(status, {
				value = "",
				name = desc.name
			})

			for i = 0, 2^desc.numStateChannels - 1 do
				filter1:setValueCompareParams(PARAM_EQUAL, i)

				_, numPixels, _ = modifier:executeGet(filter1)

				if numPixels > 0 and desc.minHarvestingGrowthState < i and i <= desc.maxHarvestingGrowthState then
					local added = ListUtil.addElementToList(foundFruits, index)

					if added then
						table.insert(foundFruitsTotalPixels, numPixels)
					end
				end

				table.insert(status, {
					name = "state " .. i,
					value = numPixels
				})
			end

			if entry.preparingOutputId ~= 0 then
				modifier:resetDensityMapAndChannels(entry.preparingOutputId, 0, 1)
				filter1:resetDensityMapAndChannels(modifier)
				filter1:setValueCompareParams(PARAM_GREATER, 0)

				_, numPixels, _ = modifier:executeGet(filter1)

				table.insert(status, {
					name = "state preparing",
					value = numPixels
				})
			end

			numFruit = numFruit + 1

			table.insert(status, {
				value = "",
				name = "",
				newColumn = numFruit % 3 == 0
			})
		end
	end

	status[#status].newColumn = true
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local ids = g_currentMission.fruits[weedType.index]

		modifier:resetDensityMapAndChannels(ids.id, weedType.startStateChannel, weedType.numStateChannels)
		filter1:resetDensityMapAndChannels(modifier)

		for i = 0, 2^weedType.numStateChannels - 1 do
			filter1:setValueCompareParams(PARAM_EQUAL, i)

			_, numPixels, totalPixels = modifier:executeGet(filter1)

			table.insert(status, {
				name = "weed " .. i,
				value = numPixels
			})
		end

		for k, fruitIndex in ipairs(foundFruits) do
			local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

			table.insert(status, {
				name = "weedFactor " .. desc.name,
				value = FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
			})

			local fruitTotalPixels = foundFruitsTotalPixels[k]
			local fruitIds = g_currentMission.fruits[fruitIndex]

			filter2:resetDensityMapAndChannels(fruitIds.id, desc.startStateChannel, desc.numStateChannels)
			filter2:setValueCompareParams(PARAM_BETWEEN, desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState)
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			filter1:resetDensityMapAndChannels(modifier)
			filter1:setValueCompareParams(PARAM_GREATER, 0)

			local _, plowPixels, _ = modifier:executeGet(filter1, filter2)

			table.insert(status, {
				name = "plowFactor " .. desc.name,
				value = string.format("%.4f | %d | %d ", plowPixels / fruitTotalPixels, plowPixels, fruitTotalPixels)
			})
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
			filter1:resetDensityMapAndChannels(modifier)
			filter1:setValueCompareParams(PARAM_GREATER, 0)

			local _, limePixels, _ = modifier:executeGet(filter1, filter2)

			table.insert(status, {
				name = "limeFactor " .. desc.name,
				value = string.format("%.4f | %d | %d", limePixels / fruitTotalPixels, limePixels, fruitTotalPixels)
			})
			modifier:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
			filter1:resetDensityMapAndChannels(modifier)
			filter1:setValueCompareParams(PARAM_GREATER, 0)

			local sprayPixelsSum, sprayNumPixels, _ = modifier:executeGet(filter1, filter2)
			local sprayFactor = 0

			if sprayNumPixels > 0 then
				sprayFactor = sprayPixelsSum / (fruitTotalPixels * g_currentMission.sprayLevelMaxValue)
			end

			table.insert(status, {
				name = "sprayFactor " .. desc.name,
				value = string.format("%.4f | %d | %d", sprayFactor, sprayPixelsSum, fruitTotalPixels * g_currentMission.sprayLevelMaxValue)
			})
		end
	end

	return status
end

function FSDensityMapUtil.assert(bool, warning)
	if FSDensityMapUtil.DEBUG_ENABLED then
		assert(bool, warning)
	end
end
