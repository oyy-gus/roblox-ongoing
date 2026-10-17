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

local FRAME_W  = 300
local FRAME_H  = 440
local PAD      = 10
local INNER_W  = FRAME_W - PAD * 2

local HDR_H    = 36
local SRCH_H   = 28
local TAB_H    = 32
local SPEED_H  = 34
local GAP      = 8

local CONT_TOP = HDR_H + GAP + SRCH_H + GAP + TAB_H + GAP
local CONT_BOT = GAP + SPEED_H + GAP
local CONT_H   = FRAME_H - CONT_TOP - CONT_BOT

local BTN_HEIGHT  = 48
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
headerLabel.TextSize         = 15
headerLabel.Font             = Enum.Font.GothamBold
headerLabel.TextXAlignment   = Enum.TextXAlignment.Center
headerLabel.TextYAlignment   = Enum.TextYAlignment.Center
headerLabel.Parent           = headerFrame
gradient(headerLabel, G.Primary, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Name                   = "CloseBtn"
closeBtn.Size                   = UDim2.new(0, 28, 0, 28)
closeBtn.AnchorPoint            = Vector2.new(1, 0.5)
closeBtn.Position               = UDim2.new(1, -6, 0.5, 0)
closeBtn.BackgroundColor3       = C.CloseRed
closeBtn.BackgroundTransparency = 0
closeBtn.Text                   = "x"
closeBtn.TextColor3             = C.TextWhite or Color3.fromHex("#FFFFFF")
closeBtn.TextSize               = 14
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.BorderSizePixel        = 0
closeBtn.AutoButtonColor        = false
closeBtn.ZIndex                 = 5
closeBtn.Parent                 = headerFrame
corner(closeBtn, 6)

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

local searchBox = Instance.new("TextBox")
searchBox.Name              = "SearchBox"
searchBox.Size              = UDim2.new(1, -30, 1, 0)
searchBox.Position          = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextColor3        = C.TextWhite
searchBox.PlaceholderText   = UIStrings.Emote.SearchPlaceholder
searchBox.PlaceholderColor3 = C.TextMuted
searchBox.Text              = ""
searchBox.TextSize          = 13
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

local resetBtn = Instance.new("ImageButton")
resetBtn.Name                   = "ResetBtn"
resetBtn.Size                   = UDim2.new(0, 20, 0, 20)
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
	btn.TextSize         = 12
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
	g.Rotation = 90
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
templateBtnInner.TextSize               = 14
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
templateFavBtn.Size                   = UDim2.new(0, 42, 1, 0)
templateFavBtn.AnchorPoint            = Vector2.new(1, 0)
templateFavBtn.Position               = UDim2.new(1, -4, 0, 0)
templateFavBtn.BackgroundTransparency = 1
templateFavBtn.Text                   = "★"
templateFavBtn.TextColor3             = C.TextDark
templateFavBtn.TextSize               = 20
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
speedLabel.Size = UDim2.new(0, 42, 1, 0)
speedLabel.Position = UDim2.new(0, 8, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = C.TextGray
speedLabel.TextSize = 11
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local speedtext = Instance.new("TextLabel")
speedtext.Name = "TextLabel"
speedtext.Size = UDim2.new(0, 38, 1, 0)
speedtext.AnchorPoint = Vector2.new(1, 0)
speedtext.Position = UDim2.new(1, -6, 0, 0)
speedtext.BackgroundTransparency = 1
speedtext.Text = "1.0x"
speedtext.TextColor3 = C.Primary1
speedtext.TextSize = 12
speedtext.Font = Enum.Font.GothamBold
speedtext.Parent = speedFrame
gradient(speedtext, G.Primary, 0)

local speedBar = Instance.new("Frame")
speedBar.Name = "speedBar"
speedBar.Size = UDim2.new(1, -96, 0, 6)
speedBar.Position = UDim2.new(0, 50, 0.5, -3)
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
gradient(speedFill, G.Primary, 0)

local speedSlider = Instance.new("Frame")
speedSlider.Name = "speedPosition"
speedSlider.Size = UDim2.new(0, 14, 0, 14)
speedSlider.AnchorPoint = Vector2.new(0.5, 0.5)
speedSlider.BackgroundColor3 = C.Primary1
speedSlider.BorderSizePixel = 0
speedSlider.Parent = speedBar
corner(speedSlider, 99)
gradient(speedSlider, G.Primary, 135)
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
unsyncBtn.TextSize               = 11
unsyncBtn.Font                   = Enum.Font.GothamBold
unsyncBtn.Parent                 = unsyncframe

local dancelabel = Instance.new("TextLabel")
dancelabel.Name                  = "DanceLabel"
dancelabel.Size                  = UDim2.new(1, -10, 0, 18)
dancelabel.Position              = UDim2.new(0, 5, 1, -22)
dancelabel.BackgroundTransparency = 1
dancelabel.Text                  = "..."
dancelabel.TextColor3            = C.TextMuted
dancelabel.TextSize              = 10
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
preloadLabel.TextSize = 14
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

local syncUpdateConnection = nil
local leaderAnimationConnection = nil
local currentDanceConnection = nil
local currentlySelectedButton = nil

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

local function getLeaderCurrentAnimation()
	if not isSyncing or not currentLeaderName then return nil end

	local lp = Players:FindFirstChild(currentLeaderName)
	if not lp or not lp.Character then return nil end

	local humanoid = lp.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local anim = humanoid:FindFirstChildOfClass("Animator")
	if not anim then return nil end

	local ok, tracks = pcall(function() return anim:GetPlayingAnimationTracks() end)
	if not ok or not tracks then return nil end

	for _, track in ipairs(tracks) do
		if track.IsPlaying and track.Animation then
			local id = track.Animation.AnimationId

			local name = animIdToName[id]
			if not name then
				local num = tostring(id):match("%d+")
				if num then name = animIdToName[num] end
			end

			if name then
				return name
			end

			for _, a in ipairs(emotesFolder:GetChildren()) do
				if a:IsA("Animation") and a.AnimationId == id then
					return a.Name
				end
			end

			local pf = emotesFolder:FindFirstChild("Pose")
			if pf then
				for _, a in ipairs(pf:GetChildren()) do
					if a:IsA("Animation") and a.AnimationId == id then
						return a.Name
					end
				end
			end
		end
	end

	return nil
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
		dancelabel.Text = an and ("♪ " .. an) or ("♪ " .. dn .. "'s Dance")

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
	if not lp then
		if player.Character then
			player.Character:SetAttribute("Syncing", nil)
		end
		updateUnsyncFrame()
		return
	end

	startSyncRE:FireServer(lp, false)

	local snd = ReplicatedStorage:FindFirstChild("Sounds")
	if snd then
		local s = snd:FindFirstChild("minimal-pop-click-ui")
		if s then s:Play() end
	end

	task.wait(0.1)
	updateUnsyncFrame()
end)

local function setupSyncMonitoring()
	if syncUpdateConnection and syncUpdateConnection.Connected then
		syncUpdateConnection:Disconnect()
	end
	if leaderAnimationConnection and leaderAnimationConnection.Connected then
		leaderAnimationConnection:Disconnect()
	end

	syncUpdateConnection = nil
	leaderAnimationConnection = nil

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	updateUnsyncFrame()
	setupCurrentDanceListener()

	syncUpdateConnection = player.Character:GetAttributeChangedSignal("Syncing"):Connect(function()
		updateUnsyncFrame()

		if isSyncing and currentLeaderName then
			local lp = Players:FindFirstChild(currentLeaderName)
			if lp and lp.Character then
				local h = lp.Character:FindFirstChildOfClass("Humanoid")
				if h then
					local a = h:FindFirstChildOfClass("Animator")
					if a then
						if leaderAnimationConnection and leaderAnimationConnection.Connected then
							leaderAnimationConnection:Disconnect()
						end

						leaderAnimationConnection = a.AnimationPlayed:Connect(function(track)
							if not (isSyncing and track and track.Animation) then return end

							local id = track.Animation.AnimationId

							local name = animIdToName[id]
							if not name then
								local num = tostring(id):match("%d+")
								if num then name = animIdToName[num] end
							end

							if name then
								dancelabel.Text = "♪ " .. name
								return
							end

							for _, an in ipairs(emotesFolder:GetChildren()) do
								if an:IsA("Animation") and an.AnimationId == id then
									dancelabel.Text = "♪ " .. an.Name
									return
								end
							end

							local pf = emotesFolder:FindFirstChild("Pose")
							if pf then
								for _, an in ipairs(pf:GetChildren()) do
									if an:IsA("Animation") and an.AnimationId == id then
										dancelabel.Text = "♪ " .. an.Name
										return
									end
								end
							end
						end)
					end
				end
			end
		end
	end)
end

setupSyncMonitoring()

player.CharacterAdded:Connect(function()
	task.wait(1)
	setupSyncMonitoring()
end)

task.spawn(function()
	while true do
		task.wait(0.3)
		if isSyncing and unsyncframe.Visible then
			local an = getLeaderCurrentAnimation()
			if an and dancelabel.Text ~= "♪ " .. an then
				dancelabel.Text = "♪ " .. an
			end
		end
	end
end)

local function animationStarted(animation)
	selectButtonInstantly(animation.Name)

	local snd = ReplicatedStorage:FindFirstChild("Sounds")
	if snd then
		local s = snd:FindFirstChild("minimal-pop-click-ui")
		if s then s:Play() end
	end

	task.spawn(function()
		local ok, result = pcall(function()
			return animationStartRF:InvokeServer(animation, true, currentSpeed)
		end)

		if not ok then
			warn("[EmoteHandler] Panggilan server gagal:", result)
		end
	end)
end

local function updateDisplay()
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
			show = string.lower(data.name):sub(1, #searchQuery) == string.lower(searchQuery)
		end

		if show then
			table.insert(visibleData, data)
		end
	end

	table.sort(visibleData, function(a, b)
		return a.name:lower() < b.name:lower()
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
		local btnGrad = ThemeModule.CreatePrimaryGradient(nb, 90, 1)
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
