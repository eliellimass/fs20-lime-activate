MapManager = {}
local MapManager_mt = Class(MapManager, AbstractManager)

function MapManager:new(customMt)
	local self = AbstractManager:new(customMt or MapManager_mt)

	return self
end

function MapManager:initDataStructures()
	self.maps = {}
	self.idToMap = {}
end

function MapManager:addMapItem(id, scriptFilename, className, configFile, defaultVehiclesXMLFilename, defaultItemsXMLFilename, title, description, iconFilename, baseDirectory, customEnvironment, isMultiplayerSupported, isModMap)
	if self.idToMap[id] ~= nil then
		print("Warning: Duplicate map id (" .. id .. "). Ignoring this map definition.")

		return
	end

	local item = {
		id = tostring(id),
		scriptFilename = scriptFilename,
		mapXMLFilename = configFile,
		className = className,
		defaultVehiclesXMLFilename = defaultVehiclesXMLFilename,
		defaultItemsXMLFilename = defaultItemsXMLFilename,
		title = title,
		description = description,
		iconFilename = iconFilename,
		baseDirectory = baseDirectory,
		customEnvironment = customEnvironment,
		isMultiplayerSupported = isMultiplayerSupported,
		isModMap = isModMap
	}

	table.insert(self.maps, item)

	self.idToMap[id] = item
end

function MapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile)
	local mapId = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#id"), "")
	local defaultVehiclesXMLFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#defaultVehiclesXMLFilename"), "")
	local defaultItemsXMLFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#defaultItemsXMLFilename"), "")
	local mapTitle = XMLUtil.getXMLI18NValue(xmlFile, baseName .. ".title", getXMLString, nil, "", modName, true)
	local mapDesc = XMLUtil.getXMLI18NValue(xmlFile, baseName .. ".description", getXMLString, nil, "", modName, true)
	local mapClassName = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#className"), "Mission00")
	local mapFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#filename"), "$dataS/scripts/missions/mission00.lua")
	local configFilename = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#configFilename"), "")
	local mapIconFilename = XMLUtil.getXMLI18NValue(xmlFile, baseName .. ".iconFilename", getXMLString, nil, "", modName, true)

	if mapClassName:find("[^%w_]") ~= nil then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Invalid map class name: '" .. tostring(mapClassName) .. "'. No whitespaces allowed.")
	elseif mapClassName == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing attribute '" .. tostring(baseName) .. "#className'.")
	elseif mapId == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing attribute '" .. tostring(baseName) .. "#id'.")
	elseif mapTitle == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing element: '" .. tostring(baseName) .. ".title'.")
	elseif mapDesc == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing element: '" .. tostring(baseName) .. ".description'.")
	elseif mapFilename == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing attribute '" .. tostring(baseName) .. "#filename'.")
	elseif defaultVehiclesXMLFilename == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing attribute '" .. tostring(baseName) .. "#defaultVehiclesXMLFilename'.")
	elseif defaultItemsXMLFilename == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing attribute '" .. tostring(baseName) .. "#defaultItemsXMLFilename'.")
	elseif mapIconFilename == "" then
		print("Error: Failed to load mod map '" .. tostring(modName) .. "'. Missing element: '" .. tostring(baseName) .. ".iconFilename'.")
	else
		local customEnvironment = nil
		local useModDirectory = true
		local baseDirectory = modDir
		mapFilename, useModDirectory = Utils.getFilename(mapFilename, baseDirectory)

		if useModDirectory then
			customEnvironment = modName
			mapClassName = modName .. "." .. mapClassName
		end

		mapId = modName .. "." .. mapId
		mapIconFilename = Utils.getFilename(mapIconFilename, baseDirectory)
		defaultVehiclesXMLFilename = Utils.getFilename(defaultVehiclesXMLFilename, baseDirectory)
		defaultItemsXMLFilename = Utils.getFilename(defaultItemsXMLFilename, baseDirectory)

		if not GS_IS_CONSOLE_VERSION or isDLCFile or customEnvironment == nil then
			self:addMapItem(mapId, mapFilename, mapClassName, configFilename, defaultVehiclesXMLFilename, defaultItemsXMLFilename, mapTitle, mapDesc, mapIconFilename, baseDirectory, customEnvironment, isMultiplayerSupported, true)
		else
			print("Error: Can't register map " .. mapId .. " with scripts on consoles.")
		end
	end
end

function MapManager:getModNameFromMapId(mapId)
	local parts = StringUtil.splitString(".", mapId)

	if #parts > 1 then
		return parts[1]
	end

	return nil
end

function MapManager:getMapById(id)
	return self.idToMap[id]
end

function MapManager:removeMapItem(index)
	local item = self.maps[index]

	if item ~= nil then
		self.idToMap[item.id] = nil

		table.remove(self.maps, index)
	end
end

function MapManager:getNumOfMaps()
	return table.getn(self.maps)
end

function MapManager:getMapDataByIndex(index)
	return self.maps[index]
end

g_mapManager = MapManager:new()
