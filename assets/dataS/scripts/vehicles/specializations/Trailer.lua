source("dataS/scripts/vehicles/specializations/events/TrailerToggleTipSideEvent.lua")

Trailer = {
	TIPSTATE_CLOSED = 0,
	TIPSTATE_OPENING = 1,
	TIPSTATE_OPEN = 2,
	TIPSTATE_CLOSING = 3,
	TIP_SIDE_NUM_BITS = 3,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onStartTipping")
		SpecializationUtil.registerEvent(vehicleType, "onStopTipping")
		SpecializationUtil.registerEvent(vehicleType, "onEndTipping")
	end
}

function Trailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadTipSide", Trailer.loadTipSide)
	SpecializationUtil.registerFunction(vehicleType, "getCanTogglePreferdTipSide", Trailer.getCanTogglePreferdTipSide)
	SpecializationUtil.registerFunction(vehicleType, "setPreferedTipSide", Trailer.setPreferedTipSide)
	SpecializationUtil.registerFunction(vehicleType, "startTipping", Trailer.startTipping)
	SpecializationUtil.registerFunction(vehicleType, "stopTipping", Trailer.stopTipping)
	SpecializationUtil.registerFunction(vehicleType, "endTipping", Trailer.endTipping)
	SpecializationUtil.registerFunction(vehicleType, "getTipState", Trailer.getTipState)
end

function Trailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Trailer.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimationPart", Trailer.loadAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "initializeAnimationPart", Trailer.initializeAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "postInitializeAnimationPart", Trailer.postInitializeAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateAnimationPart", Trailer.updateAnimationPart)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "resetAnimationPartValues", Trailer.resetAnimationPartValues)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", Trailer.getCanDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Trailer.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Trailer.getCanBeSelected)
end

function Trailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Trailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", Trailer)
end

function Trailer.initSpecialization()
	g_configurationManager:addConfigurationType("trailer", g_i18n:getText("configuration_trailer"), "trailer", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function Trailer:onLoad(savegame)
	local spec = self.spec_trailer

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.tipScrollerNodes.tipScrollerNode", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.tipRotationNodes.tipRotationNode", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.tipAnimations.tipAnimation", "vehicle.trailer.trailerConfigurations.trailerConfiguration.trailer.tipSide")

	local trailerConfigurationId = Utils.getNoNil(self.configurations.trailer, 1)
	local configKey = string.format("vehicle.trailer.trailerConfigurations.trailerConfiguration(%d).trailer", trailerConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.trailer.trailerConfigurations.trailerConfiguration", trailerConfigurationId, self.components, self)

	spec.tipSides = {}
	spec.dischargeNodeIndexToTipSide = {}
	local i = 0

	while true do
		local key = string.format("%s.tipSide(%d)", configKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadTipSide(self.xmlFile, key, entry) then
			table.insert(spec.tipSides, entry)

			spec.dischargeNodeIndexToTipSide[entry.dischargeNodeIndex] = entry
		end

		i = i + 1
	end

	spec.tipSideCount = table.getn(spec.tipSides)
	spec.preferedTipSideIndex = 1
	spec.currentTipSideIndex = nil
	spec.tipState = Trailer.TIPSTATE_CLOSED
	spec.remainingFillDelta = 0
	spec.dirtyFlag = self:getNextDirtyFlag()

	if spec.tipSideCount > 1 and savegame ~= nil then
		local tipSideIndex = getXMLInt(savegame.xmlFile, savegame.key .. ".trailer#tipSideIndex")

		if tipSideIndex ~= nil then
			self:setPreferedTipSide(tipSideIndex, true)
		end
	end
end

function Trailer:onDelete()
	if self.isClient then
		local spec = self.spec_trailer

		for _, tipSide in ipairs(spec.tipSides) do
			g_animationManager:deleteAnimations(tipSide.animationNodes)
		end
	end
end

function Trailer:onReadStream(streamId, connection)
	local spec = self.spec_trailer

	if spec.tipSideCount > 1 then
		self:setPreferedTipSide(streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS), true)
	end
end

function Trailer:onWriteStream(streamId, connection)
	local spec = self.spec_trailer

	if spec.tipSideCount > 1 then
		streamWriteUIntN(streamId, spec.preferedTipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
	end
end

function Trailer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_trailer

	if spec.tipSideCount > 1 then
		local actionEvent = spec.actionEvents[InputAction.TOGGLE_TIPSIDE]

		if actionEvent ~= nil then
			local state = self:getCanTogglePreferdTipSide()

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)

			if state then
				local text = string.format(g_i18n:getText("action_toggleTipSide"), spec.tipSides[spec.preferedTipSideIndex].name)

				g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
			end
		end
	end

	if spec.tipState == Trailer.TIPSTATE_OPENING then
		local tipSide = spec.tipSides[spec.currentTipSideIndex]

		if tipSide ~= nil then
			local animTime = self:getAnimationTime(tipSide.animation.name)

			if animTime >= 1 then
				spec.tipState = Trailer.TIPSTATE_OPEN
			end
		end
	elseif spec.tipState == Trailer.TIPSTATE_CLOSING then
		local tipSide = spec.tipSides[spec.currentTipSideIndex]

		if tipSide ~= nil then
			local animTime = self:getAnimationTime(tipSide.animation.name)

			if animTime <= 0 then
				spec.tipState = Trailer.TIPSTATE_CLOSED

				self:endTipping()
			end
		end
	end
end

function Trailer:loadTipSide(xmlFile, key, entry)
	local name = getXMLString(xmlFile, key .. "#name")
	entry.name = g_i18n:convertText(name, self.customEnvironment)

	if entry.name == nil then
		g_logManager:xmlWarning(self.configFileName, "Given tipSide name '%s' not found for '%s'!", tostring(name), key)

		return false
	end

	entry.dischargeNodeIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#dischargeNodeIndex"), 1)
	entry.canTipIfEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#canTipIfEmpty"), true)
	entry.animation = {
		name = getXMLString(xmlFile, key .. ".animation#name")
	}

	if entry.animation.name == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing animation name for '%s'!", key)

		return false
	end

	entry.animation.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".animation#speedScale"), 1)
	entry.animation.startTipTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".animation#startTipTime"), 0)
	entry.doorAnimation = {
		name = getXMLString(xmlFile, key .. ".doorAnimation#name"),
		speedScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".doorAnimation#speedScale"), 1),
		startTipTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".doorAnimation#startTipTime"), 0),
		delayedClosing = Utils.getNoNil(getXMLBool(xmlFile, key .. ".doorAnimation#delayedClosing"), false)
	}

	if self.isClient then
		entry.animationNodes = g_animationManager:loadAnimations(self.xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	end

	entry.currentEmptyFactor = 1

	return true
end

function Trailer:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_trailer

	if spec.tipSideCount > 1 then
		setXMLInt(xmlFile, key .. "#tipSideIndex", spec.preferedTipSideIndex)
	end
end

function Trailer:getCanTogglePreferdTipSide()
	local spec = self.spec_trailer

	return spec.tipState == Trailer.TIPSTATE_CLOSED and spec.tipSideCount > 0
end

function Trailer:setPreferedTipSide(index, noEventSend)
	local spec = self.spec_trailer
	index = math.max(1, math.min(spec.tipSideCount, index))

	if index ~= spec.preferedTipSideIndex and spec.tipSideCount > 1 and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(TrailerToggleTipSideEvent:new(self, index), nil, , self)
		else
			g_client:getServerConnection():sendEvent(TrailerToggleTipSideEvent:new(self, index))
		end
	end

	spec.preferedTipSideIndex = index
	local tipSide = spec.tipSides[index]

	self:setCurrentDischargeNodeIndex(tipSide.dischargeNodeIndex)
end

function Trailer:startTipping(tipSideIndex, noEventSend)
	local spec = self.spec_trailer
	local tipSide = spec.tipSides[tipSideIndex]

	if tipSide ~= nil then
		local animTime = self:getAnimationTime(tipSide.animation.name)

		self:playAnimation(tipSide.animation.name, tipSide.animation.speedScale, animTime, true)

		if tipSide.doorAnimation.name ~= nil then
			local animTime = self:getAnimationTime(tipSide.doorAnimation.name)

			self:playAnimation(tipSide.doorAnimation.name, tipSide.doorAnimation.speedScale, animTime, true)
		end

		g_animationManager:startAnimations(tipSide.animationNodes)

		spec.tipState = Trailer.TIPSTATE_OPENING
		spec.currentTipSideIndex = tipSideIndex

		self:setCurrentDischargeNodeIndex(tipSide.dischargeNodeIndex)

		spec.remainingFillDelta = 0

		SpecializationUtil.raiseEvent(self, "onStartTipping", tipSideIndex)
	end
end

function Trailer:stopTipping(noEventSend)
	local spec = self.spec_trailer
	local tipSide = spec.tipSides[spec.currentTipSideIndex]

	if tipSide ~= nil then
		local animTime = self:getAnimationTime(tipSide.animation.name)

		self:playAnimation(tipSide.animation.name, -tipSide.animation.speedScale, animTime, true)

		if tipSide.doorAnimation.name ~= nil and not tipSide.doorAnimation.delayedClosing then
			local animTime = self:getAnimationTime(tipSide.doorAnimation.name)

			self:playAnimation(tipSide.doorAnimation.name, -tipSide.doorAnimation.speedScale, animTime, true)
		end

		g_animationManager:stopAnimations(tipSide.animationNodes)

		spec.tipState = Trailer.TIPSTATE_CLOSING
		spec.remainingFillDelta = 0

		SpecializationUtil.raiseEvent(self, "onStopTipping")
	end
end

function Trailer:endTipping(noEventSend)
	local spec = self.spec_trailer
	local tipSide = spec.tipSides[spec.currentTipSideIndex]

	if tipSide ~= nil and tipSide.doorAnimation.name ~= nil and tipSide.doorAnimation.delayedClosing then
		local animTime = self:getAnimationTime(tipSide.doorAnimation.name)

		self:playAnimation(tipSide.doorAnimation.name, -tipSide.doorAnimation.speedScale, animTime, true)
	end

	spec.tipState = Trailer.TIPSTATE_CLOSED
	spec.currentTipSideIndex = nil

	SpecializationUtil.raiseEvent(self, "onEndTipping")
end

function Trailer:getTipState()
	return self.spec_trailer.tipState
end

function Trailer:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local spec = self.spec_trailer
	local tipSide = spec.dischargeNodeIndexToTipSide[dischargeNode.index]

	if tipSide ~= nil then
		if tipSide.animation.name ~= nil and tipSide.animation.startTipTime ~= 0 and self:getAnimationTime(tipSide.animation.name) < tipSide.animation.startTipTime then
			return 0
		end

		if tipSide.doorAnimation.name ~= nil and tipSide.doorAnimation.startTipTime ~= 0 and self:getAnimationTime(tipSide.doorAnimation.name) < tipSide.doorAnimation.startTipTime then
			return 0
		end

		return tipSide.currentEmptyFactor
	end

	return superFunc(self, dischargeNode)
end

function Trailer:loadAnimationPart(superFunc, xmlFile, partKey, part)
	if not superFunc(self, xmlFile, partKey, part) then
		return false
	end

	local startTipSideEmptyFactor = getXMLFloat(xmlFile, partKey .. "#startTipSideEmptyFactor")
	local endTipSideEmptyFactor = getXMLFloat(xmlFile, partKey .. "#endTipSideEmptyFactor")

	if startTipSideEmptyFactor ~= nil and endTipSideEmptyFactor ~= nil then
		part.startTipSideEmptyFactor = startTipSideEmptyFactor
		part.endTipSideEmptyFactor = endTipSideEmptyFactor
	end

	return true
end

function Trailer:initializeAnimationPart(superFunc, animation, part, i, numParts)
	superFunc(self, animation, part, i, numParts)

	if part.endTipSideEmptyFactor ~= nil then
		for j = i + 1, numParts do
			local part2 = animation.parts[j]

			if part.node == part2.node and part2.endTipSideEmptyFactor ~= nil then
				if part.startTime + part.duration > part2.startTime + 0.001 then
					g_logManager:xmlWarning(self.configFileName, "Overlapping tipSideEmptyFactor parts for node '%s' in animation '%s'", getName(part.node), animation.name)
				end

				part.nextTipSideEmptyFactorPart = part2
				part2.prevTipSideEmptyFactorPart = part

				if part2.startTipSideEmptyFactor == nil then
					part2.startTipSideEmptyFactor = {
						part.endTipSideEmptyFactor[1],
						part.endTipSideEmptyFactor[2],
						part.endTipSideEmptyFactor[3]
					}
				end

				break
			end
		end
	end
end

function Trailer:postInitializeAnimationPart(superFunc, animation, part, i, numParts)
	superFunc(self, animation, part, i, numParts)

	if part.endTipSideEmptyFactor ~= nil and part.startTipSideEmptyFactor == nil then
		part.startTipSideEmptyFactor = 0
	end
end

function Trailer:updateAnimationPart(superFunc, animation, part, durationToEnd, dtToUse, realDt)
	local spec = self.spec_trailer
	local hasPartChanged = superFunc(self, animation, part, durationToEnd, dtToUse, realDt)

	if part.startTipSideEmptyFactor ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextTipSideEmptyFactorPart, part.prevTipSideEmptyFactorPart, animation, true)) then
		local destFactor = part.endTipSideEmptyFactor

		if animation.currentSpeed < 0 then
			destFactor = part.startTipSideEmptyFactor
		end

		if part.tipSide == nil then
			local dischargeNode = self:getDischargeNodeByNode(part.node)
			local tipSide = spec.dischargeNodeIndexToTipSide[dischargeNode.index]

			if tipSide == nil then
				g_logManager:xmlWarning(self.configFileName, "Could not update discharge emptyFactor. No tipSide defined for node '%s'!", getName(part.node))

				part.startTipSideEmptyFactor = nil

				return hasPartChanged
			end

			part.tipSide = tipSide
			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedEmptyFactor = (destFactor - tipSide.currentEmptyFactor) * invDuration
		end

		local newValue = AnimatedVehicle.getMovedLimitedValue(part.tipSide.currentEmptyFactor, destFactor, part.speedEmptyFactor, dtToUse)

		if newValue then
			part.tipSide.currentEmptyFactor = newValue
			hasPartChanged = true
		end
	end

	return hasPartChanged
end

function Trailer:resetAnimationPartValues(superFunc, part)
	superFunc(self, part)

	part.tipSide = nil
end

function Trailer:getCanDischargeToGround(superFunc, dischargeNode)
	local canTip = superFunc(self, dischargeNode)

	if dischargeNode ~= nil then
		local spec = self.spec_trailer
		local tipSide = spec.dischargeNodeIndexToTipSide[dischargeNode.index]

		if tipSide ~= nil then
			local fillUnitIndex = dischargeNode.fillUnitIndex

			if not tipSide.canTipIfEmpty and self:getFillUnitFillLevel(fillUnitIndex) == 0 then
				canTip = false
			end
		end
	end

	return canTip
end

function Trailer:getIsNextCoverStateAllowed(superFunc, nextState)
	local spec = self.spec_trailer

	if spec.currentTipSideIndex ~= nil then
		local tipSide = spec.tipSides[spec.currentTipSideIndex]
		local dischargeNode = self:getDischargeNodeByIndex(tipSide.dischargeNodeIndex)
		local cover = self:getCoverByFillUnitIndex(dischargeNode.fillUnitIndex)

		if cover ~= nil and nextState ~= cover.index then
			return false
		end
	end

	return superFunc(self, nextState)
end

function Trailer:getCanBeSelected(superFunc)
	return true
end

function Trailer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_trailer

		if spec.tipSideCount < 2 then
			return
		end

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TIPSIDE, self, Trailer.actionEventToggleTipSide, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end
	end
end

function Trailer:onDischargeStateChanged(dischargState)
	local spec = self.spec_trailer

	if dischargState == Dischargeable.DISCHARGE_STATE_OFF then
		self:stopTipping()
	elseif dischargState == Dischargeable.DISCHARGE_STATE_GROUND or dischargState == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:startTipping(spec.preferedTipSideIndex, false)
	end
end

function Trailer:actionEventToggleTipSide(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_trailer

	if self:getCanTogglePreferdTipSide() then
		local tipSideIndex = spec.preferedTipSideIndex + 1

		if spec.tipSideCount < tipSideIndex then
			tipSideIndex = 1
		end

		self:setPreferedTipSide(tipSideIndex)
	end
end
