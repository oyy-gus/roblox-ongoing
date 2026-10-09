--[[
	MusicControls.lua
	Tujuan: Kontrol musik minimalis — hanya Vote Skip + Favorit.
	(Shuffle, Repeat, Sleep Timer sudah dihapus sesuai permintaan)
	Tema hitam-putih bersih.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

local MusicControls = {}
MusicControls.__index = MusicControls

local function makeBtn(name, text, w, active)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, w or 140, 0, 28)
	btn.BackgroundColor3 = active and Theme.Colors.Primary or Theme.Colors.Surface
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = active and Theme.Colors.TextDark or Theme.Colors.TextMuted
	btn.Font = Theme.Fonts.Header
	btn.TextSize = Theme.TextSizes.Body
	btn.AutoButtonColor = false

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusSmall)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = active and Theme.Colors.Primary or Theme.Colors.Stroke
	s.Thickness = 1
	s.Transparency = active and 0 or 0.4
	s.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = Theme.Colors.SurfaceHover,
			TextColor3 = Theme.Colors.Text,
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = active and Theme.Colors.Primary or Theme.Colors.Surface,
			TextColor3 = active and Theme.Colors.TextDark or Theme.Colors.TextMuted,
		}):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.06), {
			Size = UDim2.new(0, (w or 140) - 4, 0, 24)
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.06), {
			Size = UDim2.new(0, w or 140, 0, 28)
		}):Play()
	end)

	return btn, s
end

function MusicControls.new(onVoteSkip, onFavoriteToggle)
	local self = setmetatable({}, MusicControls)
	self.IsFavoriteFilterActive = false

	-- Container tipis satu baris
	local container = Instance.new("Frame")
	container.Name = "MusicControls"
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = Theme.Colors.CardBackground
	container.BorderSizePixel = 0

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusSmall)
	cCorner.Parent = container

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Theme.Colors.Stroke
	cStroke.Thickness = 1
	cStroke.Parent = container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = container

	-- Tombol Vote Skip
	local btnVoteSkip, _ = makeBtn("VoteSkipButton", string.format(UIStrings.Music.VoteSkip, 0, 1), 150, false)
	btnVoteSkip.Parent = container
	if onVoteSkip then
		btnVoteSkip.MouseButton1Click:Connect(onVoteSkip)
	end

	-- Tombol Filter Favorit
	local btnFavorite, favStroke = makeBtn("FavoriteButton", UIStrings.Music.FavoriteMy, 135, false)
	btnFavorite.Parent = container
	btnFavorite.MouseButton1Click:Connect(function()
		self.IsFavoriteFilterActive = not self.IsFavoriteFilterActive
		local on = self.IsFavoriteFilterActive
		btnFavorite.Text = on and UIStrings.Music.FavoriteOn or UIStrings.Music.FavoriteMy
		btnFavorite.BackgroundColor3 = on and Theme.Colors.Primary or Theme.Colors.Surface
		btnFavorite.TextColor3 = on and Theme.Colors.TextDark or Theme.Colors.TextMuted
		favStroke.Color = on and Theme.Colors.Primary or Theme.Colors.Stroke
		if onFavoriteToggle then onFavoriteToggle() end
	end)

	self.Instance = container
	self.BtnVoteSkip = btnVoteSkip
	self.BtnFavorite = btnFavorite

	return self
end

function MusicControls:UpdateVotes(votesCount, votesNeeded)
	if self.BtnVoteSkip then
		self.BtnVoteSkip.Text = string.format(UIStrings.Music.VoteSkip,
			votesCount or 0, votesNeeded or 1)
	end
end

function MusicControls:Destroy()
	if self.Instance then
		self.Instance:Destroy()
	end
end

return MusicControls
