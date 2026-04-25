source("dataS/scripts/events/WoodSellEvent.lua")

WoodSellStationPlaceable = {}
local WoodSellStationPlaceable_mt = Class(WoodSellStationPlaceable, Placeable)

InitStaticObjectClass(WoodSellStationPlaceable, "WoodSellStationPlaceable", ObjectIds.OBJECT_WOOD_SELL_STATION_PLACEABLE)

function WoodSellStationPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or WoodSellStationPlaceable_mt)

	registerObjectClassName(self, "WoodSellStationPlaceable")

	self.woodInTrigger = {}

	return self
end

function WoodSellStationPlaceable:delete()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end

	if self.woodSellTrigger ~= nil then
		removeTrigger(self.woodSellTrigger)

		self.woodSellTrigger = nil
	end

	if self.sellTrigger ~= nil then
		g_currentMission:removeActivatableObject(self)
		removeTrigger(self.sellTrigger)

		self.sellTrigger = nil
	end

	unregisterObjectClassName(self)
	WoodSellStationPlaceable:superClass().delete(self)
end

function WoodSellStationPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not WoodSellStationPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.appearsOnPDA = Utils.getNoNil(getXMLBool(xmlFile, "placeable.woodSellStation#appearsOnPDA"), false)
	local rawName = Utils.getNoNil(getXMLString(xmlFile, "placeable.woodSellStation#stationName"), "WoodSellStation")
	self.stationName = g_i18n:convertText(rawName)
	local woodSellTrigger = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.woodSellStation#triggerNode"))

	if woodSellTrigger == nil then
		g_logManager:xmlWarning(xmlFilename, "Missing wood trigger node in 'placeable.woodSellStation#triggerNode'!")
		delete(xmlFile)

		return false
	end

	local colMask = getCollisionMask(woodSellTrigger)

	if bitAND(SplitTypeManager.COLLISIONMASK_TRIGGER, colMask) == 0 then
		g_logManager:xmlWarning(xmlFilename, "Invalid collision mask for wood trigger 'placeable.woodSellStation#triggerNode'. Bit 24 needs to be set!")
		delete(xmlFile)

		return false
	end

	addTrigger(woodSellTrigger, "woodTriggerCallback", self)

	self.woodSellTrigger = woodSellTrigger
	local sellTrigger = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.woodSellStation#sellTrigger"))

	if sellTrigger == nil then
		g_logManager:xmlWarning(xmlFilename, "Missing sell trigger in 'placeable.woodSellStation#sellTrigger'!")
		delete(xmlFile)

		return false
	end

	colMask = getCollisionMask(sellTrigger)

	if bitAND(Player.COLLISIONMASK_TRIGGER, colMask) == 0 then
		g_logManager:xmlWarning(xmlFilename, "Invalid collision mask for sell trigger 'placeable.woodSellStation#triggerNode'. Bit 20 needs to be set!")
		delete(xmlFile)

		return false
	end

	if self.appearsOnPDA then
		local mapPosition = self.woodSellTrigger
		local mapPositionIndex = getUserAttribute(self.woodSellTrigger, "mapPositionIndex")

		if mapPositionIndex ~= nil then
			mapPosition = I3DUtil.indexToObject(self.woodSellTrigger, mapPositionIndex)

			if mapPosition == nil then
				mapPosition = self.woodSellTrigger
			end
		end

		self.mapHotspot = MapHotspot.loadFromXML(xmlFile, key .. ".mapHotspot", mapPosition, self.baseDirectory)

		g_currentMission:addMapHotspot(self.mapHotspot)
	end

	addTrigger(sellTrigger, "woodSellTriggerCallback", self)

	self.sellTrigger = sellTrigger
	self.activateText = g_i18n:getText("action_sellWood")
	self.objectActivated = false
	self.updateEventListeners = {}

	delete(xmlFile)

	return true
end

function WoodSellStationPlaceable:sellWood(farmId)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(WoodSellEvent:new(self, farmId))

		return
	end

	local soldWood = false
	local totalPrice = 0
	local totalVolume = 0
	local difficultyMultiplier = g_currentMission.missionInfo.sellPriceMultiplier

	for _, nodeId in pairs(self.woodInTrigger) do
		if entityExists(nodeId) then
			soldWood = true
			local baseValue = self:calculateBaseValue(nodeId)
			totalPrice = totalPrice + baseValue * difficultyMultiplier

			if g_currentMission:getIsServer() then
				totalVolume = totalVolume + getVolume(nodeId)

				delete(nodeId)
			end
		end

		self.woodInTrigger[nodeId] = nil
	end

	if soldWood then
		for _, listener in pairs(self.updateEventListeners) do
			listener:onWoodSellingUpdateEvent(self, totalPrice)
		end

		if g_currentMission:getIsServer() then
			g_currentMission:farmStats():updateStats("woodTonsSold", totalVolume)
			g_currentMission:addMoney(totalPrice, farmId, MoneyType.SOLD_WOOD, true, true)
		end
	end
end

function WoodSellStationPlaceable:woodTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if otherActorId ~= 0 then
		local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(otherActorId))

		if splitType ~= nil and splitType.pricePerLiter > 0 then
			if onEnter then
				self.woodInTrigger[otherActorId] = otherActorId
			else
				self.woodInTrigger[otherActorId] = nil
			end
		end
	end
end

function WoodSellStationPlaceable:addUpdateEventListener(listener)
	if listener ~= nil then
		self.updateEventListeners[listener] = listener
	end
end

function WoodSellStationPlaceable:removeUpdateEventListener(listener)
	if listener ~= nil then
		self.updateEventListeners[listener] = nil
	end
end

function WoodSellStationPlaceable:calculateBaseValue(objectId)
	local volume = getVolume(objectId)
	local splitType = g_splitTypeManager:getSplitTypeByIndex(getSplitType(objectId))
	local qualityScale = 1
	local lengthScale = 1
	local defoliageScale = 1
	local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(objectId)

	if sizeX ~= nil and volume > 0 then
		local bvVolume = sizeX * sizeY * sizeZ
		local volumeRatio = bvVolume / volume
		local volumeQuality = 1 - math.sqrt(MathUtil.clamp((volumeRatio - 3) / 7, 0, 1)) * 0.95
		local convexityQuality = 1 - MathUtil.clamp((numConvexes - 2) / 4, 0, 1) * 0.95
		local maxSize = math.max(sizeX, math.max(sizeY, sizeZ))

		if maxSize < 11 then
			lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6
		else
			lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
		end

		local minQuality = math.min(convexityQuality, volumeQuality)
		local maxQuality = math.max(convexityQuality, volumeQuality)
		qualityScale = minQuality + (maxQuality - minQuality) * 0.3
		defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8
	end

	qualityScale = MathUtil.lerp(1, qualityScale, g_currentMission.missionInfo.economicDifficulty / 3)
	defoliageScale = MathUtil.lerp(1, defoliageScale, g_currentMission.missionInfo.economicDifficulty / 3)

	return volume * 1000 * splitType.pricePerLiter * qualityScale * defoliageScale * lengthScale
end

function WoodSellStationPlaceable:woodSellTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		if onEnter then
			if not self.objectActivated then
				g_currentMission:addActivatableObject(self)

				self.objectActivated = true
			end
		elseif self.objectActivated then
			g_currentMission:removeActivatableObject(self)

			self.objectActivated = false
		end
	end
end

function WoodSellStationPlaceable:getIsActivatable()
	return g_currentMission.controlPlayer
end

function WoodSellStationPlaceable:drawActivate()
end

function WoodSellStationPlaceable:onActivateObject()
	g_currentMission:addActivatableObject(self)

	self.objectActivated = true

	self:sellWood(g_currentMission:getFarmId())
end
