WorkParticles = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function WorkParticles.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDoGroundManipulation", WorkParticles.getDoGroundManipulation)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimations", WorkParticles.loadGroundAnimations)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimationMapping", WorkParticles.loadGroundAnimationMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticles", WorkParticles.loadGroundParticles)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticleMapping", WorkParticles.loadGroundParticleMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundEffects", WorkParticles.loadGroundEffects)
	SpecializationUtil.registerFunction(vehicleType, "getFillTypeFromWorkAreaIndex", WorkParticles.getFillTypeFromWorkAreaIndex)
end

function WorkParticles.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", WorkParticles.loadGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", WorkParticles.updateGroundReferenceNode)
end

function WorkParticles.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkParticles)
end

function WorkParticles:onLoad(savegame)
	local spec = self.spec_workParticles

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.groundParticleAnimations.groundParticleAnimation", "vehicle.workParticles.particleAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.groundParticleAnimations.groundParticle", "vehicle.workParticles.particle")

	if self.isClient then
		spec.particleAnimations = {}
		local i = 0

		while true do
			local key = string.format("vehicle.workParticles.particleAnimation(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local animation = {}

			if self:loadGroundAnimations(self.xmlFile, key, animation, i) then
				table.insert(spec.particleAnimations, animation)
			end

			i = i + 1
		end

		spec.particles = {}
		i = 0

		while true do
			local key = string.format("vehicle.workParticles.particle(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local particle = {}

			if self:loadGroundParticles(self.xmlFile, key, particle, i) then
				table.insert(spec.particles, particle)
			end

			i = i + 1
		end

		spec.effects = {}
		i = 0

		while true do
			local key = string.format("vehicle.workParticles.effect(%d)", i)

			if not hasXMLProperty(self.xmlFile, key) then
				break
			end

			local effect = {}

			if self:loadGroundEffects(self.xmlFile, key, effect, i) then
				table.insert(spec.effects, effect)
			end

			i = i + 1
		end
	end
end

function WorkParticles:onDelete()
	local spec = self.spec_workParticles

	if self.isClient then
		for _, animation in ipairs(spec.particleAnimations) do
			if animation.filename ~= nil then
				g_i3DManager:releaseSharedI3DFile(animation.filename, self.baseDirectory, true)
			end
		end

		for _, ps in pairs(spec.particles) do
			for _, mapping in ipairs(ps.mappings) do
				ParticleUtil.deleteParticleSystem(mapping.particleSystem)
			end
		end

		for _, effect in pairs(spec.effects) do
			g_effectManager:deleteEffects(effect.effect)
		end
	end
end

function WorkParticles:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workParticles

	if self.isClient then
		local isOnField = self:getIsOnField()

		for _, animation in ipairs(spec.particleAnimations) do
			for _, mapping in ipairs(animation.mappings) do
				local refNode = mapping.groundRefNode

				if refNode ~= nil and refNode.depthNode ~= nil then
					local depth = MathUtil.clamp(refNode.depth / mapping.maxWorkDepth, 0, 1)

					if not isOnField then
						depth = 0
					end

					depth = MathUtil.clamp(math.min(depth, mapping.lastDepth + refNode.movingDirection * refNode.movedDistance / 0.5), 0, 1)
					mapping.lastDepth = depth
					mapping.speed = mapping.speed - refNode.movedDistance * refNode.movingDirection

					setVisibility(mapping.animNode, depth > 0)
					setShaderParameter(mapping.animNode, "VertxoffsetVertexdeformMotionUVscale", -6, depth, mapping.speed, 1.5, false)
				end
			end
		end

		local lastSpeed = self:getLastSpeed(true)
		local enabled = self:getDoGroundManipulation() and isOnField

		for _, ps in pairs(spec.particles) do
			for _, mapping in ipairs(ps.mappings) do
				local nodeEnabled = enabled
				nodeEnabled = nodeEnabled and mapping.groundRefNode.isActive and mapping.speedThreshold < lastSpeed

				if mapping.movingDirection ~= nil then
					nodeEnabled = nodeEnabled and mapping.movingDirection == self.movingDirection
				end

				ParticleUtil.setEmittingState(mapping.particleSystem, nodeEnabled)
			end
		end

		for _, effect in pairs(spec.effects) do
			local state = enabled and effect.speedThreshold < lastSpeed

			if effect.needsSetIsTurnedOn and self.getIsTurnedOn ~= nil then
				local turnedOn = self:getIsTurnedOn()

				if self.getAttacherVehicle ~= nil then
					local attacherVehicle = self:getAttacherVehicle()

					if attacherVehicle ~= nil and attacherVehicle.getIsTurnedOn ~= nil then
						turnedOn = turnedOn or attacherVehicle:getIsTurnedOn()
					end
				end

				state = state and turnedOn
			end

			local workArea = self:getWorkAreaByIndex(effect.workAreaIndex)

			if workArea ~= nil and workArea.requiresGroundContact then
				state = state and workArea.groundReferenceNode ~= nil and workArea.groundReferenceNode.isActive
			end

			if state then
				local fillType = self:getFillTypeFromWorkAreaIndex(effect.workAreaIndex)

				g_effectManager:setFillType(effect.effect, fillType)
				g_effectManager:startEffects(effect.effect)
			else
				g_effectManager:stopEffects(effect.effect)
			end
		end
	end
end

function WorkParticles:getDoGroundManipulation()
	return true
end

function WorkParticles:loadGroundAnimations(xmlFile, key, animation, index)
	local filenameStr = getXMLString(self.xmlFile, key .. "#file")
	local i3dNode = nil

	if filenameStr ~= nil then
		i3dNode = g_i3DManager:loadSharedI3DFile(filenameStr, self.baseDirectory)
	end

	animation.speedThreshold = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speedThreshold"), 0)
	animation.mappings = {}
	local j = 0

	while true do
		local nodeBaseName = string.format(key .. ".node(%d)", j)

		if not hasXMLProperty(self.xmlFile, nodeBaseName) then
			break
		end

		local mapping = {}

		if self:loadGroundAnimationMapping(xmlFile, nodeBaseName, mapping, j, i3dNode) then
			table.insert(animation.mappings, mapping)
		end

		j = j + 1
	end

	if i3dNode ~= nil and i3dNode ~= 0 then
		for _, mapping in ipairs(animation.mappings) do
			link(mapping.node, mapping.animNode)
			setVisibility(mapping.animNode, false)
		end

		animation.filename = filenameStr

		delete(i3dNode)
	end

	return true
end

function WorkParticles:loadGroundAnimationMapping(xmlFile, key, mapping, index)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#animMeshIndex", key .. "#animMeshNode")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid node '%s' for '%s'", getXMLString(xmlFile, key .. "#node"), key)

		return false
	end

	local groundRefIndex = getXMLInt(xmlFile, key .. "#refNodeIndex")

	if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid refNodeIndex '%s' for '%s'", getXMLString(xmlFile, key .. "#refNodeIndex"), key)

		return false
	end

	local animNode = nil
	local animMeshNode = getXMLString(xmlFile, key .. "#animMeshNode")

	if animMeshNode ~= nil then
		animNode = I3DUtil.indexToObject(node, animMeshNode, self.i3dMappings)

		if animNode == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid animMesh node '%s' '%s'", getXMLString(xmlFile, key .. "#animMeshNode"), key)

			return false
		end
	else
		local materialType = getXMLString(xmlFile, key .. "#materialType")
		local materialId = Utils.getNoNil(getXMLInt(xmlFile, key .. "#materialId"), 1)

		if materialType == nil then
			g_logManager:xmlWarning(self.configFileName, "Missing materialType in '%s'", key)

			return false
		end

		animNode = node
		local material = g_materialManager:getMaterial(FillType.UNKNOWN, materialType, materialId)

		if material ~= nil then
			setMaterial(node, material, 0)
		else
			g_logManager:xmlWarning(self.configFileName, "Invalid materialType '%s' or materialId '%s' in '%s'", materialType, materialId, key)
		end

		setVisibility(animNode, false)
	end

	mapping.node = node
	mapping.animNode = animNode
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
	mapping.lastDepth = 0
	mapping.speed = 0
	mapping.maxWorkDepth = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#maxDepth"), -0.1)

	return true
end

function WorkParticles:loadGroundParticles(xmlFile, key, particle, index)
	particle.mappings = {}
	local filename = getXMLString(xmlFile, key .. "#file")
	local i3dNode = nil

	if filename ~= nil then
		filename = Utils.getFilename(filename, self.baseDirectory)
		i3dNode = loadI3DFile(filename, true, true, false)
	end

	local j = 0

	while true do
		local nodeBaseName = string.format(key .. ".node(%d)", j)

		if not hasXMLProperty(xmlFile, nodeBaseName) then
			break
		end

		local mapping = {}

		if self:loadGroundParticleMapping(xmlFile, nodeBaseName, mapping, j, i3dNode) then
			table.insert(particle.mappings, mapping)
		end

		j = j + 1
	end

	if i3dNode ~= nil and i3dNode ~= 0 then
		for _, mapping in ipairs(particle.mappings) do
			link(mapping.node, mapping.particleNode)
			ParticleUtil.loadParticleSystemFromNode(mapping.particleNode, mapping.particleSystem, false, true)
		end

		particle.filename = filename

		delete(i3dNode)
	end

	return true
end

function WorkParticles:loadGroundParticleMapping(xmlFile, key, mapping, index, i3dNode)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#particleIndex", key .. "#particleNode")

	mapping.particleSystem = {}
	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid node '%s' for '%s'", getXMLString(xmlFile, key .. "#node"), key)

		return false
	end

	local groundRefIndex = getXMLInt(xmlFile, key .. "#refNodeIndex")

	if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid refNodeIndex '%s' for '%s'", getXMLString(xmlFile, key .. "#refNodeIndex"), key)

		return false
	end

	local particleNode = nil
	local particleNodeIndex = getXMLString(xmlFile, key .. "#particleNode")

	if particleNodeIndex ~= nil then
		particleNode = I3DUtil.indexToObject(i3dNode, particleNodeIndex, self.i3dMappings)

		if particleNode == nil then
			g_logManager:xmlWarning(self.configFileName, "Invalid particle node '%s' '%s'", getXMLString(xmlFile, key .. "#particleNode"), key)

			return false
		end
	else
		particleNode = node
		local particleType = getXMLString(xmlFile, key .. "#particleType")

		if particleType == nil then
			g_logManager:xmlWarning(self.configFileName, "Missing particleType in '%s'", key)

			return false
		end

		local fillTypeStr = getXMLString(xmlFile, key .. "#fillType")
		local fillType = Utils.getNoNil(g_fillTypeManager:getFillTypeIndexByName(fillTypeStr), FillType.UNKNOWN)
		local particleSystem = g_particleSystemManager:getParticleSystem(fillType, particleType)

		if particleSystem ~= nil then
			mapping.particleSystem = ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, node)
		else
			return false
		end
	end

	mapping.node = node
	mapping.particleNode = particleNode
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
	mapping.speedThreshold = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speedThreshold"), 0.5)
	mapping.movingDirection = getXMLInt(xmlFile, key .. "#movingDirection")

	return true
end

function WorkParticles:loadGroundEffects(xmlFile, key, effect, index)
	effect.speedThreshold = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#speedThreshold"), 0.5)
	effect.workAreaIndex = getXMLInt(xmlFile, key .. "#workAreaIndex")
	effect.needsSetIsTurnedOn = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needsSetIsTurnedOn"), false)
	effect.effect = g_effectManager:loadEffect(xmlFile, key, self.components, self, self.i3dMappings)

	return true
end

function WorkParticles:getFillTypeFromWorkAreaIndex(workAreaIndex)
	local fillType = FillType.UNKNOWN
	local workArea = self:getWorkAreaByIndex(workAreaIndex)

	if workArea ~= nil then
		if workArea.fillType ~= nil then
			fillType = workArea.fillType
		elseif workArea.fruitType ~= nil then
			fillType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(workArea.fruitType)
		end
	end

	return fillType
end

function WorkParticles:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
	local returnValue = superFunc(self, xmlFile, key, groundReferenceNode)

	if returnValue then
		groundReferenceNode.depthNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#depthNode"), self.i3dMappings)
		groundReferenceNode.movedDistance = 0
		groundReferenceNode.depth = 0
		groundReferenceNode.movingDirection = 0
	end

	return returnValue
end

function WorkParticles:updateGroundReferenceNode(superFunc, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
	superFunc(self, groundReferenceNode, x, y, z, terrainHeight, densityHeight)

	if self.isClient and groundReferenceNode.depthNode ~= nil then
		local newX, newY, newZ = getWorldTranslation(groundReferenceNode.depthNode)

		if groundReferenceNode.lastPosition == nil then
			groundReferenceNode.lastPosition = {
				newX,
				newY,
				newZ
			}
		end

		local dx, dy, dz = worldDirectionToLocal(groundReferenceNode.depthNode, newX - groundReferenceNode.lastPosition[1], newY - groundReferenceNode.lastPosition[2], newZ - groundReferenceNode.lastPosition[3])
		groundReferenceNode.movingDirection = 0

		if dz > 0.0001 then
			groundReferenceNode.movingDirection = 1
		elseif dz < -0.0001 then
			groundReferenceNode.movingDirection = -1
		end

		groundReferenceNode.movedDistance = MathUtil.vector3Length(dx, dy, dz)
		groundReferenceNode.lastPosition[3] = newZ
		groundReferenceNode.lastPosition[2] = newY
		groundReferenceNode.lastPosition[1] = newX
		local terrainHeightDepthNode = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, newX, newY, newZ)
		groundReferenceNode.depth = newY - terrainHeightDepthNode
	end
end

function WorkParticles:onDeactivate()
	local spec = self.spec_workParticles

	if self.isClient then
		for _, ps in pairs(spec.particles) do
			for _, mapping in ipairs(ps.mappings) do
				ParticleUtil.setEmittingState(mapping.particleSystem, false)
			end
		end

		for _, animation in ipairs(spec.particleAnimations) do
			for _, mapping in ipairs(animation.mappings) do
				setVisibility(mapping.animNode, false)
			end
		end
	end
end
