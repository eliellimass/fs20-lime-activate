HusbandryModulePallets = {}
local HusbandryModulePallets_mt = Class(HusbandryModulePallets, HusbandryModuleBase)

HusbandryModuleBase.registerModule("pallets", HusbandryModulePallets)

HusbandryModulePallets.fillLevelThresholdForDeletion = 1

function HusbandryModulePallets:new(isServer, isClient, mt)
	local self = HusbandryModuleBase:new(mt or HusbandryModulePallets_mt)
	self.palletSpawnerNode = nil
	self.palletFillTypeIndex = nil
	self.palletConfigFilename = ""
	self.palletSpawnerAreaSizeX = 0
	self.palletSpawnerAreaSizeZ = 0
	self.palletSpawnerFillDelta = 0
	self.palletFillUnitIndex = 0
	self.numObjectsInPalletSpawnerTrigger = 0
	self.currentPallet = nil
	self.palletSpawnerCollisionObjectId = 0
	self.availablePallet = nil

	return self
end

function HusbandryModulePallets:load(xmlFile, configKey, rootNode, owner)
	local result = HusbandryModulePallets:superClass().load(self, xmlFile, configKey, rootNode, owner)

	if result ~= true then
		return false
	end

	if not hasXMLProperty(xmlFile, configKey) then
		return false
	end

	self.palletSpawnerStartNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#startNode"))
	self.palletSpawnerWidthNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#widthNode"))
	self.palletSpawnerHeightNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, configKey .. "#heightNode"))
	local xw, yw, zw = getTranslation(self.palletSpawnerWidthNode)

	if xw == 0 or math.abs(yw) > 0.001 or math.abs(zw) > 0.001 then
		g_logManager:devWarning(string.format("Warning: width node of husbandry module pallets has incorrect parameters x(%.3f), y(%.3f), z(%.3f).", xw, yw, zw))

		return false
	end

	local xh, yh, zh = getTranslation(self.palletSpawnerHeightNode)

	if math.abs(xh) > 0.001 or math.abs(yh) > 0.001 or zh == 0 then
		g_logManager:devWarning(string.format("Warning: height node of husbandry module pallets has incorrect parameters x(%.3f), y(%.3f), z(%.3f).", xh, yh, zh))

		return false
	end

	self.palletSpawnerNode = self.palletSpawnerStartNode
	self.palletSpawnerAreaSizeX = xw
	self.palletSpawnerAreaSizeZ = zh
	self.palletSpawnerAreaDetectScale = getXMLFloat(xmlFile, configKey .. "#palletDetectScale") or 1
	local fillTypeStr = getXMLString(xmlFile, configKey .. "#fillType")
	self.palletFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
	self.palletConfigFilename = Utils.getNoNil(getXMLString(xmlFile, configKey .. "#filename"), "")
	self.palletConfigFilename = Utils.getFilename(self.palletConfigFilename, self.baseDirectory)
	self.palletFillUnitIndex = getXMLFloat(xmlFile, configKey .. "#fillUnitIndex")
	self.sizeWidth, self.sizeLength, _, _ = StoreItemUtil.getSizeValues(self.palletConfigFilename, "vehicle", 0, {})
	self.fillLevels[self.palletFillTypeIndex] = 0
	self.palletSpawnerFillDelta = 0
	self.numObjectsInPalletSpawnerTrigger = 0

	return self.palletSpawnerNode ~= nil and self.palletFillTypeIndex ~= nil and self.palletConfigFilename ~= "" and self.palletFillUnitIndex ~= nil
end

function HusbandryModulePallets:onIntervalUpdate(dayToInterval)
	HusbandryModulePallets:superClass().onIntervalUpdate(self, dayToInterval)

	local totalNumAnimals = self.owner:getNumOfAnimals()

	if self.singleAnimalUsagePerDay > 0 and totalNumAnimals > 0 then
		local productivity = self.owner:getGlobalProductionFactor()
		local fillDelta = productivity * totalNumAnimals * self.singleAnimalUsagePerDay * dayToInterval
		self.palletSpawnerFillDelta = self.palletSpawnerFillDelta + fillDelta

		if productivity > 0 and self.palletSpawnerFillDelta > 0 then
			if self.currentPallet ~= nil and self.currentPallet:getFillUnitFreeCapacity(self.palletFillUnitIndex) < 0.001 then
				self.currentPallet = nil
			end

			if self.currentPallet ~= nil then
				if not entityExists(self.currentPallet.rootNode) then
					self.currentPallet = nil
				else
					local x, _, z = localToLocal(self.currentPallet.rootNode, self.palletSpawnerNode, 0, 0, 0)
					local addX = (self.palletSpawnerAreaSizeX * self.palletSpawnerAreaDetectScale - self.palletSpawnerAreaSizeX) * 0.5
					local addZ = (self.palletSpawnerAreaSizeZ * self.palletSpawnerAreaDetectScale - self.palletSpawnerAreaSizeZ) * 0.5

					if x < -addX or z < -addZ or x > self.palletSpawnerAreaSizeX + addX or z > self.palletSpawnerAreaSizeZ + addZ then
						self.currentPallet = nil
					end
				end
			end

			if self.currentPallet == nil then
				self.availablePallet = nil
				local x, y, z = localToWorld(self.palletSpawnerNode, 0.5 * self.palletSpawnerAreaSizeX * self.palletSpawnerAreaDetectScale, 0, 0.5 * self.palletSpawnerAreaSizeZ * self.palletSpawnerAreaDetectScale)
				local rx, ry, rz = getWorldRotation(self.palletSpawnerNode)
				local nbShapesOverlap = overlapBox(x, y - 5, z, rx, ry, rz, 0.5 * self.palletSpawnerAreaSizeX * self.palletSpawnerAreaDetectScale, 10, 0.5 * self.palletSpawnerAreaSizeZ * self.palletSpawnerAreaDetectScale, "palletSpawnerCollisionTestCallback", self, nil, true, false, true)

				if self.availablePallet ~= nil then
					self.currentPallet = self.availablePallet
				end
			end

			if self.currentPallet == nil then
				local rx, ry, rz = getWorldRotation(self.palletSpawnerNode)
				local x, y, z = getWorldTranslation(self.palletSpawnerNode)
				local canCreatePallet = false
				local widthHalf = self.sizeWidth * 0.5
				local heightHalf = self.sizeLength * 0.5

				for dx = widthHalf, self.palletSpawnerAreaSizeX - widthHalf, widthHalf do
					for dz = heightHalf, self.palletSpawnerAreaSizeZ - heightHalf, widthHalf do
						x, y, z = localToWorld(self.palletSpawnerNode, dx, 0, dz)
						self.palletSpawnerCollisionObjectId = 0
						local nbShapesOverlap = overlapBox(x, y - 5, z, rx, ry, rz, widthHalf, 10, heightHalf, "palletSpawnerCollisionTestCallback", self, 8192, true, false, true)

						if self.palletSpawnerCollisionObjectId == 0 then
							canCreatePallet = true

							break
						end
					end

					if canCreatePallet then
						break
					end
				end

				if canCreatePallet and HusbandryModulePallets.fillLevelThresholdForDeletion < self.palletSpawnerFillDelta then
					self.currentPallet = g_currentMission:loadVehicle(self.palletConfigFilename, x, nil, z, 1.2, ry, true, 0, Vehicle.PROPERTY_STATE_OWNED, self.owner:getOwnerFarmId(), nil, )
				end
			end

			if self.currentPallet ~= nil then
				self.palletSpawnerFillDelta = self.currentPallet:addFillUnitFillLevel(self.owner:getOwnerFarmId(), self.palletFillUnitIndex, self.palletSpawnerFillDelta, self.palletFillTypeIndex, ToolType.UNDEFINED)

				self:setFillLevel(self.palletFillUnitIndex, self:getCurrentPalletFillLevel())
			elseif HusbandryModulePallets.fillLevelThresholdForDeletion < self.palletSpawnerFillDelta then
				self:showSpawnerBlockedWarning()
			end
		end
	end
end

function HusbandryModulePallets:showSpawnerBlockedWarning()
	if self.owner.isServer then
		g_currentMission:broadcastEventToFarm(AnimalHusbandryNoMorePalletSpaceEvent:new(self.owner), self.owner:getOwnerFarmId(), false)
	end

	if self.owner.isClient and g_currentMission:getFarmId() == self.owner:getOwnerFarmId() then
		local fillType = g_fillTypeManager:getFillTypeByIndex(self.palletFillTypeIndex)

		if fillType ~= nil then
			local animalTypeString = g_i18n:getText("ui_statisticView_" .. tostring(self.owner:getAnimalType()):lower(), g_currentMission.missionInfo.customEnvironment)
			local text = string.format(g_i18n:getText("ingameNotification_palletSpawnerBlocked"), fillType.title, animalTypeString)

			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
		end
	end
end

function HusbandryModulePallets:loadFromXMLFile(xmlFile, key)
	HusbandryModulePallets:superClass().loadFromXMLFile(self, xmlFile, key)

	self.palletSpawnerFillDelta = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#palletFillDelta"), self.palletSpawnerFillDelta)
end

function HusbandryModulePallets:saveToXMLFile(xmlFile, key, usedModNames)
	HusbandryModulePallets:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#palletFillDelta", self.palletSpawnerFillDelta)
end

function HusbandryModulePallets:palletSpawnerCollisionTestCallback(transformId)
	if transformId ~= g_currentMission.terrainRootNode and transformId ~= self.palletSpawnerNode and not Utils.getNoNil(getUserAttribute(transformId, "allowPalletSpawning"), false) then
		self.palletSpawnerCollisionObjectId = transformId
		local object = g_currentMission:getNodeObject(transformId)

		if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and object.typeName == "pallet" and object:getFillUnitFillLevel(self.palletFillUnitIndex) < object:getFillUnitCapacity(self.palletFillUnitIndex) then
			local x, _, z = localToLocal(object.rootNode, self.palletSpawnerNode, 0, 0, 0)

			if x >= 0 and z >= 0 and self.palletSpawnerAreaSizeX >= x and self.palletSpawnerAreaSizeZ >= z then
				self.availablePallet = object
			end
		end
	end

	return self.availablePallet == nil
end

function HusbandryModulePallets:getCurrentPalletFillLevel()
	local capacity = 0
	local fillLevel = 0

	if self.currentPallet ~= nil then
		fillLevel = self.currentPallet:getFillUnitFillLevel(self.palletFillUnitIndex)
		capacity = self.currentPallet:getFillUnitCapacity(self.palletFillUnitIndex)
	end

	return fillLevel, capacity
end

function HusbandryModulePallets:getFilltypeInfos()
	local result = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(self.palletFillTypeIndex)

	table.insert(result, {
		capacity = 0,
		fillType = fillType,
		fillLevel = self:getFillLevel(self.palletFillUnitIndex)
	})

	return result
end
