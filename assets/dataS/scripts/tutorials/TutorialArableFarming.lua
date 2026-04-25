TutorialArableFarming = {}
local TutorialArableFarming_mt = Class(TutorialArableFarming, Tutorial)

function TutorialArableFarming:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialArableFarming:superClass():new(baseDirectory, customMt or TutorialArableFarming_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_arableFarming_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_CULTIVATING = self:addTutorialMessage(prefix .. "cultivating")
	self.MESSAGE_PLAYER_CONTROLS = self:addTutorialMessage(prefix .. "playerControls")
	self.MESSAGE_ENTER_TRACTOR_01 = self:addTutorialMessage(prefix .. "enterTractor01")
	self.MESSAGE_VEHICLE_CONTROLS = self:addTutorialMessage(prefix .. "vehicleControls")
	self.MESSAGE_ATTACH_CULTIVATOR = self:addTutorialMessage(prefix .. "attachCultivator")
	self.MESSAGE_START_CULTIVATING = self:addTutorialMessage(prefix .. "startCultivating")
	self.MESSAGE_SOWING = self:addTutorialMessage(prefix .. "sowing")
	self.MESSAGE_ENTER_TRACTOR_02 = self:addTutorialMessage(prefix .. "enterTractor02")
	self.MESSAGE_UNFOLD_AND_LOWER_SOWINGMACHINE = self:addTutorialMessage(prefix .. "unfoldAndLowerSowingMachine")
	self.MESSAGE_WELCOME_THRESHING = self:addTutorialMessage(prefix .. "welcomeThreshing")
	self.MESSAGE_ENTER_COMBINE = self:addTutorialMessage(prefix .. "enterCombine")
	self.MESSAGE_UNFOLD_COMBINE = self:addTutorialMessage(prefix .. "unfoldCombine")
	self.MESSAGE_OPEN_PIPE = self:addTutorialMessage(prefix .. "openPipe")
	self.MESSAGE_ENTER_TRACTOR_03 = self:addTutorialMessage(prefix .. "enterTractor03")
	self.MESSAGE_DRIVE_TO_TIPTRIGGER = self:addTutorialMessage(prefix .. "driveToTipTrigger")
	self.MESSAGE_TIPPING_DONE = self:addTutorialMessage(nil)

	return self
end

function TutorialArableFarming:delete()
	self:deleteMapHotspot()
	TutorialArableFarming:superClass().delete(self)
end

function TutorialArableFarming:loadMission00Finished(node, arguments)
	TutorialArableFarming:superClass().loadMission00Finished(self, node, arguments)

	if self.cancelLoading then
		return
	end

	g_deferredLoadingManager:addTask(function ()
		self.state = BaseMission.STATE_INTRO
		self.field = self:acquireField(24)
		self.playerStartX = 665
		self.playerStartY = 0.1
		self.playerStartZ = 720
		self.playerRotX = MathUtil.degToRad(0)
		self.playerRotY = MathUtil.degToRad(110)
		self.playerStartIsAbsolute = false

		self:startLoadingTask()
	end)
	g_deferredLoadingManager:addTask(function ()
		self:removeAllHelpIcons()
		self:playerOwnsAllFields()
		self:addMoney(25000, 1)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.densityId = 0
		self.densityValue = 0
		self.densityFirstChannel = 0
		self.densityNumChannels = 0
		self.percentageDoneFactor = 0.3
		self.harvestLiters = 8000
		self.tipTriggerReferencePosistion = {
			599,
			95.2,
			678
		}
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/agco/weight1100/weight1100.xml", 641, 0.1, 726, MathUtil.degToRad(270), true, "weight01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/masseyFerguson/MF5600/MF5600.xml", 643.5, 0.1, 726, MathUtil.degToRad(270), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			motor = 2
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/kuhn/kuhnCultimerL300/kuhnCultimerL300.xml", 648, 0.1, 726, MathUtil.degToRad(270), true, "cultivator", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
	g_deferredLoadingManager:addTask(function ()
		self:clearDensityParallelograms()

		self.densityId = self.terrainDetailId
		self.densityValue = self.cultivatorValue
		self.densityFirstChannel = self.terrainDetailTypeFirstChannel
		self.densityNumChannels = self.terrainDetailTypeNumChannels
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * self.cultivatorValue
	end)
end

function TutorialArableFarming:loadedVehicles()
	if self.cancelLoading then
		return
	end

	self.state = BaseMission.STATE_RUNNING

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, FruitType.BARLEY, FieldManager.FIELDSTATE_HARVESTED, nil, 0, false, 0, 0, 0)
	end

	self:finishLoadingTask()
end

function TutorialArableFarming:update(dt)
	TutorialArableFarming:superClass().update(self, dt)

	if self.isRunning and not self.isPreparingForNextPart then
		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			local controls = {}

			self:showTutorialMessage(self.MESSAGE_WELCOME, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			self:showTutorialMessage(self.MESSAGE_CULTIVATING, {})
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_MOVE_FORWARD_PLAYER, InputAction.AXIS_MOVE_SIDE_PLAYER, g_i18n:getText("action_movePlayer")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_LOOK_UPDOWN_PLAYER, InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER, g_i18n:getText("action_lookPlayer")))
			self:showTutorialMessage(self.MESSAGE_PLAYER_CONTROLS, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local x0, y0, z0 = getWorldTranslation(self.tractor01.components[1].node)
			local x1, y1, z1 = getWorldTranslation(self.player.cameraNode)
			local dist = MathUtil.vector3Length(x1 - x0, y1 - y0, z1 - z0)
			local done = dist < 10 or self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_01, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_ACCELERATE_VEHICLE, InputAction.AXIS_BRAKE_VEHICLE, g_i18n:getText("action_accelerate")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_MOVE_SIDE_VEHICLE, nil, g_i18n:getText("action_steer")))
				self:showTutorialMessage(self.MESSAGE_VEHICLE_CONTROLS, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
			self:showTutorialMessage(self.MESSAGE_ATTACH_CULTIVATOR, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01 then
				done = self.weight01:getRootVehicle() == self.tractor01 and self.cultivator:getRootVehicle() == self.tractor01
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				self:showTutorialMessage(self.MESSAGE_START_CULTIVATING, controls)
			end
		end

		if self.cultivatingDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				self:showTutorialMessage(self.MESSAGE_SOWING, {})
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_02, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor02 then
					done = self.sowingMachine:getRootVehicle() == self.tractor02
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, string.format(g_i18n:getText("action_refillOBJECT"), self.sowingMachine.typeDesc)))
					self:showTutorialMessage(self.MESSAGE_UNFOLD_AND_LOWER_SOWINGMACHINE, controls)
				end
			end
		end

		if self.sowingDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_THRESHING, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ENTER_COMBINE, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.combine then
					done = self.cutter:getRootVehicle() == self.combine
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
					self:showTutorialMessage(self.MESSAGE_UNFOLD_COMBINE, controls)
				end
			end

			if not self.enoughHarvested then
				self.percent = math.max(self.combine:getFillUnitFillLevel(1) / self.harvestLiters * 100, 0)

				if self.percent >= 100 then
					self.enoughHarvested = true
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.combine then
					local dischargeNode = self.combine:getDischargeNodeByIndex(self.combine.spec_pipe.dischargeNodeIndex)
					local fillLevel = self.combine:getFillUnitFillLevel(dischargeNode.fillUnitIndex)

					if self.harvestLiters < fillLevel then
						done = true
					end
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_PIPE, nil, g_i18n:getText("action_pipe")))
					self:showTutorialMessage(self.MESSAGE_OPEN_PIPE, controls)

					self.state = BaseMission.STATE_RUNNING
					self.drawMissionEndCalled = false
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.trailer ~= nil then
					local fillLevel = self.trailer:getFillUnitFillLevel(1)

					if self.harvestLiters < fillLevel then
						done = true
					end
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
					self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_03, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false
				done = self.controlledVehicle == self.tractor03

				if done then
					local pos = self.tipTriggerReferencePosistion

					self:createMapHotspot(pos[1], pos[3])
					self.hud.ingameMap:toggleSize(IngameMap.STATE_MINIMAP, true)
					self:setMapTargetHotspot(self.hotspot)

					for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
						if unloadingStation.owningPlaceable ~= nil and not unloadingStation.isSellingPoint and unloadingStation.owningPlaceable:isa(SiloPlaceable) and unloadingStation.owningPlaceable:getOwnerFarmId() == FarmManager.SINGLEPLAYER_FARM_ID then
							self.unloadingStation = unloadingStation

							break
						end
					end

					if self.unloadingStation ~= nil then
						self.unloadingStation.tutorialStartFillLevel = self.unloadingStation:getFillLevel(FillType.CANOLA, g_currentMission:getFarmId())
					else
						print("Warning: 'tutorial arable farming' could not find a valid silo unloading station. Tutorial can't be completed succesfully!")
					end

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_TIPSTATE, nil, g_i18n:getText("action_toggleTipState")))
					self:showTutorialMessage(self.MESSAGE_DRIVE_TO_TIPTRIGGER, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false
				local x0, y0, z0 = getWorldTranslation(self.tractor03.components[1].node)
				local dist = MathUtil.vector3Length(self.tipTriggerReferencePosistion[1] - x0, self.tipTriggerReferencePosistion[2] - y0, self.tipTriggerReferencePosistion[3] - z0)

				if dist < 10 then
					g_currentMission:setMapTargetHotspot(nil)
				else
					g_currentMission:setMapTargetHotspot(self.hotspot)
				end

				if self.unloadingStation ~= nil and self.unloadingStation:getFillLevel(FillType.CANOLA, g_currentMission:getFarmId()) >= self.unloadingStation.tutorialStartFillLevel + self.harvestLiters * 0.8 then
					done = true
				end

				if done then
					self.tippingDone = true

					self:deleteMapHotspot()

					self.hotspot = nil
					self.drawMissionEndCalled = false
					self.canBeFinished = true
					self.state = BaseMission.STATE_FINISHED

					g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true, true)
				end
			end
		end
	end
end

function TutorialArableFarming:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_arableFarming_text_finishedHarvesting"), -1)
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_arableFarmingDone"), -1, nil, self.onEndMissionCallback, self)
		elseif not self.cultivatingDone then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_arableFarming_text_finishedCultivating"), -1, nil, self.finishCurrentPart, self)
		elseif not self.sowingDone then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_arableFarming_text_finishedSowing"), -1, nil, self.finishCurrentPart, self)
		elseif not self.harvestingDone and self.tippingDone == true then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_arableFarming_text_finishedHarvesting"), -1, nil, self.finishCurrentPart, self)
		end
	end
end

function TutorialArableFarming:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialArableFarming:loadNextVehicles()
	self.isPreparingForNextPart = true

	if self.controlledVehicle ~= nil then
		self:onLeaveVehicle()
	end

	self.player:moveTo(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerStartIsAbsolute, false)
	self.player:setRotation(self.playerRotX, self.playerRotY)
	self.player:lockInput(true)

	while table.getn(self.vehicles) > 0 do
		for i = table.getn(self.vehicles), 1, -1 do
			local vehicle = self.vehicles[i]

			vehicle:delete()
			table.remove(self.vehicles, i)
		end
	end

	if self.tireTrackSystem ~= nil then
		self.tireTrackSystem:eraseParallelogram(-1025, -1025, 1025, -1025, -1025, 1025)
	end

	self:clearDensityParallelograms()

	if not self.cultivatingDone then
		self.cultivatingDone = true

		for i = 1, self.MESSAGE_START_CULTIVATING do
			self:setWasTutorialMessageShown(i, true)
		end

		for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_CULTIVATED, nil, 0, false)
		end

		self:clearDensityParallelograms()

		self.densityId = self.terrainDetailId
		self.densityValue = self.sowingValue
		self.densityFirstChannel = self.terrainDetailTypeFirstChannel
		self.densityNumChannels = self.terrainDetailTypeNumChannels
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * self.sowingValue
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/johnDeere/series6M/series6M.xml", 638.5, 0.1, 726, MathUtil.degToRad(270), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			design = 5
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/vaderstad/spiritR300S/spiritR300S.xml", 648, 0.1, 726, MathUtil.degToRad(270), true, "sowingMachine", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/objects/bigBagContainer/bigBagContainerSeeds.xml", 648, 0.1, 723, MathUtil.degToRad(0), true, "seedsBag", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.sowingDone then
		self.sowingDone = true

		for i = 1, self.MESSAGE_UNFOLD_AND_LOWER_SOWINGMACHINE do
			self:setWasTutorialMessageShown(i, true)
		end

		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.CANOLA)

		for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_GROWING, fruitDesc.maxHarvestingGrowthState, 3, true)
		end

		self.percent = 0

		self:clearDensityParallelograms()

		self.densityId = g_currentMission.fruits[fruitDesc.index].id
		self.densityValue = fruitDesc.cutState + 1
		self.densityFirstChannel = fruitDesc.startStateChannel
		self.densityNumChannels = fruitDesc.numStateChannels
		self.densityDisabled = true
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * fruitDesc.cutState
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/johnDeere/625X/625X.xml", 638, 0.1, 728, MathUtil.degToRad(-90), true, "cutter", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/johnDeere/T560/T560.xml", 645, 0.1, 728, MathUtil.degToRad(-90), true, "combine", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/newHolland/T5/T5.xml", 563, 0.1, 751, MathUtil.degToRad(0), true, "tractor03", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/farmtech/TDK1600/TDK1600.xml", 563, 0.1, 745.275, MathUtil.degToRad(0), true, "trailer", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.harvestingDone then
		self.harvestingDone = true

		self:clearDensityParallelograms()
	end
end

function TutorialArableFarming:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)

	if not self.sowingDone and self.sowingMachine ~= nil then
		self.sowingMachine:setSeedFruitType(FruitType.CANOLA)

		self.sowingMachine.spec_sowingMachine.allowsSeedChanging = false
	elseif not self.harvestingDone and self.combine ~= nil then
		self.tractor03:attachImplement(self.trailer, 1, 3)

		if self.trailer.setCoverState ~= nil then
			self.trailer:setCoverState(1, true)
		end

		local canolaDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.CANOLA)
		self.originalCanolaLiterPerSqm = canolaDesc.literPerSqm
		canolaDesc.literPerSqm = canolaDesc.literPerSqm * 10
	end
end
