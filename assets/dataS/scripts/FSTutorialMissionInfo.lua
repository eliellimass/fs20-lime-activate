FSTutorialMissionInfo = {}
local FSTutorialMissionInfo_mt = Class(FSTutorialMissionInfo, FSMissionInfo)

function FSTutorialMissionInfo:new(baseDirectory, customEnvironment, customMt)
	return FSTutorialMissionInfo:superClass():new(baseDirectory, customEnvironment, customMt or FSTutorialMissionInfo_mt)
end

function FSTutorialMissionInfo:loadDefaults()
	FSTutorialMissionInfo:superClass().loadDefaults(self)

	self.name = ""
	self.description = ""
	self.overlayActiveFilename = ""
	self.briefingImageBasePath = ""
	self.mapId = nil
end

function FSTutorialMissionInfo:loadFromXML(xmlFile, key)
	local i18n = g_i18n

	if self.customEnvironment ~= nil then
		i18n = _G[self.customEnvironment].g_i18n
	end

	self.id = getXMLString(xmlFile, key .. "#id")
	self.mapId = getXMLString(xmlFile, key .. ".mapId")
	self.scriptFilename = getXMLString(xmlFile, key .. ".script#filename")
	self.mapXMLFilename = getXMLString(xmlFile, key .. ".script#mapFilename")
	self.scriptClass = getXMLString(xmlFile, key .. ".script#class")

	if self.id == nil then
		print("Error: Missing id attribute in mission " .. key)

		return false
	end

	if self.scriptFilename == nil or self.scriptClass == nil then
		print("Error: Missing script attributes in mission " .. self.id)

		return false
	end

	if not self:isValidMissionId(self.id) then
		print("Error: Invalid mission id '" .. self.id .. "'")

		return false
	end

	local scriptUsesModDirectory = nil
	self.scriptFilename, scriptUsesModDirectory = Utils.getFilename(self.scriptFilename, self.baseDirectory)

	if self.customEnvironment ~= nil then
		if not self:isValidMissionId(self.customEnvironment) then
			print("Error: Invalid mission customEnvironment '" .. self.customEnvironment .. "'")

			return false
		end

		self.id = self.customEnvironment .. "." .. self.id

		if scriptUsesModDirectory then
			self.scriptClass = self.customEnvironment .. "." .. self.scriptClass
		end
	end

	self.name = XMLUtil.getXMLI18NValue(xmlFile, key, getXMLString, "name", "", self.customEnvironment, true)
	self.description = XMLUtil.getXMLI18NValue(xmlFile, key, getXMLString, "description", "", self.customEnvironment, true)
	self.iconFilename = getXMLString(xmlFile, key .. ".icon#filename")
	local imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, key .. ".icon#imageSize"), {
		1024,
		1024
	})
	self.iconUVs = GuiUtils.getUVs(Utils.getNoNil(getXMLString(xmlFile, key .. ".icon#uvs"), "0 0 1 1"), imageSize)
	self.hasInitiallyOwnedFarmlands = true
	self.initialLoan = 0
	self.initialMoney = 50000
	self.loadDefaultFarm = true
	local map = g_mapManager:getMapById(self.mapId)
	self.itemsXMLLoad = map.defaultItemsXMLFilename
	self.playerStyle.useDefault = true

	return true
end
