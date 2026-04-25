VehiclePlaceable = {}
local WaterTower_mt = Class(VehiclePlaceable, Placeable)

InitStaticObjectClass(VehiclePlaceable, "VehiclePlaceable", ObjectIds.OBJECT_VEHICLE_PLACEABLE)

function VehiclePlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or WaterTower_mt)

	registerObjectClassName(self, "VehiclePlaceable")

	self.savegameData = nil

	return self
end

function VehiclePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not VehiclePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local xmlFilename = getXMLString(xmlFile, "placeable.vehicle#xmlFilename")

	delete(xmlFile)

	if xmlFilename == nil then
		return false
	end

	if self.isServer then
		xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
		local x, y, z = getWorldTranslation(self.nodeId)
		local _, yRot, _ = getWorldRotation(self.nodeId)
		self.vehicle = g_currentMission:loadVehicle(xmlFilename, x, y, z, 0, yRot, true, 0, Vehicle.PROPERTY_STATE_NONE, self:getOwnerFarmId(), nil, self.savegameData)

		if self.vehicle == nil then
			g_logManager:xmlWarning(self.configFileName, "Could not create placeable vehicle!")

			return false
		end

		self.vehicle.isVehicleSaved = false

		self.vehicle:addDeleteListener(self)
	end

	return true
end

function VehiclePlaceable:delete()
	if self.vehicle ~= nil then
		g_currentMission:removeVehicle(self.vehicle, false)
		self.vehicle:delete()
	end

	unregisterObjectClassName(self)
	VehiclePlaceable:superClass().delete(self)
end

function VehiclePlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if hasXMLProperty(xmlFile, key .. ".vehicle") then
		self.savegameData = {
			xmlFile = xmlFile,
			key = key .. ".vehicle",
			resetVehicles = resetVehicles
		}
	end

	if not VehiclePlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	return true
end

function VehiclePlaceable:onDeleteObject(object)
	if self.vehicle == object then
		self.vehicle = nil

		self:delete()
	end
end
