GuiSoundPlayer = {}
local GuiSoundPlayer_mt = Class(GuiSoundPlayer)
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH = "dataS/gui/guiSoundSamples.xml"
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT = "GuiSoundSamples"
GuiSoundPlayer.SOUND_SAMPLES = {
	SUCCESS = "success",
	SLIDER = "slider",
	FAIL = "fail",
	BACK = "back",
	PAGING = "paging",
	ERROR = "error",
	ACHIEVEMENT = "achievement",
	CONFIG_WRENCH = "configWrench",
	HOVER = "hover",
	CLICK = "click",
	CONFIG_SPRAY = "configSpray",
	TRANSACTION = "transaction",
	NONE = ""
}

function GuiSoundPlayer:new(soundManager)
	local self = setmetatable({}, GuiSoundPlayer_mt)
	self.soundManager = soundManager
	self.soundSamples = self:loadSounds(GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH)

	return self
end

function GuiSoundPlayer:loadSounds(sampleDefinitionXmlPath)
	local samples = {}
	local xmlFile = loadXMLFile("GuiSampleDefinitions", sampleDefinitionXmlPath)

	if xmlFile ~= nil and xmlFile ~= 0 then
		for _, key in pairs(GuiSoundPlayer.SOUND_SAMPLES) do
			if key ~= GuiSoundPlayer.SOUND_SAMPLES.NONE then
				local sample = self.soundManager:loadSample2DFromXML(xmlFile, GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT, key, "", 1, AudioGroup.GUI)

				if sample ~= nil then
					samples[key] = sample
				else
					print("Warning: Could not load GUI sound sample [" .. tostring(key) .. "]")
				end
			end
		end

		delete(xmlFile)
	end

	return samples
end

function GuiSoundPlayer:playSample(sampleName)
	if sampleName ~= GuiSoundPlayer.SOUND_SAMPLES.NONE then
		local sample = self.soundSamples[sampleName]

		if sample ~= nil then
			local canPlay = not self.soundManager:getIsSamplePlaying(sample)

			if canPlay then
				self.soundManager:playSample(sample)
			end
		else
			print("Warning: Tried playing GUI sample [" .. tostring(sampleName) .. "] which has not been loaded.")
		end
	end
end
