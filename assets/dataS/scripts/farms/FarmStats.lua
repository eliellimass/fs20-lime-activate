FarmStats = {}
local FarmStats_mt = Class(FarmStats)
FarmStats.STAT_NAMES = {
	"fuelUsage",
	"seedUsage",
	"sprayUsage",
	"traveledDistance",
	"workedHectares",
	"cultivatedHectares",
	"plowedHectares",
	"sownHectares",
	"fertilizedHectares",
	"threshedHectares",
	"sprayedHectares",
	"weededHectares",
	"workedTime",
	"cultivatedTime",
	"plowedTime",
	"sownTime",
	"fertilizedTime",
	"threshedTime",
	"sprayedTime",
	"weededTime",
	"baleCount",
	"breedCowsCount",
	"breedPigsCount",
	"breedSheepCount",
	"breedChickenCount",
	"breedHorsesCount",
	"revenue",
	"expenses",
	"playTime",
	"workersHired",
	"storedBales",
	"storageCapacity",
	"fieldJobMissionCount",
	"fieldJobMissionByNPC",
	"transportMissionCount",
	"plantedTreeCount",
	"cutTreeCount",
	"woodTonsSold",
	"treeTypesCut",
	"windTurbineCount"
}
FarmStats.HERO_STAT_NAMES = {
	"playTime",
	"moneyEarned",
	"traveledDistance",
	"completedMissions",
	"threshedHectares"
}

function FarmStats:new()
	local self = {}

	setmetatable(self, FarmStats_mt)

	self.statistics = {}

	for _, statName in pairs(FarmStats.STAT_NAMES) do
		self.statistics[statName] = {
			session = 0,
			total = 0
		}
	end

	self.statistics.treeTypesCut = "000000"
	self.finances = FinanceStats:new()
	self.financesHistory = {}
	self.heroStats = {}

	for _, heroStat in pairs(FarmStats.HERO_STAT_NAMES) do
		self.heroStats[heroStat] = {
			accumValue = 0
		}
	end

	self.heroStatsLoaded = false
	self.moneyEarnedHeroAccum = 0
	self.nextHeroAccumUpdate = 0

	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)
	end

	self.financesVersionCounter = 0
	self.financesHistoryVersionCounter = 0
	self.financesHistoryVersionCounterLocal = 0

	return self
end

function FarmStats:delete()
	g_currentMission:removeUpdateable(self)
end

function FarmStats:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key .. ".statistics.traveledDistance", self.statistics.traveledDistance.total)
	setXMLFloat(xmlFile, key .. ".statistics.fuelUsage", self.statistics.fuelUsage.total)
	setXMLFloat(xmlFile, key .. ".statistics.seedUsage", self.statistics.seedUsage.total)
	setXMLFloat(xmlFile, key .. ".statistics.sprayUsage", self.statistics.sprayUsage.total)
	setXMLFloat(xmlFile, key .. ".statistics.workedHectares", self.statistics.workedHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.cultivatedHectares", self.statistics.cultivatedHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.sownHectares", self.statistics.sownHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.fertilizedHectares", self.statistics.fertilizedHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.threshedHectares", self.statistics.threshedHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.plowedHectares", self.statistics.plowedHectares.total)
	setXMLFloat(xmlFile, key .. ".statistics.workedTime", self.statistics.workedTime.total)
	setXMLFloat(xmlFile, key .. ".statistics.cultivatedTime", self.statistics.cultivatedTime.total)
	setXMLFloat(xmlFile, key .. ".statistics.sownTime", self.statistics.sownTime.total)
	setXMLFloat(xmlFile, key .. ".statistics.fertilizedTime", self.statistics.fertilizedTime.total)
	setXMLFloat(xmlFile, key .. ".statistics.threshedTime", self.statistics.threshedTime.total)
	setXMLFloat(xmlFile, key .. ".statistics.plowedTime", self.statistics.plowedTime.total)
	setXMLInt(xmlFile, key .. ".statistics.baleCount", self.statistics.baleCount.total)
	setXMLInt(xmlFile, key .. ".statistics.breedCowsCount", self.statistics.breedCowsCount.total)
	setXMLInt(xmlFile, key .. ".statistics.breedSheepCount", self.statistics.breedSheepCount.total)
	setXMLInt(xmlFile, key .. ".statistics.breedPigsCount", self.statistics.breedPigsCount.total)
	setXMLInt(xmlFile, key .. ".statistics.breedChickenCount", self.statistics.breedChickenCount.total)
	setXMLInt(xmlFile, key .. ".statistics.breedHorsesCount", self.statistics.breedHorsesCount.total)
	setXMLInt(xmlFile, key .. ".statistics.fieldJobMissionCount", self.statistics.fieldJobMissionCount.total)
	setXMLInt(xmlFile, key .. ".statistics.fieldJobMissionByNPC", self.statistics.fieldJobMissionByNPC.total)
	setXMLInt(xmlFile, key .. ".statistics.transportMissionCount", self.statistics.transportMissionCount.total)
	setXMLFloat(xmlFile, key .. ".statistics.revenue", self.statistics.revenue.total)
	setXMLFloat(xmlFile, key .. ".statistics.expenses", self.statistics.expenses.total)
	setXMLFloat(xmlFile, key .. ".statistics.playTime", self.statistics.playTime.total)
	setXMLInt(xmlFile, key .. ".statistics.plantedTreeCount", self.statistics.plantedTreeCount.total)
	setXMLInt(xmlFile, key .. ".statistics.cutTreeCount", self.statistics.cutTreeCount.total)
	setXMLFloat(xmlFile, key .. ".statistics.woodTonsSold", self.statistics.woodTonsSold.total)
	setXMLString(xmlFile, key .. ".statistics.treeTypesCut", self.statistics.treeTypesCut)

	local toSave = {
		self.finances
	}
	local numHistoricItems = #self.financesHistory

	for n = 3, 0, -1 do
		if n < numHistoricItems then
			table.insert(toSave, self.financesHistory[numHistoricItems - n])
		end
	end

	for i, finances in ipairs(toSave) do
		local statsKey = string.format("%s.finances.stats(%d)", key, i - 1)

		setXMLInt(xmlFile, statsKey .. "#day", i - 1)
		finances:saveToXMLFile(xmlFile, statsKey)
	end
end

function FarmStats:loadFromXMLFile(xmlFile, key)
	local farmKey = key
	local key = key .. ".statistics"
	self.statistics.traveledDistance.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".traveledDistance"), 0)
	self.statistics.fuelUsage.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fuelUsage"), 0)
	self.statistics.seedUsage.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".seedUsage"), 0)
	self.statistics.sprayUsage.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".sprayUsage"), 0)
	self.statistics.workedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".workedHectares"), 0)
	self.statistics.cultivatedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".cultivatedHectares"), 0)
	self.statistics.sownHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".sownHectares"), 0)
	self.statistics.fertilizedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fertilizedHectares"), 0)
	self.statistics.sprayedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".sprayedHectares"), 0)
	self.statistics.threshedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".threshedHectares"), 0)
	self.statistics.weededHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".weededHectares"), 0)
	self.statistics.plowedHectares.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".plowedHectares"), 0)
	self.statistics.workedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".workedTime"), 0)
	self.statistics.cultivatedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".cultivatedTime"), 0)
	self.statistics.sownTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".sownTime"), 0)
	self.statistics.fertilizedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fertilizedTime"), 0)
	self.statistics.threshedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".threshedTime"), 0)
	self.statistics.weededTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".weededTime"), 0)
	self.statistics.sprayedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".sprayedTime"), 0)
	self.statistics.plowedTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".plowedTime"), 0)
	self.statistics.baleCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".baleCount"), 0)
	self.statistics.breedCowsCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".breedCowsCount"), 0)
	self.statistics.breedSheepCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".breedSheepCount"), 0)
	self.statistics.breedPigsCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".breedPigsCount"), 0)
	self.statistics.breedChickenCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".breedChickenCount"), 0)
	self.statistics.breedHorsesCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".breedHorsesCount"), 0)
	self.statistics.fieldJobMissionCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".fieldJobMissionCount"), 0)
	self.statistics.fieldJobMissionByNPC.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".fieldJobMissionByNPC"), 0)
	self.statistics.transportMissionCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".transportMissionCount"), 0)
	self.statistics.plantedTreeCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".plantedTreeCount"), 0)
	self.statistics.cutTreeCount.total = Utils.getNoNil(getXMLInt(xmlFile, key .. ".cutTreeCount"), 0)
	self.statistics.woodTonsSold.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".woodTonsSold"), 0)
	self.statistics.treeTypesCut = Utils.getNoNil(getXMLString(xmlFile, key .. ".treeTypesCut"), "000000")
	self.statistics.revenue.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".revenue"), 0)
	self.statistics.expenses.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".expenses"), 0)
	self.statistics.playTime.total = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".playTime"), 0)
	local i = 0

	while true do
		local financeKey = string.format("%s.finances.stats(%d)", farmKey, i)
		local day = getXMLInt(xmlFile, financeKey .. "#day")

		if day == nil then
			break
		end

		local finances = FinanceStats:new()

		finances:loadFromXMLFile(xmlFile, financeKey)

		if day == 0 then
			self.finances = finances
		else
			table.insert(self.financesHistory, finances)
		end

		i = i + 1
	end
end

function FarmStats:update(dt)
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		if not self.heroStatsLoaded and areStatsAvailable() then
			self.heroStatsLoaded = true

			for heroStatName, heroStat in pairs(self.heroStats) do
				heroStat.id = statsGetIndex(heroStatName)
				heroStat.value = statsGet(heroStat.id)

				if heroStat.accumValue ~= 0 then
					heroStat.value = heroStat.value + heroStat.accumValue

					statsSet(heroStat.id, heroStat.value)

					heroStat.accumValue = 0
				end
			end
		end

		if self.nextHeroAccumUpdate <= g_time and self.moneyEarnedHeroAccum > 0 then
			self:addValueToHeroStat("moneyEarned", self.moneyEarnedHeroAccum)

			self.moneyEarnedHeroAccum = 0
			self.nextHeroAccumUpdate = g_time + 10000
		end
	end

	self:updateStats("playTime", dt / 60000)
end

function FarmStats:addValueToHeroStat(name, value)
	local heroStat = self.heroStats[name]

	if self.heroStatsLoaded then
		heroStat.value = heroStat.value + value

		statsSet(heroStat.id, heroStat.value)
	else
		heroStat.accumValue = heroStat.accumValue + value
	end
end

function FarmStats:changeFinanceStats(amount, statType)
	if statType ~= nil and self.finances[statType] ~= nil then
		self.finances[statType] = self.finances[statType] + amount

		if g_currentMission:getIsServer() then
			self.financesVersionCounter = self.financesVersionCounter + 1

			if self.financesVersionCounter > 999999 then
				self.financesVersionCounter = 0
			end
		end
	end
end

function FarmStats:archiveFinances()
	if g_currentMission:getIsServer() then
		table.insert(self.financesHistory, self.finances)

		self.finances = FinanceStats:new()
		self.financesVersionCounter = self.financesVersionCounter + 1

		if self.financesVersionCounter > 999999 then
			self.financesVersionCounter = 0
		end

		self.financesHistoryVersionCounter = self.financesHistoryVersionCounter + 1

		if self.financesHistoryVersionCounter > 127 then
			self.financesHistoryVersionCounter = 0
		end
	end
end

function FarmStats:getCompletedFieldMissions()
	return self:getTotalValue("fieldJobMissionCount")
end

function FarmStats:getCompletedFieldMissionsSession()
	return self:getSessionValue("fieldJobMissionCount")
end

function FarmStats:getCompletedTransportMissions()
	return self:getTotalValue("transportMissionCount")
end

function FarmStats:getCompletedTransportMissionsSession()
	return self:getSessionValue("transportMissionCount")
end

function FarmStats:getCompletedMissions()
	return self:getTotalValue("fieldJobMissionCount") + self:getTotalValue("transportMissionCount")
end

function FarmStats:getCompletedMissionsSession()
	return self:getSessionValue("fieldJobMissionCount") + self:getSessionValue("transportMissionCount")
end

function FarmStats:updateStats(statName, delta)
	if delta == nil then
		printCallstack()
	end

	if self.statistics[statName] ~= nil then
		self.statistics[statName].session = self.statistics[statName].session + delta

		if self.statistics[statName].total ~= nil then
			self.statistics[statName].total = self.statistics[statName].total + delta
		end
	else
		print("Error: Invalid statistic '" .. statName .. "'")
	end

	self:addHeroStat(statName, delta)
end

function FarmStats:addHeroStat(statName, delta)
	if self.heroStats[statName] ~= nil then
		if statName == "moneyEarned" then
			self.moneyEarnedHeroAccum = self.moneyEarnedHeroAccum + delta
		else
			self:addValueToHeroStat(statName, delta)
		end
	elseif statName == "fieldJobMissionCount" then
		self:addValueToHeroStat("completedMissions", delta)
	end
end

function FarmStats:getTotalValue(statName)
	if self.statistics[statName] ~= nil then
		return self.statistics[statName].total
	end

	return nil
end

function FarmStats:getSessionValue(statName)
	if self.statistics[statName] ~= nil then
		return self.statistics[statName].session
	end

	return nil
end

function FarmStats:updateTreeTypesCut(splitTypeName)
	local trees = {
		"oak",
		"birch",
		"maple",
		{
			"spruce",
			"pine"
		},
		"poplar",
		"ash"
	}

	for i, treeName in ipairs(trees) do
		local treeMatch = false

		if type(treeName) == "table" then
			for _, subTreeName in pairs(treeName) do
				if splitTypeName == subTreeName then
					treeMatch = true
				end
			end
		elseif splitTypeName == treeName then
			treeMatch = true
		end

		if treeMatch then
			local stats = self.statistics
			stats.treeTypesCut = string.sub(stats.treeTypesCut, 1, i - 1) .. "1" .. string.sub(stats.treeTypesCut, i + 1, string.len(stats.treeTypesCut))
		end
	end
end

function FarmStats:updateFieldJobsDone(npcIndex)
	self.statistics.fieldJobMissionCount.session = self.statistics.fieldJobMissionCount.session + 1
	self.statistics.fieldJobMissionCount.total = self.statistics.fieldJobMissionCount.total + 1
	local npcValue = 2^npcIndex
	self.statistics.fieldJobMissionByNPC.total = bitOR(self.statistics.fieldJobMissionByNPC.total, npcValue)
end

function FarmStats:updateTransportJobsDone()
	self.statistics.transportMissionCount.session = self.statistics.transportMissionCount.session + 1
	self.statistics.transportMissionCount.total = self.statistics.transportMissionCount.total + 1
end

function FarmStats:getStatisticData()
	if not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission.missionDynamicInfo.isClient then
		self:addStatistic("workedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("workedHectares")), g_i18n:getArea(self:getTotalValue("workedHectares")), "%.2f")
		self:addStatistic("cultivatedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("cultivatedHectares")), g_i18n:getArea(self:getTotalValue("cultivatedHectares")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("plowedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("plowedHectares")), g_i18n:getArea(self:getTotalValue("plowedHectares")), "%.2f")
		end

		self:addStatistic("sownHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sownHectares")), g_i18n:getArea(self:getTotalValue("sownHectares")), "%.2f")
		self:addStatistic("fertilizedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("fertilizedHectares")), g_i18n:getArea(self:getTotalValue("fertilizedHectares")), "%.2f")
		self:addStatistic("threshedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("threshedHectares")), g_i18n:getArea(self:getTotalValue("threshedHectares")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("workedTime", nil, Utils.formatTime(self:getSessionValue("workedTime")), Utils.formatTime(self:getTotalValue("workedTime")), "%s")
			self:addStatistic("cultivatedTime", nil, Utils.formatTime(self:getSessionValue("cultivatedTime")), Utils.formatTime(self:getTotalValue("cultivatedTime")), "%s")
			self:addStatistic("plowedTime", nil, Utils.formatTime(self:getSessionValue("plowedTime")), Utils.formatTime(self:getTotalValue("plowedTime")), "%s")
			self:addStatistic("sownTime", nil, Utils.formatTime(self:getSessionValue("sownTime")), Utils.formatTime(self:getTotalValue("sownTime")), "%s")
			self:addStatistic("fertilizedTime", nil, Utils.formatTime(self:getSessionValue("fertilizedTime")), Utils.formatTime(self:getTotalValue("fertilizedTime")), "%s")
			self:addStatistic("threshedTime", nil, Utils.formatTime(self:getSessionValue("threshedTime")), Utils.formatTime(self:getTotalValue("threshedTime")), "%s")
		end

		self:addStatistic("traveledDistance", g_i18n:getMeasuringUnit(), g_i18n:getDistance(self:getSessionValue("traveledDistance")), g_i18n:getDistance(self:getTotalValue("traveledDistance")), "%.2f")
		self:addStatistic("fuelUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("fuelUsage")), g_i18n:getFluid(self:getTotalValue("fuelUsage")), "%.2f")
		self:addStatistic("seedUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("seedUsage")), g_i18n:getFluid(self:getTotalValue("seedUsage")), "%.2f")
		self:addStatistic("sprayUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("sprayUsage")), g_i18n:getFluid(self:getTotalValue("sprayUsage")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("baleCount", nil, self:getSessionValue("baleCount"), self:getTotalValue("baleCount"), "%d")
			self:addStatistic("plantedTreeCount", nil, self:getSessionValue("plantedTreeCount"), self:getTotalValue("plantedTreeCount"), "%d")
			self:addStatistic("cutTreeCount", nil, self:getSessionValue("cutTreeCount"), self:getTotalValue("cutTreeCount"), "%d")
			self:addStatistic("fieldJobMissionCount", nil, self:getSessionValue("fieldJobMissionCount"), self:getTotalValue("fieldJobMissionCount"), "%d")
			self:addStatistic("transportMissionCount", nil, self:getSessionValue("transportMissionCount"), self:getTotalValue("transportMissionCount"), "%d")
		end

		self:addStatistic("playTime", nil, Utils.formatTime(self:getSessionValue("playTime")), Utils.formatTime(self:getTotalValue("playTime")), "%s")
		self:addStatistic("workersHired", nil, self:getSessionValue("workersHired"), nil, "%s")

		if GS_IS_MOBILE_VERSION then
			self:addStatistic("storedBales", nil, self:getSessionValue("storedBales"), nil, "%s")
		end

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("storageCapacity", nil, g_currentMission:getFarmSiloCapacity(), nil, "%s")
		end
	end

	return Utils.getNoNil(self.statisticData, {})
end

function FarmStats:addStatistic(name, unit, valueSession, valueTotal, stringFormat)
	if self.statisticData == nil then
		self.statisticData = {}
		self.statisticDataRev = {}
	end

	local formattedName = g_i18n:getText("statistic_" .. name, g_currentMission.missionInfo.customEnvironment)

	if unit ~= nil then
		formattedName = formattedName .. " [" .. unit .. "]"
	end

	local newDataSet = self.statisticDataRev[name]

	if newDataSet == nil then
		newDataSet = {}
		self.statisticDataRev[name] = newDataSet

		table.insert(self.statisticData, newDataSet)
	end

	newDataSet.name = formattedName
	newDataSet.valueSession = string.format(stringFormat, Utils.getNoNil(valueSession, ""))
	newDataSet.valueTotal = string.format(stringFormat, Utils.getNoNil(valueTotal, ""))
end

function FarmStats:merge(other)
	for _, statName in ipairs(FarmStats.STAT_NAMES) do
		if statName == "treeTypesCut" then
			local cut = self.statistics.treeTypesCut

			for i = 1, string.len(cut) do
				if string.sub(other.statistics.treeTypesCut, i, i) == "1" then
					cut = string.sub(cut, 1, i - 1) .. "1" .. string.sub(cut, i + 1, string.len(cut))
				end
			end

			self.statistics.treeTypesCut = cut
		else
			self.statistics[statName].total = self.statistics[statName].total + other.statistics[statName].total
		end
	end

	self.finances:merge(other.finances)

	return self
end
