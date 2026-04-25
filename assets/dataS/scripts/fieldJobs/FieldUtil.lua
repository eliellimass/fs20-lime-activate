FieldUtil = {
	onCreate = function (_, id)
		for i = 0, getNumOfChildren(id) - 1 do
			local fieldId = getChildAt(id, i)
			local field = Field:new()

			if field:load(fieldId) then
				g_fieldManager:addField(field)
			else
				field:delete()
			end
		end
	end
}

function FieldUtil.initTerrain(terrainDetailId)
	FieldUtil.sprayModifier = DensityMapModifier:new(terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	FieldUtil.plowModifier = DensityMapModifier:new(terrainDetailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
	FieldUtil.plowValueFilter = DensityMapFilter:new(terrainDetailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)

	FieldUtil.plowValueFilter:setValueCompareParams("greater", 0)

	FieldUtil.limeModifier = DensityMapModifier:new(terrainDetailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
	FieldUtil.limeValueFilter = DensityMapFilter:new(terrainDetailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)

	FieldUtil.limeValueFilter:setValueCompareParams("greater", 0)

	FieldUtil.terrainDetailFilter = DensityMapFilter:new(terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

	FieldUtil.terrainDetailFilter:setValueCompareParams("greater", 0)

	FieldUtil.setFruitModifier = DensityMapModifier:new(g_currentMission.fruits[1].id, 0, 4)
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local ids = g_currentMission.fruits[weedType.index]
		FieldUtil.weedModifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
	end
end

function FieldUtil.getSprayFactor(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	FieldUtil.sprayModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, "pvv")

	local sumPixels, numPixels, _ = FieldUtil.sprayModifier:executeGet(FieldUtil.terrainDetailFilter)

	return sumPixels / (numPixels * g_currentMission.sprayLevelMaxValue)
end

function FieldUtil.getPlowFactor(field)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

	if fruitDesc ~= nil and not fruitDesc.lowSoilDensityRequired or not g_currentMission.missionInfo.plowingRequiredEnabled then
		return 1
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	FieldUtil.plowModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, "pvv")

	local _, numPixels, totalPixels = FieldUtil.plowModifier:executeGet(FieldUtil.terrainDetailFilter, FieldUtil.plowValueFilter)

	return numPixels / totalPixels
end

function FieldUtil.getLimeFactor(field)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

	if fruitDesc ~= nil and not fruitDesc.growthRequiresLime or not g_currentMission.missionInfo.limeRequired then
		return 1
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	FieldUtil.limeModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, "pvv")

	local _, numPixels, totalPixels = FieldUtil.limeModifier:executeGet(FieldUtil.terrainDetailFilter, FieldUtil.limeValueFilter)

	return numPixels / totalPixels
end

function FieldUtil.getWeedFactor(field)
	local dimWidth = getChildAt(field.fieldDimensions, 0)
	local dimStart = getChildAt(dimWidth, 0)
	local dimHeight = getChildAt(dimWidth, 1)
	local x0, _, z0 = getWorldTranslation(dimStart)
	local x1, _, z1 = getWorldTranslation(dimWidth)
	local x2, _, z2 = getWorldTranslation(dimHeight)
	local x = (x0 + x1 + x2) / 3
	local z = (z0 + z1 + z2) / 3

	return FSDensityMapUtil.getWeedFactor(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1)
end

function FieldUtil.updateFieldPartitions(field, partitionTable, partitionTargetArea)
	if partitionTable == nil then
		return
	end

	local targetArea = Utils.getNoNil(partitionTargetArea, 400)
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x0, _, z0 = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local _, _, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
		local widthLength = MathUtil.vector2Length(widthX, widthZ)
		local heightLength = MathUtil.vector2Length(heightX, heightZ)
		local _, area, _ = MathUtil.crossProduct(widthX, 0, widthZ, heightX, 0, heightZ)
		area = math.abs(area)
		local widthNumSteps = math.max(1, math.floor(math.sqrt(widthLength * area / (targetArea * heightLength)) + 0.5))
		local heightNumSteps = math.ceil(area / (widthNumSteps * targetArea))
		local widthStepX = widthX / widthNumSteps
		local widthStepZ = widthZ / widthNumSteps
		local heightStepX = heightX / heightNumSteps
		local heightStepZ = heightZ / heightNumSteps
		local widthStepScale = 1 + 0.1 / (widthLength / widthNumSteps)
		local heightStepScale = 1 + 0.1 / (heightLength / heightNumSteps)

		for iWidth = 0, widthNumSteps - 1 do
			for iHeight = 0, heightNumSteps - 1 do
				local partition = {
					x0 = x0 + widthStepX * iWidth + heightStepX * iHeight,
					z0 = z0 + widthStepZ * iWidth + heightStepZ * iHeight
				}

				if iWidth < widthNumSteps - 1 then
					partition.widthX = widthStepX * widthStepScale
					partition.widthZ = widthStepZ * widthStepScale
				else
					partition.widthX = widthStepX
					partition.widthZ = widthStepZ
				end

				if iHeight < heightNumSteps - 1 then
					partition.heightX = heightStepX * heightStepScale
					partition.heightZ = heightStepZ * heightStepScale
				else
					partition.heightX = heightStepX
					partition.heightZ = heightStepZ
				end

				table.insert(partitionTable, partition)
			end
		end
	end
end

function FieldUtil.getMeasurementPositionOfField(field)
	local dimWidth = getChildAt(field.fieldDimensions, 0)
	local dimStart = getChildAt(dimWidth, 0)
	local dimHeight = getChildAt(dimWidth, 1)
	local x0, _, z0 = getWorldTranslation(dimStart)
	local x1, _, z1 = getWorldTranslation(dimWidth)
	local x2, _, z2 = getWorldTranslation(dimHeight)

	return (x0 + x1 + x2) / 3, (z0 + z1 + z2) / 3
end

function FieldUtil.getCenterOfField(field)
	local posX, posZ = nil
	local sum = 0
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x0, _, z0 = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		posX = x0 + x1 + x2
		posZ = z0 + z1 + z2
		sum = sum + 3
	end

	if sum > 0 then
		posX = posX / sum
		posZ = posZ / sum
	end

	return posX, posZ
end

function FieldUtil.getMaxHarvestState(field, fruitType)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return nil
	end

	local x, z = field:getCenterOfFieldWorldPosition()
	local minState = fruitDesc.minHarvestingGrowthState
	local maxState = fruitDesc.maxHarvestingGrowthState

	if fruitDesc.preparedGrowthState ~= -1 then
		minState = fruitDesc.minPreparingGrowthState
		maxState = fruitDesc.maxPreparingGrowthState
	end

	local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, minState, maxState, 0, 0, 0, false)

	if area > 0 then
		local maxArea = 0
		local maxGrowthState = 0

		for i = minState, maxState do
			local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, i, i, 0, 0, 0, false)

			if maxArea < area then
				maxArea = area
				maxGrowthState = i + 1
			end
		end

		return maxGrowthState
	end

	return nil
end

function FieldUtil.getMaxGrowthState(field, fruitType)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return nil
	end

	local maxGrowthState = 0
	local maxArea = 0
	local x, z = field:getCenterOfFieldWorldPosition()
	local growthStateLimit = fruitDesc.minHarvestingGrowthState - 1

	if fruitDesc.preparedGrowthState ~= -1 then
		growthStateLimit = fruitDesc.maxPreparingGrowthState
	end

	for i = 0, growthStateLimit do
		local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, i, i, 0, 0, 0, false)

		if maxArea < area then
			maxGrowthState = i + 1
			maxArea = area
		end
	end

	return maxGrowthState
end

function FieldUtil.getMaxWeedState(field)
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local maxState = 0
		local maxArea = 0
		local x, z = field:getCenterOfFieldWorldPosition()

		FieldUtil.weedModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, "pvv")

		local filter = DensityMapFilter:new(FieldUtil.weedModifier)

		for i = 1, 5 do
			filter:setValueCompareParams("equal", i)

			local area, _ = FieldUtil.weedModifier:executeGet(filter, FieldUtil.terrainDetailFilter)

			if maxArea < area then
				maxState = i
				maxArea = area
			end
		end

		return maxState
	end

	return 0
end

function FieldUtil.getFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainDetailRequiredValueRanges, terrainDetailProhibitValueRanges, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState, useWindrowed)
	local query = g_currentMission.fieldCropsQuery

	if requiredFruitType ~= FruitType.UNKNOWN then
		local ids = g_currentMission.fruits[requiredFruitType]

		if ids ~= nil and ids.id ~= 0 then
			if useWindrowed then
				return 0, 1
			end

			local desc = g_fruitTypeManager:getFruitTypeByIndex(requiredFruitType)

			query:addRequiredCropType(ids.id, requiredMinGrowthState + 1, requiredMaxGrowthState + 1, desc.startStateChannel, desc.numStateChannels, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		end
	end

	if prohibitedFruitType ~= FruitType.UNKNOWN then
		local ids = g_currentMission.fruits[prohibitedFruitType]

		if ids ~= nil and ids.id ~= 0 then
			local desc = g_fruitTypeManager:getFruitTypeByIndex(prohibitedFruitType)

			query:addProhibitedCropType(ids.id, prohibitedMinGrowthState + 1, prohibitedMaxGrowthState + 1, desc.startStateChannel, desc.numStateChannels, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		end
	end

	for _, valueRange in pairs(terrainDetailRequiredValueRanges) do
		query:addRequiredGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	for _, valueRange in pairs(terrainDetailProhibitValueRanges) do
		query:addProhibitedGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return query:getParallelogram(x, z, widthX, widthZ, heightX, heightZ, true)
end

function FieldUtil.setAreaFruit(dimensions, fruitType, state)
	local numDimensions = getNumOfChildren(dimensions)
	local dmod = FieldUtil.setFruitModifier
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	dmod:resetDensityMapAndChannels(g_currentMission.fruits[fruitType].id, desc.startStateChannel, desc.numStateChannels)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(dimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)

		dmod:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, "ppp")
		dmod:executeSet(state)
	end
end
