local function fn(self, id)
	if getVisibility(id) == false then
		setCollisionMask(id, 0)
	end
end

local class = {
	onCreate = fn
}
ssIcePlane = class
ssSeasonAdmirer = class
ssSnowAdmirer = class
