Bale = {}
local Bale_mt = Class(Bale, MountableObject)

InitStaticObjectClass(Bale, "Bale", ObjectIds.OBJECT_BALE)

function Bale:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = Bale_mt
	end

	local self = MountableObject:new(isServer, isClient, mt)
	self.forcedClipDistance = 150

	registerObjectClassName(self, "Bale")

	self.fillType = FillType.STRAW
	self.fillLevel = 0
	self.wrappingState = 0
	self.baleValueScale = 1
	self.canBeSold = true
	self.allowPickup = true

	g_currentMission:addLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, self)

	return self
end

function Bale:delete()
	if self.i3dFilename ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.i3dFilename, nil, true)
	end

	g_currentMission:removeLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE, self)
	unregisterObjectClassName(self)
	g_currentMission:removeItemToSave(self)
	Bale:superClass().delete(self)
end

function Bale:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and self.supportsWrapping then
		self:setWrappingState(streamReadUInt8(streamId) / 255)
	end

	Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function Bale:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() and self.supportsWrapping then
		streamWriteUInt8(streamId, MathUtil.clamp(self.wrappingState * 255, 0, 255))
	end

	Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end

function Bale:readStream(streamId, connection)
	local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	if self.nodeId == 0 then
		self:createNode(i3dFilename)
	end

	self.fillLevel = streamReadFloat32(streamId)

	Bale:superClass().readStream(self, streamId, connection)
	g_currentMission:addItemToSave(self)

	self.baleValueScale = streamReadFloat32(streamId)

	if self.supportsWrapping then
		self:setWrappingState(streamReadUInt8(streamId) / 255)
		setShaderParameter(self.meshNode, "wrappingState", self.wrappingState, 0, 0, 0, false)

		local r = streamReadFloat32(streamId)
		local g = streamReadFloat32(streamId)
		local b = streamReadFloat32(streamId)
		local a = streamReadFloat32(streamId)

		self:setColor(r, g, b, a)
	end
end

function Bale:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
	streamWriteFloat32(streamId, self.fillLevel)
	Bale:superClass().writeStream(self, streamId, connection)
	streamWriteFloat32(streamId, self.baleValueScale)

	if self.supportsWrapping then
		streamWriteUInt8(streamId, MathUtil.clamp(self.wrappingState * 255, 0, 255))
		streamWriteFloat32(streamId, self.wrappingColor[1])
		streamWriteFloat32(streamId, self.wrappingColor[2])
		streamWriteFloat32(streamId, self.wrappingColor[3])
		streamWriteFloat32(streamId, self.wrappingColor[4])
	end
end

function Bale:mount(object, node, x, y, z, rx, ry, rz)
	g_currentMission:removeItemToSave(self)
	Bale:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
end

function Bale:unmount()
	if Bale:superClass().unmount(self) then
		g_currentMission:addItemToSave(self)

		return true
	end

	return false
end

function Bale:setNodeId(nodeId)
	Bale:superClass().setNodeId(self, nodeId)

	local isRoundbale = Utils.getNoNil(getUserAttribute(nodeId, "isRoundbale"), false)
	local defaultFillLevel = 4000

	if getUserAttribute(nodeId, "baleValue") ~= nil then
		print("Warning: bale 'baleValue' is not supported anymore. Use 'baleValueScale' instead and adjust the creating vehicles.")
	end

	local meshIndex = Utils.getNoNil(getUserAttribute(nodeId, "baleMeshIndex"), "1|0")
	self.meshNode = I3DUtil.indexToObject(nodeId, meshIndex)
	self.meshNodes = {
		self.meshNode
	}
	self.supportsWrapping = Utils.getNoNil(getUserAttribute(nodeId, "supportsWrapping"), false)

	if self.supportsWrapping then
		self.wrappingColor = {
			1,
			1,
			1,
			1
		}
	end

	self.fillLevel = defaultFillLevel
	self.baleValueScale = Utils.getNoNil(tonumber(getUserAttribute(nodeId, "baleValueScale")), 1)
	self.fillType = FillType.STRAW
	local fillTypeStr = getUserAttribute(nodeId, "fillType")

	if fillTypeStr ~= nil then
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex ~= nil then
			self.fillType = fillTypeIndex
		end
	elseif Utils.getNoNil(getUserAttribute(nodeId, "isHaybale"), false) then
		self.fillType = FillType.DRYGRASS_WINDROW
	end

	local baleWidth = tonumber(getUserAttribute(nodeId, "baleWidth"))
	local baleHeight = tonumber(getUserAttribute(nodeId, "baleHeight"))
	local baleLength = tonumber(getUserAttribute(nodeId, "baleLength"))
	local baleDiameter = tonumber(getUserAttribute(nodeId, "baleDiameter"))

	if baleDiameter ~= nil and baleWidth ~= nil then
		self.baleDiameter = baleDiameter
		self.baleWidth = baleWidth
	elseif baleHeight ~= nil and baleWidth ~= nil and baleLength ~= nil then
		self.baleHeight = baleHeight
		self.baleWidth = baleWidth
		self.baleLength = baleLength
	else
		local isRoundbale = Utils.getNoNil(getUserAttribute(nodeId, "isRoundbale"), false)

		if isRoundbale then
			self.baleDiameter = 1.8
			self.baleWidth = 1.2
		else
			self.baleHeight = 0.8
			self.baleWidth = 1.2
			self.baleLength = 2.4
		end
	end
end

function Bale:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)
	local baleRoot = g_i3DManager:loadSharedI3DFile(i3dFilename)
	local baleId = getChildAt(baleRoot, 0)

	link(getRootNode(), baleId)
	delete(baleRoot)
	self:setNodeId(baleId)
end

function Bale:load(i3dFilename, x, y, z, rx, ry, rz, fillLevel)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)

	self:createNode(i3dFilename)
	setTranslation(self.nodeId, x, y, z)
	setRotation(self.nodeId, rx, ry, rz)

	if fillLevel ~= nil then
		self.fillLevel = fillLevel
	end

	g_currentMission:addItemToSave(self)
end

function Bale:loadFromMemory(nodeId, i3dFilename)
	self.i3dFilename = i3dFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(i3dFilename)

	self:setNodeId(nodeId)
end

function Bale:loadFromXMLFile(xmlFile, key, resetVehicles)
	local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#position"))
	local xRot, yRot, zRot = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))

	if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
		return false
	end

	xRot = math.rad(xRot)
	yRot = math.rad(yRot)
	zRot = math.rad(zRot)
	local filename = getXMLString(xmlFile, key .. "#filename")

	if filename == nil then
		return false
	end

	filename = NetworkUtil.convertFromNetworkFilename(filename)
	local rootNode = g_i3DManager:loadSharedI3DFile(filename)

	if rootNode == 0 then
		return false
	end

	local ret = false
	local node = getChildAt(rootNode, 0)

	if node ~= nil and node ~= 0 then
		setTranslation(node, x, y, z)
		setRotation(node, xRot, yRot, zRot)
		link(getRootNode(), node)

		ret = true
	end

	delete(rootNode)

	if not ret then
		return false
	end

	self:setOwnerFarmId(Utils.getNoNil(getXMLInt(xmlFile, key .. "#farmId"), AccessHandler.EVERYONE), true)
	self:loadFromMemory(node, filename)

	local fillLevel = getXMLFloat(xmlFile, key .. "#fillLevel")

	if fillLevel ~= nil then
		self.fillLevel = fillLevel
	end

	local attributes = {}

	self:loadExtraAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
	self:applyExtraAttributes(attributes)

	return true
end

function Bale:loadExtraAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
	attributes.wrappingState = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#wrappingState"), 0)
	attributes.wrappingColor = {
		StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#wrappingColor"))
	}
	attributes.baleValueScale = Utils.getNoNil(tonumber(getXMLString(xmlFile, key .. "#valueScale")), 1)

	return true
end

function Bale:applyExtraAttributes(attributes)
	if self.supportsWrapping then
		setShaderParameter(self.meshNode, "wrappingState", attributes.wrappingState, 0, 0, 0, false)

		self.wrappingState = attributes.wrappingState

		self:setColor(unpack(attributes.wrappingColor))
	end

	self.baleValueScale = attributes.baleValueScale

	return true
end

function Bale:saveToXMLFile(xmlFile, key)
	local x, y, z = getTranslation(self.nodeId)
	local xRot, yRot, zRot = getRotation(self.nodeId)

	setXMLString(xmlFile, key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.i3dFilename)))
	setXMLString(xmlFile, key .. "#position", string.format("%.4f %.4f %.4f", x, y, z))
	setXMLString(xmlFile, key .. "#rotation", string.format("%.4f %.4f %.4f", math.deg(xRot), math.deg(yRot), math.deg(zRot)))
	setXMLFloat(xmlFile, key .. "#valueScale", self.baleValueScale)
	setXMLFloat(xmlFile, key .. "#fillLevel", self.fillLevel)
	setXMLInt(xmlFile, key .. "#farmId", self:getOwnerFarmId())

	if self.supportsWrapping then
		setXMLFloat(xmlFile, key .. "#wrappingState", self.wrappingState)
		setXMLString(xmlFile, key .. "#wrappingColor", string.format("%f %f %f %f", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], self.wrappingColor[4]))
	end
end

function Bale:getValue()
	local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType)

	return self.fillLevel * pricePerLiter * self.baleValueScale
end

function Bale:getFillType()
	return self.fillType
end

function Bale:getFillLevel()
	return self.fillLevel
end

function Bale:setFillLevel(fillLevel)
	self.fillLevel = fillLevel
end

function Bale:setCanBeSold(canBeSold)
	self.canBeSold = canBeSold
end

function Bale:getCanBeSold()
	return self.canBeSold
end

function Bale:setWrappingState(wrappingState)
	if self.supportsWrapping then
		if self.wrappingState ~= wrappingState then
			self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
		end

		self.wrappingState = wrappingState

		setShaderParameter(self.meshNode, "wrappingState", self.wrappingState, 0, 0, 0, false)
	end
end

function Bale:setColor(r, g, b, a)
	a = Utils.getNoNil(a, 1)
	b = Utils.getNoNil(b, 1)
	g = Utils.getNoNil(g, 1)
	r = Utils.getNoNil(r, 1)
	self.wrappingColor = {
		r,
		g,
		b,
		a
	}

	if getHasShaderParameter(self.meshNode, "colorScale") then
		setShaderParameter(self.meshNode, "colorScale", r, g, b, a, false)
	end
end

function Bale:getMeshNodes()
	return self.meshNodes
end

function Bale:getSupportsTensionBelts()
	return true
end

function Bale:getTensionBeltNodeId()
	return self.nodeId
end

function Bale:getBaleSupportsBaleLoader()
	return true
end

function Bale:getAllowPickup()
	return self.allowPickup
end
