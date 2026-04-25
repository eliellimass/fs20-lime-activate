Farmland = {}
local Farmland_mt = Class(Farmland)

function Farmland:new(customMt)
	local self = setmetatable({}, customMt or Farmland_mt)
	self.isOwned = false
	self.xWorldPos = 0
	self.zWorldPos = 0

	return self
end

function Farmland:load(xmlFile, key)
	self.id = getXMLInt(xmlFile, key .. "#id")

	if self.id == nil or self.id == 0 then
		print("Error: Invalid farmland id '" .. tostring(self.id) .. "'!")

		return false
	end

	self.name = Utils.getNoNil(getXMLString(xmlFile, key .. "#name"), "")
	self.areaInHa = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#areaInHa"), 2.5)
	self.fixedPrice = getXMLFloat(xmlFile, key .. "#price")

	if self.fixedPrice == nil then
		self.priceFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#priceScale"), 1)
	end

	self.price = self.fixedPrice or 1

	self:updatePrice()

	local npc = g_npcManager:getNPCByIndex(getXMLInt(xmlFile, key .. "#npcIndex"))
	self.npcIndex = g_npcManager:getRandomIndex()

	if npc ~= nil then
		self.npcIndex = npc.index
	end

	local npc = g_npcManager:getNPCByName(getXMLString(xmlFile, key .. "#npcName"))

	if npc ~= nil then
		self.npcIndex = npc.index
	end

	self.isOwned = false
	self.defaultFarmProperty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#defaultFarmProperty"), false)

	return true
end

function Farmland:delete()
end

function Farmland:setFarmlandIndicatorPosition(xWorldPos, zWorldPos)
	self.zWorldPos = zWorldPos
	self.xWorldPos = xWorldPos
end

function Farmland:setArea(areaInHa)
	self.areaInHa = areaInHa

	if self.fixedPrice == nil then
		self:updatePrice()
	end
end

function Farmland:updatePrice()
	self.price = g_farmlandManager:getPricePerHa() * self.areaInHa * self.priceFactor
end

function Farmland:getNPC()
	return g_npcManager:getNPCByIndex(self.npcIndex)
end
