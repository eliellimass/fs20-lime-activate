BunkerSiloCompacter = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function BunkerSiloCompacter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getBunkerSiloCompacter", BunkerSiloCompacter.getBunkerSiloCompacter)
end

function BunkerSiloCompacter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BunkerSiloCompacter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BunkerSiloCompacter)
end

function BunkerSiloCompacter:onLoad(savegame)
	local spec = self.spec_bunkerSiloCompacter
	spec.scale = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.bunkerSiloCompacter#compactingScale"), 1)
	spec.refNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.bunkerSiloCompacter#refNode"), self.i3dMappings)

	if self.isClient then
		spec.compactingSample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.bunkerSiloCompacter.sounds", "compacting", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
end

function BunkerSiloCompacter:getBunkerSiloCompacter()
	return self.spec_bunkerSiloCompacter
end

function BunkerSiloCompacter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and self.getWheels ~= nil then
		local spec = self.spec_bunkerSiloCompacter
		local isCompacting = false

		for _, wheel in ipairs(self:getWheels()) do
			if wheel.contact ~= Wheels.WHEEL_NO_CONTACT then
				isCompacting = true

				break
			end
		end

		if isCompacting then
			if not g_soundManager:getIsSamplePlaying(spec.compactingSample) then
				g_soundManager:playSample(spec.compactingSample)
			end
		elseif g_soundManager:getIsSamplePlaying(spec.compactingSample) then
			g_soundManager:stopSample(spec.compactingSample)
		end
	end
end
