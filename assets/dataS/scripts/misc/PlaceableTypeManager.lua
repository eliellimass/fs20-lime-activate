PlaceableTypeManager = {}
local PlaceableTypeManager_mt = Class(PlaceableTypeManager, AbstractManager)

function PlaceableTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or PlaceableTypeManager_mt)

	return self
end

function PlaceableTypeManager:initDataStructures()
	self.placeableTypes = {}
end

function PlaceableTypeManager:loadMapData()
	PlaceableTypeManager:superClass().loadMapData(self)

	local xmlFile = loadXMLFile("PlaceableTypesXML", "dataS/placeableTypes.xml")
	local i = 0

	while true do
		local baseName = string.format("placeableTypes.placeableType(%d)", i)
		local typeName = getXMLString(xmlFile, baseName .. "#name")

		if typeName == nil then
			break
		end

		local className = getXMLString(xmlFile, baseName .. "#className")
		local filename = getXMLString(xmlFile, baseName .. "#filename")

		self:addPlaceableType(typeName, className, filename, "")

		i = i + 1
	end

	delete(xmlFile)
	print("  Loaded placeable types")

	return true
end

function PlaceableTypeManager:addPlaceableType(typeName, className, filename, customEnvironment)
	if not ClassUtil.getIsValidClassName(typeName) then
		print("Warning: Invalid placeable typeName: " .. tostring(typeName) .. ". Ignoring placeable!")

		return false
	elseif self.placeableTypes[typeName] ~= nil then
		print("Error: Placeable type '" .. tostring(typeName) .. "' already exists. Ignoriring it!")

		return false
	elseif className == nil then
		print("Error: No className specified for placeable type '" .. tostring(typeName) .. "'. Ignoriring it!")

		return false
	elseif filename == nil then
		print("Error: No filename specified for placeable type '" .. tostring(typeName) .. "'. Ignoriring it!")

		return false
	else
		source(filename, customEnvironment)

		local typeEntry = {
			name = typeName,
			className = className,
			filename = filename
		}

		if customEnvironment ~= "" then
			print("  Register placeable type: " .. tostring(typeName))
		end

		self.placeableTypes[typeName] = typeEntry
	end

	return true
end

function PlaceableTypeManager:getClassObjectByTypeName(typeName)
	if typeName ~= nil then
		local placeableType = self.placeableTypes[typeName]

		if placeableType ~= nil then
			return ClassUtil.getClassObject(placeableType.className)
		end
	end

	return nil
end

function PlaceableTypeManager:initPlaceableTypes()
	for name, typeEntry in pairs(self.placeableTypes) do
		local classObj = ClassUtil.getClassObject(typeEntry.className)

		if rawget(classObj, "initPlaceableType") then
			classObj.initPlaceableType()
		end
	end
end

g_placeableTypeManager = PlaceableTypeManager:new()
