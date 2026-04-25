AchievementsScreen = {
	CONTROLS = {
		STATS_VALUE = "statsValue",
		ACHIEVEMENTS_BUTTON = "achievementsButton",
		LIST_ITEM_TEMPLATE = "listTemplate",
		ACHIEVEMENT_LIST = "achievementList",
		BUTTON_CREDITS = "creditsButton",
		LIST_SLIDER = "listSlider"
	}
}
local AchievementsScreen_mt = Class(AchievementsScreen, ScreenElement)

function AchievementsScreen:new(target, custom_mt, achievementManager)
	local self = ScreenElement:new(target, custom_mt or AchievementsScreen_mt)

	self:registerControls(AchievementsScreen.CONTROLS)

	self.achievementManager = achievementManager
	self.needAchievementSync = false
	self.selectedIndex = 1
	self.achievementElements = {}
	self.returnScreenName = "MainScreen"

	return self
end

function AchievementsScreen:onCreate(element)
	self:getAchievements()
end

function AchievementsScreen:onCreateAchievementBitmap(element)
	if self.currentAchievement ~= nil and self.currentAchievement.unlocked then
		element:setImageFilename(self.currentAchievement.imageFilename)

		local v0, u0, v1, u1, v2, u2, v3, u3 = unpack(self.currentAchievement.imageUVs)

		element:setImageUVs(nil, v0, u0, v1, u1, v2, u2, v3, u3)
		element:setImageColor(nil, 1, 1, 1, 1)
	end
end

function AchievementsScreen:onCreateAchievementTitle(element)
	if self.currentAchievement ~= nil then
		self.achievementElements[self.currentAchievement.id].title = element
	end
end

function AchievementsScreen:onCreateAchievementSuccess(element)
	if self.currentAchievement ~= nil then
		element:setVisible(self.currentAchievement.unlocked)

		self.achievementElements[self.currentAchievement.id].success = element
	end
end

function AchievementsScreen:onCreateAchievementDesc(element)
	if self.currentAchievement ~= nil then
		self.achievementElements[self.currentAchievement.id].desc = element
	end
end

function AchievementsScreen:onOpen()
	AchievementsScreen:superClass().onOpen(self)
	self.achievementList:deleteListItems()

	if self:checkAchievementSynchronization() then
		self:getAchievements()
	else
		self:assignAchievementsStatsValue(false)
	end

	if GS_IS_MOBILE_VERSION then
		-- Nothing
	end

	if GS_IS_MOBILE_VERSION and g_buildTypeParam == "CHINA_GAPP" then
		self.creditsButton:setVisible(false)
	end
end

function AchievementsScreen:getAchievements()
	self.achievementList:deleteListItems()

	if self.listTemplate ~= nil then
		for _, achievement in pairs(self.achievementManager.achievementList) do
			self.achievementElements[achievement.id] = {}
			self.currentAchievement = achievement
			local new = self.listTemplate:clone(self.achievementList)

			new:updateAbsolutePosition()

			self.currentAchievement = nil

			self:updateAchievementInfo(achievement)
		end
	end

	self.startIndex = 1
	self.selectedIndex = 1

	self:assignAchievementsStatsValue(true)
end

function AchievementsScreen:assignAchievementsStatsValue(achievementsAvailable)
	local numUnlocked = achievementsAvailable and self.achievementManager.numberOfUnlockedAchievements or 0

	self.statsValue:setText(string.format(g_i18n:getText(AchievementsScreen.L10N_SYMBOL.STATS_VALUE), numUnlocked, self.achievementManager.numberOfAchievements), true)
	self.statsValue.parent:invalidateLayout()
end

function AchievementsScreen:updateAchievementInfo(achievement)
	local elements = self.achievementElements[achievement.id]

	if elements.title ~= nil then
		elements.title:setText(achievement.name)
	end

	if elements.desc ~= nil then
		elements.desc:setText(achievement.description)
	end
end

function AchievementsScreen:onListSelectionChanged()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function AchievementsScreen:onCancelAchievementsSync()
	self.needAchievementSync = false

	self:changeScreen(MainScreen)
end

function AchievementsScreen:checkAchievementSynchronization()
	local achievementsAvailable = areAchievementsAvailable()

	if not achievementsAvailable and not self.needAchievementSync then
		self.needAchievementSync = true

		g_gui:showInfoDialog({
			text = g_i18n:getText(AchievementsScreen.L10N_SYMBOL.MESSAGE_SYNC_ACHIEVEMENTS),
			dialogType = DialogElement.TYPE_LOADING,
			callback = self.onCancelAchievementsSync,
			target = self,
			okText = g_i18n:getText(AchievementsScreen.L10N_SYMBOL.BUTTON_CANCEL),
			buttonAction = InputAction.MENU_ACCEPT
		})
	elseif achievementsAvailable and self.needAchievementSync then
		self.needAchievementSync = false

		self:getAchievements()
		g_gui:closeAllDialogs()
	end

	return achievementsAvailable
end

function AchievementsScreen:update(dt)
	AchievementsScreen:superClass().update(self, dt)

	if self:getIsVisible() then
		self:checkAchievementSynchronization()
	end
end

function AchievementsScreen:onCareerClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.careerButton)
	g_mainScreen:onCareerClick(element)
end

function AchievementsScreen:onCreditsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.creditsButton)
	g_mainScreen:onCreditsClick(element)
end

AchievementsScreen.L10N_SYMBOL = {
	MESSAGE_SYNC_ACHIEVEMENTS = "ui_achievementsSynchronizing",
	BUTTON_CANCEL = "button_cancel",
	STATS_VALUE = "ui_achievementStatsValue"
}
