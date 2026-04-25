GameSettings = {}
local GameSettings_mt = Class(GameSettings)
GameSettings.SETTING = {
	VOLUME_VEHICLE = "vehicleVolume",
	RADIO_IS_ACTIVE = "radioIsActive",
	GAMEPAD_ENABLED_SET_BY_USER = "gamepadEnabledSetByUser",
	MONEY_UNIT = "moneyUnit",
	IS_GAMEPAD_ENABLED = "isGamepadEnabled",
	VOLUME_RADIO = "radioVolume",
	SHOW_HELP_MENU = "showHelpMenu",
	PLAYER_HAT_INDEX = "playerHatIndex",
	SHOW_ALL_MODS = "showAllMods",
	SHOW_TRIGGER_MARKER = "showTriggerMarker",
	PLAYER_COLOR_INDEX = "playerColorIndex",
	PLAYER_MODEL_INDEX = "playerModelIndex",
	USE_WORLD_CAMERA = "useWorldCamera",
	USE_ACRE = "useAcre",
	VOLUME_ENVIRONMENT = "environmentVolume",
	PLAYER_JACKET_INDEX = "playerJacketIndex",
	USE_MILES = "useMiles",
	USE_COLORBLIND_MODE = "useColorblindMode",
	INVERT_Y_LOOK = "invertYLook",
	VEHICLE_ARM_SENSITIVITY = "vehicleArmSensitivity",
	EASY_ARM_CONTROL = "easyArmControl",
	HEAD_TRACKING_ENABLED_SET_BY_USER = "headTrackingEnabledSetByUser",
	VOLUME_GUI = "volumeGUI",
	MAX_NUM_MIRRORS = "maxNumMirrors",
	PLAYER_BODY_INDEX = "playerBodyIndex",
	USE_FAHRENHEIT = "useFahrenheit",
	CAMERA_SENSITIVITY = "cameraSensitivity",
	REAL_BEACON_LIGHTS = "realBeaconLights",
	RADIO_VEHICLE_ONLY = "radioVehicleOnly",
	INPUT_HELP_MODE = "inputHelpMode",
	STEERING_BACK_SPEED = "steeringBackSpeed",
	LIGHTS_PROFILE = "lightsProfile",
	FOV_Y = "fovY",
	INGAME_MAP_STATE = "ingameMapState",
	IS_TRAIN_TABBABLE = "isTrainTabbable",
	UI_SCALE = "uiScale",
	INGAME_MAP_FILTER = "ingameMapFilter",
	HORSE_ABANDON_TIMER_DURATION = "horseAbandonTimerDuration",
	MOTOR_STOP_TIMER_DURATION = "motorStopTimerDuration",
	VOLUME_MUSIC = "musicVolume",
	DEFAULT_SERVER_PORT = "defaultServerPort",
	JOYSTICK_VIBRATION_ENABLED = "joystickVibrationEnabled",
	GYROSCOPE_STEERING = "gyroscopeSteering",
	CAMERA_TILTING = "cameraTilting",
	HINTS = "hints",
	IS_HEAD_TRACKING_ENABLED = "isHeadTrackingEnabled",
	STEERING_SENSITIVITY = "steeringSensitivity",
	PLAYER_ACCESSORY_INDEX = "playerAccessoryIndex",
	RESET_CAMERA = "resetCamera",
	NICKNAME = "nickname",
	VOLUME_MASTER = "masterVolume",
	SHOW_HELP_ICONS = "showHelpIcons",
	SHOW_FIELD_INFO = "showFieldInfo",
	MP_LANGUAGE = "mpLanguage",
	PLAYER_HAIR_INDEX = "playerHairIndex",
	IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED = "isSoundPlayerStreamAccessAllowed"
}

function GameSettings:new(customMt, messageCenter)
	if customMt == nil then
		customMt = GameSettings_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.messageCenter = messageCenter
	self.notifyOnChange = false
	self.tutorialsDone = {}
	self.joinGame = {}
	self.createGame = {}
	local maxMirrors = 3

	if GS_IS_CONSOLE_VERSION then
		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
			if getNeoMode() then
				maxMirrors = 5
			else
				maxMirrors = 5
			end
		elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
			maxMirrors = 3
		else
			maxMirrors = 0
		end
	end

	self[GameSettings.SETTING.DEFAULT_SERVER_PORT] = 10823
	self[GameSettings.SETTING.MAX_NUM_MIRRORS] = maxMirrors
	self[GameSettings.SETTING.LIGHTS_PROFILE] = GS_PROFILE_VERY_HIGH
	self[GameSettings.SETTING.REAL_BEACON_LIGHTS] = false
	self[GameSettings.SETTING.MP_LANGUAGE] = getSystemLanguage()
	self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_AUTO
	self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED] = false
	self[GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER] = false
	self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
	self[GameSettings.SETTING.JOYSTICK_VIBRATION_ENABLED] = false
	self[GameSettings.SETTING.GYROSCOPE_STEERING] = g_platformSettingsManager:getSetting("defaultGyroscopeSteering", true)
	self[GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER] = false
	self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = true
	self[GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION] = 30000
	self[GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION] = 30000
	self[GameSettings.SETTING.FOV_Y] = g_fovYDefault
	self[GameSettings.SETTING.UI_SCALE] = 1
	self[GameSettings.SETTING.HINTS] = true
	self[GameSettings.SETTING.CAMERA_TILTING] = g_platformSettingsManager:getSetting("defaultCameraTilt", true)
	self[GameSettings.SETTING.SHOW_ALL_MODS] = false
	self[GameSettings.SETTING.NICKNAME] = ""
	self[GameSettings.SETTING.PLAYER_MODEL_INDEX] = 1
	self[GameSettings.SETTING.PLAYER_BODY_INDEX] = 1
	self[GameSettings.SETTING.PLAYER_COLOR_INDEX] = 2
	self[GameSettings.SETTING.PLAYER_JACKET_INDEX] = 0
	self[GameSettings.SETTING.PLAYER_ACCESSORY_INDEX] = 0
	self[GameSettings.SETTING.PLAYER_HAT_INDEX] = 0
	self[GameSettings.SETTING.PLAYER_HAIR_INDEX] = 1
	self[GameSettings.SETTING.INVERT_Y_LOOK] = false
	self[GameSettings.SETTING.VOLUME_MASTER] = 1
	self[GameSettings.SETTING.VOLUME_MUSIC] = 0.7
	self[GameSettings.SETTING.VOLUME_VEHICLE] = 0.8
	self[GameSettings.SETTING.VOLUME_ENVIRONMENT] = 0.8
	self[GameSettings.SETTING.VOLUME_RADIO] = 0.5
	self[GameSettings.SETTING.VOLUME_GUI] = 0.5
	self[GameSettings.SETTING.RADIO_IS_ACTIVE] = false
	self[GameSettings.SETTING.RADIO_VEHICLE_ONLY] = true
	self[GameSettings.SETTING.SHOW_HELP_ICONS] = true
	self[GameSettings.SETTING.USE_COLORBLIND_MODE] = false
	self[GameSettings.SETTING.EASY_ARM_CONTROL] = true
	self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_EURO

	if GS_IS_MOBILE_VERSION then
		self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_DOLLAR
	end

	self[GameSettings.SETTING.USE_MILES] = false
	self[GameSettings.SETTING.USE_FAHRENHEIT] = false
	self[GameSettings.SETTING.USE_ACRE] = false
	self[GameSettings.SETTING.SHOW_TRIGGER_MARKER] = true
	self[GameSettings.SETTING.SHOW_FIELD_INFO] = true
	self[GameSettings.SETTING.RESET_CAMERA] = false
	self[GameSettings.SETTING.USE_WORLD_CAMERA] = true
	self[GameSettings.SETTING.SHOW_HELP_MENU] = true
	self[GameSettings.SETTING.IS_TRAIN_TABBABLE] = true
	self[GameSettings.SETTING.CAMERA_SENSITIVITY] = 1
	self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY] = 1
	self[GameSettings.SETTING.STEERING_BACK_SPEED] = 5
	self[GameSettings.SETTING.STEERING_SENSITIVITY] = GS_IS_MOBILE_VERSION and 0.8 or 1
	self[GameSettings.SETTING.INGAME_MAP_FILTER] = 0
	self[GameSettings.SETTING.INGAME_MAP_STATE] = IngameMap.STATE_MINIMAP

	if GS_IS_CONSOLE_VERSION then
		self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
		self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = false
		self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_GAMEPAD
	end

	self.printedSettingsChanges = {
		[GameSettings.SETTING.VOLUME_MASTER] = "Setting 'Master Volume': %s",
		[GameSettings.SETTING.VOLUME_MUSIC] = "Setting 'Music Volume': %s",
		[GameSettings.SETTING.VOLUME_VEHICLE] = "Setting 'Vehicle Volume': %s",
		[GameSettings.SETTING.VOLUME_ENVIRONMENT] = "Setting 'Environment Volume': %s",
		[GameSettings.SETTING.VOLUME_RADIO] = "Setting 'Radio Volume': %s",
		[GameSettings.SETTING.VOLUME_GUI] = "Setting 'GUI Volume': %s",
		[GameSettings.SETTING.SHOW_TRIGGER_MARKER] = "Setting 'Show Trigger Marker': %s",
		[GameSettings.SETTING.IS_TRAIN_TABBABLE] = "Setting 'Is Train Tabbable': %s",
		[GameSettings.SETTING.RADIO_IS_ACTIVE] = "Setting 'Radio Active': %s",
		[GameSettings.SETTING.RADIO_VEHICLE_ONLY] = "Setting 'Radio Vehicle Only': %s",
		[GameSettings.SETTING.SHOW_HELP_ICONS] = "Setting 'Show Help Icons': %s",
		[GameSettings.SETTING.USE_COLORBLIND_MODE] = "Setting 'Use Colorblind Mode': %s",
		[GameSettings.SETTING.EASY_ARM_CONTROL] = "Setting 'Easy Arm Control': %s",
		[GameSettings.SETTING.INVERT_Y_LOOK] = "Setting 'Invert Y-Look': %s",
		[GameSettings.SETTING.SHOW_FIELD_INFO] = "Setting 'Show Field-Info': %s"
	}

	return self
end

function GameSettings:getTableValue(name, index)
	if name == nil then
		print("Error: GameSetting table name missing or nil!")

		return false
	end

	if index == nil then
		print("Error: GameSetting table index missing or nil!")

		return false
	end

	return self[name][index]
end

function GameSettings:setTableValue(name, index, value, doSave)
	if name == nil then
		print("Error: GameSetting table name missing or nil!")

		return false
	end

	if index == nil then
		print("Error: GameSetting table index missing or nil!")

		return false
	end

	if value == nil then
		print("Error: GameSetting table value missing or nil for index '" .. index("'!"))

		return false
	end

	if self[name] == nil then
		print("Error: GameSetting table '" .. name .. "' not found!")

		return false
	end

	self[name][index] = value

	if doSave then
		self:saveToXMLFile(g_savegameXML)
	end

	return true
end

function GameSettings:getValue(name)
	if name == nil then
		print("Error: GameSetting name missing or nil!")

		return false
	end

	return self[name]
end

function GameSettings:setValue(name, value, doSave)
	if name == nil then
		print("Error: GameSetting name missing or nil!")

		return false
	end

	if value == nil then
		print("Error: GameSetting value missing or nil for setting '" .. name .. "'!")

		return false
	end

	if self[name] == nil then
		print("Error: GameSetting '" .. name .. "' not found!")

		return false
	end

	self[name] = value

	if self.printedSettingsChanges[name] ~= nil then
		print("  " .. string.format(self.printedSettingsChanges[name], tostring(value)))
	end

	if self.notifyOnChange then
		local messageType = MessageType.SETTING_CHANGED[name]

		self.messageCenter:publish(messageType, value)
	end

	if doSave then
		self:saveToXMLFile(g_savegameXML)
	end

	return true
end

function GameSettings:loadFromXML(xmlFile)
	if xmlFile ~= nil then
		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PC then
			self:setValue(GameSettings.SETTING.DEFAULT_SERVER_PORT, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.defaultMultiplayerPort"), 10823), 0, 65535))

			local preset = GS_PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]

			self:setValue(GameSettings.SETTING.MAX_NUM_MIRRORS, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.maxNumMirrors"), preset.maxNumMirrors), 0, 7))
			self:setValue(GameSettings.SETTING.LIGHTS_PROFILE, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.lightsProfile"), preset.lightsProfile), GS_PROFILE_LOW, GS_PROFILE_VERY_HIGH))
			self:setValue(GameSettings.SETTING.REAL_BEACON_LIGHTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.realBeaconLights"), self[GameSettings.SETTING.REAL_BEACON_LIGHTS]))

			local mpLanguage = getXMLInt(xmlFile, "gameSettings.mpLanguage")

			if mpLanguage ~= nil and mpLanguage >= 0 and mpLanguage <= getNumOfLanguages() - 1 then
				self:setValue(GameSettings.SETTING.MP_LANGUAGE, mpLanguage)
			end

			local inputHelpMode = getXMLInt(xmlFile, "gameSettings.inputHelpMode")

			if inputHelpMode ~= nil then
				if inputHelpMode == GS_INPUT_HELP_MODE_AUTO or inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
					self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, inputHelpMode)

					if not getGamepadEnabled() and inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
						self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, GS_INPUT_HELP_MODE_AUTO)
					end
				else
					print("Warning: Invalid input help mode")
				end
			end

			local isGamepadEnabled = getXMLBool(xmlFile, "gameSettings.isGamepadEnabled")

			if isGamepadEnabled ~= nil then
				self:setValue(GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER, true)
				self:setValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED, isGamepadEnabled)
			end

			local isHeadTrackingEnabled = getXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled")

			if isHeadTrackingEnabled ~= nil then
				self:setValue(GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER, true)
				self:setValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED, isHeadTrackingEnabled)
			end

			self:setValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams"), self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED]))

			local motorStopTimerDuration = getXMLInt(xmlFile, "gameSettings.motorStopTimerDuration")

			if motorStopTimerDuration ~= nil then
				self:setValue(GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION, motorStopTimerDuration * 1000)
			end

			local horseAbandonTimerDuration = getXMLInt(xmlFile, "gameSettings.horseAbandonTimerDuration")

			if horseAbandonTimerDuration ~= nil then
				self:setValue(GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION, horseAbandonTimerDuration * 1000)
			end
		end

		local fovY = getXMLInt(xmlFile, "gameSettings.fovY")

		if fovY ~= nil then
			self:setValue(GameSettings.SETTING.FOV_Y, MathUtil.clamp(math.rad(fovY), g_fovYMin, g_fovYMax))
		end

		local uiScale = getXMLFloat(xmlFile, "gameSettings.uiScale")

		if uiScale ~= nil then
			self:setValue(GameSettings.SETTING.UI_SCALE, MathUtil.clamp(uiScale, 0.5, 1.5))
		end

		local modToggle = getXMLBool(xmlFile, "gameSettings.showAllMods")

		if modToggle ~= nil then
			self:setValue(GameSettings.SETTING.SHOW_ALL_MODS, modToggle)
		end

		if not GS_IS_CONSOLE_VERSION then
			self:setValue(GameSettings.SETTING.NICKNAME, Utils.getNoNil(getXMLString(xmlFile, "gameSettings.player#name"), self[GameSettings.SETTING.NICKNAME]))
		end

		self:setValue(GameSettings.SETTING.PLAYER_MODEL_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#index"), self[GameSettings.SETTING.PLAYER_MODEL_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_BODY_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#bodyIndex"), self[GameSettings.SETTING.PLAYER_BODY_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_COLOR_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#colorIndex"), self[GameSettings.SETTING.PLAYER_COLOR_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_HAIR_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#hairIndex"), self[GameSettings.SETTING.PLAYER_HAIR_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_HAT_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#hatIndex"), self[GameSettings.SETTING.PLAYER_HAT_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_JACKET_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#jacketIndex"), self[GameSettings.SETTING.PLAYER_JACKET_INDEX]))
		self:setValue(GameSettings.SETTING.PLAYER_ACCESSORY_INDEX, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.player#accessoryIndex"), self[GameSettings.SETTING.PLAYER_ACCESSORY_INDEX]))
		self:setTableValueFromXML("joinGame", "password", getXMLString, xmlFile, "gameSettings.joinGame#password")
		self:setTableValueFromXML("joinGame", "hasNoPassword", getXMLBool, xmlFile, "gameSettings.joinGame#hasNoPassword")
		self:setTableValueFromXML("joinGame", "isNotEmpty", getXMLBool, xmlFile, "gameSettings.joinGame#isNotEmpty")
		self:setTableValueFromXML("joinGame", "onlyWithAllModsAvailable", getXMLBool, xmlFile, "gameSettings.joinGame#onlyWithAllModsAvailable")
		self:setTableValueFromXML("joinGame", "serverName", getXMLString, xmlFile, "gameSettings.joinGame#serverName")
		self:setTableValueFromXML("joinGame", "mapId", getXMLString, xmlFile, "gameSettings.joinGame#mapId")
		self:setTableValueFromXML("joinGame", "language", getXMLInt, xmlFile, "gameSettings.joinGame#language")
		self:setTableValueFromXML("joinGame", "capacity", getXMLInt, xmlFile, "gameSettings.joinGame#capacity")
		self:setTableValueFromXML("createGame", "password", getXMLString, xmlFile, "gameSettings.createGame#password")

		if not GS_IS_CONSOLE_VERSION then
			self:setTableValueFromXML("createGame", "serverName", getXMLString, xmlFile, "gameSettings.createGame#name")
		end

		self:setTableValueFromXML("createGame", "port", getXMLInt, xmlFile, "gameSettings.createGame#port")
		self:setTableValueFromXML("createGame", "useUpnp", getXMLBool, xmlFile, "gameSettings.createGame#useUpnp")
		self:setTableValueFromXML("createGame", "autoAccept", getXMLBool, xmlFile, "gameSettings.createGame#autoAccept")
		self:setTableValueFromXML("createGame", "autoSave", getXMLBool, xmlFile, "gameSettings.createGame#autoSave")
		self:setTableValueFromXML("createGame", "allowOnlyFriends", getXMLBool, xmlFile, "gameSettings.createGame#allowOnlyFriends")
		self:setTableValueFromXML("createGame", "capacity", getXMLInt, xmlFile, "gameSettings.createGame#capacity")
		self:setTableValueFromXML("createGame", "bandwidth", getXMLInt, xmlFile, "gameSettings.createGame#bandwidth")
		self:setValue(GameSettings.SETTING.IS_TRAIN_TABBABLE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.isTrainTabbable"), self[GameSettings.SETTING.IS_TRAIN_TABBABLE]))
		self:setValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioVehicleOnly"), self[GameSettings.SETTING.RADIO_VEHICLE_ONLY]))
		self:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioIsActive"), self[GameSettings.SETTING.RADIO_IS_ACTIVE]))
		self:setValue(GameSettings.SETTING.USE_COLORBLIND_MODE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useColorblindMode"), self[GameSettings.SETTING.USE_COLORBLIND_MODE]))
		self:setValue(GameSettings.SETTING.EASY_ARM_CONTROL, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.easyArmControl"), self[GameSettings.SETTING.EASY_ARM_CONTROL]))
		self:setValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showTriggerMarker"), self[GameSettings.SETTING.SHOW_TRIGGER_MARKER]))
		self:setValue(GameSettings.SETTING.SHOW_FIELD_INFO, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showFieldInfo"), self[GameSettings.SETTING.SHOW_FIELD_INFO]))
		self:setValue(GameSettings.SETTING.RESET_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.resetCamera"), self[GameSettings.SETTING.RESET_CAMERA]))
		self:setValue(GameSettings.SETTING.USE_WORLD_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useWorldCamera"), self[GameSettings.SETTING.USE_WORLD_CAMERA]))
		self:setValue(GameSettings.SETTING.INVERT_Y_LOOK, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.invertYLook"), self[GameSettings.SETTING.INVERT_Y_LOOK]))
		self:setValue(GameSettings.SETTING.SHOW_HELP_ICONS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpIcons"), self[GameSettings.SETTING.SHOW_HELP_ICONS]))
		self:setValue(GameSettings.SETTING.SHOW_HELP_MENU, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpMenu"), self[GameSettings.SETTING.SHOW_HELP_MENU]))
		self:setValue(GameSettings.SETTING.VOLUME_RADIO, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.radio"), self[GameSettings.SETTING.VOLUME_RADIO]))
		self:setValue(GameSettings.SETTING.VOLUME_VEHICLE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.vehicle"), self[GameSettings.SETTING.VOLUME_VEHICLE]))
		self:setValue(GameSettings.SETTING.VOLUME_ENVIRONMENT, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.environment"), self[GameSettings.SETTING.VOLUME_ENVIRONMENT]))
		self:setValue(GameSettings.SETTING.VOLUME_GUI, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.gui"), self[GameSettings.SETTING.VOLUME_GUI]))
		self:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
		self:setValue(GameSettings.SETTING.VOLUME_MUSIC, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.music"), self[GameSettings.SETTING.VOLUME_MUSIC]))
		self:setValue(GameSettings.SETTING.CAMERA_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.cameraSensitivity"), self[GameSettings.SETTING.CAMERA_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity"), self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.STEERING_BACK_SPEED, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringBackSpeed"), self[GameSettings.SETTING.STEERING_BACK_SPEED]))
		self:setValue(GameSettings.SETTING.STEERING_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringSensitivity"), self[GameSettings.SETTING.STEERING_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.INGAME_MAP_STATE, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.ingameMapState"), IngameMap.STATE_MINIMAP))
		self:setValue(GameSettings.SETTING.INGAME_MAP_FILTER, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.ingameMapFilter"), self[GameSettings.SETTING.INGAME_MAP_FILTER]))

		if not GS_IS_MOBILE_VERSION then
			self:setValue(GameSettings.SETTING.MONEY_UNIT, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.units.money"), self[GameSettings.SETTING.MONEY_UNIT]))
			self:setValue(GameSettings.SETTING.USE_MILES, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.miles"), self[GameSettings.SETTING.USE_MILES]))
			self:setValue(GameSettings.SETTING.USE_FAHRENHEIT, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.fahrenheit"), self[GameSettings.SETTING.USE_FAHRENHEIT]))
			self:setValue(GameSettings.SETTING.USE_ACRE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.acre"), self[GameSettings.SETTING.USE_ACRE]))
		end

		self:setValue(GameSettings.SETTING.GYROSCOPE_STEERING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.gyroscopeSteering"), self[GameSettings.SETTING.GYROSCOPE_STEERING]))
		self:setValue(GameSettings.SETTING.HINTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.hints"), self[GameSettings.SETTING.HINTS]))
		self:setValue(GameSettings.SETTING.CAMERA_TILTING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraTilting"), self[GameSettings.SETTING.CAMERA_TILTING]))

		self.tutorialsDone = {}
		local i = 0

		while true do
			local key = string.format("gameSettings.tutorials.tutorial(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local tutorialId = getXMLString(xmlFile, key .. "#id")
			local tutorialCompleted = Utils.getNoNil(getXMLBool(xmlFile, key .. "#done"), false)

			if tutorialId ~= nil then
				self:setTableValue("tutorialsDone", tutorialId, tutorialCompleted)
			end

			i = i + 1
		end

		self.notifyOnChange = true
	end
end

function GameSettings:setTableValueFromXML(tableName, index, xmlFunc, xmlFile, xmlPath)
	local value = xmlFunc(xmlFile, xmlPath)

	if value ~= nil then
		self:setTableValue(tableName, index, value)
	end
end

function GameSettings:saveToXMLFile(xmlFile)
	if xmlFile ~= nil then
		setXMLBool(xmlFile, "gameSettings.invertYLook", self[GameSettings.SETTING.INVERT_Y_LOOK])
		setXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled", self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED])
		setXMLBool(xmlFile, "gameSettings.isGamepadEnabled", self[GameSettings.SETTING.IS_GAMEPAD_ENABLED])
		setXMLFloat(xmlFile, "gameSettings.cameraSensitivity", self[GameSettings.SETTING.CAMERA_SENSITIVITY])
		setXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity", self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY])
		setXMLFloat(xmlFile, "gameSettings.steeringBackSpeed", self[GameSettings.SETTING.STEERING_BACK_SPEED])
		setXMLFloat(xmlFile, "gameSettings.steeringSensitivity", self[GameSettings.SETTING.STEERING_SENSITIVITY])
		setXMLInt(xmlFile, "gameSettings.inputHelpMode", self[GameSettings.SETTING.INPUT_HELP_MODE])
		setXMLBool(xmlFile, "gameSettings.easyArmControl", self[GameSettings.SETTING.EASY_ARM_CONTROL])
		setXMLBool(xmlFile, "gameSettings.gyroscopeSteering", self[GameSettings.SETTING.GYROSCOPE_STEERING])
		setXMLBool(xmlFile, "gameSettings.hints", self[GameSettings.SETTING.HINTS])
		setXMLBool(xmlFile, "gameSettings.cameraTilting", self[GameSettings.SETTING.CAMERA_TILTING])
		setXMLBool(xmlFile, "gameSettings.showAllMods", self[GameSettings.SETTING.SHOW_ALL_MODS])
		setXMLInt(xmlFile, "gameSettings.player#index", self[GameSettings.SETTING.PLAYER_MODEL_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#bodyIndex", self[GameSettings.SETTING.PLAYER_BODY_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#colorIndex", self[GameSettings.SETTING.PLAYER_COLOR_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#hatIndex", self[GameSettings.SETTING.PLAYER_HAT_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#hairIndex", self[GameSettings.SETTING.PLAYER_HAIR_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#accessoryIndex", self[GameSettings.SETTING.PLAYER_ACCESSORY_INDEX])
		setXMLInt(xmlFile, "gameSettings.player#jacketIndex", self[GameSettings.SETTING.PLAYER_JACKET_INDEX])
		setXMLString(xmlFile, "gameSettings.player#name", self[GameSettings.SETTING.NICKNAME])
		setXMLInt(xmlFile, "gameSettings.mpLanguage", self[GameSettings.SETTING.MP_LANGUAGE])
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#password", self.createGame.password)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#name", self.createGame.serverName)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#port", self.createGame.port)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#useUpnp", self.createGame.useUpnp)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoAccept", self.createGame.autoAccept)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoSave", self.createGame.autoSave)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowOnlyFriends", self.createGame.allowOnlyFriends)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#capacity", self.createGame.capacity)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#bandwidth", self.createGame.bandwidth)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#password", self.joinGame.password)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#hasNoPassword", self.joinGame.hasNoPassword)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#isNotEmpty", self.joinGame.isNotEmpty)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#onlyWithAllModsAvailable", self.joinGame.onlyWithAllModsAvailable)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#serverName", self.joinGame.serverName)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#mapId", self.joinGame.mapId)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#language", self.joinGame.language)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#capacity", self.joinGame.capacity)
		setXMLFloat(xmlFile, "gameSettings.volume.music", self[GameSettings.SETTING.VOLUME_MUSIC])
		setXMLFloat(xmlFile, "gameSettings.volume.vehicle", self[GameSettings.SETTING.VOLUME_VEHICLE])
		setXMLFloat(xmlFile, "gameSettings.volume.environment", self[GameSettings.SETTING.VOLUME_ENVIRONMENT])
		setXMLFloat(xmlFile, "gameSettings.volume.radio", self[GameSettings.SETTING.VOLUME_RADIO])
		setXMLFloat(xmlFile, "gameSettings.volume.gui", self[GameSettings.SETTING.VOLUME_GUI])
		setXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams", self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED])
		setXMLBool(xmlFile, "gameSettings.radioIsActive", self[GameSettings.SETTING.RADIO_IS_ACTIVE])
		setXMLBool(xmlFile, "gameSettings.radioVehicleOnly", self[GameSettings.SETTING.RADIO_VEHICLE_ONLY])
		setXMLInt(xmlFile, "gameSettings.units.money", self[GameSettings.SETTING.MONEY_UNIT])
		setXMLBool(xmlFile, "gameSettings.units.miles", self[GameSettings.SETTING.USE_MILES])
		setXMLBool(xmlFile, "gameSettings.units.fahrenheit", self[GameSettings.SETTING.USE_FAHRENHEIT])
		setXMLBool(xmlFile, "gameSettings.units.acre", self[GameSettings.SETTING.USE_ACRE])
		setXMLBool(xmlFile, "gameSettings.isTrainTabbable", self[GameSettings.SETTING.IS_TRAIN_TABBABLE])
		setXMLBool(xmlFile, "gameSettings.showTriggerMarker", self[GameSettings.SETTING.SHOW_TRIGGER_MARKER])
		setXMLBool(xmlFile, "gameSettings.showFieldInfo", self[GameSettings.SETTING.SHOW_FIELD_INFO])
		setXMLBool(xmlFile, "gameSettings.showHelpIcons", self[GameSettings.SETTING.SHOW_HELP_ICONS])
		setXMLBool(xmlFile, "gameSettings.showHelpMenu", self[GameSettings.SETTING.SHOW_HELP_MENU])
		setXMLBool(xmlFile, "gameSettings.resetCamera", self[GameSettings.SETTING.RESET_CAMERA])
		setXMLBool(xmlFile, "gameSettings.useWorldCamera", self[GameSettings.SETTING.USE_WORLD_CAMERA])
		setXMLInt(xmlFile, "gameSettings.ingameMapState", self[GameSettings.SETTING.INGAME_MAP_STATE])
		setXMLInt(xmlFile, "gameSettings.ingameMapFilter", self[GameSettings.SETTING.INGAME_MAP_FILTER])
		setXMLBool(xmlFile, "gameSettings.useColorblindMode", self[GameSettings.SETTING.USE_COLORBLIND_MODE])
		setXMLInt(xmlFile, "gameSettings.maxNumMirrors", self[GameSettings.SETTING.MAX_NUM_MIRRORS])
		setXMLInt(xmlFile, "gameSettings.lightsProfile", self[GameSettings.SETTING.LIGHTS_PROFILE])
		setXMLFloat(xmlFile, "gameSettings.fovY", math.deg(self[GameSettings.SETTING.FOV_Y]))
		setXMLFloat(xmlFile, "gameSettings.uiScale", self[GameSettings.SETTING.UI_SCALE])
		setXMLBool(xmlFile, "gameSettings.realBeaconLights", self[GameSettings.SETTING.REAL_BEACON_LIGHTS])

		local numTutorials = 0

		for tutorialId, tutorialDone in pairs(self.tutorialsDone) do
			local key = string.format("gameSettings.tutorials.tutorial(%d)", numTutorials)

			setXMLString(xmlFile, key .. "#id", tutorialId)
			setXMLBool(xmlFile, key .. "#done", tutorialDone)

			numTutorials = numTutorials + 1
		end

		saveXMLFile(xmlFile)
		syncProfileFiles()
	end
end

function GameSettings:setXMLValue(xmlFile, func, xPath, value)
	if value ~= nil then
		func(xmlFile, xPath, value)
	end
end
