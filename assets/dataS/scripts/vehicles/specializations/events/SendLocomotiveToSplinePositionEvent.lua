SendLocomotiveToSplinePositionEvent = {}
local SendLocomotiveToSplinePositionEvent_mt = Class(SendLocomotiveToSplinePositionEvent, Event)

InitStaticEventClass(SendLocomotiveToSplinePositionEvent, "SendLocomotiveToSplinePositionEvent", EventIds.EVENT_SEND_LOCOMOTIVE_TO_SPLINE_POSITION)

function SendLocomotiveToSplinePositionEvent:emptyNew()
	local self = Event:new(SendLocomotiveToSplinePositionEvent_mt)

	return self
end

function SendLocomotiveToSplinePositionEvent:new(vehicle, splinePosition)
	local self = SendLocomotiveToSplinePositionEvent:emptyNew()
	self.vehicle = vehicle
	self.splinePosition = splinePosition

	return self
end

function SendLocomotiveToSplinePositionEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.splinePosition = streamReadFloat32(streamId)

	self.vehicle:setRequestedSplinePosition(self.splinePosition)
end

function SendLocomotiveToSplinePositionEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteFloat32(streamId, self.splinePosition)
end
