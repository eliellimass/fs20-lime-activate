FoliagePainter = {}
local FoliagePainter_mt = Class(FoliagePainter)

function FoliagePainter:new(customMt)
	local self = {}

	setmetatable(self, customMt or FoliagePainter_mt)

	self.terrainRootNode = 0
	self.paintableFoliages = {}
	self.numPaintableFoliages = 0

	return self
end

function FoliagePainter:delete()
	self.paintableFoliages = {}
end

function FoliagePainter:loadMapData(xmlFile, missionInfo, baseDirectory)
	local i = 0

	while true do
		local key = string.format("map.paintableFoliages.paintableFoliage(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		paintableFoliage = {
			id = Utils.getNoNil(getXMLInt(xmlFile, string.format("%s#id", key)), ""),
			layerName = Utils.getNoNil(getXMLString(xmlFile, string.format("%s#layerName", key)), ""),
			firstDensityMapChannel = Utils.getNoNil(getXMLInt(xmlFile, string.format("%s#firstDensityMapChannel", key)), 0),
			numDensityMapChannels = Utils.getNoNil(getXMLInt(xmlFile, string.format("%s#numDensityMapChannels", key)), 4),
			value = Utils.getNoNil(getXMLInt(xmlFile, string.format("%s#value", key)), 0)
		}

		table.insert(self.paintableFoliages, paintableFoliage)

		i = i + 1
	end

	self.numPaintableFoliages = i

	return true
end

function FoliagePainter:unloadMapData()
	self.paintableFoliages = {}
end

function FoliagePainter:initTerrain(terrainRootNode)
	self.terrainRootNode = terrainRootNode

	for key, paintableFoliage in pairs(self.paintableFoliages) do
		local id = getTerrainDetailByName(self.terrainRootNode, paintableFoliage.layerName)
		paintableFoliage.terrainDetailId = id
		paintableFoliage.paintModifier = DensityMapModifier:new(paintableFoliage.terrainDetailId, paintableFoliage.firstDensityMapChannel, paintableFoliage.numDensityMapChannels)
	end
end

function FoliagePainter:apply(modifiedAreas, paintTerrainFoliageId)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.id == paintTerrainFoliageId then
			local modifier = paintableFoliage.paintModifier

			for _, area in pairs(modifiedAreas) do
				local x, z, x1, z1, x2, z2 = unpack(area)

				modifier:setParallelogramWorldCoords(x, z, x1 - x, z1 - z, x2 - x, z2 - z, MODIFIER_3POINTS)
				modifier:executeSet(paintableFoliage.value)
			end

			return true
		end
	end

	return false
end

g_foliagePainter = FoliagePainter:new()
