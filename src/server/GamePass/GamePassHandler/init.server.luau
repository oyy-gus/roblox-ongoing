local Config = require(script.Config)
local Logger = require(script.Logger)
local AntiSpamManager = require(script.AntiSpamManager)
local ValidationManager = require(script.ValidationManager)
local ShopHandler = require(script.ShopHandler)

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

local GamepassFolder = ReplicatedStorage:FindFirstChild("Gamepass")
if not GamepassFolder then
	GamepassFolder = Instance.new("Folder")
	GamepassFolder.Name = "Gamepass"
	GamepassFolder.Parent = ReplicatedStorage
end

local shopRequest = GamepassFolder:FindFirstChild("ShopRequest")
if not shopRequest then
	shopRequest = Instance.new("RemoteFunction")
	shopRequest.Name = "ShopRequest"
	shopRequest.Parent = GamepassFolder
end

local playerDataUpdated = GamepassFolder:FindFirstChild("PlayerDataUpdated")
if not playerDataUpdated then
	playerDataUpdated = Instance.new("RemoteEvent")
	playerDataUpdated.Name = "PlayerDataUpdated"
	playerDataUpdated.Parent = GamepassFolder
end

local refreshRole = GamepassFolder:FindFirstChild("RefreshRole")
if not refreshRole then
	refreshRole = Instance.new("RemoteEvent")
	refreshRole.Name = "RefreshRole"
	refreshRole.Parent = GamepassFolder
end

Logger:Success("Remotes created successfully")

Logger:Info("Initializing Gamepass System (VIP Only)...")

ShopHandler:Init(RoleSystem, ValidationManager)

Logger:Success("All systems initialized!")

shopRequest.OnServerInvoke = function(player, requestData)
	if not ValidationManager:ValidatePlayer(player) then
		return {success = false, error = "Invalid player"}
	end

	local action = requestData.action

	if AntiSpamManager:IsSpamming(player, "shop_" .. action) then
		return {success = false, error = "Too many requests"}
	end

	if action == "GetShopData" then
		return ShopHandler:GetShopData(player)
	elseif action == "PromptPurchase" then
		return ShopHandler:PromptPurchase(player, requestData.gamepassType)
	else
		return {success = false, error = "Unknown action"}
	end
end

refreshRole.OnServerEvent:Connect(function(player)
	if not ValidationManager:ValidatePlayer(player) then return end
	if AntiSpamManager:IsSpamming(player) then return end

	ShopHandler:UpdatePlayerRole(player)
end)

Logger:Success("Remote handlers connected")

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassID, purchaseSuccess)
	ShopHandler:HandlePurchaseFinished(player, purchasedPassID, purchaseSuccess)
end)

Logger:Success("Marketplace events connected")

RoleSystem.RoleChanged:Connect(function(player, oldRole, newRole)
	Logger:Info(string.format("Role changed: %s -> %s (%s)",
		oldRole, newRole, player.Name))

	if Config.BroadcastRoleChange then
		ShopHandler:NotifyRoleUpdate(player, newRole)
	end
end)

Players.PlayerAdded:Connect(function(player)
	Logger:Info(string.format("Player joined: %s (UserId: %d)", player.Name, player.UserId))

	task.spawn(function()
		local role = RoleSystem:InitializePlayer(player)
		Logger:Success(string.format("%s initialized with role: %s", player.Name, role))
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	Logger:Info(string.format("Player leaving: %s (UserId: %d)", player.Name, player.UserId))

	AntiSpamManager:CleanupPlayer(player.UserId)
	RoleSystem:InvalidateOwnershipCache(player.UserId)

	Logger:Debug(string.format("Cleaned up data for %s", player.Name))
end)

task.spawn(function()
	while true do
		task.wait(Config.StatsReportInterval)

		local ownershipStats = RoleSystem:GetOwnershipStats()

		Logger:Info(string.format(
			"Ownership Stats - Cached: %d, VIP: %d, Streamer: %d, Creator: %d",
			ownershipStats.totalCached,
			ownershipStats.vipCount,
			ownershipStats.streamerCount,
			ownershipStats.creatorCount
			))
	end
end)

task.spawn(function()
	while true do
		task.wait(60)

		local playerCount = #Players:GetPlayers()
		local cacheCount = RoleSystem:GetOwnershipStats().totalCached

		if playerCount > 0 and cacheCount == 0 then
			Logger:Warn("HEALTH CHECK FAILED: No ownership cache despite players online!")
		end
	end
end)

Logger:Success("Gamepass System ready (VIP Only)!")
Logger:Success("Features:")
Logger:Success("  - Buy VIP gamepass for self")
Logger:Success("  - Auto role detection")
Logger:Success("  - Anti-spam protection")
Logger:Success("  - Debug system")
