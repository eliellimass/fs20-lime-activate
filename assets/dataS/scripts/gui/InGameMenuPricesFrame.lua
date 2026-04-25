InGameMenuPricesFrame = {}
local InGameMenuPricesFrame_mt = Class(InGameMenuPricesFrame, TabbedMenuFrameElement)
InGameMenuPricesFrame.CONTROLS = {
	TABLE_HEADER_BOX = "tableHeaderBox",
	PRICE_HEADERS = "priceHeader",
	PRICES_LIST_VERTICAL_SLIDER = "pricesListSlider",
	MAIN_BOX = "mainBox",
	PRICES_LIST_HORIZONTAL_SLIDER = "pricesListSliderHorizontal",
	PRICES_TABLE = "pricesTable"
}
InGameMenuPricesFrame.MAX_NUM_FILLTYPES = GS_IS_MOBILE_VERSION and 4 or 7
InGameMenuPricesFrame.MAX_NUM_PRICE_ROWS = GS_IS_MOBILE_VERSION and 6 or 14
InGameMenuPricesFrame.INPUT_CONTEXT_NAME = "MENU_PRICES"

function InGameMenuPricesFrame:new(subclass_mt, l10n, fillTypeManager)
	local subclass_mt = subclass_mt or InGameMenuPricesFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuPricesFrame.CONTROLS)

	self.l10n = l10n
	self.fillTypeManager = fillTypeManager
	self.dataBindings = {}
	self.sellingStations = {}
	self.stationIndex = 0
	self.startFillType = 1
	self.priceFillTypes = {}
	self.currentPriceTableRow = 1
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	return self
end

function InGameMenuPricesFrame:copyAttributes(src)
	InGameMenuPricesFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
	self.fillTypeManager = src.fillTypeManager
end

function InGameMenuPricesFrame:makeTableFocusOverrideFunction()
	if self.pricesListSliderHorizontal == nil then
		return function ()
		end
	end

	return function (target, direction)
		local doOverride = false
		local newTarget = nil
		local sliderValue = self.pricesListSliderHorizontal:getValue()

		if direction == FocusManager.RIGHT and sliderValue < self.pricesListSliderHorizontal:getMaxValue() then
			doOverride = true
			newTarget = self.pricesTable

			self.pricesListSliderHorizontal:setValue(sliderValue + 1)
		elseif direction == FocusManager.LEFT and sliderValue > 1 then
			doOverride = true
			newTarget = self.pricesTable

			self.pricesListSliderHorizontal:setValue(sliderValue - 1)
		end

		return doOverride, newTarget
	end
end

function InGameMenuPricesFrame:onFrameOpen()
	InGameMenuPricesFrame:superClass().onFrameOpen(self)
	self.tableHeaderBox:invalidateLayout()
	self:setupPriceTable()
	self:updatePriceTable()
	self:updateHeaderIcons()
	self:updateMenuButtons()
	FocusManager:setFocus(self.pricesTable)
end

function InGameMenuPricesFrame:initialize()
	self.hotspotButtonInfo = {
		profile = "buttonHotspot",
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function ()
			self:onButtonHotspot()
		end
	}
end

function InGameMenuPricesFrame:reset()
	InGameMenuPricesFrame:superClass().reset(self)

	self.arePricesInitialized = false
	self.isInputContextActive = false
end

function InGameMenuPricesFrame:toggleInput(isActive)
	if self.isInputContextActive ~= isActive then
		self.isInputContextActive = isActive

		self:toggleCustomInputContext(isActive, InGameMenuPricesFrame.INPUT_CONTEXT_NAME)

		if isActive then
			self:registerInput()
		end
	end
end

function InGameMenuPricesFrame:getStationName(sellingStation)
	local stationName = sellingStation.stationName

	if self.l10n:hasText(stationName, g_currentMission.missionInfo.customEnvironment) then
		stationName = self.l10n:getText(stationName, g_currentMission.missionInfo.customEnvironment)
	end

	return stationName
end

function InGameMenuPricesFrame.initialSortSellingStations(station1, station2)
	return station1.sortingName < station2.sortingName
end

function InGameMenuPricesFrame:setSellingStations(sellingStations)
	for k in pairs(self.sellingStations) do
		self.sellingStations[k] = nil
	end

	for _, sellingStation in pairs(sellingStations) do
		sellingStation.sortingName = self:getStationName(sellingStation)

		table.insert(self.sellingStations, sellingStation)
	end

	self:updateVerticalSlider()
	table.sort(self.sellingStations, InGameMenuPricesFrame.initialSortSellingStations)

	for _, sellingStation in pairs(self.sellingStations) do
		sellingStation.sortingName = nil
	end

	self:updatePriceTable()
end

function InGameMenuPricesFrame:updateVerticalSlider()
	if self.pricesListSlider ~= nil then
		local maxVerticalSliderValue = math.max(1, #self.sellingStations - InGameMenuPricesFrame.MAX_NUM_PRICE_ROWS)

		self.pricesListSlider:setMinValue(1)
		self.pricesListSlider:setMaxValue(maxVerticalSliderValue)

		local numVisibleItems = math.min(#self.sellingStations, InGameMenuPricesFrame.MAX_NUM_PRICE_ROWS)

		self.pricesListSlider:setSliderSize(numVisibleItems, #self.sellingStations)
	end
end

local function alwaysOverride()
	return true
end

function InGameMenuPricesFrame:setupPriceTable()
	if self.arePricesInitialized then
		return
	end

	self.pricesTable:initialize()

	self.priceFillTypes = {}

	for _, fillType in ipairs(self.fillTypeManager:getFillTypes()) do
		if fillType.showOnPriceTable then
			table.insert(self.priceFillTypes, fillType)
		end
	end

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(math.ceil(#self.priceFillTypes / InGameMenuPricesFrame.MAX_NUM_FILLTYPES))
	end

	if self.pricesListSliderHorizontal ~= nil then
		self.pricesListSliderHorizontal:setMinValue(1)
		self.pricesListSliderHorizontal:setMaxValue(#self.priceFillTypes - InGameMenuPricesFrame.MAX_NUM_FILLTYPES + 1)
		self.pricesListSliderHorizontal:setSliderSize(InGameMenuPricesFrame.MAX_NUM_FILLTYPES, #self.priceFillTypes)
	end

	self.pricesTable:setProfileOverrideFilterFunction(alwaysOverride)

	self.pricesTable.focusChangeOverride = self:makeTableFocusOverrideFunction()
	self.startFillType = 1
	self.arePricesInitialized = true
end

function InGameMenuPricesFrame:updatePriceTable()
	self.pricesTable:clearData()

	local dataRow = self:buildSiloRow("$l10n_ui_silos_owned", true, 10000000)

	self.pricesTable:addRow(dataRow)

	if not GS_IS_MOBILE_VERSION then
		dataRow = self:buildSiloRow("$l10n_ui_silos_extern", false, 900000, true)

		self.pricesTable:addRow(dataRow)
	end

	for _, station in ipairs(self.sellingStations) do
		if station.getAppearsOnStats ~= nil and station:getAppearsOnStats() then
			dataRow = self:buildDataRow(station)

			self.pricesTable:addRow(dataRow)
		end
	end

	self.pricesTable:updateView(false)
end

function InGameMenuPricesFrame:updateHeaderIcons()
	local headerIndex = 1

	for i = self.startFillType, self.startFillType + InGameMenuPricesFrame.MAX_NUM_FILLTYPES - 1 do
		local header = self.priceHeader[headerIndex]
		local fillType = self.priceFillTypes[i]

		if fillType ~= nil then
			header:setImageFilename(nil, fillType.hudOverlayFilename)
			header:setVisible(true)
		else
			header:setVisible(false)
		end

		headerIndex = headerIndex + 1
	end
end

function InGameMenuPricesFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}
	local hotspot = self:getSelectedHotspot()

	if hotspot ~= nil then
		if hotspot == g_currentMission.currentMapTargetHotspot then
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuPricesFrame.L10N_SYMBOL.REMOVE_MARKER)
		else
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuPricesFrame.L10N_SYMBOL.SET_MARKER)
		end

		table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuPricesFrame:getMainElementSize()
	return self.mainBox.size
end

function InGameMenuPricesFrame:getMainElementPosition()
	return self.mainBox.absPosition
end

function InGameMenuPricesFrame:onButtonHotspot()
	self:onDoubleClickPrices(self.pricesTable.selectedIndex)
end

function InGameMenuPricesFrame:onChangedPriceSlider(newValue)
	if newValue ~= self.startFillType then
		self.startFillType = newValue

		self.pricesTable:disableSorting()
		self:updateHeaderIcons()
		self:updatePriceTable()
	end
end

function InGameMenuPricesFrame:onClickPriceHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.pricesTable:setCustomSortFunction(InGameMenuPricesFrame.sortPrices, true)
	self.pricesTable:onClickHeader(element)
	self:updatePriceTable()
end

function InGameMenuPricesFrame:onClickSellingPointHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.pricesTable:setCustomSortFunction(nil)
	self.pricesTable:onClickHeader(element)
	self:updatePriceTable()
end

function InGameMenuPricesFrame:getSelectedHotspot()
	local selectedIndex = self.pricesTable.selectedIndex

	if selectedIndex < 1 then
		return nil
	end

	self.currentPriceTableRow = selectedIndex
	local sellingPointColumnName = self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SELLING_POINT]
	local cell = self.pricesTable:getViewDataCell(selectedIndex, sellingPointColumnName)

	if cell ~= nil and cell.value ~= nil then
		local sellingStation = cell.value

		return sellingStation.mapHotspot
	end

	return nil
end

function InGameMenuPricesFrame:onDoubleClickPrices(selectedIndex)
	if selectedIndex < 1 then
		return
	end

	local hotspot = self:getSelectedHotspot()

	if hotspot ~= nil then
		if g_currentMission.currentMapTargetHotspot == hotspot then
			g_currentMission:setMapTargetHotspot(nil)
		else
			g_currentMission:setMapTargetHotspot(hotspot)
		end

		self:updateMenuButtons()
	else
		g_currentMission:setMapTargetHotspot(nil)
	end

	self:updatePriceTable()
end

function InGameMenuPricesFrame:onSelectionChanged()
	if self.pricesTable ~= nil then
		self:updateMenuButtons()
	end
end

function InGameMenuPricesFrame:onPageChanged(page, fromPage)
	InGameMenuPricesFrame:superClass().onPageChanged(self, page, fromPage)

	self.startFillType = (page - 1) * InGameMenuPricesFrame.MAX_NUM_FILLTYPES + 1

	self:updateHeaderIcons()
	self:updatePriceTable()
end

InGameMenuPricesFrame.DATA_BINDING = {
	PRICE_TEMPLATE = "price%s",
	SELLING_POINT = "sellingPoint",
	SILO_CAPACITY_TEMPLATE = "capacity%s",
	SILO_CAPACITY_LABEL = "siloCapacityLabel"
}

function InGameMenuPricesFrame:onDataBindSellingPoint(element)
	self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SELLING_POINT] = element.name
end

function InGameMenuPricesFrame:onDataBindPrice(element, index)
	local dbKey = string.format(InGameMenuPricesFrame.DATA_BINDING.PRICE_TEMPLATE, index)
	self.dataBindings[dbKey] = element.name
end

function InGameMenuPricesFrame:onDataBindSiloCapacityLabel(element)
	self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SILO_CAPACITY_LABEL] = element.name
end

function InGameMenuPricesFrame:onDataBindSiloCapacityValue(element, index)
	local dbKey = string.format(InGameMenuPricesFrame.DATA_BINDING.SILO_CAPACITY_TEMPLATE, index)
	self.dataBindings[dbKey] = element.name
end

function InGameMenuPricesFrame:setSellingPointData(dataCell, sellingStation)
	local sellingPointProfile = InGameMenuPricesFrame.PROFILE.SELLING_POINT_CELL_NEUTRAL

	if g_currentMission.currentMapTargetHotspot ~= nil and sellingStation.mapHotspot == g_currentMission.currentMapTargetHotspot then
		sellingPointProfile = InGameMenuPricesFrame.PROFILE.SELLING_POINT_CELL_TAGGED
	elseif sellingStation.mapHotspot == nil then
		sellingPointProfile = InGameMenuPricesFrame.PROFILE.SELLING_POINT_CELL_NONE
	end

	dataCell.value = sellingStation
	dataCell.text = self:getStationName(sellingStation)
	dataCell.overrideProfileName = sellingPointProfile
end

function InGameMenuPricesFrame:setPriceData(dataCell, priceIndex, sellingStation)
	local displayFillTypeIndex = self.startFillType + priceIndex - 1

	if displayFillTypeIndex <= #self.priceFillTypes then
		local fillType = self.priceFillTypes[displayFillTypeIndex]
		local priceText = "-"
		local price = 0

		if sellingStation:getIsFillTypeAllowed(fillType.index) then
			price = tostring(sellingStation:getEffectiveFillTypePrice(fillType.index))
			priceText = self.l10n:formatMoney(price * 1000)
		end

		local priceTrend = sellingStation:getCurrentPricingTrend(fillType.index)
		local cellProfile = InGameMenuPricesFrame.PROFILE.PRICE_CELL_NEUTRAL

		if priceTrend ~= nil then
			if Utils.isBitSet(priceTrend, SellingStation.PRICE_GREAT_DEMAND) then
				cellProfile = InGameMenuPricesFrame.PROFILE.PRICE_CELL_GREAT_DEMAND
			elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_CLIMBING) then
				cellProfile = InGameMenuPricesFrame.PROFILE.PRICE_CELL_TREND_UP
			elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_FALLING) then
				cellProfile = InGameMenuPricesFrame.PROFILE.PRICE_CELL_TREND_DOWN
			end
		end

		dataCell.value = price
		dataCell.text = priceText
		dataCell.overrideProfileName = cellProfile
	end
end

function InGameMenuPricesFrame:buildDataRow(sellingStation)
	local dataRow = TableElement.DataRow:new(sellingStation.stationName, self.dataBindings)
	local sellingPointCell = dataRow.columnCells[self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SELLING_POINT]]

	self:setSellingPointData(sellingPointCell, sellingStation)

	for i = 1, InGameMenuPricesFrame.MAX_NUM_FILLTYPES do
		local dbKey = string.format(InGameMenuPricesFrame.DATA_BINDING.PRICE_TEMPLATE, i)
		local priceCell = dataRow.columnCells[self.dataBindings[dbKey]]

		self:setPriceData(priceCell, i, sellingStation)
	end

	return dataRow
end

function InGameMenuPricesFrame.sortPrices(sortCell1, sortCell2)
	return sortCell1.value - sortCell2.value
end

function InGameMenuPricesFrame:getStorageFillLevel(index, farmSilo)
	local totalCapacity = 0
	local usedCapacity = 0
	local displayFillTypeIndex = self.startFillType + index - 1

	if displayFillTypeIndex <= #self.priceFillTypes then
		local fillType = self.priceFillTypes[displayFillTypeIndex]
		local farmId = g_currentMission:getFarmId()

		for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
			if storage:getOwnerFarmId() == farmId and storage.foreignSilo ~= farmSilo and storage:getIsFillTypeSupported(fillType.index) then
				usedCapacity = usedCapacity + storage:getFillLevel(fillType.index)
				totalCapacity = totalCapacity + storage:getCapacity(fillType.index)
			end
		end
	end

	if totalCapacity > 0 then
		return usedCapacity, totalCapacity
	else
		return -1, -1
	end
end

function InGameMenuPricesFrame:buildSiloRow(title, farmSilos, priority, isLast)
	local dataRow = TableElement.DataRow:new(title, self.dataBindings)
	local siloNameCell = dataRow.columnCells[self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SELLING_POINT]]
	siloNameCell.text = self.l10n:convertText(title)
	siloNameCell.overrideProfileName = isLast and InGameMenuPricesFrame.PROFILE.SILO_NAME_LAST_ROW or InGameMenuPricesFrame.PROFILE.SILO_NAME
	local siloCapacityCell = dataRow.columnCells[self.dataBindings[InGameMenuPricesFrame.DATA_BINDING.SILO_CAPACITY_LABEL]]

	if not GS_IS_MOBILE_VERSION then
		siloCapacityCell.text = self.l10n:getText(InGameMenuPricesFrame.L10N_SYMBOL.SILO_CAPACITY)
	end

	siloCapacityCell.overrideProfileName = InGameMenuPricesFrame.PROFILE.SILO_CAPACITY_LABEL

	for i = 1, InGameMenuPricesFrame.MAX_NUM_FILLTYPES do
		local dbKey = string.format(InGameMenuPricesFrame.DATA_BINDING.PRICE_TEMPLATE, i)
		local siloCell = dataRow.columnCells[self.dataBindings[dbKey]]
		local capDbKey = string.format(InGameMenuPricesFrame.DATA_BINDING.SILO_CAPACITY_TEMPLATE, i)
		local capacityCell = dataRow.columnCells[self.dataBindings[capDbKey]]
		local fillLevel, capacity = self:getStorageFillLevel(i, farmSilos)

		if GS_IS_MOBILE_VERSION then
			siloCell.value = priority

			if fillLevel >= 0 then
				siloCell.text = string.format("%s (%d%%)", self.l10n:formatFluid(fillLevel), fillLevel / capacity * 100)
			else
				siloCell.text = "-"
			end
		else
			local fillLevelText = "-"
			local capacityText = "-"

			if fillLevel >= 0 then
				fillLevelText = self.l10n:formatFluid(fillLevel)
				capacityText = self.l10n:formatFluid(capacity)
			end

			siloCell.text = fillLevelText
			siloCell.overrideProfileName = isLast and InGameMenuPricesFrame.PROFILE.SILO_LITERS_LAST_ROW or InGameMenuPricesFrame.PROFILE.SILO_LITERS
			siloCell.value = priority
			capacityCell.text = capacityText
			capacityCell.overrideProfileName = InGameMenuPricesFrame.PROFILE.SILO_CAPACITY_VALUE
		end
	end

	return dataRow
end

InGameMenuPricesFrame.PROFILE = {
	PRICE_CELL_TREND_UP = "ingameMenuPriceRowPriceCellTrendUp",
	PRICE_CELL_GREAT_DEMAND = "ingameMenuPriceRowPriceCellGreatDemand",
	SILO_NAME = "ingameMenuPriceRowSiloNameCell",
	SILO_CAPACITY_LABEL = "ingameMenuPriceRowSiloCapacity",
	LITERS = "ingameMenuPriceRowLiters",
	PRICE_CELL_TREND_DOWN = "ingameMenuPriceRowPriceCellTrendDown",
	LITERS_LAST_ROW = "ingameMenuPriceRowLitersLastRow",
	SELLING_POINT_CELL_TAGGED = "ingameMenuPriceRowSellingPointCellTagged",
	SILO_LITERS = "ingameMenuPriceRowSiloLiters",
	SILO_LITERS_LAST_ROW = "ingameMenuPriceRowSiloLitersLastRow",
	SELLING_POINT_CELL_NONE = "ingameMenuPriceRowSellingPointCellNone",
	PRICE_CELL_NEUTRAL = "ingameMenuPriceRowPriceCell",
	SELLING_POINT_CELL_NEUTRAL = "ingameMenuPriceRowSellingPointCell",
	SILO_NAME_LAST_ROW = "ingameMenuPriceRowSiloNameCellLastRow",
	SILO_CAPACITY_VALUE = "ingameMenuPriceRowSiloCapacityValue"
}
InGameMenuPricesFrame.L10N_SYMBOL = {
	SET_MARKER = "action_tag",
	REMOVE_MARKER = "action_untag",
	SILO_CAPACITY = "ui_silos_totalCapacity"
}
