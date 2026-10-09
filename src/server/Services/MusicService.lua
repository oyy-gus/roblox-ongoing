--[[
	MusicService.lua
	Tujuan: Layanan utama server untuk sinkronisasi pemutaran lagu global (Master Clock, Queue, Vote Skip).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local PlaylistService = require(script.Parent.PlaylistService)
local QueueService = require(script.Parent.QueueService)
local PermissionService = require(script.Parent.PermissionService)

local MusicService = {}

local playlist = {}
local currentIndex = 1
local songStartTime = 0
local isPlaying = false
local isLoaded = false
local lastActionTime = {} -- Player -> timestamp cooldown
local voteSkipPlayers = {} -- Set of player UserIds who voted
local currentSongOverride = nil -- Jika memutar lagu khusus dari antrean

-- Remotes
local RE_SyncState = Remotes.GetEvent(Remotes.NAMES.SyncState)
local RE_VoteSkip = Remotes.GetEvent(Remotes.NAMES.VoteSkip)
local RE_PlaySongAtIndex = Remotes.GetEvent(Remotes.NAMES.PlaySongAtIndex)
local RE_AddToQueue = Remotes.GetEvent(Remotes.NAMES.AddToQueue)
local RF_GetState = Remotes.GetFunction(Remotes.NAMES.GetState)
local RF_GetPlaylist = Remotes.GetFunction(Remotes.NAMES.GetPlaylist)

local function getCurrentPosition()
	if not isPlaying then return 0 end
	return os.clock() - songStartTime
end

local function getVotesNeeded()
	local totalPlayers = #Players:GetPlayers()
	if totalPlayers <= 1 then return 1 end
	return math.ceil(totalPlayers * 0.5)
end

function MusicService.BuildSyncPayload()
	if not isLoaded or #playlist == 0 then
		playlist = PlaylistService.GetPlaylist()
		isLoaded = true
	end
	
	local song = currentSongOverride or playlist[currentIndex] or playlist[1]
	local votesCount = 0
	for _ in pairs(voteSkipPlayers) do
		votesCount += 1
	end

	return {
		loaded = true,
		index = currentIndex,
		total = #playlist,
		soundId = song.sound_id,
		title = song.title or UIStrings.Music.UnknownTitle,
		artist = song.artist or UIStrings.Music.UnknownArtist,
		position = getCurrentPosition(),
		serverClock = os.clock(),
		isPlaying = isPlaying,
		playlist = playlist,
		queue = QueueService.GetQueue(),
		votesCount = votesCount,
		votesNeeded = getVotesNeeded(),
	}
end

function MusicService.BroadcastSync()
	local payload = MusicService.BuildSyncPayload()
	RE_SyncState:FireAllClients(payload)
end

function MusicService.StartSong(index)
	playlist = PlaylistService.GetPlaylist()
	if #playlist == 0 then return end
	
	table.clear(voteSkipPlayers)
	currentSongOverride = nil
	currentIndex = ((index - 1) % #playlist) + 1
	songStartTime = os.clock()
	isPlaying = true
	
	print(string.format("[MusicService] Memutar lagu [%d/%d]: %s (ID: %s)", currentIndex, #playlist, playlist[currentIndex].title, tostring(playlist[currentIndex].sound_id)))
	MusicService.BroadcastSync()
end

function MusicService.NextSong()
	table.clear(voteSkipPlayers)
	local nextQueued = QueueService.PopNextSong()
	if nextQueued then
		songStartTime = os.clock()
		isPlaying = true
		currentSongOverride = nextQueued
		
		-- Cari index lagu jika ada di playlist
		for i, s in ipairs(playlist) do
			if tostring(s.sound_id) == tostring(nextQueued.sound_id) then
				currentIndex = i
				break
			end
		end
		
		print(string.format("[MusicService] Memutar lagu dari antrean: %s", nextQueued.title))
		MusicService.BroadcastSync()
		return
	end
	
	MusicService.StartSong(currentIndex + 1)
end

local function checkRateLimit(player)
	local now = os.clock()
	local last = lastActionTime[player] or 0
	if now - last < Config.SKIP_COOLDOWN then
		return false
	end
	lastActionTime[player] = now
	return true
end

function MusicService.Init()
	playlist = PlaylistService.FetchPlaylist()
	isLoaded = true
	
	-- Remote Handlers
	RF_GetState.OnServerInvoke = function(_player)
		return MusicService.BuildSyncPayload()
	end

	RF_GetPlaylist.OnServerInvoke = function(_player)
		return PlaylistService.GetPlaylist()
	end

	RE_VoteSkip.OnServerEvent:Connect(function(player)
		if not checkRateLimit(player) then return end
		voteSkipPlayers[player.UserId] = true
		
		local count = 0
		for _ in pairs(voteSkipPlayers) do count += 1 end
		
		if count >= getVotesNeeded() then
			print(string.format("[MusicService] Vote skip berhasil oleh %s. Melompat ke lagu berikutnya.", player.Name))
			MusicService.NextSong()
		else
			MusicService.BroadcastSync()
		end
	end)

	-- RE_PlaySongAtIndex: Putar lagu LANGSUNG (hanya jika tidak ada yang diputar)
	RE_PlaySongAtIndex.OnServerEvent:Connect(function(player, requestedIndex)
		if not checkRateLimit(player) then return end
		local requestedSong = playlist[requestedIndex]
		if not requestedSong then return end

		if isPlaying then
			-- Ada lagu yang sedang diputar: masukkan ke antrean otomatis
			QueueService.AddSong(requestedSong, player)
			print(string.format("[MusicService] %s menambahkan '%s' ke antrean (auto-queue: lagu sedang diputar).", player.Name, requestedSong.title))
			MusicService.BroadcastSync()
		else
			-- Tidak ada yang diputar: putar langsung
			MusicService.StartSong(requestedIndex)
		end
	end)

	-- RE_AddToQueue: Tambahkan lagu ke antrean secara eksplisit
	RE_AddToQueue.OnServerEvent:Connect(function(player, requestedIndex)
		if not checkRateLimit(player) then return end
		local requestedSong = playlist[requestedIndex]
		if not requestedSong then return end

		local ok = QueueService.AddSong(requestedSong, player)
		if ok then
			print(string.format("[MusicService] %s menambahkan '%s' ke antrean.", player.Name, requestedSong.title))
			MusicService.BroadcastSync()
		else
			warn(string.format("[MusicService] Antrean penuh, '%s' tidak bisa ditambahkan.", requestedSong.title))
		end
	end)

	-- Synchronize new players
	Players.PlayerAdded:Connect(function(player)
		task.delay(1.5, function()
			if player and player.Parent then
				RE_SyncState:FireClient(player, MusicService.BuildSyncPayload())
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastActionTime[player] = nil
		voteSkipPlayers[player.UserId] = nil
	end)

	-- Master Clock Sync Loop
	local syncTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		if not isLoaded then return end
		syncTimer += dt
		if syncTimer >= Config.SYNC_INTERVAL then
			syncTimer = 0
			MusicService.BroadcastSync()
		end
	end)

	-- Start initial song
	MusicService.StartSong(1)
end

return MusicService
