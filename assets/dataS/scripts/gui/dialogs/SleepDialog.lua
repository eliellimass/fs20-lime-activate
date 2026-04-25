SleepDialog = {
	CONTROLS = {
		DURATION = "durationElement"
	},
	MIN_DURATION = 2,
	DEFAULT_MAX_DURATION = 8
}
local SleepDialog_mt = Class(SleepDialog, YesNoDialog)

function SleepDialog:new(target, custom_mt)
	local self = YesNoDialog:new(target, custom_mt or SleepDialog_mt)
	self.selectedDuration = SleepDialog.MIN_DURATION
	self.maxDuration = SleepDialog.DEFAULT_MAX_DURATION

	self:registerControls(SleepDialog.CONTROLS)

	return self
end

function SleepDialog:onOpen()
	SleepDialog:superClass().onOpen(self)
	self:updateOptions()
end

function SleepDialog:onClose()
	SleepDialog:superClass().onClose(self)
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
end

function SleepDialog:setMaxDuration(duration)
	if duration ~= nil then
		self.maxDuration = duration
	else
		self.maxDuration = SleepDialog.DEFAULT_MAX_DURATION
	end

	self:updateOptions()
end

function SleepDialog:sendCallback(value, duration)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value, self.selectedDuration)
			else
				self.callbackFunc(value, self.selectedDuration)
			end
		end
	end
end

function SleepDialog:updateOptions()
	self.durations = {}

	for i = SleepDialog.MIN_DURATION, self.maxDuration do
		table.insert(self.durations, g_i18n:formatMinutes(i * 60))
	end

	self.durationElement:setTexts(self.durations)
end

function SleepDialog:onClickDuration(state)
	self.selectedDuration = state - 1 + SleepDialog.MIN_DURATION
end
