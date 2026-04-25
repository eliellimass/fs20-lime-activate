LandscapingScreen = {}
local LandscapingScreen_mt = Class(LandscapingScreen, ScreenElement)
LandscapingScreen.CONTROLS = {
	BRUSH_SIZE_VALUE = "brushSizeValue",
	BRUSH_STRENGTH_VALUE = "brushStrengthValue",
	TEXTURE_LABEL = "paintTextureLabel",
	TEXTURE_IMAGE = "paintTextureImage",
	TEXTURE_ITEM = "paintMaterialItem",
	CROSSHAIR_ELEMENT = "crossHairElement",
	BRUSH_STRENGTH_ITEM = "brushStrengthItem",
	SCULPT_FRAME = "sculptModeIconFrame",
	PAINT_FRAME = "paintModeIconFrame",
	MESSAGE_TEXT = "messageText",
	SCULPT_ICON = "sculptModeIcon",
	SETTINGS_BOX = "settingsBox",
	SCULPT_ITEM = "sculptModeListItem",
	PAINT_ITEM = "paintModeListItem",
	BRUSH_SIZE_ITEM = "brushSizeItem",
	MODE_LIST = "modeList",
	PAINT_ICON = "paintModeIcon"
}
LandscapingScreen.ERROR_MESSAGE_FADE_DURATION = 500
LandscapingScreen.ERROR_MESSAGE_MIN_DURATION = 2000
LandscapingScreen.ERROR_MESSAGE_HIDE_MIN_DURATION = 200

function LandscapingScreen:new(target, custom_mt, messageCenter, l10n, inputManager, landscapingController)
	local self = ScreenElement:new(target, custom_mt or LandscapingScreen_mt)

	self:registerControls(LandscapingScreen.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.controller = landscapingController
	self.showErrorMessageTime = 0
	self.errorMessageAnimation = TweenSequence.NO_SEQUENCE

	local function exitCallback()
		return self:onClickBack()
	end

	local function showErrorMessageCallback(text)
		return self:showErrorMessage(text)
	end

	self.terrainLayerTextureOverlay = nil

	self.controller:setExitCallback(exitCallback)
	self.controller:setShowErrorMessageCallback(showErrorMessageCallback)

	local data = {}

	for _, v in pairs(LandscapingScreenController.SETTINGS) do
		data[v] = 0
	end

	self.settingsDataSource = GuiDataSource:new()

	self.settingsDataSource:setData(data)
	self.settingsDataSource:addChangeListener(self, self.onSettingsChanged)
	self.controller:setSettingsDataSource(self.settingsDataSource)

	self.returnScreenClass = ShopMenu

	return self
end

function LandscapingScreen:delete()
	LandscapingScreen:superClass().delete(self)
	self.controller:delete()

	if self.terrainLayerTextureOverlay ~= nil then
		delete(self.terrainLayerTextureOverlay)

		self.terrainLayerTextureOverlay = nil
	end
end

function LandscapingScreen:reset()
	LandscapingScreen:superClass().reset(self)
	self.controller:reset()
end

function LandscapingScreen:onGuiSetupFinished()
	LandscapingScreen:superClass().onGuiSetupFinished(self)
	self.modeList:updateItemPositions()

	self.errorMessageAnimation = self:createErrorMessageAnimation()
end

function LandscapingScreen:onOpen()
	LandscapingScreen:superClass().onOpen(self)
	self.controller:activate()

	self.terrainLayerTextureOverlay = self.controller:createTerrainLayerOverlay()

	if self.controller.activatePostOverlayCreation ~= nil then
		self.controller:activatePostOverlayCreation()
	end
end

function LandscapingScreen:onClose()
	self.messageCenter:unsubscribeAll(self.controller)

	if self.terrainLayerTextureOverlay ~= nil then
		delete(self.terrainLayerTextureOverlay)

		self.terrainLayerTextureOverlay = nil
	end

	self.controller:deactivate()
	LandscapingScreen:superClass().onClose(self)
end

function LandscapingScreen:update(dt)
	LandscapingScreen:superClass().update(self, dt)
	self.controller:update(dt)

	self.showErrorMessageTime = self.showErrorMessageTime - dt

	self.errorMessageAnimation:update(dt)
end

function LandscapingScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.controller:loadMapData(mapXMLFile, missionInfo, baseDirectory)
end

function LandscapingScreen:unloadMapData()
	self.controller:unloadMapData()
end

function LandscapingScreen:mouseEvent(...)
	local eventUsed = LandscapingScreen:superClass().mouseEvent(self, ...)
	eventUsed = eventUsed or self.controller:mouseEvent(...)

	return eventUsed
end

function LandscapingScreen:draw()
	LandscapingScreen:superClass().draw(self)

	if self.paintTextureImage:getIsVisible() then
		local posX, posY = unpack(self.paintTextureImage.absPosition)
		local width, height = unpack(self.paintTextureImage.size)

		renderOverlay(self.terrainLayerTextureOverlay, posX, posY, width, height)
	end
end

function LandscapingScreen:onSettingsChanged()
	self:displayLandscapingMode(self.settingsDataSource:getItem(LandscapingScreenController.SETTINGS.MODE))
	self:displayBrushSize(self.settingsDataSource:getItem(LandscapingScreenController.SETTINGS.BRUSH_SIZE))
	self:displayBrushStrength(self.settingsDataSource:getItem(LandscapingScreenController.SETTINGS.BRUSH_STRENGTH))
	self:displayPaintMaterial(self.settingsDataSource:getItem(LandscapingScreenController.SETTINGS.TERRAIN_MATERIAL))
end

function LandscapingScreen:displayLandscapingMode(mode)
	if mode == LandscapingScreenController.MODE.SCULPTING then
		self.sculptModeIconFrame:applyProfile(LandscapingScreen.PROFILE.MODE_SELECTED)
		self.paintModeIconFrame:applyProfile(LandscapingScreen.PROFILE.MODE_UNSELECTED)
		self.modeList:setSelectedIndex(1)
	elseif mode == LandscapingScreenController.MODE.PAINTING then
		self.sculptModeIconFrame:applyProfile(LandscapingScreen.PROFILE.MODE_UNSELECTED)
		self.paintModeIconFrame:applyProfile(LandscapingScreen.PROFILE.MODE_SELECTED)
		self.modeList:setSelectedIndex(2)
	end

	self.modeList:updateItemPositions()
	self.paintMaterialItem:setVisible(mode == LandscapingScreenController.MODE.PAINTING)
	self.brushStrengthItem:setVisible(mode == LandscapingScreenController.MODE.SCULPTING)

	local flowHeight = self.settingsBox:invalidateLayout()
	local boxHeight = flowHeight + self.settingsBox.flowMargin[2] + self.settingsBox.flowMargin[4]

	self.settingsBox:setSize(self.settingsBox.size[1], boxHeight)
	self.settingsBox:invalidateLayout()
end

function LandscapingScreen:displayBrushSize(brushRadius)
	local diameter = brushRadius * 2

	self.brushSizeValue:setText(tostring(diameter))
end

function LandscapingScreen:displayBrushStrength(brushStrength)
	local text = string.format("%1.1f", brushStrength)

	self.brushStrengthValue:setText(text)
end

function LandscapingScreen:displayPaintMaterial(terrainLayer)
	if self.terrainLayerTextureOverlay ~= nil then
		setOverlayLayer(self.terrainLayerTextureOverlay, terrainLayer)
	end
end

function LandscapingScreen:onTextLoopDone()
	if self.showErrorMessageTime <= 0 then
		self.messageText:setVisible(false)
		self.errorMessageAnimation:reset()
	end
end

function LandscapingScreen:createErrorMessageAnimation()
	local colorLoop = TweenSequence.new()

	colorLoop:setTarget(self.messageText)
	colorLoop:setLooping(true)

	local firstColorFade = MultiValueTween:new(self.messageText.setTextColor, LandscapingScreen.COLOR.ERROR_MESSAGE_1, LandscapingScreen.COLOR.ERROR_MESSAGE_2, LandscapingScreen.ERROR_MESSAGE_FADE_DURATION)
	local secondColorFade = MultiValueTween:new(self.messageText.setTextColor, LandscapingScreen.COLOR.ERROR_MESSAGE_2, LandscapingScreen.COLOR.ERROR_MESSAGE_1, LandscapingScreen.ERROR_MESSAGE_FADE_DURATION)

	colorLoop:addTween(firstColorFade)
	colorLoop:addTween(secondColorFade)

	local function loopCallback()
		return self:onTextLoopDone()
	end

	colorLoop:addCallback(loopCallback)

	return colorLoop
end

function LandscapingScreen:showErrorMessage(text)
	if text == "" then
		self.messageText:setVisible(false)
		self.errorMessageAnimation:stop()
	else
		if self.messageText.text ~= text then
			self.messageText:setText(text)
		end

		self.messageText:setVisible(true)

		self.showErrorMessageTime = LandscapingScreen.ERROR_MESSAGE_MIN_DURATION

		self.errorMessageAnimation:start()
	end
end

LandscapingScreen.PROFILE = {
	MODE_UNSELECTED = "landscapingModeFrame",
	MODE_SELECTED = "landscapingModeSelectedFrame"
}
LandscapingScreen.COLOR = {
	ERROR_MESSAGE_1 = {
		1,
		1,
		0.25,
		1
	},
	ERROR_MESSAGE_2 = {
		0.75,
		0,
		0,
		1
	}
}
