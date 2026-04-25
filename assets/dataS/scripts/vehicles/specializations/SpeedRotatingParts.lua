SpeedRotatingParts = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function SpeedRotatingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadSpeedRotatingPartFromXML", SpeedRotatingParts.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSpeedRotatingPartActive", SpeedRotatingParts.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "getSpeedRotatingPartDirection", SpeedRotatingParts.getSpeedRotatingPartDirection)
	SpecializationUtil.registerFunction(vehicleType, "updateSpeedRotatingPart", SpeedRotatingParts.updateSpeedRotatingPart)
end

function SpeedRotatingParts.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", SpeedRotatingParts.validateWashableNode)
end

function SpeedRotatingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SpeedRotatingParts)
end

function SpeedRotatingParts:onLoad(savegame)
	local spec = self.spec_speedRotatingParts

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.speedRotatingParts.speedRotatingPart(0)#index", "vehicle.speedRotatingParts.speedRotatingPart(0)#node")

	spec.speedRotatingParts = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.speedRotatingParts.speedRotatingPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local speedRotatingPart = {}

		if self:loadSpeedRotatingPartFromXML(speedRotatingPart, self.xmlFile, baseName) then
			table.insert(spec.speedRotatingParts, speedRotatingPart)
		end

		i = i + 1
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function SpeedRotatingParts:onReadStream(streamId, connection)
	local spec = self.spec_speedRotatingParts

	for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
		if speedRotatingPart.versatileYRot then
			local yRot = streamReadUIntN(streamId, 9)
			speedRotatingPart.steeringAngle = yRot / 511 * math.pi * 2
		end
	end
end

function SpeedRotatingParts:onWriteStream(streamId, connection)
	local spec = self.spec_speedRotatingParts

	for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
		if speedRotatingPart.versatileYRot then
			streamWriteUIntN(streamId, MathUtil.clamp(math.floor(speedRotatingPart.steeringAngle / (math.pi * 2) * 511), 0, 511), 9)
		end
	end
end

function SpeedRotatingParts:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local spec = self.spec_speedRotatingParts
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
				if speedRotatingPart.versatileYRot then
					local yRot = streamReadUIntN(streamId, 9)
					speedRotatingPart.steeringAngle = yRot / 511 * math.pi * 2
				end
			end
		end
	end
end

function SpeedRotatingParts:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_speedRotatingParts

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
				if speedRotatingPart.versatileYRot then
					local yRot = speedRotatingPart.steeringAngle % (math.pi * 2)

					streamWriteUIntN(streamId, MathUtil.clamp(math.floor(yRot / (math.pi * 2) * 511), 0, 511), 9)
				end
			end
		end
	end
end

function SpeedRotatingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_speedRotatingParts

	for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
		local isPartActive = self:getIsSpeedRotatingPartActive(speedRotatingPart)

		if isPartActive or speedRotatingPart.lastSpeed ~= 0 and not speedRotatingPart.stopIfNotActive then
			self:updateSpeedRotatingPart(speedRotatingPart, dt, isPartActive)
		end
	end
end

function SpeedRotatingParts:loadSpeedRotatingPartFromXML(speedRotatingPart, xmlFile, key)
	speedRotatingPart.repr = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)
	speedRotatingPart.shaderNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#shaderNode"), self.i3dMappings)

	if speedRotatingPart.shaderNode ~= nil then
		speedRotatingPart.useShaderRotation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useRotation"), true)
		local scale = Utils.getNoNil(getXMLString(xmlFile, key .. "#scrollScale"), "1 0")
		speedRotatingPart.scrollScale = StringUtil.getVectorNFromString(scale, 2)
	end

	if speedRotatingPart.repr == nil and speedRotatingPart.shaderNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Invalid speedRotationPart node '%s' in '%s'", tostring(getXMLString(xmlFile, key .. "#node")), key)

		return false
	end

	speedRotatingPart.driveNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#driveNode"), self.i3dMappings), speedRotatingPart.repr)
	local componentIndex = getXMLInt(xmlFile, key .. "#refComponentIndex")

	if componentIndex ~= nil and self.components[componentIndex] ~= nil then
		speedRotatingPart.componentNode = self.components[componentIndex].node
	else
		local node = Utils.getNoNil(speedRotatingPart.driveNode, speedRotatingPart.shaderNode)
		speedRotatingPart.componentNode = self:getParentComponent(node)
	end

	speedRotatingPart.xDrive = 0
	local wheelIndex = getXMLInt(xmlFile, key .. "#wheelIndex")

	if wheelIndex ~= nil then
		if self.getWheels == nil then
			g_logManager:xmlWarning(self.configFileName, "wheelIndex for speedRotatingPart '%s' given, but no wheels loaded/defined", key)
		else
			local wheels = self:getWheels()
			local wheel = wheels[wheelIndex]

			if wheel == nil then
				g_logManager:xmlWarning(self.configFileName, "Invalid wheel index '%s' for speedRotatingPart '%s'", tostring(wheelIndex), key)

				return false
			end

			if not wheel.isSynchronized then
				g_logManager:xmlDevWarning(self.configFileName, "referenced wheel with index '%s' for speedRotatingPart '%s' is not synchronized in multiplayer", tostring(wheelIndex), key)
			end

			speedRotatingPart.wheel = wheel
			speedRotatingPart.lastWheelXRot = 0
		end
	end

	speedRotatingPart.dirRefNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#dirRefNode"), self.i3dMappings)
	speedRotatingPart.dirFrameNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#dirFrameNode"), self.i3dMappings)
	speedRotatingPart.alignDirection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#alignDirection"), false)
	speedRotatingPart.applySteeringAngle = Utils.getNoNil(getXMLBool(xmlFile, key .. "#applySteeringAngle"), false)
	speedRotatingPart.useWheelReprTranslation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useWheelReprTranslation"), true)
	speedRotatingPart.updateXDrive = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateXDrive"), true)
	speedRotatingPart.versatileYRot = Utils.getNoNil(getXMLBool(xmlFile, key .. "#versatileYRot"), false)

	if speedRotatingPart.versatileYRot and speedRotatingPart.repr == nil then
		g_logManager:xmlWarning(self.configFileName, "Versatile speedRotationPart '%s' does not support shaderNodes", key)

		return false
	end

	local minYRot = getXMLFloat(xmlFile, key .. "#minYRot")

	if minYRot ~= nil then
		speedRotatingPart.minYRot = math.rad(minYRot)
	end

	local maxYRot = getXMLFloat(xmlFile, key .. "#maxYRot")

	if maxYRot ~= nil then
		speedRotatingPart.maxYRot = math.rad(maxYRot)
	end

	speedRotatingPart.steeringAngle = 0
	speedRotatingPart.steeringAngleSent = 0
	speedRotatingPart.wheelScale = getXMLFloat(xmlFile, key .. "#wheelScale")

	if speedRotatingPart.wheelScale == nil then
		local baseRadius = 1
		local radius = 1

		if speedRotatingPart.wheel ~= nil then
			baseRadius = speedRotatingPart.wheel.radius
			radius = speedRotatingPart.wheel.radius
		end

		speedRotatingPart.wheelScale = baseRadius / Utils.getNoNil(getXMLFloat(xmlFile, key .. "#radius"), radius)
	end

	speedRotatingPart.wheelScaleBackup = speedRotatingPart.wheelScale
	speedRotatingPart.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(xmlFile, key .. "#onlyActiveWhenLowered"), false)
	speedRotatingPart.stopIfNotActive = Utils.getNoNil(getXMLBool(xmlFile, key .. "#stopIfNotActive"), false)
	speedRotatingPart.fadeOutTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#fadeOutTime"), 3) * 1000
	speedRotatingPart.activationSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#activationSpeed"), 1)
	speedRotatingPart.speedReferenceNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#speedReferenceNode"), self.i3dMappings)

	if speedRotatingPart.speedReferenceNode ~= nil and speedRotatingPart.speedReferenceNode == speedRotatingPart.driveNode then
		g_logManager:xmlWarning(self.configFileName, "Ignoring speedRotationPart '%s' because speedReferenceNode is identical with driveNode. Need to be different!", key)

		return false
	end

	speedRotatingPart.lastSpeed = 0
	speedRotatingPart.lastDir = 1

	return true
end

function SpeedRotatingParts:getIsSpeedRotatingPartActive(speedRotatingPart)
	if speedRotatingPart.onlyActiveWhenLowered then
		if self.getIsLowered ~= nil and not self:getIsLowered() then
			return false
		else
			return true
		end
	end

	return true
end

function SpeedRotatingParts:getSpeedRotatingPartDirection(speedRotatingPart)
	return 1
end

function SpeedRotatingParts:updateSpeedRotatingPart(speedRotatingPart, dt, isPartActive)
	local spec = self.spec_speedRotatingParts
	local speed = speedRotatingPart.lastSpeed
	local dir = speedRotatingPart.lastDir

	if speedRotatingPart.repr ~= nil then
		_, speedRotatingPart.steeringAngle, _ = getRotation(speedRotatingPart.repr)
	end

	if isPartActive then
		if speedRotatingPart.wheel ~= nil then
			local rotDiff = speedRotatingPart.wheel.netInfo.xDrive - speedRotatingPart.lastWheelXRot

			if math.pi < rotDiff then
				rotDiff = rotDiff - 2 * math.pi
			elseif rotDiff < -math.pi then
				rotDiff = rotDiff + 2 * math.pi
			end

			speed = math.abs(rotDiff)
			dir = MathUtil.sign(rotDiff)
			speedRotatingPart.lastWheelXRot = speedRotatingPart.wheel.netInfo.xDrive
			_, speedRotatingPart.steeringAngle, _ = getRotation(speedRotatingPart.wheel.repr)
		elseif speedRotatingPart.speedReferenceNode ~= nil then
			local newX, newY, newZ = getWorldTranslation(speedRotatingPart.speedReferenceNode)

			if speedRotatingPart.lastPosition == nil then
				speedRotatingPart.lastPosition = {
					newX,
					newY,
					newZ
				}
			end

			local dx, dy, dz = worldDirectionToLocal(speedRotatingPart.speedReferenceNode, newX - speedRotatingPart.lastPosition[1], newY - speedRotatingPart.lastPosition[2], newZ - speedRotatingPart.lastPosition[3])
			speed = MathUtil.vector3Length(dx, dy, dz)

			if dz > 0.001 then
				dir = 1
			elseif dz < -0.001 then
				dir = -1
			else
				dir = 0
			end

			speedRotatingPart.lastPosition[3] = newZ
			speedRotatingPart.lastPosition[2] = newY
			speedRotatingPart.lastPosition[1] = newX
		else
			speed = self.lastSpeedReal * dt
			dir = self.movingDirection
		end

		speedRotatingPart.brakeForce = speed * dt / speedRotatingPart.fadeOutTime
	else
		speed = math.max(speed - speedRotatingPart.brakeForce, 0)
	end

	speedRotatingPart.lastSpeed = speed
	speedRotatingPart.lastDir = dir

	if speedRotatingPart.updateXDrive then
		speedRotatingPart.xDrive = speedRotatingPart.xDrive + speed * dir * self:getSpeedRotatingPartDirection(speedRotatingPart) * speedRotatingPart.wheelScale
	end

	if speedRotatingPart.versatileYRot then
		if speed > 0.0017 and self.isServer and speedRotatingPart.activationSpeed < self:getLastSpeed(true) then
			local posX, posY, posZ = localToLocal(speedRotatingPart.repr, speedRotatingPart.componentNode, 0, 0, 0)
			speedRotatingPart.steeringAngle = Utils.getVersatileRotation(speedRotatingPart.repr, speedRotatingPart.componentNode, dt, posX, posY, posZ, speedRotatingPart.steeringAngle, speedRotatingPart.minYRot, speedRotatingPart.maxYRot)

			if math.abs(speedRotatingPart.steeringAngleSent - speedRotatingPart.steeringAngle) > 0.1 then
				speedRotatingPart.steeringAngleSent = speedRotatingPart.steeringAngle

				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		end
	else
		if speedRotatingPart.componentNode ~= nil and speedRotatingPart.dirRefNode ~= nil and not speedRotatingPart.alignDirection then
			speedRotatingPart.steeringAngle = Utils.getYRotationBetweenNodes(speedRotatingPart.componentNode, speedRotatingPart.dirRefNode)
			local _, yTrans, _ = localToLocal(speedRotatingPart.driveNode, speedRotatingPart.wheel.driveNode, 0, 0, 0)

			setTranslation(speedRotatingPart.driveNode, 0, yTrans, 0)
		end

		if speedRotatingPart.dirRefNode ~= nil and speedRotatingPart.alignDirection then
			local upX, upY, upZ = localDirectionToWorld(speedRotatingPart.dirFrameNode, 0, 1, 0)
			local dirX, dirY, dirZ = localDirectionToWorld(speedRotatingPart.dirRefNode, 0, 0, 1)

			I3DUtil.setWorldDirection(speedRotatingPart.repr, dirX, dirY, dirZ, upX, upY, upZ, 2)

			if speedRotatingPart.wheel ~= nil and speedRotatingPart.useWheelReprTranslation then
				local _, yTrans, _ = localToLocal(speedRotatingPart.wheel.driveNode, getParent(speedRotatingPart.repr), 0, 0, 0)

				setTranslation(speedRotatingPart.repr, 0, yTrans, 0)
			end
		end
	end

	if speedRotatingPart.driveNode ~= nil then
		if speedRotatingPart.repr == speedRotatingPart.driveNode then
			local steeringAngle = speedRotatingPart.steeringAngle

			if not speedRotatingPart.applySteeringAngle then
				steeringAngle = 0
			end

			setRotation(speedRotatingPart.repr, speedRotatingPart.xDrive, steeringAngle, 0)
		else
			if not speedRotatingPart.alignDirection and (speedRotatingPart.versatileYRot or speedRotatingPart.applySteeringAngle) then
				setRotation(speedRotatingPart.repr, 0, speedRotatingPart.steeringAngle, 0)
			end

			setRotation(speedRotatingPart.driveNode, speedRotatingPart.xDrive, 0, 0)
		end
	end

	if speedRotatingPart.shaderNode ~= nil then
		if speedRotatingPart.useShaderRotation then
			setShaderParameter(speedRotatingPart.shaderNode, "offsetUV", 0, 0, speedRotatingPart.xDrive, 0, false)
		else
			local pos = speedRotatingPart.xDrive % math.pi / (2 * math.pi)

			setShaderParameter(speedRotatingPart.shaderNode, "offsetUV", pos * speedRotatingPart.scrollScale[1], pos * speedRotatingPart.scrollScale[2], 0, 0, false)
		end
	end
end

function SpeedRotatingParts:validateWashableNode(superFunc, node)
	local spec = self.spec_speedRotatingParts

	for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
		if speedRotatingPart.wheel ~= nil then
			local speedRotatingPartsNodes = {}

			if speedRotatingPart.repr ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.repr, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPart.shaderNode ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.shaderNode, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPart.driveNode ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.driveNode, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPartsNodes[node] ~= nil then
				return false, self.updateWheelDirtAmount, speedRotatingPart.wheel, {
					wheel = speedRotatingPart.wheel,
					fieldDirtMultiplier = speedRotatingPart.wheel.fieldDirtMultiplier,
					streetDirtMultiplier = speedRotatingPart.wheel.streetDirtMultiplier,
					minDirtPercentage = speedRotatingPart.wheel.minDirtPercentage
				}
			end
		end
	end

	return superFunc(self, node)
end
