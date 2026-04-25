AnimationCache = {
	CHARACTER = "CHARACTER",
	PEDESTRIAN = "PEDESTRIAN"
}
local AnimationCache_mt = Class(AnimationCache)

function AnimationCache:new()
	local self = setmetatable({}, AnimationCache_mt)
	self.nameToFilename = {}
	self.nameToAnimationNode = {}
	self.loading = {}
	self.toBeDeleted = {}

	return self
end

function AnimationCache:load(name, filename)
	if self.nameToFilename[name] ~= nil then
		g_logManager:error("'%s' already exists in animation cache", name)

		return false
	end

	self.nameToFilename[name] = filename
	self.loading[name] = true

	streamI3DFile(filename, "loadFinished", self, {
		name,
		filename
	}, false, false, true)

	return true
end

function AnimationCache:loadFinished(node, arguments)
	local name, _ = unpack(arguments)
	self.loading[name] = nil

	if self.toBeDeleted[name] == nil then
		self.nameToAnimationNode[name] = node
	else
		delete(node)

		self.toBeDeleted[name] = nil
	end
end

function AnimationCache:getNode(name)
	return self.nameToAnimationNode[name]
end

function AnimationCache:isLoaded(name)
	return self.nameToAnimationNode[name] ~= nil
end

function AnimationCache:delete(name)
	local node = self.nameToAnimationNode[name]

	if node ~= nil then
		delete(node)
	elseif self.loading[name] then
		self.toBeDeleted[name] = true
	end
end
