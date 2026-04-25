BaleGrab = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function BaleGrab.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabTriggerCallback", BaleGrab.baleGrabTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", BaleGrab.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", BaleGrab.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "isComponentJointOutsideLimit", BaleGrab.isComponentJointOutsideLimit)
end

function BaleGrab.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", BaleGrab.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", BaleGrab.removeNodeObjectMapping)
end

function BaleGrab.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleGrab)
end

function BaleGrab:onLoad(savegame)
	local spec = self.spec_baleGrab

	if self.isServer then
		local attacherTriggerTriggerNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baleGrab#triggerNode"), self.i3dMappings)
		local attacherTriggerRootNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baleGrab#rootNode"), self.i3dMappings)
		local attacherTriggerJointNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.baleGrab#jointNode"), self.i3dMappings)
		local attacherJointTypeString = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.baleGrab#jointType"), "TYPE_AUTO_ATTACH_XYZ")
		local attacherJointType = DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ

		if DynamicMountUtil[attacherJointTypeString] ~= nil then
			attacherJointType = DynamicMountUtil[attacherJointTypeString]
		end

		if attacherTriggerTriggerNode ~= nil and attacherTriggerRootNode ~= nil and attacherTriggerJointNode ~= nil then
			local forceAcceleration = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baleGrab#forceAcceleration"), 20)

			addTrigger(attacherTriggerTriggerNode, "baleGrabTriggerCallback", self)

			local grabRefComponentJointIndex1 = getXMLInt(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex1")
			local grabRefComponentJointIndex2 = getXMLInt(self.xmlFile, "vehicle.baleGrab#grabRefComponentJointIndex2")
			local componentJoint1, componentJoint2 = nil

			if grabRefComponentJointIndex1 ~= nil then
				componentJoint1 = self.componentJoints[grabRefComponentJointIndex1 + 1]
			end

			if grabRefComponentJointIndex2 ~= nil then
				componentJoint2 = self.componentJoints[grabRefComponentJointIndex2 + 1]
			end

			local rotDiffThreshold1 = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold1"), 2))
			local rotDiffThreshold2 = math.rad(Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.baleGrab#rotDiffThreshold2"), 2))
			spec.dynamicMountAttacherTrigger = {
				triggerNode = attacherTriggerTriggerNode,
				rootNode = attacherTriggerRootNode,
				jointNode = attacherTriggerJointNode,
				attacherJointType = attacherJointType,
				forceAcceleration = forceAcceleration,
				componentJoint1 = componentJoint1,
				rotDiffThreshold1 = rotDiffThreshold1,
				cosRotDiffThreshold1 = math.cos(rotDiffThreshold1),
				componentJoint2 = componentJoint2,
				rotDiffThreshold2 = rotDiffThreshold2,
				cosRotDiffThreshold2 = math.cos(rotDiffThreshold2)
			}
		end

		spec.dynamicMountedObjects = {}
		spec.pendingDynamicMountObjects = {}
	end
end

function BaleGrab:onDelete()
	local spec = self.spec_baleGrab

	if self.isServer then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			object:unmountDynamic()
		end
	end

	if spec.dynamicMountAttacherTrigger ~= nil then
		removeTrigger(spec.dynamicMountAttacherTrigger.triggerNode)
	end
end

function BaleGrab:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_baleGrab
		local attachTrigger = spec.dynamicMountAttacherTrigger
		local isClosed = true

		if attachTrigger.componentJoint1 ~= nil then
			isClosed = self:isComponentJointOutsideLimit(attachTrigger.componentJoint1, attachTrigger.rotDiffThreshold1, attachTrigger.cosRotDiffThreshold1)
		end

		if isClosed and attachTrigger.componentJoint2 ~= nil then
			isClosed = self:isComponentJointOutsideLimit(attachTrigger.componentJoint2, attachTrigger.rotDiffThreshold2, attachTrigger.cosRotDiffThreshold2)
		end

		if isClosed then
			for object, _ in pairs(spec.pendingDynamicMountObjects) do
				if spec.dynamicMountedObjects[object] == nil then
					object:unmountDynamic()

					local dynamicMountData = spec.dynamicMountAttacherTrigger

					if object:mountDynamic(self, dynamicMountData.rootNode, dynamicMountData.jointNode, dynamicMountData.attacherJointType, dynamicMountData.forceAcceleration) then
						self:addDynamicMountedObject(object)
					end
				end
			end
		else
			for object, _ in pairs(spec.dynamicMountedObjects) do
				self:removeDynamicMountedObject(object, false)
				object:unmountDynamic()
			end
		end
	end
end

function BaleGrab:addDynamicMountedObject(object)
	local spec = self.spec_baleGrab
	spec.dynamicMountedObjects[object] = object
end

function BaleGrab:removeDynamicMountedObject(object, isDeleting)
	local spec = self.spec_baleGrab
	spec.dynamicMountedObjects[object] = nil

	if isDeleting then
		spec.pendingDynamicMountObjects[object] = nil
	end
end

function BaleGrab:baleGrabTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_baleGrab

	if onEnter then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object == nil then
			object = g_currentMission.nodeToObject[otherActorId]
		end

		if object ~= nil and object ~= self and object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() then
			spec.pendingDynamicMountObjects[object] = Utils.getNoNil(spec.pendingDynamicMountObjects[object], 0) + 1
		end
	elseif onLeave then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object == nil then
			object = g_currentMission.nodeToObject[otherActorId]
		end

		if object ~= nil and spec.pendingDynamicMountObjects[object] ~= nil then
			local count = spec.pendingDynamicMountObjects[object] - 1

			if count == 0 then
				spec.pendingDynamicMountObjects[object] = nil

				if spec.dynamicMountedObjects[object] ~= nil then
					self:removeDynamicMountedObject(object, false)
					object:unmountDynamic()
				end
			else
				spec.pendingDynamicMountObjects[object] = count
			end
		end
	end
end

function BaleGrab:isComponentJointOutsideLimit(componentJoint, maxRot, cosMaxRot)
	local x, _, z = localDirectionToLocal(self.components[componentJoint.componentIndices[2]].node, componentJoint.jointNode, 0, 0, 1)

	if x >= 0 == (maxRot >= 0) and z <= cosMaxRot * math.sqrt(x * x + z * z) then
		return true
	end

	return false
end

function BaleGrab:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleGrab

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = self
	end
end

function BaleGrab:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleGrab

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = nil
	end
end
