local namesToFind = {}

function checkForNames(id)
	for _, name in ipairs(namesToFind) do
		if getName(id) == name or I3DUtil.hasNamedChildren(id, name) then
			log("Found name", id, getName(id))
			printCallstack()
		end
	end
end

local oldOnInGameMenuMenu = OnInGameMenuMenu
local loadedI3Ds = {}

function isValidNode(node)
	return getHasClassId(node, ClassIds.SHAPE) or getHasClassId(node, ClassIds.AUDIO_SOURCE) or getHasClassId(node, ClassIds.CAMERA) or getHasClassId(node, ClassIds.LIGHT_SOURCE) or getHasClassId(node, ClassIds.PARTICLE_SYSTEM) or getHasClassId(node, ClassIds.TRANSFORM_GROUP)
end

function OnInGameMenuMenu(...)
	oldOnInGameMenuMenu(...)
	log("Leak Check:")
	log("Items linked to rootNode:", getNumOfChildren(getRootNode()))

	for i = 0, getNumOfChildren(getRootNode()) - 1 do
		local child = getChildAt(getRootNode(), i)

		log("    -", child, getName(child), " | num children:", getNumOfChildren(child))
	end

	log("")
	log("Loaded but not deleted objects:")

	for id, trace in pairs(loadedI3Ds) do
		log("Id: ", id, "'", trace.name, "'")
		log(trace.trace)
	end
end

function addChildren(id, t, trace)
	for i = 0, getNumOfChildren(id) - 1 do
		local child = getChildAt(id, i)

		if isValidNode(child) then
			checkForNames(child)

			t[child] = {
				name = getName(id),
				trace = trace
			}
		end

		addChildren(child, t, trace)
	end
end

function removeChildren(id, t)
	for i = 0, getNumOfChildren(id) - 1 do
		local child = getChildAt(id, i)

		if isValidNode(child) then
			checkForNames(child)

			t[child] = nil
		end

		removeChildren(child, t)
	end
end

local oldClone = clone

function clone(...)
	local id = oldClone(...)
	local trace = debug.traceback()

	if isValidNode(id) then
		checkForNames(id)

		loadedI3Ds[id] = {
			name = getName(id),
			trace = trace
		}
	end

	addChildren(id, loadedI3Ds, trace)

	return id
end

local oldLoadI3DFile = loadI3DFile

function loadI3DFile(...)
	local id = oldLoadI3DFile(...)
	local trace = debug.traceback()

	if isValidNode(id) then
		checkForNames(id)

		loadedI3Ds[id] = {
			name = getName(id),
			trace = trace
		}
	end

	addChildren(id, loadedI3Ds, trace)

	return id
end

local oldDelete = delete

function delete(id, ...)
	if isValidNode(id) then
		checkForNames(id)
		removeChildren(id, loadedI3Ds)

		loadedI3Ds[id] = nil
	end

	oldDelete(id, ...)
end

local targets = {}
local count = 0
local oldStreamI3DFile = streamI3DFile

function streamI3DFile(filename, callbackFunc, target, params, ...)
	count = count + 1
	targets[count] = {
		target = target,
		callbackFunc = callbackFunc
	}

	table.insert(params, 1, count)
	oldStreamI3DFile(filename, "myCallback", nil, params, ...)
end

function myCallback(nodeId, arguments)
	if isValidNode(nodeId) then
		loadedI3Ds[nodeId] = {
			name = getName(nodeId),
			trace = debug.traceback()
		}
	end

	local data = targets[arguments[1]]

	table.remove(arguments, 1)
	data.target[data.callbackFunc](data.target, nodeId, arguments)
end

local oldUnlink = unlink

function unlink(id, ...)
	checkForNames(id)
	oldUnlink(id, ...)
end

local oldLink = link

function link(parent, id, ...)
	checkForNames(id)
	oldLink(parent, id, ...)
end
