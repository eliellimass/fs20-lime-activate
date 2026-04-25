source("dataS/scripts/vehicles/specializations/events/VehicleSetBeaconLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetTurnLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetLightEvent.lua")

Lights = {
	TURNLIGHT_OFF = 0,
	TURNLIGHT_LEFT = 1,
	TURNLIGHT_RIGHT = 2,
	TURNLIGHT_HAZARD = 3,
	turnLightSendNumBits = 3,
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onTurnLightStateChanged")
		SpecializationUtil.registerEvent(vehicleType, "onBrakeLightsVisibilityChanged")
		SpecializationUtil.registerEvent(vehicleType, "onReverseLightsVisibilityChanged")
		SpecializationUtil.registerEvent(vehicleType, "onLightsTypesMaskChanged")
		SpecializationUtil.registerEvent(vehicleType, "onBeaconLightsVisibilityChanged")
		SpecializationUtil.registerEvent(vehicleType, "onDeactivateLights")
	end
}

function Lights.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRealLightSetup", Lights.loadRealLightSetup)
	SpecializationUtil.registerFunction(vehicleType, "loadRealLights", Lights.loadRealLights)
	SpecializationUtil.registerFunction(vehicleType, "loadVisualLights", Lights.loadVisualLights)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForLights", Lights.getIsActiveForLights)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInteriorLights", Lights.getIsActiveForInteriorLights)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleLight", Lights.getCanToggleLight)
	SpecializationUtil.registerFunction(vehicleType, "getUseHighProfile", Lights.getUseHighProfile)
	SpecializationUtil.registerFunction(vehicleType, "setNextLightsState", Lights.setNextLightsState)
	SpecializationUtil.registerFunction(vehicleType, "setLightsTypesMask", Lights.setLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "getLightsTypesMask", Lights.getLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "setTurnLightState", Lights.setTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "getTurnLightState", Lights.getTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "setBrakeLightsVisibility", Lights.setBrakeLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setBeaconLightsVisibility", Lights.setBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getBeaconLightsVisibility", Lights.getBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setReverseLightsVisibility", Lights.setReverseLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setInteriorLightsVisibility", Lights.setInteriorLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "deactivateLights", Lights.deactivateLights)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateLightsOnLeave", Lights.getDeactivateLightsOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "loadSharedLight", Lights.loadSharedLight)
	SpecializationUtil.registerFunction(vehicleType, "updateAILights", Lights.updateAILights)
end

function Lights.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStartReverseDirectionChange", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAutomatedTrainTravelActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIBlock", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIContinue", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIEnd", Lights)
end

function Lights:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.lights.low.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.lights.high.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.lights.low.light#realLight", "vehicle.lights.realLights.low.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.lights.high.light#realLight", "vehicle.lights.realLights.high.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.brakeLights.brakeLight#realLight", "vehicle.lights.realLights.high.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.brakeLights.brakeLight#decoration", "vehicle.lights.brakeLights.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnLights.turnLightLeft#realLight", "vehicle.lights.realLights.high.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnLights.turnLightLeft#decoration", "vehicle.lights.turnLights.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnLights.turnLightRight#realLight", "vehicle.lights.realLights.high.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnLights.turnLightRight#decoration", "vehicle.lights.turnLights.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")

	local spec = self.spec_lights
	spec.shaderDefaultLights = {}
	spec.shaderBrakeLights = {}
	spec.shaderLeftTurnLights = {}
	spec.shaderRightTurnLights = {}
	spec.shaderReverseLights = {}
	spec.realLights = {
		low = {
			lightTypes = {},
			turnLightsLeft = {},
			turnLightsRight = {},
			brakeLights = {},
			reverseLights = {},
			interiorLights = {}
		},
		high = {
			lightTypes = {},
			turnLightsLeft = {},
			turnLightsRight = {},
			brakeLights = {},
			reverseLights = {},
			interiorLights = {}
		}
	}
	spec.defaultLights = {}
	spec.brakeLights = {}
	spec.reverseLights = {}
	spec.turnLightsLeft = {}
	spec.turnLightsRight = {}
	spec.lightsTypesMask = 0
	spec.currentLightState = 0
	spec.numLightTypes = 0
	spec.lightStates = {}
	local registeredLightTypes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.lights.states.state(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local lightTypes = {
			StringUtil.getVectorFromString(getXMLString(self.xmlFile, key .. "#lightTypes"))
		}

		for _, lightType in pairs(lightTypes) do
			if registeredLightTypes[lightType] == nil then
				registeredLightTypes[lightType] = lightType
				spec.numLightTypes = spec.numLightTypes + 1
			end
		end

		table.insert(spec.lightStates, lightTypes)

		i = i + 1
	end

	local function loadLightsMaskFromXML(xmlFile, key, default)
		local lightTypesStr = Utils.getNoNil(getXMLString(xmlFile, key), default)
		local lightTypes = {
			StringUtil.getVectorFromString(lightTypesStr)
		}
		local lightsTypesMask = 0

		for _, lightType in pairs(lightTypes) do
			lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
		end

		return lightsTypesMask
	end

	spec.aiLightsTypesMask = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.aiState#lightTypes", "0")
	spec.aiLightsTypesMaskWork = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.aiState#lightTypesWork", "0 1 2")
	spec.sharedLights = {}
	local i = 0

	while true do
		local key = string.format("vehicle.lights.sharedLight(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local sharedLight = {}

		if self:loadSharedLight(self.xmlFile, key, sharedLight) then
			table.insert(spec.sharedLights, sharedLight)
		end

		i = i + 1
	end

	local realLightToLight = {}

	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.low", spec.realLights.low, realLightToLight)
	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.high", spec.realLights.high, realLightToLight)
	self:loadVisualLights(self.xmlFile, "vehicle.lights.defaultLights.defaultLight", true, spec.defaultLights, spec.shaderDefaultLights)
	self:loadVisualLights(self.xmlFile, "vehicle.lights.brakeLights.brakeLight", false, spec.brakeLights, spec.shaderBrakeLights)
	self:loadVisualLights(self.xmlFile, "vehicle.lights.reverseLights.reverseLight", false, spec.reverseLights, spec.shaderReverseLights)
	self:loadVisualLights(self.xmlFile, "vehicle.lights.turnLights.turnLightLeft", false, spec.turnLightsLeft, spec.shaderLeftTurnLights)
	self:loadVisualLights(self.xmlFile, "vehicle.lights.turnLights.turnLightRight", false, spec.turnLightsRight, spec.shaderRightTurnLights)

	spec.brakeLightsVisibility = false
	spec.reverseLightsVisibility = false
	spec.turnLightState = Lights.TURNLIGHT_OFF
	spec.hasTurnLights = #spec.turnLightsLeft > 0 or #spec.turnLightsRight > 0
	spec.turnLightRepetitionCount = 0
	spec.realLightsAllowed = true
	spec.actionEventsActiveChange = {}
	spec.beaconLights = {}
	local i = 0

	while true do
		local key = string.format("vehicle.lights.beaconLights.beaconLight(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)

		if node ~= nil then
			local lightXmlFilename = getXMLString(self.xmlFile, key .. "#filename")

			if lightXmlFilename ~= nil then
				lightXmlFilename = Utils.getFilename(lightXmlFilename, self.baseDirectory)
				local lightXmlFile = loadXMLFile("beaconLightXML", lightXmlFilename)

				if lightXmlFile ~= nil and lightXmlFile ~= 0 then
					local i3dFilename = getXMLString(lightXmlFile, "beaconLight.filename")

					if i3dFilename ~= nil then
						local i3dNode = g_i3DManager:loadSharedI3DFile(i3dFilename, self.baseDirectory, false, false, false)

						if i3dNode ~= nil and i3dNode ~= 0 then
							local rootNode = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, "beaconLight.rootNode#node"))
							local rotatorNode = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, "beaconLight.rotator#node"))
							local speed = getXMLFloat(lightXmlFile, "beaconLight.rotator#speed") or 0.015
							local lightNode = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, "beaconLight.light#node"))
							local lightShaderNode = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, "beaconLight.light#shaderNode"))
							local intensity = getXMLFloat(lightXmlFile, "beaconLight.light#intensity") or 1000
							local realLightNode = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, "beaconLight.realLight#node"))

							if rootNode ~= nil and (lightNode ~= nil or lightShaderNode ~= nil) then
								link(node, rootNode)
								setTranslation(rootNode, 0, 0, 0)

								local light = {
									filename = i3dFilename,
									rootNode = rootNode,
									rotatorNode = rotatorNode,
									lightNode = lightNode,
									lightShaderNode = lightShaderNode,
									realLightNode = realLightNode,
									speed = speed,
									intensity = intensity
								}

								if realLightNode ~= nil then
									light.defaultColor = {
										getLightColor(realLightNode)
									}

									setVisibility(realLightNode, false)
								end

								if lightNode ~= nil then
									setVisibility(lightNode, false)
								end

								if lightShaderNode ~= nil then
									local _, y, z, w = getShaderParameter(lightShaderNode, "lightControl")

									setShaderParameter(lightShaderNode, "lightControl", 0, y, z, w, false)
								end

								if light.speed > 0 then
									local rot = math.random(0, math.pi * 2)

									if light.rotatorNode ~= nil then
										setRotation(light.rotatorNode, 0, rot, 0)
									end
								end

								table.insert(spec.beaconLights, light)
							end

							delete(i3dNode)
						end
					end

					delete(lightXmlFile)
				end
			end
		end

		i = i + 1
	end

	spec.beaconLightsActive = false

	if self.isClient ~= nil then
		spec.samples = {
			toggleLights = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "toggleLights", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			turnLight = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "turnLight", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "lightsTypesMask",
			valueTypeToLoad = "lightState",
			valueObject = spec,
			additionalAttributesFunc = Lights.dashboardLightAttributes,
			stateFunc = Lights.dashboardLightState
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightLeft",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_LEFT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightRight",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_RIGHT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightHazard",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightAny",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_LEFT,
				Lights.TURNLIGHT_RIGHT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "beaconLightsActive",
			valueTypeToLoad = "beaconLight",
			valueObject = spec
		})
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Lights:onDelete()
	local spec = self.spec_lights

	for _, beaconLight in pairs(spec.beaconLights) do
		if beaconLight.filename ~= nil then
			g_i3DManager:releaseSharedI3DFile(beaconLight.filename, self.baseDirectory, true)
		end
	end

	for _, sharedLight in pairs(spec.sharedLights) do
		g_i3DManager:releaseSharedI3DFile(sharedLight.filename, self.baseDirectory, true)
	end

	if self.isClient ~= nil then
		for _, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end
	end
end

function Lights:onReadStream(streamId, connection)
	local lightsTypesMask = streamReadInt32(streamId)

	self:setLightsTypesMask(lightsTypesMask, true, true)

	local beaconLightsActive = streamReadBool(streamId)

	self:setBeaconLightsVisibility(beaconLightsActive, true, true)

	local turnLightState = streamReadUIntN(streamId, Lights.turnLightSendNumBits)

	self:setTurnLightState(turnLightState, true, true)
end

function Lights:onWriteStream(streamId, connection)
	local spec = self.spec_lights

	streamWriteInt32(streamId, spec.lightsTypesMask)
	streamWriteBool(streamId, spec.beaconLightsActive)
	streamWriteUIntN(streamId, spec.turnLightState, Lights.turnLightSendNumBits)
end

function Lights:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local isRootAttacherVehicle = streamReadBool(streamId)

		if isRootAttacherVehicle then
			local brakeLightsVisibility = streamReadBool(streamId)
			local reverseLightsVisibility = streamReadBool(streamId)

			self:setBrakeLightsVisibility(brakeLightsVisibility)
			self:setReverseLightsVisibility(reverseLightsVisibility)
		end
	end
end

function Lights:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_lights

	if not connection:getIsServer() then
		local rootAttacherVehicle = self:getRootVehicle()

		if rootAttacherVehicle == self then
			streamWriteBool(streamId, true)
			streamWriteBool(streamId, spec.brakeLightsVisibility)
			streamWriteBool(streamId, spec.reverseLightsVisibility)
		else
			streamWriteBool(streamId, false)
		end
	end
end

function Lights:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_lights

	if spec.beaconLightsActive then
		for _, beaconLight in pairs(spec.beaconLights) do
			if beaconLight.rotatorNode ~= nil then
				rotate(beaconLight.rotatorNode, 0, beaconLight.speed * dt, 0)
			end
		end

		self:raiseActive()
	end

	if spec.turnLightState ~= Lights.TURNLIGHT_OFF then
		local alpha = MathUtil.clamp(math.cos(7 * getShaderTimeSec()) + 0.2, 0, 1)

		if spec.turnLightState == Lights.TURNLIGHT_LEFT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
			for _, light in pairs(spec.activeTurnLightSetup.turnLightsLeft) do
				setLightColor(light.node, light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)

				for i = 0, getNumOfChildren(light.node) - 1 do
					setLightColor(getChildAt(light.node, i), light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)
				end
			end
		end

		if spec.turnLightState == Lights.TURNLIGHT_RIGHT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
			for _, light in pairs(spec.activeTurnLightSetup.turnLightsRight) do
				setLightColor(light.node, light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)

				for i = 0, getNumOfChildren(light.node) - 1 do
					setLightColor(getChildAt(light.node, i), light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)
				end
			end
		end

		self:raiseActive()
	end

	if self.isClient and spec.samples.turnLight ~= nil and Lights.TURNLIGHT_OFF < spec.turnLightState then
		local turnLightRepetitionCount = math.floor((getShaderTimeSec() * 7 + math.acos(-0.2)) / (math.pi * 2))

		if spec.turnLightRepetitionCount ~= nil and turnLightRepetitionCount ~= spec.turnLightRepetitionCount then
			g_soundManager:playSample(spec.samples.turnLight)
		end

		spec.turnLightRepetitionCount = turnLightRepetitionCount
	end
end

function Lights:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_lights
	local isDark = g_currentMission.environment.currentHour > 20 or g_currentMission.environment.currentHour < 7

	g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, isDark)

	if self.isClient then
		self:setInteriorLightsVisibility(self:getIsActiveForInteriorLights())

		for _, v in ipairs(spec.actionEventsActiveChange) do
			g_inputBinding:setActionEventActive(v, self:getIsActiveForLights())
		end

		g_inputBinding:setActionEventActive(spec.actionEventIdLight, self:getIsActiveForLights())

		if g_platformSettingsManager:getSetting("automaticLights", false) then
			if self:getIsActiveForLights() then
				local force = false

				if not spec.realLightsAllowed then
					spec.realLightsAllowed = true
					force = true
				end

				self:updateAILights(self:getRootVehicle():getActionControllerDirection() == -1, force)
			elseif self:getIsAIActive() then
				if spec.realLightsAllowed then
					spec.realLightsAllowed = false

					self:updateAILights(self:getRootVehicle():getActionControllerDirection() == -1, true)
				end
			elseif spec.lightsTypesMask ~= 0 then
				spec.realLightsAllowed = true

				self:setLightsTypesMask(0)
			end
		end
	end
end

function Lights:getIsActiveForLights()
	if self.getIsEntered ~= nil and self:getIsEntered() and self:getCanToggleLight() then
		return true
	end

	if self.attacherVehicle ~= nil and (self.isSteerable == nil or self.isSteerable == false) then
		return self.attacherVehicle:getIsActiveForLights()
	end

	return false
end

function Lights:getIsActiveForInteriorLights()
	return false
end

function Lights:getCanToggleLight()
	local spec = self.spec_lights

	if self:getIsAIActive() then
		return false
	end

	if spec.numLightTypes == 0 then
		return false
	end

	if g_currentMission.controlledVehicle == self then
		return true
	else
		return false
	end
end

function Lights:getUseHighProfile()
	local lightsProfile = g_gameSettings:getValue("lightsProfile")
	lightsProfile = g_platformSettingsManager:getSetting("lightsProfile", lightsProfile)

	return lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_HIGH and self:getIsActiveForLights()
end

function Lights:setNextLightsState()
	local spec = self.spec_lights

	if spec.lightStates ~= nil and #spec.lightStates > 0 then
		local currentLightState = spec.currentLightState + 1

		if currentLightState > #spec.lightStates or spec.currentLightState == 0 and spec.lightsTypesMask > 0 then
			currentLightState = 0
		end

		local lightsTypesMask = 0

		if currentLightState > 0 then
			for _, lightType in pairs(spec.lightStates[currentLightState]) do
				lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
			end
		end

		spec.currentLightState = currentLightState

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:setLightsTypesMask(lightsTypesMask, force, noEventSend)
	local spec = self.spec_lights

	if lightsTypesMask ~= spec.lightsTypesMask or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetLightEvent:new(self, lightsTypesMask), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetLightEvent:new(self, lightsTypesMask))
			end
		end

		if self.isClient then
			g_soundManager:playSample(spec.samples.toggleLights)
		end

		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		for _, light in pairs(inactiveLightSetup.lightTypes) do
			setVisibility(light.node, false)
		end

		local function getIsLightActive(light)
			local lightActive = false

			for _, lightType in pairs(light.lightTypes) do
				if bitAND(lightsTypesMask, 2^lightType) ~= 0 then
					lightActive = true

					break
				end
			end

			if light.enableDirection ~= nil then
				local reverserDirection = 1

				if self.getReverserDirection ~= nil then
					reverserDirection = self:getReverserDirection()
				end

				lightActive = lightActive and light.enableDirection == reverserDirection
			end

			if lightActive then
				for _, excludedLightType in pairs(light.excludedLightTypes) do
					if bitAND(lightsTypesMask, 2^excludedLightType) ~= 0 then
						lightActive = false

						break
					end
				end
			end

			return lightActive
		end

		if spec.realLightsAllowed then
			for _, light in pairs(activeLightSetup.lightTypes) do
				local isActive = getIsLightActive(light)

				if isActive then
					setVisibility(light.node, true)
				else
					local active = false

					if light.brakeLight ~= nil and light.brakeLight.isActive then
						active = true
					end

					setVisibility(light.node, active)
				end

				light.isActive = isActive
			end
		else
			for _, light in pairs(activeLightSetup.lightTypes) do
				setVisibility(light.node, false)
			end
		end

		for _, light in pairs(spec.defaultLights) do
			local isActive = getIsLightActive(light)

			setVisibility(light.node, isActive)
		end

		for _, light in pairs(spec.shaderDefaultLights) do
			local isActive = getIsLightActive(light)
			local value = 1

			if not isActive then
				value = 0
			end

			local _, y, z, w = getShaderParameter(light.node, "lightControl")

			setShaderParameter(light.node, "lightControl", math.max(value * light.intensity, 0), y, z, w, false)

			if light.toggleVisibility then
				setVisibility(light.node, isActive)
			end
		end

		spec.lightsTypesMask = lightsTypesMask

		SpecializationUtil.raiseEvent(self, "onLightsTypesMaskChanged", lightsTypesMask)
	end

	return true
end

function Lights:getLightsTypesMask()
	return self.spec_lights.lightsTypesMask
end

function Lights:setBeaconLightsVisibility(visibility, force, noEventSend)
	local spec = self.spec_lights

	if visibility ~= spec.beaconLightsActive or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetBeaconLightEvent:new(self, visibility), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent:new(self, visibility))
			end
		end

		spec.beaconLightsActive = visibility
		local realBeaconLights = g_gameSettings:getValue("realBeaconLights")

		for _, beaconLight in pairs(spec.beaconLights) do
			if realBeaconLights and beaconLight.realLightNode ~= nil then
				setVisibility(beaconLight.realLightNode, visibility)
			end

			if beaconLight.lightNode ~= nil then
				setVisibility(beaconLight.lightNode, visibility)
			end

			if beaconLight.lightShaderNode ~= nil then
				local value = 1 * beaconLight.intensity

				if not visibility then
					value = 0
				end

				local _, y, z, w = getShaderParameter(beaconLight.lightShaderNode, "lightControl")

				setShaderParameter(beaconLight.lightShaderNode, "lightControl", value, y, z, w, false)
			end
		end

		SpecializationUtil.raiseEvent(self, "onBeaconLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:getBeaconLightsVisibility()
	return self.spec_lights.beaconLightsActive
end

function Lights:setTurnLightState(state, force, noEventSend)
	local spec = self.spec_lights

	if state ~= spec.turnLightState or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetTurnLightEvent:new(self, state), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetTurnLightEvent:new(self, state))
			end
		end

		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		spec.activeTurnLightSetup = activeLightSetup

		for _, light in pairs(inactiveLightSetup.turnLightsLeft) do
			setVisibility(light.node, false)
		end

		for _, light in pairs(inactiveLightSetup.turnLightsRight) do
			setVisibility(light.node, false)
		end

		for _, light in pairs(activeLightSetup.turnLightsLeft) do
			setVisibility(light.node, state == Lights.TURNLIGHT_LEFT or state == Lights.TURNLIGHT_HAZARD)
		end

		for _, light in pairs(activeLightSetup.turnLightsRight) do
			setVisibility(light.node, state == Lights.TURNLIGHT_RIGHT or state == Lights.TURNLIGHT_HAZARD)
		end

		for _, light in pairs(spec.turnLightsLeft) do
			setVisibility(light.node, state == Lights.TURNLIGHT_LEFT or state == Lights.TURNLIGHT_HAZARD)
		end

		for _, light in pairs(spec.turnLightsRight) do
			setVisibility(light.node, state == Lights.TURNLIGHT_RIGHT or state == Lights.TURNLIGHT_HAZARD)
		end

		local value = 1

		if state ~= Lights.TURNLIGHT_LEFT and state ~= Lights.TURNLIGHT_HAZARD then
			value = 0
		end

		for _, sharedTurnLight in ipairs(spec.shaderLeftTurnLights) do
			local _, y, z, w = getShaderParameter(sharedTurnLight.node, "lightControl")

			setShaderParameter(sharedTurnLight.node, "lightControl", value * sharedTurnLight.intensity, y, z, w, false)

			if sharedTurnLight.toggleVisibility then
				setVisibility(sharedTurnLight.node, value == 1)
			end
		end

		value = 1

		if state ~= Lights.TURNLIGHT_RIGHT and state ~= Lights.TURNLIGHT_HAZARD then
			value = 0
		end

		for _, sharedTurnLight in ipairs(spec.shaderRightTurnLights) do
			local _, y, z, w = getShaderParameter(sharedTurnLight.node, "lightControl")

			setShaderParameter(sharedTurnLight.node, "lightControl", value * sharedTurnLight.intensity, y, z, w, false)

			if sharedTurnLight.toggleVisibility then
				setVisibility(sharedTurnLight.node, value == 1)
			end
		end

		spec.turnLightState = state

		SpecializationUtil.raiseEvent(self, "onTurnLightStateChanged", state)
	end

	return true
end

function Lights:getTurnLightState()
	return self.spec_lights.turnLightState
end

function Lights:setBrakeLightsVisibility(visibility)
	local spec = self.spec_lights

	if visibility ~= spec.brakeLightsVisibility then
		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		for _, light in pairs(inactiveLightSetup.brakeLights) do
			setVisibility(light.node, false)
		end

		for _, light in pairs(activeLightSetup.brakeLights) do
			light.isActive = visibility

			if visibility then
				if light.backLight ~= nil then
					local color = light.backLight.defaultColor

					setLightColor(light.node, color[1] * 2, color[2] * 2, color[3] * 2)

					for i = 0, getNumOfChildren(light.node) - 1 do
						setLightColor(getChildAt(light.node, i), color[1] * 2, color[2] * 2, color[3] * 2)
					end
				end

				setVisibility(light.node, true)

				light.isActive = true
			else
				local isVisible = false

				if light.backLight ~= nil then
					local color = light.backLight.defaultColor

					setLightColor(light.node, color[1], color[2], color[3])

					for i = 0, getNumOfChildren(light.node) - 1 do
						setLightColor(getChildAt(light.node, i), color[1], color[2], color[3])
					end

					if light.backLight.isActive then
						isVisible = true
					end
				end

				setVisibility(light.node, isVisible)
			end
		end

		for _, light in pairs(spec.brakeLights) do
			setVisibility(light.node, visibility)
		end

		local dir = 1

		if not visibility then
			dir = -1
		end

		for _, sharedBrakeLight in ipairs(spec.shaderBrakeLights) do
			local x, y, z, w = getShaderParameter(sharedBrakeLight.node, "lightControl")

			setShaderParameter(sharedBrakeLight.node, "lightControl", math.max(x + dir * sharedBrakeLight.intensity, 0), y, z, w, false)

			if sharedBrakeLight.toggleVisibility then
				setVisibility(sharedBrakeLight.node, visibility)
			end
		end

		spec.brakeLightsVisibility = visibility

		SpecializationUtil.raiseEvent(self, "onBrakeLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:setReverseLightsVisibility(visibility)
	local spec = self.spec_lights

	if visibility ~= spec.reverseLightsVisibility then
		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		for _, light in pairs(inactiveLightSetup.reverseLights) do
			setVisibility(light.node, false)
		end

		for _, light in pairs(activeLightSetup.reverseLights) do
			setVisibility(light.node, visibility)
		end

		for _, light in pairs(spec.reverseLights) do
			setVisibility(light.node, visibility)
		end

		local dir = 1

		if not visibility then
			dir = -1
		end

		for _, sharedReverseLight in ipairs(spec.shaderReverseLights) do
			local x, y, z, w = getShaderParameter(sharedReverseLight.node, "lightControl")

			setShaderParameter(sharedReverseLight.node, "lightControl", math.max(x + dir * sharedReverseLight.intensity), y, z, w, false)

			if sharedReverseLight.toggleVisibility then
				setVisibility(sharedReverseLight.node, visibility)
			end
		end

		spec.reverseLightsVisibility = visibility

		SpecializationUtil.raiseEvent(self, "onReverseLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:setInteriorLightsVisibility(visibility)
	local spec = self.spec_lights
	local brightness = 0
	local hour = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60

	if hour < 10 then
		brightness = 1 - (hour - 8) / 2
	end

	if hour > 16 then
		brightness = (hour - 16) / 2
	end

	brightness = MathUtil.clamp(brightness, 0, 1)

	if brightness == 0 then
		visibility = false
	end

	if visibility ~= spec.interiorLightsVisibility or brightness ~= spec.interiorLightsBrightness then
		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		for _, light in pairs(inactiveLightSetup.interiorLights) do
			setVisibility(light.node, false)
		end

		for _, light in pairs(activeLightSetup.interiorLights) do
			if visibility then
				if light.startColor == nil then
					light.startColor = {
						getLightColor(light.node)
					}
				end

				setLightColor(light.node, light.startColor[1] * brightness, light.startColor[2] * brightness, light.startColor[3] * brightness)
			end

			light.isActive = visibility

			setVisibility(light.node, visibility)
		end

		spec.interiorLightsVisibility = visibility
		spec.interiorLightsBrightness = brightness
	end

	return true
end

function Lights:deactivateLights()
	self:setLightsTypesMask(0, true, true)
	self:setBeaconLightsVisibility(false, true, true)
	self:setTurnLightState(Lights.TURNLIGHT_OFF, true, true)
	self:setBrakeLightsVisibility(false)
	self:setReverseLightsVisibility(false)
	self:setInteriorLightsVisibility(false)

	local spec = self.spec_lights
	spec.currentLightState = 0

	SpecializationUtil.raiseEvent(self, "onDeactivateLights")
end

function Lights:getDeactivateLightsOnLeave()
	return true
end

function Lights:loadSharedLight(xmlFile, key, sharedLight)
	local success = false
	local spec = self.spec_lights
	local xmlFilename = getXMLString(xmlFile, key .. "#filename")

	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
		local lightXmlFile = loadXMLFile("sharedLight", xmlFilename)

		if lightXmlFile ~= nil and lightXmlFile ~= 0 then
			local filename = getXMLString(lightXmlFile, "light.filename")

			if filename == nil then
				print("Warning: Missing light i3d filename 'light.filename' in '" .. tostring(xmlFilename) .. "'!")

				return
			end

			sharedLight.linkNode = I3DUtil.indexToObject(self.components, Utils.getNoNil(getXMLString(xmlFile, key .. "#linkNode"), "0>"), self.i3dMappings)

			if sharedLight.linkNode == nil then
				print("Warning: Missing light linkNode in '" .. tostring(xmlFilename) .. "'!")

				return
			end

			sharedLight.lightTypes = {
				StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#lightTypes"))
			}
			sharedLight.excludedLightTypes = {
				StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#excludedLightTypes"))
			}
			sharedLight.enableDirection = getXMLInt(xmlFile, key .. "#enableDirection")
			local rotations = {}
			local i = 0

			while true do
				local rotKey = string.format("%s.rotationNode(%d)", key, i)

				if not hasXMLProperty(xmlFile, rotKey) then
					break
				end

				local name = getXMLString(xmlFile, rotKey .. "#name")
				local rotation = StringUtil.getRadiansFromString(getXMLString(xmlFile, rotKey .. "#rotation"), 3)

				if name ~= nil then
					rotations[name] = rotation
				end

				i = i + 1
			end

			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				sharedLight.filename = filename
				sharedLight.node = I3DUtil.indexToObject(i3dNode, Utils.getNoNil(getXMLString(lightXmlFile, "light.rootNode#node"), "0"))
				local i = 0

				while true do
					local lightKey = string.format("light.defaultLight(%d)", i)

					if not hasXMLProperty(lightXmlFile, lightKey) then
						break
					end

					local types = sharedLight.lightTypes

					if #types == 0 then
						types = {
							StringUtil.getVectorFromString(Utils.getNoNil(getXMLString(lightXmlFile, lightKey .. "#lightTypes"), "0"))
						}
					end

					local light = {
						node = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, lightKey .. "#node"))
					}

					if light.node ~= nil then
						if getHasShaderParameter(light.node, "lightControl") then
							light.intensity = getXMLFloat(lightXmlFile, lightKey .. "#intensity") or 25
							light.lightTypes = types
							light.excludedLightTypes = sharedLight.excludedLightTypes
							light.enableDirection = sharedLight.enableDirection

							if #light.lightTypes >= 0 then
								table.insert(spec.shaderDefaultLights, light)
							end
						else
							print("Warning: Node '" .. getName(light.node) .. "' has no shaderparameter 'lightControl' in '" .. xmlFilename .. "'. Ignoring node!")
						end
					else
						print("Warning: Could not find node for '" .. lightKey .. "' in '" .. xmlFilename .. "'!")
					end

					i = i + 1
				end

				local function addLights(xml, key, targetTable)
					local i = 0

					while true do
						local lightKey = string.format("light.%s(%d)", key, i)

						if not hasXMLProperty(xml, lightKey) then
							break
						end

						local node = I3DUtil.indexToObject(i3dNode, getXMLString(xml, lightKey .. "#node"))

						if node ~= nil then
							if getHasShaderParameter(node, "lightControl") then
								local intensity = getXMLFloat(xml, lightKey .. "#intensity") or 25
								local toggleVisibility = Utils.getNoNil(getXMLBool(xml, lightKey .. "#toggleVisibility"), false)

								if toggleVisibility then
									setVisibility(node, false)
								end

								table.insert(targetTable, {
									node = node,
									intensity = intensity,
									toggleVisibility = toggleVisibility
								})
							else
								print("Warning: Node '" .. getName(node) .. "' has no shaderparameter 'lightControl'. Ignoring node!")
							end
						else
							print("Warning: Could not find node for '" .. key .. "' in '" .. xmlFilename .. "'!")
						end

						i = i + 1
					end
				end

				for name, rotation in pairs(rotations) do
					local node = I3DUtil.indexToObject(i3dNode, getXMLString(lightXmlFile, string.format("light.%s#node", name)))

					if node ~= nil then
						setRotation(node, unpack(rotation))
					end
				end

				addLights(lightXmlFile, "brakeLight", spec.shaderBrakeLights)
				addLights(lightXmlFile, "reverseLight", spec.shaderReverseLights)
				addLights(lightXmlFile, "turnLightLeft", spec.shaderLeftTurnLights)
				addLights(lightXmlFile, "turnLightRight", spec.shaderRightTurnLights)
				link(sharedLight.linkNode, sharedLight.node)
				delete(i3dNode)

				success = true
			end

			delete(lightXmlFile)
		end
	end

	return success
end

function Lights:updateAILights(isWorking, force)
	local spec = self.spec_lights
	local dayMinutes = g_currentMission.environment.dayTime / 60000
	local needLights = g_currentMission.environment.nightStartMinutes < dayMinutes or dayMinutes < g_currentMission.environment.nightEndMinutes

	if needLights then
		local typeMask = spec.aiLightsTypesMask

		if isWorking then
			typeMask = spec.aiLightsTypesMaskWork
		end

		if spec.lightsTypesMask ~= typeMask or force then
			self:setLightsTypesMask(typeMask, force)
		end
	elseif spec.lightsTypesMask ~= 0 or force then
		self:setLightsTypesMask(0, force)
	end
end

function Lights:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() then
		local spec = self.spec_lights

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			_, spec.actionEventIdLight = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS, self, Lights.actionEventToggleLights, false, true, false, true, nil)
			local _, actionEventIdFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHT_FRONT, self, Lights.actionEventToggleLightFront, false, true, false, true, nil)
			local _, actionEventIdWorkBack = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_BACK, self, Lights.actionEventToggleWorkLightBack, false, true, false, true, nil)
			local _, actionEventIdWorkFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_FRONT, self, Lights.actionEventToggleWorkLightFront, false, true, false, true, nil)
			local _, actionEventIdHighBeam = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_HIGH_BEAM_LIGHT, self, Lights.actionEventToggleHighBeamLight, false, true, false, true, nil)

			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_HAZARD, self, Lights.actionEventToggleTurnLightHazard, false, true, false, true, nil)
			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_LEFT, self, Lights.actionEventToggleTurnLightLeft, false, true, false, true, nil)
			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_RIGHT, self, Lights.actionEventToggleTurnLightRight, false, true, false, true, nil)

			local _, actionEventIdBeacon = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_BEACON_LIGHTS, self, Lights.actionEventToggleBeaconLights, false, true, false, true, nil)
			spec.actionEventsActiveChange = {
				actionEventIdFront,
				actionEventIdWorkBack,
				actionEventIdWorkFront,
				actionEventIdHighBeam,
				actionEventIdBeacon
			}

			for _, actionEvent in pairs(spec.actionEvents) do
				if actionEvent.actionEventId ~= nil then
					g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
					g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_LOW)
				end
			end
		end
	end
end

function Lights:onEnterVehicle(isControlling)
	local spec = self.spec_lights

	self:setLightsTypesMask(spec.lightsTypesMask, true, true)
	self:setBeaconLightsVisibility(spec.beaconLightsActive, true, true)
	self:setTurnLightState(spec.turnLightState, true, true)
end

function Lights:onLeaveVehicle()
	if self:getDeactivateLightsOnLeave() then
		self:deactivateLights()
	end
end

function Lights:onStartReverseDirectionChange()
	local spec = self.spec_lights

	if spec.lightsTypesMask > 0 then
		self:setLightsTypesMask(spec.lightsTypesMask, true, true)
	end
end

function Lights:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if attacherVehicle.getLightsTypesMask ~= nil then
		self:setLightsTypesMask(attacherVehicle:getLightsTypesMask(), true, true)
		self:setBeaconLightsVisibility(attacherVehicle:getBeaconLightsVisibility(), true, true)
		self:setTurnLightState(attacherVehicle:getTurnLightState(), true, true)
	end
end

function Lights:onPostDetach()
	self:deactivateLights()
end

function Lights:onAutomatedTrainTravelActive()
	self:updateAILights(false)
end

function Lights:onAIActive()
	self:updateAILights(true)
end

function Lights:onAIBlock()
	self:setBeaconLightsVisibility(true, true, true)
end

function Lights:onAIContinue()
	self:setBeaconLightsVisibility(false, true, true)
end

function Lights:onAIEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:setLightsTypesMask(0)
	end
end

function Lights:loadRealLightSetup(xmlFile, key, lightTable, realLightToLight)
	local i = 0

	while true do
		local lightKey = string.format("%s.light(%d)", key, i)

		if not hasXMLProperty(xmlFile, lightKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, lightKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			if getHasClassId(node, ClassIds.LIGHT_SOURCE) then
				setVisibility(node, false)

				local light = {
					node = node,
					defaultColor = {
						getLightColor(node)
					},
					enableDirection = getXMLInt(xmlFile, lightKey .. "#enableDirection"),
					excludedLightTypes = {
						StringUtil.getVectorFromString(getXMLString(xmlFile, lightKey .. "#excludedLightTypes"))
					},
					lightTypes = {
						StringUtil.getVectorFromString(getXMLString(xmlFile, lightKey .. "#lightTypes"))
					}
				}

				if #light.lightTypes >= 0 then
					realLightToLight[node] = light

					table.insert(lightTable.lightTypes, light)
				else
					print("Warning: lightType missing for light '" .. lightKey .. "' in '" .. self.configFileName .. "'")
				end
			end
		else
			print("Warning: RealLight node missing for light '" .. lightKey .. "' in '" .. self.configFileName .. "'")
		end

		i = i + 1
	end

	self:loadRealLights(xmlFile, key .. ".brakeLight", lightTable.brakeLights, realLightToLight)
	self:loadRealLights(xmlFile, key .. ".reverseLight", lightTable.reverseLights)
	self:loadRealLights(xmlFile, key .. ".turnLightLeft", lightTable.turnLightsLeft)
	self:loadRealLights(xmlFile, key .. ".turnLightRight", lightTable.turnLightsRight)
	self:loadRealLights(xmlFile, key .. ".interiorLight", lightTable.interiorLights)
end

function Lights:loadRealLights(xmlFile, key, targetTable, brakeLightTable)
	local i = 0

	while true do
		local lightKey = string.format("%s(%d)", key, i)

		if not hasXMLProperty(xmlFile, lightKey) then
			break
		end

		local index = getXMLString(xmlFile, lightKey .. "#node")
		local node = I3DUtil.indexToObject(self.components, index, self.i3dMappings)

		if node ~= nil then
			if getHasClassId(node, ClassIds.LIGHT_SOURCE) then
				local defaultColor = nil

				if node ~= nil then
					setVisibility(node, false)

					defaultColor = {
						getLightColor(node)
					}
				end

				local light = {
					isActive = false,
					node = node,
					defaultColor = defaultColor
				}

				if brakeLightTable ~= nil and brakeLightTable[light.node] ~= nil then
					light.backLight = brakeLightTable[light.node]
					brakeLightTable[light.node].brakeLight = light
				end

				table.insert(targetTable, light)
			else
				print("Warning: '" .. getName(node) .. "' (" .. index .. ") is not a real lightSource in '" .. self.configFileName .. "'!")
			end
		else
			print("Warning: RealLight node missing for light '" .. lightKey .. "' in '" .. self.configFileName .. "'")
		end

		i = i + 1
	end
end

function Lights:loadVisualLights(xmlFile, key, isDefaultLight, targetTable, shaderTargetTable)
	local i = 0

	while true do
		local lightKey = string.format("%s(%d)", key, i)

		if not hasXMLProperty(xmlFile, lightKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, lightKey .. "#node"), self.i3dMappings)
		local shaderNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, lightKey .. "#shaderNode"), self.i3dMappings)
		local intensity = Utils.getNoNil(getXMLFloat(xmlFile, lightKey .. "#intensity"), 25)

		if node ~= nil or shaderNode ~= nil then
			if node ~= nil then
				setVisibility(node, false)
			end

			if shaderNode ~= nil then
				for i = 0, getNumOfChildren(shaderNode) - 1 do
					local node = getChildAt(shaderNode, i)
					local _, y, z, w = getShaderParameter(node, "lightControl")

					setShaderParameter(node, "lightControl", 0, y, z, w, false)
				end
			end

			local light = {
				node = node,
				shaderNode = shaderNode,
				intensity = intensity,
				toggleVisibility = Utils.getNoNil(getXMLBool(xmlFile, lightKey .. "#toggleVisibility"), false)
			}

			if light.toggleVisibility then
				setVisibility(shaderNode, false)
			end

			if isDefaultLight then
				light.enableDirection = getXMLInt(xmlFile, lightKey .. "#enableDirection")
				light.excludedLightTypes = {
					StringUtil.getVectorFromString(getXMLString(xmlFile, lightKey .. "#excludedLightTypes"))
				}
				light.lightTypes = {
					StringUtil.getVectorFromString(getXMLString(xmlFile, lightKey .. "#lightTypes"))
				}
			end

			if light.shaderNode ~= nil then
				local function addLight(node, light)
					if getHasShaderParameter(node, "lightControl") then
						local shaderLight = {
							node = node,
							enableDirection = light.enableDirection,
							excludedLightTypes = light.excludedLightTypes,
							lightTypes = light.lightTypes,
							intensity = light.intensity,
							toggleVisibility = light.toggleVisibility
						}

						table.insert(shaderTargetTable, shaderLight)
					end
				end

				addLight(light.shaderNode, light)

				for i = 0, getNumOfChildren(light.shaderNode) - 1 do
					local node = getChildAt(light.shaderNode, i)

					addLight(node, light)
				end
			end

			if light.node ~= nil then
				table.insert(targetTable, light)
			end
		end

		i = i + 1
	end
end

function Lights:actionEventToggleLightFront(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() and spec.numLightTypes >= 1 then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 1)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleLights(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleLight() then
		self:setNextLightsState(self)
	end
end

function Lights:actionEventToggleWorkLightBack(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleWorkLightFront(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 4)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleHighBeamLight(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 8)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleTurnLightHazard(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
			state = Lights.TURNLIGHT_HAZARD
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleTurnLightLeft(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_LEFT then
			state = Lights.TURNLIGHT_LEFT
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleTurnLightRight(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_RIGHT then
			state = Lights.TURNLIGHT_RIGHT
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleBeaconLights(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		self:setBeaconLightsVisibility(not spec.beaconLightsActive)
	end
end

function Lights:dashboardLightAttributes(xmlFile, key, dashboard, isActive)
	dashboard.lightTypes = {
		StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#lightTypes"))
	}
	dashboard.excludedLightTypes = {
		StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#excludedLightTypes"))
	}

	return true
end

function Lights:dashboardLightState(dashboard, newValue, minValue, maxValue, isActive)
	local lightsTypesMask = self.spec_lights.lightsTypesMask
	local lightIsActive = false

	if dashboard.lightTypes ~= nil then
		for _, lightType in pairs(dashboard.lightTypes) do
			if bitAND(lightsTypesMask, 2^lightType) ~= 0 then
				lightIsActive = true

				break
			end
		end
	end

	if lightIsActive then
		for _, excludedLightType in pairs(dashboard.excludedLightTypes) do
			if bitAND(lightsTypesMask, 2^excludedLightType) ~= 0 then
				lightIsActive = false

				break
			end
		end
	end

	Dashboard.defaultDashboardStateFunc(self, dashboard, lightIsActive, minValue, maxValue, isActive)
end
