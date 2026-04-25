ContextActionDisplay = {}
local ContextActionDisplay_mt = Class(ContextActionDisplay, HUDDisplayElement)
ContextActionDisplay.CONTEXT_ICON = {
	FUEL = "fuel",
	ATTACH = "attach",
	NO_DETACH = "noDetach",
	TIP = "tip",
	FILL_BOWL = "fillBowl"
}
ContextActionDisplay.MIN_DISPLAY_DURATION = 100

function ContextActionDisplay.new(hudAtlasPath, inputDisplayManager)
	local backgroundOverlay = ContextActionDisplay.createBackground()
	local self = ContextActionDisplay:superClass().new(ContextActionDisplay_mt, backgroundOverlay, nil)
	self.uiScale = 1
	self.inputDisplayManager = inputDisplayManager
	self.inputGlyphElement = nil
	self.contextIconElements = {}
	self.contextAction = ""
	self.contextIconName = ""
	self.targetText = ""
	self.actionText = ""
	self.contextPriority = -math.huge
	self.contextIconElementRightX = 0
	self.contextIconOffsetY = 0
	self.contextIconOffsetX = 0
	self.contextIconSizeX = 0
	self.actionTextOffsetY = 0
	self.actionTextOffsetX = 0
	self.actionTextSize = 0
	self.targetTextOffsetY = 0
	self.targetTextOffsetX = 0
	self.targetTextSize = 0
	self.borderOffsetX = 0
	self.displayTime = 0

	self:createComponents(hudAtlasPath, inputDisplayManager)

	return self
end

function ContextActionDisplay:setContext(contextAction, contextIconName, targetText, priority, actionText)
	if priority == nil then
		priority = 0
	end

	if self.contextPriority <= priority and self.contextIconElements[contextIconName] ~= nil then
		self.contextAction = contextAction
		self.contextIconName = contextIconName
		self.targetText = targetText
		self.contextPriority = priority
		local eventHelpElement = self.inputDisplayManager:getEventHelpElementForAction(self.contextAction)
		self.contextEventHelpElement = eventHelpElement

		if eventHelpElement ~= nil then
			self.inputGlyphElement:setAction(contextAction)

			self.actionText = actionText or eventHelpElement.textRight or eventHelpElement.textLeft
			local posX, _ = self.inputGlyphElement:getPosition()
			posX = posX + self.inputGlyphElement:getWidth() + self.contextIconOffsetX

			for name, element in pairs(self.contextIconElements) do
				element:setPosition(posX, nil)
			end
		end

		if not self:getVisible() then
			self:setVisible(true, true)
		end
	end

	for name, element in pairs(self.contextIconElements) do
		element:setVisible(name == self.contextIconName)
	end

	self.displayTime = ContextActionDisplay.MIN_DISPLAY_DURATION
end

function ContextActionDisplay:update(dt)
	ContextActionDisplay:superClass().update(self, dt)

	self.displayTime = self.displayTime - dt
	local isVisible = self:getVisible()

	if self.displayTime <= 0 and isVisible and self.animation:getFinished() then
		self:setVisible(false, true)
	end

	if not self.animation:getFinished() then
		self:storeScaledValues()
	elseif self.contextAction ~= "" and not isVisible then
		self:resetContext()
	end
end

function ContextActionDisplay:resetContext()
	self.contextAction = ""
	self.contextIconName = ""
	self.targetText = ""
	self.actionText = ""
	self.contextPriority = -math.huge
end

function ContextActionDisplay:draw()
	if self.contextAction ~= "" and self.contextEventHelpElement ~= nil then
		self.inputGlyphElement:setAction(self.contextAction)

		local contextIconPosX, _ = self.inputGlyphElement:getPosition()
		contextIconPosX = contextIconPosX + self.inputGlyphElement:getWidth() + self.contextIconOffsetX

		for name, element in pairs(self.contextIconElements) do
			element:setPosition(contextIconPosX, nil)
		end

		ContextActionDisplay:superClass().draw(self)

		local baseX, baseY = self:getPosition()

		setTextColor(unpack(ContextActionDisplay.COLOR.ACTION_TEXT))
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local height = self:getHeight()
		local posX = baseX + self.actionTextOffsetX
		local posY = baseY + height + self.actionTextOffsetY

		renderText(posX, posY, self.actionTextSize, self.actionText)

		posX = contextIconPosX + self.contextIconSizeX + self.targetTextOffsetX
		posY = baseY + height * 0.55

		setTextBold(true)

		local width = self:getWidth()
		local textWrapWidth = width - self.targetTextOffsetX - self.contextIconSizeX - self.inputGlyphElement:getWidth() * 2 - self.contextIconOffsetX

		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextWrapWidth(textWrapWidth)
		renderText(posX, posY, self.targetTextSize, self.targetText)
		setTextWrapWidth(0)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)

		if g_uiDebugEnabled then
			local yPixel = 1 / g_screenHeight

			setOverlayColor(GuiElement.debugOverlay, 0, 1, 1, 1)
			renderOverlay(GuiElement.debugOverlay, posX, posY, textWrapWidth, yPixel)
		end
	end
end

function ContextActionDisplay:setScale(uiScale)
	ContextActionDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = ContextActionDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	self:storeScaledValues()
end

function ContextActionDisplay:storeScaledValues()
	self.contextIconOffsetX, self.contextIconOffsetY = self:scalePixelToScreenVector(ContextActionDisplay.POSITION.CONTEXT_ICON)
	self.contextIconSizeX = self:scalePixelToScreenWidth(ContextActionDisplay.SIZE.CONTEXT_ICON[1])
	self.borderOffsetX = self:scalePixelToScreenWidth(ContextActionDisplay.OFFSET.X)
	self.actionTextOffsetX, self.actionTextOffsetY = self:scalePixelToScreenVector(ContextActionDisplay.POSITION.ACTION_TEXT)
	self.actionTextSize = self:scalePixelToScreenHeight(ContextActionDisplay.TEXT_SIZE.ACTION_TEXT)
	self.targetTextOffsetX, self.targetTextOffsetY = self:scalePixelToScreenVector(ContextActionDisplay.POSITION.TARGET_TEXT)
	self.targetTextSize = self:scalePixelToScreenHeight(ContextActionDisplay.TEXT_SIZE.TARGET_TEXT)
end

function ContextActionDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(ContextActionDisplay.POSITION.BACKGROUND))

	return 0.5 - width * 0.5 - offX * scale, g_safeFrameOffsetY - offY * scale
end

function ContextActionDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(ContextActionDisplay.SIZE.BACKGROUND))
	local posX, posY = ContextActionDisplay.getBackgroundPosition(1, width)
	local overlay = Overlay:new(nil, posX, posY, width, height)

	return overlay
end

function ContextActionDisplay:createComponents(hudAtlasPath, inputDisplayManager)
	local baseX, baseY = self:getPosition()

	self:createFrame(hudAtlasPath, baseX, baseY)
	self:createInputGlyph(hudAtlasPath, baseX, baseY, inputDisplayManager)
	self:createActionIcons(hudAtlasPath, baseX, baseY)
	self:storeOriginalPosition()
end

function ContextActionDisplay:createInputGlyph(hudAtlasPath, baseX, baseY, inputDisplayManager)
	local width, height = getNormalizedScreenValues(unpack(ContextActionDisplay.SIZE.INPUT_ICON))
	local offX, offY = getNormalizedScreenValues(unpack(ContextActionDisplay.POSITION.INPUT_ICON))
	local element = InputGlyphElement:new(inputDisplayManager, width, height)
	local posX = baseX + offX
	local posY = baseY + offY + (self:getHeight() - height) * 0.5

	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(ContextActionDisplay.COLOR.INPUT_ICON)

	self.inputGlyphElement = element

	self:addChild(element)
end

function ContextActionDisplay:createFrame(hudAtlasPath, baseX, baseY)
	local frame = HUDFrameElement:new(hudAtlasPath, baseX, baseY, self:getWidth(), self:getHeight())

	frame:setColor(unpack(HUD.COLOR.FRAME_BACKGROUND))
	self:addChild(frame)
end

function ContextActionDisplay:createActionIcons(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(ContextActionDisplay.POSITION.CONTEXT_ICON))
	local width, height = getNormalizedScreenValues(unpack(ContextActionDisplay.SIZE.CONTEXT_ICON))
	local centerY = baseY + (self:getHeight() - height) * 0.5

	for _, iconName in pairs(ContextActionDisplay.CONTEXT_ICON) do
		local iconOverlay = Overlay:new(hudAtlasPath, baseX + posX, centerY, width, height)
		local uvs = ContextActionDisplay.UV[iconName]

		iconOverlay:setUVs(GuiUtils.getUVs(uvs))
		iconOverlay:setColor(unpack(ContextActionDisplay.COLOR.CONTEXT_ICON))

		local iconElement = HUDElement:new(iconOverlay)

		iconElement:setVisible(false)

		self.contextIconElements[iconName] = iconElement

		self:addChild(iconElement)
	end
end

ContextActionDisplay.UV = {
	[ContextActionDisplay.CONTEXT_ICON.ATTACH] = {
		48,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.FUEL] = {
		192,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.TIP] = {
		384,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.NO_DETACH] = {
		96,
		0,
		48,
		48
	},
	[ContextActionDisplay.CONTEXT_ICON.FILL_BOWL] = {
		96,
		0,
		48,
		48
	}
}
ContextActionDisplay.SIZE = {
	BACKGROUND = {
		775,
		102
	},
	INPUT_ICON = {
		52,
		52
	},
	CONTEXT_ICON = {
		52,
		52
	}
}
ContextActionDisplay.OFFSET = {
	X = 37.5
}
ContextActionDisplay.TEXT_SIZE = {
	TARGET_TEXT = 30,
	ACTION_TEXT = 21
}
ContextActionDisplay.POSITION = {
	BACKGROUND = {
		0,
		0
	},
	INPUT_ICON = {
		12,
		0
	},
	CONTEXT_ICON = {
		6,
		0
	},
	ACTION_TEXT = {
		0,
		6
	},
	TARGET_TEXT = {
		30,
		6
	}
}
ContextActionDisplay.COLOR = {
	INPUT_ICON = {
		1,
		1,
		1,
		1
	},
	CONTEXT_ICON = {
		1,
		1,
		1,
		1
	},
	ACTION_TEXT = {
		1,
		1,
		1,
		1
	},
	TARGET_TEXT = {
		1,
		1,
		1,
		1
	}
}
