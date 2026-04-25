source("dataS/scripts/vehicles/specializations/events/FoldableSetFoldDirectionEvent.lua")

Foldable = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onFoldStateChanged")
	end
}

function Foldable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setFoldDirection", Foldable.setFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "setFoldState", Foldable.setFoldState)
	SpecializationUtil.registerFunction(vehicleType, "getIsUnfolded", Foldable.getIsUnfolded)
	SpecializationUtil.registerFunction(vehicleType, "getFoldAnimTime", Foldable.getFoldAnimTime)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldAllowed", Foldable.getIsFoldAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldMiddleAllowed", Foldable.getIsFoldMiddleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldDirection", Foldable.getToggledFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldMiddleDirection", Foldable.getToggledFoldMiddleDirection)
	SpecializationUtil.registerFunction(vehicleType, "registerControlledAction", Foldable.registerControlledAction)
end

function Foldable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "allowLoadMovingToolStates", Foldable.allowLoadMovingToolStates)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Foldable.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Foldable.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCompensationNodeFromXML", Foldable.loadCompensationNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCompensationAngleScale", Foldable.getCompensationAngleScale)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicWheelDataFromXML", Foldable.loadDynamicWheelDataFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVersatileYRotActive", Foldable.getIsVersatileYRotActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Foldable.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Foldable.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadLevelerNodeFromXML", Foldable.loadLevelerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLevelerPickupNodeActive", Foldable.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", Foldable.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", Foldable.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Foldable.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Foldable.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInWorkPosition", Foldable.getIsInWorkPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Foldable.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Foldable.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Foldable.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Foldable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Foldable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", Foldable.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelfLoweringActionEvent", Foldable.registerSelfLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundAdjustedNodeFromXML", Foldable.loadGroundAdjustedNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundAdjustedNodeActive", Foldable.getIsGroundAdjustedNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSprayTypeFromXML", Foldable.loadSprayTypeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSprayTypeActive", Foldable.getIsSprayTypeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Foldable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", Foldable.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInputAttacherActive", Foldable.getIsInputAttacherActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalCharacterFromXML", Foldable.loadAdditionalCharacterFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAdditionalCharacterActive", Foldable.getIsAdditionalCharacterActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountObjects", Foldable.getAllowDynamicMountObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSupportAnimationFromXML", Foldable.loadSupportAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSupportAnimationAllowed", Foldable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSteeringAxleFromXML", Foldable.loadSteeringAxleFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSteeringAxleAllowed", Foldable.getIsSteeringAxleAllowed)
end

function Foldable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLoweredAll", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Foldable)
end

function Foldable.initSpecialization()
	g_configurationManager:addConfigurationType("folding", g_i18n:getText("configuration_folding"), "foldable", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_storeManager:addSpecType("workingWidthVar", "shopListAttributeIconWorkingWidth", Foldable.loadSpecValueWorkingWidth, Foldable.getSpecValueWorkingWidth)
end

function Foldable:onLoad(savegame)
	local spec = self.spec_foldable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.foldingParts", "vehicle.foldable.foldingConfigurations.foldingConfiguration.foldingParts")

	local foldingConfigurationId = Utils.getNoNil(self.configurations.folding, 1)
	local configKey = string.format("vehicle.foldable.foldingConfigurations.foldingConfiguration(%d).foldingParts", foldingConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.foldable.foldingConfigurations.foldingConfiguration", foldingConfigurationId, self.components, self)

	if not hasXMLProperty(self.xmlFile, configKey) then
		configKey = "vehicle.foldable.foldingParts"
	end

	spec.posDirectionText = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#posDirectionText"), "action_foldOBJECT")
	spec.negDirectionText = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#negDirectionText"), "action_unfoldOBJECT")
	spec.middlePosDirectionText = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#middlePosDirectionText"), "action_liftOBJECT")
	spec.middleNegDirectionText = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#middleNegDirectionText"), "action_lowerOBJECT")
	spec.startAnimTime = getXMLFloat(self.xmlFile, configKey .. "#startAnimTime")
	spec.foldMoveDirection = 0
	spec.moveToMiddle = false

	if spec.startAnimTime == nil then
		spec.startAnimTime = 0
		local startMoveDirection = Utils.getNoNil(getXMLInt(self.xmlFile, configKey .. "#startMoveDirection"), 0)

		if startMoveDirection > 0.1 then
			spec.startAnimTime = 1
		end
	end

	spec.turnOnFoldDirection = 1

	if spec.startAnimTime > 0.5 then
		spec.turnOnFoldDirection = -1
	end

	spec.turnOnFoldDirection = MathUtil.sign(Utils.getNoNil(getXMLInt(self.xmlFile, configKey .. "#turnOnFoldDirection"), spec.turnOnFoldDirection))
	spec.allowUnfoldingByAI = Utils.getNoNil(getXMLBool(self.xmlFile, configKey .. "#allowUnfoldingByAI"), true)
	local foldInputButtonStr = getXMLString(self.xmlFile, configKey .. "#foldInputButton")

	if foldInputButtonStr ~= nil then
		spec.foldInputButton = InputAction[foldInputButtonStr]
	end

	spec.foldInputButton = Utils.getNoNil(spec.foldInputButton, InputAction.IMPLEMENT_EXTRA2)
	local foldMiddleInputButtonStr = getXMLString(self.xmlFile, configKey .. "#foldMiddleInputButton")

	if foldMiddleInputButtonStr ~= nil then
		spec.foldMiddleInputButton = InputAction[foldMiddleInputButtonStr]
	end

	spec.foldMiddleInputButton = Utils.getNoNil(spec.foldMiddleInputButton, InputAction.LOWER_IMPLEMENT)
	spec.foldMiddleAnimTime = getXMLFloat(self.xmlFile, configKey .. "#foldMiddleAnimTime")
	spec.foldMiddleDirection = Utils.getNoNil(getXMLInt(self.xmlFile, configKey .. "#foldMiddleDirection"), 1)
	spec.foldMiddleAIRaiseDirection = Utils.getNoNil(getXMLInt(self.xmlFile, configKey .. "#foldMiddleAIRaiseDirection"), spec.foldMiddleDirection)
	spec.turnOnFoldMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#turnOnFoldMaxLimit"), 1)
	spec.turnOnFoldMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#turnOnFoldMinLimit"), 0)
	spec.toggleCoverMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#toggleCoverMaxLimit"), 1)
	spec.toggleCoverMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#toggleCoverMinLimit"), 0)
	spec.detachingMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#detachingMaxLimit"), 1)
	spec.detachingMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#detachingMinLimit"), 0)
	spec.allowDetachingWhileFolding = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#allowDetachingWhileFolding"), false)
	spec.loweringMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#loweringMaxLimit"), 1)
	spec.loweringMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#loweringMinLimit"), 0)
	spec.loadMovingToolStatesMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#loadMovingToolStatesMaxLimit"), 1)
	spec.loadMovingToolStatesMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#loadMovingToolStatesMinLimit"), 0)
	spec.dynamicMountMinLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#dynamicMountMinLimit"), 0)
	spec.dynamicMountMaxLimit = Utils.getNoNil(getXMLFloat(self.xmlFile, configKey .. "#dynamicMountMaxLimit"), 1)
	spec.unfoldWarning = string.format(g_i18n:getText(Utils.getNoNil(getXMLString(self.xmlFile, configKey .. "#unfoldWarning"), "warning_firstUnfoldTheTool"), self.customEnvironment), self.typeDesc)
	spec.foldAnimTime = 0
	spec.maxFoldAnimDuration = 0.0001
	spec.foldingParts = {}
	local i = 0

	while true do
		local baseName = string.format(configKey .. ".foldingPart(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseName) then
			break
		end

		local isValid = false
		local entry = {
			speedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, baseName .. "#speedScale"), 1)
		}
		local componentJointIndex = getXMLInt(self.xmlFile, baseName .. "#componentJointIndex")
		local componentJoint = nil

		if componentJointIndex ~= nil then
			if componentJointIndex == 0 then
				componentJointIndex = nil

				g_logManager:xmlWarning(self.configFileName, "Invalid componentJointIndex for folding part '%s'. Indexing starts with 1!", baseName)
			else
				componentJoint = self.componentJoints[componentJointIndex]
				entry.componentJoint = componentJoint
			end
		end

		entry.anchorActor = Utils.getNoNil(getXMLInt(self.xmlFile, baseName .. "#anchorActor"), 0)
		entry.animCharSet = 0
		local rootNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseName .. "#rootNode"), self.i3dMappings)

		if rootNode ~= nil then
			local animCharSet = getAnimCharacterSet(rootNode)

			if animCharSet ~= 0 then
				local clip = getAnimClipIndex(animCharSet, getXMLString(self.xmlFile, baseName .. "#animationClip"))

				if clip >= 0 then
					isValid = true
					entry.animCharSet = animCharSet

					assignAnimTrackClip(entry.animCharSet, 0, clip)
					setAnimTrackLoopState(entry.animCharSet, 0, false)

					entry.animDuration = getAnimClipDuration(entry.animCharSet, clip)
				end
			end
		end

		if not isValid then
			local specAnimatedVehicle = self.spec_animatedVehicle

			if specAnimatedVehicle ~= nil then
				local animationName = getXMLString(self.xmlFile, baseName .. "#animationName")

				if animationName ~= nil and specAnimatedVehicle.animations[animationName] ~= nil then
					isValid = true
					entry.animDuration = self:getAnimationDuration(animationName)
					entry.animationName = animationName
				end
			end
		end

		if isValid then
			spec.maxFoldAnimDuration = math.max(spec.maxFoldAnimDuration, entry.animDuration)

			if componentJoint ~= nil then
				local node = self.components[componentJoint.componentIndices[(entry.anchorActor + 1) % 2 + 1]].node
				entry.x, entry.y, entry.z = worldToLocal(componentJoint.jointNode, getWorldTranslation(node))
				entry.upX, entry.upY, entry.upZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 1, 0))
				entry.dirX, entry.dirY, entry.dirZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 0, 1))
			end

			table.insert(spec.foldingParts, entry)
		end

		i = i + 1
	end

	if table.getn(spec.foldingParts) > 0 then
		self.isSelectable = true
	end

	spec.actionEventsLowering = {}

	if savegame ~= nil and not savegame.resetVehicles then
		spec.loadedFoldAnimTime = getXMLFloat(savegame.xmlFile, savegame.key .. ".foldable#foldAnimTime")
	end

	if spec.loadedFoldAnimTime == nil then
		spec.loadedFoldAnimTime = spec.startAnimTime
	end

	if spec.loadedFoldAnimTime <= 0 then
		spec.foldMoveDirection = -1
	else
		spec.foldMoveDirection = 1
	end
end

function Foldable:onPostLoad(savegame)
	local spec = self.spec_foldable

	Foldable.setAnimTime(self, spec.loadedFoldAnimTime, false)

	if not SpecializationUtil.hasSpecialization(Attachable, self.specializations) then
		self:registerControlledAction()
	end
end

function Foldable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_foldable

	setXMLFloat(xmlFile, key .. "#foldAnimTime", spec.foldAnimTime)
end

function Foldable:onReadStream(streamId, connection)
	local direction = streamReadUIntN(streamId, 2) - 1
	local moveToMiddle = streamReadBool(streamId)
	local animTime = streamReadFloat32(streamId)

	Foldable.setAnimTime(self, animTime, false)
	self:setFoldState(direction, moveToMiddle, true)
end

function Foldable:onWriteStream(streamId, connection)
	local spec = self.spec_foldable
	local direction = MathUtil.sign(spec.foldMoveDirection) + 1

	streamWriteUIntN(streamId, direction, 2)
	streamWriteBool(streamId, spec.moveToMiddle)
	streamWriteFloat32(streamId, spec.foldAnimTime)
end

function Foldable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_foldable

	if self.isClient then
		Foldable.updateActionEventFold(self)

		if spec.foldMiddleAnimTime ~= nil then
			Foldable.updateActionEventFoldMiddle(self)
		end
	end

	if math.abs(spec.foldMoveDirection) > 0.1 then
		local isInvalid = false
		local foldAnimTime = 0

		if spec.foldMoveDirection < -0.1 then
			foldAnimTime = 1
		end

		for _, foldingPart in pairs(spec.foldingParts) do
			local charSet = foldingPart.animCharSet

			if spec.foldMoveDirection > 0 then
				local animTime = nil

				if charSet ~= 0 then
					animTime = getAnimTrackTime(charSet, 0)
				else
					animTime = self:getRealAnimationTime(foldingPart.animationName)
				end

				if animTime < foldingPart.animDuration then
					isInvalid = true
				end

				foldAnimTime = math.max(foldAnimTime, animTime / spec.maxFoldAnimDuration)
			elseif spec.foldMoveDirection < 0 then
				local animTime = nil

				if charSet ~= 0 then
					animTime = getAnimTrackTime(charSet, 0)
				else
					animTime = self:getRealAnimationTime(foldingPart.animationName)
				end

				if animTime > 0 then
					isInvalid = true
				end

				foldAnimTime = math.min(foldAnimTime, animTime / spec.maxFoldAnimDuration)
			end
		end

		spec.foldAnimTime = MathUtil.clamp(foldAnimTime, 0, 1)

		if isInvalid and self.isServer then
			for _, foldingPart in pairs(spec.foldingParts) do
				if foldingPart.componentJoint ~= nil then
					self:setComponentJointFrame(foldingPart.componentJoint, foldingPart.anchorActor)
				end
			end
		end
	end
end

function Foldable:setFoldDirection(direction, noEventSend)
	self:setFoldState(direction, false, noEventSend)
end

function Foldable:setFoldState(direction, moveToMiddle, noEventSend)
	local spec = self.spec_foldable

	if spec.foldMiddleAnimTime == nil then
		moveToMiddle = false
	end

	if spec.foldMoveDirection ~= direction or spec.moveToMiddle ~= moveToMiddle then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(FoldableSetFoldDirectionEvent:new(self, direction, moveToMiddle), nil, , self)
			else
				g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent:new(self, direction, moveToMiddle))
			end
		end

		spec.foldMoveDirection = direction
		spec.moveToMiddle = moveToMiddle

		for _, foldingPart in pairs(spec.foldingParts) do
			local speedScale = nil

			if spec.foldMoveDirection > 0.1 then
				if not spec.moveToMiddle or spec.foldAnimTime < spec.foldMiddleAnimTime then
					speedScale = foldingPart.speedScale
				end
			elseif spec.foldMoveDirection < -0.1 and (not spec.moveToMiddle or spec.foldMiddleAnimTime < spec.foldAnimTime) then
				speedScale = -foldingPart.speedScale
			end

			local charSet = foldingPart.animCharSet

			if charSet ~= 0 then
				if speedScale ~= nil then
					if speedScale > 0 then
						if getAnimTrackTime(charSet, 0) < 0 then
							setAnimTrackTime(charSet, 0, 0)
						end
					elseif foldingPart.animDuration < getAnimTrackTime(charSet, 0) then
						setAnimTrackTime(charSet, 0, foldingPart.animDuration)
					end

					setAnimTrackSpeedScale(charSet, 0, speedScale)
					enableAnimTrack(charSet, 0)
				else
					disableAnimTrack(charSet, 0)
				end
			else
				local animTime = nil

				if self:getIsAnimationPlaying(foldingPart.animationName) then
					animTime = self:getAnimationTime(foldingPart.animationName)
				else
					animTime = spec.foldAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)
				end

				self:stopAnimation(foldingPart.animationName, true)

				if speedScale ~= nil then
					self:playAnimation(foldingPart.animationName, speedScale, animTime, true)

					if moveToMiddle then
						local stopAnimTime = spec.foldMiddleAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)

						self:setAnimationStopTime(foldingPart.animationName, stopAnimTime)
					end
				end
			end
		end

		if spec.foldMoveDirection > 0.1 then
			spec.foldAnimTime = math.min(spec.foldAnimTime + 0.0001, math.max(spec.foldAnimTime, 1))
		elseif spec.foldMoveDirection < -0.1 then
			spec.foldAnimTime = math.max(spec.foldAnimTime - 0.0001, math.min(spec.foldAnimTime, 0))
		end

		SpecializationUtil.raiseEvent(self, "onFoldStateChanged", direction, moveToMiddle)
	end
end

function Foldable:getIsUnfolded()
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 then
		if spec.foldMiddleAnimTime ~= nil then
			if spec.turnOnFoldDirection == -1 and spec.foldAnimTime < spec.foldMiddleAnimTime + 0.01 or spec.turnOnFoldDirection == 1 and spec.foldAnimTime > spec.foldMiddleAnimTime - 0.01 then
				return true
			else
				return false
			end
		elseif spec.turnOnFoldDirection == -1 and spec.foldAnimTime == 0 or spec.turnOnFoldDirection == 1 and spec.foldAnimTime == 1 then
			return true
		else
			return false
		end
	else
		return true
	end
end

function Foldable:getFoldAnimTime()
	local spec = self.spec_foldable

	return spec.loadedFoldAnimTime or spec.foldAnimTime
end

function Foldable:getIsFoldAllowed(direction, onAiTurnOn)
	if self.getAttacherVehicle ~= nil and self:getAttacherVehicle() ~= nil then
		local inputAttacherJoint = self:getActiveInputAttacherJoint()

		if inputAttacherJoint.foldMinLimit ~= nil and inputAttacherJoint.foldMaxLimit ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if foldAnimTime < inputAttacherJoint.foldMinLimit or inputAttacherJoint.foldMaxLimit < foldAnimTime then
				return false
			end
		end
	end

	return true
end

function Foldable:getIsFoldMiddleAllowed()
	local spec = self.spec_foldable

	return spec.foldMiddleAnimTime ~= nil
end

function Foldable:getToggledFoldDirection()
	local spec = self.spec_foldable
	local foldMidTime = 0.5

	if spec.foldMiddleAnimTime ~= nil then
		if spec.foldMiddleDirection > 0 then
			foldMidTime = (1 + spec.foldMiddleAnimTime) * 0.5
		else
			foldMidTime = spec.foldMiddleAnimTime * 0.5
		end
	end

	if spec.moveToMiddle then
		return spec.foldMiddleDirection
	elseif spec.foldMoveDirection > 0.1 or spec.foldMoveDirection == 0 and foldMidTime < spec.foldAnimTime then
		return -1
	else
		return 1
	end
end

function Foldable:getToggledFoldMiddleDirection()
	local spec = self.spec_foldable
	local ret = 0

	if spec.foldMiddleAnimTime ~= nil then
		if spec.foldMoveDirection > 0.1 then
			ret = -1
		else
			ret = 1
		end

		if spec.foldMiddleDirection > 0 then
			if spec.foldAnimTime >= spec.foldMiddleAnimTime - 0.01 then
				ret = -1
			end
		elseif spec.foldAnimTime <= spec.foldMiddleAnimTime + 0.01 then
			ret = 1
		end
	end

	return ret
end

function Foldable:allowLoadMovingToolStates(superFunc)
	local spec = self.spec_foldable

	if spec.loadMovingToolStatesMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.loadMovingToolStatesMinLimit then
		return false
	end

	return superFunc(self)
end

function Foldable:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.foldLimitedOuterRange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#foldLimitedOuterRange"), false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if speedRotatingPart.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	speedRotatingPart.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMinLimit"), minFoldLimit)
	speedRotatingPart.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMaxLimit"), maxFoldLimit)

	return true
end

function Foldable:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_foldable

	if not speedRotatingPart.foldLimitedOuterRange then
		if speedRotatingPart.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < speedRotatingPart.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= speedRotatingPart.foldMaxLimit and speedRotatingPart.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Foldable:loadCompensationNodeFromXML(superFunc, compensationNode, xmlFile, key)
	compensationNode.foldAngleScale = getXMLFloat(self.xmlFile, key .. "#foldAngleScale")

	return superFunc(self, compensationNode, xmlFile, key)
end

function Foldable:getCompensationAngleScale(superFunc, compensationNode)
	local scale = superFunc(self, compensationNode)

	if compensationNode.foldAngleScale ~= nil then
		local spec = self.spec_foldable
		local animTime = 1 - spec.foldAnimTime

		if spec.foldMiddleAnimTime ~= nil then
			scale = scale * MathUtil.lerp(compensationNode.foldAngleScale, 1, animTime / (1 - spec.foldMiddleAnimTime))
		else
			scale = scale * MathUtil.lerp(compensationNode.foldAngleScale, 1, animTime)
		end
	end

	return scale
end

function Foldable:loadDynamicWheelDataFromXML(superFunc, xmlFile, key, wheelnamei, wheel)
	local fallbackOldKey = "vehicle.wheels"
	wheel.versatileFoldMinLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#versatileFoldMinLimit", getXMLFloat, 0, nil, fallbackOldKey)
	wheel.versatileFoldMaxLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, wheelnamei, "#versatileFoldMaxLimit", getXMLFloat, 1, nil, fallbackOldKey)

	return superFunc(self, xmlFile, key, wheelnamei, wheel)
end

function Foldable:getIsVersatileYRotActive(superFunc, wheel)
	local spec = self.spec_foldable

	if wheel.versatileFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < wheel.versatileFoldMinLimit then
		return false
	end

	return superFunc(self, wheel)
end

function Foldable:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.foldLimitedOuterRange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#foldLimitedOuterRange"), false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if workArea.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#foldMaxLimit", key .. ".folding#maxLimit")

	workArea.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".folding#minLimit"), minFoldLimit)
	workArea.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".folding#maxLimit"), maxFoldLimit)

	return superFunc(self, workArea, xmlFile, key)
end

function Foldable:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_foldable

	if not workArea.foldLimitedOuterRange then
		if workArea.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < workArea.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= workArea.foldMaxLimit and workArea.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, workArea)
end

function Foldable:loadLevelerNodeFromXML(superFunc, levelerNode, xmlFile, key)
	levelerNode.foldLimitedOuterRange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#foldLimitedOuterRange"), false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if levelerNode.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	levelerNode.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMinLimit"), minFoldLimit)
	levelerNode.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMaxLimit"), maxFoldLimit)

	return superFunc(self, levelerNode, xmlFile, key)
end

function Foldable:getIsLevelerPickupNodeActive(superFunc, levelerNode)
	local spec = self.spec_foldable

	if not levelerNode.foldLimitedOuterRange then
		if levelerNode.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < levelerNode.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= levelerNode.foldMaxLimit and levelerNode.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, levelerNode)
end

function Foldable:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMinLimit"), 0)
	entry.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foldMaxLimit"), 1)

	return true
end

function Foldable:getIsMovingToolActive(superFunc, movingTool)
	local foldAnimTime = self:getFoldAnimTime()

	if movingTool.foldMaxLimit < foldAnimTime or foldAnimTime < movingTool.foldMinLimit then
		return false
	end

	return superFunc(self, movingTool)
end

function Foldable:getCanBeTurnedOn(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.turnOnFoldMinLimit then
		return false
	end

	return superFunc(self)
end

function Foldable:getIsNextCoverStateAllowed(superFunc, nextState)
	if not superFunc(self, nextState) then
		return false
	end

	local spec = self.spec_foldable

	if spec.toggleCoverMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.toggleCoverMinLimit then
		return false
	end

	return true
end

function Foldable:getIsInWorkPosition(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldDirection ~= 0 and table.getn(spec.foldingParts) ~= 0 and (spec.turnOnFoldDirection ~= -1 or spec.foldAnimTime ~= 0) and (spec.turnOnFoldDirection ~= 1 or spec.foldAnimTime ~= 1) then
		return false
	end

	return superFunc(self)
end

function Foldable:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.turnOnFoldMinLimit then
		return spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:isDetachAllowed(superFunc)
	local spec = self.spec_foldable

	if spec.detachingMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.detachingMinLimit then
		return false, spec.unfoldWarning
	end

	if not spec.allowDetachingWhileFolding and spec.foldAnimTime ~= spec.foldMiddleAnimTime and spec.foldAnimTime > 0 and spec.foldAnimTime < 1 then
		return false, spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:getAllowsLowering(superFunc)
	local spec = self.spec_foldable

	if spec.loweringMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.loweringMinLimit then
		return false, spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:getIsLowered(superFunc, default)
	local spec = self.spec_foldable

	if self:getIsFoldMiddleAllowed() and spec.foldMiddleAnimTime ~= nil and spec.foldMiddleInputButton ~= nil then
		if spec.foldMoveDirection ~= 0 then
			if spec.foldMiddleDirection > 0 then
				if spec.foldAnimTime < spec.foldMiddleAnimTime + 0.01 then
					return spec.foldMoveDirection < 0 and spec.moveToMiddle ~= true
				end
			elseif spec.foldAnimTime > spec.foldMiddleAnimTime - 0.01 then
				return spec.foldMoveDirection > 0 and spec.moveToMiddle ~= true
			end
		elseif spec.foldMiddleDirection > 0 and spec.foldAnimTime < 0.01 then
			return true
		elseif spec.foldMiddleDirection < 0 and math.abs(1 - spec.foldAnimTime) < 0.01 then
			return true
		end

		return false
	end

	return superFunc(self, default)
end

function Foldable:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 and spec.foldMiddleAnimTime ~= nil then
		self:clearActionEventsTable(spec.actionEventsLowering)

		local state, actionEventId = self:addActionEvent(spec.actionEventsLowering, spec.foldMiddleInputButton, self, Foldable.actionEventFoldMiddle, false, true, false, true, nil, , ignoreCollisions)

		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		Foldable.updateActionEventFoldMiddle(self)

		if spec.foldMiddleInputButton == inputAction then
			spec.foldMiddleLoweringOverwritten = true

			return state, actionEventId
		end
	end

	return superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Foldable:registerSelfLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	return Foldable.registerLoweringActionEvent(self, superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function Foldable:loadGroundAdjustedNodeFromXML(superFunc, xmlFile, key, adjustedNode)
	if not superFunc(self, xmlFile, key, adjustedNode) then
		return true
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#foldMinLimit", key .. ".foldable#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#foldMaxLimit", key .. ".foldable#maxLimit")

	adjustedNode.foldMinLimit = getXMLFloat(xmlFile, key .. ".foldable#minLimit") or 0
	adjustedNode.foldMaxLimit = getXMLFloat(xmlFile, key .. ".foldable#maxLimit") or 1

	return true
end

function Foldable:getIsGroundAdjustedNodeActive(superFunc, adjustedNode)
	local spec = self.spec_foldable
	local foldAnimTime = spec.foldAnimTime

	if foldAnimTime ~= nil and (adjustedNode.foldMaxLimit < foldAnimTime or foldAnimTime < adjustedNode.foldMinLimit) then
		return false
	end

	return superFunc(self, adjustedNode)
end

function Foldable:loadSprayTypeFromXML(superFunc, xmlFile, key, sprayType)
	sprayType.foldMinLimit = getXMLFloat(self.xmlFile, key .. "#foldMinLimit")
	sprayType.foldMaxLimit = getXMLFloat(self.xmlFile, key .. "#foldMaxLimit")
	sprayType.foldingConfigurationIndex = getXMLInt(self.xmlFile, key .. "#foldingConfigurationIndex")

	return superFunc(self, xmlFile, key, sprayType)
end

function Foldable:getIsSprayTypeActive(superFunc, sprayType)
	local spec = self.spec_foldable

	if sprayType.foldMinLimit ~= nil and sprayType.foldMaxLimit ~= nil then
		local foldAnimTime = spec.foldAnimTime

		if foldAnimTime ~= nil and (sprayType.foldMaxLimit < foldAnimTime or foldAnimTime < sprayType.foldMinLimit) then
			return false
		end
	end

	if sprayType.foldingConfigurationIndex ~= nil and (self.configurations.folding or 1) ~= sprayType.foldingConfigurationIndex then
		return false
	end

	return superFunc(self, sprayType)
end

function Foldable:getCanBeSelected(superFunc)
	return true
end

function Foldable:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, index)
	inputAttacherJoint.foldMinLimit = getXMLFloat(xmlFile, key .. "#foldMinLimit")
	inputAttacherJoint.foldMaxLimit = getXMLFloat(xmlFile, key .. "#foldMaxLimit")

	return superFunc(self, xmlFile, key, inputAttacherJoint, index)
end

function Foldable:getIsInputAttacherActive(superFunc, inputAttacherJoint)
	if inputAttacherJoint.foldMinLimit ~= nil and inputAttacherJoint.foldMaxLimit ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if foldAnimTime < inputAttacherJoint.foldMinLimit or inputAttacherJoint.foldMaxLimit < foldAnimTime then
			return false
		end
	end

	return superFunc(self, inputAttacherJoint)
end

function Foldable:loadAdditionalCharacterFromXML(superFunc, xmlFile)
	local spec = self.spec_enterable
	spec.additionalCharacterFoldMinLimit = getXMLFloat(self.xmlFile, "vehicle.enterable.additionalCharacter#foldMinLimit")
	spec.additionalCharacterFoldMaxLimit = getXMLFloat(self.xmlFile, "vehicle.enterable.additionalCharacter#foldMaxLimit")

	return superFunc(self, xmlFile)
end

function Foldable:getIsAdditionalCharacterActive(superFunc)
	local spec = self.spec_enterable

	if spec.additionalCharacterFoldMinLimit ~= nil and spec.additionalCharacterFoldMaxLimit ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if spec.additionalCharacterFoldMinLimit <= foldAnimTime and foldAnimTime <= spec.additionalCharacterFoldMaxLimit then
			return true
		end
	end

	return superFunc(self)
end

function Foldable:getAllowDynamicMountObjects(superFunc)
	local spec = self.spec_foldable
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.dynamicMountMinLimit or spec.dynamicMountMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self)
end

function Foldable:loadSupportAnimationFromXML(superFunc, supportAnimation, xmlFile, key)
	supportAnimation.foldMinLimit = getXMLFloat(xmlFile, key .. "#foldMinLimit") or 0
	supportAnimation.foldMaxLimit = getXMLFloat(xmlFile, key .. "#foldMaxLimit") or 1

	return superFunc(self, supportAnimation, xmlFile, key)
end

function Foldable:getIsSupportAnimationAllowed(superFunc, supportAnimation)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < supportAnimation.foldMinLimit or supportAnimation.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, supportAnimation)
end

function Foldable:loadSteeringAxleFromXML(superFunc, spec, xmlFile, key)
	spec.foldMinLimit = getXMLFloat(xmlFile, key .. "#foldMinLimit") or 0
	spec.foldMaxLimit = getXMLFloat(xmlFile, key .. "#foldMaxLimit") or 1

	return superFunc(self, spec, xmlFile, key)
end

function Foldable:getIsSteeringAxleAllowed(superFunc)
	local spec = self.spec_attachable
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self)
end

function Foldable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_foldable

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local isOnlyLowering = spec.foldMiddleAnimTime ~= nil and spec.foldMiddleAnimTime == 1

			if table.getn(spec.foldingParts) > 0 and not isOnlyLowering then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.foldInputButton, self, Foldable.actionEventFold, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
				Foldable.updateActionEventFold(self)
			end
		end
	end
end

function Foldable:getCanAIImplementContinueWork(superFunc)
	local spec = self.spec_foldable
	local ret = true

	if table.getn(spec.foldingParts) > 0 and spec.allowUnfoldingByAI then
		ret = spec.foldAnimTime == spec.foldMiddleAnimTime or spec.foldAnimTime == 0 or spec.foldAnimTime == 1
	end

	return superFunc(self) and ret
end

function Foldable:onDeactivate()
	if not g_platformSettingsManager:getSetting("keepFoldingWhileDetached", false) then
		self:setFoldDirection(0, true)
	end
end

function Foldable:onSetLoweredAll(doLowering, jointDescIndex)
	local spec = self.spec_foldable

	if spec.foldMiddleAnimTime ~= nil and self:getIsFoldMiddleAllowed() then
		if doLowering then
			self:setFoldState(-spec.foldMiddleAIRaiseDirection, false)
		else
			self:setFoldState(spec.foldMiddleAIRaiseDirection, true)
		end
	end
end

function Foldable:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:registerControlledAction()
end

function Foldable:registerControlledAction()
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 then
		local unfoldedTime = spec.foldMiddleAnimTime

		if unfoldedTime == nil then
			unfoldedTime = 1

			if spec.turnOnFoldDirection < 0 then
				unfoldedTime = 0
			end
		end

		local foldedTime = 0

		if spec.turnOnFoldDirection < 0 then
			foldedTime = 1
		end

		spec.controlledActionFold = self:getRootVehicle().actionController:registerAction("fold", spec.toggleTurnOnInputBinding, 4)

		spec.controlledActionFold:setCallback(self, Foldable.actionControllerFoldEvent)
		spec.controlledActionFold:setFinishedFunctions(self, self.getFoldAnimTime, unfoldedTime, foldedTime)

		if spec.allowUnfoldingByAI then
			spec.controlledActionFold:addAIEventListener(self, "onAIStart", 1)
			spec.controlledActionFold:addAIEventListener(self, "onAIImplementStart", 1)
			spec.controlledActionFold:addAIEventListener(self, "onAIImplementEnd", -1, true)
			spec.controlledActionFold:addAIEventListener(self, "onAIEnd", -1)
		end

		if self:getIsFoldMiddleAllowed() then
			spec.controlledActionLower = self:getRootVehicle().actionController:registerAction("lowerFoldable", spec.toggleTurnOnInputBinding, 3)

			spec.controlledActionLower:setCallback(self, Foldable.actionControllerLowerEvent)
			spec.controlledActionLower:setFinishedFunctions(self, self.getFoldAnimTime, 1 - foldedTime, spec.foldMiddleAnimTime)
			spec.controlledActionLower:setResetOnDeactivation(false)

			if spec.allowUnfoldingByAI then
				spec.controlledActionLower:addAIEventListener(self, "onAIImplementStartLine", 1)
				spec.controlledActionLower:addAIEventListener(self, "onAIImplementEndLine", -1)
			end
		end
	end
end

function Foldable:actionControllerFoldEvent(direction)
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 then
		if self:getIsFoldMiddleAllowed() and spec.foldAnimTime > 0 and spec.foldAnimTime < spec.foldMiddleAnimTime then
			return false
		end

		direction = spec.turnOnFoldDirection * direction

		if self:getIsFoldAllowed(direction, false) then
			if direction == spec.turnOnFoldDirection then
				self:setFoldState(direction, true)
			else
				self:setFoldState(direction, false)
			end

			return true
		end
	end

	return false
end

function Foldable:actionControllerLowerEvent(direction)
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 then
		direction = spec.turnOnFoldDirection * direction

		if self:getIsFoldMiddleAllowed() then
			if direction == spec.turnOnFoldDirection then
				self:setFoldState(direction, false)
			elseif spec.foldMiddleDirection > 0 then
				if spec.foldAnimTime >= spec.foldMiddleAnimTime - 0.01 then
					self:setFoldState(-direction, true)
				else
					self:setFoldState(direction, true)
				end
			elseif spec.foldAnimTime <= spec.foldMiddleAnimTime + 0.01 then
				self:setFoldState(-direction, true)
			else
				self:setFoldState(direction, true)
			end

			return true
		end
	end

	return false
end

function Foldable:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_foldable

	if spec.controlledActionFold ~= nil then
		spec.controlledActionFold:remove()
	end

	if spec.controlledActionLower ~= nil then
		spec.controlledActionLower:remove()
	end
end

function Foldable:setAnimTime(animTime, placeComponents)
	local spec = self.spec_foldable
	spec.foldAnimTime = animTime
	spec.loadedFoldAnimTime = nil

	for _, foldingPart in pairs(spec.foldingParts) do
		if foldingPart.animCharSet ~= 0 then
			enableAnimTrack(foldingPart.animCharSet, 0)
			setAnimTrackTime(foldingPart.animCharSet, 0, spec.foldAnimTime * foldingPart.animDuration, true)
			disableAnimTrack(foldingPart.animCharSet, 0)
		else
			animTime = spec.foldAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)

			self:setAnimationTime(foldingPart.animationName, animTime, true)
		end
	end

	if placeComponents == nil then
		placeComponents = true
	end

	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(placeComponents)
	end

	if placeComponents and self.isServer then
		for _, foldingPart in pairs(spec.foldingParts) do
			if foldingPart.componentJoint ~= nil then
				local componentJoint = foldingPart.componentJoint
				local jointNode = componentJoint.jointNode

				if foldingPart.anchorActor == 1 then
					jointNode = componentJoint.jointNodeActor1
				end

				local node = self.components[componentJoint.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
				local x, y, z = localToWorld(jointNode, foldingPart.x, foldingPart.y, foldingPart.z)
				local upX, upY, upZ = localDirectionToWorld(jointNode, foldingPart.upX, foldingPart.upY, foldingPart.upZ)
				local dirX, dirY, dirZ = localDirectionToWorld(jointNode, foldingPart.dirX, foldingPart.dirY, foldingPart.dirZ)

				setWorldTranslation(node, x, y, z)
				I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
				self:setComponentJointFrame(componentJoint, foldingPart.anchorActor)
			end
		end
	end
end

function Foldable:updateActionEventFold()
	local spec = self.spec_foldable
	local actionEvent = spec.actionEvents[spec.foldInputButton]

	if actionEvent ~= nil then
		local direction = self:getToggledFoldDirection()
		local state = self:getIsFoldAllowed(direction, false)

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)

		if state then
			local text = nil

			if direction == spec.turnOnFoldDirection then
				text = spec.negDirectionText
			else
				text = spec.posDirectionText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText(text, self.customEnvironment), self.typeDesc))
		end
	end
end

function Foldable:updateActionEventFoldMiddle()
	local spec = self.spec_foldable
	local actionEvent = spec.actionEventsLowering[spec.foldMiddleInputButton]

	if actionEvent ~= nil then
		local state = self:getIsFoldMiddleAllowed()

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)

		if state then
			local text = nil

			if self:getToggledFoldMiddleDirection() == spec.foldMiddleDirection then
				text = spec.middlePosDirectionText
			else
				text = spec.middleNegDirectionText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText(text, self.customEnvironment), self.typeDesc))
		end
	end
end

function Foldable:actionEventFold(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 then
		local toggleDirection = self:getToggledFoldDirection()

		if self:getIsFoldAllowed(toggleDirection, false) then
			if toggleDirection == spec.turnOnFoldDirection then
				self:setFoldState(toggleDirection, true)
			else
				self:setFoldState(toggleDirection, false)
			end
		end
	end
end

function Foldable:actionEventFoldMiddle(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_foldable

	if table.getn(spec.foldingParts) > 0 and self:getIsFoldMiddleAllowed() then
		local direction = self:getToggledFoldMiddleDirection()

		if direction ~= 0 then
			if direction == spec.turnOnFoldDirection then
				self:setFoldState(direction, false)
			else
				self:setFoldState(direction, true)
			end

			if self.getAttacherVehicle ~= nil then
				local attacherVehicle = self:getAttacherVehicle()
				local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)

				if attacherJointIndex ~= nil then
					local attacherJoints = attacherVehicle:getAttacherJoints()
					local attacherJoint = attacherJoints[attacherJointIndex]
					attacherJoint.moveDown = direction ~= spec.turnOnFoldDirection
				end
			end
		end
	end

	if spec.foldMiddleLoweringOverwritten ~= nil and spec.foldMiddleLoweringOverwritten then
		AttacherJoints.actionEventLowerImplement(self, actionName, inputValue, callbackState, isAnalog)
	end
end

function Foldable.loadSpecValueWorkingWidth(xmlFile, customEnvironment)
	local workingWidths = {}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.foldable.foldingConfigurations.foldingConfiguration(%d)", i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		workingWidths[i + 1] = getXMLFloat(xmlFile, baseKey .. "#workingWidth")
		i = i + 1
	end

	return workingWidths
end

function Foldable.getSpecValueWorkingWidth(storeItem, realItem, hasRealItem, config, formatted)
	if storeItem.specs.workingWidthVar ~= nil then
		local workingWidth = storeItem.specs.workingWidthVar[config or 1]

		if (formatted == nil or formatted) and workingWidth ~= nil then
			return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(workingWidth, 1, true))
		else
			return workingWidth
		end
	end

	return nil
end
