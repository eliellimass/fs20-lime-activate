TensionBeltObject = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function TensionBeltObject.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsTensionBelts", TensionBeltObject.getSupportsTensionBelts)
	SpecializationUtil.registerFunction(vehicleType, "getMeshNodes", TensionBeltObject.getMeshNodes)
	SpecializationUtil.registerFunction(vehicleType, "getTensionBeltNodeId", TensionBeltObject.getTensionBeltNodeId)
end

function TensionBeltObject.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBeltObject)
end

function TensionBeltObject:onLoad(savegame)
	local spec = self.spec_tensionBeltObject
	spec.supportsTensionBelts = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.tensionBeltObject#supportsTensionBelts"), true)
	spec.meshNodes = {}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.tensionBeltObject.meshNodes.meshNode(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, baseKey .. "#node"), self.i3dMappings)

		if node ~= nil then
			table.insert(spec.meshNodes, node)
		end

		i = i + 1
	end
end

function TensionBeltObject:getSupportsTensionBelts()
	return self.spec_tensionBeltObject.supportsTensionBelts
end

function TensionBeltObject:getMeshNodes()
	return self.spec_tensionBeltObject.meshNodes
end

function TensionBeltObject:getTensionBeltNodeId()
	return self.components[1].node
end
