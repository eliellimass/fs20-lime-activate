InGameMenuGameSettingsFrame = {}
local InGameMenuGameSettingsFrame_mt = Class(InGameMenuGameSettingsFrame, TabbedMenuFrameElement)
InGameMenuGameSettingsFrame.CONTROLS = {
	CHECKBOX_DIRT = "checkDirt",
	CHECKBOX_HELPER_REFILL_SLURRY = "checkHelperRefillSlurry",
	OPTION_TIME_SCALE = "multiTimeScale",
	CHECKBOX_PLOWING_REQUIRED = "checkPlowingRequired",
	CHECKBOX_HELPER_REFILL_MANURE = "checkHelperRefillManure",
	CHECKBOX_HELPER_REFILL_FUEL = "checkHelperRefillFuel",
	CHECKBOX_HELPER_REFILL_FERTILIZER = "checkHelperRefillFertilizer",
	CHECKBOX_AUTO_MOTOR_START = "checkAutoMotorStart",
	CHECKBOX_STOP_AND_GO_BRAKING = "checkStopAndGoBraking",
	CHECKBOX_FRUIT_DESTRUCTION = "checkFruitDestruction",
	CHECKBOX_WEEDS_ENABLED = "checkWeedsEnabled",
	HELP_BOX = "gameSettingsHelpBox",
	TEXT_SAVEGAME_NAME = "textSavegameName",
	OPTION_AUTO_SAVE_INTERVAL = "multiAutoSaveInterval",
	CHECKBOX_HELPER_REFILL_SEED = "checkHelperRefillSeed",
	CHECKBOX_TRAFFIC = "checkTraffic",
	CHECKBOX_PLANT_GROWTH_RATE = "checkPlantGrowthRate",
	CHECKBOX_FUEL_USAGE = "checkFuelUsage",
	BUTTON_PAUSE = "buttonPauseGame",
	CHECKBOX_PLANT_WITHERING = "checkPlantWithering",
	CHECKBOX_LIME_REQUIRED = "checkLimeRequired",
	HELP_BOX_TEXT = "gameSettingsHelpBoxText",
	SETTINGS_CONTAINER = "settingsContainer",
	BOX_LAYOUT = "boxLayout",
	OPTION_ECONOMIC_DIFFICULTY = "economicDifficulty"
}

local function NO_CALLBACK()
end

function InGameMenuGameSettingsFrame:new(subclass_mt, l10n)
	local subclass_mt = subclass_mt or InGameMenuGameSettingsFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuGameSettingsFrame.CONTROLS)

	self.l10n = l10n
	self.pageMapOverview = nil
	self.missionInfo = nil
	self.manureHeaps = {}
	self.liquidManureTriggers = {}
	self.hasMasterRights = false
	self.hasCustomMenuButtons = true

	return self
end

function InGameMenuGameSettingsFrame:copyAttributes(src)
	InGameMenuGameSettingsFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
end

function InGameMenuGameSettingsFrame:initialize(pageMapOverview, onClickBackCallback)
	self.pageMapOverview = pageMapOverview

	self:assignStaticTexts()

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.saveButton = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_ACTIVATE
	}
	self.quitButton = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_CANCEL
	}
	self.serverSettingsButton = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText("button_serverSettings"),
		callback = function ()
			self:onButtonOpenServerSettings()
		end
	}

	self:updateButtons()

	self.boxLayout.wrapAround = false
	local firstSettingElement = self.boxLayout.elements[1]
	local lastSettingElement = self.boxLayout.elements[#self.boxLayout.elements]
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK

	FocusManager:linkElements(lastSettingElement, FocusManager.BOTTOM, self.buttonPauseGame)
	FocusManager:linkElements(self.buttonPauseGame, FocusManager.BOTTOM, firstSettingElement)
	FocusManager:linkElements(firstSettingElement, FocusManager.TOP, self.buttonPauseGame)
	FocusManager:linkElements(self.buttonPauseGame, FocusManager.TOP, lastSettingElement)
end

function InGameMenuGameSettingsFrame:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function InGameMenuGameSettingsFrame:setManureTriggers(manureHeaps, liquidManureTriggers)
	self.manureHeaps = manureHeaps
	self.liquidManureTriggers = liquidManureTriggers
end

function InGameMenuGameSettingsFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights

	if g_currentMission ~= nil then
		self:updateButtons()
	end
end

function InGameMenuGameSettingsFrame:onFrameOpen(element)
	InGameMenuGameSettingsFrame:superClass().onFrameOpen(self)
	self:assignDynamicTexts()
	self:updateGameSettings()
	self:updatePauseButtonState()
	FocusManager:setFocus(self.multiTimeScale)
end

function InGameMenuGameSettingsFrame:updateButtons()
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.saveButton,
		self.quitButton
	}

	if self.hasMasterRights and g_currentMission.missionDynamicInfo.isMultiplayer then
		table.insert(self.menuButtonInfo, self.serverSettingsButton)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuGameSettingsFrame:updateGameSettings()
	self.savegameName = self.missionInfo.savegameName

	self.textSavegameName:setText(self.missionInfo.savegameName)
	self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
	self.economicDifficulty:setState(self.missionInfo.economicDifficulty)
	self.checkPlantGrowthRate:setState(self.missionInfo.plantGrowthRate)
	self.checkPlantWithering:setIsChecked(self.missionInfo.isPlantWitheringEnabled)
	self.checkFruitDestruction:setIsChecked(self.missionInfo.fruitDestruction)
	self.checkPlowingRequired:setIsChecked(self.missionInfo.plowingRequiredEnabled)
	self.checkLimeRequired:setIsChecked(self.missionInfo.limeRequired)
	self.checkWeedsEnabled:setIsChecked(self.missionInfo.weedsEnabled)
	self.multiAutoSaveInterval:setState(g_autoSaveManager:getIndexFromInterval(g_autoSaveManager:getInterval()))
	self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled)
	self.checkDirt:setState(self.missionInfo.dirtInterval)
	self.checkAutoMotorStart:setIsChecked(self.missionInfo.automaticMotorStartEnabled)
	self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel)
	self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds)
	self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer)
	self.checkFuelUsage:setIsChecked(not self.missionInfo.fuelUsageLow)
	self.checkStopAndGoBraking:setIsChecked(self.missionInfo.stopAndGoBraking)
	self.checkHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
	self.checkHelperRefillManure:setState(self.missionInfo.helperManureSource)
	self.textSavegameName:setDisabled(not self.hasMasterRights)
	self.multiTimeScale:setDisabled(not self.hasMasterRights)
	self.economicDifficulty:setDisabled(not self.hasMasterRights)
	self.checkPlantGrowthRate:setDisabled(not self.hasMasterRights or self.plantGrowthRateIsLocked)
	self.checkPlantWithering:setDisabled(not self.hasMasterRights)
	self.checkFruitDestruction:setDisabled(not self.hasMasterRights)
	self.checkPlowingRequired:setDisabled(not self.hasMasterRights)
	self.checkLimeRequired:setDisabled(not self.hasMasterRights)
	self.checkWeedsEnabled:setDisabled(not self.hasMasterRights)
	self.checkDirt:setDisabled(not self.hasMasterRights)
	self.multiAutoSaveInterval:setDisabled(not g_currentMission:getIsServer())
	self.multiAutoSaveInterval:setVisible(g_currentMission:getIsServer())
end

function InGameMenuGameSettingsFrame:updatePauseButtonState()
	if g_currentMission.paused then
		self.buttonPauseGame:applyProfile(InGameMenuGameSettingsFrame.PROFILE.BUTTON_UNPAUSE)
		self.buttonPauseGame:setText(self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.UNPAUSE))
	else
		self.buttonPauseGame:applyProfile(InGameMenuGameSettingsFrame.PROFILE.BUTTON_PAUSE)
		self.buttonPauseGame:setText(self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.PAUSE))
	end
end

function InGameMenuGameSettingsFrame:assignStaticTexts()
	self:assignTimeScaleTexts()
	self:assignEconomicDifficultyTexts()
	self:assignDirtTexts()
	self:assignPlantGrowthTexts()
	self:assignAutoSaveTexts()
	self.checkFuelUsage:setTexts({
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.USAGE_LOW),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.USAGE_DEFAULT)
	})

	local helperTexts = {
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.BUY)
	}

	self.checkHelperRefillFuel:setTexts(helperTexts)
	self.checkHelperRefillSeed:setTexts(helperTexts)
	self.checkHelperRefillFertilizer:setTexts(helperTexts)
end

function InGameMenuGameSettingsFrame:assignTimeScaleTexts()
	local timeScaleTable = {}
	local numTimeScales = Utils.getNumTimeScales()

	for i = 1, numTimeScales do
		table.insert(timeScaleTable, Utils.getTimeScaleString(i))
	end

	self.multiTimeScale:setTexts(timeScaleTable)
end

function InGameMenuGameSettingsFrame:assignEconomicDifficultyTexts()
	local economicDifficultyTable = {}

	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_EASY))
	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_NORMAL))
	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_HARD))
	self.economicDifficulty:setTexts(economicDifficultyTable)
end

function InGameMenuGameSettingsFrame:assignDirtTexts()
	local textTable = {}

	table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF))

	for i = 1, 3 do
		table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.GROWTH_RATE_TEMPLATE .. i))
	end

	self.checkDirt:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:assignPlantGrowthTexts()
	local textTable = {}

	table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF))

	for i = 1, 3 do
		table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.GROWTH_RATE_TEMPLATE .. i))
	end

	self.checkPlantGrowthRate:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:assignAutoSaveTexts()
	local textTable = {}

	for _, interval in ipairs(g_autoSaveManager:getIntervalOptions()) do
		if interval > 0 then
			table.insert(textTable, interval .. " " .. self.l10n:getText("unit_minutesShort"))
		else
			table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF))
		end
	end

	self.multiAutoSaveInterval:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:assignDynamicTexts()
	local helperTexts = {
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.BUY)
	}
	local textTable = {}

	table.insert(textTable, helperTexts[1])
	table.insert(textTable, helperTexts[2])

	for i = 1, #self.manureHeaps do
		if g_currentMission.accessHandler:canPlayerAccess(self.manureHeaps[i].manureHeap.owner) then
			local text = self.manureHeaps[i].name

			if text:sub(1, 6) == InGameMenuGameSettingsFrame.L10N_SYMBOL.SUBSTITUTION_PREFIX then
				text = self.l10n:getText(text:sub(7), self.missionInfo.customEnvironment)
			end

			table.insert(textTable, text)
		end
	end

	self.checkHelperRefillManure:setTexts(textTable)

	textTable = {}

	table.insert(textTable, helperTexts[1])
	table.insert(textTable, helperTexts[2])

	for i = 1, #self.liquidManureTriggers do
		if g_currentMission.accessHandler:canPlayerAccess(self.liquidManureTriggers[i].silo.owner) then
			local text = self.liquidManureTriggers[i].name

			if text:sub(1, 6) == InGameMenuGameSettingsFrame.L10N_SYMBOL.SUBSTITUTION_PREFIX then
				text = self.l10n:getText(text:sub(7), self.missionInfo.customEnvironment)
			end

			table.insert(textTable, text)
		end
	end

	self.checkHelperRefillSlurry:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:updateToolTipBoxVisibility()
	local hasText = self.gameSettingsHelpBoxText.text ~= nil and self.gameSettingsHelpBoxText.text ~= ""

	self.gameSettingsHelpBox:setVisible(hasText)
end

function InGameMenuGameSettingsFrame:getMainElementSize()
	return self.settingsContainer.size
end

function InGameMenuGameSettingsFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function InGameMenuGameSettingsFrame:onEnterPressedSavegameName()
	local newName = self.textSavegameName.text

	if newName ~= self.savegameName then
		if newName == "" then
			newName = g_i18n:getText("defaultSavegameName")

			self.textSavegameName:setText(newName)
		end

		self.missionInfo.savegameName = newName
		self.savegameName = newName

		SavegameSettingsEvent.sendEvent()
	end
end

function InGameMenuGameSettingsFrame:onClickTimeScale(state)
	if self.hasMasterRights then
		g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
	end
end

function InGameMenuGameSettingsFrame:onClickEconomicDifficulty(state)
	if self.hasMasterRights then
		g_currentMission:setEconomicDifficulty(state)
	end
end

function InGameMenuGameSettingsFrame:onClickTraffic(state)
	if self.hasMasterRights then
		g_currentMission:setTrafficEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickDirt(state)
	if self.hasMasterRights then
		g_currentMission:setDirtInterval(state)
	end
end

function InGameMenuGameSettingsFrame:onClickFuelUsage(state)
	if self.hasMasterRights then
		g_currentMission:setFuelUsageLow(state ~= CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillFuel(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFuel(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillSeed(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuySeeds(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillFertilizer(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFertilizer(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillSlurry(state)
	if self.hasMasterRights then
		g_currentMission:setHelperSlurrySource(state)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillManure(state)
	if self.hasMasterRights then
		g_currentMission:setHelperManureSource(state)
	end
end

function InGameMenuGameSettingsFrame:onClickAutomaticMotorStart(state)
	if self.hasMasterRights then
		g_currentMission:setAutomaticMotorStartEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickPlantGrowthRate(state)
	if self.hasMasterRights then
		g_currentMission:setPlantGrowthRate(state)
	end
end

function InGameMenuGameSettingsFrame:onClickPlantWithering(state)
	if self.hasMasterRights then
		g_currentMission:setPlantWitheringEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickFruitDestruction(state)
	if self.hasMasterRights then
		g_currentMission:setFruitDestructionEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickPlowingRequired(state)
	if self.hasMasterRights then
		g_currentMission:setPlowingRequiredEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickLimeRequired(state)
	if self.hasMasterRights then
		g_currentMission:setLimeRequired(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickWeedsEnabled(state)
	if self.hasMasterRights then
		g_currentMission:setWeedsEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickStopAndGoBraking(state)
	if self.hasMasterRights then
		g_currentMission:setStopAndGoBraking(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickAutoSaveInterval(state)
	if self.hasMasterRights then
		g_currentMission:setAutoSaveInterval(g_autoSaveManager:getIntervalFromIndex(state))
	end
end

function InGameMenuGameSettingsFrame:onClickPauseGame()
	self.pageMapOverview:notifyPause()

	if GS_IS_CONSOLE_VERSION then
		self.onClickBackCallback()
	end

	g_currentMission:setManualPause(not g_currentMission.manualPause)
	self:updatePauseButtonState()
end

function InGameMenuGameSettingsFrame:onToolTipBoxTextChanged(element, text)
	self:updateToolTipBoxVisibility()
end

function InGameMenuGameSettingsFrame:onButtonOpenServerSettings()
	g_gui:showServerSettingsDialog({})
end

InGameMenuGameSettingsFrame.PROFILE = {
	BUTTON_PAUSE = "ingameMenuSettingsPauseButton",
	BUTTON_UNPAUSE = "ingameMenuSettingsUnpauseButton"
}
InGameMenuGameSettingsFrame.L10N_SYMBOL = {
	UNPAUSE = "ui_unpause",
	BUY = "ui_buy",
	OFF = "ui_off",
	PAUSE = "input_PAUSE",
	USAGE_LOW = "setting_fuelUsageLow",
	USAGE_DEFAULT = "setting_fuelUsageDefault",
	DIFFICULTY_NORMAL = "button_normal",
	DIFFICULTY_HARD = "button_hard",
	SUBSTITUTION_PREFIX = "$l10n_",
	DIFFICULTY_EASY = "button_easy",
	GROWTH_RATE_TEMPLATE = "setting_plantGrowthRateState"
}
