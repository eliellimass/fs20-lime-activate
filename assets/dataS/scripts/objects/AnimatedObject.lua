source("dataS/scripts/objects/AnimatedObjectEvent.lua")

AnimatedObject = {}
local AnimatedObject_mt = Class(AnimatedObject, Object)

InitStaticObjectClass(AnimatedObject, "AnimatedObject", ObjectIds.OBJECT_ANIMATED_OBJECT)

function AnimatedObject:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or AnimatedObject_mt)
	self.nodeId = 0
	self.isMoving = false
	self.wasPressed = false
	self.controls = {
		active = false,
		posAction = nil,
		negAction = nil,
		posText = nil,
		negText = nil,
		posActionEventId = nil,
		negActionEventId = nil
	}
	self.networkTimeInterpolator = InterpolationTime:new(1.2)
	self.networkAnimTimeInterpolator = InterpolatorValue:new(0)

	return self
end

function AnimatedObject:load(nodeId, xmlFile, key, xmlFilename)
	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	self.baseDirectory = baseDirectory
	self.customEnvironment = modName
	self.nodeId = nodeId
	self.samples = {}
	local success = true
	self.saveId = getXMLString(xmlFile, key .. "#saveId")

	if self.saveId == nil then
		self.saveId = "AnimatedObject_" .. getName(nodeId)
	end

	local animKey = key .. ".animation"
	self.animation = {
		parts = {},
		duration = Utils.getNoNil(getXMLFloat(xmlFile, animKey .. "#duration"), 3) * 1000
	}

	if self.animation.duration == 0 then
		self.animation.duration = 1000
	end

	self.animation.time = 0
	self.animation.direction = 0
	local i = 0

	while true do
		local partKey = string.format("%s.part(%d)", animKey, i)

		if not hasXMLProperty(xmlFile, partKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, partKey .. "#node"))

		if node ~= nil then
			local part = {
				node = node,
				animCurve = AnimCurve:new(linearInterpolatorN)
			}
			local hasFrames = false
			local j = 0

			while true do
				local frameKey = string.format("%s.keyFrame(%d)", partKey, j)

				if not hasXMLProperty(xmlFile, frameKey) then
					break
				end

				local keyTime = getXMLFloat(xmlFile, frameKey .. "#time")
				local keyframe = {
					time = keyTime,
					self:loadFrameValues(xmlFile, frameKey, node)
				}

				part.animCurve:addKeyframe(keyframe)

				hasFrames = true
				j = j + 1
			end

			if hasFrames then
				table.insert(self.animation.parts, part)
			end
		end

		i = i + 1
	end

	local initialTime = Utils.getNoNil(getXMLFloat(xmlFile, animKey .. "#initialTime"), 0) * 1000

	self:setAnimTime(initialTime / self.animation.duration, true)

	local startTime = getXMLFloat(xmlFile, key .. ".openingHours#startTime")
	local endTime = getXMLFloat(xmlFile, key .. ".openingHours#endTime")

	if startTime ~= nil and endTime ~= nil then
		local disableIfClosed = Utils.getNoNil(getXMLBool(xmlFile, key .. ".openingHours#disableIfClosed"), false)
		local closedText = getXMLString(xmlFile, key .. ".openingHours#closedText")

		if closedText ~= nil and g_i18n:hasText(closedText, self.customEnvironment) then
			closedText = g_i18n:getText(closedText, self.customEnvironment)
		end

		self.openingHours = {
			startTime = startTime,
			endTime = endTime,
			disableIfClosed = disableIfClosed,
			closedText = closedText
		}

		g_currentMission.environment:addHourChangeListener(self)
	end

	self.isEnabled = true
	local triggerId = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. ".controls#triggerNode"))

	if triggerId ~= nil then
		self.controls.triggerId = triggerId

		addTrigger(self.controls.triggerId, "triggerCallback", self)

		for i = 0, getNumOfChildren(self.controls.triggerId) - 1 do
			addTrigger(getChildAt(self.controls.triggerId, i), "triggerCallback", self)
		end

		local posAction = getXMLString(xmlFile, key .. ".controls#posAction")

		if posAction ~= nil then
			if InputAction[posAction] then
				self.controls.posAction = posAction
				local posText = getXMLString(xmlFile, key .. ".controls#posText")

				if posText ~= nil then
					if g_i18n:hasText(posText, self.customEnvironment) then
						posText = g_i18n:getText(posText, self.customEnvironment)
					end

					self.controls.posActionText = posText
				end

				local negText = getXMLString(xmlFile, key .. ".controls#negText")

				if negText ~= nil then
					if g_i18n:hasText(negText, self.customEnvironment) then
						negText = g_i18n:getText(negText, self.customEnvironment)
					end

					self.controls.negActionText = negText
				end

				local negAction = getXMLString(xmlFile, key .. ".controls#negAction")

				if negAction ~= nil then
					if InputAction[negAction] then
						self.controls.negAction = negAction
					else
						print("Warning: Negative direction action '" .. negAction .. "' not defined!")
					end
				end
			else
				print("Warning: Positive direction action '" .. posAction .. "' not defined!")
			end
		end
	end

	if g_client ~= nil then
		local soundsKey = key .. ".sounds"
		self.sampleMoving = g_soundManager:loadSampleFromXML(xmlFile, soundsKey, "moving", self.baseDirectory, self.nodeId, 1, AudioGroup.ENVIRONMENT, nil, )
		self.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, soundsKey, "posEnd", self.baseDirectory, self.nodeId, 1, AudioGroup.ENVIRONMENT, nil, )
		self.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, soundsKey, "negEnd", self.baseDirectory, self.nodeId, 1, AudioGroup.ENVIRONMENT, nil, )
	end

	self.animatedObjectDirtyFlag = self:getNextDirtyFlag()

	return success
end

function AnimatedObject:loadFrameValues(xmlFile, key, node)
	local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#translation"))
	local sx, sy, sz = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#scale"))
	local isVisible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#visibility"), true)
	local drx, dry, drz = getRotation(node)
	rx = Utils.getNoNilRad(rx, drx)
	ry = Utils.getNoNilRad(ry, dry)
	rz = Utils.getNoNilRad(rz, drz)
	local dx, dy, dz = getTranslation(node)
	x = Utils.getNoNil(x, dx)
	y = Utils.getNoNil(y, dy)
	z = Utils.getNoNil(z, dz)
	local dsx, dsy, dsz = getScale(node)
	sx = Utils.getNoNil(sx, dsx)
	sy = Utils.getNoNil(sy, dsy)
	sz = Utils.getNoNil(sz, dsz)
	local visibility = 1

	if not isVisible then
		visibility = 0
	end

	return x, y, z, rx, ry, rz, sx, sy, sz, visibility
end

function AnimatedObject:delete()
	self:removeActionEvents()

	if self.controls.triggerId ~= nil then
		removeTrigger(self.controls.triggerId)

		for i = 0, getNumOfChildren(self.controls.triggerId) - 1 do
			removeTrigger(getChildAt(self.controls.triggerId, i))
		end

		self.controls.triggerId = nil
	end

	if self.sampleMoving ~= nil then
		g_soundManager:deleteSample(self.sampleMoving)

		self.sampleMoving = nil
	end

	if self.samplePosEnd ~= nil then
		g_soundManager:deleteSample(self.samplePosEnd)

		self.samplePosEnd = nil
	end

	if self.sampleNegEnd ~= nil then
		g_soundManager:deleteSample(self.sampleNegEnd)

		self.sampleNegEnd = nil
	end

	g_currentMission.environment:removeHourChangeListener(self)
	AnimatedObject:superClass().delete(self)
end

function AnimatedObject:readStream(streamId, connection)
	AnimatedObject:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local animTime = streamReadFloat32(streamId)

		self:setAnimTime(animTime, true)
		self.networkAnimTimeInterpolator:setValue(animTime)
		self.networkTimeInterpolator:reset()
	end
end

function AnimatedObject:writeStream(streamId, connection)
	AnimatedObject:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteFloat32(streamId, self.animation.time)
	end
end

function AnimatedObject:readUpdateStream(streamId, timestamp, connection)
	AnimatedObject:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		self.networkTimeInterpolator:startNewPhaseNetwork()

		local animTime = streamReadFloat32(streamId)

		self.networkAnimTimeInterpolator:setTargetValue(animTime)
	end
end

function AnimatedObject:writeUpdateStream(streamId, connection, dirtyMask)
	AnimatedObject:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.animatedObjectDirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.animation.timeSend)
	end
end

function AnimatedObject:loadFromXMLFile(xmlFile, key)
	local animTime = getXMLFloat(xmlFile, key .. "#time")

	if animTime ~= nil then
		self.animation.direction = Utils.getNoNil(getXMLInt(xmlFile, key .. "#direction"), 0)

		self:setAnimTime(animTime, true)
	end

	AnimatedObject.hourChanged(self)

	return true
end

function AnimatedObject:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#time", self.animation.time)
	setXMLInt(xmlFile, key .. "#direction", self.animation.direction)
end

function AnimatedObject:registerActionEventsWhenInRange()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)

	local _ = nil

	if self.controls.posAction then
		if not self.controls.negAction then
			_, self.controls.posActionEventId = g_inputBinding:registerActionEvent(self.controls.posAction, self, self.onAnimationInputToggle, false, true, false, true)
		elseif self.controls.posAction == self.controls.negAction then
			_, self.controls.posActionEventId = g_inputBinding:registerActionEvent(self.controls.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
		else
			_, self.controls.posActionEventId = g_inputBinding:registerActionEvent(self.controls.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
			_, self.controls.negActionEventId = g_inputBinding:registerActionEvent(self.controls.negAction, self, self.onAnimationInputContinuous, false, false, true, true)
		end
	end

	if self.controls.posActionEventId then
		g_inputBinding:setActionEventTextPriority(self.controls.posActionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventTextVisibility(self.controls.posActionEventId, true)

		if self.controls.posActionText then
			g_inputBinding:setActionEventText(self.controls.posActionEventId, self.controls.posActionText)
		end
	end

	if self.controls.negActionEventId then
		g_inputBinding:setActionEventTextPriority(self.controls.negActionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventTextVisibility(self.controls.negActionEventId, true)

		if self.controls.negActionText then
			g_inputBinding:setActionEventText(self.controls.negActionEventId, self.controls.negActionText)
		end
	end

	g_inputBinding:endActionEventsModification()

	self.controls.active = true
end

function AnimatedObject:updateActionEventTexts()
	if self.controls.posAction and not self.controls.negAction and self.controls.posActionText ~= nil and self.controls.negActionText ~= nil then
		if self.animation.time == 0 or self.animation.direction < 0 then
			g_inputBinding:setActionEventText(self.controls.posActionEventId, self.controls.posActionText)
		else
			g_inputBinding:setActionEventText(self.controls.posActionEventId, self.controls.negActionText)
		end
	end
end

function AnimatedObject:removeActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)
	g_inputBinding:endActionEventsModification()

	self.controls.posActionEventId = nil
	self.controls.negActionEventId = nil
	self.controls.active = false
end

function AnimatedObject:onAnimationInputToggle()
	self.animation.direction = self.animation.direction * -1

	if self.animation.direction == 0 then
		if self.animation.time > 0 then
			self.animation.direction = -1
		else
			self.animation.direction = 1
		end
	end

	if g_server == nil then
		g_client:getServerConnection():sendEvent(AnimatedObjectEvent:new(self, self.animation.direction))
	else
		self:raiseActive()
	end
end

function AnimatedObject:onAnimationInputContinuous(actionName, inputValue)
	local changed = false

	if inputValue ~= 0 then
		if actionName == self.controls.posAction and inputValue > 0 then
			self.wasPressed = true

			if self.animation.direction ~= 1 and self.animation.time ~= 1 then
				self.animation.direction = 1
				changed = true
			end
		elseif actionName == self.controls.negAction or actionName == self.controls.posAction and inputValue < 0 then
			self.wasPressed = true

			if self.animation.direction ~= -1 and self.animation.time ~= 0 then
				self.animation.direction = -1
				changed = true
			end
		end
	elseif self.animation.direction ~= 0 and self.wasPressed then
		self.animation.direction = 0
		changed = true
	end

	if changed then
		if not g_server then
			g_client:getServerConnection():sendEvent(AnimatedObjectEvent:new(self, self.animation.direction))
		else
			self:raiseActive()
		end
	end
end

function AnimatedObject:update(dt)
	AnimatedObject:superClass().update(self, dt)

	local deactivateInput = false

	if self.playerInRange then
		if self.isEnabled then
			if not self.controls.active then
				self:registerActionEventsWhenInRange()
			end

			self:updateActionEventTexts()
		else
			deactivateInput = true

			if self.openingHours ~= nil and self.openingHours.closedText ~= nil then
				g_currentMission:addExtraPrintText(self.openingHours.closedText)
			end
		end
	else
		deactivateInput = true
	end

	if deactivateInput and self.controls.active then
		self:removeActionEvents()
	end

	local finishedAnimation = false

	if self.isServer then
		if self.animation.direction ~= 0 then
			local newAnimTime = MathUtil.clamp(self.animation.time + self.animation.direction * dt / self.animation.duration, 0, 1)

			self:setAnimTime(newAnimTime)

			if newAnimTime == 0 or newAnimTime == 1 then
				self.animation.direction = 0
				finishedAnimation = true
			end
		end

		if self.animation.time ~= self.animation.timeSend then
			self.animation.timeSend = self.animation.time

			self:raiseDirtyFlags(self.animatedObjectDirtyFlag)
		end
	else
		self.networkTimeInterpolator:update(dt)

		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		local animTime = self.networkAnimTimeInterpolator:getInterpolatedValue(interpolationAlpha)
		local newAnimTime = self:setAnimTime(animTime)

		if self.animation.direction ~= 0 then
			if self.animation.direction > 0 then
				if newAnimTime == 1 then
					self.animation.direction = 0
					finishedAnimation = true
				end
			elseif newAnimTime == 0 then
				self.animation.direction = 0
				finishedAnimation = true
			end
		end

		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	if self.sampleMoving ~= nil then
		if self.isMoving and self.animation.direction ~= 0 then
			if not self.sampleMoving.isPlaying then
				g_soundManager:playSample(self.sampleMoving)

				self.sampleMoving.isPlaying = true
			end
		elseif self.sampleMoving.isPlaying then
			g_soundManager:stopSample(self.sampleMoving)

			self.sampleMoving.isPlaying = false
		end
	end

	if finishedAnimation and self.animation.direction == 0 then
		if self.samplePosEnd ~= nil and self.animation.time == 1 then
			g_soundManager:playSample(self.samplePosEnd)
		elseif self.sampleNegEnd ~= nil and self.animation.time == 0 then
			g_soundManager:playSample(self.sampleNegEnd)
		end
	end

	self.isMoving = false

	if self.animation.direction ~= 0 then
		self:raiseActive()
	end
end

function AnimatedObject:setAnimTime(t, omitSound)
	t = MathUtil.clamp(t, 0, 1)

	for _, part in pairs(self.animation.parts) do
		local v = part.animCurve:get(t)

		self:setFrameValues(part.node, v)
	end

	self.animation.time = t
	self.isMoving = true

	return t
end

function AnimatedObject:setFrameValues(node, v)
	setTranslation(node, v[1], v[2], v[3])
	setRotation(node, v[4], v[5], v[6])
	setScale(node, v[7], v[8], v[9])
	setVisibility(node, v[10] == 1)
end

function AnimatedObject:hourChanged()
	if self.isServer then
		local currentHour = g_currentMission.environment.currentHour

		if self.openingHours ~= nil then
			if self.openingHours.startTime <= currentHour and currentHour < self.openingHours.endTime then
				if not self.openingHours.isOpen then
					if self.isServer then
						self.animation.direction = 1

						self:raiseActive()
					end

					self.openingHours.isOpen = true
				end

				if self.openingHours.disableIfClosed then
					self.isEnabled = true
				end
			else
				if self.openingHours.isOpen then
					if self.isServer then
						self.animation.direction = -1

						self:raiseActive()
					end

					self.openingHours.isOpen = false
				end

				if self.openingHours.disableIfClosed then
					self.isEnabled = false
				end
			end
		end
	end
end

function AnimatedObject:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			if self.ownerFarmId == nil or self.ownerFarmId == AccessHandler.EVERYONE or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId) then
				self.playerInRange = g_currentMission.player
			end
		else
			self.playerInRange = nil
		end

		self:raiseActive()
	end
end
