TutorialAnimals = {}
local TutorialAnimals_mt = Class(TutorialAnimals, Tutorial)

function TutorialAnimals:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialAnimals:superClass():new(baseDirectory, customMt or TutorialAnimals_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.isTutorialMission = true
	self.showHudMissionBase = true
	local prefix = "tutorial_pigs_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_ENTER_TRACTOR_01 = self:addTutorialMessage(prefix .. "enterTractor01")
	self.MESSAGE_DRIVE_TO_MARKET = self:addTutorialMessage(prefix .. "driveToLivestockMarket")
	self.MESSAGE_LOAD_PIGS = self:addTutorialMessage(prefix .. "loadPigsAtLivestockMarket")
	self.MESSAGE_DRIVE_TO_HUSBANDRY = self:addTutorialMessage(prefix .. "driveToPigHusbandry")
	self.MESSAGE_UNLOAD_PIGS = self:addTutorialMessage(prefix .. "unloadPigsAtHusbandry")
	self.MESSAGE_FINISHED_TRANSPORTING = self:addTutorialMessage(prefix .. "finishedTransporting")
	self.MESSAGE_WELCOME_02 = self:addTutorialMessage(prefix .. "welcome02")
	self.MESSAGE_ENTER_FRONTLOADER = self:addTutorialMessage(prefix .. "enterFrontloader01")
	self.MESSAGE_FEED_PIGS = self:addTutorialMessage(prefix .. "feedThePigs")
	self.MESSAGE_FINISHED_FOOD = self:addTutorialMessage(prefix .. "finishedFood")
	self.MESSAGE_WELCOME_03 = self:addTutorialMessage(prefix .. "welcome03")
	self.MESSAGE_ENTER_TRACTOR_02 = self:addTutorialMessage(prefix .. "enterTractor02")
	self.MESSAGE_DRIVE_TO_WATER = self:addTutorialMessage(prefix .. "driveToFillWaterTrigger")
	self.MESSAGE_LOAD_WATER = self:addTutorialMessage(prefix .. "loadWater")
	self.MESSAGE_FINISHED_WATER = self:addTutorialMessage(prefix .. "finishedWater")
	self.MESSAGE_WELCOME_04 = self:addTutorialMessage(prefix .. "welcome04")
	self.MESSAGE_ENTER_FRONTLOADER_02 = self:addTutorialMessage(prefix .. "enterFrontloader02")
	self.MESSAGE_PICKUP_BALE = self:addTutorialMessage(prefix .. "pickUpBale")
	self.MESSAGE_ENTER_TRACTOR_03 = self:addTutorialMessage(prefix .. "enterTractor03")
	self.MESSAGE_FINISHED_STRAW = self:addTutorialMessage(prefix .. "finishedStraw")
	self.MESSAGE_WELCOME_05 = self:addTutorialMessage(prefix .. "welcome05")
	self.MESSAGE_ENTER_FRONTLOADER_03 = self:addTutorialMessage(prefix .. "enterFrontloader03")

	return self
end

function TutorialAnimals:delete()
	if self.hotspot ~= nil then
		self.hud.ingameMap:deleteMapHotspot(self.hotspot)

		self.hotspot = nil
	end

	TutorialAnimals:superClass().delete(self)
end

function TutorialAnimals:loadMission00Finished(node, arguments)
	TutorialAnimals:superClass().loadMission00Finished(self, node, arguments)

	if self.cancelLoading then
		return
	end

	g_deferredLoadingManager:addTask(function ()
		self.state = BaseMission.STATE_INTRO
		self.playerStartX = 656
		self.playerStartY = 0.1
		self.playerStartZ = 835
		self.playerRotX = MathUtil.degToRad(0)
		self.playerRotY = MathUtil.degToRad(0)
		self.playerStartIsAbsolute = false

		self:startLoadingTask()
	end)
	g_deferredLoadingManager:addTask(function ()
		self:removeAllHelpIcons()
		self:playerOwnsAllFields()
		self:addMoney(28000, 1)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.densityId = 0
		self.densityValue = 0
		self.densityFirstChannel = 0
		self.densityNumChannels = 0
		self.pigsTransported = false
		self.haveFood = false
		self.haveWater = false
		self.haveStraw = false
		self.cleanedArea = false
		self.neededPigs = 9
		self.liveStockTriggerPosition = {
			720,
			113,
			822
		}
		self.pigPasturePosition = {
			163,
			116,
			-466.5
		}
		self.feedingTroughPosition = {
			186,
			116,
			-470
		}
		self.tipAnyHeapLine = {
			{
				195,
				116,
				-479
			},
			{
				195,
				116,
				-479
			}
		}
		self.waterFillTriggerPosition = {
			347,
			106,
			-403
		}
		self.waterTriggerPosition = {
			211,
			116,
			-434
		}
		self.strawTriggerPosition = {
			163,
			116,
			-421
		}
		local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

		if husbandry ~= nil then
			husbandry.updateMinutesInterval = math.huge
		end

		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/suer/suerSB700.xml", 665, 0.1, 822, MathUtil.degToRad(90), true, "weight01", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/jcb/jcbFastrac3000.xml", 660, 0.1, 822, MathUtil.degToRad(90), true, "tractor01", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/trailers/joskin/joskinBetimaxRDS7500.xml", 653, 0.1, 822, MathUtil.degToRad(90), true, "animalTransporter", self)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialAnimals:loadedVehicles()
	if self.cancelLoading then
		return
	end

	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialAnimals:update(dt)
	TutorialAnimals:superClass().update(self, dt)

	if self.waitTimer ~= nil then
		self.waitTimer = self.waitTimer - dt

		if self.waitTimer < 0 then
			self.waitTimer = nil

			self:fadeScreen(-1, self.timeFadeFromBlack, self.startNextPart, self)
		end
	end

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
			self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_01, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01 then
				done = self.weight01:getRootVehicle() == self.tractor01 and self.animalTransporter:getRootVehicle() == self.tractor01
			end

			if done then
				local pos = self.liveStockTriggerPosition

				self:createMapHotspot(pos[1], pos[3])
				g_currentMission:setMapTargetHotspot(self.hotspot)

				local controls = {}

				self:showTutorialMessage(self.MESSAGE_DRIVE_TO_MARKET, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			for _, object in pairs(g_currentMission.activatableObjects) do
				if object.isActivatableAdded and object.loadingVehicle ~= nil and object.loadingVehicle == self.animalTransporter then
					local x0, y0, z0 = getWorldTranslation(object.triggerId)

					if MathUtil.vector3Length(self.liveStockTriggerPosition[1] - x0, self.liveStockTriggerPosition[2] - y0, self.liveStockTriggerPosition[3] - z0) < 10 then
						done = true

						break
					end
				end
			end

			if done then
				g_currentMission:setMapTargetHotspot(nil)
			else
				g_currentMission:setMapTargetHotspot(self.hotspot)
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, g_i18n:getText("action_activateTrigger")))
				self:showTutorialMessage(self.MESSAGE_LOAD_PIGS, controls)
			end
		end

		if not self:getWasTutorialMessageShown(messageId + 1) and self:getWasTutorialMessageShown(messageId) and g_currentMission ~= nil then
			local available = g_currentMission:getMoney()
			local fillLevel = self.animalTransporter:getUnitFillLevel(self.animalTransporter.livestockTrailer.fillUnitIndex)
			local fillType = self.animalTransporter:getUnitFillType(self.animalTransporter.livestockTrailer.fillUnitIndex)

			if fillType ~= FillType.UNKNOWN then
				local animalDesc = g_animalManager:getAnimalByFillType(fillType)
				local animalSellPrice = animalDesc.price * 0.4 * g_currentMission.missionInfo.sellPriceMultiplier
				available = available + fillLevel * animalSellPrice
			end

			local boughtPigs = 0

			if fillType == FillType.PIG then
				boughtPigs = fillLevel
			end

			local animalDesc = g_animalManager:getAnimalByIndex(Animal.PIG)
			local animalBuyPrice = animalDesc.price
			local needed = (self.neededPigs - boughtPigs) * animalBuyPrice

			if available < needed then
				self.canBeFinished = true
				self.state = BaseMission.STATE_FAILED

				return
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false
			local fillLevel = self.animalTransporter:getUnitFillLevel(self.animalTransporter.livestockTrailer.fillUnitIndex)
			local fillType = self.animalTransporter:getUnitFillType(self.animalTransporter.livestockTrailer.fillUnitIndex)

			if fillLevel > 0 and fillLevel == self.neededPigs then
				if fillType == FillType.PIG then
					done = true
				else
					self.state = BaseMission.STATE_FAILED
					self.canBeFinished = true

					self:drawMissionFailed()

					self.drawMissionEndCalled = true
				end
			end

			if done then
				local pos = self.pigPasturePosition

				g_currentMission:setMapTargetHotspot(nil)
				self.ingameMap:deleteMapHotspot(self.hotspot)
				self:createMapHotspot(pos[1], pos[3])
				g_currentMission:setMapTargetHotspot(self.hotspot)

				local controls = {}

				self:showTutorialMessage(self.MESSAGE_DRIVE_TO_HUSBANDRY, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			for _, object in pairs(g_currentMission.activatableObjects) do
				if object.isActivatableAdded and object.loadingVehicle ~= nil and object.loadingVehicle == self.animalTransporter then
					local x0, y0, z0 = getWorldTranslation(object.triggerId)

					if MathUtil.vector3Length(self.pigPasturePosition[1] - x0, self.pigPasturePosition[2] - y0, self.pigPasturePosition[3] - z0) < 10 then
						done = true

						break
					end
				end
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, g_i18n:getText("action_activateTrigger")))
				self:showTutorialMessage(self.MESSAGE_UNLOAD_PIGS, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false
			local fillLevel = self.animalTransporter:getUnitFillLevel(self.animalTransporter.livestockTrailer.fillUnitIndex)

			if fillLevel == 0 then
				local numAnimals = 0
				local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

				if husbandry ~= nil then
					numAnimals = husbandry:getNumAnimals(0)
				end

				if numAnimals == self.neededPigs then
					done = true
				end
			end

			if done then
				self.ingameMap:deleteMapHotspot(self.hotspot)

				self.hotspot = nil
				self.state = BaseMission.STATE_FINISHED
			end
		end

		if self.pigsTransported then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local animalDesc = g_animalManager:getAnimalByIndex(Animal.PIG)
				local foodPerDay = animalDesc.foodPerDay

				if self.tippedFillLevels == nil or next(self.tippedFillLevels) == nil then
					self.tippedFillLevels = {}
				end

				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_02, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ENTER_FRONTLOADER, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.frontloader and self.shovel:getRootVehicle() == self.frontloader then
					done = true
				end

				if done then
					g_currentMission:setMapTargetHotspot(nil)
					self.ingameMap:deleteMapHotspot(self.hotspot)

					local pos = self.feedingTroughPosition

					self:createMapHotspot(pos[1], pos[3])
					g_currentMission:setMapTargetHotspot(self.hotspot)

					local controls = {}

					self:showTutorialMessage(self.MESSAGE_FEED_PIGS, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = true
				local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

				if husbandry ~= nil then
					for fillType, dropped in pairs(self.tippedFillLevels) do
						local enough = husbandry:getFillLevel(fillType) > 0.5 * dropped
						done = done and enough
					end
				end

				if done then
					g_currentMission:setMapTargetHotspot(nil)
					self.ingameMap:deleteMapHotspot(self.hotspot)

					self.state = BaseMission.STATE_FINISHED
				end
			end
		end

		if self.haveFood then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_03, controls)
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

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor02 and self.weight02:getRootVehicle() == self.tractor02 and self.waterTrailer:getRootVehicle() == self.tractor02 then
					done = true
				end

				if done then
					local pos = self.waterFillTriggerPosition

					self:createMapHotspot(pos[1], pos[3])
					g_currentMission:setMapTargetHotspot(self.hotspot)

					local controls = {}

					self:showTutorialMessage(self.MESSAGE_DRIVE_TO_WATER, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				for _, trigger in pairs(self.waterTrailer.waterTrailerFillTriggers) do
					local x0, y0, z0 = getWorldTranslation(trigger.triggerId)

					if MathUtil.vector3Length(self.waterFillTriggerPosition[1] - x0, self.waterFillTriggerPosition[2] - y0, self.waterFillTriggerPosition[3] - z0) < 10 then
						done = true

						break
					end
				end

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, g_i18n:getText("action_activateTrigger")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_TIPSTATE, nil, g_i18n:getText("action_toggleTipState")))
					self:showTutorialMessage(self.MESSAGE_LOAD_WATER, controls)
				end
			end

			if self:getWasTutorialMessageShown(messageId - 1) and not self.hotSpotMovedToWaterDischargeTrigger then
				local done = false
				local tool = self.waterTrailer

				if tool:getUnitCapacity(tool.waterTrailerFillUnitIndex) <= tool:getUnitFillLevel(tool.waterTrailerFillUnitIndex) then
					done = true
				end

				if done then
					local pos = self.waterTriggerPosition
					local oldHotspot = self.hotspot

					self:createMapHotspot(pos[1], pos[3])
					g_currentMission:setMapTargetHotspot(self.hotspot)
					self.ingameMap:deleteMapHotspot(oldHotspot)

					self.hotSpotMovedToWaterDischargeTrigger = true
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local inTrigger = false

				if g_currentMission.trailerTipTriggers[self.waterTrailer] ~= nil then
					local triggers = g_currentMission.trailerTipTriggers[self.waterTrailer]

					if triggers ~= nil then
						for i = 1, table.getn(triggers) do
							local x0, y0, z0 = getWorldTranslation(triggers[i].triggerId)

							if MathUtil.vector3Length(self.waterTriggerPosition[1] - x0, self.waterTriggerPosition[2] - y0, self.waterTriggerPosition[3] - z0) then
								inTrigger = true

								break
							end
						end
					end
				end

				if inTrigger then
					g_currentMission:setMapTargetHotspot(nil)
				else
					g_currentMission:setMapTargetHotspot(self.hotspot)
				end

				local done = false
				local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

				if husbandry ~= nil and not husbandry:getHasSpaceForTipping(FillType.WATER) then
					done = true
				end

				if done then
					self.ingameMap:deleteMapHotspot(self.hotspot)

					self.hotspot = nil
					self.state = BaseMission.STATE_FINISHED
				end
			end
		end

		if self.haveWater then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_04, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ENTER_FRONTLOADER_02, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.controlledVehicle ~= nil and self.controlledVehicle == self.frontloader02 and self.balefork:getRootVehicle() == self.frontloader02 then
					done = true
				end

				if done then
					local controls = {}

					self:showTutorialMessage(self.MESSAGE_PICKUP_BALE, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if next(self.strawBlower.triggeredBales) == self.bale and (self.bale.dynamicMountObject == nil or self.bale.dynamicMountObject == self.strawBlower) then
					done = true
				end

				if done then
					local pos = self.strawTriggerPosition
					local oldHotspot = self.hotspot

					self:createMapHotspot(pos[1], pos[3])
					g_currentMission:setMapTargetHotspot(self.hotspot)
					self.ingameMap:deleteMapHotspot(oldHotspot)

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_TIPSTATE, nil, g_i18n:getText("action_toggleTipState")))
					self:showTutorialMessage(self.MESSAGE_ENTER_TRACTOR_03, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local x0, y0, z0 = getWorldTranslation(self.tractor03.components[1].node)
				local dist = MathUtil.vector3Length(self.strawTriggerPosition[1] - x0, self.strawTriggerPosition[2] - y0, self.strawTriggerPosition[3] - z0)

				if dist < 10 then
					g_currentMission:setMapTargetHotspot(nil)
				else
					g_currentMission:setMapTargetHotspot(self.hotspot)
				end

				local done = false
				local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

				if husbandry ~= nil and (husbandry:getFillLevel(FillType.STRAW) == 4000 or not husbandry:getHasSpaceForTipping(FillType.STRAW)) then
					done = true
				end

				if done then
					self.ingameMap:deleteMapHotspot(self.hotspot)

					self.hotspot = nil
					self.state = BaseMission.STATE_FINISHED
				end
			end
		end

		if self.haveStraw then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_WELCOME_05, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ENTER_FRONTLOADER_03, controls)
			end

			messageId = messageId + 1
			local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) and husbandry ~= nil then
				local done = false
				local dirtLevel = husbandry:getFoodSpillageLevel()

				if dirtLevel < 1500 then
					done = true
				end

				if done then
					self.canBeFinished = true
					self.state = BaseMission.STATE_FINISHED
				end
			end
		end
	end
end

function TutorialAnimals:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			g_currentMission.inGameMessage:showMessage("", g_i18n:getText("tutorial_pigs_text_finishedCleaning"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0

			if not self.pigsTransported then
				g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_pigs_text_finishedTransporting"), -1, nil, self.finishCurrentPart, self)
				self:setWasTutorialMessageShown(self.MESSAGE_FINISHED_TRANSPORTING)
			elseif not self.haveFood then
				g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_pigs_text_finishedFood"), -1, nil, self.finishCurrentPart, self)
				self:setWasTutorialMessageShown(self.MESSAGE_FINISHED_FOOD)
			elseif not self.haveWater then
				g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_pigs_text_finishedWater"), -1, nil, self.finishCurrentPart, self)
				self:setWasTutorialMessageShown(self.MESSAGE_FINISHED_WATER)
			elseif not self.haveStraw then
				g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_pigs_text_finishedStraw"), -1, nil, self.finishCurrentPart, self)
				self:setWasTutorialMessageShown(self.MESSAGE_FINISHED_STRAW)
			elseif not self.cleanedArea then
				-- Nothing
			end
		end
	end
end

function TutorialAnimals:readyForNextPart()
	self.waitTimer = self.timeStayBlack
end

function TutorialAnimals:loadNextVehicles()
	self.isPreparingForNextPart = true

	if self.controlledVehicle ~= nil then
		self:onLeaveVehicle()
	end

	self.playerStartX = 186
	self.playerStartZ = -489
	self.playerRotY = MathUtil.degToRad(180)

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

	self:clearDensityParallelograms()

	if not self.pigsTransported then
		self.pigsTransported = true
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/kramer/kramer308T.xml", 186, 0.1, -478, MathUtil.degToRad(90), true, "frontloader", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/stoll/stollToolShovel.xml", 191, 0.1, -478, MathUtil.degToRad(90), true, "shovel", self)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.haveFood then
		self.haveFood = true
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/suer/suerSB700.xml", 190, 0.1, -478, MathUtil.degToRad(90), true, "weight02", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/newHolland/newHolland8340.xml", 186, 0.1, -478, MathUtil.degToRad(90), true, "tractor02", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/trailers/joskin/joskinAquaTrans7300.xml", 178, 0.1, -478, MathUtil.degToRad(90), true, "waterTrailer", self)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.haveWater then
		self.haveWater = true
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/kramer/kramer308T.xml", 186, 0.1, -478, MathUtil.degToRad(90), true, "frontloader02", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/stoll/stollToolBaleFork.xml", 191, 0.1, -478, MathUtil.degToRad(90), true, "balefork", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/suer/suerSB700.xml", 190, 0.1, -474, MathUtil.degToRad(90), true, "weight03", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/newHolland/newHolland8340.xml", 186, 0.1, -474, MathUtil.degToRad(90), true, "tractor03", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/trailers/kuhn/kuhnPrimor15070.xml", 178, 0.1, -474, MathUtil.degToRad(90), true, "strawBlower", self)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)

		local baleObject = Bale:new(self:getIsServer(), self:getIsClient())

		baleObject:load("data/objects/squarebales/baleStraw240.i3d", 200, 116.5, -474, 0, 0, 0, 4000)
		baleObject:register()

		self.bale = baleObject
	elseif not self.haveStraw then
		self.haveStraw = true
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/kramer/kramer308T.xml", 186, 0.1, -478, MathUtil.degToRad(90), true, "frontloader03", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/stoll/stollToolShovel.xml", 191, 0.1, -478, MathUtil.degToRad(90), true, "shovel", self)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)

		local husbandry = g_currentMission:getHusbandryByAnimalType("PIG")

		if husbandry ~= nil then
			for _, trigger in pairs(husbandry.tipTriggers) do
				trigger:updateFillPlane()
			end

			husbandry.foodToDrop = 5000

			while g_densityMapHeightManager:getMinValidLiterValue(husbandry.dirtificationFillType) < husbandry.foodToDrop do
				local foodToDrop = math.min(husbandry.foodToDrop, 20 * g_densityMapHeightManager:getMinValidLiterValue(husbandry.dirtificationFillType))
				local dropped = husbandry:updateFoodSpillage(foodToDrop)
				husbandry.foodToDrop = husbandry.foodToDrop - dropped
			end
		end
	elseif not self.cleanedArea then
		self.cleanedArea = true
	end
end

function TutorialAnimals:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)

	if self.strawBlower ~= nil then
		self.strawBlower.getCanTipToGround = Utils.overwrittenFunction(self.strawBlower.getCanTipToGround, TutorialAnimals.getCanTipToGround)
	end
end

function TutorialAnimals:getCanTipToGround()
	return false
end
