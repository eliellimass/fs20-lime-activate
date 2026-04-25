AnimalLoadingTrigger = {}
local AnimalLoadingTrigger_mt = Class(AnimalLoadingTrigger, Object)

InitStaticObjectClass(AnimalLoadingTrigger, "AnimalLoadingTrigger", ObjectIds.OBJECT_ANIMAL_LOADING_TRIGGER)

function AnimalLoadingTrigger:onCreate(id)
	local trigger = AnimalLoadingTrigger:new(g_server ~= nil, g_client ~= nil)

	if trigger ~= nil then
		g_currentMission:addOnCreateLoadedObject(trigger)
		trigger:load(id)
		trigger:register(true)
	end
end

function AnimalLoadingTrigger:new(isServer, isClient)
	local self = Object:new(isServer, isClient, AnimalLoadingTrigger_mt)
	self.customEnvironment = g_currentMission.loadingMapModName
	self.isDealer = false
	self.triggerNode = nil
	self.appearsOnPDA = true
	self.title = g_i18n:getText("ui_farm")
	self.animals = nil
	self.activateText = g_i18n:getText("animals_openAnimalScreen", self.customEnvironment)
	self.isActivatableAdded = false
	self.isPlayerInRange = false
	self.isSingleVehicleInRange = false
	self.isEnabled = false
	self.loadingVehicle = nil
	self.activatedTarget = nil
	self.objectActivated = false

	return self
end

function AnimalLoadingTrigger:load(node, husbandry)
	self.husbandry = husbandry
	self.isDealer = Utils.getNoNil(getUserAttribute(node, "isDealer"), false)

	if self.isDealer then
		local animalTypesString = getUserAttribute(node, "animalTypes")

		if animalTypesString ~= nil then
			local animalTypes = StringUtil.splitString(" ", animalTypesString)

			for _, animalTypeStr in pairs(animalTypes) do
				local animalType = g_animalManager:getAnimalsByType(animalTypeStr)

				if animalType ~= nil then
					if self.animalTypes == nil then
						self.animalTypes = {}
					end

					table.insert(self.animalTypes, animalType)
				else
					g_logManager:warning("Invalid animal type '%s' for animalLoadingTrigger '%s'!", animalTypeStr, getName(node))
				end
			end
		end
	end

	self.triggerNode = node

	addTrigger(self.triggerNode, "triggerCallback", self)

	self.appearsOnPDA = Utils.getNoNil(getUserAttribute(node, "appearsOnPDA"), self.isDealer)
	self.title = g_i18n:getText(Utils.getNoNil(getUserAttribute(node, "title"), "ui_farm"), self.customEnvironment)
	self.isEnabled = not g_isPresentationVersion or g_isPresentationVersionShopEnabled

	if self.appearsOnPDA then
		local mapPosition = node
		local mapPositionIndex = getUserAttribute(node, "mapPositionIndex")

		if mapPositionIndex ~= nil then
			mapPosition = I3DUtil.indexToObject(node, mapPositionIndex)

			if mapPosition == nil then
				mapPosition = node
			end
		end

		local x, _, z = getWorldTranslation(mapPosition)
		local fullViewName = Utils.getNoNil(getUserAttribute(node, "stationName"), "animals_dealer")

		if g_i18n:hasText(fullViewName) then
			fullViewName = g_i18n:getText(fullViewName, self.customEnvironment)
		end

		local mapHotspot = MapHotspot:new("livestockDealer", MapHotspot.CATEGORY_DEFAULT)

		mapHotspot:setText(fullViewName)
		mapHotspot:setIcon(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_SELLING_ANIMAL, nil, , )
		mapHotspot:setBackground(MapHotspot.DEFAULT_FILENAME, MapHotspot.UV.DEFAULT_CIRCLE, nil, , )
		mapHotspot:setLinkedNode(mapPosition)
		mapHotspot:setTextBold(true)

		local width, _ = getNormalizedScreenValues(150, 0)

		mapHotspot:setTextWrapWidth(width)

		self.mapHotspot = mapHotspot

		g_currentMission:addMapHotspot(self.mapHotspot)
	end

	return self
end

function AnimalLoadingTrigger:delete()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end

	g_currentMission:removeActivatableObject(self)

	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)

		self.triggerNode = nil
	end
end

function AnimalLoadingTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (onEnter or onLeave) then
		local vehicle = g_currentMission.nodeToObject[otherId]

		if vehicle ~= nil and vehicle.getSupportsAnimalType ~= nil then
			if onEnter then
				self:setLoadingTrailer(vehicle)
			elseif onLeave then
				if vehicle == self.loadingVehicle then
					self:setLoadingTrailer(nil)
				end

				if vehicle == self.activatedTarget then
					g_animalScreen:onVehicleLeftTrigger()

					self.objectActivated = false
				end
			end

			if GS_IS_MOBILE_VERSION and not g_gui:getIsGuiVisible() and onEnter and self:getIsActivatable(vehicle) then
				self:onActivateObject()

				local rootVehicle = vehicle:getRootVehicle()

				if rootVehicle.brakeToStop ~= nil then
					rootVehicle:brakeToStop()
				end
			end
		elseif vehicle ~= nil and vehicle.getIsEnterable ~= nil then
			if GS_IS_MOBILE_VERSION and not g_gui:getIsGuiVisible() then
				local hasAnimalTrailer = false
				local rootVehicle = vehicle:getRootVehicle()
				local vehicles = rootVehicle:getChildVehicles()

				for i = 1, #vehicles do
					if vehicles[i].getSupportsAnimalType ~= nil then
						hasAnimalTrailer = true
					end
				end

				if not hasAnimalTrailer then
					if onEnter then
						if not self.objectActivated then
							self.isSingleVehicleInRange = true

							self:onActivateObject()

							if rootVehicle.brakeToStop ~= nil then
								rootVehicle:brakeToStop()
							end
						end
					else
						self.isSingleVehicleInRange = false
					end

					self:updateActivatableObject()
				end
			end
		elseif g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.isPlayerInRange = true

				if GS_IS_MOBILE_VERSION then
					self:onActivateObject()
				end
			else
				self.isPlayerInRange = false
			end

			self:updateActivatableObject()
		end
	end
end

function AnimalLoadingTrigger:updateActivatableObject()
	if self.loadingVehicle ~= nil or self.isPlayerInRange or self.isSingleVehicleInRange then
		if not self.isActivatableAdded then
			self.isActivatableAdded = true

			g_currentMission:addActivatableObject(self)
		end
	elseif self.isActivatableAdded and self.loadingVehicle == nil and not self.isPlayerInRange and not self.isSingleVehicleInRange then
		g_currentMission:removeActivatableObject(self)

		self.isActivatableAdded = false
		self.objectActivated = false
	end
end

function AnimalLoadingTrigger:setLoadingTrailer(loadingVehicle)
	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(nil)
	end

	self.loadingVehicle = loadingVehicle

	if self.loadingVehicle ~= nil and self.loadingVehicle.setLoadingTrigger ~= nil then
		self.loadingVehicle:setLoadingTrigger(self)
	end

	self:updateActivatableObject()
end

function AnimalLoadingTrigger:getIsActivatable(vehicle)
	local canAccess = self.husbandry == nil or self.husbandry:getOwnerFarmId() == g_currentMission:getFarmId()

	if g_gui.currentGui == nil and self.isEnabled and canAccess and g_currentMission:getHasPlayerPermission("tradeAnimals") then
		local rootAttacherVehicle = nil

		if self.loadingVehicle ~= nil then
			rootAttacherVehicle = self.loadingVehicle:getRootVehicle()
		end

		return self.isPlayerInRange or self.isSingleVehicleInRange or rootAttacherVehicle == g_currentMission.controlledVehicle
	end

	return false
end

function AnimalLoadingTrigger:drawActivate()
end

function AnimalLoadingTrigger:onActivateObject()
	g_currentMission:removeActivatableObject(self)

	self.isActivatableAdded = false
	self.objectActivated = true
	self.activatedTarget = self.loadingVehicle
	local husbandry = self.husbandry

	if self.isDealer and self.loadingVehicle == nil then
		local husbandries = g_currentMission:getHusbandries()

		if #husbandries > 1 then
			g_gui:showAnimalDialog({
				title = g_i18n:getText("category_animalpens"),
				husbandries = husbandries,
				callback = self.onSelectedHusbandry,
				target = self
			})

			return
		elseif #husbandries == 1 then
			husbandry = husbandries[1]
		end
	end

	self:showAnimalScreen(husbandry)
end

function AnimalLoadingTrigger:showAnimalScreen(husbandry)
	local controller = g_animalScreen:getController()

	controller:setTrailer(self.loadingVehicle)
	controller:setHusbandry(husbandry)
	controller:setLoadingTrigger(self)
	controller:initialize()
	g_gui:showGui("AnimalScreen")
end

function AnimalLoadingTrigger:onSelectedHusbandry(husbandry)
	if husbandry ~= nil then
		self:showAnimalScreen(husbandry)
	else
		self:updateActivatableObject()
	end
end

function AnimalLoadingTrigger:getAnimals()
	return self.animalTypes
end
