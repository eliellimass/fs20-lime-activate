Nightlight = {}
local Nightlight_mt = Class(Nightlight)

function Nightlight:onCreate(id)
	g_currentMission:addNonUpdateable(Nightlight:new(id))
end

function Nightlight:new(name)
	local instance = {}

	setmetatable(instance, Nightlight_mt)

	instance.init = false

	if getNumOfChildren(name) == 2 then
		instance.dayId = getChildAt(name, 0)
		instance.nightId = getChildAt(name, 1)
		instance.init = true
	end

	g_currentMission.environment:addWeatherChangeListener(instance)

	return instance
end

function Nightlight:delete()
	if g_currentMission.environment ~= nil then
		g_currentMission.environment:removeWeatherChangeListener(self)
	end
end

function Nightlight:weatherChanged()
	if self.init then
		setVisibility(self.dayId, g_currentMission.environment.isSunOn)
		setVisibility(self.nightId, not g_currentMission.environment.isSunOn)
	end
end
