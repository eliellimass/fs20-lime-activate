ParticleSystemManager = {}
ParticleType = nil
local ParticleSystemManager_mt = Class(ParticleSystemManager, AbstractManager)

function ParticleSystemManager:new(customMt)
	local self = AbstractManager:new(customMt or ParticleSystemManager_mt)

	return self
end

function ParticleSystemManager:initDataStructures()
	self.nameToIndex = {}
	self.particleTypes = {}
	self.particleSystems = {}
end

function ParticleSystemManager:loadMapData()
	ParticleSystemManager:superClass().loadMapData(self)
	self:addParticleType("unloading")
	self:addParticleType("smoke")
	self:addParticleType("chopper")
	self:addParticleType("straw")
	self:addParticleType("cutter_chopper")
	self:addParticleType("soil")
	self:addParticleType("soil_smoke")
	self:addParticleType("soil_chunks")
	self:addParticleType("soil_big_chunks")
	self:addParticleType("soil_harvesting")
	self:addParticleType("spreader")
	self:addParticleType("spreader_smoke")
	self:addParticleType("windrower")
	self:addParticleType("tedder")
	self:addParticleType("weeder")
	self:addParticleType("crusher_wood")
	self:addParticleType("crusher_dust")
	self:addParticleType("prepare_fruit")
	self:addParticleType("cleaning_soil")
	self:addParticleType("cleaning_dust")
	self:addParticleType("washer_water")
	self:addParticleType("chainsaw_wood")
	self:addParticleType("chainsaw_dust")
	self:addParticleType("pickup")
	self:addParticleType("pickup_falling")
	self:addParticleType("sowing")
	self:addParticleType("loading")
	self:addParticleType("driving_dust")
	self:addParticleType("driving_dry")
	self:addParticleType("driving_wet")

	ParticleType = self.nameToIndex

	return true
end

function ParticleSystemManager:unloadMapData()
	for _, fillTypeParticleSystem in pairs(self.particleSystems) do
		for _, ps in pairs(fillTypeParticleSystem) do
			ParticleUtil.deleteParticleSystem(ps)
		end
	end

	ParticleSystemManager:superClass().unloadMapData(self)
end

function ParticleSystemManager:addParticleType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a particleType. Ignoring it!")

		return nil
	end

	name = name:upper()

	if self.nameToIndex[name] == nil then
		table.insert(self.particleTypes, name)

		self.nameToIndex[name] = #self.particleTypes
	end
end

function ParticleSystemManager:getParticleSystemTypeByName(name)
	if name ~= nil then
		name = name:upper()

		if self.nameToIndex[name] ~= nil then
			return name
		end
	end

	return nil
end

function ParticleSystemManager:addParticleSystem(fillTypeIndex, particleType, particleSystem)
	if self.particleSystems[fillTypeIndex] == nil then
		self.particleSystems[fillTypeIndex] = {}
	end

	if self.particleSystems[fillTypeIndex][particleType] ~= nil then
		if g_showDevelopmentWarnings then
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

			print("DevWarning: particle system type '" .. tostring(particleType) .. "' already exists for fillType '" .. tostring(fillType.name) .. "'. It will be overwritten!")
		end

		ParticleUtil.deleteParticleSystem(self.particleSystems[fillTypeIndex][particleType])
	end

	self.particleSystems[fillTypeIndex][particleType] = particleSystem
end

function ParticleSystemManager:getParticleSystem(fillType, particleTypeName)
	if fillType == nil or particleTypeName == nil then
		return nil
	end

	local particleType = self:getParticleSystemTypeByName(particleTypeName)

	if particleType == nil then
		return nil
	end

	local fillTypeParticles = self.particleSystems[fillType]

	if fillTypeParticles == nil then
		return nil
	end

	return fillTypeParticles[particleType]
end

g_particleSystemManager = ParticleSystemManager:new()
