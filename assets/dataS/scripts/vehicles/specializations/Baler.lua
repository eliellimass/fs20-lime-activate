source("dataS/scripts/vehicles/specializations/events/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerCreateBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerDropFromPlatformEvent.lua")

Baler = {
	UNLOADING_CLOSED = 1,
	UNLOADING_OPENING = 2,
	UNLOADING_OPEN = 3,
	UNLOADING_CLOSING = 4,
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("baler", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
}

function Baler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processBalerArea", Baler.processBalerArea)
	SpecializationUtil.registerFunction(vehicleType, "isUnloadingAllowed", Baler.isUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getTimeFromLevel", Baler.getTimeFromLevel)
	SpecializationUtil.registerFunction(vehicleType, "moveBales", Baler.moveBales)
	SpecializationUtil.registerFunction(vehicleType, "moveBale", Baler.moveBale)
	SpecializationUtil.registerFunction(vehicleType, "setIsUnloadingBale", Baler.setIsUnloadingBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleUnloading", Baler.getIsBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "dropBale", Baler.dropBale)
	SpecializationUtil.registerFunction(vehicleType, "finishBale", Baler.finishBale)
	SpecializationUtil.registerFunction(vehicleType, "createBale", Baler.createBale)
	SpecializationUtil.registerFunction(vehicleType, "setBaleTime", Baler.setBaleTime)
	SpecializationUtil.registerFunction(vehicleType, "getCanUnloadUnfinishedBale", Baler.getCanUnloadUnfinishedBale)
	SpecializationUtil.registerFunction(vehicleType, "deleteDummyBale", Baler.deleteDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "createDummyBale", Baler.createDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "handleUnloadingBaleEvent", Baler.handleUnloadingBaleEvent)
	SpecializationUtil.registerFunction(vehicleType, "dropBaleFromPlatform", Baler.dropBaleFromPlatform)
end

function Baler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Baler.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Baler.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Baler.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Baler.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Baler.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Baler.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Baler.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Baler.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", Baler.getIsAttachedTo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", Baler.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Baler.getIsFoldAllowed)
end

function Baler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Baler)
end

function Baler:onLoad(savegame)
	local spec = self.spec_baler

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fillScale#value", "vehicle.baler#fillScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.baler.animationNodes.animationNode", "baler")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baler.balingAnimation#name", "vehicle.turnOnVehicle.turnedOnAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baler.fillParticleSystems", "vehicle.baler.fillEffect with effectClass 'ParticleEffect'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baler.uvScrollParts.uvScrollPart", "vehicle.baler.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baler.balerAlarm", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.alarmTriggers.alarmTrigger.alarmSound")

	spec.fillScale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler#fillScale"), 1)
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#fillUnitIndex"), 1)
	local firstBaleMarker = getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#firstBaleMarker")

	if firstBaleMarker ~= nil then
		local baleAnimCurve = AnimCurve:new(linearInterpolatorN)
		local keyI = 0

		while true do
			local key = string.format("vehicle.baler.baleAnimation.key(%d)", keyI)
			local t = getXMLFloat(self.xmlFile, key .. "#time")
			local x, y, z = StringUtil.getVectorFromString(getXMLString(self.xmlFile, key .. "#pos"))

			if x == nil or y == nil or z == nil then
				break
			end

			local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(self.xmlFile, key .. "#rot"))
			rx = math.rad(Utils.getNoNil(rx, 0))
			ry = math.rad(Utils.getNoNil(ry, 0))
			rz = math.rad(Utils.getNoNil(rz, 0))

			baleAnimCurve:addKeyframe({
				x,
				y,
				z,
				rx,
				ry,
				rz,
				time = t
			})

			keyI = keyI + 1
		end

		if keyI > 0 then
			spec.baleAnimCurve = baleAnimCurve
			spec.firstBaleMarker = firstBaleMarker
		end
	end

	spec.baleAnimRoot, spec.baleAnimRootComponent = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#node"), self.i3dMappings)

	if spec.baleAnimRoot == nil then
		spec.baleAnimRoot = self.components[1].node
		spec.baleAnimRootComponent = self.components[1].node
	end

	if spec.firstBaleMarker == nil then
		local unloadAnimationName = getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationName")
		local closeAnimationName = getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#closeAnimationName")

		if unloadAnimationName ~= nil and closeAnimationName ~= nil then
			if self.getAnimationExists ~= nil then
				if self:getAnimationExists(unloadAnimationName) and self:getAnimationExists(closeAnimationName) then
					spec.baleUnloadAnimationName = unloadAnimationName
					spec.baleUnloadAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationSpeed"), 1)
					spec.baleCloseAnimationName = closeAnimationName
					spec.baleCloseAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#closeAnimationSpeed"), 1)
					spec.automaticDrop = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baler.baleAnimation#automaticDrop"), g_platformSettingsManager:getSetting("automaticBaleDrop", false))
					spec.baleDropAnimTime = getXMLFloat(self.xmlFile, "vehicle.baler.baleAnimation#baleDropAnimTime")

					if spec.baleDropAnimTime == nil then
						spec.baleDropAnimTime = self:getAnimationDuration(spec.baleUnloadAnimationName)
					else
						spec.baleDropAnimTime = spec.baleDropAnimTime * 1000
					end

					spec.baleScaleComponent = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#baleScaleComponent"), 3)
				else
					g_logManager:xmlError(self.configFileName, "Failed to find unload animations '%s' and '%s'.", unloadAnimationName, closeAnimationName)
				end
			else
				g_logManager:xmlError(self.configFileName, "Baler unload animations require AnimatedVehicle specialization.")
			end
		end
	end

	spec.baleTypes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.baler.baleTypes.baleType(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local isRoundBale = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#isRoundBale"), false)
		local width = MathUtil.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#width"), 1.2), 2)
		local height = MathUtil.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#height"), 0.9), 2)
		local length = MathUtil.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#length"), 2.4), 2)
		local diameter = MathUtil.round(Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#diameter"), 1.8), 2)

		table.insert(spec.baleTypes, {
			isRoundBale = isRoundBale,
			width = width,
			height = height,
			length = length,
			diameter = diameter
		})

		i = i + 1
	end

	spec.currentBaleTypeId = 1

	if table.getn(spec.baleTypes) == 0 then
		g_logManager:xmlError(self.configFileName, "No baleTypes definded for baler.")

		spec.baleTypes = nil
	end

	spec.unfinishedBaleThreshold = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#unfinishedBaleThreshold"), 2000)
	spec.canUnloadUnfinishedBale = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baler#canUnloadUnfinishedBale"), false)
	spec.lastBaleFillLevel = nil

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			eject = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "eject", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			door = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "door", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			knotCleaning = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "knotCleaning", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.knotCleaningTimer = 10000
		spec.knotCleaningTime = 120000
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baler.animationNodes", self.components, self, self.i3dMappings)
		spec.unloadAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baler.unloadAnimationNodes", self.components, self, self.i3dMappings)
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.baler.fillEffect", self.components, self, self.i3dMappings)
		spec.fillEffectType = FillType.UNKNOWN
		spec.knotingAnimation = getXMLString(self.xmlFile, "vehicle.baler.knotingAnimation#name")
		spec.knotingAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.knotingAnimation#speed"), 1)
		spec.compactingAnimation = getXMLString(self.xmlFile, "vehicle.baler.compactingAnimation#name")
		spec.compactingAnimationInterval = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.compactingAnimation#interval"), 60) * 1000
		spec.compactingAnimationCompactTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.compactingAnimation#compactTime"), 5) * 1000
		spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
		spec.compactingAnimationTime = spec.compactingAnimationInterval
		spec.compactingAnimationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.compactingAnimation#speed"), 1)
		spec.compactingAnimationMinTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.compactingAnimation#minFillLevelTime"), 1)
		spec.compactingAnimationMaxTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.compactingAnimation#maxFillLevelTime"), 0.1)
	end

	spec.lastAreaBiggerZero = false
	spec.lastAreaBiggerZeroSent = false
	spec.lastAreaBiggerZeroTime = 0
	spec.workAreaParameters = {
		lastPickedUpLiters = 0,
		lastPickedUpFillType = FillType.UNKNOWN
	}
	spec.fillUnitOverflowFillLevel = 0
	spec.maxPickupLitersPerSecond = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.baler#maxPickupLitersPerSecond"), 500)
	spec.pickUpLitersBuffer = ValueBuffer:new(750)
	spec.unloadingState = Baler.UNLOADING_CLOSED
	spec.pickupFillTypes = {}
	spec.bales = {}
	spec.dummyBale = {
		scaleNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#scaleNode"), self.i3dMappings),
		baleNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baler.baleAnimation#baleNode"), self.i3dMappings),
		currentBaleFillType = FillType.UNKNOWN,
		currentBale = nil
	}
	spec.allowsBaleUnloading = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baler.baleUnloading#allowed"), false)
	spec.baleUnloadingTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleUnloading#time"), 4) * 1000
	spec.baleFoldThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baler.baleUnloading#foldThreshold"), 0.25) * self:getFillUnitCapacity(spec.fillUnitIndex)
	spec.platformAnimation = getXMLString(self.xmlFile, "vehicle.baler.platform#animationName")
	spec.platformAnimationNextBaleTime = getXMLString(self.xmlFile, "vehicle.baler.platform#nextBaleTime")
	spec.platformAutomaticDrop = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.baler.platform#automaticDrop"), g_platformSettingsManager:getSetting("automaticBaleDrop", false))
	spec.hasPlatform = spec.platformAnimation ~= nil
	spec.hasDynamicMountPlatform = SpecializationUtil.hasSpecialization(DynamicMountAttacher, self.specializations)
	spec.platformReadyToDrop = false
	spec.platformDropInProgress = false
	spec.platformDelayedDropping = false
	spec.platformMountDelay = -1
	spec.bufferFillUnitIndex = getXMLInt(self.xmlFile, "vehicle.baler.buffer#fillUnitIndex")
	spec.bufferOverloadingSpeed = (getXMLInt(self.xmlFile, "vehicle.baler.buffer#overloadingSpeed") or 500) / 1000
	spec.bufferUnloadingStarted = false
	spec.bufferFillLevelToEmpty = 0
	spec.nonStopBaling = spec.bufferFillUnitIndex ~= nil

	if spec.nonStopBaling ~= nil then
		local fillTypeName = getXMLString(self.xmlFile, "vehicle.baler.buffer#balerDisplayType")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex ~= nil then
			self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, fillTypeIndex, true)
		end
	end

	spec.isBaleUnloading = false
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Baler:onPostLoad(savegame)
	local spec = self.spec_baler

	for fillTypeIndex, enabled in pairs(self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)) do
		if enabled and fillTypeIndex ~= FillType.UNKNOWN and g_fruitTypeManager:isFillTypeWindrow(fillTypeIndex) then
			table.insert(spec.pickupFillTypes, fillTypeIndex)
		end
	end

	if savegame ~= nil and not savegame.resetVehicles then
		local numBales = getXMLInt(savegame.xmlFile, savegame.key .. ".baler#numBales")

		if numBales ~= nil then
			spec.balesToLoad = {}

			for i = 1, numBales do
				local baleKey = string.format("%s.baler.bale(%d)", savegame.key, i - 1)
				local bale = {}
				local fillTypeStr = getXMLString(savegame.xmlFile, baleKey .. "#fillType")
				local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)

				if fillType ~= nil then
					bale.fillType = fillType.index
					bale.fillLevel = getXMLFloat(savegame.xmlFile, baleKey .. "#fillLevel")
					bale.baleTime = getXMLFloat(savegame.xmlFile, baleKey .. "#baleTime")

					table.insert(spec.balesToLoad, bale)
				end
			end
		end

		if spec.hasPlatform then
			spec.platformReadyToDrop = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#platformReadyToDrop"), spec.platformReadyToDrop)

			if spec.platformReadyToDrop then
				self:setAnimationTime(spec.platformAnimation, 1, true)
				self:setAnimationTime(spec.platformAnimation, 0, true)

				spec.platformMountDelay = 1
			end
		end
	end
end

function Baler:onDelete()
	local spec = self.spec_baler

	if self.isReconfigurating == nil or not self.isReconfigurating then
		for k, _ in pairs(spec.bales) do
			self:dropBale(k)
		end
	end

	self:deleteDummyBale()

	if self.isClient then
		g_soundManager:deleteSamples(spec.samples)
		g_effectManager:deleteEffects(spec.fillEffects)
		g_animationManager:deleteAnimations(spec.animationNodes)
		g_animationManager:deleteAnimations(spec.unloadAnimationNodes)
	end
end

function Baler:saveToXMLFile(xmlFile, key, usedModNames)
	if self.isReconfigurating == nil or not self.isReconfigurating then
		local spec = self.spec_baler

		if spec.baleUnloadAnimationName == nil or self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
			setXMLInt(xmlFile, key .. "#numBales", #spec.bales)

			for k, bale in ipairs(spec.bales) do
				local baleKey = string.format("%s.bale(%d)", key, k - 1)
				local fillTypeStr = "UNKNOWN"

				if bale.fillType ~= FillType.UNKNOWN then
					fillTypeStr = g_fillTypeManager:getFillTypeNameByIndex(bale.fillType)
				end

				setXMLString(xmlFile, baleKey .. "#fillType", fillTypeStr)
				setXMLFloat(xmlFile, baleKey .. "#fillLevel", bale.fillLevel)

				if spec.baleAnimCurve ~= nil then
					setXMLFloat(xmlFile, baleKey .. "#baleTime", bale.time)
				end
			end
		end

		if spec.hasPlatform then
			setXMLBool(xmlFile, key .. "#platformReadyToDrop", spec.platformReadyToDrop)
		end
	end
end

function Baler:onReadStream(streamId, connection)
	local spec = self.spec_baler

	if spec.baleUnloadAnimationName ~= nil then
		local state = streamReadUIntN(streamId, 7)
		local animTime = streamReadFloat32(streamId)

		if state == Baler.UNLOADING_CLOSED or state == Baler.UNLOADING_CLOSING then
			self:setIsUnloadingBale(false, true)
			self:setRealAnimationTime(spec.baleCloseAnimationName, animTime)
		elseif state == Baler.UNLOADING_OPEN or state == Baler.UNLOADING_OPENING then
			self:setIsUnloadingBale(true, true)
			self:setRealAnimationTime(spec.baleUnloadAnimationName, animTime)
		end
	end

	local numBales = streamReadUInt8(streamId)

	for i = 1, numBales do
		local fillType = streamReadInt8(streamId)
		local fillLevel = streamReadFloat32(streamId)

		self:createBale(fillType, fillLevel)

		if spec.baleAnimCurve ~= nil then
			local baleTime = streamReadFloat32(streamId)

			self:setBaleTime(i, baleTime)
		end
	end

	spec.lastAreaBiggerZero = streamReadBool(streamId)

	if spec.hasPlatform then
		spec.platformReadyToDrop = streamReadBool(streamId)

		if spec.platformReadyToDrop then
			self:setAnimationTime(spec.platformAnimation, 1, true)
			self:setAnimationTime(spec.platformAnimation, 0, true)
		end
	end
end

function Baler:onWriteStream(streamId, connection)
	local spec = self.spec_baler

	if spec.baleUnloadAnimationName ~= nil then
		streamWriteUIntN(streamId, spec.unloadingState, 7)

		local animTime = 0

		if spec.unloadingState == Baler.UNLOADING_CLOSED or spec.unloadingState == Baler.UNLOADING_CLOSING then
			animTime = self:getRealAnimationTime(spec.baleCloseAnimationName)
		elseif spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_OPENING then
			animTime = self:getRealAnimationTime(spec.baleUnloadAnimationName)
		end

		streamWriteFloat32(streamId, animTime)
	end

	streamWriteUInt8(streamId, table.getn(spec.bales))

	for i = 1, table.getn(spec.bales) do
		local bale = spec.bales[i]

		streamWriteInt8(streamId, bale.fillType)
		streamWriteFloat32(streamId, bale.fillLevel)

		if spec.baleAnimCurve ~= nil then
			streamWriteFloat32(streamId, bale.time)
		end
	end

	streamWriteBool(streamId, spec.lastAreaBiggerZero)

	if spec.hasPlatform then
		streamWriteBool(streamId, spec.platformReadyToDrop)
	end
end

function Baler:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_baler

	if connection:getIsServer() then
		spec.lastAreaBiggerZero = streamReadBool(streamId)
		spec.fillEffectType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	end
end

function Baler:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_baler

	if not connection:getIsServer() then
		streamWriteBool(streamId, spec.lastAreaBiggerZero)
		streamWriteUIntN(streamId, spec.fillEffectTypeSent, FillTypeManager.SEND_NUM_BITS)
	end
end

function Baler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baler

	if self.firstTimeRun and spec.balesToLoad ~= nil and table.getn(spec.balesToLoad) > 0 then
		local v = spec.balesToLoad[1]

		if v.targetBaleTime == nil then
			self:createBale(v.fillType, v.fillLevel)
			self:setBaleTime(table.getn(spec.bales), 0, true)

			v.targetBaleTime = v.baleTime
			v.baleTime = 0
		else
			v.baleTime = math.min(v.baleTime + dt / 1000, v.targetBaleTime)

			self:setBaleTime(table.getn(spec.bales), v.baleTime, true)

			if v.baleTime == v.targetBaleTime then
				local index = table.getn(spec.balesToLoad)

				if index == 1 then
					spec.balesToLoad = nil
				else
					table.remove(spec.balesToLoad, 1)
				end
			end
		end
	end

	if self.isServer and self.isAddedToPhysics and spec.createBaleNextFrame ~= nil and spec.createBaleNextFrame then
		self:finishBale()

		spec.createBaleNextFrame = nil
	end
end

function Baler:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baler

	if self:getIsTurnedOn() then
		if self.isClient then
			if spec.lastAreaBiggerZero and spec.fillEffectType ~= FillType.UNKNOWN then
				spec.lastAreaBiggerZeroTime = 500
			elseif spec.lastAreaBiggerZeroTime > 0 then
				spec.lastAreaBiggerZeroTime = math.max(spec.lastAreaBiggerZeroTime - dt, 0)
			end

			if spec.lastAreaBiggerZeroTime > 0 then
				g_effectManager:setFillType(spec.fillEffects, spec.fillEffectType)
				g_effectManager:startEffects(spec.fillEffects)
			else
				g_effectManager:stopEffects(spec.fillEffects)
			end

			if spec.knotCleaningTimer <= g_currentMission.time then
				g_soundManager:playSample(spec.samples.knotCleaning)

				spec.knotCleaningTimer = g_currentMission.time + spec.knotCleaningTime
			end

			if spec.compactingAnimation ~= nil and spec.unloadingState == Baler.UNLOADING_CLOSED then
				if spec.compactingAnimationTime <= g_currentMission.time then
					local fillLevel = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
					local stopTime = MathUtil.lerp(spec.compactingAnimationMinTime, spec.compactingAnimationMaxTime, fillLevel)

					if stopTime > 0 then
						self:setAnimationStopTime(spec.compactingAnimation, MathUtil.clamp(stopTime, 0, 1))
						self:playAnimation(spec.compactingAnimation, spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)

						spec.compactingAnimationTime = math.huge
					end
				end

				if spec.compactingAnimationTime == math.huge and not self:getIsAnimationPlaying(spec.compactingAnimation) then
					spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTimer - dt

					if spec.compactingAnimationCompactTimer < 0 then
						self:playAnimation(spec.compactingAnimation, -spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)

						spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
					end

					if self:getAnimationTime(spec.compactingAnimation) == 0 then
						spec.compactingAnimationTime = g_currentMission.time + spec.compactingAnimationInterval
					end
				end
			end
		end
	elseif spec.isBaleUnloading and self.isServer then
		local deltaTime = dt / spec.baleUnloadingTime

		self:moveBales(deltaTime)
	end

	if self.isClient and spec.unloadingState == Baler.UNLOADING_OPEN and getNumOfChildren(spec.baleAnimRoot) > 0 then
		delete(getChildAt(spec.baleAnimRoot, 0))
	end

	if spec.unloadingState == Baler.UNLOADING_OPENING then
		local isPlaying = self:getIsAnimationPlaying(spec.baleUnloadAnimationName)
		local animTime = self:getRealAnimationTime(spec.baleUnloadAnimationName)

		if not isPlaying or spec.baleDropAnimTime <= animTime then
			if table.getn(spec.bales) > 0 then
				self:dropBale(1)

				if self.isServer then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)
				end
			end

			if not isPlaying then
				spec.unloadingState = Baler.UNLOADING_OPEN

				if self.isClient then
					g_soundManager:stopSample(spec.samples.eject)
					g_soundManager:stopSample(spec.samples.door)
					g_animationManager:stopAnimations(spec.unloadAnimationNodes)
				end
			end
		else
			g_animationManager:startAnimations(spec.unloadAnimationNodes)
		end
	elseif spec.unloadingState == Baler.UNLOADING_CLOSING and not self:getIsAnimationPlaying(spec.baleCloseAnimationName) then
		spec.unloadingState = Baler.UNLOADING_CLOSED

		if self.isClient then
			g_soundManager:stopSample(spec.samples.door)
		end
	end

	if (spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_CLOSING) and not self.isServer and table.getn(spec.bales) > 0 then
		self:dropBale(1)
	end

	local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

	if actionEvent ~= nil then
		local showAction = false

		if self:isUnloadingAllowed() and (spec.baleUnloadAnimationName ~= nil or spec.allowsBaleUnloading) then
			if spec.unloadingState == Baler.UNLOADING_CLOSED then
				if self:getCanUnloadUnfinishedBale() then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_unloadUnfinishedBale"))

					showAction = true
				end

				if table.getn(spec.bales) > 0 then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_unloadBaler"))

					showAction = true
				end
			elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.baleUnloadAnimationName ~= nil then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_closeBack"))

				showAction = true
			end
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
	end

	if self.isServer then
		if (spec.automaticDrop ~= nil and spec.automaticDrop or self:getIsAIActive()) and self:isUnloadingAllowed() and (spec.baleUnloadAnimationName ~= nil or spec.allowsBaleUnloading) then
			if spec.unloadingState == Baler.UNLOADING_CLOSED then
				if table.getn(spec.bales) > 0 then
					self:setIsUnloadingBale(true)
				end
			elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.baleUnloadAnimationName ~= nil then
				self:setIsUnloadingBale(false)
			end
		end

		spec.pickUpLitersBuffer:add(spec.workAreaParameters.lastPickedUpLiters)

		if spec.platformAutomaticDrop and spec.platformReadyToDrop then
			self:dropBaleFromPlatform(true)
		end

		if spec.hasPlatform then
			if #spec.bales > 0 and spec.platformReadyToDrop then
				self:dropBaleFromPlatform(true)
			end

			if spec.nonStopBaling then
				local bufferLevel = self:getFillUnitFillLevel(spec.bufferFillUnitIndex)

				if bufferLevel > 0 then
					if bufferLevel == self:getFillUnitCapacity(spec.bufferFillUnitIndex) and not spec.bufferUnloadingStarted and spec.unloadingState == Baler.UNLOADING_CLOSED then
						spec.bufferUnloadingStarted = true
					end

					if spec.bufferUnloadingStarted then
						local delta = math.min(spec.bufferOverloadingSpeed * dt, bufferLevel)
						local fillType = self:getFillUnitFillType(spec.bufferFillUnitIndex)

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.bufferFillUnitIndex, -delta, fillType, ToolType.UNDEFINED, nil)
						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, fillType, ToolType.UNDEFINED, nil)

						if spec.bufferFillLevelToEmpty > 0 then
							spec.bufferFillLevelToEmpty = math.max(spec.bufferFillLevelToEmpty - delta, 0)

							if spec.bufferFillLevelToEmpty == 0 then
								spec.platformDelayedDropping = true
								spec.bufferUnloadingStarted = false
							end
						end

						if self:getFillUnitFillLevelPercentage(spec.fillUnitIndex) == 1 then
							spec.bufferUnloadingStarted = false
						end
					end
				else
					spec.bufferUnloadingStarted = false
				end
			end

			if spec.hasDynamicMountPlatform then
				if spec.platformMountDelay > 0 then
					spec.platformMountDelay = spec.platformMountDelay - 1

					if spec.platformMountDelay == 0 then
						self:forceDynamicMountPendingObjects(true)
					end
				elseif spec.platformReadyToDrop and not self:getHasDynamicMountedObjects() then
					self:dropBaleFromPlatform(false)
				end
			end
		end
	end

	if spec.hasPlatform then
		if spec.platformDelayedDropping and not spec.platformDropInProgress then
			Baler.actionEventUnloading(self)

			spec.platformDelayedDropping = false
		end

		if spec.platformDropInProgress and not self:getIsAnimationPlaying(spec.platformAnimation) then
			spec.platformDropInProgress = false
		end
	end
end

function Baler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_baler

	if table.getn(spec.bales) > 0 and spec.baleFoldThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex) then
		return false
	end

	if table.getn(spec.bales) > 1 then
		return false
	end

	if self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Baler:onDeactivate()
	local spec = self.spec_baler

	if self.isClient then
		g_effectManager:stopEffects(spec.fillEffects)
		g_soundManager:stopSamples(spec.samples)
	end
end

function Baler:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_baler

	if fillUnitIndex == spec.fillUnitIndex then
		local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
		local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)

		if spec.dummyBale.baleNode ~= nil and fillLevel > 0 and fillLevel < capacity and (spec.dummyBale.currentBale == nil or spec.dummyBale.currentBaleFillType ~= fillTypeIndex) then
			if spec.dummyBale.currentBale ~= nil then
				self:deleteDummyBale()
			end

			local t = spec.baleTypes[spec.currentBaleTypeId]
			local baleType = g_baleTypeManager:getBale(fillTypeIndex, t.isRoundBale, t.width, t.height, t.length, t.diameter)

			self:createDummyBale(baleType, fillTypeIndex)
		end

		if spec.dummyBale.currentBale ~= nil then
			local percentage = fillLevel / capacity
			local x = 1
			local y = getUserAttribute(spec.dummyBale.currentBale, "isRoundbale") and percentage or 1
			local z = percentage

			if spec.baleScaleComponent ~= nil then
				z = 1
				y = 1
				x = 1

				for axis, value in ipairs(spec.baleScaleComponent) do
					if value > 0 then
						if axis == 1 then
							x = percentage
						elseif axis == 2 then
							y = percentage
						else
							z = percentage
						end
					end
				end
			end

			setScale(spec.dummyBale.scaleNode, x, y, z)
		end

		if self.isServer then
			if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
				if self.isAddedToPhysics then
					self:finishBale()
				else
					spec.createBaleNextFrame = true
				end

				spec.fillUnitOverflowFillLevel = fillLevelDelta - appliedDelta
			elseif spec.fillUnitOverflowFillLevel > 0 and fillLevelDelta > 0 then
				local overflow = spec.fillUnitOverflowFillLevel
				spec.fillUnitOverflowFillLevel = 0
				overflow = overflow - self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, overflow, fillTypeIndex, toolType)
				spec.fillUnitOverflowFillLevel = overflow
			end
		end
	end
end

function Baler:onTurnedOn()
	if self.setFoldState ~= nil then
		self:setFoldState(-1, false)
	end

	if self.isClient then
		local spec = self.spec_baler

		g_animationManager:startAnimations(spec.animationNodes)
		g_soundManager:playSample(spec.samples.work)
	end
end

function Baler:onTurnedOff()
	if self.isClient then
		local spec = self.spec_baler

		g_effectManager:stopEffects(spec.fillEffects)
		g_animationManager:stopAnimations(spec.animationNodes)
		g_soundManager:stopSamples(spec.samples)
	end
end

function Baler:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_baler
	spec.controlledAction = self:getRootVehicle().actionController:registerAction("baleUnload", nil, 1)

	spec.controlledAction:setCallback(self, Baler.actionControllerBaleUnloadEvent)
	spec.controlledAction:setFinishedFunctions(self, Baler.getIsBaleUnloading, false, false)
end

function Baler:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_baler

	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function Baler:actionControllerBaleUnloadEvent(direction)
	if direction < 0 then
		local spec = self.spec_baler

		if self:isUnloadingAllowed() and spec.allowsBaleUnloading and spec.unloadingState == Baler.UNLOADING_CLOSED and table.getn(spec.bales) > 0 then
			self:setIsUnloadingBale(true)
		end
	end
end

function Baler:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self:getIsLowered()
end

function Baler:isUnloadingAllowed()
	local spec = self.spec_baler

	if self.spec_baleWrapper == nil then
		return not spec.allowsBaleUnloading or spec.allowsBaleUnloading and not self:getIsTurnedOn() and not spec.isBaleUnloading
	end

	if (spec.platformReadyToDrop or spec.platformDropInProgress) and self.spec_baler.unloadingState ~= Baler.UNLOADING_OPEN then
		return false
	end

	return self:allowsGrabbingBale()
end

function Baler:handleUnloadingBaleEvent()
	local spec = self.spec_baler

	if self:isUnloadingAllowed() and (spec.baleUnloadAnimationName ~= nil or spec.allowsBaleUnloading) then
		if spec.unloadingState == Baler.UNLOADING_CLOSED then
			if table.getn(spec.bales) > 0 or self:getCanUnloadUnfinishedBale() then
				self:setIsUnloadingBale(true)
			end
		elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.baleUnloadAnimationName ~= nil then
			self:setIsUnloadingBale(false)
		end
	end
end

function Baler:dropBaleFromPlatform(waitForNextBale, noEventSend)
	local spec = self.spec_baler

	if spec.platformReadyToDrop then
		self:setAnimationTime(spec.platformAnimation, 0, false)
		self:playAnimation(spec.platformAnimation, 1, self:getAnimationTime(spec.platformAnimation), true)

		if waitForNextBale == true then
			self:setAnimationStopTime(spec.platformAnimation, spec.platformAnimationNextBaleTime)
		end

		spec.platformReadyToDrop = false
		spec.platformDropInProgress = true

		if self.isServer and spec.hasDynamicMountPlatform then
			self:forceUnmountDynamicMountedObjects()
		end
	end

	BalerDropFromPlatformEvent.sendEvent(self, waitForNextBale, noEventSend)
end

function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
	local spec = self.spec_baler

	if spec.baleUnloadAnimationName ~= nil then
		if isUnloadingBale then
			if spec.unloadingState ~= Baler.UNLOADING_OPENING then
				if table.getn(spec.bales) == 0 and spec.canUnloadUnfinishedBale and spec.unfinishedBaleThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex) then
					local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
					local currentFillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
					local delta = self:getFillUnitFreeCapacity(spec.fillUnitIndex)
					spec.lastBaleFillLevel = currentFillLevel

					self:setFillUnitFillLevelToDisplay(spec.fillUnitIndex, currentFillLevel)
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, fillTypeIndex, ToolType.UNDEFINED)
				end

				BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

				spec.unloadingState = Baler.UNLOADING_OPENING

				if self.isClient then
					g_soundManager:playSample(spec.samples.eject)
					g_soundManager:playSample(spec.samples.door)
				end

				self:playAnimation(spec.baleUnloadAnimationName, spec.baleUnloadAnimationSpeed, nil, true)
			end
		elseif spec.unloadingState ~= Baler.UNLOADING_CLOSING then
			BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

			spec.unloadingState = Baler.UNLOADING_CLOSING

			if self.isClient then
				g_soundManager:playSample(spec.samples.door)
			end

			self:playAnimation(spec.baleCloseAnimationName, spec.baleCloseAnimationSpeed, nil, true)
		end
	elseif spec.allowsBaleUnloading and isUnloadingBale then
		BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

		spec.isBaleUnloading = true
	end
end

function Baler:getIsBaleUnloading()
	return self.spec_baler.isBaleUnloading
end

function Baler:getTimeFromLevel(level)
	local spec = self.spec_baler

	if spec.firstBaleMarker ~= nil then
		return level / self:getFillUnitCapacity(spec.fillUnitIndex) * spec.firstBaleMarker
	end

	return 0
end

function Baler:moveBales(dt)
	local spec = self.spec_baler

	for i = table.getn(spec.bales), 1, -1 do
		self:moveBale(i, dt)
	end
end

function Baler:moveBale(i, dt, noEventSend)
	local spec = self.spec_baler
	local bale = spec.bales[i]

	self:setBaleTime(i, bale.time + dt, noEventSend)
end

function Baler:setBaleTime(i, baleTime, noEventSend)
	local spec = self.spec_baler

	if spec.baleAnimCurve ~= nil then
		local bale = spec.bales[i]
		bale.time = baleTime

		if self.isServer then
			local v = spec.baleAnimCurve:get(bale.time)

			setTranslation(bale.baleJointNode, v[1], v[2], v[3])
			setRotation(bale.baleJointNode, v[4], v[5], v[6])

			if bale.baleJointIndex ~= 0 then
				setJointFrame(bale.baleJointIndex, 0, bale.baleJointNode)
			end
		end

		if bale.time >= 1 then
			self:dropBale(i)
		end

		if table.getn(spec.bales) == 0 then
			spec.isBaleUnloading = false
		end

		if self.isServer and (noEventSend == nil or not noEventSend) then
			g_server:broadcastEvent(BalerSetBaleTimeEvent:new(self, i, bale.time), nil, , self)
		end
	end
end

function Baler:finishBale()
	local spec = self.spec_baler

	if spec.baleTypes ~= nil then
		local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)

		if spec.baleAnimCurve ~= nil then
			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, fillTypeIndex, ToolType.UNDEFINED)
			self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex))

			local numBales = table.getn(spec.bales)
			local bale = spec.bales[numBales]

			g_server:broadcastEvent(BalerCreateBaleEvent:new(self, fillTypeIndex, bale.time), nil, , self)
		elseif spec.baleUnloadAnimationName ~= nil then
			self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex))
			g_server:broadcastEvent(BalerCreateBaleEvent:new(self, fillTypeIndex, 0), nil, , self)
		end
	end
end

function Baler:createBale(baleFillType, fillLevel)
	local spec = self.spec_baler

	if spec.knotingAnimation ~= nil then
		self:playAnimation(spec.knotingAnimation, spec.knotingAnimationSpeed, nil, true)
	end

	self:deleteDummyBale()

	local t = spec.baleTypes[spec.currentBaleTypeId]
	local baleType = g_baleTypeManager:getBale(baleFillType, t.isRoundBale, t.width, t.height, t.length, t.diameter)
	local bale = {
		filename = baleType.filename,
		time = 0,
		fillType = baleFillType,
		fillLevel = fillLevel
	}

	if spec.baleUnloadAnimationName ~= nil then
		local baleRoot = g_i3DManager:loadSharedI3DFile(baleType.filename, nil, false, false)
		local baleId = getChildAt(baleRoot, 0)

		link(spec.baleAnimRoot, baleId)
		delete(baleRoot)

		bale.id = baleId
	end

	if self.isServer and spec.baleUnloadAnimationName == nil then
		local x, y, z = getWorldTranslation(spec.baleAnimRoot)
		local rx, ry, rz = getWorldRotation(spec.baleAnimRoot)
		local baleObject = Bale:new(self.isServer, self.isClient)

		baleObject:load(bale.filename, x, y, z, rx, ry, rz, bale.fillLevel)
		baleObject:setOwnerFarmId(self:getActiveFarm(), true)
		baleObject:register()
		baleObject:setCanBeSold(false)

		local baleJointNode = createTransformGroup("BaleJointTG")

		link(spec.baleAnimRoot, baleJointNode)
		setTranslation(baleJointNode, 0, 0, 0)
		setRotation(baleJointNode, 0, 0, 0)

		local constr = JointConstructor:new()

		constr:setActors(spec.baleAnimRootComponent, baleObject.nodeId)
		constr:setJointTransforms(baleJointNode, baleObject.nodeId)

		for i = 1, 3 do
			constr:setRotationLimit(i - 1, 0, 0)
			constr:setTranslationLimit(i - 1, true, 0, 0)
		end

		constr:setEnableCollision(false)

		local baleJointIndex = constr:finalize()

		g_currentMission:removeItemToSave(baleObject)

		bale.baleJointNode = baleJointNode
		bale.baleJointIndex = baleJointIndex
		bale.baleObject = baleObject
	end

	table.insert(spec.bales, bale)
end

function Baler:dropBale(baleIndex)
	local spec = self.spec_baler
	local bale = spec.bales[baleIndex]

	if self.isServer then
		local baleObject = nil

		if bale.baleJointIndex ~= nil then
			baleObject = bale.baleObject

			removeJoint(bale.baleJointIndex)
			delete(bale.baleJointNode)
			g_currentMission:addItemToSave(bale.baleObject)
		else
			baleObject = Bale:new(self.isServer, self.isClient)
			local x, y, z = getWorldTranslation(bale.id)
			local rx, ry, rz = getWorldRotation(bale.id)

			baleObject:load(bale.filename, x, y, z, rx, ry, rz, bale.fillLevel)
			baleObject:setOwnerFarmId(self:getActiveFarm(), true)
			baleObject:register()
		end

		if spec.lastBaleFillLevel ~= nil and #spec.bales == 1 then
			baleObject:setFillLevel(spec.lastBaleFillLevel)

			spec.lastBaleFillLevel = nil
		end

		baleObject:setCanBeSold(true)

		if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
			local x, y, z = getWorldTranslation(baleObject.nodeId)
			local vx, vy, vz = getVelocityAtWorldPos(spec.baleAnimRootComponent, x, y, z)

			setLinearVelocity(baleObject.nodeId, vx, vy, vz)
		end

		g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "baleCount", 1)
	end

	if bale.id ~= nil and entityExists(bale.id) then
		delete(bale.id)

		bale.id = nil

		g_i3DManager:releaseSharedI3DFile(bale.filename, nil, true)
	end

	table.remove(spec.bales, baleIndex)

	if spec.hasPlatform then
		if not spec.platformReadyToDrop then
			spec.platformReadyToDrop = true
		end

		if spec.hasDynamicMountPlatform then
			spec.platformMountDelay = 5
		end
	end
end

function Baler:deleteDummyBale()
	local spec = self.spec_baler

	if spec.dummyBale.currentBale ~= nil then
		delete(spec.dummyBale.currentBale)
		g_i3DManager:releaseSharedI3DFile(spec.dummyBale.currentFilename, nil, true)

		spec.dummyBale.currentBale = nil
	end
end

function Baler:createDummyBale(baleType, fillTypeIndex)
	local spec = self.spec_baler
	local baleRoot = g_i3DManager:loadSharedI3DFile(baleType.filename, nil, false, false)
	local baleId = getChildAt(baleRoot, 0)

	setRigidBodyType(baleId, "NoRigidBody")
	link(spec.dummyBale.baleNode, baleId)
	delete(baleRoot)

	spec.dummyBale.currentBale = baleId
	spec.dummyBale.currentBaleFillType = fillTypeIndex
	spec.dummyBale.currentFilename = baleType.filename
end

function Baler:getCanUnloadUnfinishedBale()
	local spec = self.spec_baler

	return spec.canUnloadUnfinishedBale and spec.unfinishedBaleThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex)
end

function Baler:getCanBeTurnedOn(superFunc)
	local spec = self.spec_baler

	if spec.isBaleUnloading then
		return false
	end

	return superFunc(self)
end

function Baler:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	speedRotatingPart.rotateOnlyIfFillLevelIncreased = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotateOnlyIfFillLevelIncreased"), false)

	return superFunc(self, speedRotatingPart, xmlFile, key)
end

function Baler:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_baler

	if speedRotatingPart.rotateOnlyIfFillLevelIncreased ~= nil and speedRotatingPart.rotateOnlyIfFillLevelIncreased and spec.lastAreaBiggerZeroTime == 0 then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Baler.getDefaultSpeedLimit()
	return 25
end

function Baler:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_baler

	if not g_currentMission:getCanAddLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE) and self:getIsTurnedOn() then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyBales"), 500)

		return false
	end

	if self:getFillUnitFreeCapacity(spec.bufferFillUnitIndex or spec.fillUnitIndex) == 0 then
		return false
	end

	if self.allowPickingUp ~= nil and not self:allowPickingUp() then
		return false
	end

	if spec.baleUnloadAnimationName ~= nil and not spec.nonStopBaling and (table.getn(spec.bales) > 0 or spec.unloadingState ~= Baler.UNLOADING_CLOSED) then
		return false
	end

	return superFunc(self, workArea)
end

function Baler:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local spec = self.spec_baler
	local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond

	return value + loadPercentage, count + 1
end

function Baler:getCanBeSelected(superFunc)
	return true
end

function Baler:getIsAttachedTo(superFunc, vehicle)
	if superFunc(self, vehicle) then
		return true
	end

	local spec = self.spec_baler

	for i = 1, #spec.bales do
		if spec.bales[i].baleObject == vehicle then
			return true
		end
	end

	return false
end

function Baler:getAllowDynamicMountFillLevelInfo(superFunc)
	return false
end

function Baler:getIsFoldAllowed(superFunc, ...)
	local spec = self.spec_baler

	if spec.hasPlatform and (spec.platformReadyToDrop or spec.platformDropInProgress) then
		return false
	end

	return superFunc(self, ...)
end

function Baler:processBalerArea(workArea, dt)
	local spec = self.spec_baler
	local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	local currentFillType = self:getFillUnitFillType(spec.fillUnitIndex)

	if self.isServer then
		spec.fillEffectType = FillType.UNKNOWN
	end

	for _, fillTypeIndex in ipairs(spec.pickupFillTypes) do
		local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, , false, nil)

		if pickedUpLiters > 0 then
			if self.isServer then
				spec.fillEffectType = fillTypeIndex
			end

			if currentFillType == FillType.UNKNOWN then
				spec.workAreaParameters.lastPickedUpFillType = fillTypeIndex
				currentFillType = fillTypeIndex
			end

			spec.workAreaParameters.lastPickedUpFillType = currentFillType
			spec.workAreaParameters.lastPickedUpLiters = spec.workAreaParameters.lastPickedUpLiters + pickedUpLiters

			return pickedUpLiters, pickedUpLiters
		end
	end

	return 0, 0
end

function Baler:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_baler

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and not spec.automaticDrop then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Baler.actionEventUnloading, false, true, false, true, nil)

			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_closeCover"))
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		end
	end
end

function Baler:onStartWorkAreaProcessing(dt)
	local spec = self.spec_baler

	if self.isServer then
		spec.lastAreaBiggerZero = false
		spec.workAreaParameters.lastPickedUpLiters = 0
		spec.workAreaParameters.lastPickedUpFillType = FillType.UNKNOWN
	end
end

function Baler:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_baler

	if self.isServer then
		local pickedUpLiters = spec.workAreaParameters.lastPickedUpLiters
		local pickedUpFillType = spec.workAreaParameters.lastPickedUpFillType

		if pickedUpLiters > 0 then
			spec.lastAreaBiggerZero = true

			if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
				self:raiseDirtyFlags(spec.dirtyFlag)

				spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
			end

			local deltaLevel = pickedUpLiters * spec.fillScale

			if spec.baleUnloadAnimationName == nil then
				local deltaTime = self:getTimeFromLevel(deltaLevel)

				self:moveBales(deltaTime)
			end

			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, deltaLevel, pickedUpFillType, ToolType.UNDEFINED)
		end

		if spec.fillEffectType ~= spec.fillEffectTypeSent then
			spec.fillEffectTypeSent = spec.fillEffectType

			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end
end

function Baler:actionEventUnloading(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_baler

	if not spec.hasPlatform then
		self:handleUnloadingBaleEvent()
	else
		self:dropBaleFromPlatform(false)
	end
end
