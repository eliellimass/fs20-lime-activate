HusbandryModuleStraw = {}
local HusbandryModuleStraw_mt = Class(HusbandryModuleStraw, HusbandryModuleBase)

HusbandryModuleBase.registerModule("straw", HusbandryModuleStraw)

function HusbandryModuleStraw:new(customMt)
	return HusbandryModuleBase:new(customMt or HusbandryModuleStraw_mt)
end

function HusbandryModuleStraw:delete()
	if self.unloadPlace ~= nil then
		self.unloadPlace:delete()

		self.unloadPlace = nil
	end

	if self.fillPlane ~= nil then
		self.fillPlane:delete()

		self.fillPlane = nil
	end
end

function HusbandryModuleStraw:initDataStructures()
	HusbandryModuleStraw:superClass().initDataStructures(self)

	self.unloadPlace = nil
end

function HusbandryModuleStraw:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleStraw:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local strawNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

	if strawNodeId ~= nil then
		local unloadPlace = UnloadTrigger:new(self.owner.isServer, self.owner.isClient)

		if unloadPlace:load(strawNodeId, xmlFile, configKey, self) then
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

function HusbandryModuleStraw:loadFromXMLFile(xmlFile, key)
	HusbandryModuleWater:superClass().loadFromXMLFile(self, xmlFile, key)

	if self.fillPlane ~= nil then
		self.fillPlane:setState(self:getFillProgress())
	end
end

function HusbandryModuleStraw:readStream(streamId, connection)
	HusbandryModuleStraw:superClass().readStream(self, streamId, connection)

	if self.unloadPlace ~= nil then
		local unloadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.unloadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.unloadPlace, unloadPlaceId)
	end

	self:updateFillPlane()
end

function HusbandryModuleStraw:writeStream(streamId, connection)
	HusbandryModuleStraw:superClass().writeStream(self, streamId, connection)

	if self.unloadPlace ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.unloadPlace))
		self.unloadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.unloadPlace)
	end
end

function HusbandryModuleStraw:onIntervalUpdate(dayToInterval)
	HusbandryModuleStraw:superClass().onIntervalUpdate(self, dayToInterval)

	if self.singleAnimalUsagePerDay > 0 then
		local totalNumAnimals = self.owner:getNumOfAnimals()
		local strawNeeded = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval

		if strawNeeded > 0 then
			for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
				if fillLevel > 0 then
					self:changeFillLevels(-math.min(strawNeeded, fillLevel), fillTypeIndex)
					self:updateFillPlane()
				end
			end
		end
	end
end

function HusbandryModuleStraw:addFillLevelFromTool(farmId, deltaFillLevel, fillType)
	local changed = HusbandryModuleStraw:superClass().addFillLevelFromTool(self, farmId, deltaFillLevel, fillType)

	if deltaFillLevel > 0 and changed ~= 0 then
		self.owner:updateGlobalProductionFactor()
	end

	if changed > 0 and self.unloadPlace ~= nil and self.unloadPlace:getIsFillTypeSupported(fillType) then
		self.unloadPlace:raiseActive()
		self:updateFillPlane()
	end

	return changed
end

function HusbandryModuleStraw:hasStraw()
	local totalStraw = 0

	for _, fillLevel in pairs(self.fillLevels) do
		totalStraw = totalStraw + fillLevel
	end

	return totalStraw > 0
end

function HusbandryModuleStraw:getFilltypeInfos()
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

function HusbandryModuleStraw:getIsNodeUsed(node)
	return node == self.unloadPlace.exactFillRootNode
end

function HusbandryModuleStraw:updateFillPlane()
	if self.fillPlane ~= nil then
		local fillPlaneFactor = self:getFillProgress()

		self.fillPlane:setState(fillPlaneFactor)
	end
end

function HusbandryModuleStraw:onFillProgressChanged()
	self:updateFillPlane()
end
