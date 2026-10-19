local NotifModule = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThemeModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ThemeModule"))
local UIStrings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStrings"))

local CONFIG = {
	MaxNotifications = 5,
	Spacing = 8,
	Padding = 12,
	Width = 280,
	MinHeight = 56,
	IconSize = 22,
	SlideDistance = 40,
	AnimationDuration = 0.25,
	DefaultDuration = 3,
	CornerRadius = 8,
	BackgroundTransparency = 0.08,
	EnableSounds = true,
	SoundVolume = 0.4,
	ProgressBarHeight = 3,
	DisplayOrder = 2147483647,
}

local NOTIFICATION_TYPES = {
	Success = {
		Icon = "✓",
		PrimaryColor = Color3.fromHex("#4ADE80"),
		SoundId = "rbxassetid://6026984224",
	},
	Error = {
		Icon = "X",
		PrimaryColor = Color3.fromHex("#EF4444"),
		SoundId = "rbxassetid://5856649781",
	},
	Warning = {
		Icon = "!",
		PrimaryColor = Color3.fromHex("#F59E0B"),
		SoundId = "rbxassetid://9116840890",
	},
	Info = {
		Icon = "i",
		PrimaryColor = Color3.fromHex("#3B82F6"),
		SoundId = "rbxassetid://6026984224",
	},
	Settings = {
		Icon = "⚙",
		PrimaryColor = ThemeModule.Colors.TextGray,
		SoundId = "rbxassetid://139658322785649",
	},
	Notification = {
		Icon = "●",
		PrimaryColor = ThemeModule.Colors.Primary1,
		SoundId = "rbxassetid://6026984224",
	},
}

local notificationContainer = nil
local notificationScreenGui = nil
local activeNotifications = {}
local soundCache = {}
local monitorConnection = nil

local function ensureOnTop()
	if not notificationScreenGui or not notificationScreenGui.Parent then return end
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local highestOrder = 0
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= notificationScreenGui then
			if gui.DisplayOrder > highestOrder then
				highestOrder = gui.DisplayOrder
			end
		end
	end

	local targetOrder = math.max(highestOrder + 1000, CONFIG.DisplayOrder)
	if notificationScreenGui.DisplayOrder < targetOrder then
		notificationScreenGui.DisplayOrder = targetOrder
	end
end

local function startMonitoring()
	if monitorConnection then return end
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	monitorConnection = playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child ~= notificationScreenGui then
			task.wait(0.05)
			ensureOnTop()
		end
	end)
end

local function getScreenGui()
	local player = Players.LocalPlayer
	if not player then return nil end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return nil end

	local screenGui = playerGui:FindFirstChild("NotificationScreenGui")
	if screenGui then
		notificationScreenGui = screenGui
		ensureOnTop()
		return screenGui
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = CONFIG.DisplayOrder
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	notificationScreenGui = screenGui
	startMonitoring()
	ensureOnTop()

	return screenGui
end

local function createContainer()
	local screenGui = getScreenGui()
	if not screenGui then return nil end

	local existing = screenGui:FindFirstChild("NotificationContainer")
	if existing then return existing end

	local container = Instance.new("Frame")
	container.Name = "NotificationContainer"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -CONFIG.Padding, 1, -CONFIG.Padding)
	container.Size = UDim2.new(0, CONFIG.Width, 0.5, 0)
	container.ZIndex = 999999
	container.Parent = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, CONFIG.Spacing)
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.Parent = container

	return container
end

local function playSound(soundId)
	if not CONFIG.EnableSounds or not soundId then return end
	pcall(function()
		if not soundCache[soundId] then
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Volume = CONFIG.SoundVolume
			sound.Parent = SoundService
			soundCache[soundId] = sound
		end
		soundCache[soundId]:Stop()
		soundCache[soundId]:Play()
	end)
end

local function createNotifFrame(options)
	local notifType = NOTIFICATION_TYPES[options.Type] or NOTIFICATION_TYPES.Notification
	local primaryColor = options.Color or notifType.PrimaryColor

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Notification"
	mainFrame.Size = UDim2.new(1, 0, 0, CONFIG.MinHeight)
	mainFrame.AutomaticSize = Enum.AutomaticSize.Y
	mainFrame.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
	mainFrame.BackgroundTransparency = CONFIG.BackgroundTransparency
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.ZIndex = 999999

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
	mainCorner.Parent = mainFrame

	local stroke, strokeGrad = ThemeModule.CreateAnimatedStroke(mainFrame, 1, "Primary", 1.2)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, -12)
	accentBar.Position = UDim2.new(0, 4, 0, 6)
	accentBar.BackgroundColor3 = primaryColor
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 999999 + 1
	accentBar.Parent = mainFrame

	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
	local accentGrad = ThemeModule.CreateAnimatedGradient(accentBar, "Primary", 90, 1.2)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, CONFIG.IconSize, 0, CONFIG.IconSize)
	iconLabel.Position = UDim2.new(0, 14, 0, 10)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = options.Icon or notifType.Icon
	iconLabel.TextColor3 = primaryColor
	iconLabel.TextScaled = false
	iconLabel.TextSize = UIStrings.TextSize.Body
	iconLabel.Font = (ThemeModule.Fonts and ThemeModule.Fonts.BodyBold) or Enum.Font.GothamBold
	iconLabel.ZIndex = 999999 + 1
	iconLabel.Parent = mainFrame

	local textX = 14 + CONFIG.IconSize + 8
	local closeBtnSpace = 20

	local textContainer = Instance.new("Frame")
	textContainer.Name = "TextContainer"
	textContainer.Position = UDim2.new(0, textX, 0, 8)
	textContainer.Size = UDim2.new(1, -(textX + closeBtnSpace), 0, 0)
	textContainer.AutomaticSize = Enum.AutomaticSize.Y
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel = 0
	textContainer.ZIndex = 999999 + 1
	textContainer.Parent = mainFrame

	local textLayout = Instance.new("UIListLayout")
	textLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textLayout.Padding = UDim.new(0, 2)
	textLayout.Parent = textContainer

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y
	title.BackgroundTransparency = 1
	title.Text = options.Title or "Notifikasi"
	title.TextColor3 = ThemeModule.Colors.TextWhite
	title.TextScaled = false
	title.TextSize = UIStrings.TextSize.Body
	title.TextWrapped = true
	title.TextTruncate = Enum.TextTruncate.None
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = (ThemeModule.Fonts and ThemeModule.Fonts.Title) or Enum.Font.GothamBold
	title.ZIndex = 999999 + 1
	title.LayoutOrder = 1
	title.Parent = textContainer

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, 0, 0, 0)
	message.AutomaticSize = Enum.AutomaticSize.Y
	message.BackgroundTransparency = 1
	message.Text = options.Text or ""
	message.TextColor3 = ThemeModule.Colors.TextGray
	message.TextScaled = false
	message.TextSize = UIStrings.TextSize.Caption
	message.TextWrapped = true
	message.TextTruncate = Enum.TextTruncate.None
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.Font = (ThemeModule.Fonts and ThemeModule.Fonts.Body) or Enum.Font.Gotham
	message.ZIndex = 999999 + 1
	message.LayoutOrder = 2
	message.Parent = textContainer

	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1, 0, 0, 8)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = 3
	spacer.Parent = textContainer

	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -16, 0, CONFIG.ProgressBarHeight)
	progressBg.Position = UDim2.new(0, 8, 1, -(CONFIG.ProgressBarHeight + 3))
	progressBg.BackgroundColor3 = ThemeModule.Colors.BackgroundLight
	progressBg.BackgroundTransparency = 0.4
	progressBg.BorderSizePixel = 0
	progressBg.ZIndex = 999999 + 1
	progressBg.Parent = mainFrame

	Instance.new("UICorner", progressBg).CornerRadius = UDim.new(0, 1)

	local progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = primaryColor
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 999999 + 2
	progressFill.Parent = progressBg

	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 1)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 18, 0, 18)
	closeBtn.Position = UDim2.new(1, -22, 0, 5)
	closeBtn.BackgroundColor3 = ThemeModule.Colors.CloseRed
	closeBtn.BackgroundTransparency = 0
	closeBtn.Text = "x"
	closeBtn.TextColor3 = ThemeModule.Colors.TextWhite
	closeBtn.TextSize = 12
	closeBtn.Font = (ThemeModule.Fonts and ThemeModule.Fonts.BodyBold) or Enum.Font.GothamBold
	closeBtn.TextXAlignment = Enum.TextXAlignment.Center
	closeBtn.TextYAlignment = Enum.TextYAlignment.Center
	closeBtn.AutoButtonColor = false
	closeBtn.BorderSizePixel = 0
	closeBtn.ZIndex = 999999 + 3
	closeBtn.Parent = mainFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 4)
	closeBtnCorner.Parent = closeBtn

	local closePad = Instance.new("UIPadding")
	closePad.PaddingBottom = UDim.new(0, 2)
	closePad.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = ThemeModule.Colors.CloseRedHover,
		}):Play()
	end)

	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = ThemeModule.Colors.CloseRed,
		}):Play()
	end)

	return {
		frame = mainFrame,
		closeBtn = closeBtn,
		progressFill = progressFill,
		primaryColor = primaryColor,
		strokeGrad = strokeGrad,
		accentGrad = accentGrad,
	}
end

function NotifModule.Notify(options)
	if type(options) == "string" then
		options = { Text = options }
	end
	options = options or {}
	options.Type = options.Type or "Notification"
	options.Duration = options.Duration or CONFIG.DefaultDuration

	if not notificationContainer or not notificationContainer.Parent then
		notificationContainer = createContainer()
	end

	if not notificationContainer then
		pcall(function()
			game.StarterGui:SetCore("SendNotification", {
				Title = options.Title or "Notifikasi",
				Text = options.Text or "",
				Duration = options.Duration
			})
		end)
		return nil
	end

	ensureOnTop()

	if #activeNotifications >= CONFIG.MaxNotifications then
		local oldest = activeNotifications[1]
		if oldest then NotifModule.Dismiss(oldest) end
	end

	local notifData = createNotifFrame(options)
	notifData.frame.Parent = notificationContainer
	notifData.frame.Position = UDim2.new(0, CONFIG.SlideDistance, 0, 0)
	notifData.frame.BackgroundTransparency = 1

	table.insert(activeNotifications, notifData)

	local notifType = NOTIFICATION_TYPES[options.Type] or NOTIFICATION_TYPES.Notification
	playSound(notifType.SoundId)

	TweenService:Create(notifData.frame, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = CONFIG.BackgroundTransparency
	}):Play()

	if options.Duration > 0 then
		TweenService:Create(notifData.progressFill, TweenInfo.new(options.Duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		}):Play()
	end

	notifData.closeBtn.MouseButton1Click:Connect(function()
		NotifModule.Dismiss(notifData)
	end)

	if options.Duration > 0 then
		task.delay(options.Duration, function()
			NotifModule.Dismiss(notifData)
		end)
	end

	return notifData
end

function NotifModule.Dismiss(notifData)
	if not notifData or not notifData.frame or not notifData.frame.Parent then return end

	local tween = TweenService:Create(notifData.frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0, CONFIG.SlideDistance, 0, 0),
		BackgroundTransparency = 1
	})

	tween.Completed:Connect(function()
		if notifData.strokeGrad then
			ThemeModule.GradientSystem.Unregister(notifData.strokeGrad)
		end
		if notifData.accentGrad then
			ThemeModule.GradientSystem.Unregister(notifData.accentGrad)
		end
		pcall(function() notifData.frame:Destroy() end)
		for i, n in ipairs(activeNotifications) do
			if n == notifData then table.remove(activeNotifications, i) break end
		end
	end)

	tween:Play()
end

function NotifModule.DismissAll()
	for _, notif in ipairs(activeNotifications) do
		NotifModule.Dismiss(notif)
	end
end

function NotifModule.Success(title, text, duration)
	return NotifModule.Notify({ Type = "Success", Title = title, Text = text, Duration = duration })
end

function NotifModule.Error(title, text, duration)
	return NotifModule.Notify({ Type = "Error", Title = title, Text = text, Duration = duration })
end

function NotifModule.Warning(title, text, duration)
	return NotifModule.Notify({ Type = "Warning", Title = title, Text = text, Duration = duration })
end

function NotifModule.Info(title, text, duration)
	return NotifModule.Notify({ Type = "Info", Title = title, Text = text, Duration = duration })
end

function NotifModule.Settings(title, text, duration)
	return NotifModule.Notify({ Type = "Settings", Title = title, Text = text, Duration = duration or 2 })
end

function NotifModule.EnableSounds(enabled)
	CONFIG.EnableSounds = enabled
end

function NotifModule.ForceOnTop()
	ensureOnTop()
end

return NotifModule
