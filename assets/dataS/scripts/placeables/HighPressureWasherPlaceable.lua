HighPressureWasher = {}
local HighPressureWasher_mt = Class(HighPressureWasher, Placeable)

source("dataS/scripts/placeables/HPWPlaceableTurnOnEvent.lua")
InitStaticObjectClass(HighPressureWasher, "HighPressureWasher", ObjectIds.OBJECT_HIGHPRESSURE_WASHER_PLACEABLE)

function HighPressureWasher:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = HighPressureWasher_mt
	end

	local self = Placeable:new(isServer, isClient, mt)

	registerObjectClassName(self, "HighPressureWasher")

	return self
end

function HighPressureWasher:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not HighPressureWasher:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.lanceNode = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.highPressureWasher.lance#node"))
	self.handtoolXML = Utils.getFilename(getXMLString(xmlFile, "placeable.highPressureWasher.handtool#filename"), self.baseDirectory)
	self.playerInRangeDistance = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.highPressureWasher.playerInRangeDistance"), 3)
	self.actionRadius = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.highPressureWasher.actionRadius#distance"), 15)

	if self.isClient then
		self.hpwSamples = {}

		if self.isClient then
			self.hpwSamples.compressor = g_soundManager:loadSampleFromXML(xmlFile, "placeable.highPressureWasher.sounds", "compressor", self.baseDirectory, self.nodeId, 0, AudioGroup.VEHICLE, nil, self)
			self.hpwSamples.switch = g_soundManager:loadSampleFromXML(xmlFile, "placeable.highPressureWasher.sounds", "switch", self.baseDirectory, self.nodeId, 1, AudioGroup.VEHICLE, nil, self)
		end

		local filename = getXMLString(xmlFile, "placeable.highPressureWasher.exhaust#filename")

		if filename ~= nil then
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				local linkNode = Utils.getNoNil(I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.highPressureWasher.exhaust#index")), self.nodeId)
				self.exhaustFilename = filename
				self.exhaustNode = getChildAt(i3dNode, 0)

				link(linkNode, self.exhaustNode)
				setVisibility(self.exhaustNode, false)
				delete(i3dNode)
			end
		end
	end

	delete(xmlFile)

	self.isPlayerInRange = false
	self.isTurnedOn = false
	self.isTurningOff = false
	self.turnOffTime = 0
	self.turnOffDuration = 500
	self.activatable = HighPressureWasherActivatable:new(self)
	self.lastInRangePosition = {
		0,
		0,
		0
	}

	return true
end

function HighPressureWasher:delete()
	self:setIsTurnedOn(false, nil, false)

	if self.isClient then
		if self.exhaustFilename ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.exhaustFilename, self.baseDirectory, true)
		end

		g_soundManager:deleteSamples(self.hpwSamples)
	end

	unregisterObjectClassName(self)
	g_currentMission:removeActivatableObject(self.activatable)
	HighPressureWasher:superClass().delete(self)
end

function HighPressureWasher:readStream(streamId, connection)
	HighPressureWasher:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local isTurnedOn = streamReadBool(streamId)

		if isTurnedOn then
			local player = NetworkUtil.readNodeObject(streamId)

			if player ~= nil then
				self:setIsTurnedOn(isTurnedOn, player, true)
			end
		end
	end
end

function HighPressureWasher:writeStream(streamId, connection)
	HighPressureWasher:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteBool(streamId, self.isTurnedOn)

		if self.isTurnedOn then
			NetworkUtil.writeNodeObject(streamId, self.currentPlayer)
		end
	end
end

function HighPressureWasher:activateHandtool(player)
	self:setIsTurnedOn(true, player, true)
end

function HighPressureWasher:update(dt)
	HighPressureWasher:superClass().update(self, dt)

	if self.currentPlayer ~= nil then
		local isPlayerInRange = self:getIsPlayerInRange(self.actionRadius, self.currentPlayer)

		if isPlayerInRange then
			self.lastInRangePosition = {
				getTranslation(self.currentPlayer.rootNode)
			}
		else
			local kx, _, kz = getWorldTranslation(self.nodeId)
			local px, py, pz = getWorldTranslation(self.currentPlayer.rootNode)
			local len = MathUtil.vector2Length(px - kx, pz - kz)
			local x, y, z = unpack(self.lastInRangePosition)
			x = kx + (px - kx) / len * (self.actionRadius - 1e-05 * dt)
			z = kz + (pz - kz) / len * (self.actionRadius - 1e-05 * dt)

			self.currentPlayer:moveToAbsoluteInternal(x, py, z)

			self.lastInRangePosition = {
				x,
				y,
				z
			}

			if self.currentPlayer == g_currentMission.player then
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_hpwRangeRestriction"), 4000)
			end
		end
	end

	if self.isClient and self.isTurningOff and self.turnOffTime < g_currentMission.time then
		self.isTurningOff = false

		g_soundManager:stopSample(self.hpwSamples.compressor)
	end

	self:raiseActive()
end

function HighPressureWasher:getHighPressureWasherLoad()
	if self.isTurningOff then
		if g_currentMission.time < self.turnOffTime then
			return MathUtil.clamp((self.turnOffTime - g_currentMission.time) / self.turnOffDuration, 0, 1)
		end

		return 0
	end

	return 1
end

g_soundManager:registerModifierType("HIGH_PRESSURE_WASHER_LOAD", HighPressureWasher.getHighPressureWasherLoad)

function HighPressureWasher:updateTick(dt)
	HighPressureWasher:superClass().updateTick(self, dt)

	local isPlayerInRange, player = self:getIsPlayerInRange(self.playerInRangeDistance)

	if isPlayerInRange and g_currentMission.accessHandler:canPlayerAccess(self, player) then
		self.playerInRange = player
		self.isPlayerInRange = true

		g_currentMission:addActivatableObject(self.activatable)
	else
		self.playerInRange = nil
		self.isPlayerInRange = false

		g_currentMission:removeActivatableObject(self.activatable)
	end
end

function HighPressureWasher:setIsTurnedOn(isTurnedOn, player, noEventSend)
	HPWPlaceableTurnOnEvent.sendEvent(self, isTurnedOn, player, noEventSend)

	if self.isTurnedOn ~= isTurnedOn then
		if isTurnedOn then
			self.isTurnedOn = isTurnedOn

			if player ~= nil then
				self.currentPlayer = player

				self.currentPlayer:addDeleteListener(self, "onPlayerDelete")

				if noEventSend ~= true then
					self.currentPlayer:equipHandtool(self.handtoolXML, true, noEventSend)
					self.currentPlayer.baseInformation.currentHandtool:addDeleteListener(self, "onHandtoolDelete")
				end
			end

			if self.isClient then
				g_soundManager:playSample(self.hpwSamples.switch)
				g_soundManager:playSample(self.hpwSamples.compressor)

				if self.isTurningOff then
					self.isTurningOff = false
				end

				setVisibility(self.lanceNode, false)
			end
		else
			self:onDeactivate()
		end

		if self.exhaustNode ~= nil then
			setVisibility(self.exhaustNode, isTurnedOn)
		end
	end
end

function HighPressureWasher:onPlayerDelete()
	self.currentPlayer = nil

	self:setIsTurnedOn(false, nil, )
end

function HighPressureWasher:onHandtoolDelete()
	self.currentPlayer = nil

	self:setIsTurnedOn(false, nil, )
end

function HighPressureWasher:onDeactivate()
	if self.isClient then
		g_soundManager:playSample(self.hpwSamples.switch)
		g_soundManager:stopSample(self.hpwSamples.washing, true)

		self.isTurningOff = true
		self.turnOffTime = g_currentMission.time + self.turnOffDuration
	end

	self.isTurnedOn = false

	setVisibility(self.lanceNode, true)

	if self.currentPlayer ~= nil then
		if self.currentPlayer:hasHandtoolEquipped() then
			self.currentPlayer.baseInformation.currentHandtool:removeDeleteListener(self, "onHandtoolDelete")
			self.currentPlayer:unequipHandtool()
		end

		self.currentPlayer:removeDeleteListener(self, "onPlayerDelete")

		self.currentPlayer = nil
	end
end

function HighPressureWasher:getIsActiveForInput()
	if self.isTurnedOn and self.currentPlayer == g_currentMission.player and not g_gui:getIsGuiVisible() then
		return true
	end

	return false
end

function HighPressureWasher:getIsActiveForSound()
	return self:getIsActiveForInput()
end

function HighPressureWasher:canBeSold()
	local warning = g_i18n:getText("shop_messageReturnVehicleInUse")

	if self.currentPlayer ~= nil then
		return false, warning
	end

	return true, nil
end

HighPressureWasherActivatable = {}
local HighPressureWasherActivatable_mt = Class(HighPressureWasherActivatable)

function HighPressureWasherActivatable:new(highPressureWasher)
	local self = {}

	setmetatable(self, HighPressureWasherActivatable_mt)

	self.highPressureWasher = highPressureWasher
	self.activateText = "unknown"

	return self
end

function HighPressureWasherActivatable:getIsActivatable()
	if not self.highPressureWasher.isPlayerInRange then
		return false
	end

	if self.highPressureWasher.playerInRange ~= g_currentMission.player then
		return false
	end

	if not self.highPressureWasher.playerInRange.isControlled then
		return false
	end

	if self.highPressureWasher.isTurnedOn and self.highPressureWasher.currentPlayer ~= g_currentMission.player then
		return false
	end

	local hasHPWLance = self.currentPlayer ~= nil and self.currentPlayer:hasHandtoolEquipped() and self.currentPlayer.baseInformation.currentHandtool.isHPWLance

	if not self.highPressureWasher.isTurnedOn and hasHPWLance then
		return false
	end

	if self.highPressureWasher.isDeleted then
		return false
	end

	self:updateActivateText()

	return true
end

function HighPressureWasherActivatable:onActivateObject()
	self.highPressureWasher:setIsTurnedOn(not self.highPressureWasher.isTurnedOn, g_currentMission.player)
	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end

function HighPressureWasherActivatable:drawActivate()
end

function HighPressureWasherActivatable:updateActivateText()
	if self.highPressureWasher.isTurnedOn then
		self.activateText = string.format(g_i18n:getText("action_turnOffOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
	else
		self.activateText = string.format(g_i18n:getText("action_turnOnOBJECT"), g_i18n:getText("typeDesc_highPressureWasher"))
	end
end
