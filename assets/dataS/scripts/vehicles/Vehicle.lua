Vehicle = {}
local Vehicle_mt = Class(Vehicle, Object)
Vehicle.defaultWidth = 8
Vehicle.defaultLength = 8
Vehicle.PROPERTY_STATE_NONE = 0
Vehicle.PROPERTY_STATE_OWNED = 1
Vehicle.PROPERTY_STATE_LEASED = 2
Vehicle.PROPERTY_STATE_MISSION = 3
Vehicle.PROPERTY_STATE_SHOP_CONFIG = 4
Vehicle.SPRING_SCALE = 10
Vehicle.NUM_INTERACTION_FLAGS = 0
Vehicle.INTERACTION_FLAG_NONE = 0
Vehicle.NUM_STATE_CHANGES = 0
Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION = 0.3
Vehicle.INPUT_CONTEXT_NAME = "VEHICLE"
Vehicle.debugNetworkUpdate = false

InitStaticObjectClass(Vehicle, "Vehicle", ObjectIds.OBJECT_VEHICLE)
source("dataS/scripts/vehicles/VehicleDebug.lua")
source("dataS/scripts/vehicles/VehicleHudUtils.lua")
source("dataS/scripts/vehicles/VehicleSchemaOverlayData.lua")
source("dataS/scripts/vehicles/VehicleBrokenEvent.lua")

function Vehicle.registerInteractionFlag(name)
	local key = "INTERACTION_FLAG_" .. string.upper(name)

	if Vehicle[key] == nil then
		Vehicle.NUM_INTERACTION_FLAGS = Vehicle.NUM_INTERACTION_FLAGS + 1
		Vehicle[key] = Vehicle.NUM_INTERACTION_FLAGS
	end
end

function Vehicle.registerStateChange(name)
	local key = "STATE_CHANGE_" .. string.upper(name)

	if Vehicle[key] == nil then
		Vehicle.NUM_STATE_CHANGES = Vehicle.NUM_STATE_CHANGES + 1
		Vehicle[key] = Vehicle.NUM_STATE_CHANGES
	end
end

function Vehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreLoad")
	SpecializationUtil.registerEvent(vehicleType, "onLoad")
	SpecializationUtil.registerEvent(vehicleType, "onPostLoad")
	SpecializationUtil.registerEvent(vehicleType, "onLoadFinished")
	SpecializationUtil.registerEvent(vehicleType, "onPreDelete")
	SpecializationUtil.registerEvent(vehicleType, "onDelete")
	SpecializationUtil.registerEvent(vehicleType, "onSave")
	SpecializationUtil.registerEvent(vehicleType, "onReadStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadPositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWritePositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onPreUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateInterpolation")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateDebug")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateEnd")
	SpecializationUtil.registerEvent(vehicleType, "onDraw")
	SpecializationUtil.registerEvent(vehicleType, "onActivate")
	SpecializationUtil.registerEvent(vehicleType, "onDeactivate")
	SpecializationUtil.registerEvent(vehicleType, "onStateChange")
	SpecializationUtil.registerEvent(vehicleType, "onRegisterActionEvents")
	SpecializationUtil.registerEvent(vehicleType, "onSelect")
	SpecializationUtil.registerEvent(vehicleType, "onUnselect")
	SpecializationUtil.registerEvent(vehicleType, "onSetBroken")
end

function Vehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "drawUIInfo", Vehicle.drawUIInfo)
	SpecializationUtil.registerFunction(vehicleType, "raiseActive", Vehicle.raiseActive)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingState", Vehicle.setLoadingState)
	SpecializationUtil.registerFunction(vehicleType, "addNodeObjectMapping", Vehicle.addNodeObjectMapping)
	SpecializationUtil.registerFunction(vehicleType, "removeNodeObjectMapping", Vehicle.removeNodeObjectMapping)
	SpecializationUtil.registerFunction(vehicleType, "addToPhysics", Vehicle.addToPhysics)
	SpecializationUtil.registerFunction(vehicleType, "removeFromPhysics", Vehicle.removeFromPhysics)
	SpecializationUtil.registerFunction(vehicleType, "setRelativePosition", Vehicle.setRelativePosition)
	SpecializationUtil.registerFunction(vehicleType, "setAbsolutePosition", Vehicle.setAbsolutePosition)
	SpecializationUtil.registerFunction(vehicleType, "getLimitedVehicleYPosition", Vehicle.getLimitedVehicleYPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPosition", Vehicle.setWorldPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuaternion", Vehicle.setWorldPositionQuaternion)
	SpecializationUtil.registerFunction(vehicleType, "updateVehicleSpeed", Vehicle.updateVehicleSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getUpdatePriority", Vehicle.getUpdatePriority)
	SpecializationUtil.registerFunction(vehicleType, "getPrice", Vehicle.getPrice)
	SpecializationUtil.registerFunction(vehicleType, "getSellPrice", Vehicle.getSellPrice)
	SpecializationUtil.registerFunction(vehicleType, "getDailyUpkeep", Vehicle.getDailyUpkeep)
	SpecializationUtil.registerFunction(vehicleType, "getIsOnField", Vehicle.getIsOnField)
	SpecializationUtil.registerFunction(vehicleType, "getParentComponent", Vehicle.getParentComponent)
	SpecializationUtil.registerFunction(vehicleType, "getLastSpeed", Vehicle.getLastSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateOnLeave", Vehicle.getDeactivateOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getOwner", Vehicle.getOwner)
	SpecializationUtil.registerFunction(vehicleType, "getIsVehicleNode", Vehicle.getIsVehicleNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsOperating", Vehicle.getIsOperating)
	SpecializationUtil.registerFunction(vehicleType, "getIsActive", Vehicle.getIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInput", Vehicle.getIsActiveForInput)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForSound", Vehicle.getIsActiveForSound)
	SpecializationUtil.registerFunction(vehicleType, "getIsLowered", Vehicle.getIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "getTailwaterDepth", Vehicle.getTailwaterDepth)
	SpecializationUtil.registerFunction(vehicleType, "setBroken", Vehicle.setBroken)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleDamage", Vehicle.getVehicleDamage)
	SpecializationUtil.registerFunction(vehicleType, "getRepairPrice", Vehicle.getRepairPrice)
	SpecializationUtil.registerFunction(vehicleType, "setMassDirty", Vehicle.setMassDirty)
	SpecializationUtil.registerFunction(vehicleType, "updateMass", Vehicle.updateMass)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalComponentMass", Vehicle.getAdditionalComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getTotalMass", Vehicle.getTotalMass)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelInformation", Vehicle.getFillLevelInformation)
	SpecializationUtil.registerFunction(vehicleType, "activate", Vehicle.activate)
	SpecializationUtil.registerFunction(vehicleType, "deactivate", Vehicle.deactivate)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointFrame", Vehicle.setComponentJointFrame)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointRotLimit", Vehicle.setComponentJointRotLimit)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointTransLimit", Vehicle.setComponentJointTransLimit)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentFromXML", Vehicle.loadComponentFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentJointFromXML", Vehicle.loadComponentJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "createComponentJoint", Vehicle.createComponentJoint)
	SpecializationUtil.registerFunction(vehicleType, "loadSchemaOverlay", Vehicle.loadSchemaOverlay)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalSchemaText", Vehicle.getAdditionalSchemaText)
	SpecializationUtil.registerFunction(vehicleType, "dayChanged", Vehicle.dayChanged)
	SpecializationUtil.registerFunction(vehicleType, "raiseStateChange", Vehicle.raiseStateChange)
	SpecializationUtil.registerFunction(vehicleType, "doCheckSpeedLimit", Vehicle.doCheckSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "interact", Vehicle.interact)
	SpecializationUtil.registerFunction(vehicleType, "getInteractionHelp", Vehicle.getInteractionHelp)
	SpecializationUtil.registerFunction(vehicleType, "getDistanceToNode", Vehicle.getDistanceToNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIActive", Vehicle.getIsAIActive)
	SpecializationUtil.registerFunction(vehicleType, "addVehicleToAIImplementList", Vehicle.addVehicleToAIImplementList)
	SpecializationUtil.registerFunction(vehicleType, "setOperatingTime", Vehicle.setOperatingTime)
	SpecializationUtil.registerFunction(vehicleType, "requestActionEventUpdate", Vehicle.requestActionEventUpdate)
	SpecializationUtil.registerFunction(vehicleType, "removeActionEvents", Vehicle.removeActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateActionEvents", Vehicle.updateActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "registerActionEvents", Vehicle.registerActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateSelectableObjects", Vehicle.updateSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "registerSelectableObjects", Vehicle.registerSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "addSubselection", Vehicle.addSubselection)
	SpecializationUtil.registerFunction(vehicleType, "getRootVehicle", Vehicle.getRootVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getChildVehicles", Vehicle.getChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "addChildVehicles", Vehicle.addChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "updateChildVehicles", Vehicle.updateChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSelected", Vehicle.getCanBeSelected)
	SpecializationUtil.registerFunction(vehicleType, "getBlockSelection", Vehicle.getBlockSelection)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleSelectable", Vehicle.getCanToggleSelectable)
	SpecializationUtil.registerFunction(vehicleType, "unselectVehicle", Vehicle.unselectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "selectVehicle", Vehicle.selectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSelected", Vehicle.getIsSelected)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedObject", Vehicle.getSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedVehicle", Vehicle.getSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedVehicle", Vehicle.setSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedObject", Vehicle.setSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Vehicle.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerFunction(vehicleType, "getActiveFarm", Vehicle.getActiveFarm)
	SpecializationUtil.registerFunction(vehicleType, "onVehicleWakeUpCallback", Vehicle.onVehicleWakeUpCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanByMounted", Vehicle.getCanByMounted)
	SpecializationUtil.registerFunction(vehicleType, "getName", Vehicle.getName)
	SpecializationUtil.registerFunction(vehicleType, "getFullName", Vehicle.getFullName)
	SpecializationUtil.registerFunction(vehicleType, "getCanBePickedUp", Vehicle.getCanBePickedUp)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeReset", Vehicle.getCanBeReset)
	SpecializationUtil.registerFunction(vehicleType, "getShowOnMap", Vehicle.getShowOnMap)
	SpecializationUtil.registerFunction(vehicleType, "getIsInUse", Vehicle.getIsInUse)
	SpecializationUtil.registerFunction(vehicleType, "getPropertyState", Vehicle.getPropertyState)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAllowed", Vehicle.getAreControlledActionsAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAvailable", Vehicle.getAreControlledActionsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "playControlledActions", Vehicle.playControlledActions)
	SpecializationUtil.registerFunction(vehicleType, "getActionControllerDirection", Vehicle.getActionControllerDirection)
	SpecializationUtil.registerFunction(vehicleType, "setMapHotspot", Vehicle.setMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getMapHotspot", Vehicle.getMapHotspot)
end

function Vehicle.init()
	g_configurationManager:addConfigurationType("baseColor", g_i18n:getText("configuration_baseColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("design", g_i18n:getText("configuration_design"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_configurationManager:addConfigurationType("designColor", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("vehicleType", g_i18n:getText("configuration_design"), nil, , ConfigurationUtil.getStoreAddtionalConfigData, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_storeManager:addSpecType("age", "shopListAttributeIconLifeTime", nil, Vehicle.getSpecValueAge)
	g_storeManager:addSpecType("operatingTime", "shopListAttributeIconOperatingHours", nil, Vehicle.getSpecValueOperatingTime)
	g_storeManager:addSpecType("dailyUpkeep", "shopListAttributeIconMaintenanceCosts", nil, Vehicle.getSpecValueDailyUpkeep)
	g_storeManager:addSpecType("workingWidth", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidth, Vehicle.getSpecValueWorkingWidth)
	g_storeManager:addSpecType("speedLimit", "shopListAttributeIconWorkSpeed", Vehicle.loadSpecValueSpeedLimit, Vehicle.getSpecValueSpeedLimit)
	g_storeManager:addSpecType("combination", "shopListAttributeIconCombinations", Vehicle.loadSpecValueCombinations, Vehicle.getSpecValueCombinations)
	g_storeManager:addSpecType("slots", "shopListAttributeIconSlots", nil, Vehicle.getSpecValueSlots)
end

function Vehicle:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or Vehicle_mt)
	self.isAddedToMission = false
	self.isDeleted = false
	self.updateLoopIndex = -1
	self.loadingState = BaseMission.VEHICLE_LOAD_OK
	self.actionController = VehicleActionController:new(self)

	return self
end

function Vehicle:load(vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(vehicleData.filename)
	self.configFileName = vehicleData.filename
	self.baseDirectory = baseDirectory
	self.customEnvironment = modName
	self.typeName = vehicleData.typeName
	self.isVehicleSaved = Utils.getNoNil(vehicleData.isVehicleSaved, true)
	self.configurations = Utils.getNoNil(vehicleData.configurations, {})
	self.boughtConfigurations = Utils.getNoNil(vehicleData.boughtConfigurations, {})
	local typeDef = g_vehicleTypeManager:getVehicleTypeByName(self.typeName)

	if typeDef == nil then
		g_logManager:xmlWarning(self.configFileName, "Unable to find vehicleType '%s'", self.typeName)
		self:setLoadingState(BaseMission.VEHICLE_LOAD_ERROR)

		return self.loadingState
	end

	self.vehicleType = typeDef
	self.specializations = typeDef.specializations
	self.specializationNames = typeDef.specializationNames
	self.specializationsByName = typeDef.specializationsByName
	self.eventListeners = typeDef.eventListeners
	self.actionEvents = {}
	self.xmlFile = loadXMLFile("TempConfig", vehicleData.filename)
	self.isAddedToPhysics = false

	for funcName, func in pairs(typeDef.functions) do
		self[funcName] = func
	end

	local data = {
		{
			posX = vehicleData.posX,
			posY = vehicleData.posY,
			posZ = vehicleData.posZ,
			yOffset = vehicleData.yOffset,
			isAbsolute = vehicleData.isAbsolute
		},
		{
			rotX = vehicleData.rotX,
			rotY = vehicleData.rotY,
			rotZ = vehicleData.rotZ
		},
		vehicleData.isVehicleSaved,
		vehicleData.propertyState,
		vehicleData.ownerFarmId,
		vehicleData.price,
		vehicleData.savegame,
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments,
		vehicleData.componentPositions
	}
	local item = g_storeManager:getItemByXMLFilename(self.configFileName)

	if item ~= nil and item.configurations ~= nil then
		for configName, _ in pairs(item.configurations) do
			local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)

			if self.configurations[configName] == nil then
				ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
			end

			ConfigurationUtil.addBoughtConfiguration(self, configName, defaultConfigId)
		end

		for configName, value in pairs(self.configurations) do
			if item.configurations[configName] == nil then
				g_logManager:xmlWarning(self.configFileName, "Configurations are not present anymore. Ignoring this configuration (%s)!", configName)

				self.configurations[configName] = nil
				self.boughtConfigurations[configName] = nil
			else
				local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)

				if value > #item.configurations[configName] then
					g_logManager:xmlWarning(self.configFileName, "Configuration with index '%d' is not present anymore. Using default configuration instead!", value)

					if self.boughtConfigurations[configName] ~= nil then
						self.boughtConfigurations[configName][value] = nil

						if next(self.boughtConfigurations[configName]) == nil then
							self.boughtConfigurations[configName] = nil
						end
					end

					ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
				else
					ConfigurationUtil.addBoughtConfiguration(self, configName, value)
				end
			end
		end
	end

	for i = 1, table.getn(self.specializations) do
		local specEntryName = "spec_" .. self.specializationNames[i]

		if self[specEntryName] ~= nil then
			g_logManager:xmlError(self.configFileName, "The vehicle specialization '%s' could not be added because variable '%s' already exists!", self.specializationNames[i], specEntryName)
			self:setLoadingState(BaseMission.VEHICLE_LOAD_ERROR)
		end

		local env = {}

		setmetatable(env, {
			__index = self
		})

		env.actionEvents = {}
		self[specEntryName] = env
	end

	SpecializationUtil.raiseEvent(self, "onPreLoad", vehicleData.savegame)

	if self.loadingState ~= BaseMission.VEHICLE_LOAD_OK then
		g_logManager:xmlError(self.configFileName, "Vehicle pre-loading failed!")

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
		end

		return self.loadingState
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.filename", "vehicle.base.filename")

	self.i3dFilename = getXMLString(self.xmlFile, "vehicle.base.filename")

	if asyncCallbackFunction ~= nil then
		g_i3DManager:loadSharedI3DFile(self.i3dFilename, baseDirectory, true, false, true, self.loadFinished, self, data)
	else
		local i3dNode = g_i3DManager:loadSharedI3DFile(self.i3dFilename, baseDirectory, true, false, true)

		return self:loadFinished(i3dNode, data)
	end
end

function Vehicle:loadFinished(i3dNode, arguments)
	self:setLoadingState(BaseMission.VEHICLE_LOAD_OK)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.speedLimit#value", "vehicle.base.speedLimit#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.steeringAxleNode#index", "vehicle.base.steeringAxle#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.size#width", "vehicle.base.size#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.size#length", "vehicle.base.size#length")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.size#widthOffset", "vehicle.base.size#widthOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.size#lengthOffset", "vehicle.base.size#lengthOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.typeDesc", "vehicle.base.typeDesc")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.components", "vehicle.base.components")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.components.component", "vehicle.base.components.component")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.base.components.component1", "vehicle.base.components.component")

	local position, rotation, isSave, propertyState, ownerFarmId, price, savegame, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, componentPositions = unpack(arguments)

	if i3dNode == 0 then
		self:setLoadingState(BaseMission.VEHICLE_LOAD_ERROR)

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
		end

		return self.loadingState
	end

	if savegame ~= nil then
		local i = 0

		while true do
			local key = string.format(savegame.key .. ".boughtConfiguration(%d)", i)

			if not hasXMLProperty(savegame.xmlFile, key) then
				break
			end

			local name = getXMLString(savegame.xmlFile, key .. "#name")
			local id = getXMLInt(savegame.xmlFile, key .. "#id")

			ConfigurationUtil.addBoughtConfiguration(self, name, id)

			i = i + 1
		end

		self.tourId = nil
		local tourId = getXMLString(savegame.xmlFile, savegame.key .. "#tourId")

		if tourId ~= nil then
			self.tourId = tourId

			if g_currentMission ~= nil then
				g_currentMission.tourVehicles[self.tourId] = self
			end
		end
	end

	self.age = 0
	self.propertyState = propertyState

	self:setOwnerFarmId(ownerFarmId, true)

	if savegame ~= nil then
		local farmId = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#farmId"), AccessHandler.EVERYONE)

		if g_farmManager.spFarmWasMerged and farmId ~= AccessHandler.EVERYONE then
			farmId = FarmManager.SINGLEPLAYER_FARM_ID
		end

		self:setOwnerFarmId(farmId, true)
	end

	self.price = price

	if self.price == 0 or self.price == nil then
		local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
		self.price = StoreItemUtil.getDefaultPrice(storeItem, self.configurations)
	end

	self.typeDesc = XMLUtil.getXMLI18NValue(self.xmlFile, "vehicle.base.typeDesc", getXMLString, "", "TypeDescription", self.customEnvironment, true)
	self.synchronizePosition = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.base.synchronizePosition"), true)
	self.highPrecisionPositionSynchronization = false
	self.supportsPickUp = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.base.supportsPickUp"), true)
	self.canBeReset = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.base.canBeReset"), true)
	self.rootNode = getChildAt(i3dNode, 0)
	self.serverMass = 0
	self.isMassDirty = false
	self.components = {}
	self.vehicleNodes = {}
	local numComponents = getNumOfChildren(i3dNode)
	local rootPosition = {
		0,
		0,
		0
	}
	local i = 1
	numComponents = getXMLInt(self.xmlFile, "vehicle.base.components#numComponents") or numComponents

	while true do
		local namei = string.format("vehicle.base.components.component(%d)", i - 1)

		if not hasXMLProperty(self.xmlFile, namei) then
			break
		end

		if numComponents < i then
			g_logManager:xmlWarning(self.configFileName, "Invalid components count. I3D file has '%d' components, but tried to load component no. '%d'!", numComponents, i + 1)

			break
		end

		local component = {
			node = getChildAt(i3dNode, 0)
		}

		if self:loadComponentFromXML(component, self.xmlFile, namei, rootPosition, i) then
			local x, y, z = getWorldTranslation(component.node)
			local qx, qy, qz, qw = getWorldQuaternion(component.node)
			component.networkInterpolators = {
				position = InterpolatorPosition:new(x, y, z),
				quaternion = InterpolatorQuaternion:new(qx, qy, qz, qw)
			}

			table.insert(self.components, component)
		end

		i = i + 1
	end

	delete(i3dNode)

	self.numComponents = table.getn(self.components)

	if numComponents ~= self.numComponents then
		g_logManager:xmlWarning(self.configFileName, "I3D file offers '%d' objects, but '%d' components have been loaded!", numComponents, self.numComponents)
	end

	if self.numComponents == 0 then
		g_logManager:xmlWarning(self.configFileName, "No components defined for vehicle!")
		self:setLoadingState(BaseMission.VEHICLE_LOAD_ERROR)

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
		end

		return self.loadingState
	end

	self.i3dMappings = {}
	local i = 0

	while true do
		local key = string.format("vehicle.i3dMappings.i3dMapping(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local id = getXMLString(self.xmlFile, key .. "#id")
		local node = getXMLString(self.xmlFile, key .. "#node")

		if id ~= nil and node ~= nil then
			self.i3dMappings[id] = node
		end

		i = i + 1
	end

	self.steeringAxleNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.base.steeringAxle#node"), self.i3dMappings)

	if self.steeringAxleNode == nil then
		self.steeringAxleNode = self.components[1].node
	end

	self:loadSchemaOverlay(self.xmlFile)

	self.componentJoints = {}
	local componentJointI = 0

	while true do
		local key = string.format("vehicle.base.components.joint(%d)", componentJointI)
		local index1 = getXMLInt(self.xmlFile, key .. "#component1")
		local index2 = getXMLInt(self.xmlFile, key .. "#component2")

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

		local jointIndexStr = getXMLString(self.xmlFile, key .. "#node")

		if index1 == nil or index2 == nil or jointIndexStr == nil then
			break
		end

		local jointNode = I3DUtil.indexToObject(self.components, jointIndexStr, self.i3dMappings)

		if jointNode ~= nil and jointNode ~= 0 then
			local jointDesc = {}

			if self:loadComponentJointFromXML(jointDesc, self.xmlFile, key, componentJointI, jointNode, index1, index2) then
				table.insert(self.componentJoints, jointDesc)
			end
		end

		componentJointI = componentJointI + 1
	end

	local collisionPairI = 0
	self.collisionPairs = {}

	while true do
		local key = string.format("vehicle.base.components.collisionPair(%d)", collisionPairI)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local enabled = getXMLBool(self.xmlFile, key .. "#enabled")
		local index1 = getXMLInt(self.xmlFile, key .. "#component1")
		local index2 = getXMLInt(self.xmlFile, key .. "#component2")

		if index1 ~= nil and index2 ~= nil and enabled ~= nil then
			local component1 = self.components[index1]
			local component2 = self.components[index2]

			if component1 ~= nil and component2 ~= nil then
				if not enabled then
					table.insert(self.collisionPairs, {
						component1 = component1,
						component2 = component2,
						enabled = enabled
					})
				end
			else
				g_logManager:xmlWarning(self.configFileName, "Failed to load collision pair '%s'. Unknown component indices. Indices start with 1.", key)
			end
		end

		collisionPairI = collisionPairI + 1
	end

	self.supportsRadio = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.base.supportsRadio"), true)
	self.allowsInput = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.base.input#allowed"), true)
	self.sizeWidth, self.sizeLength, self.widthOffset, self.lengthOffset = StoreItemUtil.getSizeValuesFromXML(self.xmlFile, "vehicle", 0, self.configurations)
	self.showTailwaterDepthWarning = false
	self.thresholdTailwaterDepthWarning = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.base.tailwaterDepth#warning"), 1)
	self.thresholdTailwaterDepth = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.base.tailwaterDepth#threshold"), 2.5)
	self.networkTimeInterpolator = InterpolationTime:new(1.2)
	self.movingDirection = 0
	self.requiredDriveMode = 1
	self.rotatedTime = 0
	self.isBroken = false
	self.forceIsActive = false
	self.operatingTime = 0
	self.firstTimeRun = false
	self.lastPosition = nil
	self.lastSpeed = 0
	self.lastSpeedReal = 0
	self.lastSignedSpeed = 0
	self.lastSignedSpeedReal = 0
	self.lastMovedDistance = 0
	self.lastSpeedAcceleration = 0
	self.lastMoveTime = -10000
	self.operatingTime = 0
	self.isSelectable = true
	self.selectionObjects = {}
	self.currentSelection = {
		index = 0,
		subIndex = 1
	}
	self.selectionObject = {
		index = 0,
		isSelected = false,
		vehicle = self,
		subSelections = {}
	}
	self.childVehicles = {
		self
	}
	self.registeredActionEvents = {}
	self.actionEventUpdateRequested = false
	self.vehicleDirtyFlag = self:getNextDirtyFlag()

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:addDayChangeListener(self)
	end

	self.forcedMapHotspotType = nil
	local forcedMapHotspotType = getXMLString(self.xmlFile, "vehicle.base.mapHotspot#type")

	if forcedMapHotspotType ~= nil then
		if forcedMapHotspotType == "Tool" then
			self.forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_TOOL
		elseif forcedMapHotspotType == "Trailer" then
			self.forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_TRAILER
		elseif forcedMapHotspotType == "Combine" then
			self.forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_COMBINE
		elseif forcedMapHotspotType == "Steerable" then
			self.forcedMapHotspotType = MapHotspot.CATEGORY_VEHICLE_STEERABLE
		else
			g_logManager:xmlWarning(self.configFileName, "Unsupported forcedMapHotspotType '%s'!", forcedMapHotspotType)
		end
	end

	local speedLimit = math.huge

	for i = 1, table.getn(self.specializations) do
		if self.specializations[i].getDefaultSpeedLimit ~= nil then
			local limit = self.specializations[i].getDefaultSpeedLimit(self)
			speedLimit = math.min(limit, speedLimit)
		end
	end

	self.checkSpeedLimit = speedLimit == math.huge
	self.speedLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.base.speedLimit#value"), speedLimit)
	local objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.base.objectChanges", objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(objectChanges, true)

	if self.configurations.vehicleType ~= nil then
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration", self.configurations.vehicleType, self.components, self)
	end

	SpecializationUtil.raiseEvent(self, "onLoad", savegame)

	if self.loadingState ~= BaseMission.VEHICLE_LOAD_OK then
		g_logManager:xmlError(self.configFileName, "Vehicle loading failed!")

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
		end

		return self.loadingState
	end

	self.actionController:load(savegame)

	if self.configurations.design ~= nil then
		ConfigurationUtil.applyDesign(self, self.xmlFile, self.configurations.design)
	end

	if self.configurations.baseColor ~= nil then
		ConfigurationUtil.setColor(self, self.xmlFile, "baseColor", self.configurations.baseColor)
	end

	if self.configurations.designColor ~= nil then
		ConfigurationUtil.setColor(self, self.xmlFile, "designColor", self.configurations.designColor)
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			local component2 = self.components[jointDesc.componentIndices[2]].node
			local jointNode = jointDesc.jointNode

			if self:getParentComponent(jointNode) == component2 then
				jointNode = jointDesc.jointNodeActor1
			end

			if self:getParentComponent(jointNode) ~= component2 then
				setTranslation(component2, localToLocal(component2, jointNode, 0, 0, 0))
				setRotation(component2, localRotationToLocal(component2, jointNode, 0, 0, 0))
				link(jointNode, component2)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onPostLoad", savegame)

	if self.loadingState ~= BaseMission.VEHICLE_LOAD_OK then
		g_logManager:xmlError(self.configFileName, "Vehicle post-loading failed!")

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
		end

		return self.loadingState
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			local component2 = self.components[jointDesc.componentIndices[2]]
			local jointNode = jointDesc.jointNode

			if self:getParentComponent(jointNode) == component2.node then
				jointNode = jointDesc.jointNodeActor1
			end

			if self:getParentComponent(jointNode) ~= component2.node then
				local ox = 0
				local oy = 0
				local oz = 0

				if jointDesc.jointNodeActor1 ~= jointDesc.jointNode then
					local x1, y1, z1 = localToLocal(jointDesc.jointNode, component2.node, 0, 0, 0)
					local x2, y2, z2 = localToLocal(jointDesc.jointNodeActor1, component2.node, 0, 0, 0)
					oz = z1 - z2
					oy = y1 - y2
					ox = x1 - x2
				end

				local x, y, z = localToWorld(component2.node, ox, oy, oz)
				local rx, ry, rz = localRotationToWorld(component2.node, 0, 0, 0)

				link(getRootNode(), component2.node)
				setWorldTranslation(component2.node, x, y, z)
				setWorldRotation(component2.node, rx, ry, rz)

				component2.originalTranslation = {
					x,
					y,
					z
				}
				component2.originalRotation = {
					rx,
					ry,
					rz
				}
				component2.sentTranslation = {
					x,
					y,
					z
				}
				component2.sentRotation = {
					rx,
					ry,
					rz
				}
			end
		end

		for _, jointDesc in pairs(self.componentJoints) do
			self:setComponentJointFrame(jointDesc, 0)
			self:setComponentJointFrame(jointDesc, 1)
		end
	end

	if savegame ~= nil then
		self.age = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#age"), 0)
		self.price = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#price"), self.price)
		self.propertyState = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#propertyState"), self.propertyState)
		self.activeMissionId = getXMLInt(savegame.xmlFile, savegame.key .. "#activeMissionId")
		local operatingTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#operatingTime"), self.operatingTime) * 1000

		self:setOperatingTime(operatingTime, true)

		local findPlace = savegame.resetVehicles and not savegame.keepPosition

		if not findPlace then
			local isAbsolute = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#isAbsolute"), false)

			if isAbsolute then
				local componentPosition = {}
				local i = 1

				while true do
					local componentKey = string.format(savegame.key .. ".component%d", i)

					if not hasXMLProperty(savegame.xmlFile, componentKey) then
						break
					end

					local x, y, z = StringUtil.getVectorFromString(getXMLString(savegame.xmlFile, componentKey .. "#position"))
					local xRot, yRot, zRot = StringUtil.getVectorFromString(getXMLString(savegame.xmlFile, componentKey .. "#rotation"))

					if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
						findPlace = true

						break
					end

					xRot = math.rad(xRot)
					yRot = math.rad(yRot)
					zRot = math.rad(zRot)

					table.insert(componentPosition, {
						x = x,
						y = y,
						z = z,
						xRot = xRot,
						yRot = yRot,
						zRot = zRot
					})

					i = i + 1
				end

				if #componentPosition == #self.components then
					for i = 1, #self.components do
						local p = componentPosition[i]

						self:setWorldPosition(p.x, p.y, p.z, p.xRot, p.yRot, p.zRot, i, true)
					end
				else
					findPlace = true

					g_logManager:xmlWarning(self.configFileName, "Invalid savegame component count. Ignoring savegame position!")
				end
			else
				local yOffset = getXMLFloat(savegame.xmlFile, savegame.key .. "#yOffset")
				local xPosition = getXMLFloat(savegame.xmlFile, savegame.key .. "#xPosition")
				local zPosition = getXMLFloat(savegame.xmlFile, savegame.key .. "#zPosition")
				local yRotation = getXMLFloat(savegame.xmlFile, savegame.key .. "#yRotation")

				if yOffset == nil or xPosition == nil or zPosition == nil or yRotation == nil then
					findPlace = true
				else
					self:setRelativePosition(xPosition, yOffset, zPosition, math.rad(yRotation))
				end
			end
		end

		if findPlace then
			if savegame.resetVehicles and not savegame.keepPosition then
				local x, _, z, place, width, offset = PlacementUtil.getPlace(g_currentMission:getResetPlaces(), self.sizeWidth, self.sizeLength, self.widthOffset, self.lengthOffset, g_currentMission.usedLoadPlaces, true, false, true)

				if x ~= nil then
					local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)

					PlacementUtil.markPlaceUsed(g_currentMission.usedLoadPlaces, place, width)
					self:setRelativePosition(x, offset, z, yRot)
				else
					self:setLoadingState(BaseMission.VEHICLE_LOAD_NO_SPACE)

					if asyncCallbackFunction ~= nil then
						asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)
					end

					return self.loadingState
				end
			else
				self:setLoadingState(BaseMission.VEHICLE_LOAD_DELAYED)
			end
		end
	else
		self:setAbsolutePosition(position.posX, self:getLimitedVehicleYPosition(position), position.posZ, rotation.rotX, rotation.rotY, rotation.rotZ, componentPositions)
	end

	self:addToPhysics()
	self:updateSelectableObjects()
	self:setSelectedVehicle(self, nil, true)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", savegame)

	if componentPositions ~= nil and savegame == nil then
		self:setAbsolutePosition(position.posX, self:getLimitedVehicleYPosition(position), position.posZ, rotation.rotX, rotation.rotY, rotation.rotZ, componentPositions)
	end

	if asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, self, self.loadingState, asyncCallbackArguments)
	else
		return self.loadingState
	end
end

function Vehicle:delete()
	self.isDeleting = true

	g_messageCenter:unsubscribeAll(self)

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:removeDayChangeListener(self)
	end

	local rootVehicle = self:getRootVehicle()

	if rootVehicle:getIsAIActive() then
		rootVehicle:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)
	end

	g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
	self:removeActionEvents()
	g_inputBinding:endActionEventsModification()
	SpecializationUtil.raiseEvent(self, "onPreDelete")
	SpecializationUtil.raiseEvent(self, "onDelete")

	if self.isServer then
		for _, v in pairs(self.componentJoints) do
			if v.jointIndex ~= 0 then
				removeJoint(v.jointIndex)
			end
		end

		removeWakeUpReport(self.rootNode)
	end

	for _, v in pairs(self.components) do
		delete(v.node)
	end

	g_i3DManager:releaseSharedI3DFile(self.i3dFilename, self.baseDirectory, true)
	delete(self.xmlFile)

	self.isDeleting = false
	self.isDeleted = true

	Vehicle:superClass().delete(self)
end

function Vehicle:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLBool(xmlFile, key .. "#isAbsolute", true)
	setXMLFloat(xmlFile, key .. "#age", self.age)
	setXMLFloat(xmlFile, key .. "#price", self.price)
	setXMLInt(xmlFile, key .. "#farmId", self:getOwnerFarmId())
	setXMLInt(xmlFile, key .. "#propertyState", self.propertyState)
	setXMLFloat(xmlFile, key .. "#operatingTime", self.operatingTime / 1000)

	if self.activeMissionId ~= nil then
		setXMLInt(xmlFile, key .. "#activeMissionId", self.activeMissionId)
	end

	if self.tourId ~= nil then
		setXMLString(xmlFile, key .. "#tourId", self.tourId)
	end

	if not self.isBroken then
		for k, component in ipairs(self.components) do
			local compKey = string.format("%s.component%d", key, k)
			local node = component.node
			local x, y, z = getWorldTranslation(node)
			local xRot, yRot, zRot = getWorldRotation(node)

			setXMLString(xmlFile, compKey .. "#position", string.format("%.4f %.4f %.4f", x, y, z))
			setXMLString(xmlFile, compKey .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(xRot), math.deg(yRot), math.deg(zRot)))
		end
	end

	local configIndex = 0

	for configName, configId in pairs(self.configurations) do
		local configKey = string.format("%s.configuration(%d)", key, configIndex)

		setXMLString(xmlFile, configKey .. "#name", configName)
		setXMLInt(xmlFile, configKey .. "#id", configId)

		configIndex = configIndex + 1
	end

	configIndex = 0

	for configName, configIds in pairs(self.boughtConfigurations) do
		for configId, _ in pairs(configIds) do
			local configKey = string.format("%s.boughtConfiguration(%d)", key, configIndex)

			setXMLString(xmlFile, configKey .. "#name", configName)
			setXMLInt(xmlFile, configKey .. "#id", configId)

			configIndex = configIndex + 1
		end
	end

	for id, spec in pairs(self.specializations) do
		local name = self.specializationNames[id]

		if spec.saveToXMLFile ~= nil then
			spec.saveToXMLFile(self, xmlFile, key .. "." .. name, usedModNames)
		end
	end

	self.actionController:saveToXMLFile(xmlFile, key .. ".actionController", usedModNames)
end

function Vehicle:saveStatsToXMLFile(xmlFile, key)
	local isTabbable = self.getIsTabbable == nil or self:getIsTabbable()

	if self.isDeleted or not self.isVehicleSaved or not isTabbable then
		return false
	end

	local name = "Unknown"
	local categoryName = "unknown"
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		if storeItem.name ~= nil then
			name = tostring(storeItem.name)
		end

		if storeItem.categoryName ~= nil and storeItem.categoryName ~= "" then
			categoryName = tostring(storeItem.categoryName)
		end
	end

	setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(name))
	setXMLString(xmlFile, key .. "#category", HTMLUtil.encodeToHTML(categoryName))
	setXMLString(xmlFile, key .. "#type", HTMLUtil.encodeToHTML(tostring(self.typeName)))

	if self.components[1] ~= nil and self.components[1].node ~= 0 then
		local x, y, z = getWorldTranslation(self.components[1].node)

		setXMLFloat(xmlFile, key .. "#x", x)
		setXMLFloat(xmlFile, key .. "#y", y)
		setXMLFloat(xmlFile, key .. "#z", z)
	end

	for id, spec in pairs(self.specializations) do
		local name = self.specializationNames[id]

		if spec.saveStatsToXMLFile ~= nil then
			spec.saveStatsToXMLFile(self, xmlFile, key)
		end
	end

	return true
end

function Vehicle:readStream(streamId, connection)
	Vehicle:superClass().readStream(self, streamId)

	local configFile = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local typeName = streamReadString(streamId)
	local configurations = {}
	local numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)

	for i = 1, numConfigs do
		local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		local configId = streamReadUInt16(streamId)
		local configName = g_configurationManager:getConfigurationNameByIndex(configNameId + 1)

		if configName ~= nil then
			configurations[configName] = configId + 1
		end
	end

	local boughtConfigurations = {}
	local numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)

	for i = 1, numConfigs do
		local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		local configName = g_configurationManager:getConfigurationNameByIndex(configNameId + 1)
		boughtConfigurations[configName] = {}
		local numBoughtConfigIds = streamReadUInt16(streamId)

		for j = 1, numBoughtConfigIds do
			local boughtConfigId = streamReadUInt16(streamId)
			boughtConfigurations[configName][boughtConfigId + 1] = true
		end
	end

	if self.configFileName == nil then
		local vehicleData = {
			filename = configFile,
			isAbsolute = false,
			typeName = typeName,
			posX = 0,
			posY = nil,
			posZ = 0,
			yOffset = 0,
			rotX = 0,
			rotY = 0,
			rotZ = 0,
			isVehicleSaved = true,
			price = 0,
			propertyState = Vehicle.PROPERTY_STATE_NONE,
			ownerFarmId = self.ownerFarmId,
			isLeased = 0,
			configurations = configurations,
			boughtConfigurations = boughtConfigurations
		}

		self:load(vehicleData)
	end

	self:removeFromPhysics()

	local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
	local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

	for i = 1, table.getn(self.components) do
		local component = self.components[i]
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local x_rot = NetworkUtil.readCompressedAngle(streamId)
		local y_rot = NetworkUtil.readCompressedAngle(streamId)
		local z_rot = NetworkUtil.readCompressedAngle(streamId)
		local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)

		self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, i, true)
		component.networkInterpolators.position:setPosition(x, y, z)
		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	end

	self.networkTimeInterpolator:reset()
	self:addToPhysics()

	self.serverMass = streamReadFloat32(streamId)
	self.age = streamReadUInt16(streamId)

	self:setOperatingTime(streamReadFloat32(streamId), true)

	self.price = streamReadInt32(streamId)
	self.propertyState = streamReadUIntN(streamId, 2)

	SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
end

function Vehicle:writeStream(streamId, connection)
	Vehicle:superClass().writeStream(self, streamId)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	streamWriteString(streamId, self.typeName)

	local numConfigs = 0

	for _, _ in pairs(self.configurations) do
		numConfigs = numConfigs + 1
	end

	streamWriteUIntN(streamId, numConfigs, ConfigurationUtil.SEND_NUM_BITS)

	for configName, configId in pairs(self.configurations) do
		local configNameId = g_configurationManager:getConfigurationIndexByName(configName)

		streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, configId - 1)
	end

	local numBoughtConfigs = 0

	for _, _ in pairs(self.boughtConfigurations) do
		numBoughtConfigs = numBoughtConfigs + 1
	end

	streamWriteUIntN(streamId, numBoughtConfigs, ConfigurationUtil.SEND_NUM_BITS)

	for configName, configIds in pairs(self.boughtConfigurations) do
		local numBoughtConfigIds = 0

		for _, _ in pairs(configIds) do
			numBoughtConfigIds = numBoughtConfigIds + 1
		end

		local configNameId = g_configurationManager:getConfigurationIndexByName(configName)

		streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, numBoughtConfigIds)

		for id, _ in pairs(configIds) do
			streamWriteUInt16(streamId, id - 1)
		end
	end

	local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
	local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

	for i = 1, table.getn(self.components) do
		local component = self.components[i]
		local x, y, z = getWorldTranslation(component.node)
		local x_rot, y_rot, z_rot = getWorldRotation(component.node)

		NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
		NetworkUtil.writeCompressedAngle(streamId, x_rot)
		NetworkUtil.writeCompressedAngle(streamId, y_rot)
		NetworkUtil.writeCompressedAngle(streamId, z_rot)
	end

	streamWriteFloat32(streamId, self.serverMass)
	streamWriteUInt16(streamId, self.age)
	streamWriteFloat32(streamId, self.operatingTime)
	streamWriteInt32(streamId, self.price)
	streamWriteUIntN(streamId, self.propertyState, 2)
	SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
end

function Vehicle:readUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			self.networkTimeInterpolator:startNewPhaseNetwork()

			local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
			local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

			for i = 1, table.getn(self.components) do
				local component = self.components[i]

				if not component.isStatic then
					local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
					local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
					local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
					local x_rot = NetworkUtil.readCompressedAngle(streamId)
					local y_rot = NetworkUtil.readCompressedAngle(streamId)
					local z_rot = NetworkUtil.readCompressedAngle(streamId)
					local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)

					component.networkInterpolators.position:setTargetPosition(x, y, z)
					component.networkInterpolators.quaternion:setTargetQuaternion(qx, qy, qz, qw)
				end
			end

			SpecializationUtil.raiseEvent(self, "onReadPositionUpdateStream", streamId, connection)
		end
	end

	if Vehicle.debugNetworkUpdate then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.readUpdateStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetReadOffset(streamId)

			spec.readUpdateStream(self, streamId, timestamp, connection)
			print("  " .. tostring(className) .. " read " .. streamGetReadOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
	end
end

function Vehicle:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer and streamWriteBool(streamId, bitAND(dirtyMask, self.vehicleDirtyFlag) ~= 0) then
		local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
		local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

		for i = 1, table.getn(self.components) do
			local component = self.components[i]

			if not component.isStatic then
				local x, y, z = getWorldTranslation(component.node)
				local x_rot, y_rot, z_rot = getWorldRotation(component.node)

				NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
				NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
				NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
				NetworkUtil.writeCompressedAngle(streamId, x_rot)
				NetworkUtil.writeCompressedAngle(streamId, y_rot)
				NetworkUtil.writeCompressedAngle(streamId, z_rot)
			end
		end

		SpecializationUtil.raiseEvent(self, "onWritePositionUpdateStream", streamId, connection, dirtyMask)
	end

	if Vehicle.debugNetworkUpdate then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.writeUpdateStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetWriteOffset(streamId)

			spec.writeUpdateStream(self, streamId, connection, dirtyMask)
			print("  " .. tostring(className) .. " Wrote " .. streamGetWriteOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
	end
end

function Vehicle:updateVehicleSpeed(dt)
	if self.firstTimeRun and not self.components[1].isStatic then
		local speedReal = 0
		local movedDistance = 0
		local movingDirection = 0
		local signedSpeedReal = 0

		if not self.isServer or self.components[1].isKinematic then
			if not self.isServer and self.synchronizePosition then
				local interpPos = self.components[1].networkInterpolators.position
				local dx = 0
				local dy = 0
				local dz = 0

				if self.networkTimeInterpolator:isInterpolating() then
					dx, dy, dz = worldDirectionToLocal(self.components[1].node, interpPos.targetPositionX - interpPos.lastPositionX, interpPos.targetPositionY - interpPos.lastPositionY, interpPos.targetPositionZ - interpPos.lastPositionZ)
				end

				if dz > 0.001 then
					movingDirection = 1
				elseif dz < -0.001 then
					movingDirection = -1
				end

				speedReal = MathUtil.vector3Length(dx, dy, dz) / self.networkTimeInterpolator.interpolationDuration
				signedSpeedReal = speedReal * (dz >= 0 and 1 or -1)
				movedDistance = speedReal * dt
			else
				local x, y, z = getWorldTranslation(self.components[1].node)

				if self.lastPosition == nil then
					self.lastPosition = {
						x,
						y,
						z
					}
				end

				local dx, dy, dz = worldDirectionToLocal(self.components[1].node, x - self.lastPosition[1], y - self.lastPosition[2], z - self.lastPosition[3])
				self.lastPosition[3] = z
				self.lastPosition[2] = y
				self.lastPosition[1] = x

				if dz > 0.001 then
					movingDirection = 1
				elseif dz < -0.001 then
					movingDirection = -1
				end

				movedDistance = MathUtil.vector3Length(dx, dy, dz)
				speedReal = movedDistance / dt
				signedSpeedReal = speedReal * (dz >= 0 and 1 or -1)
			end
		elseif self.components[1].isDynamic then
			local vx, vy, vz = getLocalLinearVelocity(self.components[1].node)
			speedReal = MathUtil.vector3Length(vx, vy, vz) * 0.001
			movedDistance = speedReal * g_physicsDt
			signedSpeedReal = speedReal * (vz >= 0 and 1 or -1)

			if vz > 0.001 then
				movingDirection = 1
			elseif vz < -0.001 then
				movingDirection = -1
			end
		end

		if self.isServer then
			if g_physicsDtNonInterpolated > 0 then
				self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / g_physicsDtNonInterpolated
			end
		else
			self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / dt
		end

		if self.isServer then
			self.lastSpeed = self.lastSpeed * 0.5 + speedReal * 0.5
			self.lastSignedSpeed = self.lastSignedSpeed * 0.5 + signedSpeedReal * 0.5
		else
			self.lastSpeed = self.lastSpeed * 0.9 + speedReal * 0.1
			self.lastSignedSpeed = self.lastSignedSpeed * 0.9 + signedSpeedReal * 0.1
		end

		self.lastSpeedReal = speedReal
		self.lastSignedSpeedReal = signedSpeedReal
		self.movingDirection = movingDirection
		self.lastMovedDistance = movedDistance
	end
end

function Vehicle:update(dt)
	local isActive = self:getIsActive()
	self.isActive = isActive
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()
	self.updateLoopIndex = g_updateLoopIndex

	SpecializationUtil.raiseEvent(self, "onPreUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if not self.isServer and self.synchronizePosition then
		self.networkTimeInterpolator:update(dt)

		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()

		for i, component in pairs(self.components) do
			if not component.isStatic then
				local posX, posY, posZ = component.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
				local quatX, quatY, quatZ, quatW = component.networkInterpolators.quaternion:getInterpolatedValues(interpolationAlpha)

				self:setWorldPositionQuaternion(posX, posY, posZ, quatX, quatY, quatZ, quatW, i, false)
			end
		end

		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	SpecializationUtil.raiseEvent(self, "onUpdateInterpolation", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateVehicleSpeed(dt)

	if self.actionEventUpdateRequested then
		self:updateActionEvents()
	end

	self.actionController:update(dt)
	SpecializationUtil.raiseEvent(self, "onUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if Vehicle.debuggingActive then
		SpecializationUtil.raiseEvent(self, "onUpdateDebug", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	end

	SpecializationUtil.raiseEvent(self, "onPostUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if self.vehicleCharacter ~= nil then
		self.vehicleCharacter:setDirty(true)
	end

	if self.firstTimeRun and self.isMassDirty then
		self.isMassDirty = false

		self:updateMass()
	end

	self.firstTimeRun = true

	if self.isServer and not getIsSleeping(self.rootNode) then
		self:raiseActive()
	end

	VehicleDebug.updateDebug(self)
end

function Vehicle:updateTick(dt)
	local isActive = self:getIsActive()
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()
	self.wasTooFast = false

	if self.isServer then
		if self.synchronizePosition then
			local hasOwner = self:getOwner() ~= nil

			for i = 1, table.getn(self.components) do
				local component = self.components[i]

				if not component.isStatic then
					local x, y, z = getWorldTranslation(component.node)
					local x_rot, y_rot, z_rot = getWorldRotation(component.node)
					local sentTranslation = component.sentTranslation
					local sentRotation = component.sentRotation

					if hasOwner or math.abs(x - sentTranslation[1]) > 0.005 or math.abs(y - sentTranslation[2]) > 0.005 or math.abs(z - sentTranslation[3]) > 0.005 or math.abs(x_rot - sentRotation[1]) > 0.1 or math.abs(y_rot - sentRotation[2]) > 0.1 or math.abs(z_rot - sentRotation[3]) > 0.1 then
						self:raiseDirtyFlags(self.vehicleDirtyFlag)

						sentTranslation[1] = x
						sentTranslation[2] = y
						sentTranslation[3] = z
						sentRotation[1] = x_rot
						sentRotation[2] = y_rot
						sentRotation[3] = z_rot
						self.lastMoveTime = g_currentMission.time
					end
				end
			end
		end

		self.showTailwaterDepthWarning = false

		if not self.isBroken and not g_gui:getIsGuiVisible() then
			local tailwaterDepth = self:getTailwaterDepth()

			if self.thresholdTailwaterDepthWarning < tailwaterDepth then
				self.showTailwaterDepthWarning = true

				if self.thresholdTailwaterDepth < tailwaterDepth then
					self:setBroken()
				end
			end
		end

		local rootAttacherVehicle = self:getRootVehicle()

		if rootAttacherVehicle ~= nil and rootAttacherVehicle ~= self then
			rootAttacherVehicle.showTailwaterDepthWarning = rootAttacherVehicle.showTailwaterDepthWarning or self.showTailwaterDepthWarning
		end
	end

	if self:getIsOperating() then
		self:setOperatingTime(self.operatingTime + dt)
	end

	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	SpecializationUtil.raiseEvent(self, "onPostUpdateTick", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function Vehicle:updateEnd(dt)
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()

	SpecializationUtil.raiseEvent(self, "onUpdateEnd", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function Vehicle:draw()
	if self:getIsSelected() or self:getRootVehicle() == self then
		local isActiveForInput = self:getIsActiveForInput()
		local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)

		SpecializationUtil.raiseEvent(self, "onDraw", isActiveForInput, isActiveForInputIgnoreSelection, true)
	end

	VehicleDebug.drawDebug(self)

	if self.showTailwaterDepthWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_dontDriveIntoWater"), 2000)
	end
end

function Vehicle:drawUIInfo()
	if g_showVehicleDistance then
		local dist = calcDistanceFrom(self.rootNode, getCamera())

		if dist <= 350 then
			Utils.renderTextAtWorldPosition(x, y + 1, z, string.format("%.0f", dist), getCorrectTextSize(0.02), 0)
		end
	end
end

function Vehicle:setLoadingState(loadingState)
	if loadingState == BaseMission.VEHICLE_LOAD_OK or loadingState == BaseMission.VEHICLE_LOAD_ERROR or loadingState == BaseMission.VEHICLE_LOAD_DELAYED or loadingState == BaseMission.VEHICLE_LOAD_NO_SPACE then
		self.loadingState = loadingState
	else
		printCallstack()
		g_logManager:xmlError(self.configFileName, "Invalid loading state!")
	end
end

function Vehicle:addNodeObjectMapping(list)
	for _, v in pairs(self.components) do
		list[v.node] = self
	end
end

function Vehicle:removeNodeObjectMapping(list)
	for _, v in pairs(self.components) do
		list[v.node] = nil
	end
end

function Vehicle:addToPhysics()
	if not self.isAddedToPhysics then
		local lastMotorizedNode = nil

		for _, component in pairs(self.components) do
			addToPhysics(component.node)

			if component.motorized then
				if lastMotorizedNode ~= nil and self.isServer then
					addVehicleLink(lastMotorizedNode, component.node)
				end

				lastMotorizedNode = component.node
			end
		end

		self.isAddedToPhysics = true

		if self.isServer then
			for _, jointDesc in pairs(self.componentJoints) do
				self:createComponentJoint(self.components[jointDesc.componentIndices[1]], self.components[jointDesc.componentIndices[2]], jointDesc)
			end

			addWakeUpReport(self.rootNode, "onVehicleWakeUpCallback", self)
		end

		for _, collisionPair in pairs(self.collisionPairs) do
			setPairCollision(collisionPair.component1.node, collisionPair.component2.node, collisionPair.enabled)
		end

		self:setMassDirty()
	end

	return true
end

function Vehicle:removeFromPhysics()
	for _, component in pairs(self.components) do
		removeFromPhysics(component.node)
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			jointDesc.jointIndex = 0
		end

		removeWakeUpReport(self.rootNode)
	end

	self.isAddedToPhysics = false

	return true
end

function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
	local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)

	self:setAbsolutePosition(positionX, terrainHeight + offsetY, positionZ, 0, yRot, 0)
end

function Vehicle:setAbsolutePosition(positionX, positionY, positionZ, xRot, yRot, zRot, componentPositions)
	local tempRootNode = createTransformGroup("tempRootNode")

	setTranslation(tempRootNode, positionX, positionY, positionZ)
	setRotation(tempRootNode, xRot, yRot, zRot)

	for i, component in pairs(self.components) do
		local x, y, z = localToWorld(tempRootNode, unpack(component.originalTranslation))
		local rx, ry, rz = localRotationToWorld(tempRootNode, unpack(component.originalRotation))

		if componentPositions ~= nil and #componentPositions == #self.components then
			x, y, z = unpack(componentPositions[i][1])
			rx, ry, rz = unpack(componentPositions[i][2])
		end

		self:setWorldPosition(x, y, z, rx, ry, rz, i, true)
	end

	delete(tempRootNode)
	self.networkTimeInterpolator:reset()
end

function Vehicle:getLimitedVehicleYPosition(position)
	if position.posY == nil then
		local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, position.posX, 300, position.posZ)

		return terrainHeight + Utils.getNoNil(position.yOffset, 0)
	end

	return position.posY
end

function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, i, changeInterp)
	local component = self.components[i]

	setWorldTranslation(component.node, x, y, z)
	setWorldRotation(component.node, xRot, yRot, zRot)

	if changeInterp then
		local qx, qy, qz, qw = mathEulerToQuaternion(xRot, yRot, zRot)

		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
		component.networkInterpolators.position:setPosition(x, y, z)
	end
end

function Vehicle:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, i, changeInterp)
	local component = self.components[i]

	setWorldTranslation(component.node, x, y, z)
	setWorldQuaternion(component.node, qx, qy, qz, qw)

	if changeInterp then
		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
		component.networkInterpolators.position:setPosition(x, y, z)
	end
end

function Vehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	if self:getOwner() == connection then
		return 50
	end

	local x1, y1, z1 = getWorldTranslation(self.components[1].node)
	local dist = MathUtil.vector3Length(x1 - x, y1 - y, z1 - z)
	local clipDist = getClipDistance(self.components[1].node) * coeff

	return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end

function Vehicle:getPrice()
	return self.price
end

function Vehicle:getSellPrice()
	local priceMultiplier = 0.75
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local maxVehicleAge = storeItem.lifetime

	if maxVehicleAge ~= nil and maxVehicleAge ~= 0 then
		local ageMultiplier = 0.5 * math.min(self.age / maxVehicleAge, 1)
		local operatingTime = self.operatingTime / 3600000
		local operatingTimeMultiplier = 0.5 * math.min(operatingTime / (maxVehicleAge * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)
		priceMultiplier = priceMultiplier * math.exp(-3.5 * (ageMultiplier + operatingTimeMultiplier))
	end

	return math.max(math.floor(self:getPrice() * math.max(priceMultiplier, 0.05)) - self:getRepairPrice(true), 0)
end

function Vehicle:getIsOnField()
	local densityBits = 0

	for _, component in pairs(self.components) do
		local wx, wy, wz = localToWorld(component.node, getCenterOfMass(component.node))
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)

		if wy < h - 1 then
			break
		end

		local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, wx, wy, wz)
		densityBits = bitOR(densityBits, bits)

		if densityBits ~= 0 then
			return true
		end
	end

	return false
end

function Vehicle:getParentComponent(node)
	while node ~= 0 do
		if self:getIsVehicleNode(node) then
			return node
		end

		node = getParent(node)
	end

	return 0
end

function Vehicle:getLastSpeed(useAttacherVehicleSpeed)
	if useAttacherVehicleSpeed and self.attacherVehicle ~= nil then
		return self.attacherVehicle:getLastSpeed(true)
	end

	return self.lastSpeed * 3600
end

g_soundManager:registerModifierType("SPEED", Vehicle.getLastSpeed)

function Vehicle:getDeactivateOnLeave()
	return true
end

function Vehicle:getOwner()
	if self.owner ~= nil then
		return self.owner
	end

	return nil
end

function Vehicle:getActiveFarm()
	return self:getOwnerFarmId()
end

function Vehicle:getIsVehicleNode(nodeId)
	return self.vehicleNodes[nodeId] ~= nil
end

function Vehicle:getIsOperating()
	return false
end

function Vehicle:getIsActive()
	if self.isBroken then
		return false
	end

	if self.forceIsActive then
		return true
	end

	return false
end

function Vehicle:getIsActiveForInput(ignoreSelection, activeForAI)
	if not self.allowsInput then
		return false
	end

	if not g_currentMission.isRunning then
		return false
	end

	if (activeForAI == nil or not activeForAI) and self:getIsAIActive() then
		return false
	end

	if not ignoreSelection or ignoreSelection == nil then
		local rootVehicle = self:getRootVehicle()

		if rootVehicle ~= nil then
			local selectedObject = rootVehicle:getSelectedVehicle()

			if self ~= selectedObject then
				return false
			end
		else
			return false
		end
	end

	local rootAttacherVehicle = self:getRootVehicle()

	if rootAttacherVehicle ~= self then
		if not rootAttacherVehicle:getIsActiveForInput(true, activeForAI) then
			return false
		end
	elseif self.getIsEntered == nil and self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil then
		return false
	end

	return true
end

function Vehicle:getIsActiveForSound()
	print("Warning: Vehicle:getIsActiveForSound() is deprecated")

	return false
end

function Vehicle:getIsLowered(defaultIsLowered)
	return false
end

function Vehicle:getTailwaterDepth()
	local tailwaterDepth = 0

	for _, component in pairs(self.components) do
		local _, yt, _ = getWorldTranslation(component.node)
		tailwaterDepth = math.max(0, g_currentMission.waterY - yt)
	end

	return tailwaterDepth
end

function Vehicle:setBroken()
	if self.isServer and not self.isBroken then
		g_server:broadcastEvent(VehicleBrokenEvent:new(self), nil, , self)
	end

	self.isBroken = true

	SpecializationUtil.raiseEvent(self, "onSetBroken")
end

function Vehicle:getVehicleDamage()
	return 0
end

function Vehicle:getRepairPrice(atSellingPoint)
	return 0
end

function Vehicle:requestActionEventUpdate()
	local vehicle = self:getRootVehicle()

	if vehicle == self then
		self.actionEventUpdateRequested = true
	else
		vehicle:requestActionEventUpdate()
	end

	vehicle:removeActionEvents()
end

function Vehicle:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function Vehicle:updateActionEvents()
	local rootVehicle = self:getRootVehicle()

	rootVehicle:registerActionEvents()
end

function Vehicle:registerActionEvents(excludedVehicle)
	if not g_gui:getIsGuiVisible() and not g_currentMission.isPlayerFrozen and excludedVehicle ~= self then
		self.actionEventUpdateRequested = false
		local isActiveForInput = self:getIsActiveForInput()
		local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)

		if isActiveForInput then
			g_inputBinding:resetActiveActionBindings()
		end

		g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
		SpecializationUtil.raiseEvent(self, "onRegisterActionEvents", isActiveForInput, isActiveForInputIgnoreSelection)
		self:clearActionEventsTable(self.actionEvents)

		if self:getCanToggleSelectable() then
			local numSelectableObjects = 0

			for _, object in ipairs(self.selectableObjects) do
				numSelectableObjects = numSelectableObjects + 1 + #object.subSelections
			end

			if numSelectableObjects > 1 then
				local _, actionEventId = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT, self, Vehicle.actionEventToggleSelection, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			end
		end

		if self:getIsActiveForInput(true) and self == self:getRootVehicle() then
			self.actionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
		end

		g_inputBinding:endActionEventsModification()
	end
end

function Vehicle:clearActionEventsTable(actionEventsTable)
	if actionEventsTable ~= nil then
		for actionEventName, actionEvent in pairs(actionEventsTable) do
			g_inputBinding:removeActionEvent(actionEvent.actionEventId)

			actionEventsTable[actionEventName] = nil
		end
	end
end

function Vehicle:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true)

	if state then
		actionEventsTable[inputAction] = {
			actionEventId = actionEventId
		}
		local event = g_inputBinding.events[actionEventId]

		if event ~= nil then
			event.parentEventsTable = actionEventsTable
		end

		if customIconName and customIconName ~= "" then
			g_inputBinding:setActionEventIcon(actionEventId, customIconName)
		end
	end

	if otherEvents ~= nil and (ignoreCollisions == nil or not ignoreCollisions) then
		if self:getIsSelected() then
			local clearedVehicleEvent = false

			for _, otherEvent in ipairs(otherEvents) do
				if otherEvent.parentEventsTable ~= nil then
					g_inputBinding:removeActionEvent(otherEvent.id)

					otherEvent.parentEventsTable[otherEvent.id] = nil
					clearedVehicleEvent = true
				end
			end

			if clearedVehicleEvent then
				return self:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
			end
		else
			g_inputBinding:removeActionEvent(actionEventId)

			for _, otherEvent in ipairs(otherEvents) do
				if otherEvent.targetObject.getIsSelected ~= nil and not otherEvent.targetObject:getIsSelected() and otherEvent.parentEventsTable ~= nil then
					g_inputBinding:removeActionEvent(otherEvent.id)

					otherEvent.parentEventsTable[otherEvent.id] = nil
				end
			end
		end
	end

	return state, actionEventId
end

function Vehicle:removeActionEvent(actionEventsTable, inputAction)
	if actionEventsTable[inputAction] ~= nil then
		g_inputBinding:removeActionEvent(actionEventsTable[inputAction].actionEventId)

		actionEventsTable[inputAction] = nil
	end
end

function Vehicle:updateSelectableObjects()
	self.selectableObjects = {}

	if self == self:getRootVehicle() then
		self:registerSelectableObjects(self.selectableObjects)
	end
end

function Vehicle:registerSelectableObjects(selectableObjects)
	if self:getCanBeSelected() and not self:getBlockSelection() then
		table.insert(selectableObjects, self.selectionObject)

		self.selectionObject.index = #selectableObjects
	end
end

function Vehicle:addSubselection(subSelection)
	table.insert(self.selectionObject.subSelections, subSelection)

	return #self.selectionObject.subSelections
end

function Vehicle:getCanBeSelected()
	return VehicleDebug.state ~= 0
end

function Vehicle:getBlockSelection()
	return false
end

function Vehicle:getCanToggleSelectable()
	return false
end

function Vehicle:getRootVehicle()
	return self
end

function Vehicle:getChildVehicles()
	return self.childVehicles
end

function Vehicle:addChildVehicles(vehicles)
	table.insert(vehicles, self)
end

function Vehicle:updateChildVehicles(secondCall)
	local rootVehicle = self:getRootVehicle()

	if rootVehicle ~= self and not secondCall then
		rootVehicle:updateChildVehicles()

		local allVehicles = rootVehicle:getChildVehicles()

		for i = 1, #allVehicles do
			if allVehicles[i] ~= rootVehicle then
				allVehicles[i]:updateChildVehicles(true)
			end
		end

		return
	end

	for i = #self.childVehicles, 1, -1 do
		self.childVehicles[i] = nil
	end

	self:addChildVehicles(self.childVehicles)
end

function Vehicle:unselectVehicle()
	self.selectionObject.isSelected = false

	SpecializationUtil.raiseEvent(self, "onUnselect")
	self:requestActionEventUpdate()
end

function Vehicle:selectVehicle(subSelectionIndex, ignoreActionEventUpdate)
	self.selectionObject.isSelected = true

	SpecializationUtil.raiseEvent(self, "onSelect", subSelectionIndex)

	if ignoreActionEventUpdate == nil or not ignoreActionEventUpdate then
		self:requestActionEventUpdate()
	end
end

function Vehicle:setSelectedVehicle(vehicle, subSelectionIndex, ignoreActionEventUpdate)
	local object = nil

	if vehicle == nil or not vehicle:getCanBeSelected() or self:getBlockSelection() then
		vehicle = nil

		for _, o in ipairs(self.selectableObjects) do
			if o.vehicle:getCanBeSelected() and not o.vehicle:getBlockSelection() then
				vehicle = o.vehicle

				break
			end
		end
	end

	if vehicle ~= nil then
		object = vehicle.selectionObject
	end

	return self:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
end

function Vehicle:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
	local currentSelection = self.currentSelection

	if object == nil then
		object = self:getSelectedObject()
	end

	local found = false

	for _, o in ipairs(self.selectableObjects) do
		if o == object then
			found = true
		end
	end

	if found then
		for _, o in ipairs(self.selectableObjects) do
			if o ~= object and o.vehicle:getIsSelected() then
				o.vehicle:unselectVehicle()
			end
		end

		if object ~= currentSelection.object or subSelectionIndex ~= currentSelection.subIndex then
			currentSelection.object = object
			currentSelection.index = object.index

			if subSelectionIndex ~= nil then
				currentSelection.subIndex = subSelectionIndex
			end

			if currentSelection.subIndex > #object.subSelections then
				currentSelection.subIndex = 1
			end

			currentSelection.object.vehicle:selectVehicle(currentSelection.subIndex, ignoreActionEventUpdate)

			return true
		end
	else
		object = self:getSelectedObject()
		found = false

		for _, o in ipairs(self.selectableObjects) do
			if o == object then
				found = true
			end
		end

		if not found then
			currentSelection.object = nil
			currentSelection.index = 1
			currentSelection.subIndex = 1
		end
	end

	return false
end

function Vehicle:getIsSelected()
	return self.selectionObject.isSelected
end

function Vehicle:getSelectedObject()
	local rootVehicle = self:getRootVehicle()

	if rootVehicle == self then
		return self.currentSelection.object
	end

	return rootVehicle:getSelectedObject()
end

function Vehicle:getSelectedVehicle()
	local selectedObject = self:getSelectedObject()

	if selectedObject ~= nil then
		return selectedObject.vehicle
	end

	return nil
end

function Vehicle:hasInputConflictWithSelection(inputs)
	printCallstack()
	g_logManager:xmlWarning(self.configFileName, "Vehicle:hasInputConflictWithSelection() is deprecated!")

	return false
end

function Vehicle:setMassDirty()
	self.isMassDirty = true
end

function Vehicle:updateMass()
	self.serverMass = 0

	for _, component in ipairs(self.components) do
		if component.defaultMass == nil then
			if component.isDynamic then
				component.defaultMass = getMass(component.node)
			end

			component.mass = component.defaultMass
		end

		local mass = self:getAdditionalComponentMass(component)
		component.mass = component.defaultMass + mass

		if self.isServer and component.isDynamic and math.abs(component.lastMass - component.mass) > 0.02 then
			setMass(component.node, component.mass)

			component.lastMass = component.mass
		end

		self.serverMass = self.serverMass + component.mass
	end
end

function Vehicle:getAdditionalComponentMass(component)
	return 0
end

function Vehicle:getTotalMass(onlyGivenVehicle)
	if self.isServer then
		local mass = 0

		for _, component in ipairs(self.components) do
			mass = mass + component.mass
		end

		return mass
	end

	return 0
end

function Vehicle:getFillLevelInformation(fillLevelInformations)
end

function Vehicle:activate()
	SpecializationUtil.raiseEvent(self, "onActivate")
end

function Vehicle:deactivate()
	SpecializationUtil.raiseEvent(self, "onDeactivate")
end

function Vehicle:setComponentJointFrame(jointDesc, anchorActor)
	if anchorActor == 0 then
		local localPoses = jointDesc.jointLocalPoses[1]
		localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
		localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
	else
		local localPoses = jointDesc.jointLocalPoses[2]
		localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
		localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
	end

	local jointNode = jointDesc.jointNode

	if anchorActor == 1 then
		jointNode = jointDesc.jointNodeActor1
	end

	if jointDesc.jointIndex ~= 0 then
		setJointFrame(jointDesc.jointIndex, anchorActor, jointNode)
	end
end

function Vehicle:setComponentJointRotLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.rotLimit[axis] = maxLimit
		componentJoint.rotMinLimit[axis] = minLimit

		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointRotationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
			else
				setJointRotationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
			end
		end
	end
end

function Vehicle:setComponentJointTransLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.transLimit[axis] = maxLimit
		componentJoint.transMinLimit[axis] = minLimit

		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointTranslationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
			else
				setJointTranslationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
			end
		end
	end
end

function Vehicle:loadComponentFromXML(component, xmlFile, key, rootPosition, i)
	if not self.isServer and getRigidBodyType(component.node) == "Dynamic" then
		setRigidBodyType(component.node, "Kinematic")
	end

	link(getRootNode(), component.node)

	if i == 1 then
		rootPosition[1], rootPosition[2], rootPosition[3] = getTranslation(component.node)

		if rootPosition[2] ~= 0 then
			g_logManager:xmlWarning(self.configFileName, "Y-Translation of component 1 (node 0>) has to be 0. Current value is: %.5f", rootPosition[2])
		end
	end

	if getRigidBodyType(component.node) == "Static" then
		component.isStatic = true
	elseif getRigidBodyType(component.node) == "Kinematic" then
		component.isKinematic = true
	elseif getRigidBodyType(component.node) == "Dynamic" then
		component.isDynamic = true
	end

	translate(component.node, -rootPosition[1], -rootPosition[2], -rootPosition[3])

	local x, y, z = getTranslation(component.node)
	local rx, ry, rz = getRotation(component.node)
	component.originalTranslation = {
		x,
		y,
		z
	}
	component.originalRotation = {
		rx,
		ry,
		rz
	}
	component.sentTranslation = {
		x,
		y,
		z
	}
	component.sentRotation = {
		rx,
		ry,
		rz
	}
	component.defaultMass = nil
	component.mass = nil
	local mass = getXMLFloat(xmlFile, key .. "#mass")

	if mass ~= nil then
		if mass < 10 then
			g_logManager:xmlDevWarning(self.configFileName, "Mass is lower than 10kg for '%s'. Mass unit is kilogramms. Is this correct?", key)
		end

		if component.isDynamic then
			setMass(component.node, mass / 1000)
		end

		component.defaultMass = mass / 1000
		component.mass = component.defaultMass
		component.lastMass = component.mass
	else
		g_logManager:xmlWarning(self.configFileName, "Missing 'mass' for '%s'. Using default mass 500kg instead!", key)

		component.defaultMass = 0.5
		component.mass = 0.5
		component.lastMass = component.mass
	end

	local comStr = getXMLString(xmlFile, key .. "#centerOfMass")

	if comStr ~= nil then
		local com = StringUtil.getVectorNFromString(comStr, 3)

		if com ~= nil then
			setCenterOfMass(component.node, com[1], com[2], com[3])
		else
			g_logManager:xmlWarning(self.configFileName, "Invalid center of mass given for '%s'. Ignoring this definition", key)
		end
	end

	local count = getXMLInt(xmlFile, key .. "#solverIterationCount")

	if count ~= nil then
		setSolverIterationCount(component.node, count)

		component.solverIterationCount = count
	end

	component.motorized = getXMLBool(xmlFile, key .. "#motorized")
	self.vehicleNodes[component.node] = {
		component = component
	}
	local clipDistance = getClipDistance(component.node)

	if clipDistance >= 1000000 and getVisibility(component.node) then
		local defaultClipdistance = 300

		g_logManager:xmlWarning(self.configFileName, "No clipdistance is set to component node '%s' (%s>). Set default clipdistance '%d'", getName(component.node), i - 1, defaultClipdistance)
		setClipDistance(component.node, defaultClipdistance)
	end

	component.collideWithAttachables = Utils.getNoNil(getXMLBool(xmlFile, key .. "#collideWithAttachables"), false)

	if getRigidBodyType(component.node) ~= "NoRigidBody" then
		if getLinearDamping(component.node) > 0.01 then
			g_logManager:xmlDevWarning(self.configFileName, "Non-zero linear damping (%.4f) for component node '%s' (%s>). Is this correct?", getLinearDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) > 0.05 then
			g_logManager:xmlDevWarning(self.configFileName, "Large angular damping (%.4f) for component node '%s' (%s>). Is this correct?", getAngularDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) < 0.0001 then
			g_logManager:xmlDevWarning(self.configFileName, "Zero damping for component node '%s' (%s>). Is this correct?", getName(component.node), i - 1)
		end
	end

	local name = getName(component.node)

	if not StringUtil.endsWith(name, "component" .. i) then
		g_logManager:xmlDevWarning(self.configFileName, "Name of component '%d' ('%s') does not correpond with the component naming convention! (vehicleName_componentName_component%d)", i, name, i)
	end

	return true
end

function Vehicle:loadComponentJointFromXML(jointDesc, xmlFile, key, componentJointI, jointNode, index1, index2)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#indexActor1", key .. "#nodeActor1")

	jointDesc.componentIndices = {
		index1,
		index2
	}
	jointDesc.jointNode = jointNode
	jointDesc.jointNodeActor1 = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#nodeActor1"), self.i3dMappings), jointNode)

	if self.isServer then
		if self.components[index1] == nil or self.components[index2] == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid component indices (component1: %d, component2: %d) for component joint %d. Indices start with 1!", index1, index2, componentJointI)

			return false
		end

		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimit"))
		local rotLimits = {
			math.rad(Utils.getNoNil(x, 0)),
			math.rad(Utils.getNoNil(y, 0)),
			math.rad(Utils.getNoNil(z, 0))
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimit"))
		local transLimits = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		jointDesc.rotLimit = rotLimits
		jointDesc.transLimit = transLimits
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotMinLimit"))
		local rotMinLimits = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transMinLimit"))
		local transMinLimits = {
			x,
			y,
			z
		}

		for i = 1, 3 do
			if rotMinLimits[i] == nil then
				if rotLimits[i] >= 0 then
					rotMinLimits[i] = -rotLimits[i]
				else
					rotMinLimits[i] = rotLimits[i] + 1
				end
			end

			if transMinLimits[i] == nil then
				if transLimits[i] >= 0 then
					transMinLimits[i] = -transLimits[i]
				else
					transMinLimits[i] = transLimits[i] + 1
				end
			end
		end

		jointDesc.jointLocalPoses = {}
		local trans = {
			localToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0)
		}
		local rot = {
			localRotationToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0)
		}
		jointDesc.jointLocalPoses[1] = {
			trans = trans,
			rot = rot
		}
		local trans = {
			localToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0)
		}
		local rot = {
			localRotationToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0)
		}
		jointDesc.jointLocalPoses[2] = {
			trans = trans,
			rot = rot
		}
		jointDesc.rotMinLimit = rotMinLimits
		jointDesc.transMinLimit = transMinLimits
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitSpring"))
		local rotLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitDamping"))
		local rotLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		jointDesc.rotLimitSpring = rotLimitSpring
		jointDesc.rotLimitDamping = rotLimitDamping
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimitForceLimit"))
		local rotLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitForceLimit"))
		local transLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		jointDesc.rotLimitForceLimit = rotLimitForceLimit
		jointDesc.transLimitForceLimit = transLimitForceLimit
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitSpring"))
		local transLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transLimitDamping"))
		local transLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		jointDesc.transLimitSpring = transLimitSpring
		jointDesc.transLimitDamping = transLimitDamping
		jointDesc.zRotationXOffset = 0
		local zRotationNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#zRotationNode"), self.i3dMappings)

		if zRotationNode ~= nil then
			jointDesc.zRotationXOffset, _, _ = localToLocal(zRotationNode, jointNode, 0, 0, 0)
		end

		jointDesc.isBreakable = Utils.getNoNil(getXMLBool(xmlFile, key .. "#breakable"), false)

		if jointDesc.isBreakable then
			jointDesc.breakForce = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#breakForce"), 10)
			jointDesc.breakTorque = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#breakTorque"), 10)
		end

		jointDesc.enableCollision = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enableCollision"), false)
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#maxRotDriveForce"))
		local maxRotDriveForce = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotDriveVelocity"))
		local rotDriveVelocity = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotDriveRotation"))
		local rotDriveRotation = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotDriveSpring"))
		local rotDriveSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotDriveDamping"))
		local rotDriveDamping = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		jointDesc.rotDriveVelocity = rotDriveVelocity
		jointDesc.rotDriveRotation = rotDriveRotation
		jointDesc.rotDriveSpring = rotDriveSpring
		jointDesc.rotDriveDamping = rotDriveDamping
		jointDesc.maxRotDriveForce = maxRotDriveForce
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transDriveVelocity"))
		local transDriveVelocity = {
			x,
			y,
			z
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transDrivePosition"))
		local transDrivePosition = {
			x,
			y,
			z
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transDriveSpring"))
		local transDriveSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#transDriveDamping"))
		local transDriveDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#maxTransDriveForce"))
		local maxTransDriveForce = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		jointDesc.transDriveVelocity = transDriveVelocity
		jointDesc.transDrivePosition = transDrivePosition
		jointDesc.transDriveSpring = transDriveSpring
		jointDesc.transDriveDamping = transDriveDamping
		jointDesc.maxTransDriveForce = maxTransDriveForce
		jointDesc.jointIndex = 0
	end

	return true
end

function Vehicle:createComponentJoint(component1, component2, jointDesc)
	if component1 == nil or component2 == nil or jointDesc == nil then
		g_logManager:xmlWarning(self.configFileName, "Could not create component joint. No component1, component2 or jointDesc given!")

		return false
	end

	local constr = JointConstructor:new()

	constr:setActors(component1.node, component2.node)

	local localPoses1 = jointDesc.jointLocalPoses[1]
	local localPoses2 = jointDesc.jointLocalPoses[2]

	constr:setJointLocalPositions(localPoses1.trans[1], localPoses1.trans[2], localPoses1.trans[3], localPoses2.trans[1], localPoses2.trans[2], localPoses2.trans[3])
	constr:setJointLocalRotations(localPoses1.rot[1], localPoses1.rot[2], localPoses1.rot[3], localPoses2.rot[1], localPoses2.rot[2], localPoses2.rot[3])
	constr:setRotationLimitSpring(jointDesc.rotLimitSpring[1], jointDesc.rotLimitDamping[1], jointDesc.rotLimitSpring[2], jointDesc.rotLimitDamping[2], jointDesc.rotLimitSpring[3], jointDesc.rotLimitDamping[3])
	constr:setTranslationLimitSpring(jointDesc.transLimitSpring[1], jointDesc.transLimitDamping[1], jointDesc.transLimitSpring[2], jointDesc.transLimitDamping[2], jointDesc.transLimitSpring[3], jointDesc.transLimitDamping[3])
	constr:setZRotationXOffset(jointDesc.zRotationXOffset)

	for i = 1, 3 do
		if jointDesc.rotMinLimit[i] <= jointDesc.rotLimit[i] then
			constr:setRotationLimit(i - 1, jointDesc.rotMinLimit[i], jointDesc.rotLimit[i])
		end

		if jointDesc.transMinLimit[i] <= jointDesc.transLimit[i] then
			constr:setTranslationLimit(i - 1, true, jointDesc.transMinLimit[i], jointDesc.transLimit[i])
		else
			constr:setTranslationLimit(i - 1, false, 0, 0)
		end
	end

	constr:setRotationLimitForceLimit(jointDesc.rotLimitForceLimit[1], jointDesc.rotLimitForceLimit[2], jointDesc.rotLimitForceLimit[3])
	constr:setTranslationLimitForceLimit(jointDesc.transLimitForceLimit[1], jointDesc.transLimitForceLimit[2], jointDesc.transLimitForceLimit[3])

	if jointDesc.isBreakable then
		constr:setBreakable(jointDesc.breakForce, jointDesc.breakTorque)
	end

	constr:setEnableCollision(jointDesc.enableCollision)

	for i = 1, 3 do
		if jointDesc.maxRotDriveForce[i] > 0.0001 and (jointDesc.rotDriveVelocity[i] ~= nil or jointDesc.rotDriveRotation[i] ~= nil) then
			local pos = Utils.getNoNil(jointDesc.rotDriveRotation[i], 0)
			local vel = Utils.getNoNil(jointDesc.rotDriveVelocity[i], 0)

			constr:setAngularDrive(i - 1, jointDesc.rotDriveRotation[i] ~= nil, jointDesc.rotDriveVelocity[i] ~= nil, jointDesc.rotDriveSpring[i], jointDesc.rotDriveDamping[i], jointDesc.maxRotDriveForce[i], pos, vel)
		end

		if jointDesc.maxTransDriveForce[i] > 0.0001 and (jointDesc.transDriveVelocity[i] ~= nil or jointDesc.transDrivePosition[i] ~= nil) then
			local pos = Utils.getNoNil(jointDesc.transDrivePosition[i], 0)
			local vel = Utils.getNoNil(jointDesc.transDriveVelocity[i], 0)

			constr:setLinearDrive(i - 1, jointDesc.transDrivePosition[i] ~= nil, jointDesc.transDriveVelocity[i] ~= nil, jointDesc.transDriveSpring[i], jointDesc.transDriveDamping[i], jointDesc.maxTransDriveForce[i], pos, vel)
		end
	end

	jointDesc.jointIndex = constr:finalize()

	return true
end

function Vehicle.prefixSchemaOverlayName(baseName, prefix)
	local name = baseName

	if name ~= "" and not VehicleSchemaOverlayData.SCHEMA_OVERLAY[baseName] then
		name = prefix .. baseName
	end

	return name
end

function Vehicle:loadSchemaOverlay(xmlFile)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#height")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#invisibleBorderRight", "vehicle.base.schemaOverlay#invisibleBorderRight")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#invisibleBorderLeft", "vehicle.base.schemaOverlay#invisibleBorderLeft")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#attacherJointPosition", "vehicle.base.schemaOverlay#attacherJointPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#basePosition", "vehicle.base.schemaOverlay#basePosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#fileSelected")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#fileTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.schemaOverlay#fileSelectedTurnedOn")

	if hasXMLProperty(xmlFile, "vehicle.base.schemaOverlay") then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, "vehicle.schemaOverlay.attacherJoint", "vehicle.attacherJoints.attacherJoint.schema")

		local x, y = StringUtil.getVectorFromString(getXMLString(xmlFile, "vehicle.base.schemaOverlay#attacherJointPosition"))
		local baseX, baseY = StringUtil.getVectorFromString(getXMLString(xmlFile, "vehicle.base.schemaOverlay#basePosition"))

		if baseX == nil then
			baseX = x
		end

		if baseY == nil then
			baseY = y
		end

		local schemaNameDefault = getXMLString(xmlFile, "vehicle.base.schemaOverlay.default#name") or ""
		local schemaNameTurnedOn = getXMLString(xmlFile, "vehicle.base.schemaOverlay.turnedOn#name") or ""
		local schemaNameSelected = getXMLString(xmlFile, "vehicle.base.schemaOverlay.selected#name") or ""
		local schemaNameSelectedTurnedOn = getXMLString(xmlFile, "vehicle.base.schemaOverlay.turnedOnSelected#name") or ""
		local modPrefix = self.customEnvironment or ""
		schemaNameDefault = Vehicle.prefixSchemaOverlayName(schemaNameDefault, modPrefix)
		schemaNameTurnedOn = Vehicle.prefixSchemaOverlayName(schemaNameTurnedOn, modPrefix)
		schemaNameSelected = Vehicle.prefixSchemaOverlayName(schemaNameSelected, modPrefix)
		schemaNameSelectedTurnedOn = Vehicle.prefixSchemaOverlayName(schemaNameSelectedTurnedOn, modPrefix)
		self.schemaOverlay = VehicleSchemaOverlayData.new(baseX, baseY, schemaNameDefault, schemaNameTurnedOn, schemaNameSelected, schemaNameSelectedTurnedOn, getXMLFloat(xmlFile, "vehicle.base.schemaOverlay#invisibleBorderRight"), getXMLFloat(xmlFile, "vehicle.base.schemaOverlay#invisibleBorderLeft"))
	end
end

function Vehicle:getAdditionalSchemaText()
	return nil
end

function Vehicle:dayChanged()
	self.age = self.age + 1
end

function Vehicle:raiseStateChange(state, data)
	SpecializationUtil.raiseEvent(self, "onStateChange", state, data)
end

function Vehicle:doCheckSpeedLimit()
	return false
end

function Vehicle:getWorkLoad()
	return 0, 0
end

function Vehicle:interact()
end

function Vehicle:getInteractionHelp()
	return ""
end

function Vehicle:getDistanceToNode(node)
	self.interactionFlag = Vehicle.INTERACTION_FLAG_NONE

	return math.huge
end

function Vehicle:getIsAIActive()
	if self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			return attacherVehicle:getIsAIActive()
		end
	end

	return false
end

function Vehicle:addVehicleToAIImplementList(list)
end

function Vehicle:setOperatingTime(operatingTime, isLoading)
	if not isLoading and self.propertyState == Vehicle.PROPERTY_STATE_LEASED and g_currentMission ~= nil and g_currentMission.economyManager ~= nil and math.floor(self.operatingTime / 3600000) < math.floor(operatingTime / 3600000) then
		g_currentMission.economyManager:vehicleOperatingHourChanged(self)
	end

	self.operatingTime = math.max(Utils.getNoNil(operatingTime, 0), 0)
end

function Vehicle:getOperatingTime()
	return self.operatingTime
end

function Vehicle:doCollisionMaskCheck(targetCollisionMask, path, node, str)
	local ignoreCheck = false

	if path ~= nil then
		ignoreCheck = Utils.getNoNil(getXMLBool(self.xmlFile, path), false)
	end

	if not ignoreCheck then
		local hasMask = false

		if node == nil then
			for _, component in ipairs(self.components) do
				hasMask = hasMask or bitAND(getCollisionMask(component.node), targetCollisionMask) == targetCollisionMask
			end
		else
			hasMask = hasMask or bitAND(getCollisionMask(node), targetCollisionMask) == targetCollisionMask
		end

		if not hasMask then
			g_logManager:xmlWarning(self.configFileName, "%s has wrong collision mask! Following bit(s) need to be set '%s' or use '%s'", str or self.typeName, MathUtil.numberToSetBitsStr(targetCollisionMask), path)

			return false
		end
	end

	return true
end

function Vehicle:getIsReadyForAutomatedTrainTravel()
	return true
end

function Vehicle:getSpeedLimit(onlyIfWorking)
	local limit = math.huge
	local doCheckSpeedLimit = self:doCheckSpeedLimit()

	if onlyIfWorking == nil or onlyIfWorking and doCheckSpeedLimit then
		limit = self.speedLimit
		local damage = self:getVehicleDamage()

		if damage > 0 then
			limit = limit * (1 - damage * Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION)
		end
	end

	local attachedImplements = nil

	if self.getAttachedImplements ~= nil then
		attachedImplements = self:getAttachedImplements()
	end

	if attachedImplements ~= nil then
		for _, implement in pairs(attachedImplements) do
			if implement.object ~= nil then
				local speed, implementDoCheckSpeedLimit = implement.object:getSpeedLimit(onlyIfWorking)

				if onlyIfWorking == nil or onlyIfWorking and implementDoCheckSpeedLimit then
					limit = math.min(limit, speed)
				end

				doCheckSpeedLimit = doCheckSpeedLimit or implementDoCheckSpeedLimit
			end
		end
	end

	return limit, doCheckSpeedLimit
end

function Vehicle:onVehicleWakeUpCallback(id)
	self:raiseActive()
end

function Vehicle:getCanByMounted()
	return entityExists(self.components[1].node)
end

function Vehicle:getDailyUpkeep()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = 0.3 * math.min(self.age / storeItem.lifetime, 1)
		local operatingTime = self.operatingTime / 3600000
		local operatingTimeMultiplier = 0.7 * math.min(operatingTime / (storeItem.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)
		multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (ageMultiplier + operatingTimeMultiplier)
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, self.configurations) * multiplier
end

function Vehicle:getName()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	return storeItem.name
end

function Vehicle:getFullName()
	local name = self:getName()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)

		if brand ~= nil then
			name = brand.title .. " " .. name
		end
	end

	if self:getIsAIActive() then
		name = name .. " (" .. g_i18n:getText("ui_helper") .. " " .. self:getCurrentHelper().name .. ")"
	end

	return name
end

function Vehicle:getCanBePickedUp(byPlayer)
	return self.supportsPickUp and self:getTotalMass() <= Player.MAX_PICKABLE_OBJECT_MASS and g_currentMission.accessHandler:canPlayerAccess(self, byPlayer)
end

function Vehicle:getCanBeReset()
	return self.canBeReset
end

function Vehicle:getShowOnMap()
end

function Vehicle:getIsInUse(connection)
	return false
end

function Vehicle:getPropertyState()
	return self.propertyState
end

function Vehicle:getAreControlledActionsAvailable()
	if self:getIsAIActive() then
		return false
	end

	if self.actionController ~= nil then
		return self.actionController:getAreControlledActionsAvailable()
	end

	return false
end

function Vehicle:getAreControlledActionsAllowed()
	return not self:getIsAIActive(), ""
end

function Vehicle:playControlledActions()
	if self.actionController ~= nil then
		self.actionController:playControlledActions()
	end
end

function Vehicle:getActionControllerDirection()
	if self.actionController ~= nil then
		return self.actionController:getActionControllerDirection()
	end

	return 1
end

function Vehicle:setMapHotspot(hotspot)
	self.mapHotspot = hotspot
end

function Vehicle:getMapHotspot()
	return self.mapHotspot
end

function Vehicle:actionEventToggleSelection(actionName, inputValue, callbackState, isAnalog)
	local currentSelection = self.currentSelection
	local currentObject = currentSelection.object
	local currentObjectIndex = currentSelection.index
	local currentSubObjectIndex = currentSelection.subIndex
	local numSubSelections = 0

	if currentObject ~= nil then
		numSubSelections = #currentObject.subSelections
	end

	local newSelectedSubObjectIndex = currentSubObjectIndex + 1
	local newSelectedObjectIndex = currentObjectIndex
	local newSelectedObject = currentObject

	if numSubSelections < newSelectedSubObjectIndex then
		newSelectedSubObjectIndex = 1
		newSelectedObjectIndex = currentObjectIndex + 1

		if newSelectedObjectIndex > #self.selectableObjects then
			newSelectedObjectIndex = 1
		end

		newSelectedObject = self.selectableObjects[newSelectedObjectIndex]
	end

	if currentObject ~= newSelectedObject or currentObjectIndex ~= newSelectedObjectIndex or currentSubObjectIndex ~= newSelectedSubObjectIndex then
		self:setSelectedObject(newSelectedObject, newSelectedSubObjectIndex)
	end
end

function Vehicle.getReloadXML(vehicle)
	local vehicleXMLFile = createXMLFile("vehicleXMLFile", "", "vehicles")

	if vehicleXMLFile ~= nil then
		local key = string.format("vehicles.vehicle(%d)", 0)

		setXMLInt(vehicleXMLFile, key .. "#id", 1)
		setXMLString(vehicleXMLFile, key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
		vehicle:saveToXMLFile(vehicleXMLFile, key, {})

		return vehicleXMLFile
	end

	return nil
end

function Vehicle.getSpecValueAge(storeItem, realItem)
	if realItem ~= nil and realItem.age ~= nil then
		return string.format(g_i18n:getText("shop_age"), realItem.age)
	end

	return nil
end

function Vehicle.getSpecValueDailyUpkeep(storeItem, realItem)
	local dailyUpkeep = storeItem.dailyUpkeep

	if realItem ~= nil and realItem.getDailyUpkeep ~= nil then
		dailyUpkeep = realItem:getDailyUpkeep()
	end

	if dailyUpkeep == nil or dailyUpkeep == 0 then
		return nil
	end

	return string.format(g_i18n:getText("shop_maintenanceValue"), g_i18n:formatMoney(dailyUpkeep, 2))
end

function Vehicle.getSpecValueOperatingTime(storeItem, realItem)
	if realItem ~= nil and realItem.operatingTime ~= nil then
		local minutes = realItem.operatingTime / 60000
		local hours = math.floor(minutes / 60)
		minutes = math.floor((minutes - hours * 60) / 6)

		return string.format(g_i18n:getText("shop_operatingTime"), hours, minutes)
	end

	return nil
end

function Vehicle.loadSpecValueWorkingWidth(xmlFile, customEnvironment)
	return getXMLString(xmlFile, "vehicle.storeData.specs.workingWidth")
end

function Vehicle.getSpecValueWorkingWidth(storeItem, realItem)
	if storeItem.specs.workingWidth ~= nil then
		return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(storeItem.specs.workingWidth, 1, true))
	end

	return nil
end

function Vehicle.loadSpecValueSpeedLimit(xmlFile, customEnvironment)
	return getXMLString(xmlFile, "vehicle.base.speedLimit#value")
end

function Vehicle.getSpecValueSpeedLimit(storeItem, realItem)
	if storeItem.specs.speedLimit ~= nil then
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(storeItem.specs.speedLimit)), g_i18n:getSpeedMeasuringUnit())
	end

	return nil
end

function Vehicle.loadSpecValueCombinations(xmlFile, customEnvironment)
	return XMLUtil.getXMLI18NValue(xmlFile, "vehicle.storeData.specs", getXMLString, "combination", nil, customEnvironment, false)
end

function Vehicle.getSpecValueCombinations(storeItem, realItem)
	return storeItem.specs.combination
end

function Vehicle.getSpecValueSlots(storeItem, realItem, isGarage)
	local numOwned = g_currentMission:getNumOfItems(storeItem)
	local valueText = ""

	if isGarage then
		local sellSlotUsage = g_currentMission:getStoreItemSlotUsage(storeItem, numOwned == 1)

		if sellSlotUsage ~= 0 then
			valueText = "+" .. sellSlotUsage
		end
	else
		local buySlotUsage = g_currentMission:getStoreItemSlotUsage(storeItem, numOwned == 0)

		if buySlotUsage ~= 0 then
			valueText = "-" .. buySlotUsage
		end
	end

	if valueText ~= "" then
		return valueText
	else
		return nil
	end
end
