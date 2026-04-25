UnBanDialog = {}
local UnBanDialog_mt = Class(UnBanDialog, DialogElement)
UnBanDialog.CONTROLS = {
	LOADING_TEXT = "loadingText",
	BUTTON_UNBAN = "unBanButton",
	DIALOG_TITLE = "dialogTitleElement",
	BUTTON_UNBAN_ALL = "unBanAllButton",
	BUTTON_LAYOUT = "buttonLayout",
	BAN_LIST_ITEM_TEMPLATE = "itemTemplate",
	DIALOG_FRAME = "dialogElement",
	BAN_LIST = "banList",
	BUTTON_BACK = "backButton"
}
UnBanDialog.ELEMENT_NAME = {
	USER_NAME = "userName",
	BAN_DATE = "banDate"
}

local function NO_CALLBACK()
end

function UnBanDialog:new(target, custom_mt, l10n, banStorage)
	local self = DialogElement:new(target, custom_mt or UnBanDialog_mt)

	self:registerControls(UnBanDialog.CONTROLS)

	self.l10n = l10n
	self.banStorage = banStorage
	self.elementToUniqueUserIdMap = {}
	self.callbackFunc = NO_CALLBACK
	self.target = nil
	self.selectedUniqueUserId = nil

	return self
end

function UnBanDialog:rebuildBanList()
	self.banList:deleteListItems()

	local bans = self.banStorage:getBans()

	for i, banInfo in ipairs(bans) do
		local newItem = self.itemTemplate:clone(self.banList)

		FocusManager:loadElementFromCustomValues(newItem)

		if g_currentMission:getIsServer() then
			self.elementToUniqueUserIdMap[newItem] = banInfo.uniqueUserId
		else
			self.elementToUniqueUserIdMap[newItem] = i
		end

		local playerNameText = newItem:getDescendantByName(UnBanDialog.ELEMENT_NAME.USER_NAME)
		local banDateText = newItem:getDescendantByName(UnBanDialog.ELEMENT_NAME.BAN_DATE)

		playerNameText:setText(banInfo.lastNickname)
		banDateText:setText(banInfo.time)
	end

	self.banList:updateItemPositions()
end

function UnBanDialog:updateButtons()
	local hasBans = #self.banStorage:getBans() > 0

	self.unBanButton:setVisible(hasBans)
	self.unBanAllButton:setVisible(hasBans and g_currentMission:getIsServer())
	self.buttonLayout:invalidateLayout()
end

function UnBanDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc or NO_CALLBACK
	self.target = target
end

function UnBanDialog:closeAndCallback()
	if self.inputDelay < self.time then
		self:close()

		if self.target ~= nil then
			self.callbackFunc(self.target)
		else
			self.callbackFunc()
		end
	end
end

function UnBanDialog:onCreate()
	self.itemTemplate:unlinkElement()
end

function UnBanDialog:onOpen()
	UnBanDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250

	if g_currentMission:getIsServer() then
		self:rebuildBanList()
		self.banList:setSelectedIndex(1, true)
	else
		g_client:getServerConnection():sendEvent(GetBansEvent:new())
		self.loadingText:setVisible(true)
	end

	g_messageCenter:subscribe(GetBansEvent, self.onBansUpdated, self)
	self:updateButtons()
end

function UnBanDialog:onClose()
	UnBanDialog:superClass().onClose(self)
	g_messageCenter:unsubscribeAll(self)
end

function UnBanDialog:onListSelectionChanged(newIndex)
	local listItem = self.banList.listItems[newIndex]
	self.selectedUniqueUserId = self.elementToUniqueUserIdMap[listItem]
end

function UnBanDialog:onClickBack(_, _)
	self:closeAndCallback()

	return false
end

function UnBanDialog:onClickCancel()
	if self.banList:getItemCount() > 0 then
		if g_currentMission:getIsServer() then
			self.banStorage:removeUser(self.selectedUniqueUserId)

			local element, prevIndex = self.banList:getSelectedElement()

			self.banList:removeElement(element)
			self.banList:updateItemPositions()
			self.banList:setSelectedIndex(prevIndex, true)
		else
			local index = self.selectedUniqueUserId
			local ban = self.banStorage:getBans()[index]

			if ban ~= nil then
				g_client:getServerConnection():sendEvent(UnbanEvent:new(ban.lastNickname, index))
				g_client:getServerConnection():sendEvent(GetBansEvent:new())
				self.loadingText:setVisible(true)
			end
		end

		self:updateButtons()
	end

	return false
end

function UnBanDialog:onClickActivate()
	local bans = self.banStorage:getBans()

	if #bans > 0 then
		local ids = {}

		for _, banInfo in pairs(bans) do
			table.insert(ids, banInfo.uniqueUserId)
		end

		for _, uniqueUserId in pairs(ids) do
			local isLastElementAndDoSave = next(ids) == nil

			self.banStorage:removeUser(uniqueUserId, isLastElementAndDoSave)
		end

		self:rebuildBanList()
		self:updateButtons()
	end

	return false
end

function UnBanDialog:onBansUpdated()
	self.loadingText:setVisible(false)
	self:rebuildBanList()
	self:updateButtons()
	self.banList:setSelectedIndex(1, true)
end
