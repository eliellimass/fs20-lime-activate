ModSelectionScreen = {
	CONTROLS = {
		SELECT_BUTTON = "buttonSelect",
		MOD_LIST = "modList",
		START_BUTTON = "buttonStart",
		SELECT_ALL_BUTTON = "buttonSelectAll",
		NO_MODS_DLCS_ELEMENT = "noModsDLCsElement",
		MOD_LIST_ITEM_TEMPLATE = "listItemTemplate"
	},
	LIST_TEMPLATE_ELEMENT_NAME = {
		ICON = "icon",
		TITLE = "title",
		HASH = "hash",
		VERSION = "version"
	}
}
local ModSelectionScreen_mt = Class(ModSelectionScreen, ScreenElement)

function ModSelectionScreen:new(target, customMt, startMissionInfo, l10n, isConsoleVersion)
	local self = ScreenElement:new(target, customMt or ModSelectionScreen_mt)

	self:registerControls(ModSelectionScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.isConsoleVersion = isConsoleVersion
	self.l10n = l10n
	self.currentSelectedItem = nil
	self.availableMods = {}
	self.addedMods = {}
	self.addedModsIcons = {}
	self.numAddedModsBesidesMap = 0

	return self
end

function ModSelectionScreen:onCreate(element)
	self.modList:removeElement(self.listItemTemplate)
end

function ModSelectionScreen:onCreateHashTitle(element)
	element:setVisible(not self.isConsoleVersion)
end

function ModSelectionScreen:onCreateTick(element)
	if self.currentItem ~= nil then
		self.addedModsIcons[self.currentItem] = element
	end
end

function ModSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end

function ModSelectionScreen:onOpen()
	ModSelectionScreen:superClass().onOpen(self)
	self:setSoundSuppressed(true)

	self.mapModName = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)

	self:setupList()

	if self.mapModName ~= nil then
		self:setItemState(g_modManager:getModByName(self.mapModName), true)
	end

	self:setSoundSuppressed(false)

	local defaultModSetting = true

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 and getModUseAvailability(false) ~= MultiplayerAvailability.AVAILABLE then
		defaultModSetting = false
	end

	if GS_IS_MOBILE_VERSION then
		defaultModSetting = false
	end

	if self.missionInfo.isValid then
		for _, modInfo in pairs(self.missionInfo.mods) do
			if modInfo.modName ~= self.mapModName then
				local modItem = g_modManager:getModByName(modInfo.modName)

				if modItem ~= nil and self:showModInList(modItem) then
					if modItem.isDLC then
						self:setItemState(modItem, true)
					else
						self:setItemState(modItem, defaultModSetting)
					end
				end
			end
		end
	else
		for _, modItem in pairs(self.availableMods) do
			if modItem.isDLC then
				self:setItemState(modItem, true)
			else
				self:setItemState(modItem, defaultModSetting)
			end
		end
	end

	if self.missionDynamicInfo.isMultiplayer then
		self.buttonStart:setText(self.l10n:getText(ModSelectionScreen.L10N.BUTTON_CONTINUE))
	else
		self.buttonStart:setText(self.l10n:getText(ModSelectionScreen.L10N.BUTTON_START))
	end

	if GS_IS_MOBILE_VERSION then
		self:onClickOk()
	end
end

function ModSelectionScreen:onClickCancel()
	if #self.availableMods > 0 then
		if self.numAddedModsBesidesMap > 0 then
			for _, modItem in pairs(self.addedMods) do
				self:setItemState(modItem, false)
			end
		else
			local numDlc = 0
			local numMod = 0

			for _, modItem in pairs(self.availableMods) do
				if modItem.isDLC then
					numDlc = numDlc + 1
				else
					numMod = numMod + 1
				end
			end

			if numMod > 0 and numDlc == 0 and not PlatformPrivilegeUtil.checkModUse(self.performSelectAll, self) then
				return
			end

			self:performSelectAll()
		end
	end
end

function ModSelectionScreen:performSelectAll()
	local modSetting = getModUseAvailability(false) == MultiplayerAvailability.AVAILABLE

	for _, modItem in pairs(self.availableMods) do
		if modItem.isDLC then
			self:setItemState(modItem, true)
		else
			self:setItemState(modItem, modSetting)
		end
	end
end

function ModSelectionScreen:selectCurrentMod()
	if not self.currentSelectedItem.isDLC and not PlatformPrivilegeUtil.checkModUse(self.selectCurrentMod, self) then
		return
	end

	self:setItemState(self.currentSelectedItem, not self:getIsModSelected(self.currentSelectedItem))
end

function ModSelectionScreen:onClickActivate()
	self.currentSelectedItem = self.availableMods[self.currentSelectedRow]

	self:selectCurrentMod()
end

function ModSelectionScreen:onClickOk()
	local mods = {}

	for _, modItem in pairs(self.addedMods) do
		table.insert(mods, modItem)
	end

	self.missionDynamicInfo.mods = mods

	g_careerScreen:startGame(self.missionInfo, self.missionDynamicInfo)
end

function ModSelectionScreen:onDoubleClick(selectedRow)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

	self.currentSelectedItem = self.availableMods[selectedRow]

	self:selectCurrentMod()
end

function ModSelectionScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer
end

function ModSelectionScreen:update(dt)
	ModSelectionScreen:superClass().update(self, dt)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 and self.missionDynamicInfo.isMultiplayer then
		if getModDownloadAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			self:changeScreen(MainScreen)

			return
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")

			return
		end
	end
end

function ModSelectionScreen:showModInList(mod)
	local showMod = not self.missionDynamicInfo.isMultiplayer or mod.isMultiplayerSupported and mod.fileHash ~= nil

	if showMod and not mod.isDLC and mod.modName ~= self.mapModName then
		for mapId, _ in pairs(g_mapManager.idToMap) do
			local modName = g_mapManager:getModNameFromMapId(mapId)

			if modName ~= nil and modName == mod.modName then
				showMod = false

				break
			end
		end
	end

	return showMod
end

function ModSelectionScreen:setupList()
	self.modList:deleteListItems()

	self.availableMods = {}
	self.addedMods = {}
	self.addedModsIcons = {}
	self.numAddedModsBesidesMap = 0
	local mods = g_modManager:getMods()

	table.sort(mods, function (a, b)
		return a.title < b.title
	end)

	for _, mod in ipairs(mods) do
		if self:showModInList(mod) then
			self.currentItem = mod

			table.insert(self.availableMods, self.currentItem)

			local newListItem = self.listItemTemplate:clone(self.modList)

			newListItem:updateAbsolutePosition()

			local titleElement = newListItem:getDescendantByName(ModSelectionScreen.LIST_TEMPLATE_ELEMENT_NAME.TITLE)

			titleElement:setText(mod.title)

			local versionElement = newListItem:getDescendantByName(ModSelectionScreen.LIST_TEMPLATE_ELEMENT_NAME.VERSION)

			versionElement:setText(mod.version)

			local iconElement = newListItem:getDescendantByName(ModSelectionScreen.LIST_TEMPLATE_ELEMENT_NAME.ICON)

			iconElement:setImageFilename(mod.iconFilename)
			self:setItemState(self.currentItem, false)

			self.currentItem = nil
		end
	end

	if #self.availableMods > 0 then
		self.modList:setSelectedIndex(1, true)
	end

	self.buttonSelectAll:setDisabled(#self.availableMods == 0)
	self.noModsDLCsElement:setVisible(#self.availableMods == 0)
end

function ModSelectionScreen:setItemState(item, isSelected)
	if item ~= nil then
		local isNotUsedMap = self.mapModName == nil or item.modName ~= self.mapModName

		if isSelected then
			if isNotUsedMap and self.addedMods[item] == nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap + 1
			end

			self.addedMods[item] = item

			self.addedModsIcons[item]:setVisible(true)
		elseif isNotUsedMap then
			if self.addedMods[item] ~= nil then
				self.numAddedModsBesidesMap = self.numAddedModsBesidesMap - 1
			end

			self.addedMods[item] = nil

			self.addedModsIcons[item]:setVisible(false)
		end
	end

	self:updateSelectButton()
end

function ModSelectionScreen:getIsModSelected(item)
	return self.addedMods[item] ~= nil
end

function ModSelectionScreen:onListSelectionChanged(selectedRow)
	if self.availableMods ~= nil then
		self.currentSelectedRow = selectedRow
		self.currentSelectedItem = self.availableMods[selectedRow]

		self:updateSelectButton()
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end
end

function ModSelectionScreen:updateSelectButton()
	if self.addedMods[self.currentSelectedItem] == nil then
		self.buttonSelect:setText(self.l10n:getText(ModSelectionScreen.L10N.SELECT))
	else
		self.buttonSelect:setText(self.l10n:getText(ModSelectionScreen.L10N.DESELECT))
	end

	if #self.availableMods > 0 then
		if self.numAddedModsBesidesMap > 0 then
			self.buttonSelectAll:setText(self.l10n:getText(ModSelectionScreen.L10N.DESELECT_ALL))
		else
			self.buttonSelectAll:setText(self.l10n:getText(ModSelectionScreen.L10N.SELECT_ALL))
		end
	end
end

ModSelectionScreen.L10N = {
	BUTTON_START = "button_start",
	ONLY_ZIP = "ui_onlyForZipFiles",
	DESELECT_ALL = "button_deselectAll",
	BUTTON_CONTINUE = "button_continue",
	SELECT = "button_select",
	DESELECT = "button_deselect",
	SELECT_ALL = "button_selectAll"
}
