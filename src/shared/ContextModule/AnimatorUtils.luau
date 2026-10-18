local module = {}

local trackCache = setmetatable({}, { __mode = "k" })

module.AnimationPreloader = nil

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

function module.getOrCreateTrack(animator, animation)
	if not animator or not animation then return nil end

	if not animator.Parent or not animator.Parent.Parent then
		return nil
	end

	if module.AnimationPreloader then
		local preloadedTrack = module.AnimationPreloader.getPreloadedTrack(animation)
		if preloadedTrack then

			local isValid = pcall(function()
				return preloadedTrack.IsPlaying, preloadedTrack.Animation
			end)

			if isValid and preloadedTrack.Parent == animator then
				return preloadedTrack
			else
				if module.AnimationPreloader and typeof(module.AnimationPreloader.invalidateTrack) == "function" then
					pcall(function()
						module.AnimationPreloader.invalidateTrack(animation)
					end)
				end
			end
		end
	end

	local perAnimator = trackCache[animator]
	if not perAnimator then
		perAnimator = setmetatable({}, { __mode = "k" })
		trackCache[animator] = perAnimator
	end

	local track = perAnimator[animation]

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

	if not track then
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)

		if not ok or not loaded then
			return nil
		end

		perAnimator[animation] = loaded
		track = loaded
	end

	return track
end

function module.getPlayingDanceTrack(animator, loadedAnimations)
	if not animator or not animator.Parent then return nil end

	local tracks
	local success = pcall(function()
		tracks = animator:GetPlayingAnimationTracks()
	end)

	if not success or not tracks then return nil end

	for _, t in ipairs(tracks) do
		if isDanceTrack(t, loadedAnimations) then

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

function module.clearCacheForPlayer(player)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	trackCache[animator] = nil
end

return module
