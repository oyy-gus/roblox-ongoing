local AdminConfig = {}

AdminConfig.Services = {
	Players = game:GetService("Players"),
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	Lighting = game:GetService("Lighting"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ContextActionService = game:GetService("ContextActionService"),
	SoundService = game:GetService("SoundService"),
}

AdminConfig.Config = {
	ToggleKey = Enum.KeyCode.Insert,

	PanelSize = {
		Width = 550,
		Height = 450,
	},

	HeaderHeight = 46,
	SidebarWidth = 130,
	TabButtonHeight = 34,

	Colors = {
		Background    = Color3.fromHex("#080808"),
		Surface       = Color3.fromHex("#151515"),
		SurfaceLight  = Color3.fromHex("#1C1C1C"),
		Primary       = Color3.fromHex("#FFFFFF"),
		Success       = Color3.fromHex("#FFFFFF"),
		Error         = Color3.fromHex("#AAAAAA"),
		Warning       = Color3.fromHex("#CCCCCC"),
		Info          = Color3.fromHex("#FFFFFF"),
		Text          = Color3.fromHex("#FFFFFF"),
		TextSecondary = Color3.fromHex("#A0A0A0"),
		Border        = Color3.fromHex("#353535"),
		TabActive     = Color3.fromHex("#FFFFFF"),
		TabInactive   = Color3.fromHex("#1C1C1C"),

		Owner         = Color3.fromHex("#FFFFFF"),
		Admin         = Color3.fromHex("#E0E0E0"),
		Moderator     = Color3.fromHex("#CCCCCC"),
		VIP           = Color3.fromHex("#AAAAAA"),
		Player        = Color3.fromHex("#888888"),
	},

	Animation = {
		Speed         = 0.3,
		EaseStyle     = Enum.EasingStyle.Quint,
		EaseDirection = Enum.EasingDirection.Out,
	},

	Notification = {
		Width = 320,
		Height = 45,
		Spacing = 55,
		Duration = 3.5,
	},
}

AdminConfig.State = {
	currentTab = nil,
	isMenuOpen = false,
	isGUIReady = false,
}

AdminConfig.GUI = {
	ScreenGui        = nil,
	MainPanel        = nil,
	Header           = nil,
	TabContainer     = nil,
	ContentContainer = nil,
	CloseButton      = nil,
	AdminIcon        = nil,
	TabButtons       = {},
	TabPages         = {},
	TabNames         = {},

	RoleGivePage     = nil,
	LogsPage         = nil,
	PlayersPage      = nil,
	SettingsPage     = nil,

	RoleGiveTab      = nil,
	LogsTab          = nil,
	PlayersTab       = nil,
	SettingsTab      = nil,
}

AdminConfig.Events = {
	OnTabChanged   = Instance.new("BindableEvent"),
	OnMenuToggled  = Instance.new("BindableEvent"),
	OnGUIReady     = Instance.new("BindableEvent"),
}

AdminConfig.SoundSystem = nil

AdminConfig.OpenPanel        = function() end
AdminConfig.ClosePanel       = function() end
AdminConfig.TogglePanel      = function() end
AdminConfig.ForceClosePanel  = function() end
AdminConfig.SwitchTab        = function() end
AdminConfig.ShowNotification = function() end

function AdminConfig.IsGUIReady()
	return AdminConfig.State.isGUIReady
end

function AdminConfig.MarkGUIReady()
	AdminConfig.State.isGUIReady = true
	AdminConfig.Events.OnGUIReady:Fire()
end

function AdminConfig.WaitForGUIReady()
	if AdminConfig.State.isGUIReady then
		return true
	end
	AdminConfig.Events.OnGUIReady.Event:Wait()
	return true
end

function AdminConfig.GetColor(colorName)
	return AdminConfig.Config.Colors[colorName]
end

function AdminConfig.GetRoleColor(roleName)
	local roleColors = {
		Owner = AdminConfig.Config.Colors.Owner,
		Admin = AdminConfig.Config.Colors.Admin,
		Moderator = AdminConfig.Config.Colors.Moderator,
		VIP = AdminConfig.Config.Colors.VIP,
		Player = AdminConfig.Config.Colors.Player,
	}
	return roleColors[roleName] or AdminConfig.Config.Colors.Player
end

function AdminConfig.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

function AdminConfig.CreatePadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 10)
	padding.PaddingBottom = UDim.new(0, bottom or 10)
	padding.PaddingLeft = UDim.new(0, left or 10)
	padding.PaddingRight = UDim.new(0, right or 10)
	padding.Parent = parent
	return padding
end

function AdminConfig.CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or AdminConfig.Config.Colors.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.5
	stroke.Parent = parent
	return stroke
end

function AdminConfig.CreateListLayout(parent, direction, padding, alignment)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, padding or 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	if direction == Enum.FillDirection.Horizontal then
		layout.VerticalAlignment = alignment or Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		layout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	end

	layout.Parent = parent
	return layout
end

function AdminConfig.CreateGridLayout(parent, cellSize, cellPadding)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = cellSize or UDim2.new(0.5, -5, 0, 40)
	layout.CellPadding = cellPadding or UDim2.new(0, 10, 0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = parent
	return layout
end

function AdminConfig.CreateScrollingFrame(parent, name, position, size)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name or "ScrollFrame"
	scroll.Size = size or UDim2.new(1, 0, 1, 0)
	scroll.Position = position or UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = AdminConfig.Config.Colors.Primary
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = parent
	return scroll
end

function AdminConfig.PlayClick()
	if AdminConfig.SoundSystem and AdminConfig.SoundSystem.PlayClick then
		AdminConfig.SoundSystem.PlayClick()
	end
end

function AdminConfig.Tween(instance, properties, duration, easingStyle, easingDirection)
	local TweenService = AdminConfig.Services.TweenService
	local tweenInfo = TweenInfo.new(
		duration or 0.2,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function AdminConfig.SetupButtonHover(button, normalColor, hoverLerp)
	local TweenService = AdminConfig.Services.TweenService
	hoverLerp = hoverLerp or 0.15

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = normalColor:Lerp(Color3.new(1,1,1), hoverLerp)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

function AdminConfig.CreateButton(parent, name, text, size, position, bgColor, textColor)
	local button = Instance.new("TextButton")
	button.Name = name or "Button"
	button.Size = size or UDim2.new(0, 100, 0, 36)
	button.Position = position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = bgColor or AdminConfig.Config.Colors.Primary
	button.BorderSizePixel = 0
	button.Text = text or "Button"
	button.TextColor3 = textColor or AdminConfig.Config.Colors.Text
	button.TextSize = 10.5
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = parent

	AdminConfig.CreateCorner(button, 6)
	AdminConfig.SetupButtonHover(button, bgColor or AdminConfig.Config.Colors.Primary)

	button.MouseButton1Click:Connect(function()
		AdminConfig.PlayClick()
	end)

	return button
end

function AdminConfig.CreateSection(parent, name, position, size)
	local section = Instance.new("Frame")
	section.Name = name or "Section"
	section.Size = size or UDim2.new(1, 0, 0, 100)
	section.Position = position or UDim2.new(0, 0, 0, 0)
	section.BackgroundColor3 = AdminConfig.Config.Colors.SurfaceLight
	section.BorderSizePixel = 0
	section.Parent = parent

	AdminConfig.CreateCorner(section, 8)
	AdminConfig.CreateStroke(section, AdminConfig.Config.Colors.Border)

	return section
end

function AdminConfig.CreateSectionHeader(parent, text, icon)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = AdminConfig.Config.Colors.Surface
	header.BorderSizePixel = 0
	header.Parent = parent

	AdminConfig.CreateCorner(header, 8)

	local cover = Instance.new("Frame")
	cover.Size = UDim2.new(1, 0, 0, 10)
	cover.Position = UDim2.new(0, 0, 1, -10)
	cover.BackgroundColor3 = AdminConfig.Config.Colors.Surface
	cover.BorderSizePixel = 0
	cover.Parent = header

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = (icon or "") .. " " .. (text or "Header")
	label.TextColor3 = AdminConfig.Config.Colors.Text
	label.TextSize = 11.5
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = header

	return header, label
end

function AdminConfig.CreateInfoBox(parent, labelText, position, size)
	local frame = Instance.new("Frame")
	frame.Name = "InfoBox"
	frame.Size = size or UDim2.new(1, -20, 0, 55)
	frame.Position = position or UDim2.new(0, 10, 0, 0)
	frame.BackgroundColor3 = AdminConfig.Config.Colors.Surface
	frame.BorderSizePixel = 0
	frame.Parent = parent

	AdminConfig.CreateCorner(frame, 6)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -16, 0, 18)
	label.Position = UDim2.new(0, 8, 0, 6)
	label.BackgroundTransparency = 1
	label.Text = labelText or "Label:"
	label.TextColor3 = AdminConfig.Config.Colors.TextSecondary
	label.TextSize = 9
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -16, 0, 22)
	value.Position = UDim2.new(0, 8, 0, 26)
	value.BackgroundTransparency = 1
	value.Text = "—"
	value.TextColor3 = AdminConfig.Config.Colors.Text
	value.TextSize = 12
	value.Font = Enum.Font.GothamBold
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.Parent = frame

	return frame, label, value
end

function AdminConfig.CreatePlayerButton(parent, targetPlayer, onClick)
	local Players = AdminConfig.Services.Players
	local TweenService = AdminConfig.Services.TweenService

	local btn = Instance.new("TextButton")
	btn.Name = targetPlayer.Name
	btn.Size = UDim2.new(1, -4, 0, 42)
	btn.BackgroundColor3 = AdminConfig.Config.Colors.Surface
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = parent

	AdminConfig.CreateCorner(btn, 6)
	local btnStroke = AdminConfig.CreateStroke(btn, AdminConfig.Config.Colors.Border)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Size = UDim2.new(0, 30, 0, 30)
	avatarImage.Position = UDim2.new(0, 6, 0.5, -15)
	avatarImage.BackgroundColor3 = AdminConfig.Config.Colors.SurfaceLight
	avatarImage.BorderSizePixel = 0
	avatarImage.Parent = btn
	AdminConfig.CreateCorner(avatarImage, 15)

	task.spawn(function()
		local success, result = pcall(function()
			return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if success and avatarImage then
			avatarImage.Image = result
		end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, -50, 0, 18)
	nameLabel.Position = UDim2.new(0, 42, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = targetPlayer.DisplayName
	nameLabel.TextColor3 = AdminConfig.Config.Colors.Text
	nameLabel.TextSize = 10.5
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = btn

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, -50, 0, 14)
	usernameLabel.Position = UDim2.new(0, 42, 0, 22)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = "@" .. targetPlayer.Name
	usernameLabel.TextColor3 = AdminConfig.Config.Colors.TextSecondary
	usernameLabel.TextSize = 9
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = AdminConfig.Config.Colors.Surface:Lerp(Color3.new(1,1,1), 0.05)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = AdminConfig.Config.Colors.Surface
		}):Play()
	end)

	if onClick then
		btn.MouseButton1Click:Connect(function()
			AdminConfig.PlayClick()
			onClick(targetPlayer, btn, btnStroke)
		end)
	end

	return btn, btnStroke, avatarImage, nameLabel, usernameLabel
end

AdminConfig.RoleDefinitions = {
	{ Name = "VIP", Icon = "👑", Color = AdminConfig.Config.Colors.VIP, Priority = 1 },
}

function AdminConfig.GetRoleDefinition(roleName)
	for _, def in ipairs(AdminConfig.RoleDefinitions) do
		if def.Name == roleName then
			return def
		end
	end
	return nil
end

return AdminConfig
