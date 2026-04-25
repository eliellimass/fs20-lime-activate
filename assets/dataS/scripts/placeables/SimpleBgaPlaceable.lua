SimpleBgaPlaceable = {}
local SellStationPlaceable_mt = Class(SimpleBgaPlaceable, Placeable)

InitStaticObjectClass(SimpleBgaPlaceable, "SimpleBgaPlaceable", ObjectIds.OBJECT_SIMPLE_BGA_PLACEABLE)

function SimpleBgaPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or SellStationPlaceable_mt)

	registerObjectClassName(self, "SimpleBgaPlaceable")

	return self
end

function SimpleBgaPlaceable:delete()
	if self.sellingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(self.sellingStation)
		self.sellingStation:delete()
	end

	unregisterObjectClassName(self)
	SimpleBgaPlaceable:superClass().delete(self)
end

function SimpleBgaPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not SimpleBgaPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.sellingStation = SimpleBgaSellingStation:new(self.isServer, self.isClient)

	self.sellingStation:load(self.nodeId, xmlFile, "placeable.simpleBgaSellingStation", self.customEnvironment)

	self.sellingStation.owningPlaceable = self

	delete(xmlFile)

	return true
end

function SimpleBgaPlaceable:finalizePlacement()
	SimpleBgaPlaceable:superClass().finalizePlacement(self)
	self.sellingStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(self.sellingStation)
end

function SimpleBgaPlaceable:readStream(streamId, connection)
	SimpleBgaPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local sellingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.sellingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.sellingStation, sellingStationId)
	end
end

function SimpleBgaPlaceable:writeStream(streamId, connection)
	SimpleBgaPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.sellingStation))
		self.sellingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.sellingStation)
	end
end

function SimpleBgaPlaceable:collectPickObjects(node)
	local foundNode = false

	for _, unloadTrigger in ipairs(self.sellingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	for _, loadTrigger in ipairs(self.sellingStation.loadingStation.loadTriggers) do
		if node == loadTrigger.triggerNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		SimpleBgaPlaceable:superClass().collectPickObjects(self, node)
	end
end

function SimpleBgaPlaceable:setOwnerFarmId(ownerFarmId, noEventSend)
	SimpleBgaPlaceable:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)
	self.sellingStation:setOwnerFarmId(ownerFarmId, noEventSend)
end

function SimpleBgaPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not SimpleBgaPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	if not self.sellingStation:loadFromXMLFile(xmlFile, key .. ".simpleBgaSellingStation") then
		return false
	end

	return true
end

function SimpleBgaPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	SimpleBgaPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.sellingStation:saveToXMLFile(xmlFile, key .. ".simpleBgaSellingStation", usedModNames)
end
