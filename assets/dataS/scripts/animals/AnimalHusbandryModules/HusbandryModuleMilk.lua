HusbandryModuleMilk = {}
local HusbandryModuleMilk_mt = Class(HusbandryModuleMilk, HusbandryModuleBase)

HusbandryModuleBase.registerModule("milk", HusbandryModuleMilk)

function HusbandryModuleMilk:new(customMt)
	if customMt == nil then
		customMt = HusbandryModuleMilk_mt
	end

	local self = HusbandryModuleBase:new(customMt)

	return self
end

function HusbandryModuleMilk:delete()
	HusbandryModuleMilk:superClass().delete(self)

	if self.loadPlace ~= nil then
		self.loadPlace:delete()

		self.loadPlace = nil
	end
end

function HusbandryModuleMilk:load(xmlFile, configKey, rootNode, owner)
	local result = HusbandryModuleMilk:superClass().load(self, xmlFile, configKey, rootNode, owner)

	if result ~= true then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local milkTankNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

	if milkTankNodeId ~= nil then
		local loadPlace = LoadTrigger:new(self.owner.isServer, self.owner.isClient)
		self.stationName = self.owner:getName()

		if loadPlace:load(milkTankNodeId, xmlFile, configKey) then
			loadPlace:setSource(self)
			loadPlace:register(true)

			self.loadPlace = loadPlace

			for fillTypeIndex, state in pairs(loadPlace.fillTypes) do
				self.fillLevels[fillTypeIndex] = 0
				self.providedFillTypes[fillTypeIndex] = state
			end

			self:setCapacity(0)

			return true
		else
			loadPlace:delete()
		end
	end

	return false
end

function HusbandryModuleMilk:readStream(streamId, connection)
	HusbandryModuleMilk:superClass().readStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		local loadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.loadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.loadPlace, loadPlaceId)
	end
end

function HusbandryModuleMilk:writeStream(streamId, connection)
	HusbandryModuleMilk:superClass().writeStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadPlace))
		self.loadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.loadPlace)
	end
end

function HusbandryModuleMilk:onIntervalUpdate(dayToInterval)
	HusbandryModuleMilk:superClass().onIntervalUpdate(self, dayToInterval)

	if self.singleAnimalUsagePerDay > 0 then
		local hasWater = self.owner:hasWater()

		if hasWater then
			local totalNumAnimals = self.owner:getNumOfAnimals()
			local newMilk = self.owner:getGlobalProductionFactor() * totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval

			if newMilk > 0 then
				for fillTypeIndex, state in pairs(self.loadPlace.fillTypes) do
					self:changeFillLevels(newMilk, fillTypeIndex)
				end
			end
		end
	end
end

function HusbandryModuleMilk:getFilltypeInfos()
	local result = {}

	for fillTypeIndex, _ in pairs(self.loadPlace.fillTypes) do
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		local capacity = self:getCapacity()
		local fillLevel = self:getFillLevel(fillTypeIndex)

		table.insert(result, {
			fillType = fillType,
			fillLevel = fillLevel,
			capacity = capacity
		})
	end

	return result
end

function HusbandryModuleMilk:getIsNodeUsed(node)
	return node == self.loadPlace.triggerNode
end
