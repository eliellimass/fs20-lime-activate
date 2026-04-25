RenderElement = {}
local RenderElement_mt = Class(RenderElement, GuiElement)

function RenderElement:new(target, custom_mt)
	local self = GuiElement:new(target, custom_mt or RenderElement_mt)
	self.cameraPath = nil
	self.isRenderDirty = false
	self.overlay = 0

	return self
end

function RenderElement:delete()
	self:destroyScene()
	RenderElement:superClass().delete(self)
end

function RenderElement:loadFromXML(xmlFile, key)
	RenderElement:superClass().loadFromXML(self, xmlFile, key)

	self.filename = getXMLString(xmlFile, key .. "#filename")
	self.cameraPath = getXMLString(xmlFile, key .. "#cameraNode")
	self.superSamplingFactor = getXMLInt(xmlFile, key .. "#superSamplingFactor")

	self:addCallback(xmlFile, key .. "#onRenderLoad", "onRenderLoadCallback")
end

function RenderElement:loadProfile(profile, applyProfile)
	RenderElement:superClass().loadProfile(self, profile, applyProfile)

	self.filename = profile:getValue("filename")
	self.cameraPath = profile:getValue("cameraNode")
	self.superSamplingFactor = profile:getNumber("superSamplingFactor")

	if applyProfile then
		self:setScene(self.filename)
	end
end

function RenderElement:copyAttributes(src)
	RenderElement:superClass().copyAttributes(self, src)

	self.filename = src.filename
	self.cameraPath = src.cameraPath
	self.superSamplingFactor = src.superSamplingFactor
end

function RenderElement:createScene()
	self:setScene(self.filename)
end

function RenderElement:destroyScene()
	if self.overlay ~= 0 then
		delete(self.overlay)

		self.overlay = 0
	end

	if self.scene then
		delete(self.scene)

		self.scene = nil
	end
end

function RenderElement:setScene(filename)
	if self.scene ~= nil then
		delete(self.scene)
	end

	self.isLoading = true
	self.filename = filename

	streamI3DFile(filename, "setSceneFinished", self, {}, false, false, false)
end

function RenderElement:setSceneFinished(id)
	if id == 0 then
		print("ERROR: Failed to load character creation scene from '" .. tostring(self.filename) .. "'")
	else
		self.isLoading = false
		self.scene = id

		link(getRootNode(), id)
		self:createOverlay()
	end
end

function RenderElement:createOverlay()
	if self.overlay ~= 0 then
		delete(self.overlay)

		self.overlay = 0
	end

	local resolutionX = math.ceil(g_screenWidth * self.size[1]) * self.superSamplingFactor
	local resolutionY = math.ceil(g_screenHeight * self.size[2]) * self.superSamplingFactor
	local aspectRatio = resolutionX / resolutionY
	local camera = I3DUtil.indexToObject(self.scene, self.cameraPath)

	if camera == nil then
		print("ERROR: Could not find camera node '" .. self.cameraPath .. "' in scene")
	else
		local shapesMask = 255
		local lightsMask = 16711680
		self.overlay = createRenderOverlay(camera, aspectRatio, resolutionX, resolutionY, true, shapesMask, lightsMask)
		self.isRenderDirty = true

		self:raiseCallback("onRenderLoadCallback", self.scene, self.overlay)
	end
end

function RenderElement:update(dt)
	RenderElement:superClass().update(self, dt)

	if self.isRenderDirty and self.overlay ~= 0 then
		updateRenderOverlay(self.overlay)

		self.isRenderDirty = false
	end
end

function RenderElement:draw()
	if not self.isLoading and self.overlay ~= 0 then
		renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
	end

	RenderElement:superClass().draw(self)
end

function RenderElement:canReceiveFocus()
	return false
end

function RenderElement:getSceneRoot()
	return self.scene
end

function RenderElement:setRenderDirty()
	self.isRenderDirty = true
end
