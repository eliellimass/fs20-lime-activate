Brand = nil
BrandManager = {}
local BrandManager_mt = Class(BrandManager, AbstractManager)

function BrandManager:new(customMt)
	local self = AbstractManager:new(customMt or BrandManager_mt)

	return self
end

function BrandManager:initDataStructures()
	self.numOfBrands = 0
	self.nameToIndex = {}
	self.nameToBrand = {}
	self.indexToBrand = {}
	Brand = self.nameToIndex
end

function BrandManager:loadMapData(missionInfo)
	BrandManager:superClass().loadMapData(self)

	local xmlFile = loadXMLFile("brandsXML", "dataS/brands.xml")
	local i = 0

	while true do
		local baseXMLName = string.format("brands.brand(%d)", i)

		if not hasXMLProperty(xmlFile, baseXMLName) then
			break
		end

		local name = getXMLString(xmlFile, baseXMLName .. "#name")
		local title = nil

		if g_languageShort == "cs" then
			title = getXMLString(xmlFile, baseXMLName .. "#title_cs")

			if title == nil then
				title = getXMLString(xmlFile, baseXMLName .. "#title")
			end
		else
			title = getXMLString(xmlFile, baseXMLName .. "#title")
		end

		local image = getXMLString(xmlFile, baseXMLName .. "#image")
		local imageShopOverview = getXMLString(xmlFile, baseXMLName .. "#imageShopOverview")

		if title ~= nil and title:sub(1, 6) == "$l10n_" then
			title = g_i18n:getText(title:sub(7))
		end

		self:addBrand(name, title, image, "", false, imageShopOverview)

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview)
	if name == nil or name == "" then
		print("Warning: Could not register brand. Name is missing or empty!")

		return false
	end

	if title == nil or title == "" then
		print("Warning: Could not register brand. Title is missing or empty!")

		return false
	end

	if imageFilename == nil or imageFilename == "" then
		print("Warning: Could not register brand. Image is missing or empty!")

		return false
	end

	if baseDir == nil then
		print("Warning: Could not register brand. Basedirectory not defined!")

		return false
	end

	if imageShopOverview == nil then
		imageShopOverview = imageFilename
	end

	name = name:upper()

	if ClassUtil.getIsValidIndexName(name) then
		if self.nameToIndex[name] == nil then
			self.numOfBrands = self.numOfBrands + 1
			self.nameToIndex[name] = self.numOfBrands
			local brand = {
				index = self.numOfBrands,
				name = name,
				image = Utils.getFilename(imageFilename, baseDir),
				imageShopOverview = Utils.getFilename(imageShopOverview, baseDir),
				title = title,
				isMod = isMod
			}
			self.nameToBrand[name] = brand
			self.indexToBrand[self.numOfBrands] = brand

			return brand
		end
	else
		print("Warning: invalid brand name '" .. tostring(name) .. "'! Only capital letters allowed!")
	end
end

function BrandManager:getBrandByIndex(brandIndex)
	if brandIndex ~= nil then
		return self.indexToBrand[brandIndex]
	end

	return nil
end

function BrandManager:getBrandByName(brandName)
	if brandName ~= nil then
		return self.nameToBrand[brandName:upper()]
	end

	return nil
end

function BrandManager:getBrandIndexByName(brandName)
	if brandName ~= nil then
		return self.nameToIndex[brandName:upper()]
	end

	return nil
end

g_brandManager = BrandManager:new()
