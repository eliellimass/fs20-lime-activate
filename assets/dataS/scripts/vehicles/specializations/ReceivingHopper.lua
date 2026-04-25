source("dataS/scripts/vehicles/specializations/events/ReceivingHopperSetCreateBoxesEvent.lua")

ReceivingHopper = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end
}

function ReceivingHopper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setCreateBoxes", ReceivingHopper.setCreateBoxes)
	SpecializationUtil.registerFunction(vehicleType, "getCanSpawnNextBox", ReceivingHopper.getCanSpawnNextBox)
	SpecializationUtil.registerFunction(vehicleType, "collisionTestCallback", ReceivingHopper.collisionTestCallback)
	SpecializationUtil.registerFunction(vehicleType, "createBox", ReceivingHopper.createBox)
end

function ReceivingHopper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", ReceivingHopper.handleDischargeRaycast)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", ReceivingHopper.getCanBeSelected)
end

function ReceivingHopper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ReceivingHopper)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ReceivingHopper)
end

function ReceivingHopper:onLoad(savegame)
	local spec = self.spec_receivingHopper

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper#unloadingDelay", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper#unloadInfoIndex", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper#dischargeInfoIndex", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.tipTrigger#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.boxTrigger#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.fillScrollerNodes.fillScrollerNode", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.boxTrigger#litersPerMinute", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.raycastNode#index", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.raycastNode#raycastLength", "Dischargeable functionalities")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.boxTrigger#boxSpawnPlaceIndex", "vehicle.receivingHopper.boxes#spawnPlaceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.receivingHopper.boxTrigger.box(0)", "vehicle.receivingHopper.boxes.box(0)")

	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.receivingHopper#fillUnitIndex"), 1)
	spec.spawnPlace = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.receivingHopper.boxes#spawnPlaceNode"), self.i3dMappings)
	spec.boxes = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.receivingHopper.boxes.box(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local fillTypeStr = getXMLString(self.xmlFile, baseName .. "#fillType")
		local filename = getXMLString(self.xmlFile, baseName .. "#filename")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex ~= nil then
			spec.boxes[fillTypeIndex] = filename
		else
			g_logManager:xmlWarning(self.configFileName, "Invalid fillType '%s'", fillTypeStr)
		end

		i = i + 1
	end

	spec.createBoxes = false
	spec.lastBox = nil

	if savegame ~= nil then
		spec.createBoxes = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. ".receivingHopper#createBoxes"), spec.createBoxes)
	end
end

function ReceivingHopper:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_receivingHopper

	setXMLBool(xmlFile, key .. "#createBoxes", spec.createBoxes)
end

function ReceivingHopper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_receivingHopper

		if spec.createBoxes and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF and self:getCanSpawnNextBox() then
			self:createBox()
		end
	end
end

function ReceivingHopper:setCreateBoxes(state, noEventSend)
	local spec = self.spec_receivingHopper

	if state ~= spec.createBoxes then
		ReceivingHopperSetCreateBoxesEvent.sendEvent(self, state, noEventSend)

		spec.createBoxes = state

		ReceivingHopper.updateActionEvents(self)

		spec.lastBox = nil
	end
end

function ReceivingHopper:getCanSpawnNextBox()
	local spec = self.spec_receivingHopper
	local fillType = self:getFillUnitFillType(spec.fillUnitIndex)

	if spec.boxes[fillType] ~= nil then
		if spec.lastBox ~= nil and spec.lastBox:getFillUnitFreeCapacity(1) > 0 then
			return false
		end

		local xmlFilename = Utils.getFilename(spec.boxes[fillType], self.baseDirectory)
		local sizeWidth, sizeLength, _, _ = StoreItemUtil.getSizeValues(xmlFilename, "vehicle", 0)
		local x, y, z = getWorldTranslation(spec.spawnPlace)
		local rx, ry, rz = getWorldRotation(spec.spawnPlace)
		spec.foundObjectAtSpawnPlace = false

		overlapBox(x, y, z, rx, ry, rz, sizeWidth * 0.5, 2, sizeLength * 0.5, "collisionTestCallback", self, 5468288)

		return not spec.foundObjectAtSpawnPlace
	end

	return false
end

function ReceivingHopper:collisionTestCallback(transformId)
	if (g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil or g_currentMission:getNodeObject(transformId) ~= nil) and g_currentMission.nodeToObject[transformId] ~= self then
		local spec = self.spec_receivingHopper
		spec.foundObjectAtSpawnPlace = true
	end
end

function ReceivingHopper:createBox()
	local spec = self.spec_receivingHopper

	if self.isServer and spec.createBoxes then
		local fillType = self:getFillUnitFillType(spec.fillUnitIndex)

		if spec.boxes[fillType] ~= nil then
			local x, _, z = getWorldTranslation(spec.spawnPlace)
			local dirX, _, dirZ = localDirectionToWorld(spec.spawnPlace, 0, 1, 0)
			local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
			local xmlFilename = Utils.getFilename(spec.boxes[fillType], self.baseDirectory)
			local vehicle = g_currentMission:loadVehicle(xmlFilename, x, nil, z, 0, yRot, true, 0, Vehicle.PROPERTY_STATE_OWNED, self:getOwnerFarmId(), nil, )

			if vehicle ~= nil then
				spec.lastBox = vehicle
			end
		end
	end
end

function ReceivingHopper:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
	local stopDischarge = false

	if hitObject ~= nil then
		local fillType = self:getDischargeFillType(dischargeNode)
		local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)

		if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex) > 0 then
			self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
		else
			stopDischarge = true
		end
	else
		stopDischarge = true
	end

	if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
		self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
	end
end

function ReceivingHopper:getCanBeSelected(superFunc)
	return true
end

function ReceivingHopper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_receivingHopper

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, ReceivingHopper.actionEventToggleBoxCreation, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			ReceivingHopper.updateActionEvents(self)
		end
	end
end

function ReceivingHopper:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if self:getFillUnitFillLevel(fillUnitIndex) > 0 then
		self:raiseActive()
	end
end

function ReceivingHopper:actionEventToggleBoxCreation(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_receivingHopper

	self:setCreateBoxes(not spec.createBoxes)
end

function ReceivingHopper:updateActionEvents()
	local spec = self.spec_receivingHopper
	local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]

	if actionEvent ~= nil then
		if spec.createBoxes then
			g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_disablePalletSpawning"))
		else
			g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_enablePalletSpawning"))
		end
	end
end
