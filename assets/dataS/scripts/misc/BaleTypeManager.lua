BaleType = nil
BaleTypeManager = {}
local BaleTypeManager_mt = Class(BaleTypeManager, AbstractManager)

function BaleTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or BaleTypeManager_mt)

	return self
end

function BaleTypeManager:initDataStructures()
	self.baleTypes = {}
	self.nameToBaleType = {}
	self.nameToIndex = {}
	self.roundBales = {}
	self.squareBales = {}
	BaleType = self.nameToIndex
end

function BaleTypeManager:loadDefaultTypes(missionInfo)
	local xmlFile = loadXMLFile("baleTypes", "data/maps/maps_baleTypes.xml")

	self:loadBaleTypes(xmlFile, missionInfo, nil, true)
	delete(xmlFile)
end

function BaleTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	BaleTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes(missionInfo)

	if not XMLUtil.loadDataFromMapXML(xmlFile, "baleTypes", baseDirectory, self, self.loadBaleTypes, missionInfo, baseDirectory) then
		return false
	end

	for _, baleType in ipairs(self.baleTypes) do
		baleType.sharedRoot = g_i3DManager:loadSharedI3DFile(baleType.filename, nil, false, true)

		removeFromPhysics(baleType.sharedRoot)
	end

	return true
end

function BaleTypeManager:unloadMapData()
	for _, baleType in ipairs(self.baleTypes) do
		if baleType.sharedRoot ~= nil then
			g_i3DManager:releaseSharedI3DFile(baleType.filename, nil, true)
			delete(baleType.sharedRoot)

			baleType.sharedRoot = nil
		end
	end

	BaleTypeManager:superClass().unloadMapData(self)
end

function BaleTypeManager:loadBaleTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.baleTypes.baleType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		self:loadBaleTypeFromXML(xmlFile, key, isBaseType, baseDirectory)

		i = i + 1
	end

	return true
end

function BaleTypeManager:loadBaleTypeFromXML(xmlFile, key, isBaseType, baseDirectory, ignoreFillTypeExits)
	local filename = getXMLString(xmlFile, key .. "#filename")

	if filename ~= nil then
		local fillTypeName = Utils.getNoNil(getXMLString(xmlFile, key .. "#fillType"), "straw")
		local isRoundbale = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isRoundbale"), getXMLBool(xmlFile, key .. "#isRoundBale")), false)
		local width = MathUtil.round(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#width"), 1.2), 2)
		local height = MathUtil.round(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#height"), 0.9), 2)
		local length = MathUtil.round(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#length"), 2.4), 2)
		local diameter = MathUtil.round(Utils.getNoNil(getXMLFloat(xmlFile, key .. "#diameter"), 1.8), 2)
		local filename = Utils.getFilename(filename, baseDirectory)

		return self:addBaleType(filename, fillTypeName, isRoundbale, width, height, length, diameter, isBaseType, ignoreFillTypeExits)
	else
		g_logManager:warning("Failed to load BaleType '%s' ", key)
	end
end

function BaleTypeManager:addBaleType(filename, fillTypeName, isRoundbale, width, height, length, diameter, isBaseType, ignoreFillTypeExits)
	local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

	if fillType == nil and (ignoreFillTypeExits == nil or not ignoreFillTypeExits) then
		print("Warning: Missing fillType '" .. tostring(fillTypeName) .. "' for baleType definition. Ignoring baleType!")

		return
	end

	local name = BaleTypeManager.getBaleKey(fillTypeName, isRoundbale, width, height, length, diameter)
	local baleType = self.nameToBaleType[name]

	if baleType ~= nil then
		print("Overriding bale (" .. tostring(name) .. ") '" .. tostring(baleType.filename) .. "'")
	elseif #self.baleTypes >= 64 then
		print("Warning: Too many bale types. Only 64 bale types are supported")

		return
	else
		baleType = {
			index = #self.baleTypes + 1
		}

		table.insert(self.baleTypes, baleType)

		self.nameToBaleType[name] = baleType
		self.nameToIndex[name] = baleType.index
	end

	baleType.fillTypeName = fillTypeName
	baleType.isRoundbale = isRoundbale
	baleType.width = Utils.getNoNil(tonumber(width), 1.2)
	baleType.height = Utils.getNoNil(tonumber(height), 0.9)
	baleType.length = Utils.getNoNil(tonumber(length), 2.4)
	baleType.diameter = Utils.getNoNil(tonumber(diameter), 1.8)
	baleType.filename = filename

	if isRoundbale then
		table.insert(self.roundBales, baleType)

		if self.defaultRoundBale == nil then
			self.defaultRoundBale = baleType
		end
	else
		table.insert(self.squareBales, baleType)

		if self.defaultSquareBale == nil then
			self.defaultSquareBale = baleType
		end
	end

	return baleType
end

function BaleTypeManager:getBale(fillTypeIndex, isRoundbale, width, height, length, diameter)
	local fillTypeName = "STRAW"
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

	if fillType ~= nil then
		fillTypeName = fillType.name
	end

	local key = BaleTypeManager.getBaleKey(fillTypeName, isRoundbale, width, height, length, diameter)
	local baleType = self.nameToBaleType[key]

	if baleType ~= nil then
		return baleType
	end

	if isRoundbale then
		for _, bt in pairs(self.roundBales) do
			if bt.width <= width and bt.diameter <= diameter then
				if baleType ~= nil then
					if (fillTypeName == nil or bt.fillTypeName == fillTypeName) and baleType.width <= bt.width and baleType.diameter <= bt.diameter then
						baleType = bt
					end
				else
					baleType = bt
				end
			end
		end

		if baleType == nil then
			baleType = self.defaultRoundBale
		end
	else
		for _, bt in pairs(self.squareBales) do
			if bt.width <= width and bt.height <= height and bt.length <= length then
				if baleType ~= nil then
					if (fillTypeName == nil or bt.fillTypeName == fillTypeName) and baleType.width <= bt.width and (baleType.length <= bt.length or baleType.height <= bt.height) then
						baleType = bt
					end
				else
					baleType = bt
				end
			end
		end

		if baleType == nil then
			baleType = self.defaultSquareBale
		end
	end

	return baleType
end

function BaleTypeManager.getBaleKey(fillTypeName, isRoundbale, width, height, length, diameter)
	if isRoundbale then
		return string.format("%s_%d_%d", fillTypeName, width * 100, diameter * 100)
	else
		return string.format("%s_%d_%d_%d", fillTypeName, width * 100, height * 100, length * 100)
	end
end

g_baleTypeManager = BaleTypeManager:new()
