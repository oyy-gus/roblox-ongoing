-- ====================================
-- MUSIC CLIENT (FIXED)
-- Place in: StarterGui > MenuGUI(ScreenGui) > MusicClient(LocalScript)
-- ====================================
-- Perbaikan SINKRONISASI:
--   ✅ DESYNC_THRESHOLD diperkecil dari 2.0s ke 0.5s (koreksi lebih cepat)
--   ✅ syncServerSoundPosition: mute→tunggu load→seek→fade-in (tanpa audio bocor)
--   ✅ Progress bar menggunakan shared-clock interpolation (smooth, tanpa lompatan)
--   ✅ Hanya SATU posisi koreksi per lagu baru (tidak berulang-ulang)
--   ✅ Hilangkan koreksi posisi di Progress handler (penyebab audio "kasar")
--   ✅ Hilangkan koreksi posisi di watchServerSound (penyebab audio loncat)
--   ✅ Client fade lebih cepat untuk mengurangi celah
-- Perbaikan NOTIFIKASI:
--   ✅ Filter notifikasi server: blokir pesan sistem yang mengganggu

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local MenuConfig  = require(Modules:WaitForChild("MenuConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))
local MusicModule = require(Modules:WaitForChild("MusicModule"))

local guiReady = MenuConfig.WaitForGUIReady(15)
if not guiReady then warn("❌ MusicClient: GUI tidak ready!"); return end

local player    = Players.LocalPlayer
local musicPage = MenuConfig.GUI.MusicPage

local remoteFolder = ReplicatedStorage:WaitForChild("MusicRemotes", 30)
if not remoteFolder then warn("❌ MusicClient: MusicRemotes not found!"); return end

local dispatchAction = remoteFolder:WaitForChild("DispatchAction", 10)
local dispatchEvent  = remoteFolder:WaitForChild("DispatchEvent",  10)
local musicBroadcast = remoteFolder:WaitForChild("MusicBroadcast", 10)
local musicUpdate    = remoteFolder:WaitForChild("MusicUpdate",    10)
local requestSync    = remoteFolder:WaitForChild("RequestSync",    10)

if not (dispatchAction and dispatchEvent and musicBroadcast) then
	warn("❌ MusicClient: Critical remotes missing!"); return
end

-- ====================================
-- SYNC CONSTANTS (DIPERBAIKI)
-- ====================================
local DESYNC_THRESHOLD    = 0.5   -- DIPERKECIL: dari 2.0 ke 0.5 detik
local CLIENT_FADE_IN_DUR  = 0.3   -- DIPERCEPAT: dari 0.6 ke 0.3
local CLIENT_FADE_OUT_DUR = 0.3   -- DIPERCEPAT: dari 0.4 ke 0.3

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
	SubTabActive       = getColor("Primary1", Color3.fromRGB(255,215,0)),
	SubTabInactive     = Color3.fromRGB(40,40,55),
	SubTabDisabled     = Color3.fromRGB(30,30,40),
	SubTabText         = Color3.fromRGB(255,255,255),
	SubTabTextActive   = Color3.fromRGB(30,30,30),
	SubTabTextDisabled = Color3.fromRGB(100,100,100),
	NowPlayingBg       = Color3.fromRGB(30,30,45),
	ThumbnailBg        = Color3.fromRGB(50,50,70),
	SongNameText       = Color3.fromRGB(255,255,255),
	RequesterText      = Color3.fromRGB(140,140,160),
	DurationText       = Color3.fromRGB(200,200,220),
	FavoriteBtn        = Color3.fromRGB(220,160,30),
	FavBtnDisabled     = Color3.fromRGB(80,80,80),
	AutoplayText       = Color3.fromRGB(100,200,100),
	ProgressBg         = Color3.fromRGB(25,25,35),
	ProgressFill       = getColor("Primary1", Color3.fromRGB(255,215,0)),
	SkipBtn            = Color3.fromRGB(60,100,200),
	SkipBtnDisabled    = Color3.fromRGB(60,60,80),
	AddBtn             = Color3.fromRGB(50,140,90),
	BtnText            = Color3.fromRGB(255,255,255),
	VoteYesBtn         = Color3.fromRGB(50,180,80),
	VoteNoBtn          = Color3.fromRGB(180,60,60),
	VoteBg             = Color3.fromRGB(40,40,60),
	InputBg            = Color3.fromRGB(35,35,50),
	InputText          = Color3.fromRGB(230,230,230),
	QueueBg            = Color3.fromRGB(25,25,40),
	QueueItem          = Color3.fromRGB(35,35,52),
	QueueSongText      = Color3.fromRGB(230,230,230),
	QueueRequester     = Color3.fromRGB(160,160,180),
	ScrollBar          = Color3.fromRGB(100,100,130),
	SongsBg            = Color3.fromRGB(25,25,40),
	SongsItem          = Color3.fromRGB(35,35,52),
	SongText           = Color3.fromRGB(230,230,230),
	FavBg              = Color3.fromRGB(25,25,40),
	FavItem            = Color3.fromRGB(35,35,52),
	FavSongText        = Color3.fromRGB(230,230,230),
	FavThumb           = Color3.fromRGB(50,50,70),
	FavPlayBtn         = Color3.fromRGB(50,140,90),
	FavRemoveBtn       = Color3.fromRGB(180,60,60),
	FavBtnText         = Color3.fromRGB(255,255,255),
	FavLocked          = Color3.fromRGB(255,200,100),
	ClearBtn           = Color3.fromRGB(180,60,60),
}

local T = {
	SubTabPlayer      = "▶  Pemutar",
	SubTabSongs       = "🎵  Lagu",
	SubTabFavorites   = "⭐  Favorit",
	SubTabFavLocked   = "🔒  Favorit",
	NoSongPlaying     = "Tidak ada lagu diputar",
	RequestedBy       = "Diminta: ",
	AutoplayLabel     = "🎵  Autoplay",
	QueueTitle        = "Antrean Lagu",
	QueueEmpty        = "Antrean kosong — Autoplay aktif",
	DefaultSongs      = "Lagu Tersedia",
	MyFavorites       = "Favorit Saya",
	FavoritesLocked   = "🔒  Fitur Favorit hanya untuk VIP+",
	DurationFormat    = "%s / %s",
	Unknown           = "Tidak Diketahui",
	SkipBtn           = "⏭  Skip",
	VoteYes           = "✓  Ya",
	VoteNo            = "X  Tidak",
	AddFavorite       = "★",
	AddToQueue        = "Tambah",
	SongIDPlaceholder = "Masukkan ID Lagu...",
	Remove            = "x",
	SuccessTitle      = "Sukses",
	ErrorTitle        = "Error",
	WarningTitle      = "Peringatan",
	VIPRequired       = "VIP+ Required",
	MusicTitle        = "Musik",
	SearchTitle       = "Pencarian",
	NoSongToSkip      = "Tidak ada lagu yang sedang diputar!",
	SearchPlaceholder = "🔍  Cari lagu...",
}

local SUBTAB_H   = 34
local NP_H       = 90
local THUMB_SZ   = 70
local PROGRESS_H = 7
local CONTROLS_H = 32
local VOTE_H     = 62
local REQ_H      = 36
local REQ_BTN_W  = 76
local QTITLE_H   = 22
local QUEUE_H    = 120
local QUEUE_ITEM_H = 38
local SONG_ITEM_H  = 42
local FAV_ITEM_H   = 44
local FAV_THUMB_SZ = 36
local SEARCH_H   = 34
local CLEAR_BTN_W = 34
local PAD        = 6
local CORNER_SM  = 6
local CORNER_MD  = 8
local SCROLL_PAD = 6

local Y_NP     = 0
local Y_PROG   = Y_NP + NP_H + PAD
local Y_CTRL   = Y_PROG + PROGRESS_H + 16 + PAD
local Y_REQ    = Y_CTRL + math.max(CONTROLS_H, VOTE_H) + PAD
local Y_QTITLE = Y_REQ + REQ_H + PAD
local Y_QUEUE  = Y_QTITLE + QTITLE_H + 4
local CANVAS_H = Y_QUEUE + QUEUE_H + 10

local function addCorner(p, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or CORNER_SM); c.Parent = p; return c
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
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,215,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,140,0)) })
	g.Rotation = rotation or 90; g.Parent = parent; return g
end
local function addTextGradient(lbl, animated)
	if ThemeModule then
		if animated then return ThemeModule.CreatePrimaryGradient(lbl, 0, 1.5)
		else return ThemeModule.CreateStaticGradient(lbl, "Primary", 0) end
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255,215,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,140,0)) })
	g.Rotation = 0; g.Parent = lbl; return g
end
local function removeGradient(p)
	local g = p:FindFirstChildOfClass("UIGradient")
	if g then if ThemeModule and ThemeModule.GradientSystem then ThemeModule.GradientSystem.Unregister(g) end; g:Destroy() end
end
local function setupFixedScroll(sf)
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.AutomaticCanvasSize = Enum.AutomaticSize.None
	sf.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	sf.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	sf.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
end
local function setupAutoScroll(sf)
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.CanvasSize = UDim2.new(0,0,0,0)
	sf.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	sf.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
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

-- ====================================
-- CLIENT STATE
-- ====================================
local clientState = {
	queue           = {},
	currentSong     = nil,
	currentUploader = nil,
	isPlaying       = false,
	duration        = 0,
	isAutoplay      = false,
	serverStartTime = 0,
}

local currentSubTab      = "player"
local currentTimePos     = 0
local currentTimeLen     = 0
local userFavorites      = {}
local defaultSongs       = {}
local filteredSongs      = {}
local currentSearchQuery = ""
local lastNoResults      = 0
local canFavorite        = false

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

-- ====================================
-- VOLUME CONTROL
-- ====================================
local function cancelClientFade()
	if currentFadeTween then
		currentFadeTween:Cancel()
		currentFadeTween = nil
	end
end

local function applyVolume()
	local musicGroup = SoundService:FindFirstChild("MusicGroup")
	if musicGroup and musicGroup:IsA("SoundGroup") then
		cancelClientFade()
		musicGroup.Volume = isMuted and 0 or userVolume
	end
end

local function clientFadeIn(duration)
	local musicGroup = SoundService:FindFirstChild("MusicGroup")
	if not musicGroup or isMuted then return end
	cancelClientFade()
	musicGroup.Volume = 0
	local tween = TweenService:Create(
		musicGroup,
		TweenInfo.new(duration or CLIENT_FADE_IN_DUR, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = userVolume }
	)
	currentFadeTween = tween
	tween:Play()
end

local function clientFadeOut(duration)
	local musicGroup = SoundService:FindFirstChild("MusicGroup")
	if not musicGroup then return end
	cancelClientFade()
	local tween = TweenService:Create(
		musicGroup,
		TweenInfo.new(duration or CLIENT_FADE_OUT_DUR, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Volume = 0 }
	)
	currentFadeTween = tween
	tween:Play()
end

-- ====================================
-- SYNC HELPERS (DIPERBAIKI TOTAL)
-- ====================================

--- Hitung posisi lagu yang benar berdasarkan shared clock
local function calculateSyncPosition(serverStartTime, duration)
	if not serverStartTime or serverStartTime <= 0 then return 0 end
	local now = workspace:GetServerTimeNow()
	local elapsed = now - serverStartTime
	return math.clamp(elapsed, 0, duration or 9999)
end

--- Flag sinkronisasi
local syncInProgress = false

--- PERBAIKAN: Sinkronkan TimePosition SEKALI saat lagu baru/join
--- Mute → tunggu sound ready → seek ke posisi tepat → fade-in
--- Tidak ada koreksi berulang yang menyebabkan audio "kasar"
local function syncServerSoundPosition(expectedSoundId, serverStartTime, duration)
	syncInProgress = true
	local musicGroup = SoundService:FindFirstChild("MusicGroup")
	if musicGroup and musicGroup:IsA("SoundGroup") then
		cancelClientFade()
		musicGroup.Volume = 0
	end

	task.spawn(function()
		local serverSound = SoundService:FindFirstChild("ServerMusicSound")
		if not serverSound or not serverSound:IsA("Sound") then
			syncInProgress = false
			if not isMuted then applyVolume() end
			return
		end

		local targetSoundId = "rbxassetid://" .. tostring(expectedSoundId)

		-- Tunggu SoundId tepat (replication delay)
		local waitStart = workspace:GetServerTimeNow()
		while serverSound.SoundId ~= targetSoundId and (workspace:GetServerTimeNow() - waitStart) < 5 do
			task.wait(0.05)
		end

		if serverSound.SoundId ~= targetSoundId then
			syncInProgress = false
			if not isMuted then applyVolume() end
			return
		end

		-- Tunggu sound loaded
		if not serverSound.IsLoaded then
			serverSound.Loaded:Wait()
		end

		-- Tunggu playing
		waitStart = workspace:GetServerTimeNow()
		while not serverSound.IsPlaying and (workspace:GetServerTimeNow() - waitStart) < 5 do
			task.wait(0.05)
		end

		-- PERBAIKAN: Hitung posisi tepat sekarang (setelah semua delay loading)
		local correctPosition = calculateSyncPosition(serverStartTime, duration)

		-- Set posisi SEKALI (ini satu-satunya tempat kita koreksi posisi)
		if serverSound.IsPlaying and correctPosition > 0 then
			serverSound.TimePosition = correctPosition
			task.wait(0.05)  -- Beri waktu engine update
		end

		-- Selesai: fade-in
		syncInProgress = false
		if not isMuted then
			clientFadeIn(CLIENT_FADE_IN_DUR)
		end
	end)
end

-- SUB-TAB BAR
local subTabFrame = Instance.new("Frame")
subTabFrame.Name = "SubTabs"; subTabFrame.Size = UDim2.new(1,0,0,SUBTAB_H)
subTabFrame.BackgroundTransparency = 1; subTabFrame.Parent = musicPage

local function makeSubTab(name, text, posX, active)
	local btn = Instance.new("TextButton")
	btn.Name = name; btn.Text = text
	btn.Size = UDim2.new(0.32,0,1,0); btn.Position = UDim2.new(posX,0,0,0)
	btn.BackgroundColor3 = active and C.SubTabActive or C.SubTabInactive
	btn.BorderSizePixel = 0
	btn.TextColor3 = active and C.SubTabTextActive or C.SubTabText
	btn.TextSize = 13; btn.Font = Enum.Font.GothamBold
	btn.ClipsDescendants = true; btn.AutoButtonColor = false; btn.Parent = subTabFrame
	addCorner(btn, CORNER_SM); addSC(btn, 14)
	if active then addGradient(btn, 90, false) end
	return btn
end

local playerSubTab    = makeSubTab("PlayerTab",    T.SubTabPlayer,    0,    true)
local songsSubTab     = makeSubTab("SongsTab",     T.SubTabSongs,     0.34, false)
local favoritesSubTab = makeSubTab("FavoritesTab", T.SubTabFavorites, 0.68, false)

local musicContent = Instance.new("Frame")
musicContent.Name = "MusicContent"
musicContent.Size = UDim2.new(1,0,1,-(SUBTAB_H+PAD))
musicContent.Position = UDim2.new(0,0,0,SUBTAB_H+PAD)
musicContent.BackgroundTransparency = 1
musicContent.ClipsDescendants = true; musicContent.Parent = musicPage

-- PLAYER PAGE
local playerPage = Instance.new("Frame")
playerPage.Name = "PlayerPage"; playerPage.Size = UDim2.new(1,0,1,0)
playerPage.BackgroundTransparency = 1; playerPage.ClipsDescendants = true; playerPage.Parent = musicContent

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Name = "PlayerScroll"; playerScroll.Size = UDim2.new(1,0,1,0)
playerScroll.BackgroundTransparency = 1; playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 4; playerScroll.ScrollBarImageColor3 = C.ScrollBar
playerScroll.CanvasSize = UDim2.new(0,0,0,CANVAS_H)
playerScroll.ClipsDescendants = true; playerScroll.Parent = playerPage
setupFixedScroll(playerScroll)

local nowPlayingFrame = Instance.new("Frame")
nowPlayingFrame.Name = "NowPlaying"; nowPlayingFrame.Size = UDim2.new(1,0,0,NP_H)
nowPlayingFrame.Position = UDim2.new(0,0,0,Y_NP); nowPlayingFrame.BackgroundColor3 = C.NowPlayingBg
nowPlayingFrame.BorderSizePixel = 0; nowPlayingFrame.ClipsDescendants = true; nowPlayingFrame.Parent = playerScroll
addCorner(nowPlayingFrame, CORNER_MD)

local thumbImg = Instance.new("ImageLabel")
thumbImg.Name = "Thumbnail"; thumbImg.Size = UDim2.new(0,THUMB_SZ,0,THUMB_SZ)
thumbImg.Position = UDim2.new(0,10,0.5,-THUMB_SZ/2); thumbImg.BackgroundColor3 = C.ThumbnailBg
thumbImg.BorderSizePixel = 0; thumbImg.ScaleType = Enum.ScaleType.Crop
thumbImg.Image = "rbxassetid://0"; thumbImg.Parent = nowPlayingFrame
addCorner(thumbImg, CORNER_MD)

local infoPanel = Instance.new("Frame")
infoPanel.Name = "InfoPanel"; infoPanel.Size = UDim2.new(1,-(THUMB_SZ+20+44),1,-16)
infoPanel.Position = UDim2.new(0,THUMB_SZ+20,0,8); infoPanel.BackgroundTransparency = 1
infoPanel.ClipsDescendants = true; infoPanel.Parent = nowPlayingFrame
local infoLayout = Instance.new("UIListLayout")
infoLayout.FillDirection = Enum.FillDirection.Vertical
infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0,6); infoLayout.Parent = infoPanel

local function makeInfoLbl(name, text, color, font, sz, order)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name; lbl.Text = text; lbl.Size = UDim2.new(1,0,0,sz+4)
	lbl.BackgroundTransparency = 1; lbl.TextColor3 = color; lbl.TextSize = sz
	lbl.TextWrapped = false; lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Font = font
	lbl.LayoutOrder = order; lbl.ClipsDescendants = true; lbl.Parent = infoPanel
	addSC(lbl, sz); return lbl
end

local songNameLbl  = makeInfoLbl("SongName",  T.NoSongPlaying, C.SongNameText,  Enum.Font.GothamBold, 16, 1)
local requesterLbl = makeInfoLbl("Requester", "",              C.RequesterText, Enum.Font.Gotham,     12, 2)

local addFavBtn = Instance.new("TextButton")
addFavBtn.Name = "AddFavBtn"; addFavBtn.Text = T.AddFavorite
addFavBtn.Size = UDim2.new(0,28,0,28); addFavBtn.Position = UDim2.new(1,-34,0,8)
addFavBtn.BackgroundColor3 = C.FavoriteBtn; addFavBtn.BorderSizePixel = 0
addFavBtn.TextColor3 = C.BtnText; addFavBtn.TextSize = 15; addFavBtn.Font = Enum.Font.GothamBold
addFavBtn.Visible = false; addFavBtn.AutoButtonColor = false; addFavBtn.Parent = nowPlayingFrame
addCorner(addFavBtn, 5)

-- PROGRESS BAR
local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressFrame"; progressFrame.Size = UDim2.new(1,0,0,PROGRESS_H+16)
progressFrame.Position = UDim2.new(0,0,0,Y_PROG); progressFrame.BackgroundTransparency = 1
progressFrame.ClipsDescendants = true; progressFrame.Parent = playerScroll

local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"; progressBg.Size = UDim2.new(1,-64,0,PROGRESS_H)
progressBg.Position = UDim2.new(0,0,0.5,-PROGRESS_H/2); progressBg.BackgroundColor3 = C.ProgressBg
progressBg.BorderSizePixel = 0; progressBg.ClipsDescendants = true; progressBg.Parent = progressFrame
addCorner(progressBg, PROGRESS_H/2)

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"; progressFill.Size = UDim2.new(0,0,1,0)
progressFill.BackgroundColor3 = C.ProgressFill; progressFill.BorderSizePixel = 0
progressFill.ClipsDescendants = true; progressFill.Parent = progressBg
addCorner(progressFill, PROGRESS_H/2)

if ThemeModule then
	local pg = Instance.new("UIGradient")
	local p1, p2 = ThemeModule.GetPrimaryColors()
	pg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0,p1), ColorSequenceKeypoint.new(0.5,ThemeModule.LerpColor(p1,p2,0.5)), ColorSequenceKeypoint.new(1,p2) })
	pg.Parent = progressFill
end

local progressDot = Instance.new("Frame")
progressDot.Name = "ProgressDot"; progressDot.Size = UDim2.new(0,PROGRESS_H+6,0,PROGRESS_H+6)
progressDot.Position = UDim2.new(1,-(PROGRESS_H+6)/2,0.5,-(PROGRESS_H+6)/2)
progressDot.BackgroundColor3 = Color3.fromRGB(255,255,255); progressDot.BorderSizePixel = 0
progressDot.Visible = false; progressDot.Parent = progressFill
addCorner(progressDot, (PROGRESS_H+6)/2)

local durationLbl = Instance.new("TextLabel")
durationLbl.Name = "Duration"; durationLbl.Text = "0:00 / 0:00"
durationLbl.Size = UDim2.new(0,60,1,0); durationLbl.Position = UDim2.new(1,-60,0,0)
durationLbl.BackgroundTransparency = 1; durationLbl.TextColor3 = C.DurationText
durationLbl.TextSize = 11; durationLbl.Font = Enum.Font.GothamSemibold
durationLbl.TextXAlignment = Enum.TextXAlignment.Right; durationLbl.Visible = false; durationLbl.Parent = progressFrame
addSC(durationLbl, 11)

-- CONTROLS (Skip only)
local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "Controls"; controlsFrame.Size = UDim2.new(1,0,0,CONTROLS_H)
controlsFrame.Position = UDim2.new(0,0,0,Y_CTRL); controlsFrame.BackgroundTransparency = 1
controlsFrame.ClipsDescendants = true; controlsFrame.Parent = playerScroll

local skipBtn = Instance.new("TextButton")
skipBtn.Name = "SkipBtn"; skipBtn.Text = T.SkipBtn
skipBtn.Size = UDim2.new(1,0,1,0)
skipBtn.BackgroundColor3 = C.SkipBtnDisabled; skipBtn.BorderSizePixel = 0
skipBtn.TextColor3 = C.BtnText; skipBtn.TextSize = 13; skipBtn.Font = Enum.Font.GothamBold
skipBtn.AutoButtonColor = false; skipBtn.Parent = controlsFrame
addCorner(skipBtn, CORNER_MD)

-- VOTE SKIP PANEL
local voteSkipPanel = Instance.new("Frame")
voteSkipPanel.Name = "VoteSkipPanel"; voteSkipPanel.Size = UDim2.new(1,0,0,VOTE_H)
voteSkipPanel.Position = UDim2.new(0,0,0,Y_CTRL); voteSkipPanel.BackgroundColor3 = C.VoteBg
voteSkipPanel.BorderSizePixel = 0; voteSkipPanel.Visible = false
voteSkipPanel.ClipsDescendants = true; voteSkipPanel.Parent = playerScroll
addCorner(voteSkipPanel, CORNER_MD)

local voteInfoLbl = Instance.new("TextLabel")
voteInfoLbl.Name = "VoteInfo"; voteInfoLbl.Text = "Vote Skip: 0/2 (30s)"
voteInfoLbl.Size = UDim2.new(1,-12,0,24); voteInfoLbl.Position = UDim2.new(0,6,0,4)
voteInfoLbl.BackgroundTransparency = 1; voteInfoLbl.TextColor3 = C.BtnText
voteInfoLbl.TextSize = 12; voteInfoLbl.Font = Enum.Font.GothamBold; voteInfoLbl.Parent = voteSkipPanel

local voteYesBtn = Instance.new("TextButton")
voteYesBtn.Name = "VoteYes"; voteYesBtn.Text = T.VoteYes
voteYesBtn.Size = UDim2.new(0.48,-4,0,28); voteYesBtn.Position = UDim2.new(0,6,0,30)
voteYesBtn.BackgroundColor3 = C.VoteYesBtn; voteYesBtn.BorderSizePixel = 0
voteYesBtn.TextColor3 = C.BtnText; voteYesBtn.TextSize = 12; voteYesBtn.Font = Enum.Font.GothamBold
voteYesBtn.AutoButtonColor = false; voteYesBtn.Parent = voteSkipPanel
addCorner(voteYesBtn, CORNER_SM)

local voteNoBtn = Instance.new("TextButton")
voteNoBtn.Name = "VoteNo"; voteNoBtn.Text = T.VoteNo
voteNoBtn.Size = UDim2.new(0.48,-4,0,28); voteNoBtn.Position = UDim2.new(0.52,-2,0,30)
voteNoBtn.BackgroundColor3 = C.VoteNoBtn; voteNoBtn.BorderSizePixel = 0
voteNoBtn.TextColor3 = C.BtnText; voteNoBtn.TextSize = 12; voteNoBtn.Font = Enum.Font.GothamBold
voteNoBtn.AutoButtonColor = false; voteNoBtn.Parent = voteSkipPanel
addCorner(voteNoBtn, CORNER_SM)

-- REQUEST INPUT
local reqFrame = Instance.new("Frame")
reqFrame.Name = "RequestFrame"; reqFrame.Size = UDim2.new(1,0,0,REQ_H)
reqFrame.Position = UDim2.new(0,0,0,Y_REQ); reqFrame.BackgroundTransparency = 1
reqFrame.ClipsDescendants = true; reqFrame.Parent = playerScroll

local reqInput = Instance.new("TextBox")
reqInput.Name = "ReqInput"; reqInput.PlaceholderText = T.SongIDPlaceholder; reqInput.Text = ""
reqInput.Size = UDim2.new(1,-(REQ_BTN_W+8),1,0); reqInput.BackgroundColor3 = C.InputBg
reqInput.BorderSizePixel = 0; reqInput.TextColor3 = C.InputText
reqInput.PlaceholderColor3 = Color3.fromRGB(150,150,150); reqInput.TextSize = 12
reqInput.Font = Enum.Font.Gotham; reqInput.TextXAlignment = Enum.TextXAlignment.Left
reqInput.ClearTextOnFocus = false; reqInput.ClipsDescendants = true; reqInput.Parent = reqFrame
addCorner(reqInput, CORNER_MD)
local reqPad = Instance.new("UIPadding", reqInput)
reqPad.PaddingLeft = UDim.new(0,10); reqPad.PaddingRight = UDim.new(0,10)

local reqBtn = Instance.new("TextButton")
reqBtn.Name = "ReqBtn"; reqBtn.Text = T.AddToQueue
reqBtn.Size = UDim2.new(0,REQ_BTN_W,1,0); reqBtn.Position = UDim2.new(1,-REQ_BTN_W,0,0)
reqBtn.BackgroundColor3 = C.AddBtn; reqBtn.BorderSizePixel = 0
reqBtn.TextColor3 = C.BtnText; reqBtn.TextSize = 12; reqBtn.Font = Enum.Font.GothamBold
reqBtn.AutoButtonColor = false; reqBtn.Parent = reqFrame
addCorner(reqBtn, CORNER_MD)

-- QUEUE
local queueTitleLbl = Instance.new("TextLabel")
queueTitleLbl.Name = "QueueTitle"; queueTitleLbl.Text = T.QueueTitle
queueTitleLbl.Size = UDim2.new(1,0,0,QTITLE_H); queueTitleLbl.Position = UDim2.new(0,0,0,Y_QTITLE)
queueTitleLbl.BackgroundTransparency = 1; queueTitleLbl.TextColor3 = Color3.fromRGB(255,255,255)
queueTitleLbl.TextSize = 13; queueTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
queueTitleLbl.Font = Enum.Font.GothamBold; queueTitleLbl.Parent = playerScroll
addSC(queueTitleLbl, 14); addTextGradient(queueTitleLbl, true)

local queueScroll = Instance.new("ScrollingFrame")
queueScroll.Name = "QueueScroll"; queueScroll.Size = UDim2.new(1,0,0,QUEUE_H)
queueScroll.Position = UDim2.new(0,0,0,Y_QUEUE); queueScroll.BackgroundColor3 = C.QueueBg
queueScroll.BorderSizePixel = 0; queueScroll.ScrollBarThickness = 5
queueScroll.ScrollBarImageColor3 = C.ScrollBar; queueScroll.ClipsDescendants = true; queueScroll.Parent = playerScroll
addCorner(queueScroll, CORNER_MD); setupAutoScroll(queueScroll)
Instance.new("UIListLayout", queueScroll).Padding = UDim.new(0,4)
local queuePad = Instance.new("UIPadding", queueScroll)
queuePad.PaddingTop = UDim.new(0,SCROLL_PAD); queuePad.PaddingBottom = UDim.new(0,SCROLL_PAD)
queuePad.PaddingLeft = UDim.new(0,SCROLL_PAD); queuePad.PaddingRight = UDim.new(0,SCROLL_PAD)

local queueEmptyLbl = Instance.new("TextLabel")
queueEmptyLbl.Name = "QueueEmpty"; queueEmptyLbl.Text = T.QueueEmpty
queueEmptyLbl.Size = UDim2.new(1,-16,0,30); queueEmptyLbl.Position = UDim2.new(0,8,0.5,-15)
queueEmptyLbl.BackgroundTransparency = 1; queueEmptyLbl.TextColor3 = C.AutoplayText
queueEmptyLbl.TextSize = 12; queueEmptyLbl.Font = Enum.Font.GothamSemibold
queueEmptyLbl.Visible = false; queueEmptyLbl.Parent = queueScroll

-- SONGS PAGE
local songsPage = Instance.new("Frame")
songsPage.Name = "SongsPage"; songsPage.Size = UDim2.new(1,0,1,0)
songsPage.BackgroundTransparency = 1; songsPage.Visible = false
songsPage.ClipsDescendants = true; songsPage.Parent = musicContent

local searchContainer = Instance.new("Frame")
searchContainer.Name = "SearchContainer"; searchContainer.Size = UDim2.new(1,0,0,SEARCH_H)
searchContainer.BackgroundTransparency = 1; searchContainer.Parent = songsPage

local searchBg = Instance.new("Frame")
searchBg.Name = "SearchBg"; searchBg.Size = UDim2.new(1,0,1,0)
searchBg.BackgroundColor3 = C.InputBg; searchBg.BorderSizePixel = 0; searchBg.Parent = searchContainer
addCorner(searchBg, CORNER_MD)

local searchInput = Instance.new("TextBox")
searchInput.Name = "SearchInput"; searchInput.PlaceholderText = T.SearchPlaceholder; searchInput.Text = ""
searchInput.Size = UDim2.new(1,-(CLEAR_BTN_W+4),1,0); searchInput.BackgroundTransparency = 1
searchInput.BorderSizePixel = 0; searchInput.TextColor3 = C.InputText
searchInput.PlaceholderColor3 = Color3.fromRGB(120,120,120); searchInput.TextSize = 13
searchInput.Font = Enum.Font.Gotham; searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false; searchInput.ClipsDescendants = true; searchInput.Parent = searchContainer
local sPad = Instance.new("UIPadding", searchInput)
sPad.PaddingLeft = UDim.new(0,12); sPad.PaddingRight = UDim.new(0,4)

local clearBtn = Instance.new("TextButton")
clearBtn.Name = "ClearBtn"; clearBtn.Text = "✕"
clearBtn.Size = UDim2.new(0,CLEAR_BTN_W-4,0,SEARCH_H-6)
clearBtn.Position = UDim2.new(1,-(CLEAR_BTN_W-2),0.5,-(SEARCH_H-6)/2)
clearBtn.BackgroundColor3 = C.ClearBtn; clearBtn.BorderSizePixel = 0
clearBtn.TextColor3 = Color3.fromRGB(255,255,255); clearBtn.TextSize = 14
clearBtn.Font = Enum.Font.GothamBold; clearBtn.Visible = false
clearBtn.AutoButtonColor = false; clearBtn.Parent = searchContainer
addCorner(clearBtn, CORNER_SM)

local songsTitleLbl = Instance.new("TextLabel")
songsTitleLbl.Name = "SongsTitle"; songsTitleLbl.Text = T.DefaultSongs
songsTitleLbl.Size = UDim2.new(1,0,0,22); songsTitleLbl.Position = UDim2.new(0,0,0,SEARCH_H+8)
songsTitleLbl.BackgroundTransparency = 1; songsTitleLbl.TextColor3 = Color3.fromRGB(255,255,255)
songsTitleLbl.TextSize = 13; songsTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
songsTitleLbl.Font = Enum.Font.GothamBold; songsTitleLbl.Parent = songsPage
addSC(songsTitleLbl, 14); addTextGradient(songsTitleLbl, true)

local songsScrollY = SEARCH_H + 8 + 22 + 6
local songsScroll = Instance.new("ScrollingFrame")
songsScroll.Name = "SongsScroll"; songsScroll.Size = UDim2.new(1,0,1,-songsScrollY)
songsScroll.Position = UDim2.new(0,0,0,songsScrollY); songsScroll.BackgroundColor3 = C.SongsBg
songsScroll.BorderSizePixel = 0; songsScroll.ScrollBarThickness = 6
songsScroll.ScrollBarImageColor3 = C.ScrollBar; songsScroll.ClipsDescendants = true; songsScroll.Parent = songsPage
addCorner(songsScroll, CORNER_MD); setupAutoScroll(songsScroll)
Instance.new("UIListLayout", songsScroll).Padding = UDim.new(0,4)
local songsPad = Instance.new("UIPadding", songsScroll)
songsPad.PaddingTop = UDim.new(0,SCROLL_PAD); songsPad.PaddingBottom = UDim.new(0,SCROLL_PAD)
songsPad.PaddingLeft = UDim.new(0,SCROLL_PAD); songsPad.PaddingRight = UDim.new(0,SCROLL_PAD)

local noResultsLbl = Instance.new("TextLabel")
noResultsLbl.Name = "NoResults"; noResultsLbl.Text = "Tidak ada hasil ditemukan"
noResultsLbl.Size = UDim2.new(1,-16,0,40); noResultsLbl.Position = UDim2.new(0,8,0.5,-20)
noResultsLbl.BackgroundTransparency = 1; noResultsLbl.TextColor3 = Color3.fromRGB(180,180,180)
noResultsLbl.TextSize = 13; noResultsLbl.Font = Enum.Font.GothamSemibold
noResultsLbl.Visible = false; noResultsLbl.Parent = songsScroll

-- FAVORITES PAGE
local favPage = Instance.new("Frame")
favPage.Name = "FavPage"; favPage.Size = UDim2.new(1,0,1,0)
favPage.BackgroundTransparency = 1; favPage.Visible = false
favPage.ClipsDescendants = true; favPage.Parent = musicContent

local favTitleLbl = Instance.new("TextLabel")
favTitleLbl.Name = "FavTitle"; favTitleLbl.Text = T.MyFavorites
favTitleLbl.Size = UDim2.new(1,0,0,22); favTitleLbl.BackgroundTransparency = 1
favTitleLbl.TextColor3 = Color3.fromRGB(255,255,255); favTitleLbl.TextSize = 13
favTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; favTitleLbl.Font = Enum.Font.GothamBold
favTitleLbl.Parent = favPage; addSC(favTitleLbl, 14); addTextGradient(favTitleLbl, true)

local favScroll = Instance.new("ScrollingFrame")
favScroll.Name = "FavScroll"; favScroll.Size = UDim2.new(1,0,1,-28)
favScroll.Position = UDim2.new(0,0,0,26); favScroll.BackgroundColor3 = C.FavBg
favScroll.BorderSizePixel = 0; favScroll.ScrollBarThickness = 6
favScroll.ScrollBarImageColor3 = C.ScrollBar; favScroll.ClipsDescendants = true; favScroll.Parent = favPage
addCorner(favScroll, CORNER_MD); setupAutoScroll(favScroll)
Instance.new("UIListLayout", favScroll).Padding = UDim.new(0,4)
local favPad = Instance.new("UIPadding", favScroll)
favPad.PaddingTop = UDim.new(0,SCROLL_PAD); favPad.PaddingBottom = UDim.new(0,SCROLL_PAD)
favPad.PaddingLeft = UDim.new(0,SCROLL_PAD); favPad.PaddingRight = UDim.new(0,SCROLL_PAD)

local favLockedLbl = Instance.new("TextLabel")
favLockedLbl.Name = "FavLocked"; favLockedLbl.Text = T.FavoritesLocked
favLockedLbl.Size = UDim2.new(1,-16,0,40); favLockedLbl.Position = UDim2.new(0,8,0.5,-20)
favLockedLbl.BackgroundTransparency = 1; favLockedLbl.TextColor3 = C.FavLocked
favLockedLbl.TextSize = 12; favLockedLbl.Font = Enum.Font.GothamBold
favLockedLbl.Visible = false; favLockedLbl.Parent = favScroll

local favEmptyLbl = Instance.new("TextLabel")
favEmptyLbl.Name = "FavEmpty"; favEmptyLbl.Text = "Belum ada lagu favorit"
favEmptyLbl.Size = UDim2.new(1,-16,0,40); favEmptyLbl.Position = UDim2.new(0,8,0.5,-20)
favEmptyLbl.BackgroundTransparency = 1; favEmptyLbl.TextColor3 = Color3.fromRGB(150,150,150)
favEmptyLbl.TextSize = 12; favEmptyLbl.Font = Enum.Font.GothamSemibold
favEmptyLbl.Visible = false; favEmptyLbl.Parent = favScroll

if ThemeModule and ThemeModule.GradientSystem then ThemeModule.GradientSystem.Start() end

-- ====================================
-- HELPER RUNTIME
-- ====================================
local function updateProgressBar(timePos, timeLen)
	currentTimePos = timePos or 0
	currentTimeLen = timeLen or 0
	if timeLen and timeLen > 0 then
		local progress = math.clamp(timePos / timeLen, 0, 1)
		TweenService:Create(progressFill, TweenInfo.new(0.15, Enum.EasingStyle.Linear), { Size = UDim2.new(progress,0,1,0) }):Play()
		durationLbl.Text    = string.format(T.DurationFormat, fmtTime(timePos), fmtTime(timeLen))
		durationLbl.Visible = true
		progressDot.Visible = true
	else
		progressFill.Size   = UDim2.new(0,0,1,0)
		durationLbl.Visible = false
		progressDot.Visible = false
	end
end

local function updateSkipButton()
	skipBtn.BackgroundColor3 = clientState.currentSong and C.SkipBtn or C.SkipBtnDisabled
end

local function updateVoteSkipUI()
	if voteSkipState.active then
		controlsFrame.Visible = false
		voteSkipPanel.Visible = true
		voteInfoLbl.Text = string.format("Vote Skip: %d/%d (%ds)", voteSkipState.yesVotes, voteSkipState.required, voteSkipState.timeRemaining)
		voteYesBtn.BackgroundColor3 = voteSkipState.hasVoted and Color3.fromRGB(80,80,80) or C.VoteYesBtn
		voteNoBtn.BackgroundColor3  = voteSkipState.hasVoted and Color3.fromRGB(80,80,80) or C.VoteNoBtn
	else
		controlsFrame.Visible  = true
		voteSkipPanel.Visible  = false
		voteSkipState.hasVoted = false
	end
end

local function updateFavoriteUI()
	canFavorite = isVIPPlus()
	if canFavorite then
		favoritesSubTab.Text       = T.SubTabFavorites
		favoritesSubTab.TextColor3 = C.SubTabText
		addFavBtn.BackgroundColor3 = C.FavoriteBtn
	else
		favoritesSubTab.Text       = T.SubTabFavLocked
		favoritesSubTab.TextColor3 = C.SubTabTextDisabled
		addFavBtn.BackgroundColor3 = C.FavBtnDisabled
	end
end

local function updateQueue()
	for _, c in ipairs(queueScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local queue = clientState.queue or {}
	queueEmptyLbl.Visible = (#queue == 0 and clientState.isAutoplay)
	if #queue == 0 then return end
	for i, song in ipairs(queue) do
		local songData = song.musicData or song
		local item = Instance.new("Frame")
		item.Name = "QI_"..i; item.Size = UDim2.new(1,0,0,QUEUE_ITEM_H)
		item.BackgroundColor3 = C.QueueItem; item.BorderSizePixel = 0
		item.LayoutOrder = i; item.ClipsDescendants = true; item.Parent = queueScroll
		addCorner(item, CORNER_SM)
		local numLbl = Instance.new("TextLabel")
		numLbl.Size = UDim2.new(0,28,1,0); numLbl.BackgroundTransparency = 1
		numLbl.Text = tostring(i); numLbl.TextColor3 = C.QueueRequester
		numLbl.TextSize = 12; numLbl.Font = Enum.Font.GothamBold
		numLbl.TextXAlignment = Enum.TextXAlignment.Center
		numLbl.TextYAlignment = Enum.TextYAlignment.Center; numLbl.Parent = item
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.65,-28,0,QUEUE_ITEM_H/2); nameLbl.Position = UDim2.new(0,28,0,0)
		nameLbl.BackgroundTransparency = 1; nameLbl.Text = songData.judul or T.Unknown
		nameLbl.TextColor3 = C.QueueSongText; nameLbl.TextSize = 12; nameLbl.Font = Enum.Font.GothamSemibold
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextYAlignment = Enum.TextYAlignment.Bottom; nameLbl.Parent = item; addSC(nameLbl,13)
		local reqLbl = Instance.new("TextLabel")
		reqLbl.Size = UDim2.new(0.65,-28,0,QUEUE_ITEM_H/2); reqLbl.Position = UDim2.new(0,28,0.5,0)
		reqLbl.BackgroundTransparency = 1; reqLbl.Text = "👤 "..(song.uploader or T.Unknown)
		reqLbl.TextColor3 = C.QueueRequester; reqLbl.TextSize = 11; reqLbl.Font = Enum.Font.Gotham
		reqLbl.TextTruncate = Enum.TextTruncate.AtEnd
		reqLbl.TextXAlignment = Enum.TextXAlignment.Left; reqLbl.Parent = item; addSC(reqLbl,11)
		local dur = songData.Duration or 0
		if dur > 0 then
			local durLbl = Instance.new("TextLabel")
			durLbl.Size = UDim2.new(0.35,-8,1,0); durLbl.Position = UDim2.new(0.65,0,0,0)
			durLbl.BackgroundTransparency = 1; durLbl.Text = fmtTime(dur)
			durLbl.TextColor3 = C.QueueRequester; durLbl.TextSize = 11; durLbl.Font = Enum.Font.GothamSemibold
			durLbl.TextXAlignment = Enum.TextXAlignment.Right; durLbl.Parent = item; addSC(durLbl,11)
		end
	end
end

-- SONGS
local function norm(s) return string.lower(string.gsub(s or "","  %s+"," ")) end
local function doSearch(query)
	currentSearchQuery = query
	if query == "" then filteredSongs = defaultSongs; return defaultSongs end
	local nq = norm(query)
	local exact, starts, contains = {},{},{}
	for _, song in ipairs(defaultSongs) do
		local sn = norm(song.judul or song.name or "")
		if sn == nq then table.insert(exact, song)
		elseif string.sub(sn,1,#nq) == nq then table.insert(starts, song)
		elseif string.find(sn,nq,1,true) then table.insert(contains, song)
		end
	end
	local results = {}
	for _,s in ipairs(exact)    do table.insert(results,s) end
	for _,s in ipairs(starts)   do table.insert(results,s) end
	for _,s in ipairs(contains) do table.insert(results,s) end
	filteredSongs = results; return results
end

local function updateSongsTitle(searching, count, query)
	removeGradient(songsTitleLbl)
	if searching and query ~= "" then
		if count > 0 then
			songsTitleLbl.Text = count..' hasil untuk "'..query..'"'
			songsTitleLbl.TextColor3 = Color3.fromRGB(150,255,150)
		else
			songsTitleLbl.Text = 'Tidak ada hasil untuk "'..query..'"'
			songsTitleLbl.TextColor3 = Color3.fromRGB(255,150,150)
		end
	else
		songsTitleLbl.Text = T.DefaultSongs.." ("..count..")"
		songsTitleLbl.TextColor3 = Color3.fromRGB(255,255,255)
		addTextGradient(songsTitleLbl, true)
	end
end

local function updateSongs(list)
	local display = list or filteredSongs
	if #display == 0 and currentSearchQuery == "" then display = defaultSongs end
	for _, c in ipairs(songsScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	updateSongsTitle(currentSearchQuery ~= "", #display, currentSearchQuery)
	noResultsLbl.Visible = (#display == 0 and currentSearchQuery ~= "")
	if #display == 0 then
		if currentSearchQuery ~= "" and tick() - lastNoResults > 3 then
			lastNoResults = tick()
			notifyWarning(T.SearchTitle, 'Tidak ada lagu untuk "'..currentSearchQuery..'"')
		end
		return
	end
	for idx, song in ipairs(display) do
		local songName = song.judul or song.name or T.Unknown
		local item = Instance.new("Frame")
		item.Name = "SI_"..idx; item.Size = UDim2.new(1,0,0,SONG_ITEM_H)
		item.BackgroundColor3 = C.SongsItem; item.BorderSizePixel = 0
		item.LayoutOrder = idx; item.ClipsDescendants = true; item.Parent = songsScroll
		addCorner(item, CORNER_SM)
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = songName; nameLbl.Size = UDim2.new(1,-80,1,0)
		nameLbl.Position = UDim2.new(0,10,0,0); nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3 = C.SongText; nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextYAlignment = Enum.TextYAlignment.Center
		nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ClipsDescendants = true; nameLbl.Parent = item; addSC(nameLbl,14)
		local pb = Instance.new("TextButton")
		pb.Text = T.AddToQueue; pb.Size = UDim2.new(0,64,0,SONG_ITEM_H-12)
		pb.Position = UDim2.new(1,-70,0.5,-(SONG_ITEM_H-12)/2); pb.BackgroundColor3 = C.AddBtn
		pb.BorderSizePixel = 0; pb.TextColor3 = C.FavBtnText; pb.Font = Enum.Font.GothamBold
		pb.TextSize = 11; pb.AutoButtonColor = false; pb.Parent = item; addCorner(pb, CORNER_SM)
		local capSong = song
		pb.MouseButton1Click:Connect(function()
			if not isVIPPlus() then notifyWarning(T.VIPRequired, "Minimum rank VIP untuk menambah lagu!"); return end
			dispatch("ADD_TO_QUEUE", { musicId = tostring(capSong.id), isFromPlaylist = true })
		end)
	end
end

-- FAVORITES
local FAVORITES_KEY = "MusicFavorites_"..tostring(player.UserId)
local function saveFavorites()
	pcall(function()
		player.PlayerGui:SetAttribute(FAVORITES_KEY, game:GetService("HttpService"):JSONEncode(userFavorites))
	end)
end
local function loadFavorites()
	local ok, result = pcall(function()
		local raw = player.PlayerGui:GetAttribute(FAVORITES_KEY)
		if raw then return game:GetService("HttpService"):JSONDecode(raw) end
		return {}
	end)
	userFavorites = (ok and result) or {}
end

local function updateFavorites()
	for _, c in ipairs(favScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if not canFavorite then favLockedLbl.Visible = true; favEmptyLbl.Visible = false; return end
	favLockedLbl.Visible = false; favEmptyLbl.Visible = (#userFavorites == 0)
	if #userFavorites == 0 then return end
	for idx, song in ipairs(userFavorites) do
		local item = Instance.new("Frame")
		item.Name = "FI_"..idx; item.Size = UDim2.new(1,0,0,FAV_ITEM_H)
		item.BackgroundColor3 = C.FavItem; item.BorderSizePixel = 0
		item.LayoutOrder = idx; item.ClipsDescendants = true; item.Parent = favScroll
		addCorner(item, CORNER_SM)
		local ft = Instance.new("ImageLabel")
		ft.Size = UDim2.new(0,FAV_THUMB_SZ,0,FAV_THUMB_SZ)
		ft.Position = UDim2.new(0,6,0.5,-FAV_THUMB_SZ/2); ft.BackgroundColor3 = C.FavThumb
		ft.BorderSizePixel = 0; ft.ScaleType = Enum.ScaleType.Crop
		ft.Image = song.sampul or song.thumbnail or "rbxassetid://0"; ft.Parent = item
		addCorner(ft, CORNER_SM)
		local ix = FAV_THUMB_SZ + 12
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = song.judul or song.name or T.Unknown
		nameLbl.Size = UDim2.new(1,-(ix+76),1,0); nameLbl.Position = UDim2.new(0,ix,0,0)
		nameLbl.BackgroundTransparency = 1; nameLbl.TextColor3 = C.FavSongText; nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextYAlignment = Enum.TextYAlignment.Center
		nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ClipsDescendants = true; nameLbl.Parent = item; addSC(nameLbl,14)
		local bSz = 30
		local pb = Instance.new("TextButton")
		pb.Text = T.AddToQueue; pb.Size = UDim2.new(0,bSz+14,0,bSz)
		pb.Position = UDim2.new(1,-(bSz+14)*2-10,0.5,-bSz/2); pb.BackgroundColor3 = C.FavPlayBtn
		pb.BorderSizePixel = 0; pb.TextColor3 = C.FavBtnText; pb.Font = Enum.Font.GothamBold
		pb.TextSize = 11; pb.AutoButtonColor = false; pb.Parent = item; addCorner(pb, CORNER_SM)
		local rb = Instance.new("TextButton")
		rb.Text = T.Remove; rb.Size = UDim2.new(0,bSz,0,bSz)
		rb.Position = UDim2.new(1,-bSz-4,0.5,-bSz/2); rb.BackgroundColor3 = C.FavRemoveBtn
		rb.BorderSizePixel = 0; rb.TextColor3 = C.FavBtnText; rb.Font = Enum.Font.GothamBold
		rb.TextSize = 14; rb.AutoButtonColor = false; rb.Parent = item; addCorner(rb, CORNER_SM)
		local capSong = song
		pb.MouseButton1Click:Connect(function()
			dispatch("ADD_TO_QUEUE", { musicId = tostring(capSong.id), isFromPlaylist = true })
		end)
		rb.MouseButton1Click:Connect(function()
			table.remove(userFavorites, idx); saveFavorites(); updateFavorites()
			notifySuccess(T.SuccessTitle, '"'..(capSong.judul or capSong.name or "")..'" dihapus dari favorit')
		end)
	end
end

-- SUB-TAB SWITCH
local subPages = { player = playerPage, songs = songsPage, favorites = favPage }
local subBtns  = { player = playerSubTab, songs = songsSubTab, favorites = favoritesSubTab }

local function switchSubTab(tab)
	currentSubTab = tab
	for name, btn in pairs(subBtns) do
		local isActive   = (name == tab)
		local isDisabled = (name == "favorites" and not canFavorite)
		removeGradient(btn)
		if isActive then
			btn.BackgroundColor3 = C.SubTabActive; btn.TextColor3 = C.SubTabTextActive
			addGradient(btn, 90, false)
		elseif isDisabled then
			btn.BackgroundColor3 = C.SubTabDisabled; btn.TextColor3 = C.SubTabTextDisabled
		else
			btn.BackgroundColor3 = C.SubTabInactive; btn.TextColor3 = C.SubTabText
		end
	end
	for name, page in pairs(subPages) do page.Visible = (name == tab) end
	if tab == "songs" then
		defaultSongs = MusicModule:GetAllMusic(); filteredSongs = defaultSongs
		currentSearchQuery = ""; searchInput.Text = ""; clearBtn.Visible = false
		updateSongsTitle(false, #defaultSongs, ""); updateSongs(defaultSongs)
	elseif tab == "favorites" then
		loadFavorites(); updateFavorites()
	end
end

-- ====================================
-- PROGRESS LOOP (DIPERBAIKI — SMOOTH)
-- ====================================
-- PERBAIKAN UTAMA: Gunakan HANYA shared-clock interpolation
-- untuk progress bar. Ini memberikan smooth progress tanpa
-- lompatan yang disebabkan oleh pertarungan antara TimePosition
-- replicated dan koreksi client.
local progressConnection
local function startProgressLoop()
	if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
	progressConnection = RunService.Heartbeat:Connect(function()
		if not MenuConfig.State.isMenuOpen or MenuConfig.State.currentMainTab ~= "Music" then return end

		if clientState.isPlaying and clientState.serverStartTime > 0 then
			-- PERBAIKAN: Selalu gunakan shared-clock interpolation
			-- Ini smooth dan konsisten, tidak tergantung replication timing
			local elapsed = workspace:GetServerTimeNow() - clientState.serverStartTime
			elapsed = math.clamp(elapsed, 0, clientState.duration or 9999)
			updateProgressBar(elapsed, clientState.duration)

		elseif clientState.currentSong then
			-- Fallback: gunakan data terakhir dari server
			updateProgressBar(currentTimePos, currentTimeLen)
		else
			updateProgressBar(0, 0)
		end
	end)
end
local function stopProgressLoop()
	if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
end

-- BUTTON CONNECTIONS
playerSubTab.MouseButton1Click:Connect(function() switchSubTab("player") end)
songsSubTab.MouseButton1Click:Connect(function() switchSubTab("songs") end)
favoritesSubTab.MouseButton1Click:Connect(function()
	switchSubTab("favorites")
	if not canFavorite then notifyWarning(T.VIPRequired, "Fitur Favorit hanya untuk VIP+") end
end)

reqBtn.MouseButton1Click:Connect(function()
	if not isVIPPlus() then notifyWarning(T.VIPRequired, "Minimum rank VIP untuk menambah lagu!"); return end
	local id = reqInput.Text:gsub("%s+","")
	if id ~= "" and id:match("^%d+$") then
		dispatch("ADD_TO_QUEUE", { musicId = id, isFromPlaylist = false })
		reqInput.Text = ""
	else
		notifyWarning(T.ErrorTitle, "Masukkan ID lagu yang valid!")
	end
end)

skipBtn.MouseButton1Click:Connect(function()
	if not clientState.currentSong then notifyWarning(T.WarningTitle, T.NoSongToSkip); return end
	dispatch("CONTROL_NEXT", {})
end)

voteYesBtn.MouseButton1Click:Connect(function()
	if voteSkipState.hasVoted then return end
	voteSkipState.hasVoted = true; dispatch("SKIP_VOTE_YES", {}); updateVoteSkipUI()
end)
voteNoBtn.MouseButton1Click:Connect(function()
	if voteSkipState.hasVoted then return end
	voteSkipState.hasVoted = true; dispatch("SKIP_VOTE_NO", {}); updateVoteSkipUI()
end)

addFavBtn.MouseButton1Click:Connect(function()
	if not canFavorite then notifyWarning(T.VIPRequired, "Fitur Favorit hanya untuk VIP+"); return end
	if not clientState.currentSong then return end
	for _, s in ipairs(userFavorites) do
		if s.id == clientState.currentSong.id then notifyWarning(T.MusicTitle, "Lagu sudah ada di favorit!"); return end
	end
	table.insert(userFavorites, clientState.currentSong); saveFavorites()
	notifySuccess(T.SuccessTitle, '"'..(clientState.currentSong.judul or "")..'" ditambahkan ke favorit!')
end)

local searchDebounce
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	local q = searchInput.Text; clearBtn.Visible = (q ~= "")
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce = task.delay(0.2, function() searchDebounce = nil; updateSongs(doSearch(q)) end)
end)
clearBtn.MouseButton1Click:Connect(function()
	searchInput.Text = ""; currentSearchQuery = ""; clearBtn.Visible = false
	filteredSongs = defaultSongs; updateSongsTitle(false, #defaultSongs, ""); updateSongs(defaultSongs)
end)

-- ====================================
-- NOTIFIKASI FILTER (BARU)
-- ====================================
-- Blokir pesan sistem yang mengganggu, hanya tampilkan yang relevan ke user
local BLOCKED_NOTIFY_PATTERNS = {
	"^Sistem musik",         -- "Sistem musik sedang diinisialisasi...", "Sistem musik siap!..."
	"^Menunggu playlist",    -- "Menunggu playlist dari server..."
	"^Playlist dimuat",      -- "Playlist dimuat: X lagu tersedia"
	"^Peringatan: Gagal",    -- "Peringatan: Gagal memuat playlist dari API."
	"^Selamat datang",       -- "Selamat datang! Ketik /retry..."
	"^Sinkronisasi",         -- "Sinkronisasi... (Percobaan #X)"
	"^Tersinkron",           -- "Tersinkron! Sedang diputar:..."
	"^Sync terlalu",         -- "Sync terlalu cepat, harap tunggu..."
	"^Terdeteksi banyak",    -- "Terdeteksi banyak percobaan sync..."
	"^Gagal memuat lagu",    -- "Gagal memuat lagu, melewati..."
}

local function isNotifyBlocked(message)
	for _, pattern in ipairs(BLOCKED_NOTIFY_PATTERNS) do
		if message:match(pattern) then
			return true
		end
	end
	return false
end

-- ====================================
-- EVENT HANDLERS (DIPERBAIKI)
-- ====================================

dispatchEvent.OnClientEvent:Connect(function(event)
	if type(event) ~= "table" or type(event.type) ~= "string" then return end
	local payload = event.payload or {}

	if event.type == "SYNC_STATE" then
		clientState.queue           = payload.queue or {}
		clientState.currentSong     = payload.currentSong
		clientState.currentUploader = payload.currentUploader
		clientState.isPlaying       = payload.isPlaying or false
		clientState.duration        = payload.duration or 0
		clientState.serverStartTime = payload.serverStartTime or payload.startTime or 0

		updateQueue()
		if clientState.currentSong then
			songNameLbl.Text = clientState.currentSong.judul or T.Unknown
			if payload.isAutoplay then
				requesterLbl.Text = T.AutoplayLabel; requesterLbl.TextColor3 = C.AutoplayText
				clientState.isAutoplay = true
			else
				requesterLbl.Text = T.RequestedBy..(clientState.currentUploader or T.Unknown)
				requesterLbl.TextColor3 = C.RequesterText; clientState.isAutoplay = false
			end
			thumbImg.Image = clientState.currentSong.sampul or "rbxassetid://0"
			addFavBtn.Visible = true; currentTimeLen = clientState.duration

			local syncPos = calculateSyncPosition(clientState.serverStartTime, clientState.duration)
			updateProgressBar(syncPos, clientState.duration)

			-- Sinkronkan posisi audio SEKALI
			if clientState.currentSong.id then
				syncServerSoundPosition(clientState.currentSong.id, clientState.serverStartTime, clientState.duration)
			end
		else
			songNameLbl.Text = T.NoSongPlaying; requesterLbl.Text = ""
			thumbImg.Image = "rbxassetid://0"; addFavBtn.Visible = false
			updateProgressBar(0, 0)
		end
		updateSkipButton()

	elseif event.type == "QUEUE_UPDATE" then
		clientState.queue = payload.queue or {}; updateQueue()

	elseif event.type == "NOTIFY" then
		local msg = payload.message or ""
		-- PERBAIKAN: Filter notifikasi yang mengganggu
		if isNotifyBlocked(msg) then return end
		if msg:find("berhasil") or msg:find("added") or msg:find("Sukses") then notifySuccess(T.MusicTitle, msg)
		elseif msg:find("Error") or msg:find("gagal") or msg:find("Invalid") then notifyError(T.MusicTitle, msg)
		elseif msg:find("Tunggu") or msg:find("Cooldown") or msg:find("wait") then notifyWarning(T.MusicTitle, msg)
		else notifyInfo(T.MusicTitle, msg) end

	elseif event.type == "SKIP_VOTE_START" then
		voteSkipState.active = true; voteSkipState.yesVotes = 0; voteSkipState.noVotes = 0
		voteSkipState.timeRemaining = 30; voteSkipState.hasVoted = false
		updateVoteSkipUI()
		notifyInfo(T.MusicTitle, string.format("%s memulai vote skip: %s", payload.initiator or "?", payload.songTitle or "?"))

	elseif event.type == "SKIP_VOTE_UPDATE" then
		voteSkipState.yesVotes = payload.yesVotes or 0; voteSkipState.noVotes = payload.noVotes or 0
		voteSkipState.required = math.floor((payload.totalVoters or 2)/2)+1; updateVoteSkipUI()

	elseif event.type == "SKIP_VOTE_END" then
		voteSkipState.active = false; voteSkipState.hasVoted = false; updateVoteSkipUI()
		if payload.result == "passed" then notifySuccess(T.MusicTitle, "Vote skip berhasil! Melewati lagu...")
		else notifyWarning(T.MusicTitle, "Vote skip gagal. Lagu dilanjutkan.") end
	end
end)

-- ====================================
-- MUSIC BROADCAST HANDLER (DIPERBAIKI)
-- ====================================

musicBroadcast.OnClientEvent:Connect(function(broadcastType, payload)
	if type(broadcastType) ~= "string" then return end
	payload = payload or {}

	if broadcastType == "SongUpdate" then
		clientState.currentSong = {
			id     = payload.SoundId,
			judul  = payload.Title,
			sampul = "rbxthumb://type=Asset&id="..(payload.SoundId or "0").."&w=150&h=150",
		}
		clientState.currentUploader = payload.AddedBy
		clientState.duration        = payload.Duration or 0
		clientState.isPlaying       = true
		clientState.serverStartTime = payload.ServerStartTime or 0
		currentTimeLen = clientState.duration

		songNameLbl.Text = payload.Title or T.Unknown
		if payload.AddedBy == "Auto-Playlist" then
			requesterLbl.Text = T.AutoplayLabel; requesterLbl.TextColor3 = C.AutoplayText; clientState.isAutoplay = true
		else
			requesterLbl.Text = T.RequestedBy..(payload.AddedBy or T.Unknown)
			requesterLbl.TextColor3 = C.RequesterText; clientState.isAutoplay = false
		end
		thumbImg.Image = clientState.currentSong.sampul; addFavBtn.Visible = true
		updateProgressBar(0, clientState.duration); updateSkipButton()

		-- PERBAIKAN: Sync posisi SEKALI via syncServerSoundPosition (mute→seek→fade-in)
		-- Tidak perlu applyVolume() + clientFadeIn() terpisah lagi
		if payload.SoundId then
			syncServerSoundPosition(payload.SoundId, clientState.serverStartTime, clientState.duration)
		end

	elseif broadcastType == "StopMusic" then
		clientFadeOut(CLIENT_FADE_OUT_DUR)

		clientState.currentSong     = nil
		clientState.currentUploader = nil
		clientState.isPlaying       = false
		clientState.isAutoplay      = false
		clientState.serverStartTime = 0
		songNameLbl.Text = T.NoSongPlaying; requesterLbl.Text = ""
		thumbImg.Image = "rbxassetid://0"; addFavBtn.Visible = false
		updateProgressBar(0, 0); updateSkipButton()

	elseif broadcastType == "Progress" then
		currentTimePos = payload.Current or 0
		currentTimeLen = payload.Duration or currentTimeLen
		-- Update serverStartTime untuk interpolation
		if payload.ServerStartTime and payload.ServerStartTime > 0 then
			clientState.serverStartTime = payload.ServerStartTime
		end

		-- PERBAIKAN: TIDAK ada koreksi posisi di sini!
		-- Sebelumnya di sini ada auto-desync correction yang menyebabkan
		-- audio "kasar" karena terus-menerus mengeset TimePosition.
		-- Sekarang progress bar hanya menggunakan shared-clock interpolation.
	end
end)

-- ====================================
-- SYNC MUSIC HANDLER (UNTUK PEMAIN BARU)
-- ====================================

musicUpdate.OnClientEvent:Connect(function(syncType, data)
	if syncType == "SyncMusic" and data then
		clientState.currentSong = {
			id     = data.SoundId,
			judul  = data.Title,
			sampul = "rbxthumb://type=Asset&id="..(data.SoundId or "0").."&w=150&h=150",
		}
		clientState.currentUploader = data.AddedBy
		clientState.duration        = data.Duration or 0
		clientState.isPlaying       = data.IsPlaying or false
		clientState.serverStartTime = data.ServerStartTime or 0

		local syncPos = calculateSyncPosition(data.ServerStartTime, data.Duration)
		currentTimePos = syncPos
		currentTimeLen = data.Duration or 0

		songNameLbl.Text = data.Title or T.NoSongPlaying
		requesterLbl.Text = data.AddedBy and (T.RequestedBy..data.AddedBy) or ""
		thumbImg.Image = clientState.currentSong.sampul
		addFavBtn.Visible = clientState.currentSong ~= nil
		updateProgressBar(syncPos, currentTimeLen)
		updateSkipButton()

		-- PERBAIKAN: Sync audio SEKALI via syncServerSoundPosition (mute→seek→fade-in)
		if data.SoundId then
			syncServerSoundPosition(data.SoundId, data.ServerStartTime, data.Duration)
		end
	end
end)

-- ====================================
-- SETTINGS & MENU EVENTS
-- ====================================

if MenuConfig.Events and MenuConfig.Events.OnSettingChanged then
	MenuConfig.Events.OnSettingChanged.Event:Connect(function(key, value)
		if key == "muteMusic" then isMuted = value; applyVolume()
		elseif key == "musicVolume" then userVolume = value/100; if not isMuted then applyVolume() end end
	end)
end

MenuConfig.Events.OnMenuToggled.Event:Connect(function(isOpen)
	if isOpen and MenuConfig.State.currentMainTab == "Music" then startProgressLoop()
	else stopProgressLoop() end
end)
MenuConfig.Events.OnTabChanged.Event:Connect(function(tab)
	if tab == "Music" then startProgressLoop() else stopProgressLoop() end
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

-- ====================================
-- INITIALIZATION
-- ====================================
task.spawn(function()
	task.wait(1)
	loadFavorites()
	isMuted    = MenuConfig.UserSettings and MenuConfig.UserSettings.muteMusic or false
	userVolume = (MenuConfig.UserSettings and MenuConfig.UserSettings.musicVolume or 50) / 100
	refreshRoleUI()
	requestSync:FireServer()
	task.wait(0.5)
	if MenuConfig.State.isMenuOpen and MenuConfig.State.currentMainTab == "Music" then
		startProgressLoop()
	end
	switchSubTab("player")
end)

SoundService.ChildAdded:Connect(function(child)
	if child.Name == "ServerMusicSound" then
		task.wait(0.2)
		if not syncInProgress then
			applyVolume()
		end
		watchServerSound()
	end
end)

local ssConn
local function watchServerSound()
	if ssConn then ssConn:Disconnect() end
	local ss = SoundService:FindFirstChild("ServerMusicSound")
	if ss then
		ssConn = ss:GetPropertyChangedSignal("IsPlaying"):Connect(function()
			if ss.IsPlaying then
				task.wait(0.1)
				if not syncInProgress then
					applyVolume()
				end
				-- PERBAIKAN: TIDAK ada koreksi posisi di sini!
				-- Koreksi hanya dilakukan SEKALI oleh syncServerSoundPosition()
				-- saat lagu baru dimulai atau player baru join.
				-- Koreksi berulang di sini menyebabkan audio "kasar".
			end
		end)
	end
end
watchServerSound()
