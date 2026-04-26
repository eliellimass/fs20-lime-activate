MapOverlayGenerator = {}
local MapOverlayGenerator_mt = Class(MapOverlayGenerator)
MapOverlayGenerator.OVERLAY_TYPE = {
	SOIL = 3,
	CROPS = 1,
	GROWTH = 2,
	FARMLANDS = 4
}
MapOverlayGenerator.OVERLAY_RESOLUTION = {
	FOLIAGE_STATE = {
		512,
		512
	},
	FARMLANDS = {
		512,
		512
	}
}

local function NO_CALLBACK()
end

function MapOverlayGenerator:new(l10n, fruitTypeManager, fillTypeManager, farmlandManager, farmManager)
	local self = setmetatable({}, MapOverlayGenerator_mt)
	self.l10n = l10n
	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.farmlandManager = farmlandManager
	self.farmManager = farmManager
	self.missionFruitTypes = {}
	self.isColorBlindMode = nil
	self.foliageStateOverlay = createDensityMapVisualizationOverlay("foliageState", unpack(self:adjustedOverlayResolution(MapOverlayGenerator.OVERLAY_RESOLUTION.FOLIAGE_STATE)))
	self.farmlandStateOverlay = createDensityMapVisualizationOverlay("farmlandState", unpack(self:adjustedOverlayResolution(MapOverlayGenerator.OVERLAY_RESOLUTION.FARMLANDS, true)))
	self.typeBuilderFunctionMap = {
		[MapOverlayGenerator.OVERLAY_TYPE.CROPS] = self.buildFruitTypeMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = self.buildGrowthStateMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.SOIL] = self.buildSoilStateMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = self.buildFarmlandsMapOverlay
	}
	self.overlayHandles = {
		[MapOverlayGenerator.OVERLAY_TYPE.CROPS] = self.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = self.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.SOIL] = self.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = self.farmlandStateOverlay
	}
	self.currentOverlayHandle = nil
	self.overlayFinishedCallback = NO_CALLBACK
	self.overlayTypeCheckHash = {}

	for k, v in pairs(MapOverlayGenerator.OVERLAY_TYPE) do
		self.overlayTypeCheckHash[v] = k
	end

	if GS_IS_CONSOLE_VERSION or g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
		setDensityMapVisualizationOverlayUpdateTimeLimit(self.foliageStateOverlay, 10)
		setDensityMapVisualizationOverlayUpdateTimeLimit(self.farmlandStateOverlay, 10)
	else
		setDensityMapVisualizationOverlayUpdateTimeLimit(self.foliageStateOverlay, 20)
		setDensityMapVisualizationOverlayUpdateTimeLimit(self.farmlandStateOverlay, 20)
	end

	return self
end

function MapOverlayGenerator:delete()
	self:reset()
	delete(self.foliageStateOverlay)
	delete(self.farmlandStateOverlay)
end

function MapOverlayGenerator:adjustedOverlayResolution(default, limitToTwo)
	local profileClass = Utils.getPerformanceClassId()

	if GS_IS_CONSOLE_VERSION or profileClass == GS_PROFILE_LOW then
		return default
	elseif GS_PROFILE_VERY_HIGH <= profileClass and not limitToTwo and (not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission:getIsServer()) then
		return {
			default[1] * 4,
			default[2] * 4
		}
	else
		return {
			default[1] * 2,
			default[2] * 2
		}
	end
end

function MapOverlayGenerator:setMissionFruitTypes(missionFruitTypes)
	self.missionFruitTypes = {}

	for i, missionFruitType in ipairs(missionFruitTypes) do
		local fruitType = self.fruitTypeManager:getFruitTypeByIndex(missionFruitType.fruitTypeIndex)

		table.insert(self.missionFruitTypes, {
			foliageId = missionFruitType.id,
			fruitTypeIndex = missionFruitType.fruitTypeIndex,
			shownOnMap = fruitType.shownOnMap,
			defaultColor = fruitType.defaultMapColor,
			colorBlindColor = fruitType.colorBlindMapColor
		})
	end

	self.displayCropTypes = self:getDisplayCropTypes()
	self.displayGrowthStates = self:getDisplayGrowthStates()
	self.displaySoilStates = self:getDisplaySoilStates()
end

function MapOverlayGenerator:setColorBlindMode(isColorBlindMode)
	self.isColorBlindMode = isColorBlindMode
end

function MapOverlayGenerator:buildFruitTypeMapOverlay(fruitTypeFilter)
	for _, displayCropType in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[displayCropType.fruitTypeIndex] then
			local foliageId = displayCropType.foliageId

			if foliageId ~= nil and foliageId ~= 0 and displayCropType.fruitTypeIndex ~= FruitType.WEED then
				setDensityMapVisualizationOverlayTypeColor(self.foliageStateOverlay, foliageId, unpack(displayCropType.colors[self.isColorBlindMode]))
			end
		end
	end
end

function MapOverlayGenerator:buildGrowthStateMapOverlay(growthStateFilter, fruitTypeFilter)
	for _, displayCropType in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[displayCropType.fruitTypeIndex] then
			local foliageId = displayCropType.foliageId
			local desc = self.fruitTypeManager:getFruitTypeByIndex(displayCropType.fruitTypeIndex)

			if desc.maxHarvestingGrowthState >= 0 then
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED] then
					local witheredState = desc.maxHarvestingGrowthState + 1

					if desc.maxPreparingGrowthState >= 0 then
						witheredState = desc.maxPreparingGrowthState + 1
					end

					if witheredState ~= desc.cutState and witheredState ~= desc.preparedGrowthState and witheredState ~= desc.minPreparingGrowthState then
						local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED].colors[self.isColorBlindMode][1]

						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, witheredState + 1, color[1], color[2], color[3])
					end
				end

				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED] then
					local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED].colors[self.isColorBlindMode][1]

					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, desc.cutState + 1, color[1], color[2], color[3])
				end

				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] then
					local maxGrowingState = desc.minHarvestingGrowthState - 1

					if desc.minPreparingGrowthState >= 0 then
						maxGrowingState = math.min(maxGrowingState, desc.minPreparingGrowthState - 1)
					end

					local colors = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING].colors[self.isColorBlindMode]

					for i = 0, maxGrowingState do
						local index = math.min(i + 1, #colors)

						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i + 1, colors[index][1], colors[index][2], colors[index][3])
					end
				end

				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING] and desc.minPreparingGrowthState >= 0 then
					local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING].colors[self.isColorBlindMode][1]

					for i = desc.minPreparingGrowthState, desc.maxPreparingGrowthState do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i + 1, color[1], color[2], color[3])
					end
				end

				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] then
					local colors = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST].colors[self.isColorBlindMode]

					for i = desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState do
						local index = math.min(i - desc.minHarvestingGrowthState + 1, #colors)

						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i + 1, colors[index][1], colors[index][2], colors[index][3])
					end
				end
			end
		end
	end

	if g_currentMission.terrainDetailId ~= 0 then
		local fieldMask = bitShiftLeft(bitShiftLeft(1, g_currentMission.terrainDetailTypeNumChannels) - 1, g_currentMission.terrainDetailTypeFirstChannel)

		if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED] then
			local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED].colors[self.isColorBlindMode][1]

			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, fieldMask, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.cultivatorValue, color[1], color[2], color[3])
		end

		if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED] then
			local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED].colors[self.isColorBlindMode][1]

			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, fieldMask, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.plowValue, color[1], color[2], color[3])
		end
	end
end

function MapOverlayGenerator:buildSoilStateMapOverlay(soilStateFilter)
	if g_currentMission.terrainDetailId ~= 0 then
		local fieldMask = bitShiftLeft(bitShiftLeft(1, g_currentMission.terrainDetailTypeNumChannels) - 1, g_currentMission.terrainDetailTypeFirstChannel)

		if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] then
			for _, missionFruitType in ipairs(self.missionFruitTypes) do
				if missionFruitType.fruitTypeIndex == FruitType.WEED then
					local weedType = self.fruitTypeManager:getWeedFruitType()
					local minDisplayState = weedType.weed.minValue + 1
					local maxDisplayState = weedType.weed.maxValue
					local colors = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS].colors[self.isColorBlindMode]

					for i = minDisplayState, maxDisplayState do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, missionFruitType.foliageId, i, unpack(colors[1]))
					end
				end
			end
		end

		if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING] then
			local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING].colors[self.isColorBlindMode][1]

			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, fieldMask, g_currentMission.plowCounterFirstChannel, g_currentMission.plowCounterNumChannels, 0, color[1], color[2], color[3])
		end

		if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] then
			local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME].colors[self.isColorBlindMode][1]

			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, fieldMask, g_currentMission.limeCounterFirstChannel, g_currentMission.limeCounterNumChannels, 0, color[1], color[2], color[3])
		end

		if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] then
			local colors = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED].colors[self.isColorBlindMode]
			local maxSprayLevel = bitShiftLeft(1, g_currentMission.sprayLevelNumChannels) - 1

			for level = 1, maxSprayLevel do
				local color = colors[math.min(level, #colors)]

				setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, g_currentMission.terrainDetailId, fieldMask, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels, level, color[1], color[2], color[3])
			end
		end
	end
end

function MapOverlayGenerator:buildFarmlandsMapOverlay(selectedFarmland)
	local map = self.farmlandManager:getLocalMap()
	local farmlands = self.farmlandManager:getFarmlands()

	setOverlayColor(self.farmlandStateOverlay, 1, 1, 1, MapOverlayGenerator.FARMLANDS_ALPHA)

	for k, farmland in pairs(farmlands) do
		local ownerFarmId = self.farmlandManager:getFarmlandOwner(farmland.id)

		if ownerFarmId ~= FarmlandManager.NOT_BUYABLE_FARM_ID then
			if selectedFarmland ~= nil and farmland.id == selectedFarmland.id then
				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, map, 0, 0, getBitVectorMapNumChannels(map), k, unpack(MapOverlayGenerator.COLOR.FIELD_SELECTED))
			else
				local color = MapOverlayGenerator.COLOR.FIELD_UNOWNED

				if farmland.isOwned then
					local ownerFarm = self.farmManager:getFarmById(ownerFarmId)
					color = ownerFarm:getColor()
				end

				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, map, 0, 0, getBitVectorMapNumChannels(map), k, unpack(color))
			end
		end
	end

	local profileClass = Utils.getPerformanceClassId()

	if GS_PROFILE_HIGH <= profileClass and not GS_IS_CONSOLE_VERSION then
		setDensityMapVisualizationOverlayStateBorderColor(self.farmlandStateOverlay, map, 0, getBitVectorMapNumChannels(map), MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS, unpack(MapOverlayGenerator.COLOR.FIELD_BORDER))
	end
end

function MapOverlayGenerator:generateOverlay(mapOverlayType, finishedCallback, overlayState, overlayState2)
	local success = true

	if self.overlayTypeCheckHash[mapOverlayType] == nil then
		g_logManager:warning("Tried generating a map overlay with an invalid overlay type: [%s]", tostring(mapOverlayType))

		success = false
	else
		local overlayHandle = self.overlayHandles[mapOverlayType]
		self.overlayFinishedCallback = finishedCallback or NO_CALLBACK

		resetDensityMapVisualizationOverlay(overlayHandle)

		self.currentOverlayHandle = overlayHandle
		local builderFunction = self.typeBuilderFunctionMap[mapOverlayType]

		builderFunction(self, overlayState, overlayState2)
		generateDensityMapVisualizationOverlay(overlayHandle)
		self:checkOverlayFinished()
	end

	return success
end

function MapOverlayGenerator:generateFruitTypeOverlay(finishedCallback, fruitTypeFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.CROPS, finishedCallback, fruitTypeFilter)
end

function MapOverlayGenerator:generateGrowthStateOverlay(finishedCallback, growthStateFilter, fruitTypeFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.GROWTH, finishedCallback, growthStateFilter, fruitTypeFilter)
end

function MapOverlayGenerator:generateSoilStateOverlay(finishedCallback, soilStateFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.SOIL, finishedCallback, soilStateFilter)
end

function MapOverlayGenerator:generateFarmlandOverlay(finishedCallback, mapPosition)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS, finishedCallback, mapPosition)
end

function MapOverlayGenerator:checkOverlayFinished()
	if self.currentOverlayHandle ~= nil and getIsDensityMapVisualizationOverlayReady(self.currentOverlayHandle) then
		self.overlayFinishedCallback(self.currentOverlayHandle)

		self.currentOverlayHandle = nil
	end
end

function MapOverlayGenerator:reset()
	resetDensityMapVisualizationOverlay(self.foliageStateOverlay)
	resetDensityMapVisualizationOverlay(self.farmlandStateOverlay)

	self.currentOverlayHandle = nil
end

function MapOverlayGenerator:update(dt)
	self:checkOverlayFinished()
end

function MapOverlayGenerator:getDisplayCropTypes()
	local cropTypes = {}

	for i, fruitType in ipairs(self.missionFruitTypes) do
		if fruitType.shownOnMap and fruitType.fruitTypeIndex ~= FruitType.WEED then
			local fillableIndex = self.fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType.fruitTypeIndex)
			local fillable = self.fillTypeManager:getFillTypeByIndex(fillableIndex)
			local iconFilename = fillable.hudOverlayFilenameSmall
			local iconUVs = Overlay.DEFAULT_UVS
			local description = fillable.title

			table.insert(cropTypes, {
				colors = {
					[false] = fruitType.defaultColor,
					[true] = fruitType.colorBlindColor
				},
				iconFilename = iconFilename,
				iconUVs = iconUVs,
				description = description,
				fruitTypeIndex = fruitType.fruitTypeIndex,
				foliageId = fruitType.foliageId
			})
		end
	end

	return cropTypes
end

function MapOverlayGenerator:getDisplayGrowthStates()
	local res = {
		[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_CULTIVATED)
		},
		[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] = {
			colors = MapOverlayGenerator.FRUIT_COLORS_GROWING,
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_GROWING)
		},
		[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] = {
			colors = MapOverlayGenerator.FRUIT_COLORS_HARVEST,
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVEST)
		},
		[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_CUT
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_CUT
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVESTED)
		},
		[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_TOPPING)
		}
	}

	if not GS_IS_MOBILE_VERSION then
		res[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_PLOWED[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_PLOWED[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_PLOWED)
		}
		res[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_WITHERED[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_WITHERED[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_WITHERED)
		}
	end

	return res
end

function MapOverlayGenerator:getDisplaySoilStates()
	local weedType = self.fruitTypeManager:getWeedFruitType()
	local fillableIndex = self.fruitTypeManager:getFillTypeIndexByFruitTypeIndex(FruitType.WEED)
	local res = {
		[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] = {
			colors = MapOverlayGenerator.FRUIT_COLORS_FERTILIZED,
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_FERTILIZED)
		}
	}

	do
		res[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_LIME)
		}
	end

	do
		res[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING] = {
			colors = {
				[true] = {
					MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[true]
				},
				[false] = {
					MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[false]
				}
			},
			description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_PLOWING)
		}
	end

	if weedType ~= nil then
		local weedFillable = self.fillTypeManager:getFillTypeByIndex(fillableIndex)
		local weedBlindColor = {
			weedType.colorBlindMapColor
		} or {
			0,
			0,
			0,
			0
		}
		local weedColor = {
			weedType.defaultMapColor
		} or {
			0,
			0,
			0,
			0
		}
		local weedDescription = weedFillable.title or ""
		res[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] = {
			colors = {
				[true] = {
					weedBlindColor
				},
				[false] = {
					weedColor
				}
			},
			description = weedDescription
		}
	end

	return res
end

MapOverlayGenerator.GROWTH_STATE_INDEX = {
	HARVESTED = 4,
	HARVEST = 3,
	CULTIVATED = 1,
	GROWING = 2,
	WITHERED = 7,
	PLOWED = GS_IS_MOBILE_VERSION and 6 or 5,
	TOPPING = GS_IS_MOBILE_VERSION and 5 or 6
}
MapOverlayGenerator.SOIL_STATE_INDEX = {
	WEEDS = GS_IS_MOBILE_VERSION and 4 or 1,
	FERTILIZED = GS_IS_MOBILE_VERSION and 1 or 2,
	NEEDS_PLOWING = GS_IS_MOBILE_VERSION and 3 or 3,
	NEEDS_LIME = GS_IS_MOBILE_VERSION and 2 or 4
}
MapOverlayGenerator.FRUIT_COLORS_GROWING = {
	[false] = {
		{
			0.2928,
			0.6795,
			0.0217,
			1
		},
		{
			0.1454,
			0.5583,
			0.0341,
			1
		},
		{
			0.0257,
			0.4621,
			0.0223,
			1
		},
		{
			0.0143,
			0.2582,
			0.0126,
			1
		}
	},
	[true] = {
		{
			1,
			0.9473,
			0.227,
			1
		},
		{
			1,
			0.9046,
			0.013,
			1
		},
		{
			0.5583,
			0.4735,
			0.007,
			1
		},
		{
			0.2122,
			0.1779,
			0.0027,
			1
		}
	}
}
MapOverlayGenerator.FRUIT_COLORS_HARVEST = {
	[false] = {
		{
			0.8308,
			0.5841,
			0.0529,
			1
		},
		{
			0.7758,
			0.3095,
			0.013,
			1
		},
		{
			0.7304,
			0.1746,
			0.0262,
			1
		}
	},
	[true] = {
		{
			0.3372,
			0.4397,
			0.9911,
			1
		},
		{
			0.0561,
			0.1384,
			0.5841,
			1
		},
		{
			0.0075,
			0.0545,
			0.3095,
			1
		}
	}
}
MapOverlayGenerator.FRUIT_COLORS_FERTILIZED = {}

if not GS_IS_MOBILE_VERSION then
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = {
		{
			0.0091,
			0.0931,
			0.5841,
			1
		},
		{
			0.0018,
			0.0382,
			0.2961,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = {
		{
			0.0086,
			0.0976,
			0.5776,
			1
		},
		{
			0,
			0.0409,
			0.2918,
			1
		}
	}
else
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = {
		{
			0.0018,
			0.0382,
			0.2961,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = {
		{
			0,
			0.0409,
			0.2918,
			1
		}
	}
end

MapOverlayGenerator.FRUIT_COLORS_DISABLED = {
	{
		0.4,
		0.4,
		0.4,
		1
	},
	{
		0.3,
		0.3,
		0.3,
		1
	},
	{
		0.2,
		0.2,
		0.2,
		1
	},
	{
		0.1,
		0.1,
		0.1,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING = {
	[false] = {
		0.6172,
		0.051,
		0.051,
		1
	},
	[true] = {
		1,
		0.8632,
		0.0232,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME = {
	[false] = {
		0.0815,
		0.6584,
		0.4198,
		1
	},
	[true] = {
		0.6795,
		0.6867,
		0.7231,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS = {
	[false] = {
		0.7011,
		0.0452,
		0.0123,
		1
	},
	[true] = {
		0.3231,
		0.3467,
		0.4621,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_WITHERED = {
	[false] = {
		0.1441,
		0.0452,
		0.0123,
		1
	},
	[true] = {
		0.1195,
		0.1144,
		0.0908,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED = {
	[false] = {
		0.0967,
		0.3758,
		0.7084,
		1
	},
	[true] = {
		0.2918,
		0.3564,
		0.7011,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_PLOWED = {
	[false] = {
		0.0815,
		0.6584,
		0.4198,
		1
	},
	[true] = {
		0.6795,
		0.6867,
		0.7231,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_SOWN = {
	[false] = {
		0.9301,
		0.6404,
		0.0439,
		1
	},
	[true] = {
		0.7681,
		0.6514,
		0.0529,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_CUT = {
	0.2647,
	0.1038,
	0.358,
	1
}
MapOverlayGenerator.FRUIT_COLOR_DISABLED = {
	0.2,
	0.2,
	0.2,
	1
}
MapOverlayGenerator.COLOR = {
	FIELD_UNOWNED = {
		0,
		0,
		0
	},
	FIELD_SELECTED = {
		0.2079,
		0.7808,
		0.9965
	},
	FIELD_BORDER = {
		0.2,
		0.2,
		0.2
	}
}
MapOverlayGenerator.FARMLANDS_ALPHA = 0.5
MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS = 3
MapOverlayGenerator.L10N_SYMBOL = {
	GROWTH_MAP_HARVESTED = "ui_growthMapCutted",
	GROWTH_MAP_WITHERED = "ui_growthMapWithered",
	GROWTH_MAP_PLOWED = "ui_growthMapPlowed",
	GROWTH_MAP_HARVEST = "ui_growthMapReadyToHarvest",
	SOIL_MAP_NEED_PLOWING = "ui_growthMapNeedsPlowing",
	SOIL_MAP_NEED_LIME = "ui_growthMapNeedsLime",
	GROWTH_MAP_TOPPING = "ui_growthMapReadyToPrepareForHarvest",
	GROWTH_MAP_CULTIVATED = "ui_growthMapCultivated",
	SOIL_MAP_FERTILIZED = "ui_growthMapFertilized",
	GROWTH_MAP_GROWING = "ui_growthMapGrowing"
}
