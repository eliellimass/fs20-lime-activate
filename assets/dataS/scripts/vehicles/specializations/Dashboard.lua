Dashboard = {
	TYPES = {}
}
Dashboard.TYPES.EMITTER = 0
Dashboard.TYPES.NUMBER = 1
Dashboard.TYPES.ANIMATION = 2
Dashboard.TYPES.ROT = 3
Dashboard.TYPES.VISIBILITY = 4
Dashboard.COLORS = {
	GREY = {
		0.3,
		0.3,
		0.3,
		1
	},
	BLACK = {
		0.05,
		0.05,
		0.05,
		1
	},
	LIGHT_GREEN = {
		0.05,
		0.15,
		0.05,
		1
	},
	RED = {
		1,
		0,
		0,
		1
	},
	GREEN = {
		0,
		1,
		0,
		1
	},
	YELLOW = {
		1,
		1,
		0,
		1
	},
	ORANGE = {
		1,
		0.5,
		0,
		1
	}
}

function Dashboard.prerequisitesPresent(specializations)
	return true
end

function Dashboard.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateDashboards", Dashboard.updateDashboards)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardGroupFromXML", Dashboard.loadDashboardGroupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDashboardGroupActive", Dashboard.getIsDashboardGroupActive)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardGroupByName", Dashboard.getDashboardGroupByName)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardsFromXML", Dashboard.loadDashboardsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDashboardFromXML", Dashboard.loadDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadEmitterDashboardFromXML", Dashboard.loadEmitterDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadNumberDashboardFromXML", Dashboard.loadNumberDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimationDashboardFromXML", Dashboard.loadAnimationDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadRotationDashboardFromXML", Dashboard.loadRotationDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadVisibilityDashboardFromXML", Dashboard.loadVisibilityDashboardFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setDashboardsDirty", Dashboard.setDashboardsDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardValue", Dashboard.getDashboardValue)
	SpecializationUtil.registerFunction(vehicleType, "getDashboardColor", Dashboard.getDashboardColor)
end

function Dashboard.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Dashboard)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Dashboard)
end

function Dashboard:onLoad(savegame)
	local spec = self.spec_dashboard
	spec.dashboards = {}
	spec.criticalDashboards = {}
	spec.groups = {}
	local i = 0

	while true do
		local baseKey = string.format("%s.groups.group(%d)", "vehicle.dashboard", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local group = {}

		if self:loadDashboardGroupFromXML(self.xmlFile, baseKey, group) then
			spec.groups[group.name] = group
		end

		i = i + 1
	end

	spec.isDirty = false

	self:loadDashboardsFromXML(self.xmlFile, "vehicle.dashboard.default", {})
end

function Dashboard:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard

		self:updateDashboards(spec.criticalDashboards, dt)

		if spec.isDirty then
			self:raiseActive()
		end
	end
end

function Dashboard:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_dashboard
		local groupChanged = false

		for _, group in pairs(spec.groups) do
			if self:getIsDashboardGroupActive(group) ~= group.isActive then
				group.isActive = not group.isActive
				groupChanged = true
			end
		end

		if groupChanged then
			self:updateDashboards(spec.dashboards, dt, true)
			self:updateDashboards(spec.criticalDashboards, dt, true)
		else
			self:updateDashboards(spec.dashboards, dt)
		end

		spec.isDirty = false
	end
end

function Dashboard:updateDashboards(dashboards, dt, force)
	for _, dashboard in ipairs(dashboards) do
		local isActive = true

		for _, group in ipairs(dashboard.groups) do
			if not group.isActive then
				isActive = false

				break
			end
		end

		if dashboard.valueObject ~= nil and dashboard.valueFunc ~= nil then
			local value = self:getDashboardValue(dashboard.valueObject, dashboard.valueFunc, dashboard)

			if not isActive then
				value = dashboard.idleValue
			end

			if dashboard.doInterpolation and type(value) == "number" and value ~= dashboard.lastInterpolationValue then
				local dir = MathUtil.sign(value - dashboard.lastInterpolationValue)
				local limitFunc = math.min

				if dir < 0 then
					limitFunc = math.max
				end

				value = limitFunc(dashboard.lastInterpolationValue + dashboard.interpolationSpeed * dir * dt, value)
				dashboard.lastInterpolationValue = value
			end

			if value ~= dashboard.lastValue or force then
				dashboard.lastValue = value
				local min = self:getDashboardValue(dashboard.valueObject, dashboard.minFunc, dashboard)

				if min ~= nil then
					value = math.max(min, value)
				end

				local max = self:getDashboardValue(dashboard.valueObject, dashboard.maxFunc, dashboard)

				if max ~= nil then
					value = math.min(max, value)
				end

				local center = self:getDashboardValue(dashboard.valueObject, dashboard.centerFunc, dashboard)

				if center ~= nil then
					local maxValue = math.max(math.abs(min), math.abs(max))

					if value < center then
						value = -value / min * maxValue
					elseif center < value then
						value = value / max * maxValue
					end

					max = maxValue
					min = -maxValue
				end

				if dashboard.valueCompare ~= nil then
					if type(dashboard.valueCompare) == "table" then
						local oldValue = value
						value = false

						for _, compareValue in ipairs(dashboard.valueCompare) do
							if oldValue == compareValue then
								value = true
							end
						end
					else
						value = value == dashboard.valueCompare
					end
				end

				dashboard.stateFunc(self, dashboard, value, min, max, isActive)
			end
		elseif force then
			dashboard.stateFunc(self, dashboard, true, nil, , isActive)
		end
	end
end

function Dashboard:loadDashboardGroupFromXML(xmlFile, key, group)
	group.name = getXMLString(xmlFile, key .. "#name")

	if group.name == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing name for dashboard group '%s'", key)

		return false
	end

	if self:getDashboardGroupByName(group.name) ~= nil then
		g_logManager:xmlWarning(self.configFileName, "Duplicated dashboard group name '%s' for group '%s'", group.name, key)

		return false
	end

	group.isActive = false

	return true
end

function Dashboard:getIsDashboardGroupActive(group)
	return true
end

function Dashboard:getDashboardGroupByName(name)
	return self.spec_dashboard.groups[name]
end

function Dashboard:loadDashboardsFromXML(xmlFile, key, dashboardData)
	if self.isClient then
		local spec = self.spec_dashboard
		local i = 0

		while true do
			local baseKey = string.format("%s.dashboard(%d)", key, i)

			if not hasXMLProperty(xmlFile, baseKey) then
				break
			end

			local dashboard = {}

			if self:loadDashboardFromXML(xmlFile, baseKey, dashboard, dashboardData) then
				if dashboard.displayTypeIndex ~= Dashboard.TYPES.ROT then
					table.insert(spec.dashboards, dashboard)
				else
					table.insert(spec.criticalDashboards, dashboard)
				end
			end

			i = i + 1
		end
	end

	return true
end

function Dashboard:loadDashboardFromXML(xmlFile, key, dashboard, dashboardData)
	local valueType = getXMLString(xmlFile, key .. "#valueType")

	if valueType ~= nil then
		if valueType ~= dashboardData.valueTypeToLoad then
			return false
		end
	elseif dashboardData.valueTypeToLoad ~= nil then
		g_logManager:xmlWarning(self.configFileName, "Missing valueType for dashboard '%s'", key)

		return false
	end

	local displayType = getXMLString(xmlFile, key .. "#displayType")

	if displayType ~= nil then
		local displayTypeIndex = Dashboard.TYPES[displayType:upper()]

		if displayTypeIndex ~= nil then
			dashboard.displayTypeIndex = displayTypeIndex
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown displayType '%s' for dashboard '%s'", displayType, key)

			return false
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Missing displayType for dashboard '%s'", key)

		return false
	end

	dashboard.doInterpolation = Utils.getNoNil(getXMLBool(xmlFile, key .. "#doInterpolation"), false)
	dashboard.interpolationSpeed = getXMLFloat(xmlFile, key .. "#interpolationSpeed") or 0.005
	dashboard.idleValue = getXMLFloat(xmlFile, key .. "#idleValue") or dashboardData.idleValue or 0
	dashboard.lastInterpolationValue = 0
	dashboard.groups = {}
	local groupsStr = getXMLString(xmlFile, key .. "#groups")
	local groups = StringUtil.splitString(" ", groupsStr)

	for _, name in ipairs(groups) do
		local group = self:getDashboardGroupByName(name)

		if group ~= nil then
			table.insert(dashboard.groups, group)
		else
			g_logManager:xmlWarning(self.configFileName, "Unable to find dashboard group '%s' for dashboard '%s'", name, key)
		end
	end

	if dashboard.displayTypeIndex == Dashboard.TYPES.EMITTER then
		if not self:loadEmitterDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.NUMBER then
		if not self:loadNumberDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ANIMATION then
		if not self:loadAnimationDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ROT then
		if not self:loadRotationDashboardFromXML(xmlFile, key, dashboard) then
			return false
		end
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.VISIBILITY and not self:loadVisibilityDashboardFromXML(xmlFile, key, dashboard) then
		return false
	end

	if dashboardData.additionalAttributesFunc ~= nil and not dashboardData.additionalAttributesFunc(self, xmlFile, key, dashboard) then
		return false
	end

	dashboard.valueObject = dashboardData.valueObject
	dashboard.valueFunc = dashboardData.valueFunc
	dashboard.valueCompare = dashboardData.valueCompare
	dashboard.minFunc = dashboardData.minFunc
	dashboard.maxFunc = dashboardData.maxFunc
	dashboard.centerFunc = dashboardData.centerFunc
	dashboard.stateFunc = dashboardData.stateFunc or Dashboard.defaultDashboardStateFunc
	dashboard.lastValue = 0

	return true
end

function Dashboard:loadEmitterDashboardFromXML(xmlFile, key, dashboard)
	local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if node ~= nil then
		dashboard.node = node
		dashboard.baseColor = self:getDashboardColor(getXMLString(xmlFile, key .. "#baseColor"))

		if dashboard.baseColor ~= nil then
			setShaderParameter(dashboard.node, "baseColor", dashboard.baseColor[1], dashboard.baseColor[2], dashboard.baseColor[3], dashboard.baseColor[4], false)
		end

		dashboard.emitColor = self:getDashboardColor(getXMLString(xmlFile, key .. "#emitColor"))

		if dashboard.emitColor ~= nil then
			setShaderParameter(dashboard.node, "emitColor", dashboard.emitColor[1], dashboard.emitColor[2], dashboard.emitColor[3], dashboard.emitColor[4], false)
		end

		dashboard.intensity = getXMLFloat(xmlFile, key .. "#intensity") or 1

		setShaderParameter(dashboard.node, "lightControl", dashboard.idleValue, 0, 0, 0, false)
	else
		g_logManager:xmlWarning(self.configFileName, "Missing node for emitter dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadNumberDashboardFromXML(xmlFile, key, dashboard)
	dashboard.numbers = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#numbers"), self.i3dMappings)
	dashboard.numberColor = self:getDashboardColor(getXMLString(xmlFile, key .. "#numberColor"))

	if dashboard.numbers ~= nil and dashboard.numberColor ~= nil then
		for node, _ in pairs(I3DUtil.getNodesByShaderParam(dashboard.numbers, "numberColor")) do
			setShaderParameter(node, "numberColor", dashboard.numberColor[1], dashboard.numberColor[2], dashboard.numberColor[3], dashboard.numberColor[4], false)
		end
	end

	if dashboard.numbers ~= nil then
		dashboard.precision = Utils.getNoNil(getXMLInt(xmlFile, key .. "#precision"), 1)
		dashboard.numChilds = getNumOfChildren(dashboard.numbers)

		if dashboard.numChilds - dashboard.precision <= 0 then
			g_logManager:xmlWarning(self.configFileName, "Not enough number meshes for vehicle hud '%s'", key)
		end

		dashboard.numChilds = dashboard.numChilds - dashboard.precision
		dashboard.maxValue = 10^dashboard.numChilds - 1 / 10^dashboard.precision
	else
		g_logManager:xmlWarning(self.configFileName, "Missing numbers node for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadAnimationDashboardFromXML(xmlFile, key, dashboard)
	dashboard.animName = getXMLString(xmlFile, key .. "#animName")

	if dashboard.animName ~= nil then
		dashboard.minValueAnim = getXMLFloat(xmlFile, key .. "#minValueAnim")
		dashboard.maxValueAnim = getXMLFloat(xmlFile, key .. "#maxValueAnim")
	else
		g_logManager:xmlWarning(self.configFileName, "Missing animation for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadRotationDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if dashboard.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	dashboard.rotAxis = getXMLInt(xmlFile, key .. "#rotAxis")
	local minRotStr = getXMLString(xmlFile, key .. "#minRot")

	if minRotStr ~= nil then
		if dashboard.rotAxis ~= nil then
			dashboard.minRot = math.rad(tonumber(minRotStr))
		else
			dashboard.minRot = StringUtil.getRadiansFromString(minRotStr, 3)
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Missing 'minRot' attribute for dashboard '%s'", key)

		return false
	end

	local maxRotStr = getXMLString(xmlFile, key .. "#maxRot")

	if maxRotStr ~= nil then
		if dashboard.rotAxis ~= nil then
			dashboard.maxRot = math.rad(tonumber(maxRotStr))
		else
			dashboard.maxRot = StringUtil.getRadiansFromString(maxRotStr, 3)
		end
	else
		g_logManager:xmlWarning(self.configFileName, "Missing 'maxRot' attribute for dashboard '%s'", key)

		return false
	end

	return true
end

function Dashboard:loadVisibilityDashboardFromXML(xmlFile, key, dashboard)
	dashboard.node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"), self.i3dMappings)

	if dashboard.node == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing 'node' for dashboard '%s'", key)

		return false
	end

	setVisibility(dashboard.node, false)

	return true
end

function Dashboard:defaultDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.displayTypeIndex == Dashboard.TYPES.EMITTER then
		Dashboard.defaultEmitterDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.NUMBER then
		Dashboard.defaultNumberDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ANIMATION then
		Dashboard.defaultAnimationDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.ROT then
		Dashboard.defaultRotationDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	elseif dashboard.displayTypeIndex == Dashboard.TYPES.VISIBILITY then
		Dashboard.defaultVisibilityDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
	end
end

function Dashboard:defaultEmitterDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	newValue = newValue == nil and isActive or newValue and isActive

	setShaderParameter(dashboard.node, "lightControl", newValue and dashboard.intensity or dashboard.idleValue, 0, 0, 0, false)
end

function Dashboard:defaultNumberDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	local num = tonumber(string.format("%." .. dashboard.precision .. "f", newValue))

	I3DUtil.setNumberShaderByValue(dashboard.numbers, num, dashboard.precision, isActive)
end

function Dashboard:defaultAnimationDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	if dashboard.animName ~= nil then
		if self:getAnimationExists(dashboard.animName) then
			local normValue = nil

			if dashboard.minValueAnim ~= nil and dashboard.maxValueAnim ~= nil then
				newValue = MathUtil.clamp(newValue, dashboard.minValueAnim, dashboard.maxValueAnim)
				normValue = MathUtil.round((newValue - dashboard.minValueAnim) / (dashboard.maxValueAnim - dashboard.minValueAnim), 3)
			else
				minValue = minValue or 0
				maxValue = maxValue or 1
				normValue = MathUtil.round((newValue - minValue) / (maxValue - minValue), 3)
			end

			self:setAnimationTime(dashboard.animName, normValue, true)
		else
			g_logManager:xmlWarning(self.configFileName, "Unknown animation name '%s' for dashboard!", dashboard.animName)

			dashboard.animName = nil
		end
	end
end

function Dashboard:defaultRotationDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	minValue = minValue or 0
	maxValue = maxValue or 1
	local alpha = (newValue - minValue) / (maxValue - minValue)

	if dashboard.rotAxis ~= nil then
		local x, y, z = getRotation(dashboard.node)
		local rot = MathUtil.lerp(dashboard.minRot, dashboard.maxRot, alpha)

		if dashboard.rotAxis == 1 then
			x = rot
		elseif dashboard.rotAxis == 2 then
			y = rot
		else
			z = rot
		end

		setRotation(dashboard.node, x, y, z)
	else
		local x1, y1, z1 = unpack(dashboard.minRot)
		local x2, y2, z2 = unpack(dashboard.maxRot)
		local x, y, z = MathUtil.lerp3(x1, y1, z1, x2, y2, z2, alpha)

		setRotation(dashboard.node, x, y, z)
	end
end

function Dashboard:defaultVisibilityDashboardStateFunc(dashboard, newValue, minValue, maxValue, isActive)
	newValue = newValue == nil and isActive or newValue and isActive

	setVisibility(dashboard.node, newValue)
end

function Dashboard:warningAttributes(xmlFile, key, dashboard, isActive)
	dashboard.warningThresholdMin = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#warningThresholdMin"), -math.huge)
	dashboard.warningThresholdMax = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#warningThresholdMax"), math.huge)

	return true
end

function Dashboard:warningState(dashboard, newValue, minValue, maxValue, isActive)
	Dashboard.defaultDashboardStateFunc(self, dashboard, dashboard.warningThresholdMin < newValue and newValue < dashboard.warningThresholdMax, minValue, maxValue, isActive)
end

function Dashboard:setDashboardsDirty()
	self.spec_dashboard.isDirty = true

	self:raiseActive()
end

function Dashboard:getDashboardValue(valueObject, valueFunc, dashboard)
	if type(valueFunc) == "number" or type(valueFunc) == "boolean" then
		return valueFunc
	elseif type(valueFunc) == "function" then
		return valueFunc(valueObject, dashboard)
	end

	local object = valueObject[valueFunc]

	if type(object) == "function" then
		return valueObject[valueFunc](valueObject, dashboard)
	elseif type(object) == "number" or type(object) == "boolean" then
		return object
	end

	return nil
end

function Dashboard:getDashboardColor(colorStr)
	if colorStr == nil then
		return nil
	end

	if Dashboard.COLORS[colorStr:upper()] ~= nil then
		return Dashboard.COLORS[colorStr:upper()]
	end

	local brandColor = g_brandColorManager:getBrandColorByName(colorStr)

	if brandColor ~= nil then
		return brandColor
	end

	local vector = StringUtil.getVectorNFromString(colorStr, 4)

	if vector ~= nil then
		return vector
	end

	return nil
end
