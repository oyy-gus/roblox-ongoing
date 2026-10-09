--[[
	MusicController.lua
	Tujuan: Pengendali pemutaran audio lokal.
	  - Fade-in volume saat lagu baru dimulai
	  - Beat detection via PlaybackLoudness
	  - Sinkronisasi master clock server
	  - Penghubung aksi server (VoteSkip, PlaySongAtIndex, AddToQueue)
]]

local SoundService    = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")

local Shared        = ReplicatedStorage:WaitForChild("Shared", 15)
local Config        = require(Shared:WaitForChild("Config"))
local Remotes       = require(Shared:WaitForChild("Remotes"))
local UIStrings     = require(Shared:WaitForChild("UIStrings"))
local TitleCleaner  = require(Shared:WaitForChild("Utils"):WaitForChild("TitleCleaner"))
local MenuController = require(script.Parent.MenuController)

local MusicController = {}

-- ==================== State ====================
local sound          = nil
local isInitialized  = false
local currentSoundId = ""
local currentTitle   = ""
local currentArtist  = ""
local isPlaying      = false
local currentPosition = 0
local totalLength    = 0
local playlistData   = {}
local queueData      = {}
local votesCount     = 0
local votesNeeded    = 1
local isLoadingSong  = false  -- guard: jangan interrupt load yang sedang berjalan

-- ==================== Beat Detection ====================
local beatLevel     = 0
local volumeHistory = {}
local HISTORY_SIZE  = 8

-- ==================== Fade-In ====================
local FADE_IN_DURATION = 2.0
local fadeInStartTime  = 0
local fadeInTarget     = 0
local isFadingIn       = false
local targetVolume     = Config.DEFAULT_VOLUME

-- ==================== Helpers ====================
local function cleanSoundId(id)
	if not id then return "" end
	local str = tostring(id):match("^%s*(.-)%s*$") or ""
	if str:find("rbxassetid://", 1, true) then
		return str
	elseif tonumber(str) then
		return "rbxassetid://" .. str
	end
	return str
end

local function getRemoteEvent(name)
	local ok, remote = pcall(function() return Remotes.GetEvent(name) end)
	return ok and remote or nil
end

local function getRemoteFunction(name)
	local ok, remote = pcall(function() return Remotes.GetFunction(name) end)
	return ok and remote or nil
end

-- ==================== Fade-In Logic ====================
local function startFadeIn(toVolume)
	isFadingIn     = true
	fadeInStartTime = os.clock()
	fadeInTarget   = toVolume
	if sound then sound.Volume = 0 end
end

local function updateFadeIn()
	if not isFadingIn or not sound then return end
	local elapsed = os.clock() - fadeInStartTime
	local pct     = math.clamp(elapsed / FADE_IN_DURATION, 0, 1)
	local eased   = 1 - math.pow(1 - pct, 3)
	sound.Volume  = eased * fadeInTarget
	if pct >= 1 then
		sound.Volume = fadeInTarget
		isFadingIn   = false
	end
end

-- ==================== Beat Detection ====================
local function updateBeatDetection(dt)
	if not sound or not sound.IsPlaying then
		beatLevel = math.max(0, beatLevel - dt * 3)
		return
	end
	local rawLoudness = 0
	pcall(function() rawLoudness = sound.PlaybackLoudness or 0 end)
	local normalized = math.clamp(rawLoudness / 600, 0, 1)
	table.insert(volumeHistory, normalized)
	if #volumeHistory > HISTORY_SIZE then table.remove(volumeHistory, 1) end
	local avg = 0
	for _, v in ipairs(volumeHistory) do avg += v end
	avg = avg / math.max(1, #volumeHistory)
	local transient = math.clamp(normalized - avg * 0.8, 0, 1)
	if transient > beatLevel then
		beatLevel = math.min(1, beatLevel + (transient - beatLevel) * 0.6)
	else
		beatLevel = math.max(0, beatLevel - dt * 2.5)
	end
end

-- ==================== Play A Song ====================
local function playSong(formattedId, serverPos, serverClock, shouldPlay)
	if not sound then return end
	isLoadingSong = true

	sound:Stop()
	sound.Volume  = 0
	isFadingIn    = false
	sound.SoundId = formattedId
	volumeHistory = {}
	beatLevel     = 0

	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({sound}) end)

		local waited = 0
		while not sound.IsLoaded and waited < 8 do
			task.wait(0.1)
			waited += 0.1
		end

		isLoadingSong = false

		local nowAfterLoad = os.clock()
		local correctedPos = math.max(0, serverPos + (nowAfterLoad - serverClock))

		if sound.TimeLength > 0 and correctedPos < sound.TimeLength then
			pcall(function() sound.TimePosition = correctedPos end)
		end

		if shouldPlay then
			sound:Play()
			startFadeIn(targetVolume)
			print(string.format("[MusicController] Memutar: %s (pos=%.1fs)", formattedId, correctedPos))
		end
	end)
end

-- ==================== Init ====================
function MusicController.Init()
	if isInitialized then return end
	isInitialized = true

	-- Buat Sound object
	sound = Instance.new("Sound")
	sound.Name   = "DangdutGlobalSound"
	sound.Volume = 0
	sound.Looped = false
	sound.RollOffMaxDistance = 0
	sound.Parent = SoundService
	targetVolume = Config.DEFAULT_VOLUME

	-- Inisialisasi Menu UI dengan callback ke server
	MenuController.Init({
		onVoteSkip = function()
			local re = getRemoteEvent(Remotes.NAMES.VoteSkip)
			if re then re:FireServer() end
		end,
		onSelectSong = function(_songData, index)
			local re = getRemoteEvent(Remotes.NAMES.PlaySongAtIndex)
			if re then re:FireServer(index) end
		end,
		onQueueSong = function(_songData, index)
			local re = getRemoteEvent(Remotes.NAMES.AddToQueue)
			if re then re:FireServer(index) end
		end,
		onFavoriteToggled = function(song, isFav)
			local re = getRemoteEvent(Remotes.NAMES.ToggleFavorite)
			if re and song and song.sound_id then
				re:FireServer(tostring(song.sound_id), isFav)
			end
		end,
		onVolumeChanged = function(newVol)
			targetVolume = math.clamp(newVol, 0, 1)
			if isFadingIn then
				fadeInTarget = targetVolume
			else
				if sound then sound.Volume = targetVolume end
			end
		end,
	})

	-- Terima SyncState dari server
	local RE_SyncState = getRemoteEvent(Remotes.NAMES.SyncState)
	if RE_SyncState then
		RE_SyncState.OnClientEvent:Connect(function(state)
			MusicController.ApplySync(state)
		end)
	end

	-- RenderStepped: Fade-in + Beat + UI update
	RunService.RenderStepped:Connect(function(dt)
		updateFadeIn()
		updateBeatDetection(dt)
		if sound and sound.IsPlaying and sound.TimeLength > 0 then
			currentPosition = sound.TimePosition
			totalLength     = sound.TimeLength
		end
		MenuController.UpdateMusicPage({
			title       = currentTitle,
			artist      = currentArtist,
			position    = currentPosition,
			duration    = totalLength,
			soundId     = currentSoundId,
			playlist    = playlistData,
			queue       = queueData,
			votesCount  = votesCount,
			votesNeeded = votesNeeded,
			beatLevel   = beatLevel,
		})
	end)

	-- Minta state & data awal dari server
	task.spawn(function()
		task.wait(1)

		local RF_GetState = getRemoteFunction(Remotes.NAMES.GetState)
		if RF_GetState then
			local ok, state = pcall(function() return RF_GetState:InvokeServer() end)
			if ok and state then
				print("[MusicController] Menerima state awal dari server.")
				MusicController.ApplySync(state)
			else
				warn("[MusicController] Gagal mendapatkan state awal:", tostring(state))
			end
		else
			warn("[MusicController] RF_GetState tidak ditemukan!")
		end

		local RF_GetFavorites = getRemoteFunction(Remotes.NAMES.GetFavorites)
		if RF_GetFavorites then
			local ok, favs = pcall(function() return RF_GetFavorites:InvokeServer() end)
			if ok and favs and type(favs) == "table" then
				MenuController.SetFavorites(favs)
				print(string.format("[MusicController] Memuat %d favorit.", #favs))
			end
		end

		if not playlistData or #playlistData == 0 then
			local RF_GetPlaylist = getRemoteFunction(Remotes.NAMES.GetPlaylist)
			if RF_GetPlaylist then
				local ok, pl = pcall(function() return RF_GetPlaylist:InvokeServer() end)
				if ok and pl and type(pl) == "table" and #pl > 0 then
					playlistData = pl
					print(string.format("[MusicController] Memuat %d lagu via RF_GetPlaylist.", #pl))
				end
			end
		end
	end)
end

-- ==================== ApplySync ====================
function MusicController.ApplySync(state)
	if not state or not state.loaded then
		warn("[MusicController] ApplySync: state tidak valid atau loaded=false.")
		return
	end
	if not sound then
		warn("[MusicController] ApplySync: sound object belum dibuat! Pastikan Init() dipanggil dulu.")
		return
	end

	currentTitle  = TitleCleaner.CleanTitle(state.title or "")
	currentArtist = state.artist or UIStrings.Music.UnknownArtist
	isPlaying     = state.isPlaying == true
	votesCount    = state.votesCount or 0
	votesNeeded   = state.votesNeeded or 1
	queueData     = state.queue or {}

	if state.playlist and type(state.playlist) == "table" and #state.playlist > 0 then
		playlistData = state.playlist
	end

	local formattedId = cleanSoundId(state.soundId)
	if formattedId == "" then
		warn("[MusicController] ApplySync: soundId kosong!")
		return
	end

	print(string.format("[MusicController] ApplySync -> soundId=%s isPlaying=%s", formattedId, tostring(isPlaying)))

	-- Lagu berbeda: muat ulang dan putar
	if formattedId ~= currentSoundId then
		currentSoundId = formattedId
		playSong(formattedId, state.position or 0, state.serverClock or os.clock(), isPlaying)
	else
		-- Lagu sama: hanya koreksi drift & play/pause
		if not isLoadingSong then
			if sound.IsLoaded and sound.TimeLength > 0 then
				local localNow  = os.clock()
				local corrected = math.max(0, (state.position or 0) + (localNow - (state.serverClock or localNow)))
				local drift     = math.abs(sound.TimePosition - corrected)
				if drift > Config.SEEK_THRESHOLD then
					pcall(function() sound.TimePosition = corrected end)
				end
			end

			if isPlaying and not sound.IsPlaying then
				sound:Play()
				if sound.Volume < 0.05 then startFadeIn(targetVolume) end
			elseif not isPlaying and sound.IsPlaying then
				isFadingIn = false
				TweenService:Create(sound, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Volume = 0 }):Play()
				task.delay(0.55, function()
					if not isPlaying then sound:Pause() end
				end)
			end
		end
	end
end

-- ==================== GetBeatLevel ====================
function MusicController.GetBeatLevel()
	return beatLevel
end

return MusicController
