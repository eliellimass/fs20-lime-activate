MeshEvent = {}
local MeshEvent_mt = Class(MeshEvent, Event)

InitStaticEventClass(MeshEvent, "MeshEvent", EventIds.EVENT_MESH)

function MeshEvent:emptyNew()
	local self = Event:new(MeshEvent_mt)

	return self
end

function MeshEvent:new(mesh)
	local self = MeshEvent:emptyNew()
	self.mesh = mesh

	return self
end

function MeshEvent:readStream(streamId, connection)
	local numNodes = streamReadInt8(streamId)
	self.mesh = {}

	for i = 1, numNodes do
		local platformNodeId = streamReadString(streamId)
		local platformUserId = streamReadString(streamId)

		table.insert(self.mesh, {
			platformNodeId = platformNodeId,
			platformUserId = platformUserId
		})
	end

	self:run(connection)
end

function MeshEvent:writeStream(streamId, connection)
	local numNodes = table.getn(self.mesh)

	streamWriteInt8(streamId, numNodes)

	for i = 1, numNodes do
		streamWriteString(streamId, self.mesh[i].platformNodeId)
		streamWriteString(streamId, self.mesh[i].platformUserId)
	end
end

function MeshEvent:run(connection)
	g_currentMission.mesh = self.mesh

	g_currentMission:onMeshEvent()
end
