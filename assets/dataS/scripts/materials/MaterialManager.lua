MaterialManager = {}
MaterialType = nil
local MaterialManager_mt = Class(MaterialManager, AbstractManager)

function MaterialManager:new(customMt)
	local self = AbstractManager:new(customMt or MaterialManager_mt)

	return self
end

function MaterialManager:initDataStructures()
	self.nameToIndex = {}
	self.materialTypes = {}
	self.materials = {}
	self.modMaterialHoldersToLoad = {}
end

function MaterialManager:loadMapData()
	MaterialManager:superClass().loadMapData(self)
	self:addMaterialType("fillplane")
	self:addMaterialType("icon")
	self:addMaterialType("unloading")
	self:addMaterialType("smoke")
	self:addMaterialType("straw")
	self:addMaterialType("chopper")
	self:addMaterialType("soil")
	self:addMaterialType("sprayer")
	self:addMaterialType("spreader")
	self:addMaterialType("pipe")
	self:addMaterialType("mower")
	self:addMaterialType("belt")
	self:addMaterialType("leveler")
	self:addMaterialType("washer")
	self:addMaterialType("pickup")

	MaterialType = self.nameToIndex

	return true
end

function MaterialManager:addMaterialType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a materialType. Ignoring it!")

		return nil
	end

	name = name:upper()

	if self.nameToIndex[name] == nil then
		table.insert(self.materialTypes, name)

		self.nameToIndex[name] = #self.materialTypes
	end
end

function MaterialManager:getMaterialTypeByName(name)
	if name ~= nil then
		name = name:upper()

		if self.nameToIndex[name] ~= nil then
			return name
		end
	end

	return nil
end

function MaterialManager:addMaterial(fillTypeIndex, materialType, materialIndex, materialId)
	if fillTypeIndex == nil or materialType == nil or materialIndex == nil or materialId == nil then
		return nil
	end

	if self.materials[fillTypeIndex] == nil then
		self.materials[fillTypeIndex] = {}
	end

	local fillTypeMaterials = self.materials[fillTypeIndex]

	if fillTypeMaterials[materialType] == nil then
		fillTypeMaterials[materialType] = {}
	end

	local materialTypes = fillTypeMaterials[materialType]

	if g_showDevelopmentWarnings and materialTypes[materialIndex] ~= nil then
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

		g_logManager:devWarning("Material type '%s' already exists for fillType '%s'. It will be overwritten!", tostring(materialType), tostring(fillType.name))
	end

	materialTypes[materialIndex] = materialId
end

function MaterialManager:getMaterial(fillType, materialTypeName, materialIndex)
	if fillType == nil or materialTypeName == nil or materialIndex == nil then
		return nil
	end

	local materialType = self:getMaterialTypeByName(materialTypeName)

	if materialType == nil then
		return nil
	end

	local fillTypeMaterials = self.materials[fillType]

	if fillTypeMaterials == nil then
		return nil
	end

	local materials = fillTypeMaterials[materialType]

	if materials == nil then
		return nil
	end

	return materials[materialIndex]
end

function MaterialManager:addModMaterialHolder(filename)
	self.modMaterialHoldersToLoad[filename] = filename
end

function MaterialManager:loadModMaterialHolders()
	for filename, _ in pairs(self.modMaterialHoldersToLoad) do
		local i3dNode = loadI3DFile(filename, false, true, true)

		for i = getNumOfChildren(i3dNode) - 1, 0, -1 do
			local child = getChildAt(i3dNode, i)

			unlink(child)
		end

		delete(i3dNode)
	end
end

g_materialManager = MaterialManager:new()
