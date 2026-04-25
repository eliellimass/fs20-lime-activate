WoodCrusherPlaceable = {}
local WoodCrusherPlaceable_mt = Class(WoodCrusherPlaceable, Placeable)

InitStaticObjectClass(WoodCrusherPlaceable, "WoodCrusherPlaceable", ObjectIds.OBJECT_WOOD_CRUSHER_PLACEABLE)

function WoodCrusherPlaceable:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = WoodCrusherPlaceable_mt
	end

	local self = Placeable:new(isServer, isClient, mt)

	registerObjectClassName(self, "WoodCrusherPlaceable")

	self.lastMoneyChange = -1
	self.turnOnNextTick = false
	self.woodCrusher = {}

	return self
end

function WoodCrusherPlaceable:delete()
	if self.woodCrusherLoaded ~= nil then
		WoodCrusher.deleteWoodCrusher(self, self.woodCrusher)
	end

	unregisterObjectClassName(self)
	WoodCrusherPlaceable:superClass().delete(self)
end

function WoodCrusherPlaceable:finalizePlacement()
	WoodCrusherPlaceable:superClass().finalizePlacement(self)

	local xmlFile = loadXMLFile("TempXML", self.configFileName)

	WoodCrusher.loadWoodCrusher(self, self.woodCrusher, xmlFile, self.nodeId)

	for _, node in pairs(self.woodCrusher.moveColNodes) do
		setPairCollision(self.nodeId, node, false)
	end

	self.priceScale = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.woodCrusher#priceScale"), 0.8)

	delete(xmlFile)

	self.woodCrusherLoaded = true
	self.turnOnNextTick = true
end

function WoodCrusherPlaceable:update(dt)
	WoodCrusherPlaceable:superClass().update(self, dt)

	if self.woodCrusherLoaded then
		if self.turnOnNextTick then
			WoodCrusher.turnOnWoodCrusher(self, self.woodCrusher)

			self.turnOnNextTick = false
		end

		WoodCrusher.updateWoodCrusher(self, self.woodCrusher, dt, true)
	end
end

function WoodCrusherPlaceable:updateTick(dt)
	WoodCrusherPlaceable:superClass().updateTick(self, dt)

	if self.woodCrusherLoaded then
		WoodCrusher.updateTickWoodCrusher(self, self.woodCrusher, dt, true)

		if self.lastMoneyChange > 0 then
			self.lastMoneyChange = self.lastMoneyChange - dt

			if self.lastMoneyChange <= 0 then
				g_currentMission:showMoneyChange(MoneyType.SOLD_WOOD, nil, false, self:getOwnerFarmId())
			end

			self:raiseActive()
		end
	end
end

function WoodCrusherPlaceable:onCrushedSplitShape(splitType, volume)
	local money = volume * 1000 * splitType.woodChipsPerLiter * g_currentMission.economyManager:getPricePerLiter(FillType.WOODCHIPS) * self.priceScale

	g_currentMission:addMoney(money, self:getOwnerFarmId(), MoneyType.SOLD_WOOD, true)

	self.lastMoneyChange = 2500
end
