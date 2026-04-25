FillTriggerVehicle = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
}

function FillTriggerVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", FillTriggerVehicle.getDrawFirstFillText)
end

function FillTriggerVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillTriggerVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillTriggerVehicle)
end

function FillTriggerVehicle:onLoad(savegame)
	local spec = self.spec_fillTriggerVehicle
	local triggerNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.fillTriggerVehicle#triggerNode"), self.i3dMappings)

	if triggerNode ~= nil then
		spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.fillTriggerVehicle#fillUnitIndex"), 1)
		spec.litersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.fillTriggerVehicle#litersPerSecond"), 50)
		spec.fillTrigger = FillTrigger:new(triggerNode, self, spec.fillUnitIndex, spec.litersPerSecond)

		if self:getPropertyState() ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
			spec.fillTrigger:finalize()
		end
	end
end

function FillTriggerVehicle:onDelete()
	local spec = self.spec_fillTriggerVehicle

	if spec.fillTrigger ~= nil then
		spec.fillTrigger:delete()

		spec.fillTrigger = nil
	end
end

function FillTriggerVehicle:getDrawFirstFillText(superFunc)
	local spec = self.spec_fillTriggerVehicle

	if self.isClient and spec.fillUnitIndex ~= nil and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return true
	end

	return superFunc(self)
end
