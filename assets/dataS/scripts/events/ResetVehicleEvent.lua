ResetVehicleEvent = {
	STATE_SUCCESS = 0,
	STATE_FAILED = 1,
	STATE_NO_PERMISSION = 2,
	STATE_IN_USE = 3
}
local ResetVehicleEvent_mt = Class(ResetVehicleEvent, Event)

InitStaticEventClass(ResetVehicleEvent, "ResetVehicleEvent", EventIds.EVENT_RESET_VEHICLE)

function ResetVehicleEvent:emptyNew()
	local self = Event:new(ResetVehicleEvent_mt)

	return self
end

function ResetVehicleEvent:new(vehicle)
	local self = ResetVehicleEvent:emptyNew()
	self.vehicle = vehicle

	return self
end

function ResetVehicleEvent:newServerToClient(state)
	local self = ResetVehicleEvent:emptyNew()
	self.state = state

	return self
end

function ResetVehicleEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.vehicle = NetworkUtil.readNodeObject(streamId)
	else
		self.state = streamReadUIntN(streamId, 2)
	end

	self:run(connection)
end

function ResetVehicleEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
	else
		streamWriteUIntN(streamId, self.state, 2)
	end
end

function ResetVehicleEvent:run(connection)
	if not connection:getIsServer() then
		local state = ResetVehicleEvent.STATE_FAILED
		local vehicle = self.vehicle

		if vehicle ~= nil and vehicle.isVehicleSaved then
			if g_currentMission:getHasPlayerPermission("resetVehicle", connection, vehicle:getOwnerFarmId()) then
				if vehicle.getIsControlled == nil or not vehicle:getIsControlled() then
					local xmlFile = Vehicle.getReloadXML(vehicle)
					local key = "vehicles.vehicle(0)"
					local ret, newVehicle = g_currentMission:loadVehicleFromXML(xmlFile, key, true, false)

					if ret == BaseMission.VEHICLE_LOAD_OK then
						g_messageCenter:publish(MessageType.VEHICLE_RESET, vehicle, newVehicle)
						g_currentMission:removeVehicle(vehicle)

						state = ResetVehicleEvent.STATE_SUCCESS
					elseif ret == BaseMission.VEHICLE_LOAD_NO_SPACE and newVehicle ~= nil then
						g_currentMission:removeVehicle(newVehicle)
					end

					delete(xmlFile)
				else
					state = ResetVehicleEvent.STATE_IN_USE
				end
			else
				state = ResetVehicleEvent.STATE_NO_PERMISSION
			end
		end

		connection:sendEvent(ResetVehicleEvent:newServerToClient(state))
	else
		g_messageCenter:publish(ResetVehicleEvent, self.state)
	end
end
