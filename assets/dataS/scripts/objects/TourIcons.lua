TourIcons = {}
local TourIcons_mt = Class(TourIcons)

function TourIcons:onCreate(id)
	local tourIcons = TourIcons:new(id)

	table.insert(g_currentMission.updateables, tourIcons)

	g_currentMission.tourIconsBase = tourIcons
end

function TourIcons:new(id)
	local self = {}

	setmetatable(self, TourIcons_mt)

	self.me = id
	local num = getNumOfChildren(self.me)
	self.tourIcons = {}

	for i = 0, num - 1 do
		local tourIconTriggerId = getChildAt(self.me, i)
		local tourIconId = getChildAt(tourIconTriggerId, 0)

		addTrigger(tourIconTriggerId, "triggerCallback", self)
		setVisibility(tourIconId, false)

		local tourIcon = {
			tourIconTriggerId = tourIconTriggerId,
			tourIconId = tourIconId
		}

		table.insert(self.tourIcons, tourIcon)
	end

	self.visible = false
	self.mapHotspot = nil
	self.currentTourIconNumber = 1
	self.alpha = 0.25
	self.alphaDirection = 1
	self.startTourDialog = false
	self.startTourDialogDelay = 0
	self.permanentMessageDelay = 0
	self.isPaused = false
	self.pauseTime = 0
	self.soldStuffAtGrainElevator = false
	_, self.permanentTextSize = getNormalizedScreenValues(0, 28)

	return self
end

function TourIcons:delete()
	for _, tourIcon in pairs(self.tourIcons) do
		removeTrigger(tourIcon.tourIconTriggerId)
	end

	if self.me ~= 0 then
		delete(self.me)

		self.me = 0
	end
end

function TourIcons:showTourDialog()
	g_gui:showYesNoDialog({
		title = "",
		text = g_i18n:getText("tour_text_start"),
		callback = self.reactToDialog,
		target = self
	})
end

function TourIcons:reactToDialog(yes)
	if yes then
		self.visible = true

		self:activateNextIcon()

		if g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(false, true)
		end

		g_messageCenter:publish(MessageType.MISSION_TOUR_STARTED)
	else
		self.visible = false

		g_currentMission.hud:showInGameMessage("", g_i18n:getText("tour_text_abort"), -1)
		self:delete()
	end
end

function TourIcons:update(dt)
	if not g_currentMission.missionInfo.isValid and g_server ~= nil and self.initDone == nil and g_currentMission:getIsTourSupported() then
		self.initDone = true
		local field = g_fieldManager:getFieldByIndex(2)
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_GROWING, fruitDesc.maxHarvestingGrowthState, 3, true, g_currentMission.plowCounterMaxValue, 0, g_currentMission.limeCounterMaxValue)
		end

		local field = g_fieldManager:getFieldByIndex(1)
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.CANOLA)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_HARVESTED, 0, 0, false, g_currentMission.plowCounterMaxValue, 0, g_currentMission.limeCounterMaxValue)
		end

		local field = g_fieldManager:getFieldByIndex(3)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_CULTIVATED, 0, 0, false, g_currentMission.plowCounterMaxValue, 0, g_currentMission.limeCounterMaxValue)
		end
	end

	if self.startTourDialog then
		self.startTourDialogDelay = self.startTourDialogDelay - dt
		local showDialog = true

		if g_currentMission.cameraFlightManager ~= nil then
			showDialog = g_currentMission.cameraFlightManager.careerStartFlightPlayed
		end

		if showDialog and self.startTourDialogDelay < 0 then
			self.startTourDialog = false

			self:showTourDialog()
		end
	end

	if g_gui:getIsGuiVisible() then
		return
	elseif self.queuedMessage ~= nil then
		g_currentMission.hud.ingameMap:toggleSize(IngameMap.STATE_MINIMAP, true)
		g_currentMission.hud:showInGameMessage(unpack(self.queuedMessage))

		self.queuedMessage = nil

		return
	end

	if self.isPaused then
		if self.pauseTime > 0 then
			self.pauseTime = self.pauseTime - dt
		else
			self.pauseTime = 0
			self.isPaused = false

			self:activateNextIcon()
		end
	end

	if self.visible and not self.isPaused then
		if not g_currentMission.hud:isInGameMessageVisible() and not g_gui:getIsGuiVisible() and false then
			if self.permanentMessageDelay > 0 then
				self.permanentMessageDelay = self.permanentMessageDelay - dt
				self.alpha = 0.25
				self.alphaDirection = 1
			else
				setTextColor(1, 1, 1, self.alpha)
				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)
				setTextWrapWidth(0.35)

				if GS_IS_CONSOLE_VERSION then
					setTextWrapWidth(0.295)
				end

				renderText(0.5, 0.93, self.permanentTextSize, g_i18n:getText("tour_permanentText" .. self.currentTourIconNumber - 1))
				setTextWrapWidth(0)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextBold(false)
				setTextColor(1, 1, 1, 1)

				self.alpha = self.alpha + self.alphaDirection * dt / 600

				if self.alpha > 1 or self.alpha < 0.25 then
					self.alphaDirection = self.alphaDirection * -1
					self.alpha = MathUtil.clamp(self.alpha, 0.25, 1)
				end
			end
		end

		if self.currentTourIconNumber <= 3 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourCombine then
				self.currentTourIconNumber = 3
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 4 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourCombine and g_currentMission.tourVehicles.tourCombine.spec_combine.numAttachedCutters > 0 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 5 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourCombine and g_currentMission.controlledVehicle:getIsTurnedOn() then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 7 then
			if g_currentMission.tourVehicles.tourCombine:getIsTurnedOn() and g_currentMission.tourVehicles.tourCombine:getIsAIActive() then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber <= 9 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 then
				if self.currentTourIconNumber == 8 then
					self:activateNextIcon()
				end

				if g_currentMission.tourVehicles.tourCultivator:getRootVehicle() == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourWeight1:getRootVehicle() == g_currentMission.tourVehicles.tourTractor1 then
					self.pauseTime = 1000
					self.isPaused = true
				end
			end
		elseif self.currentTourIconNumber == 11 then
			self.pauseTime = 1000
			self.isPaused = true
		elseif self.currentTourIconNumber <= 13 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor2 then
				if self.currentTourIconNumber == 12 then
					self:activateNextIcon()
				end

				if g_currentMission.tourVehicles.tourSowingMachine:getRootVehicle() == g_currentMission.tourVehicles.tourTractor2 and g_currentMission.tourVehicles.tourWeight2:getRootVehicle() == g_currentMission.tourVehicles.tourTractor2 then
					self.pauseTime = 1000
					self.isPaused = true
				end
			end
		elseif self.currentTourIconNumber <= 16 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor3 then
				if self.currentTourIconNumber < 16 then
					self:activateNextIcon()
				end

				if g_currentMission.tourVehicles.tourTrailer:getRootVehicle() == g_currentMission.tourVehicles.tourTractor3 then
					self.pauseTime = 1000
					self.isPaused = true
				end
			end
		elseif self.currentTourIconNumber == 17 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor3 then
				if g_currentMission.tourVehicles.tourTrailer:getRootVehicle() == g_currentMission.tourVehicles.tourTractor3 then
					local tractor = g_currentMission.tourVehicles.tourTractor3
					local trailer = g_currentMission.tourVehicles.tourTrailer
					local combine = g_currentMission.tourVehicles.tourCombine
					local x, y, z = localToWorld(combine.components[1].node, 6, 0, 0)

					self.mapHotspot:setWorldPosition(x, z)

					local xv, yv, zv = getWorldTranslation(tractor.components[1].node)
					local dist = MathUtil.vector3Length(x - xv, y - yv, z - zv)

					if dist < 10 then
						g_currentMission:setMapTargetHotspot(nil)
					else
						g_currentMission:setMapTargetHotspot(self.mapHotspot)
					end

					local fillUnitIndex = 1
					local dischargeNode = combine:getCurrentDischargeNode()

					if trailer:getFillUnitFillLevel(fillUnitIndex) > 0 and dischargeNode ~= nil and dischargeNode.dischargeObject == trailer then
						self.pauseTime = 1000
						self.isPaused = true
					end
				end
			elseif g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) > 400 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 19 then
			self.pauseTime = 3000
			self.isPaused = true
		elseif self.currentTourIconNumber <= 20 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor3 then
				if self.currentTourIconNumber == 19 then
					self:activateNextIcon()
				end

				if g_currentMission.tourVehicles.tourTrailer:getRootVehicle() == g_currentMission.tourVehicles.tourTractor3 then
					local trailer = g_currentMission.tourVehicles.tourTrailer
					local unloadingStation = nil

					for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
						if station.owningPlaceable ~= nil and station.owningPlaceable.mapBoundId == "sellingStationRestaurant" then
							unloadingStation = station

							break
						end
					end

					local dischargeNode = trailer:getCurrentDischargeNode()

					if dischargeNode ~= nil and dischargeNode.currentDischargeObject ~= nil and dischargeNode.currentDischargeObject:getTarget() == unloadingStation then
						self.pauseTime = 3000
						self.isPaused = true
					end
				end
			end
		elseif self.currentTourIconNumber == 22 then
			self.pauseTime = 1000
			self.isPaused = true
		end
	end
end

function TourIcons:makeIconVisible(tourIconId)
	setVisibility(tourIconId, true)

	local x, _, z = getWorldTranslation(tourIconId)

	if self.mapHotspot == nil then
		-- Nothing
	end

	self.mapHotspot:setWorldPosition(x, z)

	local x, y, z = getWorldTranslation(tourIconId)
	local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

	if h < y then
		g_currentMission:setMapTargetHotspot(self.mapHotspot)

		self.mapHotspot.enabled = true
	else
		g_currentMission:setMapTargetHotspot(nil)

		self.mapHotspot.enabled = false
	end
end

function TourIcons:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and self.tourIcons[self.currentTourIconNumber] ~= nil and self.tourIcons[self.currentTourIconNumber].tourIconTriggerId == triggerId and getVisibility(self.tourIcons[self.currentTourIconNumber].tourIconId) then
		self:activateNextIcon()
	end
end

function TourIcons:activateNextIcon()
	for i = 1, self.currentTourIconNumber do
		local tourIcon = self.tourIcons[i]

		if getVisibility(tourIcon.tourIconId) then
			setVisibility(tourIcon.tourIconId, false)
			setCollisionMask(tourIcon.tourIconTriggerId, 0)
		end
	end

	if self.tourIcons[self.currentTourIconNumber + 1] ~= nil then
		self:makeIconVisible(self.tourIcons[self.currentTourIconNumber + 1].tourIconId)
	else
		if self.mapHotspot ~= nil then
			g_currentMission:removeMapHotspot(self.mapHotspot)
			self.mapHotspot:delete()

			self.mapHotspot = nil
		end

		if g_gameSettings:getValue("showHelpIcons") and g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(true, true)
		end

		self.visible = false

		g_messageCenter:publish(MessageType.MISSION_TOUR_FINISHED)
		self:delete()
	end

	local title = g_i18n:getText("ui_tour")
	local text = ""
	local controls = {}

	if self.currentTourIconNumber == 1 then
		text = g_i18n:getText("tour_text_part01_lookAndWalk")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_MAP_SIZE, nil, g_i18n:getText("action_toggleMapView")))

		local useGamepadButtons = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD

		if useGamepadButtons then
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_MOVE_FORWARD_PLAYER, InputAction.AXIS_MOVE_SIDE_PLAYER, g_i18n:getText("action_movePlayer")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_LOOK_UPDOWN_PLAYER, InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER, g_i18n:getText("action_lookPlayer")))
		else
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_MOVE_FORWARD_PLAYER, InputAction.AXIS_MOVE_SIDE_PLAYER, g_i18n:getText("action_movePlayer")))
		end
	elseif self.currentTourIconNumber == 2 then
		text = g_i18n:getText("tour_text_part01_enterCombine")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
	elseif self.currentTourIconNumber == 3 then
		text = g_i18n:getText("tour_text_part01_attachHeader")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
	elseif self.currentTourIconNumber == 4 then
		text = g_i18n:getText("tour_text_part01_turnOnCombine")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
	elseif self.currentTourIconNumber == 5 then
		text = g_i18n:getText("tour_text_part01_startHarvesting")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_ACCELERATE_VEHICLE, InputAction.AXIS_BRAKE_VEHICLE, g_i18n:getText("action_accelerate")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_MOVE_SIDE_VEHICLE, nil, g_i18n:getText("action_steer")))
	elseif self.currentTourIconNumber == 6 then
		text = g_i18n:getText("tour_text_part01_startHelperHarvesting")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_AI, nil, g_i18n:getText("input_TOGGLE_AI")))
	elseif self.currentTourIconNumber == 7 then
		text = g_i18n:getText("tour_text_part01_finished")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("action_exitVehicle")))
	elseif self.currentTourIconNumber == 8 then
		text = g_i18n:getText("tour_text_part02_enterTractor01")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
	elseif self.currentTourIconNumber == 9 then
		text = g_i18n:getText("tour_text_part02_startCultivating")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("input_LOWER_IMPLEMENT")))
	elseif self.currentTourIconNumber == 10 then
		text = g_i18n:getText("tour_text_part02_enoughCultivating")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_AI, nil, g_i18n:getText("input_TOGGLE_AI")))
	elseif self.currentTourIconNumber == 11 then
		text = g_i18n:getText("tour_text_part02_finished")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_VEHICLE, nil, g_i18n:getText("input_SWITCH_VEHICLE")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_VEHICLE_BACK, nil, g_i18n:getText("input_SWITCH_VEHICLE_BACK")))
	elseif self.currentTourIconNumber == 12 then
		text = g_i18n:getText("tour_text_part03_enterTractor01")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
	elseif self.currentTourIconNumber == 13 then
		text = g_i18n:getText("tour_text_part03_startSowing")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA3, nil, g_i18n:getText("action_chooseSeed")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("input_LOWER_IMPLEMENT")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
	elseif self.currentTourIconNumber == 14 then
		text = g_i18n:getText("tour_text_part03_finished")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_VEHICLE, nil, g_i18n:getText("input_SWITCH_VEHICLE")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_VEHICLE_BACK, nil, g_i18n:getText("input_SWITCH_VEHICLE_BACK")))
	elseif self.currentTourIconNumber == 15 then
		text = g_i18n:getText("tour_text_part04_enterTractor01")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
	elseif self.currentTourIconNumber == 16 then
		text = g_i18n:getText("tour_text_part04_alignToHarvester")
	elseif self.currentTourIconNumber == 17 then
		text = g_i18n:getText("tour_text_part04_unloadWheat")
	elseif self.currentTourIconNumber == 18 then
		text = g_i18n:getText("tour_text_part04_pricesInfo")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.MENU, nil, g_i18n:getText("input_MENU")))
	elseif self.currentTourIconNumber == 19 then
		text = g_i18n:getText("tour_text_part04_sellWheat")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_TIPSTATE, nil, g_i18n:getText("input_TOGGLE_TIPSTATE")))
	elseif self.currentTourIconNumber == 20 then
		text = g_i18n:getText("tour_text_part04_doneSelling")
	elseif self.currentTourIconNumber == 21 then
		text = g_i18n:getText("tour_text_part05_visitShop")

		table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_STORE, nil, g_i18n:getText("input_TOGGLE_STORE")))
	elseif self.currentTourIconNumber == 22 then
		text = g_i18n:getText("tour_text_end")
	end

	if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.setCruiseControlState ~= nil then
		g_currentMission.controlledVehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
	end

	if g_gui:getIsGuiVisible() then
		self.queuedMessage = {
			title,
			text,
			-1,
			controls
		}
	else
		g_currentMission.hud.ingameMap:toggleSize(IngameMap.STATE_MINIMAP, true)
		g_currentMission.hud:showInGameMessage(title, text, -1, controls)
	end

	self.currentTourIconNumber = self.currentTourIconNumber + 1
	self.permanentMessageDelay = 250
end
