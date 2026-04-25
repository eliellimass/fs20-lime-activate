GroundTypeManager = {}
local GroundTypeManager_mt = Class(GroundTypeManager, AbstractManager)

function GroundTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or GroundTypeManager_mt)

	return self
end

function GroundTypeManager:initDataStructures()
	self.groundTypes = {}
	self.groundTypeMappings = {}
	self.terrainLayerMapping = {}
end

function GroundTypeManager:loadGroundTypes()
	self.groundTypes = {}
	local xmlFile = loadXMLFile("fuitTypes", "data/maps/groundTypes.xml")
	local i = 0

	while true do
		local key = string.format("groundTypes.groundType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")

		if name ~= nil then
			local fallbacks = StringUtil.splitString(" ", getXMLString(xmlFile, key .. "#fallbacks"))
			local groundType = {
				fallbacks = fallbacks
			}
			self.groundTypes[name] = groundType
		end

		i = i + 1
	end

	delete(xmlFile)
end

function GroundTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GroundTypeManager:superClass().loadMapData(self)
	self:loadGroundTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "groundTypeMappings", baseDirectory, self, self.loadGroundTypeMappings, missionInfo)
end

function GroundTypeManager:loadGroundTypeMappings(xmlFile, missionInfo)
	local i = 0

	while true do
		local key = string.format("map.groundTypeMappings.groundTypeMapping(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local groundType = {
			typeName = getXMLString(xmlFile, key .. "#type"),
			layerName = getXMLString(xmlFile, key .. "#layer"),
			foliagePaintIndex = Utils.getNoNil(getXMLInt(xmlFile, key .. "#paintableFoliageId"), 0)
		}

		if groundType.typeName ~= nil and groundType.layerName ~= nil then
			self.groundTypeMappings[groundType.typeName] = groundType
		end

		i = i + 1
	end

	return true
end

function GroundTypeManager:initTerrain(terrainRootNode)
	self.terrainLayerMapping = {}
	local numLayers = getTerrainNumOfLayers(terrainRootNode)

	for i = 0, numLayers - 1 do
		local layerName = getTerrainLayerName(terrainRootNode, i)
		self.terrainLayerMapping[layerName] = i
	end
end

function GroundTypeManager:getTerrainLayerByType(typeName)
	local layerName = nil

	if typeName ~= nil and self.groundTypeMappings[typeName] ~= nil then
		layerName = self.groundTypeMappings[typeName].layerName
	end

	if layerName ~= nil then
		local layer = self.terrainLayerMapping[layerName]

		if layer ~= nil then
			return layer
		end
	end

	local groundType = self.groundTypes[typeName]

	if groundType ~= nil then
		for _, fallbackTypeName in pairs(groundType.fallbacks) do
			local fallbackLayerName = self.groundTypeMappings[fallbackTypeName].layerName

			if fallbackLayerName ~= nil then
				local layer = self.terrainLayerMapping[fallbackLayerName]

				if layer ~= nil then
					return layer
				end
			end
		end
	end

	return 0
end

function GroundTypeManager:getPaintableFoliageIdByTerrainLayer(layer)
	for key, groundType in pairs(self.groundTypeMappings) do
		local layerName = groundType.layerName
		local layerId = self.terrainLayerMapping[layerName]

		if layerId == layer then
			return groundType.foliagePaintIndex
		end
	end

	return 0
end

g_groundTypeManager = GroundTypeManager:new()
