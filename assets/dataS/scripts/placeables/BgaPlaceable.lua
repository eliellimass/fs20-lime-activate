BgaPlaceable = {}
local BgaPlaceable_mt = Class(BgaPlaceable, Placeable)

InitStaticObjectClass(BgaPlaceable, "BgaPlaceable", ObjectIds.OBJECT_BGA_PLACEABLE)

function BgaPlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or BgaPlaceable_mt)

	registerObjectClassName(self, "BgaPlaceable")

	return self
end

function BgaPlaceable:delete()
	self.bga:delete()

	for _, bunkerSilo in ipairs(self.bunkerSilos) do
		bunkerSilo:delete()
	end

	unregisterObjectClassName(self)
	BgaPlaceable:superClass().delete(self)
end

function BgaPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not BgaPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.boughtWithFarmland = true
	self.bga = Bga:new(self.isServer, self.isClient)

	if not self.bga:load(self.nodeId, xmlFile, "placeable.bga", self.customEnvironment) then
		self.bga:delete()
		delete(xmlFile)

		return false
	end

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

function BgaPlaceable:finalizePlacement()
	BgaPlaceable:superClass().finalizePlacement(self)
	self.bga:register(true)

	for _, bunkerSilo in ipairs(self.bunkerSilos) do
		bunkerSilo:register(true)
	end
end

function BgaPlaceable:readStream(streamId, connection)
	BgaPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local bgaId = NetworkUtil.readNodeObjectId(streamId)

		self.bga:readStream(streamId, connection)
		g_client:finishRegisterObject(self.bga, bgaId)

		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			local bunkerSiloId = NetworkUtil.readNodeObjectId(streamId)

			bunkerSilo:readStream(streamId, connection)
			g_client:finishRegisterObject(bunkerSilo, bunkerSiloId)
		end
	end
end

function BgaPlaceable:writeStream(streamId, connection)
	BgaPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.bga))
		self.bga:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.bga)

		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(bunkerSilo))
			bunkerSilo:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, bunkerSilo)
		end
	end
end

function BgaPlaceable:setOwnerFarmId(farmId, noEventSend)
	BgaPlaceable:superClass().setOwnerFarmId(self, farmId, noEventSend)

	if self.bga ~= nil then
		self.bga:setOwnerFarmId(farmId, true)
	end

	if self.bunkerSilos ~= nil then
		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			bunkerSilo:setOwnerFarmId(farmId, true)
		end
	end
end

function BgaPlaceable:collectPickObjects(node)
	local foundNode = false

	for _, unloadTrigger in ipairs(self.bga.bunker.unloadingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		for _, loadTrigger in ipairs(self.bga.digestateSilo.loadingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				foundNode = true

				break
			end
		end
	end

	if not foundNode then
		BgaPlaceable:superClass().collectPickObjects(self, node)
	end
end

function BgaPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not BgaPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	self.bga:loadFromXMLFile(xmlFile, key .. ".bga", resetVehicles)

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

function BgaPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	BgaPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	self.bga:saveToXMLFile(xmlFile, key .. ".bga", usedModNames)

	for k, bunkerSilo in ipairs(self.bunkerSilos) do
		local bunkerKey = string.format("%s.bunkerSilo(%d)", key, k - 1)

		setXMLInt(xmlFile, bunkerKey .. "#index", k)
		bunkerSilo:saveToXMLFile(xmlFile, bunkerKey, usedModNames)
	end
end

function BgaPlaceable:updateOwnership(updateOwner)
	local farmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)

	if self:getOwnerFarmId() ~= AccessHandler.EVERYONE and farmId == AccessHandler.EVERYONE then
		for _, bunkerSilo in ipairs(self.bunkerSilos) do
			bunkerSilo:clearSiloArea()
		end
	end

	BgaPlaceable:superClass().updateOwnership(self, updateOwner)
end
