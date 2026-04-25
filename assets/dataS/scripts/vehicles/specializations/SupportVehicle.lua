SupportVehicle = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
	end
}

function SupportVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "addSupportVehicle", SupportVehicle.addSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "removeSupportVehicle", SupportVehicle.removeSupportVehicle)
end

function SupportVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowMultipleAttachments", SupportVehicle.getAllowMultipleAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "resolveMultipleAttachments", SupportVehicle.resolveMultipleAttachments)
end

function SupportVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SupportVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", SupportVehicle)
end

function SupportVehicle:onLoad(savegame)
	local spec = self.spec_supportVehicle
	local baseKey = "vehicle.supportVehicle"
	local filename = getXMLString(self.xmlFile, baseKey .. "#filename")

	if filename ~= nil then
		spec.filename = Utils.getFilename(filename, self.customEnvironment)
	end

	spec.attacherJointIndex = getXMLInt(self.xmlFile, baseKey .. "#attacherJointIndex") or 1
	spec.inputAttacherJointIndex = getXMLInt(self.xmlFile, baseKey .. "#inputAttacherJointIndex") or 1
	spec.minTerrainDistance = getXMLFloat(self.xmlFile, baseKey .. "#minTerrainDistance") or 0.75
	spec.attachedMass = (getXMLFloat(self.xmlFile, baseKey .. "#attachedMass") or 10) / 1000
	spec.heightChecks = {}

	table.insert(spec.heightChecks, {
		x = self.sizeWidth / 2 + self.widthOffset,
		z = self.sizeLength / 2 + self.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = -self.sizeWidth / 2 + self.widthOffset,
		z = self.sizeLength / 2 + self.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = self.sizeWidth / 2 + self.widthOffset,
		z = -self.sizeLength / 2 + self.lengthOffset
	})
	table.insert(spec.heightChecks, {
		x = -self.sizeWidth / 2 + self.widthOffset,
		z = -self.sizeLength / 2 + self.lengthOffset
	})

	spec.configurations = {}
	local i = 0

	while true do
		local configurationKey = string.format("%s.configuration(%d)", baseKey, i)

		if not hasXMLProperty(self.xmlFile, configurationKey) then
			break
		end

		local name = getXMLString(self.xmlFile, configurationKey .. "#name")
		local id = getXMLInt(self.xmlFile, configurationKey .. "#id")

		if name ~= nil and id ~= nil then
			spec.configurations[name] = id
		end

		i = i + 1
	end

	spec.firstRun = true
end

function SupportVehicle:onDelete()
	if self.isServer then
		self:removeSupportVehicle()
	end
end

function SupportVehicle:onPostDetach(attacherVehicle, implement)
	if self.isServer and not self.isDeleting then
		local spec = self.spec_supportVehicle

		self:addSupportVehicle(spec.filename, spec.inputAttacherJointIndex, spec.attacherJointIndex)
	end
end

function SupportVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_supportVehicle

		if spec.firstRun then
			if self:getAttacherVehicle() == nil then
				self:addSupportVehicle(spec.filename, spec.inputAttacherJointIndex, spec.attacherJointIndex)
			end

			spec.firstRun = false
		end
	end
end

function SupportVehicle:addSupportVehicle(filename, inputAttacherJointIndex, attacherJointIndex)
	local spec = self.spec_supportVehicle

	if spec.filename ~= nil and spec.supportVehicle == nil then
		local component = self.components[1].node

		for _, check in ipairs(spec.heightChecks) do
			local x, y, z = localToWorld(component, check.x, 0, check.z)
			local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
			local difference = y - height

			if difference < spec.minTerrainDistance then
				for _, comp in ipairs(self.components) do
					local cx, cy, cz = getWorldTranslation(comp.node)

					setWorldTranslation(comp.node, cx, cy + spec.minTerrainDistance - difference, cz)
				end
			end
		end

		local storeItem = g_storeManager:getItemByXMLFilename(filename)

		if storeItem ~= nil then
			local inputAttacherJoint = self:getInputAttacherJoints()[inputAttacherJointIndex]

			if inputAttacherJoint ~= nil then
				local x, y, z = localToWorld(inputAttacherJoint.node, 0, 0, 0)
				local dirX, _, dirZ = localDirectionToWorld(inputAttacherJoint.node, 1, 0, 0)
				local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)

				self:removeFromPhysics()

				local vehicle = g_currentMission:loadVehicle(storeItem.xmlFilename, x, y, z, 0, yRot, false, 0, Vehicle.PROPERTY_STATE_NONE, self:getActiveFarm(), spec.configurations, nil, SupportVehicle.supportVehicleLoaded, self, {
					attacherJointIndex,
					inputAttacherJointIndex,
					inputAttacherJoint.node
				})

				if vehicle ~= nil then
					vehicle:setIsSupportVehicle()
				end
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Unable to find support vehicle '%s'.", filename)
		end
	end
end

function SupportVehicle:supportVehicleLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	if vehicleLoadState == BaseMission.VEHICLE_LOAD_OK and vehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		self:addToPhysics()

		local spec = self.spec_supportVehicle

		for i = 1, #self.components do
			setMass(self.components[i].node, spec.attachedMass)
		end

		if not self.isDeleted and attacherVehicle == nil then
			local offset = {
				0,
				0,
				0
			}
			local dirOffset = {
				0,
				0,
				0
			}

			if vehicle.getAttacherJoints ~= nil then
				local attacherJoints = vehicle:getAttacherJoints()

				if attacherJoints[asyncCallbackArguments[1]] ~= nil then
					offset = attacherJoints[asyncCallbackArguments[1]].jointOrigOffsetComponent
					dirOffset = attacherJoints[asyncCallbackArguments[1]].jointOrigDirOffsetComponent
				end
			end

			local x, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
			local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], unpack(dirOffset))
			local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)

			vehicle:setAbsolutePosition(x, y, z, 0, yRot, 0)
			vehicle:attachImplement(self, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, , true)
			self:getRootVehicle():updateSelectableObjects()
			self:getRootVehicle():setSelectedVehicle(self)

			spec.supportVehicle = vehicle
			local mapHotspot = self:getMapHotspot()

			if mapHotspot ~= nil then
				mapHotspot:setEnabled(true)
			end
		else
			vehicle:delete()
		end
	end
end

function SupportVehicle:removeSupportVehicle()
	local spec = self.spec_supportVehicle

	if spec.supportVehicle ~= nil then
		spec.supportVehicle:delete()

		spec.supportVehicle = nil
	end

	for i = 1, #self.components do
		local component = self.components[i]

		setMass(component.node, component.defaultMass)
	end
end

function SupportVehicle:getAllowMultipleAttachments(superFunc)
	return true
end

function SupportVehicle:resolveMultipleAttachments(superFunc)
	if self.isServer then
		self:removeSupportVehicle()
	end

	superFunc(self)
end
