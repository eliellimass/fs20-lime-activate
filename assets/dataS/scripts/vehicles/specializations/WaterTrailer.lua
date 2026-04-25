source("dataS/scripts/vehicles/specializations/events/WaterTrailerSetIsFillingEvent.lua")

WaterTrailer = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
}

function WaterTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsWaterTrailerFilling", WaterTrailer.setIsWaterTrailerFilling)
end

function WaterTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", WaterTrailer.getDrawFirstFillText)
end

function WaterTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WaterTrailer)
end

function WaterTrailer:onLoad(savegame)
	local spec = self.spec_waterTrailer
	local fillUnitIndex = getXMLInt(self.xmlFile, "vehicle.waterTrailer#fillUnitIndex")

	if fillUnitIndex ~= nil then
		spec.fillUnitIndex = fillUnitIndex
		spec.fillLitersPerSecond = Utils.getNoNil(getXMLFloat(self.xmlFile, "vehicle.waterTrailer#fillLitersPerSecond"), 500)
		spec.waterFillNode = Utils.getNoNil(I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.waterTrailer#fillNode"), self.i3dMappings), self.components[1].node)
	end

	spec.isFilling = false
	spec.activatableAdded = false
	spec.activatable = WaterTrailerActivatable:new(self)

	if self.isClient then
		spec.samples = {
			refill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.waterTrailer.sounds", "refill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function WaterTrailer:onDelete()
	local spec = self.spec_waterTrailer

	if spec.activatableAdded then
		g_currentMission:removeActivatableObject(spec.activatable)

		spec.activatableAdded = false
	end

	if self.isClient then
		g_soundManager:deleteSamples(spec.samples)
	end
end

function WaterTrailer:onReadStream(streamId, connection)
	local isFilling = streamReadBool(streamId)

	self:setIsWaterTrailerFilling(isFilling, true)
end

function WaterTrailer:onWriteStream(streamId, connection)
	local spec = self.spec_waterTrailer

	streamWriteBool(streamId, spec.isFilling)
end

function WaterTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_waterTrailer
	local _, y, _ = getWorldTranslation(spec.waterFillNode)
	local isNearWater = y <= g_currentMission.waterY + 0.2

	if isNearWater then
		if not spec.activatableAdded then
			g_currentMission:addActivatableObject(spec.activatable)

			spec.activatableAdded = true
		end
	elseif spec.activatableAdded then
		g_currentMission:removeActivatableObject(spec.activatable)

		spec.activatableAdded = false
	end

	if self.isServer then
		if spec.isFilling and not isNearWater then
			self:setIsWaterTrailerFilling(false)
		end

		if spec.isFilling and self:getFillUnitAllowsFillType(spec.fillUnitIndex, FillType.WATER) then
			local delta = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.fillLitersPerSecond * dt * 0.001, FillType.WATER, ToolType.TRIGGER, nil)

			if delta <= 0 then
				self:setIsWaterTrailerFilling(false)
			end
		end
	end
end

function WaterTrailer:setIsWaterTrailerFilling(isFilling, noEventSend)
	local spec = self.spec_waterTrailer

	if isFilling ~= spec.isFilling then
		WaterTrailerSetIsFillingEvent.sendEvent(self, isFilling, noEventSend)

		spec.isFilling = isFilling

		if self.isClient then
			if isFilling then
				g_soundManager:playSample(spec.samples.refill)
			else
				g_soundManager:stopSample(spec.samples.refill)
			end
		end
	end
end

function WaterTrailer:getDrawFirstFillText(superFunc)
	local spec = self.spec_waterTrailer

	if self.isClient and self:getIsActiveForInput() and self:getIsSelected() and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return true
	end

	return superFunc(self)
end

function WaterTrailer:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_waterTrailer

	if spec.activatableAdded then
		g_currentMission:removeActivatableObject(spec.activatable)

		spec.activatableAdded = false
	end
end

WaterTrailerActivatable = {}
local WaterTrailerActivatable_mt = Class(WaterTrailerActivatable)

function WaterTrailerActivatable:new(trailer)
	local self = {}

	setmetatable(self, WaterTrailerActivatable_mt)

	self.trailer = trailer
	self.activateText = "unknown"

	return self
end

function WaterTrailerActivatable:getIsActivatable()
	local fillUnitIndex = self.trailer.spec_waterTrailer.fillUnitIndex

	if self.trailer:getIsActiveForInput(true) and self.trailer:getFillUnitFillLevel(fillUnitIndex) < self.trailer:getFillUnitCapacity(fillUnitIndex) and self.trailer:getFillUnitAllowsFillType(fillUnitIndex, FillType.WATER) then
		self:updateActivateText()

		return true
	end

	return false
end

function WaterTrailerActivatable:onActivateObject()
	self.trailer:setIsWaterTrailerFilling(not self.trailer.spec_waterTrailer.isFilling)
	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end

function WaterTrailerActivatable:drawActivate()
end

function WaterTrailerActivatable:updateActivateText()
	if self.trailer.spec_waterTrailer.isFilling then
		self.activateText = string.format(g_i18n:getText("action_stopRefillingOBJECT"), self.trailer.typeDesc)
	else
		self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.trailer.typeDesc)
	end
end
