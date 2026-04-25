WoodCrusher = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
}

function WoodCrusher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onCrushedSplitShape", WoodCrusher.onCrushedSplitShape)
end

function WoodCrusher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", WoodCrusher.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", WoodCrusher.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", WoodCrusher.getCanBeTurnedOn)
end

function WoodCrusher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", WoodCrusher)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", WoodCrusher)
end

function WoodCrusher:onLoad(savegame)
	local spec = self.spec_woodCrusher

	WoodCrusher.loadWoodCrusher(self, spec, self.xmlFile, self.components)

	local moveColDisableCollisionPairs = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.woodCrusher#moveColDisableCollisionPairs"), true)

	if moveColDisableCollisionPairs then
		for _, component in pairs(self.components) do
			for _, node in pairs(spec.moveColNodes) do
				setPairCollision(component.node, node, false)
			end
		end
	end

	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.woodCrusher#fillUnitIndex"), 1)
end

function WoodCrusher:onDelete()
	WoodCrusher.deleteWoodCrusher(self, self.spec_woodCrusher)
end

function WoodCrusher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_woodCrusher

		if streamReadBool(streamId) then
			spec.crushingTime = 1000
		else
			spec.crushingTime = 0
		end
	end
end

function WoodCrusher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_woodCrusher

		streamWriteBool(streamId, spec.crushingTime > 0)
	end
end

function WoodCrusher:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	WoodCrusher.updateWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())
end

function WoodCrusher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	WoodCrusher.updateTickWoodCrusher(self, self.spec_woodCrusher, dt, self:getIsTurnedOn())

	local spec = self.spec_woodCrusher

	if self.isServer and g_currentMission.missionInfo.automaticMotorStartEnabled and spec.turnOnAutomatically and self.setIsTurnedOn ~= nil then
		if next(spec.moveTriggerNodes) ~= nil then
			if self.getIsMotorStarted ~= nil then
				if not self:getIsMotorStarted() then
					self:startMotor()
				end
			elseif self.attacherVehicle ~= nil and self.attacherVehicle.getIsMotorStarted ~= nil and not self.attacherVehicle:getIsMotorStarted() then
				self.attacherVehicle:startMotor()
			end

			if not self.isControlled and not self:getIsTurnedOn() and self:getCanBeTurnedOn() then
				self:setIsTurnedOn(true)
			end

			spec.turnOffTimer = 3000
		elseif self:getIsTurnedOn() then
			if spec.turnOffTimer == nil then
				spec.turnOffTimer = 3000
			end

			spec.turnOffTimer = spec.turnOffTimer - dt

			if spec.turnOffTimer < 0 then
				local rootAttacherVehicle = self:getRootVehicle()

				if not rootAttacherVehicle.isControlled then
					if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
						self:stopMotor()
					end

					self:setIsTurnedOn(false)
				end
			end
		end
	end
end

function WoodCrusher:onTurnedOn()
	WoodCrusher.turnOnWoodCrusher(self, self.spec_woodCrusher)
end

function WoodCrusher:onTurnedOff()
	WoodCrusher.turnOffWoodCrusher(self, self.spec_woodCrusher)
end

function WoodCrusher:getCanBeTurnedOn(superFunc)
	local spec = self.spec_woodCrusher

	if spec.turnOnAutomatically then
		return false
	end

	return superFunc(self)
end

function WoodCrusher:getDirtMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_woodCrusher

	if spec.crushingTime > 0 then
		multiplier = multiplier + self:getWorkDirtMultiplier()
	end

	return multiplier
end

function WoodCrusher:getWearMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_woodCrusher

	if spec.crushingTime > 0 then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function WoodCrusher:onCrushedSplitShape(splitType, volume)
	local spec = self.spec_woodCrusher

	self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, volume * 1000 * splitType.woodChipsPerLiter, FillType.WOODCHIPS, ToolType.UNDEFINED)
end

function WoodCrusher:loadWoodCrusher(woodCrusher, xmlFile, rootNode)
	woodCrusher.vehicle = self
	woodCrusher.woodCrusherSplitShapeCallback = WoodCrusher.woodCrusherSplitShapeCallback
	woodCrusher.woodCrusherMoveTriggerCallback = WoodCrusher.woodCrusherMoveTriggerCallback
	local xmlRoot = getXMLRootName(xmlFile)

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusher.moveTrigger(0)#index", xmlRoot .. ".woodCrusher.moveTriggers.trigger#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusher.moveCollision(0)#index", xmlRoot .. ".woodCrusher.moveCollisions.collision#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusher.emitterShape(0)", xmlRoot .. ".woodCrusher.crushEffects with effectClass 'ParticleEffect'")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusherStartSound", xmlRoot .. ".woodCrusher.sounds.start")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusherIdleSound", xmlRoot .. ".woodCrusher.sounds.idle")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusherWorkSound", xmlRoot .. ".woodCrusher.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".woodCrusherStopSound", xmlRoot .. ".woodCrusher.sounds.stop")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".turnedOnRotationNodes.turnedOnRotationNode#type", xmlRoot .. ".woodCrusher.animationNodes.animationNode", "woodCrusher")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, xmlRoot .. ".turnedOnScrollers.turnedOnScroller", xmlRoot .. ".woodCrusher.animationNodes.animationNode")

	local baseKey = xmlRoot .. ".woodCrusher"
	woodCrusher.cutNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, baseKey .. "#cutNode"), self.i3dMappings)
	woodCrusher.mainDrumRefNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, baseKey .. "#mainDrumRefNode"), self.i3dMappings)
	woodCrusher.moveTriggers = {}
	local i = 0

	while true do
		local key = string.format("%s.moveTriggers.trigger(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local node = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

		if node ~= nil then
			table.insert(woodCrusher.moveTriggers, node)
		end

		i = i + 1
	end

	woodCrusher.moveColNodes = {}
	i = 0

	while true do
		local key = string.format("%s.moveCollisions.collision(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local node = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

		if node ~= nil then
			table.insert(woodCrusher.moveColNodes, node)
		end

		i = i + 1
	end

	woodCrusher.moveVelocityZ = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#moveVelocityZ"), 0.8)
	woodCrusher.moveMaxForce = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#moveMaxForce"), 7)
	woodCrusher.downForceNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, baseKey .. "#downForceNode"), self.i3dMappings)
	woodCrusher.downForce = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#downForce"), 2)
	woodCrusher.cutSizeY = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#cutSizeY"), 1)
	woodCrusher.cutSizeZ = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#cutSizeZ"), 1)
	woodCrusher.moveTriggerNodes = {}

	if self.isServer and woodCrusher.moveTriggers ~= nil then
		for _, node in pairs(woodCrusher.moveTriggers) do
			addTrigger(node, "woodCrusherMoveTriggerCallback", woodCrusher)
		end
	end

	woodCrusher.crushNodes = {}
	woodCrusher.crushingTime = 0
	woodCrusher.turnOnAutomatically = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#automaticallyTurnOn"), false)

	if self.isClient then
		woodCrusher.crushEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".crushEffects", rootNode, self, self.i3dMappings)
		woodCrusher.animationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".animationNodes", rootNode, self, self.i3dMappings)
		woodCrusher.isWorkSamplePlaying = false
		woodCrusher.samples = {
			start = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "start", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "stop", self.baseDirectory, rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "work", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			idle = g_soundManager:loadSampleFromXML(xmlFile, baseKey .. ".sounds", "idle", self.baseDirectory, rootNode, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function WoodCrusher:deleteWoodCrusher(woodCrusher)
	if self.isServer and woodCrusher.moveTriggers ~= nil then
		for _, node in pairs(woodCrusher.moveTriggers) do
			removeTrigger(node)
		end
	end

	if self.isClient then
		g_effectManager:deleteEffects(woodCrusher.crushEffects)
		g_soundManager:deleteSamples(woodCrusher.samples)
		g_animationManager:deleteAnimations(woodCrusher.animationNodes)
	end
end

function WoodCrusher:updateWoodCrusher(woodCrusher, dt, isTurnedOn)
	if isTurnedOn and self.isServer then
		for node in pairs(woodCrusher.crushNodes) do
			WoodCrusher.crushSplitShape(self, woodCrusher, node)

			woodCrusher.crushNodes[node] = nil
			woodCrusher.moveTriggerNodes[node] = nil
		end

		local x, y, z = getTranslation(woodCrusher.mainDrumRefNode)
		local _ = 0
		local ty = 0
		local _ = 0
		local maxTreeSizeY = 0

		for id in pairs(woodCrusher.moveTriggerNodes) do
			if not entityExists(id) then
				woodCrusher.moveTriggerNodes[id] = nil
			elseif woodCrusher.downForceNode ~= nil then
				local x, y, z = getWorldTranslation(woodCrusher.downForceNode)
				local nx, ny, nz = localDirectionToWorld(woodCrusher.downForceNode, 1, 0, 0)
				local yx, yy, yz = localDirectionToWorld(woodCrusher.downForceNode, 0, 1, 0)
				local minY, maxY, minZ, maxZ = testSplitShape(id, x, y, z, nx, ny, nz, yx, yy, yz, woodCrusher.cutSizeY, woodCrusher.cutSizeZ)

				if minY ~= nil then
					local cx, cy, cz = localToWorld(woodCrusher.downForceNode, 0, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
					local downX, downY, downZ = localDirectionToWorld(woodCrusher.downForceNode, 0, -woodCrusher.downForce, 0)

					addForce(id, downX, downY, downZ, cx, cy, cz, false)

					if woodCrusher.mainDrumRefNode ~= nil then
						maxTreeSizeY = math.max(maxTreeSizeY, maxY)
					end
				end
			end
		end

		if woodCrusher.mainDrumRefNode ~= nil then
			if maxTreeSizeY > 0 then
				local a, b, c = localToWorld(woodCrusher.downForceNode, 0, maxTreeSizeY, 0)
				_, ty, _ = worldToLocal(getParent(woodCrusher.mainDrumRefNode), a, b, c)
			end

			if y < ty then
				y = math.min(y + 0.0003 * dt, ty)
			else
				y = math.max(y - 0.0003 * dt, ty)
			end

			setTranslation(woodCrusher.mainDrumRefNode, x, y, z)
		end

		if next(woodCrusher.moveTriggerNodes) ~= nil or woodCrusher.crushingTime > 0 then
			self:raiseActive()
		end
	end
end

function WoodCrusher:updateTickWoodCrusher(woodCrusher, dt, isTurnedOn)
	if isTurnedOn and self.isServer and woodCrusher.cutNode ~= nil and next(woodCrusher.moveTriggerNodes) ~= nil then
		local x, y, z = getWorldTranslation(woodCrusher.cutNode)
		local nx, ny, nz = localDirectionToWorld(woodCrusher.cutNode, 1, 0, 0)
		local yx, yy, yz = localDirectionToWorld(woodCrusher.cutNode, 0, 1, 0)

		for id in pairs(woodCrusher.moveTriggerNodes) do
			local lenBelow, lenAbove = getSplitShapePlaneExtents(id, x, y, z, nx, ny, nz)

			if lenAbove ~= nil and lenBelow ~= nil then
				if lenBelow <= 0.4 then
					woodCrusher.moveTriggerNodes[id] = nil

					WoodCrusher.crushSplitShape(self, woodCrusher, id)
				elseif lenAbove >= 0.2 then
					local minY = splitShape(id, x, y, z, nx, ny, nz, yx, yy, yz, woodCrusher.cutSizeY, woodCrusher.cutSizeZ, "woodCrusherSplitShapeCallback", woodCrusher)

					if minY ~= nil then
						woodCrusher.moveTriggerNodes[id] = nil
					end
				end
			end
		end
	end

	if woodCrusher.crushingTime > 0 then
		woodCrusher.crushingTime = math.max(woodCrusher.crushingTime - dt, 0)
	end

	local isCrushing = woodCrusher.crushingTime > 0

	if self.isClient then
		if isCrushing then
			g_effectManager:setFillType(woodCrusher.crushEffects, FillType.WOODCHIPS)
			g_effectManager:startEffects(woodCrusher.crushEffects)
		else
			g_effectManager:stopEffects(woodCrusher.crushEffects)
		end

		if isTurnedOn and isCrushing then
			if not woodCrusher.isWorkSamplePlaying then
				g_soundManager:playSample(woodCrusher.samples.work)

				woodCrusher.isWorkSamplePlaying = true
			end
		elseif woodCrusher.isWorkSamplePlaying then
			g_soundManager:stopSample(woodCrusher.samples.work)

			woodCrusher.isWorkSamplePlaying = false
		end
	end
end

function WoodCrusher:turnOnWoodCrusher(woodCrusher)
	if self.isServer and woodCrusher.moveColNodes ~= nil then
		for _, node in pairs(woodCrusher.moveColNodes) do
			setFrictionVelocity(node, woodCrusher.moveVelocityZ)
		end
	end

	if self.isClient then
		g_soundManager:stopSamples(woodCrusher.samples)

		woodCrusher.isWorkSamplePlaying = false

		g_soundManager:playSample(woodCrusher.samples.start)
		g_soundManager:playSample(woodCrusher.samples.idle, 0, woodCrusher.samples.start)

		if self.isClient then
			g_animationManager:startAnimations(woodCrusher.animationNodes)
		end
	end
end

function WoodCrusher:turnOffWoodCrusher(woodCrusher)
	if self.isServer then
		for node in pairs(woodCrusher.crushNodes) do
			WoodCrusher.crushSplitShape(self, woodCrusher, node)

			woodCrusher.crushNodes[node] = nil
		end

		if woodCrusher.moveColNodes ~= nil then
			for _, node in pairs(woodCrusher.moveColNodes) do
				setFrictionVelocity(node, 0)
			end
		end
	end

	if self.isClient then
		g_effectManager:stopEffects(woodCrusher.crushEffects)
		g_soundManager:stopSamples(woodCrusher.samples)
		g_soundManager:playSample(woodCrusher.samples.stop)

		woodCrusher.isWorkSamplePlaying = false

		if self.isClient then
			g_animationManager:stopAnimations(woodCrusher.animationNodes)
		end
	end
end

function WoodCrusher:crushSplitShape(woodCrusher, shape)
	local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(shape))

	if splitType ~= nil and splitType.woodChipsPerLiter > 0 then
		local volume = getVolume(shape)

		delete(shape)

		woodCrusher.crushingTime = 1000

		self:onCrushedSplitShape(splitType, volume)
	end
end

function WoodCrusher:woodCrusherSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	if not isBelow then
		self.crushNodes[shape] = shape
	end
end

function WoodCrusher:woodCrusherMoveTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local vehicle = g_currentMission.nodeToObject[otherActorId]

	if vehicle == nil and getRigidBodyType(otherActorId) == "Dynamic" then
		local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(otherActorId))

		if splitType ~= nil and splitType.woodChipsPerLiter > 0 then
			if onEnter then
				self.moveTriggerNodes[otherActorId] = Utils.getNoNil(self.moveTriggerNodes[otherActorId], 0) + 1

				self.vehicle:raiseActive()
			elseif onLeave then
				local c = self.moveTriggerNodes[otherActorId]

				if c ~= nil then
					c = c - 1

					if c == 0 then
						self.moveTriggerNodes[otherActorId] = nil
					else
						self.moveTriggerNodes[otherActorId] = c
					end
				end
			end
		end
	end
end
