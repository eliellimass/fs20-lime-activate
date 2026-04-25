TextElement = {}
local TextElement_mt = Class(TextElement, GuiElement)
TextElement.VERTICAL_ALIGNMENT = {
	TOP = "top",
	BOTTOM = "bottom",
	MIDDLE = "middle"
}

function TextElement:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = TextElement_mt
	end

	local self = GuiElement:new(target, custom_mt)
	self.textColor = {
		1,
		1,
		1,
		1
	}
	self.textDisabledColor = {
		0.5,
		0.5,
		0.5,
		1
	}
	self.textSelectedColor = {
		1,
		1,
		1,
		1
	}
	self.textHighlightedColor = {
		1,
		1,
		1,
		1
	}
	self.textOffset = {
		0,
		0
	}
	self.textFocusedOffset = {
		0,
		0
	}
	self.textSize = 0.03
	self.textBold = false
	self.textSelectedBold = false
	self.textHighlightedBold = false
	self.text2Color = {
		1,
		1,
		1,
		1
	}
	self.text2DisabledColor = {
		1,
		1,
		1,
		0
	}
	self.text2SelectedColor = {
		0,
		0,
		0,
		0.5
	}
	self.text2HighlightedColor = {
		0,
		0,
		0,
		0.5
	}
	self.text2Offset = {
		0,
		0
	}
	self.text2FocusedOffset = {
		0,
		0
	}
	self.text2Size = 0
	self.text2Bold = false
	self.text2SelectedBold = false
	self.text2HighlightedBold = false
	self.textUpperCase = false
	self.textLinesPerPage = 0
	self.currentPage = 1
	self.textResetSize = false
	self.defaultTextSize = self.textSize
	self.defaultText2Size = self.text2Size
	self.textLineHeightScale = RenderText.DEFAULT_LINE_HEIGHT_SCALE
	self.text = ""
	self.textAlignment = RenderText.ALIGN_CENTER
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
	self.ignoreDisabled = false
	self.textAutoSize = false
	self.textMaxWidth = nil
	self.textResizeWidth = nil
	self.textWrapWidth = 1

	return self
end

function TextElement:loadFromXML(xmlFile, key)
	TextElement:superClass().loadFromXML(self, xmlFile, key)

	self.textColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textColor"), self.textColor)
	self.textSelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textSelectedColor"), self.textSelectedColor)
	self.text2SelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2SelectedColor"), self.text2SelectedColor)
	self.textHighlightedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textHighlightedColor"), self.textHighlightedColor)
	self.text2HighlightedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2HighlightedColor"), self.text2HighlightedColor)
	self.textDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textDisabledColor"), self.textDisabledColor)
	self.text2DisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2DisabledColor"), self.text2DisabledColor)
	self.text2Color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2Color"), self.text2Color)
	self.textOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textOffset"), self.outputSize, self.textOffset)
	self.textFocusedOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textFocusedOffset"), self.outputSize, self.textFocusedOffset)
	self.text2Offset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#text2Offset"), self.outputSize, self.text2Offset)
	self.text2FocusedOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#text2FocusedOffset"), self.outputSize, self.text2FocusedOffset)
	self.textSize = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textSize"), {
		self.outputSize[2]
	}, {
		self.textSize
	}))
	self.text2Size = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#text2Size"), {
		self.outputSize[2]
	}, {
		self.text2Size
	}))
	self.textResizeWidth = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textResizeWidth"), {
		self.outputSize[1]
	}, {
		self.textResizeWidth
	}))
	self.textMaxWidth = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textMaxWidth"), {
		self.outputSize[1]
	}, {
		self.textMaxWidth
	}))
	self.textWrapWidth = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#textWrapWidth"), {
		self.outputSize[1]
	}, {
		self.textWrapWidth
	}))
	self.textBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textBold"), self.textBold)
	self.textSelectedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textSelectedBold"), self.textSelectedBold)
	self.textHighlightedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textHighlightedBold"), self.textHighlightedBold)
	self.textUpperCase = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textUpperCase"), self.textUpperCase)
	self.text2Bold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2Bold"), self.text2Bold)
	self.text2SelectedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2SelectedBold"), self.text2SelectedBold)
	self.text2HighlightedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2HighlightedBold"), self.text2HighlightedBold)
	self.textResetSize = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textResetSize"), self.textResetSize)
	self.textLinesPerPage = Utils.getNoNil(getXMLInt(xmlFile, key .. "#textLinesPerPage"), self.textLinesPerPage)
	self.textMaxNumLines = Utils.getNoNil(getXMLInt(xmlFile, key .. "#textMaxNumLines"), self.textMaxNumLines)
	self.textResizeLines = Utils.getNoNil(getXMLInt(xmlFile, key .. "#textResizeLines"), self.textResizeLines)
	self.textLineHeightScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#textLineHeightScale"), self.textLineHeightScale)
	self.textAutoSize = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textAutoSize"), self.textAutoSize)
	self.defaultTextSize = self.textSize
	self.defaultText2Size = self.text2Size

	if self.textMaxNumLines ~= nil and self.textWrapWidth == nil then
		print("Warning: textWrapWidth has to be set if textMaxNumLines is used.")

		self.textMaxNumLines = nil
	end

	local textAlignment = getXMLString(xmlFile, key .. "#textAlignment")

	if textAlignment ~= nil then
		textAlignment = textAlignment:lower()

		if textAlignment == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif textAlignment == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
	end

	local textVerticalAlignment = getXMLString(xmlFile, key .. "#textVerticalAlignment") or ""
	local verticalAlignKey = string.upper(textVerticalAlignment)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[verticalAlignKey] or self.textVerticalAlignment
	self.ignoreDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreDisabled"), self.ignoreDisabled)
	local text = getXMLString(xmlFile, key .. "#text")

	if GS_IS_CONSOLE_VERSION then
		local textConsole = getXMLString(xmlFile, key .. "#textConsole")

		if textConsole ~= nil then
			text = textConsole
		end
	end

	if text ~= nil then
		local addColon = false
		local length = text:len()

		if text:sub(length, length + 1) == ":" then
			text = text:sub(1, length - 1)
			addColon = true
		end

		if text:sub(1, 6) == "$l10n_" then
			text = g_i18n:getText(text:sub(7))
		end

		if addColon and text ~= "" then
			text = text .. ":"
		end

		self:setText(text, false, true)
	end

	self:addCallback(xmlFile, key .. "#onTextChanged", "onTextChangedCallback")
	self:updateSize()
end

function TextElement:loadProfile(profile, applyProfile)
	TextElement:superClass().loadProfile(self, profile, applyProfile)

	self.textColor = GuiUtils.getColorArray(profile:getValue("textColor"), self.textColor)
	self.textSelectedColor = GuiUtils.getColorArray(profile:getValue("textSelectedColor"), self.textSelectedColor)
	self.textHighlightedColor = GuiUtils.getColorArray(profile:getValue("textHighlightedColor"), self.textHighlightedColor)
	self.textDisabledColor = GuiUtils.getColorArray(profile:getValue("textDisabledColor"), self.textDisabledColor)
	self.text2Color = GuiUtils.getColorArray(profile:getValue("text2Color"), self.text2Color)
	self.text2SelectedColor = GuiUtils.getColorArray(profile:getValue("text2SelectedColor"), self.text2SelectedColor)
	self.text2HighlightedColor = GuiUtils.getColorArray(profile:getValue("text2HighlightedColor"), self.text2HighlightedColor)
	self.text2DisabledColor = GuiUtils.getColorArray(profile:getValue("text2DisabledColor"), self.text2DisabledColor)
	self.textSize = unpack(GuiUtils.getNormalizedValues(profile:getValue("textSize"), {
		self.outputSize[2]
	}, {
		self.textSize
	}))
	self.textOffset = GuiUtils.getNormalizedValues(profile:getValue("textOffset"), self.outputSize, self.textOffset)
	self.textFocusedOffset = GuiUtils.getNormalizedValues(profile:getValue("textFocusedOffset"), self.outputSize, {
		self.textOffset[1],
		self.textOffset[2]
	})
	self.text2Size = unpack(GuiUtils.getNormalizedValues(profile:getValue("text2Size"), {
		self.outputSize[2]
	}, {
		self.text2Size
	}))
	self.text2Offset = GuiUtils.getNormalizedValues(profile:getValue("text2Offset"), self.outputSize, self.text2Offset)
	self.text2FocusedOffset = GuiUtils.getNormalizedValues(profile:getValue("text2FocusedOffset"), self.outputSize, {
		self.text2Offset[1],
		self.text2Offset[2]
	})
	self.textResizeWidth = unpack(GuiUtils.getNormalizedValues(profile:getValue("textResizeWidth"), {
		self.outputSize[1]
	}, {
		self.textResizeWidth
	}))
	self.textMaxWidth = unpack(GuiUtils.getNormalizedValues(profile:getValue("textMaxWidth"), {
		self.outputSize[1]
	}, {}))
	self.textWrapWidth = unpack(GuiUtils.getNormalizedValues(profile:getValue("textWrapWidth"), {
		self.outputSize[1]
	}, {
		1
	}))
	self.textResetSize = profile:getBool("textResetSize", self.textResetSize)
	self.textBold = profile:getBool("textBold", self.textBold)
	self.textSelectedBold = profile:getBool("textSelectedBold", self.textSelectedBold)
	self.textHighlightedBold = profile:getBool("textHighlightedBold", self.textHighlightedBold)
	self.text2Bold = profile:getBool("text2Bold", self.text2Bold)
	self.text2SelectedBold = profile:getBool("text2SelectedBold", self.text2SelectedBold)
	self.text2HighlightedBold = profile:getBool("text2HighlightedBold", self.text2HighlightedBold)
	self.textUpperCase = profile:getBool("textUpperCase", self.textUpperCase)
	self.textLinesPerPage = profile:getNumber("textLinesPerPage", self.textLinesPerPage)
	self.textMaxNumLines = profile:getNumber("textMaxNumLines", self.textMaxNumLines)
	self.textResizeLines = profile:getNumber("textResizeLines", self.textResizeLines)
	self.textLineHeightScale = profile:getNumber("textLineHeightScale", self.textLineHeightScale)
	self.textAutoSize = profile:getBool("textAutoSize", self.textAutoSize)
	self.ignoreDisabled = profile:getBool("ignoreDisabled", self.ignoreDisabled)
	local textAlignment = profile:getValue("textAlignment")

	if textAlignment ~= nil then
		textAlignment = textAlignment:lower()

		if textAlignment == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif textAlignment == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
	end

	local textVerticalAlignment = profile:getValue("textVerticalAlignment", "")
	local verticalAlignKey = string.upper(textVerticalAlignment)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[verticalAlignKey] or self.textVerticalAlignment

	if applyProfile then
		self:applyTextAspectScale()
		self:updateSize()
	end
end

function TextElement:copyAttributes(src)
	TextElement:superClass().copyAttributes(self, src)

	self.text = src.text
	self.textColor = ListUtil.copyTable(src.textColor)
	self.textSelectedColor = ListUtil.copyTable(src.textSelectedColor)
	self.textHighlightedColor = ListUtil.copyTable(src.textHighlightedColor)
	self.textDisabledColor = ListUtil.copyTable(src.textDisabledColor)
	self.text2Color = ListUtil.copyTable(src.text2Color)
	self.text2SelectedColor = ListUtil.copyTable(src.text2SelectedColor)
	self.text2HighlightedColor = ListUtil.copyTable(src.text2HighlightedColor)
	self.text2DisabledColor = ListUtil.copyTable(src.text2DisabledColor)
	self.textSize = src.textSize
	self.textOffset = ListUtil.copyTable(src.textOffset)
	self.textFocusedOffset = ListUtil.copyTable(src.textFocusedOffset)
	self.text2Size = src.text2Size
	self.text2Offset = ListUtil.copyTable(src.text2Offset)
	self.text2FocusedOffset = ListUtil.copyTable(src.text2FocusedOffset)
	self.textResizeWidth = src.textResizeWidth
	self.textMaxWidth = src.textMaxWidth
	self.textWrapWidth = src.textWrapWidth
	self.ignoreDisabled = src.ignoreDisabled
	self.textAutoSize = src.textAutoSize
	self.textResetSize = src.textResetSize
	self.textBold = src.textBold
	self.textSelectedBold = src.textSelectedBold
	self.textHighlightedBold = src.textHighlightedBold
	self.text2Bold = src.text2Bold
	self.text2SelectedBold = src.text2SelectedBold
	self.text2HighlightedBold = src.text2HighlightedBold
	self.textUpperCase = src.textUpperCase
	self.textLinesPerPage = src.textLinesPerPage
	self.textMaxNumLines = src.textMaxNumLines
	self.textResizeLines = src.textResizeLines
	self.textAlignment = src.textAlignment
	self.currentPage = src.currentPage
	self.defaultTextSize = src.defaultTextSize
	self.defaultText2Size = src.defaultText2Size
	self.textLineHeightScale = src.textLineHeightScale
	self.textVerticalAlignment = src.textVerticalAlignment
	self.onTextChangedCallback = src.onTextChangedCallback
end

function TextElement:setTextSize(size)
	self.textSize = size

	self:updateSize()
end

function TextElement:applyTextAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.textOffset[1] = self.textOffset[1] * xScale
	self.textFocusedOffset[1] = self.textFocusedOffset[1] * xScale
	self.text2Offset[1] = self.text2Offset[1] * xScale
	self.text2FocusedOffset[1] = self.text2FocusedOffset[1] * xScale

	if self.textMaxWidth ~= nil then
		self.textMaxWidth = self.textMaxWidth * xScale
	end

	if self.textWrapWidth ~= nil then
		self.textWrapWidth = self.textWrapWidth * xScale
	end

	self.textSize = self.textSize * yScale
	self.text2Size = self.text2Size * yScale
	self.textOffset[2] = self.textOffset[2] * yScale
	self.textFocusedOffset[2] = self.textFocusedOffset[2] * yScale
	self.text2Offset[2] = self.text2Offset[2] * yScale
	self.text2FocusedOffset[2] = self.text2FocusedOffset[2] * yScale

	self:updateScaledWidth(xScale, yScale)
end

function TextElement:applyScreenAlignment()
	self:applyTextAspectScale()
	TextElement:superClass().applyScreenAlignment(self)
end

function TextElement:setText(text, forceTextSize, isInitializing)
	text = tostring(text)

	if self.textUpperCase then
		text = utf8ToUpper(text)
	end

	if self.textResizeLines ~= nil and self.textWrapWidth ~= nil then
		setTextWrapWidth(self.textWrapWidth)

		local lengthWithNoLineLimit = getTextLength(self.textSize, text, 99999)

		while getTextLength(self.textSize, text, self.textResizeLines) < lengthWithNoLineLimit do
			self.textSize = self.textSize - self.defaultTextSize * 0.05
			self.text2Size = self.text2Size - self.defaultText2Size * 0.05
		end

		setTextWrapWidth(0)
	end

	local leftover = nil

	if self.textMaxNumLines ~= nil and self.textWrapWidth ~= nil then
		setTextWrapWidth(self.textWrapWidth)

		local l = getTextLength(self.textSize, text, self.textMaxNumLines)

		setTextWrapWidth(0)

		leftover = utf8Substr(text, l)
		text = utf8Substr(text, 0, l)
	end

	local textHasChanged = self.text ~= text
	self.text = text

	if self.textResetSize then
		self.textSize = self.defaultTextSize
		self.text2Size = self.defaultText2Size
	end

	if self.textResizeWidth ~= nil then
		setTextWrapWidth(self.textWrapWidth, false)

		while self.textResizeWidth < self:getTextWidth() and self.textSize > self.defaultTextSize * 0.1 do
			self.textSize = self.textSize - self.defaultTextSize * 0.05
			self.text2Size = self.text2Size - self.defaultText2Size * 0.05
		end

		setTextWrapWidth(0)
	end

	self:raiseCallback("onTextChangedCallback", self, self.text)

	if textHasChanged and not isInitializing then
		self:updateScaledWidth(1, 1)
	end

	self:updateSize(forceTextSize)

	return leftover
end

function TextElement:getText()
	return self.text
end

function TextElement:setTextColor(r, g, b, a)
	self.textColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextSelectedColor(r, g, b, a)
	self.textSelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextHighlightedColor(r, g, b, a)
	self.textHighlightedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:getTextColor()
	if self.disabled and not self.ignoreDisabled then
		return self.textDisabledColor
	elseif self:getIsSelected() then
		return self.textSelectedColor
	elseif self:getIsHighlighted() then
		return self.textHighlightedColor
	else
		return self.textColor
	end
end

function TextElement:setText2Color(r, g, b, a)
	self.text2Color = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setText2SelectedColor(r, g, b, a)
	self.text2SelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setText2HighlightedColor(r, g, b, a)
	self.text2HighlightedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:getText2Color()
	if self.disabled and not self.ignoreDisabled then
		return self.text2DisabledColor
	elseif self:getIsSelected() then
		return self.text2SelectedColor
	elseif self:getIsHighlighted() then
		return self.text2HighlightedColor
	else
		return self.text2Color
	end
end

function TextElement:getTextWidth()
	setTextBold(self.textBold)

	local width = getTextWidth(self.textSize, self.text)

	setTextBold(false)

	return width
end

function TextElement:getTextHeight()
	setTextWrapWidth(self.textWrapWidth)
	setTextBold(self.textBold)
	setTextLineHeightScale(self.textLineHeightScale)

	local height, numLines = getTextHeight(self.textSize, self.text)

	setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	setTextBold(false)
	setTextWrapWidth(0)

	return height, numLines
end

function TextElement:getTextOffset()
	local xOffset = self.textOffset[1]
	local yOffset = self.textOffset[2]
	local state = self:getOverlayState()

	if state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED or state == GuiOverlay.STATE_HIGHLIGHTED then
		xOffset = self.textFocusedOffset[1]
		yOffset = self.textFocusedOffset[2]
	end

	return xOffset, yOffset
end

function TextElement:getText2Offset()
	local xOffset = self.text2Offset[1]
	local yOffset = self.text2Offset[2]
	local state = self:getOverlayState()

	if state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED or state == GuiOverlay.STATE_HIGHLIGHTED then
		xOffset = self.text2FocusedOffset[1]
		yOffset = self.text2FocusedOffset[2]
	end

	return xOffset, yOffset
end

function TextElement:getDoRenderText()
	return true
end

function TextElement:getTextPositionX()
	local xPos = self.absPosition[1]

	if self.textAlignment == RenderText.ALIGN_CENTER then
		xPos = xPos + self.absSize[1] * 0.5
	elseif self.textAlignment == RenderText.ALIGN_RIGHT then
		xPos = xPos + self.absSize[1]
	end

	return xPos
end

function TextElement:getTextPositionY(lineHeight, totalHeight)
	local yPos = self.absPosition[2]

	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
		yPos = yPos + self.absSize[2] - lineHeight
	elseif self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
		yPos = yPos + (self.absSize[2] + totalHeight) * 0.5 - lineHeight
	else
		yPos = yPos + totalHeight - lineHeight
	end

	return yPos
end

function TextElement:getTextPosition(text)
	local lineHeight = getTextHeight(self.textSize, utf8ToUpper(string.sub(text, 1, 1)))
	local totalHeight = getTextHeight(self.textSize, text)
	local xPos = self:getTextPositionX()
	local yPos = self:getTextPositionY(lineHeight, totalHeight)

	return xPos, yPos
end

function TextElement:draw()
	if self:getDoRenderText() and self.text ~= nil and self.text ~= "" then
		setTextAlignment(self.textAlignment)
		setTextWrapWidth(self.textWrapWidth)
		setTextLineBounds((self.currentPage - 1) * self.textLinesPerPage, self.textLinesPerPage)
		setTextLineHeightScale(self.textLineHeightScale)

		local text = self.text

		if self.textUpperCase then
			text = utf8ToUpper(text)
		end

		if self.textMaxWidth ~= nil then
			text = Utils.limitTextToWidth(text, self.textSize, self.textMaxWidth, false, "...")
		end

		local bold = self.textBold or self.textSelectedBold and self:getIsSelected() or self.textHighlightedBold and self:getIsHighlighted()

		setTextBold(bold)

		local xPos, yPos = self:getTextPosition(text)

		if self.text2Size > 0 then
			local x2Offset, y2Offset = self:getText2Offset()
			local bold = self.text2Bold or self.text2SelectedBold and self:getIsSelected() or self.text2HighlightedBold and self:getIsHighlighted()

			setTextBold(bold)

			local r, g, b, a = unpack(self:getText2Color())

			setTextColor(r, g, b, a * self.alpha)
			renderText(xPos + x2Offset, yPos + y2Offset, self.text2Size, text)
		end

		local r, g, b, a = unpack(self:getTextColor())

		setTextColor(r, g, b, a * self.alpha)

		local xOffset, yOffset = self:getTextOffset()

		renderText(xPos + xOffset, yPos + yOffset, self.textSize, text)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
		setTextColor(1, 1, 1, 1)
		setTextLineBounds(0, 0)
		setTextWrapWidth(0)

		if self.debugEnabled or g_uiDebugEnabled then
			if self.textMaxWidth ~= nil then
				local yPixel = 1 / g_screenHeight

				setOverlayColor(GuiElement.debugOverlay, 0, 1, 0, 1)

				local x = xPos + xOffset

				if self.textAlignment == RenderText.ALIGN_RIGHT then
					x = x - self.textMaxWidth
				elseif self.textAlignment == RenderText.ALIGN_CENTER then
					x = x - self.textMaxWidth / 2
				end

				renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, self.textMaxWidth, yPixel)
			elseif self.textWrapWidth ~= 1 and self.textMaxNumLines ~= nil then
				local yPixel = 1 / g_screenHeight

				setOverlayColor(GuiElement.debugOverlay, 0, 1, 1, 1)

				local x = xPos + xOffset

				if self.textAlignment == RenderText.ALIGN_RIGHT then
					x = x - self.textWrapWidth
				elseif self.textAlignment == RenderText.ALIGN_CENTER then
					x = x - self.textWrapWidth / 2
				end

				renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, self.textWrapWidth, yPixel)
			end
		end
	end

	TextElement:superClass().draw(self)
end

function TextElement:updateScaledWidth(xScale)
	if self.text ~= nil and self.text ~= "" and self.absSize[1] == 0 and self.absSize[2] == 0 then
		local width = self:getTextWidth()

		if self.textWrapWidth > 0 then
			width = math.min(width, self.textWrapWidth)
		end

		self:setSize(width / xScale, self.textSize)
	end
end

function TextElement:updateSize(forceTextSize)
	if not self.textAutoSize and not forceTextSize then
		return
	end

	local offset = self:getTextOffset()
	local textWidth = self:getTextWidth()
	local width = offset + textWidth
	local height = self.absSize[2]

	if height == 0 then
		height = self.textSize
	end

	self:setSize(width, height)

	if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
		self.parent:invalidateLayout()
	end
end
