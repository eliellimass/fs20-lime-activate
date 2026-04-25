Windrower = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("windrower", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Windrower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRakeFromXML", Windrower.loadRakeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateRake", Windrower.updateRake)
	SpecializationUtil.registerFunction(vehicleType, "processWindrowerArea", Windrower.processWindrowerArea)
	SpecializationUtil.registerFunction(vehicleType, "processDropArea", Windrower.processDropArea)
end

function Windrower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Windrower.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Windrower.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Windrower.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Windrower.getWearMultiplier)
end

function Windrower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Windrower)
end

function Windrower:onLoad(savegame)
	local spec = self.spec_windrower

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.animation", "vehicle.windrowers.windrower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.windrowers.windrower", "vehicle.windrower.rakes.rake")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.windrowerParticleSystems", "vehicle.windrower.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.windrower.animationNodes.animationNode", "windrower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.windrowerSound", "vehicle.windrower.sounds.work")

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.windrower.animationNodes", self.components, self, self.i3dMappings)
		spec.effects = {}
		spec.workAreaToEffects = {}
		local i = 0

		while true do
			local key = string.format("vehicle.windrower.effects.effect(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local effects = g_effectManager:loadEffect(self.xmlFile, key, self.components, self, self.i3dMappings)

			if effects ~= nil then
				local effect = {
					effects = effects,
					workAreaIndex = Utils.getNoNil(getXMLInt(self.xmlFile, key .. "#workAreaIndex"), 1),
					activeTime = -1,
					activeTimeDuration = 250,
					isActive = false,
					isActiveSent = false
				}

				table.insert(spec.effects, effect)
			end

			i = i + 1
		end

		spec.rakes = {}
		local i = 0

		while true do
			local key = string.format("vehicle.windrower.rakes.rake(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local rake = {}

			if self:loadRakeFromXML(rake, self.xmlFile, key, i) then
				table.insert(spec.rakes, rake)
				self:updateRake(rake)
			end

			i = i + 1
		end

		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.windrower.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.isWorking = false
	spec.limitToLineHeight = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.windrower#limitToLineHeight"), false)
	spec.fillTypesDirtyFlag = self:getNextDirtyFlag()
	spec.effectDirtyFlag = self:getNextDirtyFlag()

	if self.addAIFruitRequirement ~= nil then
		self:addAIFruitRequirement(FruitType.GRASS, 0, g_currentMission.terrainDetailHeightTypeNumChannels)
		self:addAIFruitRequirement(FruitType.DRYGRASS, 0, g_currentMission.terrainDetailHeightTypeNumChannels)
		self:addAIFruitRequirement(FruitType.WHEAT, 0, g_currentMission.terrainDetailHeightTypeNumChannels)
		self:addAIFruitRequirement(FruitType.BARLEY, 0, g_currentMission.terrainDetailHeightTypeNumChannels)
		self:setAIFruitExtraRequirements(true, true)
	end
end

function Windrower:onPostLoad(savegame)
	local spec = self.spec_windrower

	for i = #spec.effects, 1, -1 do
		local effect = spec.effects[i]
		local workArea = self:getWorkAreaByIndex(effect.workAreaIndex)

		if workArea ~= nil then
			effect.windrowerWorkAreaFillTypeIndex = workArea.windrowerWorkAreaIndex

			if spec.workAreaToEffects[workArea.index] == nil then
				spec.workAreaToEffects[workArea.index] = {}
			end

			table.insert(spec.workAreaToEffects[workArea.index], effect)
		else
			g_logManager:xmlWarning(self.xmlFileName, "Invalid workAreaIndex '%d' for effect 'vehicle.windrower.effects.effect(%d)'!", effect.workAreaIndex, i)
			table.insert(spec.effects, i)
		end
	end
end

function Windrower:onDelete()
	local spec = self.spec_windrower

	if self.isClient then
		for _, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end

		g_animationManager:deleteAnimations(spec.animationNodes)

		for _, effect in ipairs(spec.effects) do
			g_effectManager:deleteEffects(effect.effects)
		end
	end
end

function Windrower:onReadStream(streamId, connection)
	local spec = self.spec_windrower

	for index, _ in ipairs(spec.windrowerWorkAreaFillTypes) do
		local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		spec.windrowerWorkAreaFillTypes[index] = fillType
	end

	for _, effect in ipairs(spec.effects) do
		if streamReadBool(streamId) then
			local fillType = spec.windrowerWorkAreaFillTypes[effect.windrowerWorkAreaFillTypeIndex]

			g_effectManager:setFillType(effect.effects, fillType)
			g_effectManager:startEffects(effect.effects)
		else
			g_effectManager:stopEffects(effect.effects)
		end
	end
end

function Windrower:onWriteStream(streamId, connection)
	local spec = self.spec_windrower

	for _, fillTypeIndex in ipairs(spec.windrowerWorkAreaFillTypes) do
		streamWriteUIntN(streamId, fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
	end

	for _, effect in ipairs(spec.effects) do
		streamWriteBool(streamId, effect.isActiveSent)
	end
end

function Windrower:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_windrower

		if streamReadBool(streamId) then
			for index, _ in ipairs(spec.windrowerWorkAreaFillTypes) do
				local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
				spec.windrowerWorkAreaFillTypes[index] = fillType
			end
		end

		if streamReadBool(streamId) then
			for _, effect in ipairs(spec.effects) do
				if streamReadBool(streamId) then
					local fillType = spec.windrowerWorkAreaFillTypes[effect.windrowerWorkAreaFillTypeIndex]

					g_effectManager:setFillType(effect.effects, fillType)
					g_effectManager:startEffects(effect.effects)
				else
					g_effectManager:stopEffects(effect.effects)
				end
			end
		end
	end
end

function Windrower:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_windrower

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.fillTypesDirtyFlag) ~= 0) then
			for _, fillTypeIndex in ipairs(spec.windrowerWorkAreaFillTypes) do
				streamWriteUIntN(streamId, fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
			end
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.effectDirtyFlag) ~= 0) then
			for _, effect in ipairs(spec.effects) do
				streamWriteBool(streamId, effect.isActiveSent)
			end
		end
	end
end

function Windrower:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_windrower

	if self.isServer then
		for _, effect in ipairs(spec.effects) do
			if effect.isActive and effect.activeTime < g_currentMission.time then
				effect.isActive = false

				if effect.isActiveSent then
					effect.isActiveSent = false

					self:raiseDirtyFlags(spec.effectDirtyFlag)
				end

				g_effectManager:stopEffects(effect.effects)
			end
		end
	end

	if self.isClient and g_animationManager:areAnimationsRunning(spec.animationNodes) then
		for _, rake in pairs(spec.rakes) do
			self:updateRake(rake)
		end

		self:raiseActive()
	end
end

function Windrower:onTurnedOn()
	local spec = self.spec_windrower

	if self.isClient then
		g_soundManager:playSample(spec.samples.work)
		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function Windrower:onTurnedOff()
	local spec = self.spec_windrower

	g_soundManager:stopSamples(spec.samples)

	for _, effect in ipairs(spec.effects) do
		g_effectManager:stopEffects(effect.effects)
	end

	g_animationManager:stopAnimations(spec.animationNodes)
end

function Windrower:onDeactivate()
	if self.isClient then
		local spec = self.spec_windrower

		for _, effect in ipairs(spec.effects) do
			g_effectManager:stopEffects(effect.effects)
		end

		if self.getIsTurnedOn == nil then
			g_soundManager:stopSample(spec.samples.work)

			spec.isWorking = false
		end
	end
end

function Windrower:doCheckSpeedLimit(superFunc)
	local turnOn = true

	if self.getIsTurnedOn ~= nil then
		turnOn = self:getIsTurnedOn()
	end

	return superFunc(self) or self:getIsImplementChainLowered() and turnOn
end

function Windrower:loadRakeFromXML(rake, xmlFile, key, index)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

	rake.node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
	rake.spikes = {}
	rake.maxRotZ = math.rad(getXMLFloat(xmlFile, key .. "#spikeMaxRotZ"))
	rake.dir = Utils.getNoNil(getXMLInt(xmlFile, key .. "#dir"), 1)
	local moveUpRange = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#moveUpRange"), 2)
	local moveDownRange = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#moveDownRange"), 2)
	rake.moveUpStart = moveUpRange[1]
	rake.moveUpEnd = moveUpRange[2]
	rake.moveDownStart = moveDownRange[1]
	rake.moveDownEnd = moveDownRange[2]
	local j = 0

	while true do
		local spikeKey = string.format(key .. ".spike(%d)", j)

		if not hasXMLProperty(xmlFile, spikeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, spikeKey .. "#index", spikeKey .. "#node")

		local spike = {
			node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, spikeKey .. "#node"), self.i3dMappings),
			dir = Utils.getNoNil(getXMLInt(xmlFile, spikeKey .. "#dir"), 1)
		}
		local _, y, _ = getRotation(getParent(spike.node))
		spike.yRotOffset = y

		table.insert(rake.spikes, spike)

		j = j + 1
	end

	rake.yRotOffset = 2 * math.pi / #rake.spikes

	return true
end

function Windrower:updateRake(rake)
	local _, y, _ = getRotation(rake.node)
	y = y % (2 * math.pi)

	if rake.dir == -1 then
		y = math.abs(2 * math.pi - y)
	end

	for k, spike in pairs(rake.spikes) do
		local yRot = (y - (k - 1) * rake.yRotOffset + 2 * math.pi) % (2 * math.pi)
		local alpha = 0

		if rake.moveUpStart < yRot and yRot <= rake.moveUpEnd then
			alpha = 1 - (rake.moveUpEnd - yRot) / (rake.moveUpEnd - rake.moveUpStart)
		elseif rake.moveDownStart < yRot and yRot <= rake.moveDownEnd then
			alpha = (rake.moveDownEnd - yRot) / (rake.moveDownEnd - rake.moveDownStart)
		elseif rake.moveUpEnd < yRot and yRot <= rake.moveDownStart then
			alpha = 1
		end

		setRotation(spike.node, 0, 0, rake.maxRotZ * alpha * spike.dir)
	end
end

function Windrower.getDefaultSpeedLimit()
	return 15
end

function Windrower:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.WINDROWER
	end

	if workArea.type == WorkAreaType.WINDROWER then
		workArea.particleSystemIndex = getXMLInt(xmlFile, key .. ".windrower#particleSystemIndex")
		workArea.dropWindrowWorkAreaIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. ".windrower#dropWindrowWorkAreaIndex"), 1)
		workArea.lastValidPickupFruitType = FruitType.UNKNOWN
		workArea.lastPickupLiters = 0
		workArea.lastDroppedLiters = 0
		workArea.litersToDrop = 0
		local spec = self.spec_windrower

		if spec.windrowerWorkAreaFillTypes == nil then
			spec.windrowerWorkAreaFillTypes = {}
		end

		table.insert(spec.windrowerWorkAreaFillTypes, FruitType.UNKNOWN)

		workArea.windrowerWorkAreaIndex = #spec.windrowerWorkAreaFillTypes
	end

	return retValue
end

function Windrower:getDirtMultiplier(superFunc)
	local spec = self.spec_windrower
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Windrower:getWearMultiplier(superFunc)
	local spec = self.spec_windrower
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Windrower:onStartWorkAreaProcessing(dt, workAreas)
	local spec = self.spec_windrower

	for _, workArea in pairs(workAreas) do
		workArea.lastValidPickupFruitType = FruitType.UNKNOWN
		workArea.lastPickupLiters = 0
		workArea.lastDroppedLiters = 0
	end

	spec.isWorking = false
end

function Windrower:onEndWorkAreaProcessing(dt, workAreas)
	local spec = self.spec_windrower

	if self.isClient and self.getIsTurnedOn == nil then
		if spec.isWorking then
			if not g_soundManager:getIsSamplePlaying(spec.samples.work) then
				g_soundManager:playSample(spec.samples.work)
			end
		elseif g_soundManager:getIsSamplePlaying(spec.samples.work) then
			g_soundManager:stopSample(spec.samples.work)
		end
	end
end

function Windrower:processWindrowerArea(workArea, dt)
	local spec = self.spec_windrower
	local workAreaSpec = self.spec_workArea
	spec.isWorking = self:getLastSpeed() > 0.5
	local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	local pickupLiters = 0
	local pickupFruitType = FruitType.UNKNOWN
	local lastValidFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(workArea.lastValidPickupFruitType)

	if workArea.lastPickupLiters == 0 and (workArea.lastValidPickupFruitType == FruitType.UNKNOWN or workArea.litersToDrop < g_densityMapHeightManager:getMinValidLiterValue(lastValidFillType)) then
		for fruitTypeIndex, _ in ipairs(g_fruitTypeManager:getFruitTypes()) do
			local fillTypeIndex = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitTypeIndex)

			if fillTypeIndex ~= nil then
				pickupLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, nil, , spec.limitToLineHeight, nil)

				if pickupLiters > 0 then
					pickupFruitType = fruitTypeIndex

					break
				end
			end
		end
	else
		pickupLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(workArea.lastValidPickupFruitType), lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)

		if workArea.lastValidPickupFruitType == FruitType.GRASS then
			pickupLiters = pickupLiters - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.DRYGRASS), lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)
		elseif workArea.lastValidPickupFruitType == FruitType.DRYGRASS then
			pickupLiters = pickupLiters - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.GRASS), lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)
		end

		if pickupLiters > 0 then
			pickupFruitType = workArea.lastValidPickupFruitType
		end
	end

	if pickupFruitType ~= FruitType.UNKNOWN then
		workArea.lastValidPickupFruitType = pickupFruitType
	end

	workArea.lastPickupLiters = pickupLiters
	workArea.litersToDrop = workArea.litersToDrop + pickupLiters
	local areaWidth = MathUtil.vector3Length(lsx - lex, lsy - ley, lsz - lez)
	local area = areaWidth * self.lastMovedDistance

	if workArea.lastPickupLiters > 0 then
		local dropArea = workAreaSpec.workAreas[workArea.dropWindrowWorkAreaIndex]

		if dropArea ~= nil then
			local dropType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(workArea.lastValidPickupFruitType)
			local dropped = self:processDropArea(dropArea, workArea.lastPickupLiters, dropType)
			workArea.lastDroppedLiters = dropped
			workArea.litersToDrop = workArea.litersToDrop - dropped

			if self.isServer and self:getLastSpeed(true) > 0.5 and dropped > 0 then
				local changedFillType = false

				if spec.windrowerWorkAreaFillTypes[workArea.windrowerWorkAreaIndex] ~= dropType then
					spec.windrowerWorkAreaFillTypes[workArea.windrowerWorkAreaIndex] = dropType

					self:raiseDirtyFlags(spec.fillTypesDirtyFlag)

					changedFillType = true
				end

				local effects = spec.workAreaToEffects[workArea.index]

				if effects ~= nil then
					for _, effect in ipairs(effects) do
						effect.activeTime = g_currentMission.time + effect.activeTimeDuration

						if not effect.isActiveSent then
							effect.isActiveSent = true

							self:raiseDirtyFlags(spec.effectDirtyFlag)
						end

						if changedFillType then
							g_effectManager:setFillType(effect.effects, dropType)
						end

						if not effect.isActive then
							g_effectManager:setFillType(effect.effects, dropType)
							g_effectManager:startEffects(effect.effects)
						end

						effect.isActive = true
					end
				end
			end
		end
	end

	return workArea.lastDroppedLiters, area
end

function Windrower:processDropArea(dropArea, litersToDrop, fillType)
	local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(dropArea.start, dropArea.width, dropArea.height)
	local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, fillType, lsx, lsy, lsz, lex, ley, lez, radius, nil, dropArea.lineOffset, false, nil, false)
	dropArea.lineOffset = lineOffset

	return dropped
end
