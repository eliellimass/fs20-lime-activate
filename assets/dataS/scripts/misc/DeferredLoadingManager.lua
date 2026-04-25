DeferredLoadingManager = {}
local DeferredLoadingManager_mt = Class(DeferredLoadingManager, AsyncManager)

function DeferredLoadingManager:new(customMt)
	local self = AsyncManager:new(customMt or DeferredLoadingManager_mt)

	return self
end

function DeferredLoadingManager:flushAllTasks()
	self.firstTask = nil
	self.lastTask = nil
	self.currentRunningTask = nil

	forceEndFrameRepeatMode()
end

function DeferredLoadingManager:update(dt)
	if self:hasTasks() then
		local timer = openIntervalTimer()

		if timer == -1 then
			self:runTopTask()
		else
			local allowedTimeMs = 16
			local cnt = 0

			while self:hasTasks() and readIntervalTimerMs(timer) < allowedTimeMs do
				self:runTopTask()

				cnt = cnt + 1
			end

			local finalTime = readIntervalTimerMs(timer)

			if finalTime > 1000 then
				g_logManager:devWarning("deferred loading task ran to %d ms", finalTime)
			end

			closeIntervalTimer(timer)
		end
	end
end

g_deferredLoadingManager = DeferredLoadingManager:new()
