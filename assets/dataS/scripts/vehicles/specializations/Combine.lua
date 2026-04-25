source("dataS/scripts/vehicles/specializations/events/CombineStrawEnableEvent.lua")

Combine = {
	DAMAGED_YIELD_REDUCTION = 0.4,
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("combineChopper", false)
		g_workAreaTypeManager:addWorkAreaType("combineSwath", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations) and (SpecializationUtil.hasSpecialization(Drivable, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onStartThreshing")
		SpecializationUtil.registerEvent(vehicleType, "onStopThreshing")
	end
}

function Combine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSetup", Combine.loadCombineSetup)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineEffects", Combine.loadCombineEffects)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineRotationNodes", Combine.loadCombineRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSamples", Combine.loadCombineSamples)
	SpecializationUtil.registerFunction(vehicleType, "setIsSwathActive", Combine.setIsSwathActive)
	SpecializationUtil.registerFunction(vehicleType, "processCombineChopperArea", Combine.processCombineChopperArea)
	SpecializationUtil.registerFunction(vehicleType, "processCombineSwathArea", Combine.processCombineSwathArea)
	SpecializationUtil.registerFunction(vehicleType, "setChopperPSEnabled", Combine.setChopperPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setStrawPSEnabled", Combine.setStrawPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setCombineIsFilling", Combine.setCombineIsFilling)
	SpecializationUtil.registerFunction(vehicleType, "startThreshing", Combine.startThreshing)
	SpecializationUtil.registerFunction(vehicleType, "stopThreshing", Combine.stopThreshing)
	SpecializationUtil.registerFunction(vehicleType, "setWorkedHectars", Combine.setWorkedHectars)
	SpecializationUtil.registerFunction(vehicleType, "addCutterToCombine", Combine.addCutterToCombine)
	SpecializationUtil.registerFunction(vehicleType, "removeCutterFromCombine", Combine.removeCutterFromCombine)
	SpecializationUtil.registerFunction(vehicleType, "addCutterArea", Combine.addCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "getIsThreshingAllowed", Combine.getIsThreshingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "verifyCombine", Combine.verifyCombine)
	SpecializationUtil.registerFunction(vehicleType, "getIsBufferCombine", Combine.getIsBufferCombine)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelDependentSpeed", Combine.getFillLevelDependentSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCombineChopperSpeed", Combine.getCombineChopperSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getIsCutterCompatible", Combine.getIsCutterCompatible)
end

function Combine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Combine.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Combine.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Combine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Combine.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Combine.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Combine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Combine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Combine.getWearMultiplier)
end

function Combine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Combine)
end

function Combine:onLoad(savegame)
	local spec = self.spec_combine

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.combine.chopperSwitch", "vehicle.combine.swath and vehicle.combine.chopper")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.combine.rotationNodes.rotationNode", "combine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.workedHectars", "vehicle.combine.dashboards.dashboard with valueType 'workedHectars'")
	self:loadCombineSetup(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineEffects(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineRotationNodes(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineSamples(self.xmlFile, "vehicle.combine", spec)

	spec.attachedCutters = {}
	spec.numAttachedCutters = 0
	spec.noCutterWarning = g_i18n:convertText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.combine.warning#noCutter"), "$l10n_warning_noCuttersAttached"), self.customEnvironment)
	spec.lastArea = 0
	spec.lastAreaZeroTime = 0
	spec.lastAreaNonZeroTime = -1000000
	spec.lastCuttersArea = 0
	spec.lastCuttersAreaTime = -10000
	spec.lastInputFruitType = FruitType.UNKNOWN
	spec.lastValidInputFruitType = FruitType.UNKNOWN
	spec.lastCuttersFruitType = FruitType.UNKNOWN
	spec.lastCuttersInputFruitType = FruitType.UNKNOWN
	spec.lastDischargeTime = 0
	spec.lastChargeTime = 0
	spec.fillLevelBufferTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.combine#fillLevelBufferTime"), 2000)
	spec.workedHectars = 0
	spec.workedHectarsSent = 0

	if self.loadDashboardsFromXML ~= nil then
		local dashboardData = {
			valueFunc = "workedHectars",
			valueTypeToLoad = "workedHectars",
			valueObject = spec
		}

		self:loadDashboardsFromXML(self.xmlFile, "vehicle.combine.dashboards", dashboardData)
	end

	spec.threshingScale = 1
	spec.lastLostFillLevel = 0
	spec.workAreaParameters = {
		lastRealArea = 0,
		lastArea = 0,
		litersToDrop = 0,
		droppedLiters = 0,
		isChopperEffectEnabled = 0,
		isStrawEffectEnabled = 0
	}
	spec.chopperSpeed = 0
	spec.chopperFade = 2000
	spec.chopperTurnedOnAnimation = getXMLString(self.xmlFile, "vehicle.combine#chopperTurnedOnAnimation")
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Combine:onPostLoad(savegame)
	local spec = self.spec_combine

	if savegame ~= nil then
		if spec.swath.isAvailable then
			local isSwathActive = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. ".combine#isSwathActive"), spec.isSwathActive)

			self:setIsSwathActive(isSwathActive, true, true)
		end

		self:setWorkedHectars(Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. ".combine#workedHectars"), spec.workedHectars))
	else
		self:setIsSwathActive(spec.isSwathActive, true, true)
	end

	local ladder = spec.ladder

	if ladder.animName ~= nil then
		local time = 0

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				time = 1
			end
		end

		if ladder.foldDirection ~= 1 then
			time = 1 - time
		end

		self:setAnimationTime(ladder.animName, time, true)
	end

	if self:getFillUnitCapacity(spec.fillUnitIndex) == 0 then
		g_logManager:xmlWarning(self.configFileName, "Capacity of fill unit '%d' for combine needs to be set greater 0 or not defined! (not defined = infinity)", spec.fillUnitIndex)
	end
end

function Combine:onDelete()
	if self.isClient then
		local spec = self.spec_combine

		g_effectManager:deleteEffects(spec.fillEffects)
		g_effectManager:deleteEffects(spec.strawEffects)
		g_effectManager:deleteEffects(spec.chopperEffects)
		g_animationManager:deleteAnimations(spec.animationNodes)
		g_soundManager:deleteSamples(spec.samples)
	end
end

function Combine:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_combine

	if spec.swath.isAvailable then
		setXMLBool(xmlFile, key .. "#isSwathActive", spec.isSwathActive)
		setXMLFloat(xmlFile, key .. "#workedHectars", spec.workedHectars)
	end
end

function Combine:onReadStream(streamId, connection)
	local spec = self.spec_combine
	spec.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	local combineIsFilling = streamReadBool(streamId)
	local chopperPSenabled = streamReadBool(streamId)
	local strawPSenabled = streamReadBool(streamId)

	self:setCombineIsFilling(combineIsFilling, false, true)
	self:setChopperPSEnabled(chopperPSenabled, false, true)
	self:setStrawPSEnabled(strawPSenabled, false, true)

	local isSwathActive = streamReadBool(streamId)

	self:setIsSwathActive(isSwathActive, true)

	local workedHectars = streamReadFloat32(streamId)

	self:setWorkedHectars(workedHectars)
end

function Combine:onWriteStream(streamId, connection)
	local spec = self.spec_combine

	streamWriteUIntN(streamId, spec.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, spec.isFilling)
	streamWriteBool(streamId, spec.chopperPSenabled)
	streamWriteBool(streamId, spec.strawPSenabled)
	streamWriteBool(streamId, spec.isSwathActive)
	streamWriteFloat32(streamId, spec.workedHectars)
end

function Combine:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_combine
		spec.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
		local combineIsFilling = streamReadBool(streamId)
		local chopperPSenabled = streamReadBool(streamId)
		local strawPSenabled = streamReadBool(streamId)

		self:setCombineIsFilling(combineIsFilling, false, true)
		self:setChopperPSEnabled(chopperPSenabled, false, true)
		self:setStrawPSEnabled(strawPSenabled, false, true)

		local workedHectars = streamReadFloat32(streamId)

		self:setWorkedHectars(workedHectars)
	end
end

function Combine:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_combine

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, spec.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
			streamWriteBool(streamId, spec.isFilling)
			streamWriteBool(streamId, spec.chopperPSenabled)
			streamWriteBool(streamId, spec.strawPSenabled)
			streamWriteFloat32(streamId, spec.workedHectars)
		end
	end
end

function Combine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_combine
	local isTurnedOn = self:getIsTurnedOn()

	if isTurnedOn and self.isServer and spec.swath.isAvailable then
		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(spec.fillUnitIndex))

		if spec.isSwathActive and fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if not fruitDesc.hasWindrow then
				self:setIsSwathActive(false)
			end
		elseif (not spec.chopper.isAvailable or spec.automatedChopperSwitch) and not spec.isSwathActive and fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if fruitDesc.hasWindrow then
				self:setIsSwathActive(true)

				local inputBuffer = spec.processing.inputBuffer

				for i = 1, #inputBuffer.buffer do
					inputBuffer.buffer[i].area = 0
					inputBuffer.buffer[i].realArea = 0
					inputBuffer.buffer[i].liters = 0
					inputBuffer.buffer[i].inputLiters = 0
				end
			end
		end
	end

	if self.isClient then
		if self.spec_combine.isSwathActive then
			if spec.chopperSpeed > 0 then
				spec.chopperSpeed = math.max(spec.chopperSpeed - dt / spec.chopperFade, 0)
			end

			if spec.chopperTurnedOnAnimation ~= nil then
				local turnOnVehicleSpec = self.spec_turnOnVehicle

				if turnOnVehicleSpec ~= nil and self:getIsTurnedOn() then
					for _, animation in ipairs(turnOnVehicleSpec.turnedOnAnimations) do
						if animation.name == spec.chopperTurnedOnAnimation and animation.currentSpeed > 0 then
							animation.speedDirection = -1
						end
					end
				end
			end
		else
			if spec.chopperSpeed < 1 then
				spec.chopperSpeed = math.min(spec.chopperSpeed + dt / spec.chopperFade, 1)
			end

			if spec.chopperTurnedOnAnimation ~= nil then
				local turnOnVehicleSpec = self.spec_turnOnVehicle

				if turnOnVehicleSpec ~= nil and self:getIsTurnedOn() then
					for _, animation in ipairs(turnOnVehicleSpec.turnedOnAnimations) do
						if animation.name == spec.chopperTurnedOnAnimation and animation.currentSpeed < 1 then
							animation.speedDirection = 1

							self:playAnimation(animation.name, math.max(animation.currentSpeed * animation.speedScale, 0.001), self:getAnimationTime(animation.name), true)
						end
					end
				end
			end
		end
	end

	if self.isServer and self:getFillUnitFillLevel(spec.fillUnitIndex) < 0.0001 then
		spec.lastDischargeTime = g_time
	end
end

function Combine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_combine

	if self.isServer then
		spec.lastArea = spec.lastCuttersArea
		spec.lastAreaZeroTime = spec.lastAreaZeroTime + dt

		if spec.lastArea > 0 then
			spec.lastAreaZeroTime = 0
			spec.lastAreaNonZeroTime = g_currentMission.time
		end

		spec.lastInputFruitType = spec.lastCuttersInputFruitType
		spec.lastCuttersArea = 0
		spec.lastCuttersInputFruitType = FruitType.UNKNOWN
		spec.lastCuttersFruitType = FruitType.UNKNOWN

		if spec.lastInputFruitType ~= FruitType.UNKNOWN then
			spec.lastValidInputFruitType = spec.lastInputFruitType
		end

		local inputBuffer = spec.processing.inputBuffer

		if spec.lastAreaZeroTime > 500 and spec.fillDisableTime == nil then
			spec.fillDisableTime = g_currentMission.time + spec.processing.toggleTime
		end

		if spec.fillEnableTime ~= nil and spec.fillEnableTime <= g_currentMission.time then
			self:setCombineIsFilling(true, false, false)

			spec.fillEnableTime = nil
		end

		if spec.fillDisableTime ~= nil and spec.fillDisableTime <= g_currentMission.time then
			self:setCombineIsFilling(false, false, false)

			spec.fillDisableTime = nil
		end

		spec.workAreaParameters.isChopperEffectEnabled = math.max(spec.workAreaParameters.isChopperEffectEnabled - dt, 0)
		spec.workAreaParameters.isStrawEffectEnabled = math.max(spec.workAreaParameters.isStrawEffectEnabled - dt, 0)
		local chopperPSActive = spec.workAreaParameters.isChopperEffectEnabled > 0
		local strawPSActive = spec.workAreaParameters.isStrawEffectEnabled > 0

		self:setChopperPSEnabled(chopperPSActive, false, false)
		self:setStrawPSEnabled(strawPSActive, false, false)

		if chopperPSActive or strawPSActive then
			self:raiseActive()
		end

		if self:getIsTurnedOn() then
			local stats = g_currentMission:farmStats(self:getOwnerFarmId())

			stats:updateStats("threshedTime", dt / 60000)
			stats:updateStats("workedTime", dt / 60000)
		end

		inputBuffer.slotTimer = inputBuffer.slotTimer - dt

		if inputBuffer.slotTimer < 0 then
			inputBuffer.slotTimer = inputBuffer.slotDuration
			inputBuffer.fillIndex = inputBuffer.fillIndex + 1

			if inputBuffer.slotCount < inputBuffer.fillIndex then
				inputBuffer.fillIndex = 1
			end

			local lastDropIndex = inputBuffer.dropIndex
			inputBuffer.dropIndex = inputBuffer.dropIndex + 1

			if inputBuffer.slotCount < inputBuffer.dropIndex then
				inputBuffer.dropIndex = 1
			end

			inputBuffer.buffer[inputBuffer.dropIndex].liters = inputBuffer.buffer[inputBuffer.dropIndex].liters + inputBuffer.buffer[lastDropIndex].liters
			inputBuffer.buffer[inputBuffer.dropIndex].inputLiters = inputBuffer.buffer[inputBuffer.dropIndex].inputLiters + inputBuffer.buffer[lastDropIndex].liters
			inputBuffer.buffer[lastDropIndex].area = 0
			inputBuffer.buffer[lastDropIndex].realArea = 0
			inputBuffer.buffer[lastDropIndex].liters = 0
			inputBuffer.buffer[lastDropIndex].inputLiters = 0
		end

		if spec.isFilling ~= spec.sentIsFilling or spec.chopperPSenabled ~= spec.sentChopperPSenabled or spec.strawPSenabled ~= spec.sentStrawPSenabled then
			self:raiseDirtyFlags(spec.dirtyFlag)

			spec.sentIsFilling = spec.isFilling
			spec.sentChopperPSenabled = spec.chopperPSenabled
			spec.sentStrawPSenabled = spec.strawPSenabled
		end
	end
end

function Combine:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsTurnedOn() and not self:getIsThreshingAllowed(false) then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_doNotThreshDuringRainOrHail"), 2000)
	end
end

function Combine:loadCombineSetup(xmlFile, baseKey, entry)
	entry.allowThreshingDuringRain = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#allowThreshingDuringRain"), false)
	entry.fillUnitIndex = Utils.getNoNil(getXMLInt(xmlFile, baseKey .. "#fillUnitIndex"), 1)
	entry.loadInfoIndex = Utils.getNoNil(getXMLInt(xmlFile, baseKey .. "#loadInfoIndex"), 1)
	entry.swath = {
		isAvailable = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. ".swath#available"), false)
	}
	local isDefaultActive = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. ".swath#isDefaultActive"), entry.swath.isAvailable)

	if entry.swath.isAvailable then
		entry.swath.workAreaIndex = getXMLInt(xmlFile, baseKey .. ".swath#workAreaIndex")

		if entry.swath.workAreaIndex == nil then
			entry.swath.isAvailable = false

			g_logManager:xmlWarning(self.configFileName, "Missing 'swath#workAreaIndex' for combine swath function!")
		end

		entry.warningTime = 0
	end

	entry.chopper = {
		isAvailable = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. ".chopper#available"), false)
	}

	if entry.chopper.isAvailable then
		entry.chopper.workAreaIndex = getXMLInt(xmlFile, baseKey .. ".chopper#workAreaIndex")

		if entry.chopper.workAreaIndex == nil then
			entry.chopper.isAvailable = false

			g_logManager:xmlWarning(self.configFileName, "Missing 'chopper#workAreaIndex' for combine chopper function!")
		end

		entry.chopper.animName = getXMLString(xmlFile, baseKey .. ".chopper#animName")
		entry.chopper.animSpeedScale = getXMLFloat(xmlFile, baseKey .. ".chopper#animSpeedScale")
	end

	entry.automatedChopperSwitch = GS_IS_MOBILE_VERSION
	entry.isSwathActive = isDefaultActive
	entry.ladder = {
		animName = getXMLString(xmlFile, baseKey .. ".ladder#animName"),
		animSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".ladder#animSpeedScale"), 1),
		foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".ladder#foldMinLimit"), 0.99),
		foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".ladder#foldMaxLimit"), 1)
	}
	entry.ladder.foldDirection = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".ladder#foldDirection"), MathUtil.sign(entry.ladder.animSpeedScale))
	entry.processing = {}
	local toggleTime = getXMLFloat(xmlFile, baseKey .. ".processing#toggleTime")

	if toggleTime == nil and entry.chopper.animName ~= nil then
		toggleTime = self:getAnimationDurection(entry.chopper.animName)

		if toggleTime ~= nil then
			toggleTime = toggleTime / 1000
		end
	end

	entry.processing.toggleTime = Utils.getNoNil(toggleTime, 0) * 1000
	local inputBuffer = {}
	local slotDuration = 300
	local slotCount = MathUtil.clamp(math.ceil(entry.processing.toggleTime / slotDuration), 2, 20)
	inputBuffer.slotCount = slotCount
	inputBuffer.slotDuration = math.ceil(entry.processing.toggleTime / inputBuffer.slotCount)
	inputBuffer.fillIndex = 1
	inputBuffer.dropIndex = inputBuffer.fillIndex + 1
	inputBuffer.slotTimer = inputBuffer.slotDuration
	inputBuffer.activeTimeout = inputBuffer.slotDuration * (inputBuffer.slotCount + 2)
	inputBuffer.activeTimer = inputBuffer.activeTimeout
	inputBuffer.buffer = {}

	for i = 1, inputBuffer.slotCount do
		table.insert(inputBuffer.buffer, {
			strawRatio = 0,
			inputLiters = 0,
			realArea = 0,
			area = 0,
			liters = 0
		})
	end

	entry.processing.inputBuffer = inputBuffer
	entry.threshingStartAnimation = getXMLString(xmlFile, baseKey .. ".threshingStartAnimation#name")
	entry.threshingStartAnimationSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".threshingStartAnimation#speedScale"), 1)
	entry.threshingStartAnimationInitialIsStarted = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. ".threshingStartAnimation#initialIsStarted"), false)
	entry.foldFillLevelThreshold = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".folding#fillLevelThreshold"), (self:getFillUnitCapacity(entry.fillUnitIndex) or 0.04) * 0.15)
	entry.foldDirection = Utils.getNoNil(getXMLInt(xmlFile, baseKey .. ".folding#direction"), 1)
	entry.allowFoldWhileThreshing = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. ".folding#allowWhileThreshing"), false)
end

function Combine:loadCombineEffects(xmlFile, baseKey, entry)
	if self.isClient then
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseKey .. ".chopperParticleSystems", baseKey .. ".chopperEffect")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseKey .. ".strawParticleSystems", baseKey .. ".strawEffect")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseKey .. ".threshingFillParticleSystems", baseKey .. ".fillEffect")

		entry.chopperEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".chopperEffect", self.components, self, self.i3dMappings)
		entry.strawEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".strawEffect", self.components, self, self.i3dMappings)
		entry.fillEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".fillEffect", self.components, self, self.i3dMappings)
		entry.strawPSenabled = false
		entry.chopperPSenabled = false
		entry.isFilling = false
		entry.fillEnableTime = nil
		entry.fillDisableTime = nil
	end
end

function Combine:loadCombineRotationNodes(xmlFile, baseKey, entry)
	if self.isClient then
		entry.animationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
		entry.fillingAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".fillingAnimationNodes", self.components, self, self.i3dMappings)
		entry.rotationNodesSpeedReverseFillLevel = getXMLFloat(xmlFile, baseKey .. ".animationNodes#speedReverseFillLevel")
	end
end

function Combine:loadCombineSamples(xmlFile, key, entry)
	if self.isClient then
		entry.samples = {
			start = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function Combine:setIsSwathActive(isSwathActive, noEventSend, force)
	local spec = self.spec_combine

	if isSwathActive ~= spec.isSwathActive or force then
		CombineStrawEnableEvent.sendEvent(self, isSwathActive, noEventSend)

		spec.isSwathActive = isSwathActive
		local anim = spec.chopper.animName

		if self.playAnimation ~= nil and anim ~= nil then
			local dir = 1

			if isSwathActive then
				dir = -1
			end

			self:playAnimation(anim, dir, self:getAnimationTime(anim), true)

			if force then
				AnimatedVehicle.updateAnimationByName(self, anim, 9999999)
			end
		end

		Combine.updateToggleStrawText(self)
	end
end

function Combine:processCombineChopperArea(workArea)
	local spec = self.spec_combine

	if not spec.isSwathActive then
		local litersToDrop = spec.workAreaParameters.litersToDrop
		local strawRatio = spec.workAreaParameters.strawRatio
		spec.workAreaParameters.droppedLiters = litersToDrop

		if litersToDrop > 0 and strawRatio > 0 then
			if g_platformSettingsManager:getSetting("useSprayDiffuseMaps", true) then
				local xs, _, zs = getWorldTranslation(workArea.start)
				local xw, _, zw = getWorldTranslation(workArea.width)
				local xh, _, zh = getWorldTranslation(workArea.height)

				FSDensityMapUtil.setGroundTypeLayerArea(xs, zs, xw, zw, xh, zh, g_currentMission.chopperGroundLayerType)
			end

			self:raiseActive()

			spec.workAreaParameters.isChopperEffectEnabled = 500
		end
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Combine:processCombineSwathArea(workArea)
	local spec = self.spec_combine
	local litersToDrop = spec.workAreaParameters.litersToDrop

	if spec.isSwathActive and litersToDrop > 0 then
		local droppedLiters = 0
		local fruitDesc = g_fruitTypeManager:getFruitTypeByFillTypeIndex(spec.workAreaParameters.dropFillType)

		if fruitDesc ~= nil and fruitDesc.windrowLiterPerSqm ~= nil then
			local windrowFillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitDesc.index)

			if windrowFillType ~= nil then
				local sx, sy, sz, ex, ey, ez = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
				local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, windrowFillType, sx, sy, sz, ex, ey, ez, 0, nil, workArea.lineOffset, false, nil, false)
				droppedLiters = dropped
				workArea.lineOffset = lineOffset
			end
		end

		if droppedLiters > 0 then
			spec.workAreaParameters.isStrawEffectEnabled = 500
		end

		spec.workAreaParameters.droppedLiters = droppedLiters
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Combine:setChopperPSEnabled(chopperPSenabled, fruitTypeChanged, isSynchronized)
	local spec = self.spec_combine

	if spec.chopperPSenabled ~= chopperPSenabled or fruitTypeChanged then
		if spec.chopperEffects ~= nil and (not chopperPSenabled or fruitTypeChanged) then
			g_effectManager:stopEffects(spec.chopperEffects)
		end

		spec.chopperPSenabled = chopperPSenabled

		if self.isServer and isSynchronized then
			spec.sentChopperPSenabled = chopperPSenabled
		end

		if chopperPSenabled and self.isClient and spec.chopperEffects ~= nil then
			g_effectManager:setFillType(spec.chopperEffects, self:getFillUnitLastValidFillType(spec.fillUnitIndex))
			g_effectManager:startEffects(spec.chopperEffects)
		end
	end
end

function Combine:setStrawPSEnabled(strawPSenabled, fruitTypeChanged, isSynchronized)
	local spec = self.spec_combine

	if spec.strawPSenabled ~= strawPSenabled or fruitTypeChanged then
		if spec.strawEffects ~= nil and (not strawPSenabled or fruitTypeChanged) then
			g_effectManager:stopEffects(spec.strawEffects)
		end

		spec.strawPSenabled = strawPSenabled

		if self.isServer and isSynchronized then
			spec.sentStrawPSenabled = strawPSenabled
		end

		if not strawPSenabled then
			spec.strawToDrop = 0
		end

		if strawPSenabled and self.isClient and spec.strawEffects ~= nil then
			g_effectManager:setFillType(spec.strawEffects, self:getFillUnitLastValidFillType(spec.fillUnitIndex))
			g_effectManager:startEffects(spec.strawEffects)
		end
	end
end

function Combine:setCombineIsFilling(isFilling, fruitTypeChanged, isSynchronized)
	local spec = self.spec_combine

	if spec.isFilling ~= isFilling or fruitTypeChanged then
		spec.isFilling = isFilling

		if isFilling then
			g_animationManager:startAnimations(spec.fillingAnimationNodes)
		else
			g_animationManager:stopAnimations(spec.fillingAnimationNodes)
		end

		g_animationManager:setFillType(spec.fillingAnimationNodes, self:getFillUnitLastValidFillType(spec.fillUnitIndex))

		if self.isServer and isSynchronized then
			spec.sentIsFilling = isFilling
		end

		if spec.fillEffects ~= nil and (not isFilling or fruitTypeChanged) then
			g_effectManager:stopEffects(spec.fillEffects)
		end

		if isFilling and spec.fillEffects ~= nil then
			g_effectManager:setFillType(spec.fillEffects, self:getFillUnitLastValidFillType(spec.fillUnitIndex))
			g_effectManager:startEffects(spec.fillEffects)
		end
	end
end

function Combine:startThreshing()
	local spec = self.spec_combine

	if spec.numAttachedCutters > 0 then
		local allowLowering = not self:getIsAIActive() or not self:getRootVehicle():getAIIsTurning()

		for _, cutter in pairs(spec.attachedCutters) do
			if allowLowering and cutter ~= self then
				local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

				self:setJointMoveDown(jointDescIndex, true, true)
			end

			cutter:setIsTurnedOn(true, true)
		end

		if spec.threshingStartAnimation ~= nil and self.playAnimation ~= nil then
			self:playAnimation(spec.threshingStartAnimation, spec.threshingStartAnimationSpeedScale, self:getAnimationTime(spec.threshingStartAnimation), true)
		end

		if self.isClient then
			g_soundManager:stopSamples(spec.samples)
			g_soundManager:playSample(spec.samples.start)
			g_soundManager:playSample(spec.samples.work, 0, spec.samples.start)
		end

		SpecializationUtil.raiseEvent(self, "onStartThreshing")
	end
end

function Combine:stopThreshing()
	local spec = self.spec_combine

	if self.isClient then
		g_soundManager:stopSamples(spec.samples)
		g_soundManager:playSample(spec.samples.stop)
	end

	self:setCombineIsFilling(false, false, true)

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter ~= self then
			local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

			self:setJointMoveDown(jointDescIndex, false, true)
		end

		cutter:setIsTurnedOn(false, true)
	end

	if spec.threshingStartAnimation ~= nil and spec.playAnimation ~= nil then
		self:playAnimation(spec.threshingStartAnimation, -spec.threshingStartAnimationSpeedScale, self:getAnimationTime(spec.threshingStartAnimation), true)
	end

	SpecializationUtil.raiseEvent(self, "onStopThreshing")
end

function Combine:setWorkedHectars(hectars)
	local spec = self.spec_combine
	spec.workedHectars = hectars

	if self.isServer and math.abs(spec.workedHectars - spec.workedHectarsSent) > 0.01 then
		self:raiseDirtyFlags(spec.dirtyFlag)

		spec.workedHectarsSent = spec.workedHectars
	end
end

function Combine:addCutterToCombine(cutter)
	local spec = self.spec_combine

	if spec.attachedCutters[cutter] == nil then
		spec.attachedCutters[cutter] = cutter
		spec.numAttachedCutters = spec.numAttachedCutters + 1
	end
end

function Combine:removeCutterFromCombine(cutter)
	local spec = self.spec_combine

	if spec.attachedCutters[cutter] ~= nil then
		spec.numAttachedCutters = spec.numAttachedCutters - 1

		if spec.numAttachedCutters == 0 then
			self:setIsTurnedOn(false, true)
		end

		spec.attachedCutters[cutter] = nil
	end
end

function Combine:addCutterArea(area, realArea, inputFruitType, outputFillType, strawRatio, farmId)
	local spec = self.spec_combine

	if area > 0 and (spec.lastCuttersFruitType == FruitType.UNKNOWN or spec.lastCuttersArea == 0 or spec.lastCuttersOutputFillType == outputFillType) then
		spec.lastCuttersArea = spec.lastCuttersArea + area
		spec.lastCuttersOutputFillType = outputFillType
		spec.lastCuttersInputFruitType = inputFruitType
		spec.lastCuttersAreaTime = g_currentMission.time

		if not spec.swath.isAvailable then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
			spec.isSwathActive = not fruitDesc.hasWindrow
		end

		local litersPerSqm = 60
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)

		if fruitDesc.windrowLiterPerSqm ~= nil then
			litersPerSqm = fruitDesc.windrowLiterPerSqm
		end

		if self:getFillUnitLastValidFillType(spec.fillUnitIndex) == outputFillType then
			local liters = realArea * g_currentMission:getFruitPixelsToSqm() * litersPerSqm * strawRatio

			if liters > 0 then
				local inputBuffer = spec.processing.inputBuffer
				local slot = inputBuffer.buffer[inputBuffer.fillIndex]
				slot.area = slot.area + area
				slot.realArea = slot.realArea + realArea
				slot.liters = slot.liters + liters
				slot.inputLiters = slot.inputLiters + liters
				slot.strawRatio = strawRatio
			end
		end

		if spec.fillEnableTime == nil then
			spec.fillEnableTime = g_currentMission.time + spec.processing.toggleTime
		end

		local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
		local literPerSqm = 1

		if inputFruitType ~= FruitType.UNKNOWN then
			fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
			literPerSqm = fruitDesc.literPerSqm
		end

		local sqm = realArea * pixelToSqm
		local deltaFillLevel = sqm * literPerSqm * spec.threshingScale
		local fillType = outputFillType

		self:setWorkedHectars(spec.workedHectars + MathUtil.areaToHa(realArea, g_currentMission:getFruitPixelsToSqm()))

		if farmId ~= AccessHandler.EVERYONE then
			local damage = self:getVehicleDamage()

			if damage > 0 then
				deltaFillLevel = deltaFillLevel * (1 - damage * Combine.DAMAGED_YIELD_REDUCTION)
			end
		end

		if self:getFillUnitCapacity(spec.fillUnitIndex) == math.huge and self:getFillUnitFillLevel(spec.fillUnitIndex) > 0.001 and spec.lastDischargeTime + spec.fillLevelBufferTime < g_time then
			return deltaFillLevel
		end

		local loadInfo = self:getFillVolumeLoadInfo(spec.loadInfoIndex)

		return self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, deltaFillLevel, fillType, ToolType.UNDEFINED, loadInfo)
	end

	return 0
end

function Combine:getIsThreshingAllowed(earlyWarning)
	local spec = self.spec_combine

	if spec.allowThreshingDuringRain then
		return true
	end

	local rainScale = g_currentMission.environment.weather:getRainFallScale()
	local timeSinceLastRain = g_currentMission.environment.weather:getTimeSinceLastRain()

	if earlyWarning ~= nil and earlyWarning == true then
		if rainScale <= 0.02 and timeSinceLastRain > 20 then
			return true
		end
	elseif rainScale <= 0.1 and timeSinceLastRain > 20 then
		return true
	end

	return false
end

function Combine:verifyCombine(fruitType, outputFillType)
	local spec = self.spec_combine

	if self:getFillUnitFillLevel(spec.fillUnitIndex) > self:getFillTypeChangeThreshold() * self:getFillUnitCapacity(spec.fillUnitIndex) then
		local currentFillType = self:getFillUnitFillType(spec.fillUnitIndex)

		if currentFillType ~= FillType.UNKNOWN and fruitType ~= FruitType.UNKNOWN and currentFillType ~= outputFillType then
			if self:getIsBufferCombine() then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, currentFillType, ToolType.UNDEFINED, nil)

				return self
			end

			return nil, self, currentFillType
		end
	end

	if not self:getIsThreshingAllowed() then
		return nil
	end

	if self:getFillUnitFreeCapacity(spec.fillUnitIndex) == 0 then
		return nil
	end

	return self
end

function Combine:getIsBufferCombine()
	return self:getFillUnitCapacity(self.spec_combine.fillUnitIndex) == math.huge
end

function Combine:getFillLevelDependentSpeed()
	local spec = self.spec_combine

	if spec.rotationNodesSpeedReverseFillLevel ~= nil then
		local fillLevelPct = self:getFillUnitFillLevel(spec.fillUnitIndex) / self:getFillUnitCapacity(spec.fillUnitIndex)

		if spec.rotationNodesSpeedReverseFillLevel < fillLevelPct then
			return -1
		else
			return 1
		end
	else
		return 1
	end
end

function Combine:getCombineChopperSpeed()
	return self.spec_combine.chopperSpeed
end

function Combine:getIsCutterCompatible(fillTypes)
	local spec = self.spec_combine
	local supportedTypes = self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)

	for i = 1, #fillTypes do
		local fillType = fillTypes[i]

		for supportedType, _ in pairs(supportedTypes) do
			if fillType == supportedType then
				return true
			end
		end
	end

	return false
end

function Combine:getCombineLoadPercentage()
	local spec = self.spec_combine

	if spec ~= nil and spec.numAttachedCutters > 0 then
		local loadSum = 0

		for cutter, _ in pairs(spec.attachedCutters) do
			if cutter.getCutterLoad ~= nil then
				loadSum = loadSum + cutter:getCutterLoad()
			end
		end

		return loadSum / spec.numAttachedCutters
	end

	return 0
end

g_soundManager:registerModifierType("COMBINE_LOAD", Combine.getCombineLoadPercentage)

function Combine:getCanBeTurnedOn(superFunc)
	local spec = self.spec_combine

	if spec.numAttachedCutters <= 0 then
		return false
	end

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter ~= self and cutter.getCanBeTurnedOn ~= nil and not cutter:getCanBeTurnedOn() then
			return false
		end
	end

	return superFunc(self)
end

function Combine:getTurnedOnNotAllowedWarning(superFunc)
	if self:getIsActiveForInput(true) then
		local spec = self.spec_combine

		if not self:getCanBeTurnedOn() then
			if spec.numAttachedCutters == 0 then
				return spec.noCutterWarning
			else
				for cutter, _ in pairs(spec.attachedCutters) do
					if cutter ~= self and cutter.getTurnedOnNotAllowedWarning ~= nil then
						local warning = cutter:getTurnedOnNotAllowedWarning()

						if warning ~= nil then
							return warning
						end
					end
				end
			end
		end
	end

	return superFunc(self)
end

function Combine:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_combine

	if spec.numAttachedCutters <= 0 then
		return false, spec.noCutterWarning
	end

	return superFunc(self)
end

function Combine:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_combine

	if not self.allowFoldWhileThreshing and self:getIsTurnedOn() then
		return false
	end

	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

	if direction == spec.foldDirection and spec.foldFillLevelThreshold < fillLevel and self:getFillUnitCapacity(spec.fillUnitIndex) ~= math.huge then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Combine:getCanBeSelected(superFunc)
	return true
end

function Combine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end

	if workArea.type == WorkAreaType.COMBINECHOPPER or workArea.type == WorkAreaType.COMBINESWATH then
		if getXMLBool(xmlFile, key .. "#requiresOwnedFarmland") == nil then
			workArea.requiresOwnedFarmland = false
		end

		if getXMLBool(xmlFile, key .. "#needsSetIsTurnedOn") == nil then
			workArea.needsSetIsTurnedOn = false
		end
	end

	return true
end

function Combine:getDirtMultiplier(superFunc)
	local spec = self.spec_combine

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter.spec_cutter ~= nil and cutter.spec_cutter.isWorking then
			return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / cutter.speedLimit
		end
	end

	return superFunc(self)
end

function Combine:getWearMultiplier(superFunc)
	local spec = self.spec_combine

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter.spec_cutter ~= nil and cutter.spec_cutter.isWorking then
			return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / cutter.speedLimit
		end
	end

	return superFunc(self)
end

function Combine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_combine

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.swath.isAvailable and spec.chopper.isAvailable then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CHOPPER, self, Combine.actionEventToggleChopper, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			Combine.updateToggleStrawText(self)
		end
	end
end

function Combine:onStartWorkAreaProcessing(dt)
	local spec = self.spec_combine
	spec.workAreaParameters.droppedLiters = 0
	spec.workAreaParameters.litersToDrop = 0
	spec.workAreaParameters.strawRatio = 0
	spec.workAreaParameters.dropFillType = FillType.UNKNOWN
	local lastValidFillType = self:getFillUnitLastValidFillType(spec.fillUnitIndex)

	if lastValidFillType ~= FillType.UNKNOWN then
		local inputBuffer = spec.processing.inputBuffer
		local inputLiters = inputBuffer.buffer[inputBuffer.dropIndex].inputLiters
		spec.workAreaParameters.litersToDrop = math.min(inputBuffer.buffer[inputBuffer.dropIndex].liters, dt / inputBuffer.slotDuration * inputLiters)
		spec.workAreaParameters.strawRatio = inputBuffer.buffer[inputBuffer.dropIndex].strawRatio
		spec.workAreaParameters.dropFillType = lastValidFillType
	end

	spec.workAreaParameters.lastRealArea = 0
	spec.workAreaParameters.lastArea = 0
end

function Combine:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_combine
	local inputBuffer = spec.processing.inputBuffer
	inputBuffer.buffer[inputBuffer.dropIndex].liters = math.max(0, inputBuffer.buffer[inputBuffer.dropIndex].liters - spec.workAreaParameters.droppedLiters)
end

function Combine:onChangedFillType(fillUnitIndex, fillTypeIndex)
	local spec = self.spec_combine

	if fillUnitIndex == spec.fillUnitIndex then
		if spec.chopperPSenabled then
			self:setChopperPSEnabled(true, true, true)
		end

		if spec.strawPSenabled then
			self:setStrawPSEnabled(true, true, true)
		end

		if spec.isFilling then
			self:setCombineIsFilling(true, true, true)
		end
	end
end

function Combine:onDeactivate()
	local spec = self.spec_combine

	self:setChopperPSEnabled(false, false, true)
	self:setStrawPSEnabled(false, false, true)
	self:setCombineIsFilling(false, false, true)

	spec.fillEnableTime = nil
	spec.fillDisableTime = nil
end

function Combine:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_combine
	local attacherJoint = attachable:getActiveInputAttacherJoint()

	if attacherJoint ~= nil and (attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
		self:addCutterToCombine(attachable)
	end
end

function Combine:onPostDetachImplement(implementIndex)
	local spec = self.spec_combine
	local object = self:getObjectFromImplementIndex(implementIndex)

	if object ~= nil then
		local attacherJoint = object:getActiveInputAttacherJoint()

		if attacherJoint ~= nil and (attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
			self:removeCutterFromCombine(object)
		end
	end
end

function Combine:onTurnedOn()
	self:startThreshing()

	if self.isClient then
		local spec = self.spec_combine

		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function Combine:onTurnedOff()
	self:stopThreshing()

	if self.isClient then
		local spec = self.spec_combine

		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function Combine:onEnterVehicle()
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil then
		local fold = true

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				fold = false
			end
		end

		if fold then
			self:playAnimation(ladder.animName, -ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:onLeaveVehicle()
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil then
		local fold = true

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				fold = false
			end
		end

		if fold then
			self:playAnimation(ladder.animName, ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:onFoldStateChanged(direction, moveToMiddle)
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil and direction ~= 0 and not moveToMiddle then
		self:playAnimation(ladder.animName, direction * ladder.animSpeedScale * ladder.foldDirection, self:getAnimationTime(ladder.animName), true)
	end
end

function Combine:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_combine

	if fillUnitIndex == spec.fillUnitIndex and fillLevelDelta < 0 then
		spec.lastDischargeTime = g_time
	end
end

function Combine:actionEventToggleChopper(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_combine

	if spec.swath.isAvailable then
		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(spec.fillUnitIndex))

		if fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if fruitDesc.hasWindrow then
				self:setIsSwathActive(not spec.isSwathActive)
			else
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_couldNotToggleChopper"), 2000)
			end
		else
			self:setIsSwathActive(not spec.isSwathActive)
		end
	end
end

function Combine:updateToggleStrawText()
	local spec = self.spec_combine
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_CHOPPER]

	if actionEvent ~= nil and actionEvent.actionEventId ~= nil then
		local text = nil

		if spec.isSwathActive then
			text = g_i18n:getText("action_disableStrawSwath")
		else
			text = g_i18n:getText("action_enableStrawSwath")
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
	end
end
