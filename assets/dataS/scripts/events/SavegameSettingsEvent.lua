SavegameSettingsEvent = {}
local SavegameSettingsEvent_mt = Class(SavegameSettingsEvent, Event)

InitStaticEventClass(SavegameSettingsEvent, "SavegameSettingsEvent", EventIds.EVENT_SAVEGAME_SETTTINGS)

function SavegameSettingsEvent:emptyNew()
	local self = Event:new(SavegameSettingsEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function SavegameSettingsEvent:new()
	local self = SavegameSettingsEvent:emptyNew()

	return self
end

function SavegameSettingsEvent:readStream(streamId, connection)
	local timeScale = streamReadFloat32(streamId)
	local economicDifficulty = streamReadUIntN(streamId, 3)
	local plantGrowthRate = streamReadInt32(streamId)
	local isPlantWitheringEnabled = streamReadBool(streamId)
	local fruitDestruction = streamReadBool(streamId)
	local plowingRequired = streamReadBool(streamId)
	local limeRequired = streamReadBool(streamId)
	local weedsEnabled = streamReadBool(streamId)
	local automaticMotorStartEnabled = streamReadBool(streamId)
	local trafficEnabled = streamReadBool(streamId)
	local stopAndGoBraking = streamReadBool(streamId)
	local savegameName = streamReadString(streamId)
	local dirtInterval = streamReadUIntN(streamId, 3)
	local autoSaveInterval = streamReadInt32(streamId)
	local fuelUsageLow = streamReadBool(streamId)
	local helperBuyFuel = streamReadBool(streamId)
	local helperBuySeeds = streamReadBool(streamId)
	local helperBuyFertilizer = streamReadBool(streamId)
	local helperSlurrySource = streamReadUIntN(streamId, 4)
	local helperManureSource = streamReadUIntN(streamId, 4)

	if connection:getIsServer() or g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		g_currentMission:setTimeScale(timeScale, true)
		g_currentMission:setEconomicDifficulty(economicDifficulty, true)
		g_currentMission:setPlantGrowthRate(plantGrowthRate, true)
		g_currentMission:setPlantWitheringEnabled(isPlantWitheringEnabled, true)
		g_currentMission:setFruitDestructionEnabled(fruitDestruction, true)
		g_currentMission:setPlowingRequiredEnabled(plowingRequired, true)
		g_currentMission:setLimeRequired(limeRequired, true)
		g_currentMission:setWeedsEnabled(weedsEnabled, true)
		g_currentMission:setSavegameName(savegameName, true)
		g_currentMission:setDirtInterval(dirtInterval, true)
		g_currentMission:setAutoSaveInterval(autoSaveInterval, true)
		g_currentMission:setAutomaticMotorStartEnabled(automaticMotorStartEnabled, true)
		g_currentMission:setTrafficEnabled(trafficEnabled, true)
		g_currentMission:setHelperBuyFuel(helperBuyFuel, true)
		g_currentMission:setHelperBuySeeds(helperBuySeeds, true)
		g_currentMission:setHelperBuyFertilizer(helperBuyFertilizer, true)
		g_currentMission:setHelperSlurrySource(helperSlurrySource, true)
		g_currentMission:setHelperManureSource(helperManureSource, true)
		g_currentMission:setFuelUsageLow(fuelUsageLow, true)
		g_currentMission:setStopAndGoBraking(stopAndGoBraking, true)

		if not connection:getIsServer() then
			g_server:broadcastEvent(self, false, connection)
		end
	end
end

function SavegameSettingsEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, g_currentMission.missionInfo.timeScale)
	streamWriteUIntN(streamId, g_currentMission.missionInfo.economicDifficulty, 3)
	streamWriteInt32(streamId, g_currentMission.missionInfo.plantGrowthRate)
	streamWriteBool(streamId, g_currentMission.missionInfo.isPlantWitheringEnabled)
	streamWriteBool(streamId, g_currentMission.missionInfo.fruitDestruction)
	streamWriteBool(streamId, g_currentMission.missionInfo.plowingRequiredEnabled)
	streamWriteBool(streamId, g_currentMission.missionInfo.limeRequired)
	streamWriteBool(streamId, g_currentMission.missionInfo.weedsEnabled)
	streamWriteBool(streamId, g_currentMission.missionInfo.automaticMotorStartEnabled)
	streamWriteBool(streamId, g_currentMission.missionInfo.trafficEnabled)
	streamWriteBool(streamId, g_currentMission.missionInfo.stopAndGoBraking)
	streamWriteString(streamId, g_currentMission.missionInfo.savegameName)
	streamWriteUIntN(streamId, g_currentMission.missionInfo.dirtInterval, 3)
	streamWriteInt32(streamId, g_autoSaveManager:getInterval())
	streamWriteBool(streamId, g_currentMission.missionInfo.fuelUsageLow)
	streamWriteBool(streamId, g_currentMission.missionInfo.helperBuyFuel)
	streamWriteBool(streamId, g_currentMission.missionInfo.helperBuySeeds)
	streamWriteBool(streamId, g_currentMission.missionInfo.helperBuyFertilizer)
	streamWriteUIntN(streamId, g_currentMission.missionInfo.helperSlurrySource, 4)
	streamWriteUIntN(streamId, g_currentMission.missionInfo.helperManureSource, 4)
end

function SavegameSettingsEvent:run(connection)
	print("Error: SavegameSettingsEvent is not allowed to be executed on a local client")
end

function SavegameSettingsEvent.sendEvent(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(SavegameSettingsEvent:new(), false)
		else
			g_client:getServerConnection():sendEvent(SavegameSettingsEvent:new())
		end
	end
end
