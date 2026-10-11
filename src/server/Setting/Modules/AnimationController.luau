-- AnimationController.lua — PURE DANCESCRIPT (Original Smooth) + Instant Follower Sync
--
-- 🎯 PRIORITY SETTINGS:
-- AnimationPriority.Action = Stable priority that won't conflict with:
--   • Idle animations
--   • Walk/Run animations  
--   • Jump animations
--   • Default character animations
--
-- This ensures dance animations stay "pakem" (solid/stable) without interference!
--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatorUtils = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("AnimatorUtils"))
local SyncController = require(script.Parent.SyncController)

local module = {}

-- ============================================
-- CONFIG
-- ============================================
local FADE_IN = 0.5
local FADE_OUT = 0.5
local DANCE_WALK_SPEED = 16

-- 🎯 ANIMATION PRIORITY (For stability)
local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4  -- Action = stable, won't conflict with movement

-- ============================================
-- ANTI-SPAM
-- ============================================
local processingRequests = {}
local lastRequestTime = {}
local MIN_REQUEST_INTERVAL = 0.15

-- Track original walk speeds
local originalWalkSpeeds = {}

local function canProcessRequest(player)
	if processingRequests[player] then
		return false, "Already processing a request"
	end

	local lastTime = lastRequestTime[player] or 0
	local currentTime = tick()

	if (currentTime - lastTime) < MIN_REQUEST_INTERVAL then
		return false, "Too fast! Wait " .. string.format("%.2f", MIN_REQUEST_INTERVAL - (currentTime - lastTime)) .. "s"
	end

	return true
end

local function startProcessing(player)
	processingRequests[player] = true
	lastRequestTime[player] = tick()
end

local function endProcessing(player)
	processingRequests[player] = false
end

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
-- 🎯 ORIGINAL SMOOTH PLAYBACK (Like Before)
-- ============================================
function module.executeAnimation(player, animation, shouldPlay, speed, loadedAnimations)
	-- Anti-spam check
	local canProcess, reason = canProcessRequest(player)
	if not canProcess then
		warn("[AnimController] Request blocked for", player.Name, "-", reason)
		return "rate_limited"
	end

	startProcessing(player)

	-- Validate animator
	local animator = AnimatorUtils.getAnimator(player)
	if not animator or not animator.Parent or not animator.Parent.Parent then
		endProcessing(player)
		return "error"
	end

	speed = math.clamp(tonumber(speed) or 1, 0, 3)
	local character = player.Character

	-- Auto-unsync
	if character then
		local syncTarget = character:GetAttribute("Syncing")
		if syncTarget and syncTarget ~= "" then
			character:SetAttribute("Syncing", nil)
			AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)
			restoreOriginalWalkSpeed(player)
			task.wait(FADE_OUT)
			SyncController.updateAllLeaderStatus()
		end
	end

	-- === STOP ===
	if not shouldPlay then
		AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)

		if character then 
			character:SetAttribute("Syncing", nil) 
		end

		restoreOriginalWalkSpeed(player)
		SyncController.stopAllFollowers(player, loadedAnimations)

		endProcessing(player)
		return "stopped"
	end

	-- === TOGGLE LOGIC ===
	local currentTrack, currentName = AnimatorUtils.getPlayingDanceTrack(animator, loadedAnimations)
	local animationName = animation and animation.Name or nil

	if currentTrack and currentName == animationName then
		local isActuallyPlaying = currentTrack.IsPlaying and currentTrack.WeightCurrent > 0.1

		if isActuallyPlaying then
			-- TOGGLE OFF
			AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)

			if character then 
				character:SetAttribute("Syncing", nil) 
			end

			restoreOriginalWalkSpeed(player)
			SyncController.stopAllFollowers(player, loadedAnimations)

			endProcessing(player)
			return "stopped"
		end
	end

	-- Clear sync
	if character then 
		character:SetAttribute("Syncing", nil) 
	end

	-- ============================================
	-- 🎯 ORIGINAL SMOOTH METHOD (Stop → Play)
	-- ============================================

	-- Stop old animation with fade
	AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)

	-- Load new animation
	local animTrack = AnimatorUtils.getOrCreateTrack(animator, animation)
	if not animTrack then
		animTrack = animator:LoadAnimation(animation)
	end

	if not animTrack then
		warn("[AnimController] Failed to load animation for", player.Name)
		endProcessing(player)
		return "error"
	end

	-- ✨ SETUP: Priority for stability!
	animTrack.Looped = true
	animTrack.Priority = ANIMATION_PRIORITY  -- 🎯 Set priority untuk pakem!

	-- ✨ PLAY with proper weight
	animTrack:Play(FADE_IN, 1.0, speed)  -- Weight 1.0 for full control
	animTrack:AdjustSpeed(speed)

	-- Set dance walk speed
	setDanceWalkSpeed(player)

	-- ============================================
	-- 🚀 INSTANT FOLLOWER SYNC (No delay!)
	-- ============================================
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:GetAttribute("Syncing") == player.Name then
			pcall(function()
				SyncController.syncPlayerToAnimation(p, player, animation, speed, loadedAnimations)
			end)
		end
	end

	endProcessing(player)
	return "playing"
end

-- ============================================
-- Speed adjustment
-- ============================================
function module.adjustAnimationSpeed(player, speed, loadedAnimations)
	local character = player.Character
	if character and character:GetAttribute("Syncing") then 
		return "syncing"
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator then return "error" end

	speed = math.clamp(tonumber(speed) or 1, 0, 3)

	local track = AnimatorUtils.getPlayingDanceTrack(animator, loadedAnimations)
	if track then
		track:AdjustSpeed(speed)

		-- Update followers
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:GetAttribute("Syncing") == player.Name then
				local sa = AnimatorUtils.getAnimator(p)
				if sa then
					local st = AnimatorUtils.getPlayingDanceTrack(sa, loadedAnimations)
					if st then 
						st:AdjustSpeed(speed) 
					end
				end
			end
		end

		return "speed_changed"
	end

	return "error"
end

-- ============================================
-- Cleanup
-- ============================================
Players.PlayerRemoving:Connect(function(player)
	processingRequests[player] = nil
	lastRequestTime[player] = nil
	originalWalkSpeeds[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		originalWalkSpeeds[player] = nil
	end)
end)

return module
