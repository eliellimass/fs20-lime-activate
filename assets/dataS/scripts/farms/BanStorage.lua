BanStorage = {}
local BanStorage_mt = Class(BanStorage)

function BanStorage:new(customMt)
	local self = {}

	setmetatable(self, customMt or BanStorage_mt)

	self.bans = {}

	return self
end

function BanStorage:delete()
end

function BanStorage:loadFromXMLFile(xmlFilename)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	end

	if xmlFilename == nil then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)

	if not xmlFile then
		return false
	end

	local i = 0

	while true do
		local key = string.format("bans.ban(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local ban = {
			time = getXMLString(xmlFile, key .. "#time"),
			uniqueUserId = getXMLString(xmlFile, key .. "#uniqueUserId"),
			lastNickname = getXMLString(xmlFile, key .. "#lastNickname"),
			reason = HTMLUtil.decodeFromHTML(Utils.getNoNil(getXMLString(xmlFile, key .. "#reason"), ""))
		}

		table.insert(self.bans, ban)

		i = i + 1
	end

	delete(xmlFile)
end

function BanStorage:saveToXMLFile(xmlFilename)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	end

	local xmlFile = createXMLFile("banStorageXML", xmlFilename, "bans")

	if xmlFile ~= nil then
		for k, ban in ipairs(self.bans) do
			local banKey = string.format("bans.ban(%d)", k - 1)

			setXMLString(xmlFile, banKey .. "#uniqueUserId", ban.uniqueUserId)
			setXMLString(xmlFile, banKey .. "#lastNickname", ban.lastNickname)
			setXMLString(xmlFile, banKey .. "#time", ban.time)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end

function BanStorage:setPath(banXmlFilePath)
	self.filePath = banXmlFilePath
end

function BanStorage:isUserBanned(uniqueUserId)
	for _, ban in ipairs(self.bans) do
		if ban.uniqueUserId == uniqueUserId then
			return true
		end
	end

	return false
end

function BanStorage:addUser(uniqueUserId, nickname, saveImmediately)
	if not self:isUserBanned(uniqueUserId) then
		local ban = {
			time = g_i18n:getCurrentDate(),
			uniqueUserId = uniqueUserId,
			lastNickname = nickname,
			reason = "None given"
		}

		table.insert(self.bans, ban)

		if self.filePath ~= nil and saveImmediately == nil or saveImmediately then
			self:saveToXMLFile(self.filePath)
		end
	end
end

function BanStorage:removeUser(uniqueUserId, saveImmediately)
	for i = #self.bans, 1, -1 do
		local banInfo = self.bans[i]

		if banInfo.uniqueUserId == uniqueUserId then
			table.remove(self.bans, i)

			if self.filePath ~= nil and saveImmediately == nil or saveImmediately then
				self:saveToXMLFile(self.filePath)
			end

			break
		end
	end
end

function BanStorage:getBans()
	return self.bans
end

function BanStorage:setBansFromEvent(bans)
	self.bans = bans
end

function BanStorage:removeUserFromClient(lastNickname, index)
	local ban = self.bans[index]

	if ban == nil then
		return false
	end

	if ban.lastNickname ~= lastNickname then
		return false
	end

	self:removeUser(ban.uniqueUserId)

	return true
end
