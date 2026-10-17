local MenuConfig = {}

MenuConfig.Services = {
	Players              = game:GetService("Players"),
	TweenService         = game:GetService("TweenService"),
	UserInputService     = game:GetService("UserInputService"),
	HttpService          = game:GetService("HttpService"),
	RunService           = game:GetService("RunService"),
	GuiService           = game:GetService("GuiService"),
	Lighting             = game:GetService("Lighting"),
	ContextActionService = game:GetService("ContextActionService"),
	ReplicatedStorage    = game:GetService("ReplicatedStorage"),
	SoundService         = game:GetService("SoundService"),
	MarketplaceService   = game:GetService("MarketplaceService"),
}

MenuConfig.ThemeModule = nil

function MenuConfig.SetThemeModule(themeModule)
	MenuConfig.ThemeModule = themeModule
end

function MenuConfig.GetThemeModule()
	return MenuConfig.ThemeModule
end

function MenuConfig.GetPrimaryColor()
	if MenuConfig.ThemeModule and MenuConfig.ThemeModule.Colors then
		return MenuConfig.ThemeModule.Colors.Primary or Color3.fromRGB(88, 101, 242)
	end
	return MenuConfig.Config.Colors.Primary or Color3.fromRGB(88, 101, 242)
end

function MenuConfig.GetActiveColor()
	return MenuConfig.GetPrimaryColor()
end

MenuConfig.Config = {
	ToggleKey = Enum.KeyCode.Insert,

	PanelSize = {
		Width  = 550,
		Height = 450,
	},

	HeaderHeight    = 46,
	TabButtonHeight = 34,

	Colors = {
		Background    = Color3.fromHex("#080808"),
		Surface       = Color3.fromHex("#151515"),
		SurfaceLight  = Color3.fromHex("#1C1C1C"),
		Primary       = Color3.fromHex("#FFFFFF"),
		Success       = Color3.fromHex("#FFFFFF"),
		Error         = Color3.fromHex("#B0B0B0"),
		Warning       = Color3.fromHex("#D0D0D0"),
		Info          = Color3.fromHex("#FFFFFF"),
		Text          = Color3.fromHex("#FFFFFF"),
		TextSecondary = Color3.fromHex("#A0A0A0"),
		Border        = Color3.fromHex("#353535"),
		TabActive     = Color3.fromHex("#FFFFFF"),
		TabInactive   = Color3.fromHex("#1C1C1C"),

		PlayerList = {
			Background       = Color3.fromHex("#080808"),
			ItemBg           = Color3.fromHex("#151515"),
			ItemHover        = Color3.fromHex("#1C1C1C"),
			NameText         = Color3.fromHex("#FFFFFF"),
			UsernameText     = Color3.fromHex("#A0A0A0"),
			CountText        = Color3.fromHex("#666666"),
			ScrollBar        = Color3.fromHex("#353535"),
			OnlineIndicator  = Color3.fromHex("#4ADE80"),
			FriendIndicator  = Color3.fromHex("#FFFFFF"),
			FriendBorder     = Color3.fromHex("#353535"),
			ConnectionText   = Color3.fromHex("#A0A0A0"),
			ProfileBg        = Color3.fromHex("#151515"),
			ProfileBorder    = Color3.fromHex("#353535"),
		},
	},

	Layout = {
		ScrollBarThickness       = 4,
		ScrollBarThicknessMobile = 6,
		ButtonCorner             = 8,
		SmallCorner              = 6,
		ItemPadding              = 6,
		SectionPadding           = 10,
	},

	Animation = {
		Speed         = 0.3,
		EaseStyle     = Enum.EasingStyle.Quint,
		EaseDirection = Enum.EasingDirection.Out,
	},

	Notification = {
		Width    = 320,
		Height   = 45,
		Spacing  = 55,
		Duration = 3.5,
	},
}

MenuConfig.State = {
	currentTab         = nil,
	currentMainTab     = nil,
	isMenuOpen         = false,
	isGUIReady         = false,
	hasVIPAccess       = false,
	isResettingAvatar  = false,
	lastKnownPosition  = nil,
	hasBeenDragged     = false,
	isResizing         = false,
	lastViewportSize   = nil,
}

MenuConfig.UserSettings = {
	musicVolume        = 100,
	muteMusic          = false,
	hideBubbleChat     = false,
	hidePlayerEffects  = false,
	hidePlayers        = false,
	hideOverhead       = false,
	hideShadow         = false,
}

MenuConfig.GUI = {
	ScreenGui        = nil,
	MainPanel        = nil,
	PanelContainer   = nil,
	Header           = nil,
	TabBar           = nil,
	ContentContainer = nil,
	CloseButton      = nil,
	PanelIcon        = nil,

	TabButtons       = {},
	TabFrames        = {},
	TabPages         = {},
	TabNames         = {},

	UIScale      = nil,
	PanelUIScale = nil,
	GUIScaler    = nil,

	MusicPage      = nil,
	CommandsPage   = nil,
	PengaturanPage = nil,
	PemainPage     = nil,
	PlayersPage    = nil,
	TokoPage       = nil,
	KreditPage     = nil,
	ConfigPage     = nil,
	GamePassPage   = nil,
	CreditPage     = nil,

	MusicTab      = nil,
	CommandsTab   = nil,
	PengaturanTab = nil,
	PemainTab     = nil,
	TokoTab       = nil,
	KreditTab     = nil,
}

MenuConfig.CachedDimensions = {
	optimalWidth   = 0,
	optimalHeight  = 0,
	headerHeight   = 0,
	contentPadding = 0,
}

MenuConfig.Events = {
	OnMenuToggled        = Instance.new("BindableEvent"),
	OnTabChanged         = Instance.new("BindableEvent"),
	OnSettingChanged     = Instance.new("BindableEvent"),
	OnScreenResized      = Instance.new("BindableEvent"),
	OnGUIReady           = Instance.new("BindableEvent"),
	OnContentNeedsUpdate = Instance.new("BindableEvent"),
	OnVIPAccessChanged   = Instance.new("BindableEvent"),
	OnAvatarResetting    = Instance.new("BindableEvent"),
	OnPositionReset      = Instance.new("BindableEvent"),
	OnThemeChanged       = Instance.new("BindableEvent"),
	OnColorChanged       = Instance.new("BindableEvent"),
}

MenuConfig.SoundSystem = nil

MenuConfig.OpenPanel          = function() end
MenuConfig.ClosePanel         = function() end
MenuConfig.TogglePanel        = function() end
MenuConfig.ForceClosePanel    = function() end
MenuConfig.SwitchTab          = function() end
MenuConfig.ShowNotification   = function() end
MenuConfig.ResetPanelPosition = function() end
MenuConfig.ClampPanelPosition = function() end

MenuConfig.CloseMenu      = function() MenuConfig.ClosePanel() end
MenuConfig.OpenMenu       = function() MenuConfig.OpenPanel() end
MenuConfig.ToggleMenu     = function() MenuConfig.TogglePanel() end
MenuConfig.ForceCloseMenu = function() MenuConfig.ForceClosePanel() end
MenuConfig.ResetPosition  = function() MenuConfig.ResetPanelPosition() end

function MenuConfig.GetConfig()
	return MenuConfig.Config
end

MenuConfig.ContentUpdateCallbacks = {}

function MenuConfig.RegisterContentUpdateCallback(name, callback)
	MenuConfig.ContentUpdateCallbacks[name] = callback
end

function MenuConfig.UnregisterContentUpdateCallback(name)
	MenuConfig.ContentUpdateCallbacks[name] = nil
end

function MenuConfig.TriggerContentUpdate()
	for name, callback in pairs(MenuConfig.ContentUpdateCallbacks) do
		local ok, err = pcall(callback)
		if not ok then
			warn("Kesalahan ContentUpdate untuk " .. name .. ": " .. tostring(err))
		end
	end
end

function MenuConfig.IsGUIReady()
	return MenuConfig.State.isGUIReady
end

function MenuConfig.MarkGUIReady()
	MenuConfig.State.isGUIReady = true
	MenuConfig.Events.OnGUIReady:Fire()
	print("✅ MenuConfig: Antarmuka Siap!")
end

function MenuConfig.WaitForGUIReady(timeout)
	timeout = timeout or 10
	local startTime = tick()
	if MenuConfig.State.isGUIReady then return true end
	while not MenuConfig.State.isGUIReady do
		if tick() - startTime > timeout then
			warn("⚠️ MenuConfig.WaitForGUIReady: Timeout setelah " .. timeout .. " detik")
			return false
		end
		task.wait(0.1)
	end
	return true
end

function MenuConfig.SetVIPAccess(hasAccess)
	local changed = MenuConfig.State.hasVIPAccess ~= hasAccess
	MenuConfig.State.hasVIPAccess = hasAccess

	if changed then
		MenuConfig.Events.OnVIPAccessChanged:Fire(hasAccess)
	end
end

function MenuConfig.HasVIPAccess()
	return MenuConfig.State.hasVIPAccess
end

MenuConfig.SetVVIPAccess = MenuConfig.SetVIPAccess
MenuConfig.HasVVIPAccess = MenuConfig.HasVIPAccess

function MenuConfig.SetResettingAvatar(isResetting)
	MenuConfig.State.isResettingAvatar = isResetting
	MenuConfig.Events.OnAvatarResetting:Fire(isResetting)
end

function MenuConfig.IsResettingAvatar()
	return MenuConfig.State.isResettingAvatar
end

function MenuConfig.ChangeTheme(presetName)
	if MenuConfig.ThemeModule then
		local success = MenuConfig.ThemeModule.ApplyPreset(presetName)
		if success then
			MenuConfig.Events.OnThemeChanged:Fire(presetName)
			MenuConfig.Events.OnColorChanged:Fire()
		end
		return success
	end
	return false
end

function MenuConfig.FireColorChanged()
	MenuConfig.Events.OnColorChanged:Fire()
end

local screenInfoCache = {
	width       = 0,
	height      = 0,
	isMobile    = false,
	isLandscape = true,
	lastUpdate  = 0,
}

function MenuConfig.DetectPlatform()
	local UserInputService = MenuConfig.Services.UserInputService
	local camera = workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		screenInfoCache.width       = viewport.X
		screenInfoCache.height      = viewport.Y
		screenInfoCache.isLandscape = viewport.X > viewport.Y
	end
	screenInfoCache.isMobile   = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	screenInfoCache.lastUpdate = tick()
	return screenInfoCache
end

function MenuConfig.GetScreenInfo()
	local camera = workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		screenInfoCache.width       = viewport.X
		screenInfoCache.height      = viewport.Y
		screenInfoCache.isLandscape = viewport.X > viewport.Y
	end
	local UserInputService = MenuConfig.Services.UserInputService
	screenInfoCache.isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	return screenInfoCache
end

function MenuConfig.CalculateOptimalSize()
	local camera = workspace.CurrentCamera
	if not camera then
		return 420, 500
	end

	local viewport = camera.ViewportSize
	local screenWidth = viewport.X
	local screenHeight = viewport.Y

	local UserInputService = MenuConfig.Services.UserInputService
	local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local isLandscape = screenWidth > screenHeight

	screenInfoCache.isMobile = isMobile
	screenInfoCache.isLandscape = isLandscape
	screenInfoCache.width = screenWidth
	screenInfoCache.height = screenHeight

	local width, height

	if isMobile then
		if isLandscape then
			width = math.clamp(screenWidth * 0.55, 300, 600)
			height = math.clamp(screenHeight * 0.70, 250, 400)
		else
			width = math.clamp(screenWidth * 0.88, 280, 420)
			height = math.clamp(screenHeight * 0.50, 320, 500)
		end
	else
		width = math.clamp(screenWidth * 0.35, 400, 550)
		height = math.clamp(screenHeight * 0.55, 400, 600)
	end

	width = math.min(width, screenWidth - 40)
	height = math.min(height, screenHeight - 80)

	MenuConfig.CachedDimensions.optimalWidth = width
	MenuConfig.CachedDimensions.optimalHeight = height

	return width, height
end

function MenuConfig.GetHeaderHeight()
	local isMobile = screenInfoCache.isMobile
	local isLandscape = screenInfoCache.isLandscape

	local headerHeight
	if isMobile then
		headerHeight = isLandscape and 40 or 46
	else
		headerHeight = 50
	end

	MenuConfig.CachedDimensions.headerHeight = headerHeight
	return headerHeight
end

function MenuConfig.GetScaledValue(base, min, max)
	local camera = workspace.CurrentCamera
	if not camera then return base end
	local viewport   = camera.ViewportSize
	local scaleFactor = math.min(viewport.X / 1920, viewport.Y / 1080)
	return math.clamp(base * scaleFactor, min, max)
end

function MenuConfig.PlayClick()
	if MenuConfig.SoundSystem and MenuConfig.SoundSystem.PlayClick then
		MenuConfig.SoundSystem.PlayClick()
	end
end

function MenuConfig.Tween(instance, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration        or 0.2,
		easingStyle     or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	local tween = MenuConfig.Services.TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function MenuConfig.SetupButtonHover(button, normalColor, hoverLerp)
	hoverLerp = hoverLerp or 0.15
	button.MouseEnter:Connect(function()
		MenuConfig.Services.TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = normalColor:Lerp(Color3.new(1, 1, 1), hoverLerp)
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		MenuConfig.Services.TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = normalColor
		}):Play()
	end)
end

function MenuConfig.CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

function MenuConfig.CreatePadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop    = UDim.new(0, top    or 10)
	padding.PaddingBottom = UDim.new(0, bottom or 10)
	padding.PaddingLeft   = UDim.new(0, left   or 10)
	padding.PaddingRight  = UDim.new(0, right  or 10)
	padding.Parent = parent
	return padding
end

function MenuConfig.CreateStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color        = color or MenuConfig.Config.Colors.Border
	stroke.Thickness    = thickness or 1
	stroke.Transparency = transparency or 0.5
	stroke.Parent = parent
	return stroke
end

function MenuConfig.CreateListLayout(parent, direction, padding, alignment)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding       = UDim.new(0, padding or 5)
	layout.SortOrder     = Enum.SortOrder.LayoutOrder
	if direction == Enum.FillDirection.Horizontal then
		layout.VerticalAlignment   = alignment or Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		layout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Center
		layout.VerticalAlignment   = Enum.VerticalAlignment.Top
	end
	layout.Parent = parent
	return layout
end

function MenuConfig.CreateGridLayout(parent, cellSize, cellPadding)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize            = cellSize    or UDim2.new(0.5, -5, 0, 40)
	layout.CellPadding         = cellPadding or UDim2.new(0, 10, 0, 10)
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = parent
	return layout
end

function MenuConfig.CreateScrollingFrame(parent, name, position, size)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                   = name     or "ScrollFrame"
	scroll.Size                   = size     or UDim2.new(1, 0, 1, 0)
	scroll.Position               = position or UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 4
	scroll.ScrollBarImageColor3   = MenuConfig.Config.Colors.Primary
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scroll.ScrollingDirection     = Enum.ScrollingDirection.Y
	scroll.Parent = parent
	return scroll
end

function MenuConfig.CreateButton(parent, name, text, size, position, bgColor, textColor)
	local button = Instance.new("TextButton")
	button.Name             = name     or "Button"
	button.Size             = size     or UDim2.new(0, 100, 0, 36)
	button.Position         = position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = bgColor  or MenuConfig.Config.Colors.Primary
	button.BorderSizePixel  = 0
	button.Text             = text     or "Button"
	button.TextColor3       = textColor or MenuConfig.Config.Colors.Text
	button.TextSize         = 12
	button.Font             = Enum.Font.GothamBold
	button.AutoButtonColor  = false
	button.Parent = parent

	MenuConfig.CreateCorner(button, 6)
	MenuConfig.SetupButtonHover(button, bgColor or MenuConfig.Config.Colors.Primary)

	button.MouseButton1Click:Connect(function()
		MenuConfig.PlayClick()
	end)

	return button
end

function MenuConfig.CreateSection(parent, name, position, size)
	local section = Instance.new("Frame")
	section.Name             = name     or "Section"
	section.Size             = size     or UDim2.new(1, 0, 0, 100)
	section.Position         = position or UDim2.new(0, 0, 0, 0)
	section.BackgroundColor3 = MenuConfig.Config.Colors.SurfaceLight
	section.BorderSizePixel  = 0
	section.Parent = parent

	MenuConfig.CreateCorner(section, 8)
	MenuConfig.CreateStroke(section, MenuConfig.Config.Colors.Border)

	return section
end

function MenuConfig.CreateSectionHeader(parent, text, icon)
	local hdr = Instance.new("Frame")
	hdr.Name             = "Header"
	hdr.Size             = UDim2.new(1, 0, 0, 36)
	hdr.BackgroundColor3 = MenuConfig.Config.Colors.Surface
	hdr.BorderSizePixel  = 0
	hdr.Parent = parent

	MenuConfig.CreateCorner(hdr, 8)

	local cover = Instance.new("Frame")
	cover.Size             = UDim2.new(1, 0, 0, 10)
	cover.Position         = UDim2.new(0, 0, 1, -10)
	cover.BackgroundColor3 = MenuConfig.Config.Colors.Surface
	cover.BorderSizePixel  = 0
	cover.Parent = hdr

	local label = Instance.new("TextLabel")
	label.Size               = UDim2.new(1, -20, 1, 0)
	label.Position           = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text               = (icon or "") .. " " .. (text or "Header")
	label.TextColor3         = MenuConfig.Config.Colors.Text
	label.TextSize           = 13
	label.Font               = Enum.Font.GothamBold
	label.TextXAlignment     = Enum.TextXAlignment.Left
	label.Parent = hdr

	return hdr, label
end

function MenuConfig.CreateInfoBox(parent, labelText, position, size)
	local frame = Instance.new("Frame")
	frame.Name             = "InfoBox"
	frame.Size             = size     or UDim2.new(1, -20, 0, 55)
	frame.Position         = position or UDim2.new(0, 10, 0, 0)
	frame.BackgroundColor3 = MenuConfig.Config.Colors.Surface
	frame.BorderSizePixel  = 0
	frame.Parent = parent

	MenuConfig.CreateCorner(frame, 6)

	local label = Instance.new("TextLabel")
	label.Name               = "Label"
	label.Size               = UDim2.new(1, -16, 0, 18)
	label.Position           = UDim2.new(0, 8, 0, 6)
	label.BackgroundTransparency = 1
	label.Text               = labelText or "Label:"
	label.TextColor3         = MenuConfig.Config.Colors.TextSecondary
	label.TextSize           = 10
	label.Font               = Enum.Font.Gotham
	label.TextXAlignment     = Enum.TextXAlignment.Left
	label.Parent = frame

	local value = Instance.new("TextLabel")
	value.Name               = "Value"
	value.Size               = UDim2.new(1, -16, 0, 22)
	value.Position           = UDim2.new(0, 8, 0, 26)
	value.BackgroundTransparency = 1
	value.Text               = "—"
	value.TextColor3         = MenuConfig.Config.Colors.Text
	value.TextSize           = 14
	value.Font               = Enum.Font.GothamBold
	value.TextXAlignment     = Enum.TextXAlignment.Left
	value.TextTruncate       = Enum.TextTruncate.AtEnd
	value.Parent = frame

	return frame, label, value
end

function MenuConfig.CreatePlayerButton(parent, targetPlayer, onClick)
	local Players      = MenuConfig.Services.Players
	local TweenService = MenuConfig.Services.TweenService

	local btn = Instance.new("TextButton")
	btn.Name             = targetPlayer.Name
	btn.Size             = UDim2.new(1, -4, 0, 42)
	btn.BackgroundColor3 = MenuConfig.Config.Colors.Surface
	btn.BorderSizePixel  = 0
	btn.Text             = ""
	btn.AutoButtonColor  = false
	btn.Parent = parent

	MenuConfig.CreateCorner(btn, 6)
	local btnStroke = MenuConfig.CreateStroke(btn, MenuConfig.Config.Colors.Border)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name             = "Avatar"
	avatarImage.Size             = UDim2.new(0, 30, 0, 30)
	avatarImage.Position         = UDim2.new(0, 6, 0.5, -15)
	avatarImage.BackgroundColor3 = MenuConfig.Config.Colors.SurfaceLight
	avatarImage.BorderSizePixel  = 0
	avatarImage.Parent = btn
	MenuConfig.CreateCorner(avatarImage, 15)

	task.spawn(function()
		local ok, result = pcall(function()
			return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and avatarImage then avatarImage.Image = result end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name               = "PlayerName"
	nameLabel.Size               = UDim2.new(1, -50, 0, 18)
	nameLabel.Position           = UDim2.new(0, 42, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text               = targetPlayer.DisplayName
	nameLabel.TextColor3         = MenuConfig.Config.Colors.Text
	nameLabel.TextSize           = 12
	nameLabel.Font               = Enum.Font.GothamBold
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	nameLabel.TextTruncate       = Enum.TextTruncate.AtEnd
	nameLabel.Parent = btn

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name               = "Username"
	usernameLabel.Size               = UDim2.new(1, -50, 0, 14)
	usernameLabel.Position           = UDim2.new(0, 42, 0, 22)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text               = "@" .. targetPlayer.Name
	usernameLabel.TextColor3         = MenuConfig.Config.Colors.TextSecondary
	usernameLabel.TextSize           = 10
	usernameLabel.Font               = Enum.Font.Gotham
	usernameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate       = Enum.TextTruncate.AtEnd
	usernameLabel.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = MenuConfig.Config.Colors.Surface:Lerp(Color3.new(1,1,1), 0.05)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = MenuConfig.Config.Colors.Surface
		}):Play()
	end)

	if onClick then
		btn.MouseButton1Click:Connect(function()
			MenuConfig.PlayClick()
			onClick(targetPlayer, btn, btnStroke)
		end)
	end

	return btn, btnStroke, avatarImage, nameLabel, usernameLabel
end

function MenuConfig.GetColor(colorName)
	return MenuConfig.Config.Colors[colorName]
end

return MenuConfig
