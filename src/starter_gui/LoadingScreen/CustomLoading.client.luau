local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local UIStrings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStrings"))

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
UIStrings.EnforceContainer(gui)

local bg = Instance.new("Frame")
bg.Name = "CinematicBackground"
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromHex("#020306")
bg.BorderSizePixel = 0
bg.Parent = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#0A0D18")),
	ColorSequenceKeypoint.new(0.4, Color3.fromHex("#04050A")),
	ColorSequenceKeypoint.new(0.7, Color3.fromHex("#080A14")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#020204")),
})
bgGrad.Rotation = 135
bgGrad.Parent = bg

local topVignette = Instance.new("Frame")
topVignette.Name = "TopVignette"
topVignette.Size = UDim2.new(1, 0, 0, 160)
topVignette.Position = UDim2.new(0, 0, 0, 0)
topVignette.BackgroundColor3 = Color3.fromHex("#000000")
topVignette.BorderSizePixel = 0
topVignette.Parent = bg

local topVigGrad = Instance.new("UIGradient")
topVigGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})
topVigGrad.Rotation = 90
topVigGrad.Parent = topVignette

local botVignette = Instance.new("Frame")
botVignette.Name = "BottomVignette"
botVignette.Size = UDim2.new(1, 0, 0, 200)
botVignette.Position = UDim2.new(0, 0, 1, -200)
botVignette.BackgroundColor3 = Color3.fromHex("#000000")
botVignette.BorderSizePixel = 0
botVignette.Parent = bg

local botVigGrad = Instance.new("UIGradient")
botVigGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.15),
})
botVigGrad.Rotation = 90
botVigGrad.Parent = botVignette

local gridOverlay = Instance.new("Frame")
gridOverlay.Name = "GridOverlay"
gridOverlay.Size = UDim2.new(1, 0, 1, 0)
gridOverlay.BackgroundColor3 = Color3.fromHex("#121828")
gridOverlay.BackgroundTransparency = 0.985
gridOverlay.BorderSizePixel = 0
gridOverlay.Parent = bg

local glowOrb1 = Instance.new("Frame")
glowOrb1.Size = UDim2.new(0, 640, 0, 640)
glowOrb1.Position = UDim2.new(0.1, 0, 0.12, 0)
glowOrb1.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb1.BackgroundColor3 = Color3.fromHex("#1C2642")
glowOrb1.BackgroundTransparency = 0.93
glowOrb1.BorderSizePixel = 0
glowOrb1.Parent = bg
Instance.new("UICorner", glowOrb1).CornerRadius = UDim.new(1, 0)

local glowOrb2 = Instance.new("Frame")
glowOrb2.Size = UDim2.new(0, 580, 0, 580)
glowOrb2.Position = UDim2.new(0.9, 0, 0.82, 0)
glowOrb2.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb2.BackgroundColor3 = Color3.fromHex("#261B38")
glowOrb2.BackgroundTransparency = 0.93
glowOrb2.BorderSizePixel = 0
glowOrb2.Parent = bg
Instance.new("UICorner", glowOrb2).CornerRadius = UDim.new(1, 0)

local particleContainer = Instance.new("Frame")
particleContainer.Name = "Particles"
particleContainer.Size = UDim2.new(1, 0, 1, 0)
particleContainer.BackgroundTransparency = 1
particleContainer.ClipsDescendants = true
particleContainer.Parent = bg

local particles = {}
for i = 1, 35 do
	local p = Instance.new("Frame")
	local sz = math.random(2, 5)
	p.Size = UDim2.new(0, sz, 0, sz)
	p.Position = UDim2.new(math.random() * 0.96 + 0.02, 0, math.random() * 0.96 + 0.02, 0)
	p.BackgroundColor3 = (i % 4 == 0) and Color3.fromHex("#CBD5E1") or Color3.fromHex("#FFFFFF")
	p.BackgroundTransparency = math.random(68, 88) / 100
	p.BorderSizePixel = 0
	p.Parent = particleContainer
	Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
	table.insert(particles, {
		frame = p,
		speed = math.random(14, 34) / 10,
		baseX = p.Position.X.Scale,
		baseAlpha = p.BackgroundTransparency,
		phase = math.random() * math.pi * 2,
	})
end

local lightRay = Instance.new("Frame")
lightRay.Name = "LightRaySweep"
lightRay.Size = UDim2.new(0.5, 0, 2.2, 0)
lightRay.Position = UDim2.new(-0.8, 0, -0.6, 0)
lightRay.BackgroundColor3 = Color3.fromHex("#FFFFFF")
lightRay.BackgroundTransparency = 0.965
lightRay.BorderSizePixel = 0
lightRay.ZIndex = 1
lightRay.Parent = bg

local rayGrad = Instance.new("UIGradient")
rayGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
rayGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.88),
	NumberSequenceKeypoint.new(1, 1),
})
rayGrad.Rotation = 35
rayGrad.Parent = lightRay

local centerStage = Instance.new("Frame")
centerStage.Name = "CenterStage"
centerStage.Size = UDim2.new(0, 720, 0, 260)
centerStage.Position = UDim2.new(0.5, 0, 0.44, 0)
centerStage.AnchorPoint = Vector2.new(0.5, 0.5)
centerStage.BackgroundTransparency = 1
centerStage.ZIndex = 5
centerStage.Parent = gui

local heroTitleGlow = Instance.new("TextLabel")
heroTitleGlow.Size = UDim2.new(1, 0, 0, 64)
heroTitleGlow.Position = UDim2.new(0.5, 0, 0, 26)
heroTitleGlow.AnchorPoint = Vector2.new(0.5, 0)
heroTitleGlow.BackgroundTransparency = 1
heroTitleGlow.Text = "ROYAL DREAM"
heroTitleGlow.Font = Enum.Font.GothamBlack
heroTitleGlow.TextSize = 54
heroTitleGlow.TextColor3 = Color3.fromHex("#4A5884")
heroTitleGlow.TextTransparency = 0.65
heroTitleGlow.ZIndex = 5
heroTitleGlow.Parent = centerStage
UIStrings.LockTextSize(heroTitleGlow, 54)

local heroTitle = Instance.new("TextLabel")
heroTitle.Size = UDim2.new(1, 0, 0, 64)
heroTitle.Position = UDim2.new(0.5, 0, 0, 24)
heroTitle.AnchorPoint = Vector2.new(0.5, 0)
heroTitle.BackgroundTransparency = 1
heroTitle.Text = "ROYAL DREAM"
heroTitle.Font = Enum.Font.GothamBlack
heroTitle.TextSize = 54
heroTitle.TextColor3 = Color3.fromHex("#FFFFFF")
heroTitle.ZIndex = 6
heroTitle.Parent = centerStage
UIStrings.LockTextSize(heroTitle, 54)

local heroTitleGrad = Instance.new("UIGradient")
heroTitleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#94A3B8")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#64748B")),
})
heroTitleGrad.Rotation = 0
heroTitleGrad.Parent = heroTitle

local heroSubtitle = Instance.new("TextLabel")
heroSubtitle.Size = UDim2.new(1, 0, 0, 22)
heroSubtitle.Position = UDim2.new(0.5, 0, 0, 92)
heroSubtitle.AnchorPoint = Vector2.new(0.5, 0)
heroSubtitle.BackgroundTransparency = 1
heroSubtitle.Text = "SELAMAT DATANG"
heroSubtitle.Font = Enum.Font.GothamBold
heroSubtitle.TextSize = UIStrings.TextSize.Caption
heroSubtitle.TextColor3 = Color3.fromHex("#94A3B8")
heroSubtitle.ZIndex = 6
heroSubtitle.Parent = centerStage
UIStrings.LockTextSize(heroSubtitle, UIStrings.TextSize.Caption)

local waveContainer = Instance.new("Frame")
waveContainer.Size = UDim2.new(0, 180, 0, 18)
waveContainer.Position = UDim2.new(0.5, 0, 0, 124)
waveContainer.AnchorPoint = Vector2.new(0.5, 0)
waveContainer.BackgroundTransparency = 1
waveContainer.ZIndex = 6
waveContainer.Parent = centerStage

local waveBars = {}
for i = 1, 17 do
	local wb = Instance.new("Frame")
	wb.Size = UDim2.new(0, 4, 0, 8)
	wb.Position = UDim2.new(0, (i - 1) * 11, 0.5, 0)
	wb.AnchorPoint = Vector2.new(0, 0.5)
	wb.BackgroundColor3 = Color3.fromHex("#8492A6")
	wb.BorderSizePixel = 0
	wb.ZIndex = 6
	wb.Parent = waveContainer
	Instance.new("UICorner", wb).CornerRadius = UDim.new(1, 0)
	table.insert(waveBars, wb)
end

local bottomDock = Instance.new("Frame")
bottomDock.Name = "BottomDock"
bottomDock.Size = UDim2.new(0.86, 0, 0, 130)
bottomDock.Position = UDim2.new(0.5, 0, 0.92, 0)
bottomDock.AnchorPoint = Vector2.new(0.5, 1)
bottomDock.BackgroundTransparency = 1
bottomDock.ZIndex = 5
bottomDock.Parent = gui

local telemetryRow = Instance.new("Frame")
telemetryRow.Size = UDim2.new(1, 0, 0, 42)
telemetryRow.Position = UDim2.new(0, 0, 0, 0)
telemetryRow.BackgroundTransparency = 1
telemetryRow.ZIndex = 6
telemetryRow.Parent = bottomDock

local stageLabel = Instance.new("TextLabel")
stageLabel.Size = UDim2.new(0.65, 0, 0, 18)
stageLabel.Position = UDim2.new(0, 0, 0, 0)
stageLabel.BackgroundTransparency = 1
stageLabel.Text = "TAHAP 01 / 05 // INISIALISASI MESIN GRAFIS"
stageLabel.Font = Enum.Font.GothamBold
stageLabel.TextSize = UIStrings.TextSize.Caption
stageLabel.TextColor3 = Color3.fromHex("#64748B")
stageLabel.TextXAlignment = Enum.TextXAlignment.Left
stageLabel.ZIndex = 6
stageLabel.Parent = telemetryRow
UIStrings.LockTextSize(stageLabel, UIStrings.TextSize.Caption)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.75, 0, 0, 22)
statusLabel.Position = UDim2.new(0, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "[1/5] Inisialisasi sistem lingkungan & tata cahaya..."
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = UIStrings.TextSize.Body
statusLabel.TextColor3 = Color3.fromHex("#F1F5F9")
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 6
statusLabel.Parent = telemetryRow
UIStrings.LockTextSize(statusLabel, UIStrings.TextSize.Body)

local percentBox = Instance.new("Frame")
percentBox.Size = UDim2.new(0, 120, 1, 0)
percentBox.Position = UDim2.new(1, 0, 0, 0)
percentBox.AnchorPoint = Vector2.new(1, 0)
percentBox.BackgroundTransparency = 1
percentBox.ZIndex = 6
percentBox.Parent = telemetryRow

local percentNum = Instance.new("TextLabel")
percentNum.Size = UDim2.new(1, 0, 0, 24)
percentNum.Position = UDim2.new(1, 0, 0, 0)
percentNum.AnchorPoint = Vector2.new(1, 0)
percentNum.BackgroundTransparency = 1
percentNum.Text = "0%"
percentNum.Font = Enum.Font.GothamBlack
percentNum.TextSize = 24
percentNum.TextColor3 = Color3.fromHex("#FFFFFF")
percentNum.TextXAlignment = Enum.TextXAlignment.Right
percentNum.ZIndex = 6
percentNum.Parent = percentBox
UIStrings.LockTextSize(percentNum, 24)

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(1, 0, 0, 16)
percentLabel.Position = UDim2.new(1, 0, 0, 24)
percentLabel.AnchorPoint = Vector2.new(1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "STATUS MUAT"
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = UIStrings.TextSize.Caption
percentLabel.TextColor3 = Color3.fromHex("#64748B")
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.ZIndex = 6
percentLabel.Parent = percentBox
UIStrings.LockTextSize(percentLabel, UIStrings.TextSize.Caption)

local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.Size = UDim2.new(1, 0, 0, 6)
progressTrack.Position = UDim2.new(0, 0, 0, 48)
progressTrack.BackgroundColor3 = Color3.fromHex("#0E111C")
progressTrack.BorderSizePixel = 0
progressTrack.ZIndex = 6
progressTrack.Parent = bottomDock
Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

local trackStroke = Instance.new("UIStroke")
trackStroke.Color = Color3.fromHex("#22273C")
trackStroke.Thickness = 1
trackStroke.Parent = progressTrack

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromHex("#FFFFFF")
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 7
progressFill.Parent = progressTrack
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#475569")),
	ColorSequenceKeypoint.new(0.65, Color3.fromHex("#CBD5E1")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
fillGrad.Parent = progressFill

local glowHalo = Instance.new("Frame")
glowHalo.Size = UDim2.new(0, 22, 0, 22)
glowHalo.Position = UDim2.new(1, 0, 0.5, 0)
glowHalo.AnchorPoint = Vector2.new(0.5, 0.5)
glowHalo.BackgroundColor3 = Color3.fromHex("#FFFFFF")
glowHalo.BackgroundTransparency = 0.72
glowHalo.BorderSizePixel = 0
glowHalo.ZIndex = 7
glowHalo.Parent = progressFill
Instance.new("UICorner", glowHalo).CornerRadius = UDim.new(1, 0)

local glowBeacon = Instance.new("Frame")
glowBeacon.Size = UDim2.new(0, 8, 0, 8)
glowBeacon.Position = UDim2.new(1, 0, 0.5, 0)
glowBeacon.AnchorPoint = Vector2.new(0.5, 0.5)
glowBeacon.BackgroundColor3 = Color3.fromHex("#FFFFFF")
glowBeacon.BorderSizePixel = 0
glowBeacon.ZIndex = 8
glowBeacon.Parent = progressFill
Instance.new("UICorner", glowBeacon).CornerRadius = UDim.new(1, 0)

local footerRow = Instance.new("Frame")
footerRow.Size = UDim2.new(1, 0, 0, 48)
footerRow.Position = UDim2.new(0, 0, 0, 62)
footerRow.BackgroundTransparency = 1
footerRow.ZIndex = 6
footerRow.Parent = bottomDock

local tipLabel = Instance.new("TextLabel")
tipLabel.Size = UDim2.new(0.65, 0, 1, 0)
tipLabel.Position = UDim2.new(0, 0, 0, 0)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = "PETUNJUK: Tekan [M] untuk membuka Menu Utama atau jelajahi fitur VIP di bilah alat."
tipLabel.Font = Enum.Font.GothamMedium
tipLabel.TextSize = UIStrings.TextSize.Caption
tipLabel.TextColor3 = Color3.fromHex("#94A3B8")
tipLabel.TextXAlignment = Enum.TextXAlignment.Left
tipLabel.TextWrapped = true
tipLabel.ZIndex = 6
tipLabel.Parent = footerRow
UIStrings.LockTextSize(tipLabel, UIStrings.TextSize.Caption)

local skipNotice = Instance.new("TextLabel")
skipNotice.Name = "SkipNotice"
skipNotice.Size = UDim2.new(0.38, 0, 1, 0)
skipNotice.Position = UDim2.new(1, 0, 0.5, 0)
skipNotice.AnchorPoint = Vector2.new(1, 0.5)
skipNotice.BackgroundTransparency = 1
skipNotice.BorderSizePixel = 0
skipNotice.Visible = false
skipNotice.Text = "TEKAN SPASI / KETUK UNTUK LEWATI"
skipNotice.Font = Enum.Font.GothamMedium
skipNotice.TextSize = UIStrings.TextSize.Caption
skipNotice.TextColor3 = Color3.fromHex("#CBD5E1")
skipNotice.TextTransparency = 1
skipNotice.TextXAlignment = Enum.TextXAlignment.Right
skipNotice.ZIndex = 6
skipNotice.Parent = footerRow
UIStrings.LockTextSize(skipNotice, UIStrings.TextSize.Caption)

local isLoading = true
local canSkip = false
local hasPromptedGroup = false
local parallaxX = 0
local parallaxY = 0

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
		TweenService:Create(lightRay, TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.new(1.3, 0, -0.6, 0)
		}):Play()
		task.wait(4.8)
		if not isLoading then break end
		lightRay.Position = UDim2.new(-0.8, 0, -0.6, 0)
	end
end)

local subtitleList = {
	"SELAMAT DATANG DI TEMPAT BERKUMPULNYA PARA PECINTA MUSIK",
	"SATUKAN IRAMA, LEPASKAN PENAT, DAN CIPTAKAN KESERUAN BERSAMA",
	"TEMPATNYA BERSANTAI, MENIKMATI MUSIK, DAN BERBAGI KESERUAN TANPA BATAS",
	"NAIKKAN SEMANGATMU, IKUTI IRAMANYA, DAN NIKMATI SETIAP MOMEN",
	"SELAMAT BERSENANG-SENANG, SEMOGA SETIAP LAGU MEMBAWA KEBAHAGIAAN",
	"BIARKAN MUSIK BERBICARA, BIARKAN IRAMA MENYATUKAN KITA",
}
task.spawn(function()
	local currentSubIdx = 1
	heroSubtitle.Text = subtitleList[1]
	heroSubtitle.TextTransparency = 0

	while isLoading do
		task.wait(1.2)
		if not isLoading then break end

		local fadeOut = TweenService:Create(heroSubtitle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			Position = UDim2.new(0.5, 0, 0, 87)
		})
		fadeOut:Play()
		fadeOut.Completed:Wait()

		if not isLoading then break end

		currentSubIdx = (currentSubIdx % #subtitleList) + 1
		heroSubtitle.Text = subtitleList[currentSubIdx]
		heroSubtitle.Position = UDim2.new(0.5, 0, 0, 97)

		local fadeIn = TweenService:Create(heroSubtitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			Position = UDim2.new(0.5, 0, 0, 92)
		})
		fadeIn:Play()
	end
end)

local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(function(dt)
	if not isLoading then
		if heartbeatConn then heartbeatConn:Disconnect() end
		return
	end
	local t = os.clock()

	heroTitleGrad.Offset = Vector2.new(math.sin(t * 1.4) * 0.45, 0)

	local pulseScale = 1 + math.sin(t * 5.5) * 0.22
	glowHalo.Size = UDim2.new(0, 22 * pulseScale, 0, 22 * pulseScale)
	glowHalo.BackgroundTransparency = 0.72 + math.sin(t * 5.5) * 0.12

	local okSound, serverSound = pcall(function()
		return SoundService:FindFirstChild("ServerMusicSound") or workspace:FindFirstChild("ServerMusicSound", true)
	end)
	local soundLoudness = 0
	if okSound and serverSound and serverSound.IsPlaying then
		pcall(function() soundLoudness = serverSound.PlaybackLoudness end)
	end
	local soundBoost = math.clamp(soundLoudness / 220, 0, 1.2)

	for i, wb in ipairs(waveBars) do
		local centerDist = math.abs(i - 9)
		local baseHeight = 14 - (centerDist * 1.1)
		local h = math.clamp((math.sin(t * 4.8 + i * 0.52) * 5 + baseHeight) * (1 + soundBoost * 0.6), 3, 18)
		wb.Size = UDim2.new(0, 4, 0, h)
	end

	for _, pt in ipairs(particles) do
		local f = pt.frame
		local curY = f.Position.Y.Scale - (pt.speed * dt * 0.032)
		if curY < -0.05 then
			curY = 1.05
			pt.baseX = math.random() * 0.96 + 0.02
		end
		local curX = pt.baseX + math.sin(t * 1.5 + pt.phase) * 0.012
		f.Position = UDim2.new(curX, 0, curY, 0)
		f.BackgroundTransparency = math.clamp(pt.baseAlpha + math.sin(t * 2.2 + pt.phase) * 0.08, 0.6, 0.95)
	end

	local orb1Scale = 1 + math.sin(t * 0.8) * 0.06
	glowOrb1.Size = UDim2.new(0, 640 * orb1Scale, 0, 640 * orb1Scale)
	glowOrb1.BackgroundTransparency = 0.93 + math.sin(t * 0.8) * 0.02

	local orb2Scale = 1 + math.cos(t * 0.9) * 0.06
	glowOrb2.Size = UDim2.new(0, 580 * orb2Scale, 0, 580 * orb2Scale)
	glowOrb2.BackgroundTransparency = 0.93 + math.cos(t * 0.9) * 0.02

	local mouse = UserInputService:GetMouseLocation()
	local vp = gui.AbsoluteSize
	if vp.X > 0 and vp.Y > 0 then
		local targetPxX = math.clamp((mouse.X - vp.X / 2) * 0.02, -20, 20)
		local targetPxY = math.clamp((mouse.Y - vp.Y / 2) * 0.02, -15, 15)
		parallaxX = parallaxX + (targetPxX - parallaxX) * math.clamp(dt * 4, 0, 1)
		parallaxY = parallaxY + (targetPxY - parallaxY) * math.clamp(dt * 4, 0, 1)
		centerStage.Position = UDim2.new(0.5, parallaxX, 0.44, parallaxY)
	end
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

	local fade = TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, v in ipairs(gui:GetDescendants()) do
		if v:IsA("Frame") then
			TweenService:Create(v, fade, {BackgroundTransparency = 1}):Play()
		elseif v:IsA("TextLabel") or v:IsA("TextButton") then
			TweenService:Create(v, fade, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
		elseif v:IsA("UIStroke") then
			TweenService:Create(v, fade, {Transparency = 1}):Play()
		end
	end

	TweenService:Create(centerStage, fade, {
		Position = UDim2.new(0.5, parallaxX, 0.40, parallaxY)
	}):Play()

	task.wait(0.7)

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

UserInputService.InputBegan:Connect(function(input)
	if canSkip then
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.Space then
			finish()
		end
	end
end)

local statusMessages = {
	{ progress = 0, stage = "TAHAP 01 / 05 // MESIN GRAFIS", text = "[1/5] Inisialisasi sistem lingkungan & tata cahaya..." },
	{ progress = 22, stage = "TAHAP 02 / 05 // AUDIO SPASIAL", text = "[2/5] Mengunduh paket audio spasial & soundtrack server..." },
	{ progress = 48, stage = "TAHAP 03 / 05 // MODUL VIP", text = "[3/5] Memuat konfigurasi peran VIP & interaksi khusus..." },
	{ progress = 72, stage = "TAHAP 04 / 05 // RENDER AVATAR", text = "[4/5] Mempersiapkan karakter & avatar eksklusif..." },
	{ progress = 92, stage = "TAHAP 05 / 05 // SINKRONISASI", text = "[5/5] Sinkronisasi jaringan selesai! Selamat menikmati..." },
}

local gameTips = {
	"PETUNJUK: Tekan [M] untuk membuka Menu Utama atau jelajahi fitur VIP di bilah alat.",
	"PETUNJUK: Berdonasi ke server akan menampilkan pesan kamu ke seluruh pemain di server!",
	"PETUNJUK: Jelajahi berbagai emote VIP eksklusif untuk mengekspresikan karakter kamu.",
	"PETUNJUK: Gunakan perintah VIP pada bilah alat untuk fitur-fitur spesial dan eksklusif.",
}

task.spawn(function()
	local currentMsgIdx = 1
	local tipIndex = 1

	for i = 1, 100 do
		if not isLoading then break end

		TweenService:Create(progressFill, TweenInfo.new(0.08), {
			Size = UDim2.new(i / 100, 0, 1, 0)
		}):Play()
		percentNum.Text = i .. "%"

		for idx = #statusMessages, 1, -1 do
			if i >= statusMessages[idx].progress then
				if currentMsgIdx ~= idx then
					currentMsgIdx = idx
					stageLabel.Text = statusMessages[idx].stage
					statusLabel.Text = statusMessages[idx].text
				end
				break
			end
		end

		if i % 25 == 0 then
			tipIndex = (tipIndex % #gameTips) + 1
			tipLabel.Text = gameTips[tipIndex]
		end

		if i == 40 and not canSkip then
			canSkip = true
			skipNotice.Visible = true
			TweenService:Create(skipNotice, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
		end

		task.wait(LOADING_TIME / 100)
	end
	finish()
end)
