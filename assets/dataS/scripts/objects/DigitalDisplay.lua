DigitalDisplay = {}
local DigitalDisplay_mt = Class(DigitalDisplay)

function DigitalDisplay:new(customMt)
	local self = setmetatable({}, customMt or DigitalDisplay_mt)

	return self
end

function DigitalDisplay:load(id, xmlFile, key)
	self.rootNode = id
	self.baseNode = I3DUtil.indexToObject(id, getXMLString(xmlFile, key .. "#baseNode"))
	self.precision = getXMLInt(xmlFile, key .. "#precision") or 0
	self.showZero = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showZero"), true)

	if self.baseNode == nil then
		return false
	end

	return true
end

function DigitalDisplay:setValue(value)
	if self.baseNode ~= nil then
		I3DUtil.setNumberShaderByValue(self.baseNode, math.max(0, value), self.precision, self.showZero)
	end
end
