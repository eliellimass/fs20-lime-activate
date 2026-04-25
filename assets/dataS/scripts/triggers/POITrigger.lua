POITrigger = {}
local POITrigger_mt = Class(POITrigger)

function POITrigger:onCreate(id)
	local poi = POITrigger:new()

	if poi:loadFromNode(id) then
		g_currentMission:addNonUpdateable(poi)
	else
		poi:delete()
	end
end

function POITrigger:new(customEnv)
	local self = setmetatable({}, POITrigger_mt)
	self.infoText = nil
	self.isEnabled = true
	self.customEnv = customEnv
	self.isPlayerInRange = false
	self.vehiclesInRange = {}

	return self
end

function POITrigger:loadFromXML(rootNode, xmlFile, xmlNode, customEnv)
	self.node = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, xmlNode .. "#node"))

	if self.node == nil then
		g_logManager:devWarning("Missing node for POITrigger '%s'", xmlNode)

		return false
	end

	local text = getXMLString(xmlFile, xmlNode .. "#text")

	if text ~= nil then
		self.infoText = g_i18n:convertText(text, self.customEnv)
	else
		g_logManager:devWarning("Missing text for POITrigger '%s'", getName(self.node))

		return false
	end

	self:finalize()

	return true
end

function POITrigger:loadFromNode(node)
	self.node = node
	local text = getUserAttribute(node, "text")

	if text ~= nil then
		self.infoText = g_i18n:convertText(text, self.customEnv)
	else
		g_logManager:devWarning("Missing text for POITrigger '%s'", getName(self.node))

		return false
	end

	self:finalize()

	return true
end

function POITrigger:finalize()
	if g_currentMission:getIsClient() then
		self.triggerId = self.node

		addTrigger(self.node, "triggerCallback", self)
	end
end

function POITrigger:delete()
	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)

		self.triggerId = nil
	end

	g_currentMission:removeDrawable(self)
end

function POITrigger:draw()
	if not self.isEnabled or self.infoText == nil then
		return
	end

	local needsDrawing = self.isPlayerInRange

	if not needsDrawing then
		for vehicle, _ in pairs(self.vehiclesInRange) do
			if vehicle == g_currentMission.controlledVehicle then
				needsDrawing = true

				break
			end
		end
	end

	if needsDrawing then
		g_currentMission.hud:drawPOIInfo(self.infoText)
	end
end

function POITrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local changed = false

		if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.isPlayerInRange = true
				changed = true
			else
				self.isPlayerInRange = false
				changed = true
			end
		else
			local vehicle = g_currentMission:getNodeObject(otherId)

			if vehicle ~= nil and vehicle:isa(Vehicle) then
				local count = Utils.getNoNil(self.vehiclesInRange[vehicle], 0)

				if onEnter then
					if self.vehiclesInRange[vehicle] == nil then
						changed = true
						self.vehiclesInRange[vehicle] = 0
					end

					self.vehiclesInRange[vehicle] = count + 1
				else
					self.vehiclesInRange[vehicle] = self.vehiclesInRange[vehicle] - 1

					if self.vehiclesInRange[vehicle] == 0 then
						self.vehiclesInRange[vehicle] = nil
						changed = true
					end
				end
			end
		end

		if changed then
			g_currentMission:removeDrawable(self)

			local hasVehicle = next(self.vehiclesInRange) ~= nil
			local needsDrawing = self.isPlayerInRange or hasVehicle

			if needsDrawing then
				g_currentMission:addDrawable(self)
			end
		end
	end
end
