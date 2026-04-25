ShopLandscapingFrame = {}
local ShopLandscapingFrame_mt = Class(ShopLandscapingFrame, TabbedMenuFrameElement)
ShopLandscapingFrame.CONTROLS = {
	BG_FRAME = "backgroundFrame",
	START_BUTTON = "buttonStart"
}

local function NO_CALLBACK()
end

function ShopLandscapingFrame:new(subclass_mt)
	local subclass_mt = subclass_mt or ShopLandscapingFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(ShopLandscapingFrame.CONTROLS)

	self.startLandscapingCallback = NO_CALLBACK
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	return self
end

function ShopLandscapingFrame:onFrameOpen()
	ShopLandscapingFrame:superClass().onFrameOpen(self)
	FocusManager:setFocus(self.buttonStart)
end

function ShopLandscapingFrame:onClickOk()
	self:onClickStart()

	return false
end

function ShopLandscapingFrame:initialize(startLandscapingCallback)
	self.startLandscapingCallback = startLandscapingCallback or NO_CALLBACK
end

function ShopLandscapingFrame:onClickStart()
	self.startLandscapingCallback()
end

function ShopLandscapingFrame:getMainElementSize()
	return self.backgroundFrame.size
end

function ShopLandscapingFrame:getMainElementPosition()
	return self.backgroundFrame.absPosition
end
