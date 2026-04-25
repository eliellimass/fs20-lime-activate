SoundNode = {}
local SoundNode_mt = Class(SoundNode)

function SoundNode:new(soundNode, group, customMt)
	local self = {}

	setmetatable(self, customMt or SoundNode_mt)

	if not getHasClassId(soundNode, ClassIds.AUDIO_SOURCE) then
		g_logManager:warning("SoundNode '%s' is not an AUDIO_SOURCE!", tostring(getName(soundNode)))

		return nil
	end

	self.soundNode = soundNode
	self.nodes = {}
	self.currentNode = nil
	self.nextNode = nil
	self.outerRange = getAudioSourceRange(soundNode)
	self.innerRange = getAudioSourceInnerRange(soundNode)
	self.nextPlayTime = g_time
	self.nextCheckTime = nil

	local function addSoundSource(node, group)
		local sample = getAudioSourceSample(node)
		local duration = getSampleDuration(sample)

		setSampleGroup(sample, group)

		local volume = getSampleVolume(sample)

		setAudioSourceAutoPlay(node, false)
		stopSample(sample, 0, 0)
		table.insert(self.nodes, {
			index = #self.nodes + 1,
			node = node,
			sample = sample,
			volume = volume,
			duration = duration
		})
	end

	addSoundSource(soundNode, group)

	for i = getNumOfChildren(soundNode) - 1, 0, -1 do
		local child = getChildAt(soundNode, i)

		if getHasClassId(child, ClassIds.AUDIO_SOURCE) then
			setAudioSourceRange(child, self.outerRange)
			setAudioSourceInnerRange(child, self.innerRange)
			addSoundSource(child, group)
		end
	end

	self.retriggerMinDelay = Utils.getNoNil(getUserAttribute(soundNode, "retriggerMinDelay"), 0) * 1000
	self.retriggerMaxDelay = Utils.getNoNil(getUserAttribute(soundNode, "retriggerMaxDelay"), 0) * 1000

	if self.retriggerMinDelay == 0 and #self.nodes == 1 then
		local node = self.nodes[1]
		local newNode = clone(node.node, true, false, false)

		setName(newNode, getName(newNode) .. "_copy")
		addSoundSource(newNode, group)
	end

	local tx, ty, tz = getTranslation(soundNode)
	local rx, ry, rz = getRotation(soundNode)
	self.parent = createTransformGroup("soundGroup_" .. getName(soundNode))

	link(getParent(soundNode), self.parent, getChildIndex(soundNode))
	setTranslation(self.parent, tx, ty, tz)
	setRotation(self.parent, rx, ry, rz)

	for _, soundNode in ipairs(self.nodes) do
		link(self.parent, soundNode.node)
		setTranslation(soundNode.node, 0, 0, 0)
		setRotation(soundNode.node, 0, 0, 0)
	end

	self.playByDay = Utils.getNoNil(getUserAttribute(soundNode, "playByDay"), false)
	self.playByNight = Utils.getNoNil(getUserAttribute(soundNode, "playByNight"), false)

	if not self.playByDay and not self.playByNight then
		g_logManager:warning("Ambient 3D sound '%s' has invalid time state. At least one of the states 'playByDay' or 'playByNight' need to be 'true'", getName(soundNode))
	end

	self.playDuringHail = Utils.getNoNil(getUserAttribute(soundNode, "playDuringHail"), false)
	self.playDuringRain = Utils.getNoNil(getUserAttribute(soundNode, "playDuringRain"), false)
	self.playDuringSun = Utils.getNoNil(getUserAttribute(soundNode, "playDuringSun"), false)

	if not self.playDuringHail and not self.playDuringRain and not self.playDuringSun then
		g_logManager:warning("Ambient 3D sound '%s' has invalid weather state. At least one of the states 'playDuringHail', 'playDuringRain' or 'playDuringSun' need to be 'true'", getName(soundNode))
	end

	self.playInsideBuilding = Utils.getNoNil(getUserAttribute(soundNode, "playInsideBuilding"), true)
	self.playExterior = Utils.getNoNil(getUserAttribute(soundNode, "playExterior"), false)
	self.playInterior = Utils.getNoNil(getUserAttribute(soundNode, "playInterior"), false)

	if not self.playExterior and not self.playInterior then
		g_logManager:warning("Ambient 3D sound '%s' has invalid position state. At least one of the states 'playExterior' or 'playInterior' need to be 'true'", getName(soundNode))
	end

	self.playHourStart = MathUtil.clamp(Utils.getNoNil(getUserAttribute(soundNode, "playHourStart"), 0), 0, 24) * 1000 * 60 * 60
	self.playHourEnd = MathUtil.clamp(Utils.getNoNil(getUserAttribute(soundNode, "playHourEnd"), 24), 0, 24) * 1000 * 60 * 60
	self.playHourInverted = Utils.getNoNil(getUserAttribute(soundNode, "playHourInverted"), false)
	self.playHour = Utils.getNoNil(getUserAttribute(soundNode, "playHour"), false)
	self.autoStop = Utils.getNoNil(getUserAttribute(soundNode, "autoStop"), true)
	self.isLooping = Utils.getNoNil(getUserAttribute(soundNode, "isLooping"), false)
	self.fadeOutDuration = Utils.getNoNil(getUserAttribute(soundNode, "fadeOutDuration"), 0) * 1000

	return self
end

function SoundNode:delete()
	for _, soundNode in ipairs(self.nodes) do
		delete(soundNode.node)
	end
end

function SoundNode:update(dt, isDay, isSun, isRain, isHail, isIndoor, isInsideBuilding, dayTime, extra)
	local isInRange = calcDistanceFrom(getCamera(), self.parent) < self.outerRange

	if isInRange then
		local canPlaySound = self:getCanPlaySound(isDay, isSun, isRain, isHail, isIndoor, isInsideBuilding, dayTime, extra)

		if canPlaySound then
			if self.nextCheckTime == nil or self.nextCheckTime < g_time then
				self:setNextSound(isIndoor)
			end

			if self.lastIsIndoor ~= isIndoor then
				self:updateIndoorValues(self.currentNode, isIndoor)
				self:updateIndoorValues(self.nextNode, isIndoor)

				self.lastIsIndoor = isIndoor
			end
		elseif self.nextCheckTime ~= nil then
			self:reset()
		end
	end
end

function SoundNode:setNextSound(isIndoor)
	self.currentNode = self.nextNode
	local numNodes = #self.nodes
	local nextNodeIndex = math.random(1, numNodes)

	if self.currentNode ~= nil and nextNodeIndex == self.currentNode.index then
		nextNodeIndex = nextNodeIndex + 1

		if numNodes < nextNodeIndex then
			nextNodeIndex = 1
		end
	end

	local nextNode = self.nodes[nextNodeIndex]
	local delay = MathUtil.lerp(self.retriggerMinDelay, self.retriggerMaxDelay, math.random())
	local currentSample = 0

	if self.currentNode ~= nil then
		currentSample = self.currentNode.sample
	end

	local volume = (isIndoor and g_ambientSoundManager.indoorVolumeFactor or 1) * nextNode.volume
	local frequency = isIndoor and g_ambientSoundManager.indoorLowpassGainFactor or 1

	playSample(nextNode.sample, 1, volume, 0, delay, currentSample)
	setSampleVolume(nextNode.sample, volume)
	setSampleFrequencyFilter(nextNode.sample, 1, frequency)

	local offset = 0

	if self.currentNode ~= nil then
		offset = self.currentNode.duration - math.max(0, getSamplePlayOffset(self.currentNode.sample))
	end

	self.nextPlayTime = g_time + delay
	local nextCheckOffset = getSamplePlayTimeLeft(nextNode.sample) - 150
	self.nextCheckTime = g_time + nextCheckOffset
	self.nextNode = nextNode
end

function SoundNode:updateIndoorValues(soundNode, isIndoor)
	if soundNode ~= nil then
		local sample = soundNode.sample
		local volume = (isIndoor and g_ambientSoundManager.indoorVolumeFactor or 1) * soundNode.volume
		local frequency = isIndoor and g_ambientSoundManager.indoorLowpassGainFactor or 1

		setSampleVolume(sample, volume)
		setSampleFrequencyFilter(sample, 1, frequency)
	end
end

function SoundNode:reset()
	self.nextCheckTime = nil

	if self.autoStop then
		if self.currentNode ~= nil then
			stopSample(self.currentNode.sample, 0, self.fadeOutDuration)
		end

		if self.nextNode ~= nil then
			stopSample(self.nextNode.sample, 0, self.fadeOutDuration)
		end
	end
end

function SoundNode:getWorldPosition()
	return getWorldTranslation(self.parent)
end

function SoundNode:setWorldPosition(x, y, z)
	setWorldTranslation(self.parent, x, y, z)
end

function SoundNode:getCanPlaySound(isDay, isSun, isRain, isHail, isIndoor, isInsideBuilding, dayTime, extra)
	local canPlaySound = true
	canPlaySound = canPlaySound and (self.playByDay and isDay or self.playByNight and not isDay)
	canPlaySound = canPlaySound and (self.playDuringHail and isHail or self.playDuringRain and isRain or self.playDuringSun and isSun)
	canPlaySound = canPlaySound and (self.playExterior and not isIndoor or self.playInterior and isIndoor)
	canPlaySound = canPlaySound and (not isInsideBuilding or self.playInsideBuilding)
	canPlaySound = canPlaySound and (not self.playHour or not self.playHourInverted and self.playHourStart <= dayTime and dayTime <= self.playHourEnd or self.playHourInverted and (dayTime <= self.playHourStart or self.playHourEnd <= dayTime))

	return canPlaySound
end
