TutorialTMR = {}
local TutorialTMR_mt = Class(TutorialTMR, Tutorial)

function TutorialTMR:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialTMR:superClass():new(baseDirectory, customMt or TutorialTMR_mt, missionCollaborators)
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_feeder_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_ENTER_FRONTLOADER = self:addTutorialMessage(prefix .. "enterFrontloader")
	self.MESSAGE_LOAD_BALES = self:addTutorialMessage(prefix .. "loadBales")
	self.MESSAGE_ATTACH_SHOVEL = self:addTutorialMessage(prefix .. "attachShovel")
	self.MESSAGE_OPEN_SILO = self:addTutorialMessage(prefix .. "openSilo")
	self.MESSAGE_DISCHARGE_FORAGE = self:addTutorialMessage(prefix .. "dischargeForage")
	self.percent = 0

	return self
end

function TutorialTMR:loadMission00Finished(node, arguments)
	TutorialTMR:superClass().loadMission00Finished(self, node, arguments)

	if self.cancelLoading then
		return
	end

	g_deferredLoadingManager:addTask(function ()
		self.state = BaseMission.STATE_INTRO
		self.playerStartX = -548
		self.playerStartY = 0.1
		self.playerStartZ = 677
		self.playerRotX = MathUtil.degToRad(0)
		self.playerRotY = MathUtil.degToRad(0)
		self.playerStartIsAbsolute = false

		self:startLoadingTask()
	end)
	g_deferredLoadingManager:addTask(function ()
		self:removeAllHelpIcons()
		self:playerOwnsAllFields()
		self:addMoney(25000, 1)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.balesNode = loadI3DFile("data/maps/tutorials/TutorialTMR.i3d")

		link(getRootNode(), self.balesNode)

		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/fendt/fendt700.xml", -547.5, 0.1, 650.4, math.rad(90), true, "tractorFeeder", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/trailers/siloking/siloKingTrailedLineDuo1814.xml", -553.3, 0.1, 650.2, math.rad(90), true, "feeder", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/steerable/kramer/kramer308T.xml", -553.1, 0.1, 669, math.rad(-90), true, "frontloader", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/stoll/stollToolBaleFork.xml", -560.15, 0.1, 669, math.rad(-90), true, "balefork", self)
		self:addLoadVehicleToList(vehicles, "data/vehicles/tools/stoll/stollToolShovel.xml", -538.9, 0.1, 668.1, math.rad(90), true, "shovel", self)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)
	end)
end

function TutorialTMR:loadedVehicles()
	if self.cancelLoading then
		return
	end

	self.tractorFeeder:attachImplement(self.feeder, 1, 3)

	local husbandry = g_currentMission:getHusbandryByAnimalType("COW")

	if husbandry ~= nil then
		husbandry:addAnimals(50, 0)
	end

	local tg = getChildAt(self.balesNode, 0)

	if tg ~= 0 then
		for i = 0, 1 do
			local j = i % 2
			local id = getChildAt(tg, j)
			local x, y, z = getWorldTranslation(id)
			local xr, yr, zr = getWorldRotation(id)
			local baleObject = Bale:new(self:getIsServer(), self:getIsClient())

			if j == 0 then
				baleObject:load("data/objects/roundbales/roundbaleHay_w112_d130.i3d", x, y + 1.5 + i, z, xr, yr + math.pi / 2, zr)
			else
				baleObject:load("data/objects/roundbales/roundbaleStraw_w112_d130.i3d", x, y + 1.5 + i, z, xr, yr + math.pi / 2, zr)
			end

			baleObject:register()
			baleObject:setFillLevel(4000)

			self.baleFillLevel = 4000
		end
	end

	self.state = BaseMission.STATE_RUNNING

	self:finishLoadingTask()
end

function TutorialTMR:update(dt)
	TutorialTMR:superClass().update(self, dt)

	if self.cowSilo == nil then
		for _, object in pairs(self.nodeToObject) do
			if object.isTutorialSilo ~= nil and object.isTutorialSilo == true then
				self.cowSilo = object
			end
		end
	end

	if self.cowSilo ~= nil and not self.hasDroppedTarp then
		local x0, y0, z0 = getWorldTranslation(self.cowSilo.bunkerSiloArea.start)
		local x1, y1, z1 = getWorldTranslation(self.cowSilo.bunkerSiloArea.width)
		local x2, y2, z2 = getWorldTranslation(self.cowSilo.bunkerSiloArea.height)
		local dirHx = x2 - x0
		local dirHy = y2 - y0
		local dirHz = z2 - z0
		local dirWx = x1 - x0
		local dirWy = y1 - y0
		local dirWz = z1 - z0
		local sx = x0 + dirWx * 0.5 + dirHx * 0.25
		local sy = y0 + dirWy * 0.5 + dirHy * 0.25
		local sz = z0 + dirWz * 0.5 + dirHz * 0.25
		local ex = x0 + dirWx * 0.5 + dirHx * 0.75
		local ey = y0 + dirWy * 0.5 + dirHy * 0.75
		local ez = z0 + dirWz * 0.5 + dirHz * 0.75
		local dropped = DensityMapHeightUtil.tipToGroundAroundLine(nil, 740000, FillType.CHAFF, sx, sy + 4, sz, ex, ey + 4, ez, 0, 4, nil, false, nil)
		self.hasDroppedTarp = dropped > 0
		local id = g_currentMission.terrainDetailHeightId
		local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(FillType.CHAFF)
		local dmodHeight = DensityMapModifier:new(id, getDensityMapHeightFirstChannel(id), getDensityMapHeightNumChannels(id))

		dmodHeight:setParallelogramWorldCoords(x0, z0, x1, z1, x2 + dirHz, z2 + dirHz, "ppp")

		local heightFilter = DensityMapFilter:new(dmodHeight)

		heightFilter:setValueCompareParams("greater", (2^heightNumChannels - 1) / 2)

		local typeFilter = DensityMapFilter:new(id, g_currentMission.terrainDetailHeightTypeFirstChannel, g_currentMission.terrainDetailHeightTypeNumChannels)

		typeFilter:setValueCompareParams("equal", heightType.index)
		dmodHeight:executeSet((2^heightNumChannels - 1) / 2, heightFilter, typeFilter)

		if self.hasDroppedTarp then
			self.cowSilo:setState(BunkerSilo.STATE_CLOSED)
			self.cowSilo:updateTick(dt)

			self.cowSilo.fermentingTime = self.cowSilo.fermentingDuration
			self.cowSilo.fermentingPercent = 100
			self.cowSilo.compactedFillLevel = self.cowSilo.fillLevel
			self.cowSilo.compactedPercent = 100

			self.cowSilo:setState(BunkerSilo.STATE_FERMENTED)
		end
	end

	if self.isRunning and self.feeder ~= nil then
		local flStraw = 0
		local flGrass = 0
		local flSilage = 0

		for _, ft in pairs(self.feeder.mixerWagonFillTypes) do
			if ft.fillLevel > 0 then
				if ft.name == "dryGrass" then
					flGrass = ft.fillLevel
				elseif ft.name == "silage" then
					flSilage = ft.fillLevel
				elseif ft.name == "straw" then
					flStraw = ft.fillLevel
				end
			end
		end

		if flSilage > 0 and (flStraw == 0 or flGrass == 0) then
			self.canBeFinished = true
			self.state = BaseMission.STATE_FAILED

			return
		end

		local messageId = 1

		if not self:getWasTutorialMessageShown(messageId) then
			self:showTutorialMessage(self.MESSAGE_WELCOME, nil)
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

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.frontloader and self.balefork:getRootVehicle() == self.frontloader then
				done = true
			end

			if done then
				local controls = {}

				self:showTutorialMessage(self.MESSAGE_LOAD_BALES, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if flStraw > 0 and flGrass > 0 then
				done = true
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ATTACH, nil, g_i18n:getText("input_ATTACH")))
				self:showTutorialMessage(self.MESSAGE_ATTACH_SHOVEL, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.frontloader and self.shovel:getRootVehicle() == self.frontloader then
				done = true
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, g_i18n:getText("action_openSilo")))
				self:showTutorialMessage(self.MESSAGE_OPEN_SILO, controls)
			end
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false
			done = flSilage > 0 and self.feeder:getFillLevel() == self.feeder:getCapacity()

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.TOGGLE_TIPSTATE, nil, g_i18n:getText("action_toggleTipState")))
				self:showTutorialMessage(self.MESSAGE_DISCHARGE_FORAGE, controls)
			end
		end

		self.canBeFinished = true
		self.state = BaseMission.STATE_FINISHED
	end
end

function TutorialTMR:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_feeder_text_finished"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		else
			g_currentMission.inGameMessage:showMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_feeder_text_partlyDone"), -1, nil, self.onPartlyDoneCallback, self)

			self.percent = 0
			self.densityId = 0
			self.currentDensity = 0
		end
	end
end
