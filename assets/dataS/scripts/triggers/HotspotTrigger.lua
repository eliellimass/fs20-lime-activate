HotspotTrigger = {}
local HotspotTrigger_mt = Class(HotspotTrigger)

function HotspotTrigger:onCreate(id)
	g_currentMission:addUpdateable(HotspotTrigger:new(id))
end

function HotspotTrigger:new(name)
	local self = {}

	setmetatable(self, HotspotTrigger_mt)

	self.triggerId = name

	addTrigger(name, "triggerCallback", self)

	self.hotspotSymbol = getChildAt(name, 0)
	local x, _, z = getTranslation(name)
	local mapHotspot = MapHotspot:new(tostring(name), MapHotspot.CATEGORY_DEFAULT)

	mapHotspot:setIcon(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_HIGHLIGHT_MARKER, {
		0.2705,
		0.6514,
		0.0802,
		1
	}, nil, )
	mapHotspot:setWorldPosition(x, z)
	g_currentMission:addMapHotspot(mapHotspot)

	self.mapHotspot = mapHotspot
	self.distanceToPlayer = 0
	self.isEnabled = true

	return self
end

function HotspotTrigger:delete()
	removeTrigger(self.triggerId)
	g_currentMission:removeMapHotspot(self.mapHotspot)
	self.mapHotspot:delete()
end

function HotspotTrigger:update(dt)
	rotate(self.hotspotSymbol, 0, 0.005 * dt, 0)
end

function HotspotTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and self.isEnabled and g_currentMission.controlledVehicle ~= nil and otherId == g_currentMission.controlledVehicle.components[1].node then
		if g_currentMission.hotspotSound ~= nil then
			playSample(g_currentMission.hotspotSound, 1, 1, 0, 0, 0)
		end

		g_currentMission:hotspotTouched(triggerId)
		self.mapHotspot:setVisible(false)

		self.mapHotspot.enabled = false
		self.isEnabled = false

		setVisibility(self.triggerId, false)
	end
end
