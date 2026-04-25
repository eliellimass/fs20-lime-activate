SpecializationManager = {}
local SpecializationManager_mt = Class(SpecializationManager, AbstractManager)

function SpecializationManager:new(customMt)
	local self = AbstractManager:new(customMt or SpecializationManager_mt)

	return self
end

function SpecializationManager:initDataStructures()
	self.specializations = {}
end

function SpecializationManager:loadMapData()
	SpecializationManager:superClass().loadMapData(self)

	local xmlFile = loadXMLFile("SpecializationsXML", "dataS/specializations.xml")
	local i = 0

	while true do
		local baseName = string.format("specializations.specialization(%d)", i)
		local typeName = getXMLString(xmlFile, baseName .. "#name")

		if typeName == nil then
			break
		end

		local className = getXMLString(xmlFile, baseName .. "#className")
		local filename = getXMLString(xmlFile, baseName .. "#filename")

		g_deferredLoadingManager:addSubtask(function ()
			self:addSpecialization(typeName, className, filename, "")
		end)

		i = i + 1
	end

	delete(xmlFile)
	g_deferredLoadingManager:addSubtask(function ()
		print("  Loaded specializations")
	end)

	return true
end

function SpecializationManager:addSpecialization(name, className, filename, customEnvironment)
	if self.specializations[name] ~= nil then
		print("Error: Specialization '" .. tostring(name) .. "' already exists. Ignoring it!")

		return false
	elseif className == nil then
		print("Error: No className specified for specialization '" .. tostring(name) .. "'")

		return false
	elseif filename == nil then
		print("Error: No filename specified for specialization '" .. tostring(name) .. "'")

		return false
	else
		local specialization = {
			name = name,
			className = className,
			filename = filename
		}

		source(filename, customEnvironment)

		self.specializations[name] = specialization
	end

	return true
end

function SpecializationManager:initSpecializations()
	for name, _ in pairs(self.specializations) do
		local specialization = self:getSpecializationObjectByName(name)

		if specialization ~= nil and specialization.initSpecialization ~= nil then
			specialization.initSpecialization()
		end
	end
end

function SpecializationManager:getSpecializationByName(name)
	if name ~= nil then
		return self.specializations[name]
	end

	return nil
end

function SpecializationManager:getSpecializationObjectByName(name)
	local entry = self.specializations[name]

	if entry == nil then
		return nil
	end

	return ClassUtil.getClassObject(entry.className)
end

function SpecializationManager:getSpecializations()
	return self.specializations
end

g_specializationManager = SpecializationManager:new()
