CharacterCreationScreen = {
	CONTROLS = {
		COLOR_BUTTON_TEMPLATE = "colorButtonTemplate",
		CHARACTER_NAME_INPUT = "characterNameInput",
		HAIR_OPTION = "hairOption",
		BACK_BUTTON = "backButton",
		CONTINUE_BUTTON = "continueButton",
		BODY_OPTION = "bodyOption",
		GLASSES_OPTION = "accessoryOption",
		HAT_OPTION = "hatOption",
		BUTTON_ROT_LEFT = "buttonLeft",
		CHANGE_NAME_BUTTON = "changeNameButton",
		CHARACTER_SETTINGS_LAYOUT = "characterSettingsLayout",
		BUTTON_ROT_RIGHT = "buttonRight",
		EDIT_BUTTON = "editButton",
		CHARACTER_SCENE = "sceneRender",
		VEST_OPTION = "jacketOption",
		COLOR_BUTTON_LAYOUT = "colorButtonLayout"
	},
	COLOR_ELEMENT_NAME = "colorImage",
	ROTATION_STEP_SIZE = 0.01
}
local CharacterCreationScreen_mt = Class(CharacterCreationScreen, ScreenElement)

function CharacterCreationScreen:new(target, custom_mt, startMissionInfo)
	local self = ScreenElement:new(target, custom_mt or CharacterCreationScreen_mt)

	self:registerControls(CharacterCreationScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.blockTime = 0
	self.isMultiplayer = false
	self.isOpen = false
	self.colorMapping = {}
	self.colorIndexButtonMapping = {}
	self.colorElements = {}
	self.colorButtons = {}
	self.selectedPlayerIndex = 1
	self.selectedBodyIndex = 1
	self.selectedPlayerColorIndex = 1

	return self
end

function CharacterCreationScreen:onCreate(element)
	if GS_IS_CONSOLE_VERSION then
		self.changeNameButton:setVisible(true)
	end

	self:loadClothing()
	self:loadPlayers()
	self:setMenuTexts()
	self:createColors()
end

function CharacterCreationScreen:createColors()
	local colors = g_playerColors
	local buttonWidth = self.colorButtonTemplate.size[1] + self.colorButtonTemplate.margin[1] + self.colorButtonTemplate.margin[3]
	local numRows = math.ceil(#colors * buttonWidth / self.colorButtonLayout.size[1])
	local buttonHeight = self.colorButtonTemplate.size[2] + self.colorButtonTemplate.margin[2] + self.colorButtonTemplate.margin[4]
	local layoutHeight = numRows * buttonHeight
	self.colorButtonLayout.numFlows = numRows

	self.colorButtonLayout:setSize(nil, layoutHeight)

	for k, mpColor in pairs(colors) do
		local elem = self.colorButtonTemplate:clone(self.colorButtonLayout)

		elem:setVisible(true)

		elem.focusId = nil

		FocusManager:loadElementFromCustomValues(elem)
		elem:updateAbsolutePosition()

		self.colorMapping[elem] = k
		self.colorIndexButtonMapping[k] = elem
		local colorElement = elem:getDescendantByName(CharacterCreationScreen.COLOR_ELEMENT_NAME)

		table.insert(self.colorElements, colorElement)
		table.insert(self.colorButtons, elem)

		local buttonColor = GuiOverlay.getOverlayColor(colorElement.overlay, nil)

		for i = 1, 4 do
			buttonColor[i] = mpColor.value[i]
		end
	end

	self.colorButtonTemplate:delete()
	self.colorButtonLayout:invalidateLayout()

	local numCols = math.floor(self.colorButtonLayout.size[1] / buttonWidth)

	self:focusLinkColorButtons(numCols)
end

function CharacterCreationScreen:focusLinkColorButtons(numCols)
	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]
		local leftButton = self.colorButtonLayout.elements[i - 1]
		local rightButton = self.colorButtonLayout.elements[i + 1]
		local topButton = self.colorButtonLayout.elements[i - numCols]
		local bottomButton = self.colorButtonLayout.elements[i + numCols]

		if leftButton ~= nil then
			FocusManager:linkElements(button, FocusManager.LEFT, leftButton)
		end

		if rightButton ~= nil then
			FocusManager:linkElements(button, FocusManager.RIGHT, rightButton)
		end

		if topButton ~= nil then
			FocusManager:linkElements(button, FocusManager.TOP, topButton)
		else
			FocusManager:linkElements(button, FocusManager.TOP, self.accessoryOption)
		end

		if bottomButton ~= nil then
			FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
		elseif GS_IS_CONSOLE_VERSION then
			FocusManager:linkElements(button, FocusManager.BOTTOM, self.bodyOption)
		else
			FocusManager:linkElements(button, FocusManager.BOTTOM, self.characterNameInput)
		end
	end

	local firstButton = self.colorButtonLayout.elements[1]

	FocusManager:linkElements(self.accessoryOption, FocusManager.BOTTOM, firstButton)
	FocusManager:linkElements(self.characterSettingsLayout, FocusManager.BOTTOM, firstButton)

	local lastButton = self.colorButtonLayout.elements[#self.colorButtonLayout.elements]

	if GS_IS_CONSOLE_VERSION then
		FocusManager:linkElements(self.bodyOption, FocusManager.TOP, lastButton)
	else
		FocusManager:linkElements(self.characterNameInput, FocusManager.TOP, lastButton)
	end
end

function CharacterCreationScreen:onOpen()
	CharacterCreationScreen:superClass().onOpen(self)

	self.isOpen = true
	local playerIndex = Utils.getNoNil(g_gameSettings:getValue("playerModelIndex"), 1)
	local name = g_gameSettings:getValue("nickname")

	if GS_IS_MOBILE_VERSION then
		name = "player"
	end

	self.characterNameInput:setText(name)

	self.characterRotation = 0
	self.selectedPlayerIndex = Utils.getNoNil(g_gameSettings:getValue("playerModelIndex"), 1)
	self.selectedBodyIndex = Utils.getNoNil(g_gameSettings:getValue("playerBodyIndex"), 1)
	self.selectedCharacterIndex = 1

	for i, body in ipairs(self.bodies) do
		if body.player == self.selectedPlayerIndex and body.body == self.selectedBodyIndex then
			self.selectedCharacterIndex = i

			break
		end
	end

	if g_leagueBuild then
		self.backButton:setVisible(false)
	end

	self.selectedPlayerColorIndex = Utils.getNoNil(g_gameSettings:getValue("playerColorIndex"), 2)

	self.bodyOption:setState(self.selectedCharacterIndex)
	self.hairOption:setState(Utils.getNoNil(g_gameSettings:getValue("playerHairIndex"), 1))
	self.jacketOption:setState(Utils.getNoNil(g_gameSettings:getValue("playerJacketIndex"), 0) + 1)
	self.hatOption:setState(Utils.getNoNil(g_gameSettings:getValue("playerHatIndex"), 0) + 1)
	self.accessoryOption:setState(Utils.getNoNil(g_gameSettings:getValue("playerAccessoryIndex"), 0) + 1)
	self:updatePossiblePlayerOptions()

	if not GS_IS_MOBILE_VERSION then
		self.sceneRender:createScene()
	end

	if GS_IS_CONSOLE_VERSION then
		self.characterNameInput:setDisabled(true)
		self.changeNameButton:setVisible(false)
	end

	g_messageCenter:publish(MessageType.GUI_CHARACTER_CREATION_SCREEN_OPEN)

	if GS_IS_MOBILE_VERSION then
		self:onClickOk()
	end
end

function CharacterCreationScreen:onClose()
	self:deleteAnimation()
	self.sceneRender:destroyScene()

	self.characterNode = nil
	self.loadedPlayer = nil
	self.hatNode = nil
	self.accessoryNode = nil
	self.isOpen = false
end

function CharacterCreationScreen:onClickOk(element)
	if self.blockTime <= self.time then
		for _, button in ipairs(self.colorButtons) do
			if FocusManager:hasFocus(button) then
				local color = self.colorMapping[button]

				if self.selectedPlayerColorIndex ~= color then
					self:onClickColorButton(button)
					self:updateOkButton()

					return false
				end
			end
		end

		if not self:verifyCharacterName() then
			return false
		end

		CharacterCreationScreen:superClass().onClickOk(self)
		g_gameSettings:setValue("nickname", self.characterNameInput.text)
		g_gameSettings:setValue("playerModelIndex", self.selectedPlayerIndex)
		g_gameSettings:setValue("playerColorIndex", self.selectedPlayerColorIndex)
		g_gameSettings:setValue("playerBodyIndex", self.selectedBodyIndex)
		g_gameSettings:setValue("playerHairIndex", self.hairOption:getState())
		g_gameSettings:setValue("playerJacketIndex", self.jacketOption:getState() - 1)
		g_gameSettings:setValue("playerHatIndex", self.hatOption:getState() - 1)
		g_gameSettings:setValue("playerAccessoryIndex", self.accessoryOption:getState() - 1)
		g_gameSettings:saveToXMLFile(g_savegameXML)

		self.startMissionInfo.playerStyle.selectedModelIndex = self.selectedPlayerIndex
		self.startMissionInfo.playerStyle.selectedColorIndex = self.selectedPlayerColorIndex
		self.startMissionInfo.playerStyle.selectedBodyIndex = self.selectedBodyIndex
		self.startMissionInfo.playerStyle.selectedHatIndex = self.hatOption:getState() - 1
		self.startMissionInfo.playerStyle.selectedAccessoryIndex = self.accessoryOption:getState() - 1
		self.startMissionInfo.playerStyle.selectedHairIndex = self.hairOption:getState()
		self.startMissionInfo.playerStyle.selectedJacketIndex = self.jacketOption:getState() - 1
		self.startMissionInfo.playerStyle.playerName = self.characterNameInput.text
		self.startMissionInfo.canStart = true

		if self.isMultiplayer and not self.startMissionInfo.createGame then
			self:changeScreen(MultiplayerScreen)
		else
			self:changeScreen(CareerScreen)
		end

		return false
	else
		return true
	end
end

function CharacterCreationScreen:onClickActivate()
	if FocusManager:hasFocus(self.characterNameInput) then
		self.characterNameInput:onFocusActivate()
		self:showChangeNameButton(false)
	end
end

function CharacterCreationScreen:setMenuTexts()
	local player = self.players[self.selectedPlayerIndex]
	local characterNames = {}

	for i, _ in ipairs(self.bodies) do
		table.insert(characterNames, string.format(g_i18n:getText("character_body_name"), i))
	end

	self.bodyOption:setTexts(characterNames)

	local function getNames(list, supportsNone)
		local result = {}

		if supportsNone then
			table.insert(result, g_i18n:getText("character_option_none"))
		end

		for _, variant in ipairs(list) do
			table.insert(result, variant.name)
		end

		return result
	end

	self.hatOption:setTexts(getNames(self.clothing.hats, true))
	self.accessoryOption:setTexts(getNames(self.clothing.accessories, true))
	self.hairOption:setTexts(getNames(player.hairStyles, false))
	self.jacketOption:setTexts(getNames(player.jackets, true))
end

function CharacterCreationScreen:onNameInputFocus(element)
	self:showChangeNameButton(true)
end

function CharacterCreationScreen:onNameInputLeave(element)
	self:showChangeNameButton(false)
end

function CharacterCreationScreen:showChangeNameButton(show)
	if not GS_IS_CONSOLE_VERSION then
		self.changeNameButton:setVisible(show)
		self.changeNameButton.parent:invalidateLayout()
	end
end

function CharacterCreationScreen:updateOkButton()
	for _, button in ipairs(self.colorButtons) do
		if FocusManager:hasFocus(button) then
			local color = self.colorMapping[button]

			if self.selectedPlayerColorIndex ~= color then
				self.continueButton:setText(g_i18n:getText("button_changeColor"))

				return
			end
		end
	end

	self.continueButton:setText(g_i18n:getText("button_continue"))
end

function CharacterCreationScreen:onFocusColor()
	self:updateOkButton()
end

function CharacterCreationScreen:onLeaveColor()
	self:updateOkButton()
end

function CharacterCreationScreen:onEnterPressedCharacterName()
	self.blockTime = self.time + 250

	self:verifyCharacterName()
	FocusManager:setFocus(self.bodyOption)
end

function CharacterCreationScreen:verifyCharacterName()
	if not GS_IS_CONSOLE_VERSION then
		local name = StringUtil.trim(self.characterNameInput.text)
		local filteredName = filterText(name, true, true)

		if name == "" or name ~= filteredName then
			if name == "" then
				self.characterNameInput:setText(g_gameSettings:getValue("nickname"))
			else
				self.characterNameInput:setText(filteredName)
				print("Warning: Player name not allowed. Profanity text filter. Player name adjusted")
			end

			return false
		end
	end

	return true
end

function CharacterCreationScreen:onEscPressedCharacterName()
	self.blockTime = self.time + 250

	if not GS_IS_CONSOLE_VERSION then
		FocusManager:setFocus(self.editButton)
	else
		FocusManager:setFocus(self.colorIndexButtonMapping[self.selectedPlayerColorIndex])
	end
end

function CharacterCreationScreen:update(dt)
	CharacterCreationScreen:superClass().update(self, dt)

	if self.createIdleAnim and g_animCache:isLoaded(AnimationCache.CHARACTER) then
		self:createIdleAnimation(self.players[self.selectedPlayerIndex], self.characterNode)

		self.createIdleAnim = false
	end

	if self.characterNode and self.animation ~= nil then
		updateConditionalAnimation(self.animation.player, dt)

		local rotDir = 0
		self.characterRotation = self.characterRotation + rotDir * CharacterCreationScreen.ROTATION_STEP_SIZE

		setRotation(self.characterNode, 0, self.characterRotation, 0)
		self.sceneRender:setRenderDirty()
	end

	if self.isMultiplayer and GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("MainScreen")
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end
end

function CharacterCreationScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer
end

function CharacterCreationScreen:resetSelection()
end

function CharacterCreationScreen:loadClothing()
	local xmlFile = loadXMLFile("clothing", "dataS/playerClothing.xml")

	local function loadClothing(root, item)
		local items = {}
		local i = 0

		while true do
			local key = string.format("%s.%s(%d)", root, item, i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local item = {
				node = Utils.getNoNil(getXMLString(xmlFile, key .. "#node"), "0"),
				filename = getXMLString(xmlFile, key .. "#filename"),
				name = g_i18n:convertText(getXMLString(xmlFile, key .. "#name"))
			}

			if item.filename ~= nil then
				table.insert(items, item)
			else
				print("ERROR: Item " .. tostring(i) .. " of " .. root .. " in playerClothing has no filename")
			end

			i = i + 1
		end

		return items
	end

	self.clothing = {
		hats = loadClothing("playerClothing.hats", "hat"),
		accessories = loadClothing("playerClothing.accessories", "accessory")
	}

	delete(xmlFile)
end

function CharacterCreationScreen:loadPlayers()
	self.players = {}
	self.bodies = {}

	for i, p in ipairs(g_playerModelManager.playerModels) do
		local xmlFile = loadXMLFile("TempXML", p.xmlFilename)

		if xmlFile ~= 0 then
			local player = self:loadPlayer(xmlFile)

			if player ~= nil then
				player.xmlFilename = p.xmlFilename

				table.insert(self.players, player)
			end
		end

		delete(xmlFile)
	end

	for playerId, player in ipairs(self.players) do
		for bodyId, body in ipairs(player.bodies) do
			local setting = {
				player = playerId,
				body = bodyId
			}

			table.insert(self.bodies, setting)
		end
	end
end

function CharacterCreationScreen:loadPlayer(xmlFile)
	local player = {
		filename = getXMLString(xmlFile, "player.filename"),
		shirtNode = getXMLString(xmlFile, "player.character.thirdPerson#mesh"),
		skeletonNode = getXMLString(xmlFile, "player.character.thirdPerson#skeleton"),
		hatNode = getXMLString(xmlFile, "player.character.playerStyle.hats#rootNode"),
		hatHairNode = getXMLString(xmlFile, "player.character.playerStyle.hairStyles#hatHairNode"),
		accessoryNode = getXMLString(xmlFile, "player.character.playerStyle.accessories#rootNode")
	}

	local function loadVariants(root)
		local variants = {}
		local i = 0

		while true do
			local key = string.format(root .. ".variant(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local variant = {
				node = getXMLString(xmlFile, key .. "#node"),
				name = getXMLString(xmlFile, key .. "#name"),
				headNode = getXMLString(xmlFile, key .. "#headNode"),
				armNode = getXMLString(xmlFile, key .. "#armNode")
			}

			if variant.name ~= nil then
				variant.name = g_i18n:convertText(variant.name)
			end

			table.insert(variants, variant)

			i = i + 1
		end

		return variants
	end

	player.hairStyles = loadVariants("player.character.playerStyle.hairStyles")
	player.jackets = loadVariants("player.character.playerStyle.jackets")
	player.bodies = loadVariants("player.character.playerStyle.bodies")

	return player
end

function CharacterCreationScreen:createIdleAnimation(player, playerNode)
	local skeletonThirdPerson = I3DUtil.indexToObject(playerNode, player.skeletonNode)
	self.animation = {
		player = nil,
		parameters = {}
	}
	self.animation.parameters.forwardVelocity = {
		value = 0,
		id = 1,
		type = 1
	}
	self.animation.parameters.verticalVelocity = {
		value = 0,
		id = 2,
		type = 1
	}
	self.animation.parameters.yawVelocity = {
		value = 0,
		id = 3,
		type = 1
	}
	self.animation.parameters.onGround = {
		value = true,
		id = 4,
		type = 0
	}
	self.animation.parameters.inWater = {
		value = false,
		id = 5,
		type = 0
	}
	self.animation.parameters.isCrouched = {
		value = false,
		id = 6,
		type = 0
	}
	self.animation.parameters.absForwardVelocity = {
		value = 0,
		id = 7,
		type = 1
	}
	self.animation.parameters.isCloseToGround = {
		value = false,
		id = 8,
		type = 0
	}
	self.animation.parameters.isUsingChainsawHorizontal = {
		value = false,
		id = 9,
		type = 0
	}
	self.animation.parameters.isUsingChainsawVertical = {
		value = false,
		id = 10,
		type = 0
	}

	if skeletonThirdPerson ~= nil and getNumOfChildren(skeletonThirdPerson) > 0 then
		local animNode = g_animCache:getNode(AnimationCache.CHARACTER)

		cloneAnimCharacterSet(animNode, getParent(skeletonThirdPerson))

		local animCharsetId = getAnimCharacterSet(getChildAt(skeletonThirdPerson, 0))
		self.animation.player = createConditionalAnimation()

		for key, parameter in pairs(self.animation.parameters) do
			conditionalAnimationRegisterParameter(self.animation.player, parameter.id, parameter.type, key)
		end

		initConditionalAnimation(self.animation.player, animCharsetId, player.xmlFilename, "player.conditionalAnimation")
		setConditionalAnimationSpecificParameterIds(self.animation.player, self.animation.parameters.absForwardVelocity.id, self.animation.parameters.yawVelocity.id)

		for key, parameter in pairs(self.animation.parameters) do
			if parameter.type == 0 then
				setConditionalAnimationBoolValue(self.animation.player, parameter.id, parameter.value)
			elseif parameter.type == 1 then
				setConditionalAnimationFloatValue(self.animation.player, parameter.id, parameter.value)
			end
		end
	end
end

function CharacterCreationScreen:deleteAnimation()
	if self.animation ~= nil and self.animation.player ~= nil then
		delete(self.animation.player)

		self.animation = nil
	end
end

function CharacterCreationScreen:setCharacterIndex(index)
	self.selectedCharacterIndex = index
	local body = self.bodies[index]

	if self.selectedPlayerIndex ~= body.player then
		self.selectedPlayerIndex = body.player

		self:updatePossiblePlayerOptions()
	end

	self.selectedBodyIndex = body.body

	if body.body <= #self.hairOption.texts then
		self.hairOption:setState(body.body)
	end
end

function CharacterCreationScreen:onRenderLoad(scene, overlay)
	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:updateCharacterWithSettings()
	self:updateCharacter(self.selectedPlayerIndex, self.selectedBodyIndex, self.hairOption:getState(), g_playerColors[self.selectedPlayerColorIndex], self.hatOption:getState() - 1, self.accessoryOption:getState() - 1, self.jacketOption:getState() - 1)
end

function CharacterCreationScreen:updateCharacter(player, body, hairStyle, shirtColor, hat, accessory, jacket)
	if self.loadedPlayer ~= player then
		local filename = self.players[player].filename
		self.loadedPlayer = player

		streamI3DFile(filename, "loadCharacterFinished", self, {
			player,
			body,
			hairStyle,
			shirtColor,
			hat,
			accessory,
			jacket
		}, false, false, false)
	else
		self:updateCharacterOptions(body, hairStyle, shirtColor, hat, accessory, jacket)
	end
end

function CharacterCreationScreen:loadCharacterFinished(nodeId, arguments)
	if nodeId == 0 then
		print("ERROR: Failed to load character i3d")

		return
	end

	if not self.isOpen then
		self.loadedPlayer = nil

		delete(nodeId)

		return
	end

	local rootNode = self.sceneRender:getSceneRoot()
	local characterRoot = I3DUtil.indexToObject(rootNode, "2|0")

	if characterRoot == nil then
		self:deleteAnimation()
		delete(nodeId)

		return
	end

	if self.characterNode ~= nil then
		delete(self.characterNode)

		self.hatNode = nil
	end

	self.characterNode = nodeId

	link(characterRoot, self.characterNode)

	self.currentVisibleHat = nil
	self.currentVisibleAccessory = nil
	local player, body, hairStyle, shirtColor, hat, accessory, jacket = unpack(arguments)

	self:updateCharacterOptions(body, hairStyle, shirtColor, hat, accessory, jacket)

	self.createIdleAnim = true
end

function CharacterCreationScreen:updatePossiblePlayerOptions()
	local player = self.players[self.selectedPlayerIndex]
	local hasJackets = #player.jackets > 0
	local hasHairStyles = #player.hairStyles > 0

	self.jacketOption:setDisabled(not hasJackets)

	if not hasJackets then
		self.jacketOption:setState(1)
	end

	self.hairOption:setDisabled(not hasHairStyles)

	if not hasHairStyles then
		self.jacketOption:setState(1)
	end

	self:setMenuTexts()
end

function CharacterCreationScreen:updateCharacterOptions(body, hairStyle, shirtColor, hat, accessory, jacket)
	local player = self.players[self.loadedPlayer]

	local function makeSingleVisible(items, active, key)
		for i, item in ipairs(items) do
			local node = I3DUtil.indexToObject(self.characterNode, item[key])

			if node ~= nil then
				setVisibility(node, i == active)
			end
		end
	end

	makeSingleVisible(player.jackets, jacket, "node")
	makeSingleVisible(player.bodies, body, "headNode")
	makeSingleVisible(player.bodies, body, "armNode")

	local shirtNode = I3DUtil.indexToObject(self.characterNode, player.shirtNode)

	if shirtNode then
		local r, g, b, a = unpack(shirtColor.value)

		setShaderParameter(shirtNode, "colorScaleR", r, g, b, a, false)
	end

	if self.currentVisibleHat ~= hat then
		self.currentVisibleHat = hat

		if hat ~= 0 then
			local variant = self.clothing.hats[hat]

			streamI3DFile(variant.filename, "loadHatFinished", self, {
				hat
			}, false, false, false)
		elseif self.hatNode ~= nil then
			unlink(self.hatNode)
			delete(self.hatNode)

			self.hatNode = nil

			self:setHatHairNodeVisibility(false)
		end
	end

	makeSingleVisible(player.hairStyles, self.hatNode == nil and hairStyle or -1, "node")

	if self.currentVisibleAccessory ~= accessory then
		self.currentVisibleAccessory = accessory

		if accessory ~= 0 then
			local variant = self.clothing.accessories[accessory]

			streamI3DFile(variant.filename, "loadAccessoryFinished", self, {
				accessory
			}, false, false, false)
		elseif self.accessoryNode ~= nil then
			unlink(self.accessoryNode)
			delete(self.accessoryNode)

			self.accessoryNode = nil
		end
	end

	self.sceneRender:setRenderDirty()
end

function CharacterCreationScreen:loadHatFinished(nodeId, arguments)
	if nodeId == 0 then
		return
	end

	if not self.isOpen then
		delete(nodeId)

		return
	end

	local variantIndex = unpack(arguments)
	local player = self.players[self.loadedPlayer]

	if variantIndex ~= self.currentVisibleHat then
		delete(nodeId)

		return
	end

	if self.hatNode ~= nil then
		unlink(self.hatNode)
		delete(self.hatNode)
	end

	local hat = self.clothing.hats[variantIndex]
	local node = I3DUtil.indexToObject(nodeId, hat.node)
	self.hatNode = node
	local attach = I3DUtil.indexToObject(self.characterNode, player.hatNode)

	link(attach, node)

	for _, item in ipairs(player.hairStyles) do
		local node = I3DUtil.indexToObject(self.characterNode, item.node)

		setVisibility(node, false)
	end

	self:setHatHairNodeVisibility(true)
end

function CharacterCreationScreen:setHatHairNodeVisibility(visibility)
	local player = self.players[self.loadedPlayer]
	local hatHairNode = I3DUtil.indexToObject(self.characterNode, player.hatHairNode)

	if hatHairNode ~= nil then
		setVisibility(hatHairNode, visibility)
	end
end

function CharacterCreationScreen:loadAccessoryFinished(nodeId, arguments)
	if nodeId == 0 then
		return
	end

	if not self.isOpen then
		delete(nodeId)

		return
	end

	local variantIndex = unpack(arguments)
	local player = self.players[self.loadedPlayer]

	if variantIndex ~= self.currentVisibleAccessory then
		delete(nodeId)

		return
	end

	if self.accessoryNode ~= nil then
		unlink(self.accessoryNode)
		delete(self.accessoryNode)
	end

	local accessory = self.clothing.accessories[variantIndex]
	local node = I3DUtil.indexToObject(nodeId, accessory.node)
	self.accessoryNode = node
	local attach = I3DUtil.indexToObject(self.characterNode, player.accessoryNode)

	link(attach, node)
end

function CharacterCreationScreen:onChangeBody(state)
	self:setCharacterIndex(state)
	self:updatePossiblePlayerOptions()
	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:onChangeHairStyle(state)
	self.playerHairStyleIndex = self.hairOption:getState()

	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:onChangeHat(state)
	self.playerHat = self.hatOption:getState()

	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:onChangeJacket(state)
	self.playerJacket = self.jacketOption:getState()

	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:onChangeAccessory(state)
	self.playerAccessory = self.accessoryOption:getState()

	self:updateCharacterWithSettings()
end

function CharacterCreationScreen:onClickColorButton(element)
	self.selectedPlayerColorIndex = self.colorMapping[element]

	self:updateCharacterWithSettings()
	self:updateOkButton()
end
