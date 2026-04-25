VehicleTypeManager = {}
local VehicleTypeManager_mt = Class(VehicleTypeManager, AbstractManager)

function VehicleTypeManager:new(customMt)
	local self = AbstractManager:new(customMt or VehicleTypeManager_mt)

	return self
end

function VehicleTypeManager:initDataStructures()
	self.vehicleTypes = {}
end

function VehicleTypeManager:loadMapData()
	VehicleTypeManager:superClass().loadMapData(self)

	local xmlFile = loadXMLFile("VehicleTypesXML", "dataS/vehicleTypes.xml")
	local i = 0

	while true do
		local key = string.format("vehicleTypes.type(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		g_deferredLoadingManager:addSubtask(function ()
			self:loadVehicleTypeFromXML(xmlFile, key, nil, , )
		end)

		i = i + 1
	end

	g_deferredLoadingManager:addSubtask(function ()
		delete(xmlFile)
	end)
	g_deferredLoadingManager:addSubtask(function ()
		print("  Loaded vehicle types")
	end)

	return true
end

function VehicleTypeManager:addVehicleType(typeName, className, filename, customEnvironment)
	if self.vehicleTypes[typeName] ~= nil then
		print("Error: vehicle types multiple specifications of type '" .. typeName .. "'")

		return false
	elseif className == nil then
		print("Error: Vehicle types no className specified for '" .. typeName .. "'")

		return false
	elseif filename == nil then
		print("Error: Vehicle types no filename specified for '" .. typeName .. "'")

		return false
	else
		customEnvironment = customEnvironment or ""

		source(filename, customEnvironment)

		local typeEntry = {
			name = typeName,
			className = className,
			filename = filename,
			specializations = {},
			specializationNames = {},
			specializationsByName = {},
			functions = {},
			events = {},
			eventListeners = {},
			customEnvironment = customEnvironment
		}
		self.vehicleTypes[typeName] = typeEntry
	end

	return true
end

function VehicleTypeManager:removeVehicleType(typeName)
	self.vehicleTypes[typeName] = nil
end

function VehicleTypeManager:loadVehicleTypeFromXML(xmlFile, key, isDLC, modDir, modName)
	local typeName = getXMLString(xmlFile, key .. "#name")
	local parentName = getXMLString(xmlFile, key .. "#parent")

	if typeName == nil and parentName == nil then
		g_logManager:error("Missing name or parent for vehicleType '%s'", key)

		return false
	end

	local parent = nil

	if parentName ~= nil then
		parent = self.vehicleTypes[parentName]

		if parent == nil then
			g_logManager:error("Parent vehicle type '%s' is not defined!", parentName)

			return false
		end
	end

	local className = getXMLString(xmlFile, key .. "#className")
	local filename = getXMLString(xmlFile, key .. "#filename")

	if parent ~= nil then
		className = className or parent.className
		filename = filename or parent.filename
	end

	if modName ~= nil and modName ~= "" then
		typeName = modName .. "." .. typeName
	end

	if className ~= nil and filename ~= nil then
		local customEnvironment = nil

		if modDir ~= nil then
			local useModDirectory = true
			filename, useModDirectory = Utils.getFilename(filename, modDir)

			if useModDirectory then
				customEnvironment = modName
				className = modName .. "." .. className
			end
		end

		if not GS_IS_CONSOLE_VERSION or isDLC or customEnvironment == nil then
			self:addVehicleType(typeName, className, filename, customEnvironment)

			if parent ~= nil then
				for _, specName in ipairs(parent.specializationNames) do
					self:addSpecialization(typeName, specName)
				end
			end

			local j = 0

			while true do
				local specKey = string.format("%s.specialization(%d)", key, j)

				if not hasXMLProperty(xmlFile, specKey) then
					break
				end

				local specName = getXMLString(xmlFile, specKey .. "#name")
				local entry = g_specializationManager:getSpecializationByName(specName)

				if entry == nil then
					specName = modName .. "." .. specName
				end

				if specName ~= nil then
					self:addSpecialization(typeName, specName)
				end

				j = j + 1
			end

			return true
		else
			g_logManager:error("Can't register vehicle type '%s' with scripts on consoles.", typeName)
		end
	end

	return false
end

function VehicleTypeManager:addSpecialization(typeName, specName)
	local typeEntry = self.vehicleTypes[typeName]

	if typeEntry ~= nil then
		if typeEntry.specializationsByName[specName] == nil then
			local spec = g_specializationManager:getSpecializationObjectByName(specName)

			if spec == nil then
				print("Error: Vehicle type '" .. tostring(typeName) .. "' has unknown specialization '" .. tostring(specName) .. "'!")

				return false
			end

			table.insert(typeEntry.specializations, spec)
			table.insert(typeEntry.specializationNames, specName)

			typeEntry.specializationsByName[specName] = spec
		else
			g_logManager:error("Specialization '%s' already exists for vehicle type '%s'!", specName, typeName)
		end
	else
		g_logManager:error("VehicleType '%s' is not defined!", typeName)
	end
end

function VehicleTypeManager:validateVehicleTypes()
	for typeName, typeEntry in pairs(self.vehicleTypes) do
		g_deferredLoadingManager:addSubtask(function ()
			for _, specName in ipairs(typeEntry.specializationNames) do
				local spec = typeEntry.specializationsByName[specName]

				if not spec.prerequisitesPresent(typeEntry.specializations) then
					print("Error: Not all prerequisites of specialization " .. specName .. " are fulfilled")
					self:removeVehicleType(typeName)
				end
			end
		end)
	end
end

function VehicleTypeManager:finalizeVehicleTypes()
	for typeName, typeEntry in pairs(self.vehicleTypes) do
		g_deferredLoadingManager:addSubtask(function ()
			local classObject = ClassUtil.getClassObject(typeEntry.className)

			if classObject.registerEvents ~= nil then
				classObject.registerEvents(typeEntry)
			end

			if classObject.registerFunctions ~= nil then
				classObject.registerFunctions(typeEntry)
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEvents ~= nil then
					specialization.registerEvents(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerFunctions ~= nil then
					specialization.registerFunctions(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerOverwrittenFunctions ~= nil then
					specialization.registerOverwrittenFunctions(typeEntry)
				end
			end

			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEventListeners ~= nil then
					specialization.registerEventListeners(typeEntry)
				end
			end

			if typeEntry.customEnvironment ~= "" then
				print("  Register vehicle type: " .. typeName)
			end
		end)
	end

	return true
end

function VehicleTypeManager:getVehicleTypes()
	return self.vehicleTypes
end

function VehicleTypeManager:getVehicleTypeByName(typeName)
	if typeName ~= nil then
		return self.vehicleTypes[typeName]
	end
end

g_vehicleTypeManager = VehicleTypeManager:new()
