AITurnStrategy = {
	COLLISION_BOX_COLOR_OK = {
		0,
		1,
		0
	},
	COLLISION_BOX_COLOR_HIT = {
		1,
		0,
		0
	},
	SLOPE_DETECTION_THRESHOLD = math.tan(math.rad(30)),
	DENSITY_HEIGHT_THRESHOLD = 2
}
local AITurnStrategy_mt = Class(AITurnStrategy)

function AITurnStrategy:new(customMt)
	if customMt == nil then
		customMt = AITurnStrategy_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.isTurning = false
	self.turnLeft = nil
	self.collisionDetected = false
	self.usesExtraStraight = false
	self.distanceToCollision = 5
	self.turnSegments = {}
	self.lastValidTurnPositionOffset = 0
	self.corridorPositionOffset = 0
	self.strategyName = "AITurnStrategy"
	self.leftBox = self:createTurningSizeBox()
	self.rightBox = self:createTurningSizeBox()
	self.heightChecks = {}

	table.insert(self.heightChecks, {
		1,
		1
	})
	table.insert(self.heightChecks, {
		-1,
		1
	})
	table.insert(self.heightChecks, {
		1,
		-1
	})
	table.insert(self.heightChecks, {
		-1,
		-1
	})

	self.numHeightChecks = 4

	return self
end

function AITurnStrategy:delete()
end

function AITurnStrategy:setAIVehicle(vehicle, parent)
	self.vehicle = vehicle
	self.vehicleDirectionNode = self.vehicle:getAIVehicleDirectionNode()
	self.vehicleAISteeringNode = self.vehicle:getAIVehicleSteeringNode()
	self.vehicleAIReverserNode = self.vehicle:getAIVehicleReverserNode()
	self.reverserDirectionNode = AIVehicleUtil.getAIToolReverserDirectionNode(self.vehicle)
	self.parent = parent

	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end
end

function AITurnStrategy:update(dt)
end

function AITurnStrategy:getDriveData(dt, vX, vY, vZ, turnData)
	local tX, tY, tZ = nil
	local maxSpeed = self.vehicle:getSpeedLimit()
	maxSpeed = math.min(14, maxSpeed)
	local distanceToStop = nil
	local segment = self.turnSegments[self.activeTurnSegmentIndex]
	local segmentIsFinished = false
	local moveForwards = segment.moveForward

	if segment.isCurve then
		local angleDirSign = MathUtil.sign(segment.endAngle - segment.startAngle)
		local curAngle = nil

		if self.reverserDirectionNode ~= nil and not moveForwards then
			curAngle = AITurnStrategy.getAngleInSegment(self.reverserDirectionNode, segment)
		else
			curAngle = AITurnStrategy.getAngleInSegment(self.vehicleAISteeringNode, segment)
		end

		local nextAngleDistance = math.max(3, 0.33 * self.vehicle.maxTurningRadius)
		local nextAngle = curAngle + angleDirSign * nextAngleDistance / segment.radius

		if math.pi < nextAngle then
			nextAngle = nextAngle - 2 * math.pi
		elseif nextAngle < -math.pi then
			nextAngle = nextAngle + 2 * math.pi
		end

		local endAngle = segment.endAngle

		if math.pi < endAngle then
			endAngle = endAngle - 2 * math.pi
		elseif endAngle < -math.pi then
			endAngle = endAngle + 2 * math.pi
		end

		angleDirSign = MathUtil.sign(segment.endAngle - segment.startAngle)
		local curAngleDiff = angleDirSign * (curAngle - endAngle)

		if math.rad(10) < curAngleDiff then
			curAngleDiff = curAngleDiff - 2 * math.pi
		elseif curAngleDiff < -2 * math.pi + math.rad(10) then
			curAngleDiff = curAngleDiff + 2 * math.pi
		end

		local nextAngleDiff = angleDirSign * (nextAngle - endAngle)

		if math.rad(10) < nextAngleDiff then
			nextAngleDiff = nextAngleDiff - 2 * math.pi
		elseif nextAngleDiff < -2 * math.pi + math.rad(10) then
			nextAngleDiff = nextAngleDiff + 2 * math.pi
		end

		local pX = math.cos(nextAngle) * segment.radius
		local pZ = math.sin(nextAngle) * segment.radius
		tX, tY, tZ = localToWorld(segment.o, pX, 0, pZ)
		distanceToStop = -curAngleDiff * segment.radius

		if distanceToStop < 0.01 or segment.usePredictionToSkipToNextSegment ~= false and nextAngleDiff > 0 then
			segmentIsFinished = true
		end

		if segment.checkForSkipToNextSegment then
			local nextSegment = self.turnSegments[self.activeTurnSegmentIndex + 1]
			local dirX = nextSegment.endPoint[1] - nextSegment.startPoint[1]
			local dirZ = nextSegment.endPoint[3] - nextSegment.startPoint[3]
			local dirLength = MathUtil.vector2Length(dirX, dirZ)
			local dx, _, _ = nil

			if self.reverserDirectionNode ~= nil and not moveForwards then
				dx, _, _ = worldDirectionToLocal(self.reverserDirectionNode, dirX / dirLength, 0, dirZ / dirLength)
			else
				dx, _, _ = worldDirectionToLocal(self.vehicleAISteeringNode, dirX / dirLength, 0, dirZ / dirLength)
			end

			local l = MathUtil.vector2Length(dirX, dirZ)
			dirZ = dirZ / l
			dirX = dirX / l
			pX, pZ = MathUtil.projectOnLine(vX, vZ, nextSegment.startPoint[1], nextSegment.startPoint[3], dirX, dirZ)
			local dist = MathUtil.vector2Length(vX - pX, vZ - pZ)
			local distToStart = MathUtil.vector2Length(vX - nextSegment.startPoint[1], vZ - nextSegment.startPoint[3])

			if dist < 1.5 and math.abs(dx) < 0.15 and distToStart < self.vehicle.sizeLength / 2 then
				segmentIsFinished = true
			end
		end

		if not moveForwards and self.reverserDirectionNode ~= nil then
			local x, _, z = worldToLocal(self.reverserDirectionNode, tX, vY, tZ)
			local alpha = Utils.getYRotationBetweenNodes(self.vehicleAISteeringNode, self.reverserDirectionNode)
			local ltX = math.cos(alpha) * x - math.sin(alpha) * z
			local ltZ = math.sin(alpha) * x + math.cos(alpha) * z
			ltX = -ltX
			tX, _, tZ = localToWorld(self.vehicleAISteeringNode, ltX, 0, ltZ)
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			drawDebugLine(vX, vY + 2, vZ, 1, 1, 0, tX, tY + 2, tZ, 1, 1, 0)
		end
	else
		local toolX, _, toolZ = nil

		if self.reverserDirectionNode ~= nil then
			toolX, _, toolZ = getWorldTranslation(self.reverserDirectionNode)
		end

		local dirX = segment.endPoint[1] - segment.startPoint[1]
		local dirZ = segment.endPoint[3] - segment.startPoint[3]
		local l = MathUtil.vector2Length(dirX, dirZ)
		dirZ = dirZ / l
		dirX = dirX / l
		local pX, pZ = nil

		if self.reverserDirectionNode ~= nil and not moveForwards then
			pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		elseif self.vehicleAIReverserNode ~= nil and not moveForwards then
			toolX, _, toolZ = getWorldTranslation(self.vehicleAIReverserNode)
			pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		else
			pX, pZ = MathUtil.projectOnLine(vX, vZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		end

		local factor = 1
		tX = pX + dirX * factor * self.vehicle.maxTurningRadius
		tZ = pZ + dirZ * factor * self.vehicle.maxTurningRadius

		if self.reverserDirectionNode ~= nil and not moveForwards then
			local x, _, z = worldToLocal(self.reverserDirectionNode, tX, vY, tZ)
			local alpha = Utils.getYRotationBetweenNodes(self.vehicleAISteeringNode, self.reverserDirectionNode)
			local articulatedAxisSpec = self.vehicle.spec_articulatedAxis

			if articulatedAxisSpec ~= nil and articulatedAxisSpec.componentJoint ~= nil then
				local node1 = self.vehicle.components[articulatedAxisSpec.componentJoint.componentIndices[1]].node
				local node2 = self.vehicle.components[articulatedAxisSpec.componentJoint.componentIndices[2]].node

				if articulatedAxisSpec.anchorActor == 1 then
					node2 = node1
					node1 = node2
				end

				local beta = Utils.getYRotationBetweenNodes(node1, node2)
				alpha = alpha - beta
			end

			local ltX = math.cos(alpha) * x - math.sin(alpha) * z
			local ltZ = math.sin(alpha) * x + math.cos(alpha) * z
			ltX = -ltX
			tX, _, tZ = localToWorld(self.vehicleAISteeringNode, ltX, 0, ltZ)
		end

		distanceToStop = MathUtil.vector3Length(segment.endPoint[1] - vX, segment.endPoint[2] - vY, segment.endPoint[3] - vZ)
		local _, _, lz = worldToLocal(self.vehicleAISteeringNode, segment.endPoint[1], segment.endPoint[2], segment.endPoint[3])

		if segment.moveForward and lz < 0 or not segment.moveForward and lz > 0 then
			segmentIsFinished = true
		end

		if segment.checkAlignmentToSkipSegment then
			local d1x, _, d1z = localDirectionToWorld(self.vehicleAISteeringNode, 0, 0, 1)
			local l1 = MathUtil.vector2Length(d1x, d1z)
			d1z = d1z / l1
			d1x = d1x / l1
			local a1 = math.acos(d1x * dirX + d1z * dirZ)
			local dist = MathUtil.vector2Length(vX - pX, vZ - pZ)
			local canSkip = math.deg(a1) < 8 and dist < 0.6

			if self.vehicle.spec_articulatedAxis ~= nil and self.vehicle.spec_articulatedAxis.componentJoint ~= nil then
				for i = 1, 2 do
					local node = self.vehicle.components[self.vehicle.spec_articulatedAxis.componentJoint.componentIndices[i]].node
					d1x, _, d1z = localDirectionToWorld(node, 0, 0, 1)
					l1 = MathUtil.vector2Length(d1x, d1z)
					d1z = d1z / l1
					d1x = d1x / l1
					local a = math.acos(d1x * dirX + d1z * dirZ)
					canSkip = canSkip and math.deg(a) < 8
				end
			end

			if self.reverserDirectionNode ~= nil then
				local d2x, _, d2z = localDirectionToWorld(self.reverserDirectionNode, 0, 0, 1)
				local l2 = MathUtil.vector2Length(d2x, d2z)
				d2z = d2z / l2
				d2x = d2x / l2
				local a2 = math.acos(d2x * dirX + d2z * dirZ)
				pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
				dist = MathUtil.vector2Length(toolX - pX, toolZ - pZ)
				canSkip = canSkip and math.deg(a2) < 6 and dist < 0.6
			end

			local nextSegment = self.turnSegments[self.activeTurnSegmentIndex + 1]
			local _, _, sz = worldToLocal(self.vehicleDirectionNode, nextSegment.startPoint[1], nextSegment.startPoint[2], nextSegment.startPoint[3])
			local _, _, ez = worldToLocal(self.vehicleDirectionNode, nextSegment.endPoint[1], nextSegment.endPoint[2], nextSegment.endPoint[3])
			canSkip = canSkip and (sz < 0 or ez < 0)

			if canSkip then
				segmentIsFinished = true
			end
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local sY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, tX, vY, tZ)

			drawDebugLine(vX, vY + 2, vZ, 1, 1, 0, tX, sY + 2, tZ, 1, 1, 0)
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("active segment: %d", self.activeTurnSegmentIndex))
	end

	if segment.checkForValidArea then
		local lookAheadDist = 0
		local lookAheadSize = 1

		if not moveForwards then
			lookAheadSize = -1
		end

		if AIVehicleUtil.checkImplementListForValidGround(self.vehicle, lookAheadDist, lookAheadSize) then
			segmentIsFinished = true
			self.activeTurnSegmentIndex = #self.turnSegments
		end
	end

	if segment.findEndOfField then
		local lookAheadDist = 0
		local lookAheadSize = 1

		if not moveForwards then
			lookAheadSize = -1
		end

		if not AIVehicleUtil.checkImplementListForValidGround(self.vehicle, lookAheadDist, lookAheadSize) then
			segmentIsFinished = true
		end
	end

	if segmentIsFinished then
		self.activeTurnSegmentIndex = self.activeTurnSegmentIndex + 1

		if self.turnSegments[self.activeTurnSegmentIndex] == nil then
			self.isTurning = false

			return nil
		end
	end

	local totalSegmentLength = 0
	local usedSegmentDistance = 0

	for i, turnSegment in ipairs(self.turnSegments) do
		if turnSegment.checkAlignmentToSkipSegment then
			break
		end

		local segmentLength = nil

		if turnSegment.isCurve then
			segmentLength = math.abs(turnSegment.endAngle - turnSegment.startAngle) * turnSegment.radius
		else
			segmentLength = math.abs(MathUtil.vector3Length(turnSegment.endPoint[1] - turnSegment.startPoint[1], turnSegment.endPoint[2] - turnSegment.startPoint[2], turnSegment.endPoint[3] - turnSegment.startPoint[3]))
		end

		segmentLength = math.abs(segmentLength)
		totalSegmentLength = totalSegmentLength + segmentLength

		if i < self.activeTurnSegmentIndex then
			usedSegmentDistance = usedSegmentDistance + segmentLength
		elseif i == self.activeTurnSegmentIndex then
			usedSegmentDistance = usedSegmentDistance + segmentLength - distanceToStop
		end
	end

	local turnProgress = usedSegmentDistance / totalSegmentLength

	self.vehicle:aiTurnProgress(turnProgress, self.turnLeft)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("turn progress: %.1f%%", turnProgress * 100))
	end

	if not segment.slowDown then
		distanceToStop = math.huge
	end

	return tX, tZ, moveForwards, maxSpeed, distanceToStop
end

function AITurnStrategy:updateTurningSizeBox(box, turnLeft, turnData, distanceToTurn)
	box.center[3] = distanceToTurn / 2
	box.size[3] = distanceToTurn / 2
	box.size[2] = 5
	box.size[1] = 3
end

function AITurnStrategy:createTurningSizeBox()
	local box = {
		name = self.strategyName,
		center = {
			0,
			0,
			0
		},
		rotation = {
			0,
			0,
			0
		},
		size = {
			0,
			0,
			0
		}
	}

	return box
end

function AITurnStrategy:getDistanceToCollision(dt, vX, vY, vZ, turnData, lookAheadDistance)
	local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft
	local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight
	local distanceToTurn = lookAheadDistance

	if not allowLeft and not allowRight then
		distanceToTurn = -1
	elseif self.turnLeft ~= nil then
		if self.turnLeft and not allowRight or not self.turnLeft and not allowLeft then
			distanceToTurn = -1
		end
	else
		local allowLeftWithCol = allowLeft and self.collisionEndPosLeft == nil
		local allowRightWithCol = allowRight and self.collisionEndPosRight == nil

		if not allowLeftWithCol or not allowRightWithCol then
			local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)

			if allowLeftWithCol and leftAreaPercentage <= 3 * AIVehicleUtil.VALID_AREA_THRESHOLD then
				distanceToTurn = -1
			end

			if allowRightWithCol and rightAreaPercentage <= 3 * AIVehicleUtil.VALID_AREA_THRESHOLD then
				distanceToTurn = -1
			end
		end
	end

	if self.collisionDetected then
		if self.collisionDetectedPosX ~= nil then
			local dist = MathUtil.vector3Length(vX - self.collisionDetectedPosX, vY - self.collisionDetectedPosY, vZ - self.collisionDetectedPosZ)
			distanceToTurn = math.min(distanceToTurn, lookAheadDistance - dist)
		else
			distanceToTurn = -1
		end
	end

	self.distanceToCollision = distanceToTurn
	local boxLookBackDistance = 0

	if self.parent ~= nil and self.parent.rowStartTranslation ~= nil then
		local x, _, z = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())
		boxLookBackDistance = math.min(MathUtil.vector2Length(x - self.parent.rowStartTranslation[1], z - self.parent.rowStartTranslation[3]) * 0.66, 5)
	end

	local collisionHitLeft = false
	local collisionHitRight = false

	if (self.turnLeft == nil or self.turnLeft == false) and allowLeft then
		local turnLeft = true

		self:updateTurningSizeBox(self.leftBox, turnLeft, turnData, math.max(0, distanceToTurn))

		local box = self.leftBox
		box.center[3] = box.center[3] - boxLookBackDistance / 2
		box.size[3] = box.size[3] + boxLookBackDistance

		if not self:validateCollisionBox(box) then
			self.vehicle.stopAIVehicle(AIVehicle.STOP_REASON_UNKOWN)

			return distanceToTurn
		end

		collisionHitLeft = self:getIsBoxColliding(box)

		if collisionHitLeft and self.collisionEndPosLeft == nil then
			self.collisionEndPosLeft = {
				localToWorld(self.vehicleDirectionNode, 0, 0, box.size[3])
			}
		end
	end

	if (self.turnLeft == nil or self.turnLeft == true) and allowRight then
		local turnLeft = false

		self:updateTurningSizeBox(self.rightBox, turnLeft, turnData, math.max(0, distanceToTurn))

		local box = self.rightBox
		box.center[3] = box.center[3] - boxLookBackDistance / 2
		box.size[3] = box.size[3] + boxLookBackDistance

		if not self:validateCollisionBox(box) then
			self.vehicle.stopAIVehicle(AIVehicle.STOP_REASON_UNKOWN)

			return distanceToTurn
		end

		collisionHitRight = self:getIsBoxColliding(box)

		if collisionHitRight and self.collisionEndPosRight == nil then
			self.collisionEndPosRight = {
				localToWorld(self.vehicleDirectionNode, 0, 0, box.size[3])
			}
		end
	end

	self:evaluateCollisionHits(vX, vY, vZ, collisionHitLeft, collisionHitRight, turnData)

	return distanceToTurn
end

function AITurnStrategy:getIsBoxColliding(box)
	local vehicleDirectionNode = self.vehicleDirectionNode
	local hasCollision, minHeight, maxSlope, maxDensityHeight = getAIHelperCollisionBoxInfo(g_currentMission.terrainRootNode, vehicleDirectionNode, box.center[1], box.center[2], box.center[3], box.size[1], box.size[2], box.size[3], AIVehicleUtil.COLLISION_MASK)

	return hasCollision or minHeight < g_currentMission.waterY or AITurnStrategy.SLOPE_DETECTION_THRESHOLD < maxSlope or AITurnStrategy.DENSITY_HEIGHT_THRESHOLD <= maxDensityHeight
end

function AITurnStrategy:getCollisionBoxSlope(rootNode, x1, y1, z1, x2, y2, z2)
	x1, _, z1 = localToWorld(rootNode, x1, y1, z1)
	x2, _, z2 = localToWorld(rootNode, x2, y2, z2)
	local terrain1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
	local terrain2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)
	local length = MathUtil.vector2Length(x1 - x2, z1 - z2)
	local angleBetween = math.abs(terrain1 - terrain2) / length

	return angleBetween
end

function AITurnStrategy:validateCollisionBox(box)
	for i = 1, 3 do
		if box.center[i] ~= box.center[i] or box.rotation[i] ~= box.rotation[i] or box.size[i] ~= box.size[i] then
			return false
		end
	end

	return true
end

function AITurnStrategy:startTurn(driveStrategyStraight)
	local turnData = driveStrategyStraight.turnData
	self.isTurning = true

	for _, segment in pairs(self.turnSegments) do
		if segment.o ~= nil then
			delete(segment.o)
		end
	end

	self.turnSegments = {}
	self.turnSegmentsTotalLength = 0
	self.activeTurnSegmentIndex = 1
	local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft and driveStrategyStraight.gabAllowTurnLeft
	local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight and driveStrategyStraight.gabAllowTurnRight

	if not allowLeft and not allowRight then
		return false
	end

	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end

	local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		log(" --(I)--> self.turnLeft:", self.turnLeft, "leftAreaPercentage:", leftAreaPercentage, "rightAreaPercentage:", rightAreaPercentage)
	end

	if driveStrategyStraight.corridorDistance ~= nil then
		self.corridorPositionOffset = -driveStrategyStraight.corridorDistance
	end

	local function checkForLastValidPosition(vehicleNode, turnLeft, threshold)
		if turnLeft and not allowLeft then
			return false
		end

		if not turnLeft and not allowRight then
			return false
		end

		local position = driveStrategyStraight.lastValidTurnLeftPosition

		if not turnLeft then
			position = driveStrategyStraight.lastValidTurnRightPosition
		end

		if position[1] ~= 0 and position[2] ~= 0 and position[3] ~= 0 then
			local x, y, z = unpack(driveStrategyStraight.lastValidTurnCheckPosition)
			local distance = MathUtil.vector3Length(position[1] - x, position[2] - y, position[3] - z)

			if threshold < distance then
				self.lastValidTurnPositionOffset = -distance

				return true
			end
		end
	end

	if self.turnLeft == nil then
		local forcePreferLeft = self.collisionEndPosLeft == nil and self.collisionEndPosRight ~= nil
		local forcePreferRight = self.collisionEndPosRight == nil and self.collisionEndPosLeft ~= nil and allowRight and AIVehicleUtil.VALID_AREA_THRESHOLD < rightAreaPercentage
		local preferLeft = (rightAreaPercentage < leftAreaPercentage or forcePreferLeft) and not forcePreferRight

		if allowLeft and AIVehicleUtil.VALID_AREA_THRESHOLD < leftAreaPercentage and (preferLeft or not allowRight) then
			self.turnLeft = true

			checkForLastValidPosition(self.vehicleDirectionNode, true, 5)
		elseif allowRight and AIVehicleUtil.VALID_AREA_THRESHOLD < rightAreaPercentage then
			self.turnLeft = false

			checkForLastValidPosition(self.vehicleDirectionNode, false, 5)
		elseif not checkForLastValidPosition(self.vehicleDirectionNode, true, 5) then
			if not checkForLastValidPosition(self.vehicleDirectionNode, false, 5) then
				self:debugPrint("Stopping AIVehicle - no valid ground (I)")

				return false
			else
				self.turnLeft = false
			end
		else
			self.turnLeft = true
		end
	else
		self.turnLeft = not self.turnLeft

		if self.turnLeft then
			if not allowLeft or leftAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD then
				if not checkForLastValidPosition(self.vehicleDirectionNode, true, 5) then
					return false
				end
			else
				checkForLastValidPosition(self.vehicleDirectionNode, true, 5)
			end
		elseif not allowRight or rightAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD then
			if not checkForLastValidPosition(self.vehicleDirectionNode, false, 5) then
				return false
			end
		else
			checkForLastValidPosition(self.vehicleDirectionNode, false, 5)
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		log(" --(II)--> self.turnLeft:", self.turnLeft, "leftAreaPercentage:", leftAreaPercentage, "rightAreaPercentage:", rightAreaPercentage)
	end

	driveStrategyStraight.turnLeft = not self.turnLeft

	driveStrategyStraight:updateTurnData()

	driveStrategyStraight.turnLeft = nil
	local checkFrontDistance = 5
	self.vehicle.aiDriveDirection[2] = -self.vehicle.aiDriveDirection[2]
	self.vehicle.aiDriveDirection[1] = -self.vehicle.aiDriveDirection[1]
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local x = self.vehicle.aiDriveTarget[1]
	local z = self.vehicle.aiDriveTarget[2]
	local dirX = self.vehicle.aiDriveDirection[1]
	local dirZ = self.vehicle.aiDriveDirection[2]
	local sideDistance = 2 * sideOffset
	local sideDirX = -dirZ
	local sideDirY = dirX
	z = z + sideDirY * sideDistance
	x = x + sideDirX * sideDistance
	self.vehicle.aiDriveTarget[2] = z
	self.vehicle.aiDriveTarget[1] = x

	self.vehicle:aiStartTurn(self.turnLeft)

	return true
end

function AITurnStrategy:getZOffsetForTurn(box0)
	local box = {
		name = "ZoffsetForTurn",
		center = {
			box0.center[1],
			box0.center[2],
			box0.center[3]
		},
		size = {
			box0.size[1],
			box0.size[2],
			box0.size[3]
		}
	}
	local length = math.max(self.distanceToCollision + 2 * box0.size[3], 20)
	box.center[3] = length / 2
	box.size[3] = length / 2
	box.vFront = {
		localDirectionToWorld(self.vehicleDirectionNode, 0, 0, 1)
	}
	box.vLeft = {
		localDirectionToWorld(self.vehicleDirectionNode, 1, 0, 0)
	}
	local zOffset = self.distanceToCollision
	local i = 0

	while box.size[3] > 0.5 do
		self.collisionHit = self:getIsBoxColliding(box)

		if self.collisionHit then
			box.center[3] = box.center[3] - box.size[3] / 2
		else
			zOffset = box.center[3] + box.size[3]
			box.center[3] = box.center[3] + 3 * box.size[3] / 2
		end

		box.size[3] = box.size[3] / 2
		i = i + 1
	end

	return zOffset
end

function AITurnStrategy:startTurnFinalization()
	for _, segment in pairs(self.turnSegments) do
		if segment.startPoint ~= nil then
			segment.startPoint[2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, segment.startPoint[1], 0, segment.startPoint[3])
			segment.endPoint[2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, segment.endPoint[1], 0, segment.endPoint[3])
		elseif segment.o ~= nil then
			local x, y, z = getWorldTranslation(segment.o)
			y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

			setTranslation(segment.o, x, y, z)
		end
	end

	for _, segment in pairs(self.turnSegments) do
		if segment.startPoint ~= nil then
			segment.length = MathUtil.vector3Length(segment.endPoint[1] - segment.startPoint[1], segment.endPoint[2] - segment.startPoint[2], segment.endPoint[3] - segment.startPoint[3])
			self.turnSegmentsTotalLength = self.turnSegmentsTotalLength + segment.length
		else
			segment.length = math.rad(segment.endAngle - segment.startAngle) * segment.radius
			self.turnSegmentsTotalLength = self.turnSegmentsTotalLength + segment.length
		end
	end
end

function AITurnStrategy:onEndTurn(turnLeft)
	if #self.turnSegments > 0 then
		self.vehicle:aiEndTurn(self.turnLeft)
	end

	self.collisionDetected = false
	self.collisionEndPosLeft = nil
	self.collisionEndPosRight = nil
	self.collisionDetectedPosX = nil
	self.turnSegments = {}
	self.turnLeft = turnLeft

	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end
end

function AITurnStrategy.getAngleInSegment(node, segment, pos)
	if pos == nil then
		pos = {
			0,
			0,
			0
		}
	end

	local vX, _, vZ = localToLocal(node, segment.o, pos[1], pos[2], pos[3])

	return math.atan2(vZ, vX)
end

function AITurnStrategy.drawTurnSegments(segments)
	for i, segment in pairs(segments) do
		if segment.isCurve == true then
			local oX, oY, oZ = localToWorld(segment.o, 0, 2, 0)
			local xX, xY, xZ = localToWorld(segment.o, 2, 2, 0)
			local yX, yY, yZ = localToWorld(segment.o, 0, 4, 0)
			local zX, zY, zZ = localToWorld(segment.o, 0, 2, 2)

			drawDebugLine(oX, oY, oZ, 1, 0, 0, xX, xY, xZ, 1, 0, 0)
			drawDebugLine(oX, oY, oZ, 0, 1, 0, yX, yY, yZ, 0, 1, 0)
			drawDebugLine(oX, oY, oZ, 0, 0, 1, zX, zY, zZ, 0, 0, 1)
			Utils.renderTextAtWorldPosition(yX, yY, yZ, tostring(i), 0.02, 0)

			local ts = 20

			for i = 0, ts - 1 do
				local x1 = segment.radius * math.cos(segment.startAngle + i * (segment.endAngle - segment.startAngle) / ts)
				local z1 = segment.radius * math.sin(segment.startAngle + i * (segment.endAngle - segment.startAngle) / ts)
				local x2 = segment.radius * math.cos(segment.startAngle + (i + 1) * (segment.endAngle - segment.startAngle) / ts)
				local z2 = segment.radius * math.sin(segment.startAngle + (i + 1) * (segment.endAngle - segment.startAngle) / ts)
				local w1X, w1Y, w1Z = localToWorld(segment.o, x1, 0, z1)
				local w2X, w2Y, w2Z = localToWorld(segment.o, x2, 0, z2)
				local w1Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, w1X, w1Y, w1Z) + 1
				local w2Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, w2X, w2Y, w2Z) + 1

				drawDebugLine(w1X, w1Y, w1Z, (ts - i) / ts, i / ts, 0, w2X, w2Y, w2Z, (ts - i - 1) / ts, (i + 1) / ts, 0)
			end
		else
			local sY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, unpack(segment.startPoint)) + 1
			local eY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, unpack(segment.endPoint)) + 1

			drawDebugLine(segment.startPoint[1], sY, segment.startPoint[3], 1, 0, 0, segment.endPoint[1], eY, segment.endPoint[3], 0, 1, 0)
			drawDebugLine(segment.startPoint[1], sY, segment.startPoint[3], 1, 1, 1, segment.startPoint[1], sY + 2, segment.startPoint[3], 1, 1, 1)
			drawDebugLine(segment.endPoint[1], sY, segment.endPoint[3], 1, 1, 1, segment.endPoint[1], sY + 2, segment.endPoint[3], 1, 1, 1)
			Utils.renderTextAtWorldPosition((segment.startPoint[1] + segment.endPoint[1]) / 2, (sY + eY) / 2, (segment.startPoint[3] + segment.endPoint[3]) / 2, tostring(i), 0.02, 0)
		end
	end
end

function AITurnStrategy:collisionTestCallback(transformId)
	self.collisionHit = true

	return false
end

function AITurnStrategy:evaluateCollisionHits(vX, vY, vZ, collisionHitLeft, collisionHitRight, turnData)
	if not collisionHitLeft and self.collisionEndPosLeft ~= nil then
		local _, _, z = worldToLocal(self.vehicleDirectionNode, self.collisionEndPosLeft[1], self.collisionEndPosLeft[2], self.collisionEndPosLeft[3])

		if z < -1 then
			self.collisionEndPosLeft = nil
			self.collisionDetected = false
			self.collisionDetectedPosX = nil
		end
	end

	if not collisionHitRight and self.collisionEndPosRight ~= nil then
		local _, _, z = worldToLocal(self.vehicleDirectionNode, self.collisionEndPosRight[1], self.collisionEndPosRight[2], self.collisionEndPosRight[3])

		if z < -1 then
			self.collisionEndPosRight = nil
			self.collisionDetected = false
			self.collisionDetectedPosX = nil
		end
	end

	if self.turnLeft == nil then
		if collisionHitLeft or collisionHitRight then
			local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft
			local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight

			if collisionHitLeft and collisionHitRight then
				self.collisionDetected = true
			else
				local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)
				allowRight = allowRight and leftAreaPercentage <= rightAreaPercentage
				allowLeft = allowLeft and rightAreaPercentage <= leftAreaPercentage

				if collisionHitLeft and not allowRight then
					self.collisionDetected = true
					self.turnLeft = false
				elseif collisionHitRight and not allowLeft then
					self.collisionDetected = true
					self.turnLeft = true
				else
					self.turnLeft = collisionHitLeft
				end
			end
		end
	elseif self.turnLeft then
		if collisionHitRight then
			self.collisionDetected = true
		end
	elseif collisionHitLeft then
		self.collisionDetected = true
	end

	if self.collisionDetected and self.collisionDetectedPosX == nil then
		self.collisionDetectedPosZ = vZ
		self.collisionDetectedPosY = vY
		self.collisionDetectedPosX = vX
	end
end

function AITurnStrategy:checkCollisionInFront(turnData, lookAheadDistance)
	lookAheadDistance = lookAheadDistance or 5
	local maxX = turnData.sideOffsetLeft
	local minX = turnData.sideOffsetRight
	local maxZ = math.max(4, turnData.toolOverhang.front.zt)
	local box = {
		name = "checkCollisionInFront",
		center = {
			maxX - (maxX - minX) / 2,
			0,
			maxZ / 2 + lookAheadDistance / 2
		},
		rotation = {
			0,
			0,
			0
		},
		size = {
			(maxX - minX) / 2,
			5,
			maxZ / 2 + lookAheadDistance / 2
		}
	}
	self.collisionHit = self:getIsBoxColliding(box)

	return self.collisionHit
end

function AITurnStrategy:adjustHeightOfTurningSizeBox(box)
	local height = 10
	box.size[2] = height
	box.center[2] = 0
end

function AITurnStrategy:getNoFullCoverageZOffset()
	local offset = 0

	if AIVehicleUtil.getAttachedImplementsBlockTurnBackward(self.vehicle) then
		return 0
	end

	local attachedAIImplements = self.vehicle:getAttachedAIImplements()

	for _, implement in pairs(attachedAIImplements) do
		if implement.object:getAIHasNoFullCoverageArea() then
			local leftMarker, _, backMarker = implement.object:getAIMarkers()
			local _, _, markerZOffset = localToLocal(backMarker, leftMarker, 0, 0, 0)
			offset = offset + markerZOffset
		end
	end

	offset = offset + self.corridorPositionOffset
	offset = offset + self.lastValidTurnPositionOffset

	return offset
end

function AITurnStrategy:getVehicleToWorld(x, y, z, returnTable)
	x, y, z = localToWorld(self.vehicleDirectionNode, x, y, z + self:getNoFullCoverageZOffset())

	if returnTable then
		return {
			x,
			y,
			z
		}
	end

	return x, y, z
end

function AITurnStrategy:addNoFullCoverageSegment(turnSegments)
	local offset = self:getNoFullCoverageZOffset()

	if offset ~= 0 then
		local segment = {
			isCurve = false,
			moveForward = false,
			slowDown = true,
			startPoint = self:getVehicleToWorld(0, 0, -offset, true),
			endPoint = self:getVehicleToWorld(0, 0, 0, true)
		}

		table.insert(turnSegments, segment)
	end
end

function AITurnStrategy:debugPrint(text)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print(string.format("DEBUG: %s", text))
	end
end
