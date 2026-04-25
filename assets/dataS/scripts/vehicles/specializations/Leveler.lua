Leveler = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(BunkerSiloInteractor, specializations)
	end
}

function Leveler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsLevelerPickupNodeActive", Leveler.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "loadLevelerNodeFromXML", Leveler.loadLevelerNodeFromXML)
end

function Leveler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Leveler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Leveler)
end

function Leveler:onLoad(savegame)
	local spec = self.spec_leveler

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.leveler.levelerNode#index", "vehicle.leveler.levelerNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.levelerEffects", "vehicle.leveler.effects")

	spec.nodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.leveler.levelerNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local levelerNode = {}

		if self:loadLevelerNodeFromXML(levelerNode, self.xmlFile, key) then
			table.insert(spec.nodes, levelerNode)
		end

		i = i + 1
	end

	spec.pickUpDirection = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.leveler.pickUpDirection"), 1)
	spec.fillUnitIndex = getXMLInt(self.xmlFile, "vehicle.leveler#fillUnitIndex")
	spec.litersToPickup = 0

	if not self:getFillUnitExists(spec.fillUnitIndex) then
		g_logManager:xmlWarning(self.configFileName, "Unknown fillUnitIndex '%s' for leveler", tostring(spec.fillUnitIndex))
	end

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.leveler.effects", self.components, self, self.i3dMappings)
	end
end

function Leveler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_leveler

	if self.isClient then
		local fillType = self:getFillUnitFillType(spec.fillUnitIndex)
		local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
		local visible = fillLevel > 2 * g_densityMapHeightManager:getMinValidLiterValue(fillType)

		if visible and fillType ~= FillType.UNKNOWN then
			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)

			local fillPercentage = fillLevel / self:getFillUnitCapacity(spec.fillUnitIndex)

			for _, effect in pairs(spec.effects) do
				effect:setFillLevel(fillPercentage)
				effect:setLastVehicleSpeed(self.movingDirection * self:getLastSpeed())
			end
		else
			g_effectManager:stopEffects(spec.effects)
		end
	end

	if self.isServer then
		for _, levelerNode in pairs(spec.nodes) do
			local x0, y0, z0 = localToWorld(levelerNode.node, -levelerNode.width, 0, levelerNode.maxDropDirOffset)
			local x1, y1, z1 = localToWorld(levelerNode.node, levelerNode.width, 0, levelerNode.maxDropDirOffset)

			if not g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getOwnerFarmId(), x0, z0) or not g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getOwnerFarmId(), x1, z1) then
				break
			end

			local pickedUpFillLevel = 0
			local fillType = self:getFillUnitFillType(spec.fillUnitIndex)
			local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

			if fillType == FillType.UNKNOWN or fillLevel < g_densityMapHeightManager:getMinValidLiterValue(fillType) + 0.001 then
				local newFillType = DensityMapHeightUtil.getFillTypeAtLine(x0, y0, z0, x1, y1, z1, 0.5 * levelerNode.maxDropDirOffset)

				if newFillType ~= FillType.UNKNOWN and newFillType ~= fillType then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge)

					fillType = newFillType
				end
			end

			local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillType)

			if fillType ~= FillType.UNKNOWN and heightType ~= nil then
				local innerRadius = 0
				local outerRadius = DensityMapHeightUtil.getDefaultMaxRadius(fillType)
				local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)

				if self:getIsLevelerPickupNodeActive(levelerNode) and spec.pickUpDirection == self.movingDirection then
					local sx, sy, sz = localToWorld(levelerNode.node, -levelerNode.width, 0, 0)
					local ex, ey, ez = localToWorld(levelerNode.node, levelerNode.width, 0, 0)
					fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
					local delta = -(capacity - fillLevel)
					local numHeightLimitChecks = levelerNode.numHeightLimitChecks

					if numHeightLimitChecks > 0 then
						local movementY = 0

						for i = 0, numHeightLimitChecks do
							local t = i / numHeightLimitChecks
							local xi = sx + (ex - sx) * t
							local yi = sy + (ey - sy) * t
							local zi = sz + (ez - sz) * t
							local hi = DensityMapHeightUtil.getHeightAtWorldPos(xi, yi, zi)
							movementY = math.max(movementY, hi - 0.05 - yi)
						end

						if movementY > 0 then
							sy = sy + movementY
							ey = ey + movementY
						end
					end

					levelerNode.lastPickUp, levelerNode.lineOffsetPickUp = DensityMapHeightUtil.tipToGroundAroundLine(self, delta, fillType, sx, sy - 0.1, sz, ex, ey - 0.1, ez, innerRadius, outerRadius, levelerNode.lineOffsetPickUp, true, nil)

					if levelerNode.lastPickUp < 0 then
						levelerNode.lastPickUp = levelerNode.lastPickUp + spec.litersToPickup
						spec.litersToPickup = 0

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -levelerNode.lastPickUp, fillType, ToolType.UNDEFINED, nil)

						pickedUpFillLevel = levelerNode.lastPickUp
					end
				end

				fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

				if fillLevel > 0 then
					local f = fillLevel / capacity
					local width = MathUtil.lerp(levelerNode.minDropWidth, levelerNode.maxDropWidth, f)
					local sx, sy, sz = localToWorld(levelerNode.node, -width, 0, 0)
					local ex, ey, ez = localToWorld(levelerNode.node, width, 0, 0)
					local yOffset = -0.15000000000000002
					levelerNode.lastDrop1, levelerNode.lineOffsetDrop1 = DensityMapHeightUtil.tipToGroundAroundLine(self, fillLevel, fillType, sx, sy + yOffset, sz, ex, ey + yOffset, ez, innerRadius, outerRadius, levelerNode.lineOffsetDrop1, true, tipOcclusionAreas)

					if levelerNode.lastDrop1 > 0 then
						local leftOver = fillLevel - levelerNode.lastDrop1

						if leftOver <= g_densityMapHeightManager:getMinValidLiterValue(fillType) then
							levelerNode.lastDrop1 = fillLevel
							spec.litersToPickup = spec.litersToPickup + leftOver
						end

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -levelerNode.lastDrop1, fillType, ToolType.UNDEFINED, nil)
					end
				end

				fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

				if fillLevel > 0 then
					local f = fillLevel / capacity
					local width = MathUtil.lerp(levelerNode.minDropWidth, levelerNode.maxDropWidth, f)
					local yOffset = MathUtil.lerp(levelerNode.minDropHeight, levelerNode.maxDropHeight, f)
					local sx, sy, sz = localToWorld(levelerNode.node, -width, 0, 0)
					local ex, ey, ez = localToWorld(levelerNode.node, width, 0, 0)
					local dx, dy, dz = localDirectionToWorld(levelerNode.node, 0, 0, 1)
					local backOffset = -outerRadius * spec.pickUpDirection * 1.5
					local backLen = MathUtil.lerp(levelerNode.minDropDirOffset, levelerNode.maxDropDirOffset, f) - backOffset
					local backX = dx * backOffset
					local backY = dy * backOffset
					local backZ = dz * backOffset
					dz = dz * backLen
					dy = dy * backLen
					dx = dx * backLen
					local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

					if terrainHeightUpdater ~= nil then
						addDensityMapHeightOcclusionArea(terrainHeightUpdater, sx + backX, sy + backY, sz + backZ, ex - sx, ey - sy, ez - sz, dx, dy, dz, true)

						if width < levelerNode.width - 0.05 then
							local sx2, sy2, sz2 = localToWorld(levelerNode.node, -levelerNode.width, 0, 0)
							local ex2, ey2, ez2 = localToWorld(levelerNode.node, levelerNode.width, 0, 0)

							addDensityMapHeightOcclusionArea(terrainHeightUpdater, sx2 + backX, sy2 + backY, sz2 + backZ, sx - sx2, sy - sy2, sz - sz2, dx, dy, dz, false)
							addDensityMapHeightOcclusionArea(terrainHeightUpdater, ex + backX, ey + backY, ez + backZ, ex2 - ex, ey2 - ey, ez2 - ez, dx, dy, dz, false)
						end
					end

					levelerNode.lastDrop2, levelerNode.lineOffsetDrop2 = DensityMapHeightUtil.tipToGroundAroundLine(self, fillLevel, fillType, sx, sy + yOffset, sz, ex, ey + yOffset, ez, 0, outerRadius, levelerNode.lineOffsetDrop2, true, nil)

					if levelerNode.lastDrop2 > 0 then
						local leftOver = fillLevel - levelerNode.lastDrop2

						if leftOver <= g_densityMapHeightManager:getMinValidLiterValue(fillType) then
							levelerNode.lastDrop2 = fillLevel
							spec.litersToPickup = spec.litersToPickup + leftOver
						end

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -levelerNode.lastDrop2, fillType, ToolType.UNDEFINED, nil)
					end
				end
			end

			if pickedUpFillLevel < 0 and fillType ~= FillType.UNKNOWN then
				self:notifiyBunkerSilo(pickedUpFillLevel, fillType)
			end
		end
	end
end

function Leveler:loadLevelerNodeFromXML(levelerNode, xmlFile, key)
	levelerNode.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if levelerNode.node ~= nil then
		levelerNode.width = getXMLFloat(xmlFile, key .. "#width")
		levelerNode.minDropWidth = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minDropWidth"), levelerNode.width * 0.5)
		levelerNode.maxDropWidth = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDropWidth"), levelerNode.width)
		levelerNode.minDropHeight = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minDropHeight"), 0)
		levelerNode.maxDropHeight = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDropHeight"), 1)
		levelerNode.minDropDirOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minDropDirOffset"), 0.7)
		levelerNode.maxDropDirOffset = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDropDirOffset"), 0.7)
		levelerNode.numHeightLimitChecks = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#numHeightLimitChecks"), 6)
		levelerNode.lineOffsetPickUp = nil
		levelerNode.lineOffsetDrop = nil
		levelerNode.lastPickUp = 0
		levelerNode.lastDrop = 0

		return true
	end

	return false
end

function Leveler:getIsLevelerPickupNodeActive(levelerNode)
	return true
end
