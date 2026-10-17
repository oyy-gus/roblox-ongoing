local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local emotesFolder = ReplicatedStorage:WaitForChild("Emotes")

local module = {}

local DEBUG_MODE = false

local function debug(...)
	if not DEBUG_MODE then return end
	print("[AnimLoader]", ...)
end

function module.loadAnimations()
	local animations = {}
	local animCount = 0

	debug("📂 Loading animations from DanceConfig, PoseConfig, and Emotes folder...")

	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if not poseFolder then
		poseFolder = Instance.new("Folder")
		poseFolder.Name = "Pose"
		poseFolder.Parent = emotesFolder
	end

	local danceConfigModule = emotesFolder:FindFirstChild("DanceConfig")
	if danceConfigModule and danceConfigModule:IsA("ModuleScript") then
		local ok, danceList = pcall(require, danceConfigModule)
		if ok and typeof(danceList) == "table" then
			for _, item in ipairs(danceList) do
				local name = item.name or item.Name
				local animId = item.animationId or item.AnimationId or item.id or item.Id
				if name and animId then
					local anim = emotesFolder:FindFirstChild(name)
					if not anim or not anim:IsA("Animation") then
						anim = Instance.new("Animation")
						anim.Name = name
						anim.AnimationId = animId
						anim.Parent = emotesFolder
					else
						anim.AnimationId = animId
					end
					animations[name] = anim
					animCount = animCount + 1
					debug("✅ Dance (Config):", name)
				end
			end
		end
	end

	local poseConfigModule = emotesFolder:FindFirstChild("PoseConfig")
	if poseConfigModule and poseConfigModule:IsA("ModuleScript") then
		local ok, poseList = pcall(require, poseConfigModule)
		if ok and typeof(poseList) == "table" then
			for _, item in ipairs(poseList) do
				local name = item.name or item.Name
				local animId = item.animationId or item.AnimationId or item.id or item.Id
				if name and animId then
					local anim = poseFolder:FindFirstChild(name)
					if not anim or not anim:IsA("Animation") then
						anim = Instance.new("Animation")
						anim.Name = name
						anim.AnimationId = animId
						anim.Parent = poseFolder
					else
						anim.AnimationId = animId
					end
					animations[name] = anim
					animCount = animCount + 1
					debug("✅ Pose (Config):", name)
				end
			end
		end
	end

	for _, anim in ipairs(emotesFolder:GetChildren()) do
		if anim:IsA("Animation") and not animations[anim.Name] then
			animations[anim.Name] = anim
			animCount = animCount + 1
			debug("✅ Dance (Folder):", anim.Name)
		end
	end

	for _, anim in ipairs(poseFolder:GetChildren()) do
		if anim:IsA("Animation") and not animations[anim.Name] then
			animations[anim.Name] = anim
			animCount = animCount + 1
			debug("✅ Pose (Folder):", anim.Name)
		end
	end

	debug(string.format("📦 Total: %d animations loaded", animCount))

	if animCount > 0 then
		local startTime = tick()
		local allAnims = {}

		for _, anim in pairs(animations) do
			table.insert(allAnims, anim)
		end

		local success = pcall(function()
			ContentProvider:PreloadAsync(allAnims)
		end)

		local loadTime = tick() - startTime

		if success then
			debug(string.format("⚡ Preloaded in %.2fs", loadTime))
		else
			warn("[AnimLoader] Pra-muat gagal (non-kritis)")
		end
	end

	return animations
end

function module.getAnimation(animName)

	local anim = emotesFolder:FindFirstChild(animName)
	if anim and anim:IsA("Animation") then
		return anim
	end

	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if poseFolder then
		anim = poseFolder:FindFirstChild(animName)
		if anim and anim:IsA("Animation") then
			return anim
		end
	end

	return nil
end

function module.getAnimationCategory(animName)
	local poseFolder = emotesFolder:FindFirstChild("Pose")
	if poseFolder and poseFolder:FindFirstChild(animName) then
		return "Pose"
	end
	return "Dance"
end

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
