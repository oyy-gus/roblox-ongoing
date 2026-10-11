-- ====================================
-- MUSIC PLAYLIST BRIDGE (IMPROVED)
-- Place in: ServerStorage > Modules(Folder) > MusicPlaylistBridge(ModuleScript)
-- ====================================
-- Changes:
--   ✅ tick() → workspace:GetServerTimeNow()

local MusicPlaylistBridge = {}

local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local API_URL        = "https://oyy-gus.github.io/api/v2/roblox/music/playlist.json"
local DEFAULT_SAMPUL = "rbxassetid://YOUR_LOGO_ASSET_ID"
local MAX_RETRIES    = 3
local RETRY_DELAY    = 3

local isLoaded   = false
local isLoading  = false
local loadedList = {}
local callbacks  = {}

local function notifyCallbacks(list)
	for _, cb in ipairs(callbacks) do
		task.spawn(cb, list)
	end
	callbacks = {}
end

local function doFetch()
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			local response = HttpService:GetAsync(API_URL, true)
			local decoded  = HttpService:JSONDecode(response)
			local list = {}
			if decoded and decoded.dj then
				for _, song in ipairs(decoded.dj) do
					if song.sound_id and song.title then
						table.insert(list, {
							id     = tostring(song.sound_id),
							judul  = song.title,
							sampul = DEFAULT_SAMPUL,
						})
					end
				end
			end
			return list
		end)
		if ok and result and #result > 0 then
			print(string.format("[MusicPlaylistBridge] Berhasil fetch: %d lagu (percobaan %d)", #result, attempt))
			return result
		else
			warn(string.format("[MusicPlaylistBridge] Gagal fetch percobaan %d/%d: %s", attempt, MAX_RETRIES, tostring(result)))
			if attempt < MAX_RETRIES then task.wait(RETRY_DELAY) end
		end
	end
	warn("[MusicPlaylistBridge] Semua percobaan gagal!")
	return {}
end

function MusicPlaylistBridge:FetchAsync()
	if isLoaded then return loadedList end
	if isLoading then
		local done = false
		self:OnReady(function(list) loadedList = list; done = true end)
		local t = workspace:GetServerTimeNow()
		while not done and (workspace:GetServerTimeNow() - t) < 30 do task.wait(0.1) end
		return loadedList
	end
	isLoading = true
	local list = doFetch()
	loadedList = list
	isLoaded   = true
	isLoading  = false
	local MusicModule = require(ReplicatedStorage.Modules:WaitForChild("MusicModule"))
	MusicModule:SetPlaylist(loadedList)
	notifyCallbacks(loadedList)
	return loadedList
end

function MusicPlaylistBridge:WaitUntilReady(timeout)
	timeout = timeout or 30
	if isLoaded then return loadedList end
	local result = nil
	local done   = false
	self:OnReady(function(list) result = list; done = true end)
	local t = workspace:GetServerTimeNow()
	while not done and (workspace:GetServerTimeNow() - t) < timeout do task.wait(0.1) end
	if not done then warn("[MusicPlaylistBridge] Timeout menunggu playlist!") end
	return result or loadedList or {}
end

function MusicPlaylistBridge:OnReady(callback)
	if isLoaded then task.spawn(callback, loadedList)
	else table.insert(callbacks, callback) end
end

function MusicPlaylistBridge:IsLoaded() return isLoaded end
function MusicPlaylistBridge:GetList()   return loadedList end

return MusicPlaylistBridge
