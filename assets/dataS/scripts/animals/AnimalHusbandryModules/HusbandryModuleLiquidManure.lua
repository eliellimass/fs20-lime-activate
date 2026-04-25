HusbandryModuleLiquidManure = {}
local HusbandryModuleLiquidManure_mt = Class(HusbandryModuleLiquidManure, HusbandryModuleBase)

HusbandryModuleBase.registerModule("liquidManure", HusbandryModuleLiquidManure)

function HusbandryModuleLiquidManure:new(customMt)
	return HusbandryModuleBase:new(customMt or HusbandryModuleLiquidManure_mt)
end

function HusbandryModuleLiquidManure:delete()
	g_currentMission:removeLiquidManureSilo(self)
	HusbandryModuleLiquidManure:superClass().delete(self)

	if self.loadPlace ~= nil then
		self.loadPlace:delete()

		self.loadPlace = nil
	end

	if self.fillPlane ~= nil then
		self.fillPlane:delete()

		self.fillPlane = nil
	end
end

function HusbandryModuleLiquidManure:load(xmlFile, configKey, rootNode, owner)
	if not HusbandryModuleLiquidManure:superClass().load(self, xmlFile, configKey, rootNode, owner) then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local liquidManureNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

	if liquidManureNodeId ~= nil then
		local loadPlace = LoadTrigger:new(self.owner.isServer, self.owner.isClient)

		if loadPlace:load(liquidManureNodeId, xmlFile, configKey) then
			loadPlace:setSource(self)
			loadPlace:register(true)

			self.stationName = self.owner:getName()
			self.loadPlace = loadPlace
			self.fillPlane = FillPlane:new()

			self.fillPlane:load(rootNode, xmlFile, configKey .. ".fillPlane")

			for fillTypeIndex, state in pairs(loadPlace.fillTypes) do
				self.fillLevels[fillTypeIndex] = 0
				self.providedFillTypes[fillTypeIndex] = state

				self:setCapacity(0)
			end

			return true
		else
			loadPlace:delete()
		end
	end

	return false
end

function HusbandryModuleLiquidManure:finalizePlacement()
	HusbandryModuleLiquidManure:superClass().finalizePlacement(self)
	g_currentMission:addLiquidManureSilo(self.owner:getName(), self)

	return true
end

function HusbandryModuleLiquidManure:readStream(streamId, connection)
	HusbandryModuleLiquidManure:superClass().readStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		local loadPlaceId = NetworkUtil.readNodeObjectId(streamId)

		self.loadPlace:readStream(streamId, connection)
		g_client:finishRegisterObject(self.loadPlace, loadPlaceId)
	end
end

function HusbandryModuleLiquidManure:writeStream(streamId, connection)
	HusbandryModuleLiquidManure:superClass().writeStream(self, streamId, connection)

	if self.loadPlace ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.loadPlace))
		self.loadPlace:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.loadPlace)
	end
end

function HusbandryModuleLiquidManure:onIntervalUpdate(dayToInterval)
	HusbandryModuleLiquidManure:superClass().onIntervalUpdate(self, dayToInterval)

	if self.singleAnimalUsagePerDay > 0 then
		local totalNumAnimals = self.owner:getNumOfAnimals()
		local hasWater = self.owner:hasWater()

		if hasWater then
			local newLiquidManure = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval

			if newLiquidManure > 0 then
				for fillTypeIndex, _ in pairs(self.fillLevels) do
					self:changeFillLevels(newLiquidManure, fillTypeIndex)
				end

				if self.fillPlane ~= nil then
					self.fillPlane:setState(self:getFillProgress())
				end
			end
		end
	end
end

function HusbandryModuleLiquidManure:getFilltypeInfos()
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

function HusbandryModuleLiquidManure:getIsNodeUsed(node)
	return node == self.loadPlace.triggerNode
end
