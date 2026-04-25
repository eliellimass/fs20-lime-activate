FinanceStatsEvent = {}
local FinanceStatsEvent_mt = Class(FinanceStatsEvent, Event)

InitStaticEventClass(FinanceStatsEvent, "FinanceStatsEvent", EventIds.EVENT_FINANCE_STATS)

function FinanceStatsEvent:emptyNew()
	local self = Event:new(FinanceStatsEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function FinanceStatsEvent:new(historyIndex, farmId)
	local self = FinanceStatsEvent:emptyNew()
	self.historyIndex = historyIndex
	self.farmId = farmId

	assert(historyIndex >= 0 and historyIndex <= 255)

	return self
end

function FinanceStatsEvent:readStream(streamId, connection)
	self.historyIndex = streamReadUInt8(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if connection:getIsServer() then
		local farm = g_farmManager:getFarmById(self.farmId)
		local stats = farm.stats
		local financesHistoryVersionCounter = streamReadUIntN(streamId, 7)
		stats.financesHistoryVersionCounter = financesHistoryVersionCounter

		if streamReadBool(streamId) then
			local finances = nil

			if self.historyIndex == 0 then
				finances = stats.finances
			else
				local numHistoryEntries = #stats.financesHistory

				if numHistoryEntries < self.historyIndex then
					for i = 1, self.historyIndex - numHistoryEntries do
						table.insert(stats.financesHistory, 1, FinanceStats:new())
					end

					numHistoryEntries = self.historyIndex
				end

				finances = stats.financesHistory[numHistoryEntries - self.historyIndex + 1]
			end

			for _, statName in ipairs(FinanceStats.statNames) do
				local money = streamReadFloat32(streamId)
				finances[statName] = money
			end
		end
	else
		connection:sendEvent(self)
	end
end

function FinanceStatsEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.historyIndex)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if not connection:getIsServer() then
		local stats = g_farmManager:getFarmById(self.farmId).stats
		local financesHistoryVersionCounter = stats.financesHistoryVersionCounter

		streamWriteUIntN(streamId, financesHistoryVersionCounter, 7)

		local finances = nil

		if self.historyIndex == 0 then
			finances = stats.finances
		else
			local numHistoryEntries = #stats.financesHistory

			if self.historyIndex <= numHistoryEntries then
				finances = stats.financesHistory[numHistoryEntries - self.historyIndex + 1]
			end
		end

		if streamWriteBool(streamId, finances ~= nil and self.farmId ~= FarmManager.SPECTATOR_FARM_ID) then
			for _, statName in ipairs(FinanceStats.statNames) do
				local money = Utils.getNoNil(finances[statName], 0)

				streamWriteFloat32(streamId, money)
			end
		end
	end
end

function FinanceStatsEvent:run(connection)
	print("Error: FinanceStatsEvent is not allowed to be executed on a local client")
end
