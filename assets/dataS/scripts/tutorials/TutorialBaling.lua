TutorialBaling = {}
local TutorialBaling_mt = Class(TutorialBaling, Tutorial)

function TutorialBaling:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialBaling:superClass():new(baseDirectory, customMt or TutorialBaling_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_baling_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_ENTER_TRACTOR_01 = self:addTutorialMessage(prefix .. "enterTractor01")
	self.MESSAGE_UNFOLD_BALER = self:addTutorialMessage(prefix .. "unfoldBaler")
	self.MESSAGE_WELCOME_AUTOSTACKER = self:addTutorialMessage(prefix .. "welcomeAutostacker")
	self.MESSAGE_ATTACH_TOOLS_02 = self:addTutorialMessage(prefix .. "attachTools02")
	self.MESSAGE_UNLOAD_AUTOSTACKER = self:addTutorialMessage(prefix .. "unloadAutostacker")
	self.disableMapTargetHotspotHiding = true

	return self
end

function TutorialBaling:delete()
	self:deleteMapHotspot()

	for _, triggerId in pairs(self.tutorialTriggers) do
		if triggerId ~= nil then
			removeTrigger(triggerId)
			delete(triggerId)
		end
	end

	TutorialBaling:superClass().delete(self)
end

function TutorialBaling:loadMission00Finished(node, arguments)
	TutorialBaling:superClass().loadMission00Finished(self, node, arguments)

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
		self.percentageDoneFactor = 0.2
		self.neededBales = 5
		self.tutorialNode = loadI3DFile("data/maps/tutorials/tutorialAutoStacking.i3d")

		link(getRootNode(), self.tutorialNode)

		self.triggerPos = {
			693,
			752
		}
		local triggerY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.triggerPos[1], 0, self.triggerPos[2]) - 2
		self.tutorialTriggers = {}
		local triggerParentId = getChildAt(self.tutorialNode, 0)

		if triggerParentId ~= 0 then
			local numChildren = getNumOfChildren(triggerParentId)

			for i = 0, numChildren - 1 do
				local id = getChildAt(triggerParentId, i)

				setWorldTranslation(id, self.triggerPos[1], triggerY, self.triggerPos[2])
				addTrigger(id, "triggerCallback", self)
				table.insert(self.tutorialTriggers, id)
			end
		end

		self.enoughBalesCreated = false
		self.enoughBalesCollected = false
		self.balesDropped = false
		self.balesInTrigger = {}
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/fendt/fendt700/fendt700.xml", 640, 0.1, 728, MathUtil.degToRad(270), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID, {
			motor = 3
		})
		self:addLoadVehicleToList(vehicles, "data/vehicles/kuhn/kuhnLSB1290D/kuhnLSB1290D.xml", 648, 0.1, 728, MathUtil.degToRad(270), true, "baler", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialBaling:loadedVehicles()
	if self.cancelLoading then
		return
	end

	local fruitId = FruitType.BARLEY

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, fruitId, FieldManager.FIELDSTATE_HARVESTED, nil, 0, false)
	end

	local fillPerBale = self.baler:getFillUnitCapacity(self.baler.spec_baler.fillUnitIndex)
	local delta = 2.4 * fillPerBale
	local fillType = FillType.STRAW

	for i = 0, 3 do
		local sx = 568
		local sy = 0
		local sz = 728 + i * 40 / 4
		local ex = sx + 63
		local ey = 0
		local ez = sz
		local radius = 0.5

		DensityMapHeightUtil.tipToGroundAroundLine(nil, delta, fillType, sx, sy, sz, ex, ey, ez, 0, radius, nil, false, nil)
	end

	for nonUpdateable, _ in pairs(g_currentMission.nonUpdateables) do
		if nonUpdateable.triggerId ~= nil and nonUpdateable.isEnabled == true and nonUpdateable.isBaleDestroyerTrigger == true then
			nonUpdateable.isEnabled = false
		end
	end

	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialBaling:update(dt)
	TutorialBaling:superClass().update(self, dt)

	if self.isRunning and self.state ~= BaseMission.STATE_FINISHED and not self.isPreparingForNextPart then
		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME, nil)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local controls = {}

			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
			table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
			self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_01, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = self.controlledVehicle == self.tractor01

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01 then
				done = self.baler:getRootVehicle() == self.tractor01
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_unfold")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				self:showTutorialMessage(self.MESSAGE_UNFOLD_BALER, controls)
			end
		end

		if not self.enoughBalesCreated then
			self.percent = math.min(g_currentMission:farmStats():getTotalValue("baleCount") / self.neededBales, 1)

			if self.percent == 1 then
				playSample(g_currentMission.missionSuccessSound, 1, 1, 0, 0, 0)
			end
		end

		if self.enoughBalesCreated then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_AUTOSTACKER, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
				self:showTutorialMessage(self.MESSAGE_ATTACH_TOOLS_02, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.autostack ~= nil then
					self.percent = math.min(1, self.autostack:getFillUnitFillLevel(self.autostack.spec_baleLoader.fillUnitIndex) / self.neededBales)
					self.enoughBalesCollected = self.percent == 1
					done = self.percent == 1
				end

				if done then
					self:createMapHotspot(self.triggerPos[1], self.triggerPos[2])
					g_currentMission:setMapTargetHotspot(self.hotspot)

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA3, nil, g_i18n:getText("action_unloadBaler")))
					self:showTutorialMessage(self.MESSAGE_UNLOAD_AUTOSTACKER, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) and self.tractor02 ~= nil then
				-- Nothing
			end
		end
	end
end

function TutorialBaling:draw()
	TutorialBaling:superClass().draw(self)

	if self.isRunning and not g_gui:getIsGuiVisible() and self.showHudMissionBase and not self:isFading() then
		self:setTutorialProgress(self.percent)

		if self.percent == 1 and not self.enoughBalesCollected then
			self.state = BaseMission.STATE_FINISHED
		end

		if self.state == BaseMission.STATE_FINISHED and not self.drawMissionEndCalled then
			self:drawMissionCompleted()

			self.drawMissionEndCalled = true
		end

		if self.state == BaseMission.STATE_FAILED and not self.drawMissionEndCalled then
			self:drawMissionFailed()

			self.drawMissionEndCalled = true
		end
	end
end

function TutorialBaling:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_baling_text_finishedAutostacking"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_baling_text_finishedBaling"), -1, nil, self.finishCurrentPart, self)

			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0
		end
	end
end

function TutorialBaling:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialBaling:loadNextVehicles()
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

	self:clearDensityParallelograms()

	if not self.enoughBalesCreated then
		self.enoughBalesCreated = true

		for i = 1, self.MESSAGE_UNFOLD_BALER do
			self:setWasTutorialMessageShown(i, true)
		end

		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/agco/weight650/weight650.xml", 636, 0.1, 728, MathUtil.degToRad(270), true, "weight02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/jcb/fastrac4220/fastrac4220.xml", 640, 0.1, 728, MathUtil.degToRad(270), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/arcusin/arcusinFSX6372/arcusinFSX6372.xml", 650, 0.4, 728, MathUtil.degToRad(270), true, "autostack", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.enoughBalesCollected then
		self.enoughBalesCollected = true
	end
end

function TutorialBaling:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)
end

function TutorialBaling:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if otherId ~= 0 then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object:isa(Bale) then
			self.balesInTrigger[object] = onEnter or onStay
		end
	end

	local balesInTriggerCount = 0

	for _, state in pairs(self.balesInTrigger) do
		if state then
			balesInTriggerCount = balesInTriggerCount + 1
		end
	end

	self.balesDropped = balesInTriggerCount == self.neededBales

	if self.balesDropped then
		self.canBeFinished = true
		self.state = BaseMission.STATE_FINISHED

		if g_currentMission.missionSuccessSound ~= nil then
			playSample(g_currentMission.missionSuccessSound, 1, 1, 0, 0, 0)
		end

		g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true, true)
	end
end
