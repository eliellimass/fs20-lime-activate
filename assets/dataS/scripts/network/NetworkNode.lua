NetworkNode = {}
local NetworkNode_mt = Class(NetworkNode)
NetworkNode.LOCAL_STREAM_ID = 0
NetworkNode.PACKET_EVENT = 1
NetworkNode.PACKET_VEHICLE = 2
NetworkNode.PACKET_PLAYER = 3
NetworkNode.PACKET_SPLITSHAPES = 4
NetworkNode.PACKET_DENSITY_MAPS = 5
NetworkNode.PACKET_TERRAIN_DEFORM = 6
NetworkNode.PACKET_OTHERS = 7
NetworkNode.NUM_PACKETS = 7
NetworkNode.CHANNEL_MAIN = 1
NetworkNode.CHANNEL_SECONDARY = 2
NetworkNode.CHANNEL_GROUND = 3
NetworkNode.CHANNEL_CHAT = 4
NetworkNode.OBJECT_SEND_NUM_BITS = 24

function NetworkNode:new(customMt)
	local self = setmetatable({}, customMt or NetworkNode_mt)
	self.objects = {}
	self.objectIds = {}
	self.activeObjects = {}
	self.activeObjectsNextFrame = {}
	self.removedObjects = {}
	self.dirtyObjects = {}
	self.lastUploadedKBs = 0
	self.lastUploadedKBsSmooth = 0
	self.maxUploadedKBs = 0
	self.graphColors = {
		[NetworkNode.PACKET_EVENT] = {
			1,
			0,
			0,
			1
		},
		[NetworkNode.PACKET_VEHICLE] = {
			0,
			1,
			0,
			1
		},
		[NetworkNode.PACKET_PLAYER] = {
			0,
			0,
			1,
			1
		},
		[NetworkNode.PACKET_SPLITSHAPES] = {
			1,
			1,
			0,
			1
		},
		[NetworkNode.PACKET_DENSITY_MAPS] = {
			0.5,
			0.5,
			0,
			1
		},
		[NetworkNode.PACKET_TERRAIN_DEFORM] = {
			0.5,
			0.5,
			0.5,
			1
		},
		[NetworkNode.PACKET_OTHERS] = {
			0,
			1,
			1,
			1
		}
	}
	self.packetGraphs = {}
	self.packetBytes = {}

	for i = 1, NetworkNode.NUM_PACKETS do
		local showGraphLabels = i == 1
		self.packetGraphs[i] = Graph:new(80, 0.2, 0.2, 0.6, 0.6, 0, 1000, showGraphLabels, "bytes")

		self.packetGraphs[i]:setColor(self.graphColors[i][1], self.graphColors[i][2], self.graphColors[i][3], self.graphColors[i][4])

		self.packetBytes[i] = 0
	end

	self.showNetworkTraffic = false
	self.showActiveObjects = false

	return self
end

function NetworkNode:delete()
	for _, object in pairs(self.objects) do
		self:unregisterObject(object, true)
		object:delete()
	end

	for i = 1, NetworkNode.NUM_PACKETS do
		self.packetGraphs[i]:delete()
	end
end

function NetworkNode:setNetworkListener(listener)
	self.networkListener = listener
end

function NetworkNode:keyEvent(unicode, sym, modifier, isDown)
end

function NetworkNode:mouseEvent(posX, posY, isDown, isUp, button)
end

function NetworkNode:update(dt)
end

function NetworkNode:updateActiveObjects(dt)
	for id, object in pairs(self.removedObjects) do
		self.activeObjects[id] = nil
		self.activeObjectsNextFrame[id] = nil
		self.removedObjects[id] = nil
	end

	for _, object in pairs(self.activeObjects) do
		object:update(dt)
	end
end

function NetworkNode:updateActiveObjectsTick(dt)
	for i = #self.dirtyObjects, 1, -1 do
		self.dirtyObjects[i] = nil
	end

	for serverId, object in pairs(self.activeObjects) do
		object:updateTick(dt)

		if object.dirtyMask ~= 0 then
			object.lastServerId = serverId

			table.insert(self.dirtyObjects, object)
		end

		local id = self:getObjectId(object)
		self.activeObjects[id] = nil

		if self.activeObjectsNextFrame[id] == nil then
			object:updateEnd(dt)
		end
	end

	local oldObject = self.activeObjects
	self.activeObjects = self.activeObjectsNextFrame
	self.activeObjectsNextFrame = oldObject

	return self.dirtyObjects
end

function NetworkNode:drawConnectionNetworkStats(connection, offsetY)
	if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
		return false
	end

	local ping, download, upload, packetLoss = netGetConnectionStats(connection.streamId)

	if ping == nil then
		packetLoss = 0
		upload = 0
		download = 0
		ping = 0
	end

	if connection.pingSmooth == nil then
		connection.packetLossSmooth = packetLoss
		connection.uploadSmooth = upload
		connection.downloadSmooth = download
		connection.pingSmooth = ping
	end

	connection.pingSmooth = connection.pingSmooth + (ping - connection.pingSmooth) * 0.2
	connection.downloadSmooth = connection.downloadSmooth + (download - connection.downloadSmooth) * 0.2
	connection.uploadSmooth = connection.uploadSmooth + (upload - connection.uploadSmooth) * 0.2
	connection.packetLossSmooth = connection.packetLossSmooth + (packetLoss - connection.packetLossSmooth) * 0.2
	packetLoss = connection.packetLossSmooth
	upload = connection.uploadSmooth
	download = connection.downloadSmooth
	ping = connection.pingSmooth

	renderText(0.5, 0.77 - offsetY * 0.03, 0.025, string.format("%dms w:%2d d:%4.2fkb/s u:%4.2fkb/s l:%4.2f%% comp: %.2f%%", ping, connection.lastSeqSent - connection.highestAckedSeq, download / 1024, upload / 1024, packetLoss * 100, 1 / connection.compressionRatio * 100))

	return true
end

function NetworkNode:getObjectPacketType(object)
	if object == nil then
		return NetworkNode.PACKET_OTHERS
	elseif object:isa(Vehicle) then
		return NetworkNode.PACKET_VEHICLE
	elseif object:isa(Player) then
		return NetworkNode.PACKET_PLAYER
	else
		return NetworkNode.PACKET_OTHERS
	end
end

function NetworkNode:getPacketTypeName(packetType)
	for key, value in pairs(Network) do
		if value == packetType then
			return key
		end
	end

	return "TYPE_UNKNOWN"
end

function NetworkNode:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, name, object)
	local endOffset = streamGetReadOffset(streamId)
	local readNumBits = endOffset - (startOffset + 32)

	if readNumBits ~= numBits then
		local objectInfo = ""

		if object ~= nil then
			objectInfo = ": " .. object.className

			if object.configFileName ~= nil then
				objectInfo = objectInfo .. " (" .. object.configFileName .. ")"
			end
		end

		print("Error: Not all bits read in object " .. name .. " (" .. readNumBits .. " vs " .. numBits .. ")" .. objectInfo)
	end
end

function NetworkNode:addPacketSize(packetType, packetSizeInBytes)
	if self.showNetworkTraffic then
		self.packetBytes[packetType] = self.packetBytes[packetType] + packetSizeInBytes
	end
end

function NetworkNode:updatePacketStats(dt)
	if self.showNetworkTraffic then
		local packetBytesSum = 0

		for i = 1, NetworkNode.NUM_PACKETS do
			self.packetGraphs[i]:addValue(packetBytesSum + self.packetBytes[i], packetBytesSum)

			packetBytesSum = packetBytesSum + self.packetBytes[i]
			self.packetBytes[i] = 0
		end

		self.lastUploadedKBs = packetBytesSum / 1024 * 1000 / dt
	end
end

function NetworkNode:draw()
	if self.showNetworkTraffic then
		local smoothAlpha = 0.8
		self.lastUploadedKBsSmooth = self.lastUploadedKBsSmooth * smoothAlpha + self.lastUploadedKBs * (1 - smoothAlpha)

		renderText(0.6, 0.8, getCorrectTextSize(0.025), string.format("Game Data Upload %.2fkb/s ", self.lastUploadedKBsSmooth))

		for i = 1, NetworkNode.NUM_PACKETS do
			self.packetGraphs[i]:draw()
		end

		local x = self.packetGraphs[1].left + self.packetGraphs[1].width + 0.01
		local y = self.packetGraphs[1].bottom
		local textSize = getCorrectTextSize(0.025)

		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_EVENT]))
		renderText(x, y, textSize, "event")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_VEHICLE]))
		renderText(x, y + textSize, textSize, "vehicle")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_PLAYER]))
		renderText(x, y + 2 * textSize, textSize, "player")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_SPLITSHAPES]))
		renderText(x, y + 3 * textSize, textSize, "split shapes")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_DENSITY_MAPS]))
		renderText(x, y + 4 * textSize, textSize, "density maps")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_TERRAIN_DEFORM]))
		renderText(x, y + 5 * textSize, textSize, "terrain deform")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_OTHERS]))
		renderText(x, y + 6 * textSize, textSize, "others")
		setTextColor(1, 1, 1, 1)

		if self.clientConnections ~= nil then
			local i = 0

			for _, connection in pairs(self.clientConnections) do
				if self:drawConnectionNetworkStats(connection, i) then
					i = i + 1
				end
			end
		elseif self.serverConnection ~= nil then
			self:drawConnectionNetworkStats(self.serverConnection, 0)
		end
	end

	if self.showActiveObjects then
		local objects = {}

		for id, object in pairs(self.activeObjects) do
			table.insert(objects, {
				id = id,
				obj = object,
				filename = tostring(object.configFileName)
			})
		end

		table.sort(objects, function (a, b)
			return a.id < b.id
		end)
		renderText(0.7, 0.915, 0.012, "Objects in update-loop:")

		for i, object in ipairs(objects) do
			renderText(0.7, 0.9 - i * 0.015, 0.012, string.format("%d: %s - %s", object.id, tostring(ClassUtil.getClassNameByObject(object.obj)), tostring(object.filename)))
		end
	end
end

function NetworkNode:packetReceived(packetType, timestamp, streamId)
end

function NetworkNode:getObject(id)
	return self.objects[id]
end

function NetworkNode:getObjectId(object)
	return self.objectIds[object]
end

function NetworkNode:addObject(object, id)
	self.objects[id] = object
	self.objectIds[object] = id

	self:addObjectToUpdateLoop(object)

	if self.networkListener ~= nil then
		self.networkListener:onObjectCreated(object)
	end
end

function NetworkNode:removeObject(object, id)
	self:removeObjectFromUpdateLoop(object)

	if self.networkListener ~= nil then
		self.networkListener:onObjectDeleted(object)
	end

	self.objects[id] = nil
	self.objectIds[object] = nil
end

function NetworkNode:addObjectToUpdateLoop(object)
	if object.isRegistered then
		local id = self:getObjectId(object)

		if id ~= nil then
			self.activeObjects[id] = object
			self.activeObjectsNextFrame[id] = object
		end
	end
end

function NetworkNode:removeObjectFromUpdateLoop(object)
	local id = self:getObjectId(object)

	if id ~= nil then
		self.removedObjects[id] = object
		self.activeObjects[id] = nil
		self.activeObjectsNextFrame[id] = nil
	end
end

function NetworkNode:registerObject(object, alreadySent)
end

function NetworkNode:unregisterObject(object, alreadySent)
end

function NetworkNode:consoleCommandToggleShowNetworkTraffic()
	self.showNetworkTraffic = not self.showNetworkTraffic

	return "ShowNetworkTraffic = " .. tostring(self.showNetworkTraffic)
end

function NetworkNode:consoleCommandToggleNetworkShowActiveObjects()
	self.showActiveObjects = not self.showActiveObjects

	return "NetworkShowActiveServerObjects = " .. tostring(self.showActiveObjects)
end
