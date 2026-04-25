StoreManager = {}
local StoreManager_mt = Class(StoreManager, AbstractManager)
StoreManager.CATEGORY_TYPE = {
	OBJECT = "OBJECT",
	PLACEABLE = "PLACEABLE",
	VEHICLE = "VEHICLE",
	TOOL = "TOOL",
	NONE = ""
}

function StoreManager:new(customMt)
	local self = AbstractManager:new(customMt or StoreManager_mt)

	return self
end

function StoreManager:initDataStructures()
	self.numOfCategories = 0
	self.categories = {}
	self.items = {}
	self.xmlFilenameToItem = {}
	self.modStoreItems = {}
	self.specTypes = {}
	self.nameToSpecType = {}
end

function StoreManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	StoreManager:superClass().loadMapData(self)

	local categoryXMLFile = loadXMLFile("storeCategoriesXML", "dataS/storeCategories.xml")
	local i = 0

	while true do
		local baseXMLName = string.format("categories.category(%d)", i)

		if not hasXMLProperty(categoryXMLFile, baseXMLName) then
			break
		end

		local name = getXMLString(categoryXMLFile, baseXMLName .. "#name")
		local title = getXMLString(categoryXMLFile, baseXMLName .. "#title")
		local imageFilename = getXMLString(categoryXMLFile, baseXMLName .. "#image")
		local type = getXMLString(categoryXMLFile, baseXMLName .. "#type")

		if title ~= nil and title:sub(1, 6) == "$l10n_" then
			title = g_i18n:getText(title:sub(7))
		end

		self:addCategory(name, title, imageFilename, type, "")

		i = i + 1
	end

	delete(categoryXMLFile)

	local storeItemsFilename = "dataS/storeItems.xml"

	if g_isPresentationVersionSpecialStore then
		storeItemsFilename = g_isPresentationVersionSpecialStorePath
	end

	self:loadItemsFromXML(storeItemsFilename)

	if xmlFile ~= nil then
		local mapStoreItemsFilename = getXMLString(xmlFile, "map.storeItems#filename")

		if mapStoreItemsFilename ~= nil then
			mapStoreItemsFilename = Utils.getFilename(mapStoreItemsFilename, baseDirectory)

			self:loadItemsFromXML(mapStoreItemsFilename)
		end
	end

	for _, item in ipairs(self.modStoreItems) do
		g_deferredLoadingManager:addSubtask(function ()
			self:loadItem(item.xmlFilename, item.baseDir, item.customEnvironment, item.isMod, item.isBundleItem, item.dlcTitle)
		end)
	end

	return true
end

function StoreManager:loadItemsFromXML(filename)
	local xmlFile = loadXMLFile("storeItemsXML", filename)
	local i = 0

	while true do
		local storeItemBaseName = string.format("storeItems.storeItem(%d)", i)

		if not hasXMLProperty(xmlFile, storeItemBaseName) then
			break
		end

		local xmlFilename = getXMLString(xmlFile, storeItemBaseName .. "#xmlFilename")

		g_deferredLoadingManager:addSubtask(function ()
			self:loadItem(xmlFilename, "", nil, false, false, "")
		end)

		i = i + 1
	end

	delete(xmlFile)
end

function StoreManager:addCategory(name, title, imageFilename, type, baseDir)
	if name == nil or name == "" then
		print("Warning: Could not register store category. Name is missing or empty!")

		return false
	end

	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is no valid name for a category!")

		return false
	end

	if title == nil or title == "" then
		print("Warning: Could not register store category. Title is missing or empty!")

		return false
	end

	if imageFilename == nil or imageFilename == "" then
		print("Warning: Could not register store category. Image is missing or empty!")

		return false
	end

	if baseDir == nil then
		print("Warning: Could not register store category. Basedirectory not defined!")

		return false
	end

	name = name:upper()

	if name == "COINS" and (GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID and (g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA")) then
		return false
	end

	if self.categories[name] == nil then
		self.numOfCategories = self.numOfCategories + 1
		local category = {
			name = name,
			title = title,
			image = Utils.getFilename(imageFilename, baseDir),
			type = StoreManager.CATEGORY_TYPE[type] ~= nil and type or StoreManager.CATEGORY_TYPE.NONE,
			orderId = self.numOfCategories
		}
		self.categories[name] = category

		return true
	end

	return false
end

function StoreManager:removeCategory(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is no valid name for a category!")

		return
	end

	name = name:upper()

	for _, item in pairs(self.items) do
		if item.category == name then
			item.category = "MISC"
		end
	end

	self.categories[name] = nil
end

function StoreManager:getCategoryByName(name)
	if name ~= nil then
		return self.categories[name:upper()]
	end

	return nil
end

function StoreManager:addSpecType(name, profile, loadFunc, getValueFunc)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is no valid name for a spec type!")

		return
	end

	if self.nameToSpecType == nil then
		printCallstack()
	end

	if self.nameToSpecType[name] ~= nil then
		print("Error: spec type name '" .. name .. "' is already in use!")

		return
	end

	local specType = {
		name = name,
		profile = profile,
		loadFunc = loadFunc,
		getValueFunc = getValueFunc
	}
	self.nameToSpecType[name] = specType

	table.insert(self.specTypes, specType)
end

function StoreManager:getSpecTypes()
	return self.specTypes
end

function StoreManager:getSpecTypeByName(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is no valid name for a spec type!")

		return
	end

	return self.nameToSpecType[name]
end

function StoreManager:addItem(storeItem)
	if self.xmlFilenameToItem[storeItem.xmlFilenameLower] ~= nil then
		return false
	end

	table.insert(self.items, storeItem)

	storeItem.id = #self.items
	self.xmlFilenameToItem[storeItem.xmlFilenameLower] = storeItem

	return true
end

function StoreManager:removeItemByIndex(index)
	local item = self.items[index]

	if item ~= nil then
		self.xmlFilenameToItem[item.xmlFilenameLower] = nil
		local numItems = table.getn(self.items)

		if index < numItems then
			self.items[index] = self.items[numItems]
			self.items[index].id = index
		end

		table.remove(self.items, numItems)
	end
end

function StoreManager:getItems()
	return self.items
end

function StoreManager:getItemByIndex(index)
	if index ~= nil then
		return self.items[index]
	end

	return nil
end

function StoreManager:getItemByXMLFilename(xmlFilename)
	if xmlFilename ~= nil then
		return self.xmlFilenameToItem[xmlFilename:lower()]
	end
end

function StoreManager:getItemByCustomEnvironment(customEnvironment)
	local items = {}

	for _, item in ipairs(self.items) do
		if item.customEnvironment == customEnvironment then
			table.insert(items, item)
		end
	end

	return items
end

function StoreManager:addModStoreItem(xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)
	table.insert(self.modStoreItems, {
		xmlFilename = xmlFilename,
		baseDir = baseDir,
		customEnvironment = customEnvironment,
		isMod = isMod,
		isBundleItem = isBundleItem,
		dlcTitle = dlcTitle
	})
end

function StoreManager:loadItem(xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)
	local xmlFilename = Utils.getFilename(xmlFilename, baseDir)
	local xmlFile = loadXMLFile("storeItemXML", xmlFilename)
	local baseXMLName = getXMLRootName(xmlFile)
	local storeDataXMLName = baseXMLName .. ".storeData"

	if not hasXMLProperty(xmlFile, storeDataXMLName) then
		g_logManager:xmlError(xmlFilename, "No storeData found. StoreItem will be ignored!")
		delete(xmlFile)

		return nil
	end

	local isValid = true
	local name = XMLUtil.getXMLI18NValue(xmlFile, storeDataXMLName, getXMLString, "name", nil, customEnvironment, true)

	if name == nil then
		g_logManager:xmlWarning(xmlFilename, "Name missing for storeitem. Ignoring store item!")

		isValid = false
	end

	local imageFilename = Utils.getNoNil(getXMLString(xmlFile, storeDataXMLName .. ".image"), "")

	if imageFilename == "" then
		g_logManager:xmlWarning(xmlFilename, "Image icon is missing for storeitem. Ignoring store item!")

		isValid = false
	end

	if not isValid then
		delete(xmlFile)

		return nil
	end

	local storeItem = {
		name = name,
		xmlFilename = xmlFilename,
		xmlFilenameLower = xmlFilename:lower(),
		imageFilename = Utils.getFilename(imageFilename, baseDir),
		functions = StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment),
		specs = StoreItemUtil.getSpecsFromXML(self.specTypes, xmlFile, customEnvironment),
		brandIndex = StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLName, xmlFilename),
		species = Utils.getNoNil(getXMLString(xmlFile, storeDataXMLName .. ".species"), ""),
		canBeSold = Utils.getNoNil(getXMLBool(xmlFile, storeDataXMLName .. ".canBeSold"), true),
		showInStore = Utils.getNoNil(getXMLBool(xmlFile, storeDataXMLName .. ".showInStore"), not isBundleItem),
		isBundleItem = isBundleItem,
		allowLeasing = Utils.getNoNil(getXMLBool(xmlFile, storeDataXMLName .. ".allowLeasing"), true),
		maxItemCount = getXMLInt(xmlFile, storeDataXMLName .. ".maxItemCount"),
		rotation = Utils.getNoNilRad(getXMLFloat(xmlFile, storeDataXMLName .. ".rotation"), 0),
		shopTranslationOffset = StringUtil.getVectorNFromString(getXMLString(xmlFile, storeDataXMLName .. ".shopTranslationOffset"), 3),
		shopRotationOffset = StringUtil.getRadiansFromString(getXMLString(xmlFile, storeDataXMLName .. ".shopRotationOffset"), 3),
		shopHeight = Utils.getNoNil(getXMLFloat(xmlFile, storeDataXMLName .. ".shopHeight"), 0),
		financeCategory = getXMLString(xmlFile, storeDataXMLName .. ".financeCategory"),
		shopFoldingState = Utils.getNoNil(getXMLBool(xmlFile, storeDataXMLName .. ".shopFoldingState"), 0)
	}
	storeItem.sharedVramUsage, storeItem.perInstanceVramUsage, storeItem.ignoreVramUsage = StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
	storeItem.dlcTitle = dlcTitle
	storeItem.isMod = isMod
	storeItem.customEnvironment = customEnvironment
	local categoryName = getXMLString(xmlFile, storeDataXMLName .. ".category")
	local category = self:getCategoryByName(categoryName)

	if category == nil then
		g_logManager:xmlWarning(xmlFilename, "Invalid category '%s' in store data! Using 'misc' instead!", tostring(categoryName))

		category = self:getCategoryByName("misc")
	end

	storeItem.categoryName = category.name
	storeItem.configurations = StoreItemUtil.getConfigurationsFromXML(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
	storeItem.subConfigurations = StoreItemUtil.getSubConfigurationsFromXML(storeItem.configurations)
	storeItem.configurationSets = StoreItemUtil.getConfigurationSetsFromXML(storeItem, xmlFile, baseXMLName, baseDir, customEnvironment, isMod)
	storeItem.price = Utils.getNoNil(getXMLFloat(xmlFile, storeDataXMLName .. ".price"), 0)

	if storeItem.price < 0 then
		g_logManager:xmlWarning(xmlFilename, "Price has to be greater than 0. Using default 10.000 instead!")

		storeItem.price = 10000
	end

	storeItem.dailyUpkeep = Utils.getNoNil(getXMLFloat(xmlFile, storeDataXMLName .. ".dailyUpkeep"), 0)
	storeItem.runningLeasingFactor = Utils.getNoNil(getXMLFloat(xmlFile, storeDataXMLName .. ".runningLeasingFactor"), EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
	storeItem.lifetime = Utils.getNoNil(getXMLFloat(xmlFile, storeDataXMLName .. ".lifetime"), 600)

	if hasXMLProperty(xmlFile, storeDataXMLName .. ".bundleElements") then
		local bundleInfo = {
			bundleItems = {},
			attacherInfo = {}
		}
		local price = 0
		local lifetime = math.huge
		local dailyUpkeep = 0
		local runningLeasingFactor = 0
		local i = 0

		while true do
			local bundleKey = string.format(storeDataXMLName .. ".bundleElements.bundleElement(%d)", i)

			if not hasXMLProperty(xmlFile, bundleKey) then
				break
			end

			local bundleXmlFile = getXMLString(xmlFile, bundleKey .. ".xmlFilename")
			local offset = StringUtil.getVectorNFromString(Utils.getNoNil(getXMLString(xmlFile, bundleKey .. ".offset"), "0 0 0"), 3)
			local rotation = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, bundleKey .. ".yRotation"), 0))

			if bundleXmlFile ~= nil then
				local completePath = Utils.getFilename(bundleXmlFile, baseDir)
				local item = self:getItemByXMLFilename(completePath)

				if item == nil then
					item = self:loadItem(bundleXmlFile, baseDir, customEnvironment, isMod, true, dlcTitle)
				end

				if item ~= nil then
					price = price + item.price
					dailyUpkeep = dailyUpkeep + item.dailyUpkeep
					runningLeasingFactor = runningLeasingFactor + item.runningLeasingFactor
					lifetime = math.min(lifetime, item.lifetime)

					table.insert(bundleInfo.bundleItems, {
						item = item,
						xmlFilename = item.xmlFilename,
						offset = offset,
						rotation = rotation,
						price = item.price
					})
				end
			end

			i = i + 1
		end

		local i = 0

		while true do
			local attachKey = string.format(storeDataXMLName .. ".attacherInfo.attach(%d)", i)

			if not hasXMLProperty(xmlFile, attachKey) then
				break
			end

			local bundleElement0 = getXMLInt(xmlFile, attachKey .. "#bundleElement0")
			local bundleElement1 = getXMLInt(xmlFile, attachKey .. "#bundleElement1")
			local attacherJointIndex = getXMLInt(xmlFile, attachKey .. "#attacherJointIndex")
			local inputAttacherJointIndex = getXMLInt(xmlFile, attachKey .. "#inputAttacherJointIndex")

			if bundleElement0 ~= nil and bundleElement1 ~= nil and attacherJointIndex ~= nil and inputAttacherJointIndex ~= nil then
				table.insert(bundleInfo.attacherInfo, {
					bundleElement0 = bundleElement0,
					bundleElement1 = bundleElement1,
					attacherJointIndex = attacherJointIndex,
					inputAttacherJointIndex = inputAttacherJointIndex
				})
			end

			i = i + 1
		end

		storeItem.price = price
		storeItem.dailyUpkeep = dailyUpkeep
		storeItem.runningLeasingFactor = runningLeasingFactor
		storeItem.lifetime = lifetime
		storeItem.bundleInfo = bundleInfo
	end

	self:addItem(storeItem)
	delete(xmlFile)

	return storeItem
end

g_storeManager = StoreManager:new()
