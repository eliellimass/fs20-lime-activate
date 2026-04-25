ConnectionRequestAnswerEvent = {}
local ConnectionRequestAnswerEvent_mt = Class(ConnectionRequestAnswerEvent, Event)

InitStaticEventClass(ConnectionRequestAnswerEvent, "ConnectionRequestAnswerEvent", EventIds.EVENT_CONNECTION_REQUEST_ANSWER)

ConnectionRequestAnswerEvent.ANSWER_OK = 0
ConnectionRequestAnswerEvent.ANSWER_DENIED = 1
ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD = 2
ConnectionRequestAnswerEvent.ANSWER_FULL = 3
ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED = 4
ConnectionRequestAnswerEvent.ALREADY_IN_USE = 5

function ConnectionRequestAnswerEvent:emptyNew()
	local self = Event:new(ConnectionRequestAnswerEvent_mt)

	return self
end

function ConnectionRequestAnswerEvent:new(answer, difficulty, economicDifficulty, timeScale, isDedicatedServer, userId)
	local self = ConnectionRequestAnswerEvent:emptyNew()
	self.answer = answer
	self.difficulty = difficulty
	self.economicDifficulty = economicDifficulty
	self.timeScale = timeScale
	self.isDedicatedServer = isDedicatedServer
	self.userId = userId

	return self
end

function ConnectionRequestAnswerEvent:readStream(streamId, connection)
	self.answer = streamReadUIntN(streamId, 3)

	if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self.difficulty = streamReadUIntN(streamId, 3)
		self.economicDifficulty = streamReadUIntN(streamId, 3)
		self.timeScale = streamReadFloat32(streamId)
		self.isDedicatedServer = streamReadBool(streamId)
		self.userId = NetworkUtil.readNodeObjectId(streamId)
	end

	self:run(connection)
end

function ConnectionRequestAnswerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.answer, 3)

	if self.answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		streamWriteUIntN(streamId, self.difficulty, 3)
		streamWriteUIntN(streamId, self.economicDifficulty, 3)
		streamWriteFloat32(streamId, self.timeScale)
		streamWriteBool(streamId, self.isDedicatedServer)
		NetworkUtil.writeNodeObjectId(streamId, self.userId)
	end
end

function ConnectionRequestAnswerEvent:run(connection)
	g_currentMission:onConnectionRequestAnswer(connection, self.answer, self.difficulty, self.economicDifficulty, self.timeScale, self.isDedicatedServer, self.userId)
end
