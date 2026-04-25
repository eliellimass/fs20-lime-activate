SettingsModel = {}
local SettingsModel_mt = Class(SettingsModel)
SettingsModel.SETTING_CLASS = {
	SAVE_GAMEPLAY_SETTINGS = 2,
	SAVE_ALL = 3,
	SAVE_ENGINE_QUALITY_SETTINGS = 1,
	SAVE_NONE = 0
}
SettingsModel.SETTING = {
	RESOLUTION = "resolution",
	MSAA = "msaa",
	MAX_TIRE_TRACKS = "maxTireTracks",
	TEXTURE_RESOLUTION = "textureResolution",
	CONSOLE_RESOLUTION = "consoleResolution",
	V_SYNC = "vSync",
	LANGUAGE = "language",
	LOD_DISTANCE = "lodDistance",
	SHADOW_MAP_FILTERING = "shadowMapFiltering",
	TERRAIN_LOD_DISTANCE = "terrainLODDistance",
	FOLIAGE_DRAW_DISTANCE = "foliageDrawDistance",
	RESOLUTION_SCALE = "resolutionScale",
	SHADOW_QUALITY = "shadowQuality",
	TEXTURE_FILTERING = "textureFiltering",
	BRIGHTNESS = "brightness",
	PERFORMANCE_CLASS = "performanceClass",
	VOLUME_MESH_TESSELLATION = "volumeMeshTessellation",
	MAX_LIGHTS = "maxLights",
	TERRAIN_QUALITY = "terrainQuality",
	CONSOLE_RENDER_QUALITY = "consoleRenderQuality",
	WINDOW_MODE = "windowMode",
	SHADER_QUALITY = "shaderQuality",
	MP_LANGUAGE = "mpLanguage",
	OBJECT_DRAW_DISTANCE = "objectDrawDistance",
	LIGHTS_PROFILE = GameSettings.SETTING.LIGHTS_PROFILE,
	REAL_BEACON_LIGHTS = GameSettings.SETTING.REAL_BEACON_LIGHTS,
	MAX_MIRRORS = GameSettings.SETTING.MAX_NUM_MIRRORS,
	INPUT_HELP_MODE = GameSettings.SETTING.INPUT_HELP_MODE,
	GAMEPAD_ENABLED = GameSettings.SETTING.IS_GAMEPAD_ENABLED,
	HEAD_TRACKING_ENABLED = GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED,
	VOLUME_MUSIC = GameSettings.SETTING.VOLUME_MUSIC,
	UI_SCALE = GameSettings.SETTING.UI_SCALE,
	FOV_Y = GameSettings.SETTING.FOV_Y,
	INVERT_Y_LOOK = GameSettings.SETTING.INVERT_Y_LOOK,
	VOLUME_MASTER = GameSettings.SETTING.VOLUME_MASTER,
	SHOW_HELP_MENU = GameSettings.SETTING.SHOW_HELP_MENU,
	EASY_ARM_CONTROL = GameSettings.SETTING.EASY_ARM_CONTROL,
	VOLUME_ENVIRONMENT = GameSettings.SETTING.VOLUME_ENVIRONMENT,
	VOLUME_VEHICLE = GameSettings.SETTING.VOLUME_VEHICLE,
	RADIO_VEHICLE_ONLY = GameSettings.SETTING.RADIO_VEHICLE_ONLY,
	RADIO_IS_ACTIVE = GameSettings.SETTING.RADIO_IS_ACTIVE,
	VOLUME_RADIO = GameSettings.SETTING.VOLUME_RADIO,
	VOLUME_GUI = GameSettings.SETTING.VOLUME_GUI,
	SHOW_HELP_ICONS = GameSettings.SETTING.SHOW_HELP_ICONS,
	USE_COLORBLIND_MODE = GameSettings.SETTING.USE_COLORBLIND_MODE,
	SHOW_TRIGGER_MARKER = GameSettings.SETTING.SHOW_TRIGGER_MARKER,
	SHOW_FIELD_INFO = GameSettings.SETTING.SHOW_FIELD_INFO,
	USE_MILES = GameSettings.SETTING.USE_MILES,
	USE_FAHRENHEIT = GameSettings.SETTING.USE_FAHRENHEIT,
	USE_ACRE = GameSettings.SETTING.USE_ACRE,
	MONEY_UNIT = GameSettings.SETTING.MONEY_UNIT,
	RESET_CAMERA = GameSettings.SETTING.RESET_CAMERA,
	USE_WORLD_CAMERA = GameSettings.SETTING.USE_WORLD_CAMERA,
	IS_TRAIN_TABBABLE = GameSettings.SETTING.IS_TRAIN_TABBABLE,
	CAMERA_SENSITIVITY = GameSettings.SETTING.CAMERA_SENSITIVITY,
	VEHICLE_ARM_SENSITIVITY = GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY,
	STEERING_BACK_SPEED = GameSettings.SETTING.STEERING_BACK_SPEED,
	STEERING_SENSITIVITY = GameSettings.SETTING.STEERING_SENSITIVITY,
	GYROSCOPE_STEERING = GameSettings.SETTING.GYROSCOPE_STEERING,
	CAMERA_TILTING = GameSettings.SETTING.CAMERA_TILTING,
	HINTS = GameSettings.SETTING.HINTS
}

function SettingsModel.new(gameSettings, settingsFileHandle, l10n, soundMixer, isConsoleVersion)
	local self = setmetatable({}, SettingsModel_mt)
	self.gameSettings = gameSettings
	self.settingsFileHandle = settingsFileHandle
	self.l10n = l10n
	self.soundMixer = soundMixer
	self.isConsoleVersion = isConsoleVersion
	self.settings = {}
	self.sortedSettings = {}
	self.settingReaders = {}
	self.settingWriters = {}
	self.defaultReaderFunction = self:makeDefaultReaderFunction()
	self.defaultWriterFunction = self:makeDefaultWriterFunction()
	self.volumeTexts = {}
	self.brightnessTexts = {}
	self.fovYTexts = {}
	self.indexToFovYMapping = {}
	self.fovYToIndexMapping = {}
	self.uiScaleValues = {}
	self.uiScaleTexts = {}
	self.cameraSensitivityValues = {}
	self.cameraSensitivityStrings = {}
	self.cameraSensitivityStep = 0.25
	self.vehicleArmSensitivityValues = {}
	self.vehicleArmSensitivityStrings = {}
	self.vehicleArmSensitivityStep = 0.25
	self.steeringBackSpeedValues = {}
	self.steeringBackSpeedStrings = {}
	self.steeringBackSpeedStep = 1
	self.steeringSensitivityValues = {}
	self.steeringSensitivityStrings = {}
	self.steeringSensitivityStep = 0.1
	self.moneyUnitTexts = {}
	self.distanceUnitTexts = {}
	self.temperatureUnitTexts = {}
	self.areaUnitTexts = {}
	self.radioModeTexts = {}
	self.resolutionScaleTexts = {}
	self.msaaTexts = {}
	self.shadowQualityTexts = {}
	self.fourStateTexts = {}
	self.lowHighTexts = {}
	self.textureFilteringTexts = {}
	self.shadowMapMaxLightsTexts = {}
	self.percentValues = {}
	self.perentageTexts = {}
	self.percentStep = 0.05
	self.tireTracksValues = {}
	self.tireTracksTexts = {}
	self.tireTracksStep = 0.5
	self.maxMirrorsTexts = {}
	self.resolutionTexts = {}
	self.mpLanguageTexts = {}
	self.inputHelpModeTexts = {}
	self.intialValues = {}
	self.deviceSettings = {}
	self.currentDevice = {}
	self.minBrightness = 0.5
	self.maxBrightness = 2
	self.brightnessStep = 0.1
	self.minFovY = 45
	self.maxFovY = 90

	self:initialize()

	return self
end

function SettingsModel:initialize()
	self:createControlDisplayValues()
	self:addManagedSettings()

	if g_isPresentationVersion then
		self:setValue(SettingsModel.SETTING.PERFORMANCE_CLASS, 3)
		self:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)
	end
end

function SettingsModel:addManagedSettings()
	self:addPerformanceClassSetting()
	self:addMSAASetting()
	self:addTextureFilteringSetting()
	self:addTextureResolutionSetting()
	self:addShadowQualitySetting()
	self:addShaderQualitySetting()
	self:addShadowMapFilteringSetting()
	self:addShadowMaxLightsSetting()
	self:addTerrainQualitySetting()
	self:addObjectDrawDistanceSetting()
	self:addFoliageDrawDistanceSetting()
	self:addLODDistanceSetting()
	self:addTerrainLODDistanceSetting()
	self:addVolumeMeshTessellationSetting()
	self:addMaxTireTracksSetting()
	self:addLightsProfileSetting()
	self:addRealBeaconLightsSetting()
	self:addMaxMirrorsSetting()
	self:addWindowModeSetting()
	self:addLanguageSetting()
	self:addMPLanguageSetting()
	self:addInputHelpModeSetting()
	self:addBrightnessSetting()
	self:addVSyncSetting()
	self:addFovYSetting()
	self:addUIScaleSetting()
	self:addMasterVolumeSetting()
	self:addMusicVolumeSetting()
	self:addEnvironmentVolumeSetting()
	self:addVehicleVolumeSetting()
	self:addRadioVolumeSetting()
	self:addVolumeGUISetting()
	self:addSteeringBackSpeedSetting()
	self:addSteeringSensitivitySetting()
	self:addCameraSensitivitySetting()
	self:addVehicleArmSensitivitySetting()

	if GS_IS_MOBILE_VERSION then
		self:addGyroscopeSteeringSetting()
		self:addHintsSetting()
		self:addCameraTiltingSetting()
	end

	if GS_IS_CONSOLE_VERSION then
		self:addConsoleResolutionSetting()
		self:addConsoleRenderQualitySetting()
	else
		self:addSetting(SettingsModel.SETTING.RESOLUTION, getScreenMode, setScreenMode)
		self:addResolutionScaleSetting()
	end

	self:addDirectSetting(SettingsModel.SETTING.USE_COLORBLIND_MODE)
	self:addDirectSetting(SettingsModel.SETTING.GAMEPAD_ENABLED)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_FIELD_INFO)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_MENU)
	self:addDirectSetting(SettingsModel.SETTING.RADIO_IS_ACTIVE)
	self:addDirectSetting(SettingsModel.SETTING.RESET_CAMERA)
	self:addDirectSetting(SettingsModel.SETTING.RADIO_VEHICLE_ONLY)
	self:addDirectSetting(SettingsModel.SETTING.IS_TRAIN_TABBABLE)
	self:addDirectSetting(SettingsModel.SETTING.HEAD_TRACKING_ENABLED)
	self:addDirectSetting(SettingsModel.SETTING.USE_FAHRENHEIT)
	self:addDirectSetting(SettingsModel.SETTING.USE_WORLD_CAMERA)
	self:addDirectSetting(SettingsModel.SETTING.MONEY_UNIT)
	self:addDirectSetting(SettingsModel.SETTING.USE_ACRE)
	self:addDirectSetting(SettingsModel.SETTING.EASY_ARM_CONTROL)
	self:addDirectSetting(SettingsModel.SETTING.INVERT_Y_LOOK)
	self:addDirectSetting(SettingsModel.SETTING.USE_MILES)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_TRIGGER_MARKER)
	self:addDirectSetting(SettingsModel.SETTING.SHOW_HELP_ICONS)
end

function SettingsModel:addSetting(gameSettingsKey, readerFunction, writerFunction, noRestartRequired)
	local initialValue = readerFunction(gameSettingsKey)
	self.settings[gameSettingsKey] = {
		key = gameSettingsKey,
		saved = initialValue,
		changed = initialValue,
		noRestartRequired = noRestartRequired
	}
	self.settingReaders[gameSettingsKey] = readerFunction
	self.settingWriters[gameSettingsKey] = writerFunction

	table.insert(self.sortedSettings, self.settings[gameSettingsKey])
end

function SettingsModel:setValue(settingKey, value)
	self.settings[settingKey].changed = value
end

function SettingsModel:getValue(settingKey, trueValue)
	if trueValue then
		return self.settingReaders[settingKey](settingKey)
	end

	if self.settings[settingKey] == nil then
		return 0
	end

	return self.settings[settingKey].changed
end

function SettingsModel:setSettingsFileHandle(settingsFileHandle)
	self.settingsFileHandle = settingsFileHandle
end

function SettingsModel:refresh()
	for settingsKey, setting in pairs(self.settings) do
		setting.saved = self.settingReaders[settingsKey](settingsKey)
		setting.changed = setting.saved
	end
end

function SettingsModel:refreshChangedValue()
	for settingsKey, setting in pairs(self.settings) do
		setting.changed = self.settingReaders[settingsKey](settingsKey)
	end
end

function SettingsModel:reset()
	for _, setting in pairs(self.sortedSettings) do
		setting.changed = setting.saved
		local writeFunction = self.settingWriters[setting.key]

		writeFunction(setting.changed, setting.key)
	end

	self:resetDeviceChanges()
end

function SettingsModel:hasChanges()
	for _, setting in pairs(self.settings) do
		if setting.saved ~= setting.changed then
			return true
		end
	end

	return self:hasDeviceChanges()
end

function SettingsModel:needsRestartToApplyChanges()
	for _, setting in pairs(self.settings) do
		if setting.saved ~= setting.changed and not setting.noRestartRequired then
			return true
		end
	end

	return self:hasDeviceChanges()
end

function SettingsModel:applyChanges(settingClassesToSave)
	for _, setting in pairs(self.sortedSettings) do
		local settingsKey = setting.key
		local savedValue = self.settings[settingsKey].saved
		local changedValue = self.settings[settingsKey].changed

		if savedValue ~= changedValue then
			local writeFunction = self.settingWriters[settingsKey]

			writeFunction(changedValue, settingsKey)

			self.settings[settingsKey].saved = changedValue
		end
	end

	if settingClassesToSave ~= 0 then
		self:saveChanges(settingClassesToSave)
	end
end

function SettingsModel:saveChanges(settingClassesToSave)
	if bitAND(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS) ~= 0 then
		self.gameSettings:saveToXMLFile(self.settingsFileHandle)
	end

	self:saveDeviceChanges()

	if bitAND(settingClassesToSave, SettingsModel.SETTING_CLASS.SAVE_ENGINE_QUALITY_SETTINGS) ~= 0 then
		saveHardwareScalability()

		if self.isConsoleVersion or GS_IS_MOBILE_VERSION then
			executeSettingsChange()
		end
	end
end

function SettingsModel:applyPerformanceClass(value)
	local settingsKey = SettingsModel.SETTING.PERFORMANCE_CLASS
	local writeFunction = self.settingWriters[settingsKey]

	writeFunction(value, settingsKey)

	self.settings[settingsKey].changed = value

	self:refreshChangedValue()
end

function SettingsModel:applyCustomSettings()
	for settingsKey in pairs(self.settings) do
		if settingsKey ~= SettingsModel.SETTING.PERFORMANCE_CLASS then
			local changedValue = self.settings[settingsKey].changed
			local writeFunction = self.settingWriters[settingsKey]

			writeFunction(changedValue, settingsKey)
		end
	end
end

function SettingsModel:createControlDisplayValues()
	self.volumeTexts = {
		self.l10n:getText("ui_off"),
		"10%",
		"20%",
		"30%",
		"40%",
		"50%",
		"60%",
		"70%",
		"80%",
		"90%",
		"100%"
	}

	for i = self.minBrightness, self.maxBrightness + 0.0001, self.brightnessStep do
		table.insert(self.brightnessTexts, string.format("%.1f", i))
	end

	local index = 1

	for i = self.minFovY, self.maxFovY do
		self.indexToFovYMapping[index] = i
		self.fovYToIndexMapping[i] = index

		table.insert(self.fovYTexts, string.format(self.l10n:getText("setting_fovyDegree"), i))

		index = index + 1
	end

	for i = 1, 11 do
		table.insert(self.uiScaleTexts, string.format("%d%%", MathUtil.round(0.5 + (i - 1) * 0.1, 1) * 100))
	end

	for i = 0.5, 2.1, 0.1 do
		table.insert(self.resolutionScaleTexts, string.format("%d%%", MathUtil.round(i * 100)))
	end

	for i = 0.5, 3, self.cameraSensitivityStep do
		table.insert(self.cameraSensitivityStrings, string.format("%d%%", i * 100))
		table.insert(self.cameraSensitivityValues, i)
	end

	for i = 0.5, 3, self.vehicleArmSensitivityStep do
		table.insert(self.vehicleArmSensitivityStrings, string.format("%d%%", i * 100))
		table.insert(self.vehicleArmSensitivityValues, i)
	end

	for i = 0, 10, self.steeringBackSpeedStep do
		table.insert(self.steeringBackSpeedStrings, string.format("%d%%", i * 10))
		table.insert(self.steeringBackSpeedValues, i)
	end

	for i = 0.4, 2, self.steeringSensitivityStep do
		table.insert(self.steeringSensitivityStrings, string.format("%d%%", i * 100 + 0.5))
		table.insert(self.steeringSensitivityValues, i)
	end

	self.moneyUnitTexts = {
		self.l10n:getText("unit_euro"),
		self.l10n:getText("unit_dollar"),
		self.l10n:getText("unit_pound")
	}
	self.distanceUnitTexts = {
		self.l10n:getText("unit_km"),
		self.l10n:getText("unit_miles")
	}
	self.temperatureUnitTexts = {
		self.l10n:getText("unit_celsius"),
		self.l10n:getText("unit_fahrenheit")
	}
	self.areaUnitTexts = {
		self.l10n:getText("unit_ha"),
		self.l10n:getText("unit_acre")
	}
	self.radioModeTexts = {
		self.l10n:getText("setting_radioAlways"),
		self.l10n:getText("setting_radioVehicleOnly")
	}
	self.msaaTexts = {
		self.l10n:getText("ui_off"),
		"2x",
		"4x",
		"8x"
	}
	self.shadowQualityTexts = {
		self.l10n:getText("setting_off"),
		self.l10n:getText("setting_medium"),
		self.l10n:getText("setting_high"),
		self.l10n:getText("setting_veryHigh")
	}
	self.fourStateTexts = {
		self.l10n:getText("setting_low"),
		self.l10n:getText("setting_medium"),
		self.l10n:getText("setting_high"),
		self.l10n:getText("setting_veryHigh")
	}
	self.lowHighTexts = {
		self.l10n:getText("setting_low"),
		self.l10n:getText("setting_high")
	}
	self.textureFilteringTexts = {
		"Bilinear",
		"Trilinear",
		"Aniso 1x",
		"Aniso 2x",
		"Aniso 4x",
		"Aniso 8x",
		"Aniso 16x"
	}
	self.shadowMapMaxLightsTexts = {}

	for i = 1, 10 do
		table.insert(self.shadowMapMaxLightsTexts, string.format("%d", i))
	end

	self.percentValues = {}
	self.perentageTexts = {}
	self.percentStep = 0.05

	for i = 0, 30 do
		table.insert(self.perentageTexts, string.format("%.f%%", (0.5 + i * self.percentStep) * 100))
		table.insert(self.percentValues, 0.5 + i * self.percentStep)
	end

	self.tireTracksValues = {}
	self.tireTracksTexts = {}
	self.tireTracksStep = 0.5

	for i = 0, 4, self.tireTracksStep do
		table.insert(self.tireTracksTexts, string.format("%d%%", i * 100))
		table.insert(self.tireTracksValues, i)
	end

	self.maxMirrorsTexts = {}

	for i = 0, 7 do
		table.insert(self.maxMirrorsTexts, string.format("%d", i))
	end

	self.resolutionTexts = {}
	local numR = getNumOfScreenModes()

	for i = 0, numR - 1 do
		local x, y = getScreenModeInfo(i)
		local aspect = x / y
		local aspectStr = ""

		if aspect == 1.25 then
			aspectStr = "(5:4)"
		elseif aspect > 1.3 and aspect < 1.4 then
			aspectStr = "(4:3)"
		elseif aspect > 1.7 and aspect < 1.8 then
			aspectStr = "(16:9)"
		elseif aspect > 2.3 and aspect < 2.4 then
			aspectStr = "(21:9)"
		else
			aspectStr = string.format("(%1.0f:10)", aspect * 10)
		end

		table.insert(self.resolutionTexts, string.format("%dx%d %s", x, y, aspectStr))
	end

	self.mpLanguageTexts = {}
	local numL = getNumOfLanguages()

	for i = 0, numL - 1 do
		table.insert(self.mpLanguageTexts, getLanguageName(i))
	end

	self.inputHelpModeTexts = {
		self.l10n:getText("ui_auto"),
		self.l10n:getText("ui_keyboard"),
		self.l10n:getText("ui_gamepad")
	}
	self.consoleResolutionTexts = {
		self.l10n:getText("ui_fullhd_desc"),
		self.l10n:getText("ui_quadhd_desc")
	}
	self.consoleRenderQualityTexts = {
		self.l10n:getText("button_normal"),
		self.l10n:getText("button_enhanced")
	}
	self.deadzoneValues = {}
	self.deadzoneTexts = {}
	self.deadzoneStep = 0.01

	for i = 0, 0.301, self.deadzoneStep do
		table.insert(self.deadzoneTexts, string.format("%d%%", math.floor(i * 100 + 0.001)))
		table.insert(self.deadzoneValues, i)
	end

	self.sensitivityValues = {}
	self.sensitivityTexts = {}
	self.sensitivityStep = 0.25

	for i = 1, 2, self.sensitivityStep do
		table.insert(self.sensitivityTexts, string.format("%d%%", i * 100))
		table.insert(self.sensitivityValues, i)
	end
end

function SettingsModel:getDeadzoneTexts()
	return self.deadzoneTexts
end

function SettingsModel:getSensitivityTexts()
	return self.sensitivityTexts
end

function SettingsModel:getDeviceHasAxisDeadzone(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]

	return settings ~= nil and settings.deadzones[axisIndex] ~= nil
end

function SettingsModel:getDeviceHasAxisSensitivity(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]

	return settings ~= nil and settings.sensitivities[axisIndex] ~= nil
end

function SettingsModel:getNumDevices()
	return #self.deviceSettings
end

function SettingsModel:nextDevice()
	self.currentDevice = self.currentDevice + 1

	if self.currentDevice > #self.deviceSettings then
		self.currentDevice = 1
	end
end

function SettingsModel:getCurrentDeviceName()
	local setting = self.deviceSettings[self.currentDevice]

	if setting ~= nil then
		return setting.device.deviceName
	end

	return ""
end

function SettingsModel:initDeviceSettings()
	self.deviceSettings = {}
	self.currentDevice = 0

	for _, device in pairs(g_inputBinding.devicesByInternalId) do
		local deadzones = {}
		local sensitivities = {}
		local mouseSensitivity = {}

		table.insert(self.deviceSettings, {
			device = device,
			deadzones = deadzones,
			sensitivities = sensitivities,
			mouseSensitivity = mouseSensitivity
		})

		for axisIndex = 0, Input.MAX_NUM_AXES - 1 do
			if getHasGamepadAxis(axisIndex, device.internalId) then
				local deadzone = device:getDeadzone(axisIndex)
				local value = Utils.getValueIndex(deadzone, self.deadzoneValues)
				deadzones[axisIndex] = {
					current = value,
					saved = value
				}
				local sensitivity = device:getSensitivity(axisIndex)
				local value = Utils.getValueIndex(sensitivity, self.sensitivityValues)
				sensitivities[axisIndex] = {
					current = value,
					saved = value
				}
			end
		end

		if device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local scale, _ = g_inputBinding:getMouseMotionScale()
			local value = Utils.getValueIndex(scale, self.sensitivityValues)
			mouseSensitivity.current = value
			mouseSensitivity.saved = value
		end

		self.currentDevice = 1
	end
end

function SettingsModel:hasDeviceChanges()
	for _, settings in ipairs(self.deviceSettings) do
		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzone = settings.deadzones[axisIndex]

			if deadzone.current ~= deadzone.saved then
				return true
			end

			local sensitivity = settings.sensitivities[axisIndex]

			if sensitivity.current ~= sensitivity.saved then
				return true
			end
		end

		if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local mouseSensitivity = settings.mouseSensitivity

			if mouseSensitivity.current ~= mouseSensitivity.saved then
				return true
			end
		end
	end

	return false
end

function SettingsModel:saveDeviceChanges()
	local changedSettings = false

	for _, settings in ipairs(self.deviceSettings) do
		local device = settings.device

		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzones = settings.deadzones[axisIndex]
			local deadzone = self.deadzoneValues[deadzones.current]
			deadzones.saved = deadzones.current

			device:setDeadzone(axisIndex, deadzone)

			local sensitivities = settings.sensitivities[axisIndex]
			local sensitivity = self.sensitivityValues[sensitivities.current]
			sensitivities.saved = sensitivities.current

			device:setSensitivity(axisIndex, sensitivity)

			changedSettings = true
		end

		if settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			local mouseSensitivity = settings.mouseSensitivity

			if mouseSensitivity.current ~= mouseSensitivity.saved then
				g_inputBinding:setMouseMotionScale(self.sensitivityValues[mouseSensitivity.current])

				mouseSensitivity.saved = mouseSensitivity.current
				changedSettings = true
			end
		end
	end

	if changedSettings then
		g_inputBinding:applyGamepadDeadzones()
		g_inputBinding:saveToXMLFile()
	end
end

function SettingsModel:resetDeviceChanges()
	for _, settings in ipairs(self.deviceSettings) do
		for axisIndex, _ in pairs(settings.deadzones) do
			local deadzone = settings.deadzones[axisIndex]
			deadzone.current = deadzone.saved
			local sensitivity = settings.sensitivities[axisIndex]
			sensitivity.current = deadzone.saved
		end

		settings.mouseSensitivity.current = settings.mouseSensitivity.saved
	end
end

function SettingsModel:setDeviceDeadzoneValue(axisIndex, value)
	local settings = self.deviceSettings[self.currentDevice]

	if settings ~= nil then
		settings.deadzones[axisIndex].current = value
	end
end

function SettingsModel:setDeviceSensitivityValue(axisIndex, value)
	local settings = self.deviceSettings[self.currentDevice]

	if settings ~= nil then
		settings.sensitivities[axisIndex].current = value
	end
end

function SettingsModel:setMouseSensitivity(value)
	local settings = self.deviceSettings[self.currentDevice]

	if settings ~= nil then
		settings.mouseSensitivity.current = value
	end
end

function SettingsModel:getDeviceAxisDeadzoneValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]

	return settings.deadzones[axisIndex].current
end

function SettingsModel:getDeviceAxisSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]

	return settings.sensitivities[axisIndex].current
end

function SettingsModel:getMouseSensitivityValue(axisIndex)
	local settings = self.deviceSettings[self.currentDevice]

	return settings.mouseSensitivity.current
end

function SettingsModel:getIsDeviceMouse()
	local settings = self.deviceSettings[self.currentDevice]

	return settings ~= nil and settings.device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE
end

function SettingsModel:setConsoleResolution(value)
	local displayResolution = self:getValue(SettingsModel.SETTING.CONSOLE_RESOLUTION)

	if not getNeoMode() or displayResolution then
		self:setValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY, 1)
	else
		self:setValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY, self.settings[SettingsModel.SETTING.CONSOLE_RENDER_QUALITY].saved)
	end

	self:setValue(SettingsModel.SETTING.CONSOLE_RESOLUTION, value)
end

function SettingsModel:getConsoleIsRenderQualityDisabled()
	local displayResolution = self:getValue(SettingsModel.SETTING.CONSOLE_RESOLUTION)

	return not getNeoMode() or displayResolution ~= 1
end

function SettingsModel:getConsoleIsResolutionVisible()
	return getNeoMode() and get4kAvailable()
end

function SettingsModel:getConsoleIsRenderQualityVisible()
	return getNeoMode()
end

function SettingsModel:getConsoleResolutionTexts()
	return self.consoleResolutionTexts
end

function SettingsModel:getConsoleRenderQualityTexts()
	return self.consoleRenderQualityTexts
end

function SettingsModel:getResolutionTexts()
	return self.resolutionTexts
end

function SettingsModel:getMPLanguageTexts()
	return self.mpLanguageTexts
end

function SettingsModel:getInputHelpModeTexts()
	return self.inputHelpModeTexts
end

function SettingsModel:getLanguageTexts()
	return g_availableLanguageNamesTable
end

function SettingsModel:getIsLanguageDisabled()
	return #g_availableLanguagesTable <= 1 or GS_IS_STEAM_VERSION
end

function SettingsModel:getPerformanceClassTexts()
	local class, isCustom = getPerformanceClass()
	local texts = {}

	table.insert(texts, self.l10n:getText("setting_low"))
	table.insert(texts, self.l10n:getText("setting_medium"))
	table.insert(texts, self.l10n:getText("setting_high"))
	table.insert(texts, self.l10n:getText("setting_veryHigh"))

	if not GS_IS_MOBILE_VERSION then
		local settings = GS_PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]
		isCustom = isCustom or settings[SettingsModel.SETTING.LIGHTS_PROFILE] ~= g_gameSettings:getValue(SettingsModel.SETTING.LIGHTS_PROFILE)
		isCustom = isCustom or settings[SettingsModel.SETTING.MAX_MIRRORS] ~= g_gameSettings:getValue(SettingsModel.SETTING.MAX_MIRRORS)
		isCustom = isCustom or settings[SettingsModel.SETTING.REAL_BEACON_LIGHTS] ~= g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS)

		if isCustom then
			local index = Utils.getPerformanceClassIndex(class)
			texts[index] = texts[index] .. " (Custom)"
		end
	end

	return texts, class, isCustom
end

function SettingsModel:getMSAATexts()
	return self.msaaTexts
end

function SettingsModel:getShadowQualityTexts()
	return self.shadowQualityTexts
end

function SettingsModel:getShaderQualityTexts()
	return self.fourStateTexts
end

function SettingsModel:getTextureResolutionTexts()
	return self.lowHighTexts
end

function SettingsModel:getTextureFilteringTexts()
	return self.textureFilteringTexts
end

function SettingsModel:getShadowMapFilteringTexts()
	return self.lowHighTexts
end

function SettingsModel:getTerraingQualityTexts()
	return self.lowHighTexts
end

function SettingsModel:getLightsProfileTexts()
	return self.fourStateTexts
end

function SettingsModel:getShadowMapLightsTexts()
	return self.shadowMapMaxLightsTexts
end

function SettingsModel:getObjectDrawDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getFoliageDrawDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getLODDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getTerrainLODDistanceTexts()
	return self.perentageTexts
end

function SettingsModel:getVolumeMeshTessalationTexts()
	return self.perentageTexts
end

function SettingsModel:getMaxTireTracksTexts()
	return self.tireTracksTexts
end

function SettingsModel:getMaxMirrorsTexts()
	return self.maxMirrorsTexts
end

function SettingsModel:getBrightnessTexts()
	return self.brightnessTexts
end

function SettingsModel:getFovYTexts()
	return self.fovYTexts
end

function SettingsModel:getUiScaleTexts()
	return self.uiScaleTexts
end

function SettingsModel:getAudioVolumeTexts()
	return self.volumeTexts
end

function SettingsModel:getCameraSensitivityTexts()
	return self.cameraSensitivityStrings
end

function SettingsModel:getVehicleArmSensitivityTexts()
	return self.vehicleArmSensitivityStrings
end

function SettingsModel:getSteeringBackSpeedTexts()
	return self.steeringBackSpeedStrings
end

function SettingsModel:getSteeringSensitivityTexts()
	return self.steeringSensitivityStrings
end

function SettingsModel:getMoneyUnitTexts()
	return self.moneyUnitTexts
end

function SettingsModel:getDistanceUnitTexts()
	return self.distanceUnitTexts
end

function SettingsModel:getTemperatureUnitTexts()
	return self.temperatureUnitTexts
end

function SettingsModel:getAreaUnitTexts()
	return self.areaUnitTexts
end

function SettingsModel:getRadioModeTexts()
	return self.radioModeTexts
end

function SettingsModel:getResolutionScaleTexts()
	return self.resolutionScaleTexts
end

function SettingsModel:makeDefaultReaderFunction()
	return function (gameSettingsKey)
		return self.gameSettings:getValue(gameSettingsKey)
	end
end

function SettingsModel:makeDefaultWriterFunction()
	return function (value, gameSettingsKey)
		self.gameSettings:setValue(gameSettingsKey, value)
	end
end

function SettingsModel:addDirectSetting(gameSettingsKey)
	self:addSetting(gameSettingsKey, self.defaultReaderFunction, self.defaultWriterFunction)
end

function SettingsModel:addConsoleResolutionSetting()
	local function readValue()
		local displayResolution, _ = SettingsModel.getConsoleResolutionStateFromMode(getDiscretePerformanceSetting())

		return displayResolution
	end

	local function writeValue(value)
		self:setConsolePerformanceSetting()
		setScreenMode(value - 1)
	end

	self:addSetting(SettingsModel.SETTING.CONSOLE_RESOLUTION, readValue, writeValue)
end

function SettingsModel:addConsoleRenderQualitySetting()
	local function readValue()
		local _, renderQuality = SettingsModel.getConsoleResolutionStateFromMode(getDiscretePerformanceSetting())

		return renderQuality
	end

	local function writeValue(value)
		self:setConsolePerformanceSetting()
	end

	self:addSetting(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY, readValue, writeValue)
end

function SettingsModel:setConsolePerformanceSetting()
	local renderQuality = self:getValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY)
	local resolution = self:getValue(SettingsModel.SETTING.CONSOLE_RESOLUTION)
	local discreteSetting = SettingsModel.getModeFromResolutionState(resolution, renderQuality)

	setDiscretePerformanceSetting(discreteSetting)
end

function SettingsModel:addPerformanceClassSetting()
	local function readValue()
		return Utils.getPerformanceClassIndex(getPerformanceClass())
	end

	local function writeValue(value)
		local class = Utils.getPerformanceClassFromIndex(value)

		setPerformanceClass(class)

		if g_currentMission ~= nil and g_currentMission.terrainRootNode ~= nil then
			local foliageViewCoeff = getFoliageViewDistanceCoeff()
			local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(g_currentMission.terrainRootNode)

			setTerrainLodBlendDynamicDistances(g_currentMission.terrainRootNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)
		end

		local settings = GS_PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]

		self.gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, settings[SettingsModel.SETTING.LIGHTS_PROFILE])
		self.gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, settings[SettingsModel.SETTING.MAX_MIRRORS])
		self.gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, settings[SettingsModel.SETTING.REAL_BEACON_LIGHTS])
		onProfileUiResolutionScalingChanged()
	end

	self:addSetting(SettingsModel.SETTING.PERFORMANCE_CLASS, readValue, writeValue)
end

function SettingsModel:addMSAASetting()
	local function readValue()
		return SettingsModel.getMSAAIndex(getMSAA())
	end

	local function writeValue(value)
		setMSAA(SettingsModel.getMSAAFromIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.MSAA, readValue, writeValue)
end

function SettingsModel:addTextureFilteringSetting()
	local function readValue()
		return SettingsModel.getTextureFilteringIndex(getFilterTrilinear(), getFilterAnisotropy())
	end

	local function writeValue(value)
		local isTrilinear, anisoValue = SettingsModel.getTextureFilteringByIndex(value)

		setFilterTrilinear(isTrilinear)
		setFilterAnisotropy(anisoValue)
	end

	self:addSetting(SettingsModel.SETTING.TEXTURE_FILTERING, readValue, writeValue)
end

function SettingsModel:addTextureResolutionSetting()
	local function readValue()
		return SettingsModel.getTextureResolutionIndex(getTextureResolution())
	end

	local function writeValue(value)
		setTextureResolution(SettingsModel.getTextureResolutionByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.TEXTURE_RESOLUTION, readValue, writeValue)
end

function SettingsModel:addShadowQualitySetting()
	local function readValue()
		return SettingsModel.getShadowQualityIndex(getShadowQuality(), getHasShadowFocusBox())
	end

	local function writeValue(value)
		setShadowQuality(SettingsModel.getShadowQualityByIndex(value))
		setHasShadowFocusBox(SettingsModel.getHasShadowFocusBoxByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.SHADOW_QUALITY, readValue, writeValue)
end

function SettingsModel:addShaderQualitySetting()
	local function readValue()
		return SettingsModel.getShaderQualityIndex(getShaderQuality())
	end

	local function writeValue(value)
		setShaderQuality(SettingsModel.getShaderQualityByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.SHADER_QUALITY, readValue, writeValue)
end

function SettingsModel:addShadowMapFilteringSetting()
	local function readValue()
		return SettingsModel.getShadowMapFilterIndex(getShadowMapFilterSize())
	end

	local function writeValue(value)
		setShadowMapFilterSize(SettingsModel.getShadowMapFilterByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.SHADOW_MAP_FILTERING, readValue, writeValue)
end

function SettingsModel:addShadowMaxLightsSetting()
	local function readValue()
		return getMaxNumShadowLights()
	end

	local function writeValue(value)
		setMaxNumShadowLights(value)
	end

	self:addSetting(SettingsModel.SETTING.MAX_LIGHTS, readValue, writeValue)
end

function SettingsModel:addTerrainQualitySetting()
	local function readValue()
		return SettingsModel.getTerrainQualityIndex(getHasTerrainNormalMapping())
	end

	local function writeValue(value)
		setHasTerrainNormalMapping(SettingsModel.getTerrainQualityByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.TERRAIN_QUALITY, readValue, writeValue)
end

function SettingsModel:addObjectDrawDistanceSetting()
	local function readValue()
		return Utils.getValueIndex(getViewDistanceCoeff(), self.percentValues)
	end

	local function writeValue(value)
		setViewDistanceCoeff(self.percentValues[value])
	end

	self:addSetting(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, readValue, writeValue)
end

function SettingsModel:addFoliageDrawDistanceSetting()
	local function readValue()
		return Utils.getValueIndex(getFoliageViewDistanceCoeff(), self.percentValues)
	end

	local function writeValue(value)
		setFoliageViewDistanceCoeff(self.percentValues[value])
	end

	self:addSetting(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, readValue, writeValue)
end

function SettingsModel:addLODDistanceSetting()
	local function readValue()
		return Utils.getValueIndex(getLODDistanceCoeff(), self.percentValues)
	end

	local function writeValue(value)
		setLODDistanceCoeff(self.percentValues[value])
	end

	self:addSetting(SettingsModel.SETTING.LOD_DISTANCE, readValue, writeValue)
end

function SettingsModel:addTerrainLODDistanceSetting()
	local function readValue()
		return Utils.getValueIndex(getTerrainLODDistanceCoeff(), self.percentValues)
	end

	local function writeValue(value)
		setTerrainLODDistanceCoeff(self.percentValues[value])
	end

	self:addSetting(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, readValue, writeValue)
end

function SettingsModel:addVolumeMeshTessellationSetting()
	local function readValue()
		return Utils.getValueIndex(SettingsModel.getVolumeMeshTessellationCoeff(), self.percentValues)
	end

	local function writeValue(value)
		SettingsModel.setVolumeMeshTessellationCoeff(self.percentValues[value])
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, readValue, writeValue)
end

function SettingsModel:addMaxTireTracksSetting()
	local function readValue()
		return Utils.getValueIndex(getTyreTracksSegmentsCoeff(), self.tireTracksValues)
	end

	local function writeValue(value)
		setTyreTracksSegementsCoeff(self.tireTracksValues[value])
	end

	self:addSetting(SettingsModel.SETTING.MAX_TIRE_TRACKS, readValue, writeValue)
end

function SettingsModel:addLightsProfileSetting()
	local function readValue()
		return g_gameSettings:getValue(SettingsModel.SETTING.LIGHTS_PROFILE)
	end

	local function writeValue(value)
		g_gameSettings:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, value)
	end

	self:addSetting(SettingsModel.SETTING.LIGHTS_PROFILE, readValue, writeValue)
end

function SettingsModel:addRealBeaconLightsSetting()
	local function readValue()
		return g_gameSettings:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS)
	end

	local function writeValue(value)
		g_gameSettings:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, value)
	end

	self:addSetting(SettingsModel.SETTING.REAL_BEACON_LIGHTS, readValue, writeValue)
end

function SettingsModel:addMaxMirrorsSetting()
	local function readValue()
		return SettingsModel.getNumOfReflectionMapsIndex(g_gameSettings:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	end

	local function writeValue(value)
		g_gameSettings:setValue(SettingsModel.SETTING.MAX_MIRRORS, SettingsModel.getNumOfReflectionMapsByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.MAX_MIRRORS, readValue, writeValue)
end

function SettingsModel:addWindowModeSetting()
	local function readWindowMode()
		return not getFullscreen()
	end

	local function writeWindowMode(isWindowMode)
		setFullscreen(not isWindowMode)
	end

	self:addSetting(SettingsModel.SETTING.WINDOW_MODE, readWindowMode, writeWindowMode)
end

function SettingsModel:addLanguageSetting()
	local function readLanguage()
		return g_settingsLanguageGUI + 1
	end

	local function writeLanguage(value)
		g_settingsLanguageGUI = value - 1

		setLanguage(g_availableLanguagesTable[value])
	end

	self:addSetting(SettingsModel.SETTING.LANGUAGE, readLanguage, writeLanguage)
end

function SettingsModel:addMPLanguageSetting()
	local function readMPLanguage()
		return self.gameSettings:getValue(SettingsModel.SETTING.MP_LANGUAGE) + 1
	end

	local function writeMPLanguage(value)
		self.gameSettings:setValue(SettingsModel.SETTING.MP_LANGUAGE, value - 1)
	end

	self:addSetting(SettingsModel.SETTING.MP_LANGUAGE, readMPLanguage, writeMPLanguage)
end

function SettingsModel:addInputHelpModeSetting()
	local function readValue()
		return self.gameSettings:getValue(SettingsModel.SETTING.INPUT_HELP_MODE)
	end

	local function writeValue(value)
		self.gameSettings:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, value)
	end

	self:addSetting(SettingsModel.SETTING.INPUT_HELP_MODE, readValue, writeValue, true)
end

function SettingsModel:addBrightnessSetting()
	local function readBrightness()
		local brightness = getBrightness()

		return tonumber(string.format("%.0f", (brightness - self.minBrightness) / self.brightnessStep)) + 1
	end

	local function writeBrightness(index)
		local value = self.minBrightness + self.brightnessStep * (index - 1)

		setBrightness(MathUtil.clamp(value, self.minBrightness, self.maxBrightness))
	end

	self:addSetting(SettingsModel.SETTING.BRIGHTNESS, readBrightness, writeBrightness)
end

function SettingsModel:addVSyncSetting()
	local function readVSync()
		return SettingsModel.getVSyncIndex(getVsync())
	end

	local function writeVSync(value)
		setVsync(SettingsModel.getVSyncByIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.V_SYNC, readVSync, writeVSync)
end

function SettingsModel:addFovYSetting()
	local function readFovY()
		local fovY = math.deg(self.gameSettings:getValue(SettingsModel.SETTING.FOV_Y))

		return self.fovYToIndexMapping[math.min(math.max(math.floor(fovY + 0.5), self.minFovY), self.maxFovY)]
	end

	local function writeFovY(value)
		self.gameSettings:setValue(SettingsModel.SETTING.FOV_Y, math.rad(self.indexToFovYMapping[value]))
	end

	self:addSetting(SettingsModel.SETTING.FOV_Y, readFovY, writeFovY, true)
end

function SettingsModel:addUIScaleSetting()
	local function readUIScale()
		return Utils.getUIScaleIndex(self.gameSettings:getValue(SettingsModel.SETTING.UI_SCALE))
	end

	local function writeUIScale(value)
		self.gameSettings:setValue(SettingsModel.SETTING.UI_SCALE, Utils.getUIScaleFromIndex(value))
	end

	self:addSetting(SettingsModel.SETTING.UI_SCALE, readUIScale, writeUIScale, true)
end

function SettingsModel:addResolutionScaleSetting()
	local function readResolutionScale()
		return SettingsModel.getScalingStateFromResolutionScaling(getResolutionScaling())
	end

	local function writeResolutionScale(value)
		setResolutionScaling(SettingsModel.getScalingFromResolutionScalingState(value))
		onProfileUiResolutionScalingChanged()
	end

	self:addSetting(SettingsModel.SETTING.RESOLUTION_SCALE, readResolutionScale, writeResolutionScale)
end

function SettingsModel:addCameraSensitivitySetting()
	local function readSensitivity()
		return Utils.getStateFromValues(self.cameraSensitivityValues, self.cameraSensitivityStep, self.gameSettings:getValue(SettingsModel.SETTING.CAMERA_SENSITIVITY))
	end

	local function writeSensitivity(value)
		self.gameSettings:setValue(SettingsModel.SETTING.CAMERA_SENSITIVITY, self.cameraSensitivityValues[value])
	end

	self:addSetting(SettingsModel.SETTING.CAMERA_SENSITIVITY, readSensitivity, writeSensitivity, true)
end

function SettingsModel:addVehicleArmSensitivitySetting()
	local function readSensitivity()
		return Utils.getStateFromValues(self.vehicleArmSensitivityValues, self.vehicleArmSensitivityStep, self.gameSettings:getValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY))
	end

	local function writeSensitivity(value)
		self.gameSettings:setValue(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, self.vehicleArmSensitivityValues[value])
	end

	self:addSetting(SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY, readSensitivity, writeSensitivity)
end

function SettingsModel:addMasterVolumeSetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_MASTER))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.soundMixer:setMasterVolume(volume)
		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_MASTER, volume)
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_MASTER, readVolume, writeVolume, true)
end

function SettingsModel:addMusicVolumeSetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, volume)
		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_MUSIC, volume)
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_MUSIC, readVolume, writeVolume, true)
end

function SettingsModel:addEnvironmentVolumeSetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, volume)
		self.soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, volume)

		if GS_IS_MOBILE_VERSION then
			g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.DEFAULT, volume)
		end
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_ENVIRONMENT, readVolume, writeVolume, true)
end

function SettingsModel:addVehicleVolumeSetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, volume)
		self.soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, volume)
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_VEHICLE, readVolume, writeVolume, true)
end

function SettingsModel:addRadioVolumeSetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_RADIO))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_RADIO, volume)
		self.soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, volume)
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_RADIO, readVolume, writeVolume, true)
end

function SettingsModel:addVolumeGUISetting()
	local function readVolume()
		return Utils.getMasterVolumeIndex(self.gameSettings:getValue(SettingsModel.SETTING.VOLUME_GUI))
	end

	local function writeVolume(value)
		local volume = Utils.getMasterVolumeFromIndex(value)

		self.gameSettings:setValue(SettingsModel.SETTING.VOLUME_GUI, volume)
		self.soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, volume)
	end

	self:addSetting(SettingsModel.SETTING.VOLUME_GUI, readVolume, writeVolume, true)
end

function SettingsModel:addSteeringBackSpeedSetting()
	local function readSpeed()
		return Utils.getStateFromValues(self.steeringBackSpeedValues, self.steeringBackSpeedStep, self.gameSettings:getValue(SettingsModel.SETTING.STEERING_BACK_SPEED))
	end

	local function writeSpeed(value)
		self.gameSettings:setValue(SettingsModel.SETTING.STEERING_BACK_SPEED, self.steeringBackSpeedValues[value])
	end

	self:addSetting(SettingsModel.SETTING.STEERING_BACK_SPEED, readSpeed, writeSpeed)
end

function SettingsModel:addSteeringSensitivitySetting()
	local function readSpeed()
		return Utils.getStateFromValues(self.steeringSensitivityValues, self.steeringSensitivityStep, self.gameSettings:getValue(SettingsModel.SETTING.STEERING_SENSITIVITY))
	end

	local function writeSpeed(value)
		self.gameSettings:setValue(SettingsModel.SETTING.STEERING_SENSITIVITY, self.steeringSensitivityValues[value])
	end

	self:addSetting(SettingsModel.SETTING.STEERING_SENSITIVITY, readSpeed, writeSpeed)
end

function SettingsModel:addGyroscopeSteeringSetting()
	local function read()
		return self.gameSettings:getValue(SettingsModel.SETTING.GYROSCOPE_STEERING)
	end

	local function write(value)
		self.gameSettings:setValue(SettingsModel.SETTING.GYROSCOPE_STEERING, value)
	end

	self:addSetting(SettingsModel.SETTING.GYROSCOPE_STEERING, read, write)
end

function SettingsModel:addHintsSetting()
	local function read()
		return self.gameSettings:getValue(SettingsModel.SETTING.HINTS)
	end

	local function write(value)
		self.gameSettings:setValue(SettingsModel.SETTING.HINTS, value)
	end

	self:addSetting(SettingsModel.SETTING.HINTS, read, write)
end

function SettingsModel:addCameraTiltingSetting()
	local function read()
		return self.gameSettings:getValue(SettingsModel.SETTING.CAMERA_TILTING)
	end

	local function write(value)
		self.gameSettings:setValue(SettingsModel.SETTING.CAMERA_TILTING, value)
	end

	self:addSetting(SettingsModel.SETTING.CAMERA_TILTING, read, write)
end

function SettingsModel.getVSyncByIndex(index)
	if index == 1 then
		return false
	end

	return true
end

function SettingsModel.getVSyncIndex(vSync)
	if not vSync then
		return 1
	end

	return 2
end

function SettingsModel.getShadowQualityIndex(shadowQuality, hasShadowFocusBox)
	if shadowQuality == 1 then
		return 2
	end

	if shadowQuality == 2 and hasShadowFocusBox == false then
		return 3
	end

	if shadowQuality == 2 and hasShadowFocusBox == true then
		return 4
	end

	return 1
end

function SettingsModel.getShadowQualityByIndex(shadowIndex)
	if shadowIndex == 2 then
		return 1
	end

	if shadowIndex == 3 then
		return 2
	end

	if shadowIndex == 4 then
		return 2
	end

	return 0
end

function SettingsModel.getHasShadowFocusBoxByIndex(shadowIndex)
	if shadowIndex == 2 then
		return false
	end

	if shadowIndex == 3 then
		return false
	end

	if shadowIndex == 4 then
		return true
	end

	return false
end

function SettingsModel.getShaderQualityIndex(shaderQuality)
	if shaderQuality == 1 then
		return 2
	end

	if shaderQuality == 2 then
		return 3
	end

	if shaderQuality == 3 then
		return 4
	end

	return 1
end

function SettingsModel.getShaderQualityByIndex(shaderIndex)
	if shaderIndex == 2 then
		return 1
	end

	if shaderIndex == 3 then
		return 2
	end

	if shaderIndex == 4 then
		return 3
	end

	return 0
end

function SettingsModel.getShadowMapFilterIndex(shadowFilter)
	if shadowFilter == 16 then
		return 2
	end

	return 1
end

function SettingsModel.getShadowMapFilterByIndex(shadowFilterIndex)
	if shadowFilterIndex == 2 then
		return 16
	end

	return 4
end

function SettingsModel.getTerrainQualityIndex(hasNormalMapping)
	if hasNormalMapping then
		return 2
	end

	return 1
end

function SettingsModel.getTerrainQualityByIndex(qualityIndex)
	if qualityIndex == 2 then
		return true
	end

	return false
end

function SettingsModel.getTextureFilteringIndex(isTrilinear, anisoValue)
	local filterIndex = 1

	if isTrilinear and anisoValue == 0 then
		filterIndex = 2
	end

	if isTrilinear and anisoValue == 1 then
		filterIndex = 3
	end

	if isTrilinear and anisoValue == 2 then
		filterIndex = 4
	end

	if isTrilinear and anisoValue == 4 then
		filterIndex = 5
	end

	if isTrilinear and anisoValue == 8 then
		filterIndex = 6
	end

	if isTrilinear and anisoValue == 16 then
		filterIndex = 7
	end

	return filterIndex
end

function SettingsModel.getTextureFilteringByIndex(filteringIndex)
	if filteringIndex == 2 then
		return true, 0
	end

	if filteringIndex == 3 then
		return true, 1
	end

	if filteringIndex == 4 then
		return true, 2
	end

	if filteringIndex == 5 then
		return true, 4
	end

	if filteringIndex == 6 then
		return true, 8
	end

	if filteringIndex == 7 then
		return true, 16
	end

	return false, 0
end

function SettingsModel.getTextureResolutionIndex(textureResolution)
	if textureResolution == 0 then
		return 2
	end

	return 1
end

function SettingsModel.getTextureResolutionByIndex(textureResolutionIndex)
	if textureResolutionIndex == 2 then
		return 0
	end

	return 1
end

function SettingsModel.getMSAAIndex(msaa)
	local currentMSAAIndex = 1

	if msaa == 2 then
		currentMSAAIndex = 2
	end

	if msaa == 4 then
		currentMSAAIndex = 3
	end

	if msaa == 8 then
		currentMSAAIndex = 4
	end

	return currentMSAAIndex
end

function SettingsModel.getMSAAFromIndex(msaaIndex)
	local currentMSAA = 1

	if msaaIndex == 2 then
		currentMSAA = 2
	end

	if msaaIndex == 3 then
		currentMSAA = 4
	end

	if msaaIndex == 4 then
		currentMSAA = 8
	end

	return currentMSAA
end

function SettingsModel.getNumOfReflectionMapsByIndex(index)
	return MathUtil.clamp(index - 1, 0, 7)
end

function SettingsModel.getNumOfReflectionMapsIndex(numOfReflectionMaps)
	return MathUtil.clamp(numOfReflectionMaps, 0, 7) + 1
end

function SettingsModel.getVolumeMeshTessellationCoeff()
	return 0.5 + 2 - getVolumeMeshTessellationCoeff()
end

function SettingsModel.setVolumeMeshTessellationCoeff(coeff)
	setVolumeMeshTessellationCoeff(2 + 0.5 - coeff)
end

function SettingsModel.getConsoleResolutionStateFromMode(mode)
	local resState = 1
	local qualityState = 1

	if mode == "1080p+" then
		resState = 1
		qualityState = 2
	elseif mode == "1440p" then
		resState = 2
		qualityState = 1
	elseif mode == "2160p" then
		resState = 3
		qualityState = 1
	end

	return resState, qualityState
end

function SettingsModel.getModeFromResolutionState(displayResolution, renderQuality)
	if displayResolution == 1 then
		if renderQuality == 2 then
			return "1080p+"
		end
	elseif displayResolution == 2 then
		return "1440p"
	elseif displayResolution == 3 then
		return "2160p"
	end

	return "1080p"
end

function SettingsModel.getScalingFromResolutionScalingState(state)
	return 0.4 + 0.1 * state
end

function SettingsModel.getScalingStateFromResolutionScaling(scaling)
	return math.floor((scaling - 0.4) * 10)
end
