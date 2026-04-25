LogManager = {}
local LogManager_mt = Class(LogManager, AbstractManager)

function LogManager:new(customMt)
	local self = AbstractManager:new(customMt or LogManager_mt)

	return self
end

function LogManager:xmlWarning(xmlFilename, warningMessage, ...)
	print(string.format("  Warning (%s): " .. warningMessage, xmlFilename, ...))
end

function LogManager:xmlError(xmlFilename, errorMessage, ...)
	print(string.format("  Error (%s): " .. errorMessage, xmlFilename, ...))
end

function LogManager:xmlInfo(xmlFilename, infoMessage, ...)
	print(string.format("  Info (%s): " .. infoMessage, xmlFilename, ...))
end

function LogManager:xmlDevWarning(xmlFilename, warningMessage, ...)
	if g_isDevelopmentVersion then
		print(string.format("  DevWarning (%s): " .. warningMessage, xmlFilename, ...))
	end
end

function LogManager:xmlDevError(xmlFilename, errorMessage, ...)
	if g_isDevelopmentVersion then
		print(string.format("  DevError (%s): " .. errorMessage, xmlFilename, ...))
	end
end

function LogManager:xmlDevInfo(xmlFilename, infoMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevInfo (%s): " .. infoMessage, xmlFilename, ...))
	end
end

function LogManager:warning(warningMessage, ...)
	print(string.format("  Warning: " .. warningMessage, ...))
end

function LogManager:error(errorMessage, ...)
	print(string.format("  Error: " .. errorMessage, ...))
end

function LogManager:info(infoMessage, ...)
	print(string.format("  Info: " .. infoMessage, ...))
end

function LogManager:devWarning(warningMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevWarning: " .. warningMessage, ...))
	end
end

function LogManager:devError(errorMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevError: " .. errorMessage, ...))
	end
end

function LogManager:devInfo(infoMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevInfo: " .. infoMessage, ...))
	end
end

g_logManager = LogManager:new()
