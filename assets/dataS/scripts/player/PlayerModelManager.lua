PlayerModelManager = {
	SEND_NUM_BITS = 2
}
local PlayerModelManager_mt = Class(PlayerModelManager)
PlayerModelManager.GENDERS = {
	GENDER_NONE = 0,
	GENDER_MALE = 2,
	GENDER_FEMALE = 1
}

function PlayerModelManager:new(customMt)
	local self = {}

	setmetatable(self, customMt or PlayerModelManager_mt)
	self:initDataStructures()

	return self
end

function PlayerModelManager:initDataStructures()
	self.playerModels = {}
	self.nameToPlayerModel = {}
	self.nameToIndex = {}
end

function PlayerModelManager:load(xmlFilename)
	local result = false

	if xmlFilename ~= nil and xmlFilename ~= "" then
		local xmlFile = loadXMLFile("TempXML", xmlFilename)

		if xmlFile ~= nil and xmlFile ~= 0 then
			local i = 0

			while true do
				local baseKey = "playerModels.playerModel"
				local XMLFilenameKey = string.format("%s(%d)#xmlFilename", baseKey, i)
				local genderKey = string.format("%s(%d)#gender", baseKey, i)
				local defaultNameKey = string.format("%s(%d)#defaultName", baseKey, i)
				local descKey = string.format("%s(%d)#desc", baseKey, i)

				if not hasXMLProperty(xmlFile, XMLFilenameKey) or not hasXMLProperty(xmlFile, genderKey) or not hasXMLProperty(xmlFile, defaultNameKey) or not hasXMLProperty(xmlFile, descKey) then
					break
				end

				local modelXMLFilename = getXMLString(xmlFile, XMLFilenameKey)
				local modelGender = getXMLString(xmlFile, genderKey)
				local modelDefaultName = getXMLString(xmlFile, defaultNameKey)
				local modelDesc = getXMLString(xmlFile, descKey)
				local modelGenderId = PlayerModelManager.GENDERS.GENDER_NONE
				modelGender = modelGender:upper()

				if modelGender == "FEMALE" then
					modelGenderId = PlayerModelManager.GENDERS.GENDER_FEMALE
				else
					modelGenderId = PlayerModelManager.GENDERS.GENDER_MALE
				end

				if self:addPlayerModel(modelDefaultName, modelXMLFilename, modelDesc, modelGenderId) ~= nil then
					result = true
				end

				i = i + 1
			end

			delete(xmlFile)
		else
			print(string.format("Warning: Cannot open xmlFilename('%s') is missing for player model manager.", tostring(xmlFilename)))
		end
	else
		print(string.format("Warning: Config xmlFilename('%s') is missing for player model manager.", tostring(xmlFilename)))
	end

	return result
end

function PlayerModelManager:loadMapData(xmlFile)
	return true
end

function PlayerModelManager:unloadMapData()
end

function PlayerModelManager:addPlayerModel(name, xmlFilename, description, genderId)
	if not ClassUtil.getIsValidIndexName(name) then
		g_logManager:devWarning("Warning: '%s' is not a valid name for a player. Ignoring it!", tostring(name))

		return nil
	end

	if xmlFilename == nil or xmlFilename == "" then
		g_logManager:devWarning("Warning: Config xmlFilename is missing for player '%s'. Ignoring it!", tostring(name))

		return nil
	end

	name = name:upper()

	if self.nameToPlayerModel[name] == nil then
		local numPlayerModels = #self.playerModels + 1
		local playerModel = {
			name = name,
			index = numPlayerModels,
			xmlFilename = Utils.getFilename(xmlFilename, nil),
			description = description,
			genderId = genderId
		}

		table.insert(self.playerModels, playerModel)

		self.nameToPlayerModel[name] = playerModel
		self.nameToIndex[name] = numPlayerModels

		return playerModel
	else
		g_logManager:devWarning("Warning: Player '%s' already exists. Ignoring it!", tostring(name))
	end

	return nil
end

function PlayerModelManager:getPlayerModelByIndex(index)
	if index ~= nil then
		return self.playerModels[index]
	end

	return nil
end

function PlayerModelManager:getPlayerByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToPlayerModel[name]
	end

	return nil
end

function PlayerModelManager:getNumOfPlayerModels()
	return #self.playerModels
end

g_playerModelManager = PlayerModelManager:new()
