BuyingStationPlaceable = {}
local SiloPlaceable_mt = Class(BuyingStationPlaceable, Placeable)

InitStaticObjectClass(BuyingStationPlaceable, "BuyingStationPlaceable", ObjectIds.OBJECT_BUYING_STATION_PLACEABLE)

function BuyingStationPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or SiloPlaceable_mt)

	registerObjectClassName(self, "BuyingStationPlaceable")

	return self
end

function BuyingStationPlaceable:delete()
	if self.buyingStation ~= nil then
		self.buyingStation:delete()
	end

	unregisterObjectClassName(self)
	BuyingStationPlaceable:superClass().delete(self)
end

function BuyingStationPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not BuyingStationPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.buyingStation = BuyingStation:new(self.isServer, self.isClient)

	self.buyingStation:load(self.nodeId, xmlFile, "placeable.buyingStation", self.customEnvironment)

	self.buyingStation.owningPlaceable = self

	delete(xmlFile)

	return true
end

function BuyingStationPlaceable:finalizePlacement()
	BuyingStationPlaceable:superClass().finalizePlacement(self)
	self.buyingStation:register(true)
end

function BuyingStationPlaceable:readStream(streamId, connection)
	BuyingStationPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local buyingStationId = NetworkUtil.readNodeObjectId(streamId)

		self.buyingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(self.buyingStation, buyingStationId)
	end
end

function BuyingStationPlaceable:writeStream(streamId, connection)
	BuyingStationPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.buyingStation))
		self.buyingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.buyingStation)
	end
end

function BuyingStationPlaceable:collectPickObjects(node)
	local foundNode = false

	if not foundNode then
		for _, loadTrigger in ipairs(self.buyingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				foundNode = true

				break
			end
		end
	end

	if not foundNode then
		BuyingStationPlaceable:superClass().collectPickObjects(self, node)
	end
end
