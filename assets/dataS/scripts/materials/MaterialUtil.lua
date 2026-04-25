MaterialUtil = {
	onCreateMaterial = function (_, id)
		local fillTypeStr = getUserAttribute(id, "fillType")

		if fillTypeStr == nil then
			print("Warning: No fillType given in '" .. getName(id) .. "' for MaterialUtil.onCreateMaterial")

			return
		end

		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex == nil then
			print("Warning: Unknown fillType '" .. tostring(fillTypeStr) .. "' for MaterialUtil.onCreateMaterial")

			return
		end

		local materialTypeName = getUserAttribute(id, "materialType")

		if materialTypeName == nil then
			print("Warning: No materialType given for '" .. getName(id) .. "' for MaterialUtil.onCreateMaterial")

			return
		end

		local materialType = g_materialManager:getMaterialTypeByName(materialTypeName)

		if materialType == nil then
			print("Warning: Unknown materialType '" .. materialTypeName .. "' given for '" .. getName(id) .. "' for MaterialUtil.onCreateMaterial")

			return
		end

		local matIdStr = Utils.getNoNil(getUserAttribute(id, "materialIndex"), 1)
		local materialIndex = tonumber(matIdStr)

		if materialIndex == nil then
			print("Warning: Invalid materialIndex '" .. matIdStr .. "' for " .. getName(id) .. "-" .. materialTypeName .. "!")

			return
		end

		g_materialManager:addMaterial(fillTypeIndex, materialType, materialIndex, getMaterial(id, 0))
	end,
	onCreateParticleSystem = function (_, id)
		local fillTypeStr = getUserAttribute(id, "fillType")

		if fillTypeStr == nil then
			print("Warning: No fillType given in '" .. getName(id) .. "' for MaterialUtil.onCreateParticleSystem")

			return
		end

		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex == nil then
			print("Warning: Unknown fillType '" .. tostring(fillTypeStr) .. "' for MaterialUtil.onCreateParticleSystem")

			return
		end

		local particleTypeName = getUserAttribute(id, "particleType")

		if particleTypeName == nil then
			print("Warning: No particleType given for filltype '" .. tostring(fillTypeStr) .. "' for MaterialUtil.onCreateParticleSystem")

			return
		end

		local particleType = g_particleSystemManager:getParticleSystemTypeByName(particleTypeName)

		if particleType == nil then
			print("Warning: Unknown particletype '" .. particleTypeName .. "' given for filltype '" .. tostring(fillTypeStr) .. "' for MaterialUtil.onCreateParticleSystem")

			return
		end

		local defaultEmittingState = Utils.getNoNil(getUserAttribute(id, "defaultEmittingState"), false)
		local worldSpace = Utils.getNoNil(getUserAttribute(id, "worldSpace"), true)
		local forceFullLifespan = Utils.getNoNil(getUserAttribute(id, "forceFullLifespan"), false)
		local particleSystem = {}

		ParticleUtil.loadParticleSystemFromNode(id, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan)
		g_particleSystemManager:addParticleSystem(fillTypeIndex, particleType, particleSystem)
	end,
	onCreateCutterEffect = function (_, id)
		local fruitTypeName = getUserAttribute(id, "fruitType")

		if fruitTypeName == nil then
			print("Warning: No fruitType '" .. tostring(fruitTypeName) .. "' given for MaterialUtil.onCreateCutterEffect")

			return
		end

		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)

		if fruitType == nil then
			print("Warning: Unknown fruitType '" .. tostring(fruitTypeName) .. "' for MaterialUtil.onCreateCutterEffect")

			return
		end

		local cutterEffectTypeName = getUserAttribute(id, "cutterEffectType")

		if cutterEffectTypeName == nil then
			print("Warning: No cutterEffectType given for fruitType '" .. tostring(fruitTypeName) .. "' for MaterialUtil.onCreateCutterEffect")

			return
		end

		local cutterEffectType = g_cutterEffectManager:getCutterEffectTypeByName(cutterEffectTypeName)

		if cutterEffectType == nil then
			print("Warning: Unknown cutterEffectType '" .. tostring(cutterEffectTypeName) .. "' given for fruitType '" .. tostring(fruitTypeName) .. "' for MaterialUtil.onCreateCutterEffect")

			return
		end

		local isThreshing = Utils.getNoNil(getUserAttribute(id, "isThreshing"), true)
		local growthStatesStr = getUserAttribute(id, "growthStates")
		local effectId = CutterEffectType.THRESHING

		if not isThreshing then
			effectId = CutterEffectType.FORAGE
		end

		local growthStates = {}

		if growthStatesStr ~= nil then
			for _, state in pairs({
				StringUtil.getVectorFromString(growthStatesStr)
			}) do
				table.insert(growthStates, state)
			end
		else
			for i = fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState do
				table.insert(growthStates, i)
			end
		end

		g_cutterEffectManager:addCutterEffect(fruitType.index, cutterEffectType, effectId, growthStates, id)
	end
}
