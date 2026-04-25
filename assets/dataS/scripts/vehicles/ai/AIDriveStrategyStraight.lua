AIDriveStrategyStraight = {}
local AIDriveStrategyStraight_mt = Class(AIDriveStrategyStraight, AIDriveStrategy)

function AIDriveStrategyStraight:new(customMt)
	if customMt == nil then
		customMt = AIDriveStrategyStraight_mt
	end

	local self = AIDriveStrategy:new(customMt)

	return self
end

function AIDriveStrategyStraight:delete()
	AIDriveStrategyStraight:superClass().delete(self)

	for _, implement in ipairs(self.vehicle:getAttachedAIImplements()) do
		implement.object:aiImplementEndLine()

		local rootVehicle = implement.object:getRootVehicle()

		rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_AI_END_LINE)
	end
end

function AIDriveStrategyStraight:setAIVehicle(vehicle)
	AIDriveStrategyStraight:superClass().setAIVehicle(self, vehicle)

	local dx, _, dz = localDirectionToWorld(self.vehicle:getAIVehicleDirectionNode(), 0, 0, 1)

	if g_currentMission.snapAIDirection then
		local snapAngle = self.vehicle:getDirectionSnapAngle()
		local terrainAngle = math.pi / math.max(g_currentMission.terrainDetailAngleMaxValue + 1, 4)
		snapAngle = math.max(snapAngle, terrainAngle)
		local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
		angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
		dx, dz = MathUtil.getDirectionFromYRotation(angleRad)
	else
		local length = MathUtil.vector2Length(dx, dz)
		dx = dx / length
		dz = dz / length
	end

	self.vehicle.aiDriveDirection = {
		dx,
		dz
	}
	local x, _, z = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())
	self.vehicle.aiDriveTarget = {
		x,
		z
	}
	local useDefault = true
	self.allowTurnBackward = AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)

	if not self.allowTurnBackward then
		useDefault = false
	end

	self.aiToolReverserDirectionNode = AIVehicleUtil.getAIToolReverserDirectionNode(self.vehicle)
	self.vehicleAIReverserNode = self.vehicle:getAIVehicleReverserNode()
	self.turnStrategies = {}
	local usedStrategies = ""

	if useDefault then
		usedStrategies = usedStrategies .. "   +DEFAULT "

		table.insert(self.turnStrategies, AITurnStrategyDefault:new())

		usedStrategies = usedStrategies .. "   +DEFAULT (reverse)"

		table.insert(self.turnStrategies, AITurnStrategyDefaultReverse:new())
	end

	if self.aiToolReverserDirectionNode ~= nil or useDefault or self.vehicleAIReverserNode then
		usedStrategies = usedStrategies .. "   +BULBs (reverse)"

		table.insert(self.turnStrategies, AITurnStrategyBulb1Reverse:new())
		table.insert(self.turnStrategies, AITurnStrategyBulb2Reverse:new())
		table.insert(self.turnStrategies, AITurnStrategyBulb3Reverse:new())
	else
		usedStrategies = usedStrategies .. "   +BULBs"

		table.insert(self.turnStrategies, AITurnStrategyBulb1:new())
		table.insert(self.turnStrategies, AITurnStrategyBulb2:new())
		table.insert(self.turnStrategies, AITurnStrategyBulb3:new())
	end

	if self.aiToolReverserDirectionNode ~= nil or useDefault or self.vehicleAIReverserNode then
		usedStrategies = usedStrategies .. "   +HALFCIRCLE (reverse)"

		table.insert(self.turnStrategies, AITurnStrategyHalfCircleReverse:new())
	else
		usedStrategies = usedStrategies .. " +HALFCIRCLE"

		table.insert(self.turnStrategies, AITurnStrategyHalfCircle:new())
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AI is using strategies: " .. usedStrategies .. " for " .. tostring(self.vehicle.configFileName))
	end

	for _, turnStrategy in pairs(self.turnStrategies) do
		turnStrategy:setAIVehicle(self.vehicle, self)
	end

	self.activeTurnStrategy = nil
	self.turnDataIsStable = false
	self.turnDataIsStableCounter = 0
	self.fieldEndGabDetected = false
	self.fieldEndGabLastPos = {}
	self.gabAllowTurnLeft = true
	self.gabAllowTurnRight = true
	self.resetGabDetection = true
	self.lastValidTurnLeftPosition = {
		0,
		0,
		0
	}
	self.lastValidTurnLeftValue = 0
	self.lastValidTurnRightPosition = {
		0,
		0,
		0
	}
	self.lastValidTurnRightValue = 0
	self.lastValidTurnCheckPosition = {
		0,
		0,
		0
	}
	self.useCorridor = false
	self.useCorridorStart = nil
	self.useCorridorTimeOut = 0
	self.rowStartTranslation = nil
	self.lastLookAheadDistance = 5
	self.driveExtraDistanceToFieldBorder = false
	self.toolLineStates = {}
end

function AIDriveStrategyStraight:update(dt)
	for _, strategy in pairs(self.turnStrategies) do
		strategy:update(dt)
	end
end

function AIDriveStrategyStraight:getDriveData(dt, vX, vY, vZ)
	if self.activeTurnStrategy ~= nil then
		self.fieldEndGabDetected = false
		self.fieldEndGabLastPos = {}
		self.lastValidTurnLeftPosition = {
			0,
			0,
			0
		}
		self.lastValidTurnLeftValue = 0
		self.lastValidTurnRightPosition = {
			0,
			0,
			0
		}
		self.lastValidTurnRightValue = 0
		self.gabAllowTurnLeft = true
		self.gabAllowTurnRight = true
		self.resetGabDetection = true
		self.rowStartTranslation = nil
		local tX, tZ, moveForwards, maxSpeed, distanceToStop = self.activeTurnStrategy:getDriveData(dt, vX, vY, vZ, self.turnData)

		if tX ~= nil then
			return tX, tZ, moveForwards, maxSpeed, distanceToStop
		else
			for _, turnStrategy in pairs(self.turnStrategies) do
				turnStrategy:onEndTurn(self.activeTurnStrategy.turnLeft)
			end

			self.turnLeft = self.activeTurnStrategy.turnLeft
			self.activeTurnStrategy = nil
			self.idealTurnStrategy = nil
			self.turnDataIsStable = false
			self.turnDataIsStableCounter = 0
			self.lastLookAheadDistance = 5
			self.foundField = false
			self.foundNoBetterTurnStrategy = false
			self.lastHasNoField = false
		end
	end

	if self.rowStartTranslation == nil then
		local x, y, z = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())
		self.rowStartTranslation = {
			x,
			y,
			z
		}
	end

	local distanceToEndOfField, hasField, ownedField = self:getDistanceToEndOfField(dt, vX, vY, vZ)
	local attachedAIImplements = self.vehicle:getAttachedAIImplements()

	if hasField and distanceToEndOfField > 0 then
		self.foundField = true
	end

	if self.foundField == false and distanceToEndOfField <= 0 and self.turnLeft ~= nil then
		local _, _, lz = worldToLocal(self.vehicle:getAIVehicleDirectionNode(), self.vehicle.aiDriveTarget[1], 0, self.vehicle.aiDriveTarget[2])

		if lz > 0 then
			distanceToEndOfField = self.lookAheadDistanceField
			self.lastHasNoField = false
		end
	end

	if not hasField and self.foundField ~= true and self.turnLeft == nil then
		if ownedField then
			self.vehicle:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)
			self:debugPrint("Stopping AIVehicle - unable to find field")
		else
			self.vehicle:stopAIVehicle(AIVehicle.STOP_REASON_FIELD_NOT_OWNED)
			self:debugPrint("Stopping AIVehicle - field not owned")
		end

		return nil
	end

	if distanceToEndOfField <= 0 then
		for _, implement in ipairs(attachedAIImplements) do
			local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
			local hasNoFullCoverageArea, _ = implement.object:getAIHasNoFullCoverageArea()
			local allowCheck = self.turnLeft == nil or self.turnLeft and self.gabAllowTurnRight or self.turnLeft == false and self.gabAllowTurnLeft
			allowCheck = allowCheck and not hasNoFullCoverageArea

			if allowCheck then
				local dir = self.turnLeft and -1 or 1
				local width = calcDistanceFrom(leftMarker, rightMarker)
				local sX, sZ, wX, wZ, hX, hZ = AIVehicleUtil.getAreaDimensions(self.vehicle.aiDriveDirection[1], self.vehicle.aiDriveDirection[2], leftMarker, rightMarker, dir * width, 0, 1, false)
				local area, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ, false)

				if area > 0 and not AIVehicleUtil.getIsAreaOwned(self.vehicle, sX, sZ, wX, wZ, hX, hZ) then
					area = 0
				end

				if self.turnLeft == nil then
					if not self.gabAllowTurnLeft then
						area = 0
					end

					if area <= 0 and self.gabAllowTurnRight then
						dir = -dir
						sX, sZ, wX, wZ, hX, hZ = AIVehicleUtil.getAreaDimensions(self.vehicle.aiDriveDirection[1], self.vehicle.aiDriveDirection[2], leftMarker, rightMarker, dir * width, 0, 1, false)
						area, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ, false)

						if area > 0 and not AIVehicleUtil.getIsAreaOwned(self.vehicle, sX, sZ, wX, wZ, hX, hZ) then
							area = 0
						end
					end
				end

				if area > 0 then
					distanceToEndOfField = 5
					self.driveExtraDistanceToFieldBorder = true
				end
			end
		end
	else
		self.driveExtraDistanceToFieldBorder = false
	end

	local lookAheadDistance = self.lastLookAheadDistance
	local distanceToCollision = 0

	if distanceToEndOfField > 0 and not self.useCorridor then
		if not self.turnDataIsStable then
			self:updateTurnData()
		end

		local searchForTurnStrategy = self.idealTurnStrategy == nil

		if self.idealTurnStrategy ~= nil then
			distanceToCollision = self.idealTurnStrategy:getDistanceToCollision(dt, vX, vY, vZ, self.turnData, lookAheadDistance)

			if distanceToCollision < lookAheadDistance then
				searchForTurnStrategy = true
			else
				self.foundNoBetterTurnStrategy = false
			end
		end

		if searchForTurnStrategy and self.foundNoBetterTurnStrategy ~= true then
			for i, turnStrategy in pairs(self.turnStrategies) do
				if turnStrategy ~= self.idealTurnStrategy then
					local colDist = turnStrategy:getDistanceToCollision(dt, vX, vY, vZ, self.turnData, lookAheadDistance)

					if lookAheadDistance <= colDist and not turnStrategy.collisionDetected then
						self.idealTurnStrategy = turnStrategy
						distanceToCollision = colDist

						break
					end
				end
			end
		end

		if self.idealTurnStrategy ~= nil then
			self.turnLeft = self.idealTurnStrategy.turnLeft
		end
	end

	local distanceToTurn = math.min(distanceToEndOfField, distanceToCollision)

	if distanceToCollision < lookAheadDistance and distanceToCollision < distanceToEndOfField and (self.turnLeft ~= nil or self.idealTurnStrategy == nil) then
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

		for _, implement in pairs(attachedAIImplements) do
			AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
		end

		local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, self.turnData)

		if self.turnLeft and rightAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD or not self.turnLeft and leftAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD or self.idealTurnStrategy == nil then
			self.foundNoBetterTurnStrategy = false
			local collision = self.turnStrategies[1]:checkCollisionInFront(self.turnData)

			if collision or distanceToEndOfField <= 0 then
				self.foundNoBetterTurnStrategy = false
				self.idealTurnStrategy = nil

				if self.turnLeft == nil then
					self.vehicle:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)

					return nil
				end
			else
				distanceToTurn = lookAheadDistance
			end
		end
	end

	if self.allowTurnBackward or self.aiToolReverserDirectionNode ~= nil then
		if distanceToTurn <= 0 and distanceToEndOfField > 0 then
			local collision = self.turnStrategies[1]:checkCollisionInFront(self.turnData, 0)

			if not collision then
				if self.vehicle:getLastSpeed() < 1.5 then
					self.useCorridorTimeOut = self.useCorridorTimeOut + dt
				else
					self.useCorridorTimeOut = 0
				end

				if self.useCorridorTimeOut > 3000 then
					collision = true
				end
			end

			if not collision then
				distanceToTurn = distanceToEndOfField
				self.useCorridor = true

				if self.useCorridorStart == nil then
					self.useCorridorStart = {
						vX,
						vY,
						vZ
					}
				end
			else
				self.useCorridor = false
			end
		else
			self.useCorridor = false
		end
	end

	if distanceToTurn <= 0 and not self.useCorridor then
		for _, implement in ipairs(attachedAIImplements) do
			if implement.aiEndLineCalled == nil or not implement.aiEndLineCalled then
				implement.aiEndLineCalled = true
				implement.aiStartLineCalled = nil

				implement.object:aiImplementEndLine()

				local rootVehicle = implement.object:getRootVehicle()

				rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_AI_END_LINE)
			end
		end

		self.lastHasNoField = false
		self.activeTurnStrategy = self.idealTurnStrategy

		if self.turnData ~= nil and self.activeTurnStrategy ~= nil then
			if self.useCorridorStart ~= nil then
				local distance = MathUtil.vector3Length(self.useCorridorStart[1] - vX, self.useCorridorStart[2] - vY, self.useCorridorStart[3] - vZ)
				self.corridorDistance = distance
				self.useCorridorStart = nil

				self:debugPrint(string.format("start turn with corridor offset: %.2f", distance))
			end

			local canTurn = self.activeTurnStrategy:startTurn(self)
			self.activeTurnStrategy.lastValidTurnPositionOffset = 0
			self.corridorDistance = 0

			if not canTurn then
				self.vehicle:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)
				self:debugPrint("Stopping AIVehicle - could not start to turn")

				return nil
			end

			return self.activeTurnStrategy:getDriveData(dt, vX, vY, vZ, self.turnData)
		else
			self.vehicle:stopAIVehicle(AIVehicle.STOP_REASON_REGULAR)
		end

		return nil
	else
		return self:getDriveStraightData(dt, vX, vY, vZ, distanceToTurn, distanceToEndOfField)
	end
end

function AIDriveStrategyStraight:getDriveStraightData(dt, vX, vY, vZ, distanceToTurn, distanceToEndOfField)
	if self.vehicle.aiDriveDirection == nil then
		return nil, , true, 0, 0
	end

	local pX, pZ = MathUtil.projectOnLine(vX, vZ, self.vehicle.aiDriveTarget[1], self.vehicle.aiDriveTarget[2], self.vehicle.aiDriveDirection[1], self.vehicle.aiDriveDirection[2])
	local tX = pX + self.vehicle.aiDriveDirection[1] * self.vehicle.maxTurningRadius
	local tZ = pZ + self.vehicle.aiDriveDirection[2] * self.vehicle.maxTurningRadius
	local maxSpeed = self.vehicle:getSpeedLimit()
	local attachedAIImplements = self.vehicle:getAttachedAIImplements()

	for i = #self.toolLineStates, 1, -1 do
		self.toolLineStates[i] = nil
	end

	local nrOfImplements = #attachedAIImplements

	for i = nrOfImplements, 1, -1 do
		local implement = attachedAIImplements[i]

		if self.toolLineStates[i + 1] == -1 and attachedAIImplements[i + 1].object:getAttacherVehicle() == implement.object then
			self.toolLineStates[i] = -1
		else
			local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
			local safetyOffset = 0.2
			local markerZOffset = 0
			local _, _, areaLength = localToLocal(backMarker, leftMarker, 0, 0, 0)
			local size = 1
			local doAdditionalFieldEndChecks = false
			local hasNoFullCoverageArea, hasNoFullCoverageAreaOffset = implement.object:getAIHasNoFullCoverageArea()

			if hasNoFullCoverageArea then
				markerZOffset = areaLength
				size = math.abs(markerZOffset) + hasNoFullCoverageAreaOffset
				doAdditionalFieldEndChecks = true
			end

			local function getAreaDimensions(leftNode, rightNode, xOffset, zOffset, areaSize, invertXOffset)
				local xOffsetLeft = xOffset
				local xOffsetRight = xOffset

				if invertXOffset == nil or invertXOffset then
					xOffsetLeft = -xOffsetLeft
				end

				local lX, _, lZ = localToWorld(leftNode, xOffsetLeft, 0, zOffset)
				local rX, _, rZ = localToWorld(rightNode, xOffsetRight, 0, zOffset)
				local sX = lX - 0.5 * self.vehicle.aiDriveDirection[1]
				local sZ = lZ - 0.5 * self.vehicle.aiDriveDirection[2]
				local wX = rX - 0.5 * self.vehicle.aiDriveDirection[1]
				local wZ = rZ - 0.5 * self.vehicle.aiDriveDirection[2]
				local hX = lX + areaSize * self.vehicle.aiDriveDirection[1]
				local hZ = lZ + areaSize * self.vehicle.aiDriveDirection[2]

				return sX, sZ, wX, wZ, hX, hZ
			end

			local sX, sZ, wX, wZ, hX, hZ = getAreaDimensions(leftMarker, rightMarker, safetyOffset, markerZOffset, size)
			local area, totalArea = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ, false)

			if area / totalArea > 0.025 then
				if not self.fieldEndGabDetected then
					self.toolLineStates[i] = -1
				end

				if doAdditionalFieldEndChecks then
					local distance1 = 0
					local distance2 = 0
					local sX1, sZ1, wX1, wZ1, hX1, hZ1 = getAreaDimensions(leftMarker, rightMarker, safetyOffset, 1, 1)
					local area2, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX1, sZ1, wX1, wZ1, hX1, hZ1, false)

					if #self.fieldEndGabLastPos > 0 then
						distance1 = math.abs(MathUtil.vector2Length(sX1 - self.fieldEndGabLastPos[1], sZ1 - self.fieldEndGabLastPos[2]))
					end

					local sX2, sZ2, wX2, wZ2, hX2, hZ2 = getAreaDimensions(leftMarker, rightMarker, safetyOffset, -1, 1)
					local area3, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX2, sZ2, wX2, wZ2, hX2, hZ2, false)

					if #self.fieldEndGabLastPos > 0 then
						distance2 = math.abs(MathUtil.vector2Length(sX2 - self.fieldEndGabLastPos[1], sZ2 - self.fieldEndGabLastPos[2]))
					end

					if area3 == 0 and area2 > 0 and distance1 > 0 and distance2 > 0 and distance1 > 3 and distance2 < distance1 then
						self.fieldEndGabDetected = true
						self.toolLineStates[i] = 1
					end

					if area2 > 0 then
						self.fieldEndGabLastPos[1] = sX1
						self.fieldEndGabLastPos[2] = sZ1
					end
				end

				if not self.driveExtraDistanceToFieldBorder then
					local usedAreaLength = math.abs(areaLength)

					if markerZOffset ~= 0 then
						usedAreaLength = 0
					end

					local dir = self.turnLeft and -1 or 1
					local width = calcDistanceFrom(leftMarker, rightMarker)
					sX, sZ, wX, wZ, hX, hZ = getAreaDimensions(leftMarker, rightMarker, dir * width, markerZOffset - usedAreaLength, size, false)
					area, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ, false)
					local x = 0
					local y = 0
					local z = 0

					if not AIVehicleUtil.getIsAreaOwned(self.vehicle, sX, sZ, wX, wZ, hX, hZ) then
						area = 0
					end

					if area > 0 then
						x, y, z = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())
					else
						dir = -dir
						sX, sZ, wX, wZ, hX, hZ = getAreaDimensions(leftMarker, rightMarker, dir * width, markerZOffset - usedAreaLength, size, false)
						area, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX, hZ, false)

						if not AIVehicleUtil.getIsAreaOwned(self.vehicle, sX, sZ, wX, wZ, hX, hZ) then
							area = 0
						end

						if area > 0 then
							x, y, z = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())
						end
					end

					if area > 0 then
						if dir > 0 then
							if self.lastValidTurnRightValue < area then
								self.lastValidTurnLeftPosition[3] = z
								self.lastValidTurnLeftPosition[2] = y
								self.lastValidTurnLeftPosition[1] = x
								self.lastValidTurnLeftValue = math.max(area, self.lastValidTurnLeftValue)
								self.lastValidTurnRightPosition[3] = 0
								self.lastValidTurnRightPosition[2] = 0
								self.lastValidTurnRightPosition[1] = 0
							end
						elseif self.lastValidTurnLeftValue < area then
							self.lastValidTurnRightPosition[3] = z
							self.lastValidTurnRightPosition[2] = y
							self.lastValidTurnRightPosition[1] = x
							self.lastValidTurnRightValue = math.max(area, self.lastValidTurnRightValue)
							self.lastValidTurnLeftPosition[3] = 0
							self.lastValidTurnLeftPosition[2] = 0
							self.lastValidTurnLeftPosition[1] = 0
						end
					end

					self.lastValidTurnCheckPosition[1], self.lastValidTurnCheckPosition[2], self.lastValidTurnCheckPosition[3] = getWorldTranslation(self.vehicle:getAIVehicleDirectionNode())

					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						DebugUtil.drawDebugGizmoAtWorldPos(self.lastValidTurnLeftPosition[1], self.lastValidTurnLeftPosition[2], self.lastValidTurnLeftPosition[3], 0, 1, 0, 0, 1, 0, "last valid left", true)
						DebugUtil.drawDebugGizmoAtWorldPos(self.lastValidTurnRightPosition[1], self.lastValidTurnRightPosition[2], self.lastValidTurnRightPosition[3], 0, 1, 0, 0, 1, 0, "last valid right", true)
					end
				end
			elseif self.lastHasNoField then
				self.toolLineStates[i] = 1
			else
				local lX, _, lZ = localToWorld(leftMarker, -safetyOffset, 0, markerZOffset)
				local hX2 = lX + math.max(distanceToTurn, 2.5) * self.vehicle.aiDriveDirection[1]
				local hZ2 = lZ + math.max(distanceToTurn, 2.5) * self.vehicle.aiDriveDirection[2]
				local area2, _ = AIVehicleUtil.getAIAreaOfVehicle(implement.object, sX, sZ, wX, wZ, hX2, hZ2, false)

				if area2 <= 0 then
					self.toolLineStates[i] = 1
				end
			end
		end
	end

	for i = nrOfImplements, 1, -1 do
		local implement = attachedAIImplements[i]

		if self.toolLineStates[i] == -1 then
			if implement.aiStartLineCalled == nil or not implement.aiStartLineCalled then
				implement.aiStartLineCalled = true
				implement.aiEndLineCalled = nil

				implement.object:aiImplementStartLine()

				local rootVehicle = implement.object:getRootVehicle()

				rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_AI_START_LINE)
			end
		elseif self.toolLineStates[i] == 1 and (implement.aiEndLineCalled == nil or not implement.aiEndLineCalled) then
			implement.aiEndLineCalled = true
			implement.aiStartLineCalled = nil

			implement.object:aiImplementEndLine()

			local rootVehicle = implement.object:getRootVehicle()

			rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_AI_END_LINE)
		end
	end

	local canContinueWork = self.vehicle:getCanAIVehicleContinueWork()

	if not canContinueWork then
		maxSpeed = 0
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("===> canContinueWork: %s", tostring(canContinueWork)))
		self.vehicle:addAIDebugLine({
			vX,
			vY,
			vZ
		}, {
			tX,
			vY,
			tZ
		}, {
			1,
			1,
			1
		})
	end

	self.gabAllowTurnLeft = true
	self.gabAllowTurnRight = true
	local changeCounter = 0
	local lastBit = false
	local gabBits = ""
	local gabPos = -1

	for _, implement in ipairs(attachedAIImplements) do
		local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
		local width = calcDistanceFrom(leftMarker, rightMarker) + 0.8
		local divisions = 2.5

		if width < 8.5 then
			divisions = 1.5
		end

		if width < 4.5 then
			divisions = 1
		end

		local checkpoints = implement.object.aiImplementGabCheckpoints or MathUtil.round(width / divisions, 0)

		if implement.object.aiImplementGabCheckpoints == nil then
			implement.object.aiImplementGabCheckpoints = checkpoints
		end

		if implement.object.aiImplementGabCheckpointValues == nil or self.resetGabDetection then
			implement.object.aiImplementGabCheckpointValues = {}
			self.resetGabDetection = false
		end

		local values = implement.object.aiImplementGabCheckpointValues
		implement.object.aiImplementCurCheckpoint = (implement.object.aiImplementCurCheckpoint or -1) + 1

		if checkpoints <= implement.object.aiImplementCurCheckpoint then
			implement.object.aiImplementCurCheckpoint = 0
		end

		local currentCheckpoint = implement.object.aiImplementCurCheckpoint

		if checkpoints > 2 then
			local checkpointWidth = width / checkpoints
			local x1, y1, z1 = localToWorld(leftMarker, 0.4, 0, 0)
			local x2, y2, z2 = localToWorld(rightMarker, -0.4, 0, 0)
			local x = x1 - (x1 - x2) * currentCheckpoint * checkpointWidth / width
			local y = y1 - (y1 - y2) * currentCheckpoint * checkpointWidth / width
			local z = z1 - (z1 - z2) * currentCheckpoint * checkpointWidth / width
			local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, y, z) ~= 0
			local bit = values[currentCheckpoint + 1]
			bit = bit or isOnField
			values[currentCheckpoint + 1] = bit
			local hasLeftGab = gabPos > 0 and gabPos < 0.5
			local hasRightGab = gabPos >= 0.5
			self.gabAllowTurnLeft = self.gabAllowTurnLeft and values[1] and not hasLeftGab
			self.gabAllowTurnRight = self.gabAllowTurnRight and values[#values] and not hasRightGab

			for i = 1, checkpoints do
				if values[i] ~= lastBit then
					changeCounter = changeCounter + 1

					if changeCounter > 2 then
						gabPos = i / checkpoints
					end

					lastBit = values[i]
				end

				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					gabBits = gabBits .. tostring(values[i] and 1 or 0)
				end
			end
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("===> gab bits: %s", gabBits))

		if gabPos > 0 then
			self.vehicle:addAIDebugText(string.format("===> gab pos: %s%% side: %s", gabPos * 100, gabPos < 0.5 and "left" or "right"))
		end

		self.vehicle:addAIDebugText(string.format("===> gab allow Left: %s", self.gabAllowTurnLeft))
		self.vehicle:addAIDebugText(string.format("===> gab allow right: %s", self.gabAllowTurnRight))
	end

	return tX, tZ, true, maxSpeed, distanceToTurn
end

function AIDriveStrategyStraight:updateTurnData()
	self.turnData = Utils.getNoNil(self.turnData, {})
	local turnData = self.turnData
	local aiVehicleDirectionNode = self.vehicle:getAIVehicleDirectionNode()
	local attachedAIImplements = self.vehicle:getAttachedAIImplements()
	turnData.radius = self.vehicle.maxTurningRadius * 1.1
	local minTurningRadius = self.vehicle:getAIMinTurningRadius()

	if minTurningRadius ~= nil then
		turnData.radius = math.max(turnData.radius, minTurningRadius)
	end

	local maxToolRadius = 0

	for _, implement in pairs(attachedAIImplements) do
		maxToolRadius = math.max(maxToolRadius, AIVehicleUtil.getMaxToolRadius(implement))
	end

	turnData.radius = math.max(turnData.radius, maxToolRadius)
	local minWidthOfAIArea = math.huge
	turnData.maxZOffset = -math.huge
	turnData.minZOffset = math.huge
	turnData.aiAreaMaxX = -math.huge
	turnData.aiAreaMinX = math.huge
	local lastTypeName = nil
	local allImplementsOfSameType = true

	for _, implement in pairs(attachedAIImplements) do
		if lastTypeName == nil then
			lastTypeName = implement.object.typeName
		end

		allImplementsOfSameType = allImplementsOfSameType and lastTypeName == implement.object.typeName
		local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
		local xL, _, zL = localToLocal(leftMarker, aiVehicleDirectionNode, 0, 0, 0)
		local xR, _, zR = localToLocal(rightMarker, aiVehicleDirectionNode, 0, 0, 0)
		local xB, _, zB = localToLocal(backMarker, aiVehicleDirectionNode, 0, 0, 0)
		local lrDistance = math.abs(xL - xR)

		if lrDistance < minWidthOfAIArea then
			minWidthOfAIArea = lrDistance
			turnData.minAreaImplement = implement
		end

		turnData.aiAreaMinX = math.min(turnData.aiAreaMinX, xL, xR, xB)
		turnData.aiAreaMaxX = math.max(turnData.aiAreaMaxX, xL, xR, xB)
		turnData.maxZOffset = math.max(turnData.maxZOffset, zL, zR)
		turnData.minZOffset = math.min(turnData.minZOffset, zL, zR)
	end

	turnData.allImplementsOfSameType = allImplementsOfSameType

	if turnData.maxZOffset == turnData.minZOffset then
		turnData.zOffset = 2 * turnData.maxZOffset
		turnData.zOffsetTurn = math.max(1, 2 * turnData.maxZOffset)
	elseif turnData.maxZOffset > 0 and turnData.minZOffset < 0 then
		turnData.zOffset = turnData.minZOffset + turnData.maxZOffset
		turnData.zOffsetTurn = math.max(1, turnData.minZOffset + turnData.maxZOffset)
	elseif turnData.maxZOffset > 0 and turnData.minZOffset > 0 then
		turnData.zOffset = 2 * turnData.maxZOffset
		turnData.zOffsetTurn = math.max(1, 2 * turnData.maxZOffset)
	elseif turnData.maxZOffset < 0 and turnData.minZOffset < 0 then
		turnData.zOffset = turnData.minZOffset + turnData.maxZOffset
		turnData.zOffsetTurn = math.max(1, turnData.minZOffset + turnData.maxZOffset)
	end

	local minLeftMarker, minRightMarker, _ = turnData.minAreaImplement.object:getAIMarkers()
	turnData.sideOffsetLeft = localToLocal(minLeftMarker, aiVehicleDirectionNode, 0, 0, 0)
	turnData.sideOffsetRight = localToLocal(minRightMarker, aiVehicleDirectionNode, 0, 0, 0)

	if allImplementsOfSameType then
		turnData.sideOffsetLeft = turnData.aiAreaMaxX
		turnData.sideOffsetRight = turnData.aiAreaMinX
	end

	turnData.sideOffsetLeft = turnData.sideOffsetLeft - 0.13
	turnData.sideOffsetRight = turnData.sideOffsetRight + 0.13
	turnData.radius = math.max(turnData.radius, turnData.sideOffsetLeft, -turnData.sideOffsetRight)

	if self.turnLeft ~= nil then
		local canInvertMarkerOnTurn = false

		for _, implement in pairs(attachedAIImplements) do
			canInvertMarkerOnTurn = canInvertMarkerOnTurn or implement.object:getAIInvertMarkersOnTurn(self.turnLeft)
		end

		if canInvertMarkerOnTurn then
			local offset = math.abs(turnData.sideOffsetLeft - turnData.sideOffsetRight) / 2
			turnData.sideOffsetLeft = offset
			turnData.sideOffsetRight = -offset
		end
	end

	turnData.useExtraStraightLeft = turnData.radius < turnData.sideOffsetLeft
	turnData.useExtraStraightRight = turnData.sideOffsetRight < -turnData.radius
	turnData.toolOverhang = {
		front = {},
		back = {}
	}
	turnData.allToolsAtFront = true
	local xt = self.vehicle.sizeWidth * 0.5
	local zt = self.vehicle.sizeLength * 0.75
	local alphaX = math.atan(-zt / (xt + turnData.radius))
	local alphaZ = math.atan((xt + turnData.radius) / zt)
	local xb = math.cos(alphaX) * xt - math.sin(alphaX) * zt + math.cos(alphaX) * turnData.radius
	local zb = math.sin(alphaZ) * xt + math.cos(alphaZ) * zt + math.sin(alphaZ) * turnData.radius

	for _, side in pairs({
		"front",
		"back"
	}) do
		turnData.toolOverhang[side].xt = xt
		turnData.toolOverhang[side].zt = zt
		turnData.toolOverhang[side].xb = xb
		turnData.toolOverhang[side].zb = zb
	end

	for _, implement in pairs(attachedAIImplements) do
		if implement.object:getAIAllowTurnBackward() then
			local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
			local leftSizeMarker, rightSizeMarker, backSizeMarker = implement.object:getAISizeMarkers()
			local xL, _, zL = localToLocal(Utils.getNoNil(leftSizeMarker, leftMarker), aiVehicleDirectionNode, 0, 0, 0)
			local xR, _, zR = localToLocal(Utils.getNoNil(rightSizeMarker, rightMarker), aiVehicleDirectionNode, 0, 0, 0)
			local xB, _, zB = localToLocal(Utils.getNoNil(backSizeMarker, backMarker), aiVehicleDirectionNode, 0, 0, 0)
			turnData.allToolsAtFront = turnData.allToolsAtFront and zB > 0
			local xt = math.max(math.abs(xL), math.abs(xR), math.abs(xB))
			local zt = math.max(math.abs(zL), math.abs(zR), math.abs(zB))
			local xb = math.sqrt(xt * xt + zt * zt) + turnData.radius
			local zb = xb
			local side = "back"

			if zB > 0 then
				side = "front"
			end

			local toolOverhang = turnData.toolOverhang[side]
			toolOverhang.xb = math.max(xb, toolOverhang.xb)
			toolOverhang.zb = math.max(zb, toolOverhang.zb)
			toolOverhang.xt = math.max(xt, toolOverhang.xt)
			toolOverhang.zt = math.max(zt, toolOverhang.zt)
		end
	end

	local rotTime = 1 / self.vehicle.wheelSteeringDuration * math.atan(1 / turnData.radius) / math.atan(1 / self.vehicle.maxTurningRadius)
	local angle = nil

	if rotTime >= 0 then
		angle = rotTime / self.vehicle.maxRotTime * self.vehicle.maxRotation
	else
		angle = rotTime / self.vehicle.minRotTime * self.vehicle.maxRotation
	end

	for _, implement in pairs(attachedAIImplements) do
		if not implement.object:getAIAllowTurnBackward() then
			local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
			local leftSizeMarker, rightSizeMarker, backSizeMarker = implement.object:getAISizeMarkers()
			local lX, _, lZ = localToLocal(Utils.getNoNil(leftSizeMarker, leftMarker), implement.object.components[1].node, 0, 0, 0)
			local rX, _, rZ = localToLocal(Utils.getNoNil(rightSizeMarker, rightMarker), implement.object.components[1].node, 0, 0, 0)
			local bX, _, bZ = localToLocal(Utils.getNoNil(backSizeMarker, backMarker), implement.object.components[1].node, 0, 0, 0)
			local nX = math.max(math.abs(lX), math.abs(rX), math.abs(bX))
			local nZ = math.min(-math.abs(lZ), -math.abs(rZ), -math.abs(bZ))

			if implement.object.getActiveInputAttacherJoint then
				local inputAttacherJoint = implement.object:getActiveInputAttacherJoint()
				local xAtt, _, zAtt = localToLocal(implement.object.components[1].node, inputAttacherJoint.node, nX, 0, nZ)
				zAtt = -xAtt
				xAtt = zAtt
				local xRot = xAtt * math.cos(-angle) - zAtt * math.sin(-angle)
				local zRot = xAtt * math.sin(-angle) + zAtt * math.cos(-angle)
				local xFin, _, _ = localToLocal(implement.object.components[1].node, aiVehicleDirectionNode, xRot, 0, zRot)
				xFin = xFin + turnData.radius
				turnData.toolOverhang.back.xb = math.max(turnData.toolOverhang.back.xb, xFin)
				local xL, _, _ = localToLocal(Utils.getNoNil(leftSizeMarker, leftMarker), aiVehicleDirectionNode, 0, 0, 0)
				local xR, _, _ = localToLocal(Utils.getNoNil(rightSizeMarker, rightMarker), aiVehicleDirectionNode, 0, 0, 0)
				local _, _, zB = localToLocal(Utils.getNoNil(backSizeMarker, backMarker), aiVehicleDirectionNode, 0, 0, 0)
				turnData.toolOverhang.back.xt = math.max(turnData.toolOverhang.back.xt, math.max(math.abs(xL), math.abs(xR)))
				turnData.toolOverhang.back.zt = math.max(turnData.toolOverhang.back.zt, -zB)
				local _, rotationJoint, wheels = implement.object:getAITurnRadiusLimitation()
				local angleSteer = 0

				if rotationJoint ~= nil then
					for _, wheel in pairs(wheels) do
						if wheel.steeringAxleScale ~= 0 and wheel.steeringAxleRotMax ~= 0 then
							angleSteer = math.max(angleSteer, math.abs(wheel.steeringAxleRotMax))
						end
					end
				end

				if angleSteer ~= 0 and rotationJoint ~= nil then
					local wheelIndexCount = #wheels

					if rotationJoint ~= nil and wheelIndexCount > 0 then
						local cx = 0
						local cz = 0

						for _, wheel in pairs(wheels) do
							local x, _, z = localToLocal(wheel.repr, implement.object.components[1].node, 0, 0, 0)
							cx = cx + x
							cz = cz + z
						end

						cx = cx / wheelIndexCount
						cz = cz / wheelIndexCount
						local dx = nX - cx
						local dz = nZ - cz
						local delta = math.sqrt(dx * dx + dz * dz)
						local xFin = delta + turnData.radius
						turnData.toolOverhang.back.xb = math.max(turnData.toolOverhang.back.xb, xFin)
					end
				end
			end
		end
	end

	for _, implement in pairs(attachedAIImplements) do
		local leftMarker, _, _ = implement.object:getAIMarkers()
		local _, _, z = localToLocal(leftMarker, aiVehicleDirectionNode, 0, 0, 0)
		implement.distToVehicle = z
	end

	local function sortImplementsByDistance(arg1, arg2)
		return arg2.distToVehicle < arg1.distToVehicle
	end

	table.sort(attachedAIImplements, sortImplementsByDistance)

	if self.lastTurnData == nil then
		self.lastTurnData = {
			radius = turnData.radius,
			maxZOffset = turnData.maxZOffset,
			minZOffset = turnData.minZOffset,
			aiAreaMaxX = turnData.aiAreaMaxX,
			aiAreaMinX = turnData.aiAreaMinX,
			sideOffsetLeft = turnData.sideOffsetLeft,
			sideOffsetRight = turnData.sideOffsetRight
		}
	elseif self.vehicle:getLastSpeed() > 2 and math.abs(self.lastTurnData.radius - turnData.radius) < 0.03 and math.abs(self.lastTurnData.maxZOffset - turnData.maxZOffset) < 0.03 and math.abs(self.lastTurnData.minZOffset - turnData.minZOffset) < 0.03 and math.abs(self.lastTurnData.aiAreaMaxX - turnData.aiAreaMaxX) < 0.03 and math.abs(self.lastTurnData.aiAreaMinX - turnData.aiAreaMinX) < 0.03 and math.abs(self.lastTurnData.sideOffsetLeft - turnData.sideOffsetLeft) < 0.03 and math.abs(self.lastTurnData.sideOffsetRight - turnData.sideOffsetRight) < 0.03 then
		self.turnDataIsStableCounter = self.turnDataIsStableCounter + 1

		if self.turnDataIsStableCounter > 120 then
			self.turnDataIsStable = true
		end
	else
		self.lastTurnData.radius = turnData.radius
		self.lastTurnData.maxZOffset = turnData.maxZOffset
		self.lastTurnData.minZOffset = turnData.minZOffset
		self.lastTurnData.aiAreaMaxX = turnData.aiAreaMaxX
		self.lastTurnData.aiAreaMinX = turnData.aiAreaMinX
		self.lastTurnData.sideOffsetLeft = turnData.sideOffsetLeft
		self.lastTurnData.sideOffsetRight = turnData.sideOffsetRight
		self.turnDataIsStableCounter = 0
	end
end
