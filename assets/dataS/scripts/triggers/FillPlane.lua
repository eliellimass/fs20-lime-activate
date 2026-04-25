FillPlane = {}
local FillPlane_mt = Class(FillPlane)

function FillPlane:new(customMt)
	local self = {}

	setmetatable(self, customMt or FillPlane_mt)
	self:initDataStructures()

	return self
end

function FillPlane:delete()
end

function FillPlane:initDataStructures()
	self.node = nil
	self.maxCapacity = 0
	self.moveMinY = 0
	self.moveMaxY = 0
	self.loaded = false
	self.colorChange = false
end

function FillPlane:load(rootNode, xmlFile, xmlNode)
	local fillPlaneNodeStr = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "node", getXMLString, rootNode)

	if fillPlaneNodeStr ~= nil then
		local fillPlaneNode = I3DUtil.indexToObject(rootNode, fillPlaneNodeStr)

		if fillPlaneNode ~= nil then
			self.node = fillPlaneNode
			self.moveMinY = Utils.getNoNil(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "minY", getXMLFloat, rootNode), 0)
			self.moveMaxY = Utils.getNoNil(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "maxY", getXMLFloat, rootNode), 0)
			self.colorChange = Utils.getNoNil(XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "colorChange", getXMLBool, rootNode), false)

			assert(self.moveMinY <= self.moveMaxY)

			self.loaded = self.node ~= nil
			local x, _, z = getTranslation(self.node)

			setTranslation(self.node, x, self.moveMinY, z)
		end
	end
end

function FillPlane:setState(state)
	if self.loaded then
		local delta = self.moveMaxY - self.moveMinY
		local y = math.min(self.moveMinY + delta * state, self.moveMaxY)
		local x, oldY, z = getTranslation(self.node)

		setTranslation(self.node, x, y, z)

		return oldY ~= y
	end

	return false
end

function FillPlane:setColorScale(colorScale)
	if self.loaded then
		setShaderParameter(self.node, "colorScale", colorScale[1], colorScale[2], colorScale[3], 0, false)
	end
end
