NightIllumination = {}
local NightIllumination_mt = Class(NightIllumination)

function NightIllumination:onCreate(id)
	g_currentMission:addNonUpdateable(NightIllumination:new(id))
end

function NightIllumination:new(id)
	local self = {}

	setmetatable(self, NightIllumination_mt)
	g_currentMission.environment:addWeatherChangeListener(self)

	self.id = id
	self.windowsId = 0
	self.lightsId = 0

	if getNumOfChildren(id) > 0 then
		self.windowsId = getChildAt(id, 0)
	end

	if getNumOfChildren(id) > 1 then
		self.lightsId = getChildAt(id, 1)
	end

	self.lightIntensity = Utils.getNoNil(getUserAttribute(self.id, "lightIntensity"), 1)

	if self.windowsId ~= 0 then
		setShaderParameter(self.windowsId, "lightControl", 0, 0, 0, 0, false)
	end

	if self.lightsId ~= 0 then
		setVisibility(self.lightsId, false)
	end

	return self
end

function NightIllumination:delete()
	if g_currentMission.environment ~= nil then
		g_currentMission.environment:removeWeatherChangeListener(self)
	end
end

function NightIllumination:weatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		local isLightNeeded = not g_currentMission.environment.isSunOn or not not g_currentMission.environment.weather:getIsRaining()

		if self.windowsId ~= 0 then
			if isLightNeeded then
				setShaderParameter(self.windowsId, "lightControl", self.lightIntensity, 0, 0, 0, false)
			else
				setShaderParameter(self.windowsId, "lightControl", 0, 0, 0, 0, false)
			end
		end

		if self.lightsId ~= 0 then
			setVisibility(self.lightsId, isLightNeeded)
		end
	end
end
