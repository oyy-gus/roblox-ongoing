local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local SG = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = RS:WaitForChild("Modules")
local AdminConfig = require(Modules:WaitForChild("AdminConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))
local UIStrings = require(Modules:WaitForChild("UIStrings"))

AdminConfig.WaitForGUIReady()

local RemoteFolder = RS:WaitForChild("Message")
local CheckAccessRemote = RemoteFolder:WaitForChild("CheckAccess")
local SendMessageRemote = RemoteFolder:WaitForChild("SendMessage")
local ReceiveMessageRemote = RemoteFolder:WaitForChild("ReceiveMessage")

local Config = {
	Notification = {
		Duration = 6,
		MaxVisible = 3,
		Width = 340,
		MinHeight = 88,
		MaxHeight = 220,
		TopOffset = 12,
		Spacing = 6,
		Animation = {
			DropSpeed = 0.45,
			EasingStyle = Enum.EasingStyle.Back,
			EasingDirection = Enum.EasingDirection.Out,
			ExitSpeed = 0.25,
			ExitEasingStyle = Enum.EasingStyle.Quad,
			ExitEasingDirection = Enum.EasingDirection.In
		},
		Sound = {
			Enabled = true,
			SoundId = "rbxassetid://17208361335",
			Volume = 0.5,
			PlaybackSpeed = 1
		}
	},
	TextBox = {
		MaxLength = 200,
		Placeholder = "Type your message here..."
	}
}

local activeNotifications = {}
local notificationContainer = nil
local broadcastGUIElements = {}
local registeredGradients = {}

local sendBroadcastMessage
local clearTextBox

local function getTextHeight(text, font, textSize, maxWidth)
	local success, textBounds = pcall(function()
		return TextService:GetTextSize(text, textSize, font, Vector2.new(maxWidth, 1000))
	end)
	if success then
		return textBounds.Y
	end
	return 20
end

local function buildBroadcastGUI()
	local broadcastPage = AdminConfig.GUI.BroadcastPage
	if not broadcastPage then
		warn("[BroadcastClient] Halaman broadcast tidak ditemukan!")
		return
	end

	for _, child in ipairs(broadcastPage:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingTop = UDim.new(0, 16)
	mainPadding.PaddingBottom = UDim.new(0, 16)
	mainPadding.PaddingLeft = UDim.new(0, 16)
	mainPadding.PaddingRight = UDim.new(0, 16)
	mainPadding.Parent = broadcastPage

	local headerSection = Instance.new("Frame")
	headerSection.Name = "HeaderSection"
	headerSection.Size = UDim2.new(1, 0, 0, 50)
	headerSection.Position = UDim2.new(0, 0, 0, 0)
	headerSection.BackgroundTransparency = 1
	headerSection.Active = true
	headerSection.Parent = broadcastPage

	local headerIcon = Instance.new("TextLabel")
	headerIcon.Name = "HeaderIcon"
	headerIcon.Size = UDim2.new(0, 40, 0, 40)
	headerIcon.Position = UDim2.new(0, 0, 0.5, -20)
	headerIcon.BackgroundTransparency = 1
	headerIcon.Text = "📢"
	headerIcon.TextSize = 20
	headerIcon.Font = Enum.Font.GothamBold
	headerIcon.Parent = headerSection

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "HeaderTitle"
	headerTitle.Size = UDim2.new(1, -50, 0, 24)
	headerTitle.Position = UDim2.new(0, 50, 0, 4)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "Siaran Pesan"
	headerTitle.TextColor3 = ThemeModule.Colors.TextWhite
	headerTitle.TextSize = UIStrings.TextSize.Title
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = headerSection

	local headerSubtitle = Instance.new("TextLabel")
	headerSubtitle.Name = "HeaderSubtitle"
	headerSubtitle.Size = UDim2.new(1, -50, 0, 18)
	headerSubtitle.Position = UDim2.new(0, 50, 0, 28)
	headerSubtitle.BackgroundTransparency = 1
	headerSubtitle.Text = "Kirim pesan siaran ke semua pemain"
	headerSubtitle.TextColor3 = ThemeModule.Colors.TextGray
	headerSubtitle.TextSize = UIStrings.TextSize.Caption
	headerSubtitle.Font = Enum.Font.GothamMedium
	headerSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	headerSubtitle.Parent = headerSection

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 60)
	divider.BackgroundColor3 = ThemeModule.Colors.BackgroundLighter
	divider.BorderSizePixel = 0
	divider.Parent = broadcastPage

	local inputSection = Instance.new("Frame")
	inputSection.Name = "InputSection"
	inputSection.Size = UDim2.new(1, 0, 0, 140)
	inputSection.Position = UDim2.new(0, 0, 0, 75)
	inputSection.BackgroundTransparency = 1
	inputSection.Active = true
	inputSection.Parent = broadcastPage

	local inputLabel = Instance.new("TextLabel")
	inputLabel.Name = "InputLabel"
	inputLabel.Size = UDim2.new(1, 0, 0, 24)
	inputLabel.Position = UDim2.new(0, 0, 0, 0)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Text = "📝 Isi Pesan"
	inputLabel.TextColor3 = ThemeModule.Colors.TextWhite
	inputLabel.TextSize = UIStrings.TextSize.Title
	inputLabel.Font = Enum.Font.GothamBold
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.Parent = inputSection

	local textBoxContainer = Instance.new("Frame")
	textBoxContainer.Name = "TextBoxContainer"
	textBoxContainer.Size = UDim2.new(1, 0, 0, 100)
	textBoxContainer.Position = UDim2.new(0, 0, 0, 28)
	textBoxContainer.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
	textBoxContainer.BorderSizePixel = 0
	textBoxContainer.Parent = inputSection

	ThemeModule.CreateCorner(textBoxContainer, 8)

	local textBoxStroke = Instance.new("UIStroke")
	textBoxStroke.Color = ThemeModule.Colors.BackgroundLighter
	textBoxStroke.Thickness = 1
	textBoxStroke.Parent = textBoxContainer

	local textBox = Instance.new("TextBox")
	textBox.Name = "MessageTextBox"
	textBox.Size = UDim2.new(1, -20, 1, -20)
	textBox.Position = UDim2.new(0, 10, 0, 10)
	textBox.BackgroundTransparency = 1
	textBox.Text = ""
	textBox.PlaceholderText = Config.TextBox.Placeholder
	textBox.PlaceholderColor3 = ThemeModule.Colors.TextGray
	textBox.TextColor3 = ThemeModule.Colors.TextWhite
	textBox.TextSize = UIStrings.TextSize.Caption
	textBox.Font = Enum.Font.Gotham
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Top
	textBox.TextWrapped = true
	textBox.MultiLine = true
	textBox.ClearTextOnFocus = false
	textBox.Parent = textBoxContainer

	broadcastGUIElements.TextBox = textBox
	broadcastGUIElements.TextBoxContainer = textBoxContainer
	broadcastGUIElements.TextBoxStroke = textBoxStroke

	textBox.Focused:Connect(function()
		TS:Create(textBoxStroke, TweenInfo.new(0.2), {Color = ThemeModule.Colors.Primary1}):Play()
	end)

	textBox.FocusLost:Connect(function(enterPressed)
		TS:Create(textBoxStroke, TweenInfo.new(0.2), {Color = ThemeModule.Colors.BackgroundLighter}):Play()
		if enterPressed and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			sendBroadcastMessage()
		end
	end)

	local charCounter = Instance.new("TextLabel")
	charCounter.Name = "CharCounter"
	charCounter.Size = UDim2.new(0, 120, 0, 18)
	charCounter.Position = UDim2.new(1, -120, 0, 132)
	charCounter.BackgroundTransparency = 1
	charCounter.Text = "0/" .. Config.TextBox.MaxLength
	charCounter.TextColor3 = ThemeModule.Colors.TextGray
	charCounter.TextSize = UIStrings.TextSize.Caption
	charCounter.Font = Enum.Font.Gotham
	charCounter.TextXAlignment = Enum.TextXAlignment.Right
	charCounter.Parent = inputSection

	broadcastGUIElements.CharCounter = charCounter

	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local length = #textBox.Text
		charCounter.Text = length .. "/" .. Config.TextBox.MaxLength
		if length > Config.TextBox.MaxLength then
			charCounter.TextColor3 = ThemeModule.Colors.Error
			textBox.Text = string.sub(textBox.Text, 1, Config.TextBox.MaxLength)
		elseif length > Config.TextBox.MaxLength * 0.8 then
			charCounter.TextColor3 = ThemeModule.Colors.Warning
		else
			charCounter.TextColor3 = ThemeModule.Colors.TextGray
		end
	end)

	local actionSection = Instance.new("Frame")
	actionSection.Name = "ActionSection"
	actionSection.Size = UDim2.new(1, 0, 0, 48)
	actionSection.Position = UDim2.new(0, 0, 0, 230)
	actionSection.BackgroundTransparency = 1
	actionSection.Parent = broadcastPage

	local sendButton = Instance.new("TextButton")
	sendButton.Name = "SendButton"
	sendButton.Size = UDim2.new(0, 160, 0, 44)
	sendButton.Position = UDim2.new(1, -160, 0, 0)
	sendButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sendButton.BorderSizePixel = 0
	sendButton.Text = ""
	sendButton.AutoButtonColor = false
	sendButton.Parent = actionSection

	ThemeModule.CreateCorner(sendButton, 8)

	local sendGradient = ThemeModule.CreateAnimatedGradient(sendButton, "Primary", 45, 1.2)
	table.insert(registeredGradients, sendGradient)

	local sendIcon = Instance.new("TextLabel")
	sendIcon.Size = UDim2.new(0, 22, 1, 0)
	sendIcon.Position = UDim2.new(0, 14, 0, 0)
	sendIcon.BackgroundTransparency = 1
	sendIcon.Text = "📤"
	sendIcon.TextSize = 16
	sendIcon.Font = Enum.Font.GothamBold
	sendIcon.Parent = sendButton

	local sendText = Instance.new("TextLabel")
	sendText.Size = UDim2.new(1, -50, 1, 0)
	sendText.Position = UDim2.new(0, 44, 0, 0)
	sendText.BackgroundTransparency = 1
	sendText.Text = "Kirim Siaran"
	sendText.TextColor3 = ThemeModule.Colors.BackgroundDark
	sendText.TextSize = UIStrings.TextSize.Button
	sendText.Font = Enum.Font.GothamBold
	sendText.TextXAlignment = Enum.TextXAlignment.Left
	sendText.Parent = sendButton

	broadcastGUIElements.SendButton = sendButton

	sendButton.MouseEnter:Connect(function()
		TS:Create(sendButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 165, 0, 46)}):Play()
	end)
	sendButton.MouseLeave:Connect(function()
		TS:Create(sendButton, TweenInfo.new(0.2), {Size = UDim2.new(0, 160, 0, 44)}):Play()
	end)

	local clearButton = Instance.new("TextButton")
	clearButton.Name = "ClearButton"
	clearButton.Size = UDim2.new(0, 105, 0, 44)
	clearButton.Position = UDim2.new(1, -275, 0, 0)
	clearButton.BackgroundColor3 = ThemeModule.Colors.BackgroundLight
	clearButton.BorderSizePixel = 0
	clearButton.Text = ""
	clearButton.AutoButtonColor = false
	clearButton.Parent = actionSection

	ThemeModule.CreateCorner(clearButton, 8)

	local clearIcon = Instance.new("TextLabel")
	clearIcon.Size = UDim2.new(0, 20, 1, 0)
	clearIcon.Position = UDim2.new(0, 12, 0, 0)
	clearIcon.BackgroundTransparency = 1
	clearIcon.Text = "x"
	clearIcon.TextSize = UIStrings.TextSize.Caption
	clearIcon.TextColor3 = ThemeModule.Colors.TextWhite
	clearIcon.Font = Enum.Font.GothamBold
	clearIcon.Parent = clearButton

	local clearText = Instance.new("TextLabel")
	clearText.Size = UDim2.new(1, -40, 1, 0)
	clearText.Position = UDim2.new(0, 35, 0, 0)
	clearText.BackgroundTransparency = 1
	clearText.Text = "Hapus"
	clearText.TextColor3 = ThemeModule.Colors.TextWhite
	clearText.TextSize = UIStrings.TextSize.Caption
	clearText.Font = Enum.Font.GothamMedium
	clearText.TextXAlignment = Enum.TextXAlignment.Left
	clearText.Parent = clearButton

	broadcastGUIElements.ClearButton = clearButton

	clearButton.MouseEnter:Connect(function()
		TS:Create(clearButton, TweenInfo.new(0.15), {BackgroundColor3 = ThemeModule.Colors.BackgroundLighter}):Play()
	end)
	clearButton.MouseLeave:Connect(function()
		TS:Create(clearButton, TweenInfo.new(0.15), {BackgroundColor3 = ThemeModule.Colors.BackgroundLight}):Play()
	end)

	local infoSection = Instance.new("Frame")
	infoSection.Name = "InfoSection"
	infoSection.Size = UDim2.new(1, 0, 0, 56)
	infoSection.Position = UDim2.new(0, 0, 1, -70)
	infoSection.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
	infoSection.BorderSizePixel = 0
	infoSection.Parent = broadcastPage

	ThemeModule.CreateCorner(infoSection, 8)

	local infoIcon = Instance.new("TextLabel")
	infoIcon.Size = UDim2.new(0, 24, 0, 24)
	infoIcon.Position = UDim2.new(0, 10, 0.5, -12)
	infoIcon.BackgroundTransparency = 1
	infoIcon.Text = "ℹ️"
	infoIcon.TextSize = UIStrings.TextSize.Caption
	infoIcon.Font = Enum.Font.GothamBold
	infoIcon.Parent = infoSection

	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(1, -50, 1, -12)
	infoText.Position = UDim2.new(0, 40, 0, 6)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Pesan dikirim ke seluruh pemain. Maks 200 karakter. Ctrl+Enter untuk mengirim."
	infoText.TextColor3 = ThemeModule.Colors.TextGray
	infoText.TextSize = UIStrings.TextSize.Caption
	infoText.Font = Enum.Font.Gotham
	infoText.TextXAlignment = Enum.TextXAlignment.Left
	infoText.TextWrapped = true
	infoText.Parent = infoSection

	sendButton.MouseButton1Click:Connect(sendBroadcastMessage)
	clearButton.MouseButton1Click:Connect(clearTextBox)

	print("[BroadcastClient] Antarmuka berhasil dibuat!")
end

local function setupNotificationContainer()
	if notificationContainer then return end
	notificationContainer = Instance.new("ScreenGui")
	notificationContainer.Name = "BroadcastNotifications"
	notificationContainer.ResetOnSpawn = false
	notificationContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notificationContainer.DisplayOrder = 150
	notificationContainer.IgnoreGuiInset = true
	notificationContainer.Parent = playerGui
end

local function playNotificationSound()
	if not Config.Notification.Sound.Enabled then return end
	local sound = Instance.new("Sound")
	sound.SoundId = Config.Notification.Sound.SoundId
	sound.Volume = Config.Notification.Sound.Volume
	sound.PlaybackSpeed = Config.Notification.Sound.PlaybackSpeed
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function updateNotificationPositions()
	local currentY = Config.Notification.TopOffset
	for i, notifData in ipairs(activeNotifications) do
		if i <= Config.Notification.MaxVisible then
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TS:Create(notifData.Frame, tweenInfo, {Position = UDim2.new(0.5, 0, 0, currentY)}):Play()
			notifData.TargetY = currentY
			currentY = currentY + notifData.Height + Config.Notification.Spacing
		end
	end
	while #activeNotifications > Config.Notification.MaxVisible do
		local oldest = activeNotifications[#activeNotifications]
		if oldest and oldest.Frame then oldest.Frame:Destroy() end
		table.remove(activeNotifications, #activeNotifications)
	end
end

local function removeNotification(notifData)
	for i, data in ipairs(activeNotifications) do
		if data == notifData then
			table.remove(activeNotifications, i)
			break
		end
	end

	local exitTweenInfo = TweenInfo.new(Config.Notification.Animation.ExitSpeed, Config.Notification.Animation.ExitEasingStyle, Config.Notification.Animation.ExitEasingDirection)
	local currentPos = notifData.Frame.Position

	TS:Create(notifData.Frame, exitTweenInfo, {Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, 0, currentPos.Y.Offset - 40)}):Play()

	if notifData.Frame:IsA("CanvasGroup") then
		TS:Create(notifData.Frame, exitTweenInfo, {GroupTransparency = 1}):Play()
	end

	task.delay(Config.Notification.Animation.ExitSpeed, function()
		if notifData.Frame then
			if notifData.Gradient then ThemeModule.GradientSystem.Unregister(notifData.Gradient) end
			if notifData.AccentGradient then ThemeModule.GradientSystem.Unregister(notifData.AccentGradient) end
			notifData.Frame:Destroy()
			updateNotificationPositions()
		end
	end)
end

local function createBroadcastNotification(messageData)
	setupNotificationContainer()

	local message = messageData.Message or ""
	local messageWidth = Config.Notification.Width - 24

	local messageTextHeight = getTextHeight(message, Enum.Font.Gotham, UIStrings.TextSize.Body, messageWidth)
	local messageBoxHeight = math.max(30, messageTextHeight + 12)

	local totalHeight = 52 + messageBoxHeight + 8
	totalHeight = math.clamp(totalHeight, Config.Notification.MinHeight, Config.Notification.MaxHeight)

	local startY = -totalHeight - 15

	local notif = Instance.new("CanvasGroup")
	notif.Name = "BroadcastNotification"
	notif.Size = UDim2.new(0, Config.Notification.Width, 0, totalHeight)
	notif.Position = UDim2.new(0.5, 0, 0, startY)
	notif.AnchorPoint = Vector2.new(0.5, 0)
	notif.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
	notif.BorderSizePixel = 0
	notif.GroupTransparency = 0
	notif.Parent = notificationContainer

	ThemeModule.CreateCorner(notif, 8)

	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 16, 1, 16)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.ZIndex = -1
	shadow.Parent = notif

	local notifStroke, notifGradient = ThemeModule.CreateAnimatedStroke(notif, 1, "Primary", 1.5)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 3, 1, -10)
	accentBar.Position = UDim2.new(0, 5, 0, 5)
	accentBar.BackgroundColor3 = ThemeModule.Colors.Primary1
	accentBar.BorderSizePixel = 0
	accentBar.Parent = notif
	ThemeModule.CreateCorner(accentBar, 2)
	local accentGradient = ThemeModule.CreateAnimatedGradient(accentBar, "Primary", 90, 1.5)

	local avatarContainer = Instance.new("Frame")
	avatarContainer.Size = UDim2.new(0, 28, 0, 28)
	avatarContainer.Position = UDim2.new(0, 12, 0, 8)
	avatarContainer.BackgroundColor3 = ThemeModule.Colors.BackgroundLight
	avatarContainer.BorderSizePixel = 0
	avatarContainer.Parent = notif
	ThemeModule.CreateCorner(avatarContainer, 14)

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = ThemeModule.Colors.Primary1
	avatarStroke.Thickness = 1.5
	avatarStroke.Parent = avatarContainer

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(1, -2, 1, -2)
	avatarImage.Position = UDim2.new(0, 1, 0, 1)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Parent = avatarContainer
	ThemeModule.CreateCorner(avatarImage, 13)

	local success, content = pcall(function()
		return Players:GetUserThumbnailAsync(messageData.SenderId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if success then avatarImage.Image = content end

	local broadcastLabel = Instance.new("TextLabel")
	broadcastLabel.Size = UDim2.new(0, 80, 0, 16)
	broadcastLabel.Position = UDim2.new(0, 44, 0, 5)
	broadcastLabel.BackgroundTransparency = 1
	broadcastLabel.Text = "SIARAN"
	broadcastLabel.TextColor3 = ThemeModule.Colors.Primary1
	broadcastLabel.TextSize = UIStrings.TextSize.Caption
	broadcastLabel.Font = Enum.Font.GothamBold
	broadcastLabel.TextXAlignment = Enum.TextXAlignment.Left
	broadcastLabel.Parent = notif

	local badgeContainer = Instance.new("Frame")
	badgeContainer.Name = "BadgeContainer"
	badgeContainer.Size = UDim2.new(1, -96, 0, 22)
	badgeContainer.Position = UDim2.new(0, 44, 0, 23)
	badgeContainer.BackgroundTransparency = 1
	badgeContainer.Parent = notif

	local badgeLayout = Instance.new("UIListLayout")
	badgeLayout.FillDirection = Enum.FillDirection.Horizontal
	badgeLayout.Padding = UDim.new(0, 4)
	badgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	badgeLayout.Parent = badgeContainer

	local nameBadge = Instance.new("Frame")
	nameBadge.Name = "NameBadge"
	nameBadge.Size = UDim2.new(0, 70, 0, 20)
	nameBadge.BackgroundColor3 = ThemeModule.Colors.BackgroundLight
	nameBadge.BorderSizePixel = 0
	nameBadge.LayoutOrder = 1
	nameBadge.Parent = badgeContainer
	ThemeModule.CreateCorner(nameBadge, 4)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 1, 0)
	nameLabel.Position = UDim2.new(0, 3, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "• " .. (messageData.SenderName or "Unknown")
	nameLabel.TextColor3 = ThemeModule.Colors.TextWhite
	nameLabel.TextSize = UIStrings.TextSize.Caption
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = nameBadge

	local roleBadge = Instance.new("Frame")
	roleBadge.Name = "RoleBadge"
	roleBadge.Size = UDim2.new(0, 60, 0, 20)
	roleBadge.BackgroundColor3 = messageData.RoleColor or ThemeModule.Colors.Primary1
	roleBadge.BackgroundTransparency = 0.8
	roleBadge.BorderSizePixel = 0
	roleBadge.LayoutOrder = 2
	roleBadge.Parent = badgeContainer
	ThemeModule.CreateCorner(roleBadge, 4)

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, -6, 1, 0)
	roleLabel.Position = UDim2.new(0, 3, 0, 0)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = "• " .. (messageData.RoleText or "PLAYER")
	roleLabel.TextColor3 = messageData.RoleColor or ThemeModule.Colors.Primary1
	roleLabel.TextSize = UIStrings.TextSize.Caption
	roleLabel.Font = Enum.Font.GothamBold
	roleLabel.TextXAlignment = Enum.TextXAlignment.Center
	roleLabel.Parent = roleBadge

	task.defer(function()
		if nameLabel and nameLabel.Parent and nameBadge and nameBadge.Parent then
			local nameText = "• " .. (messageData.SenderName or "Unknown")
			local nameWidth = TextService:GetTextSize(nameText, UIStrings.TextSize.Caption, Enum.Font.GothamBold, Vector2.new(200, 20)).X
			nameBadge.Size = UDim2.new(0, math.clamp(nameWidth + 12, 50, 130), 0, 20)
		end

		if roleLabel and roleLabel.Parent and roleBadge and roleBadge.Parent then
			local roleText = "• " .. (messageData.RoleText or "PLAYER")
			local roleWidth = TextService:GetTextSize(roleText, UIStrings.TextSize.Caption, Enum.Font.GothamBold, Vector2.new(200, 20)).X
			roleBadge.Size = UDim2.new(0, math.clamp(roleWidth + 12, 50, 100), 0, 20)
		end
	end)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 18, 0, 18)
	closeBtn.Position = UDim2.new(1, -22, 0, 5)
	closeBtn.BackgroundColor3 = ThemeModule.Colors.CloseRed
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "x"
	closeBtn.TextColor3 = ThemeModule.Colors.TextWhite
	closeBtn.TextSize = 12
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextXAlignment = Enum.TextXAlignment.Center
	closeBtn.TextYAlignment = Enum.TextYAlignment.Center
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = notif
	ThemeModule.CreateCorner(closeBtn, 5)

	local closePad = Instance.new("UIPadding")
	closePad.PaddingBottom = UDim.new(0, 2)
	closePad.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		TS:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = ThemeModule.Colors.CloseRedHover}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TS:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = ThemeModule.Colors.CloseRed}):Play()
	end)

	local messageContainer = Instance.new("Frame")
	messageContainer.Name = "MessageContainer"
	messageContainer.Size = UDim2.new(1, -20, 0, messageBoxHeight)
	messageContainer.Position = UDim2.new(0, 10, 0, 48)
	messageContainer.BackgroundColor3 = ThemeModule.Colors.BackgroundDark
	messageContainer.BorderSizePixel = 0
	messageContainer.Parent = notif
	ThemeModule.CreateCorner(messageContainer, 5)

	local messageContent = Instance.new("TextLabel")
	messageContent.Size = UDim2.new(1, -10, 1, -6)
	messageContent.Position = UDim2.new(0, 5, 0, 3)
	messageContent.BackgroundTransparency = 1
	messageContent.Text = message
	messageContent.TextColor3 = ThemeModule.Colors.TextGray
	messageContent.TextSize = UIStrings.TextSize.Body
	messageContent.Font = Enum.Font.Gotham
	messageContent.TextXAlignment = Enum.TextXAlignment.Left
	messageContent.TextYAlignment = Enum.TextYAlignment.Top
	messageContent.TextWrapped = true
	messageContent.Parent = messageContainer

	local notifData = {
		Frame = notif,
		Gradient = notifGradient,
		AccentGradient = accentGradient,
		Height = totalHeight,
		Timestamp = tick(),
		Duration = Config.Notification.Duration
	}

	closeBtn.MouseButton1Click:Connect(function()
		removeNotification(notifData)
	end)

	for i, existingNotif in ipairs(activeNotifications) do
		local newIndex = i + 1
		if newIndex <= Config.Notification.MaxVisible then
			local newY = Config.Notification.TopOffset + totalHeight + Config.Notification.Spacing
			for j = 1, i - 1 do
				if activeNotifications[j] then
					newY = newY + activeNotifications[j].Height + Config.Notification.Spacing
				end
			end
			existingNotif.TargetY = newY
			TS:Create(existingNotif.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, newY)
			}):Play()
		end
	end

	table.insert(activeNotifications, 1, notifData)

	while #activeNotifications > Config.Notification.MaxVisible do
		local oldest = activeNotifications[#activeNotifications]
		if oldest and oldest.Frame then oldest.Frame:Destroy() end
		table.remove(activeNotifications, #activeNotifications)
	end

	TS:Create(notif, TweenInfo.new(Config.Notification.Animation.DropSpeed, Config.Notification.Animation.EasingStyle, Config.Notification.Animation.EasingDirection), {
		Position = UDim2.new(0.5, 0, 0, Config.Notification.TopOffset)
	}):Play()

	playNotificationSound()

	task.delay(notifData.Duration, function()
		if notifData.Frame and notifData.Frame.Parent then
			removeNotification(notifData)
		end
	end)
end

sendBroadcastMessage = function()
	local textBox = broadcastGUIElements.TextBox
	if not textBox then return end
	local message = textBox.Text:match("^%s*(.-)%s*$")
	if message == "" then
		NotifModule.Warning("Siaran", "Silakan masukkan pesan", 3)
		return
	end
	if AdminConfig.SoundSystem and AdminConfig.SoundSystem.PlayClick then
		AdminConfig.SoundSystem.PlayClick()
	end
	SendMessageRemote:FireServer(message)
	textBox.Text = ""
	NotifModule.Success("Siaran", "Pesan siaran berhasil dikirim!", 2)
end

clearTextBox = function()
	local textBox = broadcastGUIElements.TextBox
	if textBox then
		textBox.Text = ""
		if AdminConfig.SoundSystem and AdminConfig.SoundSystem.PlayClick then
			AdminConfig.SoundSystem.PlayClick()
		end
		NotifModule.Info("Siaran", "Teks dibersihkan", 2)
	end
end

ReceiveMessageRemote.OnClientEvent:Connect(function(messageData)
	if messageData.Type == "Error" then
		NotifModule.Error("Error", messageData.Message, 4)
	elseif messageData.Type == "Message" then
		createBroadcastNotification(messageData)
	end
end)

local function cleanup()
	for _, gradient in ipairs(registeredGradients) do
		if gradient then ThemeModule.GradientSystem.Unregister(gradient) end
	end
	registeredGradients = {}
	for _, notifData in ipairs(activeNotifications) do
		if notifData.Gradient then ThemeModule.GradientSystem.Unregister(notifData.Gradient) end
		if notifData.AccentGradient then ThemeModule.GradientSystem.Unregister(notifData.AccentGradient) end
		if notifData.Frame then notifData.Frame:Destroy() end
	end
	activeNotifications = {}
end

local function updateThemeGradients()
	local sendBtn = broadcastGUIElements.SendButton
	if sendBtn then
		local grad = sendBtn:FindFirstChildOfClass("UIGradient")
		if grad then
			grad.Color = ThemeModule.Gradients.Primary
		end
	end
end

local function initialize()
	buildBroadcastGUI()
	local broadcastPage = AdminConfig.GUI.BroadcastPage
	if broadcastPage then
		broadcastPage.Destroying:Connect(cleanup)
	end

	if ThemeModule.OnThemeChanged then
		ThemeModule.OnThemeChanged.Event:Connect(updateThemeGradients)
	end

	local MenuConfig = nil
	pcall(function()
		MenuConfig = require(Modules:WaitForChild("MenuConfig", 5))
	end)
	if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnColorChanged then
		MenuConfig.Events.OnColorChanged.Event:Connect(updateThemeGradients)
	end

	player:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
		local theme = player:GetAttribute("CurrentTheme")
		if theme and ThemeModule and ThemeModule.ApplyPreset then
			ThemeModule.ApplyPreset(theme)
		end
		updateThemeGradients()
	end)

	local cur = player:GetAttribute("CurrentTheme")
	if cur and ThemeModule and ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset(cur)
	end
	updateThemeGradients()

	print("✅ [BroadcastClient] Loaded!")
end

task.delay(0.5, initialize)
