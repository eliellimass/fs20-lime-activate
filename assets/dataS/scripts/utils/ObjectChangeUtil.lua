ObjectChangeUtil = {}

function ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, objects, rootNode, parent)
	local i = 0

	while true do
		local nodeKey = string.format(key .. ".objectChange(%d)", i)

		if not hasXMLProperty(xmlFile, nodeKey) then
			break
		end

		local node = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, nodeKey .. "#node"), parent.i3dMappings)

		if node ~= nil then
			local object = {
				node = node
			}

			ObjectChangeUtil.loadValuesFromXML(xmlFile, nodeKey, node, object, parent)
			table.insert(objects, object)
		end

		i = i + 1
	end
end

function ObjectChangeUtil.loadValuesFromXML(xmlFile, key, node, object, parent)
	object.visibilityActive = getXMLBool(xmlFile, key .. "#visibilityActive")
	object.visibilityInactive = getXMLBool(xmlFile, key .. "#visibilityInactive")
	object.translationActive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#translationActive"), 3)
	object.translationInactive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#translationInactive"), 3)
	object.rotationActive = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotationActive"), 3)
	object.rotationInactive = StringUtil.getRadiansFromString(getXMLString(xmlFile, key .. "#rotationInactive"), 3)
	object.scaleActive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#scaleActive"), 3)
	object.scaleInactive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#scaleInactive"), 3)

	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionActive", key .. "#compoundChildActive or #rigidBodyTypeActive")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionInactive", key .. "#compoundChildInactive or #rigidBodyTypeInactive")

	object.massActive = nil
	object.massInactive = nil
	local massActive = getXMLFloat(xmlFile, key .. "#massActive")

	if massActive ~= nil then
		object.massActive = massActive / 1000
	end

	local massInactive = getXMLFloat(xmlFile, key .. "#massInactive")

	if massInactive ~= nil then
		object.massInactive = massInactive / 1000
	end

	object.centerOfMassActive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#centerOfMassActive"), 3)
	object.centerOfMassInactive = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#centerOfMassInactive"), 3)
	object.compoundChildActive = getXMLBool(xmlFile, key .. "#compoundChildActive")
	object.compoundChildInactive = getXMLBool(xmlFile, key .. "#compoundChildInactive")
	object.rigidBodyTypeActive = getXMLString(xmlFile, key .. "#rigidBodyTypeActive")
	object.rigidBodyTypeInactive = getXMLString(xmlFile, key .. "#rigidBodyTypeInactive")

	if object.rigidBodyTypeActive ~= nil then
		local t = object.rigidBodyTypeActive

		if t ~= "Static" and t ~= "Dynamic" and t ~= "Kinematic" and t ~= "NoRigidBody" then
			g_logManager:warning("Invalid rigidBodyTypeActive '%s' for object change node '%s'. Use 'Static', 'Dynamic', 'Kinematic' or 'NoRigidBody'!", t, key)

			object.rigidBodyTypeActive = nil
		end
	end

	if object.rigidBodyTypeInactive ~= nil then
		local t = object.rigidBodyTypeInactive

		if t ~= "Static" and t ~= "Dynamic" and t ~= "Kinematic" and t ~= "NoRigidBody" then
			g_logManager:warning("Invalid rigidBodyTypeInactive '%s' for object change node '%s'. Use 'Static', 'Dynamic', 'Kinematic' or 'NoRigidBody'!", t, key)

			object.rigidBodyTypeInactive = nil
		end
	end

	if parent ~= nil and parent.loadObjectChangeValuesFromXML ~= nil then
		parent:loadObjectChangeValuesFromXML(xmlFile, key, node, object)
	end
end

function ObjectChangeUtil.setObjectChanges(objects, isActive, target, updateFunc)
	for _, object in pairs(objects) do
		ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc)
	end
end

function ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc)
	if isActive then
		if object.visibilityActive ~= nil then
			setVisibility(object.node, object.visibilityActive)
		end

		if object.translationActive ~= nil then
			setTranslation(object.node, object.translationActive[1], object.translationActive[2], object.translationActive[3])
		end

		if object.rotationActive ~= nil then
			setRotation(object.node, object.rotationActive[1], object.rotationActive[2], object.rotationActive[3])
		end

		if object.scaleActive ~= nil then
			setScale(object.node, object.scaleActive[1], object.scaleActive[2], object.scaleActive[3])
		end

		if object.massActive ~= nil then
			setMass(object.node, object.massActive)

			if target ~= nil and target.components ~= nil then
				for _, component in ipairs(target.components) do
					if component.node == object.node then
						component.defaultMass = object.massActive

						target:setMassDirty()
					end
				end
			end
		end

		if object.centerOfMassActive ~= nil then
			setCenterOfMass(object.node, unpack(object.centerOfMassActive))
		end

		if object.compoundChildActive ~= nil then
			setIsCompoundChild(object.node, object.compoundChildActive)
		end

		if object.rigidBodyTypeActive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeActive)
		end
	else
		if object.visibilityInactive ~= nil then
			setVisibility(object.node, object.visibilityInactive)
		end

		if object.translationInactive ~= nil then
			setTranslation(object.node, object.translationInactive[1], object.translationInactive[2], object.translationInactive[3])
		end

		if object.rotationInactive ~= nil then
			setRotation(object.node, object.rotationInactive[1], object.rotationInactive[2], object.rotationInactive[3])
		end

		if object.scaleInactive ~= nil then
			setScale(object.node, object.scaleInactive[1], object.scaleInactive[2], object.scaleInactive[3])
		end

		if object.massInactive ~= nil then
			setMass(object.node, object.massInactive)

			if target ~= nil and target.components ~= nil then
				for _, component in ipairs(target.components) do
					if component.node == object.node then
						component.defaultMass = object.massInactive

						target:setMassDirty()
					end
				end
			end
		end

		if object.centerOfMassInactive ~= nil then
			setCenterOfMass(object.node, unpack(object.centerOfMassInactive))
		end

		if object.compoundChildInactive ~= nil then
			setIsCompoundChild(object.node, object.compoundChildInactive)
		end

		if object.rigidBodyTypeInactive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeInactive)
		end
	end

	if target ~= nil then
		if target.setObjectChangeValues ~= nil then
			target:setObjectChangeValues(object, isActive)
		end

		if updateFunc ~= nil then
			updateFunc(target, object.node)
		end
	end
end

function ObjectChangeUtil.updateObjectChanges(xmlFile, key, configKey, rootNode, parent)
	local i = 0
	local activeI = configKey - 1

	while true do
		local objectChangeKey = string.format(key .. "(%d)", i)

		if not hasXMLProperty(xmlFile, objectChangeKey) then
			break
		end

		if i ~= activeI then
			local objects = {}

			ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, objects, rootNode, parent)
			ObjectChangeUtil.setObjectChanges(objects, false, parent)
		end

		i = i + 1
	end

	if activeI < i then
		local objectChangeKey = string.format(key .. "(%d)", activeI)
		local objects = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, objects, rootNode, parent)
		ObjectChangeUtil.setObjectChanges(objects, true, parent)
	end
end
