XMLUtil = {
	getXMLI18NValue = function (xmlFile, baseKey, func, name, defaultValue, customEnvironment, showWarning)
		local i18n = g_i18n

		if customEnvironment ~= nil then
			i18n = _G[customEnvironment].g_i18n
		end

		if name == nil or name == "" then
			name = ""
		else
			name = "." .. name
		end

		local defaultVal = func(xmlFile, baseKey .. ".en" .. name)

		if defaultVal == nil then
			defaultVal = func(xmlFile, baseKey .. name .. ".en")

			if defaultVal == nil then
				defaultVal = func(xmlFile, baseKey .. ".de" .. name)

				if defaultVal == nil then
					defaultVal = func(xmlFile, baseKey .. name .. ".de")

					if defaultVal == nil then
						local s = func(xmlFile, baseKey .. name)

						if s ~= nil then
							if type(s) == "string" and s:sub(1, 6) == "$l10n_" then
								defaultVal = i18n:getText(s:sub(7))
							else
								defaultVal = s
							end
						end

						if defaultVal == nil then
							defaultVal = defaultValue
						end
					end
				end
			end
		end

		if defaultVal == nil and (showWarning == nil or showWarning) then
			print("Error: loading xml I18N item, missing 'en' or global value of attribute '" .. baseKey .. name .. "'")

			return nil
		end

		local val = getXMLString(xmlFile, baseKey .. "." .. g_languageShort .. name)

		if val == nil then
			val = getXMLString(xmlFile, baseKey .. name .. "." .. g_languageShort)

			if val == nil then
				val = defaultVal
			end
		end

		return val
	end,
	checkDeprecatedXMLElements = function (xmlFile, xmlFilename, oldElement, newElement, oldValue)
		local found = false
		local extraWarning = ""

		if oldValue ~= nil then
			if getXMLString(xmlFile, oldElement) == oldValue then
				found = true
				extraWarning = string.format(" with value '%s'", oldValue)
			end
		elseif getXMLString(xmlFile, oldElement) ~= nil or hasXMLProperty(xmlFile, oldElement) and not oldElement:find("#") then
			found = true
		end

		if found then
			if newElement ~= nil then
				g_logManager:xmlWarning(xmlFilename, "'%s'%s is not supported anymore, use '%s' instead!", oldElement, extraWarning, newElement)
			else
				g_logManager:xmlWarning(xmlFilename, "'%s'%s is not supported anymore!", oldElement, extraWarning)
			end
		end
	end,
	getValueFromXMLFileOrUserAttribute = function (xmlFile, xmlNode, name, xmlFunc, node)
		local value = nil

		if type(node) == "number" then
			value = getUserAttribute(node, name)
		end

		if value == nil and xmlFile ~= nil then
			value = xmlFunc(xmlFile, xmlNode .. "#" .. name)
		end

		return value
	end,
	getXMLStringWithDefault = function (xmlFile, key, defkey, overridekey, attrname)
		local r = getXMLString(xmlFile, key .. "#" .. attrname)

		if not r and defkey then
			r = getXMLString(xmlFile, defkey .. "#" .. attrname)
		end

		if overridekey then
			r = getXMLString(xmlFile, overridekey .. "#" .. attrname) or r
		end

		return r
	end,
	getXMLIntWithDefault = function (xmlFile, key, defkey, overridekey, attrname)
		local r = getXMLInt(xmlFile, key .. "#" .. attrname)

		if not r and defkey then
			r = getXMLInt(xmlFile, defkey .. "#" .. attrname)
		end

		if overridekey then
			r = getXMLInt(xmlFile, overridekey .. "#" .. attrname) or r
		end

		return r
	end,
	getXMLFloatWithDefault = function (xmlFile, key, defkey, overridekey, attrname)
		local r = getXMLFloat(xmlFile, key .. "#" .. attrname)

		if not r and defkey then
			r = getXMLFloat(xmlFile, defkey .. "#" .. attrname)
		end

		if overridekey then
			r = getXMLFloat(xmlFile, overridekey .. "#" .. attrname) or r
		end

		return r
	end,
	getXMLOverwrittenValue = function (xmlFile, key, subKey, param, xmlFunc, fallbackValue, valueFunc, ...)
		local value = nil

		if key ~= nil then
			if getXMLString(xmlFile, key .. subKey) == "-" then
				return nil
			end

			value = xmlFunc(xmlFile, key .. subKey .. param)

			if valueFunc ~= nil and value ~= nil then
				value = valueFunc(value, unpack(arg or {}))
			end
		end

		return Utils.getNoNil(value, fallbackValue)
	end,
	loadDataFromMapXML = function (mapXMLFile, xmlKey, baseDirectory, loadTarget, loadFunc, ...)
		local filename = getXMLString(mapXMLFile, string.format("map.%s#filename", xmlKey))
		local xmlFile = mapXMLFile

		if filename ~= nil then
			local xmlFilename = Utils.getFilename(filename, baseDirectory)
			xmlFile = loadXMLFile("mapDataXML", xmlFilename)
		end

		local success = loadFunc(loadTarget, xmlFile, ...)

		if xmlFile ~= mapXMLFile then
			delete(xmlFile)
		end

		return success
	end
}
