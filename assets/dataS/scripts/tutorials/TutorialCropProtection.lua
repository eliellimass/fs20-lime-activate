TutorialCropProtection = {}
local TutorialCropProtection_mt = Class(TutorialCropProtection, Tutorial)

function TutorialCropProtection:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialCropProtection:superClass():new(baseDirectory, customMt or TutorialCropProtection_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_cropProtection_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_WEEDER_INFO = self:addTutorialMessage(prefix .. "wedderInfo")
	self.MESSAGE_ATTACH_TOOLS_01 = self:addTutorialMessage(prefix .. "attachTools01")
	self.MESSAGE_UNFOLD_TOOLS_01 = self:addTutorialMessage(prefix .. "unfoldWeeder")
	self.MESSAGE_SPRAYER_INFO = self:addTutorialMessage(prefix .. "sprayerInfo")
	self.MESSAGE_FILL_UNFOLD_TOOLS_02 = self:addTutorialMessage(prefix .. "unfoldTools02")

	return self
end

function TutorialCropProtection:loadMission00Finished(node, arguments)
	TutorialCropProtection:superClass().loadMission00Finished(self, node, arguments)

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
		self.percentageDoneFactor = 0.99
		self.weedingDone = false
		self.sprayingDone = false
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/suer/SB700/SB700.xml", 636, 0.1, 730.5, MathUtil.degToRad(270), true, "weight01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/fendt/favorit500/favorit500.xml", 640, 0.1, 730.5, MathUtil.degToRad(270), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			wheel = 3
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/einboeck/rotation1200/rotation1200.xml", 644, 0.1, 730.5, MathUtil.degToRad(270), true, "weeder", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialCropProtection:loadedVehicles()
	if self.cancelLoading then
		return
	end

	local fruitId = FruitType.WHEAT

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitId, FieldManager.FIELDSTATE_GROWING, 2, 0, false, 0, 2, 0)
	end

	local weedType = g_fruitTypeManager:getWeedFruitType()
	local ids = g_currentMission.fruits[weedType.index]
	local weed = weedType.weed

	self:clearDensityParallelograms()

	self.densityId = ids.id
	self.densityValue = 0
	self.densityFirstChannel = weedType.startStateChannel
	self.densityNumChannels = weedType.numStateChannels
	self.densityValueShift = 1
	local totalArea = self:addFieldParallelograms()
	self.targetDensity = self.percentageDoneFactor * totalArea * 1
	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialCropProtection:update(dt)
	TutorialCropProtection:superClass().update(self, dt)

	if self.isRunning and not self.isPreparingForNextPart then
		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			self:showTutorialMessage(self.MESSAGE_WEEDER_INFO)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
			self:showTutorialMessage(self.MESSAGE_ATTACH_TOOLS_01, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle == self.tractor01 then
				done = self.weight01:getRootVehicle() == self.tractor01 and self.weeder:getRootVehicle() == self.tractor01
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				self:showTutorialMessage(self.MESSAGE_UNFOLD_TOOLS_01, controls)
			end
		end

		if self.weedingDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_SPRAYER_INFO, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle == self.tractor02 then
					done = self.weight02:getRootVehicle() == self.tractor02 and self.sprayer:getRootVehicle() == self.tractor02
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, string.format(g_i18n:getText("action_refillOBJECT"), self.sprayer.typeDesc)))
					self:showTutorialMessage(self.MESSAGE_FILL_UNFOLD_TOOLS_02, controls)

					self.canBeFinished = true
				end
			end
		end
	end
end

function TutorialCropProtection:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_cropProtection_text_finishedSpraying"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0

			if not self.weedingDone then
				self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_cropProtection_text_finishedWeeder"), -1, nil, self.finishCurrentPart, self)
			elseif not self.sprayingDone then
				-- Nothing
			end
		end
	end
end

function TutorialCropProtection:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialCropProtection:loadNextVehicles()
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

	if not self.weedingDone then
		self.weedingDone = true

		for i = 1, self.MESSAGE_UNFOLD_TOOLS_01 do
			self:setWasTutorialMessageShown(i, true)
		end

		local fruitId = FruitType.WHEAT

		for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitId, FieldManager.FIELDSTATE_GROWING, 4, 0, false, 0, 3, 0)
		end

		local weedType = g_fruitTypeManager:getWeedFruitType()
		local ids = g_currentMission.fruits[weedType.index]
		local weed = weedType.weed
		self.densityId = ids.id
		self.densityValue = 5
		self.densityFirstChannel = weedType.startStateChannel
		self.densityNumChannels = weedType.numStateChannels
		self.densityValueShift = 0
		local totalArea = self:addFieldParallelograms()
		self.targetDensity = self.percentageDoneFactor * totalArea * self.densityValue
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/agco/weight1500/weight1500.xml", 636, 0.1, 734, MathUtil.degToRad(270), true, "weight02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/caseIH/puma/puma.xml", 640, 0.1, 734, MathUtil.degToRad(270), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			wheel = 5
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/hardi/mega2200/mega2200.xml", 644, 0.1, 734, MathUtil.degToRad(270), true, "sprayer", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/objects/pallets/liquidTank/herbicideTank.xml", 637, 0.1, 731, MathUtil.degToRad(270), true, "pallet", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	end
end

function TutorialCropProtection:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)
end
