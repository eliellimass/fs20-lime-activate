SettingsDisplayFrame = {}
local SettingsDisplayFrame_mt = Class(SettingsDisplayFrame, TabbedMenuFrameElement)
SettingsDisplayFrame.CONTROLS = {
	FOV_Y = "fovYElement",
	UI_SCALE = "uiScaleElement",
	WINDOW_MODE = "windowModeElement",
	ELEMENT_PERFORMANCE_CLASS = "performanceClassElement",
	BRIGHTNESS = "brightnessElement",
	V_SYNC = "vSyncElement",
	RESOLUTION = "resolutionElement",
	RESOLUTION_SCALE = "resolutionScaleElement",
	MAIN_CONTAINER = "settingsContainer"
}

function SettingsDisplayFrame:new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement:new(target, custom_mt or SettingsDisplayFrame_mt)

	self:registerControls(SettingsDisplayFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true

	return self
end

function SettingsDisplayFrame:copyAttributes(src)
	SettingsDisplayFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsDisplayFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}
	self.advancedButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_ADVANCED),
		callback = function ()
			self:onClickAdvancedButton()
		end
	}
end

function SettingsDisplayFrame:setOpenAdvancedSettingsCallback(itemSelectedCallback)
	self.notifyAdvancedSettingsButton = itemSelectedCallback or NO_CALLBACK
end

function SettingsDisplayFrame:onApplySettings()
	local needsRestart = self.settingsModel:needsRestartToApplyChanges()

	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		restartApplication("")
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsDisplayFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.advancedButtonInfo)

	return buttons
end

function SettingsDisplayFrame:updateValues()
	self:updatePerformanceClass()
	self.performanceClassElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.windowModeElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.WINDOW_MODE))
	self.resolutionElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.RESOLUTION) + 1)
	self.vSyncElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.V_SYNC))
	self.brightnessElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
	self.fovYElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
	self.uiScaleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
	self.resolutionScaleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onFrameOpen()
	self:updateValues()
end

function SettingsDisplayFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsDisplayFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function SettingsDisplayFrame:updatePerformanceClass()
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	self.performanceClassElement:setTexts(texts)
end

function SettingsDisplayFrame:onCreatePerformanceClass(element)
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	element:setTexts(texts)
end

function SettingsDisplayFrame:onCreateResolution(element)
	element:setTexts(self.settingsModel:getResolutionTexts())
end

function SettingsDisplayFrame:onCreateBrightness(element)
	element:setTexts(self.settingsModel:getBrightnessTexts())
end

function SettingsDisplayFrame:onCreateFovY(element)
	element:setTexts(self.settingsModel:getFovYTexts())
end

function SettingsDisplayFrame:onCreateUIScale(element)
	element:setTexts(self.settingsModel:getUiScaleTexts())
end

function SettingsDisplayFrame:onCreateResolutioncale(element)
	element:setTexts(self.settingsModel:getResolutionScaleTexts())
end

function SettingsDisplayFrame:onClickPerformanceClass(state)
	self.settingsModel:applyPerformanceClass(state)
	self:updateValues()
end

function SettingsDisplayFrame:onClickResolution(state)
	self.settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickFovY(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickBrightness(state)
	self.settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickWindowMode(state)
	self.settingsModel:setValue(SettingsModel.SETTING.WINDOW_MODE, self.windowModeElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickVSync(state)
	self.settingsModel:setValue(SettingsModel.SETTING.V_SYNC, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickUIScale(state)
	self.settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickAdvancedButton()
	self.notifyAdvancedSettingsButton()
end

function SettingsDisplayFrame:onClickResolutionScale(state)
	self.settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
	self:setMenuButtonInfoDirty()
end

SettingsDisplayFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply",
	BUTTON_ADVANCED = "setting_advanced"
}
