local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local RoleSystem          = require(ServerStorage.Modules.RoleSystem)
local MusicModule         = require(ReplicatedStorage.Modules:WaitForChild("MusicModule"))
local MusicStorageHandler = require(ReplicatedStorage.Modules:WaitForChild("MusicStorageHandler"))

local MusicQueueManager      = require(script.MusicQueueManager)
local MusicPlaybackManager   = require(script.MusicPlaybackManager)
local MusicValidationService = require(script.MusicValidationService)
local MusicSkipVoteManager   = require(script.MusicSkipVoteManager)
local MusicPlaylistManager   = require(script.MusicPlaylistManager)

local CONFIG = {
	COOLDOWNS = {
		VIP       = 60,
		Creator   = 60,
		Streamer  = 60,
		Admin     = 0,
		Developer = 0,
		Owner     = 0,
	},
	SPAM_PROTECTION = {
		ACTIONS_LIMIT = 3,
		TIME_WINDOW   = 5,
		ACTION_COOLDOWNS = {
			ADD_TO_QUEUE       = 2,
			SKIP_VOTE_INITIATE = 10,
			CONTROL_NEXT       = 5,
		},
	},
	SKIP_VOTE_DURATION    = 30,
	SKIP_VOTE_COOLDOWN    = 1,
	MAX_QUEUE_SIZE        = 30,
	MAX_QUEUE_PER_USER    = 5,
	MAX_MUSIC_ID_LENGTH   = 20,
	DEFAULT_SONG_DURATION = 180,
	AUTO_PLAYLIST_ENABLED = true,

	SYNC_DEBOUNCE_TIME       = 0.3,
	PROGRESS_UPDATE_INTERVAL = 3,
	BATCH_UPDATE_DELAY       = 0.1,
	PRELOAD_TOP_SONGS        = 5,
	MAX_LOAD_RETRIES         = 2,
	LOAD_RETRY_DELAY         = 1,
	SYNC_RATE_LIMIT          = 2,
}

local SystemState = {
	IsReady                = false,
	InitialPreloadComplete = false,
	LoadingQueue           = {},
	FailedLoads            = {},
}

local remoteFolder = ReplicatedStorage:FindFirstChild("MusicRemotes")
if not remoteFolder then
	remoteFolder        = Instance.new("Folder")
	remoteFolder.Name   = "MusicRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name, className)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote        = Instance.new(className)
		remote.Name   = name
		remote.Parent = remoteFolder
	end
	return remote
end

local dispatchAction = getOrCreateRemote("DispatchAction", "RemoteEvent")
local dispatchEvent  = getOrCreateRemote("DispatchEvent",  "RemoteEvent")
local musicBroadcast = getOrCreateRemote("MusicBroadcast", "RemoteEvent")
local musicUpdate    = getOrCreateRemote("MusicUpdate",    "RemoteEvent")
local requestSync    = getOrCreateRemote("RequestSync",    "RemoteEvent")
local getPlaylist    = getOrCreateRemote("GetPlaylist",    "RemoteFunction")

local Remotes = {
	DispatchAction = dispatchAction,
	DispatchEvent  = dispatchEvent,
	MusicBroadcast = musicBroadcast,
	MusicUpdate    = musicUpdate,
	RequestSync    = requestSync,
}

getPlaylist.OnServerInvoke = function(player)
	return {
		songs     = MusicModule:GetAllMusic(),
		playlists = MusicModule:GetPlaylists(),
	}
end

local queueManager      = MusicQueueManager.new(CONFIG)
local playbackManager   = MusicPlaybackManager.new(CONFIG)
local validationService = MusicValidationService.new(CONFIG)
local skipVoteManager   = MusicSkipVoteManager.new(CONFIG, RoleSystem)
local playlistManager   = MusicPlaylistManager.new(CONFIG)

local RateLimiter = {}
RateLimiter.playerLimits = {}

function RateLimiter:CheckLimit(player, actionType)
	local userId   = player.UserId
	local cooldown = CONFIG.SPAM_PROTECTION.ACTION_COOLDOWNS[actionType] or CONFIG.SYNC_RATE_LIMIT
	if not self.playerLimits[userId] then self.playerLimits[userId] = {} end
	local lastTime = self.playerLimits[userId][actionType]
	if lastTime and (workspace:GetServerTimeNow() - lastTime) < cooldown then return false end
	self.playerLimits[userId][actionType] = workspace:GetServerTimeNow()
	return true
end

function RateLimiter:Cleanup(userId)
	self.playerLimits[userId] = nil
end

local RetryTracker = {}
RetryTracker.playerRetries = {}

function RetryTracker:Track(player)
	local userId = player.UserId
	if not self.playerRetries[userId] then
		self.playerRetries[userId] = { count = 0, lastRetry = 0, totalRetries = 0, firstRetry = workspace:GetServerTimeNow() }
	end
	local data        = self.playerRetries[userId]
	data.count        = data.count + 1
	data.totalRetries = data.totalRetries + 1
	data.lastRetry    = workspace:GetServerTimeNow()
	return data
end

function RetryTracker:GetStats(player)
	return self.playerRetries[player.UserId] or { count = 0, totalRetries = 0 }
end

function RetryTracker:Reset(player)
	if self.playerRetries[player.UserId] then
		self.playerRetries[player.UserId].count = 0
	end
end

function RetryTracker:Cleanup(userId)
	self.playerRetries[userId] = nil
end

local Dispatcher = {}

function Dispatcher:SendToClient(player, eventType, payload)
	if player and player:IsDescendantOf(Players) then
		pcall(function()
			dispatchEvent:FireClient(player, { type = eventType, payload = payload })
		end)
	end
end

function Dispatcher:SendToAll(eventType, payload)
	pcall(function()
		dispatchEvent:FireAllClients({ type = eventType, payload = payload })
	end)
end

function Dispatcher:Notify(player, message)
	self:SendToClient(player, "NOTIFY", { message = message })
end

function Dispatcher:NotifyAll(message)
	self:SendToAll("NOTIFY", { message = message })
end

function Dispatcher:SyncQueueOnly()
	local fullQueue    = queueManager:GetQueue()
	local limitedQueue = {}
	for i = 1, math.min(10, #fullQueue) do
		table.insert(limitedQueue, fullQueue[i])
	end
	self:SendToAll("QUEUE_UPDATE", { queue = limitedQueue, totalCount = #fullQueue })
end

function Dispatcher:SyncState()
	local s = playbackManager:GetState()
	self:SendToAll("SYNC_STATE", {
		queue           = queueManager:GetQueue(),
		currentSong     = s.currentSong,
		currentUploader = s.currentUploader,
		isPlaying       = s.isPlaying,
		startTime       = s.startTime,
		duration        = s.duration,
		serverStartTime = s.startTime,
		serverTimeNow   = workspace:GetServerTimeNow(),
	})
end

function Dispatcher:SyncToPlayer(player)
	if not validationService:ValidatePlayer(player) then return end
	local s = playbackManager:GetState()
	self:SendToClient(player, "SYNC_STATE", {
		queue           = queueManager:GetQueue(),
		currentSong     = s.currentSong,
		currentUploader = s.currentUploader,
		isPlaying       = s.isPlaying,
		startTime       = s.startTime,
		duration        = s.duration,
		serverStartTime = s.startTime,
		serverTimeNow   = workspace:GetServerTimeNow(),
	})
	if s.isPlaying and s.currentSong then
		playbackManager:SyncToPlayer(Remotes, player)
	end
end

local syncBatch = { queueUpdatePending = false, stateUpdatePending = false }

local function scheduleBatchedSync(syncType)
	if syncType == "queue" then
		if syncBatch.queueUpdatePending then return end
		syncBatch.queueUpdatePending = true
		task.delay(CONFIG.BATCH_UPDATE_DELAY, function()
			syncBatch.queueUpdatePending = false
			Dispatcher:SyncQueueOnly()
		end)
	elseif syncType == "state" then
		if syncBatch.stateUpdatePending then return end
		syncBatch.stateUpdatePending = true
		task.delay(CONFIG.BATCH_UPDATE_DELAY, function()
			syncBatch.stateUpdatePending = false
			Dispatcher:SyncState()
		end)
	end
end

local function loadSongOnDemand(musicId, musicTitle)
	if SystemState.LoadingQueue[musicId] then
		local startWait = workspace:GetServerTimeNow()
		while SystemState.LoadingQueue[musicId] and (workspace:GetServerTimeNow() - startWait) < 20 do
			task.wait(0.5)
		end
	end

	local sound, duration = MusicStorageHandler:GetSound(musicId)
	if duration > 0 then return duration end

	if SystemState.FailedLoads[musicId] then
		local failData = SystemState.FailedLoads[musicId]
		if workspace:GetServerTimeNow() - failData.timestamp < 300 then return 0 end
	end

	SystemState.LoadingQueue[musicId] = true
	sound, duration = MusicStorageHandler:LoadSound(musicId, musicTitle)
	SystemState.LoadingQueue[musicId] = nil

	if duration > 0 then
		return duration
	else
		SystemState.FailedLoads[musicId] = { title = musicTitle, timestamp = workspace:GetServerTimeNow() }
		return 0
	end
end

local function preloadNextSong()
	if not queueManager:IsEmpty() then
		local queue = queueManager:GetQueue()
		if queue[1] then
			local nextData = queue[1].musicData
			loadSongOnDemand(nextData.id, nextData.judul)
		end
	elseif CONFIG.AUTO_PLAYLIST_ENABLED then
		local nextSong = playlistManager:PeekNextSong()
		if nextSong then
			loadSongOnDemand(nextSong.id, nextSong.judul)
		end
	end
end

local playNextSong
local isPlayingNext = false

playNextSong = function()
	if isPlayingNext then
		warn("[MusicSystem] playNextSong sedang berjalan, abaikan panggilan ganda")
		return
	end
	isPlayingNext = true

	local function resetLock()
		isPlayingNext = false
	end

	if skipVoteManager:IsActive() then
		skipVoteManager:EndVote(Dispatcher, true)
	end
	if not queueManager:IsEmpty() then
		local nextSong = queueManager:GetNext()
		local duration = loadSongOnDemand(nextSong.musicData.id, nextSong.musicData.judul)
		if duration > 0 then
			nextSong.musicData.Duration  = duration
			nextSong.Duration            = duration
			playbackManager.autoNextCallback = playNextSong
			playbackManager.preloadCallback  = preloadNextSong
			local success = playbackManager:Play(Remotes, nextSong, nextSong.uploader, false)
			resetLock()
			if success then scheduleBatchedSync("state")
			else task.delay(0.5, playNextSong) end
		else
			warn(string.format("[MusicSystem] Gagal memuat lagu queue '%s' (ID: %s), melewati...", tostring(nextSong.musicData.judul), tostring(nextSong.musicData.id)))
			resetLock()
			task.delay(0.5, playNextSong)
		end

	elseif CONFIG.AUTO_PLAYLIST_ENABLED then
		local playlistSong = playlistManager:GetNextSong()
		if playlistSong then
			local duration = loadSongOnDemand(playlistSong.id, playlistSong.judul)
			if duration > 0 then
				playlistSong.Duration = duration
				local songData = { musicData = playlistSong, uploader = "Auto-Playlist", Duration = duration }
				playbackManager.autoNextCallback = playNextSong
				playbackManager.preloadCallback  = preloadNextSong
				local success = playbackManager:Play(Remotes, songData, "Auto-Playlist", true)
				resetLock()
				if success then scheduleBatchedSync("state")
				else task.delay(0.5, playNextSong) end
			else
				warn(string.format("[MusicSystem] Gagal memuat lagu playlist '%s' (ID: %s), melewati...", tostring(playlistSong.judul), tostring(playlistSong.id)))
				resetLock()
				task.delay(0.5, playNextSong)
			end
		else
			playbackManager:StopWithFade(Remotes)
			resetLock()
			scheduleBatchedSync("state")
		end
	else
		playbackManager:StopWithFade(Remotes)
		resetLock()
		scheduleBatchedSync("state")
	end
end

local ActionHandlers = {}

function ActionHandlers:ADD_TO_QUEUE(player, data)
	if not validationService:ValidatePlayer(player) then return end
	if not RateLimiter:CheckLimit(player, "ADD_TO_QUEUE") then
		Dispatcher:Notify(player, "Tunggu 2 detik sebelum menambah lagu lagi!")
		return
	end

	local musicId        = data.musicId
	local isFromPlaylist = data.isFromPlaylist
	if type(musicId) ~= "string" or type(isFromPlaylist) ~= "boolean" then return end

	local canProceed, spamMsg = validationService:CheckSpamProtection(player)
	if not canProceed then Dispatcher:Notify(player, spamMsg); return end

	local role = RoleSystem:GetPlayerRole(player)
	if RoleSystem.Config.RoleHierarchy[role] < 2 then
		Dispatcher:Notify(player, "Minimal rank VIP untuk menambah lagu!")
		return
	end

	local canAddCooldown, cooldownMsg = validationService:CheckCooldown(player, CONFIG.COOLDOWNS)
	if not canAddCooldown then Dispatcher:Notify(player, cooldownMsg); return end

	if not SystemState.InitialPreloadComplete then
		Dispatcher:Notify(player, "Sistem sedang memuat playlist, harap tunggu...")
		return
	end

	task.spawn(function()
		local musicData
		if isFromPlaylist then
			local found = MusicModule:GetMusicById(musicId)
			if not found then Dispatcher:Notify(player, "Lagu tidak ditemukan di playlist!"); return end
			musicData = {
				id       = tostring(found.id),
				judul    = found.judul,
				sampul   = found.sampul,
				Duration = found.Duration or 0,
			}
		else
			local valid, vdata, reason = validationService:ValidateMusicId(musicId)
			if not valid then Dispatcher:Notify(player, "Music ID tidak valid! Periksa kembali."); return end
			musicData = vdata
		end

		local sound, cachedDur = MusicStorageHandler:GetSound(musicData.id)
		if cachedDur and cachedDur > 0 then
			musicData.Duration = math.round(cachedDur)
		elseif not musicData.Duration or musicData.Duration <= 0 then

			local realDur = loadSongOnDemand(musicData.id, musicData.judul)
			if realDur and realDur > 0 then
				musicData.Duration = math.round(realDur)
			else
				musicData.Duration = CONFIG.DEFAULT_SONG_DURATION
			end
		end

		if isFromPlaylist and musicData.Duration > 0 then
			local found = MusicModule:GetMusicById(musicId)
			if found then found.Duration = musicData.Duration end
		end

		local success, errorMsg = queueManager:AddToQueue(musicData, player.DisplayName, player.UserId)
		if not success then Dispatcher:Notify(player, errorMsg); return end

		validationService:UpdateCooldown(player)
		scheduleBatchedSync("queue")
		local queuePosition = queueManager:GetSize()
		Dispatcher:Notify(player, string.format("'%s' ditambahkan ke antrean (Posisi: #%d)", musicData.judul, queuePosition))

		if musicData.Duration == CONFIG.DEFAULT_SONG_DURATION then
			task.spawn(function()
				local realDur = loadSongOnDemand(musicData.id, musicData.judul)
				if realDur and realDur > 0 and realDur ~= CONFIG.DEFAULT_SONG_DURATION then
					musicData.Duration = math.round(realDur)

					queueManager:UpdateDuration(musicData.id, realDur)
					if isFromPlaylist then
						local found = MusicModule:GetMusicById(musicId)
						if found then found.Duration = musicData.Duration end
					end
					scheduleBatchedSync("queue")
				end
			end)
		end

		if not playbackManager:IsPlaying() then
			task.delay(0.5, playNextSong)
		end
	end)
end

function ActionHandlers:CONTROL_NEXT(player, data)
	if not validationService:ValidatePlayer(player) then return end
	local role          = RoleSystem:GetPlayerRole(player)
	local roleHierarchy = RoleSystem.Config.RoleHierarchy[role] or 0

	local currentSong = playbackManager:GetCurrentSong()
	if not currentSong then Dispatcher:Notify(player, "Tidak ada lagu yang sedang diputar!"); return end

	if roleHierarchy >= 5 then
		if not RateLimiter:CheckLimit(player, "CONTROL_NEXT") then
			Dispatcher:Notify(player, "Tunggu sebentar sebelum skip lagi!")
			return
		end
		Dispatcher:NotifyAll(string.format("%s (%s) skip: %s", player.DisplayName, role, currentSong.judul or "Unknown"))
		if skipVoteManager:IsActive() then
			skipVoteManager:EndVote(Dispatcher, true)
		end
		playNextSong()
		return
	end

	if skipVoteManager:IsActive() then
		ActionHandlers:SKIP_VOTE_YES(player, data)
		return
	end

	if not RateLimiter:CheckLimit(player, "SKIP_VOTE_INITIATE") then
		Dispatcher:Notify(player, "Tunggu sebelum memulai vote skip lagi!")
		return
	end

	local success, msg = skipVoteManager:StartVote(player, currentSong, Dispatcher)
	if not success then
		Dispatcher:Notify(player, msg)
	else
		Dispatcher:NotifyAll(string.format("%s memulai vote skip untuk: %s", player.DisplayName, currentSong.judul or "Unknown"))

		if not skipVoteManager:IsActive() then
			task.wait(0.5)
			playNextSong()
		end
	end
end

function ActionHandlers:SKIP_VOTE_YES(player, data)
	if not validationService:ValidatePlayer(player) then return end
	local success, passed = skipVoteManager:CastVote(player, "yes", Dispatcher)
	if not success then
		Dispatcher:Notify(player, "Tidak bisa vote. Tidak ada vote aktif atau kamu sudah vote!")
		return
	end
	if passed then
		local currentSong = playbackManager:GetCurrentSong()
		Dispatcher:NotifyAll(string.format("Vote skip berhasil! Melewati: %s", currentSong and currentSong.judul or "Unknown"))
		task.wait(1)
		playNextSong()
		skipVoteManager:EndVote(Dispatcher, true)
	else
		Dispatcher:Notify(player, "Votemu telah dihitung!")
	end
end

function ActionHandlers:SKIP_VOTE_NO(player, data)
	if not validationService:ValidatePlayer(player) then return end
	local success = skipVoteManager:CastVote(player, "no", Dispatcher)
	if success then
		Dispatcher:Notify(player, "Votemu telah dihitung!")
	else
		Dispatcher:Notify(player, "Tidak bisa vote. Tidak ada vote aktif atau kamu sudah vote!")
	end
end

dispatchAction.OnServerEvent:Connect(function(player, action)
	if not validationService:ValidatePlayer(player) then return end
	if type(action) ~= "table" or type(action.type) ~= "string" then return end
	local validActions = {
		ADD_TO_QUEUE  = true,
		CONTROL_NEXT  = true,
		SKIP_VOTE_YES = true,
		SKIP_VOTE_NO  = true,
	}
	if not validActions[action.type] then return end
	local handler = ActionHandlers[action.type]
	if handler then
		pcall(function() handler(ActionHandlers, player, action.payload or {}) end)
	end
end)

requestSync.OnServerEvent:Connect(function(player)
	if not validationService:ValidatePlayer(player) then return end
	if not RateLimiter:CheckLimit(player, "REQUEST_SYNC") then
		return
	end
	RetryTracker:Track(player)

	Dispatcher:SyncToPlayer(player)
	RetryTracker:Reset(player)
end)

Players.PlayerAdded:Connect(function(player)
	RoleSystem:InitializePlayer(player)
	task.wait(0.5)
	if validationService:ValidatePlayer(player) then
		Dispatcher:SyncToPlayer(player)

	end

	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then return end
		task.wait(0.5)
		if validationService:ValidatePlayer(player) then
			Dispatcher:SyncToPlayer(player)

			task.delay(1.5, function()
				if validationService:ValidatePlayer(player) then
					Dispatcher:SyncToPlayer(player)
				end
			end)
		end
	end)

	player.Chatted:Connect(function(message)
		local role = RoleSystem:GetPlayerRole(player)
		if role == "Owner" or role == "Developer" or role == "Admin" then
			local lowerMsg = string.lower(message)

			if lowerMsg == "/retrystats" or lowerMsg == ";rs" then
				local totalPlayers, totalRetries, playersWithRetries = 0, 0, 0
				for _, plr in ipairs(Players:GetPlayers()) do
					totalPlayers = totalPlayers + 1
					local stats = RetryTracker:GetStats(plr)
					if stats.totalRetries > 0 then
						playersWithRetries = playersWithRetries + 1
						totalRetries = totalRetries + stats.totalRetries
					end
				end
				Dispatcher:Notify(player, string.format(
					"Statistik Retry:\nPlayer dengan retry: %d/%d\nTotal percobaan: %d",
					playersWithRetries, totalPlayers, totalRetries
					))
			end

			if lowerMsg:match("^/retryplayer%s+") or lowerMsg:match("^;retryplayer%s+") then
				local targetName = lowerMsg:match("^/retryplayer%s+(.+)") or lowerMsg:match("^;retryplayer%s+(.+)")
				local targetPlayer, matches = nil, {}
				local lowerTarget = targetName:lower()
				for _, plr in ipairs(Players:GetPlayers()) do
					local lowerDisplay = plr.DisplayName:lower()
					if lowerDisplay == lowerTarget then targetPlayer = plr; break end
					if #lowerTarget >= 3 and lowerDisplay:sub(1, #lowerTarget) == lowerTarget then
						table.insert(matches, plr)
					end
				end
				if not targetPlayer then
					if #matches == 1 then targetPlayer = matches[1]
					elseif #matches > 1 then
						local names = {}
						for _, plr in ipairs(matches) do table.insert(names, plr.DisplayName) end
						Dispatcher:Notify(player, "Beberapa player ditemukan: "..table.concat(names, ", ")..". Lebih spesifik!")
						return
					end
				end
				if targetPlayer then
					Dispatcher:SyncToPlayer(targetPlayer)
					task.delay(0.3, function()
						Dispatcher:Notify(player, string.format("Musik %s telah di-resync!", targetPlayer.DisplayName))
					end)
				else
					Dispatcher:Notify(player, "Player tidak ditemukan!")
				end
			end

			if lowerMsg == "/retryall" or lowerMsg == ";retryall" then
				for _, plr in ipairs(Players:GetPlayers()) do
					if validationService:ValidatePlayer(plr) then
						Dispatcher:SyncToPlayer(plr)
					end
				end

				Dispatcher:Notify(player, "Musik semua player telah di-resync!")
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	validationService:CleanupPlayer(userId)
	skipVoteManager:UpdateVoteOnPlayerLeave(userId, Dispatcher)
	RateLimiter:Cleanup(userId)
	RetryTracker:Cleanup(userId)
	scheduleBatchedSync("queue")
end)

MusicStorageHandler:StartAutoCleanup()

task.spawn(function()

	local bridge    = require(ServerStorage:WaitForChild("Modules"):WaitForChild("MusicPlaylistBridge"))
	local fetchList = bridge:WaitUntilReady(30)

	if fetchList and #fetchList > 0 then
		MusicModule:SetPlaylist(fetchList)
	end

	local preloadCount = MusicModule:Preload()
	if preloadCount == 0 then
		warn("[MusicSystem] Playlist kosong atau gagal fetch API!")
	end

	local currentQueue = queueManager:GetQueue()
	if #currentQueue > 0 then
		for _, songData in ipairs(currentQueue) do
			local duration = loadSongOnDemand(songData.musicData.id, songData.musicData.judul)
			if duration > 0 then
				songData.musicData.Duration = duration
				songData.Duration           = duration
			end
		end
	end

	local musicList = MusicModule:GetAllMusic()
	local topSongs  = {}
	for i = 1, math.min(CONFIG.PRELOAD_TOP_SONGS, #musicList) do
		table.insert(topSongs, musicList[i])
	end
	for _, song in ipairs(topSongs) do
		if not MusicStorageHandler:IsSoundReady(song.id) then
			local duration = loadSongOnDemand(song.id, song.judul)
			if duration > 0 then song.Duration = duration end
		end
	end

	SystemState.InitialPreloadComplete = true

	print(string.format("[MusicSystem] Sistem musik siap! %d lagu tersedia", #musicList))
	task.wait(0.5)
	SystemState.IsReady = true

	if CONFIG.AUTO_PLAYLIST_ENABLED and queueManager:IsEmpty() and not playbackManager:IsPlaying() then
		playNextSong()
	elseif not queueManager:IsEmpty() and not playbackManager:IsPlaying() then
		playNextSong()
	end
end)
