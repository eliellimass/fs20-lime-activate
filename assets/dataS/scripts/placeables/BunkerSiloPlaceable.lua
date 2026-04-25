BunkerSiloPlaceable = {}
local BgaPlaceable_mt = Class(BunkerSiloPlaceable, Placeable)

InitStaticObjectClass(BunkerSiloPlaceable, "BunkerSiloPlaceable", ObjectIds.OBJECT_BUNKERSILO_PLACEABLE)

function BunkerSiloPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or BgaPlaceable_mt)

	registerObjectClassName(self, "BunkerSiloPlaceable")

	return self
end

function BunkerSiloPlaceable:delete()
	for _, bunkerSilo in ipairs(self.bunkerSilos) do
		bunkerSilo:delete()
	end

	unregisterObjectClassName(self)
	BunkerSiloPlaceable:superClass().delete(self)
end

function BunkerSiloPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not BunkerSiloPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.bunkerSilos = {}
	local i = 0

	while true do
		local bunkerKey = string.format("placeable.bunkerSilos.bunkerSilo(%d)", i)

		if not hasXMLProperty(xmlFile, bunkerKey) then
			break
		end

		local bunkerSilo = BunkerSilo:new(self.isServer, self.isClient)

		if bunkerSilo:load(self.nodeId, xmlFile, bunkerKey) then
			table.insert(self.bunkerSilos, bunkerSilo)
		else
			bunkerSilo:delete()
		end

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function BunkerSiloPlaceable:finalizePlacement()
	BunkerSiloPlaceable:superClass().finalizePlacement(self)

	for _, bunkerSilo in ipairs(self.bunkerSilos) do
		bunkerSilo:register(true)
	end
end

function BunkerSiloPlaceable:onSell()
	BunkerSiloPlaceable:superClass().onSell(self)

	for _, bunkerSilo in ipairs(self.bunkerSilos) do
		bunkerSilo:clearSiloArea()
	end
end

function BunkerSiloPlaceable:readStream(streamId, connection)
	BunkerSiloPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			local bunkerSiloId = NetworkUtil.readNodeObjectId(streamId)

			bunkerSilo:readStream(streamId, connection)
			g_client:finishRegisterObject(bunkerSilo, bunkerSiloId)
		end
	end
end

function BunkerSiloPlaceable:writeStream(streamId, connection)
	BunkerSiloPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(bunkerSilo))
			bunkerSilo:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, bunkerSilo)
		end
	end
end

function BunkerSiloPlaceable:collectPickObjects(node)
	if not foundNode then
		BunkerSiloPlaceable:superClass().collectPickObjects(self, node)
	end
end

function BunkerSiloPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not BunkerSiloPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	local i = 0

	while true do
		local bunkerKey = string.format("%s.bunkerSilo(%d)", key, i)

		if not hasXMLProperty(xmlFile, bunkerKey) then
			break
		end

		local index = getXMLInt(xmlFile, bunkerKey .. "#index")

		if index ~= nil then
			if self.bunkerSilos[index] ~= nil then
				if not self.bunkerSilos[index]:loadFromXMLFile(xmlFile, bunkerKey) then
					return false
				end
			else
				g_logManager:warning("Could not load bunkersilo. Given 'index' '%d' is not defined!", index)
			end
		end

		i = i + 1
	end

	return true
end

function BunkerSiloPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	BunkerSiloPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	for k, bunkerSilo in ipairs(self.bunkerSilos) do
		local bunkerKey = string.format("%s.bunkerSilo(%d)", key, k - 1)

		setXMLInt(xmlFile, bunkerKey .. "#index", k)
		bunkerSilo:saveToXMLFile(xmlFile, bunkerKey, usedModNames)
	end
end
