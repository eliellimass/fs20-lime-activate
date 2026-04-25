DenyAcceptDialog = {}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog, YesNoDialog)

function DenyAcceptDialog:new(target, custom_mt)
	local self = YesNoDialog:new(target, custom_mt or DenyAcceptDialog_mt)

	return self
end

function DenyAcceptDialog:sendCallback(isDenied, isAlwaysDenied)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, self.connection, isDenied, isAlwaysDenied)
			else
				self.callbackFunc(self.connection, isDenied, isAlwaysDenied)
			end
		end
	end
end

function DenyAcceptDialog:onClickOk()
	self:sendCallback(false, false)

	return false
end

function DenyAcceptDialog:onClickBack(forceBack)
	self:sendCallback(true, false)

	return false
end

function DenyAcceptDialog:onClickCancel(forceBack)
	self:sendCallback(true, false)

	return false
end

function DenyAcceptDialog:onClickActivate()
	self:sendCallback(true, true)

	return false
end

function DenyAcceptDialog:setConnection(connection)
	local text = g_i18n:getText("ui_playerWantsToJoinGame")

	if connection ~= nil then
		self.connection = connection
	end

	self:setText(text)
end
