local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("SyncRemotes")
local animationStartRE = remotes:WaitForChild("animationStart")
local startSyncRE = remotes:WaitForChild("startSync")
local changeSpeedRE = remotes:WaitForChild("changeSpeed")

local AnimationController = require(script.Parent:WaitForChild("Modules"):WaitForChild("AnimationController"))
local AnimationLoader = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("AnimationLoader"))

local AnimatorUtils = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("AnimatorUtils"))
local SyncController = require(script.Parent:WaitForChild("Modules"):WaitForChild("SyncController"))

local loadedAnimations = AnimationLoader.loadAnimations()

local playerConnections = {}

local function cleanupPlayerConnections(player)
	if playerConnections[player] then
		for _, connection in ipairs(playerConnections[player]) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
		playerConnections[player] = nil
	end
end

local function forceUnsyncAllFollowers(leavingPlayer)
	local leavingPlayerName = leavingPlayer.Name

	for _, follower in ipairs(Players:GetPlayers()) do
		if follower ~= leavingPlayer and follower.Character then
			local syncTarget = follower.Character:GetAttribute("Syncing")

			if syncTarget == leavingPlayerName then

				local animator = AnimatorUtils.getAnimator(follower)
				if animator then
					pcall(function()
						AnimatorUtils.stopAllDances(animator, loadedAnimations, 0)
					end)
				end

				follower.Character:SetAttribute("Syncing", nil)
				follower.Character:SetAttribute("CurrentDance", nil)
				follower.Character:SetAttribute("DanceStartTime", nil)
				follower.Character:SetAttribute("DanceSpeed", nil)
				follower.Character:SetAttribute("IsLeader", nil)
				follower.Character:SetAttribute("FollowerCount", nil)
			end
		end
	end
end

animationStartRE.OnServerInvoke = function(player, animation, shouldPlay, speed)
	return AnimationController.executeAnimation(player, animation, shouldPlay, speed, loadedAnimations)
end

changeSpeedRE.OnServerEvent:Connect(function(player, speed)
	AnimationController.adjustAnimationSpeed(player, speed, loadedAnimations)
end)

startSyncRE.OnServerEvent:Connect(function(player, target, condition)
	SyncController.handleSyncRequest(player, target, condition, loadedAnimations)
end)

local function setupPlayerRespawnHandler(player)
	cleanupPlayerConnections(player)

	if not playerConnections[player] then
		playerConnections[player] = {}
	end

	local charAddedConn = player.CharacterAdded:Connect(function(character)

		local humanoid = character:WaitForChild("Humanoid", 5)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)

		if not humanoid or not hrp then
			warn("[SyncSystem] Character load timeout for", player.Name)
			return
		end

		task.wait(0.5)

		local unsyncSuccess = pcall(function()
			forceUnsyncAllFollowers(player)
		end)

		if not unsyncSuccess then
			warn("[SyncSystem] Gagal memaksa unsync untuk", player.Name)
		end

		character:SetAttribute("Syncing", nil)
		character:SetAttribute("IsLeader", nil)
		character:SetAttribute("FollowerCount", nil)

		task.delay(0.2, function()
			SyncController.updateAllLeaderStatus()
		end)
	end)

	table.insert(playerConnections[player], charAddedConn)

	local charRemovingConn = player.CharacterRemoving:Connect(function(character)

		pcall(function()
			forceUnsyncAllFollowers(player)
		end)

		character:SetAttribute("Syncing", nil)
		character:SetAttribute("IsLeader", nil)
		character:SetAttribute("FollowerCount", nil)
	end)

	table.insert(playerConnections[player], charRemovingConn)

	if player.Character then
		task.spawn(function()
			local humanoid = player.Character:WaitForChild("Humanoid", 5)
			local hrp = player.Character:WaitForChild("HumanoidRootPart", 5)

			if humanoid and hrp then
				player.Character:SetAttribute("Syncing", nil)
				player.Character:SetAttribute("IsLeader", nil)
				player.Character:SetAttribute("FollowerCount", nil)
			end
		end)
	end
end

Players.PlayerRemoving:Connect(function(leavingPlayer)

	pcall(function()
		forceUnsyncAllFollowers(leavingPlayer)
	end)

	cleanupPlayerConnections(leavingPlayer)

	if leavingPlayer.Character then
		leavingPlayer.Character:SetAttribute("Syncing", nil)
		leavingPlayer.Character:SetAttribute("IsLeader", nil)
		leavingPlayer.Character:SetAttribute("FollowerCount", nil)
	end

	task.wait(0.1)
	SyncController.updateAllLeaderStatus()
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(0.5)
	setupPlayerRespawnHandler(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(0.5)
		setupPlayerRespawnHandler(player)
	end)
end

game:BindToClose(function()

	for player, _ in pairs(playerConnections) do
		cleanupPlayerConnections(player)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			player.Character:SetAttribute("Syncing", nil)
			player.Character:SetAttribute("IsLeader", nil)
			player.Character:SetAttribute("FollowerCount", nil)
		end
	end
end)
