TopNotification = {}
local TopNotification_mt = Class(TopNotification, HUDDisplayElement)
TopNotification.NO_NOTIFICATION = {
	text = "",
	info = "",
	title = "",
	duration = 0
}
TopNotification.DEFAULT_DURATION = 5000
TopNotification.FADE_DURATION = 500
TopNotification.ICON = {
	RADIO = "radio"
}

function TopNotification.new(hudAtlasPath)
	local backgroundOverlay = TopNotification.createBackground(hudAtlasPath)
	local self = TopNotification:superClass().new(TopNotification_mt, backgroundOverlay, nil)
	self.currentNotification = TopNotification.NO_NOTIFICATION
	self.icons = {}
	self.titleTextSize = 0
	self.descTextSize = 0
	self.infoTextSize = 0
	self.maxTextWidth = 0
	self.titleOffsetY = 0
	self.titleOffsetX = 0
	self.descOffsetY = 0
	self.descOffsetX = 0
	self.infoOffsetY = 0
	self.infoOffsetX = 0
	self.iconOffsetY = 0
	self.iconOffsetX = 0
	self.notificationStartDuration = 0

	self:storeScaledValues()
	self:createComponents(hudAtlasPath)
	self:createIconOverlays()

	return self
end

function TopNotification:delete()
	for k, overlay in pairs(self.icons) do
		overlay:delete()

		self.icons[k] = nil
	end

	TopNotification:superClass().delete(self)
end

function TopNotification:setNotification(title, text, info, iconKey, duration)
	local icon = nil

	if iconKey ~= nil and self.icons[iconKey] ~= nil then
		icon = self.icons[iconKey]
	end

	if duration == nil or duration < 0 then
		duration = TopNotification.DEFAULT_DURATION
	end

	local notification = {
		title = title,
		text = text,
		info = info,
		icon = icon,
		duration = duration
	}
	self.notificationStartDuration = duration
	self.currentNotification = notification

	self:setVisible(true, true)
end

function TopNotification:getHidingTranslation()
	return 0, 0.5
end

function TopNotification:update(dt)
	TopNotification:superClass().update(self, dt)

	if self:getVisible() and self.currentNotification ~= TopNotification.NO_NOTIFICATION then
		if self.currentNotification.duration < TopNotification.FADE_DURATION and self.animation:getFinished() then
			self:setVisible(false, true)
		end

		if self.currentNotification.duration <= 0 then
			self.currentNotification = TopNotification.NO_NOTIFICATION
		else
			self.currentNotification.duration = self.currentNotification.duration - dt
		end
	end
end

function TopNotification:draw()
	if self:getVisible() then
		TopNotification:superClass().draw(self)

		local notification = self.currentNotification
		local title = Utils.limitTextToWidth(notification.title, self.titleTextSize, self.maxTextWidth, false, "...")
		local text = Utils.limitTextToWidth(notification.text, self.descTextSize, self.maxTextWidth, false, "...")
		local info = Utils.limitTextToWidth(notification.info, self.infoTextSize, self.maxTextWidth, false, "...")
		local fadeAlpha = 1

		if self.notificationStartDuration - self.currentNotification.duration < TopNotification.FADE_DURATION then
			fadeAlpha = (self.notificationStartDuration - self.currentNotification.duration) / TopNotification.FADE_DURATION
		elseif self.currentNotification.duration < TopNotification.FADE_DURATION then
			fadeAlpha = self.currentNotification.duration / TopNotification.FADE_DURATION
		end

		local _, _, _, baseAlpha = self:getColor()
		local baseX, baseY = self:getPosition()
		local width = self:getWidth()
		local height = self:getHeight()
		local alpha = baseAlpha * fadeAlpha

		if notification.icon ~= nil then
			local icon = notification.icon

			icon:setColor(nil, , , alpha)
			icon:setPosition(baseX + width - notification.icon.width + self.iconOffsetX, baseY + (height - notification.icon.height) * 0.5)
			icon:render()
		end

		local r, g, b, a = unpack(TopNotification.COLOR.TEXT_TITLE)

		setTextColor(r, g, b, a * alpha)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_CENTER)

		local centerX = baseX + width * 0.5

		renderText(centerX + self.titleOffsetX, baseY + self.titleOffsetY, self.titleTextSize, title)

		r, g, b, a = unpack(TopNotification.COLOR.TEXT_DESC)

		setTextColor(r, g, b, a * alpha)
		renderText(centerX + self.descOffsetX, baseY + self.descOffsetY, self.descTextSize, text)

		r, g, b, a = unpack(TopNotification.COLOR.TEXT_INFO)

		setTextColor(r, g, b, a * alpha)
		renderText(centerX + self.infoOffsetX, baseY + self.infoOffsetY, self.infoTextSize, info)
	end
end

function TopNotification.getBackgroundPosition(uiScale, width, height)
	local offX, offY = getNormalizedScreenValues(unpack(TopNotification.POSITION.SELF))

	return 0.5 - width * 0.5 + offX * uiScale, 1 - g_safeFrameOffsetY - height + offY * uiScale
end

function TopNotification:setScale(uiScale)
	TopNotification:superClass().setScale(self, uiScale)
	self:storeScaledValues()

	local width, height = self:scalePixelToScreenVector(TopNotification.SIZE.SELF)
	local posX, posY = TopNotification.getBackgroundPosition(uiScale, width, height)

	self:setPosition(posX, posY)
end

function TopNotification:storeScaledValues()
	self.titleTextSize = self:scalePixelToScreenHeight(TopNotification.TEXT_SIZE.TITLE)
	self.descTextSize = self:scalePixelToScreenHeight(TopNotification.TEXT_SIZE.TEXT)
	self.infoTextSize = self:scalePixelToScreenHeight(TopNotification.TEXT_SIZE.INFO)
	self.maxTextWidth = self:scalePixelToScreenWidth(TopNotification.TEXT_SIZE.MAX_TEXT_WIDTH)
	self.titleOffsetX, self.titleOffsetY = self:scalePixelToScreenVector(TopNotification.POSITION.TITLE_OFFSET)
	self.descOffsetX, self.descOffsetY = self:scalePixelToScreenVector(TopNotification.POSITION.TEXT_OFFSET)
	self.infoOffsetX, self.infoOffsetY = self:scalePixelToScreenVector(TopNotification.POSITION.INFO_OFFSET)
	self.iconOffsetX, self.iconOffsetY = self:scalePixelToScreenVector(TopNotification.POSITION.ICON)
	local iconWidth, iconHeight = self:scalePixelToScreenVector(TopNotification.SIZE.ICON)

	for _, overlay in pairs(self.icons) do
		overlay:setDimension(iconWidth, iconHeight)
	end
end

function TopNotification.createBackground(hudAtlasPath)
	local width, height = getNormalizedScreenValues(unpack(TopNotification.SIZE.SELF))
	local posX, posY = TopNotification.getBackgroundPosition(1, width, height)
	local overlay = Overlay:new(nil, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(TopNotification.UV.BACKGROUND))

	return overlay
end

function TopNotification:createComponents(hudAtlasPath)
	local posX, posY = self:getPosition()
	local width = self:getWidth()
	local height = self:getHeight()
	local frame = HUDFrameElement:new(hudAtlasPath, posX, posY, width, height)

	frame:setColor(unpack(HUD.COLOR.FRAME_BACKGROUND))
	self:addChild(frame)
end

function TopNotification:createIconOverlays()
	local width, height = getNormalizedScreenValues(unpack(TopNotification.SIZE.ICON))
	local iconOverlay = Overlay:new(g_baseUIFilename, 0, 0, width, height)

	iconOverlay:setUVs(GuiUtils.getUVs(TopNotification.UV.ICON_RADIO_STREAM))
	iconOverlay:setColor(unpack(TopNotification.COLOR.ICON))

	self.icons[TopNotification.ICON.RADIO] = iconOverlay
end

TopNotification.UV = {
	BACKGROUND = {
		8,
		8,
		2,
		2
	},
	ICON_RADIO_STREAM = {
		390,
		208,
		64,
		64
	}
}
TopNotification.POSITION = {
	SELF = {
		0,
		0
	},
	TITLE_OFFSET = {
		0,
		56
	},
	TEXT_OFFSET = {
		0,
		32
	},
	INFO_OFFSET = {
		0,
		8
	},
	ICON = {
		-4,
		0
	}
}
TopNotification.TEXT_SIZE = {
	TEXT = 22,
	TITLE = 36,
	INFO = 16,
	MAX_TEXT_WIDTH = 700
}
TopNotification.SIZE = {
	SELF = {
		775,
		90
	},
	ICON = {
		48,
		48
	}
}
TopNotification.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		1
	},
	TEXT_TITLE = {
		1,
		1,
		1,
		1
	},
	TEXT_DESC = {
		0.8,
		0.8,
		0.8,
		1
	},
	TEXT_INFO = {
		0.7,
		0.7,
		0.7,
		1
	},
	ICON = {
		1,
		1,
		1,
		1
	}
}
