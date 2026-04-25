HusbandryModuleBase = {}
local HusbandryModuleBase_mt = Class(HusbandryModuleBase)

function HusbandryModuleBase:new(customMt)
	if customMt == nil then
		customMt = HusbandryModuleBase_mt
	end

	local self = {}

	setmetatable(self, customMt)
	self:initDataStructures()

	self.owner = nil

	return self
end

function HusbandryModuleBase:initDataStructures()
	self.fillLevels = {}
	self.fillCapacity = 0
	self.providedFillTypes = {}
	self.singleAnimalUsagePerDay = 0
end

function HusbandryModuleBase:delete()
	self.owner = nil
end

function HusbandryModuleBase:load(xmlFile, configKey, rootNode, owner)
	self.owner = owner

	return true
end

function HusbandryModuleBase:finalizePlacement()
	return true
end

function HusbandryModuleBase:onSell()
	self.fillLevels = {}
	self.fillCapacity = 0
	self.providedFillTypes = {}
	self.singleAnimalUsagePerDay = 0
end

function HusbandryModuleBase:onIntervalUpdate(dayToInterval)
end

function HusbandryModuleBase:onQuarterHourChanged()
end

function HusbandryModuleBase:onHourChanged()
end

function HusbandryModuleBase:onDayChanged()
end

function HusbandryModuleBase:update(dt)
end

function HusbandryModuleBase:readStream(streamId, connection)
	local nbFillLevel = streamReadUInt8(streamId)

	for i = 1, nbFillLevel do
		local fillTypeIndex = streamReadUInt8(streamId)
		local fillLevel = streamReadFloat32(streamId)

		self:setFillLevel(fillTypeIndex, fillLevel)
	end
end

function HusbandryModuleBase:writeStream(streamId, connection)
	local nbFillLevel = 0

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		nbFillLevel = nbFillLevel + 1
	end

	streamWriteUInt8(streamId, nbFillLevel)

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		streamWriteUInt8(streamId, fillTypeIndex)
		streamWriteFloat32(streamId, fillLevel)
	end
end

function HusbandryModuleBase:readUpdateStream(streamId, timestamp, connection)
	local nbFillLevel = streamReadUInt8(streamId)

	for i = 1, nbFillLevel do
		local fillTypeIndex = streamReadUInt8(streamId)
		local fillLevel = streamReadFloat32(streamId)

		self:setFillLevel(fillTypeIndex, fillLevel)
	end
end

function HusbandryModuleBase:writeUpdateStream(streamId, connection, dirtyMask)
	local nbFillLevel = 0

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		nbFillLevel = nbFillLevel + 1
	end

	streamWriteUInt8(streamId, nbFillLevel)

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		streamWriteUInt8(streamId, fillTypeIndex)
		streamWriteFloat32(streamId, fillLevel)
	end
end

function HusbandryModuleBase:loadFromXMLFile(xmlFile, key)
	self.fillCapacity = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#fillCapacity"), self.fillCapacity)
	local i = 0

	while true do
		local fillLevelKey = key .. string.format(".fillLevel(%d)", i)

		if not hasXMLProperty(xmlFile, fillLevelKey) then
			break
		end

		local fillTypeName = getXMLString(xmlFile, fillLevelKey .. "#fillType")
		local fillLevel = getXMLFloat(xmlFile, fillLevelKey .. "#fillLevel")

		if fillTypeName ~= nil and fillLevel ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

			if fillTypeIndex ~= nil then
				self:setFillLevel(fillTypeIndex, fillLevel)

				self.providedFillTypes[fillTypeIndex] = true
			end
		end

		i = i + 1
	end
end

function HusbandryModuleBase:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#fillCapacity", self.fillCapacity)

	local index = 0

	for fillTypeIndex, state in pairs(self.providedFillTypes) do
		if state then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)

			if fillTypeName ~= nil then
				local fillLevel = self.fillLevels[fillTypeIndex]

				if fillLevel ~= nil then
					local fillLevelKey = string.format("%s.fillLevel(%d)", key, index)

					setXMLString(xmlFile, fillLevelKey .. "#fillType", fillTypeName)
					setXMLFloat(xmlFile, fillLevelKey .. "#fillLevel", fillLevel)

					index = index + 1
				end
			end
		end
	end
end

function HusbandryModuleBase:getIsFillTypeAllowed(fillTypeIndex)
	for fTypeIndex, state in pairs(self.providedFillTypes) do
		if fTypeIndex == fillTypeIndex and state then
			return true
		end
	end

	return false
end

function HusbandryModuleBase:getIsToolTypeAllowed(toolType)
	return true
end

function HusbandryModuleBase:getHasSpaceForUnloading()
	return self:getTotalFillLevel() <= self:getCapacity()
end

function HusbandryModuleBase:changeFillLevels(fillDelta, fillTypeIndex)
	local delta = 0

	if self.fillLevels[fillTypeIndex] ~= nil then
		local oldFillLevel = self.fillLevels[fillTypeIndex]
		local newFillLevel = oldFillLevel + fillDelta
		newFillLevel = math.max(newFillLevel, 0)
		delta = newFillLevel - oldFillLevel
		local oldTotalFillLevel = self:getTotalFillLevel()
		local capacity = self:getCapacity()
		local newTotalFillLevel = oldTotalFillLevel + delta
		newTotalFillLevel = MathUtil.clamp(newTotalFillLevel, 0, capacity)
		delta = newTotalFillLevel - oldTotalFillLevel

		self:setFillLevel(fillTypeIndex, newTotalFillLevel)
	end

	return delta
end

function HusbandryModuleBase:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex)
	if not self:getHasSpaceForUnloading() then
		return 0
	end

	local changed = 0
	changed = self:changeFillLevels(deltaFillLevel, fillTypeIndex)

	return changed
end

function HusbandryModuleBase:getFillLevel(fillTypeIndex)
	return Utils.getNoNil(self.fillLevels[fillTypeIndex], 0)
end

function HusbandryModuleBase:setFillLevel(fillTypeIndex, fillLevel)
	if self.fillLevels[fillTypeIndex] ~= fillLevel then
		self.fillLevels[fillTypeIndex] = fillLevel

		self:onFillProgressChanged()

		if self.owner.isServer then
			self.owner:raiseDirtyFlags(self.owner.husbandryDirtyFlag)
		end
	end
end

function HusbandryModuleBase:getTotalFillLevel()
	local totalFillLevel = 0

	for _, fillLevel in pairs(self.fillLevels) do
		totalFillLevel = totalFillLevel + fillLevel
	end

	return totalFillLevel
end

function HusbandryModuleBase:setCapacity(newCapacity)
	self.fillCapacity = newCapacity

	self:onFillProgressChanged()
end

function HusbandryModuleBase:getFreeCapacity(fillTypeIndex)
	return self:getCapacity() - self:getFillLevel(fillTypeIndex)
end

function HusbandryModuleBase:setSingleAnimalUsagePerDay(usagePerDay)
	self.singleAnimalUsagePerDay = usagePerDay
end

function HusbandryModuleBase:getCapacity()
	return self.fillCapacity
end

function HusbandryModuleBase:getFillProgress()
	local capacity = self:getCapacity()

	if capacity > 0 then
		local progress = self:getTotalFillLevel() / capacity
		progress = MathUtil.clamp(progress, 0, 1)

		return progress
	end

	return 0
end

function HusbandryModuleBase:getProvidedFillTypes()
	return self.providedFillTypes
end

function HusbandryModuleBase:getIsNodeUsed(node)
	return false
end

function HusbandryModuleBase:getAllFillLevels()
	local fillLevels = {}
	local capacity = self:getCapacity()

	for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
		fillLevels[fillTypeIndex] = fillLevel
	end

	return fillLevels, capacity
end

function HusbandryModuleBase:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillableObject == 0 or fillableObject == self then
		return 0
	end

	local oldFillLevel = self:getFillLevel(fillTypeIndex)
	fillDelta = math.min(fillDelta, oldFillLevel)
	local actualDelta = fillableObject:addFillUnitFillLevel(self.owner:getOwnerFarmId(), fillUnitIndex, fillDelta, fillTypeIndex, ToolType.UNDEFINED, fillInfo)
	actualDelta = self:changeFillLevels(-actualDelta, fillTypeIndex)

	return actualDelta
end

function HusbandryModuleBase:getIsFillAllowedToFarm(farmId)
	return g_currentMission.accessHandler:canFarmAccess(farmId, self.owner)
end

function HusbandryModuleBase:getIsInUse()
	return false
end

function HusbandryModuleBase:onFillProgressChanged()
end

local registry = {}

function HusbandryModuleBase.registerModule(moduleName, moduleType)
	registry[moduleName] = moduleType
end

function HusbandryModuleBase.createModule(moduleName)
	local moduleType = registry[moduleName]
	local moduleInstance = nil

	if moduleType ~= nil then
		moduleInstance = moduleType.new()
	end

	return moduleInstance
end

function HusbandryModuleBase.hasModule(moduleName)
	return registry[moduleName] ~= nil
end
