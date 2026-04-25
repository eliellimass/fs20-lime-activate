TutorialFertilizing = {}
local TutorialFertilizing_mt = Class(TutorialFertilizing, Tutorial)

function TutorialFertilizing:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialFertilizing:superClass():new(baseDirectory, customMt or TutorialFertilizing_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_fertilizing_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_WELCOME_FERTILIZER = self:addTutorialMessage(prefix .. "welcomeFertilizer")
	self.MESSAGE_START_FERTILIZING = self:addTutorialMessage(prefix .. "startFertilizing")
	self.MESSAGE_WELCOME_RADISH = self:addTutorialMessage(prefix .. "welcomeRadish")
	self.MESSAGE_ATTACH_TOOLS_02 = self:addTutorialMessage(prefix .. "attachTools02")

	return self
end

function TutorialFertilizing:loadMission00Finished(node, arguments)
	TutorialFertilizing:superClass().loadMission00Finished(self, node, arguments)

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
		self.percentageDoneFactor = 0.6
		self.fertilizingDone = false
		self.radishDone = false
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/agco/weight650/weight650.xml", 636, 0.1, 728, MathUtil.degToRad(270), true, "weight01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/johnDeere/series6R/series6R.xml", 640, 0.1, 728, MathUtil.degToRad(270), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/farmtech/superfex800/superfex800.xml", 644, 0.1, 719, MathUtil.degToRad(0), true, "manureSpreader", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/kotte/ve8000/ve8000.xml", 649, 0.1, 719, MathUtil.degToRad(0), true, "slurrySpreader", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/bredal/K105/k105.xml", 654, 0.1, 719.5, MathUtil.degToRad(0), true, "fertilizerSpreader", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialFertilizing:loadedVehicles()
	if self.cancelLoading then
		return
	end

	local sprayers = {
		self.manureSpreader,
		self.slurrySpreader,
		self.fertilizerSpreader
	}
	local fillTypes = {
		FillType.MANURE,
		FillType.LIQUIDMANURE,
		FillType.FERTILIZER
	}

	for i, sprayer in ipairs(sprayers) do
		local index = sprayer.spec_sprayer.fillUnitIndex
		local capacity = sprayer:getFillUnitCapacity(index)

		sprayer:addFillUnitFillLevel(FarmManager.SINGLEPLAYER_FARM_ID, index, capacity, fillTypes[i], ToolType.UNDEFINED, nil)
	end

	local fruitId = FruitType.WHEAT

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitId, FieldManager.FIELDSTATE_HARVESTED, nil, 0, false)
	end

	self:clearDensityParallelograms()

	self.useDensityArea = true
	self.densityId = self.terrainDetailId
	self.densityValue = 0
	self.densityFirstChannel = self.sprayFirstChannel
	self.densityNumChannels = self.sprayNumChannels
	local totalArea = self:addFieldParallelograms()
	self.targetDensity = self.percentageDoneFactor * totalArea
	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialFertilizing:update(dt)
	TutorialFertilizing:superClass().update(self, dt)

	if self.isRunning and not self.isPreparingForNextPart then
		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME, nil)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
			self:showTutorialMessage(self.MESSAGE_WELCOME_FERTILIZER, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle == self.tractor01 and self.weight01:getRootVehicle() == self.tractor01 then
				if self.manureSpreader:getRootVehicle() == self.tractor01 then
					self.chosenFertilizer = "MANURE"
					done = true
				elseif self.fertilizerSpreader:getRootVehicle() == self.tractor01 then
					self.chosenFertilizer = "FERTILIZER"
					done = true
				elseif self.slurrySpreader:getRootVehicle() == self.tractor01 then
					self.chosenFertilizer = "SLURRY"
					done = true
				end
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
				self:showTutorialMessage(self.MESSAGE_START_FERTILIZING, controls)
			end
		end

		if self.fertilizingDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_RADISH, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				self:showTutorialMessage(self.MESSAGE_ATTACH_TOOLS_02, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor02

				if done then
					self.canBeFinished = true
				end
			end
		end
	end
end

function TutorialFertilizing:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_fertilizing_text_finishedRadish"), -1, nil, , )
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_fertilizing_text_finishedTutorial"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0

			if not self.fertilizingDone then
				self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_fertilizing_text_finishedFertilizing"), -1, nil, self.finishCurrentPart, self)
			elseif not self.radishDone then
				-- Nothing
			end
		end
	end
end

function TutorialFertilizing:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialFertilizing:loadNextVehicles()
	self.isPreparingForNextPart = true

	if self.controlledVehicle ~= nil then
		self:onLeaveVehicle()
	end

	self.player:moveTo(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerStartIsAbsolute, false)

	local rotY = self.playerRotY
	self.player.graphicsRotY = rotY
	self.player.rotY = rotY
	self.player.cameraRotY = rotY
	self.player.targetGraphicsRotY = rotY

	self.player:lockInput(true)

	while table.getn(self.vehicles) > 0 do
		for i = table.getn(self.vehicles), 1, -1 do
			local vehicle = self.vehicles[i]

			vehicle:delete()
			table.remove(self.vehicles, i)
		end
	end

	if g_currentMission.tireTrackSystem ~= nil then
		g_currentMission.tireTrackSystem:eraseParallelogram(-1025, -1025, 1025, -1025, -1025, 1025)
	end

	self:clearDensityParallelograms()

	if not self.fertilizingDone then
		self.fertilizingDone = true

		for i = 1, self.MESSAGE_START_FERTILIZING do
			self:setWasTutorialMessageShown(i, true)
		end

		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.OILSEEDRADISH)

		for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_GROWING, 2, 0, false)
		end

		self:clearDensityParallelograms()

		self.densityId = self.terrainDetailId
		self.densityValue = self.cultivatorValue
		self.densityFirstChannel = self.terrainDetailTypeFirstChannel
		self.densityNumChannels = self.terrainDetailTypeNumChannels
		self.percentageDoneFactor = 0.3
		self.useDensityArea = false
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * self.densityValue
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/agco/weight650/weight650.xml", 636, 0.1, 727.5, MathUtil.degToRad(270), true, "weight02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/steyr/terrusCVT/terrusCVT.xml", 640, 0.1, 727.5, MathUtil.degToRad(270), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			motor = 2
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/horsch/tiger6DT/tiger6DT.xml", 647, 0.1, 727.5, MathUtil.degToRad(270), true, "cultivator", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.radishDone then
		-- Nothing
	end
end

function TutorialFertilizing:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)
end
