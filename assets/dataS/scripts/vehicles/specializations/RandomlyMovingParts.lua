RandomlyMovingParts = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function RandomlyMovingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRandomlyMovingPartFromXML", RandomlyMovingParts.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateRandomlyMovingPart", RandomlyMovingParts.updateRandomlyMovingPart)
	SpecializationUtil.registerFunction(vehicleType, "updateRotationTargetValues", RandomlyMovingParts.updateRotationTargetValues)
	SpecializationUtil.registerFunction(vehicleType, "getIsRandomlyMovingPartActive", RandomlyMovingParts.getIsRandomlyMovingPartActive)
end

function RandomlyMovingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RandomlyMovingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RandomlyMovingParts)
end

function RandomlyMovingParts:onLoad(savegame)
	local spec = self.spec_randomlyMovingParts
	spec.nodes = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.randomlyMovingParts.randomlyMovingPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local randomlyMovingPart = {}

		if self:loadRandomlyMovingPartFromXML(randomlyMovingPart, self.xmlFile, baseName) then
			table.insert(spec.nodes, randomlyMovingPart)
		end

		i = i + 1
	end
end

function RandomlyMovingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_randomlyMovingParts

	for _, part in pairs(spec.nodes) do
		self:updateRandomlyMovingPart(part, dt)
	end
end

function RandomlyMovingParts:loadRandomlyMovingPartFromXML(part, xmlFile, key)
	if not hasXMLProperty(self.xmlFile, key) then
		return false
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node == nil then
		g_logManager:xmlWarning(self.configFileName, "Unknown node for randomlyMovingPart in '%s'", key)

		return false
	end

	part.node = node

	if self.getGroundReferenceNodeFromIndex ~= nil then
		local refNodeIndex = getXMLInt(xmlFile, key .. "#refNodeIndex")

		if refNodeIndex ~= nil then
			if refNodeIndex ~= 0 then
				local groundReferenceNode = self:getGroundReferenceNodeFromIndex(refNodeIndex)

				if groundReferenceNode ~= nil then
					part.groundReferenceNode = groundReferenceNode
				end
			else
				g_logManager:xmlWarning(self.configFileName, "Unknown ground reference node in '%s'! Indices start with '0'", key .. "#refNodeIndex")
			end
		end
	end

	local rx, ry, rz = getRotation(part.node)
	local rotMean = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotMean"), 2)

	if rotMean then
		part.rotOrig = {
			rx,
			ry,
			rz
		}
		part.rotCur = {
			rx,
			ry,
			rz
		}
		part.rotAxis = getXMLInt(xmlFile, key .. "#rotAxis")
		part.rotMean = rotMean
		part.rotVar = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotVariance"), 2)
		part.rotTimeMean = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#rotTimeMean"), 2)
		part.rotTimeVar = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#rotTimeVariance"), 2)
		part.pauseMean = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#pauseMean"), 2)
		part.pauseVar = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#pauseVariance"), 2)

		for i = 1, 2 do
			part.rotTimeMean[i] = part.rotTimeMean[i] * 1000
			part.rotTimeVar[i] = part.rotTimeVar[i] * 1000
			part.pauseMean[i] = part.pauseMean[i] * 1000
			part.pauseVar[i] = part.pauseVar[i] * 1000
		end

		part.rotTarget = {}
		part.rotSpeed = {}
		part.pause = {}
		part.isSpeedDependent = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isSpeedDependent"), false)

		self:updateRotationTargetValues(part)
	end

	part.nextMoveTime = g_currentMission.time + part.pause[2]
	part.curMoveDirection = 1
	part.isActive = true

	return true
end

function RandomlyMovingParts:updateRandomlyMovingPart(part, dt)
	if part.nextMoveTime < g_currentMission.time then
		local speed = dt

		if part.isSpeedDependent then
			speed = speed * math.min(self:getLastSpeed() / self:getSpeedLimit(true), 1)
		end

		part.isActive = self:getIsRandomlyMovingPartActive(part)

		if part.curMoveDirection > 0 then
			if part.isActive then
				part.rotCur[part.rotAxis] = math.min(part.rotTarget[1], part.rotCur[part.rotAxis] + part.rotSpeed[1] * speed)

				if part.rotCur[part.rotAxis] == part.rotTarget[1] then
					part.curMoveDirection = -1
					part.nextMoveTime = g_currentMission.time + part.pause[1]
				end
			end
		else
			part.rotCur[part.rotAxis] = math.max(part.rotTarget[2], part.rotCur[part.rotAxis] + part.rotSpeed[2] * speed)

			if part.rotCur[part.rotAxis] == part.rotTarget[2] and part.isActive then
				part.curMoveDirection = 1
				part.nextMoveTime = g_currentMission.time + part.pause[2]

				self:updateRotationTargetValues(part)
			end
		end

		setRotation(part.node, part.rotCur[1], part.rotCur[2], part.rotCur[3])

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(part.node)
		end

		return true
	else
		return false
	end
end

function RandomlyMovingParts:updateRotationTargetValues(part)
	for i = 1, 2 do
		part.rotTarget[i] = part.rotMean[i] + part.rotVar[i] * (-0.5 + math.random())
	end

	for i = 1, 2 do
		local rotTime = part.rotTimeMean[i] + part.rotTimeVar[i] * (-0.5 + math.random())

		if i == 1 then
			part.rotSpeed[i] = (part.rotTarget[1] - part.rotTarget[2]) / rotTime
		else
			part.rotSpeed[i] = (part.rotTarget[2] - part.rotTarget[1]) / rotTime
		end
	end

	for i = 1, 2 do
		part.pause[i] = part.pauseMean[i] + part.pauseVar[i] * (-0.5 + math.random())
	end
end

function RandomlyMovingParts:getIsRandomlyMovingPartActive(part)
	local retValue = true

	if part.groundReferenceNode ~= nil then
		retValue = self:getIsGroundReferenceNodeActive(part.groundReferenceNode)
	end

	return retValue
end
