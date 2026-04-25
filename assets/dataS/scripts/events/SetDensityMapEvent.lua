SetDensityMapEvent = {}
local SetDensityMapEvent_mt = Class(SetDensityMapEvent, Event)

InitStaticEventClass(SetDensityMapEvent, "SetDensityMapEvent", EventIds.EVENT_SET_DENSITY_MAP)

SetDensityMapEvent.PartSizeBits = 160000

function SetDensityMapEvent:emptyNew()
	local self = Event:new(SetDensityMapEvent_mt)
	self.streamId = createStream()

	return self
end

function SetDensityMapEvent:newAck(ackIndex)
	local self = SetDensityMapEvent:emptyNew()
	self.ackIndex = ackIndex

	return self
end

function SetDensityMapEvent:newReceiving(numParts)
	local self = SetDensityMapEvent:emptyNew()
	self.numParts = numParts

	return self
end

function SetDensityMapEvent:new()
	local self = SetDensityMapEvent:emptyNew()
	local streamId = self.streamId
	local sentDensityMaps = {}

	for i = 1, table.getn(g_currentMission.fruitsList) do
		local fruit = g_currentMission.fruitsList[i]

		if fruit.id ~= 0 then
			local filename = getDensityMapFilename(fruit.id)

			if sentDensityMaps[filename] == nil then
				streamWriteBool(streamId, true)

				sentDensityMaps[filename] = true

				writeDensityDataToStream(fruit.id, streamId)
			else
				streamWriteBool(streamId, false)
			end
		end

		if fruit.preparingOutputId ~= 0 then
			local filename = getDensityMapFilename(fruit.preparingOutputId)

			if sentDensityMaps[filename] == nil then
				streamWriteBool(streamId, true)

				sentDensityMaps[filename] = true

				writeDensityDataToStream(fruit.preparingOutputId, streamId)
			else
				streamWriteBool(streamId, false)
			end
		end
	end

	local detailFilename = getDensityMapFilename(g_currentMission.terrainDetailId)

	if sentDensityMaps[detailFilename] == nil then
		streamWriteBool(streamId, true)

		sentDensityMaps[detailFilename] = true

		writeDensityDataToStream(g_currentMission.terrainDetailId, streamId)
	else
		streamWriteBool(streamId, false)
	end

	for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
		local id = g_currentMission.dynamicFoliageLayers[i]
		local filename = getDensityMapFilename(id)

		if sentDensityMaps[filename] == nil then
			streamWriteBool(streamId, true)

			sentDensityMaps[filename] = true

			writeDensityDataToStream(id, streamId)
		else
			streamWriteBool(streamId, false)
		end
	end

	self.currentPartIndex = 0
	self.numParts = math.ceil(streamGetWriteOffset(streamId) / SetDensityMapEvent.PartSizeBits)
	self.percentage = 0

	return self
end

function SetDensityMapEvent:delete()
	if self.streamId ~= 0 then
		delete(self.streamId)

		self.streamId = 0
	end
end

function SetDensityMapEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local currentPartIndex = streamReadInt32(streamId)

		if currentPartIndex == 0 then
			local numParts = streamReadInt32(streamId)
			g_currentMission.receivingDensityMapEvent = SetDensityMapEvent:newReceiving(numParts)
		end

		local event = g_currentMission.receivingDensityMapEvent

		streamWriteStream(event.streamId, streamId, SetDensityMapEvent.PartSizeBits, true)
		g_currentMission:onDensityMapsProgress(connection, (currentPartIndex + 1) / event.numParts)
		connection:sendEvent(SetDensityMapEvent:newAck(currentPartIndex))

		if currentPartIndex == event.numParts - 1 then
			event:processReadData()
			g_currentMission.receivingDensityMapEvent:delete()

			g_currentMission.receivingDensityMapEvent = nil
		end
	else
		local ackIndex = streamReadInt32(streamId)
		local syncPlayer = g_currentMission.playersSynchronizing[connection]

		if syncPlayer ~= nil and syncPlayer.densityMapEvent ~= nil then
			local densityMapEvent = syncPlayer.densityMapEvent
			densityMapEvent.percentage = (ackIndex + 1) / densityMapEvent.numParts

			if ackIndex + 1 < densityMapEvent.numParts then
				connection:sendEvent(densityMapEvent, false)
			end

			g_currentMission:onDensityMapsProgress(connection, (ackIndex + 1) / densityMapEvent.numParts)
		end
	end
end

function SetDensityMapEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		assert(g_currentMission.playersSynchronizing[connection].densityMapEvent == self)

		local currentPartIndex = self.currentPartIndex
		self.currentPartIndex = currentPartIndex + 1

		streamWriteInt32(streamId, currentPartIndex)

		if currentPartIndex == 0 then
			streamWriteInt32(streamId, self.numParts)
		end

		local readOffset = streamGetReadOffset(self.streamId)

		streamSetReadOffset(self.streamId, currentPartIndex * SetDensityMapEvent.PartSizeBits)
		streamWriteStream(streamId, self.streamId, SetDensityMapEvent.PartSizeBits, true)
		streamSetReadOffset(self.streamId, readOffset)
	else
		streamWriteInt32(streamId, self.ackIndex)
	end
end

function SetDensityMapEvent:processReadData()
	local streamId = self.streamId

	for i = 1, table.getn(g_currentMission.fruitsList) do
		local fruit = g_currentMission.fruitsList[i]

		if fruit.id ~= 0 then
			local hasData = streamReadBool(streamId)

			if hasData then
				readDensityDataFromStream(fruit.id, streamId)
			end
		end

		if fruit.preparingOutputId ~= 0 then
			local hasData = streamReadBool(streamId)

			if hasData then
				readDensityDataFromStream(fruit.preparingOutputId, streamId)
			end
		end
	end

	local hasData = streamReadBool(streamId)

	if hasData then
		readDensityDataFromStream(g_currentMission.terrainDetailId, streamId)
	end

	for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
		local id = g_currentMission.dynamicFoliageLayers[i]
		local hasData = streamReadBool(streamId)

		if hasData then
			readDensityDataFromStream(id, streamId)
		end
	end
end

function SetDensityMapEvent:run(connection)
end
