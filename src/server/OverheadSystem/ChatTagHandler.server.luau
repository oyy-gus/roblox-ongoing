local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

local ChatTagConfig = {
	TagColors = {
		Owner     = Color3.fromRGB(255, 170, 90),
		Developer = Color3.fromRGB(120, 200, 140),
		Admin     = Color3.fromRGB(200, 80, 80),
		Streamer  = Color3.fromRGB(170, 140, 255),
		Creator   = Color3.fromRGB(120, 220, 220),
		VIP       = Color3.fromRGB(255, 210, 120),
	},

	TagText = {
		Owner     = "👑 OWNER",
		Developer = "⚙️ DEV",
		Admin     = "🛡️ ADMIN",
		Streamer  = "🔴 STREAMER",
		Creator   = "🎨 CREATOR",
		VIP       = "⭐ VIP",
	},

	TagPriority = {
		Owner     = 1,
		Developer = 2,
		Admin     = 3,
		Streamer  = 4,
		Creator   = 5,
		VIP       = 6,
	},
}

local function isStaffRole(role)
	return role == "Owner" or role == "Developer" or role == "Admin"
end

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local GetChatTags = Remotes:WaitForChild("GetChatTags")
local TagsUpdated = Remotes:WaitForChild("TagsUpdated")

local function getPlayerTags(player)
	local tags = {}

	local role        = RoleSystem:GetPlayerRole(player)
	local hasVIP      = RoleSystem:HasVIP(player)
	local hasStreamer = RoleSystem:HasStreamer(player)
	local hasCreator  = RoleSystem:HasCreator(player)

	if isStaffRole(role) then
		return {
			{
				TagText  = ChatTagConfig.TagText[role],
				TagColor = ChatTagConfig.TagColors[role],
				Priority = ChatTagConfig.TagPriority[role],
			}
		}
	end

	if role == "Streamer" or hasStreamer then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.Streamer,
			TagColor = ChatTagConfig.TagColors.Streamer,
			Priority = ChatTagConfig.TagPriority.Streamer,
		})
	end

	if role == "Creator" or hasCreator then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.Creator,
			TagColor = ChatTagConfig.TagColors.Creator,
			Priority = ChatTagConfig.TagPriority.Creator,
		})
	end

	if role == "VIP" or hasVIP then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.VIP,
			TagColor = ChatTagConfig.TagColors.VIP,
			Priority = ChatTagConfig.TagPriority.VIP,
		})
	end

	table.sort(tags, function(a, b)
		return a.Priority < b.Priority
	end)

	return tags
end

GetChatTags.OnServerInvoke = function(requestingPlayer, targetUserId)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return {}
	end
	return getPlayerTags(targetPlayer)
end

local function broadcastTagUpdate(player)
	local tags = getPlayerTags(player)
	TagsUpdated:FireAllClients(player.UserId, tags)
end

RoleSystem.RoleChanged:Connect(broadcastTagUpdate)
RoleSystem.VIPChanged:Connect(broadcastTagUpdate)
RoleSystem.StreamerChanged:Connect(broadcastTagUpdate)
RoleSystem.CreatorChanged:Connect(broadcastTagUpdate)

print("✅ [ChatTagHandler] Server loaded!")
