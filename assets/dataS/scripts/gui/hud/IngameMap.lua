IngameMap = {}
local IngameMap_mt = Class(IngameMap, HUDElement)
IngameMap.alpha = 1
IngameMap.alphaInc = 0.005
IngameMap.maxIconZoom = 1.4
IngameMap.STATE_MINIMAP = 0
IngameMap.STATE_MAP = 1
IngameMap.STATE_OFF = 2
IngameMap.STATE_SMALL = GS_IS_MOBILE_VERSION and 3 or 2
IngameMap.STATE_MEDIUM = GS_IS_MOBILE_VERSION and 3 or 0
IngameMap.STATE_LARGE = GS_IS_MOBILE_VERSION and 2 or 1
IngameMap.L10N_SYMBOL_TOGGLE_MAP = "input_TOGGLE_MAP_SIZE"
IngameMap.L10N_SYMBOL_SELECT_MAP = "input_INGAMEMAP_ACCEPT"
IngameMap.L10N_SYMBOL_MAP_LABEL = "ui_map"

function IngameMap.new(hud, hudAtlasPath, inputDisplayManager, customMt)
	local self = IngameMap:superClass().new(customMt or IngameMap_mt, nil, )
	self.overlay = self:createBackground()
	self.hud = hud
	self.hudAtlasPath = hudAtlasPath
	self.uiScale = 1
	self.inputDisplayManager = inputDisplayManager
	self.showPlayerCoordinates = true
	self.showMapLabel = true
	self.showInputIcon = true
	self.mapOverlay = Overlay:new(nil, 0, 0, 1, 1)
	self.mapElement = HUDElement:new(self.mapOverlay)
	self.mapFrameElement = nil
	self.toggleMapSizeGlyph = nil
	self.playerMapArrowElement = nil
	self.mapLabelText = utf8ToUpper(g_i18n:getText(IngameMap.L10N_SYMBOL_MAP_LABEL))
	self.selectHotspotText = g_i18n:getText(IngameMap.L10N_SYMBOL_SELECT_MAP)
	self.mapLabelOffsetY = 0
	self.mapLabelOffsetX = 0
	self.mapLabelTextSize = 0
	self.mapOffsetY = 0
	self.mapOffsetX = 0
	self.mapSizeY = 0
	self.mapSizeX = 0
	self.mapToFrameDiffY = 0
	self.mapToFrameDiffX = 0
	self.toggleSizeGlyphOffsetY = 0
	self.toggleSizeGlyphOffsetX = 0

	self:createComponents(hudAtlasPath)

	self.filter = {
		[MapHotspot.CATEGORY_DEFAULT] = true,
		[MapHotspot.CATEGORY_FIELD_DEFINITION] = true,
		[MapHotspot.CATEGORY_TRIGGER] = true,
		[MapHotspot.CATEGORY_COLLECTABLE] = true,
		[MapHotspot.CATEGORY_AI] = true,
		[MapHotspot.CATEGORY_TOUR] = true,
		[MapHotspot.CATEGORY_MISSION] = true,
		[MapHotspot.CATEGORY_VEHICLE_STEERABLE] = true,
		[MapHotspot.CATEGORY_VEHICLE_COMBINE] = true,
		[MapHotspot.CATEGORY_VEHICLE_TRAILER] = true,
		[MapHotspot.CATEGORY_VEHICLE_TOOL] = true
	}

	self:setWorldSize(2048, 2048)

	local uiScale = g_gameSettings:getValue("uiScale")
	self.mapPosX = g_safeFrameOffsetX
	self.mapPosY = g_safeFrameOffsetY
	self.minMapWidth, self.minMapHeight = getNormalizedScreenValues(unpack(IngameMap.SIZE.MAP))
	self.mapArrowWidth, self.mapArrowHeight = getNormalizedScreenValues(unpack(IngameMap.SIZE.PLAYER_ARROW))

	self:setSize(self.minMapWidth, self.minMapHeight)

	self.maxMapHeight = 0.7 - 2 * self.mapPosY
	self.maxMapWidth = self.maxMapHeight * g_screenHeight / g_screenWidth
	self.resizeTime = 100
	self.resizeDir = 0
	self.state = IngameMap.STATE_MINIMAP
	self.minMapVisWidth = 0.3
	self.maxMapVisWidth = 1
	self.iconZoom = 1.4
	self.maxIconZoom = IngameMap.maxIconZoom
	self.mapVisWidthMin = self.minMapVisWidth
	self.mapVisWidth = 0.1
	self.mapVisHeight = self.mapVisWidth / self.mapAspectRatio
	self.mapUVs = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	self.normalizedPlayerPosX = 0
	self.normalizedPlayerPosZ = 0
	self.playerRotation = 0
	self.centerXPos = 0
	self.centerZPos = 0
	self.hotspots = {}
	self.selectedHotspot = nil
	self.isVisible = true
	self.allowToggle = true
	self.topDownCamera = nil

	return self
end

function IngameMap:delete()
	IngameMap:superClass().delete(self)
	g_inputBinding:removeActionEventsByTarget(self)
	self.mapElement:delete()
	self.playerMapArrowElement:delete()
	self.mapArrowRedOverlay:delete()
	self:setSelectedHotspot(nil)

	for _, hotspot in pairs(self.hotspots) do
		hotspot:delete()
	end
end

function IngameMap:setFullscreen(isFullscreen)
	self.isFullscreen = isFullscreen

	if isFullscreen then
		self.mapVisWidthMin = 1
		self.centerXPos = 0
		self.centerZPos = 0
	end
end

function IngameMap:toggleSize(state, force)
	local newState = self.state + 1

	if IngameMap.STATE_OFF < newState then
		newState = IngameMap.STATE_MINIMAP
	end

	if state ~= nil and (force or self.state ~= IngameMap.STATE_OFF) then
		newState = state

		if state == IngameMap.STATE_MINIMAP and self.state == IngameMap.STATE_MAP then
			self.resizeDir = -1
		end
	end

	self.state = newState

	if newState == IngameMap.STATE_MAP then
		self.resizeDir = 1
	else
		self:resetSettings()
	end

	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.state == IngameMap.STATE_OFF)
	g_gameSettings:setValue("ingameMapState", newState)
end

function IngameMap:setTopDownCamera(guiTopDownCamera)
	self.topDownCamera = guiTopDownCamera
end

function IngameMap:setSelectedHotspot(hotspot)
	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(false)
	end

	self.selectedHotspot = hotspot

	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(true)
	end
end

function IngameMap:getHotspotIndex(hotspot)
	for i, spot in ipairs(self.hotspots) do
		if spot == hotspot then
			return i
		end
	end

	return -1
end

function IngameMap:cycleVisibleHotspot(currentHotspot, categoriesHash, direction)
	local currentIndex = self:getHotspotIndex(currentHotspot) + direction

	if currentIndex < 1 or currentIndex > #self.hotspots then
		if direction > 0 then
			currentIndex = 1
		else
			currentIndex = #self.hotspots
		end
	end

	local visitedCount = 0
	local hotspot = self.hotspots[currentIndex]

	while visitedCount < #self.hotspots do
		if hotspot:getIsVisible() and self.filter[hotspot.category] and categoriesHash[hotspot.category] and hotspot:getIsEnabled() then
			break
		end

		visitedCount = visitedCount + 1
		currentIndex = currentIndex + direction

		if currentIndex > #self.hotspots then
			currentIndex = 1
		elseif currentIndex < 1 then
			currentIndex = #self.hotspots
		end

		hotspot = self.hotspots[currentIndex]
	end

	if visitedCount < #self.hotspots then
		return hotspot
	else
		return nil
	end
end

function IngameMap:resetSettings()
	if self.overlay == nil then
		return
	end

	if self.state == IngameMap.STATE_MAP then
		self.mapWidth = self.maxMapWidth
		self.mapHeight = self.maxMapHeight
		self.mapVisWidthMin = self.maxMapVisWidth
		self.iconZoom = self.maxIconZoom
		self.mapAlpha = 0.7
	else
		self.mapWidth = self.minMapWidth
		self.mapHeight = self.minMapHeight
		self.mapVisWidthMin = self.minMapVisWidth
		self.iconZoom = self.maxIconZoom
		self.mapAlpha = 1
	end

	self:setScale(self.uiScale)

	local baseX, baseY = self:getBackgroundPosition()

	self:setPosition(baseX + self.mapOffsetX, baseY + self.mapOffsetY)
	self:setSize(self.mapWidth, self.mapHeight)
	self:setSelectedHotspot(nil)
end

function IngameMap:getIsFullSize()
	return self.state == IngameMap.STATE_MAP or self.isFullscreen and self.mapVisWidthMin <= 1
end

function IngameMap:getHeight()
	if self.state == IngameMap.STATE_OFF then
		return 0
	else
		return IngameMap:superClass().getHeight(self)
	end
end

function IngameMap:getRequiredHeight()
	return self:getHeight() + self.mapLabelTextSize + self.mapLabelOffsetY
end

function IngameMap:setSize(width, height)
	self.mapWidth = width
	self.mapHeight = height
	self.mapAspectRatio = self.mapWidth / (self.mapHeight / g_screenAspectRatio)

	self.mapOverlay:setDimension(width, height)

	self.mapArrowXPos = self.mapPosX + self.mapWidth / 2 - self.mapArrowWidth / 2
	self.mapArrowYPos = self.mapPosY + self.mapHeight / 2 - self.mapArrowHeight / 2

	self:setDimension(width + self.mapToFrameDiffX, height + self.mapToFrameDiffY)
	self.mapFrameElement:setDimension(self:getWidth(), self:getHeight())
end

function IngameMap:setPosition(posX, posY)
	posY = posY or self.mapPosY
	posX = posX or self.mapPosX

	IngameMap:superClass().setPosition(self, posX - self.mapOffsetX, posY - self.mapOffsetY)

	self.mapPosX = posX
	self.mapPosY = posY

	self.mapOverlay:setPosition(self.mapPosX, self.mapPosY)
end

function IngameMap:setAllowToggle(isAllowed)
	self.allowToggle = isAllowed

	if self.toggleMapSizeGlyph ~= nil then
		self.toggleMapSizeGlyph:setVisible(isAllowed)
	end
end

function IngameMap:zoom(zoomDiff)
	self.mapVisWidthMin = MathUtil.clamp(self.mapVisWidthMin + zoomDiff, self.minMapVisWidth, self.maxMapVisWidth)

	self:setSize(self.mapWidth, self.mapHeight)

	self.iconZoom = 1.2 + 1 - (self.mapVisWidthMin - self.minMapVisWidth) / (self.maxMapVisWidth - self.minMapVisWidth)

	self:setZoomScale(self.uiScale * self.iconZoom)
end

function IngameMap:setZoomScale(uniZoomScale)
	self.playerMapArrowElement:setScale(uniZoomScale, uniZoomScale)
	self.mapArrowRedOverlay:setScale(uniZoomScale, uniZoomScale)
end

function IngameMap:setIsVisible(isVisible)
	self.isVisible = isVisible

	g_inputBinding:setActionEventActive(self.toggleMapSizeEventId, isVisible)
end

function IngameMap:onToggleMapSize()
	if self.allowToggle and (not g_gui:getIsGuiVisible() or g_gui:getIsOverlayGuiVisible()) then
		self:toggleSize()
	end
end

function IngameMap:loadMap(filename, worldSizeX, worldSizeZ)
	self.mapElement:delete()
	self:setWorldSize(worldSizeX, worldSizeZ)

	local baseX, baseY = self:getPosition()
	local mapOverlay = Overlay:new(filename, baseX + self.mapOffsetX, baseY + self.mapOffsetY, self.mapSizeX, self.mapSizeY)
	self.mapOverlay = mapOverlay
	self.mapAlpha = 1
	local mapElement = HUDElement:new(mapOverlay)
	self.mapElement = mapElement

	self:setScale(self.uiScale)
end

function IngameMap:registerInput()
	local _, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_MAP_SIZE, self, self.onToggleMapSize, false, true, false, true)
	self.toggleMapSizeEventId = eventId

	g_inputBinding:setActionEventText(self.toggleMapSizeEventId, g_i18n:getText(IngameMap.L10N_SYMBOL_TOGGLE_MAP))
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.state == IngameMap.STATE_OFF)
	g_inputBinding:setActionEventTextPriority(self.toggleMapSizeEventId, GS_PRIO_VERY_LOW)
end

function IngameMap:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeX = worldSizeX
	self.worldSizeZ = worldSizeZ
	self.worldCenterOffsetX = self.worldSizeX * 0.5
	self.worldCenterOffsetZ = self.worldSizeZ * 0.5
end

function IngameMap:setMapObjectOverlayRotation(overlay, rotation)
	overlay:setRotation(rotation, overlay.width * 0.5, overlay.height * 0.5)
end

function IngameMap:determinePlayerPosition(player)
	return player:getPositionData()
end

function IngameMap:determineVehiclePosition(steerable)
	local posX, posY, posZ = getTranslation(steerable.rootNode)
	local dx, _, dz = localDirectionToWorld(steerable.rootNode, 0, 0, 1)
	local yRot = nil

	if steerable.spec_drivable ~= nil and steerable.spec_drivable.reverserDirection == -1 then
		yRot = MathUtil.getYRotationFromDirection(dx, dz)
	else
		yRot = MathUtil.getYRotationFromDirection(dx, dz) + math.pi
	end

	return posX, posY, posZ, yRot
end

function IngameMap:updateFilters()
	for category, _ in pairs(self.filter) do
		self:setFilter(category, not Utils.isBitSet(g_gameSettings:getValue("ingameMapFilter"), category))
	end
end

function IngameMap:setFilter(category, isActive)
	if category ~= nil then
		if isActive then
			g_gameSettings:setValue("ingameMapFilter", Utils.clearBit(g_gameSettings:getValue("ingameMapFilter"), category))
		else
			g_gameSettings:setValue("ingameMapFilter", Utils.setBit(g_gameSettings:getValue("ingameMapFilter"), category))
		end

		self.filter[category] = isActive
		self.hotspots_sorted = nil
	end
end

function IngameMap:addMapHotspot(mapHotspot)
	table.insert(self.hotspots, mapHotspot)

	if GS_IS_MOBILE_VERSION then
		local mapSize = 1024

		table.sort(self.hotspots, function (v1, v2)
			local band1 = math.ceil((v1.zMapPos + mapSize * 0.5) / (mapSize * 0.16666))
			local band2 = math.ceil((v2.zMapPos + mapSize * 0.5) / (mapSize * 0.16666))

			if band1 == band2 then
				return v1.xMapPos < v2.xMapPos or v1.xMapPos == v2.xMapPos and v1.zMapPos < v2.zMapPos
			else
				return band1 - band2 < 0
			end
		end)
	else
		table.sort(self.hotspots, function (v1, v2)
			return v2.category < v1.category
		end)
	end

	self.hotspots_sorted = nil

	return mapHotspot
end

function IngameMap:removeMapHotspot(mapHotspot)
	if mapHotspot ~= nil then
		for i = 1, table.getn(self.hotspots) do
			if self.hotspots[i] == mapHotspot then
				table.remove(self.hotspots, i)

				break
			end
		end

		if self.selectedHotspot == mapHotspot then
			self:setSelectedHotspot(nil)
		end

		if g_currentMission ~= nil and g_currentMission.currentMapTargetHotspot == mapHotspot then
			g_currentMission:setMapTargetHotspot(nil)
		end

		mapHotspot.enabled = false
		self.hotspots_sorted = nil
	end
end

function IngameMap:setMapObjectOverlayPosition(overlay, objectX, objectZ, width, height, enabled, persistent, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	local centerX = self.centerXPos
	local centerZ = self.centerZPos
	local halfMapWidth = self.mapVisWidth * 0.5
	local halfMapHeight = self.mapVisHeight * 0.5
	local visible = true
	overlay.x = self.mapPosX + self.mapWidth / 2 - width / 2
	overlay.y = self.mapPosY + self.mapHeight / 2 - height / 2

	if not leftBorderReached and not rightBorderReached then
		overlay.x = overlay.x + (objectX - centerX) * self.mapWidth / self.mapVisWidth
	elseif leftBorderReached then
		overlay.x = overlay.x + (objectX - halfMapWidth) * self.mapWidth / self.mapVisWidth
		overlay.x = math.max(overlay.x, self.mapPosX)
	else
		overlay.x = overlay.x + (objectX - (1 - halfMapWidth)) * self.mapWidth / self.mapVisWidth
		overlay.x = math.min(overlay.x, self.mapPosX + self.mapWidth - width)
	end

	if not topBorderReached and not bottomBorderReached then
		overlay.y = overlay.y - (objectZ - centerZ) * self.mapHeight / self.mapVisHeight
	elseif topBorderReached then
		overlay.y = overlay.y - (objectZ - halfMapHeight) * self.mapHeight / self.mapVisHeight
		overlay.y = math.min(overlay.y, self.mapPosY + self.mapHeight - height)
	else
		overlay.y = overlay.y - (objectZ - (1 - halfMapHeight)) * self.mapHeight / self.mapVisHeight
		overlay.y = math.max(overlay.y, self.mapPosY)
	end

	local overlayX = overlay.x
	local overlayY = overlay.y
	local overlayWidth = width
	local overlayHeight = height

	if overlay.getBoundings ~= nil then
		overlayX, overlayY, overlayWidth, overlayHeight = overlay:getBoundings()
	end

	if not persistent and (overlayX < self.mapPosX or overlayX + overlayWidth > self.mapPosX + self.mapWidth or overlayY < self.mapPosY or overlayY + overlayHeight > self.mapPosY + self.mapHeight) then
		visible = false
	end

	if persistent and enabled then
		local deltaX = objectX - centerX
		local deltaY = objectZ - centerZ
		local dir = 1000000

		if math.abs(deltaY) > 0.0001 then
			dir = deltaX / deltaY
		end

		if overlay.y > self.mapPosY + self.mapHeight - height then
			overlay.y = self.mapPosY + self.mapHeight - height
			overlay.x = self.mapPosX + self.mapWidth / 2 - width / 2
			overlay.x = overlay.x - dir * (self.mapHeight / 2 - 1.4 * height)
		end

		if overlay.y < self.mapPosY then
			overlay.y = self.mapPosY
			overlay.x = self.mapPosX + self.mapWidth / 2 - width / 2
			overlay.x = overlay.x + dir * (self.mapHeight / 2 - 1.125 * height)
		end

		if overlay.x > self.mapPosX + self.mapWidth - width then
			overlay.x = self.mapPosX + self.mapWidth - width
			overlay.y = self.mapPosY + self.mapHeight / 2 - height / 2
			overlay.y = overlay.y - 1 / dir * (self.mapWidth / 2 + width * 2)

			if overlay.y > self.mapPosY + self.mapHeight - height then
				overlay.y = self.mapPosY + self.mapHeight - height
			end

			if overlay.y < self.mapPosY then
				overlay.y = self.mapPosY
			end
		end

		if overlay.x < self.mapPosX then
			overlay.x = self.mapPosX
			overlay.y = self.mapPosY + self.mapHeight / 2 - height / 2
			overlay.y = overlay.y + 1 / dir * (self.mapWidth / 2 + width * 2)

			if overlay.y > self.mapPosY + self.mapHeight - height then
				overlay.y = self.mapPosY + self.mapHeight - height
			end

			if overlay.y < self.mapPosY then
				overlay.y = self.mapPosY
			end
		end
	end

	return visible
end

function IngameMap:update(dt)
	if self.showInputIcon then
		self:updateInputGlyphs()
	end

	if self.hotspots_sorted == nil then
		self.hotspots_sorted = {
			[true] = {},
			[false] = {}
		}

		for _, currentHotspot in pairs(self.hotspots) do
			if self.filter[currentHotspot.category] then
				table.insert(self.hotspots_sorted[currentHotspot.renderLast], currentHotspot)
			end
		end
	end

	if self.state ~= IngameMap.STATE_OFF then
		self:updatePlayerPosition()
		self:updateMapAnimation(dt)
	end

	IngameMap.alpha = IngameMap.alpha + IngameMap.alphaInc * dt

	if IngameMap.alpha > 1 then
		IngameMap.alphaInc = -IngameMap.alphaInc
		IngameMap.alpha = 1
	elseif IngameMap.alpha < 0 then
		IngameMap.alphaInc = -IngameMap.alphaInc
		IngameMap.alpha = 0
	end
end

function IngameMap:updateMapAnimation(dt)
	if self.resizeDir ~= 0 then
		local deltaTime = dt

		if not self.isVisible then
			deltaTime = self.resizeTime * 2
		end

		local newValues = Utils.getMovedLimitedValues({
			self.mapWidth,
			self.mapHeight,
			self.mapVisWidthMin,
			self.mapAlpha
		}, {
			self.maxMapWidth,
			self.maxMapHeight,
			self.maxMapVisWidth,
			0.7
		}, {
			self.minMapWidth,
			self.minMapHeight,
			self.minMapVisWidth,
			1
		}, 4, self.resizeTime, deltaTime, self.resizeDir ~= 1)
		self.mapVisWidthMin = newValues[3]
		self.mapAlpha = newValues[4]

		self:setSize(newValues[1], newValues[2])

		if self.mapVisWidthMin == self.maxMapVisWidth or self.mapVisWidthMin == self.minMapVisWidth then
			self.resizeDir = 0
		end
	end
end

function IngameMap:updatePlayerPosition()
	local playerPosX = 0
	local playerPosY = 0
	local playerPosZ = 0

	if self.topDownCamera ~= nil then
		playerPosX, playerPosY, playerPosZ, self.playerRotation = self.topDownCamera:determineMapPosition()
	elseif g_currentMission.controlPlayer then
		if g_currentMission.player ~= nil then
			playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determinePlayerPosition(g_currentMission.player)
		end
	elseif g_currentMission.controlledVehicle ~= nil then
		playerPosX, playerPosY, playerPosZ, self.playerRotation = self:determineVehiclePosition(g_currentMission.controlledVehicle)
	end

	self.normalizedPlayerPosX = MathUtil.clamp((playerPosX + self.worldCenterOffsetX) / self.worldSizeX, 0, 1)
	self.normalizedPlayerPosZ = MathUtil.clamp((playerPosZ + self.worldCenterOffsetZ) / self.worldSizeZ, 0, 1)
end

function IngameMap:updatePlayerArrow(centerPlayer, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	local r, g, b = self:colorForFarm(g_currentMission.player.farmId)

	if self.mapVisWidth > 0.5 then
		self.playerMapArrowOverlay:setColor(r, g, b, IngameMap.alpha)
	else
		self.playerMapArrowOverlay:setColor(r, g, b, 1)
	end

	self.playerMapArrowElement:setVisible(true)

	if centerPlayer then
		self.playerMapArrowOverlay.x = self.mapPosX + self.mapWidth * 0.5 - self.playerMapArrowOverlay.width * 0.5
		self.playerMapArrowOverlay.y = self.mapPosY + self.mapHeight * 0.5 - self.playerMapArrowOverlay.height * 0.5

		if leftBorderReached then
			self.playerMapArrowOverlay.x = self.mapPosX + self.mapWidth * 0.5 * self.normalizedPlayerPosX / (self.mapVisWidth * 0.5) - self.playerMapArrowOverlay.width * 0.5
		elseif rightBorderReached then
			self.playerMapArrowOverlay.x = self.mapPosX + self.mapWidth * (1 - 0.5 * (1 - self.normalizedPlayerPosX) / (self.mapVisWidth * 0.5)) - self.playerMapArrowOverlay.width * 0.5
		end

		if topBorderReached then
			self.playerMapArrowOverlay.y = self.mapPosY + self.mapHeight * (1 - 0.5 * self.normalizedPlayerPosZ / (self.mapVisHeight * 0.5)) - self.playerMapArrowOverlay.height * 0.5
		elseif bottomBorderReached then
			self.playerMapArrowOverlay.y = self.mapPosY + self.mapHeight * 0.5 * (1 - self.normalizedPlayerPosZ) / (self.mapVisHeight * 0.5) - self.playerMapArrowOverlay.height * 0.5
		end

		self.playerMapArrowOverlay.x = MathUtil.clamp(self.playerMapArrowOverlay.x, self.mapPosX, self.mapPosX + self.mapWidth - self.mapArrowWidth)
		self.playerMapArrowOverlay.y = MathUtil.clamp(self.playerMapArrowOverlay.y, self.mapPosY, self.mapPosY + self.mapHeight - self.mapArrowHeight)

		self:setMapObjectOverlayRotation(self.playerMapArrowOverlay, self.playerRotation)
	elseif self:setMapObjectOverlayPosition(self.playerMapArrowOverlay, self.normalizedPlayerPosX, self.normalizedPlayerPosZ, self.playerMapArrowOverlay.width, self.playerMapArrowOverlay.height, true, false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached) then
		self:setMapObjectOverlayRotation(self.playerMapArrowOverlay, self.playerRotation)
	else
		self.playerMapArrowElement:setVisible(false)
	end
end

function IngameMap:updateMapHeightZoomFactor()
	self.mapVisWidth = math.min(self.mapVisWidthMin, 1)
	self.mapVisHeight = math.min(self.mapVisWidth / self.mapAspectRatio, 1)
	local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = self:updateMapUVs()

	return leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached
end

function IngameMap:updateInputGlyphs()
	self.toggleMapSizeGlyph:setAction(InputAction.TOGGLE_MAP_SIZE)

	local baseX, baseY = self:getPosition()
	local baseWidth = self:getWidth()
	local baseHeight = self:getHeight()
	local width = self.toggleMapSizeGlyph:getWidth()
	local posX = baseX + baseWidth - width - self.toggleSizeGlyphOffsetX
	local posY = baseY + baseHeight + self.toggleSizeGlyphOffsetY

	self.toggleMapSizeGlyph:setPosition(posX, posY)
end

function IngameMap:updateMapUVs()
	local leftBorderReached = false
	local rightBorderReached = false
	local topBorderReached = false
	local bottomBorderReached = false
	local x = self.centerXPos
	local y = self.centerZPos
	self.mapUVs[1] = x - self.mapVisWidth / 2
	self.mapUVs[2] = 1 - y - self.mapVisHeight / 2
	self.mapUVs[3] = self.mapUVs[1]
	self.mapUVs[4] = 1 - y + self.mapVisHeight / 2
	self.mapUVs[5] = x + self.mapVisWidth / 2
	self.mapUVs[6] = 1 - y - self.mapVisHeight / 2
	self.mapUVs[7] = self.mapUVs[5]
	self.mapUVs[8] = 1 - y + self.mapVisHeight / 2

	if self.mapUVs[1] <= 0 then
		leftBorderReached = true
		self.centerXPos = x - self.mapUVs[1]
		self.mapUVs[1] = 0
		self.mapUVs[3] = self.mapUVs[1]
		self.mapUVs[5] = self.mapVisWidth
		self.mapUVs[7] = self.mapUVs[5]
	end

	if self.mapUVs[5] >= 1 then
		rightBorderReached = true
		self.centerXPos = x - (self.mapUVs[1] - (1 - self.mapVisWidth))
		self.mapUVs[1] = 1 - self.mapVisWidth
		self.mapUVs[3] = self.mapUVs[1]
		self.mapUVs[5] = 1
		self.mapUVs[7] = self.mapUVs[5]
	end

	if self.mapUVs[2] <= 0 then
		bottomBorderReached = true
		self.centerZPos = y + self.mapUVs[2]
		self.mapUVs[2] = 0
		self.mapUVs[6] = self.mapUVs[2]
		self.mapUVs[4] = self.mapVisHeight
		self.mapUVs[8] = self.mapUVs[4]
	end

	if self.mapUVs[4] >= 1 then
		topBorderReached = true
		self.centerZPos = y + self.mapUVs[2] - (1 - self.mapVisHeight)
		self.mapUVs[2] = 1 - self.mapVisHeight
		self.mapUVs[6] = self.mapUVs[2]
		self.mapUVs[4] = 1
		self.mapUVs[8] = self.mapUVs[4]
	end

	setOverlayUVs(self.mapOverlay.overlayId, self.mapUVs[1], self.mapUVs[2], self.mapUVs[3], self.mapUVs[4], self.mapUVs[5], self.mapUVs[6], self.mapUVs[7], self.mapUVs[8])

	return leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached
end

function IngameMap:draw()
	if self.isVisible and self.state ~= IngameMap.STATE_OFF then
		local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = self:updateMapHeightZoomFactor()

		self:drawMap(self.mapAlpha, true)
		self:updatePlayerArrow(self.state == IngameMap.STATE_MINIMAP, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)

		self.centerXPos = self.normalizedPlayerPosX
		self.centerZPos = self.normalizedPlayerPosZ

		self:drawPointsOfInterest(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
		self:drawPlayerArrow()

		if self.showPlayerCoordinates then
			self:drawPlayersCoordinates()
		end

		self:drawLatencyToServer()

		if self.showMapLabel then
			self:drawMapLabel()
		end

		IngameMap:superClass().draw(self)
	end
end

function IngameMap:drawPlayerArrow()
	self.playerMapArrowElement:draw()
end

function IngameMap:drawMapLabel()
	setTextColor(unpack(IngameMap.COLOR.MAP_LABEL))
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)

	local baseX, baseY = self:getPosition()
	local height = self:getHeight()
	local posX = baseX + self.mapLabelOffsetX
	local posY = baseY + height + self.mapLabelOffsetY

	renderText(posX, posY, self.mapLabelTextSize, self.mapLabelText)
end

function IngameMap:drawMap(alpha, isStandalone)
	self.mapOverlay:setColor(nil, , , alpha or self.mapAlpha)
	self.mapElement:draw()
end

function IngameMap:drawPointsOfInterest(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, false, self:getIsFullSize())
	self:drawOtherPlayerArrows(self:getIsFullSize(), leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self:drawEnterableArrows(self:getIsFullSize(), leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true, self:getIsFullSize())

	if self.selectedHotspot ~= nil then
		slot7 = self
		slot5 = self.drawHotspot
		slot8 = self.selectedHotspot
		slot9 = leftBorderReached
		slot10 = rightBorderReached
		slot11 = topBorderReached
		slot12 = bottomBorderReached
		slot13 = false

		if false then
			slot13 = self:getIsFullSize()
		end

		slot5(slot7, slot8, slot9, slot10, slot11, slot12, slot13)
	end
end

function IngameMap:colorForFarm(farmId)
	local farm = g_farmManager:getFarmById(farmId)

	if farm ~= nil then
		local color = Farm.COLORS[farm.color]

		if color ~= nil then
			return color[1], color[2], color[3], color[4]
		end
	end

	return 1, 1, 1, 1
end

function IngameMap:drawOtherPlayerArrows(showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	for _, player in pairs(g_currentMission.players) do
		if player.isControlled and not player.isEntered and player ~= g_currentMission.player then
			local posX, _, posZ, rotY = self:determinePlayerPosition(player)
			rotY = rotY - math.pi
			posX = (math.floor(posX) + self.worldCenterOffsetX) / self.worldSizeX
			posZ = (math.floor(posZ) + self.worldCenterOffsetZ) / self.worldSizeZ
			local positionVisible = self:setMapObjectOverlayPosition(self.mapArrowRedOverlay, posX, posZ, self.mapArrowRedOverlay.width, self.mapArrowRedOverlay.height, true, showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)

			if positionVisible then
				self:setMapObjectOverlayRotation(self.mapArrowRedOverlay, rotY)

				local r, g, b, a = self:colorForFarm(player.farmId)

				self.mapArrowRedOverlay:setColor(r, g, b, a)
				self.mapArrowRedOverlay:render()

				if showNames then
					setTextAlignment(RenderText.ALIGN_LEFT)
					setTextBold(false)
					setTextColor(1, 1, 1, 1)

					local textWidth = getTextWidth(self.playerFontSize, player.visualInformation.playerName)
					local posX = MathUtil.clamp(self.mapArrowRedOverlay.x + self.mapArrowRedOverlay.width * 0.5 + self.playerNameOffsetX - textWidth * 0.5, self.mapPosX, self.mapPosX + self.mapWidth - textWidth)

					renderText(posX, self.mapArrowRedOverlay.y + self.playerNameOffsetY, self.playerFontSize, player.visualInformation.playerName)
				end
			end
		end
	end
end

function IngameMap:drawEnterableArrows(showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	for _, enterable in pairs(g_currentMission.enterables) do
		if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled and not enterable.spec_enterable.isEntered then
			local posX, _, posZ, rotY = self:determineVehiclePosition(enterable)
			posX = (math.floor(posX) + self.worldCenterOffsetX) / self.worldSizeX
			posZ = (math.floor(posZ) + self.worldCenterOffsetZ) / self.worldSizeZ
			local positionVisible = self:setMapObjectOverlayPosition(self.mapArrowRedOverlay, posX, posZ, self.mapArrowRedOverlay.width, self.mapArrowRedOverlay.height, true, showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)

			if positionVisible then
				self:setMapObjectOverlayRotation(self.mapArrowRedOverlay, rotY)

				local r, g, b, a = self:colorForFarm(enterable:getActiveFarm())

				self.mapArrowRedOverlay:setColor(r, g, b, a)
				self.mapArrowRedOverlay:render()

				if showNames then
					setTextAlignment(RenderText.ALIGN_LEFT)
					setTextBold(false)
					setTextColor(1, 1, 1, 1)

					local textWidth = getTextWidth(self.playerFontSize, enterable:getControllerName())
					local posX = MathUtil.clamp(self.mapArrowRedOverlay.x + self.mapArrowRedOverlay.width * 0.5 + self.playerNameOffsetX - textWidth * 0.5, self.mapPosX, self.mapPosX + self.mapWidth - textWidth)

					renderText(posX, self.mapArrowRedOverlay.y + self.playerNameOffsetY, self.playerFontSize, enterable:getControllerName())
				end
			end
		end
	end
end

function IngameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, renderLast, showNames, minimalHotspotSize, noScaling)
	if renderLast then
		new2DLayer()
	end

	if self.hotspots_sorted ~= nil then
		for _, hotspot in pairs(self.hotspots_sorted[renderLast]) do
			hotspot:setIsVisible(false)

			if hotspot ~= self.selectedHotspot and (minimalHotspotSize == nil or hotspot.category == MapHotspot.CATEGORY_FIELD_DEFINITION or minimalHotspotSize <= hotspot.width) then
				self:drawHotspot(hotspot, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, showNames, noScaling)
			end
		end
	end
end

function IngameMap:drawHotspot(hotspot, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, showNames, noScaling)
	if hotspot ~= nil then
		if hotspot.linkNode ~= nil and hotspot.linkNode ~= 0 then
			local objectX, _, objectZ = getWorldTranslation(hotspot.linkNode)
			hotspot.xMapPos = objectX
			hotspot.zMapPos = objectZ
		end

		local objectX = (hotspot.xMapPos + self.worldCenterOffsetX) / self.worldSizeX
		local objectZ = (hotspot.zMapPos + self.worldCenterOffsetZ) / self.worldSizeZ
		hotspot.zoom = self.iconZoom

		hotspot:setIsVisible(self:setMapObjectOverlayPosition(hotspot, objectX, objectZ, hotspot.width * hotspot.zoom, hotspot.height * hotspot.zoom, hotspot.enabled, hotspot.persistent, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached))

		local scale = self.uiScale

		if noScaling then
			scale = 1
		end

		hotspot:render(self.mapPosX, self.mapPosX + self.mapWidth, self.mapPosY, self.mapPosY + self.mapHeight, scale, showNames)
	end
end

function IngameMap:drawPlayersCoordinates()
	local renderString = string.format("[%.1f°, %d, %d]", math.deg(-self.playerRotation % (2 * math.pi)), self.normalizedPlayerPosX * self.worldSizeX, self.normalizedPlayerPosZ * self.worldSizeZ)

	setTextAlignment(RenderText.ALIGN_RIGHT)
	setTextBold(false)
	setTextColor(unpack(IngameMap.COLOR.COORDINATES_TEXT))
	renderText(self.mapPosX + self.mapWidth - self.coordOffsetX, self.mapPosY + self.coordOffsetY, self.fontSize, renderString)
end

function IngameMap:drawLatencyToServer()
	if g_client ~= nil and g_client.currentLatency ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.missionDynamicInfo.isClient then
		if g_client.currentLatency <= 50 then
			setTextColor(unpack(IngameMap.COLOR.LATENCY_GOOD))
		elseif g_client.currentLatency < 100 then
			setTextColor(unpack(IngameMap.COLOR.LATENCY_MEDIUM))
		else
			setTextColor(unpack(IngameMap.COLOR.LATENCY_BAD))
		end

		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(self.mapPosX + self.mapWidth - self.coordOffsetX, self.mapPosY + self.mapHeight - self.coordOffsetY - self.fontSize, self.fontSize, string.format("%dms", math.max(g_client.currentLatency, 10)))
	end
end

function IngameMap:setScale(uiScale)
	IngameMap:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale

	self:storeScaledValues(uiScale)
	self.mapElement:setScale(uiScale, uiScale)

	local uniZoomScale = uiScale * self.iconZoom

	self.playerMapArrowElement:setScale(uniZoomScale, uniZoomScale)
	self.mapArrowRedOverlay:setScale(uniZoomScale, uniZoomScale)

	local x, y = self:getPosition()

	self:setPosition(x + self.mapOffsetX, y + self.mapOffsetY)
	self:setSize(self.mapWidth, self.mapHeight)
end

function IngameMap:storeScaledValues(uiScale)
	self.minMapWidth, self.minMapHeight = self:scalePixelToScreenVector(IngameMap.SIZE.MAP)
	self.mapLabelOffsetX, self.mapLabelOffsetY = self:scalePixelToScreenVector(IngameMap.POSITION.MAP_LABEL)
	self.mapLabelTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TITLE)
	self.mapOffsetX, self.mapOffsetY = self:scalePixelToScreenVector(IngameMap.POSITION.MAP)
	self.mapSizeX, self.mapSizeY = self:scalePixelToScreenVector(IngameMap.SIZE.MAP)
	self.toggleSizeGlyphOffsetX, self.toggleSizeGlyphOffsetY = self:scalePixelToScreenVector(IngameMap.POSITION.INPUT_ICON)
	self.selectHotspotTextSize = self:scalePixelToScreenHeight(IngameMap.TEXT_SIZE.GLYPH_TEXT)
	self.fontSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.coordOffsetX, self.coordOffsetY = self:scalePixelToScreenVector(IngameMap.POSITION.INFO_TEXT)
	self.playerFontSize = self:scalePixelToScreenHeight(IngameMap.TEXT_SIZE.PLAYER_NAME)
	self.playerNameOffsetX, self.playerNameOffsetY = self:scalePixelToScreenVector(IngameMap.POSITION.PLAYER_NAME)
	self.mapToFrameDiffY = self:scalePixelToScreenHeight(IngameMap.SIZE.SELF[2] - IngameMap.SIZE.MAP[2])
	self.mapToFrameDiffX = self:scalePixelToScreenWidth(IngameMap.SIZE.SELF[1] - IngameMap.SIZE.MAP[1])
end

function IngameMap:getBackgroundPosition()
	return g_safeFrameOffsetX, g_safeFrameOffsetY
end

function IngameMap:createBackground()
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.SELF))
	local posX, posY = self:getBackgroundPosition()

	return Overlay:new(nil, posX, posY, width, height)
end

function IngameMap:createComponents(hudAtlasPath)
	local baseX, baseY = self:getPosition()
	local width = self:getWidth()
	local height = self:getHeight()

	self:createFrame(hudAtlasPath, baseX, baseY, width, height)

	if self.showInputIcon then
		self:createToggleMapSizeGlyph(hudAtlasPath, baseX, baseY, width, height)
	end

	self:createPlayerMapArrow()
	self:createOtherMapArrowOverlay()
end

function IngameMap:createFrame(hudAtlasPath, baseX, baseY, width, height)
	local frame = HUDFrameElement:new(hudAtlasPath, baseX, baseY, width, height)
	self.mapFrameElement = frame

	self:addChild(frame)
end

function IngameMap:createToggleMapSizeGlyph(hudAtlasPath, baseX, baseY, baseWidth, baseHeight)
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.INPUT_ICON))
	local offX, offY = getNormalizedScreenValues(unpack(IngameMap.POSITION.INPUT_ICON))
	local element = InputGlyphElement:new(self.inputDisplayManager, width, height)
	local posX = baseX + baseWidth - width - offX
	local posY = baseY + baseHeight + offY

	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(IngameMap.COLOR.INPUT_ICON)
	element:setAction(InputAction.TOGGLE_MAP_SIZE)

	self.toggleMapSizeGlyph = element

	self:addChild(element)
end

function IngameMap:createPlayerMapArrow()
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.PLAYER_ARROW))
	local playerMapArrowOverlay = Overlay:new(MapHotspot.DEFAULT_FILENAME, 0, 0, width, height)

	playerMapArrowOverlay:setUVs(MapHotspot.UV.DEFAULT_NAV_POINTER)
	playerMapArrowOverlay:setColor(unpack(IngameMap.COLOR.PLAYER_ARROW))
	playerMapArrowOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT)

	self.playerMapArrowOverlay = playerMapArrowOverlay
	local element = HUDElement:new(playerMapArrowOverlay)
	self.playerMapArrowElement = element
end

function IngameMap:createOtherMapArrowOverlay()
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.OTHER_ARROW))
	local mapArrowRedOverlay = Overlay:new(MapHotspot.DEFAULT_FILENAME, 0, 0, width, height)

	mapArrowRedOverlay:setUVs(MapHotspot.UV.DEFAULT_NAV_POINTER)
	mapArrowRedOverlay:setColor(unpack(IngameMap.COLOR.OTHER_ARROW))

	self.mapArrowRedOverlay = mapArrowRedOverlay
end

IngameMap.MIN_MAP_WIDTH = GS_IS_MOBILE_VERSION and 600 or 300
IngameMap.MIN_MAP_HEIGHT = IngameMap.MIN_MAP_WIDTH * 0.77
IngameMap.SIZE = {
	MAP = {
		IngameMap.MIN_MAP_WIDTH,
		IngameMap.MIN_MAP_HEIGHT
	},
	SELF = {
		IngameMap.MIN_MAP_WIDTH + HUDFrameElement.THICKNESS.FRAME * 2,
		IngameMap.MIN_MAP_HEIGHT + HUDFrameElement.THICKNESS.BAR
	},
	PLAYER_ARROW = {
		GS_IS_MOBILE_VERSION and 60 or 30,
		GS_IS_MOBILE_VERSION and 60 or 30
	},
	OTHER_ARROW = {
		GS_IS_MOBILE_VERSION and 60 or 30,
		GS_IS_MOBILE_VERSION and 60 or 30
	},
	HOTSPOT = {
		GS_IS_MOBILE_VERSION and 30 or 12,
		GS_IS_MOBILE_VERSION and 30 or 12
	},
	INPUT_ICON = {
		30,
		30
	}
}
IngameMap.TEXT_SIZE = {
	PLAYER_NAME = 12,
	GLYPH_TEXT = 16
}
IngameMap.POSITION = {
	MAP = {
		HUDFrameElement.THICKNESS.FRAME,
		HUDFrameElement.THICKNESS.BAR
	},
	MAP_LABEL = {
		0,
		3
	},
	INFO_TEXT = {
		6,
		6
	},
	PLAYER_NAME = {
		0,
		4
	},
	INPUT_ICON = {
		0,
		3
	}
}
IngameMap.COLOR = {
	PLAYER_ARROW = {
		0.2705,
		0.6514,
		0.0802,
		1
	},
	OTHER_ARROW = {
		0.8069,
		0.0097,
		0.0097,
		1
	},
	INPUT_ICON = {
		1,
		1,
		1,
		1
	},
	MAP_LABEL = {
		1,
		1,
		1,
		1
	},
	COORDINATES_TEXT = {
		1,
		1,
		1,
		1
	},
	LATENCY_GOOD = {
		1,
		1,
		1,
		1
	},
	LATENCY_MEDIUM = {
		0.9301,
		0.2874,
		0.013,
		1
	},
	LATENCY_BAD = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
}
