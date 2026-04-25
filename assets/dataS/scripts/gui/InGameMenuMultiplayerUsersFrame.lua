InGameMenuMultiplayerUsersFrame = {}
local InGameMenuMultiplayerUsersFrame_mt = Class(InGameMenuMultiplayerUsersFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerUsersFrame.CONTROLS = {
	ACTION_BUTTON_REMOVE_FROM_FARM = "removeButton",
	ACTION_BUTTON_BAN = "banButton",
	ACTION_BUTTON_PROMOTE = "promoteButton",
	BUY_VEHICLE_PERMISSION = "buyVehiclePermissionCheckbox",
	ACTIONS_BOX = "actionsBox",
	FARM_ROW_TEMPLATE = "userListFarmTemplate",
	MANAGE_CONTRACTS_PERMISSION = "manageMissionsPermissionCheckbox",
	ACTION_BUTTON_TRANSFER = "transferButton",
	PLAYER_ROW_TEMPLATE = "userListPlayerTemplate",
	CONTAINER = "container",
	SELL_PLACEABLE_PERMISSION = "sellPlaceablePermissionCheckbox",
	HIRE_ASSISTANT_PERMISSION = "hireAssistantPermissionCheckbox",
	ACTION_BUTTON_CONTRACTOR = "contractorButton",
	USER_LIST = "userList",
	BALANCE_LABEL = "currentBalanceLabel",
	PERMISSIONS_BOX = "permissionsBox",
	SELL_VEHICLE_PERMISSION = "sellVehiclePermissionCheckbox",
	ACTION_BUTTON_KICK = "kickButton",
	TRADE_ANIMALS_PERMISSION = "tradeAnimalsPermissionCheckbox",
	RESET_VEHICLE_PERMISSION = "resetVehiclePermissionCheckbox",
	CREATE_FIELDS_PERMISSION = "createFieldsPermissionCheckbox",
	PERMISSION_ROWS = "permissionRow",
	BUY_PLACEABLE_PERMISSION = "buyPlaceablePermissionCheckbox",
	BALANCE_TEXT = "currentBalanceText",
	LANDSCAPING_PERMISSION = "landscapingPermissionCheckbox"
}
InGameMenuMultiplayerUsersFrame.ELEMENT_NAME = {
	ROW_FARM_COLOR = "farmColor",
	ROW_PLAYER_NAME = "playerName",
	ROW_FARM_NAME = "farmName"
}
InGameMenuMultiplayerUsersFrame.TRANSFER_AMOUNT = {
	SMALL = 5000,
	MEDIUM = 50000,
	LARGE = 250000
}

function InGameMenuMultiplayerUsersFrame:new(subclass_mt, messageCenter, l10n, farmManager)
	local subclass_mt = subclass_mt or InGameMenuMultiplayerUsersFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt)

	self:registerControls(InGameMenuMultiplayerUsersFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.farmManager = farmManager
	self.currentUser = User:new()
	self.playerFarm = nil
	self.banStorage = nil
	self.selectedUser = nil
	self.selectedUserFarm = nil
	self.isNavigatingUsers = false
	self.users = {}
	self.listRowUser = {}
	self.permissionCheckboxes = {}
	self.checkboxPermissions = {}
	self.hasCustomMenuButtons = true
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.menuButtonInfo = {
		self.backButtonInfo
	}
	self.banButtonInfo = {}
	self.kickButtonInfo = {}
	self.adminButtonInfo = {}
	self.inviteFriendsInfo = {}
	self.showProfileInfo = {}

	return self
end

function InGameMenuMultiplayerUsersFrame:copyAttributes(src)
	InGameMenuMultiplayerUsersFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.farmManager = src.farmManager
end

function InGameMenuMultiplayerUsersFrame:initialize()
	self.userListPlayerTemplate:unlinkElement()
	self.userListFarmTemplate:unlinkElement()
	self:setupUserListFocusContext()

	self.unbanButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.BUTTON_UNBAN),
		callback = function ()
			self:onButtonUnBan()
		end
	}
	self.adminButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.BUTTON_ADMIN),
		callback = function ()
			self:onButtonAdminLogin()
		end
	}
	self.showProfileInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.BUTTON_SHOW_PROFILE),
		callback = function ()
			self:onButtonShowProfile()
		end
	}
	self.inviteFriendsInfo = {
		inputAction = InputAction.MENU_EXTRA_2,
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.BUTTON_INVITE_FRIENDS),
		callback = function ()
			self:onButtonInviteFriends()
		end
	}
	self.permissionCheckboxes = {
		[Farm.PERMISSION.BUY_VEHICLE] = self.buyVehiclePermissionCheckbox,
		[Farm.PERMISSION.SELL_VEHICLE] = self.sellVehiclePermissionCheckbox,
		[Farm.PERMISSION.RESET_VEHICLE] = self.resetVehiclePermissionCheckbox,
		[Farm.PERMISSION.BUY_PLACEABLE] = self.buyPlaceablePermissionCheckbox,
		[Farm.PERMISSION.SELL_PLACEABLE] = self.sellPlaceablePermissionCheckbox,
		[Farm.PERMISSION.HIRE_ASSISTANT] = self.hireAssistantPermissionCheckbox,
		[Farm.PERMISSION.MANAGE_CONTRACTS] = self.manageMissionsPermissionCheckbox,
		[Farm.PERMISSION.TRADE_ANIMALS] = self.tradeAnimalsPermissionCheckbox,
		[Farm.PERMISSION.CREATE_FIELDS] = self.createFieldsPermissionCheckbox,
		[Farm.PERMISSION.LANDSCAPING] = self.landscapingPermissionCheckbox
	}
	self.checkboxPermissions = {}

	for k, v in pairs(self.permissionCheckboxes) do
		self.checkboxPermissions[v] = k
	end
end

function InGameMenuMultiplayerUsersFrame:delete()
	InGameMenuMultiplayerUsersFrame:superClass().delete(self)
	self.userListPlayerTemplate:delete()
	self.userListFarmTemplate:delete()
end

function InGameMenuMultiplayerUsersFrame:onFrameOpen()
	InGameMenuMultiplayerUsersFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(GetAdminAnswerEvent, self.onAdminLoginSuccess, self)
	self.messageCenter:subscribe(PlayerPermissionsEvent, self.onPermissionChanged, self)
	self.messageCenter:subscribe(ContractingStateEvent, self.onContractingStateChanged, self)
	self.messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
	self.messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	self.messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self:setCurrentUserId(g_currentMission.playerUserId)
	self:updateDisplay()
	FocusManager:setFocus(self.userList)
end

function InGameMenuMultiplayerUsersFrame:onFrameClose()
	InGameMenuMultiplayerUsersFrame:superClass().onFrameClose(self)
	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuMultiplayerUsersFrame:setupUserListFocusContext()
	function self.userList.onFocusEnter()
		self.isNavigatingUsers = true

		self:updateMenuButtons()
	end

	function self.userList.onFocusLeave()
		self.isNavigatingUsers = false

		self:updateMenuButtons()
	end
end

function InGameMenuMultiplayerUsersFrame:getMainElementSize()
	return self.container.size
end

function InGameMenuMultiplayerUsersFrame:getMainElementPosition()
	return self.container.absPosition
end

function InGameMenuMultiplayerUsersFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end

function InGameMenuMultiplayerUsersFrame:setCurrentUserId(userId)
	self.currentUserId = userId
	self.currentUser = g_currentMission.userManager:getUserByUserId(userId) or self.currentUser

	self:updateMenuButtons()
end

function InGameMenuMultiplayerUsersFrame:setBanStorage(banStorage)
	self.banStorage = banStorage
end

function InGameMenuMultiplayerUsersFrame:setUsers(users)
	local sortedUsers = self:getSortedUsers(users)
	self.users = sortedUsers
	self.shouldRebuildUserList = true

	self:updateMenuButtons()
end

local function alphabetSortUsers(user1, user2)
	return user1:getNickname() < user2:getNickname()
end

function InGameMenuMultiplayerUsersFrame:getSortedUsers(users)
	local sortedUsers = {}

	for _, user in pairs(users) do
		if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
			table.insert(sortedUsers, user)
		end
	end

	local function groupUsers(user1, user2)
		local farm1 = self.farmManager:getFarmByUserId(user1:getId())
		local farm2 = self.farmManager:getFarmByUserId(user2:getId())
		local farm1Id = farm1.farmId
		local farm2Id = farm2.farmId

		if self.playerFarm ~= nil and farm1Id == self.playerFarm.farmId then
			farm1Id = -math.huge
		end

		if self.playerFarm ~= nil and farm2Id == self.playerFarm.farmId then
			farm2Id = -math.huge
		end

		if farm1Id == FarmManager.SPECTATOR_FARM_ID then
			farm1Id = math.huge
		end

		if farm2Id == FarmManager.SPECTATOR_FARM_ID then
			farm2Id = math.huge
		end

		return farm1Id < farm2Id or alphabetSortUsers(user1, user2)
	end

	return sortedUsers
end

function InGameMenuMultiplayerUsersFrame:buildUserDisplayInfo(isMasterUser, isFarmManager)
	local info = ""

	if isMasterUser or isFarmManager then
		if isMasterUser then
			info = info .. self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.LABEL_ADMIN)

			if isFarmManager then
				info = info .. "\n"
			end
		end

		if isFarmManager then
			info = info .. self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.LABEL_FARM_MANAGER)
		end
	end

	return info
end

function InGameMenuMultiplayerUsersFrame:getSortedFarmList()
	local list = {}
	local farms = g_farmManager:getFarms()
	local mapping = g_farmManager.farmIdToFarm

	table.insert(list, self.playerFarm)

	for _, farm in pairs(farms) do
		if not farm.isSpectator and farm ~= self.playerFarm then
			table.insert(list, farm)
		end
	end

	if not self.playerFarm.isSpectator and #mapping[FarmManager.SPECTATOR_FARM_ID]:getActiveUsers() > 0 then
		table.insert(list, mapping[FarmManager.SPECTATOR_FARM_ID])
	end

	return list
end

function InGameMenuMultiplayerUsersFrame:rebuildUserList()
	local prevSelectedRow = self.userList:getSelectedElement() or 0
	local prevUser = self.listRowUser[prevSelectedRow] or 1

	for k in pairs(self.listRowUser) do
		self.listRowUser[k] = nil
	end

	local newIndex = 1
	local rowIndex = 1

	self.userList:deleteListItems()

	self.listRowUser = {}

	for _, farm in ipairs(self:getSortedFarmList()) do
		if self.userListFarmTemplate ~= nil then
			local new = self.userListFarmTemplate:clone(self.userList)

			FocusManager:loadElementFromCustomValues(new)
			new:applyProfile("ingameMenuMPUsersListFarm")

			new.doNotAlternate = true

			if farm.farmId ~= FarmManager.SPECTATOR_FARM_ID then
				local itemText = new:getDescendantByName("farmName")

				itemText:setText(farm.name)

				itemText = new:getDescendantByName("farmBalance")
				local balance = farm:getBalance()

				itemText:setText(self.l10n:formatMoney(balance, 0, false) .. " " .. self.l10n:getCurrencySymbol(true))
			else
				new:getDescendantByName("farmName"):setText(self.l10n:getText("ui_noFarm"))
				new:getDescendantByName("farmBalance"):setText("")
			end

			rowIndex = rowIndex + 1
		end

		for i, userInfo in ipairs(farm:getActiveUsers()) do
			local user = g_currentMission.userManager:getUserByUserId(userInfo.userId)

			if user ~= nil and (not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId()) and self.userListPlayerTemplate ~= nil then
				local new = self.userListPlayerTemplate:clone(self.userList)

				FocusManager:loadElementFromCustomValues(new)

				local itemText = new:getDescendantByName("playerName")

				itemText:setText(user:getNickname())

				local itemText = new:getDescendantByName("playerInfo")
				local farm = self.farmManager:getFarmByUserId(user:getId())
				local isFarmManager = farm:isUserFarmManager(user:getId())
				local infoText = self:buildUserDisplayInfo(user:getIsMasterUser(), isFarmManager)

				itemText:setText(infoText)
				new:updateAbsolutePosition()

				self.listRowUser[new] = user

				if user == prevUser then
					newIndex = rowIndex
				end

				rowIndex = rowIndex + 1
			end
		end
	end

	self.userList:updateItemPositions()
	self.userList:setSelectedIndex(newIndex, true)
end

function InGameMenuMultiplayerUsersFrame:updateElements()
	local isFarmManager = self.playerFarm:isUserFarmManager(self.currentUserId)
	local hasHighPrivilege = isFarmManager or self.currentUser:getIsMasterUser()
	local isOwnFarmSelected = self.selectedUserFarm == self.playerFarm
	local isSpectatorSelected = self.selectedUserFarm.isSpectator
	local isSelfSelected = self.selectedUser:getId() == self.currentUserId
	local isSelectedUserFarmManager = self.selectedUserFarm:isUserFarmManager(self.selectedUser:getId())
	local canManageSelectedFarm = isFarmManager and isOwnFarmSelected or self.currentUser:getIsMasterUser()

	self.transferButton:setVisible(not isOwnFarmSelected and isFarmManager and not isSpectatorSelected)
	self.removeButton:setVisible(canManageSelectedFarm and not isSelfSelected and not isSpectatorSelected)
	self.promoteButton:setVisible(canManageSelectedFarm and not isSpectatorSelected)
	self.contractorButton:setVisible(hasHighPrivilege and not isOwnFarmSelected and not isSpectatorSelected)

	if self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId) then
		self.contractorButton:setText(self.l10n:getText("button_mp_ungrant"))
	else
		self.contractorButton:setText(self.l10n:getText("button_mp_grant"))
	end

	if isSelectedUserFarmManager then
		self.promoteButton:setText(self.l10n:getText("button_mp_dimiss"))
	else
		self.promoteButton:setText(self.l10n:getText("button_mp_promote"))
	end

	local kickBanButtonsVisible = not isSelfSelected and self.currentUser:getIsMasterUser()

	self.kickButton:setVisible(kickBanButtonsVisible)
	self.banButton:setVisible(kickBanButtonsVisible)

	local canChangePermissions = not isSpectatorSelected and canManageSelectedFarm and not isSelectedUserFarmManager and not self.selectedUser:getIsMasterUser()
	local permissions = self.selectedUserFarm:getUserPermissions(self.selectedUser:getId())

	for permissionKey, checkbox in pairs(self.permissionCheckboxes) do
		checkbox:setIsChecked(permissions[permissionKey] or self.selectedUser:getIsMasterUser())
		checkbox:setDisabled(not canChangePermissions)
	end

	self.actionsBox:invalidateLayout()
	self.permissionsBox:invalidateLayout()
end

function InGameMenuMultiplayerUsersFrame:update(dt)
	InGameMenuMultiplayerUsersFrame:superClass().update(self, dt)

	if self.shouldRebuildUserList then
		self.shouldRebuildUserList = false

		self:rebuildUserList()
	end
end

function InGameMenuMultiplayerUsersFrame:updateMenuButtons()
	self.menuButtonInfo = {
		self.backButtonInfo
	}

	if self.currentUser:getIsMasterUser() and self.selectedUser ~= nil then
		if #self.banStorage:getBans() > 0 or g_currentMission.connectedToDedicatedServer then
			table.insert(self.menuButtonInfo, self.unbanButtonInfo)
		end
	elseif g_currentMission ~= nil and g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser() then
		table.insert(self.menuButtonInfo, self.adminButtonInfo)
	end

	if GS_IS_CONSOLE_VERSION then
		if self.selectedUser ~= nil and self.isNavigatingUsers then
			table.insert(self.menuButtonInfo, self.showProfileInfo)
		end

		if PlatformPrivilegeUtil.getCanInvitePlayer(g_currentMission) then
			table.insert(self.menuButtonInfo, self.inviteFriendsInfo)
		end
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuMultiplayerUsersFrame:updateBalance()
	local balance = self.playerFarm:getBalance()
	local balanceMoneyText = self.l10n:formatMoney(balance, 0, false) .. " " .. self.l10n:getCurrencySymbol(true)

	self:setCurrentBalance(balance, balanceMoneyText)
end

function InGameMenuMultiplayerUsersFrame:setCurrentBalance(balance, balanceString)
	local balanceProfile = InGameMenuMultiplayerUsersFrame.PROFILE.BALANCE_POSITIVE

	if math.floor(balance) <= -1 then
		balanceProfile = InGameMenuMultiplayerUsersFrame.PROFILE.BALANCE_NEGATIVE
	end

	if self.currentBalanceText.profile ~= balanceProfile then
		self.currentBalanceText:applyProfile(balanceProfile)
	end

	self.currentBalanceText:setText(balanceString)
end

function InGameMenuMultiplayerUsersFrame:updateDisplay()
	self:rebuildUserList()

	if self.selectedUser ~= nil and self.selectedUserFarm ~= nil then
		self:updateElements()
		self:updateMenuButtons()
	end

	self:updateBalance()
end

function InGameMenuMultiplayerUsersFrame:onButtonBan()
	if self.selectedUser ~= nil and self.selectedUser:getId() ~= g_currentMission:getServerUserId() then
		local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_BAN_CONFIRM), self.selectedUser:getNickname())

		g_gui:showYesNoDialog({
			text = text,
			title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_BAN_TITLE),
			callback = self.onYesNoBan,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.INFO_CANNOT_BAN_SERVER)
		})
	end
end

function InGameMenuMultiplayerUsersFrame:onYesNoBan(yes)
	if yes then
		g_client:getServerConnection():sendEvent(KickBanEvent:new(false, self.selectedUser:getId()))
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonKick()
	if self.selectedUser ~= nil and self.selectedUser:getId() ~= g_currentMission:getServerUserId() then
		local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_KICK_CONFIRM), self.selectedUser:getNickname())

		g_gui:showYesNoDialog({
			text = text,
			title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_KICK_TITLE),
			callback = self.onYesNoKick,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.INFO_CANNOT_KICK_SERVER)
		})
	end
end

function InGameMenuMultiplayerUsersFrame:onYesNoKick(yes)
	if yes then
		g_client:getServerConnection():sendEvent(KickBanEvent:new(true, self.selectedUser:getId()))
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonUnBan()
	g_gui:showUnBanDialog({
		callback = self.updateMenuButtons,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onButtonShowProfile()
	if self.selectedUser ~= nil then
		local nickname = self.selectedUser:getPlatformUserId()

		if nickname == "" then
			nickname = self.selectedUser:getNickname()
		end

		showUserProfile(nickname)
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonInviteFriends()
	if GS_PLATFORM_TYPE ~= GS_PLATFORM_TYPE_PC then
		if g_currentMission ~= nil then
			openMpFriendInvitation(#g_currentMission.userManager:getUsers(), g_currentMission.missionDynamicInfo.capacity)
		else
			openMpFriendInvitation(1, 6)
		end
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonAdminLogin()
	g_gui:showPasswordDialog({
		defaultPassword = "",
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.PROMPT_ADMIN_PASSWORD),
		callback = self.onAdminPassword,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onUserSelected(index)
	local rowElement = self.userList.elements[index]
	local user = self.listRowUser[rowElement]

	if user ~= nil then
		self.selectedUser = user
		local userFarm = self.farmManager:getFarmByUserId(user:getId())
		self.selectedUserFarm = userFarm

		self:updateMenuButtons()
		self:updateElements()
	end
end

function InGameMenuMultiplayerUsersFrame:onClickPermission(checkboxElement, isActive)
	local permission = self.checkboxPermissions[checkboxElement]

	self.selectedUserFarm:setUserPermission(self.selectedUser:getId(), permission, isActive)
end

function InGameMenuMultiplayerUsersFrame:onClickTransferButton()
	g_gui:showTransferMoneyDialog({
		farm = self.selectedUserFarm,
		callback = self.transferMoney,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:transferMoney(amount)
	if amount > 0 then
		self.farmManager:transferMoney(self.selectedUserFarm, amount)
		self:updateBalance()
	end
end

function InGameMenuMultiplayerUsersFrame:onClickRemoveFromFarm()
	local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_REMOVE_CONFIRM), self.selectedUser:getNickname())

	g_gui:showYesNoDialog({
		text = text,
		title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_REMOVE_TITLE),
		callback = self.onYesNoRemoveFromFarm,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onYesNoRemoveFromFarm(yes)
	if yes then
		self.farmManager:removeUserFromFarm(self.selectedUser:getId())
	end
end

function InGameMenuMultiplayerUsersFrame:onClickPromote()
	if not self.selectedUserFarm:isUserFarmManager(self.selectedUser:getId()) then
		local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_PROMOTE_CONFIRM), self.selectedUser:getNickname())

		g_gui:showYesNoDialog({
			text = text,
			title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_PROMOTE_TITLE),
			callback = self.onYesNoPromoteToFarmManager,
			target = self
		})
	else
		self.selectedUserFarm:demoteUser(self.selectedUser:getId())
	end
end

function InGameMenuMultiplayerUsersFrame:onYesNoPromoteToFarmManager(yes)
	if yes then
		self.selectedUserFarm:promoteUser(self.selectedUser:getId())
	end
end

function InGameMenuMultiplayerUsersFrame:onClickContractor()
	local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm)
	local confirmTextTemplateSymbol = ""

	if isContracting then
		confirmTextTemplateSymbol = InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_DENY_CONTRACTOR_CONFIRM
	else
		confirmTextTemplateSymbol = InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_GRANT_CONTRACTOR_CONFIRM
	end

	local text = string.format(self.l10n:getText(confirmTextTemplateSymbol), self.selectedUserFarm.name)

	g_gui:showYesNoDialog({
		text = text,
		title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_CONTRACTOR_STATE_TITLE),
		callback = self.onYesNoToggleContractorState,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onYesNoToggleContractorState(yes)
	if yes then
		local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)

		self.selectedUserFarm:setIsContractingFor(self.playerFarm.farmId, not isContracting, false)
	end
end

function InGameMenuMultiplayerUsersFrame:onFarmsChanged(farmId)
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onPlayerFarmChanged(player)
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onPermissionChanged()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onMasterUserAdded()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onUserAdded()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onUserRemoved()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onContractingStateChanged()
	self:updateElements()
end

function InGameMenuMultiplayerUsersFrame:onAdminPassword(password)
	g_client:getServerConnection():sendEvent(GetAdminEvent:new(password))
end

function InGameMenuMultiplayerUsersFrame:onAdminLoginSuccess()
	self:updateDisplay()

	if self.playerFarm ~= nil and self.playerFarm.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		self.playerFarm:promoteUser(self.currentUserId)
	end
end

InGameMenuMultiplayerUsersFrame.L10N_SYMBOL = {
	PROMPT_ADMIN_PASSWORD = "ui_enterAdminPassword",
	LABEL_FARM_MANAGER = "ui_farmManager",
	INFO_CANNOT_BAN_SERVER = "ui_serverCannotBeBanned",
	LABEL_ADMIN = "ui_admin",
	DIALOG_REMOVE_TITLE = "ui_removeFromFarmTitle",
	MONEY_BUTTON_TEMPLATE = "button_mp_transferMoney",
	DIALOG_PROMOTE_TITLE = "ui_promoteToFarmManagerTitle",
	DIALOG_CONTRACTOR_STATE_TITLE = "ui_contractorStateChangeTitle",
	DIALOG_KICK_CONFIRM = "ui_kickConfirm",
	BUTTON_SHOW_PROFILE = "button_showProfile",
	DIALOG_KICK_TITLE = "ui_kickTitle",
	BUTTON_CONTRACT = "button_mp_grant",
	DIALOG_DENY_CONTRACTOR_CONFIRM = "ui_contractorUngrantConfirm",
	DIALOG_PROMOTE_CONFIRM = "ui_promoteToFarmManagerConfirm",
	BUTTON_UNCONTRACT = "button_mp_ungrant",
	BUTTON_UNBAN = "button_unban",
	DIALOG_BAN_TITLE = "ui_banTitle",
	BUTTON_ADMIN = "button_adminLogin",
	BUTTON_INVITE_FRIENDS = "ui_inviteScreen",
	DIALOG_REMOVE_CONFIRM = "ui_removeFromFarmConfirm",
	DIALOG_BAN_CONFIRM = "ui_banConfirm",
	INFO_CANNOT_KICK_SERVER = "ui_serverCannotBeKicked",
	DIALOG_GRANT_CONTRACTOR_CONFIRM = "ui_contractorGrantConfirm"
}
InGameMenuMultiplayerUsersFrame.PROFILE = {
	BALANCE_NEGATIVE = "shopMoneyNeg",
	BALANCE_POSITIVE = "shopMoney",
	CURRENT_PLAYER_TEXT = "ingameMenuMPUsersListRowTextCurrentPlayer"
}
