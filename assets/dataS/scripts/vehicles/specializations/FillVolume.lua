FillVolume = {
	SEND_NUM_BITS = 6,
	SEND_MAX_SIZE = 15
}
FillVolume.SEND_PRECISION = FillVolume.SEND_MAX_SIZE / math.pow(2, FillVolume.SEND_NUM_BITS)

function FillVolume.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function FillVolume.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolume", FillVolume.loadFillVolume)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeInfo", FillVolume.loadFillVolumeInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeHeightNode", FillVolume.loadFillVolumeHeightNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeLoadInfo", FillVolume.getFillVolumeLoadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUnloadInfo", FillVolume.getFillVolumeUnloadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeIndicesByFillUnitIndex", FillVolume.getFillVolumeIndicesByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillTypeByFillUnitIndex", FillVolume.setFillVolumeForcedFillTypeByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillType", FillVolume.setFillVolumeForcedFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUVScrollSpeed", FillVolume.getFillVolumeUVScrollSpeed)
end

function FillVolume.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setMovingToolDirty", FillVolume.setMovingToolDirty)
end

function FillVolume.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", FillVolume)
end

function FillVolume.initSpecialization()
	g_configurationManager:addConfigurationType("fillVolume", g_i18n:getText("configuration_fillVolume"), "fillVolume", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function FillVolume:onLoad(savegame)
	local spec = self.spec_fillVolume
	local fillVolumeConfigurationId = Utils.getNoNil(self.configurations.fillVolume, 1)
	local configKey = string.format("vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(%d).volumes", fillVolumeConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration", fillVolumeConfigurationId, self.components, self)

	spec.volumes = {}
	spec.fillVolumeDeformersByNode = {}
	spec.fillUnitFillVolumeMapping = {}
	local i = 0

	while true do
		local key = string.format("%s.volume(%d)", configKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadFillVolume(self.xmlFile, key, entry) then
			table.insert(spec.volumes, entry)

			entry.index = #spec.volumes
		end

		i = i + 1
	end

	for _, mapping in ipairs(spec.fillUnitFillVolumeMapping) do
		for _, fillVolume in ipairs(mapping.fillVolumes) do
			fillVolume.fillUnitFactor = fillVolume.fillUnitFactor / mapping.sumFactors
		end
	end

	for _, fillVolume in ipairs(spec.volumes) do
		local capacity = self:getFillUnitCapacity(fillVolume.fillUnitIndex)
		local fillVolumeCapacity = capacity * fillVolume.fillUnitFactor
		fillVolume.volume = createFillPlaneShape(fillVolume.baseNode, "fillPlane", fillVolumeCapacity, fillVolume.maxDelta, fillVolume.maxSurfaceAngle, fillVolume.maxPhysicalSurfaceAngle, fillVolume.maxSubDivEdgeLength, fillVolume.allSidePlanes)

		if fillVolume.volume == nil or fillVolume.volume == 0 then
			print("Warning: fillVolume '" .. tostring(getName(fillVolume.baseNode)) .. "' could not create actual fillVolume in '" .. self.configFileName .. "'! Simplifying the mesh could help")
		else
			setVisibility(fillVolume.volume, false)

			for i = #fillVolume.deformers, 1, -1 do
				local deformer = fillVolume.deformers[i]
				deformer.polyline = findPolyline(fillVolume.volume, deformer.posX, deformer.posZ)

				if deformer.polyline == nil and deformer.polyline ~= -1 then
					print("Warning: Could not find 'polyline' for '" .. tostring(getName(deformer.node)) .. "' in '" .. self.configFileName .. "'")
					table.remove(fillVolume.deformers, i)
				end
			end

			link(fillVolume.baseNode, fillVolume.volume)
		end
	end

	spec.loadInfos = {}
	local i = 0

	while true do
		local key = string.format("vehicle.fillVolume.loadInfos.loadInfo(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
			table.insert(spec.loadInfos, entry)
		end

		i = i + 1
	end

	spec.unloadInfos = {}
	local i = 0

	while true do
		local key = string.format("vehicle.fillVolume.unloadInfos.unloadInfo(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadFillVolumeInfo(self.xmlFile, key, entry) then
			table.insert(spec.unloadInfos, entry)
		end

		i = i + 1
	end

	spec.heightNodes = {}
	spec.fillVolumeIndexToHeightNode = {}
	local i = 0

	while true do
		local key = string.format("vehicle.fillVolume.heightNodes.heightNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local entry = {}

		if self:loadFillVolumeHeightNode(self.xmlFile, key, entry) then
			table.insert(spec.heightNodes, entry)

			if spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] == nil then
				spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex] = {}
			end

			table.insert(spec.fillVolumeIndexToHeightNode[entry.fillVolumeIndex], entry)
		end

		i = i + 1
	end

	spec.lastPositionInfo = {
		0,
		0
	}
	spec.lastPositionInfoSent = {
		0,
		0
	}
	spec.availableFillNodes = {}
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function FillVolume:onDelete()
	local spec = self.spec_fillVolume

	for _, fillVolume in ipairs(spec.volumes) do
		if fillVolume.volume ~= nil then
			delete(fillVolume.volume)
		end

		fillVolume.volume = nil
	end
end

function FillVolume:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_fillVolume

		if streamReadBool(streamId) then
			local x = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			local z = streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			spec.lastPositionInfo[1] = x
			spec.lastPositionInfo[2] = z
		end
	end
end

function FillVolume:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_fillVolume

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			local x = (spec.lastPositionInfoSent[1] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, x, FillVolume.SEND_NUM_BITS)

			local z = (spec.lastPositionInfoSent[2] + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE * (math.pow(2, FillVolume.SEND_NUM_BITS) - 1)

			streamWriteUIntN(streamId, z, FillVolume.SEND_NUM_BITS)

			spec.lastPositionInfoSent[1] = math.floor(x) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
			spec.lastPositionInfoSent[2] = math.floor(z) / (math.pow(2, FillVolume.SEND_NUM_BITS) - 1) * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
		end
	end
end

function FillVolume:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_fillVolume

		for _, volume in pairs(spec.volumes) do
			for _, deformer in ipairs(volume.deformers) do
				if deformer.isDirty and deformer.polyline ~= nil and deformer.polyline ~= -1 then
					deformer.isDirty = false
					local posX, _, posZ = localToLocal(deformer.node, deformer.baseNode, 0, 0, 0)

					if math.abs(posX - deformer.posX) > 0.0001 or math.abs(posZ - deformer.posZ) > 0.0001 then
						deformer.lastPosX = posX
						deformer.lastPosZ = posZ
						local dx = posX - deformer.initPos[1]
						local dz = posZ - deformer.initPos[3]

						setPolylineTranslation(volume.volume, deformer.polyline, dx, dz)
					end
				end
			end

			local uvScrollSpeedX, uvScrollSpeedY, uvScrollSpeedZ = self:getFillVolumeUVScrollSpeed(volume.index)

			if uvScrollSpeedX ~= 0 or uvScrollSpeedY ~= 0 or uvScrollSpeedZ ~= 0 then
				volume.uvPosition[1] = volume.uvPosition[1] + uvScrollSpeedX * dt
				volume.uvPosition[2] = volume.uvPosition[2] + uvScrollSpeedY * dt
				volume.uvPosition[3] = volume.uvPosition[3] + uvScrollSpeedZ * dt

				setShaderParameter(volume.volume, "uvOffset", volume.uvPosition[1], volume.uvPosition[2], volume.uvPosition[3], 0, false)
			end
		end

		for _, heightNode in pairs(spec.heightNodes) do
			if heightNode.isDirty then
				heightNode.isDirty = false
				local baseNode = spec.volumes[heightNode.fillVolumeIndex].baseNode
				local volumeNode = spec.volumes[heightNode.fillVolumeIndex].volume

				if baseNode ~= nil and volumeNode ~= nil then
					local minHeight = math.huge
					local maxHeight = -math.huge
					local maxHeightWorld = -math.huge

					for _, refNode in pairs(heightNode.refNodes) do
						local x, _, z = localToLocal(refNode.refNode, baseNode, 0, 0, 0)
						local height = getFillPlaneHeightAtLocalPos(volumeNode, x, z)
						minHeight = math.min(minHeight, height)
						maxHeight = math.max(maxHeight, height)
						local _, yw, _ = localToWorld(baseNode, x, height, z)
						maxHeightWorld = math.max(maxHeightWorld, yw)
					end

					heightNode.currentMinHeight = minHeight
					heightNode.currentMaxHeight = maxHeight
					heightNode.currentMaxHeightWorld = maxHeightWorld

					for _, node in pairs(heightNode.nodes) do
						local sx = node.scaleAxis[1] * minHeight
						local sy = node.scaleAxis[2] * minHeight
						local sz = node.scaleAxis[3] * minHeight

						if node.scaleMax[1] > 0 then
							sx = math.min(node.scaleMax[1], sx)
						end

						if node.scaleMax[2] > 0 then
							sy = math.min(node.scaleMax[2], sy)
						end

						if node.scaleMax[3] > 0 then
							sz = math.min(node.scaleMax[3], sz)
						end

						local tx = node.transAxis[1] * minHeight
						local ty = node.transAxis[2] * minHeight
						local tz = node.transAxis[3] * minHeight

						if node.transMax[1] > 0 then
							tx = math.min(node.transMax[1], tx)
						end

						if node.transMax[2] > 0 then
							ty = math.min(node.transMax[2], ty)
						end

						if node.transMax[3] > 0 then
							tz = math.min(node.transMax[3], tz)
						end

						setScale(node.node, node.baseScale[1] + sx, node.baseScale[2] + sy, node.baseScale[3] + sz)
						setTranslation(node.node, node.basePosition[1] + tx, node.basePosition[2] + ty, node.basePosition[3] + tz)

						if node.orientateToWorldY then
							local _, dy, _ = localDirectionToWorld(getParent(node.node), 0, 1, 0)
							local alpha = math.acos(dy)

							setRotation(node.node, alpha, 0, 0)
						end
					end
				end
			end
		end
	end
end

function FillVolume:loadFillVolume(xmlFile, key, entry)
	local spec = self.spec_fillVolume

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	entry.baseNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if entry.baseNode == nil then
		print("Warning: fillVolume '" .. tostring(key) .. "' has an invalid 'node' in '" .. self.configFileName .. "'!")

		return false
	end

	local fillUnitIndex = getXMLInt(xmlFile, key .. "#fillUnitIndex")
	entry.fillUnitIndex = fillUnitIndex

	if fillUnitIndex == nil then
		print("Warning: fillVolume '" .. tostring(key) .. "' has no 'fillUnitIndex' given in '" .. self.configFileName .. "'!")

		return false
	end

	if not self:getFillUnitExists(fillUnitIndex) then
		print("Warning: fillVolume '" .. tostring(key) .. "' has an invalid 'fillUnitIndex' in '" .. self.configFileName .. "'!")

		return false
	end

	entry.fillUnitFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#fillUnitFactor"), 1)

	if spec.fillUnitFillVolumeMapping[fillUnitIndex] == nil then
		spec.fillUnitFillVolumeMapping[fillUnitIndex] = {
			sumFactors = 0,
			fillVolumes = {}
		}
	end

	table.insert(spec.fillUnitFillVolumeMapping[fillUnitIndex].fillVolumes, entry)

	spec.fillUnitFillVolumeMapping[fillUnitIndex].sumFactors = entry.fillUnitFactor
	entry.allSidePlanes = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allSidePlanes"), true)
	local defaultFillTypeStr = getXMLString(xmlFile, key .. "#defaultFillType")

	if defaultFillTypeStr ~= nil then
		local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeStr)

		if defaultFillTypeIndex == nil then
			print("Warning: Invalid defaultFillType '" .. tostring(defaultFillTypeStr) .. "' for '" .. tostring(key) .. "' in '" .. self.configFileName .. "'")

			return false
		else
			entry.defaultFillType = defaultFillTypeIndex
		end
	else
		entry.defaultFillType = self:getFillUnitFirstSupportedFillType(fillUnitIndex)
	end

	local forcedVolumeFillTypeStr = getXMLString(xmlFile, key .. "#defaultFillType")

	if forcedVolumeFillTypeStr ~= nil then
		local forcedVolumeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(forcedVolumeFillTypeStr)

		if forcedVolumeFillTypeIndex ~= nil then
			entry.forcedVolumeFillType = forcedVolumeFillTypeIndex
		else
			print("Warning: Invalid forcedVolumeFillType '" .. tostring(forcedVolumeFillTypeStr) .. "' for '" .. tostring(key) .. "' in '" .. self.configFileName .. "'")

			return false
		end
	end

	entry.maxDelta = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDelta"), 1)
	entry.maxSurfaceAngle = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxAllowedHeapAngle"), 35))
	entry.maxPhysicalSurfaceAngle = math.rad(35)
	entry.maxSubDivEdgeLength = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxSubDivEdgeLength"), 0.9)
	entry.uvPosition = {
		0,
		0,
		0
	}
	entry.deformers = {}
	local j = 0

	while true do
		local deformerKey = string.format("%s.deformNode(%d)", key, j)

		if not hasXMLProperty(xmlFile, deformerKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, deformerKey .. "#index", deformerKey .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, deformerKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			local initPos = {
				localToLocal(node, entry.baseNode, 0, 0, 0)
			}
			local deformer = {
				node = node,
				initPos = initPos,
				posX = initPos[1],
				posZ = initPos[3],
				volume = entry.volume,
				baseNode = entry.baseNode
			}

			table.insert(entry.deformers, deformer)

			spec.fillVolumeDeformersByNode[node] = deformer
		end

		j = j + 1
	end

	entry.lastFillType = FillType.UNKNOWN

	return true
end

function FillVolume:loadFillVolumeInfo(xmlFile, key, entry)
	entry.nodes = {}
	local i = 0

	while true do
		local infoKey = key .. string.format(".node(%d)", i)

		if not hasXMLProperty(xmlFile, infoKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, infoKey .. "#index", infoKey .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, infoKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			local nodeEntry = {
				node = node,
				width = Utils.getNoNil(getXMLFloat(xmlFile, infoKey .. "#width"), 1),
				length = Utils.getNoNil(getXMLFloat(xmlFile, infoKey .. "#length"), 1),
				fillVolumeHeightIndex = getXMLInt(xmlFile, infoKey .. "#fillVolumeHeightIndex"),
				priority = Utils.getNoNil(getXMLInt(xmlFile, infoKey .. "#priority"), 1),
				minHeight = getXMLFloat(xmlFile, infoKey .. "#minHeight"),
				maxHeight = getXMLFloat(xmlFile, infoKey .. "#maxHeight"),
				minFillLevelPercentage = getXMLFloat(xmlFile, infoKey .. "#minFillLevelPercentage"),
				maxFillLevelPercentage = getXMLFloat(xmlFile, infoKey .. "#maxFillLevelPercentage"),
				heightForTranslation = getXMLFloat(xmlFile, infoKey .. "#heightForTranslation"),
				translationStart = StringUtil.getVectorNFromString(getXMLString(xmlFile, infoKey .. "#translationStart"), 3),
				translationEnd = StringUtil.getVectorNFromString(getXMLString(xmlFile, infoKey .. "#translationEnd"), 3),
				translationAlpha = 0
			}

			table.insert(entry.nodes, nodeEntry)
		else
			g_logManager:xmlWarning(self.configFileName, "Missing node for '%s'", infoKey)
		end

		i = i + 1
	end

	table.sort(entry.nodes, function (a, b)
		return b.priority < a.priority
	end)

	return true
end

function FillVolume:loadFillVolumeHeightNode(xmlFile, key, entry)
	entry.isDirty = false
	entry.fillVolumeIndex = getXMLInt(xmlFile, key .. "#fillVolumeIndex") or 1

	if self.spec_fillVolume.volumes[entry.fillVolumeIndex] == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid fillVolumeIndex '%d' for heightNode '%s'. Igoring heightNode!", entry.fillVolumeIndex, key)

		return false
	end

	entry.refNodes = {}
	local i = 0

	while true do
		local nodeKey = key .. string.format(".refNode(%d)", i)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, nodeKey .. "#index", nodeKey .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, nodeKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			table.insert(entry.refNodes, {
				refNode = node
			})
		else
			g_logManager:xmlWarning(self.configFileName, "Missing node for '%s'", nodeKey)
		end

		i = i + 1
	end

	entry.nodes = {}
	i = 0

	while true do
		local nodeKey = key .. string.format(".node(%d)", i)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, nodeKey .. "#index", nodeKey .. "#node")

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, nodeKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			local nodeEntry = {
				node = node,
				baseScale = {
					StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, nodeKey .. "#baseScale"), "1 1 1"))
				},
				scaleAxis = {
					StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, nodeKey .. "#scaleAxis"), "0 0 0"))
				},
				scaleMax = {
					StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, nodeKey .. "#scaleMax"), "0 0 0"))
				},
				basePosition = {
					getTranslation(node)
				},
				transAxis = {
					StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, nodeKey .. "#transAxis"), "0 0 0"))
				},
				transMax = {
					StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(xmlFile, nodeKey .. "#transMax"), "0 0 0"))
				},
				orientateToWorldY = Utils.getNoNil(getXMLBool(xmlFile, nodeKey .. "#orientateToWorldY"), false)
			}

			table.insert(entry.nodes, nodeEntry)
		else
			g_logManager:xmlWarning(self.configFileName, "Missing node for '%s'", nodeKey)
		end

		i = i + 1
	end

	return true
end

function FillVolume:getFillVolumeLoadInfo(loadInfoIndex)
	local spec = self.spec_fillVolume

	return spec.loadInfos[loadInfoIndex]
end

function FillVolume:getFillVolumeUnloadInfo(unloadInfoIndex)
	local spec = self.spec_fillVolume

	return spec.unloadInfos[unloadInfoIndex]
end

function FillVolume:getFillVolumeIndicesByFillUnitIndex(fillUnitIndex)
	local spec = self.spec_fillVolume
	local indices = {}

	for i, fillVolume in ipairs(spec.volumes) do
		if fillVolume.fillUnitIndex == fillUnitIndex then
			table.insert(indices, i)
		end
	end

	return indices
end

function FillVolume:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedFillType)
	local spec = self.spec_fillVolume

	for i, fillVolume in ipairs(spec.volumes) do
		if fillVolume.fillUnitIndex == fillUnitIndex then
			self:setFillVolumeForcedFillType(i, forcedFillType)
		end
	end
end

function FillVolume:setFillVolumeForcedFillType(fillVolumeIndex, forcedFillType)
	local spec = self.spec_fillVolume

	if spec.volumes[fillVolumeIndex] ~= nil then
		spec.volumes[fillVolumeIndex].forcedFillType = forcedFillType
	end
end

function FillVolume:getFillVolumeUVScrollSpeed()
	return 0, 0, 0
end

function FillVolume:setMovingToolDirty(superFunc, node)
	superFunc(self, node)

	local spec = self.spec_fillVolume

	if spec.fillVolumeDeformersByNode ~= nil then
		local deformer = spec.fillVolumeDeformersByNode[node]

		if deformer ~= nil then
			deformer.isDirty = true
		end
	end
end

function FillVolume:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_fillVolume
	local mapping = spec.fillUnitFillVolumeMapping[fillUnitIndex]

	if mapping == nil then
		return
	end

	local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)
	fillType = self:getFillUnitFillType(fillUnitIndex)

	for _, volume in ipairs(mapping.fillVolumes) do
		local baseNode = volume.baseNode
		local volumeNode = volume.volume

		if baseNode == nil or volumeNode == nil then
			return
		end

		if volume.forcedFillType ~= nil then
			fillType = volume.forcedFillType
		end

		if fillLevel == 0 then
			volume.forcedFillType = nil
		end

		if fillType ~= volume.lastFillType then
			local maxPhysicalSurfaceAngle = nil
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillType)

			if fillType ~= nil then
				maxPhysicalSurfaceAngle = fillType.maxPhysicalSurfaceAngle
			end

			if maxPhysicalSurfaceAngle ~= nil and volume.volume ~= nil then
				setFillPlaneMaxPhysicalSurfaceAngle(volume.volume, maxPhysicalSurfaceAngle)
			end
		end

		setVisibility(volume.volume, fillLevel > 0)

		local material = nil

		if fillType ~= FillType.UNKNOWN and fillType ~= volume.lastFillType then
			local usedFillType = fillType

			if volume.forcedVolumeFillType ~= nil then
				usedFillType = volume.forcedVolumeFillType
			end

			material = g_materialManager:getMaterial(usedFillType, "fillplane", 1)
		end

		if fillType ~= FillType.UNKNOWN and fillType ~= volume.lastFillType then
			if material == nil and volume.defaultFillType ~= nil then
				material = g_materialManager:getMaterial(volume.defaultFillType, "fillplane", 1)
			end

			if material ~= nil then
				setMaterial(volume.volume, material, 0)
			end
		end

		if fillPositionData ~= nil then
			for i = #spec.availableFillNodes, 1, -1 do
				spec.availableFillNodes[i] = nil
			end

			if fillPositionData.nodes ~= nil then
				local neededPriority = fillPositionData.nodes[1].priority

				while table.getn(spec.availableFillNodes) == 0 and neededPriority >= 1 do
					for _, node in pairs(fillPositionData.nodes) do
						if neededPriority <= node.priority then
							local doInsert = true

							if node.minHeight ~= nil or node.maxHeight ~= nil then
								local height = -math.huge

								if node.fillVolumeHeightIndex ~= nil and spec.heightNodes[node.fillVolumeHeightIndex] ~= nil then
									for _, refNode in pairs(spec.heightNodes[node.fillVolumeHeightIndex].refNodes) do
										local x, _, z = localToLocal(refNode.refNode, baseNode, 0, 0, 0)
										height = math.max(height, getFillPlaneHeightAtLocalPos(volumeNode, x, z))
									end
								else
									local x, _, z = localToLocal(node.node, baseNode, 0, 0, 0)
									height = math.max(height, getFillPlaneHeightAtLocalPos(volumeNode, x, z))
								end

								if node.minHeight ~= nil and height < node.minHeight then
									doInsert = false
								end

								if node.maxHeight ~= nil and node.maxHeight < height then
									doInsert = false
								end

								if node.heightForTranslation ~= nil then
									if node.heightForTranslation < height then
										node.translationAlpha = node.translationAlpha + 0.01
										local x, y, z = MathUtil.vector3ArrayLerp(node.translationStart, node.translationEnd, node.translationAlpha)

										setTranslation(node.node, x, y, z)
									else
										node.translationAlpha = node.translationAlpha - 0.01
									end

									node.translationAlpha = MathUtil.clamp(node.translationAlpha, 0, 1)
								end
							end

							if node.minFillLevelPercentage ~= nil or node.maxFillLevelPercentage ~= nil then
								local percentage = fillLevel / self:getFillUnitCapacity(fillUnitIndex)

								if node.minFillLevelPercentage ~= nil and percentage < node.minFillLevelPercentage then
									doInsert = false
								end

								if node.maxFillLevelPercentage ~= nil and node.maxFillLevelPercentage < percentage then
									doInsert = false
								end
							end

							if doInsert then
								table.insert(spec.availableFillNodes, node)
							end
						end
					end

					if table.getn(spec.availableFillNodes) > 0 then
						break
					end

					neededPriority = neededPriority - 1
				end
			else
				table.insert(spec.availableFillNodes, fillPositionData)
			end

			local numFillNodes = table.getn(spec.availableFillNodes)
			local avgX = 0
			local avgZ = 0

			for i = 1, numFillNodes do
				local node = spec.availableFillNodes[i]
				local x0, y0, z0 = getWorldTranslation(node.node)
				local d1x, d1y, d1z = localDirectionToWorld(node.node, node.width, 0, 0)
				local d2x, d2y, d2z = localDirectionToWorld(node.node, 0, 0, node.length)

				if VehicleDebug.state == VehicleDebug.DEBUG then
					drawDebugLine(x0, y0, z0, 1, 0, 0, x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0)
					drawDebugLine(x0, y0, z0, 0, 0, 1, x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1)
					drawDebugPoint(x0, y0, z0, 1, 1, 1, 1)
					drawDebugPoint(x0 + d1x, y0 + d1y, z0 + d1z, 1, 0, 0, 1)
					drawDebugPoint(x0 + d2x, y0 + d2y, z0 + d2z, 0, 0, 1, 1)
				end

				x0 = x0 - (d1x + d2x) / 2
				y0 = y0 - (d1y + d2y) / 2
				z0 = z0 - (d1z + d2z) / 2

				fillPlaneAdd(volume.volume, appliedDelta / numFillNodes, x0, y0, z0, d1x, d1y, d1z, d2x, d2y, d2z)

				local newX, _, newZ = localToLocal(node.node, volume.volume, 0, 0, 0)
				avgZ = avgZ + newZ
				avgX = avgX + newX
			end

			local newX = avgX / numFillNodes
			local newZ = avgZ / numFillNodes

			if FillVolume.SEND_PRECISION < math.abs(newX - spec.lastPositionInfoSent[1]) or FillVolume.SEND_PRECISION < math.abs(newZ - spec.lastPositionInfoSent[2]) then
				spec.lastPositionInfoSent[1] = newX
				spec.lastPositionInfoSent[2] = newZ

				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		else
			local x, y, z = localToWorld(volume.volume, 0, 0, 0)
			local d1x, d1y, d1z = localDirectionToWorld(volume.volume, 0.1, 0, 0)
			local d2x, d2y, d2z = localDirectionToWorld(volume.volume, 0, 0, 0.1)

			if not self.isServer and spec.lastPositionInfo[1] ~= 0 and spec.lastPositionInfo[2] ~= 0 then
				x, y, z = localToWorld(volume.volume, spec.lastPositionInfo[1], 0, spec.lastPositionInfo[2])
			end

			local steps = MathUtil.clamp(math.floor(appliedDelta / 400), 1, 25)

			for i = 1, steps do
				fillPlaneAdd(volume.volume, appliedDelta / steps, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
			end
		end

		local heightNodes = spec.fillVolumeIndexToHeightNode[volume.index]

		if heightNodes ~= nil then
			for _, heightNode in ipairs(heightNodes) do
				heightNode.isDirty = true
			end
		end

		for _, deformer in pairs(volume.deformers) do
			deformer.isDirty = true
		end

		volume.lastFillType = fillType
	end
end
