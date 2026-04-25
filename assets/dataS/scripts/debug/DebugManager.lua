DebugManager = {}
local DebugManager_mt = Class(DebugManager, AbstractManager)

function DebugManager:new(customMt)
	local self = AbstractManager:new(customMt or DebugManager_mt)

	return self
end

function DebugManager:initDataStructures()
	self.permanentElements = {}
	self.frameElements = {}
end

function DebugManager:update(dt)
	for _, element in ipairs(self.permanentElements) do
		element:draw()
	end
end

function DebugManager:draw()
	for _, element in ipairs(self.permanentElements) do
		element:draw()
	end

	for i = #self.frameElements, 1, -1 do
		self.frameElements[i]:draw()
		table.remove(self.frameElements, i)
	end
end

function DebugManager:addPermanentElement(element)
	ListUtil.addElementToList(self.permanentElements, element)
end

function DebugManager:removePermanentElement(element)
	ListUtil.removeElementFromList(self.permanentElements, element)
end

function DebugManager:addFrameElement(element)
	ListUtil.addElementToList(self.frameElements, element)
end

g_debugManager = DebugManager:new()
