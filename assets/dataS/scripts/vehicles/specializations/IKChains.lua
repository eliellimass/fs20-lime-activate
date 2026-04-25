IKChains = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", IKChains)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdate", IKChains)
	end,
	onLoad = function (self, savegame)
		local spec = self.spec_ikChains
		spec.chains = {}
		local i = 0

		while true do
			local key = string.format("vehicle.ikChains.ikChain(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			IKUtil.loadIKChain(self.xmlFile, key, self.components, self.components, spec.chains, self.getParentComponent, self)

			i = i + 1
		end

		IKUtil.updateAlignNodes(spec.chains, self.getParentComponent, self, nil)
	end,
	onUpdate = function (self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		local spec = self.spec_ikChains

		IKUtil.updateIKChains(spec.chains)
	end
}
