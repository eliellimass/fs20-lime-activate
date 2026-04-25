HelpLineManager = {}
local HelpLineManager_mt = Class(HelpLineManager, AbstractManager)
HelpLineManager.ITEM_TYPE = {
	TEXT = "text",
	IMAGE = "image"
}

function HelpLineManager:new(customMt)
	local self = AbstractManager:new(customMt or HelpLineManager_mt)

	return self
end

function HelpLineManager:initDataStructures()
	self.categories = {}
	self.categoryNames = {}
end

function HelpLineManager:loadMapData(xmlFile, missionInfo)
	HelpLineManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.helpline#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load helpline config file '" .. tostring(filename) .. "'!")

		return false
	end

	self:loadFromXML(filename, missionInfo)

	return true
end

function HelpLineManager:loadFromXML(filename, missionInfo)
	local xmlFile = loadXMLFile("helpLineViewContentXML", filename)
	local i = 0

	while true do
		local categoryKey = string.format("helpLines.category(%d)", i)

		if not hasXMLProperty(xmlFile, categoryKey) then
			break
		end

		local category = self:loadCategory(xmlFile, categoryKey, missionInfo)

		if category ~= nil then
			table.insert(self.categories, category)
		end

		i = i + 1
	end

	delete(xmlFile)
end

function HelpLineManager:loadCategory(xmlFile, key, missionInfo)
	local category = {
		title = getXMLString(xmlFile, key .. "#title"),
		pages = {}
	}
	local i = 0

	while true do
		local pageKey = string.format(key .. ".page(%d)", i)

		if not hasXMLProperty(xmlFile, pageKey) then
			break
		end

		local page = self:loadPage(xmlFile, pageKey, missionInfo)

		table.insert(category.pages, page)

		i = i + 1
	end

	return category
end

function HelpLineManager:loadPage(xmlFile, key, missionInfo)
	local page = {
		title = getXMLString(xmlFile, key .. "#title"),
		items = {}
	}
	local i = 0

	while true do
		local itemKey = string.format(key .. ".item(%d)", i)

		if not hasXMLProperty(xmlFile, itemKey) then
			break
		end

		local type = getXMLString(xmlFile, itemKey .. "#type")
		local value = getXMLString(xmlFile, itemKey .. "#value")

		if (type == HelpLineManager.ITEM_TYPE.TEXT or type == HelpLineManager.ITEM_TYPE.IMAGE) and value ~= nil then
			local heightScale = Utils.getNoNil(getXMLFloat(xmlFile, itemKey .. "#heightScale"), 1)
			local imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, itemKey .. "#imageSize"), {
				1024,
				1024
			})
			local imageUVs = GuiUtils.getUVs(Utils.getNoNil(getXMLString(xmlFile, itemKey .. "#imageUVs"), "0 0 1 1"), imageSize)
			local fixedWidth = Utils.getNoNil(getXMLFloat(xmlFile, itemKey .. "#fixedWidth"), nil)

			table.insert(page.items, {
				type = type,
				value = value,
				heightScale = heightScale,
				imageUVs = imageUVs,
				fixedWidth = fixedWidth
			})
		end

		i = i + 1
	end

	return page
end

function HelpLineManager:convertText(text)
	local translated = g_i18n:convertText(text)

	return string.gsub(translated, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
end

function HelpLineManager:getCategories()
	return self.categories
end

function HelpLineManager:getCategory(categoryIndex)
	if categoryIndex ~= nil then
		return self.categories[categoryIndex]
	end

	return nil
end

g_helpLineManager = HelpLineManager:new()
