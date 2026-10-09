-- MusicServer: Server-side music synchronization system
-- Fetches playlist from API, controls global playback state,
-- and ensures ALL players hear the exact same song at the exact same position.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ─── Constants ───────────────────────────────────────────────────────────────
local PLAYLIST_URL = "https://oyy-gus.github.io/api/v1/roblox/music/playlist.json"
local SYNC_INTERVAL = 5        -- seconds between forced re-sync broadcasts
local TICK_RATE = 0.05         -- 50ms tick for position tracking

-- ─── Remote Events ───────────────────────────────────────────────────────────
local Remotes = Instance.new("Folder")
Remotes.Name = "MusicRemotes"
Remotes.Parent = ReplicatedStorage

local RE_SyncState   = Instance.new("RemoteEvent")  -- Server → Client: full state sync
RE_SyncState.Name    = "SyncState"
RE_SyncState.Parent  = Remotes

local RE_NextSong    = Instance.new("RemoteEvent")  -- Client → Server: skip request (admin)
RE_NextSong.Name     = "NextSong"
RE_NextSong.Parent   = Remotes

local RE_PrevSong    = Instance.new("RemoteEvent")
RE_PrevSong.Name     = "PrevSong"
RE_PrevSong.Parent   = Remotes

local RF_GetState    = Instance.new("RemoteFunction") -- Client → Server: request current state
RF_GetState.Name     = "GetState"
RF_GetState.Parent   = Remotes

local RF_GetPlaylist = Instance.new("RemoteFunction") -- Client → Server: request full playlist
RF_GetPlaylist.Name  = "GetPlaylist"
RF_GetPlaylist.Parent = Remotes

-- ─── State ───────────────────────────────────────────────────────────────────
local playlist       = {}       -- { title, sound_id }[]
local currentIndex   = 1        -- 1-based index
local songStartTime  = 0        -- os.clock() when song started
local isPlaying      = false
local isLoaded       = false

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function getCurrentPosition()
	if not isPlaying then return 0 end
	return os.clock() - songStartTime
end

local function buildSyncPayload()
	if not isLoaded or #playlist == 0 then
		return { loaded = false }
	end
	local song = playlist[currentIndex]
	return {
		loaded       = true,
		index        = currentIndex,
		total        = #playlist,
		soundId      = song.sound_id,
		title        = song.title,
		position     = getCurrentPosition(),  -- precise server time
		serverClock  = os.clock(),            -- client can calibrate latency
		isPlaying    = isPlaying,
	}
end

local function broadcastSync()
	local payload = buildSyncPayload()
	RE_SyncState:FireAllClients(payload)
end

local function startSong(index)
	if #playlist == 0 then return end
	-- clamp index
	currentIndex = ((index - 1) % #playlist) + 1
	songStartTime = os.clock()
	isPlaying = true
	print(string.format("[MusicServer] Now playing [%d/%d]: %s", currentIndex, #playlist, playlist[currentIndex].title))
	broadcastSync()
end

local function nextSong()
	startSong(currentIndex + 1)
end

local function prevSong()
	startSong(currentIndex - 1)
end

-- ─── Fetch Playlist ──────────────────────────────────────────────────────────
local function fetchPlaylist()
	local ok, result = pcall(function()
		local json = HttpService:GetAsync(PLAYLIST_URL, true)
		return HttpService:JSONDecode(json)
	end)

	if ok and result and result.dj then
		playlist = result.dj
		print(string.format("[MusicServer] Loaded %d songs from API.", #playlist))
		isLoaded = true
		startSong(1)
	else
		warn("[MusicServer] Failed to fetch playlist:", result)
		-- Fallback hardcoded songs
		playlist = {
			{ title = "DJ ALWAYS LOVING YOU",       sound_id = "84552280374794" },
			{ title = "DJ JEALOUSY VELOCITY",       sound_id = "89501777604655" },
			{ title = "DJ MANGU",                   sound_id = "117289628255606" },
			{ title = "DJ SAMPAI AKHIR",            sound_id = "126888998031809" },
			{ title = "DJ BERDUA LEBIH BAIK",       sound_id = "95531563140400" },
			{ title = "DJ KONCO MESRA",             sound_id = "123369864623197" },
		}
		isLoaded = true
		startSong(1)
	end
end

-- ─── Remote Handlers ─────────────────────────────────────────────────────────
RF_GetState.OnServerInvoke = function(_player)
	return buildSyncPayload()
end

RF_GetPlaylist.OnServerInvoke = function(_player)
	return playlist
end

RE_NextSong.OnServerEvent:Connect(function(player)
	-- Only allow; you can add admin check here
	print(string.format("[MusicServer] %s requested next song.", player.Name))
	nextSong()
end)

RE_PrevSong.OnServerEvent:Connect(function(player)
	print(string.format("[MusicServer] %s requested previous song.", player.Name))
	prevSong()
end)

-- ─── New Player Sync ─────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	task.delay(1, function()  -- wait for client to load
		if player and player.Parent then
			local payload = buildSyncPayload()
			RE_SyncState:FireClient(player, payload)
		end
	end)
end)

-- ─── Periodic Sync Loop ──────────────────────────────────────────────────────
-- Every SYNC_INTERVAL seconds, broadcast state to correct any drift
local syncTimer = 0
local tickTimer = 0

RunService.Heartbeat:Connect(function(dt)
	if not isLoaded then return end

	tickTimer += dt
	syncTimer += dt

	-- Periodic forced re-sync
	if syncTimer >= SYNC_INTERVAL then
		syncTimer = 0
		broadcastSync()
	end
end)

-- ─── Boot ────────────────────────────────────────────────────────────────────
task.spawn(fetchPlaylist)
