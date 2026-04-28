MapSelectionScreen = {
	CONTROLS = {
		MAP_SELECTION_TITLE = "mapSelectionTitle",
		SELECTOR_LEFT_GP = "selectorLeftGamepad",
		MAP_SELECTION_TEXT = "mapSelectionText",
		MAP_SELECTOR = "mapSelector",
		SELECTOR_RIGHT_GP = "selectorRightGamepad",
		MAP_LIST = "mapList",
		MAP_LIST_ITEM_TEMPLATE = "listItemTemplate",
		SELECTION_STATE_BOX = "selectionStateBox"
	}
}
local MapSelectionScreen_mt = Class(MapSelectionScreen, ScreenElement)

function MapSelectionScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or MapSelectionScreen_mt)

	self:registerControls(MapSelectionScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.isMultiplayer = false
	self.selectedMapId = 0
	self.maps = {}

	return self
end

function MapSelectionScreen:onOpen()
	MapSelectionScreen:superClass().onOpen(self)
	self.mapList:deleteListItems()

	self.maps = {}
	local mapTexts = {}

	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)

		if not map.isModMap or not self.isMultiplayer or map.isMultiplayerSupported then
			table.insert(self.maps, map)
			table.insert(mapTexts, "title")

			local newListItem = self.listItemTemplate:clone(self.mapList)

			newListItem:setVisible(true)
			newListItem:updateAbsolutePosition()
		end
	end

	self.mapSelector:setMinValue(1)
	self.mapSelector:setMaxValue(#self.maps)

	if #self.maps > 0 then
		self:onSelectionChanged(1, true)
	end

	-- if GS_IS_MOBILE_VERSION then
	-- 	self:onClickOk()
	-- end
end

function MapSelectionScreen:onCreateMapImage(element)
	if #self.maps > 0 then
		self.createdMapImage = element

		element:setImageFilename(self.maps[#self.maps].iconFilename)
	end
end

function MapSelectionScreen:selectMap(mapId, isInitialSetting)
	self.selectedMapId = mapId
	local map = self.maps[mapId]

	if map then
		if not isInitialSetting then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
		end

		self.mapSelectionTitle:setText(map.title)
		self.mapSelectionText:setText(map.description)
	end
end

function MapSelectionScreen:onClickMapSelection(state)
	self.mapList:setSelectedIndex(state)
end

function MapSelectionScreen:onSelectionChanged(index, isInitialSetting)
	self:selectMap(index, isInitialSetting)
	self.mapSelector:setValue(index)
	self:updateSelectors()
end

function MapSelectionScreen:onClickOk()
	if self.selectedMapId > 0 then
		local mapModName = g_mapManager:getModNameFromMapId(self.maps[self.selectedMapId].id)

		if mapModName ~= nil and not PlatformPrivilegeUtil.checkModUse(self.onClickOk, self) then
			return
		end
	end

	MapSelectionScreen:superClass().onClickOk(self)

	if self.selectedMapId > 0 then
		local map = self.maps[self.selectedMapId]
		self.startMissionInfo.mapId = map.id

		self:changeScreen(CharacterCreationScreen, MapSelectionScreen)
	end
end

function MapSelectionScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer
end

function MapSelectionScreen:selectMapByNameAndFile(name, filename)
	local mapId = name

	if filename ~= "default" then
		filename, _ = Utils.getFilenameInfo(filename)
		mapId = filename .. "." .. name
	end

	local selectedMap = g_mapManager:getMapDataByIndex(1)

	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)

		if (not map.isModMap or not self.isMultiplayer or map.isMultiplayerSupported) and map.id == mapId then
			selectedMap = map

			break
		end
	end

	self.startMissionInfo.mapId = selectedMap.id
end

function MapSelectionScreen:update(dt)
	MapSelectionScreen:superClass().update(self, dt)

	if self.isMultiplayer then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("MainScreen")
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end
end

function MapSelectionScreen:inputEvent(action, value, eventUsed)
	eventUsed = MapSelectionScreen:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
		local curIndex = self.mapList.selectedIndex

		if action == InputAction.MENU_PAGE_PREV then
			self.mapList:setSelectedIndex(math.max(curIndex - 1, 1))
		else
			self.mapList:setSelectedIndex(curIndex + 1)
		end

		self:updateSelectors()

		eventUsed = true
	end

	return eventUsed
end

function MapSelectionScreen:updateSelectors()
	self.selectorLeftGamepad:setVisible(self.mapList.selectedIndex ~= 1)
	self.selectorRightGamepad:setVisible(self.mapList.selectedIndex ~= #self.maps)
end
