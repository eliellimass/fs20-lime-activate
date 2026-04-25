FSMissionInfo = {}
local FSMissionInfo_mt = Class(FSMissionInfo, MissionInfo)

function FSMissionInfo:new(baseDirectory, customEnvironment, customMt)
	if customMt == nil then
		customMt = FSMissionInfo_mt
	end

	local self = FSMissionInfo:superClass():new(baseDirectory, customEnvironment, customMt)

	return self
end

function FSMissionInfo:loadDefaults()
	FSMissionInfo:superClass().loadDefaults(self)

	self.automaticMotorStartEnabled = true
	self.stopAndGoBraking = true
	self.fruitDestruction = true
	self.plowingRequiredEnabled = true
	self.weedsEnabled = true
	self.limeRequired = true
	self.fuelUsageLow = false
	self.helperBuyFuel = false
	self.helperBuySeeds = false
	self.helperBuyFertilizer = false
	self.helperSlurrySource = 2
	self.helperManureSource = 2
	self.difficulty = 1
	self.economicDifficulty = 2
	self.buyPriceMultiplier = 1
	self.sellPriceMultiplier = 1
	self.fuelUsage = 0
	self.seedUsage = 0
	self.sprayUsage = 0
	self.traveledDistance = 0
	self.workedHectares = 0
	self.cultivatedHectares = 0
	self.sownHectares = 0
	self.fertilizedHectares = 0
	self.threshedHectares = 0
	self.revenue = 0
	self.expenses = 0
	self.playTime = 0
	self.playerStyle = PlayerStyle:new()
	self.dayTime = 400

	if g_isPresentationVersion then
		self.dayTime = 900
	end

	self.currentDay = 1
	self.realHourTimer = 3600000
	self.timeScale = g_platformSettingsManager:getSetting("defaultTimeScale", 5)
	self.timeScaleMultiplier = 1
	self.missionFrequency = 2
	self.plantGrowthRate = 3
	self.isPlantWitheringEnabled = true
	self.trafficEnabled = true
	self.dirtInterval = 3
	self.steeringBackSpeed = 5
	self.steeringSensitivity = 1
	self.fieldJobMissionCount = 0
	self.transportMissionCount = 0
	self.fieldJobMissionByNPC = 0
	self.foundHelpIcons = "00000000000000000000"
	self.savegameName = g_i18n:getText("defaultSavegameName")
	self.plantedTreeCount = 0
	self.cutTreeCount = 0
	self.woodTonsSold = 0
	self.treeTypesCut = "000000"
	self.windTurbineCount = 0
end

function FSMissionInfo:getIsDensityMapValid(mission)
	return false
end

function FSMissionInfo:getIsTerrainLodTextureValid(mission)
	return false
end

function FSMissionInfo:getAreSplitShapesValid(mission)
	return false
end

function FSMissionInfo:getIsTipCollisionValid(mission)
	return false
end

function FSMissionInfo:getIsPlacementCollisionValid(mission)
	return false
end

function FSMissionInfo:getIsLoadedFromSavegame()
	return true
end
