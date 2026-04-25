FieldInfoDisplay = {}
local FieldInfoDisplay_mt = Class(FieldInfoDisplay, HUDDisplayElement)
FieldInfoDisplay.MAX_ROW_COUNT = 12
FieldInfoDisplay.INFO_TYPE = {
	OWNER = 1,
	FERTILIZATION = 4,
	FRUIT_TYPE = 2,
	FIELD_STATE = 3,
	WEED = 5,
	LIME_STATE = 7,
	PLOWING_STATE = 6,
	CUSTOM = FieldInfoDisplay.MAX_ROW_COUNT + 1
}
FieldInfoDisplay.LIME_REQUIRED_THRESHOLD = 0.25
FieldInfoDisplay.PLOWING_REQUIRED_THRESHOLD = 0.25
local NULL_SEPARATOR = {
	setVisible = function ()
	end
}

function FieldInfoDisplay.new(hudAtlasPath, l10n, fruitTypeManager, currentMission, farmManager, farmlandManager)
	local backgroundOverlay = FieldInfoDisplay.createBackground(hudAtlasPath)
	local self = FieldInfoDisplay:superClass().new(FieldInfoDisplay_mt, backgroundOverlay, nil)
	self.isEnabled = true
	self.l10n = l10n
	self.fruitTypeManager = fruitTypeManager
	self.currentMission = currentMission
	self.farmManager = farmManager
	self.farmlandManager = farmlandManager
	self.requestedFieldData = false
	self.rows = {}
	self.needResize = false
	self.displayLabelText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.DISPLAY_LABEL):upper()
	self.labelTextSize = 0
	self.rowTextSize = 0
	self.labelTextOffsetY = 0
	self.labelTextOffsetX = 0
	self.leftTextOffsetY = 0
	self.leftTextOffsetX = 0
	self.rightTextOffsetY = 0
	self.rightTextOffsetX = 0
	self.rowHeight = 0
	self.rowWidth = 0
	self.listMarginHeight = 0
	self.listMarginWidth = 0
	self.frameElement = nil
	self.rowListElement = nil
	self.separators = {}

	self:createComponents(hudAtlasPath)
	self:setupRows()

	return self
end

function FieldInfoDisplay:setupRows()
	for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
		table.insert(self.rows, {
			rightText = "",
			leftText = "",
			infoType = FieldInfoDisplay.INFO_TYPE.CUSTOM,
			leftColor = {
				unpack(FieldInfoDisplay.COLOR.TEXT_DEFAULT)
			}
		})
	end

	for _, infoType in pairs(FieldInfoDisplay.INFO_TYPE) do
		local infoTypeRow = self.rows[infoType]

		if infoTypeRow ~= nil then
			infoTypeRow.infoType = infoType
		end
	end
end

function FieldInfoDisplay:setEnabled(isEnabled)
	self.isEnabled = isEnabled

	if not isEnabled then
		self:clearFieldData()
	end
end

function FieldInfoDisplay:setPlayer(player)
	self.player = player
end

function FieldInfoDisplay:setFruitType(fruitTypeIndex, fruitGrowthState)
	local fruitTypeRow = self.rows[FieldInfoDisplay.INFO_TYPE.FRUIT_TYPE]
	local fieldStateRow = self.rows[FieldInfoDisplay.INFO_TYPE.FIELD_STATE]

	if fruitTypeIndex > 0 then
		local fruitType = self.fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		fruitTypeRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.FRUIT_TYPE)
		fruitTypeRow.rightText = fruitType.fillType.title
		local witheredState = fruitType.maxHarvestingGrowthState + 1

		if fruitType.maxPreparingGrowthState >= 0 then
			witheredState = fruitType.maxPreparingGrowthState + 1
		end

		local maxGrowingState = fruitType.minHarvestingGrowthState - 1

		if fruitType.minPreparingGrowthState >= 0 then
			maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
		end

		local text = ""

		if fruitGrowthState == fruitType.cutState + 1 then
			text = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.GROWTH_STATE_CUT)
		elseif fruitGrowthState == witheredState + 1 then
			text = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.GROWTH_STATE_WITHERED)
		elseif fruitGrowthState > 0 and fruitGrowthState <= maxGrowingState + 1 then
			text = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.GROWTH_STATE_GROWING)
		elseif fruitType.minPreparingGrowthState >= 0 and fruitType.minPreparingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxPreparingGrowthState + 1 then
			text = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.GROWTH_STATE_NEED_PREP)
		elseif fruitGrowthState >= fruitType.minHarvestingGrowthState + 1 and fruitGrowthState <= fruitType.maxHarvestingGrowthState + 1 then
			text = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.GROWTH_STATE_CAN_HARVEST)
		end

		if text ~= "" then
			fieldStateRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.FIELD_STATE)
			fieldStateRow.rightText = text
		else
			self:clearInfoRow(fieldStateRow)
		end
	else
		self:clearInfoRow(fruitTypeRow)
		self:clearInfoRow(fieldStateRow)
	end

	self.needResize = true
end

function FieldInfoDisplay:setFarmlandOwnerFarmId(farmlandId, ownerFarmId)
	local ownerRow = self.rows[FieldInfoDisplay.INFO_TYPE.OWNER]
	ownerRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.OWNED_BY)
	local farmName = nil

	if ownerFarmId == self.currentMission:getFarmId() and ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
		farmName = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.OWNER_YOU)
	elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
		local farmland = self.farmlandManager:getFarmlandById(farmlandId)

		if farmland == nil then
			farmName = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.OWNER_NOBODY)
		else
			local npc = farmland:getNPC()
			farmName = npc.title
		end
	else
		local farm = self.farmManager:getFarmById(ownerFarmId)

		if farm ~= nil then
			farmName = farm.name
		else
			farmName = "Unkown"
		end
	end

	ownerRow.rightText = farmName
	self.needResize = true
end

function FieldInfoDisplay:setFertilization(fertilizationFactor)
	local fertRow = self.rows[FieldInfoDisplay.INFO_TYPE.FERTILIZATION]

	if fertilizationFactor >= 0 then
		fertRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.FERTILIZATION)
		fertRow.rightText = string.format("%d %%", fertilizationFactor * 100)
	else
		self:clearInfoRow(fertRow)
	end

	self.needResize = true
end

function FieldInfoDisplay:setWeed(weedFactor)
	local weedRow = self.rows[FieldInfoDisplay.INFO_TYPE.WEED]

	if weedFactor >= 0 and g_currentMission.missionInfo.weedsEnabled then
		weedRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.WEED)
		weedRow.rightText = string.format("%d %%", weedFactor * 100)
	else
		self:clearInfoRow(weedRow)
	end

	self.needResize = true
end

function FieldInfoDisplay:setPlowingRequired(isRequired)
	local plowRow = self.rows[FieldInfoDisplay.INFO_TYPE.PLOWING_STATE]

	if isRequired and g_currentMission.missionInfo.plowingRequiredEnabled then
		plowRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.NEED_PLOWING)
		local highlightColor = FieldInfoDisplay.COLOR.TEXT_HIGHLIGHT

		for i = 1, 4 do
			plowRow.leftColor[i] = highlightColor[i]
		end
	else
		self:clearInfoRow(plowRow)
	end

	self.needResize = true
end

function FieldInfoDisplay:setLimeRequired(isRequired)
	local limeRow = self.rows[FieldInfoDisplay.INFO_TYPE.LIME_STATE]

	if isRequired and g_currentMission.missionInfo.limeRequired then
		limeRow.leftText = self.l10n:getText(FieldInfoDisplay.L10N_SYMBOL.NEED_LIME)
		local highlightColor = FieldInfoDisplay.COLOR.TEXT_HIGHLIGHT

		for i = 1, 4 do
			limeRow.leftColor[i] = highlightColor[i]
		end
	else
		self:clearInfoRow(limeRow)
	end

	self.needResize = true
end

function FieldInfoDisplay:addCustomText(leftText, rightText, leftColor)
	local customRowIndex = 0
	local row = nil

	for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
		row = self.rows[i]

		if row.infoType == FieldInfoDisplay.INFO_TYPE.CUSTOM and row.leftText == "" and row.rightText == "" then
			customRowIndex = i

			break
		end
	end

	if customRowIndex > 0 and customRowIndex <= FieldInfoDisplay.MAX_ROW_COUNT then
		row.leftText = leftText
		row.rightText = rightText or ""
		local color = leftColor or FieldInfoDisplay.COLOR.TEXT_DEFAULT

		for i = 1, 4 do
			row.leftColor[i] = color[i]
		end

		self.needResize = true
	end

	return customRowIndex
end

function FieldInfoDisplay:clearCustomText(rowIndex)
	if rowIndex ~= nil then
		if rowIndex > 0 and rowIndex <= FieldInfoDisplay.MAX_ROW_COUNT and self.rows[rowIndex].infoType == FieldInfoDisplay.INFO_TYPE.CUSTOM then
			self:clearInfoRow(self.rows[rowIndex])

			self.needResize = true
		end
	else
		for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
			local row = self.rows[i]

			if row.infoType == FieldInfoDisplay.INFO_TYPE.CUSTOM then
				self:clearInfoRow(row)
			end
		end

		self.needResize = true
	end
end

function FieldInfoDisplay:clearInfoRow(row)
	row.leftText = ""
	row.rightText = ""
	local defaultColor = FieldInfoDisplay.COLOR.TEXT_DEFAULT

	for i = 1, 4 do
		row.leftColor[i] = defaultColor[i]
	end
end

function FieldInfoDisplay:clearFieldData()
	for _, row in pairs(self.rows) do
		if row.infoType ~= FieldInfoDisplay.INFO_TYPE.CUSTOM then
			self:clearInfoRow(row)
		end
	end

	self.needResize = true
end

function FieldInfoDisplay:onFieldDataUpdateFinished(data)
	if not self.requestedFieldData then
		return
	end

	local hasData = data ~= nil

	if hasData then
		self:clearFieldData()
		self:setFarmlandOwnerFarmId(data.farmlandId, data.ownerFarmId)
		self:setLimeRequired(FieldInfoDisplay.LIME_REQUIRED_THRESHOLD < data.needsLimeFactor)
		self:setPlowingRequired(FieldInfoDisplay.PLOWING_REQUIRED_THRESHOLD < data.needsPlowFactor)
		self:setFertilization(data.fertilizerFactor)
		self:setWeed(data.weedFactor)

		local fruitIndex = 0
		local fruitState = 0
		local maxPixels = 0

		for fruitDescIndex, state in pairs(data.fruits) do
			if maxPixels < data.fruitPixels[fruitDescIndex] then
				maxPixels = data.fruitPixels[fruitDescIndex]
				fruitIndex = fruitDescIndex
				fruitState = state
			end
		end

		self:setFruitType(fruitIndex, fruitState)
	end

	self.requestedFieldData = false

	self:setVisible(hasData and self.player.isEntered)
end

function FieldInfoDisplay:update(dt)
	FieldInfoDisplay:superClass().update(self, dt)

	if self.isEnabled and self.player ~= nil and self.player.isEntered and not self.requestedFieldData then
		local posX, posY, posZ, rotY = self.player:getPositionData()
		local sizeX = 5
		local sizeZ = 5
		local distance = 2
		local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
		local sideX, _, sideZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
		local startWorldX = posX - sideX * sizeX * 0.5 - dirX * distance
		local startWorldZ = posZ - sideZ * sizeX * 0.5 - dirZ * distance
		local widthWorldX = posX + sideX * sizeX * 0.5 - dirX * distance
		local widthWorldZ = posZ + sideZ * sizeX * 0.5 - dirZ * distance
		local heightWorldX = posX - sideX * sizeX * 0.5 - dirX * (distance + sizeZ)
		local heightWorldZ = posZ - sideZ * sizeX * 0.5 - dirZ * (distance + sizeZ)
		self.requestedFieldData = true

		FSDensityMapUtil.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.onFieldDataUpdateFinished, self)
	end

	if self.needResize then
		self:updateSize()
	end
end

function FieldInfoDisplay:updateSize()
	for _, sep in pairs(self.separators) do
		sep:setVisible(false)
	end

	local rowCount = 0

	for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
		local row = self.rows[i]

		if row.leftText ~= "" or row.rightText ~= "" then
			rowCount = rowCount + 1

			if rowCount > 1 and rowCount < FieldInfoDisplay.MAX_ROW_COUNT then
				self.separators[rowCount]:setVisible(true)
			end
		end
	end

	local newListHeight = rowCount * self.rowHeight

	self.rowListElement:setDimension(self.rowListElement:getWidth(), newListHeight)

	local listWidth = self.rowListElement:getWidth()
	local listHeight = self.rowListElement:getHeight()
	local width = listWidth + self.listMarginWidth * 2
	local height = listHeight + self.listMarginHeight * 2

	self:setDimension(width, height)
	self.frameElement:setDimension(width, height)

	local posX, posY = FieldInfoDisplay.getBackgroundPosition(self.uiScale)

	self:setPosition(posX, posY)
	self.rowListElement:setPosition(posX + self.listMarginWidth, posY + self.listMarginHeight)

	self.needResize = false
end

function FieldInfoDisplay:reset()
	self.requestedFieldData = false

	self:setVisible(false)
	self:clearFieldData()
end

function FieldInfoDisplay:draw()
	if self.isEnabled and self:getVisible() then
		FieldInfoDisplay:superClass().draw(self)
		self:drawText()
	end
end

function FieldInfoDisplay:drawText()
	local posX, posY = self:getPosition()
	local labelPosX = posX + self.labelTextOffsetX
	local labelPosY = posY + self:getHeight() + self.labelTextOffsetY

	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(unpack(FieldInfoDisplay.COLOR.TEXT_DEFAULT))
	renderText(labelPosX, labelPosY, self.labelTextSize, self.displayLabelText)

	local listPosX, listPosY = self.rowListElement:getPosition()
	local listWidth = self.rowListElement:getWidth()
	local listHeight = self.rowListElement:getHeight()
	local rowPosY = listPosY + listHeight - self.rowHeight

	for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
		local row = self.rows[i]

		if row.leftText ~= "" or row.rightText ~= "" then
			local centerY = rowPosY + (self.rowHeight - self.rowTextSize) * 0.5
			local leftTextY = centerY + self.leftTextOffsetY
			local leftTextX = listPosX + self.leftTextOffsetX
			local rightTextY = centerY + self.rightTextOffsetY
			local rightTextX = listPosX + listWidth + self.rightTextOffsetX

			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			setTextColor(unpack(row.leftColor))
			renderText(leftTextX, leftTextY, self.rowTextSize, row.leftText)
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(unpack(FieldInfoDisplay.COLOR.TEXT_DEFAULT))
			renderText(rightTextX, rightTextY, self.rowTextSize, row.rightText)

			rowPosY = rowPosY - self.rowHeight
		end
	end
end

function FieldInfoDisplay.getBackgroundPosition(uiScale)
	local width, _ = getNormalizedScreenValues(unpack(FieldInfoDisplay.SIZE.SELF))
	local posX = 1 - g_safeFrameOffsetX - width * uiScale
	local posY = g_safeFrameOffsetY

	return posX, posY
end

function FieldInfoDisplay:setScale(uiScale)
	FieldInfoDisplay:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale

	self:storeScaledValues()
end

function FieldInfoDisplay:storeScaledValues()
	self.labelTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TITLE)
	self.rowTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.labelTextOffsetX, self.labelTextOffsetY = self:scalePixelToScreenVector(FieldInfoDisplay.POSITION.DISPLAY_LABEL)
	self.leftTextOffsetX, self.leftTextOffsetY = self:scalePixelToScreenVector(FieldInfoDisplay.POSITION.TEXT_LEFT)
	self.rightTextOffsetX, self.rightTextOffsetY = self:scalePixelToScreenVector(FieldInfoDisplay.POSITION.TEXT_RIGHT)
	self.rowWidth, self.rowHeight = self:scalePixelToScreenVector(FieldInfoDisplay.SIZE.ROW)
	self.listMarginWidth, self.listMarginHeight = self:scalePixelToScreenVector(FieldInfoDisplay.SIZE.ROW_LIST_MARGIN)
end

function FieldInfoDisplay.createBackground()
	local posX, posY = FieldInfoDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(FieldInfoDisplay.SIZE.SELF))

	return Overlay:new(nil, posX, posY, width, height)
end

function FieldInfoDisplay:createComponents(hudAtlasPath)
	local posX, posY = self:getPosition()
	self.frameElement = self:createFrame(hudAtlasPath, posX, posY)
	self.rowListElement = self:createRowListContainer(posX, posY)

	self:createSeparators(hudAtlasPath)
end

function FieldInfoDisplay:createFrame(hudAtlasPath, baseX, baseY)
	local width = self:getWidth()
	local height = self:getHeight()
	local frame = HUDFrameElement:new(hudAtlasPath, baseX, baseY, width, height)

	frame:setColor(unpack(HUD.COLOR.FRAME_BACKGROUND))
	self:addChild(frame)

	return frame
end

function FieldInfoDisplay:createRowListContainer(baseX, baseY)
	local listOffX, listOffY = self:scalePixelToScreenVector(FieldInfoDisplay.SIZE.ROW_LIST_MARGIN)
	local listWidth, listHeight = self:scalePixelToScreenVector(FieldInfoDisplay.SIZE.ROW_LIST)
	local listOverlay = Overlay:new(nil, baseX + listOffX, baseY + listOffY, listWidth, listHeight)
	local listElement = HUDElement:new(listOverlay)

	self:addChild(listElement)

	return listElement
end

function FieldInfoDisplay:createSeparators(hudAtlasPath)
	local listPosX, listPosY = self.rowListElement:getPosition()
	local sepWidth, sepHeight = self:scalePixelToScreenVector(FieldInfoDisplay.SIZE.SEPARATOR)
	sepHeight = math.max(sepHeight, 1 / g_screenHeight)
	local rowHeight = self:scalePixelToScreenHeight(FieldInfoDisplay.SIZE.ROW[2])

	for i = 1, FieldInfoDisplay.MAX_ROW_COUNT do
		local separatorElement = nil

		if i == 1 or i == FieldInfoDisplay.MAX_ROW_COUNT then
			separatorElement = NULL_SEPARATOR
		else
			local overlay = Overlay:new(hudAtlasPath, listPosX, listPosY, sepWidth, sepHeight)

			overlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
			overlay:setColor(unpack(InputHelpDisplay.COLOR.SEPARATOR))

			separatorElement = HUDElement:new(overlay)

			separatorElement:setVisible(false)
			self.rowListElement:addChild(separatorElement)
		end

		self.separators[i] = separatorElement
		listPosY = listPosY + rowHeight
	end
end

FieldInfoDisplay.POSITION = {
	DISPLAY_LABEL = {
		0,
		3
	},
	TEXT_LEFT = {
		0,
		2
	},
	TEXT_RIGHT = {
		0,
		2
	}
}
FieldInfoDisplay.SIZE = {
	SELF = {
		340,
		160
	},
	ROW_LIST_MARGIN = {
		30,
		15
	},
	ROW_LIST = {
		280,
		26
	},
	ROW = {
		280,
		26
	},
	SEPARATOR = {
		280,
		1
	}
}
FieldInfoDisplay.COLOR = {
	TEXT_DEFAULT = {
		1,
		1,
		1,
		1
	},
	TEXT_HIGHLIGHT = {
		0.991,
		0.3865,
		0.01,
		1
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.3
	}
}
FieldInfoDisplay.L10N_SYMBOL = {
	NEED_PLOWING = "ui_growthMapNeedsPlowing",
	FERTILIZATION = "ui_growthMapFertilized",
	OWNER_NOBODY = "fieldInfo_ownerNobody",
	WEED = "fillType_weed",
	FIELD_STATE = "ui_mapOverviewGrowth",
	OWNED_BY = "fieldInfo_ownedBy",
	NEED_LIME = "ui_growthMapNeedsLime",
	GROWTH_STATE_GROWING = "ui_growthMapGrowing",
	OWNER_YOU = "fieldInfo_ownerYou",
	GROWTH_STATE_WITHERED = "ui_growthMapWithered",
	FRUIT_TYPE = "statistic_fillType",
	DISPLAY_LABEL = "ui_fieldInfo",
	GROWTH_STATE_NEED_PREP = "ui_growthMapReadyToPrepareForHarvest",
	GROWTH_STATE_CAN_HARVEST = "ui_growthMapReadyToHarvest",
	GROWTH_STATE_CUT = "ui_growthMapCutted"
}
