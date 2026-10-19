local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOPBAR_CONFIG = { Alignment = "left", InitDelay = 2 }

local remotes                          = ReplicatedStorage:WaitForChild("SyncRemotes")
local updateFavoritedAnimationsEventRE = remotes:WaitForChild("updateFavoritedAnimationsEvent")
local animationStartRF                 = remotes:WaitForChild("animationStart")
local startSyncRE                      = remotes:WaitForChild("startSync")
local changeSpeedRE                    = remotes:WaitForChild("changeSpeed")
local syncNotificationRE               = remotes:WaitForChild("SyncNotification")

local emotesFolder       = ReplicatedStorage:WaitForChild("Emotes")
local DanceConfig        = require(emotesFolder:WaitForChild("DanceConfig"))
local PoseConfig         = require(emotesFolder:WaitForChild("PoseConfig"))

local animIdToName = {}
local function registerAnimId(name, animId)
	if not animId then return end
	animIdToName[tostring(animId)] = name
	local num = tostring(animId):match("%d+")
	if num then
		animIdToName[num] = name
		animIdToName["rbxassetid://" .. num] = name
	end
end

for _, item in ipairs(DanceConfig) do
	registerAnimId(item.name, item.animationId)
end
for _, item in ipairs(PoseConfig) do
	registerAnimId(item.name, item.animationId)
end

local SyncModule         = ReplicatedStorage:WaitForChild("ContextModule")
local Modules            = ReplicatedStorage:WaitForChild("Modules")
local AutoScaleSystem    = ReplicatedStorage:WaitForChild("AutoScaleSystem")

local AnimationPreloader = require(SyncModule:WaitForChild("AnimationPreloader"))
local AnimatorUtils      = require(SyncModule:WaitForChild("AnimatorUtils"))
local ThemeModule        = require(Modules:WaitForChild("ThemeModule"))
local NotifModule        = require(Modules:WaitForChild("NotifModule"))
local ScaleSystem        = require(AutoScaleSystem:WaitForChild("ScaleSystem"))
local UIStrings          = require(Modules:WaitForChild("UIStrings"))
local PanelAnimationController = require(Modules:WaitForChild("PanelAnimationController"))

AnimatorUtils.AnimationPreloader = AnimationPreloader

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local C = ThemeModule.Colors
local G = ThemeModule.Gradients

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
end

local function gradient(parent, colorSeq, rot)
	local g = Instance.new("UIGradient")
	g.Color    = colorSeq
	g.Rotation = rot or 0
	g.Parent   = parent
end

local FRAME_W  = 320
local FRAME_H  = 440
local PAD      = 10
local INNER_W  = FRAME_W - PAD * 2

local HDR_H    = 44
local SRCH_H   = 36
local TAB_H    = 40
local SPEED_H  = 44
local GAP      = 8

local CONT_TOP = HDR_H + GAP + SRCH_H + GAP + TAB_H + GAP
local CONT_BOT = GAP + SPEED_H + GAP
local CONT_H   = FRAME_H - CONT_TOP - CONT_BOT

local BTN_HEIGHT  = 52
local BTN_SPACING = 8

local ContextActionService = game:GetService("ContextActionService")

local gui = playerGui:WaitForChild("EmoteGui")
if gui:IsA("ScreenGui") then
	gui.IgnoreGuiInset = true
	gui.DisplayOrder   = 100
end

local scaler = ScaleSystem.new(gui)
print("[MenuAnimasi] Skala otomatis diterapkan - Skala saat ini:", scaler:GetCurrentScale())

local mainframe = Instance.new("Frame")
mainframe.Name             = "MainFrame"
mainframe.Size             = UDim2.new(0, FRAME_W, 0, FRAME_H)
mainframe.AnchorPoint      = Vector2.new(0, 0.5)
mainframe.Position         = UDim2.new(0, 15, 0.5, 0)
mainframe.BackgroundColor3 = C.BackgroundDark
mainframe.BorderSizePixel  = 0
mainframe.Visible          = false
mainframe.Active           = true
mainframe.ClipsDescendants = true
mainframe.Parent           = gui

corner(mainframe, 12)
gradient(mainframe, G.Background, 135)
ThemeModule.CreateAnimatedStroke(mainframe, 2, "Primary", 1.2)
local emoteAnim = PanelAnimationController.new(mainframe, { CollapsedHeight = HDR_H })

do
	local dragging, dragStart, startPos = false, nil, nil
	local function endDrag()
		if dragging then
			dragging = false
			ContextActionService:UnbindAction("EmoteDragCameraSink")
		end
	end

	mainframe.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch)
			and (input.Position.Y - mainframe.AbsolutePosition.Y) <= HDR_H * scaler:GetCurrentScale() then
			dragging = true
			dragStart = input.Position
			startPos = mainframe.Position
			ContextActionService:BindActionAtPriority(
				"EmoteDragCameraSink",
				function() return Enum.ContextActionResult.Sink end,
				false,
				Enum.ContextActionPriority.High.Value + 2000,
				Enum.UserInputType.MouseMovement,
				Enum.UserInputType.Touch
			)
		end
	end)
	mainframe.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) and dragging then
			endDrag()
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = input.Position - dragStart
		mainframe.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end)
end

local headerFrame = Instance.new("Frame")
headerFrame.Name             = "HeaderFrame"
headerFrame.Size             = UDim2.new(1, 0, 0, HDR_H)
headerFrame.BackgroundColor3 = C.BackgroundMedium
headerFrame.BorderSizePixel  = 0
headerFrame.Active           = true
headerFrame.ZIndex           = 2
headerFrame.Parent           = mainframe
corner(headerFrame, 12)

do
	local g = Instance.new("UIGradient")
	g.Color = G.Background
	g.Rotation = 90
	g.Parent   = headerFrame
end

local hdrLine = Instance.new("Frame")
hdrLine.Size             = UDim2.new(1, 0, 0, 1)
hdrLine.Position         = UDim2.new(0, 0, 1, -1)
hdrLine.BackgroundColor3 = C.Border
hdrLine.BackgroundTransparency = 0
hdrLine.BorderSizePixel  = 0
hdrLine.Parent           = headerFrame

local headerLabel = Instance.new("TextLabel")
headerLabel.Name             = "Header"
headerLabel.Size             = UDim2.new(1, -60, 1, 0)
headerLabel.Position         = UDim2.new(0, 20, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text             = UIStrings.Emote.Title
headerLabel.TextColor3       = C.Primary1
headerLabel.TextSize         = UIStrings.TextSize.Title
headerLabel.Font             = Enum.Font.GothamBold
headerLabel.TextXAlignment   = Enum.TextXAlignment.Center
headerLabel.TextYAlignment   = Enum.TextYAlignment.Center
headerLabel.Parent           = headerFrame
ThemeModule.CreatePrimaryGradient(headerLabel, 0, 1.2)

local closeBtn = Instance.new("TextButton")
closeBtn.Name                   = "CloseBtn"
closeBtn.Size                   = UDim2.new(0, 28, 0, 28)
closeBtn.AnchorPoint            = Vector2.new(1, 0.5)
closeBtn.Position               = UDim2.new(1, -6, 0.5, 0)
closeBtn.BackgroundColor3       = C.CloseRed
closeBtn.BackgroundTransparency = 0
closeBtn.Text                   = "x"
closeBtn.TextColor3             = C.TextWhite or Color3.fromHex("#FFFFFF")
closeBtn.TextSize               = 15
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.TextXAlignment         = Enum.TextXAlignment.Center
closeBtn.TextYAlignment         = Enum.TextYAlignment.Center
closeBtn.BorderSizePixel        = 0
closeBtn.AutoButtonColor        = false
closeBtn.ZIndex                 = 5
closeBtn.Parent                 = headerFrame
corner(closeBtn, 6)

local closePad = Instance.new("UIPadding")
closePad.PaddingBottom = UDim.new(0, 2)
closePad.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.12), {
		BackgroundColor3 = C.CloseRedHover,
	}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.12), {
		BackgroundColor3 = C.CloseRed,
	}):Play()
end)

local searchWrapper = Instance.new("Frame")
searchWrapper.Name             = "SearchWrapper"
searchWrapper.Size             = UDim2.new(1, -(PAD*2), 0, SRCH_H)
searchWrapper.Position         = UDim2.new(0, PAD, 0, HDR_H + GAP)
searchWrapper.BackgroundColor3 = C.BackgroundLight
searchWrapper.BorderSizePixel  = 0
searchWrapper.Active           = true
searchWrapper.ClipsDescendants = false
searchWrapper.Parent           = mainframe
corner(searchWrapper, 8)
ThemeModule.CreateStaticStroke(searchWrapper, 1, C.BackgroundLighter, 0)

local updateDisplay = nil
local currentSort   = "AZ"

local searchBox = Instance.new("TextBox")
searchBox.Name              = "SearchBox"
searchBox.Size              = UDim2.new(1, -80, 1, 0)
searchBox.Position          = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextColor3        = C.TextWhite
searchBox.PlaceholderText   = UIStrings.Emote.SearchPlaceholder
searchBox.PlaceholderColor3 = C.TextMuted
searchBox.Text              = ""
searchBox.TextSize          = UIStrings.TextSize.Caption
searchBox.Font              = Enum.Font.Gotham
searchBox.BorderSizePixel   = 0
searchBox.ClearTextOnFocus  = false
searchBox.ZIndex            = 3
searchBox.Parent            = searchWrapper

do
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 10)
	p.Parent = searchBox
end

local sortBtn = Instance.new("TextButton")
sortBtn.Name                   = "SortBtn"
sortBtn.Size                   = UDim2.new(0, 52, 0, 28)
sortBtn.AnchorPoint            = Vector2.new(1, 0.5)
sortBtn.Position               = UDim2.new(1, -6, 0.5, 0)
sortBtn.BackgroundColor3       = C.BackgroundMedium
sortBtn.BorderSizePixel        = 0
sortBtn.Text                   = "A-Z "
sortBtn.TextColor3             = C.TextMuted
sortBtn.TextSize               = UIStrings.TextSize.Caption
sortBtn.Font                   = Enum.Font.GothamBold
sortBtn.ZIndex                 = 5
sortBtn.Parent                 = searchWrapper
corner(sortBtn, 6)

sortBtn.MouseEnter:Connect(function()
	TweenService:Create(sortBtn, TweenInfo.new(0.1), {
		TextColor3 = C.TextWhite,
		BackgroundColor3 = C.BackgroundLighter
	}):Play()
end)
sortBtn.MouseLeave:Connect(function()
	TweenService:Create(sortBtn, TweenInfo.new(0.1), {
		TextColor3 = C.TextMuted,
		BackgroundColor3 = C.BackgroundMedium
	}):Play()
end)

sortBtn.MouseButton1Click:Connect(function()
	if currentSort == "AZ" then
		currentSort = "ZA"
		sortBtn.Text = "Z-A "
	else
		currentSort = "AZ"
		sortBtn.Text = "A-Z "
	end
	if updateDisplay then
		updateDisplay()
	end
end)

local resetBtn = Instance.new("ImageButton")
resetBtn.Name                   = "ResetBtn"
resetBtn.Size                   = UDim2.new(0, 18, 0, 18)
resetBtn.AnchorPoint            = Vector2.new(1, 0.5)
resetBtn.Position               = UDim2.new(1, -6, 0.5, 0)
resetBtn.BackgroundTransparency = 1
resetBtn.Image                  = "rbxassetid://111713825944259"
resetBtn.ImageColor3            = C.TextMuted
resetBtn.ImageTransparency      = 0
resetBtn.BorderSizePixel        = 0
resetBtn.ZIndex                 = 5
resetBtn.Visible                = false
resetBtn.Parent                 = searchWrapper

resetBtn.MouseEnter:Connect(function()
	TweenService:Create(resetBtn, TweenInfo.new(0.1), {
		ImageColor3 = C.TextWhite
	}):Play()
end)
resetBtn.MouseLeave:Connect(function()
	TweenService:Create(resetBtn, TweenInfo.new(0.1), {
		ImageColor3 = C.TextMuted
	}):Play()
end)

resetBtn.MouseButton1Click:Connect(function()
	searchBox.Text = ""
end)

local tabBar = Instance.new("Frame")
tabBar.Name             = "TabBar"
tabBar.Size             = UDim2.new(1, -(PAD*2), 0, TAB_H)
tabBar.Position         = UDim2.new(0, PAD, 0, HDR_H + GAP + SRCH_H + GAP)
tabBar.BackgroundColor3 = C.BackgroundMedium
tabBar.BorderSizePixel  = 0
tabBar.Active           = true
tabBar.Parent           = mainframe
corner(tabBar, 8)

do
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tl.VerticalAlignment = Enum.VerticalAlignment.Center
	tl.Padding = UDim.new(0, 4)
	tl.Parent = tabBar

	local tp = Instance.new("UIPadding")
	tp.PaddingLeft   = UDim.new(0, 4)
	tp.PaddingRight  = UDim.new(0, 4)
	tp.PaddingTop    = UDim.new(0, 4)
	tp.PaddingBottom = UDim.new(0, 4)
	tp.Parent = tabBar
end

local TAB_W = math.floor((INNER_W - 8 - 12) / 3)

local function makeTabBtn(name, text, order)
	local btn = Instance.new("TextButton")
	btn.Name             = name
	btn.Size             = UDim2.new(0, TAB_W, 1, 0)
	btn.BackgroundColor3 = C.BackgroundMedium
	btn.TextColor3       = C.TextGray
	btn.Text             = text
	btn.TextSize         = UIStrings.TextSize.Caption
	btn.Font             = Enum.Font.GothamBold
	btn.BorderSizePixel  = 0
	btn.LayoutOrder      = order
	btn.Parent           = tabBar
	corner(btn, 6)
	return btn
end

local danceBtn    = makeTabBtn("Dance",    UIStrings.Emote.TabDance, 1)
local poseBtn     = makeTabBtn("Pose",     UIStrings.Emote.TabPose,  2)
local favoriteBtn = makeTabBtn("Favorite", UIStrings.Emote.TabFavorite,   3)

local function attachTabGradient(btn)
	local g = Instance.new("UIGradient")
	g.Color = G.Primary
	g.Rotation = 45
	g.Enabled = false
	g.Parent = btn
	return g
end

local danceGrad    = attachTabGradient(danceBtn)
local poseGrad     = attachTabGradient(poseBtn)
local favoriteGrad = attachTabGradient(favoriteBtn)
ThemeModule.GradientSystem.Register(danceGrad, 1)
ThemeModule.GradientSystem.Register(poseGrad, 1)
ThemeModule.GradientSystem.Register(favoriteGrad, 1)

local containerframe = Instance.new("Frame")
containerframe.Name             = "Container"
containerframe.Size             = UDim2.new(1, -(PAD*2), 0, CONT_H)
containerframe.Position         = UDim2.new(0, PAD, 0, CONT_TOP)
containerframe.BackgroundColor3 = C.BackgroundMedium
containerframe.BorderSizePixel  = 0
containerframe.Active           = true
containerframe.ClipsDescendants = true
containerframe.Parent           = mainframe
corner(containerframe, 8)

local containerlist = Instance.new("ScrollingFrame")
containerlist.Name                   = "ContainerList"
containerlist.Size                   = UDim2.new(1, 0, 1, 0)
containerlist.BackgroundTransparency = 1
containerlist.BorderSizePixel        = 0
containerlist.ScrollBarThickness     = 0
containerlist.ScrollBarImageTransparency = 1
containerlist.ScrollingEnabled       = true
containerlist.VerticalScrollBarInset = Enum.ScrollBarInset.None
containerlist.CanvasSize             = UDim2.new(0, 0, 0, 0)
containerlist.AutomaticCanvasSize    = Enum.AutomaticSize.Y
containerlist.ScrollingDirection     = Enum.ScrollingDirection.Y
containerlist.Parent                 = containerframe

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
listLayout.Padding             = UDim.new(0, BTN_SPACING)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent              = containerlist

local listPad = Instance.new("UIPadding")
listPad.PaddingLeft   = UDim.new(0, 6)
listPad.PaddingRight  = UDim.new(0, 6)
listPad.PaddingTop    = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)
listPad.Parent        = containerlist

local templateframe = Instance.new("Frame")
templateframe.Name             = "Template"
templateframe.Size             = UDim2.new(1, 0, 0, BTN_HEIGHT)
templateframe.BackgroundColor3 = C.BackgroundLight
templateframe.BorderSizePixel  = 0
templateframe.Visible          = false
templateframe.Parent           = containerlist
corner(templateframe, 8)

local templateBtnInner = Instance.new("TextButton")
templateBtnInner.Name                   = "TemplateBtn"
templateBtnInner.Size                   = UDim2.new(1, -48, 1, 0)
templateBtnInner.BackgroundTransparency = 1
templateBtnInner.Text                   = "Emote Name"
templateBtnInner.TextColor3             = C.TextWhite
templateBtnInner.TextSize               = UIStrings.TextSize.Body
templateBtnInner.Font                   = Enum.Font.GothamMedium
templateBtnInner.TextXAlignment         = Enum.TextXAlignment.Left
templateBtnInner.TextTruncate           = Enum.TextTruncate.AtEnd
templateBtnInner.Parent                 = templateframe
do
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 16)
	p.Parent = templateBtnInner
end

local templateFavBtn = Instance.new("TextButton")
templateFavBtn.Name                   = "FavoriteBtn"
templateFavBtn.Size                   = UDim2.new(0, 44, 1, 0)
templateFavBtn.AnchorPoint            = Vector2.new(1, 0)
templateFavBtn.Position               = UDim2.new(1, -4, 0, 0)
templateFavBtn.BackgroundTransparency = 1
templateFavBtn.Text                   = "★"
templateFavBtn.TextColor3             = C.TextDark
templateFavBtn.TextSize               = UIStrings.TextSize.Title
templateFavBtn.Font                   = Enum.Font.GothamBold
templateFavBtn.Parent                 = templateframe

local SPEED_Y = FRAME_H - GAP - SPEED_H

local speedFrame = Instance.new("Frame")
speedFrame.Name             = "SpeedFrame"
speedFrame.Size             = UDim2.new(1, -(PAD*2), 0, SPEED_H)
speedFrame.Position         = UDim2.new(0, PAD, 0, SPEED_Y)
speedFrame.BackgroundColor3 = C.BackgroundMedium
speedFrame.BorderSizePixel  = 0
speedFrame.Active           = true
speedFrame.Parent           = mainframe
corner(speedFrame, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 50, 1, 0)
speedLabel.Position = UDim2.new(0, 8, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = C.TextGray
speedLabel.TextSize = UIStrings.TextSize.Caption
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local speedtext = Instance.new("TextLabel")
speedtext.Name = "TextLabel"
speedtext.Size = UDim2.new(0, 46, 1, 0)
speedtext.AnchorPoint = Vector2.new(1, 0)
speedtext.Position = UDim2.new(1, -6, 0, 0)
speedtext.BackgroundTransparency = 1
speedtext.Text = "1.0x"
speedtext.TextColor3 = C.Primary1
speedtext.TextSize = UIStrings.TextSize.Caption
speedtext.Font = Enum.Font.GothamBold
speedtext.Parent = speedFrame
ThemeModule.CreatePrimaryGradient(speedtext, 0, 1.2)

local speedBar = Instance.new("Frame")
speedBar.Name = "speedBar"
speedBar.Size = UDim2.new(1, -112, 0, 6)
speedBar.Position = UDim2.new(0, 58, 0.5, -3)
speedBar.BackgroundColor3 = C.BackgroundLight
speedBar.BorderSizePixel = 0
speedBar.Parent = speedFrame
corner(speedBar, 3)

local speedFill = Instance.new("Frame")
speedFill.Name = "speedFill"
speedFill.Size = UDim2.new(0.2, 0, 1, 0)
speedFill.BackgroundColor3 = C.Primary1
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar
corner(speedFill, 3)
ThemeModule.CreatePrimaryGradient(speedFill, 0, 1.2)

local speedSlider = Instance.new("Frame")
speedSlider.Name = "speedPosition"
speedSlider.Size = UDim2.new(0, 18, 0, 18)
speedSlider.AnchorPoint = Vector2.new(0.5, 0.5)
speedSlider.BackgroundColor3 = C.Primary1
speedSlider.BorderSizePixel = 0
speedSlider.Parent = speedBar
corner(speedSlider, 99)
ThemeModule.CreatePrimaryGradient(speedSlider, 135, 1.2)
ThemeModule.CreateStaticStroke(speedSlider, 1, Color3.fromRGB(255, 255, 200), 0.5)

local speedButton = Instance.new("TextButton")
speedButton.Name = "Button"
speedButton.Size = UDim2.new(1, 0, 1, 0)
speedButton.BackgroundTransparency = 1
speedButton.Text = ""
speedButton.Parent = speedSlider

local unsyncframe = Instance.new("Frame")
unsyncframe.Name             = "UnsyncFrame"
unsyncframe.Size             = containerframe.Size
unsyncframe.Position         = containerframe.Position
unsyncframe.BackgroundColor3 = C.BackgroundMedium
unsyncframe.BackgroundTransparency = 0.3
unsyncframe.BorderSizePixel  = 0
unsyncframe.Active           = true
unsyncframe.Visible          = false
unsyncframe.ZIndex           = 5
unsyncframe.Parent           = mainframe
corner(unsyncframe, 8)
ThemeModule.CreateAnimatedStroke(unsyncframe, 1, "Primary", 0.8)

local unsyncBtn = Instance.new("TextButton")
unsyncBtn.Name                   = "UnsyncBtn"
unsyncBtn.Size                   = UDim2.new(1, 0, 1, 0)
unsyncBtn.Position               = UDim2.new(0, 0, 0, 0)
unsyncBtn.AnchorPoint            = Vector2.new(0, 0)
unsyncBtn.BackgroundTransparency = 1
unsyncBtn.Text                   = "Tersinkronisasi\nKetuk untuk Lepas"
unsyncBtn.TextColor3             = C.Warning
unsyncBtn.TextSize               = UIStrings.TextSize.Caption
unsyncBtn.Font                   = Enum.Font.GothamBold
unsyncBtn.TextWrapped            = true
unsyncBtn.Parent                 = unsyncframe

local dancelabel = Instance.new("TextLabel")
dancelabel.Name                  = "DanceLabel"
dancelabel.Size                  = UDim2.new(1, -10, 0, 20)
dancelabel.Position              = UDim2.new(0, 5, 1, -24)
dancelabel.BackgroundTransparency = 1
dancelabel.Text                  = "..."
dancelabel.TextColor3            = C.TextMuted
dancelabel.TextSize              = UIStrings.TextSize.Caption
dancelabel.Font                  = Enum.Font.Gotham
dancelabel.TextXAlignment        = Enum.TextXAlignment.Left
dancelabel.TextTruncate          = Enum.TextTruncate.AtEnd
dancelabel.ZIndex                = 6
dancelabel.Parent                = unsyncframe

local preloadLabel = Instance.new("TextLabel")
preloadLabel.Name = "PreloadStatus"
preloadLabel.Size = UDim2.new(1, 0, 1, 0)
preloadLabel.BackgroundColor3 = C.BackgroundDark
preloadLabel.BackgroundTransparency = 0.05
preloadLabel.TextColor3 = C.TextWhite
preloadLabel.Text = "Memuat data animasi..."
preloadLabel.TextSize = UIStrings.TextSize.Caption
preloadLabel.Font = Enum.Font.GothamBold
preloadLabel.Visible = false
preloadLabel.ZIndex = 10
preloadLabel.Parent = mainframe
corner(preloadLabel, 12)

local clickSound = nil
pcall(function() clickSound = SoundService:WaitForChild("Sound", 3) end)
local function playTopBarClick()
	if clickSound then
		pcall(function()
			clickSound.TimePosition = 0
			clickSound:Play()
		end)
	end
end

local emoteIcon, isTopBarInitialized = nil, false
local topbarConnections = {}

local function addTopBarConnection(name, conn)
	topbarConnections[name] = topbarConnections[name] or {}
	table.insert(topbarConnections[name], conn)
end

local function cleanupTopBarConnections(name)
	if not topbarConnections[name] then return end
	for _, c in ipairs(topbarConnections[name]) do
		if c and c.Connected then c:Disconnect() end
	end
	topbarConnections[name] = nil
end

emoteIcon = Icon.new()
emoteIcon:setImage(15290394895)
emoteIcon:setOrder(1)

if TOPBAR_CONFIG.Alignment == "left" then
	emoteIcon:setLeft()
elseif TOPBAR_CONFIG.Alignment == "mid" then
	emoteIcon:setMid()
else
	emoteIcon:setRight()
end

local iconData = { icon = emoteIcon, isOpen = false, lockSync = false }

addTopBarConnection("Emote", emoteIcon:bindEvent("selected", function()
	playTopBarClick()
	if not iconData.lockSync then
		iconData.isOpen = true
		emoteAnim:Open(FRAME_H)
	end
end))

addTopBarConnection("Emote", emoteIcon:bindEvent("deselected", function()
	playTopBarClick()
	if not iconData.lockSync then
		iconData.isOpen = false
		emoteAnim:Close()
	end
end))

addTopBarConnection("Emote_sync", mainframe:GetPropertyChangedSignal("Visible"):Connect(function()
	if not isTopBarInitialized or iconData.lockSync then return end

	if mainframe.Visible and not iconData.isOpen then
		iconData.lockSync = true
		iconData.icon:select()
		iconData.isOpen = true
		iconData.lockSync = false
	elseif not mainframe.Visible and iconData.isOpen then
		iconData.lockSync = true
		iconData.icon:deselect()
		iconData.isOpen = false
		iconData.lockSync = false
	end
end))

closeBtn.MouseButton1Click:Connect(function()
	emoteAnim:Close()
	iconData.icon:deselect()
end)

ThemeModule.GradientSystem.Start()
task.wait(TOPBAR_CONFIG.InitDelay)
isTopBarInitialized = false
mainframe.Visible = false
iconData.isOpen = false
iconData.icon:deselect()
task.wait(0.5)
isTopBarInitialized = true
print("[BilahAtas] Berhasil diinisialisasi")

syncNotificationRE.OnClientEvent:Connect(function(notifType, leaderName)
	if notifType == "sync_success" then
		local lp = Players:FindFirstChild(leaderName)
		NotifModule.Success("Synced!", "Dance synced to " .. (lp and lp.DisplayName or leaderName), 2.5)

	elseif notifType == "unsync_success" then
		NotifModule.Info("Unsynced", "You are now unsynced", 2)

	elseif notifType == "leader_blocked" then
		NotifModule.Warning("You're a Leader!", "Cannot sync to followers", 3)

	elseif notifType == "circular_blocked" then
		NotifModule.Error("Sync Error", "Cannot create circular sync", 2.5)
	end
end)

local allButtons          = {}
local buttonsByName       = {}
local favoritedAnimations = {}
local currentCategory     = "Dance"
local searchQuery         = ""
local currentSpeed        = 1
local isSyncing           = false
local currentLeaderName   = nil

local currentPlayingTrack = nil
local currentPlayingName  = nil

local syncUpdateConnection = nil
local leaderAnimationConnection = nil
local leaderStoppedConnection = nil
local leaderCharConnection = nil
local currentDanceConnection = nil
local currentlySelectedButton = nil
local syncedFollowerDances = {}

do
	local sd = player:GetAttribute("SavedFavoritedAnimations")
	if sd and typeof(sd) == "string" then
		local ok, dec = pcall(HttpService.JSONDecode, HttpService, sd)
		if ok and typeof(dec) == "table" then
			favoritedAnimations = dec
			updateFavoritedAnimationsEventRE:FireServer(HttpService:JSONEncode(favoritedAnimations))
		end
	end
end

local function saveFavoritedAnimations()
	updateFavoritedAnimationsEventRE:FireServer(HttpService:JSONEncode(favoritedAnimations))
end

local function setButtonActive(buttonData, isActive)
	if not buttonData or not buttonData.button then return end

	local nb = buttonData.button
	local btnGrad = nb:FindFirstChildOfClass("UIGradient")
	local tBtn = nb:FindFirstChild("TemplateBtn")

	if buttonData.activeTween then
		buttonData.activeTween:Cancel()
		buttonData.activeTween = nil
	end

	if isActive then
		nb.BackgroundColor3 = C.Primary1
		if btnGrad then btnGrad.Enabled = true end
		if tBtn then tBtn.TextColor3 = C.BackgroundDark end
	else
		nb.BackgroundColor3 = C.BackgroundLight
		if btnGrad then btnGrad.Enabled = false end
		if tBtn then tBtn.TextColor3 = C.TextWhite end
	end
end

local function selectButtonInstantly(animationName)
	if currentlySelectedButton then
		setButtonActive(currentlySelectedButton, false)
	end

	local newButtonData = buttonsByName[animationName]
	if newButtonData then
		setButtonActive(newButtonData, true)
		currentlySelectedButton = newButtonData
	else
		currentlySelectedButton = nil
	end
end

local function updateButtonVisuals(currentDanceName)
	for _, data in ipairs(allButtons) do
		local btnGrad = data.button:FindFirstChildOfClass("UIGradient")
		local tBtn = data.button:FindFirstChild("TemplateBtn")

		if data.activeTween then
			data.activeTween:Cancel()
			data.activeTween = nil
		end

		if currentDanceName and data.name == currentDanceName then
			data.button.BackgroundColor3 = C.Primary1
			if btnGrad then btnGrad.Enabled = true end
			if tBtn then tBtn.TextColor3 = C.BackgroundDark end
			currentlySelectedButton = data
		else
			data.button.BackgroundColor3 = C.BackgroundLight
			if btnGrad then btnGrad.Enabled = false end
			if tBtn then tBtn.TextColor3 = C.TextWhite end
		end
	end
end

local function stopLocalDance(notifyServer)
	if currentPlayingTrack then
		pcall(function() currentPlayingTrack:Stop(0.15) end)
		currentPlayingTrack = nil
	end
	currentPlayingName = nil
	selectButtonInstantly(nil)
	if player.Character then
		player.Character:SetAttribute("CurrentDance", nil)
		player.Character:SetAttribute("DanceStartTime", nil)
	end
	table.clear(syncedFollowerDances)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:GetAttribute("Syncing") == player.Name then
			local oHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
			local oAnim = oHum and oHum:FindFirstChildOfClass("Animator")
			if oAnim then
				local ok, oTracks = pcall(function() return oAnim:GetPlayingAnimationTracks() end)
				if ok and oTracks then
					for _, t in ipairs(oTracks) do
						pcall(function() t:Stop(0.15) end)
					end
				end
			end
		end
	end
	if notifyServer then
		task.spawn(function()
			pcall(function()
				animationStartRF:InvokeServer(nil, false, currentSpeed)
			end)
		end)
	end
end

local function setupCurrentDanceListener()
	if currentDanceConnection and currentDanceConnection.Connected then
		currentDanceConnection:Disconnect()
	end

	if not player.Character then return end

	local currentDance = player.Character:GetAttribute("CurrentDance")
	updateButtonVisuals(currentDance)

	currentDanceConnection = player.Character:GetAttributeChangedSignal("CurrentDance"):Connect(function()
		local newDance = player.Character:GetAttribute("CurrentDance")
		updateButtonVisuals(newDance)
	end)
end

local function getLeaderTrackAndName(lp)
	if not lp or not lp.Character then return nil, nil end
	local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil, nil end
	local anim = humanoid:FindFirstChildOfClass("Animator")
	if not anim then return nil, nil end

	local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end)
	if not ok or not tracks then return nil, nil end

	for _, track in ipairs(tracks) do
		if track.IsPlaying and track.Animation then
			local id = track.Animation.AnimationId
			local name = animIdToName[id]
			if not name then
				local num = tostring(id):match("%d+")
				if num then name = animIdToName[num] end
			end
			if not name then
				for _, a in ipairs(emotesFolder:GetChildren()) do
					if a:IsA("Animation") and a.AnimationId == id then
						name = a.Name
						break
					end
				end
			end
			if not name then
				local pf = emotesFolder:FindFirstChild("Pose")
				if pf then
					for _, a in ipairs(pf:GetChildren()) do
						if a:IsA("Animation") and a.AnimationId == id then
							name = a.Name
							break
						end
					end
				end
			end
			if name then
				return track, name
			end
		end
	end

	local leaderDanceAttr = lp.Character:GetAttribute("CurrentDance")
	if leaderDanceAttr and leaderDanceAttr ~= "" then
		local animObj = emotesFolder:FindFirstChild(leaderDanceAttr)
		if not animObj then
			local pf = emotesFolder:FindFirstChild("Pose")
			if pf then animObj = pf:FindFirstChild(leaderDanceAttr) end
		end
		if animObj then
			local loadedTrack = AnimatorUtils.getOrCreateTrack(anim, animObj)
			return loadedTrack, leaderDanceAttr
		end
	end

	return nil, nil
end

local function getLeaderCurrentAnimation()
	if not isSyncing or not currentLeaderName then return nil end
	local lp = Players:FindFirstChild(currentLeaderName)
	local _, name = getLeaderTrackAndName(lp)
	return name
end

local function syncFollowerToLeaderTrack(leaderTrack, animName)
	if not leaderTrack or not leaderTrack.Animation then return end
	local myAnimator = AnimatorUtils.getAnimator(player)
	if not myAnimator then return end

	local animObj = leaderTrack.Animation
	local lp = Players:FindFirstChild(currentLeaderName or "")
	local leaderStartTime = lp and lp.Character and lp.Character:GetAttribute("DanceStartTime")
	local targetSpeed = (lp and lp.Character and lp.Character:GetAttribute("DanceSpeed")) or leaderTrack.Speed or 1

	local function calculateTargetTime(track)
		if leaderStartTime and track and track.Length and track.Length > 0 then
			local elapsed = (workspace:GetServerTimeNow() - leaderStartTime) * targetSpeed
			if elapsed >= 0 then
				return elapsed % track.Length
			end
		end
		return leaderTrack.TimePosition
	end

	if currentPlayingTrack and currentPlayingTrack.Animation and (currentPlayingTrack.Animation.AnimationId == animObj.AnimationId or currentPlayingName == animName) and currentPlayingTrack.IsPlaying then
		if currentPlayingTrack.Length and currentPlayingTrack.Length > 0 then
			local idealTime = calculateTargetTime(currentPlayingTrack)
			local diff = currentPlayingTrack.TimePosition - idealTime
			if diff > currentPlayingTrack.Length / 2 then diff = diff - currentPlayingTrack.Length end
			if diff < -currentPlayingTrack.Length / 2 then diff = diff + currentPlayingTrack.Length end

			local absDiff = math.abs(diff)
			if absDiff > 0.45 then
				currentPlayingTrack.TimePosition = idealTime
			elseif absDiff > 0.06 then
				local nudge = (diff < 0) and 1.06 or 0.94
				currentPlayingTrack:AdjustSpeed(targetSpeed * nudge)
			else
				currentPlayingTrack:AdjustSpeed(targetSpeed)
			end
		end
		return
	end

	if currentPlayingTrack and currentPlayingTrack.IsPlaying then
		currentPlayingTrack:Stop(0.15)
		currentPlayingTrack = nil
	end

	local myTrack = AnimatorUtils.getOrCreateTrack(myAnimator, animObj)
	if not myTrack then
		myTrack = myAnimator:LoadAnimation(animObj)
	end
	if not myTrack then return end

	myTrack.Priority = Enum.AnimationPriority.Action4
	myTrack.Looped = true
	myTrack:Play(0.15, 1.0, targetSpeed)
	myTrack:AdjustSpeed(targetSpeed)
	myTrack.TimePosition = calculateTargetTime(myTrack)

	currentPlayingTrack = myTrack
	currentPlayingName = animName
	selectButtonInstantly(animName)
	if player.Character then
		player.Character:SetAttribute("CurrentDance", animName)
		player.Character:SetAttribute("DanceStartTime", leaderStartTime or workspace:GetServerTimeNow())
		player.Character:SetAttribute("DanceSpeed", targetSpeed)
	end
end

local function updateUnsyncFrame()
	if not player.Character then
		unsyncframe.Visible = false
		return
	end

	local syncTarget = player.Character:GetAttribute("Syncing")

	if syncTarget and syncTarget ~= "" then
		isSyncing = true
		currentLeaderName = syncTarget

		local lp = Players:FindFirstChild(syncTarget)
		local dn = lp and lp.DisplayName or syncTarget

		unsyncBtn.Text = "Synced to " .. dn .. "\nTap to Unsync"

		local an = getLeaderCurrentAnimation()
		dancelabel.Text = an and ("♪ " .. an) or ("♪ Waiting for " .. dn)

		unsyncframe.Visible = true
	else
		unsyncframe.Visible = false
		isSyncing = false
		currentLeaderName = nil
	end
end

unsyncBtn.MouseButton1Click:Connect(function()
	if not isSyncing or not currentLeaderName then return end

	local lp = Players:FindFirstChild(currentLeaderName)
	stopLocalDance(false)

	if player.Character then
		player.Character:SetAttribute("Syncing", nil)
	end

	if lp then
		startSyncRE:FireServer(lp, false)
	end

	local snd = ReplicatedStorage:FindFirstChild("Sounds")
	if snd then
		local s = snd:FindFirstChild("minimal-pop-click-ui")
		if s then s:Play() end
	end

	updateUnsyncFrame()
end)

local function setupSyncMonitoring()
	if syncUpdateConnection and syncUpdateConnection.Connected then
		syncUpdateConnection:Disconnect()
		syncUpdateConnection = nil
	end
	if leaderAnimationConnection and leaderAnimationConnection.Connected then
		leaderAnimationConnection:Disconnect()
		leaderAnimationConnection = nil
	end
	if leaderStoppedConnection and leaderStoppedConnection.Connected then
		leaderStoppedConnection:Disconnect()
		leaderStoppedConnection = nil
	end
	if leaderCharConnection and leaderCharConnection.Connected then
		leaderCharConnection:Disconnect()
		leaderCharConnection = nil
	end

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	updateUnsyncFrame()
	setupCurrentDanceListener()

	local function bindLeader(leaderPlayer)
		if leaderAnimationConnection and leaderAnimationConnection.Connected then
			leaderAnimationConnection:Disconnect()
			leaderAnimationConnection = nil
		end
		if leaderStoppedConnection and leaderStoppedConnection.Connected then
			leaderStoppedConnection:Disconnect()
			leaderStoppedConnection = nil
		end
		if leaderCharConnection and leaderCharConnection.Connected then
			leaderCharConnection:Disconnect()
			leaderCharConnection = nil
		end

		if not leaderPlayer then
			stopLocalDance(false)
			return
		end

		leaderCharConnection = leaderPlayer.CharacterAdded:Connect(function()
			task.wait(0.5)
			if isSyncing and currentLeaderName == leaderPlayer.Name then
				bindLeader(leaderPlayer)
			end
		end)

		local dn = leaderPlayer.DisplayName or leaderPlayer.Name

		if not leaderPlayer.Character then
			stopLocalDance(false)
			dancelabel.Text = "♪ Waiting for " .. dn
			return
		end
		local h = leaderPlayer.Character:FindFirstChildOfClass("Humanoid")
		local a = h and h:FindFirstChildOfClass("Animator")
		if not a then
			stopLocalDance(false)
			dancelabel.Text = "♪ Waiting for " .. dn
			return
		end

		local lTrack, lName = getLeaderTrackAndName(leaderPlayer)
		if lTrack and lName then
			dancelabel.Text = "♪ " .. lName
			syncFollowerToLeaderTrack(lTrack, lName)
		else
			stopLocalDance(false)
			dancelabel.Text = "♪ Waiting for " .. dn
		end

		leaderAnimationConnection = a.AnimationPlayed:Connect(function(track)
			if not (isSyncing and currentLeaderName == leaderPlayer.Name and track and track.Animation) then return end
			task.wait(0.02)
			local freshTrack, freshName = getLeaderTrackAndName(leaderPlayer)
			if freshTrack and freshName then
				dancelabel.Text = "♪ " .. freshName
				syncFollowerToLeaderTrack(freshTrack, freshName)
			end
		end)

		leaderStoppedConnection = leaderPlayer.Character:GetAttributeChangedSignal("CurrentDance"):Connect(function()
			if not (isSyncing and currentLeaderName == leaderPlayer.Name) then return end
			local newDance = leaderPlayer.Character and leaderPlayer.Character:GetAttribute("CurrentDance")
			local freshDn = leaderPlayer.DisplayName or leaderPlayer.Name
			if not newDance or newDance == "" then
				stopLocalDance(false)
				dancelabel.Text = "♪ Waiting for " .. freshDn
			else
				task.wait(0.02)
				local freshTrack, freshName = getLeaderTrackAndName(leaderPlayer)
				if freshTrack and freshName then
					dancelabel.Text = "♪ " .. freshName
					syncFollowerToLeaderTrack(freshTrack, freshName)
				else
					dancelabel.Text = "♪ " .. newDance
				end
			end
		end)
	end

	syncUpdateConnection = player.Character:GetAttributeChangedSignal("Syncing"):Connect(function()
		updateUnsyncFrame()

		if isSyncing and currentLeaderName then
			local lp = Players:FindFirstChild(currentLeaderName)
			if lp then
				bindLeader(lp)
			end
		else
			if leaderAnimationConnection and leaderAnimationConnection.Connected then
				leaderAnimationConnection:Disconnect()
				leaderAnimationConnection = nil
			end
			if leaderStoppedConnection and leaderStoppedConnection.Connected then
				leaderStoppedConnection:Disconnect()
				leaderStoppedConnection = nil
			end
			if leaderCharConnection and leaderCharConnection.Connected then
				leaderCharConnection:Disconnect()
				leaderCharConnection = nil
			end
			stopLocalDance(false)
		end
	end)

	if isSyncing and currentLeaderName then
		local lp = Players:FindFirstChild(currentLeaderName)
		if lp then
			bindLeader(lp)
		end
	end
end

local lastLeaderVisualSync = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastLeaderVisualSync < 0.05 then return end
	lastLeaderVisualSync = now

	if not player.Character then return end
	local myDance = player.Character:GetAttribute("CurrentDance")
	if not myDance or not currentPlayingTrack or not currentPlayingTrack.IsPlaying then return end

	local myTime = currentPlayingTrack.TimePosition
	local myLength = currentPlayingTrack.Length
	if not myLength or myLength <= 0 then return end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local syncTarget = otherPlayer.Character:GetAttribute("Syncing")
			if syncTarget == player.Name then
				local oHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
				local oAnim = oHum and oHum:FindFirstChildOfClass("Animator")
				if oAnim then
					local ok, oTracks = pcall(function() return oAnim:GetPlayingAnimationTracks() end)
					if ok and oTracks then
						for _, oTrack in ipairs(oTracks) do
							if oTrack.IsPlaying and oTrack.Animation and currentPlayingTrack.Animation and (oTrack.Animation.AnimationId == currentPlayingTrack.Animation.AnimationId) then
								local trackLen = oTrack.Length or myLength
								if trackLen and trackLen > 0 then
									if syncedFollowerDances[otherPlayer] ~= myDance then

										oTrack.TimePosition = myTime
										syncedFollowerDances[otherPlayer] = myDance
									else
										local diff = oTrack.TimePosition - myTime
										if diff > trackLen / 2 then diff = diff - trackLen end
										if diff < -trackLen / 2 then diff = diff + trackLen end

										if math.abs(diff) > 0.35 then
											oTrack.TimePosition = myTime
										end
									end
								end
							end
						end
					end
				end
			else
				syncedFollowerDances[otherPlayer] = nil
			end
		end
	end
end)

setupSyncMonitoring()

player.CharacterAdded:Connect(function()
	currentPlayingTrack = nil
	currentPlayingName  = nil
	selectButtonInstantly(nil)
	task.wait(0.5)
	setupSyncMonitoring()
end)

task.spawn(function()
	while true do
		task.wait(0.4)
		if isSyncing and currentLeaderName then
			local lp = Players:FindFirstChild(currentLeaderName)
			if lp and lp.Character then
				local lTrack, lName = getLeaderTrackAndName(lp)
				if lTrack and lName then
					if dancelabel.Text ~= "♪ " .. lName then
						dancelabel.Text = "♪ " .. lName
					end
					if currentPlayingTrack and currentPlayingTrack.IsPlaying and currentPlayingTrack.Animation then
						local trackLen = currentPlayingTrack.Length
						if trackLen and trackLen > 0 then
							local leaderStartTime = lp.Character and lp.Character:GetAttribute("DanceStartTime")
							local targetSpeed = (lp.Character and lp.Character:GetAttribute("DanceSpeed")) or lTrack.Speed or 1
							local idealTime = lTrack.TimePosition
							if leaderStartTime then
								local elapsed = (workspace:GetServerTimeNow() - leaderStartTime) * targetSpeed
								if elapsed >= 0 then
									idealTime = elapsed % trackLen
								end
							end

							local diff = currentPlayingTrack.TimePosition - idealTime
							if diff > trackLen / 2 then diff = diff - trackLen end
							if diff < -trackLen / 2 then diff = diff + trackLen end

							local absDiff = math.abs(diff)
							if absDiff > 0.45 then
								currentPlayingTrack.TimePosition = idealTime
							elseif absDiff > 0.06 then
								local nudge = (diff < 0) and 1.06 or 0.94
								currentPlayingTrack:AdjustSpeed(targetSpeed * nudge)
							else
								currentPlayingTrack:AdjustSpeed(targetSpeed)
							end
						end
					else
						syncFollowerToLeaderTrack(lTrack, lName)
					end
				else
					if currentPlayingTrack and currentPlayingTrack.IsPlaying then
						stopLocalDance(false)
					end
					local dn = lp.DisplayName or lp.Name
					local waitingText = "♪ Waiting for " .. dn
					if dancelabel.Text ~= waitingText then
						dancelabel.Text = waitingText
					end
				end
			else
				if not lp then
					isSyncing = false
					currentLeaderName = nil
					if player.Character then
						player.Character:SetAttribute("Syncing", nil)
					end
					stopLocalDance(false)
					updateUnsyncFrame()
				end
			end
		end
	end
end)

local function animationStarted(animation)
	local animName = animation.Name

	local snd = ReplicatedStorage:FindFirstChild("Sounds")
	if snd then
		local s = snd:FindFirstChild("minimal-pop-click-ui")
		if s then s:Play() end
	end

	if currentPlayingName == animName and currentPlayingTrack and currentPlayingTrack.IsPlaying then
		stopLocalDance(true)
		return
	end

	if isSyncing then
		isSyncing = false
		local prevLeader = currentLeaderName
		currentLeaderName = nil
		if player.Character then
			player.Character:SetAttribute("Syncing", nil)
		end
		updateUnsyncFrame()
		if prevLeader then
			local lp = Players:FindFirstChild(prevLeader)
			if lp then
				startSyncRE:FireServer(lp, false)
			end
		end
	end

	if currentPlayingTrack and currentPlayingTrack.IsPlaying then
		currentPlayingTrack:Stop(0.15)
		currentPlayingTrack = nil
	end

	local animator = AnimatorUtils.getAnimator(player)
	if not animator then return end

	local track = AnimatorUtils.getOrCreateTrack(animator, animation)
	if not track then
		track = animator:LoadAnimation(animation)
	end

	if track then
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play(0.15, 1.0, currentSpeed)
		track:AdjustSpeed(currentSpeed)

		currentPlayingTrack = track
		currentPlayingName = animName
		selectButtonInstantly(animName)

		if player.Character then
			player.Character:SetAttribute("CurrentDance", animName)
			player.Character:SetAttribute("DanceSpeed", currentSpeed)
			player.Character:SetAttribute("DanceStartTime", workspace:GetServerTimeNow())
		end

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:GetAttribute("Syncing") == player.Name then
				syncedFollowerDances[otherPlayer] = animName
				local oHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
				local oAnim = oHum and oHum:FindFirstChildOfClass("Animator")
				if oAnim then
					local fTrack = AnimatorUtils.getOrCreateTrack(oAnim, animation)
					if not fTrack then
						fTrack = oAnim:LoadAnimation(animation)
					end
					if fTrack then
						fTrack.Priority = Enum.AnimationPriority.Action4
						fTrack.Looped = true
						fTrack:Play(0.15, 1.0, currentSpeed)
						fTrack:AdjustSpeed(currentSpeed)
						fTrack.TimePosition = 0

						local ok, oTracks = pcall(function() return oAnim:GetPlayingAnimationTracks() end)
						if ok and oTracks then
							for _, t in ipairs(oTracks) do
								if t ~= fTrack and t.IsPlaying and t.Animation and t.Animation.AnimationId ~= animation.AnimationId then
									pcall(function() t:Stop(0.15) end)
								end
							end
						end
					end
				end
			end
		end
	end

	task.spawn(function()
		local ok, result = pcall(function()
			return animationStartRF:InvokeServer(animation, true, currentSpeed)
		end)
		if not ok then
			warn("[EmoteHandler] Server invoke error:", result)
		end
	end)
end

updateDisplay = function()
	containerlist.CanvasPosition = Vector2.new(0, 0)

	local visibleData = {}

	for _, data in ipairs(allButtons) do
		data.button.Visible = false

		local show = false

		if currentCategory == "Favorite" then
			show = favoritedAnimations[data.name] == true
		elseif currentCategory == data.category then
			show = true
		end

		if show and searchQuery ~= "" then
			show = string.find(string.lower(data.name), string.lower(searchQuery), 1, true) ~= nil
		end

		if show then
			table.insert(visibleData, data)
		end
	end

	table.sort(visibleData, function(a, b)
		if currentSort == "ZA" then
			return a.name:lower() > b.name:lower()
		else
			return a.name:lower() < b.name:lower()
		end
	end)

	for i, data in ipairs(visibleData) do
		data.button.LayoutOrder = i
		data.button.Visible     = true
	end
end

local function toggleFavorite(animation, favBtn)
	favoritedAnimations[animation.Name] = not favoritedAnimations[animation.Name]

	favBtn.TextColor3 = favoritedAnimations[animation.Name]
		and C.TextWhite
		or C.TextDark

	saveFavoritedAnimations()

	if currentCategory == "Favorite" then
		updateDisplay()
	end
end

local function createEmoteButton(animation, category)
	local nb = templateframe:Clone()
	nb.Name    = animation.Name
	nb.Visible = true

	local tBtn = nb:FindFirstChild("TemplateBtn")
	local fBtn = nb:FindFirstChild("FavoriteBtn")

	if tBtn then
		tBtn.Text = animation.Name
	end

	if fBtn then
		fBtn.TextColor3 = favoritedAnimations[animation.Name]
			and C.TextWhite
			or C.TextDark

		fBtn.MouseButton1Click:Connect(function()
			toggleFavorite(animation, fBtn)
		end)
	end

	local buttonData = {
		button      = nb,
		animation   = animation,
		category    = category,
		name        = animation.Name,
		activeTween = nil,
	}

	table.insert(allButtons, buttonData)
	buttonsByName[animation.Name] = buttonData

	if tBtn then
		local btnGrad = ThemeModule.CreatePrimaryGradient(nb, 45, 1)
		btnGrad.Enabled = false

		tBtn.MouseButton1Click:Connect(function()
			animationStarted(animation)
		end)

		tBtn.MouseEnter:Connect(function()
			local g = nb:FindFirstChildOfClass("UIGradient")
			if g and g.Enabled then return end

			if buttonData.activeTween then
				buttonData.activeTween:Cancel()
			end

			buttonData.activeTween = TweenService:Create(nb, TweenInfo.new(0.05), {
				BackgroundColor3 = C.BackgroundLighter
			})
			buttonData.activeTween:Play()
		end)

		tBtn.MouseLeave:Connect(function()
			local g = nb:FindFirstChildOfClass("UIGradient")
			if g and g.Enabled then return end

			if buttonData.activeTween then
				buttonData.activeTween:Cancel()
			end

			buttonData.activeTween = TweenService:Create(nb, TweenInfo.new(0.05), {
				BackgroundColor3 = C.BackgroundLight
			})
			buttonData.activeTween:Play()
		end)
	end

	nb.Parent = containerlist
	return nb
end

local tabGradients = {
	Dance = danceGrad,
	Pose = poseGrad,
	Favorite = favoriteGrad
}

local tabBtns = {
	Dance = danceBtn,
	Pose = poseBtn,
	Favorite = favoriteBtn
}

local function setActiveCategory(category)
	currentCategory = category
	searchBox.Text  = ""
	searchQuery     = ""

	for name, btn in pairs(tabBtns) do
		local active = (name == category)
		local gr     = tabGradients[name]

		if active then
			btn.TextColor3       = C.BackgroundDark
			btn.BackgroundColor3 = C.Primary1
			gr.Enabled           = true
		else
			btn.TextColor3       = C.TextGray
			btn.BackgroundColor3 = C.BackgroundMedium
			gr.Enabled           = false
		end
	end

	updateDisplay()
end

danceBtn.MouseButton1Click:Connect(function()
	setActiveCategory("Dance")
end)

poseBtn.MouseButton1Click:Connect(function()
	setActiveCategory("Pose")
end)

favoriteBtn.MouseButton1Click:Connect(function()
	setActiveCategory("Favorite")
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = searchBox.Text
	resetBtn.Visible = (searchQuery ~= "")
	updateDisplay()
end)

do
	local isDragging = false
	local activeDragInput = nil

	local function isPositionInSliderArea(position)
		local barPos = speedBar.AbsolutePosition
		local barSize = speedBar.AbsoluteSize
		local margin = 15 * scaler:GetCurrentScale()

		return position.X >= barPos.X - margin
			and position.X <= barPos.X + barSize.X + margin
			and position.Y >= barPos.Y - margin
			and position.Y <= barPos.Y + barSize.Y + margin
	end

	local function startDrag(input)
		if isSyncing then
			NotifModule.Warning("Sync Active", "Cannot change speed while syncing", 2)
			return false
		end

		if not isPositionInSliderArea(input.Position) then
			return false
		end

		isDragging = true
		activeDragInput = input
		return true
	end

	local function stopDrag(input)
		if input and activeDragInput and input ~= activeDragInput then
			if input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
				activeDragInput = nil
			end
			return
		end
		isDragging = false
		activeDragInput = nil
	end

	local function updateDrag(inputPosition)
		if not isDragging then return end

		local bx    = speedBar.AbsolutePosition.X
		local bw    = speedBar.AbsoluteSize.X
		local scale = math.clamp((inputPosition.X - bx) / bw, 0, 1)

		speedSlider.Position = UDim2.fromScale(scale, 0.5)
		speedFill.Size       = UDim2.new(scale, 0, 1, 0)

		local ns = math.floor(math.clamp(0.5 + scale * 2.5, 0.5, 3) * 10) / 10
		if ns ~= currentSpeed then
			currentSpeed = ns
			speedtext.Text = string.format("%.1fx", currentSpeed)
			if currentPlayingTrack and currentPlayingTrack.IsPlaying and not isSyncing then
				currentPlayingTrack:AdjustSpeed(currentSpeed)
				if player.Character then
					player.Character:SetAttribute("DanceSpeed", currentSpeed)
				end
			end
			if not isSyncing then
				changeSpeedRE:FireServer(currentSpeed)
			end
		end
	end

	speedButton.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			startDrag(input)
		end
	end)

	speedBar.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if isPositionInSliderArea(input.Position) then
				if startDrag(input) then
					updateDrag(input.Position)
				end
			end
		end
	end)

	speedSlider.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			stopDrag(input)
		end
	end)

	speedBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			stopDrag(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not isDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			stopDrag(nil)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if not isDragging then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateDrag(input.Position)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			if activeDragInput == nil or input == activeDragInput or isPositionInSliderArea(input.Position) then
				updateDrag(input.Position)
			end
		end
	end)

	local initialScale = (1.0 - 0.5) / 2.5
	speedSlider.Position = UDim2.fromScale(initialScale, 0.5)
	speedFill.Size       = UDim2.new(initialScale, 0, 1, 0)
	speedtext.Text       = "1.0x"
end

task.spawn(function()
	preloadLabel.Visible = true

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	task.wait(1.5)

	local ok = AnimationPreloader.preloadAnimations(emotesFolder)

	preloadLabel.Text = ok and "Animations ready!" or "Preload failed"
	task.wait(ok and 1.5 or 3)
	preloadLabel.Visible = false
end)

local poseFolder = emotesFolder:FindFirstChild("Pose")
if not poseFolder then
	poseFolder = Instance.new("Folder")
	poseFolder.Name = "Pose"
	poseFolder.Parent = emotesFolder
end

local function getOrCreateAnim(folder, name, animId)
	local anim = folder:FindFirstChild(name)
	if not anim or not anim:IsA("Animation") then
		anim = Instance.new("Animation")
		anim.Name = name
		anim.AnimationId = animId
		anim.Parent = folder
	else
		anim.AnimationId = animId
	end
	return anim
end

for _, item in ipairs(DanceConfig) do
	local anim = getOrCreateAnim(emotesFolder, item.name, item.animationId)
	createEmoteButton(anim, "Dance")
end

for _, item in ipairs(PoseConfig) do
	local anim = getOrCreateAnim(poseFolder, item.name, item.animationId)
	createEmoteButton(anim, "Pose")
end

for _, anim in ipairs(emotesFolder:GetChildren()) do
	if anim:IsA("Animation") and not buttonsByName[anim.Name] then
		createEmoteButton(anim, "Dance")
	end
end

for _, anim in ipairs(poseFolder:GetChildren()) do
	if anim:IsA("Animation") and not buttonsByName[anim.Name] then
		createEmoteButton(anim, "Pose")
	end
end

setActiveCategory("Dance")

Players.PlayerRemoving:Connect(function(rp)
	syncedFollowerDances[rp] = nil
	if isSyncing and currentLeaderName and rp.Name == currentLeaderName then
		isSyncing = false
		currentLeaderName = nil
		if player.Character then
			player.Character:SetAttribute("Syncing", nil)
		end
		stopLocalDance(false)
		updateUnsyncFrame()
	end

	if rp ~= player then return end

	for name in pairs(topbarConnections) do
		cleanupTopBarConnections(name)
	end

	if emoteIcon then
		pcall(function() emoteIcon:destroy() end)
	end

	if danceGrad then ThemeModule.GradientSystem.Unregister(danceGrad) end
	if poseGrad then ThemeModule.GradientSystem.Unregister(poseGrad) end
	if favoriteGrad then ThemeModule.GradientSystem.Unregister(favoriteGrad) end

	if scaler then
		scaler:Destroy()
	end

	emoteIcon = nil
	topbarConnections = {}
end)

script.Destroying:Connect(function()
	if syncUpdateConnection and syncUpdateConnection.Connected then
		syncUpdateConnection:Disconnect()
	end

	if leaderAnimationConnection and leaderAnimationConnection.Connected then
		leaderAnimationConnection:Disconnect()
	end

	if leaderStoppedConnection and leaderStoppedConnection.Connected then
		leaderStoppedConnection:Disconnect()
	end

	if leaderCharConnection and leaderCharConnection.Connected then
		leaderCharConnection:Disconnect()
	end

	if currentDanceConnection and currentDanceConnection.Connected then
		currentDanceConnection:Disconnect()
	end

	if danceGrad then ThemeModule.GradientSystem.Unregister(danceGrad) end
	if poseGrad then ThemeModule.GradientSystem.Unregister(poseGrad) end
	if favoriteGrad then ThemeModule.GradientSystem.Unregister(favoriteGrad) end

	if scaler then
		scaler:Destroy()
	end
end)

print("[EmoteHandler] Siap - AutoScale:", scaler:GetCurrentScale())

