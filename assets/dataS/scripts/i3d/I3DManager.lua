I3DManager = {}
local I3DManager_mt = Class(I3DManager, AbstractManager)

function I3DManager:new(customMt)
	local self = AbstractManager:new(customMt or I3DManager_mt)

	return self
end

function I3DManager:initDataStructures()
	self.sharedI3DFiles = {}
	self.sharedI3DFilesPendingCallbacks = {}
end

function I3DManager:loadSharedI3DFile(filename, baseDir, callOnCreate, addToPhysics, verbose, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	callOnCreate = Utils.getNoNil(callOnCreate, false)
	addToPhysics = Utils.getNoNil(addToPhysics, false)
	local filename = Utils.getFilename(filename, baseDir)
	local sharedI3D = self.sharedI3DFiles[filename]
	verbose = true

	if asyncCallbackFunction ~= nil then
		if sharedI3D == nil then
			local callbacks = self.sharedI3DFilesPendingCallbacks[filename]

			if callbacks == nil then
				self.sharedI3DFilesPendingCallbacks[filename] = {}

				table.insert(self.sharedI3DFilesPendingCallbacks[filename], {
					callOnCreate,
					addToPhysics,
					asyncCallbackFunction,
					asyncCallbackObject,
					asyncCallbackArguments
				})
				streamI3DFile(filename, "loadSharedI3DFileFinished", self, {
					filename
				}, false, false, verbose)
			else
				table.insert(callbacks, {
					callOnCreate,
					addToPhysics,
					asyncCallbackFunction,
					asyncCallbackObject,
					asyncCallbackArguments
				})
			end
		else
			local id = 0

			if sharedI3D.nodeId == 0 then
				print("Error: failed to load i3d file '" .. filename .. "'")
			else
				id = clone(sharedI3D.nodeId, false, callOnCreate, addToPhysics)
			end

			sharedI3D.refCount = sharedI3D.refCount + 1

			asyncCallbackFunction(asyncCallbackObject, id, asyncCallbackArguments)
		end
	else
		if sharedI3D == nil then
			local nodeId = loadI3DFile(filename, false, false, verbose)
			sharedI3D = {
				refCount = 0,
				nodeId = nodeId
			}
			self.sharedI3DFiles[filename] = sharedI3D
		end

		local id = 0

		if sharedI3D.nodeId == 0 then
			print("Error: failed to load i3d file '" .. filename .. "'")
		else
			id = clone(sharedI3D.nodeId, false, callOnCreate, addToPhysics)
		end

		sharedI3D.refCount = sharedI3D.refCount + 1

		return id
	end
end

function I3DManager:loadSharedI3DFileFinished(nodeId, arguments)
	local filename = arguments[1]
	local callbacks = self.sharedI3DFilesPendingCallbacks[filename]
	local sharedI3D = {
		refCount = 0,
		nodeId = nodeId
	}
	self.sharedI3DFilesPendingCallbacks[filename] = nil
	self.sharedI3DFiles[filename] = sharedI3D

	if nodeId == 0 then
		print("Error: failed to load i3d file '" .. filename .. "'")
	end

	for _, callback in pairs(callbacks) do
		local callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(callback)
		local id = 0

		if sharedI3D.nodeId ~= 0 then
			id = clone(sharedI3D.nodeId, false, callOnCreate, addToPhysics)
		end

		sharedI3D.refCount = sharedI3D.refCount + 1

		asyncCallbackFunction(asyncCallbackObject, id, asyncCallbackArguments)
	end
end

function I3DManager:fillSharedI3DFileCache(filename, baseDir)
	local filename = Utils.getFilename(filename, baseDir)
	local sharedI3D = self.sharedI3DFiles[filename]

	if sharedI3D == nil then
		local nodeId = loadI3DFile(filename, false, false)
		local sharedI3D = {
			refCount = 0,
			nodeId = nodeId
		}
		self.sharedI3DFiles[filename] = sharedI3D
	end
end

function I3DManager:releaseSharedI3DFile(filename, baseDir, autoDelete)
	local filename = Utils.getFilename(filename, baseDir)
	local sharedI3D = self.sharedI3DFiles[filename]

	if sharedI3D ~= nil then
		sharedI3D.refCount = sharedI3D.refCount - 1

		if autoDelete and sharedI3D.refCount <= 0 then
			if sharedI3D.nodeId ~= 0 then
				delete(sharedI3D.nodeId)
			end

			self.sharedI3DFiles[filename] = nil
		end
	end
end

function I3DManager:deleteSharedI3DFiles()
	for _, sharedI3D in pairs(self.sharedI3DFiles) do
		if sharedI3D.nodeId ~= 0 then
			delete(sharedI3D.nodeId)
		end
	end

	self.sharedI3DFiles = {}
end

g_i3DManager = I3DManager:new()
