source("dataS/scripts/vehicles/specializations/events/CylinderedEasyControlChangeEvent.lua")

Cylindered = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onMovingToolChanged")
	end
}

function Cylindered.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingPartFromXML", Cylindered.loadMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingToolFromXML", Cylindered.loadMovingToolFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentMovingTools", Cylindered.loadDependentMovingTools)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentParts", Cylindered.loadDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentComponentJoints", Cylindered.loadDependentComponentJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAttacherJoints", Cylindered.loadDependentAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentWheels", Cylindered.loadDependentWheels)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentTranslatingParts", Cylindered.loadDependentTranslatingParts)
	SpecializationUtil.registerFunction(vehicleType, "loadExtraDependentParts", Cylindered.loadExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAnimations", Cylindered.loadDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "loadCopyLocalDirectionParts", Cylindered.loadCopyLocalDirectionParts)
	SpecializationUtil.registerFunction(vehicleType, "loadRotationBasedLimits", Cylindered.loadRotationBasedLimits)
	SpecializationUtil.registerFunction(vehicleType, "setMovingToolDirty", Cylindered.setMovingToolDirty)
	SpecializationUtil.registerFunction(vehicleType, "updateCylinderedInitial", Cylindered.updateCylinderedInitial)
	SpecializationUtil.registerFunction(vehicleType, "allowLoadMovingToolStates", Cylindered.allowLoadMovingToolStates)
	SpecializationUtil.registerFunction(vehicleType, "getMovingToolByNode", Cylindered.getMovingToolByNode)
	SpecializationUtil.registerFunction(vehicleType, "getMovingPartByNode", Cylindered.getMovingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsMovingToolActive", Cylindered.getIsMovingToolActive)
	SpecializationUtil.registerFunction(vehicleType, "setDelayedData", Cylindered.setDelayedData)
	SpecializationUtil.registerFunction(vehicleType, "updateDelayedTool", Cylindered.updateDelayedTool)
	SpecializationUtil.registerFunction(vehicleType, "updateEasyControl", Cylindered.updateEasyControl)
	SpecializationUtil.registerFunction(vehicleType, "setIsEasyControlActive", Cylindered.setIsEasyControlActive)
	SpecializationUtil.registerFunction(vehicleType, "updateExtraDependentParts", Cylindered.updateExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentAnimations", Cylindered.updateDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentToolLimits", Cylindered.updateDependentToolLimits)
end

function Cylindered.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Cylindered.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadObjectChangeValuesFromXML", Cylindered.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setObjectChangeValues", Cylindered.setObjectChangeValues)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", Cylindered.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Cylindered.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Cylindered.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Cylindered.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicMountGrabFromXML", Cylindered.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDynamicMountGrabOpened", Cylindered.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", Cylindered.setComponentJointFrame)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalSchemaText", Cylindered.getAdditionalSchemaText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cylindered.getWearMultiplier)
end

function Cylindered.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cylindered)
end

function Cylindered:onLoad(savegame)
	local spec = self.spec_cylindered

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.movingParts", "vehicle.cylindered.movingParts")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.movingTools", "vehicle.cylindered.movingTools")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.cylinderedHydraulicSound", "vehicle.cylindered.sounds.hydraulic")

	spec.samples = {}

	if self.isClient then
		spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.isHydraulicSamplePlaying = false
	end

	spec.activeDirtyMovingParts = {}
	local referenceNodes = {}
	spec.nodesToMovingParts = {}
	spec.movingParts = {}
	self.anyMovingPartsDirty = false
	spec.detachLockNodes = nil
	local i = 0

	while true do
		local partKey = string.format("vehicle.cylindered.movingParts.movingPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, partKey) then
			break
		end

		local entry = {}

		if self:loadMovingPartFromXML(self.xmlFile, partKey, entry) then
			if referenceNodes[entry.node] == nil then
				referenceNodes[entry.node] = {}
			end

			if spec.nodesToMovingParts[entry.node] == nil then
				table.insert(referenceNodes[entry.node], entry)
				self:loadDependentParts(self.xmlFile, partKey, entry)
				self:loadDependentComponentJoints(self.xmlFile, partKey, entry)
				self:loadCopyLocalDirectionParts(self.xmlFile, partKey, entry)
				self:loadExtraDependentParts(self.xmlFile, partKey, entry)
				self:loadDependentAnimations(self.xmlFile, partKey, entry)

				entry.key = partKey

				table.insert(spec.movingParts, entry)

				if entry.isActiveDirty then
					table.insert(spec.activeDirtyMovingParts, entry)
				end

				spec.nodesToMovingParts[entry.node] = entry
			else
				g_logManager:xmlWarning(self.configFileName, "Moving part with node '%s' already exists!", getName(entry.node))
			end
		end

		i = i + 1
	end

	spec.isActiveDirtyTimeOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.cylindered.movingParts#isActiveDirtyTimeOffset"), 0) * 1000
	spec.isActiveDirtyTime = g_currentMission.time

	for _, part in pairs(spec.movingParts) do
		part.dependentParts = {}

		for _, ref in pairs(part.dependentPartNodes) do
			if referenceNodes[ref] ~= nil then
				for _, p in pairs(referenceNodes[ref]) do
					part.dependentParts[p] = p
					p.isDependentPart = true
				end
			end
		end
	end

	local function addMovingPart(part, newTable, allowDependentParts)
		for _, addedPart in ipairs(newTable) do
			if addedPart == part then
				return
			end
		end

		if part.isDependentPart == true and allowDependentParts ~= true then
			return
		end

		table.insert(newTable, part)

		for _, depPart in pairs(part.dependentParts) do
			addMovingPart(depPart, newTable, true)
		end
	end

	local newParts = {}

	for _, part in ipairs(spec.movingParts) do
		addMovingPart(part, newParts)
	end

	spec.movingParts = newParts
	spec.controlGroups = {}
	spec.controlGroupMapping = {}
	spec.currentControlGroupIndex = 1
	spec.controlGroupNames = {}
	local i = 0

	while true do
		local groupKey = string.format("vehicle.cylindered.movingTools.controlGroups.controlGroup(%d)", i)

		if not hasXMLProperty(self.xmlFile, groupKey) then
			break
		end

		local name = getXMLString(self.xmlFile, groupKey .. "#name")

		if name ~= nil then
			table.insert(spec.controlGroupNames, g_i18n:convertText(name, self.customEnvironment))
		end

		i = i + 1
	end

	spec.nodesToMovingTools = {}
	spec.movingTools = {}
	local i = 0

	while true do
		local toolKey = string.format("vehicle.cylindered.movingTools.movingTool(%d)", i)

		if not hasXMLProperty(self.xmlFile, toolKey) then
			break
		end

		local entry = {}

		if self:loadMovingToolFromXML(self.xmlFile, toolKey, entry) then
			if referenceNodes[entry.node] == nil then
				referenceNodes[entry.node] = {}
			end

			if spec.nodesToMovingTools[entry.node] == nil then
				table.insert(referenceNodes[entry.node], entry)
				self:loadDependentMovingTools(self.xmlFile, toolKey, entry)
				self:loadDependentParts(self.xmlFile, toolKey, entry)
				self:loadDependentComponentJoints(self.xmlFile, toolKey, entry)
				self:loadExtraDependentParts(self.xmlFile, toolKey, entry)
				self:loadDependentAnimations(self.xmlFile, toolKey, entry)

				entry.isActive = true
				entry.key = toolKey

				table.insert(spec.movingTools, entry)

				spec.nodesToMovingTools[entry.node] = entry
			else
				g_logManager:xmlWarning(self.configFileName, "Moving tool with node '%s' already exists!", getName(entry.node))
			end
		end

		i = i + 1
	end

	for _, groupIndex in ipairs(spec.controlGroups) do
		local subSelectionIndex = self:addSubselection(groupIndex)
		spec.controlGroupMapping[subSelectionIndex] = groupIndex
	end

	for _, part in pairs(spec.movingTools) do
		part.dependentParts = {}

		for _, ref in pairs(part.dependentPartNodes) do
			if referenceNodes[ref] ~= nil then
				for _, p in pairs(referenceNodes[ref]) do
					part.dependentParts[p] = p
				end
			end
		end

		for i = #part.dependentMovingTools, 1, -1 do
			local dependentTool = part.dependentMovingTools[i]
			local tool = spec.nodesToMovingTools[dependentTool.node]

			if tool ~= nil then
				dependentTool.movingTool = tool
			else
				g_logManager:xmlWarning(self.configFileName, "Dependent moving tool '%s' not defined. Ignoring it!", getName(dependentTool.node))
				table.remove(part.dependentMovingTools, i)
			end
		end
	end

	local simpleKey = "vehicle.cylindered.movingTools.easyArmControl"

	if hasXMLProperty(self.xmlFile, simpleKey) then
		spec.easyArmControl = {
			rootNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, simpleKey .. "#rootNode"), self.i3dMappings),
			targetNodeY = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, simpleKey .. "#node"), self.i3dMappings)
		}
		spec.easyArmControl.targetNodeZ = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, simpleKey .. "#targetNodeZ"), self.i3dMappings) or spec.easyArmControl.targetNodeY

		if spec.easyArmControl.targetNodeZ ~= nil and spec.easyArmControl.targetNodeY ~= nil then
			local targetYTool = self:getMovingToolByNode(spec.easyArmControl.targetNodeY)
			local targetZTool = self:getMovingToolByNode(spec.easyArmControl.targetNodeZ)

			if targetYTool ~= nil and targetZTool ~= nil then
				spec.easyArmControl.targetNode = spec.easyArmControl.targetNodeZ

				if getParent(spec.easyArmControl.targetNodeY) == spec.easyArmControl.targetNodeZ then
					spec.easyArmControl.targetNode = spec.easyArmControl.targetNodeY
				end

				spec.easyArmControl.targetRefNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, simpleKey .. "#refNode"), self.i3dMappings)
				spec.easyArmControl.lastValidPositionY = {
					getTranslation(spec.easyArmControl.targetNodeY)
				}
				spec.easyArmControl.lastValidPositionZ = {
					getTranslation(spec.easyArmControl.targetNodeZ)
				}
				spec.easyArmControl.xRotationMaxDistance = getXMLFloat(self.xmlFile, simpleKey .. ".xRotationNodes#maxDistance") or 0
				spec.easyArmControl.xRotationNodes = {}
				spec.easyArmControl.zTranslationNodes = {}
				i = 0
				local maxTrans = 0

				while true do
					local transKey = string.format("%s.zTranslationNodes.zTranslationNode(%d)", simpleKey, i)

					if not hasXMLProperty(self.xmlFile, transKey) then
						break
					end

					local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, transKey .. "#node"), self.i3dMappings)

					if node ~= nil then
						local movingTool = self:getMovingToolByNode(node)

						if movingTool ~= nil then
							local maxDistance = math.abs(movingTool.transMin - movingTool.transMax)
							maxTrans = maxTrans + maxDistance
							movingTool.easyArmControlActive = false

							table.insert(spec.easyArmControl.zTranslationNodes, {
								transFactor = 0,
								node = node,
								movingTool = movingTool,
								maxDistance = maxDistance
							})
						end
					end

					i = i + 1
				end

				for _, translationNode in ipairs(spec.easyArmControl.zTranslationNodes) do
					translationNode.transFactor = translationNode.maxDistance / maxTrans
				end

				for i = 1, 2 do
					local xRotKey = string.format("%s.xRotationNodes.xRotationNode%d", simpleKey, i)

					if not hasXMLProperty(self.xmlFile, xRotKey) then
						g_logManager:xmlWarning(self.configFileName, "Missing second xRotation node for easy control!")

						spec.easyArmControl = nil

						break
					end

					local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, xRotKey .. "#node"), self.i3dMappings)
					local refNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, xRotKey .. "#refNode"), self.i3dMappings)

					if node ~= nil and refNode ~= nil then
						local movingTool = self:getMovingToolByNode(node)

						if movingTool ~= nil then
							movingTool.easyArmControlActive = false

							table.insert(spec.easyArmControl.xRotationNodes, {
								node = node,
								refNode = refNode,
								movingTool = movingTool
							})
						end
					end
				end
			else
				g_logManager:xmlError(self.configFileName, "Missing moving tools for easy control targets!")

				spec.easyArmControl = nil
			end
		else
			g_logManager:xmlError(self.configFileName, "Missing easy control targets!")

			spec.easyArmControl = nil
		end
	end

	if self.loadDashboardsFromXML ~= nil then
		local dashboardData = {
			maxFunc = 1,
			minFunc = 0,
			valueTypeToLoad = "movingTool",
			idleValue = 0.5,
			valueObject = self,
			valueFunc = Cylindered.getMovingToolDashboardState,
			additionalAttributesFunc = Cylindered.movingToolDashboardAttributes
		}

		self:loadDashboardsFromXML(self.xmlFile, "vehicle.cylindered.dashboards", dashboardData)
	end

	if self.isClient and g_isDevelopmentVersion and (#spec.movingParts > 0 or #spec.movingTools > 0) and spec.samples.hydraulic == nil then
		g_logManager:xmlDevWarning(self.configFileName, "Missing cylindered hydraulic sound")
	end

	spec.cylinderedDirtyFlag = self:getNextDirtyFlag()
	spec.cylinderedInputDirtyFlag = self:getNextDirtyFlag()
	spec.isLoading = true
end

function Cylindered:onPostLoad(savegame)
	local spec = self.spec_cylindered

	for _, tool in pairs(spec.movingTools) do
		if self:getIsMovingToolActive(tool) then
			if tool.startRot ~= nil then
				tool.curRot[tool.rotationAxis] = tool.startRot

				setRotation(tool.node, unpack(tool.curRot))
			end

			if tool.startTrans ~= nil then
				tool.curTrans[tool.translationAxis] = tool.startTrans

				setTranslation(tool.node, unpack(tool.curTrans))
			end

			if tool.delayedNode ~= nil then
				self:setDelayedData(tool, true)
			end

			if tool.isIntitialDirty then
				Cylindered.setDirty(self, tool)
			end
		end
	end

	for _, part in pairs(spec.movingParts) do
		self:loadDependentAttacherJoints(self.xmlFile, part.key, part)
		self:loadDependentWheels(self.xmlFile, part.key, part)
	end

	for _, tool in pairs(spec.movingTools) do
		self:loadDependentAttacherJoints(self.xmlFile, tool.key, tool)
		self:loadDependentWheels(self.xmlFile, tool.key, tool)
	end

	if self:allowLoadMovingToolStates() and savegame ~= nil and not savegame.resetVehicles then
		local i = 0

		for _, tool in ipairs(spec.movingTools) do
			if tool.saving then
				if self:getIsMovingToolActive(tool) then
					local toolKey = string.format("%s.cylindered.movingTool(%d)", savegame.key, i)
					local changed = false

					if tool.transSpeed ~= nil then
						local newTrans = getXMLFloat(savegame.xmlFile, toolKey .. "#translation")

						if newTrans ~= nil then
							if tool.transMax ~= nil then
								newTrans = math.min(newTrans, tool.transMax)
							end

							if tool.transMin ~= nil then
								newTrans = math.max(newTrans, tool.transMin)
							end
						end

						if newTrans ~= nil and math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
							tool.curTrans = {
								[tool.translationAxis] = newTrans,
								getTranslation(tool.node)
							}

							setTranslation(tool.node, unpack(tool.curTrans))

							changed = true
						end
					end

					if tool.rotSpeed ~= nil then
						local newRot = getXMLFloat(savegame.xmlFile, toolKey .. "#rotation")

						if newRot ~= nil then
							if tool.rotMax ~= nil then
								newRot = math.min(newRot, tool.rotMax)
							end

							if tool.rotMin ~= nil then
								newRot = math.max(newRot, tool.rotMin)
							end
						end

						if newRot ~= nil and math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
							tool.curRot = {
								[tool.rotationAxis] = newRot,
								getRotation(tool.node)
							}

							setRotation(tool.node, unpack(tool.curRot))

							changed = true
						end
					end

					if tool.animSpeed ~= nil then
						local animTime = getXMLFloat(savegame.xmlFile, toolKey .. "#animationTime")

						if animTime ~= nil then
							if tool.animMinTime ~= nil then
								animTime = math.max(animTime, tool.animMinTime)
							end

							if tool.animMaxTime ~= nil then
								animTime = math.min(animTime, tool.animMaxTime)
							end

							tool.curAnimTime = animTime

							self:setAnimationTime(tool.animName, animTime, true)
						end
					end

					if changed then
						Cylindered.setDirty(self, tool)
					end

					if tool.delayedNode ~= nil then
						self:setDelayedData(tool, true)
					end
				end

				i = i + 1
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
			end
		end
	end

	self:updateEasyControl(9999, true)
	self:updateCylinderedInitial(false)

	spec.isActiveDirtyTime = g_currentMission.time + math.max(spec.isActiveDirtyTimeOffset, 1000)
end

function Cylindered:onLoadFinished(savegame)
	local spec = self.spec_cylindered
	spec.isLoading = false

	for i = 1, table.getn(spec.movingTools) do
		local tool = spec.movingTools[i]

		if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
			self:updateDelayedTool(tool, true)
		end
	end
end

function Cylindered:onDelete()
	local spec = self.spec_cylindered

	if self.isClient then
		g_soundManager:deleteSamples(spec.samples)
	end

	for _, movingTool in pairs(spec.movingTools) do
		if movingTool.icon ~= nil then
			movingTool.icon:delete()

			movingTool.icon = nil
		end
	end
end

function Cylindered:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_cylindered
	local index = 0

	for _, tool in ipairs(spec.movingTools) do
		if tool.saving then
			local toolKey = string.format("%s.movingTool(%d)", key, index)

			if tool.transSpeed ~= nil then
				setXMLFloat(xmlFile, toolKey .. "#translation", tool.curTrans[tool.translationAxis])
			end

			if tool.rotSpeed ~= nil then
				setXMLFloat(xmlFile, toolKey .. "#rotation", tool.curRot[tool.rotationAxis])
			end

			if tool.animSpeed ~= nil then
				setXMLFloat(xmlFile, toolKey .. "#animationTime", tool.curAnimTime)
			end

			index = index + 1
		end
	end
end

function Cylindered:onReadStream(streamId, connection)
	local spec = self.spec_cylindered

	if self:allowLoadMovingToolStates() and connection:getIsServer() then
		for i = 1, table.getn(spec.movingTools) do
			local tool = spec.movingTools[i]

			if tool.dirtyFlag ~= nil then
				tool.networkTimeInterpolator:reset()

				if tool.transSpeed ~= nil then
					local newTrans = streamReadFloat32(streamId)
					tool.curTrans[tool.translationAxis] = newTrans

					setTranslation(tool.node, unpack(tool.curTrans))
					tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					local newRot = streamReadFloat32(streamId)
					tool.curRot[tool.rotationAxis] = newRot

					setRotation(tool.node, unpack(tool.curRot))
					tool.networkInterpolators.rotation:setAngle(newRot)
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = streamReadFloat32(streamId)
					tool.curAnimTime = newAnimTime

					self:setAnimationTime(tool.animName, tool.curAnimTime)
					tool.networkInterpolators.animation:setValue(newAnimTime)
				end

				if tool.delayedNode ~= nil then
					self:setDelayedData(tool, true)
				end

				Cylindered.setDirty(self, tool)
			end
		end
	end
end

function Cylindered:onWriteStream(streamId, connection)
	local spec = self.spec_cylindered

	if self:allowLoadMovingToolStates() and not connection:getIsServer() then
		for i = 1, table.getn(spec.movingTools) do
			local tool = spec.movingTools[i]

			if tool.dirtyFlag ~= nil then
				if tool.transSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curRot[tool.rotationAxis])
				end

				if tool.animSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curAnimTime)
				end
			end
		end
	end
end

function Cylindered:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_cylindered

	if not connection:getIsServer() then
		if streamReadBool(streamId) then
			for _, tool in ipairs(spec.movingTools) do
				if tool.axisActionIndex ~= nil then
					tool.move = (streamReadUIntN(streamId, 12) / 4095 * 2 - 1) * 5

					if math.abs(tool.move) < 0.01 then
						tool.move = 0
					end
				end
			end
		end
	elseif streamReadBool(streamId) then
		for _, tool in ipairs(spec.movingTools) do
			if tool.dirtyFlag ~= nil and streamReadBool(streamId) then
				tool.networkTimeInterpolator:startNewPhaseNetwork()

				if tool.transSpeed ~= nil then
					local newTrans = streamReadFloat32(streamId)

					if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
						tool.networkInterpolators.translation:setTargetValue(newTrans)
					end
				end

				if tool.rotSpeed ~= nil then
					local newRot = nil

					if tool.rotMin == nil or tool.rotMax == nil then
						newRot = NetworkUtil.readCompressedAngle(streamId)
					else
						if tool.syncMinRotLimits then
							tool.rotMin = streamReadFloat32(streamId)
						end

						if tool.syncMaxRotLimits then
							tool.rotMax = streamReadFloat32(streamId)
						end

						tool.networkInterpolators.rotation:setMinMax(tool.rotMin, tool.rotMax)

						newRot = NetworkUtil.readCompressedRange(streamId, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
					end

					if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
						tool.networkInterpolators.rotation:setTargetAngle(newRot)
					end
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = NetworkUtil.readCompressedRange(streamId, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)

					if math.abs(newAnimTime - tool.curAnimTime) > 0.0001 then
						tool.networkInterpolators.animation:setTargetValue(newAnimTime)
					end
				end
			end
		end
	end
end

function Cylindered:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_cylindered

	if connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.cylinderedInputDirtyFlag) ~= 0) then
			for _, tool in ipairs(spec.movingTools) do
				if tool.axisActionIndex ~= nil then
					local value = (MathUtil.clamp(tool.moveToSend / 5, -1, 1) + 1) / 2 * 4095

					streamWriteUIntN(streamId, value, 12)
				end
			end
		end
	elseif streamWriteBool(streamId, bitAND(dirtyMask, spec.cylinderedDirtyFlag) ~= 0) then
		for _, tool in ipairs(spec.movingTools) do
			if tool.dirtyFlag ~= nil and streamWriteBool(streamId, bitAND(dirtyMask, tool.dirtyFlag) ~= 0 and self:getIsMovingToolActive(tool)) then
				if tool.transSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					local rot = tool.curRot[tool.rotationAxis]

					if tool.rotMin == nil or tool.rotMax == nil then
						NetworkUtil.writeCompressedAngle(streamId, rot)
					else
						if tool.syncMinRotLimits then
							streamWriteFloat32(streamId, tool.rotMin)
						end

						if tool.syncMaxRotLimits then
							streamWriteFloat32(streamId, tool.rotMax)
						end

						NetworkUtil.writeCompressedRange(streamId, rot, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
					end
				end

				if tool.animSpeed ~= nil then
					NetworkUtil.writeCompressedRange(streamId, tool.curAnimTime, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)
				end
			end
		end
	end
end

function Cylindered:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered
	spec.movingToolNeedsSound = false
	spec.movingPartNeedsSound = false

	self:updateEasyControl(dt)

	if self.isServer then
		for i = 1, table.getn(spec.movingTools) do
			local tool = spec.movingTools[i]
			local rotSpeed = 0
			local transSpeed = 0
			local animSpeed = 0
			local move = tool.move + tool.externalMove

			if math.abs(move) > 0 then
				tool.externalMove = 0

				if tool.rotSpeed ~= nil then
					rotSpeed = move * tool.rotSpeed

					if tool.rotAcceleration ~= nil and math.abs(rotSpeed - tool.lastRotSpeed) >= tool.rotAcceleration * dt then
						if tool.lastRotSpeed < rotSpeed then
							rotSpeed = tool.lastRotSpeed + tool.rotAcceleration * dt
						else
							rotSpeed = tool.lastRotSpeed - tool.rotAcceleration * dt
						end
					end
				end

				if tool.transSpeed ~= nil then
					transSpeed = move * tool.transSpeed

					if tool.transAcceleration ~= nil and math.abs(transSpeed - tool.lastTransSpeed) >= tool.transAcceleration * dt then
						if tool.lastTransSpeed < transSpeed then
							transSpeed = tool.lastTransSpeed + tool.transAcceleration * dt
						else
							transSpeed = tool.lastTransSpeed - tool.transAcceleration * dt
						end
					end
				end

				if tool.animSpeed ~= nil then
					animSpeed = move * tool.animSpeed

					if tool.animAcceleration ~= nil and math.abs(animSpeed - tool.lastAnimSpeed) >= tool.animAcceleration * dt then
						if tool.lastAnimSpeed < animSpeed then
							animSpeed = tool.lastAnimSpeed + tool.animAcceleration * dt
						else
							animSpeed = tool.lastAnimSpeed - tool.animAcceleration * dt
						end
					end
				end
			else
				if tool.rotAcceleration ~= nil then
					if tool.lastRotSpeed < 0 then
						rotSpeed = math.min(tool.lastRotSpeed + tool.rotAcceleration * dt, 0)
					else
						rotSpeed = math.max(tool.lastRotSpeed - tool.rotAcceleration * dt, 0)
					end
				end

				if tool.transAcceleration ~= nil then
					if tool.lastTransSpeed < 0 then
						transSpeed = math.min(tool.lastTransSpeed + tool.transAcceleration * dt, 0)
					else
						transSpeed = math.max(tool.lastTransSpeed - tool.transAcceleration * dt, 0)
					end
				end

				if tool.animAcceleration ~= nil then
					if tool.lastAnimSpeed < 0 then
						animSpeed = math.min(tool.lastAnimSpeed + tool.animAcceleration * dt, 0)
					else
						animSpeed = math.max(tool.lastAnimSpeed - tool.animAcceleration * dt, 0)
					end
				end
			end

			local changed = false

			if rotSpeed ~= nil and rotSpeed ~= 0 then
				changed = changed or Cylindered.setToolRotation(self, tool, rotSpeed, dt)
			else
				tool.lastRotSpeed = 0
			end

			if transSpeed ~= nil and transSpeed ~= 0 then
				changed = changed or Cylindered.setToolTranslation(self, tool, transSpeed, dt)
			else
				tool.lastTransSpeed = 0
			end

			if animSpeed ~= nil and animSpeed ~= 0 then
				changed = changed or Cylindered.setToolAnimation(self, tool, animSpeed, dt)
			else
				tool.lastAnimSpeed = 0
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				if dependentTool.speedScale ~= nil then
					local isAllowed = true

					if dependentTool.requiresMovement and not changed then
						isAllowed = false
					end

					if isAllowed then
						dependentTool.movingTool.externalMove = dependentTool.speedScale * tool.move
					end
				end

				Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
				self:updateDependentToolLimits(tool, dependentTool)
			end

			if changed then
				if tool.playSound then
					spec.movingToolNeedsSound = true
				end

				Cylindered.setDirty(self, tool)

				tool.networkPositionIsDirty = true

				self:raiseDirtyFlags(tool.dirtyFlag)
				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)

				tool.networkDirtyNextFrame = true
			elseif tool.networkDirtyNextFrame then
				self:raiseDirtyFlags(tool.dirtyFlag)
				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)

				tool.networkDirtyNextFrame = nil
			end
		end
	else
		for i = 1, table.getn(spec.movingTools) do
			local tool = spec.movingTools[i]

			tool.networkTimeInterpolator:update(dt)

			local interpolationAlpha = tool.networkTimeInterpolator:getAlpha()
			local changed = false

			if self:getIsMovingToolActive(tool) then
				if tool.rotSpeed ~= nil then
					local newRot = tool.networkInterpolators.rotation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
						changed = true
						tool.curRot[tool.rotationAxis] = newRot

						setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
					end
				end

				if tool.transSpeed ~= nil then
					local newTrans = tool.networkInterpolators.translation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
						changed = true
						tool.curTrans[tool.translationAxis] = newTrans

						setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
					end
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = tool.networkInterpolators.animation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newAnimTime - tool.curAnimTime) > 0.0001 then
						changed = true
						tool.curAnimTime = newAnimTime

						self:setAnimationTime(tool.animName, newAnimTime)
					end
				end

				if changed then
					Cylindered.setDirty(self, tool)
				end
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				if not dependentTool.movingTool.syncMinRotLimits or not dependentTool.movingTool.syncMaxRotLimits then
					self:updateDependentToolLimits(tool, dependentTool)
				end
			end

			if tool.networkTimeInterpolator:isInterpolating() then
				self:raiseActive()
			end
		end
	end

	for i = 1, table.getn(spec.movingTools) do
		local tool = spec.movingTools[i]

		if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
			self:updateDelayedTool(tool)
		end
	end
end

function Cylindered:setDelayedData(tool, immediate)
	local x, y, z = getTranslation(tool.node)
	local rx, ry, rz = getRotation(tool.node)
	tool.delayedHistroyData[3] = {
		rot = {
			rx,
			ry,
			rz
		},
		trans = {
			x,
			y,
			z
		}
	}

	if immediate then
		tool.delayedHistroyData[2] = tool.delayedHistroyData[3]
		tool.delayedHistroyData[1] = tool.delayedHistroyData[2]
	end

	tool.delayedHistoryIndex = 3
end

function Cylindered:updateDelayedTool(tool, forceLastPosition)
	local spec = self.spec_cylindered

	if forceLastPosition ~= nil and forceLastPosition then
		tool.delayedHistroyData[2] = tool.delayedHistroyData[3]
		tool.delayedHistroyData[1] = tool.delayedHistroyData[2]
	end

	local currentData = tool.delayedHistroyData[1]
	tool.delayedHistroyData[1] = tool.delayedHistroyData[2]
	tool.delayedHistroyData[2] = tool.delayedHistroyData[3]

	setRotation(tool.delayedNode, unpack(currentData.rot))
	setTranslation(tool.delayedNode, unpack(currentData.trans))

	tool.delayedHistoryIndex = tool.delayedHistoryIndex - 1
	local movingPart = spec.nodesToMovingParts[tool.delayedNode]
	local movingTool = spec.nodesToMovingTools[tool.delayedNode]

	if movingPart ~= nil then
		Cylindered.setDirty(self, movingPart)
	end

	if spec.nodesToMovingTools[tool.delayedNode] ~= nil then
		Cylindered.setDirty(self, movingTool)
	end
end

function Cylindered:updateEasyControl(dt, updateDelayedNodes)
	local spec = self.spec_cylindered
	local easyArmControl = spec.easyArmControl

	if easyArmControl ~= nil then
		local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
		local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)
		local easyArmControlState = g_gameSettings:getValue("easyArmControl")
		local easyArmControlsActive = true
		easyArmControlsActive = easyArmControlsActive and self:getIsMovingToolActive(targetYTool)
		easyArmControlsActive = easyArmControlsActive and self:getIsMovingToolActive(targetZTool)
		local hasChanged = false

		if self.isClient and (spec.lastEasyArmControlState ~= easyArmControlState or spec.lastEasyArmControlsActive ~= easyArmControlsActive) then
			spec.lastEasyArmControlState = easyArmControlState
			spec.lastEasyArmControlsActive = easyArmControlsActive

			self:requestActionEventUpdate()

			local isActive = easyArmControlState and easyArmControlsActive

			self:setIsEasyControlActive(isActive)

			hasChanged = isActive
		end

		local tYx, tYy, tYz = getTranslation(easyArmControl.targetNodeY)
		local tZx, tZy, tZz = getTranslation(easyArmControl.targetNodeZ)

		if tYx + tYy + tYz ~= easyArmControl.oldTargetNodeYTrans or tZx + tZy + tZz ~= easyArmControl.oldTargetNodeZTrans then
			hasChanged = true
		end

		if self.isServer and easyArmControlState and hasChanged and easyArmControlsActive then
			easyArmControl.oldTargetNodeYTrans = tYx + tYy + tYz
			easyArmControl.oldTargetNodeZTrans = tZx + tZy + tZz
			local xRotNode1 = easyArmControl.xRotationNodes[1].refNode
			local xRotNode2 = easyArmControl.xRotationNodes[2].refNode
			local x, y, z = localToLocal(easyArmControl.targetNode, getParent(xRotNode1), 0, 0, 0)
			local distance = MathUtil.vector3Length(x, y, z)
			local transDelta = distance - easyArmControl.xRotationMaxDistance

			for i, translationNode in ipairs(easyArmControl.zTranslationNodes) do
				local tool = translationNode.movingTool
				local targetTrans = MathUtil.clamp(transDelta * translationNode.transFactor, tool.transMin, tool.transMax)
				local _, _, z = getTranslation(translationNode.node)
				local deltaTrans = targetTrans - z

				if Cylindered.setToolTranslation(self, tool, nil, 0, deltaTrans) then
					Cylindered.setDirty(self, tool)
					self:raiseDirtyFlags(tool.dirtyFlag)
					self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
				end
			end

			local _, _, node1Length = localToLocal(xRotNode2, xRotNode1, 0, 0, 0)
			local _, b, c = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
			local node2Length = MathUtil.vector2Length(b, c)
			local _, ly, lz = localToLocal(easyArmControl.targetNode, getParent(xRotNode1), 0, 0, 0)
			local _, _, iy, iz = MathUtil.getCircleCircleIntersection(0, 0, node1Length, ly, lz, node2Length)
			local isOutOfRange = true

			if iy ~= nil and iz ~= nil then
				local node1Rotation = -math.atan2(iy, iz)
				local node1Tool = easyArmControl.xRotationNodes[1].movingTool

				if node1Tool.rotMin <= node1Rotation and node1Rotation <= node1Tool.rotMax then
					local node2Rotation = math.pi - math.acos((node1Length * node1Length + node2Length * node2Length - distance * distance) / (2 * node1Length * node2Length))
					local node2Tool = easyArmControl.xRotationNodes[2].movingTool

					if node2Tool.rotMin <= node2Rotation and node2Rotation <= node2Tool.rotMax then
						setRotation(xRotNode1, node1Rotation, 0, 0)
						setRotation(xRotNode2, node2Rotation, 0, 0)

						for i = 1, 2 do
							local rotationNode = easyArmControl.xRotationNodes[i]
							local rx, _, _ = getRotation(rotationNode.refNode)
							local x, _, _ = getRotation(rotationNode.node)

							if Cylindered.setToolRotation(self, rotationNode.movingTool, nil, 0, rx - x) then
								Cylindered.setDirty(self, rotationNode.movingTool)

								if updateDelayedNodes ~= nil and updateDelayedNodes then
									self:updateDelayedTool(rotationNode.movingTool)
								end

								self:raiseDirtyFlags(rotationNode.movingTool.dirtyFlag)
								self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
							end
						end

						x, y, z = getTranslation(easyArmControl.targetNodeY)
						easyArmControl.lastValidPositionY[1] = x
						easyArmControl.lastValidPositionY[2] = y
						easyArmControl.lastValidPositionY[3] = z
						x, y, z = getTranslation(easyArmControl.targetNodeZ)
						easyArmControl.lastValidPositionZ[1] = x
						easyArmControl.lastValidPositionZ[2] = y
						easyArmControl.lastValidPositionZ[3] = z
						isOutOfRange = false
					end
				end
			end

			if isOutOfRange then
				setTranslation(easyArmControl.targetNodeY, unpack(easyArmControl.lastValidPositionY))
				setTranslation(easyArmControl.targetNodeZ, unpack(easyArmControl.lastValidPositionZ))
			end
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
			local xRotNode1 = easyArmControl.xRotationNodes[1].refNode
			local xRotNode2 = easyArmControl.xRotationNodes[2].refNode
			local _, _, node1Length = localToLocal(xRotNode2, xRotNode1, 0, 0, 0)
			local _, b, c = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
			local node2Length = MathUtil.vector2Length(b, c)
			local x1, y1, z1 = localToWorld(xRotNode1, 0, 0, 0)
			local x2, y2, z2 = localToWorld(xRotNode1, 0, 0, node1Length)

			drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0)

			x1, y1, z1 = localToWorld(xRotNode2, 0, 0, 0)
			x2, y2, z2 = localToWorld(xRotNode2, 0, 0, node2Length)

			drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 1, 0, 0)
			DebugUtil.drawDebugNode(easyArmControl.targetNode, "scTarget")
			DebugUtil.drawDebugNode(easyArmControl.targetRefNode, "scTargetRef")
		end
	end
end

function Cylindered:setIsEasyControlActive(state, noEventSend)
	if self.isServer then
		local spec = self.spec_cylindered
		local easyArmControl = spec.easyArmControl

		if easyArmControl ~= nil then
			local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
			local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)

			if state then
				local _, y, z = localToLocal(easyArmControl.targetRefNode, getParent(easyArmControl.targetNodeY), 0, 0, 0)
				local _, oldY, _ = getTranslation(easyArmControl.targetNodeY)

				if Cylindered.setToolTranslation(self, targetYTool, nil, 0, y - oldY) then
					Cylindered.setDirty(self, targetYTool)
					self:raiseDirtyFlags(targetYTool.dirtyFlag)
				end

				_, _, z = localToLocal(easyArmControl.targetRefNode, getParent(easyArmControl.targetNodeZ), 0, 0, 0)
				local _, _, oldZ = getTranslation(easyArmControl.targetNodeZ)

				if Cylindered.setToolTranslation(self, targetZTool, nil, 0, z - oldZ) then
					Cylindered.setDirty(self, targetZTool)
					self:raiseDirtyFlags(targetZTool.dirtyFlag)
				end

				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
			end
		end
	end

	CylinderedEasyControlChangeEvent.sendEvent(self, state, noEventSend)
end

function Cylindered:updateExtraDependentParts(part, dt)
end

function Cylindered:updateDependentAnimations(part, dt)
	if #part.dependentAnimations > 0 then
		for _, dependentAnimation in ipairs(part.dependentAnimations) do
			local pos = 0

			if dependentAnimation.translationAxis ~= nil then
				local retValues = {
					getTranslation(dependentAnimation.node)
				}
				pos = (retValues[dependentAnimation.translationAxis] - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
			end

			if dependentAnimation.rotationAxis ~= nil then
				local retValues = {
					getRotation(dependentAnimation.node)
				}
				pos = (retValues[dependentAnimation.rotationAxis] - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
			end

			pos = MathUtil.clamp(math.abs(pos), 0, 1)

			if dependentAnimation.invert then
				pos = 1 - pos
			end

			dependentAnimation.lastPos = pos

			self:setAnimationTime(dependentAnimation.name, pos, true)
		end
	end
end

function Cylindered:updateDependentToolLimits(tool, dependentTool)
	if dependentTool.minTransLimits ~= nil or dependentTool.maxTransLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.minTransLimits ~= nil then
			dependentTool.movingTool.transMin = MathUtil.lerp(dependentTool.minTransLimits[1], dependentTool.minTransLimits[2], 1 - state)
		end

		if dependentTool.maxTransLimits ~= nil then
			dependentTool.movingTool.transMax = MathUtil.lerp(dependentTool.maxTransLimits[1], dependentTool.maxTransLimits[2], 1 - state)
		end

		local transLimitChanged = Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)

		if transLimitChanged then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end

	if dependentTool.minRotLimits ~= nil or dependentTool.maxRotLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.minRotLimits ~= nil then
			dependentTool.movingTool.rotMin = MathUtil.lerp(dependentTool.minRotLimits[1], dependentTool.minRotLimits[2], 1 - state)
		end

		if dependentTool.maxRotLimits ~= nil then
			dependentTool.movingTool.rotMax = MathUtil.lerp(dependentTool.maxRotLimits[1], dependentTool.maxRotLimits[2], 1 - state)
		end

		dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)

		local rotLimitChanged = Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)

		if rotLimitChanged then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end
end

function Cylindered:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_cylindered

		for _, movingTool in pairs(spec.movingTools) do
			if movingTool.axisActionIndex ~= nil and spec.currentControlGroupIndex == movingTool.controlGroupIndex then
				local actionEvent = spec.actionEvents[movingTool.axisActionIndex]

				if actionEvent ~= nil then
					g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsMovingToolActive(movingTool))
				end
			end
		end
	end
end

function Cylindered:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered
	spec.isActiveDirtyTime = g_currentMission.time + spec.isActiveDirtyTimeOffset

	if g_currentMission.time <= spec.isActiveDirtyTime then
		for _, part in pairs(spec.activeDirtyMovingParts) do
			Cylindered.setDirty(self, part)
		end
	end

	for _, tool in pairs(spec.movingTools) do
		if tool.isDirty then
			if tool.playSound then
				spec.movingToolNeedsSound = true
			end

			if self.isServer then
				Cylindered.updateComponentJoints(self, tool, false)
			end

			self:updateExtraDependentParts(tool, dt)
			self:updateDependentAnimations(tool, dt)

			tool.isDirty = false
		end
	end

	if self.anyMovingPartsDirty then
		for i, part in ipairs(spec.movingParts) do
			if part.isDirty then
				Cylindered.updateMovingPart(self, part, false)
				self:updateExtraDependentParts(part, dt)
				self:updateDependentAnimations(part, dt)

				if part.playSound then
					spec.cylinderedHydraulicSoundPartNumber = i
					spec.movingPartNeedsSound = true
				end
			elseif spec.isClient and spec.cylinderedHydraulicSoundPartNumber == i then
				spec.movingPartNeedsSound = false
			end
		end

		self.anyMovingPartsDirty = false
	end

	if self.isClient then
		if spec.movingToolNeedsSound or spec.movingPartNeedsSound then
			if not spec.isHydraulicSamplePlaying then
				g_soundManager:playSample(spec.samples.hydraulic)

				spec.isHydraulicSamplePlaying = true
			end

			self:raiseActive()
		elseif spec.isHydraulicSamplePlaying then
			g_soundManager:stopSample(spec.samples.hydraulic)

			spec.isHydraulicSamplePlaying = false
		end
	end
end

function Cylindered:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered

	if #spec.controlGroupNames > 1 and isActiveForInputIgnoreSelection then
		g_currentMission:addExtraPrintText(string.format(g_i18n:getText("action_selectedControlGroup"), spec.controlGroupNames[spec.currentControlGroupIndex], spec.currentControlGroupIndex))
	end
end

function Cylindered:loadMovingPartFromXML(xmlFile, key, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
	local referenceFrame = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#referenceFrame"), self.i3dMappings)

	if node ~= nil and referenceFrame ~= nil then
		entry.referencePoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#referencePoint"), self.i3dMappings)
		entry.node = node
		entry.referenceFrame = referenceFrame
		entry.invertZ = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#invertZ"), false)
		entry.scaleZ = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#scaleZ"), false)
		entry.limitedAxis = getXMLInt(self.xmlFile, key .. "#limitedAxis")
		entry.isActiveDirty = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#isActiveDirty"), false)
		entry.playSound = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#playSound"), false)
		entry.moveToReferenceFrame = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#moveToReferenceFrame"), false)

		if entry.moveToReferenceFrame then
			local x, y, z = worldToLocal(referenceFrame, getWorldTranslation(node))
			entry.referenceFrameOffset = {
				x,
				y,
				z
			}
		end

		entry.doLineAlignment = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#doLineAlignment"), false)
		entry.partLength = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. ".orientationLine#partLength"), 0.5)
		entry.orientationLineNodes = {}
		local i = 0

		while true do
			local pointKey = string.format("%s.orientationLine.lineNode(%d)", key, i)

			if not hasXMLProperty(xmlFile, pointKey) then
				break
			end

			local lineNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, pointKey .. "#node"), self.i3dMappings)

			table.insert(entry.orientationLineNodes, lineNode)

			i = i + 1
		end

		entry.doDirectionAlignment = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#doDirectionAlignment"), true)
		entry.doRotationAlignment = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#doRotationAlignment"), false)
		entry.rotMultiplier = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#rotMultiplier"), 0)
		local minRot = getXMLFloat(self.xmlFile, key .. "#minRot")
		local maxRot = getXMLFloat(self.xmlFile, key .. "#maxRot")

		if minRot ~= nil and maxRot ~= nil then
			if entry.limitedAxis ~= nil then
				entry.minRot = MathUtil.getValidLimit(math.rad(minRot))
				entry.maxRot = MathUtil.getValidLimit(math.rad(maxRot))
			else
				print("Warning: minRot/maxRot requires the use of limitedAxis in '" .. self.configFileName .. "'")
			end
		end

		entry.alignToWorldY = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#alignToWorldY"), false)

		if entry.referencePoint ~= nil then
			local localReferencePoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#localReferencePoint"), self.i3dMappings)
			local refX, refY, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))

			if localReferencePoint ~= nil then
				local x, y, z = worldToLocal(node, getWorldTranslation(localReferencePoint))
				entry.referenceDistance = MathUtil.vector3Length(refX - x, refY - y, refZ - z)
				entry.lastReferenceDistance = entry.referenceDistance
				entry.localReferencePoint = {
					x,
					y,
					z
				}
				local side = y * (refZ - z) - z * (refY - y)
				entry.localReferenceAngleSide = side
				entry.localReferencePointNode = localReferencePoint
				entry.updateLocalReferenceDistance = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#updateLocalReferenceDistance"), false)
				entry.localReferenceTranslate = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#localReferenceTranslate"), false)

				if entry.localReferenceTranslate then
					entry.localReferenceTranslation = {
						getTranslation(entry.node)
					}
				end
			else
				entry.referenceDistance = 0
				entry.localReferencePoint = {
					refX,
					refY,
					refZ
				}
			end

			entry.referenceDistanceThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#referenceDistanceThreshold"), 0)
			entry.useLocalOffset = Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#useLocalOffset"), false)
			entry.localReferenceDistance = MathUtil.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3])

			self:loadDependentTranslatingParts(self.xmlFile, key, entry)
		end

		entry.directionThreshold = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#directionThreshold"), 0.0001)
		entry.lastDirection = {
			0,
			0,
			0
		}
		entry.lastUpVector = {
			0,
			0,
			0
		}
		entry.isDirty = false
		entry.isPart = true

		return true
	end

	return false
end

function Cylindered:loadMovingToolFromXML(xmlFile, key, entry)
	local spec = self.spec_cylindered

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node ~= nil then
		entry.node = node
		entry.externalMove = 0
		entry.easyArmControlActive = true
		entry.isEasyControlTarget = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isEasyControlTarget"), false)
		entry.networkInterpolators = {}

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#rotSpeed", key .. ".rotation#rotSpeed")

		local rotSpeed = getXMLFloat(xmlFile, key .. ".rotation#rotSpeed")

		if rotSpeed ~= nil then
			entry.rotSpeed = math.rad(rotSpeed) / 1000
		end

		local rotAcceleration = getXMLFloat(xmlFile, key .. ".rotation#rotAcceleration")

		if rotAcceleration ~= nil then
			entry.rotAcceleration = math.rad(rotAcceleration) / 1000000
		end

		entry.lastRotSpeed = 0
		local rotMax = getXMLFloat(xmlFile, key .. ".rotation#rotMax")

		if rotMax ~= nil then
			entry.rotMax = math.rad(rotMax)
		end

		local rotMin = getXMLFloat(xmlFile, key .. ".rotation#rotMin")

		if rotMin ~= nil then
			entry.rotMin = math.rad(rotMin)
		end

		entry.syncMaxRotLimits = Utils.getNoNil(getXMLBool(xmlFile, key .. ".rotation#syncMaxRotLimits"), false)
		entry.syncMinRotLimits = Utils.getNoNil(getXMLBool(xmlFile, key .. ".rotation#syncMinRotLimits"), false)
		entry.rotSendNumBits = Utils.getNoNil(getXMLInt(xmlFile, key .. ".rotation#rotSendNumBits"), 8)
		local attachRotMax = getXMLFloat(xmlFile, key .. ".rotation#attachRotMax")

		if attachRotMax ~= nil then
			entry.attachRotMax = math.rad(attachRotMax)
		end

		local attachRotMin = getXMLFloat(xmlFile, key .. ".rotation#attachRotMin")

		if attachRotMin ~= nil then
			entry.attachRotMin = math.rad(attachRotMin)
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#transSpeed", key .. ".rotation#transSpeed")

		local transSpeed = getXMLFloat(xmlFile, key .. ".translation#transSpeed")

		if transSpeed ~= nil then
			entry.transSpeed = transSpeed / 1000
		end

		local transAcceleration = getXMLFloat(xmlFile, key .. ".translation#transAcceleration")

		if transAcceleration ~= nil then
			entry.transAcceleration = transAcceleration / 1000000
		end

		entry.lastTransSpeed = 0
		entry.transMax = getXMLFloat(xmlFile, key .. ".translation#transMax")
		entry.transMin = getXMLFloat(xmlFile, key .. ".translation#transMin")
		entry.attachTransMax = getXMLFloat(xmlFile, key .. ".translation#attachTransMax")
		entry.attachTransMin = getXMLFloat(xmlFile, key .. ".translation#attachTransMin")
		entry.playSound = Utils.getNoNil(getXMLBool(xmlFile, key .. "#playSound"), false)

		if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
			local animSpeed = getXMLFloat(xmlFile, key .. ".animation#animSpeed")

			if animSpeed ~= nil then
				entry.animSpeed = animSpeed / 1000
			end

			local animAcceleration = getXMLFloat(xmlFile, key .. ".animation#animAcceleration")

			if animAcceleration ~= nil then
				entry.animAcceleration = animAcceleration / 1000000
			end

			entry.curAnimTime = 0
			entry.lastAnimSpeed = 0
			entry.animName = getXMLString(xmlFile, key .. ".animation#animName")
			entry.animSendNumBits = Utils.getNoNil(getXMLInt(xmlFile, key .. ".animation#animSendNumBits"), 8)
			entry.animMaxTime = math.min(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".animation#animMaxTime"), 1), 1)
			entry.animMinTime = math.max(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".animation#animMinTime"), 0), 0)
			local animStartTime = getXMLFloat(xmlFile, key .. ".animation#animStartTime")

			if animStartTime ~= nil then
				entry.curAnimTime = animStartTime

				self:setAnimationTime(entry.animName, animStartTime)
			end

			entry.networkInterpolators.animation = InterpolatorValue:new(entry.curAnimTime)

			entry.networkInterpolators.animation:setMinMax(0, 1)
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. ".controls#iconFilename", key .. ".controls#iconName")

		local iconName = getXMLString(xmlFile, key .. ".controls#iconName")

		if iconName ~= nil then
			if InputHelpElement.AXIS_ICON[iconName] == nil then
				iconName = (self.customEnvironment or "") .. iconName
			end

			entry.axisActionIcon = iconName
		end

		entry.controlGroupIndex = getXMLInt(xmlFile, key .. ".controls#groupIndex") or 0

		if entry.controlGroupIndex ~= 0 then
			if spec.controlGroupNames[entry.controlGroupIndex] ~= nil then
				ListUtil.addElementToList(spec.controlGroups, entry.controlGroupIndex)
			else
				g_logManager:xmlWarning(self.configFileName, "ControlGroup '%d' not defined for '%s'!", entry.controlGroupIndex, key)
			end
		end

		entry.axis = getXMLString(xmlFile, key .. ".controls#axis")

		if entry.axis ~= nil then
			entry.axisActionIndex = InputAction[entry.axis]
		end

		entry.invertAxis = Utils.getNoNil(getXMLBool(xmlFile, key .. ".controls#invertAxis"), false)
		entry.mouseSpeedFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".controls#mouseSpeedFactor"), 1)

		if entry.rotSpeed ~= nil or entry.transSpeed ~= nil or entry.animSpeed ~= nil then
			entry.dirtyFlag = self:getNextDirtyFlag()
			entry.saving = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSaving"), true)
		end

		entry.isDirty = false
		entry.isIntitialDirty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isIntitialDirty"), true)
		entry.rotationAxis = Utils.getNoNil(getXMLInt(xmlFile, key .. ".rotation#rotationAxis"), 1)
		entry.translationAxis = Utils.getNoNil(getXMLInt(xmlFile, key .. ".translation#translationAxis"), 3)
		local detachingRotMaxLimit = getXMLFloat(xmlFile, key .. ".rotation#detachingRotMaxLimit")
		local detachingRotMinLimit = getXMLFloat(xmlFile, key .. ".rotation#detachingRotMinLimit")
		local detachingTransMaxLimit = getXMLFloat(xmlFile, key .. ".translation#detachingTransMaxLimit")
		local detachingTransMinLimit = getXMLFloat(xmlFile, key .. ".translation#detachingTransMinLimit")

		if detachingRotMaxLimit ~= nil or detachingRotMinLimit ~= nil or detachingTransMaxLimit ~= nil or detachingTransMinLimit ~= nil then
			if spec.detachLockNodes == nil then
				spec.detachLockNodes = {}
			end

			local detachLock = {}

			if detachingRotMaxLimit ~= nil then
				detachLock.detachingRotMaxLimit = math.rad(detachingRotMaxLimit)
			end

			if detachingRotMinLimit ~= nil then
				detachLock.detachingRotMinLimit = math.rad(detachingRotMinLimit)
			end

			detachLock.detachingTransMinLimit = detachingTransMinLimit
			detachLock.detachingTransMaxLimit = detachingTransMaxLimit
			spec.detachLockNodes[entry] = detachLock
		end

		local rx, ry, rz = getRotation(node)
		entry.curRot = {
			rx,
			ry,
			rz
		}
		local x, y, z = getTranslation(node)
		entry.curTrans = {
			x,
			y,
			z
		}
		entry.startRot = getXMLFloat(xmlFile, key .. ".rotation#startRot")

		if entry.startRot ~= nil then
			entry.startRot = math.rad(entry.startRot)
		end

		entry.startTrans = getXMLFloat(xmlFile, key .. ".translation#startTrans")
		entry.move = 0
		entry.moveToSend = 0

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#delayedIndex", key .. "#delayedNode")

		entry.delayedNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#delayedNode"), self.i3dMappings)

		if entry.delayedNode ~= nil then
			entry.currentDelayedData = {
				rot = {
					rx,
					ry,
					rz
				},
				trans = {
					x,
					y,
					z
				}
			}
			entry.delayedHistroyData = {
				{
					rot = {
						rx,
						ry,
						rz
					},
					trans = {
						x,
						y,
						z
					}
				},
				{
					rot = {
						rx,
						ry,
						rz
					},
					trans = {
						x,
						y,
						z
					}
				},
				{
					rot = {
						rx,
						ry,
						rz
					},
					trans = {
						x,
						y,
						z
					}
				}
			}
			entry.delayedHistoryIndex = 0
		end

		entry.networkInterpolators.translation = InterpolatorValue:new(entry.curTrans[entry.translationAxis])

		entry.networkInterpolators.translation:setMinMax(entry.transMin, entry.transMax)

		entry.networkInterpolators.rotation = InterpolatorAngle:new(entry.curRot[entry.rotationAxis])

		entry.networkInterpolators.rotation:setMinMax(entry.rotMin, entry.rotMax)

		entry.networkTimeInterpolator = InterpolationTime:new(1.2)
		entry.isTool = true

		return true
	end

	return false
end

function Cylindered:loadDependentMovingTools(xmlFile, baseName, entry)
	entry.dependentMovingTools = {}
	local j = 0

	while true do
		local refBaseName = baseName .. string.format(".dependentMovingTool(%d)", j)

		if not hasXMLProperty(xmlFile, refBaseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, refBaseName .. "#index", refBaseName .. "#index")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#node"), self.i3dMappings)
		local speedScale = getXMLFloat(xmlFile, refBaseName .. "#speedScale")
		local requiresMovement = Utils.getNoNil(getXMLBool(xmlFile, refBaseName .. "#requiresMovement"), false)
		local rotationBasedLimits = AnimCurve:new(Cylindered.limitInterpolator)
		local found = false
		local i = 0

		while true do
			local key = string.format("%s.limit(%d)", refBaseName .. ".rotationBasedLimits", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local keyFrame = self:loadRotationBasedLimits(xmlFile, key, entry)

			if keyFrame ~= nil then
				rotationBasedLimits:addKeyframe(keyFrame)

				found = true
			end

			i = i + 1
		end

		if not found then
			rotationBasedLimits = nil
		end

		local minTransLimits = getXMLString(xmlFile, refBaseName .. "#minTransLimits")
		local maxTransLimits = getXMLString(xmlFile, refBaseName .. "#maxTransLimits")
		local minRotLimits = getXMLString(xmlFile, refBaseName .. "#minRotLimits")
		local maxRotLimits = getXMLString(xmlFile, refBaseName .. "#maxRotLimits")

		if node ~= nil and (rotationBasedLimits ~= nil or speedScale ~= nil or minTransLimits ~= nil or maxTransLimits ~= nil or minRotLimits ~= nil or maxRotLimits ~= nil) then
			local dependentTool = {
				node = node,
				rotationBasedLimits = rotationBasedLimits,
				speedScale = speedScale,
				requiresMovement = requiresMovement,
				minTransLimits = StringUtil.getVectorNFromString(minTransLimits, 2),
				maxTransLimits = StringUtil.getVectorNFromString(maxTransLimits, 2),
				minRotLimits = StringUtil.getRadiansFromString(minRotLimits, 2),
				maxRotLimits = StringUtil.getRadiansFromString(maxRotLimits, 2)
			}

			table.insert(entry.dependentMovingTools, dependentTool)
		end

		j = j + 1
	end
end

function Cylindered:loadDependentParts(xmlFile, baseName, entry)
	entry.dependentPartNodes = {}
	local j = 0

	while true do
		local refBaseName = baseName .. string.format(".dependentPart(%d)", j)

		if not hasXMLProperty(xmlFile, refBaseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, refBaseName .. "#index", refBaseName .. "#index")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#node"), self.i3dMappings)

		if node ~= nil then
			table.insert(entry.dependentPartNodes, node)
		end

		j = j + 1
	end
end

function Cylindered:loadDependentComponentJoints(xmlFile, baseName, entry)
	if not self.isServer then
		return
	end

	entry.componentJoints = {}

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. "#componentJointIndex", baseName .. ".componentJoint#index")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. "#anchorActor", baseName .. ".componentJoint#anchorActor")

	local i = 0

	while true do
		local key = baseName .. string.format(".componentJoint(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local index = getXMLInt(xmlFile, key .. "#index")

		if index ~= nil and self.componentJoints[index] ~= nil then
			local anchorActor = Utils.getNoNil(getXMLInt(xmlFile, key .. "#anchorActor"), 0)
			local componentJoint = self.componentJoints[index]
			local jointEntry = {
				componentJoint = componentJoint,
				anchorActor = anchorActor,
				index = index
			}
			local jointNode = componentJoint.jointNode

			if jointEntry.anchorActor == 1 then
				jointNode = componentJoint.jointNodeActor1
			end

			local node = self.components[componentJoint.componentIndices[2]].node
			jointEntry.x, jointEntry.y, jointEntry.z = localToLocal(node, jointNode, 0, 0, 0)
			jointEntry.upX, jointEntry.upY, jointEntry.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
			jointEntry.dirX, jointEntry.dirY, jointEntry.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)

			table.insert(entry.componentJoints, jointEntry)
		else
			g_logManager:xmlWarning(self.configFileName, "Invalid index for '%s'", key)
		end

		i = i + 1
	end
end

function Cylindered:loadDependentAttacherJoints(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. "#jointIndices", baseName .. ".attacherJoint#jointIndices")

	local indices = StringUtil.getVectorNFromString(getXMLString(xmlFile, baseName .. ".attacherJoint#jointIndices"))

	if indices ~= nil then
		entry.attacherJoints = {}
		local availableAttacherJoints = nil

		if self.getAttacherJoints ~= nil then
			availableAttacherJoints = self:getAttacherJoints()
		end

		if availableAttacherJoints ~= nil then
			for i = 1, table.getn(indices) do
				if availableAttacherJoints[indices[i]] ~= nil then
					table.insert(entry.attacherJoints, availableAttacherJoints[indices[i]])
				end
			end
		end
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. "#inputAttacherJoint", baseName .. ".inputAttacherJoint#value")

	entry.inputAttacherJoint = Utils.getNoNil(getXMLBool(xmlFile, baseName .. ".inputAttacherJoint#value"), false)
end

function Cylindered:loadDependentWheels(xmlFile, baseName, entry)
	if SpecializationUtil.hasSpecialization(Wheels, self.specializations) then
		local indices = StringUtil.getVectorNFromString(getXMLString(xmlFile, baseName .. "#wheelIndices"))

		if indices ~= nil then
			entry.wheels = {}

			for _, wheelIndex in pairs(indices) do
				local wheel = self:getWheelFromWheelIndex(wheelIndex)

				if wheel ~= nil then
					table.insert(entry.wheels, wheel)
				else
					g_logManager:xmlWarning(self.configFileName, "Invalid wheelIndex '%s' for '%s'!", wheelIndex, baseName)
				end
			end
		end
	end
end

function Cylindered:loadDependentTranslatingParts(xmlFile, baseName, entry)
	entry.translatingParts = {}

	if entry.referencePoint ~= nil then
		local j = 0

		while true do
			local refBaseName = baseName .. string.format(".translatingPart(%d)", j)

			if not hasXMLProperty(xmlFile, refBaseName) then
				break
			end

			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, refBaseName .. "#index", refBaseName .. "#node")

			local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#node"), self.i3dMappings)

			if node ~= nil then
				local transEntry = {
					node = node
				}
				local x, y, z = getTranslation(node)
				transEntry.startPos = {
					x,
					y,
					z
				}
				local _, _, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))
				transEntry.referenceDistance = refZ
				transEntry.referenceDistancePoint = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#referenceDistancePoint"), self.i3dMappings)
				transEntry.minZTrans = getXMLFloat(xmlFile, refBaseName .. "#minZTrans")
				transEntry.maxZTrans = getXMLFloat(xmlFile, refBaseName .. "#maxZTrans")

				table.insert(entry.translatingParts, transEntry)
			end

			j = j + 1
		end
	end
end

function Cylindered:loadExtraDependentParts(xmlFile, baseName, entry)
	return true
end

function Cylindered:loadDependentAnimations(xmlFile, baseName, entry)
	entry.dependentAnimations = {}
	local i = 0

	while true do
		local baseKey = string.format("%s.dependentAnimation(%d)", baseName, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local animationName = getXMLString(self.xmlFile, baseKey .. "#name")

		if animationName ~= nil then
			local dependentAnimation = {
				name = animationName,
				lastPos = 0,
				translationAxis = getXMLInt(self.xmlFile, baseKey .. "#translationAxis"),
				rotationAxis = getXMLInt(self.xmlFile, baseKey .. "#rotationAxis"),
				node = entry.node
			}
			local useTranslatingPartIndex = getXMLInt(self.xmlFile, baseKey .. "#useTranslatingPartIndex")

			if useTranslatingPartIndex ~= nil and entry.translatingParts[useTranslatingPartIndex] ~= nil then
				dependentAnimation.node = entry.translatingParts[useTranslatingPartIndex].node
			end

			dependentAnimation.minValue = getXMLFloat(self.xmlFile, baseKey .. "#minValue")
			dependentAnimation.maxValue = getXMLFloat(self.xmlFile, baseKey .. "#maxValue")

			if dependentAnimation.rotationAxis ~= nil then
				dependentAnimation.minValue = MathUtil.degToRad(dependentAnimation.minValue)
				dependentAnimation.maxValue = MathUtil.degToRad(dependentAnimation.maxValue)
			end

			dependentAnimation.invert = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#invert"), false)

			table.insert(entry.dependentAnimations, dependentAnimation)
		end

		i = i + 1
	end
end

function Cylindered:loadCopyLocalDirectionParts(xmlFile, baseName, entry)
	entry.copyLocalDirectionParts = {}
	local j = 0

	while true do
		local refBaseName = baseName .. string.format(".copyLocalDirectionPart(%d)", j)

		if not hasXMLProperty(xmlFile, refBaseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, refBaseName .. "#index", refBaseName .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#node"), self.i3dMappings)

		if node ~= nil then
			local copyLocalDirectionPart = {
				node = node,
				dirScale = StringUtil.getVectorNFromString(getXMLString(xmlFile, refBaseName .. "#dirScale"), 3),
				upScale = StringUtil.getVectorNFromString(getXMLString(xmlFile, refBaseName .. "#upScale"), 3)
			}

			self:loadDependentComponentJoints(xmlFile, refBaseName, copyLocalDirectionPart)
			table.insert(entry.copyLocalDirectionParts, copyLocalDirectionPart)
		end

		j = j + 1
	end
end

function Cylindered:loadRotationBasedLimits(xmlFile, key, tool)
	local rotation = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#rotation"), nil)
	local rotMin = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#rotMin"), nil)
	local rotMax = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#rotMax"), nil)
	local transMin = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#transMin"), nil)
	local transMax = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#transMax"), nil)

	if rotation ~= nil and (rotMin ~= nil or rotMax ~= nil or transMin ~= nil or transMax ~= nil) then
		local time = (rotation - tool.rotMin) / (tool.rotMax - tool.rotMin)

		return {
			rotMin = rotMin,
			rotMax = rotMax,
			transMin = transMin,
			transMax = transMax,
			time = time
		}
	end

	return nil
end

function Cylindered:setMovingToolDirty(node)
	local spec = self.spec_cylindered
	local tool = spec.nodesToMovingTools[node]

	if tool ~= nil then
		local x, y, z = getRotation(tool.node)
		tool.curRot[1] = x
		tool.curRot[2] = y
		tool.curRot[3] = z
		local x, y, z = getTranslation(tool.node)
		tool.curTrans[1] = x
		tool.curTrans[2] = y
		tool.curTrans[3] = z

		Cylindered.setDirty(self, tool)

		if not self.isServer and self.isClient then
			tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
			tool.networkInterpolators.rotation:setAngle(tool.curRot[tool.rotationAxis])
		end
	end
end

function Cylindered:updateCylinderedInitial(placeComponents, keepDirty)
	if placeComponents == nil then
		placeComponents = true
	end

	if keepDirty == nil then
		keepDirty = false
	end

	local spec = self.spec_cylindered

	for _, part in pairs(spec.activeDirtyMovingParts) do
		Cylindered.setDirty(self, part)
	end

	for _, tool in ipairs(spec.movingTools) do
		if tool.isDirty then
			Cylindered.updateWheels(self, tool)

			if self.isServer then
				Cylindered.updateComponentJoints(self, tool, placeComponents)
			end

			tool.isDirty = keepDirty
		end

		self:updateDependentAnimations(tool, 9999)
	end

	for _, part in ipairs(spec.movingParts) do
		if part.isDirty then
			Cylindered.updateMovingPart(self, part, placeComponents)
			Cylindered.updateWheels(self, part)

			part.isDirty = keepDirty
		end

		self:updateDependentAnimations(part, 9999)
	end
end

function Cylindered:allowLoadMovingToolStates(superFunc)
	return true
end

function Cylindered:getMovingToolByNode(node)
	return self.spec_cylindered.nodesToMovingTools[node]
end

function Cylindered:getMovingPartByNode(node)
	return self.spec_cylindered.nodesToMovingParts[node]
end

function Cylindered:getIsMovingToolActive(movingTool)
	return movingTool.isActive
end

function Cylindered:isDetachAllowed(superFunc)
	local spec = self.spec_cylindered

	if spec.detachLockNodes ~= nil then
		for entry, data in pairs(spec.detachLockNodes) do
			local node = entry.node
			local rot = {
				getRotation(node)
			}

			if data.detachingRotMinLimit ~= nil and rot[entry.rotationAxis] < data.detachingRotMinLimit then
				return false, nil
			end

			if data.detachingRotMaxLimit ~= nil and data.detachingRotMaxLimit < rot[entry.rotationAxis] then
				return false, nil
			end

			local trans = {
				getTranslation(node)
			}

			if data.detachingTransMinLimit ~= nil and trans[entry.translationAxis] < data.detachingTransMinLimit then
				return false, nil
			end

			if data.detachingTransMaxLimit ~= nil and data.detachingTransMaxLimit < trans[entry.translationAxis] then
				return false, nil
			end
		end
	end

	return superFunc(self)
end

function Cylindered:loadObjectChangeValuesFromXML(superFunc, xmlFile, key, node, object)
	superFunc(self, xmlFile, key, node, object)

	local spec = self.spec_cylindered

	if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[node] ~= nil then
		local movingTool = spec.nodesToMovingTools[node]
		object.movingToolRotMaxActive = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#movingToolRotMaxActive"), movingTool.rotMax)
		object.movingToolRotMaxInactive = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#movingToolRotMaxInactive"), movingTool.rotMax)
		object.movingToolRotMinActive = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#movingToolRotMinActive"), movingTool.rotMin)
		object.movingToolRotMinInactive = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#movingToolRotMinInactive"), movingTool.rotMin)
	end
end

function Cylindered:setObjectChangeValues(superFunc, object, isActive)
	superFunc(self, object, isActive)

	local spec = self.spec_cylindered

	if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[object.node] ~= nil then
		local movingTool = spec.nodesToMovingTools[object.node]

		if isActive then
			movingTool.rotMax = object.movingToolRotMaxActive
			movingTool.rotMin = object.movingToolRotMinActive
		else
			movingTool.rotMax = object.movingToolRotMaxInactive
			movingTool.rotMin = object.movingToolRotMinInactive
		end
	end
end

function Cylindered:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if hasXMLProperty(xmlFile, baseKey) then
		entry.movingToolActivation = {
			node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#node"), self.i3dMappings),
			isInverted = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInverted"), false),
			openFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#openFactor"), 1),
			openOffset = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#openOffset"), 0)
		}
		entry.movingToolActivation.openOffsetInv = 1 - entry.movingToolActivation.openOffset
	end

	return true
end

function Cylindered:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	if dischargeNode.movingToolActivation == nil then
		return superFunc(self, dischargeNode)
	else
		local spec = self.spec_cylindered
		local movingToolActivation = dischargeNode.movingToolActivation
		local currentSpeed = superFunc(self, dischargeNode)
		local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
		local state = Cylindered.getMovingToolState(self, movingTool)

		if movingToolActivation.isInverted then
			state = math.abs(state - 1)
		end

		state = math.max(state - movingToolActivation.openOffset, 0) / movingToolActivation.openOffsetInv
		local speedFactor = MathUtil.clamp(state / movingToolActivation.openFactor, 0, 1)

		return currentSpeed * speedFactor
	end
end

function Cylindered:loadShovelNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if not hasXMLProperty(xmlFile, baseKey) then
		return true
	end

	entry.movingToolActivation = {
		node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#node"), self.i3dMappings),
		isInverted = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInverted"), false),
		openFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#openFactor"), 1)
	}

	return true
end

function Cylindered:getShovelNodeIsActive(superFunc, shovelNode)
	local isActive = superFunc(self, shovelNode)

	if not isActive or shovelNode.movingToolActivation == nil then
		return isActive
	end

	local spec = self.spec_cylindered
	local movingToolActivation = shovelNode.movingToolActivation
	local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
	local state = Cylindered.getMovingToolState(self, movingTool)

	if movingToolActivation.isInverted then
		state = math.abs(state - 1)
	end

	return movingToolActivation.openFactor < state
end

function Cylindered:loadDynamicMountGrabFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if not hasXMLProperty(xmlFile, baseKey) then
		return true
	end

	entry.movingToolActivation = {
		node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#node"), self.i3dMappings),
		isInverted = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInverted"), false),
		openFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#openFactor"), 1)
	}

	return true
end

function Cylindered:getIsDynamicMountGrabOpened(superFunc, grab)
	local isActive = superFunc(self, grab)

	if not isActive or grab.movingToolActivation == nil then
		return isActive
	end

	local spec = self.spec_cylindered
	local movingToolActivation = grab.movingToolActivation
	local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
	local state = Cylindered.getMovingToolState(self, movingTool)

	if movingToolActivation.isInverted then
		state = math.abs(state - 1)
	end

	return movingToolActivation.openFactor < state
end

function Cylindered:setComponentJointFrame(superFunc, jointDesc, anchorActor)
	superFunc(self, jointDesc, anchorActor)

	local spec = self.spec_cylindered

	for _, movingTool in ipairs(spec.movingTools) do
		for _, componentJoint in ipairs(movingTool.componentJoints) do
			local componentJointDesc = self.componentJoints[componentJoint.index]
			local jointNode = componentJointDesc.jointNode

			if componentJoint.anchorActor == 1 then
				jointNode = componentJointDesc.jointNodeActor1
			end

			local node = self.components[componentJointDesc.componentIndices[2]].node
			componentJoint.x, componentJoint.y, componentJoint.z = localToLocal(node, jointNode, 0, 0, 0)
			componentJoint.upX, componentJoint.upY, componentJoint.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
			componentJoint.dirX, componentJoint.dirY, componentJoint.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)
		end
	end
end

function Cylindered:getAdditionalSchemaText(superFunc)
	local t = superFunc(self)

	if self.isClient and self:getIsActiveForInput(true) then
		local spec = self.spec_cylindered

		if #spec.controlGroupNames > 1 then
			if t ~= nil then
				t = t .. " "
			end

			t = tostring(spec.currentControlGroupIndex)
		end
	end

	return t
end

function Cylindered:getWearMultiplier(superFunc)
	local spec = self.spec_cylindered
	local multiplier = superFunc(self)

	if spec.isHydraulicSamplePlaying then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function Cylindered:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_cylindered

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			for i = 1, table.getn(spec.movingTools) do
				local movingTool = spec.movingTools[i]
				local isSelectedGroup = movingTool.controlGroupIndex == 0 or movingTool.controlGroupIndex == spec.currentControlGroupIndex
				local canBeControlled = not g_gameSettings:getValue("easyArmControl") and not movingTool.isEasyControlTarget or movingTool.easyArmControlActive

				if movingTool.axisActionIndex ~= nil and isSelectedGroup and canBeControlled then
					local _, actionEventId = self:addActionEvent(spec.actionEvents, movingTool.axisActionIndex, self, Cylindered.actionEventInput, false, false, true, true, i, movingTool.axisActionIcon)

					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				end
			end
		end
	end
end

function Cylindered:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_cylindered

	for _, tool in ipairs(spec.movingTools) do
		local changed = false

		if tool.transSpeed ~= nil then
			local trans = tool.curTrans[tool.translationAxis]
			local changedTrans = false

			if tool.attachTransMax ~= nil and tool.attachTransMax < trans then
				trans = tool.attachTransMax
				changedTrans = true
			elseif tool.attachTransMin ~= nil and trans < tool.attachTransMin then
				trans = tool.attachTransMin
				changedTrans = true
			end

			if changedTrans then
				tool.curTrans[tool.translationAxis] = trans

				setTranslation(tool.node, unpack(tool.curTrans))

				changed = true
			end
		end

		if tool.rotSpeed ~= nil then
			local rot = tool.curRot[tool.rotationAxis]
			local changedRot = false

			if tool.attachRotMax ~= nil and tool.attachRotMax < rot then
				rot = tool.attachRotMax
				changedRot = true
			elseif tool.attachRotMin ~= nil and rot < tool.attachRotMin then
				rot = tool.attachRotMin
				changedRot = true
			end

			if changedRot then
				tool.curRot[tool.rotationAxis] = rot

				setRotation(tool.node, unpack(tool.curRot))

				changed = true
			end
		end

		if changed then
			Cylindered.setDirty(self, tool)
		end
	end
end

function Cylindered:onSelect(subSelectionIndex)
	local spec = self.spec_cylindered
	local controlGroupIndex = spec.controlGroupMapping[subSelectionIndex]

	if controlGroupIndex ~= nil then
		spec.currentControlGroupIndex = controlGroupIndex
	else
		spec.currentControlGroupIndex = 0
	end
end

function Cylindered:onUnselect()
	local spec = self.spec_cylindered
	spec.currentControlGroupIndex = 0
end

function Cylindered:onDeactivate()
	if self.isClient then
		local spec = self.spec_cylindered

		g_soundManager:stopSample(spec.samples.hydraulic)

		spec.isHydraulicSamplePlaying = false
	end
end

function Cylindered:setToolTranslation(tool, transSpeed, dt, delta)
	local curTrans = {
		getTranslation(tool.node)
	}
	local newTrans = curTrans[tool.translationAxis]
	local oldTrans = newTrans

	if transSpeed ~= nil then
		newTrans = newTrans + transSpeed * dt
	else
		newTrans = newTrans + delta
	end

	if tool.transMax ~= nil then
		newTrans = math.min(newTrans, tool.transMax)
	end

	if tool.transMin ~= nil then
		newTrans = math.max(newTrans, tool.transMin)
	end

	local diff = newTrans - oldTrans

	if dt ~= 0 then
		tool.lastTransSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		curTrans[tool.translationAxis] = newTrans
		tool.curTrans = curTrans

		setTranslation(tool.node, unpack(tool.curTrans))
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, transSpeed, dt)

		return true
	end

	return false
end

function Cylindered:setToolRotation(tool, rotSpeed, dt, delta)
	local curRot = {
		getRotation(tool.node)
	}
	local newRot = curRot[tool.rotationAxis]

	if rotSpeed ~= nil then
		newRot = newRot + rotSpeed * dt
	else
		newRot = newRot + delta
	end

	if tool.rotMax ~= nil then
		newRot = math.min(newRot, tool.rotMax)
	end

	if tool.rotMin ~= nil then
		newRot = math.max(newRot, tool.rotMin)
	end

	local diff = newRot - curRot[tool.rotationAxis]

	if rotSpeed ~= nil and dt ~= 0 then
		tool.lastRotSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		if tool.rotMin == nil and tool.rotMax == nil then
			if newRot > 2 * math.pi then
				newRot = newRot - 2 * math.pi
			end

			if newRot < 0 then
				newRot = newRot + 2 * math.pi
			end
		end

		tool.curRot[tool.rotationAxis] = newRot

		setRotation(tool.node, unpack(tool.curRot))
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, rotSpeed, dt)

		return true
	end

	return false
end

function Cylindered:setToolAnimation(tool, animSpeed, dt)
	local newAnimTime = tool.curAnimTime + animSpeed * dt

	if tool.animMaxTime ~= nil then
		newAnimTime = math.min(newAnimTime, tool.animMaxTime)
	end

	if tool.animMinTime ~= nil then
		newAnimTime = math.max(newAnimTime, tool.animMinTime)
	end

	local diff = newAnimTime - tool.curAnimTime

	if dt ~= 0 then
		tool.lastAnimSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		tool.curAnimTime = newAnimTime

		self:setAnimationTime(tool.animName, newAnimTime)
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, animSpeed, dt)

		return true
	end

	return false
end

function Cylindered:getMovingToolState(tool)
	local state = 0

	if tool.rotMax ~= nil and tool.rotMin ~= nil then
		state = (tool.curRot[tool.rotationAxis] - tool.rotMin) / (tool.rotMax - tool.rotMin)
	elseif tool.transMax ~= nil and tool.transMin ~= nil then
		state = (tool.curTrans[tool.translationAxis] - tool.transMin) / (tool.transMax - tool.transMin)
	end

	return state
end

function Cylindered:setDirty(part)
	if not part.isDirty or self.spec_cylindered.isLoading then
		part.isDirty = true
		self.anyMovingPartsDirty = true

		if part.delayedNode ~= nil then
			self:setDelayedData(part)
		end

		if part.isTool then
			Cylindered.updateAttacherJoints(self, part)
			Cylindered.updateWheels(self, part)
		end

		for _, v in pairs(part.dependentParts) do
			Cylindered.setDirty(self, v)
		end
	end
end

function Cylindered:updateWheels(part)
	if part.wheels ~= nil then
		for _, wheel in pairs(part.wheels) do
			wheel.positionX, wheel.positionY, wheel.positionZ = localToLocal(getParent(wheel.repr), wheel.node, wheel.startPositionX - wheel.steeringCenterOffsetX, wheel.startPositionY - wheel.steeringCenterOffsetY, wheel.startPositionZ - wheel.steeringCenterOffsetZ)

			if wheel.useReprDirection then
				wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.repr, wheel.node, 0, -1, 0)
				wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.repr, wheel.node, 1, 0, 0)
			elseif wheel.useDriveNodeDirection then
				wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 0, -1, 0)
				wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 1, 0, 0)
			end

			self:updateWheelBase(wheel)
		end
	end
end

function Cylindered:updateMovingPart(part, placeComponents, updateDependentParts)
	local refX, refY, refZ = nil
	local dirX = 0
	local dirY = 0
	local dirZ = 0
	local changed = false

	if part.referencePoint ~= nil then
		if part.moveToReferenceFrame then
			local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])

			setTranslation(part.node, x, y, z)

			changed = true
		end

		refX, refY, refZ = getWorldTranslation(part.referencePoint)

		if part.referenceDistance == 0 then
			if part.useLocalOffset then
				local lx, ly, lz = worldToLocal(part.node, refX, refY, refZ)
				dirX, dirY, dirZ = localDirectionToWorld(part.node, lx - part.localReferencePoint[1], ly - part.localReferencePoint[2], lz)
			else
				local x, y, z = getWorldTranslation(part.node)
				dirZ = refZ - z
				dirY = refY - y
				dirX = refX - x
			end
		else
			if part.updateLocalReferenceDistance then
				local _, y, z = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
				part.localReferenceDistance = MathUtil.vector2Length(y, z)
			end

			if part.referenceDistancePoint ~= nil then
				local _, _, z = worldToLocal(part.node, getWorldTranslation(part.referenceDistancePoint))
				part.referenceDistance = z
			end

			if part.localReferenceTranslate then
				local _, ly, lz = worldToLocal(part.node, refX, refY, refZ)

				if math.abs(ly) < part.referenceDistance then
					local dz = math.sqrt(part.referenceDistance * part.referenceDistance - ly * ly)
					local z1 = lz - dz - part.localReferenceDistance
					local z2 = lz + dz - part.localReferenceDistance

					if math.abs(z2) < math.abs(z1) then
						z1 = z2
					end

					local parentNode = getParent(part.node)
					local tx, ty, tz = unpack(part.localReferenceTranslation)
					local _, _, coz = localToLocal(parentNode, part.node, tx, ty, tz)
					local ox, oy, oz = localDirectionToLocal(part.node, parentNode, 0, 0, z1 - coz)

					setTranslation(part.node, tx + ox, ty + oy, tz + oz)

					changed = true
				end
			else
				local r1 = part.localReferenceDistance
				local r2 = part.referenceDistance
				local _, ly, lz = worldToLocal(part.node, refX, refY, refZ)
				local ix, iy, i2x, i2y = MathUtil.getCircleCircleIntersection(0, 0, r1, ly, lz, r2)
				local allowUpdate = true

				if part.referenceDistanceThreshold > 0 then
					local lRefX, lRefY, lRefZ = worldToLocal(part.node, getWorldTranslation(part.referencePoint))
					local x, y, z = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
					local currentDistance = MathUtil.vector3Length(lRefX - x, lRefY - y, lRefZ - z)

					if math.abs(currentDistance - part.referenceDistance) < part.referenceDistanceThreshold then
						allowUpdate = false
					end
				end

				if allowUpdate and ix ~= nil then
					if i2x ~= nil then
						local side = ix * (lz - iy) - iy * (ly - ix)

						if side < 0 ~= (part.localReferenceAngleSide < 0) then
							iy = i2y
							ix = i2x
						end
					end

					dirX, dirY, dirZ = localDirectionToWorld(part.node, 0, ix, iy)
					changed = true
				end
			end
		end
	else
		if part.alignToWorldY then
			dirX, dirY, dirZ = localDirectionToWorld(getRootNode(), 0, 1, 0)
			changed = true
		else
			dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, 0, 1)
			changed = true
		end

		if part.moveToReferenceFrame then
			local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])

			setTranslation(part.node, x, y, z)

			changed = true
		end

		if part.doLineAlignment then
			local foundPoint = false

			for i = 1, #part.orientationLineNodes - 1 do
				local startNode = part.orientationLineNodes[i]
				local endNode = part.orientationLineNodes[i + 1]
				local _, sy, sz = localToLocal(startNode, part.referenceFrame, 0, 0, 0)
				local _, ey, ez = localToLocal(endNode, part.referenceFrame, 0, 0, 0)
				local _, cy, cz = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
				local hasIntersection, i1y, i1z, i2y, i2z = MathUtil.getCircleLineIntersection(cy, cz, part.partLength, sy, sz, ey, ez)

				if hasIntersection then
					local targetY, targetZ = nil

					if not MathUtil.getIsOutOfBounds(i1y, sy, ey) and not MathUtil.getIsOutOfBounds(i1z, sz, ez) then
						targetZ = i1z
						targetY = i1y
						foundPoint = true
					end

					if not MathUtil.getIsOutOfBounds(i2y, sy, ey) and not MathUtil.getIsOutOfBounds(i2z, sz, ez) then
						targetZ = i2z
						targetY = i2y
						foundPoint = true
					end

					if foundPoint and not MathUtil.isNan(targetY) and not MathUtil.isNan(targetZ) then
						dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, targetY, targetZ)
						local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)

						I3DUtil.setWorldDirection(part.node, dirX, dirY, dirZ, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)

						changed = true

						break
					end
				end
			end
		end
	end

	if not self:getIsActive() and part.directionThreshold ~= nil and part.directionThreshold > 0 then
		local lDirX, lDirY, lDirZ = worldDirectionToLocal(getParent(part.node), dirX, dirY, dirZ)
		local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)

		if part.directionThreshold < math.abs(part.lastDirection[1] - lDirX) or part.directionThreshold < math.abs(part.lastDirection[2] - lDirY) or part.directionThreshold < math.abs(part.lastDirection[3] - lDirZ) or part.directionThreshold < math.abs(part.lastUpVector[1] - upX) or part.directionThreshold < math.abs(part.lastUpVector[2] - upY) or part.directionThreshold < math.abs(part.lastUpVector[3] - upZ) then
			part.lastDirection = {
				lDirX,
				lDirY,
				lDirZ
			}
			part.lastUpVector = {
				upX,
				upY,
				upZ
			}
		else
			dirZ = 0
			dirY = 0
			dirX = 0
			changed = false
		end
	end

	if (dirX ~= 0 or dirY ~= 0 or dirZ ~= 0) and part.doDirectionAlignment then
		local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)

		if part.invertZ then
			dirX = -dirX
			dirY = -dirY
			dirZ = -dirZ
		end

		I3DUtil.setWorldDirection(part.node, dirX, dirY, dirZ, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)

		changed = true

		if part.scaleZ and part.localReferenceDistance ~= nil then
			local len = MathUtil.vector3Length(dirX, dirY, dirZ)

			setScale(part.node, 1, 1, len / part.localReferenceDistance)
		end
	end

	if part.doRotationAlignment then
		local x, y, z = getRotation(part.referenceFrame)

		setRotation(part.node, x * part.rotMultiplier, y * part.rotMultiplier, z * part.rotMultiplier)

		changed = true
	end

	if part.referencePoint ~= nil then
		local numTranslatingParts = table.getn(part.translatingParts)

		if numTranslatingParts > 0 then
			local _, _, dist = worldToLocal(part.node, refX, refY, refZ)

			for i = 1, numTranslatingParts do
				local translatingPart = part.translatingParts[i]
				local newZ = (dist - translatingPart.referenceDistance) / numTranslatingParts

				if translatingPart.minZTrans ~= nil then
					newZ = math.max(translatingPart.minZTrans, newZ)
				end

				if translatingPart.maxZTrans ~= nil then
					newZ = math.min(translatingPart.maxZTrans, newZ)
				end

				local allowUpdate = true

				if part.referenceDistanceThreshold > 0 then
					local _, _, oldZ = getTranslation(translatingPart.node)

					if math.abs(oldZ - newZ) < part.referenceDistanceThreshold then
						allowUpdate = false
					end
				end

				if allowUpdate then
					setTranslation(translatingPart.node, translatingPart.startPos[1], translatingPart.startPos[2], newZ)

					changed = true
				end
			end
		end
	end

	if changed and part.copyLocalDirectionParts ~= nil then
		for _, copyLocalDirectionPart in pairs(part.copyLocalDirectionParts) do
			local dx, dy, dz = localDirectionToWorld(part.node, 0, 0, 1)
			dx, dy, dz = worldDirectionToLocal(getParent(part.node), dx, dy, dz)
			dx = dx * copyLocalDirectionPart.dirScale[1]
			dy = dy * copyLocalDirectionPart.dirScale[2]
			dz = dz * copyLocalDirectionPart.dirScale[3]
			local ux, uy, uz = localDirectionToWorld(part.node, 0, 1, 0)
			ux, uy, uz = worldDirectionToLocal(getParent(part.node), ux, uy, uz)
			ux = ux * copyLocalDirectionPart.upScale[1]
			uy = uy * copyLocalDirectionPart.upScale[2]
			uz = uz * copyLocalDirectionPart.upScale[3]

			setDirection(copyLocalDirectionPart.node, dx, dy, dz, ux, uy, uz)

			changed = true

			if self.isServer then
				Cylindered.updateComponentJoints(self, copyLocalDirectionPart, placeComponents)
			end
		end
	end

	if self.isServer and changed then
		Cylindered.updateComponentJoints(self, part, placeComponents)
		Cylindered.updateAttacherJoints(self, part)
		Cylindered.updateWheels(self, part)
	end

	if changed then
		Cylindered.updateWheels(self, part)
	end

	if updateDependentParts and part.dependentParts ~= nil then
		for _, part in pairs(part.dependentParts) do
			Cylindered.updateMovingPart(self, part, placeComponents, updateDependentParts)
		end
	end

	part.isDirty = false
end

function Cylindered:updateComponentJoints(entry, placeComponents)
	if self.isServer and entry.componentJoints ~= nil then
		for _, joint in ipairs(entry.componentJoints) do
			local componentJoint = joint.componentJoint
			local jointNode = componentJoint.jointNode

			if joint.anchorActor == 1 then
				jointNode = componentJoint.jointNodeActor1
			end

			if placeComponents then
				local node = self.components[componentJoint.componentIndices[2]].node
				local x, y, z = localToWorld(jointNode, joint.x, joint.y, joint.z)
				local upX, upY, upZ = localDirectionToWorld(jointNode, joint.upX, joint.upY, joint.upZ)
				local dirX, dirY, dirZ = localDirectionToWorld(jointNode, joint.dirX, joint.dirY, joint.dirZ)

				setWorldTranslation(node, x, y, z)
				I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
			end

			self:setComponentJointFrame(componentJoint, joint.anchorActor)
		end
	end
end

function Cylindered:updateAttacherJoints(entry)
	if self.isServer then
		if entry.attacherJoints ~= nil then
			for _, joint in ipairs(entry.attacherJoints) do
				if joint.jointIndex ~= 0 then
					setJointFrame(joint.jointIndex, 0, joint.jointTransform)
				end
			end
		end

		if entry.inputAttacherJoint and self.getAttacherVehicle ~= nil then
			local attacherVehicle = self:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local attacherJoints = attacherVehicle:getAttacherJoints()

				if attacherJoints ~= nil then
					local jointDescIndex = attacherVehicle:getAttacherJointIndexFromObject(self)

					if jointDescIndex ~= nil then
						local jointDesc = attacherJoints[jointDescIndex]
						local inputAttacherJoint = self:getActiveInputAttacherJoint()

						if inputAttacherJoint ~= nil then
							setJointFrame(jointDesc.jointIndex, 1, inputAttacherJoint.node)
						end
					end
				end
			end
		end
	end
end

function Cylindered.limitInterpolator(first, second, alpha)
	local oneMinusAlpha = 1 - alpha
	local rotMin, rotMax, transMin, transMax = nil

	if first.rotMin ~= nil and second.rotMin ~= nil then
		rotMin = first.rotMin * alpha + second.rotMin * oneMinusAlpha
	end

	if first.rotMax ~= nil and second.rotMax ~= nil then
		rotMax = first.rotMax * alpha + second.rotMax * oneMinusAlpha
	end

	if first.transMin ~= nil and second.transMin ~= nil then
		transMin = first.minTrans * alpha + second.transMin * oneMinusAlpha
	end

	if first.transMax ~= nil and second.transMax ~= nil then
		transMax = first.transMax * alpha + second.transMax * oneMinusAlpha
	end

	return rotMin, rotMax, transMin, transMax
end

function Cylindered:updateRotationBasedLimits(tool, dependentTool)
	if dependentTool.rotationBasedLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.rotationBasedLimits ~= nil then
			local minRot, maxRot, minTrans, maxTrans = dependentTool.rotationBasedLimits:get(state)

			if minRot ~= nil then
				dependentTool.movingTool.rotMin = minRot
			end

			if maxRot ~= nil then
				dependentTool.movingTool.rotMax = maxRot
			end

			if minTrans ~= nil then
				dependentTool.movingTool.transMin = minTrans
			end

			if maxTrans ~= nil then
				dependentTool.movingTool.transMax = maxTrans
			end

			local isDirty = false

			if minRot ~= nil or maxRot ~= nil then
				isDirty = isDirty or Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)
			end

			if minTrans ~= nil or maxTrans ~= nil then
				isDirty = isDirty or Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)
			end

			if isDirty then
				Cylindered.setDirty(self, dependentTool.movingTool)
				self:raiseDirtyFlags(dependentTool.movingTool.dirtyFlag)
				self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
			end
		end
	end
end

function Cylindered:actionEventInput(actionName, inputValue, callbackState, isAnalog, isMouse)
	local spec = self.spec_cylindered
	local tool = spec.movingTools[callbackState]

	if tool ~= nil then
		local move = nil

		if tool.invertAxis then
			move = -inputValue
		else
			move = inputValue
		end

		move = move * g_gameSettings:getValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY)

		if isMouse then
			move = move * 16.666 / g_currentDt * tool.mouseSpeedFactor

			if tool.moveLocked then
				if math.abs(inputValue) < 0.75 then
					if math.abs(move) > math.abs(tool.lockTool.move) * 2 then
						tool.moveLocked = false
					else
						move = 0
					end
				else
					tool.moveLocked = false
				end
			else
				local function checkOtherTools(tools)
					for tool2Index, tool2 in ipairs(tools) do
						if tool2Index ~= callbackState and tool2.move ~= nil and tool2.move ~= 0 then
							if math.abs(tool2.move) < math.abs(move) then
								tool2.move = 0
								tool2.moveToSend = 0
								tool2.moveLocked = true
								tool2.lockTool = tool
							else
								move = 0
								tool.moveLocked = true
								tool.lockTool = tool2
							end
						end
					end
				end

				checkOtherTools(spec.movingTools)

				if self.getAttachedImplements ~= nil then
					for _, implement in pairs(self:getAttachedImplements()) do
						local vehicle = implement.object

						if vehicle.spec_cylindered ~= nil then
							checkOtherTools(vehicle.spec_cylindered.movingTools)
						end
					end
				end
			end
		end

		if move ~= tool.move then
			tool.move = move
		end

		if tool.move ~= tool.moveToSend then
			tool.moveToSend = tool.move

			self:raiseDirtyFlags(spec.cylinderedInputDirtyFlag)
		end
	end
end

function Cylindered:getMovingToolDashboardState(dashboard)
	local vehicle = self

	if dashboard.attacherJointIndex ~= nil then
		local implement = self:getImplementFromAttacherJointIndex(dashboard.attacherJointIndex)

		if implement ~= nil then
			vehicle = implement.object
		else
			vehicle = nil
		end
	end

	if vehicle ~= nil then
		local spec = vehicle.spec_cylindered

		if spec ~= nil then
			for _, movingTool in ipairs(spec.movingTools) do
				if movingTool.axis == dashboard.axis then
					return (movingTool.move + 1) / 2
				end
			end
		end
	end

	return 0.5
end

function Cylindered:movingToolDashboardAttributes(xmlFile, key, dashboard)
	dashboard.axis = getXMLString(xmlFile, key .. "#axis")

	if dashboard.axis == nil then
		g_logManager:xmlWarning(self.configFileName, "Misssing axis attribute for dashboard '%s'", key)

		return false
	end

	dashboard.attacherJointIndex = getXMLInt(xmlFile, key .. "#attacherJointIndex")

	return true
end
