Workshop = {}
local Workshop_mt = Class(Workshop, Placeable)

InitStaticObjectClass(Workshop, "Workshop", ObjectIds.OBJECT_WORKSHOP_PLACEABLE)

function Workshop:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or Workshop_mt)

	registerObjectClassName(self, "Workshop")

	return self
end

function Workshop:delete()
	unregisterObjectClassName(self)
	g_currentMission:removeUpdateable(self.sellingPoint)
	self.sellingPoint:delete()
	Workshop:superClass().delete(self)
end

function Workshop:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not Workshop:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.sellingPoint = VehicleSellingPoint:new(self.nodeId)

	self.sellingPoint:load(xmlFile, "placeable.sellingPoint")
	self.sellingPoint:setOwnerFarmId(self:getOwnerFarmId())

	self.sellingPoint.owningPlaceable = self

	g_currentMission:addUpdateable(self.sellingPoint)
	delete(xmlFile)

	return true
end

function Workshop:setOwnerFarmId(ownerFarmId, noEventSend)
	Workshop:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)

	if self.sellingPoint ~= nil then
		self.sellingPoint:setOwnerFarmId(ownerFarmId)
	end
end
