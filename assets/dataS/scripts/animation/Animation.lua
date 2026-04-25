Animation = {}
local Animation_mt = Class(Animation)

function Animation:new(customMt)
	local self = setmetatable({}, customMt or Animation_mt)

	return self
end

function Animation:delete()
end

function Animation:update(dt)
end

function Animation:isRunning()
	return false
end

function Animation:start()
	return false
end

function Animation:stop()
	return false
end

function Animation:reset()
end

function Animation:setFillType(fillTypeIndex)
end
