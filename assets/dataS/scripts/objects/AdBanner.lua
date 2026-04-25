AdBanner = {}
local AdBanner_mt = Class(AdBanner)

function AdBanner:onCreate(id)
	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_SWITCH or GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_ANDROID and g_buildTypeParam == "CHINA_GAPP" then
		delete(id)
	else
		g_currentMission:addAdBanner(AdBanner:new(id))
	end
end

function AdBanner:new(id, customMt)
	local self = setmetatable({}, customMt or AdBanner_mt)
	self.rootNode = id
	local adNodeIndex = getUserAttribute(id, "adNodeIndex")

	if adNodeIndex ~= nil then
		self.adNode = I3DUtil.indexToObject(self.rootNode, adNodeIndex)
	end

	return self
end

function AdBanner:delete()
	g_currentMission:removeAdBanner(self)
end
