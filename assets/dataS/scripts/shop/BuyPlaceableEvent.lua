BuyPlaceableEvent = {}
local BuyPlaceableEvent_mt = Class(BuyPlaceableEvent, Event)
BuyPlaceableEvent.STATE_SUCCESS = 0
BuyPlaceableEvent.STATE_FAILED_TO_LOAD = 1
BuyPlaceableEvent.STATE_NO_SPACE = 2
BuyPlaceableEvent.STATE_NO_PERMISSION = 3
BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 4
BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED = 5

InitStaticEventClass(BuyPlaceableEvent, "BuyPlaceableEvent", EventIds.EVENT_BUY_PLACEABLE)

function BuyPlaceableEvent:emptyNew()
	local self = Event:new(BuyPlaceableEvent_mt)

	return self
end

function BuyPlaceableEvent:new(filename, x, y, z, rx, ry, rz, displacementCosts, ownerFarmId, modifyTerrain)
	local self = BuyPlaceableEvent:emptyNew()
	self.filename = filename
	self.x = x
	self.y = y
	self.z = z
	self.rx = rx
	self.ry = ry
	self.rz = rz
	self.displacementCosts = displacementCosts
	self.ownerFarmId = ownerFarmId
	self.modifyTerrain = modifyTerrain

	return self
end

function BuyPlaceableEvent:newServerToClient(errorCode, price)
	local self = BuyPlaceableEvent:emptyNew()
	self.errorCode = errorCode
	self.price = price

	return self
end

function BuyPlaceableEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.rx = streamReadFloat32(streamId)
		self.ry = streamReadFloat32(streamId)
		self.rz = streamReadFloat32(streamId)
		self.displacementCosts = streamReadInt32(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.modifyTerrain = streamReadBool(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.price = streamReadInt32(streamId)
	end

	self:run(connection)
end

function BuyPlaceableEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rx)
		streamWriteFloat32(streamId, self.ry)
		streamWriteFloat32(streamId, self.rz)
		streamWriteInt32(streamId, self.displacementCosts)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteBool(streamId, self.modifyTerrain)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteInt32(streamId, self.price)
	end
end

function BuyPlaceableEvent:run(connection)
	if not connection:getIsServer() then
		local errorCode = BuyPlaceableEvent.STATE_FAILED_TO_LOAD
		local price = 0

		if not g_currentMission:getHasPlayerPermission("buyPlaceable", connection) then
			errorCode = BuyPlaceableEvent.STATE_NO_PERMISSION
		else
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)

			if dataStoreItem ~= nil then
				price, _ = g_currentMission.economyManager:getBuyPrice(dataStoreItem)
				price = price + self.displacementCosts

				if price <= g_currentMission:getMoney(self.ownerFarmId) then
					local placeable, hasNoSpace = PlacementUtil.loadPlaceableFromXML(self.filename, self.x, self.y, self.z, self.rx, self.ry, self.rz, false, self.ownerFarmId)

					if placeable ~= nil then
						if GS_IS_CONSOLE_VERSION and not fileExists(self.filename) then
							placeable:delete()
						else
							local modifyHandler = {
								price = price,
								placeable = placeable,
								connection = connection,
								self = self,
								callback = function (handler, errorCode, displacedVolume, blockedObjectName)
									local self = handler.self

									if errorCode ~= TerrainDeformation.STATE_SUCCESS then
										handler.placeable:delete()
										handler.connection:sendEvent(BuyPlaceableEvent:newServerToClient(BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED, handler.price))
									else
										handler.placeable:finalizePlacement()
										handler.placeable:clearFoliageAndTipAreas()
										handler.placeable:register()
										g_currentMission:addMoney(-handler.price, self.ownerFarmId, MoneyType.SHOP_PROPERTY_BUY, true)
										handler.placeable:onBuy()
										handler.connection:sendEvent(BuyPlaceableEvent:newServerToClient(BuyPlaceableEvent.STATE_SUCCESS, handler.price))
									end
								end
							}
							local deform = nil

							if self.modifyTerrain then
								deform = placeable:createDeformationObject(g_currentMission.terrainRootNode)
							end

							g_terrainDeformationQueue:queueJob(deform, false, "callback", modifyHandler)

							return
						end
					elseif hasNoSpace then
						errorCode = BuyPlaceableEvent.STATE_NO_SPACE
					end
				else
					errorCode = BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY
				end
			end
		end

		connection:sendEvent(BuyPlaceableEvent:newServerToClient(errorCode, price))
	else
		g_messageCenter:publish(BuyPlaceableEvent, self.errorCode, self.price)
	end
end
