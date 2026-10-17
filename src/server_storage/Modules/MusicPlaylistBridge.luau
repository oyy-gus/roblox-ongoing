local MusicPlaylistBridge = {}

local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local API_URL        = "https://oyy-gus.github.io/api/v2/roblox/music/playlist.json"
local DEFAULT_SAMPUL = "rbxassetid://118306547253139"
local MAX_RETRIES    = 3
local RETRY_DELAY    = 3

local isLoaded        = false
local isLoading       = false
local loadedList      = {}
local loadedPlaylists = {}
local callbacks       = {}

local function notifyCallbacks(list, playlists)
	for _, cb in ipairs(callbacks) do
		task.spawn(cb, list, playlists)
	end
	callbacks = {}
end

local function doFetch()
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			local response = HttpService:GetAsync(API_URL, true)
			local decoded  = HttpService:JSONDecode(response)
			local list = {}
			local playlists = {}

			if decoded and decoded.playlists and type(decoded.playlists) == "table" then
				for _, pl in ipairs(decoded.playlists) do
					local plName = pl.name or "Playlist"
					local plThumb = pl.thumbnail
					if not plThumb or plThumb == "" then
						plThumb = DEFAULT_SAMPUL
					end

					local plTracks = {}
					if pl.tracks and type(pl.tracks) == "table" then
						for _, song in ipairs(pl.tracks) do
							local soundId = song.sound_id or song.id
							local title = song.title or song.judul
							if soundId and title then
								local soundIdStr = tostring(soundId)
								local trackObj = {
									id                = soundIdStr,
									sound_id          = soundIdStr,
									judul             = title,
									title             = title,
									sampul            = plThumb,
									thumbnail         = plThumb,
									playlistName      = plName,
									playlistThumbnail = plThumb,
								}
								table.insert(list, trackObj)
								table.insert(plTracks, trackObj)
							end
						end
					end

					table.insert(playlists, {
						name      = plName,
						thumbnail = plThumb,
						tracks    = plTracks,
					})
				end
			elseif decoded and decoded.dj and type(decoded.dj) == "table" then
				local plTracks = {}
				local plName = "DJ Playlist"
				local plThumb = DEFAULT_SAMPUL
				for _, song in ipairs(decoded.dj) do
					if song.sound_id and song.title then
						local soundIdStr = tostring(song.sound_id)
						local sThumb = song.thumbnail or song.sampul or plThumb
						local trackObj = {
							id                = soundIdStr,
							sound_id          = soundIdStr,
							judul             = song.title,
							title             = song.title,
							sampul            = sThumb,
							thumbnail         = sThumb,
							playlistName      = plName,
							playlistThumbnail = plThumb,
						}
						table.insert(list, trackObj)
						table.insert(plTracks, trackObj)
					end
				end
				table.insert(playlists, {
					name      = plName,
					thumbnail = plThumb,
					tracks    = plTracks,
				})
			end

			return { list = list, playlists = playlists }
		end)

		if ok and result and result.list and #result.list > 0 then
			print(string.format("[MusicPlaylistBridge] Berhasil fetch: %d lagu, %d playlist (percobaan %d)", #result.list, #result.playlists, attempt))
			return result
		else
			warn(string.format("[MusicPlaylistBridge] Gagal fetch percobaan %d/%d: %s", attempt, MAX_RETRIES, tostring(result)))
			if attempt < MAX_RETRIES then task.wait(RETRY_DELAY) end
		end
	end
	warn("[MusicPlaylistBridge] Semua percobaan gagal!")
	return { list = {}, playlists = {} }
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
	local res = doFetch()
	loadedList      = res.list or {}
	loadedPlaylists = res.playlists or {}
	isLoaded        = true
	isLoading       = false

	local MusicModule = require(ReplicatedStorage.Modules:WaitForChild("MusicModule"))
	MusicModule:SetPlaylist(loadedList, loadedPlaylists)
	notifyCallbacks(loadedList, loadedPlaylists)
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
	if isLoaded then task.spawn(callback, loadedList, loadedPlaylists)
	else table.insert(callbacks, callback) end
end

function MusicPlaylistBridge:IsLoaded() return isLoaded end
function MusicPlaylistBridge:GetList()   return loadedList end
function MusicPlaylistBridge:GetPlaylists() return loadedPlaylists end

return MusicPlaylistBridge
