Cutter = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("cutter", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Cutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readTestAreasStream", Cutter.readTestAreasStream)
	SpecializationUtil.registerFunction(vehicleType, "writeTestAreasStream", Cutter.writeTestAreasStream)
	SpecializationUtil.registerFunction(vehicleType, "getCombine", Cutter.getCombine)
	SpecializationUtil.registerFunction(vehicleType, "getAllowCutterAIFruitRequirements", Cutter.getAllowCutterAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "loadTestAreaFromXML", Cutter.loadTestAreaFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsTestAreaActive", Cutter.getIsTestAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "processCutterArea", Cutter.processCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "processPickupCutterArea", Cutter.processPickupCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "getCutterLoad", Cutter.getCutterLoad)
end

function Cutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Cutter.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Cutter.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", Cutter.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", Cutter.getIsRandomlyMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cutter.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cutter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cutter.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cutter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cutter.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isAttachAllowed", Cutter.isAttachAllowed)
end

function Cutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cutter)
end

function Cutter:onLoad(savegame)
	local spec = self.spec_cutter

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.cutter.animationNodes.animationNode", "cutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter.reelspikes", "vehicle.cutter.rotationNodes.rotationNode or vehicle.turnOnVehicle.turnedOnAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter.threshingParticleSystems.threshingParticleSystem", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter.threshingParticleSystems.emitterShape", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter#convertedFillTypeCategories", "vehicle.cutter#fruitTypeConverter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cutter#startAnimationName", "vehicle.turnOnVehicle.turnOnAnimation#name")

	local fruitTypes = nil
	local fruitTypeNames = getXMLString(self.xmlFile, "vehicle.cutter#fruitTypes")
	local fruitTypeCategories = getXMLString(self.xmlFile, "vehicle.cutter#fruitTypeCategories")

	if fruitTypeCategories ~= nil and fruitTypeNames == nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames(fruitTypeCategories, "Warning: Cutter has invalid fruitTypeCategory '%s' in '" .. self.configFileName .. "'")
	elseif fruitTypeCategories == nil and fruitTypeNames ~= nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByNames(fruitTypeNames, "Warning: Cutter has invalid fruitType '%s' in '" .. self.configFileName .. "'")
	else
		g_logManager:xmlWarning(self.configFileName, "Cutter needs either the 'fruitTypeCategories' or 'fruitTypes' attribute!")
	end

	if fruitTypes ~= nil then
		spec.fruitTypes = {}

		for _, fruitType in pairs(fruitTypes) do
			table.insert(spec.fruitTypes, fruitType)
		end
	end

	spec.fruitTypeConverters = {}
	local category = getXMLString(self.xmlFile, "vehicle.cutter#fruitTypeConverter")

	if category ~= nil then
		local data = g_fruitTypeManager:getConverterDataByName(category)

		if data ~= nil then
			for input, converter in pairs(data) do
				spec.fruitTypeConverters[input] = converter
			end
		end
	end

	spec.fillTypes = {}

	for _, fruitType in ipairs(spec.fruitTypes) do
		if spec.fruitTypeConverters[fruitType] ~= nil then
			table.insert(spec.fillTypes, spec.fruitTypeConverters[fruitType].fillTypeIndex)
		else
			local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)

			if fillType ~= nil then
				table.insert(spec.fillTypes, fillType)
			end
		end
	end

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.cutter.animationNodes", self.components, self, self.i3dMappings)
		spec.fruitExtraObjects = {}
		local i = 0

		while true do
			local key = string.format("vehicle.cutter.fruitExtraObjects.fruitExtraObject(%d)", i)

			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")

			local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
			local anim = getXMLString(self.xmlFile, key .. "#anim")
			local isDefault = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#isDefault"), false)
			local fruitType = g_fruitTypeManager:getFruitTypeByName(getXMLString(self.xmlFile, key .. "#fruitType"))

			if fruitType == nil or node == nil and anim == nil then
				break
			end

			if node ~= nil then
				setVisibility(node, false)
			end

			local extraObject = {
				node = node,
				anim = anim
			}
			spec.fruitExtraObjects[fruitType.index] = extraObject

			if isDefault then
				spec.fruitExtraObjects[FruitType.UNKNOWN] = extraObject
			end

			i = i + 1
		end

		spec.hideExtraObjectsOnDetach = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cutter.fruitExtraObjects#hideOnDetach"), false)
		spec.testAreas = {}
		spec.testAreaBase = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.cutter.testAreas#baseNode"), self.i3dMappings), self.rootNode)
		i = 0

		while true do
			local key = string.format("vehicle.cutter.testAreas.testArea(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local testArea = {}

			if self:loadTestAreaFromXML(testArea, self.xmlFile, key) then
				table.insert(spec.testAreas, testArea)
			end

			i = i + 1
		end

		spec.cutterEffects = {}
		spec.currentCutterEffect = nil

		if hasXMLProperty(self.xmlFile, "vehicle.cutter.effect") then
			for _, fruitTypeIndex in ipairs(spec.fruitTypes) do
				spec.cutterEffects[fruitTypeIndex] = {}
				i = 0

				while true do
					local key = string.format("vehicle.cutter.effect.effectNode(%d)", i)

					if not hasXMLProperty(self.xmlFile, key) then
						break
					end

					local effect = CutterEffect:new()

					effect:load(self.xmlFile, key, self.components, self, fruitTypeIndex, self.i3dMappings)
					table.insert(spec.cutterEffects[fruitTypeIndex], effect)

					i = i + 1
				end
			end
		end

		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.fillEffect", self.components, self, self.i3dMappings)
	end

	spec.allowsForageGrowthState = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cutter#allowsForageGrowthState"), false)
	spec.allowCuttingWhileRaised = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cutter#allowCuttingWhileRaised"), false)
	spec.movingDirection = MathUtil.sign(Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.cutter#movingDirection"), 1))
	spec.strawRatio = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.cutter#strawRatio"), 1)
	spec.useWindrow = false
	spec.currentInputFillType = FillType.UNKNOWN
	spec.currentInputFruitType = FruitType.UNKNOWN
	spec.currentInputFruitTypeAI = FruitType.UNKNOWN
	spec.lastValidInputFruitType = FruitType.UNKNOWN
	spec.currentInputFruitTypeSent = FruitType.UNKNOWN
	spec.currentGrowthStateTime = 0
	spec.currentGrowthStateTimer = 0
	spec.currentGrowthState = 0
	spec.lastAreaBiggerZero = false
	spec.lastAreaBiggerZeroSent = false
	spec.lastAreaBiggerZeroTime = -1
	spec.workAreaParameters = {
		lastRealArea = 0,
		lastArea = 0,
		lastGrowthState = 0,
		lastGrowthStateArea = 0,
		fruitTypesToUse = {},
		lastFruitTypeToUse = {}
	}
	spec.lastOutputFillTypes = {}
	spec.lastPrioritizedOutputType = FillType.UNKNOWN
	spec.lastOutputTime = 0
	spec.cutterLoad = 0
	spec.isWorking = false
	spec.workAreaParameters.countArea = true
	spec.aiNoValidGroundTimer = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.effectDirtyFlag = self:getNextDirtyFlag()

	self:doCollisionMaskCheck(MathUtil.bitsToMask(26), "vehicle.cutter#ignoreCollisionMask")
end

function Cutter:onPostLoad(savegame)
	if self.addCutterToCombine ~= nil then
		self:addCutterToCombine(self)
	end

	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onDelete()
	if self.isClient then
		local spec = self.spec_cutter

		for _, effectAttribute in pairs(spec.cutterEffects) do
			g_effectManager:deleteEffects(effectAttribute.effect)
		end

		g_effectManager:deleteEffects(spec.fillEffects)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function Cutter:onReadStream(streamId, connection)
	self:readTestAreasStream(streamId, connection)

	local spec = self.spec_cutter
	spec.lastAreaBiggerZero = streamReadBool(streamId)

	if spec.lastAreaBiggerZero then
		spec.lastAreaBiggerZeroTime = g_currentMission.time
	end
end

function Cutter:onWriteStream(streamId, connection)
	self:writeTestAreasStream(streamId, connection)

	local spec = self.spec_cutter

	streamWriteBool(streamId, spec.lastAreaBiggerZeroSent)
end

function Cutter:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_cutter

		if streamReadBool(streamId) then
			self:readTestAreasStream(streamId, connection)
		end

		spec.lastAreaBiggerZero = streamReadBool(streamId)

		if spec.lastAreaBiggerZero then
			spec.lastAreaBiggerZeroTime = g_currentMission.time
		end
	end
end

function Cutter:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_cutter

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.effectDirtyFlag) ~= 0) then
			self:writeTestAreasStream(streamId, connection)
		end

		streamWriteBool(streamId, spec.lastAreaBiggerZeroSent)
	end
end

function Cutter:readTestAreasStream(streamId, connection)
	local spec = self.spec_cutter
	local readGrowthState = false

	for _, testArea in ipairs(spec.testAreas) do
		testArea.hasFruitContact = streamReadBool(streamId)

		if testArea.hasFruitContact then
			readGrowthState = true
		end
	end

	if readGrowthState then
		spec.currentGrowthState = streamReadUIntN(streamId, 4)
	end

	spec.currentInputFruitType = streamReadUIntN(streamId, 7)

	if streamReadBool(streamId) then
		spec.lastValidInputFruitType = spec.currentInputFruitType
	else
		spec.currentInputFruitType = FillType.UNKNOWN
	end

	if streamReadBool(streamId) then
		spec.currentInputFillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
	else
		spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
	end
end

function Cutter:writeTestAreasStream(streamId, connection)
	local spec = self.spec_cutter
	local sentGrowthState = false

	for _, testArea in ipairs(spec.testAreas) do
		streamWriteBool(streamId, testArea.hasFruitContact)

		if testArea.hasFruitContact then
			sentGrowthState = true
		end
	end

	if sentGrowthState then
		streamWriteUIntN(streamId, spec.currentGrowthState, 4)
	end

	streamWriteUIntN(streamId, spec.currentInputFruitType, 7)
	streamWriteBool(streamId, spec.currentInputFruitType == spec.lastValidInputFruitType)
	streamWriteBool(streamId, spec.useWindrow)
end

function Cutter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cutter
	local isTurnedOn = self:getIsTurnedOn()
	local isEffectActive = isTurnedOn and self.movingDirection == spec.movingDirection and self:getLastSpeed() > 0.5 and (spec.allowCuttingWhileRaised or self:getIsLowered(true))

	if isEffectActive then
		local minEffectValue = math.huge
		local maxEffectValue = -math.huge
		local chargedAreas = 0

		for _, area in ipairs(spec.testAreas) do
			local x, y, z = getWorldTranslation(area.start)
			local x1, y1, z1 = getWorldTranslation(area.width)
			local x2, _, z2 = getWorldTranslation(area.height)

			if self.isServer and spec.currentInputFruitType ~= nil and self:getIsTestAreaActive(area) then
				local fruitValue, _, _, _ = FSDensityMapUtil.getFruitArea(spec.currentInputFruitType, x, z, x1, z1, x2, z2, nil, spec.allowsForageGrowthState)
				area.hasFruitContact = fruitValue > 0

				if area.hasFruitContactSent ~= area.hasFruitContact then
					self:raiseDirtyFlags(spec.effectDirtyFlag)

					area.hasFruitContactSent = area.hasFruitContact
				end
			end

			if area.hasFruitContact then
				local lx1, _, _ = worldToLocal(spec.testAreaBase, x, y, z)
				local lx2, _, _ = worldToLocal(spec.testAreaBase, x1, y1, z1)
				minEffectValue = math.min(minEffectValue, lx1, lx2)
				maxEffectValue = math.max(maxEffectValue, lx1, lx2)
				chargedAreas = chargedAreas + 1
			end
		end

		if not spec.useWindrow and #spec.testAreas > 0 then
			local currentLoad = chargedAreas / #spec.testAreas
			spec.cutterLoad = spec.cutterLoad * 0.95 + currentLoad * 0.05
		end

		local reset = false

		if minEffectValue == math.huge and maxEffectValue == -math.huge then
			minEffectValue = 0
			maxEffectValue = 0
			reset = true
		end

		if spec.movingDirection > 0 then
			minEffectValue = minEffectValue * -1
			maxEffectValue = maxEffectValue * -1

			if minEffectValue > maxEffectValue then
				local t = minEffectValue
				minEffectValue = maxEffectValue
				maxEffectValue = t
			end
		end

		local inputFruitType = spec.currentInputFruitType

		if inputFruitType ~= spec.lastValidInputFruitType then
			inputFruitType = nil
		end

		if inputFruitType ~= nil then
			local newEffect = spec.cutterEffects[inputFruitType]

			if newEffect ~= nil then
				if spec.currentCutterEffect ~= newEffect then
					g_effectManager:resetEffects(spec.currentCutterEffect)
				end

				spec.currentCutterEffect = newEffect

				for _, effect in ipairs(spec.currentCutterEffect) do
					if effect.setGrowthState ~= nil then
						effect:setGrowthState(spec.currentGrowthState)
					end

					if effect.setMinMaxWidth ~= nil then
						effect:setMinMaxWidth(minEffectValue, maxEffectValue, reset)
					end
				end
			elseif spec.currentCutterEffect ~= nil then
				g_effectManager:resetEffects(spec.currentCutterEffect)
			end

			Cutter.updateExtraObjects(self)
		end

		local isCollecting = g_currentMission.time < spec.lastAreaBiggerZeroTime + 300
		local fillType = spec.currentInputFillType

		if spec.useWindrow then
			if isCollecting then
				spec.cutterLoad = spec.cutterLoad * 0.95 + 0.05
			else
				spec.cutterLoad = spec.cutterLoad * 0.9
			end
		end

		if fillType ~= FillType.UNKNOWN and isCollecting then
			g_effectManager:setFillType(spec.fillEffects, fillType)
			g_effectManager:setMinMaxWidth(spec.fillEffects, minEffectValue, maxEffectValue, reset)
			g_effectManager:startEffects(spec.fillEffects)
		else
			g_effectManager:stopEffects(spec.fillEffects)
		end
	else
		if spec.currentCutterEffect ~= nil then
			for _, effect in pairs(spec.currentCutterEffect) do
				if effect.setMinMaxWidth ~= nil then
					effect:setMinMaxWidth(0, 0, true)
				end
			end
		end

		g_effectManager:stopEffects(spec.fillEffects)

		spec.cutterLoad = spec.cutterLoad * 0.9
	end

	spec.lastOutputTime = spec.lastOutputTime + dt

	if spec.lastOutputTime > 500 then
		spec.lastPrioritizedOutputType = FillType.UNKNOWN
		local max = 0

		for i, _ in pairs(spec.lastOutputFillTypes) do
			if max < spec.lastOutputFillTypes[i] then
				spec.lastPrioritizedOutputType = i
				max = spec.lastOutputFillTypes[i]
			end

			spec.lastOutputFillTypes[i] = 0
		end

		spec.lastOutputTime = 0
	end
end

function Cutter:getCombine()
	local spec = self.spec_cutter
	local outputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)

	if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
		outputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
	end

	if self.verifyCombine ~= nil then
		return self:verifyCombine(spec.currentInputFruitType, outputFillType)
	elseif self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil and attacherVehicle.verifyCombine ~= nil then
			return attacherVehicle:verifyCombine(spec.currentInputFruitType, outputFillType)
		end
	end

	return nil
end

function Cutter:getAllowCutterAIFruitRequirements()
	return true
end

function Cutter:processCutterArea(workArea, dt)
	local spec = self.spec_cutter

	if spec.workAreaParameters.combineVehicle ~= nil then
		local xs, _, zs = getWorldTranslation(workArea.start)
		local xw, _, zw = getWorldTranslation(workArea.width)
		local xh, _, zh = getWorldTranslation(workArea.height)
		local lastRealArea = 0
		local lastThreshedArea = 0
		local lastArea = 0

		for _, fruitType in ipairs(spec.workAreaParameters.fruitTypesToUse) do
			local realArea, area, sprayFactor, plowFactor, limeFactor, weedFactor, growthState, growthStateArea, terrainDetailPixelsSum = FSDensityMapUtil.cutFruitArea(fruitType, xs, zs, xw, zw, xh, zh, true, true, spec.allowsForageGrowthState, g_currentMission.chopperGroundLayerType)

			if realArea > 0 then
				if self.isServer then
					if growthState ~= spec.currentGrowthState then
						spec.currentGrowthStateTimer = spec.currentGrowthStateTimer + dt

						if spec.currentGrowthStateTimer > 500 or spec.currentGrowthStateTime + 1000 < g_time then
							spec.currentGrowthState = growthState
							spec.currentGrowthStateTimer = 0
						end
					else
						spec.currentGrowthStateTimer = 0
						spec.currentGrowthStateTime = g_time
					end

					spec.currentInputFruitType = fruitType

					if terrainDetailPixelsSum > 0 then
						spec.currentInputFruitTypeAI = fruitType
					end

					spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)
					spec.useWindrow = false
				end

				local multiplier = g_currentMission:getHarvestScaleMultiplier(fruitType, sprayFactor, plowFactor, limeFactor, weedFactor)
				lastRealArea = realArea * multiplier
				lastThreshedArea = realArea
				lastArea = area
				spec.workAreaParameters.lastFruitType = fruitType

				break
			end
		end

		if lastArea > 0 then
			if workArea.chopperAreaIndex ~= nil then
				local workArea = self:getWorkAreaByIndex(workArea.chopperAreaIndex)

				if workArea ~= nil then
					local xs, _, zs = getWorldTranslation(workArea.start)
					local xw, _, zw = getWorldTranslation(workArea.width)
					local xh, _, zh = getWorldTranslation(workArea.height)

					FSDensityMapUtil.setGroundTypeLayerArea(xs, zs, xw, zw, xh, zh, g_currentMission.chopperGroundLayerType)
				else
					workArea.chopperAreaIndex = nil

					g_logManager:xmlWarning(self.configFileName, "Invalid chopperAreaIndex '%d' for workArea '%d'!", workArea.chopperAreaIndex, workArea.index)
				end
			end

			spec.isWorking = true
		end

		spec.workAreaParameters.lastRealArea = spec.workAreaParameters.lastRealArea + lastRealArea
		spec.workAreaParameters.lastThreshedArea = spec.workAreaParameters.lastThreshedArea + lastThreshedArea
		spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + lastThreshedArea
		spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + lastArea
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Cutter:processPickupCutterArea(workArea, dt)
	local spec = self.spec_cutter

	if spec.workAreaParameters.combineVehicle ~= nil then
		local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)

		for _, fruitType in ipairs(spec.workAreaParameters.fruitTypesToUse) do
			local fillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitType)

			if fillType ~= nil then
				local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, , false, nil)

				if self.isServer and pickedUpLiters > 0 then
					local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
					local literPerSqm = fruitDesc.literPerSqm
					local lastCutterArea = pickedUpLiters / (g_currentMission:getFruitPixelsToSqm() * literPerSqm)
					spec.currentInputFruitType = fruitType
					spec.useWindrow = true
					spec.currentInputFillType = fillType
					spec.workAreaParameters.lastFruitType = fruitType
					spec.workAreaParameters.lastRealArea = spec.workAreaParameters.lastRealArea + lastCutterArea
					spec.workAreaParameters.lastThreshedArea = spec.workAreaParameters.lastThreshedArea + lastCutterArea
					spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + lastCutterArea
					spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + lastCutterArea
					spec.isWorking = true

					break
				end
			end
		end
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Cutter:onStartWorkAreaProcessing(dt)
	local spec = self.spec_cutter
	local combineVehicle, alternativeCombine, requiredFillType = self:getCombine()

	if combineVehicle == nil and requiredFillType ~= nil then
		combineVehicle = alternativeCombine
	end

	spec.workAreaParameters.combineVehicle = combineVehicle
	spec.workAreaParameters.lastRealArea = 0
	spec.workAreaParameters.lastThreshedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastArea = 0
	spec.workAreaParameters.lastGrowthState = 0
	spec.workAreaParameters.lastGrowthStateArea = 0

	if spec.workAreaParameters.lastFruitType == nil then
		spec.workAreaParameters.fruitTypesToUse = spec.fruitTypes
	else
		for i = 1, #spec.workAreaParameters.lastFruitTypeToUse do
			spec.workAreaParameters.lastFruitTypeToUse[i] = nil
		end

		spec.workAreaParameters.lastFruitTypeToUse[1] = spec.workAreaParameters.lastFruitType
		spec.workAreaParameters.fruitTypesToUse = spec.workAreaParameters.lastFruitTypeToUse
	end

	if requiredFillType ~= nil then
		for i = 1, #spec.workAreaParameters.lastFruitTypeToUse do
			spec.workAreaParameters.lastFruitTypeToUse[i] = nil
		end

		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(requiredFillType)

		for inputFruitType, fruitTypeConverter in pairs(spec.fruitTypeConverters) do
			if fruitTypeConverter.fillTypeIndex == requiredFillType then
				table.insert(spec.workAreaParameters.lastFruitTypeToUse, inputFruitType)

				fruitType = nil
			end
		end

		if fruitType ~= nil then
			table.insert(spec.workAreaParameters.lastFruitTypeToUse, fruitType)
		end

		spec.workAreaParameters.fruitTypesToUse = spec.workAreaParameters.lastFruitTypeToUse
	end

	spec.workAreaParameters.lastFruitType = nil
	spec.isWorking = false
end

function Cutter:onEndWorkAreaProcessing(dt, hasProcessed)
	if self.isServer then
		local spec = self.spec_cutter
		local lastRealArea = spec.workAreaParameters.lastRealArea
		local lastThreshedArea = spec.workAreaParameters.lastThreshedArea
		local lastStatsArea = spec.workAreaParameters.lastStatsArea
		local lastArea = spec.workAreaParameters.lastArea

		if lastRealArea > 0 then
			if spec.workAreaParameters.combineVehicle ~= nil then
				local inputFruitType = spec.workAreaParameters.lastFruitType

				if self:getIsAIActive() then
					local requirements = self:getAIFruitRequirements()
					local requirement = requirements[1]

					if #requirements == 1 and requirement ~= nil and requirement.fruitType ~= FruitType.UNKNOWN then
						inputFruitType = requirement.fruitType
					end
				end

				local conversionFactor = 1
				local outputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(inputFruitType)

				if spec.fruitTypeConverters[inputFruitType] ~= nil then
					outputFillType = spec.fruitTypeConverters[inputFruitType].fillTypeIndex
					conversionFactor = spec.fruitTypeConverters[inputFruitType].conversionFactor
				end

				if spec.lastOutputFillTypes[outputFillType] == nil then
					spec.lastOutputFillTypes[outputFillType] = lastRealArea
				else
					spec.lastOutputFillTypes[outputFillType] = spec.lastOutputFillTypes[outputFillType] + lastRealArea
				end

				if spec.lastPrioritizedOutputType ~= FillType.UNKNOWN then
					outputFillType = spec.lastPrioritizedOutputType
				end

				lastRealArea = lastRealArea * conversionFactor
				local farmId = self:getLastTouchedFarmlandFarmId()
				local appliedDelta = spec.workAreaParameters.combineVehicle:addCutterArea(lastArea, lastRealArea, inputFruitType, outputFillType, spec.strawRatio, farmId)

				if appliedDelta > 0 then
					spec.lastValidInputFruitType = inputFruitType
				end
			end

			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("threshedHectares", ha)
			stats:updateStats("workedHectares", ha)

			spec.lastAreaBiggerZero = lastArea > 0

			if spec.lastAreaBiggerZero then
				spec.lastAreaBiggerZeroTime = g_currentMission.time
			end

			if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
				self:raiseDirtyFlags(spec.dirtyFlag)

				spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
			end

			if spec.currentInputFruitType ~= spec.currentInputFruitTypeSent then
				self:raiseDirtyFlags(spec.effectDirtyFlag)

				spec.currentInputFruitTypeSent = spec.currentInputFruitType
			end

			if self:getAllowCutterAIFruitRequirements() then
				if self.setAIFruitRequirements ~= nil then
					local requirements = self:getAIFruitRequirements()
					local requirement = requirements[1]

					if #requirements > 1 or requirement == nil or requirement.fruitType == FruitType.UNKNOWN then
						local fruitType = g_fruitTypeManager:getFruitTypeByIndex(spec.currentInputFruitTypeAI)

						if fruitType ~= nil then
							local minState = spec.allowsForageGrowthState and fruitType.minForageGrowthState or fruitType.minHarvestingGrowthState

							self:setAIFruitRequirements(spec.currentInputFruitTypeAI, minState, fruitType.maxHarvestingGrowthState)
						end
					end
				end

				spec.aiNoValidGroundTimer = 0
			end
		elseif self:getAllowCutterAIFruitRequirements() and hasProcessed then
			if self:getIsAIActive() then
				spec.aiNoValidGroundTimer = spec.aiNoValidGroundTimer + dt

				if spec.aiNoValidGroundTimer > 5000 then
					local rootVehicle = self:getRootVehicle()

					if rootVehicle.stopAIVehicle ~= nil then
						rootVehicle:stopAIVehicle(AIVehicle.STOP_REASON_UNKOWN)
					end
				end
			else
				spec.aiNoValidGroundTimer = 0
			end
		end
	end
end

function Cutter:loadTestAreaFromXML(testArea, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#startIndex", key .. "#startNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#widthIndex", key .. "#widthNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#heightIndex", key .. "#heightNode")

	local start = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#startNode"), self.i3dMappings)
	local width = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#widthNode"), self.i3dMappings)
	local height = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#heightNode"), self.i3dMappings)

	if start ~= nil and width ~= nil and height ~= nil then
		testArea.start = start
		testArea.width = width
		testArea.height = height
		testArea.hasFruitContact = false
		testArea.hasFruitContactSent = false

		return true
	end

	return false
end

function Cutter:getIsTestAreaActive(area)
	return true
end

function Cutter:getCutterLoad()
	return self.spec_cutter.cutterLoad
end

function Cutter:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.rotateIfTurnedOn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotateIfTurnedOn"), false)

	return true
end

function Cutter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_cutter

	if not spec.allowCuttingWhileRaised and not self:getIsLowered(true) or speedRotatingPart.rotateIfTurnedOn and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Cutter:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
	local retValue = superFunc(self, part, xmlFile, key)
	part.moveOnlyIfCutted = Utils.getNoNil(getXMLBool(xmlFile, key .. "#moveOnlyIfCutted"), false)

	return retValue
end

function Cutter:getIsRandomlyMovingPartActive(superFunc, part)
	local retValue = superFunc(self, part)

	if part.moveOnlyIfCutted then
		retValue = retValue and self.spec_cutter.lastAreaBiggerZeroTime >= g_currentMission.time - 150
	end

	return retValue
end

function Cutter:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_cutter

	if (self.getAllowsLowering == nil or self:getAllowsLowering()) and not spec.allowCuttingWhileRaised and not self:getIsLowered(true) then
		return false
	end

	return superFunc(self, workArea)
end

function Cutter:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and (self.getIsLowered == nil or self:getIsLowered())
end

function Cutter:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)
	workArea.chopperAreaIndex = getXMLInt(xmlFile, key .. ".chopperArea#index")

	return retValue
end

function Cutter:getDirtMultiplier(superFunc)
	local spec = self.spec_cutter

	if spec.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Cutter:getWearMultiplier(superFunc)
	local spec = self.spec_cutter

	if spec.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Cutter:isAttachAllowed(superFunc, farmId, attacherVehicle)
	local spec = self.spec_cutter

	if attacherVehicle.spec_combine ~= nil and not attacherVehicle:getIsCutterCompatible(spec.fillTypes) then
		return false, g_i18n:getText("info_attach_not_allowed")
	end

	return superFunc(self, farmId, attacherVehicle)
end

function Cutter:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onPostDetach(attacherVehicle, implement)
	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onTurnedOn()
	if self.isClient then
		local spec = self.spec_cutter

		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function Cutter:onTurnedOff()
	local spec = self.spec_cutter

	if self.isClient then
		g_animationManager:stopAnimations(spec.animationNodes)
		g_effectManager:resetEffects(spec.currentCutterEffect)

		spec.currentInputFruitType = FruitType.UNKNOWN
		spec.currentInputFruitTypeAI = FruitType.UNKNOWN
		spec.currentInputFillType = FillType.UNKNOWN
	end
end

function Cutter:onAIImplementStart()
	if self:getAllowCutterAIFruitRequirements() then
		self:clearAIFruitRequirements()

		local spec = self.spec_cutter

		for _, fruitTypeIndex in ipairs(spec.fruitTypes) do
			local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

			if fruitType ~= nil then
				local minState = spec.allowsForageGrowthState and fruitType.minForageGrowthState or fruitType.minHarvestingGrowthState

				self:addAIFruitRequirement(fruitType.index, minState, fruitType.maxHarvestingGrowthState)
			end
		end
	end
end

function Cutter:updateExtraObjects()
	local spec = self.spec_cutter

	if spec.currentInputFruitType ~= nil then
		local extraObject = spec.fruitExtraObjects[spec.currentInputFruitType]

		if spec.hideExtraObjectsOnDetach and (self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil) then
			extraObject = nil
		end

		if extraObject ~= spec.currentExtraObject then
			if spec.currentExtraObject ~= nil then
				if spec.currentExtraObject.node ~= nil then
					setVisibility(spec.currentExtraObject.node, false)
				end

				if spec.currentExtraObject.anim ~= nil and self.playAnimation ~= nil then
					self:playAnimation(spec.currentExtraObject.anim, -1, self:getAnimationTime(spec.currentExtraObject.anim), true)
				end

				spec.currentExtraObject = nil
			end

			if extraObject ~= nil then
				if extraObject.node ~= nil then
					setVisibility(extraObject.node, true)
				end

				if extraObject.anim ~= nil and self.playAnimation ~= nil then
					self:playAnimation(extraObject.anim, 1, self:getAnimationTime(extraObject.anim), true)
				end

				spec.currentExtraObject = extraObject
			end
		end
	end
end

function Cutter.getDefaultSpeedLimit()
	return 10
end

function Cutter:updateDebugValues(values)
	local spec = self.spec_cutter

	table.insert(values, {
		name = "lastPrioritizedOutputType",
		value = string.format("%s", g_fillTypeManager:getFillTypeNameByIndex(spec.lastPrioritizedOutputType))
	})

	local sum = 0

	for fillType, value in pairs(spec.lastOutputFillTypes) do
		sum = sum + value
	end

	for fillType, value in pairs(spec.lastOutputFillTypes) do
		table.insert(values, {
			name = string.format("buffer (%s)", g_fillTypeManager:getFillTypeNameByIndex(fillType)),
			value = string.format("%.0f%%", value / sum * 100)
		})
	end
end
