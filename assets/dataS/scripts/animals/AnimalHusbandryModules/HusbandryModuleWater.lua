HusbandryModuleWater = {}
local HusbandryModuleWater_mt = Class(HusbandryModuleWater, HusbandryModuleBase)

HusbandryModuleBase.registerModule("water", HusbandryModuleWater)

function HusbandryModuleWater:new(customMt)
	return HusbandryModuleBase:new(customMt or HusbandryModuleWater_mt)
end

function HusbandryModuleWater:delete()
	if self.unloadPlace ~= nil then
		self.unloadPlace:delete()

		self.unloadPlace = nil
	end

	if self.fillPlane ~= nil then
		self.fillPlane:delete()

		self.fillPlane = nil
	end
end

function HusbandryModuleWater:initDataStructures()
	HusbandryModuleWater:superClass().initDataStructures(self)

	self.unloadPlace = nil
end

function HusbandryModuleWater:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleWater:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local waterNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

	if waterNodeId ~= nil then
		local unloadPlace = UnloadTrigger:new(self.owner.isServer, self.owner.isClient)

		if unloadPlace:load(waterNodeId, xmlFile, configKey, self) then
			unloadPlace:register(true)

			self.unloadPlace = unloadPlace
			self.fillPlane = FillPlane:new()

			self.fillPlane:load(rootNode, xmlFile, configKey .. ".fillPlane")

			for fillTypeIndex, state in pairs(unloadPlace.fillTypes) do
				self.fillLevels[fillTypeIndex] = 0
				self.providedFillTypes[fillTypeIndex] = state
			end

			self:setCapacity(0)

			return true
		else
			unloadPlace:delete()

			return false
		end
	end

	return false
end

function HusbandryModuleWater:loadFromXMLFile(xmlFile, key)
	HusbandryModuleWater:superClass().loadFromXMLFile(self, xmlFile, key)
	self:updateFillPlane()
end

function HusbandryModuleWater:readStream(streamId, connection)
	HusbandryModuleWater:superClass().readStream(self, streamId, connection)

	if self.unloadPlace ~= nil then
		local unloadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.unloadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadPlace, unloadPlaceId)
	end
end

function HusbandryModuleWater:writeStream(streamId, connection)
	HusbandryModuleWater:superClass().writeStream(self, streamId, connection)

	if self.unloadPlace ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadPlace))
		self.unloadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadPlace)
	end
end

function HusbandryModuleWater:onIntervalUpdate(dayToInterval)
	HusbandryModuleWater:superClass().onIntervalUpdate(self, dayToInterval)

	if self.singleAnimalUsagePerDay > 0 then
		local totalNumAnimals = self.owner:getNumOfAnimals()
		local waterNeeded = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval

		if waterNeeded > 0 then
			for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
				if fillLevel > 0 then
					self:changeFillLevels(-math.min(waterNeeded, fillLevel), fillTypeIndex)
					self:updateFillPlane()
				end
			end
		end
	end
end

function HusbandryModuleWater:addFillLevelFromTool(farmId, deltaFillLevel, fillType)
	local changed = HusbandryModuleWater:superClass().addFillLevelFromTool(self, farmId, deltaFillLevel, fillType)

	if deltaFillLevel > 0 and changed ~= 0 then
		self.owner:updateGlobalProductionFactor()
	end

	if changed > 0 and self.unloadPlace ~= nil and self.unloadPlace:getIsFillTypeSupported(fillType) then
		self.unloadPlace:raiseActive()
		self:updateFillPlane()
	end

	return changed
end

function HusbandryModuleWater:hasWater()
	local totalWater = 0

	for _, fillLevel in pairs(self.fillLevels) do
		totalWater = totalWater + fillLevel
	end

	return totalWater > 0
end

function HusbandryModuleWater:getFilltypeInfos()
	local result = {}

	for filltypeIndex, val in pairs(self.fillLevels) do
		local fillType = g_fillTypeManager:getFillTypeByIndex(filltypeIndex)
		local capacity = self.unloadPlace.target:getCapacity()
		local fillLevel = self.unloadPlace.target:getFillLevel(filltypeIndex)

		table.insert(result, {
			fillType = fillType,
			fillLevel = fillLevel,
			capacity = capacity
		})
	end

	return result
end

function HusbandryModuleWater:getIsNodeUsed(node)
	return node == self.unloadPlace.exactFillRootNode
end

function HusbandryModuleWater:updateFillPlane()
	if self.fillPlane ~= nil then
		self.fillPlane:setState(self:getFillProgress())
	end
end

function HusbandryModuleWater:onFillProgressChanged()
	self:updateFillPlane()
end
