Shovel = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(FillVolume, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations) and SpecializationUtil.hasSpecialization(BunkerSiloInteractor, specializations)
	end
}

function Shovel.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadShovelNode", Shovel.loadShovelNode)
	SpecializationUtil.registerFunction(vehicleType, "getShovelNodeIsActive", Shovel.getShovelNodeIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getCanShovelAtPosition", Shovel.getCanShovelAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "getShovelTipFactor", Shovel.getShovelTipFactor)
end

function Shovel.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Shovel.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", Shovel.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", Shovel.handleDischargeOnEmpty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", Shovel.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", Shovel.getCanToggleDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", Shovel.getCanToggleDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Shovel.getWearMultiplier)
end

function Shovel.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Shovel)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Shovel)
end

function Shovel:onLoad(savegame)
	local spec = self.spec_shovel

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpNode", "vehicle.shovel.shovelNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpWidth", "vehicle.shovel.shovelNode#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpLength", "vehicle.shovel.shovelNode#length")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpYOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpRequiresMovement", "vehicle.shovel.shovelNode#needsMovement")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.shovel#pickUpNeedsToBeTurnedOn", "vehicle.shovel.shovelNode#needsActivation")

	spec.ignoreFillUnitFillType = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.shovel#ignoreFillUnitFillType"), false)
	spec.shovelNodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.shovel.shovelNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local shovelNode = {}

		if self:loadShovelNode(self.xmlFile, key, shovelNode) then
			table.insert(spec.shovelNodes, shovelNode)
		end

		i = i + 1
	end

	spec.shovelDischargeInfo = {
		dischargeNodeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.shovel.dischargeInfo#dischargeNodeIndex"), 1),
		node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.shovel.dischargeInfo#node"), self.i3dMappings)
	}

	if spec.shovelDischargeInfo.node ~= nil then
		local minSpeedAngle = getXMLFloat(self.xmlFile, "vehicle.shovel.dischargeInfo#minSpeedAngle")
		local maxSpeedAngle = getXMLFloat(self.xmlFile, "vehicle.shovel.dischargeInfo#maxSpeedAngle")

		if minSpeedAngle == nil or maxSpeedAngle == nil then
			g_logManager:xmlWarning(self.configFileName, "Missing 'minSpeedAngle' or 'maxSpeedAngle' for dischargeNode 'vehicle.shovel.dischargeInfo'")

			return false
		end

		spec.shovelDischargeInfo.minSpeedAngle = math.rad(minSpeedAngle)
		spec.shovelDischargeInfo.maxSpeedAngle = math.rad(maxSpeedAngle)
	end

	if self.isClient then
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.shovel.fillEffect", self.components, self, self.i3dMappings)
	end

	spec.effectDirtyFlag = self:getNextDirtyFlag()
	spec.loadingFillType = FillType.UNKNOWN
end

function Shovel:onDelete()
	if self.isClient then
		local spec = self.spec_shovel

		g_effectManager:deleteEffects(spec.fillEffects)
	end
end

function Shovel:onReadStream(streamId, connection)
	local spec = self.spec_shovel
	spec.loadingFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
end

function Shovel:onWriteStream(streamId, connection)
	local spec = self.spec_shovel

	streamWriteUIntN(streamId, spec.loadingFillType, FillTypeManager.SEND_NUM_BITS)
end

function Shovel:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_shovel

		if streamReadBool(streamId) then
			spec.loadingFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

function Shovel:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_shovel

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.effectDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, spec.loadingFillType, FillTypeManager.SEND_NUM_BITS)
		end
	end
end

function Shovel:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_shovel

	if self.isServer then
		local validPickupFillType = FillType.UNKNOWN

		for _, shovelNode in pairs(spec.shovelNodes) do
			if self:getShovelNodeIsActive(shovelNode) then
				local fillLevel = self:getFillUnitFillLevel(shovelNode.fillUnitIndex)
				local capacity = self:getFillUnitCapacity(shovelNode.fillUnitIndex)

				if fillLevel < capacity then
					local pickupFillType = self:getFillUnitFillType(shovelNode.fillUnitIndex)

					if fillLevel / capacity < self:getFillTypeChangeThreshold() then
						pickupFillType = FillType.UNKNOWN
					end

					local freeCapacity = math.min(capacity - fillLevel, shovelNode.fillLitersPerSecond * dt)
					local sx, sy, sz = localToWorld(shovelNode.node, -shovelNode.width, shovelNode.yOffset, shovelNode.zOffset)
					local ex, ey, ez = localToWorld(shovelNode.node, shovelNode.width, shovelNode.yOffset, shovelNode.zOffset)
					local innerRadius = shovelNode.length
					local radius = nil

					if self:getCanShovelAtPosition(shovelNode) then
						if pickupFillType == FillType.UNKNOWN or spec.ignoreFillUnitFillType then
							pickupFillType = DensityMapHeightUtil.getFillTypeAtLine(sx, sy, sz, ex, ey, ez, innerRadius)
						end

						if pickupFillType ~= FillType.UNKNOWN and self:getFillUnitSupportsFillType(shovelNode.fillUnitIndex, pickupFillType) then
							local fillDelta, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, -freeCapacity, pickupFillType, sx, sy, sz, ex, ey, ez, innerRadius, radius, shovelNode.lineOffset, true, nil)
							shovelNode.lineOffset = lineOffset

							if fillDelta < 0 then
								local loadInfo = self:getFillVolumeLoadInfo(shovelNode.loadInfoIndex)

								self:addFillUnitFillLevel(self:getOwnerFarmId(), shovelNode.fillUnitIndex, -fillDelta, pickupFillType, ToolType.UNDEFINED, loadInfo)

								validPickupFillType = pickupFillType

								self:notifiyBunkerSilo(fillDelta, pickupFillType)
							end
						end
					end
				end
			end
		end

		if spec.loadingFillType ~= validPickupFillType then
			spec.loadingFillType = validPickupFillType

			self:raiseDirtyFlags(spec.effectDirtyFlag)
		end
	end

	if self.isClient then
		if spec.loadingFillType ~= FillType.UNKNOWN then
			g_effectManager:setFillType(spec.fillEffects, spec.loadingFillType)
			g_effectManager:startEffects(spec.fillEffects)
		else
			g_effectManager:stopEffects(spec.fillEffects)
		end
	end
end

function Shovel:loadShovelNode(xmlFile, key, shovelNode)
	shovelNode.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if shovelNode.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for shovelNode '%s'!", key)

		return false
	end

	shovelNode.fillUnitIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#fillUnitIndex"), 1)
	shovelNode.loadInfoIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#loadInfoIndex"), 1)
	shovelNode.width = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#width"), 1)
	shovelNode.length = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#length"), 0.5)
	shovelNode.yOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#yOffset"), 0)
	shovelNode.zOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#zOffset"), 0)
	shovelNode.needsMovement = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsMovement"), true)
	shovelNode.lastPosition = {
		0,
		0,
		0
	}
	shovelNode.fillLitersPerSecond = (getXMLFloat(xmlFile, key .. "#fillLitersPerSecond") or math.huge) / 1000
	shovelNode.maxPickupAngle = getXMLFloat(xmlFile, key .. "#maxPickupAngle")

	if shovelNode.maxPickupAngle ~= nil then
		shovelNode.maxPickupAngle = math.rad(shovelNode.maxPickupAngle)
	end

	shovelNode.needsAttacherVehicle = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsAttacherVehicle"), true)

	return true
end

function Shovel:getShovelNodeIsActive(shovelNode)
	local isActive = true

	if shovelNode.needsMovement then
		local x, y, z = getWorldTranslation(shovelNode.node)
		local _, _, dz = worldToLocal(shovelNode.node, shovelNode.lastPosition[1], shovelNode.lastPosition[2], shovelNode.lastPosition[3])
		isActive = isActive and dz < 0
		shovelNode.lastPosition[1] = x
		shovelNode.lastPosition[2] = y
		shovelNode.lastPosition[3] = z
	end

	if shovelNode.maxPickupAngle ~= nil then
		local _, dy, _ = localDirectionToWorld(shovelNode.node, 0, 0, 1)
		local angle = math.acos(dy)

		if shovelNode.maxPickupAngle < angle then
			return false
		end
	end

	if shovelNode.needsAttacherVehicle and self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil then
		return false
	end

	return isActive
end

function Shovel:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local spec = self.spec_shovel
	local parentFactor = superFunc(self, dischargeNode)
	local info = spec.shovelDischargeInfo

	if info.node ~= nil and info.dischargeNodeIndex == dischargeNode.index then
		return parentFactor * self:getShovelTipFactor()
	end

	return parentFactor
end

function Shovel:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local spec = self.spec_shovel

	if dischargeNode.index ~= spec.shovelDischargeInfo.dischargeNodeIndex or self.spec_shovel.shovelDischargeInfo.node == nil then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function Shovel:handleDischargeOnEmpty(superFunc, dischargedLiters, minDropReached, hasMinDropFillLevel)
	if self.spec_shovel.shovelDischargeInfo.node == nil then
		superFunc(self, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function Shovel:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	if self.spec_shovel.shovelDischargeInfo.node ~= nil then
		if hitObject ~= nil then
			local fillType = self:getDischargeFillType(dischargeNode)
			local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)

			if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex, fillType, self:getOwnerFarmId()) > 0 then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
			elseif self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
				self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
			end
		else
			local fillLevel = self:getFillUnitFillLevel(dischargeNode.fillUnitIndex)

			if fillLevel > 0 and self:getShovelTipFactor() > 0 then
				if self:getCanDischargeToGround(dischargeNode) then
					self:setDischargeState(Dischargeable.DISCHARGE_STATE_GROUND, true)
				elseif self:getIsActiveForInput(true) then
					if not self:getCanDischargeToLand(dischargeNode) then
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 5000)
					elseif not self:getCanDischargeAtPosition(dischargeNode) then
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"), 5000)
					end
				end
			end
		end
	else
		superFunc(self, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	end
end

function Shovel:getCanToggleDischargeToObject(superFunc)
	if self.spec_shovel.shovelDischargeInfo.node ~= nil then
		return false
	end

	return superFunc(self)
end

function Shovel:getCanToggleDischargeToGround(superFunc)
	if self.spec_shovel.shovelDischargeInfo.node ~= nil then
		return false
	end

	return superFunc(self)
end

function Shovel:getShovelTipFactor()
	local spec = self.spec_shovel
	local info = spec.shovelDischargeInfo

	if info.node ~= nil then
		local _, dy, _ = localDirectionToWorld(info.node, 0, 0, 1)
		local angle = math.acos(dy)

		if info.minSpeedAngle < angle then
			return math.max(0, math.min(1, (angle - info.minSpeedAngle) / (info.maxSpeedAngle - info.minSpeedAngle)))
		end
	end

	return 0
end

function Shovel:getWearMultiplier(superFunc)
	local spec = self.spec_shovel
	local multiplier = superFunc(self)

	if spec.loadingFillType ~= FillType.UNKNOWN then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function Shovel:getCanShovelAtPosition(shovelNode)
	if shovelNode == nil then
		return false
	end

	local sx, _, sz = localToWorld(shovelNode.node, -shovelNode.width, 0, 0)
	local activeFarm = self:getActiveFarm()
	local ex, _, ez = localToWorld(shovelNode.node, shovelNode.width, 0, 0)
	local isStartOwned = g_currentMission.accessHandler:canFarmAccessLand(activeFarm, sx, sz)

	if not isStartOwned then
		return false
	end

	return g_currentMission.accessHandler:canFarmAccessLand(activeFarm, ex, ez)
end

function Shovel:updateDebugValues(values)
	local spec = self.spec_shovel
	local info = spec.shovelDischargeInfo

	if info.node ~= nil then
		local _, dy, _ = localDirectionToWorld(info.node, 0, 0, 1)
		local angle = math.acos(dy)

		table.insert(values, {
			name = "angle",
			value = math.deg(angle)
		})
		table.insert(values, {
			name = "minSpeedAngle",
			value = math.deg(info.minSpeedAngle)
		})
		table.insert(values, {
			name = "maxSpeedAngle",
			value = math.deg(info.maxSpeedAngle)
		})

		if info.minSpeedAngle < angle then
			local factor = math.max(0, math.min(1, (angle - info.minSpeedAngle) / (info.maxSpeedAngle - info.minSpeedAngle)))

			table.insert(values, {
				name = "factor",
				value = factor
			})
		else
			table.insert(values, {
				value = "Out of Range - 0",
				name = "factor"
			})
		end
	end
end
