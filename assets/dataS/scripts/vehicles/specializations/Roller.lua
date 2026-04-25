Roller = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("roller", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Roller.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processRollerArea", Roller.processRollerArea)
end

function Roller.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Roller.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", Roller.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Roller.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Roller.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Roller.getIsWorkAreaActive)
end

function Roller.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Roller)
end

function Roller:onLoad(savegame)
	local spec = self.spec_roller

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.rollerSound", "vehicle.roller.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.onlyActiveWhenLowered#value", "vehicle.roller#onlyActiveWhenLowered")

	if self.isClient then
		spec.samples = {}
		spec.isWorkSamplePlaying = false
		spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.roller.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	spec.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.roller#onlyActiveWhenLowered"), true)
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.isWorking = false
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Roller:onDelete()
	if self.isClient then
		local spec = self.spec_roller

		g_soundManager:deleteSamples(spec.samples)
	end
end

function Roller:processRollerArea(workArea, dt)
	local spec = self.spec_roller
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local realArea = FSDensityMapUtil.updateRollerArea(xs, zs, xw, zw, xh, zh)

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return realArea
end

function Roller:doCheckSpeedLimit(superFunc)
	local spec = self.spec_roller

	return superFunc(self) or spec.isWorking
end

function Roller:getDoGroundManipulation(superFunc)
	local spec = self.spec_roller

	return superFunc(self) and spec.isWorking
end

function Roller:getDirtMultiplier(superFunc)
	local spec = self.spec_roller
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier()
	end

	return multiplier
end

function Roller:getWearMultiplier(superFunc)
	local spec = self.spec_roller
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function Roller:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.ROLLER then
		local spec = self.spec_roller

		if g_currentMission.time < spec.startActivationTime then
			return false
		end

		if spec.onlyActiveWhenLowered and not self:getIsLowered() then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Roller:onStartWorkAreaProcessing(dt)
	local spec = self.spec_roller
	spec.isWorking = false
end

function Roller:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_roller

	if self.isClient then
		if spec.isWorking then
			if not spec.isWorkSamplePlaying then
				g_soundManager:playSample(spec.samples.work)

				spec.isWorkSamplePlaying = true
			end
		elseif spec.isWorkSamplePlaying then
			g_soundManager:stopSample(spec.samples.work)

			spec.isWorkSamplePlaying = false
		end
	end
end

function Roller:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_roller
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function Roller:onDeactivate()
	local spec = self.spec_roller

	g_soundManager:stopSample(spec.samples.work)

	spec.isWorkSamplePlaying = false
end

function Roller.getDefaultSpeedLimit()
	return 15
end
