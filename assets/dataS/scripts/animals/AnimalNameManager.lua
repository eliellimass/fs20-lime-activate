AnimalNameManager = {}
local AnimalNameManager_mt = Class(AnimalNameManager, AbstractManager)

function AnimalNameManager:new(customMt)
	local self = AbstractManager:new(customMt or AnimalNameManager_mt)

	return self
end

function AnimalNameManager:initDataStructures()
	self.names = {}
end

function AnimalNameManager:loadMapData(xmlFile, missionInfo)
	AnimalNameManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.animalNames#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load animal name configuration file '" .. tostring(filename) .. "'!")

		return false
	end

	self:loadNamesFromXML(filename)

	return true
end

function AnimalNameManager:loadNamesFromXML(filename)
	local xmlFile = loadXMLFile("animalNames", filename)

	if xmlFile ~= nil then
		local i = 0

		while true do
			local key = string.format("animalNames.name(%d)", i)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local name = Utils.getNoNil(getXMLString(xmlFile, key .. "#value"), "")

			if name:sub(1, 6) == "$l10n_" then
				name = g_i18n:getText(name:sub(7))

				table.insert(self.names, name)
			end

			i = i + 1
		end

		delete(xmlFile)

		return true
	end

	return false
end

function AnimalNameManager:getRandomName()
	local index = math.random(#self.names)

	if index > 0 then
		return self.names[index]
	end

	return ""
end

g_animalNameManager = AnimalNameManager:new()
