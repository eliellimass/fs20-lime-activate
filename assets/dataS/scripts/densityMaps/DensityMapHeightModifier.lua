DensityMapHeightModifier = {}
local DensityMapHeightModifier_mt = Class(DensityMapHeightModifier)

function DensityMapHeightModifier:new()
	local self = setmetatable({}, DensityMapHeightModifier_mt)
	self.getFillTypeAtArea = {
		modifierType = nil,
		filterType = nil
	}
	self.getFillLevelAtArea = {
		modifierHeight = nil,
		filterHeight = nil,
		filterType = nil
	}
	self.getValueAtArea = {
		modifierHeight = nil
	}
	self.removeFromGroundByArea = {
		modifier = nil,
		filterType = nil
	}
	self.changeFillTypeAtArea = {
		modifierType = nil,
		filterType = nil
	}
	self.clearArea = {
		modifier = nil
	}

	return self
end
