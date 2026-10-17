local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatorUtils = require(ReplicatedStorage:WaitForChild("ContextModule"):WaitForChild("AnimatorUtils"))
local SyncController = require(script.Parent.SyncController)

local module = {}

local FADE_IN = 0.5
local FADE_OUT = 0.5
local DANCE_WALK_SPEED = 16

local ANIMATION_PRIORITY = Enum.AnimationPriority.Action4

local processingRequests = {}
local lastRequestTime = {}
local MIN_REQUEST_INTERVAL = 0.15

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

function module.executeAnimation(player, animation, shouldPlay, speed, loadedAnimations)

	local canProcess, reason = canProcessRequest(player)
	if not canProcess then
		warn("[AnimController] Request blocked for", player.Name, "-", reason)
		return "rate_limited"
	end

	startProcessing(player)

	if typeof(animation) == "string" and loadedAnimations then
		animation = loadedAnimations[animation]
	elseif typeof(animation) == "table" and animation.Name and loadedAnimations then
		animation = loadedAnimations[animation.Name]
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator or not animator.Parent or not animator.Parent.Parent then
		endProcessing(player)
		return "error"
	end

	speed = math.clamp(tonumber(speed) or 1, 0, 3)
	local character = player.Character

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

	local currentTrack, currentName = AnimatorUtils.getPlayingDanceTrack(animator, loadedAnimations)
	local animationName = animation and animation.Name or nil

	if currentTrack and currentName == animationName then
		local isActuallyPlaying = currentTrack.IsPlaying and currentTrack.WeightCurrent > 0.1

		if isActuallyPlaying then

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

	if character then
		character:SetAttribute("Syncing", nil)
	end

	AnimatorUtils.stopAllDances(animator, loadedAnimations, FADE_OUT)

	local animTrack = AnimatorUtils.getOrCreateTrack(animator, animation)
	if not animTrack then
		animTrack = animator:LoadAnimation(animation)
	end

	if not animTrack then
		warn("[AnimController] Gagal memuat animasi untuk", player.Name)
		endProcessing(player)
		return "error"
	end

	animTrack.Looped = true
	animTrack.Priority = ANIMATION_PRIORITY

	animTrack:Play(FADE_IN, 1.0, speed)
	animTrack:AdjustSpeed(speed)

	setDanceWalkSpeed(player)

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
