VehicleSchemaOverlayData = {}
local VehicleSchemaOverlayData_mt = Class(VehicleSchemaOverlayData)

function VehicleSchemaOverlayData.new(offsetX, offsetY, schemaNameDefault, schemaNameOn, schemaNameSelected, schemaNameSelectedOn, invisibleBorderRight, invisibleBorderLeft)
	local self = setmetatable({}, VehicleSchemaOverlayData_mt)
	self.offsetX = offsetX or 0
	self.offsetY = offsetY or 0
	self.schemaNameDefault = schemaNameDefault
	self.schemaNameOn = schemaNameOn
	self.schemaNameSelected = schemaNameSelected
	self.schemaNameSelectedOn = schemaNameSelectedOn
	self.invisibleBorderRight = invisibleBorderRight or 0.05
	self.invisibleBorderLeft = invisibleBorderLeft or 0.05
	self.attacherJoints = nil

	return self
end

function VehicleSchemaOverlayData:addAttacherJoint(attacherOffsetX, attacherOffsetY, rotation, invertX, liftedOffsetX, liftedOffsetY)
	if not self.attacherJoints then
		self.attacherJoints = {}
	end

	local attacherJointData = {
		x = attacherOffsetX or 0,
		y = attacherOffsetY or 0,
		rotation = rotation or 0,
		invertX = not not invertX,
		liftedOffsetX = liftedOffsetX or 0,
		liftedOffsetY = liftedOffsetY or 5
	}

	table.insert(self.attacherJoints, attacherJointData)
end

VehicleSchemaOverlayData.SCHEMA_OVERLAY = {
	DEFAULT_VEHICLE = "DEFAULT_VEHICLE",
	DEFAULT_VEHICLE_SELECTED = "DEFAULT_VEHICLE_SELECTED",
	DEFAULT_VEHICLE_SELECTED_ON = "DEFAULT_VEHICLE_SELECTED_ON",
	DEFAULT_VEHICLE_ON = "DEFAULT_VEHICLE_ON",
	DEFAULT_IMPLEMENT = "DEFAULT_IMPLEMENT",
	DEFAULT_IMPLEMENT_SELECTED = "DEFAULT_IMPLEMENT_SELECTED",
	DEFAULT_IMPLEMENT_SELECTED_ON = "DEFAULT_IMPLEMENT_SELECTED_ON",
	DEFAULT_IMPLEMENT_ON = "DEFAULT_IMPLEMENT_ON"
}
