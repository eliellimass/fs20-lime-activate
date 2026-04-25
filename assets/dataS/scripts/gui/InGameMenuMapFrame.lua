InGameMenuMapFrame = {}
local InGameMenuMapFrame_mt = Class(InGameMenuMapFrame, TabbedMenuFrameElement)
InGameMenuMapFrame.CONTROLS = {
	FILTER_BUTTON_COMBINE = "filterButtonCombine",
	BUTTON_RESET_VEHICLE = "buttonResetVehicle",
	FILTER_BUTTON_OTHER = "filterButtonOther",
	FILTER_BUTTON_TOOL = "filterButtonTool",
	FILTER_BUTTON_TIPPING = "filterButtonTipping",
	SOIL_STATE_FILTER_BOX = "mapOverviewSoilBox",
	CONTEXT_IMAGE = "contextImage",
	FILTER_PAGING = "filterPaging",
	CONTEXT_TEXT = "contextText",
	SOIL_STATE_FILTER_TEXTS = "soilStateFilterText",
	FILTER_BUTTON_FIELD_JOBS = "filterButtonContracts",
	FARMLAND_VALUE_BOX = "farmlandValueBox",
	BUTTON_SWITCH_MAP_MODE = "buttonSwitchMapMode",
	BUTTON_SELECT = "buttonSelectIngame",
	BUTTON_ENTER_VEHICLE = "buttonEnterVehicle",
	GROWTH_STATE_FILTER_TEXTS = "growthStateFilterText",
	GROWTH_STATE_FILTER_BOX = "mapOverviewGrowthBox",
	BUTTON_SELL_FARMLAND = "buttonSellFarmland",
	ZOOM_GLYPH_PLACEHOLDER = "mapZoomGlyphPlaceholder",
	BUTTON_BOX = "buttonBox",
	BUTTON_LAYOUT = "buttonLayout",
	MAP_OVERVIEW_SELECTOR = "mapOverviewSelector",
	MAP_BOX = "mapBox",
	MAP_CURSOR = "mapCursor",
	DYNAMIC_MAP_IMAGE_LOADING = "dynamicMapImageLoading",
	CROP_TYPE_FILTER_BOX = "mapOverviewFruitTypeBox",
	BUTTON_SET_MARKER = "buttonSetMarker",
	BUTTON_BUY_FARMLAND = "buttonBuyFarmland",
	VEHICLE_BOX = "vehicleBox",
	CONTEXT_BOX = "contextBox",
	INGAME_MAP = "ingameMap",
	MOVE_GLYPH_PLACEHOLDER = "mapMoveGlyphPlaceholder",
	FILTER_BOX = "filterBox",
	GENERIC_BOX = "genericBox",
	CONTEXT_FARM = "contextFarm",
	CONTEXT_BOX_CORNER = "contextBoxCorner",
	FILTER_BUTTON_VEHICLE = "filterButtonVehicle",
	SOIL_STATE_FILTER_COLORS = "soilStateFilterColor",
	GROWTH_STATE_FILTER_BUTTONS = "growthStateFilterButton",
	MAP_CONTROLS_DISPLAY = "mapControls",
	SOIL_STATE_FILTER_BUTTONS = "soilStateFilterButton",
	BALANCE_TEXT = "balanceText",
	FARMLAND_VALUE_TEXT = "farmlandValueText",
	BUTTON_VISIT_PLACE = "buttonVisitPlace",
	GROWTH_STATE_FILTER_COLORS = "growthStateFilterColor",
	FILTER_BUTTON_TRAILER = "filterButtonTrailer"
}
InGameMenuMapFrame.MODE_OVERVIEW = 1
InGameMenuMapFrame.MODE_FARMLANDS = 2
InGameMenuMapFrame.FRUITS_PER_PAGE = 15
InGameMenuMapFrame.MAP_FRUIT_TYPE = 1
InGameMenuMapFrame.MAP_GROWTH = 2
InGameMenuMapFrame.MAP_SOIL = 3
InGameMenuMapFrame.FRUIT_TYPE_BUTTON_ELEMENT = {
	BUTTON = "cropTypeFilterButton",
	COLOR = "cropTypeFilterColor",
	ICON = "cropTypeFilterIcon",
	TYPE = "cropTypeFilterText"
}
InGameMenuMapFrame.INPUT_CONTEXT_NAME = "MENU_MAP_OVERVIEW"
InGameMenuMapFrame.CLEAR_INPUT_ACTIONS = {
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_EXTRA_1,
	InputAction.MENU_EXTRA_2,
	InputAction.SWITCH_VEHICLE,
	InputAction.SWITCH_VEHICLE_BACK,
	InputAction.CAMERA_ZOOM_IN,
	InputAction.CAMERA_ZOOM_OUT,
	InputAction.MENU_AXIS_LEFT_RIGHT
}
InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS = {
	InputAction.SWITCH_VEHICLE,
	InputAction.SWITCH_VEHICLE_BACK,
	InputAction.CAMERA_ZOOM_IN,
	InputAction.CAMERA_ZOOM_OUT
}
InGameMenuMapFrame.BUTTON_FRAME_SIDE = GS_IS_MOBILE_VERSION and GuiElement.FRAME_LEFT or GuiElement.FRAME_RIGHT

local function NO_CALLBACK()
end

function InGameMenuMapFrame:new(subclass_mt, messageCenter, l10n, inputManager, inputDisplayManager, fruitTypeManager, fillTypeManager, storeManager, shopController, farmlandManager, farmManager)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or InGameMenuMapFrame_mt)

	self:registerControls(InGameMenuMapFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager
	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.storeManager = storeManager
	self.shopController = shopController
	self.farmManager = farmManager
	self.farmlandManager = farmlandManager
	self.onClickBackCallback = NO_CALLBACK
	self.client = nil
	self.playerFarm = nil
	self.mode = InGameMenuMapFrame.MODE_OVERVIEW
	self.hotspotFilterState = {}
	self.fruitTypeFilter = {}
	self.growthStateFilter = {}
	self.soilStateFilter = {}
	self.mapOverlayGenerator = nil
	self.growthSelectionMappingIndex = 1
	self.soilSelectionMappingIndex = 1
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self.isMapOverviewInitialized = false
	self.lastInputHelpMode = 0
	self.isInputContextActive = false
	self.foliageStateOverlay = nil
	self.foliageStateOverlayIsReady = false
	self.farmlandStateOverlay = nil
	self.farmlandStateOverlayIsReady = false
	self.currentFruitPageId = 1
	self.selectedFarmland = nil

	function self.overviewOverlayFinishedCallback(overlayId)
		self:onOverviewOverlayFinished(overlayId)
	end

	function self.farmlandOverlayFinishedCallback(overlayId)
		self:onFarmlandOverlayFinished(overlayId)
	end

	self.currentHotspot = nil
	self.ingameMapBase = nil
	self.staticUIDeadzone = {
		0,
		0,
		0,
		0
	}
	self.zoomInputGlyph = nil
	self.moveInputGlyph = nil
	self.glyphTextSize = 0
	self.zoomText = ""
	self.moveCursorText = ""
	self.panMapText = ""
	self.canSell = false
	self.canBuy = false
	self.removeMarker = false
	self.canSetMarker = false
	self.canVisit = false
	self.canReset = false
	self.canEnter = false

	return self
end

function InGameMenuMapFrame:copyAttributes(src)
	InGameMenuMapFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.inputManager = src.inputManager
	self.inputDisplayManager = src.inputDisplayManager
	self.fruitTypeManager = src.fruitTypeManager
	self.fillTypeManager = src.fillTypeManager
	self.storeManager = src.storeManager
	self.shopController = src.shopController
	self.farmlandManager = src.farmlandManager
	self.farmManager = src.farmManager
	self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end

function InGameMenuMapFrame:onGuiSetupFinished()
	InGameMenuMapFrame:superClass().onGuiSetupFinished(self)

	local _ = nil
	_, self.glyphTextSize = getNormalizedScreenValues(0, InGameMenuMapFrame.GLYPH_TEXT_SIZE)
	self.zoomText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_ZOOM_MAP)
	self.moveCursorText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_MOVE_CURSOR)
	self.panMapText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.INPUT_PAN_MAP)
end

function InGameMenuMapFrame:createInputGlyphs()
	local iconWidth, iconHeight = getNormalizedScreenValues(unpack(InGameMenuMapFrame.GLYPH_SIZE))
	self.zoomInputGlyph = InputGlyphElement:new(self.inputDisplayManager, iconWidth, iconHeight)

	self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
	self.zoomInputGlyph:setScale(1, 1)
	self.zoomInputGlyph:setKeyboardGlyphColor(InGameMenuMapFrame.GLYPH_COLOR)
	self.zoomInputGlyph:setUpperCase(true)
	self.zoomInputGlyph:setBold(true)

	self.moveInputGlyph = InputGlyphElement:new(self.inputDisplayManager, iconWidth, iconHeight)

	self.moveInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
	self.moveInputGlyph:setScale(1, 1)
	self.moveInputGlyph:setKeyboardGlyphColor(InGameMenuMapFrame.GLYPH_COLOR)
	self.moveInputGlyph:setUpperCase(true)
	self.moveInputGlyph:setBold(true)
end

function InGameMenuMapFrame:delete()
	InGameMenuMapFrame:superClass().delete(self)

	if self.zoomInputGlyph ~= nil then
		self.zoomInputGlyph:delete()
	end

	if self.moveInputGlyph ~= nil then
		self.moveInputGlyph:delete()
	end

	self.messageCenter:unsubscribeAll(self)
	self.farmlandManager:removeStateChangeListener(self)
end

function InGameMenuMapFrame:initialize(onClickBackCallback)
	if not GS_IS_MOBILE_VERSION then
		self:createInputGlyphs()
		self:updateInputGlyphs()
	end

	self.messageCenter:subscribe(ResetVehicleEvent, self.onVehicleReset, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)

	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK

	self.filterPaging:updatePageMapping()

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(6)
	end
end

function InGameMenuMapFrame:onFrameOpen()
	InGameMenuMapFrame:superClass().onFrameOpen(self)
	self:toggleMapInput(true)
	self.ingameMap:onOpen()
	self.ingameMap:registerActionEvents()
	self:disableAlternateBindings()

	self.mapOverviewZoom = 1
	self.mapOverviewCenterX = 0.5
	self.mapOverviewCenterY = 0.5
	self.mode = InGameMenuMapFrame.MODE_OVERVIEW

	self.filterBox:setVisible(true)

	if self.farmlandValueBox ~= nil then
		self.farmlandValueBox:setVisible(false)
	end

	if self.visible and not self.isMapOverviewInitialized then
		self:setupMapOverview()
		self:assignFilterData()
		self.mapOverviewSelector:setState(1)
	else
		self:setMapSelectionItem(self.currentHotspot)
	end

	self:onClickMapOverviewSelector(self.mapOverviewSelector:getState())
	self:initializeFilterButtonState()
	self:setMapSelectionItem(nil)
	FocusManager:setFocus(self.mapOverviewSelector)

	if not GS_IS_MOBILE_VERSION then
		self:updateInputGlyphs()
	else
		self:onPageChanged(self.currentPage, self.currentPage)
		self.ingameMap:setFixedHorizontal(1 - self.filterBox.absSize[1], self.filterBox.absSize[1] / 2)
		self.ingameMap:setLockedToBorder(-self.pageHeader.absSize[2] / 2, 1 - self.pageHeader.absSize[2])
	end
end

function InGameMenuMapFrame:onFrameClose()
	InGameMenuMapFrame:superClass().onFrameClose(self)
	self.ingameMap:onClose()
	self:toggleMapInput(false)
	self:toggleFarmlandsHotspotFilterSettings(false)
end

function InGameMenuMapFrame:onLoadMapFinished()
	self.mapOverlayGenerator = MapOverlayGenerator:new(self.l10n, self.fruitTypeManager, self.fillTypeManager, self.farmlandManager, self.farmManager)

	self.mapOverlayGenerator:setColorBlindMode(self.isColorBlindMode)
	self.mapOverlayGenerator:setMissionFruitTypes(self.missionFruitTypes)

	self.displayCropTypes = self.mapOverlayGenerator:getDisplayCropTypes()
	self.displayGrowthStates = self.mapOverlayGenerator:getDisplayGrowthStates()
	self.displaySoilStates = self.mapOverlayGenerator:getDisplaySoilStates()

	if g_currentMission.terrainRootNode ~= nil then
		self:assignFilterData()
		self.farmlandManager:addStateChangeListener(self)
	end
end

function InGameMenuMapFrame:toggleMapInput(isActive)
	if self.isInputContextActive ~= isActive then
		self.isInputContextActive = isActive

		self:toggleCustomInputContext(isActive, InGameMenuMapFrame.INPUT_CONTEXT_NAME)

		if isActive then
			self:registerInput()
		else
			self:unregisterInput(true)
		end
	end
end

function InGameMenuMapFrame:reset()
	InGameMenuMapFrame:superClass().reset(self)

	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:delete()

		self.mapOverlayGenerator = nil
	end

	self:resetFarmlandSelection()

	self.foliageStateOverlayIsReady = false
	self.farmlandStateOverlayIsReady = false
	self.isMapOverviewInitialized = false
	self.isInputContextActive = false
	self.currentHotspot = nil
	self.hotspotFilterState = {}

	self:hideContextBox()
end

function InGameMenuMapFrame:disableAlternateBindings()
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_UP_DOWN)
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function InGameMenuMapFrame:update(dt)
	InGameMenuMapFrame:superClass().update(self, dt)

	local currentInputHelpMode = self.inputManager:getInputHelpMode()

	if currentInputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = currentInputHelpMode

		self:disableAlternateBindings()
		self.buttonSelectIngame:setVisible(currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and not GS_IS_MOBILE_VERSION)
		self:updateContextInputBarVisibility()

		if not GS_IS_MOBILE_VERSION then
			self:updateInputGlyphs()
		end
	end

	self.mapOverlayGenerator:update(dt)
end

function InGameMenuMapFrame:getContextBoxPositionAndOrientation(hotspot)
	local hotspotX, hotspotY, hotspotWidth, hotspotHeight = hotspot:getBoundings()
	local posX = hotspotX + hotspotWidth * 0.5
	local posY = hotspotY + hotspotHeight * 0.5
	local outRight = posX + self.contextBox.size[1] > 1
	local outLeft = posX - self.contextBox.size[1] < 0
	local outTop = posY + self.contextBox.size[2] > 1
	local outBottom = posY + self.contextBox.size[2] < 0
	local orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
	local rotation = 0

	if outRight then
		if outTop then
			orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
			rotation = math.pi
		else
			orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_LEFT
			rotation = math.pi * 0.5
		end
	elseif outLeft then
		if outTop then
			orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
			rotation = -math.pi * 0.5
		else
			orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
		end
	elseif outTop then
		orientation = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		rotation = -math.pi * 0.5
	end

	return posX, posY, orientation, rotation
end

function InGameMenuMapFrame:updateContextBoxPosition()
	if self.contextBox ~= nil and self.contextBox:getIsVisible() and self.currentHotspot ~= nil then
		if not self.currentHotspot:getIsVisible() then
			self:setMapSelectionItem(nil)

			return
		end

		local posX, posY, orientation, rotation = self:getContextBoxPositionAndOrientation(self.currentHotspot)
		local goLeft = orientation == InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_LEFT or orientation == InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
		local goDown = orientation == InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT or orientation == InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT

		if goLeft then
			posX = posX - self.contextBox.size[1]
		end

		if goDown then
			posY = posY - self.contextBox.size[2]

			self.contextBox:applyProfile(InGameMenuMapFrame.CONTEXT_BOX_TOP_FRAME_PROFILE)
		else
			self.contextBox:applyProfile(InGameMenuMapFrame.CONTEXT_BOX_BOTTOM_FRAME_PROFILE)
		end

		self.contextBox:setAbsolutePosition(posX, posY)

		local cornerAlignment = InGameMenuMapFrame.CONTEXT_BOX_CORNER_ALIGNMENT[orientation]

		self.contextBoxCorner:updatePositionForOrigin(cornerAlignment)
		self.contextBoxCorner:updateScreenAlign(cornerAlignment)
		self.contextBoxCorner:setImageRotation(rotation)
		self.contextBoxCorner:updateAbsolutePosition()
	end
end

function InGameMenuMapFrame:setInGameMap(ingameMap)
	self.ingameMapBase = ingameMap

	self.ingameMap:setIngameMap(ingameMap)
end

function InGameMenuMapFrame:setTerrainSize(terrainSize)
	self.ingameMap:setTerrainSize(terrainSize)
end

function InGameMenuMapFrame:setMissionFruitTypes(missionFruitTypes)
	self.missionFruitTypes = missionFruitTypes
end

function InGameMenuMapFrame:setClient(client)
	self.client = client
end

function InGameMenuMapFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm

	self:onMoneyChanged(playerFarm.farmId, playerFarm:getBalance())
end

function InGameMenuMapFrame:assignFilterData()
	self.filterPaging:updatePageMapping()
	self:assignCropTypeFilterData()
	self:assignGroundStateFilterData(true, self.displayGrowthStates, self.growthStateFilterButton, self.growthStateFilterColor, self.growthStateFilterText)
	self:assignGroundStateFilterData(false, self.displaySoilStates, self.soilStateFilterButton, self.soilStateFilterColor, self.soilStateFilterText)
end

local function cropTypeButtonPredicate(element)
	return element.name == InGameMenuMapFrame.FRUIT_TYPE_BUTTON_ELEMENT.BUTTON
end

local function cropTypeColorPredicate(element)
	return element.name == InGameMenuMapFrame.FRUIT_TYPE_BUTTON_ELEMENT.COLOR
end

local function cropTypeIconPredicate(element)
	return element.name == InGameMenuMapFrame.FRUIT_TYPE_BUTTON_ELEMENT.ICON
end

local function cropTypeTextPredicate(element)
	return element.name == InGameMenuMapFrame.FRUIT_TYPE_BUTTON_ELEMENT.TYPE
end

function InGameMenuMapFrame:assignCropTypeFilterData()
	local cropTypeIndex = 1

	for i = 1, #self.mapOverviewFruitTypeBox do
		local box = self.mapOverviewFruitTypeBox[i]
		local buttons = box:getDescendants(cropTypeButtonPredicate)
		local colors = box:getDescendants(cropTypeColorPredicate)
		local icons = box:getDescendants(cropTypeIconPredicate)
		local texts = box:getDescendants(cropTypeTextPredicate)

		for j = 1, #buttons do
			if cropTypeIndex <= #self.displayCropTypes then
				buttons[j]:setVisible(true)
				buttons[j]:toggleFrameSide(InGameMenuMapFrame.BUTTON_FRAME_SIDE, false)

				buttons[j].onHighlightCallback = self.onFilterButtonSelect
				buttons[j].onHighlightRemoveCallback = self.onFilterButtonUnselect
				buttons[j].onFocusCallback = self.onFilterButtonSelect
				buttons[j].onLeaveCallback = self.onFilterButtonUnselect
				local cropType = self.displayCropTypes[cropTypeIndex]

				buttons[j].onClickCallback = function ()
					self:onClickCropFilter(buttons[j], cropType.fruitTypeIndex)
				end

				local color = cropType.colors[self.isColorBlindMode]

				colors[j]:setImageColor(GuiOverlay.STATE_NORMAL, unpack(color))
				icons[j]:setImageFilename(cropType.iconFilename)
				icons[j]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(cropType.iconUVs))
				texts[j]:setText(cropType.description)

				local filterValue = self.fruitTypeFilter[cropType.fruitTypeIndex]

				if filterValue == nil then
					filterValue = cropType.fruitTypeIndex ~= FruitType.GRASS and cropType.fruitTypeIndex ~= FruitType.WEED
				end

				self.fruitTypeFilter[cropType.fruitTypeIndex] = filterValue

				self:setFilterButtonDisplayEnabled(buttons[j], filterValue)
			else
				buttons[j]:setVisible(false)
			end

			cropTypeIndex = cropTypeIndex + 1
		end

		box:invalidateLayout()
	end
end

function InGameMenuMapFrame:assignGroundStateFilterData(isGrowth, displayStates, filterButtons, filterColors, filterTexts)
	for i = 1, #filterButtons do
		if i <= #displayStates then
			local filterButton = filterButtons[i]

			filterButton:setVisible(true)
			filterButton:toggleFrameSide(InGameMenuMapFrame.BUTTON_FRAME_SIDE, false)

			filterButton.onHighlightCallback = self.onFilterButtonSelect
			filterButton.onHighlightRemoveCallback = self.onFilterButtonUnselect
			filterButton.onFocusCallback = self.onFilterButtonSelect
			filterButton.onLeaveCallback = self.onFilterButtonUnselect
			local state = displayStates[i]
			local colors = state.colors[self.isColorBlindMode]
			local colorElement = filterColors[i]

			self:assignGroundStateColors(colorElement, colors)
			filterTexts[i]:setText(state.description)

			function filterButton.onClickCallback()
				if isGrowth then
					self:onClickGrowthFilter(filterButton, i)
				else
					self:onClickSoilFilter(filterButton, i)
				end
			end

			local filterMap = nil

			if isGrowth then
				filterMap = self.growthStateFilter
			else
				filterMap = self.soilStateFilter
			end

			local filterValue = filterMap[i]
			filterMap[i] = filterValue == nil and true or filterValue

			self:setFilterButtonDisplayEnabled(filterButton, filterMap[i])
		else
			filterButtons[i]:setVisible(false)
		end
	end
end

function InGameMenuMapFrame:assignGroundStateColors(colorElement, stateColors)
	if #stateColors == 1 then
		colorElement:setImageColor(GuiOverlay.STATE_NORMAL, unpack(stateColors[1]))
	else
		for i = #colorElement.elements, 1, -1 do
			colorElement.elements[i]:delete()
		end

		colorElement:applyProfile(InGameMenuMapFrame.GROUND_STATE_FILTER_COLOR_PROFILE)

		local partWidth = colorElement.size[1] / #stateColors

		colorElement:setSize(partWidth, nil)
		colorElement:setImageColor(GuiOverlay.STATE_NORMAL, unpack(stateColors[1]))

		local basePosX = colorElement.absPosition[1]
		local clones = {}

		for i = 2, #stateColors do
			local newPart = colorElement:clone()

			table.insert(clones, newPart)
			newPart:setSize(partWidth, nil)
			newPart:setPosition((i - 1) * partWidth, 0)
			newPart:setImageColor(GuiOverlay.STATE_NORMAL, unpack(stateColors[i]))
		end

		for _, clone in ipairs(clones) do
			colorElement:addElement(clone)
		end
	end
end

function InGameMenuMapFrame:resetUIDeadzones()
	self.ingameMap:clearCursorDeadzones()
	self.ingameMap:addCursorDeadzone(unpack(self.staticUIDeadzone))

	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		self.ingameMap:addCursorDeadzone(self.filterBox.absPosition[1], self.filterBox.absPosition[2], self.filterBox.absPosition[1] + self.filterBox.size[1], self.filterBox.absPosition[2] + self.filterBox.size[2])
	end
end

function InGameMenuMapFrame:setStaticUIDeadzone(screenX, screenY, width, height)
	self.staticUIDeadzone = {
		screenX,
		screenY,
		width,
		height
	}
end

function InGameMenuMapFrame:setupMapOverview()
	self.isMapOverviewInitialized = true
	self.mapSelectorMapping = {
		InGameMenuMapFrame.MAP_FRUIT_TYPE
	}
	local fruitTypesTextTemplate = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.MAP_SELECTOR_FRUIT_TYPES)
	self.mapSelectorTexts = {
		string.format(fruitTypesTextTemplate, "")
	}
	self.fruitTypePages = {
		{}
	}
	self.fruitMapping = {}
	local fruitCounter = 0

	for i, desc in pairs(self.displayCropTypes) do
		if InGameMenuMapFrame.FRUITS_PER_PAGE <= fruitCounter then
			local clone = self.mapOverviewFruitTypeBox[1]:clone(self.mapOverviewFruitTypeBox[1].parent)

			FocusManager:loadElementFromCustomValues(clone)
			table.insert(self.mapOverviewFruitTypeBox, clone)
			table.insert(self.fruitTypePages, {})
			table.insert(self.mapSelectorMapping, InGameMenuMapFrame.MAP_FRUIT_TYPE)

			self.mapSelectorTexts[1] = string.format(fruitTypesTextTemplate, " 1")

			table.insert(self.mapSelectorTexts, string.format(fruitTypesTextTemplate, " " .. #self.fruitTypePages))

			fruitCounter = 0
		end

		local entry = {
			isVisible = true,
			fruitIndex = desc.fruitTypeIndex
		}

		table.insert(self.fruitTypePages[#self.fruitTypePages], entry)

		self.fruitMapping[desc.fruitTypeIndex] = entry
		fruitCounter = fruitCounter + 1
	end

	table.insert(self.mapSelectorMapping, InGameMenuMapFrame.MAP_GROWTH)
	table.insert(self.mapSelectorTexts, self.l10n:getText("ui_mapOverviewGrowth"))
	table.insert(self.mapSelectorMapping, InGameMenuMapFrame.MAP_SOIL)
	table.insert(self.mapSelectorTexts, self.l10n:getText("ui_mapOverviewSoil"))
	self.filterPaging:removeElement(self.mapOverviewGrowthBox)
	self.filterPaging:addElement(self.mapOverviewGrowthBox)
	self.filterPaging:removeElement(self.mapOverviewSoilBox)
	self.filterPaging:addElement(self.mapOverviewSoilBox)
	self.mapOverviewSelector:setTexts(self.mapSelectorTexts)
end

function InGameMenuMapFrame:onOverviewOverlayFinished(overlayId)
	self.foliageStateOverlay = overlayId
	self.foliageStateOverlayIsReady = true

	self.dynamicMapImageLoading:setVisible(false)
end

function InGameMenuMapFrame:onFarmlandOverlayFinished(overlayId)
	self.farmlandStateOverlay = overlayId
	self.farmlandStateOverlayIsReady = true

	self.dynamicMapImageLoading:setVisible(false)
end

function InGameMenuMapFrame:generateOverviewOverlay()
	if self.isMapOverviewInitialized then
		local state = self.mapOverviewSelector:getState()
		local currentMap = self.mapSelectorMapping[state]

		if self.foliageStateOverlay == nil then
			self.foliageStateOverlayIsReady = false

			self.dynamicMapImageLoading:setVisible(true)
		end

		if currentMap == InGameMenuMapFrame.MAP_FRUIT_TYPE then
			self.mapOverlayGenerator:generateFruitTypeOverlay(self.overviewOverlayFinishedCallback, self.fruitTypeFilter)
		elseif currentMap == InGameMenuMapFrame.MAP_GROWTH then
			self.mapOverlayGenerator:generateGrowthStateOverlay(self.overviewOverlayFinishedCallback, self.growthStateFilter, self.fruitTypeFilter)
		elseif currentMap == InGameMenuMapFrame.MAP_SOIL then
			self.mapOverlayGenerator:generateSoilStateOverlay(self.overviewOverlayFinishedCallback, self.soilStateFilter)
		end
	end
end

function InGameMenuMapFrame:generateFarmlandOverlay(selectedFarmland)
	if self.isMapOverviewInitialized then
		self.mapOverlayGenerator:generateFarmlandOverlay(self.farmlandOverlayFinishedCallback, selectedFarmland)
	end
end

function InGameMenuMapFrame:setFilterIconState(element, category)
	local isActive = self.ingameMapBase.filter[category]
	local profileName = InGameMenuMapFrame.HOTSPOT_FILTER_ICON_PROFILE[isActive][category]

	element:applyProfile(profileName)
end

function InGameMenuMapFrame:toggleFarmlandsHotspotFilterSettings(isActive)
	if isActive then
		for k, v in pairs(self.ingameMapBase.filter) do
			self.hotspotFilterState[k] = v

			self.ingameMapBase:setFilter(k, false)
		end

		self.ingameMapBase:setFilter(MapHotspot.CATEGORY_FIELD_DEFINITION, true)
		self.ingameMapBase:setFilter(MapHotspot.CATEGORY_TRIGGER, true)
		self.ingameMapBase:setFilter(MapHotspot.CATEGORY_MISSION, true)
		self.ingameMapBase:setFilter(MapHotspot.CATEGORY_DEFAULT, true)
	else
		for k, v in pairs(self.hotspotFilterState) do
			self.ingameMapBase:setFilter(k, v)
		end
	end
end

function InGameMenuMapFrame:draw()
	InGameMenuMapFrame:superClass().draw(self)
	self:updateContextBoxPosition()

	if not GS_IS_MOBILE_VERSION then
		self.zoomInputGlyph:draw()
		self.moveInputGlyph:draw()
	end
end

function InGameMenuMapFrame:showContextInput(canEnter, canReset, canVisit, canSetMarker, removeMarker, canBuy, canSell)
	self.buttonEnterVehicle:setVisible(canEnter)
	self.buttonResetVehicle:setVisible(canReset)
	self.buttonVisitPlace:setVisible(canVisit and not GS_IS_MOBILE_VERSION)
	self.buttonSetMarker:setVisible(canSetMarker)
	self.buttonBuyFarmland:setVisible(canBuy)
	self.buttonSellFarmland:setVisible(canSell)
	self:showContextMarker(canSetMarker, removeMarker)
	self:updateContextInputBarVisibility()
end

function InGameMenuMapFrame:updateContextInputBarVisibility()
	self.buttonBox:setVisible(true)

	local isVisible = self.buttonEnterVehicle:getIsVisible() or self.buttonResetVehicle:getIsVisible() or self.buttonVisitPlace:getIsVisible() or self.buttonSetMarker:getIsVisible() or self.buttonBuyFarmland:getIsVisible() or self.buttonSellFarmland:getIsVisible() or self.buttonSelectIngame:getIsVisible()

	self.buttonBox:setVisible(isVisible)

	if isVisible then
		self.buttonLayout:invalidateLayout()
	end
end

function InGameMenuMapFrame:showContextMarker(canSetMarker, removeMarker)
	if canSetMarker then
		local markerText = nil

		if removeMarker then
			markerText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.REMOVE_MARKER)
		else
			markerText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.SET_MARKER)
		end

		self.buttonSetMarker:setText(markerText)
	end
end

function InGameMenuMapFrame:showContextBox(hotspot, description, imageFilename, uvs, farmId)
	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW and self.contextBox ~= nil then
		self.contextBox:setVisible(true)

		local x, y = self:getContextBoxPositionAndOrientation(hotspot)

		self.contextBox:setAbsolutePosition(x, y)
		self.contextImage:setImageFilename(imageFilename)
		self.contextImage:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(uvs))
		self.contextText:setText(description)

		if farmId ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
			local farm = g_farmManager:getFarmById(farmId)

			self.contextFarm:setText(farm.name)
			self.contextFarm:setTextColor(unpack(farm:getColor()))
		else
			self.contextFarm:setText("")
		end
	end
end

function InGameMenuMapFrame:hideContextBox()
	if self.contextBox ~= nil then
		self.contextBox:setVisible(false)
	end
end

function InGameMenuMapFrame:setMapSelectionItem(hotspot)
	self.ingameMapBase:setSelectedHotspot(hotspot)

	self.selectedField = nil
	local canEnter = false
	local canReset = false
	local canVisit = false
	local canSetMarker = false
	local removeMarker = false
	local canBuy = false
	local name, imageFilename, uvs, vehicle, isHorse, farmId = nil
	local showContextBox = false

	if hotspot ~= nil then
		name, imageFilename, uvs, vehicle = self:getHotspotData(hotspot)

		if vehicle ~= nil and (hotspot.category == MapHotspot.CATEGORY_VEHICLE_COMBINE or hotspot.category == MapHotspot.CATEGORY_VEHICLE_STEERABLE or hotspot.category == MapHotspot.CATEGORY_VEHICLE_TOOL or hotspot.category == MapHotspot.CATEGORY_VEHICLE_TRAILER or hotspot.category == MapHotspot.CATEGORY_AI) then
			self.currentHotspot = hotspot

			self.ingameMap:setMapFocusToHotspot(hotspot)

			farmId = vehicle:getOwnerFarmId()
			name = vehicle:getName()
			local specEnterable = vehicle.spec_enterable

			if specEnterable ~= nil and not specEnterable.isControlled then
				canEnter = specEnterable.enterReferenceNode ~= nil and specEnterable.exitPoint ~= nil and g_currentMission.isTutorialMission ~= true and (g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and vehicle:getIsEnterable()
			end

			canReset = g_currentMission.isTutorialMission ~= true and (g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and vehicle:getCanBeReset() and hotspot.category ~= MapHotspot.CATEGORY_AI
			canReset = canReset and g_currentMission:getHasPlayerPermission("resetVehicle", nil, vehicle:getOwnerFarmId())
			local specRideable = vehicle.spec_rideable

			if specRideable ~= nil then
				isHorse = true
				local animal = specRideable.animal
				name = animal:getName()
				local subType = animal.subType
				local storeInfo = subType.storeInfo
				imageFilename = storeInfo.imageFilename
				uvs = Overlay.DEFAULT_UVS
			end

			showContextBox = true
		elseif hotspot.category == MapHotspot.CATEGORY_FIELD_DEFINITION then
			self.currentHotspot = hotspot
			self.selectedField = hotspot:getAssociatedData()

			self.ingameMap:setMapFocusToHotspot(hotspot)

			local field = g_fieldManager:getFieldByIndex(self.selectedField)
			canBuy = field:getIsAIActive()

			if canBuy and GS_IS_MOBILE_VERSION then
				self.buttonBuyFarmland:setText(string.format("%s (%s)", self.l10n:getText("button_buy"), self.l10n:formatMoney(field.farmland.price)))
			end

			if GS_IS_MOBILE_VERSION and self.currentPage ~= 5 then
				local old = self.currentPage
				self.currentPage = 5

				self:onPageChanged(self.currentPage, old)
			end
		elseif GS_IS_MOBILE_VERSION and self.currentPage ~= 6 and (hotspot.category == MapHotspot.CATEGORY_DEFAULT or hotspot.category == MapHotspot.CATEGORY_TRIGGER) then
			local old = self.currentPage
			self.currentPage = 6

			self:onPageChanged(self.currentPage, old)
		elseif hotspot:getHasDetails() then
			if hotspot.category ~= MapHotspot.CATEGORY_AI then
				canSetMarker = true
				removeMarker = g_currentMission.currentMapTargetHotspot == hotspot

				if not GS_IS_MOBILE_VERSION then
					canVisit = true
				end
			end

			self.currentHotspot = hotspot

			self.ingameMap:setMapFocusToHotspot(hotspot)

			showContextBox = name ~= nil and name ~= "" and imageFilename ~= nil and uvs ~= nil
		end
	else
		self.currentHotspot = nil
	end

	if isHorse then
		self.buttonEnterVehicle:setText(string.format(g_i18n:getText("action_rideAnimal"), name))
	else
		self.buttonEnterVehicle:setText(g_i18n:getText("button_enterVehicle"))
	end

	if showContextBox then
		if GS_IS_MOBILE_VERSION then
			if vehicle ~= nil then
				if self.currentPage ~= 4 then
					local old = self.currentPage
					self.currentPage = 4

					self:onPageChanged(self.currentPage, old)
				end

				local storeItem = self.storeManager:getItemByXMLFilename(vehicle.configFileName)
				local itemBrand = g_brandManager:getBrandByIndex(storeItem.brandIndex)

				self.vehicleBox:getDescendantByName("brandImage"):setImageFilename(itemBrand.image)
				self.vehicleBox:getDescendantByName("name"):setText(vehicle:getName())

				local childs = vehicle:getChildVehicles()

				for i = 1, 3 do
					local attached = childs[i]
					local show = attached ~= nil and attached ~= vehicle
					local icon = self.vehicleBox:getDescendantByName("attachIcon" .. i)
					local text = self.vehicleBox:getDescendantByName("attachText" .. i)

					icon:setVisible(show)
					text:setVisible(show)

					if show then
						text:setText(attached:getName())
					end
				end

				self.vehicleBox:getDescendantByName("nothingAttached"):setVisible(#childs <= 1)
			end
		else
			self:showContextBox(hotspot, name, imageFilename, uvs, farmId)
		end
	elseif not GS_IS_MOBILE_VERSION then
		self:hideContextBox()
	end

	self:showContextInput(canEnter, canReset, canVisit, canSetMarker, removeMarker, canBuy, false)

	self.canBuy = canBuy
	self.removeMarker = removeMarker
	self.canSetMarker = canSetMarker
	self.canVisit = canVisit
	self.canReset = canReset
	self.canEnter = canEnter
end

function InGameMenuMapFrame:updateMapSelectionFilterNavigation()
	local targetButtonTop, targetButtonBottom = nil

	if self.mapSelectionPreviousItem.visible then
		targetButtonTop = self.mapSelectionPreviousItem
	elseif self.mapSelectionNextItem.visible then
		targetButtonTop = self.mapSelectionNextItem
	end

	if targetButtonBottom == nil then
		if self.mapSelectionEnter.visible then
			targetButtonBottom = self.mapSelectionEnter
		elseif self.mapSelectionReset.visible then
			targetButtonBottom = self.mapSelectionReset
		elseif self.mapSelectionVisit.visible then
			targetButtonBottom = self.mapSelectionVisit
		elseif self.mapSelectionTag.visible then
			targetButtonBottom = self.mapSelectionTag
		end
	end

	targetButtonTop = Utils.getNoNil(targetButtonTop, self.mapSelectionPreviousItem)
	targetButtonBottom = Utils.getNoNil(targetButtonBottom, self.mapSelectionEnter)

	for _, elem in pairs(self.mapOverviewFilters) do
		elem.focusChangeData[FocusManager.BOTTOM] = targetButtonTop.focusId
	end

	targetButtonTop.focusChangeData[FocusManager.BOTTOM] = targetButtonBottom.focusId
	targetButtonBottom.focusChangeData[FocusManager.TOP] = targetButtonTop.focusId
end

function InGameMenuMapFrame:getHotspotData(hotspot)
	if hotspot ~= nil then
		if hotspot.category == MapHotspot.CATEGORY_VEHICLE_COMBINE or hotspot.category == MapHotspot.CATEGORY_VEHICLE_STEERABLE or hotspot.category == MapHotspot.CATEGORY_VEHICLE_TOOL or hotspot.category == MapHotspot.CATEGORY_VEHICLE_TRAILER or hotspot.category == MapHotspot.CATEGORY_AI then
			local vehicle = g_currentMission.nodeToObject[hotspot.linkNode]

			if vehicle ~= nil then
				local storeItem = self.storeManager:getItemByXMLFilename(vehicle.configFileName)

				if storeItem ~= nil then
					return storeItem.name, storeItem.imageFilename, Overlay.DEFAULT_UVS, vehicle
				end
			end
		else
			local overlay = hotspot:getOverlay(math.huge)

			if overlay ~= nil then
				return hotspot.fullViewName, overlay.filename, hotspot.imageUVs, nil
			end
		end
	end

	return nil, , , 
end

function InGameMenuMapFrame:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive

		self.mapOverlayGenerator:setColorBlindMode(self.isColorBlindMode)
		self:assignFilterData()
		self:generateOverviewOverlay()
	end
end

function InGameMenuMapFrame:initializeFilterButtonState()
	self:setFilterIconState(self.filterButtonVehicle, MapHotspot.CATEGORY_VEHICLE_STEERABLE)
	self:setFilterIconState(self.filterButtonCombine, MapHotspot.CATEGORY_VEHICLE_COMBINE)
	self:setFilterIconState(self.filterButtonTrailer, MapHotspot.CATEGORY_VEHICLE_TRAILER)
	self:setFilterIconState(self.filterButtonTool, MapHotspot.CATEGORY_VEHICLE_TOOL)
	self:setFilterIconState(self.filterButtonTipping, MapHotspot.CATEGORY_TRIGGER)
	self:setFilterIconState(self.filterButtonContracts, MapHotspot.CATEGORY_MISSION)
	self:setFilterIconState(self.filterButtonOther, MapHotspot.CATEGORY_DEFAULT)

	local filterIndex = 1

	for _, box in ipairs(self.mapOverviewFruitTypeBox) do
		local buttons = box:getDescendants(cropTypeButtonPredicate)

		for _, button in ipairs(buttons) do
			local cropType = self.displayCropTypes[filterIndex]
			local isButtonEnabled = cropType ~= nil and self.fruitTypeFilter[cropType.fruitTypeIndex]

			self:setFilterButtonDisplayEnabled(button, isButtonEnabled)

			filterIndex = filterIndex + 1
		end
	end

	for i, button in ipairs(self.growthStateFilterButton) do
		self:setFilterButtonDisplayEnabled(button, self.growthStateFilter[i])
	end

	for i, button in ipairs(self.soilStateFilterButton) do
		self:setFilterButtonDisplayEnabled(button, self.soilStateFilter[i])
	end
end

function InGameMenuMapFrame:resetFarmlandSelection()
	self.selectedFarmland = nil
	self.canBuy = false
	self.canSell = false
end

function InGameMenuMapFrame:checkPlaceablesOnFarmland(farmland)
	local ownedItems = self.shopController:getOwnedFarmItems()

	for storeItem, itemInfos in pairs(ownedItems) do
		if storeItem.canBeSold and StoreItemUtil.getIsPlaceable(storeItem) then
			for _, placeable in pairs(itemInfos.items) do
				local posX, _, posZ = getWorldTranslation(placeable.nodeId)
				local placeableFarmlandId = self.farmlandManager:getFarmlandIdAtWorldPosition(posX, posZ)

				if placeableFarmlandId == farmland.id then
					return true
				end
			end
		end
	end

	return false
end

function InGameMenuMapFrame:onMoneyChanged(farmId, newBalance)
	if farmId == self.playerFarm.farmId and self.balanceText ~= nil then
		self.balanceText:setText(self.l10n:formatMoney(newBalance, 0, true, true))

		local requiredProfile = InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEUTRAL

		if math.floor(newBalance) <= -1 then
			requiredProfile = InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEGATIVE
		end

		if self.balanceText.profile ~= requiredProfile then
			self.balanceText:applyProfile(requiredProfile)
		end

		self.balanceText:updateAbsolutePosition()
	end
end

function InGameMenuMapFrame:onClickMapFilterSteerable(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_VEHICLE_STEERABLE, not self.ingameMapBase.filter[MapHotspot.CATEGORY_VEHICLE_STEERABLE])
	self:setFilterIconState(element, MapHotspot.CATEGORY_VEHICLE_STEERABLE)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterCombine(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_VEHICLE_COMBINE, not self.ingameMapBase.filter[MapHotspot.CATEGORY_VEHICLE_COMBINE])
	self:setFilterIconState(element, MapHotspot.CATEGORY_VEHICLE_COMBINE)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterTrailer(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_VEHICLE_TRAILER, not self.ingameMapBase.filter[MapHotspot.CATEGORY_VEHICLE_TRAILER])
	self:setFilterIconState(element, MapHotspot.CATEGORY_VEHICLE_TRAILER)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterTools(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_VEHICLE_TOOL, not self.ingameMapBase.filter[MapHotspot.CATEGORY_VEHICLE_TOOL])
	self:setFilterIconState(element, MapHotspot.CATEGORY_VEHICLE_TOOL)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterTipStations(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_TRIGGER, not self.ingameMapBase.filter[MapHotspot.CATEGORY_TRIGGER])
	self:setFilterIconState(element, MapHotspot.CATEGORY_TRIGGER)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterContracts(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_MISSION, not self.ingameMapBase.filter[MapHotspot.CATEGORY_MISSION])
	self:setFilterIconState(element, MapHotspot.CATEGORY_MISSION)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onClickMapFilterOther(element)
	self.ingameMapBase:setFilter(MapHotspot.CATEGORY_DEFAULT, not self.ingameMapBase.filter[MapHotspot.CATEGORY_DEFAULT])
	self:setFilterIconState(element, MapHotspot.CATEGORY_DEFAULT)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onDrawPostIngameMap(element, ingameMap)
	if self.hideContentOverlay then
		return
	end

	local modeOverlay = 0

	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW and self.foliageStateOverlayIsReady then
		modeOverlay = self.foliageStateOverlay
	elseif self.mode == InGameMenuMapFrame.MODE_FARMLANDS and self.farmlandStateOverlayIsReady then
		modeOverlay = self.farmlandStateOverlay
	end

	if modeOverlay ~= 0 then
		setOverlayUVs(modeOverlay, ingameMap.mapUVs[1], ingameMap.mapUVs[2], ingameMap.mapUVs[3], ingameMap.mapUVs[4], ingameMap.mapUVs[5], ingameMap.mapUVs[6], ingameMap.mapUVs[7], ingameMap.mapUVs[8])
		renderOverlay(modeOverlay, element.absPosition[1], element.absPosition[2], element.size[1], element.size[2])
	end
end

function InGameMenuMapFrame:onClickMapOverviewSelector(state)
	self.filterPaging:setPage(state)

	for i = 1, #self.mapOverviewFruitTypeBox do
		self.mapOverviewFruitTypeBox[i]:invalidateLayout()
	end

	self.mapOverviewGrowthBox:invalidateLayout()
	self.mapOverviewSoilBox:invalidateLayout()
	self:generateOverviewOverlay()
end

function InGameMenuMapFrame.onFilterButtonSelect(_, button)
	button:toggleFrameSide(InGameMenuMapFrame.BUTTON_FRAME_SIDE, true)
end

function InGameMenuMapFrame.onFilterButtonUnselect(_, button)
	button:toggleFrameSide(InGameMenuMapFrame.BUTTON_FRAME_SIDE, false)

	for _, child in pairs(button.elements) do
		child:setDisabled(child:getIsDisabled())
	end
end

function InGameMenuMapFrame:setFilterButtonDisplayEnabled(filterButton, isEnabled)
	for _, child in pairs(filterButton.elements) do
		child:setDisabled(not isEnabled)
	end
end

function InGameMenuMapFrame:toggleFilter(filterButton, filterMap, filterKey)
	local prevValue = filterMap[filterKey]
	filterMap[filterKey] = not prevValue

	self:setFilterButtonDisplayEnabled(filterButton, not prevValue)
	self:generateOverviewOverlay()
end

function InGameMenuMapFrame:onClickCropFilter(element, fruitTypeIndex)
	self:toggleFilter(element, self.fruitTypeFilter, fruitTypeIndex)
end

function InGameMenuMapFrame:onClickGrowthFilter(element, growthStateIndex)
	self:toggleFilter(element, self.growthStateFilter, growthStateIndex)
end

function InGameMenuMapFrame:onClickSoilFilter(element, soilStateIndex)
	self:toggleFilter(element, self.soilStateFilter, soilStateIndex)
end

function InGameMenuMapFrame:onClickHotspot(element, hotspot)
	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW and self.currentHotspot ~= hotspot and InGameMenuMapFrame.HOTSPOT_VALID_CATEGORIES[hotspot.category] then
		self:setMapSelectionItem(hotspot)
	end
end

function InGameMenuMapFrame:onClickMap(element, worldX, worldZ)
	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		self:setMapSelectionItem(nil)
	elseif self.mode == InGameMenuMapFrame.MODE_FARMLANDS then
		self.selectedFarmland = self.farmlandManager:getFarmlandAtWorldPosition(worldX, worldZ)

		if self.selectedFarmland ~= nil then
			self:generateFarmlandOverlay(self.selectedFarmland)

			if self.selectedFarmland.price <= self.playerFarm:getBalance() or self.selectedFarmland.isOwned then
				self.balanceText:applyProfile(InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEUTRAL)
			else
				self.balanceText:applyProfile(InGameMenuMapFrame.PROFILE.MONEY_VALUE_NEGATIVE)
			end

			self.farmlandValueText:setText(self.l10n:formatMoney(self.selectedFarmland.price, 0, true, true))
			self.farmlandValueBox:setVisible(true)

			local ownerFarmId = self.farmlandManager:getFarmlandOwner(self.selectedFarmland.id)
			local playerIsFarmManager = g_currentMission:getHasPlayerPermission("farmManager")
			self.canBuy = ownerFarmId == FarmlandManager.NO_OWNER_FARM_ID and playerIsFarmManager
			self.canSell = ownerFarmId == self.playerFarm.farmId and playerIsFarmManager

			self:showContextInput(false, false, false, false, false, self.canBuy, self.canSell)
		else
			self:resetFarmlandSelection()
		end
	end
end

function InGameMenuMapFrame:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self:selectFirstHotspot()
end

function InGameMenuMapFrame:onFarmlandStateChanged(farmlandId, farmId)
	if self.mode == InGameMenuMapFrame.MODE_FARMLANDS then
		if self.selectedFarmland ~= nil and self.selectedFarmland.id == farmlandId then
			self:resetFarmlandSelection()
		end

		self:generateFarmlandOverlay(nil)
		self:showContextInput()
	end
end

function InGameMenuMapFrame:onVehicleReset(state)
	if state == ResetVehicleEvent.STATE_SUCCESS then
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_DONE),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onInfoOkClick,
			target = self
		})
	elseif state == ResetVehicleEvent.STATE_FAILED then
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_FAILED),
			callback = self.onInfoOkClick,
			target = self
		})
	elseif state == ResetVehicleEvent.STATE_IN_USE then
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_IN_USE),
			callback = self.onInfoOkClick,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_NO_PERMISSION),
			callback = self.onInfoOkClick,
			target = self
		})
	end
end

function InGameMenuMapFrame:onInfoOkClick()
	self:disableAlternateBindings()
end

function InGameMenuMapFrame:onClickResetVehicle()
	if (g_currentMission.tourIconsBase == nil or not g_currentMission.tourIconsBase.visible) and self.currentHotspot ~= nil then
		g_gui:showYesNoDialog({
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_RESET_CONFIRM),
			title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.VEHICLE_RESET),
			callback = self.onYesNoReset,
			target = self
		})
	end
end

function InGameMenuMapFrame:onClickVisitPlace()
	if self.currentHotspot ~= nil and self.currentHotspot.xMapPos ~= nil and self.currentHotspot.zMapPos ~= nil then
		self.onClickBackCallback()

		if g_currentMission.controlledVehicle ~= nil then
			g_currentMission:onLeaveVehicle(self.currentHotspot.xMapPos, 1, self.currentHotspot.zMapPos, false, false)
		else
			g_currentMission.player:moveTo(self.currentHotspot.xMapPos, 1, self.currentHotspot.zMapPos, false, false)
		end
	end
end

function InGameMenuMapFrame:onClickTagPlace()
	if self.currentHotspot ~= nil and self.currentHotspot.xMapPos ~= nil and self.currentHotspot.zMapPos ~= nil then
		if g_currentMission.currentMapTargetHotspot ~= self.currentHotspot then
			self.removeMarker = true

			g_currentMission:setMapTargetHotspot(self.currentHotspot)
		else
			self.removeMarker = false

			g_currentMission:setMapTargetHotspot(nil)
		end

		self:showContextMarker(self.canSetMarker, self.removeMarker)
	end
end

function InGameMenuMapFrame:onClickEnterVehicle()
	local vehicle = g_currentMission.nodeToObject[self.currentHotspot.linkNode]

	if vehicle ~= nil and not g_currentMission.isPlayerFrozen and vehicle:getIsEnterable() then
		self.onClickBackCallback()
		g_currentMission:requestToEnterVehicle(vehicle)
	end
end

function InGameMenuMapFrame:onClickSwitchMapMode()
	if GS_IS_MOBILE_VERSION then
		return
	end

	local showContext = true
	local showFilters = true
	local showFarmlandValue = false

	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		self.mode = InGameMenuMapFrame.MODE_FARMLANDS

		self:generateFarmlandOverlay()

		showContext = false
		showFilters = false
		showFarmlandValue = true

		self.balanceText:setText(self.l10n:formatMoney(self.playerFarm:getBalance(), 0, true, true))
		self:resetFarmlandSelection()
		self:hideContextBox()
		self:showContextInput(false, false, false, false, false, false, false)
	else
		self.mode = InGameMenuMapFrame.MODE_OVERVIEW

		self:generateOverviewOverlay()
		self:setMapSelectionItem(self.currentHotspot)
	end

	self.filterBox:setVisible(showFilters)
	self.farmlandValueBox:setVisible(false)
	self:toggleFarmlandsHotspotFilterSettings(self.mode == InGameMenuMapFrame.MODE_FARMLANDS)

	if not GS_IS_MOBILE_VERSION then
		self:updateInputGlyphs()
	end

	self:resetUIDeadzones()
end

function InGameMenuMapFrame:onClickBuyFarmland()
	if GS_IS_MOBILE_VERSION then
		if self.selectedField ~= nil then
			return self:onClickBuyField(self.selectedField)
		end

		return
	end

	if self.selectedFarmland ~= nil then
		local price = self.selectedFarmland.price

		if price <= self.playerFarm:getBalance() then
			local text = string.format(self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND), self.l10n:formatMoney(price, 0, true, true))

			g_gui:showYesNoDialog({
				title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
				text = text,
				callback = self.onYesNoBuyFarmland,
				target = self
			})
		else
			g_gui:showInfoDialog({
				title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
				text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY)
			})
		end
	end
end

function InGameMenuMapFrame:onClickSellFarmland()
	if self:checkPlaceablesOnFarmland(self.selectedFarmland) then
		g_gui:showInfoDialog({
			title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND_TITLE),
			text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_CANNOT_SELL_WTIH_PLACEABLES)
		})
	else
		local price = self.selectedFarmland.price
		local text = string.format(self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND), self.l10n:formatMoney(price, 0, true, true))

		g_gui:showYesNoDialog({
			title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_SELL_FARMLAND_TITLE),
			text = text,
			callback = self.onYesNoSellFarmland,
			target = self
		})
	end
end

function InGameMenuMapFrame:onYesNoReset(yes)
	if yes and self.currentHotspot ~= nil then
		local vehicle = g_currentMission.nodeToObject[self.currentHotspot.linkNode]

		if vehicle ~= nil then
			local rootAttacherVehicle = vehicle:getRootVehicle()

			if not rootAttacherVehicle:getIsAIActive() then
				self.client:getServerConnection():sendEvent(ResetVehicleEvent:new(vehicle))
				self:selectFirstHotspot()
			else
				g_gui:showInfoDialog({
					text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_VEHICLE_IN_USE),
					callback = self.onInfoOkClick,
					target = self
				})
			end
		end
	end
end

function InGameMenuMapFrame:notifyPause()
	self:setMapSelectionItem(self.currentHotspot)
end

function InGameMenuMapFrame:selectFirstHotspot(allowedHotspots)
	if allowedHotspots == nil then
		allowedHotspots = InGameMenuMapFrame.HOTSPOT_VALID_CATEGORIES

		if GS_IS_MOBILE_VERSION then
			allowedHotspots = InGameMenuMapFrame.PAGE_HOTSPOTS[self.currentPage]
		end
	end

	local firstHotspot = self.ingameMapBase:cycleVisibleHotspot(nil, allowedHotspots, 1)

	self:setMapSelectionItem(firstHotspot)
end

function InGameMenuMapFrame:updateInputGlyphTransform(placeholderElement, inputGlyph)
	local width, height = unpack(placeholderElement.size)

	inputGlyph:setDimension(width, height)

	local posX, posY = unpack(placeholderElement.absPosition)
	posX = posX + width - inputGlyph:getWidth()
	posY = posY + (height - inputGlyph:getHeight()) * 0.5

	inputGlyph:setPosition(posX, posY)
end

function InGameMenuMapFrame:updateInputGlyphs()
	self:updateInputGlyphTransform(self.mapZoomGlyphPlaceholder, self.zoomInputGlyph)
	self:updateInputGlyphTransform(self.mapMoveGlyphPlaceholder, self.moveInputGlyph)

	local moveActions, moveText, zoomActions = nil

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		moveText = self.moveCursorText
		moveActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE,
			InputAction.AXIS_LOOK_UPDOWN_VEHICLE
		}
		zoomActions = {
			InputAction.AXIS_ACCELERATE_VEHICLE,
			InputAction.AXIS_BRAKE_VEHICLE
		}
	else
		moveText = self.panMapText
		moveActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_DRAG,
			InputAction.AXIS_LOOK_UPDOWN_DRAG
		}
		zoomActions = {
			InputAction.CAMERA_ZOOM_IN,
			InputAction.CAMERA_ZOOM_OUT
		}
	end

	self.moveInputGlyph:setActions(moveActions, moveText, self.glyphTextSize, true, true)
	self.zoomInputGlyph:setActions(zoomActions, self.zoomText, self.glyphTextSize, true, true)

	local switchText = ""

	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		switchText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.SWITCH_FARMLANDS)
	elseif self.mode == InGameMenuMapFrame.MODE_FARMLANDS then
		switchText = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.SWITCH_OVERVIEW)
	end

	self.buttonSwitchMapMode:setInputAction(InputAction.MENU_EXTRA_1)
	self.buttonSwitchMapMode:setText(switchText)
end

function InGameMenuMapFrame:onYesNoBuyFarmland(yes)
	if yes then
		local price = self.selectedFarmland.price

		if price <= self.playerFarm:getBalance() then
			self.client:getServerConnection():sendEvent(FarmlandStateEvent:new(self.selectedFarmland.id, g_currentMission:getFarmId(), price))
		end
	end
end

function InGameMenuMapFrame:onYesNoSellFarmland(yes)
	if yes then
		local price = self.selectedFarmland.price

		self.client:getServerConnection():sendEvent(FarmlandStateEvent:new(self.selectedFarmland.id, FarmlandManager.NO_OWNER_FARM_ID, price))
	end
end

function InGameMenuMapFrame:onPageChanged(page, fromPage)
	InGameMenuMapFrame:superClass().onPageChanged(self, page, fromPage)

	local vehicleBox = false
	local filterBox = false

	if page <= 3 then
		self.mapOverviewSelector:setState(page, true)
		self:setMapSelectionItem(nil)

		self.hideContentOverlay = false
		filterBox = true

		self:setTitle(self.l10n:getText("ui_ingameMenuMapOverview") .. " - " .. self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.MAP_PAGES[page]))
	elseif page == 4 then
		self.hideContentOverlay = true
		vehicleBox = true

		self:setTitle(self.l10n:getText("ui_ingameMenuMapOverview") .. " - " .. self.l10n:getText("ui_vehicles"))
	elseif page == 5 then
		self:setTitle(self.l10n:getText("ui_ingameMenuMapOverview") .. " - " .. self.l10n:getText("ui_fields"))
	elseif page == 6 then
		self:setTitle(self.l10n:getText("ui_pointsOfInterest"))
	end

	if page > 3 and (self.currentHotspot == nil or not InGameMenuMapFrame.PAGE_HOTSPOTS[self.currentPage][self.currentHotspot.category]) then
		self:selectFirstHotspot()
	end

	self.vehicleBox:setVisible(vehicleBox)
	self.filterBox:setVisible(filterBox)
	self.genericBox:setVisible(not vehicleBox and not filterBox)
end

function InGameMenuMapFrame:onClickBuyField(fieldId)
	local field = g_fieldManager:getFieldByIndex(fieldId)
	local farmland = field.farmland

	if self.farmlandManager:getFarmlandOwner(farmland.id) ~= g_currentMission:getFarmId() then
		local money = self.playerFarm:getBalance()
		local price = farmland.price

		if price <= money then
			local text = string.format(self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.MOBILE_BUY_FIELD_TEXT), self.l10n:formatMoney(money, 0, true, true), self.l10n:formatMoney(price, 0, true, true))

			g_gui:showYesNoDialog({
				title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
				text = text,
				callback = self.onYesNoBuyField,
				target = self
			})
		elseif self.shopController.inAppPurchaseController:getIsAvailable() then
			local text = string.format(self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.MOBILE_BUY_FIELD_TEXT_COINS), self.l10n:formatMoney(money, 0, true, true), self.l10n:formatMoney(price, 0, true, true))

			g_gui:showYesNoDialog({
				title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
				text = text,
				callback = self.onYesNoBuyCoins,
				target = self
			})

			self.toBuyField = nil
		else
			g_gui:showInfoDialog({
				title = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_TITLE),
				text = self.l10n:getText(InGameMenuMapFrame.L10N_SYMBOL.DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY)
			})
		end
	end

	self.toBuyField = field
end

function InGameMenuMapFrame:onYesNoBuyField(yes)
	if yes then
		self.client:getServerConnection():sendEvent(FarmlandStateEvent:new(self.toBuyField.farmland.id, g_currentMission:getFarmId(), self.toBuyField.farmland.price))
		self:setMapSelectionItem(self.currentHotspot)
	end

	self.toBuyField = nil
end

function InGameMenuMapFrame:onYesNoBuyCoins(yes)
	if yes then
		self.onClickBackCallback()
		g_currentMission.shopMenu:showCoinShop()
	end
end

function InGameMenuMapFrame:registerInput()
	self:unregisterInput()

	local eventId, state = self.inputManager:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onMenuActivate, false, true, false, true)
	eventId, state = self.inputManager:registerActionEvent(InputAction.MENU_CANCEL, self, self.onMenuCancel, false, true, false, true)
	eventId, state = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, true, 1)
	eventId, state = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, true, -1)

	if GS_IS_MOBILE_VERSION then
		eventId, state = self.inputManager:registerActionEvent(InputAction.MENU_AXIS_LEFT_RIGHT, self, self.onSwitchVehicleGeneric, false, true, false, true)
	end

	eventId, state = self.inputManager:registerActionEvent(InputAction.MENU_EXTRA_1, self, self.onClickSwitchMapMode, false, true, false, true)
	eventId, state = self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_IN, self, self.onZoomIn, false, true, true, true)
	eventId, state = self.inputManager:registerActionEvent(InputAction.CAMERA_ZOOM_OUT, self, self.onZoomOut, false, true, true, true)
end

function InGameMenuMapFrame:unregisterInput(customOnly)
	local list = customOnly and InGameMenuMapFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuMapFrame.CLEAR_INPUT_ACTIONS

	for _, actionName in pairs(list) do
		self.inputManager:removeActionEventsByActionName(actionName)
	end
end

function InGameMenuMapFrame:onZoomIn(x, y)
	self.ingameMap:zoom(1)
end

function InGameMenuMapFrame:onZoomOut()
	self.ingameMap:zoom(-1)
end

function InGameMenuMapFrame:onMenuActivate()
	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		if self.canEnter then
			self:onClickEnterVehicle()
		elseif self.canVisit then
			self:onClickVisitPlace()
		elseif GS_IS_MOBILE_VERSION and self.canBuy then
			self:onClickBuyField(self.selectedField)
		end
	elseif self.mode == InGameMenuMapFrame.MODE_FARMLANDS and self.canBuy then
		self:onClickBuyFarmland()
	end
end

function InGameMenuMapFrame:onMenuCancel()
	if self.mode == InGameMenuMapFrame.MODE_OVERVIEW then
		if self.canSetMarker then
			self:onClickTagPlace()
		elseif self.canReset then
			self:onClickResetVehicle()
		end
	elseif self.mode == InGameMenuMapFrame.MODE_FARMLANDS and self.canSell then
		self:onClickSellFarmland()
	end
end

function InGameMenuMapFrame:onSwitchVehicle(_, _, direction)
	local allowedHotspots = InGameMenuMapFrame.HOTSPOT_VALID_CATEGORIES

	if GS_IS_MOBILE_VERSION then
		allowedHotspots = InGameMenuMapFrame.PAGE_HOTSPOTS[self.currentPage]
	end

	local newHotspot = self.ingameMapBase:cycleVisibleHotspot(self.currentHotspot, allowedHotspots, direction)

	self:setMapSelectionItem(newHotspot)
end

function InGameMenuMapFrame:onSwitchVehicleGeneric(_, dir)
	if dir < 0 then
		self:onSwitchVehicle(nil, , -1)
	else
		self:onSwitchVehicle(nil, , 1)
	end
end

function InGameMenuMapFrame:onClickBack()
	self:onClickBackCallback()
end

InGameMenuMapFrame.HOTSPOT_VALID_CATEGORIES = {
	[MapHotspot.CATEGORY_VEHICLE_STEERABLE] = true,
	[MapHotspot.CATEGORY_VEHICLE_COMBINE] = true,
	[MapHotspot.CATEGORY_VEHICLE_TRAILER] = true,
	[MapHotspot.CATEGORY_VEHICLE_TOOL] = true,
	[MapHotspot.CATEGORY_TRIGGER] = true,
	[MapHotspot.CATEGORY_MISSION] = true,
	[MapHotspot.CATEGORY_DEFAULT] = true,
	[MapHotspot.CATEGORY_AI] = true,
	[MapHotspot.CATEGORY_FIELD_DEFINITION] = GS_IS_MOBILE_VERSION
}
InGameMenuMapFrame.PAGE_HOTSPOTS = {
	{},
	{},
	{},
	{
		[MapHotspot.CATEGORY_VEHICLE_TOOL] = true,
		[MapHotspot.CATEGORY_VEHICLE_TRAILER] = true,
		[MapHotspot.CATEGORY_VEHICLE_COMBINE] = true,
		[MapHotspot.CATEGORY_VEHICLE_STEERABLE] = true,
		[MapHotspot.CATEGORY_AI] = true
	},
	{
		[MapHotspot.CATEGORY_FIELD_DEFINITION] = true
	},
	{
		[MapHotspot.CATEGORY_DEFAULT] = true,
		[MapHotspot.CATEGORY_TRIGGER] = true
	}
}
InGameMenuMapFrame.GROUND_STATE_FILTER_COLOR_PROFILE = "ingameMenuMapFilterDynamicColorLarge"
InGameMenuMapFrame.CONTEXT_BOX_BOTTOM_FRAME_PROFILE = "ingameMenuMapContextBoxFrameBottom"
InGameMenuMapFrame.CONTEXT_BOX_TOP_FRAME_PROFILE = "ingameMenuMapContextBoxFrameTop"
InGameMenuMapFrame.HOTSPOT_FILTER_ICON_PROFILE = {
	[true] = {
		[MapHotspot.CATEGORY_VEHICLE_STEERABLE] = "ingameMenuMapFilterButtonIconSteerable",
		[MapHotspot.CATEGORY_VEHICLE_COMBINE] = "ingameMenuMapFilterButtonIconCombine",
		[MapHotspot.CATEGORY_VEHICLE_TRAILER] = "ingameMenuMapFilterButtonIconTrailer",
		[MapHotspot.CATEGORY_VEHICLE_TOOL] = "ingameMenuMapFilterButtonIconTool",
		[MapHotspot.CATEGORY_TRIGGER] = "ingameMenuMapFilterButtonIconTipping",
		[MapHotspot.CATEGORY_MISSION] = "ingameMenuMapFilterButtonIconFieldJobs",
		[MapHotspot.CATEGORY_DEFAULT] = "ingameMenuMapFilterButtonIconOther"
	},
	[false] = {
		[MapHotspot.CATEGORY_VEHICLE_STEERABLE] = "ingameMenuMapFilterButtonIconSteerableInactive",
		[MapHotspot.CATEGORY_VEHICLE_COMBINE] = "ingameMenuMapFilterButtonIconCombineInactive",
		[MapHotspot.CATEGORY_VEHICLE_TRAILER] = "ingameMenuMapFilterButtonIconTrailerInactive",
		[MapHotspot.CATEGORY_VEHICLE_TOOL] = "ingameMenuMapFilterButtonIconToolInactive",
		[MapHotspot.CATEGORY_TRIGGER] = "ingameMenuMapFilterButtonIconTippingInactive",
		[MapHotspot.CATEGORY_MISSION] = "ingameMenuMapFilterButtonIconFieldJobsInactive",
		[MapHotspot.CATEGORY_DEFAULT] = "ingameMenuMapFilterButtonIconOtherInactive"
	}
}
InGameMenuMapFrame.GLYPH_SIZE = {
	36,
	36
}
InGameMenuMapFrame.GLYPH_TEXT_SIZE = 20
InGameMenuMapFrame.GLYPH_COLOR = {
	1,
	1,
	1,
	1
}
InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION = {
	TOP_RIGHT = "topRight",
	BOTTOM_LEFT = "bottomLeft",
	BOTTOM_RIGHT = "bottomRight",
	TOP_LEFT = "topLeft"
}
InGameMenuMapFrame.CONTEXT_BOX_CORNER_ALIGNMENT = {
	[InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_RIGHT] = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT,
	[InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT] = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_LEFT,
	[InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT] = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_RIGHT,
	[InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.TOP_LEFT] = InGameMenuMapFrame.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
}
InGameMenuMapFrame.L10N_SYMBOL = {
	DIALOG_VEHICLE_RESET_DONE = "ui_vehicleResetDone",
	DIALOG_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse",
	REMOVE_MARKER = "action_untag",
	SWITCH_FARMLANDS = "ui_ingameMenuMapFarmlands",
	VEHICLE_RESET = "button_reset",
	DIALOG_BUY_FARMLAND_TITLE = "shop_messageBuyFarmlandTitle",
	DIALOG_VEHICLE_RESET_CONFIRM = "ui_wantToResetVehicleText",
	MAP_SELECTOR_GROWTH_STATES = "ui_mapOverviewGrowth",
	SWITCH_OVERVIEW = "ui_ingameMenuMapOverview",
	DIALOG_SELL_FARMLAND_TITLE = "shop_messageSellFarmlandTitle",
	INPUT_ZOOM_MAP = "ui_ingameMenuMapZoom",
	MOBILE_BUY_FIELD_TEXT = "ui_mobile_buyFieldDialogText",
	INPUT_PAN_MAP = "ui_ingameMenuMapPan",
	SET_MARKER = "action_tag",
	BUY_FIELD_TITLE = "shop_messageBuyFieldTitle",
	DIALOG_BUY_FARMLAND = "shop_messageBuyFarmlandText",
	DIALOG_SELL_FARMLAND = "shop_messageSellFarmlandText",
	DIALOG_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionGeneral",
	MAP_SELECTOR_FRUIT_TYPES = "ui_mapOverviewFruitTypes",
	MAP_SELECTOR_SOIL_STATES = "ui_mapOverviewSoil",
	DIALOG_CANNOT_SELL_WTIH_PLACEABLES = "shop_messageCannotSellFarmlandWithPlaceables",
	DIALOG_VEHICLE_RESET_FAILED = "ui_vehicleResetFailed",
	DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuyFarmland",
	MOBILE_BUY_FIELD_TEXT_COINS = "ui_mobile_buyFieldDialogText_buyCoins",
	INPUT_MOVE_CURSOR = "ui_ingameMenuMapMoveCursor",
	MAP_PAGES = {
		"ui_map_crops",
		"ui_map_growth",
		"ui_map_soil"
	}
}
InGameMenuMapFrame.PROFILE = {
	MONEY_VALUE_NEGATIVE = "ingameMenuMapMoneyValueNegative",
	MONEY_VALUE_NEUTRAL = "ingameMenuMapMoneyValue"
}
