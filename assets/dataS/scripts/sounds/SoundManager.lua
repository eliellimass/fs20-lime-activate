SoundModifierType = nil
SoundManager = {
	MAX_SAMPLES_PER_FRAME = 5,
	DEFAULT_SOUND_TEMPLATES = "data/sounds/soundTemplates.xml",
	SAMPLE_ATTRIBUTES = {
		"volume",
		"pitch",
		"lowpassGain"
	},
	SAMPLE_RANDOMIZATIONS = {
		"randomizationsIn",
		"randomizationsOut"
	}
}
local SoundManager_mt = Class(SoundManager, AbstractManager)

function SoundManager:new(customMt)
	local self = AbstractManager:new(customMt or SoundManager_mt)

	return self
end

function SoundManager:initDataStructures()
	self.samples = {}
	self.orderedSamples = {}
	self.activeSamples = {}
	self.activeSamplesSet = {}
	self.currentSampleIndex = 1
	self.oldRandomizationIndex = 1
	self.isIndoor = false
	self.isInsideBuilding = false
	self.soundTemplates = {}
	self.soundTemplateXMLFile = nil

	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)

	self.modifierTypeNameToIndex = {}
	self.modifierTypeIndexToDesc = {}
	SoundModifierType = self.modifierTypeNameToIndex
	self.indoorStateChangedListeners = {}
end

function SoundManager:registerModifierType(typeName, func, minFunc, maxFunc)
	typeName = typeName:upper()

	if SoundModifierType[typeName] == nil then
		local desc = {
			name = typeName,
			index = #self.modifierTypeIndexToDesc + 1,
			func = func,
			minFunc = minFunc,
			maxFunc = maxFunc
		}
		SoundModifierType[typeName] = desc.index

		table.insert(self.modifierTypeIndexToDesc, desc)
	end

	return SoundModifierType[typeName]
end

function SoundManager:loadSoundTemplates(xmlFilename)
	local xmlFile = loadXMLFile("TempTemplates", xmlFilename)

	if xmlFile ~= nil then
		local i = 0

		while true do
			local key = string.format("soundTemplates.template(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local name = getXMLString(xmlFile, key .. "#name")

			if name ~= nil then
				if self.soundTemplates[name] == nil then
					self.soundTemplates[name] = key
				else
					print(string.format("Warning: Sound template '%s' already exists!", name))
				end
			end

			i = i + 1
		end

		self.soundTemplateXMLFile = xmlFile

		return true
	end

	return false
end

function SoundManager:reloadSoundTemplates()
	for k, _ in pairs(self.soundTemplates) do
		self.soundTemplates[k] = nil
	end

	if entityExists(self.soundTemplateXMLFile) then
		delete(self.soundTemplateXMLFile)
	end

	self.soundTemplateXMLFile = nil

	self:loadSoundTemplates(SoundManager.DEFAULT_SOUND_TEMPLATES)
end

function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
	local newSample = ListUtil.copyTable(sample)
	newSample.modifiers = ListUtil.copyTable(sample.modifiers)

	if not sample.is2D then
		newSample.soundNode = createAudioSource(newSample.sampleName, newSample.filename, newSample.outerRadius, newSample.innerRadius, newSample.current.volume, newSample.loops)
		newSample.soundSample = getAudioSourceSample(newSample.soundNode)

		setAudioSourceAutoPlay(newSample.soundNode, false)
		link(linkNode, newSample.soundNode)

		newSample.linkNode = linkNode

		setTranslation(newSample.soundNode, 0, 0, 0)
	end

	setSampleGroup(newSample.soundSample, sample.audioGroup)

	newSample.audioGroup = sample.audioGroup

	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end

	self.samples[newSample] = newSample

	table.insert(self.orderedSamples, newSample)

	return newSample
end

function SoundManager:cloneSample2D(sample, linkNode, modifierTargetObject)
	local newSample = ListUtil.copyTable(sample)
	newSample.modifiers = ListUtil.copyTable(sample.modifiers)
	newSample.audioGroup = sample.audioGroup
	newSample.linkNode = 0
	newSample.soundNode = nil
	newSample.is2D = true
	newSample.soundSample = createSample(newSample.sampleName)

	loadSample(newSample.soundSample, newSample.filename, false)

	newSample.duration = getSampleDuration(newSample.soundSample)

	setSampleGroup(newSample.soundSample, sample.audioGroup)

	newSample.audioGroup = sample.audioGroup

	if modifierTargetObject ~= nil then
		newSample.modifierTargetObject = modifierTargetObject
	end

	self.samples[newSample] = newSample

	table.insert(self.orderedSamples, newSample)

	return newSample
end

function SoundManager:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, is2D, components, i3dMappings)
	local isValid = false
	local usedExternal = false
	local actualXmlFile = xmlFile
	local sampleKey = ""
	local linkNode = 0

	if sampleName ~= nil then
		if not AudioGroup.getIsValidAudioGroup(audioGroup) then
			print("Warning: Invalid audioGroup index '" .. tostring(audioGroup) .. "'. Using default group instead!")

			audioGroup = AudioGroup.DEFAULT
		end

		sampleKey = baseKey .. "." .. sampleName
		local externalSoundFilename = getXMLString(actualXmlFile, baseKey .. "#externalSoundFile")
		local externalSoundFile = nil

		if externalSoundFilename ~= nil and not hasXMLProperty(actualXmlFile, sampleKey) then
			externalSoundFilename = Utils.getFilename(externalSoundFilename, baseDir)
			externalSoundFile = loadXMLFile("ExternalSoundFileTemp", externalSoundFilename)

			if externalSoundFile ~= nil then
				actualXmlFile = externalSoundFile
				sampleKey = "sounds." .. sampleName
				usedExternal = true
			end
		end

		if hasXMLProperty(actualXmlFile, sampleKey) then
			isValid = true

			if not is2D then
				linkNode = I3DUtil.indexToObject(components, getXMLString(actualXmlFile, sampleKey .. "#linkNode"), i3dMappings)

				if linkNode == nil then
					if type(components) == "number" then
						linkNode = components
					elseif type(components) == "table" then
						linkNode = components[1].node
					else
						print("Warning: Could not find linkNode (" .. tostring(getXMLString(actualXmlFile, sampleKey .. "#linkNode")) .. ") for sample '" .. tostring(sampleName) .. "'. Ignoring it!")

						isValid = false
					end
				end
			end
		end
	end

	return isValid, usedExternal, actualXmlFile, sampleKey, linkNode
end

function SoundManager:loadSample2DFromXML(xmlFile, baseKey, sampleName, baseDir, loops, audioGroup)
	local sample = nil
	local isValid, usedExternal, definitionXmlFile, sampleKey = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, true)

	if isValid then
		sample = {}
		local template = getXMLString(definitionXmlFile, sampleKey .. "#template")

		if template ~= nil then
			sample = self:loadSampleAttributesFromTemplate(template, baseDir, loops)
		end

		if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops) then
			return nil
		end

		sample.is2D = true
		sample.filename = Utils.getFilename(sample.filename, baseDir)
		sample.linkNode = 0
		sample.sampleName = sampleName
		sample.current = sample.outdoorAttributes
		sample.audioGroup = audioGroup
		sample.soundSample = createSample(sample.sampleName)

		loadSample(sample.soundSample, sample.filename, false)

		sample.duration = getSampleDuration(sample.soundSample)

		setSampleGroup(sample.soundSample, sample.audioGroup)
		setSampleVolume(sample.soundSample, sample.current.volume)
		setSamplePitch(sample.soundSample, sample.current.pitch)
		setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain)

		self.samples[sample] = sample

		table.insert(self.orderedSamples, sample)
	end

	if usedExternal then
		delete(definitionXmlFile)
	end

	return sample
end

function SoundManager:loadSampleFromXML(xmlFile, baseKey, sampleName, baseDir, components, loops, audioGroup, i3dMappings, modifierTargetObject)
	local sample = nil
	local isValid, usedExternal, definitionXmlFile, sampleKey, linkNode = self:validateSampleDefinition(xmlFile, baseKey, sampleName, baseDir, audioGroup, false, components, i3dMappings)

	if isValid then
		sample = {}
		local template = getXMLString(definitionXmlFile, sampleKey .. "#template")

		if template ~= nil then
			sample = self:loadSampleAttributesFromTemplate(template, baseDir, loops)
		end

		if not self:loadSampleAttributesFromXML(sample, definitionXmlFile, sampleKey, baseDir, loops) then
			return nil
		end

		sample.filename = Utils.getFilename(sample.filename, baseDir)
		sample.linkNode = linkNode
		sample.sampleName = sampleName
		sample.modifierTargetObject = modifierTargetObject
		sample.current = sample.outdoorAttributes
		sample.audioGroup = audioGroup

		self:createAudioSource(sample, sample.filename)

		self.samples[sample] = sample

		table.insert(self.orderedSamples, sample)
	end

	if usedExternal then
		delete(definitionXmlFile)
	end

	return sample
end

function SoundManager:createAudioSource(sample, filename)
	if sample.soundNode ~= nil then
		delete(sample.soundNode)
	end

	sample.soundNode = createAudioSource(sample.sampleName, filename, sample.outerRadius, sample.innerRadius, sample.current.volume, sample.loops)
	sample.soundSample = getAudioSourceSample(sample.soundNode)
	sample.duration = getSampleDuration(sample.soundSample)
	sample.outerRange = getAudioSourceRange(sample.soundNode)
	sample.innerRange = getAudioSourceInnerRange(sample.soundNode)
	sample.isDirty = true

	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain)
	setAudioSourceAutoPlay(sample.soundNode, false)
	link(sample.linkNode, sample.soundNode)
	setTranslation(sample.soundNode, 0, 0, 0)
end

function SoundManager:createAudio2d(sample, filename)
	if sample.soundSample ~= nil then
		delete(sample.soundSample)
	end

	sample.soundSample = createSample(sample.sampleName)

	loadSample(sample.soundSample, filename, false)

	sample.duration = getSampleDuration(sample.soundSample)

	setSampleGroup(sample.soundSample, sample.audioGroup)
	setSampleVolume(sample.soundSample, sample.current.volume)
	setSamplePitch(sample.soundSample, sample.current.pitch)
	setSampleFrequencyFilter(sample.soundSample, 1, sample.current.lowpassGain)
end

function SoundManager:loadSampleAttributesFromTemplate(templateName, baseDir, defaultLoops)
	local xmlKey = self.soundTemplates[templateName]

	if xmlKey ~= nil and self.soundTemplateXMLFile ~= nil then
		local sample = {}

		if not self:loadSampleAttributesFromXML(sample, self.soundTemplateXMLFile, xmlKey, baseDir, defaultLoops, false) then
			sample = {}
		end

		return sample
	end

	return {}
end

function SoundManager:loadSampleAttributesFromXML(sample, xmlFile, key, baseDir, defaultLoops, requiresFile)
	local parent = getXMLString(xmlFile, key .. "#parent")

	if parent ~= nil then
		local templateKey = self.soundTemplates[parent]

		if templateKey ~= nil then
			self:loadSampleAttributesFromXML(sample, self.soundTemplateXMLFile, templateKey, baseDir, defaultLoops, false)
		end
	end

	sample.filename = Utils.getNoNil(getXMLString(xmlFile, key .. "#file"), sample.filename)

	if sample.filename == nil and (requiresFile == nil or requiresFile) then
		print("Warning: Filename not defined in '" .. tostring(key) .. "'. Ignoring it!")

		return false
	end

	sample.innerRadius = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#innerRadius"), sample.innerRadius), 5)
	sample.outerRadius = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#outerRadius"), sample.outerRadius), 80)
	sample.indoorAttributes = Utils.getNoNil(sample.indoorAttributes, {})
	sample.indoorAttributes.volume = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".volume#indoor"), sample.indoorAttributes.volume), 0.8)
	sample.indoorAttributes.pitch = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".pitch#indoor"), sample.indoorAttributes.pitch), 1)
	sample.indoorAttributes.lowpassGain = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassGain#indoor"), sample.indoorAttributes.lowpassGain), 0.8)
	sample.outdoorAttributes = Utils.getNoNil(sample.outdoorAttributes, {})
	sample.outdoorAttributes.volume = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".volume#outdoor"), sample.outdoorAttributes.volume), 1)
	sample.outdoorAttributes.pitch = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".pitch#outdoor"), sample.outdoorAttributes.pitch), 1)
	sample.outdoorAttributes.lowpassGain = Utils.getNoNil(Utils.getNoNil(getXMLFloat(xmlFile, key .. ".lowpassGain#outdoor"), sample.outdoorAttributes.lowpassGain), 1)
	sample.loops = Utils.getNoNil(Utils.getNoNil(getXMLInt(xmlFile, key .. "#loops"), sample.loops), Utils.getNoNil(defaultLoops, 1))
	local fadeIn = getXMLFloat(xmlFile, key .. "#fadeIn")

	if fadeIn ~= nil then
		fadeIn = fadeIn * 1000
	end

	sample.fadeIn = Utils.getNoNil(Utils.getNoNil(fadeIn, sample.fadeIn), 0)
	local fadeOut = getXMLFloat(xmlFile, key .. "#fadeOut")

	if fadeOut ~= nil then
		fadeOut = fadeOut * 1000
	end

	sample.fadeOut = Utils.getNoNil(Utils.getNoNil(fadeOut, sample.fadeOut), 0)
	sample.fade = 0

	self:loadModifiersFromXML(sample, xmlFile, key)
	self:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)

	return true
end

function SoundManager:loadModifiersFromXML(sample, xmlFile, key)
	sample.modifiers = Utils.getNoNil(sample.modifiers, {})

	for _, attribute in pairs(SoundManager.SAMPLE_ATTRIBUTES) do
		local modifier = Utils.getNoNil(sample.modifiers[attribute], {})
		local i = 0

		while true do
			local modKey = string.format("%s.%s.modifier(%d)", key, attribute, i)

			if not hasXMLProperty(xmlFile, modKey) then
				break
			end

			local type = getXMLString(xmlFile, modKey .. "#type")
			local typeIndex = SoundModifierType[type]

			if typeIndex ~= nil then
				if modifier[typeIndex] == nil then
					modifier[typeIndex] = AnimCurve:new(linearInterpolator1)
				end

				local value = getXMLFloat(xmlFile, modKey .. "#value")
				local modifiedValue = getXMLFloat(xmlFile, modKey .. "#modifiedValue")

				modifier[typeIndex]:addKeyframe({
					modifiedValue,
					time = value
				})
			end

			i = i + 1
		end

		modifier.currentValue = nil
		sample.modifiers[attribute] = modifier
	end
end

function SoundManager:loadRandomizationsFromXML(sample, xmlFile, key, baseDir)
	sample.randomizationsIn = sample.randomizationsIn or {}
	sample.randomizationsOut = sample.randomizationsOut or {}
	local i = 0

	while true do
		local baseKey = string.format("%s.randomization(%d)", key, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local randomization = {
			minVolume = getXMLFloat(xmlFile, baseKey .. "#minVolume"),
			maxVolume = getXMLFloat(xmlFile, baseKey .. "#maxVolume"),
			minPitch = getXMLFloat(xmlFile, baseKey .. "#minPitch"),
			maxPitch = getXMLFloat(xmlFile, baseKey .. "#maxPitch"),
			minLowpassGain = getXMLFloat(xmlFile, baseKey .. "#minLowpassGain"),
			maxLowpassGain = getXMLFloat(xmlFile, baseKey .. "#maxLowpassGain"),
			isInside = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isInside"), true),
			isOutside = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#isOutside"), true)
		}

		if randomization.isInside then
			table.insert(sample.randomizationsIn, randomization)
		end

		if randomization.isOutside then
			table.insert(sample.randomizationsOut, randomization)
		end

		i = i + 1
	end

	sample.sourceRandomizations = sample.sourceRandomizations or {}
	i = 0

	while true do
		local baseKey = string.format("%s.sourceRandomization(%d)", key, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local filename = getXMLString(xmlFile, baseKey .. "#file")

		if filename ~= nil then
			filename = Utils.getFilename(filename, baseDir)

			table.insert(sample.sourceRandomizations, filename)
		end

		i = i + 1
	end

	if #sample.sourceRandomizations > 0 and not sample.addedBaseFileToRandomizations then
		local filename = Utils.getFilename(sample.filename, baseDir)

		table.insert(sample.sourceRandomizations, filename)

		sample.addedBaseFileToRandomizations = true
	end
end

function SoundManager:update(dt)
	for i = 0, SoundManager.MAX_SAMPLES_PER_FRAME do
		local index = self.currentSampleIndex

		if index > #self.activeSamples then
			self.currentSampleIndex = 1

			break
		end

		local sample = self.activeSamples[index]

		if self:getIsSamplePlaying(sample) then
			self:updateSampleFade(sample, dt)
			self:updateSampleModifiers(sample)
			self:updateSampleAttributes(sample)
		else
			ListUtil.removeElementFromList(self.activeSamples, sample)

			sample.fade = 0
		end

		self.currentSampleIndex = self.currentSampleIndex + 1
	end
end

function SoundManager:updateSampleFade(sample, dt)
	if sample ~= nil and sample.fadeIn ~= 0 then
		sample.fade = math.min(sample.fade + dt, sample.fadeIn)
	end
end

function SoundManager:updateSampleModifiers(sample)
	if sample == nil or sample.modifiers == nil then
		return
	end

	for attributeIndex, attribute in pairs(SoundManager.SAMPLE_ATTRIBUTES) do
		local modifier = sample.modifiers[attribute]

		if modifier ~= nil then
			local value = 1

			for name, typeIndex in pairs(SoundModifierType) do
				local changeValue, _, available = self:getSampleModifierValue(sample, attribute, typeIndex)

				if available then
					value = value * changeValue
				end
			end

			modifier.currentValue = value
		end
	end
end

function SoundManager:updateSampleAttributes(sample, force)
	if sample ~= nil then
		if sample.isIndoor ~= self.isIndoor or force then
			self:setCurrentSampleAttributes(sample, self.isIndoor)

			sample.isIndoor = self.isIndoor
		end

		local volumeFactor = self:getModifierFactor(sample, "volume")
		local pitchFactor = self:getModifierFactor(sample, "pitch")
		local lowpassGainFactor = self:getModifierFactor(sample, "lowpassGain")

		setSampleVolume(sample.soundSample, volumeFactor * self:getCurrentSampleVolume(sample))
		setSamplePitch(sample.soundSample, pitchFactor * self:getCurrentSamplePitch(sample))
		setSampleFrequencyFilter(sample.soundSample, 1, lowpassGainFactor * self:getCurrentSampleLowpassGain(sample))
	end
end

function SoundManager:updateSampleRandomizations(sample)
	if sample ~= nil then
		for _, name in ipairs(SoundManager.SAMPLE_RANDOMIZATIONS) do
			local numRandomizations = #sample[name]

			if numRandomizations > 0 then
				local randomizationIndexToUse = math.max(math.floor(math.random(numRandomizations)), 1)
				local randomizationToUse = sample[name][randomizationIndexToUse]

				if randomizationToUse.minVolume ~= nil and randomizationToUse.maxVolume then
					sample[name].volume = math.random() * (randomizationToUse.maxVolume - randomizationToUse.minVolume) + randomizationToUse.minVolume
				end

				if randomizationToUse.minPitch ~= nil and randomizationToUse.maxPitch then
					sample[name].pitch = math.random() * (randomizationToUse.maxPitch - randomizationToUse.minPitch) + randomizationToUse.minPitch
				end

				if randomizationToUse.minLowpassGain ~= nil and randomizationToUse.maxLowpassGain then
					sample[name].lowpassGain = math.random() * (randomizationToUse.maxLowpassGain - randomizationToUse.minLowpassGain) + randomizationToUse.minLowpassGain
				end
			end
		end

		local numRandomizations = #sample.sourceRandomizations

		if numRandomizations > 0 then
			local randomizationIndexToUse = 1

			for i = 1, 3 do
				randomizationIndexToUse = math.max(math.floor(math.random(numRandomizations)), 1)

				if self.oldRandomizationIndex ~= randomizationIndexToUse then
					break
				end
			end

			self.oldRandomizationIndex = randomizationIndexToUse
			local filename = sample.sourceRandomizations[randomizationIndexToUse]

			if not sample.is2D then
				self:createAudioSource(sample, filename)
			else
				self:createAudio2d(sample, filename)
			end
		end
	end
end

function SoundManager:getSampleModifierValue(sample, attribute, typeIndex)
	local modifier = sample.modifiers[attribute]

	if modifier ~= nil then
		local curve = modifier[typeIndex]

		if curve ~= nil then
			local typeData = self.modifierTypeIndexToDesc[typeIndex]
			local t = typeData.func(sample.modifierTargetObject)

			if typeData.maxFunc ~= nil and typeData.minFunc ~= nil then
				local min = typeData.minFunc(sample.modifierTargetObject)
				t = MathUtil.clamp((t - min) / (typeData.maxFunc(sample.modifierTargetObject) - min), 0, 1)
			end

			return curve:get(t), t, true
		end
	end

	return 0, 0, false
end

function SoundManager:deleteSample(sample)
	if sample ~= nil and sample.filename ~= nil then
		self.samples[sample] = nil

		ListUtil.removeElementFromList(self.activeSamples, sample)
		ListUtil.removeElementFromList(self.orderedSamples, sample)

		if sample.soundNode ~= nil then
			delete(sample.soundNode)
		end

		if sample.is2D then
			delete(sample.soundSample)
		end
	end
end

function SoundManager:deleteSamples(samples, delay, afterSample)
	if samples ~= nil then
		for _, sample in pairs(samples) do
			self:deleteSample(sample, delay, afterSample)
		end
	end
end

function SoundManager:playSample(sample, delay, afterSample)
	if sample ~= nil then
		self:updateSampleRandomizations(sample)
		self:updateSampleModifiers(sample)
		self:updateSampleAttributes(sample, true)

		delay = delay or 0
		local afterSampleId = 0

		if afterSample ~= nil then
			afterSampleId = afterSample.soundSample
		end

		playSample(sample.soundSample, sample.loops, self:getModifierFactor(sample, "volume") * self:getCurrentSampleVolume(sample), 0, delay, afterSampleId)
		ListUtil.addElementToList(self.activeSamples, sample)
	end
end

function SoundManager:playSamples(samples, delay, afterSample)
	for _, sample in pairs(samples) do
		self:playSample(sample, delay, afterSample)
	end
end

function SoundManager:stopSample(sample, force)
	if sample ~= nil and sample.filename ~= nil then
		stopSample(sample.soundSample, 0, sample.fadeOut)
	end
end

function SoundManager:stopSamples(samples)
	for _, sample in pairs(samples) do
		self:stopSample(sample)
	end
end

function SoundManager:setSampleVolume(sample, volume)
	if sample ~= nil then
		setSampleVolume(sample.soundSample, volume)
	end
end

function SoundManager:setSamplePitch(sample, pitch)
	if sample ~= nil then
		setSamplePitch(sample.soundSample, pitch)
	end
end

function SoundManager:getIsSamplePlaying(sample, offset)
	if sample ~= nil then
		return isSamplePlaying(sample.soundSample)
	end

	return false
end

function SoundManager:setCurrentSampleAttributes(sample, isIndoor)
	if isIndoor then
		sample.current = sample.indoorAttributes
		sample.randomizations = sample.randomizationsIn
	else
		sample.current = sample.outdoorAttributes
		sample.randomizations = sample.randomizationsOut
	end
end

function SoundManager:getCurrentSampleVolume(sample)
	return (sample.current.volume + self:getCurrentRandomizationValue(sample, "volume")) * self:getCurrentFadeFactor(sample)
end

function SoundManager:getCurrentSamplePitch(sample)
	return sample.current.pitch + self:getCurrentRandomizationValue(sample, "pitch")
end

function SoundManager:getCurrentSampleLowpassGain(sample)
	return sample.current.lowpassGain + self:getCurrentRandomizationValue(sample, "lowpassGain")
end

function SoundManager:getCurrentRandomizationValue(sample, attribute)
	if sample.randomizations ~= nil and sample.randomizations[attribute] ~= nil then
		return sample.randomizations[attribute]
	end

	return 0
end

function SoundManager:getCurrentFadeFactor(sample)
	local fadeFactor = 1

	if sample.fadeIn ~= 0 then
		fadeFactor = sample.fade / sample.fadeIn
	end

	return fadeFactor
end

function SoundManager:setIsIndoor(isIndoor)
	if self.isIndoor ~= isIndoor then
		self.isIndoor = isIndoor

		for _, target in ipairs(self.indoorStateChangedListeners) do
			target:onIndoorStateChanged(isIndoor)
		end
	end
end

function SoundManager:addIndoorStateChangedListener(target)
	ListUtil.addElementToList(self.indoorStateChangedListeners, target)
end

function SoundManager:removeIndoorStateChangedListener(target)
	ListUtil.removeElementFromList(self.indoorStateChangedListeners, target)
end

function SoundManager:getIsIndoor()
	return self.isIndoor
end

function SoundManager:setIsInsideBuilding(isInsideBuilding)
	if self.isInsideBuilding ~= isInsideBuilding then
		self.isInsideBuilding = isInsideBuilding
	end
end

function SoundManager:getIsInsideBuilding()
	return self.isInsideBuilding
end

function SoundManager:getModifierFactor(sample, modifierName)
	if sample.modifiers ~= nil then
		local modifier = sample.modifiers[modifierName]

		if modifier ~= nil and modifier.currentValue ~= nil then
			return modifier.currentValue
		end
	end

	return 1
end

g_soundManager = SoundManager:new()
