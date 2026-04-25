SolarCollectorPlaceable = {}
local SolarCollectorPlaceable_mt = Class(SolarCollectorPlaceable, Placeable)

InitStaticObjectClass(SolarCollectorPlaceable, "SolarCollectorPlaceable", ObjectIds.OBJECT_SOLAR_COLLECTOR_PLACEABLE)

function SolarCollectorPlaceable:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = SolarCollectorPlaceable_mt
	end

	local self = Placeable:new(isServer, isClient, mt)

	registerObjectClassName(self, "SolarCollectorPlaceable")

	self.headNode = 0
	self.incomePerHour = 0
	self.headRotationRandom = 0

	return self
end

function SolarCollectorPlaceable:delete()
	unregisterObjectClassName(self)
	g_currentMission.environment:removeHourChangeListener(self)
	SolarCollectorPlaceable:superClass().delete(self)
end

function SolarCollectorPlaceable:readStream(streamId, connection)
	if connection:getIsServer() then
		self.headRotationRandom = NetworkUtil.readCompressedAngle(streamId)
	end

	SolarCollectorPlaceable:superClass().readStream(self, streamId, connection)
end

function SolarCollectorPlaceable:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeCompressedAngle(streamId, self.headRotationRandom)
	end

	SolarCollectorPlaceable:superClass().writeStream(self, streamId, connection)
end

function SolarCollectorPlaceable:createNode(i3dFilename)
	if not SolarCollectorPlaceable:superClass().createNode(self, i3dFilename) then
		return false
	end

	if getNumOfChildren(self.nodeId) < 1 then
		delete(self.nodeId)

		self.nodeId = 0

		return false
	end

	self.headNode = getChildAt(self.nodeId, 0)

	return true
end

function SolarCollectorPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not SolarCollectorPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	return true
end

function SolarCollectorPlaceable:finalizePlacement()
	SolarCollectorPlaceable:superClass().finalizePlacement(self)
	g_currentMission.environment:addHourChangeListener(self)
end

function SolarCollectorPlaceable:initPose(x, y, z, rx, ry, rz, initRandom)
	SolarCollectorPlaceable:superClass().initPose(self, x, y, z, rx, ry, rz, initRandom)

	local rotVariation = 0.1
	self.headRotationRandom = math.rad(-15) + math.random() * 2 * rotVariation - rotVariation

	self:updateHeadRotation()
end

function SolarCollectorPlaceable:updateHeadRotation()
	local headRotation = math.rad(-15)

	if g_currentMission.environment.sunLightId ~= nil then
		local dx, _, dz = localDirectionToWorld(g_currentMission.environment.sunLightId, 0, 0, 1)
		headRotation = math.atan2(dx, dz)
	end

	headRotation = headRotation + self.headRotationRandom
	local dx, _, dz = worldDirectionToLocal(self.nodeId, math.sin(headRotation), 0, math.cos(headRotation))

	setDirection(self.headNode, dx, 0, dz, 0, 1, 0)
end

function SolarCollectorPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	local headRotationRandom = getXMLFloat(xmlFile, key .. "#headRotationRandom")

	if headRotationRandom == nil then
		return false
	end

	self.headRotationRandom = headRotationRandom

	if not SolarCollectorPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	return true
end

function SolarCollectorPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	SolarCollectorPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#headRotationRandom", self.headRotationRandom)
end

function SolarCollectorPlaceable:update(dt)
end

function SolarCollectorPlaceable:hourChanged()
	if self.isServer then
		g_currentMission:addMoney(self.incomePerHour, self:getOwnerFarmId(), MoneyType.PROPERTY_INCOME, true)
	end

	self:updateHeadRotation()
end
