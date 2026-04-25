ListUtil = {
	copyTable = function (sourceTable)
		if sourceTable == nil then
			return nil
		end

		local newTable = {}

		for key, value in pairs(sourceTable) do
			newTable[key] = value
		end

		return setmetatable(newTable, getmetatable(sourceTable))
	end
}

function ListUtil.copyTableRecursively(sourceTable)
	if sourceTable == nil then
		return nil
	end

	local newTable = {}

	for key, value in pairs(sourceTable) do
		if type(value) == "table" then
			newTable[key] = ListUtil.copyTableRecursively(value)
		else
			newTable[key] = value
		end
	end

	return setmetatable(newTable, getmetatable(sourceTable))
end

function ListUtil.addElementToList(list, newElement)
	if list ~= nil and newElement ~= nil then
		for k, element in ipairs(list) do
			if element == newElement then
				return false, k
			end
		end

		table.insert(list, newElement)

		return true, #list
	end

	return false, -1
end

function ListUtil.removeElementFromList(list, element)
	if list ~= nil and element ~= nil then
		for i, v in ipairs(list) do
			if v == element then
				table.remove(list, i)

				return true
			end
		end
	end

	return false
end

function ListUtil.hasListElement(list, element)
	if list ~= nil and element ~= nil then
		for _, element1 in pairs(list) do
			if element1 == element then
				return true
			end
		end
	end

	return false
end

function ListUtil.findListElementFirstIndex(list, element, defaultReturn)
	if list ~= nil and element ~= nil then
		for key, value in ipairs(list) do
			if value == element then
				return key
			end
		end
	end

	return defaultReturn
end

function ListUtil.areListsEqual(list1, list2, orderIndependent)
	if #list1 ~= #list2 then
		return false
	end

	if orderIndependent then
		for _, element1 in ipairs(list1) do
			if not ListUtil.hasListElement(list2, element1) then
				return false
			end
		end

		for _, element2 in ipairs(list2) do
			if not ListUtil.hasListElement(list1, element2) then
				return false
			end
		end

		return true
	else
		for i, element1 in ipairs(list1) do
			if list2[i] ~= element1 then
				return false
			end
		end

		return true
	end
end

function ListUtil.getRandomElement(list)
	return list[math.random(table.getn(list))]
end

function ListUtil.listToSet(list)
	local result = {}

	for _, element in ipairs(list) do
		result[element] = element
	end

	return result
end

function ListUtil.setToList(set)
	local result = {}

	for element, _ in pairs(set) do
		table.insert(result, element)
	end

	return result
end

function ListUtil.setToHash(set)
	local result = {}

	for element, value in pairs(set) do
		result[element] = value
	end

	return result
end

function ListUtil.areSetsEqual(set1, set2)
	return ListUtil.isSubset(set1, set2) and ListUtil.isSubset(set2, set1)
end

function ListUtil.isSubset(set1, set2)
	for element1, _ in pairs(set1) do
		if set2[element1] == nil then
			return false
		end
	end

	return true
end

function ListUtil.isRealSubset(set1, set2)
	return ListUtil.isSubset(set1, set2) and not ListUtil.isSubset(set2, set1)
end

function ListUtil.hasSetIntersection(set1, set2)
	for element1, _ in pairs(set1) do
		if set2[element1] ~= nil then
			return true
		end
	end

	return false
end

function ListUtil.getSetIntersection(set1, set2)
	local result = {}

	for element1, _ in pairs(set1) do
		if set2[element1] ~= nil then
			result[element1] = element1
		end
	end

	return result
end

function ListUtil.getSetSubtraction(set1, set2)
	local result = {}

	for element, _ in pairs(set1) do
		if set2[element] == nil then
			result[element] = element
		end
	end

	return result
end

function ListUtil.getSetUnion(set1, set2)
	local result = {}

	for element, _ in pairs(set1) do
		result[element] = element
	end

	for element, _ in pairs(set2) do
		result[element] = element
	end

	return result
end

function ListUtil.filter(list, closure)
	local result = {}

	for key, element in pairs(list) do
		if closure(element, key) then
			result[key] = element
		end
	end

	return result
end

function ListUtil.ifilter(list, closure)
	local result = {}

	for index, element in ipairs(list) do
		if closure(element, index) then
			table.insert(result, element)
		end
	end

	return result
end

function ListUtil.size(t)
	local count = 0

	for _ in pairs(t) do
		count = count + 1
	end

	return count
end
