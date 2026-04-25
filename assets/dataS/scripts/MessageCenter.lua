MessageCenter = {}
local MessageCenter_mt = Class(MessageCenter)

function MessageCenter:new(customMt)
	local self = {}

	setmetatable(self, MessageCenter_mt)

	self.subscribers = {}
	self.queue = {}

	return self
end

function MessageCenter:delete()
end

function MessageCenter:update(dt)
	if #self.queue > 0 then
		for _, message in ipairs(self.queue) do
			self:publish(message[1], unpack(message[2]))
		end

		self.queue = {}
	end
end

function MessageCenter:subscribe(messageType, callback, callbackTarget, argument)
	if messageType == nil then
		g_logManager:warning("Tried subscribing to a message with a nil-value message type. Check subscribe() function call arguments at:")
		printCallstack()

		return
	end

	if callback == nil then
		g_logManager:warning("Tried subscribing to a message with a nil-value callback. Check subscribe() function call arguments at:")
		printCallstack()

		return
	end

	local subscribers = self.subscribers[messageType]

	if subscribers == nil then
		subscribers = {}
		self.subscribers[messageType] = subscribers
	end

	table.insert(subscribers, {
		callback = callback,
		callbackTarget = callbackTarget,
		argument = argument
	})
end

function MessageCenter:unsubscribe(messageType, callbackTarget)
	local subscribers = self.subscribers[messageType]

	if subscribers ~= nil then
		for _, info in ipairs(subscribers) do
			if info.callbackTarget == callbackTarget then
				ListUtil.removeElementFromList(subscribers, info)
			end
		end
	end
end

function MessageCenter:unsubscribeAll(callbackTarget)
	for messageId, subscribers in pairs(self.subscribers) do
		for _, info in ipairs(subscribers) do
			if info.callbackTarget == callbackTarget then
				ListUtil.removeElementFromList(subscribers, info)
			end
		end
	end
end

function MessageCenter:publish(messageType, ...)
	if messageType == nil then
		g_logManager:warning("Warning: Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()

		return
	end

	local subscribers = self.subscribers[messageType]

	if subscribers ~= nil then
		for _, info in ipairs(subscribers) do
			if info.callbackTarget == nil then
				if info.argument == nil then
					info.callback(...)
				else
					info.callback(info.argument, ...)
				end
			elseif info.argument == nil then
				info.callback(info.callbackTarget, ...)
			else
				info.callback(info.callbackTarget, info.argument, ...)
			end
		end
	end
end

function MessageCenter:publishDelayed(messageType, ...)
	if messageType == nil then
		g_logManager:warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()

		return
	end

	table.insert(self.queue, {
		messageType,
		{
			...
		}
	})
end

local messageTypeId = 0

function nextMessageTypeId()
	messageTypeId = messageTypeId + 1

	return messageTypeId
end

MessageType = {
	MONEY_CHANGED = nextMessageTypeId(),
	PLAYER_FARM_CHANGED = nextMessageTypeId(),
	FARM_CREATED = nextMessageTypeId(),
	FARM_PROPERTY_CHANGED = nextMessageTypeId(),
	FARM_DELETED = nextMessageTypeId(),
	PLAYER_CREATED = nextMessageTypeId(),
	ACHIEVEMENT_UNLOCKED = nextMessageTypeId(),
	HUSBANDRY_ANIMALS_CHANGED = nextMessageTypeId(),
	VEHICLE_REPAIRED = nextMessageTypeId(),
	VEHICLE_RESET = nextMessageTypeId(),
	GUI_BEFORE_OPEN = nextMessageTypeId(),
	GUI_AFTER_OPEN = nextMessageTypeId(),
	GUI_BEFORE_CLOSE = nextMessageTypeId(),
	GUI_AFTER_CLOSE = nextMessageTypeId(),
	GUI_INGAME_OPEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_FINANCES_SCREEN = nextMessageTypeId(),
	GUI_INGAME_OPEN_FARMS_SCREEN = nextMessageTypeId(),
	GUI_CAREER_SCREEN_OPEN = nextMessageTypeId(),
	GUI_MAIN_SCREEN_OPEN = nextMessageTypeId(),
	GUI_CHARACTER_CREATION_SCREEN_OPEN = nextMessageTypeId(),
	GUI_DIALOG_OPENED = nextMessageTypeId(),
	SAVEGAMES_LOADED = nextMessageTypeId(),
	GAME_STATE_CHANGED = nextMessageTypeId(),
	SETTING_CHANGED = {}
}

for _, setting in pairs(GameSettings.SETTING) do
	MessageType.SETTING_CHANGED[setting] = nextMessageTypeId()
end

MessageType.INPUT_BINDINGS_CHANGED = nextMessageTypeId()
MessageType.INPUT_MODE_CHANGED = nextMessageTypeId()
MessageType.INPUT_HELP_MODE_CHANGED = nextMessageTypeId()
MessageType.INPUT_DEVICES_CHANGED = nextMessageTypeId()
MessageType.TIMESCALE_CHANGED = nextMessageTypeId()
MessageType.SAVEGAME_LOADED = nextMessageTypeId()
MessageType.MISSION_GENERATED = nextMessageTypeId()
MessageType.MISSION_DELETED = nextMessageTypeId()
MessageType.MISSION_TOUR_STARTED = nextMessageTypeId()
MessageType.MISSION_TOUR_FINISHED = nextMessageTypeId()
MessageType.USER_PROFILE_CHANGED = nextMessageTypeId()
MessageType.USER_ADDED = nextMessageTypeId()
MessageType.USER_REMOVED = nextMessageTypeId()
MessageType.MASTERUSER_ADDED = nextMessageTypeId()
MessageType.HOUR_CHANGED = nextMessageTypeId()
MessageType.DAY_CHANGED = nextMessageTypeId()
MessageType.UNLOADING_STATIONS_CHANGED = nextMessageTypeId()
MessageType.AI_VEHICLE_STATE_CHANGE = nextMessageTypeId()
MessageType.RADIO_CHANNEL_CHANGE = nextMessageTypeId()
MessageType.APP_SUSPENDED = nextMessageTypeId()
MessageType.APP_RESUMED = nextMessageTypeId()
