HandTool = {}
local HandTool_mt = Class(HandTool, Object)

InitStaticObjectClass(HandTool, "HandTool", ObjectIds.OBJECT_HANDTOOL)

HandTool.handToolTypes = {}

function registerHandTool(typeName, classObject)
	if not ClassUtil.getIsValidClassName(typeName) then
		print("Error: invalid handtool typeName: " .. typeName)

		return
	end

	HandTool.handToolTypes[typeName] = classObject
end

function HandTool:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = HandTool_mt
	end

	local self = Object:new(isServer, isClient, mt)
	self.static = true
	self.player = nil
	self.owner = nil
	self.currentPlayerHandNode = nil
	self.price = 0
	self.age = 0
	self.activatePressed = false

	return self
end

function HandTool:load(xmlFilename, player)
	self.configFileName = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = loadXMLFile("TempXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local i3dFilename = getXMLString(xmlFile, "handTool.filename")

	if i3dFilename == nil then
		delete(xmlFile)

		return false
	end

	self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
	local node = g_i3DManager:loadSharedI3DFile(self.i3dFilename)
	self.rootNode = getChildAt(node, 0)
	self.player = player
	self.handNodePosition = {}
	self.handNodeRotation = {}
	self.handNode = nil
	self.originalHandNodeParent = nil
	self.referenceNode = nil

	if self.player == g_currentMission.player then
		self.handNodePosition = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.firstPerson#position"), "0 0 0"), 3)
		self.handNodeRotation = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.firstPerson#rotation"), "0 0 0"), 3)
		self.handNode = Utils.getNoNil(I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.handNode.firstPerson#node")), self.rootNode)
		self.referenceNode = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.handNode.firstPerson#referenceNode"))
	else
		self.handNodePosition = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.thirdPerson#position"), "0 0 0"), 3)
		self.handNodeRotation = StringUtil.getRadiansFromString(Utils.getNoNil(getXMLString(xmlFile, "handTool.handNode.thirdPerson#rotation"), "0 0 0"), 3)
		self.handNode = Utils.getNoNil(I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.handNode.thirdPerson#node")), self.rootNode)
		self.referenceNode = I3DUtil.indexToObject(self.rootNode, getXMLString(xmlFile, "handTool.handNode.thirdPerson#referenceNode"))
	end

	if self.rootNode ~= self.handNode then
		self.originalHandNodeParent = getParent(self.handNode)
	end

	setTranslation(self.handNode, unpack(self.handNodePosition))
	setRotation(self.handNode, unpack(self.handNodeRotation))

	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if self.price == 0 or self.price == nil then
		self.price = StoreItemUtil.getDefaultPrice(storeItem)
	end

	if g_currentMission ~= nil and storeItem.canBeSold then
		g_currentMission.environment:addDayChangeListener(self)
	end

	self.targets = {}

	IKUtil.loadIKChainTargets(xmlFile, "handTool.targets", self.rootNode, self.targets, nil)
	setVisibility(self.rootNode, false)

	self.isActive = false

	delete(xmlFile)

	return true
end

function HandTool:setHandNode(playerHandNode)
	if self.currentPlayerHandNode ~= playerHandNode then
		self.currentPlayerHandNode = playerHandNode

		link(playerHandNode, self.handNode)

		if self.referenceNode ~= nil then
			local x, y, z = getWorldTranslation(self.referenceNode)
			x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
			local a, b, c = getTranslation(self.handNode)

			setTranslation(self.handNode, a - x, b - y, c - z)
		end
	end
end

function HandTool:delete()
	self:removeActionEvents()

	if g_currentMission ~= nil then
		g_currentMission.environment:removeDayChangeListener(self)
	end

	if self.rootNode ~= nil and self.rootNode ~= 0 then
		if self.originalHandNodeParent ~= nil and getParent(self.handNode) ~= self.originalHandNodeParent then
			link(self.originalHandNodeParent, self.handNode)
		end

		g_i3DManager:releaseSharedI3DFile(self.i3dFilename, g_currentMission.baseDirectory, false)
		delete(self.rootNode)
	end

	HandTool:superClass().delete(self)
end

function HandTool:update(dt, allowInput)
	if self.isActive then
		self:raiseActive()
	end
end

function HandTool:onActivate(allowInput)
	setVisibility(self.rootNode, true)

	self.isActive = true

	self:raiseActive()

	if self.player.isOwner then
		self:registerActionEvents()
	end
end

function HandTool:onDeactivate(allowInput)
	setVisibility(self.rootNode, false)

	self.isActive = false

	self:removeActionEvents()
end

function HandTool:loadFromXMLFile(xmlFile, key, resetVehicles)
	return true
end

function HandTool:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLString(xmlFile, key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
end

function HandTool:getDailyUpkeep()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)
		multiplier = EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, nil) * multiplier
end

function HandTool:getSellPrice()
	local priceMultiplier = 0.5
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local maxVehicleAge = storeItem.lifetime

	if maxVehicleAge ~= nil and maxVehicleAge ~= 0 then
		priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxVehicleAge, 1))
	end

	return math.floor(self.price * math.max(priceMultiplier, 0.05))
end

function HandTool:dayChanged()
	self.age = self.age + 1
end

function HandTool:isBeingUsed()
	return false
end

function HandTool:registerActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:endActionEventsModification()
end

function HandTool:removeActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)
	g_inputBinding:endActionEventsModification()
end
