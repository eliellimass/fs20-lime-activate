Effect = {}
local Effect_mt = Class(Effect)

function Effect:new(customMt)
	local self = setmetatable({}, customMt or Effect_mt)

	return self
end

function Effect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
	if not hasXMLProperty(xmlFile, baseName) then
		return nil
	end

	self.parent = parent
	self.rootNodes = rootNodes
	self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
	self.baseDirectory = parent.baseDirectory
	local filename = getXMLString(xmlFile, baseName .. "#filename")

	if filename ~= nil then
		local shared = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#shared"), true)
		local i3dNode = 0

		if shared then
			i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)
		else
			filename = Utils.getFilename(filename, self.baseDirectory)
			i3dNode = loadI3DFile(filename, false, false, false)
		end

		if i3dNode ~= 0 then
			if shared then
				self.filename = filename
			end

			if not self:loadEffectAttributes(xmlFile, baseName, nil, i3dNode, i3dMapping) then
				g_logManager:xmlWarning(self.configFileName, "Failed to load effect from file '%s'", baseName)

				return nil
			end

			self:transformEffectNode(xmlFile, baseName, nil)
			delete(i3dNode)
		end
	else
		if not self:loadEffectAttributes(xmlFile, baseName, nil, rootNodes, i3dMapping) then
			g_logManager:xmlWarning(self.configFileName, "Failed to load effect '%s' from node", baseName)

			return nil
		end

		self:transformEffectNode(xmlFile, baseName, nil)
	end

	return self
end

function Effect:loadFromNode(node, parent)
	self.parent = parent
	self.baseDirectory = parent.baseDirectory
	self.configFileName = Utils.getNoNil(parent.configFileName, parent.xmlFilename)
	local filename = getUserAttribute(node, "filename")
	local i3dNode = 0

	if filename ~= nil then
		local shared = Utils.getNoNil(getUserAttribute(node, "shared"), true)

		if shared then
			i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)
		else
			filename = Utils.getFilename(filename, self.baseDirectory)
			i3dNode = loadI3DFile(filename, false, false, false)
		end

		if shared then
			self.filename = filename
		end
	end

	if not self:loadEffectAttributes(nil, , node, i3dNode) then
		g_logManager:xmlWarning(self.configFileName, "Failed to load effect from node '%s'", getName(node))

		return nil
	end

	self:transformEffectNode(nil, , node)

	if i3dNode ~= 0 then
		delete(i3dNode)
	end

	return self
end

function Effect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	local useSelfAsEffectNode = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLFloat, node, "useSelfAsEffectNode"), false)
	self.prio = Utils.getNoNil(Effect.getValue(xmlFile, key, getXMLInt, node, "prio"), 0)
	local effect = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, getXMLString, node, "effectNode"), i3dMapping)

	if effect == nil and useSelfAsEffectNode then
		effect = node
	end

	if effect ~= nil then
		self.node = effect
	else
		self.node = I3DUtil.indexToObject(i3dNode, Effect.getValue(xmlFile, key, getXMLString, node, "node"), i3dMapping)
		self.linkNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), Effect.getValue(xmlFile, key, getXMLString, node, "linkNode"), i3dMapping)

		if self.linkNode == nil then
			if node == nil then
				g_logManager:xmlWarning(self.configFileName, "LinkNode is nil in '%s'", key)
			else
				g_logManager:xmlWarning(self.configFileName, "LinkNode is nil in node attribute '%s'", getName(node))
			end

			return false
		end

		if self.node == nil then
			if node == nil then
				g_logManager:xmlWarning(self.configFileName, "Node is nil in '%s'", key)
			else
				g_logManager:xmlWarning(self.configFileName, "Node is nil in node attribute '%s'", getName(node))
			end

			return false
		end

		if self.node ~= nil and self.linkNode ~= nil then
			link(self.linkNode, self.node)
		end
	end

	return true
end

function Effect:transformEffectNode(xmlFile, key, node)
	local x, y, z = StringUtil.getVectorFromString(Effect.getValue(xmlFile, key, getXMLString, node, "position"))
	local rotX, rotY, rotZ = StringUtil.getVectorFromString(Effect.getValue(xmlFile, key, getXMLString, node, "rotation"))

	if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
		rotX = MathUtil.degToRad(rotX)
		rotY = MathUtil.degToRad(rotY)
		rotZ = MathUtil.degToRad(rotZ)
	end

	local scaleX, scaleY, scaleZ = StringUtil.getVectorFromString(Effect.getValue(xmlFile, key, getXMLString, node, "scale"))

	if x ~= nil and y ~= nil and z ~= nil then
		setTranslation(self.node, x, y, z)
	end

	if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
		setRotation(self.node, rotX, rotY, rotZ)
	end

	if scaleX ~= nil and scaleY ~= nil and scaleZ ~= nil then
		setScale(self.node, scaleX, scaleY, scaleZ)
	end

	setVisibility(self.node, false)
end

function Effect:delete()
	if self.filename ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.filename, self.baseDirectory, true)
	end
end

function Effect:update(dt)
end

function Effect:isRunning()
	return false
end

function Effect:start()
	return false
end

function Effect:stop()
	return false
end

function Effect:reset()
end

function Effect:getIsFullyVisible()
	return true
end

function Effect.getValue(xmlFile, key, func, node, name)
	if node == nil then
		return func(xmlFile, key .. "#" .. name)
	else
		return getUserAttribute(node, name)
	end
end
