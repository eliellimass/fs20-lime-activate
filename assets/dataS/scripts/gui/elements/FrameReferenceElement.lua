FrameReferenceElement = {}
local FrameReferenceElement_mt = Class(FrameReferenceElement, GuiElement)

function FrameReferenceElement:new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = FrameReferenceElement_mt
	end

	local self = GuiElement:new(target, custom_mt)
	self.referencedFrameName = ""

	return self
end

function FrameReferenceElement:loadFromXML(xmlFile, key)
	FrameReferenceElement:superClass().loadFromXML(self, xmlFile, key)

	self.referencedFrameName = getXMLString(xmlFile, key .. "#ref") or ""
end

function FrameReferenceElement:copyAttributes(src)
	FrameReferenceElement:superClass().copyAttributes(self, src)

	self.referencedFrameName = src.referencedFrameName
end
