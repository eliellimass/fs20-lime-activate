BuyableBale = {
	initSpecialization = function ()
		g_configurationManager:addConfigurationType("buyableBaleAmount", g_i18n:getText("configuration_buyableBaleAmount"), nil, , , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	end,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function BuyableBale.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBaleAtPosition", BuyableBale.loadBaleAtPosition)
end

function BuyableBale.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BuyableBale)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BuyableBale)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BuyableBale)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BuyableBale)
end

function BuyableBale:onLoad(savegame)
	local spec = self.spec_buyableBale
	spec.loadedBales = {}
	spec.baleFilename = getXMLString(self.xmlFile, "vehicle.buyableBale#filename")
	spec.isWrapped = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.buyableBale#isWrapped"), false)
	local positionOffset = {
		0,
		0,
		0
	}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.buyableBale.offsets.offset(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local offset = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, baseKey .. "#offset"), 3)
		local amount = getXMLInt(self.xmlFile, baseKey .. "#amount")

		if amount <= self.configurations.buyableBaleAmount then
			positionOffset = offset
		end

		i = i + 1
	end

	spec.positions = {}
	i = 0

	while true do
		local baseKey = string.format("vehicle.buyableBale.balePositions.balePosition(%d)", i)

		if not hasXMLProperty(self.xmlFile, baseKey) then
			break
		end

		local position = StringUtil.getVectorNFromString(getXMLString(self.xmlFile, baseKey .. "#position"), 3)
		local rotation = StringUtil.getRadiansFromString(getXMLString(self.xmlFile, baseKey .. "#rotation"), 3)

		if position ~= nil and rotation ~= nil then
			if positionOffset ~= nil then
				for j = 1, 3 do
					position[j] = position[j] + positionOffset[j]
				end
			end

			table.insert(spec.positions, {
				position = position,
				rotation = rotation
			})
		end

		i = i + 1
	end
end

function BuyableBale:onLoadFinished(savegame)
	local spec = self.spec_buyableBale

	for j, position in ipairs(spec.positions) do
		if j <= self.configurations.buyableBaleAmount then
			self:loadBaleAtPosition(position)
		end
	end
end

function BuyableBale:loadBaleAtPosition(position)
	local spec = self.spec_buyableBale

	if self.isServer or self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		local x, y, z = localToWorld(self.components[1].node, unpack(position.position))
		local rx, ry, rz = localRotationToWorld(self.components[1].node, unpack(position.rotation))
		local baleObject = Bale:new(self.isServer, self.isClient)

		baleObject:load(spec.baleFilename, x, y, z, rx, ry, rz)
		baleObject:setOwnerFarmId(self:getActiveFarm(), true)

		if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
			baleObject:register()
		end

		baleObject:setCanBeSold(false)

		if spec.isWrapped then
			baleObject:setWrappingState(1)

			if self.configurations.baseColor ~= nil then
				local color = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor)

				baleObject:setColor(unpack(color))
			end
		end

		setPairCollision(self.components[1].node, baleObject.nodeId, false)
		table.insert(spec.loadedBales, baleObject)
	end
end

function BuyableBale:onDelete()
	if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		local spec = self.spec_buyableBale

		for _, bale in ipairs(spec.loadedBales) do
			bale:delete()
		end
	end
end

function BuyableBale:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer and self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		g_currentMission:removeVehicle(self)
	end
end
