--[[
	PlaylistCard.lua - Daftar lagu hitam-putih, bersih dan rapi.
	FavoriteMap TIDAK disimpan di sini -- diterima dari luar via Update(favoriteMap).
	Ini memastikan single source of truth ada di MusicPage.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local TitleCleaner = require(ReplicatedStorage.Shared.Utils.TitleCleaner)

local PlaylistCard = {}
PlaylistCard.__index = PlaylistCard

function PlaylistCard.new(onSongSelected, onSongQueued, onFavoriteToggled, headerText, emptyText)
	local self = setmetatable({}, PlaylistCard)

	local container = Instance.new("Frame")
	container.Name = "PlaylistCardContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Theme.Colors.CardBackground
	container.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadius)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Thickness = 1
	stroke.Parent = container

	-- Header tipis
	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, 0, 0, 24)
	hdr.BackgroundColor3 = Theme.Colors.Surface
	hdr.BorderSizePixel = 0
	hdr.Parent = container

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadius)
	hCorner.Parent = hdr

	local hFix = Instance.new("Frame")
	hFix.Size = UDim2.new(1, 0, 0, 8)
	hFix.Position = UDim2.new(0, 0, 1, -8)
	hFix.BackgroundColor3 = Theme.Colors.Surface
	hFix.BorderSizePixel = 0
	hFix.Parent = hdr

	local hLbl = Instance.new("TextLabel")
	hLbl.Size = UDim2.new(1, -8, 1, 0)
	hLbl.Position = UDim2.new(0, 8, 0, 0)
	hLbl.BackgroundTransparency = 1
	hLbl.Text = "🎶 " .. (headerText or UIStrings.Music.GlobalPlaylistHeader)
	hLbl.TextColor3 = Theme.Colors.Text
	hLbl.Font = Theme.Fonts.Header
	hLbl.TextSize = Theme.TextSizes.Header
	hLbl.TextXAlignment = Enum.TextXAlignment.Left
	hLbl.Parent = hdr

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "PlaylistScroll"
	scroll.Size = UDim2.new(1, -12, 1, -28)
	scroll.Position = UDim2.new(0, 6, 0, 26)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Theme.Colors.StrokeHighlight
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 3)
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 4)
	end)

	self.Instance    = container
	self.Scroll      = scroll
	self.OnSongSelected   = onSongSelected
	self.OnSongQueued     = onSongQueued
	self.OnFavoriteToggled = onFavoriteToggled
	self.EmptyText   = emptyText
	self._lastKey    = nil   -- cache key untuk deteksi perubahan
	return self
end

--[[
	Update(playlistData, currentSoundId, favoriteMap)
	  playlistData  : tabel lagu { {title, sound_id, ...}, ... }
	  currentSoundId: sound_id lagu yang sedang diputar (rbxassetid://... atau string number)
	  favoriteMap   : { [soundId_string] = true } -- dari MusicPage (single source of truth)
]]
function PlaylistCard:Update(playlistData, currentSoundId, favoriteMap)
	favoriteMap = favoriteMap or {}

	-- Cache key: jumlah lagu + soundId aktif + jumlah favorit
	-- Re-render hanya ketika salah satunya berubah
	local favCount = 0
	for _ in pairs(favoriteMap) do favCount += 1 end
	local newKey = tostring(#(playlistData or {})) .. "|" .. tostring(currentSoundId) .. "|fav" .. favCount

	if self._lastKey == newKey then return end
	self._lastKey = newKey

	-- Bersihkan elemen lama
	for _, c in ipairs(self.Scroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	-- Pesan kosong
	if not playlistData or #playlistData == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 60)
		lbl.BackgroundTransparency = 1
		lbl.Text = "⚠ " .. (self.EmptyText or UIStrings.Music.EmptyPlaylist)
		lbl.TextColor3 = Theme.Colors.TextSubtle
		lbl.Font = Theme.Fonts.Body
		lbl.TextSize = Theme.TextSizes.Body
		lbl.TextWrapped = true
		lbl.Parent = self.Scroll
		return
	end

	-- Render setiap lagu
	for idx, song in ipairs(playlistData) do
		local soundIdStr = tostring(song.sound_id)
		local isCurrent  = (soundIdStr == tostring(currentSoundId))
		-- isFav ditangkap saat RENDER ini (bukan dari event click)
		local isFav = favoriteMap[soundIdStr] == true

		local card = Instance.new("Frame")
		card.Name = "Song_" .. idx
		card.Size = UDim2.new(1, -4, 0, 32)
		card.BackgroundColor3 = isCurrent and Theme.Colors.SurfaceActive or Theme.Colors.Surface
		card.BorderSizePixel = 0

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 5)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = isCurrent and Theme.Colors.StrokeBright or Theme.Colors.Stroke
		cStroke.Thickness = 1
		cStroke.Transparency = isCurrent and 0.2 or 0.6
		cStroke.Parent = card

		-- Nomor / indikator
		local num = Instance.new("TextLabel")
		num.Size = UDim2.new(0, 28, 1, 0)
		num.Position = UDim2.new(0, 28, 0, 0)
		num.BackgroundTransparency = 1
		num.Text = isCurrent and "▶" or tostring(idx)
		num.TextColor3 = isCurrent and Theme.Colors.Text or Theme.Colors.TextSubtle
		num.Font = isCurrent and Theme.Fonts.Header or Theme.Fonts.Body
		num.TextSize = Theme.TextSizes.Small
		num.TextXAlignment = Enum.TextXAlignment.Center
		num.Parent = card

		-- Tombol bintang favorit
		local favBtn = Instance.new("TextButton")
		favBtn.Size = UDim2.new(0, 20, 0, 20)
		favBtn.Position = UDim2.new(0, 5, 0.5, -10)
		favBtn.BackgroundTransparency = 1
		favBtn.Text = isFav and "★" or "☆"
		favBtn.TextColor3 = isFav and Theme.Colors.Text or Theme.Colors.TextSubtle
		favBtn.Font = Theme.Fonts.Header
		favBtn.TextSize = 13
		favBtn.AutoButtonColor = false
		-- Kirim status BARU (kebalikan isFav saat render) ke callback
		-- MusicPage akan update FavoriteMap & paksa re-render
		favBtn.MouseButton1Click:Connect(function()
			if self.OnFavoriteToggled then
				self.OnFavoriteToggled(song, not isFav)
			end
		end)
		favBtn.Parent = card

		-- Label judul
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -155, 1, 0)
		title.Position = UDim2.new(0, 58, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = TitleCleaner.CleanTitle(song.title)
		title.TextColor3 = isCurrent and Theme.Colors.Text or Theme.Colors.TextMuted
		title.Font = isCurrent and Theme.Fonts.Header or Theme.Fonts.Body
		title.TextSize = Theme.TextSizes.Body
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		-- Tombol Antre
		local qBtn = Instance.new("TextButton")
		qBtn.Size = UDim2.new(0, 82, 0, 22)
		qBtn.Position = UDim2.new(1, -88, 0.5, -11)
		qBtn.BackgroundColor3 = isCurrent and Theme.Colors.SurfaceActive or Theme.Colors.CardBackground
		qBtn.BorderSizePixel = 0
		qBtn.Text = isCurrent and ("▶ " .. UIStrings.SubTabs.NowPlaying) or UIStrings.Music.AddQueue
		qBtn.TextColor3 = isCurrent and Theme.Colors.Text or Theme.Colors.TextMuted
		qBtn.Font = Theme.Fonts.Header
		qBtn.TextSize = Theme.TextSizes.Small
		qBtn.AutoButtonColor = false

		local qCorner = Instance.new("UICorner")
		qCorner.CornerRadius = UDim.new(0, 4)
		qCorner.Parent = qBtn

		local qStroke = Instance.new("UIStroke")
		qStroke.Color = isCurrent and Theme.Colors.StrokeHighlight or Theme.Colors.Stroke
		qStroke.Thickness = 1
		qStroke.Transparency = 0.4
		qStroke.Parent = qBtn

		if not isCurrent then
			qBtn.MouseEnter:Connect(function()
				TweenService:Create(qBtn, TweenInfo.new(Theme.Animation.Fast), {
					BackgroundColor3 = Theme.Colors.SurfaceHover,
					TextColor3 = Theme.Colors.Text,
				}):Play()
			end)
			qBtn.MouseLeave:Connect(function()
				TweenService:Create(qBtn, TweenInfo.new(Theme.Animation.Fast), {
					BackgroundColor3 = Theme.Colors.CardBackground,
					TextColor3 = Theme.Colors.TextMuted,
				}):Play()
			end)
			qBtn.MouseButton1Click:Connect(function()
				TweenService:Create(qBtn, TweenInfo.new(0.06), {Size=UDim2.new(0,76,0,18)}):Play()
				task.delay(0.08, function()
					TweenService:Create(qBtn, TweenInfo.new(0.06), {Size=UDim2.new(0,82,0,22)}):Play()
				end)
				if self.OnSongQueued then self.OnSongQueued(song, idx) end
			end)
		end

		qBtn.Parent = card
		card.Parent = self.Scroll
	end
end

function PlaylistCard:Destroy()
	if self.Instance then self.Instance:Destroy() end
end

return PlaylistCard
