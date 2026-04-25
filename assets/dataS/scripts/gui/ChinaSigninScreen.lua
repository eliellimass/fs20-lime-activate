ChinaSigninScreen = {
	CONTROLS = {
		TAPTAP_LOGIN_BUTTON = "tapTapLoginButton"
	}
}
local ChinaSigninScreen_mt = Class(ChinaSigninScreen, ScreenElement)

function ChinaSigninScreen:new(inGameMenu, shopMenu, achievementManager, settingsModel)
	local self = {}
	self = ScreenElement:new(nil, ChinaSigninScreen_mt)

	self:registerControls(ChinaSigninScreen.CONTROLS)

	self.inGameMenu = inGameMenu
	self.shopMenu = shopMenu
	self.achievementManager = achievementManager
	self.settingsModel = settingsModel

	return self
end

function ChinaSigninScreen:onCreate()
end

function ChinaSigninScreen:onOpen()
	g_isSignedIn = false

	if not g_menuMusicIsPlayingStarted then
		g_menuMusicIsPlayingStarted = true

		playStreamedSample(g_menuMusic, 0)
	end
end

function ChinaSigninScreen:onClose()
end

function ChinaSigninScreen:update(dt)
	if getIsUserSignedIn() then
		self:changeScreen(MainScreen)
	else
		self.tapTapLoginButton:setVisible(true)
	end
end

function ChinaSigninScreen:draw()
end

function ChinaSigninScreen:onYesNoSigninAccept(yes)
end

function ChinaSigninScreen:onClickTapTapLogin()
	requestUserSignin()
end

function ChinaSigninScreen:inputEvent(action, value, eventUsed)
end

function ChinaSigninScreen:signIn()
end
