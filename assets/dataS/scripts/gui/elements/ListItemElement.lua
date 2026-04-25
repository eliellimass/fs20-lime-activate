ListItemElement = {}
local ListItemElement_mt = Class(ListItemElement, BitmapElement)

function ListItemElement:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = ListItemElement_mt
	end

	local self = BitmapElement:new(target, custom_mt)
	self.mouseEntered = false
	self.allowSelected = true
	self.allowFocus = true
	self.autoSelectChildren = false
	self.handleFocus = false

	return self
end

function ListItemElement:loadFromXML(xmlFile, key)
	ListItemElement:superClass().loadFromXML(self, xmlFile, key)

	self.allowSelected = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSelected"), self.allowSelected)
	self.allowFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowFocus"), self.allowFocus)
	self.autoSelectChildren = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoSelectChildren"), self.autoSelectChildren)

	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
end

function ListItemElement:loadProfile(profile, applyProfile)
	ListItemElement:superClass().loadProfile(self, profile, applyProfile)

	self.allowSelected = profile:getBool("allowSelected", self.allowSelected)
	self.allowFocus = profile:getBool("allowFocus", self.allowFocus)
	self.autoSelectChildren = profile:getBool("autoSelectChildren", self.autoSelectChildren)
end

function ListItemElement:copyAttributes(src)
	ListItemElement:superClass().copyAttributes(self, src)

	self.allowSelected = src.allowSelected
	self.allowFocus = src.allowFocus
	self.autoSelectChildren = src.autoSelectChildren
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	self.onClickCallback = src.onClickCallback
end

function ListItemElement:getIsSelected()
	if self:getOverlayState() == GuiOverlay.STATE_SELECTED then
		return true
	else
		return ListItemElement:superClass().getIsSelected(self)
	end
end

function ListItemElement:onClose()
	ListItemElement:superClass().onClose(self)
	self:reset()
end

function ListItemElement:setSelected(selected)
	if selected then
		if self.allowSelected then
			self:setOverlayState(GuiOverlay.STATE_SELECTED)
		else
			self:setOverlayState(GuiOverlay.STATE_FOCUSED)
		end
	elseif self:getOverlayState() ~= GuiOverlay.STATE_HIGHLIGHTED then
		self:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function ListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsVisible() then
		if ListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
			if not isDown and not isUp then
				if self:getOverlayState() ~= GuiOverlay.STATE_SELECTED and self.handleFocus then
					FocusManager:setHighlight(self)
				end

				if not self.mouseEntered then
					self.mouseEntered = true

					if self.handleFocus then
						self:raiseCallback("onFocusCallback", self)
					end
				end
			end

			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				self.mouseDown = true
			end

			if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
				self.mouseDown = false

				self:raiseCallback("onClickCallback", self)
			end
		else
			if self.mouseEntered then
				self.mouseEntered = false

				if self.handleFocus then
					self:raiseCallback("onLeaveCallback", self)
				end
			end

			self.mouseDown = false

			if not self.focusActive and self.handleFocus and self:getOverlayState() ~= GuiOverlay.STATE_SELECTED then
				FocusManager:unsetHighlight(self)
			end
		end
	end

	return eventUsed
end

function ListItemElement:getFocusTarget(incomingDirection, moveDirection)
	if self.autoSelectChildren then
		return ListItemElement:superClass().getFocusTarget(self, incomingDirection, moveDirection)
	else
		return self
	end
end
