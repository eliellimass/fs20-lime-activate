source("dataS/scripts/vehicles/specializations/events/BaleWrapperStateEvent.lua")

BaleWrapper = {
	STATE_NONE = 0,
	STATE_MOVING_BALE_TO_WRAPPER = 1,
	STATE_MOVING_GRABBER_TO_WORK = 2,
	STATE_WRAPPER_WRAPPING_BALE = 3,
	STATE_WRAPPER_FINSIHED = 4,
	STATE_WRAPPER_DROPPING_BALE = 5,
	STATE_WRAPPER_RESETTING_PLATFORM = 6,
	STATE_NUM_BITS = 3,
	CHANGE_GRAB_BALE = 1,
	CHANGE_DROP_BALE_AT_GRABBER = 2,
	CHANGE_WRAPPING_START = 3,
	CHANGE_WRAPPING_BALE_FINSIHED = 4,
	CHANGE_WRAPPER_START_DROP_BALE = 5,
	CHANGE_WRAPPER_BALE_DROPPED = 6,
	CHANGE_WRAPPER_PLATFORM_RESET = 7,
	CHANGE_BUTTON_EMPTY = 8,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
}

function BaleWrapper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWrapperFromXML", BaleWrapper.loadWrapperFromXML)
	SpecializationUtil.registerFunction(vehicleType, "allowsGrabbingBale", BaleWrapper.allowsGrabbingBale)
	SpecializationUtil.registerFunction(vehicleType, "pickupWrapperBale", BaleWrapper.pickupWrapperBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleFillTypeSkiped", BaleWrapper.getIsBaleFillTypeSkiped)
	SpecializationUtil.registerFunction(vehicleType, "getWrapperBaleType", BaleWrapper.getWrapperBaleType)
	SpecializationUtil.registerFunction(vehicleType, "updateWrappingState", BaleWrapper.updateWrappingState)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleWrapper.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "updateWrapNodes", BaleWrapper.updateWrapNodes)
	SpecializationUtil.registerFunction(vehicleType, "playMoveToWrapper", BaleWrapper.playMoveToWrapper)
end

function BaleWrapper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", BaleWrapper.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleWrapper.getCanBeSelected)
end

function BaleWrapper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleWrapper)
end

function BaleWrapper.initSpecialization()
	g_configurationManager:addConfigurationType("wrappingColor", g_i18n:getText("configuration_wrappingColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
end

function BaleWrapper:onLoad(savegame)
	local spec = self.spec_baleWrapper

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.wrapper", "vehicle.baleWrapper")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleGrabber", "vehicle.baleWrapper.grabber")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.grabber#index", "vehicle.baleWrapper.grabber#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.roundBaleWrapper#baleIndex", "vehicle.baleWrapper.roundBaleWrapper#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.roundBaleWrapper#wrapperIndex", "vehicle.baleWrapper.roundBaleWrapper#wrapperNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.squareBaleWrapper#baleIndex", "vehicle.baleWrapper.squareBaleWrapper#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.baleWrapper.squareBaleWrapper#wrapperIndex", "vehicle.baleWrapper.squareBaleWrapper#wrapperNode")

	local baseKey = "vehicle.baleWrapper"
	spec.roundBaleWrapper = {}

	self:loadWrapperFromXML(spec.roundBaleWrapper, self.xmlFile, baseKey .. ".roundBaleWrapper")

	spec.squareBaleWrapper = {}

	self:loadWrapperFromXML(spec.squareBaleWrapper, self.xmlFile, baseKey .. ".squareBaleWrapper")

	spec.currentWrapper = {}
	spec.currentWrapperFoldMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#foldMinLimit"), 0)
	spec.currentWrapperFoldMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. "#foldMaxLimit"), 1)
	spec.currentWrapper = spec.roundBaleWrapper

	self:updateWrapNodes(false, true, 0)

	spec.currentWrapper = spec.squareBaleWrapper

	self:updateWrapNodes(false, true, 0)

	spec.baleGrabber = {
		grabNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. ".grabber#node"), self.i3dMappings),
		nearestDistance = Utils.getNoNil(getXMLFloat(self.xmlFile, baseKey .. ".grabber#nearestDistance"), 3)
	}
	spec.baleToLoad = nil
	spec.baleToMount = nil
	spec.baleWrapperState = BaleWrapper.STATE_NONE
	spec.grabberIsMoving = false
	spec.hasBaleWrapper = true
	spec.showInvalidBaleWarning = false
end

function BaleWrapper:onPostLoad(savegame)
	local spec = self.spec_baleWrapper

	if savegame ~= nil and not savegame.resetVehicles then
		local filename = getXMLString(savegame.xmlFile, savegame.key .. ".baleWrapper#baleFileName")

		if filename ~= nil then
			filename = NetworkUtil.convertFromNetworkFilename(filename)
			local wrapperTime = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. ".baleWrapper#wrapperTime"), 0)
			local baleValueScale = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. ".baleWrapper#baleValueScale"), 1)
			local fillLevel = getXMLFloat(savegame.xmlFile, savegame.key .. ".baleWrapper#fillLevel")
			local translation = {
				0,
				0,
				0
			}
			local rotation = {
				0,
				0,
				0
			}
			spec.baleToLoad = {
				filename = filename,
				translation = translation,
				rotation = rotation,
				fillLevel = fillLevel,
				wrapperTime = wrapperTime,
				baleValueScale = baleValueScale
			}
		end
	end

	if self.configurations.wrappingColor ~= nil then
		ConfigurationUtil.setColor(self, self.xmlFile, "wrappingColor", self.configurations.wrappingColor)
	end
end

function BaleWrapper:loadWrapperFromXML(wrapper, xmlFile, baseKey)
	wrapper.animations = {}

	for _, animType in pairs({
		"moveToWrapper",
		"wrapBale",
		"dropFromWrapper",
		"resetAfterDrop"
	}) do
		local key = string.format("%s.animations.%s", baseKey, animType)
		local anim = {
			animName = getXMLString(xmlFile, key .. "#animName"),
			animSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#animSpeed"), 1),
			reverseAfterMove = Utils.getNoNil(getXMLBool(xmlFile, key .. "#reverseAfterMove"), true)
		}

		if Utils.getNoNil(getXMLBool(xmlFile, key .. "#resetOnStart"), false) then
			self:playAnimation(anim.animName, -1, 0.1, true)
			AnimatedVehicle.updateAnimationByName(self, anim.animName, 9999999)
		end

		wrapper.animations[animType] = anim
	end

	wrapper.allowedBaleTypes = {}
	local i = 0

	while true do
		local key = string.format("%s.baleTypes.baleType(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local wrapperBaleFilename = Utils.getFilename(getXMLString(xmlFile, key .. "#wrapperBaleFilename"), self.baseDirectory)

		if wrapperBaleFilename == nil or not fileExists(wrapperBaleFilename) then
			g_logManager:xmlWarning(self.configFileName, "Unknown wrapper bale file '%s' for '%s'", tostring(wrapperBaleFilename), key)

			break
		end

		local fillTypeStr = getXMLString(xmlFile, key .. "#fillType")

		if fillTypeStr == nil or g_fillTypeManager:getFillTypeByName(fillTypeStr) == nil then
			g_logManager:xmlWarning(self.configFileName, "Warning: invalid fillType '%s' for '%s' given!", tostring(fillTypeStr), key)

			break
		end

		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
		wrapper.allowedBaleTypes[fillTypeIndex] = {}
		local minBaleDiameter = getXMLFloat(xmlFile, key .. "#minBaleDiameter")
		local maxBaleDiameter = getXMLFloat(xmlFile, key .. "#maxBaleDiameter")
		local minBaleWidth = getXMLFloat(xmlFile, key .. "#minBaleWidth")
		local maxBaleWidth = getXMLFloat(xmlFile, key .. "#maxBaleWidth")

		if minBaleDiameter ~= nil and maxBaleDiameter ~= nil and minBaleWidth ~= nil and maxBaleWidth ~= nil then
			table.insert(wrapper.allowedBaleTypes[fillTypeIndex], {
				fillType = fillTypeIndex,
				wrapperBaleFilename = wrapperBaleFilename,
				minBaleDiameter = minBaleDiameter,
				maxBaleDiameter = maxBaleDiameter,
				minBaleWidth = minBaleWidth,
				maxBaleWidth = maxBaleWidth
			})
		else
			local minBaleHeight = getXMLFloat(xmlFile, key .. "#minBaleHeight")
			local maxBaleHeight = getXMLFloat(xmlFile, key .. "#maxBaleHeight")
			local minBaleLength = getXMLFloat(xmlFile, key .. "#minBaleLength")
			local maxBaleLength = getXMLFloat(xmlFile, key .. "#maxBaleLength")

			if minBaleWidth ~= nil and maxBaleWidth ~= nil and minBaleHeight ~= nil and maxBaleHeight ~= nil and minBaleLength ~= nil and maxBaleLength ~= nil then
				table.insert(wrapper.allowedBaleTypes[fillTypeIndex], {
					fillType = fillTypeIndex,
					wrapperBaleFilename = wrapperBaleFilename,
					minBaleWidth = minBaleWidth,
					maxBaleWidth = maxBaleWidth,
					minBaleHeight = minBaleHeight,
					maxBaleHeight = maxBaleHeight,
					minBaleLength = minBaleLength,
					maxBaleLength = maxBaleLength
				})
			end
		end

		i = i + 1
	end

	wrapper.baleNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#baleNode"), self.i3dMappings)
	wrapper.wrapperNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, baseKey .. "#wrapperNode"), self.i3dMappings)
	wrapper.wrapperRotAxis = Utils.getNoNil(getXMLInt(xmlFile, baseKey .. "#wrapperRotAxis"), 2)
	local wrappingAnimCurve = AnimCurve:new(linearInterpolatorN)
	i = 0

	while true do
		local keyI = string.format("%s.wrapperAnimation.key(%d)", baseKey, i)
		local t = getXMLFloat(xmlFile, keyI .. "#time")
		local baleX, baleY, baleZ = StringUtil.getVectorFromString(getXMLString(xmlFile, keyI .. "#baleRot"))

		if baleX == nil or baleY == nil or baleZ == nil then
			break
		end

		baleX = math.rad(Utils.getNoNil(baleX, 0))
		baleY = math.rad(Utils.getNoNil(baleY, 0))
		baleZ = math.rad(Utils.getNoNil(baleZ, 0))
		local wrapperX, wrapperY, wrapperZ = StringUtil.getVectorFromString(getXMLString(xmlFile, keyI .. "#wrapperRot"))
		wrapperX = math.rad(Utils.getNoNil(wrapperX, 0))
		wrapperY = math.rad(Utils.getNoNil(wrapperY, 0))
		wrapperZ = math.rad(Utils.getNoNil(wrapperZ, 0))

		wrappingAnimCurve:addKeyframe({
			baleX,
			baleY,
			baleZ,
			wrapperX,
			wrapperY,
			wrapperZ,
			time = t
		})

		i = i + 1
	end

	wrapper.animCurve = wrappingAnimCurve
	wrapper.animTime = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. "#wrappingTime"), 5) * 1000
	wrapper.currentTime = 0
	wrapper.currentBale = nil
	wrapper.wrapAnimNodes = {}
	i = 0

	while true do
		local wrapAnimNodeKey = string.format("%s.wrapAnimNodes.wrapAnimNode(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, wrapAnimNodeKey) then
			break
		end

		local nodeId = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, wrapAnimNodeKey .. "#index"), self.i3dMappings)

		if nodeId ~= nil then
			local animCurve = AnimCurve:new(linearInterpolatorN)
			local keyI = 0
			local useWrapperRot = false

			while true do
				local nodeKey = string.format(wrapAnimNodeKey .. ".key(%d)", keyI)
				local wrapperRot = getXMLFloat(xmlFile, nodeKey .. "#wrapperRot")
				local wrapperTime = getXMLFloat(xmlFile, nodeKey .. "#wrapperTime")

				if wrapperRot == nil and wrapperTime == nil then
					break
				end

				useWrapperRot = wrapperRot ~= nil
				local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#trans"))
				local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#rot"))
				local sx, sy, sz = StringUtil.getVectorFromString(getXMLString(xmlFile, nodeKey .. "#scale"))
				x = Utils.getNoNil(x, 0)
				y = Utils.getNoNil(y, 0)
				z = Utils.getNoNil(z, 0)
				rx = math.rad(Utils.getNoNil(rx, 0))
				ry = math.rad(Utils.getNoNil(ry, 0))
				rz = math.rad(Utils.getNoNil(rz, 0))
				sx = Utils.getNoNil(sx, 1)
				sy = Utils.getNoNil(sy, 1)
				sz = Utils.getNoNil(sz, 1)

				if wrapperRot ~= nil then
					animCurve:addKeyframe({
						x,
						y,
						z,
						rx,
						ry,
						rz,
						sx,
						sy,
						sz,
						time = math.rad(wrapperRot)
					})
				else
					animCurve:addKeyframe({
						x,
						y,
						z,
						rx,
						ry,
						rz,
						sx,
						sy,
						sz,
						time = wrapperTime
					})
				end

				keyI = keyI + 1
			end

			if keyI > 0 then
				local repeatWrapperRot = Utils.getNoNil(getXMLBool(xmlFile, wrapAnimNodeKey .. "#repeatWrapperRot"), false)
				local normalizeRotationOnBaleDrop = Utils.getNoNil(getXMLInt(xmlFile, wrapAnimNodeKey .. "#normalizeRotationOnBaleDrop"), 0)

				table.insert(wrapper.wrapAnimNodes, {
					nodeId = nodeId,
					animCurve = animCurve,
					repeatWrapperRot = repeatWrapperRot,
					normalizeRotationOnBaleDrop = normalizeRotationOnBaleDrop,
					useWrapperRot = useWrapperRot
				})
			end
		end

		i = i + 1
	end

	wrapper.wrapNodes = {}
	i = 0

	while true do
		local wrapNodeKey = string.format("%s.wrapNodes.wrapNode(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, wrapNodeKey) then
			break
		end

		local nodeId = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, wrapNodeKey .. "#index"), self.i3dMappings)
		local wrapVisibility = Utils.getNoNil(getXMLBool(xmlFile, wrapNodeKey .. "#wrapVisibility"), false)
		local emptyVisibility = Utils.getNoNil(getXMLBool(xmlFile, wrapNodeKey .. "#emptyVisibility"), false)

		if nodeId ~= nil and (wrapVisibility or emptyVisibility) then
			local maxWrapperRot = getXMLFloat(xmlFile, wrapNodeKey .. "#maxWrapperRot")

			if maxWrapperRot == nil then
				maxWrapperRot = math.huge
			else
				maxWrapperRot = math.rad(maxWrapperRot)
			end

			table.insert(wrapper.wrapNodes, {
				nodeId = nodeId,
				wrapVisibility = wrapVisibility,
				emptyVisibility = emptyVisibility,
				maxWrapperRot = maxWrapperRot
			})
		end

		i = i + 1
	end

	wrapper.wrappingStateCurve = AnimCurve:new(linearInterpolator1)
	i = 0

	while true do
		local key2 = string.format("%s.wrappingState.key(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, key2) then
			break
		end

		local t = getXMLFloat(xmlFile, key2 .. "#time")
		local wrappingState = getXMLFloat(xmlFile, key2 .. "#wrappingState")

		wrapper.wrappingStateCurve:addKeyframe({
			wrappingState,
			time = t
		})

		i = i + 1
	end

	if self.isServer then
		wrapper.collisions = {}
		i = 0

		while true do
			local key2 = string.format("%s.wrappingCollisions.collision(%d)", baseKey, i)

			if not hasXMLProperty(self.xmlFile, key2) then
				break
			end

			local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, key2 .. "#node"), self.i3dMappings)
			local activeCollisionMask = getXMLInt(self.xmlFile, key2 .. "#activeCollisionMask")
			local inActiveCollisionMask = getXMLInt(self.xmlFile, key2 .. "#inActiveCollisionMask")

			table.insert(wrapper.collisions, {
				node = node,
				activeCollisionMask = activeCollisionMask,
				inActiveCollisionMask = inActiveCollisionMask
			})

			i = i + 1
		end
	end

	local defaultText = wrapper == self.spec_baleWrapper.roundBaleWrapper and "action_unloadRoundBale" or "action_unloadSquareBale"
	wrapper.unloadBaleText = Utils.getNoNil(getXMLString(xmlFile, baseKey .. "#unloadBaleText"), defaultText)
	local fillTypesStr = getXMLString(self.xmlFile, baseKey .. "#skipWrappingFillTypes")
	wrapper.skipUnsupportedBales = Utils.getNoNil(getXMLBool(self.xmlFile, baseKey .. "#skipUnsupportedBales"), fillTypesStr ~= nil and fillTypesStr ~= "")

	if self.isClient then
		wrapper.samples = {
			wrap = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			start = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		wrapper.wrappingSoundEndTime = Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".sounds#wrappingEndTime"), 1)
	end
end

function BaleWrapper:onDelete()
	local spec = self.spec_baleWrapper
	local baleId = nil

	if spec.currentWrapper.currentBale ~= nil then
		baleId = spec.currentWrapper.currentBale
	end

	if spec.baleGrabber.currentBale ~= nil then
		baleId = spec.baleGrabber.currentBale
	end

	if baleId ~= nil then
		local bale = NetworkUtil.getObject(baleId)

		if bale ~= nil then
			bale:unmount()
		end
	end

	if self.isClient then
		g_soundManager:deleteSamples(spec.roundBaleWrapper.samples)
		g_soundManager:deleteSamples(spec.squareBaleWrapper.samples)
	end
end

function BaleWrapper:saveToXMLFile(xmlFile, key, usedModNames)
	if self.isReconfigurating == nil or not self.isReconfigurating then
		local spec = self.spec_baleWrapper
		local baleServerId = spec.baleGrabber.currentBale

		if baleServerId == nil then
			baleServerId = spec.currentWrapper.currentBale
		end

		if baleServerId ~= nil then
			local bale = NetworkUtil.getObject(baleServerId)

			if bale ~= nil then
				local fillLevel = bale:getFillLevel()
				local baleValueScale = bale.baleValueScale

				setXMLString(xmlFile, key .. "#baleFileName", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(bale.i3dFilename)))
				setXMLFloat(xmlFile, key .. "#fillLevel", fillLevel)
				setXMLFloat(xmlFile, key .. "#wrapperTime", spec.currentWrapper.currentTime)
				setXMLFloat(xmlFile, key .. "#baleValueScale", baleValueScale)
			end
		end
	end
end

function BaleWrapper:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_baleWrapper
		local isRoundBaleWrapper = streamReadBool(streamId)

		if isRoundBaleWrapper then
			spec.currentWrapper = spec.roundBaleWrapper
		else
			spec.currentWrapper = spec.squareBaleWrapper
		end

		local wrapperState = streamReadUIntN(streamId, BaleWrapper.STATE_NUM_BITS)

		if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= wrapperState then
			local baleServerId, isRoundBale = nil

			if wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
				baleServerId = NetworkUtil.readNodeObjectId(streamId)
				isRoundBale = streamReadBool(streamId)
			end

			if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
				self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, baleServerId)
				AnimatedVehicle.updateAnimations(self, 99999999)
			elseif wrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
				self.baleGrabber.currentBale = baleServerId

				self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)
				AnimatedVehicle.updateAnimations(self, 99999999)
			elseif wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
				spec.currentWrapper = isRoundBale and spec.roundBaleWrapper or spec.squareBaleWrapper
				local attachNode = spec.currentWrapper.baleNode
				spec.baleToMount = {
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

				self:updateWrapNodes(true, false, 0)

				spec.currentWrapper.currentBale = baleServerId

				if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
					local wrapperTime = streamReadFloat32(streamId)
					spec.currentWrapper.currentTime = wrapperTime

					self:updateWrappingState(spec.currentWrapper.currentTime / spec.currentWrapper.animTime, true)
				else
					spec.currentWrapper.currentTime = spec.currentWrapper.animTime

					self:updateWrappingState(1, true)
					self:doStateChange(BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED)
					AnimatedVehicle.updateAnimations(self, 99999999)

					if BaleWrapper.STATE_WRAPPER_DROPPING_BALE <= wrapperState then
						self:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE)
						AnimatedVehicle.updateAnimations(self, 99999999)
					end
				end
			else
				spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
			end
		end
	end
end

function BaleWrapper:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_baleWrapper

		streamWriteBool(streamId, spec.currentWrapper == spec.roundBaleWrapper)

		local wrapperState = spec.baleWrapperState

		streamWriteUIntN(streamId, wrapperState, BaleWrapper.STATE_NUM_BITS)

		if BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER <= wrapperState and wrapperState ~= BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM then
			local bale = nil

			if wrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
				NetworkUtil.writeNodeObjectId(streamId, spec.baleGrabber.currentBale)

				bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)
			else
				NetworkUtil.writeNodeObjectId(streamId, spec.currentWrapper.currentBale)

				bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)
			end

			streamWriteBool(streamId, (bale or {}).baleDiameter ~= nil)
		end

		if wrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
			streamWriteFloat32(streamId, spec.currentWrapper.currentTime)
		end
	end
end

function BaleWrapper:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleWrapper

	if self.firstTimeRun then
		if spec.baleToLoad ~= nil then
			local v = spec.baleToLoad
			spec.baleToLoad = nil
			local baleObject = Bale:new(self.isServer, self.isClient)
			local x, y, z = unpack(v.translation)
			local rx, ry, rz = unpack(v.rotation)

			baleObject:load(v.filename, x, y, z, rx, ry, rz, v.fillLevel)
			baleObject:setOwnerFarmId(self:getActiveFarm(), true)
			baleObject:register()

			if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
				self:doStateChange(BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(baleObject))
				self:doStateChange(BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER)

				baleObject.baleValueScale = v.baleValueScale
				local wrapperState = math.min(v.wrapperTime / spec.currentWrapper.animTime, 1)

				baleObject:setWrappingState(wrapperState)
				self:doStateChange(BaleWrapper.CHANGE_WRAPPING_START)

				spec.currentWrapper.currentTime = v.wrapperTime
				local wrappingTime = spec.currentWrapper.currentTime / spec.currentWrapper.animTime

				self:setAnimationTime(spec.currentWrapper.animations.wrapBale.animName, wrappingTime)
				self:updateWrappingState(wrappingTime)
			end
		end

		if spec.baleToMount ~= nil then
			local bale = NetworkUtil.getObject(spec.baleToMount.serverId)

			if bale ~= nil then
				local x, y, z = unpack(spec.baleToMount.trans)
				local rx, ry, rz = unpack(spec.baleToMount.rot)

				bale:mount(self, spec.baleToMount.linkNode, x, y, z, rx, ry, rz)

				spec.baleToMount = nil

				if spec.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
					self:playMoveToWrapper(bale)
				end
			end
		end
	end

	if spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
		local wrapper = spec.currentWrapper
		wrapper.currentTime = wrapper.currentTime + dt
		local wrappingTime = wrapper.currentTime / wrapper.animTime

		self:updateWrappingState(wrappingTime)
		self:raiseActive()

		if self.isClient then
			if wrapper.wrappingSoundEndTime <= wrappingTime then
				if g_soundManager:getIsSamplePlaying(wrapper.samples.wrap) then
					g_soundManager:stopSample(wrapper.samples.wrap)
					g_soundManager:playSample(wrapper.samples.stop)
				end
			elseif not g_soundManager:getIsSamplePlaying(wrapper.samples.wrap) then
				g_soundManager:playSample(wrapper.samples.wrap)
			end
		end
	end
end

function BaleWrapper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleWrapper
	spec.showInvalidBaleWarning = false

	if self:allowsGrabbingBale() and spec.baleGrabber.grabNode ~= nil and spec.baleGrabber.currentBale == nil then
		local nearestBale, nearestBaleType = BaleWrapper.getBaleInRange(self, spec.baleGrabber.grabNode, spec.baleGrabber.nearestDistance)

		if nearestBale ~= nil then
			if self.isServer and (nearestBaleType ~= nil or self:getIsBaleFillTypeSkiped(nearestBale)) then
				self:pickupWrapperBale(nearestBale, nearestBaleType)
			elseif spec.lastDroppedBale ~= nearestBale then
				spec.showInvalidBaleWarning = true
			end
		end
	end

	if self.isServer and spec.baleWrapperState ~= BaleWrapper.STATE_NONE then
		if spec.baleWrapperState == BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER then
			if not self:getIsAnimationPlaying(spec.currentWrapper.animations.moveToWrapper.animName) then
				g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER), true, nil, self)
			end
		elseif spec.baleWrapperState == BaleWrapper.STATE_MOVING_GRABBER_TO_WORK then
			if not self:getIsAnimationPlaying(spec.currentWrapper.animations.moveToWrapper.animName) then
				local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)

				if bale ~= nil and not bale.supportsWrapping then
					g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
				else
					g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_START), true, nil, self)
				end
			end
		elseif spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_DROPPING_BALE then
			if not self:getIsAnimationPlaying(spec.currentWrapper.animations.dropFromWrapper.animName) then
				g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED), true, nil, self)
			end
		elseif spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM and not self:getIsAnimationPlaying(spec.currentWrapper.animations.resetAfterDrop.animName) then
			g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET), true, nil, self)
		end
	end

	local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED)
		g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText(spec.currentWrapper.unloadBaleText, self.customEnvironment))
	end

	if spec.setWrappingStateFinished then
		g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)

		spec.setWrappingStateFinished = false
	end
end

function BaleWrapper:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_baleWrapper

		if spec.showInvalidBaleWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_baleNotSupported"), 500)
		end
	end
end

function BaleWrapper:allowsGrabbingBale()
	local spec = self.spec_baleWrapper
	local specFoldable = self.spec_foldable

	if specFoldable ~= nil and specFoldable.foldAnimTime ~= nil and (spec.currentWrapperFoldMaxLimit < specFoldable.foldAnimTime or specFoldable.foldAnimTime < spec.currentWrapperFoldMinLimit) then
		return false
	end

	return spec.baleWrapperState == BaleWrapper.STATE_NONE
end

function BaleWrapper:updateWrapNodes(isWrapping, isEmpty, t, wrapperRot)
	local spec = self.spec_baleWrapper

	if wrapperRot == nil then
		wrapperRot = 0
	end

	for _, wrapNode in pairs(spec.currentWrapper.wrapNodes) do
		local doShow = true

		if wrapNode.maxWrapperRot ~= nil then
			doShow = wrapperRot < wrapNode.maxWrapperRot
		end

		setVisibility(wrapNode.nodeId, doShow and (isWrapping and wrapNode.wrapVisibility or isEmpty and wrapNode.emptyVisibility))
	end

	if isWrapping then
		local wrapperRotRepeat = MathUtil.sign(wrapperRot) * (wrapperRot % math.pi)

		if wrapperRotRepeat < 0 then
			wrapperRotRepeat = wrapperRotRepeat + math.pi
		end

		for _, wrapAnimNode in pairs(spec.currentWrapper.wrapAnimNodes) do
			local v = nil

			if wrapAnimNode.useWrapperRot then
				local rot = wrapperRot

				if wrapAnimNode.repeatWrapperRot then
					rot = wrapperRotRepeat
				end

				v = wrapAnimNode.animCurve:get(rot)
			else
				v = wrapAnimNode.animCurve:get(t)
			end

			if v ~= nil then
				setTranslation(wrapAnimNode.nodeId, v[1], v[2], v[3])
				setRotation(wrapAnimNode.nodeId, v[4], v[5], v[6])
				setScale(wrapAnimNode.nodeId, v[7], v[8], v[9])
			end
		end
	elseif not isEmpty then
		for _, wrapAnimNode in pairs(spec.currentWrapper.wrapAnimNodes) do
			if wrapAnimNode.normalizeRotationOnBaleDrop ~= 0 then
				local rot = {
					getRotation(wrapAnimNode.nodeId)
				}

				for i = 1, 3 do
					rot[i] = wrapAnimNode.normalizeRotationOnBaleDrop * MathUtil.sign(rot[i]) * (rot[i] % (2 * math.pi))
				end

				setRotation(wrapAnimNode.nodeId, rot[1], rot[2], rot[3])
			end
		end
	end
end

function BaleWrapper:updateWrappingState(t, noEventSend)
	local spec = self.spec_baleWrapper
	t = math.min(t, 1)
	local wrapperRot = 0

	if spec.currentWrapper.animCurve ~= nil then
		local v = spec.currentWrapper.animCurve:get(t)

		if v ~= nil then
			setRotation(spec.currentWrapper.baleNode, v[1] % (math.pi * 2), v[2] % (math.pi * 2), v[3] % (math.pi * 2))
			setRotation(spec.currentWrapper.wrapperNode, v[4] % (math.pi * 2), v[5] % (math.pi * 2), v[6] % (math.pi * 2))

			wrapperRot = v[3 + spec.currentWrapper.wrapperRotAxis]
		elseif spec.currentWrapper.animations.wrapBale.animName ~= nil then
			t = self:getAnimationTime(spec.currentWrapper.animations.wrapBale.animName)
		end

		if spec.currentWrapper.currentBale ~= nil then
			local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)

			if bale ~= nil and not self:getIsBaleFillTypeSkiped(bale) then
				if self.isServer then
					local wrappingState = t

					if table.getn(spec.currentWrapper.wrappingStateCurve.keyframes) > 0 then
						wrappingState = spec.currentWrapper.wrappingStateCurve:get(t)
					end

					bale:setWrappingState(wrappingState)
				end

				if bale.setColor ~= nil then
					local color = ConfigurationUtil.getColorByConfigId(self, "wrappingColor")

					if color ~= nil then
						local r, g, b, a = unpack(color)

						bale:setColor(r, g, b, a)
					end
				end
			end
		end
	end

	self:updateWrapNodes(t > 0, false, t, wrapperRot)

	if t == 1 and self.isServer and spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_WRAPPING_BALE and not noEventSend then
		g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED), true, nil, self)
	end
end

function BaleWrapper:playMoveToWrapper(bale)
	local spec = self.spec_baleWrapper
	spec.currentWrapper = spec.roundBaleWrapper

	if bale.baleDiameter == nil then
		spec.currentWrapper = spec.squareBaleWrapper
	end

	if spec.currentWrapper.animations.moveToWrapper.animName ~= nil then
		self:playAnimation(spec.currentWrapper.animations.moveToWrapper.animName, spec.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
	end
end

function BaleWrapper:doStateChange(id, nearestBaleServerId)
	local spec = self.spec_baleWrapper

	if (id == BaleWrapper.CHANGE_WRAPPING_START or spec.baleWrapperState ~= BaleWrapper.STATE_WRAPPER_FINSIHED and id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE) and self:getIsBaleFillTypeSkiped(NetworkUtil.getObject(spec.currentWrapper.currentBale)) then
		if self.isServer then
			spec.setWrappingStateFinished = true
		end

		return
	end

	if id == BaleWrapper.CHANGE_GRAB_BALE then
		local bale = NetworkUtil.getObject(nearestBaleServerId)
		spec.baleGrabber.currentBale = nearestBaleServerId

		if bale ~= nil then
			local x, y, z = localToLocal(bale.nodeId, getParent(spec.baleGrabber.grabNode), 0, 0, 0)

			setTranslation(spec.baleGrabber.grabNode, x, y, z)
			bale:mount(self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)

			spec.baleToMount = nil

			spec:playMoveToWrapper(bale)
		else
			spec.baleToMount = {
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

		spec.baleWrapperState = BaleWrapper.STATE_MOVING_BALE_TO_WRAPPER
	elseif id == BaleWrapper.CHANGE_DROP_BALE_AT_GRABBER then
		local attachNode = spec.currentWrapper.baleNode
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			bale:mount(self, attachNode, 0, 0, 0, 0, 0, 0)

			spec.baleToMount = nil
		else
			spec.baleToMount = {
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

		self:updateWrapNodes(true, false, 0)

		spec.currentWrapper.currentBale = spec.baleGrabber.currentBale
		spec.baleGrabber.currentBale = nil

		if spec.currentWrapper.animations.moveToWrapper.animName ~= nil and spec.currentWrapper.animations.moveToWrapper.reverseAfterMove then
			self:playAnimation(spec.currentWrapper.animations.moveToWrapper.animName, -spec.currentWrapper.animations.moveToWrapper.animSpeed, nil, true)
		end

		spec.baleWrapperState = BaleWrapper.STATE_MOVING_GRABBER_TO_WORK
	elseif id == BaleWrapper.CHANGE_WRAPPING_START then
		spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_WRAPPING_BALE

		if self.isClient then
			g_soundManager:playSample(spec.currentWrapper.samples.start)
			g_soundManager:playSample(spec.currentWrapper.samples.wrap, 0, spec.currentWrapper.samples.start)
		end

		if spec.currentWrapper.animations.wrapBale.animName ~= nil then
			self:playAnimation(spec.currentWrapper.animations.wrapBale.animName, spec.currentWrapper.animations.wrapBale.animSpeed, nil, true)
		end

		if self.isServer then
			for _, collision in pairs(spec.currentWrapper.collisions) do
				setCollisionMask(collision.node, collision.activeCollisionMask)
			end
		end
	elseif id == BaleWrapper.CHANGE_WRAPPING_BALE_FINSIHED then
		if self.isClient then
			g_soundManager:stopSample(spec.currentWrapper.samples.wrap)
			g_soundManager:stopSample(spec.currentWrapper.samples.stop)

			if spec.currentWrapper.wrappingSoundEndTime == 1 then
				g_soundManager:playSample(spec.currentWrapper.samples.stop)
			end

			if g_soundManager:getIsSamplePlaying(spec.currentWrapper.samples.start) then
				g_soundManager:stopSample(spec.currentWrapper.samples.start)
			end
		end

		self:updateWrappingState(1, true)

		spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_FINSIHED

		if self:getIsBaleFillTypeSkiped(NetworkUtil.getObject(spec.currentWrapper.currentBale)) then
			self:updateWrappingState(0, true)
		end
	elseif id == BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE then
		self:updateWrapNodes(false, false, 0)

		if spec.currentWrapper.animations.dropFromWrapper.animName ~= nil then
			self:playAnimation(spec.currentWrapper.animations.dropFromWrapper.animName, spec.currentWrapper.animations.dropFromWrapper.animSpeed, nil, true)
		end

		spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_DROPPING_BALE

		if self.isServer then
			for _, collision in pairs(spec.currentWrapper.collisions) do
				setCollisionMask(collision.node, collision.inActiveCollisionMask)
			end
		end
	elseif id == BaleWrapper.CHANGE_WRAPPER_BALE_DROPPED then
		local bale = NetworkUtil.getObject(spec.currentWrapper.currentBale)

		if bale ~= nil then
			bale:unmount()
		end

		spec.lastDroppedBale = bale
		spec.currentWrapper.currentBale = nil
		spec.currentWrapper.currentTime = 0

		if spec.currentWrapper.animations.resetAfterDrop.animName ~= nil then
			self:playAnimation(spec.currentWrapper.animations.resetAfterDrop.animName, spec.currentWrapper.animations.resetAfterDrop.animSpeed, nil, true)
		end

		spec.baleWrapperState = BaleWrapper.STATE_WRAPPER_RESETTING_PLATFORM
	elseif id == BaleWrapper.CHANGE_WRAPPER_PLATFORM_RESET then
		self:updateWrappingState(0)
		self:updateWrapNodes(false, true, 0)

		spec.baleWrapperState = BaleWrapper.STATE_NONE
	elseif id == BaleWrapper.CHANGE_BUTTON_EMPTY then
		assert(self.isServer)

		if spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
			g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE), true, nil, self)
		end
	end
end

function BaleWrapper:getWrapperBaleType(bale)
	local spec = self.spec_baleWrapper
	local baleTypes = nil

	if bale.baleDiameter ~= nil then
		baleTypes = spec.roundBaleWrapper.allowedBaleTypes[bale:getFillType()]
	else
		baleTypes = spec.squareBaleWrapper.allowedBaleTypes[bale:getFillType()]
	end

	if baleTypes ~= nil then
		for _, baleType in pairs(baleTypes) do
			if bale.baleDiameter ~= nil and bale.baleWidth ~= nil then
				if baleType.minBaleDiameter <= bale.baleDiameter and bale.baleDiameter <= baleType.maxBaleDiameter and baleType.minBaleWidth <= bale.baleWidth and bale.baleWidth <= baleType.maxBaleWidth then
					return baleType
				end
			elseif bale.baleHeight ~= nil and bale.baleWidth ~= nil and bale.baleLength ~= nil and baleType.minBaleHeight <= bale.baleHeight and bale.baleHeight <= baleType.maxBaleHeight and baleType.minBaleWidth <= bale.baleWidth and bale.baleWidth <= baleType.maxBaleWidth and baleType.minBaleLength <= bale.baleLength and bale.baleLength <= baleType.maxBaleLength then
				return baleType
			end
		end
	end

	return nil
end

function BaleWrapper:pickupWrapperBale(bale, baleType)
	if baleType ~= nil and bale.i3dFilename ~= baleType.wrapperBaleFilename then
		local x, y, z = getWorldTranslation(bale.nodeId)
		local rx, ry, rz = getWorldRotation(bale.nodeId)
		local fillLevel = bale.fillLevel
		local baleValueScale = bale.baleValueScale
		local baleFarm = bale:getOwnerFarmId()

		bale:delete()

		bale = Bale:new(self.isServer, self.isClient)

		bale:load(baleType.wrapperBaleFilename, x, y, z, rx, ry, rz, fillLevel)

		bale.baleValueScale = baleValueScale

		bale:setOwnerFarmId(baleFarm, true)
		bale:register()
	end

	g_server:broadcastEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(bale)), true, nil, self)
end

function BaleWrapper:getIsBaleFillTypeSkiped(bale)
	if bale == nil then
		return false
	end

	local spec = self.spec_baleWrapper
	local wrapper = spec.roundBaleWrapper

	if not bale.baleDiameter == nil then
		wrapper = spec.squareBaleWrapper
	end

	local isBaleSupported = false

	for fillTypeIndex, baleTypes in pairs(wrapper.allowedBaleTypes) do
		for _, baleType in pairs(baleTypes) do
			if bale.i3dFilename == baleType.wrapperBaleFilename or bale.fillType == fillTypeIndex then
				isBaleSupported = true

				break
			end
		end
	end

	if not isBaleSupported and wrapper.skipUnsupportedBales then
		return true
	end

	return false
end

function BaleWrapper:getBaleInRange(refNode, distance)
	local nearestDistance = distance
	local nearestBale, nearestBaleType = nil

	for _, item in pairs(g_currentMission.itemsToSave) do
		local bale = item.item

		if bale:isa(Bale) then
			local maxDist = nil

			if bale.baleDiameter ~= nil then
				maxDist = math.min(bale.baleDiameter, bale.baleWidth)
			else
				maxDist = math.min(bale.baleLength, bale.baleHeight, bale.baleWidth)
			end

			local _, _, z = localToLocal(bale.nodeId, refNode, 0, 0, 0)

			if math.abs(z) < maxDist and calcDistanceFrom(refNode, bale.nodeId) < nearestDistance then
				local foundBaleType = nil

				if not bale.supportsWrapping or bale.wrappingState < 0.99 then
					foundBaleType = self:getWrapperBaleType(bale)
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

	return nearestBale, nearestBaleType
end

function BaleWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_baleWrapper

	if spec.baleWrapperState ~= BaleWrapper.STATE_NONE then
		return false
	end

	return superFunc(self, direction, onAiTurnOn)
end

function BaleWrapper:getCanBeSelected(superFunc)
	return true
end

function BaleWrapper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_baleWrapper

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleWrapper.actionEventEmpty, true, false, false, true, nil)

			g_inputBinding:setActionEventText(actionEventId, g_i18n:getText(spec.currentWrapper.unloadBaleText, self.customEnvironment))
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		end
	end
end

function BaleWrapper:onDeactivate()
	local spec = self.spec_baleWrapper
	spec.showInvalidBaleWarning = false

	if self.isClient then
		for _, sample in pairs(spec.currentWrapper.samples) do
			g_soundManager:stopSample(sample)
		end
	end
end

function BaleWrapper:actionEventEmpty(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_baleWrapper

	if spec.baleWrapperState == BaleWrapper.STATE_WRAPPER_FINSIHED then
		g_client:getServerConnection():sendEvent(BaleWrapperStateEvent:new(self, BaleWrapper.CHANGE_BUTTON_EMPTY))
	end
end
