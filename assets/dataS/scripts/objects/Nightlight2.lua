Nightlight2 = {}
local Nightlight2_mt = Class(Nightlight2)

function Nightlight2:onCreate(id)
	g_currentMission:addNonUpdateable(Nightlight2:new(id))
end

function Nightlight2:new(id)
	local self = {}

	setmetatable(self, Nightlight2_mt)

	self.id = id
	self.switchCollision = Utils.getNoNil(getUserAttribute(id, "switchCollision"), false)

	if self.switchCollision then
		self.collisionMask = getCollisionMask(id)
	end

	self:setVisibility(false)
	g_currentMission.environment:addWeatherChangeListener(self)

	return self
end

function Nightlight2:delete()
	if g_currentMission.environment ~= nil then
		g_currentMission.environment:removeWeatherChangeListener(self)
	end
end

function Nightlight2:setVisibility(visible)
	setVisibility(self.id, visible)

	if self.switchCollision then
		setCollisionMask(self.id, visible and self.collisionMask or 0)
	end
end

function Nightlight2:weatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		self:setVisibility(not g_currentMission.environment.isSunOn or not not g_currentMission.environment.weather:getIsRaining())
	end
end
