ConveyorBelt = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
}

function ConveyorBelt.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", ConveyorBelt.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", ConveyorBelt.handleDischargeOnEmpty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", ConveyorBelt.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", ConveyorBelt.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowOnMap", ConveyorBelt.getShowOnMap)
end

function ConveyorBelt.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", ConveyorBelt)
end

function ConveyorBelt:onLoad(savegame)
	local spec = self.spec_conveyorBelt

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.conveyorBelt.animationNodes", self.components, self, self.i3dMappings)
	end

	spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.conveyorBelt.effects", self.components, self, self.i3dMappings)
	spec.currentDelay = 0

	table.sort(spec.effects, function (effect1, effect2)
		return effect1.startDelay < effect2.startDelay
	end)

	for _, effect in pairs(spec.effects) do
		if effect.planeFadeTime ~= nil then
			spec.currentDelay = spec.currentDelay + effect.planeFadeTime
		end

		if effect.setScrollUpdate ~= nil then
			effect:setScrollUpdate(false)
		end
	end

	spec.maxDelay = spec.currentDelay
	spec.morphStartPos = 0
	spec.morphEndPos = 0
	spec.isEffectDirty = false
	spec.emptyFactor = 1
	spec.scrollUpdateTime = 0
	spec.lastScrollUpdate = false
	spec.dischargeNodeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.conveyorBelt#dischargeNodeIndex"), 1)

	self:setCurrentDischargeNodeIndex(spec.dischargeNodeIndex)

	local dischargeNode = self:getDischargeNodeByIndex(spec.dischargeNodeIndex)
	local capacity = self:getFillUnitCapacity(dischargeNode.fillUnitIndex)
	spec.fillUnitIndex = dischargeNode.fillUnitIndex
	spec.startFillLevel = capacity * Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.conveyorBelt#startPercentage"), 0.9)
	local i = 0

	while true do
		local key = string.format("vehicle.conveyorBelt.offset(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local movingToolNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#movingToolNode"), self.i3dMappings)

		if movingToolNode ~= nil then
			if spec.offsets == nil then
				spec.offsets = {}
			end

			local offset = {
				lastState = 0,
				movingToolNode = movingToolNode,
				effects = {}
			}
			local j = 0

			while true do
				local effectKey = string.format(key .. ".effect(%d)", j)

				if not hasXMLProperty(self.xmlFile, effectKey) then
					break
				end

				local effectIndex = Utils.getNoNil(getXMLInt(self.xmlFile, effectKey .. "#index"), 0)
				local effect = spec.effects[effectIndex]

				if effect ~= nil and effect.setOffset ~= nil then
					local entry = {
						effect = effect,
						minValue = Utils.getNoNil(getXMLFloat(self.xmlFile, effectKey .. "#minOffset"), 0) * 1000,
						maxValue = Utils.getNoNil(getXMLFloat(self.xmlFile, effectKey .. "#maxOffset"), 1) * 1000,
						inverted = Utils.getNoNil(getXMLBool(self.xmlFile, effectKey .. "#inverted"), false)
					}

					table.insert(offset.effects, entry)
				else
					g_logManager:xmlWarning(self.configFileName, "Effect index '%d' not found!", effectIndex)
				end

				j = j + 1
			end

			table.insert(spec.offsets, offset)
		else
			g_logManager:xmlWarning(self.configFileName, "Missing movingToolNode for conveyor offset '%s'!", key)
		end

		i = i + 1
	end
end

function ConveyorBelt:onPostLoad(savegame)
	local spec = self.spec_conveyorBelt

	if spec.offsets ~= nil then
		if self.getMovingToolByNode ~= nil then
			spec.movingToolToOffset = {}

			for i = #spec.offsets, 1, -1 do
				local offset = spec.offsets[i]
				local movingTool = self:getMovingToolByNode(offset.movingToolNode)

				if movingTool ~= nil then
					offset.movingTool = movingTool
					spec.movingToolToOffset[movingTool] = offset

					ConveyorBelt.onMovingToolChanged(self, movingTool, 0, 0)
				else
					g_logManager:xmlWarning(self.configFileName, "No movingTool node '%s' defined for conveyor offset '%d'!", getName(offset.movingToolNode), i)
					table.remove(spec.offsets, i)
				end
			end

			if #spec.offsets == 0 then
				spec.offsets = nil
				spec.movingToolToOffset = nil
			end
		else
			g_logManager:xmlError(self.configFileName, "'Cylindered' specialization is required to use conveyorBelt offsets!")

			spec.offsets = nil
		end
	end
end

function ConveyorBelt:onDelete()
	local spec = self.spec_conveyorBelt

	g_effectManager:deleteEffects(spec.effects)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function ConveyorBelt:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_conveyorBelt
		local isBeltActive = self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF

		if isBeltActive then
			local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

			if fillLevel > 0.0001 then
				local movedFactor = dt / spec.currentDelay
				spec.morphStartPos = MathUtil.clamp(spec.morphStartPos + movedFactor, 0, 1)
				spec.morphEndPos = MathUtil.clamp(spec.morphEndPos + movedFactor, 0, 1)
				local fillFactor = fillLevel / self:getFillUnitCapacity(spec.fillUnitIndex)
				local visualFactor = spec.morphEndPos - spec.morphStartPos
				spec.emptyFactor = 1

				if fillFactor < visualFactor then
					spec.emptyFactor = MathUtil.clamp(fillFactor / visualFactor, 0, 1)
				else
					local offset = fillFactor - visualFactor
					spec.offset = offset
					spec.morphStartPos = MathUtil.clamp(spec.morphStartPos - offset / ((1 - spec.morphStartPos) * spec.currentDelay) * dt, 0, 1)
				end

				spec.isEffectDirty = true
			end
		end

		if spec.isEffectDirty then
			for _, effect in pairs(spec.effects) do
				if effect.setMorphPosition ~= nil then
					local effectStart = effect.startDelay / spec.currentDelay
					local effectEnd = (effect.startDelay + effect.planeFadeTime - effect.offset) / spec.currentDelay
					local offsetFactor = effect.offset / effect.planeFadeTime
					local startMorphFactor = (spec.morphStartPos - effectStart) / (effectEnd - effectStart)
					local startMorph = MathUtil.clamp(offsetFactor + startMorphFactor * (1 - offsetFactor), offsetFactor, 1)
					local endMorphFactor = (spec.morphEndPos - effectStart) / (effectEnd - effectStart)
					local endMorph = MathUtil.clamp(offsetFactor + endMorphFactor * (1 - offsetFactor), offsetFactor, 1)

					effect:setMorphPosition(startMorph, endMorph)
				end
			end

			spec.isEffectDirty = false
		end

		spec.scrollUpdateTime = math.max(spec.scrollUpdateTime - dt, 0)
		local doScrollUpdate = spec.scrollUpdateTime > 0

		if doScrollUpdate ~= spec.lastScrollUpdate then
			if doScrollUpdate then
				g_animationManager:startAnimations(spec.animationNodes)
			else
				g_animationManager:stopAnimations(spec.animationNodes)
			end

			for _, effect in pairs(spec.effects) do
				if effect.setScrollUpdate ~= nil then
					effect:setScrollUpdate(doScrollUpdate)
				end
			end

			spec.lastScrollUpdate = doScrollUpdate
		end
	end
end

function ConveyorBelt:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local spec = self.spec_conveyorBelt
	local parentFactor = superFunc(self, dischargeNode)

	if spec.dischargeNodeIndex == dischargeNode.index then
		if spec.morphEndPos == 1 then
			return spec.emptyFactor
		else
			return 0
		end
	end

	return parentFactor
end

function ConveyorBelt:handleDischargeOnEmpty(superFunc, dischargeNode)
	local spec = self.spec_conveyorBelt

	if dischargeNode.index ~= spec.dischargeNodeIndex then
		superFunc(self, dischargeNode)
	end
end

function ConveyorBelt:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local spec = self.spec_conveyorBelt

	if dischargeNode.index ~= spec.dischargeNodeIndex then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function ConveyorBelt:getIsEnterable(superFunc)
	return (self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil) and superFunc(self)
end

function ConveyorBelt:getShowOnMap(superFunc)
	return true
end

function ConveyorBelt:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_conveyorBelt

	if spec.fillUnitIndex == fillUnitIndex then
		local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

		if fillLevelDelta > 0 then
			spec.morphStartPos = 0
			spec.morphEndPos = math.max(spec.morphEndPos, fillLevel / self:getFillUnitCapacity(fillUnitIndex))
			spec.isEffectDirty = true
		end

		if fillLevelDelta ~= 0 then
			spec.scrollUpdateTime = 1000
		end

		if fillLevel == 0 then
			g_effectManager:stopEffects(spec.effects)

			spec.morphStartPos = 0
			spec.morphEndPos = 0
			spec.isEffectDirty = true
		else
			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)
		end
	end
end

function ConveyorBelt:onMovingToolChanged(movingTool, speed, dt)
	local spec = self.spec_conveyorBelt

	if spec.offsets ~= nil then
		local offset = spec.movingToolToOffset[movingTool]

		if offset ~= nil then
			local state = Cylindered.getMovingToolState(self, movingTool)

			if state ~= offset.lastState then
				local updateDelay = false

				for _, entry in pairs(offset.effects) do
					local effectState = state

					if entry.inverted then
						effectState = 1 - effectState
					end

					entry.effect:setOffset(MathUtil.lerp(entry.minValue, entry.maxValue, effectState))

					updateDelay = true
				end

				if updateDelay then
					spec.currentDelay = 0

					for _, effect in pairs(spec.effects) do
						if effect.planeFadeTime ~= nil then
							spec.currentDelay = spec.currentDelay + effect.planeFadeTime - effect.offset
						end
					end
				end

				offset.lastState = state
			end
		end
	end
end

function ConveyorBelt:updateDebugValues(values)
	local spec = self.spec_conveyorBelt

	table.insert(values, {
		name = "offset",
		value = spec.offset
	})
	table.insert(values, {
		name = "morphStartPos",
		value = spec.morphStartPos
	})
	table.insert(values, {
		name = "morphEndPos",
		value = spec.morphEndPos
	})
end
