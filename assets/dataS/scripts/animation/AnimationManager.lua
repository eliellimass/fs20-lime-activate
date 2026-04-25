AnimationManager = {}
local AnimationManager_mt = Class(AnimationManager, AbstractManager)

function AnimationManager:new(customMt)
	local self = AbstractManager:new(customMt or AnimationManager_mt)

	return self
end

function AnimationManager:initDataStructures()
	self.runningAnimations = {}
	self.registeredAnimationClasses = {}
end

function AnimationManager:registerAnimationClass(className, animationClass)
	if not ClassUtil.getIsValidClassName(className) then
		print("Error: Invalid animation class name: " .. className)

		return
	end

	self.registeredAnimationClasses[className] = animationClass
end

function AnimationManager:getAnimationClass(className)
	return self.registeredAnimationClasses[className]
end

function AnimationManager:loadAnimations(xmlFile, baseName, rootNode, parent, i3dMapping)
	local animations = {}
	local i = 0

	while true do
		local key = string.format(baseName .. ".animationNode(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local animationClassName = getXMLString(xmlFile, key .. "#class") or "RotationAnimation"
		local animationClass = self:getAnimationClass(animationClassName)

		if animationClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				animationClass = self:getAnimationClass(parent.customEnvironment .. "." .. animationClassName)
			end

			if animationClass == nil then
				animationClass = ClassUtil.getClassObject(animationClassName)
			end
		end

		if animationClass ~= nil then
			local animation = animationClass:new()

			if animation ~= nil then
				table.insert(animations, animation:load(xmlFile, key, rootNode, parent, i3dMapping))
			end
		else
			print("Warning: Unkown animation '" .. animationClassName .. "' in '" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "'")
		end

		i = i + 1
	end

	return animations
end

function AnimationManager:deleteAnimations(animations)
	if animations ~= nil then
		for i = #animations, 1, -1 do
			local animation = animations[i]
			self.runningAnimations[animation] = nil

			animation:delete()
			table.remove(animations, i)
		end
	end
end

function AnimationManager:update(dt)
	for index, animation in pairs(self.runningAnimations) do
		animation:update(dt)

		if not animation:isRunning() then
			self.runningAnimations[index] = nil
		end
	end
end

function AnimationManager:areAnimationsRunning(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			if animation:isRunning() then
				return true
			end
		end
	end

	return false
end

function AnimationManager:startAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:startAnimation(animation)
		end
	end
end

function AnimationManager:startAnimation(animation)
	if animation ~= nil and animation:start() then
		self.runningAnimations[animation] = animation
	end
end

function AnimationManager:stopAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:stopAnimation(animation)
		end
	end
end

function AnimationManager:stopAnimation(animation)
	if animation.stop == nil then
		printCallstack()
	end

	if animation ~= nil and animation:stop() then
		self.runningAnimations[animation] = animation
	end
end

function AnimationManager:resetAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:resetAnimation(animation)
		end
	end
end

function AnimationManager:resetAnimation(animation)
	if animation ~= nil then
		self.runningAnimations[animation] = nil

		animation:reset()
	end
end

function AnimationManager:setFillType(animations, fillType)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			if animation.setFillType ~= nil then
				animation:setFillType(fillType)
			end
		end
	end
end

g_animationManager = AnimationManager:new()
