-- Place in: ReplicatedStorage > Modules > FriendConfig (ModuleScript)
-- ========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendConfig = {}

-- ========================================
-- WARNA FRIEND BUTTON
-- ========================================
FriendConfig.Colors = {
	Add         = Color3.fromRGB(59, 130, 246),
	AddHover    = Color3.fromRGB(79, 150, 255),
	Pending     = Color3.fromRGB(234, 179, 8),
	PendingHover = Color3.fromRGB(250, 200, 50),
	Accept      = Color3.fromRGB(34, 197, 94),
	AcceptHover = Color3.fromRGB(50, 220, 110),
	Already     = Color3.fromRGB(55, 55, 60),
	AlreadyHover = Color3.fromRGB(65, 65, 70),
}

-- ========================================
-- STATUS CONFIG
-- ========================================
FriendConfig.StatusConfig = {
	[Enum.FriendStatus.Unknown] = {
		text = "👤 Tambah Teman",
		color = FriendConfig.Colors.Add,
		hoverColor = FriendConfig.Colors.AddHover,
		active = true,
		action = "add"
	},
	[Enum.FriendStatus.NotFriend] = {
		text = "👤 Tambah Teman",
		color = FriendConfig.Colors.Add,
		hoverColor = FriendConfig.Colors.AddHover,
		active = true,
		action = "add"
	},
	[Enum.FriendStatus.Friend] = {
		text = "✓ Sudah Berteman",
		color = FriendConfig.Colors.Already,
		hoverColor = FriendConfig.Colors.AlreadyHover,
		active = false,
		action = "none"
	},
	[Enum.FriendStatus.FriendRequestSent] = {
		text = "⏳ Permintaan Terkirim",
		color = FriendConfig.Colors.Pending,
		hoverColor = FriendConfig.Colors.PendingHover,
		active = true,
		action = "revoke"
	},
	[Enum.FriendStatus.FriendRequestReceived] = {
		text = "✉️ Terima Permintaan",
		color = FriendConfig.Colors.Accept,
		hoverColor = FriendConfig.Colors.AcceptHover,
		active = true,
		action = "accept"
	},
}

-- ========================================
-- POLLING SETTINGS
-- ========================================
FriendConfig.Polling = {
	NormalInterval = 3,
	IntensiveInterval = 0.5,
	IntensiveDuration = 20,
}

-- ========================================
-- EMOJI INDICATORS
-- ========================================
FriendConfig.Indicators = {
	[Enum.FriendStatus.Friend] = " 👥",
	[Enum.FriendStatus.FriendRequestSent] = " ⏳",
	[Enum.FriendStatus.FriendRequestReceived] = " ✉️",
}

-- ========================================
-- CACHE
-- ========================================
local countCache = {}
local CACHE_DURATION = 60

-- ========================================
-- FORMAT NUMBER
-- ========================================
function FriendConfig.FormatNumber(num)
	if not num or num == 0 then
		return "0"
	elseif num >= 1000000 then
		return string.format("%.1fM", num / 1000000):gsub("%.0M", "M")
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000):gsub("%.0K", "K")
	else
		return tostring(num)
	end
end

-- ========================================
-- ★ GET FRIEND COUNT (Client-side via Pages)
-- ========================================
function FriendConfig.GetFriendCount(userId)
	if not userId then return 0 end

	local cacheKey = "friends_" .. tostring(userId)
	local cached = countCache[cacheKey]
	if cached and (tick() - cached.time) < CACHE_DURATION then
		return cached.count
	end

	local count = 0
	local success, err = pcall(function()
		local friendPages = Players:GetFriendsAsync(userId)
		while true do
			local currentPage = friendPages:GetCurrentPage()
			count = count + #currentPage
			if friendPages.IsFinished then break end
			friendPages:AdvanceToNextPageAsync()
		end
	end)

	if success then
		countCache[cacheKey] = { count = count, time = tick() }
		return count
	else
		warn("[FriendConfig] Gagal mendapatkan jumlah teman:", err)
		return cached and cached.count or 0
	end
end

-- ========================================
-- ★ GET FOLLOWER COUNT (Via Server - FIXED)
-- ========================================
function FriendConfig.GetFollowerCount(userId)
	if not userId then return 0 end

	-- Check local cache first
	local cacheKey = "followers_" .. tostring(userId)
	local cached = countCache[cacheKey]
	if cached and (tick() - cached.time) < CACHE_DURATION then
		return cached.count
	end

	-- Wait for remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if not remotes then 
		warn("[FriendConfig] Remotes folder tidak ditemukan")
		return cached and cached.count or 0 
	end

	local getFollowerCount = remotes:WaitForChild("GetFollowerCount", 5)
	if not getFollowerCount then 
		warn("[FriendConfig] GetFollowerCount remote tidak ditemukan")
		return cached and cached.count or 0 
	end

	-- Request from server
	local success, result = pcall(function()
		return getFollowerCount:InvokeServer(userId)
	end)

	if success and result then
		-- Cache locally
		countCache[cacheKey] = { count = result, time = tick() }
		return result
	else
		warn("[FriendConfig] Gagal mendapatkan follower count:", result)
		return cached and cached.count or 0
	end
end

-- ========================================
-- ★ GET FOLLOWING COUNT (Via Server)
-- ========================================
function FriendConfig.GetFollowingCount(userId)
	if not userId then return 0 end

	local cacheKey = "following_" .. tostring(userId)
	local cached = countCache[cacheKey]
	if cached and (tick() - cached.time) < CACHE_DURATION then
		return cached.count
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
	if not remotes then return cached and cached.count or 0 end

	local getFollowingCount = remotes:WaitForChild("GetFollowingCount", 5)
	if not getFollowingCount then return cached and cached.count or 0 end

	local success, result = pcall(function()
		return getFollowingCount:InvokeServer(userId)
	end)

	if success and result then
		countCache[cacheKey] = { count = result, time = tick() }
		return result
	else
		return cached and cached.count or 0
	end
end

-- ========================================
-- ★ GET ALL SOCIAL COUNTS (Async)
-- ========================================
function FriendConfig.GetSocialCountsAsync(userId, callback)
	if not callback then return end

	task.spawn(function()
		local friends = 0
		local followers = 0
		local following = 0

		-- Get friend count (client-side)
		pcall(function()
			friends = FriendConfig.GetFriendCount(userId)
		end)

		-- Get follower count (server-side)
		pcall(function()
			followers = FriendConfig.GetFollowerCount(userId)
		end)

		-- Get following count (server-side)
		pcall(function()
			following = FriendConfig.GetFollowingCount(userId)
		end)

		callback({
			friends = friends,
			followers = followers,
			following = following,
		})
	end)
end

-- ========================================
-- CLEAR CACHE
-- ========================================
function FriendConfig.ClearCache(userId)
	if userId then
		countCache["friends_" .. tostring(userId)] = nil
		countCache["followers_" .. tostring(userId)] = nil
		countCache["following_" .. tostring(userId)] = nil
	else
		countCache = {}
	end
end

-- ========================================
-- FRIEND TRACKER CLASS
-- ========================================
local FriendTracker = {}
FriendTracker.__index = FriendTracker

function FriendTracker.new()
	local self = setmetatable({}, FriendTracker)
	self.lastKnownStatus = nil
	self.intensivePollingEndTime = 0
	self.pollingThread = nil
	self.isActive = false
	self.targetPlayer = nil
	self.friendButton = nil
	self.nameLabel = nil
	self.onStatusChanged = nil
	return self
end

function FriendTracker:GetLocalPlayer()
	return Players.LocalPlayer
end

function FriendTracker:GetFriendStatus(targetPlayer)
	if not targetPlayer or targetPlayer == self:GetLocalPlayer() then
		return Enum.FriendStatus.Unknown
	end

	local success, status = pcall(function()
		return self:GetLocalPlayer():GetFriendStatus(targetPlayer)
	end)

	return success and status or Enum.FriendStatus.Unknown
end

function FriendTracker:GetStatusConfig(status)
	return FriendConfig.StatusConfig[status] or FriendConfig.StatusConfig[Enum.FriendStatus.Unknown]
end

function FriendTracker:GetIndicator(status)
	return FriendConfig.Indicators[status] or ""
end

function FriendTracker:StartIntensivePolling()
	self.intensivePollingEndTime = tick() + FriendConfig.Polling.IntensiveDuration
end

function FriendTracker:IsIntensivePolling()
	return tick() < self.intensivePollingEndTime
end

function FriendTracker:GetPollInterval()
	return self:IsIntensivePolling() 
		and FriendConfig.Polling.IntensiveInterval 
		or FriendConfig.Polling.NormalInterval
end

function FriendTracker:UpdateButton()
	if not self.friendButton or not self.friendButton.Parent then return false end
	if not self.targetPlayer then return false end

	local status = self:GetFriendStatus(self.targetPlayer)
	local config = self:GetStatusConfig(status)
	local statusChanged = (status ~= self.lastKnownStatus)

	if statusChanged then
		self.lastKnownStatus = status

		self.friendButton.Text = config.text
		self.friendButton:SetAttribute("FriendAction", config.action)
		self.friendButton.Active = config.active

		TweenService:Create(self.friendButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			BackgroundColor3 = config.color,
			TextTransparency = config.active and 0 or 0.3
		}):Play()

		self:UpdateNameLabel()

		if self.onStatusChanged then
			self.onStatusChanged(status, config)
		end

		if status == Enum.FriendStatus.Friend then
			self.intensivePollingEndTime = 0
			FriendConfig.ClearCache(self.targetPlayer.UserId)
		end

		return true
	end

	return false
end

function FriendTracker:UpdateNameLabel()
	if not self.nameLabel or not self.nameLabel.Parent then return end
	if not self.targetPlayer then return end

	local indicator = self:GetIndicator(self.lastKnownStatus)
	self.nameLabel.Text = self.targetPlayer.DisplayName .. indicator
end

function FriendTracker:SetNameLabel(label)
	self.nameLabel = label
end

function FriendTracker:SetOnStatusChanged(callback)
	self.onStatusChanged = callback
end

function FriendTracker:StartPolling(button, targetPlayer)
	self:StopPolling()

	self.friendButton = button
	self.targetPlayer = targetPlayer
	self.isActive = true
	self.lastKnownStatus = self:GetFriendStatus(targetPlayer)

	self.pollingThread = task.spawn(function()
		while self.isActive and self.friendButton and self.friendButton.Parent do
			local interval = self:GetPollInterval()
			task.wait(interval)

			if self.isActive and self.targetPlayer then
				self:UpdateButton()
			else
				break
			end
		end
	end)
end

function FriendTracker:StopPolling()
	self.isActive = false

	if self.pollingThread then
		task.cancel(self.pollingThread)
		self.pollingThread = nil
	end

	self.friendButton = nil
	self.targetPlayer = nil
	self.nameLabel = nil
	self.lastKnownStatus = nil
	self.intensivePollingEndTime = 0
end

function FriendTracker:SendFriendRequest(targetPlayer)
	if not targetPlayer then return false end

	local success = pcall(function()
		StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
	end)

	if success then
		self:StartIntensivePolling()
		return true
	end

	-- Fallback
	pcall(function()
		GuiService:InspectPlayerFromUserId(targetPlayer.UserId)
	end)
	self:StartIntensivePolling()
	return false
end

function FriendTracker:RevokeFriendRequest(targetPlayer)
	if not targetPlayer then return false end

	local success = pcall(function()
		StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
	end)

	if success then
		self:StartIntensivePolling()
	end

	return success
end

function FriendTracker:AcceptFriendRequest(targetPlayer)
	if not targetPlayer then return false end

	local success = pcall(function()
		StarterGui:SetCore("PromptSendFriendRequest", targetPlayer)
	end)

	if success then
		self:StartIntensivePolling()
		return true
	end

	return false
end

function FriendTracker:HandleAction(targetPlayer, action)
	if not targetPlayer then return end

	if action == "add" then
		self:SendFriendRequest(targetPlayer)
	elseif action == "revoke" then
		self:RevokeFriendRequest(targetPlayer)
	elseif action == "accept" then
		self:AcceptFriendRequest(targetPlayer)
	end
end

function FriendTracker:GetDisplayNameWithIndicator(targetPlayer)
	if not targetPlayer then return "" end

	local status = self:GetFriendStatus(targetPlayer)
	local indicator = self:GetIndicator(status)

	return targetPlayer.DisplayName .. indicator
end

function FriendTracker:Destroy()
	self:StopPolling()
	self.onStatusChanged = nil
end

-- ========================================
-- EXPORT
-- ========================================
FriendConfig.FriendTracker = FriendTracker

function FriendConfig.GetFriendStatus(targetPlayer)
	local localPlayer = Players.LocalPlayer
	if not targetPlayer or targetPlayer == localPlayer then
		return Enum.FriendStatus.Unknown
	end

	local success, status = pcall(function()
		return localPlayer:GetFriendStatus(targetPlayer)
	end)

	return success and status or Enum.FriendStatus.Unknown
end

function FriendConfig.GetStatusConfig(status)
	return FriendConfig.StatusConfig[status] or FriendConfig.StatusConfig[Enum.FriendStatus.Unknown]
end

function FriendConfig.GetIndicator(status)
	return FriendConfig.Indicators[status] or ""
end

function FriendConfig.GetDisplayNameWithIndicator(targetPlayer)
	if not targetPlayer then return "" end

	local status = FriendConfig.GetFriendStatus(targetPlayer)
	local indicator = FriendConfig.GetIndicator(status)

	return targetPlayer.DisplayName .. indicator
end

function FriendConfig.CreateTracker()
	return FriendTracker.new()
end

return FriendConfig

-- ========================================
-- MENU CONFIG MODULE
