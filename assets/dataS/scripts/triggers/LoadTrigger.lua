LoadTrigger = {}
local LoadTrigger_mt = Class(LoadTrigger, Object)

InitStaticObjectClass(LoadTrigger, "LoadTrigger", ObjectIds.OBJECT_LOAD_TRIGGER)

function LoadTrigger:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or LoadTrigger_mt)
	self.fillableObjects = {}

	return self
end

function LoadTrigger:load(rootNode, xmlFile, xmlNode)
	self.rootNode = rootNode
	self.objectsInTriggers = {}
	local triggerNodeStr = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "triggerNode", getXMLString, self.rootNode)
	local triggerNode = I3DUtil.indexToObject(self.rootNode, triggerNodeStr)

	if triggerNode == nil then
		triggerNodeStr = getUserAttribute(self.rootNode, "triggerIndex")
		triggerNode = I3DUtil.indexToObject(self.rootNode, triggerNodeStr)
	end

	if triggerNode == nil then
		print("Error: LoadTrigger could not load trigger. Check the user attribute 'triggerNode'")
		printCallstack()

		return false
	end

	self.triggerNode = triggerNode

	addTrigger(triggerNode, "loadTriggerCallback", self)
	g_currentMission:addNodeObject(triggerNode, self)

	local fillLitersPerMS = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillLitersPerSecond", getXMLInt, self.rootNode)
	self.fillLitersPerMS = (tonumber(fillLitersPerMS) or 1000) / 1000
	local dischargeNodeStr = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "dischargeNode", getXMLString, self.rootNode)
	local dischargeNode = I3DUtil.indexToObject(self.rootNode, dischargeNodeStr)

	if dischargeNode ~= nil then
		self.dischargeInfo = {
			name = "fillVolumeDischargeInfo",
			nodes = {}
		}
		local width = Utils.getNoNil(getUserAttribute(dischargeNode, "width"), 0.5)
		local length = Utils.getNoNil(getUserAttribute(dischargeNode, "length"), 0.5)

		table.insert(self.dischargeInfo.nodes, {
			priority = 1,
			node = dischargeNode,
			width = width,
			length = length
		})
	end

	self.soundNode = createTransformGroup("loadTriggerSoundNode")

	link(dischargeNode or self.triggerNode, self.soundNode)

	if self.isClient then
		self.effects = g_effectManager:loadEffect(xmlFile, xmlNode, self.rootNode, self)
		self.samples = {}
		local fillSoundIdentifier = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillSoundIdentifier", getXMLString, self.rootNode)
		local fillSoundNode = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillSoundNode", getXMLString, self.rootNode)

		if fillSoundNode == nil then
			fillSoundNode = self.rootNode
		end

		local xmlSoundFile = loadXMLFile("mapXML", g_currentMission.missionInfo.mapSoundXmlFilename)

		if xmlSoundFile ~= nil and xmlSoundFile ~= 0 then
			local directory = g_currentMission.baseDirectory
			local modName, baseDirectory = Utils.getModNameAndBaseDirectory(g_currentMission.missionInfo.mapSoundXmlFilename)

			if modName ~= nil then
				directory = baseDirectory .. modName
			end

			if fillSoundIdentifier ~= nil then
				self.samples.load = g_soundManager:loadSampleFromXML(xmlSoundFile, "sound.object", fillSoundIdentifier, directory, getRootNode(), 0, AudioGroup.ENVIRONMENT, nil, )

				if self.samples.load ~= nil then
					link(fillSoundNode, self.samples.load.soundNode)
					setTranslation(self.samples.load.soundNode, 0, 0, 0)
				end
			end

			delete(xmlSoundFile)
		end

		local scrollerStr = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "scrollerIndex", getXMLString, self.rootNode)
		self.scroller = I3DUtil.indexToObject(self.rootNode, scrollerStr)

		if self.scroller ~= nil then
			local shaderParameterName = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "shaderParameterName", getXMLString, self.rootNode)
			local scrollerScrollSpeed = tonumber(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "scrollerScrollSpeed", getXMLFloat, self.rootNode))
			self.scrollerShaderParameterName = Utils.getNoNil(shaderParameterName, "uvScrollSpeed")

			if scrollerScrollSpeed ~= nil then
				self.scrollerSpeedX, self.scrollerSpeedY = StringUtil.getVectorFromString(scrollerScrollSpeed)
			end

			self.scrollerSpeedX = Utils.getNoNil(self.scrollerSpeedX, 0)
			self.scrollerSpeedY = Utils.getNoNil(self.scrollerSpeedY, -0.75)

			setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
		end
	end

	self.fillTypes = {}
	local fillTypeCategories = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypeCategories", getXMLString, self.rootNode)
	local fillTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypes", getXMLString, self.rootNode)
	local fillTypes = nil

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: UnloadTrigger has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: UnloadTrigger has invalid fillType '%s'.")
	end

	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			self.fillTypes[fillType] = true
		end
	else
		self.fillTypes = nil
	end

	self.autoStart = Utils.getNoNil(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "autoStart", getXMLBool, self.rootNode), false)
	self.hasInfiniteCapacity = Utils.getNoNil(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "infiniteCapacity", getXMLBool, self.rootNode), false)
	self.startFillText = g_i18n:getText("action_siloStartFilling")
	self.stopFillText = g_i18n:getText("action_siloStopFilling")
	self.activateText = self.startFillText
	self.isLoading = false
	self.selectedFillType = FillType.UNKNOWN
	self.automaticFilling = g_platformSettingsManager:getSetting("automaticFilling", false)
	self.requiresActiveVehicle = not self.automaticFilling
	self.automaticFillingTimer = 0

	return true
end

function LoadTrigger:delete()
	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
	end

	if self.isClient then
		for _, sample in pairs(self.samples) do
			g_soundManager:deleteSample(sample)
		end

		g_effectManager:deleteEffects(self.effects)
	end

	g_currentMission:removeActivatableObject(self)
	LoadTrigger:superClass().delete(self)
end

function LoadTrigger:setSource(object)
	assert(object.getProvidedFillTypes ~= nil)
	assert(object.getAllFillLevels ~= nil)
	assert(object.addFillLevelToFillableObject ~= nil)
	assert(object.getIsFillAllowedToFarm ~= nil)

	self.source = object
end

function LoadTrigger:loadTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local fillableObject = g_currentMission:getNodeObject(otherId)

	if fillableObject ~= nil and fillableObject ~= self.source and fillableObject.getRootVehicle ~= nil and fillableObject.getFillUnitIndexFromNode ~= nil then
		local fillTypes = self.source:getProvidedFillTypes()

		if fillTypes ~= nil then
			local foundFillUnitIndex = fillableObject:getFillUnitIndexFromNode(otherId)

			if foundFillUnitIndex ~= nil then
				local found = false

				for fillTypeIndex, state in pairs(fillTypes) do
					if state and (self.fillTypes == nil or self.fillTypes[fillTypeIndex]) and fillableObject:getFillUnitSupportsFillType(foundFillUnitIndex, fillTypeIndex) and fillableObject:getFillUnitAllowsFillType(foundFillUnitIndex, fillTypeIndex) then
						found = true

						break
					end
				end

				if not found then
					foundFillUnitIndex = nil
				end
			end

			if foundFillUnitIndex == nil then
				for fillTypeIndex, state in pairs(fillTypes) do
					if state and (self.fillTypes == nil or self.fillTypes[fillTypeIndex]) then
						local fillUnits = fillableObject:getFillUnits()

						for fillUnitIndex, fillUnit in ipairs(fillUnits) do
							if fillUnit.exactFillRootNode == nil and fillableObject:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex) and fillableObject:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex) then
								foundFillUnitIndex = fillUnitIndex

								break
							end
						end
					end
				end
			end

			if foundFillUnitIndex ~= nil then
				if onEnter then
					self.fillableObjects[otherId] = {
						object = fillableObject,
						fillUnitIndex = foundFillUnitIndex
					}

					fillableObject:addDeleteListener(self)
				elseif onLeave then
					self.fillableObjects[otherId] = nil

					fillableObject:removeDeleteListener(self)

					if self.isLoading and self.currentFillableObject == fillableObject then
						self:setIsLoading(false)
					end

					if fillableObject == self.validFillableObject then
						self.validFillableObject = nil
						self.validFillableFillUnitIndex = nil
					end
				end

				if self.automaticFilling then
					if not self.isLoading and next(self.fillableObjects) ~= nil and self:getIsActivatable() then
						self:onActivateObject()
					end
				elseif next(self.fillableObjects) ~= nil then
					g_currentMission:addActivatableObject(self)
				else
					g_currentMission:removeActivatableObject(self)
				end
			end
		end
	end
end

function LoadTrigger:farmIdForFillableObject(fillableObject)
	local objectFarmId = fillableObject:getOwnerFarmId()

	if fillableObject.getActiveFarm ~= nil then
		objectFarmId = fillableObject:getActiveFarm()
	end

	if objectFarmId == nil then
		objectFarmId = FarmManager.SPECTATOR_FARM_ID
	end

	return objectFarmId
end

function LoadTrigger:getIsActivatable(ignoreControlState)
	if next(self.fillableObjects) == nil then
		return false
	elseif self.isLoading then
		if self.currentFillableObject ~= nil and (self.currentFillableObject:getRootVehicle() == g_currentMission.controlledVehicle or not self.requiresActiveVehicle) then
			return true
		end
	else
		self.validFillableObject = nil
		self.validFillableFillUnitIndex = nil
		local hasLowPrioObject = false
		local numOfObjects = 0

		for _, fillableObject in pairs(self.fillableObjects) do
			if fillableObject.lastWasFilled then
				hasLowPrioObject = true
			end

			numOfObjects = numOfObjects + 1
		end

		hasLowPrioObject = hasLowPrioObject and numOfObjects > 1

		for _, fillableObject in pairs(self.fillableObjects) do
			if (not fillableObject.lastWasFilled or not hasLowPrioObject) and (fillableObject.object:getRootVehicle() == g_currentMission.controlledVehicle or not self.requiresActiveVehicle) and fillableObject.object:getFillUnitSupportsToolType(fillableObject.fillUnitIndex, ToolType.TRIGGER) then
				if not self.source:getIsFillAllowedToFarm(self:farmIdForFillableObject(fillableObject.object)) then
					return false
				end

				self.validFillableObject = fillableObject.object
				self.validFillableFillUnitIndex = fillableObject.fillUnitIndex

				return true
			end
		end
	end

	return false
end

function LoadTrigger:drawActivate()
end

function LoadTrigger:onActivateObject()
	if not self.isLoading then
		local fillLevels, capacity = self.source:getAllFillLevels(g_currentMission:getFarmId())
		local fillableObject = self.validFillableObject
		local fillUnitIndex = self.validFillableFillUnitIndex
		local firstFillType = nil
		local validFillLevels = {}
		local numFillTypes = 0

		for fillTypeIndex, fillLevel in pairs(fillLevels) do
			if (self.fillTypes == nil or self.fillTypes[fillTypeIndex]) and fillableObject:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex) then
				validFillLevels[fillTypeIndex] = fillLevel

				if firstFillType == nil then
					firstFillType = fillTypeIndex
				end

				numFillTypes = numFillTypes + 1
			end
		end

		if not self.autoStart and numFillTypes > 1 then
			local startAllowed = true

			if fillableObject.getIsActiveForInput ~= nil then
				startAllowed = fillableObject:getIsActiveForInput(true)
			end

			if startAllowed then
				local text = nil

				if self.hasInfiniteCapacity then
					text = string.format("%s", self.source.stationName)
				else
					text = string.format("%s (%s)", self.source.stationName, g_i18n:formatFluid(capacity))
				end

				g_gui:showSiloDialog({
					title = text,
					fillLevels = validFillLevels,
					capacity = capacity,
					callback = self.onFillTypeSelection,
					target = self,
					hasInfiniteCapacity = self.hasInfiniteCapacity
				})

				if GS_IS_MOBILE_VERSION then
					local rootVehicle = fillableObject:getRootVehicle()

					if rootVehicle.brakeToStop ~= nil then
						rootVehicle:brakeToStop()
					end
				end
			end
		else
			self:onFillTypeSelection(firstFillType)
		end
	else
		self:setIsLoading(false)
	end

	g_currentMission:addActivatableObject(self)
end

function LoadTrigger:onFillTypeSelection(fillType)
	if fillType ~= nil and fillType ~= FillType.UNKNOWN then
		local validFillableObject = self.validFillableObject

		if validFillableObject ~= nil and (validFillableObject:getRootVehicle() == g_currentMission.controlledVehicle or not self.requiresActiveVehicle) then
			local fillUnitIndex = self.validFillableFillUnitIndex

			self:setIsLoading(true, validFillableObject, fillUnitIndex, fillType)
		end
	end
end

function LoadTrigger:setIsLoading(isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
	LoadTriggerSetIsLoadingEvent.sendEvent(self, isLoading, targetObject, fillUnitIndex, fillType, noEventSend)

	if isLoading then
		self:startLoading(fillType, targetObject, fillUnitIndex)
	else
		self:stopLoading()
	end

	self:setFillSoundIsPlaying(isLoading)

	if self.currentFillableObject ~= nil and self.currentFillableObject.setFillSoundIsPlaying ~= nil then
		self.currentFillableObject:setFillSoundIsPlaying(isLoading)
	end
end

function LoadTrigger:startLoading(fillType, fillableObject, fillUnitIndex)
	if not self.isLoading then
		self:raiseActive()

		self.isLoading = true
		self.selectedFillType = fillType
		self.currentFillableObject = fillableObject
		self.fillUnitIndex = fillUnitIndex
		self.activateText = self.stopFillText

		if self.isClient then
			g_effectManager:setFillType(self.effects, self.selectedFillType)
			g_effectManager:startEffects(self.effects)
			g_soundManager:playSample(self.samples.load)

			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, self.scrollerSpeedX, self.scrollerSpeedY, 0, 0, false)
			end
		end
	end
end

function LoadTrigger:stopLoading()
	if self.isLoading then
		self:raiseActive()

		self.isLoading = false
		self.selectedFillType = FillType.UNKNOWN
		self.activateText = self.startFillText

		for i, fillableObject in pairs(self.fillableObjects) do
			fillableObject.lastWasFilled = fillableObject.object == self.validFillableObject
		end

		if self.isClient then
			g_effectManager:stopEffects(self.effects)
			g_soundManager:stopSample(self.samples.load)

			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
			end
		end
	end
end

function LoadTrigger:update(dt)
	if self.isServer then
		if self.isLoading then
			if self.currentFillableObject ~= nil then
				local fillDelta = self.source:addFillLevelToFillableObject(self.currentFillableObject, self.fillUnitIndex, self.selectedFillType, self.fillLitersPerMS * dt, self.dischargeInfo, ToolType.TRIGGER)

				if fillDelta == nil or math.abs(fillDelta) < 0.001 then
					self:setIsLoading(false)
				end
			elseif self.isLoading then
				self:setIsLoading(false)
			end

			self:raiseActive()
		elseif self.automaticFilling and next(self.fillableObjects) ~= nil then
			self.automaticFillingTimer = math.max(self.automaticFillingTimer - dt, 0)

			if self.automaticFillingTimer == 0 and self:getIsActivatable() then
				self:onActivateObject()

				self.automaticFillingTimer = 10000
			end

			self:raiseActive()
		end
	end
end

function LoadTrigger:getCurrentFillType()
	return self.selectedFillType
end

function LoadTrigger:getFillTargetNode()
	if self.currentFillableObject ~= nil then
		return self.currentFillableObject:getFillUnitRootNode(self.fillUnitIndex)
	end
end

function LoadTrigger:setFillSoundIsPlaying(state)
	if self.dischargeInfo == nil and state then
		local target = self:getFillTargetNode()

		if target ~= nil then
			local x, y, z = getWorldTranslation(target)

			setWorldTranslation(self.soundNode, x, y, z)
		end
	end

	FillTrigger.setFillSoundIsPlaying(self, state)
end

function LoadTrigger:onDeleteObject(vehicle)
	for k, fillableObject in pairs(self.fillableObjects) do
		if fillableObject.object == vehicle then
			self.fillableObjects[k] = nil
		end
	end
end
