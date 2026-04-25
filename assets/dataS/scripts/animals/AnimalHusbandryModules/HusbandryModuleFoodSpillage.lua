HusbandryModuleFoodSpillage = {}
local HusbandryModuleFoodSpillage_mt = Class(HusbandryModuleFoodSpillage, HusbandryModuleBase)

HusbandryModuleBase.registerModule("foodSpillage", HusbandryModuleFoodSpillage)

function HusbandryModuleFoodSpillage:new(customMt)
	local self = HusbandryModuleBase:new(customMt or HusbandryModuleFoodSpillage_mt)

	return self
end

function HusbandryModuleFoodSpillage:delete()
end

function HusbandryModuleFoodSpillage:initDataStructures()
	HusbandryModuleFoodSpillage:superClass().initDataStructures(self)

	self.spillageAreas = {}
	self.foodToDrop = 0
	self.spillageFillType = FillType.UNKNOWN
	self.lineOffset = 0
	self.cleanlinessFactor = 0
	self.hasCleanliness = false
end

function HusbandryModuleFoodSpillage:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleFoodSpillage:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local i = 0

	while true do
		local areaKey = string.format("%s.area(%d)", configKey, i)

		if not hasXMLProperty(xmlFile, areaKey) then
			break
		end

		local start = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, areaKey .. "#startNode"))
		local width = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, areaKey .. "#widthNode"))
		local height = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, areaKey .. "#heightNode"))

		if start ~= nil and width ~= nil and height ~= nil then
			table.insert(self.spillageAreas, {
				start = start,
				width = width,
				height = height
			})
		end

		i = i + 1
	end

	local spillageFillType = getXMLString(xmlFile, configKey .. "#fillType")

	if spillageFillType ~= nil then
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(spillageFillType)

		if fillTypeIndex ~= nil then
			self.spillageFillType = fillTypeIndex
		end
	end

	self.hasCleanliness = true

	return self.spillageFillType ~= nil and #self.spillageAreas > 0
end

function HusbandryModuleFoodSpillage:readStream(streamId, connection)
	HusbandryModuleFoodSpillage:superClass().readStream(self, streamId, connection)

	if self.hasCleanliness then
		self.cleanlinessFactor = streamReadUInt8(streamId) / 255
	end
end

function HusbandryModuleFoodSpillage:writeStream(streamId, connection)
	HusbandryModuleFoodSpillage:superClass().writeStream(self, streamId, connection)

	if self.hasCleanliness then
		local cleanliness = math.floor(self.cleanlinessFactor * 255 + 0.5)

		streamWriteUInt8(streamId, cleanliness)
	end
end

function HusbandryModuleFoodSpillage:readUpdateStream(streamId, timestamp, connection)
	HusbandryModuleFoodSpillage:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if self.hasCleanliness then
		self.cleanlinessFactor = streamReadUInt8(streamId) / 255
	end
end

function HusbandryModuleFoodSpillage:writeUpdateStream(streamId, connection, dirtyMask)
	HusbandryModuleFoodSpillage:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if self.hasCleanliness then
		local cleanliness = math.floor(self.cleanlinessFactor * 255 + 0.5)

		streamWriteUInt8(streamId, cleanliness)
	end
end

function HusbandryModuleFoodSpillage:onIntervalUpdate(dayToInterval)
	HusbandryModuleFoodSpillage:superClass().onIntervalUpdate(self, dayToInterval)
	self:updateCleanlinessFactor(dayToInterval)
end

function HusbandryModuleFoodSpillage:updateCleanlinessFactor(dayToInterval)
	if self.hasCleanliness and self.singleAnimalUsagePerDay > 0 and #self.spillageAreas > 0 then
		local totalNumAnimals = self.owner:getNumOfAnimals()
		local spillageDelta = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval
		local maxSpillageLevel = totalNumAnimals * self.singleAnimalUsagePerDay * 2
		local totalConsumed = 0
		local consumedFood = self.owner:getConsumedFood()

		if consumedFood ~= nil then
			for _, amountConsumed in pairs(consumedFood) do
				totalConsumed = totalConsumed + amountConsumed
			end
		end

		spillageDelta = math.min(spillageDelta, totalConsumed)
		local spillageLevel = self:getFoodSpillageLevel()
		self.cleanlinessFactor = 1 - math.min(1, spillageLevel / maxSpillageLevel)

		if self.cleanlinessFactor > 0 then
			self.foodToDrop = self.foodToDrop + spillageDelta
		end
	end

	if g_densityMapHeightManager:getMinValidLiterValue(self.spillageFillType) < self.foodToDrop then
		local spillageDelta = math.min(self.foodToDrop, 20 * g_densityMapHeightManager:getMinValidLiterValue(self.spillageFillType))
		local dropped = self:updateFoodSpillage(spillageDelta)
		self.foodToDrop = self.foodToDrop - dropped
	end
end

function HusbandryModuleFoodSpillage:loadFromXMLFile(xmlFile, key)
	HusbandryModuleFoodSpillage:superClass().loadFromXMLFile(self, xmlFile, key)

	if self.hasCleanliness then
		self.cleanlinessFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#cleanlinessFactor"), self.cleanlinessFactor)
		self.foodToDrop = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#foodToDrop"), self.foodToDrop)
	end
end

function HusbandryModuleFoodSpillage:saveToXMLFile(xmlFile, key, usedModNames)
	HusbandryModuleFoodSpillage:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	if self.hasCleanliness then
		setXMLFloat(xmlFile, key .. "#cleanlinessFactor", self.cleanlinessFactor)
		setXMLFloat(xmlFile, key .. "#foodToDrop", self.foodToDrop)
	end
end

function HusbandryModuleFoodSpillage:updateFoodSpillage(spillageDelta)
	local foodDropped = 0

	if self.hasCleanliness and self.cleanlinessFactor > 0 and g_densityMapHeightManager:getMinValidLiterValue(self.spillageFillType) < spillageDelta then
		local i = math.random(1, #self.spillageAreas)
		local spillageArea = self.spillageAreas[i]
		local xs, _, zs = getWorldTranslation(spillageArea.start)
		local xw, _, zw = getWorldTranslation(spillageArea.width)
		local xh, _, zh = getWorldTranslation(spillageArea.height)
		local ux = xw - xs
		local uz = zw - zs
		local vx = xh - xs
		local vz = zh - zs
		local vLength = MathUtil.vector2Length(vx, vz)
		local sx = xs + math.random() * ux + math.random() * vx
		local sz = zs + math.random() * uz + math.random() * vz
		local ex = xs + math.random() * ux + math.random() * vx
		local ez = zs + math.random() * uz + math.random() * vz
		local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
		local ey = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, ex, 0, ez)
		local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, spillageDelta, self.spillageFillType, sx, sy, sz, ex, ey, ez, 0, vLength, self.lineOffset, false, nil)
		foodDropped = dropped
		self.lineOffset = lineOffset
	end

	return foodDropped
end

function HusbandryModuleFoodSpillage:getFoodSpillageLevel()
	local totalLevel = 0

	for _, spillageArea in ipairs(self.spillageAreas) do
		local xs, _, zs = getWorldTranslation(spillageArea.start)
		local xw, _, zw = getWorldTranslation(spillageArea.width)
		local xh, _, zh = getWorldTranslation(spillageArea.height)
		local fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.spillageFillType, xs, zs, xw, zw, xh, zh)
		totalLevel = totalLevel + fillLevel
	end

	return totalLevel
end

function HusbandryModuleFoodSpillage:getSpillageFactor()
	if self.hasCleanliness then
		return self.cleanlinessFactor
	end

	return nil
end
