I18N = {}
local I18N_mt = Class(I18N)
I18N.MONEY_MAX_DISPLAY_VALUE = 999999999
I18N.MONEY_MIN_DISPLAY_VALUE = -999999999

function I18N:new()
	local self = {}

	setmetatable(self, I18N_mt)

	self.texts = {}
	self.modEnvironments = {}

	if g_addTestCommands then
		addConsoleCommand("gsVerifyI18N", "", "consoleCommandVerifyAll", self)
	end

	return self
end

function I18N:load()
	self.texts = {}
	local xmlFile = loadXMLFile("TempConfig", "dataS/l10n" .. g_languageSuffix .. ".xml")

	self:loadEntriesFromXML(xmlFile, "l10n.elements.e(%d)", "Warning: duplicate text in l10n" .. g_languageSuffix .. ".xml. Ignoring previous definition of %s.", self.texts)

	self.fluidFactor = Utils.getNoNil(getXMLFloat(xmlFile, "l10n.fluid#factor"), 1)
	self.powerFactorHP = Utils.getNoNil(getXMLFloat(xmlFile, "l10n.power#factor"), 1)
	self.powerFactorKW = 0.735499
	self.moneyUnit = GS_MONEY_EURO
	self.useMiles = false
	self.useFahrenheit = false
	self.useAcre = false

	if g_gameSettings ~= nil then
		self.moneyUnit = g_gameSettings:getValue("moneyUnit")
		self.useMiles = g_gameSettings:getValue("useMiles")
	end

	delete(xmlFile)
end

function I18N:loadEntriesFromXML(xmlFile, keyFormat, duplicateWarningFormat, outputEntries)
	local textI = 0

	while true do
		local key = string.format(keyFormat, textI)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#k")
		local text = getXMLString(xmlFile, key .. "#v")

		if name ~= nil and text ~= nil then
			if outputEntries[name] ~= nil then
				print(string.format(duplicateWarningFormat, name))
			end

			outputEntries[name] = text:gsub("\r\n", "\n")
		end

		textI = textI + 1
	end
end

function I18N:addModI18N(modName)
	local modi18n = {
		texts = {}
	}

	setmetatable(modi18n, {
		__index = self
	})
	setmetatable(modi18n.texts, {
		__index = self.texts
	})

	self.modEnvironments[modName] = modi18n

	function modi18n:setText(name, value)
		self.texts[name] = value
	end

	function modi18n:hasModText(name)
		return self.texts[name] ~= nil
	end

	return modi18n
end

function I18N:getText(name, customEnv)
	local ret = nil

	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]

		if modEnv ~= nil then
			ret = I18N.getPlatformText(modEnv, name)
		end
	end

	if ret == nil then
		ret = I18N.getPlatformText(self, name)

		if ret == nil then
			ret = string.format("Missing '%s' in l10n%s.xml", name, g_languageSuffix)

			if g_showDevelopmentWarnings then
				g_logManager:devWarning(ret)
			end
		end
	end

	return ret
end

function I18N.getPlatformText(env, name)
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		return env.texts[name .. "_ps4"] or env.texts[name]
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_XBOXONE then
		return env.texts[name .. "_xboxone"] or env.texts[name]
	elseif GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH then
		return env.texts[name .. "_switch"] or env.texts[name .. "_mobile"] or env.texts[name]
	elseif GS_IS_MOBILE_VERSION then
		return env.texts[name .. "_mobile"] or env.texts[name]
	else
		return env.texts[name]
	end
end

function I18N:hasText(name, customEnv)
	local ret = nil

	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]

		if modEnv ~= nil then
			ret = I18N.getPlatformText(modEnv, name)
		end
	end

	if ret == nil then
		ret = I18N.getPlatformText(self, name)
	end

	return ret ~= nil
end

function I18N:setText(name, value)
	self.texts[name] = value
end

function I18N:setMoneyUnit(unit)
	self.moneyUnit = unit
end

function I18N:setUseMiles(useMiles)
	self.useMiles = useMiles
end

function I18N:setUseFahrenheit(useFahrenheit)
	self.useFahrenheit = useFahrenheit
end

function I18N:setUseAcre(useAcre)
	self.useAcre = useAcre
end

function I18N:getCurrency(currency)
	return currency * self:getCurrencyFactor()
end

function I18N:getCurrencyFactor()
	if self.moneyUnit == GS_MONEY_EURO then
		return 1
	elseif self.moneyUnit == GS_MONEY_POUND then
		return 0.79
	else
		return 1.34
	end
end

function I18N:getMeasuringUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useMiles then
		return self.texts["unit_miles" .. postfix]
	end

	return self.texts["unit_km" .. postfix]
end

function I18N:getVolumeUnit(useLongName)
	local postfix = not useLongName and "Short" or ""

	return self.texts["unit_liter" .. postfix]
end

function I18N:getVolume(liters)
	return liters
end

function I18N:getSpeedMeasuringUnit()
	if self.useMiles then
		return self.texts.unit_mph
	end

	return self.texts.unit_kmh
end

function I18N:getSpeed(speed)
	if self.useMiles then
		return speed * 0.62137
	end

	return speed
end

function I18N:getTemperature(temperature)
	if self.useFahrenheit then
		return temperature * 1.8 + 32
	end

	return temperature
end

function I18N:formatTemperature(temperatureCelsius, precision, useLongName)
	local temperature = self:getTemperature(temperatureCelsius)
	local str = self:getTemperatureUnit(useLongName)

	return string.format("%1." .. (precision or 0) .. "f %s", temperature, str)
end

function I18N:getTemperatureUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useFahrenheit then
		return self.texts["unit_fahrenheit" .. postfix]
	end

	return self.texts["unit_celsius" .. postfix]
end

function I18N:getAreaUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useAcre then
		return self.texts["unit_acre" .. postfix]
	end

	return self.texts["unit_ha" .. postfix]
end

function I18N:getArea(ha)
	if self.useAcre then
		return ha * 2.4711
	end

	return ha
end

function I18N:formatArea(areaInHa, precision, useLongName)
	local area = self:getArea(areaInHa)
	local str = self:getAreaUnit(useLongName)

	return string.format("%1." .. (precision or 0) .. "f %s", area, str)
end

function I18N:getDistance(distance)
	if self.useMiles then
		return distance * 0.62137
	end

	return distance
end

function I18N:getFluid(fluid)
	return fluid * self.fluidFactor
end

function I18N:formatFluid(liters)
	return string.format("%u %s", self:getFluid(liters), g_i18n:getText("unit_literShort"))
end

function I18N:formatVolume(liters, precision)
	return string.format("%s %s", self:formatNumber(self:getVolume(liters), precision), self:getVolumeUnit())
end

function I18N:getPower(power)
	return power * self.powerFactorHP, power * self.powerFactorKW
end

function I18N:formatNumber(number, precision, forcePrecision)
	if number == nil then
		g_logManager:error("Invalid value for I18N:formatNumber")
		printCallstack()

		number = 0
	end

	local currencyString = ""

	if precision == nil then
		precision = 0
	end

	if precision == 0 then
		number = math.floor(number)
	end

	local baseString = string.format("%1." .. precision .. "f", number)

	if baseString == "-0" then
		baseString = "0"
	end

	local groupingChar = self:getText("unit_digitGroupingSymbol")

	if groupingChar ~= " " and groupingChar ~= "." and groupingChar ~= "," then
		groupingChar = " "
	end

	local prefix, num, decimal = string.match(baseString, "^([^%d]*%d)(%d*)[.]?(%d*)")
	currencyString = prefix .. num:reverse():gsub("(%d%d%d)", "%1" .. groupingChar):reverse()
	local prec = decimal:len()

	if prec > 0 and (decimal ~= string.rep("0", prec) or forcePrecision) then
		currencyString = currencyString .. self:getDecimalSeparator() .. decimal:sub(1, precision)
	end

	return currencyString
end

function I18N:formatMoney(number, precision, addCurrency, prefixCurrencySymbol)
	if number == nil then
		g_logManager:error("Invalid value for I18N:formatMoney")
		printCallstack()

		number = 0
	end

	local clampedDisplayMoney = MathUtil.clamp(number, I18N.MONEY_MIN_DISPLAY_VALUE, I18N.MONEY_MAX_DISPLAY_VALUE)
	local currencyString = self:formatNumber(clampedDisplayMoney, precision)

	if addCurrency == nil or addCurrency then
		if prefixCurrencySymbol == nil or not prefixCurrencySymbol then
			currencyString = currencyString .. " " .. self:getCurrencySymbol(true)
		else
			currencyString = self:getCurrencySymbol(true) .. " " .. currencyString
		end
	end

	return currencyString
end

function I18N:getDecimalSeparator()
	return Utils.getNoNil(self:getText("unit_decimalSymbol"), ".")
end

function I18N:getCurrencySymbol(useShort)
	local postFix = ""

	if useShort then
		postFix = "Short"
	end

	if g_buildTypeParam == "CHINA_GAPP" then
		return self:getText("unit_coins" .. postFix)
	elseif self.moneyUnit == GS_MONEY_EURO then
		return self:getText("unit_euro" .. postFix)
	elseif self.moneyUnit == GS_MONEY_POUND then
		return self:getText("unit_pound" .. postFix)
	else
		return self:getText("unit_dollar" .. postFix)
	end
end

function I18N:convertText(text, customEnv)
	if text == nil then
		printCallstack()

		return nil
	end

	if text:sub(1, 6) == "$l10n_" then
		text = g_i18n:getText(text:sub(7), customEnv)
	end

	return text
end

function I18N:getCurrentDate()
	local dateString = ""

	if g_languageShort == "en" then
		dateString = getDate("%Y-%m-%d")
	elseif g_languageShort == "de" then
		dateString = getDate("%d.%m.%Y")
	elseif g_languageShort == "jp" then
		dateString = getDate("%Y/%m/%d")
	else
		dateString = getDate("%d/%m/%Y")
	end

	return dateString
end

function I18N:consoleCommandVerifyAll()
	print("Verifying i18n files:")

	local texts = {}
	local allNamesSet = {}
	local numL = getNumOfLanguages()

	for langIndex = 0, numL - 1 do
		local code = getLanguageCode(langIndex)
		local filenameShort = "l10n_" .. code .. ".xml"
		local xmlFilename = "dataS/" .. filenameShort

		if fileExists(xmlFilename) then
			local xmlFile = loadXMLFile("TempConfig", xmlFilename)
			local textsI = {}

			self:loadEntriesFromXML(xmlFile, "l10n.elements.e(%d)", "Warning: duplicate text in " .. filenameShort .. ". Ignoring previous definition of %s.", textsI)
			table.insert(texts, {
				filename = filenameShort,
				texts = textsI
			})

			for name, _ in pairs(textsI) do
				allNamesSet[name] = true
			end

			delete(xmlFile)
		end
	end

	for name, _ in pairs(allNamesSet) do
		for _, codeData in pairs(texts) do
			local text = codeData.texts[name]

			if text == nil then
				print(string.format("Warning: Missing text for %s in %s", name, codeData.filename))
			elseif StringUtil.trim(text) == "" or text:upper():find("TODO") then
				print(string.format("Warning: Empty or todo text for %s in %s", name, codeData.filename))
			end
		end
	end

	return "Verified all i18n files"
end

function I18N:formatMinutes(minutes)
	if minutes ~= nil then
		local hours = math.floor(minutes / 60)
		local mins = minutes - hours * 60

		return string.format(self:getText("ui_hours"), hours, mins)
	else
		return self:getText("ui_hours_none")
	end
end
