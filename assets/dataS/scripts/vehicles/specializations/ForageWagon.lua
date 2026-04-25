ForageWagon = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("forageWagon", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(Pickup, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function ForageWagon.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processForageWagonArea", ForageWagon.processForageWagonArea)
	SpecializationUtil.registerFunction(vehicleType, "setFillEffectActive", ForageWagon.setFillEffectActive)
end

function ForageWagon.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", ForageWagon.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", ForageWagon.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", ForageWagon.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", ForageWagon.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", ForageWagon.getIsSpeedRotatingPartActive)
end

function ForageWagon.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", ForageWagon)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", ForageWagon)
end

function ForageWagon:onLoad(savegame)
	local spec = self.spec_forageWagon

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.forageWagon#turnedOnTipScrollerSpeedFactor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.turnOnVehicle.rotationNodes.rotationNode", "forageWagon")

	spec.isFilling = false
	spec.isFillingSent = false
	spec.fillTimer = 0
	spec.workAreaIndex = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.forageWagon#workAreaIndex"), 1)
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.forageWagon#fillUnitIndex"), 1)
	spec.loadInfoIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.forageWagon#loadInfoIndex"), 1)
	spec.maxPickupLitersPerSecond = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.forageWagon#maxPickupLitersPerSecond"), 500)

	if self.isClient then
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.forageWagon.fillEffect", self.components, self, self.i3dMappings)
	end

	spec.workAreaParameters = {
		forcedFillType = FillType.UNKNOWN
	}
	spec.pickUpLitersBuffer = ValueBuffer:new(750)
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function ForageWagon:onDelete()
	if self.isClient then
		local spec = self.spec_forageWagon

		if spec.fillEffects ~= nil then
			g_effectManager:deleteEffects(spec.fillEffects)
		end
	end
end

function ForageWagon:onReadStream(streamId, connection)
	local spec = self.spec_forageWagon
	spec.isFilling = streamReadBool(streamId)

	self:setFillEffectActive(spec.isFilling)
end

function ForageWagon:onWriteStream(streamId, connection)
	local spec = self.spec_forageWagon

	streamWriteBool(streamId, spec.isFillingSent)
end

function ForageWagon:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_forageWagon
		spec.isFilling = streamReadBool(streamId)

		self:setFillEffectActive(spec.isFilling)
	end
end

function ForageWagon:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_forageWagon

		streamWriteBool(streamId, spec.isFillingSent)
	end
end

function ForageWagon:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_forageWagon

	if self.isServer then
		local isFilling = false

		if spec.fillTimer > 0 then
			spec.fillTimer = spec.fillTimer - dt
			isFilling = true
		end

		spec.isFilling = isFilling

		if spec.isFilling ~= spec.isFillingSent then
			self:raiseDirtyFlags(spec.dirtyFlag)

			spec.isFillingSent = spec.isFilling

			self:setFillEffectActive(spec.isFilling)
		end

		spec.pickUpLitersBuffer:add(spec.workAreaParameters.lastPickupLiters)
	end
end

function ForageWagon:processForageWagonArea(workArea)
	local spec = self.spec_forageWagon
	local radius = 0.5
	local lsx, lsy, lsz, lex, ley, lez = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)
	local pickupLiters = 0

	if spec.workAreaParameters.forcedFillType ~= FillType.UNKNOWN then
		pickupLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, spec.workAreaParameters.forcedFillType, lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)

		if spec.workAreaParameters.forcedFillType == g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.GRASS) then
			pickupLiters = pickupLiters - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.DRYGRASS), lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)
		elseif spec.workAreaParameters.forcedFillType == g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.DRYGRASS) then
			pickupLiters = pickupLiters - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(FruitType.GRASS), lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)
		end
	else
		local supportedFillTypes = self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)

		if supportedFillTypes ~= nil then
			for fillType, state in pairs(supportedFillTypes) do
				if state then
					pickupLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillType, lsx, lsy, lsz, lex, ley, lez, radius, nil, , false, nil)

					if pickupLiters > 0 then
						spec.workAreaParameters.forcedFillType = fillType

						break
					end
				end
			end
		end
	end

	workArea.lastPickUpLiters = pickupLiters
	workArea.pickupParticlesActive = pickupLiters > 0
	spec.workAreaParameters.lastPickupLiters = spec.workAreaParameters.lastPickupLiters + pickupLiters
	local realArea = 0
	local area = 0

	if self.movingDirection == 1 then
		local width = MathUtil.vector3Length(lsx - lex, lsy - ley, lsz - lez)
		area = width * self.lastMovedDistance
		realArea = area
	end

	return realArea, area
end

function ForageWagon:setFillEffectActive(isActive)
	local spec = self.spec_forageWagon

	if isActive then
		local lastValidFillType = self:getFillUnitLastValidFillType(spec.fillUnitIndex)

		if spec.fillEffects ~= nil then
			g_effectManager:setFillType(spec.fillEffects, lastValidFillType)
			g_effectManager:startEffects(spec.fillEffects)
		end
	elseif spec.fillEffects ~= nil then
		g_effectManager:stopEffects(spec.fillEffects)
	end
end

function ForageWagon:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.rotateOnlyIfFillLevelIncreased = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rotateOnlyIfFillLevelIncreased"), false)

	return true
end

function ForageWagon:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_forageWagon

	if speedRotatingPart.rotateOnlyIfFillLevelIncreased ~= nil and speedRotatingPart.rotateOnlyIfFillLevelIncreased and not spec.isFilling then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function ForageWagon:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_forageWagon
	local forageWagonArea = self.spec_workArea.workAreas[spec.workAreaIndex]

	if forageWagonArea ~= nil and workArea == forageWagonArea and (not self:getIsTurnedOn() or not self:allowPickingUp()) then
		return false
	end

	return superFunc(self, workArea)
end

function ForageWagon:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self:getIsLowered()
end

function ForageWagon:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local spec = self.spec_forageWagon
	local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond

	return value + loadPercentage, count + 1
end

function ForageWagon:onStartWorkAreaProcessing(dt)
	local spec = self.spec_forageWagon
	spec.workAreaParameters.forcedFillType = FillType.UNKNOWN
	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

	if self:getFillTypeChangeThreshold(spec.fillUnitIndex) < fillLevel then
		spec.workAreaParameters.forcedFillType = self:getFillUnitFillType(spec.fillUnitIndex)
	end

	spec.workAreaParameters.lastPickupLiters = 0
end

function ForageWagon:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_forageWagon

	if self.isServer and spec.workAreaParameters.lastPickupLiters > 0 then
		local loadInfo = self:getFillVolumeLoadInfo(spec.loadInfoIndex)
		local filledLiters = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.workAreaParameters.lastPickupLiters, spec.workAreaParameters.forcedFillType, ToolType.UNDEFINED, loadInfo)

		if filledLiters + 0.01 < spec.workAreaParameters.lastPickupLiters then
			self:setIsTurnedOn(false)
			self:setPickupState(false)
		end

		spec.fillTimer = 500
	end
end

function ForageWagon:onTurnedOff()
	local spec = self.spec_forageWagon

	if self.isClient then
		spec.fillTimer = 0

		self:setFillEffectActive(false)
	end
end

function ForageWagon:onDeactivate()
	if self.isClient then
		local spec = self.spec_forageWagon
		spec.fillTimer = 0

		self:setFillEffectActive(false)
	end
end

function ForageWagon.getDefaultSpeedLimit()
	return 20
end
