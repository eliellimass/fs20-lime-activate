source("dataS/scripts/events/VehicleRemoveEvent.lua")
source("dataS/scripts/events/OnCreateLoadedObjectEvent.lua")

BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.STATE_CONTINUED = 6
BaseMission.VEHICLE_LOAD_OK = 1
BaseMission.VEHICLE_LOAD_ERROR = 2
BaseMission.VEHICLE_LOAD_DELAYED = 3
BaseMission.VEHICLE_LOAD_NO_SPACE = 4
BaseMission.TOTAL_VRAM = 2724200448.0
BaseMission.TOTAL_NUM_GARAGE_SLOTS = 1299
BaseMission.VRAM_USAGE_PER_SLOT = BaseMission.TOTAL_VRAM / BaseMission.TOTAL_NUM_GARAGE_SLOTS
BaseMission.INPUT_CONTEXT_VEHICLE = "VEHICLE"
BaseMission.INPUT_CONTEXT_PAUSE = "PAUSE"
BaseMission.INPUT_CONTEXT_SYNCHRONIZING = "MP_SYNC"
BaseMission.allowPhysicsPausing = true

function BaseMission:new(baseDirectory, customMt, missionCollaborators)
	local self = {}

	if customMt ~= nil then
		setmetatable(self, customMt)
	else
		setmetatable(self, BaseMission_mt)
	end

	self.baseDirectory = baseDirectory
	self.server = missionCollaborators.server
	self.client = missionCollaborators.client
	self.messageCenter = missionCollaborators.messageCenter
	self.savegameController = missionCollaborators.savegameController
	self.inputManager = missionCollaborators.inputManager
	self.inputDisplayManager = missionCollaborators.inputDisplayManager
	self.achievementManager = missionCollaborators.achievementManager
	self.modManager = missionCollaborators.modManager
	self.fillTypeManager = missionCollaborators.fillTypeManager
	self.fruitTypeManager = missionCollaborators.fruitTypeManager
	self.guiSoundPlayer = missionCollaborators.guiSoundPlayer
	self.guiTopDownCamera = missionCollaborators.guiTopDownCamera
	self.bans = missionCollaborators.banStorage
	self.hud = nil
	self.isTutorialMission = false
	self.cancelLoading = false
	self.vertexBufferMemoryUsage = 0
	self.indexBufferMemoryUsage = 0
	self.textureMemoryUsage = 0
	self.waitForDLCVerification = false
	self.waitForCorruptDlcs = false
	self.physicsPaused = false
	self.firstTimeRun = false
	self.waterY = -200
	self.isInsideBuilding = false
	self.players = {}
	self.connectionsToPlayer = {}
	self.updateables = {}
	self.nonUpdateables = {}
	self.drawables = {}
	self.currentTipTrigger = nil
	self.tipTriggers = {}
	self.siloTriggers = {}
	self.trailerTipTriggers = {}
	self.boughtVehiclesToLoad = {}
	self.triggerMarkers = {}
	self.dynamicallyLoadedObjects = {}
	self.isPlayerFrozen = false
	self.environment = nil
	self.tipTriggerRangeThreshold = 1
	self.isTipTriggerInRange = false
	self.state = BaseMission.STATE_INTRO
	self.endDelayTime = 5000
	self.endTimeStamp = 0
	self.isRunning = false
	self.isLoaded = false
	self.numLoadingTasks = 0
	self.isMissionStarted = false
	self.controlledVehicle = nil
	self.controlledVehicles = {}
	self.controlPlayer = true
	self.storeIsActive = false
	self.isToggleVehicleAllowed = true
	self.slotUsage = 0
	self.vehicles = {}
	self.enterables = {}
	self.interactiveVehicles = {}
	self.attachables = {}
	self.placeables = {}
	self.objectToRailroadVehicle = {}
	self.ownedItems = {}
	self.leasedVehicles = {}
	self.vehiclesToDelete = {}
	self.loadSpawnPlaces = {}
	self.storeSpawnPlaces = {}
	self.restrictedZones = {}
	self.usedLoadPlaces = {}
	self.usedStorePlaces = {}
	self.vehiclesToSpawn = {}
	self.nodeToObject = {}
	self.itemsToSave = {}
	self.onCreateLoadedObjectsToSave = {}
	self.onCreateLoadedObjectsToSaveByIndex = {}
	self.numOnCreateLoadedObjectsToSave = 0
	self.maps = {}
	self.surfaceSounds = {}
	self.cuttingSounds = {}
	self.mountThreshold = 6
	self.preSimulateTime = 4000
	self.disableCombineAI = true
	self.disableTractorAI = true
	self.snapAIDirection = true

	if GS_IS_CONSOLE_VERSION then
		self.maxNumHirables = 6
	elseif GS_IS_MOBILE_VERSION then
		self.maxNumHirables = 6
	else
		self.maxNumHirables = 10
	end

	self.time = 0
	self.missionTime = 0
	self.activatableObjects = {}
	self.activateListeners = {}
	self.pauseListeners = {}
	self.paused = false
	self.pressStartPaused = false
	self.manualPaused = false
	self.suspendPaused = false
	self.lastNonPauseGameState = GameState.PLAY
	self.isLoadingMap = false
	self.numLoadingMaps = 0
	self.loadingMapBaseDirectory = ""
	self.onCreateLoadedObjects = {}
	self.objectsToClassName = {}
	self.vehiclesToAttach = {}
	self.lastInteractionTime = -1
	self.isExitingGame = false
	self.eventActivateObject = ""

	return self
end

function BaseMission:initialize()
	self:subscribeSettingsChangeMessages()
	self:subscribeGuiOpenCloseMessages()
	self.messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChange, self)

	self.hud = self:createHUD()

	self.guiTopDownCamera:setHUD(self.hud)
end

function BaseMission:createHUD()
	local hud = g_hudClass.new(self.server ~= nil, self.client ~= nil, GS_IS_CONSOLE_VERSION, self.messageCenter, g_i18n, self.inputManager, self.inputDisplayManager, self.modManager, self.fillTypeManager, self.fruitTypeManager, self.guiSoundPlayer, self, g_farmManager, g_farmlandManager)

	return hud
end

function BaseMission:delete()
	self.messageCenter:unsubscribeAll(self)

	self.isExitingGame = true
	self.isRunning = false

	self:setMapTargetHotspot(nil)

	if BaseMission.MAP_TARGET_MARKER ~= nil then
		delete(BaseMission.MAP_TARGET_MARKER)

		BaseMission.MAP_TARGET_MARKER = nil
	end

	if self:getIsClient() and not self.controlPlayer and self.controlledVehicle ~= nil then
		self:onLeaveVehicle()
	end

	if g_server ~= nil then
		g_server:delete()

		g_server = nil
	end

	if g_client ~= nil then
		g_client:delete()

		g_client = nil
	end

	self.guiTopDownCamera:reset()
	setCamera(g_defaultCamera)
	self.messageCenter:unsubscribeAll(self.hud)
	self.hud:delete()

	if self.player ~= nil then
		self.player:delete()
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
		self.trafficSystem:reset()
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(false)
	end

	g_terrainDeformationQueue:cancelAllJobs()

	for _, v in pairs(self.vehicles) do
		v:delete()
	end

	self.vehicles = {}
	self.leasedVehicles = {}
	self.ownedItems = {}

	for _, vehicle in ipairs(self.vehiclesToDelete) do
		vehicle:delete()

		if not vehicle.isDeleted then
			vehicle:delete()
		end
	end

	for _, item in pairs(self.itemsToSave) do
		item.item:delete()
	end

	for _, object in pairs(self.dynamicallyLoadedObjects) do
		delete(object)
	end

	if self.environment ~= nil then
		self.environment:delete()

		self.environment = nil
	end

	for _, v in pairs(self.updateables) do
		v:delete()
	end

	for _, v in pairs(self.nonUpdateables) do
		v:delete()
	end

	for i = #g_modEventListeners, 1, -1 do
		if g_modEventListeners[i].deleteMap ~= nil then
			g_modEventListeners[i]:deleteMap()
		end
	end

	for _, v in pairs(self.maps) do
		delete(v)
	end

	for _, surfaceSound in pairs(self.surfaceSounds) do
		g_soundManager:deleteSample(surfaceSound.sample)
	end

	self.surfaceSounds = {}
	self.cuttingSounds = {}

	self:unregisterActionEvents()
	removeConsoleCommand("gsSetFOV")
	removeConsoleCommand("gsRender360Screenshot")
	removeConsoleCommand("gsTakeEnvProbes")
	removeConsoleCommand("gsTakeVehicleScreenshotsFromOutside")
	removeConsoleCommand("gsTakeVehicleScreenshotsFromInside")
	removeConsoleCommand("gsDeleteAllVehicles")
	self.inputManager:clearAllContexts()
end

function BaseMission:load()
	self:startLoadingTask()

	self.controlPlayer = true
	self.controlledVehicle = nil

	addConsoleCommand("gsSetFOV", "Sets camera field of view angle", "consoleCommandSetFOV", self)

	if self:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsRender360Screenshot", "Renders 360 screenshots from current camera position", "consoleCommandRender360Screenshot", self)
		addConsoleCommand("gsTakeEnvProbes", "Takes env. probes from current camera position", "consoleCommandTakeEnvProbes", self)
		addConsoleCommand("gsTakeVehicleScreenshotsFromOutside", "Takes several screenshots of the selected vehicle from outside", "consoleCommandTakeScreenshotsFromOutside", self)
		addConsoleCommand("gsTakeVehicleScreenshotsFromInside", "Takes several screenshots of the selected vehicle from inside", "consoleCommandTakeScreenshotsFromInside", self)
		addConsoleCommand("gsDeleteAllVehicles", "Deletes all vehicles", "consoleCommandDeleteAllVehicles", self)
	end

	self:finishLoadingTask()
end

function BaseMission:startLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks + 1

	if self.numLoadingTasks == 1 then
		setStreamLowPriorityI3DFiles(false)

		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(false)
		end
	end
end

function BaseMission:finishLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks - 1

	if self.numLoadingTasks <= 0 then
		if not self.isLoaded then
			self:onFinishedLoading()
		end

		setStreamLowPriorityI3DFiles(true)

		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(true)
		end
	end
end

function BaseMission:onFinishedLoading()
	self.isLoaded = true

	g_gui:setCurrentMission(self)
	g_gui:setClient(g_client)
end

function BaseMission:canStartMission()
	if self:getIsServer() then
		return true
	end

	return self.player ~= nil
end

function BaseMission:onStartMission()
	self:fadeScreen(-1, 1500, nil)

	self.isMissionStarted = true

	self:setShowTriggerMarker(g_gameSettings:getValue("showTriggerMarker"))

	if self:getIsClient() then
		local context = Player.INPUT_CONTEXT_NAME

		if GS_IS_MOBILE_VERSION and self.missionInfo.isNewSPCareer then
			context = Vehicle.INPUT_CONTEXT_NAME
		end

		self.inputManager:setContext(context, true, true)
		self:registerActionEvents()
		self:registerPauseActionEvents()
	end
end

function BaseMission:onObjectCreated(object)
	if object:isa(Player) then
		self.players[object.rootNode] = object

		if object.isOwner then
			self.player = object

			self.inGameMenu:setPlayer(object)
			self.hud:setPlayer(object)
		end

		if self:getIsServer() then
			self.connectionsToPlayer[object.networkInformation.creatorConnection] = object
		end

		g_messageCenter:publish(MessageType.PLAYER_CREATED, object)
	elseif object:isa(Vehicle) or object:isa(RailroadVehicle) then
		self:addVehicle(object)
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectCreated(object)
	end
end

function BaseMission:onObjectDeleted(object)
	if object:isa(Player) then
		if self.player == object then
			self.player = nil
		end

		self.players[object.rootNode] = nil

		if self:getIsServer() then
			self.connectionsToPlayer[object.networkInformation.creatorConnection] = nil
		end
	elseif object:isa(Vehicle) or object:isa(RailroadVehicle) then
		if object.isAddedToMission then
			self:removeVehicle(object, false)
		end
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectDeleted(object)
	end
end

function BaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if addPhysics == nil then
		addPhysics = true
	end

	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(filename)

	if self.numLoadingMaps == 0 then
		self.loadingMapModName = modName
		self.loadingMapBaseDirectory = baseDirectory

		resetModOnCreateFunctions()

		for modName, loaded in pairs(g_modIsLoaded) do
			if loaded and not g_modManager:isModMap(modName) then
				_G[modName].g_onCreateUtil.activateOnCreateFunctions()
			end
		end

		if modName ~= nil then
			_G[modName].g_onCreateUtil.activateOnCreateFunctions()
		end

		self.isLoadingMap = true
	elseif self.loadingMapBaseDirectory ~= baseDirectory then
		print("Warning: Asynchronous map loading from different mods. onCreate functions will not work correctly")
	end

	self.numLoadingMaps = self.numLoadingMaps + 1

	if asyncCallbackFunction ~= nil then
		streamI3DFile(filename, "loadMapFinished", self, {
			filename,
			asyncCallbackFunction,
			asyncCallbackObject,
			asyncCallbackArguments
		}, addPhysics, true, true)
	else
		local node = loadI3DFile(filename, addPhysics)

		self:loadMapFinished(node, {
			filename
		})

		return node
	end
end

function BaseMission:loadMapFinished(node, arguments, callAsyncCallback)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.MAP)

	local filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	if node ~= 0 then
		self:findDynamicObjects(node)
	end

	self.numLoadingMaps = self.numLoadingMaps - 1

	if self.numLoadingMaps == 0 then
		self.isLoadingMap = false

		resetModOnCreateFunctions()

		self.loadingMapModName = nil
		self.loadingMapBaseDirectory = ""
	end

	if node ~= 0 then
		if not g_currentMission.cancelLoading then
			table.insert(self.maps, node)
			link(getRootNode(), node)
		end
	else
		print("Error: failed to load map " .. filename)
	end

	if self.environment.water ~= nil then
		local _, y, _ = getWorldTranslation(self.environment.water)
		self.waterY = y

		self.guiTopDownCamera:setWaterLevelHeight(y)
	end

	for _, v in pairs(g_modEventListeners) do
		if v.loadMap ~= nil then
			v:loadMap(filename)
		end
	end

	self:setShowFieldInfo(g_gameSettings:getValue("showFieldInfo"))

	if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, node, asyncCallbackArguments)
	end
end

function BaseMission:findDynamicObjects(node)
	for i = 1, getNumOfChildren(node) do
		local c = getChildAt(node, i - 1)

		if getRigidBodyType(c) == "Dynamic" then
			if (not getHasClassId(c, ClassIds.SHAPE) or getSplitType(c) == 0) and self.missionDynamicInfo.isMultiplayer then
				local mpCreatePhysicsObject = Utils.getNoNil(getUserAttribute(c, "mpCreatePhysicsObject"), false)
				local mpRemoveRigidBody = Utils.getNoNil(getUserAttribute(c, "mpRemoveRigidBody"), true)

				if mpCreatePhysicsObject then
					local object = PhysicsObject:new(self:getIsServer(), self:getIsClient())

					g_currentMission:addOnCreateLoadedObject(object)
					object:loadOnCreate(c)
					object:register(true)
				elseif mpRemoveRigidBody then
					setRigidBodyType(c, "NoRigidBody")
				end
			end
		elseif g_buildTypeParam == "CHINA_GAPP" and getName(c) == "liquidManurePump" then
			setVisibility(c, false)
		else
			self:findDynamicObjects(c)
		end
	end
end

function BaseMission:loadMapSounds(xmlFilename, baseDirectory)
	if not self:getIsClient() then
		return
	end

	local xmlFile = loadXMLFile("mapSoundXML", xmlFilename)
	self.surfaceSounds = {}
	local i = 0

	while true do
		local key = string.format("sound.surface.material(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local entry = {
			type = Utils.getNoNil(getXMLString(xmlFile, key .. "#type"), "wheel"),
			materialId = getXMLInt(xmlFile, key .. "#materialId"),
			name = getXMLString(xmlFile, key .. "#name")
		}
		local loopCount = getXMLInt(xmlFile, key .. "#loopCount") or 0
		entry.sample = g_soundManager:loadSampleFromXML(xmlFile, "sound.surface", string.format("material(%d)", i), baseDirectory, getRootNode(), loopCount, AudioGroup.ENVIRONMENT, nil, )

		table.insert(self.surfaceSounds, entry)

		i = i + 1
	end

	self.cuttingSounds = {}
	local j = 0

	while true do
		local key = string.format("sound.cutting.sample(%d)", j)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local entry = {
			name = getXMLString(xmlFile, key .. "#name")
		}

		if entry.name ~= nil then
			self.cuttingSounds[entry.name] = entry
		else
			print("Warning: a cutting sound does not have a name")
		end

		j = j + 1
	end

	delete(xmlFile)
end

function BaseMission:addLoadVehicleToList(list, filename, x, yOffset, z, yRot, save, varName, varObject, ownerFarmId, configurations)
	table.insert(list, {
		filename = filename,
		x = x,
		yOffset = yOffset,
		z = z,
		yRot = yRot,
		save = save,
		varName = varName,
		varObject = varObject,
		ownerFarmId = Utils.getNoNil(farmId, AccessHandler.EVERYONE),
		configurations = Utils.getNoNil(configurations, {})
	})
end

function BaseMission:loadVehiclesFromList(list, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if table.getn(list) == 0 or self.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, asyncCallbackArguments)

		return
	end

	local a = list[1]

	self:loadVehicle(a.filename, a.x, nil, a.z, a.yOffset, a.yRot, a.save, 0, Vehicle.PROPERTY_STATE_NONE, a.ownerFarmId, a.configurations, nil, self.loadVehiclesFromListFinished, self, {
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments,
		list
	})
end

function BaseMission:loadVehiclesFromListFinished(vehicle, vehicleLoadState, arguments)
	local asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, list = unpack(arguments)

	if vehicle == nil then
		asyncCallbackFunction(asyncCallbackObject, vehicleLoadState, asyncCallbackArguments)

		return
	end

	vehicle:register()

	local a = list[1]

	if a.varObject ~= nil and a.varName ~= nil then
		a.varObject[a.varName] = vehicle
	end

	table.remove(list, 1)

	if table.getn(list) == 0 or self.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, asyncCallbackArguments)

		return
	end

	local a = list[1]

	self:loadVehicle(a.filename, a.x, nil, a.z, a.yOffset, a.yRot, a.save, 0, Vehicle.PROPERTY_STATE_NONE, a.ownerFarmId, a.configurations, nil, self.loadVehiclesFromListFinished, self, arguments)
end

function BaseMission:loadVehicle(filename, x, y, z, yOffset, yRot, save, price, propertyState, ownerFarmId, configurations, savegameData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if self.cancelLoading then
		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, BaseMission.VEHICLE_LOAD_OK, asyncCallbackArguments)
		end

		return
	end

	if not self:getIsServer() then
		print("Error: loadVehicle is only allowed on a server")
		printCallstack()

		return
	end

	if g_storeManager:getItemByXMLFilename(filename) == nil then
		print("Error: loadVehicle can only load existing store items")

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, BaseMission.VEHICLE_LOAD_ERROR, asyncCallbackArguments)
		end

		return
	end

	local xmlFile = loadXMLFile("TempConfig", filename)
	local typeName = getXMLString(xmlFile, "vehicle#type")
	configurations = Utils.getNoNil(configurations, {})

	if configurations ~= nil and savegameData ~= nil and savegameData.xmlFile ~= 0 then
		local i = 0

		while true do
			local key = string.format(savegameData.key .. ".configuration(%d)", i)

			if not hasXMLProperty(savegameData.xmlFile, key) then
				break
			end

			local name = getXMLString(savegameData.xmlFile, key .. "#name")
			local id = getXMLInt(savegameData.xmlFile, key .. "#id")
			configurations[name] = id
			i = i + 1
		end
	end

	if configurations ~= nil and configurations.vehicleType ~= nil then
		local storeItem = g_storeManager:getItemByXMLFilename(filename)

		if storeItem.configurations ~= nil and storeItem.configurations.vehicleType then
			typeName = storeItem.configurations.vehicleType[configurations.vehicleType].vehicleType
		end
	end

	delete(xmlFile)

	local ret = nil
	local vehicleLoadState = BaseMission.VEHICLE_LOAD_OK

	if typeName == nil then
		print("Error loadVehicle: invalid vehicle config file '" .. filename .. "', no type specified")
	else
		local typeDef = g_vehicleTypeManager:getVehicleTypeByName(typeName)
		local modName, _ = Utils.getModNameAndBaseDirectory(filename)

		if modName ~= nil then
			if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
				print("Error: Mod '" .. modName .. "' of vehicle '" .. filename .. "'")
				print("       is not loaded. This vehicle will not be loaded.")

				if asyncCallbackFunction ~= nil then
					asyncCallbackFunction(asyncCallbackObject, nil, BaseMission.VEHICLE_LOAD_ERROR, asyncCallbackArguments)
				end

				return
			end

			if typeDef == nil then
				typeName = modName .. "." .. typeName
				typeDef = g_vehicleTypeManager:getVehicleTypeByName(typeName)
			end
		end

		if typeDef == nil then
			print("Error loadVehicle: unknown type '" .. typeName .. "' in '" .. filename .. "'")
		else
			local vehicleClass = ClassUtil.getClassObject(typeDef.className)

			if vehicleClass ~= nil then
				local vehicle = vehicleClass:new(self:getIsServer(), self:getIsClient())
				local vehicleData = {
					filename = filename,
					isAbsolute = false,
					typeName = typeName,
					price = price,
					propertyState = propertyState,
					ownerFarmId = ownerFarmId,
					posX = x,
					posY = y,
					posZ = z,
					yOffset = yOffset,
					rotX = 0,
					rotY = yRot,
					rotZ = 0,
					isVehicleSaved = save,
					configurations = configurations
				}

				if savegameData ~= nil then
					vehicleData.savegame = {
						xmlFile = savegameData.xmlFile,
						key = savegameData.key,
						resetVehicles = savegameData.resetVehicles,
						keepPosition = savegameData.keepPosition
					}
				end

				if asyncCallbackFunction ~= nil then
					vehicle:load(vehicleData, self.loadVehicleFinished, self, {
						asyncCallbackFunction,
						asyncCallbackObject,
						asyncCallbackArguments
					})
				else
					vehicleLoadState = vehicle:load(vehicleData)

					if (vehicleLoadState == BaseMission.VEHICLE_LOAD_OK or vehicleLoadState == BaseMission.VEHICLE_LOAD_DELAYED) and vehicle.rootNode ~= nil then
						vehicle:register()
					end
				end

				ret = vehicle
			end
		end
	end

	if asyncCallbackFunction ~= nil then
		if ret == nil then
			asyncCallbackFunction(asyncCallbackObject, nil, BaseMission.VEHICLE_LOAD_ERROR, asyncCallbackArguments)
		else
			return ret
		end
	else
		return ret, vehicleLoadState
	end
end

function BaseMission:loadVehicleFinished(vehicle, vehicleLoadState, arguments)
	local asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	if vehicle ~= nil then
		vehicle:register()
	end

	asyncCallbackFunction(asyncCallbackObject, vehicle, vehicleLoadState, asyncCallbackArguments)
end

function BaseMission:loadVehicleFromXML(xmlFile, key, resetVehicle, allowDelayed, xmlFilename, keepPosition)
	local filename = getXMLString(xmlFile, key .. "#filename")

	if filename ~= nil then
		filename = NetworkUtil.convertFromNetworkFilename(filename)

		if keepPosition == nil then
			keepPosition = false
		end

		local vehicle, vehicleLoadState = self:loadVehicle(filename, 0, nil, 0, 0, 0, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, {
			xmlFile = xmlFile,
			key = key,
			resetVehicles = resetVehicle,
			keepPosition = keepPosition
		})

		if vehicle ~= nil then
			if vehicleLoadState == BaseMission.VEHICLE_LOAD_ERROR then
				self:removeVehicle(vehicle)

				return BaseMission.VEHICLE_LOAD_ERROR
			elseif vehicleLoadState == BaseMission.VEHICLE_LOAD_DELAYED then
				self:removeVehicle(vehicle)

				if allowDelayed and xmlFilename ~= nil then
					table.insert(self.vehiclesToSpawn, {
						xmlKey = key,
						xmlFilename = xmlFilename
					})

					return BaseMission.VEHICLE_LOAD_DELAYED
				else
					return BaseMission.VEHICLE_LOAD_ERROR
				end
			else
				return vehicleLoadState, vehicle
			end
		end
	end

	return BaseMission.VEHICLE_LOAD_ERROR
end

function BaseMission:loadVehiclesAtPlace(storeItem, places, usedPlaces, configurations, price, propertyState, ownerFarmId, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local sizeWidth, sizeLength, widthOffset, lengthOffset = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation, configurations)
	local boughtVehiclesToLoad = {
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}
	self.boughtVehiclesToLoad[asyncCallbackArguments.targetOwner] = boughtVehiclesToLoad
	local x, _, z, place, width, offset = PlacementUtil.getPlace(places, sizeWidth, sizeLength, widthOffset, lengthOffset, usedPlaces, true, false, true)

	if x == nil then
		self:loadVehiclesAtPlaceFinished(asyncCallbackArguments.targetOwner, BaseMission.VEHICLE_LOAD_NO_SPACE)

		return
	end

	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + storeItem.rotation
	local items = {}

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in pairs(storeItem.bundleInfo.bundleItems) do
			local itemConfigurations = {}

			for name, index in pairs(configurations) do
				if bundleItem.item.configurations[name] ~= nil then
					itemConfigurations[name] = index
				end
			end

			table.insert(items, {
				xmlFilename = bundleItem.xmlFilename,
				x = x,
				z = z,
				yRot = yRot,
				yOffset = offset,
				offset = bundleItem.offset,
				rotation = bundleItem.rotation,
				price = bundleItem.price,
				propertyState = propertyState,
				ownerFarmId = ownerFarmId,
				configurations = itemConfigurations
			})
		end
	else
		table.insert(items, {
			rotation = 0,
			xmlFilename = storeItem.xmlFilename,
			x = x,
			z = z,
			yRot = yRot,
			yOffset = offset,
			offset = {
				0,
				0,
				0
			},
			price = price,
			propertyState = propertyState,
			ownerFarmId = ownerFarmId,
			configurations = configurations
		})
	end

	boughtVehiclesToLoad.storeItem = storeItem
	boughtVehiclesToLoad.loadedVehicles = {}
	boughtVehiclesToLoad.vehicles = items
	boughtVehiclesToLoad.loadedVehicleIndex = 0
	boughtVehiclesToLoad.usedPlaces = usedPlaces
	boughtVehiclesToLoad.place = place
	boughtVehiclesToLoad.width = width

	if not self:loadVehiclesAtPlaceStep(asyncCallbackArguments.targetOwner) then
		self:loadVehiclesAtPlaceFinished(targetOwner, BaseMission.VEHICLE_LOAD_ERROR)
	end
end

function BaseMission:loadVehiclesAtPlaceStep(targetOwner)
	local data = self.boughtVehiclesToLoad[targetOwner]
	local vehicles = data.vehicles
	local index = data.loadedVehicleIndex + 1

	if index <= #vehicles then
		local item = vehicles[index]
		local x = item.x
		local offset = item.yOffset + item.offset[2]
		local z = item.z
		local yRot = item.yRot + item.rotation
		local dirX, dirZ = MathUtil.getDirectionFromYRotation(item.yRot)
		local upX, upZ = MathUtil.getDirectionFromYRotation(item.yRot + math.pi / 2)
		x = x + upX * item.offset[1] + dirX * item.offset[3]
		z = z + upZ * item.offset[1] + dirZ * item.offset[3]

		self:loadVehicle(item.xmlFilename, x, nil, z, offset, yRot, true, item.price, item.propertyState, item.ownerFarmId, item.configurations, nil, self.loadVehiclesAtPlaceStepFinished, self, {
			targetOwner
		})

		return true
	end

	return false
end

function BaseMission:loadVehiclesAtPlaceStepFinished(vehicle, vehicleLoadState, arguments)
	local targetOwner = unpack(arguments)

	if vehicle ~= nil then
		local data = self.boughtVehiclesToLoad[targetOwner]
		data.loadedVehicleIndex = data.loadedVehicleIndex + 1

		table.insert(data.loadedVehicles, vehicle)

		if not self:loadVehiclesAtPlaceStep(targetOwner) then
			self:loadVehiclesAtPlaceFinished(targetOwner, BaseMission.VEHICLE_LOAD_OK)
		end
	else
		self:loadVehiclesAtPlaceFinished(targetOwner, BaseMission.VEHICLE_LOAD_NO_SPACE)
	end
end

function BaseMission:loadVehiclesAtPlaceFinished(targetOwner, code)
	local data = self.boughtVehiclesToLoad[targetOwner]

	if code == BaseMission.VEHICLE_LOAD_OK then
		if data.storeItem.bundleInfo ~= nil then
			local loadedVehicles = data.loadedVehicles
			local bundleInfo = {}

			for _, attachInfo in pairs(data.storeItem.bundleInfo.attacherInfo) do
				local v1 = loadedVehicles[attachInfo.bundleElement0]
				local v2 = loadedVehicles[attachInfo.bundleElement1]

				v1:attachImplement(v2, attachInfo.inputAttacherJointIndex, attachInfo.attacherJointIndex, true, nil, , true)
				table.insert(bundleInfo, {
					v1 = v1,
					v2 = v2,
					input = attachInfo.inputAttacherJointIndex,
					attacher = attachInfo.attacherJointIndex
				})
			end

			if g_server ~= nil then
				g_server:broadcastEvent(VehicleBundleAttachEvent:new(bundleInfo), nil, , self)
			end
		end

		PlacementUtil.markPlaceUsed(data.usedPlaces, data.place, data.width)
	end

	if data.asyncCallbackFunction ~= nil then
		data.asyncCallbackFunction(data.asyncCallbackObject, code, data.asyncCallbackArguments)
	end

	self.boughtVehiclesToLoad[targetOwner] = nil
end

function BaseMission:loadObjectAtPlace(xmlFilename, places, usedPlaces, rotationOffset, ownerFarmId)
	local sizeWidth, sizeLength, widthOffset, lengthOffset = StoreItemUtil.getSizeValues(xmlFilename, "object", rotationOffset)
	local isLimitReached = false
	local x, y, z, place, width, _ = PlacementUtil.getPlace(places, sizeWidth, sizeLength, widthOffset, lengthOffset, usedPlaces, true, false, true)

	if x == nil then
		return nil, true, isLimitReached
	end

	local object = nil
	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + rotationOffset
	local xmlFile = loadXMLFile("tempObjectXML", xmlFilename)
	local className = Utils.getNoNil(getXMLString(xmlFile, "object.className"), "")
	local filename = getXMLString(xmlFile, "object.filename")
	local class = ClassUtil.getClassObject(className)

	if class ~= nil then
		if filename ~= nil then
			object = class:new(self:getIsServer(), self:getIsClient())

			object:setOwnerFarmId(ownerFarmId, true)

			filename = Utils.getFilename(filename, self.baseDirectory)

			if object:load(filename, x, y, z, 0, yRot, 0, xmlFilename) then
				object:register()
				object:setFillLevel(object.capacity, false)
			else
				object:delete()

				object = nil
			end
		else
			print("Warning: File '" .. tostring(filename) .. "' not found!")

			if false then
				isLimitReached = true
			end
		end
	else
		print("Warning: Class '" .. tostring(className) .. "' not found!")
	end

	delete(xmlFile)

	if object ~= nil then
		PlacementUtil.markPlaceUsed(usedPlaces, place, width)

		return object, false, isLimitReached
	end

	return nil, false, isLimitReached
end

function BaseMission:addOwnedItem(item)
	BaseMission.addItemToList(self.ownedItems, item)
end

function BaseMission:removeOwnedItem(item)
	BaseMission.removeItemFromList(self.ownedItems, item)
end

function BaseMission:getNumOwnedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.ownedItems, storeItem, farmId)
end

function BaseMission:addLeasedItem(item)
	BaseMission.addItemToList(self.leasedVehicles, item)
end

function BaseMission:removeLeasedItem(item)
	BaseMission.removeItemFromList(self.leasedVehicles, item)
end

function BaseMission:getNumLeasedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.leasedVehicles, storeItem, farmId)
end

function BaseMission.getNumListItems(list, storeItem, farmId)
	local numItems = 0

	if storeItem.bundleInfo == nil then
		if list[storeItem] ~= nil then
			if farmId == nil then
				numItems = list[storeItem].numItems
			else
				numItems = 0

				for _, item in pairs(list[storeItem].items) do
					if item:getOwnerFarmId() == farmId then
						numItems = numItems + 1
					end
				end
			end
		end
	else
		local maxNumOfItems = math.huge

		for _, bundleItem in pairs(storeItem.bundleInfo.bundleItems) do
			maxNumOfItems = math.min(maxNumOfItems, BaseMission.getNumListItems(list, bundleItem.item, farmId))
		end

		numItems = maxNumOfItems
	end

	return numItems
end

function BaseMission.addItemToList(list, item)
	if list == nil or item == nil then
		return
	end

	local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)

	if storeItem ~= nil then
		if list[storeItem] == nil then
			list[storeItem] = {
				numItems = 0,
				storeItem = storeItem,
				items = {}
			}
		end

		if list[storeItem].items[item] == nil then
			list[storeItem].numItems = list[storeItem].numItems + 1
			list[storeItem].items[item] = item
		end
	end
end

function BaseMission.removeItemFromList(list, item)
	if list == nil or item == nil then
		return
	end

	local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)

	if storeItem ~= nil and list[storeItem] ~= nil and list[storeItem].items[item] ~= nil then
		list[storeItem].numItems = list[storeItem].numItems - 1
		list[storeItem].items[item] = nil

		if list[storeItem].numItems == 0 then
			list[storeItem] = nil
		end
	end
end

function BaseMission:addPlaceable(placeable)
	ListUtil.addElementToList(self.placeables, placeable)
end

function BaseMission:removePlaceable(placeable)
	ListUtil.removeElementFromList(self.placeables, placeable)
end

function BaseMission:addVehicle(vehicle)
	vehicle:addNodeObjectMapping(self.nodeToObject)
	ListUtil.addElementToList(self.vehicles, vehicle)

	vehicle.isAddedToMission = true

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		self:addOwnedItem(vehicle)
	elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		self:addLeasedItem(vehicle)
	end
end

function BaseMission:removeVehicle(vehicle, callDelete)
	if self:getIsClient() and vehicle == self.controlledVehicle then
		self:onLeaveVehicle()
	end

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		self:removeOwnedItem(vehicle)
	elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		self:removeLeasedItem(vehicle)
	end

	ListUtil.removeElementFromList(self.vehicles, vehicle)
	vehicle:removeNodeObjectMapping(self.nodeToObject)
	ListUtil.removeElementFromList(self.vehiclesToDelete, vehicle)

	vehicle.isAddedToMission = false

	if callDelete == nil or callDelete == true then
		if self:getIsServer() then
			ListUtil.addElementToList(self.vehiclesToDelete, vehicle)
		else
			g_client:getServerConnection():sendEvent(VehicleRemoveEvent:new(vehicle))
		end
	end
end

function BaseMission:addUpdateable(updateable)
	assert(updateable.isa == nil or not updateable:isa(Object), "No network objects allowed in addUpdateable")

	self.updateables[updateable] = updateable
end

function BaseMission:removeUpdateable(updateable)
	self.updateables[updateable] = nil
end

function BaseMission:addNonUpdateable(nonUpdateable)
	assert(nonUpdateable.isa == nil or not nonUpdateable:isa(Object), "No network objects allowed in addNonUpdateable")

	self.nonUpdateables[nonUpdateable] = nonUpdateable
end

function BaseMission:removeNonUpdateable(nonUpdateable)
	self.nonUpdateables[nonUpdateable] = nil
end

function BaseMission:addDrawable(drawable)
	self.drawables[drawable] = drawable
end

function BaseMission:removeDrawable(drawable)
	self.drawables[drawable] = nil
end

function BaseMission:addOnCreateLoadedObject(object)
	if not self.isLoadingMap then
		print("Error: only allowed to add objects while loading maps")

		return
	end

	table.insert(self.onCreateLoadedObjects, object)

	return table.getn(self.onCreateLoadedObjects)
end

function BaseMission:getOnCreateLoadedObject(index)
	return self.onCreateLoadedObjects[index]
end

function BaseMission:getNumOnCreateLoadedObjects()
	return table.getn(self.onCreateLoadedObjects)
end

function BaseMission:addNodeObject(node, object)
	assert(self.nodeToObject[node] == nil, "Error: [BaseMission:addNodeObject] node(" .. getName(node) .. ") object(" .. tostring(object) .. ")")

	self.nodeToObject[node] = object
end

function BaseMission:removeNodeObject(node)
	self.nodeToObject[node] = nil
end

function BaseMission:getNodeObject(node)
	return self.nodeToObject[node]
end

function BaseMission:addActivatableObject(activatableObject)
	if activatableObject.activateText == nil then
		print("Error BaseMission addActivatableObject: missing attribute activateText")

		return
	end

	if self.activatableObjects[activatableObject] == nil then
		self.activatableObjects[activatableObject] = activatableObject
	end
end

function BaseMission:removeActivatableObject(activatableObject)
	for key, object in pairs(self.activatableObjects) do
		if object == activatableObject then
			self.activatableObjects[key] = nil

			break
		end
	end
end

function BaseMission:addActivateListener(listener)
	table.insert(self.activateListeners, listener)
end

function BaseMission:addItemToSave(item)
	if item.saveToXMLFile == nil then
		print("Error: adding item which does not have a saveToXMLFile function")

		return
	end

	if self.objectsToClassName[item] == nil then
		print("Error: adding item which does not have a className registered. Use registerObjectClassName(object,className)")

		return
	end

	self.itemsToSave[item] = {
		item = item,
		className = self.objectsToClassName[item]
	}
end

function BaseMission:removeItemToSave(item)
	self.itemsToSave[item] = nil
end

function BaseMission:addOnCreateLoadedObjectToSave(object)
	if not self.isLoadingMap then
		print("Error: Only allowed to add onCreate loaded objects to save while loading maps")

		return
	end

	if object.saveToXMLFile == nil then
		print("Error: Adding onCreate loaded object so save which does not have a saveToXMLFile function")

		return
	end

	if object.saveId == nil then
		print("Error: Adding onCreate loaded object with invalid saveId")

		return
	end

	local prevObject = self.onCreateLoadedObjectsToSave[object.saveId]

	if prevObject == object then
		return
	end

	if prevObject ~= nil then
		print("Error: Adding onCreate loaded object with duplicate saveId " .. tostring(object.saveId))

		return
	end

	self.onCreateLoadedObjectsToSave[object.saveId] = object
	self.numOnCreateLoadedObjectsToSave = self.numOnCreateLoadedObjectsToSave + 1
	object.saveOrderIndex = self.numOnCreateLoadedObjectsToSave
end

function BaseMission:removeOnCreateLoadedObjectToSave(object)
	if object.saveId ~= nil then
		local prevObject = self.onCreateLoadedObjectsToSave[object.saveId]

		if prevObject == object then
			self.onCreateLoadedObjectsToSave[object.saveId] = nil
		end
	end
end

function BaseMission:pauseGame()
	if not self.paused then
		self:doPauseGame()

		if self:getIsServer() then
			GamePauseEvent.sendEvent()
		end
	end
end

function BaseMission:tryUnpauseGame()
	if self:canUnpauseGame() then
		self:doUnpauseGame()

		if self:getIsServer() then
			GamePauseEvent.sendEvent()
		end

		return true
	end

	return false
end

function BaseMission:canUnpauseGame()
	return self.paused and not self.manualPaused and not self.suspendPaused and not self.pressStartPaused
end

function BaseMission:setManualPause(doPause)
	if (self:getIsServer() or self.isMasterUser) and doPause ~= self.manualPaused then
		self.manualPaused = doPause

		if self:getIsServer() then
			if doPause then
				self:pauseGame()
			else
				self:tryUnpauseGame()
			end
		else
			g_client:getServerConnection():sendEvent(GamePauseRequestEvent:new(doPause))
		end
	end
end

function BaseMission:doPauseGame()
	self.paused = true
	self.isRunning = false

	simulatePhysics(false)
	simulateParticleSystems(false)
	self:resetGameState()

	for target, callbackFunc in pairs(self.pauseListeners) do
		callbackFunc(target, self.paused)
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(false)
	end
end

function BaseMission:doUnpauseGame()
	self.paused = false
	self.isRunning = true

	simulatePhysics(true)
	simulateParticleSystems(true)

	local lastNonPauseGameState = self.lastNonPauseGameState

	if lastNonPauseGameState == GameState.MENU_INGAME and g_gui.currentGuiName ~= "InGameMenu" then
		lastNonPauseGameState = GameState.PLAY
	end

	g_gameStateManager:setGameState(lastNonPauseGameState)

	for target, callbackFunc in pairs(self.pauseListeners) do
		callbackFunc(target, self.paused)
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(g_currentMission.missionInfo.trafficEnabled)
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(true)
	end
end

function BaseMission:addPauseListeners(target, callbackFunc)
	self.pauseListeners[target] = callbackFunc
end

function BaseMission:removePauseListeners(target)
	self.pauseListeners[target] = nil
end

function BaseMission:resetGameState()
	if self.pressStartPaused then
		g_gameStateManager:setGameState(GameState.LOADING)
	elseif self.paused then
		g_gameStateManager:setGameState(GameState.PAUSED)
	else
		g_gameStateManager:setGameState(GameState.PLAY)
	end
end

function BaseMission:toggleVehicle(delta)
	if not self.isToggleVehicleAllowed then
		return
	end

	local numVehicles = table.getn(self.enterables)

	if numVehicles > 0 then
		local index = 1
		local oldIndex = 1

		if not self.controlPlayer and self.controlledVehicle ~= nil then
			for i = 1, numVehicles do
				if self.controlledVehicle == self.enterables[i] then
					oldIndex = i
					index = i + delta

					if numVehicles < index then
						index = 1
					end

					if index < 1 then
						index = numVehicles
					end

					break
				end
			end
		elseif delta < 0 then
			index = numVehicles
		end

		local found = false

		repeat
			local enterable = self.enterables[index]

			if enterable:getIsTabbable() and enterable:getIsEnterable() then
				found = true
			else
				index = index + delta

				if numVehicles < index then
					index = 1
				end

				if index < 1 then
					index = numVehicles
				end
			end
		until found or index == oldIndex

		if found then
			g_currentMission:requestToEnterVehicle(self.enterables[index])
		end
	end
end

function BaseMission:getIsClient()
	return g_client ~= nil
end

function BaseMission:getIsServer()
	return g_server ~= nil
end

function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	if self.isRunning and not g_gui:getIsGuiVisible() then
		if g_server ~= nil then
			g_server:mouseEvent(posX, posY, isDown, isUp, button)
		end

		if g_client ~= nil then
			g_client:mouseEvent(posX, posY, isDown, isUp, button)
		end

		if self:getIsClient() then
			if self.controlPlayer then
				self.player:mouseEvent(posX, posY, isDown, isUp, button)
			elseif self.controlledVehicle ~= nil then
				-- Nothing
			end
		end
	end

	for _, v in pairs(g_modEventListeners) do
		if v.mouseEvent ~= nil then
			v:mouseEvent(posX, posY, isDown, isUp, button)
		end
	end
end

function BaseMission:keyEvent(unicode, sym, modifier, isDown)
	if self.isRunning and not g_gui:getIsGuiVisible() then
		if self:getIsServer() then
			g_server:keyEvent(unicode, sym, modifier, isDown)
		end

		if self:getIsClient() then
			g_client:keyEvent(unicode, sym, modifier, isDown)
		end
	end

	for _, v in pairs(g_modEventListeners) do
		if v.keyEvent ~= nil then
			v:keyEvent(unicode, sym, modifier, isDown)
		end
	end
end

function BaseMission:preUpdate(dt)
	if not self.waitForCorruptDlcs then
		if self.waitForDLCVerification and verifyDlcs() and g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog" then
			g_gui:showGui("")

			self.waitForDLCVerification = false
		end

		if storeAreDlcsCorrupted() then
			self.waitForCorruptDlcs = true
			local infoDialog = g_gui:showGui("InfoDialog")

			infoDialog.target:setText(g_i18n:getText("dialog_dlcsCorruptQuit"))
			infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
			infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
		elseif not self.waitForDLCVerification and storeHaveDlcsChanged() then
			g_forceNeedsDlcsAndModsReload = true

			if not verifyDlcs() then
				self.waitForDLCVerification = true
				local infoDialog = g_gui:showGui("InfoDialog")

				infoDialog.target:setText(g_i18n:getText("dialog_reinsertDlcMedia"))
				infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
				infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
			elseif checkForNewDlcs() then
				self.hud:showInGameMessage(g_i18n:getText("message_newDlcsRestartTitle"), g_i18n:getText("message_newDlcsRestartText"), -1)
			end
		end
	end
end

function BaseMission:dlcProblemOnQuitOk()
	OnInGameMenuMenu()
end

function BaseMission:update(dt)
	if self.waitForDLCVerification or self.waitForCorruptDlcs then
		return
	end

	if self:getIsServer() then
		g_server:update(dt, self.isRunning)
	end

	if self:getIsClient() then
		g_client:update(dt, self.isRunning)
	end

	while next(self.vehiclesToDelete) ~= nil do
		local i = #self.vehiclesToDelete
		local vehicle = self.vehiclesToDelete[i]

		table.remove(self.vehiclesToDelete, i)
		vehicle:delete()
	end

	for i = #self.vehiclesToAttach, 1, -1 do
		local info = self.vehiclesToAttach[i]
		local v1 = NetworkUtil.getObject(info.v1)
		local v2 = NetworkUtil.getObject(info.v2)

		if v1 ~= nil and v2 ~= nil then
			v1:attachImplement(v2, info.inputJointIndex, info.jointIndex, true, nil, , true)
			table.remove(self.vehiclesToAttach, i)
		end
	end

	if self.gameStarted then
		local newSuspendPaused = nil

		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			newSuspendPaused = g_appIsSuspended or g_windowHasFocus
		else
			newSuspendPaused = g_appIsSuspended
		end

		if newSuspendPaused ~= self.suspendPaused then
			self.suspendPaused = newSuspendPaused

			if newSuspendPaused then
				self:pauseGame()
			else
				self:tryUnpauseGame()
			end
		end
	end

	self.achievementManager:update(dt)
	self.hud:update(dt)

	if not self.isRunning then
		return
	end

	if self.firstTimeRun then
		local numToSpawn = table.getn(self.vehiclesToSpawn)

		if numToSpawn > 0 then
			for i = 1, numToSpawn do
				local xmlFilename = self.vehiclesToSpawn[i].xmlFilename
				local xmlFile = loadXMLFile("VehiclesXML", xmlFilename)
				local key = self.vehiclesToSpawn[i].xmlKey

				if self:loadVehicleFromXML(xmlFile, key, true, false) == BaseMission.VEHICLE_LOAD_ERROR then
					print("Warning: corrupt vehicles xml '" .. xmlFilename .. "', vehicle " .. key .. " could not be loaded")
				end

				delete(xmlFile)
			end

			self.vehiclesToSpawn = {}
		end
	end

	for k in pairs(self.usedStorePlaces) do
		self.usedStorePlaces[k] = nil
	end

	for k in pairs(self.usedLoadPlaces) do
		self.usedLoadPlaces[k] = nil
	end

	self.time = self.time + dt

	if self:getIsClient() then
		if not g_gui:getIsGuiVisible() then
			self.hud:updateBlinkingWarning(dt)

			if self.currentMapTargetHotspot ~= nil and not self.disableMapTargetHotspotHiding then
				local x, _, z = getWorldTranslation(getCamera())
				local distance = MathUtil.vector2Length(x - self.currentMapTargetHotspot.xMapPos, z - self.currentMapTargetHotspot.zMapPos)

				if distance < 10 then
					self:setMapTargetHotspot(nil)
				end
			end
		end

		self.interactiveVehicleInRange = self:getInteractiveVehicleInRange()
	end

	if self.environment ~= nil then
		self.environment:update(dt)
	end

	for _, v in pairs(self.updateables) do
		v:update(dt)
	end

	for _, v in pairs(g_modEventListeners) do
		if v.update ~= nil then
			v:update(dt)
		end
	end

	g_ambientSoundManager:update(dt)
	g_sleepManager:update(dt)

	self.firstTimeRun = true

	if self.takeVehicleScreenshots then
		local info = self.vehicleScreenshotsInfo

		if info.timer == nil then
			info.timer = self.time + 3000
		end

		if info.vehicle == nil then
			for _, missionVehicle in pairs(self.vehicles) do
				if missionVehicle.configFileName ~= nil then
					local restString = missionVehicle.configFileName

					while true do
						local startPos, _ = string.find(restString, "/")

						if startPos == nil then
							break
						end

						restString = string.sub(restString, startPos + 1)
					end

					restString = string.sub(restString, 1, string.len(restString) - 4)

					if restString == info.vehicleName then
						info.vehicle = missionVehicle

						break
					end
				end
			end
		end

		if info.vehicle == nil then
			print("Warning: Could not start taking screenshot, because vehicle '" .. tostring(info.vehicleName) .. "' could not be found")

			self.takeVehicleScreenshots = false
			info = {}
		else
			if info.baseNode == nil then
				info.screenshotsDir = getUserProfileAppPath() .. "screenshots/" .. info.vehicleName .. "/"

				createFolder(info.screenshotsDir)

				if info.isIndoor then
					info.screenshotsDir = getUserProfileAppPath() .. "screenshots/" .. info.vehicleName .. "/indoor/"

					createFolder(info.screenshotsDir)
				end

				info.camera = createCamera("screenshotCamera", info.FOV, 0.1, 5000)
				info.xRot = createTransformGroup("xRot")
				info.yRot = createTransformGroup("yRot")
				info.baseNode = createTransformGroup("baseNode")

				link(getRootNode(), info.baseNode)
				link(info.baseNode, info.yRot)
				link(info.yRot, info.xRot)
				link(info.xRot, info.camera)

				local x, y, z = nil

				if info.isIndoor then
					if info.vehicle.cameras ~= nil then
						for _, cam in pairs(info.vehicle.cameras) do
							if cam.isInside then
								x, y, z = getWorldTranslation(cam.cameraNode)
							end
						end

						info.characterCameraMinDistance = info.vehicle.characterCameraMinDistance
						info.vehicle.characterCameraMinDistance = math.huge

						if info.vehicle.characterNode ~= nil then
							info.characterVisibility = getVisibility(info.vehicle.characterNode)

							setVisibility(info.vehicle.characterNode, false)

							if info.vehicle.characterMesh ~= nil then
								info.characterMeshVisibility = getVisibility(info.vehicle.characterMesh)

								setVisibility(info.vehicle.characterMesh, false)
							end
						end
					end

					if x == nil then
						print("Warning: Could not start taking screenshot, because vehicle '" .. tostring(info.vehicleName) .. "' has no camera with the attribute 'isInside'")

						self.takeVehicleScreenshots = false
						info = {}

						return
					end
				else
					x, y, z = getWorldTranslation(info.vehicle.components[1].node)
				end

				local dx, dy, dz = localDirectionToWorld(info.vehicle.components[1].node, info.positionOffset[1], info.positionOffset[2], info.positionOffset[3])

				setTranslation(info.baseNode, x + dx, y + dy, z + dz)

				local rx, ry, rz = getWorldRotation(info.vehicle.components[1].node)

				setRotation(info.baseNode, rx, ry, rz)
				setRotation(info.xRot, info.xRotation, 0, 0)
				setTranslation(info.camera, 0, 0, info.distance)

				if SpecializationUtil.hasSpecialization(Foldable, info.vehicle.specializations) then
					local animTime = 0

					if info.unfold then
						if info.vehicle.turnOnFoldDirection > 0 then
							animTime = 1
						else
							animTime = 0
						end
					elseif info.vehicle.turnOnFoldDirection > 0 then
						animTime = 0
					else
						animTime = 1
					end

					Foldable.setAnimTime(info.vehicle, animTime, false)

					if info.vehicle.movingTools ~= nil then
						info.hasMovingTimer = 1500

						for _, tool in ipairs(info.vehicle.movingTools) do
							Cylindered.setDirty(info.vehicle, tool)
						end

						for _, part in ipairs(info.vehicle.movingParts) do
							Cylindered.setDirty(info.vehicle, part)
						end
					end
				end

				info.sunLightId = g_currentMission.environment.sunLightId
				g_currentMission.environment.dayNightCycle = false

				setLightColor(info.sunLightId, 1, 1, 1)
			end

			if info.hasMovingTimer ~= nil and info.hasMovingTimer > 0 then
				info.hasMovingTimer = info.hasMovingTimer - dt

				for _, tool in ipairs(info.vehicle.movingTools) do
					Cylindered.setDirty(info.vehicle, tool)
				end

				for _, part in ipairs(info.vehicle.movingParts) do
					Cylindered.setDirty(info.vehicle, part)
				end
			end

			setRotation(info.yRot, 0, (info.screenShotIndex - 1) * math.pi / 4, 0)
			setCamera(info.camera)

			local dx, dy, dz = localDirectionToWorld(info.camera, 0.5, 0.5, 1)

			setDirection(info.sunLightId, dx, dy, dz)

			if info.timer < self.time then
				local screenshotName = info.screenshotsDir .. string.format("view_%02d.png", info.screenShotIndex - 1)

				saveScreenshot(screenshotName)

				info.screenShotIndex = info.screenShotIndex + 1
				info.timer = self.time + 200
			end

			if info.screenShotIndex == 9 then
				self.takeVehicleScreenshots = false

				delete(info.baseNode)

				if info.isIndoor and info.vehicle.characterNode ~= nil then
					setVisibility(info.vehicle.characterNode, info.characterVisibility)

					if info.vehicle.characterMesh ~= nil then
						setVisibility(info.vehicle.characterMesh, info.characterMeshVisibility)
					end

					info.vehicle.characterCameraMinDistance = info.characterCameraMinDistance
				end

				self.hud:setIsVisible(true)

				info = {}
				g_currentMission.environment.dayNightCycle = true
				g_currentMission.environment.lightTimer = g_currentMission.environment.lightUpdateInterval
			end
		end
	end

	if g_touchHandler ~= nil then
		g_touchHandler:update(dt)
	end
end

function BaseMission:draw()
	local isNotFading = not self.hud:getIsFading()

	if self:getIsClient() and self.isRunning and not g_gui:getIsGuiVisible() and isNotFading then
		self.hud:drawControlledEntityHUD()

		for _, vehicle in pairs(self.enterables) do
			vehicle:drawUIInfo()
		end

		for _, player in pairs(self.players) do
			player:drawUIInfo()
		end
	end

	if self.isRunning and (not g_gui:getIsGuiVisible() or self.guiTopDownCamera:getIsActive()) and isNotFading then
		local canActivateObject = false

		for key, object in pairs(self.activatableObjects) do
			if object:getIsActivatable() then
				canActivateObject = true

				self.inputManager:setActionEventText(self.eventActivateObject, object.activateText)
				object:drawActivate()

				break
			end
		end

		for _, drawable in pairs(self.drawables) do
			drawable:draw()
		end

		self.inputManager:setActionEventTextVisibility(self.eventActivateObject, canActivateObject)
		self.inputManager:setActionEventActive(self.eventActivateObject, canActivateObject)
		new2DLayer()
		self.hud:drawInputHelp()
		self.hud:drawTopNotification()
		self.hud:drawBlinkingWarning()

		if g_server ~= nil then
			g_server:draw()
		elseif g_client ~= nil then
			g_client:draw()
		end

		for _, v in pairs(g_modEventListeners) do
			if v.draw ~= nil then
				v:draw()
			end
		end

		self.hud:drawPresentationVersion()
	end

	if self.paused and not self.isMissionStarted and not g_gui:getIsGuiVisible() then
		self.hud:drawGamePaused(true)
	end

	self.hud:drawFading()

	if g_touchHandler ~= nil then
		g_touchHandler:draw()
	end
end

function BaseMission:requestToEnterVehicle(vehicle)
	if self.accessHandler:canPlayerAccess(vehicle) then
		g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(vehicle, self.player.visualInformation, self:getFarmId()))
	end
end

function BaseMission:enterVehicleWithPlayer(vehicle, player)
	local enterableSpec = vehicle.spec_enterable

	if vehicle ~= nil and enterableSpec ~= nil and enterableSpec.isControlled == false then
		local connection = player.networkInformation.creatorConnection

		vehicle:setOwner(connection)

		vehicle.controllerFarmId = player.farmId

		g_server:broadcastEvent(VehicleEnterResponseEvent:new(NetworkUtil.getObjectId(vehicle), false, player.visualInformation, player.farmId))
		connection:sendEvent(VehicleEnterResponseEvent:new(NetworkUtil.getObjectId(vehicle), true, player.visualInformation, player.farmId))
	end
end

function BaseMission:onEnterVehicle(vehicle, playerStyle, farmId)
	if self.controlPlayer then
		self.player:onLeave()
	elseif self.controlledVehicle ~= nil then
		g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(self.controlledVehicle))
		self.controlledVehicle:leaveVehicle()
	end

	local oldContext = self.inputManager:getContextName()

	self.inputManager:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
	self:registerActionEvents()
	self:registerPauseActionEvents()

	self.controlledVehicle = vehicle

	self.controlledVehicle:enterVehicle(true, playerStyle, farmId)

	if g_gui:getIsGuiVisible() and oldContext ~= Vehicle.INPUT_CONTEXT_NAME then
		self.inputManager:setContext(oldContext, false, false)
	end

	self.controlPlayer = false

	self.hud:setControlledVehicle(vehicle)
	self.hud:setIsControllingPlayer(false)
	self.guiTopDownCamera:setControlledVehicle(vehicle)
end

function BaseMission:onLeaveVehicle(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
	if not self.controlPlayer and self.controlledVehicle ~= nil then
		g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(self.controlledVehicle))

		if self.controlledVehicle.getIsEntered ~= nil and self.controlledVehicle:getIsEntered() then
			self.controlledVehicle:leaveVehicle()
		end

		self.inputManager:resetActiveActionBindings()

		local prevContext = self.inputManager:getContextName()
		local isVehicleContext = prevContext == BaseMission.INPUT_CONTEXT_VEHICLE
		local isInMenu = g_gui:getIsGuiVisible()

		if isInMenu then
			self.inputManager:beginActionEventsModification(Player.INPUT_CONTEXT_NAME, true)
		else
			self.inputManager:setContext(Player.INPUT_CONTEXT_NAME, true, isVehicleContext)
		end

		self:registerActionEvents()

		self.controlPlayer = true

		if playerTargetPosX ~= nil and playerTargetPosY ~= nil and playerTargetPosZ ~= nil then
			self.player:moveTo(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
		else
			self.player:moveToExitPoint(self.controlledVehicle)
		end

		self.player:onEnter(true)
		self.player:onLeaveVehicle()

		self.controlledVehicle = nil

		self.hud:setIsControllingPlayer(true)
		self.hud:setControlledVehicle(nil)
		self.guiTopDownCamera:setControlledPlayer(self.player)

		if isInMenu then
			self.inputManager:endActionEventsModification(true)
			self.inputManager:setPreviousContext(Gui.INPUT_CONTEXT_MENU, Player.INPUT_CONTEXT_NAME)
		end

		self:registerPauseActionEvents()
	end
end

function BaseMission:getTrailerInTipRange(vehicle, minDistance)
	print("WARNING: BaseMission.getTrailerInTipRange() is deprecated")

	return false
end

function BaseMission:getIsTrailerInTipRange()
	print("WARNING: BaseMission.getIsTrailerInTipRange() is deprecated")

	return false
end

function BaseMission:addInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = vehicle
end

function BaseMission:removeInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = nil
end

function BaseMission:getInteractiveVehicleInRange()
	local nearestVehicle = nil

	if self.player ~= nil and not self.player.isCarryingObject then
		local nearestDistance = math.huge

		for _, vehicle in pairs(self.interactiveVehicles) do
			if not vehicle.isBroken and not vehicle.isControlled then
				local vehicleDistance = vehicle:getDistanceToNode(self.player.rootNode)

				if vehicleDistance < nearestDistance then
					nearestDistance = vehicleDistance
					nearestVehicle = vehicle
				end
			end
		end
	end

	return nearestVehicle
end

function BaseMission:addEnterableVehicle(vehicle)
	ListUtil.addElementToList(self.enterables, vehicle)
end

function BaseMission:isEnterableVehicle(vehicle)
	for _, enterable in ipairs(self.enterables) do
		if enterable == vehicle then
			return true
		end
	end

	return false
end

function BaseMission:removeEnterableVehicle(vehicle)
	ListUtil.removeElementFromList(self.enterables, vehicle)
end

function BaseMission:addAttachableVehicle(vehicle)
	ListUtil.addElementToList(self.attachables, vehicle)
end

function BaseMission:removeAttachableVehicle(vehicle)
	ListUtil.removeElementFromList(self.attachables, vehicle)
end

function BaseMission:onSunkVehicle(vehicle)
end

function BaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo

	self:setMoneyUnit(g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT))
	self:setUseMiles(g_gameSettings:getValue(GameSettings.SETTING.USE_MILES))
	self:setUseFahrenheit(g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT))
	self:setUseAcre(g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE))
	self.bans:setPath(missionInfo.bansXML)
	self.hud:setMissionInfo(missionInfo)
	self.inGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, self.baseDirectory, self.isTutorialMission)
end

function BaseMission:onCreateTriggerMarker(id)
	g_currentMission:addTriggerMarker(id)
end

function BaseMission:addTriggerMarker(id)
	ListUtil.addElementToList(self.triggerMarkers, id)
end

function BaseMission:removeTriggerMarker(id)
	ListUtil.removeElementFromList(self.triggerMarkers, id)
end

function BaseMission:setShowTriggerMarker(areVisible)
	for _, node in ipairs(self.triggerMarkers) do
		setVisibility(node, areVisible)
	end
end

function BaseMission:setShowFieldInfo(isVisible)
	self.hud:setFieldInfoVisible(isVisible)
end

function BaseMission:addHelpButtonText(text, actionName1, actionName2, prio)
end

function BaseMission:addHelpAxis(actionName, overlay)
end

function BaseMission:addExtraPrintText(text)
	self.hud:addExtraPrintText(text)
end

function BaseMission:addGameNotification(title, text, info, icon, duration, notification)
	return self.hud:addTopNotification(title, text, info, icon, duration, notification)
end

function BaseMission:showBlinkingWarning(text, duration, priority)
	self.hud:showBlinkingWarning(text, duration, priority)
end

function BaseMission:setMoneyUnit(unit)
	g_i18n:setMoneyUnit(unit)
end

function BaseMission:setUseMiles(useMiles)
	g_i18n:setUseMiles(useMiles)
end

function BaseMission:setUseAcre(useAcrea)
	g_i18n:setUseAcre(useAcrea)
end

function BaseMission:setUseFahrenheit(useFahrenheit)
	g_i18n:setUseFahrenheit(useFahrenheit)
end

function BaseMission:fadeScreen(direction, duration, callbackFunc, callbackTarget)
	self.hud:fadeScreen(direction, duration, callbackFunc, callbackTarget)
end

function BaseMission:setIsInsideBuilding(isInsideBuilding)
	self.isInsideBuilding = isInsideBuilding

	if g_soundManager ~= nil then
		g_soundManager:setIsInsideBuilding(isInsideBuilding)
	end
end

function BaseMission:loadI3D(i3dFilename, parent)
	local filename = Utils.getFilename(i3dFilename, self.baseDirectory)
	local i3dNode = loadI3DFile(filename, false, true, false)

	if i3dNode == 0 then
		print("ERROR: i3d file " .. i3dFilename .. " not found")
		printCallstack()

		return nil
	end

	local children = {}

	for i = getNumOfChildren(i3dNode) - 1, 0, -1 do
		local child = getChildAt(i3dNode, i)

		if parent ~= nil then
			link(parent, child)
		else
			unlink(child)
		end

		table.insert(self.dynamicallyLoadedObjects, child)
		table.insert(children, child)
	end

	delete(i3dNode)

	return children
end

function BaseMission:getStoreItemSlotUsage(storeItem, includeShared)
	if storeItem == nil or StoreItemUtil.getIsAnimal(storeItem) or StoreItemUtil.getIsObject(storeItem) then
		return 0
	end

	local vramUsage = nil

	if includeShared then
		vramUsage = storeItem.perInstanceVramUsage + storeItem.sharedVramUsage
	else
		vramUsage = math.max(storeItem.perInstanceVramUsage, storeItem.sharedVramUsage * 0.05)
	end

	return math.max(math.ceil(vramUsage / BaseMission.VRAM_USAGE_PER_SLOT), 1)
end

function BaseMission:calculateSlotUsage()
	self.slotUsage = (self.vertexBufferMemoryUsage + self.indexBufferMemoryUsage + self.textureMemoryUsage) / BaseMission.VRAM_USAGE_PER_SLOT

	for storeItem, item in pairs(self.ownedItems) do
		if item.numItems > 0 and not storeItem.ignoreVramUsage then
			self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(storeItem, true) + self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
		end
	end

	for storeItem, item in pairs(self.leasedVehicles) do
		if item.numItems > 0 and not storeItem.ignoreVramUsage then
			self.slotUsage = self.slotUsage + self:getStoreItemSlotUsage(storeItem, true) + self:getStoreItemSlotUsage(storeItem, false) * (item.numItems - 1)
		end
	end

	self.shopMenu:onSlotUsageChanged(self.slotUsage, BaseMission.TOTAL_NUM_GARAGE_SLOTS)
end

function BaseMission:getNumOfItems(storeItem, farmId)
	local numItems = 0

	if self.ownedItems[storeItem] ~= nil then
		if farmId == nil then
			numItems = numItems + self.ownedItems[storeItem].numItems
		elseif self.ownedItems[storeItem].numItems > 0 then
			for _, item in pairs(self.ownedItems[storeItem].items) do
				if item:getOwnerFarmId() == farmId then
					numItems = numItems + 1
				end
			end
		end
	end

	if self.leasedVehicles[storeItem] ~= nil then
		if farmId == nil then
			numItems = numItems + self.leasedVehicles[storeItem].numItems
		elseif self.leasedVehicles[storeItem].numItems > 0 then
			for _, item in pairs(self.leasedVehicles[storeItem].items) do
				if item:getOwnerFarmId() == farmId then
					numItems = numItems + 1
				end
			end
		end
	end

	return numItems
end

function BaseMission:hasEnoughSlots(storeItem)
	if not GS_IS_CONSOLE_VERSION or storeItem.ignoreVramUsage then
		return true
	end

	local slotUsage = g_currentMission:getStoreItemSlotUsage(storeItem, self:getNumOfItems(storeItem) == 0)

	return BaseMission.TOTAL_NUM_GARAGE_SLOTS >= self.slotUsage + slotUsage
end

function BaseMission:spawnCollisionTestCallback(transformId)
	if self.nodeToObject[transformId] ~= nil then
		self.spawnCollisionsFound = true
	end
end

function BaseMission:setMapTargetHotspot(mapHotspot)
	if self.currentMapTargetHotspot ~= nil then
		self.currentMapTargetHotspot:setBlinking(false)

		self.currentMapTargetHotspot.persistent = false

		g_currentMission.economyManager:updateGreatDemandsPDASpots()
	end

	if mapHotspot ~= nil then
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, mapHotspot.xMapPos, 0, mapHotspot.zMapPos)

		self:setMapTargetMarker(true, mapHotspot.xMapPos, h, mapHotspot.zMapPos)
		mapHotspot:setBlinking(true)

		mapHotspot.persistent = true
	else
		self:setMapTargetMarker(false, 0, 0, 0)
	end

	self.currentMapTargetHotspot = mapHotspot
end

function BaseMission:setMapTargetMarker(isActive, posX, posY, posZ)
	if BaseMission.MAP_TARGET_MARKER ~= nil then
		if isActive then
			setTranslation(BaseMission.MAP_TARGET_MARKER, posX, posY, posZ)
		end

		setVisibility(BaseMission.MAP_TARGET_MARKER, isActive)
	end
end

function BaseMission:onCreateMapTargetMarker(id)
	if BaseMission.MAP_TARGET_MARKER == nil then
		BaseMission.MAP_TARGET_MARKER = id

		link(getRootNode(), id)
		setVisibility(id, false)
	end
end

function BaseMission:onCreateLoadSpawnPlace(id)
	local place = PlacementUtil.createPlace(id)

	table.insert(g_currentMission.loadSpawnPlaces, place)
end

function BaseMission:onCreateStoreSpawnPlace(id)
	local place = PlacementUtil.createPlace(id)

	table.insert(g_currentMission.storeSpawnPlaces, place)
end

function BaseMission:onCreateRestrictedZone(id)
	local restrictedZone = PlacementUtil.createRestrictedZone(id)

	table.insert(g_currentMission.restrictedZones, restrictedZone)
end

function BaseMission:getResetPlaces()
	if #self.loadSpawnPlaces > 0 then
		return self.loadSpawnPlaces
	end

	return self.storeSpawnPlaces
end

function BaseMission:consoleCommandRender360Screenshot(resolution, subDir)
	local screenShotFolder = g_screenshotsDirectory

	if subDir ~= nil then
		screenShotFolder = screenShotFolder .. subDir .. "/"
	else
		screenShotFolder = screenShotFolder .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
	end

	createFolder(screenShotFolder)

	local baseFilename = screenShotFolder .. "fsScreen360"
	local resolution = Utils.getNoNil(tonumber(resolution), 512)
	local numMSAA = 1
	local clearColorR = 0
	local clearColorG = 0
	local clearColorB = 0
	local clearColorA = 0
	local bloomQuality = 5
	local useDOF = true
	local ssaoQuality = 15
	local cloudQuality = 4

	render360Screenshot(baseFilename, resolution, "hdr_raw", numMSAA, clearColorR, clearColorG, clearColorB, clearColorA, bloomQuality, useDOF, ssaoQuality, cloudQuality)
end

function BaseMission:consoleCommandTakeEnvProbes(numIterations, mobile, coverage, outputDirectory)
	numIterations = tonumber(numIterations)

	if numIterations == nil then
		return "Arguments: numIterations (required), mobile(optional, default: false), outputDirectory (optional, default: [cloud coverage 0.5] [map xml-path])"
	end

	local cloudCoverage = 0.5

	if coverage ~= nil then
		cloudCoverage = tonumber(coverage)

		if cloudCoverage > 1 then
			cloudCoverage = 1
		elseif cloudCoverage < 0 then
			cloudCoverage = 0
		end
	end

	if mobile == nil then
		mobile = false
	end

	local renderResolution = 512
	local outputResolution = 256

	if mobile then
		outputResolution = 128
	end

	if self.environment ~= nil then
		local envMapTimes, baseDirectory = nil

		if self.environment.baseLighting.envMapBasePath ~= nil then
			envMapTimes = self.environment.baseLighting.envMapTimes
			baseDirectory = self.environment.baseLighting.envMapBasePath
		else
			envMapTimes = {
				0
			}
			baseDirectory = g_screenshotsDirectory .. "envProbes/"
		end

		if outputDirectory ~= nil then
			baseDirectory = outputDirectory
		end

		if baseDirectory:sub(baseDirectory:len()) ~= "/" then
			baseDirectory = baseDirectory .. "/"
		end

		createFolder(baseDirectory)
		print("Writing env maps to " .. baseDirectory)

		local suffix = ""

		if GS_IS_MOBILE_VERSION then
			suffix = "_uncompressed"
		end

		if #envMapTimes > 0 then
			for j = 0, numIterations - 1 do
				if #envMapTimes > 1 then
					for i, dayTime in ipairs(envMapTimes) do
						self.environment:consoleCommandSetDayTime(dayTime)
						self.environment:updateSceneParameters()

						self.environment.baseLighting.envMapRenderingMode = true

						self.environment.baseLighting:update(0, true)

						self.environment.baseLighting.envMapRenderingMode = false

						setGlobalCloudState(0.15, 0.75, 0, 1, 50, 0, 20, 0.28, cloudCoverage)
						renderEnvProbe(renderResolution, outputResolution, 15, 4, baseDirectory .. Lighting.getEnvMapBaseFilename(dayTime) .. suffix .. ".dds")
					end
				else
					renderEnvProbe(renderResolution, outputResolution, 15, 4, baseDirectory .. Lighting.getEnvMapBaseFilename(envMapTimes[1]) .. suffix .. ".dds")
				end

				print("Envmap-Tool finished iteration " .. tostring(j))
			end
		end
	end
end

function BaseMission:consoleCommandTakeScreenshotsFromOutside(vehicleName, distance, xOffset, yOffset, zOffset, unfold)
	if vehicleName == nil then
		return "Invalid arguments. Arguments: vehicleName (required), distance (optional), xOffset (optional), yOffset (optional), zOffset (optional), unfold (optional)"
	end

	self.takeVehicleScreenshots = true
	self.vehicleScreenshotsInfo = {
		vehicleName = vehicleName,
		isIndoor = false,
		screenShotIndex = 1,
		distance = math.min(100, math.max(1, Utils.getNoNil(tonumber(distance), 15))),
		xRotation = -math.pi / 8,
		positionOffset = {
			tonumber(Utils.getNoNil(xOffset, 0)),
			tonumber(Utils.getNoNil(yOffset, 0)),
			tonumber(Utils.getNoNil(zOffset, 0))
		},
		FOV = math.rad(65),
		unfold = false
	}

	if unfold == "true" then
		self.vehicleScreenshotsInfo.unfold = true
	end

	self.hud:setIsVisible(false)
end

function BaseMission:consoleCommandTakeScreenshotsFromInside(vehicleName, xRotation, xOffset, yOffset, zOffset, FOV, unfold)
	if vehicleName == nil then
		return "Invalid arguments. Arguments: vehicleName (required), xRotation (optional), xOffset (optional), yOffset (optional), zOffset (optional), FOV (optional), unfold (optional)"
	end

	self.takeVehicleScreenshots = true
	self.vehicleScreenshotsInfo = {
		vehicleName = vehicleName,
		isIndoor = true,
		screenShotIndex = 1,
		distance = 0,
		xRotation = math.rad(Utils.getNoNil(tonumber(xRotation), 0)),
		positionOffset = {
			tonumber(Utils.getNoNil(xOffset, 0)),
			tonumber(Utils.getNoNil(yOffset, 0)),
			tonumber(Utils.getNoNil(zOffset, 0))
		},
		FOV = math.rad(Utils.getNoNil(tonumber(FOV), 65)),
		unfold = false
	}

	if unfold == "true" then
		self.vehicleScreenshotsInfo.unfold = true
	end

	self.hud:setIsVisible(false)
end

function BaseMission:consoleCommandSetFOV(fovY)
	local fovY = tonumber(fovY)

	if fovY ~= nil then
		local cameraBase = self.player

		if self.controlledVehicle ~= nil then
			cameraBase = self.controlledVehicle:getActiveCamera()
		end

		if fovY < 0 then
			fovY = cameraBase.fovY
		else
			fovY = math.rad(fovY)
		end

		setFovY(cameraBase.cameraNode, fovY)

		return "Set camera fov to " .. tostring(math.deg(fovY))
	else
		return "Command needs number argument. gsSetFOV fieldOfViewAngle (-1 to reset to default)"
	end
end

function BaseMission:consoleCommandDeleteAllVehicles()
	for i = table.getn(self.vehicles), 1, -1 do
		local vehicle = self.vehicles[i]

		if vehicle.isa ~= nil and vehicle:isa(Vehicle) then
			self:removeVehicle(vehicle)
		end
	end

	return "Deleted all vehicles!"
end

function BaseMission:setLastInteractionTime(timeDelta)
	self.lastInteractionTime = g_time
end

function BaseMission:subscribeSettingsChangeMessages()
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], self.setShowTriggerMarker, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_FIELD_INFO], self.setShowFieldInfo, self)
end

function BaseMission:subscribeGuiOpenCloseMessages()
	self.messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onBeforeMenuOpen, self)
	self.messageCenter:subscribe(MessageType.GUI_AFTER_CLOSE, self.onAfterMenuClose, self)
end

function BaseMission:onBeforeMenuOpen()
	self.hud:onMenuVisibilityChange(true, g_gui:getIsOverlayGuiVisible())
end

function BaseMission:onAfterMenuClose()
	self.hud:onMenuVisibilityChange(false, false)
end

function BaseMission:onGameStateChange(newGameState, oldGameState)
	if newGameState ~= GameState.PAUSED then
		self.lastNonPauseGameState = newGameState
	end
end

function BaseMission:registerActionEvents()
	local _, eventId = self.inputManager:registerActionEvent(InputAction.PAUSE, self, self.onPause, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onToggleHelpText, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, true, 1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, true, -1)

	self.inputManager:setActionEventTextVisibility(eventId, false)
	self.hud:registerInput()
end

function BaseMission:unregisterActionEvents()
	self.inputManager:removeActionEventsByTarget(self)
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)
	self.inputManager:removeActionEventsByTarget(self)
	self.inputManager:endActionEventsModification()
end

function BaseMission:registerPauseActionEvents()
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)

	local _, eventId = nil

	if GS_IS_CONSOLE_VERSION then
		_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onConsoleAcceptPause, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	_, eventId = self.inputManager:registerActionEvent(InputAction.PAUSE, self, self.onPause, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)
	self.inputManager:endActionEventsModification()
end

function BaseMission:onPause()
	if self.gameStarted then
		self:setManualPause(not self.manualPaused)
	end
end

function BaseMission:onConsoleAcceptPause()
	if self.gameStarted and self.manualPaused and GS_IS_CONSOLE_VERSION then
		self:setManualPause(false)
	end
end

function BaseMission:onToggleHelpText()
	local isVisible = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)

	g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, isVisible)
end

function BaseMission:onSwitchVehicle(_, _, directionValue)
	if not self.isPlayerFrozen and self.isRunning then
		self:toggleVehicle(directionValue)
	end
end
