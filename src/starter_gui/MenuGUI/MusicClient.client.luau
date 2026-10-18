local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local ContentProvider   = game:GetService("ContentProvider")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))
local MusicModule = require(Modules:WaitForChild("MusicModule"))

local guiReady = MenuConfig.WaitForGUIReady(15)
if not guiReady then warn("❌ MusicClient: GUI belum siap!"); return end

local player    = Players.LocalPlayer
local musicPage = MenuConfig.GUI.MusicPage

local remoteFolder = ReplicatedStorage:WaitForChild("MusicRemotes", 30)
if not remoteFolder then warn("❌ MusicClient: Folder MusicRemotes tidak ditemukan!"); return end

local dispatchAction = remoteFolder:WaitForChild("DispatchAction", 10)
local dispatchEvent  = remoteFolder:WaitForChild("DispatchEvent",  10)
local musicBroadcast = remoteFolder:WaitForChild("MusicBroadcast", 10)
local musicUpdate    = remoteFolder:WaitForChild("MusicUpdate",    10)
local requestSync    = remoteFolder:WaitForChild("RequestSync",    10)
local getFavorites   = remoteFolder:WaitForChild("GetFavorites",   10)

if not (dispatchAction and dispatchEvent and musicBroadcast) then
	warn("❌ MusicClient: Remote penting tidak ditemukan!"); return
end

local DESYNC_THRESHOLD    = 0.5
local CLIENT_FADE_IN_DUR  = 0.40
local CLIENT_FADE_OUT_DUR = 0.18

local function getPlayerHierarchy()
	local roleValue = player:FindFirstChild("Role")
	if roleValue and roleValue:IsA("StringValue") then
		local hierarchy = { Owner=7, Developer=6, Admin=5, Streamer=4, Creator=3, VIP=2, Guest=1 }
		return hierarchy[roleValue.Value] or 1, roleValue.Value
	end
	return 1, "Guest"
end

local function isAdminPlus() return getPlayerHierarchy() >= 5 end
local function isVIPPlus()   return getPlayerHierarchy() >= 2 end

local function dispatch(actionType, payload)
	dispatchAction:FireServer({ type = actionType, payload = payload or {} })
end

local function getColor(name, fallback)
	return (ThemeModule and ThemeModule.Colors[name]) or fallback
end

local C = {
	SubTabActive       = Color3.fromHex("#FFFFFF"),
	SubTabInactive     = Color3.fromHex("#121212"),
	SubTabDisabled     = Color3.fromHex("#181818"),
	SubTabText         = Color3.fromHex("#8E8E93"),
	SubTabTextActive   = Color3.fromHex("#111111"),
	SubTabTextDisabled = Color3.fromHex("#4D4D4D"),
	NowPlayingBg       = Color3.fromHex("#151515"),
	ThumbnailBg        = Color3.fromHex("#080808"),
	SongNameText       = Color3.fromHex("#FFFFFF"),
	RequesterText      = Color3.fromHex("#E2E8F0"),
	DurationText       = Color3.fromHex("#888888"),
	FavoriteBtn        = Color3.fromHex("#FFFFFF"),
	FavBtnDisabled     = Color3.fromHex("#353535"),
	AutoplayText       = Color3.fromHex("#FFFFFF"),
	ProgressBg         = Color3.fromHex("#080808"),
	ProgressFill       = Color3.fromHex("#FFFFFF"),
	MuteBtn            = Color3.fromHex("#222222"),
	MuteBtnActive      = Color3.fromHex("#FFFFFF"),
	MuteBtnText        = Color3.fromHex("#FFFFFF"),
	MuteBtnTextActive  = Color3.fromHex("#111111"),
	AddBtn             = Color3.fromHex("#262626"),
	BtnText            = Color3.fromHex("#FFFFFF"),
	VoteYesBtn         = Color3.fromHex("#FFFFFF"),
	VoteNoBtn          = Color3.fromHex("#2E2E2E"),
	VoteBg             = Color3.fromHex("#151515"),
	InputBg            = Color3.fromHex("#121212"),
	InputText          = Color3.fromHex("#FFFFFF"),
	QueueBg            = Color3.fromHex("#0F0F0F"),
	QueueItem          = Color3.fromHex("#151515"),
	QueueSongText      = Color3.fromHex("#FFFFFF"),
	QueueRequester     = Color3.fromHex("#8E8E93"),
	ScrollBar          = Color3.fromHex("#353535"),
	SongsBg            = Color3.fromHex("#0F0F0F"),
	SongsItem          = Color3.fromHex("#151515"),
	SongText           = Color3.fromHex("#FFFFFF"),
	FavBg              = Color3.fromHex("#0F0F0F"),
	FavItem            = Color3.fromHex("#151515"),
	FavSongText        = Color3.fromHex("#FFFFFF"),
	FavThumb           = Color3.fromHex("#080808"),
	FavPlayBtn         = Color3.fromHex("#222222"),
	FavRemoveBtn       = Color3.fromHex("#202020"),
	FavBtnText         = Color3.fromHex("#FFFFFF"),
	FavLocked          = Color3.fromHex("#888888"),
	ClearBtn           = Color3.fromHex("#222222"),
	Border             = Color3.fromHex("#242424"),
}

local T = {
	SubTabPlayer      = "🎧  Pemutar",
	SubTabSongs       = "🎵  Lagu",
	SubTabFavorites   = "⭐  Favorit",
	SubTabFavLocked   = "🔒  Favorit",
	NoSongPlaying     = "Tidak ada lagu diputar",
	RequestedBy       = "Diminta: ",
	AutoplayLabel     = "🎵  Autoplay",
	QueueTitle        = "📋  Antrean Lagu",
	QueueEmpty        = "Antrean Kosong",
	QueueEmptySub     = "Autoplay aktif — Lagu diputar otomatis oleh sistem",
	DefaultSongs      = "🎵  Lagu Tersedia",
	MyFavorites       = "⭐  Favorit Saya",
	FavoritesLocked   = "Fitur Khusus VIP+",
	FavoritesLockedSub= "Simpan daftar lagu favoritmu tanpa batas dengan status VIP ke atas.",
	FavEmpty          = "Belum Ada Lagu Favorit",
	FavEmptySub       = "Tekan tombol bintang (★) pada Pemutar untuk menyimpan lagu di sini.",
	DurationFormat    = "%s / %s",
	Unknown           = "Tidak Diketahui",
	MuteBtn           = "🔊  Mute Musik",
	UnmuteBtn         = "🔇  Bunyikan Musik",
	StatusLive        = "● LIVE BEAT-REACTIVE",
	StatusIdle        = "○ GLOBAL MUSIC IDLE",
	VoteYes           = "✓  Ya",
	VoteNo            = "X  Tidak",
	AddFavorite       = "★",
	AddToQueue        = "+ Antre",
	SongIDPlaceholder = "🎵  Masukkan ID lagu Roblox (cth: 1843404007)...",
	Remove            = "x",
	SuccessTitle      = "Sukses",
	ErrorTitle        = "Error",
	WarningTitle      = "Peringatan",
	VIPRequired       = "VIP+ Required",
	MusicTitle        = "Musik",
	SearchTitle       = "Pencarian",
	NoSongToSkip      = "Tidak ada lagu yang sedang diputar!",
	SearchPlaceholder = "🔍  Cari lagu berdasarkan judul...",
}

local DEFAULT_THUMBNAIL = "rbxassetid://118306547253139"

local function resolveThumbnail(thumb, soundId)
	if not thumb or type(thumb) ~= "string" then
		return DEFAULT_THUMBNAIL
	end

	local t = thumb:gsub("%s", "")
	if t == "" or t == "0" or t == "rbxassetid://0" or t:find("YOUR_LOGO_ASSET_ID") then
		return DEFAULT_THUMBNAIL
	end

	if t:find("^rbxassetid://") or t:find("^rbxthumb://") or t:find("^http") or t:find("^rbxasset://") then
		return t
	end

	if t:match("^%d+$") then
		if t == "0" or tonumber(t) == 0 then
			return DEFAULT_THUMBNAIL
		end
		return "rbxassetid://" .. t
	end

	return DEFAULT_THUMBNAIL
end

local DIM = {
	SUBTAB_H           = 36,
	NP_H               = 388,
	THUMB_SZ           = 70,
	PROGRESS_H         = 5,
	CONTROLS_H         = 32,
	VOTE_H             = 62,
	REQ_H              = 40,
	REQ_BTN_W          = 84,
	QTITLE_H           = 26,
	QUEUE_H            = 150,
	QUEUE_ITEM_H       = 44,
	SONG_ITEM_H        = 46,
	FAV_ITEM_H         = 50,
	FAV_THUMB_SZ       = 38,
	SEARCH_H           = 38,
	CLEAR_BTN_W        = 32,
	PAD                = 8,
	CORNER_SM          = 6,
	CORNER_MD          = 8,
	CORNER_LG          = 10,
	SCROLL_PAD         = 6,
	QUEUE_CARD_H       = 40 + 8 + 26 + 6 + 150 + 16,
	PLAYLIST_CARD_H    = 140,
	PLAYLIST_SECTION_H = 26 + 8 + 156 + 20,
	SEARCH_SECTION_H   = 38 + 16,
}

local UI = {
	navButtons     = {},
	visualizerBars = {},
	filterButtons  = {},
	playlistCards  = {},
}

local function getPlaylistThumbnailByName(playlistName)
	if not playlistName or playlistName == "" then return nil end
	local lower = string.lower(playlistName)
	if lower == "favorites" or lower == "favorit saya" then
		return "81579105803685"
	end
	local playlists = MusicModule:GetPlaylists()
	for _, pl in ipairs(playlists) do
		if pl.name and string.lower(pl.name) == lower then
			if pl.thumbnail and pl.thumbnail ~= "" then
				return pl.thumbnail
			end
		end
	end
	return nil
end

local function getSongThumbnail(song)
	if not song then return DEFAULT_THUMBNAIL end
	local pName = song.playlistName or song.PlaylistName
	local sId = tostring(song.id or song.SoundId or song.sound_id or "")

	if (not pName or pName == "") and sId ~= "" then
		for _, pl in ipairs(MusicModule:GetPlaylists()) do
			if pl.tracks then
				for _, trk in ipairs(pl.tracks) do
					local trkId = tostring(trk.id or trk.sound_id or trk.SoundId or "")
					if trkId == sId then
						pName = pl.name
						break
					end
				end
			end
			if pName then break end
		end
	end

	if pName and pName ~= "" then
		local plThumb = getPlaylistThumbnailByName(pName)
		if plThumb and plThumb ~= "" then
			return resolveThumbnail(plThumb)
		end
	end

	local direct = song.sampul or song.thumbnail or song.Thumbnail or song.Sampul
	if direct and direct ~= "" then
		return resolveThumbnail(direct)
	end

	return DEFAULT_THUMBNAIL
end

local function setThumb(url, soundId)
	if not UI.thumbImg then return end
	local resolved = resolveThumbnail(url, soundId)
	if UI.thumbImg.Image == resolved then return end
	if resolved == DEFAULT_THUMBNAIL then
		UI.thumbImg.Image = DEFAULT_THUMBNAIL
		return
	end

	local currentTarget = resolved
	UI.thumbImg.Image = resolved
	task.spawn(function()
		task.wait(8)
		if UI.thumbImg and UI.thumbImg.Image == currentTarget and not UI.thumbImg.IsLoaded then
			UI.thumbImg.Image = DEFAULT_THUMBNAIL
		end
	end)
end

local function addCorner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or DIM.CORNER_SM); c.Parent = p; return c
end
local function addStroke(p, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = color or Color3.fromHex("#242424")
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function addSC(p, mx, mn)
	local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = mx; c.MinTextSize = mn or 8; c.Parent = p; return c
end
local function addGradient(parent, rotation, animated)
	if ThemeModule then
		if animated then return ThemeModule.CreatePrimaryGradient(parent, rotation or 90)
		else return ThemeModule.CreateStaticGradient(parent, "Primary", rotation or 90) end
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#151515")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")), ColorSequenceKeypoint.new(1, Color3.fromHex("#353535")) })
	g.Rotation = rotation or 90; g.Parent = parent; return g
end
local function addTextGradient(lbl, animated)
	if ThemeModule then
		if animated then return ThemeModule.CreatePrimaryGradient(lbl, 0, 1.5)
		else return ThemeModule.CreateStaticGradient(lbl, "Primary", 0) end
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")), ColorSequenceKeypoint.new(1, Color3.fromHex("#888888")) })
	g.Rotation = 0; g.Parent = lbl; return g
end
local function removeGradient(p)
	local g = p:FindFirstChildOfClass("UIGradient")
	if g then if ThemeModule and ThemeModule.GradientSystem then ThemeModule.GradientSystem.Unregister(g) end; g:Destroy() end
end
local function setupFixedScroll(sf)
	sf.Active = true
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.AutomaticCanvasSize = Enum.AutomaticSize.None
	sf.HorizontalScrollBarInset = Enum.ScrollBarInset.None

	sf.VerticalScrollBarInset = Enum.ScrollBarInset.None
	sf.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
end
local function setupAutoScroll(sf)
	sf.Active = true
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.CanvasSize = UDim2.new(0,0,0,0)
	sf.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	sf.VerticalScrollBarInset = Enum.ScrollBarInset.None
	sf.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
end
local function fmtTime(sec)
	if not sec or sec <= 0 then return "0:00" end
	return string.format("%d:%02d", math.floor(sec/60), math.floor(sec%60))
end

local function notifySuccess(t,m) if NotifModule then NotifModule.Success(t,m,3) end end
local function notifyError(t,m)   if NotifModule then NotifModule.Error(t,m,3) end end
local function notifyWarning(t,m) if NotifModule then NotifModule.Warning(t,m,3) end end
local function notifyInfo(t,m)    if NotifModule then NotifModule.Info(t,m,3) end end

local clientState = {
	queue           = {},
	currentSong     = nil,
	currentUploader = nil,
	isPlaying       = false,
	duration        = 0,
	isAutoplay      = false,
	serverStartTime = 0,
}

local function cleanMusicId(raw)
	if not raw then return "" end
	local s = tostring(raw):gsub("%s+", "")
	return s:match("%d+") or s
end

local function isSongInQueue(targetId)
	local cleanTarget = cleanMusicId(targetId)
	if cleanTarget == "" then return false end
	for _, item in ipairs(clientState.queue or {}) do
		local mData = item.musicData or item
		local rawId = mData and (mData.id or mData.sound_id)
		if rawId and cleanMusicId(rawId) == cleanTarget then
			return true
		end
	end
	return false
end

local currentSubTab      = "player"
local currentTimePos     = 0
local currentTimeLen     = 0
local userFavorites      = {}
local defaultSongs       = {}
local filteredSongs      = {}
local currentSearchQuery = ""
local lastNoResults      = 0
local canFavorite        = false
local activePlaylistType = ""

local updatePlaylistCardsState
local rebuildPlaylistCards

local function getActiveSongList()
	if activePlaylistType == "favorites" then
		return userFavorites
	elseif activePlaylistType and activePlaylistType ~= "" then
		local songs = MusicModule:GetSongsByPlaylist(activePlaylistType)
		return songs or {}
	else
		local playlists = MusicModule:GetPlaylists()
		if #playlists > 0 and playlists[1].name then
			activePlaylistType = playlists[1].name
			return playlists[1].tracks or {}
		end
		return {}
	end
end

local voteSkipState = {
	active        = false,
	yesVotes      = 0,
	noVotes       = 0,
	required      = 2,
	timeRemaining = 30,
	hasVoted      = false,
}

local isMuted    = false
local userVolume = 0.5
local currentFadeTween = nil

local function cancelClientFade()
	if currentFadeTween then
		currentFadeTween:Cancel()
		currentFadeTween = nil
	end
end

local function cleanupAudioAPINodes()
	local toDestroy = {
		"ClientMusicFader",
		"ClientAudioOutput",
		"ServerAudioPlayer",
		"ServerAudioFader",
		"FiestaAudioEqualizer",
	}
	for _, name in ipairs(toDestroy) do
		local node = SoundService:FindFirstChild(name)
		if node then
			pcall(function() node:Destroy() end)
		end
	end
	local camera = workspace.CurrentCamera
	if camera then
		local oldListener = camera:FindFirstChild("ClientMusicListener")
		if oldListener then
			pcall(function() oldListener:Destroy() end)
		end
	end
end
task.spawn(cleanupAudioAPINodes)

local function getServerSound(waitSec)
	local s = SoundService:FindFirstChild("ServerMusicSound")
	if s and s:IsA("Sound") then
		s.Looped = false
		return s
	end
	local wsSound = workspace:FindFirstChild("ServerMusicSound", true)
	if wsSound and wsSound:IsA("Sound") then
		wsSound.Looped = false
		return wsSound
	end
	if waitSec and waitSec > 0 then
		local waited = SoundService:WaitForChild("ServerMusicSound", waitSec)
		if waited and waited:IsA("Sound") then
			waited.Looped = false
			return waited
		end
	end
	return nil
end

pcall(function()
	SoundService:SetListener(Enum.ListenerType.Camera)
end)

local function getMusicGroup()
	return SoundService:FindFirstChild("mainEffects") or SoundService:FindFirstChild("MusicGroup")
end

local isSyncing = true
local hasInitialSynced = false
local currentSyncId = 0

local function applyVolume()
	if isSyncing or not hasInitialSynced then return end
	cancelClientFade()
	local musicGroup = getMusicGroup()
	if musicGroup and musicGroup:IsA("SoundGroup") then
		musicGroup.Volume = isMuted and 0 or userVolume
	end
	local ss = getServerSound()
	if ss and ss:IsA("Sound") and musicGroup then
		if ss.SoundGroup ~= musicGroup then
			ss.SoundGroup = musicGroup
		end
	end
end

local function clientFadeIn(duration)
	if isMuted then return end
	cancelClientFade()
	local musicGroup = getMusicGroup()
	if not musicGroup or not musicGroup:IsA("SoundGroup") then return end
	local dur = duration or CLIENT_FADE_IN_DUR
	local tween = TweenService:Create(
		musicGroup,
		TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Volume = userVolume }
	)
	currentFadeTween = tween
	tween:Play()
end

local function clientFadeOut(duration)
	cancelClientFade()
	local musicGroup = getMusicGroup()
	if not musicGroup or not musicGroup:IsA("SoundGroup") then return end
	local dur = duration or CLIENT_FADE_OUT_DUR
	local tween = TweenService:Create(
		musicGroup,
		TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Volume = 0 }
	)
	currentFadeTween = tween
	tween:Play()
end

local function calculateSyncPosition(serverStartTime, duration)
	if not serverStartTime or serverStartTime <= 0 then return 0 end
	local now = workspace:GetServerTimeNow()
	local elapsed = now - serverStartTime
	if elapsed < 0 then return 0 end
	local ss = getServerSound()
	local realMax = (ss and ss:IsA("Sound") and ss.TimeLength > 0) and ss.TimeLength or (duration > 0 and duration or 9999)
	return math.clamp(elapsed, 0, realMax)
end

local lastDriftCorrection = 0
local function gentleDriftCorrect(serverStartTime, duration)
	if isSyncing or isMuted then return end
	local now = workspace:GetServerTimeNow()
	if (now - lastDriftCorrection) < 8 then return end

	local serverSound = getServerSound()
	if not serverSound or not serverSound:IsA("Sound") or not serverSound.IsPlaying then return end

	local expectedPos = calculateSyncPosition(serverStartTime, duration)
	local actualPos = serverSound.TimePosition
	local drift = math.abs(expectedPos - actualPos)

	if drift > 0.5 then
		local maxLen = (serverSound.TimeLength > 0) and serverSound.TimeLength or duration
		if expectedPos > 0 and (maxLen <= 0 or expectedPos < maxLen - 0.5) then
			pcall(function()
				serverSound.TimePosition = expectedPos
			end)
			lastDriftCorrection = now
		end
	end
end

local function syncServerSoundPosition(expectedSoundId, serverStartTime, duration, isNewSong)
	local ss = getServerSound(2.5)
	if not ss or not ss:IsA("Sound") then
		isSyncing = false
		hasInitialSynced = true
		return
	end

	local musicGroup = getMusicGroup()
	if musicGroup and ss.SoundGroup ~= musicGroup then
		ss.SoundGroup = musicGroup
	end

	pcall(function()
		ss.PlaybackSpeed = 1.0
	end)

	local curStartTime = clientState.serverStartTime or serverStartTime or 0
	local curDuration = clientState.duration or duration or currentTimeLen or 0
	local targetSoundId = expectedSoundId and ("rbxassetid://" .. tostring(expectedSoundId))

	if not isNewSong and hasInitialSynced and ss.IsPlaying and ss.IsLoaded
		and (not targetSoundId or ss.SoundId == targetSoundId) and curStartTime > 0 then
		local expectedPos = workspace:GetServerTimeNow() - curStartTime
		if math.abs(ss.TimePosition - expectedPos) < 0.15 then
			isSyncing = false
			return
		end
	end

	currentSyncId = currentSyncId + 1
	local mySyncId = currentSyncId

	isSyncing = true
	cancelClientFade()
	if musicGroup and musicGroup:IsA("SoundGroup") then
		musicGroup.Volume = 0
	end

	task.spawn(function()
		local function finishSync()
			if mySyncId == currentSyncId then
				isSyncing = false
				hasInitialSynced = true
				if not isMuted then
					clientFadeIn(CLIENT_FADE_IN_DUR)
				end
			end
		end

		task.delay(6.0, function()
			if mySyncId == currentSyncId and isSyncing then
				finishSync()
			end
		end)

		if targetSoundId then
			local t0 = os.clock()
			while ss.SoundId ~= targetSoundId and (os.clock() - t0) < 3.0 do
				task.wait(0.03)
				if mySyncId ~= currentSyncId then return end
			end
		end

		local t1 = os.clock()
		while (not ss.IsLoaded or ss.TimeLength <= 0 or not ss.IsPlaying) and (os.clock() - t1) < 5.0 do
			task.wait(0.03)
			if mySyncId ~= currentSyncId then return end
		end

		if ss.TimeLength > 0 and clientState.duration ~= ss.TimeLength then
			clientState.duration = ss.TimeLength
			currentTimeLen = ss.TimeLength
			if clientState.currentSong then
				clientState.currentSong.Duration = ss.TimeLength
			end
		end

		if clientState.isPlaying and ss.IsLoaded and not ss.IsPlaying then
			pcall(function() ss:Play() end)
		end

		local startT = clientState.serverStartTime or serverStartTime or curStartTime or 0
		if startT > 0 then
			local realMax = (ss.TimeLength > 0) and ss.TimeLength or curDuration
			local expectedPos = workspace:GetServerTimeNow() - startT
			if expectedPos >= 0 and (realMax <= 0 or expectedPos < realMax - 0.5) then
				if math.abs(ss.TimePosition - expectedPos) > 0.08 then
					pcall(function()

						ss.TimePosition = expectedPos + 0.05
					end)
					task.wait(0.08)
					if mySyncId ~= currentSyncId then return end
				end
			end
		end

		lastDriftCorrection = workspace:GetServerTimeNow()
		finishSync()
	end)
end

local function getViewportHeight()
	local panelH = 450
	local headerH = 46
	if MenuConfig and MenuConfig.Config then
		if MenuConfig.Config.PanelSize and MenuConfig.Config.PanelSize.Height then
			panelH = MenuConfig.Config.PanelSize.Height
		end
		if MenuConfig.Config.HeaderHeight then
			headerH = MenuConfig.Config.HeaderHeight
		end
	end
	local mainPanel = MenuConfig.GUI and MenuConfig.GUI.MainPanel
	if mainPanel and mainPanel.Size.Y.Offset > 0 then
		panelH = mainPanel.Size.Y.Offset
	end
	return math.max(388, panelH - headerH - 16)
end

local updateMusicLayout
updateMusicLayout = function()
	if not UI.musicScroll then return end
	local winH = getViewportHeight()
	local curY = 0

	if UI.nowPlayingFrame then
		UI.nowPlayingFrame.Position = UDim2.new(0, 0, 0, 0)
		UI.nowPlayingFrame.Size     = UDim2.new(1, 0, 0, winH)
		curY = winH + DIM.PAD
	end

	if UI.queueSection then
		UI.queueSection.Position = UDim2.new(0, 0, 0, curY)
		UI.queueSection.Size     = UDim2.new(1, 0, 0, DIM.QUEUE_CARD_H)
		curY = curY + DIM.QUEUE_CARD_H + DIM.PAD
	end

	if UI.playlistSection then
		UI.playlistSection.Position = UDim2.new(0, 0, 0, curY)
		UI.playlistSection.Size     = UDim2.new(1, 0, 0, DIM.PLAYLIST_SECTION_H)
		curY = curY + DIM.PLAYLIST_SECTION_H + DIM.PAD
	end

	if UI.searchSection then
		UI.searchSection.Position = UDim2.new(0, 0, 0, curY)
		UI.searchSection.Size     = UDim2.new(1, 0, 0, DIM.SEARCH_SECTION_H)
		curY = curY + DIM.SEARCH_SECTION_H + DIM.PAD
	end

	if UI.librarySection and UI.songsContainer then
		UI.librarySection.Position = UDim2.new(0, 0, 0, curY)
		local libContentH = 32 + UI.songsContainer.Size.Y.Offset + 14
		UI.librarySection.Size = UDim2.new(1, 0, 0, math.max(160, libContentH))
		curY = curY + UI.librarySection.Size.Y.Offset + DIM.PAD + 10
	end

	UI.musicScroll.CanvasSize = UDim2.new(0, 0, 0, curY)
end

local function scrollToSection(targetY)
	if not UI.musicScroll then return end
	local maxScroll = math.max(0, UI.musicScroll.CanvasSize.Y.Offset - UI.musicScroll.AbsoluteWindowSize.Y)
	local clampedY = math.clamp(targetY, 0, maxScroll)
	TweenService:Create(UI.musicScroll, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CanvasPosition = Vector2.new(0, clampedY),
	}):Play()
end

local function updateProgressBar(timePos, timeLen)
	currentTimePos = timePos or 0
	currentTimeLen = timeLen or 0
	if not UI.progressFill then return end
	if timeLen and timeLen > 0 then
		local progress = math.clamp(timePos / timeLen, 0, 1)
		TweenService:Create(UI.progressFill, TweenInfo.new(0.15, Enum.EasingStyle.Linear), { Size = UDim2.new(progress,0,1,0) }):Play()
		if UI.durationLbl then
			UI.durationLbl.Text    = string.format(T.DurationFormat, fmtTime(timePos), fmtTime(timeLen))
			UI.durationLbl.Visible = true
		end
		if UI.progressDot then
			UI.progressDot.Visible = true
		end
	else
		UI.progressFill.Size = UDim2.new(0,0,1,0)
		if UI.durationLbl then UI.durationLbl.Visible = false end
		if UI.progressDot then UI.progressDot.Visible = false end
	end
end

local isRealBeat = false
local beatIntensity = 0
local loudnessAvg = 0
local lastBeatTime = 0

local function updateBeatAnalysis(dt, now)
	local serverSound = getServerSound()
	local realLoudness = 0
	if serverSound and serverSound.IsPlaying then
		local ok, loudness = pcall(function() return serverSound.PlaybackLoudness end)
		if ok and type(loudness) == "number" then
			realLoudness = loudness
		end
	end

	if realLoudness > 5 then
		isRealBeat = true
		loudnessAvg = (loudnessAvg * 0.92) + (realLoudness * 0.08)
		local threshold = math.max(loudnessAvg * 1.30, 95)
		if realLoudness > threshold and (now - lastBeatTime) > 0.16 then
			local hit = math.clamp((realLoudness - threshold) / 200, 0.4, 1.0)
			beatIntensity = math.max(beatIntensity, hit)
			lastBeatTime = now
		else
			beatIntensity = math.max(0, beatIntensity - (dt * 4.2))
		end
	else
		isRealBeat = false
		if clientState.isPlaying then
			beatIntensity = ((math.sin(now * 5.2) + 1) * 0.5) * 0.35
		else
			beatIntensity = math.max(0, beatIntensity - (dt * 5.0))
		end
	end

	if ThemeModule and ThemeModule.GradientSystem and ThemeModule.GradientSystem.SetBeat then
		ThemeModule.GradientSystem.SetBeat(1.0 + (beatIntensity * 1.5))
	end
end

local progressConn = nil
local function startProgressLoop()
	if progressConn then return end
	progressConn = RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		updateBeatAnalysis(dt, now)
		if clientState.isPlaying and clientState.serverStartTime > 0 then
			local ss = getServerSound()
			if ss and ss:IsA("Sound") and ss.TimeLength > 0 and clientState.duration ~= ss.TimeLength then
				clientState.duration = ss.TimeLength
				currentTimeLen = ss.TimeLength
				if clientState.currentSong then
					clientState.currentSong.Duration = ss.TimeLength
				end
			end
			local syncPos = calculateSyncPosition(clientState.serverStartTime, clientState.duration)
			updateProgressBar(syncPos, clientState.duration)
		end
		local barShapes = { 0.45, 0.75, 1.0, 0.85, 0.65, 0.90, 0.50 }
		for i, bar in ipairs(UI.visualizerBars) do
			local mult = barShapes[i] or 0.7
			local wave = (math.sin(now * 8 + i * 0.9) + 1) * 0.5
			local h = math.clamp(math.floor(3 + (wave * 8 * mult) + (beatIntensity * 9 * mult)), 2, 16)
			bar.Size = UDim2.new(0, 5, 0, h)
		end
		if UI.npStrokeGrad then
			UI.npStrokeGrad.Rotation = (now * 60) % 360
		end
	end)
end

local function stopProgressLoop()
	if progressConn then
		progressConn:Disconnect()
		progressConn = nil
	end
end

local voteCountdownConn = nil

local function updateVoteSkipUI()
	if not UI.voteSkipPanel then return end
	if voteSkipState.active then
		UI.voteSkipPanel.Visible = true
		local req = math.max(1, voteSkipState.required or 1)
		local yes = voteSkipState.yesVotes or 0
		if UI.voteInfoLbl then
			UI.voteInfoLbl.Text = string.format("Vote Skip: %d/%d (%ds)", yes, req, math.max(0, voteSkipState.timeRemaining or 0))
		end
		if UI.skipBtn then
			UI.skipBtn.Text = string.format("%d/%d", yes, req)
			UI.skipBtn.TextColor3 = Color3.fromHex("#60A5FA")
		end

		if voteSkipState.hasVoted then
			if UI.voteYesBtn then UI.voteYesBtn.Visible = false end
			if UI.voteNoBtn then UI.voteNoBtn.Visible = false end
			if UI.voteStatusLbl then UI.voteStatusLbl.Visible = true end
		else
			if UI.voteYesBtn then UI.voteYesBtn.Visible = true end
			if UI.voteNoBtn then UI.voteNoBtn.Visible = true end
			if UI.voteStatusLbl then UI.voteStatusLbl.Visible = false end
		end
	else
		UI.voteSkipPanel.Visible = false
		if UI.skipBtn then
			UI.skipBtn.Text = "⏭"
			UI.skipBtn.TextColor3 = Color3.fromHex("#FFFFFF")
		end
		if voteCountdownConn then
			task.cancel(voteCountdownConn)
			voteCountdownConn = nil
		end
	end
end

local function updateSkipButton()
	local hasSong = (clientState.currentSong ~= nil and clientState.isPlaying)
	if UI.skipBtn then UI.skipBtn.Visible = hasSong end
	if not hasSong then
		if UI.voteSkipPanel then UI.voteSkipPanel.Visible = false end
		if voteCountdownConn then
			task.cancel(voteCountdownConn)
			voteCountdownConn = nil
		end
	end
end

local function updateFavoriteUI()
	canFavorite = isVIPPlus()
	if UI.favSubLbl then
		UI.favSubLbl.Text = canFavorite and string.format("%d Lagu Favorit", #userFavorites) or "Fitur Khusus VIP+"
	end
	if UI.addFavBtn then
		if canFavorite then
			UI.addFavBtn.BackgroundColor3 = Color3.fromHex("#1C1C1C")
			UI.addFavBtn.TextColor3       = Color3.fromHex("#FFFFFF")
		else
			UI.addFavBtn.BackgroundColor3 = Color3.fromHex("#141414")
			UI.addFavBtn.TextColor3       = Color3.fromHex("#555555")
		end
	end
end

local function updateQueue()
	if not UI.queueScroll then return end
	for _, c in ipairs(UI.queueScroll:GetChildren()) do
		if c:IsA("Frame") and c ~= UI.queueEmptyFrame then c:Destroy() end
	end
	local queue = clientState.queue or {}
	local isEmpty = (#queue == 0)
	if UI.queueEmptyFrame then UI.queueEmptyFrame.Visible = isEmpty end
	if UI.queueBadge then
		UI.queueBadge.Text = isEmpty and "Autoplay" or string.format("%d Lagu", #queue)
		UI.queueBadge.TextColor3 = isEmpty and Color3.fromHex("#9E9E9E") or Color3.fromHex("#FFFFFF")
	end
	if isEmpty then return end

	for i, song in ipairs(queue) do
		local songData = song.musicData or song
		local item = Instance.new("Frame")
		item.Name = "QI_"..i
		item.Size = UDim2.new(1, 0, 0, DIM.QUEUE_ITEM_H)
		item.BackgroundColor3 = Color3.fromHex("#151515")
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.ClipsDescendants = true
		item.Parent = UI.queueScroll
		addCorner(item, DIM.CORNER_MD)
		local itemStroke = addStroke(item, Color3.fromHex("#242424"), 1, 0)

		local rankFrame = Instance.new("Frame")
		rankFrame.Name = "Rank"
		rankFrame.Size = UDim2.new(0, 24, 0, 24)
		rankFrame.Position = UDim2.new(0, 8, 0.5, -12)
		rankFrame.BackgroundColor3 = Color3.fromHex("#202020")
		rankFrame.BorderSizePixel = 0
		rankFrame.Parent = item
		addCorner(rankFrame, 6)
		addStroke(rankFrame, Color3.fromHex("#2E2E2E"), 1, 0)

		local numLbl = Instance.new("TextLabel")
		numLbl.Size = UDim2.new(1, 0, 1, 0)
		numLbl.BackgroundTransparency = 1
		numLbl.Text = tostring(i)
		numLbl.TextColor3 = Color3.fromHex("#D4D4D4")
		numLbl.TextSize = 11
		numLbl.Font = Enum.Font.GothamBold
		numLbl.TextXAlignment = Enum.TextXAlignment.Center
		numLbl.TextYAlignment = Enum.TextYAlignment.Center
		numLbl.Parent = rankFrame

		local dur = tonumber(songData.Duration or songData.duration or song.Duration or song.duration or 0) or 0
		local rightOffset = (dur > 0) and 70 or 10

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -(40 + rightOffset), 0, 20)
		nameLbl.Position = UDim2.new(0, 38, 0, 4)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = songData.judul or T.Unknown
		nameLbl.TextColor3 = Color3.fromHex("#FFFFFF")
		nameLbl.TextSize = 12
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = item
		addSC(nameLbl, 13)

		local reqLbl = Instance.new("TextLabel")
		reqLbl.Size = UDim2.new(1, -(40 + rightOffset), 0, 16)
		reqLbl.Position = UDim2.new(0, 38, 0, 22)
		reqLbl.BackgroundTransparency = 1
		reqLbl.Text = "👤 "..(song.uploader or T.Unknown)
		reqLbl.TextColor3 = Color3.fromHex("#8E8E93")
		reqLbl.TextSize = 10
		reqLbl.Font = Enum.Font.GothamMedium
		reqLbl.TextTruncate = Enum.TextTruncate.AtEnd
		reqLbl.TextXAlignment = Enum.TextXAlignment.Left
		reqLbl.Parent = item

		if dur > 0 then
			local durBadge = Instance.new("TextLabel")
			durBadge.Name = "DurBadge"
			durBadge.Text = fmtTime(dur)
			durBadge.Size = UDim2.new(0, 52, 0, 22)
			durBadge.Position = UDim2.new(1, -60, 0.5, -11)
			durBadge.BackgroundColor3 = Color3.fromHex("#1C1C1C")
			durBadge.BorderSizePixel = 0
			durBadge.TextColor3 = Color3.fromHex("#A3A3A3")
			durBadge.TextSize = 10
			durBadge.Font = Enum.Font.GothamMedium
			durBadge.TextXAlignment = Enum.TextXAlignment.Center
			durBadge.Parent = item
			addCorner(durBadge, 6)
			addStroke(durBadge, Color3.fromHex("#282828"), 1, 0)
		end

		item.MouseEnter:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromHex("#202020"),
			}):Play()
			TweenService:Create(itemStroke, TweenInfo.new(0.15), {
				Color = Color3.fromHex("#3E3E3E"),
			}):Play()
		end)
		item.MouseLeave:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromHex("#151515"),
			}):Play()
			TweenService:Create(itemStroke, TweenInfo.new(0.15), {
				Color = Color3.fromHex("#242424"),
			}):Play()
		end)
	end
end

local function norm(s) return string.lower(string.gsub(s or "","  %s+"," ")) end
local function doSearch(query)
	currentSearchQuery = query
	local sourceList = getActiveSongList() or {}
	if query == "" then
		filteredSongs = sourceList
		return sourceList
	end
	local nq = norm(query)
	local exact, starts, contains = {},{},{}
	for _, song in ipairs(sourceList) do
		local sn = norm(song.judul or song.title or song.name or "")
		if sn == nq then table.insert(exact, song)
		elseif string.sub(sn,1,#nq) == nq then table.insert(starts, song)
		elseif string.find(sn,nq,1,true) then table.insert(contains, song)
		end
	end
	local results = {}
	for _,s in ipairs(exact)    do table.insert(results,s) end
	for _,s in ipairs(starts)   do table.insert(results,s) end
	for _,s in ipairs(contains) do table.insert(results,s) end
	filteredSongs = results
	return results
end

local function updateSongsTitle(searching, count, query)
	if not UI.songsTitleLbl or not UI.songsBadge then return end
	removeGradient(UI.songsTitleLbl)
	if searching and query ~= "" then
		if count > 0 then
			UI.songsTitleLbl.Text = 'Hasil Pencarian'
			UI.songsTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			UI.songsBadge.Text = string.format("%d Hasil", count)
			UI.songsBadge.TextColor3 = Color3.fromHex("#60A5FA")
		else
			UI.songsTitleLbl.Text = 'Tidak Ada Hasil'
			UI.songsTitleLbl.TextColor3 = Color3.fromHex("#EF4444")
			UI.songsBadge.Text = "0 Hasil"
			UI.songsBadge.TextColor3 = Color3.fromHex("#EF4444")
		end
	elseif activePlaylistType == "favorites" then
		UI.songsTitleLbl.Text = T.MyFavorites or "Favorit Saya"
		UI.songsTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		UI.songsBadge.Text = string.format("%d Lagu", count)
		UI.songsBadge.TextColor3 = Color3.fromHex("#9E9E9E")
		addTextGradient(UI.songsTitleLbl, true)
	else
		UI.songsTitleLbl.Text = "📁  " .. tostring(activePlaylistType)
		UI.songsTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		UI.songsBadge.Text = string.format("%d Lagu", count)
		UI.songsBadge.TextColor3 = Color3.fromHex("#9E9E9E")
		addTextGradient(UI.songsTitleLbl, true)
	end
end

local function saveFavorites()
	dispatch("SAVE_FAVORITES", { favorites = userFavorites })
end

local function loadFavorites()
	local data = nil
	if getFavorites then
		local ok, res = pcall(function() return getFavorites:InvokeServer() end)
		if ok and type(res) == "table" and #res > 0 then
			data = res
		end
	end
	if not data then
		local raw = player:GetAttribute("MusicFavorites")
		if raw and type(raw) == "string" then
			local ok, res = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
			if ok and type(res) == "table" then data = res end
		end
	end
	userFavorites = data or {}
	if UI.favSubLbl then
		UI.favSubLbl.Text = canFavorite and string.format("%d Lagu Favorit", #userFavorites) or "Fitur Khusus VIP+"
	end
	updateFavoriteUI()
end

local function updateSongs(list)
	if not UI.songsContainer then return end
	local isFavView = (activePlaylistType == "favorites")
	local sourceList = getActiveSongList() or {}
	local display = list or filteredSongs
	if #display == 0 and currentSearchQuery == "" then display = sourceList end

	for _, c in ipairs(UI.songsContainer:GetChildren()) do
		if c:IsA("Frame") and c ~= UI.noResultsFrame and c ~= UI.favEmptyFrame and c ~= UI.favLockedFrame then
			c:Destroy()
		end
	end

	updateSongsTitle(currentSearchQuery ~= "", #display, currentSearchQuery)

	if isFavView and not canFavorite then
		if UI.favLockedFrame then UI.favLockedFrame.Visible = true end
		if UI.favEmptyFrame then UI.favEmptyFrame.Visible = false end
		if UI.noResultsFrame then UI.noResultsFrame.Visible = false end
		UI.songsContainer.Size = UDim2.new(1, 0, 0, 150)
		task.defer(updateMusicLayout)
		return
	end
	if UI.favLockedFrame then UI.favLockedFrame.Visible = false end

	if isFavView and #userFavorites == 0 then
		if UI.favEmptyFrame then UI.favEmptyFrame.Visible = true end
		if UI.noResultsFrame then UI.noResultsFrame.Visible = false end
		UI.songsContainer.Size = UDim2.new(1, 0, 0, 140)
		task.defer(updateMusicLayout)
		return
	end
	if UI.favEmptyFrame then UI.favEmptyFrame.Visible = false end

	local isNoSearch = (#display == 0 and currentSearchQuery ~= "")
	if UI.noResultsFrame then UI.noResultsFrame.Visible = isNoSearch end
	if isNoSearch then
		UI.songsContainer.Size = UDim2.new(1, 0, 0, 130)
		if tick() - lastNoResults > 3 then
			lastNoResults = tick()
			notifyWarning(T.SearchTitle, 'Tidak ada lagu untuk "'..currentSearchQuery..'"')
		end
		task.defer(updateMusicLayout)
		return
	end

	local totalSongsH = #display * (DIM.SONG_ITEM_H + 4)
	UI.songsContainer.Size = UDim2.new(1, 0, 0, totalSongsH)

	for idx, song in ipairs(display) do
		local songName = song.judul or song.name or T.Unknown
		local songId = tostring(song.id or song.sound_id or song.SoundId or "")
		local isCurrentPlaying = (clientState.isPlaying and clientState.currentSong and tostring(clientState.currentSong.id) == songId)

		local item = Instance.new("Frame")
		item.Name = "SI_"..idx
		item.Size = UDim2.new(1, 0, 0, DIM.SONG_ITEM_H)
		item.BackgroundColor3 = isCurrentPlaying and Color3.fromHex("#1A1A1A") or Color3.fromHex("#151515")
		item.BorderSizePixel = 0
		item.LayoutOrder = idx
		item.ClipsDescendants = true
		item.Parent = UI.songsContainer
		addCorner(item, DIM.CORNER_MD)
		local itemStroke = addStroke(item, isCurrentPlaying and Color3.fromHex("#4A4A4A") or Color3.fromHex("#242424"), 1, 0)

		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.new(0, 36, 0, 36)
		thumb.Position = UDim2.new(0, 6, 0.5, -18)
		thumb.BackgroundColor3 = Color3.fromHex("#080808")
		thumb.BorderSizePixel = 0
		thumb.ScaleType = Enum.ScaleType.Crop
		thumb.Image = getSongThumbnail(song)
		thumb.Parent = item
		addCorner(thumb, DIM.CORNER_SM)
		addStroke(thumb, Color3.fromHex("#282828"), 1, 0)

		local infoLeft = 48
		local rightSpace = isFavView and 115 or 85

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = songName
		nameLbl.Size = UDim2.new(1, -(infoLeft + rightSpace), 0, 20)
		nameLbl.Position = UDim2.new(0, infoLeft, 0, 4)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = Color3.fromHex("#FFFFFF")
		nameLbl.TextSize = 12
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Parent = item
		addSC(nameLbl, 13)

		local subLbl = Instance.new("TextLabel")
		if isCurrentPlaying then
			subLbl.Text = "▶  Sedang Diputar"
			subLbl.TextColor3 = Color3.fromHex("#10B981")
		elseif isFavView then
			subLbl.Text = "⭐  Tersimpan di Favorit"
			subLbl.TextColor3 = Color3.fromHex("#8E8E93")
		else
			subLbl.Text = song.playlistName and ("📁  " .. song.playlistName) or "Lagu Pilihan Server"
			subLbl.TextColor3 = Color3.fromHex("#737373")
		end
		subLbl.Size = UDim2.new(1, -(infoLeft + rightSpace), 0, 16)
		subLbl.Position = UDim2.new(0, infoLeft, 0, 23)
		subLbl.BackgroundTransparency = 1
		subLbl.TextSize = 10
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.Font = Enum.Font.GothamMedium
		subLbl.Parent = item

		local btnH = 28
		local pb = Instance.new("TextButton")
		pb.Text = T.AddToQueue
		pb.Size = UDim2.new(0, 64, 0, btnH)
		local pbRight = isFavView and -(64 + btnH + 10) or -72
		pb.Position = UDim2.new(1, pbRight, 0.5, -btnH/2)
		pb.BackgroundColor3 = Color3.fromHex("#222222")
		pb.BorderSizePixel = 0
		pb.TextColor3 = Color3.fromHex("#FFFFFF")
		pb.Font = Enum.Font.GothamBold
		pb.TextSize = 11
		pb.AutoButtonColor = false
		pb.Parent = item
		addCorner(pb, DIM.CORNER_SM)
		local pbStroke = addStroke(pb, Color3.fromHex("#3E3E3E"), 1, 0)

		pb.MouseEnter:Connect(function()
			TweenService:Create(pb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#333333") }):Play()
			TweenService:Create(pbStroke, TweenInfo.new(0.15), { Color = Color3.fromHex("#666666") }):Play()
		end)
		pb.MouseLeave:Connect(function()
			TweenService:Create(pb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#222222") }):Play()
			TweenService:Create(pbStroke, TweenInfo.new(0.15), { Color = Color3.fromHex("#3E3E3E") }):Play()
		end)

		local capSong = song
		pb.MouseButton1Click:Connect(function()
			if not isVIPPlus() then notifyWarning(T.VIPRequired, "Minimum rank VIP untuk menambah lagu!"); return end
			local targetId = cleanMusicId(capSong.id or capSong.sound_id)
			if clientState.currentSong then
				local curId = cleanMusicId(clientState.currentSong.id or clientState.currentSong.sound_id)
				if curId ~= "" and curId == targetId then
					notifyWarning(T.WarningTitle, "Lagu ini sedang diputar!")
					return
				end
			end
			if isSongInQueue(targetId) then
				notifyWarning(T.WarningTitle, "Lagu ini sudah ada di antrean!")
				return
			end
			dispatch("ADD_TO_QUEUE", { musicId = tostring(capSong.id or capSong.sound_id), isFromPlaylist = true })
		end)

		if isFavView then
			local rb = Instance.new("TextButton")
			rb.Text = T.Remove
			rb.Size = UDim2.new(0, btnH, 0, btnH)
			rb.Position = UDim2.new(1, -(btnH + 6), 0.5, -btnH/2)
			rb.BackgroundColor3 = Color3.fromHex("#202020")
			rb.BorderSizePixel = 0
			rb.TextColor3 = Color3.fromHex("#9E9E9E")
			rb.Font = Enum.Font.GothamBold
			rb.TextSize = 12
			rb.AutoButtonColor = false
			rb.Parent = item
			addCorner(rb, DIM.CORNER_SM)
			local rbStroke = addStroke(rb, Color3.fromHex("#333333"), 1, 0)

			rb.MouseEnter:Connect(function()
				TweenService:Create(rb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#3A1A1A"), TextColor3 = Color3.fromHex("#EF4444") }):Play()
				TweenService:Create(rbStroke, TweenInfo.new(0.15), { Color = Color3.fromHex("#DC2626") }):Play()
			end)
			rb.MouseLeave:Connect(function()
				TweenService:Create(rb, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#202020"), TextColor3 = Color3.fromHex("#9E9E9E") }):Play()
				TweenService:Create(rbStroke, TweenInfo.new(0.15), { Color = Color3.fromHex("#333333") }):Play()
			end)

			rb.MouseButton1Click:Connect(function()
				table.remove(userFavorites, idx)
				saveFavorites()
				updateFavoriteUI()
				updateSongs(userFavorites)
				notifySuccess(T.SuccessTitle, '"'..(capSong.judul or capSong.name or "")..'" dihapus dari favorit')
			end)
		end

		item.MouseEnter:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = isCurrentPlaying and Color3.fromHex("#222222") or Color3.fromHex("#1F1F1F"),
			}):Play()
		end)
		item.MouseLeave:Connect(function()
			TweenService:Create(item, TweenInfo.new(0.15), {
				BackgroundColor3 = isCurrentPlaying and Color3.fromHex("#1A1A1A") or Color3.fromHex("#151515"),
			}):Play()
		end)
	end

	task.defer(updateMusicLayout)
end

local function selectPlaylist(pType)
	activePlaylistType = pType
	currentSearchQuery = ""
	if UI.searchInput then UI.searchInput.Text = "" end
	if UI.clearBtn then UI.clearBtn.Visible = false end

	if updatePlaylistCardsState then
		updatePlaylistCardsState()
	end

	if pType == "favorites" then
		loadFavorites()
	end

	local songs = getActiveSongList() or {}
	filteredSongs = songs
	updateSongs(songs)
end

local function buildNowPlaying()

	local np = Instance.new("Frame")
	np.Name = "NowPlaying"
	np.Size = UDim2.new(1, 0, 0, DIM.NP_H)
	np.Position = UDim2.new(0, 0, 0, 0)
	np.ZIndex = 1
	np.BackgroundColor3 = Color3.fromHex("#080808")
	np.BorderSizePixel = 0
	np.ClipsDescendants = true
	np.Parent = UI.musicScroll
	addCorner(np, 12)

	local npStroke = Instance.new("UIStroke")
	npStroke.Name = "NPStroke"; npStroke.Thickness = 1.2; npStroke.Color = Color3.fromRGB(255,255,255)
	npStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; npStroke.Parent = np

	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = (ThemeModule and ThemeModule.Gradients and ThemeModule.Gradients.Primary) or ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#151515")),
		ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#353535")),
	})
	strokeGrad.Rotation = 45; strokeGrad.Parent = npStroke
	UI.npStrokeGrad = strokeGrad
	if ThemeModule and ThemeModule.GradientSystem then
		ThemeModule.GradientSystem.Register(strokeGrad, 1.2)
	end

	local thumb = Instance.new("ImageLabel")
	thumb.Name = "Thumbnail"
	thumb.Size = UDim2.new(1, 0, 1, 0)
	thumb.Position = UDim2.new(0, 0, 0, 0)
	thumb.BackgroundTransparency = 1
	thumb.BorderSizePixel = 0
	thumb.ScaleType = Enum.ScaleType.Crop
	thumb.ImageTransparency = 0
	thumb.Image = DEFAULT_THUMBNAIL
	thumb.ZIndex = 1
	thumb.Parent = np
	UI.thumbImg = thumb

	local darkOverlay = Instance.new("Frame")
	darkOverlay.Name = "DarkOverlay"
	darkOverlay.Size = UDim2.new(1, 0, 0, 160)
	darkOverlay.Position = UDim2.new(0, 0, 1, -160)
	darkOverlay.BackgroundColor3 = Color3.fromHex("#000000")
	darkOverlay.BackgroundTransparency = 0
	darkOverlay.BorderSizePixel = 0
	darkOverlay.ZIndex = 2
	darkOverlay.Parent = np
	addCorner(darkOverlay, 12)

	local overlayGrad = Instance.new("UIGradient")
	overlayGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#000000")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#000000")),
	})
	overlayGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.40, 0.75),
		NumberSequenceKeypoint.new(0.70, 0.35),
		NumberSequenceKeypoint.new(1.0, 0.05),
	})
	overlayGrad.Rotation = 90
	overlayGrad.Parent = darkOverlay

	local npBadge = Instance.new("Frame")
	npBadge.Name = "Badge"
	npBadge.Size = UDim2.new(0, 90, 0, 18)
	npBadge.Position = UDim2.new(0, 8, 0, 8)
	npBadge.BackgroundColor3 = Color3.fromHex("#080808")
	npBadge.BackgroundTransparency = 0.15
	npBadge.BorderSizePixel = 0
	npBadge.ZIndex = 4
	npBadge.Parent = np
	addCorner(npBadge, 9)

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Thickness = 1
	badgeStroke.Color = Color3.fromHex("#505050")
	badgeStroke.Transparency = 0.2
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent = npBadge

	local badgeDot = Instance.new("Frame")
	badgeDot.Name = "Dot"
	badgeDot.Size = UDim2.new(0, 5, 0, 5)
	badgeDot.Position = UDim2.new(0, 8, 0.5, -2)
	badgeDot.BackgroundColor3 = Color3.fromHex("#FFFFFF")
	badgeDot.BorderSizePixel = 0
	badgeDot.ZIndex = 5
	badgeDot.Parent = npBadge
	addCorner(badgeDot, 3)

	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "Text"
	badgeText.Size = UDim2.new(1, -20, 1, 0)
	badgeText.Position = UDim2.new(0, 18, 0, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = "NOW PLAYING"
	badgeText.TextColor3 = Color3.fromHex("#FFFFFF")
	badgeText.TextSize = 9
	badgeText.Font = Enum.Font.GothamBold
	badgeText.TextXAlignment = Enum.TextXAlignment.Left
	badgeText.ZIndex = 5
	badgeText.Parent = npBadge

	local favBtn = Instance.new("TextButton")
	favBtn.Name = "AddFavBtn"
	favBtn.Text = T.AddFavorite
	favBtn.Size = UDim2.new(0, 28, 0, 28)
	favBtn.Position = UDim2.new(1, -36, 0, 8)
	favBtn.BackgroundColor3 = Color3.fromHex("#1A1A1A")
	favBtn.BackgroundTransparency = 0.1
	favBtn.BorderSizePixel = 0
	favBtn.TextColor3 = Color3.fromHex("#FFFFFF")
	favBtn.TextSize = 15
	favBtn.Font = Enum.Font.GothamBold
	favBtn.Visible = false
	favBtn.AutoButtonColor = false
	favBtn.ZIndex = 5
	favBtn.Parent = np
	addCorner(favBtn, 14)

	local favBtnStroke = Instance.new("UIStroke")
	favBtnStroke.Thickness = 1
	favBtnStroke.Color = Color3.fromHex("#505050")
	favBtnStroke.Transparency = 0.2
	favBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	favBtnStroke.Parent = favBtn

	favBtn.MouseEnter:Connect(function()
		if canFavorite then
			TweenService:Create(favBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#333333") }):Play()
		end
	end)
	favBtn.MouseLeave:Connect(function()
		if canFavorite then
			TweenService:Create(favBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#1A1A1A") }):Play()
		end
	end)

	favBtn.MouseButton1Click:Connect(function()
		if not isVIPPlus() then
			notifyWarning(T.VIPRequired, "Minimum rank VIP untuk menambah favorit!")
			return
		end
		if not clientState.currentSong then
			notifyWarning(T.MusicTitle, "Tidak ada lagu yang sedang diputar!")
			return
		end
		local curId = tostring(clientState.currentSong.id)
		for _, s in ipairs(userFavorites) do
			if tostring(s.id or s.sound_id) == curId then
				notifyInfo(T.MusicTitle, "Lagu sudah ada di daftar favoritmu!")
				return
			end
		end
		table.insert(userFavorites, clientState.currentSong)
		saveFavorites()
		updateFavoriteUI()
		if activePlaylistType == "favorites" then
			updateSongs(userFavorites)
		end
		notifySuccess(T.SuccessTitle, '"'..(clientState.currentSong.judul or T.Unknown)..'" ditambahkan ke favorit!')
	end)
	UI.addFavBtn = favBtn

	local npContent = Instance.new("Frame")
	npContent.Name = "NPContent"
	npContent.Size = UDim2.new(1, -16, 0, 72)
	npContent.Position = UDim2.new(0, 8, 1, -(72 + 30))
	npContent.BackgroundTransparency = 1
	npContent.ZIndex = 10
	npContent.Parent = np

	local songName = Instance.new("TextLabel")
	songName.Name = "SongName"
	songName.Text = T.NoSongPlaying
	songName.Size = UDim2.new(1, 0, 0, 24)
	songName.Position = UDim2.new(0, 0, 0, 0)
	songName.BackgroundTransparency = 1
	songName.TextColor3 = Color3.fromHex("#FFFFFF")
	songName.TextSize = 14
	songName.Font = Enum.Font.GothamBold
	songName.TextTruncate = Enum.TextTruncate.AtEnd
	songName.TextXAlignment = Enum.TextXAlignment.Left
	songName.TextStrokeTransparency = 0.75
	songName.TextStrokeColor3 = Color3.new(0, 0, 0)
	songName.ZIndex = 12
	songName.Parent = npContent
	addSC(songName, 15)
	UI.songNameLbl = songName

	local reqLbl = Instance.new("TextLabel")
	reqLbl.Name = "Requester"
	reqLbl.Text = ""
	reqLbl.Size = UDim2.new(1, 0, 0, 18)
	reqLbl.Position = UDim2.new(0, 0, 0, 25)
	reqLbl.BackgroundTransparency = 1
	reqLbl.TextColor3 = C.RequesterText
	reqLbl.TextSize = 12
	reqLbl.Font = Enum.Font.GothamMedium
	reqLbl.TextTruncate = Enum.TextTruncate.AtEnd
	reqLbl.TextXAlignment = Enum.TextXAlignment.Left
	reqLbl.TextStrokeTransparency = 0.75
	reqLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	reqLbl.ZIndex = 12
	reqLbl.Parent = npContent
	addSC(reqLbl, 13, 10)
	UI.requesterLbl = reqLbl

	local vizContainer = Instance.new("Frame")
	vizContainer.Name = "VizContainer"
	vizContainer.Size = UDim2.new(0, 56, 0, 16)
	vizContainer.Position = UDim2.new(0, 0, 1, -16)
	vizContainer.BackgroundTransparency = 1
	vizContainer.ZIndex = 12
	vizContainer.Parent = npContent

	UI.visualizerBars = {}
	for i = 1, 7 do
		local bar = Instance.new("Frame")
		bar.Name = "Bar"..i
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Size = UDim2.new(0, 5, 0, 3)
		bar.Position = UDim2.new(0, (i-1)*8, 1, 0)
		bar.BackgroundColor3 = Color3.fromHex("#FFFFFF")
		bar.BorderSizePixel = 0
		bar.ZIndex = 13
		addCorner(bar, 2)
		bar.Parent = vizContainer
		table.insert(UI.visualizerBars, bar)
	end

	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, -16, 0, 22)
	progressFrame.Position = UDim2.new(0, 8, 1, -28)
	progressFrame.BackgroundTransparency = 1
	progressFrame.ZIndex = 10
	progressFrame.Parent = np

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -90, 0, DIM.PROGRESS_H)
	progressBg.Position = UDim2.new(0, 0, 0.5, -DIM.PROGRESS_H/2)
	progressBg.BackgroundColor3 = Color3.fromHex("#303030")
	progressBg.BackgroundTransparency = 0.3
	progressBg.BorderSizePixel = 0
	progressBg.ClipsDescendants = true
	progressBg.ZIndex = 11
	progressBg.Parent = progressFrame
	addCorner(progressBg, DIM.PROGRESS_H/2)

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromHex("#FFFFFF")
	progressFill.BorderSizePixel = 0
	progressFill.ClipsDescendants = true
	progressFill.ZIndex = 12
	progressFill.Parent = progressBg
	addCorner(progressFill, DIM.PROGRESS_H/2)

	local pg = Instance.new("UIGradient")
	pg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0,Color3.fromHex("#888888")), ColorSequenceKeypoint.new(0.5,Color3.fromHex("#DDDDDD")), ColorSequenceKeypoint.new(1,Color3.fromHex("#FFFFFF")) })
	pg.Parent = progressFill
	UI.progressFill = progressFill

	local progressDot = Instance.new("Frame")
	progressDot.Name = "ProgressDot"
	progressDot.Size = UDim2.new(0, DIM.PROGRESS_H+5, 0, DIM.PROGRESS_H+5)
	progressDot.Position = UDim2.new(1, -(DIM.PROGRESS_H+5)/2, 0.5, -(DIM.PROGRESS_H+5)/2)
	progressDot.BackgroundColor3 = Color3.fromRGB(255,255,255)
	progressDot.BorderSizePixel = 0
	progressDot.Visible = false
	progressDot.ZIndex = 13
	progressDot.Parent = progressFill
	addCorner(progressDot, (DIM.PROGRESS_H+5)/2)
	UI.progressDot = progressDot

	local durLbl = Instance.new("TextLabel")
	durLbl.Name = "Duration"
	durLbl.Text = "0:00 / 0:00"
	durLbl.Size = UDim2.new(0, 52, 1, 0)
	durLbl.Position = UDim2.new(1, -84, 0, 0)
	durLbl.BackgroundTransparency = 1
	durLbl.TextColor3 = Color3.fromHex("#D1D5DB")
	durLbl.TextSize = 10
	durLbl.Font = Enum.Font.GothamSemibold
	durLbl.TextXAlignment = Enum.TextXAlignment.Right
	durLbl.Visible = false
	durLbl.ZIndex = 12
	durLbl.Parent = progressFrame
	addSC(durLbl, 10)
	UI.durationLbl = durLbl

	local skip = Instance.new("TextButton")
	skip.Name = "SkipBtn"
	skip.Text = "⏭"
	skip.Size = UDim2.new(0, 24, 0, 20)
	skip.Position = UDim2.new(1, -24, 0.5, -10)
	skip.BackgroundColor3 = Color3.fromHex("#1A1A1A")
	skip.BackgroundTransparency = 0.1
	skip.BorderSizePixel = 0
	skip.TextColor3 = Color3.fromHex("#FFFFFF")
	skip.TextSize = 11
	skip.Font = Enum.Font.GothamBold
	skip.AutoButtonColor = false
	skip.Visible = false
	skip.ZIndex = 12
	skip.Parent = progressFrame
	addCorner(skip, 5)

	local skipStroke = Instance.new("UIStroke")
	skipStroke.Thickness = 1
	skipStroke.Color = Color3.fromHex("#505050")
	skipStroke.Transparency = 0.25
	skipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	skipStroke.Parent = skip

	skip.MouseButton1Click:Connect(function()
		if not clientState.currentSong or not clientState.isPlaying then
			notifyWarning(T.MusicTitle, T.NoSongToSkip)
			return
		end
		dispatch("CONTROL_NEXT")
	end)
	UI.skipBtn = skip

	local votePanel = Instance.new("Frame")
	votePanel.Name = "VoteSkipPanel"
	votePanel.Size = UDim2.new(1, -16, 0, 32)
	votePanel.Position = UDim2.new(0, 8, 1, -66)
	votePanel.BackgroundColor3 = Color3.fromHex("#0C0C0C")
	votePanel.BackgroundTransparency = 0.05
	votePanel.BorderSizePixel = 0
	votePanel.Visible = false
	votePanel.ZIndex = 15
	votePanel.Parent = np
	addCorner(votePanel, 8)

	local vStroke = Instance.new("UIStroke")
	vStroke.Thickness = 1
	vStroke.Color = Color3.fromHex("#3B82F6")
	vStroke.Transparency = 0.3
	vStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	vStroke.Parent = votePanel

	local voteInfo = Instance.new("TextLabel")
	voteInfo.Name = "VoteInfo"
	voteInfo.Size = UDim2.new(1, -112, 1, 0)
	voteInfo.Position = UDim2.new(0, 10, 0, 0)
	voteInfo.BackgroundTransparency = 1
	voteInfo.Text = "Vote Skip: 1/2"
	voteInfo.TextColor3 = Color3.fromHex("#FFFFFF")
	voteInfo.TextSize = 10
	voteInfo.Font = Enum.Font.GothamMedium
	voteInfo.TextXAlignment = Enum.TextXAlignment.Left
	voteInfo.TextTruncate = Enum.TextTruncate.AtEnd
	voteInfo.ZIndex = 16
	voteInfo.Parent = votePanel
	addSC(voteInfo, 11)
	UI.voteInfoLbl = voteInfo

	local voteYes = Instance.new("TextButton")
	voteYes.Name = "VoteYesBtn"
	voteYes.Text = "✓ Ya"
	voteYes.Size = UDim2.new(0, 44, 0, 22)
	voteYes.Position = UDim2.new(1, -102, 0.5, -11)
	voteYes.BackgroundColor3 = Color3.fromHex("#15803D")
	voteYes.BackgroundTransparency = 0.1
	voteYes.BorderSizePixel = 0
	voteYes.TextColor3 = Color3.fromHex("#FFFFFF")
	voteYes.TextSize = 10
	voteYes.Font = Enum.Font.GothamBold
	voteYes.AutoButtonColor = false
	voteYes.ZIndex = 16
	voteYes.Parent = votePanel
	addCorner(voteYes, 5)

	voteYes.MouseButton1Click:Connect(function()
		dispatch("SKIP_VOTE_YES")
		voteSkipState.hasVoted = true
		updateVoteSkipUI()
	end)
	UI.voteYesBtn = voteYes

	local voteNo = Instance.new("TextButton")
	voteNo.Name = "VoteNoBtn"
	voteNo.Text = "X Tidak"
	voteNo.Size = UDim2.new(0, 48, 0, 22)
	voteNo.Position = UDim2.new(1, -54, 0.5, -11)
	voteNo.BackgroundColor3 = Color3.fromHex("#262626")
	voteNo.BackgroundTransparency = 0.1
	voteNo.BorderSizePixel = 0
	voteNo.TextColor3 = Color3.fromHex("#E5E7EB")
	voteNo.TextSize = 10
	voteNo.Font = Enum.Font.GothamBold
	voteNo.AutoButtonColor = false
	voteNo.ZIndex = 16
	voteNo.Parent = votePanel
	addCorner(voteNo, 5)

	voteNo.MouseButton1Click:Connect(function()
		dispatch("SKIP_VOTE_NO")
		voteSkipState.hasVoted = true
		updateVoteSkipUI()
	end)
	UI.voteNoBtn = voteNo

	local voteStatus = Instance.new("TextLabel")
	voteStatus.Name = "VoteStatusLbl"
	voteStatus.Text = "✓ Sudah Vote"
	voteStatus.Size = UDim2.new(0, 96, 1, 0)
	voteStatus.Position = UDim2.new(1, -102, 0, 0)
	voteStatus.BackgroundTransparency = 1
	voteStatus.TextColor3 = Color3.fromHex("#10B981")
	voteStatus.TextSize = 10
	voteStatus.Font = Enum.Font.GothamMedium
	voteStatus.TextXAlignment = Enum.TextXAlignment.Center
	voteStatus.Visible = false
	voteStatus.ZIndex = 16
	voteStatus.Parent = votePanel
	UI.voteStatusLbl = voteStatus

	UI.voteSkipPanel = votePanel
	UI.nowPlayingFrame = np
end

local function buildQueueSection()
	local qs = Instance.new("Frame")
	qs.Name = "QueueSection"
	qs.Size = UDim2.new(1, 0, 0, DIM.QUEUE_CARD_H)
	qs.Position = UDim2.new(0, 0, 0, DIM.NP_H + DIM.PAD)
	qs.BackgroundColor3 = Color3.fromHex("#0F0F0F")
	qs.BorderSizePixel = 0
	qs.ClipsDescendants = true
	qs.Parent = UI.musicScroll
	addCorner(qs, DIM.CORNER_LG)
	addStroke(qs, Color3.fromHex("#222222"), 1, 0)

	local pad = Instance.new("UIPadding", qs)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local qHeader = Instance.new("Frame")
	qHeader.Name = "QueueHeader"
	qHeader.Size = UDim2.new(1, 0, 0, DIM.QTITLE_H)
	qHeader.Position = UDim2.new(0, 0, 0, 0)
	qHeader.BackgroundTransparency = 1
	qHeader.Parent = qs

	local qTitle = Instance.new("TextLabel")
	qTitle.Name = "QueueTitle"
	qTitle.Text = T.QueueTitle
	qTitle.Size = UDim2.new(1, -100, 1, 0)
	qTitle.Position = UDim2.new(0, 0, 0, 0)
	qTitle.BackgroundTransparency = 1
	qTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	qTitle.TextSize = 13
	qTitle.TextXAlignment = Enum.TextXAlignment.Left
	qTitle.Font = Enum.Font.GothamBold
	qTitle.Parent = qHeader
	addSC(qTitle, 14)
	addTextGradient(qTitle, true)

	local qBadge = Instance.new("TextLabel")
	qBadge.Name = "QueueBadge"
	qBadge.Text = "Autoplay"
	qBadge.Size = UDim2.new(0, 85, 0, 20)
	qBadge.Position = UDim2.new(1, -85, 0.5, -10)
	qBadge.BackgroundColor3 = Color3.fromHex("#181818")
	qBadge.BorderSizePixel = 0
	qBadge.TextColor3 = Color3.fromHex("#9E9E9E")
	qBadge.TextSize = 10
	qBadge.Font = Enum.Font.GothamBold
	qBadge.TextXAlignment = Enum.TextXAlignment.Center
	qBadge.Parent = qHeader
	addCorner(qBadge, 10)
	addStroke(qBadge, Color3.fromHex("#2C2C2C"), 1, 0)
	UI.queueBadge = qBadge

	local reqFrame = Instance.new("Frame")
	reqFrame.Name = "RequestFrame"
	reqFrame.Size = UDim2.new(1, 0, 0, DIM.REQ_H)
	reqFrame.Position = UDim2.new(0, 0, 0, DIM.QTITLE_H + 8)
	reqFrame.BackgroundTransparency = 1
	reqFrame.Parent = qs

	local reqContainer = Instance.new("Frame")
	reqContainer.Name = "ReqInputContainer"
	reqContainer.Size = UDim2.new(1, -(DIM.REQ_BTN_W + 8), 1, 0)
	reqContainer.Position = UDim2.new(0, 0, 0, 0)
	reqContainer.BackgroundColor3 = C.InputBg
	reqContainer.BorderSizePixel = 0
	reqContainer.ClipsDescendants = true
	reqContainer.Parent = reqFrame
	addCorner(reqContainer, DIM.CORNER_MD)
	local reqStroke = addStroke(reqContainer, Color3.fromHex("#262626"), 1, 0)

	local reqInput = Instance.new("TextBox")
	reqInput.Name = "ReqInput"
	reqInput.PlaceholderText = T.SongIDPlaceholder
	reqInput.Text = ""
	reqInput.Size = UDim2.new(1, -24, 1, 0)
	reqInput.Position = UDim2.new(0, 12, 0, 0)
	reqInput.BackgroundTransparency = 1
	reqInput.BorderSizePixel = 0
	reqInput.TextColor3 = C.InputText
	reqInput.PlaceholderColor3 = Color3.fromHex("#737373")
	reqInput.TextSize = 12
	reqInput.Font = Enum.Font.GothamMedium
	reqInput.TextXAlignment = Enum.TextXAlignment.Left
	reqInput.TextYAlignment = Enum.TextYAlignment.Center
	reqInput.ClearTextOnFocus = false
	reqInput.ClipsDescendants = true
	reqInput.Parent = reqContainer

	reqContainer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			reqInput:CaptureFocus()
		end
	end)

	local function submitSongReq()
		local rawText = reqInput.Text:gsub("%s+", "")
		local id = rawText:match("%d+")
		if id and id ~= "" then
			if not isVIPPlus() then
				notifyWarning(T.VIPRequired, "Minimum rank VIP untuk menambah lagu!")
				return
			end
			if clientState.currentSong then
				local curId = cleanMusicId(clientState.currentSong.id or clientState.currentSong.sound_id)
				if curId ~= "" and curId == id then
					notifyWarning(T.WarningTitle, "Lagu ini sedang diputar!")
					return
				end
			end
			if isSongInQueue(id) then
				notifyWarning(T.WarningTitle, "Lagu ini sudah ada di antrean!")
				return
			end
			dispatch("ADD_TO_QUEUE", { musicId = id, isFromPlaylist = false })
			reqInput.Text = ""
		end
	end

	reqInput.Focused:Connect(function()
		TweenService:Create(reqStroke, TweenInfo.new(0.18), { Color = Color3.fromHex("#FFFFFF"), Transparency = 0.3 }):Play()
		TweenService:Create(reqContainer, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromHex("#171717") }):Play()
	end)
	reqInput.FocusLost:Connect(function(enterPressed)
		TweenService:Create(reqStroke, TweenInfo.new(0.18), { Color = Color3.fromHex("#262626"), Transparency = 0 }):Play()
		TweenService:Create(reqContainer, TweenInfo.new(0.18), { BackgroundColor3 = C.InputBg }):Play()
		if enterPressed then submitSongReq() end
	end)
	UI.reqInput = reqInput

	local reqBtn = Instance.new("TextButton")
	reqBtn.Name = "ReqBtn"
	reqBtn.Text = T.AddToQueue
	reqBtn.Size = UDim2.new(0, DIM.REQ_BTN_W, 1, 0)
	reqBtn.Position = UDim2.new(1, -DIM.REQ_BTN_W, 0, 0)
	reqBtn.BackgroundColor3 = Color3.fromHex("#FFFFFF")
	reqBtn.BorderSizePixel = 0
	reqBtn.TextColor3 = Color3.fromHex("#111111")
	reqBtn.TextSize = 12
	reqBtn.Font = Enum.Font.GothamBold
	reqBtn.AutoButtonColor = false
	reqBtn.Parent = reqFrame
	addCorner(reqBtn, DIM.CORNER_MD)

	reqBtn.MouseEnter:Connect(function()
		TweenService:Create(reqBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#E2E2E2") }):Play()
	end)
	reqBtn.MouseLeave:Connect(function()
		TweenService:Create(reqBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#FFFFFF") }):Play()
	end)
	reqBtn.Activated:Connect(submitSongReq)
	UI.reqBtn = reqBtn

	local qScroll = Instance.new("ScrollingFrame")
	qScroll.Name = "QueueScroll"
	qScroll.Size = UDim2.new(1, 0, 0, DIM.QUEUE_H)
	qScroll.Position = UDim2.new(0, 0, 0, DIM.QTITLE_H + 8 + DIM.REQ_H + 8)
	qScroll.BackgroundColor3 = Color3.fromHex("#141414")
	qScroll.BorderSizePixel = 0
	qScroll.ScrollBarThickness = 4
	qScroll.ScrollBarImageColor3 = Color3.fromHex("#3E3E3E")
	qScroll.ClipsDescendants = true
	qScroll.Parent = qs
	addCorner(qScroll, DIM.CORNER_MD)
	addStroke(qScroll, Color3.fromHex("#202020"), 1, 0)
	setupAutoScroll(qScroll)

	local qLayout = Instance.new("UIListLayout", qScroll)
	qLayout.Padding = UDim.new(0, 4)

	local qScrollPad = Instance.new("UIPadding", qScroll)
	qScrollPad.PaddingTop = UDim.new(0, DIM.SCROLL_PAD)
	qScrollPad.PaddingBottom = UDim.new(0, DIM.SCROLL_PAD)
	qScrollPad.PaddingLeft = UDim.new(0, DIM.SCROLL_PAD)
	qScrollPad.PaddingRight = UDim.new(0, DIM.SCROLL_PAD)

	local qEmpty = Instance.new("Frame")
	qEmpty.Name = "QueueEmptyFrame"
	qEmpty.Size = UDim2.new(1, 0, 0, 110)
	qEmpty.BackgroundTransparency = 1
	qEmpty.Visible = false
	qEmpty.Parent = qScroll

	local qeIcon = Instance.new("TextLabel")
	qeIcon.Size = UDim2.new(0, 34, 0, 34)
	qeIcon.Position = UDim2.new(0.5, -17, 0, 10)
	qeIcon.BackgroundColor3 = Color3.fromHex("#181818")
	qeIcon.Text = "🎵"
	qeIcon.TextSize = 16
	qeIcon.TextColor3 = Color3.fromHex("#FFFFFF")
	qeIcon.BorderSizePixel = 0
	qeIcon.Parent = qEmpty
	addCorner(qeIcon, 17)
	addStroke(qeIcon, Color3.fromHex("#2A2A2A"), 1, 0)

	local qeLbl = Instance.new("TextLabel")
	qeLbl.Name = "QueueEmpty"
	qeLbl.Text = T.QueueEmpty
	qeLbl.Size = UDim2.new(1, -16, 0, 20)
	qeLbl.Position = UDim2.new(0, 8, 0, 50)
	qeLbl.BackgroundTransparency = 1
	qeLbl.TextColor3 = Color3.fromHex("#D4D4D4")
	qeLbl.TextSize = 12
	qeLbl.Font = Enum.Font.GothamBold
	qeLbl.TextXAlignment = Enum.TextXAlignment.Center
	qeLbl.Parent = qEmpty

	local qeSub = Instance.new("TextLabel")
	qeSub.Name = "QueueEmptySub"
	qeSub.Text = T.QueueEmptySub
	qeSub.Size = UDim2.new(1, -20, 0, 18)
	qeSub.Position = UDim2.new(0, 10, 0, 70)
	qeSub.BackgroundTransparency = 1
	qeSub.TextColor3 = Color3.fromHex("#737373")
	qeSub.TextSize = 10
	qeSub.Font = Enum.Font.GothamMedium
	qeSub.TextXAlignment = Enum.TextXAlignment.Center
	qeSub.Parent = qEmpty

	UI.queueEmptyFrame = qEmpty
	UI.queueScroll = qScroll
	UI.queueSection = qs
end

local function makePlaylistCard(name, titleText, countText, thumbUrlOrIcon, layoutOrder, playlistKey)
	local FOLDER_RADIUS = 12
	local card = Instance.new("TextButton")
	card.Name = name
	card.Size = UDim2.new(0, DIM.PLAYLIST_CARD_H, 0, DIM.PLAYLIST_CARD_H)
	local isSelected = (activePlaylistType == playlistKey)
	card.BackgroundColor3 = Color3.fromHex("#151515")
	card.BorderSizePixel = 0
	card.AutoButtonColor = false
	card.Text = ""
	card.LayoutOrder = layoutOrder or 1
	card.ClipsDescendants = false
	card.ZIndex = isSelected and 5 or 1
	card.Parent = UI.cardsScroll
	addCorner(card, FOLDER_RADIUS)
	local cardStroke = addStroke(card, isSelected and Color3.fromHex("#FFFFFF") or Color3.fromHex("#262626"), isSelected and 2 or 1, 0)

	local isImage = thumbUrlOrIcon and type(thumbUrlOrIcon) == "string" and (
		thumbUrlOrIcon:find("rbxassetid://") or
		thumbUrlOrIcon:match("^%d+$") or
		thumbUrlOrIcon:find("^rbxthumb://") or
		thumbUrlOrIcon:find("^http") or
		thumbUrlOrIcon:find("^rbxasset://")
	)

	if isImage then
		local thumbImg = Instance.new("ImageLabel")
		thumbImg.Name = "Thumbnail"
		thumbImg.Size = UDim2.new(1, 0, 1, 0)
		thumbImg.Position = UDim2.new(0, 0, 0, 0)
		thumbImg.BackgroundTransparency = 1
		thumbImg.BorderSizePixel = 0
		thumbImg.ScaleType = Enum.ScaleType.Crop
		thumbImg.Image = resolveThumbnail(thumbUrlOrIcon)
		thumbImg.ZIndex = 1
		thumbImg.Parent = card
		addCorner(thumbImg, FOLDER_RADIUS)
	else
		local bgFrame = Instance.new("Frame")
		bgFrame.Name = "BgFrame"
		bgFrame.Size = UDim2.new(1, 0, 1, 0)
		bgFrame.Position = UDim2.new(0, 0, 0, 0)
		bgFrame.BackgroundColor3 = Color3.fromHex("#181818")
		bgFrame.BorderSizePixel = 0
		bgFrame.ZIndex = 1
		bgFrame.Parent = card
		addCorner(bgFrame, FOLDER_RADIUS)

		local centerIcon = Instance.new("TextLabel")
		centerIcon.Name = "CenterIcon"
		centerIcon.Size = UDim2.new(0, 48, 0, 48)
		centerIcon.Position = UDim2.new(0.5, -24, 0.35, -24)
		centerIcon.BackgroundTransparency = 1
		centerIcon.Text = thumbUrlOrIcon or "📁"
		centerIcon.TextSize = 30
		centerIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
		centerIcon.ZIndex = 1
		centerIcon.Parent = bgFrame
	end

	local bottomOverlay = Instance.new("Frame")
	bottomOverlay.Name = "BottomOverlay"
	bottomOverlay.Size = UDim2.new(1, 0, 1, 0)
	bottomOverlay.Position = UDim2.new(0, 0, 0, 0)
	bottomOverlay.BackgroundColor3 = Color3.fromHex("#000000")
	bottomOverlay.BorderSizePixel = 0
	bottomOverlay.ZIndex = 2
	bottomOverlay.Parent = card
	addCorner(bottomOverlay, FOLDER_RADIUS)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.0),
		NumberSequenceKeypoint.new(0.40, 1.0),
		NumberSequenceKeypoint.new(0.70, 0.45),
		NumberSequenceKeypoint.new(1.0, 0.05),
	})
	grad.Parent = bottomOverlay

	local tLbl = Instance.new("TextLabel")
	tLbl.Name = "CardTitle"
	tLbl.Text = titleText
	tLbl.Size = UDim2.new(1, -16, 0, 20)
	tLbl.Position = UDim2.new(0, 8, 1, -44)
	tLbl.BackgroundTransparency = 1
	tLbl.TextColor3 = Color3.fromHex("#FFFFFF")
	tLbl.TextSize = 13
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.TextTruncate = Enum.TextTruncate.AtEnd
	tLbl.ZIndex = 3
	tLbl.Parent = card
	addSC(tLbl, 14)

	local sLbl = Instance.new("TextLabel")
	sLbl.Name = "CardSub"
	sLbl.Text = countText
	sLbl.Size = UDim2.new(1, -16, 0, 16)
	sLbl.Position = UDim2.new(0, 8, 1, -22)
	sLbl.BackgroundTransparency = 1
	sLbl.TextColor3 = Color3.fromHex("#D1D5DB")
	sLbl.TextSize = 11
	sLbl.Font = Enum.Font.GothamMedium
	sLbl.TextXAlignment = Enum.TextXAlignment.Left
	sLbl.TextTruncate = Enum.TextTruncate.AtEnd
	sLbl.ZIndex = 3
	sLbl.Parent = card

	local activeInd = Instance.new("TextLabel")
	activeInd.Name = "ActiveIndicator"
	activeInd.Size = UDim2.new(0, 50, 0, 18)
	activeInd.Position = UDim2.new(1, -56, 0, 6)
	activeInd.BackgroundColor3 = Color3.fromHex("#0F0F0F")
	activeInd.BackgroundTransparency = 0.2
	activeInd.Text = "● Aktif"
	activeInd.TextColor3 = Color3.fromHex("#FFFFFF")
	activeInd.TextSize = 9
	activeInd.Font = Enum.Font.GothamBold
	activeInd.Visible = isSelected
	activeInd.BorderSizePixel = 0
	activeInd.ZIndex = 4
	activeInd.Parent = card
	addCorner(activeInd, 4)
	addStroke(activeInd, Color3.fromHex("#FFFFFF"), 1, 0.4)

	card.MouseEnter:Connect(function()
		local isSel = (activePlaylistType == playlistKey)
		if not isSel then
			card.ZIndex = 3
		end
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {
			Color = Color3.fromHex("#FFFFFF"),
			Thickness = 2,
		}):Play()
	end)
	card.MouseLeave:Connect(function()
		local isSel = (activePlaylistType == playlistKey)
		card.ZIndex = isSel and 5 or 1
		TweenService:Create(cardStroke, TweenInfo.new(0.15), {
			Color = isSel and Color3.fromHex("#FFFFFF") or Color3.fromHex("#262626"),
			Thickness = isSel and 2 or 1,
		}):Play()
	end)

	card.MouseButton1Click:Connect(function()
		selectPlaylist(playlistKey)
	end)

	UI.playlistCards[playlistKey] = {
		card      = card,
		stroke    = cardStroke,
		subLbl    = sLbl,
		activeInd = activeInd,
	}

	return card
end

updatePlaylistCardsState = function()
	for key, data in pairs(UI.playlistCards) do
		local isSel = (key == activePlaylistType)
		if data.card then
			data.card.ZIndex = isSel and 5 or 1
		end
		if data.stroke then
			data.stroke.Color = isSel and Color3.fromHex("#FFFFFF") or Color3.fromHex("#262626")
			data.stroke.Thickness = isSel and 2 or 1
		end
		if data.activeInd then
			data.activeInd.Visible = isSel
		end
		if key == "favorites" and data.subLbl then
			data.subLbl.Text = canFavorite and string.format("%d Lagu", #userFavorites) or "Khusus VIP+"
		end
	end
end

rebuildPlaylistCards = function()
	if not UI.cardsScroll then return end
	UI.playlistCards = {}
	for _, child in ipairs(UI.cardsScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end

	local playlists = MusicModule:GetPlaylists() or {}
	local order = 1

	local favCountStr = canFavorite and string.format("%d Lagu", #userFavorites) or "Khusus VIP+"
	local favThumb = getPlaylistThumbnailByName("favorites") or "81579105803685"
	makePlaylistCard("Card_Favorites", "Favorit Saya", favCountStr, favThumb, order, "favorites")
	order = order + 1

	for _, pl in ipairs(playlists) do
		local plName = pl.name or "Playlist"
		local tracks = pl.tracks or {}
		local countStr = string.format("%d Lagu", #tracks)
		local thumb = (pl.thumbnail and pl.thumbnail ~= "") and pl.thumbnail or nil
		makePlaylistCard("Card_PL_"..order, plName, countStr, thumb, order, plName)
		order = order + 1
	end

	if UI.playlistBadge then
		local totalPlaylists = #playlists + 1
		UI.playlistBadge.Text = string.format("%d Playlist", totalPlaylists)
	end

	if updatePlaylistCardsState then
		updatePlaylistCardsState()
	end
end

local function buildPlaylistSection()
	local ps = Instance.new("Frame")
	ps.Name = "PlaylistSection"
	ps.Size = UDim2.new(1, 0, 0, DIM.PLAYLIST_SECTION_H)
	ps.BackgroundColor3 = Color3.fromHex("#0F0F0F")
	ps.BorderSizePixel = 0
	ps.ClipsDescendants = true
	ps.Parent = UI.musicScroll
	addCorner(ps, DIM.CORNER_LG)
	addStroke(ps, Color3.fromHex("#222222"), 1, 0)

	local pad = Instance.new("UIPadding", ps)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local header = Instance.new("Frame")
	header.Name = "PlaylistHeader"
	header.Size = UDim2.new(1, 0, 0, DIM.QTITLE_H)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Parent = ps

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "PlaylistTitle"
	titleLbl.Text = "📂  Koleksi Playlist"
	titleLbl.Size = UDim2.new(1, -110, 1, 0)
	titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Parent = header
	addSC(titleLbl, 14)
	addTextGradient(titleLbl, true)

	local badge = Instance.new("TextLabel")
	badge.Name = "PlaylistBadge"
	badge.Text = "0 Playlist"
	badge.Size = UDim2.new(0, 95, 0, 20)
	badge.Position = UDim2.new(1, -95, 0.5, -10)
	badge.BackgroundColor3 = Color3.fromHex("#181818")
	badge.BorderSizePixel = 0
	badge.TextColor3 = Color3.fromHex("#9E9E9E")
	badge.TextSize = 10
	badge.Font = Enum.Font.GothamBold
	badge.TextXAlignment = Enum.TextXAlignment.Center
	badge.Parent = header
	addCorner(badge, 10)
	addStroke(badge, Color3.fromHex("#2C2C2C"), 1, 0)
	UI.playlistBadge = badge

	local cardsScroll = Instance.new("ScrollingFrame")
	cardsScroll.Name = "PlaylistCardsScroll"
	cardsScroll.Size = UDim2.new(1, 0, 0, DIM.PLAYLIST_CARD_H + 16)
	cardsScroll.Position = UDim2.new(0, 0, 0, DIM.QTITLE_H + 8)
	cardsScroll.BackgroundTransparency = 1
	cardsScroll.BorderSizePixel = 0
	cardsScroll.ScrollBarThickness = 0
	cardsScroll.ScrollBarImageTransparency = 1
	cardsScroll.ScrollingDirection = Enum.ScrollingDirection.X
	cardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	cardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	cardsScroll.ClipsDescendants = true
	cardsScroll.Parent = ps

	local scrollPad = Instance.new("UIPadding", cardsScroll)
	scrollPad.PaddingLeft = UDim.new(0, 10)
	scrollPad.PaddingRight = UDim.new(0, 10)
	scrollPad.PaddingTop = UDim.new(0, 8)
	scrollPad.PaddingBottom = UDim.new(0, 8)

	local cardsLayout = Instance.new("UIListLayout", cardsScroll)
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Padding = UDim.new(0, 10)

	UI.cardsScroll = cardsScroll
	UI.playlistSection = ps

	rebuildPlaylistCards()
end

local function buildSearchSection()
	local ss = Instance.new("Frame")
	ss.Name = "SearchSection"
	ss.Size = UDim2.new(1, 0, 0, DIM.SEARCH_SECTION_H)
	ss.BackgroundColor3 = Color3.fromHex("#0F0F0F")
	ss.BorderSizePixel = 0
	ss.ClipsDescendants = true
	ss.Parent = UI.musicScroll
	addCorner(ss, DIM.CORNER_LG)
	addStroke(ss, Color3.fromHex("#222222"), 1, 0)

	local pad = Instance.new("UIPadding", ss)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local searchContainer = Instance.new("Frame")
	searchContainer.Name = "SearchContainer"
	searchContainer.Size = UDim2.new(1, 0, 0, DIM.SEARCH_H)
	searchContainer.Position = UDim2.new(0, 0, 0, 0)
	searchContainer.BackgroundColor3 = C.InputBg
	searchContainer.BorderSizePixel = 0
	searchContainer.Parent = ss
	addCorner(searchContainer, DIM.CORNER_MD)
	local searchStroke = addStroke(searchContainer, Color3.fromHex("#262626"), 1, 0)

	local searchIcon = Instance.new("TextLabel")
	searchIcon.Name = "SearchIcon"
	searchIcon.Text = "🔍"
	searchIcon.Size = UDim2.new(0, 24, 0, 24)
	searchIcon.Position = UDim2.new(0, 8, 0.5, -12)
	searchIcon.BackgroundTransparency = 1
	searchIcon.TextColor3 = Color3.fromHex("#888888")
	searchIcon.TextSize = 13
	searchIcon.Font = Enum.Font.Gotham
	searchIcon.Parent = searchContainer

	local searchInput = Instance.new("TextBox")
	searchInput.Name = "SearchInput"
	searchInput.PlaceholderText = T.SearchPlaceholder
	searchInput.Text = ""
	searchInput.Size = UDim2.new(1, -(36 + DIM.CLEAR_BTN_W + 6), 1, 0)
	searchInput.Position = UDim2.new(0, 36, 0, 0)
	searchInput.BackgroundTransparency = 1
	searchInput.BorderSizePixel = 0
	searchInput.TextColor3 = C.InputText
	searchInput.PlaceholderColor3 = Color3.fromHex("#737373")
	searchInput.TextSize = 12
	searchInput.Font = Enum.Font.GothamMedium
	searchInput.TextXAlignment = Enum.TextXAlignment.Left
	searchInput.TextYAlignment = Enum.TextYAlignment.Center
	searchInput.ClearTextOnFocus = false
	searchInput.ClipsDescendants = true
	searchInput.Parent = searchContainer

	searchInput.Focused:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.18), { Color = Color3.fromHex("#FFFFFF"), Transparency = 0.3 }):Play()
		TweenService:Create(searchContainer, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromHex("#171717") }):Play()
	end)
	searchInput.FocusLost:Connect(function()
		TweenService:Create(searchStroke, TweenInfo.new(0.18), { Color = Color3.fromHex("#262626"), Transparency = 0 }):Play()
		TweenService:Create(searchContainer, TweenInfo.new(0.18), { BackgroundColor3 = C.InputBg }):Play()
	end)

	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearBtn"
	clearBtn.Text = "x"
	clearBtn.Size = UDim2.new(0, DIM.CLEAR_BTN_W - 6, 0, DIM.SEARCH_H - 12)
	clearBtn.Position = UDim2.new(1, -(DIM.CLEAR_BTN_W - 2), 0.5, -(DIM.SEARCH_H - 12) / 2)
	clearBtn.BackgroundColor3 = C.ClearBtn
	clearBtn.BorderSizePixel = 0
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.TextSize = 12
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.Visible = false
	clearBtn.AutoButtonColor = false
	clearBtn.Parent = searchContainer
	addCorner(clearBtn, DIM.CORNER_SM)

	clearBtn.MouseEnter:Connect(function()
		TweenService:Create(clearBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromHex("#333333") }):Play()
	end)
	clearBtn.MouseLeave:Connect(function()
		TweenService:Create(clearBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.ClearBtn }):Play()
	end)

	local searchDebounce
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local q = searchInput.Text
		clearBtn.Visible = (q ~= "")
		if searchDebounce then task.cancel(searchDebounce) end
		searchDebounce = task.delay(0.2, function()
			searchDebounce = nil
			updateSongs(doSearch(q))
		end)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		searchInput.Text = ""
		currentSearchQuery = ""
		clearBtn.Visible = false
		local sourceList = getActiveSongList() or {}
		filteredSongs = sourceList
		updateSongsTitle(false, #sourceList, "")
		updateSongs(sourceList)
	end)

	UI.searchInput = searchInput
	UI.clearBtn = clearBtn
	UI.searchSection = ss
end

local function buildLibrarySection()
	local ls = Instance.new("Frame")
	ls.Name = "LibrarySection"
	ls.Size = UDim2.new(1, 0, 0, 300)
	ls.BackgroundColor3 = Color3.fromHex("#0F0F0F")
	ls.BorderSizePixel = 0
	ls.ClipsDescendants = true
	ls.Parent = UI.musicScroll
	addCorner(ls, DIM.CORNER_LG)
	addStroke(ls, Color3.fromHex("#222222"), 1, 0)

	local pad = Instance.new("UIPadding", ls)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)

	local header = Instance.new("Frame")
	header.Name = "SongsHeader"
	header.Size = UDim2.new(1, 0, 0, 24)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Parent = ls

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "SongsTitle"
	titleLbl.Text = T.DefaultSongs
	titleLbl.Size = UDim2.new(1, -95, 1, 0)
	titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Parent = header
	addSC(titleLbl, 14)
	addTextGradient(titleLbl, true)
	UI.songsTitleLbl = titleLbl

	local badge = Instance.new("TextLabel")
	badge.Name = "SongsBadge"
	badge.Text = "0 Lagu"
	badge.Size = UDim2.new(0, 85, 0, 20)
	badge.Position = UDim2.new(1, -85, 0.5, -10)
	badge.BackgroundColor3 = Color3.fromHex("#181818")
	badge.BorderSizePixel = 0
	badge.TextColor3 = Color3.fromHex("#9E9E9E")
	badge.TextSize = 10
	badge.Font = Enum.Font.GothamBold
	badge.TextXAlignment = Enum.TextXAlignment.Center
	badge.Parent = header
	addCorner(badge, 10)
	addStroke(badge, Color3.fromHex("#2C2C2C"), 1, 0)
	UI.songsBadge = badge

	local songsCont = Instance.new("Frame")
	songsCont.Name = "SongsContainer"
	songsCont.Size = UDim2.new(1, 0, 0, 200)
	songsCont.Position = UDim2.new(0, 0, 0, 32)
	songsCont.BackgroundTransparency = 1
	songsCont.Parent = ls

	local layout = Instance.new("UIListLayout", songsCont)
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local noRes = Instance.new("Frame")
	noRes.Name = "NoResultsFrame"
	noRes.Size = UDim2.new(1, 0, 0, 120)
	noRes.BackgroundTransparency = 1
	noRes.Visible = false
	noRes.Parent = songsCont

	local nrIcon = Instance.new("TextLabel")
	nrIcon.Size = UDim2.new(0, 36, 0, 36)
	nrIcon.Position = UDim2.new(0.5, -18, 0, 12)
	nrIcon.BackgroundColor3 = Color3.fromHex("#181818")
	nrIcon.Text = "🔍"
	nrIcon.TextSize = 16
	nrIcon.TextColor3 = Color3.fromHex("#FFFFFF")
	nrIcon.BorderSizePixel = 0
	nrIcon.Parent = noRes
	addCorner(nrIcon, 18)
	addStroke(nrIcon, Color3.fromHex("#2A2A2A"), 1, 0)

	local nrLbl = Instance.new("TextLabel")
	nrLbl.Name = "NoResults"
	nrLbl.Text = "Tidak ada lagu ditemukan"
	nrLbl.Size = UDim2.new(1, -16, 0, 20)
	nrLbl.Position = UDim2.new(0, 8, 0, 54)
	nrLbl.BackgroundTransparency = 1
	nrLbl.TextColor3 = Color3.fromHex("#D4D4D4")
	nrLbl.TextSize = 12
	nrLbl.Font = Enum.Font.GothamBold
	nrLbl.TextXAlignment = Enum.TextXAlignment.Center
	nrLbl.Parent = noRes

	local nrSub = Instance.new("TextLabel")
	nrSub.Text = "Coba gunakan kata kunci pencarian yang lain."
	nrSub.Size = UDim2.new(1, -20, 0, 18)
	nrSub.Position = UDim2.new(0, 10, 0, 74)
	nrSub.BackgroundTransparency = 1
	nrSub.TextColor3 = Color3.fromHex("#737373")
	nrSub.TextSize = 10
	nrSub.Font = Enum.Font.GothamMedium
	nrSub.TextXAlignment = Enum.TextXAlignment.Center
	nrSub.Parent = noRes
	UI.noResultsFrame = noRes

	local favEmp = Instance.new("Frame")
	favEmp.Name = "FavEmptyFrame"
	favEmp.Size = UDim2.new(1, 0, 0, 130)
	favEmp.BackgroundTransparency = 1
	favEmp.Visible = false
	favEmp.Parent = songsCont

	local feIcon = Instance.new("TextLabel")
	feIcon.Size = UDim2.new(0, 38, 0, 38)
	feIcon.Position = UDim2.new(0.5, -19, 0, 12)
	feIcon.BackgroundColor3 = Color3.fromHex("#1E1E1E")
	feIcon.Text = "⭐"
	feIcon.TextSize = 18
	feIcon.TextColor3 = Color3.fromHex("#FFFFFF")
	feIcon.BorderSizePixel = 0
	feIcon.Parent = favEmp
	addCorner(feIcon, 19)
	addStroke(feIcon, Color3.fromHex("#353535"), 1, 0)

	local feLbl = Instance.new("TextLabel")
	feLbl.Name = "FavEmpty"
	feLbl.Text = T.FavEmpty
	feLbl.Size = UDim2.new(1, -20, 0, 22)
	feLbl.Position = UDim2.new(0, 10, 0, 56)
	feLbl.BackgroundTransparency = 1
	feLbl.TextColor3 = Color3.fromHex("#D4D4D4")
	feLbl.TextSize = 13
	feLbl.Font = Enum.Font.GothamBold
	feLbl.TextXAlignment = Enum.TextXAlignment.Center
	feLbl.Parent = favEmp

	local feSub = Instance.new("TextLabel")
	feSub.Text = T.FavEmptySub
	feSub.Size = UDim2.new(1, -24, 0, 32)
	feSub.Position = UDim2.new(0, 12, 0, 78)
	feSub.BackgroundTransparency = 1
	feSub.TextColor3 = Color3.fromHex("#737373")
	feSub.TextSize = 10
	feSub.Font = Enum.Font.GothamMedium
	feSub.TextWrapped = true
	feSub.TextXAlignment = Enum.TextXAlignment.Center
	feSub.Parent = favEmp
	UI.favEmptyFrame = favEmp

	local favLock = Instance.new("Frame")
	favLock.Name = "FavLockedFrame"
	favLock.Size = UDim2.new(1, 0, 0, 140)
	favLock.BackgroundTransparency = 1
	favLock.Visible = false
	favLock.Parent = songsCont

	local flIcon = Instance.new("TextLabel")
	flIcon.Size = UDim2.new(0, 38, 0, 38)
	flIcon.Position = UDim2.new(0.5, -19, 0, 12)
	flIcon.BackgroundColor3 = Color3.fromHex("#1E1E1E")
	flIcon.Text = "🔒"
	flIcon.TextSize = 18
	flIcon.TextColor3 = Color3.fromHex("#FFFFFF")
	flIcon.BorderSizePixel = 0
	flIcon.Parent = favLock
	addCorner(flIcon, 19)
	addStroke(flIcon, Color3.fromHex("#353535"), 1, 0)

	local flLbl = Instance.new("TextLabel")
	flLbl.Name = "FavLocked"
	flLbl.Text = T.FavoritesLocked
	flLbl.Size = UDim2.new(1, -20, 0, 22)
	flLbl.Position = UDim2.new(0, 10, 0, 58)
	flLbl.BackgroundTransparency = 1
	flLbl.TextColor3 = Color3.fromHex("#FFFFFF")
	flLbl.TextSize = 13
	flLbl.Font = Enum.Font.GothamBold
	flLbl.TextXAlignment = Enum.TextXAlignment.Center
	flLbl.Parent = favLock

	local flSub = Instance.new("TextLabel")
	flSub.Text = T.FavoritesLockedSub
	flSub.Size = UDim2.new(1, -24, 0, 32)
	flSub.Position = UDim2.new(0, 12, 0, 80)
	flSub.BackgroundTransparency = 1
	flSub.TextColor3 = Color3.fromHex("#888888")
	flSub.TextSize = 11
	flSub.Font = Enum.Font.GothamMedium
	flSub.TextWrapped = true
	flSub.TextXAlignment = Enum.TextXAlignment.Center
	flSub.Parent = favLock
	UI.favLockedFrame = favLock

	UI.songsContainer = songsCont
	UI.librarySection = ls
end

local function buildMusicUI()
	local mScroll = Instance.new("ScrollingFrame")
	mScroll.Name = "MusicScroll"
	mScroll.Size = UDim2.new(1, 0, 1, 0)
	mScroll.Position = UDim2.new(0, 0, 0, 0)
	mScroll.BackgroundTransparency = 1
	mScroll.BorderSizePixel = 0
	mScroll.ScrollBarThickness = 0
	mScroll.ScrollBarImageTransparency = 1
	mScroll.ClipsDescendants = true
	mScroll.ScrollingEnabled = true
	mScroll.Parent = musicPage
	setupFixedScroll(mScroll)
	UI.musicScroll = mScroll

	buildNowPlaying()
	buildQueueSection()
	buildPlaylistSection()
	buildSearchSection()
	buildLibrarySection()

	updateMusicLayout()
	if MenuConfig.GUI and MenuConfig.GUI.MainPanel then
		MenuConfig.GUI.MainPanel:GetPropertyChangedSignal("Size"):Connect(function()
			task.defer(updateMusicLayout)
		end)
	end

	if ThemeModule and ThemeModule.GradientSystem then ThemeModule.GradientSystem.Start() end
end
buildMusicUI()

local BLOCKED_NOTIFY_PATTERNS = {
	"^Sistem musik",
	"^Menunggu playlist",
	"^Playlist dimuat",
	"^Peringatan: Gagal",
	"^Selamat datang",
	"^Sinkronisasi",
	"^Tersinkron",
	"^Sync terlalu",
	"^Terdeteksi banyak",
	"^Gagal memuat lagu",
}

local function isNotifyBlocked(message)
	for _, pattern in ipairs(BLOCKED_NOTIFY_PATTERNS) do
		if message:match(pattern) then
			return true
		end
	end
	return false
end

dispatchEvent.OnClientEvent:Connect(function(event)
	if type(event) ~= "table" or type(event.type) ~= "string" then return end
	local payload = event.payload or {}

	if event.type == "SYNC_STATE" or event.type == "STATE_UPDATE" then
		clientState.queue           = payload.queue or {}
		clientState.currentSong     = payload.currentSong
		clientState.currentUploader = payload.currentUploader or payload.uploader
		clientState.isPlaying       = payload.isPlaying or false
		clientState.duration        = payload.duration or 0
		clientState.serverStartTime = payload.serverStartTime or payload.startTime or event.serverStartTime or 0

		updateQueue()
		if clientState.currentSong then
			local songId = clientState.currentSong.id
			clientState.currentSong.sampul = getSongThumbnail(clientState.currentSong)
			if UI.songNameLbl then UI.songNameLbl.Text = clientState.currentSong.judul or T.Unknown end
			if payload.isAutoplay then
				if UI.requesterLbl then UI.requesterLbl.Text = T.AutoplayLabel; UI.requesterLbl.TextColor3 = C.AutoplayText end
				clientState.isAutoplay = true
			else
				if UI.requesterLbl then UI.requesterLbl.Text = T.RequestedBy..(clientState.currentUploader or T.Unknown); UI.requesterLbl.TextColor3 = C.RequesterText end
				clientState.isAutoplay = false
			end
			setThumb(clientState.currentSong.sampul, songId)
			if UI.addFavBtn then UI.addFavBtn.Visible = true end
			currentTimeLen = clientState.duration

			local syncPos = calculateSyncPosition(clientState.serverStartTime, clientState.duration)
			updateProgressBar(syncPos, clientState.duration)

			if clientState.currentSong.id then
				syncServerSoundPosition(clientState.currentSong.id, clientState.serverStartTime, clientState.duration, false)
			end
		else
			isSyncing = false
			hasInitialSynced = true
			if UI.songNameLbl then UI.songNameLbl.Text = T.NoSongPlaying end
			if UI.requesterLbl then UI.requesterLbl.Text = "" end
			setThumb(nil)
			if UI.addFavBtn then UI.addFavBtn.Visible = false end
			updateProgressBar(0, 0)
		end
		updateSkipButton()
		task.defer(updateSongs)

	elseif event.type == "QUEUE_UPDATE" then
		clientState.queue = payload.queue or {}; updateQueue()

	elseif event.type == "NOTIFY" then
		local msg = payload.message or ""

		if isNotifyBlocked(msg) then return end
		if msg:find("berhasil") or msg:find("added") or msg:find("Sukses") then notifySuccess(T.MusicTitle, msg)
		elseif msg:find("Error") or msg:find("gagal") or msg:find("Invalid") then notifyError(T.MusicTitle, msg)
		elseif msg:find("Tunggu") or msg:find("Cooldown") or msg:find("wait") then notifyWarning(T.MusicTitle, msg)
		else notifyInfo(T.MusicTitle, msg) end

	elseif event.type == "SKIP_VOTE_START" then
		voteSkipState.active = true
		voteSkipState.yesVotes = payload.yesVotes or 1
		voteSkipState.noVotes = payload.noVotes or 0
		voteSkipState.required = payload.required or math.floor((payload.totalVoters or 2)/2)+1
		voteSkipState.timeRemaining = 30
		if payload.initiator == player.DisplayName then
			voteSkipState.hasVoted = true
		else
			voteSkipState.hasVoted = false
		end
		updateVoteSkipUI()
		notifyInfo(T.MusicTitle, string.format("%s memulai vote skip: %s", payload.initiator or "?", payload.songTitle or "?"))

		if voteCountdownConn then task.cancel(voteCountdownConn) end
		voteCountdownConn = task.spawn(function()
			while voteSkipState.active and voteSkipState.timeRemaining > 0 do
				task.wait(1)
				if not voteSkipState.active then break end
				voteSkipState.timeRemaining = voteSkipState.timeRemaining - 1
				local req = math.max(1, voteSkipState.required or 1)
				local yes = voteSkipState.yesVotes or 0
				if UI.voteInfoLbl then UI.voteInfoLbl.Text = string.format("Vote Skip: %d/%d (%ds)", yes, req, math.max(0, voteSkipState.timeRemaining)) end
			end
		end)

	elseif event.type == "SKIP_VOTE_UPDATE" then
		voteSkipState.yesVotes = payload.yesVotes or 0
		voteSkipState.noVotes = payload.noVotes or 0
		voteSkipState.required = payload.required or math.floor((payload.totalVoters or 2)/2)+1
		updateVoteSkipUI()

	elseif event.type == "SKIP_VOTE_END" then
		voteSkipState.active = false
		voteSkipState.hasVoted = false
		if voteCountdownConn then
			task.cancel(voteCountdownConn)
			voteCountdownConn = nil
		end
		updateVoteSkipUI()
		if payload.result == "passed" then
			notifySuccess(T.MusicTitle, "Vote skip berhasil! Melewati lagu...")
		else
			notifyWarning(T.MusicTitle, "Vote skip gagal. Lagu dilanjutkan.")
		end
	end
end)

musicBroadcast.OnClientEvent:Connect(function(broadcastType, payload)
	if type(broadcastType) ~= "string" then return end
	payload = payload or {}

	if broadcastType == "SongUpdate" then
		clientState.currentSong = {
			id           = payload.SoundId,
			judul        = payload.Title,
			playlistName = payload.PlaylistName,
			sampul       = nil,
		}
		clientState.currentSong.sampul = getSongThumbnail(clientState.currentSong)
		clientState.currentUploader = payload.AddedBy
		clientState.duration        = payload.Duration or 0
		clientState.isPlaying       = true
		clientState.serverStartTime = payload.ServerStartTime or 0
		currentTimeLen = clientState.duration

		if UI.songNameLbl then UI.songNameLbl.Text = payload.Title or T.Unknown end
		if payload.AddedBy == "Auto-Playlist" then
			if UI.requesterLbl then UI.requesterLbl.Text = T.AutoplayLabel; UI.requesterLbl.TextColor3 = C.AutoplayText end
			clientState.isAutoplay = true
		else
			if UI.requesterLbl then UI.requesterLbl.Text = T.RequestedBy..(payload.AddedBy or T.Unknown); UI.requesterLbl.TextColor3 = C.RequesterText end
			clientState.isAutoplay = false
		end
		setThumb(clientState.currentSong.sampul, clientState.currentSong.id)
		if UI.addFavBtn then UI.addFavBtn.Visible = true end
		updateProgressBar(0, clientState.duration); updateSkipButton()
		task.defer(updateSongs)

		if payload.SoundId then
			syncServerSoundPosition(payload.SoundId, clientState.serverStartTime, clientState.duration, true)
		end

	elseif broadcastType == "StopMusic" then
		clientFadeOut(CLIENT_FADE_OUT_DUR)
		isSyncing = false
		hasInitialSynced = true

		clientState.currentSong     = nil
		clientState.currentUploader = nil
		clientState.isPlaying       = false
		clientState.isAutoplay      = false
		clientState.serverStartTime = 0
		if UI.songNameLbl then UI.songNameLbl.Text = T.NoSongPlaying end
		if UI.requesterLbl then UI.requesterLbl.Text = "" end
		setThumb(nil)
		if UI.addFavBtn then UI.addFavBtn.Visible = false end
		updateProgressBar(0, 0); updateSkipButton()
		task.defer(updateSongs)

	elseif broadcastType == "SongDurationUpdate" then
		if payload.Duration and payload.Duration > 0 then
			clientState.duration = payload.Duration
			currentTimeLen = payload.Duration
			if clientState.currentSong then
				clientState.currentSong.Duration = payload.Duration
			end
			local syncPos = calculateSyncPosition(clientState.serverStartTime, clientState.duration)
			updateProgressBar(syncPos, clientState.duration)
		end

	elseif broadcastType == "Progress" then
		currentTimePos = payload.Current or 0
		if payload.Duration and payload.Duration > 0 then
			clientState.duration = payload.Duration
			currentTimeLen = payload.Duration
			if clientState.currentSong then
				clientState.currentSong.Duration = payload.Duration
			end
		end

		if payload.ServerStartTime and payload.ServerStartTime > 0 then
			clientState.serverStartTime = payload.ServerStartTime
		end

		if clientState.isPlaying and clientState.serverStartTime > 0 then
			gentleDriftCorrect(clientState.serverStartTime, clientState.duration)
		end
	end
end)

musicUpdate.OnClientEvent:Connect(function(syncType, data)
	if syncType == "SyncMusic" and data then
		clientState.currentSong = {
			id           = data.SoundId,
			judul        = data.Title,
			playlistName = data.PlaylistName,
			sampul       = nil,
		}
		clientState.currentSong.sampul = getSongThumbnail(clientState.currentSong)
		clientState.currentUploader = data.AddedBy
		clientState.duration        = data.Duration or 0
		clientState.isPlaying       = data.IsPlaying or false
		clientState.serverStartTime = data.ServerStartTime or 0

		local syncPos = calculateSyncPosition(data.ServerStartTime, data.Duration)
		currentTimePos = syncPos
		currentTimeLen = data.Duration or 0

		if UI.songNameLbl then UI.songNameLbl.Text = data.Title or T.NoSongPlaying end
		if data.AddedBy == "Auto-Playlist" then
			if UI.requesterLbl then UI.requesterLbl.Text = T.AutoplayLabel; UI.requesterLbl.TextColor3 = C.AutoplayText end
			clientState.isAutoplay = true
		else
			if UI.requesterLbl then UI.requesterLbl.Text = data.AddedBy and (T.RequestedBy..data.AddedBy) or ""; UI.requesterLbl.TextColor3 = C.RequesterText end
			clientState.isAutoplay = false
		end
		setThumb(clientState.currentSong.sampul, clientState.currentSong.id)
		if UI.addFavBtn then UI.addFavBtn.Visible = clientState.currentSong ~= nil end
		updateProgressBar(syncPos, currentTimeLen)
		updateSkipButton()
		task.defer(updateSongs)

		if data.SoundId then
			syncServerSoundPosition(data.SoundId, data.ServerStartTime, data.Duration, false)
		end
	end
end)

if MenuConfig.Events and MenuConfig.Events.OnSettingChanged then
	MenuConfig.Events.OnSettingChanged.Event:Connect(function(key, value)
		if key == "muteMusic" then isMuted = value; applyVolume()
		elseif key == "musicVolume" then userVolume = value / 100; if not isMuted then applyVolume() end end
	end)
end

MenuConfig.Events.OnMenuToggled.Event:Connect(function(isOpen)
	if isOpen then
		if MenuConfig.State.currentMainTab == "Music" then
			startProgressLoop()
		end
		task.defer(updateMusicLayout)
		task.delay(0.1, updateMusicLayout)
		task.delay(0.36, updateMusicLayout)
	else
		stopProgressLoop()
	end
end)
MenuConfig.Events.OnTabChanged.Event:Connect(function(tab)
	if tab == "Music" then
		startProgressLoop()
		task.defer(updateMusicLayout)
		task.delay(0.1, updateMusicLayout)
	else
		stopProgressLoop()
	end
end)

local function refreshRoleUI()
	canFavorite = isVIPPlus()
	updateFavoriteUI()
end

local roleValue = player:FindFirstChild("Role")
if roleValue and roleValue:IsA("StringValue") then
	roleValue.Changed:Connect(refreshRoleUI)
else
	player.ChildAdded:Connect(function(child)
		if child.Name == "Role" and child:IsA("StringValue") then
			child.Changed:Connect(refreshRoleUI); refreshRoleUI()
		end
	end)
end

isMuted    = MenuConfig.UserSettings and MenuConfig.UserSettings.muteMusic or false
userVolume = (MenuConfig.UserSettings and MenuConfig.UserSettings.musicVolume or 50) / 100

local startMg = getMusicGroup()
if startMg and startMg:IsA("SoundGroup") then
	startMg.Volume = 0
end

task.spawn(function()
	task.delay(4.0, function()
		if not hasInitialSynced then
			isSyncing = false
			hasInitialSynced = true
			applyVolume()
		end
	end)

	loadFavorites()
	refreshRoleUI()
	requestSync:FireServer()
	defaultSongs = MusicModule:GetAllMusic()
	filteredSongs = defaultSongs

	if rebuildPlaylistCards then
		rebuildPlaylistCards()
	end

	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Music" then
		startProgressLoop()
	end

	local playlists = MusicModule:GetPlaylists()
	if #playlists > 0 and playlists[1].name then
		selectPlaylist(playlists[1].name)
	else
		selectPlaylist("favorites")
	end
	updateMusicLayout()
end)

local ssPlayConn
local ssLoadConn
local ssIdConn
local ssLenConn
local function watchServerSound()
	if ssPlayConn then ssPlayConn:Disconnect(); ssPlayConn = nil end
	if ssLoadConn then ssLoadConn:Disconnect(); ssLoadConn = nil end
	if ssIdConn then ssIdConn:Disconnect(); ssIdConn = nil end
	if ssLenConn then ssLenConn:Disconnect(); ssLenConn = nil end

	local ss = getServerSound()
	if ss then
		local function checkDuration()
			if ss and ss:IsA("Sound") and ss.TimeLength > 0 then
				if clientState.duration ~= ss.TimeLength then
					clientState.duration = ss.TimeLength
					currentTimeLen = ss.TimeLength
					if clientState.currentSong then
						clientState.currentSong.Duration = ss.TimeLength
					end
				end
			end
		end
		checkDuration()

		if not isSyncing and hasInitialSynced then
			applyVolume()
		end

		ssPlayConn = ss:GetPropertyChangedSignal("IsPlaying"):Connect(function()
			checkDuration()
			if ss.IsPlaying and not isSyncing and hasInitialSynced then
				applyVolume()
			end
		end)

		ssLoadConn = ss:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			checkDuration()
			if ss.IsLoaded and not isSyncing and hasInitialSynced then
				applyVolume()
			end
		end)

		ssLenConn = ss:GetPropertyChangedSignal("TimeLength"):Connect(checkDuration)

		ssIdConn = ss:GetPropertyChangedSignal("SoundId"):Connect(checkDuration)
	end
end
watchServerSound()

workspace.DescendantAdded:Connect(function(child)
	if child.Name == "ServerMusicSound" and child:IsA("Sound") then
		watchServerSound()
	end
end)
SoundService.ChildAdded:Connect(function(child)
	if child.Name == "ServerMusicSound" and child:IsA("Sound") then
		watchServerSound()
	end
end)

if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnColorChanged then
	MenuConfig.Events.OnColorChanged.Event:Connect(function()
		if UI.npStrokeGrad and ThemeModule and ThemeModule.Gradients then
			UI.npStrokeGrad.Color = ThemeModule.Gradients.Primary
		end
		if musicPage and ThemeModule and ThemeModule.Gradients then
			for _, desc in ipairs(musicPage:GetDescendants()) do
				if desc:IsA("UIGradient") and desc.Name == "StrokeGradient" then
					desc.Color = ThemeModule.Gradients.Primary
				end
			end
		end
	end)
end
