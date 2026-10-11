-- StarterGui > LoadingScreen > CustomLoading(LocalScript)
-- FINAL FULL LOADING + GROUP ASYNC + VERIFIED SIGNAL
-- =========================

-- SERVICES
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- CONFIG
local GROUP_ID = 550072302
local LOADING_TIME = 5

-- PLAYER
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- REMOVE DEFAULT LOADING
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- HIDE CORE GUI
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	StarterGui:SetCore("TopbarEnabled", false)
end)

-- FREEZE PLAYER
task.spawn(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	hum.WalkSpeed = 0
	hum.JumpPower = 0
end)

-- GUI ROOT
local gui = script.Parent
if gui:IsA("ScreenGui") then
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10000
end
gui.Parent = playerGui


-- BACKGROUND
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(15,15,20)
bg.BorderSizePixel = 0
bg.Parent = gui

-- OVERLAY
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.4
overlay.BorderSizePixel = 0
overlay.Parent = gui

-- CENTER
local center = Instance.new("Frame")
center.Size = UDim2.new(0,420,0,230)
center.Position = UDim2.new(0.5,0,0.5,0)
center.AnchorPoint = Vector2.new(0.5,0.5)
center.BackgroundTransparency = 1
center.Parent = gui

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,50)
title.BackgroundTransparency = 1
title.Text = "3F1 DANGDUT COMMUNITY"
title.Font = Enum.Font.GothamBold
title.TextSize = 34
title.TextColor3 = Color3.new(1,1,1)
title.Parent = center

-- DOTS
local dotsFrame = Instance.new("Frame")
dotsFrame.Size = UDim2.new(0,90,0,20)
dotsFrame.Position = UDim2.new(0.5,0,0,60)
dotsFrame.AnchorPoint = Vector2.new(0.5,0)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Parent = center

local dots = {}
for i = 1,3 do
	local d = Instance.new("Frame")
	d.Size = UDim2.new(0,12,0,12)
	d.Position = UDim2.new(0,(i-1)*30,0.5,0)
	d.AnchorPoint = Vector2.new(0,0.5)
	d.BackgroundColor3 = Color3.new(1,1,1)
	d.BorderSizePixel = 0
	d.Parent = dotsFrame
	Instance.new("UICorner", d).CornerRadius = UDim.new(1,0)
	table.insert(dots,d)
end

-- BAR BG
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1,0,0,8)
barBg.Position = UDim2.new(0,0,0,100)
barBg.BackgroundColor3 = Color3.fromRGB(50,50,60)
barBg.BorderSizePixel = 0
barBg.Parent = center
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

-- BAR
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromRGB(0,200,255)
bar.BorderSizePixel = 0
bar.Parent = barBg
Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

-- PERCENT
local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1,0,0,30)
percent.Position = UDim2.new(0,0,0,115)
percent.BackgroundTransparency = 1
percent.Font = Enum.Font.GothamBold
percent.TextSize = 22
percent.TextColor3 = Color3.new(1,1,1)
percent.Text = "0%"
percent.Parent = center

-- SKIP TEXT
local skipText = Instance.new("TextLabel")
skipText.Size = UDim2.new(1,0,0,24)
skipText.Position = UDim2.new(0,0,0,150)
skipText.BackgroundTransparency = 1
skipText.Font = Enum.Font.Gotham
skipText.TextSize = 15
skipText.TextColor3 = Color3.fromRGB(150,150,160)
skipText.Text = ""
skipText.Parent = center

-- STATE
local isLoading = true
local canSkip = false
local hasPromptedGroup = false

-- Get/Create GroupJoined remote
local groupJoinedRemote = ReplicatedStorage:WaitForChild("GroupJoined", 5)
if not groupJoinedRemote then
	task.wait(1)
	groupJoinedRemote = ReplicatedStorage:FindFirstChild("GroupJoined")
end

-- Function to notify server about group status
local function notifyGroupStatus()
	if groupJoinedRemote then
		groupJoinedRemote:FireServer()
		print("[CustomLoading] Notified server about group status")
	end
end

-- DOT ANIMATION
task.spawn(function()
	while isLoading do
		for _,d in ipairs(dots) do
			if not isLoading then break end
			TweenService:Create(d, TweenInfo.new(0.25), {
				Size = UDim2.new(0,12,0,24),
				BackgroundColor3 = Color3.fromRGB(0,200,255)
			}):Play()
			task.wait(0.12)
			TweenService:Create(d, TweenInfo.new(0.25), {
				Size = UDim2.new(0,12,0,12),
				BackgroundColor3 = Color3.new(1,1,1)
			}):Play()
		end
	end
end)

-- ====================================
-- RESTORE CORE GUI (TANPA BACKPACK)
-- ====================================
local function restoreCoreGui()
	pcall(function()
		-- Enable semua KECUALI Backpack
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.AvatarSwitcher, true)
		-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)  -- JANGAN enable Backpack - biarkan custom inventory handle

		-- Enable topbar
		StarterGui:SetCore("TopbarEnabled", true)
	end)
end

-- FINISH FUNCTION
local function finish()
	if not isLoading then return end
	isLoading = false

	local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _,v in ipairs(gui:GetDescendants()) do
		if v:IsA("Frame") then
			TweenService:Create(v, fade, {BackgroundTransparency = 1}):Play()
		elseif v:IsA("TextLabel") then
			TweenService:Create(v, fade, {TextTransparency = 1}):Play()
		end
	end

	task.wait(0.6)

	-- RESTORE GUI (tanpa Backpack)
	restoreCoreGui()

	-- RESTORE PLAYER
	if player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
	end

	gui:Destroy()

	-- Notify server about initial group status
	notifyGroupStatus()

	-- GROUP JOIN PROMPT (ASYNC)
	task.defer(function()
		if not hasPromptedGroup then
			-- Cek dulu apakah sudah member pakai IsInGroupAsync
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
						print("[CustomLoading] Player joined, updating overhead...")

					elseif result == Enum.GroupMembershipStatus.AlreadyMember then
						notifyGroupStatus()

					elseif result == Enum.GroupMembershipStatus.JoinRequestPending then
						print("[CustomLoading] Join request pending, waiting approval")

					elseif result == Enum.GroupMembershipStatus.None then
						print("[CustomLoading] Player declined atau tidak eligible")
					end
				else
					warn("[CustomLoading] PromptJoinAsync gagal:", result)
				end
			else
				-- Sudah member, tetap notify server buat update overhead
				notifyGroupStatus()
			end
		end
	end)
end

-- INPUT SKIP
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

-- LOADING BAR
task.spawn(function()
	for i = 1,100 do
		if not isLoading then break end
		TweenService:Create(bar, TweenInfo.new(0.1), {
			Size = UDim2.new(i/100,0,1,0)
		}):Play()
		percent.Text = i.."%"
		if i == 50 then
			canSkip = true
			skipText.Text = "Klik dimana saja/Klik spasi untuk lewati!"
		end
		task.wait(LOADING_TIME/100)
	end
	finish()
end)
