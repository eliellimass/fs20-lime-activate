ParticleEffect = {}
local ParticleEffect_mt = Class(ParticleEffect, Effect)

function ParticleEffect:new(customMt)
	local self = Effect:new(customMt or ParticleEffect_mt)
	self.isActive = false
	self.currentFillType = FillType.UNKNOWN

	return self
end

function ParticleEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ParticleEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.emitterShape = self.node
	self.emitterShapeTrans = createTransformGroup("emitterShapeTrans")

	link(getParent(self.emitterShape), self.emitterShapeTrans, getChildIndex(self.emitterShape))
	link(self.emitterShapeTrans, self.emitterShape)

	self.emitCountScale = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "emitCountScale"), 1)
	self.particleType = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLString, node, "particleType"), "unloading")
	self.worldSpace = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "worldSpace"), true)
	self.delay = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "delay"), 0)
	self.startTime = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "startTime"), self.delay)
	self.startTimeMs = self.startTime * 1000
	self.stopTime = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "stopTime"), self.delay)
	self.stopTimeMs = self.stopTime * 1000
	self.lifespan = Effect.getValue(xmlFile, key, getXMLFloat, node, "lifespan")
	self.extraDistance = Effect.getValue(xmlFile, key, getXMLFloat, node, "extraDistance") or 0
	self.realStartTime = -math.huge
	self.realStopTime = math.huge
	self.useCuttingWidth = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLBool, node, "useCuttingWidth"), true)
	self.currentParticleSystem = nil
	self.particleSystems = {}

	return true
end

function ParticleEffect:delete()
	ParticleEffect:superClass().delete(self)
	ParticleUtil.deleteParticleSystems(self.particleSystems)
end

function ParticleEffect:isRunning()
	return self.isActive
end

function ParticleEffect:start()
	if self.currentParticleSystem ~= nil then
		ParticleUtil.setEmittingState(self.currentParticleSystem, self.totalWidth == nil or self.totalWidth > 0)

		self.isActive = true
		self.realStartTime = g_time
		self.realStopTime = math.huge

		return true
	end

	return false
end

function ParticleEffect:stop()
	ParticleUtil.setEmittingState(self.currentParticleSystem, false)

	if self.currentParticleSystem ~= nil then
		self.realStopTime = g_time
	end

	self.currentParticleSystem = nil
	self.isActive = false
end

function ParticleEffect:reset()
end

function ParticleEffect:setFillType(fillType)
	local success = true

	if self.currentFillType ~= fillType or self.currentParticleSystem == nil then
		local wasActive = false

		if self.currentParticleSystem ~= nil then
			wasActive = true

			ParticleUtil.setEmittingState(self.currentParticleSystem, false)

			self.currentParticleSystem = nil
		end

		if self.particleSystems[fillType] == nil then
			local particleSystem = g_particleSystemManager:getParticleSystem(fillType, self.particleType)

			if particleSystem ~= nil then
				local psClone = clone(particleSystem.shape, true, false, true)
				local currentPS = {}
				local emitterShape = self.emitterShape

				ParticleUtil.loadParticleSystemFromNode(psClone, currentPS, false, self.worldSpace, particleSystem.forceFullLifespan)

				self.particleSystems[fillType] = currentPS

				ParticleUtil.setEmitterShape(self.particleSystems[fillType], emitterShape)

				local scale = currentPS.emitterShapeSize / currentPS.defaultEmitterShapeSize * self.emitCountScale

				ParticleUtil.initEmitterScale(currentPS, scale)
				ParticleUtil.setEmitCountScale(currentPS, 1)

				if self.lifespan ~= nil then
					ParticleUtil.setParticleLifespan(currentPS, self.lifespan * 1000)

					currentPS.originalLifespan = self.lifespan * 1000
				end

				ParticleUtil.setParticleStartStopTime(currentPS, self.startTime, self.stopTime)

				if not currentPS.worldSpace then
					link(getParent(emitterShape), currentPS.shape, getChildIndex(emitterShape))
					setTranslation(currentPS.shape, getTranslation(emitterShape))
					setRotation(currentPS.shape, getRotation(emitterShape))
					link(currentPS.shape, emitterShape)
					setTranslation(emitterShape, 0, 0, 0)
					setRotation(emitterShape, 0, 0, 0)
				end
			else
				success = false
			end
		end

		self.currentParticleSystem = self.particleSystems[fillType]

		if wasActive then
			ParticleUtil.setEmittingState(self.currentParticleSystem, true)
		end

		if self.currentParticleSystem ~= nil then
			self.distanceToLifespans = {}

			for j = 0, 1, 0.1 do
				local invJ = 1 - j
				local lifespans = AnimCurve:new(linearInterpolator1)

				for i = 1, 20 do
					local lifespan = i * 100
					local normalSpeed, _ = getParticleSystemAverageSpeed(self.currentParticleSystem.geometry)
					local gravity = 7.17e-06
					local distance = normalSpeed * lifespan * invJ + gravity * lifespan * lifespan

					lifespans:addKeyframe({
						lifespan,
						time = distance
					})
				end

				table.insert(self.distanceToLifespans, lifespans)
			end
		end

		self.currentFillType = fillType
	end

	return success
end

function ParticleEffect:setMinMaxWidth(minValue, maxValue, reset)
	if self.useCuttingWidth then
		local widthX = math.abs(minValue - maxValue)
		local emitterShape = self.emitterShape
		local _, sy, sz = getScale(emitterShape)

		setScale(emitterShape, widthX, sy, sz)

		local _, y, z = getTranslation(emitterShape)

		setTranslation(emitterShape, -(maxValue - widthX * 0.5), y, z)
		ParticleUtil.setEmitCountScale(self.currentParticleSystem, widthX)

		self.totalWidth = widthX

		if self.isActive then
			ParticleUtil.setEmittingState(self.currentParticleSystem, widthX > 0)
		end
	end
end

function ParticleEffect:setDistance(distance, terrain)
	if self.currentParticleSystem ~= nil and not self.currentParticleSystem.forceFullLifespan then
		local _, dirY, _ = localDirectionToWorld(self.currentParticleSystem.emitterShape, 0, 1, 0)
		local direction = dirY / 1
		local index = math.floor(direction * #self.distanceToLifespans)
		local curve = self.distanceToLifespans[MathUtil.clamp(index, 1, #self.distanceToLifespans)]
		local lifespan = curve:get(distance + self.extraDistance)

		ParticleUtil.setParticleLifespan(self.currentParticleSystem, lifespan)
	end
end

function ParticleEffect:getIsFullyVisible()
	return self.realStartTime + self.startTimeMs < g_time and g_time < self.realStopTime + self.stopTimeMs
end
