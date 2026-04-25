SellingStationPlaceable = {}
local SellStationPlaceable_mt = Class(SellingStationPlaceable, Placeable)

InitStaticObjectClass(SellingStationPlaceable, "SellingStationPlaceable", ObjectIds.OBJECT_SELLING_STATION_PLACEABLE)

function SellingStationPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or SellStationPlaceable_mt)

	registerObjectClassName(self, "SellingStationPlaceable")

	return self
end

function SellingStationPlaceable:delete()
	if self.sellingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.sellingStation)
		self.sellingStation:delete()
	end

	unregisterObjectClassName(self)
	SellingStationPlaceable:superClass().delete(self)
end

function SellingStationPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not SellingStationPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.sellingStation = SellingStation:new(self.isServer, self.isClient)

	self.sellingStation:load(self.nodeId, xmlFile, "placeable.sellingStation", self.customEnvironment)

	self.sellingStation.owningPlaceable = self

	delete(xmlFile)

	return true
end

function SellingStationPlaceable:finalizePlacement()
	SellingStationPlaceable:superClass().finalizePlacement(self)
	self.sellingStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(self.sellingStation)
end

function SellingStationPlaceable:readStream(streamId, connection)
	SellingStationPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local sellingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.sellingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.sellingStation, sellingStationId)
	end
end

function SellingStationPlaceable:writeStream(streamId, connection)
	SellingStationPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.sellingStation))
		self.sellingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.sellingStation)
	end
end

function SellingStationPlaceable:collectPickObjects(node)
	local foundNode = false

	for _, unloadTrigger in ipairs(self.sellingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		SellingStationPlaceable:superClass().collectPickObjects(self, node)
	end
end

function SellingStationPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not SellingStationPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	if not self.sellingStation:loadFromXMLFile(xmlFile, key .. ".sellingStation") then
		return false
	end

	return true
end

function SellingStationPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	SellingStationPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.sellingStation:saveToXMLFile(xmlFile, key .. ".sellingStation", usedModNames)
end
