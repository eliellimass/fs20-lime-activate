EffectManager = {}
local EffectManager_mt = Class(EffectManager, AbstractManager)

function EffectManager:new(customMt)
	local self = AbstractManager:new(customMt or EffectManager_mt)

	return self
end

function EffectManager:initDataStructures()
	self.runningEffects = {}
	self.registeredEffectClasses = {}
end

function EffectManager:loadEffect(xmlFile, baseName, rootNode, parent, i3dMapping)
	local effects = {}
	local i = 0

	while true do
		local key = string.format(baseName .. ".effectNode(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local effectClassName = Utils.getNoNil(getXMLString(xmlFile, key .. "#effectClass"), "ShaderPlaneEffect")
		local effectClass = self:getEffectClass(effectClassName)

		if effectClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
			end

			if effectClass == nil then
				effectClass = ClassUtil.getClassObject(effectClassName)
			end
		end

		if effectClass ~= nil then
			local effect = effectClass:new()

			if effect ~= nil then
				table.insert(effects, effect:load(xmlFile, key, rootNode, parent, i3dMapping))
			end
		else
			print("Warning: Unkown effect '" .. effectClassName .. "' in '" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "'")
		end

		i = i + 1
	end

	return effects
end

function EffectManager:loadFromNode(node, parent)
	local effects = {}

	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)
		local effectClassName = Utils.getNoNil(getUserAttribute(child, "effectClass"), "ShaderPlaneEffect")
		local effectClass = self:getEffectClass(effectClassName)

		if effectClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
			end

			if effectClass == nil then
				effectClass = ClassUtil.getClassObject(effectClassName)
			end
		end

		if effectClass ~= nil then
			local effect = effectClass:new()

			if effect ~= nil then
				table.insert(effects, effect:loadFromNode(child, parent))
			end
		else
			print("Warning: Unkown effect '" .. effectClassName .. "' in '" .. getName(node) .. "'")
		end
	end

	return effects
end

function EffectManager:registerEffectClass(className, effectClass)
	if not ClassUtil.getIsValidClassName(className) then
		print("Error: Invalid effect class name: " .. className)

		return
	end

	self.registeredEffectClasses[className] = effectClass
end

function EffectManager:getEffectClass(className)
	return self.registeredEffectClasses[className]
end

function EffectManager:deleteEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self.runningEffects[effect] = nil

			effect:delete()
		end
	end
end

function EffectManager:update(dt)
	for index, effect in pairs(self.runningEffects) do
		effect:update(dt)

		if not effect:isRunning() then
			self.runningEffects[index] = nil
		end
	end
end

function EffectManager:startEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:startEffect(effect)
		end
	end
end

function EffectManager:startEffect(effect)
	if effect ~= nil and effect:start() then
		self.runningEffects[effect] = effect
	end
end

function EffectManager:stopEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:stopEffect(effect)
		end
	end
end

function EffectManager:stopEffect(effect)
	if effect ~= nil and effect:stop() then
		self.runningEffects[effect] = effect
	end
end

function EffectManager:resetEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:resetEffect(effect)
		end
	end
end

function EffectManager:resetEffect(effect)
	if effect ~= nil then
		self.runningEffects[effect] = nil

		effect:reset()
	end
end

function EffectManager:setFillType(effects, fillType)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setFillType ~= nil then
				effect:setFillType(fillType)
			end
		end
	end
end

function EffectManager:setMinMaxWidth(effects, minWidth, maxWidth, reset)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setMinMaxWidth ~= nil then
				effect:setMinMaxWidth(minWidth, maxWidth, reset)
			end
		end
	end
end

g_effectManager = EffectManager:new()
