RailroadCrossing = {}
local RailroadCrossing_mt = Class(RailroadCrossing)

function RailroadCrossing:new(isServer, isClient, trainSystem, nodeId, customMt)
	local self = {}

	setmetatable(self, customMt or RailroadCrossing_mt)

	self.trainSystem = trainSystem
	self.nodeId = nodeId
	self.isServer = isServer
	self.isClient = isClient

	return self
end

function RailroadCrossing:loadFromXML(xmlFile, key)
	self.rootNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#rootNode"))
	self.startDistance = Utils.getNoNil(getXMLInt(xmlFile, key .. ".activation#startDistance"), 50)
	self.endDistance = Utils.getNoNil(getXMLInt(xmlFile, key .. ".activation#endDistance"), 50)
	self.isActive = false
	self.splinePositionTime = 0
	self.doCloseCrossing = false
	self.gateDirection = 1
	self.gates = {}
	self.signals = {}
	self.samples = {}
	local i = 0

	while true do
		local gateKey = string.format("%s.gates.gate(%d)", key, i)

		if not hasXMLProperty(xmlFile, gateKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, gateKey .. "#node"))
		local animCurve = AnimCurve:new(linearInterpolatorN)
		local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, gateKey .. "#startRot"))
		local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, gateKey .. "#startTrans"))
		local drx, dry, drz = getRotation(node)
		rx = Utils.getNoNilRad(rx, drx)
		ry = Utils.getNoNilRad(ry, dry)
		rz = Utils.getNoNilRad(rz, drz)
		local dx, dy, dz = getTranslation(node)
		x = Utils.getNoNil(x, dx)
		y = Utils.getNoNil(y, dy)
		z = Utils.getNoNil(z, dz)

		animCurve:addKeyframe({
			x,
			y,
			z,
			rx,
			ry,
			rz,
			time = 0
		})
		setTranslation(node, x, y, z)
		setRotation(node, rx, ry, rz)

		rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, gateKey .. "#endRot"))
		x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, gateKey .. "#endTrans"))
		rx = Utils.getNoNilRad(rx, drx)
		ry = Utils.getNoNilRad(ry, dry)
		rz = Utils.getNoNilRad(rz, drz)
		x = Utils.getNoNil(x, dx)
		y = Utils.getNoNil(y, dy)
		z = Utils.getNoNil(z, dz)

		animCurve:addKeyframe({
			x,
			y,
			z,
			rx,
			ry,
			rz,
			time = 1
		})

		local duration = Utils.getNoNil(getXMLFloat(xmlFile, gateKey .. "#duration"), 3) * 1000
		local closingOffset = Utils.getNoNil(getXMLFloat(xmlFile, gateKey .. "#closingOffset"), 0) * 1000

		table.insert(self.gates, {
			animTime = 0,
			currentOffset = 0,
			node = node,
			animCurve = animCurve,
			duration = duration,
			closingOffset = closingOffset
		})

		i = i + 1
	end

	local lightsProfile = g_gameSettings:getValue("lightsProfile")
	local i = 0

	while true do
		local signalKey = string.format("%s.signals.signal(%d)", key, i)

		if not hasXMLProperty(xmlFile, signalKey) then
			break
		end

		local signalNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, signalKey .. "#node"))

		if signalNode ~= nil then
			setVisibility(signalNode, false)

			local signal = {
				node = signalNode,
				alternatingLights = Utils.getNoNil(getXMLBool(xmlFile, signalKey .. "#alternatingLights")),
				lights = {}
			}

			for j = 0, getNumOfChildren(signal.node) - 1 do
				local light = {
					node = getChildAt(signal.node, j)
				}

				if getNumOfChildren(light.node) > 0 then
					light.realLight = getChildAt(light.node, 0)

					if lightsProfile == GS_PROFILE_HIGH or lightsProfile == GS_PROFILE_VERY_HIGH then
						light.defaultColor = {
							getLightColor(light.realLight)
						}
					else
						setVisibility(light.realLight, false)

						light.realLight = nil
					end
				end

				if signal.alternatingLights and #signal.lights % 2 == 0 then
					setShaderParameter(light.node, "blinkOffset", 0.5, 0, 0, 0, false)

					if light.realLight ~= nil then
						setLightColor(light.realLight, light.defaultColor[1] * 0.2, light.defaultColor[2] * 0.2, light.defaultColor[3] * 0.2)
					end
				end

				table.insert(signal.lights, light)
			end

			table.insert(self.signals, signal)
		end

		i = i + 1
	end

	if self.isClient then
		self.samples.crossing = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "crossing", g_currentMission.loadingMapBaseDirectory, self.nodeId, 0, AudioGroup.ENVIRONMENT, nil, self)
		self.isCrossingSamplePlaying = false
	end

	self.trainSystem:addSplinePositionUpdateListener(self)

	return true
end

function RailroadCrossing:delete()
	if self.isClient then
		g_soundManager:deleteSample(self.samples.crossing)

		self.samples.crossing = nil
	end

	self.trainSystem:removeSplinePositionUpdateListener(self)
end

function RailroadCrossing:setSplineTimeByPosition(t, splineLength)
	t = SplineUtil.getValidSplineTime(t)
	self.splinePositionTime = t
	self.startTime = t - self.startDistance / splineLength
	self.endTime = t + self.endDistance / splineLength
end

function RailroadCrossing:update(dt)
	if self.doCloseCrossing and self.gateDirection == 1 or not self.doCloseCrossing and self.gateDirection == -1 then
		self:updateGates(dt, self.gateDirection)
	end

	if self.isActive then
		local alpha = MathUtil.clamp(math.cos(7 * getShaderTimeSec()) + 0.2, 0, 1)
		local alpha2 = MathUtil.clamp(math.cos(7 * getShaderTimeSec() + math.pi) + 0.2, 0, 1)

		for _, signal in pairs(self.signals) do
			for k, light in pairs(signal.lights) do
				if light.realLight ~= nil then
					local currentAlpha = alpha

					if signal.alternatingLights and k % 2 == 1 then
						currentAlpha = alpha2
					end

					setLightColor(light.realLight, light.defaultColor[1] * currentAlpha, light.defaultColor[2] * currentAlpha, light.defaultColor[3] * currentAlpha)
				end
			end
		end
	end
end

function RailroadCrossing:updateGates(dt, direction)
	local isAnimDone = true

	for _, gate in pairs(self.gates) do
		if gate.currentOffset == 0 then
			gate.animTime = MathUtil.clamp(gate.animTime + direction * dt / gate.duration, 0, 1)
			local v = gate.animCurve:get(gate.animTime)

			setTranslation(gate.node, v[1], v[2], v[3])
			setRotation(gate.node, v[4], v[5], v[6])
		else
			gate.currentOffset = math.max(gate.currentOffset - dt, 0)
		end

		isAnimDone = isAnimDone and (gate.animTime == 0 or gate.animTime == 1) and gate.closingOffset == 0
	end

	if isAnimDone then
		self.gateDirection = self.gateDirection * -1
	end
end

function RailroadCrossing:onSplinePositionTimeUpdate(startTime, endTime)
	startTime = SplineUtil.getValidSplineTime(startTime)
	endTime = SplineUtil.getValidSplineTime(endTime)
	local doCloseCrossing = self.startTime < startTime and startTime < self.endTime or self.startTime < endTime and endTime < self.endTime

	if doCloseCrossing ~= self.doCloseCrossing then
		for _, signal in pairs(self.signals) do
			setVisibility(signal.node, doCloseCrossing)
		end

		self.isActive = doCloseCrossing

		if doCloseCrossing then
			for _, gate in pairs(self.gates) do
				if gate.animTime == 0 then
					gate.currentOffset = gate.closingOffset
				end
			end

			self.gateDirection = 1

			if g_client ~= nil and not self.isCrossingSamplePlaying then
				g_soundManager:playSample(self.samples.crossing)

				self.isCrossingSamplePlaying = true
			end
		else
			self.gateDirection = -1

			if g_client ~= nil and self.isCrossingSamplePlaying then
				g_soundManager:stopSample(self.samples.crossing)

				self.isCrossingSamplePlaying = false
			end
		end

		self.doCloseCrossing = doCloseCrossing
	end
end
