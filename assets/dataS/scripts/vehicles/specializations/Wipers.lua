Wipers = {
	forcedState = 0,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function Wipers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWiperFromXML", Wipers.loadWiperFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForWipers", Wipers.getIsActiveForWipers)
end

function Wipers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wipers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wipers)
end

function Wipers:onLoad(savegame)
	local spec = self.spec_wipers
	spec.wipers = {}
	local i = 0

	while true do
		local key = string.format("vehicle.wipers.wiper(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local wiper = {}

		if self:loadWiperFromXML(self.xmlFile, key, wiper) then
			table.insert(spec.wipers, wiper)
		end

		i = i + 1
	end

	spec.hasWipers = #spec.wipers > 0
	spec.lastRainScale = 0
end

function Wipers:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wipers

	if spec.hasWipers and self:getIsControlled() then
		spec.lastRainScale = g_currentMission.environment.weather:getRainFallScale()

		for _, wiper in pairs(spec.wipers) do
			local stateIdToUse = 0

			if self:getIsActiveForWipers() and spec.lastRainScale > 0 then
				for stateIndex, state in ipairs(wiper.states) do
					if spec.lastRainScale <= state.maxRainValue then
						stateIdToUse = stateIndex

						break
					end
				end
			end

			if Wipers.forcedState ~= 0 then
				stateIdToUse = MathUtil.clamp(Wipers.forcedState, 1, #wiper.states)
			end

			if stateIdToUse > 0 then
				local currentState = wiper.states[stateIdToUse]

				if self:getAnimationTime(wiper.animName) == 1 then
					self:playAnimation(wiper.animName, -currentState.animSpeed, 1, true)
				end

				if (wiper.nextStartTime == nil or wiper.nextStartTime < g_currentMission.time) and not self:getIsAnimationPlaying(wiper.animName) then
					self:playAnimation(wiper.animName, currentState.animSpeed, 0, true)

					wiper.nextStartTime = nil
				end

				if wiper.nextStartTime == nil then
					wiper.nextStartTime = g_currentMission.time + wiper.animDuration / currentState.animSpeed + currentState.animPause
				end
			end
		end
	end
end

function Wipers:loadWiperFromXML(xmlFile, key, wiper)
	local animName = getXMLString(xmlFile, key .. "#animName")

	if animName ~= nil then
		if self:getAnimationExists(animName) then
			wiper.animName = animName
			wiper.animDuration = self:getAnimationDuration(animName)
			wiper.states = {}
			local j = 0

			while true do
				local stateKey = string.format("%s.state(%d)", key, j)

				if not hasXMLProperty(xmlFile, stateKey) then
					break
				end

				local state = {
					animSpeed = getXMLFloat(xmlFile, stateKey .. "#animSpeed"),
					animPause = getXMLFloat(xmlFile, stateKey .. "#animPause")
				}

				if state.animSpeed ~= nil and state.animPause ~= nil then
					state.animPause = state.animPause * 1000

					table.insert(wiper.states, state)
				end

				j = j + 1
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Animation '%s' not defined for wiper '%s'!", animName, key)

			return false
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Missing animation for wiper '%s'!", key)

		return false
	end

	local numStates = #wiper.states

	if numStates > 0 then
		local stepSize = 1 / numStates
		local curMax = stepSize

		for _, state in ipairs(wiper.states) do
			state.maxRainValue = curMax
			curMax = curMax + stepSize
		end

		wiper.nextStartTime = nil
	else
		g_logManager:xmlWarning(self.configFileName, "No states defined for wiper '%s'!", key)

		return false
	end

	return true
end

function Wipers:getIsActiveForWipers()
	return true
end

function consoleSetWiperState(state)
	if state == nil then
		return "No arguments given! Usage: gsSetWiperState <state> (state 0 = use state from weather)"
	end

	Wipers.forcedState = tonumber(state)

	return "Set global wiper states to " .. tostring(Wipers.forcedState)
end

addConsoleCommand("gsSetWiperState", "Sets the given wiper state for all vehicles", "consoleSetWiperState", nil)
