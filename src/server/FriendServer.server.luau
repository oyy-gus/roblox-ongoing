-- ========================================
-- FRIEND SERVER (FIXED - DENGAN ROPROXY)
-- Place in: ServerScriptService > FriendServer (Script)
-- ========================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ========================================
-- CONFIG
-- ========================================
local CONFIG = {
	-- ★ GUNAKAN ROPROXY UNTUK BYPASS ROBLOX RESTRICTION
	PROXY_URL = "https://friends.roproxy.com",
	
	-- Cache duration (detik)
	CACHE_DURATION = 120,
	
	-- Rate limit per player (detik)
	REQUEST_COOLDOWN = 2,
	
	-- Debug mode
	DEBUG = true,
}

-- ========================================
-- SETUP REMOTES
-- ========================================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function createRemote(name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local getFollowerCount = createRemote("GetFollowerCount")
local getFollowingCount = createRemote("GetFollowingCount")
local getSocialCounts = createRemote("GetSocialCounts")
local getFriendCountServer = createRemote("GetFriendCountServer")

-- ========================================
-- CACHE SYSTEM
-- ========================================
local cache = {}

local function getCached(key)
	local cached = cache[key]
	if cached and (tick() - cached.time) < CONFIG.CACHE_DURATION then
		return cached.value, true
	end
	return nil, false
end

local function setCache(key, value)
	cache[key] = {
		value = value,
		time = tick()
	}
end

-- ========================================
-- RATE LIMITING
-- ========================================
local lastRequestTime = {}

local function canRequest(player)
	if not player then return false end
	
	local lastTime = lastRequestTime[player.UserId]
	if lastTime and (tick() - lastTime) < CONFIG.REQUEST_COOLDOWN then
		return false
	end
	lastRequestTime[player.UserId] = tick()
	return true
end

-- ========================================
-- DEBUG HELPER
-- ========================================
local function debugLog(...)
	if CONFIG.DEBUG then
		print("[FriendServer]", ...)
	end
end

local function debugWarn(...)
	if CONFIG.DEBUG then
		warn("[FriendServer]", ...)
	end
end

-- ========================================
-- ★ HTTP REQUEST VIA ROPROXY
-- ========================================
local function makeRequest(endpoint)
	-- Build URL dengan RoProxy

	local url = CONFIG.PROXY_URL .. endpoint
	
	debugLog("📡 Request:", url)
	
	local success, response = pcall(function()
		return HttpService:GetAsync(url, true) -- true = no cache
	end)
	
	if not success then
		debugWarn("❌ HTTP Error:", response)
		return nil, response
	end
	
	local parseSuccess, data = pcall(function()
		return HttpService:JSONDecode(response)
	end)
	
	if not parseSuccess then
		debugWarn("❌ JSON Parse Error:", response)
		return nil, "JSON Parse Error"
	end
	
	return data, nil
end

-- ========================================
-- API FUNCTIONS
-- ========================================
local function fetchFollowerCount(userId)
	local cacheKey = "followers_" .. tostring(userId)
	
	-- Check cache first
	local cached, isValid = getCached(cacheKey)
	if isValid then
		debugLog("📦 Cache hit - Followers:", cached)
		return cached
	end
	
	-- Fetch from API
	local endpoint = "/v1/users/" .. tostring(userId) .. "/followers/count"
	local data, err = makeRequest(endpoint)
	
	if data and data.count then
		debugLog("✅ Followers fetched:", data.count)
		setCache(cacheKey, data.count)
		return data.count
	end
	
	-- Return cached value if available, else 0
	debugWarn("⚠️ Using fallback for followers")
	return cached or 0
end

local function fetchFollowingCount(userId)
	local cacheKey = "following_" .. tostring(userId)
	
	local cached, isValid = getCached(cacheKey)
	if isValid then
		debugLog("📦 Cache hit - Following:", cached)
		return cached
	end
	
	local endpoint = "/v1/users/" .. tostring(userId) .. "/followings/count"
	local data, err = makeRequest(endpoint)
	
	if data and data.count then
		debugLog("✅ Following fetched:", data.count)
		setCache(cacheKey, data.count)
		return data.count
	end
	
	debugWarn("⚠️ Using fallback for following")
	return cached or 0
end

local function fetchFriendCount(userId)
	local cacheKey = "friends_" .. tostring(userId)
	
	local cached, isValid = getCached(cacheKey)
	if isValid then
		debugLog("📦 Cache hit - Friends:", cached)
		return cached
	end
	
	local endpoint = "/v1/users/" .. tostring(userId) .. "/friends/count"
	local data, err = makeRequest(endpoint)
	
	if data and data.count then
		debugLog("✅ Friends fetched:", data.count)
		setCache(cacheKey, data.count)
		return data.count
	end
	
	debugWarn("⚠️ Using fallback for friends")
	return cached or 0
end

-- ========================================
-- REMOTE HANDLERS
-- ========================================
getFollowerCount.OnServerInvoke = function(player, userId)
	-- Validate
	if not userId or type(userId) ~= "number" then
		debugWarn("Invalid userId:", tostring(userId))
		return 0
	end
	
	-- Rate limit check
	if not canRequest(player) then
		local cached = getCached("followers_" .. tostring(userId))
		debugLog("⏳ Rate limited, returning cache:", cached or 0)
		return cached or 0
	end
	
	return fetchFollowerCount(userId)
end

getFollowingCount.OnServerInvoke = function(player, userId)
	if not userId or type(userId) ~= "number" then
		return 0
	end
	
	if not canRequest(player) then
		local cached = getCached("following_" .. tostring(userId))
		return cached or 0
	end
	
	return fetchFollowingCount(userId)
end

getFriendCountServer.OnServerInvoke = function(player, userId)
	if not userId or type(userId) ~= "number" then
		return 0
	end
	
	if not canRequest(player) then
		local cached = getCached("friends_" .. tostring(userId))
		return cached or 0
	end
	
	return fetchFriendCount(userId)
end

getSocialCounts.OnServerInvoke = function(player, userId)
	if not userId or type(userId) ~= "number" then
		return { friends = 0, followers = 0, following = 0 }
	end
	
	if not canRequest(player) then
		return {
			friends = getCached("friends_" .. tostring(userId)) or 0,
			followers = getCached("followers_" .. tostring(userId)) or 0,
			following = getCached("following_" .. tostring(userId)) or 0,
		}
	end
	
	-- Fetch all counts
	return {
		friends = fetchFriendCount(userId),
		followers = fetchFollowerCount(userId),
		following = fetchFollowingCount(userId),
	}
end

-- ========================================
-- CLEANUP
-- ========================================
Players.PlayerRemoving:Connect(function(player)
	lastRequestTime[player.UserId] = nil
end)

-- Periodic cache cleanup (setiap 5 menit)
task.spawn(function()
	while true do
		task.wait(300)
		local now = tick()
		local cleaned = 0
		
		for key, data in pairs(cache) do
			if (now - data.time) > CONFIG.CACHE_DURATION * 2 then
				cache[key] = nil
				cleaned = cleaned + 1
			end
		end
		
		if cleaned > 0 then
			debugLog("🧹 Cache cleaned:", cleaned, "entries")
		end
	end
end)

print("✅ [FriendServer] Loaded!")
print("📡 Using RoProxy:", CONFIG.PROXY_URL)

