local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local GROUP_ID = 550072302
local LOADING_TIME = 5

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
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromHex("#080808")
bg.BorderSizePixel = 0
bg.Parent = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#141414")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#050505")),
})
bgGrad.Rotation = 45
bgGrad.Parent = bg

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.fromHex("#000000")
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Parent = gui

local center = Instance.new("Frame")
center.Size = UDim2.new(0,440,0,240)
center.Position = UDim2.new(0.5,0,0.5,0)
center.AnchorPoint = Vector2.new(0.5,0.5)
center.BackgroundColor3 = Color3.fromHex("#101010")
center.BackgroundTransparency = 0.25
center.BorderSizePixel = 0
center.Parent = gui

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(0, 16)
centerCorner.Parent = center

local centerStroke = Instance.new("UIStroke")
centerStroke.Color = Color3.fromHex("#282828")
centerStroke.Thickness = 1.2
centerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
centerStroke.Parent = center

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,46)
title.Position = UDim2.new(0,0,0,22)
title.BackgroundTransparency = 1
title.Text = "MAXI STRONG"
title.Font = Enum.Font.GothamBlack
title.TextSize = 34
title.TextColor3 = Color3.fromHex("#FFFFFF")
title.Parent = center

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1,0,0,16)
subtitle.Position = UDim2.new(0,0,0,68)
subtitle.BackgroundTransparency = 1
subtitle.Text = "COMMUNITY EXPERIENCE"
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 10
subtitle.TextColor3 = Color3.fromHex("#888888")
subtitle.Parent = center

local dotsFrame = Instance.new("Frame")
dotsFrame.Size = UDim2.new(0,80,0,16)
dotsFrame.Position = UDim2.new(0.5,0,0,96)
dotsFrame.AnchorPoint = Vector2.new(0.5,0)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Parent = center

local dots = {}
for i = 1,3 do
	local d = Instance.new("Frame")
	d.Size = UDim2.new(0,8,0,8)
	d.Position = UDim2.new(0,(i-1)*28 + 6,0.5,0)
	d.AnchorPoint = Vector2.new(0,0.5)
	d.BackgroundColor3 = Color3.fromHex("#555555")
	d.BorderSizePixel = 0
	d.Parent = dotsFrame
	Instance.new("UICorner", d).CornerRadius = UDim.new(1,0)
	table.insert(dots,d)
end

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1,-80,0,6)
barBg.Position = UDim2.new(0.5,0,0,130)
barBg.AnchorPoint = Vector2.new(0.5,0)
barBg.BackgroundColor3 = Color3.fromHex("#1C1C1C")
barBg.BorderSizePixel = 0
barBg.Parent = center
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromHex("#333333")
barStroke.Thickness = 1
barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
barStroke.Parent = barBg

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromHex("#FFFFFF")
bar.BorderSizePixel = 0
bar.Parent = barBg
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

local barGrad = Instance.new("UIGradient")
barGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#777777")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#FFFFFF")),
})
barGrad.Parent = bar

local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1,0,0,24)
percent.Position = UDim2.new(0,0,0,146)
percent.BackgroundTransparency = 1
percent.Font = Enum.Font.GothamBold
percent.TextSize = 18
percent.TextColor3 = Color3.fromHex("#FFFFFF")
percent.Text = "0%"
percent.Parent = center

local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1,0,0,20)
skipText.Position = UDim2.new(0,0,0,182)
skipText.BackgroundTransparency = 1
skipText.Font = Enum.Font.Gotham
skipText.TextSize = 12
skipText.TextColor3 = Color3.fromHex("#777777")
skipText.Text = ""
skipText.Parent = center

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
		for _,d in ipairs(dots) do
			if not isLoading then break end
			TweenService:Create(d, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0,8,0,16),
				BackgroundColor3 = Color3.fromHex("#FFFFFF")
			}):Play()
			task.wait(0.12)
			TweenService:Create(d, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0,8,0,8),
				BackgroundColor3 = Color3.fromHex("#555555")
			}):Play()
		end
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

	local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _,v in ipairs(gui:GetDescendants()) do
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

UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if canSkip then
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.Space then
			finish()
		end
	end
end)

task.spawn(function()
	for i = 1,100 do
		if not isLoading then break end
		TweenService:Create(bar, TweenInfo.new(0.1), {
			Size = UDim2.new(i/100,0,1,0)
		}):Play()
		percent.Text = i.."%"
		if i == 50 then
			canSkip = true
			skipText.Text = "Klik dimana saja atau Tekan Spasi untuk lewati"
		end
		task.wait(LOADING_TIME/100)
	end
	finish()
end)
