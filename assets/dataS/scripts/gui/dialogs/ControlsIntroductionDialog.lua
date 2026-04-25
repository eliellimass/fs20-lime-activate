ControlsIntroductionDialog = {}
local ControlsIntroductionDialog_mt = Class(ControlsIntroductionDialog, InfoDialog)

function ControlsIntroductionDialog:new(target, custom_mt)
	local self = InfoDialog:new(target, custom_mt or ControlsIntroductionDialog_mt)

	return self
end
