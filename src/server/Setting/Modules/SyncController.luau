-- SyncController.lua — PURE DANCESCRIPT + Instant Follower Crossfade
--
-- PRIORITY SETTINGS:
-- AnimationPriority.Action = Ensures followers have the same stable priority as leader
-- This prevents default animations from interfering with synced dance animations
--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimatorUtils = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("AnimatorUtils"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local syncNotificationRE = remotes:FindFirstChild("SyncNotification")
if not syncNotificationRE then
	syncNotificationRE = Instance.new("RemoteEvent")
	syncNotificationRE.Name = "SyncNotification"
	syncNotificationRE.Parent = remotes
end

local module = {}

-- ============================================
-- CONFIG
-- ============================================
local FADE_IN = 0.5
local FADE_OUT = 0.5
local DANCE_WALK_SPEED = 16

-- ANIMATION PRIORITY (Must match AnimationController!)
local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4

-- Track original walk speeds
local originalWalkSpeeds = {}
local MAX_SYNC_DEPTH = 100

-- ============================================
-- WalkSpeed Management
-- ============================================
local function saveOriginalWalkSpeed(player)
	if not originalWalkSpeeds[player] then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			originalWalkSpeeds[player] = humanoid.WalkSpeed
		end
	end
end

local function setDanceWalkSpeed(player)
	saveOriginalWalkSpeed(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = DANCE_WALK_SPEED
	end
end

local function restoreOriginalWalkSpeed(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and originalWalkSpeeds[player] then
		humanoid.WalkSpeed = originalWalkSpeeds[player]
	end
end

-- ============================================
-- Helper Functions
-- ============================================
local function waitForCharacterReady(player, timeout)
	timeout = timeout or 5
	local startTime = tick()

	while tick() - startTime < timeout do
		if AnimatorUtils.isCharacterReady(player) then
			return true
		end
		task.wait(0.1)
	end

	return false
end

-- ============================================
-- Get Ultimate Sync Source
-- ============================================
function module.getSyncSource(player, depth, visitedPlayers)
	depth = depth or 0
	visitedPlayers = visitedPlayers or {}

	if not player or not player.Parent then 
		return nil
	end

	if not player.Character or not player.Character.Parent then 
		return nil 
	end

	if depth >= MAX_SYNC_DEPTH then
		warn("[SyncController] Max sync depth reached for", player.Name)
		return player
	end

	if visitedPlayers[player] then
		warn("[SyncController] Circular sync detected for", player.Name)
		player.Character:SetAttribute("Syncing", nil)
		return player
	end

	visitedPlayers[player] = true

	local syncTarget = player.Character:GetAttribute("Syncing")
	if not syncTarget or syncTarget == "" then 
		return player 
	end

	local targetPlayer = Players:FindFirstChild(syncTarget)
	if not targetPlayer or not targetPlayer.Parent then
		player.Character:SetAttribute("Syncing", nil)
		return player
	end

	if not targetPlayer.Character or not targetPlayer.Character.Parent then
		player.Character:SetAttribute("Syncing", nil)
		return player
	end

	return module.getSyncSource(targetPlayer, depth + 1, visitedPlayers)
end

-- ============================================
-- Count Followers
-- ============================================
function module.getFollowerCount(player)
	if not player or not player.Parent or not player.Character then
		return 0
	end

	local count = 0

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Parent and p.Character then
			local success, ultimateLeader = pcall(function()
				return module.getSyncSource(p)
			end)

			if success and ultimateLeader == player then
				count = count + 1
			elseif not success then
				if p.Character then
					p.Character:SetAttribute("Syncing", nil)
				end
			end
		end
	end

	return count
end

-- ============================================
-- Check if player is a leader
-- ============================================
function module.isLeader(player)
	if not player or not player.Character then
		return false
	end

	local isLeader = player.Character:GetAttribute("IsLeader")
	local followerCount = player.Character:GetAttribute("FollowerCount") or 0

	return isLeader == true and followerCount > 0
end

-- ============================================
-- Check if target is following player
-- ============================================
function module.isFollowingPlayer(follower, leader)
	if not follower or not leader then
		return false
	end

	if not follower.Character or not leader.Character then
		return false
	end

	local success, ultimateLeader = pcall(function()
		return module.getSyncSource(follower)
	end)

	return success and ultimateLeader == leader
end

-- ============================================
-- Update Leader Status
-- ============================================
function module.updateLeaderStatus(player)
	if not player or not player.Parent or not player.Character then 
		return 
	end

	local success, followerCount = pcall(function()
		return module.getFollowerCount(player)
	end)

	if not success then
		followerCount = 0
	end

	if followerCount > 0 then
		player.Character:SetAttribute("IsLeader", true)
		player.Character:SetAttribute("FollowerCount", followerCount)
	else
		player.Character:SetAttribute("IsLeader", nil)
		player.Character:SetAttribute("FollowerCount", nil)
	end
end

function module.updateAllLeaderStatus()
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			module.updateLeaderStatus(player)
		end)
	end
end

-- ============================================
-- Stop All Followers
-- ============================================
function module.stopAllFollowers(leaderPlayer, loadedAnimations)
	if not leaderPlayer then return 0 end

	local stoppedCount = 0
	local leaderName = leaderPlayer.Name

	for _, follower in ipairs(Players:GetPlayers()) do
		if follower ~= leaderPlayer and follower.Character then
			local syncTarget = follower.Character:GetAttribute("Syncing")

			if syncTarget == leaderName then
				local animator = AnimatorUtils.getAnimator(follower)
				if animator then
					pcall(function()
						AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)
					end)
				end

				restoreOriginalWalkSpeed(follower)
				stoppedCount = stoppedCount + 1
			end
		end
	end

	return stoppedCount
end

-- ============================================
-- 🚀 INSTANT CROSSFADE for Followers Only
-- ============================================
function module.syncPlayerToAnimation(player, sourcePlayer, animation, speed, loadedAnimations)
	if not AnimatorUtils.isCharacterReady(player) then
		warn("[SyncController] Player character not ready:", player.Name)
		return false
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator or not animation then 
		return false
	end

	-- Get leader's current TimePosition
	local sourceAnimator = AnimatorUtils.getAnimator(sourcePlayer)
	local leaderTimePosition = 0

	if sourceAnimator then
		local leaderTrack = AnimatorUtils.getPlayingDanceTrack(sourceAnimator, loadedAnimations)
		if leaderTrack and leaderTrack.Animation == animation then
			leaderTimePosition = leaderTrack.TimePosition
		end
	end

	-- Set syncing attribute
	if player.Character then
		player.Character:SetAttribute("Syncing", sourcePlayer.Name)
	end

	-- Load animation
	local newTrack = AnimatorUtils.getOrCreateTrack(animator, animation)
	if not newTrack then
		newTrack = animator:LoadAnimation(animation)
	end

	if not newTrack then
		warn("[SyncController] Failed to load animation for:", player.Name)
		return false
	end

	-- ✨ SETUP: Priority for stability!
	newTrack.Looped = true
	newTrack.Priority = ANIMATION_PRIORITY  -- 🎯 Set priority untuk pakem!

	-- 🚀 INSTANT CROSSFADE: Play FIRST, then stop old (for followers only!)
	newTrack:Play(FADE_IN, 1.0, speed or 1)  -- Weight 1.0 for full control
	newTrack:AdjustSpeed(speed or 1)

	-- 🎯 Set TimePosition IMMEDIATELY after play
	newTrack.TimePosition = leaderTimePosition

	-- Stop old animations with slight delay (creates smooth crossfade)
	task.delay(0.05, function()
		AnimatorUtils.stopOtherDances(animator, newTrack, loadedAnimations, FADE_OUT)
	end)

	-- Set dance walk speed
	setDanceWalkSpeed(player)

	pcall(function()
		module.updateAllLeaderStatus()
	end)

	return true
end

-- Aliases for compatibility
function module.syncPlayerToAnimationCrossfade(player, sourcePlayer, animation, speed, loadedAnimations)
	return module.syncPlayerToAnimation(player, sourcePlayer, animation, speed, loadedAnimations)
end

function module.syncPlayerToAnimationFast(player, sourcePlayer, animation, speed, loadedAnimations)
	return module.syncPlayerToAnimation(player, sourcePlayer, animation, speed, loadedAnimations)
end

-- ============================================
-- 🚀 INSTANT Sync Player to Source (Followers Only)
-- ============================================
function module.syncPlayerToSource(player, sourcePlayer, loadedAnimations)
	if not waitForCharacterReady(player, 3) then
		warn("[SyncController] Timeout waiting for player character:", player.Name)
		return false
	end

	if not waitForCharacterReady(sourcePlayer, 3) then
		warn("[SyncController] Timeout waiting for source character:", sourcePlayer.Name)
		return false
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator then 
		return false
	end

	local sourceAnimator = AnimatorUtils.getAnimator(sourcePlayer)
	if not sourceAnimator then 
		return false
	end

	local sourceTrack = AnimatorUtils.getPlayingDanceTrack(sourceAnimator, loadedAnimations)

	-- Set syncing attribute
	player.Character:SetAttribute("Syncing", sourcePlayer.Name)

	-- If source has no animation, stop
	if not sourceTrack then
		AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)
		restoreOriginalWalkSpeed(player)

		pcall(function()
			module.updateAllLeaderStatus()
		end)
		return false
	end

	-- Load animation
	local newTrack = AnimatorUtils.getOrCreateTrack(animator, sourceTrack.Animation)
	if not newTrack then
		newTrack = animator:LoadAnimation(sourceTrack.Animation)
	end

	if not newTrack then
		warn("[SyncController] Failed to load animation for:", player.Name)
		return false
	end

	-- ✨ SETUP: Priority for stability!
	newTrack.Looped = true
	newTrack.Priority = ANIMATION_PRIORITY  -- 🎯 Set priority untuk pakem!

	-- 🚀 INSTANT CROSSFADE: Play FIRST with leader's TimePosition
	newTrack:Play(FADE_IN, 1.0, sourceTrack.Speed or 1)  -- Weight 1.0 for full control
	newTrack:AdjustSpeed(sourceTrack.Speed or 1)

	-- 🎯 CRITICAL: Set TimePosition IMMEDIATELY after play
	newTrack.TimePosition = sourceTrack.TimePosition

	-- Stop old animations with delay (smooth crossfade)
	task.delay(0.05, function()
		AnimatorUtils.stopOtherDances(animator, newTrack, loadedAnimations, FADE_OUT)
	end)

	-- Set dance walk speed
	setDanceWalkSpeed(player)

	pcall(function()
		module.updateAllLeaderStatus()
	end)

	return true
end

-- ============================================
-- Reset Chain Time Position
-- ============================================
function module.resetChainTimePosition(sourcePlayer, loadedAnimations)
	local sourceAnimator = AnimatorUtils.getAnimator(sourcePlayer)
	if not sourceAnimator then return end

	local sourceTrack = AnimatorUtils.getPlayingDanceTrack(sourceAnimator, loadedAnimations)
	if not sourceTrack then return end

	sourceTrack.TimePosition = 0

	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			local success, syncSource = pcall(function()
				return module.getSyncSource(p)
			end)

			if success and syncSource == sourcePlayer then
				local a = AnimatorUtils.getAnimator(p)
				if a then
					local t = AnimatorUtils.getPlayingDanceTrack(a, loadedAnimations)
					if t then 
						t.TimePosition = 0 
					end
				end
			end
		end
	end
end

-- ============================================
-- Unsync Player
-- ============================================
function module.unsyncPlayer(player, loadedAnimations)
	local animator = AnimatorUtils.getAnimator(player)
	if animator then
		pcall(function()
			AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)
		end)
		task.wait(FADE_OUT)
	end

	restoreOriginalWalkSpeed(player)

	if player.Character then
		player.Character:SetAttribute("Syncing", nil)
	end

	-- Unsync all followers
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherSyncTarget = otherPlayer.Character:GetAttribute("Syncing")
			if otherSyncTarget == player.Name then
				local oa = AnimatorUtils.getAnimator(otherPlayer)
				if oa then 
					pcall(function()
						AnimatorUtils.stopAllDances(oa, loadedAnimations, FADE_OUT)
					end)
				end

				restoreOriginalWalkSpeed(otherPlayer)
				otherPlayer.Character:SetAttribute("Syncing", nil)
			end
		end
	end

	pcall(function()
		module.updateAllLeaderStatus()
	end)
end

-- ============================================
-- Unsync All Followers of Leader
-- ============================================
function module.unsyncAllFollowersOfLeader(leaderPlayer, loadedAnimations)
	if not leaderPlayer then return 0 end

	local leaderName = leaderPlayer.Name
	local unsyncedCount = 0

	for _, followerPlayer in ipairs(Players:GetPlayers()) do
		if followerPlayer ~= leaderPlayer and followerPlayer.Character then
			local syncTarget = followerPlayer.Character:GetAttribute("Syncing")

			if syncTarget then
				local success, ultimateLeader = pcall(function()
					return module.getSyncSource(followerPlayer)
				end)

				if success and ultimateLeader == leaderPlayer then
					local animator = AnimatorUtils.getAnimator(followerPlayer)
					if animator then
						pcall(function()
							AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)
						end)
					end

					restoreOriginalWalkSpeed(followerPlayer)
					followerPlayer.Character:SetAttribute("Syncing", nil)
					unsyncedCount = unsyncedCount + 1
				end
			end
		end
	end

	if leaderPlayer.Character then
		leaderPlayer.Character:SetAttribute("IsLeader", nil)
		leaderPlayer.Character:SetAttribute("FollowerCount", nil)
	end

	pcall(function()
		module.updateAllLeaderStatus()
	end)

	return unsyncedCount
end

-- ============================================
-- Check circular reference
-- ============================================
function module.wouldCreateCircular(player, targetPlayer)
	if not player or not targetPlayer then
		return false
	end

	if player == targetPlayer then
		return true
	end

	if targetPlayer.Character then
		local targetSync = targetPlayer.Character:GetAttribute("Syncing")
		if targetSync == player.Name then
			return true
		end
	end

	local success, ultimateLeader = pcall(function()
		return module.getSyncSource(targetPlayer)
	end)

	if success and ultimateLeader == player then
		return true
	end

	if player.Character then
		local playerSync = player.Character:GetAttribute("Syncing")
		if playerSync and playerSync ~= "" then
			local playerLeader = module.getSyncSource(player)
			if playerLeader == targetPlayer then
				return true
			end
		end
	end

	return false
end

-- ============================================
-- Handle Sync Request
-- ============================================
function module.handleSyncRequest(player, target, condition, loadedAnimations)
	local targetPlayer = target and Players:FindFirstChild(target.Name)
	if not targetPlayer then 
		warn("[SyncController] Target player not found:", target and target.Name or "nil")
		return 
	end

	if not waitForCharacterReady(player, 3) then
		warn("[SyncController] Player not ready for sync:", player.Name)
		return
	end

	if not waitForCharacterReady(targetPlayer, 3) then
		warn("[SyncController] Target player not ready for sync:", targetPlayer.Name)
		return
	end

	if condition and module.isLeader(player) then
		if module.isFollowingPlayer(targetPlayer, player) then
			warn("[SyncController] Leader cannot sync to their own follower:", player.Name, "->", targetPlayer.Name)
			syncNotificationRE:FireClient(player, "leader_blocked", targetPlayer.Name)
			return
		end
	end

	if condition then
		if module.wouldCreateCircular(player, targetPlayer) then
			warn("[SyncController] Circular sync blocked:", player.Name, "->", targetPlayer.Name)
			syncNotificationRE:FireClient(player, "circular_blocked", targetPlayer.Name)
			return
		end
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator then 
		warn("[SyncController] No animator for player:", player.Name)
		return 
	end

	local currentSyncTarget = player.Character and player.Character:GetAttribute("Syncing")

	if condition then
		if currentSyncTarget == targetPlayer.Name then
			-- Toggle off
			module.unsyncPlayer(player, loadedAnimations)
			syncNotificationRE:FireClient(player, "unsync_success")
		else
			-- Sync to new target
			local success, sourcePlayer = pcall(function()
				return module.getSyncSource(targetPlayer)
			end)

			if not success or not sourcePlayer then
				warn("[SyncController] Failed to get sync source for", targetPlayer.Name)
				return
			end

			local syncSuccess = module.syncPlayerToSource(player, sourcePlayer, loadedAnimations)

			if not syncSuccess then
				warn("[SyncController] Failed to sync", player.Name, "to", sourcePlayer.Name)
				return
			end

			syncNotificationRE:FireClient(player, "sync_success", sourcePlayer.Name)

			-- Sync all followers
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local otherSyncTarget = otherPlayer.Character:GetAttribute("Syncing")
					if otherSyncTarget == player.Name then
						pcall(function()
							module.syncPlayerToSource(otherPlayer, sourcePlayer, loadedAnimations)
						end)
					end
				end
			end
		end
	else
		module.unsyncPlayer(player, loadedAnimations)
		syncNotificationRE:FireClient(player, "unsync_success")
	end

	pcall(function()
		module.updateAllLeaderStatus()
	end)
end

-- ============================================
-- Cleanup
-- ============================================
Players.PlayerRemoving:Connect(function(player)
	originalWalkSpeeds[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		originalWalkSpeeds[player] = nil
	end)
end)

return module
