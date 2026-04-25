Tutorial = {}
local Tutorial_mt = Class(Tutorial, Mission00)

function Tutorial:new(baseDirectory, customMt, missionCollaborators)
	local self = Tutorial:superClass():new(baseDirectory, customMt or Tutorial_mt, missionCollaborators)
	self.densityId = 0
	self.densityRegions = {}
	self.densityParallelograms = {}
	self.isTutorialMission = true
	self.startDensity = 0
	self.targetDensity = 100000
	self.currentDensity = 0
	self.isLowerLimit = false
	self.numRegionsPerFrame = 1
	self.densityValue = 1
	self.densityFirstChannel = 0
	self.densityNumChannels = 1
	self.densityDisabled = false
	self.densityValueShift = 0
	self.tutorialMessages = {}
	self.endTime = 0
	self.messageShown = {}
	self.state = BaseMission.STATE_INTRO
	self.currentDensityIndex = 1
	self.percent = 0
	self.timeFadeToBlack = 500
	self.timeFadeFromBlack = 500
	self.timeStayBlack = 500
	self.disableAIVehicle = true

	if g_addTestCommands then
		addConsoleCommand("gsNextTutorialStage", "Forces next tutorial stage", "consoleCommandNextTutorialStage", self)
	end

	EconomyManager.MAX_GREAT_DEMANDS = 0

	return self
end

function Tutorial:onStartMission()
	Tutorial:superClass().onStartMission(self)

	self.densityModifier = DensityMapModifier:new(self.terrainDetailId, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
	self.showTourHint = false
end

function Tutorial:consoleCommandNextTutorialStage()
	self.state = BaseMission.STATE_FINISHED
end

function Tutorial:delete()
	Tutorial:superClass().delete(self)
	removeConsoleCommand("gsNextTutorialStage")
end

function Tutorial:load()
	Tutorial:superClass().load(self)

	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	self.percent = 0
	self.missionInfo.stopAndGoBraking = true
	self.missionInfo.automaticMotorStartEnabled = true

	g_gameSettings:setValue("showHelpIcons", false)
	self.hud:setGameInfoPartVisibility(HUD.GAME_INFO_PART.TUTORIAL)
end

function Tutorial:update(dt)
	Tutorial:superClass().update(self, dt)

	if self.state == BaseMission.STATE_INTRO and not self.controlPlayer then
		self.state = BaseMission.STATE_RUNNING
	end

	if self.isRunning then
		local menuEvent = g_inputBinding:getFirstActiveEventForActionName(InputAction.MENU)

		g_inputBinding:setActionEventTextVisibility(menuEvent.id, true)
		g_inputBinding:setActionEventText(menuEvent.id, g_i18n:getText("action_toggleBriefing"))
		g_inputBinding:setActionEventTextPriority(menuEvent.id, GS_PRIO_LOW)

		if self.state == BaseMission.STATE_RUNNING then
			if not self.densityDisabled then
				self:updateDensity()
			end

			self.missionTime = self.missionTime + dt

			if not self.densityDisabled then
				if self.isLowerLimit then
					self.percent = math.ceil(math.min((self.startDensity - self.currentDensity) / (self.startDensity - self.targetDensity), 1) * 100)
				else
					self.percent = math.ceil(math.min(self.currentDensity / (self.targetDensity - self.startDensity), 1) * 100)
				end

				if self.percent > 100 then
					self.percent = 100
				end
			end

			if self.percent == 100 then
				self.state = BaseMission.STATE_FINISHED
				self.endTime = self.time

				if g_currentMission.missionSuccessSound ~= nil then
					playSample(g_currentMission.missionSuccessSound, 1, 1, 0, 0, 0)
				end
			end
		end

		if g_currentMission ~= nil then
			for _, vehicle in pairs(g_currentMission.vehicles) do
				if vehicle.isBroken then
					self.canBeFinished = true
					self.state = BaseMission.STATE_FAILED

					break
				end
			end
		end
	end

	if self.waitTimer ~= nil then
		self.waitTimer = self.waitTimer - dt

		if self.waitTimer < 0 then
			self.waitTimer = nil

			self:fadeScreen(-1, self.timeFadeFromBlack, self.startNextPart, self)
		end
	end
end

function Tutorial:isFading()
	if self.state == BaseMission.STATE_FINISHED then
		return false
	else
		return self.hud:getIsFading()
	end
end

function Tutorial:draw()
	Tutorial:superClass().draw(self)

	if self.isRunning and not g_gui:getIsGuiVisible() and self.showHudMissionBase and not self:isFading() then
		self:setTutorialProgress(self.percent / 100)

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

function Tutorial:getIsAutoSaveSupported()
	return false
end

function Tutorial:getIsTourSupported()
	return false
end

function Tutorial:addTutorialMessage(message, shown)
	table.insert(self.tutorialMessages, {
		checked = false,
		shown = Utils.getNoNil(shown, false),
		text = message
	})

	return #self.tutorialMessages
end

function Tutorial:showTutorialMessage(messageId, controls)
	if self.messageIdToShow == nil then
		if messageId ~= nil and self.tutorialMessages[messageId] ~= nil then
			self.messageIdToShow = messageId
			self.tutorialMessages[messageId].shown = true

			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.setCruiseControlState ~= nil then
				g_currentMission.controlledVehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
			end

			if self.tutorialMessages[messageId].text ~= nil then
				self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText(self.tutorialMessages[messageId].text, g_currentMission.missionInfo.customEnvironment), -1, controls, self.tutorialMessageShown, self)
			else
				self.tutorialMessages[messageId].checked = true
			end
		else
			print(debug.traceback())
			print("Warning: MessageId '" .. tostring(messageId) .. "' not found!")
		end
	end
end

function Tutorial:tutorialMessageShown()
	if self.messageIdToShow ~= nil then
		for i = self.messageIdToShow, 1, -1 do
			self.tutorialMessages[i].checked = true
			self.tutorialMessages[i].shown = true
		end

		self.messageIdToShow = nil
	end
end

function Tutorial:getWasTutorialMessageShown(messageId)
	return messageId ~= nil and self.tutorialMessages[messageId] ~= nil and self.tutorialMessages[messageId].shown
end

function Tutorial:setWasTutorialMessageShown(messageId, value)
	if messageId ~= nil and self.tutorialMessages[messageId] ~= nil then
		self.tutorialMessages[messageId].checked = Utils.getNoNil(value, true)
		self.tutorialMessages[messageId].shown = Utils.getNoNil(value, true)
	end
end

function Tutorial:updateDensity()
	if self.densityId ~= nil and self.densityId ~= 0 then
		self.currentDensity = 0

		self.densityModifier:resetDensityMapAndChannels(self.densityId, self.densityFirstChannel, self.densityNumChannels)
		self.densityModifier:setReturnValueShift(self.densityValueShift)

		local filter = DensityMapFilter:new(self.densityModifier)

		if self.useDensityArea then
			filter:setValueCompareParams("greater", self.densityValue)
		else
			filter:setValueCompareParams("equal", self.densityValue)
		end

		for _, parallelogram in ipairs(self.densityParallelograms) do
			self.densityModifier:setParallelogramWorldCoords(parallelogram.x, parallelogram.z, parallelogram.widthX, parallelogram.widthZ, parallelogram.heightX, parallelogram.heightZ, "pvv")

			local density, pixelDensity, _ = self.densityModifier:executeGet(filter)

			if self.useDensityArea then
				self.currentDensity = self.currentDensity + pixelDensity
			else
				self.currentDensity = self.currentDensity + density
			end
		end
	end
end

function Tutorial:addDensityParallelogram(x, z, widthX, widthZ, heightX, heightZ)
	table.insert(self.densityParallelograms, {
		x = x,
		z = z,
		widthX = widthX,
		widthZ = widthZ,
		heightX = heightX,
		heightZ = heightZ
	})

	local dmod = DensityMapModifier:new(self.densityId)

	dmod:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ)

	local totalArea = dmod:executeGetArea()

	return totalArea
end

function Tutorial:clearDensityParallelograms()
	self.densityParallelograms = {}
end

function Tutorial:addFieldParallelograms()
	local totalArea = 0
	local numDimensions = getNumOfChildren(self.field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(self.field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local sx, _, sz = getWorldTranslation(dimStart)
		local wx, _, wz = getWorldTranslation(dimWidth)
		local hx, _, hz = getWorldTranslation(dimHeight)
		local area = self:addDensityParallelogram(sx, sz, wx - sx, wz - sz, hx - sx, hz - sz)
		totalArea = totalArea + area
	end

	return totalArea
end

function Tutorial:buyFarmland(id)
	g_farmlandManager:setLandOwnership(id, FarmManager.SINGLEPLAYER_FARM_ID)
end

function Tutorial:sellFarmland(id)
	g_farmlandManager:setLandOwnership(id, FarmlandManager.NO_OWNER_FARM_ID)
end

function Tutorial:finishCurrentPart()
	self:fadeScreen(1, self.timeFadeToBlack, self.loadNextVehicles, self)
end

function Tutorial:acquireField(fieldId)
	local field = g_fieldManager:getFieldByIndex(fieldId)

	if field == nil or not field.fieldMissionAllowed then
		print("Error: Could not find field for tutorial!")
	end

	self:buyFarmland(field.farmland.id)

	return field
end

function Tutorial:disownField(fieldId)
	local field = g_fieldManager:getFieldByIndex(fieldId)

	if field == nil or not field.fieldMissionAllowed then
		print("Error: Could not find field for tutorial!")
	end

	self:sellFarmland(field.farmland.id)
end

function Tutorial:getMessages()
	return self.tutorialMessages
end

function Tutorial:deleteMapHotspot()
	if self.hotspot ~= nil then
		self:removeMapHotspot(self.hotspot)
		self.hotspot:delete()

		self.hotspot = nil
	end
end

function Tutorial:createMapHotspot(x, z)
	self.hotspot = MapHotspot:new("tutorial", MapHotspot.CATEGORY_DEFAULT)

	self.hotspot:setImage(nil, MapHotspot.UV.DEFAULT_HIGHLIGHT_MARKER, {
		0.2705,
		0.6514,
		0.0802,
		1
	})
	self.hotspot:setWorldPosition(x, z)
	self.hotspot:setPersistent(true)
	self:addMapHotspot(self.hotspot)
end
