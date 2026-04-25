HeatingPlantPlaceable = {}
local HeatingPlantPlaceable_mt = Class(HeatingPlantPlaceable, Placeable)

InitStaticObjectClass(HeatingPlantPlaceable, "HeatingPlantPlaceable", ObjectIds.OBJECT_HEATING_PLANT_PLACEABLE)

function HeatingPlantPlaceable:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = HeatingPlantPlaceable_mt
	end

	local self = Placeable:new(isServer, isClient, mt)

	registerObjectClassName(self, "HeatingPlantPlaceable")

	self.heatingPlantDirtyFlag = self:getNextDirtyFlag()

	return self
end

function HeatingPlantPlaceable:delete()
	if self.tipTrigger ~= nil then
		self.tipTrigger:removeUpdateEventListener(self)
		self.tipTrigger:delete()
	end

	if self.exhaustEffect ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.exhaustEffect.filename, self.baseDirectory, true)
	end

	g_animationManager:deleteAnimations(self.animationNodes)
	unregisterObjectClassName(self)
	HeatingPlantPlaceable:superClass().delete(self)
end

function HeatingPlantPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not HeatingPlantPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.tipTrigger = TipTrigger:new(self.isServer, self.isClient)

	if self.tipTrigger:load(I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.heatingPlant#tipTrigger"))) then
		self.tipTrigger:register(true)
		self.tipTrigger:addUpdateEventListener(self)
	else
		self.tipTrigger:delete()

		self.tipTrigger = nil
	end

	if self.isClient then
		self.animationNodes = g_animationManager:loadAnimations(xmlFile, "placeable.animationNodes", self.nodeId, self, nil)
		local filename = getXMLString(xmlFile, "placeable.exhaust#filename")
		local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.exhaust#index"))

		if filename ~= nil then
			local i3dNode = g_i3DManager:loadSharedI3DFile(filename, self.baseDirectory, false, false, false)

			if i3dNode ~= 0 then
				self.exhaustEffect = {
					node = getChildAt(i3dNode, 0),
					filename = filename
				}

				link(Utils.getNoNil(node, self.nodeId), self.exhaustEffect.node)
				setVisibility(self.exhaustEffect.node, false)
				setShaderParameter(self.exhaustEffect.node, "param", 0, 0, 0, 0.4, false)
				delete(i3dNode)
			end
		end
	end

	self.workingTimeDuration = 120000
	self.workingTime = 0

	delete(xmlFile)

	return true
end

function HeatingPlantPlaceable:readStream(streamId, connection)
	HeatingPlantPlaceable:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local tipTriggerId = NetworkUtil.readNodeObjectId(streamId)

		self.tipTrigger:readStream(streamId, connection)
		g_client:finishRegisterObject(self.tipTrigger, tipTriggerId)
	end
end

function HeatingPlantPlaceable:writeStream(streamId, connection)
	HeatingPlantPlaceable:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.tipTrigger))
		self.tipTrigger:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, self.tipTrigger)
	end
end

function HeatingPlantPlaceable:readUpdateStream(streamId, timestamp, connection)
	HeatingPlantPlaceable:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		local workingTimeBiggerZero = streamReadBool(streamId)

		if workingTimeBiggerZero then
			self.workingTime = self.workingTimeDuration

			if self.exhaustEffect ~= nil then
				setVisibility(self.exhaustEffect.node, true)
			end
		end
	end
end

function HeatingPlantPlaceable:writeUpdateStream(streamId, connection, dirtyMask)
	HeatingPlantPlaceable:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		streamWriteBool(streamId, self.workingTime > 0)
	end
end

function HeatingPlantPlaceable:collectPickObjects(node)
	if self.tipTrigger == nil or self.tipTrigger.shovelTarget == nil or self.tipTrigger.shovelTarget.nodeId ~= node then
		HeatingPlantPlaceable:superClass().collectPickObjects(self, node)
	end
end

function HeatingPlantPlaceable:update(dt)
	HeatingPlantPlaceable:superClass().update(self, dt)

	if self.isClient and self.workingTime > 0 then
		self.workingTime = self.workingTime - dt

		if self.workingTime <= 0 then
			if self.exhaustEffect ~= nil then
				setVisibility(self.exhaustEffect.node, false)
			end

			g_animationManager:stopAnimations(self.animationNodes)
		end
	end
end

function HeatingPlantPlaceable:updateTick(dt)
	HeatingPlantPlaceable:superClass().updateTick(self, dt)
end

function HeatingPlantPlaceable:onUpdateEvent(trigger, fillDelta, fillType, trailer, tipTriggerTarget)
	if self.exhaustEffect ~= nil then
		setVisibility(self.exhaustEffect.node, true)
	end

	if self.isServer then
		self:raiseDirtyFlags(self.heatingPlantDirtyFlag)
	end

	self.workingTime = self.workingTimeDuration

	g_animationManager:startAnimations(self.animationNodes)
end
