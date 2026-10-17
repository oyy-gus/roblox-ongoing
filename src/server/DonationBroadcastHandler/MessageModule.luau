local BroadcastConfig = require(script.Parent.BroadcastConfig)

local MessageModule = {}

function MessageModule.filterMessage(message)

	message = message:gsub("^%s+", ""):gsub("%s+$", "")

	if #message > BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH then
		message = message:sub(1, BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH)
	end

	return message
end

return MessageModule
