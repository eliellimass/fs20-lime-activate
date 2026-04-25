AnimationElement = {}
local AnimationElement_mt = Class(AnimationElement, BitmapElement)

function AnimationElement:new(target, custom_mt)
	local self = BitmapElement:new(target, custom_mt or AnimationElement_mt)
	self.animationOffset = -1
	self.animationFrames = 8
	self.animationTimer = 0
	self.animationSpeed = 120
	self.animationFrameSize = 0
	self.animationStartPos = 0
	self.animationUVOffset = 0

	return self
end

function AnimationElement:loadFromXML(xmlFile, key)
	AnimationElement:superClass().loadFromXML(self, xmlFile, key)

	self.animationOffset = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationOffset"), self.animationOffset)
	self.animationFrames = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationFrames"), self.animationFrames)
	self.animationSpeed = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationSpeed"), self.animationSpeed)
	local animationUVOffset = getXMLString(xmlFile, key .. "#animationUVOffset")

	if animationUVOffset ~= nil then
		animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
		self.animationUVOffset = animationUVOffset[1]
	end

	local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
	self.animationDefaultUVs = ListUtil.copyTable(uvs)

	self:setAnimationData()
end

function AnimationElement:loadProfile(profile, applyProfile)
	AnimationElement:superClass().loadProfile(self, profile, applyProfile)

	self.animationOffset = profile:getNumber("animationOffset", self.animationOffset)
	self.animationFrames = profile:getNumber("animationFrames", self.animationFrames)
	self.animationSpeed = profile:getNumber("animationSpeed", self.animationSpeed)
	local animationUVOffset = profile:getValue("animationUVOffset")

	if animationUVOffset ~= nil then
		animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
		self.animationUVOffset = animationUVOffset[1]
	end
end

function AnimationElement:copyAttributes(src)
	AnimationElement:superClass().copyAttributes(self, src)

	self.animationDefaultUVs = ListUtil.copyTable(src.animationDefaultUVs)
	self.animationOffset = src.animationOffset
	self.animationFrames = src.animationFrames
	self.animationSpeed = src.animationSpeed
	self.animationUVOffset = src.animationUVOffset

	self:setImageUVs(nil, unpack(self.animationDefaultUVs))
	self:setAnimationData()
end

function AnimationElement:update(dt)
	AnimationElement:superClass().update(self, dt)

	self.animationTimer = self.animationTimer - dt

	if self.animationTimer < 0 then
		self.animationTimer = self.animationSpeed
		self.animationOffset = self.animationOffset + 1

		if self.animationOffset > self.animationFrames - 1 then
			self.animationOffset = 0
		end

		self:updateAnimationUVs()
	end
end

function AnimationElement:updateAnimationUVs()
	local frameOffset = self.animationStartPos + (self.animationFrameSize + self.animationUVOffset) * self.animationOffset

	self:setImageUVs(nil, frameOffset, nil, frameOffset, nil, frameOffset + self.animationFrameSize, nil, frameOffset + self.animationFrameSize, nil)
end

function AnimationElement:setAnimationData()
	if self.overlay ~= nil then
		local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
		self.animationFrameSize = (uvs[5] - uvs[1] - self.animationUVOffset * (self.animationFrames - 1)) / self.animationFrames
		self.animationStartPos = uvs[1]

		self:updateAnimationUVs()
	end
end
