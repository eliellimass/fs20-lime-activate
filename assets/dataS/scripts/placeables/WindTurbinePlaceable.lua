WindTurbinePlaceable = {}
local WindTurbinePlaceable_mt = Class(WindTurbinePlaceable, Placeable)

InitStaticObjectClass(WindTurbinePlaceable, "WindTurbinePlaceable", ObjectIds.OBJECT_WIND_TURBINE_PLACEABLE)

function WindTurbinePlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or WindTurbinePlaceable_mt)

	registerObjectClassName(self, "WindTurbinePlaceable")

	self.rotationNode = 0
	self.headNode = 0
	self.incomePerHour = 0

	return self
end

function WindTurbinePlaceable:delete()
	unregisterObjectClassName(self)
	g_currentMission.environment:removeHourChangeListener(self)
	WindTurbinePlaceable:superClass().delete(self)
end

function WindTurbinePlaceable:readStream(streamId, connection)
	if connection:getIsServer() then
		self.headRotation = NetworkUtil.readCompressedAngle(streamId)
	end

	WindTurbinePlaceable:superClass().readStream(self, streamId, connection)
end

function WindTurbinePlaceable:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeCompressedAngle(streamId, self.headRotation)
	end

	WindTurbinePlaceable:superClass().writeStream(self, streamId, connection)
end

function WindTurbinePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not WindTurbinePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.headNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.windTurbine#headNode"))
	self.rotationNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.windTurbine#rotationNode"))

	self:initPose(x, y, z, rx, ry, rz, initRandom)
	delete(xmlFile)

	return true
end

function WindTurbinePlaceable:finalizePlacement()
	WindTurbinePlaceable:superClass().finalizePlacement(self)
	g_currentMission.environment:addHourChangeListener(self)
end

function WindTurbinePlaceable:initPose(x, y, z, rx, ry, rz, initRandom)
	WindTurbinePlaceable:superClass().initPose(self, x, y, z, rx, ry, rz, initRandom)

	if self.headNode ~= nil and self.headNode ~= 0 then
		if initRandom == nil or initRandom == true then
			local rotVariation = 0.2
			self.headRotation = 0.7 + math.random() * 2 * rotVariation - rotVariation
		end

		rotate(self.rotationNode, 0, 0, math.random() * math.pi * 2)
		self:updateHeadRotation()
	end
end

function WindTurbinePlaceable:updateHeadRotation()
	local dx, _, dz = worldDirectionToLocal(self.nodeId, math.sin(self.headRotation), 0, math.cos(self.headRotation))

	setDirection(self.headNode, dx, 0, dz, 0, 1, 0)
end

function WindTurbinePlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	local headRotation = getXMLFloat(xmlFile, key .. "#headRotation")

	if headRotation == nil then
		return false
	end

	self.headRotation = headRotation

	if not WindTurbinePlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	return true
end

function WindTurbinePlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	WindTurbinePlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. "#headRotation", self.headRotation)
end

function WindTurbinePlaceable:update(dt)
	if self.rotationNode ~= 0 then
		rotate(self.rotationNode, 0, 0, -0.0025 * dt)
		self:raiseActive()
	end
end

function WindTurbinePlaceable:hourChanged()
	if self.isServer then
		g_currentMission:addMoney(self.incomePerHour, self:getOwnerFarmId(), MoneyType.PROPERTY_INCOME, true)
	end
end
