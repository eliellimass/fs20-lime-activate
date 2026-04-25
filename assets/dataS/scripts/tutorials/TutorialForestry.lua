TutorialForestry = {}
local TutorialForestry_mt = Class(TutorialForestry, Tutorial)

function TutorialForestry:new(baseDirectory, customMt, missionCollaborators)
	local self = TutorialForestry:superClass():new(baseDirectory, customMr or TutorialForestry_mt, missionCollaborators)
	self.missionPercent = 0
	self.state = BaseMission.STATE_INTRO
	self.showHudMissionBase = true
	local prefix = "tutorial_forestry_text_"
	self.MESSAGE_WELCOME = self:addTutorialMessage(prefix .. "welcome")
	self.MESSAGE_ATTACH_PLANTER = self:addTutorialMessage(prefix .. "planter")
	self.MESSAGE_START_PLANTING = self:addTutorialMessage(prefix .. "startPlanting")
	self.MESSAGE_CHAINSAW = self:addTutorialMessage(prefix .. "chainsaw")
	self.MESSAGE_GET_ROTATE_CHAINSAW = self:addTutorialMessage(prefix .. "getChainsaw")
	self.MESSAGE_CHAINSAW_CUT_TREE = self:addTutorialMessage(prefix .. "chainsawCutTree")
	self.MESSAGE_CHAINSAW_CUT_TRUNK = self:addTutorialMessage(prefix .. "chainsawCutTrunk")
	self.MESSAGE_CHAINSAW_IN_TRUCK = self:addTutorialMessage(prefix .. "logInTruck")
	self.MESSAGE_HARVESTER = self:addTutorialMessage(prefix .. "harvester")
	self.MESSAGE_HARVESTER_CUT_TREE = self:addTutorialMessage(prefix .. "harvesterCutTree")
	self.MESSAGE_HARVESTER_CUT_TRUNK = self:addTutorialMessage(prefix .. "harvesterCutTrunk")
	self.MESSAGE_TRANSPORT = self:addTutorialMessage(prefix .. "transporting")
	self.MESSAGE_STABILIZERS = self:addTutorialMessage(prefix .. "unfoldStabilizers")
	self.MESSAGE_GRAB_TRUNK = self:addTutorialMessage(prefix .. "grabTrunk")
	self.MESSAGE_SELL = self:addTutorialMessage(prefix .. "sell")
	self.onWoodSellingUpdateEvent = TutorialForestry.onWoodSellingUpdateEvent
	self.knownSplitShapes = {}

	return self
end

function TutorialForestry:delete()
	self:deleteMapHotspot()

	if self.player:hasHandtoolEquipped() then
		self.player:unequipHandtool()
	end

	TutorialForestry:superClass().delete(self)
end

function TutorialForestry:loadMission00Finished(node, arguments)
	TutorialForestry:superClass().loadMission00Finished(self, node, arguments)

	if self.cancelLoading then
		return
	end

	g_deferredLoadingManager:addTask(function ()
		self.state = BaseMission.STATE_INTRO
		self.field = self:acquireField(6)
		self.playerStartX = -623
		self.playerStartY = 0
		self.playerStartZ = -55
		self.playerRotX = MathUtil.degToRad(0)
		self.playerRotY = MathUtil.degToRad(150)
		self.playerStartIsAbsolute = false

		self:startLoadingTask()
	end)
	g_deferredLoadingManager:addTask(function ()
		self:removeAllHelpIcons()
		self:playerOwnsAllFields()
		self:addMoney(25000, 1)
	end)
	g_deferredLoadingManager:addTask(function ()
		self.densityDisabled = true
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/suer/SB1000/SB1000.xml", -631.573, 0.1, -26.495, MathUtil.degToRad(45), true, "weight", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/valtra/NSeries/NSeries.xml", -633.59, 0.1, -28.494, MathUtil.degToRad(45), true, "tractor01", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/damcon/damconPL75/damconPL75.xml", -637.66, 0.1, -32.564, MathUtil.degToRad(45), true, "planter", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/objects/pallets/treeSaplingPallet/treeSaplingPallet.xml", -633.456, 0.1, -25.323, MathUtil.degToRad(-45), true, "pallet", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.loadedVehicles, self)

		local childs = self:loadI3D("data/maps/trees/treeMarker.i3d", getRootNode())
		self.markerNode = childs[1]
		self.sellingPos = {
			-711,
			77,
			131
		}
		self.neededTrees = 4
		self.chainsawToBuy = "data/firstPerson/chainsaws/jonsered/jonsered2252.xml"
	end)
end

function TutorialForestry:placeTree()
	self.treePos = {
		-641,
		74.7,
		-32
	}
	self.treePos[2] = getTerrainHeightAtWorldPos(self.terrainRootNode, self.treePos[1], self.treePos[2], self.treePos[3])
	local index = g_treePlantManager:getTreeTypeDescFromName("treeFir").index

	g_treePlantManager:plantTree(index, self.treePos[1], self.treePos[2], self.treePos[3], 0, 0, 0, 0)

	local timeDelta = 1080000000

	g_treePlantManager:updateTrees(timeDelta, timeDelta)

	self.isTreeCut = false
	self.isTrunkCut = false

	setTranslation(self.markerNode, self.treePos[1], self.treePos[2] + 2, self.treePos[3])
	setVisibility(self.markerNode, false)
end

function TutorialForestry:findTree()
	if self.initialSplitShape == nil and self.treePos ~= nil then
		local x = self.treePos[1] - 2
		local y = self.treePos[2] + 2
		local z = self.treePos[3] + 2
		local nx = 0
		local ny = 1
		local nz = 0
		local yx = 1
		local yy = 0
		local yz = 0
		local cutSizeY = 4
		local cutSizeZ = 4
		local shape, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ)

		if shape ~= nil and shape ~= 0 then
			self.initialSplitShape = shape
		end
	end
end

function TutorialForestry:loadedVehicles()
	if self.cancelLoading then
		return
	end

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, FruitType.NONE, FieldManager.FIELDSTATE_CULTIVATED, nil, 0, false, 0, 0, 0)
	end

	self:finishLoadingTask()

	self.state = BaseMission.STATE_RUNNING
end

function TutorialForestry:draw()
	TutorialForestry:superClass().draw(self)

	if self.initialSplitShape == nil and self.treePos ~= nil then
		local x = self.treePos[1] - 2
		local y = self.treePos[2] + 2
		local z = self.treePos[3] + 2
		local nx = 0
		local ny = 1
		local nz = 0
		local yx = 1
		local yy = 0
		local yz = 0
		local cutSizeY = 4
		local cutSizeZ = 4

		drawDebugLine(x, y, z, 1, 0, 0, x + nx, y + ny, z + nz, 1, 0, 0)
		drawDebugLine(x, y, z, 0, 1, 0, x + yx, y + yy, z + yz, 0, 1, 0)
	end
end

function TutorialForestry:update(dt)
	TutorialForestry:superClass().update(self, dt)
	self:findTree()

	if not self.addedUpdateEventListener and self.sellingPos ~= nil then
		self.addedUpdateEventListener = true

		for _, placeable in pairs(self.placeables) do
			if placeable:isa(WoodSellStationPlaceable) then
				local x, y, z = getWorldTranslation(placeable.woodSellTrigger)
				local dist = MathUtil.vector3Length(x - self.sellingPos[1], y - self.sellingPos[2], z - self.sellingPos[3])

				if dist < 10 then
					placeable:addUpdateEventListener(self)
				end
			end
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
			self:showTutorialMessage(self.MESSAGE_ATTACH_PLANTER, controls)
		end

		messageId = messageId + 1

		if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
			local done = false

			if self.controlledVehicle ~= nil and self.controlledVehicle == self.tractor01 then
				done = self.weight:getRootVehicle() == self.tractor01 and self.planter:getRootVehicle() == self.tractor01
			end

			if done then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.LOWER_IMPLEMENT, nil, g_i18n:getText("action_lower")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_OBJECT, nil, string.format(g_i18n:getText("action_refillOBJECT"), self.planter.typeDesc)))
				self:showTutorialMessage(self.MESSAGE_START_PLANTING, controls)
			end
		end

		if not self.plantingDone then
			self.percent = math.min(g_currentMission:farmStats():getTotalValue("plantedTreeCount") / self.neededTrees * 100, 100)
		end

		if self.plantingDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				self:showTutorialMessage(self.MESSAGE_CHAINSAW)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				if self.hotspot == nil then
					self:createMapHotspot(self.treePos[1], self.treePos[3])
					setVisibility(self.markerNode, true)
				end

				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.NEXT_HANDTOOL, nil, g_i18n:getText("action_nextHandTool")))
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_ROTATE_HANDTOOL, nil, g_i18n:getText("action_turnHandToolLeft")))
				self:showTutorialMessage(self.MESSAGE_GET_ROTATE_CHAINSAW, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local chainsaw = g_currentMission.player.baseInformation.currentHandtool

				if chainsaw ~= nil and math.abs(chainsaw.rotationZ) > 0.75 then
					g_currentMission.hud.ingameMap:toggleSize(IngameMap.STATE_MINIMAP, true)

					self.field = self:acquireField(6)
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ACTIVATE_HANDTOOL, nil, g_i18n:getText("input_ACTIVATE_HANDTOOL")))
					self:showTutorialMessage(self.MESSAGE_CHAINSAW_CUT_TREE, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false
				local chainsaw = g_currentMission.player.baseInformation.currentHandtool

				if chainsaw ~= nil and chainsaw.curSplitShape ~= nil and chainsaw.curSplitShape == self.initialSplitShape then
					self.treeSplitShapeToCheck = chainsaw.curSplitShape
				end

				if self.treeSplitShapeToCheck ~= nil and not self.isTreeCut and not entityExists(self.treeSplitShapeToCheck) then
					self.trunkSplitShapeToCheck = nil

					if table.getn(ChainsawUtil.curSplitShapes) == 2 then
						for _, curSplitShape in pairs(ChainsawUtil.curSplitShapes) do
							if entityExists(curSplitShape.shape) then
								local rigidType = getRigidBodyType(curSplitShape.shape)

								if rigidType == "Dynamic" then
									self.trunkSplitShapeToCheck = curSplitShape.shape
								end
							end
						end

						if self.trunkSplitShapeToCheck ~= nil then
							self.isTreeCut = true
							self.percent = 33
						end
					end
				end

				if not self.isTreeCut then
					local px, py, pz = getWorldTranslation(g_currentMission.player.graphicsRootNode)
					local dist = MathUtil.vector3Length(px - self.treePos[1], py - self.treePos[2], pz - self.treePos[3])

					if dist < 5 then
						setVisibility(self.markerNode, false)
					else
						setVisibility(self.markerNode, true)
					end
				else
					setVisibility(self.markerNode, false)
				end

				done = self.isTreeCut

				if done then
					self:deleteMapHotspot()
					self:showTutorialMessage(self.MESSAGE_CHAINSAW_CUT_TRUNK)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false

				if self.isTreeCut and not self.isTrunkCut and self.trunkSplitShapeToCheck ~= nil and not entityExists(self.trunkSplitShapeToCheck) then
					self.trunkSplitShapeToCheck = nil
					self.isTrunkCut = true
					self.percent = 66
				end

				done = self.isTrunkCut

				if done then
					self:showTutorialMessage(self.MESSAGE_CHAINSAW_IN_TRUCK)
				end
			end
		end

		if self.chainsawDone then
			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local controls = {}

				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
				self:showTutorialMessage(self.MESSAGE_HARVESTER, controls)
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = self.controlledVehicle ~= nil and self.controlledVehicle == self.harvester

				if done then
					g_currentMission.hud.ingameMap:toggleSize(IngameMap.STATE_MINIMAP, true)

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA, nil, g_i18n:getText("action_turnOn")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_woodHarvesterCut")))
					self:showTutorialMessage(self.MESSAGE_HARVESTER_CUT_TREE, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				if self.harvester.spec_woodHarvester.attachedSplitShape ~= nil and self.harvester.spec_woodHarvester.prevSplitShape == self.initialSplitShape then
					self.isTreeCut = true
					self.percent = 33
					self.trunkSplitShapeToCheck = self.harvester.spec_woodHarvester.attachedSplitShape
				end

				if not self.isTreeCut then
					local px, py, pz = getWorldTranslation(g_currentMission.player.graphicsRootNode)
					local dist = MathUtil.vector3Length(px - self.treePos[1], py - self.treePos[2], pz - self.treePos[3])

					if dist < 5 then
						setVisibility(self.markerNode, false)
					else
						setVisibility(self.markerNode, true)
					end
				else
					setVisibility(self.markerNode, false)
				end

				if self.isTreeCut then
					self:deleteMapHotspot()

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA3, nil, string.format(g_i18n:getText("action_woodHarvesterChangeCutLength"), 5)))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.IMPLEMENT_EXTRA2, nil, g_i18n:getText("action_woodHarvesterCut")))
					self:showTutorialMessage(self.MESSAGE_HARVESTER_CUT_TRUNK, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				if self.isTreeCut and not self.isTrunkCut and self.trunkSplitShapeToCheck ~= nil and not entityExists(self.trunkSplitShapeToCheck) then
					self.trunkSplitShapeToCheck = nil
					self.isTrunkCut = true
					self.percent = 66
				end

				if self.isTrunkCut then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.ENTER, nil, g_i18n:getText("input_ENTER")))
					self:showTutorialMessage(self.MESSAGE_TRANSPORT, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = self.controlledVehicle ~= nil and (self.controlledVehicle == self.forwarder or self.controlledVehicle == self.tractor02)

				if done then
					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.AXIS_CRANE_ARM2, nil, g_i18n:getText("action_unfoldSupportFeet")))
					self:showTutorialMessage(self.MESSAGE_STABILIZERS, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local done = false
				local spec = self.forwarder.spec_cylindered
				local tool = nil

				for _, movingTool in pairs(spec.movingTools) do
					if movingTool.axisActionIcon == "SUPPORT_ARM_TRANSLATE_Y" then
						tool = movingTool
					end
				end

				done = Cylindered.getMovingToolState(self.forwarder, tool) == 0

				if done then
					self:createMapHotspot(self.sellingPos[1], self.sellingPos[3])
					g_currentMission:setMapTargetHotspot(self.hotspot)

					local controls = {}

					table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SWITCH_IMPLEMENT, nil, g_i18n:getText("action_switchImplement")))
					self:showTutorialMessage(self.MESSAGE_GRAB_TRUNK, controls)
				end
			end

			messageId = messageId + 1

			if not self:getWasTutorialMessageShown(messageId) and self:getWasTutorialMessageShown(messageId - 1) then
				local x0, _, z0 = getWorldTranslation(self.tractor02.components[1].node)
				local dist = MathUtil.vector2Length(self.sellingPos[1] - x0, self.sellingPos[3] - z0)
				local done = dist < 8

				if done then
					local controls = {}

					self:showTutorialMessage(self.MESSAGE_SELL, controls)
				end
			end
		end
	end
end

function TutorialForestry:readyForNextPart()
	self.waitTimer = self.timeStayBlack

	if self.plantingDone and not self.chainsawDone then
		self.truck.spec_enterable.isBroken = true
	end
end

function TutorialForestry:loadNextVehicles()
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

	self.percent = 0

	if not self.plantingDone then
		self.plantingDone = true

		for i = 1, self.MESSAGE_START_PLANTING do
			self:setWasTutorialMessageShown(i, true)
		end

		self.initialSplitShape = nil

		self:placeTree()

		if self.player ~= nil and self.chainsawToBuy ~= nil then
			local farm = g_farmManager:getFarmById(self.player.farmId)

			farm:addHandTool(self.chainsawToBuy)

			self.chainsawToBuy = nil
		end

		self:disownField(6)

		self.tutorialNode = loadI3DFile("data/maps/tutorials/tutorialChainsaw.i3d")

		link(getRootNode(), self.tutorialNode)

		self.triggerPos = {
			-630,
			-35
		}
		local triggerY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.triggerPos[1], 0, self.triggerPos[2]) - 2
		self.tutorialTriggers = {}
		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/lizard/pickup1978/pickup1978.xml", -631, 0.1, -36, MathUtil.degToRad(-90), true, "truck", self, 2)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.chainsawDone then
		self.chainsawDone = true

		for i = 1, self.MESSAGE_CHAINSAW_IN_TRUCK do
			self:setWasTutorialMessageShown(i, true)
		end

		for _, trigger in ipairs(self.tutorialTriggers) do
			removeTrigger(trigger)
		end

		delete(self.tutorialNode)

		for _, shape in pairs(self.knownSplitShapes) do
			delete(shape)
		end

		self.knownSplitShapes = {}

		self:findTree()

		if self.initialSplitShape then
			if entityExists(self.initialSplitShape) then
				delete(self.initialSplitShape)
			end

			self.initialSplitShape = nil
		end

		self.initialSplitShape = nil

		self:placeTree()

		local vehicles = {}

		self:addLoadVehicleToList(vehicles, "data/vehicles/sampoRosenlew/HR46/HR46.xml", -631, 0.1, -36, MathUtil.degToRad(-90), true, "harvester", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/fendt/fendt700/fendt700.xml", -639.391, 0.1, -41.03, MathUtil.degToRad(-45), true, "tractor02", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:addLoadVehicleToList(vehicles, "data/vehicles/stepa/FHL13AK/FHL13AK.xml", -635.624, 0.1, -44.8, MathUtil.degToRad(-45), true, "forwarder", self, FarmManager.SINGLEPLAYER_FARM_ID)
		self:loadVehiclesFromList(vehicles, self.readyForNextPart, self)
	elseif not self.transportingDone then
		self.transportingDone = true
	end
end

function TutorialForestry:startNextPart()
	self.isPreparingForNextPart = false
	self.state = BaseMission.STATE_RUNNING
	self.drawMissionEndCalled = false

	self.player:lockInput(false)

	if not self.chainsawDone and self.truck ~= nil then
		local vX, vY, vZ = getWorldTranslation(self.truck.components[1].node)
		local triggerParentId = getChildAt(self.tutorialNode, 0)

		if triggerParentId ~= 0 then
			local id = getChildAt(triggerParentId, 0)

			setWorldTranslation(id, vX + 1.175, vY + 0.77, vZ + 0)
			addTrigger(id, "triggerCallback", self)
			table.insert(self.tutorialTriggers, id)
		end

		self.truck.propertyState = Vehicle.PROPERTY_STATE_NONE
	end

	if not self.transportingDone and self.tractor02 ~= nil then
		self.tractor02:attachImplement(self.forwarder, 1, 3)
	end
end

function TutorialForestry:drawMissionCompleted()
	if self.state == BaseMission.STATE_FINISHED then
		if self.canBeFinished then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_forestry_text_finished"), -1, nil, self.onEndMissionCallback, self)
			g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true)
		elseif not self.plantingDone then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_forestry_text_finishedPlanting"), -1, nil, self.finishCurrentPart, self)
		elseif not self.chainsawDone then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_forestry_text_finishedChainsaw"), -1, nil, self.finishCurrentPart, self)
		elseif not self.woodHarvesterDone then
			self.hud:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_forestry_text_finishedHarvesting"), -1, nil, self.finishCurrentPart, self)
		end
	end
end

function TutorialForestry:onWoodSellingUpdateEvent(trigger, sellValue)
	if sellValue ~= nil and sellValue > 0 then
		self.trunkSold = true
		self.percent = 100
		self.canBeFinished = true
		self.state = BaseMission.STATE_FINISHED

		if g_currentMission.missionSuccessSound ~= nil then
			playSample(g_currentMission.missionSuccessSound, 1, 1, 0, 0, 0)
		end

		g_gameSettings:setTableValue("tutorialsDone", self.missionInfo.id, true, true)
	end
end

function TutorialForestry:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if otherId ~= 0 then
		local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(otherId))

		if splitType ~= nil and splitType.pricePerLiter > 0 then
			self.percent = 100
		end
	end
end

function TutorialForestry:addKnownSplitShape(shape)
	self.knownSplitShapes[shape] = shape
end

function TutorialForestry:removeKnownSplitShape(shape)
	self.knownSplitShapes[shape] = nil
end
