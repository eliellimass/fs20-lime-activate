PowerConsumer = {}

function PowerConsumer.initSpecialization()
	g_storeManager:addSpecType("neededPower", "shopListAttributeIconPowerReq", PowerConsumer.loadSpecValueNeededPower, PowerConsumer.getSpecValueNeededPower)
end

function PowerConsumer.prerequisitesPresent(specializations)
	return true
end

function PowerConsumer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerSetup", PowerConsumer.loadPowerSetup)
	SpecializationUtil.registerFunction(vehicleType, "getPtoRpm", PowerConsumer.getPtoRpm)
	SpecializationUtil.registerFunction(vehicleType, "getDoConsumePtoPower", PowerConsumer.getDoConsumePtoPower)
	SpecializationUtil.registerFunction(vehicleType, "getPowerMultiplier", PowerConsumer.getPowerMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getConsumedPtoTorque", PowerConsumer.getConsumedPtoTorque)
	SpecializationUtil.registerFunction(vehicleType, "getConsumingLoad", PowerConsumer.getConsumingLoad)
end

function PowerConsumer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", PowerConsumer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", PowerConsumer.getTurnedOnNotAllowedWarning)
end

function PowerConsumer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerConsumer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PowerConsumer)
end

function PowerConsumer:onLoad(savegame)
	local spec = self.spec_powerConsumer
	spec.forceNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.powerConsumer#forceNode"), self.i3dMappings)
	spec.forceDirNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.powerConsumer#forceDirNode"), self.i3dMappings), spec.forceNode)
	spec.forceFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.powerConsumer#forceFactor"), 1)
	spec.maxForce = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.powerConsumer#maxForce"), 0)
	spec.forceDir = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.powerConsumer#forceDir"), 1)
	spec.turnOnNotAllowedWarning = string.format(g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.powerConsumer#turnOnNotAllowedWarning"), "warning_insufficientPowerOutput"), self.customEnvironment), self.typeDesc)

	self:loadPowerSetup(self.xmlFile)
end

function PowerConsumer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer and self.isActive then
		local spec = self.spec_powerConsumer

		if spec.forceNode ~= nil and self.movingDirection == spec.forceDir then
			local multiplier = self:getPowerMultiplier()

			if multiplier ~= 0 then
				local frictionForce = spec.forceFactor * self.lastSpeedReal * 1000 * self:getTotalMass(false) / (dt / 1000)
				local force = -math.min(frictionForce, spec.maxForce) * self.movingDirection * multiplier
				local dx, dy, dz = localDirectionToWorld(spec.forceDirNode, 0, 0, force)
				local px, py, pz = getCenterOfMass(spec.forceNode)

				addForce(spec.forceNode, dx, dy, dz, px, py, pz, true)

				if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS and self:getIsActiveForInput() then
					local str = string.format("frictionForce=%.2f maxForce=%.2f -> force=%.2f", frictionForce, spec.maxForce, force)

					renderText(0.7, 0.85, getCorrectTextSize(0.02), str)
				end
			end
		end
	end
end

function PowerConsumer:loadPowerSetup(xmlFile)
	local spec = self.spec_powerConsumer

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, "vehicle.powerConsumer#neededPtoPower", "vehicle.powerConsumer#neededMinPtoPower and vehicle.powerConsumer#neededMaxPtoPower")

	spec.neededMaxPtoPower = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#neededMaxPtoPower"), 0)
	spec.neededMinPtoPower = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#neededMinPtoPower"), spec.neededMaxPtoPower)

	if spec.neededMaxPtoPower < spec.neededMinPtoPower then
		g_logManager:xmlWarning(self.configFileName, "'vehicle.powerConsumer#neededMaxPtoPower' is smaller than 'vehicle.powerConsumer#neededMinPtoPower'")
	end

	spec.ptoRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.powerConsumer#ptoRpm"), 0)
end

function PowerConsumer:getPtoRpm()
	if self:getDoConsumePtoPower() then
		return self.spec_powerConsumer.ptoRpm
	end

	return 0
end

function PowerConsumer:getDoConsumePtoPower()
	return self.getIsTurnedOn ~= nil and self:getIsTurnedOn()
end

function PowerConsumer:getPowerMultiplier()
	return 1
end

function PowerConsumer:getConsumedPtoTorque(expected)
	if self:getDoConsumePtoPower() or expected ~= nil and expected then
		local spec = self.spec_powerConsumer
		local rpm = spec.ptoRpm

		if rpm > 0.001 then
			local consumingLoad, count = self:getConsumingLoad()

			if count > 0 then
				consumingLoad = consumingLoad / count
			else
				consumingLoad = 1
			end

			local neededPtoPower = spec.neededMinPtoPower + consumingLoad * (spec.neededMaxPtoPower - spec.neededMinPtoPower)

			return neededPtoPower / (rpm * math.pi / 30)
		end
	end

	return 0
end

function PowerConsumer:getConsumingLoad()
	return 0, 0
end

function PowerConsumer:getCanBeTurnedOn(superFunc)
	local rootVehicle = self:getRootVehicle()

	if rootVehicle ~= nil and rootVehicle.getMotor ~= nil then
		local rootMotor = rootVehicle:getMotor()
		local torqueRequested = self:getConsumedPtoTorque(true)
		torqueRequested = torqueRequested + PowerConsumer.getTotalConsumedPtoTorque(rootVehicle, self)
		torqueRequested = torqueRequested / rootMotor:getPtoMotorRpmRatio()

		if torqueRequested > 0 and torqueRequested > 0.9 * rootMotor:getPeakTorque() and not self:getIsTurnedOn() then
			return false, true
		end
	end

	if superFunc ~= nil then
		return superFunc(self)
	else
		return true, false
	end
end

function PowerConsumer:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_powerConsumer
	local _, notEnoughPower = PowerConsumer.getCanBeTurnedOn(self)

	if notEnoughPower then
		return spec.turnOnNotAllowedWarning
	else
		return superFunc(self)
	end
end

function PowerConsumer:getTotalConsumedPtoTorque(excludeVehicle)
	local torque = 0

	if self ~= excludeVehicle and self.getConsumedPtoTorque ~= nil then
		torque = self:getConsumedPtoTorque()
	end

	if self.getAttachedImplements ~= nil then
		local attachedImplements = self:getAttachedImplements()

		for _, implement in pairs(attachedImplements) do
			torque = torque + PowerConsumer.getTotalConsumedPtoTorque(implement.object, excludeVehicle)
		end
	end

	return torque
end

function PowerConsumer:getMaxPtoRpm()
	local rpm = 0

	if self.getPtoRpm ~= nil then
		rpm = self:getPtoRpm()
	end

	if self.getAttachedImplements ~= nil then
		local attachedImplements = self:getAttachedImplements()

		for _, implement in pairs(attachedImplements) do
			rpm = math.max(rpm, PowerConsumer.getMaxPtoRpm(implement.object))
		end
	end

	return rpm
end

function consoleSetPowerConsumer(neededMinPtoPower, neededMaxPtoPower, forceFactor, maxForce, forceDir, ptoRpm)
	if neededMinPtoPower == nil then
		return "No arguments given! Usage: gsSetPowerConsumer <neededMinPtoPower> <neededMaxPtoPower> <forceFactor> <maxForce> <forceDir> <ptoRpm>"
	end

	local object = nil

	if g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle:getSelectedImplement() ~= nil and g_currentMission.controlledVehicle:getSelectedImplement().object.spec_powerConsumer ~= nil then
		object = g_currentMission.controlledVehicle:getSelectedImplement().object
	end

	if object ~= nil then
		object.spec_powerConsumer.neededMinPtoPower = Utils.getNoNil(neededMinPtoPower, object.spec_powerConsumer.neededMinPtoPower)
		object.spec_powerConsumer.neededMaxPtoPower = Utils.getNoNil(neededMaxPtoPower, object.spec_powerConsumer.neededMaxPtoPower)
		object.spec_powerConsumer.forceFactor = Utils.getNoNil(forceFactor, object.spec_powerConsumer.forceFactor)
		object.spec_powerConsumer.maxForce = Utils.getNoNil(maxForce, object.spec_powerConsumer.maxForce)
		object.spec_powerConsumer.forceDir = Utils.getNoNil(forceDir, object.spec_powerConsumer.forceDir)
		object.spec_powerConsumer.ptoRpm = Utils.getNoNil(ptoRpm, object.spec_powerConsumer.ptoRpm)

		for _, veh in pairs(g_currentMission.vehicles) do
			if veh.configFileName == object.configFileName then
				veh.spec_powerConsumer.neededMinPtoPower = object.spec_powerConsumer.neededMinPtoPower
				veh.spec_powerConsumer.neededMaxPtoPower = object.spec_powerConsumer.neededMaxPtoPower
				veh.spec_powerConsumer.forceFactor = object.spec_powerConsumer.forceFactor
				veh.spec_powerConsumer.maxForce = object.spec_powerConsumer.maxForce
				veh.spec_powerConsumer.forceDir = object.spec_powerConsumer.forceDir
				veh.spec_powerConsumer.ptoRpm = object.spec_powerConsumer.ptoRpm
			end
		end
	else
		return "No vehicle with powerConsumer specialization selected"
	end
end

addConsoleCommand("gsSetPowerConsumer", "Sets properties of the powerConsumer specialization", "consoleSetPowerConsumer", nil)

function PowerConsumer.loadSpecValueNeededPower(xmlFile, customEnvironment)
	return getXMLString(xmlFile, "vehicle.storeData.specs.neededPower")
end

function PowerConsumer.getSpecValueNeededPower(storeItem, realItem)
	if storeItem.specs.neededPower ~= nil then
		local hp, kw = g_i18n:getPower(storeItem.specs.neededPower)

		return string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(kw), MathUtil.round(hp))
	end

	return nil
end
