WorkArea = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("default", false)
		g_workAreaTypeManager:addWorkAreaType("auxiliary", false)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(GroundReference, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onStartWorkAreaProcessing")
		SpecializationUtil.registerEvent(vehicleType, "onEndWorkAreaProcessing")
	end
}

function WorkArea.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWorkAreaFromXML", WorkArea.loadWorkAreaFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getWorkAreaByIndex", WorkArea.getWorkAreaByIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaActive", WorkArea.getIsWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "setWorkAreaProcessingTime", WorkArea.setWorkAreaProcessingTime)
	SpecializationUtil.registerFunction(vehicleType, "getIsWorkAreaProcessing", WorkArea.getIsWorkAreaProcessing)
	SpecializationUtil.registerFunction(vehicleType, "getTypedNetworkAreas", WorkArea.getTypedNetworkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getTypedWorkAreas", WorkArea.getTypedWorkAreas)
	SpecializationUtil.registerFunction(vehicleType, "getIsTypedWorkAreaActive", WorkArea.getIsTypedWorkAreaActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsFarmlandNotOwnedWarningShown", WorkArea.getIsFarmlandNotOwnedWarningShown)
	SpecializationUtil.registerFunction(vehicleType, "getLastTouchedFarmlandFarmId", WorkArea.getLastTouchedFarmlandFarmId)
	SpecializationUtil.registerFunction(vehicleType, "getIsAccessibleAtWorldPosition", WorkArea.getIsAccessibleAtWorldPosition)
end

function WorkArea.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", WorkArea.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", WorkArea.getIsSpeedRotatingPartActive)
end

function WorkArea.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkArea)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkArea)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", WorkArea)
end

function WorkArea:onLoad(savegame)
	local spec = self.spec_workArea

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#startIndex", "vehicle.workAreas.workArea(0).area#startIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#widthIndex", "vehicle.workAreas.workArea(0).area#widthIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#heightIndex", "vehicle.workAreas.workArea(0).area#heightIndex")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#foldMinLimit", "vehicle.workAreas.workArea(0).folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#foldMaxLimit", "vehicle.workAreas.workArea(0).folding#maxLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.workAreas.workArea(0)#refNodeIndex", "vehicle.workAreas.workArea(0).groundReferenceNode#index")

	spec.workAreas = {}
	local i = 0

	while true do
		local key = string.format("vehicle.workAreas.workArea(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local workArea = {}

		if self:loadWorkAreaFromXML(workArea, self.xmlFile, key) then
			table.insert(spec.workAreas, workArea)

			workArea.index = #spec.workAreas
		end

		i = i + 1
	end

	spec.workAreaByType = {}

	for _, area in pairs(spec.workAreas) do
		if spec.workAreaByType[area.type] == nil then
			spec.workAreaByType[area.type] = {}
		end

		table.insert(spec.workAreaByType[area.type], area)
	end

	spec.lastAccessedFarmlandOwner = 0
	spec.showFarmlandNotOwnedWarning = false
end

function WorkArea:getIsAccessibleAtWorldPosition(farmId, x, z, workAreaType)
	if self.propertyState == Vehicle.PROPERTY_STATE_MISSION then
		return g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType)
	end

	local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)

	if farmlandId == nil then
		return false
	end

	if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
		return true, FarmlandManager.NO_OWNER_FARM_ID
	end

	local landOwner = g_farmlandManager:getFarmlandOwner(farmlandId)
	local accessible = landOwner ~= 0 and g_currentMission.accessHandler:canFarmAccessOtherId(farmId, landOwner) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType)

	return accessible, landOwner
end

function WorkArea:getLastTouchedFarmlandFarmId()
	local spec = self.spec_workArea

	if spec.lastAccessedFarmlandOwner ~= 0 then
		return spec.lastAccessedFarmlandOwner
	end

	return 0
end

function WorkArea:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workArea

	SpecializationUtil.raiseEvent(self, "onStartWorkAreaProcessing", dt, spec.workAreas)

	spec.showFarmlandNotOwnedWarning = false
	local hasProcessed = false
	local isOwned = false
	local allowWarning = false

	for _, workArea in ipairs(spec.workAreas) do
		if workArea.type ~= WorkAreaType.AUXILIARY then
			workArea.lastWorkedHectares = 0
			local isAreaActive = self:getIsWorkAreaActive(workArea)

			if isAreaActive and workArea.requiresOwnedFarmland then
				local farmId = self:getActiveFarm()

				if farmId == nil then
					farmId = AccessHandler.EVERYONE
				end

				local xs, _, zs = getWorldTranslation(workArea.start)
				local isAccessible, farmlandOwner = self:getIsAccessibleAtWorldPosition(farmId, xs, zs, workArea.type)

				if isAccessible then
					if farmlandOwner ~= nil then
						spec.lastAccessedFarmlandOwner = farmlandOwner
					end

					isOwned = true
				else
					local xw, _, zw = getWorldTranslation(workArea.width)

					if self:getIsAccessibleAtWorldPosition(farmId, xw, zw, workArea.type) then
						isOwned = true
					else
						local xh, _, zh = getWorldTranslation(workArea.height)

						if self:getIsAccessibleAtWorldPosition(farmId, xh, zh, workArea.type) then
							isOwned = true
						else
							local x = xw + xh - xs
							local z = zw + zh - zs

							if self:getIsAccessibleAtWorldPosition(farmId, x, z, workArea.type) then
								isOwned = true
							end
						end
					end
				end

				if not isOwned then
					isAreaActive = false
				end

				allowWarning = true
			end

			if isAreaActive then
				if workArea.preprocessingFunction ~= nil then
					workArea.preprocessingFunction(self, workArea, dt)
				end

				if workArea.processingFunction ~= nil then
					local realArea, _ = workArea.processingFunction(self, workArea, dt)
					workArea.lastWorkedHectares = MathUtil.areaToHa(realArea, g_currentMission:getFruitPixelsToSqm())

					if workArea.lastWorkedHectares > 0 then
						self:setWorkAreaProcessingTime(workArea, g_currentMission.time)
					end

					if g_wildlifeSpawnerManager ~= nil and realArea > 0 then
						local workAreaType = g_workAreaTypeManager:getWorkAreaTypeByIndex(workArea.type)

						if workAreaType.attractWildlife then
							local xw, _, zw = getWorldTranslation(workArea.width)
							local xh, _, zh = getWorldTranslation(workArea.height)
							local radius = 3
							local posX = 0.5 * xw + 0.5 * xh
							local posZ = 0.5 * zw + 0.5 * zh
							local lifeTime = 0

							g_wildlifeSpawnerManager:addAreaOfInterest(lifeTime, posX, posZ, radius)
						end
					end
				end

				if workArea.postprocessingFunction ~= nil then
					workArea.postprocessingFunction(self, workArea, dt)
				end

				hasProcessed = true
			end
		end
	end

	if allowWarning and not isOwned then
		spec.showFarmlandNotOwnedWarning = true
	end

	SpecializationUtil.raiseEvent(self, "onEndWorkAreaProcessing", dt, hasProcessed)
end

function WorkArea:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workArea

	if spec.showFarmlandNotOwnedWarning then
		if self.propertyState == Vehicle.PROPERTY_STATE_MISSION then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_cantUseMissionVehiclesOnOtherLand"))
		else
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
		end
	end
end

function WorkArea:loadWorkAreaFromXML(workArea, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".area#startIndex", key .. ".area#startNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".area#widthIndex", key .. ".area#widthNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".area#heightIndex", key .. ".area#heightNode")

	local start = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".area#startNode"), self.i3dMappings)
	local width = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".area#widthNode"), self.i3dMappings)
	local height = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. ".area#heightNode"), self.i3dMappings)

	if start ~= nil and width ~= nil and height ~= nil then
		local areaTypeStr = getXMLString(xmlFile, key .. "#type")
		workArea.type = g_workAreaTypeManager:getWorkAreaTypeIndexByName(areaTypeStr) or WorkAreaType.DEFAULT

		if workArea.type == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid workArea type '%s' for workArea '%s'!", areaTypeStr, key)

			return false
		end

		workArea.isSynchronized = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isSynchronized"), true)
		workArea.requiresGroundContact = Utils.getNoNil(getXMLBool(xmlFile, key .. "#requiresGroundContact"), true)

		if workArea.type ~= WorkAreaType.AUXILIARY then
			if workArea.requiresGroundContact then
				XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#refNodeIndex", key .. ".groundReferenceNode#index")

				local groundReferenceNodeIndex = getXMLInt(xmlFile, key .. ".groundReferenceNode#index")

				if groundReferenceNodeIndex == nil then
					g_logManager:xmlWarning(self.configFileName, "Missing groundReference 'groundReferenceNode#index' for workArea '%s'. Add requiresGroundContact=\"false\" if groundContact is not required!", key)

					return false
				end

				local groundReferenceNode = self:getGroundReferenceNodeFromIndex(groundReferenceNodeIndex)

				if groundReferenceNode ~= nil then
					workArea.groundReferenceNode = groundReferenceNode
				else
					g_logManager:xmlWarning(self.configFileName, "Invalid groundReferenceNode-index for workArea '%s'!", key)

					return false
				end
			end

			workArea.disableBackwards = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disableBackwards"), true)
			workArea.functionName = getXMLString(xmlFile, key .. "#functionName")

			if workArea.functionName == nil then
				g_logManager:xmlWarning(self.configFileName, "Missing 'functionName' for workArea '%s'!", key)

				return false
			else
				if self[workArea.functionName] == nil then
					g_logManager:xmlWarning(self.configFileName, "Given functionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.functionName))

					return false
				end

				workArea.processingFunction = self[workArea.functionName]
			end

			workArea.preprocessFunctionName = getXMLString(xmlFile, key .. "#preprocessFunctionName")

			if workArea.preprocessFunctionName ~= nil then
				if self[workArea.preprocessFunctionName] == nil then
					g_logManager:xmlWarning(self.configFileName, "Given preprocessFunctionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.preprocessFunctionName))

					return false
				end

				workArea.preprocessingFunction = self[workArea.preprocessFunctionName]
			end

			workArea.postprocessFunctionName = getXMLString(xmlFile, key .. "#postprocessFunctionName")

			if workArea.postprocessFunctionName ~= nil then
				if self[workArea.postprocessFunctionName] == nil then
					g_logManager:xmlWarning(self.configFileName, "Given postprocessFunctionName '%s' not defined. Please add missing function or specialization!", tostring(workArea.postprocessFunctionName))

					return false
				end

				workArea.postprocessingFunction = self[workArea.postprocessFunctionName]
			end

			workArea.requiresOwnedFarmland = Utils.getNoNil(getXMLBool(xmlFile, key .. "#requiresOwnedFarmland"), true)
		end

		workArea.lastProcessingTime = 0
		workArea.start = start
		workArea.width = width
		workArea.height = height

		return true
	end

	return false
end

function WorkArea:getWorkAreaByIndex(workAreaIndex)
	local spec = self.spec_workArea

	return spec.workAreas[workAreaIndex]
end

function WorkArea:getIsWorkAreaActive(workArea)
	local isActive = true

	if workArea.requiresGroundContact == true and workArea.groundReferenceNode ~= nil then
		isActive = self:getIsGroundReferenceNodeActive(workArea.groundReferenceNode)
	end

	if isActive and workArea.disableBackwards then
		isActive = isActive and self.movingDirection > 0
	end

	return isActive
end

function WorkArea:setWorkAreaProcessingTime(workArea, time)
	workArea.lastProcessingTime = time
end

function WorkArea:getIsWorkAreaProcessing(workArea)
	return g_currentMission.time <= workArea.lastProcessingTime + 200
end

function WorkArea:getTypedNetworkAreas(areaType, needsFieldProperty)
	local workAreasSend = {}
	local area = 0
	local typedWorkAreas = self:getTypedWorkAreas(areaType)
	local showFarmlandNotOwnedWarning = false

	for _, workArea in pairs(typedWorkAreas) do
		if self:getIsWorkAreaActive(workArea) then
			local x, _, z = getWorldTranslation(workArea.start)
			local isAccessible = not needsFieldProperty

			if needsFieldProperty then
				local farmId = g_currentMission:getFarmId()
				isAccessible = g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, areaType)
			end

			if isAccessible then
				local x1, _, z1 = getWorldTranslation(workArea.width)
				local x2, _, z2 = getWorldTranslation(workArea.height)
				area = area + math.abs((z1 - z) * (x2 - x) - (x1 - x) * (z2 - z))

				table.insert(workAreasSend, {
					x,
					z,
					x1,
					z1,
					x2,
					z2
				})
			else
				showFarmlandNotOwnedWarning = true
			end
		end
	end

	return workAreasSend, showFarmlandNotOwnedWarning, area
end

function WorkArea:getTypedWorkAreas(areaType)
	local spec = self.spec_workArea

	return Utils.getNoNil(spec.workAreaByType[areaType], {})
end

function WorkArea:getIsTypedWorkAreaActive(areaType)
	local isActive = false
	local typedWorkAreas = self:getTypedWorkAreas(areaType)

	for _, workArea in pairs(typedWorkAreas) do
		if self:getIsWorkAreaActive(workArea) then
			isActive = true

			break
		end
	end

	return isActive, typedWorkAreas
end

function WorkArea:getIsFarmlandNotOwnedWarningShown()
	return self.spec_workArea.showFarmlandNotOwnedWarning
end

function WorkArea:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.workAreaIndex = getXMLInt(xmlFile, key .. "#workAreaIndex")

	return true
end

function WorkArea:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.workAreaIndex ~= nil then
		local spec = self.spec_workArea
		local workArea = spec.workAreas[speedRotatingPart.workAreaIndex]

		if workArea == nil then
			speedRotatingPart.workAreaIndex = nil

			g_logManager:xmlWarning(self.configFileName, "Invalid workAreaIndex '%s'. Indexing starts with 1!", tostring(speedRotatingPart.workAreaIndex))

			return true
		end

		if not self:getIsWorkAreaProcessing(spec.workAreas[speedRotatingPart.workAreaIndex]) then
			return false
		end
	end

	return superFunc(self, speedRotatingPart)
end
