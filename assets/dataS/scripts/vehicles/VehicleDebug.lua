VehicleDebug = {
	WORKAREA_COLORS = {
		{
			1,
			0,
			0,
			1
		},
		{
			0,
			1,
			0,
			1
		},
		{
			0,
			0,
			1,
			1
		},
		{
			1,
			1,
			0,
			1
		},
		{
			1,
			0,
			1,
			1
		},
		{
			0,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1
		}
	},
	DEBUG_PHYSICS = 1,
	DEBUG = 2,
	DEBUG_ATTRIBUTES = 3,
	DEBUG_ATTACHER_JOINTS = 4,
	DEBUG_AI = 5,
	DEBUG_SOUNDS = 6,
	DEBUG_TIPPING = 7,
	state = 0
}

if g_isDevelopmentVersion then
	VehicleDebug.state = 0
end

function VehicleDebug.consoleCommandVehicleDebug(unusedSelf)
	return "VehicleDebug - Values: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG))
end

function VehicleDebug.consoleCommandVehicleDebugAttacherJoints(unusedSelf)
	local success = VehicleDebug.setState(VehicleDebug.DEBUG_ATTACHER_JOINTS)

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		if VehicleDebug.attacherJointUpperEventId == nil and VehicleDebug.attacherJointLowerEventId == nil then
			local _, upperEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_ARM, VehicleDebug, VehicleDebug.moveUpperRotation, false, false, true, true)
			VehicleDebug.attacherJointUpperEventId = upperEventId
			local _, lowerEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_TOOL, VehicleDebug, VehicleDebug.moveLowerRotation, false, false, true, true)
			VehicleDebug.attacherJointLowerEventId = lowerEventId
		end
	else
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointUpperEventId)
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointLowerEventId)

		VehicleDebug.attacherJointUpperEventId = nil
		VehicleDebug.attacherJointLowerEventId = nil
	end

	return "VehicleDebug - AttacherJoints: " .. tostring(success)
end

function VehicleDebug.consoleCommandVehicleDebugAttributes(unusedSelf)
	return "VehicleDebug - Attributes: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_ATTRIBUTES))
end

function VehicleDebug.consoleCommandVehicleDebugAI(unusedSelf)
	return "VehicleDebug - AI: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_AI))
end

function VehicleDebug.consoleCommandVehicleDebugPhysics(unusedSelf)
	return "VehicleDebug - Physics: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_PHYSICS))
end

function VehicleDebug.consoleCommandVehicleDebugSounds(unusedSelf)
	return "VehicleDebug - Sounds: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_SOUNDS))
end

function VehicleDebug.consoleCommandVehicleDebugTipping(unusedSelf)
	return "VehicleDebug - Tipping: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_TIPPING))
end

function VehicleDebug.setState(state)
	local ret = false

	if VehicleDebug.state == state then
		VehicleDebug.state = 0
	else
		VehicleDebug.state = state
		ret = true
	end

	if g_currentMission ~= nil then
		for _, vehicle in pairs(g_currentMission.vehicles) do
			vehicle:updateSelectableObjects()
			vehicle:updateActionEvents()
			vehicle:setSelectedVehicle(vehicle)
		end
	end

	return ret
end

function VehicleDebug.updateDebug(vehicle)
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		VehicleDebug.drawDebugAttributeRendering(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		VehicleDebug.drawDebugAttacherJoints(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
		VehicleDebug.drawDebugAIRendering(vehicle)
	end

	if VehicleDebug.state == VehicleDebug.DEBUG then
		VehicleDebug.drawDebugValues(vehicle)
	end
end

function VehicleDebug.drawDebug(vehicle)
	if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
		local v = vehicle:getSelectedVehicle()

		if v == nil then
			v = vehicle
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
			VehicleDebug.drawDebugRendering(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_SOUNDS then
			VehicleDebug.drawSoundDebugValues(v)
		end
	end
end

function VehicleDebug:drawDebugRendering()
	local x, _, z = getWorldTranslation(self.components[1].node)
	local fieldOwned = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(g_currentMission:getFarmId(), x, z)
	local str1 = ""
	local str2 = ""
	local str3 = ""
	local str4 = ""
	local motorSpec = self.spec_motorized
	local motor = nil

	if motorSpec ~= nil then
		motor = motorSpec.motor
		local torque = motor:getMotorAvailableTorque()
		local neededPtoTorque = motor:getMotorExternalTorque()
		local motorPower = motor:getMotorRotSpeed() * (torque - neededPtoTorque) * 1000
		str1 = str1 .. "motor:\n"
		str2 = str2 .. string.format("%1.2frpm\n", motor:getNonClampedMotorRpm())
		str1 = str1 .. "clutch:\n"
		str2 = str2 .. string.format("%1.2frpm\n", motor:getClutchRotSpeed() * 30 / math.pi)
		str1 = str1 .. "available power:\n"
		str2 = str2 .. string.format("%1.2fhp %1.2fkW\n", motorPower / 735.49875, motorPower / 1000)
		str1 = str1 .. "gear:\n"
		str2 = str2 .. string.format("%2d (%1.2f)\n", motor.gear, motor:getGearRatio())
		str1 = str1 .. "motor load:\n"
		str2 = str2 .. string.format("%1.2fkN %1.2fkN\n", torque, motor:getMotorAppliedTorque())
		local ptoPower = motor:getNonClampedMotorRpm() * math.pi / 30 * neededPtoTorque
		local ptoLoad = neededPtoTorque / motor:getPeakTorque()
		str3 = str3 .. "pto load:\n"
		str4 = str4 .. string.format("%.2f%% %.2fkW %1.2fkN\n", ptoLoad * 100, ptoPower, neededPtoTorque)
		str3 = str3 .. "motor load:\n"
		str4 = str4 .. string.format("%.2f%%\n", motorSpec.smoothedLoadPercentage * 100)
		str3 = str3 .. "motor load for sounds:\n"
		str4 = str4 .. string.format("%.2f%%\n", Motorized.getMotorLoadPercentage(self) * 100)
		str3 = str3 .. "brakeForce:\n"
		str4 = str4 .. string.format("%.2f\n", (self.spec_wheels or {
			brakePedal = 0
		}).brakePedal)
		local diesel = (self:getFillUnitByIndex(self:getFirstValidFillUnitToFill(FillType.DIESEL, true)) or {
			fillLevel = 0
		}).fillLevel
		local def = (self:getFillUnitByIndex(self:getFirstValidFillUnitToFill(FillType.DEF, true)) or {
			fillLevel = 0
		}).fillLevel
		local air = (self:getFillUnitByIndex(self:getFirstValidFillUnitToFill(FillType.AIR, true)) or {
			fillLevel = 0
		}).fillLevel
		str3 = str3 .. "fuelUsage Diesel:\n"
		str4 = str4 .. string.format("%.2fl/h (%.2fl)\n", motorSpec.lastFuelUsage, diesel)
		str3 = str3 .. "fuelUsage DEF:\n"
		str4 = str4 .. string.format("%.2fl/h (%.2fl)\n", motorSpec.lastDefUsage, def)
		str3 = str3 .. "usage AIR:\n"
		str4 = str4 .. string.format("%.2fl/sec (%.2fl)\n", motorSpec.lastAirUsage, air)
	end

	str1 = str1 .. "vel acc[m/s2]:\n"
	str2 = str2 .. string.format("%1.4f\n", self.lastSpeedAcceleration * 1000 * 1000)
	str1 = str1 .. "vel[km/h]:\n"
	str2 = str2 .. string.format("%1.3f\n", self:getLastSpeed())
	str1 = str1 .. "field owned:\n"
	str2 = str2 .. tostring(fieldOwned) .. "\n"
	str1 = str1 .. "mass:\n"
	str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass(true) * 1000)
	str1 = str1 .. "mass incl. attach:\n"
	str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass() * 1000)

	if self.isServer then
		local specWheels = self.spec_wheels

		if specWheels ~= nil and table.getn(specWheels.wheels) > 0 then
			local wheelsStrs = {
				"\n",
				"longSlip\n",
				"latSlip\n",
				"load\n",
				"frict.\n",
				"compr.\n",
				"rpm\n",
				"steer.\n",
				"radius\n"
			}

			for i, wheel in ipairs(specWheels.wheels) do
				local susp = 100 * (wheel.netInfo.y - (wheel.positionY + wheel.deltaY - 1.2 * wheel.suspTravel)) / wheel.suspTravel - 20
				local rpm = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * 30 / math.pi
				local longSlip, latSlip = getWheelShapeSlip(wheel.node, wheel.wheelShape)
				local gravity = 9.81
				local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

				if tireLoad ~= nil then
					local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
					local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
					tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
					tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
				else
					tireLoad = 0
				end

				wheelsStrs[1] = wheelsStrs[1] .. string.format("%d:\n", i)
				wheelsStrs[2] = wheelsStrs[2] .. string.format("%2.2f\n", longSlip)
				wheelsStrs[3] = wheelsStrs[3] .. string.format("%2.2f\n", latSlip)
				wheelsStrs[4] = wheelsStrs[4] .. string.format("%2.2f\n", tireLoad / gravity)
				wheelsStrs[5] = wheelsStrs[5] .. string.format("%2.2f\n", wheel.sinkFrictionScaleFactor * wheel.frictionScale * wheel.tireGroundFrictionCoeff)
				wheelsStrs[6] = wheelsStrs[6] .. string.format("%1.0f%%\n", susp)
				wheelsStrs[7] = wheelsStrs[7] .. string.format("%3.1f\n", rpm)
				wheelsStrs[8] = wheelsStrs[8] .. string.format("%6.3f\n", math.deg(wheel.steeringAngle))
				wheelsStrs[9] = wheelsStrs[9] .. string.format("%.2f\n", wheel.radius)
				local longMaxSlip = 1
				local latMaxSlip = 0.9
				local sizeX = 0.11
				local sizeY = 0.15
				local spacingX = 0.028
				local spacingY = 0.013
				local x = 0.028 + (sizeX + spacingX) * (i - 1)
				local longY = 1 - spacingY - sizeY
				local latY = longY - spacingY - sizeY
				local numGraphValues = 20
				local longGraph = wheel.debugLongitudalFrictionGraph

				if longGraph == nil then
					longGraph = Graph:new(numGraphValues, x, longY, sizeX, sizeY, 0, 0.0001, true, "", Graph.STYLE_LINES)

					longGraph:setColor(1, 1, 1, 1)

					wheel.debugLongitudalFrictionGraph = longGraph
				end

				longGraph.maxValue = 0.01

				for s = 1, numGraphValues do
					local longForce, _ = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, (s - 1) / (numGraphValues - 1) * longMaxSlip, latSlip, tireLoad)

					longGraph:setValue(s, longForce)

					longGraph.maxValue = math.max(longGraph.maxValue, longForce)
				end

				local latGraph = wheel.debugLateralFrictionGraph

				if latGraph == nil then
					latGraph = Graph:new(numGraphValues, x, latY, sizeX, sizeY, 0, 0.0001, true, "", Graph.STYLE_LINES)

					latGraph:setColor(1, 1, 1, 1)

					wheel.debugLateralFrictionGraph = latGraph
				end

				latGraph.maxValue = 0.01

				for s = 1, numGraphValues do
					local _, latForce = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, longSlip, (s - 1) / (numGraphValues - 1) * latMaxSlip, tireLoad)
					latForce = math.abs(latForce)

					latGraph:setValue(s, latForce)

					latGraph.maxValue = math.max(latGraph.maxValue, latForce)
				end

				local longSlipOverlay = wheel.debugLongitudalFrictionSlipOverlay

				if longSlipOverlay == nil then
					longSlipOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

					setOverlayColor(longSlipOverlay, 0, 1, 0, 0.2)

					wheel.debugLongitudalFrictionSlipOverlay = longSlipOverlay
				end

				local latSlipOverlay = wheel.debugLateralFrictionSlipOverlay

				if latSlipOverlay == nil then
					latSlipOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

					setOverlayColor(latSlipOverlay, 0, 1, 0, 0.2)

					wheel.debugLateralFrictionSlipOverlay = latSlipOverlay
				end

				longGraph:draw()
				latGraph:draw()

				local longForce, latForce = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, longSlip, latSlip, tireLoad)

				renderOverlay(longSlipOverlay, x, longY, sizeX * math.min(math.abs(longSlip) / longMaxSlip, 1), sizeY * math.min(math.abs(longForce) / longGraph.maxValue, 1))
				renderOverlay(latSlipOverlay, x, latY, sizeX * math.min(math.abs(latSlip) / latMaxSlip, 1), sizeY * math.min(math.abs(latForce) / latGraph.maxValue, 1))
			end

			local str1Height = getTextHeight(getCorrectTextSize(0.02), str1)

			Utils.renderMultiColumnText(0.015, 0.64 - str1Height - 0.005, getCorrectTextSize(0.02), wheelsStrs, 0.008, {
				RenderText.ALIGN_RIGHT,
				RenderText.ALIGN_LEFT
			})
		end

		if motorSpec ~= nil and motorSpec.differentials ~= nil then
			local getSpeedsOfDifferential = nil

			function getSpeedsOfDifferential(self, diff)
				local motorSpec = self.spec_motorized
				local specWheels = self.spec_wheels
				local speed1, speed2 = nil

				if diff.diffIndex1IsWheel then
					local wheel = specWheels.wheels[diff.diffIndex1]
					speed1 = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * wheel.radius
				else
					local s1, s2 = getSpeedsOfDifferential(self, motorSpec.differentials[diff.diffIndex1 + 1])
					speed1 = (s1 + s2) / 2
				end

				if diff.diffIndex2IsWheel then
					local wheel = specWheels.wheels[diff.diffIndex2]
					speed2 = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * wheel.radius
				else
					local s1, s2 = getSpeedsOfDifferential(self, motorSpec.differentials[diff.diffIndex2 + 1])
					speed2 = (s1 + s2) / 2
				end

				return speed1, speed2
			end

			local function getRatioOfDifferential(self, speed1, speed2)
				local ratio = math.abs(math.max(speed1, speed2)) / math.max(math.abs(math.min(speed1, speed2)), 0.001)

				return ratio
			end

			local diffStrs = {
				"\n",
				"torqueRatio\n",
				"maxSpeedRatio\n",
				"actualSpeedRatio\n"
			}

			for i, diff in pairs(motorSpec.differentials) do
				diffStrs[1] = diffStrs[1] .. string.format("%d:\n", i)
				diffStrs[2] = diffStrs[2] .. string.format("%2.2f\n", diff.torqueRatio)
				diffStrs[3] = diffStrs[3] .. string.format("%2.2f\n", diff.maxSpeedRatio)
				local speed1, speed2 = getSpeedsOfDifferential(self, diff)
				local ratio = getRatioOfDifferential(self, speed1, speed2)
				diffStrs[4] = diffStrs[4] .. string.format("%2.2f\n", ratio)
			end

			local str1Height = getTextHeight(getCorrectTextSize(0.02), str1)

			Utils.renderMultiColumnText(0.015, 0.42 - str1Height - 0.005, getCorrectTextSize(0.02), diffStrs, 0.008, {
				RenderText.ALIGN_RIGHT,
				RenderText.ALIGN_LEFT
			})
		end

		if motor ~= nil then
			local sizeX = 0.25
			local sizeY = 0.2
			local x = 0.65
			local y = 0.64 - sizeY
			local curveOverlay = motor.debugCurveOverlay

			if curveOverlay == nil then
				curveOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

				setOverlayColor(curveOverlay, 0, 1, 0, 0.2)

				motor.debugCurveOverlay = curveOverlay
			end

			local torqueCurve = motor:getTorqueCurve()
			local numTorqueValues = #torqueCurve.keyframes
			local minRpm = math.min(motor:getMinRpm(), torqueCurve.keyframes[1].time)
			local maxRpm = math.max(motor:getMaxRpm(), torqueCurve.keyframes[numTorqueValues].time)
			local torqueGraph = motor.debugTorqueGraph
			local powerGraph = motor.debugPowerGraph

			if torqueGraph == nil then
				local numValues = numTorqueValues * 32
				torqueGraph = Graph:new(numValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)

				torqueGraph:setColor(1, 1, 1, 1)

				motor.debugTorqueGraph = torqueGraph
				powerGraph = Graph:new(numValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

				powerGraph:setColor(1, 0, 0, 1)

				motor.debugPowerGraph = powerGraph
				torqueGraph.maxValue = 0.01
				powerGraph.maxValue = 0.01

				for s = 1, numValues do
					local rpm = (s - 1) / (numValues - 1) * (torqueCurve.keyframes[numTorqueValues].time - torqueCurve.keyframes[1].time) + torqueCurve.keyframes[1].time
					local torque = motor:getTorqueCurveValue(rpm)
					local power = torque * 1000 * rpm * math.pi / 30
					local hpPower = power / 735.49875
					local posX = (rpm - minRpm) / (maxRpm - minRpm)

					torqueGraph:setValue(s, torque)

					torqueGraph.maxValue = math.max(torqueGraph.maxValue, torque)

					torqueGraph:setXPosition(s, posX)
					powerGraph:setValue(s, hpPower)

					powerGraph.maxValue = math.max(powerGraph.maxValue, hpPower)

					powerGraph:setXPosition(s, posX)
				end
			end

			torqueGraph:draw()
			powerGraph:draw()
			renderOverlay(curveOverlay, x, y, sizeX * MathUtil.clamp((motor:getNonClampedMotorRpm() - minRpm) / (maxRpm - minRpm), 0, 1), sizeY)

			local y = y - sizeY - 0.013
			local maxSpeed = motor:getMaximumForwardSpeed()
			local effTorqueGraphs = motor.debugEffectiveTorqueGraphs
			local effPowerGraphs = motor.debugEffectivePowerGraphs
			local effGearRatioGraphs = motor.debugEffectiveGearRatioGraphs
			local effRpmGraphs = motor.debugEffectiveRpmGraphs

			if effTorqueGraphs == nil then
				local numVelocityValues = 20
				local numGears = 1

				if motor.minForwardGearRatio == nil and motor.forwardGearRatios ~= nil then
					numGears = #motor.forwardGearRatios
				end

				effTorqueGraphs = {}
				effPowerGraphs = {}
				effGearRatioGraphs = {}
				effRpmGraphs = {}
				motor.debugEffectiveTorqueGraphs = effTorqueGraphs
				motor.debugEffectivePowerGraphs = effPowerGraphs
				motor.debugEffectiveGearRatioGraphs = effGearRatioGraphs
				motor.debugEffectiveRpmGraphs = effRpmGraphs

				for gear = 1, numGears do
					local effTorqueGraph = Graph:new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)

					effTorqueGraph:setColor(1, 1, 1, 1)
					table.insert(effTorqueGraphs, effTorqueGraph)

					local effPowerGraph = Graph:new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effPowerGraph:setColor(1, 0, 0, 1)
					table.insert(effPowerGraphs, effPowerGraph)

					local effGearRatioGraph = Graph:new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effGearRatioGraph:setColor(0.35, 1, 0.85, 1)
					table.insert(effGearRatioGraphs, effGearRatioGraph)

					local effRpmGraph = Graph:new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effRpmGraph:setColor(0.18, 0.18, 1, 1)
					table.insert(effRpmGraphs, effRpmGraph)

					effTorqueGraph.maxValue = 0.01
					effPowerGraph.maxValue = 0.01
					effGearRatioGraph.maxValue = 0.01
					effRpmGraph.maxValue = 0.01

					for s = 1, numVelocityValues do
						local speed = (s - 1) / (numVelocityValues - 1) * maxSpeed
						local gearRatio = nil

						if numGears == 1 then
							_, gearRatio = motor:getBestGear(1, speed * 30 / math.pi, 0, math.huge, 0)
						else
							gearRatio = motor.forwardGearRatios[gear]
						end

						local gearRpm = speed * 30 / math.pi * gearRatio
						local torque = torqueCurve:get(gearRpm)
						local power = torque * 1000 * gearRpm * math.pi / 30
						local hpPower = power / 735.49875

						if minRpm <= gearRpm and gearRpm <= maxRpm then
							effTorqueGraph:setValue(s, torque)

							effTorqueGraph.maxValue = math.max(effTorqueGraph.maxValue, torque)

							effPowerGraph:setValue(s, hpPower)

							effPowerGraph.maxValue = math.max(effPowerGraph.maxValue, hpPower)

							effGearRatioGraph:setValue(s, gearRatio)

							effGearRatioGraph.maxValue = math.max(effGearRatioGraph.maxValue, gearRatio)

							effRpmGraph:setValue(s, gearRpm)

							effRpmGraph.maxValue = math.max(effRpmGraph.maxValue, gearRpm)
						end
					end
				end
			end

			for _, graph in pairs(effTorqueGraphs) do
				graph:draw()
			end

			for _, graph in pairs(effPowerGraphs) do
				graph:draw()
			end

			for _, graph in pairs(effGearRatioGraphs) do
				graph:draw()
			end

			for _, graph in pairs(effRpmGraphs) do
				graph:draw()
			end

			renderOverlay(curveOverlay, x, y, sizeX * MathUtil.clamp(self.lastSpeedReal * 1000 / maxSpeed, 0, 1), sizeY)
		end
	end

	Utils.renderMultiColumnText(0.015, 0.65, getCorrectTextSize(0.02), {
		str1,
		str2
	}, 0.008, {
		RenderText.ALIGN_RIGHT,
		RenderText.ALIGN_LEFT
	})
	Utils.renderMultiColumnText(0.235, 0.65, getCorrectTextSize(0.02), {
		str3,
		str4
	}, 0.008, {
		RenderText.ALIGN_RIGHT,
		RenderText.ALIGN_LEFT
	})
end

function VehicleDebug.drawDebugAttributeRendering(vehicle)
	local x1, y1, z1 = localToWorld(vehicle.rootNode, -vehicle.sizeWidth * 0.5 + vehicle.widthOffset, 1, vehicle.sizeLength * 0.5 + vehicle.lengthOffset)
	local x2, y2, z2 = localToWorld(vehicle.rootNode, vehicle.sizeWidth * 0.5 + vehicle.widthOffset, 1, vehicle.sizeLength * 0.5 + vehicle.lengthOffset)
	local x3, y3, z3 = localToWorld(vehicle.rootNode, -vehicle.sizeWidth * 0.5 + vehicle.widthOffset, 1, -vehicle.sizeLength * 0.5 + vehicle.lengthOffset)
	local x4, y4, z4 = localToWorld(vehicle.rootNode, vehicle.sizeWidth * 0.5 + vehicle.widthOffset, 1, -vehicle.sizeLength * 0.5 + vehicle.lengthOffset)

	drawDebugLine(x1, y1, z1, 0, 0, 1, x2, y2, z2, 0, 0, 1)
	drawDebugLine(x1, y1, z1, 0, 0, 1, x3, y3, z3, 0, 0, 1)
	drawDebugLine(x2, y2, z2, 0, 0, 1, x4, y4, z4, 0, 0, 1)
	drawDebugLine(x3, y3, z3, 0, 0, 1, x4, y4, z4, 0, 0, 1)

	if vehicle.spec_attacherJoints ~= nil then
		for _, implement in pairs(vehicle.spec_attacherJoints.attachedImplements) do
			if implement.object ~= nil then
				local jointDesc = vehicle.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
				local x, y, z = getWorldTranslation(jointDesc.jointTransform)

				drawDebugPoint(x, y, z, 1, 0, 0, 1)

				local groundRaycastResult = {
					raycastCallback = function (self, transformId, x, y, z, distance)
						if vehicle.vehicleNodes[transformId] == nil and implement.object.vehicleNodes[transformId] == nil then
							self.groundDistance = distance

							return false
						end

						return true
					end,
					vehicle = vehicle,
					object = implement.object,
					groundDistance = 0
				}

				raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)
				drawDebugLine(x, y, z, 0, 1, 0, x, y - groundRaycastResult.groundDistance, z, 0, 1, 0)
				drawDebugPoint(x, y - groundRaycastResult.groundDistance, z, 1, 0, 0, 1)
				Utils.renderTextAtWorldPosition(x, y + 0.1, z, string.format("%.4f", groundRaycastResult.groundDistance), getCorrectTextSize(0.02), 0)

				local attacherJoint = implement.object:getActiveInputAttacherJoint()

				if attacherJoint.heightNode ~= nil then
					local x, y, z = getWorldTranslation(attacherJoint.heightNode)
					local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

					DebugUtil.drawDebugNode(attacherJoint.heightNode, string.format("HeightNode: %.3f", y - h))
				end
			end
		end

		for _, attacherJoint in pairs(vehicle:getAttacherJoints()) do
			DebugUtil.drawDebugNode(attacherJoint.jointTransform, getName(attacherJoint.jointTransform))
		end
	end

	if vehicle.spec_workArea ~= nil then
		local typedColor = {}
		local numTypes = 0

		for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
			local color = typedColor[workArea.type]

			if color == nil then
				numTypes = numTypes + 1
				color = VehicleDebug.WORKAREA_COLORS[numTypes]
				typedColor[workArea.type] = color
			end

			local r, g, b, _ = unpack(color)
			local x, y, z = getWorldTranslation(workArea.start)
			local x1, y1, z1 = getWorldTranslation(workArea.width)
			local x2, y2, z2 = getWorldTranslation(workArea.height)
			local x3 = x2 - x + x1
			local y3 = y2 - y + y1
			local z3 = z2 - z + z1
			y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
			y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, y1, z1)
			y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, y2, z2)
			y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, y3, z3)

			DebugUtil.drawDebugArea(workArea.start, workArea.width, workArea.height, r, g, b, true)

			local x = x2 + (x1 - x2) * 0.5
			local z = z2 + (z1 - z2) * 0.5
			local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
			local isActive = vehicle:getIsWorkAreaActive(workArea)
			local textColor = isActive and {
				0.5,
				1,
				0.5,
				1
			} or {
				1,
				0.1,
				0.1,
				1
			}

			Utils.renderTextAtWorldPosition(x, y + 0.1, z, tostring(g_workAreaTypeManager:getWorkAreaTypeNameByIndex(workArea.type)), getCorrectTextSize(0.015), -getCorrectTextSize(0.015) * 0.5, textColor)
		end
	end

	if vehicle.getTipOcclusionAreas ~= nil then
		for _, occlusionArea in pairs(vehicle:getTipOcclusionAreas()) do
			DebugUtil.drawDebugArea(occlusionArea.start, occlusionArea.width, occlusionArea.height, 1, 1, 0, true, false, false)
		end
	end

	if vehicle.spec_foliageBending ~= nil then
		local offset = 0.25

		for _, bendingNode in ipairs(vehicle.spec_foliageBending.bendingNodes) do
			if bendingNode.id ~= nil then
				DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset, 1, 0, 0)
				DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX - offset, bendingNode.maxX + offset, bendingNode.minZ - offset, bendingNode.maxZ + offset, bendingNode.yOffset, 0, 1, 0)
			end
		end
	end

	if vehicle:getIsActiveForInput() and vehicle.spec_enterable ~= nil then
		local spec = vehicle.spec_enterable
		local camera = spec.cameras[spec.camIndex]

		if camera ~= nil then
			local name = getName(camera.cameraPositionNode)
			local x, y, z = getTranslation(camera.cameraPositionNode)
			local rotationNode = camera.cameraPositionNode

			if camera.rotateNode ~= nil then
				rotationNode = camera.rotateNode
			end

			local rx, ry, rz = getRotation(rotationNode)

			if camera.hasExtraRotationNode then
				rx = -((math.pi - rx) % (2 * math.pi))
				ry = (ry + math.pi) % (2 * math.pi)
				rz = (rz - math.pi) % (2 * math.pi)
			end

			local text = string.format("camera '%s': translation: %.2f %.2f %.2f  rotation: %.2f %.2f %.2f", name, x, y, z, math.deg(rx), math.deg(ry), math.deg(rz))

			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 1)
			renderText(0.5 + 1 / g_screenWidth, 0.95 - 1 / g_screenHeight, 0.02, text)
			renderText(0.5 + 1 / g_screenWidth, 0.98 - 1 / g_screenHeight, 0.05, "______________________________________________________________________")
			setTextColor(1, 1, 1, 1)
			renderText(0.5, 0.95, 0.02, text)
			renderText(0.5, 0.98, 0.05, "______________________________________________________________________")
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end

	for i, component in pairs(vehicle.components) do
		local x, y, z = getCenterOfMass(component.node)
		x, y, z = localToWorld(component.node, x, y, z)
		local dirX, dirY, dirZ = localDirectionToWorld(component.node, 0, 0, 1)
		local upX, upY, upZ = localDirectionToWorld(component.node, 0, 1, 0)

		DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, "CoM comp" .. i, false)
	end

	if vehicle.spec_ikChains ~= nil then
		IKUtil.debugDrawChains(vehicle.spec_ikChains.chains, true)
	end
end

function VehicleDebug.drawDebugAIRendering(vehicle)
	if vehicle.getAIMarkers ~= nil and vehicle:getIsAIActive() and vehicle:getCanImplementBeUsedForAI() then
		local leftMarker, rightMarker, backMarker = vehicle:getAIMarkers()

		DebugUtil.drawDebugNode(leftMarker, getName(leftMarker), true)
		DebugUtil.drawDebugNode(rightMarker, getName(rightMarker), true)
		DebugUtil.drawDebugNode(backMarker, getName(backMarker), true)

		local reverserNode = vehicle:getAIToolReverserDirectionNode()

		if reverserNode ~= nil and reverserNode ~= backMarker then
			DebugUtil.drawDebugNode(reverserNode, getName(reverserNode), true)
		end
	end

	local root = vehicle:getRootVehicle()

	if root.getIsControlled ~= nil and root:getIsControlled() and root.actionController ~= nil then
		root.actionController:drawDebugRendering()
	end
end

function VehicleDebug.drawDebugValues(vehicle)
	local information = {}

	for k, v in ipairs(vehicle.specializations) do
		if v.updateDebugValues ~= nil then
			local values = {}

			v.updateDebugValues(vehicle, values)

			if #values > 0 then
				local info = {
					title = vehicle.specializationNames[k],
					content = values
				}

				table.insert(information, info)
			end
		end
	end

	local d = DebugInfoTable:new()

	d:createWithNodeToCamera(vehicle.rootNode, 4, information, 0.05)
	g_debugManager:addFrameElement(d)
end

function VehicleDebug.drawSoundDebugValues(vehicle)
	local function getColumn(...)
		local ret = ""

		for _, str in ipairs({
			...
		}) do
			if type(str) == "number" then
				str = string.format("%.2f", str)
			end

			ret = ret .. "\n" .. str
		end

		return ret
	end

	local curY = 0.98
	local textSize = 0.015
	local spacing = 0.0175

	for _, sample in pairs(g_soundManager.orderedSamples) do
		local isSurfaceSound = false

		for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
			if surfaceSound.name == sample.sampleName then
				isSurfaceSound = true
			end
		end

		if sample.modifierTargetObject == vehicle and not isSurfaceSound then
			local isModifiedSample = false
			local modVolume = g_soundManager:getModifierFactor(sample, "volume")
			local modPitch = g_soundManager:getModifierFactor(sample, "pitch")
			local modLowPassGain = g_soundManager:getModifierFactor(sample, "lowpassGain")
			local texts = {
				getColumn(string.format("%s isPlaying(%s)", sample.sampleName, g_soundManager:getIsSamplePlaying(sample)), "volume:", "pitch:", "lowpassGain:"),
				getColumn("default", sample.current.volume, sample.current.pitch, sample.current.lowpassGain),
				getColumn("current", sample.current.volume * modVolume, sample.current.pitch * modPitch, sample.current.lowpassGain * modLowPassGain),
				getColumn("modValue", modVolume, modPitch, modLowPassGain)
			}

			for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
				local column = {
					type.name
				}
				local isAvailable = false

				for _, attribute in pairs({
					"volume",
					"pitch",
					"lowpassGain"
				}) do
					local changeValue, t, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)
					isAvailable = isAvailable or available

					table.insert(column, string.format("%.2f -> %.2f", t, changeValue))
				end

				if isAvailable then
					isModifiedSample = true

					table.insert(texts, getColumn(unpack(column)))
				end
			end

			if isModifiedSample then
				Utils.renderMultiColumnText(0.05, curY, textSize, texts, 0.06, {
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT,
					RenderText.ALIGN_LEFT
				})

				curY = curY - spacing * 4.2
			end
		end
	end
end

function VehicleDebug.consoleCommandAnalyze(unusedSelf)
	if g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.isServer then
		local self = g_currentMission.controlledVehicle:getSelectedVehicle()

		if self == nil then
			self = g_currentMission.controlledVehicle
		end

		print("Analyzing vehicle '" .. self.configFileName .. "'. Make sure vehicle is standing on a flat plane parallel to xz-plane")

		local groundRaycastResult = {
			raycastCallback = function (self, transformId, x, y, z, distance)
				if self.vehicle.vehicleNodes[transformId] ~= nil then
					return true
				end

				if self.vehicle.aiTrafficCollisionTrigger == transformId then
					return true
				end

				if transformId ~= g_currentMission.terrainRootNode then
					print("Warning: Vehicle is not standing on ground! " .. getName(transformId))
				end

				self.groundDistance = distance

				return false
			end
		}

		if self.spec_attacherJoints ~= nil then
			for i, attacherJoint in ipairs(self.spec_attacherJoints.attacherJoints) do
				local trx, try, trz = getRotation(attacherJoint.jointTransform)

				setRotation(attacherJoint.jointTransform, unpack(attacherJoint.jointOrigRot))

				if attacherJoint.rotationNode ~= nil or attacherJoint.rotationNode2 ~= nil then
					local rx, ry, rz = nil

					if attacherJoint.rotationNode ~= nil then
						rx, ry, rz = getRotation(attacherJoint.rotationNode)
					end

					local rx2, ry2, rz2 = nil

					if attacherJoint.rotationNode2 ~= nil then
						rx2, ry2, rz2 = getRotation(attacherJoint.rotationNode2)
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.upperRotation))
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.upperRotation2))
					end

					local x, y, z = getWorldTranslation(attacherJoint.jointTransform)
					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self

					raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.01 then
						print(" Issue found: Attacher joint " .. i .. " has invalid upperDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.upperDistanceToGround)
					end

					if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
						local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
						local angle = math.deg(math.acos(MathUtil.clamp(dy, -1, 1)))
						local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)

						if dxy < 0 then
							angle = -angle
						end

						if math.abs(angle - math.deg(attacherJoint.upperRotationOffset)) > 1 then
							print(" Issue found: Attacher joint " .. i .. " has invalid upperRotationOffset. True value is: " .. angle .. ". Value in XML: " .. math.deg(attacherJoint.upperRotationOffset))
						end
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.lowerRotation))
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.lowerRotation2))
					end

					local x, y, z = getWorldTranslation(attacherJoint.jointTransform)
					groundRaycastResult.groundDistance = 0

					raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.01 then
						print(" Issue found: Attacher joint " .. i .. " has invalid lowerDistanceToGround. True value: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.lowerDistanceToGround)
					end

					if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
						local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
						local angle = math.deg(math.acos(MathUtil.clamp(dy, -1, 1)))
						local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)

						if dxy < 0 then
							angle = -angle
						end

						if math.abs(angle - math.deg(attacherJoint.lowerRotationOffset)) > 1 then
							print(" Issue found: Attacher joint " .. i .. " has invalid lowerRotationOffset. True value is: " .. angle .. ". Value in XML: " .. math.deg(attacherJoint.lowerRotationOffset))
						end
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, rx, ry, rz)
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, rx2, ry2, rz2)
					end
				end

				setRotation(attacherJoint.jointTransform, trx, try, trz)

				if attacherJoint.transNode ~= nil then
					local sx, sy, sz = getTranslation(attacherJoint.transNode)
					local _, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMaxY, 0)

					setTranslation(attacherJoint.transNode, sx, y, sz)

					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self
					local wx, wy, wz = getWorldTranslation(attacherJoint.transNode)

					raycastAll(wx, wy, wz, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.02 then
						print(" Issue found: Attacher joint " .. i .. " has invalid upperDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.upperDistanceToGround)
					end

					_, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMinY, 0)

					setTranslation(attacherJoint.transNode, sx, y, sz)

					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self
					local wx, wy, wz = getWorldTranslation(attacherJoint.transNode)

					raycastAll(wx, wy, wz, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.02 then
						print(" Issue found: Attacher joint " .. i .. " has invalid lowerDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.lowerDistanceToGround)
					end

					setTranslation(attacherJoint.transNode, sx, sy, sz)
				end
			end
		end

		if self.spec_wheels ~= nil then
			for i, wheel in ipairs(self.spec_wheels.wheels) do
				local _, comY, _ = getCenterOfMass(wheel.node)
				local forcePointY = wheel.positionY + wheel.deltaY - wheel.radius * wheel.forcePointRatio

				if comY < forcePointY then
					print(string.format(" Issue found: Wheel %d has force point higher than center of mass. %.2f > %.2f. This can lead to undesired driving behavior (inward-leaning).", i, forcePointY, comY))
				end

				local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

				if tireLoad ~= nil then
					local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
					local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
					tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
					local gravity = 9.81
					tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
					tireLoad = tireLoad / gravity

					if math.abs(tireLoad - wheel.restLoad) > 0.2 then
						print(string.format(" Issue found: Wheel %d has wrong restLoad. %.2f vs. %.2f in XML. Verify that this leads to the desired behavior.", i, tireLoad, wheel.restLoad))
					end
				end
			end
		end

		return "Analyzed vehicle"
	end

	return "Failed to analyze vehicle. Invalid controlled vehicle"
end

function VehicleDebug:moveUpperRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local vehicle = VehicleDebug.currentAttacherJointVehicle

		if vehicle.getAttacherVehicle ~= nil then
			local attacherVehicle = vehicle:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local implement = attacherVehicle:getImplementByObject(vehicle)

				if implement ~= nil then
					local jointDescIndex = implement.jointDescIndex
					local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]

					if jointDesc.rotationNode ~= nil then
						jointDesc.upperRotation[1] = jointDesc.upperRotation[1] + math.rad(inputValue * 0.002 * 16)
						jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001

						print("upperRotation: " .. math.deg(jointDesc.upperRotation[1]))
					end
				end
			end
		end
	end
end

function VehicleDebug:moveLowerRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local vehicle = VehicleDebug.currentAttacherJointVehicle

		if vehicle.getAttacherVehicle ~= nil then
			local attacherVehicle = vehicle:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local implement = attacherVehicle:getImplementByObject(vehicle)

				if implement ~= nil then
					local jointDescIndex = implement.jointDescIndex
					local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]

					if jointDesc.rotationNode ~= nil then
						jointDesc.lowerRotation[1] = jointDesc.lowerRotation[1] + math.rad(inputValue * 0.002 * 16)
						jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001

						print("lowerRotation: " .. math.deg(jointDesc.lowerRotation[1]))
					end
				end
			end
		end
	end
end

function VehicleDebug.drawDebugAttacherJoints(vehicle)
	VehicleDebug.currentAttacherJointVehicle = vehicle
end

addConsoleCommand("gsVehicleAnalyze", "Analyze vehicle", "VehicleDebug.consoleCommandAnalyze", nil)
addConsoleCommand("gsVehicleDebug", "Toggles the vehicle debug values rendering", "VehicleDebug.consoleCommandVehicleDebug", nil)
addConsoleCommand("gsVehicleDebugAttacherJoints", "Toggles the vehicle attacherJoint debug rendering", "VehicleDebug.consoleCommandVehicleDebugAttacherJoints", nil)
addConsoleCommand("gsVehicleDebugAttributes", "Toggles the vehicle attribute debug rendering", "VehicleDebug.consoleCommandVehicleDebugAttributes", nil)
addConsoleCommand("gsVehicleDebugAI", "Toggles the vehicle AI debug rendering", "VehicleDebug.consoleCommandVehicleDebugAI", nil)
addConsoleCommand("gsVehicleDebugPhysics", "Toggles the vehicle physics debug rendering", "VehicleDebug.consoleCommandVehicleDebugPhysics", nil)
addConsoleCommand("gsVehicleDebugSounds", "Toggles the vehicle sound debug rendering", "VehicleDebug.consoleCommandVehicleDebugSounds", nil)
addConsoleCommand("gsVehicleDebugTipping", "Toggles the tipping debug rendering", "VehicleDebug.consoleCommandVehicleDebugTipping", nil)
