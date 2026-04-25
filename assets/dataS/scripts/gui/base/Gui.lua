Gui = {}
local Gui_mt = Class(Gui)
Gui.CONFIGURATION_CLASS_MAPPING = {}
Gui.ELEMENT_PROCESSING_FUNCTIONS = {}
Gui.NAV_AXES = {
	InputAction.MENU_AXIS_LEFT_RIGHT,
	InputAction.MENU_AXIS_UP_DOWN
}
Gui.NAV_ACTIONS = {
	InputAction.MENU_ACCEPT,
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_BACK,
	InputAction.MENU,
	InputAction.TOGGLE_STORE,
	InputAction.TOGGLE_MAP,
	InputAction.MENU_PAGE_PREV,
	InputAction.MENU_PAGE_NEXT,
	InputAction.MENU_EXTRA_1,
	InputAction.MENU_EXTRA_2
}
Gui.GUI_PROFILE_BASE = "baseReference"
Gui.INPUT_CONTEXT_MENU = "MENU"
Gui.INPUT_CONTEXT_DIALOG = "DIALOG"

function Gui:new(messageCenter, languageSuffix, inputManager, guiSoundPlayer)
	local self = setmetatable({}, Gui_mt)
	self.messageCenter = messageCenter
	self.languageSuffix = languageSuffix
	self.inputManager = inputManager
	self.soundPlayer = guiSoundPlayer

	FocusManager:setSoundPlayer(guiSoundPlayer)

	self.screens = {}
	self.screenControllers = {}
	self.dialogs = {}
	self.profiles = {}
	self.traits = {}
	self.focusElements = {}
	self.guis = {}
	self.nameScreenTypes = {}
	self.currentGuiName = ""
	self.frames = {}
	self.isInputListening = false
	self.actionEventIds = {}
	self.frameInputTarget = nil
	self.frameInputHandled = false
	self.networkEventSubscribers = {}
	self.changeScreenClosure = self:makeChangeScreenClosure()
	self.toggleCustomInputContextClosure = self:makeToggleCustomInputContextClosure()
	self.playSampleClosure = self:makePlaySampleClosure()

	return self
end

function Gui:loadPresets(xmlFile, rootKey)
	local presets = {}
	local i = 0

	while true do
		local key = string.format("%s.Preset(%d)", rootKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local value = getXMLString(xmlFile, key .. "#value")

		if name ~= nil and value ~= nil then
			if StringUtil.startsWith(value, "$preset_") then
				local preset = string.gsub(value, "$preset_", "")

				if presets[preset] ~= nil then
					value = presets[preset]
				else
					g_logManager:devWarning("Preset '%s' is not defined in Preset!", preset)
				end
			end

			presets[name] = value
		end

		i = i + 1
	end

	return presets
end

function Gui:loadTraits(xmlFile, rootKey, presets)
	local i = 0

	while true do
		local trait = GuiProfile:new(self.profiles, self.traits)

		if not trait:loadFromXML(xmlFile, rootKey .. ".Trait(" .. i .. ")", presets, true) then
			break
		end

		self.traits[trait.name] = trait
		i = i + 1
	end
end

function Gui:loadProfileSet(xmlFile, rootKey, presets, categoryName)
	local i = 0

	while true do
		local profile = GuiProfile:new(self.profiles, self.traits)

		if not profile:loadFromXML(xmlFile, rootKey .. ".Profile(" .. i .. ")", presets, false) then
			break
		end

		profile.category = categoryName
		self.profiles[profile.name] = profile
		local j = 0

		while true do
			local k = rootKey .. ".Profile(" .. i .. ").Variant(" .. j .. ")"

			if not hasXMLProperty(xmlFile, k) then
				break
			end

			local variantName = getXMLString(xmlFile, k .. "#name")

			if variantName ~= nil then
				local variantProfile = GuiProfile:new(self.profiles, self.traits)

				if not variantProfile:loadFromXML(xmlFile, k, presets, false, true) then
					break
				end

				if variantProfile.parent == nil then
					variantProfile.parent = profile.name
				end

				variantProfile.category = categoryName
				variantProfile.name = variantName .. "_" .. profile.name
				self.profiles[variantProfile.name] = variantProfile
			end

			j = j + 1
		end

		i = i + 1
	end
end

function Gui:loadProfiles(xmlFilename)
	local xmlFile = loadXMLFile("Temp", xmlFilename)

	if xmlFile ~= nil and xmlFile ~= 0 then
		local presets = self:loadPresets(xmlFile, "GuiProfiles.Presets")

		self:loadTraits(xmlFile, "GuiProfiles.Traits", presets)
		self:loadProfileSet(xmlFile, "GuiProfiles", presets)

		local i = 0

		while true do
			local key = string.format("GuiProfiles.Category(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local categoryName = getXMLString(xmlFile, key .. "#name")

			self:loadProfileSet(xmlFile, key, presets, categoryName)

			i = i + 1
		end

		delete(xmlFile)
	else
		g_logManager:error("Could not open guiProfile-config '%s'!", xmlFilename)
	end
end

function Gui:loadGui(xmlFilename, name, controller, isFrame)
	local xmlFile = loadXMLFile("Temp", xmlFilename)
	local gui = nil

	if xmlFile ~= nil and xmlFile ~= 0 then
		FocusManager:setGui(name)

		gui = GuiElement:new(controller)
		gui.name = name
		gui.xmlFilename = xmlFilename
		controller.name = name

		gui:loadFromXML(xmlFile, "GUI")

		if isFrame then
			controller.name = gui.name
		end

		self:loadGuiRec(xmlFile, "GUI", gui, controller)

		if not isFrame then
			gui:applyScreenAlignment()
			gui:updateAbsolutePosition()
		end

		controller:addElement(gui)
		controller:exposeControlsAsFields(name)
		controller:onGuiSetupFinished()
		gui:raiseCallback("onCreateCallback", gui, gui.onCreateArgs)

		if isFrame then
			self:addFrame(controller, gui)
		else
			self.guis[name] = gui
			self.nameScreenTypes[name] = controller:class()

			self:addScreen(controller:class(), controller, gui)
		end

		delete(xmlFile)
	else
		g_logManager:error("Could not open gui-config '%s'!", xmlFilename)
	end

	return gui
end

function Gui:loadGuiRec(xmlFile, xmlNodePath, parentGuiElement, target)
	local i = 0

	while true do
		local currentXmlPath = xmlNodePath .. ".GuiElement(" .. i .. ")"
		local typeName = getXMLString(xmlFile, currentXmlPath .. "#type")

		if typeName == nil then
			break
		end

		local newGuiElement = nil
		local elementClass = Gui.CONFIGURATION_CLASS_MAPPING[typeName]

		if elementClass then
			newGuiElement = elementClass:new(target)
		else
			newGuiElement = GuiElement:new(target)
		end

		newGuiElement.typeName = typeName

		newGuiElement:loadFromXML(xmlFile, currentXmlPath)
		parentGuiElement:addElement(newGuiElement)

		local processingFunction = Gui.ELEMENT_PROCESSING_FUNCTIONS[typeName]

		if processingFunction then
			newGuiElement = processingFunction(self, newGuiElement)
		end

		self:loadGuiRec(xmlFile, currentXmlPath, newGuiElement, target)
		newGuiElement:raiseCallback("onCreateCallback", newGuiElement, newGuiElement.onCreateArgs)

		i = i + 1
	end
end

function Gui:resolveFrameReference(frameRefElement)
	local refName = frameRefElement.referencedFrameName or ""
	local frame = self.frames[refName]

	if frame ~= nil then
		local frameName = frameRefElement.name or refName
		local frameController = frame.parent

		FocusManager:setGui(frameName)

		local frameParent = frameRefElement.parent
		local controllerClone = frameController:clone(frameParent, true, true)
		controllerClone.name = frameName
		controllerClone.positionOrigin = frameParent.positionOrigin
		controllerClone.screenAlign = frameParent.screenAlign

		controllerClone:setSize(unpack(frameParent.size))

		local cloneRoot = controllerClone:getRootElement()
		cloneRoot.positionOrigin = frameParent.positionOrigin
		cloneRoot.screenAlign = frameParent.screenAlign

		cloneRoot:setSize(unpack(frameParent.size))

		local targetingChildren = controllerClone:getDescendants(function (element)
			return element.target == frameController
		end)

		for _, element in pairs(targetingChildren) do
			element.target = controllerClone
			element.targetName = controllerClone.name

			element:raiseCallback("onCreateCallback", element, element.onCreateArgs)
		end

		local frameId = frameRefElement.id
		controllerClone.id = frameId

		if frameRefElement.target then
			frameRefElement.target[frameId] = controllerClone
		end

		FocusManager:loadElementFromCustomValues(controllerClone, nil, , false, false)
		frameRefElement:unlinkElement()
		frameRefElement:delete()

		return controllerClone
	else
		return frameRefElement
	end
end

function Gui:getProfile(profileName)
	if profileName ~= nil then
		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
			local terrPrefix = ""
			local territory = getGameTerritory()

			if territory ~= nil and territory ~= "" then
				terrPrefix = territory .. "_"
			end

			local ps4ProfileName = g_platformPrefix .. terrPrefix .. profileName

			if self.profiles[ps4ProfileName] then
				profileName = ps4ProfileName
			end
		else
			local platformProfileName = g_platformPrefix .. profileName

			if self.profiles[platformProfileName] then
				profileName = platformProfileName
			elseif GS_IS_CONSOLE_VERSION then
				local consoleProfileName = "consoles_" .. profileName

				if self.profiles[consoleProfileName] then
					profileName = consoleProfileName
				end
			end

			if GS_IS_MOBILE_VERSION then
				local consoleProfileName = "mobile_" .. profileName

				if self.profiles[consoleProfileName] then
					profileName = consoleProfileName
				end
			end
		end
	end

	if not profileName or not self.profiles[profileName] then
		if profileName and profileName ~= "" then
			g_logManager:warning("Could not retrieve GUI profile '%s'. Using base reference profile instead.", tostring(profileName))
		end

		profileName = Gui.GUI_PROFILE_BASE
	end

	return self.profiles[profileName]
end

function Gui:getIsGuiVisible()
	return self.currentGui ~= nil or self:getIsDialogVisible()
end

function Gui:getIsDialogVisible()
	return #self.dialogs > 0
end

function Gui:getIsOverlayGuiVisible()
	return self.currentGui == self.screens[PlacementScreen] or self.currentGui == self.screens[LandscapingScreen]
end

function Gui:getActionEventId(actionName)
	return self.actionEventIds[actionName]
end

function Gui:showGui(guiName)
	if guiName == nil then
		guiName = ""
	end

	return self:changeScreen(self.guis[self.currentGui], self.nameScreenTypes[guiName])
end

function Gui:showDialog(guiName, closeAllOthers)
	local gui = self.guis[guiName]

	if gui ~= nil then
		if closeAllOthers then
			local list = self.dialogs

			for _, v in ipairs(list) do
				if v ~= gui then
					self:closeDialog(v)
				end
			end
		end

		local oldListener = self.currentListener

		if self.currentListener == gui then
			return gui
		end

		if self.currentListener ~= nil then
			self.focusElements[self.currentListener] = FocusManager:getFocusedElement()
		end

		if not self:getIsGuiVisible() then
			self:enterMenuContext()
		end

		self:enterMenuContext(Gui.INPUT_CONTEXT_DIALOG .. "_" .. tostring(guiName))
		FocusManager:setGui(guiName)
		table.insert(self.dialogs, gui)
		gui:onOpen()

		self.currentListener = gui

		g_messageCenter:publish(MessageType.GUI_DIALOG_OPENED, guiName, oldListener ~= nil and oldListener ~= gui)
	end

	return gui
end

function Gui:closeDialogByName(guiName)
	local gui = self.guis[guiName]

	if gui ~= nil then
		self:closeDialog(gui)
	end
end

function Gui:closeDialog(gui)
	for k, v in ipairs(self.dialogs) do
		if v == gui then
			v:onClose()
			table.remove(self.dialogs, k)

			if self.currentListener == gui then
				if #self.dialogs > 0 then
					self.currentListener = self.dialogs[#self.dialogs]
				elseif self.currentGui == gui then
					self.currentListener = nil
					self.currentGui = nil
				else
					self.currentListener = self.currentGui
				end

				if self.currentListener ~= nil then
					FocusManager:setGui(self.currentListener.name)

					if self.focusElements[self.currentListener] ~= nil then
						FocusManager:setFocus(self.focusElements[self.currentListener])

						self.focusElements[self.currentListener] = nil
					end
				end
			end

			self.inputManager:revertContext(false)

			break
		end
	end

	if not self:getIsGuiVisible() then
		self:changeScreen(nil)
	end
end

function Gui:closeAllDialogs()
	for _, v in ipairs(self.dialogs) do
		self:closeDialog(v)
	end
end

function Gui:registerMenuInput()
	for _, actionName in ipairs(Gui.NAV_ACTIONS) do
		local _, eventId = self.inputManager:registerActionEvent(actionName, self, self.onMenuInput, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)

		self.actionEventIds[actionName] = eventId
	end

	for _, actionName in pairs(Gui.NAV_AXES) do
		local _, eventId = self.inputManager:registerActionEvent(actionName, self, self.onMenuInput, false, true, true, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)

		_, eventId = self.inputManager:registerActionEvent(actionName, self, self.onReleaseMovement, true, false, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	self.isInputListening = true
end

function Gui:mouseEvent(posX, posY, isDown, isUp, button)
	local eventUsed = false

	if self.currentListener ~= nil then
		eventUsed = self.currentListener:mouseEvent(posX, posY, isDown, isUp, button)
	end

	if not eventUsed and self.currentListener ~= nil and self.currentListener.target ~= nil and self.currentListener.target.mouseEvent ~= nil then
		self.currentListener.target:mouseEvent(posX, posY, isDown, isUp, button)
	end
end

function Gui:keyEvent(unicode, sym, modifier, isDown)
	local eventUsed = false

	if self.currentListener ~= nil then
		eventUsed = self.currentListener:keyEvent(unicode, sym, modifier, isDown)
	end

	if self.currentListener ~= nil and self.currentListener.target ~= nil and not eventUsed and self.currentListener.target.keyEvent ~= nil then
		self.currentListener.target:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	end
end

function Gui:update(dt)
	for _, v in pairs(self.dialogs) do
		v:update(dt)

		if v.target ~= nil then
			v.target:update(dt)
		end
	end

	local currentGui = self.currentGui

	if currentGui ~= nil then
		if currentGui.target ~= nil and currentGui.target.preUpdate ~= nil then
			currentGui.target:preUpdate(dt)
		end

		if currentGui == self.currentGui then
			currentGui:update(dt)

			if currentGui == self.currentGui and currentGui.target ~= nil and currentGui.target.update ~= nil then
				currentGui.target:update(dt)
			end
		end
	end

	self.frameInputTarget = nil
	self.frameInputHandled = false
end

function Gui:draw()
	if self.currentGui ~= nil then
		self.currentGui:draw()
	end

	for _, v in pairs(self.dialogs) do
		v:draw()
	end
end

function Gui:notifyControls(action, value)
	local eventUsed = false

	if self.frameInputTarget == nil then
		self.frameInputTarget = self.currentListener
	end

	local locked = FocusManager:isFocusInputLocked(action, value)

	if not locked then
		if not eventUsed and self.frameInputTarget ~= nil then
			eventUsed = self.frameInputTarget:inputEvent(action, value)
		end

		if not eventUsed and self.frameInputTarget ~= nil and self.frameInputTarget.target ~= nil then
			eventUsed = self.frameInputTarget.target:inputEvent(action, value)
		end

		local focusedElement = FocusManager:getFocusedElement()

		if not eventUsed and focusedElement ~= nil and focusedElement:getIsActive() then
			eventUsed = focusedElement:inputEvent(action, value)
		end

		eventUsed = eventUsed or FocusManager:inputEvent(action, value, eventUsed)
	end

	self.frameInputHandled = eventUsed
end

function Gui:onMenuInput(actionName, inputValue)
	if not self.frameInputHandled and self.isInputListening then
		self:notifyControls(actionName, inputValue)
	end
end

function Gui:onReleaseMovement(actionName)
	FocusManager:releaseMovementFocusInput(actionName)
end

function Gui:hasElementInputFocus(element)
	return self.currentListener ~= nil and self.currentListener.target == element
end

function Gui:getScreenInstanceByClass(screenClass)
	return self.screenControllers[screenClass]
end

function Gui:changeScreen(source, screenClass, returnScreenClass)
	self:closeAllDialogs()

	local isMenuOpening = not self:getIsGuiVisible()
	local screenElement = self.screens[screenClass]

	if source ~= nil then
		source:onClose()
	end

	if source == nil and self.currentGui ~= nil then
		self.currentGui:onClose()
	end

	local screenName = screenElement and screenElement.name or ""
	self.currentGui = screenElement
	self.currentGuiName = screenName
	self.currentListener = screenElement

	if screenElement ~= nil and isMenuOpening then
		self.messageCenter:publish(MessageType.GUI_BEFORE_OPEN)
		self:enterMenuContext()
	end

	FocusManager:setGui(screenName)

	local screenController = self.screenControllers[screenClass]

	if screenElement ~= nil and screenController ~= nil then
		screenController:setReturnScreenClass(returnScreenClass or screenController.returnScreenClass)
		screenElement:onOpen()

		if isMenuOpening then
			self.messageCenter:publish(MessageType.GUI_AFTER_OPEN)
		end
	end

	if not self:getIsGuiVisible() then
		self.messageCenter:publish(MessageType.GUI_BEFORE_CLOSE)
		self:leaveMenuContext()
		self.messageCenter:publish(MessageType.GUI_AFTER_CLOSE)
	end

	return screenElement
end

function Gui:makeChangeScreenClosure()
	return function (source, screenClass, returnScreenClass)
		self:changeScreen(source, screenClass, returnScreenClass)
	end
end

function Gui:toggleCustomInputContext(isActive, contextName)
	if isActive then
		self:enterMenuContext(contextName)
	else
		self:leaveMenuContext()
	end
end

function Gui:makeToggleCustomInputContextClosure()
	return function (isActive, contextName)
		self:toggleCustomInputContext(isActive, contextName)
	end
end

function Gui:makePlaySampleClosure()
	return function (sampleName)
		self.soundPlayer:playSample(sampleName)
	end
end

function Gui:assignPlaySampleCallback(guiElement)
	if guiElement:hasIncluded(PlaySampleMixin) then
		guiElement:setPlaySampleCallback(self.playSampleClosure)
	end

	return guiElement
end

function Gui:enterMenuContext(contextName)
	self.inputManager:setContext(contextName or Gui.INPUT_CONTEXT_MENU, true, false)
	self:registerMenuInput()

	self.isInputListening = true
end

function Gui:leaveMenuContext()
	if self.isInputListening then
		self.inputManager:revertContext(false)

		self.isInputListening = self:getIsGuiVisible()
	end
end

function Gui:addFrame(frameController, frameRootElement)
	self.frames[frameController.name] = frameRootElement

	frameController:setChangeScreenCallback(self.changeScreenClosure)
	frameController:setInputContextCallback(self.toggleCustomInputContextClosure)
	frameController:setPlaySampleCallback(self.playSampleClosure)
end

function Gui:addScreen(screenClass, screenInstance, screenRootElement)
	self.screens[screenClass] = screenRootElement
	self.screenControllers[screenClass] = screenInstance

	screenInstance:setChangeScreenCallback(self.changeScreenClosure)
	screenInstance:setInputContextCallback(self.toggleCustomInputContextClosure)
	screenInstance:setPlaySampleCallback(self.playSampleClosure)
end

function Gui:setCurrentMission(currentMission)
	self.screenControllers[ShopConfigScreen]:setCurrentMission(currentMission)
end

function Gui:setEconomyManager(economyManager)
	self.screenControllers[ShopConfigScreen]:setEconomyManager(economyManager)
end

function Gui:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	if not GS_IS_MOBILE_VERSION then
		self.screenControllers[ShopConfigScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
		self.screenControllers[LandscapingScreen]:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	end
end

function Gui:unloadMapData()
	self.screenControllers[ShopConfigScreen]:unloadMapData()
	self.screenControllers[LandscapingScreen]:unloadMapData()
end

function Gui:setClient(client)
end

function Gui:setIsMultiplayer(isMultiplayer)
	local notifyScreenClasses = {
		CareerScreen,
		ModSelectionScreen,
		MapSelectionScreen,
		DifficultyScreen,
		CharacterCreationScreen
	}

	for _, class in pairs(notifyScreenClasses) do
		local controller = self.screenControllers[class]

		if controller ~= nil then
			controller:setIsMultiplayer(isMultiplayer)
		end
	end
end

function Gui:showColorPickerDialog(args)
	local dialog = self:showDialog("ColorPickerDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setColors(args.colors, args.defaultColor)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showTextInputDialog(args)
	local dialog = self.guis.TextInputDialog

	if dialog ~= nil and args ~= nil then
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.defaultText, args.dialogPrompt, args.imePrompt, args.maxCharacters, args.args, false, args.disableFilter)
		dialog.target:setButtonTexts(args.confirmText, args.backText, args.activateInputText)
		self:showDialog("TextInputDialog")
	end
end

function Gui:showPasswordDialog(args)
	local dialog = self.guis.PasswordDialog

	if dialog ~= nil and args ~= nil then
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.defaultPassword, nil, , , args.args, true)
		dialog.target:setButtonTexts(args.startText, args.backText)
		self:showDialog("PasswordDialog")
	end
end

function Gui:showYesNoDialog(args)
	local dialog = self:showDialog("YesNoDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setText(args.text)
		dialog.target:setTitle(args.title)
		dialog.target:setDialogType(Utils.getNoNil(args.dialogType, DialogElement.TYPE_QUESTION))
		dialog.target:setCallback(args.callback, args.target, args.args)
		dialog.target:setButtonTexts(args.yesText, args.noText)
	end
end

function Gui:showInfoDialog(args)
	local dialog = self:showDialog("InfoDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setDialogType(Utils.getNoNil(args.dialogType, DialogElement.TYPE_WARNING))
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.args)
		dialog.target:setButtonTexts(args.okText)
		dialog.target:setButtonAction(args.buttonAction)
	end
end

function Gui:showChinaAgeRatingDialog(args)
	local dialog = self:showDialog("ChinaAgeRatingDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.args)
		dialog.target:setButtonTexts(args.okText)
		dialog.target:setButtonAction(args.buttonAction)
	end
end

function Gui:showControlsIntroductionDialog(args)
	local dialog = self:showDialog("ControlsIntroductionDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.args)
		dialog.target:setButtonTexts(args.okText)
		dialog.target:setButtonAction(args.buttonAction)
	end
end

function Gui:showMessageDialog(args)
	if args ~= nil then
		if args.visible then
			local dialog = self:showDialog("MessageDialog")

			if dialog ~= nil then
				dialog.target:setDialogType(Utils.getNoNil(args.dialogType, DialogElement.TYPE_LOADING))
				dialog.target:setIsCloseAllowed(Utils.getNoNil(args.isCloseAllowed, true))
				dialog.target:setText(args.text)
				dialog.target:setUpdateCallback(args.updateCallback, args.updateTarget, args.updateArgs)
			end
		else
			self:closeDialogByName("MessageDialog")
		end
	end
end

function Gui:showConnectionFailedDialog(args)
	local dialog = self:showDialog("ConnectionFailedDialog", true)

	if dialog ~= nil and args ~= nil then
		dialog.target:setDialogType(Utils.getNoNil(args.dialogType, DialogElement.TYPE_WARNING))
		dialog.target:setText(args.text)
		dialog.target:setCallback(args.callback, args.target, args.args)
		dialog.target:setButtonTexts(args.okText)
	end
end

function Gui:showDenyAcceptDialog(args)
	self:showGui("")

	local dialog = self:showDialog("DenyAcceptDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setCallback(args.callback, args.target)
		dialog.target:setConnection(args.connection, args.nickname)
		dialog.target:setTitle(args.nickname)
	end
end

function Gui:showSiloDialog(args)
	local dialog = self:showDialog("SiloDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setTitle(args.title)
		dialog.target:setText(args.text)
		dialog.target:setFillLevels(args.fillLevels, args.capacity, args.hasInfiniteCapacity)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showAnimalDialog(args)
	local dialog = self:showDialog("AnimalDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setTitle(args.title)
		dialog.target:setText(args.text)
		dialog.target:setHusbandries(args.husbandries)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showSellItemDialog(args)
	local dialog = self:showDialog("SellItemDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setItem(args.item, args.price, args.storeItem)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showDirectSellDialog(args)
	local dialog = self:showDialog("DirectSellDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setVehicle(args.vehicle, args.owner, args.ownWorkshop)
	end
end

function Gui:showEditFarmDialog(args)
	local dialog = self:showDialog("EditFarmDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setExistingFarm(args.farmId)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showUnBanDialog(args)
	local dialog = self:showDialog("UnBanDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setCallback(args.callback, args.target)
	end
end

function Gui:showSleepDialog(args)
	local dialog = self:showDialog("SleepDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setTitle(g_i18n:getText("ui_inGameSleep"))
		dialog.target:setText(args.text)
		dialog.target:setMaxDuration(args.maxDuration)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showTransferMoneyDialog(args)
	local dialog = self:showDialog("TransferMoneyDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setTargetFarm(args.farm)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showServerSettingsDialog(args)
	local dialog = self:showDialog("ServerSettingsDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showVoteDialog(args)
	local dialog = self:showDialog("VoteDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setValue(args.value)
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui:showGameRateDialog(args)
	local dialog = self:showDialog("GameRateDialog")

	if dialog ~= nil and args ~= nil then
		dialog.target:setCallback(args.callback, args.target, args.args)
	end
end

function Gui.initGuiLibrary(baseDir)
	source(baseDir .. "/base/GuiProfile.lua")
	source(baseDir .. "/base/GuiUtils.lua")
	source(baseDir .. "/base/GuiOverlay.lua")
	source(baseDir .. "/base/GuiDataSource.lua")
	source(baseDir .. "/base/GuiMixin.lua")
	source(baseDir .. "/base/IndexChangeSubjectMixin.lua")
	source(baseDir .. "/base/PlaySampleMixin.lua")
	source(baseDir .. "/base/Tween.lua")
	source(baseDir .. "/base/MultiValueTween.lua")
	source(baseDir .. "/base/TweenSequence.lua")
	source(baseDir .. "/elements/GuiElement.lua")
	source(baseDir .. "/elements/FrameElement.lua")
	source(baseDir .. "/elements/ScreenElement.lua")
	source(baseDir .. "/elements/DialogElement.lua")
	source(baseDir .. "/elements/BitmapElement.lua")
	source(baseDir .. "/elements/TextElement.lua")
	source(baseDir .. "/elements/ButtonElement.lua")
	source(baseDir .. "/elements/ToggleButtonElement.lua")
	source(baseDir .. "/elements/VideoElement.lua")
	source(baseDir .. "/elements/SliderElement.lua")
	source(baseDir .. "/elements/TextInputElement.lua")
	source(baseDir .. "/elements/ListElement.lua")
	source(baseDir .. "/elements/StableListElement.lua")
	source(baseDir .. "/elements/MultiTextOptionElement.lua")
	source(baseDir .. "/elements/CheckedOptionElement.lua")
	source(baseDir .. "/elements/ListItemElement.lua")
	source(baseDir .. "/elements/AnimationElement.lua")
	source(baseDir .. "/elements/TimerElement.lua")
	source(baseDir .. "/elements/BoxLayoutElement.lua")
	source(baseDir .. "/elements/FlowLayoutElement.lua")
	source(baseDir .. "/elements/PagingElement.lua")
	source(baseDir .. "/elements/TableElement.lua")
	source(baseDir .. "/elements/TableHeaderElement.lua")
	source(baseDir .. "/elements/IngameMapElement.lua")
	source(baseDir .. "/elements/IndexStateElement.lua")
	source(baseDir .. "/elements/FrameReferenceElement.lua")
	source(baseDir .. "/elements/RenderElement.lua")
	source(baseDir .. "/elements/BreadcrumbsElement.lua")
	source(baseDir .. "/elements/ThreePartBitmapElement.lua")

	local mapping = Gui.CONFIGURATION_CLASS_MAPPING
	mapping.button = ButtonElement
	mapping.toggleButton = ToggleButtonElement
	mapping.video = VideoElement
	mapping.slider = SliderElement
	mapping.text = TextElement
	mapping.textInput = TextInputElement
	mapping.bitmap = BitmapElement
	mapping.list = ListElement
	mapping.stableList = StableListElement
	mapping.multiTextOption = MultiTextOptionElement
	mapping.checkedOption = CheckedOptionElement
	mapping.listItem = ListItemElement
	mapping.animation = AnimationElement
	mapping.timer = TimerElement
	mapping.boxLayout = BoxLayoutElement
	mapping.flowLayout = FlowLayoutElement
	mapping.paging = PagingElement
	mapping.table = TableElement
	mapping.tableHeader = TableHeaderElement
	mapping.ingameMap = IngameMapElement
	mapping.indexState = IndexStateElement
	mapping.frameReference = FrameReferenceElement
	mapping.render = RenderElement
	mapping.breadcrumbs = BreadcrumbsElement
	mapping.threePartBitmap = ThreePartBitmapElement
	local procFuncs = Gui.ELEMENT_PROCESSING_FUNCTIONS
	procFuncs.frameReference = Gui.resolveFrameReference
	procFuncs.button = Gui.assignPlaySampleCallback
	procFuncs.slider = Gui.assignPlaySampleCallback
	procFuncs.multiTextOption = Gui.assignPlaySampleCallback
	procFuncs.checkedOption = Gui.assignPlaySampleCallback
end
