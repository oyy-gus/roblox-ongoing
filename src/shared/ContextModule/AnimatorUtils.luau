-- AnimatorUtils.lua — PURE: No Priority Logic, Let Roblox Handle It

local module = {}

-- 🧠 Simple cache with weak keys (auto-cleanup by Lua GC)
local trackCache = setmetatable({}, { __mode = "k" })

-- Reference to AnimationPreloader (set by EmoteHandler)
module.AnimationPreloader = nil

-- ============================================
-- Animation Set (for O(1) lookup)
-- ============================================
local function animationSetFrom(loadedAnimations)
	if not loadedAnimations then return nil end
	if loadedAnimations.__asSet then return loadedAnimations.__asSet end

	local set = setmetatable({}, { __mode = "k" })
	for _, animObj in pairs(loadedAnimations) do
		if typeof(animObj) == "Instance" and animObj:IsA("Animation") then
			set[animObj] = true
		end
	end

	loadedAnimations.__asSet = set
	return set
end

-- ============================================
-- Check if track is a dance track
-- ============================================
local function isDanceTrack(track, loadedAnimations)
	if not track or not loadedAnimations then return false end
	if not track.Animation then return false end

	local asSet = animationSetFrom(loadedAnimations)
	if asSet and asSet[track.Animation] then
		return true
	end

	if track.Name and loadedAnimations[track.Name] then
		return true
	end

	return false
end

-- ============================================
-- Character Readiness Check
-- ============================================
function module.isCharacterReady(player)
	if not player or not player.Parent then 
		return false 
	end

	if not player.Character or not player.Character.Parent then 
		return false 
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.Parent then 
		return false 
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator or not animator.Parent then 
		return false 
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp.Parent then 
		return false 
	end

	return true
end

function module.getAnimator(player)
	if not module.isCharacterReady(player) then 
		return nil 
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid:FindFirstChildOfClass("Animator")
end

-- ============================================
-- 🎯 PURE: Get or Create Animation Track
-- ============================================
function module.getOrCreateTrack(animator, animation)
	if not animator or not animation then return nil end

	-- Validate animator hierarchy
	if not animator.Parent or not animator.Parent.Parent then
		return nil
	end

	-- ✅ Try preloaded track first (CLIENT-SIDE ONLY)
	if module.AnimationPreloader then
		local preloadedTrack = module.AnimationPreloader.getPreloadedTrack(animation)
		if preloadedTrack then
			-- Validate preloaded track
			local isValid = pcall(function()
				return preloadedTrack.IsPlaying, preloadedTrack.Animation
			end)

			if isValid and preloadedTrack.Parent == animator then
				return preloadedTrack
			else
				-- Preloaded track is invalid, clear it
				if module.AnimationPreloader then
					module.AnimationPreloader.invalidateTrack(animation)
				end
			end
		end
	end

	-- Fallback to cache system
	local perAnimator = trackCache[animator]
	if not perAnimator then
		perAnimator = setmetatable({}, { __mode = "k" })
		trackCache[animator] = perAnimator
	end

	local track = perAnimator[animation]

	-- Validate cached track
	if track then
		local isValid = pcall(function()
			if not track.Parent or track.Parent ~= animator then
				return false
			end
			return track.IsPlaying, track.Animation
		end)

		if not isValid then
			perAnimator[animation] = nil
			track = nil
		end
	end

	-- Create new track if needed
	if not track then
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		if not ok or not loaded then 
			return nil 
		end

		-- ✨ NO PRIORITY SETTING - Let Roblox handle it!

		perAnimator[animation] = loaded
		track = loaded
	end

	return track
end

-- ============================================
-- Get Currently Playing Dance Track
-- ============================================
function module.getPlayingDanceTrack(animator, loadedAnimations)
	if not animator or not animator.Parent then return nil end

	local tracks
	local success = pcall(function()
		tracks = animator:GetPlayingAnimationTracks()
	end)

	if not success or not tracks then return nil end

	for _, t in ipairs(tracks) do
		if isDanceTrack(t, loadedAnimations) then
			-- Try to find name from map
			local hit = nil
			for name, animObj in pairs(loadedAnimations or {}) do
				if typeof(animObj) == "Instance" and t.Animation == animObj then
					hit = name
					break
				end
			end
			return t, (hit or t.Name)
		end
	end

	return nil
end

-- ============================================
-- Stop All Dance Tracks
-- ============================================
function module.stopAllDances(animator, loadedAnimations, fadeOut)
	if not animator or not animator.Parent then return end
	fadeOut = (fadeOut ~= nil) and fadeOut or 0.06

	local tracks
	local success = pcall(function()
		tracks = animator:GetPlayingAnimationTracks()
	end)

	if not success or not tracks then return end

	for _, t in ipairs(tracks) do
		if isDanceTrack(t, loadedAnimations) then
			pcall(function() t:Stop(fadeOut) end)
		end
	end
end

-- ============================================
-- Stop all dances EXCEPT the specified track
-- ============================================
function module.stopOtherDances(animator, excludeTrack, loadedAnimations, fadeOut)
	if not animator or not animator.Parent then return end
	fadeOut = (fadeOut ~= nil) and fadeOut or 0.06

	local tracks
	local success = pcall(function()
		tracks = animator:GetPlayingAnimationTracks()
	end)

	if not success or not tracks then return end

	for _, t in ipairs(tracks) do
		if t ~= excludeTrack and isDanceTrack(t, loadedAnimations) then
			pcall(function() t:Stop(fadeOut) end)
		end
	end
end

-- ============================================
-- Clear Cache (call on character death)
-- ============================================
function module.clearCacheForPlayer(player)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	-- Clear this animator's cache
	trackCache[animator] = nil
end

return module
