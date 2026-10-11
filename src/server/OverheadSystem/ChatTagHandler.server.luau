-- ============================================================
-- ChatTagHandler (SERVER)
-- Menyediakan data tag untuk client
-- Admin+ hanya tampilkan 1 tag tertinggi
-- Place in: ServerScriptService > OverheadSystem > ChatTagHandler
-- ============================================================

local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

-- ============================================================
-- CONFIG CHAT TAGS
-- ============================================================
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

-- ============================================================
-- HELPER: Cek apakah role adalah Staff (Admin+)
-- ============================================================
local function isStaffRole(role)
	return role == "Owner" or role == "Developer" or role == "Admin"
end

-- ============================================================
-- GET REMOTES (Manual)
-- ============================================================
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local GetChatTags = Remotes:WaitForChild("GetChatTags")
local TagsUpdated = Remotes:WaitForChild("TagsUpdated")

-- ============================================================
-- HELPER: Kumpulkan tag yang dimiliki pemain
-- ============================================================
local function getPlayerTags(player)
	local tags = {}

	local role        = RoleSystem:GetPlayerRole(player)
	local hasVIP      = RoleSystem:HasVIP(player)
	local hasStreamer = RoleSystem:HasStreamer(player)
	local hasCreator  = RoleSystem:HasCreator(player)

	-- ========================================
	-- STAFF ROLE (Admin+): Hanya 1 tag
	-- ========================================
	if isStaffRole(role) then
		return {
			{
				TagText  = ChatTagConfig.TagText[role],
				TagColor = ChatTagConfig.TagColors[role],
				Priority = ChatTagConfig.TagPriority[role],
			}
		}
	end

	-- ========================================
	-- NON-STAFF: Bisa multiple tags
	-- ========================================

	-- Streamer
	if role == "Streamer" or hasStreamer then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.Streamer,
			TagColor = ChatTagConfig.TagColors.Streamer,
			Priority = ChatTagConfig.TagPriority.Streamer,
		})
	end

	-- Creator
	if role == "Creator" or hasCreator then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.Creator,
			TagColor = ChatTagConfig.TagColors.Creator,
			Priority = ChatTagConfig.TagPriority.Creator,
		})
	end

	-- VIP
	if role == "VIP" or hasVIP then
		table.insert(tags, {
			TagText  = ChatTagConfig.TagText.VIP,
			TagColor = ChatTagConfig.TagColors.VIP,
			Priority = ChatTagConfig.TagPriority.VIP,
		})
	end

	-- Urutkan berdasarkan prioritas
	table.sort(tags, function(a, b)
		return a.Priority < b.Priority
	end)

	return tags
end

-- ============================================================
-- REMOTE FUNCTION: Client request tags untuk UserId
-- ============================================================
GetChatTags.OnServerInvoke = function(requestingPlayer, targetUserId)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return {}
	end
	return getPlayerTags(targetPlayer)
end

-- ============================================================
-- BROADCAST: Notifikasi client saat role berubah
-- ============================================================
local function broadcastTagUpdate(player)
	local tags = getPlayerTags(player)
	TagsUpdated:FireAllClients(player.UserId, tags)
end

RoleSystem.RoleChanged:Connect(broadcastTagUpdate)
RoleSystem.VIPChanged:Connect(broadcastTagUpdate)
RoleSystem.StreamerChanged:Connect(broadcastTagUpdate)
RoleSystem.CreatorChanged:Connect(broadcastTagUpdate)

print("✅ [ChatTagHandler] Server loaded!")
