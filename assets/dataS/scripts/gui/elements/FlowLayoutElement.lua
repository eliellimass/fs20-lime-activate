FlowLayoutElement = {}
local FlowLayoutElement_mt = Class(FlowLayoutElement, BoxLayoutElement)

function FlowLayoutElement:new(target, custom_mt)
	local self = BoxLayoutElement:new(target, custom_mt or FlowLayoutElement_mt)
	self.alignmentX = BoxLayoutElement.ALIGN_LEFT
	self.alignmentY = BoxLayoutElement.ALIGN_BOTTOM

	return self
end

function FlowLayoutElement:invalidateLayout(ignoreVisibility)
	local totalWidth = 0

	for _, element in pairs(self.elements) do
		if self:getIsElementIncluded(element, ignoreVisibility) then
			totalWidth = totalWidth + element.absSize[1] + element.margin[1] + element.margin[3]
		end
	end

	local posX = 0

	if self.alignmentX == FlowLayoutElement.ALIGN_CENTER then
		posX = self.absSize[1] * 0.5 - totalWidth * 0.5
	elseif self.alignmentX == FlowLayoutElement.ALIGN_RIGHT then
		posX = self.absSize[1] - totalWidth
	end

	for _, element in pairs(self.elements) do
		if self:getIsElementIncluded(element, ignoreVisibility) then
			posX = posX + element.margin[1]
			local posY = element.margin[4]

			if self.alignmentY == FlowLayoutElement.ALIGN_MIDDLE then
				posY = self.absSize[2] * 0.5 - element.absSize[2] * 0.5
			elseif self.alignmentY == FlowLayoutElement.ALIGN_TOP then
				posY = self.absSize[2] - element.absSize[2]
			end

			element:setPosition(posX, posY)

			posX = posX + element.absSize[1] + element.margin[3]
		end
	end
end
