source("dataS/scripts/vehicles/specializations/events/SetCoverStateEvent.lua")

Cover = {
	SEND_NUM_BITS = 4,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function Cover.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCoverFromXML", Cover.loadCoverFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsNextCoverStateAllowed", Cover.getIsNextCoverStateAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setCoverState", Cover.setCoverState)
	SpecializationUtil.registerFunction(vehicleType, "playCoverAnimation", Cover.playCoverAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getCoverByFillUnitIndex", Cover.getCoverByFillUnitIndex)
end

function Cover.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Cover.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Cover.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPipeNodes", Cover.loadPipeNodes)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPipeStateChangeAllowed", Cover.getIsPipeStateChangeAllowed)
end

function Cover.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onAddedFillUnitTrigger", Cover)
	SpecializationUtil.registerEventListener(vehicleType, "onRemovedFillUnitTrigger", Cover)
end

function Cover.initSpecialization()
	g_configurationManager:addConfigurationType("cover", g_i18n:getText("configuration_cover"), "cover", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function Cover:onLoad(savegame)
	local spec = self.spec_cover

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cover#animationName", "vehicle.cover.coverConfigurations.coverConfiguration.cover#openAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.foldable.foldingParts#closeCoverOnFold", "vehicle.cover.coverConfigurations.coverConfiguration.cover#closeCoverIfNotAllowed")

	local coverConfigurationId = Utils.getNoNil(self.configurations.cover, 1)
	local configKey = string.format("vehicle.cover.coverConfigurations.coverConfiguration(%d)", coverConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.cover.coverConfigurations.coverConfiguration", coverConfigurationId, self.components, self)

	spec.state = 0
	spec.runningAnimations = {}
	spec.covers = {}
	spec.fillUnitIndexToCover = {}
	spec.isStateSetAutomatically = false
	local i = 0

	while true do
		local key = string.format("%s.cover(%d)", configKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local cover = {}

		if self:loadCoverFromXML(self.xmlFile, key, cover) then
			for j = #cover.fillUnitIndices, 1, -1 do
				local index = cover.fillUnitIndices[j]

				if spec.fillUnitIndexToCover[index] == nil then
					spec.fillUnitIndexToCover[index] = cover
				else
					table.remove(cover.fillUnitIndices, j)
					g_logManager:xmlWarning(self.configFileName, "FillUnit '%d' for cover '%s' is already used by another cover. Only one cover per fillUnit is allowed. Ignoring it!", i, key)
				end
			end

			table.insert(spec.covers, cover)

			cover.index = #spec.covers
		end

		i = i + 1
	end

	spec.closeCoverIfNotAllowed = Utils.getNoNil(getXMLBool(self.xmlFile, configKey .. "#closeCoverIfNotAllowed"), false)
	spec.openCoverWhileTipping = Utils.getNoNil(getXMLBool(self.xmlFile, configKey .. "#openCoverWhileTipping"), false)
	spec.hasCovers = #spec.covers > 0
	spec.isDirty = false
end

function Cover:onPostLoad(savegame)
	local spec = self.spec_cover

	if spec.hasCovers then
		local state = 0

		if savegame ~= nil then
			state = getXMLInt(savegame.xmlFile, savegame.key .. ".cover#state") or state
		end

		if state == 0 then
			spec.state = table.getn(spec.covers)
		end

		self:setCoverState(state, true)

		for i = #spec.runningAnimations, 1, -1 do
			local animation = spec.runningAnimations[i]

			AnimatedVehicle.updateAnimationByName(self, animation.name, 9999999)
			table.remove(spec.runningAnimations, i)
		end

		spec.isDirty = false
	end
end

function Cover:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_cover

	if spec.hasCovers then
		setXMLInt(xmlFile, key .. "#state", spec.state)
	end
end

function Cover:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_cover

		if spec.hasCovers then
			local state = streamReadUIntN(streamId, Cover.SEND_NUM_BITS)

			self:setCoverState(state, true)

			for i = #spec.runningAnimations, 1, -1 do
				local animation = spec.runningAnimations[i]

				AnimatedVehicle.updateAnimationByName(self, animation.name, 9999999)
				table.remove(spec.runningAnimations, i)
			end

			spec.isDirty = false
		end
	end
end

function Cover:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_cover

		if spec.hasCovers then
			streamWriteUIntN(streamId, spec.state, Cover.SEND_NUM_BITS)
		end
	end
end

function Cover:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cover

	if spec.isDirty then
		local animation = spec.runningAnimations[1]

		if animation ~= nil then
			local nextAnim = spec.runningAnimations[2]

			if nextAnim ~= nil and nextAnim.name == animation.name then
				table.remove(spec.runningAnimations, 1)
				self:stopAnimation(animation.name, true)
				self:playCoverAnimation(nextAnim)
			end

			if not self:getIsAnimationPlaying(animation.name) then
				table.remove(spec.runningAnimations, 1)

				local nextAnimation = spec.runningAnimations[1]

				if nextAnimation ~= nil then
					self:playCoverAnimation(nextAnimation)
				else
					spec.isDirty = false
				end
			end
		end
	end

	if spec.closeCoverIfNotAllowed and spec.state ~= 0 then
		local newState = spec.state + 1

		if newState > #spec.covers then
			newState = 0
		end

		if not self:getIsNextCoverStateAllowed(newState) then
			self:setCoverState(0, true)
		end
	end
end

function Cover:loadCoverFromXML(xmlFile, key, cover)
	cover.openAnimation = getXMLString(xmlFile, key .. "#openAnimation")
	cover.openAnimationStopTime = getXMLFloat(xmlFile, key .. "#openAnimationStopTime")

	if cover.openAnimation == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'openAnimation' for cover '%s'!", key)

		return false
	end

	cover.closeAnimation = getXMLString(xmlFile, key .. "#closeAnimation")
	cover.closeAnimationStopTime = getXMLFloat(xmlFile, key .. "#closeAnimationStopTime")
	cover.startOpenState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#openOnBuy"), false)
	cover.forceOpenOnTip = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceOpenOnTip"), true)
	cover.autoReactToTrigger = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoReactToTrigger"), true)
	local indices = getXMLString(xmlFile, key .. "#fillUnitIndices")

	if indices == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'fillUnitIndices' for cover '%s'!", key)

		return false
	end

	cover.fillUnitIndices = {
		StringUtil.getVectorFromString(indices)
	}
	cover.blockedToolTypes = {}
	local strBlockedToolTypes = Utils.getNoNil(getXMLString(xmlFile, key .. "#blockedToolTypes"), "dischargeable bale trigger")
	strBlockedToolTypes = StringUtil.splitString(" ", StringUtil.trim(strBlockedToolTypes))

	for _, toolType in ipairs(strBlockedToolTypes) do
		local index = g_toolTypeManager:getToolTypeIndexByName(toolType)

		if index ~= ToolType.UNDEFINED then
			cover.blockedToolTypes[index] = true
		end
	end

	return true
end

function Cover:setCoverState(state, noEventSend)
	local spec = self.spec_cover

	if spec.hasCovers and state >= 0 and state <= #spec.covers then
		SetCoverStateEvent.sendEvent(self, state, noEventSend)

		local startAnim = #spec.runningAnimations == 0

		if spec.state > 0 then
			local cover = spec.covers[spec.state]
			local animation = cover.closeAnimation
			local stopTime = cover.closeAnimationStopTime or 1

			if animation == nil then
				animation = cover.openAnimation
				stopTime = cover.openAnimationStopTime or 0
			end

			if self:getAnimationExists(animation) then
				table.insert(spec.runningAnimations, {
					name = animation,
					stopTime = stopTime
				})
			end
		end

		if state > 0 then
			local cover = spec.covers[state]

			table.insert(spec.runningAnimations, {
				name = cover.openAnimation,
				stopTime = cover.openAnimationStopTime or 1
			})
		end

		spec.state = state
		spec.isDirty = #spec.runningAnimations > 0

		if startAnim and #spec.runningAnimations > 0 then
			self:playCoverAnimation(spec.runningAnimations[1])
		end

		Cover.updateActionText(self)
	end
end

function Cover:playCoverAnimation(animation)
	local dir = MathUtil.sign(animation.stopTime - self:getAnimationTime(animation.name))

	self:setAnimationStopTime(animation.name, animation.stopTime)
	self:playAnimation(animation.name, dir, self:getAnimationTime(animation.name), true)
end

function Cover:getCoverByFillUnitIndex(fillUnitIndex)
	return self.spec_cover.fillUnitIndexToCover[fillUnitIndex]
end

function Cover:getIsNextCoverStateAllowed(nextState)
	return true
end

function Cover:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	local spec = self.spec_cover

	if spec.hasCovers then
		local cover = spec.fillUnitIndexToCover[fillUnitIndex]

		if cover ~= nil and spec.state ~= cover.index and cover.blockedToolTypes[toolType] then
			return false
		end
	end

	return superFunc(self, fillUnitIndex, toolType)
end

function Cover:getCanBeSelected(superFunc)
	return true
end

function Cover:loadPipeNodes(superFunc, pipeNodes, xmlFile, baseKey)
	superFunc(self, pipeNodes, xmlFile, baseKey)

	local spec = self.spec_pipe
	spec.coverMinState = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.pipe#coverMinState"), 0)
	spec.coverMaxState = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.pipe#coverMaxState"), #self.spec_cover.covers)
end

function Cover:getIsPipeStateChangeAllowed(superFunc)
	if not superFunc(self) then
		return false
	end

	local spec = self.spec_pipe
	local specCover = self.spec_cover

	if specCover.state < spec.coverMinState or spec.coverMaxState < specCover.state then
		return false
	end

	return true
end

function Cover:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_cover

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.hasCovers then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_COVER, self, Cover.actionEventToggleCover, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			Cover.updateActionText(self)
		end
	end
end

function Cover:onStartTipping(tipSide)
	if self.spec_cover.openCoverWhileTipping then
		local trailerSpec = self.spec_trailer
		local tipSideDesc = trailerSpec.tipSides[tipSide]
		local dischargeNode = self:getDischargeNodeByIndex(tipSideDesc.dischargeNodeIndex)
		local cover = self:getCoverByFillUnitIndex(dischargeNode.fillUnitIndex)

		if cover ~= nil then
			self:setCoverState(cover.index, true)
		end
	end
end

function Cover:onAddedFillUnitTrigger(fillTypeIndex, fillUnitIndex, numTriggers)
	local spec = self.spec_cover

	if spec.hasCovers then
		local cover = spec.fillUnitIndexToCover[fillUnitIndex]

		if cover ~= nil then
			local isDifferentState = spec.state ~= cover.index
			local isStateChangedAllowed = self:getIsNextCoverStateAllowed(cover.index)

			if cover.autoReactToTrigger and isDifferentState and isStateChangedAllowed then
				self:setCoverState(cover.index, true)

				spec.isStateSetAutomatically = true
			end
		end
	end
end

function Cover:onRemovedFillUnitTrigger(numTriggers)
	local spec = self.spec_cover

	if spec.hasCovers and numTriggers == 0 then
		local cover = spec.covers[spec.state]

		if cover ~= nil and spec.isStateSetAutomatically and cover.autoReactToTrigger then
			self:setCoverState(0, true)

			spec.isStateSetAutomatically = false
		end
	end
end

function Cover:updateActionText()
	local spec = self.spec_cover
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_COVER]

	if actionEvent ~= nil then
		local text = g_i18n:getText("action_nextCover")

		if spec.state == #spec.covers then
			text = g_i18n:getText("action_closeCover")
		elseif spec.state == 0 then
			text = g_i18n:getText("action_openCover")
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
	end
end

function Cover:actionEventToggleCover(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_cover
	local newState = spec.state + 1

	if newState > #spec.covers then
		newState = 0
	end

	if self:getIsNextCoverStateAllowed(newState) then
		self:setCoverState(newState)

		spec.isStateSetAutomatically = false
	end
end
