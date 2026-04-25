source("dataS/scripts/vehicles/specializations/events/BaleLoaderStateEvent.lua")

BaleLoader = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end,
	GRAB_MOVE_UP = 1,
	GRAB_MOVE_DOWN = 2,
	GRAB_DROP_BALE = 3,
	EMPTY_NONE = 1,
	EMPTY_TO_WORK = 2,
	EMPTY_ROTATE_PLATFORM = 3,
	EMPTY_ROTATE1 = 4,
	EMPTY_CLOSE_GRIPPERS = 5,
	EMPTY_HIDE_PUSHER1 = 6,
	EMPTY_HIDE_PUSHER2 = 7,
	EMPTY_ROTATE2 = 8,
	EMPTY_WAIT_TO_DROP = 9,
	EMPTY_WAIT_TO_SINK = 10,
	EMPTY_SINK = 11,
	EMPTY_CANCEL = 12,
	EMPTY_WAIT_TO_REDO = 13,
	CHANGE_DROP_BALES = 1,
	CHANGE_SINK = 2,
	CHANGE_EMPTY_REDO = 3,
	CHANGE_EMPTY_START = 4,
	CHANGE_EMPTY_CANCEL = 5,
	CHANGE_MOVE_TO_WORK = 6,
	CHANGE_MOVE_TO_TRANSPORT = 7,
	CHANGE_GRAB_BALE = 8,
	CHANGE_GRAB_MOVE_UP = 9,
	CHANGE_GRAB_DROP_BALE = 10,
	CHANGE_GRAB_MOVE_DOWN = 11,
	CHANGE_FRONT_PUSHER = 12,
	CHANGE_ROTATE_PLATFORM = 13,
	CHANGE_EMPTY_ROTATE_PLATFORM = 14,
	CHANGE_EMPTY_ROTATE1 = 15,
	CHANGE_EMPTY_CLOSE_GRIPPERS = 16,
	CHANGE_EMPTY_HIDE_PUSHER1 = 17,
	CHANGE_EMPTY_HIDE_PUSHER2 = 18,
	CHANGE_EMPTY_ROTATE2 = 19,
	CHANGE_EMPTY_WAIT_TO_DROP = 20,
	CHANGE_EMPTY_STATE_NIL = 21,
	CHANGE_EMPTY_WAIT_TO_REDO = 22,
	CHANGE_BUTTON_EMPTY = 23,
	CHANGE_BUTTON_EMPTY_ABORT = 24,
	CHANGE_BUTTON_WORK_TRANSPORT = 25
}

function BaleLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleLoader.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "getBaleGrabberDropBaleAnimName", BaleLoader.getBaleGrabberDropBaleAnimName)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabbingAllowed", BaleLoader.getIsBaleGrabbingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "pickupBale", BaleLoader.pickupBale)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleLoader.baleGrabberTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "mountDynamicBale", BaleLoader.mountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "unmountDynamicBale", BaleLoader.unmountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "getLoadedBales", BaleLoader.getLoadedBales)
	SpecializationUtil.registerFunction(vehicleType, "startAutomaticBaleUnloading", BaleLoader.startAutomaticBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingInProgress", BaleLoader.getIsAutomaticBaleUnloadingInProgress)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingAllowed", BaleLoader.getIsAutomaticBaleUnloadingAllowed)
end

function BaleLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleLoader.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", BaleLoader.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", BaleLoader.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", BaleLoader.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", BaleLoader.getAreControlledActionsAllowed)
end

function BaleLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BaleLoader)
end

function BaleLoader:onLoad(savegame)
	local spec = self.spec_baleLoader

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleloaderTurnedOnScrollers.baleloaderTurnedOnScroller", "vehicle.baleLoader.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleGrabber", "vehicle.baleLoader.grabber")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.balePlaces", "vehicle.baleLoader.balePlaces")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.grabParticleSystem", "vehicle.baleLoader.grabber.grabParticleSystem")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#pickupRange", "vehicle.baleLoader.grabber#pickupRange")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleTypes", "vehicle.baleLoader.baleTypes")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textTransportPosition", "vehicle.baleLoader.texts#transportPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textOperatingPosition", "vehicle.baleLoader.texts#operatingPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textUnload", "vehicle.baleLoader.texts#unload")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textTilting", "vehicle.baleLoader.texts#tilting")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textLowering", "vehicle.baleLoader.texts#lowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textLowerPlattform", "vehicle.baleLoader.texts#lowerPlattform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textAbortUnloading", "vehicle.baleLoader.texts#abortUnloading")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#textUnloadHere", "vehicle.baleLoader.texts#unloadHere")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#rotatePlatformAnimName", "vehicle.baleLoader.animations#rotatePlatform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#rotatePlatformBackAnimName", "vehicle.baleLoader.animations#rotatePlatformBack")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleLoader#rotatePlatformEmptyAnimName", "vehicle.baleLoader.animations#rotatePlatformEmpty")

	local baseKey = "vehicle.baleLoader"
	spec.balesToLoad = {}
	spec.balesToMount = {}
	spec.isInWorkPosition = false
	spec.grabberIsMoving = false
	spec.synchronizeFillLevel = false
	spec.synchronizeFullFillLevel = true
	spec.rotatePlatformDirection = 0
	spec.frontBalePusherDirection = 0
	spec.emptyState = BaleLoader.EMPTY_NONE
	spec.itemsToSave = {}
	spec.texts = {
		transportPosition = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#transportPosition"), "action_baleloaderTransportPosition"),
		operatingPosition = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#operatingPosition"), "action_baleloaderOperatingPosition"),
		unload = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#unload"), "action_baleloaderUnload"),
		tilting = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#tilting"), "info_baleloaderTiltingTable"),
		lowering = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#lowering"), "info_baleloaderLoweringTable"),
		lowerPlattform = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#lowerPlattform"), "action_baleloaderLowerPlatform"),
		abortUnloading = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#abortUnloading"), "action_baleloaderAbortUnloading"),
		unloadHere = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".texts#unloadHere"), "action_baleloaderUnloadHere")
	}
	spec.animations = {
		rotatePlatform = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".animations#rotatePlatform"), "rotatePlatform"),
		rotatePlatformBack = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".animations#rotatePlatformBack"), "rotatePlatform"),
		rotatePlatformEmpty = Utils.getNoNil(getXMLString(self.xmlFile, baseKey .. ".animations#rotatePlatformEmpty"), "rotatePlatform"),
		grabberDropBaleReverseSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. ".animations#grabberDropBaleReverseSpeed"), 5),
		grabberDropToWork = getXMLString(self.xmlFile, baseKey .. ".animations#grabberDropToWork"),
		moveBalePlacesEmptySpeed = getXMLFloat(self.xmlFile, baseKey .. ".animations#moveBalePlacesEmptySpeed") or 1
	}
	spec.moveBalePlacesAfterRotatePlatform = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#moveBalePlacesAfterRotatePlatform"), false)
	spec.moveBalePlacesMaxGrabberTime = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#moveBalePlacesMaxGrabberTime"), math.huge)
	spec.alwaysMoveBalePlaces = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#alwaysMoveBalePlaces"), false)
	spec.transportPositionAfterUnloading = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#transportPositionAfterUnloading"), true)
	spec.useBalePlaceAsLoadPosition = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#useBalePlaceAsLoadPosition"), false)
	spec.balePlaceOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#balePlaceOffset"), 0)
	spec.keepBaleRotationDuringLoad = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#keepBaleRotationDuringLoad"), false)
	spec.automaticUnloading = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#automaticUnloading"), false)
	spec.resetEmptyRotateAnimation = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#resetEmptyRotateAnimation"), true)
	spec.mountDynamic = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. ".dynamicMount#enabled"), false)
	spec.updateBaleJointNodePosition = {}
	spec.dynamicMountMinTransLimits = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, baseKey .. ".dynamicMount#minTransLimits"), 3)
	spec.dynamicMountMaxTransLimits = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, baseKey .. ".dynamicMount#maxTransLimits"), 3)
	spec.isBaleWeightDirty = false
	spec.fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, baseKey .. "#fillUnitIndex"), 1)
	spec.baleGrabber = {
		grabNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. ".grabber#grabNode"), self.i3dMappings),
		pickupRange = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. ".grabber#pickupRange"), 3),
		balesInTrigger = {},
		trigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. ".grabber#triggerNode"), self.i3dMappings)
	}

	if spec.baleGrabber.trigger ~= nil then
		addTrigger(spec.baleGrabber.trigger, "baleGrabberTriggerCallback", self)
	else
		g_logManager:xmlError(self.configFileName, "Bale grabber needs a valid trigger!")
	end

	spec.startBalePlace = {
		bales = {},
		node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. ".balePlaces#startBalePlace"), self.i3dMappings)
	}

	if spec.startBalePlace.node ~= nil then
		spec.startBalePlace.numOfPlaces = getNumOfChildren(spec.startBalePlace.node)

		if spec.startBalePlace.numOfPlaces == 0 then
			spec.startBalePlace.node = nil
		else
			spec.startBalePlace.origRot = {}
			spec.startBalePlace.origTrans = {}

			for i = 1, spec.startBalePlace.numOfPlaces do
				local node = getChildAt(spec.startBalePlace.node, i - 1)
				spec.startBalePlace.origRot[i] = {
					getRotation(node)
				}
				spec.startBalePlace.origTrans[i] = {
					getTranslation(node)
				}
			end
		end
	end

	spec.startBalePlace.count = 0
	spec.currentBalePlace = 1
	spec.balePlaces = {}
	local i = 0

	while true do
		local key = string.format("%s.balePlaces.balePlace(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#node"), self.i3dMappings)
		local collision = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key .. "#collision"), self.i3dMappings)

		if node ~= nil then
			local entry = {
				node = node
			}

			if collision ~= nil then
				entry.collision = collision

				setIsCompoundChild(entry.collision, false)
			end

			table.insert(spec.balePlaces, entry)
		end

		i = i + 1
	end

	if self.isClient then
		local grabParticleSystem = {}
		local psName = baseKey .. ".grabber.grabParticleSystem"

		if ParticleUtil.loadParticleSystem(self.xmlFile, grabParticleSystem, psName, self.components, false, nil, self.baseDirectory) then
			spec.grabParticleSystem = grabParticleSystem
			spec.grabParticleSystemDisableTime = 0
			spec.grabParticleSystemDisableDuration = Utils.getNoNil(getXMLFloat(self.xmlFile, psName .. "#disableDuration"), 0.6) * 1000
		end

		spec.samples = {
			grab = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "grab", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			emptyRotate = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "emptyRotate", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.allowedBaleTypes = {}
	i = 0

	while true do
		local key = string.format("%s.baleTypes.baleType(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local minBaleDiameter = getXMLFloat(self.xmlFile, key .. "#minBaleDiameter")
		local maxBaleDiameter = getXMLFloat(self.xmlFile, key .. "#maxBaleDiameter")
		local minBaleWidth = getXMLFloat(self.xmlFile, key .. "#minBaleWidth")
		local maxBaleWidth = getXMLFloat(self.xmlFile, key .. "#maxBaleWidth")
		local minBaleHeight = getXMLFloat(self.xmlFile, key .. "#minBaleHeight")
		local maxBaleHeight = getXMLFloat(self.xmlFile, key .. "#maxBaleHeight")
		local minBaleLength = getXMLFloat(self.xmlFile, key .. "#minBaleLength")
		local maxBaleLength = getXMLFloat(self.xmlFile, key .. "#maxBaleLength")

		if minBaleDiameter ~= nil and maxBaleDiameter ~= nil and minBaleWidth ~= nil and maxBaleWidth ~= nil then
			table.insert(spec.allowedBaleTypes, {
				minBaleDiameter = MathUtil.round(minBaleDiameter, 2),
				maxBaleDiameter = MathUtil.round(maxBaleDiameter, 2),
				minBaleWidth = MathUtil.round(minBaleWidth, 2),
				maxBaleWidth = MathUtil.round(maxBaleWidth, 2)
			})
		elseif minBaleWidth ~= nil and maxBaleWidth ~= nil and minBaleHeight ~= nil and maxBaleHeight ~= nil and minBaleLength ~= nil and maxBaleLength ~= nil then
			table.insert(spec.allowedBaleTypes, {
				minBaleWidth = MathUtil.round(minBaleWidth, 2),
				maxBaleWidth = MathUtil.round(maxBaleWidth, 2),
				minBaleHeight = MathUtil.round(minBaleHeight, 2),
				maxBaleHeight = MathUtil.round(maxBaleHeight, 2),
				minBaleLength = MathUtil.round(minBaleLength, 2),
				maxBaleLength = MathUtil.round(maxBaleLength, 2)
			})
		end

		i = i + 1
	end

	spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
	spec.showBaleNotSupportedWarning = false
	spec.automaticUnloadingInProgress = false
	spec.lastPickupAutomatedUnloadingDelayTime = 15000
	spec.lastPickupTime = -spec.lastPickupAutomatedUnloadingDelayTime
end

function BaleLoader:onPostLoad(savegame)
	if savegame ~= nil then
		local spec = self.spec_baleLoader

		if Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. ".baleLoader#isInWorkPosition"), false) then
			if not spec.isInWorkPosition then
				spec.grabberIsMoving = true
				spec.isInWorkPosition = true

				BaleLoader.moveToWorkPosition(self, true)
			end
		else
			BaleLoader.moveToTransportPosition(self)
		end

		spec.currentBalePlace = 1
		spec.startBalePlace.count = 0
		local numBales = 0

		if not savegame.resetVehicles then
			local i = 0

			while true do
				local baleKey = savegame.key .. string.format(".baleLoader.bale(%d)", i)

				if not hasXMLProperty(savegame.xmlFile, baleKey) then
					break
				end

				local filename = getXMLString(savegame.xmlFile, baleKey .. "#filename")

				if filename ~= nil then
					filename = NetworkUtil.convertFromNetworkFilename(filename)
					local x, y, z = StringUtil.getVectorFromString(getXMLString(savegame.xmlFile, baleKey .. "#position"))
					local xRot, yRot, zRot = StringUtil.getVectorFromString(getXMLString(savegame.xmlFile, baleKey .. "#rotation"))
					local fillLevel = getXMLFloat(savegame.xmlFile, baleKey .. "#fillLevel")
					local balePlace = getXMLInt(savegame.xmlFile, baleKey .. "#balePlace")
					local helper = getXMLInt(savegame.xmlFile, baleKey .. "#helper")
					local farmId = getXMLInt(savegame.xmlFile, baleKey .. "#farmId")

					if balePlace == nil or balePlace > 0 and (x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil) or balePlace < 1 and helper == nil then
						print("Warning: Corrupt savegame, bale " .. filename .. " could not be loaded")
					else
						xRot = math.rad(xRot)
						yRot = math.rad(yRot)
						zRot = math.rad(zRot)
						local translation, rotation = nil

						if balePlace > 0 then
							translation = {
								x,
								y,
								z
							}
							rotation = {
								xRot,
								yRot,
								zRot
							}
						else
							translation = {
								0,
								0,
								0
							}
							rotation = {
								0,
								0,
								0
							}
						end

						local parentNode, bales = nil

						if balePlace < 1 then
							if spec.startBalePlace.node ~= nil and helper <= spec.startBalePlace.numOfPlaces then
								parentNode = getChildAt(spec.startBalePlace.node, helper - 1)

								if spec.startBalePlace.bales == nil then
									spec.startBalePlace.bales = {}
								end

								bales = spec.startBalePlace.bales
								spec.startBalePlace.count = spec.startBalePlace.count + 1
							end
						elseif balePlace <= table.getn(spec.balePlaces) then
							spec.currentBalePlace = math.max(spec.currentBalePlace, balePlace + 1)
							parentNode = spec.balePlaces[balePlace].node

							if spec.balePlaces[balePlace].bales == nil then
								spec.balePlaces[balePlace].bales = {}
							end

							bales = spec.balePlaces[balePlace].bales
						end

						if parentNode ~= nil then
							local attributes = {}

							Bale.loadExtraAttributesFromXMLFile(self, attributes, savegame.xmlFile, baleKey, savegame.resetVehicles)

							numBales = numBales + 1

							table.insert(spec.balesToLoad, {
								parentNode = parentNode,
								filename = filename,
								bales = bales,
								translation = translation,
								rotation = rotation,
								fillLevel = fillLevel,
								farmId = farmId,
								attributes = attributes
							})
						end
					end
				end

				i = i + 1
			end
		end

		BaleLoader.updateBalePlacesAnimations(self)

		for i, place in pairs(spec.balePlaces) do
			if place.collision ~= nil then
				if i <= numBales then
					setIsCompoundChild(place.collision, true)
				else
					setIsCompoundChild(place.collision, false)
				end
			end
		end
	end
end

function BaleLoader:onDelete()
	local spec = self.spec_baleLoader

	for _, balePlace in pairs(spec.balePlaces) do
		if balePlace.bales ~= nil then
			for _, baleServerId in pairs(balePlace.bales) do
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					if spec.mountDynamic then
						self:unmountDynamicBale(bale)
					else
						bale:unmount()
					end

					if self.isReconfigurating ~= nil and self.isReconfigurating then
						bale:delete()
					end
				end
			end
		end
	end

	for _, baleServerId in ipairs(spec.startBalePlace.bales) do
		local bale = NetworkUtil.getObject(baleServerId)

		if bale ~= nil then
			if spec.mountDynamic then
				self:unmountDynamicBale(bale)
			else
				bale:unmount()
			end

			if self.isReconfigurating ~= nil and self.isReconfigurating then
				bale:delete()
			end
		end
	end

	if spec.baleGrabber.currentBale ~= nil then
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			if spec.mountDynamic then
				self:unmountDynamicBale(bale)
			else
				bale:unmount()
			end
		end
	end

	if self.isClient then
		if spec.grabParticleSystem ~= nil then
			ParticleUtil.deleteParticleSystem(spec.grabParticleSystem)
		end

		for i, sample in pairs(spec.samples) do
			g_soundManager:deleteSample(sample)
		end
	end

	if spec.baleGrabber.trigger ~= nil then
		removeTrigger(spec.baleGrabber.trigger)
	end

	g_animationManager:deleteAnimations(spec.animationNodes)
end

function BaleLoader:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_baleLoader

	setXMLBool(xmlFile, key .. "#isInWorkPosition", spec.isInWorkPosition)

	local baleIndex = 0

	for i, balePlace in pairs(spec.balePlaces) do
		if balePlace.bales ~= nil then
			for _, baleServerId in pairs(balePlace.bales) do
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					local baleKey = string.format("%s.bale(%d)", key, baleIndex)

					bale:saveToXMLFile(xmlFile, baleKey)

					local startBaleEmpty = table.getn(spec.startBalePlace.bales) == 0
					local loadPlaceEmpty = self:getFillUnitFillLevel(spec.fillUnitIndex) % spec.startBalePlace.numOfPlaces ~= 0
					local lastItem = math.floor(self:getFillUnitFillLevel(spec.fillUnitIndex) / spec.startBalePlace.numOfPlaces) + 1 == i
					local evenCapacity = self:getFillUnitCapacity(spec.fillUnitIndex) % 2 == 0

					if startBaleEmpty and loadPlaceEmpty and lastItem and evenCapacity then
						setXMLInt(xmlFile, baleKey .. "#balePlace", 0)
						setXMLInt(xmlFile, baleKey .. "#helper", 1)
					else
						setXMLInt(xmlFile, baleKey .. "#balePlace", i)
					end

					baleIndex = baleIndex + 1
				end
			end
		end
	end

	for i, baleServerId in ipairs(spec.startBalePlace.bales) do
		local bale = NetworkUtil.getObject(baleServerId)

		if bale ~= nil then
			local baleKey = string.format("%s.bale(%d)", key, baleIndex)

			bale:saveToXMLFile(xmlFile, baleKey)
			setXMLInt(xmlFile, baleKey .. "#balePlace", 0)
			setXMLInt(xmlFile, baleKey .. "#helper", i)

			baleIndex = baleIndex + 1
		end
	end

	if spec.baleGrabber.currentBale ~= nil then
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			bale:unmount()

			spec.baleGrabber.currentBaleIsUnmounted = true
		end
	end
end

function BaleLoader:onReadStream(streamId, connection)
	local spec = self.spec_baleLoader
	spec.isInWorkPosition = streamReadBool(streamId)
	spec.frontBalePusherDirection = streamReadIntN(streamId, 3)
	spec.rotatePlatformDirection = streamReadIntN(streamId, 3)

	if spec.isInWorkPosition then
		BaleLoader.moveToWorkPosition(self)
	end

	local emptyState = streamReadUIntN(streamId, 4)
	spec.currentBalePlace = streamReadInt8(streamId)

	if streamReadBool(streamId) then
		spec.baleGrabber.currentBale = NetworkUtil.readNodeObjectId(streamId)
		spec.balesToMount[spec.baleGrabber.currentBale] = {
			serverId = spec.baleGrabber.currentBale,
			linkNode = spec.baleGrabber.grabNode,
			trans = {
				0,
				0,
				0
			},
			rot = {
				0,
				0,
				0
			}
		}
	end

	spec.startBalePlace.count = streamReadUIntN(streamId, 3)

	for i = 1, spec.startBalePlace.count do
		local baleServerId = NetworkUtil.readNodeObjectId(streamId)
		local attachNode = getChildAt(spec.startBalePlace.node, i - 1)
		spec.balesToMount[baleServerId] = {
			serverId = baleServerId,
			linkNode = attachNode,
			trans = {
				0,
				0,
				0
			},
			rot = {
				0,
				0,
				0
			}
		}

		table.insert(spec.startBalePlace.bales, baleServerId)
	end

	for i = 1, table.getn(spec.balePlaces) do
		local balePlace = spec.balePlaces[i]
		local numBales = streamReadUIntN(streamId, 3)

		if numBales > 0 then
			balePlace.bales = {}

			for baleI = 1, numBales do
				local baleServerId = NetworkUtil.readNodeObjectId(streamId)
				local x = streamReadFloat32(streamId)
				local y = streamReadFloat32(streamId)
				local z = streamReadFloat32(streamId)

				table.insert(balePlace.bales, baleServerId)

				spec.balesToMount[baleServerId] = {
					serverId = baleServerId,
					linkNode = balePlace.node,
					trans = {
						x,
						y,
						z
					},
					rot = {
						0,
						0,
						0
					}
				}
			end
		end
	end

	BaleLoader.updateBalePlacesAnimations(self)

	if BaleLoader.EMPTY_TO_WORK <= emptyState then
		self:doStateChange(BaleLoader.CHANGE_EMPTY_START)
		AnimatedVehicle.updateAnimations(self, 99999999)

		if BaleLoader.EMPTY_ROTATE_PLATFORM <= emptyState then
			self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM)
			AnimatedVehicle.updateAnimations(self, 99999999)

			if BaleLoader.EMPTY_ROTATE1 <= emptyState then
				self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE1)
				AnimatedVehicle.updateAnimations(self, 99999999)

				if BaleLoader.EMPTY_CLOSE_GRIPPERS <= emptyState then
					self:doStateChange(BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS)
					AnimatedVehicle.updateAnimations(self, 99999999)

					if BaleLoader.EMPTY_HIDE_PUSHER1 <= emptyState then
						self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1)
						AnimatedVehicle.updateAnimations(self, 99999999)

						if BaleLoader.EMPTY_HIDE_PUSHER2 <= emptyState then
							self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2)
							AnimatedVehicle.updateAnimations(self, 99999999)

							if BaleLoader.EMPTY_ROTATE2 <= emptyState then
								self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE2)
								AnimatedVehicle.updateAnimations(self, 99999999)

								if BaleLoader.EMPTY_WAIT_TO_DROP <= emptyState then
									self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP)
									AnimatedVehicle.updateAnimations(self, 99999999)

									if emptyState == BaleLoader.EMPTY_CANCEL or emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
										self:doStateChange(BaleLoader.CHANGE_EMPTY_CANCEL)
										AnimatedVehicle.updateAnimations(self, 99999999)

										if emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
											self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO)
											AnimatedVehicle.updateAnimations(self, 99999999)
										end
									elseif emptyState == BaleLoader.EMPTY_WAIT_TO_SINK or emptyState == BaleLoader.EMPTY_SINK then
										self:doStateChange(BaleLoader.CHANGE_DROP_BALES)
										AnimatedVehicle.updateAnimations(self, 99999999)

										if emptyState == BaleLoader.EMPTY_SINK then
											self:doStateChange(BaleLoader.CHANGE_SINK)
											AnimatedVehicle.updateAnimations(self, 99999999)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	spec.emptyState = emptyState
end

function BaleLoader:onWriteStream(streamId, connection)
	local spec = self.spec_baleLoader

	streamWriteBool(streamId, spec.isInWorkPosition)
	streamWriteIntN(streamId, spec.frontBalePusherDirection, 3)
	streamWriteIntN(streamId, spec.rotatePlatformDirection, 3)
	streamWriteUIntN(streamId, spec.emptyState, 4)
	streamWriteInt8(streamId, spec.currentBalePlace)

	if streamWriteBool(streamId, spec.baleGrabber.currentBale ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, spec.baleGrabber.currentBale)
	end

	streamWriteUIntN(streamId, spec.startBalePlace.count, 3)

	for i = 1, spec.startBalePlace.count do
		local baleServerId = spec.startBalePlace.bales[i]

		NetworkUtil.writeNodeObjectId(streamId, baleServerId)
	end

	for i = 1, table.getn(spec.balePlaces) do
		local balePlace = spec.balePlaces[i]
		local numBales = 0

		if balePlace.bales ~= nil then
			numBales = table.getn(balePlace.bales)
		end

		streamWriteUIntN(streamId, numBales, 3)

		if balePlace.bales ~= nil then
			for baleI = 1, numBales do
				local baleServerId = balePlace.bales[baleI]
				local bale = NetworkUtil.getObject(baleServerId)
				local nodeId = bale.nodeId
				local x, y, z = getTranslation(nodeId)

				NetworkUtil.writeNodeObjectId(streamId, baleServerId)
				streamWriteFloat32(streamId, x)
				streamWriteFloat32(streamId, y)
				streamWriteFloat32(streamId, z)
			end
		end
	end
end

function BaleLoader:updateBalePlacesAnimations()
	local spec = self.spec_baleLoader

	if spec.startBalePlace.numOfPlaces < spec.currentBalePlace or spec.moveBalePlacesAfterRotatePlatform and spec.currentBalePlace > 1 then
		local delta = 1
		local numBalePlaces = table.getn(spec.balePlaces)

		if spec.moveBalePlacesAfterRotatePlatform and not spec.alwaysMoveBalePlaces and not spec.useBalePlaceAsLoadPosition then
			delta = 0
		end

		if spec.useBalePlaceAsLoadPosition then
			numBalePlaces = numBalePlaces - 1
			delta = delta + spec.balePlaceOffset
		end

		self:playAnimation("moveBalePlaces", 1, 0, true)
		self:setAnimationStopTime("moveBalePlaces", (spec.currentBalePlace - delta) / numBalePlaces)
		AnimatedVehicle.updateAnimations(self, 99999999)
	end

	if spec.startBalePlace.count >= 1 then
		self:playAnimation("balesToOtherRow", 20, nil, true)
		AnimatedVehicle.updateAnimations(self, 99999999)

		if spec.startBalePlace.numOfPlaces <= spec.startBalePlace.count then
			BaleLoader.rotatePlatform(self)
		end
	end
end

function BaleLoader:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if self.firstTimeRun then
		for k, v in pairs(spec.balesToLoad) do
			local baleObject = Bale:new(self.isServer, self.isClient)
			local x, y, z = unpack(v.translation)
			local rx, ry, rz = unpack(v.rotation)

			baleObject:load(v.filename, x, y, z, rx, ry, rz, v.fillLevel)

			baleObject.ownerFarmId = Utils.getNoNil(v.farmId, AccessHandler.EVERYONE)

			if spec.mountDynamic then
				self:mountDynamicBale(baleObject, v.parentNode)
			else
				baleObject:mount(self, v.parentNode, x, y, z, rx, ry, rz)
			end

			baleObject:applyExtraAttributes(v.attributes)
			baleObject:register()
			table.insert(v.bales, NetworkUtil.getObjectId(baleObject))

			spec.balesToLoad[k] = nil
		end

		for k, baleToMount in pairs(spec.balesToMount) do
			local bale = NetworkUtil.getObject(baleToMount.serverId)

			if bale ~= nil then
				local x, y, z = unpack(baleToMount.trans)
				local rx, ry, rz = unpack(baleToMount.rot)

				if spec.mountDynamic then
					self:mountDynamicBale(bale, baleToMount.linkNode)
				else
					bale:mount(self, baleToMount.linkNode, x, y, z, rx, ry, rz)
				end

				spec.balesToMount[k] = nil
			end
		end
	end

	if self.isClient and spec.grabParticleSystem ~= nil and spec.grabParticleSystemDisableTime ~= 0 and spec.grabParticleSystemDisableTime < g_currentMission.time then
		ParticleUtil.setEmittingState(spec.grabParticleSystem, false)

		spec.grabParticleSystemDisableTime = 0
	end

	if spec.grabberIsMoving and not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
		spec.grabberIsMoving = false
	end

	spec.showBaleNotSupportedWarning = false

	if self:getIsBaleGrabbingAllowed() and spec.baleGrabber.grabNode ~= nil and spec.baleGrabber.currentBale == nil then
		local nearestBale, nearestBaleType = BaleLoader.getBaleInRange(self, spec.baleGrabber.grabNode, spec.baleGrabber.balesInTrigger)

		if nearestBale ~= nil then
			if nearestBaleType == nil then
				spec.showBaleNotSupportedWarning = true
			elseif self.isServer then
				self:pickupBale(nearestBale, nearestBaleType)
			end
		end
	end

	if self.isServer then
		if spec.grabberMoveState ~= nil then
			if spec.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
				if not self:getIsAnimationPlaying("baleGrabberWorkToDrop") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_MOVE_UP), true, nil, self)
				end
			elseif spec.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
				if not self:getIsAnimationPlaying(spec.currentBaleGrabberDropBaleAnimName) then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_DROP_BALE), true, nil, self)
				end
			elseif spec.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN then
				local name = spec.animations.grabberDropToWork or "baleGrabberWorkToDrop"

				if not self:getIsAnimationPlaying(name) then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_MOVE_DOWN), true, nil, self)
					self:setAnimationTime(spec.currentBaleGrabberDropBaleAnimName, 0, false)
					self:setAnimationTime("baleGrabberWorkToDrop", 0, false)
				end
			end
		end

		if spec.frontBalePusherDirection ~= 0 and not self:getIsAnimationPlaying("frontBalePusher") then
			g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_FRONT_PUSHER), true, nil, self)
		end

		if spec.rotatePlatformDirection ~= 0 then
			local name = spec.animations.rotatePlatform

			if spec.rotatePlatformDirection < 0 then
				name = spec.animations.rotatePlatformBack
			end

			if not self:getIsAnimationPlaying(name) and not self:getIsAnimationPlaying("moveBalePlacesExtrasOnce") and not spec.moveBalePlacesDelayedMovement then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_ROTATE_PLATFORM), true, nil, self)
			end
		end

		if spec.emptyState ~= BaleLoader.EMPTY_NONE then
			if spec.emptyState == BaleLoader.EMPTY_TO_WORK then
				if not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
				if not self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE1), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE1 then
				if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
				if not self:getIsAnimationPlaying("closeGrippers") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
				if not self:getIsAnimationPlaying("emptyHidePusher1") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
				if self:getAnimationTime("moveBalePusherToEmpty") < 0.7 or not self:getIsAnimationPlaying("moveBalePusherToEmpty") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE2 then
				if not self:getIsAnimationPlaying("emptyRotate") then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_SINK then
				if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") and not self:getIsAnimationPlaying("emptyHidePusher1") and not self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_STATE_NIL), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying("emptyRotate") then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO), true, nil, self)
			end
		end
	end

	if spec.baleGrabber.currentBaleIsUnmounted then
		spec.baleGrabber.currentBaleIsUnmounted = false
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			if spec.mountDynamic then
				self:mountDynamicBale(bale, spec.baleGrabber.grabNode)
			else
				bale:mount(self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
			end
		end
	end
end

function BaleLoader:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]

		if actionEvent ~= nil then
			local showAction = false

			if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
				if spec.isInWorkPosition then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.transportPosition, self.customEnvironment))

					showAction = true
				else
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.operatingPosition, self.customEnvironment))

					showAction = true
				end
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
		end

		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]

		if actionEvent ~= nil then
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP)
		end

		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			local showAction = false

			if spec.emptyState == BaleLoader.EMPTY_NONE then
				if BaleLoader.getAllowsStartUnloading(self) then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.unload, self.customEnvironment))

					showAction = true
				end
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.unloadHere, self.customEnvironment))

				showAction = true
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.lowerPlattform, self.customEnvironment))

				showAction = true
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.texts.unload, self.customEnvironment))

				showAction = true
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
		end
	end

	if self.isServer then
		if spec.automaticUnloading or spec.automaticUnloadingInProgress then
			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				self:doStateChange(BaleLoader.CHANGE_BUTTON_EMPTY)
			end

			local isPlaying = self:getIsAnimationPlaying("releaseFrontplattform")

			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK and not isPlaying then
				self:doStateChange(BaleLoader.CHANGE_SINK)
			end
		end

		if spec.mountDynamic then
			local jointNodePositionChanged = false

			for i, jointNode in ipairs(spec.updateBaleJointNodePosition) do
				local x, y, z = getTranslation(jointNode.node)

				if jointNode.quaternion == nil then
					local qx, qy, qz, qw = getQuaternion(jointNode.node)
					jointNode.quaternion = {
						qx,
						qy,
						qz,
						qw
					}
				end

				jointNode.time = jointNode.time + dt

				if jointNode.time < 1000 then
					local qx = 0
					local qy = 0
					local qz = 0
					local qw = 1

					if math.abs(jointNode.quaternion[2]) > 0.5 then
						qx, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 1, 0, 0, jointNode.time / 1000)
					elseif math.abs(jointNode.quaternion[2]) < 0.5 then
						qx, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 0, 0, 1, jointNode.time / 1000)
					end

					setQuaternion(jointNode.node, qx, qy, qz, qw)

					jointNodePositionChanged = true
				end

				if math.abs(x) + math.abs(y) + math.abs(z) > 0.001 then
					local move = 0.0001 * dt

					local function moveValue(old, move)
						local limit = MathUtil.sign(old) > 0 and math.max or math.min

						return limit(old - MathUtil.sign(old) * move, 0)
					end

					setTranslation(jointNode.node, moveValue(x, move), moveValue(y, move), moveValue(z, move))

					jointNodePositionChanged = true
				elseif jointNode.time > 1000 then
					table.remove(spec.updateBaleJointNodePosition, i)
				end
			end

			local anyAnimationPlaying = false

			for name, _ in pairs(self.spec_animatedVehicle.animations) do
				if self:getIsAnimationPlaying(name) then
					anyAnimationPlaying = true
				end
			end

			if anyAnimationPlaying or jointNodePositionChanged or spec.isBaleWeightDirty then
				for _, balePlace in pairs(spec.balePlaces) do
					if balePlace.bales ~= nil then
						for _, baleServerId in pairs(balePlace.bales) do
							local bale = NetworkUtil.getObject(baleServerId)

							if bale ~= nil then
								if bale.dynamicMountJointIndex ~= nil then
									setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
								end

								if bale.backupMass == nil then
									local mass = getMass(bale.nodeId)

									if mass ~= 1 then
										bale.backupMass = mass

										setMass(bale.nodeId, 0.1)

										spec.isBaleWeightDirty = false
									end
								end
							end
						end
					end
				end

				for _, baleServerId in ipairs(spec.startBalePlace.bales) do
					local bale = NetworkUtil.getObject(baleServerId)

					if bale ~= nil then
						if bale.dynamicMountJointIndex ~= nil then
							setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
						end

						if bale.backupMass == nil then
							local mass = getMass(bale.nodeId)

							if mass ~= 1 then
								bale.backupMass = mass

								setMass(bale.nodeId, 0.1)

								spec.isBaleWeightDirty = false
							end
						end
					end
				end
			end
		end
	end

	if spec.moveBalePlacesDelayedMovement and self:getAnimationTime("baleGrabberWorkToDrop") < spec.moveBalePlacesMaxGrabberTime then
		spec.rotatePlatformDirection = -1

		self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)

		if spec.moveBalePlacesAfterRotatePlatform and (spec.currentBalePlace <= table.getn(spec.balePlaces) or spec.alwaysMoveBalePlaces) then
			self:playAnimation("moveBalePlaces", 1, (spec.currentBalePlace - 1) / table.getn(spec.balePlaces), true)
			self:setAnimationStopTime("moveBalePlaces", spec.currentBalePlace / table.getn(spec.balePlaces))
			self:playAnimation("moveBalePlacesExtrasOnce", 1, nil, true)
		end

		spec.moveBalePlacesDelayedMovement = nil
	end
end

function BaleLoader:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if spec.showBaleNotSupportedWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_baleNotSupported", self.customEnvironment), 2000)
	end
end

function BaleLoader:getBaleInRange(refNode, balesInTrigger)
	local spec = self.spec_baleLoader
	local nearestDistance = spec.baleGrabber.pickupRange
	local nearestBale, nearestBaleType = nil

	for bale, state in pairs(balesInTrigger) do
		if state ~= nil and state > 0 then
			local isValidBale = true

			for _, balePlace in pairs(spec.balePlaces) do
				if balePlace.bales ~= nil then
					for _, baleServerId in pairs(balePlace.bales) do
						local baleInPlace = NetworkUtil.getObject(baleServerId)

						if baleInPlace ~= nil and baleInPlace == bale then
							isValidBale = false
						end
					end
				end
			end

			for _, baleServerId in ipairs(spec.startBalePlace.bales) do
				local baleInPlace = NetworkUtil.getObject(baleServerId)

				if baleInPlace ~= nil and baleInPlace == bale then
					isValidBale = false
				end
			end

			if bale == nil or not entityExists(bale.nodeId) then
				isValidBale = false
			end

			if bale.dynamicMountJointIndex ~= nil then
				isValidBale = false
			end

			if not bale:getBaleSupportsBaleLoader() then
				isValidBale = false
			end

			if isValidBale then
				local distance = calcDistanceFrom(refNode, bale.nodeId)

				if distance < nearestDistance then
					local foundBaleType = nil

					for _, baleType in pairs(spec.allowedBaleTypes) do
						if baleType.minBaleDiameter ~= nil then
							if bale.baleDiameter ~= nil and bale.baleWidth ~= nil and baleType.minBaleDiameter <= bale.baleDiameter and bale.baleDiameter <= baleType.maxBaleDiameter and baleType.minBaleWidth <= bale.baleWidth and bale.baleWidth <= baleType.maxBaleWidth then
								foundBaleType = baleType

								break
							end
						elseif bale.baleWidth ~= nil and bale.baleHeight ~= nil and bale.baleLength ~= nil and baleType.minBaleWidth <= bale.baleWidth and bale.baleWidth <= baleType.maxBaleWidth and baleType.minBaleHeight <= bale.baleHeight and bale.baleHeight <= baleType.maxBaleHeight and baleType.minBaleLength <= bale.baleLength and bale.baleLength <= baleType.maxBaleLength then
							foundBaleType = baleType

							break
						end
					end

					if foundBaleType ~= nil or nearestBaleType == nil then
						if foundBaleType ~= nil then
							nearestDistance = distance
						end

						nearestBale = bale
						nearestBaleType = foundBaleType
					end
				end
			end
		end
	end

	return nearestBale, nearestBaleType
end

function BaleLoader:onDeactivate()
	local spec = self.spec_baleLoader

	if spec.grabParticleSystem ~= nil then
		ParticleUtil.setEmittingState(spec.grabParticleSystem, false)
	end
end

function BaleLoader:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_baleLoader
	spec.controlledAction = self:getRootVehicle().actionController:registerAction("baleLoaderWorkstate", nil, 4)

	spec.controlledAction:setCallback(self, BaleLoader.actionControllerEvent)

	local function finishedFunc(self)
		return self.spec_baleLoader.isInWorkPosition
	end

	spec.controlledAction:setFinishedFunctions(self, finishedFunc, true, false)
end

function BaleLoader:actionControllerEvent(direction)
	local spec = self.spec_baleLoader

	if direction > 0 and not spec.isInWorkPosition or direction < 0 and spec.isInWorkPosition then
		BaleLoader.actionEventWorkTransport(self)

		return true
	end
end

function BaleLoader:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_baleLoader

	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function BaleLoader:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_baleLoader

	if spec.fillUnitIndex == fillUnitIndex then
		local targetTime = self:getFillUnitFillLevel(spec.fillUnitIndex) / self:getFillUnitCapacity(spec.fillUnitIndex)
		local direction = 1

		if targetTime < self:getAnimationTime("baleLoaderFillLevel") then
			direction = -1
		end

		self:playAnimation("baleLoaderFillLevel", direction, self:getAnimationTime("baleLoaderFillLevel"), true)
		self:setAnimationStopTime("baleLoaderFillLevel", targetTime)

		spec.lastValidFillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex) - appliedDelta
	end
end

function BaleLoader:doStateChange(id, nearestBaleServerId)
	local spec = self.spec_baleLoader

	if id == BaleLoader.CHANGE_DROP_BALES then
		spec.currentBalePlace = 1

		for _, balePlace in pairs(spec.balePlaces) do
			if balePlace.bales ~= nil then
				for _, baleServerId in pairs(balePlace.bales) do
					local bale = NetworkUtil.getObject(baleServerId)

					if bale ~= nil then
						if spec.mountDynamic then
							self:unmountDynamicBale(bale)
						else
							bale:unmount()
						end

						if spec.baleGrabber.balesInTrigger[bale] ~= nil then
							spec.baleGrabber.balesInTrigger[bale] = nil
						end
					end

					spec.balesToMount[baleServerId] = nil
				end

				balePlace.bales = nil
			end
		end

		self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)

		for _, place in pairs(spec.balePlaces) do
			if place.collision ~= nil then
				setIsCompoundChild(place.collision, false)
			end
		end

		self:playAnimation("releaseFrontplattform", 1, nil, true)
		self:playAnimation("closeGrippers", -1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
	elseif id == BaleLoader.CHANGE_SINK then
		if spec.resetEmptyRotateAnimation then
			self:playAnimation("emptyRotate", -1, nil, true)
		end

		self:playAnimation("moveBalePlacesToEmpty", -spec.animations.moveBalePlacesEmptySpeed, nil, true)
		self:playAnimation("emptyHidePusher1", -1, nil, true)
		self:playAnimation(spec.animations.rotatePlatformEmpty, -1, nil, true)

		if not spec.isInWorkPosition then
			self:playAnimation("closeGrippers", 1, self:getAnimationTime("closeGrippers"), true)
		end

		spec.emptyState = BaleLoader.EMPTY_SINK
	elseif id == BaleLoader.CHANGE_EMPTY_REDO then
		self:playAnimation("emptyRotate", 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_ROTATE2
	elseif id == BaleLoader.CHANGE_EMPTY_START then
		if GS_IS_MOBILE_VERSION then
			if self:getRootVehicle():getActionControllerDirection() > 0 then
				spec.controlledAction.parent:startActionSequence()
			end

			spec.emptyState = BaleLoader.EMPTY_TO_WORK
		else
			BaleLoader.moveToWorkPosition(self)

			spec.emptyState = BaleLoader.EMPTY_TO_WORK
		end
	elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
		self:playAnimation("emptyRotate", -1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_CANCEL
	elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
		if spec.isInWorkPosition then
			spec.grabberIsMoving = true
			spec.isInWorkPosition = false

			g_animationManager:stopAnimations(spec.animationNodes)
			BaleLoader.moveToTransportPosition(self)
		end
	elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
		if not spec.isInWorkPosition then
			spec.grabberIsMoving = true
			spec.isInWorkPosition = true

			g_animationManager:startAnimations(spec.animationNodes)
			BaleLoader.moveToWorkPosition(self)
		end
	elseif id == BaleLoader.CHANGE_GRAB_BALE then
		local bale = NetworkUtil.getObject(nearestBaleServerId)
		spec.baleGrabber.currentBale = nearestBaleServerId

		if bale ~= nil then
			if spec.mountDynamic then
				self:mountDynamicBale(bale, spec.baleGrabber.grabNode)
			else
				bale:mount(self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
			end

			spec.balesToMount[nearestBaleServerId] = nil
		else
			spec.balesToMount[nearestBaleServerId] = {
				serverId = nearestBaleServerId,
				linkNode = spec.baleGrabber.grabNode,
				trans = {
					0,
					0,
					0
				},
				rot = {
					0,
					0,
					0
				}
			}
		end

		spec.grabberMoveState = BaleLoader.GRAB_MOVE_UP

		self:playAnimation("baleGrabberWorkToDrop", 1, nil, true)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)

		for i, place in pairs(spec.balePlaces) do
			if place.collision ~= nil then
				if i <= self:getFillUnitFillLevel(spec.fillUnitIndex) then
					setIsCompoundChild(place.collision, true)
				else
					setIsCompoundChild(place.collision, false)
				end
			end
		end

		if self.isClient then
			g_soundManager:playSample(spec.samples.grab)

			if spec.grabParticleSystem ~= nil then
				ParticleUtil.setEmittingState(spec.grabParticleSystem, true)

				spec.grabParticleSystemDisableTime = g_currentMission.time + spec.grabParticleSystemDisableDuration
			end
		end
	elseif id == BaleLoader.CHANGE_GRAB_MOVE_UP then
		spec.currentBaleGrabberDropBaleAnimName = self:getBaleGrabberDropBaleAnimName()

		self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, 1, nil, true)

		spec.grabberMoveState = BaleLoader.GRAB_DROP_BALE
	elseif id == BaleLoader.CHANGE_GRAB_DROP_BALE then
		if spec.startBalePlace.count < spec.startBalePlace.numOfPlaces and spec.startBalePlace.node ~= nil then
			local attachNode = getChildAt(spec.startBalePlace.node, spec.startBalePlace.count)
			local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

			if bale ~= nil then
				if spec.mountDynamic then
					self:mountDynamicBale(bale, attachNode)
				else
					local rx = 0
					local ry = 0
					local rz = 0

					if spec.keepBaleRotationDuringLoad then
						rx, ry, rz = localRotationToLocal(bale.nodeId, attachNode, 0, 0, 0)
					end

					bale:mount(self, attachNode, 0, 0, 0, rx, ry, rz)
				end

				spec.balesToMount[spec.baleGrabber.currentBale] = nil
			else
				spec.balesToMount[spec.baleGrabber.currentBale] = {
					serverId = spec.baleGrabber.currentBale,
					linkNode = attachNode,
					trans = {
						0,
						0,
						0
					},
					rot = {
						0,
						0,
						0
					}
				}
			end

			spec.startBalePlace.count = spec.startBalePlace.count + 1

			table.insert(spec.startBalePlace.bales, spec.baleGrabber.currentBale)

			spec.baleGrabber.currentBale = nil

			if spec.startBalePlace.count < spec.startBalePlace.numOfPlaces then
				spec.frontBalePusherDirection = 1

				self:playAnimation("balesToOtherRow", 1, nil, true)
				self:playAnimation("frontBalePusher", 1, nil, true)
			elseif spec.startBalePlace.count == spec.startBalePlace.numOfPlaces then
				BaleLoader.rotatePlatform(self)
			end

			if spec.animations.grabberDropToWork ~= nil then
				self:playAnimation(spec.animations.grabberDropToWork, 1, 0, true)
			else
				self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, -spec.animations.grabberDropBaleReverseSpeed, nil, true)
				self:playAnimation("baleGrabberWorkToDrop", -1, nil, true)
			end

			spec.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
		end
	elseif id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
		spec.grabberMoveState = nil
	elseif id == BaleLoader.CHANGE_FRONT_PUSHER then
		if spec.frontBalePusherDirection > 0 then
			self:playAnimation("frontBalePusher", -1, nil, true)

			spec.frontBalePusherDirection = -1
		else
			spec.frontBalePusherDirection = 0
		end
	elseif id == BaleLoader.CHANGE_ROTATE_PLATFORM then
		if spec.rotatePlatformDirection > 0 then
			local balePlace = spec.balePlaces[spec.currentBalePlace]
			spec.currentBalePlace = spec.currentBalePlace + 1

			for i = 1, table.getn(spec.startBalePlace.bales) do
				local node = getChildAt(spec.startBalePlace.node, i - 1)
				local x, y, z = getTranslation(node)
				local rx, ry, rz = getRotation(node)
				local baleServerId = spec.startBalePlace.bales[i]
				local bale = NetworkUtil.getObject(baleServerId)

				if spec.keepBaleRotationDuringLoad then
					x, y, z = localToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
					rx, ry, rz = localRotationToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
				end

				if bale ~= nil then
					if spec.mountDynamic then
						self:mountDynamicBale(bale, balePlace.node)
					else
						bale:mount(spec, balePlace.node, x, y, z, rx, ry, rz)
					end

					spec.balesToMount[baleServerId] = nil
				else
					spec.balesToMount[baleServerId] = {
						serverId = baleServerId,
						linkNode = balePlace.node,
						trans = {
							x,
							y,
							z
						},
						rot = {
							rx,
							ry,
							rz
						}
					}
				end
			end

			balePlace.bales = spec.startBalePlace.bales
			spec.startBalePlace.bales = {}
			spec.startBalePlace.count = 0

			for i = 1, spec.startBalePlace.numOfPlaces do
				local node = getChildAt(spec.startBalePlace.node, i - 1)

				setRotation(node, unpack(spec.startBalePlace.origRot[i]))
				setTranslation(node, unpack(spec.startBalePlace.origTrans[i]))
			end

			if spec.emptyState == BaleLoader.EMPTY_NONE then
				if self:getAnimationTime("baleGrabberWorkToDrop") < spec.moveBalePlacesMaxGrabberTime or spec.moveBalePlacesMaxGrabberTime == math.huge then
					spec.rotatePlatformDirection = -1

					self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)

					if spec.moveBalePlacesAfterRotatePlatform and (spec.currentBalePlace <= table.getn(spec.balePlaces) or spec.alwaysMoveBalePlaces) then
						self:playAnimation("moveBalePlaces", 1, (spec.currentBalePlace - 1) / table.getn(spec.balePlaces), true)
						self:setAnimationStopTime("moveBalePlaces", spec.currentBalePlace / table.getn(spec.balePlaces))
						self:playAnimation("moveBalePlacesExtrasOnce", 1, nil, true)
					end
				else
					spec.rotatePlatformDirection = -1
					spec.moveBalePlacesDelayedMovement = true
				end
			else
				spec.rotatePlatformDirection = 0
			end
		else
			spec.rotatePlatformDirection = 0
		end
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
		spec.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM

		if spec.startBalePlace.count == 0 then
			self:playAnimation(spec.animations.rotatePlatformEmpty, 1, nil, true)
		else
			BaleLoader.rotatePlatform(self)
		end
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
		self:playAnimation("emptyRotate", 1, nil, true)
		self:setAnimationStopTime("emptyRotate", 0.2)

		local balePlacesTime = self:getRealAnimationTime("moveBalePlaces")

		self:playAnimation("moveBalePlacesToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePlacesToEmpty"), true)
		self:playAnimation("moveBalePusherToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePusherToEmpty"), true)

		spec.emptyState = BaleLoader.EMPTY_ROTATE1

		if self.isClient then
			g_soundManager:playSample(spec.samples.emptyRotate)
		end
	elseif id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
		self:playAnimation("closeGrippers", 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
	elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
		self:playAnimation("emptyHidePusher1", 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
	elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
		self:playAnimation("moveBalePusherToEmpty", -2, nil, true)

		spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
		self:playAnimation("emptyRotate", 1, self:getAnimationTime("emptyRotate"), true)

		spec.emptyState = BaleLoader.EMPTY_ROTATE2
	elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
	elseif id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
		spec.emptyState = BaleLoader.EMPTY_NONE

		if GS_IS_MOBILE_VERSION then
			if self:getRootVehicle():getActionControllerDirection() < 0 then
				spec.controlledAction.parent:startActionSequence()
			end
		elseif spec.transportPositionAfterUnloading then
			BaleLoader.moveToTransportPosition(self)

			if self.isServer then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
			end
		end

		spec.automaticUnloadingInProgress = false
	elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
	elseif id == BaleLoader.CHANGE_BUTTON_EMPTY then
		assert(self.isServer)

		if spec.emptyState ~= BaleLoader.EMPTY_NONE then
			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self)
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_SINK), true, nil, self)
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self)
			end
		elseif BaleLoader.getAllowsStartUnloading(self) then
			g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self)
		end
	elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
		assert(self.isServer)

		if spec.emptyState ~= BaleLoader.EMPTY_NONE and spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
			g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self)
		end
	elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
		assert(self.isServer)

		if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
			if spec.isInWorkPosition then
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
			else
				g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
			end
		end
	end
end

function BaleLoader:getAllowsStartUnloading()
	local spec = self.spec_baleLoader

	if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 then
		return false
	end

	if spec.rotatePlatformDirection ~= 0 then
		return false
	end

	if spec.frontBalePusherDirection ~= 0 then
		return false
	end

	if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
		return false
	end

	if spec.emptyState ~= BaleLoader.EMPTY_NONE then
		return false
	end

	return true
end

function BaleLoader:rotatePlatform()
	local spec = self.spec_baleLoader
	spec.rotatePlatformDirection = 1

	self:playAnimation(spec.animations.rotatePlatform, 1, nil, true)

	if spec.currentBalePlace > 1 and not spec.moveBalePlacesAfterRotatePlatform or spec.alwaysMoveBalePlaces then
		self:playAnimation("moveBalePlaces", 1, (spec.currentBalePlace - 1) / table.getn(spec.balePlaces), true)
		self:setAnimationStopTime("moveBalePlaces", spec.currentBalePlace / table.getn(spec.balePlaces))
		self:playAnimation("moveBalePlacesExtrasOnce", 1, nil, true)
	end
end

function BaleLoader:moveToWorkPosition(onLoad)
	local speed = 1

	if onLoad then
		speed = 9999
	end

	self:playAnimation("baleGrabberTransportToWork", speed, MathUtil.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1), true)

	local animTime = nil

	if self:getAnimationTime("closeGrippers") ~= 0 then
		animTime = self:getAnimationTime("closeGrippers")
	end

	self:playAnimation("closeGrippers", -1, animTime, true)
end

function BaleLoader:moveToTransportPosition()
	self:playAnimation("baleGrabberTransportToWork", -1, MathUtil.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1), true)
	self:playAnimation("closeGrippers", 1, MathUtil.clamp(self:getAnimationTime("closeGrippers"), 0, 1), true)
end

function BaleLoader:getBaleGrabberDropBaleAnimName()
	local spec = self.spec_baleLoader
	local name = string.format("baleGrabberDropBale%d", spec.startBalePlace.count)

	if self:getAnimationExists(name) then
		return name
	end

	return "baleGrabberDropBale"
end

function BaleLoader:getIsBaleGrabbingAllowed()
	local spec = self.spec_baleLoader

	if not spec.isInWorkPosition then
		return false
	end

	if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
		return false
	end

	if spec.startBalePlace.numOfPlaces <= spec.startBalePlace.count then
		return false
	end

	if spec.frontBalePusherDirection ~= 0 then
		return false
	end

	if spec.rotatePlatformDirection ~= 0 then
		return false
	end

	if spec.alwaysMoveBalePlaces and self:getIsAnimationPlaying("moveBalePlaces") then
		return false
	end

	if spec.emptyState ~= BaleLoader.EMPTY_NONE then
		return false
	end

	if self:getFillUnitFreeCapacity(spec.fillUnitIndex) == 0 then
		return false
	end

	return true
end

function BaleLoader:pickupBale(nearestBale, nearestBaleType)
	g_server:broadcastEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(nearestBale)), true, nil, self)

	self.spec_baleLoader.lastPickupTime = g_time
end

function BaleLoader:baleGrabberTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object:isa(Bale) then
			local spec = self.spec_baleLoader

			if onEnter then
				spec.baleGrabber.balesInTrigger[object] = Utils.getNoNil(spec.baleGrabber.balesInTrigger[object], 0) + 1
			elseif onLeave and spec.baleGrabber.balesInTrigger[object] ~= nil then
				spec.baleGrabber.balesInTrigger[object] = math.max(0, spec.baleGrabber.balesInTrigger[object] - 1)

				if spec.baleGrabber.balesInTrigger[object] == 0 then
					spec.baleGrabber.balesInTrigger[object] = nil
				end
			end
		end
	end
end

function BaleLoader:mountDynamicBale(bale, node)
	if self.isServer then
		local spec = self.spec_baleLoader

		if bale.dynamicMountJointIndex ~= nil then
			link(node, bale.dynamicMountJointNode)
			setWorldTranslation(bale.dynamicMountJointNode, getWorldTranslation(bale.nodeId))
			setWorldRotation(bale.dynamicMountJointNode, getWorldRotation(bale.nodeId))
			setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
			table.insert(spec.updateBaleJointNodePosition, {
				time = 0,
				node = bale.dynamicMountJointNode
			})
		else
			local jointNode = createTransformGroup("baleJoint")

			link(node, jointNode)
			setWorldTranslation(jointNode, getWorldTranslation(bale.nodeId))
			setWorldRotation(jointNode, getWorldRotation(bale.nodeId))
			bale:mountDynamic(self, self:getParentComponent(node), jointNode, DynamicMountUtil.TYPE_FIX_ATTACH, 0, false)

			if spec.dynamicMountMinTransLimits ~= nil and spec.dynamicMountMaxTransLimits ~= nil then
				for i = 1, 3 do
					local active = spec.dynamicMountMinTransLimits[i] ~= 0 or spec.dynamicMountMaxTransLimits[i] ~= 0

					if active then
						setJointTranslationLimit(bale.dynamicMountJointIndex, i - 1, active, spec.dynamicMountMinTransLimits[i], spec.dynamicMountMaxTransLimits[i])
					end
				end
			end

			table.insert(spec.updateBaleJointNodePosition, {
				time = 0,
				node = jointNode
			})

			spec.isBaleWeightDirty = true

			g_currentMission:removeItemToSave(bale)
		end
	end
end

function BaleLoader:unmountDynamicBale(bale)
	if self.isServer then
		bale:unmountDynamic()
		delete(bale.dynamicMountJointNode)

		if bale.backupMass ~= nil then
			setMass(bale.nodeId, bale.backupMass)

			bale.backupMass = nil
		end

		g_currentMission:addItemToSave(bale)
	end
end

function BaleLoader:getLoadedBales()
	local bales = {}
	local spec = self.spec_baleLoader

	for _, balePlace in pairs(spec.balePlaces) do
		if balePlace.bales ~= nil then
			for _, baleServerId in pairs(balePlace.bales) do
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					table.insert(bales, bale)
				end
			end
		end
	end

	for _, baleServerId in ipairs(spec.startBalePlace.bales) do
		local bale = NetworkUtil.getObject(baleServerId)

		if bale ~= nil then
			table.insert(bales, bale)
		end
	end

	return bales
end

function BaleLoader:startAutomaticBaleUnloading()
	local spec = self.spec_baleLoader

	if spec.emptyState == BaleLoader.EMPTY_NONE then
		spec.automaticUnloadingInProgress = true

		g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
	end
end

function BaleLoader:getIsAutomaticBaleUnloadingInProgress()
	return self.spec_baleLoader.automaticUnloadingInProgress
end

function BaleLoader:getIsAutomaticBaleUnloadingAllowed()
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	end

	if g_time < self.spec_baleLoader.lastPickupTime + self.spec_baleLoader.lastPickupAutomatedUnloadingDelayTime then
		return false
	end

	if not BaleLoader.getAllowsStartUnloading(self) then
		return false
	end

	return true
end

function BaleLoader:getCanBeSelected(superFunc)
	return true
end

function BaleLoader:getAllowDynamicMountFillLevelInfo(superFunc)
	local spec = self.spec_baleLoader

	if spec.mountDynamic then
		return false
	end

	return superFunc(self)
end

function BaleLoader:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleLoader

	if spec.baleGrabber.trigger ~= nil then
		list[spec.baleGrabber.trigger] = self
	end
end

function BaleLoader:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleLoader

	if spec.baleGrabber.trigger ~= nil then
		list[spec.baleGrabber.trigger] = nil
	end
end

function BaleLoader:getAreControlledActionsAllowed(superFunc)
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	end

	return superFunc(self)
end

function BaleLoader:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_baleLoader

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleLoader.actionEventEmpty, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, BaleLoader.actionEventWorkTransport, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, BaleLoader.actionEventAbortEmpty, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText(spec.texts.abortUnloading, self.customEnvironment))
		end
	end
end

function BaleLoader:actionEventEmpty(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
end

function BaleLoader:actionEventAbortEmpty(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_EMPTY_ABORT))
end

function BaleLoader:actionEventWorkTransport(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent:new(self, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT))
end
