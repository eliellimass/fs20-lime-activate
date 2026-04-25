FSBaseMission = {
	USER_STATE_LOADING = 1,
	USER_STATE_SYNCHRONIZING = 2,
	USER_STATE_CONNECTED = 3,
	USER_STATE_INGAME = 4,
	RADIO_OFF = 1,
	RADIO_VEHICLE_ONLY = 2,
	RADIO_ALWAYS = 3,
	CONNECTION_LOST_DEFAULT = 0,
	CONNECTION_LOST_KICKED = 1,
	CONNECTION_LOST_BANNED = 2,
	LIMITED_OBJECT_TYPE_BALE = 1,
	INGAME_NOTIFICATION_OK = {
		0.0976,
		0.624,
		0,
		1
	},
	INGAME_NOTIFICATION_INFO = {
		1,
		1,
		1,
		1
	},
	INGAME_NOTIFICATION_GREATDEMAND = {
		1,
		1,
		1,
		1
	},
	INGAME_NOTIFICATION_CRITICAL = {
		0.9301,
		0.2874,
		0.013,
		1
	},
	DEBUG_SHOW_FIELDSTATUS = false,
	DEBUG_SHOW_FIELDSTATUS_SIZE = 5
}
local l_engineState = true
local l_engineStateTimer = math.random(900000, 1200000)

if getEngineState ~= nil then
	l_engineState = getEngineState()
	getEngineState = nil
end

local function onEngineStateCallback()
	openWebFile("fs2019Purchase.php?type=2", "")
end

source("dataS/scripts/events/SavegameSettingsEvent.lua")
source("dataS/scripts/events/BaseMissionFinishedLoadingEvent.lua")
source("dataS/scripts/events/BaseMissionReadyEvent.lua")
source("dataS/scripts/events/SetDensityMapEvent.lua")
source("dataS/scripts/events/SetSplitShapesEvent.lua")
source("dataS/scripts/events/UpdateSplitShapesEvent.lua")
source("dataS/scripts/events/ConnectionRequestEvent.lua")
source("dataS/scripts/events/ConnectionRequestAnswerEvent.lua")
source("dataS/scripts/events/ChangeLoanEvent.lua")
source("dataS/scripts/events/MeshEvent.lua")
source("dataS/scripts/events/GamePauseEvent.lua")
source("dataS/scripts/events/GamePauseRequestEvent.lua")
source("dataS/scripts/events/PlayerPermissionsEvent.lua")
source("dataS/scripts/events/FinanceStatsEvent.lua")

local FSBaseMission_mt = Class(FSBaseMission, BaseMission)

function FSBaseMission:new(baseDirectory, customMt, missionCollaborators)
	local self = FSBaseMission:superClass():new(baseDirectory, customMt or FSBaseMission_mt, missionCollaborators)
	self.shopController = missionCollaborators.shopController
	self.inGameMenu = missionCollaborators.inGameMenu
	self.shopMenu = missionCollaborators.shopMenu
	self.animalController = missionCollaborators.animalController
	self.placementController = missionCollaborators.placementController
	self.landscapingController = missionCollaborators.landscapingController

	self.inGameMenu:setClient(self.client)
	self.inGameMenu:setServer(self.server)
	self.shopMenu:setClient(self.client)
	self.shopMenu:setServer(self.server)
	self.inGameMenu:setBanStorage(missionCollaborators.banStorage)
	self.placementController:setCurrentMission(self)
	self.placementController:setClient(self.client)
	self.landscapingController:setClient(self.client)

	self.trainSystems = {}
	self.objectsToCallOnMapFinished = {}

	self:registerToLoadOnMapFinished(self.inGameMenu)
	self:registerToLoadOnMapFinished(self.shopMenu)

	self.mapDensityMapRevision = 1
	self.mapTerrainLodTextureRevision = 1
	self.mapSplitShapesRevision = 1
	self.mapTipCollisionRevision = 1
	self.mapPlacementCollisionRevision = 1
	self.fruits = {}
	self.fruitsList = {}
	self.fieldCropsUpdaters = {}
	self.fieldCropsUpdatersCellSize = 16
	self.weedUpdater = nil
	self.densityMapSyncerCellSize = 32
	self.fieldCropsAllowGrowing = true
	self.cultivatorValue = 1
	self.plowValue = 2
	self.sowingValue = 3
	self.sowingWidthValue = 4
	self.grassValue = 5
	self.firstSowableValue = 1
	self.lastSowableValue = 2
	self.firstSowingValue = 3
	self.lastSowingValue = 5
	self.terrainDetailTypeFirstChannel = 0
	self.terrainDetailTypeNumChannels = 3
	local useSprayDiffuseMaps = g_platformSettingsManager:getSetting("useSprayDiffuseMaps", true)
	local useTerrainDetailAngle = g_platformSettingsManager:getSetting("useTerrainDetailAngle", true)
	local useMultipleSprayLevels = g_platformSettingsManager:getSetting("useMultipleSprayLevels", true)
	local usePlowCounter = g_platformSettingsManager:getSetting("usePlowCounter", true)
	local useLimeCounter = g_platformSettingsManager:getSetting("useLimeCounter", true)
	local currentBit = 3
	self.sprayFirstChannel = currentBit
	self.sprayNumChannels = useSprayDiffuseMaps and 3 or 1
	self.sprayMaxValue = 2^self.sprayNumChannels - 1
	currentBit = currentBit + self.sprayNumChannels
	self.terrainDetailAngleFirstChannel = currentBit
	self.terrainDetailAngleNumChannels = useTerrainDetailAngle and 2 or 0
	self.terrainDetailAngleMaxValue = 2^self.terrainDetailAngleNumChannels - 1
	currentBit = currentBit + self.terrainDetailAngleNumChannels
	self.sprayLevelFirstChannel = currentBit
	self.sprayLevelNumChannels = useMultipleSprayLevels and 2 or 1
	self.sprayLevelMaxValue = g_platformSettingsManager:getSetting("sprayLevelMaxValue", 2)

	if usePlowCounter then
		currentBit = currentBit + self.sprayLevelNumChannels
	end

	self.plowCounterFirstChannel = currentBit
	self.plowCounterNumChannels = usePlowCounter and 1 or 0
	self.plowCounterMaxValue = 2^self.plowCounterNumChannels - 1

	if useLimeCounter then
		currentBit = currentBit + self.plowCounterNumChannels
	end

	self.limeCounterFirstChannel = currentBit
	self.limeCounterNumChannels = useLimeCounter and 1 or 0
	self.limeCounterMaxValue = 2^self.limeCounterNumChannels - 1
	self.densityMapModifiers = FSDensityMapModifier:new()
	self.densityHeightMapModifiers = DensityMapHeightModifier:new()
	self.chopperGroundLayerType = 5
	self.numFruitDensityMapChannels = 10
	self.terrainDetailHeightTypeFirstChannel = 0
	self.terrainDetailHeightTypeNumChannels = 5
	self.sendMoneyUserIndex = 1
	self.playerStartIsAbsolute = false
	self.playersToAccept = {}
	self.playersLoading = {}
	self.doSaveGameState = SavegameController.SAVE_STATE_NONE
	self.currentDeviceHasNoSpace = false
	self.dediEmptyPaused = false
	self.userSigninPaused = false
	self.isSynchronizingWithPlayers = false
	self.playersSynchronizing = {}
	self.userManager = UserManager:new(self:getIsServer())
	self.mesh = {}
	self.meshActive = false
	self.meshEnabled = false
	self.playerUserId = -1
	self.blockedIps = {}
	self.clientUserId = nil
	self.terrainSize = 1
	self.terrainDetailMapSize = 1
	self.fruitMapSize = 1
	self.dynamicFoliageLayers = {}
	self.terrainDetailId = 0
	self.mapsSplitShapeFileIds = {}
	self.isMasterUser = false
	self.connectionWasClosed = false
	self.connectionWasAccepted = false
	self.cameraPaths = {}
	self.cameraPathIsPlaying = false

	if g_isDevelopmentVersion then
		-- Nothing
	end

	self.cullingWorldXZOffset = 0
	self.cullingWorldMinY = -100
	self.cullingWorldMaxY = 500
	self.densityMapPercentageFraction = 0.7
	self.splitShapesPercentageFraction = 0.2
	self.restPercentageFraction = 1 - self.densityMapPercentageFraction - self.splitShapesPercentageFraction
	self.groundValueIds = {}
	self.husbandries = {}
	self.doghouses = {}
	self.tireTrackSystem = nil
	self.placeables = {}
	self.placeablesToDelete = {}
	self.placeablesDeleteTestTime = 0
	self.liquidManureTriggers = {}
	self.liquidManureTriggerMapping = {}
	self.manureHeaps = {}
	self.adBanners = {}
	self.limitedObjects = {
		[FSBaseMission.LIMITED_OBJECT_TYPE_BALE] = {
			maxNumObjects = 200,
			objects = {}
		}
	}
	self.vehicleChangeListeners = {}
	self.tourVehicles = {}
	self.masterUsers = {}
	self.masterUserCount = 0
	self.connectedToDedicatedServer = false

	if g_dedicatedServerInfo ~= nil then
		self.gameStatsInterval = g_dedicatedServerInfo.gameStatsInterval
	else
		self.gameStatsInterval = 60000
	end

	self.gameStatsTime = 0
	self.wasNetworkError = false
	self.eventRadioToggle = ""
	self.radioEvents = {}
	self.moneyChanges = {}

	return self
end

function FSBaseMission:initialize()
	FSBaseMission:superClass().initialize(self)
	g_treePlantManager:initialize()
	MoneyType.reset()

	self.foliageBendingSystem = nil

	if g_platformSettingsManager:getSetting("foliageBending", true) then
		self.foliageBendingSystem = FoliageBendingSystem:new()
	end

	self.accessHandler = AccessHandler:new()
	self.storageSystem = StorageSystem:new(self.accessHandler)

	self:subscribeMessages()
	self.inGameMenu:setInGameMap(self.hud:getIngameMap())
	self.inGameMenu:setHUD(self.hud)
	self.shopMenu:setHUD(self.hud)
	self.placementController:setHUD(self.hud)
	self.landscapingController:setHUD(self.hud)
end

function FSBaseMission:delete()
	self.isExitingGame = true

	if self.missionDynamicInfo.isMultiplayer then
		meshNetworkEnd()
	end

	self:pauseRadio()

	if self.receivingDensityMapEvent ~= nil then
		self.receivingDensityMapEvent:delete()

		self.receivingDensityMapEvent = nil
	end

	if self.receivingSplitShapesEvent ~= nil then
		self.receivingSplitShapesEvent:delete()

		self.receivingSplitShapesEvent = nil
	end

	if self.weedUpdater ~= nil then
		delete(self.weedUpdater)

		self.weedUpdater = nil
	end

	if self.densityMapSyncer ~= nil then
		delete(self.densityMapSyncer)
	end

	destroyLowResCollisionHandler()
	self.accessHandler:delete()
	self.bans:delete()
	g_foliagePainter:unloadMapData()
	g_wildlifeSpawnerManager:unloadMapData()
	g_farmManager:unloadMapData()
	g_helperManager:unloadMapData()
	g_npcManager:unloadMapData()
	g_farmlandManager:unloadMapData()
	g_missionManager:unloadMapData()
	g_fieldManager:unloadMapData()
	g_gameplayHintManager:unloadMapData()
	g_sprayTypeManager:unloadMapData()
	g_connectionHoseManager:unloadMapData()
	g_densityMapHeightManager:unloadMapData()
	g_vehicleTypeManager:unloadMapData()
	g_placeableTypeManager:unloadMapData()
	g_specializationManager:unloadMapData()
	g_treePlantManager:unloadMapData()
	g_materialManager:unloadMapData()
	g_particleSystemManager:unloadMapData()
	g_cutterEffectManager:unloadMapData()
	g_effectManager:unloadMapData()
	g_animationManager:unloadMapData()
	g_ambientSoundManager:unloadMapData()
	g_tensionBeltManager:unloadMapData()
	g_groundTypeManager:unloadMapData()
	g_weatherTypeManager:unloadMapData()
	g_gui:unloadMapData()
	FSBaseMission:superClass().delete(self)
	self.inGameMenu:reset()
	self.shopMenu:reset()

	for placeable in pairs(self.placeablesToDelete) do
		placeable:delete()
	end

	self.placeablesToDelete = {}

	for _, updater in pairs(self.fieldCropsUpdaters) do
		delete(updater.updater)

		updater.updater = nil
	end

	for i = #self.adBanners, 1, -1 do
		local adBanner = self.adBanners[i]

		adBanner:delete()
	end

	g_fillTypeManager:unloadMapData()
	g_fruitTypeManager:unloadMapData()
	g_baleTypeManager:unloadMapData()
	g_animalManager:unloadMapData()
	g_animalFoodManager:unloadMapData()
	g_animalNameManager:unloadMapData()
	g_helpLineManager:unloadMapData()
	g_storeManager:unloadMapData()
	g_workAreaTypeManager:unloadMapData()
	g_configurationManager:unloadMapData()
	g_toolTypeManager:unloadMapData()
	g_splitTypeManager:unloadMapData()
	g_brandManager:unloadMapData()

	if self.tireTrackSystem ~= nil then
		self.tireTrackSystem:delete()
	end

	if self.foliageBendingSystem ~= nil then
		self.foliageBendingSystem:delete()
	end

	if self.economyManager ~= nil then
		self.economyManager:delete()
	end

	if g_soundPlayer ~= nil then
		g_soundPlayer:removeEventListener(self)

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			g_soundPlayer:setStreamingAccessOwner(nil)
		end
	end

	removeConsoleCommand("gsCheatMoney")
	removeConsoleCommand("gsExportStoreItems")
	removeConsoleCommand("gsStartGreatDemand")
	removeConsoleCommand("gsCheatSilo")
	removeConsoleCommand("gsFillVehicle")
	removeConsoleCommand("gsFillUnitAdd")
	removeConsoleCommand("gsSetFuel")
	removeConsoleCommand("gsSetOperatingTime")
	removeConsoleCommand("gsAddBale")
	removeConsoleCommand("gsAddPallet")
	removeConsoleCommand("gsShowTipCollisions")
	removeConsoleCommand("gsShowPlacementCollisions")
	removeConsoleCommand("gsUpdateTipCollisions")
	removeConsoleCommand("gsShowVehicleDistance")
	removeConsoleCommand("gsSetDirtScale")
	removeConsoleCommand("gsReloadVehicle")
	removeConsoleCommand("gsTeleport")
	removeConsoleCommand("gsToggleDebugFieldStatus")
	removeConsoleCommand("gsSaveDediXMLStatsFile")
	removeConsoleCommand("gsSaveGame")
	removeConsoleCommand("gsLoadAllVehicles")
	removeConsoleCommand("gsLoadTree")
	removeConsoleCommand("gsTipFillType")
	removeConsoleCommand("gsClearTipArea")
	removeConsoleCommand("gsAddWearAmount")
	removeConsoleCommand("gsAddDirtAmount")
	removeConsoleCommand("gsSetTemperature")
	removeConsoleCommand("gsActivateCameraPath")
	removeConsoleCommand("gsListHusbandries")
	removeConsoleCommand("gsAnimalAdd")
	removeConsoleCommand("gsAnimalRemove")

	for _, v in pairs(self.cameraPaths) do
		v:delete()
	end

	if self.missionSuccessSound ~= nil then
		delete(self.missionSuccessSound)
	end
end

function FSBaseMission:load()
	self:startLoadingTask()

	if g_addCheatCommands then
		addConsoleCommand("gsShowVehicleDistance", "Shows the distance between vehicle and cam", "consoleCommandShowVehicleDistance", self)
	end

	if self:getIsServer() then
		if g_addCheatCommands then
			if not self.missionDynamicInfo.isMultiplayer then
				addConsoleCommand("gsReloadVehicle", "Reloads a whole vehicle", "consoleCommandReloadVehicle", self)
			end

			addConsoleCommand("gsShowTipCollisions", "Shows the collisions for tipping on the ground", "consoleCommandShowTipCollisions", self)
			addConsoleCommand("gsShowPlacementCollisions", "Shows the collisions for placement and terraforming", "consoleCommandShowPlacementCollisions", self)
			addConsoleCommand("gsAddBale", "Adds a bale", "consoleCommandAddBale", self)
			addConsoleCommand("gsAddPallet", "Adds a pallet", "consoleCommandAddPallet", self)
			addConsoleCommand("gsSetFuel", "Sets the vehicle fuel level", "consoleCommandSetFuel", self)
			addConsoleCommand("gsSetTemperature", "Sets the vehicle motor temperature", "consoleCommandSetMotorTemperature", self)
			addConsoleCommand("gsFillVehicle", "Fills the vehicle with given filltype", "consoleCommandFillVehicle", self)
			addConsoleCommand("gsFillUnitAdd", "Changes a fillUnit with given filllevel and filltype", "consoleCommandFillUnitAdd", self)
			addConsoleCommand("gsSetOperatingTime", "Sets the vehicle operating time", "consoleCommandSetOperatingTime", self)
			addConsoleCommand("gsAddDirtAmount", "Adds a given amount to current dirt amount", "consoleCommandAddDirtAmount", self)
			addConsoleCommand("gsAddWearAmount", "Adds a given amount to current wear amount", "consoleCommandAddWearAmount", self)
			addConsoleCommand("gsCheatSilo", "Add silo amount", "consoleCommandCheatSilo", self)
			addConsoleCommand("gsLoadAllVehicles", "Load all vehicles", "consoleCommandLoadAllVehicles", self)
			addConsoleCommand("gsLoadTree", "Load a tree", "consoleCommandLoadTree", self)
			addConsoleCommand("gsTipFillType", "Tips a fillType", "consoleCommandTipFillType", self)
			addConsoleCommand("gsClearTipArea", "Clears tip area", "consoleCommandClearTipArea", self)
		end

		if g_addTestCommands then
			addConsoleCommand("gsExportStoreItems", "Exports storeItem data", "consoleCommandExportStoreItems", self)
			addConsoleCommand("gsStartGreatDemand", "Starts a great demand", "consoleStartGreatDemand", self)
			addConsoleCommand("gsUpdateTipCollisions", "Updates the collisions for tipping on the ground around the current camera", "consoleCommandUpdateTipCollisions", self)
			addConsoleCommand("gsTeleport", "Teleports to given field or x/z-position", "consoleCommandTeleport", self)
			addConsoleCommand("gsToggleDebugFieldStatus", "Shows field status", "consoleCommandToggleDebugFieldStatus", self)
			addConsoleCommand("gsSaveDediXMLStatsFile", "Saves dedi XML stats file", "consoleCommandSaveDediXMLStatsFile", self)
			addConsoleCommand("gsSaveGame", "Saves the current savegame", "consoleCommandSaveGame", self)
		end
	end

	if g_isDevelopmentVersion then
		addConsoleCommand("gsActivateCameraPath", "Activate camera path", "consoleActivateCameraPath", self)
		addConsoleCommand("gsListHusbandries", "List all husbandries.", "consoleCommandListHusbandries", self)
		addConsoleCommand("gsAnimalAdd", "Adds an animal", "consoleCommandAddAnimal", self)
		addConsoleCommand("gsAnimalRemove", "Removes an animal", "consoleCommandRemoveAnimal", self)
	end

	self.economyManager = EconomyManager:new()

	g_gui:setEconomyManager(self.economyManager)
	FSBaseMission:superClass().load(self)
	self.inGameMenu:setTerrainSize(self.terrainSize)

	self.missionSuccessSound = createSample("missionSuccessSound")

	loadSample(self.missionSuccessSound, "data/sounds/ui/uiSuccess.wav", false)
	self:setHarvestScaleRatio(unpack(g_platformSettingsManager:getSetting("harvestScaleRation", {
		0.5,
		0.15,
		0.15,
		0.2
	})))
	self:finishLoadingTask()
end

function FSBaseMission:setHarvestScaleRatio(sprayRatio, plowRatio, limeRatio, weedRatio)
	self.harvestSprayScaleRatio = sprayRatio
	self.harvestPlowScaleRatio = plowRatio
	self.harvestLimeScaleRatio = limeRatio
	self.harvestWeedScaleRatio = weedRatio
end

function FSBaseMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor)
	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local multiplier = 1
	multiplier = multiplier + self.harvestSprayScaleRatio * sprayFactor
	multiplier = multiplier + self.harvestPlowScaleRatio * plowFactor
	multiplier = multiplier + self.harvestLimeScaleRatio * limeFactor
	multiplier = multiplier + self.harvestWeedScaleRatio * weedFactor

	return multiplier
end

function FSBaseMission:onStartMission()
	FSBaseMission:superClass().onStartMission(self)

	if g_client ~= nil then
		if self:getIsServer() then
			local connection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID]
			local user = self.userManager:getUserByConnection(connection)
			local farm = g_farmManager:getFarmByUserId(user:getId())
			local farmId = FarmManager.SPECTATOR_FARM_ID

			if farm ~= nil then
				farmId = farm.farmId
			end

			self:createPlayer(connection, true, self.missionInfo.playerStyle, farmId, user:getId())
			user:setState(FSBaseMission.USER_STATE_INGAME)
		else
			g_client:getServerConnection():sendEvent(ClientStartMissionEvent:new())
		end

		if g_dedicatedServerInfo == nil and (not GS_IS_MOBILE_VERSION or not self.missionInfo.isNewSPCareer) then
			local spawnPoint = g_farmManager:getSpawnPoint(self.player.farmId)

			if not self.missionInfo.isValid then
				spawnPoint = g_mission00StartPoint
			end

			if not self.isTutorialMission and spawnPoint ~= nil then
				local x, y, z = getWorldTranslation(spawnPoint)
				local dx, _, dz = localDirectionToWorld(spawnPoint, 0, 0, -1)
				local ry = MathUtil.getYRotationFromDirection(dx, dz)
				y = math.max(y, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.2)

				self.player:moveTo(x, y, z, true, false)
				self.player:setRotation(0, ry)
			else
				self.player:moveTo(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerStartIsAbsolute, false)
				self.player:setRotation(self.playerRotX, self.playerRotY)
			end

			self.player:onEnter(true)
			self.hud:setIsControllingPlayer(true)
			self.guiTopDownCamera:setControlledPlayer(self.player)
		end

		if not g_gameSettings:getValue("radioVehicleOnly") then
			self:playRadio()
		end

		self:setRadioVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
		self:setVehicleVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
		self:setEnvironmentVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
		self:setGUIVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
	end

	if self.missionInfo ~= nil then
		g_logManager:info("Savegame Setting 'dirtInterval': %d", self.missionInfo.dirtInterval)
		g_logManager:info("Savegame Setting 'plantGrowthRate': %d", self.missionInfo.plantGrowthRate)
		g_logManager:info("Savegame Setting 'fuelUsageLow': %s", self.missionInfo.fuelUsageLow)
		g_logManager:info("Savegame Setting 'plowingRequiredEnabled': %s", self.missionInfo.plowingRequiredEnabled)
		g_logManager:info("Savegame Setting 'weedsEnabled': %s", self.missionInfo.weedsEnabled)
		g_logManager:info("Savegame Setting 'limeRequired': %s", self.missionInfo.limeRequired)
	end

	self:updateGameStatsXML()

	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(g_gameSettings:getValue("showHelpIcons"))
	end

	self:notifyPlayerFarmChanged(self.player)

	if GS_IS_MOBILE_VERSION and self.missionInfo.isNewSPCareer and #self.enterables > 0 then
		self:requestToEnterVehicle(self.enterables[1])
	end

	self.meshEnabled = true

	self:configureMesh()
end

function FSBaseMission:createPlayer(connection, isOwner, playerStyle, farmId, userId)
	local player = Player:new(g_server ~= nil, true)
	local playerDesc = g_playerModelManager:getPlayerModelByIndex(playerStyle.selectedModelIndex)
	player.farmId = farmId
	player.userId = userId

	player:load(playerDesc.xmlFilename, playerStyle, connection, isOwner)
	player:updateHandTools()
	player:register(false)
end

function FSBaseMission:getClientPosition()
	return getWorldTranslation(getCamera())
end

function FSBaseMission:setLoadingScreen(loadingScreen)
	self.loadingScreen = loadingScreen
end

function FSBaseMission:onConnectionOpened(connection)
end

function FSBaseMission:onConnectionAccepted(connection)
	self.connectionWasAccepted = true

	if self.loadingScreen ~= nil then
		self.loadingScreen:onWaitingForAccept()
	end

	g_client:getServerConnection():sendEvent(ConnectionRequestEvent:new(self.missionInfo.playerStyle, g_gameSettings:getValue("mpLanguage"), self.missionDynamicInfo.password, GS_PLATFORM_TYPE, getUserId(), getP2PNodeId()), nil, true)
end

function FSBaseMission:onConnectionRequest(connection, playerStyle, languageIndex, password, platformIndex, platformUserId, platformNodeId, uniqueUserId)
	if platformNodeId == nil then
		if connection.streamId ~= NetworkNode.LOCAL_STREAM_ID then
			local ip, port = streamGetIpAndPort(connection.streamId)
			platformNodeId = "ip://" .. tostring(ip) .. ":" .. tostring(port)
		else
			platformNodeId = ""
		end
	end

	if connection.streamId ~= NetworkNode.LOCAL_STREAM_ID then
		local userCount = self.userManager:getNumberOfUsers()

		if g_dedicatedServerInfo ~= nil then
			userCount = userCount - 1
		end

		if self.missionDynamicInfo.capacity <= userCount + table.getn(self.playersToAccept) then
			connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_FULL), nil, true)
			g_server:closeConnection(connection)

			return
		end

		if self.bans:isUserBanned(uniqueUserId) then
			connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED), nil, true)
			g_server:closeConnection(connection)

			return
		end

		local keyAlreadyInUse = self.userManager:getUserByUniqueId(uniqueUserId) ~= nil

		if not keyAlreadyInUse then
			for _, playerToAccept in ipairs(self.playersToAccept) do
				if playerToAccept.uniqueUserId == uniqueUserId then
					keyAlreadyInUse = true

					break
				end
			end
		end

		if keyAlreadyInUse then
			connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
			g_server:closeConnection(connection)

			return
		end

		if self.missionDynamicInfo.password == password then
			table.insert(self.playersToAccept, {
				connection = connection,
				playerStyle = playerStyle,
				language = languageIndex,
				platformUserId = platformUserId,
				platformNodeId = platformNodeId,
				platform = platformIndex,
				uniqueUserId = uniqueUserId
			})
		else
			connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD), nil, true)
			g_server:closeConnection(connection)

			return
		end
	else
		local userId = self.userManager:getNextUserId()

		assert(userId == 1)

		self.playerUserId = 1
		local user = User:new()

		user:setId(userId)
		user:setUniqueUserId(uniqueUserId)
		user:setNickname(playerStyle.playerName)
		user:setConnection(connection)
		user:setPlatformUserId(platformUserId)
		user:setPlatformNodeId(platformNodeId)
		user:setPlatformIndex(platformIndex)
		user:setIsMasterUser(true)
		user:setLanguageIndex(languageIndex)
		user:setConnectedTime(self.time)
		user:setState(FSBaseMission.USER_STATE_CONNECTED)
		user:setPlayerStyle(playerStyle)
		self.userManager:addUser(user)
		self.userManager:addMasterUserByConnection(connection)
		self:sendNumPlayersToMasterServer(1)
		connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_OK, self.missionInfo.difficulty, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServerInfo ~= nil, self.playerUserId), nil, true)
		table.insert(self.mesh, {
			connection = connection,
			platformNodeId = platformNodeId,
			platformUserId = platformUserId
		})
		self:configureMesh()
	end
end

function FSBaseMission:onConnectionDenyAccept(connection, isDenied, isAlwaysDenied)
	local playerToAccept = nil

	for i = 1, table.getn(self.playersToAccept) do
		local p = self.playersToAccept[i]

		if p.connection == connection then
			playerToAccept = p

			table.remove(self.playersToAccept, i)

			break
		end
	end

	if playerToAccept == nil then
		return
	end

	local playerNickname = ""
	local playerStyle = PlayerStyle:new()
	local user = nil
	local answer = ConnectionRequestAnswerEvent.ANSWER_OK

	if isAlwaysDenied then
		self.bans:addUser(playerToAccept.uniqueUserId, playerToAccept.playerStyle.playerName)

		answer = ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED
	elseif isDenied then
		answer = ConnectionRequestAnswerEvent.ANSWER_DENIED
	else
		local nickname = playerToAccept.playerStyle.playerName

		playerStyle:copySelection(playerToAccept.playerStyle)

		local languageIndex = playerToAccept.language
		local platformIndex = playerToAccept.platform
		local platformUserId = playerToAccept.platformUserId
		local platformNodeId = playerToAccept.platformNodeId
		local uniqueUserId = playerToAccept.uniqueUserId
		local newNickname = nickname
		local existingUser = self.userManager:getUserByNickname(nickname, true)
		local index = 1

		while existingUser ~= nil do
			newNickname = nickname .. " (" .. index .. ")"
			existingUser = self.userManager:getUserByNickname(newNickname, true)
			index = index + 1
		end

		local financeUpdateSendTime = self.time + math.floor(math.random() * 300 + 400)
		user = User:new()

		user:setId(self.userManager:getNextUserId())
		user:setUniqueUserId(uniqueUserId)
		user:setNickname(newNickname)
		user:setConnection(connection)
		user:setPlatformUserId(platformUserId)
		user:setPlatformNodeId(platformNodeId)
		user:setPlatformIndex(platformIndex)
		user:setLanguageIndex(languageIndex)
		user:setConnectedTime(self.time)
		user:setState(FSBaseMission.USER_STATE_LOADING)
		user:setPlayerStyle(playerStyle)
		user:setFinanceUpdateSendTime(financeUpdateSendTime)
		self.userManager:addUser(user)
		self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
		table.insert(self.mesh, {
			connection = connection,
			platformNodeId = platformNodeId,
			platformUserId = platformUserId
		})
		self:configureMesh()
		g_server:broadcastEvent(MeshEvent:new(self.mesh), nil, , , true)

		self.playersLoading[connection] = {
			connection = connection,
			user = user
		}
		playerStyle.playerName = newNickname
	end

	local playerFarm = g_farmManager:getFarmForUniqueUserId(playerToAccept.uniqueUserId)
	local userId = user ~= nil and user:getId() or nil

	connection:sendEvent(ConnectionRequestAnswerEvent:new(answer, self.missionInfo.difficulty, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServerInfo ~= nil, userId), nil, true)

	if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self:createPlayer(connection, false, playerStyle, playerFarm.farmId, user:getId())
	else
		g_server:closeConnection(connection)
	end
end

function FSBaseMission:onConnectionRequestAnswer(connection, answer, difficulty, economicDifficulty, timeScale, connectedToDedicatedServer, clientUserId)
	if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self.missionInfo.difficulty = difficulty
		self.missionInfo.economicDifficulty = economicDifficulty
		self.missionInfo.timeScale = timeScale
		self.connectedToDedicatedServer = connectedToDedicatedServer

		self:onConnectionRequestAccepted(connection)

		self.playerUserId = clientUserId
	else
		self.connectionWasClosed = true
		local text = g_i18n:getText("ui_serverDeniedAccess")

		if answer == ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD then
			text = g_i18n:getText("ui_wrongPassword")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED then
			text = g_i18n:getText("ui_banned")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_FULL then
			text = g_i18n:getText("ui_gameFull")
		elseif answer == ConnectionRequestAnswerEvent.ALREADY_IN_USE then
			text = g_i18n:getText("ui_connectionLostKeyInUse")
		end

		g_gui:showInfoDialog({
			text = text,
			callback = self.onConnectionRequestAnswerOk,
			target = self
		})
	end
end

function FSBaseMission:onConnectionRequestAnswerOk()
	OnInGameMenuMenu()

	if masterServerConnectFront ~= nil then
		g_multiplayerScreen:initJoinGameScreen()
		g_gui:showGui("ConnectToMasterServerScreen")

		if g_masterServerConnection.lastBackServerIndex >= 0 then
			g_connectToMasterServerScreen:connectToBack(g_masterServerConnection.lastBackServerIndex)
		else
			g_connectToMasterServerScreen:connectToFront()
		end
	end
end

function FSBaseMission:onConnectionRequestAccepted(connection)
	if self.loadingScreen ~= nil then
		self.loadingScreen:loadWithConnection(connection)
	end
end

function FSBaseMission:onConnectionRequestAcceptedLoad(connection)
	self.loadingConnection = connection

	simulatePhysics(false)
	self:load()
end

function FSBaseMission:onFinishedLoading()
	FSBaseMission:superClass().onFinishedLoading(self)

	local connection = self.loadingConnection

	if not self:getIsServer() then
		setCamera(g_defaultCamera)

		local x, y, z = self:getClientPosition()

		if self.loadingScreen ~= nil then
			self.loadingScreen:onWaitingForDynamicData()
		end

		self.pressStartPaused = true

		self:pauseGame()
		connection:sendEvent(BaseMissionFinishedLoadingEvent:new(x, y, z, getViewDistanceCoeff()), nil, true)
	else
		self.pressStartPaused = true

		self:pauseGame()

		if self.loadingScreen ~= nil then
			self.loadingScreen:onFinishedReceivingDynamicData()
		end
	end
end

function FSBaseMission:getAllowsGuiDisplay()
	if self.isSynchronizingWithPlayers and self.player ~= nil then
		return false
	end

	return true
end

function FSBaseMission:onConnectionFinishedLoading(connection, x, y, z, viewDistanceCoeff)
	assert(not connection:getIsLocal(), "No local connection allowed in BaseMission:onConnectionFinishedLoading")

	if self.playersSynchronizing[connection] ~= nil or self.playersLoading[connection] == nil then
		g_server:closeConnection(connection)

		return
	end

	addSplitShapeConnection(connection.streamId)

	if self.densityMapSyncer ~= nil then
		addDensityMapSyncerConnection(self.densityMapSyncer, connection.streamId)
	end

	addTerrainUpdateConnection(self.terrainRootNode, connection.streamId)
	connection:setIsReadyForEvents(true)

	local user = self.playersLoading[connection].user
	self.playersLoading[connection] = nil

	user:setState(FSBaseMission.USER_STATE_SYNCHRONIZING)

	local syncPlayer = {
		connection = connection,
		user = user
	}
	self.playersSynchronizing[connection] = syncPlayer

	if g_dedicatedServerInfo ~= nil then
		setFramerateLimiter(true, g_dedicatedServerMaxFrameLimit)

		self.dediEmptyPaused = false
	end

	self.isSynchronizingWithPlayers = true

	self:pauseGame()
	g_farmManager:playerJoinedGame(user:getUniqueUserId(), user:getId(), user, connection)
	g_server:sendEventIds(connection)
	g_server:sendObjectClassIds(connection)
	connection:sendEvent(OnCreateLoadedObjectEvent:new())
	g_server:sendObjects(connection, x, y, z, viewDistanceCoeff)
	connection:sendEvent(SavegameSettingsEvent:new())
	connection:sendEvent(EnvironmentTimeEvent:new(self.environment.currentDay, self.environment.dayTime))

	local weather = self.environment.weather

	connection:sendEvent(WeatherAddObjectEvent:new(weather.forecastItems, true))
	connection:sendEvent(WindObjectChangedEvent:new(weather.currentWindObjectIndex, true))
	connection:sendEvent(FogStateEvent:new(weather.fogUpdater.targetMieScale, weather.fogUpdater.lastMieScale, weather.fogUpdater.alpha, weather.fogUpdater.duration, weather.fog.nightFactor, weather.fog.dayFactor))

	local farm = g_farmManager:getFarmForUniqueUserId(user:getUniqueUserId())

	connection:sendEvent(FarmsInitialStateEvent:new(farm.farmId))

	if farm.farmId ~= 0 then
		connection:sendEvent(ChangeLoanEvent:new(farm.loan, farm.farmId))

		for i = 0, 4 do
			connection:sendEvent(FinanceStatsEvent:new(i, farm.farmId))
		end

		user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
	end

	connection:sendEvent(FarmlandInitialStateEvent:new())
	connection:sendEvent(GreatDemandsEvent:new(self.economyManager.greatDemands))

	if self.loadingScreen ~= nil then
		self.loadingScreen:setDynamicDataPercentage(self.restPercentageFraction)
	end

	g_server:broadcastEvent(UserEvent:new(self.userManager:getUsers(), {}, self.missionDynamicInfo.capacity, true))

	local splitShapesEvent = SetSplitShapesEvent:new()
	syncPlayer.splitShapesEvent = splitShapesEvent

	connection:sendEvent(splitShapesEvent, false)
end

function FSBaseMission:onSplitShapesProgress(connection, percentage)
	if percentage < 1 then
		if not self:getIsServer() and self.loadingScreen ~= nil then
			self.loadingScreen:setDynamicDataPercentage(percentage * self.splitShapesPercentageFraction + self.restPercentageFraction)
		end
	elseif self:getIsServer() then
		local syncPlayer = self.playersSynchronizing[connection]

		if syncPlayer ~= nil then
			if syncPlayer.splitShapesEvent ~= nil then
				syncPlayer.splitShapesEvent:delete()

				syncPlayer.splitShapesEvent = nil
			end

			connection:sendEvent(BaseMissionReadyEvent:new(), nil, true)
		end
	end
end

function FSBaseMission:onFinishedReceivingDynamicData(connection)
	if self.loadingScreen ~= nil then
		self.loadingScreen:onFinishedReceivingDynamicData()
		connection:sendEvent(BaseMissionReadyEvent:new(), nil, true)
	end
end

function FSBaseMission:onConnectionReady(connection)
	local syncPlayer = self.playersSynchronizing[connection]

	if syncPlayer == nil then
		g_server:closeConnection(connection)

		return
	end

	if syncPlayer.densityMapEvent ~= nil then
		syncPlayer.densityMapEvent:delete()

		syncPlayer.densityMapEvent = nil
	end

	if syncPlayer.splitShapesEvent ~= nil then
		syncPlayer.splitShapesEvent:delete()

		syncPlayer.splitShapesEvent = nil
	end

	connection:setIsReadyForObjects(true)

	local user = syncPlayer.user

	user:setState(FSBaseMission.USER_STATE_CONNECTED)

	self.playersSynchronizing[connection] = nil

	if next(self.playersSynchronizing) == nil then
		self.isSynchronizingWithPlayers = false

		self:tryUnpauseGame()
		self:showPauseDisplay(self.paused)
	end
end

function FSBaseMission:onConnectionClosed(connection)
	if not self:getIsServer() then
		if self.receivingDensityMapEvent ~= nil then
			self.receivingDensityMapEvent:delete()

			self.receivingDensityMapEvent = nil
		end

		if self.receivingSplitShapesEvent ~= nil then
			self.receivingSplitShapesEvent:delete()

			self.receivingSplitShapesEvent = nil
		end

		self:pauseGame()

		if not self.connectionWasClosed then
			self.isSynchronizingWithPlayers = false
			self.connectionWasClosed = true

			setPresenceMode(PresenceModes.PRESENCE_IDLE)

			if self.cleanServerShutDown == nil or not self.cleanServerShutDown then
				local text = g_i18n:getText("ui_failedToConnectToGame")

				if self.connectionWasAccepted then
					if self.connectionLostState == FSBaseMission.CONNECTION_LOST_KICKED then
						text = g_i18n:getText("ui_connectionLostKicked")
					elseif self.connectionLostState == FSBaseMission.CONNECTION_LOST_BANNED then
						text = g_i18n:getText("ui_connectionLostBanned")
					else
						text = g_i18n:getText("ui_connectionLost")
					end
				end

				if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "ChatDialog" then
					g_gui:showGui("")
				end

				g_gui:showInfoDialog({
					text = text,
					callback = OnInGameMenuMenu
				})
			end

			self.cleanServerShutDown = false
			self.connectionLostState = nil
		end
	else
		removeSplitShapeConnection(connection.streamId)

		if self.densityMapSyncer ~= nil then
			removeDensityMapSyncerConnection(self.densityMapSyncer, connection.streamId)
		end

		removeTerrainUpdateConnection(self.terrainRootNode, connection.streamId)

		for i = 1, table.getn(self.playersToAccept) do
			if self.playersToAccept[i].connection == connection then
				table.remove(self.playersToAccept, i)

				break
			end
		end

		self.playersLoading[connection] = nil
		local user = self.userManager:getUserByConnection(connection)

		if user ~= nil then
			g_farmManager:playerQuitGame(user:getId())
		end

		g_wildlifeSpawnerManager:onConnectionClosed()

		for _, vehicle in pairs(self.vehicles) do
			if vehicle.owner == connection then
				g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(vehicle))
			end
		end

		self.userManager:removeUserByConnection(connection)

		for i = 1, table.getn(self.mesh) do
			if self.mesh[i].connection == connection then
				table.remove(self.mesh, i)
				self:configureMesh()
				g_server:broadcastEvent(MeshEvent:new(self.mesh), nil, , , true)

				break
			end
		end

		local syncPlayer = self.playersSynchronizing[connection]

		if syncPlayer ~= nil then
			if syncPlayer.densityMapEvent ~= nil then
				syncPlayer.densityMapEvent:delete()
			end

			if syncPlayer.splitShapesEvent ~= nil then
				syncPlayer.splitShapesEvent:delete()
			end

			self.playersSynchronizing[connection] = nil

			if next(self.playersSynchronizing) == nil then
				self.isSynchronizingWithPlayers = false

				self:tryUnpauseGame()
				self:showPauseDisplay(self.paused)
			end
		end

		if self.connectionsToPlayer[connection] ~= nil then
			local player = self.connectionsToPlayer[connection]

			player:delete()

			self.connectionsToPlayer[connection] = nil
		end

		local userCount = self.userManager:getNumberOfUsers()

		self:sendNumPlayersToMasterServer(userCount)
		g_server:broadcastEvent(UserEvent:new({}, {
			user
		}, self.missionDynamicInfo.capacity, false))

		if userCount == 1 and g_dedicatedServerInfo ~= nil then
			setFramerateLimiter(true, g_dedicatedServerMinFrameLimit)

			if g_dedicatedServerInfo.pauseGameIfEmpty then
				self.dediEmptyPaused = true

				self:pauseGame()
			end
		end
	end
end

function FSBaseMission:cancelPlayersSynchronizing()
	for connection, _ in pairs(self.playersSynchronizing) do
		g_server:closeConnection(connection)
	end
end

function FSBaseMission:onConnectionsUpdateTick(dt)
	if self:getIsServer() then
		if table.getn(g_server.clients) > 0 then
			prepareSplitShapesServerWriteUpdateStream(dt)

			if startWriteSplitShapesServerEvents() then
				for streamId, connection in pairs(g_server.clientConnections) do
					if streamId ~= NetworkNode.LOCAL_STREAM_ID then
						connection:sendEvent(UpdateSplitShapesEvent:new())
					end
				end

				finishWriteSplitShapesServerEvents()
			end
		end

		self.sendMoneyUserIndex = self.sendMoneyUserIndex + 2

		if self.userManager:getNumberOfUsers() < self.sendMoneyUserIndex then
			self.sendMoneyUserIndex = 1
		end
	end
end

function FSBaseMission:onConnectionWriteUpdateStream(connection, maxPacketSize, networkDebug)
	if not connection:getIsServer() then
		local treePacketPercentage = 0.3
		local densityPacketPercentage = 0.2
		local terrainDeformPacketPercentage = 0.2
		local startSplitShapesOffset = nil

		if networkDebug then
			startSplitShapesOffset = streamGetWriteOffset(connection.streamId)

			streamWriteInt32(connection.streamId, 0)
		end

		local x, y, z = g_server:getClientPosition(connection.streamId)
		local viewCoeff = g_server:getClientClipDistCoeff(connection.streamId)
		local oldPacketSize = streamGetWriteOffset(connection.streamId)

		writeSplitShapesServerUpdateToStream(connection.streamId, connection.streamId, x, y, z, viewCoeff, maxPacketSize * treePacketPercentage)
		g_server:addPacketSize(NetworkNode.PACKET_SPLITSHAPES, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

		if networkDebug then
			local endSplitShapesOffset = streamGetWriteOffset(connection.streamId)

			streamSetWriteOffset(connection.streamId, startSplitShapesOffset)
			streamWriteInt32(connection.streamId, endSplitShapesOffset - (startSplitShapesOffset + 32))
			streamSetWriteOffset(connection.streamId, endSplitShapesOffset)
		end

		if self.densityMapSyncer ~= nil then
			local startDensityOffset = nil

			if networkDebug then
				startDensityOffset = streamGetWriteOffset(connection.streamId)

				streamWriteInt32(connection.streamId, 0)
			end

			local syncerMaxPacketSize = maxPacketSize * densityPacketPercentage
			local oldPacketSize = streamGetWriteOffset(connection.streamId)

			writeDensityMapSyncerServerUpdateToStream(self.densityMapSyncer, connection.streamId, connection.streamId, x, y, z, viewCoeff, syncerMaxPacketSize, connection.lastSeqSent)
			g_server:addPacketSize(NetworkNode.PACKET_DENSITY_MAPS, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

			if networkDebug then
				local endDensityOffset = streamGetWriteOffset(connection.streamId)

				streamSetWriteOffset(connection.streamId, startDensityOffset)
				streamWriteInt32(connection.streamId, endDensityOffset - (startDensityOffset + 32))
				streamSetWriteOffset(connection.streamId, endDensityOffset)
			end
		end

		local startTerrainOffset = nil

		if networkDebug then
			startTerrainOffset = streamGetWriteOffset(connection.streamId)

			streamWriteInt32(connection.streamId, 0)
		end

		local syncerMaxPacketSize = maxPacketSize * terrainDeformPacketPercentage
		local oldPacketSize = streamGetWriteOffset(connection.streamId)

		writeTerrainUpdateStream(self.terrainRootNode, connection.streamId, connection.streamId, syncerMaxPacketSize, x, y, z)
		g_server:addPacketSize(NetworkNode.PACKET_TERRAIN_DEFORM, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

		if networkDebug then
			local endTerrainOffset = streamGetWriteOffset(connection.streamId)

			streamSetWriteOffset(connection.streamId, startTerrainOffset)
			streamWriteInt32(connection.streamId, endTerrainOffset - (startTerrainOffset + 32))
			streamSetWriteOffset(connection.streamId, endTerrainOffset)
		end
	end
end

function FSBaseMission:onConnectionReadUpdateStream(connection, networkDebug)
	if connection:getIsServer() then
		local startOffset = 0
		local numBits = 0

		if networkDebug then
			startOffset = streamGetReadOffset(connection.streamId)
			numBits = streamReadInt32(connection.streamId)
		end

		readSplitShapesServerUpdateFromStream(connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)

		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "splitshape")
		end

		if self.densityMapSyncer ~= nil then
			local startOffset = 0
			local numBits = 0

			if networkDebug then
				startOffset = streamGetReadOffset(connection.streamId)
				numBits = streamReadInt32(connection.streamId)
			end

			readDensityMapSyncerServerUpdateFromStream(self.densityMapSyncer, connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)

			if networkDebug then
				g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "densitymapsyncer")
			end
		end

		local startOffset = 0
		local numBits = 0

		if networkDebug then
			startOffset = streamGetReadOffset(connection.streamId)
			numBits = streamReadInt32(connection.streamId)
		end

		readTerrainUpdateStream(self.terrainRootNode, connection.streamId)

		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "terrainmods")
		end
	end
end

function FSBaseMission:onFinishedClientsWriteUpdateStream()
end

function FSBaseMission:onConnectionPacketSent(connection, packetId)
end

function FSBaseMission:onConnectionPacketLost(connection, packetId)
	if not connection:getIsServer() and self.densityMapSyncer ~= nil then
		setDensityMapSyncerLostPacket(self.densityMapSyncer, connection.streamId, packetId)
	end
end

function FSBaseMission:onShutdownEvent(connection)
	if not self:getIsServer() then
		self.cleanServerShutDown = true

		setPresenceMode(PresenceModes.PRESENCE_IDLE)
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_serverWasShutdown"),
			callback = self.onShutdownEventOk,
			target = self
		})
	else
		local user = self.userManager:getUserByConnection(connection)

		self.userManager:removeUserByConnection(connection)

		for i = 1, table.getn(self.mesh) do
			if self.mesh[i].connection == connection then
				table.remove(self.mesh, i)
				self:configureMesh()
				g_server:broadcastEvent(MeshEvent:new(self.mesh), nil, , , true)

				break
			end
		end

		self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
		g_server:broadcastEvent(UserEvent:new({}, {
			user
		}, self.missionDynamicInfo.capacity, false))
	end
end

function FSBaseMission:onShutdownEventOk()
	OnInGameMenuMenu()
end

function FSBaseMission:onMasterServerConnectionFailed(reason)
	if self.isMissionStarted then
		g_gui:showGui("InGameMenu")
		self.inGameMenu:setMasterServerConnectionFailed(reason)
	else
		OnInGameMenuMenu(false, true)
	end
end

function FSBaseMission:getServerUserId()
	return 1
end

function FSBaseMission:getFarmId(connection)
	if self:getIsServer() then
		if self.player ~= nil and connection == nil then
			return self.player.farmId
		end

		if connection == nil then
			return nil
		end

		local player = self:getPlayerByConnection(connection)

		if player == nil then
			return nil
		end

		return player.farmId
	else
		if self.player == nil then
			return 0
		end

		return self.player.farmId
	end
end

function FSBaseMission:farmStats(farmId)
	if farmId == nil then
		farmId = self.player.farmId
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		print("Error: Farm not found for stats")

		return FarmStats:new()
	end

	return farm.stats
end

function FSBaseMission:getPlayerByConnection(connection)
	return self.connectionsToPlayer[connection]
end

function FSBaseMission:kickUser(user)
	assert(self:getIsServer())

	local connection = user:getConnection()

	connection:sendEvent(KickBanNotificationEvent:new(true))
	g_server:closeConnection(connection)
end

function FSBaseMission:banUser(user)
	assert(self:getIsServer())
	self.bans:addUser(user:getUniqueUserId(), user:getNickname())

	local connection = user:getConnection()

	connection:sendEvent(KickBanNotificationEvent:new(false))
	g_server:closeConnection(connection)
end

function FSBaseMission:addVehicle(vehicle)
	FSBaseMission:superClass().addVehicle(self, vehicle)

	if self.hud and not vehicle:isa(RailroadVehicle) then
		self:addVehicleHotspot(vehicle)
	end

	for _, listener in ipairs(self.vehicleChangeListeners) do
		listener:onVehiclesChanged(vehicle, true, false)
	end
end

function FSBaseMission:addVehicleHotspot(vehicle)
	local width, height = getNormalizedScreenValues(25, 25)
	local forcedMapHotspotType = vehicle.forcedMapHotspotType

	if forcedMapHotspotType == nil then
		local isCombine = SpecializationUtil.hasSpecialization(Combine, vehicle.specializations)
		local isTrailer = SpecializationUtil.hasSpecialization(Trailer, vehicle.specializations)
		local isPallet = vehicle.typeName == "pallet"
		local isDrivable = SpecializationUtil.hasSpecialization(Drivable, vehicle.specializations)
		local isTabbable = SpecializationUtil.hasSpecialization(Enterable, vehicle.specializations) and vehicle.spec_enterable.isTabbable
		local isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
		local showOnMap = vehicle:getShowOnMap()

		if isPallet or isRideable then
			return
		end

		if showOnMap == false then
			return
		end

		if not isCombine and not isTrailer and not isDrivable then
			forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_TOOL
		elseif isTrailer and not isDrivable then
			forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_TRAILER
		elseif isCombine then
			forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_COMBINE
		elseif not isCombine and (isTabbable or showOnMap) and isDrivable then
			forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_STEERABLE
		end
	end

	if forcedMapHotspotType ~= nil then
		local color, name = nil

		if forcedMapHotspotType == MapHotspot.CATEGORY_VEHICLE_TOOL then
			color = {
				0.9301,
				0.6404,
				0.0439,
				1
			}
			name = "Tool"
		elseif forcedMapHotspotType == MapHotspot.CATEGORY_VEHICLE_TRAILER then
			color = {
				0.0091,
				0.0931,
				0.5841,
				1
			}
			name = "Trailer"
		elseif forcedMapHotspotType == MapHotspot.CATEGORY_VEHICLE_COMBINE then
			color = {
				0.6514,
				0.0399,
				0.0399,
				1
			}
			name = "Combine"
		elseif forcedMapHotspotType == MapHotspot.CATEGORY_VEHICLE_STEERABLE then
			color = {
				0.2705,
				0.6514,
				0.0802,
				1
			}
			name = "Steerable"
		end

		local mapHotspot = MapHotspot:new(name, forcedMapHotspotType)

		mapHotspot:setIcon(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_CIRCLE, color, nil, )
		mapHotspot:setBackground(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_CIRCLE, nil, , )
		mapHotspot:setSize(width, height)
		mapHotspot:setIconScale(0.75)
		mapHotspot:setRenderLast(true)
		mapHotspot:setLinkedNode(vehicle.rootNode)
		mapHotspot:setOwnerFarmId(vehicle:getOwnerFarmId())
		mapHotspot:setShowName(false)
		vehicle:setMapHotspot(mapHotspot)
		self:addMapHotspot(mapHotspot)
	end
end

function FSBaseMission:removeVehicle(vehicle, callDelete)
	FSBaseMission:superClass().removeVehicle(self, vehicle, callDelete)

	local mapHotspot = vehicle:getMapHotspot()

	if mapHotspot ~= nil then
		self:removeMapHotspot(mapHotspot)
		mapHotspot:delete()
		vehicle:setMapHotspot(nil)
	end

	for _, listener in ipairs(self.vehicleChangeListeners) do
		listener:onVehiclesChanged(vehicle, false, self.isExitingGame)
	end
end

function FSBaseMission:addVehicleChangeListener(listener)
	if listener ~= nil then
		ListUtil.addElementToList(self.vehicleChangeListeners, listener)
	end
end

function FSBaseMission:removeVehicleChangeListener(listener)
	if listener ~= nil then
		ListUtil.removeElementFromList(self.vehicleChangeListeners, listener)
	end
end

function FSBaseMission:updateMenuAccessibleVehicles()
	local accessibleVehicles = {}

	if self.player ~= nil then
		for _, vehicle in ipairs(self.vehicles) do
			local hasAccess = self.accessHandler:canPlayerAccess(vehicle)
			local isProperty = vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED or vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED
			local isPallet = vehicle.typeName == "pallet"

			if hasAccess and vehicle.getSellPrice ~= nil and vehicle.price ~= nil and isProperty and not isPallet and not SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
				table.insert(accessibleVehicles, vehicle)
			end
		end
	end

	self.inGameMenu:setAccessibleVehicles(accessibleVehicles)
end

function FSBaseMission:addOwnedItem(item)
	FSBaseMission:superClass().addOwnedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setOwnedFarmItems(self.ownedItems, farmId)
end

function FSBaseMission:removeOwnedItem(item)
	FSBaseMission:superClass().removeOwnedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setOwnedFarmItems(self.ownedItems, farmId)
end

function FSBaseMission:addLeasedItem(item)
	FSBaseMission:superClass().addLeasedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setLeasedFarmItems(self.leasedVehicles, farmId)
end

function FSBaseMission:removeLeasedItem(item)
	FSBaseMission:superClass().removeLeasedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setLeasedFarmItems(self.leasedVehicles, farmId)
end

function FSBaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local loadingFileId = -1

	if self.missionInfo.mapsSplitShapeFileIds ~= nil then
		loadingFileId = Utils.getNoNil(self.missionInfo.mapsSplitShapeFileIds[table.getn(self.mapsSplitShapeFileIds) + 1], -1)
	end

	setSplitShapesLoadingFileId(loadingFileId)

	local splitShapeFileId = setSplitShapesNextFileId()

	table.insert(self.mapsSplitShapeFileIds, splitShapeFileId)
	FSBaseMission:superClass().loadMap(self, filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end

function FSBaseMission:registerToLoadOnMapFinished(object)
	table.insert(self.objectsToCallOnMapFinished, object)
end

function FSBaseMission:loadMapFinished(node, arguments, callAsyncCallback)
	local startedRepeat = startFrameRepeatMode()

	FSBaseMission:superClass().loadMapFinished(self, node, arguments, false)

	local filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	if node ~= 0 then
		local terrainNode = 0
		local numChildren = getNumOfChildren(node)

		for i = 0, numChildren - 1 do
			local t = getChildAt(node, i)

			if getHasClassId(t, ClassIds.TERRAIN_TRANSFORM_GROUP) then
				terrainNode = t

				break
			end
		end

		if terrainNode ~= 0 then
			self:initTerrain(terrainNode, filename)
		end
	end

	if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, node, asyncCallbackArguments)
	end

	if startedRepeat then
		endFrameRepeatMode()
	end

	for _, object in pairs(self.objectsToCallOnMapFinished) do
		object:onLoadMapFinished()
	end

	self.objectsToCallOnMapFinished = {}

	self.inGameMenu:setManureTriggers(self.manureHeaps, self.liquidManureTriggers)
	self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.hud:setConnectedUsers(self.userManager:getUsers())
end

function FSBaseMission:initTerrain(terrainId, filename)
	self.terrainRootNode = terrainId
	local terrainColMask = getCollisionMask(self.terrainRootNode)
	local newTerrainColMask = bitAND(terrainColMask, bitNOT(AIVehicleUtil.COLLISION_MASK))

	if terrainColMask ~= newTerrainColMask then
		setCollisionMask(self.terrainRootNode, newTerrainColMask)
	end

	self.terrainSize = getTerrainSize(self.terrainRootNode)

	self.inGameMenu:setTerrainSize(self.terrainSize)
	self.guiTopDownCamera:setTerrainRootNode(self.terrainRootNode)
	self.landscapingController:setTerrainRootNode(self.terrainRootNode)
	createLowResCollisionHandler(64, 64, 1, 1048543, 4, 1048543, 5)
	setLowResCollisionHandlerTerrainRootNode(g_currentMission.terrainRootNode)

	local x, y, z = getWorldTranslation(self.terrainRootNode)

	if math.abs(x) > 0.1 or math.abs(z) > 0.1 or y < 0 then
		print("Warning: the terrain node needs to be a x=0 and z=0 and y >= 0")
	end

	self.areaCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.02)
	self.areaRelativeCompressionParams = NetworkUtil.createWorldPositionCompressionParams(100, 50, 0.02)
	self.vehicleXZPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.005)
	self.vehicleYPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.005)
	self.vehicleXZPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.0001)
	self.vehicleYPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.0001)

	setSplitShapesWorldCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.005, 1700, 200, 0.005, self.terrainSize, 0.5 * self.terrainSize, 0.005)

	local worldSizeHalf = 0.5 * self.terrainSize + self.cullingWorldXZOffset
	local worldMinY = self.cullingWorldMinY
	local worldMaxY = self.cullingWorldMaxY

	setAudioCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)
	setLightCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		setShapeCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)
	else
		setShapeCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 64)
	end

	local foliageViewCoeff = getFoliageViewDistanceCoeff()
	local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(self.terrainRootNode)

	setTerrainLodBlendDynamicDistances(self.terrainRootNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)

	if self.foliageBendingSystem then
		self.foliageBendingSystem:setTerrainTransformGroup(self.terrainRootNode)
	end

	self.terrainDetailId = getTerrainDetailByName(self.terrainRootNode, "terrainDetail")

	if self.terrainDetailId ~= 0 then
		self.terrainDetailMapSize = getDensityMapSize(self.terrainDetailId)
	end

	self.fieldCropsUpdaters = {}

	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		local entry = {
			id = 0,
			preparingOutputId = 0,
			fruitTypeIndex = fruitType.index
		}
		local id = getTerrainDetailByName(self.terrainRootNode, fruitType.layerName)
		entry.id = id

		if fruitType.preparingOutputName ~= nil then
			entry.preparingOutputId = getTerrainDetailByName(self.terrainRootNode, fruitType.preparingOutputName)
		end

		if id ~= 0 then
			self.fruitMapSize = math.max(self.fruitMapSize, getDensityMapSize(entry.id))
			local mapName = getDensityMapFilename(id)
			mapName = Utils.getFilenameInfo(mapName)

			if self:getIsServer() and fruitType.weed == nil then
				if self.fieldCropsUpdaters[mapName] == nil then
					self.fieldCropsUpdaters[mapName] = {
						ids = {}
					}
				end

				local updater = self.fieldCropsUpdaters[mapName]
				updater.ids[fruitType.layerName] = id
			end
		end

		if id ~= 0 or entry.preparingOutputId ~= 0 then
			self.fruits[fruitType.index] = entry

			table.insert(self.fruitsList, entry)
		end
	end

	self.inGameMenu:setMissionFruitTypes(self.fruitsList)

	if self:getIsServer() then
		local weedType = g_fruitTypeManager:getWeedFruitType()

		if weedType ~= nil then
			local detailId = getTerrainDetailByName(self.terrainRootNode, weedType.layerName)
			local weed = weedType.weed
			self.weedUpdater = createTerrainDetailUpdater(weedType.layerName, detailId, weedType.startStateChannel, weedType.numStateChannels, 0, 0, weed.updateDelta, weed.availFirstChannel, weed.availNumChannels, weed.availMinValue, weed.growthStateTime)

			setUpdateMinMaxValue(self.weedUpdater, 0, weed.minValue, weed.maxValue)
		end

		for _, updater in pairs(self.fieldCropsUpdaters) do
			local constr = FieldCropsUpdaterConstructor:new(self.fieldCropsUpdatersCellSize)

			for name, id in pairs(updater.ids) do
				local fruitType = g_fruitTypeManager:getFruitTypeByName(name)
				local groundTypeChangedValue = self:getFruitTypeGroundTypeValue(fruitType.groundTypeChanged)

				constr:addCropType(id, fruitType.numGrowthStates, fruitType.growthStateTime, fruitType.resetsSpray, fruitType.groundTypeChangeGrowthState + 1, groundTypeChangedValue, fruitType.groundTypeChangeMask)
			end

			if self.terrainDetailId ~= 0 then
				constr:setGroundTerrainDetail(self.terrainDetailId, self.sprayFirstChannel, self.sprayNumChannels, self.terrainDetailTypeFirstChannel, self.terrainDetailTypeNumChannels)
			end

			updater.updater = constr:finalize("CropsUpdater")
		end
	end

	if self.missionDynamicInfo.isMultiplayer and self.densityMapSyncer == nil then
		self.densityMapSyncer = createDensityMapSyncer("DensityMapSyncer", self.terrainRootNode, self.densityMapSyncerCellSize)
	end

	if self.terrainDetailId ~= 0 then
		self.fieldCropsQuery = FieldCropsQuery:new(self.terrainDetailId)
	end

	if self.missionDynamicInfo.isMultiplayer then
		for _, fruit in pairs(self.fruits) do
			if fruit.id ~= 0 then
				addDensityMapSyncerDensityMap(self.densityMapSyncer, fruit.id)
			end

			if fruit.preparingOutputId ~= 0 then
				addDensityMapSyncerDensityMap(self.densityMapSyncer, fruit.preparingOutputId)
			end
		end

		if self.terrainDetailId ~= 0 then
			addDensityMapSyncerDensityMap(self.densityMapSyncer, self.terrainDetailId)
		end

		for _, id in pairs(self.dynamicFoliageLayers) do
			addDensityMapSyncerDensityMap(self.densityMapSyncer, id)
		end
	end

	self.terrainDetailHeightId = getTerrainDetailByName(self.terrainRootNode, "terrainDetailHeight")
	self.terrainDetailHeightMapSize = self.fruitMapSize

	if self.terrainDetailHeightId ~= 0 then
		self.terrainDetailHeightMapSize = getDensityMapSize(self.terrainDetailHeightId)
		local collisionMapFilename = filename .. "." .. DensityMapHeightManager.TIP_COL_FILENAME
		local placementMapFilename = filename .. "." .. DensityMapHeightManager.PLC_COL_FILENAME

		g_densityMapHeightManager:initialize(self:getIsServer(), collisionMapFilename, placementMapFilename)

		local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

		if terrainHeightUpdater ~= nil and self.missionDynamicInfo.isMultiplayer then
			addDensityMapSyncerDensityMap(self.densityMapSyncer, g_currentMission.terrainDetailHeightId)
		end
	end

	self:updateFoliageGrowthStateTime()
	self:updatePlantWithering()

	if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
		local dir = self.missionInfo.savegameDirectory

		for filename, updater in pairs(self.fieldCropsUpdaters) do
			loadCropsGrowthStateFromFile(updater.updater, dir .. "/" .. filename .. "_growthState.xml")
		end

		if self.weedUpdater ~= nil then
			loadTerrainDetailUpdaterStateFromFile(self.weedUpdater, dir .. "/weed_growthState.xml")
		end
	end

	g_groundTypeManager:initTerrain(self.terrainRootNode)
	FSDensityMapUtil.initTerrain(self.terrainDetailId)
	DensityMapHeightUtil.initTerrain(self.terrainDetailId)
	FieldUtil.initTerrain(self.terrainDetailId)
	g_foliagePainter:initTerrain(self.terrainRootNode)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.TERRAIN)
end

function FSBaseMission:getFruitTypeGroundTypeValue(groundType)
	if groundType == FruitTypeManager.GROUND_TYPE_CULTIVATOR then
		return self.cultivatorValue
	elseif groundType == FruitTypeManager.GROUND_TYPE_PLOW then
		return self.plowValue
	elseif groundType == FruitTypeManager.GROUND_TYPE_SOWING then
		return self.sowingValue
	elseif groundType == FruitTypeManager.GROUND_TYPE_SOWING_WIDTH then
		return self.sowingWidthValue
	elseif groundType == FruitTypeManager.GROUND_TYPE_GRASS then
		return self.grassValue
	end

	return 0
end

function FSBaseMission:addGroundValueId(fillType, id, firstChannel, numChannels, maxValue, groundAmountToFillLevel)
	self.groundValueIds[fillType] = {
		id = id,
		firstChannel = firstChannel,
		numChannels = numChannels,
		maxValue = maxValue,
		groundAmountToFillLevel = groundAmountToFillLevel
	}
end

function FSBaseMission:addOnCreateLoadedObject(object)
	if self.userManager:getNumberOfUsers() > 1 then
		print("Error: addOnCreateLoadedObject is only allowed during map loading when no client is connected")
		printCallstack()

		return
	end

	return FSBaseMission:superClass().addOnCreateLoadedObject(self, object)
end

function FSBaseMission:addTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = trainSystem
end

function FSBaseMission:removeTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = nil
end

function FSBaseMission:setTrainSystemTabbable(isTabbable)
	for trainSystem, _ in pairs(self.trainSystems) do
		trainSystem:setIsTrainTabbable(isTabbable)
	end
end

function FSBaseMission:addLimitedObject(objectType, object)
	if GS_IS_CONSOLE_VERSION then
		if self.limitedObjects[objectType].maxNumObjects > 0 then
			local numObjects = table.getn(self.limitedObjects[objectType])
			local i = 1

			while self.limitedObjects[objectType].maxNumObjects <= numObjects and i <= numObjects do
				local object_i = self.limitedObjects[i]

				if object_i:getAllowsAutoDelete() then
					table.remove(self.limitedObjects, i)
					object_i:delete()

					numObjects = numObjects - 1
				else
					i = i + 1
				end
			end
		end

		table.insert(self.limitedObjects[objectType].objects, object)
	end
end

function FSBaseMission:removeLimitedObject(objectType, object)
	if GS_IS_CONSOLE_VERSION then
		for i, object_i in pairs(self.limitedObjects[objectType].objects) do
			if object_i == object then
				table.remove(self.limitedObjects[objectType].objects, i)

				break
			end
		end
	end
end

function FSBaseMission:getCanAddLimitedObject(objectType)
	if not GS_IS_CONSOLE_VERSION then
		return true
	else
		return #self.limitedObjects[objectType].objects + 1 <= self.limitedObjects[objectType].maxNumObjects
	end
end

function FSBaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	FSBaseMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
	self.hud:mouseEvent(posX, posY, isDown, isUp, button)
end

function FSBaseMission:keyEvent(unicode, sym, modifier, isDown)
	FSBaseMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)

	if self.isRunning and not g_gui:getIsGuiVisible() and g_flightAndNoHUDKeysEnabled and sym == Input.KEY_o and isDown then
		self.hud:setIsVisible(not self.hud:getIsVisible())
	end

	if g_gui.currentGui ~= nil and g_flightAndNoHUDKeysEnabled and self.isRunning and sym == Input.KEY_o and isDown and g_gui.currentGui.target == g_shopConfigScreen then
		g_shopConfigScreen:toggleHUDVisible()
	end
end

function FSBaseMission:updatePauseInputContext()
	local hasPauseContext = self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_PAUSE or self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING
	local needPause = self.gameStarted and self.paused and (not g_gui:getIsGuiVisible() or self.isSynchronizingWithPlayers)
	local needUnpause = self.gameStarted and not self.paused

	if not self.isSynchronizingWithPlayers and self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
		self.inputManager:revertContext()
	end

	if needPause and not hasPauseContext then
		self.inputManager:setContext(BaseMission.INPUT_CONTEXT_PAUSE)
	elseif needUnpause and hasPauseContext then
		self.inputManager:revertContext()
	end

	if needPause and self.isSynchronizingWithPlayers and self.inputManager:getContextName() ~= BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
		self.inputManager:setContext(BaseMission.INPUT_CONTEXT_SYNCHRONIZING, true)
	end
end

function FSBaseMission:update(dt)
	FSBaseMission:superClass().update(self, dt)

	if not l_engineState and self.isRunning then
		local playTimeH = Utils.getNoNil(g_farmManager:getFarmById(self.player.farmId).stats:getTotalValue("playTime"), 0) / 60

		if playTimeH > 4 then
			l_engineStateTimer = l_engineStateTimer - dt

			if l_engineStateTimer < 0 and not g_gui:getIsGuiVisible() then
				g_gui:showInfoDialog({
					text = g_i18n:getText("dialog_getFullVersion"),
					callback = onEngineStateCallback
				})

				l_engineStateTimer = math.random(1200000, 1800000)
			end
		end
	end

	self.hud:updateMessageAndIcon(dt)
	self.hud:updateMap(dt)
	g_densityMapHeightManager:update(dt)

	if g_wildlifeSpawnerManager ~= nil then
		g_wildlifeSpawnerManager:update(dt)
	end

	self:updatePauseInputContext()

	if not self.isRunning and g_dedicatedServerInfo == nil then
		if self.paused and not self.isSynchronizingWithPlayers and not g_gui:getIsGuiVisible() and GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
			setPresenceMode(PresenceModes.PRESENCE_IDLE)

			self.presenceMode = PresenceModes.PRESENCE_IDLE
		end

		self:updateSaving()

		return
	end

	if table.getn(self.playersToAccept) > 0 then
		if self.missionDynamicInfo.autoAccept then
			self:onConnectionDenyAccept(self.playersToAccept[1].connection, false, false)
		elseif self:getCanAcceptPlayers() then
			g_gui:showDenyAcceptDialog({
				callback = self.onConnectionDenyAccept,
				target = self,
				connection = self.playersToAccept[1].connection,
				nickname = self.playersToAccept[1].playerStyle.playerName
			})
		end
	end

	g_effectManager:update(dt)
	g_animationManager:update(dt)

	if self:getIsServer() then
		for k, user in ipairs(self.userManager:getUsers()) do
			if k > 1 then
				local farm = g_farmManager:getFarmByUserId(user:getId())

				if user:getState() == FSBaseMission.USER_STATE_INGAME and user:getFinanceUpdateSendTime() < self.time then
					user:setFinanceUpdateSendTime(self.time + math.floor(math.random() * 300 + 5000))

					if farm.stats.financesVersionCounter ~= user:getFinancesVersionCounter() then
						user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
						user:getConnection():sendEvent(FinanceStatsEvent:new(0, farm.farmId))
					end
				end
			end
		end

		if g_dedicatedServerInfo ~= nil and self.gameStatsTime <= self.time then
			self:updateGameStatsXML()
		end

		g_treePlantManager:updateTrees(dt, dt * self:getEffectiveTimeScale())
	end

	for placeable in pairs(self.placeablesToDelete) do
		placeable:delete()

		self.placeablesToDelete[placeable] = nil
	end

	if self:getIsClient() then
		if not g_gui:getIsGuiVisible() then
			if g_soundPlayer ~= nil then
				local isRadioToggleActive = self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio or not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)

				self.inputManager:setActionEventActive(self.eventRadioToggle, isRadioToggleActive)
			end

			self.hud:updateVehicleName(dt)
		end

		if self.currentCameraPath ~= nil then
			-- Nothing
		end

		self:updateSaving()
	end

	local presenceMode = nil

	if self.missionInfo:isa(FSCareerMissionInfo) then
		if self.missionDynamicInfo.isMultiplayer then
			if self:getIsServer() then
				local activeUsers = 0

				for _, user in ipairs(self.userManager:getUsers()) do
					local connection = user:getConnection()

					if user:getState() == FSBaseMission.USER_STATE_INGAME and connection ~= nil and self.connectionsToPlayer[connection] ~= nil then
						activeUsers = activeUsers + 1
					end
				end

				if activeUsers > 1 then
					presenceMode = PresenceModes.PRESENCE_MULTIPLAYER
				else
					presenceMode = PresenceModes.PRESENCE_MULTIPLAYER_ALONE
				end
			else
				presenceMode = PresenceModes.PRESENCE_MULTIPLAYER
			end
		else
			presenceMode = PresenceModes.PRESENCE_CAREER
		end
	else
		presenceMode = PresenceModes.PRESENCE_TUTORIAL
	end

	if self.wasNetworkError and GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		presenceMode = PresenceModes.PRESENCE_IDLE
	end

	if self.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER and presenceMode ~= PresenceModes.PRESENCE_MULTIPLAYER then
		setPresenceMode(presenceMode)

		self.presenceMode = presenceMode
	elseif self.presenceMode ~= presenceMode and (not g_gui:getIsGuiVisible() or self:getIsServer()) then
		setPresenceMode(presenceMode)

		self.presenceMode = presenceMode
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 and self.missionDynamicInfo.isMultiplayer then
		local networkError = getNetworkError()

		if networkError and not self.wasNetworkError then
			networkError = string.gsub(networkError, "Network", "dialog_network")
			self.wasNetworkError = true

			g_gui:showConnectionFailedDialog({
				text = g_i18n:getText(networkError),
				callback = g_connectionFailedDialog.onOkCallback,
				target = g_connectionFailedDialog,
				args = {
					g_gui.currentGuiName
				}
			})
		elseif not networkError and self.wasNetworkError then
			self.wasNetworkError = false
		end

		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			OnInGameMenuMenu()
		end
	end

	if self.debugVehiclesToBeLoaded ~= nil then
		local data = self.debugVehiclesToBeLoaded[1]

		if data ~= nil then
			local storeItem = data.storeItem
			local items = {}

			if storeItem.bundleInfo ~= nil then
				for _, item in pairs(storeItem.bundleInfo.bundleItems) do
					table.insert(items, {
						xmlFilename = item.xmlFilename
					})
				end
			else
				table.insert(items, {
					xmlFilename = storeItem.xmlFilename
				})
			end

			for _, item in pairs(items) do
				local vehicle = g_currentMission:loadVehicle(item.xmlFilename, 0, nil, 0, 0, 0, true, 0, Vehicle.PROPERTY_STATE_OWNED, AccessHandler.EVERYONE, data.configurations, nil)

				if vehicle ~= nil then
					g_currentMission:removeVehicle(vehicle)
				end
			end

			table.remove(self.debugVehiclesToBeLoaded, 1)
		else
			local totalTime = g_time - self.debugVehiclesToBeLoadedStartTime

			print(string.format("Successfully loaded and removed all vehicles in %.1f seconds!", totalTime / 1000))

			self.debugVehiclesToBeLoaded = nil
		end
	end

	if self.isExitingGame then
		OnInGameMenuMenu()
	end

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_IOS or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID and g_buildTypeParam ~= "CHINA_GAPP" and g_buildTypeParam == "CHINA" then
		self:testForGameRating()
	end
end

function FSBaseMission:testForGameRating()
	if g_gui:getIsGuiVisible() then
		return
	end

	local lifetimeStats = g_lifetimeStats
	local totalPlayTime = lifetimeStats:getTotalRuntime()
	local amountGameRateDialogShown = lifetimeStats.gameRateMessagesShown
	local show = amountGameRateDialogShown < 4 and totalPlayTime >= amountGameRateDialogShown * 3 + 1

	if show then
		lifetimeStats.gameRateMessagesShown = amountGameRateDialogShown + 1

		lifetimeStats:save()
		g_gui:showGameRateDialog()
	end
end

function FSBaseMission:updateSaving()
	if self.doSaveGameState ~= SavegameController.SAVE_STATE_NONE then
		if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST then
			if self.savegameController:isStorageDeviceUnavailable() then
				self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT

				if g_dedicatedServerInfo == nil then
					self.inGameMenu:notifyValidateSavegameList(self.currentDeviceHasNoSpace, self.onYesNoSavegameSelectDevice, self)
				else
					g_logManager:error("The device no space to save the game.")
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT then
			-- Nothing
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_OVERWRITE_DIALOG then
			local metadata, _ = saveGetInfoById(self.missionInfo.savegameIndex)

			if metadata ~= "" then
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT

				if g_dedicatedServerInfo == nil then
					self.inGameMenu:notifyOverwriteSavegame(self.onYesNoSavegameOverwrite, self)
				else
					self:onYesNoSavegameOverwrite(true)
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT then
			-- Nothing
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_NOP_WRITE then
			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE then
			if g_dedicatedServerInfo == nil then
				self.inGameMenu:notifyStartSaving()
			end

			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE_WAIT
			self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION

			self:saveSavegame(self.doSaveGameBlocking)
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE_WAIT and not self.savegameController:getIsSaving() then
			local errorCode = self.savegameController:getSavingErrorCode()

			if errorCode ~= Savegame.ERROR_OK then
				if errorCode == Savegame.ERROR_SAVE_NO_SPACE and GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_PS4 then
					self.currentDeviceHasNoSpace = true

					if g_dedicatedServerInfo == nil then
						self.inGameMenu:notifySaveFailedNoSpace(self.onYesNoSavegameSelectDevice, self)
					end
				else
					self.doSaveGameState = SavegameController.SAVE_STATE_NONE
					self.savingMinEndTime = 0

					self.savegameController:resetStorageDeviceSelection()

					if g_dedicatedServerInfo == nil then
						self.inGameMenu:notifySavegameNotSaved()
					end
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_NONE

				if g_dedicatedServerInfo == nil then
					self.inGameMenu:notifySaveComplete()
				end
			end
		end

		return
	end
end

function FSBaseMission:onYesNoSavegameSelectDevice(yes)
	if yes then
		self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT

		self.savegameController:resetStorageDeviceSelection()
		self.savegameController:updateSavegames()
	else
		self.doSaveGameState = SavegameController.SAVE_STATE_NONE
		self.savingMinEndTime = 0

		self.inGameMenu:notifySavegameNotSaved()
	end
end

function FSBaseMission:onSaveGameUpdateComplete(errorCode)
	if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT then
		if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
			self.currentDeviceHasNoSpace = false
			self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
		else
			self.doSaveGameState = SavegameController.SAVE_STATE_NONE

			self.savegameController:resetStorageDeviceSelection()
			self.inGameMenu:notifySavegameNotSaved(errorCode)
		end
	end
end

function FSBaseMission:onYesNoSavegameOverwrite(yes)
	if yes then
		self.doSaveGameState = InGameMenu.SAVE_STATE_NOP_WRITE
	else
		self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
		self.savingMinEndTime = 0

		self.inGameMenu:notifySavegameNotSaved()
	end
end

function FSBaseMission:getSynchronizingPercentage()
	local percentage = 0
	local numSyncPlayers = 0

	for _, syncPlayer in pairs(self.playersSynchronizing) do
		percentage = percentage + self.restPercentageFraction

		if syncPlayer.densityMapEvent ~= nil then
			percentage = percentage + syncPlayer.densityMapEvent.percentage * self.densityMapPercentageFraction
		end

		if syncPlayer.splitShapesEvent ~= nil then
			percentage = percentage + syncPlayer.splitShapesEvent.percentage * self.splitShapesPercentageFraction
		end

		numSyncPlayers = numSyncPlayers + 1
	end

	if numSyncPlayers > 0 then
		percentage = percentage / numSyncPlayers
	end

	return math.floor(percentage * 100)
end

function FSBaseMission:showPauseDisplay(enableDisplay)
	local pauseText = ""

	if enableDisplay then
		pauseText = g_i18n:getText("ui_gamePaused")

		if GS_IS_CONSOLE_VERSION and self:getIsServer() then
			pauseText = pauseText .. " " .. g_i18n:getText("ui_continueGame")
		end
	end

	self.hud:onPauseGameChange(enableDisplay, pauseText)
end

function FSBaseMission:draw()
	if self.paused then
		if self.isSynchronizingWithPlayers then
			local percentageStr = ""

			if self:getIsServer() then
				percentageStr = string.format(" %i%%", self:getSynchronizingPercentage())
			end

			local pauseText = g_i18n:getText("ui_synchronizingWithOtherPlayers") .. percentageStr

			self.hud:onPauseGameChange(nil, pauseText)
		end

		local menuVisible = g_gui:getIsGuiVisible() and not g_gui:getIsOverlayGuiVisible()

		if not menuVisible or self.isSynchronizingWithPlayers then
			self.hud:drawGamePaused(not self.isMissionStarted and not menuVisible)
		end
	end

	if self.isRunning and (not g_gui:getIsGuiVisible() or g_gui:getIsOverlayGuiVisible()) and not self.hud:getIsFading() then
		if g_showTipCollisions then
			g_densityMapHeightManager:visualizeCollisionMap()
		end

		if g_showPlacementCollisions then
			g_densityMapHeightManager:visualizePlacementCollisionMap()
		end

		if self.hud:getIsVisible() then
			self.hud:drawBaseHUD()
			self.hud:drawVehicleName()
		end
	end

	FSBaseMission:superClass().draw(self)

	if not self.hud:getIsFading() then
		self.hud:drawInGameMessageAndIcon()
	end

	if FSBaseMission.DEBUG_SHOW_FIELDSTATUS then
		local x, _, z = getWorldTranslation(getCamera())
		local size = FSBaseMission.DEBUG_SHOW_FIELDSTATUS_SIZE
		local startWorldX = x - size * 0.5
		local startWorldZ = z + size * 0.5
		local widthWorldX = x + size * 0.5
		local widthWorldZ = z + size * 0.5
		local heightWorldX = x - size * 0.5
		local heightWorldZ = z - size * 0.5

		DebugUtil.drawDebugAreaRectangle(startWorldX, 0, startWorldZ, widthWorldX, 0, widthWorldZ, heightWorldX, 0, heightWorldZ, true, 1, 0, 0)

		local fieldStatus = FSDensityMapUtil.getStatus(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		DebugUtil.renderTable(0.1, 0.98, 0.012, fieldStatus, 0.1)
	end
end

function FSBaseMission:addMoneyChange(amount, farmId, moneyType, forceShow)
	if self:getIsServer() then
		if self.moneyChanges[moneyType.id] == nil then
			self.moneyChanges[moneyType.id] = {}
		end

		local changes = self.moneyChanges[moneyType.id]

		if changes[farmId] == nil then
			changes[farmId] = 0
		end

		changes[farmId] = changes[farmId] + amount

		if self:getFarmId() == farmId then
			self.hud:addMoneyChange(moneyType, amount)
		end

		if forceShow then
			self:broadcastNotifications(moneyType, farmId)
		end
	else
		g_logManager:error("addMoneyChange() called on client")
		printCallstack()
	end
end

function FSBaseMission:showMoneyChange(moneyType, text, allFarms, farmId)
	if self:getIsServer() then
		if allFarms then
			for _, farm in ipairs(g_farmManager:getFarms()) do
				self:broadcastNotifications(moneyType, farm.farmId, text)
			end
		else
			self:broadcastNotifications(moneyType, farmId or g_currentMission:getFarmId(), text)
		end
	else
		g_client:getServerConnection():sendEvent(RequestMoneyChangeEvent:new(moneyType))
	end
end

function FSBaseMission:broadcastNotifications(moneyType, farmId, text)
	if moneyType == nil then
		printCallstack()
	end

	local farms = g_currentMission.moneyChanges[moneyType.id]

	if farms then
		local amount = farms[farmId]

		if amount then
			g_currentMission:broadcastEventToFarm(MoneyChangeEvent:new(amount, moneyType, farmId, text), farmId, false)

			if farmId == g_currentMission:getFarmId() then
				if text ~= nil then
					text = g_i18n:getText(text)
				end

				g_currentMission.hud:showMoneyChange(moneyType, text)
			end

			farms[farmId] = nil
		end
	end
end

function FSBaseMission:showAttachContext(attachableVehicle)
	self.hud:showAttachContext(self:getVehicleName(attachableVehicle))
end

function FSBaseMission:showTipContext(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

	self.hud:showTipContext(fillType.title)
end

function FSBaseMission:showFuelContext(fuelingVehicle)
	self.hud:showFuelContext(self:getVehicleName(fuelingVehicle))
end

function FSBaseMission:showFillDogBowlContext()
	self.hud:showFillDogBowlContext()
end

function FSBaseMission:addIngameNotification(notificationType, text)
	self.hud:addSideNotification(notificationType, text)
end

function FSBaseMission:setTutorialProgress(value)
	self.hud:setTutorialProgress(value)
end

function FSBaseMission:getIsAutoSaveSupported()
	return not g_isPresentationVersion and not g_isPresentationVersionUseReloadButton
end

function FSBaseMission:doPauseGame()
	FSBaseMission:superClass().doPauseGame(self)
	self.inGameMenu:setIsGamePaused(true)
	self.shopMenu:setIsGamePaused(true)
	self.placementController:setIsGamePaused(true)
	self.landscapingController:setIsGamePaused(true)
	self:updateFoliageGrowthStateTime()
end

function FSBaseMission:canUnpauseGame()
	return FSBaseMission:superClass().canUnpauseGame(self) and not self.isSynchronizingWithPlayers and not self.dediEmptyPaused and not self.userSigninPaused
end

function FSBaseMission:doUnpauseGame()
	FSBaseMission:superClass().doUnpauseGame(self)
	self.inGameMenu:setIsGamePaused(false)
	self.shopMenu:setIsGamePaused(false)
	self.placementController:setIsGamePaused(false)
	self.landscapingController:setIsGamePaused(false)
	self:updateFoliageGrowthStateTime()

	if g_dedicatedServerInfo ~= nil then
		setFramerateLimiter(true, g_dedicatedServerMaxFrameLimit)
	end
end

function FSBaseMission:getCanAcceptPlayers()
	return not g_gui:getIsDialogVisible()
end

function FSBaseMission:drawMissionCompleted()
	self.hud:drawMissionCompleted()
end

function FSBaseMission:drawMissionFailed()
	self.hud:drawMissionFailed()
end

function FSBaseMission:onEndMissionCallback()
	if self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED then
		self.isExitingGame = true
	end
end

function FSBaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	resetSplitShapes()
	setUseKinematicSplitShapes(not self:getIsServer())

	if missionInfo.isValid then
		local flags = TerrainLoadFlags.TEXTURE_CACHE + TerrainLoadFlags.NORMAL_MAP_CACHE + TerrainLoadFlags.OCCLUDER_CACHE

		if missionInfo:getIsDensityMapValid(self) then
			flags = flags + TerrainLoadFlags.DENSITY_MAPS_USE_LOAD_DIR
		end

		if not GS_IS_MOBILE_VERSION then
			flags = flags + TerrainLoadFlags.HEIGHT_MAP_USE_LOAD_DIR + TerrainLoadFlags.NORMAL_MAP_CACHE_USE_LOAD_DIR + TerrainLoadFlags.OCCLUDER_CACHE_USE_LOAD_DIR
			flags = flags + TerrainLoadFlags.TEXTURE_CACHE_USE_LOAD_DIR

			if missionInfo:getIsTerrainLodTextureValid(self) and g_densityMapHeightManager ~= nil and g_densityMapHeightManager:checkTypeMappings() then
				flags = flags + TerrainLoadFlags.LOD_TEXTURE_CACHE
			end
		end

		setTerrainLoadDirectory(missionInfo.savegameDirectory, flags)
	else
		setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
	end

	if missionInfo:getAreSplitShapesValid(self) then
		loadSplitShapesFromFile(missionInfo.savegameDirectory .. "/splitShapes.gmss")
	end

	FSBaseMission:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)

	if g_soundPlayer ~= nil then
		g_soundPlayer:addEventListener(self)

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			g_soundPlayer:setStreamingAccessOwner(self)
		end
	end

	self:updateMaxNumHirables()
	self.hud:setIngameMapSize(g_gameSettings:getValue("ingameMapState"))
end

function FSBaseMission:updateMaxNumHirables()
	if self.missionDynamicInfo.isMultiplayer then
		if self.missionDynamicInfo.capacity ~= nil then
			self.maxNumHirables = math.max(4, math.min(self.missionDynamicInfo.capacity, g_helperManager:getNumOfHelpers()))
		end
	elseif GS_IS_CONSOLE_VERSION then
		self.maxNumHirables = math.min(6, g_helperManager:getNumOfHelpers())
	elseif GS_IS_MOBILE_VERSION then
		self.maxNumHirables = math.min(6, g_helperManager:getNumOfHelpers())
	else
		self.maxNumHirables = g_helperManager:getNumOfHelpers()
	end
end

function FSBaseMission:addLiquidManureSilo(name, silo)
	if self:getLiquidManureSiloInfo(silo) ~= nil then
		print("Error: trigger already added")

		return
	end

	table.insert(self.liquidManureTriggers, {
		name = name,
		silo = silo
	})
end

function FSBaseMission:getLiquidManureSiloInfo(silo)
	for _, value in pairs(self.liquidManureTriggers) do
		if value.silo == silo then
			return value
		end
	end

	return nil
end

function FSBaseMission:removeLiquidManureSilo(silo)
	for key, value in pairs(self.liquidManureTriggers) do
		if value.silo == silo then
			table.remove(self.liquidManureTriggers, key)

			return
		end
	end
end

function FSBaseMission:getManureHeapInfo(manureHeap)
	for _, value in pairs(self.manureHeaps) do
		if value.manureHeap == manureHeap then
			return value
		end
	end

	return nil
end

function FSBaseMission:addManureHeap(name, manureHeap)
	if self:getManureHeapInfo(manureHeap) ~= nil then
		print("Error: trigger already added")

		return
	end

	table.insert(self.manureHeaps, {
		name = name,
		manureHeap = manureHeap
	})
end

function FSBaseMission:removeManureHeap(manureHeap)
	for key, value in pairs(self.manureHeaps) do
		if value.manureHeap == manureHeap then
			table.remove(self.manureHeaps, key)

			return
		end
	end
end

function FSBaseMission:addAdBanner(adBanner)
	ListUtil.addElementToList(self.adBanners, adBanner)
end

function FSBaseMission:removeAdBanner(adBanner)
	ListUtil.removeElementFromList(self.adBanners, adBanner)
end

function FSBaseMission:addMoney(amount, farmId, moneyType, addChange, forceShowChange)
	if self:getIsServer() then
		if farmId == 0 then
			print("Error: Can't change money of spectator farm")
			printCallstack()

			return
		end

		local farm = g_farmManager:getFarmById(farmId)

		if farm == nil then
			return
		end

		farm:changeBalance(amount, moneyType)

		if addChange then
			self:addMoneyChange(amount, farmId, moneyType, forceShowChange)
		end
	else
		print("Error: FSBaseMission:addMoney is only allowed on a server")
		printCallstack()
	end
end

function FSBaseMission:addPurchasedMoney(amount)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmById(FarmManager.SINGLEPLAYER_FARM_ID)

		if farm == nil then
			return
		end

		farm:addPurchasedCoins(amount)
	else
		print("Error: FSBaseMission:addPurchasedMoney is only allowed on a server")
		printCallstack()
	end
end

function FSBaseMission:getMoney(farmId)
	if farmId == nil then
		farmId = self.player == nil and FarmManager.SINGLEPLAYER_FARM_ID or self.player.farmId
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		return 0
	end

	self.cacheFarm = farm

	return farm.money
end

function FSBaseMission:setPlayerPermission(userId, permission, allow)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmByUserId(userId)
		local player = farm.userIdToPlayer[userId]
		player.permissions[permission] = allow
	end
end

function FSBaseMission:setPlayerPermissions(userId, permissions)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmByUserId(userId)
		local player = farm.userIdToPlayer[userId]

		for _, permission in ipairs(Farm.PERMISSIONS) do
			if permissions[permission] ~= nil then
				player.permissions[permission] = permissions[permission]
			end
		end
	end
end

function FSBaseMission:getHasPlayerPermission(permission, connection, farmId, checkClient)
	if checkClient == nil or not checkClient then
		if self:getIsServer() then
			if connection == nil or connection:getIsLocal() or connection:getIsServer() or self.userManager:getIsConnectionMasterUser(connection) then
				return true
			end
		elseif self.isMasterUser then
			return true
		end

		if connection ~= nil and connection:getIsServer() then
			return true
		end
	end

	local user = nil

	if connection ~= nil then
		user = self.userManager:getUserByConnection(connection)
	else
		user = self.userManager:getUserByUserId(self.playerUserId)
	end

	local farm = g_farmManager:getFarmByUserId(user:getId())
	local player = farm.userIdToPlayer[user:getId()]

	if farmId ~= nil and farm.farmId ~= farmId then
		return false
	end

	return player.isFarmManager or Utils.getNoNil(player.permissions[permission], false)
end

function FSBaseMission:getTerrainDetailPixelsToSqm()
	local f = self.terrainSize / self.terrainDetailMapSize

	return f * f
end

function FSBaseMission:getFruitPixelsToSqm()
	local f = self.terrainSize / self.fruitMapSize

	return f * f
end

function FSBaseMission:getIngameMap()
	return self.hud:getIngameMap()
end

function FSBaseMission:sendNumPlayersToMasterServer(numPlayers)
	if self.missionDynamicInfo.isMultiplayer then
		if g_dedicatedServerInfo ~= nil then
			numPlayers = numPlayers - 1
		end

		masterServerSetNumPlayers(numPlayers)
	end
end

function FSBaseMission:setTimeScale(timeScale, noEventSend)
	if timeScale ~= self.missionInfo.timeScale then
		self.missionInfo.timeScale = timeScale

		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
		self:updateFoliageGrowthStateTime()
		SavegameSettingsEvent.sendEvent(noEventSend)

		if g_server ~= nil then
			g_server:broadcastEvent(EnvironmentTimeEvent:new(self.environment.currentDay, self.environment.dayTime))
		end
	end
end

function FSBaseMission:setTimeScaleMultiplier(timeScaleMultiplier)
	if timeScaleMultiplier ~= self.missionInfo.timeScaleMultiplier then
		self.missionInfo.timeScaleMultiplier = timeScaleMultiplier

		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
	end
end

function FSBaseMission:getEffectiveTimeScale()
	return self.missionInfo.timeScale * (self.missionInfo.timeScaleMultiplier or 1)
end

function FSBaseMission:setEconomicDifficulty(economicDifficulty, noEventSend)
	if economicDifficulty ~= self.missionInfo.economicDifficulty then
		self.missionInfo.economicDifficulty = economicDifficulty

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setPlantGrowthRate(plantGrowthRate, noEventSend)
	if plantGrowthRate ~= self.missionInfo.plantGrowthRate and self.plantGrowthRateIsLocked ~= true then
		self.missionInfo.plantGrowthRate = plantGrowthRate

		self:updateFoliageGrowthStateTime()
		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'plantGrowthRate': %d", plantGrowthRate)
	end
end

function FSBaseMission:setPlantGrowthRateLocked(state)
	self.plantGrowthRateIsLocked = state
end

function FSBaseMission:setSavegameName(name, noEventSend)
	if name ~= self.missionInfo.savegameName then
		self.missionInfo.savegameName = name

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:startSaveCurrentGame(hiddenUI, blocking)
	self.currentDeviceHasNoSpace = false

	if g_dedicatedServerInfo ~= nil or isDediSaving then
		self:saveSavegame(blocking)
	else
		self.doSaveGameState = InGameMenu.SAVE_STATE_WRITE
		self.doSaveGameBlocking = blocking

		self.inGameMenu:startSavingGameDisplay()
	end

	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function FSBaseMission:saveSavegame(blocking)
	if not g_sleepManager:getIsSleeping() then
		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			self.isSaving = true

			self:pauseGame()
		end

		self.savegameController:saveSavegame(self.missionInfo, blocking)
	end
end

function FSBaseMission:getFoliageGrowthStateTimeMultiplier()
	local mult = 0

	if self.missionInfo.plantGrowthRate == 2 then
		mult = 2
	elseif self.missionInfo.plantGrowthRate == 3 then
		mult = 1
	elseif self.missionInfo.plantGrowthRate == 4 then
		mult = 0.8
	end

	return mult / self:getEffectiveTimeScale()
end

function FSBaseMission:updateFoliageGrowthStateTime()
	if self:getIsServer() then
		local multiplier = self:getFoliageGrowthStateTimeMultiplier()

		for _, updater in pairs(self.fieldCropsUpdaters) do
			setCropsEnableGrowth(updater.updater, multiplier > 0 and not self.paused and self.fieldCropsAllowGrowing and self.isLoaded)

			if multiplier > 0 then
				for name, id in pairs(updater.ids) do
					local fruitType = g_fruitTypeManager:getFruitTypeByName(name)

					setCropsGrowthStateTime(updater.updater, id, fruitType.growthStateTime * multiplier)
				end
			end
		end

		if self.weedUpdater ~= nil then
			local weedType = g_fruitTypeManager:getFruitTypeByName("weed")
			local delta = 0

			if multiplier > 0 and not self.paused and self.fieldCropsAllowGrowing and self.isLoaded and self.missionInfo.weedsEnabled then
				delta = weedType.weed.updateDelta
			end

			setUpdateDeltaValue(self.weedUpdater, delta)
			setUpdateCycleTime(self.weedUpdater, weedType.weed.growthStateTime * multiplier)
		end
	end
end

function FSBaseMission:setPlantWitheringEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.isPlantWitheringEnabled then
		self.missionInfo.isPlantWitheringEnabled = isEnabled

		self:updatePlantWithering()
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setFruitDestructionEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.fruitDestruction then
		self.missionInfo.fruitDestruction = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setPlowingRequiredEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.plowingRequiredEnabled then
		self.missionInfo.plowingRequiredEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'plowingRequiredEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setLimeRequired(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.limeRequired then
		self.missionInfo.limeRequired = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'limeRequired': %s", isEnabled)
	end
end

function FSBaseMission:setWeedsEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.weedsEnabled then
		self.missionInfo.weedsEnabled = isEnabled

		self:updateFoliageGrowthStateTime()
		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'weedsEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setStopAndGoBraking(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.stopAndGoBraking then
		self.missionInfo.stopAndGoBraking = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutoSaveInterval(interval, noEventSend)
	if interval ~= g_autoSaveManager:getInterval() then
		g_autoSaveManager:setInterval(interval)
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setTrafficEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.trafficEnabled then
		self.missionInfo.trafficEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)

		if self.trafficSystem ~= nil then
			self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)

			if not self.missionInfo.trafficEnabled then
				self.trafficSystem:reset()
			end
		end
	end
end

function FSBaseMission:setDirtInterval(dirtInterval, noEventSend)
	if dirtInterval ~= self.missionInfo.dirtInterval then
		self.missionInfo.dirtInterval = dirtInterval

		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'dirtInterval': %d", dirtInterval)
	end
end

function FSBaseMission:setFuelUsageLow(fuelUsageLow, noEventSend)
	if fuelUsageLow ~= self.missionInfo.fuelUsageLow then
		self.missionInfo.fuelUsageLow = fuelUsageLow

		SavegameSettingsEvent.sendEvent(noEventSend)
		g_logManager:info("Savegame Setting 'fuelUsageLow': %s", fuelUsageLow)
	end
end

function FSBaseMission:setHelperBuyFuel(helperBuyFuel, noEventSend)
	if helperBuyFuel ~= self.missionInfo.helperBuyFuel then
		self.missionInfo.helperBuyFuel = helperBuyFuel

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuySeeds(helperBuySeeds, noEventSend)
	if helperBuySeeds ~= self.missionInfo.helperBuySeeds then
		self.missionInfo.helperBuySeeds = helperBuySeeds

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuyFertilizer(helperBuyFertilizer, noEventSend)
	if helperBuyFertilizer ~= self.missionInfo.helperBuyFertilizer then
		self.missionInfo.helperBuyFertilizer = helperBuyFertilizer

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperSlurrySource(helperSlurrySource, noEventSend)
	if helperSlurrySource ~= self.missionInfo.helperSlurrySource then
		self.missionInfo.helperSlurrySource = helperSlurrySource

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperManureSource(helperManureSource, noEventSend)
	if helperManureSource ~= self.missionInfo.helperManureSource then
		self.missionInfo.helperManureSource = helperManureSource

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutomaticMotorStartEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.automaticMotorStartEnabled then
		self.missionInfo.automaticMotorStartEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:updatePlantWithering()
	if self:getIsServer() then
		for _, updater in pairs(self.fieldCropsUpdaters) do
			for name, id in pairs(updater.ids) do
				local fruitType = g_fruitTypeManager:getFruitTypeByName(name)
				local numStates = fruitType.numGrowthStates

				if not GS_IS_MOBILE_VERSION and self.missionInfo.isPlantWitheringEnabled then
					numStates = fruitType.witheringNumGrowthStates
				end

				setCropsNumGrowthStates(updater.updater, id, numStates)
				self:updatePlantRegrowth(updater.updater, id, fruitType)
			end
		end
	end

	local prefix = "Disabled"

	if self.missionInfo.isPlantWitheringEnabled then
		prefix = "Enabled"
	end

	print(prefix .. " withering")
end

function FSBaseMission:updatePlantRegrowth(updater, id, fruitType)
	if fruitType.regrows then
		setCropsGrowthNextState(updater, id, fruitType.cutState + 1, fruitType.firstRegrowthState + 1)
	end
end

function FSBaseMission:addKnownSplitShape(shape)
end

function FSBaseMission:removeKnownSplitShape(shape)
end

function FSBaseMission:getDoghouse(farmId)
	for _, doghouse in pairs(self.doghouses) do
		if doghouse:getOwnerFarmId() == farmId then
			return doghouse
		end
	end

	return nil
end

function FSBaseMission:onDayChanged()
end

function FSBaseMission:onHourChanged()
	if self:getIsServer() then
		self:showMoneyChange(MoneyType.AI, nil, true)
	end
end

function FSBaseMission:onMinuteChanged()
end

function FSBaseMission:registerHusbandry(husbandryId, husbandry)
	self.husbandries[husbandryId] = husbandry

	self.inGameMenu:setHusbandries(self.husbandries)
end

function FSBaseMission:unregisterHusbandry(husbandryId)
	self.husbandries[husbandryId] = nil

	self.inGameMenu:setHusbandries(self.husbandries)
end

function FSBaseMission:getHusbandryByAnimalType(animalType)
	for _, husbandry in pairs(self.husbandries) do
		if husbandry:getAnimalType() == animalType and self.player.farmId == husbandry:getOwnerFarmId() then
			return husbandry
		end
	end

	return nil
end

function FSBaseMission:getHusbandries(farmId)
	farmId = farmId or self.player.farmId
	local husbandries = {}

	for _, husbandry in pairs(self.husbandries) do
		if farmId == husbandry:getOwnerFarmId() then
			table.insert(husbandries, husbandry)
		end
	end

	return husbandries
end

function FSBaseMission:onLeaveVehicle(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
	FSBaseMission:superClass().onLeaveVehicle(self, playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)

	if g_gameSettings:getValue("radioVehicleOnly") then
		self:pauseRadio()
	end
end

function FSBaseMission:pauseRadio()
	if g_soundPlayer ~= nil then
		self:setRadioActionEventsState(false)
		self.hud:hideTopNotification()
		g_soundPlayer:pause()
	end
end

function FSBaseMission:playRadio()
	if g_soundPlayer ~= nil and g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE) then
		local hasStartedPlaying = g_soundPlayer:play()

		self:setRadioActionEventsState(hasStartedPlaying)
	end
end

function FSBaseMission:getIsRadioPlaying()
	if g_soundPlayer ~= nil then
		return g_soundPlayer:getIsPlaying()
	end

	return false
end

function FSBaseMission:onSoundPlayerChange(channelName, itemName, isOnlineStream)
	if not GS_IS_MOBILE_VERSION then
		local rating = ""
		local iconKey = nil

		if isOnlineStream then
			rating = g_i18n:getText("ui_radioRating")
			iconKey = TopNotification.ICON.RADIO
		end

		self:addGameNotification(string.upper(channelName), string.upper(itemName), rating, iconKey, 4000, self.radioNotification)
	end

	g_messageCenter:publish(MessageType.RADIO_CHANNEL_CHANGE, channelName, itemName, isOnlineStream)
end

function FSBaseMission:onSoundPlayerStreamAccess()
	if g_gameSettings:getValue("isSoundPlayerStreamAccessAllowed") then
		self:onStreamAccessAllowed(true)
	else
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_radioRating") .. "\n\n" .. g_i18n:getText("ui_continueQuestion"),
			callback = self.onStreamAccessAllowed,
			target = self
		})
	end
end

function FSBaseMission:onStreamAccessAllowed(yes)
	if g_soundPlayer ~= nil then
		if yes then
			g_gameSettings:setValue("isSoundPlayerStreamAccessAllowed", true, true)
		end

		g_soundPlayer:setStreamAccessAllowed(yes)
	end
end

function FSBaseMission:setRadioVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_RADIO, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
end

function FSBaseMission:setVehicleVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_VEHICLE, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
end

function FSBaseMission:setEnvironmentVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_ENVIRONMENT, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))

	if GS_IS_MOBILE_VERSION then
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.DEFAULT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
	end
end

function FSBaseMission:setGUIVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_GUI, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
end

function FSBaseMission:getVehicleName(vehicle)
	local name = vehicle:getFullName()
	name = utf8ToUpper(name)

	return name
end

function FSBaseMission:onEnterVehicle(vehicle, playerIndex, playerColorIndex, farmId)
	FSBaseMission:superClass().onEnterVehicle(self, vehicle, playerIndex, playerColorIndex, farmId)

	if g_soundPlayer ~= nil then
		if not self:getIsRadioPlaying() then
			if vehicle.supportsRadio then
				self:playRadio()
			end
		elseif not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
			self:pauseRadio()
		end
	end

	self.currentVehicleName = self:getVehicleName(vehicle)

	self.hud:showVehicleName(self.currentVehicleName)
end

function FSBaseMission:setMoneyUnit(unit)
	FSBaseMission:superClass().setMoneyUnit(self, unit)
	self.hud:setMoneyUnit(unit)
end

function FSBaseMission:getFarmSiloCapacity()
	local capacity = 0

	if self.farmSiloTrigger ~= nil then
		for siloSource, _ in pairs(self.farmSiloTrigger.siloSources) do
			capacity = capacity + siloSource.capacity
		end
	end

	return capacity
end

function FSBaseMission:consoleCommandCheatMoney(amount)
	amount = tonumber(Utils.getNoNil(amount, 10000000))

	if amount == nil then
		return "Invalid arguments. Arguments: amount"
	end

	local farmId = self.player.farmId

	if self:getIsServer() or self.isMasterUser then
		if self:getIsServer() then
			self:addMoney(amount, farmId, MoneyType.OTHER, true, true)
		else
			g_client:getServerConnection():sendEvent(CheatMoneyEvent:new(amount, farmId))
		end

		return "Add money " .. amount
	end
end

function FSBaseMission:consoleCommandExportStoreItems()
	local csvFile = getUserProfileAppPath() .. "storeItems.csv"
	local specTypes = g_storeManager:getSpecTypes()
	local file = io.open(csvFile, "w")

	if file ~= nil then
		local header = "xmlFilename;category;brand;name;price;lifetime;dailyUpkeep;"

		for _, spec in pairs(specTypes) do
			header = header .. spec.name .. ";"
		end

		file:write(header .. "\n")

		for _, storeItem in pairs(g_storeManager:getItems()) do
			local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
			local data = string.format("%s;%s;%s;%s;%s;%s;%s;", storeItem.xmlFilename, storeItem.categoryName, brand.name, storeItem.name, storeItem.price, storeItem.lifetime, storeItem.dailyUpkeep)

			for _, spec in pairs(specTypes) do
				local value = spec.getValueFunc(storeItem, nil)

				if value == nil or type(value) == "table" then
					value = ""
				end

				data = data .. StringUtil.trim(value) .. ";"
			end

			file:write(data .. "\n")
		end

		file:close()
	end
end

function FSBaseMission:consoleStartGreatDemand()
	for _, greatDemand in pairs(self.economyManager.greatDemands) do
		self.economyManager:stopGreatDemand(greatDemand)
	end

	for _, greatDemand in pairs(self.economyManager.greatDemands) do
		greatDemand:setUpRandomDemand(true, self.economyManager.greatDemands)

		greatDemand.demandStart.day = g_currentMission.environment.currentDay
		greatDemand.demandStart.hour = g_currentMission.environment.currentHour + 1
	end

	return "Great demand starts in the next hour..."
end

function FSBaseMission:consoleCommandCheatSilo(fillTypeName, amount)
	if self:getIsServer() then
		amount = tonumber(amount)

		if fillTypeName == nil or amount == nil then
			return "Invalid arguments. Arguments: fillTypeName amount"
		end

		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			return "Invalid fillType " .. fillTypeName
		end

		local silo = nil
		local farmId = self:getFarmId()

		for _, placeable in pairs(self.placeables) do
			if placeable:getOwnerFarmId() == farmId and placeable:isa(SiloPlaceable) then
				silo = placeable

				break
			end
		end

		if silo == nil then
			return "No Farm Silo found for current farm"
		end

		silo:setAmount(fillTypeIndex, amount)

		return "Added " .. amount .. " to farm silo"
	end
end

function FSBaseMission:consoleCommandReloadVehicle(resetVehicle)
	if self:getIsServer() and not self.missionDynamicInfo.isMultiplayer and self.controlledVehicle ~= nil then
		g_soundManager:reloadSoundTemplates()

		local vehicle = self.controlledVehicle
		local steerable = vehicle
		vehicle.isReconfigurating = true
		local vehicleList = {}
		local usedModNames = {}
		local currentVehicle = vehicle
		resetVehicle = (resetVehicle ~= nil or false) and resetVehicle:lower() == "true"

		local function addVehicle(v, list)
			if v.isVehicleSaved then
				v.isReconfigurating = true

				table.insert(list, v)

				if v ~= nil and v.getAttachedImplements ~= nil then
					local attachedImplements = v:getAttachedImplements()

					for _, implement in pairs(attachedImplements) do
						addVehicle(implement.object, list)
					end
				end
			else
				self:removeVehicle(v)
			end
		end

		addVehicle(currentVehicle, vehicleList)

		local xmlFile = createXMLFile("vehicleXMLFile", "", "vehicles")
		local savedVehiclesToId = self:saveVehicleList(xmlFile, "vehicles", vehicleList, usedModNames)
		local steerableId = savedVehiclesToId[vehicle]

		g_i3DManager:deleteSharedI3DFiles()

		local loadedVehicles = {}
		local success = true
		local i = 1

		while true do
			local key = string.format("vehicles.vehicle(%d)", i - 1)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local ret, newVehicle = self:loadVehicleFromXML(xmlFile, key, resetVehicle, false, nil, resetVehicle)

			if ret == BaseMission.VEHICLE_LOAD_ERROR or newVehicle == nil then
				success = false

				break
			end

			local id = getXMLString(xmlFile, key .. "#id")
			loadedVehicles[id] = newVehicle
			i = i + 1
		end

		if success then
			for _, vehicle in pairs(vehicleList) do
				self:removeVehicle(vehicle)
				vehicle:removeFromPhysics()
			end

			local i = 0

			while true do
				local key = string.format("vehicles.attachments(%d)", i)

				if not hasXMLProperty(xmlFile, key) then
					break
				end

				local id = getXMLString(xmlFile, key .. "#rootVehicleId")

				if id ~= nil then
					local vehicle = loadedVehicles[id]

					if vehicle ~= nil then
						vehicle:loadAttachmentsFromXMLFile(xmlFile, key, loadedVehicles)
					end
				end

				i = i + 1
			end

			steerable = loadedVehicles[tostring(steerableId)]
		else
			for _, vehicle in pairs(loadedVehicles) do
				self:removeVehicle(vehicle)
				vehicle:removeFromPhysics()
			end
		end

		self:requestToEnterVehicle(steerable)
		delete(xmlFile)
	end
end

function FSBaseMission:consoleCommandTipFillType(fillTypeName, value, length, rows, spacing)
	local usage = "gsTipFillType fillTypeName value"

	if fillTypeName == nil then
		return "No filltype given. " .. usage
	end

	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	if fillTypeIndex == nil then
		return "Invalid fillType. " .. usage
	end

	value = tonumber(value)

	if value == nil then
		return "No value given. " .. usage
	end

	length = Utils.getNoNil(tonumber(length), 1)
	rows = Utils.getNoNil(tonumber(rows), 1)
	spacing = Utils.getNoNil(tonumber(spacing), 3)
	local x = 0
	local y = 0
	local z = 0
	local dirX = 1
	local _ = 0
	local dirZ = 0

	if self.controlPlayer then
		if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
			x, y, z = getWorldTranslation(self.player.rootNode)
			dirZ = -math.cos(self.player.rotY)
			_ = 0
			dirX = -math.sin(self.player.rotY)
		end
	elseif self.controlledVehicle ~= nil then
		x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
		dirX, _, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
	end

	local initialOffset = (rows - 1) * spacing * -0.5

	for i = 0, rows - 1 do
		local offset = initialOffset + i * spacing
		local lx = x + offset * dirZ
		local ly = y
		local lz = z + offset * -dirX

		DensityMapHeightUtil.tipToGroundAroundLine(self.controlledVehicle, value, fillTypeIndex, lx, ly, lz, lx + length * dirX, ly, lz + length * dirZ, 10, 40, nil, , , )
	end

	if self.controlPlayer and self.player ~= nil then
		local _, delta = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)

		self.player:moveTo(x, delta, z, false, false)
	end

	return "Tipped ..."
end

function FSBaseMission:consoleCommandClearTipArea(size)
	size = tonumber(size)
	local terrainSizeHalf = self.terrainSize * 0.5
	local x0 = -terrainSizeHalf
	local z0 = terrainSizeHalf
	local x1 = terrainSizeHalf
	local z1 = terrainSizeHalf
	local x2 = -terrainSizeHalf
	local z2 = -terrainSizeHalf

	if size ~= nil then
		local node = nil

		if self.controlPlayer then
			if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
				node = self.player.rootNode
			end
		elseif self.controlledVehicle ~= nil then
			node = self.controlledVehicle.rootNode
		end

		if node ~= nil then
			local sizeHalf = size * 0.5
			x0, _, z0 = localToWorld(node, -sizeHalf, 0, sizeHalf)
			x1, _, z1 = localToWorld(node, sizeHalf, 0, sizeHalf)
			x2, _, z2 = localToWorld(node, -sizeHalf, 0, -sizeHalf)
		end
	end

	DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)
end

function FSBaseMission:consoleCommandLoadTree(length, treeType, growthState)
	local treeTypes = ""

	for name, _ in pairs(g_treePlantManager.nameToTreeType) do
		treeTypes = string.format("%s'%s', ", treeTypes, name)
	end

	length = tonumber(length)
	local usage = "gsLoadTree length [type (available: " .. treeTypes .. ")] [growthState]"

	if length == nil then
		return "No length given. " .. usage
	end

	if treeType == nil then
		treeType = "TREEFIR"
	end

	local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromName(treeType)

	if treeTypeDesc == nil then
		return "Invalid tree type. " .. usage
	end

	growthState = Utils.getNoNil(growthState, table.getn(treeTypeDesc.treeFilenames))
	local x = 0
	local y = 0
	local z = 0
	local dirX = 1
	local dirY = 0
	local dirZ = 0

	if self.controlPlayer then
		if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
			x, y, z = getWorldTranslation(self.player.rootNode)
			dirZ = -math.cos(self.player.rotY)
			dirY = 0
			dirX = -math.sin(self.player.rotY)
		end
	elseif self.controlledVehicle ~= nil then
		x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
		dirX, dirY, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
	end

	z = z + dirZ * 4
	x = x + dirX * 4
	y = y + 1

	g_treePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthState)
end

function FSBaseMission:consoleCommandTeleport(field, z)
	local usage = "gsTeleport xPos|field [zPos] (if zPos is not given first parameter is used as field id)"
	field = tonumber(field)
	z = tonumber(z)

	if field == nil then
		return "Invalid field or x-position. " .. usage
	end

	local targetX, targetZ = nil

	if z == nil then
		local field = g_fieldManager:getFieldByIndex(field)

		if field ~= nil then
			targetZ = field.posZ
			targetX = field.posX
		else
			return "Invalid field id. " .. usage
		end
	else
		local worldSizeX = self.terrainSize
		local worldSizeZ = self.terrainSize
		targetX = MathUtil.clamp(field, 0, worldSizeX) - worldSizeX * 0.5
		targetZ = MathUtil.clamp(z, 0, worldSizeZ) - worldSizeZ * 0.5
	end

	if self.controlledVehicle == nil then
		self.player:moveTo(targetX, 0.5, targetZ, false, false)
	else
		local vehicleCombos = {}
		local vehicles = {}

		local function addVehiclePositions(vehicle)
			local x, y, z = getWorldTranslation(vehicle.rootNode)

			table.insert(vehicles, {
				vehicle = vehicle,
				offset = {
					worldToLocal(self.controlledVehicle.rootNode, x, y, z)
				}
			})

			for _, impl in pairs(vehicle:getAttachedImplements()) do
				addVehiclePositions(impl.object)
				table.insert(vehicleCombos, {
					vehicle = vehicle,
					object = impl.object,
					jointDescIndex = impl.jointDescIndex,
					inputAttacherJointDescIndex = impl.object:getActiveInputAttacherJointDescIndex()
				})
			end

			for i = table.getn(vehicle:getAttachedImplements()), 1, -1 do
				vehicle:detachImplement(1, true)
			end

			vehicle:removeFromPhysics()
		end

		addVehiclePositions(self.controlledVehicle)

		for k, data in pairs(vehicles) do
			local x = targetX
			local z = targetZ

			if k > 1 then
				x, _, z = localToWorld(self.controlledVehicle.rootNode, unpack(data.offset))
			end

			local _, ry, _ = getWorldRotation(data.vehicle.rootNode)

			data.vehicle:setRelativePosition(x, 0.5, z, ry, true)
			data.vehicle:addToPhysics()
		end

		for _, combo in pairs(vehicleCombos) do
			combo.vehicle:attachImplement(combo.object, combo.inputAttacherJointDescIndex, combo.jointDescIndex, true, nil, , false)
		end
	end
end

function FSBaseMission:consoleCommandAddDirtAmount(amount)
	if self:getIsServer() then
		amount = Utils.getNoNil(tonumber(amount), 0)

		if self.controlledVehicle ~= nil then
			for _, v in pairs(self.vehicles) do
				if v:getIsActive() and v.addDirtAmount ~= nil then
					v:addDirtAmount(amount)
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandAddWearAmount(amount)
	if self:getIsServer() then
		amount = Utils.getNoNil(tonumber(amount), 0)

		if self.controlledVehicle ~= nil then
			for _, v in pairs(self.vehicles) do
				if v:getIsActive() and v.addWearAmount ~= nil then
					v:addWearAmount(amount)
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandLoadAllVehicles(loadConfigs)
	if self:getIsServer() and not self.missionDynamicInfo.isMultiplayer then
		loadConfigs = string.lower(loadConfigs or "false") == "true"
		self.debugVehiclesToBeLoaded = {}
		self.debugVehiclesToBeLoadedStartTime = g_time

		for _, storeItem in pairs(g_storeManager:getItems()) do
			if StoreItemUtil.getIsVehicle(storeItem) then
				table.insert(self.debugVehiclesToBeLoaded, {
					storeItem = storeItem,
					configurations = {}
				})

				if loadConfigs and storeItem.configurations ~= nil then
					for name, items in pairs(storeItem.configurations) do
						if #items > 1 then
							for k, _ in ipairs(items) do
								local configs = {
									[name] = k
								}

								table.insert(self.debugVehiclesToBeLoaded, {
									storeItem = storeItem,
									configurations = configs
								})
							end
						end
					end
				end
			end
		end

		if loadConfigs then
			return "Loading vehicles with all configs..."
		else
			return "Loading vehicles (add param 'true' to load vehicles with configs)..."
		end
	else
		return "Command not allowed in multiplayer"
	end
end

function FSBaseMission:consoleCommandFillUnitAdd(fillUnitIndex, fillTypeName, amount)
	if fillUnitIndex == nil or fillTypeName == nil then
		return "Please use 'gsFillUnitAdd <fillUnitIndex> <fillTypeName> <amount>' to change the fillLevel and fillType of a fillUnit!"
	end

	if not self:getIsServer() then
		return "'gsFillUnitAdd <fillUnitIndex> <fillTypeName> <amount>' can only be called on server side!"
	end

	if self.controlledVehicle == nil then
		return "'gsFillUnitAdd <fillUnitIndex> <fillTypeName> <amount>' can only be used from within a controlled vehicle!"
	end

	local fillableVehicle = nil

	if self.controlledVehicle.getSelectedObject ~= nil then
		local selectedObject = self.controlledVehicle:getSelectedObject()

		if selectedObject ~= nil and selectedObject.vehicle.addFillUnitFillLevel ~= nil then
			fillableVehicle = selectedObject.vehicle
		end
	end

	if fillableVehicle == nil and self.controlledVehicle.addFillUnitFillLevel ~= nil then
		fillableVehicle = self.controlledVehicle
	end

	local farmId = self:getFarmId()

	if fillableVehicle ~= nil and fillableVehicle.getFillUnitSupportedToolTypes ~= nil then
		fillUnitIndex = tonumber(fillUnitIndex)
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		amount = tonumber(amount)

		if fillUnitIndex ~= nil and fillTypeIndex ~= nil then
			local capacity = fillableVehicle:getFillUnitCapacity(fillUnitIndex)

			if capacity > 0 then
				amount = amount or capacity

				if amount == 0 then
					amount = -capacity
				end

				fillableVehicle:addFillUnitFillLevel(farmId, fillUnitIndex, amount, fillTypeIndex, ToolType.UNDEFINED)

				local fillLevel = fillableVehicle:getFillUnitFillLevel(fillUnitIndex)
				fillTypeIndex = fillableVehicle:getFillUnitFillType(fillUnitIndex)
				fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), "unknown")

				return string.format("new fillLevel: %.1f, fillType: %d (%s)", fillLevel, fillTypeIndex, fillTypeName)
			else
				return "Selected Vehicle cannot be filled. Capacity is 0!"
			end
		else
			return "'gsFillUnitAdd <fillUnitIndex> <fillType> <amount>', check given parameters!"
		end
	else
		return "'gsFillUnitAdd <fillUnitIndex> <fillType> <amount>' could not find a fillable vehicle!"
	end
end

function FSBaseMission:consoleCommandFillVehicle(fillTypeName, amount)
	return "gsFillVehicle is deprecated, please use 'gsFillUnitAdd <fillUnitIndex> <fillTypeName> <amount>' to change the fillLevel and fillType of a fillUnit!"
end

function FSBaseMission:consoleCommandSetFuel(fuelLevel)
	if self:getIsServer() then
		if fuelLevel == nil then
			return "No fuellevel given! Usage: gsSetFuel <fuelLevel>"
		end

		fuelLevel = Utils.getNoNil(tonumber(fuelLevel), 10000000000.0)
		local vehicle = self.controlledVehicle

		if vehicle ~= nil then
			if vehicle.getConsumerFillUnitIndex ~= nil then
				local fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)

				if fillUnitIndex ~= nil then
					local fillLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
					local delta = fuelLevel - fillLevel

					vehicle:addFillUnitFillLevel(self:getFarmId(), fillUnitIndex, delta, FillType.DIESEL, ToolType.UNDEFINED, nil)
				else
					return "No Fuel filltype supported!"
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandSetMotorTemperature(temperature)
	if self:getIsServer() then
		if temperature == nil then
			return "No temperature given! Usage: gsSetTemperature <temperature>"
		end

		temperature = Utils.getNoNil(tonumber(temperature), 0)
		local vehicle = self.controlledVehicle

		if vehicle ~= nil then
			local spec = vehicle.spec_motorized

			if spec ~= nil then
				spec.motorTemperature.value = MathUtil.clamp(temperature, spec.motorTemperature.valueMin, spec.motorTemperature.valueMax)

				return "Set motor temperature to " .. spec.motorTemperature.value
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandSetOperatingTime(operatingTime)
	if self:getIsServer() then
		if operatingTime == nil then
			return "No operatingTime given! Usage: gsSetOperatingTime <operatingTime (h)>"
		end

		operatingTime = Utils.getNoNil(tonumber(operatingTime), 0)
		operatingTime = operatingTime * 1000 * 60 * 60

		if self.controlledVehicle ~= nil then
			if self.controlledVehicle.setOperatingTime ~= nil then
				self.controlledVehicle:setOperatingTime(operatingTime)
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandShowVehicleDistance(active)
	g_showVehicleDistance = Utils.getNoNil(active, not g_showVehicleDistance)
end

function FSBaseMission:consoleCommandShowTipCollisions(active)
	g_showTipCollisions = Utils.getNoNil(active, not g_showTipCollisions)
end

function FSBaseMission:consoleCommandShowPlacementCollisions(active)
	g_showPlacementCollisions = Utils.getNoNil(active, not g_showPlacementCollisions)
end

function FSBaseMission:consoleCommandUpdateTipCollisions()
	local x, _, z = getWorldTranslation(getCamera(0))

	g_densityMapHeightManager:updateCollisionMap(x - 10, z - 10, x + 10, z + 10)
end

function FSBaseMission:consoleCommandAddBale(fillTypeName, isRoundbale, width, height, length)
	if self:getIsServer() then
		fillTypeName = Utils.getNoNil(fillTypeName, "STRAW")
		local isWrapped = fillTypeName:lower() == "silage"
		isRoundbale = Utils.stringToBoolean(isRoundbale)
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex == nil then
			print("Invalid fillTypeName (e.g. STRAW). Use gsAddBale fillTypeName isRoundBale [width height/diameter length]")

			return
		end

		local defaultWidth = 1.2
		local defaultHeight = 0.9
		local defaultLength = 2.4

		if isRoundbale then
			defaultWidth = 1.12
			defaultHeight = 1.3
		end

		if fillTypeIndex == FillType.COTTON then
			defaultWidth = 2.44
			defaultHeight = 2.44
			defaultLength = 4.88
		end

		width = tonumber(Utils.getNoNil(width, defaultWidth))
		height = tonumber(Utils.getNoNil(height, defaultHeight))
		length = tonumber(Utils.getNoNil(length, defaultLength))
		local bale = g_baleTypeManager:getBale(fillTypeIndex, isRoundbale, width, height, length, height)
		local realFile = NetworkUtil.convertFromNetworkFilename(bale.filename)
		local x = 0
		local y = 0
		local z = 0
		local dirX = 1
		local dirZ = 0

		if self.controlPlayer then
			if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
				x, y, z = getWorldTranslation(self.player.rootNode)
				dirZ = -math.cos(self.player.rotY)
				dirX = -math.sin(self.player.rotY)
			end
		elseif self.controlledVehicle ~= nil then
			x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
			dirX, _, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
		else
			x, y, z = getWorldTranslation(getCamera())
			dirX, _, dirZ = localDirectionToWorld(getCamera(), 0, 0, -1)
		end

		z = z + dirZ * 4
		x = x + dirX * 4
		y = y + 5
		local baleObject = Bale:new(self:getIsServer(), self:getIsClient())

		baleObject:load(realFile, x, y, z, 0, 0, 0, nil)

		if isWrapped then
			baleObject:setWrappingState(1)
		end

		baleObject:setOwnerFarmId(g_currentMission:getFarmId(), true)
		baleObject:register()

		return string.format("Created bale at (%.2f, %.2f, %.2f). For specific bales use: gsAddBale fillType isRoundBale [width height/diameter length] ", x, y, z)
	end
end

function FSBaseMission:consoleCommandAddPallet(palletType)
	palletType = string.upper(palletType)
	local pallets = {
		WOOL = "$data/objects/pallets/woolPallet/woolPallet.xml",
		SEEDS = "$data/objects/bigBagContainer/bigBagContainerSeeds.xml",
		PIGFOOD = "$data/objects/bigBagContainer/bigBagContainerPigFood.xml",
		FERTILIZER = "$data/objects/bigBagContainer/bigBagContainerFertilizer.xml",
		LIME = "$data/objects/bigBagContainer/bigBagContainerLime.xml",
		LIQUID_FERTILIZER = "$data/objects/pallets/liquidTank/fertilizerTank.xml",
		HERBICIDE = "$data/objects/pallets/liquidTank/herbicideTank.xml",
		TREE_SAPLINGS = "$data/objects/pallets/treeSaplingPallet/treeSaplingPallet.xml",
		POPLAR = "$data/objects/pallets/palletPoplar/palletPoplar.xml",
		EGG = "$data/objects/pallets/eggBox/eggBox.xml"
	}
	local xmlFilename = pallets[palletType]

	if xmlFilename ~= nil then
		local x = 0
		local y = 0
		local z = 0
		local dirX = 1
		local dirZ = 0

		if self.controlPlayer then
			if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
				x, y, z = getWorldTranslation(self.player.rootNode)
				dirZ = -math.cos(self.player.rotY)
				dirX = -math.sin(self.player.rotY)
			end
		elseif self.controlledVehicle ~= nil then
			x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
			dirX, _, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
		end

		z = z + dirZ * 4
		x = x + dirX * 4
		y = y + 5
		xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
		local pallet = g_currentMission:loadVehicle(xmlFilename, x, nil, z, 0, 0, true, 0, Vehicle.PROPERTY_STATE_OWNED, 1, nil, )

		if pallet ~= nil then
			local fillTypeIndex = pallet:getFillUnitFirstSupportedFillType(1)

			pallet:addFillUnitFillLevel(1, 1, math.huge, fillTypeIndex, ToolType.UNDEFINED, nil)
		end
	else
		local types = ""

		for k, _ in pairs(pallets) do
			types = types .. k .. " "
		end

		return "Invalid pallet type. Valid types are " .. types
	end
end

function FSBaseMission:consoleActivateCameraPath(cameraPathIndex)
	cameraPathIndex = tonumber(cameraPathIndex)

	if cameraPathIndex == nil or cameraPathIndex < 1 or table.getn(self.cameraPaths) < cameraPathIndex then
		return "Invalid argument. Argument: cameraPathIndex"
	end

	if self.currentCameraPath ~= nil then
		self.currentCameraPath:deactivate()
	end

	self.cameraPathIsPlaying = false
	self.currentCameraPath = self.cameraPaths[cameraPathIndex]

	self.currentCameraPath:activate()

	return "Camera path activated"
end

function FSBaseMission:consoleCommandListHusbandries()
	local result = ""

	for id, husbandry in pairs(self.husbandries) do
		result = string.format("%s\n- id('%d') type('%s') subtypeCount(%d) totalAnimals(%d)", result, id, husbandry:getAnimalType(), husbandry:getNumAnimalSubTypes(), husbandry:getNumOfAnimals())
	end

	return result
end

function FSBaseMission:consoleCommandAddAnimal(husbandryId, fillTypeName)
	local husbandry = self.husbandries[tonumber(husbandryId)]

	if husbandry == nil then
		return "Husbandry not found! gsAddAnimal <husbandryId> <fillType>"
	end

	local class, fillType = g_animalManager:getClassObjectFromFillTypeName(fillTypeName)

	if class ~= nil then
		local animal = class:new(self:getIsServer(), self:getIsClient(), husbandry, fillType)

		animal:register()
		husbandry:addSingleAnimal(animal)

		return "Added animal"
	else
		return "Animal not found! gsAddAnimal <husbandryId> <fillType>"
	end
end

function FSBaseMission:consoleCommandRemoveAnimal(husbandryId, animalIndex)
	local husbandry = self.husbandries[tonumber(husbandryId)]

	if husbandry == nil then
		return "Husbandry not found! gsRemoveAnimal <husbandryId> <animalIndex>"
	end

	local animal = husbandry:getModuleByName("animals").animals[tonumber(animalIndex) or 1]

	if animal ~= nil then
		husbandry:removeAnimal(animal)

		return "Removed animal"
	end

	return "Husbandry not found! gsRemoveAnimal <husbandryId> <animalIndex>"
end

function FSBaseMission:consoleCommandToggleDebugFieldStatus(size)
	FSBaseMission.DEBUG_SHOW_FIELDSTATUS = not FSBaseMission.DEBUG_SHOW_FIELDSTATUS
	FSBaseMission.DEBUG_SHOW_FIELDSTATUS_SIZE = math.abs(Utils.getNoNil(tonumber(size), 10))

	return "ToggleFieldStatus: " .. tostring(FSBaseMission.DEBUG_SHOW_FIELDSTATUS) .. " " .. tostring(FSBaseMission.DEBUG_SHOW_FIELDSTATUS_SIZE) .. "m"
end

function FSBaseMission:consoleCommandSaveDediXMLStatsFile()
	self:updateGameStatsXML()
end

function FSBaseMission:consoleCommandSaveGame()
	self:saveSavegame()
end

function FSBaseMission:updateFoundHelpIcons()
	if self.helpIconsBase ~= nil then
		for i = 1, string.len(self.missionInfo.foundHelpIcons) do
			if string.sub(self.missionInfo.foundHelpIcons, i, i) == "1" then
				self.helpIconsBase:deleteHelpIcon(i)
			end
		end
	end
end

function FSBaseMission:removeAllHelpIcons()
	if self.helpIconsBase ~= nil then
		for i = 1, string.len(self.missionInfo.foundHelpIcons) do
			self.helpIconsBase:deleteHelpIcon(i)
		end
	end
end

function FSBaseMission:playerOwnsAllFields()
	for k, _ in pairs(g_farmlandManager:getFarmlands()) do
		g_client:getServerConnection():sendEvent(FarmlandStateEvent:new(k, 1, 0))
	end
end

function FSBaseMission:addPlaceableToDelete(placeable)
	self.placeablesToDelete[placeable] = placeable
end

function FSBaseMission:removePlaceableToDelete(placeable)
	self.placeablesToDelete[placeable] = nil
end

function FSBaseMission:broadcastEventToMasterUser(event, ignoreConnection)
	for _, user in pairs(self.userManager:getMasterUsers()) do
		local connection = user:getConnection()

		if connection ~= ignoreConnection then
			connection:sendEvent(event)
		end
	end

	event:delete()
end

function FSBaseMission:broadcastMissionDynamicInfo(connection)
	assert(self:getIsServer(), "broadcastMissionDynamicInfo call is only allowed on Server")
	self:broadcastEventToMasterUser(MissionDynamicInfoEvent:new(), connection)
end

function FSBaseMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends)
	if serverName ~= "" and g_dedicatedServerInfo == nil then
		self.missionDynamicInfo.serverName = serverName
	end

	if g_dedicatedServerInfo == nil then
		self.missionDynamicInfo.capacity = capacity
	end

	self.missionDynamicInfo.password = password
	self.missionDynamicInfo.autoAccept = autoAccept or g_dedicatedServerInfo ~= nil
	self.missionDynamicInfo.allowOnlyFriends = allowOnlyFriends

	self:updateMaxNumHirables()

	if g_dedicatedServerInfo ~= nil then
		self:updateDedicatedServerXML()
	end
end

function FSBaseMission:updateMasterServerInfo(connection)
	if self:getIsServer() then
		local userCount = self.userManager:getNumberOfUsers()

		if g_dedicatedServerInfo ~= nil then
			userCount = userCount - 1
		end

		masterServerSetServerInfo(g_currentMission.missionDynamicInfo.serverName, g_currentMission.missionDynamicInfo.password, g_currentMission.missionDynamicInfo.capacity, userCount, g_currentMission.missionDynamicInfo.allowOnlyFriends)
		self:broadcastMissionDynamicInfo(connection)
	end
end

function FSBaseMission:onMeshEvent()
	self:configureMesh()
end

function FSBaseMission:updateDedicatedServerXML()
	if g_gameServerXML ~= nil then
		setXMLString(g_gameServerXML, "gameserver.settings.game_name", self.missionDynamicInfo.serverName)
		setXMLString(g_gameServerXML, "gameserver.settings.game_password", self.missionDynamicInfo.password)
		setXMLInt(g_gameServerXML, "gameserver.settings.max_player", self.missionDynamicInfo.capacity)
		saveXMLFile(g_gameServerXML)
	end
end

function FSBaseMission:updateGameStatsXML()
	if g_dedicatedServerInfo ~= nil and g_gameStatsXMLPath ~= nil then
		local key = "Server"
		local xmlFile = createXMLFile("serverStatsFile", g_gameStatsXMLPath, key)

		if xmlFile ~= nil and xmlFile ~= 0 then
			local gameName = self.missionDynamicInfo.serverName or ""
			local mapName = "Unknown"
			local masterServer = "Unknown"

			if g_dedicatedServerInfo ~= nil then
				mapName = g_dedicatedServerInfo.selectedMap.title
				masterServer = g_dedicatedServerInfo.masterServerName
			end

			local dayTime = 0

			if self.environment ~= nil then
				dayTime = self.environment.dayTime
			end

			local mapSize = Utils.getNoNil(self.terrainSize, 2048)
			local numUsers = self.userManager:getNumberOfUsers()

			if g_dedicatedServerInfo ~= nil then
				numUsers = numUsers - 1
			end

			local capacity = self.missionDynamicInfo.capacity or 0

			setXMLString(xmlFile, key .. "#game", "Farming Simulator 20")
			setXMLString(xmlFile, key .. "#version", g_gameVersionDisplay .. g_gameVersionDisplayExtra)
			setXMLString(xmlFile, key .. "#server", masterServer)
			setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(gameName))
			setXMLString(xmlFile, key .. "#mapName", HTMLUtil.encodeToHTML(mapName))
			setXMLInt(xmlFile, key .. "#dayTime", dayTime)
			setXMLString(xmlFile, key .. "#mapOverviewFilename", NetworkUtil.convertToNetworkFilename(self.mapImageFilename))
			setXMLInt(xmlFile, key .. "#mapSize", mapSize)
			setXMLInt(xmlFile, key .. ".Slots#capacity", capacity)
			setXMLInt(xmlFile, key .. ".Slots#numUsed", numUsers)

			local i = 0

			for _, user in ipairs(self.userManager:getUsers()) do
				local player = nil
				local connection = user:getConnection()

				if connection ~= nil then
					player = self.connectionsToPlayer[connection]
				end

				if user:getId() ~= self:getServerUserId() or g_dedicatedServerInfo == nil then
					local playerKey = string.format("%s.Slots.Player(%d)", key, i)
					local playtime = (self.time - user:getConnectedTime()) / 60000

					setXMLBool(xmlFile, playerKey .. "#isUsed", true)
					setXMLBool(xmlFile, playerKey .. "#isAdmin", user:getIsMasterUser())
					setXMLInt(xmlFile, playerKey .. "#uptime", playtime)

					if player ~= nil and player.isControlled and player.rootNode ~= nil and player.rootNode ~= 0 then
						local x, y, z = getWorldTranslation(player.rootNode)

						setXMLFloat(xmlFile, playerKey .. "#x", x)
						setXMLFloat(xmlFile, playerKey .. "#y", y)
						setXMLFloat(xmlFile, playerKey .. "#z", z)
					end

					setXMLString(xmlFile, playerKey, HTMLUtil.encodeToHTML(user:getNickname(), true))

					i = i + 1
				end
			end

			for i = numUsers + 1, capacity do
				local playerKey = string.format("%s.Slots.Player(%d)", key, i)

				setXMLBool(xmlFile, playerKey .. "#isUsed", false)
			end

			local i = 0

			for _, vehicle in pairs(self.vehicles) do
				local vehicleKey = string.format("%s.Vehicles.Vehicle(%d)", key, i)

				if vehicle:saveStatsToXMLFile(xmlFile, vehicleKey) then
					i = i + 1
				end
			end

			local i = 0

			for _, mod in pairs(self.missionDynamicInfo.mods) do
				local modKey = string.format("%s.Mods.Mod(%d)", key, i)

				setXMLString(xmlFile, modKey .. "#name", HTMLUtil.encodeToHTML(mod.modName))
				setXMLString(xmlFile, modKey .. "#author", HTMLUtil.encodeToHTML(mod.author))
				setXMLString(xmlFile, modKey .. "#version", HTMLUtil.encodeToHTML(mod.version))
				setXMLString(xmlFile, modKey, HTMLUtil.encodeToHTML(mod.title, true))

				if mod.fileHash ~= nil then
					setXMLString(xmlFile, modKey .. "#hash", HTMLUtil.encodeToHTML(mod.fileHash))
				end

				i = i + 1
			end

			local i = 0

			for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
				local farmlandKey = string.format("%s.Farmlands.Farmland(%d)", key, i)

				setXMLString(xmlFile, farmlandKey .. "#name", tostring(farmland.name))
				setXMLInt(xmlFile, farmlandKey .. "#id", farmland.id)
				setXMLInt(xmlFile, farmlandKey .. "#owner", g_farmlandManager:getFarmlandOwner(farmland.id))
				setXMLFloat(xmlFile, farmlandKey .. "#area", farmland.areaInHa)
				setXMLInt(xmlFile, farmlandKey .. "#area", farmland.price)
				setXMLFloat(xmlFile, farmlandKey .. "#x", farmland.xWorldPos)
				setXMLFloat(xmlFile, farmlandKey .. "#z", farmland.zWorldPos)

				i = i + 1
			end

			i = 0

			for _, field in pairs(g_fieldManager:getFields()) do
				local fieldKey = string.format("%s.Fields.Field(%d)", key, i)

				setXMLString(xmlFile, fieldKey .. "#id", tostring(field.fieldId))
				setXMLFloat(xmlFile, fieldKey .. "#x", field.posX)
				setXMLFloat(xmlFile, fieldKey .. "#z", field.posZ)
				setXMLBool(xmlFile, fieldKey .. "#isOwned", not field.isAIActive)

				i = i + 1
			end

			saveXMLFile(xmlFile)
			delete(xmlFile)
		end
	end

	self.gameStatsTime = self.time + self.gameStatsInterval
end

function FSBaseMission:setVisibilityOfGUIComponents(state)
	self.hud:setIsVisible(state)
end

function FSBaseMission:configureMesh()
	if not self.missionDynamicInfo.isMultiplayer then
		return
	end

	if not self.meshActive then
		if self.meshEnabled then
			meshNetworkBegin("voice")

			self.meshActive = true
		else
			return
		end
	end

	meshNetworkBeginConfig()

	for _, node in pairs(self.mesh) do
		meshNetworkAddNode(node.platformNodeId, Utils.getNoNil(node.platformUserId, ""))
	end

	meshNetworkEndConfig()
end

function FSBaseMission:setConnectionLostState(state)
	self.connectionLostState = state
end

function FSBaseMission:addMapHotspot(hotspot)
	return self.hud:addMapHotspot(hotspot)
end

function FSBaseMission:removeMapHotspot(hotspot)
	self.hud:removeMapHotspot(hotspot)
end

function FSBaseMission:isInGameMessageActive()
	return self.hud:isInGameMessageActive()
end

function FSBaseMission:registerActionEvents()
	FSBaseMission:superClass().registerActionEvents(self)

	local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU, self, self.onToggleMenu, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_STORE, self, self.onToggleStore, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_MAP, self, self.onToggleMap, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	if g_isPresentationVersionUseReloadButton then
		_, eventId = self.inputManager:registerActionEvent(InputAction.RELOAD_GAME, self, self.onReloadSavegame, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	if g_soundPlayer ~= nil then
		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_TOGGLE, self, self.onToggleRadio, false, true, false, false)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)

		self.eventRadioToggle = eventId
		local radioEventsActive = self:getIsRadioPlaying()
		local radioEvents = {}
		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_PREVIOUS_CHANNEL, g_soundPlayer, g_soundPlayer.previousChannel, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_NEXT_CHANNEL, g_soundPlayer, g_soundPlayer.nextChannel, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_NEXT_ITEM, g_soundPlayer, g_soundPlayer.nextItem, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_PREVIOUS_ITEM, g_soundPlayer, g_soundPlayer.previousItem, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(radioEvents, eventId)

		self.radioEvents = radioEvents
	end

	if not self.isTutorialMission then
		_, eventId = self.inputManager:registerActionEvent(InputAction.INCREASE_TIMESCALE, self, self.onChangeTimescale, false, true, false, true, 1)

		self.inputManager:setActionEventTextVisibility(eventId, false)

		_, eventId = self.inputManager:registerActionEvent(InputAction.DECREASE_TIMESCALE, self, self.onChangeTimescale, false, true, false, true, -1)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	if self.missionDynamicInfo.isMultiplayer then
		_, eventId = self.inputManager:registerActionEvent(InputAction.CHAT, self, self.toggleChat, false, true, false, true)
	end
end

function FSBaseMission:registerPauseActionEvents()
	FSBaseMission:superClass().registerPauseActionEvents(self)
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)

	local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU, self, self.onToggleMenu, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)
	self.inputManager:endActionEventsModification()
end

function FSBaseMission:onReloadSavegame()
	if g_gamingStationManager:getIsActive() then
		OnInGameMenuMenu()
		g_gui:showGui("CareerScreen")

		return
	end

	local savegameIndex = self.missionInfo.savegameIndex
	local isSaved = self.missionInfo.isValid

	OnInGameMenuMenu()

	if isSaved then
		g_gui:setIsMultiplayer(false)
		g_gui:showGui("CareerScreen")

		g_careerScreen.selectedIndex = savegameIndex
		local savegameController = g_careerScreen.savegameController
		local savegame = savegameController:getSavegame(savegameIndex)

		if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
			return
		end

		g_careerScreen.currentSavegame = savegame

		g_careerScreen:onClickOk()

		if g_gui.currentGuiName == "ModSelectionScreen" then
			g_modSelectionScreen:onClickOk()
		end
	end
end

function FSBaseMission:onToggleMenu()
	if not self.isSynchronizingWithPlayers then
		self:updateMenuAccessibleVehicles()
		g_gui:changeScreen(nil, InGameMenu)

		if GS_IS_MOBILE_VERSION then
			self.inGameMenu:goToPage(self.inGameMenu.pageMain)
		end
	end
end

function FSBaseMission:onToggleMap()
	if not self.isSynchronizingWithPlayers then
		self:updateMenuAccessibleVehicles()
		g_gui:changeScreen(nil, InGameMenu)

		if GS_IS_MOBILE_VERSION then
			self.inGameMenu:goToPage(self.inGameMenu.pageMapOverview)
		end
	end
end

function FSBaseMission:onToggleStore()
	if not self.isSynchronizingWithPlayers then
		if not g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
			g_gui:showInfoDialog({
				text = g_i18n:getText("dialog_shopOnlyWorksInCareer")
			})
		end

		if (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and not self.isPlayerFrozen and self.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
			if GS_IS_CONSOLE_VERSION then
				self:calculateSlotUsage()
			end

			g_gui:changeScreen(nil, ShopMenu)
		end
	end
end

function FSBaseMission:toggleChat(isActive)
	if not self.isSynchronizingWithPlayers then
		if isActive == nil or isActive then
			g_gui:showGui("ChatDialog")

			isActive = true
		else
			isActive = false
		end

		self.hud:setChatWindowVisible(isActive)
	end
end

function FSBaseMission:onToggleRadio()
	local isActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)

	g_gameSettings:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, not isActive)
end

function FSBaseMission:onChangeTimescale(_, _, indexStep)
	if (self:getIsServer() or self.isMasterUser) and not g_sleepManager:getIsSleeping() then
		local timeScaleIndex = Utils.getTimeScaleIndex(self.missionInfo.timeScale)

		self:setTimeScale(Utils.getTimeScaleFromIndex(timeScaleIndex + indexStep))
	end
end

function FSBaseMission:onShowHelpIconsChanged(isVisible)
	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(isVisible)
	end
end

function FSBaseMission:onRadioVehicleOnlyChanged(isVehicleOnly)
	local isRadioPlayingSettingActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
	local canPlayRadioNow = not isVehicleOnly or isVehicleOnly and self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio

	if isRadioPlayingSettingActive then
		if canPlayRadioNow then
			if not self:getIsRadioPlaying() then
				self:playRadio()
			end
		else
			self:pauseRadio()
		end
	end
end

function FSBaseMission:onRadioIsActiveChanged(isActive)
	local isRadioPlaying = isActive

	if not isActive then
		self:pauseRadio()
	else
		local isVehicleOnly = g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)

		if not isVehicleOnly or isVehicleOnly and self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio then
			self:playRadio()
		end
	end
end

function FSBaseMission:setRadioActionEventsState(isActive)
	for _, eventId in pairs(self.radioEvents) do
		self.inputManager:setActionEventActive(eventId, isActive)
	end
end

function FSBaseMission:subscribeMessages()
	self.messageCenter:subscribe(SaveEvent, self.startSaveCurrentGame, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
	self.messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	self.messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_TRAIN_TABBABLE], self.setTrainSystemTabbable, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_ICONS], self.onShowHelpIconsChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_VEHICLE_ONLY], self.onRadioVehicleOnlyChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_IS_ACTIVE], self.onRadioIsActiveChanged, self)
	self.messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onAppSuspended, self)
	self.messageCenter:subscribe(MessageType.APP_RESUMED, self.onAppResumed, self)
end

function FSBaseMission:onAppSuspended()
	if g_isPresentationVersion and not g_isPresentationVersionSaveGameOnQuit then
		return
	end

	if not self.isLoaded then
		return
	end

	if not self.savegameController:getIsSaving() then
		self:saveSavegame(true)
	end
end

function FSBaseMission:onAppResumed()
	if not g_gui:getIsGuiVisible() then
		g_autoSaveManager:resetTime()
		g_gui:changeScreen(nil, InGameMenu)
	end
end

function FSBaseMission:notifyPlayerFarmChanged(player)
	if player == self.player then
		if self:getIsClient() and self.controlledVehicle ~= nil then
			self:onLeaveVehicle()
		end

		self.shopController:setOwnedFarmItems(self.ownedItems, self.player.farmId)
		self.shopController:setLeasedFarmItems(self.leasedVehicles, self.player.farmId)

		local farm = g_farmManager:getFarmById(self.player.farmId)

		self.inGameMenu:setPlayerFarm(farm)
		self.shopMenu:setPlayerFarm(farm)
		self.inGameMenu:onMoneyChanged(farm.farmId, farm:getBalance())
		self.shopMenu:onMoneyChanged(farm.farmId, farm:getBalance())
		self.landscapingController:setPlayerFarm(farm)
	end
end

function FSBaseMission:onUserAdded(user)
	self:updateMaxNumHirables()

	if user:getId() == self.playerUserId then
		self.inGameMenu:setCurrentUserId(self.playerUserId)
		self.shopMenu:setCurrentUserId(self.playerUserId)
		self.landscapingController:setCurrentUserId(self.playerUserId)
	end

	if user:getId() ~= g_currentMission:getServerUserId() and user:getId() ~= self.playerUserId then
		print(user:getNickname() .. " joined the game")
		g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserJoin"))
	end

	self:updateGameStatsXML()
	self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.hud:setConnectedUsers(self.userManager:getUsers())
end

function FSBaseMission:onUserRemoved(user)
	self:updateMaxNumHirables()

	if user:getId() ~= g_currentMission:getServerUserId() and user:getId() ~= self.playerUserId then
		print(user:getNickname() .. " left the game")
		g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserLeave"))
	end

	self:updateGameStatsXML()
	self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.hud:setConnectedUsers(self.userManager:getUsers())
end

function FSBaseMission:onMasterUserAdded(user)
	if user:getId() == self.playerUserId then
		self.isMasterUser = true

		if g_addCheatCommands then
			addConsoleCommand("gsCheatMoney", "Add a lot of money", "consoleCommandCheatMoney", self)
		end
	end

	if self:getIsServer() then
		g_server:broadcastEvent(UserDataEvent:new({
			user
		}))
	end
end

function FSBaseMission:broadcastEventToFarm(event, farmId, sendLocal, ignoreConnection, ghostObject, force)
	local connectionList = {}

	for streamId, connection in pairs(g_server.clientConnections) do
		local player = self.connectionsToPlayer[connection]

		if player ~= nil and player.farmId == farmId then
			connectionList[streamId] = connection
		end
	end

	g_server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList)
end

function FSBaseMission:getDefaultServerName()
	local name = ""
	local nickname = g_gameSettings:getValue("nickname")

	if g_languageShort == "pl" then
		name = nickname .. " - " .. g_i18n:getText("ui_serverNameGame")
	elseif StringUtil.endsWith(nickname, "s") then
		name = nickname .. "' " .. g_i18n:getText("ui_serverNameGame")
	elseif StringUtil.endsWith(nickname, "'") then
		name = nickname .. "s " .. g_i18n:getText("ui_serverNameGame")
	else
		name = nickname .. "'s " .. g_i18n:getText("ui_serverNameGame")
	end

	return name
end
