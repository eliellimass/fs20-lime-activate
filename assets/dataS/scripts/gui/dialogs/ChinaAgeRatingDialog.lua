ChinaAgeRatingDialog = {}
local ChinaAgeRatingDialog_mt = Class(ChinaAgeRatingDialog, InfoDialog)

function ChinaAgeRatingDialog:new(target, custom_mt)
	local self = InfoDialog:new(target, custom_mt or ChinaAgeRatingDialog_mt)

	return self
end
