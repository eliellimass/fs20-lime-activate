AchievementManager = {}
local AchievementManager_mt = Class(AchievementManager, AbstractManager)

function AchievementManager:new(customMt, messageCenter)
	local self = AbstractManager:new(customMt or AchievementManager_mt)
	self.messageCenter = messageCenter

	return self
end

function AchievementManager:initDataStructures()
	self.achievementList = {}
	self.achievementListById = {}
	self.achievementListByName = {}
	self.achievementPlates = nil
	self.numberOfAchievements = 0
	self.numberOfUnlockedAchievements = 0
	self.achievementsValid = false
	self.achievementTimer = 0
	self.achievementTimeInterval = 1500
end

function AchievementManager:load()
	local usePlatinum = GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4
	local xmlFile = loadXMLFile("achievementsXML", "dataS/achievements.xml")
	local xmlFileContent = saveXMLFileToMemory(xmlFile)

	initAchievements(xmlFileContent)

	local i = 0
	self.numberOfAchievements = 0

	while true do
		local key = string.format("achievements.achievement(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local id = getXMLString(xmlFile, key .. "#id")
		local idName = getXMLString(xmlFile, key .. "#idName")
		local score = getXMLInt(xmlFile, key .. "#score")
		local targetScore = getXMLInt(xmlFile, key .. "#targetScore")
		local showScore = getXMLBool(xmlFile, key .. "#showScore")
		local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
		local imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, key .. "#imageSize"), {
			1024,
			1024
		})
		local imageUVs = GuiUtils.getUVs(Utils.getNoNil(getXMLString(xmlFile, key .. "#imageUVs"), "0 0 1 1"), imageSize)
		local psnType = Utils.getNoNil(getXMLString(xmlFile, key .. "#psn_type"), "")

		if id ~= nil and idName ~= nil and (psnType ~= "P" or usePlatinum) then
			local name = g_i18n:getText("achievement_name" .. idName)
			local description = g_i18n:getText("achievement_desc" .. idName)
			description = string.gsub(description, "$MEASURING_UNIT", g_i18n:getMeasuringUnit(true))
			description = string.gsub(description, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))

			self:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename, imageUVs)
		end

		i = i + 1
	end

	delete(xmlFile)

	if areAchievementsAvailable() then
		self:loadAchievementsState()
	end

	return true
end

function AchievementManager:loadMapData()
	if g_currentMission.missionInfo.isNewSPCareer then
		self.startPlayTime = nil
		self.startMoney = nil
		self.startFieldJobMissionCount = nil
		self.startCultivatedHectares = nil
		self.startSownHectares = nil
		self.startFertilizedHectares = nil
		self.startThreshedHectares = nil
		self.startCutTreeCount = nil
		self.startBreedCowsCount = nil
		self.startBreedSheepCount = nil
		self.startBreedPigsCount = nil
		self.startBreedChickenCount = nil
	else
		local stats = g_currentMission:farmStats()
		self.startPlayTime = math.floor(stats:getTotalValue("playTime") / 60 + 0.0001)
		local farm = g_farmManager:getFarmById(0)
		self.startMoney = farm.money
		self.startFieldJobMissionCount = stats:getTotalValue("fieldJobMissionCount")
		self.startCultivatedHectares = stats:getTotalValue("cultivatedHectares")
		self.startSownHectares = stats:getTotalValue("sownHectares")
		self.startFertilizedHectares = stats:getTotalValue("fertilizedHectares")
		self.startThreshedHectares = stats:getTotalValue("threshedHectares")
		self.startCutTreeCount = stats:getTotalValue("cutTreeCount")
		self.startBreedCowsCount = stats:getTotalValue("breedCowsCount")
		self.startBreedSheepCount = stats:getTotalValue("breedSheepCount")
		self.startBreedPigsCount = stats:getTotalValue("breedPigsCount")
		self.startBreedChickenCount = stats:getTotalValue("breedChickenCount")
	end

	return true
end

function AchievementManager:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename, imageUVs)
	local achievement = {
		id = tostring(id),
		idName = idName,
		name = name,
		description = description,
		score = score,
		targetScore = targetScore,
		showScore = showScore,
		imageFilename = imageFilename,
		imageUVs = imageUVs,
		unlocked = false
	}

	table.insert(self.achievementList, achievement)

	self.achievementListById[id] = achievement
	self.achievementListByName[idName] = achievement
	self.numberOfAchievements = self.numberOfAchievements + 1

	return achievement
end

function AchievementManager:resetAchievementsState()
	self.numberOfUnlockedAchievements = 0

	for _, achievement in pairs(self.achievementList) do
		achievement.unlocked = false
	end

	self.achievementsValid = false
end

function AchievementManager:loadAchievementsState()
	self.numberOfUnlockedAchievements = 0

	for _, achievement in pairs(self.achievementList) do
		achievement.unlocked = getAchievement(tonumber(achievement.id))

		if achievement.unlocked then
			self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
		end
	end

	self.achievementsValid = true
end

function AchievementManager:updatePlates()
	if self.achievementPlates ~= nil then
		local achievementsParentId = getChild(self.achievementPlates, "achievements")

		if achievementsParentId ~= 0 then
			local numChildren = getNumOfChildren(achievementsParentId)

			for i = 0, numChildren - 1 do
				local nodeId = getChildAt(achievementsParentId, i)
				local achievementId = getUserAttribute(nodeId, "id")

				if achievementId ~= nil and self.achievementListById[achievementId] ~= nil and self.achievementListById[achievementId].unlocked then
					setVisibility(nodeId, true)
				else
					setVisibility(nodeId, false)
				end
			end
		end
	end
end

function AchievementManager:handleStandardScoreAchievement(idName, currentScore, startScore)
	local currentAchievement = self.achievementListByName[idName]

	if currentAchievement ~= nil and not currentAchievement.unlocked then
		local ignoreAchievement = false

		if not g_currentMission.missionInfo.isNewSPCareer and startScore ~= nil and currentScore == startScore then
			ignoreAchievement = true
		end

		if not ignoreAchievement then
			currentAchievement.score = currentScore

			if currentAchievement.targetScore <= currentAchievement.score then
				currentAchievement.unlocked = true

				unlockAchievement(tonumber(currentAchievement.id))

				if not hasNativeAchievementGUI() then
					self.messageCenter:publish(MessageType.ACHIEVEMENT_UNLOCKED, currentAchievement.name, currentAchievement.description, currentAchievement.imageFilename, currentAchievement.imageUVs)
				end

				self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
			end
		end
	end
end

function AchievementManager:update(dt)
	if not areAchievementsAvailable() or g_isPresentationVersion then
		return
	end

	if getHaveAchievementsChanged() then
		self.achievementsValid = false
	end

	if not self.achievementsValid then
		self:loadAchievementsState()
	end

	if g_currentMission ~= nil and g_currentMission.gameStarted and g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and not g_currentMission.missionDynamicInfo.isMultiplayer then
		self:updateAchievements(dt)
	end
end

function AchievementManager:updateAchievements(dt)
	self.achievementTimer = self.achievementTimer + dt

	if self.achievementTimeInterval <= self.achievementTimer then
		local farm = g_farmManager:getFarmById(g_currentMission:getFarmId())

		if farm == nil then
			return
		end

		local stats = farm.stats

		self:handleStandardScoreAchievement("PlayTime10", math.floor(stats:getTotalValue("playTime") / 60 + 0.0001), self.startPlayTime)
		self:handleStandardScoreAchievement("Money10Million", farm.money, self.startMoney)

		local contractCount = stats:getTotalValue("fieldJobMissionCount") + stats:getTotalValue("transportMissionCount")

		self:handleStandardScoreAchievement("Mission1", contractCount, self.startFieldJobMissionCount)
		self:handleStandardScoreAchievement("Mission50", contractCount, self.startFieldJobMissionCount)
		self:handleStandardScoreAchievement("Mission100", contractCount, self.startFieldJobMissionCount)

		local cultivatedHectares = stats:getTotalValue("cultivatedHectares")

		self:handleStandardScoreAchievement("Cultivate1", cultivatedHectares, self.startCultivatedHectares)
		self:handleStandardScoreAchievement("Cultivate10", cultivatedHectares, self.startCultivatedHectares)
		self:handleStandardScoreAchievement("Cultivate100", cultivatedHectares, self.startCultivatedHectares)

		local sownHectares = stats:getTotalValue("sownHectares")

		self:handleStandardScoreAchievement("Sow1", sownHectares, self.startSownHectares)
		self:handleStandardScoreAchievement("Sow10", sownHectares, self.startSownHectares)
		self:handleStandardScoreAchievement("Sow100", sownHectares, self.startSownHectares)

		local fertilizedHectares = stats:getTotalValue("fertilizedHectares")

		self:handleStandardScoreAchievement("Fertilize1", fertilizedHectares, self.startFertilizedHectares)
		self:handleStandardScoreAchievement("Fertilize10", fertilizedHectares, self.startFertilizedHectares)
		self:handleStandardScoreAchievement("Fertilize100", fertilizedHectares, self.startFertilizedHectares)

		local threshedHectares = stats:getTotalValue("threshedHectares")

		self:handleStandardScoreAchievement("ThreshedHectares1", threshedHectares, self.startThreshedHectares)
		self:handleStandardScoreAchievement("ThreshedHectares10", threshedHectares, self.startThreshedHectares)
		self:handleStandardScoreAchievement("ThreshedHectares100", threshedHectares, self.startThreshedHectares)
		self:handleStandardScoreAchievement("FirstCutTree", stats:getTotalValue("cutTreeCount"), self.startCutTreeCount)
		self:handleStandardScoreAchievement("CutTrees25", stats:getTotalValue("cutTreeCount"), self.startCutTreeCount)
		self:handleStandardScoreAchievement("BreedCows", stats:getTotalValue("breedCowsCount"), self.startBreedCowsCount)
		self:handleStandardScoreAchievement("BreedSheep", stats:getTotalValue("breedSheepCount"), self.startBreedSheepCount)
		self:handleStandardScoreAchievement("BreedPigs", stats:getTotalValue("breedPigsCount"), self.startBreedPigsCount)
		self:handleStandardScoreAchievement("BreedChicken", stats:getTotalValue("breedChickenCount"), self.startBreedChickenCount)

		self.achievementTimer = 0
	end
end
