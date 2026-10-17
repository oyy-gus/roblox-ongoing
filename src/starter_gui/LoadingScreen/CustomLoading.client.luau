local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GROUP_ID = 550072302
local LOADING_TIME = 4.2

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	StarterGui:SetCore("TopbarEnabled", false)
end)

task.spawn(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	hum.WalkSpeed = 0
	hum.JumpPower = 0
end)

local gui = script.Parent
if gui:IsA("ScreenGui") then
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10000
end
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Name = "LoadingBackground"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromHex("#030306")
bg.BorderSizePixel = 0
bg.Parent = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#0B0C16")),
	ColorSequenceKeypoint.new(0.45, Color3.fromHex("#05060A")),
	ColorSequenceKeypoint.new(0.75, Color3.fromHex("#080912")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#020204")),
})
bgGrad.Rotation = 135
bgGrad.Parent = bg

local topVignette = Instance.new("Frame")
topVignette.Name = "TopVignette"
topVignette.Size = UDim2.new(1, 0, 0, 120)
topVignette.Position = UDim2.new(0, 0, 0, 0)
topVignette.BackgroundColor3 = Color3.fromHex("#000000")
topVignette.BorderSizePixel = 0
topVignette.Parent = bg

local topVigGrad = Instance.new("UIGradient")
topVigGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
topVigGrad.Rotation = 90
topVigGrad.Parent = topVignette

local botVignette = Instance.new("Frame")
botVignette.Name = "BottomVignette"
botVignette.Size = UDim2.new(1, 0, 0, 120)
botVignette.Position = UDim2.new(0, 0, 1, -120)
botVignette.BackgroundColor3 = Color3.fromHex("#000000")
botVignette.BorderSizePixel = 0
botVignette.Parent = bg

local botVigGrad = Instance.new("UIGradient")
botVigGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.3),
})
botVigGrad.Rotation = 90
botVigGrad.Parent = botVignette

local particleContainer = Instance.new("Frame")
particleContainer.Name = "Particles"
particleContainer.Size = UDim2.new(1, 0, 1, 0)
particleContainer.BackgroundTransparency = 1
particleContainer.ClipsDescendants = true
particleContainer.Parent = bg

local particles = {}
for i = 1, 28 do
	local p = Instance.new("Frame")
	local sz = math.random(2, 5)
	p.Size = UDim2.new(0, sz, 0, sz)
	p.Position = UDim2.new(math.random() * 0.94 + 0.03, 0, math.random() * 0.94 + 0.03, 0)
	p.BackgroundColor3 = (i % 3 == 0) and Color3.fromHex("#CBD5E1") or Color3.fromHex("#FFFFFF")
	p.BackgroundTransparency = math.random(70, 90) / 100
	p.BorderSizePixel = 0
	p.Parent = particleContainer
	Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
	table.insert(particles, {
		frame = p,
		speed = math.random(12, 32) / 10,
		baseX = p.Position.X.Scale,
		baseAlpha = p.BackgroundTransparency,
		phase = math.random() * math.pi * 2,
	})
end

local glowOrb1 = Instance.new("Frame")
glowOrb1.Size = UDim2.new(0, 520, 0, 520)
glowOrb1.Position = UDim2.new(0.12, 0, 0.15, 0)
glowOrb1.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb1.BackgroundColor3 = Color3.fromHex("#1E2540")
glowOrb1.BackgroundTransparency = 0.94
glowOrb1.BorderSizePixel = 0
glowOrb1.Parent = bg
Instance.new("UICorner", glowOrb1).CornerRadius = UDim.new(1, 0)

local glowOrb2 = Instance.new("Frame")
glowOrb2.Size = UDim2.new(0, 480, 0, 480)
glowOrb2.Position = UDim2.new(0.88, 0, 0.85, 0)
glowOrb2.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb2.BackgroundColor3 = Color3.fromHex("#261E38")
glowOrb2.BackgroundTransparency = 0.94
glowOrb2.BorderSizePixel = 0
glowOrb2.Parent = bg
Instance.new("UICorner", glowOrb2).CornerRadius = UDim.new(1, 0)

local centerCard = Instance.new("Frame")
centerCard.Name = "CenterCard"
centerCard.Size = UDim2.new(0, 560, 0, 325)
centerCard.Position = UDim2.new(0.5, 0, 0.5, 0)
centerCard.AnchorPoint = Vector2.new(0.5, 0.5)
centerCard.BackgroundColor3 = Color3.fromHex("#080910")
centerCard.BackgroundTransparency = 0.08
centerCard.BorderSizePixel = 0
centerCard.ClipsDescendants = true
centerCard.Parent = gui

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(0, 24)
centerCorner.Parent = centerCard

local centerStroke = Instance.new("UIStroke")
centerStroke.Color = Color3.fromHex("#303448")
centerStroke.Thickness = 1.8
centerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
centerStroke.Parent = centerCard

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#1C1E2C")),
	ColorSequenceKeypoint.new(0.25, Color3.fromHex("#707898")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(0.75, Color3.fromHex("#707898")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#1C1E2C")),
})
strokeGrad.Rotation = 45
strokeGrad.Parent = centerStroke

local cardShine = Instance.new("Frame")
cardShine.Name = "ShineSweep"
cardShine.Size = UDim2.new(0.4, 0, 1.8, 0)
cardShine.Position = UDim2.new(-0.6, 0, -0.4, 0)
cardShine.BackgroundColor3 = Color3.fromHex("#FFFFFF")
cardShine.BackgroundTransparency = 0.94
cardShine.BorderSizePixel = 0
cardShine.ZIndex = 2
cardShine.Parent = centerCard

local shineGrad = Instance.new("UIGradient")
shineGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
shineGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.86),
	NumberSequenceKeypoint.new(1, 1),
})
shineGrad.Rotation = 25
shineGrad.Parent = cardShine

local function makeTechCorner(posX, posY, ancX, ancY)
	local tc = Instance.new("Frame")
	tc.Size = UDim2.new(0, 12, 0, 12)
	tc.Position = UDim2.new(posX, posX == 0 and 12 or -12, posY, posY == 0 and 12 or -12)
	tc.AnchorPoint = Vector2.new(ancX, ancY)
	tc.BackgroundTransparency = 1
	tc.ZIndex = 3
	tc.Parent = centerCard

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 3, 0, 3)
	dot.Position = UDim2.new(ancX, ancX == 0 and 0 or -3, ancY, ancY == 0 and 0 or -3)
	dot.BackgroundColor3 = Color3.fromHex("#8892B0")
	dot.BackgroundTransparency = 0.3
	dot.BorderSizePixel = 0
	dot.ZIndex = 3
	dot.Parent = tc
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end
makeTechCorner(0, 0, 0, 0)
makeTechCorner(1, 0, 1, 0)
makeTechCorner(0, 1, 0, 1)
makeTechCorner(1, 1, 1, 1)

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 220, 0, 26)
badge.Position = UDim2.new(0.5, 0, 0, 18)
badge.AnchorPoint = Vector2.new(0.5, 0)
badge.BackgroundColor3 = Color3.fromHex("#121422")
badge.BorderSizePixel = 0
badge.ZIndex = 3
badge.Parent = centerCard
Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = Color3.fromHex("#353A54")
badgeStroke.Thickness = 1
badgeStroke.Parent = badge

local badgeGrad = Instance.new("UIGradient")
badgeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#282C40")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#8A94B8")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#282C40")),
})
badgeGrad.Rotation = 0
badgeGrad.Parent = badgeStroke

local badgeText = Instance.new("TextLabel")
badgeText.Size = UDim2.new(1, 0, 1, 0)
badgeText.BackgroundTransparency = 1
badgeText.Text = "👑 ✦ MAXI STRONG VIP ✦ 👑"
badgeText.Font = Enum.Font.GothamBold
badgeText.TextSize = 10
badgeText.TextColor3 = Color3.fromHex("#E2E6F5")
badgeText.ZIndex = 4
badgeText.Parent = badge

local titleShadow = Instance.new("TextLabel")
titleShadow.Size = UDim2.new(1, -40, 0, 44)
titleShadow.Position = UDim2.new(0.5, 0, 0, 52)
titleShadow.AnchorPoint = Vector2.new(0.5, 0)
titleShadow.BackgroundTransparency = 1
titleShadow.Text = "MAXI STRONG"
titleShadow.Font = Enum.Font.GothamBlack
titleShadow.TextSize = 38
titleShadow.TextColor3 = Color3.fromHex("#000000")
titleShadow.TextTransparency = 0.5
titleShadow.ZIndex = 3
titleShadow.Parent = centerCard

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 44)
title.Position = UDim2.new(0.5, 0, 0, 50)
title.AnchorPoint = Vector2.new(0.5, 0)
title.BackgroundTransparency = 1
title.Text = "MAXI STRONG"
title.Font = Enum.Font.GothamBlack
title.TextSize = 38
title.TextColor3 = Color3.fromHex("#FFFFFF")
title.ZIndex = 4
title.Parent = centerCard

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#A2A8C0")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#8890AA")),
})
titleGrad.Rotation = 0
titleGrad.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 18)
subtitle.Position = UDim2.new(0.5, 0, 0, 96)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "PENGALAMAN ROLEPLAY & KOMUNITAS EKSKLUSIF"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromHex("#888EA6")
subtitle.ZIndex = 4
subtitle.Parent = centerCard

local waveBars = {}
local waveContainer = Instance.new("Frame")
waveContainer.Size = UDim2.new(0, 130, 0, 14)
waveContainer.Position = UDim2.new(0.5, 0, 0, 120)
waveContainer.AnchorPoint = Vector2.new(0.5, 0)
waveContainer.BackgroundTransparency = 1
waveContainer.ZIndex = 4
waveContainer.Parent = centerCard

for i = 1, 13 do
	local wb = Instance.new("Frame")
	wb.Size = UDim2.new(0, 4, 0, 6)
	wb.Position = UDim2.new(0, (i - 1) * 10 + 3, 0.5, 0)
	wb.AnchorPoint = Vector2.new(0, 0.5)
	wb.BackgroundColor3 = Color3.fromHex("#8A94BA")
	wb.BorderSizePixel = 0
	wb.ZIndex = 4
	wb.Parent = waveContainer
	Instance.new("UICorner", wb).CornerRadius = UDim.new(1, 0)
	table.insert(waveBars, wb)
end

local barContainer = Instance.new("Frame")
barContainer.Size = UDim2.new(1, -70, 0, 9)
barContainer.Position = UDim2.new(0.5, 0, 0, 144)
barContainer.AnchorPoint = Vector2.new(0.5, 0)
barContainer.BackgroundColor3 = Color3.fromHex("#10121D")
barContainer.BorderSizePixel = 0
barContainer.ZIndex = 4
barContainer.Parent = centerCard
Instance.new("UICorner", barContainer).CornerRadius = UDim.new(1, 0)

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromHex("#282D42")
barStroke.Thickness = 1
barStroke.Parent = barContainer

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromHex("#FFFFFF")
barFill.BorderSizePixel = 0
barFill.ZIndex = 5
barFill.Parent = barContainer
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#5A6588")),
	ColorSequenceKeypoint.new(0.7, Color3.fromHex("#C8D2E8")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
fillGrad.Parent = barFill

local glowTipHalo = Instance.new("Frame")
glowTipHalo.Size = UDim2.new(0, 18, 0, 18)
glowTipHalo.Position = UDim2.new(1, 0, 0.5, 0)
glowTipHalo.AnchorPoint = Vector2.new(0.5, 0.5)
glowTipHalo.BackgroundColor3 = Color3.fromHex("#FFFFFF")
glowTipHalo.BackgroundTransparency = 0.75
glowTipHalo.BorderSizePixel = 0
glowTipHalo.ZIndex = 5
glowTipHalo.Parent = barFill
Instance.new("UICorner", glowTipHalo).CornerRadius = UDim.new(1, 0)

local glowTip = Instance.new("Frame")
glowTip.Size = UDim2.new(0, 8, 0, 8)
glowTip.Position = UDim2.new(1, 0, 0.5, 0)
glowTip.AnchorPoint = Vector2.new(0.5, 0.5)
glowTip.BackgroundColor3 = Color3.fromHex("#FFFFFF")
glowTip.BorderSizePixel = 0
glowTip.ZIndex = 6
glowTip.Parent = barFill
Instance.new("UICorner", glowTip).CornerRadius = UDim.new(1, 0)

local infoRow = Instance.new("Frame")
infoRow.Size = UDim2.new(1, -70, 0, 22)
infoRow.Position = UDim2.new(0.5, 0, 0, 162)
infoRow.AnchorPoint = Vector2.new(0.5, 0)
infoRow.BackgroundTransparency = 1
infoRow.ZIndex = 4
infoRow.Parent = centerCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -70, 1, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "[1/5] Inisialisasi sistem lingkungan & grafis..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromHex("#A4ACC6")
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.ZIndex = 4
statusLabel.Parent = infoRow

local percentBadge = Instance.new("Frame")
percentBadge.Size = UDim2.new(0, 56, 0, 20)
percentBadge.Position = UDim2.new(1, 0, 0.5, 0)
percentBadge.AnchorPoint = Vector2.new(1, 0.5)
percentBadge.BackgroundColor3 = Color3.fromHex("#141726")
percentBadge.BorderSizePixel = 0
percentBadge.ZIndex = 4
percentBadge.Parent = infoRow
Instance.new("UICorner", percentBadge).CornerRadius = UDim.new(0, 6)

local percentStroke = Instance.new("UIStroke")
percentStroke.Color = Color3.fromHex("#2C324A")
percentStroke.Thickness = 1
percentStroke.Parent = percentBadge

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 12
percentLabel.TextColor3 = Color3.fromHex("#FFFFFF")
percentLabel.TextXAlignment = Enum.TextXAlignment.Center
percentLabel.TextYAlignment = Enum.TextYAlignment.Center
percentLabel.ZIndex = 5
percentLabel.Parent = percentBadge

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -70, 0, 1)
divider.Position = UDim2.new(0.5, 0, 0, 196)
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.BackgroundColor3 = Color3.fromHex("#1C2030")
divider.BorderSizePixel = 0
divider.ZIndex = 4
divider.Parent = centerCard

local metaLabel = Instance.new("TextLabel")
metaLabel.Size = UDim2.new(1, -70, 0, 16)
metaLabel.Position = UDim2.new(0.5, 0, 0, 204)
metaLabel.AnchorPoint = Vector2.new(0.5, 0)
metaLabel.BackgroundTransparency = 1
metaLabel.Text = "SERVER VIP-01 • ENGINE v3.4 • STATUS: STABIL"
metaLabel.Font = Enum.Font.GothamMedium
metaLabel.TextSize = 9
metaLabel.TextColor3 = Color3.fromHex("#606884")
metaLabel.TextXAlignment = Enum.TextXAlignment.Center
metaLabel.ZIndex = 4
metaLabel.Parent = centerCard

local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(0, 310, 0, 36)
skipButton.Position = UDim2.new(0.5, 0, 0, 240)
skipButton.AnchorPoint = Vector2.new(0.5, 0)
skipButton.BackgroundColor3 = Color3.fromHex("#161A2B")
skipButton.BackgroundTransparency = 1
skipButton.BorderSizePixel = 0
skipButton.Visible = false
skipButton.Text = "✦ TEKAN SPASI / KETUK UNTUK LEWATI ✦"
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 11
skipButton.TextColor3 = Color3.fromHex("#D8DEFA")
skipButton.TextTransparency = 1
skipButton.AutoButtonColor = false
skipButton.ZIndex = 5
skipButton.Parent = centerCard
Instance.new("UICorner", skipButton).CornerRadius = UDim.new(1, 0)

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = Color3.fromHex("#3E4668")
skipStroke.Thickness = 1.2
skipStroke.Transparency = 1
skipStroke.Parent = skipButton

local skipGrad = Instance.new("UIGradient")
skipGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#282E48")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#A0ACDA")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#282E48")),
})
skipGrad.Rotation = 0
skipGrad.Parent = skipStroke

local isLoading = true
local canSkip = false
local hasPromptedGroup = false

local groupJoinedRemote = ReplicatedStorage:WaitForChild("GroupJoined", 5)
if not groupJoinedRemote then
	task.wait(1)
	groupJoinedRemote = ReplicatedStorage:FindFirstChild("GroupJoined")
end

local function notifyGroupStatus()
	if groupJoinedRemote then
		groupJoinedRemote:FireServer()
		print("[CustomLoading] Memberitahu server status grup")
	end
end

task.spawn(function()
	while isLoading do
		TweenService:Create(cardShine, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.new(1.4, 0, -0.4, 0)
		}):Play()
		task.wait(3.2)
		if not isLoading then break end
		cardShine.Position = UDim2.new(-0.6, 0, -0.4, 0)
	end
end)

local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(function(dt)
	if not isLoading then
		if heartbeatConn then heartbeatConn:Disconnect() end
		return
	end
	local t = os.clock()
	local offset = math.sin(t * 1.8) * 0.5
	strokeGrad.Offset = Vector2.new(offset, 0)
	titleGrad.Offset = Vector2.new(math.sin(t * 1.2) * 0.45, 0)
	badgeGrad.Offset = Vector2.new(math.sin(t * 2.0) * 0.5, 0)
	skipGrad.Offset = Vector2.new(math.sin(t * 2.5) * 0.5, 0)

	local pulseScale = 1 + math.sin(t * 5) * 0.2
	glowTipHalo.Size = UDim2.new(0, 18 * pulseScale, 0, 18 * pulseScale)
	glowTipHalo.BackgroundTransparency = 0.70 + math.sin(t * 5) * 0.15

	for i, wb in ipairs(waveBars) do
		local centerDist = math.abs(i - 7)
		local baseHeight = 12 - (centerDist * 1.2)
		local h = math.clamp(math.sin(t * 4.5 + i * 0.55) * 4 + baseHeight, 3, 14)
		wb.Size = UDim2.new(0, 4, 0, h)
	end

	for _, pt in ipairs(particles) do
		local f = pt.frame
		local curY = f.Position.Y.Scale - (pt.speed * dt * 0.035)
		if curY < -0.05 then
			curY = 1.05
			pt.baseX = math.random() * 0.94 + 0.03
		end
		local curX = pt.baseX + math.sin(t * 1.4 + pt.phase) * 0.012
		f.Position = UDim2.new(curX, 0, curY, 0)
		f.BackgroundTransparency = math.clamp(pt.baseAlpha + math.sin(t * 2 + pt.phase) * 0.08, 0.6, 0.96)
	end

	local orb1Scale = 1 + math.sin(t * 0.8) * 0.06
	glowOrb1.Size = UDim2.new(0, 520 * orb1Scale, 0, 520 * orb1Scale)
	glowOrb1.BackgroundTransparency = 0.94 + math.sin(t * 0.8) * 0.02

	local orb2Scale = 1 + math.cos(t * 0.9) * 0.06
	glowOrb2.Size = UDim2.new(0, 480 * orb2Scale, 0, 480 * orb2Scale)
	glowOrb2.BackgroundTransparency = 0.94 + math.cos(t * 0.9) * 0.02
end)

local function restoreCoreGui()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.AvatarSwitcher, true)
		StarterGui:SetCore("TopbarEnabled", true)
	end)
end

local function finish()
	if not isLoading then return end
	isLoading = false

	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end

	local fade = TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, v in ipairs(gui:GetDescendants()) do
		if v:IsA("Frame") then
			TweenService:Create(v, fade, {BackgroundTransparency = 1}):Play()
		elseif v:IsA("TextLabel") or v:IsA("TextButton") then
			TweenService:Create(v, fade, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		elseif v:IsA("UIStroke") then
			TweenService:Create(v, fade, {Transparency = 1}):Play()
		end
	end

	TweenService:Create(centerCard, fade, {
		Size = UDim2.new(0, 580, 0, 340)
	}):Play()

	task.wait(0.65)

	restoreCoreGui()

	if player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
	end

	gui:Destroy()

	notifyGroupStatus()

	task.defer(function()
		if not hasPromptedGroup then
			local alreadyMember = false
			local checkSuccess, checkResult = pcall(function()
				return player:IsInGroupAsync(GROUP_ID)
			end)
			if checkSuccess then
				alreadyMember = checkResult
			end

			if not alreadyMember then
				hasPromptedGroup = true
				local success, result = pcall(function()
					return GroupService:PromptJoinAsync(GROUP_ID)
				end)

				if success then
					if result == Enum.GroupMembershipStatus.Joined then
						task.wait(1)
						notifyGroupStatus()
						print("[CustomLoading] Pemain bergabung, memperbarui overhead...")
					elseif result == Enum.GroupMembershipStatus.AlreadyMember then
						notifyGroupStatus()
					elseif result == Enum.GroupMembershipStatus.JoinRequestPending then
						print("[CustomLoading] Permintaan bergabung tertunda, menunggu persetujuan")
					elseif result == Enum.GroupMembershipStatus.None then
						print("[CustomLoading] Pemain menolak atau tidak memenuhi syarat")
					end
				else
					warn("[CustomLoading] PromptJoinAsync gagal:", result)
				end
			else
				notifyGroupStatus()
			end
		end
	end)
end

skipButton.MouseEnter:Connect(function()
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromHex("#22283E")
	}):Play()
	TweenService:Create(skipStroke, TweenInfo.new(0.2), {
		Color = Color3.fromHex("#6270A0")
	}):Play()
end)

skipButton.MouseLeave:Connect(function()
	TweenService:Create(skipButton, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromHex("#161A2B")
	}):Play()
	TweenService:Create(skipStroke, TweenInfo.new(0.2), {
		Color = Color3.fromHex("#3E4668")
	}):Play()
end)

skipButton.MouseButton1Click:Connect(function()
	if canSkip then
		finish()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if canSkip then
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.Space then
			finish()
		end
	end
end)

local statusMessages = {
	{ progress = 0, text = "[1/5] Inisialisasi sistem lingkungan & grafis..." },
	{ progress = 22, text = "[2/5] Memuat sinkronisasi audio spasial server..." },
	{ progress = 48, text = "[3/5] Mengunduh modul peran VIP & interaksi khusus..." },
	{ progress = 72, text = "[4/5] Mempersiapkan karakter & avatar eksklusif..." },
	{ progress = 92, text = "[5/5] Sinkronisasi selesai! Selamat datang di Maxi Strong..." },
}

task.spawn(function()
	local currentMsgIdx = 1
	for i = 1, 100 do
		if not isLoading then break end
		TweenService:Create(barFill, TweenInfo.new(0.08), {
			Size = UDim2.new(i / 100, 0, 1, 0)
		}):Play()
		percentLabel.Text = i .. "%"

		for idx = #statusMessages, 1, -1 do
			if i >= statusMessages[idx].progress then
				if currentMsgIdx ~= idx then
					currentMsgIdx = idx
					statusLabel.Text = statusMessages[idx].text
				end
				break
			end
		end

		if i == 45 and not canSkip then
			canSkip = true
			skipButton.Visible = true
			TweenService:Create(skipButton, TweenInfo.new(0.4), { BackgroundTransparency = 0.15, TextTransparency = 0 }):Play()
			TweenService:Create(skipStroke, TweenInfo.new(0.4), { Transparency = 0 }):Play()
		end

		task.wait(LOADING_TIME / 100)
	end
	finish()
end)
