BaleStoragePlaceable = {}
local BaleStoragePlaceable_mt = Class(BaleStoragePlaceable, Placeable)

InitStaticObjectClass(BaleStoragePlaceable, "BaleStoragePlaceable", ObjectIds.OBJECT_BALE_STORAGE_PLACEABLE)

function BaleStoragePlaceable:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or BaleStoragePlaceable_mt)

	registerObjectClassName(self, "BaleStoragePlaceable")

	self.storedBales = {}
	self.opticalBales = {}
	self.physicsBale = nil
	self.baleLoadersInTrigger = {}

	return self
end

function BaleStoragePlaceable:delete()
	removeTrigger(self.triggerId)

	if self.poiTrigger ~= nil then
		self.poiTrigger:delete()
	end

	unregisterObjectClassName(self)
	BaleStoragePlaceable:superClass().delete(self)
end

function BaleStoragePlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
	if not BaleStoragePlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
		return false
	end

	local xmlFile = loadXMLFile("TempXML", xmlFilename)
	local triggerId = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.baleStorage#triggerNode"))

	if triggerId == nil then
		g_logManager:xmlWarning(xmlFilename, "Missing bale trigger node in 'placeable.baleStorage#triggerNode'!")
		delete(xmlFile)

		return false
	end

	addTrigger(triggerId, "baleTriggerCallback", self)

	self.triggerId = triggerId
	local fillTypeNames = getXMLString(xmlFile, "placeable.baleStorage#fillTypes") or "straw"
	self.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames)
	self.capacity = Utils.getNoNil(getXMLFloat(xmlFile, "placeable.baleStorage#capacity"), 32)
	self.balePlaces = {}
	local i = 0

	while true do
		local baseKey = string.format("placeable.baleStorage.balePlace(%d)", i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local entry = {
			node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, baseKey .. "#node"))
		}

		table.insert(self.balePlaces, entry)

		i = i + 1
	end

	if #self.balePlaces == 0 then
		g_logManager:xmlWarning(xmlFilename, "Missing bale places in 'placeable.baleStorage.balePlace#node'!")
		delete(xmlFile)

		return false
	end

	self.physicalBalePlace = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, "placeable.baleStorage#physicalBalePlace"))

	if self.physicalBalePlace == nil then
		g_logManager:xmlWarning(xmlFilename, "Missing physical bale place in 'placeable.baleStorage#physicalBalePlace'!")
		delete(xmlFile)

		return false
	end

	if hasXMLProperty(xmlFile, "placeable.baleStorage.poiTrigger") then
		self.poiTrigger = POITrigger:new()

		if not self.poiTrigger:loadFromXML(self.nodeId, xmlFile, "placeable.baleStorage.poiTrigger") then
			self.poiTrigger:delete()

			self.poiTrigger = nil
		end
	end

	delete(xmlFile)

	return true
end

function BaleStoragePlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
	if not BaleStoragePlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
		return false
	end

	self.storedBales = {}
	local i = 0

	while true do
		local baseKey = string.format("%s.baleStorage.bale(%d)", key, i)

		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end

		local storedBale = {
			filename = getXMLString(xmlFile, baseKey .. "#filename"),
			fillLevel = getXMLFloat(xmlFile, baseKey .. "#fillLevel"),
			isOpticalBale = getXMLBool(xmlFile, baseKey .. "#isOpticalBale"),
			isPhysicsBale = getXMLBool(xmlFile, baseKey .. "#isPhysicsBale"),
			ownerFarmId = getXMLInt(xmlFile, baseKey .. "#ownerFarmId") or 1
		}

		table.insert(self.storedBales, storedBale)

		if storedBale.isPhysicsBale then
			self.physicsBale = self:addPhysicalBale(storedBale)

			self:raiseActive()
		elseif storedBale.isOpticalBale then
			local opticalBale = self:addOpticalBale(storedBale)
			storedBale.opticalBale = opticalBale
		end

		g_farmManager:updateFarmStats(self:getOwnerFarmId(), "storedBales", 1)

		i = i + 1
	end

	return true
end

function BaleStoragePlaceable:saveToXMLFile(xmlFile, key, usedModNames)
	BaleStoragePlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

	for i, storedBale in ipairs(self.storedBales) do
		local baleKey = string.format("%s.baleStorage.bale(%d)", key, i - 1)

		setXMLString(xmlFile, baleKey .. "#filename", storedBale.filename)
		setXMLFloat(xmlFile, baleKey .. "#fillLevel", storedBale.fillLevel)
		setXMLBool(xmlFile, baleKey .. "#isOpticalBale", Utils.getNoNil(storedBale.isOpticalBale, false))
		setXMLBool(xmlFile, baleKey .. "#isPhysicsBale", Utils.getNoNil(storedBale.isPhysicsBale, false))
		setXMLInt(xmlFile, baleKey .. "#ownerFarmId", Utils.getNoNil(storedBale.ownerFarmId, 1))
	end
end

function BaleStoragePlaceable:updateTick(dt)
	if self.physicsBale ~= nil then
		local foundBale = false

		if entityExists(self.physicsBale.nodeId) then
			local x, y, z = getWorldTranslation(self.physicalBalePlace)
			local bx, by, bz = getWorldTranslation(self.physicsBale.nodeId)
			local distance = MathUtil.vector3Length(x - bx, y - by, z - bz)

			if distance < 0.5 then
				foundBale = true
			end
		end

		if not foundBale then
			g_currentMission:addItemToSave(self.physicsBale)

			for i, storedBale in ipairs(self.storedBales) do
				if storedBale.isPhysicsBale then
					table.remove(self.storedBales, i)
					g_farmManager:updateFarmStats(self:getOwnerFarmId(), "storedBales", -1)
				end
			end

			self.physicsBale = nil
		end
	elseif #self.storedBales > 0 then
		local sizeBale = self.opticalBales[1]

		if sizeBale ~= nil then
			local x, y, z = getWorldTranslation(self.physicalBalePlace)
			local rx, ry, rz = getWorldRotation(self.physicalBalePlace)
			local sizeX = sizeBale.baleWidth
			local sizeY = sizeBale.baleHeight or sizeBale.baleDiameter
			local sizeZ = sizeBale.baleLength or sizeBale.baleDiameter
			self.freeSpace = true

			overlapBox(x, y, z, rx, ry, rz, sizeX / 2, sizeY / 2, sizeZ / 2, "baleOverlapCallback", self, 16781314, true, false, true)

			if self.freeSpace then
				local replacedPhysicsBale = false

				for _, storedBale in ipairs(self.storedBales) do
					if not storedBale.isOpticalBale and not storedBale.isPhysicsBale then
						self.physicsBale = self:addPhysicalBale(storedBale)
						storedBale.isPhysicsBale = true
						replacedPhysicsBale = true

						break
					end
				end

				if not replacedPhysicsBale then
					local opticalBale = self.opticalBales[#self.opticalBales]

					if opticalBale ~= nil then
						for _, storedBale in ipairs(self.storedBales) do
							if opticalBale.baleData == storedBale then
								self:removeOpticalBale()

								self.physicsBale = self:addPhysicalBale(storedBale)
								storedBale.isPhysicsBale = true

								break
							end
						end
					end
				end
			end
		end
	end

	for index, baleLoader in ipairs(self.baleLoadersInTrigger) do
		if baleLoader:getIsAutomaticBaleUnloadingAllowed() then
			local bales = baleLoader:getLoadedBales()
			local unloadingAllowed = false

			for i, bale in ipairs(bales) do
				local fillType = bale:getFillType()

				for _, fillTypeSupported in ipairs(self.fillTypes) do
					if fillType == fillTypeSupported then
						unloadingAllowed = true

						break
					end
				end
			end

			if unloadingAllowed then
				baleLoader:startAutomaticBaleUnloading()
			end
		end
	end

	if self.physicsBale ~= nil or self.physicsBale == nil and #self.storedBales > 0 or #self.baleLoadersInTrigger > 0 then
		self:raiseActive()
	end

	BaleStoragePlaceable:superClass().updateTick(self, dt)
end

function BaleStoragePlaceable:baleOverlapCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local object = g_currentMission:getNodeObject(transformId)

		if object ~= nil and getRigidBodyType(transformId) == "Dynamic" then
			self.freeSpace = false
		end
	end
end

function BaleStoragePlaceable:baleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil then
			if object:isa(Bale) and object:getAllowPickup() then
				if onEnter then
					for _, fillType in ipairs(self.fillTypes) do
						if object:getFillType() == fillType then
							if #self.storedBales < self.capacity then
								self:addBale(object)

								break
							end

							self:showWarning("warning_noMoreFreeCapacity", object:getFillType())

							break
						end

						self:showWarning("warning_notAcceptedHere", object:getFillType())

						break
					end
				end
			elseif g_platformSettingsManager:getSetting("automaticBaleDrop", false) and object:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations) then
				if onEnter then
					table.insert(self.baleLoadersInTrigger, object)
					self:raiseActive()
				elseif onLeave then
					for index, baleLoader in ipairs(self.baleLoadersInTrigger) do
						if baleLoader == object then
							table.remove(self.baleLoadersInTrigger, index)

							break
						end
					end
				end
			end
		end
	end
end

function BaleStoragePlaceable:showWarning(warningText, fillTypeIndex)
	warningText = g_i18n:getText(warningText)
	local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local warning = string.format(warningText, fillTypeDesc.title)

	g_currentMission:showBlinkingWarning(warning, 5000)
end

function BaleStoragePlaceable:addBale(bale)
	if bale == self.physicsBale then
		return
	end

	for _, opticalBale in ipairs(self.opticalBales) do
		if bale == opticalBale then
			return
		end
	end

	local baleData = {
		filename = bale.i3dFilename,
		fillLevel = bale.fillLevel,
		ownerFarmId = bale.ownerFarmId
	}

	if self.physicsBale ~= nil then
		local opticalBale = self:addOpticalBale(baleData)

		bale:delete()

		baleData.opticalBale = opticalBale
		baleData.isOpticalBale = opticalBale ~= nil
	else
		removeFromPhysics(bale.nodeId)
		setWorldTranslation(bale.nodeId, getWorldTranslation(self.physicalBalePlace))
		setWorldRotation(bale.nodeId, getWorldRotation(self.physicalBalePlace))
		addToPhysics(bale.nodeId)

		self.physicsBale = bale
		baleData.isPhysicsBale = true

		g_currentMission:removeItemToSave(bale)
		self:raiseActive()
	end

	table.insert(self.storedBales, baleData)
	g_farmManager:updateFarmStats(self:getOwnerFarmId(), "storedBales", 1)
end

function BaleStoragePlaceable:addOpticalBale(baleData)
	if #self.opticalBales < #self.balePlaces then
		local balePlace = self.balePlaces[#self.opticalBales + 1]

		if balePlace ~= nil then
			local x, y, z = getWorldTranslation(balePlace.node)
			local rx, ry, rz = getWorldRotation(balePlace.node)
			local baleObject = Bale:new(self.isServer, self.isClient)

			baleObject:load(baleData.filename, x, y, z, rx, ry, rz, baleData.fillLevel)
			baleObject:register()
			baleObject:setCanBeSold(false)

			baleObject.baleData = baleData

			setRigidBodyType(baleObject.nodeId, "Kinematic")

			baleObject.allowPickup = false

			g_currentMission:removeItemToSave(baleObject)
			table.insert(self.opticalBales, baleObject)

			return baleObject
		end
	end
end

function BaleStoragePlaceable:removeOpticalBale()
	local numBales = #self.opticalBales

	if numBales > 0 then
		local bale = self.opticalBales[numBales]

		bale:delete()

		self.opticalBales[numBales] = nil
	end
end

function BaleStoragePlaceable:addPhysicalBale(baleData)
	local x, y, z = getWorldTranslation(self.physicalBalePlace)
	local rx, ry, rz = getWorldRotation(self.physicalBalePlace)
	local baleObject = Bale:new(self.isServer, self.isClient)

	baleObject:load(baleData.filename, x, y, z, rx, ry, rz, baleData.fillLevel)
	baleObject:setOwnerFarmId(baleData.ownerFarmId)
	baleObject:register()
	baleObject:setCanBeSold(true)
	g_currentMission:removeItemToSave(baleObject)

	return baleObject
end
