VehicleCharacter = {}
local VehicleCharacter_mt = Class(VehicleCharacter)

function VehicleCharacter:new(vehicle, customMt)
	if customMt == nil then
		customMt = VehicleCharacter_mt
	end

	local self = setmetatable({}, customMt)
	self.vehicle = vehicle
	self.characterNode = nil
	self.allowUpdate = true
	self.ikChains = {}
	self.ikChainTargets = {}
	self.animationCharsetId = 0
	self.animationPlayer = 0
	self.useAnimation = false

	return self
end

function VehicleCharacter:load(xmlFile, xmlNode)
	if getXMLString(xmlFile, xmlNode .. "#index") ~= nil then
		g_logManager:warning("'%s' is not supported anymore, use '%s' instead!", xmlNode .. "#index", xmlNode .. "#node")
	end

	self.characterNode = I3DUtil.indexToObject(self.vehicle.components, getXMLString(xmlFile, xmlNode .. "#node"), self.vehicle.i3dMappings)

	if self.characterNode ~= nil then
		self.characterCameraMinDistance = Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#cameraMinDistance"), 1.5)
		self.characterDistanceRefNode = I3DUtil.indexToObject(self.vehicle.components, getXMLString(xmlFile, xmlNode .. "#distanceRefNode"), self.vehiclei3dMappings)

		if self.characterDistanceRefNode == nil then
			self.characterDistanceRefNode = self.characterNode
		end

		setVisibility(self.characterNode, false)

		self.useAnimation = Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#useAnimation"), false)

		if not self.useAnimation then
			self.ikChainTargets = {}

			IKUtil.loadIKChainTargets(xmlFile, xmlNode, self.vehicle.components, self.ikChainTargets, self.vehicle.i3dMappings)
		end

		self.characterSpineRotation = StringUtil.getRadiansFromString(getXMLString(xmlFile, xmlNode .. "#spineRotation"), 3)
		self.characterSpineSpeedDepended = Utils.getNoNil(getXMLBool(xmlFile, xmlNode .. "#speedDependedSpine"), false)
		self.characterSpineNodeMinRot = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#spineNodeMinRot"), 10))
		self.characterSpineNodeMaxRot = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#spineNodeMaxRot"), -10))
		self.characterSpineNodeMinAcc = Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#spineNodeMinAcc"), -1) / 1000000
		self.characterSpineNodeMaxAcc = Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#spineNodeMaxAcc"), 1) / 1000000
		self.characterSpineNodeAccDeadZone = Utils.getNoNil(getXMLFloat(xmlFile, xmlNode .. "#spineNodeAccDeadZone"), 0.2) / 1000000
		self.characterSpineLastRotation = 0

		self:setCharacterVisibility(false)

		return true
	end

	return false
end

function VehicleCharacter:getParentComponent()
	return self.vehicle:getParentComponent(self.characterNode)
end

function VehicleCharacter:loadCharacter(xmlFilename, playerStyle)
	local linkNode = Utils.getNoNil(self.characterNode, self.vehicle.rootNode)

	if not Player.loadVisuals(self, xmlFilename, playerStyle, linkNode, false, self.ikChains, nil, , self.characterNode) then
		self:delete()

		return false
	end

	local specIK = self.vehicle.spec_ikChains

	if specIK ~= nil then
		for chainId, chain in pairs(self.ikChains) do
			specIK.chains[chainId] = chain
		end

		for ikChainId, target in pairs(self.ikChainTargets) do
			IKUtil.setTarget(self.ikChains, ikChainId, target)
		end
	end

	if self.characterSpineRotation ~= nil and self.thirdPersonSpineNode ~= nil then
		setRotation(self.thirdPersonSpineNode, unpack(self.characterSpineRotation))
	end

	if self.useAnimation and self.skeletonThirdPerson ~= nil and getNumOfChildren(self.skeletonThirdPerson) > 0 then
		local animNode = g_animCache:getNode(AnimationCache.CHARACTER)

		cloneAnimCharacterSet(getChildAt(animNode, 0), self.skeletonThirdPerson)

		self.animationCharsetId = getAnimCharacterSet(getChildAt(self.skeletonThirdPerson, 0))
		self.animationPlayer = createConditionalAnimation()

		if self.animationCharsetId == 0 then
			g_logManager:devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(self.skeletonThirdPerson)), getName(self.skeletonThirdPerson))
			printScenegraph(getParent(self.skeletonThirdPerson))
		end
	end

	self:setCharacterDirty()
	self:setCharacterVisibility(true)

	self.isCharacterLoaded = true

	return true
end

function VehicleCharacter:delete()
	if self.isCharacterLoaded then
		local specIK = self.vehicle.spec_ikChains

		if specIK ~= nil then
			for chainId, _ in pairs(self.ikChains) do
				specIK.chains[chainId] = nil
			end
		end

		Player.deleteVisuals(self, self.ikChains)
	end

	self.isCharacterLoaded = false

	if self.animationPlayer ~= 0 then
		delete(self.animationPlayer)

		self.animationPlayer = 0
	end
end

function VehicleCharacter:setCharacterDirty()
	self:setDirty(true)
end

function VehicleCharacter:setDirty(setAllDirty)
	for chainId, target in pairs(self.ikChainTargets) do
		if target.setDirty or setAllDirty then
			IKUtil.setIKChainDirty(self.ikChains, chainId)
		end
	end
end

function VehicleCharacter:updateIKChains()
	IKUtil.updateIKChains(self.ikChains)
end

function VehicleCharacter:setSpineDirty(acc)
	if math.abs(acc) < self.characterSpineNodeAccDeadZone then
		acc = 0
	end

	local alpha = MathUtil.clamp((acc - self.characterSpineNodeMinAcc) / (self.characterSpineNodeMaxAcc - self.characterSpineNodeMinAcc), 0, 1)
	local rotation = MathUtil.lerp(self.characterSpineNodeMinRot, self.characterSpineNodeMaxRot, alpha)

	if rotation ~= self.characterSpineLastRotation then
		self.characterSpineLastRotation = self.characterSpineLastRotation * 0.95 + rotation * 0.05

		setRotation(self.spineNode, self.characterSpineLastRotation, 0, 0)
		self:setDirty()
	end
end

function VehicleCharacter:updateVisibility(isVisible)
	if entityExists(self.characterDistanceRefNode) and entityExists(getCamera()) then
		local dist = calcDistanceFrom(self.characterDistanceRefNode, getCamera())
		local visible = self.characterCameraMinDistance <= dist

		self:setCharacterVisibility(visible)
	end
end

function VehicleCharacter:setCharacterVisibility(isVisible)
	if self.characterNode ~= nil then
		setVisibility(self.characterNode, isVisible)
	end

	if self.meshThirdPerson ~= nil then
		setVisibility(self.meshThirdPerson, isVisible)
	end
end

function VehicleCharacter:setAllowCharacterUpdate(state)
	self.allowUpdate = state
end

function VehicleCharacter:getAllowCharacterUpdate()
	return self.allowUpdate
end

function VehicleCharacter:update(dt)
	if self:getAllowCharacterUpdate() then
		self:setCharacterDirty()
	end
end

function VehicleCharacter:getIKChainTargets()
	return self.ikChainTargets
end

function VehicleCharacter:setIKChainTargets(targets, force)
	if self.ikChainTargets ~= targets or force then
		self.ikChainTargets = targets

		if self.isCharacterLoaded then
			for ikChainId, target in pairs(self.ikChainTargets) do
				IKUtil.setTarget(self.ikChains, ikChainId, target)
			end

			self:setCharacterDirty()
		end
	end
end

function VehicleCharacter:getPlayerStyle()
	return self.visualInformation
end
