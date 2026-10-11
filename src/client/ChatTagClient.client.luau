-- ============================================================
-- ChatTagClient (CLIENT)
-- Menampilkan tag di chat menggunakan TextChatService
-- Place in: StarterPlayer > StarterPlayerScripts > ChatTagClient
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- GET REMOTES (Manual)
-- ============================================================
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local GetChatTags = Remotes:WaitForChild("GetChatTags")
local TagsUpdated = Remotes:WaitForChild("TagsUpdated")

-- ============================================================
-- CACHE TAGS
-- ============================================================
local tagsCache = {}

local function fetchTags(userId)
	local success, tags = pcall(function()
		return GetChatTags:InvokeServer(userId)
	end)

	if success and tags then
		tagsCache[userId] = tags
		return tags
	end

	return {}
end

local function getTags(userId)
	if tagsCache[userId] then
		return tagsCache[userId]
	end
	return fetchTags(userId)
end

-- ============================================================
-- LISTEN FOR TAG UPDATES
-- ============================================================
TagsUpdated.OnClientEvent:Connect(function(userId, tags)
	tagsCache[userId] = tags
end)

-- ============================================================
-- HELPER: Color3 to Hex
-- ============================================================
local function color3ToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

-- ============================================================
-- TEXTCHATSERVICE: OnIncomingMessage
-- ============================================================
TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")

	local source = message.TextSource
	if not source then
		return properties
	end

	local userId = source.UserId
	local tags = getTags(userId)

	if tags and #tags > 0 then
		local prefixParts = {}

		for _, tag in ipairs(tags) do
			local hex = color3ToHex(tag.TagColor)
			table.insert(prefixParts,
				string.format(
					'<font color="%s">[%s]</font>',
					hex,
					tag.TagText
				)
			)
		end

		local prefix = table.concat(prefixParts, " ") .. " "
		properties.PrefixText = prefix .. message.PrefixText
	end

	return properties
end

-- ============================================================
-- PRE-FETCH TAGS FOR EXISTING PLAYERS
-- ============================================================
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		fetchTags(player.UserId)
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		fetchTags(player.UserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	tagsCache[player.UserId] = nil
end)

print("✅ [ChatTagClient] Loaded!")
