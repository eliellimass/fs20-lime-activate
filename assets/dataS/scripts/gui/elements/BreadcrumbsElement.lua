BreadcrumbsElement = {}
local BreadcrumbsElement_mt = Class(BreadcrumbsElement, FlowLayoutElement)

function BreadcrumbsElement:new(target, custom_mt)
	local self = FlowLayoutElement:new(target, custom_mt or BreadcrumbsElement_mt)
	self.crumbs = {}

	return self
end

function BreadcrumbsElement:copyAttributes(src)
	BreadcrumbsElement:superClass().copyAttributes(self, src)

	self.textTemplate = src.textTemplate
	self.dividerTemplate = src.dividerTemplate
	self.ownsTemplates = false
end

function BreadcrumbsElement:onGuiSetupFinished()
	BreadcrumbsElement:superClass().onGuiSetupFinished(self)

	if self.textTemplate == nil or self.dividerTemplate == nil then
		self.ownsTemplates = true
		self.textTemplate = self:getFirstDescendant(function (element)
			return element:isa(TextElement)
		end)

		if self.textTemplate ~= nil then
			self.textTemplate:unlinkElement()
		end

		self.dividerTemplate = self:getFirstDescendant(function (element)
			return element:isa(BitmapElement)
		end)

		if self.dividerTemplate ~= nil then
			self.dividerTemplate:unlinkElement()
		end
	end
end

function BreadcrumbsElement:delete()
	if self.ownsTemplates then
		if self.textTemplate ~= nil then
			self.textTemplate:delete()
		end

		if self.dividerTemplate ~= nil then
			self.dividerTemplate:delete()
		end
	end

	BreadcrumbsElement:superClass().delete(self)
end

function BreadcrumbsElement:setBreadcrumbs(crumbs)
	self.crumbs = crumbs

	self:updateElements()
end

function BreadcrumbsElement:updateElements()
	local numItems = #self.elements

	for i = 1, numItems do
		self.elements[1]:delete()
	end

	local requireDividerNext = false

	for _, crumb in ipairs(self.crumbs) do
		if requireDividerNext then
			local divider = self.dividerTemplate:clone(self)
		end

		local text = self.textTemplate:clone(self)

		text:setText(crumb)

		requireDividerNext = true
	end

	self:invalidateLayout()
end
