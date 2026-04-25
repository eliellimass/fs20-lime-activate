RailroadCaller = {}
local RailroadCaller_mt = Class(RailroadCaller)

function RailroadCaller:new(isServer, isClient, trainSystem, nodeId, customMt)
	local self = {}

	setmetatable(self, customMt or RailroadCaller_mt)

	self.trainSystem = trainSystem
	self.nodeId = nodeId
	self.isServer = isServer
	self.isClient = isClient

	return self
end

function RailroadCaller:loadFromXML(xmlFile, key)
	self.triggerNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, key .. "#triggerNode"))
	self.rootNode = self.triggerNode

	if self.triggerNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing trigger 'triggerNode' for railroadCaller '%s'!", key)
		delete(xmlFile)

		return false
	end

	addTrigger(self.triggerNode, "railroadCallerTriggerCallback", self)

	self.activateText = g_i18n:getText("action_activateShop")
	self.objectActivated = false

	return true
end

function RailroadCaller:delete()
	if self.triggerNode ~= nil then
		g_currentMission:removeActivatableObject(self)
		removeTrigger(self.triggerNode)

		self.triggerNode = nil
	end
end

function RailroadCaller:setSplineTimeByPosition(t, splineLength)
	self.splinePositionTime = SplineUtil.getValidSplineTime(t)
end

function RailroadCaller:railroadCallerTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.trainSystem ~= nil and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
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

function RailroadCaller:getIsActivatable()
	return g_currentMission.controlPlayer
end

function RailroadCaller:drawActivate()
end

function RailroadCaller:onActivateObject()
	g_currentMission:addActivatableObject(self)

	self.objectActivated = true

	self:callRailroad()
end

function RailroadCaller:callRailroad()
	if self.trainSystem ~= nil then
		self.trainSystem:setRequestedSplinePosition(self.splinePositionTime)
	end
end
