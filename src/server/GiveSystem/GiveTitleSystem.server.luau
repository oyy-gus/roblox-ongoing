local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage  = game:GetService("ServerStorage")

local TitleEvent = ReplicatedStorage:FindFirstChild("TitleEvent")
if not TitleEvent then
	TitleEvent = Instance.new("RemoteEvent")
	TitleEvent.Name = "TitleEvent"
	TitleEvent.Parent = ReplicatedStorage
end

local ModulesFolder   = script.Parent:WaitForChild("Title")
local DataStoreModule = require(ModulesFolder:WaitForChild("DataStoreModule"))
local TitleRenderer   = require(ModulesFolder:WaitForChild("TitleRenderer"))
local PlayerManager   = require(ModulesFolder:WaitForChild("PlayerManager"))
local RoleSystem      = require(ServerStorage.Modules.RoleSystem)

local function isAdmin(player)
	local role = RoleSystem:GetPlayerRole(player)
	return role == "Owner" or role == "Developer" or role == "Admin"
end

TitleEvent.OnServerEvent:Connect(function(player, action, ...)

	if action == "RequestAdminPanel" then
		if isAdmin(player) then
			TitleEvent:FireClient(player, "IsAdmin")
			TitleEvent:FireClient(player, "ShowPanel")
		end
		return
	end

	if action == "RequestPlayerList" then
		if isAdmin(player) then
			TitleEvent:FireClient(player, "PlayerList", PlayerManager:GetPlayerList())
		end
		return
	end

	if action == "RequestPlayerTitles" then
		if isAdmin(player) then
			local targetName = ...
			local function sendTitles(userId)
				local titles = DataStoreModule:LoadTitlesForUserId(userId) or {}
				TitleEvent:FireClient(player, "PlayerTitles", titles)
			end
			local target = Players:FindFirstChild(targetName)
			if target then
				sendTitles(target.UserId)
				return
			end
			local userId = PlayerManager:ResolveUserIdByName(targetName)
			if userId then
				sendTitles(userId)
			else
				TitleEvent:FireClient(player, "PlayerTitles", {})
			end
		end
		return
	end

	if not isAdmin(player) then return end

	if action == "SetTitleSlot" then
		local targetName, slot, text, mode, colorTemplate, _, height, fontStyle, distanceLevel = ...
		slot = math.clamp(tonumber(slot) or 1, 1, 14)

		local function apply(userId)
			local titles = DataStoreModule:LoadTitlesForUserId(userId) or {}
			titles[slot] = {
				Text          = tostring(text or ""),
				Mode          = tostring(mode or "fixed"),
				ColorTemplate = tostring(colorTemplate or "Sunset"),
				Height        = tonumber(height) or 0,
				Font          = tostring(fontStyle or "Gotham"),
				Distance      = math.clamp(tonumber(distanceLevel) or 20, 0, 20),
			}
			DataStoreModule:SaveTitlesForUserId(userId, titles)
			local t = Players:GetPlayerByUserId(userId)
			if t and t.Character then
				TitleRenderer:RenderAllTitles(t, t.Character, titles)
			end
		end

		local target = Players:FindFirstChild(targetName)
		if target then apply(target.UserId); return end
		local id = PlayerManager:ResolveUserIdByName(targetName)
		if id then apply(id) else warn("[GiveTitleSystem] SetTitleSlot: tidak dapat menemukan:", targetName) end

	elseif action == "RemoveTitleSlot" then
		local targetName, slot = ...
		slot = math.clamp(tonumber(slot) or 1, 1, 14)

		local function remove(userId)
			local titles = DataStoreModule:LoadTitlesForUserId(userId) or {}
			titles[slot] = nil
			DataStoreModule:SaveTitlesForUserId(userId, titles)
			local t = Players:GetPlayerByUserId(userId)
			if t and t.Character then
				TitleRenderer:RenderAllTitles(t, t.Character, titles)
			end
		end

		local target = Players:FindFirstChild(targetName)
		if target then remove(target.UserId); return end
		local id = PlayerManager:ResolveUserIdByName(targetName)
		if id then remove(id) else warn("[GiveTitleSystem] RemoveTitleSlot: tidak dapat menemukan:", targetName) end

	elseif action == "RemoveAllTitles" then
		local targetName = ...

		local function removeAll(userId)
			DataStoreModule:SaveTitlesForUserId(userId, nil)
			local t = Players:GetPlayerByUserId(userId)
			if t and t.Character then
				TitleRenderer:ClearTitles(t.Character, userId)
			end
		end

		local target = Players:FindFirstChild(targetName)
		if target then removeAll(target.UserId); return end
		local id = PlayerManager:ResolveUserIdByName(targetName)
		if id then removeAll(id) else warn("[GiveTitleSystem] RemoveAllTitles: tidak dapat menemukan:", targetName) end
	end
end)

local function onPlayerAdded(player)

	task.spawn(function()
		task.wait(1)
		if isAdmin(player) then
			player:SetAttribute("IsAdmin", true)
		end
	end)

	PlayerManager:SetupPlayerMonitoring(player, DataStoreModule, TitleRenderer)

	if player.Character then
		task.wait(0.8)
		local titles = DataStoreModule:LoadTitlesForUserId(player.UserId) or {}
		TitleRenderer:RenderAllTitles(player, player.Character, titles)
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlayerManager:OnPlayerRemoving(player)
	TitleRenderer:OnPlayerRemoving(player.UserId)
end)

Players.PlayerAdded:Connect(onPlayerAdded)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

print("✅ [GiveTitleSystem] Berhasil dimuat!")

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local RoleSystem = require(ServerStorage.Modules.RoleSystem)

local Config = {
	DebugMode = false,
	CheckInterval = 5,

	RankItems = {
		{
			Name = "Glowstick",
			Path = ServerStorage.Items.Glowstick,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},
		{
			Name = "Sign",
			Path = ServerStorage.Items.Sign,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},
		{
			Name = "SupremeMoneyGun",
			Path = ServerStorage.Items.SupremeMoneyGun,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},
		{
			Name = "Heart",
			Path = ServerStorage.Items.Heart,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},
		{
			Name = "Mawar",
			Path = ServerStorage.Items.Mawar,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},

		{
			Name = "SelfieStick",
			Path = ServerStorage.Items.SelfieStick,
			MinimumRank = "VIP",
			MinimumHierarchy = 2
		},

	}
}

local playerGivenItems = {}

local function debugPrint(...)
	if Config.DebugMode then
		print("[ItemGiver]", ...)
	end
end

local function hasMinimumRank(player, minimumHierarchy)
	local playerRole = RoleSystem:GetPlayerRole(player)
	local playerHierarchy = RoleSystem.Config.RoleHierarchy[playerRole] or 0
	return playerHierarchy >= minimumHierarchy
end

local function countItems(player, itemName)
	local count = 0

	if player.Backpack then
		for _, item in ipairs(player.Backpack:GetChildren()) do
			if item.Name == itemName and item:IsA("Tool") then
				count = count + 1
			end
		end
	end

	if player.Character then
		for _, item in ipairs(player.Character:GetChildren()) do
			if item.Name == itemName and item:IsA("Tool") then
				count = count + 1
			end
		end
	end

	return count
end

local function hasItem(player, itemName)
	return countItems(player, itemName) > 0
end

local function cleanAllDuplicates(player, itemName)
	local removed = 0

	if player.Backpack then
		for _, item in ipairs(player.Backpack:GetChildren()) do
			if item.Name == itemName and item:IsA("Tool") then
				item:Destroy()
				removed = removed + 1
			end
		end
	end

	if player.Character then
		for _, item in ipairs(player.Character:GetChildren()) do
			if item.Name == itemName and item:IsA("Tool") then
				item:Destroy()
				removed = removed + 1
			end
		end
	end

	if removed > 0 then
		debugPrint(string.format("Cleaned %d duplicate(s) of %s from %s", removed, itemName, player.Name))
	end
end

local function giveItemToPlayer(player, itemConfig)
	if not player or not player.Parent then
		return
	end

	if not player.Backpack then
		return
	end

	if not itemConfig.Path or not itemConfig.Path.Parent then
		if Config.DebugMode then
			warn("[ItemGiver] Sumber item tidak ditemukan:", itemConfig.Name)
		end
		return
	end

	cleanAllDuplicates(player, itemConfig.Name)
	task.wait(0.05)

	local itemClone = itemConfig.Path:Clone()
	itemClone.Parent = player.Backpack

	if not playerGivenItems[player.UserId] then
		playerGivenItems[player.UserId] = {}
	end
	playerGivenItems[player.UserId][itemConfig.Name] = true

	debugPrint(string.format("Gave %s to %s (Rank: %s)",
		itemConfig.Name,
		player.Name,
		RoleSystem:GetPlayerRole(player)
		))
end

local function checkAndGiveItems(player)
	if not player or not player.Parent then
		return
	end

	if not playerGivenItems[player.UserId] then
		playerGivenItems[player.UserId] = {}
	end

	for _, itemConfig in ipairs(Config.RankItems) do
		if hasMinimumRank(player, itemConfig.MinimumHierarchy) then
			local itemCount = countItems(player, itemConfig.Name)

			if not playerGivenItems[player.UserId][itemConfig.Name] or itemCount == 0 then
				giveItemToPlayer(player, itemConfig)
			elseif itemCount > 1 then
				debugPrint(string.format("Found %d duplicates of %s for %s - cleaning...", itemCount, itemConfig.Name, player.Name))
				cleanAllDuplicates(player, itemConfig.Name)
				task.wait(0.05)
				giveItemToPlayer(player, itemConfig)
			end
		else
			if hasItem(player, itemConfig.Name) then
				cleanAllDuplicates(player, itemConfig.Name)
				playerGivenItems[player.UserId][itemConfig.Name] = nil
				debugPrint(string.format("Removed %s from %s (Insufficient rank)",
					itemConfig.Name,
					player.Name
					))
			end
		end
	end
end

local playerLoops = {}

local function startPlayerLoop(player)
	if playerLoops[player] then
		playerLoops[player]:Disconnect()
	end

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	task.wait(1)
	checkAndGiveItems(player)

	local lastCheck = tick()
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not player or not player.Parent then
			connection:Disconnect()
			playerLoops[player] = nil
			return
		end

		if tick() - lastCheck >= Config.CheckInterval then
			lastCheck = tick()
			checkAndGiveItems(player)
		end
	end)

	playerLoops[player] = connection
end

local function onPlayerAdded(player)
	RoleSystem:InitializePlayer(player)
	playerGivenItems[player.UserId] = {}

	player.CharacterAdded:Connect(function()
		playerGivenItems[player.UserId] = {}
		task.wait(1.5)
		checkAndGiveItems(player)
	end)

	startPlayerLoop(player)
end

local function onPlayerRemoving(player)
	if playerLoops[player] then
		playerLoops[player]:Disconnect()
		playerLoops[player] = nil
	end

	playerGivenItems[player.UserId] = nil
end

RoleSystem.RoleChanged:Connect(function(player, oldRole, newRole)
	debugPrint(string.format("Role changed: %s (%s -> %s)",
		player.Name,
		oldRole,
		newRole
		))

	playerGivenItems[player.UserId] = {}
	task.wait(0.5)
	checkAndGiveItems(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerAdded(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

debugPrint("Rank Item Giver System initialized (VIP Only)!")
debugPrint("Check interval:", Config.CheckInterval, "seconds")
debugPrint("Configured items:", #Config.RankItems)
