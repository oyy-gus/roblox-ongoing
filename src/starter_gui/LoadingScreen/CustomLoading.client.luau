local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GROUP_ID = 550072302
local LOADING_TIME = 4.5

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
bg.BackgroundColor3 = Color3.fromHex("#060608")
bg.BorderSizePixel = 0
bg.Parent = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#0E0E16")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#07070B")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#040406")),
})
bgGrad.Rotation = 135
bgGrad.Parent = bg

local glowOrb1 = Instance.new("Frame")
glowOrb1.Size = UDim2.new(0, 420, 0, 420)
glowOrb1.Position = UDim2.new(0.2, 0, 0.2, 0)
glowOrb1.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb1.BackgroundColor3 = Color3.fromHex("#FFFFFF")
glowOrb1.BackgroundTransparency = 0.96
glowOrb1.BorderSizePixel = 0
glowOrb1.Parent = bg
Instance.new("UICorner", glowOrb1).CornerRadius = UDim.new(1, 0)

local glowOrb2 = Instance.new("Frame")
glowOrb2.Size = UDim2.new(0, 360, 0, 360)
glowOrb2.Position = UDim2.new(0.8, 0, 0.8, 0)
glowOrb2.AnchorPoint = Vector2.new(0.5, 0.5)
glowOrb2.BackgroundColor3 = Color3.fromHex("#888888")
glowOrb2.BackgroundTransparency = 0.97
glowOrb2.BorderSizePixel = 0
glowOrb2.Parent = bg
Instance.new("UICorner", glowOrb2).CornerRadius = UDim.new(1, 0)

local centerCard = Instance.new("Frame")
centerCard.Name = "CenterCard"
centerCard.Size = UDim2.new(0, 480, 0, 260)
centerCard.Position = UDim2.new(0.5, 0, 0.5, 0)
centerCard.AnchorPoint = Vector2.new(0.5, 0.5)
centerCard.BackgroundColor3 = Color3.fromHex("#0D0D12")
centerCard.BackgroundTransparency = 0.15
centerCard.BorderSizePixel = 0
centerCard.ClipsDescendants = true
centerCard.Parent = gui

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(0, 20)
centerCorner.Parent = centerCard

local centerStroke = Instance.new("UIStroke")
centerStroke.Color = Color3.fromHex("#333342")
centerStroke.Thickness = 1.5
centerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
centerStroke.Parent = centerCard

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#222230")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#222230")),
})
strokeGrad.Rotation = 45
strokeGrad.Parent = centerStroke

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 180, 0, 24)
badge.Position = UDim2.new(0.5, 0, 0, 22)
badge.AnchorPoint = Vector2.new(0.5, 0)
badge.BackgroundColor3 = Color3.fromHex("#171722")
badge.BorderSizePixel = 0
badge.Parent = centerCard
Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = Color3.fromHex("#353548")
badgeStroke.Thickness = 1
badgeStroke.Parent = badge

local badgeText = Instance.new("TextLabel")
badgeText.Size = UDim2.new(1, 0, 1, 0)
badgeText.BackgroundTransparency = 1
badgeText.Text = "✦ PENGALAMAN RESMI ✦"
badgeText.Font = Enum.Font.GothamBold
badgeText.TextSize = 10
badgeText.TextColor3 = Color3.fromHex("#D0D0E0")
badgeText.Parent = badge

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 42)
title.Position = UDim2.new(0.5, 0, 0, 54)
title.AnchorPoint = Vector2.new(0.5, 0)
title.BackgroundTransparency = 1
title.Text = "MAXI STRONG"
title.Font = Enum.Font.GothamBlack
title.TextSize = 34
title.TextColor3 = Color3.fromHex("#FFFFFF")
title.Parent = centerCard

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#C0C0D0")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#A0A0B0")),
})
titleGrad.Rotation = 0
titleGrad.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 18)
subtitle.Position = UDim2.new(0.5, 0, 0, 96)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "KOMUNITAS & PENGALAMAN ROLEPLAY TERBAIK"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextColor3 = Color3.fromHex("#888899")
subtitle.Parent = centerCard

local barContainer = Instance.new("Frame")
barContainer.Size = UDim2.new(1, -80, 0, 8)
barContainer.Position = UDim2.new(0.5, 0, 0, 134)
barContainer.AnchorPoint = Vector2.new(0.5, 0)
barContainer.BackgroundColor3 = Color3.fromHex("#151520")
barContainer.BorderSizePixel = 0
barContainer.Parent = centerCard
Instance.new("UICorner", barContainer).CornerRadius = UDim.new(1, 0)

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromHex("#2C2C3C")
barStroke.Thickness = 1
barStroke.Parent = barContainer

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromHex("#FFFFFF")
barFill.BorderSizePixel = 0
barFill.Parent = barContainer
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#888899")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
fillGrad.Parent = barFill

local infoRow = Instance.new("Frame")
infoRow.Size = UDim2.new(1, -80, 0, 22)
infoRow.Position = UDim2.new(0.5, 0, 0, 150)
infoRow.AnchorPoint = Vector2.new(0.5, 0)
infoRow.BackgroundTransparency = 1
infoRow.Parent = centerCard

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -60, 1, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Menginisialisasi modul sistem..."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromHex("#A0A0B0")
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Parent = infoRow

local percentLabel = Instance.new("TextLabel")
percentLabel.Size = UDim2.new(0, 60, 1, 0)
percentLabel.Position = UDim2.new(1, 0, 0, 0)
percentLabel.AnchorPoint = Vector2.new(1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 13
percentLabel.TextColor3 = Color3.fromHex("#FFFFFF")
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.TextYAlignment = Enum.TextYAlignment.Center
percentLabel.Parent = infoRow

local skipContainer = Instance.new("Frame")
skipContainer.Size = UDim2.new(0, 280, 0, 30)
skipContainer.Position = UDim2.new(0.5, 0, 0, 195)
skipContainer.AnchorPoint = Vector2.new(0.5, 0)
skipContainer.BackgroundColor3 = Color3.fromHex("#171724")
skipContainer.BackgroundTransparency = 1
skipContainer.BorderSizePixel = 0
skipContainer.Visible = false
skipContainer.Parent = centerCard
Instance.new("UICorner", skipContainer).CornerRadius = UDim.new(1, 0)

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = Color3.fromHex("#333345")
skipStroke.Thickness = 1
skipStroke.Transparency = 1
skipStroke.Parent = skipContainer

local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1, 0, 1, 0)
skipText.BackgroundTransparency = 1
skipText.Font = Enum.Font.GothamMedium
skipText.TextSize = 11
skipText.TextColor3 = Color3.fromHex("#CCCCCC")
skipText.TextTransparency = 1
skipText.Text = "Tekan SPASI atau Ketuk Layar untuk Lewati ▶"
skipText.Parent = skipContainer

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

local heartbeatConn
heartbeatConn = RunService.Heartbeat:Connect(function()
	if not isLoading then
		if heartbeatConn then heartbeatConn:Disconnect() end
		return
	end
	local t = os.clock()
	local offset = math.sin(t * 1.8) * 0.5
	strokeGrad.Offset = Vector2.new(offset, 0)
	titleGrad.Offset = Vector2.new(math.sin(t * 1.2) * 0.4, 0)
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

	local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, v in ipairs(gui:GetDescendants()) do
		if v:IsA("Frame") then
			TweenService:Create(v, fade, {BackgroundTransparency = 1}):Play()
		elseif v:IsA("TextLabel") then
			TweenService:Create(v, fade, {TextTransparency = 1}):Play()
		elseif v:IsA("UIStroke") then
			TweenService:Create(v, fade, {Transparency = 1}):Play()
		end
	end

	task.wait(0.6)

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
	{ progress = 0, text = "Menginisialisasi modul sistem..." },
	{ progress = 22, text = "Memuat aset audio & visual..." },
	{ progress = 48, text = "Menghubungkan ke server roleplay..." },
	{ progress = 75, text = "Menyiapkan karakter & avatar..." },
	{ progress = 95, text = "Sinkronisasi selesai! Selamat datang..." },
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

		if i == 50 and not canSkip then
			canSkip = true
			skipContainer.Visible = true
			TweenService:Create(skipContainer, TweenInfo.new(0.35), { BackgroundTransparency = 0.2 }):Play()
			TweenService:Create(skipStroke, TweenInfo.new(0.35), { Transparency = 0 }):Play()
			TweenService:Create(skipText, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
		end

		task.wait(LOADING_TIME / 100)
	end
	finish()
end)
