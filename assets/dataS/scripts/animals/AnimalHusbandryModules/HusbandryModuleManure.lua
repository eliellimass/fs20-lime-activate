HusbandryModuleManure = {}
local HusbandryModuleManure_mt = Class(HusbandryModuleManure, HusbandryModuleBase)

HusbandryModuleBase.registerModule("manure", HusbandryModuleManure)

function HusbandryModuleManure:new(customMt)
	if customMt == nil then
		customMt = HusbandryModuleManure_mt
	end

	local self = HusbandryModuleBase:new(customMt)

	return self
end

function HusbandryModuleManure:delete()
	g_currentMission:removeManureHeap(self)

	if self.manureArea ~= nil then
		g_densityMapHeightManager:removeFixedFillTypesArea(self.manureArea)
	end

	if self.loadTrigger ~= nil then
		self.loadTrigger:delete()
	end

	if self.fillPlane ~= nil then
		self.fillPlane:delete()
	end
end

function HusbandryModuleManure:initDataStructures()
	HusbandryModuleManure:superClass().initDataStructures(self)

	self.manureArea = nil
	self.splittedManureAreas = nil
	self.fillTypeIndex = 0
	self.manureToDrop = 0
	self.manureToRemove = 0
	self.lineOffsetManure = 0
	self.manureHeapName = ""
end

function HusbandryModuleManure:load(xmlFile, configKey, rootNode, owner)
	local result = HusbandryModuleManure:superClass().load(self, xmlFile, configKey, rootNode, owner)

	if result ~= true then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	local manureAreaNodeStart = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#startNode"))
	local manureAreaNodeWidth = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#widthNode"))
	local manureAreaNodeHeight = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#heightNode"))
	local capacity = getXMLFloat(xmlFile, configKey .. "#capacity")

	if capacity ~= nil then
		self.fillCapacity = capacity

		self:setCapacity(capacity, true)
	end

	local fillTypeIndex = nil
	local fillTypeNames = getXMLString(xmlFile, configKey .. "#fillTypes")

	if fillTypeNames ~= nil then
		local fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: HusbandryModuleManure has invalid fillType '%s'.")

		if fillTypes ~= nil and #fillTypes > 0 then
			fillTypeIndex = fillTypes[1]
		end
	end

	if fillTypeIndex ~= nil then
		self.fillTypeIndex = fillTypeIndex

		if manureAreaNodeStart ~= nil and manureAreaNodeWidth ~= nil and manureAreaNodeHeight ~= nil then
			self.manureArea = {
				start = manureAreaNodeStart,
				width = manureAreaNodeWidth,
				height = manureAreaNodeHeight
			}
			self.splittedManureAreas = DensityMapHeightUtil.getAreaPartitions(manureAreaNodeStart, manureAreaNodeWidth, manureAreaNodeHeight)
			local fillTypes = {
				[self.fillTypeIndex] = true
			}

			g_densityMapHeightManager:setFixedFillTypesArea(self.manureArea, fillTypes)
		end

		self.fillLevels[self.fillTypeIndex] = self:getManureLevel()
		local manureNodeId = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#node"))

		if manureNodeId ~= nil then
			local loadTrigger = LoadTrigger:new(self.owner.isServer, self.owner.isClient)

			if loadTrigger:load(manureNodeId, xmlFile, configKey) then
				loadTrigger:setSource(self)
				loadTrigger:register(true)

				self.loadTrigger = loadTrigger

				for _fillTypeIndex, state in pairs(loadTrigger.fillTypes) do
					self.providedFillTypes[_fillTypeIndex] = state
				end

				self.fillPlane = FillPlane:new()

				self.fillPlane:load(rootNode, xmlFile, configKey .. ".fillPlane")

				result = true
			else
				g_logManager:warning("Failed to load LoadTrigger for HusbandryModuleManure.")
				loadTrigger:delete()

				result = false
			end
		end
	else
		g_logManager:warning("Failed to load HusbandryModuleManure. Unable to find drop area or fill type.")

		result = false
	end

	return result
end

function HusbandryModuleManure:finalizePlacement()
	HusbandryModuleManure:superClass().finalizePlacement(self)
	g_currentMission:addManureHeap(self.owner:getName(), self)

	return true
end

function HusbandryModuleManure:onIntervalUpdate(dayToInterval)
	HusbandryModuleManure:superClass().onIntervalUpdate(self, dayToInterval)

	if self.singleAnimalUsagePerDay > 0 then
		local hasStraw = self.owner:hasStraw()

		if hasStraw then
			local minValidLiterValue = g_densityMapHeightManager:getMinValidLiterValue(self.fillTypeIndex)
			local fillLevel = self:getFillLevel(self.fillTypeIndex)

			if self:getCapacity() < fillLevel + self.manureToDrop then
				self.manureToDrop = math.max(self:getCapacity() - fillLevel, minValidLiterValue)
			end

			if minValidLiterValue <= self.manureToDrop then
				local maxManureToDrop = math.min(self.manureToDrop, 200 * minValidLiterValue)
				local dropped = self:updateManure(maxManureToDrop)
				self.manureToDrop = self.manureToDrop - dropped
			end

			local totalNumAnimals = self.owner:getNumOfAnimals()
			local newManure = totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval
			self.manureToDrop = self.manureToDrop + newManure
			local manureLevel = self:getManureLevel()

			self:setFillLevel(self.fillTypeIndex, manureLevel + self.manureToDrop)
		end
	end
end

function HusbandryModuleManure:loadFromXMLFile(xmlFile, key)
	HusbandryModuleManure:superClass().loadFromXMLFile(self, xmlFile, key)

	self.manureToDrop = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#manureToDrop"), self.manureToDrop)
	self.manureToRemove = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#manureToRemove"), self.manureToRemove)
end

function HusbandryModuleManure:saveToXMLFile(xmlFile, key, usedModNames)
	HusbandryModuleManure:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#manureToDrop", self.manureToDrop)
	setXMLFloat(xmlFile, key .. "#manureToRemove", self.manureToRemove)
end

function HusbandryModuleManure:updateManure(manureIncrease)
	local manureDropped = 0

	if self.manureArea ~= nil then
		if g_densityMapHeightManager:getMinValidLiterValue(self.fillTypeIndex) < manureIncrease then
			for _, area in ipairs(self.splittedManureAreas) do
				local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(area.start, area.width, area.height, false)
				local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, manureIncrease, self.fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, radius, area.lineOffset, false, nil)
				area.lineOffset = lineOffset
				manureDropped = manureDropped + dropped
				manureIncrease = manureIncrease - dropped

				if manureIncrease <= 0 then
					break
				end
			end
		end
	else
		manureDropped = manureIncrease
	end

	return manureDropped
end

function HusbandryModuleManure:getManureLevel()
	local fillLevel = nil

	if self.manureArea ~= nil then
		local xs, _, zs = getWorldTranslation(self.manureArea.start)
		local xw, _, zw = getWorldTranslation(self.manureArea.width)
		local xh, _, zh = getWorldTranslation(self.manureArea.height)
		fillLevel = DensityMapHeightUtil.getFillLevelAtArea(self.fillTypeIndex, xs, zs, xw, zw, xh, zh)
	else
		fillLevel = self:getFillLevel(self.fillTypeIndex)
	end

	return fillLevel
end

function HusbandryModuleManure:removeManure(delta)
	local used = 0

	if self.manureArea ~= nil then
		if delta <= self.manureToDrop then
			self.manureToDrop = self.manureToDrop - delta
			used = delta
		else
			self.manureToDrop = self.manureToDrop - delta
			delta = math.abs(self.manureToDrop)
			self.manureToDrop = 0
			self.manureToRemove = self.manureToRemove + delta
			local manureLevel = self:getManureLevel()

			self:setFillLevel(self.fillTypeIndex, manureLevel + self.manureToDrop)

			if self.manureToRemove < manureLevel then
				used = delta

				if g_densityMapHeightManager:getMinValidLiterValue(self.fillTypeIndex) < self.manureToRemove then
					for _, area in ipairs(self.splittedManureAreas) do
						local lsx, lsy, lsz, lex, ley, lez, radius = DensityMapHeightUtil.getLineByArea(area.start, area.width, area.height, true)
						local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, -self.manureToRemove, self.fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, radius, radius, area.lineOffset, false, nil)
						area.lineOffset = lineOffset
						self.manureToRemove = math.max(self.manureToRemove + dropped, 0)

						if self.manureToRemove <= 0 then
							break
						end
					end
				end
			end
		end
	else
		local manureLevel = self:getManureLevel()

		self:setFillLevel(self.fillTypeIndex, manureLevel - delta)

		used = math.abs(delta)
	end

	return used
end

function HusbandryModuleManure:changeFillLevels(fillDelta, fillTypeIndex)
	if fillTypeIndex == self.fillTypeIndex and fillDelta < 0 then
		return self:removeManure(-fillDelta)
	end

	return 0
end

function HusbandryModuleManure:getFilltypeInfos()
	local result = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(self.fillTypeIndex)
	local capacity = self:getCapacity()
	local fillLevel = self:getFillLevel(self.fillTypeIndex)

	table.insert(result, {
		fillType = fillType,
		fillLevel = fillLevel,
		capacity = capacity
	})

	return result
end

function HusbandryModuleManure:getIsNodeUsed(node)
	return self.loadTrigger ~= nil and node == self.loadTrigger.triggerNode
end

function HusbandryModuleManure:setFillLevel(fillTypeIndex, fillLevel)
	HusbandryModuleManure:superClass().setFillLevel(self, fillTypeIndex, fillLevel)

	if self.fillPlane ~= nil then
		self.fillPlane:setState(fillLevel / self:getCapacity())
	end
end

function HusbandryModuleManure:setCapacity(capacity, forced)
	if self.fillCapacity == nil or self.fillCapacity == 0 or forced then
		HusbandryModuleManure:superClass().setCapacity(self, capacity)
	end
end
