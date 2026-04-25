FieldManager = {
	FIELDSTATE_PLOWED = 0,
	FIELDSTATE_CULTIVATED = 1,
	FIELDSTATE_GROWING = 2,
	FIELDSTATE_HARVESTED = 3,
	FIELDEVENT_PLOWED = 1,
	FIELDEVENT_CULTIVATED = 2,
	FIELDEVENT_HARVESTED = 3,
	FIELDEVENT_GROWN = 4,
	FIELDEVENT_WEEDED = 5,
	FIELDEVENT_SPRAYED = 6,
	FIELDEVENT_SOWN = 7,
	FIELDEVENT_WITHERED = 8,
	FIELDEVENT_GROWING = 9
}
local FieldManager_mt = Class(FieldManager, AbstractManager)

function FieldManager:new(customMt)
	local self = AbstractManager:new(customMt or FieldManager_mt)

	return self
end

function FieldManager:initDataStructures()
	self.fields = {}
	self.farmlandIdFieldMapping = {}
	self.fieldStatusParametersToSet = nil
	self.currentFieldPartitionIndex = nil
end

function FieldManager:loadMapData(xmlFile)
	FieldManager:superClass().loadMapData(self)
	g_currentMission:addUpdateable(self)

	self.setFieldPartitionModifier = DensityMapModifier:new(g_currentMission.terrainDetailId)
	self.detailModifier = DensityMapModifier:new(g_currentMission.terrainDetailId)
	local weedType = g_fruitTypeManager:getWeedFruitType()

	if weedType ~= nil then
		local ids = g_currentMission.fruits[weedType.index]
		local weed = weedType.weed
		self.weedModifier = DensityMapModifier:new(ids.id, weedType.startStateChannel, weedType.numStateChannels)
	end

	self.availableFruitTypeIndices = {}
	self.minFieldGrowthStateTime = math.huge

	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if fruitType.useForFieldJob and fruitType.allowsSeeding and fruitType.needsSeeding and g_currentMission.fruits[fruitType.index] ~= nil then
			table.insert(self.availableFruitTypeIndices, fruitType.index)

			self.minFieldGrowthStateTime = math.min(self.minFieldGrowthStateTime, fruitType.growthStateTime)
		end
	end

	self.fruitTypesCount = table.getn(self.availableFruitTypeIndices)
	self.fieldIndexToCheck = table.getn(self.fields)

	g_deferredLoadingManager:addSubtask(function ()
		for i, field in ipairs(self.fields) do
			local posX, posZ = field:getCenterOfFieldWorldPosition()
			local farmland = g_farmlandManager:getFarmlandAtWorldPosition(posX, posZ)

			if farmland ~= nil then
				field:setFarmland(farmland)

				if self.farmlandIdFieldMapping[farmland.id] == nil then
					self.farmlandIdFieldMapping[farmland.id] = {}
				end

				table.insert(self.farmlandIdFieldMapping[farmland.id], field)
			else
				g_logManager:error("Failed to find farmland in center of field '%s'", i)
			end
		end
	end)

	if not g_currentMission.missionInfo.isValid and g_server ~= nil then
		g_deferredLoadingManager:addSubtask(function ()
			local index = 1

			for _, field in pairs(self.fields) do
				if field:getIsAIActive() and field.fieldMissionAllowed and not field.farmland.isOwned then
					local fruitIndex = self.availableFruitTypeIndices[index]

					if field.fieldGrassMission then
						fruitIndex = FruitType.GRASS
					end

					local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
					local fieldState = FieldManager.FIELDSTATE_GROWING
					local growthState = nil

					if fruitDesc.minHarvestingGrowthState == 0 and fruitDesc.maxHarvestingGrowthState == 0 and fruitDesc.cutState == 0 then
						growthState = 2
					elseif fruitDesc.minPreparingGrowthState ~= -1 then
						growthState = math.random(1, fruitDesc.maxPreparingGrowthState + 1)
					else
						growthState = math.random(1, fruitDesc.maxHarvestingGrowthState + 1)
					end

					if fruitIndex == FruitType.GRASS and growthState == 1 then
						growthState = 2
					end

					local weedValue = 0

					if fruitDesc.plantsWeed then
						weedValue = 1
					end

					local plowState = 0

					if not g_currentMission.missionInfo.plowingRequiredEnabled then
						plowState = g_currentMission.plowCounterMaxValue
					else
						plowState = math.random(0, g_currentMission.plowCounterMaxValue)
					end

					local sprayLevel = math.random(0, g_currentMission.sprayLevelMaxValue)
					local limeState = math.random(0, g_currentMission.limeCounterMaxValue)

					for i = 1, table.getn(field.maxFieldStatusPartitions) do
						self:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitIndex, fieldState, growthState, sprayLevel, false, plowState, weedValue, limeState)
					end

					index = index + 1

					if self.fruitTypesCount < index then
						index = 1
					end
				end
			end
		end)
	elseif g_server ~= nil then
		for _, field in pairs(self.fields) do
			g_deferredLoadingManager:addSubtask(function ()
				self:findFieldFruit(field)
			end)
		end
	end

	g_deferredLoadingManager:addSubtask(function ()
		self:findFieldSizes()
	end)
	g_deferredLoadingManager:addSubtask(function ()
		g_farmlandManager:addStateChangeListener(self)

		if g_currentMission:getIsServer() and g_addCheatCommands then
			addConsoleCommand("gsSetFieldFruit", "Sets a given fruit to field", "consoleCommandSetFieldFruit", self)
			addConsoleCommand("gsSetFieldFruitAll", "Sets a given fruit to all fields", "consoleCommandSetFieldFruitAll", self)
			addConsoleCommand("gsSetFieldGround", "Sets a given fruit to field", "consoleCommandSetFieldGround", self)
			addConsoleCommand("gsSetFieldGroundAll", "Sets a given fruit to allfield", "consoleCommandSetFieldGroundAll", self)
		end
	end)
	g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.farmPropertyChanged, self)
end

function FieldManager:unloadMapData()
	g_currentMission:removeUpdateable(self)
	g_farmlandManager:removeStateChangeListener(self)

	for _, field in pairs(self.fields) do
		field:delete()
	end

	self.fields = {}
	self.setFieldPartitionModifier = nil
	self.detailModifier = nil
	self.weedModifier = nil

	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsSetFieldFruit")
	removeConsoleCommand("gsSetFieldFruitAll")
	removeConsoleCommand("gsSetFieldGround")
	removeConsoleCommand("gsSetFieldGroundAll")
	FieldManager:superClass().unloadMapData(self)
end

function FieldManager:delete()
end

function FieldManager:update(dt)
	if g_server == nil then
		return
	end

	if self.fieldStatusParametersToSet ~= nil then
		if self.currentFieldPartitionIndex == nil then
			self.currentFieldPartitionIndex = 1
		else
			self.currentFieldPartitionIndex = self.currentFieldPartitionIndex + 1
		end

		if table.getn(self.fieldStatusParametersToSet[2]) < self.currentFieldPartitionIndex then
			self.currentFieldPartitionIndex = nil
			self.fieldStatusParametersToSet = nil
		end

		if self.fieldStatusParametersToSet ~= nil then
			local args = self.fieldStatusParametersToSet
			args[3] = self.currentFieldPartitionIndex

			self:setFieldPartitionStatus(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11])
		end
	else
		local field = self.fields[self.fieldIndexToCheck]

		if field ~= nil and field:getIsAIActive() and field.fieldMissionAllowed and field.currentMission == nil and field.fruitType ~= FruitType.GRASS then
			local multiplier = g_currentMission:getFoliageGrowthStateTimeMultiplier()
			local x, z = field:getCenterOfFieldWorldPosition()

			if field.fruitType ~= nil then
				local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

				if fruitDesc == nil then
					field.fruitType = nil

					return
				end

				local fertilizerFruit = fruitDesc.minHarvestingGrowthState == 0 and fruitDesc.maxHarvestingGrowthState == 0 and fruitDesc.cutState == 0
				local maxGrowthState = FieldUtil.getMaxGrowthState(field, field.fruitType)

				if field.maxKnownGrowthState == nil then
					field.maxKnownGrowthState = maxGrowthState
				elseif field.maxKnownGrowthState ~= maxGrowthState then
					field.maxKnownGrowthState = maxGrowthState

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_GROWING, true)
				end

				if fertilizerFruit then
					local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, field.fruitType, 2, 2, 0, 0, 0, false)

					if area > 0.5 * totalArea then
						self.fieldStatusParametersToSet = {
							field,
							field.setFieldStatusPartitions,
							1,
							nil,
							FieldManager.FIELDSTATE_CULTIVATED,
							0,
							g_currentMission.sprayLevelMaxValue,
							true
						}

						g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
					end
				end

				if not fertilizerFruit then
					local forceWithering = g_currentMission.missionInfo.isPlantWitheringEnabled and math.random() > 0.7

					if forceWithering then
						local witheredState = fruitDesc.witheringNumGrowthStates - 1

						if fruitDesc.witheringNumGrowthStates == fruitDesc.numGrowthStates then
							witheredState = nil
						end

						if witheredState ~= nil then
							local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, field.fruitType, witheredState, witheredState, 0, 0, 0, false)

							if area > 0.5 * totalArea then
								g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_WITHERED)

								if field.lastCheckedTime == nil then
									field.lastCheckedTime = g_currentMission.time
								elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier then
									local sprayFactor = FieldUtil.getSprayFactor(field) * g_currentMission.sprayLevelMaxValue
									self.fieldStatusParametersToSet = {
										field,
										field.setFieldStatusPartitions,
										1,
										nil,
										FieldManager.FIELDSTATE_CULTIVATED,
										0,
										sprayFactor,
										false
									}
									field.lastCheckedTime = nil

									g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
								end
							end
						end
					else
						local maxState = fruitDesc.maxHarvestingGrowthState

						if fruitDesc.maxPreparingGrowthState > -1 then
							maxState = fruitDesc.maxPreparingGrowthState
						end

						local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, field.fruitType, maxState, maxState, 0, 0, 0, false)

						if area > 0.5 * totalArea then
							if field.lastCheckedTime == nil then
								field.lastCheckedTime = g_currentMission.time
							elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier then
								self.fieldStatusParametersToSet = {
									field,
									field.setFieldStatusPartitions,
									1,
									field.fruitType,
									FieldManager.FIELDSTATE_HARVESTED,
									fruitDesc.cutState,
									0,
									false,
									nil,
									0
								}
								field.lastCheckedTime = nil

								g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_HARVESTED)
							end
						end
					end

					if fruitDesc.minHarvestingGrowthState <= maxGrowthState or fruitDesc.preparedGrowthState ~= -1 and maxGrowthState >= fruitDesc.minPreparingGrowthState + 1 and maxGrowthState <= fruitDesc.maxPreparingGrowthState then
						g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_GROWN)
					end

					local maxWeedState = FieldUtil.getMaxWeedState(field)

					if field.maxKnownWeedState == nil then
						field.maxKnownWeedState = maxWeedState
					elseif field.maxKnownWeedState ~= maxWeedState then
						field.maxKnownWeedState = maxWeedState

						g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_GROWING, true)
					end

					if maxWeedState == 2 and (maxGrowthState == 1 or maxGrowthState == 2) then
						if field.lastCheckedTime == nil then
							field.lastCheckedTime = g_currentMission.time
						elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier * 0.5 then
							local sprayFactor = FieldUtil.getSprayFactor(field) * g_currentMission.sprayLevelMaxValue
							self.fieldStatusParametersToSet = {
								field,
								field.setFieldStatusPartitions,
								1,
								field.fruitType,
								FieldManager.FIELDSTATE_GROWING,
								maxGrowthState,
								sprayFactor,
								false,
								nil,
								0
							}
							field.lastCheckedTime = nil

							g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_WEEDED)
						end
					elseif maxWeedState >= 2 and maxWeedState <= 3 and maxGrowthState > 2 then
						if field.lastCheckedTime == nil then
							field.lastCheckedTime = g_currentMission.time
						elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier then
							local sprayFactor = FieldUtil.getSprayFactor(field) * g_currentMission.sprayLevelMaxValue
							local weedState = FieldUtil.getMaxWeedState(field)
							local weedType = g_fruitTypeManager:getWeedFruitType()
							local newWeedState = nil

							for _, data in ipairs(weedType.weed.herbicideReplaces) do
								if data.src == weedState then
									newWeedState = data.target

									break
								end
							end

							self.fieldStatusParametersToSet = {
								field,
								field.setFieldStatusPartitions,
								1,
								field.fruitType,
								FieldManager.FIELDSTATE_GROWING,
								maxGrowthState,
								sprayFactor,
								false,
								[10] = newWeedState
							}
							field.lastCheckedTime = nil

							g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_SPRAYED)
						end
					end

					local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, field.fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)

					if area > 0.5 * totalArea then
						field.stateIsKnown = false

						if field.lastCheckedTime == nil then
							field.lastCheckedTime = g_currentMission.time
						elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier then
							local sprayFactor = FieldUtil.getSprayFactor(field) * g_currentMission.sprayLevelMaxValue
							self.fieldStatusParametersToSet = {
								field,
								field.setFieldStatusPartitions,
								1,
								nil,
								FieldManager.FIELDSTATE_CULTIVATED,
								0,
								sprayFactor,
								false
							}
							field.lastCheckedTime = nil

							g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
						end
					end
				end
			elseif field.lastCheckedTime == nil then
				field.lastCheckedTime = g_currentMission.time
			elseif g_currentMission.time > field.lastCheckedTime + self.minFieldGrowthStateTime * multiplier then
				local fruitIndex = self:getFruitIndexForField(field)

				if fruitIndex ~= nil then
					local sprayFactor = FieldUtil.getSprayFactor(field) * g_currentMission.sprayLevelMaxValue
					local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
					self.fieldStatusParametersToSet = {
						field,
						field.setFieldStatusPartitions,
						1,
						fruitIndex,
						FieldManager.FIELDSTATE_GROWING,
						1,
						sprayFactor,
						false,
						[10] = fruitDesc.plantsWeed and 1 or 0
					}

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_SOWN)
				end

				field.lastCheckedTime = nil
			end
		end

		self.fieldIndexToCheck = self.fieldIndexToCheck - 1

		if self.fieldIndexToCheck == 0 then
			self.fieldIndexToCheck = table.getn(self.fields)
		end
	end
end

function FieldManager:updateFieldOwnership()
	for _, field in ipairs(self.fields) do
		field:updateOwnership()
	end
end

function FieldManager:farmPropertyChanged(farmId)
	for _, field in ipairs(self.fields) do
		if g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId then
			field:updateHotspotColor(farmId)
		end
	end
end

function FieldManager:getFruitIndexForField(field)
	if field.fieldGrassMission then
		return FruitType.GRASS
	end

	return math.random(1, table.getn(self.availableFruitTypeIndices))
end

function FieldManager:addField(field)
	table.insert(self.fields, field)
	field:setFieldId(#self.fields)
	field:addMapHotspot()
end

function FieldManager:getFieldByIndex(index)
	if index ~= nil then
		return self.fields[index]
	end

	return nil
end

function FieldManager:getFields()
	return self.fields
end

function FieldManager:setFieldPartitionStatus(field, fieldPartitions, fieldPartitionIndex, fruitIndex, fieldState, growthState, sprayState, setSpray, plowState, weedState, limeState)
	field.lastCheckedTime = nil
	field.fruitType = fruitIndex
	field.stateIsKnown = false
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	local state = growthState

	if state == nil and fruitDesc ~= nil then
		state = math.random(1, fruitDesc.maxHarvestingGrowthState + 1)

		if fruitDesc.minPreparingGrowthState ~= -1 then
			state = math.random(1, fruitDesc.maxPreparingGrowthState + 1)
		end
	end

	local partition = fieldPartitions[fieldPartitionIndex]
	local dmod = self.setFieldPartitionModifier

	if partition ~= nil then
		local x = partition.x0
		local z = partition.z0
		local widthX = partition.widthX
		local widthZ = partition.widthZ
		local heightX = partition.heightX
		local heightZ = partition.heightZ
		local x0 = x
		local z0 = z
		local x1 = x + widthX
		local z1 = z + widthZ
		local x2 = x + heightX
		local z2 = z + heightZ
		local id = g_currentMission.terrainDetailHeightId
		local firstChannel = g_currentMission.terrainDetailHeightTypeFirstChannel
		local numChannels = g_currentMission.terrainDetailHeightTypeNumChannels

		dmod:resetDensityMapAndChannels(id, getDensityMapHeightFirstChannel(id), getDensityMapHeightNumChannels(id))
		dmod:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, "pvv")
		dmod:executeSet(0)
		dmod:resetDensityMapAndChannels(id, firstChannel, numChannels)
		dmod:executeSet(0)

		if fieldState == FieldManager.FIELDSTATE_CULTIVATED then
			FSDensityMapUtil.updateCultivatorArea(x0, z0, x1, z1, x2, z2, false, false, field.fieldAngle, nil)
			FSDensityMapUtil.eraseTireTrack(x0, z0, x1, z1, x2, z2)

			field.fruitType = nil
		elseif fieldState == FieldManager.FIELDSTATE_PLOWED then
			FSDensityMapUtil.updatePlowArea(x0, z0, x1, z1, x2, z2, false, true, field.fieldAngle)
			FSDensityMapUtil.eraseTireTrack(x0, z0, x1, z1, x2, z2)

			field.fruitType = nil
		elseif fieldState == FieldManager.FIELDSTATE_GROWING then
			local groundTypeValue = nil

			if fruitDesc.useSeedingWidth then
				groundTypeValue = g_currentMission.sowingWidthValue
			else
				groundTypeValue = g_currentMission.sowingValue
			end

			if fruitDesc.groundTypeChangeGrowthState >= 0 and fruitDesc.groundTypeChangeGrowthState < state then
				groundTypeValue = g_currentMission:getFruitTypeGroundTypeValue(fruitDesc.groundTypeChanged)
			end

			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
			dmod:executeSet(field.fieldAngle)
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			dmod:executeSet(groundTypeValue)
			dmod:resetDensityMapAndChannels(g_currentMission.fruits[fruitDesc.index].id, fruitDesc.startStateChannel, fruitDesc.numStateChannels)
			dmod:executeSet(state)

			if g_currentMission.fruits[fruitDesc.index].preparingOutputId ~= 0 then
				dmod:resetDensityMapAndChannels(g_currentMission.fruits[fruitDesc.index].preparingOutputId, 0, 1)
				dmod:executeSet(0)
			end
		elseif fieldState == FieldManager.FIELDSTATE_HARVESTED then
			local state = fruitDesc.cutState + 1
			local groundTypeValue = nil

			if fruitDesc.useSeedingWidth then
				groundTypeValue = g_currentMission.sowingWidthValue
			else
				groundTypeValue = g_currentMission.sowingValue
			end

			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
			dmod:executeSet(field.fieldAngle)
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			dmod:executeSet(groundTypeValue)
			dmod:resetDensityMapAndChannels(g_currentMission.fruits[fruitDesc.index].id, fruitDesc.startStateChannel, fruitDesc.numStateChannels)
			dmod:executeSet(state)

			if fruitDesc.preparingOutputName ~= nil then
				dmod:resetDensityMapAndChannels(g_currentMission.fruits[fruitDesc.index].preparingOutputId, 0, 1)
				dmod:executeSet(1)
			end
		end

		local filter = DensityMapFilter:new(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)

		filter:setValueCompareParams("greater", 0)

		if sprayState ~= nil then
			if g_currentMission.sprayLevelMaxValue < sprayState then
				sprayState = g_currentMission.sprayLevelMaxValue
			end

			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
			dmod:executeSet(sprayState, filter)
		end

		if setSpray == true and sprayState ~= nil and sprayState > 0 then
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			dmod:executeSet(1, filter)
		else
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			dmod:executeSet(0, filter)
		end

		if plowState ~= nil then
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			dmod:executeSet(plowState, filter)
		end

		if weedState ~= nil then
			local weedType = g_fruitTypeManager:getWeedFruitType()

			if weedType ~= nil then
				local ids = g_currentMission.fruits[weedType.index]

				dmod:resetDensityMapAndChannels(ids.id, weedType.startStateChannel, weedType.numStateChannels)
				dmod:executeSet(weedState, filter)
			end
		end

		if limeState ~= nil then
			dmod:resetDensityMapAndChannels(g_currentMission.terrainDetailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
			dmod:executeSet(limeState, filter)
		end
	end
end

function FieldManager:onFarmlandStateChanged(farmlandId, farmId)
	local fields = self.farmlandIdFieldMapping[farmlandId]

	if fields ~= nil then
		for _, field in ipairs(fields) do
			if farmId == FarmlandManager.NO_OWNER_FARM_ID then
				field:activate()
				self:findFieldFruit(field)
			else
				field:deactivate()
			end
		end
	end
end

function FieldManager:findFieldFruit(field)
	if field.fieldMissionAllowed then
		local x, z = field:getCenterOfFieldWorldPosition()

		local function testFruit(fruitType)
			local minState = 0
			local maxState = 10
			local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, minState, maxState, 0, 0, 0, false)

			return area > 0.9 * totalArea
		end

		for _, fruitType in pairs(self.availableFruitTypeIndices) do
			if testFruit(fruitType) then
				field.fruitType = fruitType

				break
			end
		end

		if testFruit(FruitType.GRASS) then
			field.fruitType = FruitType.GRASS
		end
	end
end

function FieldManager:findFieldSizes()
	local bitMapSize = 4096
	local terrainSize = getTerrainSize(g_currentMission.terrainRootNode)

	local function convertWorldToAccessPosition(x, z)
		return math.floor(bitMapSize * (x + terrainSize * 0.5) / terrainSize), math.floor(bitMapSize * (z + terrainSize * 0.5) / terrainSize)
	end

	local function pixelToHa(area)
		local pixelToSqm = terrainSize / bitMapSize

		return area * pixelToSqm * pixelToSqm / 10000
	end

	for _, field in pairs(self.fields) do
		local sumPixel = 0
		local bitVector = createBitVectorMap("field")

		loadBitVectorMapNew(bitVector, bitMapSize, bitMapSize, 1, true)

		for i = 0, getNumOfChildren(field.fieldDimensions) - 1 do
			local dimWidth = getChildAt(field.fieldDimensions, i)
			local dimStart = getChildAt(dimWidth, 0)
			local dimHeight = getChildAt(dimWidth, 1)
			local x0, _, z0 = getWorldTranslation(dimStart)
			local widthX, _, widthZ = getWorldTranslation(dimWidth)
			local heightX, _, heightZ = getWorldTranslation(dimHeight)
			local x, z = convertWorldToAccessPosition(x0, z0)
			local widthX, widthZ = convertWorldToAccessPosition(widthX, widthZ)
			local heightX, heightZ = convertWorldToAccessPosition(heightX, heightZ)
			sumPixel = sumPixel + setBitVectorMapParallelogram(bitVector, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, 1, 0)
		end

		field.fieldArea = pixelToHa(sumPixel)

		delete(bitVector)
	end
end

function FieldManager:setFieldFruit(field, fruitType, state, groundLayer, fertilizerState, plowingState, weedState, limeState, setSpray)
	if field == nil or field.fieldDimensions == nil or fruitType == nil then
		return false
	end

	local weedType = g_fruitTypeManager:getWeedFruitType()
	local detailId = g_currentMission.terrainDetailId
	field.fruitType = fruitType.index

	if g_missionManager.fieldToMission[field.fieldId] ~= nil then
		g_missionManager:deleteMission(g_missionManager.fieldToMission[field.fieldId])
	end

	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local heightTypes = g_densityMapHeightManager:getFillTypeToDensityMapHeightTypes()

		for fillTypeIndex, _ in pairs(heightTypes) do
			DensityMapHeightUtil.removeFromGroundByArea(x, z, x1, z1, x2, z2, fillTypeIndex)
		end

		state = MathUtil.clamp(state, 0, 2^fruitType.numStateChannels - 1)
		local dmod = DensityMapModifier:new(g_currentMission.fruits[fruitType.index].id, fruitType.startStateChannel, fruitType.numStateChannels)

		dmod:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, "ppp")
		dmod:executeSet(state)

		local groundTypeValue = g_currentMission.sowingValue

		if fruitType ~= nil then
			if fruitType.useSeedingWidth then
				groundTypeValue = g_currentMission.sowingWidthValue
			end

			if fruitType.groundTypeChangeGrowthState >= 0 and fruitType.groundTypeChangeGrowthState < state then
				groundTypeValue = g_currentMission:getFruitTypeGroundTypeValue(fruitType.groundTypeChanged)
			end
		end

		dmod:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		dmod:executeSet(groundTypeValue)
		dmod:resetDensityMapAndChannels(detailId, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
		dmod:executeSet(0)
		dmod:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
		dmod:executeSet(tonumber(groundLayer) or 0)
		dmod:resetDensityMapAndChannels(detailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
		dmod:executeSet(fertilizerState)

		if setSpray then
			dmod:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			dmod:executeSet(1, filter)
		else
			dmod:resetDensityMapAndChannels(detailId, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			dmod:executeSet(0, filter)
		end

		dmod:resetDensityMapAndChannels(detailId, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
		dmod:executeSet(plowingState)
		dmod:resetDensityMapAndChannels(detailId, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
		dmod:executeSet(limeState)

		if weedType ~= nil then
			local ids = g_currentMission.fruits[weedType.index]

			dmod:resetDensityMapAndChannels(ids.id, weedType.startStateChannel, weedType.numStateChannels)
			dmod:executeSet(weedState)
		end
	end
end

function FieldManager:consoleCommandSetFieldFruit(fieldIndex, fruitName, state, groundLayer, fertilizerState, plowingState, weedState, limeState, setSpray, buyField)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		fieldIndex = tonumber(fieldIndex)
		state = tonumber(state) or 5
		groundLayer = Utils.getNoNil(tonumber(groundLayer), 0)
		fertilizerState = math.min(Utils.getNoNil(tonumber(fertilizerState), 0), g_currentMission.sprayLevelMaxValue)
		plowingState = Utils.getNoNil(tonumber(plowingState), 0)
		weedState = Utils.getNoNil(tonumber(weedState), 0)
		limeState = Utils.getNoNil(tonumber(limeState), 0)
		buyField = tostring(buyField):lower() == "true"
		local usage = "Use gsSetFieldFruit fieldId fruitName [growthState] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [setSpray] [buyField]"
		local field = self:getFieldByIndex(fieldIndex)

		if field == nil then
			return "Invalid Field-Index. " .. usage
		end

		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitType == nil then
			return "Invalid fruitType. " .. usage
		end

		if field.fieldDimensions ~= nil then
			if buyField and field.isActive then
				g_client:getServerConnection():sendEvent(FarmlandStateEvent:new(field.farmland.id, 1, 0))
				print("Info: Bought field farmland")
			end

			self:setFieldFruit(field, fruitType, state, groundLayer, fertilizerState, plowingState, weedState, limeState, setSpray)

			return "Updated field"
		end

		return "Field not found"
	else
		return "Command not allowed"
	end
end

function FieldManager:consoleCommandSetFieldFruitAll(fruitName, state, groundLayer, fertilizerState, plowingState, weedState, limeState, setSpray, buyField)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		state = tonumber(state) or 5
		groundLayer = Utils.getNoNil(tonumber(groundLayer), 0)
		fertilizerState = math.min(Utils.getNoNil(tonumber(fertilizerState), 0), g_currentMission.sprayLevelMaxValue)
		plowingState = Utils.getNoNil(tonumber(plowingState), 0)
		weedState = Utils.getNoNil(tonumber(weedState), 0)
		limeState = Utils.getNoNil(tonumber(limeState), 0)
		buyField = tostring(buyField):lower() == "true"
		local usage = "Use gsSetFieldFruitAll fruitName [growthState] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [setSpray] [buyField]"
		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitType == nil then
			return "Invalid fruitType. " .. usage
		end

		for _, field in ipairs(self.fields) do
			if field.fieldDimensions ~= nil then
				if buyFields and field.isActive then
					g_client:getServerConnection():sendEvent(FarmlandStateEvent:new(field.farmland.id, 1, 0))
					print("Info: Bought field farmland")
				end

				self:setFieldFruit(field, fruitType, state, groundLayer, fertilizerState, plowingState, weedState, limeState, setSpray)
			end
		end

		return "Updated field"
	else
		return "Command not allowed"
	end
end

function FieldManager:consoleCommandSetFieldGround(fieldIndex, groundName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, buyField, removeFoliage)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local states = {
			cultivator = FruitTypeManager.GROUND_TYPE_CULTIVATOR,
			plow = FruitTypeManager.GROUND_TYPE_PLOW,
			sowing = FruitTypeManager.GROUND_TYPE_SOWING,
			sowing_width = FruitTypeManager.GROUND_TYPE_SOWING_WIDTH
		}
		local usage = "Use gsSetFieldGround fieldIndex groundName[cultivator, plow, sowing, sowing_width] [angle] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [buyField] [removeFoliage]"
		local groundState = states[tostring(groundName)]

		if groundState == nil then
			for name, type in pairs(states) do
				if StringUtil.startsWith(name, tostring(groundName)) then
					groundState = type
				end
			end

			if groundState == nil then
				return "Invalid Groundname. " .. usage
			end
		end

		buyField = tostring(buyField):lower() == "true"
		fieldIndex = tonumber(fieldIndex)
		fertilizerState = tonumber(fertilizerState) or 0
		plowingState = tonumber(plowingState) or 0
		angle = tonumber(angle) or 0
		weedState = tonumber(weedState) or 0
		limeState = tonumber(limeState) or 0
		removeFoliage = tostring(removeFoliage):lower() ~= "false"

		self:setFielGround(fieldIndex, groundState, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, buyField, removeFoliage)

		return "Updated field"
	end

	return "Fields are not activated"
end

function FieldManager:consoleCommandSetFieldGroundAll(groundName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, buyFields, removeFoliage)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local states = {
			cultivator = FruitTypeManager.GROUND_TYPE_CULTIVATOR,
			plow = FruitTypeManager.GROUND_TYPE_PLOW,
			sowing = FruitTypeManager.GROUND_TYPE_SOWING,
			sowing_width = FruitTypeManager.GROUND_TYPE_SOWING_WIDTH
		}
		local usage = "Use gsSetFieldGroundAll groundName[cultivator, plow, sowing, sowing_width] [angle] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [buyFields] [removeFoliage]"
		local groundState = states[tostring(groundName)]

		if groundState == nil then
			for name, type in pairs(states) do
				if StringUtil.startsWith(name, tostring(groundName)) then
					groundState = type
				end
			end

			if groundState == nil then
				return "Invalid Groundname. " .. usage
			end
		end

		buyFields = tostring(buyFields):lower() == "true"
		fertilizerState = tonumber(fertilizerState) or 0
		plowingState = tonumber(plowingState) or 0
		angle = tonumber(angle) or 0
		weedState = tonumber(weedState) or 0
		limeState = tonumber(limeState) or 0
		removeFoliage = tostring(removeFoliage):lower() ~= "false"

		for i, _ in ipairs(self.fields) do
			self:setFielGround(i, groundState, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, buyFields, removeFoliage)
		end

		return "Updated fields"
	end

	return "Fields are not activated"
end

function FieldManager:setFielGround(fieldIndex, groundState, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, buyField, removeFoliage)
	local field = self:getFieldByIndex(fieldIndex)

	if field ~= nil and field.fieldDimensions ~= nil then
		if buyField and field.isActive then
			g_client:getServerConnection():sendEvent(FarmlandStateEvent:new(field.farmland.id, 1, 0))
		end

		field.fruitType = nil
		local weedType = g_fruitTypeManager:getWeedFruitType()
		local groundTypeValue = g_currentMission:getFruitTypeGroundTypeValue(groundState)
		local dmodDetail = self.detailModifier
		local numDimensions = getNumOfChildren(field.fieldDimensions)

		for i = 1, numDimensions do
			local dimWidth = getChildAt(field.fieldDimensions, i - 1)
			local dimStart = getChildAt(dimWidth, 0)
			local dimHeight = getChildAt(dimWidth, 1)
			local x, _, z = getWorldTranslation(dimStart)
			local x1, _, z1 = getWorldTranslation(dimWidth)
			local x2, _, z2 = getWorldTranslation(dimHeight)

			if removeFoliage then
				FSDensityMapUtil.updateDestroyCommonArea(x, z, x1, z1, x2, z2, true)
				FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2, nil)
			end

			dmodDetail:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, "ppp")
			dmodDetail:setDensityMapChannels(g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
			dmodDetail:executeSet(groundTypeValue)
			dmodDetail:setDensityMapChannels(g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels)
			dmodDetail:executeSet(angle)
			dmodDetail:setDensityMapChannels(g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			dmodDetail:executeSet(tonumber(groundLayer) or 0)
			dmodDetail:setDensityMapChannels(g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
			dmodDetail:executeSet(fertilizerState)
			dmodDetail:setDensityMapChannels(g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels)
			dmodDetail:executeSet(plowingState)
			dmodDetail:setDensityMapChannels(g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels)
			dmodDetail:executeSet(limeState)

			if weedType ~= nil then
				self.weedModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, "ppp")
				self.weedModifier:executeSet(weedState)
			end
		end

		return "Updated field"
	end

	return "Missing field dimensions"
end

g_fieldManager = FieldManager:new()
