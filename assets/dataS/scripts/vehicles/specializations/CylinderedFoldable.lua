CylinderedFoldable = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Cylindered, specializations) and SpecializationUtil.hasSpecialization(Foldable, specializations)
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CylinderedFoldable)
	end,
	onPostLoad = function (self, savegame)
		if Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.cylindered#loadMovingToolStatesAfterFolding"), false) then
			Cylindered.onPostLoad(self, savegame)
		end
	end
}
