FertilizingCultivator = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Cultivator, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
	end
}

function FertilizingCultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", FertilizingCultivator.processCultivatorArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", FertilizingCultivator.setSprayerAITerrainDetailProhibitedRange)
end

function FertilizingCultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingCultivator)
end

function FertilizingCultivator:onLoad(savegame)
	local spec = self.spec_fertilizingCultivator
	spec.needsSetIsTurnedOn = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.fertilizingCultivator#needsSetIsTurnedOn"), false)
	self.spec_sprayer.useSpeedLimit = false
end

function FertilizingCultivator:processCultivatorArea(superFunc, workArea, dt)
	local spec = self.spec_fertilizingCultivator
	local specCultivator = self.spec_cultivator
	local specSpray = self.spec_sprayer
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local cultivatorParams = specCultivator.workAreaParameters
	local sprayerParams = specSpray.workAreaParameters
	local sprayTypeIndex = SprayType.FERTILIZER

	if sprayerParams.sprayFillLevel <= 0 or spec.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		sprayTypeIndex = nil
	end

	local cultivatorChangedArea, cultivatorTotalArea = FSDensityMapUtil.updateCultivatorArea(xs, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, not cultivatorParams.limitGrassDestructionToField, cultivatorParams.angle, sprayTypeIndex)
	cultivatorParams.lastChangedArea = cultivatorParams.lastChangedArea + cultivatorChangedArea
	cultivatorParams.lastTotalArea = cultivatorParams.lastTotalArea + cultivatorTotalArea
	cultivatorParams.lastStatsArea = cultivatorParams.lastStatsArea + cultivatorChangedArea

	if specCultivator.isSubsoiler then
		FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
	end

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	if sprayTypeIndex ~= nil then
		local sprayChangedArea, sprayTotalArea = FSDensityMapUtil.updateSprayArea(xs, zs, xw, zw, xh, zh, sprayTypeIndex)
		sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + sprayChangedArea
		sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + sprayTotalArea
		sprayerParams.lastStatsArea = 0
		sprayerParams.isActive = true
	end

	specCultivator.isWorking = true

	return cultivatorChangedArea, cultivatorTotalArea
end

function FertilizingCultivator:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
	if self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailProhibitedRange()

		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

		if sprayTypeDesc ~= nil then
			self:addAITerrainDetailProhibitedRange(1, 2, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels)
			self:addAITerrainDetailProhibitedRange(g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelMaxValue, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels)
		end
	end
end
