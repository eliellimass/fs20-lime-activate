source("dataS/scripts/vehicles/specializations/events/TensionBeltsEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TensionBeltsRefreshEvent.lua")

TensionBelts = {
	debugRendering = false,
	NUM_SEND_BITS = 4,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function TensionBelts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "createTensionBelt", TensionBelts.createTensionBelt)
	SpecializationUtil.registerFunction(vehicleType, "removeTensionBelt", TensionBelts.removeTensionBelt)
	SpecializationUtil.registerFunction(vehicleType, "setTensionBeltsActive", TensionBelts.setTensionBeltsActive)
	SpecializationUtil.registerFunction(vehicleType, "setAllTensionBeltsActive", TensionBelts.setAllTensionBeltsActive)
	SpecializationUtil.registerFunction(vehicleType, "objectOverlapCallback", TensionBelts.objectOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "getObjectToMount", TensionBelts.getObjectToMount)
	SpecializationUtil.registerFunction(vehicleType, "getObjectsToUnmount", TensionBelts.getObjectsToUnmount)
	SpecializationUtil.registerFunction(vehicleType, "updateFastenState", TensionBelts.updateFastenState)
	SpecializationUtil.registerFunction(vehicleType, "refreshTensionBelts", TensionBelts.refreshTensionBelts)
	SpecializationUtil.registerFunction(vehicleType, "freeTensionBeltObject", TensionBelts.freeTensionBeltObject)
	SpecializationUtil.registerFunction(vehicleType, "lockTensionBeltObject", TensionBelts.lockTensionBeltObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInTensionBeltsRange", TensionBelts.getIsPlayerInTensionBeltsRange)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicallyMountedNode", TensionBelts.getIsDynamicallyMountedNode)
	SpecializationUtil.registerFunction(vehicleType, "tensionBeltActivationTriggerCallback", TensionBelts.tensionBeltActivationTriggerCallback)
end

function TensionBelts.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", TensionBelts.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TensionBelts.getCanBeSelected)
end

function TensionBelts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TensionBelts)
end

function TensionBelts.initSpecialization()
	g_configurationManager:addConfigurationType("tensionBelts", g_i18n:getText("configuration_tensionBelts"), "tensionBelts", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
end

function TensionBelts:onLoad(savegame)
	local spec = self.spec_tensionBelts
	local tensionBeltConfigurationId = Utils.getNoNil(self.configurations.tensionBelts, 1)
	local configKey = string.format("vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(%d).tensionBelts", tensionBeltConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration", tensionBeltConfigurationId, self.components, self)

	spec.hasTensionBelts = true

	if not hasXMLProperty(self.xmlFile, configKey) then
		spec.hasTensionBelts = false

		return
	end

	spec.belts = {}
	spec.tensionBelts = {}
	spec.singleBelts = {}
	spec.sortedBelts = {}
	spec.activatable = TensionBeltsActivatable:new(self)
	spec.totalInteractionRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#totalInteractionRadius"), 6)
	spec.interactionRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#interactionRadius"), 1)
	spec.interactionBaseNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, configKey .. "#interactionBaseNode"), self.i3dMappings), self.rootNode)
	spec.activationTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, configKey .. "#activationTrigger"), self.i3dMappings)

	if spec.activationTrigger ~= nil then
		addTrigger(spec.activationTrigger, "tensionBeltActivationTriggerCallback", self)
	end

	spec.isPlayerInTrigger = false
	spec.checkSizeOffsets = {
		0,
		2.5,
		1.5
	}
	spec.numObjectsIntensionBeltRange = 0
	local tensionBeltType = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#tensionBeltType"), "basic")
	local beltData = g_tensionBeltManager:getBeltData(tensionBeltType)

	if beltData ~= nil then
		spec.width = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#width"), 0.15)
		spec.ratchetPosition = getXMLFloat(self.xmlFile, configKey .. "#ratchetPosition")
		spec.useHooks = Utils.getNoNil(getXMLBool(self.xmlFile, configKey .. "#useHooks"), true)
		spec.maxEdgeLength = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#maxEdgeLength"), 0.1)
		spec.geometryBias = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#geometryBias"), 0.01)
		spec.defaultOffsetSide = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#defaultOffsetSide"), 0.1)
		spec.defaultOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#defaultOffset"), 0)
		spec.defaultHeight = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#defaultHeight"), 5)
		spec.beltData = beltData
		spec.linkNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, configKey .. "#linkNode"), self.i3dMappings)
		spec.rootNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, configKey .. "#rootNode"), self.i3dMappings), self.components[1].node)
		spec.jointNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, configKey .. "#jointNode"), self.i3dMappings), spec.rootNode)
		spec.checkTimerDuration = 500
		spec.checkTimer = spec.checkTimerDuration

		if getRigidBodyType(spec.jointNode) ~= "Dynamic" and getRigidBodyType(spec.jointNode) ~= "Kinematic" then
			print("Error: Given jointNode '" .. getName(spec.jointNode) .. "' has invalid rigidBodyType. Have to be 'Dynamic' or 'Kinematic'! Using '" .. getName(self.components[1].node) .. "' instead!")

			spec.jointNode = self.components[1].node
		end

		local rigidBodyType = getRigidBodyType(spec.jointNode)
		spec.isDynamic = rigidBodyType == "Dynamic"
		local x, y, z = localToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
		local rx, ry, rz = localRotationToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
		spec.linkNodePosition = {
			x,
			y,
			z
		}
		spec.linkNodeRotation = {
			rx,
			ry,
			rz
		}
		local i = 0

		while true do
			local key = string.format(configKey .. ".tensionBelt(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			if #spec.sortedBelts == 2^TensionBelts.NUM_SEND_BITS then
				print("Warning: Max number of tension belts is " .. 2^TensionBelts.NUM_SEND_BITS .. "!")

				break
			end

			local startNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#startNode"), self.i3dMappings)
			local endNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#endNode"), self.i3dMappings)

			if startNode ~= nil and endNode ~= nil then
				local x, y, _ = localToLocal(endNode, startNode, 0, 0, 0)

				if math.abs(x) < 0.0001 and math.abs(y) < 0.0001 then
					if spec.linkNode == nil then
						spec.linkNode = getParent(startNode)
					end

					if spec.startNode == nil then
						spec.startNode = startNode
					end

					spec.endNode = endNode
					local offsetLeft = getXMLFloat(self.xmlFile, key .. "#offsetLeft")
					local offsetRight = getXMLFloat(self.xmlFile, key .. "#offsetRight")
					local offset = getXMLFloat(self.xmlFile, key .. "#offset")
					local height = getXMLFloat(self.xmlFile, key .. "#height")
					local intersectionNodes = {}
					local j = 0

					while true do
						local intersectionKey = string.format(key .. ".intersectionNode(%d)", j)

						if not hasXMLProperty(self.xmlFile, intersectionKey) then
							break
						end

						local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, intersectionKey .. "#node"), self.i3dMappings)

						if node ~= nil then
							table.insert(intersectionNodes, node)
						end

						j = j + 1
					end

					local belt = {
						id = i + 1,
						startNode = startNode,
						endNode = endNode,
						offsetLeft = offsetLeft,
						offsetRight = offsetRight,
						offset = offset,
						height = height,
						intersectionNodes = intersectionNodes
					}
					spec.singleBelts[belt] = belt

					table.insert(spec.sortedBelts, belt)
				else
					print("Warning: x and y position of endNode need to be 0 for tension belt '" .. key .. "' in '" .. self.configFileName .. "'!")
				end
			end

			i = i + 1
		end

		local minX = math.huge
		local minZ = math.huge
		local maxX = -math.huge
		local maxZ = -math.huge

		for _, belt in pairs(spec.singleBelts) do
			local sx, _, sz = localToLocal(belt.startNode, spec.interactionBaseNode, 0, 0, 0)
			local ex, _, ez = localToLocal(belt.endNode, spec.interactionBaseNode, 0, 0, 0)
			minX = math.min(minX, sx, ex)
			minZ = math.min(minZ, sz, ez)
			maxX = math.max(maxX, sx, ex)
			maxZ = math.max(maxZ, sz, ez)
		end

		spec.interactionBasePointX = (maxX + minX) / 2
		spec.interactionBasePointZ = (maxZ + minZ) / 2

		for _, belt in pairs(spec.singleBelts) do
			local sx, _, sz = localToLocal(belt.startNode, spec.interactionBaseNode, 0, 0, 0)
			local sl = MathUtil.vector2Length(spec.interactionBasePointX - sx, spec.interactionBasePointZ - sz) + 1
			local el = MathUtil.vector2Length(spec.interactionBasePointX - sx, spec.interactionBasePointZ - sz) + 1
			spec.totalInteractionRadius = math.max(spec.totalInteractionRadius, sl, el)
		end

		spec.hasTensionBelts = #spec.sortedBelts > 0
	else
		print("Warning: No belt data found for tension belts in '" .. self.configFileName .. "'!")
	end

	spec.checkBoxes = {}
	spec.objectsToJoint = {}
	spec.isPlayerInRange = false
	spec.currentBelt = nil
	spec.areBeltsFasten = false
end

function TensionBelts:onPostLoad(savegame)
	if savegame ~= nil then
		local spec = self.spec_tensionBelts
		spec.beltsToLoad = {}
		local i = 0

		while true do
			local key = string.format("%s.tensionBelts.belt(%d)", savegame.key, i)

			if not hasXMLProperty(savegame.xmlFile, key) then
				break
			end

			if getXMLBool(savegame.xmlFile, key .. "#isActive") then
				table.insert(spec.beltsToLoad, i + 1)
			end

			i = i + 1
		end
	end
end

function TensionBelts:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_tensionBelts

	if spec.hasTensionBelts then
		for i, belt in ipairs(spec.sortedBelts) do
			local beltKey = string.format("%s.belt(%d)", key, i - 1)

			setXMLBool(xmlFile, beltKey .. "#isActive", belt.mesh ~= nil)
		end
	end
end

function TensionBelts:onPreDelete()
	if self.spec_tensionBelts.sortedBelts ~= nil then
		for _, belt in pairs(self.spec_tensionBelts.sortedBelts) do
			local objects, _ = self:getObjectToMount(belt)

			for id, _ in pairs(objects) do
				I3DUtil.wakeUpObject(id)
			end
		end
	end
end

function TensionBelts:onDelete()
	local spec = self.spec_tensionBelts
	spec.isPlayerInRange = false

	g_currentMission:removeActivatableObject(spec.activatable)
	self:setTensionBeltsActive(false, nil, true)

	if spec.activationTrigger ~= nil then
		removeTrigger(spec.activationTrigger)

		spec.activationTrigger = nil
	end
end

function TensionBelts:onReadStream(streamId, connection)
	local spec = self.spec_tensionBelts

	if not spec.hasTensionBelts then
		return
	end

	if spec.tensionBelts ~= nil then
		spec.beltsToLoad = {}

		for k, _ in ipairs(spec.sortedBelts) do
			local beltActive = streamReadBool(streamId)

			if beltActive then
				table.insert(spec.beltsToLoad, k)
			end
		end
	end
end

function TensionBelts:onWriteStream(streamId, connection)
	local spec = self.spec_tensionBelts

	if not spec.hasTensionBelts then
		return
	end

	if spec.tensionBelts ~= nil then
		for _, belt in ipairs(spec.sortedBelts) do
			streamWriteBool(streamId, belt.mesh ~= nil)
		end
	end
end

function TensionBelts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_tensionBelts

	if not spec.hasTensionBelts then
		return
	end

	if spec.beltsToLoad ~= nil then
		for _, k in pairs(spec.beltsToLoad) do
			local noEventSend = false

			if not self.isServer then
				noEventSend = true
			end

			self:setTensionBeltsActive(true, spec.sortedBelts[k].id, noEventSend)
		end

		spec.beltsToLoad = nil
	end

	if self.isServer and spec.isDynamic then
		local x, y, z = localToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
		local rx, ry, rz = localRotationToLocal(spec.linkNode, spec.jointNode, 0, 0, 0)
		local isDirty = false

		if math.abs(x - spec.linkNodePosition[1]) > 0.001 or math.abs(y - spec.linkNodePosition[2]) > 0.001 or math.abs(z - spec.linkNodePosition[3]) > 0.001 or math.abs(rx - spec.linkNodeRotation[1]) > 0.001 or math.abs(ry - spec.linkNodeRotation[2]) > 0.001 or math.abs(rz - spec.linkNodeRotation[3]) > 0.001 then
			isDirty = true
		end

		if isDirty then
			spec.linkNodePosition[3] = z
			spec.linkNodePosition[2] = y
			spec.linkNodePosition[1] = x
			spec.linkNodeRotation[3] = rz
			spec.linkNodeRotation[2] = ry
			spec.linkNodeRotation[1] = rx

			for _, joint in pairs(spec.objectsToJoint) do
				setJointFrame(joint.jointIndex, 0, joint.jointTransform)
			end
		end
	end

	if TensionBelts.debugRendering then
		for belt, _ in pairs(spec.belts) do
			DebugUtil.drawDebugNode(belt)

			for i = 0, getNumOfChildren(belt) - 1 do
				DebugUtil.drawDebugNode(getChildAt(belt, i))
			end
		end

		if spec.checkBoxes ~= nil then
			for _, box in pairs(spec.checkBoxes) do
				local p = box.points
				local c = box.color

				drawDebugLine(p[1][1], p[1][2], p[1][3], c[1], c[2], c[3], p[2][1], p[2][2], p[2][3], c[1], c[2], c[3])
				drawDebugLine(p[2][1], p[2][2], p[2][3], c[1], c[2], c[3], p[3][1], p[3][2], p[3][3], c[1], c[2], c[3])
				drawDebugLine(p[3][1], p[3][2], p[3][3], c[1], c[2], c[3], p[4][1], p[4][2], p[4][3], c[1], c[2], c[3])
				drawDebugLine(p[4][1], p[4][2], p[4][3], c[1], c[2], c[3], p[1][1], p[1][2], p[1][3], c[1], c[2], c[3])
				drawDebugLine(p[5][1], p[5][2], p[5][3], c[1], c[2], c[3], p[6][1], p[6][2], p[6][3], c[1], c[2], c[3])
				drawDebugLine(p[6][1], p[6][2], p[6][3], c[1], c[2], c[3], p[7][1], p[7][2], p[7][3], c[1], c[2], c[3])
				drawDebugLine(p[7][1], p[7][2], p[7][3], c[1], c[2], c[3], p[8][1], p[8][2], p[8][3], c[1], c[2], c[3])
				drawDebugLine(p[8][1], p[8][2], p[8][3], c[1], c[2], c[3], p[5][1], p[5][2], p[5][3], c[1], c[2], c[3])
				drawDebugLine(p[1][1], p[1][2], p[1][3], c[1], c[2], c[3], p[5][1], p[5][2], p[5][3], c[1], c[2], c[3])
				drawDebugLine(p[4][1], p[4][2], p[4][3], c[1], c[2], c[3], p[8][1], p[8][2], p[8][3], c[1], c[2], c[3])
				drawDebugLine(p[2][1], p[2][2], p[2][3], c[1], c[2], c[3], p[6][1], p[6][2], p[6][3], c[1], c[2], c[3])
				drawDebugLine(p[3][1], p[3][2], p[3][3], c[1], c[2], c[3], p[7][1], p[7][2], p[7][3], c[1], c[2], c[3])
				drawDebugPoint(p[9][1], p[9][2], p[9][3], 1, 1, 1, 1)
			end
		end

		local a, b, c = localToWorld(spec.interactionBaseNode, spec.interactionBasePointX, 0, spec.interactionBasePointZ)

		drawDebugPoint(a, b, c, 0, 0, 1, 1, 1, 1, 1)

		for i = 0, 350, 10 do
			local x, y, z = localToWorld(spec.interactionBaseNode, spec.interactionBasePointX + math.cos(math.rad(i)) * spec.totalInteractionRadius, 0, spec.interactionBasePointZ + math.sin(math.rad(i)) * spec.totalInteractionRadius)

			drawDebugPoint(x, y, z, 1, 1, 1, 1)

			for _, belt in pairs(spec.singleBelts) do
				local x, y, z = localToWorld(belt.startNode, math.cos(math.rad(i)) * spec.interactionRadius, 0, math.sin(math.rad(i)) * spec.interactionRadius)

				drawDebugPoint(x, y, z, 0, 1, 0, 1)

				local x, y, z = localToWorld(belt.endNode, math.cos(math.rad(i)) * spec.interactionRadius, 0, math.sin(math.rad(i)) * spec.interactionRadius)

				drawDebugPoint(x, y, z, 1, 0, 0, 1)
			end
		end
	end

	if spec.isPlayerInTrigger or spec.isPlayerInRange then
		self:raiseActive()
	end

	local currentBelt = nil
	local wasInRange = spec.isPlayerInRange
	spec.isPlayerInRange, currentBelt = self:getIsPlayerInTensionBeltsRange()

	if spec.isPlayerInRange then
		if currentBelt ~= spec.currentBelt then
			if spec.currentBelt ~= nil and spec.currentBelt.dummy ~= nil then
				delete(spec.currentBelt.dummy)

				spec.currentBelt.dummy = nil
			end

			spec.currentBelt = currentBelt

			if spec.currentBelt ~= nil and spec.currentBelt.mesh == nil then
				local objects, _ = self:getObjectToMount(spec.currentBelt)

				self:createTensionBelt(spec.currentBelt, true, objects)
			end
		end

		g_currentMission:addActivatableObject(spec.activatable)
	elseif wasInRange then
		g_currentMission:removeActivatableObject(spec.activatable)

		if spec.currentBelt ~= nil and spec.currentBelt.dummy ~= nil then
			delete(spec.currentBelt.dummy)

			spec.currentBelt.dummy = nil
			spec.currentBelt = nil
		end
	end
end

function TensionBelts:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_tensionBelts

	if not spec.hasTensionBelts then
		return
	end

	if self.isServer and spec.tensionBelts ~= nil then
		spec.checkTimer = spec.checkTimer - dt

		if spec.checkTimer < 0 then
			local needUpdate = false

			for phyiscObject, _ in pairs(spec.objectsToJoint) do
				if not entityExists(phyiscObject) then
					spec.objectsToJoint[phyiscObject] = nil
					needUpdate = true

					break
				end
			end

			if needUpdate then
				self:refreshTensionBelts()
			end

			spec.checkTimer = spec.checkTimerDuration
		end
	end
end

function TensionBelts:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_tensionBelts

	if not spec.hasTensionBelts then
		return
	end

	if isActiveForInputIgnoreSelection and isSelected then
		if spec.areBeltsFasten then
			g_currentMission:addHelpButtonText(g_i18n:getText("action_unfastenTensionBelts"), InputBinding.TOGGLE_TENSION_BELTS, nil, GS_PRIO_NORMAL)
		else
			g_currentMission:addHelpButtonText(g_i18n:getText("action_fastenTensionBelts"), InputBinding.TOGGLE_TENSION_BELTS, nil, GS_PRIO_NORMAL)
		end
	end
end

function TensionBelts:refreshTensionBelts()
	if self.isServer and g_server ~= nil then
		g_server:broadcastEvent(TensionBeltsRefreshEvent:new(self), nil, , self)
	end

	for _, belt in pairs(self.spec_tensionBelts.sortedBelts) do
		if belt.mesh ~= nil then
			self:removeTensionBelt(belt)

			local objects, _ = self:getObjectToMount(belt)

			self:createTensionBelt(belt, false, objects)
		end
	end
end

function TensionBelts:freeTensionBeltObject(objectId, objectsToJointTable, isDynamic)
	if entityExists(objectId) then
		local jointData = objectsToJointTable[objectId]

		if isDynamic then
			if jointData ~= nil then
				removeJoint(jointData.jointIndex)
				delete(jointData.jointTransform)
			end

			for obj, _ in pairs(objectsToJointTable) do
				if obj ~= objectId then
					setPairCollision(objectId, obj, true)
				end
			end
		else
			local parentNode = nil

			if jointData ~= nil then
				parentNode = jointData.parent
			end

			if parentNode ~= nil and not entityExists(parentNode) then
				delete(objectId)
			else
				if parentNode == nil then
					parentNode = getRootNode()
				end

				local x, y, z = getWorldTranslation(objectId)
				local a, b, c = getWorldRotation(objectId)

				link(parentNode, objectId)
				setWorldTranslation(objectId, x, y, z)
				setWorldRotation(objectId, a, b, c)
				setRigidBodyType(objectId, "Dynamic")
			end
		end
	end

	objectsToJointTable[objectId] = nil
end

function TensionBelts:lockTensionBeltObject(objectId, objectsToJointTable, isDynamic, jointNode, object)
	if objectsToJointTable[objectId] == nil then
		if isDynamic then
			local constr = JointConstructor:new()

			constr:setActors(jointNode, objectId)

			local jointTransform = createTransformGroup("tensionBeltJoint")

			link(self.spec_tensionBelts.linkNode, jointTransform)

			local x, y, z = localToWorld(objectId, getCenterOfMass(objectId))

			setWorldTranslation(jointTransform, x, y, z)

			local rx, ry, rz = getWorldRotation(objectId)

			setWorldRotation(jointTransform, rx, ry, rz)
			constr:setJointTransforms(jointTransform, jointTransform)
			constr:setRotationLimit(0, 0, 0)
			constr:setRotationLimit(1, 0, 0)
			constr:setRotationLimit(2, 0, 0)

			local springForce = 7500
			local springDamping = 1500

			constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
			constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

			local jointIndex = constr:finalize()
			objectsToJointTable[objectId] = {
				jointIndex = jointIndex,
				jointTransform = jointTransform
			}
		else
			local parentNode = getParent(objectId)
			local x, y, z = localToLocal(objectId, jointNode, 0, 0, 0)
			local a, b, c = localRotationToLocal(objectId, jointNode, 0, 0, 0)

			setRigidBodyType(objectId, "Kinematic")
			link(jointNode, objectId)
			setTranslation(objectId, x, y, z)
			setRotation(objectId, a, b, c)

			objectsToJointTable[objectId] = {
				parent = parentNode
			}

			if object ~= nil and object.components ~= nil then
				for _, component in ipairs(object.components) do
					if component.node == objectId then
						component.isKinematic = true
						component.isDynamic = false
					end
				end
			end
		end
	end
end

function TensionBelts:setTensionBeltsActive(isActive, beltId, noEventSend)
	local spec = self.spec_tensionBelts

	if spec.tensionBelts ~= nil then
		TensionBeltsEvent.sendEvent(self, isActive, beltId, noEventSend)

		local belt = nil

		if beltId ~= nil then
			belt = spec.sortedBelts[beltId]
		end

		if isActive then
			local objects, _ = self:getObjectToMount(belt)

			if belt == nil then
				for _, belt in pairs(spec.singleBelts) do
					if belt.mesh == nil then
						self:createTensionBelt(belt, false, objects)
					end
				end
			elseif belt.mesh == nil then
				self:createTensionBelt(belt, false, objects)
			end

			if self.isServer then
				for _, data in pairs(objects) do
					self:lockTensionBeltObject(data.physics, spec.objectsToJoint, spec.isDynamic, spec.jointNode, data.object)

					if data.object ~= nil then
						data.object.tensionMountObject = self
					end
				end
			else
				for _, data in pairs(objects) do
					if data.object ~= nil then
						data.object.tensionMountObject = self
					end
				end
			end
		else
			if belt == nil then
				for _, belt in pairs(spec.singleBelts) do
					self:removeTensionBelt(belt)
				end
			else
				self:removeTensionBelt(belt)
			end

			if self.isServer then
				local objectIds, _ = self:getObjectsToUnmount(belt)

				for _, objectId in pairs(objectIds) do
					self:freeTensionBeltObject(objectId, spec.objectsToJoint, spec.isDynamic)
				end
			end

			local objects, _ = self:getObjectToMount(belt)

			for _, data in pairs(objects) do
				if data.object ~= nil then
					data.object.tensionMountObject = nil

					if self.isServer and data.object.components ~= nil then
						for _, component in ipairs(data.object.components) do
							if component.node == data.physics then
								component.isKinematic = false
								component.isDynamic = true
							end
						end
					end
				end
			end
		end

		self:updateFastenState()
	end
end

function TensionBelts:setAllTensionBeltsActive(isActive, noEventSend)
	local spec = self.spec_tensionBelts

	if spec.hasTensionBelts then
		isActive = Utils.getNoNil(isActive, not spec.areBeltsFasten)

		for _, belt in pairs(spec.sortedBelts) do
			self:setTensionBeltsActive(isActive, belt.id, noEventSend)
		end
	end
end

function TensionBelts:updateFastenState()
	local spec = self.spec_tensionBelts
	local unfastenBelts = false

	for _, belt in pairs(spec.singleBelts) do
		if belt.mesh == nil then
			unfastenBelts = true

			break
		end
	end

	spec.areBeltsFasten = not unfastenBelts
end

function TensionBelts:createTensionBelt(belt, isDummy, objects)
	local spec = self.spec_tensionBelts
	local tensionBelt = TensionBeltGeometryConstructor:new()
	local beltData = spec.beltData

	tensionBelt:setWidth(spec.width)
	tensionBelt:setMaxEdgeLength(spec.maxEdgeLength)

	if isDummy then
		tensionBelt:setMaterial(beltData.dummyMaterial.materialId)
		tensionBelt:setUVscale(beltData.dummyMaterial.uvScale)
	else
		tensionBelt:setMaterial(beltData.material.materialId)
		tensionBelt:setUVscale(beltData.material.uvScale)
	end

	if spec.ratchetPosition ~= nil and beltData.ratchet ~= nil then
		tensionBelt:addAttachment(0, spec.ratchetPosition, beltData.ratchet.sizeRatio * spec.width)
	end

	if spec.useHooks and beltData.hook ~= nil then
		tensionBelt:addAttachment(0, 0, beltData.hook.sizeRatio * spec.width)
		tensionBelt:addAttachment(1, 0, beltData.hook.sizeRatio * spec.width)
	end

	tensionBelt:setFixedPoints(belt.startNode, belt.endNode)
	tensionBelt:setGeometryBias(spec.geometryBias)
	tensionBelt:setLinkNode(spec.linkNode)

	for _, pointNode in pairs(belt.intersectionNodes) do
		local x, y, z = getWorldTranslation(pointNode)
		local dirX, dirY, dirZ = localDirectionToWorld(pointNode, 1, 0, 0)

		tensionBelt:addIntersectionPoint(x, y, z, dirX, dirY, dirZ)
	end

	for _, object in pairs(objects) do
		for _, node in pairs(object.visuals) do
			if getSplitType(node) ~= 0 then
				tensionBelt:addShape(node, -100, 100, -100, 100)
			else
				tensionBelt:addShape(node, 0, 1, 0, 1)
			end
		end
	end

	local beltShape, _, beltLength = tensionBelt:finalize()

	if beltShape ~= 0 then
		if isDummy then
			belt.dummy = beltShape
		else
			local currentIndex = 0

			if spec.ratchetPosition ~= nil and beltData.ratchet ~= nil and currentIndex < getNumOfChildren(beltShape) then
				local scale = spec.width
				local ratched = clone(beltData.ratchet.node, false, false, false)

				link(getChildAt(beltShape, 0), ratched)
				setScale(ratched, scale, scale, scale)

				currentIndex = currentIndex + 1
			end

			if spec.useHooks and beltData.hook ~= nil and getNumOfChildren(beltShape) > currentIndex + 1 then
				local scale = spec.width
				local hookStart = clone(beltData.hook.node, false, false, false)

				link(getChildAt(beltShape, currentIndex), hookStart)
				setScale(hookStart, scale, scale, scale)

				local hookEnd = clone(beltData.hook.node, false, false, false)

				link(getChildAt(beltShape, currentIndex + 1), hookEnd)
				setRotation(hookEnd, 0, math.pi, 0)
				setTranslation(hookEnd, 0, 0, beltData.hook.sizeRatio * spec.width)
				setScale(hookEnd, scale, scale, scale)

				currentIndex = currentIndex + 2

				setShaderParameter(beltShape, "beltClipOffsets", 0, beltData.hook.sizeRatio * spec.width, beltLength - beltData.hook.sizeRatio * spec.width, beltLength, false)
			end

			belt.mesh = beltShape
			spec.belts[beltShape] = beltShape

			if belt.dummy ~= nil then
				delete(belt.dummy)

				belt.dummy = nil
			end
		end

		return beltShape
	end

	return nil
end

function TensionBelts:removeTensionBelt(belt)
	if belt.mesh ~= nil then
		local spec = self.spec_tensionBelts
		spec.belts[belt.mesh] = nil

		delete(belt.mesh)

		belt.mesh = nil

		if spec.currentBelt == belt then
			spec.currentBelt = nil
		end
	end
end

function TensionBelts:getObjectToMount(belt)
	local spec = self.spec_tensionBelts
	local markerStart = spec.startNode
	local markerEnd = spec.endNode
	local offsetLeft, offsetRight, offset, height = nil

	if belt ~= nil then
		markerStart = belt.startNode
		markerEnd = belt.endNode
		offsetLeft = belt.offsetLeft
		offsetRight = belt.offsetRight
		offset = belt.offset
		height = belt.height

		if offsetLeft == nil and spec.sortedBelts[belt.id - 1] ~= nil and spec.sortedBelts[belt.id - 1].mesh ~= nil then
			local x, _, _ = localToLocal(markerStart, spec.sortedBelts[belt.id - 1].startNode, 0, 0, 0)
			offsetLeft = math.abs(x)
		end

		if offsetRight == nil and spec.sortedBelts[belt.id + 1] ~= nil and spec.sortedBelts[belt.id + 1].mesh ~= nil then
			local x, _, _ = localToLocal(markerStart, spec.sortedBelts[belt.id + 1].startNode, 0, 0, 0)
			offsetRight = math.abs(x)
		end
	end

	if offsetLeft == nil then
		offsetLeft = spec.defaultOffsetSide
	end

	if offsetRight == nil then
		offsetRight = spec.defaultOffsetSide
	end

	if offset == nil then
		offset = spec.defaultOffset
	end

	if height == nil then
		height = spec.defaultHeight
	end

	local sizeX = (offsetLeft + offsetRight) * 0.5
	local sizeY = height * 0.5
	local _, _, width = localToLocal(markerEnd, markerStart, 0, 0, 0)
	local sizeZ = width * 0.5 - 2 * offset
	local centerX = (offsetLeft - offsetRight) * 0.5
	local centerY = height * 0.5
	local centerZ = width * 0.5
	local x, y, z = localToWorld(markerStart, centerX, centerY, centerZ)

	if TensionBelts.debugRendering then
		local box = {
			points = {}
		}
		local colorR = math.random(0, 1)
		local colorG = math.random(0, 1)
		local colorB = math.random(0, 1)
		box.color = {
			colorR,
			colorG,
			colorB
		}
		local blx, bly, blz = localToWorld(markerStart, centerX - sizeX, centerY - sizeY, centerZ - sizeZ)
		local brx, bry, brz = localToWorld(markerStart, centerX + sizeX, centerY - sizeY, centerZ - sizeZ)
		local flx, fly, flz = localToWorld(markerStart, centerX - sizeX, centerY - sizeY, centerZ + sizeZ)
		local frx, fry, frz = localToWorld(markerStart, centerX + sizeX, centerY - sizeY, centerZ + sizeZ)
		local tblx, tbly, tblz = localToWorld(markerStart, centerX - sizeX, centerY + sizeY, centerZ - sizeZ)
		local tbrx, tbry, tbrz = localToWorld(markerStart, centerX + sizeX, centerY + sizeY, centerZ - sizeZ)
		local tflx, tfly, tflz = localToWorld(markerStart, centerX - sizeX, centerY + sizeY, centerZ + sizeZ)
		local tfrx, tfry, tfrz = localToWorld(markerStart, centerX + sizeX, centerY + sizeY, centerZ + sizeZ)

		table.insert(box.points, {
			blx,
			bly,
			blz
		})
		table.insert(box.points, {
			brx,
			bry,
			brz
		})
		table.insert(box.points, {
			frx,
			fry,
			frz
		})
		table.insert(box.points, {
			flx,
			fly,
			flz
		})
		table.insert(box.points, {
			tblx,
			tbly,
			tblz
		})
		table.insert(box.points, {
			tbrx,
			tbry,
			tbrz
		})
		table.insert(box.points, {
			tfrx,
			tfry,
			tfrz
		})
		table.insert(box.points, {
			tflx,
			tfly,
			tflz
		})
		table.insert(box.points, {
			x,
			y,
			z
		})

		spec.checkBoxes[markerStart] = box
	end

	local rx, ry, rz = getWorldRotation(markerStart)
	spec.objectsInTensionBeltRange = {}
	spec.numObjectsIntensionBeltRange = 0

	overlapBox(x, y, z, rx, ry, rz, sizeX, sizeY, sizeZ, "objectOverlapCallback", self, 3212828671.0, true, false, true)

	return spec.objectsInTensionBeltRange, spec.numObjectsIntensionBeltRange
end

function TensionBelts:getObjectsToUnmount(belt)
	local spec = self.spec_tensionBelts
	local objectIdsToUnmount = {}
	local numObjects = 0

	for objectId, _ in pairs(spec.objectsToJoint) do
		objectIdsToUnmount[objectId] = objectId
		numObjects = numObjects + 1
	end

	for _, otherBelt in pairs(spec.singleBelts) do
		if otherBelt.mesh ~= nil and otherBelt ~= belt then
			local objectToMount, _ = self:getObjectToMount(otherBelt)

			for _, object in pairs(objectToMount) do
				if objectIdsToUnmount[object.physics] ~= nil then
					objectIdsToUnmount[object.physics] = nil
					numObjects = numObjects - 1
				end
			end
		end
	end

	return objectIdsToUnmount, numObjects
end

function TensionBelts:objectOverlapCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local spec = self.spec_tensionBelts
		local object = g_currentMission:getNodeObject(transformId)

		if object ~= nil then
			if object.getSupportsTensionBelts ~= nil and object:getSupportsTensionBelts() and object.getMeshNodes ~= nil and object.dynamicMountObject == nil then
				local nodeId = object:getTensionBeltNodeId()

				if spec.objectsInTensionBeltRange[nodeId] == nil then
					local nodes = object:getMeshNodes()

					if nodes ~= nil then
						spec.objectsInTensionBeltRange[nodeId] = {
							physics = nodeId,
							visuals = nodes,
							object = object
						}
						spec.numObjectsIntensionBeltRange = spec.numObjectsIntensionBeltRange + 1
					end
				end
			end
		elseif getSplitType(transformId) ~= 0 then
			local rigidBodyType = getRigidBodyType(transformId)

			if (rigidBodyType == "Dynamic" or rigidBodyType == "Kinematic") and spec.objectsInTensionBeltRange[transformId] == nil then
				spec.objectsInTensionBeltRange[transformId] = {
					physics = transformId,
					visuals = {
						transformId
					}
				}
				spec.numObjectsIntensionBeltRange = spec.numObjectsIntensionBeltRange + 1
			end
		end
	end

	return true
end

function TensionBelts:getIsPlayerInTensionBeltsRange()
	if g_currentMission.player == nil then
		return false, nil
	end

	if not g_currentMission.accessHandler:canPlayerAccess(self) then
		return false, nil
	end

	local spec = self.spec_tensionBelts

	if spec.beltData ~= nil then
		local px, py, pz = getWorldTranslation(g_currentMission.player.rootNode)
		local vx, vy, vz = localToWorld(spec.interactionBaseNode, spec.interactionBasePointX, 0, spec.interactionBasePointZ)
		local currentBelt = nil
		local distance = math.huge

		if MathUtil.vector3Length(px - vx, py - vy, pz - vz) < spec.totalInteractionRadius then
			if spec.tensionBelts ~= nil then
				for _, belt in pairs(spec.singleBelts) do
					local sx, sy, sz = getWorldTranslation(belt.startNode)
					local ex, ey, ez = getWorldTranslation(belt.endNode)
					local sDistance = MathUtil.vector3Length(px - sx, py - sy, pz - sz)
					local eDistance = MathUtil.vector3Length(px - ex, py - ey, pz - ez)

					if sDistance < distance and sDistance < spec.interactionRadius or eDistance < distance and eDistance < spec.interactionRadius then
						currentBelt = belt
						distance = math.min(sDistance, eDistance)
					end
				end
			end

			if distance < spec.interactionRadius then
				return true, currentBelt
			end
		end
	end

	return false, nil
end

function TensionBelts:getIsDynamicallyMountedNode(node)
	local spec = self.spec_tensionBelts

	if spec.objectsToJoint ~= nil then
		for object, _ in pairs(spec.objectsToJoint) do
			if object == node then
				return true
			end
		end
	end

	return false
end

function TensionBelts:getIsReadyForAutomatedTrainTravel(superFunc)
	local spec = self.spec_tensionBelts

	if spec.hasTensionBelts and spec.numObjectsIntensionBeltRange > 0 then
		return false
	end

	return superFunc(self)
end

function TensionBelts:getCanBeSelected(superFunc)
	return true
end

function TensionBelts:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local spec = self.spec_tensionBelts

	if self.isClient and spec.hasTensionBelts then
		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TENSION_BELTS, self, TensionBelts.actionEventToggleTensionBelts, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end
	end
end

function TensionBelts:tensionBeltActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_tensionBelts

	if self.isClient and spec.hasTensionBelts and (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		if onEnter then
			self:raiseActive()

			spec.isPlayerInTrigger = true
		else
			spec.isPlayerInTrigger = false
		end
	end
end

TensionBeltsActivatable = {}
local TensionBeltsActivatable_mt = Class(TensionBeltsActivatable)

function TensionBeltsActivatable:new(object)
	local self = {}

	setmetatable(self, TensionBeltsActivatable_mt)

	self.object = object
	self.spec = object.spec_tensionBelts
	self.activateText = g_i18n:getText("action_fastenTensionBelt")

	return self
end

function TensionBeltsActivatable:getIsActivatable()
	return self.spec.isPlayerInRange
end

function TensionBeltsActivatable:onActivateObject()
	if self.spec.currentBelt ~= nil then
		if self.spec.currentBelt.mesh ~= nil then
			self.object:setTensionBeltsActive(false, self.spec.currentBelt.id, false)
		else
			self.object:setTensionBeltsActive(true, self.spec.currentBelt.id, false)
		end
	end

	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end

function TensionBeltsActivatable:drawActivate()
end

function TensionBeltsActivatable:updateActivateText()
	if self.spec.currentBelt ~= nil and self.spec.currentBelt.mesh ~= nil then
		self.activateText = g_i18n:getText("action_unfastenTensionBelt")
	else
		self.activateText = g_i18n:getText("action_fastenTensionBelt")
	end
end

function TensionBelts:actionEventToggleTensionBelts(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_tensionBelts
	local newState = not spec.areBeltsFasten

	for _, belt in pairs(spec.sortedBelts) do
		self:setTensionBeltsActive(newState, belt.id, false)
	end

	spec.checkBoxes = {}
end

function TensionBelts.consoleCommandToggleTensionBeltDebugRendering(unusedSelf)
	TensionBelts.debugRendering = not TensionBelts.debugRendering

	return "TensionBeltsDebugRendering = " .. tostring(TensionBelts.debugRendering)
end

addConsoleCommand("gsToggleTensionBeltDebugRendering", "Toggles the debug tension belt rendering of the vehicle", "TensionBelts.consoleCommandToggleTensionBeltDebugRendering", nil)
