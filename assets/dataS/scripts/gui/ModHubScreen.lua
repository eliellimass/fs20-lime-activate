ModHubScreen = {}
local ModHubScreen_mt = Class(ModHubScreen, TabbedMenuWithDetails)
ModHubScreen.SPECIAL_LIST_LIMIT = 42
ModHubScreen.CONTROLS = {
	PAGE_DOWNLOADS = "pageDownloads",
	PAGE_LOADING = "pageLoading",
	PAGE_INSTALLED = "pageInstalled",
	PAGE_CONTEST = "pageContest",
	PAGE_DLCS = "pageDLCs",
	PAGE_SEARCH = "pageSearch",
	PAGE_ITEMS = "pageItems",
	PAGE_DETAILS = "pageDetails",
	LOADING = "loadingElement",
	PAGE_UPDATES = "pageUpdates",
	PAGE_CATEGORIES = "pageCategories",
	DISC_SPACE = "discSpace",
	PAGE_LATEST = "pageLatest",
	PAGE_MOST_DOWNLOADED = "pageMostDownloaded",
	PAGE_BEST = "pageBest"
}

local function NO_CALLBACK()
end

function ModHubScreen:new(target, customMt, messageCenter, l10n, inputManager, modHubController, isConsoleVersion)
	local self = TabbedMenuWithDetails:new(target, customMt or ModHubScreen_mt, messageCenter, l10n, inputManager)

	self:registerControls(ModHubScreen.CONTROLS)

	self.modHubController = modHubController
	self.isConsoleVersion = isConsoleVersion
	self.checkForLoaded = true
	self.isLoading = true
	self.showingAllMods = false

	return self
end

function ModHubScreen:onGuiSetupFinished()
	ModHubScreen:superClass().onGuiSetupFinished(self)

	self.showingAllMods = g_gameSettings:getValue(GameSettings.SETTING.SHOW_ALL_MODS)

	self.modHubController:setShowAllMods(self.showingAllMods)
	self:setupPages()
	self:setupMenuButtonInfo()
end

function ModHubScreen:setupPages()
	local pagePredicate = self:makeIsModHubEnabledPredicate()
	local contestPredicate = self:makeIsContestEnabledPredicate()
	local detailsPredicate = self:makeIsModHubItemsEnabledPredicate()
	local orderedPages = {
		{
			self.pageLoading,
			self:makeIsLoadingEnabledPredicate(),
			ModHubScreen.TAB_UV.CATEGORIES
		},
		{
			self.pageCategories,
			pagePredicate,
			ModHubScreen.TAB_UV.CATEGORIES
		},
		{
			self.pageInstalled,
			pagePredicate,
			ModHubScreen.TAB_UV.INSTALLED
		},
		{
			self.pageUpdates,
			pagePredicate,
			ModHubScreen.TAB_UV.UPDATES
		},
		{
			self.pageDownloads,
			pagePredicate,
			ModHubScreen.TAB_UV.DOWNLOADS
		},
		{
			self.pageDLCs,
			pagePredicate,
			ModHubScreen.TAB_UV.DLCS
		},
		{
			self.pageBest,
			pagePredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageMostDownloaded,
			pagePredicate,
			ModHubScreen.TAB_UV.MOST_DOWNLOADED
		},
		{
			self.pageLatest,
			pagePredicate,
			ModHubScreen.TAB_UV.LATEST
		},
		{
			self.pageContest,
			contestPredicate,
			ModHubScreen.TAB_UV.CONTEST
		},
		{
			self.pageItems,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageDetails,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageSearch,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		}
	}

	for i, pageDef in ipairs(orderedPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local normalizedUVs = GuiUtils.getUVs(iconUVs, ModHubScreen.IMAGE.TABS)

		self:addPageTab(page, "dataS/menu/modCategories.png", normalizedUVs)
	end
end

function ModHubScreen:setupMenuButtonInfo()
	local onButtonBackFunction = self.clickBackCallback
	self.defaultMenuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK,
			text = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_BACK),
			callback = onButtonBackFunction
		}
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction
	}

	self:assignMenuButtonInfo(self.defaultMenuButtonInfo)
end

function ModHubScreen:initializePages()
	self.modHubController:setShowAllMods(self.showingAllMods)
	self.modHubController:load()
	self.modHubController:setDiscSpaceChangedCallback(self.updateDiscSpace, self)

	local onSearchButtonCallback = self:makeSelfCallback(self.onSearchButton)
	local onToggleCallback = self:makeSelfCallback(self.onToggleBeta)
	local getBetaToggleTextCallback = self:makeSelfCallback(self.getBetaToggleText)

	self.pageCategories:initialize(self.modHubController:getCategories(), self:makeSelfCallback(self.onClickCategory), self.l10n:getText(ModHubScreen.L10N_SYMBOL.HEADER_MOD_HUB), ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO)
	self.pageCategories:setSearchCallback(onSearchButtonCallback)
	self.pageCategories:setBreadcrumbs(self:getBreadcrumbs(self.pageCategories))
	self.pageCategories:setToggleBetaCallback(onToggleCallback)
	self.pageCategories:setBetaToggleTextCallback(getBetaToggleTextCallback)

	local clickItemCallback = self:makeClickItemCallback()
	local onSelectItemCallback = self:makeSelfCallback(self.onSelectItem)

	local function initCategoryPage(page, categoryName, limit)
		local category = self.modHubController:getCategory(categoryName)

		if category ~= nil then
			page:initialize()
			page:setCategoryId(category.id)
			page:setCategory(categoryName)
			page:setBreadcrumbs(self:getBreadcrumbs(page))
			page:setItemClickCallback(clickItemCallback)
			page:setItemSelectCallback(onSelectItemCallback)
			page:setSearchCallback(onSearchButtonCallback)
			page:setToggleBetaCallback(onToggleCallback)
			page:setBetaToggleTextCallback(getBetaToggleTextCallback)

			if limit ~= nil then
				page:setListSizeLimit(limit)
			end
		end
	end

	initCategoryPage(self.pageInstalled, "installed")
	initCategoryPage(self.pageLatest, "latest", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageUpdates, "update")
	initCategoryPage(self.pageDLCs, "dlc")
	initCategoryPage(self.pageDownloads, "download")
	initCategoryPage(self.pageBest, "best", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageMostDownloaded, "most_downloaded", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageContest, "contest")
	self.pageSearch:initialize()
	self.pageSearch:setItemClickCallback(clickItemCallback)
	self.pageSearch:setItemSelectCallback(onSelectItemCallback)
	self.pageItems:initialize()
	self.pageItems:setItemClickCallback(clickItemCallback)
	self.pageItems:setItemSelectCallback(onSelectItemCallback)
	self.pageItems:setSearchCallback(onSearchButtonCallback)
	self.pageItems:setToggleBetaCallback(onToggleCallback)
	self.pageItems:setBetaToggleTextCallback(getBetaToggleTextCallback)
	self.pageDetails:initialize()
end

function ModHubScreen:reset()
	ModHubScreen:superClass().reset(self)
	self.modHubController:reset()

	self.showingAllMods = false
end

function ModHubScreen:onOpen(element)
	self.modHubController:startModification()

	if modDownloadManagerLoaded() then
		self:setIsLoading(false)

		self.checkForLoaded = false
	else
		self:setIsLoading(true)
	end

	ModHubScreen:superClass().onOpen(self)
end

function ModHubScreen:onClose(element)
	self.modHubController:endModification()
	ModHubScreen:superClass().onClose(self)
end

function ModHubScreen:update(dt)
	ModHubScreen:superClass().update(self, dt)

	if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_PS4 then
		if getModDownloadAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			self:changeScreen(MainScreen)

			return
		end

		if getNetworkError() then
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")

			return
		end
	end

	if self.checkForLoaded and modDownloadManagerLoaded() then
		self.checkForLoaded = false

		self:setIsLoading(false)
	end
end

function ModHubScreen:setIsLoading(loading)
	self.isLoading = loading

	if not loading and not self.initialized then
		self:initializePages()

		self.initialized = true
	end
end

function ModHubScreen:exitMenu()
	self:changeScreen(MainScreen)
end

function ModHubScreen:getBreadcrumbs(page)
	local list = ModHubScreen:superClass().getBreadcrumbs(self, page)

	if self:getStack(page)[1].page ~= self.pageCategories then
		table.insert(list, 1, self.l10n:getText(ModHubScreen.L10N_SYMBOL.HEADER_MOD_HUB))
	end

	return list
end

function ModHubScreen:onClickCategory(categoryId, categoryName)
	self.pageItems:setCategoryId(categoryId)
	self.pageItems:setCategory(categoryName)
	self:pushDetail(self.pageItems)
	self.pageItems:setBreadcrumbs(self:getBreadcrumbs())
end

function ModHubScreen:onSelectItem(page, modId, selectedElement)
	local modInfo = self.modHubController:getModInfo(modId)

	page:setModInfo(modInfo)
end

function ModHubScreen:updateDiscSpace(freeSpaceKb, usedSpaceKb)
	self.discSpace:setVisible(self.isConsoleVersion)
	self.discSpace:setText(string.format("%s: %.0f %%", g_i18n:getText("ui_usedDiscSpace"), 100 * usedSpaceKb / (usedSpaceKb + freeSpaceKb), true))
end

function ModHubScreen:onSearchButton(categoryId)
	g_gui:showTextInputDialog({
		disableFilter = true,
		maxCharacters = 40,
		callback = self.onSearchFinished,
		target = self,
		dialogPrompt = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		imePrompt = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		confirmText = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		args = categoryId
	})
end

function ModHubScreen:onSearchFinished(text, ok, categoryId)
	if ok and text:len() > 0 then
		local result = self.modHubController:searchMods(categoryId, text)

		self.pageSearch:setModItems(result)

		local breadcrumb = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH) .. " '" .. text:lower() .. "'"
		self.pageSearch.title = breadcrumb

		self:pushDetail(self.pageSearch)
		self.pageSearch:setBreadcrumbs(self:getBreadcrumbs())
	end
end

function ModHubScreen:onToggleBeta(page)
	self.showingAllMods = not self.showingAllMods

	self.modHubController:setShowAllMods(self.showingAllMods)
	self.modHubController:reload()
	g_gameSettings:setValue(GameSettings.SETTING.SHOW_ALL_MODS, self.showingAllMods, true)
	page:reload()
	self.pageCategories:setCategories(self.modHubController:getCategories())
end

function ModHubScreen:getBetaToggleText()
	if self.showingAllMods then
		return self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_TOP)
	else
		return self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_ALL)
	end
end

function ModHubScreen:makeClickItemCallback()
	return function (page, modId, categoryName)
		local modInfo = self.modHubController:getModInfo(modId)

		self.pageDetails:setModInfo(modInfo)
		self:pushDetail(self.pageDetails)
		self.pageDetails:setBreadcrumbs(self:getBreadcrumbs())
	end
end

function ModHubScreen:makeIsLoadingEnabledPredicate()
	return function ()
		return self.isLoading
	end
end

function ModHubScreen:makeIsModHubEnabledPredicate()
	return function ()
		return not self.isLoading and not self:getIsDetailMode()
	end
end

function ModHubScreen:makeIsModHubItemsEnabledPredicate()
	return function ()
		return false
	end
end

function ModHubScreen:makeIsContestEnabledPredicate()
	return function ()
		return not self.isLoading and not self:getIsDetailMode() and self.modHubController:isContestEnabled()
	end
end

ModHubScreen.L10N_SYMBOL = {
	BUTTON_SHOW_ALL = "button_modHubShowAll",
	BUTTON_SHOW_TOP = "button_modHubShowTop",
	BUTTON_SEARCH = "modHub_search",
	HEADER_MOD_HUB = "modHub_title",
	BUTTON_BACK = "button_back"
}
ModHubScreen.TAB_UV = {
	CATEGORIES = {
		4,
		4,
		65,
		65
	},
	INSTALLED = {
		142,
		73,
		65,
		65
	},
	LATEST = {
		280,
		4,
		65,
		65
	},
	UPDATES = {
		73,
		73,
		65,
		65
	},
	DLCS = {
		73,
		4,
		65,
		65
	},
	DOWNLOADS = {
		4,
		73,
		65,
		65
	},
	BEST = {
		142,
		4,
		65,
		65
	},
	MOST_DOWNLOADED = {
		211,
		4,
		65,
		65
	},
	CONTEST = {
		349,
		4,
		65,
		65
	}
}
ModHubScreen.IMAGE = {
	TABS = {
		512,
		256
	}
}
ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO = 1
