--[[
	VolumeSlider.lua — Volume slider hitam-putih bersih.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)

local VolumeSlider = {}
VolumeSlider.__index = VolumeSlider

function VolumeSlider.new(onVolumeChanged)
	local self = setmetatable({}, VolumeSlider)

	local container = Instance.new("Frame")
	container.Name = "VolumeSliderContainer"
	container.Size = UDim2.new(1, 0, 0, 34)
	container.BackgroundColor3 = Theme.Colors.CardBackground
	container.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusSmall)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Stroke
	stroke.Thickness = 1
	stroke.Parent = container

	-- Tombol Mute
	local muteBtn = Instance.new("TextButton")
	muteBtn.Size = UDim2.new(0, 30, 0, 26)
	muteBtn.Position = UDim2.new(0, 4, 0.5, -13)
	muteBtn.BackgroundColor3 = Theme.Colors.Surface
	muteBtn.BorderSizePixel = 0
	muteBtn.Text = "🔊"
	muteBtn.TextColor3 = Theme.Colors.Text
	muteBtn.Font = Theme.Fonts.Header
	muteBtn.TextSize = Theme.TextSizes.Header
	muteBtn.AutoButtonColor = false

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 4)
	mCorner.Parent = muteBtn
	muteBtn.Parent = container

	-- Label
	local volText = Instance.new("TextLabel")
	volText.Size = UDim2.new(0, 50, 1, 0)
	volText.Position = UDim2.new(0, 37, 0, 0)
	volText.BackgroundTransparency = 1
	volText.Text = UIStrings.Music.Volume
	volText.TextColor3 = Theme.Colors.TextSubtle
	volText.Font = Theme.Fonts.Body
	volText.TextSize = Theme.TextSizes.Small
	volText.TextXAlignment = Enum.TextXAlignment.Left
	volText.Parent = container

	-- Track
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -155, 0, 5)
	track.Position = UDim2.new(0, 90, 0.5, -2)
	track.BackgroundColor3 = Theme.Colors.ProgressTrack
	track.BorderSizePixel = 0
	track.Parent = container

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(1, 0)
	tCorner.Parent = track

	-- Fill
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.6, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Colors.Primary
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(1, 0)
	fCorner.Parent = fill

	-- Persen
	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(0, 40, 1, 0)
	pct.Position = UDim2.new(1, -45, 0, 0)
	pct.BackgroundTransparency = 1
	pct.Text = "60%"
	pct.TextColor3 = Theme.Colors.Text
	pct.Font = Theme.Fonts.Code
	pct.TextSize = Theme.TextSizes.Small
	pct.TextXAlignment = Enum.TextXAlignment.Center
	pct.Parent = container

	self.Instance = container
	self.MuteButton = muteBtn
	self.SliderTrack = track
	self.SliderFill = fill
	self.PercentText = pct
	self.CurrentVolume = 0.6
	self.IsMuted = false
	self.OnVolumeChanged = onVolumeChanged

	-- Drag logic
	local dragging = false
	local function updateFromInput(input)
		local posX = input.Position.X
		local absX = track.AbsolutePosition.X
		local absW = track.AbsoluteSize.X
		local p = math.clamp((posX - absX) / absW, 0, 1)
		self:SetVolume(p)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	muteBtn.MouseButton1Click:Connect(function()
		self.IsMuted = not self.IsMuted
		if self.IsMuted then
			muteBtn.Text = "🔇"
			fill.BackgroundColor3 = Theme.Colors.Danger
			if self.OnVolumeChanged then self.OnVolumeChanged(0) end
		else
			muteBtn.Text = "🔊"
			fill.BackgroundColor3 = Theme.Colors.Primary
			if self.OnVolumeChanged then self.OnVolumeChanged(self.CurrentVolume) end
		end
	end)

	return self
end

function VolumeSlider:SetVolume(val)
	self.CurrentVolume = math.clamp(val, 0, 1)
	self.SliderFill.Size = UDim2.new(self.CurrentVolume, 0, 1, 0)
	self.PercentText.Text = string.format("%d%%", math.floor(self.CurrentVolume * 100))
	if not self.IsMuted and self.OnVolumeChanged then
		self.OnVolumeChanged(self.CurrentVolume)
	end
end

function VolumeSlider:Destroy()
	if self.Instance then self.Instance:Destroy() end
end

return VolumeSlider
