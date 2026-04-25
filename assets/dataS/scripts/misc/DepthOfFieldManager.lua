DepthOfFieldManager = {}
local DepthOfFieldManager_mt = Class(DepthOfFieldManager, AbstractManager)

function DepthOfFieldManager:new(customMt)
	self = AbstractManager:new(customMt or DepthOfFieldManager_mt)
	self.initialState = {
		getDoFparams()
	}
	self.currentState = {
		getDoFparams()
	}
	self.blurState = {
		1,
		100000,
		1,
		10000,
		100000
	}
	self.blurIsActive = false

	function self.oldSetDoFparams()
	end

	return self
end

function DepthOfFieldManager:getInitialDoFParams()
	return unpack(self.initialState)
end

function DepthOfFieldManager:getCurrentDoFParams()
	return unpack(self.currentState)
end

function DepthOfFieldManager:getBlurDoFParams()
	return unpack(self.blurState)
end

function DepthOfFieldManager:reset()
	setDoFparams(unpack(self.initialState))
end

function DepthOfFieldManager:setManipulatedParams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd)
	self.currentState[1] = nearCoCRadius or self.initialState[1]
	self.currentState[2] = nearBlurEnd or self.initialState[2]
	self.currentState[3] = farCoCRadius or self.initialState[3]
	self.currentState[4] = farBlurStart or self.initialState[4]
	self.currentState[5] = farBlurEnd or self.initialState[5]

	setDoFparams(unpack(self.currentState))
end

function DepthOfFieldManager:setBlurState(state)
	if state == nil then
		state = not self.blurIsActive
	end

	if state then
		self.oldSetDoFparams(unpack(self.blurState))
	else
		self.oldSetDoFparams(unpack(self.currentState))
	end

	self.blurIsActive = state
end

function DepthOfFieldManager:getIsDoFChangeAllowed()
	return not self.blurIsActive
end

function DepthOfFieldManager:queueDoFChange(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd)
	self.currentState = {
		nearCoCRadius,
		nearBlurEnd,
		farCoCRadius,
		farBlurStart,
		farBlurEnd
	}
end

g_depthOfFieldManager = DepthOfFieldManager:new()
g_depthOfFieldManager.oldSetDoFparams = setDoFparams

function setDoFparams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd)
	if g_depthOfFieldManager:getIsDoFChangeAllowed() then
		g_depthOfFieldManager.oldSetDoFparams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd)
	end

	g_depthOfFieldManager:queueDoFChange(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd)
end
