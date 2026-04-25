FarmhousePlaceable = {}
local FarmhousePlaceable_mt = Class(FarmhousePlaceable, Placeable)

InitStaticObjectClass(FarmhousePlaceable, "FarmhousePlaceable", ObjectIds.OBJECT_FARMHOUSE_PLACEABLE)

function FarmhousePlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or FarmhousePlaceable_mt)

	registerObjectClassName(self, "FarmhousePlaceable")

	return self
end

function FarmhousePlaceable:delete()
	unregisterObjectClassName(self)

	if self.sleepingTrigger ~= nil then
		removeTrigger(self.sleepingTrigger)
	end

	g_currentMission:removeActivatableObject(self)

	self.objectActivated = false

	FarmhousePlaceable:superClass().delete(self)
end

function FarmhousePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not FarmhousePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.spawnNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.farmhouse#spawnNode"))
	self.sleepingTrigger = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.farmhouse.sleeping#triggerNode"))

	if self.sleepingTrigger ~= nil then
		addTrigger(self.sleepingTrigger, "sleepingTriggerCallback", self)
	end

	self.sleepingCamera = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.farmhouse.sleeping#cameraNode"))
	self.activateText = g_i18n:getText("ui_inGameSleep")
	self.isEnabled = true
	self.objectActivated = false

	delete(xmlFile)

	return true
end

function FarmhousePlaceable:getCanBePlacedAt(x, y, z, distance, farmId)
	local canBePlaced = FarmhousePlaceable:superClass().getCanBePlacedAt(self, x, y, z, distance, farmId)

	return canBePlaced and self:canPlaceHouse()
end

function FarmhousePlaceable:canBuy()
	local canBePlaced = FarmhousePlaceable:superClass().canBuy(self)

	return canBePlaced and self:canPlaceHouse(), g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
end

function FarmhousePlaceable:canPlaceHouse()
	return g_farmManager:getFarmById(g_currentMission.player.farmId):getFarmhouse() == nil
end

function FarmhousePlaceable:getSpawnPoint()
	return self.spawnNode
end

function FarmhousePlaceable:getSpawnWorldPosition()
	return getWorldTranslation(self.spawnNode)
end

function FarmhousePlaceable:getSleepCamera()
	return self.sleepingCamera
end

function FarmhousePlaceable:sleepingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.player:onEnterFarmhouse()
		end

		if self:getOwnerFarmId() == g_currentMission.player.farmId then
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
end

function FarmhousePlaceable:getIsActivatable()
	return g_currentMission:getFarmId() == self:getOwnerFarmId()
end

function FarmhousePlaceable:drawActivate()
end

function FarmhousePlaceable:onActivateObject()
	g_sleepManager:showDialog()
end
