Mission00 = {}
local Mission00_mt = Class(Mission00, FSBaseMission)

function Mission00:new(baseDirectory, customMt, missionCollaborators)
	local mt = customMt

	if mt == nil then
		mt = Mission00_mt
	end

	local self = Mission00:superClass():new(baseDirectory, mt, missionCollaborators)
	self.renderTime = true
	self.disableCombineAI = false
	self.disableTractorAI = false
	self.messages = {}
	self.chatMessages = {}
	self.chatMessagesHistoryNum = 50
	self.objectsToCallOnMissionStarted = {}

	if g_dedicatedServerInfo ~= nil then
		self:setAutoSaveInterval(g_dedicatedServerInfo.autoSaveInterval, true)
	end

	self.isSaving = false
	g_mission00StartPoint = nil
	self.gameStarted = false
	self.loadFinishedListeners = {}
	self.mapHotspots = {}

	if g_isDevelopmentVersion then
		addConsoleCommand("gsRenderStoreIcons", "Render store icons", "consoleRenderStoreIcons", self)
	end

	return self
end

function Mission00:delete()
	if g_isDevelopmentVersion then
		removeConsoleCommand("gsRenderStoreIcons")
	end

	for _, hotspot in ipairs(self.mapHotspots) do
		self:removeMapHotspot(hotspot)
		hotspot:delete()
	end

	g_autoSaveManager:delete()

	if self.cameraFlightManager ~= nil then
		self.cameraFlightManager:update()
	end

	Mission00:superClass().delete(self)
end

function Mission00:setMissionInfo(missionInfo, missionDynamicInfo)
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, self.baseDirectory)
	self.xmlFile = loadXMLFile("MapXML", mapXMLFilename)
	self.mapWidth = Utils.getNoNil(getXMLInt(self.xmlFile, "map#width"), 2048)
	self.mapHeight = Utils.getNoNil(getXMLInt(self.xmlFile, "map#height"), 2048)
	self.mapImageFilename = Utils.getFilename(getXMLString(self.xmlFile, "map#imageFilename"), self.baseDirectory)

	setSceneBrightness(getBrightness())
	g_deferredLoadingManager:addTask(function ()
		g_storeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.STORE)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_gameplayHintManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_groundTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_ambientSoundManager:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_connectionHoseManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_fillTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_fruitTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_sprayTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_baleTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_weatherTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		if not g_animalNameManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory) then
			print("Warning: cannot load animal name manager!")
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		if not g_animalManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory) then
			print("Warning: cannot load animal manager!")
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		if not g_animalFoodManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory) then
			print("Warning: cannot load animal food manager!")
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		g_densityMapHeightManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_npcManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_helperManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		if not g_wildlifeSpawnerManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory) then
			delete(g_wildlifeSpawnerManager)

			g_wildlifeSpawnerManager = nil

			print("Warning: cannot load wildlife manager!")
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		g_treePlantManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_materialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_particleSystemManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_cutterEffectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_effectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_foliagePainter:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.DATA)
	end)

	self.cullingWorldXZOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.culling#xzOffset"), self.cullingWorldXZOffset)
	self.cullingWorldMinY = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.culling#minY"), self.cullingWorldMinY)
	self.cullingWorldMaxY = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.culling#maxY"), self.cullingWorldMaxY)
	self.mapDensityMapRevision = Utils.getNoNil(getXMLInt(self.xmlFile, "map.densityMap#revision"), 1)
	self.mapTerrainLodTextureRevision = Utils.getNoNil(getXMLInt(self.xmlFile, "map.terrainLodTexture#revision"), 1)
	self.mapSplitShapesRevision = Utils.getNoNil(getXMLInt(self.xmlFile, "map.splitShapes#revision"), 1)
	self.mapTipCollisionRevision = Utils.getNoNil(getXMLInt(self.xmlFile, "map.tipCollision#revision"), 1)
	self.mapPlacementCollisionRevision = Utils.getNoNil(getXMLInt(self.xmlFile, "map.placementCollision#revision"), 1)
	self.vertexBufferMemoryUsage = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.vertexBufferMemoryUsage"), self.vertexBufferMemoryUsage)
	self.indexBufferMemoryUsage = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.indexBufferMemoryUsage"), self.indexBufferMemoryUsage)
	self.textureMemoryUsage = Utils.getNoNil(getXMLFloat(self.xmlFile, "map.textureMemoryUsage"), self.textureMemoryUsage)

	g_deferredLoadingManager:addTask(function ()
		Mission00:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
	end)
end

function Mission00:load()
	self:startLoadingTask()
	self:loadEnvironment(self.xmlFile)

	local mapFilename = getXMLString(self.xmlFile, "map.filename")
	mapFilename = Utils.getFilename(mapFilename, self.baseDirectory)

	self:loadMap(mapFilename, true, self.loadMission00Finished, self)

	local soundFilename = Utils.getNoNil(getXMLString(self.xmlFile, "map.sounds#filename"), "$data/maps/map01_sound.xml")
	soundFilename = Utils.getFilename(soundFilename, self.baseDirectory)
	self.missionInfo.mapSoundXmlFilename = soundFilename

	self:loadMapSounds(soundFilename, self.baseDirectory)

	self.mapPerformanceTestUtil = MapPerformanceTestUtil:new()

	self.hud:setGameInfoPartVisibility(HUD.GAME_INFO_PART.MONEY + HUD.GAME_INFO_PART.TIME + HUD.GAME_INFO_PART.WEATHER)
	self.hud:setChatMessagesReference(self.chatMessages)
end

function Mission00:loadMission00Finished(node, arguments)
	if self.cancelLoading then
		return
	end

	g_deferredLoadingManager:addTask(function ()
		self:loadAdditionalFiles(self.xmlFile)
		g_materialManager:loadModMaterialHolders()
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.hud:loadIngameMap(self.mapImageFilename, self.mapWidth, self.mapHeight)
		self:loadHotspots(self.xmlFile)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.showWeatherForecast = true
	end)
	g_deferredLoadingManager:addTask(function ()
		g_farmlandManager:loadMapData(self.xmlFile)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_fieldManager:loadMapData(self.xmlFile)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_farmManager:loadMapData(self.xmlFile)

		if self.missionDynamicInfo.isMultiplayer then
			self:loadCompetitiveMultiplayer(self.xmlFile)
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		if self.missionInfo.vehiclesXMLLoad ~= nil then
			self:loadVehicles(self.missionInfo.vehiclesXMLLoad, self.missionInfo.resetVehicles)
		elseif self.missionInfo.itemsXMLLoad ~= nil then
			self:loadItems(self.missionInfo.itemsXMLLoad)
		else
			self:loadItemsFinished()
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		g_missionManager:loadMapData(self.xmlFile)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_helpLineManager:loadMapData(self.xmlFile, self.missionInfo)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_gui:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	end)
	g_deferredLoadingManager:addTask(function ()
		if g_mission00StartPoint ~= nil then
			local x, y, z = getTranslation(g_mission00StartPoint)
			local dirX, _, dirZ = localDirectionToWorld(g_mission00StartPoint, 0, 0, -1)
			self.playerStartX = x
			self.playerStartY = y
			self.playerStartZ = z
			self.playerRotX = 0
			self.playerRotY = MathUtil.getYRotationFromDirection(dirX, dirZ)
			self.playerStartIsAbsolute = true
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		g_autoSaveManager:loadFinished()
	end)
	g_deferredLoadingManager:addTask(function ()
		g_preorderBonusManager:loadFinished()
	end)
	g_deferredLoadingManager:addTask(function ()
		if not self.missionDynamicInfo.isMultiplayer then
			self:updateFoundHelpIcons()
		else
			self:removeAllHelpIcons()
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		if g_isPresentationVersion and not g_isPresentationVersionFieldJobEnabled then
			self:playerOwnsAllFields()
		end

		if not self.isTutorialMission and self.missionInfo.isNewSPCareer and self.cameraFlightManager ~= nil then
			self.cameraFlightManager:load(self.xmlFile)
		end
	end)
	g_deferredLoadingManager:addTask(function ()
		delete(self.xmlFile)

		self.xmlFile = nil
	end)
	g_deferredLoadingManager:addTask(function ()
		Mission00:superClass().load(self)

		if self.missionInfo.economyXMLLoad ~= nil then
			self:loadEconomy(self.missionInfo.economyXMLLoad)
		end
	end)

	if self:getIsServer() then
		g_deferredLoadingManager:addTask(function ()
			g_farmManager:loadFromXMLFile(self.missionInfo.farmsXMLLoad)
		end)
		g_deferredLoadingManager:addTask(function ()
			g_farmlandManager:loadFromXMLFile(self.missionInfo.farmlandXMLLoad)
		end)
		g_deferredLoadingManager:addTask(function ()
			g_npcManager:loadFromXMLFile(self.missionInfo.npcXMLLoad)
		end)
		g_deferredLoadingManager:addTask(function ()
			self.bans:loadFromXMLFile(self.missionInfo.bansXMLLoad)
		end)
	end

	g_deferredLoadingManager:addTask(function ()
		g_densityMapHeightManager:loadFromXMLFile(self.missionInfo.densityMapHeightXMLLoad)
	end)
	g_deferredLoadingManager:addTask(function ()
		g_treePlantManager:loadFromXMLFile(self.missionInfo.treePlantXMLLoad)
	end)
	g_deferredLoadingManager:addTask(function ()
		self:finishLoadingTask()
	end)
end

function Mission00:loadEnvironment(xmlFile)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.environment#filename"), self.baseDirectory)
	self.environment = Environment:new(filename)

	if self.missionInfo.environmentXMLLoad ~= nil and self:getIsServer() then
		local xmlFile = loadXMLFile("environmentXML", self.missionInfo.environmentXMLLoad)

		self.environment:loadFromXMLFile(xmlFile, "environment")
		delete(xmlFile)
	end

	self.hud:setEnvironment(self.environment)
	self.inGameMenu:setEnvironment(self.environment)
end

function Mission00:loadAdditionalFiles(xmlFile)
	local i = 0

	while true do
		local key = string.format("map.additionalFiles.additionalFile(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			return
		end

		local filename = getXMLString(xmlFile, key .. "#filename")

		if filename ~= nil then
			g_deferredLoadingManager:addSubtask(function ()
				self:loadI3D(filename)
			end)
		end

		i = i + 1
	end
end

function Mission00:loadHotspots(xmlFile)
	local i = 0

	while true do
		local key = string.format("map.hotspots.hotspot(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local mapHotspot = MapHotspot.loadFromXML(xmlFile, key, nil, self.baseDirectory)

		if mapHotspot ~= nil then
			self:addMapHotspot(mapHotspot)
			table.insert(self.mapHotspots, mapHotspot)
		end

		i = i + 1
	end
end

function Mission00:registerObjectToCallOnMissionStart(object)
	if object ~= nil then
		table.insert(self.objectsToCallOnMissionStarted, object)
	end
end

function Mission00:onStartMission()
	Mission00:superClass().onStartMission(self)
	g_gameStateManager:setGameState(GameState.PLAY)
	self.achievementManager:loadMapData()

	if self.missionInfo.isNewSPCareer and not self.missionDynamicInfo.isMultiplayer and (g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA") then
		self.showGameIntro = true
	elseif self.missionInfo.isNewSPCareer and not self.missionDynamicInfo.isMultiplayer then
		self.showTourHint = true
	else
		g_currentMission.economyManager:restartGreatDemands()
	end

	for _, object in pairs(self.objectsToCallOnMissionStarted) do
		object:onMissionStarted()
	end

	self.objectsToCallOnMissionStarted = {}
	self.gameStarted = true
end

function Mission00:getIsTourSupported()
	return self.missionInfo.difficulty == 1 and self.missionInfo.map.id == "MapUS" or GS_IS_MOBILE_VERSION
end

function Mission00:update(dt)
	if self.cameraFlightManager ~= nil then
		self.cameraFlightManager:update(dt)
	end

	Mission00:superClass().update(self, dt)

	if self.showGameIntro and not self.hud:getIsFading() then
		self.showGameIntro = false

		g_gui:showChinaAgeRatingDialog({
			text = g_i18n:getText("gameBackgroundStoryIntro"),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onClickShowGameIntro,
			target = self
		})
	end

	if self.showTourHint then
		self.showTourHint = false
		local difficulty = self.missionInfo.difficulty

		if self:getIsTourSupported() then
			if self.tourIconsBase ~= nil and not g_isPresentationVersion then
				self.tourIconsBase.startTourDialog = true
			end
		elseif difficulty == 1 then
			self.hud:showInGameMessage("", g_i18n:getText("tour_text_noTour"), -1, nil, , )
		elseif difficulty == 2 then
			self.hud:showInGameMessage("", g_i18n:getText("tour_text_noTourA"), -1, nil, , )
		else
			self.hud:showInGameMessage("", g_i18n:getText("tour_text_noTourB"), -1, nil, , )
		end
	end

	if self:getIsServer() then
		g_autoSaveManager:update(dt)
		g_preorderBonusManager:update(dt)

		self.isSaving = self.savegameController:getIsSaving()

		if (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) and not self.isSaving then
			self:tryUnpauseGame()
		end
	end
end

function Mission00:onClickShowGameIntro()
	g_gui:showControlsIntroductionDialog({
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onClickShowControlsIntroduction,
		target = self
	})
end

function Mission00:onClickShowControlsIntroduction()
	self.showTourHint = true
end

function Mission00:doPauseGame()
	Mission00:superClass().doPauseGame(self)
	self:showPauseDisplay(true)
end

function Mission00:doUnpauseGame()
	Mission00:superClass().doUnpauseGame(self)
	self:showPauseDisplay(false)
end

function Mission00:canUnpauseGame()
	return Mission00:superClass().canUnpauseGame(self) and not self.isSaving
end

function Mission00:draw()
	Mission00:superClass().draw(self)

	if self.missionDynamicInfo.isMultiplayer and self.gameStarted then
		self.hud:drawCommunicationDisplay()
	end
end

function Mission00:loadVehiclesStep(xmlFile, xmlFilename, resetVehicles)
	if self.cancelLoading then
		return false
	end

	local defaultItemsToSPFarm = Utils.getNoNil(getXMLBool(xmlFile, "vehicles#loadAnyFarmInSingleplayer"), false)

	while true do
		local vehicleI = self.loadVehiclesNextVehicleI
		self.loadVehiclesNextVehicleI = self.loadVehiclesNextVehicleI + 1
		local key = string.format("vehicles.vehicle(%d)", vehicleI)

		if not hasXMLProperty(xmlFile, key) then
			return false
		end

		local modName = getXMLString(xmlFile, key .. "#modName")
		local filename = getXMLString(xmlFile, key .. "#filename")
		local defaultProperty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#defaultFarmProperty"), false)
		local farmId = getXMLInt(xmlFile, key .. "#farmId")
		local loadForCompetitive = defaultProperty and self.missionInfo.isCompetitiveMultiplayer and g_farmManager:getFarmById(farmId) ~= nil
		local loadDefaultProperty = defaultProperty and self.missionInfo.loadDefaultFarm and not self.missionDynamicInfo.isMultiplayer and (farmId == FarmManager.SINGLEPLAYER_FARM_ID or defaultItemsToSPFarm)
		local allowedToLoad = self.missionInfo.isValid or not defaultProperty or loadDefaultProperty or loadForCompetitive

		if (modName == nil or g_modIsLoaded[modName]) and filename ~= nil and allowedToLoad then
			if loadDefaultProperty and defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
				setXMLInt(xmlFile, key .. "#farmId", FarmManager.SINGLEPLAYER_FARM_ID)
			end

			filename = NetworkUtil.convertFromNetworkFilename(filename)
			local savegame = {
				xmlFile = xmlFile,
				key = key,
				resetVehicles = resetVehicles
			}

			self:loadVehicle(filename, 0, nil, 0, 0, 0, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, savegame, self.loadVehiclesLoadVehicleFinished, self, {
				xmlFile,
				key,
				xmlFilename,
				resetVehicles
			})

			return true
		end
	end
end

function Mission00:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)
	if self.cancelLoading then
		delete(xmlFile)
		self:finishLoadingTask()

		return
	end

	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLES)

	if not resetVehicles then
		local i = 0

		while true do
			local key = string.format("vehicles.attachments(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local id = getXMLString(xmlFile, key .. "#rootVehicleId")

			if id ~= nil then
				local vehicle = self.loadVehiclesById[id]

				if vehicle ~= nil and vehicle.loadAttachmentsFromXMLFile ~= nil then
					vehicle:loadAttachmentsFromXMLFile(xmlFile, key, self.loadVehiclesById)
				end
			end

			i = i + 1
		end
	end

	g_deferredLoadingManager:addSubtask(function ()
		if self.missionInfo.itemsXMLLoad ~= nil then
			self:loadItems(self.missionInfo.itemsXMLLoad)
		end
	end)
	g_deferredLoadingManager:addSubtask(function ()
		if self.missionInfo.onCreateObjectsXMLLoad ~= nil then
			self:loadOnCreateLoadedObjects(self.missionInfo.onCreateObjectsXMLLoad)
		end
	end)
	g_deferredLoadingManager:addSubtask(function ()
		for _, listener in ipairs(self.loadFinishedListeners) do
			g_deferredLoadingManager:addSubtask(function ()
				listener:onLoadFinished()
			end)
		end
	end)
	g_deferredLoadingManager:addSubtask(function ()
		g_preorderBonusManager:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)
	end)
	g_deferredLoadingManager:addSubtask(function ()
		delete(xmlFile)
		self:finishLoadingTask()
	end)
end

function Mission00:loadItems(xmlFilename)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("IXML", xmlFilename)
		self.loadItemsById = {}
		local defaultItemsToSPFarm = Utils.getNoNil(getXMLBool(xmlFile, "items#loadAnyFarmInSingleplayer"), false)
		local i = 0

		while true do
			local key = string.format("items.item(%d)", i)
			local className = getXMLString(xmlFile, key .. "#className")
			local id = getXMLInt(xmlFile, key .. "#id")

			if className == nil then
				break
			end

			local defaultProperty = getXMLBool(xmlFile, key .. "#defaultFarmProperty")
			local farmId = getXMLInt(xmlFile, key .. "#farmId")
			local loadForCompetitive = defaultProperty and self.missionInfo.isCompetitiveMultiplayer and g_farmManager:getFarmById(farmId) ~= nil
			local loadDefaultProperty = defaultProperty and self.missionInfo.loadDefaultFarm and not self.missionDynamicInfo.isMultiplayer and (farmId == FarmManager.SINGLEPLAYER_FARM_ID or defaultItemsToSPFarm)
			local allowedToLoad = self.missionInfo.isValid or not defaultProperty or loadDefaultProperty or loadForCompetitive
			local modName = getXMLString(xmlFile, key .. "#modName")

			if (modName == nil or g_modIsLoaded[modName]) and allowedToLoad then
				local itemClass = ClassUtil.getClassObject(className)

				if itemClass ~= nil and itemClass.new ~= nil then
					g_deferredLoadingManager:addSubtask(function ()
						local item = itemClass:new(self:getIsServer(), self:getIsClient())

						if item ~= nil and item.loadFromXMLFile ~= nil and item:loadFromXMLFile(xmlFile, key) then
							if loadDefaultProperty and defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
								item:setOwnerFarmId(FarmManager.SINGLEPLAYER_FARM_ID)
							end

							item:register()
							self:addItemToSave(item)

							if id ~= nil then
								self.loadItemsById[id] = item
							end
						else
							print("Warning: corrupt savegame, item " .. i .. " with className " .. className .. " could not be loaded")
						end
					end)
				else
					print("Error: Corrupt savegame, item " .. i .. " has invalid className '" .. className .. "'")
				end
			end

			i = i + 1
		end

		g_deferredLoadingManager:addSubtask(function ()
			delete(xmlFile)
		end)
	end

	g_deferredLoadingManager:addSubtask(function ()
		self:loadItemsFinished()
	end)
end

function Mission00:loadItemsFinished()
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ITEMS)

	if self:getIsServer() then
		g_deferredLoadingManager:addTask(function ()
			g_missionManager:loadFromXMLFile(self.missionInfo.missionsXMLLoad)
		end)
		g_deferredLoadingManager:addTask(function ()
			g_farmManager:mergeObjectsForSingleplayer()
		end)
	end
end

function Mission00:loadOnCreateLoadedObjects(xmlFilename)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("onCreateLoadedObjectsXML", xmlFilename)
		local i = 0

		while true do
			local key = string.format("onCreateLoadedObjects.onCreateLoadedObject(%d)", i)
			local saveId = getXMLString(xmlFile, key .. "#saveId")

			if saveId ~= nil then
				local object = self.onCreateLoadedObjectsToSave[saveId]

				if object ~= nil then
					if object.loadFromXMLFile == nil or not object:loadFromXMLFile(xmlFile, key) then
						print("Warning: corrupt savegame, onCreateLoadedObject " .. i .. " with saveId " .. saveId .. " could not be loaded")
					end
				else
					print("Error: Corrupt savegame, onCreateLoadedObject " .. i .. " has invalid saveId '" .. saveId .. "'")
				end
			else
				local id = getXMLInt(xmlFile, key .. "#id")

				if id == nil then
					break
				end

				local object = nil

				for _, objectI in pairs(self.onCreateLoadedObjectsToSave) do
					if objectI.saveOrderIndex == id then
						object = objectI

						break
					end
				end

				if object ~= nil then
					if object.loadFromXMLFile == nil or not object:loadFromXMLFile(xmlFile, key) then
						print("Warning: corrupt savegame, onCreateLoadedObject " .. i .. " with id " .. id .. " could not be loaded")
					end
				else
					print("Error: Corrupt savegame, onCreateLoadedObject " .. i .. " has invalid id '" .. id .. "'")
				end
			end

			i = i + 1
		end

		delete(xmlFile)
	end
end

function Mission00:loadVehicles(xmlFilename, resetVehicles)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("VehiclesXML", xmlFilename)

		self:startLoadingTask()

		self.loadVehiclesNextVehicleI = 0
		self.loadVehiclesById = {}

		if not self:loadVehiclesStep(xmlFile, xmlFilename, resetVehicles) then
			self:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)
		end
	end
end

function Mission00:loadVehiclesLoadVehicleFinished(vehicle, vehicleLoadState, arguments)
	g_deferredLoadingManager:addTask(function ()
		local xmlFile, key, xmlFilename, resetVehicles = unpack(arguments)

		if self.cancelLoading then
			self:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)

			return
		end

		if vehicle ~= nil then
			if vehicleLoadState == BaseMission.VEHICLE_LOAD_ERROR then
				print("Warning: corrupt savegame, vehicle " .. vehicle.configFileName .. " could not be loaded")
				self:removeVehicle(vehicle)
			elseif vehicleLoadState == BaseMission.VEHICLE_LOAD_DELAYED then
				table.insert(self.vehiclesToSpawn, {
					xmlKey = key,
					xmlFilename = xmlFilename
				})
				self:removeVehicle(vehicle)
			else
				local id = getXMLString(xmlFile, key .. "#id")

				if id ~= nil then
					self.loadVehiclesById[id] = vehicle
				end
			end
		end

		if not self:loadVehiclesStep(xmlFile, xmlFilename, resetVehicles) then
			self:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)
		end
	end)
end

function Mission00:saveVehicleList(xmlFile, key, vehicles, usedModNames)
	local savedVehiclesToId = {}
	local curId = 1

	for _, vehicle in pairs(vehicles) do
		if vehicle.isVehicleSaved then
			local vehicleKey = string.format("%s.vehicle(%d)", key, curId - 1)

			setXMLInt(xmlFile, vehicleKey .. "#id", curId)

			savedVehiclesToId[vehicle] = curId
			vehicle.currentSavegameVehicleId = curId
			local modExtra = ""
			local modName = vehicle.customEnvironment

			if modName ~= nil then
				if usedModNames ~= nil then
					usedModNames[modName] = modName
				end

				setXMLString(xmlFile, vehicleKey .. "#modName", modName)
			end

			setXMLString(xmlFile, vehicleKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
			vehicle:saveToXMLFile(xmlFile, vehicleKey, usedModNames)

			curId = curId + 1
		end
	end

	local attachementIndex = 0

	for _, vehicle in pairs(vehicles) do
		if vehicle.isVehicleSaved and vehicle.saveAttachmentsToXMLFile ~= nil and vehicle:saveAttachmentsToXMLFile(xmlFile, string.format("%s.attachments(%d)", key, attachementIndex), savedVehiclesToId) then
			attachementIndex = attachementIndex + 1
		end
	end

	g_preorderBonusManager:saveVehicleList(xmlFile, key, vehicles, usedModNames)

	return savedVehiclesToId
end

function Mission00:saveVehicles(xmlFile, key, usedModNames)
	self:saveVehicleList(xmlFile, key, self.vehicles, usedModNames)
end

function Mission00:saveOnCreateObjects(xmlFile, key, usedModNames)
	local index = 0

	for id, object in pairs(self.onCreateLoadedObjectsToSave) do
		local objectKey = string.format("%s.onCreateLoadedObject(%d)", key, index)

		setXMLString(xmlFile, objectKey .. "#saveId", id)
		object:saveToXMLFile(xmlFile, objectKey, usedModNames)

		index = index + 1
	end
end

function Mission00:saveItems(xmlFile, key, usedModNames)
	local itemToSave = {}

	for _, item in pairs(self.itemsToSave) do
		table.insert(itemToSave, item)

		item.item.currentSavegameItemId = #itemToSave
	end

	for index, item in ipairs(itemToSave) do
		if item.item.getNeedsSaving == nil or item.item:getNeedsSaving() then
			local itemKey = string.format("%s.item(%d)", key, index - 1)

			setXMLString(xmlFile, itemKey .. "#className", item.className)
			setXMLInt(xmlFile, itemKey .. "#id", index)

			local modName = item.item.customEnvironment
			local classModName = ClassUtil.getClassModName(item.className)

			if modName == nil then
				modName = classModName
			end

			if modName ~= nil then
				if usedModNames ~= nil then
					usedModNames[modName] = modName
				end

				setXMLString(xmlFile, itemKey .. "#modName", modName)
			end

			if classModName ~= nil and usedModNames ~= nil then
				usedModNames[classModName] = classModName
			end

			item.item:saveToXMLFile(xmlFile, itemKey, usedModNames)
		end
	end
end

function Mission00:onCreateStartPoint(id)
	g_mission00StartPoint = id
end

function Mission00:addChatMessage(sender, msg)
	self:setLastChatMessageTime()

	while self.chatMessagesHistoryNum <= table.getn(self.chatMessages) do
		table.remove(self.chatMessages, 1)
	end

	table.insert(self.chatMessages, {
		msg = msg,
		sender = sender
	})
	self.hud:setChatWindowVisible(true, true)
end

function Mission00:setLastChatMessageTime()
	self.lastChatMessageTime = g_currentMission.time
end

function Mission00:scrollChatMessages(delta)
	self.hud:scrollChatMessages(delta, #self.chatMessages)
end

function Mission00:loadEconomy(xmlFilename)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("economyXML", xmlFilename)

		g_currentMission.economyManager:loadFromXMLFile(xmlFile, "economy")
		delete(xmlFile)
	end
end

function Mission00:addLoadFinishedListener(listener)
	ListUtil.addElementToList(self.loadFinishedListeners, listener)
end

function Mission00:removeLoadFinishedListener(listener)
	ListUtil.removeElementFromList(self.loadFinishedListeners, listener)
end

function Mission00:consoleRenderStoreIcons(name)
	local visibleNodes = {}
	local rootNode = getRootNode()
	local numChildren = getNumOfChildren(rootNode)

	for i = 0, numChildren - 1 do
		local node = getChildAt(rootNode, i)

		if getVisibility(node) then
			setVisibility(node, false)
			table.insert(visibleNodes, node)
		end
	end

	local lightSource = createLightSource("light", "directional", 1, 1, 1, 10000)

	setRotation(lightSource, math.rad(-70), 0, math.rad(-30))
	setUseLightScattering(lightSource, true)

	local dx, dy, dz = localDirectionToWorld(lightSource, 0, 0, 1)

	setLightScatteringDirection(lightSource, dx, dy, dz)
	setLightShadowMap(lightSource, true, 2048)
	link(rootNode, lightSource)

	local totalRot = math.rad(0)
	local x = 0
	local y = 0
	local z = 0
	local camCenter = createTransformGroup("center")
	local camera = createCamera("iconsCam", math.rad(60), 0.1, 100)

	link(camCenter, camera)
	setTranslation(camera, 0, 0, 10)
	setTranslation(camCenter, x, y + 2, z)
	setRotation(camCenter, math.rad(-30), math.rad(45) + totalRot, 0)

	local oldCam = getCamera()

	setCamera(camera)

	local storeItems = g_storeManager:getItems()

	for _, storeItem in pairs(storeItems) do
		local items = {}

		if storeItem.bundleInfo ~= nil then
			for _, item in pairs(storeItem.bundleInfo.bundleItems) do
				table.insert(items, {
					xmlFilename = item.xmlFilename,
					x = x + item.offset[1],
					y = y + item.offset[2],
					z = z + item.offset[2],
					yRot = item.rotation + totalRot
				})
			end
		else
			table.insert(items, {
				xmlFilename = storeItem.xmlFilename,
				x = x,
				y = y,
				z = z,
				yRot = totalRot
			})
		end

		for _, item in pairs(items) do
			item.vehicle = self:loadVehicle(item.xmlFilename, item.x, item.y, item.z, 0, item.yRot, false, 0, Vehicle.PROPERTY_STATE_OWNED, 1, {}, savegameData, nil, , )
		end

		local iconFilename = items[1].xmlFilename
		local lastSlash = iconFilename:find("/[^/]*$")

		if lastSlash ~= nil then
			local filename = iconFilename:sub(lastSlash + 1, iconFilename:len() - 4)
			iconFilename = iconFilename:sub(1, lastSlash) .. "store_" .. filename .. ".png"
		else
			local filename = iconFilename:sub(1, iconFilename:len() - 4)
			iconFilename = iconFilename .. "store_" .. filename .. ".png"
		end

		print(iconFilename)
		renderScreenshot(iconFilename, 1024, 1024, 1, "raw_alpha", 1, 0, 0, 0, 0, 0, 15, false, 0)

		for _, item in pairs(items) do
			if item.vehicle ~= nil then
				item.vehicle:delete()
			end
		end

		break
	end

	setCamera(oldCam)
	delete(camCenter)
	delete(lightSource)

	for _, node in pairs(visibleNodes) do
		setVisibility(node, true)
	end
end

function Mission00:loadCompetitiveMultiplayer(xmlFile)
	local filename = getXMLString(xmlFile, "map.competitiveMultiplayer#filename")

	if filename == nil or not self:getIsServer() then
		return
	end

	filename = Utils.getFilename(filename, self.baseDirectory)

	if not self.missionInfo.isValid then
		local xmlFile = loadXMLFile("CompetitiveXML", filename)
		local i = 0

		while true do
			local farmKey = string.format("competitiveMultiplayer.farms.farm(%d)", i)

			if not hasXMLProperty(xmlFile, farmKey) then
				break
			end

			local farmId = getXMLInt(xmlFile, farmKey .. "#farmId")
			local name = getXMLString(xmlFile, farmKey .. "#name")
			local color = getXMLInt(xmlFile, farmKey .. "#color")
			local farm = g_farmManager:createFarm(name, color, nil, farmId)

			if farm ~= nil then
				local money = getXMLFloat(xmlFile, farmKey .. "#money")

				if money ~= nil then
					farm.money = money
				end

				local loan = getXMLFloat(xmlFile, farmKey .. "#loan")

				if loan ~= nil then
					farm.loan = loan
				end
			end

			i = i + 1
		end

		delete(xmlFile)
	end

	self.missionInfo.isCompetitiveMultiplayer = true
end
