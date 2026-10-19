local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

repeat task.wait() until player.Character
task.wait(1)

local CarryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CarryConfig"))
local ThemeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ThemeModule"))
local UIStrings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStrings"))

local AutoScaleSystem = ReplicatedStorage:WaitForChild("AutoScaleSystem")
local ScaleSystem = require(AutoScaleSystem:WaitForChild("ScaleSystem"))

local remoteFolder = ReplicatedStorage:WaitForChild(CarryConfig.REMOTE_FOLDER, 10)
if not remoteFolder then
	warn("[Gendong UI] Folder Remote tidak ditemukan!")
	return
end

local RequestRemote = remoteFolder:WaitForChild("CarryRequest", 10)
local ResponseRemote = remoteFolder:WaitForChild("CarryResponse", 10)
local EndRemote = remoteFolder:WaitForChild("CarryEnd", 10)

local gui = script.Parent
if not gui:IsA("ScreenGui") then

	warn("[CARRY UI] Parent bukan ScreenGui — membuat fallback ScreenGui")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("CarryGui")
	if existing then
		gui = existing
	else
		gui = Instance.new("ScreenGui")
		gui.Name = "CarryGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 100
		gui.Parent = playerGui
	end
	script.Parent = gui
end

if gui:IsA("ScreenGui") then
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
end

local guiScaler = ScaleSystem.new(gui)

local function getCurrentScale()
	return guiScaler:GetCurrentScale()
end

local Theme = {
	MenuBg = Color3.fromHex("#080808"),
	MenuBgTransparency = 0.1,

	SegmentDefault = Color3.fromHex("#151515"),
	SegmentHover = Color3.fromHex("#FFFFFF"),
	SegmentSelected = Color3.fromHex("#888888"),

	TextWhite = Color3.fromHex("#FFFFFF"),
	TextMuted = Color3.fromHex("#666666"),
	TextDark = Color3.fromHex("#111111"),

	AccentGold = Color3.fromHex("#FFFFFF"),
	AccentRed = Color3.fromHex("#2A2A2A"),
	AccentGreen = Color3.fromHex("#FFFFFF"),

	BorderColor = Color3.fromHex("#353535"),
	BorderGlow = Color3.fromHex("#FFFFFF"),
	DividerColor = Color3.fromHex("#353535"),
	DividerHighlight = Color3.fromHex("#FFFFFF"),
}

local CarryStyles = {
	{
		id = "bridal",
		name = "Pengantin",
		icon = "💒",
		description = "Gaya gendong romantis",
		angle = 0,
	},
	{
		id = "couplehug",
		name = "Pelukan",
		icon = "🤗",
		description = "Peluk saat menggendong",
		angle = 72,
	},
	{
		id = "pasakal",
		name = "Pasakal",
		icon = "🎭",
		description = "Gaya tradisional",
		angle = 144,
	},
	{
		id = "piggyback",
		name = "Punggung",
		icon = "🐷",
		description = "Gendong di punggung",
		angle = 216,
	},
	{
		id = "piggyupperback",
		name = "Pundak Atas",
		icon = "🔝",
		description = "Gendong di pundak atas",
		angle = 288,
	},
}

local MENU_SIZE = 320
local CENTER_SIZE = 70
local ICON_SIZE = 50
local LABEL_OFFSET = 115
local DIVIDER_INNER = 40
local DIVIDER_OUTER = 155

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, thickness, color, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = color or Theme.BorderColor
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local function createGradient(parent, color1, color2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2),
	})
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function cleanupExistingUI()
	local existingElements = {"RadialMenu", "NotificationFrame", "GetDownBtn"}
	for _, name in ipairs(existingElements) do
		local existing = gui:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

cleanupExistingUI()

local menuContainer = Instance.new("Frame")
menuContainer.Name = "RadialMenu"
menuContainer.Size = UDim2.new(0, MENU_SIZE, 0, MENU_SIZE)
menuContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
menuContainer.AnchorPoint = Vector2.new(0.5, 0.5)
menuContainer.BackgroundTransparency = 1
menuContainer.Visible = false
menuContainer.ZIndex = 10
menuContainer.Parent = gui

local outerRing = Instance.new("Frame")
outerRing.Name = "OuterRing"
outerRing.Size = UDim2.new(1, 0, 1, 0)
outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
outerRing.BackgroundColor3 = Theme.MenuBg
outerRing.BackgroundTransparency = Theme.MenuBgTransparency
outerRing.ZIndex = 11
outerRing.Parent = menuContainer
corner(outerRing, MENU_SIZE / 2)

stroke(outerRing, 3, Theme.BorderColor, 0.2)

local glowStroke = Instance.new("UIStroke")
glowStroke.Name = "GlowStroke"
glowStroke.Thickness = 2
glowStroke.Color = Theme.AccentGold
glowStroke.Transparency = 0.7
glowStroke.Parent = outerRing

local dividerContainer = Instance.new("Frame")
dividerContainer.Name = "DividerContainer"
dividerContainer.Size = UDim2.new(1, 0, 1, 0)
dividerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
dividerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
dividerContainer.BackgroundTransparency = 1
dividerContainer.ZIndex = 12
dividerContainer.Parent = menuContainer

local dividerLines = {}
local segmentAngle = 360 / #CarryStyles

for i = 1, #CarryStyles do
	local dividerAngle = CarryStyles[i].angle - (segmentAngle / 2)
	local angleRad = math.rad(dividerAngle - 90)
	local lineLength = DIVIDER_OUTER - DIVIDER_INNER

	local dividerLine = Instance.new("Frame")
	dividerLine.Name = "Divider_" .. i
	dividerLine.Size = UDim2.new(0, 2, 0, lineLength)
	dividerLine.Position = UDim2.new(0.5, 0, 0.5, 0)
	dividerLine.AnchorPoint = Vector2.new(0.5, 1)
	dividerLine.BackgroundColor3 = Theme.DividerColor
	dividerLine.BackgroundTransparency = 0.2
	dividerLine.BorderSizePixel = 0
	dividerLine.Rotation = dividerAngle
	dividerLine.ZIndex = 13
	dividerLine.Parent = dividerContainer

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 150)),
		ColorSequenceKeypoint.new(0.5, Theme.DividerColor),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 50)),
	})
	gradient.Rotation = 180
	gradient.Parent = dividerLine

	corner(dividerLine, 1)

	table.insert(dividerLines, {
		frame = dividerLine,
		angle = dividerAngle,
		index = i
	})
end

local centerCircle = Instance.new("Frame")
centerCircle.Name = "CenterCircle"
centerCircle.Size = UDim2.new(0, CENTER_SIZE, 0, CENTER_SIZE)
centerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
centerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
centerCircle.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
centerCircle.ZIndex = 20
centerCircle.Parent = menuContainer
corner(centerCircle, CENTER_SIZE / 2)
stroke(centerCircle, 2, Theme.AccentRed, 0.3)

createGradient(centerCircle,
	Color3.fromRGB(70, 35, 35),
	Color3.fromRGB(40, 20, 20),
	135
)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(1, 0, 1, 0)
closeBtn.Position = UDim2.new(0, 0, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "x"
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextXAlignment = Enum.TextXAlignment.Center
closeBtn.TextYAlignment = Enum.TextYAlignment.Center
closeBtn.TextColor3 = Theme.AccentRed
closeBtn.ZIndex = 21
closeBtn.Parent = centerCircle

local closePad = Instance.new("UIPadding")
closePad.PaddingBottom = UDim.new(0, 4)
closePad.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(centerCircle, TweenInfo.new(0.15), {
		BackgroundColor3 = Theme.AccentRed
	}):Play()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		TextColor3 = Theme.TextWhite
	}):Play()

	local strokeObj = centerCircle:FindFirstChildOfClass("UIStroke")
	if strokeObj then
		TweenService:Create(strokeObj, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(255, 100, 100),
			Transparency = 0
		}):Play()
	end
end)

closeBtn.MouseLeave:Connect(function()
	TweenService:Create(centerCircle, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(50, 30, 30)
	}):Play()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {
		TextColor3 = Theme.AccentRed
	}):Play()

	local strokeObj = centerCircle:FindFirstChildOfClass("UIStroke")
	if strokeObj then
		TweenService:Create(strokeObj, TweenInfo.new(0.15), {
			Color = Theme.AccentRed,
			Transparency = 0.3
		}):Play()
	end
end)

local hoverInfoFrame = Instance.new("Frame")
hoverInfoFrame.Name = "HoverInfo"
hoverInfoFrame.Size = UDim2.new(0, 120, 0, 50)
hoverInfoFrame.Position = UDim2.new(0.5, 0, 0.5, -55)
hoverInfoFrame.AnchorPoint = Vector2.new(0.5, 1)
hoverInfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hoverInfoFrame.BackgroundTransparency = 0.2
hoverInfoFrame.Visible = false
hoverInfoFrame.ZIndex = 25
hoverInfoFrame.Parent = menuContainer
corner(hoverInfoFrame, 10)
stroke(hoverInfoFrame, 1, Theme.AccentGold, 0.3)

local hoverIcon = Instance.new("TextLabel")
hoverIcon.Name = "HoverIcon"
hoverIcon.Size = UDim2.new(1, 0, 0, 28)
hoverIcon.Position = UDim2.new(0, 0, 0, 2)
hoverIcon.BackgroundTransparency = 1
hoverIcon.Text = "💒"
hoverIcon.TextSize = 22
hoverIcon.Font = Enum.Font.GothamBold
hoverIcon.TextColor3 = Theme.TextWhite
hoverIcon.ZIndex = 26
hoverIcon.Parent = hoverInfoFrame

local hoverLabel = Instance.new("TextLabel")
hoverLabel.Name = "HoverLabel"
hoverLabel.Size = UDim2.new(1, 0, 0, 18)
hoverLabel.Position = UDim2.new(0, 0, 0, 30)
hoverLabel.BackgroundTransparency = 1
hoverLabel.Text = "Bridal"
hoverLabel.TextSize = UIStrings.TextSize.Caption
hoverLabel.Font = Enum.Font.GothamBold
hoverLabel.TextColor3 = Theme.AccentGold
hoverLabel.ZIndex = 26
hoverLabel.Parent = hoverInfoFrame

local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "TargetLabel"
targetLabel.Size = UDim2.new(0, 240, 0, 30)
targetLabel.Position = UDim2.new(0.5, 0, 0, -42)
targetLabel.AnchorPoint = Vector2.new(0.5, 0)
targetLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
targetLabel.BackgroundTransparency = 0.3
targetLabel.Text = "Carry: PlayerName"
targetLabel.TextSize = UIStrings.TextSize.Caption
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextColor3 = Theme.AccentGold
targetLabel.ZIndex = 25
targetLabel.Parent = menuContainer
corner(targetLabel, 12)
stroke(targetLabel, 1, Theme.AccentGold, 0.5)

local segmentButtons = {}
local segmentFrames = {}

local function createSegmentButton(styleData, index)
	local angle = math.rad(styleData.angle - 90)
	local radius = LABEL_OFFSET
	local x = math.cos(angle) * radius
	local y = math.sin(angle) * radius

	local segmentFrame = Instance.new("Frame")
	segmentFrame.Name = "Segment_" .. styleData.id
	segmentFrame.Size = UDim2.new(0, 75, 0, 75)
	segmentFrame.Position = UDim2.new(0.5, x, 0.5, y)
	segmentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	segmentFrame.BackgroundTransparency = 1
	segmentFrame.ZIndex = 15
	segmentFrame.Parent = menuContainer

	local iconBg = Instance.new("Frame")
	iconBg.Name = "IconBg"
	iconBg.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	iconBg.Position = UDim2.new(0.5, 0, 0.35, 0)
	iconBg.AnchorPoint = Vector2.new(0.5, 0.5)
	iconBg.BackgroundColor3 = Theme.SegmentDefault
	iconBg.ZIndex = 16
	iconBg.Parent = segmentFrame
	corner(iconBg, ICON_SIZE / 2)
	stroke(iconBg, 2, Theme.BorderColor, 0.3)

	createGradient(iconBg,
		Color3.fromRGB(50, 50, 65),
		Color3.fromRGB(30, 30, 40),
		135
	)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = styleData.icon
	iconLabel.TextSize = 24
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Theme.TextWhite
	iconLabel.ZIndex = 17
	iconLabel.Parent = iconBg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 14, 0, 18)
	nameLabel.Position = UDim2.new(0.5, 0, 0.76, 0)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = styleData.name
	nameLabel.TextSize = UIStrings.TextSize.Caption
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Theme.TextMuted
	nameLabel.ZIndex = 17
	nameLabel.Parent = segmentFrame

	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 10, 1, 10)
	button.Position = UDim2.new(0.5, 0, 0.5, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.ZIndex = 18
	button.Parent = segmentFrame

	segmentButtons[styleData.id] = {
		frame = segmentFrame,
		iconBg = iconBg,
		iconLabel = iconLabel,
		nameLabel = nameLabel,
		button = button,
		data = styleData,
		index = index,
	}
	table.insert(segmentFrames, segmentFrame)

	return segmentFrame
end

for i, styleData in ipairs(CarryStyles) do
	createSegmentButton(styleData, i)
end

local instructionLabel = Instance.new("TextLabel")
instructionLabel.Name = "InstructionLabel"
instructionLabel.Size = UDim2.new(0, 320, 0, 24)
instructionLabel.Position = UDim2.new(0.5, 0, 1, 25)
instructionLabel.AnchorPoint = Vector2.new(0.5, 0)
instructionLabel.BackgroundTransparency = 1
instructionLabel.Text = "Ketuk gaya untuk memilih • Tengah untuk menutup"
instructionLabel.TextSize = UIStrings.TextSize.Caption
instructionLabel.Font = Enum.Font.Gotham
instructionLabel.TextWrapped = true
instructionLabel.TextColor3 = Theme.TextMuted
instructionLabel.ZIndex = 25
instructionLabel.Parent = menuContainer

local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 360, 0, 0)
notificationFrame.AutomaticSize = Enum.AutomaticSize.Y
notificationFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
notificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
notificationFrame.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
notificationFrame.Visible = false
notificationFrame.ZIndex = 50
notificationFrame.Parent = gui
corner(notificationFrame, 16)
ThemeModule.CreateAnimatedStroke(notificationFrame, 1.5, "Primary", 1.2)

local notifPadding = Instance.new("UIPadding")
notifPadding.PaddingTop = UDim.new(0, 14)
notifPadding.PaddingBottom = UDim.new(0, 14)
notifPadding.PaddingLeft = UDim.new(0, 14)
notifPadding.PaddingRight = UDim.new(0, 14)
notifPadding.Parent = notificationFrame

local notifListLayout = Instance.new("UIListLayout")
notifListLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifListLayout.FillDirection = Enum.FillDirection.Vertical
notifListLayout.Padding = UDim.new(0, 10)
notifListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifListLayout.Parent = notificationFrame

local notifTitle = Instance.new("TextLabel")
notifTitle.Name = "Title"
notifTitle.Size = UDim2.new(1, 0, 0, 24)
notifTitle.BackgroundTransparency = 1
notifTitle.Text = "📩 PERMINTAAN GENDONG"
notifTitle.TextSize = UIStrings.TextSize.Title
notifTitle.Font = Enum.Font.GothamBold
notifTitle.TextColor3 = ThemeModule.Colors.Primary1
notifTitle.TextXAlignment = Enum.TextXAlignment.Left
notifTitle.LayoutOrder = 1
notifTitle.ZIndex = 51
notifTitle.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "NotifLabel"
notifLabel.Size = UDim2.new(1, 0, 0, 0)
notifLabel.AutomaticSize = Enum.AutomaticSize.Y
notifLabel.BackgroundTransparency = 1
notifLabel.Text = "Pemain ingin menggendong Anda"
notifLabel.TextSize = UIStrings.TextSize.Body
notifLabel.Font = Enum.Font.Gotham
notifLabel.TextColor3 = ThemeModule.Colors.TextGray
notifLabel.TextWrapped = true
notifLabel.TextXAlignment = Enum.TextXAlignment.Left
notifLabel.LayoutOrder = 2
notifLabel.ZIndex = 51
notifLabel.Parent = notificationFrame

local notifBtnContainer = Instance.new("Frame")
notifBtnContainer.Size = UDim2.new(1, 0, 0, 44)
notifBtnContainer.BackgroundTransparency = 1
notifBtnContainer.LayoutOrder = 3
notifBtnContainer.ZIndex = 51
notifBtnContainer.Parent = notificationFrame

local notifBtnLayout = Instance.new("UIListLayout")
notifBtnLayout.FillDirection = Enum.FillDirection.Horizontal
notifBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifBtnLayout.Padding = UDim.new(0, 15)
notifBtnLayout.Parent = notifBtnContainer

local acceptBtn = Instance.new("TextButton")
acceptBtn.Name = "AcceptBtn"
acceptBtn.Size = UDim2.new(0, 130, 0, 44)
acceptBtn.BackgroundColor3 = ThemeModule.Colors.ButtonPrimaryBg
acceptBtn.Text = "✓ Terima"
acceptBtn.TextSize = UIStrings.TextSize.Button
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.TextColor3 = ThemeModule.Colors.ButtonPrimaryText
acceptBtn.ZIndex = 52
acceptBtn.Parent = notifBtnContainer
corner(acceptBtn, 8)

local rejectBtn = Instance.new("TextButton")
rejectBtn.Name = "RejectBtn"
rejectBtn.Size = UDim2.new(0, 130, 0, 44)
rejectBtn.BackgroundColor3 = ThemeModule.Colors.CloseRed
rejectBtn.Text = "✖️ Tolak"
rejectBtn.TextSize = UIStrings.TextSize.Button
rejectBtn.Font = Enum.Font.GothamBold
rejectBtn.TextColor3 = ThemeModule.Colors.TextWhite
rejectBtn.ZIndex = 52
rejectBtn.Parent = notifBtnContainer
corner(rejectBtn, 8)

local getDownBtn = Instance.new("TextButton")
getDownBtn.Name = "GetDownBtn"
getDownBtn.Size = UDim2.new(0, 180, 0, 50)
getDownBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
getDownBtn.AnchorPoint = Vector2.new(0.5, 0.5)
getDownBtn.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
getDownBtn.Text = "🚫 TURUN"
getDownBtn.TextSize = UIStrings.TextSize.Button
getDownBtn.Font = Enum.Font.GothamBold
getDownBtn.TextColor3 = ThemeModule.Colors.TextWhite
getDownBtn.Visible = false
getDownBtn.ZIndex = 100
getDownBtn.Parent = gui
corner(getDownBtn, 12)
ThemeModule.CreateAnimatedStroke(getDownBtn, 2, "Primary", 1.2)

local currentState = "idle"
local selectedTarget = nil
local pendingCarrier = nil
local pendingStyle = nil
local styleTimeoutToken = 0
local connections = {}
local currentAnimTracks = {carrier = nil, carried = nil}
local jumpBlockConn = nil
local hoveredStyle = nil

local function trackConnection(conn)
	table.insert(connections, conn)
	return conn
end

local function stopAllAnimations()
	for role, track in pairs(currentAnimTracks) do
		if track and track.IsPlaying then
			track:Stop(0.2)
		end
		currentAnimTracks[role] = nil
	end
end

local function cleanupState()
	selectedTarget = nil
	pendingCarrier = nil
	pendingStyle = nil
	styleTimeoutToken = styleTimeoutToken + 1
	stopAllAnimations()
end

local function getHumanoid()
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function getRigType()
	local hum = getHumanoid()
	return hum and (hum.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6") or "R15"
end

local function playAnimation(style, role)
	local hum = getHumanoid()
	if not hum then return end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end

	if currentAnimTracks[role] then
		currentAnimTracks[role]:Stop(0.15)
	end

	local rigType = getRigType()
	local animId = CarryConfig.getAnimationId(style, role, rigType)

	if animId == 0 then
		CarryConfig.debugPrint("ANIM", "No animation for", style, role)
		return
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)

	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if success and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.2)
		currentAnimTracks[role] = track
		CarryConfig.debugPrint("ANIM", "Playing", style, role, animId)
	else
		warn("[Gendong UI] Gagal memuat animasi:", animId)
	end
end

local function getAdjacentDividerIndices(segmentIndex)
	local totalStyles = #CarryStyles
	local leftIndex = segmentIndex
	local rightIndex = (segmentIndex % totalStyles) + 1
	return leftIndex, rightIndex
end

local function highlightDividers(segmentIndex, isHighlighted)
	local leftIdx, rightIdx = getAdjacentDividerIndices(segmentIndex)

	for i, divData in ipairs(dividerLines) do
		local divider = divData.frame

		if isHighlighted and (i == leftIdx or i == rightIdx) then
			TweenService:Create(divider, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.DividerHighlight,
				BackgroundTransparency = 0,
				Size = UDim2.new(0, 3, 0, DIVIDER_OUTER - DIVIDER_INNER + 5)
			}):Play()
		else
			TweenService:Create(divider, TweenInfo.new(0.15), {
				BackgroundColor3 = Theme.DividerColor,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(0, 2, 0, DIVIDER_OUTER - DIVIDER_INNER)
			}):Play()
		end
	end
end

local function resetAllDividers()
	for _, divData in ipairs(dividerLines) do
		TweenService:Create(divData.frame, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.DividerColor,
			BackgroundTransparency = 0.2,
			Size = UDim2.new(0, 2, 0, DIVIDER_OUTER - DIVIDER_INNER)
		}):Play()
	end
end

local menuAnimToken = 0
local activeMenuTweens = {}
local notifAnimToken = 0
local getDownAnimToken = 0

local function cancelMenuTweens()
	menuAnimToken += 1
	for _, tw in ipairs(activeMenuTweens) do
		pcall(function() tw:Cancel() end)
	end
	table.clear(activeMenuTweens)
end

local function animateMenuOpen()
	cancelMenuTweens()
	local token = menuAnimToken

	menuContainer.Visible = true
	menuContainer.Size = UDim2.new(0, 0, 0, 0)
	outerRing.BackgroundTransparency = 1
	hoverInfoFrame.Visible = false

	for _, divData in ipairs(dividerLines) do
		divData.frame.BackgroundTransparency = 1
		divData.frame.Size = UDim2.new(0, 2, 0, 0)
	end

	local scaleTween = TweenService:Create(menuContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, MENU_SIZE, 0, MENU_SIZE)
	})
	table.insert(activeMenuTweens, scaleTween)

	local fadeTween = TweenService:Create(outerRing, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		BackgroundTransparency = Theme.MenuBgTransparency
	})
	table.insert(activeMenuTweens, fadeTween)

	scaleTween:Play()
	fadeTween:Play()

	for i, frame in ipairs(segmentFrames) do
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)

		local styleData = CarryStyles[i]
		local angle = math.rad(styleData.angle - 90)
		local radius = LABEL_OFFSET
		local targetX = math.cos(angle) * radius
		local targetY = math.sin(angle) * radius

		task.delay(0.05 * i, function()
			if menuAnimToken ~= token then return end
			local segTween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, targetX, 0.5, targetY)
			})
			table.insert(activeMenuTweens, segTween)
			segTween:Play()
		end)
	end

	task.delay(0.25, function()
		if menuAnimToken ~= token then return end
		for i, divData in ipairs(dividerLines) do
			task.delay(0.04 * i, function()
				if menuAnimToken ~= token then return end
				local divTween = TweenService:Create(divData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.2,
					Size = UDim2.new(0, 2, 0, DIVIDER_OUTER - DIVIDER_INNER)
				})
				table.insert(activeMenuTweens, divTween)
				divTween:Play()
			end)
		end
	end)

	task.spawn(function()
		while menuContainer.Visible and menuAnimToken == token do
			local g1 = TweenService:Create(glowStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.3
			})
			table.insert(activeMenuTweens, g1)
			g1:Play()
			task.wait(1.5)
			if not menuContainer.Visible or menuAnimToken ~= token then break end
			local g2 = TweenService:Create(glowStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.8
			})
			table.insert(activeMenuTweens, g2)
			g2:Play()
			task.wait(1.5)
		end
	end)
end

local function animateMenuClose(callback)
	cancelMenuTweens()
	local token = menuAnimToken
	hoverInfoFrame.Visible = false

	for _, divData in ipairs(dividerLines) do
		local tw = TweenService:Create(divData.frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 2, 0, 0)
		})
		table.insert(activeMenuTweens, tw)
		tw:Play()
	end

	for i, frame in ipairs(segmentFrames) do
		local tw = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		})
		table.insert(activeMenuTweens, tw)
		tw:Play()
	end

	task.delay(0.15, function()
		if menuAnimToken ~= token then return end

		local scaleTween = TweenService:Create(menuContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		table.insert(activeMenuTweens, scaleTween)

		scaleTween.Completed:Connect(function()
			if menuAnimToken ~= token then return end
			menuContainer.Visible = false
			menuContainer.Size = UDim2.new(0, MENU_SIZE, 0, MENU_SIZE)

			for i, frame in ipairs(segmentFrames) do
				local styleData = CarryStyles[i]
				local angle = math.rad(styleData.angle - 90)
				local radius = LABEL_OFFSET
				frame.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
			end

			for _, divData in ipairs(dividerLines) do
				divData.frame.BackgroundTransparency = 0.2
				divData.frame.BackgroundColor3 = Theme.DividerColor
				divData.frame.Size = UDim2.new(0, 2, 0, DIVIDER_OUTER - DIVIDER_INNER)
			end

			if callback then callback() end
		end)

		scaleTween:Play()
	end)
end

local function animateNotificationIn()
	notifAnimToken += 1
	notificationFrame.Visible = true
	notificationFrame.Position = UDim2.new(0.5, 0, -0.2, 0)

	TweenService:Create(notificationFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.3, 0)
	}):Play()
end

local function animateNotificationOut(callback)
	notifAnimToken += 1
	local token = notifAnimToken
	TweenService:Create(notificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, -0.2, 0)
	}):Play()

	task.delay(0.3, function()
		if notifAnimToken ~= token then return end
		notificationFrame.Visible = false
		notificationFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
		if callback then callback() end
	end)
end

local function animateGetDownIn()
	getDownAnimToken += 1
	getDownBtn.Visible = true
	getDownBtn.Size = UDim2.new(0, 0, 0, 0)

	TweenService:Create(getDownBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 180, 0, 50)
	}):Play()
end

local function animateGetDownOut(callback)
	getDownAnimToken += 1
	local token = getDownAnimToken
	TweenService:Create(getDownBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()

	task.delay(0.2, function()
		if getDownAnimToken ~= token then return end
		getDownBtn.Visible = false
		getDownBtn.Size = UDim2.new(0, 180, 0, 50)
		if callback then callback() end
	end)
end

local function setSegmentHover(styleId, isHovered)
	local segment = segmentButtons[styleId]
	if not segment then return end

	local iconBg = segment.iconBg
	local nameLabel = segment.nameLabel
	local strokeObj = iconBg:FindFirstChildOfClass("UIStroke")

	if isHovered then
		hoveredStyle = styleId

		hoverIcon.Text = segment.data.icon
		hoverLabel.Text = segment.data.name
		hoverInfoFrame.Visible = true

		hoverInfoFrame.Size = UDim2.new(0, 100, 0, 40)
		TweenService:Create(hoverInfoFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 120, 0, 50)
		}):Play()

		TweenService:Create(iconBg, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.SegmentHover,
			Size = UDim2.new(0, ICON_SIZE + 10, 0, ICON_SIZE + 10)
		}):Play()

		TweenService:Create(nameLabel, TweenInfo.new(0.15), {
			TextColor3 = Theme.AccentGold,
			TextSize = UIStrings.TextSize.Caption
		}):Play()

		if strokeObj then
			TweenService:Create(strokeObj, TweenInfo.new(0.15), {
				Color = Theme.AccentGold,
				Transparency = 0,
				Thickness = 3
			}):Play()
		end

		highlightDividers(segment.index, true)

	else
		if hoveredStyle == styleId then
			hoveredStyle = nil
			hoverInfoFrame.Visible = false
		end

		TweenService:Create(iconBg, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.SegmentDefault,
			Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
		}):Play()

		TweenService:Create(nameLabel, TweenInfo.new(0.15), {
			TextColor3 = Theme.TextMuted,
			TextSize = UIStrings.TextSize.Caption
		}):Play()

		if strokeObj then
			TweenService:Create(strokeObj, TweenInfo.new(0.15), {
				Color = Theme.BorderColor,
				Transparency = 0.3,
				Thickness = 2
			}):Play()
		end

		resetAllDividers()
	end
end

for styleId, segment in pairs(segmentButtons) do
	segment.button.MouseEnter:Connect(function()
		setSegmentHover(styleId, true)
	end)

	segment.button.MouseLeave:Connect(function()
		setSegmentHover(styleId, false)
	end)
end

local function hideAllFrames()
	menuContainer.Visible = false
	notificationFrame.Visible = false
	getDownBtn.Visible = false
	hoverInfoFrame.Visible = false

	menuContainer.Size = UDim2.new(0, MENU_SIZE, 0, MENU_SIZE)

	for _, divData in ipairs(dividerLines) do
		divData.frame.BackgroundTransparency = 0.2
		divData.frame.BackgroundColor3 = Theme.DividerColor
	end

	CarryConfig.debugPrint("UI", "All frames hidden")
end

local function showStyleSelection(target)
	if not target or not target:IsA("Player") then
		warn("[Gendong UI] Target tidak valid untuk pemilihan gaya")
		return
	end

	currentState = "selecting_style"
	selectedTarget = target

	CarryConfig.debugPrint("UI", "=== SHOW STYLE SELECTION ===")
	CarryConfig.debugPrint("UI", "Target:", target.Name)

	if not player.Character or not target.Character then
		warn("[Gendong UI] Karakter belum siap")
		return
	end

	local myHRP = player.Character:FindFirstChild("HumanoidRootPart")
	local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")

	if not myHRP or not targetHRP then
		warn("[Gendong UI] HumanoidRootPart tidak ditemukan")
		return
	end

	local distance = (myHRP.Position - targetHRP.Position).Magnitude
	if distance > CarryConfig.MAX_DISTANCE then
		warn("[Gendong UI] Target terlalu jauh! Jarak:", distance)
		return
	end

	targetLabel.Text = "🎯 Gendong: " .. target.DisplayName
	hoveredStyle = nil

	hideAllFrames()
	task.wait(0.05)

	animateMenuOpen()

	local myToken = styleTimeoutToken + 1
	styleTimeoutToken = myToken

	task.delay(CarryConfig.REQUEST_TIMEOUT, function()
		if styleTimeoutToken == myToken and currentState == "selecting_style" then
			CarryConfig.debugPrint("UI", "Style selection timeout")
			animateMenuClose(function()
				cleanupState()
				currentState = "idle"
			end)
		end
	end)
end

local function showCarryNotification(carrierId, carrierName, style)
	currentState = "pending_response"
	pendingCarrier = carrierId
	pendingStyle = style

	CarryConfig.debugPrint("UI", "Show carry request from", carrierName, "style:", style)

	hideAllFrames()

	local styleData = CarryConfig.getStyle(style)
	local styleName = styleData and styleData.displayName or style

	local styleIcon = "🤝"
	for _, s in ipairs(CarryStyles) do
		if s.id == style then
			styleIcon = s.icon
			break
		end
	end

	notifLabel.Text = string.format("%s %s ingin menggendong Anda\nGaya: %s", styleIcon, carrierName, styleName)

	acceptBtn.BackgroundColor3 = ThemeModule.Colors.ButtonPrimaryBg
	rejectBtn.BackgroundColor3 = ThemeModule.Colors.CloseRed

	task.wait(0.05)
	animateNotificationIn()
end

local function showGetDownButton()
	currentState = "being_carried"

	CarryConfig.debugPrint("UI", "Show get down button")

	hideAllFrames()
	task.wait(0.05)
	animateGetDownIn()

	if not jumpBlockConn then
		jumpBlockConn = trackConnection(UserInputService.JumpRequest:Connect(function()
			local hum = getHumanoid()
			if hum then hum.Jump = false end
		end))
	end
end

local function hideGetDownButton()
	animateGetDownOut()

	if jumpBlockConn then
		jumpBlockConn:Disconnect()
		jumpBlockConn = nil
	end
end

local function handleStyleSelection(styleName)
	CarryConfig.debugPrint("UI", "=== STYLE SELECTED ===")
	CarryConfig.debugPrint("UI", "Style:", styleName)

	if currentState ~= "selecting_style" or not selectedTarget then
		CarryConfig.debugPrint("UI", "Cannot select style - wrong state or no target")
		return
	end

	if not CarryConfig.isValidStyle(styleName) then
		warn("[Gendong UI] Gaya tidak valid:", styleName)
		return
	end

	local segment = segmentButtons[styleName]
	if segment then
		TweenService:Create(segment.iconBg, TweenInfo.new(0.1), {
			BackgroundColor3 = Theme.SegmentSelected
		}):Play()

		highlightDividers(segment.index, true)
	end

	task.wait(0.15)

	animateMenuClose()

	RequestRemote:FireServer({
		cmd = "RequestCarry",
		targetId = selectedTarget.UserId,
		style = styleName
	})

	currentState = "waiting"
	CarryConfig.debugPrint("UI", "Request sent to server")
end

for styleId, segment in pairs(segmentButtons) do
	segment.button.MouseButton1Click:Connect(function()
		CarryConfig.debugPrint("UI", styleId, "button clicked")
		handleStyleSelection(styleId)
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	if currentState == "selecting_style" then
		animateMenuClose(function()
			cleanupState()
			currentState = "idle"
		end)
	end
end)

acceptBtn.MouseButton1Click:Connect(function()
	if currentState ~= "pending_response" or not pendingCarrier then
		return
	end

	CarryConfig.debugPrint("UI", "Accepted carry request")

	TweenService:Create(acceptBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = ThemeModule.Colors.ButtonPressedBg
	}):Play()

	task.wait(0.15)
	animateNotificationOut()

	ResponseRemote:FireServer({
		cmd = "AcceptCarry"
	})

	currentState = "waiting"
end)

rejectBtn.MouseButton1Click:Connect(function()
	if currentState ~= "pending_response" or not pendingCarrier then
		return
	end

	CarryConfig.debugPrint("UI", "Rejected carry request")

	TweenService:Create(rejectBtn, TweenInfo.new(0.1), {
		BackgroundColor3 = ThemeModule.Colors.ButtonPressedBg
	}):Play()

	task.wait(0.15)
	animateNotificationOut(function()
		cleanupState()
		currentState = "idle"
	end)

	ResponseRemote:FireServer({
		cmd = "RejectCarry"
	})
end)

acceptBtn.MouseEnter:Connect(function()
	TweenService:Create(acceptBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(225, 225, 225)
	}):Play()
end)
acceptBtn.MouseLeave:Connect(function()
	TweenService:Create(acceptBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = ThemeModule.Colors.ButtonPrimaryBg
	}):Play()
end)

rejectBtn.MouseEnter:Connect(function()
	TweenService:Create(rejectBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = ThemeModule.Colors.CloseRedHover
	}):Play()
end)
rejectBtn.MouseLeave:Connect(function()
	TweenService:Create(rejectBtn, TweenInfo.new(0.15), {
		BackgroundColor3 = ThemeModule.Colors.CloseRed
	}):Play()
end)

getDownBtn.MouseButton1Click:Connect(function()
	if currentState ~= "being_carried" and currentState ~= "carrying" then
		return
	end

	CarryConfig.debugPrint("UI", "Get down button clicked")

	hideGetDownButton()
	EndRemote:FireServer({})
	cleanupState()
	currentState = "idle"
end)

getDownBtn.MouseEnter:Connect(function()
	TweenService:Create(getDownBtn, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 190, 0, 54)
	}):Play()
end)
getDownBtn.MouseLeave:Connect(function()
	TweenService:Create(getDownBtn, TweenInfo.new(0.15), {
		Size = UDim2.new(0, 180, 0, 50)
	}):Play()
end)

RequestRemote.OnClientEvent:Connect(function(data)
	if not data or type(data) ~= "table" then return end

	local cmd = data.cmd
	CarryConfig.debugPrint("UI", "Received:", cmd)

	if cmd == "CarryStarted" then
		currentState = "carrying"
		animateGetDownIn()
		playAnimation(data.style, "carrier")

	elseif cmd == "BeingCarried" then
		showGetDownButton()
		playAnimation(data.style, "carried")

	elseif cmd == "RequestExpired" then
		animateMenuClose(function()
			cleanupState()
			currentState = "idle"
		end)

	elseif cmd == "RequestFailed" then
		animateMenuClose(function()
			cleanupState()
			currentState = "idle"
		end)

	elseif cmd == "RequestRejected" then
		cleanupState()
		currentState = "idle"
	end
end)

ResponseRemote.OnClientEvent:Connect(function(data)
	if not data or type(data) ~= "table" then return end

	local cmd = data.cmd
	CarryConfig.debugPrint("UI", "Received:", cmd)

	if cmd == "ShowRequest" then
		showCarryNotification(data.carrierId, data.carrierName, data.style)

	elseif cmd == "RequestExpired" then
		animateNotificationOut(function()
			cleanupState()
			currentState = "idle"
		end)

	elseif cmd == "CarryFailed" then
		animateNotificationOut(function()
			cleanupState()
			currentState = "idle"
		end)
	end
end)

EndRemote.OnClientEvent:Connect(function(data)
	if not data or type(data) ~= "table" then return end

	local cmd = data.cmd
	CarryConfig.debugPrint("UI", "Received:", cmd)

	if cmd == "CarryEnded" then
		hideGetDownButton()
		hideAllFrames()
		cleanupState()
		currentState = "idle"
	end
end)

local carryEventConnection = nil

local function setupCarryEventListener()
	local eventsFolder = ReplicatedStorage:FindFirstChild("CarryEvents")

	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "CarryEvents"
		eventsFolder.Parent = ReplicatedStorage
	end

	local showUIEvent = eventsFolder:FindFirstChild("ShowStyleUI")

	if not showUIEvent then
		showUIEvent = Instance.new("BindableEvent")
		showUIEvent.Name = "ShowStyleUI"
		showUIEvent.Parent = eventsFolder
	end

	local connection = showUIEvent.Event:Connect(function(target)
		if not target or not target:IsA("Player") then
			warn("[Gendong UI] Target tidak valid diterima:", target)
			return
		end

		CarryConfig.debugPrint("UI", "=== ShowStyleUI EVENT RECEIVED ===")
		CarryConfig.debugPrint("UI", "Target:", target.Name)

		if currentState == "idle" or currentState == "selecting_style" then
			showStyleSelection(target)
		else
			if currentState == "waiting" then
				cleanupState()
				currentState = "idle"
				task.wait(0.1)
				showStyleSelection(target)
			end
		end
	end)

	trackConnection(connection)
	CarryConfig.debugPrint("UI", "Context menu integration connected")

	return connection
end

carryEventConnection = setupCarryEventListener()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Escape then
		if menuContainer.Visible and currentState == "selecting_style" then
			animateMenuClose(function()
				cleanupState()
				currentState = "idle"
			end)
		end
	end
end)

player.CharacterAdded:Connect(function()
	hideAllFrames()
	cleanupState()
	stopAllAnimations()
	currentState = "idle"

	if carryEventConnection then
		carryEventConnection:Disconnect()
	end

	task.wait(1)
	carryEventConnection = setupCarryEventListener()
	CarryConfig.debugPrint("UI", "Character respawned - listener reset")
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		for _, conn in ipairs(connections) do
			if conn and conn.Connected then
				conn:Disconnect()
			end
		end
		stopAllAnimations()
		cleanupState()

		if guiScaler then
			guiScaler:Destroy()
		end
	end
end)

gui.Destroying:Connect(function()
	if guiScaler then
		guiScaler:Destroy()
	end
end)

hideAllFrames()
CarryConfig.debugPrint("UI", "✅ Antarmuka Gendong Siap (Skala Otomatis)")
print("[CarryHandler] 🎮 Menu Radial Gendong Siap!")
print("  • Menggunakan ScreenGui:", gui.Name)
print("  • Sistem skala otomatis aktif")
print("  • Tombol tutup di bagian tengah")
print("  • Garis pemisah antar gaya")
print("  • Info popup hover aktif")
print("  • Skala saat ini:", getCurrentScale())
