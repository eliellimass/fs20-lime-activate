TutorialSoilCare = {}
local TutorialSoilCare_mt = Class(TutorialSoilCare, Tutorial)

function TutorialSoilCare:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialSoilCare:superClass():new(baseDirectory, customMt or TutorialSoilCare_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_soilCare_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_WELCOME_LIME = self:addTutorialMessage(prefix .. "welcomeLime")
	self.MESSAGE_ATTACH_TOOLS_01 = self:addTutorialMessage(prefix .. "attachTools01")
	self.MESSAGE_WELCOME_PLOW = self:addTutorialMessage(prefix .. "welcomePlow")
	self.MESSAGE_ATTACH_TOOLS_02 = self:addTutorialMessage(prefix .. "attachTools02")

	return self
end

function TutorialSoilCare:loadMission00Finished(node, arguments)
	TutorialSoilCare:superClass().loadMission00Finished(self, node, arguments)

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
		self.percentageDoneFactor = 0.95
		self.limeDone = false
		self.plowDone = false
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/suer/SB1000/SB1000.xml", 636, 0.1, 734, MathUtil.degToRad(270), true, "weight01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/caseIH/magnum7240Pro/magnum7240Pro.xml", 640, 0.1, 734, MathUtil.degToRad(270), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/bredal/K165/K165.xml", 648, 0.1, 734, MathUtil.degToRad(270), true, "sprayer", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialSoilCare:loadedVehicles()
	if self.cancelLoading then
		return
	end

	local sprayers = {
		self.sprayer
	}
	local fillTypes = {
		FillType.LIME
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

	self.densityId = self.terrainDetailId
	self.densityValue = self.limeCounterMaxValue
	self.densityFirstChannel = self.limeCounterFirstChannel
	self.densityNumChannels = self.limeCounterNumChannels
	local totalArea = self:addFieldParallelograms()
	self.targetDensity = self.percentageDoneFactor * totalArea * self.densityValue
	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialSoilCare:update(dt)
	TutorialSoilCare:superClass().update(self, dt)

	if self.isRunning and not self.isPreparingForNextPart then
		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME, nil)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME_LIME, nil)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
			self:showTutorialMessage(self.MESSAGE_ATTACH_TOOLS_01, controls)
		end

		if self.limeDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_PLOW, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				self:showTutorialMessage(self.MESSAGE_ATTACH_TOOLS_02, controls)

				self.canBeFinished = true
			end
		end
	end
end

function TutorialSoilCare:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_soilCare_text_finishedPlow"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0

			if not self.limeDone then
				self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_soilCare_text_finishedLime"), -1, nil, self.finishCurrentPart, self)
			elseif not self.raddishDone then
				-- Nothing
			end
		end
	end
end

function TutorialSoilCare:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialSoilCare:loadNextVehicles()
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

	if not self.limeDone then
		self.limeDone = true

		for i = 1, self.MESSAGE_ATTACH_TOOLS_01 do
			self:setWasTutorialMessageShown(i, true)
		end

		local fruitId = FruitType.CANOLA

		for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitId, FieldManager.FIELDSTATE_HARVESTED, nil, 0, false)
		end

		self:clearDensityParallelograms()

		self.densityId = self.terrainDetailId
		self.densityValue = self.plowValue
		self.densityFirstChannel = self.terrainDetailTypeFirstChannel
		self.densityNumChannels = self.terrainDetailTypeNumChannels
		self.percentageDoneFactor = 0.15
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * self.densityValue
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/suer/SB1000/SB1000.xml", 636, 0.1, 725, MathUtil.degToRad(270), true, "weight02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/masseyFerguson/MF7700/MF7700.xml", 640, 0.1, 725, MathUtil.degToRad(270), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/agromasz/agromaszPOH5/agromaszPOH5.xml", 644, 0.1, 725, MathUtil.degToRad(270), true, "plow", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.plowDone then
		self.plowDone = true
	end
end

function TutorialSoilCare:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)
end
