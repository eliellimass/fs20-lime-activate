PedestrianSystem = {}
local PedestrianSystem_mt = Class(PedestrianSystem)

function PedestrianSystem:onCreate(transformId)
	local xmlFile = getUserAttribute(transformId, "xmlFile")

	if xmlFile ~= nil then
		xmlFile = Utils.getFilename(xmlFile, g_currentMission.loadingMapBaseDirectory)
		local pedestrianSystem = PedestrianSystem:new()
		local animNode = g_animCache:getNode(AnimationCache.PEDESTRIAN)

		if animNode ~= nil then
			if not pedestrianSystem:load(xmlFile, transformId, animNode) then
				pedestrianSystem:delete()
			end
		else
			print("Error: Unable to find Pedestrian Animation.")
		end

		g_currentMission:addUpdateable(pedestrianSystem)

		g_currentMission.pedestrianSystem = pedestrianSystem
	else
		print("Error: Missing xmlFile attribute for pedestrian system in " .. getName(transformId))
	end
end

function PedestrianSystem:new()
	local self = setmetatable({}, PedestrianSystem_mt)
	self.pedestrianSystemId = 0

	return self
end

function PedestrianSystem:load(xmlFile, transformId, referenceNodeId)
	self.pedestrianSystemId = createPedestrianSystem(xmlFile, transformId, referenceNodeId)

	setPedestrianSystemNightTimeRange(self.pedestrianSystemId, g_currentMission.environment.nightStart, g_currentMission.environment.nightEnd)

	return true
end

function PedestrianSystem:delete()
	if self.pedestrianSystemId ~= 0 then
		delete(self.pedestrianSystemId)

		g_currentMission.pedestrianSystem = nil
	end
end

function PedestrianSystem:update(dt)
	setPedestrianSystemDaytime(self.pedestrianSystemId, g_currentMission.environment.dayTime)
end

function PedestrianSystem:setEnabled(state)
	setPedestrianSystemEnabled(self.pedestrianSystemId, state)
end

function PedestrianSystem:setNightTimeRange(nightStart, nightEnd)
	setPedestrianSystemNightTimeRange(self.pedestrianSystemId, nightStart, nightEnd)
end
