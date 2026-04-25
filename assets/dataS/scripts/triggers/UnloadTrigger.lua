UnloadTrigger = {}
local UnloadTrigger_mt = Class(UnloadTrigger, Object)

InitStaticObjectClass(UnloadTrigger, "UnloadTrigger", ObjectIds.OBJECT_UNLOAD_TRIGGER)

function UnloadTrigger:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or UnloadTrigger_mt)
	self.fillTypes = {}
	self.avoidFillTypes = {}
	self.acceptedToolTypes = {}
	self.notAllowedWarningText = nil

	return self
end

function UnloadTrigger:load(rootNode, xmlFile, xmlNode, target, extraAttributes)
	self.baleTrigger = BaleUnloadTrigger:new(self.isServer, self.isClient)

	if self.baleTrigger:load(rootNode, xmlFile, xmlNode .. ".baleTrigger", self) then
		self.baleTrigger:setTarget(self)
		self.baleTrigger:register(true)
	else
		self.baleTrigger = nil
	end

	local exactFillRootNode = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "exactFillRootNode", getXMLString, rootNode)
	self.exactFillRootNode = I3DUtil.indexToObject(rootNode, exactFillRootNode)

	if self.exactFillRootNode ~= nil then
		local colMask = getCollisionMask(self.exactFillRootNode)

		if bitAND(FillUnit.EXACTFILLROOTNODE_MASK, colMask) == 0 then
			g_logManager:warning("Invalid exactFillRootNode collision mask for unloadTrigger. Bit 30 needs to be set!")

			return false
		end

		g_currentMission:addNodeObject(self.exactFillRootNode, self)
	end

	if target ~= nil then
		self:setTarget(target)
	end

	self:loadFillTypes(rootNode, xmlFile, xmlNode)
	self:loadAcceptedToolType(rootNode, xmlFile, xmlNode)
	self:loadAvoidFillTypes(rootNode, xmlFile, xmlNode)

	self.isEnabled = true
	self.extraAttributes = extraAttributes

	return true
end

function UnloadTrigger:delete()
	if self.baleTrigger ~= nil then
		self.baleTrigger:delete()
	end

	UnloadTrigger:superClass().delete(self)
end

function UnloadTrigger:loadAcceptedToolType(rootNode, xmlFile, xmlNode)
	local acceptedToolTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "acceptedToolTypes", getXMLString, rootNode)
	local acceptedToolTypes = StringUtil.getVectorFromString(acceptedToolTypeNames)

	if acceptedToolTypes ~= nil then
		for _, acceptedToolType in pairs(acceptedToolTypes) do
			local toolTypeInt = g_toolTypeManager:getToolTypeIndexByName(acceptedToolType)
			self.acceptedToolTypes[toolTypeInt] = true
		end
	else
		self.acceptedToolTypes = nil
	end
end

function UnloadTrigger:loadAvoidFillTypes(rootNode, xmlFile, xmlNode)
	local avoidFillTypeCategories = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "avoidFillTypeCategories", getXMLString, rootNode)
	local avoidFillTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "avoidFillTypes", getXMLString, rootNode)
	local avoidFillTypes = nil

	if avoidFillTypeCategories ~= nil and avoidFillTypeNames == nil then
		avoidFillTypes = g_fillTypeManager:getFillTypesByCategoryNames(avoidFillTypeCategories, "Warning: UnloadTrigger has invalid avoidFillTypeCategory '%s'.")
	elseif avoidFillTypeCategories == nil and avoidFillTypeNames ~= nil then
		avoidFillTypes = g_fillTypeManager:getFillTypesByNames(avoidFillTypeNames, "Warning: UnloadTrigger has invalid avoidFillType '%s'.")
	end

	if avoidFillTypes ~= nil then
		for _, fillType in pairs(avoidFillTypes) do
			self.avoidFillTypes[fillType] = true
		end
	else
		self.avoidFillTypes = nil
	end
end

function UnloadTrigger:loadFillTypes(rootNode, xmlFile, xmlNode)
	local fillTypeCategories = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypeCategories", getXMLString, rootNode)
	local fillTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypes", getXMLString, rootNode)
	local fillTypes = nil

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: UnloadTrigger has invalid fillTypeCategory '%s'.")
	elseif fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: UnloadTrigger has invalid fillType '%s'.")
	end

	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			self.fillTypes[fillType] = true
		end
	else
		self.fillTypes = nil
	end
end

function UnloadTrigger:setTarget(object)
	assert(object.getIsFillTypeAllowed ~= nil)
	assert(object.getIsToolTypeAllowed ~= nil)
	assert(object.addFillLevelFromTool ~= nil)
	assert(object.getFreeCapacity ~= nil)

	self.target = object
end

function UnloadTrigger:getTarget()
	return self.target
end

function UnloadTrigger:getFillUnitIndexFromNode(node)
	return 1
end

function UnloadTrigger:getFillUnitExactFillRootNode(fillUnitIndex)
	return self.exactFillRootNode
end

function UnloadTrigger:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta, fillTypeIndex, fillPositionData, toolType, self.extraAttributes)

	return applied
end

function UnloadTrigger:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	local supported = self:getIsFillTypeSupported(fillType)

	return supported
end

function UnloadTrigger:getFillUnitSupportsToolType(fillUnit, toolType, fillType)
	return true
end

function UnloadTrigger:getFillUnitAllowsFillType(fillUnitIndex, fillType)
	return self:getIsFillTypeAllowed(fillType)
end

function UnloadTrigger:getIsFillTypeAllowed(fillType)
	return self:getIsFillTypeSupported(fillType)
end

function UnloadTrigger:getIsFillTypeSupported(fillType)
	local accepted = true

	if self.target ~= nil then
		if not self.target:getIsFillTypeAllowed(fillType, extraAttributes) then
			accepted = false
		end
	elseif self.fillTypes ~= nil and not self.fillTypes[fillType] then
		accepted = false
	end

	if self.avoidFillTypes ~= nil and self.avoidFillTypes[fillType] then
		accepted = false
	end

	return accepted
end

function UnloadTrigger:getIsFillAllowedFromFarm(farmId)
	if self.target ~= nil and self.target.getIsFillAllowedFromFarm ~= nil then
		return self.target:getIsFillAllowedFromFarm(farmId)
	end

	return true
end

function UnloadTrigger:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	if self.target.getFreeCapacity ~= nil then
		return self.target:getFreeCapacity(fillTypeIndex, farmId)
	end

	return 0
end

function UnloadTrigger:getIsToolTypeAllowed(toolType)
	local accepted = true

	if self.acceptedToolTypes ~= nil and self.acceptedToolTypes[toolType] ~= true then
		accepted = false
	end

	if accepted then
		return self.target:getIsToolTypeAllowed(toolType)
	else
		return false
	end
end

function UnloadTrigger:getCustomDischargeNotAllowedWarning()
	return self.notAllowedWarningText
end
