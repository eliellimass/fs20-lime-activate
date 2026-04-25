VehicleSchemaDisplay = {}
local VehicleSchemaDisplay_mt = Class(VehicleSchemaDisplay, HUDDisplayElement)
VehicleSchemaDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
VehicleSchemaDisplay.MAX_SCHEMA_COLLECTION_DEPTH = 5

function VehicleSchemaDisplay.new(modManager)
	local backgroundOverlay = VehicleSchemaDisplay.createBackground()
	local self = VehicleSchemaDisplay:superClass().new(VehicleSchemaDisplay_mt, backgroundOverlay, nil)
	self.modManager = modManager
	self.vehicle = nil
	self.isDocked = false
	self.vehicleSchemaOverlays = {}
	self.iconSizeY = 0
	self.iconSizeX = 0
	self.maxSchemaWidth = 0

	return self
end

function VehicleSchemaDisplay:delete()
	VehicleSchemaDisplay:superClass().delete(self)

	for k, v in pairs(self.vehicleSchemaOverlays) do
		v:delete()

		self.vehicleSchemaOverlays[k] = nil
	end
end

function VehicleSchemaDisplay:loadVehicleSchemaOverlays()
	local xmlFile = loadXMLFile("VehicleSchemaDisplayOverlays", VehicleSchemaDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH)

	self:loadVehicleSchemaOverlaysFromXML(xmlFile)
	delete(xmlFile)

	for _, modDesc in ipairs(self.modManager:getMods()) do
		local xmlFile = loadXMLFile("ModFile", modDesc.modFile)

		self:loadVehicleSchemaOverlaysFromXML(xmlFile, modDesc.modFile)
		delete(xmlFile)
	end

	self:storeScaledValues()
end

function VehicleSchemaDisplay:loadVehicleSchemaOverlaysFromXML(xmlFile, modPath)
	local rootPath = "vehicleSchemaOverlays"
	local baseDirectory = ""
	local prefix = ""

	if modPath then
		rootPath = "modDesc.vehicleSchemaOverlays"
		local modName, dir = Utils.getModNameAndBaseDirectory(modPath)
		baseDirectory = dir
		prefix = modName
	end

	local atlasPath = getXMLString(xmlFile, rootPath .. "#filename")
	local imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, rootPath .. "#imageSize"), {
		1024,
		1024
	})
	local i = 0

	while true do
		local baseName = string.format("%s.overlay(%d)", rootPath, i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local baseOverlayName = getXMLString(xmlFile, baseName .. "#name")
		local uvString = getXMLString(xmlFile, baseName .. "#uvs") or string.format("0px 0px %ipx %ipx", imageSize[1], imageSize[2])
		local uvs = GuiUtils.getUVs(uvString, imageSize)
		local sizeString = getXMLString(xmlFile, baseName .. "#size") or string.format("%ipx %ipx", VehicleSchemaDisplay.SIZE.ICON[1], VehicleSchemaDisplay.SIZE.ICON[1])
		local size = GuiUtils.getNormalizedValues(sizeString, {
			1,
			1
		})

		if baseOverlayName then
			local overlayName = prefix .. baseOverlayName
			local atlasFileName = Utils.getFilename(atlasPath, baseDirectory)
			local schemaOverlay = Overlay:new(atlasFileName, 0, 0, size[1], size[2])

			schemaOverlay:setUVs(uvs)

			self.vehicleSchemaOverlays[overlayName] = schemaOverlay
		end

		i = i + 1
	end
end

function VehicleSchemaDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

function VehicleSchemaDisplay:lateSetDocked(isDocked)
	self.isDocked = isDocked
end

function VehicleSchemaDisplay:setDocked(isDocked, animate)
	local targetX, targetY = VehicleSchemaDisplay.getBackgroundPosition(isDocked, self:getScale())

	if animate and self.animation:getFinished() then
		local startX, startY = self:getPosition()

		self:animateDocking(startX, startY, targetX, targetY, isDocked)
	else
		self.animation:stop()

		self.isDocked = isDocked

		self:setPosition(targetX, targetY)
	end
end

function VehicleSchemaDisplay:draw()
	if self.vehicle ~= nil then
		VehicleSchemaDisplay:superClass().draw(self)
		self:drawVehicleSchemaOverlays(self.vehicle)
	end
end

function VehicleSchemaDisplay:animateDocking(startX, startY, targetX, targetY, isDocking)
	local sequence = TweenSequence.new(self)
	local lateDockInstant = HUDDisplayElement.MOVE_ANIMATION_DURATION * 0.5

	if not isDocking then
		sequence:addInterval(HUDDisplayElement.MOVE_ANIMATION_DURATION)

		lateDockInstant = lateDockInstant + HUDDisplayElement.MOVE_ANIMATION_DURATION
	end

	sequence:addTween(MultiValueTween:new(self.setPosition, {
		startX,
		startY
	}, {
		targetX,
		targetY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION))
	sequence:insertCallback(self.lateSetDocked, isDocking, lateDockInstant)
	sequence:start()

	self.animation = sequence
end

function VehicleSchemaDisplay:collectVehicleSchemaDisplayOverlays(overlays, depth, vehicle, rootVehicle, parentOverlay, x, y, rotation, invertX)
	if vehicle.getAttachedImplements == nil then
		return
	end

	local attachedImplements = vehicle:getAttachedImplements()

	for _, implement in pairs(attachedImplements) do
		local object = implement.object

		if object ~= nil and object.schemaOverlay ~= nil then
			local selected = object:getIsSelected()
			local turnedOn = object.getIsTurnedOn ~= nil and object:getIsTurnedOn()
			local jointDesc = vehicle.schemaOverlay.attacherJoints[implement.jointDescIndex]

			if jointDesc ~= nil then
				local invertX = invertX ~= jointDesc.invertX
				local overlay = self:getSchemaOverlayForState(object.schemaOverlay, turnedOn, selected, true)
				local baseY = y + jointDesc.y * parentOverlay.height
				local baseX = nil

				if invertX then
					baseX = x - overlay.width + (1 - jointDesc.x) * parentOverlay.width
				else
					baseX = x + jointDesc.x * parentOverlay.width
				end

				local rotation = rotation + jointDesc.rotation
				local offsetX, offsetY = nil

				if invertX then
					offsetX = -object.schemaOverlay.offsetX * overlay.width
				else
					offsetX = object.schemaOverlay.offsetX * overlay.width
				end

				offsetY = object.schemaOverlay.offsetY * overlay.height
				local rotatedX = offsetX * math.cos(rotation) - offsetY * math.sin(rotation)
				local rotatedY = offsetX * math.sin(rotation) + offsetY * math.cos(rotation)
				baseX = baseX - rotatedX
				baseY = baseY - rotatedY

				if object.getIsLowered == nil or not object:getIsLowered(true) then
					local widthOffset, heightOffset = getNormalizedScreenValues(jointDesc.liftedOffsetX, jointDesc.liftedOffsetY)
					baseX = baseX + widthOffset
					baseY = baseY + heightOffset
				end

				local additionalText = object:getAdditionalSchemaText()

				table.insert(overlays, {
					overlay = overlay,
					additionalText = additionalText,
					x = baseX,
					y = baseY,
					rotation = rotation,
					invertX = invertX,
					invisibleBorderRight = object.schemaOverlay.invisibleBorderRight,
					invisibleBorderLeft = object.schemaOverlay.invisibleBorderLeft
				})

				if depth <= VehicleSchemaDisplay.MAX_SCHEMA_COLLECTION_DEPTH then
					self:collectVehicleSchemaDisplayOverlays(overlays, depth + 1, object, rootVehicle, overlay, baseX, baseY, rotation, invertX)
				end
			end
		end
	end
end

function VehicleSchemaDisplay:getVehicleSchemaOverlays(vehicle)
	local turnedOn = vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn()
	local selected = vehicle:getIsSelected()
	local overlay = self:getSchemaOverlayForState(vehicle.schemaOverlay, turnedOn, selected, false)
	local additionalText = vehicle:getAdditionalSchemaText()
	local overlays = {}

	table.insert(overlays, {
		y = 0,
		rotation = 0,
		x = 0,
		invertX = false,
		overlay = overlay,
		additionalText = additionalText,
		invisibleBorderRight = vehicle.schemaOverlay.invisibleBorderRight,
		invisibleBorderLeft = vehicle.schemaOverlay.invisibleBorderLeft
	})
	self:collectVehicleSchemaDisplayOverlays(overlays, 1, vehicle, vehicle, overlay, 0, 0, 0, false)

	return overlays, overlay.height
end

function VehicleSchemaDisplay:getSchemaDelimiters(overlayDescriptions)
	local minX = math.huge
	local maxX = -math.huge

	for _, overlayDesc in pairs(overlayDescriptions) do
		local overlay = overlayDesc.overlay
		local cosRot = math.cos(overlayDesc.rotation)
		local sinRot = math.sin(overlayDesc.rotation)
		local offX = overlayDesc.invisibleBorderLeft * overlay.width
		local dx = overlay.width + (overlayDesc.invisibleBorderRight + overlayDesc.invisibleBorderLeft) * overlay.width
		local dy = overlay.height
		local x = overlayDesc.x + offX * cosRot
		local dx2 = dx * cosRot
		local dx3 = -dy * sinRot
		local dx4 = dx2 + dx3
		maxX = math.max(maxX, x, x + dx2, x + dx3, x + dx4)
		minX = math.min(minX, x, x + dx2, x + dx3, x + dx4)
	end

	return minX, maxX
end

function VehicleSchemaDisplay:drawVehicleSchemaOverlays(vehicle)
	vehicle = vehicle:getRootVehicle()

	if vehicle.schemaOverlay ~= nil then
		local overlays, overlayHeight = self:getVehicleSchemaOverlays(vehicle)
		local baseX, baseY = self:getPosition()
		baseY = baseY + (self:getHeight() - overlayHeight) * 0.5

		if self.isDocked then
			baseX = baseX + self:getWidth()
		end

		local minX, maxX = self:getSchemaDelimiters(overlays)
		local scale = 1
		local sizeX = maxX - minX

		if self.maxSchemaWidth < sizeX then
			scale = self.maxSchemaWidth / sizeX
		end

		local newPosX = baseX

		if self.isDocked then
			newPosX = newPosX - maxX * scale
		else
			newPosX = newPosX - minX * scale
		end

		for _, overlayDesc in pairs(overlays) do
			local overlay = overlayDesc.overlay
			local width = overlay.width
			local height = overlay.height

			overlay:setInvertX(overlayDesc.invertX)
			overlay:setPosition(newPosX + overlayDesc.x, baseY + overlayDesc.y)
			overlay:setRotation(overlayDesc.rotation, 0, 0)
			overlay:setDimension(width * scale, height * scale)
			overlay:render()

			if overlayDesc.additionalText ~= nil then
				local posX = newPosX + overlayDesc.x + width * scale * 0.5
				local posY = baseY + overlayDesc.y + height * scale

				setTextBold(false)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(posX, posY, getCorrectTextSize(0.009), overlayDesc.additionalText)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextColor(1, 1, 1, 1)
			end

			overlay:setDimension(width, height)
		end
	end
end

function VehicleSchemaDisplay:getSchemaOverlayForState(schemaOverlayData, isTurnedOn, isSelected, isImplement)
	local overlay, schemaName = nil

	if isSelected then
		schemaName = schemaOverlayData.schemaNameSelected

		if not schemaName or schemaName == "" then
			schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_IMPLEMENT_SELECTED or VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_VEHICLE_SELECTED
		end
	end

	if isTurnedOn then
		schemaName = schemaOverlayData.schemaNameTurnedOn

		if not schemaName or schemaName == "" then
			schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_IMPLEMENT_ON or VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_VEHICLE_ON
		end
	end

	if isTurnedOn and isSelected then
		schemaName = schemaOverlayData.schemaNameSelectedOn

		if not schemaName or schemaName == "" then
			schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_IMPLEMENT_SELECTED_ON or VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_VEHICLE_SELECTED_ON
		end
	end

	if not schemaName or schemaName == "" then
		schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_IMPLEMENT or VehicleSchemaOverlayData.SCHEMA_OVERLAY.DEFAULT_VEHICLE
	end

	return self.vehicleSchemaOverlays[schemaName]
end

function VehicleSchemaDisplay:setScale(uiScale)
	VehicleSchemaDisplay:superClass().setScale(self, uiScale, uiScale)

	local posX, posY = VehicleSchemaDisplay.getBackgroundPosition(self.isDocked, uiScale)

	self:setPosition(posX, posY)
	self:storeScaledValues()
end

function VehicleSchemaDisplay:storeScaledValues()
	self.iconSizeX, self.iconSizeY = self:scalePixelToScreenVector(VehicleSchemaDisplay.SIZE.ICON)
	self.maxSchemaWidth = self:scalePixelToScreenWidth(VehicleSchemaDisplay.MAX_SCHEMA_WIDTH)

	for _, overlay in pairs(self.vehicleSchemaOverlays) do
		overlay:resetDimensions()

		local pixelSize = {
			overlay.defaultWidth,
			overlay.defaultHeight
		}
		local width, height = self:scalePixelToScreenVector(pixelSize)

		overlay:setDimension(width, height)
	end
end

function VehicleSchemaDisplay.getBackgroundPosition(isDocked, uiScale)
	local width, height = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
	local posX = g_safeFrameOffsetX
	local posY = 1 - g_safeFrameOffsetY - height * uiScale

	if isDocked then
		local offX, offY = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.POSITION.SELF_DOCKED))
		posX = posX + (offX - width) * uiScale
		posY = posY + offY * uiScale
	end

	return posX, posY
end

function VehicleSchemaDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
	local posX, posY = VehicleSchemaDisplay.getBackgroundPosition(false, 1)

	return Overlay:new(nil, posX, posY, width, height)
end

VehicleSchemaDisplay.MAX_SCHEMA_WIDTH = 180
VehicleSchemaDisplay.SIZE = {
	SELF = {
		VehicleSchemaDisplay.MAX_SCHEMA_WIDTH,
		30
	},
	ICON = {
		30,
		30
	}
}
VehicleSchemaDisplay.POSITION = {
	SELF_DOCKED = {
		InputHelpDisplay.POSITION.FRAME[1] + InputHelpDisplay.SIZE.HEADER[1],
		0
	}
}
