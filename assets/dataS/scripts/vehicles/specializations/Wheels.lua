Wheels = {
	WHEEL_NO_CONTACT = 0,
	WHEEL_OBJ_CONTACT = 1,
	WHEEL_GROUND_CONTACT = 2,
	WHEEL_GROUND_HEIGHT_CONTACT = 3,
	perlinNoiseSink = {}
}
Wheels.perlinNoiseSink.randomFrequency = 0.2
Wheels.perlinNoiseSink.persistence = 0
Wheels.perlinNoiseSink.numOctaves = 2
Wheels.perlinNoiseSink.randomSeed = 123
Wheels.perlinNoiseWobble = {
	randomFrequency = 0.8,
	persistence = 0,
	numOctaves = 4,
	randomSeed = 321
}
Wheels.GROUND_PARTICLES = {
	true,
	false,
	true,
	false,
	true,
	true,
	true
}
Wheels.MAX_SINK = {
	0.2,
	0.25,
	0.08,
	0.15,
	0.1
}

function Wheels.prerequisitesPresent(specializations)
	return true
end

function Wheels.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onBrake")
	SpecializationUtil.registerEvent(vehicleType, "onFinishedWheelLoading")
end

function Wheels.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelContact", Wheels.updateWheelContact)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelTireTracks", Wheels.updateWheelTireTracks)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDensityMapHeight", Wheels.updateWheelDensityMapHeight)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDestruction", Wheels.updateWheelDestruction)
	SpecializationUtil.registerFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", Wheels.getIsWheelFoliageDestructionAllowed)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelSink", Wheels.updateWheelSink)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelFriction", Wheels.updateWheelFriction)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelBase", Wheels.updateWheelBase)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelTireFriction", Wheels.updateWheelTireFriction)
	SpecializationUtil.registerFunction(vehicleType, "setWheelPositionDirty", Wheels.setWheelPositionDirty)
	SpecializationUtil.registerFunction(vehicleType, "setWheelTireFrictionDirty", Wheels.setWheelTireFrictionDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDriveGroundParticleSystemsScale", Wheels.getDriveGroundParticleSystemsScale)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicWheelDataFromXML", Wheels.loadDynamicWheelDataFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelParticleSystem", Wheels.loadWheelParticleSystem)
	SpecializationUtil.registerFunction(vehicleType, "finalizeWheel", Wheels.finalizeWheel)
	SpecializationUtil.registerFunction(vehicleType, "finalizeConnector", Wheels.finalizeConnector)
	SpecializationUtil.registerFunction(vehicleType, "loadHubs", Wheels.loadHubs)
	SpecializationUtil.registerFunction(vehicleType, "loadConnectorFromXML", Wheels.loadConnectorFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelDataFromExternalXML", Wheels.loadWheelDataFromExternalXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelPhysicsData", Wheels.loadWheelPhysicsData)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelData", Wheels.loadWheelData)
	SpecializationUtil.registerFunction(vehicleType, "loadHubFromXML", Wheels.loadHubFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelsSteeringDataFromXML", Wheels.loadWheelsSteeringDataFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadNonPhysicalWheelFromXML", Wheels.loadNonPhysicalWheelFromXML)
	SpecializationUtil.registerFunction(vehicleType, "deleteVisualWheel", Wheels.deleteVisualWheel)
	SpecializationUtil.registerFunction(vehicleType, "getIsVersatileYRotActive", Wheels.getIsVersatileYRotActive)
	SpecializationUtil.registerFunction(vehicleType, "getWheelFromWheelIndex", Wheels.getWheelFromWheelIndex)
	SpecializationUtil.registerFunction(vehicleType, "getWheels", Wheels.getWheels)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSurfaceSound", Wheels.getCurrentSurfaceSound)
	SpecializationUtil.registerFunction(vehicleType, "getAreSurfaceSoundsActive", Wheels.getAreSurfaceSoundsActive)
	SpecializationUtil.registerFunction(vehicleType, "destroyFruitArea", Wheels.destroyFruitArea)
	SpecializationUtil.registerFunction(vehicleType, "brake", Wheels.brake)
	SpecializationUtil.registerFunction(vehicleType, "getBrakeForce", Wheels.getBrakeForce)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelChocksPosition", Wheels.updateWheelChocksPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelChockPosition", Wheels.updateWheelChockPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDirtAmount", Wheels.updateWheelDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getAllowTireTracks", Wheels.getAllowTireTracks)
	SpecializationUtil.registerFunction(vehicleType, "getTireTrackColor", Wheels.getTireTrackColor)
end

function Wheels.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Wheels.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Wheels.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", Wheels.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Wheels.validateWashableNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIVehicleDirectionNode", Wheels.getAIVehicleDirectionNode)
end

function Wheels.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Wheels)
end

function Wheels.initSpecialization()
	g_configurationManager:addConfigurationType("wheel", g_i18n:getText("configuration_wheelSetup"), "wheels", nil, Wheels.loadBrandName, Wheels.loadedBrandNames, ConfigurationUtil.SELECTOR_MULTIOPTION, g_i18n:getText("configuration_wheelBrand"), Wheels.getBrands, Wheels.getWheelsByBrand)
	g_configurationManager:addConfigurationType("rimColor", g_i18n:getText("configuration_rimColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
end

function Wheels:onLoad(savegame)
	local spec = self.spec_wheels

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.driveGroundParticleSystems", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#hasParticles")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheelConfigurations.wheelConfiguration", "vehicle.wheels.wheelConfigurations.wheelConfiguration")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.rimColor", "vehicle.wheels.rimColor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.hubColor", "vehicle.wheels.hubs.color0")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.dynamicallyLoadedWheels", "vehicle.wheels.dynamicallyLoadedWheels")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.ackermannSteeringConfigurations", "vehicle.wheels.ackermannSteeringConfigurations")

	local wheelConfigurationId = Utils.getNoNil(self.configurations.wheel, 1)
	local configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", wheelConfigurationId - 1)
	local key = configKey .. ".wheels"

	if self.configurations.wheel ~= nil and not hasXMLProperty(self.xmlFile, key) then
		g_logManager:xmlWarning(self.configFileName, "Invalid wheelConfigurationId '%d'. Using default wheel config instead!", self.configurations.wheel)

		wheelConfigurationId = 1
		key = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", 0) .. ".wheels"
	end

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", wheelConfigurationId, self.components, self)

	local rimColorStr = getXMLString(self.xmlFile, "vehicle.wheels.rimColor")

	if rimColorStr ~= nil then
		spec.rimColor = ConfigurationUtil.getColorFromString(rimColorStr)
	elseif getXMLBool(self.xmlFile, "vehicle.wheels.rimColor#useBaseColor") then
		spec.rimColor = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor) or ConfigurationUtil.getColorByConfigId(self, "baseMaterial", self.configurations.baseMaterial)
	end

	if spec.rimColor ~= nil then
		spec.rimColor[4] = getXMLInt(self.xmlFile, "vehicle.wheels.rimColor#material")
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheels.wheel", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel")

	spec.hubs = {}

	self:loadHubs()

	self.maxRotTime = 0
	self.minRotTime = 0
	self.rotatedTimeInterpolator = InterpolatorValue:new(0)
	self.autoRotateBackSpeed = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#autoRotateBackSpeed", getXMLFloat, 1, nil, )
	self.speedDependentRotateBack = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#speedDependentRotateBack", getXMLBool, true, nil, )
	self.differentialIndex = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#differentialIndex", getXMLInt, nil, , )
	spec.ackermannSteeringIndex = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#ackermannSteeringIndex", getXMLInt, nil, , )

	if Utils.getNoNil(getXMLBool(self.xmlFile, key .. "#hasSurfaceSounds"), true) then
		local surfaceSoundLinkNodeStr = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, "", "#surfaceSoundLinkNode", getXMLString, "0>", nil, )
		local surfaceSoundLinkNode = I3DUtil.indexToObject(self.components, surfaceSoundLinkNodeStr, self.i3dMappings)
		spec.surfaceSounds = {}
		spec.surfaceIdToSound = {}
		spec.surfaceNameToSound = {}
		spec.currentSurfaceSound = nil

		for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
			if surfaceSound.type == "wheel" and surfaceSound.sample ~= nil then
				local sample = g_soundManager:cloneSample(surfaceSound.sample, surfaceSoundLinkNode, self)
				sample.sampleName = surfaceSound.name

				table.insert(spec.surfaceSounds, sample)

				spec.surfaceIdToSound[surfaceSound.materialId] = sample
				spec.surfaceNameToSound[surfaceSound.name] = sample
			end
		end
	end

	spec.wheelSmoothAccumulation = 0
	spec.wheelCreationTimer = 0
	spec.wheels = {}
	spec.wheelChocks = {}
	local i = 0

	while true do
		local wheelnamei = string.format(".wheel(%d)", i)

		if not hasXMLProperty(self.xmlFile, key .. wheelnamei) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configIndex", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configId")

		local reprStr = ConfigurationUtil.getConfigurationValue(self.xmlFile, key, wheelnamei, ".physics#repr", getXMLString, nil, , )

		if reprStr ~= nil then
			local wheel = {
				repr = I3DUtil.indexToObject(self.components, reprStr, self.i3dMappings)
			}

			if wheel.repr ~= nil then
				wheel.xmlIndex = i

				self:loadDynamicWheelDataFromXML(self.xmlFile, key, wheelnamei, wheel)
				self:finalizeWheel(wheel)
				table.insert(spec.wheels, wheel)
			else
				g_logManager:xmlWarning(self.configFileName, "Invalid wheel repr '%s'!", reprStr)
			end
		else
			g_logManager:xmlWarning(self.configFileName, "No repr node given for wheel '%s'!", wheelnamei)
		end

		i = i + 1
	end

	spec.dynamicallyLoadedWheels = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, baseName .. "#configIndex", baseName .. "#configId")

		local dynamicallyLoadedWheel = {}

		if self:loadNonPhysicalWheelFromXML(dynamicallyLoadedWheel, self.xmlFile, baseName) then
			table.insert(spec.dynamicallyLoadedWheels, dynamicallyLoadedWheel)
		end

		i = i + 1
	end

	spec.networkTimeInterpolator = InterpolationTime:new(1.2)
	local numWheels = table.getn(spec.wheels)

	for iWheel = 1, numWheels do
		local wheel1 = spec.wheels[iWheel]

		if wheel1.oppositeWheelIndex == nil then
			for jWheel = 1, numWheels do
				if iWheel ~= jWheel then
					local wheel2 = spec.wheels[jWheel]

					if math.abs(wheel1.positionX + wheel2.positionX) < 0.1 and math.abs(wheel1.positionZ - wheel2.positionZ) < 0.1 and math.abs(wheel1.positionY - wheel2.positionY) < 0.1 then
						wheel1.oppositeWheelIndex = jWheel
						wheel2.oppositeWheelIndex = iWheel

						break
					end
				end
			end
		end
	end

	self:loadWheelsSteeringDataFromXML(self.xmlFile, spec.ackermannSteeringIndex)
	SpecializationUtil.raiseEvent(self, "onFinishedWheelLoading", self.xmlFile, key)

	spec.wheelSinkActive = g_platformSettingsManager:getSetting("wheelSink", true)
	spec.wheelDensityHeightSmoothActive = g_platformSettingsManager:getSetting("wheelDensityHeightSmooth", true)
	spec.wheelVisualPressureActive = g_platformSettingsManager:getSetting("wheelVisualPressure", true)
	spec.brakePedal = 0
	spec.forceIsActiveTime = 3000
	spec.forceIsActiveTimer = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Wheels:onLoadFinished(savegame)
	self:updateWheelChocksPosition(nil, true)
end

function Wheels:loadHubs()
	local spec = self.spec_wheels
	spec.hubsColors = {}

	for j = 0, 7 do
		local hubsColorsKey = string.format("vehicle.wheels.hubs.color%d", j)
		local colorStr = getXMLString(self.xmlFile, hubsColorsKey)
		local material = getXMLInt(self.xmlFile, hubsColorsKey .. "#material")

		if colorStr ~= nil then
			spec.hubsColors[j] = ConfigurationUtil.getColorFromString(colorStr)
			spec.hubsColors[j][4] = material
		elseif getXMLBool(self.xmlFile, hubsColorsKey .. "#useBaseColor") then
			spec.hubsColors[j] = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor) or ConfigurationUtil.getColorByConfigId(self, "baseMaterial", self.configurations.baseMaterial)
		elseif getXMLBool(self.xmlFile, hubsColorsKey .. "#useRimColor") then
			spec.hubsColors[j] = Utils.getNoNil(ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor), spec.rimColor)
		end
	end

	spec.hubs = {}
	local i = 0

	while true do
		local key = string.format("vehicle.wheels.hubs.hub(%d)", i)
		local reprNodeStr = getXMLString(self.xmlFile, key .. "#linkNode")

		if reprNodeStr == nil then
			break
		end

		local hubFilename = getXMLString(self.xmlFile, key .. "#filename")
		local isLeft = getXMLBool(self.xmlFile, key .. "#isLeft")
		local reprNode = I3DUtil.indexToObject(self.components, reprNodeStr, self.i3dMappings)
		local hub = {}

		if self:loadHubFromXML(hubFilename, isLeft, hub, reprNode) then
			for j = 0, 7 do
				local color = XMLUtil.getXMLOverwrittenValue(self.xmlFile, key, string.format(".color%d", j), "", getXMLString, "global")
				local material = XMLUtil.getXMLOverwrittenValue(self.xmlFile, key, string.format(".color%d#material", j), "", getXMLInt, nil)

				if color == "global" then
					color = spec.hubsColors[j]
				else
					color = ConfigurationUtil.getColorFromString(color)

					if color ~= nil then
						color[4] = material
					end
				end

				if color ~= nil and hub.colors[j] == nil then
					g_logManager:xmlWarning(self.configFileName, "ColorShader 'color%d' is not supported by '%s'.", j, hubFilename)
				else
					color = color or hub.colors[j]

					if color ~= nil then
						local r, g, b, mat = unpack(color)

						if mat == nil then
							_, _, _, mat = getShaderParameter(hub.node, string.format("colorMat%d", j))
						end

						setShaderParameter(hub.node, string.format("colorMat%d", j), r, g, b, mat, false)
					end
				end
			end

			local offset = getXMLFloat(self.xmlFile, key .. "#offset")

			if offset ~= nil then
				if not isLeft then
					offset = offset * -1
				end

				setTranslation(hub.node, offset, 0, 0)
			end

			local scale = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, key .. "#scale"), 3)

			if scale ~= nil then
				setScale(hub.node, scale[1], scale[2], scale[3])
			end

			table.insert(spec.hubs, hub)
		end

		i = i + 1
	end
end

function Wheels:finalizeWheel(wheel, parentWheel)
	local spec = self.spec_wheels

	if parentWheel == nil and wheel.repr ~= nil then
		wheel.startPositionX, wheel.startPositionY, wheel.startPositionZ = getTranslation(wheel.repr)
		wheel.driveNodeStartPosX, wheel.driveNodeStartPosY, wheel.driveNodeStartPosZ = getTranslation(wheel.driveNode)
		wheel.dirtAmount = 0
		wheel.xDriveOffset = 0
		wheel.lastColor = {
			0,
			0,
			0,
			0
		}
		wheel.lastTerrainAttribute = 0
		wheel.contact = Wheels.WHEEL_NO_CONTACT
		wheel.steeringAngle = 0
		wheel.lastMovement = 0
		wheel.hasGroundContact = false
		wheel.hasHandbrake = true
		local vehicleNode = self.vehicleNodes[wheel.node]

		if vehicleNode ~= nil and vehicleNode.component ~= nil and vehicleNode.component.motorized == nil then
			vehicleNode.component.motorized = true
		end

		if wheel.useReprDirection then
			wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.repr, wheel.node, 0, -1, 0)
			wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.repr, wheel.node, 1, 0, 0)
		elseif wheel.useDriveNodeDirection then
			wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 0, -1, 0)
			wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 1, 0, 0)
		else
			wheel.directionZ = 0
			wheel.directionY = -1
			wheel.directionX = 0
			wheel.axleZ = 0
			wheel.axleY = 0
			wheel.axleX = 1
		end

		wheel.steeringCenterOffsetZ = 0
		wheel.steeringCenterOffsetY = 0
		wheel.steeringCenterOffsetX = 0

		if wheel.repr ~= wheel.driveNode then
			wheel.steeringCenterOffsetX, wheel.steeringCenterOffsetY, wheel.steeringCenterOffsetZ = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
			wheel.steeringCenterOffsetX = -wheel.steeringCenterOffsetX
			wheel.steeringCenterOffsetY = -wheel.steeringCenterOffsetY
			wheel.steeringCenterOffsetZ = -wheel.steeringCenterOffsetZ
		end

		if g_currentMission.tireTrackSystem ~= nil and wheel.hasTireTracks then
			wheel.tireTrackIndex = g_currentMission.tireTrackSystem:createTrack(wheel.width, wheel.tireTrackAtlasIndex)
		end

		wheel.maxLatStiffness = wheel.maxLatStiffness * wheel.restLoad
		wheel.maxLatStiffnessLoad = wheel.maxLatStiffnessLoad * wheel.restLoad
		wheel.mass = wheel.mass + wheel.additionalMass
		wheel.lastTerrainValue = 0
		wheel.sink = 0
		wheel.sinkTarget = 0
		wheel.radiusOriginal = wheel.radius
		wheel.sinkFrictionScaleFactor = 1
		wheel.sinkLongStiffnessFactor = 1
		wheel.sinkLatStiffnessFactor = 1
		local positionY = wheel.positionY + wheel.deltaY
		wheel.netInfo = {
			xDrive = 0,
			x = wheel.positionX,
			y = positionY,
			z = wheel.positionZ,
			suspensionLength = wheel.suspTravel * 0.5,
			sync = {
				yRange = 10,
				yMin = -5
			},
			yMin = positionY - 1.2 * wheel.suspTravel
		}

		self:updateWheelBase(wheel)
		self:updateWheelTireFriction(wheel)

		wheel.networkInterpolators = {
			xDrive = InterpolatorAngle:new(wheel.netInfo.xDrive),
			position = InterpolatorPosition:new(wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z),
			suspensionLength = InterpolatorValue:new(wheel.netInfo.suspensionLength)
		}
	end

	local function loadWheelPart(wheel, parent, name, filename, index, offset, widthAndDiam, scale)
		if filename == nil then
			return
		end

		local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

		if i3dNode ~= 0 then
			wheel[name] = I3DUtil.indexToObject(i3dNode, index, self.i3dMappings)

			if wheel[name] ~= nil then
				link(parent, wheel[name])
				delete(i3dNode)

				if offset ~= 0 then
					local dir = 1

					if not wheel.isLeft then
						dir = -1
					end

					setTranslation(wheel[name], offset * dir, 0, 0)
				end

				if scale ~= nil then
					setScale(wheel[name], scale[1], scale[2], scale[3])
				end

				if widthAndDiam ~= nil then
					if getHasShaderParameter(wheel[name], "widthAndDiam") then
						setShaderParameter(wheel[name], "widthAndDiam", widthAndDiam[1], widthAndDiam[2], 0, 0, false)
					else
						local scaleX = MathUtil.inchToM(widthAndDiam[1])
						local scaleZY = MathUtil.inchToM(widthAndDiam[2])

						setScale(wheel[name], scaleX, scaleZY, scaleZY)
					end
				end
			else
				g_logManager:xmlWarning(self.configFileName, "Failed to load node '%s' for file '%s'", index, filename)
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Failed to load file '%s' wheel part '%s'", filename, name)
		end
	end

	if parentWheel ~= nil then
		wheel.linkNode = createTransformGroup("linkNode")

		link(parentWheel.driveNode, wheel.linkNode)
	end

	loadWheelPart(wheel, wheel.linkNode, "wheelTire", wheel.tireFilename, wheel.tireNodeStr, 0, nil, )
	loadWheelPart(wheel, wheel.linkNode, "wheelOuterRim", wheel.outerRimFilename, wheel.outerRimNodeStr, 0, wheel.outerRimWidthAndDiam, wheel.outerRimScale)
	loadWheelPart(wheel, wheel.linkNode, "wheelInnerRim", wheel.innerRimFilename, wheel.innerRimNodeStr, wheel.innerRimOffset, wheel.innerRimWidthAndDiam, wheel.innerRimScale)
	loadWheelPart(wheel, wheel.linkNode, "wheelAdditional", wheel.additionalFilename, wheel.additionalNodeStr, wheel.additionalOffset, wheel.additionalWidthAndDiam, wheel.additionalScale)

	if wheel.wheelTire ~= nil then
		local zRot = 0

		if wheel.tireIsInverted then
			zRot = MathUtil.degToRad(180)
		end

		setRotation(wheel.wheelTire, wheel.xRotOffset, 0, zRot)

		local x, y, z, _ = getShaderParameter(wheel.wheelTire, "morphPosition")

		setShaderParameter(wheel.wheelTire, "morphPosition", x, y, z, 0, false)
	end

	local configColor = ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor)
	local color = wheel.color or configColor or spec.rimColor

	if color ~= nil then
		local r, g, b, mat = unpack(color)

		if wheel.wheelOuterRim ~= nil then
			if mat == nil then
				_, _, _, mat = getShaderParameter(wheel.wheelOuterRim, "colorMat0")
			end

			setShaderParameter(wheel.wheelOuterRim, "colorMat0", r, g, b, mat, false)
		end

		if wheel.wheelInnerRim ~= nil then
			if mat == nil then
				_, _, _, mat = getShaderParameter(wheel.wheelInnerRim, "colorMat0")
			end

			setShaderParameter(wheel.wheelInnerRim, "colorMat0", r, g, b, mat, false)
		end
	end

	local additionalColor = Utils.getNoNil(wheel.additionalColor, color)

	if wheel.wheelAdditional ~= nil and additionalColor ~= nil then
		local r, g, b, _ = unpack(additionalColor)
		local _, _, _, w = getShaderParameter(wheel.wheelAdditional, "colorMat0")

		setShaderParameter(wheel.wheelAdditional, "colorMat0", r, g, b, w, false)
	end

	if wheel.additionalWheels ~= nil then
		local outmostWheelWidth = 0
		local totalWheelshapeOffset = 0
		local offsetDir = -1

		for _, additionalWheel in pairs(wheel.additionalWheels) do
			self:finalizeWheel(additionalWheel, wheel)

			local baseWheelWidth = MathUtil.mToInch(wheel.width)
			local dualWheelWidth = MathUtil.mToInch(additionalWheel.width)
			local diameter = 0
			local wheelOffset = MathUtil.mToInch(additionalWheel.offset)

			if wheel.outerRimWidthAndDiam ~= nil then
				baseWheelWidth = wheel.outerRimWidthAndDiam[1]
				diameter = wheel.outerRimWidthAndDiam[2]
			end

			if additionalWheel.outerRimWidthAndDiam ~= nil then
				dualWheelWidth = additionalWheel.outerRimWidthAndDiam[1]
			end

			if additionalWheel.isLeft then
				offsetDir = 1
			end

			if wheel.tireIsInverted then
				setRotation(additionalWheel.wheelTire, 0, 0, math.pi)
			end

			local totalOffset = 0
			totalOffset = totalOffset + offsetDir * MathUtil.inchToM(0.5 * baseWheelWidth + wheelOffset + 0.5 * dualWheelWidth)

			if math.abs(totalWheelshapeOffset) < math.abs(totalOffset) then
				totalWheelshapeOffset = math.abs(totalOffset)
				outmostWheelWidth = additionalWheel.width
			end

			if additionalWheel.connector ~= nil then
				self:finalizeConnector(wheel, additionalWheel.connector, diameter, baseWheelWidth, wheelOffset, offsetDir, dualWheelWidth)
			end

			local x, y, z = getTranslation(additionalWheel.linkNode)

			setTranslation(additionalWheel.linkNode, x + totalOffset, y, z)

			if additionalWheel.driveGroundParticleSystems ~= nil then
				for name, ps in pairs(additionalWheel.driveGroundParticleSystems) do
					ps.offsets[1] = ps.offsets[1] + totalOffset
					local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode))

					setTranslation(ps.emitterShape, wx + ps.offsets[1], wy + ps.offsets[2], wz + ps.offsets[3])
					table.insert(wheel.driveGroundParticleSystems[name], ps)
				end
			end
		end

		wheel.widthOffset = wheel.widthOffset + offsetDir * totalWheelshapeOffset / 2
		local wheelX, _, _ = getTranslation(wheel.wheelTire)
		local additionalWheelX = wheelX + totalWheelshapeOffset
		wheel.wheelshapeWidth = wheel.width / 2 + math.abs(wheelX - additionalWheelX) + outmostWheelWidth / 2
	end
end

function Wheels:finalizeConnector(wheel, connector, diameter, baseWheelWidth, wheelDistance, offsetDir, dualWheelWidth)
	local i3dNode = g_i3DManager:loadSharedI3DFile(connector.filename, self.baseDirectory, false, false, false)

	if i3dNode ~= 0 then
		local node = I3DUtil.indexToObject(i3dNode, connector.nodeStr, self.i3dMappings)

		if node ~= nil then
			connector.node = node
			connector.linkNode = wheel.wheelTire

			link(wheel.driveNode, connector.node)

			if not connector.useWidthAndDiam then
				if getHasShaderParameter(connector.node, "connectorPos") then
					setShaderParameter(connector.node, "connectorPos", 0, baseWheelWidth, wheelDistance, dualWheelWidth, false)
				end

				local x, _, z, w = getShaderParameter(connector.node, "widthAndDiam")

				setShaderParameter(connector.node, "widthAndDiam", x, diameter, z, w, false)
			else
				local connectorOffset = offsetDir * ((0.5 * baseWheelWidth + 0.5 * wheelDistance) * 0.0254 + connector.additionalOffset)
				local connectorDiameter = connector.diameter or diameter

				setTranslation(connector.node, connectorOffset, 0, 0)
				setShaderParameter(connector.node, "widthAndDiam", connector.width, connectorDiameter, 0, 0, false)
			end

			if connector.usePosAndScale and getHasShaderParameter(connector.node, "connectorPosAndScale") then
				local _, _, _, w = getShaderParameter(connector.node, "connectorPosAndScale")

				setShaderParameter(connector.node, "connectorPosAndScale", connector.startPos, connector.endPos, connector.scale, w, false)
			end

			if connector.color ~= nil and getHasShaderParameter(connector.node, "colorMat0") then
				local r, g, b, mat = unpack(connector.color)

				if mat == nil then
					_, _, _, mat = getShaderParameter(connector.node, "colorMat0")
				end

				setShaderParameter(connector.node, "colorMat0", r, g, b, mat, false)
			end
		end

		delete(i3dNode)
	end
end

function Wheels:loadHubFromXML(xmlFilename, isLeft, hub, linkNode)
	local xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = loadXMLFile("TempConfig", xmlFilename)
	local key = "hub"
	local nodeKey = "left"

	if not isLeft then
		nodeKey = "right"
	end

	local i3dFilename = getXMLString(xmlFile, key .. ".filename")

	if i3dFilename == nil then
		g_logManager:xmlError(xmlFilename, "Unable to retrieve hub i3d filename!")

		return false
	end

	local hubi3dNode = g_i3DManager:loadSharedI3DFile(i3dFilename, self.baseDirectory, false, false, false)

	if hubi3dNode == 0 then
		return false
	end

	local nodeStr = getXMLString(xmlFile, key .. ".nodes#" .. nodeKey)
	hub.node = I3DUtil.indexToObject(hubi3dNode, nodeStr, self.i3dMappings)

	if hub.node ~= nil then
		link(linkNode, hub.node)
		delete(hubi3dNode)

		local colors = {}

		for j = 0, 7 do
			colors[j] = ConfigurationUtil.getColorFromString(getXMLString(xmlFile, key .. string.format(".color%d", j)))
		end

		hub.colors = colors
	end

	delete(xmlFile)

	return true
end

function Wheels:loadWheelPhysicsData(xmlFile, key, wheelnamei, wheel)
	local physicsKey = wheelnamei .. ".physics"

	if wheel.repr ~= nil then
		wheel.node = self:getParentComponent(wheel.repr)

		if wheel.node ~= 0 then
			XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. wheelnamei .. "#steeringNode", string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels%s.steering#node", wheelnamei))

			local driveNodeStr = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#driveNode", getXMLString, nil, , )
			wheel.driveNode = I3DUtil.indexToObject(self.components, driveNodeStr, self.i3dMappings)

			if wheel.driveNode == wheel.repr then
				g_logManager:xmlWarning(self.configFileName, "repr and driveNode may not be equal for '%s'. Using default driveNode instead!", key .. "." .. physicsKey)

				wheel.driveNode = nil
			end

			wheel.linkNode = I3DUtil.indexToObject(self.components, ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#linkNode", getXMLString, nil, , ), self.i3dMappings)

			if wheel.driveNode == nil then
				local newRepr = createTransformGroup("wheelReprNode")
				local reprIndex = getChildIndex(wheel.repr)

				link(getParent(wheel.repr), newRepr, reprIndex)
				setTranslation(newRepr, getTranslation(wheel.repr))
				setRotation(newRepr, getRotation(wheel.repr))
				setScale(newRepr, getScale(wheel.repr))

				wheel.driveNode = wheel.repr

				link(newRepr, wheel.driveNode)
				setTranslation(wheel.driveNode, 0, 0, 0)
				setRotation(wheel.driveNode, 0, 0, 0)
				setScale(wheel.driveNode, 1, 1, 1)

				wheel.repr = newRepr
			end

			if wheel.driveNode ~= nil then
				local driveNodeDirectionNode = createTransformGroup("driveNodeDirectionNode")

				link(getParent(wheel.repr), driveNodeDirectionNode)
				setWorldTranslation(driveNodeDirectionNode, getWorldTranslation(wheel.driveNode))
				setWorldRotation(driveNodeDirectionNode, getWorldRotation(wheel.driveNode))

				wheel.driveNodeDirectionNode = driveNodeDirectionNode
			end

			if wheel.linkNode == nil then
				wheel.linkNode = wheel.driveNode
			end

			wheel.yOffset = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#yOffset", getXMLFloat, 0, nil, )

			if wheel.yOffset ~= 0 then
				setTranslation(wheel.driveNode, localToLocal(wheel.driveNode, getParent(wheel.driveNode), 0, wheel.yOffset, 0))
			end

			wheel.showSteeringAngle = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#showSteeringAngle", getXMLBool, true, nil, )
			wheel.suspTravel = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#suspTravel", getXMLFloat, 0.01, nil, )
			local initialCompression = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#initialCompression", getXMLFloat, nil, , )

			if initialCompression ~= nil then
				wheel.deltaY = (1 - initialCompression * 0.01) * wheel.suspTravel
			else
				wheel.deltaY = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#deltaY", getXMLFloat, 0, nil, )
			end

			wheel.spring = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#spring", getXMLFloat, 0, nil, ) * Vehicle.SPRING_SCALE
			wheel.torque = 0
			wheel.brakeFactor = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#brakeFactor", getXMLFloat, 1, nil, )
			wheel.autoHoldBrakeFactor = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#autoHoldBrakeFactor", getXMLFloat, wheel.brakeFactor, nil, )
			wheel.damperCompressionLowSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperCompressionLowSpeed", getXMLFloat, nil, , )
			wheel.damperRelaxationLowSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperRelaxationLowSpeed", getXMLFloat, nil, , )

			if wheel.damperRelaxationLowSpeed == nil then
				wheel.damperRelaxationLowSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damper", getXMLFloat, Utils.getNoNil(wheel.damperCompressionLowSpeed, 0), nil, )
			end

			wheel.damperRelaxationHighSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperRelaxationHighSpeed", getXMLFloat, wheel.damperRelaxationLowSpeed * 0.7, nil, )

			if wheel.damperCompressionLowSpeed == nil then
				wheel.damperCompressionLowSpeed = wheel.damperRelaxationLowSpeed * 0.9
			end

			wheel.damperCompressionHighSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperCompressionHighSpeed", getXMLFloat, wheel.damperCompressionLowSpeed * 0.2, nil, )
			wheel.damperCompressionLowSpeedThreshold = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperCompressionLowSpeedThreshold", getXMLFloat, 0.1016, nil, )
			wheel.damperRelaxationLowSpeedThreshold = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#damperRelaxationLowSpeedThreshold", getXMLFloat, 0.1524, nil, )
			wheel.forcePointRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#forcePointRatio", getXMLFloat, 0, nil, )
			wheel.driveMode = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#driveMode", getXMLInt, 0, nil, )
			wheel.xOffset = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#xOffset", getXMLFloat, 0, nil, )
			wheel.transRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#transRatio", getXMLFloat, 0, nil, )
			wheel.isSynchronized = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#isSynchronized", getXMLBool, true, nil, )
			wheel.tipOcclusionAreaGroupId = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#tipOcclusionAreaGroupId", getXMLInt, nil, , )
			wheel.positionX, wheel.positionY, wheel.positionZ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
			wheel.useReprDirection = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#useReprDirection", getXMLBool, false, nil, )
			wheel.useDriveNodeDirection = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#useDriveNodeDirection", getXMLBool, false, nil, )
			wheel.mass = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#mass", getXMLFloat, wheel.mass, nil, )
			wheel.radius = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#radius", getXMLFloat, Utils.getNoNil(wheel.radius, 0.5), nil, )
			wheel.width = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#width", getXMLFloat, Utils.getNoNil(wheel.width, 0.6), nil, )
			wheel.wheelshapeWidth = wheel.width
			wheel.widthOffset = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#widthOffset", getXMLFloat, 0, nil, )
			wheel.restLoad = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#restLoad", getXMLFloat, Utils.getNoNil(wheel.restLoad, 1), nil, )
			wheel.maxLongStiffness = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#maxLongStiffness", getXMLFloat, Utils.getNoNil(wheel.maxLongStiffness, 30), nil, )
			wheel.maxLatStiffness = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#maxLatStiffness", getXMLFloat, Utils.getNoNil(wheel.maxLatStiffness, 40), nil, )
			wheel.maxLatStiffnessLoad = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#maxLatStiffnessLoad", getXMLFloat, Utils.getNoNil(wheel.maxLatStiffnessLoad, 2), nil, )
			wheel.frictionScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#frictionScale", getXMLFloat, Utils.getNoNil(wheel.frictionScale, 1), nil, )
			wheel.rotationDamping = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotationDamping", getXMLFloat, wheel.mass * 0.035, nil, )
			wheel.tireGroundFrictionCoeff = 1
			local tireTypeName = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#tireType", getXMLString, "mud", nil, )
			wheel.tireType = WheelsUtil.getTireType(tireTypeName)

			if wheel.tireType == nil then
				g_logManager:xmlWarning(self.configFileName, "Failed to find tire type '%s'. Defaulting to 'mud'!", tireTypeName)

				wheel.tireType = WheelsUtil.getTireType("mud")
			end

			wheel.fieldDirtMultiplier = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#fieldDirtMultiplier", getXMLFloat, 75, nil, )
			wheel.streetDirtMultiplier = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#streetDirtMultiplier", getXMLFloat, -150, nil, )
			wheel.minDirtPercentage = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#minDirtPercentage", getXMLFloat, 0.35, nil, )
			wheel.smoothGroundRadius = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#smoothGroundRadius", getXMLFloat, Utils.getNoNil(wheel.smoothGroundRadius, math.max(0.6, wheel.width * 0.75)), nil, )
			wheel.versatileYRot = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#versatileYRot", getXMLBool, false, nil, )
			wheel.forceVersatility = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#forceVersatility", getXMLBool, false, nil, )
			wheel.supportsWheelSink = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#supportsWheelSink", getXMLBool, true, nil, )
			wheel.maxWheelSink = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#maxWheelSink", getXMLFloat, math.huge, nil, )
			wheel.hasTireTracks = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#hasTireTracks", getXMLBool, false, nil, )
			wheel.hasParticles = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#hasParticles", getXMLBool, false, nil, )
			local steeringKey = wheelnamei .. ".steering"
			wheel.steeringNode = I3DUtil.indexToObject(self.components, ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#node", getXMLString, nil, , ), self.i3dMappings)
			wheel.steeringRotNode = I3DUtil.indexToObject(self.components, ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#rotNode", getXMLString, nil, , ), self.i3dMappings)
			wheel.steeringNodeMinTransX = ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#nodeMinTransX", getXMLFloat, nil, , )
			wheel.steeringNodeMaxTransX = ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#nodeMaxTransX", getXMLFloat, nil, , )
			wheel.steeringNodeMinRotY = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#nodeMinRotY", getXMLFloat, nil, , ))
			wheel.steeringNodeMaxRotY = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringKey, "#nodeMaxRotY", getXMLFloat, nil, , ))
			local fenderKey = wheelnamei .. ".fender"
			wheel.fenderNode = I3DUtil.indexToObject(self.components, ConfigurationUtil.getConfigurationValue(xmlFile, key, fenderKey, "#node", getXMLString, nil, , ), self.i3dMappings)
			wheel.fenderRotMax = ConfigurationUtil.getConfigurationValue(xmlFile, key, fenderKey, "#rotMax", getXMLFloat, nil, , )
			wheel.fenderRotMin = ConfigurationUtil.getConfigurationValue(xmlFile, key, fenderKey, "#rotMin", getXMLFloat, nil, , )
			local steeringAxleKey = wheelnamei .. ".steeringAxle"
			wheel.steeringAxleScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringAxleKey, "#scale", getXMLFloat, 0, nil, )
			wheel.steeringAxleRotMax = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringAxleKey, "#rotMax", getXMLFloat, 0, nil, ))
			wheel.steeringAxleRotMin = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, steeringAxleKey, "#rotMin", getXMLFloat, -0, nil, ))
			wheel.rotSpeed = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotSpeed", getXMLFloat, nil, , ))
			wheel.rotSpeedNeg = Utils.getNoNilRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotSpeedNeg", getXMLFloat, nil, , ), nil)
			wheel.rotMax = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotMax", getXMLFloat, nil, , ))
			wheel.rotMin = MathUtil.degToRad(ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotMin", getXMLFloat, nil, , ))
			wheel.rotSpeedLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, physicsKey, "#rotSpeedLimit", getXMLFloat, nil, , )
		else
			g_logManager:xmlWarning(self.configFileName, "Invalid repr for wheel '%s'. Needs to be a child of a collision!", key .. physicsKey)
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Invalid repr for wheel '%s'!", key .. physicsKey)
	end

	return true
end

function Wheels:onDelete()
	local spec = self.spec_wheels

	for _, hub in pairs(spec.hubs) do
		delete(hub.node)
	end

	for _, wheel in pairs(spec.wheels) do
		self:deleteVisualWheel(wheel)

		if g_currentMission.tireTrackSystem ~= nil and wheel.tireTrackIndex ~= nil then
			g_currentMission.tireTrackSystem:destroyTrack(wheel.tireTrackIndex)
		end

		if wheel.driveGroundParticleSystems ~= nil then
			for _, ps in pairs(wheel.driveGroundParticleSystems) do
				ParticleUtil.deleteParticleSystems(ps)
			end
		end

		if wheel.additionalWheels ~= nil then
			for _, additionalWheel in pairs(wheel.additionalWheels) do
				self:deleteVisualWheel(additionalWheel)

				if g_currentMission.tireTrackSystem ~= nil and additionalWheel.tireTrackIndex ~= nil then
					g_currentMission.tireTrackSystem:destroyTrack(additionalWheel.tireTrackIndex)
				end
			end
		end
	end

	if spec.wheelChocks ~= nil then
		for _, wheelChock in pairs(spec.wheelChocks) do
			if wheelChock.filename ~= nil then
				g_i3DManager:releaseSharedI3DFile(wheelChock.filename, self.baseDirectory, true)
				delete(wheelChock.node)
			end
		end
	end

	for _, dynamicallyLoadedWheel in pairs(spec.dynamicallyLoadedWheels) do
		self:deleteVisualWheel(dynamicallyLoadedWheel)
	end

	if spec.surfaceSounds then
		g_soundManager:deleteSamples(spec.surfaceSounds)
	end
end

function Wheels:onReadStream(streamId, connection)
	if connection.isServer then
		local spec = self.spec_wheels

		spec.networkTimeInterpolator:reset()

		for i = 1, table.getn(spec.wheels) do
			local wheel = spec.wheels[i]
			wheel.netInfo.x = streamReadFloat32(streamId)
			wheel.netInfo.y = streamReadFloat32(streamId)
			wheel.netInfo.z = streamReadFloat32(streamId)
			wheel.netInfo.xDrive = streamReadFloat32(streamId)
			wheel.netInfo.suspensionLength = streamReadFloat32(streamId)
			wheel.contact = streamReadUIntN(streamId, 2)

			if wheel.versatileYRot then
				local yRot = streamReadUIntN(streamId, 9)
				wheel.steeringAngle = yRot / 511 * math.pi * 2
			end

			wheel.networkInterpolators.position:setPosition(wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z)
			wheel.networkInterpolators.xDrive:setAngle(wheel.netInfo.xDrive)
			wheel.networkInterpolators.suspensionLength:setValue(wheel.netInfo.suspensionLength)
		end

		self.rotatedTimeInterpolator:setValue(0)
	end
end

function Wheels:onWriteStream(streamId, connection)
	if not connection.isServer then
		local spec = self.spec_wheels

		for i = 1, table.getn(spec.wheels) do
			local wheel = spec.wheels[i]

			streamWriteFloat32(streamId, wheel.netInfo.x)
			streamWriteFloat32(streamId, wheel.netInfo.y)
			streamWriteFloat32(streamId, wheel.netInfo.z)
			streamWriteFloat32(streamId, wheel.netInfo.xDrive)
			streamWriteFloat32(streamId, wheel.netInfo.suspensionLength)
			streamWriteUIntN(streamId, wheel.contact, 2)

			if wheel.versatileYRot then
				local yRot = wheel.steeringAngle % (math.pi * 2)

				streamWriteUIntN(streamId, MathUtil.clamp(math.floor(yRot / (math.pi * 2) * 511), 0, 511), 9)
			end
		end
	end
end

function Wheels:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			local spec = self.spec_wheels

			spec.networkTimeInterpolator:startNewPhaseNetwork()

			for i = 1, table.getn(spec.wheels) do
				local wheel = spec.wheels[i]

				if wheel.isSynchronized then
					local xDrive = streamReadUIntN(streamId, 9)
					xDrive = xDrive / 511 * math.pi * 2

					wheel.networkInterpolators.xDrive:setTargetAngle(xDrive)

					local y = streamReadUIntN(streamId, 8)
					y = y / 255 * wheel.netInfo.sync.yRange + wheel.netInfo.sync.yMin

					wheel.networkInterpolators.position:setTargetPosition(wheel.netInfo.x, y, wheel.netInfo.z)

					local suspLength = streamReadUIntN(streamId, 7)

					wheel.networkInterpolators.suspensionLength:setTargetValue(suspLength / 100)

					if wheel.tireTrackIndex ~= nil then
						wheel.contact = streamReadUIntN(streamId, 2)
					end

					if wheel.versatileYRot then
						local yRot = streamReadUIntN(streamId, 9)
						wheel.steeringAngle = yRot / 511 * math.pi * 2
					end

					wheel.lastTerrainValue = streamReadUIntN(streamId, 3)
				end
			end

			if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
				local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
				local rotatedTime = streamReadUIntN(streamId, 8)

				if math.abs(self.rotatedTime) < 0.001 then
					self.rotatedTime = 0
				end

				local rotatedTimeTarget = rotatedTime / 255 * rotatedTimeRange + self.minRotTime

				self.rotatedTimeInterpolator:setTargetValue(rotatedTimeTarget)
			end
		end
	end
end

function Wheels:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_wheels

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for i = 1, table.getn(spec.wheels) do
				local wheel = spec.wheels[i]

				if wheel.isSynchronized then
					local xDrive = wheel.netInfo.xDrive % (math.pi * 2)

					streamWriteUIntN(streamId, MathUtil.clamp(math.floor(xDrive / (math.pi * 2) * 511), 0, 511), 9)
					streamWriteUIntN(streamId, MathUtil.clamp(math.floor((wheel.netInfo.y - wheel.netInfo.sync.yMin) / wheel.netInfo.sync.yRange * 255), 0, 255), 8)
					streamWriteUIntN(streamId, MathUtil.clamp(wheel.netInfo.suspensionLength * 100, 0, 128), 7)

					if wheel.tireTrackIndex ~= nil then
						streamWriteUIntN(streamId, wheel.contact, 2)
					end

					if wheel.versatileYRot then
						local yRot = wheel.steeringAngle % (math.pi * 2)

						streamWriteUIntN(streamId, MathUtil.clamp(math.floor(yRot / (math.pi * 2) * 511), 0, 511), 9)
					end

					streamWriteUIntN(streamId, wheel.lastTerrainValue, 3)
				end
			end

			if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
				local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
				local rotatedTime = MathUtil.clamp(math.floor((self.rotatedTime - self.minRotTime) / rotatedTimeRange * 255), 0, 255)

				streamWriteUIntN(streamId, rotatedTime, 8)
			end
		end
	end
end

function Wheels:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wheels

	if self.isServer and spec.wheelCreationTimer > 0 then
		spec.wheelCreationTimer = spec.wheelCreationTimer - 1

		if spec.wheelCreationTimer == 0 then
			for _, wheel in pairs(spec.wheels) do
				wheel.wheelShapeCreated = true
			end
		end
	end

	if not self.isServer and self.isClient then
		spec.networkTimeInterpolator:update(dt)

		local interpolationAlpha = spec.networkTimeInterpolator:getAlpha()
		self.rotatedTime = self.rotatedTimeInterpolator:getInterpolatedValue(interpolationAlpha)

		for i = 1, table.getn(spec.wheels) do
			local wheel = spec.wheels[i]
			wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z = wheel.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
			wheel.netInfo.xDrive = wheel.networkInterpolators.xDrive:getInterpolatedValue(interpolationAlpha)
			wheel.netInfo.suspensionLength = wheel.networkInterpolators.suspensionLength:getInterpolatedValue(interpolationAlpha)

			if wheel.driveGroundParticleSystems ~= nil then
				for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
					for _, ps in ipairs(typedPs) do
						setTranslation(ps.emitterShape, wheel.netInfo.x + ps.offsets[1], wheel.netInfo.y + ps.offsets[2], wheel.netInfo.z + ps.offsets[3])
					end
				end
			end
		end

		if spec.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	if self.firstTimeRun then
		for _, wheel in pairs(spec.wheels) do
			if self.isActive then
				self:updateWheelContact(wheel)

				if spec.wheelSinkActive then
					self:updateWheelSink(wheel, dt)
				end

				self:updateWheelFriction(wheel, dt)
				self:updateWheelTireTracks(wheel)

				if spec.wheelDensityHeightSmoothActive then
					self:updateWheelDensityMapHeight(wheel, dt)
				end

				if not GS_IS_MOBILE_VERSION then
					self:updateWheelDestruction(wheel, dt)
				end

				WheelsUtil.updateWheelPhysics(self, wheel, spec.brakePedal, dt)
			end

			local changed = WheelsUtil.updateWheelGraphics(self, wheel, dt)

			if wheel.updateWheelChock and changed then
				for _, wheelChock in ipairs(wheel.wheelChocks) do
					self:updateWheelChockPosition(wheelChock, false)
				end
			end
		end

		if self:getAreSurfaceSoundsActive() then
			if spec.surfaceSounds ~= nil then
				local currentSound = self:getCurrentSurfaceSound()

				if currentSound ~= spec.currentSurfaceSound then
					if spec.currentSurfaceSound ~= nil then
						g_soundManager:stopSample(spec.currentSurfaceSound)
					end

					if currentSound ~= nil then
						g_soundManager:playSample(currentSound)
					end

					spec.currentSurfaceSound = currentSound
				end
			end
		elseif spec.currentSurfaceSound ~= nil then
			g_soundManager:stopSample(spec.currentSurfaceSound)
		end
	end

	if #spec.wheels > 0 and self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function Wheels:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_wheels

		for _, wheel in ipairs(spec.wheels) do
			if wheel.isPositionDirty then
				self:updateWheelBase(wheel)

				wheel.isPositionDirty = false
			end

			if wheel.isFrictionDirty then
				self:updateWheelTireFriction(wheel)

				wheel.isFrictionDirty = false
			end
		end
	end
end

function Wheels:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		if wheel.rotSpeedLimit ~= nil then
			local dir = -1

			if self:getLastSpeed() <= wheel.rotSpeedLimit then
				dir = 1
			end

			wheel.currentRotSpeedAlpha = MathUtil.clamp(wheel.currentRotSpeedAlpha + dir * dt / 1000, 0, 1)
			wheel.rotSpeed = wheel.rotSpeedDefault * wheel.currentRotSpeedAlpha
			wheel.rotSpeedNeg = wheel.rotSpeedNegDefault * wheel.currentRotSpeedAlpha
		end
	end

	if self.isClient then
		local speed = self:getLastSpeed()
		local groundWetness = g_currentMission.environment.weather:getGroundWetness()
		local groundIsWet = groundWetness > 0.2

		for _, wheel in pairs(spec.wheels) do
			if wheel.driveGroundParticleSystems ~= nil then
				local states = wheel.driveGroundParticleStates
				local enableSoilPS = false

				if wheel.lastTerrainValue > 0 and wheel.lastTerrainValue < 5 then
					enableSoilPS = speed > 1
				end

				local sizeScale = 2 * wheel.width * wheel.radiusOriginal
				states.driving_dry = enableSoilPS
				states.driving_wet = enableSoilPS and groundIsWet
				states.driving_dust = not groundIsWet

				for psName, state in pairs(states) do
					local typedPs = wheel.driveGroundParticleSystems[psName]

					if typedPs ~= nil then
						for _, ps in ipairs(typedPs) do
							if state then
								if self.movingDirection < 0 then
									setRotation(ps.emitterShape, 0, math.pi + wheel.steeringAngle, 0)
								else
									setRotation(ps.emitterShape, 0, wheel.steeringAngle, 0)
								end

								local scale = nil

								if psName ~= "driving_dust" then
									local wheelSpeed = MathUtil.rpmToMps(wheel.netInfo.xDriveSpeed / (2 * math.pi) * 60, wheel.radius)
									local wheelSlip = math.pow(wheelSpeed / self.lastSpeedReal, 2.5)
									scale = self:getDriveGroundParticleSystemsScale(ps, wheelSpeed) * wheelSlip
								else
									scale = self:getDriveGroundParticleSystemsScale(ps, self.lastSpeedReal)
								end

								if ps.isTintable then
									if ps.lastColor == nil then
										ps.lastColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.targetColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.currentColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.alpha = 1
									end

									if ps.alpha ~= 1 then
										ps.alpha = math.min(ps.alpha + dt / 1000, 1)
										ps.currentColor = {
											MathUtil.vector3ArrayLerp(ps.lastColor, ps.targetColor, ps.alpha)
										}

										if ps.alpha == 1 then
											ps.lastColor[1] = ps.currentColor[1]
											ps.lastColor[2] = ps.currentColor[2]
											ps.lastColor[3] = ps.currentColor[3]
										end
									end

									if ps.alpha == 1 and ps.wheel.lastColor[1] ~= ps.targetColor[1] and ps.wheel.lastColor[2] ~= ps.targetColor[2] and ps.wheel.lastColor[3] ~= ps.targetColor[3] then
										ps.alpha = 0
										ps.targetColor[1] = ps.wheel.lastColor[1]
										ps.targetColor[2] = ps.wheel.lastColor[2]
										ps.targetColor[3] = ps.wheel.lastColor[3]
									end
								end

								if scale > 0 then
									ParticleUtil.setEmittingState(ps, true)

									if ps.isTintable then
										setShaderParameter(ps.shape, "psColor", ps.currentColor[1], ps.currentColor[2], ps.currentColor[3], 1, false)
									end
								else
									ParticleUtil.setEmittingState(ps, false)
								end

								local maxSpeed = 13.88888888888889
								local circum = wheel.radiusOriginal
								local maxWheelRpm = maxSpeed / circum
								local wheelRotFactor = Utils.getNoNil(wheel.netInfo.xDriveSpeed, 0) / maxWheelRpm
								local emitScale = scale * wheelRotFactor * sizeScale

								ParticleUtil.setEmitCountScale(ps, MathUtil.clamp(emitScale, ps.minScale, ps.maxScale))

								local speedFactor = 1

								ParticleUtil.setParticleSystemSpeed(ps, ps.particleSpeed * speedFactor)
								ParticleUtil.setParticleSystemSpeedRandom(ps, ps.particleRandomSpeed * speedFactor)
							else
								ParticleUtil.setEmittingState(ps, false)
							end
						end
					end

					states[psName] = false
				end
			end
		end
	end
end

function Wheels:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_wheels

		for _, wheel in pairs(spec.wheels) do
			if wheel.driveGroundParticleSystems ~= nil then
				for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
					for _, ps in ipairs(typedPs) do
						ParticleUtil.setEmittingState(ps, false)
					end
				end
			end
		end

		if spec.currentSurfaceSound ~= nil then
			g_soundManager:stopSample(spec.currentSurfaceSound)

			spec.currentSurfaceSound = nil
		end
	end
end

function Wheels:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		wheel.xDriveOffset = wheel.netInfo.xDrive
		wheel.updateWheel = false

		self:updateWheelBase(wheel)
		self:updateWheelTireFriction(wheel)
	end

	if self.isServer then
		local brakeForce = self:getBrakeForce()

		for _, wheel in pairs(spec.wheels) do
			setWheelShapeProps(wheel.node, wheel.wheelShape, 0, brakeForce * wheel.brakeFactor, wheel.steeringAngle, wheel.rotationDamping)
			setWheelShapeAutoHoldBrakeForce(wheel.node, wheel.wheelShape, brakeForce * wheel.autoHoldBrakeFactor)
		end

		self:brake(brakeForce)

		spec.wheelCreationTimer = 2
	end

	return true
end

function Wheels:removeFromPhysics(superFunc)
	local ret = superFunc(self)

	if self.isServer then
		local spec = self.spec_wheels

		for _, wheel in pairs(spec.wheels) do
			wheel.wheelShape = 0
			wheel.wheelShapeCreated = false
		end
	end

	return ret
end

function Wheels:getTotalMass(superFunc, onlyGivenVehicle)
	local mass = superFunc(self)
	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		mass = mass + wheel.mass
	end

	return mass
end

function Wheels:validateWashableNode(superFunc, node)
	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		local wheelNode = wheel.driveNode

		if wheel.linkNode ~= wheel.driveNode then
			wheelNode = wheel.linkNode
		end

		local wheelNodes = {}

		I3DUtil.getNodesByShaderParam(wheelNode, "RDT", wheelNodes)

		if wheelNodes[node] ~= nil then
			return false, self.updateWheelDirtAmount, wheel, {
				wheel = wheel,
				fieldDirtMultiplier = wheel.fieldDirtMultiplier,
				streetDirtMultiplier = wheel.streetDirtMultiplier,
				minDirtPercentage = wheel.minDirtPercentage
			}
		end
	end

	return superFunc(self, node)
end

function Wheels:getAIVehicleDirectionNode(superFunc)
	return self.spec_wheels.steeringCenterNode
end

function Wheels:updateWheelDirtAmount(nodeData, dt)
	local dirtAmount = self:updateDirtAmount(nodeData, dt)
	local allowManipulation = true

	if nodeData.wheel ~= nil and nodeData.wheel.contact == Wheels.WHEEL_NO_CONTACT then
		allowManipulation = false
	end

	if allowManipulation then
		local isOnField = false

		if nodeData.wheel ~= nil and nodeData.wheel.densityType ~= 0 and nodeData.wheel.densityType ~= g_currentMission.grassValue then
			isOnField = true
		end

		if isOnField then
			dirtAmount = dirtAmount * nodeData.fieldDirtMultiplier
		elseif nodeData.minDirtPercentage < self:getNodeDirtAmount(nodeData) then
			local speedFactor = self:getLastSpeed() / 20
			dirtAmount = dirtAmount * nodeData.streetDirtMultiplier * speedFactor
		end
	end

	return dirtAmount
end

function Wheels:getAllowTireTracks()
	return true
end

function Wheels:setWheelPositionDirty(wheel)
	if wheel ~= nil then
		wheel.isPositionDirty = true
	end
end

function Wheels:setWheelTireFrictionDirty(wheel)
	if wheel ~= nil then
		wheel.isFrictionDirty = true
	end
end

function Wheels:updateWheelContact(wheel)
	local spec = self.spec_wheels
	local wx = wheel.netInfo.x
	local wy = wheel.netInfo.y
	local wz = wheel.netInfo.z
	wy = wy - wheel.radius
	wx = wx + wheel.xOffset
	wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)

	if self.isServer and self.isAddedToPhysics and wheel.wheelShapeCreated then
		local contactObject, contactSubShapeIndex = getWheelShapeContactObject(wheel.node, wheel.wheelShape)

		if contactObject == g_currentMission.terrainRootNode then
			if contactSubShapeIndex <= 0 then
				wheel.contact = Wheels.WHEEL_GROUND_CONTACT
			else
				wheel.contact = Wheels.WHEEL_GROUND_HEIGHT_CONTACT
			end
		elseif wheel.hasGroundContact and contactObject ~= 0 and getRigidBodyType(contactObject) == "Static" and getUserAttribute(contactObject, "noTireTracks") ~= true then
			wheel.contact = Wheels.WHEEL_OBJ_CONTACT
		else
			wheel.contact = Wheels.WHEEL_NO_CONTACT
		end
	end

	if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
		wheel.densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, wx, wy, wz)
		wheel.densityType = bitAND(bitShiftRight(wheel.densityBits, g_currentMission.terrainDetailTypeFirstChannel), 2^g_currentMission.terrainDetailTypeNumChannels - 1)
	else
		wheel.densityBits = 0
		wheel.densityType = 0
	end

	wheel.shallowWater = wy < g_currentMission.waterY
end

function Wheels:getTireTrackColor(wheel, wx, wy, wz)
	local r, g, b = nil
	local a = 0
	local t = nil

	if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
		local isOnField = wheel.densityType ~= 0
		local dirtAmount = 1

		if isOnField then
			r, g, b, a = FSDensityMapUtil.getTireTrackColorFromDensityBits(wheel.densityBits)
			t = 1

			if wheel.densityType == g_currentMission.grassValue then
				dirtAmount = 0.7
			end
		else
			r, g, b, a, t = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz, true, true, true, true, false)
			dirtAmount = 0.5
		end

		wheel.dirtAmount = dirtAmount
		wheel.lastColor[1] = r
		wheel.lastColor[2] = g
		wheel.lastColor[3] = b
		wheel.lastColor[4] = a
		wheel.lastTerrainAttribute = t
	elseif wheel.contact == Wheels.WHEEL_OBJ_CONTACT and wheel.dirtAmount > 0 then
		local maxTrackLength = 30 * (1 + g_currentMission.environment.weather:getGroundWetness())
		local speedFactor = math.min(self:getLastSpeed(), 20) / 20
		maxTrackLength = maxTrackLength * (2 - speedFactor)
		wheel.dirtAmount = math.max(wheel.dirtAmount - self.lastMovedDistance / maxTrackLength, 0)
		b = wheel.lastColor[3]
		g = wheel.lastColor[2]
		r = wheel.lastColor[1]
		a = 0
	end

	return r, g, b, a, t
end

function Wheels:updateWheelTireTracks(wheel)
	local wx = wheel.netInfo.x
	local wy = wheel.netInfo.y
	local wz = wheel.netInfo.z
	wy = wy - wheel.radius
	wx = wx + wheel.xOffset
	wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
	local r, g, b, a, t = self:getTireTrackColor(wheel, wx, wy, wz)

	if wheel.tireTrackIndex ~= nil then
		if self:getAllowTireTracks() and r ~= nil then
			local ux, uy, uz = localDirectionToWorld(wheel.node, 0, 1, 0)
			local tireDirection = self.movingDirection

			if wheel.tireIsInverted then
				tireDirection = tireDirection * -1
			end

			g_currentMission.tireTrackSystem:addTrackPoint(wheel.tireTrackIndex, wx, wy, wz, ux, uy, uz, r, g, b, wheel.dirtAmount, a, tireDirection)

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in pairs(wheel.additionalWheels) do
					if additionalWheel.tireTrackIndex ~= nil then
						wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(additionalWheel.wheelTire))
						wy = wy - wheel.radius
						wx = wx + wheel.xOffset
						wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
						wy = math.max(wy, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz))
						tireDirection = self.movingDirection

						if additionalWheel.tireIsInverted then
							tireDirection = tireDirection * -1
						end

						g_currentMission.tireTrackSystem:addTrackPoint(additionalWheel.tireTrackIndex, wx, wy, wz, ux, uy, uz, r, g, b, wheel.dirtAmount, a, tireDirection)
					end
				end
			end
		else
			g_currentMission.tireTrackSystem:cutTrack(wheel.tireTrackIndex)

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in pairs(wheel.additionalWheels) do
					if additionalWheel.tireTrackIndex ~= nil then
						g_currentMission.tireTrackSystem:cutTrack(additionalWheel.tireTrackIndex)
					end
				end
			end
		end
	end
end

function Wheels:getCurrentSurfaceSound()
	local spec = self.spec_wheels

	for _, wheel in ipairs(spec.wheels) do
		if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
			local isOnField = wheel.densityType ~= 0
			local shallowWater = wheel.shallowWater

			if isOnField then
				return spec.surfaceNameToSound.field
			elseif shallowWater then
				return spec.surfaceNameToSound.shallowWater
			else
				return spec.surfaceIdToSound[wheel.lastTerrainAttribute]
			end
		elseif wheel.contact == Wheels.WHEEL_OBJ_CONTACT then
			return spec.surfaceNameToSound.asphalt
		elseif wheel.contact ~= Wheels.WHEEL_NO_CONTACT then
			break
		end
	end
end

function Wheels:getAreSurfaceSoundsActive()
	return self:getIsActive()
end

function Wheels:updateWheelDensityMapHeight(wheel, dt)
	if not self.isServer then
		return
	end

	local spec = self.spec_wheels
	local wheelSmoothAmount = 0

	if self.lastSpeedReal > 0.0002 then
		wheelSmoothAmount = spec.wheelSmoothAccumulation + math.max(self.lastMovedDistance * 1.2, 0.0003 * dt)
		local rounded = DensityMapHeightUtil.getRoundedHeightValue(wheelSmoothAmount)
		spec.wheelSmoothAccumulation = wheelSmoothAmount - rounded
	else
		spec.wheelSmoothAccumulation = 0
	end

	if wheelSmoothAmount == 0 then
		return
	end

	local wx = wheel.netInfo.x
	local wy = wheel.netInfo.y
	local wz = wheel.netInfo.z
	wy = wy - wheel.radius
	wx = wx + wheel.xOffset
	wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)

	if wheel.smoothGroundRadius > 0 then
		local smoothYOffset = -0.1
		local heightType = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(wx, wy, wz, wheel.smoothGroundRadius)

		if heightType ~= nil and heightType.allowsSmoothing then
			local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

			if terrainHeightUpdater ~= nil then
				local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)
				local physicsDeltaHeight = wy - terrainHeight
				local deltaHeight = (physicsDeltaHeight + heightType.collisionBaseOffset) / heightType.collisionScale
				deltaHeight = math.min(math.max(deltaHeight, physicsDeltaHeight + heightType.minCollisionOffset), physicsDeltaHeight + heightType.maxCollisionOffset)
				deltaHeight = math.max(deltaHeight + smoothYOffset, 0)
				local internalHeight = terrainHeight + deltaHeight

				smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, wx, internalHeight, wz, wheelSmoothAmount, heightType.index, 0, wheel.smoothGroundRadius, wheel.smoothGroundRadius + 1.2)

				if Vehicle.debugRendering then
					DebugUtil.drawDebugCircle(wx, internalHeight, wz, wheel.smoothGroundRadius, 10)
				end
			end
		end

		if wheel.additionalWheels ~= nil then
			for _, additionalWheel in pairs(wheel.additionalWheels) do
				local refNode = wheel.repr
				local xShift, yShift, zShift = localToLocal(additionalWheel.wheelTire, refNode, additionalWheel.xOffset, 0, 0)
				local wx, wy, wz = localToWorld(refNode, xShift, yShift - additionalWheel.radius, zShift)
				local heightType = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(wx, wy, wz, additionalWheel.smoothGroundRadius)

				if heightType ~= nil and heightType.allowsSmoothing then
					local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

					if terrainHeightUpdater ~= nil then
						local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)
						local physicsDeltaHeight = wy - terrainHeight
						local deltaHeight = (physicsDeltaHeight + heightType.collisionBaseOffset) / heightType.collisionScale
						deltaHeight = math.min(math.max(deltaHeight, physicsDeltaHeight + heightType.minCollisionOffset), physicsDeltaHeight + heightType.maxCollisionOffset)
						deltaHeight = math.max(deltaHeight + smoothYOffset, 0)
						local internalHeight = terrainHeight + deltaHeight

						smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, wx, internalHeight, wz, wheelSmoothAmount, heightType.index, 0, additionalWheel.smoothGroundRadius, additionalWheel.smoothGroundRadius + 1.2)

						if Vehicle.debugRendering then
							DebugUtil.drawDebugCircle(wx, internalHeight, wz, additionalWheel.smoothGroundRadius, 10)
						end
					end
				end
			end
		end
	end
end

function Wheels:updateWheelDestruction(wheel, dt)
	if self:getIsWheelFoliageDestructionAllowed(wheel) then
		local width = 0.5 * wheel.width
		local length = math.min(0.5, 0.5 * wheel.width)
		local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
		local x0, y0, z0 = localToWorld(wheel.repr, x + width, 0, z - length)
		local x1, y1, z1 = localToWorld(wheel.repr, x - width, 0, z - length)
		local x2, y2, z2 = localToWorld(wheel.repr, x + width, 0, z + length)

		if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x0, z0) then
			self:destroyFruitArea(x0, z0, x1, z1, x2, z2)
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
			drawDebugLine(x0, y0, z0, 1, 0, 0, x1, y1, z1, 1, 0, 0)
			drawDebugLine(x0, y0, z0, 1, 1, 0, x2, y2, z2, 1, 1, 0)
		end

		if wheel.additionalWheels ~= nil then
			for _, additionalWheel in pairs(wheel.additionalWheels) do
				local width = 0.5 * additionalWheel.width
				local length = math.min(0.5, 0.5 * additionalWheel.width)
				local refNode = wheel.node

				if wheel.repr ~= wheel.driveNode then
					refNode = wheel.repr
				end

				local xShift, yShift, zShift = localToLocal(additionalWheel.wheelTire, refNode, 0, 0, 0)
				local x0, y0, z0 = localToWorld(refNode, xShift + width, yShift, zShift - length)
				local x1, y1, z1 = localToWorld(refNode, xShift - width, yShift, zShift - length)
				local x2, y2, z2 = localToWorld(refNode, xShift + width, yShift, zShift + length)

				if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getActiveFarm(), x0, z0) then
					self:destroyFruitArea(x0, z0, x1, z1, x2, z2)
				end

				if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
					drawDebugLine(x0, y0, z0, 1, 0, 0, x1, y1, z1, 1, 0, 0)
					drawDebugLine(x0, y0, z0, 1, 1, 0, x2, y2, z2, 1, 1, 0)
				end
			end
		end
	end
end

function Wheels:getIsWheelFoliageDestructionAllowed(wheel)
	if not g_currentMission.missionInfo.fruitDestruction then
		return false
	end

	if self:getIsAIActive() then
		return false
	end

	if wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT then
		return false
	end

	if wheel.isCareWheel then
		return false
	end

	if self.getBlockFoliageDestruction ~= nil and self:getBlockFoliageDestruction() then
		return false
	end

	return true
end

function Wheels:updateWheelSink(wheel, dt)
	if wheel.supportsWheelSink and self.isServer and self.isAddedToPhysics then
		local spec = self.spec_wheels
		local maxSink = 0.2
		local sinkTarget = 0

		if wheel.mirroredWheel == nil then
			for _, mirWheel in ipairs(spec.wheels) do
				if mirWheel.mirroredWheel == nil and mirWheel ~= wheel then
					local x1, y1, z1 = localToLocal(wheel.node, wheel.repr, 0, 0, 0)
					local x2, y2, z2 = localToLocal(wheel.node, mirWheel.repr, 0, 0, 0)
					local diff = math.abs(x1 - -x2) + math.abs(y1 - y2) + math.abs(z1 - z2)

					if diff < 0.25 then
						wheel.mirroredWheel = mirWheel
						mirWheel.invMirroredWheel = wheel
					end
				end
			end
		end

		local force = false

		if wheel.contact ~= Wheels.WHEEL_NO_CONTACT and self:getLastSpeed() > 0.3 then
			wheel.avgSink = nil
			local width = 0.25 * wheel.width
			local length = 0.25 * wheel.width
			local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
			local x0, _, z0 = localToWorld(wheel.repr, x + width, 0, z - length)
			local x1, _, z1 = localToWorld(wheel.repr, x - width, 0, z - length)
			local x2, _, z2 = localToWorld(wheel.repr, x + width, 0, z + length)
			local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
			local density, area = FSDensityMapUtil.getFieldValue(x0, z0, x1, z1, x2, z2)
			local terrainValue = 0

			if area > 0 then
				terrainValue = math.floor(density / area + 0.5)
			end

			wheel.lastTerrainValue = terrainValue
			local noiseValue = 0

			if terrainValue > 0 then
				local xPerlin = x + 0.5 * widthX + 0.5 * heightX
				local zPerlin = z + 0.5 * widthZ + 0.5 * heightZ
				xPerlin = math.floor(xPerlin * 100) * 0.01
				zPerlin = math.floor(zPerlin * 100) * 0.01
				local perlinNoise = Wheels.perlinNoiseSink
				local noiseSink = 0.5 * (1 + getPerlinNoise2D(xPerlin * perlinNoise.randomFrequency, zPerlin * perlinNoise.randomFrequency, perlinNoise.persistence, perlinNoise.numOctaves, perlinNoise.randomSeed))
				perlinNoise = Wheels.perlinNoiseWobble
				local noiseWobble = 0.5 * (1 + getPerlinNoise2D(xPerlin * perlinNoise.randomFrequency, zPerlin * perlinNoise.randomFrequency, perlinNoise.persistence, perlinNoise.numOctaves, perlinNoise.randomSeed))
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

				tireLoad = tireLoad / gravity
				local loadFactor = math.min(1, math.max(0, tireLoad / wheel.maxLatStiffnessLoad))
				local wetnessFactor = g_currentMission.environment.weather:getGroundWetness()
				noiseSink = 0.333 * (2 * loadFactor + wetnessFactor) * noiseSink
				noiseValue = math.max(noiseSink, noiseWobble)
			end

			maxSink = Wheels.MAX_SINK[terrainValue] or maxSink

			if terrainValue == 2 and wheel.oppositeWheelIndex ~= nil then
				local oppositeWheel = spec.wheels[wheel.oppositeWheelIndex]

				if oppositeWheel.lastTerrainValue ~= nil and oppositeWheel.lastTerrainValue ~= 2 then
					maxSink = maxSink * 1.3
				end
			end

			sinkTarget = math.min(0.2 * wheel.radiusOriginal, math.min(maxSink, wheel.maxWheelSink) * noiseValue)
		elseif self:getLastSpeed() < 0.3 then
			if wheel.mirroredWheel ~= nil then
				if wheel.avgSink == nil then
					wheel.avgSink = (wheel.mirroredWheel.sinkTarget + wheel.sinkTarget) / 2
				end

				sinkTarget = wheel.avgSink
				force = wheel.sink ~= wheel.avgSink
				wheel.sinkTarget = sinkTarget
			elseif wheel.invMirroredWheel ~= nil and wheel.invMirroredWheel.avgSink ~= nil then
				sinkTarget = wheel.invMirroredWheel.avgSink
				force = wheel.sink ~= wheel.invMirroredWheel.avgSink
				wheel.sinkTarget = sinkTarget
			end
		end

		if wheel.sinkTarget < sinkTarget then
			wheel.sinkTarget = math.min(sinkTarget, wheel.sinkTarget + 0.05 * math.min(30, math.max(0, self:getLastSpeed() - 0.2)) * dt / 1000)
		elseif sinkTarget < wheel.sinkTarget then
			wheel.sinkTarget = math.max(sinkTarget, wheel.sinkTarget - 0.05 * math.min(30, math.max(0, self:getLastSpeed() - 0.2)) * dt / 1000)
		end

		if math.abs(wheel.sink - wheel.sinkTarget) > 0.001 or force then
			wheel.sink = wheel.sinkTarget
			local radius = wheel.radiusOriginal - wheel.sink

			if radius ~= wheel.radius then
				wheel.radius = radius

				if self.isServer then
					self:setWheelPositionDirty(wheel)

					local sinkFactor = wheel.sink / maxSink * (1 + 0.4 * g_currentMission.environment.weather:getGroundWetness())
					wheel.sinkLongStiffnessFactor = 1 - 0.1 * sinkFactor
					wheel.sinkLatStiffnessFactor = 1 - 0.2 * sinkFactor

					self:setWheelTireFrictionDirty(wheel)
				end
			end
		end
	end
end

function Wheels:updateWheelFriction(wheel, dt)
	if self.isServer then
		local isOnField = wheel.densityType ~= 0
		local depth = wheel.lastColor[4]
		local groundType = WheelsUtil.getGroundType(isOnField, wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT, depth)
		local coeff = WheelsUtil.getTireFriction(wheel.tireType, groundType, g_currentMission.environment.weather:getGroundWetness())

		if self:getLastSpeed() > 0.2 and coeff ~= wheel.tireGroundFrictionCoeff then
			wheel.tireGroundFrictionCoeff = coeff

			self:setWheelTireFrictionDirty(wheel)
		end
	end
end

function Wheels:updateWheelBase(wheel)
	if self.isServer and self.isAddedToPhysics then
		local positionX = wheel.positionX - wheel.directionX * wheel.deltaY
		local positionY = wheel.positionY - wheel.directionY * wheel.deltaY
		local positionZ = wheel.positionZ - wheel.directionZ * wheel.deltaY
		local x1, y1, z1 = localToWorld(wheel.node, wheel.positionX, wheel.positionY, wheel.positionZ)
		local x2, y2, z2 = localToWorld(wheel.node, positionX, positionY, positionZ)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		local collisionMask = 251
		wheel.wheelShape = createWheelShape(wheel.node, positionX, positionY, positionZ, wheel.radius, wheel.suspTravel, wheel.spring, wheel.damperCompressionLowSpeed, wheel.damperCompressionHighSpeed, wheel.damperCompressionLowSpeedThreshold, wheel.damperRelaxationLowSpeed, wheel.damperRelaxationHighSpeed, wheel.damperRelaxationLowSpeedThreshold, wheel.mass, collisionMask, wheel.wheelShape)
		local forcePointY = positionY - wheel.radius * wheel.forcePointRatio
		local steeringX, steeringY, steeringZ = localToLocal(getParent(wheel.repr), wheel.node, wheel.startPositionX, wheel.startPositionY + wheel.deltaY, wheel.startPositionZ)

		setWheelShapeForcePoint(wheel.node, wheel.wheelShape, wheel.positionX, forcePointY, positionZ)
		setWheelShapeSteeringCenter(wheel.node, wheel.wheelShape, steeringX, steeringY, steeringZ)
		setWheelShapeDirection(wheel.node, wheel.wheelShape, wheel.directionX, wheel.directionY, wheel.directionZ, wheel.axleX, wheel.axleY, wheel.axleZ)
		setWheelShapeWidth(wheel.node, wheel.wheelShape, wheel.wheelshapeWidth, wheel.widthOffset)

		if wheel.driveGroundParticleSystems ~= nil then
			for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
				for _, ps in ipairs(typedPs) do
					setTranslation(ps.emitterShape, wheel.positionX + ps.offsets[1], positionY + ps.offsets[2], wheel.positionZ + ps.offsets[3])
				end
			end
		end
	end
end

function Wheels:updateWheelTireFriction(wheel)
	if self.isServer and self.isAddedToPhysics then
		setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.sinkFrictionScaleFactor * wheel.maxLongStiffness, wheel.sinkLatStiffnessFactor * wheel.maxLatStiffness, wheel.maxLatStiffnessLoad, wheel.sinkFrictionScaleFactor * wheel.frictionScale * wheel.tireGroundFrictionCoeff)
	end
end

function Wheels:getDriveGroundParticleSystemsScale(particleSystem, speed)
	local wheel = particleSystem.wheel

	if wheel ~= nil then
		if particleSystem.onlyActiveOnGroundContact and wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT then
			return 0
		end

		if not Wheels.GROUND_PARTICLES[wheel.lastTerrainAttribute] then
			return 0
		end

		if wheel.densityType == g_currentMission.grassValue then
			return 0
		end
	end

	local minSpeed = particleSystem.minSpeed
	local direction = particleSystem.direction

	if minSpeed < speed and (direction == 0 or direction > 0 == (self.movingDirection > 0)) then
		local maxSpeed = particleSystem.maxSpeed
		local alpha = math.min((speed - minSpeed) / (maxSpeed - minSpeed), 1)
		local scale = MathUtil.lerp(particleSystem.minScale, particleSystem.maxScale, alpha)

		return scale
	end

	return 0
end

function Wheels:loadDynamicWheelDataFromXML(xmlFile, key, wheelnamei, wheel)
	local spec = self.spec_wheels

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, string.format("vehicle.wheels%s#hasTyreTracks", wheelnamei), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels%s#hasTireTracks", wheelnamei))
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, string.format("vehicle.wheels%s#tyreTrackAtlasIndex", wheelnamei), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels%s#tireTrackAtlasIndex", wheelnamei))
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, string.format("vehicle.wheels%s#configIndex", wheelnamei), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels%s#configId", wheelnamei))

	local colorStr = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#color", getXMLString, nil, , )

	if colorStr ~= nil then
		wheel.color = ConfigurationUtil.getColorFromString(colorStr)
	end

	local additionalColorStr = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#additionalColor", getXMLString, nil, , )

	if additionalColorStr ~= nil then
		wheel.additionalColor = ConfigurationUtil.getColorFromString(additionalColorStr)
	end

	wheel.isLeft = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#isLeft", getXMLBool, true, nil, )
	local wheelXmlFilename = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#filename", getXMLString, nil, , )

	if wheelXmlFilename ~= nil and wheelXmlFilename ~= "" then
		local wheelConfigId = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#configId", getXMLString, "default", nil, )
		wheel.xRotOffset = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#xRotOffset", getXMLFloat, 0, nil, )

		self:loadWheelDataFromExternalXML(wheel, wheelXmlFilename, wheelConfigId, true)
	end

	self:loadWheelData(wheel, xmlFile, key .. wheelnamei)

	if wheel.mass == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'mass' for wheel '%s'. Using default '0.1'!", string.format(key .. "%s", wheelnamei))

		wheel.mass = 0.1
	end

	self:loadWheelPhysicsData(self.xmlFile, key, wheelnamei, wheel)

	local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, self.configurations.wheel, "vehicle.wheels.wheelConfigurations.wheelConfiguration", "vehicle", "wheels")
	key = key .. ".wheels"
	local i = 0

	while true do
		local additionalWheelKey = string.format(key .. wheelnamei .. ".additionalWheel(%d)", i)

		if not hasXMLProperty(xmlFile, additionalWheelKey) then
			break
		end

		local wheelXmlFilename = getXMLString(xmlFile, additionalWheelKey .. "#filename")

		if wheelXmlFilename ~= nil and wheelXmlFilename ~= "" then
			XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, additionalWheelKey .. "#configIndex", additionalWheelKey .. "#configId")
			XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, additionalWheelKey .. "#addRaycast", nil)

			local additionalWheel = {
				node = wheel.node,
				key = additionalWheelKey,
				linkNode = wheel.linkNode
			}
			local wheelConfigId = Utils.getNoNil(getXMLString(xmlFile, additionalWheelKey .. "#configId"), "default")
			additionalWheel.isLeft = Utils.getNoNil(getXMLBool(xmlFile, additionalWheelKey .. "#isLeft"), wheel.isLeft) or false
			additionalWheel.xRotOffset = Utils.getNoNilRad(getXMLFloat(xmlFile, additionalWheelKey .. "#xRotOffset"), 0)
			additionalWheel.color = Utils.getNoNil(ConfigurationUtil.getColorFromString(getXMLString(xmlFile, additionalWheelKey .. "#color")), wheel.color)

			if self:loadWheelDataFromExternalXML(additionalWheel, wheelXmlFilename, wheelConfigId, false) then
				additionalWheel.hasParticles = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, additionalWheelKey .. "#hasParticles"), wheel.hasParticles), false)
				additionalWheel.hasTireTracks = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, additionalWheelKey .. "#hasTireTracks"), wheel.hasTireTracks), false)

				if g_currentMission.tireTrackSystem ~= nil and additionalWheel.hasTireTracks then
					additionalWheel.tireTrackIndex = g_currentMission.tireTrackSystem:createTrack(additionalWheel.width, additionalWheel.tireTrackAtlasIndex)
				end

				additionalWheel.offset = Utils.getNoNil(getXMLFloat(xmlFile, additionalWheelKey .. "#offset"), 0)

				self:loadConnectorFromXML(wheel, additionalWheel, xmlFile, additionalWheelKey)

				if wheel.additionalWheels == nil then
					wheel.additionalWheels = {}
				end

				table.insert(wheel.additionalWheels, additionalWheel)

				wheel.mass = wheel.mass + additionalWheel.mass
				wheel.maxLatStiffness = wheel.maxLatStiffness + additionalWheel.maxLatStiffness
				wheel.maxLongStiffness = wheel.maxLongStiffness + additionalWheel.maxLongStiffness
			end
		end

		i = i + 1
	end

	local i = 0

	while true do
		local chockKey = string.format("%s%s.wheelChock(%d)", key, wheelnamei, i)

		if not hasXMLProperty(self.xmlFile, chockKey) then
			break
		end

		local filename = Utils.getNoNil(getXMLString(xmlFile, chockKey .. "#filename"), "$data/shared/assets/wheelChocks/wheelChock01.i3d")
		local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

		if i3dNode ~= 0 then
			local chockNode = getChildAt(i3dNode, 0)
			local posRefNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "posRefNode"), self.i3dMappings)

			if posRefNode ~= nil then
				local chock = {
					wheel = wheel,
					node = chockNode,
					filename = filename,
					scale = Utils.getNoNil(StringUtil.getVectorNFromString(getXMLString(xmlFile, chockKey .. "#scale"), 3), {
						1,
						1,
						1
					})
				}

				setScale(chock.node, unpack(chock.scale))

				chock.parkingNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, chockKey .. "#parkingNode"), self.i3dMappings)
				chock.isInverted = Utils.getNoNil(getXMLBool(xmlFile, chockKey .. "#isInverted"), false)
				chock.isParked = Utils.getNoNil(getXMLBool(xmlFile, chockKey .. "#isParked"), false)
				_, chock.height, chock.zOffset = localToLocal(posRefNode, chock.node, 0, 0, 0)
				chock.height = chock.height / chock.scale[2]
				chock.zOffset = chock.zOffset / chock.scale[3]
				chock.offset = Utils.getNoNil(StringUtil.getVectorNFromString(getXMLString(xmlFile, chockKey .. "#offset"), 3), {
					0,
					0,
					0
				})
				chock.parkedNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "parkedNode"), self.i3dMappings)
				chock.linkedNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "linkedNode"), self.i3dMappings)
				local color = g_brandColorManager:loadColorAndMaterialFromXML(self.configFileName, chockNode, "colorMat0", xmlFile, chockKey, "color", false)

				if color ~= nil then
					I3DUtil.setShaderParameterRec(chockNode, "colorMat0", color[1], color[2], color[3], color[4])
				end

				self:updateWheelChockPosition(chock, chock.isParked)

				wheel.updateWheelChock = false

				if wheel.wheelChocks == nil then
					wheel.wheelChocks = {}
				end

				table.insert(wheel.wheelChocks, chock)
				table.insert(spec.wheelChocks, chock)
			else
				g_logManager:xmlWarning(self.configFileName, "Missing 'posRefNode'-userattribute for wheel-chock '%s'!", chockKey)
			end

			delete(i3dNode)
		end

		i = i + 1
	end

	if wheel.hasParticles then
		self:loadWheelParticleSystem(wheel, xmlFile, key .. wheelnamei)
	end

	if wheel.driveGroundParticleSystems ~= nil then
		local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode))

		for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
			for _, ps in ipairs(typedPs) do
				setTranslation(ps.rootNode, wx + ps.offsets[1], wy - wheel.radius + ps.offsets[2], wz + ps.offsets[3])
			end
		end
	end

	wheel.wheelShape = 0
	wheel.wheelShapeCreated = false
end

function Wheels:loadConnectorFromXML(wheel, additionalWheel, xmlFile, wheelKey)
	local spec = self.spec_wheels
	local connectorFilename = getXMLString(xmlFile, wheelKey .. ".connector#filename")

	if connectorFilename ~= nil and connectorFilename ~= "" then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, wheelKey .. ".connector#index", wheelKey .. ".connector#node")

		local connector = {}

		if StringUtil.endsWith(connectorFilename, ".xml") then
			local xmlFilename = Utils.getFilename(connectorFilename, self.baseDirectory)
			local connectorXmlFile = loadXMLFile("TempConfig", xmlFilename)

			if connectorXmlFile ~= nil then
				local nodeKey = "leftNode"

				if not wheel.isLeft then
					nodeKey = "rightNode"
				end

				connector.filename = getXMLString(connectorXmlFile, "connector.file#name")
				connector.nodeStr = getXMLString(connectorXmlFile, "connector.file#" .. nodeKey)

				delete(connectorXmlFile)
			else
				g_logManager:xmlError(self.configFileName, "Unable to load connector xml file '%s'!", connectorFilename)
			end
		else
			connector.filename = connectorFilename
			connector.nodeStr = getXMLString(xmlFile, wheelKey .. ".connector#node")
		end

		if connector.filename ~= nil and connector.filename ~= "" then
			connector.useWidthAndDiam = Utils.getNoNil(getXMLBool(xmlFile, wheelKey .. ".connector#useWidthAndDiam"), false)
			connector.usePosAndScale = Utils.getNoNil(getXMLBool(xmlFile, wheelKey .. ".connector#usePosAndScale"), false)
			connector.diameter = getXMLFloat(xmlFile, wheelKey .. ".connector#diameter")
			connector.additionalOffset = Utils.getNoNil(getXMLFloat(xmlFile, wheelKey .. ".connector#offset"), 0)
			connector.width = getXMLFloat(xmlFile, wheelKey .. ".connector#width")
			connector.distance = getXMLFloat(xmlFile, wheelKey .. ".connector#distance")
			connector.startPos = getXMLFloat(xmlFile, wheelKey .. ".connector#startPos")
			connector.endPos = getXMLFloat(xmlFile, wheelKey .. ".connector#endPos")
			connector.scale = getXMLFloat(xmlFile, wheelKey .. ".connector#uniformScale")
			connector.color = ConfigurationUtil.getColorFromString(getXMLString(xmlFile, wheelKey .. ".connector#color")) or ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor) or wheel.color or spec.rimColor
			additionalWheel.connector = connector
		end
	end
end

function Wheels:loadWheelParticleSystem(wheel, xmlFile, key)
	wheel.driveGroundParticleSystems = {}
	wheel.driveGroundParticleStates = {
		driving_wet = false,
		driving_dust = false,
		driving_dry = false
	}

	local function getParticleSystem(xmlFile, wheelKey, wheelData, particleSystem)
		local emitterShapeRoot = g_i3DManager:loadSharedI3DFile("$data/particleSystems/shared/wheelEmitterShape.i3d", self.baseDirectory, false, false, false)

		if emitterShapeRoot == 0 or emitterShapeRoot == nil then
			local emitterShape = getChildAt(emitterShapeRoot, 0)

			link(wheel.node, emitterShape)
			delete(emitterShapeRoot)

			local ps = ParticleUtil.copyParticleSystem(xmlFile, wheelKey, particleSystem, emitterShape)
			ps.particleSpeed = ParticleUtil.getParticleSystemSpeed(ps)
			ps.particleRandomSpeed = ParticleUtil.getParticleSystemSpeedRandom(ps)
			ps.isTintable = Utils.getNoNil(getUserAttribute(ps.shape, "tintable"), true)
			ps.offsets = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, wheelKey .. ".wheelParticleSystem#psOffset"), "0 0 0"), 3)
			local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode))

			setTranslation(ps.emitterShape, wx + ps.offsets[1], wy + ps.offsets[2], wz + ps.offsets[3])
			setScale(ps.emitterShape, wheelData.width, wheelData.radius * 2, wheelData.radius * 2)

			ps.wheel = wheel
			ps.rootNode = ps.emitterShape
			ps.minSpeed = Utils.getNoNil(getXMLFloat(xmlFile, wheelKey .. ".wheelParticleSystem#minSpeed"), 3) / 3600
			ps.maxSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, wheelKey .. ".wheelParticleSystem#maxSpeed"), 20) / 3600
			ps.minScale = Utils.getNoNil(getXMLFloat(self.xmlFile, wheelKey .. ".wheelParticleSystem#minScale"), 0.1)
			ps.maxScale = Utils.getNoNil(getXMLFloat(self.xmlFile, wheelKey .. ".wheelParticleSystem#maxScale"), 1)
			ps.direction = Utils.getNoNil(getXMLFloat(self.xmlFile, wheelKey .. ".wheelParticleSystem#direction"), 0)
			ps.onlyActiveOnGroundContact = Utils.getNoNil(getXMLBool(self.xmlFile, wheelKey .. ".wheelParticleSystem#onlyActiveOnGroundContact"), true)

			return ps
		end

		return nil
	end

	for name, _ in pairs(wheel.driveGroundParticleStates) do
		local particleSystem = g_particleSystemManager:getParticleSystem(FillType.UNKNOWN, name)

		if particleSystem ~= nil then
			local wheelParticles = {}

			table.insert(wheelParticles, getParticleSystem(xmlFile, key, wheel, particleSystem))

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in ipairs(wheel.additionalWheels) do
					if additionalWheel.hasParticles then
						if additionalWheel.driveGroundParticleSystems == nil then
							additionalWheel.driveGroundParticleSystems = {}
						end

						additionalWheel.driveGroundParticleSystems[name] = getParticleSystem(xmlFile, additionalWheel.key, additionalWheel, particleSystem)
					end
				end
			end

			wheel.driveGroundParticleSystems[name] = wheelParticles
		end
	end
end

function Wheels:loadWheelDataFromExternalXML(wheel, xmlFilename, wheelConfigId)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = loadXMLFile("TempConfig", xmlFilename)

	if xmlFile ~= nil then
		local defaultKey = "wheel.default"

		self:loadWheelData(wheel, xmlFile, defaultKey)

		if wheelConfigId ~= "default" then
			local i = 0
			local wheelConfigFound = false

			while true do
				local configKey = string.format("wheel.configurations.configuration(%d)", i)

				if not hasXMLProperty(xmlFile, configKey) then
					break
				end

				if getXMLString(xmlFile, configKey .. "#id") == wheelConfigId then
					wheelConfigFound = true

					self:loadWheelData(wheel, xmlFile, configKey)

					break
				end

				i = i + 1
			end

			if not wheelConfigFound then
				g_logManager:xmlError(xmlFilename, "WheelConfigId '%s' not found!", wheelConfigId)

				return false
			end
		end

		delete(xmlFile)
	else
		g_logManager:xmlError(xmlFilename, "Unable to load xml file '%s'!", wheelConfigId)

		return false
	end

	return true
end

function Wheels:loadWheelData(wheel, xmlFile, configKey)
	local key = "nodeLeft"

	if not wheel.isLeft then
		key = "nodeRight"
	end

	wheel.radius = getXMLFloat(xmlFile, configKey .. ".physics#radius") or wheel.radius

	if wheel.radius == nil then
		g_logManager:xmlWarning(self.configFileName, "No radius defined for wheel '%s'! Using default value of 0.5!", configKey .. ".physics#radius")

		wheel.radius = 0.5
	end

	wheel.width = getXMLFloat(xmlFile, configKey .. ".physics#width") or wheel.width

	if wheel.width == nil then
		g_logManager:xmlWarning(self.configFileName, "No width defined for wheel '%s'! Using default value of 0.5!", configKey .. ".physics#width")

		wheel.width = 0.5
	end

	wheel.mass = getXMLFloat(xmlFile, configKey .. ".physics#mass") or wheel.mass or 0.1
	local tireTypeName = getXMLString(xmlFile, configKey .. ".tire#tireType")

	if tireTypeName ~= nil then
		local tireType = WheelsUtil.getTireType(tireTypeName)

		if tireType ~= nil then
			wheel.tireType = tireType
		else
			g_logManager:xmlWarning(self.configFileName, "Tire type '%s' not defined!", tireTypeName)
		end
	end

	wheel.frictionScale = getXMLFloat(xmlFile, configKey .. ".physics#frictionScale") or wheel.frictionScale
	wheel.maxLongStiffness = getXMLFloat(xmlFile, configKey .. ".physics#maxLongStiffness") or wheel.maxLongStiffness
	wheel.maxLatStiffness = getXMLFloat(xmlFile, configKey .. ".physics#maxLatStiffness") or wheel.maxLatStiffness
	wheel.maxLatStiffnessLoad = getXMLFloat(xmlFile, configKey .. ".physics#maxLatStiffnessLoad") or wheel.maxLatStiffnessLoad
	wheel.tireTrackAtlasIndex = getXMLInt(xmlFile, configKey .. ".tire#tireTrackAtlasIndex") or wheel.tireTrackAtlasIndex or 0
	wheel.widthOffset = getXMLFloat(xmlFile, configKey .. ".tire#widthOffset") or wheel.widthOffset or 0
	wheel.xOffset = getXMLFloat(xmlFile, configKey .. ".tire#xOffset") or wheel.xOffset or 0
	wheel.maxDeformation = getXMLFloat(xmlFile, configKey .. ".tire#maxDeformation") or wheel.maxDeformation or 0
	wheel.deformation = 0
	wheel.isCareWheel = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, configKey .. ".tire#isCareWheel"), wheel.isCareWheel), true)
	wheel.smoothGroundRadius = getXMLFloat(xmlFile, configKey .. ".physics#smoothGroundRadius") or math.max(0.6, wheel.width * 0.75)
	wheel.tireFilename = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".tire#filename", "", getXMLString, wheel.tireFilename)
	wheel.tireIsInverted = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".tire#isInverted", "", getXMLBool, wheel.tireIsInverted)
	wheel.tireNodeStr = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".tire#node", "", getXMLString, nil) or XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".tire#" .. key, "", getXMLString, wheel.tireNodeStr)
	wheel.outerRimFilename = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".outerRim#filename", "", getXMLString, wheel.outerRimFilename)
	wheel.outerRimNodeStr = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".outerRim#node", "", getXMLString, wheel.outerRimNodeStr) or "0|0"
	wheel.outerRimWidthAndDiam = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".outerRim#widthAndDiam", "", getXMLString, wheel.outerRimWidthAndDiam, StringUtil.getVectorNFromString, 2)
	wheel.outerRimScale = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".outerRim#scale", "", getXMLString, wheel.outerRimScale, StringUtil.getVectorNFromString, 3)
	wheel.innerRimFilename = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#filename", "", getXMLString, wheel.innerRimFilename)
	wheel.innerRimNodeStr = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#node", "", getXMLString, nil) or XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#" .. key, "", getXMLString, wheel.innerRimNodeStr)
	wheel.innerRimWidthAndDiam = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#widthAndDiam", "", getXMLString, wheel.innerRimWidthAndDiam, StringUtil.getVectorNFromString, 2)
	wheel.innerRimOffset = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#offset", "", getXMLFloat, wheel.innerRimOffset) or 0
	wheel.innerRimScale = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".innerRim#scale", "", getXMLString, wheel.innerRimScale, StringUtil.getVectorNFromString, 3)
	wheel.additionalFilename = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#filename", "", getXMLString, wheel.additionalFilename)
	wheel.additionalNodeStr = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#node", "", getXMLString, nil) or XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#" .. key, "", getXMLString, wheel.additionalNodeStr)
	wheel.additionalOffset = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#offset", "", getXMLFloat, wheel.additionalOffset) or 0
	wheel.additionalScale = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#scale", "", getXMLString, wheel.additionalScale, StringUtil.getVectorNFromString, 3)
	wheel.additionalMass = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#mass", "", getXMLFloat, wheel.additionalMass) or 0
	wheel.additionalWidthAndDiam = XMLUtil.getXMLOverwrittenValue(xmlFile, configKey, ".additional#widthAndDiam", "", getXMLString, wheel.additionalWidthAndDiam, StringUtil.getVectorNFromString, 2)
end

function Wheels:loadWheelsSteeringDataFromXML(xmlFile, ackermannSteeringIndex)
	local spec = self.spec_wheels
	local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, ackermannSteeringIndex, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering", "vehicle.ackermannSteering", "ackermann")
	spec.steeringCenterNode = nil
	local rotSpeed = getXMLFloat(xmlFile, key .. "#rotSpeed")
	local rotMax = getXMLFloat(xmlFile, key .. "#rotMax")
	local centerX, centerZ = nil
	local rotCenterWheel1 = getXMLInt(xmlFile, key .. "#rotCenterWheel1")

	if rotCenterWheel1 ~= nil and spec.wheels[rotCenterWheel1] ~= nil then
		local wheel = spec.wheels[rotCenterWheel1]
		centerX, _, centerZ = localToLocal(wheel.node, self.components[1].node, wheel.positionX, wheel.positionY, wheel.positionZ)
		local rotCenterWheel2 = getXMLInt(xmlFile, key .. "#rotCenterWheel2")

		if rotCenterWheel2 ~= nil and spec.wheels[rotCenterWheel2] ~= nil then
			local wheel2 = spec.wheels[rotCenterWheel2]
			local x, _, z = localToLocal(wheel2.node, self.components[1].node, wheel2.positionX, wheel2.positionY, wheel2.positionZ)
			centerZ = 0.5 * (centerZ + z)
			centerX = 0.5 * (centerX + x)
		end
	else
		local centerNode, _ = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#rotCenterNode"), self.i3dMappings)

		if centerNode ~= nil then
			centerX, _, centerZ = localToLocal(centerNode, self.components[1].node, 0, 0, 0)
			spec.steeringCenterNode = centerNode
		else
			local p = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#rotCenter", 2))

			if p ~= nil then
				centerX = p[1]
				centerZ = p[2]
			end
		end
	end

	if spec.steeringCenterNode == nil then
		spec.steeringCenterNode = createTransformGroup("steeringCenterNode")

		link(self.components[1].node, spec.steeringCenterNode)

		if centerX ~= nil and centerZ ~= nil then
			setTranslation(spec.steeringCenterNode, centerX, 0, centerZ)
		end
	end

	if rotSpeed ~= nil and rotMax ~= nil and centerX ~= nil then
		rotSpeed = math.abs(math.rad(rotSpeed))
		rotMax = math.abs(math.rad(rotMax))
		local maxTurningRadius = 0
		local maxTurningRadiusWheel = 0

		for i, wheel in ipairs(spec.wheels) do
			if wheel.rotSpeed ~= 0 then
				local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
				local turningRadius = math.abs(diffZ) / math.tan(rotMax) + math.abs(diffX)

				if maxTurningRadius <= turningRadius then
					maxTurningRadius = turningRadius
					maxTurningRadiusWheel = i
				end
			end
		end

		self.maxRotation = math.max(Utils.getNoNil(self.maxRotation, 0), rotMax)
		self.maxTurningRadius = maxTurningRadius
		self.maxTurningRadiusWheel = maxTurningRadiusWheel
		self.wheelSteeringDuration = rotMax / rotSpeed

		if maxTurningRadiusWheel > 0 then
			for _, wheel in ipairs(spec.wheels) do
				if wheel.rotSpeed ~= 0 then
					local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
					local rotMaxI = math.atan(diffZ / (maxTurningRadius - diffX))
					local rotMinI = -math.atan(diffZ / (maxTurningRadius + diffX))
					local switchMaxMin = rotMaxI < rotMinI

					if switchMaxMin then
						rotMinI = rotMaxI
						rotMaxI = rotMinI
					end

					wheel.rotMax = rotMaxI
					wheel.rotMin = rotMinI
					wheel.rotSpeed = rotMaxI / self.wheelSteeringDuration
					wheel.rotSpeedNeg = -rotMinI / self.wheelSteeringDuration

					if switchMaxMin then
						wheel.rotSpeedNeg = -wheel.rotSpeed
						wheel.rotSpeed = -wheel.rotSpeedNeg
					end
				end
			end
		end
	end

	for _, wheel in ipairs(spec.wheels) do
		if wheel.rotSpeed ~= 0 then
			if wheel.rotMax >= 0 == (wheel.rotSpeed >= 0) then
				self.maxRotTime = math.max(wheel.rotMax / wheel.rotSpeed, self.maxRotTime)
			end

			if wheel.rotMin >= 0 == (wheel.rotSpeed >= 0) then
				self.maxRotTime = math.max(wheel.rotMin / wheel.rotSpeed, self.maxRotTime)
			end

			local rotSpeedNeg = wheel.rotSpeedNeg

			if rotSpeedNeg == nil then
				rotSpeedNeg = wheel.rotSpeed
			end

			if wheel.rotMax >= 0 ~= (rotSpeedNeg >= 0) then
				self.minRotTime = math.min(wheel.rotMax / rotSpeedNeg, self.minRotTime)
			end

			if wheel.rotMin >= 0 ~= (rotSpeedNeg >= 0) then
				self.minRotTime = math.min(wheel.rotMin / rotSpeedNeg, self.minRotTime)
			end
		end

		wheel.fenderRotMax = Utils.getNoNilRad(wheel.fenderRotMax, wheel.rotMax)
		wheel.fenderRotMin = Utils.getNoNilRad(wheel.fenderRotMin, wheel.rotMin)
		wheel.steeringNodeMaxRot = math.max(wheel.rotMax, wheel.steeringAxleRotMax)
		wheel.steeringNodeMinRot = math.min(wheel.rotMin, wheel.steeringAxleRotMin)

		if wheel.rotSpeedLimit ~= nil then
			wheel.rotSpeedDefault = wheel.rotSpeed
			wheel.rotSpeedNegDefault = wheel.rotSpeedNeg
			wheel.currentRotSpeedAlpha = 1
		end
	end
end

function Wheels:loadNonPhysicalWheelFromXML(dynamicallyLoadedWheel, xmlFile, key)
	dynamicallyLoadedWheel.linkNode = I3DUtil.indexToObject(self.components, Utils.getNoNil(getXMLString(xmlFile, key .. "#linkNode"), "0>"), self.i3dMappings)
	local wheelXmlFilename = getXMLString(xmlFile, key .. "#filename")

	if wheelXmlFilename ~= nil and wheelXmlFilename ~= "" then
		local wheelConfigId = Utils.getNoNil(getXMLString(xmlFile, key .. "#configId"), "default")
		dynamicallyLoadedWheel.isLeft = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLeft"), true)
		dynamicallyLoadedWheel.tireIsInverted = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isInverted"), false)
		dynamicallyLoadedWheel.xRotOffset = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. "#xRotOffset"), 0)
		local colorStr = getXMLString(xmlFile, key .. "#color")

		if colorStr ~= nil then
			dynamicallyLoadedWheel.color = ConfigurationUtil.getColorFromString(colorStr)
		end

		local additionalColorStr = getXMLString(xmlFile, key .. "#additionalColor")

		if additionalColorStr ~= nil then
			dynamicallyLoadedWheel.additionalColor = ConfigurationUtil.getColorFromString(additionalColorStr)
		end

		self:loadWheelDataFromExternalXML(dynamicallyLoadedWheel, wheelXmlFilename, wheelConfigId)
		self:finalizeWheel(dynamicallyLoadedWheel)

		return true
	end

	return false
end

function Wheels:deleteVisualWheel(wheel)
	if wheel.tireFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(wheel.tireFilename, self.baseDirectory, true)
	end

	if wheel.innerRimFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(wheel.innerRimFilename, self.baseDirectory, true)
	end

	if wheel.outerRimFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(wheel.outerRimFilename, self.baseDirectory, true)
	end

	if wheel.additionalFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(wheel.additionalFilename, self.baseDirectory, true)
	end

	if wheel.connector ~= nil then
		g_i3DManager:releaseSharedI3DFile(wheel.connector.filename, self.baseDirectory, true)
	end
end

function Wheels:getIsVersatileYRotActive(wheel)
	return true
end

function Wheels:getWheelFromWheelIndex(wheelIndex)
	return self.spec_wheels.wheels[wheelIndex]
end

function Wheels:getWheels()
	return self.spec_wheels.wheels
end

function Wheels:destroyFruitArea(x0, z0, x1, z1, x2, z2)
	FSDensityMapUtil.updateWheelDestructionArea(x0, z0, x1, z1, x2, z2)
end

function Wheels:brake(brakePedal)
	local spec = self.spec_wheels
	spec.brakePedal = brakePedal

	for _, wheel in pairs(spec.wheels) do
		WheelsUtil.updateWheelPhysics(self, wheel, spec.brakePedal, 0)
	end

	SpecializationUtil.raiseEvent(self, "onBrake", spec.brakePedal)
end

function Wheels:getBrakeForce()
	return 0
end

function Wheels:updateWheelChocksPosition(isInParkingPosition, continueUpdate)
	local spec = self.spec_wheels

	if spec.wheelChocks ~= nil then
		for _, wheelChock in pairs(spec.wheelChocks) do
			wheelChock.wheel.updateWheelChock = continueUpdate
			isInParkingPosition = Utils.getNoNil(isInParkingPosition, wheelChock.isParked)

			self:updateWheelChockPosition(wheelChock, isInParkingPosition)
		end
	end
end

function Wheels:updateWheelChockPosition(wheelChock, isInParkingPosition)
	if isInParkingPosition then
		if wheelChock.parkingNode ~= nil then
			setTranslation(wheelChock.node, 0, 0, 0)
			setRotation(wheelChock.node, 0, 0, 0)
			link(wheelChock.parkingNode, wheelChock.node)
			setVisibility(wheelChock.node, true)
		else
			setVisibility(wheelChock.node, false)
		end
	else
		setVisibility(wheelChock.node, true)

		local wheel = wheelChock.wheel
		local radiusChockHeightOffset = wheel.radius - wheel.deformation - wheelChock.height
		local angle = math.acos(radiusChockHeightOffset / wheel.radius)
		local zWheelIntersection = wheel.radius * math.sin(angle)
		local zChockOffset = -zWheelIntersection - wheelChock.zOffset

		link(wheel.node, wheelChock.node)

		local _, yRot, _ = localRotationToLocal(getParent(wheel.repr), wheel.node, getRotation(wheel.repr))

		if wheelChock.isInverted then
			yRot = yRot + math.pi
		end

		setRotation(wheelChock.node, 0, yRot, 0)

		local dirX, dirY, dirZ = localDirectionToLocal(wheelChock.node, wheel.node, 0, 0, 1)
		local normX, normY, normZ = localDirectionToLocal(wheelChock.node, wheel.node, 1, 0, 0)
		local posX, posY, posZ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
		posX = posX + normX * wheelChock.offset[1] + dirX * (zChockOffset + wheelChock.offset[3])
		posY = posY + normY * wheelChock.offset[1] + dirY * (zChockOffset + wheelChock.offset[3]) - wheel.radius + wheel.deformation + wheelChock.offset[2]
		posZ = posZ + normZ * wheelChock.offset[1] + dirZ * (zChockOffset + wheelChock.offset[3])

		setTranslation(wheelChock.node, posX, posY, posZ)
	end

	if wheelChock.parkedNode ~= nil then
		setVisibility(wheelChock.parkedNode, isInParkingPosition)
	end

	if wheelChock.linkedNode ~= nil then
		setVisibility(wheelChock.linkedNode, not isInParkingPosition)
	end

	return true
end

function Wheels:onLeaveVehicle()
	local spec = self.spec_wheels

	if self.isServer and self.isAddedToPhysics then
		for _, wheel in pairs(spec.wheels) do
			setWheelShapeProps(wheel.node, wheel.wheelShape, 0, self:getBrakeForce() * wheel.brakeFactor, wheel.steeringAngle, wheel.rotationDamping)
		end
	end
end

function Wheels:onPreAttach()
	self:updateWheelChocksPosition(true, false)
end

function Wheels:onPostDetach()
	self:updateWheelChocksPosition(false, true)
end

function Wheels.loadBrandName(xmlFile, key, baseDir, customEnvironment, isMod, configItem)
	local name = getXMLString(xmlFile, key .. "#brand")
	configItem.wheelBrandKey = key

	if name ~= nil then
		local brandDesc = g_brandManager:getBrandByName(name)

		if brandDesc ~= nil then
			configItem.wheelBrandName = brandDesc.title
		else
			g_logManager:warning("Wheel brand '%s' is not defined for '%s'!", name, key)
		end
	end
end

function Wheels.loadedBrandNames(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	local hasWheelBrands = false

	for _, item in ipairs(configurationItems) do
		if item.wheelBrandName ~= nil then
			hasWheelBrands = true

			break
		end
	end

	if hasWheelBrands then
		for _, item in ipairs(configurationItems) do
			if item.wheelBrandName == nil then
				g_logManager:xmlWarning(storeItem.xmlFilename, "Wheel brand missing for wheel configuration '%s'!", item.wheelBrandKey)
			end
		end
	end
end

function Wheels.getBrands(items)
	local brands = {}
	local addedBrands = {}

	for _, item in ipairs(items) do
		if item.wheelBrandName ~= nil and addedBrands[item.wheelBrandName] == nil then
			table.insert(brands, item.wheelBrandName)

			addedBrands[item.wheelBrandName] = true
		end
	end

	return brands
end

function Wheels.getWheelsByBrand(items, brand)
	local wheels = {}

	for _, item in ipairs(items) do
		if item.wheelBrandName == brand then
			table.insert(wheels, item)
		end
	end

	return wheels
end
