StumpCutter = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end
}

function StumpCutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "crushSplitShape", StumpCutter.crushSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "stumpCutterSplitShapeCallback", StumpCutter.stumpCutterSplitShapeCallback)
end

function StumpCutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StumpCutter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StumpCutter.getWearMultiplier)
end

function StumpCutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", StumpCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", StumpCutter)
end

function StumpCutter:onLoad(savegame)
	local spec = self.spec_stumpCutter

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.stumpCutter.animationNodes.animationNode", "stumbCutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutterStartSound", "vehicle.stumpCutter.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutterIdleSound", "vehicle.stumpCutter.sounds.idle")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutterWorkSound", "vehicle.stumpCutter.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutterStopSound", "vehicle.stumpCutter.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutter.emitterShape(0)", "vehicle.stumpCutter.effects.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.stumpCutter.particleSystem(0)", "vehicle.stumpCutter.effects.effectNode")

	local baseKey = "vehicle.stumpCutter"
	spec.cutNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. "#cutNode"), self.i3dMappings)
	spec.cutSizeY = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#cutSizeY"), 1)
	spec.cutSizeZ = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#cutSizeZ"), 1)
	spec.cutFullTreeThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#cutFullTreeThreshold"), 0.4)
	spec.cutPartThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#cutPartThreshold"), 0.2)

	if self.isClient then
		spec.samples = {
			start = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			idle = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "idle", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.maxWorkFadeTime = 1000
		spec.workFadeTime = 0
		spec.effects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".effects", self.components, self, self.i3dMappings)
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
	end

	spec.maxCutTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#maxCutTime"), 4000)
	spec.nextCutTime = spec.maxCutTime
	spec.maxResetCutTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#maxResetCutTime"), 1000)
	spec.resetCutTime = spec.maxResetCutTime
end

function StumpCutter:onDelete()
	if self.isClient then
		local spec = self.spec_stumpCutter

		g_effectManager:deleteEffects(spec.effects)
		g_soundManager:deleteSamples(spec.samples)
		g_animationManager:deleteAnimations(spec.animationNodes)
	end
end

function StumpCutter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsTurnedOn() then
		local spec = self.spec_stumpCutter

		if spec.cutNode ~= nil then
			spec.curLenAbove = 0
			local x, y, z = getWorldTranslation(spec.cutNode)
			local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
			local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)

			if spec.curSplitShape ~= nil and testSplitShape(spec.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ) == nil then
				spec.curSplitShape = nil
			end

			if spec.curSplitShape == nil then
				local shape, _, _, _, _ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ)

				if shape ~= 0 then
					spec.curSplitShape = shape
				end
			end

			if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
				local x1, y1, z1 = localToWorld(spec.cutNode, 0, 0, spec.cutSizeZ)
				local x2, y2, z2 = localToWorld(spec.cutNode, 0, spec.cutSizeY, 0)

				DebugUtil.drawDebugAreaRectangle(x, y, z, x1, y1, z1, x2, y2, z2, false, 0, 1, 0)
			end

			local isWorking = false

			if spec.curSplitShape ~= nil then
				local lenBelow, lenAbove = getSplitShapePlaneExtents(spec.curSplitShape, x, y, z, nx, ny, nz)
				isWorking = spec.cutPartThreshold <= lenAbove
				spec.workFadeTime = math.min(spec.maxWorkFadeTime, spec.workFadeTime + dt)

				if self.isServer then
					spec.resetCutTime = spec.maxResetCutTime

					if spec.nextCutTime > 0 then
						spec.nextCutTime = spec.nextCutTime - dt

						if spec.nextCutTime <= 0 then
							local _, ly, _ = worldToLocal(spec.curSplitShape, x, y, z)

							if (lenBelow <= spec.cutFullTreeThreshold or ly < spec.cutPartThreshold + 0.01) and lenAbove < 1 then
								self:crushSplitShape(spec.curSplitShape)

								spec.curSplitShape = nil
							elseif spec.cutPartThreshold <= lenAbove then
								spec.nextCutTime = spec.maxCutTime
								local curSplitShape = spec.curSplitShape
								spec.curSplitShape = nil
								spec.curLenAbove = lenAbove

								splitShape(curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, spec.cutSizeY, spec.cutSizeZ, "stumpCutterSplitShapeCallback", self)
							else
								spec.curSplitShape = nil
								spec.nextCutTime = spec.maxCutTime
							end
						end
					end
				end
			else
				spec.workFadeTime = math.max(0, spec.workFadeTime - dt)

				if self.isServer and spec.resetCutTime > 0 then
					spec.resetCutTime = spec.resetCutTime - dt

					if spec.resetCutTime <= 0 then
						spec.nextCutTime = spec.maxCutTime
					end
				end
			end

			if self.isClient then
				if isWorking then
					g_effectManager:setFillType(spec.effects, FillType.WOODCHIPS)
					g_effectManager:startEffects(spec.effects)

					if not g_soundManager:getIsSamplePlaying(spec.samples.work) then
						g_soundManager:playSample(spec.samples.work)
					end
				else
					g_effectManager:stopEffects(spec.effects)

					if g_soundManager:getIsSamplePlaying(spec.samples.work) then
						g_soundManager:stopSample(spec.samples.work)
					end
				end
			end
		end
	end
end

function StumpCutter:onDeactivate()
	if self.isClient then
		local spec = self.spec_stumpCutter

		g_effectManager:stopEffects(spec.effects)
	end
end

function StumpCutter:onTurnedOn()
	if self.isClient then
		local spec = self.spec_stumpCutter

		g_soundManager:stopSamples(spec.samples)
		g_soundManager:playSample(spec.samples.start)
		g_soundManager:playSample(spec.samples.idle, 0, spec.samples.start)
		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function StumpCutter:onTurnedOff()
	if self.isClient then
		local spec = self.spec_stumpCutter
		spec.workFadeTime = 0

		g_effectManager:stopEffects(spec.effects)
		g_soundManager:stopSamples(spec.samples)
		g_soundManager:playSample(spec.samples.stop)
		g_animationManager:stopAnimations(spec.animationNodes)
	end
end

function StumpCutter:crushSplitShape(shape)
	if self.isServer then
		local range = 10
		local x, _, z = getWorldTranslation(shape)

		g_densityMapHeightManager:setCollisionMapAreaDirty(x - range, z - range, x + range, z + range)
		delete(shape)
	end
end

function StumpCutter:stumpCutterSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local spec = self.spec_stumpCutter

	if not isBelow then
		if spec.curLenAbove < 1 then
			self:crushSplitShape(shape)
		end
	else
		local yPos = minY + (maxY - minY) / 2
		local zPos = minZ + (maxZ - minZ) / 2
		local _, y, _ = localToWorld(spec.cutNode, -0.05, yPos, zPos)
		local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, getWorldTranslation(spec.cutNode))

		if y < height then
			self:crushSplitShape(shape)
		else
			spec.curSplitShape = shape
		end
	end
end

function StumpCutter:getDirtMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_stumpCutter

	if spec.curSplitShape ~= nil then
		multiplier = multiplier + self:getWorkDirtMultiplier()
	end

	return multiplier
end

function StumpCutter:getWearMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_stumpCutter

	if spec.curSplitShape ~= nil then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end
