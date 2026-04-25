SpecializationUtil = {
	callSpecializationsFunction = function (func)
		return function (self, ...)
			for _, v in pairs(g_specializationManager:getSpecializations()) do
				local f = v[func]

				if f ~= nil then
					f(self, ...)
				end
			end
		end
	end,
	raiseEvent = function (vehicle, eventName, ...)
		assert(vehicle.eventListeners[eventName] ~= nil, "Error: Event '" .. tostring(eventName) .. "' is not registered for vehicleType '" .. tostring(vehicle.vehicleType.name) .. "'!")

		for _, spec in ipairs(vehicle.eventListeners[eventName]) do
			spec[eventName](vehicle, ...)
		end
	end,
	registerEvent = function (vehicleType, eventName)
		if vehicleType.functions[eventName] ~= nil or vehicleType.events[eventName] ~= nil or eventName == nil or eventName == "" then
			printCallstack()
		end

		assert(vehicleType.functions[eventName] == nil, "Error: Event '" .. tostring(eventName) .. "' already registered as function in vehicleType '" .. tostring(vehicleType.name) .. "'!")
		assert(vehicleType.events[eventName] == nil, "Error: Event '" .. tostring(eventName) .. "' already registered as event in vehicleType '" .. tostring(vehicleType.name) .. "'!")
		assert(eventName ~= nil and eventName ~= "", "Error: Event '" .. tostring(eventName) .. "' is 'nil' or empty!")

		vehicleType.events[eventName] = eventName
		vehicleType.eventListeners[eventName] = {}
	end,
	registerFunction = function (vehicleType, funcName, func)
		if vehicleType.functions[funcName] ~= nil or vehicleType.events[funcName] ~= nil or func == nil then
			printCallstack()
		end

		assert(vehicleType.functions[funcName] == nil, "Error: Function '" .. tostring(funcName) .. "' already registered as function in vehicleType '" .. tostring(vehicleType.name) .. "'!")
		assert(vehicleType.events[funcName] == nil, "Error: Function '" .. tostring(funcName) .. "' already registered as event in vehicleType '" .. tostring(vehicleType.name) .. "'!")
		assert(func ~= nil, "Error: Given reference for Function '" .. tostring(funcName) .. "' is 'nil'!")

		vehicleType.functions[funcName] = func
	end,
	registerOverwrittenFunction = function (vehicleType, funcName, func)
		assert(func ~= nil, "Error: Given reference for OverwrittenFunction '" .. tostring(funcName) .. "' is 'nil'!")

		if vehicleType.functions[funcName] ~= nil then
			vehicleType.functions[funcName] = Utils.overwrittenFunction(vehicleType.functions[funcName], func)
		end
	end,
	registerEventListener = function (vehicleType, eventName, spec)
		local className = ClassUtil.getClassName(spec)

		assert(vehicleType.eventListeners ~= nil, "Error: Invalid vehicle type for specialization '" .. tostring(className) .. "'!")

		if vehicleType.eventListeners[eventName] == nil then
			return
		end

		assert(spec[eventName] ~= nil, "Error: Event listener function '" .. tostring(eventName) .. "' not defined in specialization '" .. tostring(className) .. "'!")

		local found = false

		for _, registeredSpec in pairs(vehicleType.eventListeners[eventName]) do
			if registeredSpec == spec then
				found = true

				break
			end
		end

		assert(not found, "Error: Eventlistener for '" .. eventName .. "' already registered in specialization '" .. tostring(className) .. "'!")
		table.insert(vehicleType.eventListeners[eventName], spec)
	end,
	hasSpecialization = function (spec, specializations)
		for _, v in pairs(specializations) do
			if v == spec then
				return true
			end
		end

		return false
	end
}
