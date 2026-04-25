PlatformSettingsManager = {}
local PlatformSettingsManager_mt = Class(PlatformSettingsManager, AbstractManager)
PlatformSettingsManager.PLATFORM_SETTING_FILE = "dataS/platformSettings.xml"
PlatformSettingsManager.PLATFORM_ANY = "any"

function PlatformSettingsManager:new(customMt)
	self = AbstractManager:new(customMt or PlatformSettingsManager_mt)
	self.settings = {}

	self:loadSettingsFromFile(PlatformSettingsManager.PLATFORM_SETTING_FILE)

	return self
end

function PlatformSettingsManager:loadSettingsFromFile(xmlFilename)
	local xmlFile = loadXMLFile("TempSettings", xmlFilename)

	if xmlFile ~= nil then
		local i = 0

		while true do
			local baseKey = string.format("platformSettings.settings(%d)", i)

			if not hasXMLProperty(xmlFile, baseKey) then
				break
			end

			local platform = getXMLString(xmlFile, baseKey .. "#platform")

			if platform ~= nil then
				if self:getIsPlatformActive(platform) then
					local j = 0

					while true do
						local settingKey = string.format("%s.setting(%d)", baseKey, j)

						if not hasXMLProperty(xmlFile, settingKey) then
							break
						end

						local name = getXMLString(xmlFile, settingKey .. "#name")
						local value = getXMLString(xmlFile, settingKey .. "#value")
						local type = getXMLString(xmlFile, settingKey .. "#type")

						if name ~= nil and value ~= nil then
							if type == "number" then
								value = tonumber(value)
							elseif type == "boolean" then
								value = value:lower() == "true"
							elseif type == "vector" then
								value = {
									StringUtil.getVectorFromString(value)
								}
							elseif value == "" then
								value = nil
							end

							self.settings[name] = value
						end

						j = j + 1
					end
				end
			else
				g_logManager:warning("Unknown platform for platformSetting '%s'!", baseKey)
			end

			i = i + 1
		end

		return true
	end

	return false
end

function PlatformSettingsManager:getIsPlatformActive(platform)
	if platform ~= nil then
		if platform == PlatformSettingsManager.PLATFORM_ANY then
			return true
		end

		for _, subPlatform in pairs(StringUtil.splitString(" ", platform)) do
			if _G[subPlatform] == true then
				return true
			end

			if StringUtil.startsWith(subPlatform, "GS_PLATFORM_TYPE_") and GS_PLATFORM_TYPE == _G[subPlatform] then
				return true
			end
		end
	end

	return false
end

function PlatformSettingsManager:getSetting(name, default)
	return Utils.getNoNil(self.settings[name], default)
end

g_platformSettingsManager = PlatformSettingsManager:new()
