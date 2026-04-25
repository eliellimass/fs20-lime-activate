source("dataS/scripts/vehicles/specializations/events/AIVehicleIsBlockedEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIVehicleSetStartedEvent.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategy.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyBaler.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCollision.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCombine.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyStraight.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyConveyor.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategy.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyDefault.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb1.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb2.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb3.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyHalfCircle.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyDefaultReverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb1Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb2Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb3Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyHalfCircleReverse.lua")

AIVehicle = {
	TRAFFIC_COLLISION_BOX_FILENAME = "$data/shared/ai/trafficCollision.i3d",
	TRAFFIC_COLLISION = 0,
	NUM_BITS_REASONS = 4,
	STOP_REASON_USER = 1,
	STOP_REASON_REGULAR = 2,
	STOP_REASON_UNKOWN = 3,
	STOP_REASON_OUT_OF_FUEL = 4,
	STOP_REASON_OUT_OF_FILL = 5,
	STOP_REASON_BLOCKED_BY_OBJECT = 6,
	STOP_REASON_GRAINTANK_IS_FULL = 7,
	STOP_REASON_FIELD_NOT_OWNED = 8,
	STOP_REASON_IMPLEMENT_WRONG_WAY = 9,
	STOP_REASON_OUT_OF_MONEY = 10,
	REASON_TEXT_MAPPING = {}
}
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_USER] = "ingameNotification_aiVehicleReasonUser"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_REGULAR] = "ingameNotification_aiVehicleReasonRegular"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_UNKOWN] = "ingameNotification_aiVehicleReasonUnkown"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_OUT_OF_FUEL] = "ingameNotification_aiVehicleReasonOutOfFuel"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_OUT_OF_FILL] = "ingameNotification_aiVehicleReasonOutOfFill"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_BLOCKED_BY_OBJECT] = "ingameNotification_aiVehicleReasonBlockedByObject"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_GRAINTANK_IS_FULL] = "ingameNotification_aiVehicleReasonGrainTankIsFull"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_FIELD_NOT_OWNED] = "ingameNotification_aiVehicleReasonFieldNotOwned"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_IMPLEMENT_WRONG_WAY] = "ingameNotification_aiVehicleReasonImplementWrongWay"
AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_OUT_OF_MONEY] = "ingameNotification_aiVehicleReasonOutOfMoney"
AIVehicle.WARNING_TOO_MANY_WORKERS_ACTIVE = "warning_tooManyWorkersActive"
AIVehicle.numHirablesHired = 0
AIVehicle.hiredHirables = {}
AIVehicle.aiUpdateLowFrequencyDelay = 4
AIVehicle.aiUpdateDelay = 2
AIVehicle.aiUpdateDelayLowFps = 1

function AIVehicle.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function AIVehicle.initSpecialization()
	Vehicle.registerStateChange("AI_START_LINE")
	Vehicle.registerStateChange("AI_END_LINE")

	local collisionRoot = g_i3DManager:loadSharedI3DFile(AIVehicle.TRAFFIC_COLLISION_BOX_FILENAME, "", false, true, false)

	if collisionRoot ~= nil and collisionRoot ~= 0 then
		local collision = getChildAt(collisionRoot, 0)

		link(getRootNode(), collision)

		AIVehicle.TRAFFIC_COLLISION = collision

		delete(collisionRoot)
	end
end

function AIVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIEnd")
	SpecializationUtil.registerEvent(vehicleType, "onAIStartTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAITurnProgress")
	SpecializationUtil.registerEvent(vehicleType, "onAIEndTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIContinue")
end

function AIVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartAIVehicle", AIVehicle.getCanStartAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAIVehicle", AIVehicle.getCanToggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIVehicleContinueWork", AIVehicle.getCanAIVehicleContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "registerAITask", AIVehicle.registerAITask)
	SpecializationUtil.registerFunction(vehicleType, "registerSecureAITask", AIVehicle.registerSecureAITask)
	SpecializationUtil.registerFunction(vehicleType, "toggleAIVehicle", AIVehicle.toggleAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "startAIVehicle", AIVehicle.startAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "stopAIVehicle", AIVehicle.stopAIVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentHelper", AIVehicle.getCurrentHelper)
	SpecializationUtil.registerFunction(vehicleType, "updateAI", AIVehicle.updateAI)
	SpecializationUtil.registerFunction(vehicleType, "updateAILowFrequency", AIVehicle.updateAILowFrequency)
	SpecializationUtil.registerFunction(vehicleType, "getAICollisionTriggers", AIVehicle.getAICollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleDirectionNode", AIVehicle.getAIVehicleDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleSteeringNode", AIVehicle.getAIVehicleSteeringNode)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleReverserNode", AIVehicle.getAIVehicleReverserNode)
	SpecializationUtil.registerFunction(vehicleType, "getAISteeringSpeed", AIVehicle.getAISteeringSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionSnapAngle", AIVehicle.getDirectionSnapAngle)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsTrafficCollisionBox", AIVehicle.getAINeedsTrafficCollisionBox)
	SpecializationUtil.registerFunction(vehicleType, "updateAIImplementData", AIVehicle.updateAIImplementData)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedAIImplements", AIVehicle.getAttachedAIImplements)
	SpecializationUtil.registerFunction(vehicleType, "getAIDidNotMoveTimeout", AIVehicle.getAIDidNotMoveTimeout)
	SpecializationUtil.registerFunction(vehicleType, "updateAIDriveStrategies", AIVehicle.updateAIDriveStrategies)
	SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotVisibility", AIVehicle.setAIMapHotspotVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setAIMapHotspotBlinking", AIVehicle.setAIMapHotspotBlinking)
	SpecializationUtil.registerFunction(vehicleType, "getAIIsTurning", AIVehicle.getAIIsTurning)
	SpecializationUtil.registerFunction(vehicleType, "getAILastAllowedToDrive", AIVehicle.getAILastAllowedToDrive)
	SpecializationUtil.registerFunction(vehicleType, "aiStartTurn", AIVehicle.aiStartTurn)
	SpecializationUtil.registerFunction(vehicleType, "aiTurnProgress", AIVehicle.aiTurnProgress)
	SpecializationUtil.registerFunction(vehicleType, "aiEndTurn", AIVehicle.aiEndTurn)
	SpecializationUtil.registerFunction(vehicleType, "aiBlock", AIVehicle.aiBlock)
	SpecializationUtil.registerFunction(vehicleType, "aiContinue", AIVehicle.aiContinue)
	SpecializationUtil.registerFunction(vehicleType, "raiseAIEvent", AIVehicle.raiseAIEvent)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugTexts", AIVehicle.clearAIDebugTexts)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugText", AIVehicle.addAIDebugText)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugLines", AIVehicle.clearAIDebugLines)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugLine", AIVehicle.addAIDebugLine)
end

function AIVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIActive", AIVehicle.getIsAIActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", AIVehicle.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVehicleControlledByPlayer", AIVehicle.getIsVehicleControlledByPlayer)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStopMotorOnLeave", AIVehicle.getStopMotorOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDisableVehicleCharacterOnLeave", AIVehicle.getDisableVehicleCharacterOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIVehicle.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", AIVehicle.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", AIVehicle.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", AIVehicle.getIsActive)
end

function AIVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", AIVehicle)
end

function AIVehicle:onLoad(savegame)
	local spec = self.spec_aiVehicle
	spec.aiSteeringSpeed = Utils.getNoNil(getXMLFloat(spec.xmlFile, "vehicle.ai.steeringSpeed"), 1) * 0.001
	spec.isActive = false
	spec.aiImplementList = {}
	spec.aiImplementDataDirtyFlag = true
	spec.aiDriveParams = {
		valid = false
	}
	spec.aiUpdateLowFrequencyDt = 0
	spec.aiUpdateDt = 0
	spec.taskList = {}
	spec.driveStrategies = {}
	spec.didNotMoveTimeout = Utils.getNoNil(getXMLFloat(spec.xmlFile, "vehicle.ai.didNotMoveTimeout#value"), 5000)

	if getXMLBool(spec.xmlFile, "vehicle.ai.didNotMoveTimeout#deactivated") then
		spec.didNotMoveTimeout = math.huge
	end

	spec.didNotMoveTimer = spec.didNotMoveTimeout
	spec.debugTexts = {}
	spec.debugLines = {}
	spec.aiTrafficCollision = nil
	spec.aiTrafficCollisionRemoveDelay = 0
	spec.aiTrafficCollisionTranslation = {
		0,
		0,
		20
	}
	spec.pricePerMS = Utils.getNoNil(getXMLFloat(spec.xmlFile, "vehicle.ai.pricePerHour"), 2000) / 60 / 60 / 1000
	spec.steeringNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.ai.steeringNode#node"), self.i3dMappings)
	spec.reverserNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.ai.reverserNode#node"), self.i3dMappings)
end

function AIVehicle:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local helperIndex = streamReadUInt8(streamId)
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

		self:startAIVehicle(helperIndex, true, farmId)
	end
end

function AIVehicle:onWriteStream(streamId, connection)
	local spec = self.spec_aiVehicle

	if streamWriteBool(streamId, self:getIsAIActive()) then
		streamWriteUInt8(streamId, spec.currentHelper.index)
		streamWriteUIntN(streamId, spec.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
end

function AIVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiVehicle

	if VehicleDebug.state == VehicleDebug.DEBUG_AI and self:getIsActiveForInput(true, true) then
		if #spec.debugTexts > 0 then
			for i, text in pairs(spec.debugTexts) do
				renderText(0.7, 0.92 - 0.02 * i, 0.02, text)
			end
		end

		if #spec.debugLines > 0 then
			for _, l in pairs(spec.debugLines) do
				drawDebugLine(l.s[1], l.s[2], l.s[3], l.c[1], l.c[2], l.c[3], l.e[1], l.e[2], l.e[3], l.c[1], l.c[2], l.c[3])
			end
		end
	end

	if spec.aiImplementDataDirtyFlag then
		spec.aiImplementDataDirtyFlag = false

		self:updateAIImplementData()
	end

	if self.isServer and self:getIsAIActive() then
		if spec.driveStrategies ~= nil then
			for i = 1, #spec.driveStrategies do
				local driveStrategy = spec.driveStrategies[i]

				driveStrategy:update(dt)
			end
		end

		local hirableIndex = 0

		for hirable in pairs(AIVehicle.hiredHirables) do
			if self == hirable then
				break
			end

			hirableIndex = hirableIndex + 1
		end

		spec.aiUpdateLowFrequencyDt = spec.aiUpdateLowFrequencyDt + dt

		if (g_updateLoopIndex + hirableIndex) % AIVehicle.aiUpdateLowFrequencyDelay == 0 then
			self:updateAILowFrequency(spec.aiUpdateLowFrequencyDt)

			spec.aiUpdateLowFrequencyDt = 0
		end

		spec.aiUpdateDt = spec.aiUpdateDt + dt
		local aiUpdateDelay = dt > 25 and AIVehicle.aiUpdateDelayLowFps or AIVehicle.aiUpdateDelay

		if (g_updateLoopIndex + hirableIndex) % aiUpdateDelay == 0 then
			self:updateAI(spec.aiUpdateDt)

			spec.aiUpdateDt = 0
		end
	end

	if self:getIsAIActive() then
		if spec.aiTrafficCollision ~= nil and not self:getAIIsTurning() then
			local x, y, z = localToWorld(self.components[1].node, unpack(spec.aiTrafficCollisionTranslation))

			setTranslation(spec.aiTrafficCollision, x, y, z)
			setRotation(spec.aiTrafficCollision, localRotationToWorld(self.components[1].node, 0, 0, 0))
		end

		self:raiseActive()
	end
end

function AIVehicle:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiVehicle

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.TOGGLE_AI]

		if actionEvent ~= nil and self:getIsActiveForInput(true, true) and self:getCanToggleAIVehicle() then
			if self:getIsAIActive() then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_dismissEmployee"))
			else
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_hireEmployee"))
			end
		end
	end
end

function AIVehicle:updateAILowFrequency(dt)
	local spec = self.spec_aiVehicle

	self:clearAIDebugTexts()
	self:clearAIDebugLines()

	if self:getIsAIActive() then
		local difficultyMultiplier = g_currentMission.missionInfo.buyPriceMultiplier

		if GS_IS_MOBILE_VERSION then
			difficultyMultiplier = difficultyMultiplier * 0.8
		end

		local price = -dt * difficultyMultiplier * spec.pricePerMS

		if self.getLastTouchedFarmlandFarmId ~= nil and self:getLastTouchedFarmlandFarmId() == 0 then
			price = price * MissionManager.AI_PRICE_MULTIPLIER
		end

		g_currentMission:addMoney(price, spec.startedFarmId, MoneyType.AI, true)

		local farm = g_farmManager:getFarmById(spec.startedFarmId)

		if farm ~= nil and farm:getBalance() + price < 0 then
			self:stopAIVehicle(AIVehicle.STOP_REASON_OUT_OF_MONEY)
		end

		if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
			local vX, vY, vZ = getWorldTranslation(self:getAIVehicleSteeringNode())
			local tX, tZ, moveForwards, maxSpeedStra, maxSpeed, distanceToStop = nil

			for i = 1, #spec.driveStrategies do
				local driveStrategy = spec.driveStrategies[i]
				tX, tZ, moveForwards, maxSpeedStra, distanceToStop = driveStrategy:getDriveData(dt, vX, vY, vZ)
				maxSpeed = math.min(maxSpeedStra or math.huge, maxSpeed or math.huge)

				if tX ~= nil or not self:getIsAIActive() then
					break
				end
			end

			if tX == nil and self:getIsAIActive() then
				self:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)
			end

			if not self:getIsAIActive() then
				return
			end

			local minimumSpeed = 5
			local lookAheadDistance = 5
			local distSpeed = math.max(minimumSpeed, maxSpeed * math.min(1, distanceToStop / lookAheadDistance))
			local speedLimit, _ = self:getSpeedLimit()
			maxSpeed = math.min(maxSpeed, distSpeed, speedLimit)
			maxSpeed = math.min(maxSpeed, self:getCruiseControlMaxSpeed())
			local isAllowedToDrive = maxSpeed ~= 0
			spec.aiDriveParams.moveForwards = moveForwards
			spec.aiDriveParams.tX = tX
			spec.aiDriveParams.tY = vY
			spec.aiDriveParams.tZ = tZ
			spec.aiDriveParams.maxSpeed = maxSpeed
			spec.aiDriveParams.valid = true
			spec.lastAllowedToDrive = isAllowedToDrive

			if isAllowedToDrive and self:getLastSpeed() < 0.5 then
				spec.didNotMoveTimer = spec.didNotMoveTimer - dt
			else
				spec.didNotMoveTimer = spec.didNotMoveTimeout
			end

			if spec.didNotMoveTimer < 0 then
				self:stopAIVehicle(AIVehicle.STOP_REASON_BLOCKED_BY_OBJECT)
			end
		end

		if #spec.taskList > 0 then
			for i, task in pairs(spec.taskList) do
				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					self:addAIDebugText(string.format("AI TASK: %d - %s", i, task.getFunc))
				end

				if task.getObject ~= nil then
					if task.getObject[task.getFunc](task.getObject, unpack(task.getParams)) then
						task.setObject[task.setFunc](task.setObject, unpack(task.setParams))

						spec.taskList[i] = nil
					end
				else
					task.setObject[task.setFunc](task.setObject, unpack(task.setParams))

					spec.taskList[i] = nil
				end
			end
		end

		self:raiseAIEvent("onAIActive", "onAIImplementActive")
	elseif spec.aiTrafficCollisionRemoveDelay > 0 then
		spec.aiTrafficCollisionRemoveDelay = spec.aiTrafficCollisionRemoveDelay - dt

		if spec.aiTrafficCollisionRemoveDelay <= 0 then
			if spec.aiTrafficCollision ~= nil then
				if entityExists(spec.aiTrafficCollision) then
					delete(spec.aiTrafficCollision)
				end

				spec.aiTrafficCollision = nil
			end

			spec.aiTrafficCollisionRemoveDelay = 0
		end
	end
end

function AIVehicle:updateAI(dt)
	local spec = self.spec_aiVehicle

	if spec.aiDriveParams.valid then
		local moveForwards = spec.aiDriveParams.moveForwards
		local tX = spec.aiDriveParams.tX
		local tY = spec.aiDriveParams.tY
		local tZ = spec.aiDriveParams.tZ
		local maxSpeed = spec.aiDriveParams.maxSpeed
		local pX, _, pZ = worldToLocal(self:getAIVehicleSteeringNode(), tX, tY, tZ)

		if not moveForwards and self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.aiRevereserNode ~= nil then
			pX, _, pZ = worldToLocal(self.spec_articulatedAxis.aiRevereserNode, tX, tY, tZ)
		end

		if not moveForwards and self:getAIVehicleReverserNode() ~= nil then
			pX, _, pZ = worldToLocal(self:getAIVehicleReverserNode(), tX, tY, tZ)
		end

		local acceleration = 1
		local isAllowedToDrive = maxSpeed ~= 0

		AIVehicleUtil.driveToPoint(self, dt, acceleration, isAllowedToDrive, moveForwards, pX, pZ, maxSpeed)
	end
end

function AIVehicle:getCanStartAIVehicle()
	local spec = self.spec_aiVehicle

	if self:getAIVehicleDirectionNode() == nil then
		return false
	end

	if g_currentMission.disableAIVehicle then
		return false
	end

	if g_currentMission.maxNumHirables <= AIVehicle.numHirablesHired then
		return false, AIVehicle.WARNING_TOO_MANY_WORKERS_ACTIVE
	end

	if #spec.aiImplementList == 0 then
		return false
	end

	return true
end

function AIVehicle:getCanToggleAIVehicle()
	return self:getCanStartAIVehicle() or self:getIsAIActive()
end

function AIVehicle:getCanAIVehicleContinueWork()
	for _, implement in ipairs(self:getAttachedAIImplements()) do
		if not implement.object:getCanAIImplementContinueWork() then
			return false
		end
	end

	if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) and not self:getCanAIImplementContinueWork() then
		return false
	end

	return true
end

function AIVehicle:registerAITask(setObject, setFunc, setParams)
	local spec = self.spec_aiVehicle

	if setObject[setFunc] == nil then
		return false
	end

	table.insert(spec.taskList, {
		setObject = setObject,
		setFunc = setFunc,
		setParams = setParams
	})

	return false
end

function AIVehicle:registerSecureAITask(getObject, getFunc, getParams, setObject, setFunc, setParams)
	local spec = self.spec_aiVehicle

	if getObject[getFunc] == nil then
		return false
	end

	if setObject[setFunc] == nil then
		return false
	end

	table.insert(spec.taskList, {
		getObject = getObject,
		getFunc = getFunc,
		getParams = getParams,
		setObject = setObject,
		setFunc = setFunc,
		setParams = setParams
	})

	return false
end

function AIVehicle:toggleAIVehicle()
	if self:getIsAIActive() then
		self:stopAIVehicle(AIVehicle.STOP_REASON_USER)
	else
		local canStart, warning = self:getCanStartAIVehicle()

		if canStart then
			self:startAIVehicle(nil, false, g_currentMission.player.farmId)
		elseif warning ~= nil then
			g_currentMission:showBlinkingWarning(g_i18n:getText(warning), 5000)
		end
	end
end

function AIVehicle:startAIVehicle(helperIndex, noEventSend, startedFarmId)
	local spec = self.spec_aiVehicle

	if not self:getIsAIActive() then
		if helperIndex ~= nil then
			spec.currentHelper = g_helperManager:getHelperByIndex(helperIndex)
		else
			spec.currentHelper = g_helperManager:getRandomHelper()
		end

		g_helperManager:useHelper(spec.currentHelper)

		spec.startedFarmId = startedFarmId

		if self.isServer then
			g_farmManager:updateFarmStats(startedFarmId, "workersHired", 1)
		end

		if noEventSend == nil or noEventSend == false then
			local event = AIVehicleSetStartedEvent:new(self, nil, true, spec.currentHelper, startedFarmId)

			if g_server ~= nil then
				g_server:broadcastEvent(event, nil, , self)
			else
				g_client:getServerConnection():sendEvent(event)
			end
		end

		AIVehicle.numHirablesHired = AIVehicle.numHirablesHired + 1
		AIVehicle.hiredHirables[self] = self

		if self.setRandomVehicleCharacter ~= nil then
			self:setRandomVehicleCharacter()
		end

		local _, textSize = getNormalizedScreenValues(0, 12)
		local _, textOffsetY = getNormalizedScreenValues(0, 22)
		local width, height = getNormalizedScreenValues(30, 30)
		local mapHotspot = MapHotspot:new("helper", MapHotspot.CATEGORY_AI)

		mapHotspot:setIcon(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_HELPER, {
			0.052,
			0.1248,
			0.672,
			1
		}, nil, )
		mapHotspot:setBackground(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_HELPER, nil, , )
		mapHotspot:setIconScale(0.75)
		mapHotspot:setText(spec.currentHelper.name)
		mapHotspot:setSize(width, height)
		mapHotspot:setLinkedNode(spec.components[1].node)
		mapHotspot:setOwnerFarmId(self:getOwnerFarmId())
		mapHotspot:setTextOffset(0, textOffsetY)
		mapHotspot:setTextSize(textSize)
		mapHotspot:setTextColor({
			1,
			1,
			1,
			1
		})
		mapHotspot:setHasDetails(false)

		spec.mapAIHotspot = mapHotspot

		g_currentMission:addMapHotspot(spec.mapAIHotspot)

		local mapHotspot = self:getMapHotspot()

		if mapHotspot ~= nil then
			mapHotspot:setEnabled(false)
		end

		spec.isActive = true

		if self.isServer then
			self:updateAIImplementData()
			self:updateAIDriveStrategies()
		end

		self:raiseAIEvent("onAIStart", "onAIImplementStart")
		self:requestActionEventUpdate()

		if self:getAINeedsTrafficCollisionBox() and AIVehicle.TRAFFIC_COLLISION ~= nil and AIVehicle.TRAFFIC_COLLISION ~= 0 then
			local collision = clone(AIVehicle.TRAFFIC_COLLISION, true, false, true)
			spec.aiTrafficCollision = collision
		end
	end

	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, true, self)

	if self.isServer then
		for _, implement in pairs(self:getAttachedAIImplements()) do
			local needsAlignment, threshold = implement.object:getAINeedsRootAlignment()

			if needsAlignment then
				local yRot = Utils.getYRotationBetweenNodes(self.components[1].node, implement.object.components[1].node)

				if threshold < math.abs(yRot) then
					self:stopAIVehicle(AIVehicle.STOP_REASON_IMPLEMENT_WRONG_WAY)
				end
			end
		end
	end

	local farm = g_farmManager:getFarmById(spec.startedFarmId)

	if farm ~= nil and farm:getBalance() < 0 then
		self:stopAIVehicle(AIVehicle.STOP_REASON_OUT_OF_MONEY)
	end
end

function AIVehicle:stopAIVehicle(reason, noEventSend)
	local spec = self.spec_aiVehicle

	if self:getIsAIActive() then
		if noEventSend == nil or noEventSend == false then
			local event = AIVehicleSetStartedEvent:new(self, reason, false, nil, spec.startedFarmId)

			if g_server ~= nil then
				g_server:broadcastEvent(event, nil, , self)
			else
				g_client:getServerConnection():sendEvent(event)
			end
		end

		spec.aiDriveParams.valid = false

		if self.isClient and g_currentMission.player ~= nil and g_currentMission.player.farmId == spec.startedFarmId and reason ~= nil and reason ~= AIVehicle.STOP_REASON_USER then
			local notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL

			if reason == AIVehicle.STOP_REASON_REGULAR then
				notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
			end

			if g_currentMission.accessHandler:canPlayerAccess(self) then
				g_currentMission:addIngameNotification(notificationType, string.format(g_i18n:getText(AIVehicle.REASON_TEXT_MAPPING[reason]), spec.currentHelper.name))
			end
		end

		g_helperManager:releaseHelper(spec.currentHelper)

		spec.currentHelper = nil

		if self.isServer then
			g_farmManager:updateFarmStats(spec.startedFarmId, "workersHired", -1)
		end

		AIVehicle.numHirablesHired = math.max(AIVehicle.numHirablesHired - 1, 0)
		AIVehicle.hiredHirables[self] = nil

		if self.restoreVehicleCharacter ~= nil then
			self:restoreVehicleCharacter()
		end

		if spec.mapAIHotspot ~= nil then
			g_currentMission:removeMapHotspot(spec.mapAIHotspot)
			spec.mapAIHotspot:delete()

			spec.mapAIHotspot = nil
		end

		local mapHotspot = self:getMapHotspot()

		if mapHotspot ~= nil then
			mapHotspot:setEnabled(true)
		end

		self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)

		if self.isServer then
			WheelsUtil.updateWheelsPhysics(self, 0, spec.lastSpeedReal * spec.movingDirection, 0, true, true)

			if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
				for i = #spec.driveStrategies, 1, -1 do
					spec.driveStrategies[i]:delete()
					table.remove(spec.driveStrategies, i)
				end

				spec.driveStrategies = {}
			end
		end

		spec.isActive = false
		spec.isTurning = false

		if self:getAINeedsTrafficCollisionBox() then
			setTranslation(spec.aiTrafficCollision, 0, -1000, 0)

			spec.aiTrafficCollisionRemoveDelay = 200
		end

		if self.brake ~= nil then
			self:brake(1)
		end

		self:getRootVehicle().actionController:resetCurrentState()
		self:raiseAIEvent("onAIEnd", "onAIImplementEnd")
		self:requestActionEventUpdate()
	end

	g_messageCenter:publish(MessageType.AI_VEHICLE_STATE_CHANGE, false, self)
end

function AIVehicle:getIsAIActive(superFunc)
	return superFunc(self) or self.spec_aiVehicle.isActive
end

function AIVehicle:getCurrentHelper()
	return self.spec_aiVehicle.currentHelper
end

function AIVehicle:getAICollisionTriggers(collisionTriggers)
end

function AIVehicle:getAIVehicleDirectionNode()
	return self.components[1].node
end

function AIVehicle:getAIVehicleSteeringNode()
	return self.spec_aiVehicle.steeringNode or self:getAIVehicleDirectionNode()
end

function AIVehicle:getAIVehicleReverserNode()
	return self.spec_aiVehicle.reverserNode
end

function AIVehicle:getAISteeringSpeed()
	return self.spec_aiVehicle.aiSteeringSpeed
end

function AIVehicle:getDirectionSnapAngle()
	return 0
end

function AIVehicle:getAINeedsTrafficCollisionBox()
	return true
end

function AIVehicle:updateAIImplementData()
	local spec = self.spec_aiVehicle
	spec.aiImplementList = {}

	self:addVehicleToAIImplementList(spec.aiImplementList)
end

function AIVehicle:getAttachedAIImplements()
	return self.spec_aiVehicle.aiImplementList
end

function AIVehicle:getAIDidNotMoveTimeout()
	return self.spec_aiVehicle.didNotMoveTimeout
end

function AIVehicle:updateAIDriveStrategies()
	local spec = self.spec_aiVehicle

	if #spec.aiImplementList > 0 then
		if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
			for i = #spec.driveStrategies, 1, -1 do
				spec.driveStrategies[i]:delete()
				table.remove(spec.driveStrategies, i)
			end

			spec.driveStrategies = {}
		end

		local foundCombine = false
		local foundBaler = false

		for _, implement in pairs(spec.aiImplementList) do
			if SpecializationUtil.hasSpecialization(Combine, implement.object.specializations) then
				foundCombine = true
			end

			if SpecializationUtil.hasSpecialization(Baler, implement.object.specializations) then
				foundBaler = true
			end
		end

		foundCombine = foundCombine or SpecializationUtil.hasSpecialization(Combine, spec.specializations)

		if foundCombine then
			local driveStrategyCombine = AIDriveStrategyCombine:new()

			driveStrategyCombine:setAIVehicle(self)
			table.insert(spec.driveStrategies, driveStrategyCombine)
		end

		foundBaler = foundBaler or SpecializationUtil.hasSpecialization(Baler, spec.specializations)

		if foundBaler then
			local driveStrategyCombine = AIDriveStrategyBaler:new()

			driveStrategyCombine:setAIVehicle(self)
			table.insert(spec.driveStrategies, driveStrategyCombine)
		end

		local driveStrategyCollision = AIDriveStrategyCollision:new()
		local driveStrategyStraight = AIDriveStrategyStraight:new()

		driveStrategyCollision:setAIVehicle(self)
		driveStrategyStraight:setAIVehicle(self)
		table.insert(spec.driveStrategies, driveStrategyCollision)
		table.insert(spec.driveStrategies, driveStrategyStraight)
	end
end

function AIVehicle:setAIMapHotspotVisibility(visibility)
	local spec = self.spec_aiVehicle

	if spec.mapAIHotspot ~= nil then
		spec.mapAIHotspot.enabled = visibility
	end
end

function AIVehicle:setAIMapHotspotBlinking(isBlinking)
	local spec = self.spec_aiVehicle

	if spec.mapAIHotspot ~= nil then
		spec.mapAIHotspot:setBlinking(isBlinking)
	end
end

function AIVehicle:saveStatsToXMLFile(xmlFile, key)
	setXMLBool(xmlFile, key .. "#isAIActive", self:getIsAIActive())
end

function AIVehicle:getAIIsTurning()
	return self.spec_aiVehicle.isTurning
end

function AIVehicle:getAILastAllowedToDrive()
	return self.spec_aiVehicle.lastAllowedToDrive
end

function AIVehicle:aiStartTurn(left)
	local spec = self.spec_aiVehicle
	spec.isTurning = true

	self:raiseAIEvent("onAIStartTurn", "onAIImplementStartTurn", left)
end

function AIVehicle:aiTurnProgress(progress, left)
	self:raiseAIEvent("onAITurnProgress", "onAIImplementTurnProgress", progress, left)
end

function AIVehicle:aiEndTurn(left)
	local spec = self.spec_aiVehicle
	spec.isTurning = false

	self:raiseAIEvent("onAIEndTurn", "onAIImplementEndTurn", left)
end

function AIVehicle:aiBlock()
	self:raiseAIEvent("onAIBlock", "onAIImplementBlock")

	if self.isClient and g_currentMission.player.farmId == self.spec_aiVehicle.startedFarmId then
		local helperName = self:getCurrentHelper().name
		local text = string.format(g_i18n:getText(AIVehicle.REASON_TEXT_MAPPING[AIVehicle.STOP_REASON_BLOCKED_BY_OBJECT]), helperName)

		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
	end
end

function AIVehicle:aiContinue()
	self:raiseAIEvent("onAIContinue", "onAIImplementContinue")
end

function AIVehicle:raiseAIEvent(eventName, implementName, ...)
	for _, implement in ipairs(self:getAttachedAIImplements()) do
		if implement.object ~= self then
			SpecializationUtil.raiseEvent(implement.object, implementName, ...)
		end

		self:getRootVehicle().actionController:onAIEvent(implement.object, implementName)
	end

	if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) then
		SpecializationUtil.raiseEvent(self, implementName, ...)
	end

	SpecializationUtil.raiseEvent(self, eventName, ...)
	self:getRootVehicle().actionController:onAIEvent(self, eventName)
end

function AIVehicle:clearAIDebugTexts()
	for i = #self.spec_aiVehicle.debugTexts, 1, -1 do
		self.spec_aiVehicle.debugTexts[i] = nil
	end
end

function AIVehicle:addAIDebugText(text)
	local spec = self.spec_aiVehicle

	table.insert(spec.debugTexts, text)
end

function AIVehicle:clearAIDebugLines()
	for i = #self.spec_aiVehicle.debugLines, 1, -1 do
		self.spec_aiVehicle.debugLines[i] = nil
	end
end

function AIVehicle:addAIDebugLine(s, e, c)
	local spec = self.spec_aiVehicle

	table.insert(spec.debugLines, {
		s = s,
		e = e,
		c = c
	})
end

function AIVehicle:onEnterVehicle(isControlling)
	self:setAIMapHotspotVisibility(false)
end

function AIVehicle:onLeaveVehicle()
	self:setAIMapHotspotVisibility(true)
end

function AIVehicle:getDeactivateOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIVehicle:getIsVehicleControlledByPlayer(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIVehicle:getStopMotorOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIVehicle:getDisableVehicleCharacterOnLeave(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIVehicle:getAllowTireTracks(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIVehicle:getActiveFarm(superFunc)
	local starter = self.spec_aiVehicle.startedFarmId

	if starter ~= nil then
		return starter
	else
		return superFunc(self)
	end
end

function AIVehicle:getIsInUse(superFunc, connection)
	if self:getIsAIActive() then
		return true
	end

	return superFunc(self, connection)
end

function AIVehicle:getIsActive(superFunc)
	if self:getIsAIActive() then
		return true
	end

	return superFunc(self)
end

function AIVehicle:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH then
		local spec = self.spec_aiVehicle
		spec.aiImplementDataDirtyFlag = true
	end
end

function AIVehicle:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_aiVehicle

		self:clearActionEventsTable(spec.actionEvents)

		if self:getIsActiveForInput(true, true) and not g_isPresentationVersionAIDeactivated then
			local _, eventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI, self, AIVehicle.actionEventToggleAIState, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)
		end
	end
end

function AIVehicle:onSetBroken()
	if self:getIsAIActive() then
		self:stopAIVehicle(AIVehicle.STOP_REASON_UNKOWN)
	end
end

function AIVehicle:actionEventToggleAIState(actionName, inputValue, callbackState, isAnalog)
	if g_currentMission:getHasPlayerPermission("hireAssistant") then
		self:toggleAIVehicle()
	end
end
