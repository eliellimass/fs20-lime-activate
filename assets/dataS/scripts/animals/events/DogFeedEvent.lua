DogFeedEvent = {}
local DogFeedEvent_mt = Class(DogFeedEvent, Event)

InitStaticEventClass(DogFeedEvent, "DogFeedEvent", EventIds.EVENT_DOG_FEED)

function DogFeedEvent:emptyNew()
	local self = Event:new(DogFeedEvent_mt)

	return self
end

function DogFeedEvent:new(dog)
	local self = DogFeedEvent:emptyNew()
	self.dog = dog

	return self
end

function DogFeedEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function DogFeedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
end

function DogFeedEvent:run(connection)
	if self.dog ~= nil then
		self.dog:feed()
	end
end
