PreorderBonusManager = {
	TRY_TO_SPAWN_TIME = 60000,
	BONUS_FARM_ID = 1
}
local PreorderBonusManager_mt = Class(PreorderBonusManager, AbstractManager)

function PreorderBonusManager:new(customMt)
	self = AbstractManager:new(customMt or PreorderBonusManager_mt)
	self.spawnedMods = {}
	self.modsToSpawn = {}
	self.timer = 0

	return self
end

function PreorderBonusManager:loadFinished()
	for _, mod in pairs(g_modManager:getMods()) do
		if mod.isPreorderBonus then
			self.modsToSpawn[mod.modDir] = mod
		end
	end
end

function PreorderBonusManager:loadVehiclesFinish(xmlFile, xmlFilename, resetVehicles)
	local i = 0

	while true do
		local key = string.format("vehicles.spawnedPreorderBonus(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local modDir = getXMLString(xmlFile, key .. "#modDir")

		if modDir ~= nil then
			self:setModSpawned(modDir)
		end

		i = i + 1
	end
end

function PreorderBonusManager:saveVehicleList(xmlFile, key, vehicles, usedModNames)
	local i = 0

	for modDir, _ in pairs(self.spawnedMods) do
		setXMLString(xmlFile, string.format("%s.spawnedPreorderBonus(%d)#modDir", key, i), modDir)

		i = i + 1
	end
end

function PreorderBonusManager:update(dt)
	if next(self.modsToSpawn) ~= nil then
		self.timer = self.timer - dt

		if self.timer <= 0 then
			for _, mod in pairs(self.modsToSpawn) do
				self:spawnBonus(mod)
			end

			self.timer = PreorderBonusManager.TRY_TO_SPAWN_TIME
		end
	end
end

function PreorderBonusManager:spawnBonus(mod)
	local items = g_storeManager:getItemByCustomEnvironment(mod.modName)

	for _, item in ipairs(items) do
		if fileExists(item.xmlFilename) then
			local asyncParams = {
				targetOwner = self,
				mod = mod
			}

			g_currentMission:loadVehiclesAtPlace(item, g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, {}, 0, Vehicle.PROPERTY_STATE_OWNED, PreorderBonusManager.BONUS_FARM_ID, self.onPreorderBonusSpawnCallack, self, asyncParams)
		end
	end
end

function PreorderBonusManager:onPreorderBonusSpawnCallack(code, params)
	if code == BaseMission.VEHICLE_LOAD_OK then
		self:setModSpawned(params.mod.modDir)
	end
end

function PreorderBonusManager:setModSpawned(modDir)
	self.spawnedMods[modDir] = self.modsToSpawn[modDir]
	self.modsToSpawn[modDir] = nil
end
