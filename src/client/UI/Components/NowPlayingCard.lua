--[[
	NowPlayingCard.lua
	Tujuan: Komponen "Sedang Diputar" — hitam-putih gradient berputar reaktif beat.
	Layout bersih: header kiri, EQ kanan, judul, artis, progress bar, waktu.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local TitleCleaner = require(ReplicatedStorage.Shared.Utils.TitleCleaner)

local NowPlayingCard = {}
NowPlayingCard.__index = NowPlayingCard

local function formatTime(secs)
	if not secs or secs ~= secs or secs < 0 then secs = 0 end
	return string.format("%d:%02d", math.floor(secs/60), math.floor(secs%60))
end

function NowPlayingCard.new()
	local self = setmetatable({}, NowPlayingCard)
	self.BeatLevel = 0

	-- ========== Frame Utama (tinggi tetap) ==========
	local frame = Instance.new("Frame")
	frame.Name = "NowPlayingCard"
	frame.Size = UDim2.new(1, 0, 0, 130)
	frame.BackgroundColor3 = Theme.Colors.Background
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadius)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.StrokeHighlight
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = frame

	-- Background gradient hitam-putih berputar
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,    Theme.Colors.BeatBlack),
		ColorSequenceKeypoint.new(0.45, Theme.Colors.BeatDark),
		ColorSequenceKeypoint.new(0.8,  Theme.Colors.BeatMid),
		ColorSequenceKeypoint.new(1,    Theme.Colors.BeatBlack),
	})
	bgGrad.Rotation = 0
	bgGrad.Parent = frame

	-- ========== Row 1: Label SEDANG DIPUTAR + EQ Bars ==========
	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, -16, 0, 20)
	headerRow.Position = UDim2.new(0, 8, 0, 7)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = frame

	local nowPlayLabel = Instance.new("TextLabel")
	nowPlayLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nowPlayLabel.BackgroundTransparency = 1
	nowPlayLabel.Text = "● " .. UIStrings.Music.NowPlaying
	nowPlayLabel.TextColor3 = Theme.Colors.Text
	nowPlayLabel.Font = Theme.Fonts.Header
	nowPlayLabel.TextSize = Theme.TextSizes.Small
	nowPlayLabel.TextXAlignment = Enum.TextXAlignment.Left
	nowPlayLabel.Parent = headerRow

	-- EQ container (kanan)
	local eqContainer = Instance.new("Frame")
	eqContainer.Size = UDim2.new(0.45, 0, 1, 0)
	eqContainer.Position = UDim2.new(0.55, 0, 0, 0)
	eqContainer.BackgroundTransparency = 1
	eqContainer.Parent = headerRow

	local eqLayout = Instance.new("UIListLayout")
	eqLayout.FillDirection = Enum.FillDirection.Horizontal
	eqLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	eqLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	eqLayout.Padding = UDim.new(0, 2)
	eqLayout.Parent = eqContainer

	local eqBars = {}
	for i = 1, 8 do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 5, 0.5, 0)
		bar.BackgroundColor3 = Theme.Colors.Primary
		bar.BorderSizePixel = 0

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 2)
		bc.Parent = bar

		bar.Parent = eqContainer
		table.insert(eqBars, bar)
	end

	-- ========== Row 2: Judul Lagu ==========
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "SongTitleLabel"
	titleLabel.Size = UDim2.new(1, -16, 0, 22)
	titleLabel.Position = UDim2.new(0, 8, 0, 30)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = UIStrings.Music.Loading
	titleLabel.TextColor3 = Theme.Colors.Text
	titleLabel.Font = Theme.Fonts.Title
	titleLabel.TextSize = Theme.TextSizes.Title
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame

	-- ========== Row 3: Artis ==========
	local artistLabel = Instance.new("TextLabel")
	artistLabel.Name = "ArtistLabel"
	artistLabel.Size = UDim2.new(1, -16, 0, 14)
	artistLabel.Position = UDim2.new(0, 8, 0, 54)
	artistLabel.BackgroundTransparency = 1
	artistLabel.Text = UIStrings.Music.ServerSource
	artistLabel.TextColor3 = Theme.Colors.TextMuted
	artistLabel.Font = Theme.Fonts.Body
	artistLabel.TextSize = Theme.TextSizes.Body
	artistLabel.TextXAlignment = Enum.TextXAlignment.Left
	artistLabel.Parent = frame

	-- ========== Progress Bar ==========
	local progressBG = Instance.new("Frame")
	progressBG.Size = UDim2.new(1, -16, 0, 5)
	progressBG.Position = UDim2.new(0, 8, 0, 78)
	progressBG.BackgroundColor3 = Theme.Colors.ProgressTrack
	progressBG.BorderSizePixel = 0
	progressBG.Parent = frame

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(1, 0)
	pCorner.Parent = progressBG

	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Theme.Colors.Primary
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBG

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(1, 0)
	fCorner.Parent = progressFill

	-- Gradient putih→abu pada fill
	local fGrad = Instance.new("UIGradient")
	fGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Colors.BeatMid),
		ColorSequenceKeypoint.new(1, Theme.Colors.BeatWhite),
	})
	fGrad.Parent = progressFill

	-- ========== Waktu ==========
	local timeElapsed = Instance.new("TextLabel")
	timeElapsed.Size = UDim2.new(0, 50, 0, 14)
	timeElapsed.Position = UDim2.new(0, 8, 0, 87)
	timeElapsed.BackgroundTransparency = 1
	timeElapsed.Text = "0:00"
	timeElapsed.TextColor3 = Theme.Colors.TextSubtle
	timeElapsed.Font = Theme.Fonts.Code
	timeElapsed.TextSize = Theme.TextSizes.Small
	timeElapsed.TextXAlignment = Enum.TextXAlignment.Left
	timeElapsed.Parent = frame

	local timeTotal = Instance.new("TextLabel")
	timeTotal.Size = UDim2.new(0, 50, 0, 14)
	timeTotal.Position = UDim2.new(1, -58, 0, 87)
	timeTotal.BackgroundTransparency = 1
	timeTotal.Text = "0:00"
	timeTotal.TextColor3 = Theme.Colors.TextSubtle
	timeTotal.Font = Theme.Fonts.Code
	timeTotal.TextSize = Theme.TextSizes.Small
	timeTotal.TextXAlignment = Enum.TextXAlignment.Right
	timeTotal.Parent = frame

	-- ========== Render Loop ==========
	local eqTime = 0
	local gradAngle = 0

	local conn = RunService.RenderStepped:Connect(function(dt)
		eqTime += dt
		local beat = self.BeatLevel or 0

		-- EQ Bars: hitam→putih sesuai beat
		for i, bar in ipairs(eqBars) do
			local h = 0.15 + 0.55 * math.abs(math.sin(eqTime * (1.4 + i*0.3) + i))
			h = math.min(1, h + beat * 0.35)
			bar.Size = UDim2.new(0, 5, h, 0)
			-- Warna makin putih saat beat tinggi
			local bright = math.floor(80 + beat * 175)
			bar.BackgroundColor3 = Color3.fromRGB(bright, bright, bright)
		end

		-- Gradient berputar, kencang saat beat
		local speed = 8 + beat * 30
		gradAngle = (gradAngle + dt * speed) % 360
		bgGrad.Rotation = gradAngle

		local midBright = math.floor(30 + beat * 120)
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Theme.Colors.BeatBlack),
			ColorSequenceKeypoint.new(0.4,  Color3.fromRGB(midBright, midBright, midBright)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(midBright*2, midBright*2, midBright*2)),
			ColorSequenceKeypoint.new(1,    Theme.Colors.BeatBlack),
		})

		-- Stroke dan fill bergerak
		fGrad.Rotation = (gradAngle * 2) % 360
		stroke.Transparency = math.max(0, 0.5 - beat * 0.4)
		stroke.Color = Color3.fromRGB(
			math.floor(80 + beat * 175),
			math.floor(80 + beat * 175),
			math.floor(80 + beat * 175)
		)

		-- Label "SEDANG DIPUTAR" berkedip saat beat tinggi
		if beat > 0.6 then
			nowPlayLabel.TextColor3 = Theme.Colors.AccentBright
		else
			nowPlayLabel.TextColor3 = Theme.Colors.TextMuted
		end
	end)

	self.Instance = frame
	self.TitleLabel = titleLabel
	self.ArtistLabel = artistLabel
	self.ProgressFill = progressFill
	self.TimeElapsed = timeElapsed
	self.TimeTotal = timeTotal
	self.BgGrad = bgGrad
	self.Conn = conn

	return self
end

function NowPlayingCard:Update(title, artist, currentPos, totalLength, beatLevel)
	if beatLevel ~= nil then self.BeatLevel = beatLevel end

	if self.TitleLabel then
		self.TitleLabel.Text = TitleCleaner.CleanTitle(title)
	end
	if self.ArtistLabel then
		self.ArtistLabel.Text = artist or UIStrings.Music.ServerSource
	end
	if totalLength and totalLength > 0 then
		local pct = math.clamp(currentPos / totalLength, 0, 1)
		self.ProgressFill.Size = UDim2.new(pct, 0, 1, 0)
		self.TimeElapsed.Text = formatTime(currentPos)
		self.TimeTotal.Text = formatTime(totalLength)
	else
		self.ProgressFill.Size = UDim2.new(0, 0, 1, 0)
		self.TimeElapsed.Text = "0:00"
		self.TimeTotal.Text = "0:00"
	end
end

function NowPlayingCard:Destroy()
	if self.Conn then self.Conn:Disconnect() end
	if self.Instance then self.Instance:Destroy() end
end

return NowPlayingCard
