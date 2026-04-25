MissionCollaborators = {}
local MissionCollaborators_mt = Class(MissionCollaborators)

function MissionCollaborators:new()
	local self = setmetatable({}, MissionCollaborators_mt)
	self.server = nil
	self.client = nil
	self.savegameController = nil
	self.messageCenter = nil
	self.achievementManager = nil
	self.inputManager = nil
	self.inputDisplayManager = nil
	self.modManager = nil
	self.fillTypeManager = nil
	self.fruitTypeManager = nil
	self.inGameMenu = nil
	self.shopMenu = nil
	self.landscapingScreen = nil
	self.guiSoundPlayer = nil
	self.guiTopDownCamera = nil
	self.placementController = nil
	self.landscapingController = nil
	self.shopController = nil
	self.animalController = nil

	return self
end
