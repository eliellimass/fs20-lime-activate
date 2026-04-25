I3DUtil = {
	checkChildIndex = function (node, index)
		if getNumOfChildren(node) <= index then
			g_logManager:error(string.format("Failed to find child %d from node %s, only %s childs given", tostring(index), tostring(getName(node)), tostring(getNumOfChildren(node))))
			printCallstack()

			return false
		end

		return true
	end
}

function I3DUtil.indexToObject(components, index, mappings)
	if index == nil or components == nil then
		return nil
	end

	if mappings ~= nil and mappings[index] ~= nil then
		index = mappings[index]
	end

	local curPos = 1
	local rootNode = nil
	local iStart, iEnd = string.find(index, ">", 1, true)

	if iStart ~= nil then
		curPos = iEnd + 1
	end

	if type(components) == "table" then
		local componentIndex = 1

		if iStart ~= nil then
			local curCompIndex = tonumber(string.sub(index, 1, iStart - 1))

			if curCompIndex == nil then
				g_logManager:error("Invalid index format: %s", tostring(index))
			end

			componentIndex = curCompIndex + 1
		end

		if components[componentIndex] == nil then
			g_logManager:error("Invalid compound index: %s", tostring(index))

			return nil
		end

		rootNode = components[componentIndex].node
	else
		rootNode = components
	end

	if iStart ~= nil and iEnd == string.len(index) then
		return rootNode, rootNode
	end

	if type(components) ~= "table" and iStart ~= nil then
		g_logManager:error(string.format("Invalid usage of '>'! Works with vehicle components table only. Please replace '>' with '|' in the xml config. Referenced node: '%s'", tostring(index)))
		printCallstack()

		return nil
	end

	local retVal = rootNode
	local iStart, iEnd = string.find(index, "|", curPos, true)

	while iStart ~= nil do
		local indexNumber = tonumber(string.sub(index, curPos, iStart - 1))

		if indexNumber == nil or not I3DUtil.checkChildIndex(retVal, indexNumber) then
			g_logManager:error("Index not found: %s", tostring(index))

			return nil
		end

		retVal = getChildAt(retVal, indexNumber)
		curPos = iEnd + 1
		iStart, iEnd = string.find(index, "|", curPos, true)
	end

	local indexNumber = tonumber(string.sub(index, curPos))

	if indexNumber == nil or not I3DUtil.checkChildIndex(retVal, indexNumber) then
		g_logManager:error("Index not found: %s", tostring(index))

		return nil
	end

	retVal = getChildAt(retVal, indexNumber)

	return retVal, rootNode
end

function I3DUtil.setNumberShaderByValue(numbers, value, precision, showZero)
	if numbers ~= nil then
		value = math.floor(value * 10^precision)

		for i = 0, getNumOfChildren(numbers) - 1 do
			local elem = getChildAt(numbers, i)

			if value > 0 then
				local curNumber = value - math.floor(value / 10) * 10
				value = (value - curNumber) / 10

				setShaderParameter(elem, "number", curNumber, 0, 0, 0, false)
			elseif showZero and i <= precision then
				setShaderParameter(elem, "number", 0, 0, 0, 0, false)
			else
				setShaderParameter(elem, "number", -1, 0, 0, 0, false)
			end
		end
	end
end

function I3DUtil.wakeUpObject(node)
	addImpulse(node, 0, 0.001, 0, 0, 0, 0, true)
end

function I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ, limitedAxis, minRot, maxRot)
	local parent = getParent(node)

	if MathUtil.isNan(dirX) or MathUtil.isNan(dirY) or MathUtil.isNan(dirZ) then
		g_logManager:error("Failed to set world direction: Object '%s' dir %.2f %.2f %.2f up %.2f %.2f %.2f", getName(node), dirX, dirY, dirZ, upX, upY, upZ)

		return
	end

	if parent ~= 0 then
		dirX, dirY, dirZ = worldDirectionToLocal(parent, dirX, dirY, dirZ)
		upX, upY, upZ = worldDirectionToLocal(parent, upX, upY, upZ)
	end

	if limitedAxis ~= nil then
		if limitedAxis == 1 then
			dirX = 0

			if minRot ~= nil then
				dirZ, dirY = MathUtil.getRotationLimitedVector2(dirZ, dirY, minRot, maxRot)
			end
		elseif limitedAxis == 2 then
			dirY = 0

			if minRot ~= nil then
				dirZ, dirX = MathUtil.getRotationLimitedVector2(dirZ, dirX, minRot, maxRot)
			end
		else
			dirZ = 0

			if minRot ~= nil then
				dirX, dirY = MathUtil.getRotationLimitedVector2(dirX, dirY, minRot, maxRot)
			end
		end
	end

	I3DUtil.setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
end

function I3DUtil.setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	if MathUtil.vector3LengthSq(dirX, dirY, dirZ) > 0.0001 then
		setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	end
end

function I3DUtil.setShaderParameterRec(node, shaderParam, x, y, z, w, sameMaterial, material)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		if sameMaterial ~= nil and sameMaterial and material == nil then
			material = getMaterial(node, 0)
		end

		if material == nil or getMaterial(node, 0) == material then
			setShaderParameter(node, shaderParam, x, y, z, w, false)
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			I3DUtil.setShaderParameterRec(getChildAt(node, i), shaderParam, x, y, z, w, sameMaterial, material)
		end
	end
end

function I3DUtil.getNodesByShaderParam(node, shaderParam, nodes, sorted)
	if nodes == nil then
		nodes = {}
	end

	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		if sorted == nil or not sorted then
			nodes[node] = node
		else
			table.insert(nodes, node)
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			I3DUtil.getNodesByShaderParam(getChildAt(node, i), shaderParam, nodes, sorted)
		end
	end

	return nodes
end

function I3DUtil.printChildren(node, offset)
	offset = offset or "    "

	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)

		log(offset, child, getName(child))
		I3DUtil.printChildren(child, offset .. "    ")
	end
end

function I3DUtil.hasNamedChildren(node, name)
	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)

		if getName(child) == name or I3DUtil.hasNamedChildren(child, name) then
			return true
		end
	end

	return false
end
