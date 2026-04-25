source("dataS/scripts/vehicles/specializations/events/RidgeMarkerSetStateEvent.lua")

RidgeMarker = {
	SEND_NUM_BITS = 3
}
RidgeMarker.MAX_NUM_RIDGEMARKERS = 2^RidgeMarker.SEND_NUM_BITS

function RidgeMarker.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("ridgemarker", false)
end

function RidgeMarker.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function RidgeMarker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRidgeMarker", RidgeMarker.loadRidgeMarker)
	SpecializationUtil.registerFunction(vehicleType, "setRidgeMarkerState", RidgeMarker.setRidgeMarkerState)
	SpecializationUtil.registerFunction(vehicleType, "canFoldRidgeMarker", RidgeMarker.canFoldRidgeMarker)
	SpecializationUtil.registerFunction(vehicleType, "processRidgeMarkerArea", RidgeMarker.processRidgeMarkerArea)
end

function RidgeMarker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", RidgeMarker.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", RidgeMarker.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", RidgeMarker.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", RidgeMarker.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", RidgeMarker.getCanBeSelected)
end

function RidgeMarker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", RidgeMarker)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", RidgeMarker)
end

function RidgeMarker:onLoad(savegame)
	local spec = self.spec_ridgeMarker

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.ridgeMarkers", "vehicle.ridgeMarker")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.ridgeMarkers.ridgeMarker", "vehicle.ridgeMarker.marker")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.ridgeMarker.ridgeMarker", "vehicle.ridgeMarker.marker")

	local inputButtonStr = getXMLString(self.xmlFile, "vehicle.ridgeMarker#inputButton")

	if inputButtonStr ~= nil then
		spec.ridgeMarkerInputButton = InputAction[inputButtonStr]
	end

	spec.ridgeMarkerInputButton = Utils.getNoNil(spec.ridgeMarkerInputButton, InputAction.IMPLEMENT_EXTRA4)
	spec.ridgeMarkers = {}
	spec.workAreaToRidgeMarker = {}
	local i = 0

	while true do
		local key = string.format("vehicle.ridgeMarker.marker(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		if table.getn(spec.ridgeMarkers) >= RidgeMarker.MAX_NUM_RIDGEMARKERS - 1 then
			g_logManager:xmlError(self.configFileName, "Too many ridgeMarker states. Only %d states are supported!", RidgeMarker.MAX_NUM_RIDGEMARKERS - 1)

			break
		end

		local ridgeMarker = {}

		if self:loadRidgeMarker(self.xmlFile, key, ridgeMarker) then
			table.insert(spec.ridgeMarkers, ridgeMarker)

			spec.workAreaToRidgeMarker[ridgeMarker.workAreaIndex] = ridgeMarker
		end

		i = i + 1
	end

	spec.numRigdeMarkers = table.getn(spec.ridgeMarkers)
	spec.ridgeMarkerMinFoldTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.ridgeMarker#foldMinLimit"), 0)
	spec.ridgeMarkerMaxFoldTime = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.ridgeMarker#foldMaxLimit"), 1)
	spec.foldDisableDirection = getXMLInt(self.xmlFile, "vehicle.ridgeMarker#foldDisableDirection")
	spec.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.ridgeMarker#onlyActiveWhenLowered"), true)
	spec.ridgeMarkerState = 0
	spec.directionNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.ridgeMarker#directionNode"), self.i3dMappings)
end

function RidgeMarker:onPostLoad(savegame)
	local spec = self.spec_ridgeMarker

	if spec.numRigdeMarkers > 0 and savegame ~= nil then
		local state = getXMLInt(savegame.xmlFile, savegame.key .. ".ridgeMarker#state")

		if state ~= nil then
			self:setRidgeMarkerState(state, true)

			if state ~= 0 then
				AnimatedVehicle.updateAnimationByName(self, spec.ridgeMarkers[state].animName, 9999999)
			end
		end
	end
end

function RidgeMarker:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_ridgeMarker

	if spec.numRigdeMarkers > 0 then
		setXMLInt(xmlFile, key .. "#state", spec.ridgeMarkerState)
	end
end

function RidgeMarker:onReadStream(streamId, connection)
	local spec = self.spec_ridgeMarker

	if spec.numRigdeMarkers > 0 then
		local state = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)

		self:setRidgeMarkerState(state, true)

		if state ~= 0 then
			AnimatedVehicle.updateAnimationByName(self, spec.ridgeMarkers[state].animName, 9999999)
		end
	end
end

function RidgeMarker:onWriteStream(streamId, connection)
	local spec = self.spec_ridgeMarker

	if spec.numRigdeMarkers > 0 then
		streamWriteUIntN(streamId, spec.ridgeMarkerState, RidgeMarker.SEND_NUM_BITS)
	end
end

function RidgeMarker:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		RidgeMarker.updateActionEvents(self)
	end
end

function RidgeMarker:loadRidgeMarker(xmlFile, key, ridgeMarker)
	ridgeMarker.animName = getXMLString(xmlFile, key .. "#animName")
	ridgeMarker.minWorkLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#minWorkLimit"), 0.99)
	ridgeMarker.maxWorkLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxWorkLimit"), 1)
	ridgeMarker.liftedAnimTime = getXMLFloat(xmlFile, key .. "#liftedAnimTime")
	ridgeMarker.workAreaIndex = getXMLInt(xmlFile, key .. "#workAreaIndex")

	if ridgeMarker.workAreaIndex == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'workAreaIndex' for ridgeMarker '%s'!", key)

		return false
	end

	return true
end

function RidgeMarker:setRidgeMarkerState(state, noEventSend)
	local spec = self.spec_ridgeMarker

	if spec.ridgeMarkerState ~= state then
		RidgeMarkerSetStateEvent.sendEvent(self, state, noEventSend)

		if spec.ridgeMarkerState ~= 0 then
			local animTime = self:getAnimationTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName)

			self:playAnimation(spec.ridgeMarkers[spec.ridgeMarkerState].animName, -1, animTime, true)
		end

		spec.ridgeMarkerState = state

		if spec.ridgeMarkerState ~= 0 then
			if spec.ridgeMarkers[spec.ridgeMarkerState].liftedAnimTime ~= nil and not self:getIsLowered(true) then
				self:setAnimationStopTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName, spec.ridgeMarkers[spec.ridgeMarkerState].liftedAnimTime)
			end

			local animTime = self:getAnimationTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName)

			self:playAnimation(spec.ridgeMarkers[spec.ridgeMarkerState].animName, 1, animTime, true)
		end
	end
end

function RidgeMarker:canFoldRidgeMarker(state)
	local spec = self.spec_ridgeMarker
	local foldAnimTime = nil

	if self.getFoldAnimTime ~= nil then
		foldAnimTime = self:getFoldAnimTime()

		if foldAnimTime < spec.ridgeMarkerMinFoldTime or spec.ridgeMarkerMaxFoldTime < foldAnimTime then
			return false
		end
	end

	local foldableSpec = self.spec_foldable

	if state ~= 0 and not foldableSpec.moveToMiddle and spec.foldDisableDirection ~= nil and (spec.foldDisableDirection == foldableSpec.foldMoveDirection or foldableSpec.foldMoveDirection == 0) then
		return false
	end

	return true
end

function RidgeMarker:processRidgeMarkerArea(workArea, dt)
	local spec = self.spec_ridgeMarker
	local x, _, z = getWorldTranslation(workArea.startTest)
	local x1, _, z1 = getWorldTranslation(workArea.widthTest)
	local x2, _, z2 = getWorldTranslation(workArea.heightTest)
	local cultivatorArea = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.cultivatorValue, x, z, x1, z1, x2, z2)
	local plowArea = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.plowValue, x, z, x1, z1, x2, z2)
	local x, _, z = getWorldTranslation(workArea.start)
	local x1, _, z1 = getWorldTranslation(workArea.width)
	local x2, _, z2 = getWorldTranslation(workArea.height)
	local sowingArea = FSDensityMapUtil.getAreaDensity(g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, g_currentMission.sowingValue, x, z, x1, z1, x2, z2)

	if sowingArea > 0 or cultivatorArea > 0 or plowArea > 0 then
		local wx = x1 - x
		local wz = z1 - z
		local hx = x2 - x
		local hz = z2 - z
		local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize
		x = math.floor(x * worldToDensity + 0.5) / worldToDensity
		z = math.floor(z * worldToDensity + 0.5) / worldToDensity
		z1 = z + wz
		x1 = x + wx
		z2 = z + hz
		x2 = x + hx
		local dx, _, dz = localDirectionToWorld(Utils.getNoNil(spec.directionNode, self.rootNode), 0, 0, 1)
		local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)

		if cultivatorArea < plowArea then
			FSDensityMapUtil.updateCultivatorArea(x, z, x1, z1, x2, z2, false, false, angle, nil)
		else
			FSDensityMapUtil.updatePlowArea(x, z, x1, z1, x2, z2, false, false, angle, false)
		end

		FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
	end

	return 0, 0
end

function RidgeMarker:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. ".area#startIndexTest", key .. ".testArea#startNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. ".area#widthIndexTest", key .. ".testArea#widthNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. ".area#heightIndexTest", key .. ".testArea#heightNode")

	local startTest = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".testArea#startNode"), self.i3dMappings)
	local widthTest = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".testArea#widthNode"), self.i3dMappings)
	local heightTest = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".testArea#heightNode"), self.i3dMappings)

	if startTest ~= nil and widthTest ~= nil and heightTest ~= nil then
		workArea.startTest = startTest
		workArea.widthTest = widthTest
		workArea.heightTest = heightTest

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#animName")

		if workArea.type == WorkAreaType.DEFAULT then
			workArea.type = WorkAreaType.RIDGEMARKER
		end
	elseif workArea.type == WorkAreaType.RIDGEMARKER then
		g_logManager:xmlWarning(self.configFileName, "Missing test area for ridge marker area '%s'", key)
	end

	return true
end

function RidgeMarker:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.ridgeMarkerAnim = getXMLString(xmlFile, key .. "#ridgeMarkerAnim")
	speedRotatingPart.ridgeMarkerAnimTimeMax = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#ridgeMarkerAnimTimeMax"), 0.99)

	return true
end

function RidgeMarker:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.ridgeMarkerAnim ~= nil and self:getAnimationTime(speedRotatingPart.ridgeMarkerAnim) < speedRotatingPart.ridgeMarkerAnimTimeMax then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function RidgeMarker:getCanBeSelected(superFunc)
	return true
end

function RidgeMarker:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.RIDGEMARKER then
		local spec = self.spec_ridgeMarker
		local ridgeMarker = spec.workAreaToRidgeMarker[workArea.index]

		if ridgeMarker ~= nil then
			local animTime = self:getAnimationTime(ridgeMarker.animName)

			if ridgeMarker.maxWorkLimit < animTime or animTime < ridgeMarker.minWorkLimit then
				return false
			end

			if spec.onlyActiveWhenLowered and not self:getIsLowered(false) then
				return false
			end
		end
	end

	return superFunc(self, workArea)
end

function RidgeMarker:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_ridgeMarker

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.numRigdeMarkers > 0 then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.ridgeMarkerInputButton, self, RidgeMarker.actionEventToggleRidgeMarkers, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_toggleRidgeMarker"))
		end
	end
end

function RidgeMarker:onSetLowered(lowered)
	local spec = self.spec_ridgeMarker

	if lowered then
		for _, ridgeMarker in pairs(spec.ridgeMarkers) do
			if ridgeMarker.liftedAnimTime ~= nil then
				local animTime = self:getAnimationTime(ridgeMarker.animName)

				if animTime == ridgeMarker.liftedAnimTime then
					self:playAnimation(ridgeMarker.animName, 1, animTime, true)
				end
			end
		end
	else
		for _, ridgeMarker in pairs(spec.ridgeMarkers) do
			if ridgeMarker.liftedAnimTime ~= nil then
				local animTime = self:getAnimationTime(ridgeMarker.animName)

				if ridgeMarker.liftedAnimTime < animTime then
					self:setAnimationStopTime(ridgeMarker.animName, ridgeMarker.liftedAnimTime)
					self:playAnimation(ridgeMarker.animName, -1, animTime, true)
				end
			end
		end
	end
end

function RidgeMarker:onFoldStateChanged(direction, moveToMiddle)
	if not moveToMiddle and direction > 0 then
		self:setRidgeMarkerState(0, true)
	end
end

function RidgeMarker:onAIImplementStart()
	self:setRidgeMarkerState(0, true)
end

function RidgeMarker:actionEventToggleRidgeMarkers(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_ridgeMarker
	local newState = (spec.ridgeMarkerState + 1) % (spec.numRigdeMarkers + 1)

	if self:canFoldRidgeMarker(newState) then
		self:setRidgeMarkerState(newState)
	end
end

function RidgeMarker:updateActionEvents()
	local spec = self.spec_ridgeMarker
	local actionEvent = spec.actionEvents[spec.ridgeMarkerInputButton]

	if actionEvent ~= nil then
		local isVisible = false

		if spec.numRigdeMarkers > 0 then
			local newState = (spec.ridgeMarkerState + 1) % (spec.numRigdeMarkers + 1)

			if self:canFoldRidgeMarker(newState) then
				isVisible = true
			end
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, isVisible)
	end
end
