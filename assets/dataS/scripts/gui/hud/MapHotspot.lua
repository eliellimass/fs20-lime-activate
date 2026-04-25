MapHotspot = {
	CATEGORY_DEFAULT = 0,
	CATEGORY_FIELD_DEFINITION = 1,
	CATEGORY_MISSION = 2,
	CATEGORY_TRIGGER = 3,
	CATEGORY_COLLECTABLE = 4,
	CATEGORY_AI = 5,
	CATEGORY_TOUR = 6,
	CATEGORY_VEHICLE_TOOL = 7,
	CATEGORY_VEHICLE_TRAILER = 8,
	CATEGORY_VEHICLE_COMBINE = 9,
	CATEGORY_VEHICLE_STEERABLE = 10,
	DEFAULT_COLOR = {
		1,
		1,
		1,
		1
	},
	DEFAULT_BG_COLOR = {
		1,
		1,
		1,
		1
	},
	SELECTED_COLOR = {
		0.2122,
		0.5271,
		0.0307,
		1
	},
	DEFAULT_FILE_SIZE = {
		2048,
		1024
	},
	DEFAULT_FILENAME = "dataS2/menu/hud/mapHotspots.png"
}
local MapHotspot_mt = Class(MapHotspot)

function MapHotspot.loadFromXML(xmlFile, key, rootNode, baseDirectory)
	local name = getXMLString(xmlFile, key .. "#name")

	if name == nil then
		return nil
	end

	local category = getXMLString(xmlFile, key .. "#category") or "CATEGORY_TRIGGER"
	local category = string.upper(category)
	local categoryIndex = MapHotspot[category]

	if categoryIndex == nil then
		g_logManager:xmlWarning(xmlFile, "Given MapHotspot category '%s' not found for '%s'", category, key .. "#category")

		return nil
	end

	local hotspot = MapHotspot:new(name, categoryIndex)
	local title = getXMLString(xmlFile, key .. "#title")

	if title ~= nil then
		hotspot:setText(title)
	end

	local function getUVs(xmlFile, key, defaultUVs)
		local refSize = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#filesize"), 2) or MapHotspot.DEFAULT_FILE_SIZE
		local uvStr = getXMLString(xmlFile, key .. "#uvs")
		local uvs = nil

		if uvStr ~= nil then
			uvStr = string.upper(uvStr)
			local defaultUVs = MapHotspot.UV[uvStr]

			if defaultUVs ~= nil then
				return defaultUVs
			end

			uvStr = string.lower(uvStr)
		end

		return GuiUtils.getUVs(uvStr, refSize, defaultUVs)
	end

	if hasXMLProperty(xmlFile, key .. ".icon") then
		local iconFilename = getXMLString(xmlFile, key .. ".icon#filename") or MapHotspot.DEFAULT_FILENAME
		iconFilename = Utils.getFilename(iconFilename, baseDirectory)
		local uvs = getUVs(xmlFile, key .. ".icon", Overlay.DEFAULT_UVS)
		local color = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".icon#color"), 4)
		local colorInactive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".icon#colorInactive"), 4)
		local colorSelected = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".icon#colorSelected"), 4)

		hotspot:setIcon(iconFilename, uvs, color, colorInactive, colorSelected)
		hotspot:setIconScale(getXMLFloat(xmlFile, key .. ".icon#scale"))
	end

	if hasXMLProperty(xmlFile, key .. ".background") then
		local backgroundFilename = getXMLString(xmlFile, key .. ".background#filename") or MapHotspot.DEFAULT_FILENAME
		backgroundFilename = Utils.getFilename(backgroundFilename, baseDirectory)
		local uvs = getUVs(xmlFile, key .. ".background", MapHotspot.UV.DEFAULT_CIRCLE)
		local color = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".background#color"), 4)
		local colorInactive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".background#colorInactive"), 4)
		local colorSelected = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".background#colorSelected"), 4)

		hotspot:setBackground(backgroundFilename, uvs, color, colorInactive, colorSelected)
	end

	local linkNode = rootNode

	if rootNode ~= nil then
		linkNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, key .. "#linkNode")) or rootNode
	end

	hotspot:setLinkedNode(linkNode)

	local xMapPos = getXMLFloat(xmlFile, key .. "#xMapPos")
	local zMapPos = getXMLFloat(xmlFile, key .. "#zMapPos")

	if xMapPos ~= nil and zMapPos ~= nil then
		hotspot:setWorldPosition(xMapPos, zMapPos)
	end

	local size = getXMLString(xmlFile, key .. "#size")

	if size ~= nil then
		local width, height = unpack(GuiUtils.getNormalizedValues(size, {
			g_referenceScreenWidth,
			g_referenceScreenHeight
		}))

		hotspot:setSize(width, height)
	end

	local textSizeStr = getXMLString(xmlFile, key .. ".text#size")

	if textSizeStr ~= nil then
		local textSize = GuiUtils.getNormalizedTextSize(textSizeStr)

		hotspot:setTextSize(textSize)
	end

	hotspot:setTextBold(getXMLBool(xmlFile, key .. ".text#bold"))
	hotspot:setTextColor(StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. ".text#color"), 4))

	local textAlignmentStr = getXMLString(xmlFile, key .. ".text#alignment")

	if textAlignmentStr ~= nil then
		textAlignmentStr = textAlignmentStr:lower()
		local textAlignment = RenderText.ALIGN_LEFT

		if textAlignmentStr == "right" then
			textAlignment = RenderText.ALIGN_RIGHT
		elseif textAlignmentStr == "center" then
			textAlignment = RenderText.ALIGN_CENTER
		end

		hotspot:setTextAlignment(textAlignment)
	end

	local textWrapWidth = getXMLString(xmlFile, key .. ".text#textWrapWidth")

	if textWrapWidth ~= nil then
		local width, _ = unpack(GuiUtils.getNormalizedValues(textWrapWidth, {
			g_referenceScreenWidth,
			g_referenceScreenHeight
		}))

		hotspot:setTextWrapWidth(width)
	end

	local textOffset = getXMLString(xmlFile, key .. ".text#offset")

	if textOffset ~= nil then
		local offsetX, offsetY = unpack(GuiUtils.getNormalizedValues(textOffset, {
			g_referenceScreenWidth,
			g_referenceScreenHeight
		}))

		hotspot:setTextOffset(offsetX, offsetY)
	end

	hotspot:setShowName(getXMLBool(xmlFile, key .. ".text#showName"))
	hotspot:setBlinking(getXMLBool(xmlFile, key .. "#blinking"))
	hotspot:setPersistent(getXMLBool(xmlFile, key .. "#persistent"))
	hotspot:setRenderLast(getXMLBool(xmlFile, key .. "#renderLast"))

	return hotspot
end

function MapHotspot:new(name, category)
	local self = setmetatable({}, MapHotspot_mt)
	self.name = name
	self.fullViewName = name
	self.icon = nil
	self.background = nil
	self.xMapPos = 0
	self.zMapPos = 0
	self.x = 0
	self.y = 0
	local size = GS_IS_MOBILE_VERSION and 60 or 18
	self.width, self.height = getNormalizedScreenValues(size, size)
	self.zoom = 1
	self.iconScale = 1
	self.linkNode = nil
	self.category = Utils.getNoNil(category, MapHotspot.CATEGORY_DEFAULT)
	self.ownerFarmId = AccessHandler.EVERYONE
	local _, textSize = getNormalizedScreenValues(0, GS_IS_MOBILE_VERSION and 16 or 12)
	self.textSize = textSize
	self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(0, 1)
	self.textBold = false
	self.textColor = {
		1,
		1,
		1,
		1
	}
	self.textAlignment = RenderText.ALIGN_CENTER
	self.textWrapWidth = 0
	self.showName = true
	self.isVisible = true
	self.enabled = true
	self.blinking = false
	self.persistent = false
	self.active = true
	self.renderLast = false
	self.hasDetails = true

	return self
end

function MapHotspot:delete()
	self.enabled = false

	if self.icon ~= nil then
		self.icon.overlay:delete()

		self.icon = nil
	end

	if self.background ~= nil then
		self.background.overlay:delete()

		self.background = nil
	end
end

function MapHotspot:getOverlay(height)
	return self.overlay
end

function MapHotspot:setSize(width, height)
	self.width = width or self.width
	self.height = height or self.height
end

function MapHotspot:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
end

function MapHotspot:setWorldPosition(x, z)
	self.xMapPos = x
	self.zMapPos = z
end

function MapHotspot:setLinkedNode(nodeId)
	self.linkNode = nodeId or nil

	if nodeId ~= nil then
		local x, _, z = getWorldTranslation(nodeId)
		self.zMapPos = z
		self.xMapPos = x
	end
end

function MapHotspot:setIcon(filename, uv, color, colorInactive, colorSelected)
	if self.icon ~= nil then
		self.icon.overlay:delete()
	end

	if filename == nil then
		self.icon = nil

		return
	end

	local icon = {
		filename = filename,
		uvs = uv or Overlay.DEFAULT_UVS,
		color = color or MapHotspot.DEFAULT_COLOR,
		colorInactive = colorInactive,
		colorSelected = colorSelected
	}
	local overlay = Overlay:new(filename, 0, 0, 1, 1)

	overlay:setUVs(icon.uvs)
	overlay:setColor(unpack(icon.color))

	icon.overlay = overlay
	self.icon = icon
end

function MapHotspot:setBackground(filename, uv, color, colorInactive, colorSelected)
	if self.background ~= nil then
		self.background.overlay:delete()
	end

	local background = {
		filename = filename,
		uvs = uv or Overlay.DEFAULT_UVS,
		color = color or MapHotspot.DEFAULT_BG_COLOR,
		colorInactive = colorInactive or MapHotspot.COLOR.INACTIVE,
		colorSelected = colorSelected or MapHotspot.SELECTED_COLOR
	}
	local overlay = Overlay:new(filename, 0, 0, 1, 1)

	overlay:setUVs(background.uvs)
	overlay:setColor(unpack(background.color))

	background.overlay = overlay
	self.background = background
end

function MapHotspot:setIconColor(color)
	local icon = self.icon

	if icon ~= nil then
		if color == nil then
			icon.overlay:setColor(nil, , , )
		else
			icon.overlay:setColor(color[1], color[2], color[3], nil)
		end
	end
end

function MapHotspot:setBackgroundColor(color)
	local background = self.background

	if background ~= nil then
		if color == nil then
			background.overlay:setColor(nil, , , 1)
		else
			background.overlay:setColor(color[1], color[2], color[3], nil)
		end
	end
end

function MapHotspot:setBlinking(blinking)
	self.blinking = blinking

	if not blinking then
		local background = self.background

		if background ~= nil then
			background.overlay:setColor(nil, , , 1)
		end

		local icon = self.icon

		if icon ~= nil then
			icon.overlay:setColor(nil, , , 1)
		end
	end
end

function MapHotspot:setIsVisible(isVisible)
	self.isVisible = isVisible
end

function MapHotspot:getIsVisible()
	return self.isVisible
end

function MapHotspot:setEnabled(isEnabled)
	self.enabled = isEnabled
end

function MapHotspot:getIsEnabled()
	return self.enabled
end

function MapHotspot:setIconScale(scale)
	self.iconScale = scale or 1
end

function MapHotspot:setRenderLast(bool)
	self.renderLast = Utils.getNoNil(bool, false)
end

function MapHotspot:setPersistent(persistent)
	self.persistent = Utils.getNoNil(persistent, false)
end

function MapHotspot:getIsActive()
	return self.ownerFarmId == AccessHandler.EVERYONE or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId)
end

function MapHotspot:setSelected(selected)
	self.isSelected = selected
end

function MapHotspot:setOwnerFarmId(farmId)
	if farmId == nil then
		farmId = AccessHandler.EVERYONE
	end

	self.ownerFarmId = farmId
end

function MapHotspot:getOwnerFarmId()
	return self.ownerFarmId
end

function MapHotspot:getHasDetails()
	return self.hasDetails
end

function MapHotspot:setHasDetails(hasDetails)
	self.hasDetails = Utils.getNoNil(hasDetails, self.hasDetails)
end

function MapHotspot:setShowName(showName)
	self.showName = Utils.getNoNil(showName, self.showName)
end

function MapHotspot:setText(name)
	self.fullViewName = g_i18n:convertText(name)
end

function MapHotspot:setTextOffset(x, y)
	self.textOffsetX = x or self.textOffsetX
	self.textOffsetY = y or self.textOffsetY
end

function MapHotspot:setRawTextOffset(textOffsetValue)
	local offX, offY = unpack(GuiUtils.getNormalizedValues(textOffsetValue, {
		g_referenceScreenWidth,
		g_referenceScreenHeight
	}))
	self.textOffsetX = offX
	self.textOffsetY = offY
end

function MapHotspot:setTextSize(textSize)
	self.textSize = textSize or self.textSize
end

function MapHotspot:setTextBold(textBold)
	self.textBold = Utils.getNoNil(textBold, self.textBold)
end

function MapHotspot:setTextColor(textColor)
	self.textColor = textColor or self.textColor
end

function MapHotspot:setTextColorSelected(textColorSelected)
	self.textColorSelected = textColorSelected
end

function MapHotspot:setTextAlignment(alignment)
	self.textAlignment = alignment or self.textAlignment
end

function MapHotspot:setTextWrapWidth(textWrapWidth)
	self.textWrapWidth = textWrapWidth or self.textWrapWidth
end

function MapHotspot:getWidth(addText, scale)
	scale = scale or 1
	local width = self.width * self.zoom * scale

	if addText and self.showName and self.fullViewName ~= "" then
		setTextWrapWidth(self.textWrapWidth)

		width = math.max(width, getTextWidth(self.textSize * self.zoom * scale, self.fullViewName))

		setTextWrapWidth(0)
	end

	return width
end

function MapHotspot:getHeight(addText, scale)
	scale = scale or 1
	local height = self.height * self.zoom * scale

	if addText and self.showName and self.fullViewName ~= "" then
		setTextWrapWidth(self.textWrapWidth)

		local textHeight, _ = getTextHeight(self.textSize * self.zoom * scale, self.fullViewName)

		setTextWrapWidth(0)

		height = math.max(height, textHeight)

		if self.textOffsetY < 0 then
			height = height - self.textOffsetY
		elseif height < self.textOffsetY then
			height = height + self.textOffsetY - height
		end
	end

	return height
end

function MapHotspot:getBoundings(addText, scale)
	addText = Utils.getNoNil(addText, true)
	scale = scale or 1
	local width = self:getWidth(addText, scale)
	local height = self:getHeight(addText, scale)

	return self.x, self.y, width, height
end

function MapHotspot:renderOverlay(overlayData, x, y, width, height)
	if overlayData ~= nil then
		local overlay = overlayData.overlay

		overlay:setDimension(width, height)
		overlay:setPosition(x, y)

		local color = overlayData.color

		if not self:getIsActive() then
			color = overlayData.colorInactive
		elseif self.isSelected then
			color = overlayData.colorSelected
		end

		overlay:setColor(unpack(color or overlayData.color))

		if self.blinking then
			overlay:setColor(nil, , , IngameMap.alpha)
		end

		overlay:render()

		return true
	end

	return false
end

function MapHotspot:render(minX, maxX, minY, maxY, scale, drawText)
	if self:getIsVisible() and self.enabled then
		scale = scale or 1
		local scaleChange = 1

		if self.isSelected and self.width > 0 then
			scaleChange = math.max(1 / self.width / 60, 1.1)
			scale = scale * scaleChange
		end

		local zoom = self.zoom
		local x, y, width, height = self:getBoundings(false, scale)

		if self.isSelected then
			x = x - (width - width / scaleChange) / 2
			y = y - (height - height / scaleChange) / 2
		end

		local halfX = g_currentMission.mapWidth * 0.5
		local halfZ = g_currentMission.mapHeight * 0.5
		local objectX = (self.xMapPos + halfX) / g_currentMission.mapWidth
		local objectZ = (self.zMapPos + halfZ) / g_currentMission.mapHeight
		local hasBackground = self:renderOverlay(self.background, x, y, width, height)

		if hasBackground then
			local bgWidth = width
			local bgHeight = height
			width = width * self.iconScale
			height = height * self.iconScale
			x = x + bgWidth * 0.5 - width * 0.5
			y = y + bgHeight * 0.5 - height * 0.5
		end

		self:renderOverlay(self.icon, x, y, width, height)

		local doRenderText = self.showName and self.fullViewName ~= "" and (drawText or self.renderLast)
		doRenderText = doRenderText or self.category == MapHotspot.CATEGORY_AI or self.category == MapHotspot.CATEGORY_FIELD_DEFINITION

		if doRenderText then
			setTextBold(self.textBold)
			setTextAlignment(self.textAlignment)
			setTextWrapWidth(self.textWrapWidth)

			local alpha = 1

			if self.blinking then
				alpha = IngameMap.alpha
			end

			setTextColor(0, 0, 0, 1)

			local textSize = self.textSize * zoom * scale
			local text = self.fullViewName
			local x = x

			if self.textAlignment == RenderText.ALIGN_RIGHT then
				x = x + width
			elseif self.textAlignment == RenderText.ALIGN_CENTER then
				x = x + width * 0.5
			end

			local posX = x + self.textOffsetX * self.zoom * scale
			local posY = self.y - (self.textSize - self.textOffsetY) * self.zoom * scale

			renderText(posX + 1 / g_screenWidth, posY - 1 / g_screenHeight, textSize, text)

			local textColor = self.textColor

			if not self:getIsActive() then
				textColor = self.textColorInactive
			elseif self.isSelected then
				textColor = self.textColorSelected
			end

			local r, g, b, _ = unpack(textColor or self.textColor)

			setTextColor(r, g, b, alpha)
			renderText(posX, posY, textSize, text)
			setTextAlignment(RenderText.ALIGN_LEFT)
			setTextWrapWidth(0)
			setTextColor(1, 1, 1, 1)
			setTextBold(false)
		end
	end
end

function MapHotspot:drawBoundings()
	local x, y, w, h = self:getBoundings()
	local xPixel = 1 / g_screenWidth
	local yPixel = 1 / g_screenHeight

	setOverlayColor(GuiElement.debugOverlay, 1, 0, 0, 1)
	renderOverlay(GuiElement.debugOverlay, x - xPixel, y - yPixel, w + 2 * xPixel, yPixel)
	renderOverlay(GuiElement.debugOverlay, x - xPixel, y + h, w + 2 * xPixel, yPixel)
	renderOverlay(GuiElement.debugOverlay, x - xPixel, y, xPixel, h)
	renderOverlay(GuiElement.debugOverlay, x + w, y, xPixel, h)
end

function MapHotspot:setAssociatedData(data)
	self.associatedData = data
end

function MapHotspot:getAssociatedData()
	return self.associatedData
end

MapHotspot.UV = {
	DEFAULT_SELLING_WOOL = GuiUtils.getUVs({
		0,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_SELLING = GuiUtils.getUVs({
		256,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_SELLING_VEHICLE = GuiUtils.getUVs({
		512,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_SELLING_ANIMAL = GuiUtils.getUVs({
		768,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_SELLING_BALE = GuiUtils.getUVs({
		1024,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_SELLING_BGA = GuiUtils.getUVs({
		1280,
		0,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_ANIMAL_PIG = GuiUtils.getUVs({
		0,
		256,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_ANIMAL_HORSE = GuiUtils.getUVs({
		256,
		256,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_ANIMAL_COW = GuiUtils.getUVs({
		512,
		256,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_ANIMAL_SHEEP = GuiUtils.getUVs({
		768,
		256,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_FUEL = GuiUtils.getUVs({
		0,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_BANK = GuiUtils.getUVs({
		256,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_FERTILIZER = GuiUtils.getUVs({
		512,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_SEEDS = GuiUtils.getUVs({
		768,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_FARM = GuiUtils.getUVs({
		1024,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_POI_WASHING = GuiUtils.getUVs({
		1280,
		512,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_NAV_POINTER = GuiUtils.getUVs({
		0,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_HELPER = GuiUtils.getUVs({
		256,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_MISSION = GuiUtils.getUVs({
		512,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_CIRCLE = GuiUtils.getUVs({
		768,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_HIGHLIGHT_MARKER = GuiUtils.getUVs({
		1024,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE),
	DEFAULT_FIELD_BUY = GuiUtils.getUVs({
		1280,
		768,
		256,
		256
	}, MapHotspot.DEFAULT_FILE_SIZE)
}
MapHotspot.COLOR = {
	INACTIVE = {
		0.3,
		0.3,
		0.3,
		1
	}
}
