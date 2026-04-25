InGameMenuGeneralSettingsFrame = {}
local InGameMenuGeneralSettingsFrame_mt = Class(InGameMenuGeneralSettingsFrame, TabbedMenuFrameElement)
InGameMenuGeneralSettingsFrame.CONTROLS = {
	CHECKBOX_IS_RADIO_ACTIVE = "checkIsRadioActive",
	OPTION_MONEY_UNIT = "multiMoneyUnit",
	CHECKBOX_USE_EASY_ARM_CONTROLER = "checkUseEasyArmControl",
	CHECKBOX_USE_WORLD_CAMERA = "checkUseWorldCamera",
	CHECKBOX_HELP_ICONS = "checkHelpIcons",
	CHECKBOX_SHOW_FIELD_INFO = "checkShowFieldInfo",
	CHECKBOX_SHOW_TRIGGER_MARKER = "checkShowTriggerMarker",
	CHECKBOX_AUTO_HELP = "checkAutoHelp",
	OPTION_VOLUME_RADIO = "multiRadioVolume",
	CHECKBOX_USE_MILES = "checkUseMiles",
	BUTTON_NATIVE_HELP = "buttonNativeHelp",
	CHECKBOX_INVERT_Y_LOOK = "checkInvertYLook",
	OPTION_STEERING_SENSITIVITY = "multiSteeringSensitivity",
	OPTION_VOLUME_VEHICLE = "multiVehicleVolume",
	CHECKBOX_COLORBLIND_MODE = "checkColorBlindMode",
	OPTION_VOLUME_MASTER = "multiMasterVolume",
	CHECKBOX_USE_ACRE = "checkUseAcre",
	OPTION_VEHICLE_ARM_SENSITIVITY = "multiVehicleArmSensitivity",
	CHECKBOX_RESET_CAMERA = "checkResetCamera",
	CHECKBOX_IS_TRAIN_TABBABLE = "checkIsTrainTabbable",
	OPTION_STEERING_BACK_SPEED = "multiSteeringBackSpeed",
	HELP_BOX = "generalSettingsHelpBox",
	OPTION_VOLUME_GUI = "multiVolumeGUI",
	OPTION_INPUT_HELP_MODE = "multiInputHelpMode",
	HELP_BOX_TEXT = "generalSettingsHelpBoxText",
	SETTINGS_CONTAINER = "settingsContainer",
	BOX_LAYOUT = "boxLayout",
	CHECKBOX_IS_RADIO_VEHICLE_ONLY = "checkIsRadioVehicleOnly",
	OPTION_VOLUME_ENVIRONMENT = "multiEnvironmentVolume",
	OPTION_CAMERA_SENSITIVITY = "multiCameraSensitivity"
}

function InGameMenuGeneralSettingsFrame:new(subclass_mt, settingsModel)
	local subclass_mt = subclass_mt or InGameMenuGeneralSettingsFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuGeneralSettingsFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.checkboxMapping = {}
	self.optionMapping = {}

	return self
end

function InGameMenuGeneralSettingsFrame:copyAttributes(src)
	InGameMenuGeneralSettingsFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
end

function InGameMenuGeneralSettingsFrame:initialize()
	self.checkboxMapping[self.checkAutoHelp] = SettingsModel.SETTING.SHOW_HELP_MENU
	self.checkboxMapping[self.checkHelpIcons] = SettingsModel.SETTING.SHOW_HELP_ICONS
	self.checkboxMapping[self.checkColorBlindMode] = SettingsModel.SETTING.USE_COLORBLIND_MODE
	self.checkboxMapping[self.checkUseMiles] = SettingsModel.SETTING.USE_MILES
	self.checkboxMapping[self.checkUseAcre] = SettingsModel.SETTING.USE_ACRE
	self.checkboxMapping[self.checkShowTriggerMarker] = SettingsModel.SETTING.SHOW_TRIGGER_MARKER
	self.checkboxMapping[self.checkShowFieldInfo] = SettingsModel.SETTING.SHOW_FIELD_INFO
	self.checkboxMapping[self.checkIsRadioVehicleOnly] = SettingsModel.SETTING.RADIO_VEHICLE_ONLY
	self.checkboxMapping[self.checkIsRadioActive] = SettingsModel.SETTING.RADIO_IS_ACTIVE
	self.checkboxMapping[self.checkResetCamera] = SettingsModel.SETTING.RESET_CAMERA
	self.checkboxMapping[self.checkUseWorldCamera] = SettingsModel.SETTING.USE_WORLD_CAMERA
	self.checkboxMapping[self.checkInvertYLook] = SettingsModel.SETTING.INVERT_Y_LOOK
	self.checkboxMapping[self.checkUseEasyArmControl] = SettingsModel.SETTING.EASY_ARM_CONTROL
	self.checkboxMapping[self.checkIsTrainTabbable] = SettingsModel.SETTING.IS_TRAIN_TABBABLE

	self.checkUseMiles:setTexts(self.settingsModel:getDistanceUnitTexts())
	self.checkUseAcre:setTexts(self.settingsModel:getAreaUnitTexts())
	self.checkIsRadioVehicleOnly:setTexts(self.settingsModel:getRadioModeTexts())

	self.optionMapping[self.multiMoneyUnit] = SettingsModel.SETTING.MONEY_UNIT
	self.optionMapping[self.multiCameraSensitivity] = SettingsModel.SETTING.CAMERA_SENSITIVITY
	self.optionMapping[self.multiVehicleArmSensitivity] = SettingsModel.SETTING.VEHICLE_ARM_SENSITIVITY
	self.optionMapping[self.multiSteeringBackSpeed] = SettingsModel.SETTING.STEERING_BACK_SPEED
	self.optionMapping[self.multiSteeringSensitivity] = SettingsModel.SETTING.STEERING_SENSITIVITY
	self.optionMapping[self.multiMasterVolume] = SettingsModel.SETTING.VOLUME_MASTER
	self.optionMapping[self.multiVehicleVolume] = SettingsModel.SETTING.VOLUME_VEHICLE
	self.optionMapping[self.multiEnvironmentVolume] = SettingsModel.SETTING.VOLUME_ENVIRONMENT
	self.optionMapping[self.multiRadioVolume] = SettingsModel.SETTING.VOLUME_RADIO
	self.optionMapping[self.multiVolumeGUI] = SettingsModel.SETTING.VOLUME_GUI
	self.optionMapping[self.multiInputHelpMode] = SettingsModel.SETTING.INPUT_HELP_MODE

	self.multiMoneyUnit:setTexts(self.settingsModel:getMoneyUnitTexts())
	self.multiCameraSensitivity:setTexts(self.settingsModel:getCameraSensitivityTexts())
	self.multiVehicleArmSensitivity:setTexts(self.settingsModel:getVehicleArmSensitivityTexts())
	self.multiSteeringBackSpeed:setTexts(self.settingsModel:getSteeringBackSpeedTexts())
	self.multiSteeringSensitivity:setTexts(self.settingsModel:getSteeringSensitivityTexts())
	self.multiMasterVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiVehicleVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiEnvironmentVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiRadioVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiVolumeGUI:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiInputHelpMode:setTexts(self.settingsModel:getInputHelpModeTexts())

	if GS_IS_CONSOLE_VERSION then
		self.multiInputHelpMode:setVisible(false)
		self.multiSteeringBackSpeed:setVisible(false)
	end

	local needNativeHelpButton = GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE

	self.buttonNativeHelp:setVisible(needNativeHelpButton)

	if needNativeHelpButton then
		self.boxLayout.wrapAround = false
		local firstSettingElement = self.boxLayout.elements[1]
		local lastSettingElement = self.boxLayout.elements[#self.boxLayout.elements]

		FocusManager:linkElements(lastSettingElement, FocusManager.BOTTOM, self.buttonNativeHelp)
		FocusManager:linkElements(self.buttonNativeHelp, FocusManager.BOTTOM, firstSettingElement)
		FocusManager:linkElements(firstSettingElement, FocusManager.TOP, self.buttonNativeHelp)
		FocusManager:linkElements(self.buttonNativeHelp, FocusManager.TOP, lastSettingElement)
	end
end

function InGameMenuGeneralSettingsFrame:onFrameOpen(element)
	InGameMenuGeneralSettingsFrame:superClass().onFrameOpen(self)
	self:updateGeneralSettings()

	if g_currentMission.missionDynamicInfo.isMultiplayer then
		self.checkIsTrainTabbable:setVisible(false)
	else
		self.checkIsTrainTabbable:setVisible(true)
	end

	self.boxLayout:invalidateLayout()
	FocusManager:setFocus(self.boxLayout)
end

function InGameMenuGeneralSettingsFrame:onFrameClose()
	InGameMenuGeneralSettingsFrame:superClass().onFrameClose(self)
	self.settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS)
end

function InGameMenuGeneralSettingsFrame:updateGeneralSettings()
	self.settingsModel:refresh()

	for element, settingsKey in pairs(self.checkboxMapping) do
		element:setIsChecked(self.settingsModel:getValue(settingsKey))
	end

	for element, settingsKey in pairs(self.optionMapping) do
		element:setState(self.settingsModel:getValue(settingsKey))
	end
end

function InGameMenuGeneralSettingsFrame:updateToolTipBoxVisibility()
	local hasText = self.generalSettingsHelpBoxText.text ~= nil and self.generalSettingsHelpBoxText.text ~= ""

	self.generalSettingsHelpBox:setVisible(hasText)
end

function InGameMenuGeneralSettingsFrame:getMainElementSize()
	return self.settingsContainer.size
end

function InGameMenuGeneralSettingsFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function InGameMenuGeneralSettingsFrame:onClickCheckbox(state, checkboxElement)
	local settingsKey = self.checkboxMapping[checkboxElement]

	if settingsKey ~= nil then
		self.settingsModel:setValue(settingsKey, state == CheckedOptionElement.STATE_CHECKED)
		self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)

		self.dirty = true
	else
		print("Warning: Invalid settings checkbox event or key configuration for element " .. checkboxElement:toString())
	end
end

function InGameMenuGeneralSettingsFrame:onClickMultiOption(state, optionElement)
	local settingsKey = self.optionMapping[optionElement]

	if settingsKey ~= nil then
		self.settingsModel:setValue(settingsKey, state)
		self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)

		self.dirty = true
	else
		print("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
	end
end

function InGameMenuGeneralSettingsFrame:onClickNativeHelp()
	openNativeHelpMenu()
end

function InGameMenuGeneralSettingsFrame:onToolTipBoxTextChanged(element, text)
	self:updateToolTipBoxVisibility()
end
