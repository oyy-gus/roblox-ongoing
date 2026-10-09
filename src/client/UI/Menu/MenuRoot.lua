--[[
	MenuRoot.lua
	Tujuan: Frame menu utama — tema hitam-putih dengan gradient memutar berdasarkan beat.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local UIStrings = require(ReplicatedStorage.Shared.UIStrings)
local MenuNavigation = require(script.Parent.MenuNavigation)

local MenuRoot = {}
MenuRoot.__index = MenuRoot

function MenuRoot.new(onCloseRequested)
	local self = setmetatable({}, MenuRoot)
	self.BeatLevel = 0
	self.IsVisible = false

	-- ========== Frame Utama ==========
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MenuMainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.new(0.88, 0, 0.85, 0)
	mainFrame.BackgroundColor3 = Theme.Colors.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.ClipsDescendants = true

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Theme.Dimensions.MinMenuSize
	sizeConstraint.MaxSize = Theme.Dimensions.MaxMenuSize
	sizeConstraint.Parent = mainFrame

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusLarge)
	mainCorner.Parent = mainFrame

	-- Background gradient hitam-putih berputar
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Theme.Colors.BeatBlack),
		ColorSequenceKeypoint.new(0.4, Theme.Colors.BeatDark),
		ColorSequenceKeypoint.new(0.8, Theme.Colors.BeatMid),
		ColorSequenceKeypoint.new(1,   Theme.Colors.BeatBlack),
	})
	bgGrad.Rotation = 0
	bgGrad.Parent = mainFrame

	-- Outer border putih (beat-reactive)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = Theme.Colors.Primary
	outerStroke.Thickness = 1
	outerStroke.Transparency = 0.7
	outerStroke.Parent = mainFrame

	-- ========== Header ==========
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = Theme.Colors.Header
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, Theme.Dimensions.CornerRadiusLarge)
	hCorner.Parent = header

	local hFix = Instance.new("Frame")
	hFix.Size = UDim2.new(1, 0, 0, 12)
	hFix.Position = UDim2.new(0, 0, 1, -12)
	hFix.BackgroundColor3 = Theme.Colors.Header
	hFix.BorderSizePixel = 0
	hFix.Parent = header

	-- Divider bawah header
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -20, 0, 1)
	divider.Position = UDim2.new(0, 10, 0, 39)
	divider.BackgroundColor3 = Theme.Colors.Stroke
	divider.BorderSizePixel = 0
	divider.Parent = mainFrame

	local divGrad = Instance.new("UIGradient")
	divGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(0.5, Theme.Colors.StrokeHighlight),
		ColorSequenceKeypoint.new(1,   Color3.new(0,0,0)),
	})
	divGrad.Parent = divider

	-- ========== Judul ==========
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "HeaderTitle"
	titleLabel.Size = UDim2.new(1, -55, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎵 " .. UIStrings.Menu.Title
	titleLabel.TextColor3 = Theme.Colors.Text
	titleLabel.Font = Theme.Fonts.Title
	titleLabel.TextSize = Theme.TextSizes.Title
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	-- ========== Tombol ✕ ==========
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 26, 0, 26)
	closeBtn.Position = UDim2.new(1, -32, 0.5, -13)
	closeBtn.BackgroundColor3 = Theme.Colors.Surface
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Theme.Colors.TextMuted
	closeBtn.Font = Theme.Fonts.Header
	closeBtn.TextSize = 13
	closeBtn.AutoButtonColor = false

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 5)
	cCorner.Parent = closeBtn

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Theme.Colors.Stroke
	cStroke.Thickness = 1
	cStroke.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = Theme.Colors.Danger,
			TextColor3 = Color3.new(1,1,1),
		}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(Theme.Animation.Fast), {
			BackgroundColor3 = Theme.Colors.Surface,
			TextColor3 = Theme.Colors.TextMuted,
		}):Play()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		if onCloseRequested then onCloseRequested() end
	end)
	closeBtn.Parent = header

	-- ========== Navigation ==========
	local navigation = MenuNavigation.new()
	navigation.Instance.Position = UDim2.new(0, Theme.Dimensions.PanelPadding, 0, 45)
	navigation.Instance.Size = UDim2.new(1, -Theme.Dimensions.PanelPadding * 2, 0, 30)
	navigation.Instance.Parent = mainFrame

	-- ========== Content Area ==========
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -Theme.Dimensions.PanelPadding * 2, 1, -84)
	contentArea.Position = UDim2.new(0, Theme.Dimensions.PanelPadding, 0, 80)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	-- ========== Animasi Gradient Berputar ==========
	local gradAngle = 0
	local gradConnection = RunService.RenderStepped:Connect(function(dt)
		local beat = self.BeatLevel or 0
		-- Makin kencang saat beat tinggi (5–30 deg/detik)
		local speed = 5 + beat * 25
		gradAngle = (gradAngle + dt * speed) % 360
		bgGrad.Rotation = gradAngle

		-- Divider berputar berlawanan
		divGrad.Rotation = (360 - gradAngle * 0.5) % 360

		-- Warna gradient: hitam→abu→putih, makin terang saat beat
		local brightLevel = beat * 0.5
		local midColor = Color3.fromRGB(
			math.floor(70 + brightLevel * 185),
			math.floor(70 + brightLevel * 185),
			math.floor(70 + brightLevel * 185)
		)
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Theme.Colors.BeatBlack),
			ColorSequenceKeypoint.new(0.35, Theme.Colors.BeatDark),
			ColorSequenceKeypoint.new(0.65, midColor),
			ColorSequenceKeypoint.new(1,   Theme.Colors.BeatBlack),
		})

		-- Border putih makin terang saat beat
		outerStroke.Transparency = math.max(0.1, 0.7 - beat * 0.5)
	end)

	-- ========== Draggable ==========
	do
		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = mainFrame.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				mainFrame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	self.Instance = mainFrame
	self.Header = header
	self.TitleLabel = titleLabel
	self.CloseButton = closeBtn
	self.Navigation = navigation
	self.ContentArea = contentArea
	self.BgGrad = bgGrad
	self.GradConnection = gradConnection

	return self
end

function MenuRoot:SetBeatLevel(beat)
	self.BeatLevel = beat or 0
end

function MenuRoot:SetVisible(visible)
	self.IsVisible = visible
	if visible then
		self.Instance.Visible = true
		self.Instance.Size = UDim2.new(0.82, 0, 0.78, 0)
		TweenService:Create(self.Instance, TweenInfo.new(Theme.Animation.Normal, Theme.Animation.EasingStyle), {
			Size = UDim2.new(0.88, 0, 0.85, 0)
		}):Play()
	else
		TweenService:Create(self.Instance, TweenInfo.new(Theme.Animation.Fast, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0.82, 0, 0.78, 0)
		}):Play()
		task.delay(Theme.Animation.Fast + 0.05, function()
			if not self.IsVisible then
				self.Instance.Visible = false
			end
		end)
	end
end

function MenuRoot:Destroy()
	if self.GradConnection then
		self.GradConnection:Disconnect()
	end
	if self.Instance then
		self.Instance:Destroy()
	end
end

return MenuRoot
