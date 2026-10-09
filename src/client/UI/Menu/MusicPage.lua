--[[
	MusicPage.lua
	Tujuan: Layout halaman musik dengan 4 sub-tab (Diputar, Daftar Lagu, Favorit, Antrean).
	Mendukung halaman khusus lagu favorit yang tersimpan ke DataStore server.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local NowPlayingCard  = require(script.Parent.Parent.Components.NowPlayingCard)
local MusicControls   = require(script.Parent.Parent.Components.MusicControls)
local VolumeSlider    = require(script.Parent.Parent.Components.VolumeSlider)
local PlaylistCard    = require(script.Parent.Parent.Components.PlaylistCard)
local QueueList       = require(script.Parent.Parent.Components.QueueList)
local SearchBar       = require(script.Parent.Parent.Components.SearchBar)

local MusicPage = {}
MusicPage.__index = MusicPage

-- Helper: buat tombol sub-tab
local function makeTabBtn(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 92, 1, -4)
	btn.BackgroundColor3 = Theme.Colors.Surface
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Theme.Colors.TextSubtle
	btn.Font = Theme.Fonts.Header
	btn.TextSize = Theme.TextSizes.Small
	btn.AutoButtonColor = false

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = Theme.Colors.Stroke
	s.Thickness = 1
	s.Transparency = 0.5
	s.Parent = btn

	return btn, s
end

function MusicPage.new(callbacks)
	callbacks = callbacks or {}
	local self = setmetatable({}, MusicPage)

	local searchQuery = ""
	local favSearchQuery = ""
	self.FavoriteMap = {}

	-- Container Utama
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MusicPageContainer"
	mainContainer.Size = UDim2.new(1, 0, 1, 0)
	mainContainer.BackgroundTransparency = 1

	-- Sub-Tab Bar (tinggi 30px)
	local subTabBar = Instance.new("Frame")
	subTabBar.Name = "SubTabBar"
	subTabBar.Size = UDim2.new(1, 0, 0, 30)
	subTabBar.Position = UDim2.new(0, 0, 0, 0)
	subTabBar.BackgroundColor3 = Theme.Colors.CardBackground
	subTabBar.BorderSizePixel = 0
	subTabBar.Parent = mainContainer

	local stCorner = Instance.new("UICorner")
	stCorner.CornerRadius = UDim.new(0, 6)
	stCorner.Parent = subTabBar

	local stStroke = Instance.new("UIStroke")
	stStroke.Color = Theme.Colors.Stroke
	stStroke.Thickness = 1
	stStroke.Parent = subTabBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = subTabBar

	local btnNowPlaying, strokeNP = makeTabBtn(UIStrings.SubTabs.NowPlaying)
	btnNowPlaying.Parent = subTabBar

	local btnPlaylist, strokePL = makeTabBtn(UIStrings.SubTabs.Playlist)
	btnPlaylist.Parent = subTabBar

	local btnFav, strokeFAV = makeTabBtn(UIStrings.SubTabs.Favorites)
	btnFav.Parent = subTabBar

	local btnQueue, strokeQ = makeTabBtn(UIStrings.SubTabs.Queue)
	btnQueue.Parent = subTabBar

	-- View Containers (mulai dari y=33)
	local viewY = 33

	-- VIEW 1: Sedang Diputar
	local viewNP = Instance.new("Frame")
	viewNP.Name = "ViewNowPlaying"
	viewNP.Size = UDim2.new(1, 0, 1, -viewY)
	viewNP.Position = UDim2.new(0, 0, 0, viewY)
	viewNP.BackgroundTransparency = 1
	viewNP.Visible = true
	viewNP.Parent = mainContainer

	local npLayout = Instance.new("UIListLayout")
	npLayout.SortOrder = Enum.SortOrder.LayoutOrder
	npLayout.Padding = UDim.new(0, 6)
	npLayout.Parent = viewNP

	-- VIEW 2: Daftar Lagu Lengkap
	local viewPL = Instance.new("Frame")
	viewPL.Name = "ViewPlaylist"
	viewPL.Size = UDim2.new(1, 0, 1, -viewY)
	viewPL.Position = UDim2.new(0, 0, 0, viewY)
	viewPL.BackgroundTransparency = 1
	viewPL.Visible = false
	viewPL.Parent = mainContainer

	local plLayout = Instance.new("UIListLayout")
	plLayout.SortOrder = Enum.SortOrder.LayoutOrder
	plLayout.Padding = UDim.new(0, 5)
	plLayout.Parent = viewPL

	-- VIEW 3: Halaman Favorit Saya
	local viewFAV = Instance.new("Frame")
	viewFAV.Name = "ViewFavorites"
	viewFAV.Size = UDim2.new(1, 0, 1, -viewY)
	viewFAV.Position = UDim2.new(0, 0, 0, viewY)
	viewFAV.BackgroundTransparency = 1
	viewFAV.Visible = false
	viewFAV.Parent = mainContainer

	local favLayout = Instance.new("UIListLayout")
	favLayout.SortOrder = Enum.SortOrder.LayoutOrder
	favLayout.Padding = UDim.new(0, 5)
	favLayout.Parent = viewFAV

	-- VIEW 4: Antrean
	local viewQ = Instance.new("Frame")
	viewQ.Name = "ViewQueue"
	viewQ.Size = UDim2.new(1, 0, 1, -viewY)
	viewQ.Position = UDim2.new(0, 0, 0, viewY)
	viewQ.BackgroundTransparency = 1
	viewQ.Visible = false
	viewQ.Parent = mainContainer

	-- ========== Komponen View 1 ==========
	local nowPlayingCard = NowPlayingCard.new()
	nowPlayingCard.Instance.LayoutOrder = 1
	nowPlayingCard.Instance.Parent = viewNP

	local musicControls = MusicControls.new(callbacks.onVoteSkip, function() end)
	musicControls.Instance.LayoutOrder = 2
	musicControls.Instance.Parent = viewNP

	local volumeSlider = VolumeSlider.new(callbacks.onVolumeChanged)
	volumeSlider.Instance.LayoutOrder = 3
	volumeSlider.Instance.Parent = viewNP

	-- ========== Callback Toggling Favorite ==========
	local handleFavToggle = function(song, isFav)
		if song and song.sound_id then
			self.FavoriteMap[tostring(song.sound_id)] = isFav
			-- Paksa re-render kedua kartu dengan mereset cache key
			if self.PlaylistCard then self.PlaylistCard._lastKey = nil end
			if self.FavPlaylistCard then self.FavPlaylistCard._lastKey = nil end
		end
		if callbacks.onFavoriteToggled then
			callbacks.onFavoriteToggled(song, isFav)
		end
	end

	-- ========== Komponen View 2 (Daftar Lagu) ==========
	local searchBarPL = SearchBar.new(function(query)
		searchQuery = string.lower(query or "")
	end)
	searchBarPL.Instance.LayoutOrder = 1
	searchBarPL.Instance.Parent = viewPL

	local playlistCard = PlaylistCard.new(
		callbacks.onSelectSong,
		callbacks.onQueueSong,
		handleFavToggle
	)
	playlistCard.Instance.Size = UDim2.new(1, 0, 1, -39)
	playlistCard.Instance.LayoutOrder = 2
	playlistCard.Instance.Parent = viewPL

	-- ========== Komponen View 3 (Favorit Saya) ==========
	local searchBarFAV = SearchBar.new(function(query)
		favSearchQuery = string.lower(query or "")
	end)
	searchBarFAV.Instance.LayoutOrder = 1
	searchBarFAV.Instance.Parent = viewFAV

	local favPlaylistCard = PlaylistCard.new(
		callbacks.onSelectSong,
		callbacks.onQueueSong,
		handleFavToggle,
		UIStrings.Music.FavoritesHeader,   -- header: "Favorit Saya"
		UIStrings.Music.EmptyFavorites     -- empty: "Belum ada lagu favorit..."
	)
	favPlaylistCard.Instance.Size = UDim2.new(1, 0, 1, -39)
	favPlaylistCard.Instance.LayoutOrder = 2
	favPlaylistCard.Instance.Parent = viewFAV

	-- ========== Komponen View 4 (Antrean) ==========
	local queueList = QueueList.new()
	queueList.Instance.Size = UDim2.new(1, 0, 1, 0)
	queueList.Instance.Parent = viewQ

	-- ========== Switch Sub-Tab ==========
	local function setTab(name)
		local tabs = {
			{ btn=btnNowPlaying, s=strokeNP,  key="NowPlaying", view=viewNP  },
			{ btn=btnPlaylist,   s=strokePL,  key="Playlist",   view=viewPL  },
			{ btn=btnFav,        s=strokeFAV, key="Favorites",  view=viewFAV },
			{ btn=btnQueue,      s=strokeQ,   key="Queue",      view=viewQ   },
		}
		for _, t in ipairs(tabs) do
			local on = (t.key == name)
			TweenService:Create(t.btn, TweenInfo.new(Theme.Animation.Fast), {
				BackgroundColor3 = on and Theme.Colors.Primary or Theme.Colors.Surface,
				TextColor3       = on and Theme.Colors.TextDark or Theme.Colors.TextSubtle,
			}):Play()
			t.s.Color        = on and Theme.Colors.StrokeBright or Theme.Colors.Stroke
			t.s.Transparency = on and 0.2 or 0.5
			t.view.Visible   = on
		end
	end

	btnNowPlaying.MouseButton1Click:Connect(function() setTab("NowPlaying") end)
	btnPlaylist.MouseButton1Click:Connect(function() setTab("Playlist") end)
	btnFav.MouseButton1Click:Connect(function() setTab("Favorites") end)
	btnQueue.MouseButton1Click:Connect(function() setTab("Queue") end)

	setTab("NowPlaying")

	-- Simpan Referensi
	self.Instance = mainContainer
	self.NowPlayingCard = nowPlayingCard
	self.MusicControls = musicControls
	self.VolumeSlider = volumeSlider
	self.PlaylistCard = playlistCard
	self.FavPlaylistCard = favPlaylistCard
	self.QueueList = queueList
	self.GetSearchQuery = function() return searchQuery end
	self.GetFavSearchQuery = function() return favSearchQuery end

	return self
end

function MusicPage:SetFavorites(favList)
	if type(favList) == "table" then
		for _, soundId in ipairs(favList) do
			self.FavoriteMap[tostring(soundId)] = true
		end
		-- Paksa re-render kedua kartu
		if self.PlaylistCard then self.PlaylistCard._lastKey = nil end
		if self.FavPlaylistCard then self.FavPlaylistCard._lastKey = nil end
	end
end

function MusicPage:Update(stateData)
	if not stateData then return end

	if self.NowPlayingCard then
		self.NowPlayingCard:Update(
			stateData.title,
			stateData.artist,
			stateData.position,
			stateData.duration,
			stateData.beatLevel
		)
	end

	if self.MusicControls then
		self.MusicControls:UpdateVotes(stateData.votesCount, stateData.votesNeeded)
	end

	if stateData.playlist then
		-- 1. Update Daftar Lagu
		local query = self.GetSearchQuery()
		local listPL = stateData.playlist
		if query ~= "" then
			local filtered = {}
			for _, song in ipairs(stateData.playlist) do
				if string.find(string.lower(song.title or ""), query, 1, true) then
					table.insert(filtered, song)
				end
			end
			listPL = filtered
		end
		-- Pass FavoriteMap ke PlaylistCard agar render bintang benar
		self.PlaylistCard:Update(listPL, stateData.soundId, self.FavoriteMap)

		-- 2. Update Favorit: filter dari playlist berdasarkan FavoriteMap
		local favQuery = self.GetFavSearchQuery()
		local favList = {}
		for _, song in ipairs(stateData.playlist) do
			local isFav = self.FavoriteMap[tostring(song.sound_id)] == true
			local okQuery = (favQuery == "") or string.find(string.lower(song.title or ""), favQuery, 1, true)
			if isFav and okQuery then
				table.insert(favList, song)
			end
		end
		self.FavPlaylistCard:Update(favList, stateData.soundId, self.FavoriteMap)
	end

	if self.QueueList then
		self.QueueList:Update(stateData.queue)
	end
end

function MusicPage:Destroy()
	if self.Instance then self.Instance:Destroy() end
end

return MusicPage
