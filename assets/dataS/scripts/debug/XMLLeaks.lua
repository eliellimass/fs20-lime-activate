openXMLFiles = {}
local oldOpen = loadXMLFile

function loadXMLFile(name, filename, ...)
	local id = oldOpen(name, filename, ...)
	openXMLFiles[id] = {
		filename = filename,
		trace = debug.traceback()
	}

	return id
end

local oldLoadFromMemory = loadXMLFileFromMemory

function loadXMLFileFromMemory(...)
	local id = oldLoadFromMemory(...)
	openXMLFiles[id] = {
		filename = "From Memory",
		trace = debug.traceback()
	}

	return id
end

local oldDelete = delete

function delete(id, ...)
	oldDelete(id, ...)

	openXMLFiles[id] = nil
end

local oldDoExit = doExit

function doExit()
	log("Open XML-Files")

	for id, data in pairs(openXMLFiles) do
		log(id, data.filename)
		log(data.trace)
	end

	oldDoExit()
end
