IngameMapElement = {}
local IngameMapElement_mt = Class(IngameMapElement, GuiElement)
IngameMapElement.CURSOR_SPEED_FACTOR = 0.0006
IngameMapElement.ZOOM_SPEED_FACTOR = 0.05
IngameMapElement.BORDER_SCROLL_THRESHOLD = 0.03
IngameMapElement.MAP_ZOOM_SHOW_NAMES = GS_IS_MOBILE_VERSION and 0.5 or 0.8
IngameMapElement.DRAG_START_DISTANCE = 2

function IngameMapElement:new(target, custom_mt)
	local self = GuiElement:new(target, custom_mt or IngameMapElement_mt)
	self.ingameMap = nil
	self.cursorId = nil
	self.inputMode = GS_INPUT_HELP_MODE_GAMEPAD
	self.terrainSize = 0
	self.mapAlpha = 1
	self.zoomMin = 0.4
	self.zoomMax = 2
	self.zoomDefault = 1
	self.mapCenterX = 0
	self.mapCenterY = 0
	self.mapZoom = self.zoomDefault
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0
	self.accumZoomInput = 0
	self.useMouse = false
	self.resetMouseNextFrame = false
	self.cursorDeadzones = {}
	self.minDragDistanceX = IngameMapElement.DRAG_START_DISTANCE / g_screenWidth
	self.minDragDistanceY = IngameMapElement.DRAG_START_DISTANCE / g_screenHeight
	self.hasDragged = false
	self.minimalHotspotSize = getNormalizedScreenValues(9, 1)

	return self
end

function IngameMapElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)

	self.ingameMap = nil

	IngameMapElement:superClass().delete(self)
end

function IngameMapElement:loadFromXML(xmlFile, key)
	IngameMapElement:superClass().loadFromXML(self, xmlFile, key)

	self.cursorId = getXMLString(xmlFile, key .. "#cursorId")
	self.mapAlpha = getXMLFloat(xmlFile, key .. "#mapAlpha") or self.mapAlpha

	self:addCallback(xmlFile, key .. "#onDrawPreIngameMap", "onDrawPreIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMap", "onDrawPostIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMapHotspots", "onDrawPostIngameMapHotspotsCallback")
	self:addCallback(xmlFile, key .. "#onClickHotspot", "onClickHotspotCallback")
	self:addCallback(xmlFile, key .. "#onClickMap", "onClickMapCallback")
end

function IngameMapElement:loadProfile(profile, applyProfile)
	IngameMapElement:superClass().loadProfile(self, profile, applyProfile)

	self.mapAlpha = profile:getNumber("mapAlpha", self.mapAlpha)
end

function IngameMapElement:copyAttributes(src)
	IngameMapElement:superClass().copyAttributes(self, src)

	self.mapZoom = src.mapZoom
	self.mapAlpha = src.mapAlpha
	self.cursorId = src.cursorId
	self.onDrawPreIngameMapCallback = src.onDrawPreIngameMapCallback
	self.onDrawPostIngameMapCallback = src.onDrawPostIngameMapCallback
	self.onDrawPostIngameMapHotspotsCallback = src.onDrawPostIngameMapHotspotsCallback
	self.onClickHotspotCallback = src.onClickHotspotCallback
	self.onClickMapCallback = src.onClickMapCallback
end

function IngameMapElement:onGuiSetupFinished()
	IngameMapElement:superClass().onGuiSetupFinished(self)

	if self.cursorId ~= nil then
		if self.target[self.cursorId] ~= nil then
			self.cursorElement = self.target[self.cursorId]
		else
			print("Warning: CursorId '" .. self.cursorId .. "' not found for '" .. self.target.name .. "'!")
		end
	end
end

function IngameMapElement:addCursorDeadzone(screenX, screenY, width, height)
	table.insert(self.cursorDeadzones, {
		screenX,
		screenY,
		width,
		height
	})
end

function IngameMapElement:clearCursorDeadzones()
	self.cursorDeadzones = {}
end

function IngameMapElement:isCursorInDeadzones(cursorScreenX, cursorScreenY)
	for _, zone in pairs(self.cursorDeadzones) do
		if GuiUtils.checkOverlayOverlap(cursorScreenX, cursorScreenY, zone[1], zone[2], zone[3], zone[4]) then
			return true
		end
	end

	return false
end

function IngameMapElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)

		if not GS_IS_CONSOLE_VERSION and (isDown or isUp or posX ~= self.lastMousePosX or posY ~= self.lastMousePosY) then
			self.useMouse = true

			if self.cursorElement then
				self.cursorElement:setVisible(false)
			end
		end

		if GS_IS_MOBILE_VERSION and self.useMouse and isDown then
			self.lastMousePosY = posY
		end

		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) and isDown and button == Input.MOUSE_BUTTON_LEFT and not self:isCursorInDeadzones(posX, posY) then
			eventUsed = true

			if not self.mouseDown then
				self.mouseDown = true
			end
		end

		if self.mouseDown and self.lastMousePosX ~= nil then
			local distX = self.lastMousePosX - posX
			local distY = posY - self.lastMousePosY

			if self.isFixedHorizontal then
				distX = 0
			end

			if self.minDragDistanceX < math.abs(distX) or self.minDragDistanceY < math.abs(distY) then
				local factorX = -distX
				local factorY = distY

				self:moveCenter(factorX, factorY)

				self.hasDragged = true
			end
		end

		if isUp and button == Input.MOUSE_BUTTON_LEFT then
			if not eventUsed and self.mouseDown and not self.hasDragged then
				local localX, localY = self:getLocalPosition(posX, posY)

				self:onClickMap(localX, localY)
				self:selectHotspotAt(posX, posY)

				eventUsed = true
			end

			self.mouseDown = false
			self.hasDragged = false
		end

		self.lastMousePosX = posX
		self.lastMousePosY = posY
	end

	return eventUsed
end

function IngameMapElement:moveCenter(x, y)
	local width, height = self:getElementSize()
	self.mapCenterX = MathUtil.clamp(self.mapCenterX + x, width * -0.5, width * 0.5)
	self.mapCenterY = MathUtil.clamp(self.mapCenterY + y, height * -0.5, height * 0.5)

	if self.lockedToBorder then
		local lim = (self.height - self.absSize[2]) / 2
		self.mapCenterY = MathUtil.clamp(self.mapCenterY - self.yOffset, lim, -lim) + self.yOffset
	end
end

function IngameMapElement:getLocaPointerTarget()
	if self.useMouse then
		return self:getLocalPosition(self.lastMousePosX, self.lastMousePosY)
	elseif self.cursorElement then
		local posX = self.cursorElement.absPosition[1] + self.cursorElement.size[1] * 0.5
		local posY = self.cursorElement.absPosition[2] + self.cursorElement.size[2] * 0.5

		return self:getLocalPosition(posX, posY)
	end

	return 0, 0
end

function IngameMapElement:zoom(direction)
	if GS_IS_MOBILE_VERSION then
		return
	end

	local targetX, targetY = self:getLocaPointerTarget()
	local oldZoom = self.mapZoom
	local speed = IngameMapElement.ZOOM_SPEED_FACTOR * direction * self.size[1]
	self.mapZoom = MathUtil.clamp(self.mapZoom + speed, self.zoomMin, self.zoomMax)

	self:moveCenter(0, 0)

	local width, height = self:getElementSize()

	self:setSize(width, height)

	if oldZoom ~= self.mapZoom then
		local newTargetX, newTargetY = self:getLocaPointerTarget()
		local diffX = newTargetX - targetX
		local diffY = newTargetY - targetY
		diffX = diffX * width
		diffY = diffY * height

		self:moveCenter(diffX, diffY)
	end
end

function IngameMapElement:setFixedHorizontal(width, offset)
	self.isFixedHorizontal = true
	self.mapZoom = width
	local width, height = self:getElementSize()

	self:setSize(width, height)

	self.mapCenterX = offset
	self.mapCenterY = 0
end

function IngameMapElement:setLockedToBorder(yOffset, height)
	self.yOffset = yOffset
	self.height = height
	self.lockedToBorder = true
end

function IngameMapElement:update(dt)
	IngameMapElement:superClass().update(self, dt)

	self.inputMode = g_inputBinding:getLastInputMode()

	if not g_gui:getIsDialogVisible() and not self.alreadyClosed then
		local zoomFactor = MathUtil.clamp(self.accumZoomInput, -1, 1)

		if zoomFactor ~= 0 then
			self:zoom(zoomFactor * -0.015 * dt)
		end

		if self.cursorElement ~= nil then
			self.cursorElement:setVisible(self.inputMode == GS_INPUT_HELP_MODE_GAMEPAD and not GS_IS_MOBILE_VERSION)
			self:updateCursor(self.accumHorizontalInput, -self.accumVerticalInput, dt)

			self.useMouse = false
		end

		self:updateMap()
	end

	self:resetFrameInputState()
end

function IngameMapElement:getElementSize()
	local width = self.mapZoom

	return width, width * g_screenAspectRatio
end

function IngameMapElement:updateMap()
	local width, height = self:getElementSize()

	self:setSize(width, height)
	self:setPosition(self.mapCenterX, self.mapCenterY)
	self.ingameMap:setPosition(self.absPosition[1], self.absPosition[2])
	self.ingameMap:setSize(self.size[1], self.size[2])

	self.ingameMap.iconZoom = 0.3 + (self.zoomMax - self.zoomMin) * self.mapZoom

	self.ingameMap:setZoomScale(self.ingameMap.iconZoom)
	self.ingameMap:updatePlayerPosition()
end

function IngameMapElement:resetFrameInputState()
	self.accumZoomInput = 0
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0

	if self.resetMouseNextFrame then
		self.useMouse = false
		self.resetMouseNextFrame = false
	end
end

function IngameMapElement:draw()
	local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = self.ingameMap:updateMapHeightZoomFactor()

	self:raiseCallback("onDrawPreIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawMap(self.mapAlpha)
	self:raiseCallback("onDrawPostIngameMapCallback", self, self.ingameMap)

	local showNames = IngameMapElement.MAP_ZOOM_SHOW_NAMES <= self.mapZoom
	local minimalHotspotSize = self.minimalHotspotSize / self.mapZoom

	self.ingameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, false, showNames, minimalHotspotSize, true)
	self.ingameMap:drawOtherPlayerArrows(showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self.ingameMap:drawEnterableArrows(showNames, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self.ingameMap:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, true, showNames, minimalHotspotSize, true)

	if self.ingameMap.selectedHotspot ~= nil then
		self.ingameMap:drawHotspot(self.ingameMap.selectedHotspot, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached, showNames, true)
	end

	self.ingameMap:updatePlayerArrow(false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
	self.ingameMap:drawPlayerArrow()
	self:raiseCallback("onDrawPostIngameMapHotspots", self, self.ingameMap)
	IngameMapElement:superClass().draw(self)
end

function IngameMapElement:onOpen()
	IngameMapElement:superClass().onOpen(self)

	if self.cursorElement ~= nil then
		self.cursorElement:setVisible(false)
	end

	if self.largestSize == nil then
		self.largestSize = self.size
	end

	self.ingameMap:setFullscreen(true)
end

function IngameMapElement:onClose()
	IngameMapElement:superClass().onClose(self)
	self:removeActionEvents()
	self.ingameMap:setFullscreen(false)
	self.ingameMap:resetSettings()
end

function IngameMapElement:reset()
	IngameMapElement:superClass().reset(self)

	self.mapCenterX = 0
	self.mapCenterY = 0
	self.mapZoom = 1

	self.ingameMap:resetSettings()
end

function IngameMapElement:updateCursor(deltaX, deltaY, dt)
	if self.cursorElement ~= nil and (self.cursorElement:getIsVisible() or GS_IS_MOBILE_VERSION) then
		local speed = IngameMapElement.CURSOR_SPEED_FACTOR
		local parentWidth = self.cursorElement.parent.size[1]
		local parentHeight = self.cursorElement.parent.size[2]
		local cursorWidth = self.cursorElement.size[1]
		local cursorHeight = self.cursorElement.size[2]
		local diffX = deltaX * speed * dt / g_screenAspectRatio
		local diffY = deltaY * speed * dt

		self:moveCenter(-diffX, -diffY)
	end
end

function IngameMapElement:selectHotspotAt(posX, posY)
	if self.ingameMap.hotspots_sorted ~= nil then
		if not self:selectHotspotFrom(self.ingameMap.hotspots_sorted[true], posX, posY) then
			self:selectHotspotFrom(self.ingameMap.hotspots_sorted[false], posX, posY)
		end

		return
	end

	self:selectHotspotFrom(self.ingameMap.hotspots, posX, posY)
end

function IngameMapElement:selectHotspotFrom(hotspots, posX, posY)
	for i = #hotspots, 1, -1 do
		local hotspot = hotspots[i]

		if self.ingameMap.filter[hotspot.category] and hotspot:getIsVisible() and hotspot.category ~= MapHotspot.CATEGORY_COLLECTABLE and hotspot:getIsActive() and hotspot:getIsEnabled() and GuiUtils.checkOverlayOverlap(posX, posY, hotspot.x, hotspot.y, hotspot:getWidth(false, 1), hotspot:getHeight(false, 1), nil) then
			self:raiseCallback("onClickHotspotCallback", self, hotspot)

			return true
		end
	end

	return false
end

function IngameMapElement:getLocalPosition(posX, posY)
	if posX == nil then
		printCallstack()
	end

	return MathUtil.clamp((posX - self.absPosition[1]) / self.size[1], 0, 1), MathUtil.clamp((posY - self.absPosition[2]) / self.size[2], 0, 1)
end

function IngameMapElement:onClickMap(localPosX, localPosY)
	local worldPosX, worldPosZ = self:localToWorldPos(localPosX, localPosY)

	self:raiseCallback("onClickMapCallback", self, worldPosX, worldPosZ)
end

function IngameMapElement:localToWorldPos(localPosX, localPosY)
	local worldPosX = localPosX * self.terrainSize
	local worldPosZ = -localPosY * self.terrainSize
	worldPosX = worldPosX - self.terrainSize * 0.5
	worldPosZ = worldPosZ + self.terrainSize * 0.5

	return worldPosX, worldPosZ
end

function IngameMapElement:setMapFocusToHotspot(hotspot)
	if hotspot ~= nil then
		local objectX = (hotspot.xMapPos + self.ingameMap.worldCenterOffsetX) / self.ingameMap.worldSizeX
		local objectZ = (hotspot.zMapPos + self.ingameMap.worldCenterOffsetZ) / self.ingameMap.worldSizeZ

		if self:isCursorInDeadzones(objectX, objectZ) then
			self.ingameMapCenterX = MathUtil.clamp(objectX, 0 + self.ingameMap.mapVisWidth * 0.5, 1 - self.ingameMap.mapVisWidth * 0.5)
			self.ingameMapCenterY = MathUtil.clamp(objectZ, 0 + self.ingameMap.mapVisHeight * 0.5, 1 - self.ingameMap.mapVisHeight * 0.5)
		end

		if self.isFixedHorizontal then
			if objectZ < 0.5 then
				self:moveCenter(0, -1)
			else
				self:moveCenter(0, 1)
			end
		end
	end
end

function IngameMapElement:isPointVisible(x, z)
end

function IngameMapElement:setIngameMap(ingameMap)
	self.ingameMap = ingameMap
end

function IngameMapElement:setTerrainSize(terrainSize)
	self.terrainSize = terrainSize
end

function IngameMapElement:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onHorizontalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onVerticalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.INGAMEMAP_ACCEPT, self, self.onAccept, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_ACCELERATE_VEHICLE, self, self.onZoomInput, false, false, true, true, -1)
	g_inputBinding:registerActionEvent(InputAction.AXIS_BRAKE_VEHICLE, self, self.onZoomInput, false, false, true, true, 1)
end

function IngameMapElement:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function IngameMapElement:onHorizontalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() and not self.isFixedHorizontal then
		self.accumHorizontalInput = self.accumHorizontalInput + inputValue
	end
end

function IngameMapElement:onVerticalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() then
		self.accumVerticalInput = self.accumVerticalInput + inputValue
	end
end

function IngameMapElement:onAccept()
	if self.cursorElement then
		local posX = self.cursorElement.absPosition[1]
		local posY = self.cursorElement.absPosition[2]
		local localX, localY = self:getLocaPointerTarget()

		self:onClickMap(localX, localY)
		self:selectHotspotAt(posX, posY)
	end
end

function IngameMapElement:onZoomInput(_, inputValue, direction)
	if not self:checkAndResetMouse() then
		self.accumZoomInput = self.accumZoomInput + direction * inputValue
	end
end

function IngameMapElement:checkAndResetMouse()
	local useMouse = self.useMouse

	if useMouse then
		self.resetMouseNextFrame = true
	end

	return useMouse
end
