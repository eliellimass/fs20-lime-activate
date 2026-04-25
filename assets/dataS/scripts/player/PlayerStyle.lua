PlayerStyle = {}
local PlayerStyle_mt = Class(PlayerStyle)

function PlayerStyle:new(customMt)
	local self = {}

	setmetatable(self, customMt or PlayerStyle_mt)

	self.player = nil
	self.selectedModelIndex = 1
	self.selectedColorIndex = 0
	self.selectedBodyIndex = 0
	self.selectedHatIndex = 0
	self.selectedAccessoryIndex = 0
	self.selectedHairIndex = 0
	self.selectedJacketIndex = 0
	self.playerName = "player"
	self.bodies = {}
	self.playerHatNode = nil
	self.playerAccessoryNode = nil
	self.accessoryNode = nil
	self.hatNode = nil
	self.hatReferenceFilename = ""
	self.accessoryReferenceFilename = ""
	self.accessories = {}
	self.hairs = {
		hatStyleNode = nil,
		styles = {}
	}
	self.jackets = {}
	self.protection = {
		helmetNode = nil,
		glovesNode = nil,
		isVisible = false
	}
	self.useDefault = false

	return self
end

function PlayerStyle:copySelection(other)
	self.selectedModelIndex = other.selectedModelIndex
	self.selectedColorIndex = other.selectedColorIndex
	self.selectedBodyIndex = other.selectedBodyIndex
	self.selectedHatIndex = other.selectedHatIndex
	self.selectedAccessoryIndex = other.selectedAccessoryIndex
	self.selectedHairIndex = other.selectedHairIndex
	self.selectedJacketIndex = other.selectedJacketIndex
	self.playerName = other.playerName
	self.useDefault = other.useDefault
end

function PlayerStyle:applySelection()
	self:setBody(self.selectedBodyIndex)
	self:setHair(self.selectedHairIndex)
	self:setHat(self.selectedHatIndex)
	self:setAccessory(self.selectedAccessoryIndex)
	self:setJacket(self.selectedJacketIndex)
	self:setColor(self.selectedColorIndex)
end

function PlayerStyle:loadXML(player, playerRootNode, xmlFile, baseKey)
	local i = 0
	self.player = player
	i = 0

	while true do
		local headKey = string.format("%s.playerStyle.bodies.variant(%d)#headNode", baseKey, i)
		local armsKey = string.format("%s.playerStyle.bodies.variant(%d)#armNode", baseKey, i)

		if not hasXMLProperty(xmlFile, headKey) or not hasXMLProperty(xmlFile, armsKey) then
			break
		end

		local headNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, headKey))
		local armsNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, armsKey))

		table.insert(self.bodies, {
			headNode = headNode,
			armsNode = armsNode
		})

		i = i + 1
	end

	self.playerHatNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, string.format("%s.playerStyle.hats#rootNode", baseKey)))
	self.hatReferenceFilename = getXMLString(xmlFile, string.format("%s.playerStyle.hats#filename", baseKey))
	self.playerAccessoryNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, string.format("%s.playerStyle.hats#rootNode", baseKey)))
	self.accessoryReferenceFilename = getXMLString(xmlFile, string.format("%s.playerStyle.hats#filename", baseKey))
	self.hairs.hatStyleNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, string.format("%s.playerStyle.hairStyles#hatHairNode", baseKey)))
	i = 0

	while true do
		local hairStyleKey = string.format("%s.playerStyle.hairStyles.variant(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, hairStyleKey) then
			break
		end

		local node = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, hairStyleKey .. "#node"))
		local name = Utils.getNoNil(getXMLString(xmlFile, hairStyleKey .. "#name"), "")
		local isHatHair = Utils.getNoNil(getXMLBool(xmlFile, hairStyleKey .. "#isHatHair"), false)

		if isHatHair and self.hairs.hatIndex == 0 then
			self.hairs.hatIndex = i + 1
		end

		table.insert(self.hairs.styles, {
			node = node,
			name = name
		})

		i = i + 1
	end

	i = 0

	while true do
		local jacketKey = string.format("%s.playerStyle.jackets.variant(%d)", baseKey, i)

		if not hasXMLProperty(xmlFile, jacketKey) then
			break
		end

		local node = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, jacketKey .. "#node"))
		local name = getXMLString(xmlFile, jacketKey .. "#name")

		table.insert(self.jackets, {
			node = node,
			name = name
		})

		i = i + 1
	end

	self.protection.helmetNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, string.format("%s.playerStyle.helmet#node", baseKey)))
	self.protection.glovesNode = I3DUtil.indexToObject(playerRootNode, getXMLString(xmlFile, string.format("%s.playerStyle.gloves#node", baseKey)))

	if self.useDefault then
		local defaultHatKey = string.format("%s.playerStyle#defaultHat", baseKey)

		if hasXMLProperty(xmlFile, defaultHatKey) then
			self.selectedHatIndex = getXMLInt(xmlFile, defaultHatKey)
		end

		local defaultAccessoryKey = string.format("%s.playerStyle#defaultAccessory", baseKey)

		if hasXMLProperty(xmlFile, defaultAccessoryKey) then
			self.selectedAccessoryIndex = getXMLInt(xmlFile, defaultAccessoryKey)
		end

		local defaultHairstyleKey = string.format("%s.playerStyle#defaultHaistyle", baseKey)

		if hasXMLProperty(xmlFile, defaultHairstyleKey) then
			self.selectedHairIndex = getXMLInt(xmlFile, defaultHairstyleKey)
		end

		local defaultBodyKey = string.format("%s.playerStyle#defaultBody", baseKey)

		if hasXMLProperty(xmlFile, defaultBodyKey) then
			self.selectedBodyIndex = getXMLInt(xmlFile, defaultBodyKey)
		end
	end
end

function PlayerStyle:linkProtectiveWear(linkNode)
	if self.protection.glovesNode ~= nil then
		link(linkNode, self.protection.glovesNode)
	end
end

function PlayerStyle:unlinkProtectiveWear()
	if self.protection.glovesNode ~= nil then
		unlink(self.protection.glovesNode)
	end
end

function PlayerStyle:readStream(streamId, connection)
	self.selectedModelIndex = streamReadUIntN(streamId, PlayerModelManager.SEND_NUM_BITS)
	self.selectedColorIndex = streamReadUInt8(streamId)
	self.selectedBodyIndex = streamReadUInt8(streamId)
	self.selectedHatIndex = streamReadUInt8(streamId)
	self.selectedAccessoryIndex = streamReadUInt8(streamId)
	self.selectedHairIndex = streamReadUInt8(streamId)
	self.selectedJacketIndex = streamReadUInt8(streamId)
	self.playerName = streamReadString(streamId)
end

function PlayerStyle:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.selectedModelIndex, PlayerModelManager.SEND_NUM_BITS)
	streamWriteUInt8(streamId, self.selectedColorIndex)
	streamWriteUInt8(streamId, self.selectedBodyIndex)
	streamWriteUInt8(streamId, self.selectedHatIndex)
	streamWriteUInt8(streamId, self.selectedAccessoryIndex)
	streamWriteUInt8(streamId, self.selectedHairIndex)
	streamWriteUInt8(streamId, self.selectedJacketIndex)
	streamWriteString(streamId, self.playerName)
end

function PlayerStyle:setColor(playerColorIndex)
	if self.player ~= nil then
		if self.player.meshThirdPerson ~= nil and self.player.meshThirdPerson ~= 0 and playerColorIndex > 0 and playerColorIndex <= table.getn(g_playerColors) then
			local r, g, b, a = unpack(g_playerColors[playerColorIndex].value)
			self.selectedColorIndex = playerColorIndex

			setShaderParameter(self.player.meshThirdPerson, "colorScaleR", r, g, b, a, false)
		end
	else
		g_logManager:devError("-- [PlayerStyle:setColor] Player not set. Missing call to PlayerStyle:loadXML().")
	end
end

function PlayerStyle:setBody(bodyIndex)
	local result = false

	if self.player ~= nil then
		for key, body in ipairs(self.bodies) do
			if key == bodyIndex then
				result = true

				setVisibility(body.headNode, true)
				setVisibility(body.armsNode, true)

				self.selectedBodyIndex = key
			else
				setVisibility(body.headNode, false)
				setVisibility(body.armsNode, false)
			end
		end
	else
		g_logManager:devError("-- [PlayerStyle:setBody] Player not set. Missing call to PlayerStyle:loadXML().")
	end

	return result
end

function PlayerStyle:removeHat()
	local result = false

	if self.player ~= nil and self.hatNode ~= nil then
		unlink(self.hatNode)
		delete(self.hatNode)

		self.hatNode = nil
		self.selectedAccessoryIndex = 0
		result = true
	end

	return result
end

function PlayerStyle:removeAccessory()
	local result = false

	if self.player ~= nil and self.accessoryNode ~= nil then
		unlink(self.accessoryNode)
		delete(self.accessoryNode)

		self.accessoryNode = nil
		self.selectedAccessoryIndex = 0
		result = true
	end

	return result
end

function PlayerStyle:setHair(hairIndex, isHatHair)
	local result = false

	if self.player ~= nil then
		if isHatHair ~= nil and isHatHair then
			if self.selectedHairIndex > 0 then
				local currentHairStyleNode = self.hairs.styles[self.selectedHairIndex].node

				setVisibility(currentHairStyleNode, false)
				setVisibility(self.hairs.hatStyleNode, true)
			end

			result = true
		else
			for key, hairStyle in ipairs(self.hairs.styles) do
				if key == hairIndex then
					if self.selectedHatIndex == 0 then
						setVisibility(hairStyle.node, true)
					end

					self.selectedHairIndex = key
					result = true
				else
					setVisibility(hairStyle.node, false)
				end
			end
		end
	else
		g_logManager:devError("-- [PlayerStyle:setHair] Player not set. Missing call to PlayerStyle:loadXML().")
	end

	return result
end

function PlayerStyle:setHat(hatIndex)
	local result = false

	if self.player ~= nil and self.playerHatNode ~= nil then
		if hatIndex == 0 and self.selectedHatIndex > 0 then
			result = self:removeHat()

			self:setHair(self.selectedHairIndex)
		elseif hatIndex ~= self.selectedHatIndex or self.hatNode == nil then
			self:removeHat()

			local xmlFilename = Utils.getFilename(self.hatReferenceFilename)

			if xmlFilename ~= nil and xmlFilename ~= "" then
				local xmlFile = loadXMLFile("hatXML", xmlFilename)

				if xmlFile ~= nil and xmlFile ~= 0 then
					local hatKey = string.format("playerClothing.hats.hat(%d)#filename", hatIndex - 1)

					if hasXMLProperty(xmlFile, hatKey) then
						local i3dFilename = getXMLString(xmlFile, hatKey)
						self.hatNode = loadI3DFile(i3dFilename, false, false, false)

						if self.hatNode ~= nil then
							self:setHair(0, true)
							link(self.playerHatNode, self.hatNode)

							self.selectedHatIndex = hatIndex
							result = true
						end
					end

					delete(xmlFile)
				end
			end
		end
	else
		g_logManager:devError("-- [PlayerStyle:setHat] Player not set. Missing call to PlayerStyle:loadXML().")
	end

	return result
end

function PlayerStyle:setJacket(jacketIndex)
	local result = false

	if self.player ~= nil then
		for key, jacket in ipairs(self.jackets) do
			if key == jacketIndex then
				result = true

				setVisibility(jacket.node, true)

				self.selectedJacketIndex = key
			else
				setVisibility(jacket.node, false)
			end
		end
	else
		g_logManager:devError("-- [PlayerStyle:setJacket] Player not set. Missing call to PlayerStyle:loadXML().")
	end

	return result
end

function PlayerStyle:setAccessory(accessoryIndex)
	local result = false

	if self.player ~= nil and self.playerAccessoryNode ~= nil then
		if accessoryIndex == 0 and self.selectedAccessoryIndex > 0 then
			result = self:removeHat()

			self:setHair(self.selectedHairIndex)
		elseif accessoryIndex ~= self.selectedAccessoryIndex or self.accessoryNode == nil then
			self:removeAccessory()

			local xmlFilename = Utils.getFilename(self.accessoryReferenceFilename)

			if xmlFilename ~= nil and xmlFilename ~= "" then
				local xmlFile = loadXMLFile("accessoryXML", xmlFilename)

				if xmlFile ~= nil and xmlFile ~= 0 then
					local accessoryKey = string.format("playerClothing.accessories.accessory(%d)#filename", accessoryIndex - 1)

					if hasXMLProperty(xmlFile, accessoryKey) then
						local i3dFilename = getXMLString(xmlFile, accessoryKey)
						self.accessoryNode = loadI3DFile(i3dFilename, false, false, false)

						if self.accessoryNode ~= nil then
							link(self.playerAccessoryNode, self.accessoryNode)

							self.selectedAccessoryIndex = accessoryIndex
							result = true
						end
					end

					delete(xmlFile)
				end
			end
		end
	else
		g_logManager:devError("-- [PlayerStyle:setAccessory] Player not set. Missing call to PlayerStyle:loadXML().")
	end

	return result
end

function PlayerStyle:setProtectiveVisibility(state)
	self.protection.isVisible = state

	if self.player ~= nil then
		if self.protection.helmetNode ~= nil then
			setVisibility(self.protection.helmetNode, state)
		end

		if self.protection.glovesNode ~= nil then
			setVisibility(self.protection.glovesNode, state)
		end

		self:updateHeadWearVisibility()
	else
		g_logManager:devError("-- [PlayerStyle:setProtectiveVisibility] Player not set. Missing call to PlayerStyle:loadXML().")
	end
end

function PlayerStyle:setProtectiveUV(uvs)
	if self.protection.helmetNode ~= nil then
		setShaderParameter(self.protection.helmetNode, "offsetUV", uvs[1], uvs[2], 0, 0, false)
	end

	if self.protection.glovesNode ~= nil then
		setShaderParameter(self.protection.glovesNode, "offsetUV", uvs[1], uvs[2], 0, 0, false)
	end
end

function PlayerStyle:getProtectiveVisibility()
	return self.protection.isVisible
end

function PlayerStyle:updateHeadWearVisibility()
	local isThirdPerson = getVisibility(self.player.meshThirdPerson)

	if isThirdPerson then
		local protectiveGearVisibility = self:getProtectiveVisibility()

		if self.selectedHatIndex > 0 then
			setVisibility(self.hatNode, not protectiveGearVisibility and isThirdPerson)
		elseif self.selectedHairIndex > 0 then
			local currentHairStyleNode = self.hairs.styles[self.selectedHairIndex].node

			setVisibility(currentHairStyleNode, not protectiveGearVisibility)
			setVisibility(self.hairs.hatStyleNode, protectiveGearVisibility)
		end
	end
end

function PlayerStyle:setVisibility(state)
	if self.player ~= nil then
		if self.selectedBodyIndex > 0 then
			local body = self.bodies[self.selectedBodyIndex]

			setVisibility(body.headNode, state)
			setVisibility(body.armsNode, state)
		end

		if self.hatNode ~= nil then
			setVisibility(self.hatNode, state)

			if self.selectedHairIndex > 0 then
				setVisibility(self.hairs.hatStyleNode, state)
			end
		elseif self.selectedHairIndex > 0 then
			local currentHairStyleNode = self.hairs.styles[self.selectedHairIndex].node

			setVisibility(currentHairStyleNode, state)
		end

		if self.accessoryNode ~= nil then
			setVisibility(self.accessoryNode, state)
		end

		if self.selectedJacketIndex > 0 then
			local jacket = self.jackets[self.selectedJacketIndex]

			setVisibility(jacket.node, state)
		end
	else
		g_logManager:devError("-- [PlayerStyle:setVisibility] Player not set. Missing call to PlayerStyle:loadXML().")
	end
end
