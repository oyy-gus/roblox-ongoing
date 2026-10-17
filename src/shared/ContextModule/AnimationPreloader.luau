local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local module = {}

local CONFIG = {
	DEBUG_ENABLED = false,
	PRELOAD_ON_SPAWN = false,
	PRELOAD_DELAY = 2,
	BATCH_SIZE = 5,
	BATCH_DELAY = 0.1
}

local preloadedTracks = {}
local isPreloaded = false

local function debug(...)
	if CONFIG.DEBUG_ENABLED then
		print("[AnimPreloader]", ...)
	end
end

local function getAnimator()
	if not player.Character then return nil end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		warn("[AnimPreloader] No Animator found!")
		return nil
	end

	return animator
end

function module.preloadAnimations(animationFolder)
	if isPreloaded then
		debug("Already preloaded, skipping...")
		return
	end

	local animator = getAnimator()
	if not animator then
		warn("[AnimPreloader] Tidak dapat pra-muat - tidak ada animator")
		return
	end

	debug("🔄 Starting preload...")

	local animations = {}

	for _, anim in ipairs(animationFolder:GetDescendants()) do
		if anim:IsA("Animation") then
			table.insert(animations, anim)
		end
	end

	debug("Found", #animations, "animations to preload")

	local startTime = tick()
	local successCount = 0
	local failCount = 0

	for i = 1, #animations, CONFIG.BATCH_SIZE do
		local batch = {}

		for j = i, math.min(i + CONFIG.BATCH_SIZE - 1, #animations) do
			table.insert(batch, animations[j])
		end

		for _, anim in ipairs(batch) do
			local success, track = pcall(function()
				return animator:LoadAnimation(anim)
			end)

			if success and track then
				preloadedTracks[anim] = track
				successCount = successCount + 1
				debug("✅", anim.Name)
			else
				failCount = failCount + 1
				warn("[AnimPreloader] Gagal pra-muat:", anim.Name)
			end
		end

		if i + CONFIG.BATCH_SIZE <= #animations then
			task.wait(CONFIG.BATCH_DELAY)
		end
	end

	local loadTime = tick() - startTime
	isPreloaded = true

	debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	debug("✅ PRELOAD COMPLETE")
	debug(string.format("⏱️  Time: %.2fs", loadTime))
	debug(string.format("✅ Success: %d", successCount))
	debug(string.format("❌ Failed: %d", failCount))
	debug("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	return true
end

function module.getPreloadedTrack(animation)
	return preloadedTracks[animation]
end

function module.isPreloaded()
	return isPreloaded
end

function module.clearCache()
	debug("🧹 Clearing preload cache...")

	for _, track in pairs(preloadedTracks) do
		pcall(function()
			track:Stop(0)
		end)
	end

	preloadedTracks = {}
	isPreloaded = false

	debug("✅ Cache cleared")
end

if CONFIG.PRELOAD_ON_SPAWN then
	local function setupPreload()
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		local humanoid = player.Character:WaitForChild("Humanoid")
		player.Character:WaitForChild("HumanoidRootPart")

		task.wait(0.5)

		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			warn("[AnimPreloader] No Animator found!")
			return
		end

		task.wait(CONFIG.PRELOAD_DELAY)

		local animFolder = ReplicatedStorage:WaitForChild("StoredAnimations")
		local emotesFolder = ReplicatedStorage:WaitForChild("Emotes")

		module.preloadAnimations(emotesFolder)
	end

	task.spawn(setupPreload)

	player.CharacterAdded:Connect(function()
		module.clearCache()
		task.wait(1)
		setupPreload()
	end)
end

return module
