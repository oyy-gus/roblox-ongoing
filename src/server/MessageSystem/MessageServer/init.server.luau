-- Place in: StarterScriptService > MessageSystem(Folder) > MessageServer(Script)

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)
local MessageConfig = require(script.MessageConfig)

-- ====================================
-- REMOTE SETUP
-- ====================================
local RemoteFolder = ReplicatedStorage:FindFirstChild("Message") or Instance.new("Folder")
RemoteFolder.Name = "Message"
RemoteFolder.Parent = ReplicatedStorage

local CheckAccessRemote = RemoteFolder:FindFirstChild("CheckAccess") or Instance.new("RemoteFunction")
CheckAccessRemote.Name = "CheckAccess"
CheckAccessRemote.Parent = RemoteFolder

local SendMessageRemote = RemoteFolder:FindFirstChild("SendMessage") or Instance.new("RemoteEvent")
SendMessageRemote.Name = "SendMessage"
SendMessageRemote.Parent = RemoteFolder

local ReceiveMessageRemote = RemoteFolder:FindFirstChild("ReceiveMessage") or Instance.new("RemoteEvent")
ReceiveMessageRemote.Name = "ReceiveMessage"
ReceiveMessageRemote.Parent = RemoteFolder

-- ====================================
-- PLAYER DATA
-- ====================================
local PlayerData = {}

local function initPlayerData(userId)
	if not PlayerData[userId] then
		PlayerData[userId] = {
			LastMessageTime = 0,
			MessageCount = 0,
			LastMinuteReset = tick()
		}
	end
end

local function cleanPlayerData(userId)
	PlayerData[userId] = nil
end

-- ====================================
-- ACCESS CHECK
-- ====================================
local function hasAccess(player)
	local role = RoleSystem:GetPlayerRole(player)
	local minRole = MessageConfig.Access.MinimumRole

	local playerPriority = MessageConfig.Access.RoleHierarchy[role] or 0
	local minPriority = MessageConfig.Access.RoleHierarchy[minRole] or 0

	return playerPriority >= minPriority
end

CheckAccessRemote.OnServerInvoke = function(player)
	return hasAccess(player)
end

-- ====================================
-- MESSAGE VALIDATION
-- ====================================
local function validateMessage(player, message)
	initPlayerData(player.UserId)
	local data = PlayerData[player.UserId]

	if not hasAccess(player) then
		return false, "You don't have permission to send messages"
	end

	if #message < MessageConfig.Validation.MinLength then
		return false, "Message too short"
	end

	if #message > MessageConfig.Validation.MaxLength then
		return false, "Message too long (max " .. MessageConfig.Validation.MaxLength .. " characters)"
	end

	local currentTime = tick()
	local timeSinceLastMessage = currentTime - data.LastMessageTime

	if timeSinceLastMessage < MessageConfig.Validation.Cooldown then
		local waitTime = math.ceil(MessageConfig.Validation.Cooldown - timeSinceLastMessage)
		return false, "Please wait " .. waitTime .. " seconds before sending another message"
	end

	if currentTime - data.LastMinuteReset >= 60 then
		data.MessageCount = 0
		data.LastMinuteReset = currentTime
	end

	if data.MessageCount >= MessageConfig.Validation.MaxMessagesPerMinute then
		return false, "Too many messages. Please slow down"
	end

	return true, "Valid"
end

-- ====================================
-- TEXT FILTERING
-- ====================================
local function filterText(text, fromUserId)
	if not MessageConfig.Validation.EnableFilter then
		return text
	end

	local success, result = pcall(function()
		return TextService:FilterStringAsync(text, fromUserId)
	end)

	if success and result then
		local filteredSuccess, filteredText = pcall(function()
			return result:GetNonChatStringForBroadcastAsync()
		end)

		if filteredSuccess then
			return filteredText
		end
	end

	return text
end

-- ====================================
-- SEND MESSAGE
-- ====================================
SendMessageRemote.OnServerEvent:Connect(function(player, message)
	local isValid, errorMsg = validateMessage(player, message)

	if not isValid then
		ReceiveMessageRemote:FireClient(player, {
			Type = "Error",
			Message = errorMsg
		})
		return
	end

	local filteredMessage = filterText(message, player.UserId)

	local data = PlayerData[player.UserId]
	data.LastMessageTime = tick()
	data.MessageCount = data.MessageCount + 1

	local role = RoleSystem:GetPlayerRole(player)
	local roleConfig = MessageConfig.RoleDisplay[role] or MessageConfig.RoleDisplay.Player

	local messageData = {
		Type = "Message",
		SenderId = player.UserId,
		SenderName = player.DisplayName,
		SenderUsername = player.Name,
		Role = role,
		RoleText = roleConfig.Text,
		RoleColor = roleConfig.Color,
		Message = filteredMessage,
		Timestamp = tick()
	}

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		ReceiveMessageRemote:FireClient(targetPlayer, messageData)
	end
end)

-- ====================================
-- PLAYER MANAGEMENT
-- ====================================
Players.PlayerAdded:Connect(function(player)
	initPlayerData(player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	cleanPlayerData(player.UserId)
end)

game:BindToClose(function()
	PlayerData = {}
end)
