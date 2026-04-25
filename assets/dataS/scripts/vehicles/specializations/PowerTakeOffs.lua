PowerTakeOffs = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
	end
}

function PowerTakeOffs.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadOutputPowerTakeOff", PowerTakeOffs.loadOutputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadInputPowerTakeOff", PowerTakeOffs.loadInputPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadLocalPowerTakeOff", PowerTakeOffs.loadLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "placeLocalPowerTakeOff", PowerTakeOffs.placeLocalPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOff", PowerTakeOffs.updatePowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedPowerTakeOffs", PowerTakeOffs.updateAttachedPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "updatePowerTakeOffLength", PowerTakeOffs.updatePowerTakeOffLength)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffsByJointDescIndex", PowerTakeOffs.getOutputPowerTakeOffsByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getOutputPowerTakeOffs", PowerTakeOffs.getOutputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffs", PowerTakeOffs.getInputPowerTakeOffs)
	SpecializationUtil.registerFunction(vehicleType, "getInputPowerTakeOffsByJointDescIndexAndName", PowerTakeOffs.getInputPowerTakeOffsByJointDescIndexAndName)
	SpecializationUtil.registerFunction(vehicleType, "getIsPowerTakeOffActive", PowerTakeOffs.getIsPowerTakeOffActive)
	SpecializationUtil.registerFunction(vehicleType, "attachPowerTakeOff", PowerTakeOffs.attachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachPowerTakeOff", PowerTakeOffs.detachPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "parkPowerTakeOff", PowerTakeOffs.parkPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerTakeOffFromConfigFile", PowerTakeOffs.loadPowerTakeOffFromConfigFile)
	SpecializationUtil.registerFunction(vehicleType, "loadSingleJointPowerTakeOff", PowerTakeOffs.loadSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateSingleJointPowerTakeOff", PowerTakeOffs.updateSingleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadDoubleJointPowerTakeOff", PowerTakeOffs.loadDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "updateDoubleJointPowerTakeOff", PowerTakeOffs.updateDoubleJointPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "loadBasicPowerTakeOff", PowerTakeOffs.loadBasicPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "attachTypedPowerTakeOff", PowerTakeOffs.attachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "detachTypedPowerTakeOff", PowerTakeOffs.detachTypedPowerTakeOff)
	SpecializationUtil.registerFunction(vehicleType, "validatePowerTakeOffAttachment", PowerTakeOffs.validatePowerTakeOffAttachment)
end

function PowerTakeOffs.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", PowerTakeOffs.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", PowerTakeOffs.updateExtraDependentParts)
end

function PowerTakeOffs.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateInterpolation", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", PowerTakeOffs)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", PowerTakeOffs)
end

function PowerTakeOffs.initSpecialization()
	g_configurationManager:addConfigurationType("powerTakeOff", g_i18n:getText("configuration_powerTakeOff"), "powerTakeOffs", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function PowerTakeOffs:onLoad(savegame)
	local spec = self.spec_powerTakeOffs
	spec.outputPowerTakeOffs = {}
	spec.inputPowerTakeOffs = {}
	spec.localPowerTakeOffs = {}
	spec.delayedPowerTakeOffsMountings = {}
end

function PowerTakeOffs:onPostLoad(savegame)
	local spec = self.spec_powerTakeOffs
	local ptoConfigurationId = Utils.getNoNil(self.configurations.powerTakeOff, 1)
	local configKey = string.format("vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration(%d)", ptoConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.powerTakeOffs.powerTakeOffConfigurations.powerTakeOffConfiguration", ptoConfigurationId, self.components, self)

	if not hasXMLProperty(self.xmlFile, configKey) then
		configKey = "vehicle.powerTakeOffs"
	end

	if SpecializationUtil.hasSpecialization(AttacherJoints, self.specializations) then
		local i = 0

		while true do
			local baseName = string.format("%s.output(%d)", configKey, i)

			if not hasXMLProperty(self.xmlFile, baseName) then
				break
			end

			local entry = {}

			if self:loadOutputPowerTakeOff(self.xmlFile, baseName, entry) then
				table.insert(spec.outputPowerTakeOffs, entry)
			end

			i = i + 1
		end
	end

	if SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
		local i = 0

		while true do
			local baseName = string.format("%s.input(%d)", configKey, i)

			if not hasXMLProperty(self.xmlFile, baseName) then
				break
			end

			local entry = {}

			if self:loadInputPowerTakeOff(self.xmlFile, baseName, entry) then
				table.insert(spec.inputPowerTakeOffs, entry)
				self:parkPowerTakeOff(entry)
			end

			i = i + 1
		end
	end

	local i = 0

	while true do
		local baseName = string.format("%s.local(%d)", configKey, i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local entry = {}

		if self:loadLocalPowerTakeOff(self.xmlFile, baseName, entry) then
			table.insert(spec.localPowerTakeOffs, entry)
		end

		i = i + 1
	end
end

function PowerTakeOffs:onLoadFinished(savegame)
	local spec = self.spec_powerTakeOffs

	for _, powerTakeOff in ipairs(spec.localPowerTakeOffs) do
		self:placeLocalPowerTakeOff(powerTakeOff)
	end
end

function PowerTakeOffs:onDelete()
	local spec = self.spec_powerTakeOffs

	for _, output in pairs(spec.outputPowerTakeOffs) do
		if output.rootNode ~= nil then
			delete(output.rootNode)
			delete(output.attachNode)
		end
	end

	for _, input in pairs(spec.inputPowerTakeOffs) do
		if input.rootNode ~= nil then
			delete(input.rootNode)
			delete(input.attachNode)
		end

		g_animationManager:deleteAnimations(input.animationNodes)
	end

	for _, localPto in pairs(spec.localPowerTakeOffs) do
		g_animationManager:deleteAnimations(localPto.animationNodes)
	end
end

function PowerTakeOffs:onUpdateInterpolation(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_powerTakeOffs

		for _, input in pairs(spec.inputPowerTakeOffs) do
			if input.connectedVehicle ~= nil and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex then
				self:updatePowerTakeOff(input, dt)
			end
		end

		if self.getAttachedImplements ~= nil then
			for _, implement in ipairs(self:getAttachedImplements()) do
				if implement.object.updateAttachedPowerTakeOffs ~= nil then
					implement.object:updateAttachedPowerTakeOffs(dt, self)
				end
			end
		end

		local isPowerTakeOffActive = self:getIsPowerTakeOffActive()

		if spec.lastIsPowerTakeOffActive ~= isPowerTakeOffActive then
			for _, input in pairs(spec.inputPowerTakeOffs) do
				if isPowerTakeOffActive then
					g_animationManager:startAnimations(input.animationNodes)
				else
					g_animationManager:stopAnimations(input.animationNodes)
				end
			end

			for _, localPto in pairs(spec.localPowerTakeOffs) do
				if isPowerTakeOffActive then
					g_animationManager:startAnimations(localPto.animationNodes)
				else
					g_animationManager:stopAnimations(localPto.animationNodes)
				end
			end

			spec.lastIsPowerTakeOffActive = isPowerTakeOffActive
		end
	end
end

function PowerTakeOffs:loadOutputPowerTakeOff(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#linkNode", baseName .. "#outputNode")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, baseName .. "#filename", "pto file is now defined in the pto input node")

	entry.skipToInputAttacherIndex = getXMLInt(xmlFile, baseName .. "#skipToInputAttacherIndex")
	local outputNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#outputNode"), self.i3dMappings)

	if outputNode == nil and entry.skipToInputAttacherIndex == nil then
		g_logManager:xmlWarning(self.configFileName, "Pto output needs to have either a valid 'outputNode' or a 'skipToInputAttacherIndex' in '%s'", baseName)

		return false
	end

	local attacherJointIndices = {}
	local attacherJointIndicesStr = getXMLString(xmlFile, baseName .. "#attacherJointIndices")

	if attacherJointIndicesStr == nil then
		g_logManager:xmlWarning(self.configFileName, "Pto output needs to have valid 'attacherJointIndices' in '%s'", baseName)

		return false
	else
		local indices = {
			StringUtil.getVectorFromString(attacherJointIndicesStr)
		}

		for _, index in ipairs(indices) do
			if self:getAttacherJointByJointDescIndex(index) == nil then
				g_logManager:xmlWarning(self.configFileName, "The given attacherJointIndex '%d' for '%s' can't be resolved into a valid attacherJoint", index, baseName)

				return false
			else
				attacherJointIndices[index] = true
			end
		end
	end

	entry.outputNode = outputNode
	entry.attacherJointIndices = attacherJointIndices
	entry.connectedInput = nil
	entry.ptoName = getXMLString(self.xmlFile, baseName .. "#ptoName") or "DEFAULT_PTO"
	entry.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, baseName, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)

	return true
end

function PowerTakeOffs:loadInputPowerTakeOff(xmlFile, baseName, entry)
	local inputNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#inputNode"), self.i3dMappings)

	if inputNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Pto input needs to have a valid 'inputNode' in '%s'", baseName)

		return false
	end

	local inputAttacherJointIndices = {}
	local inputAttacherJointIndicesStr = getXMLString(xmlFile, baseName .. "#inputAttacherJointIndices")

	if inputAttacherJointIndicesStr == nil then
		g_logManager:xmlWarning(self.configFileName, "Pto output needs to have valid 'inputAttacherJointIndices' in '%s'", baseName)

		return false
	else
		local indices = {
			StringUtil.getVectorFromString(inputAttacherJointIndicesStr)
		}

		for _, index in ipairs(indices) do
			if self:getInputAttacherJointByJointDescIndex(index) == nil then
				g_logManager:xmlWarning(self.configFileName, "The given inputAttacherJointIndex '%d' for '%s' can't be resolved into a valid inputAttacherJoint", index, baseName)

				return false
			else
				inputAttacherJointIndices[index] = true
			end
		end
	end

	entry.inputNode = inputNode
	entry.detachNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#detachNode"), self.i3dMappings)
	entry.inputAttacherJointIndices = inputAttacherJointIndices
	entry.aboveAttacher = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#aboveAttacher"), true)
	entry.color = ConfigurationUtil.getColorFromString(getXMLString(xmlFile, baseName .. "#color"))
	local filename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#filename"), "$data/shared/assets/powerTakeOffs/walterscheidW.xml")

	if filename ~= nil then
		if not self:loadPowerTakeOffFromConfigFile(entry, filename) then
			return false
		end

		if self.addAllSubWashableNodes ~= nil and entry.startNode ~= nil then
			self:addAllSubWashableNodes(entry.startNode)
		end
	end

	entry.ptoName = getXMLString(self.xmlFile, baseName .. "#ptoName") or "DEFAULT_PTO"
	entry.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, baseName, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)

	return true
end

function PowerTakeOffs:loadLocalPowerTakeOff(xmlFile, baseName, entry)
	entry.inputNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#startNode"), self.i3dMappings)

	if entry.inputNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing startNode for local power take off '%s'", baseName)

		return false
	end

	entry.endNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#endNode"), self.i3dMappings)

	if entry.endNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing endNode for local power take off '%s'", baseName)

		return false
	end

	entry.color = ConfigurationUtil.getColorFromString(getXMLString(xmlFile, baseName .. "#color"))
	local filename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#filename"), "$data/shared/assets/powerTakeOffs/walterscheidW.xml")

	if filename ~= nil then
		if not self:loadPowerTakeOffFromConfigFile(entry, filename) then
			return false
		end

		if self.addAllSubWashableNodes ~= nil and entry.startNode ~= nil then
			self:addAllSubWashableNodes(entry.startNode)
		end
	end

	return true
end

function PowerTakeOffs:placeLocalPowerTakeOff(powerTakeOff)
	if not powerTakeOff.isPlaced then
		link(powerTakeOff.endNode, powerTakeOff.linkNode)
		setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
		setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
		self:updatePowerTakeOffLength(powerTakeOff)

		powerTakeOff.isPlaced = true
	end

	self:updatePowerTakeOff(powerTakeOff, 0)
end

function PowerTakeOffs:updatePowerTakeOff(input, dt)
	if input.updateFunc ~= nil then
		input.updateFunc(self, input, dt)
	end
end

function PowerTakeOffs:updateAttachedPowerTakeOffs(dt, attacherVehicle)
	local spec = self.spec_powerTakeOffs

	for _, input in pairs(spec.inputPowerTakeOffs) do
		if input.connectedVehicle ~= nil and input.connectedVehicle == attacherVehicle and self.updateLoopIndex == input.connectedVehicle.updateLoopIndex then
			self:updatePowerTakeOff(input, dt)
		end
	end
end

function PowerTakeOffs:updatePowerTakeOffLength(input)
	if input.updateDistanceFunc ~= nil then
		input.updateDistanceFunc(self, input)
	end
end

function PowerTakeOffs:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)
	local retOutputs = {}
	local spec = self.spec_powerTakeOffs

	for _, output in pairs(spec.outputPowerTakeOffs) do
		if output.attacherJointIndices[jointDescIndex] ~= nil then
			table.insert(retOutputs, output)
		end
	end

	if table.getn(retOutputs) > 0 then
		for _, output in ipairs(retOutputs) do
			if output.skipToInputAttacherIndex ~= nil then
				local secondAttacherVehicle = self:getAttacherVehicle()

				if secondAttacherVehicle ~= nil then
					local ownImplement = secondAttacherVehicle:getImplementByObject(self)
					retOutputs = secondAttacherVehicle:getOutputPowerTakeOffsByJointDescIndex(ownImplement.jointDescIndex)

					break
				end
			end
		end
	end

	return retOutputs
end

function PowerTakeOffs:getOutputPowerTakeOffs()
	return self.spec_powerTakeOffs.outputPowerTakeOffs
end

function PowerTakeOffs:getInputPowerTakeOffsByJointDescIndexAndName(jointDescIndex, ptoName)
	local retInputs = {}
	local spec = self.spec_powerTakeOffs

	for _, input in pairs(spec.inputPowerTakeOffs) do
		if input.inputAttacherJointIndices[jointDescIndex] ~= nil and input.ptoName == ptoName then
			table.insert(retInputs, input)
		end
	end

	if table.getn(retInputs) == 0 then
		for _, output in pairs(spec.outputPowerTakeOffs) do
			if output.skipToInputAttacherIndex == jointDescIndex then
				for index, _ in pairs(output.attacherJointIndices) do
					local implement = self:getImplementFromAttacherJointIndex(index)

					if implement ~= nil then
						retInputs = implement.object:getInputPowerTakeOffsByJointDescIndexAndName(implement.inputJointDescIndex, ptoName)
					end
				end
			end
		end
	end

	return retInputs
end

function PowerTakeOffs:getInputPowerTakeOffs()
	return self.spec_powerTakeOffs.inputPowerTakeOffs
end

function PowerTakeOffs:getIsPowerTakeOffActive()
	return false
end

function PowerTakeOffs:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_powerTakeOffs
	local outputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)

	for _, output in ipairs(outputs) do
		if attachableObject.getInputPowerTakeOffsByJointDescIndexAndName ~= nil then
			local inputs = attachableObject:getInputPowerTakeOffsByJointDescIndexAndName(inputJointDescIndex, output.ptoName)

			for _, input in ipairs(inputs) do
				output.connectedInput = input
				output.connectedVehicle = attachableObject
				input.connectedVehicle = self
				input.connectedOutput = output

				table.insert(spec.delayedPowerTakeOffsMountings, {
					jointDescIndex = jointDescIndex,
					input = input,
					output = output
				})
			end
		end
	end

	return true
end

function PowerTakeOffs:detachPowerTakeOff(detachingVehicle, implement)
	local spec = self.spec_powerTakeOffs
	spec.delayedPowerTakeOffsMountings = {}
	local outputs = detachingVehicle:getOutputPowerTakeOffsByJointDescIndex(implement.jointDescIndex)

	for _, output in ipairs(outputs) do
		if output.connectedInput ~= nil then
			local input = output.connectedInput

			if input.detachFunc ~= nil then
				input.detachFunc(self, input, output)
			end

			input.connectedVehicle = nil
			input.connectedOutput = nil
			output.connectedVehicle = nil
			output.connectedInput = nil

			ObjectChangeUtil.setObjectChanges(input.objectChanges, false)
			ObjectChangeUtil.setObjectChanges(output.objectChanges, false)
		end
	end

	return true
end

function PowerTakeOffs:parkPowerTakeOff(input)
	if input.detachNode ~= nil then
		link(input.detachNode, input.linkNode)
		link(input.inputNode, input.startNode)
		self:updatePowerTakeOff(input, 0)
		self:updatePowerTakeOffLength(input)
	else
		unlink(input.linkNode)
		unlink(input.startNode)
	end
end

function PowerTakeOffs:onPreAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex)
	self:attachPowerTakeOff(attachableObject, inputJointDescIndex, jointDescIndex)
end

function PowerTakeOffs:onPostAttachImplement(attachableObject, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_powerTakeOffs

	for i = #spec.delayedPowerTakeOffsMountings, 1, -1 do
		local delayedMounting = spec.delayedPowerTakeOffsMountings[i]

		if delayedMounting.jointDescIndex == jointDescIndex then
			local input = delayedMounting.input
			local output = delayedMounting.output

			if input.attachFunc ~= nil then
				input.attachFunc(self, input, output)
			end

			ObjectChangeUtil.setObjectChanges(input.objectChanges, true)
			ObjectChangeUtil.setObjectChanges(output.objectChanges, true)
			table.remove(spec.delayedPowerTakeOffsMountings, i)
		end
	end
end

function PowerTakeOffs:onPreDetachImplement(implement)
	self:detachPowerTakeOff(self, implement)
end

function PowerTakeOffs:loadPowerTakeOffFromConfigFile(powerTakeOff, xmlFilename)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = loadXMLFile("TempConfig", xmlFilename)

	if xmlFile ~= nil then
		local filename = getXMLString(xmlFile, "powerTakeOff#filename")

		if filename ~= nil then
			powerTakeOff.filename = filename
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				powerTakeOff.startNode = I3DUtil.indexToObject(i3dNode, getXMLString(xmlFile, "powerTakeOff.startNode#node"))
				powerTakeOff.size = Utils.getNoNil(getXMLFloat(xmlFile, "powerTakeOff#size"), 0.19)
				powerTakeOff.minLength = Utils.getNoNil(getXMLFloat(xmlFile, "powerTakeOff#minLength"), 0.6)
				powerTakeOff.maxAngle = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, "powerTakeOff#maxAngle"), 45))
				powerTakeOff.zOffset = getXMLFloat(xmlFile, "powerTakeOff#zOffset") or 0
				powerTakeOff.animationNodes = g_animationManager:loadAnimations(xmlFile, "powerTakeOff.animationNodes", i3dNode, self)

				if getXMLBool(xmlFile, "powerTakeOff#isSingleJoint") then
					self:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
				elseif getXMLBool(xmlFile, "powerTakeOff#isDoubleJoint") then
					self:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
				else
					self:loadBasicPowerTakeOff(powerTakeOff, xmlFile, i3dNode)
				end

				if powerTakeOff.color ~= nil and #powerTakeOff.color >= 3 then
					local colorShaderParameter = getXMLString(xmlFile, "powerTakeOff#colorShaderParameter")

					if colorShaderParameter ~= nil then
						local nodes = {}

						I3DUtil.getNodesByShaderParam(powerTakeOff.startNode, colorShaderParameter, nodes)

						for _, node in pairs(nodes) do
							local _, _, _, mat = getShaderParameter(node, colorShaderParameter)

							setShaderParameter(node, colorShaderParameter, powerTakeOff.color[1], powerTakeOff.color[2], powerTakeOff.color[3], mat, false)
						end
					end
				end

				link(powerTakeOff.inputNode, powerTakeOff.startNode)
				delete(i3dNode)
			else
				g_logManager:xmlWarning(self.configFileName, "Failed to find powerTakeOff in i3d file '%s'", filename, xmlFilename)

				return false
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Failed to open powerTakeOff i3d file '%s' in '%s'", filename, xmlFilename)

			return false
		end

		delete(xmlFile)

		return true
	end

	g_logManager:xmlWarning(self.configFileName, "Failed to open powerTakeOff config file '%s'", xmlFilename)

	return false
end

function PowerTakeOffs:loadSingleJointPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startJoint = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.startJoint#node"))
	powerTakeOff.scalePart = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.scalePart#node"))
	powerTakeOff.scalePartRef = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.scalePart#referenceNode"))
	local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = dis
	powerTakeOff.translationPart = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart#node"))
	powerTakeOff.translationPartRef = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart#referenceNode"))
	powerTakeOff.translationPartLength = getXMLFloat(xmlFile, "powerTakeOff.translationPart#length") or 0.4
	powerTakeOff.decal = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart.decal#node"))
	powerTakeOff.decalSize = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#size") or 0.1
	powerTakeOff.decalOffset = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#offset") or 0.05
	powerTakeOff.decalMinOffset = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#minOffset") or 0.01
	powerTakeOff.endJoint = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.endJoint#node"))
	powerTakeOff.linkNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.linkNode#node"))
	local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(betweenLength)
	powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)

	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)

	powerTakeOff.updateFunc = PowerTakeOffs.updateSingleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateSingleJointPowerTakeOff(powerTakeOff, dt)
	local x, y, z = getWorldTranslation(powerTakeOff.linkNode)
	local dx, dy, dz = worldToLocal(powerTakeOff.startNode, x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint, dx, dy, dz, 0, 1, 0)

	dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint), x, y, z)

	setTranslation(powerTakeOff.endJoint, 0, 0, MathUtil.vector3Length(dx, dy, dz))

	local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)

	setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end

function PowerTakeOffs:loadDoubleJointPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startJoint1 = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.startJoint1#node"))
	powerTakeOff.startJoint2 = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.startJoint2#node"))
	powerTakeOff.scalePart = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.scalePart#node"))
	powerTakeOff.scalePartRef = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.scalePart#referenceNode"))
	local _, _, dis = localToLocal(powerTakeOff.scalePartRef, powerTakeOff.scalePart, 0, 0, 0)
	powerTakeOff.scalePartBaseDistance = dis
	powerTakeOff.translationPart = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart#node"))
	powerTakeOff.translationPartRef = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart#referenceNode"))
	powerTakeOff.translationPartLength = getXMLFloat(xmlFile, "powerTakeOff.translationPart#length") or 0.4
	powerTakeOff.decal = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.translationPart.decal#node"))
	powerTakeOff.decalSize = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#size") or 0.1
	powerTakeOff.decalOffset = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#offset") or 0.05
	powerTakeOff.decalMinOffset = getXMLFloat(xmlFile, "powerTakeOff.translationPart.decal#minOffset") or 0.01
	powerTakeOff.endJoint1 = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.endJoint1#node"))
	powerTakeOff.endJoint1Ref = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.endJoint1#referenceNode"))
	powerTakeOff.endJoint2 = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.endJoint2#node"))
	powerTakeOff.linkNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.linkNode#node"))
	local _, _, betweenLength = localToLocal(powerTakeOff.translationPart, powerTakeOff.translationPartRef, 0, 0, 0)
	local _, _, ptoLength = localToLocal(powerTakeOff.startNode, powerTakeOff.linkNode, 0, 0, 0)
	powerTakeOff.betweenLength = math.abs(betweenLength)
	powerTakeOff.connectorLength = math.abs(ptoLength) - math.abs(betweenLength)

	setTranslation(powerTakeOff.linkNode, 0, 0, 0)
	setRotation(powerTakeOff.linkNode, 0, 0, 0)

	powerTakeOff.updateFunc = PowerTakeOffs.updateDoubleJointPowerTakeOff
	powerTakeOff.updateDistanceFunc = PowerTakeOffs.updateDistanceOfTypedPowerTakeOff
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateDoubleJointPowerTakeOff(powerTakeOff, dt)
	local x, y, z = getWorldTranslation(powerTakeOff.startNode)
	local dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint2), x, y, z)

	I3DUtil.setDirection(powerTakeOff.endJoint2, dx * 0.5, dy * 0.5, dz, 0, 1, 0)

	x, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
	dx, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint1), x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint1, dx * 0.5, dy * 0.5, dz, 0, 1, 0)

	x, y, z = getWorldTranslation(powerTakeOff.endJoint1Ref)
	dx, dy, dz = worldToLocal(getParent(powerTakeOff.startJoint2), x, y, z)

	I3DUtil.setDirection(powerTakeOff.startJoint2, dx, dy, dz, 0, 1, 0)

	dx, dy, dz = worldToLocal(getParent(powerTakeOff.endJoint1), x, y, z)

	setTranslation(powerTakeOff.endJoint1, 0, 0, MathUtil.vector3Length(dx, dy, dz))

	local dist = calcDistanceFrom(powerTakeOff.scalePart, powerTakeOff.scalePartRef)

	setScale(powerTakeOff.scalePart, 1, 1, dist / powerTakeOff.scalePartBaseDistance)
end

function PowerTakeOffs:loadBasicPowerTakeOff(powerTakeOff, xmlFile, rootNode)
	powerTakeOff.startNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.startNode#node"))
	powerTakeOff.linkNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "powerTakeOff.linkNode#node"))
	powerTakeOff.attachFunc = PowerTakeOffs.attachTypedPowerTakeOff
	powerTakeOff.detachFunc = PowerTakeOffs.detachTypedPowerTakeOff
end

function PowerTakeOffs:updateDistanceOfTypedPowerTakeOff(powerTakeOff)
	local attachLength = calcDistanceFrom(powerTakeOff.linkNode, powerTakeOff.startNode)
	local transPartScale = math.max(attachLength - powerTakeOff.connectorLength, 0) / powerTakeOff.betweenLength

	setScale(powerTakeOff.translationPart, 1, 1, transPartScale)

	if powerTakeOff.decal ~= nil then
		local transPartLength = transPartScale * powerTakeOff.translationPartLength

		if transPartLength > powerTakeOff.decalMinOffset * 2 + powerTakeOff.decalSize then
			local offset = math.min((transPartLength - powerTakeOff.decalSize) / 2, powerTakeOff.decalOffset)
			local decalTranslation = offset + powerTakeOff.decalSize * 0.5
			local x, y, _ = getTranslation(powerTakeOff.decal)

			setTranslation(powerTakeOff.decal, x, y, -decalTranslation / transPartScale)
			setScale(powerTakeOff.decal, 1, 1, 1 / transPartScale)
		else
			setVisibility(powerTakeOff.decal, false)
		end
	end
end

function PowerTakeOffs:attachTypedPowerTakeOff(powerTakeOff, output)
	if self:validatePowerTakeOffAttachment(powerTakeOff, output) then
		link(output.outputNode, powerTakeOff.linkNode)
		link(powerTakeOff.inputNode, powerTakeOff.startNode)
		setTranslation(powerTakeOff.linkNode, 0, 0, powerTakeOff.zOffset)
		setTranslation(powerTakeOff.startNode, 0, 0, -powerTakeOff.zOffset)
		self:updatePowerTakeOff(powerTakeOff, 0)
		self:updatePowerTakeOffLength(powerTakeOff)
	end
end

function PowerTakeOffs:detachTypedPowerTakeOff(powerTakeOff, output)
	self:parkPowerTakeOff(powerTakeOff)
end

function PowerTakeOffs:validatePowerTakeOffAttachment(powerTakeOff, output)
	if output.outputNode == nil or powerTakeOff.inputNode == nil then
		return false
	end

	local x1, y1, z1 = getWorldTranslation(output.outputNode)
	local x2, y2, z2 = getWorldTranslation(powerTakeOff.inputNode)
	local length = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

	if length < powerTakeOff.minLength then
		return false
	end

	local length2D = MathUtil.vector2Length(x1 - x2, z1 - z2)
	local angle = math.acos(length2D / length)

	if powerTakeOff.maxAngle < angle then
		return false
	end

	return true
end

function PowerTakeOffs:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	local indices = StringUtil.getVectorNFromString(getXMLString(xmlFile, baseName .. ".powerTakeOffs#indices"))

	if indices ~= nil then
		entry.powerTakeOffs = {}

		for i = 1, table.getn(indices) do
			table.insert(entry.powerTakeOffs, indices[i])
		end
	end

	local localIndices = StringUtil.getVectorNFromString(getXMLString(xmlFile, baseName .. ".powerTakeOffs#localIndices"))

	if localIndices ~= nil then
		entry.localPowerTakeOffs = {}

		for i = 1, table.getn(localIndices) do
			table.insert(entry.localPowerTakeOffs, localIndices[i])
		end
	end

	return true
end

function PowerTakeOffs:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if part.powerTakeOffs ~= nil then
		local spec = self.spec_powerTakeOffs

		for i, index in ipairs(part.powerTakeOffs) do
			if spec.inputPowerTakeOffs[index] == nil then
				part.powerTakeOffs[i] = nil

				g_logManager:xmlWarning(self.configFileName, "Unable to find powerTakeOff index '%d' for movingPart/movingTool '%s'", index, getName(part.node))
			else
				self:updatePowerTakeOff(spec.inputPowerTakeOffs[index], dt)
			end
		end
	end

	if part.localPowerTakeOffs ~= nil then
		local spec = self.spec_powerTakeOffs

		for i, index in ipairs(part.localPowerTakeOffs) do
			if spec.localPowerTakeOffs[index] == nil then
				part.localPowerTakeOffs[i] = nil

				g_logManager:xmlWarning(self.configFileName, "Unable to find local powerTakeOff index '%d' for movingPart/movingTool '%s'", index, getName(part.node))
			else
				self:placeLocalPowerTakeOff(spec.localPowerTakeOffs[index], dt)
			end
		end
	end
end
