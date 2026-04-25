TrafficSystem = {}
local TrafficSystem_mt = Class(TrafficSystem, Object)

InitStaticObjectClass(TrafficSystem, "TrafficSystem", ObjectIds.TRAFFIC_SYSTEM)

function TrafficSystem:onCreate(transformId)
	local xmlFile = getUserAttribute(transformId, "xmlFile")

	if xmlFile ~= nil then
		xmlFile = Utils.getFilename(xmlFile, g_currentMission.loadingMapBaseDirectory)
		local lightsProfile = g_gameSettings:getValue("lightsProfile")
		local useHighProfile = lightsProfile == GS_PROFILE_HIGH or lightsProfile == GS_PROFILE_VERY_HIGH
		local trafficSystem = TrafficSystem:new(g_server ~= nil, g_client ~= nil)

		if trafficSystem:load(xmlFile, transformId, useHighProfile, g_server ~= nil, g_client ~= nil) then
			trafficSystem:register(true)
			g_currentMission:addOnCreateLoadedObject(trafficSystem)
			trafficSystem:setEnabled(g_currentMission.missionInfo.trafficEnabled)
		else
			trafficSystem:delete()
		end

		g_currentMission.trafficSystem = trafficSystem
	else
		print("Error: Missing xmlFile attribute for traffic system in " .. getName(transformId))
	end
end

function TrafficSystem:new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = TrafficSystem_mt
	end

	local self = Object:new(isServer, isClient, customMt)
	self.trafficSystemId = 0
	self.isEnabled = false
	self.trafficSystemDirtyFlag = self:getNextDirtyFlag()

	return self
end

function TrafficSystem:load(xmlFile, transformId, useHighProfile, isServer, isClient)
	self.trafficSystemId = createTrafficSystem(xmlFile, transformId, useHighProfile, isServer, isClient)
	self.isEnabled = true

	g_soundManager:addIndoorStateChangedListener(self)
	setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not g_soundManager:getIsIndoor())
	setTrafficSystemNightTimeRange(self.trafficSystemId, g_currentMission.environment.nightStart, g_currentMission.environment.nightEnd)

	return true
end

function TrafficSystem:delete()
	if self.trafficSystemId ~= 0 then
		delete(self.trafficSystemId)

		g_currentMission.trafficSystem = nil
	end

	g_soundManager:removeIndoorStateChangedListener(self)
end

function TrafficSystem:writeUpdateStream(streamId, connection, dirtyMask)
	TrafficSystem:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		writeTrafficSystemToStream(self.trafficSystemId, streamId)
	end
end

function TrafficSystem:readUpdateStream(streamId, timestamp, connection)
	TrafficSystem:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		readTrafficSystemFromStream(self.trafficSystemId, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
	end
end

function TrafficSystem:update(dt)
	setTrafficSystemDaytime(self.trafficSystemId, g_currentMission.environment.dayTime)

	if self.isEnabled then
		self:raiseActive()
	end
end

function TrafficSystem:updateTick(dt)
	self:raiseDirtyFlags(self.trafficSystemDirtyFlag)
end

function TrafficSystem:setNightTimeRange(nightStart, nightEnd)
	setTrafficSystemNightTimeRange(self.trafficSystemId, nightStart, nightEnd)
end

function TrafficSystem:setEnabled(state)
	setTrafficSystemEnabled(self.trafficSystemId, state)

	self.isEnabled = state

	if state then
		self:raiseActive()
	end
end

function TrafficSystem:reset()
	resetTrafficSystem(self.trafficSystemId)
end

function TrafficSystem:onIndoorStateChanged(isIndoor)
	setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not isIndoor)
end
