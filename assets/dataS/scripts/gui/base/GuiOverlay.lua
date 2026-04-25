GuiOverlay = {
	STATE_NORMAL = 1,
	STATE_DISABLED = 2,
	STATE_FOCUSED = 3,
	STATE_PRESSED = 4,
	STATE_SELECTED = 5,
	STATE_HIGHLIGHTED = 6
}

function GuiOverlay:loadOverlay(overlay, overlayName, imageSize, profile, xmlFile, key)
	if overlay.uvs == nil then
		overlay.uvs = Overlay.DEFAULT_UVS
	end

	if overlay.color == nil then
		overlay.color = {
			1,
			1,
			1,
			1
		}
	end

	local filename, previewFilename = nil

	if xmlFile ~= nil then
		filename = getXMLString(xmlFile, key .. "#" .. overlayName .. "Filename" .. g_gui.languageSuffix) or getXMLString(xmlFile, key .. "#" .. overlayName .. "Filename")
		previewFilename = getXMLString(xmlFile, key .. "#" .. overlayName .. "PreviewFilename")

		GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
		GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
	elseif profile ~= nil then
		filename = profile:getValue(overlayName .. "Filename" .. g_gui.languageSuffix) or profile:getValue(overlayName .. "Filename")
		previewFilename = profile:getValue(overlayName .. "PreviewFilename")

		GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
		GuiOverlay.loadProfileColors(profile, overlay, overlayName)
	end

	if filename == nil then
		return nil
	end

	if previewFilename == nil then
		previewFilename = "dataS2/menu/blank.png"
	end

	if filename == "g_baseUIFilename" then
		filename = g_baseUIFilename
	end

	overlay.filename = string.gsub(filename, "$l10nSuffix", g_gui.languageSuffix)
	overlay.previewFilename = previewFilename

	return overlay
end

function GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "UVs")

	if uvs ~= nil then
		overlay.uvs = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "FocusedUVs")

	if uvs ~= nil then
		overlay.uvsFocused = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "PressedUVs")

	if uvs ~= nil then
		overlay.uvsPressed = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "SelectedUVs")

	if uvs ~= nil then
		overlay.uvsSelected = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "DisabledUVs")

	if uvs ~= nil then
		overlay.uvsDisabled = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = getXMLString(xmlFile, key .. "#" .. overlayName .. "HighlightedUVs")

	if uvs ~= nil then
		overlay.uvsHighlighted = GuiUtils.getUVs(uvs, imageSize)
	end
end

function GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
	local uvs = profile:getValue(overlayName .. "UVs")

	if uvs ~= nil then
		overlay.uvs = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = profile:getValue(overlayName .. "FocusedUVs")

	if uvs ~= nil then
		overlay.uvsFocused = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = profile:getValue(overlayName .. "PressedUVs")

	if uvs ~= nil then
		overlay.uvsPressed = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = profile:getValue(overlayName .. "SelectedUVs")

	if uvs ~= nil then
		overlay.uvsSelected = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = profile:getValue(overlayName .. "DisabledUVs")

	if uvs ~= nil then
		overlay.uvsDisabled = GuiUtils.getUVs(uvs, imageSize)
	end

	local uvs = profile:getValue(overlayName .. "HighlightedUVs")

	if uvs ~= nil then
		overlay.uvsHighlighted = GuiUtils.getUVs(uvs, imageSize)
	end
end

function GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "Color"))

	if color ~= nil then
		overlay.color = color
	end

	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "FocusedColor"))

	if color ~= nil then
		overlay.colorFocused = color
	end

	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "PressedColor"))

	if color ~= nil then
		overlay.colorPressed = color
	end

	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "SelectedColor"))

	if color ~= nil then
		overlay.colorSelected = color
	end

	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "DisabledColor"))

	if color ~= nil then
		overlay.colorDisabled = color
	end

	local color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#" .. overlayName .. "HighlightedColor"))

	if color ~= nil then
		overlay.colorHighlighted = color
	end

	local rotation = getXMLFloat(xmlFile, key .. "#" .. overlayName .. "Rotation")

	if rotation ~= nil then
		overlay.rotation = math.rad(rotation)
	end

	local isWebOverlay = getXMLBool(xmlFile, key .. "#" .. overlayName .. "IsWebOverlay")

	if isWebOverlay ~= nil then
		overlay.isWebOverlay = isWebOverlay
	end
end

function GuiOverlay.loadProfileColors(profile, overlay, overlayName)
	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "Color"))

	if color ~= nil then
		overlay.color = color
	end

	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "FocusedColor"))

	if color ~= nil then
		overlay.colorFocused = color
	end

	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "PressedColor"))

	if color ~= nil then
		overlay.colorPressed = color
	end

	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "SelectedColor"))

	if color ~= nil then
		overlay.colorSelected = color
	end

	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "DisabledColor"))

	if color ~= nil then
		overlay.colorDisabled = color
	end

	local color = GuiUtils.getColorArray(profile:getValue(overlayName .. "HighlightedColor"))

	if color ~= nil then
		overlay.colorHighlighted = color
	end

	local rotation = profile:getValue(overlayName .. "Rotation")

	if rotation ~= nil then
		overlay.rotation = math.rad(tonumber(rotation))
	end

	local isWebOverlay = profile:getBool(overlayName .. "IsWebOverlay")

	if isWebOverlay ~= nil then
		overlay.isWebOverlay = isWebOverlay
	end
end

function GuiOverlay.createOverlay(overlay, filename)
	if overlay.overlay ~= nil and overlay.filename == filename then
		return overlay
	end

	if filename ~= nil then
		overlay.filename = string.gsub(filename, "$l10nSuffix", g_gui.languageSuffix)
	end

	GuiOverlay.deleteOverlay(overlay)

	if overlay.filename ~= nil then
		local imageOverlay = 0

		if overlay.isWebOverlay == nil or not overlay.isWebOverlay or overlay.isWebOverlay and not StringUtil.startsWith(overlay.filename, "http") then
			imageOverlay = createImageOverlay(overlay.filename)
		else
			imageOverlay = createWebImageOverlay(overlay.filename, overlay.previewFilename)
		end

		if imageOverlay ~= 0 then
			overlay.overlay = imageOverlay
		end
	end

	overlay.rotation = Utils.getNoNil(overlay.rotation, 0)
	overlay.alpha = Utils.getNoNil(overlay.alpha, 1)

	return overlay
end

function GuiOverlay.copyOverlay(overlay, overlaySrc)
	overlay.filename = overlaySrc.filename
	overlay.uvs = {
		overlaySrc.uvs[1],
		overlaySrc.uvs[2],
		overlaySrc.uvs[3],
		overlaySrc.uvs[4],
		overlaySrc.uvs[5],
		overlaySrc.uvs[6],
		overlaySrc.uvs[7],
		overlaySrc.uvs[8]
	}
	overlay.color = {
		overlaySrc.color[1],
		overlaySrc.color[2],
		overlaySrc.color[3],
		overlaySrc.color[4]
	}
	overlay.rotation = overlaySrc.rotation
	overlay.alpha = overlaySrc.alpha
	overlay.isWebOverlay = overlaySrc.isWebOverlay
	overlay.previewFilename = overlaySrc.previewFilename

	if overlaySrc.uvsFocused ~= nil then
		overlay.uvsFocused = {
			overlaySrc.uvsFocused[1],
			overlaySrc.uvsFocused[2],
			overlaySrc.uvsFocused[3],
			overlaySrc.uvsFocused[4],
			overlaySrc.uvsFocused[5],
			overlaySrc.uvsFocused[6],
			overlaySrc.uvsFocused[7],
			overlaySrc.uvsFocused[8]
		}
	end

	if overlaySrc.colorFocused ~= nil then
		overlay.colorFocused = {
			overlaySrc.colorFocused[1],
			overlaySrc.colorFocused[2],
			overlaySrc.colorFocused[3],
			overlaySrc.colorFocused[4]
		}
	end

	if overlaySrc.uvsPressed ~= nil then
		overlay.uvsPressed = {
			overlaySrc.uvsPressed[1],
			overlaySrc.uvsPressed[2],
			overlaySrc.uvsPressed[3],
			overlaySrc.uvsPressed[4],
			overlaySrc.uvsPressed[5],
			overlaySrc.uvsPressed[6],
			overlaySrc.uvsPressed[7],
			overlaySrc.uvsPressed[8]
		}
	end

	if overlaySrc.colorPressed ~= nil then
		overlay.colorPressed = {
			overlaySrc.colorPressed[1],
			overlaySrc.colorPressed[2],
			overlaySrc.colorPressed[3],
			overlaySrc.colorPressed[4]
		}
	end

	if overlaySrc.uvsSelected ~= nil then
		overlay.uvsSelected = {
			overlaySrc.uvsSelected[1],
			overlaySrc.uvsSelected[2],
			overlaySrc.uvsSelected[3],
			overlaySrc.uvsSelected[4],
			overlaySrc.uvsSelected[5],
			overlaySrc.uvsSelected[6],
			overlaySrc.uvsSelected[7],
			overlaySrc.uvsSelected[8]
		}
	end

	if overlaySrc.colorSelected ~= nil then
		overlay.colorSelected = {
			overlaySrc.colorSelected[1],
			overlaySrc.colorSelected[2],
			overlaySrc.colorSelected[3],
			overlaySrc.colorSelected[4]
		}
	end

	if overlaySrc.uvsDisabled ~= nil then
		overlay.uvsDisabled = {
			overlaySrc.uvsDisabled[1],
			overlaySrc.uvsDisabled[2],
			overlaySrc.uvsDisabled[3],
			overlaySrc.uvsDisabled[4],
			overlaySrc.uvsDisabled[5],
			overlaySrc.uvsDisabled[6],
			overlaySrc.uvsDisabled[7],
			overlaySrc.uvsDisabled[8]
		}
	end

	if overlaySrc.colorDisabled ~= nil then
		overlay.colorDisabled = {
			overlaySrc.colorDisabled[1],
			overlaySrc.colorDisabled[2],
			overlaySrc.colorDisabled[3],
			overlaySrc.colorDisabled[4]
		}
	end

	if overlaySrc.uvsHighlighted ~= nil then
		overlay.uvsHighlighted = {
			overlaySrc.uvsHighlighted[1],
			overlaySrc.uvsHighlighted[2],
			overlaySrc.uvsHighlighted[3],
			overlaySrc.uvsHighlighted[4],
			overlaySrc.uvsHighlighted[5],
			overlaySrc.uvsHighlighted[6],
			overlaySrc.uvsHighlighted[7],
			overlaySrc.uvsHighlighted[8]
		}
	end

	if overlaySrc.colorHighlighted ~= nil then
		overlay.colorHighlighted = {
			overlaySrc.colorHighlighted[1],
			overlaySrc.colorHighlighted[2],
			overlaySrc.colorHighlighted[3],
			overlaySrc.colorHighlighted[4]
		}
	end

	return GuiOverlay.createOverlay(overlay)
end

function GuiOverlay.deleteOverlay(overlay)
	if overlay ~= nil and overlay.overlay ~= nil then
		delete(overlay.overlay)

		overlay.overlay = nil
	end
end

function GuiOverlay.getOverlayColor(overlay, state)
	local color = nil

	if state == GuiOverlay.STATE_NORMAL then
		color = overlay.color
	elseif state == GuiOverlay.STATE_DISABLED then
		color = overlay.colorDisabled
	elseif state == GuiOverlay.STATE_FOCUSED then
		color = overlay.colorFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		color = overlay.colorSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		color = overlay.colorHighlighted
	elseif state == GuiOverlay.STATE_PRESSED then
		color = overlay.colorPressed

		if color == nil then
			color = overlay.colorFocused
		end
	end

	if color == nil then
		color = overlay.color
	end

	return color
end

function GuiOverlay.getOverlayUVs(overlay, state)
	local uvs = nil

	if state == GuiOverlay.STATE_DISABLED then
		uvs = overlay.uvsDisabled
	elseif state == GuiOverlay.STATE_FOCUSED then
		uvs = overlay.uvsFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		uvs = overlay.uvsSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		uvs = overlay.uvsHighlighted
	elseif state == GuiOverlay.STATE_PRESSED then
		uvs = overlay.uvsPressed

		if uvs == nil then
			uvs = overlay.uvsFocused
		end
	end

	if uvs == nil then
		uvs = overlay.uvs
	end

	return uvs
end

function GuiOverlay.renderOverlay(overlay, posX, posY, sizeX, sizeY, state)
	if overlay.overlay ~= nil then
		local r, g, b, a = unpack(GuiOverlay.getOverlayColor(overlay, state))

		if a ~= 0 then
			setOverlayRotation(overlay.overlay, overlay.rotation, sizeX / 2, sizeY / 2)
			setOverlayUVs(overlay.overlay, unpack(GuiOverlay.getOverlayUVs(overlay, state)))
			setOverlayColor(overlay.overlay, r, g, b, a * overlay.alpha)
			renderOverlay(overlay.overlay, posX, posY, sizeX, sizeY)
		end
	end
end

function GuiOverlay.copyColors(overlay, source)
	overlay.color = source.color
	overlay.colorDisabled = source.colorDisabled
	overlay.colorFocused = source.colorFocused
	overlay.colorSelected = source.colorSelected
	overlay.colorHighlighted = source.colorHighlighted
	overlay.colorPressed = source.colorPressed
end
