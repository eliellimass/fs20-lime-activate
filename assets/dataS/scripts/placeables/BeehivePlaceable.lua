BeehivePlaceable = {}
local BeehivePlaceable_mt = Class(BeehivePlaceable, Placeable)

InitStaticObjectClass(BeehivePlaceable, "BeehivePlaceable", ObjectIds.OBJECT_BEEHIVE_PLACEABLE)

function BeehivePlaceable:new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = BeehivePlaceable_mt
	end

	local self = Placeable:new(isServer, isClient, mt)

	registerObjectClassName(self, "BeehivePlaceable")

	return self
end

function BeehivePlaceable:delete()
	unregisterObjectClassName(self)
	g_currentMission.environment:removeHourChangeListener(self)

	if self.particleSystem ~= nil then
		ParticleUtil.deleteParticleSystem(self.particleSystem)
	end

	BeehivePlaceable:superClass().delete(self)
end

function BeehivePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not BeehivePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	self.particleSystem = {}

	ParticleUtil.loadParticleSystem(xmlFile, self.particleSystem, "placeable.particleSystem", self.nodeId, true, nil, self.baseDirectory)
	delete(xmlFile)

	return true
end

function BeehivePlaceable:hourChanged()
	if self.isServer then
		g_currentMission:addMoney(self.incomePerHour, self:getOwnerFarmId(), MoneyType.PROPERTY_INCOME, true)
	end
end
