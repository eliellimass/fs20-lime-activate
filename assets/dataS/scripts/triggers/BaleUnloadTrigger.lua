BaleUnloadTrigger = {}
local BaleUnloadTrigger_mt = Class(BaleUnloadTrigger, Object)

InitStaticObjectClass(BaleUnloadTrigger, "BaleUnloadTrigger", ObjectIds.OBJECT_BALE_UNLOAD_TRIGGER)

function BaleUnloadTrigger:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or BaleUnloadTrigger_mt)
	self.triggerNode = nil
	self.balesInTrigger = {}
	self.baleLoadersInTrigger = {}

	return self
end

function BaleUnloadTrigger:load(rootNode, xmlFile, xmlNode, target)
	local triggerNode = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "triggerNode", getXMLString, rootNode)

	if triggerNode ~= nil then
		self.triggerNode = I3DUtil.indexToObject(rootNode, triggerNode)

		if self.triggerNode ~= nil then
			addTrigger(self.triggerNode, "baleTriggerCallback", self)
		end
	end

	if self.triggerNode == nil then
		return false
	end

	local deleteLitersPerSecond = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "deleteLitersPerSecond", getXMLInt, rootNode)

	if deleteLitersPerSecond ~= nil then
		self.deleteLitersPerMS = deleteLitersPerSecond * 0.0001
	end

	if target ~= nil then
		self:setTarget(target)
	end

	self.isEnabled = true

	return true
end

function BaleUnloadTrigger:delete()
	if self.triggerNode ~= nil and self.triggerNode ~= 0 then
		removeTrigger(self.triggerNode)

		self.triggerNode = 0
	end

	BaleUnloadTrigger:superClass().delete(self)
end

function BaleUnloadTrigger:setTarget(object)
	assert(object.getIsFillTypeAllowed ~= nil)
	assert(object.getIsToolTypeAllowed ~= nil)
	assert(object.addFillUnitFillLevel ~= nil)

	self.target = object
end

function BaleUnloadTrigger:getTarget()
	return self.target
end

function BaleUnloadTrigger:update(dt)
	BaleUnloadTrigger:superClass().update(self, dt)

	if self.isServer then
		for index, bale in ipairs(self.balesInTrigger) do
			if bale ~= nil and bale.nodeId ~= 0 then
				if bale.dynamicMountJointIndex == nil then
					local fillType = bale:getFillType()
					local fillLevel = bale:getFillLevel()
					local fillInfo = nil
					local delta = bale:getFillLevel()

					if self.deleteLitersPerMS ~= nil then
						delta = self.deleteLitersPerMS * dt
					end

					if delta > 0 then
						local ownerFarmId = bale:getOwnerFarmId()

						if ownerFarmId == 0 then
							ownerFarmId = 1
						end

						delta = self.target:addFillUnitFillLevel(ownerFarmId, 1, delta, fillType, ToolType.BALE, fillInfo)

						bale:setFillLevel(fillLevel - delta)

						local newFillLevel = bale:getFillLevel()

						if newFillLevel < 0.01 then
							bale:delete()
							table.remove(self.balesInTrigger, index)

							break
						end
					end
				end
			else
				table.remove(self.balesInTrigger, index)
			end
		end

		for index, baleLoader in ipairs(self.baleLoadersInTrigger) do
			if baleLoader:getIsAutomaticBaleUnloadingAllowed() then
				local bales = baleLoader:getLoadedBales()
				local unloadingAllowed = false

				for i, bale in ipairs(bales) do
					local fillType = bale:getFillType()

					if self.target:getIsFillTypeAllowed(fillType) and self.target:getIsFillTypeSupported(fillType) and self.target:getIsToolTypeAllowed(ToolType.BALE) then
						unloadingAllowed = true

						break
					end
				end

				if unloadingAllowed then
					baleLoader:startAutomaticBaleUnloading()
				end
			end
		end

		if #self.balesInTrigger > 0 or #self.baleLoadersInTrigger > 0 then
			self:raiseActive()
		end
	end
end

function BaleUnloadTrigger:baleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil then
			if object:isa(Bale) then
				if onEnter then
					local fillType = object:getFillType()

					if self.target:getIsFillTypeAllowed(fillType) and self.target:getIsFillTypeSupported(fillType) and self.target:getIsToolTypeAllowed(ToolType.BALE) then
						self:raiseActive()
						table.insert(self.balesInTrigger, object)
					end
				elseif onLeave then
					for index, bale in ipairs(self.balesInTrigger) do
						if bale == object then
							table.remove(self.balesInTrigger, index)

							break
						end
					end
				end
			elseif object:isa(Vehicle) then
				local isAutoLoadActive = g_platformSettingsManager:getSetting("automaticBaleDrop", false) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations)

				if onEnter then
					if isAutoLoadActive then
						table.insert(self.baleLoadersInTrigger, object)
						self:raiseActive()
					end
				elseif onLeave and isAutoLoadActive then
					for index, baleLoader in ipairs(self.baleLoadersInTrigger) do
						if baleLoader == object then
							table.remove(self.baleLoadersInTrigger, index)

							break
						end
					end
				end
			elseif g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
				if onEnter then
					-- Nothing
				elseif onLeave then
					-- Nothing
				end
			end
		end
	end
end
