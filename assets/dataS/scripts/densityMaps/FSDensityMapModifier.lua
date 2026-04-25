FSDensityMapModifier = {}
local FSDensityMapModifier_mt = Class(FSDensityMapModifier)

function FSDensityMapModifier:new()
	local self = setmetatable({}, FSDensityMapModifier_mt)
	self.cutFruitArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateDestroyCommonArea = {
		modifier = nil,
		multiModifiers = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.getFruitArea = {
		modifier = nil,
		filter = nil
	}
	self.setGroundTypeLayerArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateFruitPreparerArea = {
		modifier = nil,
		filter = nil
	}
	self.updateDirectSowingArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateSowingArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateRollerArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.getStatus = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.getFieldStatus = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateSubsoilerArea = {
		modifier = nil,
		filter = nil
	}
	self.updateCultivatorArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updatePlowArea = {
		modifier = nil,
		filter = nil
	}
	self.setWeedArea = {
		modifier = nil,
		filter = nil
	}
	self.removeWeedArea = {
		modifier = nil,
		filter = nil
	}
	self.getWeedFactor = {
		modifier = nil,
		filter = nil,
		maskFilter = nil
	}
	self.getFieldValue = {
		modifier = nil,
		filter = nil
	}
	self.getAreaDensity = {
		modifier = nil,
		filter = nil
	}
	self.getFieldDensity = {
		modifier = nil,
		filter = nil
	}
	self.resetSprayArea = {
		modifier = nil,
		filter = nil
	}
	self.updateFertilizerArea = {
		modifier = nil,
		filter = nil
	}
	self.updateLimeArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.removeSprayArea = {
		modifier = nil,
		filter = nil
	}
	self.updateHerbicideArea = {
		modifier = nil,
		weedFilter = nil
	}
	self.updateWeederArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.updateWheelDestructionArea = {
		modifier = nil,
		filter1 = nil,
		filter2 = nil
	}
	self.getAIDensityHeightArea = {
		modifier = nil,
		filter = nil
	}
	self.removeFieldArea = {
		modifier = nil
	}

	return self
end
