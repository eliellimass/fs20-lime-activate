source("dataS/scripts/vehicles/specializations/events/PlowRotationEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowLimitToFieldEvent.lua")

Plow = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("plow", true)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Plow.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processPlowArea", Plow.processPlowArea)
	SpecializationUtil.registerFunction(vehicleType, "setRotationMax", Plow.setRotationMax)
	SpecializationUtil.registerFunction(vehicleType, "setRotationCenter", Plow.setRotationCenter)
	SpecializationUtil.registerFunction(vehicleType, "setPlowLimitToField", Plow.setPlowLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlowRotationAllowed", Plow.getIsPlowRotationAllowed)
end

function Plow.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Plow.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldMiddleAllowed", Plow.getIsFoldMiddleAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Plow.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Plow.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Plow.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Plow.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedRotatingPartDirection", Plow.getSpeedRotatingPartDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Plow.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Plow.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Plow.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Plow.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIInvertMarkersOnTurn", Plow.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Plow.getCanBeSelected)
end

function Plow.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementTurnProgress", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartAnimation", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Plow)
end

function Plow:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		print("Warning: No ground reference nodes in " .. self.configFileName)
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.rotationPart", "vehicle.plow.rotationPart")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.ploughDirectionNode#index", "vehicle.plow.directionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.rotateLeftToMax#value", "vehicle.plow.rotateLeftToMax#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.animTimeCenterPosition#value", "vehicle.plow.ai#centerPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.aiPlough#rotateEarly", "vehicle.plow.ai#rotateCompletelyHeadlandPos")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.onlyActiveWhenLowered#value", "vehicle.plow.onlyActiveWhenLowered#value")

	local spec = self.spec_plow
	spec.rotationPart = {
		turnAnimation = getXMLString(self.xmlFile, "vehicle.plow.rotationPart#turnAnimationName"),
		foldMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#foldMinLimit"), 0),
		foldMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#foldMaxLimit"), 1),
		limitFoldRotationMax = getXMLBool(self.xmlFile, "vehicle.plow.rotationPart#limitFoldRotationMax"),
		foldRotationMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#foldRotationMinLimit"), 0),
		foldRotationMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#foldRotationMaxLimit"), 1),
		rotationFoldMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#rotationFoldMinLimit"), 0),
		rotationFoldMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.rotationPart#rotationFoldMaxLimit"), 1),
		rotationAllowedIfLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.plow.rotationPart#rotationAllowedIfLowered"), true)
	}
	spec.directionNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.plow.directionNode#node"), self.i3dMappings), self.components[1].node)

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:addAITerrainDetailRequiredRange(g_currentMission.cultivatorValue, g_currentMission.cultivatorValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingValue, g_currentMission.sowingValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.sowingWidthValue, g_currentMission.sowingWidthValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
		self:addAITerrainDetailRequiredRange(g_currentMission.grassValue, g_currentMission.grassValue, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels)
	end

	spec.ai = {
		centerPosition = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.ai#centerPosition"), 0.5),
		rotateToCenterHeadlandPos = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.ai#rotateToCenterHeadlandPos"), 0.5),
		rotateCompletelyHeadlandPos = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.plow.ai#rotateCompletelyHeadlandPos"), 0.5)
	}
	spec.rotateLeftToMax = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.plow.rotateLeftToMax#value"), true)
	spec.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.plow.onlyActiveWhenLowered#value"), true)
	spec.rotationMax = false
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.lastPlowArea = 0
	spec.limitToField = true
	spec.forceLimitToField = false
	spec.wasTurnAnimationStopped = false
	spec.isWorking = false

	if self.isClient then
		spec.samples = {
			turn = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.plow.sounds", "turn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.plow.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
	end

	spec.workAreaParameters = {
		limitToField = spec.limitToField,
		forceLimitToField = spec.forceLimitToField,
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastTotalArea = 0
	}
end

function Plow:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local rotationMax = getXMLBool(savegame.xmlFile, savegame.key .. ".plow#rotationMax")

		if rotationMax ~= nil and self:getIsPlowRotationAllowed() then
			local plowTurnAnimTime = getXMLFloat(savegame.xmlFile, savegame.key .. ".plow#turnAnimTime")

			self:setRotationMax(rotationMax, true, plowTurnAnimTime)

			if self.updateCylinderedInitial ~= nil then
				self:updateCylinderedInitial(false)
			end
		end
	end
end

function Plow:onDelete()
	if self.isClient then
		local spec = self.spec_plow

		g_soundManager:deleteSamples(spec.samples)
	end
end

function Plow:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_plow

	setXMLBool(xmlFile, key .. "#rotationMax", spec.rotationMax)

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		setXMLFloat(xmlFile, key .. "#turnAnimTime", turnAnimTime)
	end
end

function Plow:onReadStream(streamId, connection)
	local spec = self.spec_plow
	local rotationMax = streamReadBool(streamId)
	local turnAnimTime = nil

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		turnAnimTime = streamReadFloat32(streamId)
	end

	self:setRotationMax(rotationMax, true, turnAnimTime)

	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(false)
	end
end

function Plow:onWriteStream(streamId, connection)
	local spec = self.spec_plow

	streamWriteBool(streamId, spec.rotationMax)

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		streamWriteFloat32(streamId, turnAnimTime)
	end
end

function Plow:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_plow
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			if not spec.forceLimitToField and g_currentMission:getHasPlayerPermission("createFields", self:getOwner()) then
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)

				if spec.limitToField then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_allowCreateFields"))
				else
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_limitToFields"))
				end
			else
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
			end
		end

		if spec.rotationPart.turnAnimation ~= nil then
			actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]

			if actionEvent ~= nil then
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsPlowRotationAllowed())
			end
		end
	end
end

function Plow:processPlowArea(workArea, dt)
	local spec = self.spec_plow
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local params = spec.workAreaParameters
	local changedArea, totalArea = FSDensityMapUtil.updatePlowArea(xs, zs, xw, zw, xh, zh, not params.limitToField, not params.limitGrassDestructionToField, params.angle)
	params.lastChangedArea = params.lastChangedArea + changedArea
	params.lastStatsArea = params.lastStatsArea + changedArea
	params.lastTotalArea = params.lastTotalArea + totalArea

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return changedArea, totalArea
end

function Plow:setRotationMax(rotationMax, noEventSend, turnAnimationTime)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlowRotationEvent:new(self, rotationMax), nil, , self)
		else
			g_client:getServerConnection():sendEvent(PlowRotationEvent:new(self, rotationMax))
		end
	end

	local spec = self.spec_plow
	spec.rotationMax = rotationMax

	if spec.rotationPart.turnAnimation ~= nil then
		if turnAnimationTime == nil then
			local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

			if spec.rotationMax then
				self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
			else
				self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
			end
		else
			self:setAnimationTime(spec.rotationPart.turnAnimation, turnAnimationTime, true)
		end
	end
end

function Plow:setRotationCenter()
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		self:setAnimationStopTime(spec.rotationPart.turnAnimation, spec.ai.centerPosition)

		local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if animTime < spec.ai.centerPosition then
			self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
		elseif spec.ai.centerPosition < animTime then
			self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
		end
	end
end

function Plow:setPlowLimitToField(plowLimitToField, noEventSend)
	local spec = self.spec_plow

	if spec.limitToField ~= plowLimitToField then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(PlowLimitToFieldEvent:new(self, plowLimitToField), nil, , self)
			else
				g_client:getServerConnection():sendEvent(PlowLimitToFieldEvent:new(self, plowLimitToField))
			end
		end

		spec.limitToField = plowLimitToField
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			local text = nil

			if spec.limitToField then
				text = g_i18n:getText("action_allowCreateFields")
			else
				text = g_i18n:getText("action_limitToFields")
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function Plow:getIsPlowRotationAllowed()
	local spec = self.spec_plow

	if self.getFoldAnimTime ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if spec.rotationPart.rotationFoldMaxLimit < foldAnimTime or foldAnimTime < spec.rotationPart.rotationFoldMinLimit then
			return false
		end
	end

	if not spec.rotationPart.rotationAllowedIfLowered and self.getIsLowered ~= nil and self:getIsLowered() then
		return false
	end

	return true
end

function Plow:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_plow

	if spec.rotationPart.limitFoldRotationMax ~= nil and spec.rotationPart.limitFoldRotationMax == spec.rotationMax then
		return false
	end

	if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
		local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
			return false
		end
	end

	if not spec.rotationPart.rotationAllowedIfLowered and self.getIsLowered ~= nil and self:getIsLowered() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Plow:getIsFoldMiddleAllowed(superFunc)
	local spec = self.spec_plow

	if spec.rotationPart.limitFoldRotationMax ~= nil and spec.rotationPart.limitFoldRotationMax == spec.rotationMax then
		return false
	end

	if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
		local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
			return false
		end
	end

	return superFunc(self)
end

function Plow:getDirtMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_plow

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Plow:getWearMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_plow

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Plow:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.disableOnTurn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disableOnTurn"), true)
	speedRotatingPart.turnAnimLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnAnimLimit"), 0)
	speedRotatingPart.turnAnimLimitSide = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#turnAnimLimitSide"), 0)
	speedRotatingPart.invertDirectionOnRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#invertDirectionOnRotation"), true)

	return true
end

function Plow:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil and speedRotatingPart.disableOnTurn then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if turnAnimTime ~= nil then
			local enabled = nil

			if speedRotatingPart.turnAnimLimitSide < 0 then
				enabled = turnAnimTime <= speedRotatingPart.turnAnimLimit
			elseif speedRotatingPart.turnAnimLimitSide > 0 then
				enabled = 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
			else
				enabled = turnAnimTime <= speedRotatingPart.turnAnimLimit or 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
			end

			if not enabled then
				return false
			end
		end
	end

	return superFunc(self, speedRotatingPart)
end

function Plow:getSpeedRotatingPartDirection(superFunc, speedRotatingPart)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if turnAnimTime > 0.5 and speedRotatingPart.invertDirectionOnRotation then
			return -1
		end
	end

	return superFunc(self, speedRotatingPart)
end

function Plow:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self.spec_plow.onlyActiveWhenLowered and self:getIsImplementChainLowered()
end

function Plow:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.PLOW
	end

	return retValue
end

function Plow.getDefaultSpeedLimit()
	return 15
end

function Plow:getIsWorkAreaActive(superFunc, workArea)
	if not superFunc(self, workArea) then
		return false
	end

	local spec = self.spec_plow

	if g_currentMission.time < spec.startActivationTime then
		return false
	end

	if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
		return false
	end

	return true
end

function Plow:getCanAIImplementContinueWork(superFunc)
	return not self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation) and superFunc(self)
end

function Plow:getAIInvertMarkersOnTurn(superFunc, turnLeft)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		if turnLeft then
			return spec.rotationMax == spec.rotateLeftToMax
		else
			return spec.rotationMax ~= spec.rotateLeftToMax
		end
	end

	return false
end

function Plow:getCanBeSelected(superFunc)
	return true
end

function Plow:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_plow

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if spec.rotationPart.turnAnimation ~= nil then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, Plow.actionEventTurn, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_turnPlow"))
			end

			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Plow.actionEventLimitToField, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end
	end
end

function Plow:onStartWorkAreaProcessing(dt)
	local spec = self.spec_plow
	spec.isWorking = false
	local limitToField = spec.limitToField or spec.forceLimitToField
	local limitGrassDestructionToField = spec.limitToField or spec.forceLimitToField

	if not g_currentMission:getHasPlayerPermission("createFields", self:getOwner(), nil, true) then
		limitToField = true
		limitGrassDestructionToField = true
	end

	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)
	spec.workAreaParameters.limitToField = limitToField
	spec.workAreaParameters.limitGrassDestructionToField = limitGrassDestructionToField
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastTotalArea = 0
end

function Plow:onEndWorkAreaProcessing(dt)
	local spec = self.spec_plow

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea

		if lastStatsArea > 0 then
			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("workedHectares", ha)
			stats:updateStats("plowedHectares", ha)
			stats:updateStats("workedTime", dt / 60000)
			stats:updateStats("plowedTime", dt / 60000)
		end
	end

	if self.isClient then
		if spec.isWorking then
			if not spec.isWorkSamplePlaying then
				g_soundManager:playSample(spec.samples.work)

				spec.isWorkSamplePlaying = true
			end
		elseif spec.isWorkSamplePlaying then
			g_soundManager:stopSample(spec.samples.work)

			spec.isWorkSamplePlaying = false
		end
	end
end

function Plow:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_plow
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout

	if spec.wasTurnAnimationStopped then
		local dir = 1

		if not spec.rotationMax then
			dir = -1
		end

		self:playAnimation(spec.rotationPart.turnAnimation, dir, self:getAnimationTime(spec.rotationPart.turnAnimation), true)

		spec.wasTurnAnimationStopped = false
	end
end

function Plow:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_plow
	spec.limitToField = true

	if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		self:stopAnimation(spec.rotationPart.turnAnimation, true)

		spec.wasTurnAnimationStopped = true
	end
end

function Plow:onDeactivate()
	if self.isClient then
		local spec = self.spec_plow

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function Plow:onAIImplementTurnProgress(progress, left)
	local spec = self.spec_plow

	if spec.ai.rotateToCenterHeadlandPos < progress and progress < spec.ai.rotateCompletelyHeadlandPos then
		self:setRotationCenter()
	elseif spec.ai.rotateCompletelyHeadlandPos < progress then
		self:setRotationMax(left)
	end
end

function Plow:onStartAnimation(animName)
	local spec = self.spec_plow

	g_soundManager:playSample(spec.samples.turn)
end

function Plow:onFinishAnimation(animName)
	local spec = self.spec_plow

	g_soundManager:stopSample(spec.samples.turn)
end

function Plow:actionEventTurn(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil and self:getIsPlowRotationAllowed() then
		self:setRotationMax(not spec.rotationMax)
	end
end

function Plow:actionEventLimitToField(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_plow

	if not spec.forceLimitToField then
		self:setPlowLimitToField(not spec.limitToField)
	end
end
