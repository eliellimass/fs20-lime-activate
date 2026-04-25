CutterEffectManager = {}
CutterEffectType = nil
local CutterEffectManager_mt = Class(CutterEffectManager, AbstractManager)

function CutterEffectManager:new(customMt)
	self = AbstractManager:new(customMt or CutterEffectManager_mt)

	return self
end

function CutterEffectManager:initDataStructures()
	self.nameToIndex = {}
	self.cutterEffectTypes = {}
	self.cutterEffects = {}
end

function CutterEffectManager:loadMapData()
	CutterEffectManager:superClass().loadMapData(self)
	self:addCutterEffectType("threshing")
	self:addCutterEffectType("forage")
	self:addCutterEffectType("center")
	self:addCutterEffectType("left")
	self:addCutterEffectType("right")

	CutterEffectType = self.nameToIndex

	return true
end

function CutterEffectManager:addCutterEffectType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a cutterEffectType. Ignoring it!")

		return nil
	end

	name = name:upper()

	if self.nameToIndex[name] == nil then
		table.insert(self.cutterEffectTypes, name)

		self.nameToIndex[name] = #self.cutterEffectTypes
	end
end

function CutterEffectManager:getCutterEffectTypeByName(name)
	if name ~= nil then
		name = name:upper()

		if self.nameToIndex[name] ~= nil then
			return name
		end
	end

	return nil
end

function CutterEffectManager:addCutterEffect(fruitTypeIndex, cutterEffectType, effectId, growthStates, id)
	if fruitTypeIndex == nil or cutterEffectType == nil or effectId == nil or growthStates == nil or id == nil then
		return nil
	end

	if self.cutterEffects[fruitTypeIndex] == nil then
		self.cutterEffects[fruitTypeIndex] = {}
	end

	local cutterEffects = self.cutterEffects[fruitTypeIndex]

	if cutterEffects[cutterEffectType] == nil then
		cutterEffects[cutterEffectType] = {}
	end

	local cutterEffectTypes = cutterEffects[cutterEffectType]

	for _, state in pairs(growthStates) do
		if cutterEffectTypes[effectId] == nil then
			cutterEffectTypes[effectId] = {}
		end

		cutterEffectTypes[effectId][state] = id
	end
end

function CutterEffectManager:getCutterEffects(fruitTypeIndex, effectType, isThreshing)
	if effectType == nil then
		return nil
	end

	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

	if fruitType == nil then
		return
	end

	local fruitEffect = self.cutterEffects[fruitTypeIndex]

	if fruitEffect == nil then
		return nil
	end

	if fruitEffect[effectType] == nil then
		return nil
	end

	local effectId = CutterEffectType.THRESHING

	if isThreshing ~= nil and not isThreshing then
		effectId = CutterEffectType.FORAGE
	end

	return fruitEffect[effectType][effectId]
end

g_cutterEffectManager = CutterEffectManager:new()
