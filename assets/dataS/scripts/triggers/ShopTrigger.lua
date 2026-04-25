ShopTrigger = {}
local ShopTrigger_mt = Class(ShopTrigger)

function ShopTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(ShopTrigger:new(id))
end

function ShopTrigger:new(name)
	local self = {}

	setmetatable(self, ShopTrigger_mt)

	if g_currentMission:getIsClient() then
		self.triggerId = name

		addTrigger(name, "triggerCallback", self)
	end

	self.shopSymbol = getChildAt(name, 0)
	self.shopPlayerSpawn = getChildAt(name, 1)
	self.objectActivated = false
	self.isEnabled = true

	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.playerFarmChanged, self)
	self:updateIconVisibility()

	self.activateText = g_i18n:getText("action_activateShop")

	return self
end

function ShopTrigger:delete()
	g_messageCenter:unsubscribeAll(self)

	if self.triggerId ~= nil then
		removeTrigger(self.triggerId)
	end

	self.shopSymbol = nil

	g_currentMission:removeActivatableObject(self)
end

function ShopTrigger:getIsActivatable()
	return self.isEnabled and g_currentMission.controlPlayer and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end

function ShopTrigger:drawActivate()
end

function ShopTrigger:onActivateObject()
	g_currentMission:addActivatableObject(self)

	self.objectActivated = true

	g_gui:changeScreen(nil, ShopMenu)

	local x, y, z = getWorldTranslation(self.shopPlayerSpawn)
	local dx, _, dz = localDirectionToWorld(self.shopPlayerSpawn, 0, 0, -1)

	g_currentMission.player:moveToAbsolute(x, y, z)

	g_currentMission.player.rotY = MathUtil.getYRotationFromDirection(dx, dz)
end

function ShopTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and (onEnter or onLeave) and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			if not self.objectActivated then
				g_currentMission:addActivatableObject(self)

				self.objectActivated = true
			end
		elseif self.objectActivated then
			g_currentMission:removeActivatableObject(self)

			self.objectActivated = false
		end
	end
end

function ShopTrigger:updateIconVisibility()
	if self.shopSymbol ~= nil then
		local hideMission = g_isPresentationVersion and not g_isPresentationVersionShopEnabled or not g_currentMission.missionInfo:isa(FSCareerMissionInfo)
		local farmId = g_currentMission:getFarmId()
		local visibleForFarm = farmId ~= FarmManager.SPECTATOR_FARM_ID

		setVisibility(self.shopSymbol, not hideMission and visibleForFarm)
	end
end

function ShopTrigger:playerFarmChanged(player)
	if player == g_currentMission.player then
		self:updateIconVisibility()
	end
end
