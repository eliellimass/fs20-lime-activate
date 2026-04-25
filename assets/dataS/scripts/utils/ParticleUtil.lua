ParticleUtil = {
	loadParticleSystemData = function (xmlFile, data, baseString)
		data.nodeStr = getXMLString(xmlFile, baseString .. "#node")
		data.psFile = getXMLString(xmlFile, baseString .. "#file")
		data.posX, data.posY, data.posZ = StringUtil.getVectorFromString(getXMLString(xmlFile, baseString .. "#position"))
		data.rotX, data.rotY, data.rotZ = StringUtil.getVectorFromString(getXMLString(xmlFile, baseString .. "#rotation"))
		data.rotX = MathUtil.degToRad(data.rotX)
		data.rotY = MathUtil.degToRad(data.rotY)
		data.rotZ = MathUtil.degToRad(data.rotZ)
		data.worldSpace = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#worldSpace"), true)
		data.psRootNodeStr = getXMLString(xmlFile, baseString .. "#particleNode")
		data.forceFullLifespan = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#forceFullLifespan"), false)
		data.useEmitterVisibility = Utils.getNoNil(getXMLBool(xmlFile, baseString .. "#useEmitterVisibility"), false)
	end
}

function ParticleUtil.loadParticleSystem(xmlFile, particleSystem, baseString, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
	local data = {}

	ParticleUtil.loadParticleSystemData(xmlFile, data, baseString)

	return ParticleUtil.loadParticleSystemFromData(data, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
end

function ParticleUtil.loadParticleSystemFromData(data, particleSystem, linkNodes, defaultEmittingState, defaultPsFile, baseDir, defaultLinkNode)
	if defaultLinkNode == nil then
		defaultLinkNode = linkNodes

		if type(linkNodes) == "table" then
			defaultLinkNode = linkNodes[1].node
		end
	end

	local linkNode = Utils.getNoNil(I3DUtil.indexToObject(linkNodes, data.nodeStr), defaultLinkNode)
	local psFile = data.psFile

	if psFile == nil then
		psFile = defaultPsFile
	end

	if psFile == nil then
		return
	end

	psFile = Utils.getFilename(psFile, baseDir)
	local rootNodeFile = loadI3DFile(psFile, true, true, false)
	local rootNode = rootNodeFile

	if rootNode == 0 then
		print("Error: failed to load particle system " .. psFile)

		return
	end

	if data.psRootNodeStr ~= nil then
		local newRootNode = I3DUtil.indexToObject(rootNode, data.psRootNodeStr)

		if newRootNode ~= nil then
			rootNode = newRootNode
		end
	else
		rootNode = getChildAt(rootNodeFile, 0)
	end

	if linkNode ~= nil then
		link(linkNode, rootNode)
	end

	local posX = data.posX
	local posY = data.posY
	local posZ = data.posZ

	if posX ~= nil and posY ~= nil and posZ ~= nil then
		setTranslation(rootNode, posX, posY, posZ)
	end

	local rotX = data.rotX
	local rotY = data.rotY
	local rotZ = data.rotZ

	if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
		setRotation(rootNode, rotX, rotY, rotZ)
	end

	local returnValue = ParticleUtil.loadParticleSystemFromNode(rootNode, particleSystem, defaultEmittingState, data.worldSpace, data.forceFullLifespan, psFile)

	if rootNode ~= rootNodeFile then
		delete(rootNodeFile)
	end

	return returnValue
end

function ParticleUtil.loadParticleSystemFromNode(rootNode, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan, file)
	if defaultEmittingState == nil then
		defaultEmittingState = true
	end

	if getHasClassId(rootNode, ClassIds.SHAPE) then
		local geometry = getGeometry(rootNode)

		if geometry ~= 0 and getHasClassId(geometry, ClassIds.PARTICLE_SYSTEM) then
			particleSystem.emitterShape = getEmitterShape(geometry)
			particleSystem.emitterShapeSize = getEmitterSurfaceSize(geometry)
			particleSystem.defaultEmitterShapeSize = getEmitterSurfaceSize(geometry)

			if worldSpace then
				local parent = getParent(rootNode)

				if particleSystem.emitterShape ~= 0 and getParent(particleSystem.emitterShape) == rootNode then
					local x, y, z = getScale(particleSystem.emitterShape)

					setTranslation(particleSystem.emitterShape, worldToLocal(parent, getWorldTranslation(particleSystem.emitterShape)))

					local dx, dy, dz = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 0, 1))
					local upx, upy, upz = worldDirectionToLocal(rootNode, localDirectionToWorld(particleSystem.emitterShape, 0, 1, 0))

					setDirection(particleSystem.emitterShape, dx, dy, dz, upx, upy, upz)
					link(parent, particleSystem.emitterShape)
					setScale(particleSystem.emitterShape, x, y, z)
				end

				link(getRootNode(), rootNode)
				setTranslation(rootNode, 0, 0, 0)
				setRotation(rootNode, 0, 0, 0)
			end

			setObjectMask(rootNode, 16711807)

			particleSystem.geometry = geometry
			particleSystem.shape = rootNode
			particleSystem.worldSpace = worldSpace
			particleSystem.forceFullLifespan = forceFullLifespan
			particleSystem.originalLifespan = getParticleSystemLifespan(geometry)

			setEmittingState(geometry, defaultEmittingState)
		end
	end

	particleSystem.isEmitting = defaultEmittingState

	return rootNode
end

function ParticleUtil.deleteParticleSystem(particleSystem)
	if particleSystem ~= nil and particleSystem.shape ~= nil then
		if entityExists(particleSystem.shape) then
			delete(particleSystem.shape)
		end

		particleSystem.shape = nil
	end
end

function ParticleUtil.deleteParticleSystems(particleSystems)
	if particleSystems ~= nil then
		for _, ps in pairs(particleSystems) do
			ParticleUtil.deleteParticleSystem(ps)
		end
	end
end

function ParticleUtil.setEmittingState(particleSystem, state, resetStartTimer, resetStopTimer)
	if particleSystem ~= nil and particleSystem.isEmitting ~= state then
		particleSystem.isEmitting = state

		if resetStartTimer == nil then
			resetStartTimer = true
		end

		if resetStopTimer == nil then
			resetStopTimer = true
		end

		if state then
			if resetStartTimer then
				resetEmitStartTimer(particleSystem.geometry)
			end
		elseif resetStopTimer then
			resetEmitStopTimer(particleSystem.geometry)
		end

		setEmittingState(particleSystem.geometry, state)

		if state and particleSystem.useEmitterVisibility then
			setVisibility(particleSystem.shape, getOverallVisibility(particleSystem.emitterShape))
		end
	end
end

function ParticleUtil.getParticleSystemAverageSpeed(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemAverageSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemTimeScale(particleSystem, scale)
	if particleSystem ~= nil and scale ~= nil then
		setParticleSystemTimeScale(particleSystem.geometry, scale)
	end
end

function ParticleUtil.setEmitCountScale(particleSystem, scale)
	if particleSystem ~= nil and scale ~= nil then
		setEmitCountScale(particleSystem.geometry, scale)
	end
end

function ParticleUtil.setParticleLifespan(particleSystem, lifespan)
	if particleSystem ~= nil and lifespan ~= nil then
		setParticleSystemLifespan(particleSystem.geometry, lifespan, true)
	end
end

function ParticleUtil.addParticleSystemSimulationTime(particleSystem, simTime)
	if particleSystem ~= nil and simTime ~= nil then
		addParticleSystemSimulationTime(particleSystem.geometry, simTime)
	end
end

function ParticleUtil.setParticleStartStopTime(particleSystem, startTime, stopTime)
	if particleSystem ~= nil and startTime ~= nil and stopTime ~= nil then
		setEmitStartTime(particleSystem.geometry, startTime * 1000)
		setEmitStopTime(particleSystem.geometry, stopTime * 1000)
	end
end

function ParticleUtil.getParticleSystemSpeed(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpeed(particleSystem, speed)
	if particleSystem ~= nil and speed ~= nil then
		setParticleSystemSpeed(particleSystem.geometry, speed)
	end
end

function ParticleUtil.getParticleSystemSpeedRandom(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpeedRandom(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpeedRandom(particleSystem, randomSpeed)
	if particleSystem ~= nil and randomSpeed ~= nil then
		setParticleSystemSpeedRandom(particleSystem.geometry, randomSpeed)
	end
end

function ParticleUtil.getParticleSystemNormalSpeed(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemNormalSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemNormalSpeed(particleSystem, normalSpeed)
	if particleSystem ~= nil and normalSpeed ~= nil then
		setParticleSystemNormalSpeed(particleSystem.geometry, normalSpeed)
	end
end

function ParticleUtil.getParticleSystemTangentSpeed(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemTangentSpeed(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemTangentSpeed(particleSystem, tangentSpeed)
	if particleSystem ~= nil and tangentSpeed ~= nil then
		setParticleSystemTangentSpeed(particleSystem.geometry, tangentSpeed)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleX(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpriteScaleX(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, spriteScaleX)
	if particleSystem ~= nil and spriteScaleX ~= nil then
		setParticleSystemSpriteScaleX(particleSystem.geometry, spriteScaleX)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleY(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpriteScaleY(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, spriteScaleY)
	if particleSystem ~= nil and spriteScaleY ~= nil then
		setParticleSystemSpriteScaleY(particleSystem.geometry, spriteScaleY)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleXGain(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpriteScaleXGain(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleXGain(particleSystem, spriteScaleXGain)
	if particleSystem ~= nil and spriteScaleXGain ~= nil then
		setParticleSystemSpriteScaleXGain(particleSystem.geometry, spriteScaleXGain)
	end
end

function ParticleUtil.getParticleSystemSpriteScaleYGain(particleSystem)
	if particleSystem ~= nil then
		return getParticleSystemSpriteScaleYGain(particleSystem.geometry)
	end
end

function ParticleUtil.setParticleSystemSpriteScaleYGain(particleSystem, spriteScaleYGain)
	if particleSystem ~= nil and spriteScaleYGain ~= nil then
		setParticleSystemSpriteScaleYGain(particleSystem.geometry, spriteScaleYGain)
	end
end

function ParticleUtil.resetNumOfEmittedParticles(particleSystem)
	if particleSystem ~= nil then
		resetNumOfEmittedParticles(particleSystem.geometry)
	end
end

function ParticleUtil.setEmitterShape(particleSystem, emitterShape)
	if particleSystem ~= nil and emitterShape ~= nil and particleSystem.geometry ~= nil and particleSystem.geometry ~= 0 and getHasClassId(particleSystem.geometry, ClassIds.PARTICLE_SYSTEM) then
		setEmitterShape(particleSystem.geometry, emitterShape)

		particleSystem.emitterShape = emitterShape
		particleSystem.emitterShapeSize = getEmitterSurfaceSize(particleSystem.geometry)
	end
end

function ParticleUtil.initEmitterScale(particleSystem, scale)
	if particleSystem ~= nil then
		setNumOfParticlesToEmitPerMs(particleSystem.geometry, getNumOfParticlesToEmitPerMs(particleSystem.geometry) * scale)
		setMaxNumOfParticles(particleSystem.geometry, math.ceil(getMaxNumOfParticles(particleSystem.geometry) * scale))
	end
end

function ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, emitterShape)
	local currentPS = {
		worldSpace = Utils.getNoNil(getXMLBool(xmlFile, key .. "#worldSpace"), true),
		emitCountScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#emitCountScale"), 1),
		delay = getXMLFloat(xmlFile, key .. "#delay")
	}
	currentPS.startTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#startTime"), currentPS.delay)
	currentPS.stopTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#stopTime"), currentPS.delay)
	currentPS.lifespan = getXMLFloat(xmlFile, key .. "#lifespan")
	currentPS.useEmitterVisibility = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useEmitterVisibility"), false)
	local psClone = clone(particleSystem.shape, true, false, true)

	setObjectMask(psClone, 16711807)
	ParticleUtil.loadParticleSystemFromNode(psClone, currentPS, false, currentPS.worldSpace, particleSystem.forceFullLifespan)

	if emitterShape ~= nil then
		ParticleUtil.setEmitterShape(currentPS, emitterShape)

		local scale = currentPS.emitterShapeSize / currentPS.defaultEmitterShapeSize * currentPS.emitCountScale

		ParticleUtil.initEmitterScale(currentPS, scale)
		ParticleUtil.setEmitCountScale(currentPS, 1)

		if currentPS.lifespan ~= nil then
			ParticleUtil.setParticleLifespan(currentPS, currentPS.lifespan * 1000)

			currentPS.originalLifespan = currentPS.lifespan * 1000
		end

		ParticleUtil.setParticleStartStopTime(currentPS, currentPS.startTime, currentPS.stopTime)

		if not currentPS.worldSpace then
			link(getParent(emitterShape), currentPS.shape, getChildIndex(emitterShape))
			setTranslation(currentPS.shape, getTranslation(emitterShape))
			setRotation(currentPS.shape, getRotation(emitterShape))
			link(currentPS.shape, emitterShape)
			setTranslation(emitterShape, 0, 0, 0)
			setRotation(emitterShape, 0, 0, 0)
		end
	end

	return currentPS
end
