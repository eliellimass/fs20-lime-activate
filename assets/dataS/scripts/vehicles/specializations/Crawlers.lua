Crawlers = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Wheels, specializations)
	end
}

function Crawlers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromXML", Crawlers.loadCrawlerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromConfigFile", Crawlers.loadCrawlerFromConfigFile)
end

function Crawlers.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Crawlers.validateWashableNode)
end

function Crawlers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Crawlers)
end

function Crawlers:onLoad(savegame)
	local spec = self.spec_crawlers
	local wheelConfigId = Utils.getNoNil(self.configurations.wheel, 1)
	local wheelKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", wheelConfigId - 1)
	spec.crawlers = {}
	local i = 0

	while true do
		local key = string.format(wheelKey .. ".crawlers.crawler(%d)", i)

		if not hasXMLProperty(self.xmlFile, key) then
			break
		end

		local crawler = {}

		if self:loadCrawlerFromXML(self.xmlFile, key, crawler) then
			table.insert(spec.crawlers, crawler)
		end

		i = i + 1
	end
end

function Crawlers:onDelete()
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		if crawler.filename ~= nil then
			g_i3DManager:releaseSharedI3DFile(crawler.filename, self.baseDirectory, true)
		end
	end
end

function Crawlers:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		crawler.movedDistance = 0

		if crawler.wheel ~= nil then
			local newX, _, _ = getRotation(crawler.wheel.driveNode)

			if crawler.lastRotation == nil then
				crawler.lastRotation = newX
			end

			if newX - crawler.lastRotation < -math.pi then
				crawler.lastRotation = crawler.lastRotation - 2 * math.pi
			elseif math.pi < newX - crawler.lastRotation then
				crawler.lastRotation = crawler.lastRotation + 2 * math.pi
			end

			crawler.movedDistance = crawler.wheel.radius * (newX - crawler.lastRotation)
			crawler.lastRotation = newX
		else
			local newX, newY, newZ = getWorldTranslation(crawler.speedReferenceNode)

			if crawler.lastPosition == nil then
				crawler.lastPosition = {
					newX,
					newY,
					newZ
				}
			end

			local dx, dy, dz = worldDirectionToLocal(crawler.speedReferenceNode, newX - crawler.lastPosition[1], newY - crawler.lastPosition[2], newZ - crawler.lastPosition[3])
			local movingDirection = 0

			if dz > 0.0001 then
				movingDirection = 1
			elseif dz < -0.0001 then
				movingDirection = -1
			end

			crawler.movedDistance = MathUtil.vector3Length(dx, dy, dz) * movingDirection
			crawler.lastPosition[1] = newX
			crawler.lastPosition[2] = newY
			crawler.lastPosition[3] = newZ
		end

		for _, scrollerNode in pairs(crawler.scrollerNodes) do
			scrollerNode.scrollPosition = (scrollerNode.scrollPosition + crawler.movedDistance * scrollerNode.scrollSpeed) % scrollerNode.scrollLength

			if scrollerNode.shaderParameterComponent == 1 then
				setShaderParameter(scrollerNode.node, scrollerNode.shaderParameterName, scrollerNode.scrollPosition, 0, 0, 0, false)
			else
				setShaderParameter(scrollerNode.node, scrollerNode.shaderParameterName, 0, scrollerNode.scrollPosition, 0, 0, false)
			end
		end

		for _, rotatingPart in pairs(crawler.rotatingParts) do
			if crawler.wheel ~= nil and rotatingPart.speedScale == nil then
				local newX, _, _ = getRotation(crawler.wheel.driveNode)

				setRotation(rotatingPart.node, newX, 0, 0)
			elseif rotatingPart.speedScale ~= nil then
				rotate(rotatingPart.node, rotatingPart.speedScale * crawler.movedDistance, 0, 0)
			end
		end
	end
end

function Crawlers:loadCrawlerFromXML(xmlFile, key, crawler)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#crawlerIndex", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#length", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#shaderParameterComponent", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#shaderParameterName", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#scrollLength", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#scrollSpeed", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#index", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. ".rotatingPart", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#linkIndex", key .. "#linkNode")

	local linkNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#linkNode"), self.i3dMappings)

	if linkNode == nil then
		g_logManager:xmlWarning(self.configFileName, "Missing link node for crawler '%s'", key)

		return false
	end

	local isLeft = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isLeft"), false)
	crawler.trackWidth = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#trackWidth"), 1)
	local filename = getXMLString(xmlFile, key .. "#filename")

	if not self:loadCrawlerFromConfigFile(crawler, filename, linkNode, isLeft) then
		return false
	end

	local offset = StringUtil.getVectorNFromString(getXMLString(xmlFile, key .. "#offset"), 3)

	if offset ~= nil then
		setTranslation(crawler.loadedCrawler, unpack(offset))
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#speedRefWheel", key .. "#wheelIndex")

	local wheelIndex = getXMLInt(xmlFile, key .. "#wheelIndex")

	if wheelIndex ~= nil then
		local wheels = self:getWheels()

		if wheels[wheelIndex] ~= nil then
			crawler.wheel = wheels[wheelIndex]

			if not crawler.wheel.isSynchronized then
				g_logManager:xmlWarning(self.configFileName, "Wheel for crawler '%s' in not synchronized! It won't rotate on the client side.", key)
			end
		end
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#speedRefNode", key .. "#speedReferenceNode")

	crawler.speedReferenceNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(xmlFile, key .. "#speedReferenceNode"), self.i3dMappings), linkNode)
	crawler.movedDistance = 0
	crawler.fieldDirtMultiplier = Utils.getNoNil(getXMLInt(xmlFile, key .. "#fieldDirtMultiplier"), 150)
	crawler.streetDirtMultiplier = Utils.getNoNil(getXMLInt(xmlFile, key .. "#streetDirtMultiplier"), -300)
	crawler.minDirtPercentage = Utils.getNoNil(getXMLInt(xmlFile, key .. "#minDirtPercentage"), 0.35)

	return true
end

function Crawlers:loadCrawlerFromConfigFile(crawler, xmlFilename, linkNode, isLeft)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = loadXMLFile("TempConfig", xmlFilename)

	if xmlFile ~= nil then
		local filename = getXMLString(xmlFile, "crawler.file#name")

		if filename ~= nil then
			crawler.filename = filename
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				local key = isLeft and "leftNode" or "rightNode"
				crawler.loadedCrawler = I3DUtil.indexToObject(i3dNode, getXMLString(xmlFile, "crawler.file#" .. key))

				link(linkNode, crawler.loadedCrawler)
				delete(i3dNode)
			else
				g_logManager:xmlWarning(self.configFileName, "Failed to find crawler in i3d file '%s'", filename, xmlFilename)

				return false
			end
		else
			g_logManager:xmlWarning(self.configFileName, "Failed to open crawler i3d file '%s' in '%s'", filename, xmlFilename)

			return false
		end

		crawler.scrollerNodes = {}
		local j = 0

		while true do
			local key = string.format("crawler.scrollerNodes.scrollerNode(%d)", j)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local entry = {
				node = I3DUtil.indexToObject(crawler.loadedCrawler, getXMLString(xmlFile, key .. "#node"))
			}

			if entry.node ~= nil then
				entry.scrollSpeed = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#scrollSpeed"), 1)
				entry.scrollLength = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#scrollLength"), 1)
				entry.shaderParameterName = Utils.getNoNil(getXMLString(xmlFile, key .. "#shaderParameterName"), "offsetUV")
				entry.shaderParameterComponent = Utils.getNoNil(getXMLInt(xmlFile, key .. "#shaderParameterComponent"), 1)
				entry.scrollPosition = 0

				if crawler.trackWidth ~= 1 and Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTrackPart"), true) then
					setScale(entry.node, crawler.trackWidth, 1, 1)
				end

				table.insert(crawler.scrollerNodes, entry)
			end

			j = j + 1
		end

		crawler.rotatingParts = {}
		j = 0

		while true do
			local key = string.format("crawler.rotatingParts.rotatingPart(%d)", j)

			if not hasXMLProperty(xmlFile, key) then
				break
			end

			local entry = {
				node = I3DUtil.indexToObject(crawler.loadedCrawler, getXMLString(xmlFile, key .. "#node"))
			}

			if entry.node ~= nil then
				entry.radius = getXMLFloat(xmlFile, key .. "#radius")
				entry.speedScale = getXMLFloat(xmlFile, key .. "#speedScale")

				if entry.speedScale == nil and entry.radius ~= nil then
					entry.speedScale = 1 / entry.radius
				end

				table.insert(crawler.rotatingParts, entry)
			end

			j = j + 1
		end

		local function applyColor(name, color)
			j = 0

			while true do
				local key = string.format("crawler.%s.%s(%d)", name .. "s", name, j)

				if not hasXMLProperty(xmlFile, key) then
					break
				end

				local node = I3DUtil.indexToObject(crawler.loadedCrawler, getXMLString(xmlFile, key .. "#node"))

				if node ~= nil then
					local shaderParameter = getXMLString(xmlFile, key .. "#shaderParameter")

					if getHasShaderParameter(node, shaderParameter) then
						local r, g, b, mat = unpack(color)

						if mat == nil then
							_, _, _, mat = getShaderParameter(node, shaderParameter)
						end

						I3DUtil.setShaderParameterRec(node, shaderParameter, r, g, b, mat, true)
					else
						g_logManager:xmlWarning(self.configFileName, "Missing shaderParameter '%s' on object '%s' in %s", shaderParameter, getName(node), key)
					end
				end

				j = j + 1
			end
		end

		local rimColor = Utils.getNoNil(ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor), self.spec_wheels.rimColor)

		if rimColor ~= nil then
			crawler.rimColorNodes = applyColor("rimColorNode", rimColor)
		end

		crawler.objectChanges = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, "crawler", crawler.objectChanges, crawler.loadedCrawler, self)
		ObjectChangeUtil.setObjectChanges(crawler.objectChanges, true)
		delete(xmlFile)

		return true
	end

	g_logManager:xmlWarning(self.configFileName, "Failed to open crawler config file '%s'", xmlFilename)

	return false
end

function Crawlers:validateWashableNode(superFunc, node)
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		local crawlerNodes = {}

		I3DUtil.getNodesByShaderParam(crawler.loadedCrawler, "RDT", crawlerNodes)

		if crawlerNodes[node] ~= nil then
			return false, self.updateWheelDirtAmount, crawler, {
				wheel = crawler.wheel,
				fieldDirtMultiplier = crawler.fieldDirtMultiplier,
				streetDirtMultiplier = crawler.streetDirtMultiplier,
				minDirtPercentage = crawler.minDirtPercentage
			}
		end
	end

	return superFunc(self, node)
end
