-- AnimationLoader.lua — SIMPLIFIED: Direct access tanpa duplikasi
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local emotesFolder = ReplicatedStorage:WaitForChild("Emotes")

local module = {}

-- ============================================
-- CONFIG
-- ============================================
local DEBUG_MODE = false

local function debug(...)
	if not DEBUG_MODE then return end
	print("[AnimLoader]", ...)
end

-- ============================================
-- MAIN: Build animation table (NO CLONING!)
-- ============================================
function module.loadAnimations()
	local animations = {}
	local animCount = 0

	debug("📂 Loading animations from Emotes folder...")

	-- Load Dance animations (root level)
	for _, anim in ipairs(emotesFolder:GetChildren()) do
		if anim:IsA("Animation") then
			animations[anim.Name] = anim -- DIRECT reference!
			animCount = animCount + 1
			debug("✅ Dance:", anim.Name)
		end
	end

	-- Load Pose animations (Pose subfolder)
	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if poseFolder then
		for _, anim in ipairs(poseFolder:GetChildren()) do
			if anim:IsA("Animation") then
				animations[anim.Name] = anim -- DIRECT reference!
				animCount = animCount + 1
				debug("✅ Pose:", anim.Name)
			end
		end
	end

	debug(string.format("📦 Total: %d animations loaded", animCount))

	-- ============================================
	-- PRELOAD (Optional - untuk faster load)
	-- ============================================
	if animCount > 0 then
		local startTime = tick()
		local allAnims = {}

		-- Collect all animations
		for _, anim in pairs(animations) do
			table.insert(allAnims, anim)
		end

		-- Preload
		local success = pcall(function()
			ContentProvider:PreloadAsync(allAnims)
		end)

		local loadTime = tick() - startTime

		if success then
			debug(string.format("⚡ Preloaded in %.2fs", loadTime))
		else
			warn("[AnimLoader] Preload failed (non-critical)")
		end
	end

	return animations
end

-- ============================================
-- HELPER: Get animation by name
-- ============================================
function module.getAnimation(animName)
	-- Direct lookup from Emotes folder
	local anim = emotesFolder:FindFirstChild(animName)
	if anim and anim:IsA("Animation") then
		return anim
	end

	-- Check Pose folder
	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if poseFolder then
		anim = poseFolder:FindFirstChild(animName)
		if anim and anim:IsA("Animation") then
			return anim
		end
	end

	return nil
end

-- ============================================
-- HELPER: Get category
-- ============================================
function module.getAnimationCategory(animName)
	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if poseFolder and poseFolder:FindFirstChild(animName) then
		return "Pose"
	end
	return "Dance"
end

-- ============================================
-- HELPER: Get all by category
-- ============================================
function module.getAnimationsByCategory(category)
	local results = {}

	if category == "Dance" then
		for _, anim in ipairs(emotesFolder:GetChildren()) do
			if anim:IsA("Animation") then
				table.insert(results, anim)
			end
		end
	elseif category == "Pose" then
		local poseFolder = emotesFolder:FindFirstChild("Pose")
		if poseFolder then
			for _, anim in ipairs(poseFolder:GetChildren()) do
				if anim:IsA("Animation") then
					table.insert(results, anim)
				end
			end
		end
	end

	return results
end

return module
