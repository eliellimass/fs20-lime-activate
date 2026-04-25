source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStartEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStopEvent.lua")

AnimatedVehicle = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onPlayAnimation")
		SpecializationUtil.registerEvent(vehicleType, "onStartAnimation")
		SpecializationUtil.registerEvent(vehicleType, "onFinishAnimation")
		SpecializationUtil.registerEvent(vehicleType, "onStopAnimation")
	end
}

function AnimatedVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimation", AnimatedVehicle.loadAnimation)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimationPart", AnimatedVehicle.loadAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationParts", AnimatedVehicle.initializeAnimationParts)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationPart", AnimatedVehicle.initializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "postInitializeAnimationPart", AnimatedVehicle.postInitializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "playAnimation", AnimatedVehicle.playAnimation)
	SpecializationUtil.registerFunction(vehicleType, "stopAnimation", AnimatedVehicle.stopAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationExists", AnimatedVehicle.getAnimationExists)
	SpecializationUtil.registerFunction(vehicleType, "getIsAnimationPlaying", AnimatedVehicle.getIsAnimationPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getRealAnimationTime", AnimatedVehicle.getRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setRealAnimationTime", AnimatedVehicle.setRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationTime", AnimatedVehicle.getAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationTime", AnimatedVehicle.setAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationDuration", AnimatedVehicle.getAnimationDuration)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationSpeed", AnimatedVehicle.setAnimationSpeed)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationStopTime", AnimatedVehicle.setAnimationStopTime)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationValues", AnimatedVehicle.resetAnimationValues)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationPartValues", AnimatedVehicle.resetAnimationPartValues)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimationPart", AnimatedVehicle.updateAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfActiveAnimations", AnimatedVehicle.getNumOfActiveAnimations)
end

function AnimatedVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", AnimatedVehicle.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", AnimatedVehicle.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", AnimatedVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", AnimatedVehicle.getIsWorkAreaActive)
end

function AnimatedVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AnimatedVehicle)
end

function AnimatedVehicle:onLoad(savegame)
	local spec = self.spec_animatedVehicle
	spec.animations = {}
	local i = 0

	while true do
		local key = string.format("vehicle.animations.animation(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local animation = {}

		if self:loadAnimation(self.xmlFile, key, animation) then
			spec.animations[animation.name] = animation
		end

		i = i + 1
	end

	spec.activeAnimations = {}
	spec.numActiveAnimations = 0
end

function AnimatedVehicle:onPostLoad(savegame)
	local spec = self.spec_animatedVehicle

	for name, animation in pairs(spec.animations) do
		if animation.resetOnStart then
			self:playAnimation(name, -1, nil, true)
			AnimatedVehicle.updateAnimationByName(self, name, 9999999, false)
		end
	end
end

function AnimatedVehicle:onDelete()
	local spec = self.spec_animatedVehicle

	for name, animation in pairs(spec.animations) do
		if self.isClient then
			g_soundManager:deleteSample(animation.sample)
		end
	end
end

function AnimatedVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	AnimatedVehicle.updateAnimations(self, dt)

	if self.spec_animatedVehicle.numActiveAnimations > 0 then
		self:raiseActive()
	end
end

function AnimatedVehicle:loadAnimation(xmlFile, key, animation)
	local name = getXMLString(xmlFile, key .. "#name")

	if name ~= nil then
		animation.name = name
		animation.parts = {}
		animation.currentTime = 0
		animation.currentSpeed = 1
		animation.looping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#looping"), false)
		animation.resetOnStart = Utils.getNoNil(getXMLBool(xmlFile, key .. "#resetOnStart"), true)
		local partI = 0

		while true do
			local partKey = key .. string.format(".part(%d)", partI)

			if not hasXMLProperty(xmlFile, partKey) then
				break
			end

			local animationPart = {}

			if self:loadAnimationPart(xmlFile, partKey, animationPart) then
				table.insert(animation.parts, animationPart)
			end

			partI = partI + 1
		end

		animation.partsReverse = {}

		for _, part in ipairs(animation.parts) do
			table.insert(animation.partsReverse, part)
		end

		table.sort(animation.parts, AnimatedVehicle.animPartSorter)
		table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse)
		self:initializeAnimationParts(animation)

		animation.currentPartIndex = 1
		animation.duration = 0

		for _, part in ipairs(animation.parts) do
			animation.duration = math.max(animation.duration, part.startTime + part.duration)
		end

		if self.isClient then
			animation.sample = g_soundManager:loadSampleFromXML(self.xmlFile, key, "sound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		end

		return true
	end

	return false
end

function AnimatedVehicle:loadAnimationPart(xmlFile, partKey, part)
	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, partKey .. "#node"), self.i3dMappings)
	local startTime = getXMLFloat(xmlFile, partKey .. "#startTime")
	local duration = getXMLFloat(xmlFile, partKey .. "#duration")
	local endTime = getXMLFloat(xmlFile, partKey .. "#endTime")
	local direction = MathUtil.sign(Utils.getNoNil(getXMLInt(xmlFile, partKey .. "#direction"), 0))
	local startRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRot"), 3)
	local endRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRot"), 3)
	local startTrans = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTrans"), 3)
	local endTrans = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTrans"), 3)
	local startScale = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startScale"), 3)
	local endScale = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endScale"), 3)
	local visibility = getXMLBool(xmlFile, partKey .. "#visibility")
	local componentJointIndex = getXMLInt(xmlFile, partKey .. "#componentJointIndex")
	local requiredAnimation = getXMLString(xmlFile, partKey .. "#requiredAnimation")
	local requiredAnimationRange = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#requiredAnimationRange"), 2)

	if componentJointIndex ~= nil and componentJointIndex < 1 then
		g_logManager:warning("Invalid componentJointIndex for animation part '%s'. Indexing starts with 1!", partKey)

		componentJointIndex = nil
	end

	local componentJoint = nil

	if componentJointIndex ~= nil then
		componentJoint = self.componentJoints[componentJointIndex]
	end

	local startRotLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRotLimit"), 3)
	local startRotMinLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRotMinLimit"), 3)
	local startRotMaxLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRotMaxLimit"), 3)

	if startRotLimit ~= nil then
		startRotMinLimit = {}
		startRotMaxLimit = {}

		for i = 1, 3 do
			startRotMinLimit[i] = -startRotLimit[i]
			startRotMaxLimit[i] = startRotLimit[i]
		end
	end

	local endRotLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRotLimit"), 3)
	local endRotMinLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRotMinLimit"), 3)
	local endRotMaxLimit = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRotMaxLimit"), 3)

	if endRotLimit ~= nil then
		endRotMinLimit = {}
		endRotMaxLimit = {}

		for i = 1, 3 do
			endRotMinLimit[i] = -endRotLimit[i]
			endRotMaxLimit[i] = endRotLimit[i]
		end
	end

	local startTransLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTransLimit"), 3)
	local startTransMinLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTransMinLimit"), 3)
	local startTransMaxLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTransMaxLimit"), 3)

	if startTransLimit ~= nil then
		startTransMinLimit = {}
		startTransMaxLimit = {}

		for i = 1, 3 do
			startTransMinLimit[i] = -startTransLimit[i]
			startTransMaxLimit[i] = startTransLimit[i]
		end
	end

	local endTransLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTransLimit"), 3)
	local endTransMinLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTransMinLimit"), 3)
	local endTransMaxLimit = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTransMaxLimit"), 3)

	if endTransLimit ~= nil then
		endTransMinLimit = {}
		endTransMaxLimit = {}

		for i = 1, 3 do
			endTransMinLimit[i] = -endTransLimit[i]
			endTransMaxLimit[i] = endTransLimit[i]
		end
	end

	local shaderParameter = getXMLString(xmlFile, partKey .. "#shaderParameter")
	local shaderStartValues = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#shaderStartValues"), 4)
	local shaderEndValues = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#shaderEndValues"), 4)
	local animationClip = getXMLString(xmlFile, partKey .. "#animationClip")
	local clipStartTime = getXMLFloat(xmlFile, partKey .. "#clipStartTime")
	local clipEndTime = getXMLFloat(xmlFile, partKey .. "#clipEndTime")
	local dependentAnim = getXMLString(xmlFile, partKey .. "#dependentAnimation")
	local dependentAnimStartTime = getXMLFloat(xmlFile, partKey .. "#dependentAnimationStartTime")
	local dependentAnimEndTime = getXMLFloat(xmlFile, partKey .. "#dependentAnimationEndTime")
	local hasTiming = startTime ~= nil and (duration ~= nil or endTime ~= nil)

	if hasTiming then
		if endTime ~= nil then
			duration = endTime - startTime
		end

		part.node = node
		part.startTime = startTime * 1000
		part.duration = duration * 1000
		part.direction = direction
		part.requiredAnimation = requiredAnimation
		part.requiredAnimationRange = requiredAnimationRange

		if node ~= nil then
			if endRot ~= nil then
				part.startRot = startRot
				part.endRot = endRot
			end

			if endTrans ~= nil then
				part.startTrans = startTrans
				part.endTrans = endTrans
			end

			if endScale ~= nil then
				part.startScale = startScale
				part.endScale = endScale
			end

			if shaderParameter ~= nil and shaderEndValues ~= nil and shaderStartValues ~= nil then
				if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParameter) then
					part.shaderParameter = shaderParameter
					part.shaderStartValues = shaderStartValues
					part.shaderEndValues = shaderEndValues
				else
					g_logManager:warning("Node '%s' has no shaderParameter '%s' for animation part '%s'!", getName(node), shaderParameter, partKey)
				end
			end

			if animationClip ~= nil and clipStartTime ~= nil and clipEndTime ~= nil then
				part.animationClip = animationClip
				part.animationCharSet = getAnimCharacterSet(node)
				part.animationClipIndex = getAnimClipIndex(part.animationCharSet, animationClip)
				part.clipStartTime = clipStartTime
				part.clipEndTime = clipEndTime
			end

			part.visibility = visibility
		end

		if dependentAnim ~= nil and dependentAnimStartTime ~= nil and dependentAnimEndTime ~= nil then
			part.dependentAnim = dependentAnim
			part.dependentAnimStartTime = dependentAnimStartTime
			part.dependentAnimEndTime = dependentAnimEndTime
		end

		if self.isServer and componentJoint ~= nil then
			if endRotMinLimit ~= nil then
				part.componentJoint = componentJoint
				part.startRotMinLimit = startRotMinLimit
				part.startRotMaxLimit = startRotMaxLimit
				part.endRotMinLimit = endRotMinLimit
				part.endRotMaxLimit = endRotMaxLimit
			end

			if endTransMinLimit ~= nil then
				part.componentJoint = componentJoint
				part.startTransMinLimit = startTransMinLimit
				part.startTransMaxLimit = startTransMaxLimit
				part.endTransMinLimit = endTransMinLimit
				part.endTransMaxLimit = endTransMaxLimit
			end
		end

		return true
	end

	return false
end

function AnimatedVehicle:initializeAnimationParts(animation)
	local numParts = table.getn(animation.parts)

	for i, part in ipairs(animation.parts) do
		self:initializeAnimationPart(animation, part, i, numParts)
	end

	for i, part in ipairs(animation.parts) do
		self:postInitializeAnimationPart(animation, part, i, numParts)
	end
end

function AnimatedVehicle:initializeAnimationPart(animation, part, i, numParts)
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextRotPart", "prevRotPart", "startRot", "endRot", "rotation")
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextTransPart", "prevTransPart", "startTrans", "endTrans", "translation")
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextScalePart", "prevScalePart", "startScale", "endScale", "scale")
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextShaderPart", "prevShaderPart", "shaderStartValues", "shaderEndValues", "shaderParameter")
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextClipPart", "prevClipPart", "clipStartTime", "clipEndTime", "animation clip")
	AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextDependentAnimPart", "prevDependentAnimPart", "dependentAnimStartTime", "dependentAnimEndTime", "dependent animation", nil, , "dependentAnim")

	if self.isServer then
		AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextRotLimitPart", "prevRotLimitPart", "startRotMinLimit", "endRotMinLimit", "joint rot limit", "startRotMaxLimit", "endRotMaxLimit", "componentJoint")
		AnimatedVehicle.initializeAnimationPartAttribute(self, animation, part, i, numParts, "nextTransLimitPart", "prevTransLimitPart", "startTransMinLimit", "startTransMinLimit", "joint trans limit", "startTransMaxLimit", "endTransMaxLimit", "componentJoint")
	end
end

function AnimatedVehicle:postInitializeAnimationPart(animation, part, i, numParts)
	if part.endRot ~= nil and part.startRot == nil then
		local x, y, z = getRotation(part.node)
		part.startRot = {
			x,
			y,
			z
		}
	end

	if part.endTrans ~= nil and part.startTrans == nil then
		local x, y, z = getTranslation(part.node)
		part.startTrans = {
			x,
			y,
			z
		}
	end

	if part.endScale ~= nil and part.startScale == nil then
		local x, y, z = getScale(part.node)
		part.startScale = {
			x,
			y,
			z
		}
	end

	if self.isServer then
		if part.endRotMinLimit ~= nil and part.startRotMinLimit == nil then
			local rotLimit = part.componentJoint.rotMinLimit
			part.startRotMinLimit = {
				rotLimit[1],
				rotLimit[2],
				rotLimit[3]
			}
		end

		if part.endRotMaxLimit ~= nil and part.startRotMaxLimit == nil then
			local rotLimit = part.componentJoint.rotLimit
			part.startRotMaxLimit = {
				rotLimit[1],
				rotLimit[2],
				rotLimit[3]
			}
		end

		if part.endTransMinLimit ~= nil and part.startTransMinLimit == nil then
			local transLimit = part.componentJoint.transMinLimit
			part.startTransMinLimit = {
				transLimit[1],
				transLimit[2],
				transLimit[3]
			}
		end

		if part.endTransMaxLimit ~= nil and part.startTransMaxLimit == nil then
			local transLimit = part.componentJoint.transLimit
			part.startTransMaxLimit = {
				transLimit[1],
				transLimit[2],
				transLimit[3]
			}
		end
	end
end

function AnimatedVehicle:playAnimation(name, speed, animTime, noEventSend)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onPlayAnimation", name)

		if speed == nil then
			speed = animation.currentSpeed
		end

		if speed == nil or speed == 0 then
			return
		end

		if animTime == nil then
			if self:getIsAnimationPlaying(name) then
				animTime = self:getAnimationTime(name)
			elseif speed > 0 then
				animTime = 0
			else
				animTime = 1
			end
		end

		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(AnimatedVehicleStartEvent:new(self, name, speed, animTime), nil, , self)
			else
				g_client:getServerConnection():sendEvent(AnimatedVehicleStartEvent:new(self, name, speed, animTime))
			end
		end

		if spec.activeAnimations[name] == nil then
			spec.activeAnimations[name] = animation
			spec.numActiveAnimations = spec.numActiveAnimations + 1

			SpecializationUtil.raiseEvent(self, "onStartAnimation", name)
		end

		animation.currentSpeed = speed
		animation.currentTime = animTime * animation.duration

		self:resetAnimationValues(animation)

		if self.isClient then
			g_soundManager:playSample(animation.sample)
		end

		self:raiseActive()
	end
end

function AnimatedVehicle:stopAnimation(name, noEventSend)
	local spec = self.spec_animatedVehicle

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(AnimatedVehicleStopEvent:new(self, name), nil, , self)
		else
			g_client:getServerConnection():sendEvent(AnimatedVehicleStopEvent:new(self, name))
		end
	end

	local animation = spec.animations[name]

	if animation ~= nil then
		SpecializationUtil.raiseEvent(self, "onStopAnimation", name)

		animation.stopTime = nil

		if self.isClient then
			g_soundManager:stopSample(animation.sample)
		end
	end

	if spec.activeAnimations[name] ~= nil then
		spec.numActiveAnimations = spec.numActiveAnimations - 1
		spec.activeAnimations[name] = nil

		SpecializationUtil.raiseEvent(self, "onFinishAnimation", name)
	end
end

function AnimatedVehicle:getAnimationExists(name)
	local spec = self.spec_animatedVehicle

	return spec.animations[name] ~= nil
end

function AnimatedVehicle:getIsAnimationPlaying(name)
	local spec = self.spec_animatedVehicle

	return spec.activeAnimations[name] ~= nil
end

function AnimatedVehicle:getRealAnimationTime(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.currentTime
	end

	return 0
end

function AnimatedVehicle:setRealAnimationTime(name, animTime, update)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		if update == nil or update then
			local currentSpeed = animation.currentSpeed
			animation.currentSpeed = 1

			if animTime < animation.currentTime then
				animation.currentSpeed = -1
			end

			self:resetAnimationValues(animation)

			local dtToUse, _ = AnimatedVehicle.updateAnimationCurrentTime(self, animation, 99999999, animTime)

			AnimatedVehicle.updateAnimation(self, animation, dtToUse, false)

			animation.currentSpeed = currentSpeed
		else
			animation.currentTime = animTime
		end
	end
end

function AnimatedVehicle:getAnimationTime(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.currentTime / animation.duration
	end

	return 0
end

function AnimatedVehicle:setAnimationTime(name, animTime, update)
	local spec = self.spec_animatedVehicle

	if spec.animations == nil then
		printCallstack()
	end

	local animation = spec.animations[name]

	if animation ~= nil then
		self:setRealAnimationTime(name, animTime * animation.duration, update)
	end
end

function AnimatedVehicle:getAnimationDuration(name)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		return animation.duration
	end

	return 1
end

function AnimatedVehicle:setAnimationSpeed(name, speed)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		local speedReversed = false

		if animation.currentSpeed > 0 ~= (speed > 0) then
			speedReversed = true
		end

		animation.currentSpeed = speed

		if self:getIsAnimationPlaying(name) and speedReversed then
			self:resetAnimationValues(animation)
		end
	end
end

function AnimatedVehicle:setAnimationStopTime(name, stopTime)
	local spec = self.spec_animatedVehicle
	local animation = spec.animations[name]

	if animation ~= nil then
		animation.stopTime = stopTime * animation.duration
	end
end

function AnimatedVehicle:resetAnimationValues(animation)
	AnimatedVehicle.findCurrentPartIndex(animation)

	for _, part in ipairs(animation.parts) do
		self:resetAnimationPartValues(part)
	end
end

function AnimatedVehicle:resetAnimationPartValues(part)
	part.curRot = nil
	part.speedRot = nil
	part.curTrans = nil
	part.speedTrans = nil
	part.curScale = nil
	part.speedScale = nil
	part.curVisibility = nil
	part.curRotMinLimit = nil
	part.curRotMaxLimit = nil
	part.speedRotLimit = nil
	part.curTransMinLimit = nil
	part.curTransMaxLimit = nil
	part.speedTransLimit = nil
	part.shaderCurValues = nil
	part.curClipTime = nil
	part.curDependentAnimTime = nil
end

function AnimatedVehicle:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.animName = getXMLString(xmlFile, key .. "#animName")
	speedRotatingPart.animOuterRange = Utils.getNoNil(getXMLBool(xmlFile, key .. "#animOuterRange"), false)
	speedRotatingPart.animMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#animMinLimit"), 0)
	speedRotatingPart.animMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#animMaxLimit"), 1)

	return true
end

function AnimatedVehicle:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.animName ~= nil then
		local animTime = self:getAnimationTime(speedRotatingPart.animName)

		if speedRotatingPart.animOuterRange then
			if speedRotatingPart.animMinLimit < animTime or animTime < speedRotatingPart.animMaxLimit then
				return false
			end
		elseif speedRotatingPart.animMaxLimit < animTime or animTime < speedRotatingPart.animMinLimit then
			return false
		end
	end

	return superFunc(self, speedRotatingPart)
end

function AnimatedVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.animName = getXMLString(xmlFile, key .. "#animName")
	workArea.animMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#animMinLimit"), 0)
	workArea.animMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#animMaxLimit"), 1)

	return superFunc(self, workArea, xmlFile, key)
end

function AnimatedVehicle:getIsWorkAreaActive(superFunc, workArea)
	if workArea.animName ~= nil then
		local animTime = self:getAnimationTime(workArea.animName)

		if workArea.animMaxLimit < animTime or animTime < workArea.animMinLimit then
			return false
		end
	end

	return superFunc(self, workArea)
end

function AnimatedVehicle:initializeAnimationPartAttribute(animation, part, i, numParts, nextName, prevName, startName, endName, warningName, startName2, endName2, additionalCompareParam)
	if part[endName] ~= nil then
		for j = i + 1, numParts do
			local part2 = animation.parts[j]
			local additionalCompare = true

			if additionalCompareParam ~= nil and part[additionalCompareParam] ~= part2[additionalCompareParam] then
				additionalCompare = false
			end

			local sameRequiredRange = true

			if part.requiredAnimation ~= nil and part.requiredAnimation == part2.requiredAnimation then
				for n, v in ipairs(part.requiredAnimationRange) do
					if part2.requiredAnimationRange[n] ~= v then
						sameRequiredRange = false
					end
				end
			end

			if part.direction == part2.direction and part.node == part2.node and part2[endName] ~= nil and additionalCompare and sameRequiredRange then
				if part.direction == part2.direction and part.startTime + part.duration > part2.startTime + 0.001 then
					g_logManager:xmlWarning(self.configFileName, "Overlapping %s parts for node '%s' in animation '%s'", warningName, getName(part.node), animation.name)
				end

				part[nextName] = part2
				part2[prevName] = part

				if part2[startName] == nil then
					part2[startName] = {
						unpack(part[endName])
					}
				end

				if startName2 ~= nil and endName2 ~= nil and part2[startName2] == nil then
					part2[startName2] = {
						unpack(part[endName2])
					}
				end

				break
			end
		end
	end
end

function AnimatedVehicle.animPartSorter(a, b)
	if a.startTime < b.startTime then
		return true
	elseif a.startTime == b.startTime then
		return a.duration < b.duration
	end

	return false
end

function AnimatedVehicle.animPartSorterReverse(a, b)
	local endTimeA = a.startTime + a.duration
	local endTimeB = b.startTime + b.duration

	if endTimeA > endTimeB then
		return true
	elseif endTimeA == endTimeB then
		return b.startTime < a.startTime
	end

	return false
end

function AnimatedVehicle.getMovedLimitedValue(currentValue, destValue, speed, dt)
	local limitF = math.min

	if destValue < currentValue then
		limitF = math.max
	elseif destValue == currentValue then
		return currentValue
	end

	local ret = limitF(currentValue + speed * dt, destValue)

	return ret
end

function AnimatedVehicle.setMovedLimitedValues3(currentValues, destValues, speeds, dt)
	local hasChanged = false

	for i = 1, 3 do
		local newValue = AnimatedVehicle.getMovedLimitedValue(currentValues[i], destValues[i], speeds[i], dt)

		if currentValues[i] ~= newValue then
			hasChanged = true
			currentValues[i] = newValue
		end
	end

	return hasChanged
end

function AnimatedVehicle.setMovedLimitedValues4(currentValues, destValues, speeds, dt)
	local hasChanged = false

	for i = 1, 4 do
		local newValue = AnimatedVehicle.getMovedLimitedValue(currentValues[i], destValues[i], speeds[i], dt)

		if currentValues[i] ~= newValue then
			hasChanged = true
			currentValues[i] = newValue
		end
	end

	return hasChanged
end

function AnimatedVehicle.findCurrentPartIndex(animation)
	if animation.currentSpeed > 0 then
		animation.currentPartIndex = table.getn(animation.parts) + 1

		for i, part in ipairs(animation.parts) do
			if animation.currentTime <= part.startTime + part.duration then
				animation.currentPartIndex = i

				break
			end
		end
	else
		animation.currentPartIndex = table.getn(animation.partsReverse) + 1

		for i, part in ipairs(animation.partsReverse) do
			if part.startTime <= animation.currentTime then
				animation.currentPartIndex = i

				break
			end
		end
	end
end

function AnimatedVehicle.getDurationToEndOfPart(part, anim)
	if anim.currentSpeed > 0 then
		return part.startTime + part.duration - anim.currentTime
	else
		return anim.currentTime - part.startTime
	end
end

function AnimatedVehicle.getNextPartIsPlaying(nextPart, prevPart, anim, default)
	if anim.currentSpeed > 0 then
		if nextPart ~= nil then
			return anim.currentTime < nextPart.startTime
		end
	elseif prevPart ~= nil then
		return prevPart.startTime + prevPart.duration < anim.currentTime
	end

	return default
end

function AnimatedVehicle:updateAnimations(dt, allowRestart)
	local spec = self.spec_animatedVehicle

	for _, anim in pairs(spec.activeAnimations) do
		local dtToUse, stopAnim = AnimatedVehicle.updateAnimationCurrentTime(self, anim, dt, anim.stopTime)

		AnimatedVehicle.updateAnimation(self, anim, dtToUse, stopAnim, allowRestart)
	end
end

function AnimatedVehicle:updateAnimationByName(animName, dt, allowRestart)
	local spec = self.spec_animatedVehicle
	local anim = spec.animations[animName]

	if anim ~= nil then
		local dtToUse, stopAnim = AnimatedVehicle.updateAnimationCurrentTime(self, anim, dt, anim.stopTime)

		AnimatedVehicle.updateAnimation(self, anim, dtToUse, stopAnim, allowRestart)
	end
end

function AnimatedVehicle:updateAnimationCurrentTime(anim, dt, stopTime)
	anim.currentTime = anim.currentTime + dt * anim.currentSpeed
	local absSpeed = math.abs(anim.currentSpeed)
	local dtToUse = dt * absSpeed
	local stopAnim = false

	if stopTime ~= nil then
		if anim.currentSpeed > 0 then
			if stopTime <= anim.currentTime then
				dtToUse = dtToUse - (anim.currentTime - stopTime)
				anim.currentTime = stopTime
				stopAnim = true
			end
		elseif anim.currentTime <= stopTime then
			dtToUse = dtToUse - (stopTime - anim.currentTime)
			anim.currentTime = stopTime
			stopAnim = true
		end
	end

	return dtToUse, stopAnim
end

function AnimatedVehicle:updateAnimation(anim, dtToUse, stopAnim, allowRestart)
	local spec = self.spec_animatedVehicle
	local numParts = table.getn(anim.parts)
	local parts = anim.parts

	if anim.currentSpeed < 0 then
		parts = anim.partsReverse
	end

	if dtToUse > 0 then
		local hasChanged = false
		local nothingToChangeYet = false

		for partI = anim.currentPartIndex, numParts do
			local part = parts[partI]
			local isInRange = true

			if part.requiredAnimation ~= nil then
				local time = self:getAnimationTime(part.requiredAnimation)

				if time < part.requiredAnimationRange[1] or part.requiredAnimationRange[2] < time then
					isInRange = false
				end
			end

			if (part.direction == 0 or part.direction > 0 == (anim.currentSpeed >= 0)) and isInRange then
				local durationToEnd = AnimatedVehicle.getDurationToEndOfPart(part, anim)

				if part.duration < durationToEnd then
					nothingToChangeYet = true

					break
				end

				local realDt = dtToUse

				if anim.currentSpeed > 0 then
					local startT = anim.currentTime - dtToUse

					if startT < part.startTime then
						realDt = dtToUse - part.startTime + startT
					end
				else
					local startT = anim.currentTime + dtToUse
					local endTime = part.startTime + part.duration

					if startT > endTime then
						realDt = dtToUse - (startT - endTime)
					end
				end

				durationToEnd = durationToEnd + realDt

				if self:updateAnimationPart(anim, part, durationToEnd, dtToUse, realDt) then
					if self.setMovingToolDirty ~= nil then
						self:setMovingToolDirty(part.node)
					end

					hasChanged = true
				end
			end

			if partI == anim.currentPartIndex and (anim.currentSpeed > 0 and part.startTime + part.duration < anim.currentTime or anim.currentSpeed <= 0 and anim.currentTime < part.startTime) then
				self:resetAnimationPartValues(part)

				anim.currentPartIndex = anim.currentPartIndex + 1
			end
		end

		if not nothingToChangeYet and not hasChanged and numParts <= anim.currentPartIndex then
			if anim.currentSpeed > 0 then
				anim.currentTime = anim.duration
			else
				anim.currentTime = 0
			end

			stopAnim = true
		end
	end

	if stopAnim or numParts < anim.currentPartIndex or anim.currentPartIndex < 1 then
		if not stopAnim then
			if anim.currentSpeed > 0 then
				anim.currentTime = anim.duration
			else
				anim.currentTime = 0
			end
		end

		anim.currentTime = math.min(math.max(anim.currentTime, 0), anim.duration)
		anim.stopTime = nil

		if spec.activeAnimations[anim.name] ~= nil then
			spec.numActiveAnimations = spec.numActiveAnimations - 1

			if self.isClient then
				g_soundManager:stopSample(spec.activeAnimations[anim.name].sample)
			end

			spec.activeAnimations[anim.name] = nil

			SpecializationUtil.raiseEvent(self, "onFinishAnimation", anim.name)
		end

		if (allowRestart == nil or allowRestart) and anim.looping then
			self:setAnimationTime(anim.name, math.abs(anim.duration - anim.currentTime - 1), true)
			self:playAnimation(anim.name, anim.currentSpeed, nil, true)
		end
	end
end

function AnimatedVehicle:updateAnimationPart(animation, part, durationToEnd, dtToUse, realDt)
	local hasPartChanged = false

	if part.startRot ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextRotPart, part.prevRotPart, animation, true)) then
		local destRot = part.endRot

		if animation.currentSpeed < 0 then
			destRot = part.startRot
		end

		if part.curRot == nil then
			local x, y, z = getRotation(part.node)
			part.curRot = {
				x,
				y,
				z
			}
			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedRot = {
				(destRot[1] - x) * invDuration,
				(destRot[2] - y) * invDuration,
				(destRot[3] - z) * invDuration
			}
		end

		if AnimatedVehicle.setMovedLimitedValues3(part.curRot, destRot, part.speedRot, realDt) then
			setRotation(part.node, part.curRot[1], part.curRot[2], part.curRot[3])

			hasPartChanged = true
		end
	end

	if part.startTrans ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextTransPart, part.prevTransPart, animation, true)) then
		local destTrans = part.endTrans

		if animation.currentSpeed < 0 then
			destTrans = part.startTrans
		end

		if part.curTrans == nil then
			local x, y, z = getTranslation(part.node)
			part.curTrans = {
				x,
				y,
				z
			}
			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedTrans = {
				(destTrans[1] - x) * invDuration,
				(destTrans[2] - y) * invDuration,
				(destTrans[3] - z) * invDuration
			}
		end

		if AnimatedVehicle.setMovedLimitedValues3(part.curTrans, destTrans, part.speedTrans, realDt) then
			setTranslation(part.node, part.curTrans[1], part.curTrans[2], part.curTrans[3])

			hasPartChanged = true
		end
	end

	if part.startScale ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextScalePart, part.prevScalePart, animation, true)) then
		local destScale = part.endScale

		if animation.currentSpeed < 0 then
			destScale = part.startScale
		end

		if part.curScale == nil then
			local x, y, z = getScale(part.node)
			part.curScale = {
				x,
				y,
				z
			}
			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedScale = {
				(destScale[1] - x) * invDuration,
				(destScale[2] - y) * invDuration,
				(destScale[3] - z) * invDuration
			}
		end

		if AnimatedVehicle.setMovedLimitedValues3(part.curScale, destScale, part.speedScale, realDt) then
			setScale(part.node, part.curScale[1], part.curScale[2], part.curScale[3])

			hasPartChanged = true
		end
	end

	if part.shaderParameter ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextShaderPart, part.prevShaderPart, animation, true)) then
		local destValues = part.shaderEndValues

		if animation.currentSpeed < 0 then
			destValues = part.shaderStartValues
		end

		if part.shaderCurValues == nil then
			local x, y, z, w = getShaderParameter(part.node, part.shaderParameter)
			part.shaderCurValues = {
				x,
				y,
				z,
				w
			}
			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedShader = {
				(destValues[1] - x) * invDuration,
				(destValues[2] - y) * invDuration,
				(destValues[3] - z) * invDuration,
				(destValues[4] - w) * invDuration
			}
		end

		if AnimatedVehicle.setMovedLimitedValues4(part.shaderCurValues, destValues, part.speedShader, realDt) then
			setShaderParameter(part.node, part.shaderParameter, part.shaderCurValues[1], part.shaderCurValues[2], part.shaderCurValues[3], part.shaderCurValues[4], false)

			hasPartChanged = true
		end
	end

	if part.animationClip ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextClipPart, part.prevClipPart, animation, true)) then
		local destValue = part.clipEndTime

		if animation.currentSpeed < 0 then
			destValue = part.clipStartTime
		end

		local forceUpdate = false

		if part.curClipTime == nil then
			local oldClipIndex = getAnimTrackAssignedClip(part.animationCharSet, 0)

			clearAnimTrackClip(part.animationCharSet, 0)
			assignAnimTrackClip(part.animationCharSet, 0, part.animationClipIndex)

			part.curClipTime = part.clipStartTime

			if oldClipIndex == part.animationClipIndex then
				part.curClipTime = getAnimTrackTime(part.animationCharSet, 0)
			end

			local invDuration = 1 / math.max(durationToEnd, 0.001)
			part.speedClip = (destValue - part.curClipTime) * invDuration
			forceUpdate = true
		end

		local newTime = AnimatedVehicle.getMovedLimitedValue(part.curClipTime, destValue, part.speedClip, realDt)

		if newTime ~= part.curClipTime or forceUpdate then
			part.curClipTime = newTime

			enableAnimTrack(part.animationCharSet, 0)
			setAnimTrackTime(part.animationCharSet, 0, newTime, true)
			disableAnimTrack(part.animationCharSet, 0)

			hasPartChanged = true
		end
	end

	if part.visibility ~= nil then
		if part.curVisibility == nil then
			part.curVisibility = getVisibility(part.node)
		end

		if part.visibility ~= part.curVisibility then
			part.curVisibility = part.visibility

			setVisibility(part.node, part.visibility)

			hasPartChanged = true
		end
	end

	if part.dependentAnim ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextDependentAnimPart, part.prevDependentAnimPart, animation, true)) then
		if self:getAnimationExists(part.dependentAnim) then
			local destValue = part.dependentAnimEndTime

			if animation.currentSpeed < 0 then
				destValue = part.dependentAnimStartTime
			end

			local forceUpdate = false

			if part.curDependentAnimTime == nil then
				part.curDependentAnimTime = self:getAnimationTime(part.dependentAnim)
				local invDuration = 1 / math.max(durationToEnd, 0.001)
				part.speedDependentAnim = (destValue - part.curDependentAnimTime) * invDuration
				forceUpdate = true
			end

			local newTime = AnimatedVehicle.getMovedLimitedValue(part.curDependentAnimTime, destValue, part.speedDependentAnim, realDt)

			if newTime ~= part.curDependentAnimTime or forceUpdate then
				part.curDependentAnimTime = newTime

				self:setAnimationTime(part.dependentAnim, newTime, true)

				hasPartChanged = true
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Unable to find dependent animation '%s'", part.dependentAnim)
		end
	end

	if self.isServer then
		if part.startRotMinLimit ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextRotLimitPart, part.prevRotLimitPart, animation, true)) then
			local destRotMinLimit = part.endRotMinLimit
			local destRotMaxLimit = part.endRotMaxLimit

			if animation.currentSpeed < 0 then
				destRotMinLimit = part.startRotMinLimit
				destRotMaxLimit = part.startRotMaxLimit
			end

			if part.curRotMinLimit == nil then
				local x, y, z = unpack(part.componentJoint.rotMinLimit)
				part.curRotMinLimit = {
					x,
					y,
					z
				}
				local invDuration = 1 / math.max(durationToEnd, 0.001)
				part.speedRotMinLimit = {
					(destRotMinLimit[1] - x) * invDuration,
					(destRotMinLimit[2] - y) * invDuration,
					(destRotMinLimit[3] - z) * invDuration
				}
			end

			if part.curRotMaxLimit == nil then
				local x, y, z = unpack(part.componentJoint.rotLimit)
				part.curRotMaxLimit = {
					x,
					y,
					z
				}
				local invDuration = 1 / math.max(durationToEnd, 0.001)
				part.speedRotMaxLimit = {
					(destRotMaxLimit[1] - x) * invDuration,
					(destRotMaxLimit[2] - y) * invDuration,
					(destRotMaxLimit[3] - z) * invDuration
				}
			end

			for i = 1, 3 do
				local newRotMinLimit = AnimatedVehicle.getMovedLimitedValue(part.curRotMinLimit[i], destRotMinLimit[i], part.speedRotMinLimit[i], realDt)
				local newRotMaxLimit = AnimatedVehicle.getMovedLimitedValue(part.curRotMaxLimit[i], destRotMaxLimit[i], part.speedRotMaxLimit[i], realDt)

				if newRotMinLimit ~= part.curRotMinLimit[i] or newRotMaxLimit ~= part.curRotMaxLimit[i] then
					part.curRotMinLimit[i] = newRotMinLimit
					part.curRotMaxLimit[i] = newRotMaxLimit

					self:setComponentJointRotLimit(part.componentJoint, i, newRotMinLimit, newRotMaxLimit)

					hasPartChanged = true
				end
			end
		end

		if part.startTransMinLimit ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(part.nextTransLimitPart, part.prevTransLimitPart, animation, true)) then
			local destTransMinLimit = part.endTransMinLimit
			local destTransMaxLimit = part.endTransMaxLimit

			if animation.currentSpeed < 0 then
				destTransMinLimit = part.startTransMinLimit
				destTransMaxLimit = part.startTransMaxLimit
			end

			if part.curTransMinLimit == nil then
				local x, y, z = unpack(part.componentJoint.transMinLimit)
				part.curTransMinLimit = {
					x,
					y,
					z
				}
				local invDuration = 1 / math.max(durationToEnd, 0.001)
				part.speedTransMinLimit = {
					(destTransMinLimit[1] - x) * invDuration,
					(destTransMinLimit[2] - y) * invDuration,
					(destTransMinLimit[3] - z) * invDuration
				}
			end

			if part.curTransMaxLimit == nil then
				local x, y, z = unpack(part.componentJoint.transLimit)
				part.curTransMaxLimit = {
					x,
					y,
					z
				}
				local invDuration = 1 / math.max(durationToEnd, 0.001)
				part.speedTransMaxLimit = {
					(destTransMaxLimit[1] - x) * invDuration,
					(destTransMaxLimit[2] - y) * invDuration,
					(destTransMaxLimit[3] - z) * invDuration
				}
			end

			for i = 1, 3 do
				local newTransMinLimit = AnimatedVehicle.getMovedLimitedValue(part.curTransMinLimit[i], destTransMinLimit[i], part.speedTransMinLimit[i], realDt)
				local newTransMaxLimit = AnimatedVehicle.getMovedLimitedValue(part.curTransMaxLimit[i], destTransMaxLimit[i], part.speedTransMaxLimit[i], realDt)

				if newTransMinLimit ~= part.curTransMinLimit[i] or newTransMaxLimit ~= part.curTransMaxLimit[i] then
					part.curTransMinLimit[i] = newTransMinLimit
					part.curTransMaxLimit[i] = newTransMaxLimit

					self:setComponentJointTransLimit(part.componentJoint, i, newTransMinLimit, newTransMaxLimit)

					hasPartChanged = true
				end
			end
		end
	end

	return hasPartChanged
end

function AnimatedVehicle:getNumOfActiveAnimations()
	return self.spec_animatedVehicle.numActiveAnimations
end
