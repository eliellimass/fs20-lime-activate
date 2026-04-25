AsyncManager = {}
local AsyncManager_mt = Class(AsyncManager)

function AsyncManager:new(customMt)
	local self = setmetatable({}, customMt or AsyncManager_mt)

	self:initDataStructures()

	return self
end

function AsyncManager:initDataStructures()
	self.firstTask = nil
	self.lastTask = nil
	self.currentRunningTask = nil
	self.enabled = true
	self.doTracing = false
	self.executeSubTasksImmediately = self.doTracing and false
end

function AsyncManager:runLambda(lambda)
	if self.doTracing then
		traceOn(2)
		lambda()
		traceOff()
	else
		lambda()
	end
end

function AsyncManager:addTask(lambda)
	if not self.enabled then
		self:runLambda(lambda)
	else
		local taskCb = {
			lambda = lambda,
			nextTask = nil,
			firstSubTask = nil,
			lastSubTask = nil
		}

		if self.currentRunningTask == nil then
			if self.doTracing then
				print("Deferred a lambda")
			end

			if self.firstTask == nil then
				self.firstTask = taskCb
				self.lastTask = taskCb
			else
				self.lastTask.nextTask = taskCb
				self.lastTask = taskCb
			end
		else
			if self.doTracing then
				print("Queued a sub-lambda")
			end

			if self.currentRunningTask.firstSubTask == nil then
				self.currentRunningTask.firstSubTask = taskCb
				self.currentRunningTask.lastSubTask = taskCb
			else
				self.currentRunningTask.lastSubTask.nextTask = taskCb
				self.currentRunningTask.lastSubTask = taskCb
			end
		end
	end
end

function AsyncManager:addSubtask(lambda)
	if self.executeSubTasksImmediately then
		lambda()
	elseif not self.enabled or self.currentRunningTask == nil then
		if self.enabled then
			print("WARNING: addSubtask is *not* queuing the task, because not inside a task")
			printCallstack()
		end

		self:runLambda(lambda)
	else
		self:addTask(lambda)
	end
end

function AsyncManager:hasTasks()
	return self.firstTask ~= nil
end

function AsyncManager:flushAllTasks()
	self:initDataStructures()
end

function AsyncManager:runTopTask()
	if self.firstTask ~= nil then
		local taskCb = self.firstTask
		self.firstTask = taskCb.nextTask

		if self.firstTask == nil then
			self.lastTask = nil
		end

		self.currentRunningTask = taskCb

		self:runLambda(taskCb.lambda)

		self.currentRunningTask = nil

		if taskCb.firstSubTask ~= nil then
			taskCb.lastSubTask.nextTask = self.firstTask
			self.firstTask = taskCb.firstSubTask

			if self.lastTask == nil then
				self.lastTask = taskCb.lastSubTask
			end
		end

		return true
	else
		return false
	end
end

function AsyncManager:update(dt)
	if self:hasTasks() then
		self:runTopTask()
	end
end

g_asyncManager = AsyncManager:new()
