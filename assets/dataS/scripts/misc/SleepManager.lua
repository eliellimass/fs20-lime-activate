SleepManager = {
	SLEEPING_TIME_SCALE = 5000,
	TIME_TO_ANSWER_REQUEST = 20000,
	NO_SLEEP_PAST = 10
}
local SleepManager_mt = Class(SleepManager, AbstractManager)

function SleepManager:new(customMt)
	self = AbstractManager:new(customMt or SleepManager_mt)
	self.isSleeping = false
	self.wakeUpTime = 0
	self.sleepingRanges = {
		{
			19,
			24
		},
		{
			0,
			5
		}
	}
	self.requestedSleep = false
	self.requestedTime = 0
	self.requestCounter = 0
	self.responseCounter = 0

	return self
end

function SleepManager:update(dt)
	if self.wakeUpTime < g_time and self.isSleeping then
		self:stopSleep()
	end

	if self.requestedSleep then
		if self.responseCounter == self.requestCounter then
			self:startSleep(self.duration)

			self.responseCounter = 0
			self.requestedSleep = false
		end

		if self.requestedTime + SleepManager.TIME_TO_ANSWER_REQUEST < g_time then
			self.responseCounter = 0
			self.requestedSleep = false
		end
	end
end

function SleepManager:startSleep(hours, noEventSend)
	if g_currentMission:getIsServer() then
		self.wakeUpTime = g_time + hours * 60 * 60 * 1000 / SleepManager.SLEEPING_TIME_SCALE
		self.startTimeScale = g_currentMission.missionInfo.timeScale

		g_currentMission:setTimeScale(SleepManager.SLEEPING_TIME_SCALE)

		self.isSleeping = true
	end

	local camera = self:getCamera()

	if camera ~= 0 then
		setCamera(camera)
	end

	g_currentMission.isPlayerFrozen = true

	StartSleepStateEvent.sendEvent(hours, noEventSend)
end

function SleepManager:stopSleep(noEventSend)
	if g_currentMission:getIsServer() then
		g_currentMission:setTimeScale(self.startTimeScale)

		self.isSleeping = false
	end

	if self:getCamera() ~= 0 then
		setCamera(g_currentMission.player.cameraNode)
	end

	g_currentMission.isPlayerFrozen = false

	StopSleepStateEvent.sendEvent(noEventSend)
end

function SleepManager:getCanSleep()
	local currentHour = g_currentMission.environment.dayTime / 60 / 60 / 1000

	for _, range in ipairs(self.sleepingRanges) do
		if range[1] < currentHour and currentHour < range[2] then
			return true
		end
	end

	return false
end

function SleepManager:getIsSleeping()
	return self.isSleeping
end

function SleepManager:showDialog()
	if self:getCanSleep() then
		g_gui:showSleepDialog({
			text = g_i18n:getText("ui_inGameSleepSelectDuration"),
			callback = self.sleepDialogYesNo,
			target = self,
			maxDuration = self:getMaxSleepDuration()
		})
	else
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_inGameSleepWrongTime"),
			dialogType = DialogElement.TYPE_WARNING,
			target = self
		})
	end
end

function SleepManager:getMaxSleepDuration()
	local currentHour = g_currentMission.environment.dayTime / 60 / 60 / 1000
	local max = nil

	if self.sleepingRanges[1][1] < currentHour then
		max = 24 - currentHour + SleepManager.NO_SLEEP_PAST
	else
		max = SleepManager.NO_SLEEP_PAST - currentHour
	end

	return math.floor(max)
end

function SleepManager:sleepDialogYesNo(yesNo, duration)
	if yesNo then
		SleepRequestEvent.sendEvent(g_currentMission.playerUserId)

		self.duration = duration
		self.requestedSleep = true
		self.requestedTime = g_time
		self.responseCounter = 0
		self.requestCounter = table.getn(g_currentMission.userManager:getUsers()) - 1

		if g_currentMission.connectedToDedicatedServer then
			self.requestCounter = self.requestCounter - 1
		end
	end
end

function SleepManager:showSleepRequest(userId)
	if userId ~= g_currentMission.playerUserId then
		local user = g_currentMission.userManager:getUserByUserId(userId)

		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_inGameSleepRequest"), user:getNickname()),
			callback = self.sleepRequestYesNo,
			target = self
		})
	end
end

function SleepManager:sleepRequestYesNo(yesNo)
	SleepResponseEvent.sendEvent(g_currentMission.playerUserId, yesNo)
end

function SleepManager:sleepResponse(userId, answer)
	if answer then
		self.responseCounter = self.responseCounter + 1
	else
		if userId ~= g_currentMission.playerUserId then
			local user = g_currentMission.userManager:getUserByUserId(userId)

			g_gui:showInfoDialog({
				text = string.format(g_i18n:getText("ui_inGameSleepRequestDenied"), user:getNickname()),
				dialogType = DialogElement.TYPE_WARNING,
				target = self
			})
		end

		self.responseCounter = 0
		self.requestedSleep = false
	end
end

function SleepManager:getCamera(node)
	return g_farmManager:getSleepCamera(g_currentMission.player.farmId)
end

g_sleepManager = SleepManager:new()
