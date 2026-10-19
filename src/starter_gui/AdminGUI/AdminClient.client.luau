local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local AdminConfig = require(Modules:WaitForChild("AdminConfig"))
local ThemeModule = require(Modules:WaitForChild("ThemeModule"))
local NotifModule = require(Modules:WaitForChild("NotifModule"))
local PanelAnimationController = require(Modules:WaitForChild("PanelAnimationController"))
local UIStrings = require(Modules:WaitForChild("UIStrings"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Icon      = require(ReplicatedStorage:WaitForChild("Icon"))

local gui    = script.Parent
local Config = AdminConfig.Config

local ALLOWED_ROLES = {
	["Owner"]     = true,
	["Developer"] = true,
	["Admin"]     = true,
}

local PANEL_WIDTH   = Config.PanelSize.Width
local PANEL_HEIGHT  = Config.PanelSize.Height
local HEADER_HEIGHT = Config.HeaderHeight
local SIDEBAR_WIDTH = Config.SidebarWidth

local DRAG_PADDING = 10

local ANIMATION_CONFIG = {
	OpenDuration       = 0.25,
	CloseDuration      = 0.18,
	ScaleStart         = 0.9,
	ScaleEnd           = 1,
	SlideOffsetY       = 20,
	OpenEaseStyle      = Enum.EasingStyle.Quart,
	OpenEaseDirection  = Enum.EasingDirection.Out,
	CloseEaseStyle     = Enum.EasingStyle.Quart,
	CloseEaseDirection = Enum.EasingDirection.In,
}

if gui:GetAttribute("AdminInitialized") then return end
gui:SetAttribute("AdminInitialized", true)

gui.Name = "AdminGUI"
if gui:IsA("ScreenGui") then
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder   = 100
	gui.IgnoreGuiInset = true
	gui.Enabled        = true
end

ThemeModule.GradientSystem.Start()

local ScalingSystem = require(
	ReplicatedStorage
		:WaitForChild("AutoScaleSystem")
		:WaitForChild("ScaleSystem")
)

local guiScaler = ScalingSystem.new(gui)

local function getCurrentScale()
	return guiScaler:GetCurrentScale()
end

local uiScale = gui:FindFirstChildOfClass("UIScale")

local SoundSystem = { ClickSound = nil, SoundId = "rbxassetid://139658322785649" }

function SoundSystem.Setup()
	SoundSystem.ClickSound = Instance.new("Sound")
	SoundSystem.ClickSound.Name          = "AdminClickSound"
	SoundSystem.ClickSound.SoundId       = SoundSystem.SoundId
	SoundSystem.ClickSound.Volume        = 0.5
	SoundSystem.ClickSound.PlaybackSpeed = 1.2
	SoundSystem.ClickSound.Parent        = game:GetService("SoundService")
end

function SoundSystem.PlayClick()
	if SoundSystem.ClickSound then
		SoundSystem.ClickSound:Stop()
		SoundSystem.ClickSound:Play()
	end
end

SoundSystem.Setup()
AdminConfig.SoundSystem = SoundSystem

local CameraLockSystem = { isLocked = false }

function CameraLockSystem.Lock()
	if CameraLockSystem.isLocked then return end
	CameraLockSystem.originalMouseBehavior         = UserInputService.MouseBehavior
	CameraLockSystem.originalMouseDeltaSensitivity = UserInputService.MouseDeltaSensitivity
	UserInputService.MouseBehavior                 = Enum.MouseBehavior.Default
	UserInputService.MouseDeltaSensitivity         = 0
	CameraLockSystem.isLocked = true
end

function CameraLockSystem.Unlock()
	if not CameraLockSystem.isLocked then return end
	if CameraLockSystem.originalMouseBehavior then
		UserInputService.MouseBehavior = CameraLockSystem.originalMouseBehavior
	end
	if CameraLockSystem.originalMouseDeltaSensitivity then
		UserInputService.MouseDeltaSensitivity = CameraLockSystem.originalMouseDeltaSensitivity
	end
	CameraLockSystem.isLocked = false
end

local panelContainer = Instance.new("Frame")
panelContainer.Name                   = "PanelContainer"
panelContainer.Size                   = UDim2.new(1, 0, 1, 0)
panelContainer.Position               = UDim2.new(0, 0, 0, 0)
panelContainer.BackgroundTransparency = 1
panelContainer.BorderSizePixel        = 0
panelContainer.Visible                = false
panelContainer.Parent                 = gui

local function getDefaultPanelOffset()
	local currentScale = getCurrentScale()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local halfX = viewportSize.X * 0.5
	local offsetX = (halfX - DRAG_PADDING) / currentScale - PANEL_WIDTH / 2
	local offsetY = 0
	return offsetX, offsetY
end

local mainPanel = Instance.new("CanvasGroup")
mainPanel.Name              = "MainPanel"
mainPanel.Size              = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
mainPanel.Position          = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint       = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3  = ThemeModule.Colors.BackgroundDark
mainPanel.BorderSizePixel   = 0
mainPanel.Active            = true
mainPanel.GroupTransparency = 0
mainPanel.Parent            = panelContainer

local panelUIScale = Instance.new("UIScale")
panelUIScale.Scale  = 1
panelUIScale.Parent = mainPanel

ThemeModule.CreateCorner(mainPanel, 12)

local mainStroke, mainStrokeGradient = ThemeModule.CreateAnimatedStroke(mainPanel, 2, "Primary", 1.2)
mainStroke.Transparency = 1

local header = Instance.new("Frame")
header.Name             = "Header"
header.Size             = UDim2.new(1, 0, 0, HEADER_HEIGHT)
header.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
header.BorderSizePixel  = 0
header.Active           = true
header.Parent           = mainPanel

ThemeModule.CreateCorner(header, 12)

local headerCover = Instance.new("Frame")
headerCover.Size             = UDim2.new(1, 0, 0, 15)
headerCover.Position         = UDim2.new(0, 0, 1, -15)
headerCover.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
headerCover.BorderSizePixel  = 0
headerCover.Active           = true
headerCover.Parent           = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name               = "Title"
titleLabel.Size               = UDim2.new(0, 300, 1, 0)
titleLabel.Position           = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "🛡️  Panel Kontrol Admin"
titleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize           = UIStrings.TextSize.Title
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = header
UIStrings.LockTextSize(titleLabel, UIStrings.TextSize.Title)

local titleGradient = ThemeModule.CreatePrimaryGradient(titleLabel, 0, 1.2)

local closeButton = Instance.new("TextButton")
closeButton.Name             = "CloseButton"
closeButton.Size             = UDim2.new(0, 32, 0, 32)
closeButton.Position         = UDim2.new(1, -40, 0, 7)
closeButton.BackgroundColor3 = ThemeModule.Colors.CloseRed
closeButton.BorderSizePixel  = 0
closeButton.Text             = "x"
closeButton.TextColor3       = ThemeModule.Colors.TextWhite
closeButton.TextSize         = 14
closeButton.Font             = Enum.Font.GothamBold
closeButton.TextXAlignment   = Enum.TextXAlignment.Center
closeButton.TextYAlignment   = Enum.TextYAlignment.Center
closeButton.AutoButtonColor  = false
closeButton.Parent           = header
UIStrings.LockTextSize(closeButton, 14)

ThemeModule.CreateCorner(closeButton, 6)

local closePad = Instance.new("UIPadding")
closePad.PaddingBottom = UDim.new(0, 3)
closePad.Parent = closeButton

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = ThemeModule.Colors.CloseRedHover }):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = ThemeModule.Colors.CloseRed }):Play()
end)

local tabContainer = Instance.new("ScrollingFrame")
tabContainer.Name             = "TabContainer"
tabContainer.Size             = UDim2.new(0, SIDEBAR_WIDTH, 1, -(HEADER_HEIGHT + 16))
tabContainer.Position         = UDim2.new(0, 8, 0, HEADER_HEIGHT + 8)
tabContainer.BackgroundColor3 = ThemeModule.Colors.BackgroundMedium
tabContainer.BorderSizePixel  = 0
tabContainer.ScrollBarThickness = 0
tabContainer.ScrollBarImageTransparency = 1
tabContainer.CanvasSize       = UDim2.new(0, 0, 0, 0)
tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
tabContainer.Parent           = mainPanel

ThemeModule.CreateCorner(tabContainer, 8)

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop    = UDim.new(0, 8)
tabPadding.PaddingBottom = UDim.new(0, 8)
tabPadding.PaddingLeft   = UDim.new(0, 5)
tabPadding.PaddingRight  = UDim.new(0, 5)
tabPadding.Parent        = tabContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding             = UDim.new(0, 4)
tabLayout.FillDirection       = Enum.FillDirection.Vertical
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
tabLayout.SortOrder           = Enum.SortOrder.LayoutOrder
tabLayout.Parent              = tabContainer

local contentContainer = Instance.new("Frame")
contentContainer.Name                   = "ContentContainer"
contentContainer.Size                   = UDim2.new(1, -(SIDEBAR_WIDTH + 24), 1, -(HEADER_HEIGHT + 16))
contentContainer.Position               = UDim2.new(0, SIDEBAR_WIDTH + 16, 0, HEADER_HEIGHT + 8)
contentContainer.BackgroundColor3       = ThemeModule.Colors.BackgroundMedium
contentContainer.BackgroundTransparency = 0
contentContainer.BorderSizePixel        = 0
contentContainer.Active                 = true
contentContainer.ClipsDescendants       = true
contentContainer.Parent                 = mainPanel

ThemeModule.CreateCorner(contentContainer, 8)

local tabDefinitions = {
	{ Name = "RoleGive",    Icon = "🎭", DisplayName = "Bagi Role",    Order = 1 },
	{ Name = "Broadcast",   Icon = "📢", DisplayName = "Siaran",       Order = 2 },
	{ Name = "CustomTitle", Icon = "✨", DisplayName = "Gelar Khusus", Order = 3 },
	{ Name = "ManageTitle", Icon = "📝", DisplayName = "Kelola Gelar", Order = 4 },
	{ Name = "Logs",        Icon = "📋", DisplayName = "Catatan Log",  Order = 5 },
	{ Name = "Players",     Icon = "👥", DisplayName = "Daftar Pemain", Order = 6 },
	{ Name = "Settings",    Icon = "⚙️", DisplayName = "Pengaturan",    Order = 7 },
}

local tabButtons     = {}
local tabFrames      = {}
local tabPages       = {}
local tabNames       = {}
local tabGradients   = {}
local tabHoverTweens = {}

local TAB_COLORS = {
	ActiveBackground   = Color3.fromRGB(255, 255, 255),
	InactiveBackground = ThemeModule.Colors.BackgroundLight,
	HoverBackground    = ThemeModule.Colors.BackgroundLighter,
	ActiveText         = ThemeModule.Colors.BackgroundDark,
	InactiveText       = ThemeModule.Colors.TextGray,
}

local function createTabButton(def)
	local btnFrame = Instance.new("Frame")
	btnFrame.Name             = def.Name .. "TabFrame"
	btnFrame.Size             = UDim2.new(1, 0, 0, Config.TabButtonHeight)
	btnFrame.BackgroundColor3 = TAB_COLORS.InactiveBackground
	btnFrame.BorderSizePixel  = 0
	btnFrame.LayoutOrder      = def.Order
	btnFrame.Parent           = tabContainer

	ThemeModule.CreateCorner(btnFrame, 6)

	local frameGradient = Instance.new("UIGradient")
	frameGradient.Name    = "FrameGradient"
	frameGradient.Color   = ThemeModule.Gradients.Primary
	frameGradient.Rotation = 45
	frameGradient.Enabled = false
	frameGradient.Parent  = btnFrame

	tabGradients[def.Name]   = frameGradient
	tabFrames[def.Name]      = btnFrame
	tabHoverTweens[def.Name] = nil

	local btn = Instance.new("TextButton")
	btn.Name               = def.Name .. "Tab"
	btn.Size               = UDim2.new(1, 0, 1, 0)
	btn.Position           = UDim2.new(0, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel    = 0
	btn.Text               = def.Icon .. "  " .. def.DisplayName
	btn.TextColor3         = TAB_COLORS.InactiveText
	btn.TextSize           = UIStrings.TextSize.Caption
	btn.Font               = Enum.Font.GothamMedium
	btn.AutoButtonColor    = false
	btn.TextXAlignment     = Enum.TextXAlignment.Left
	btn.Parent             = btnFrame
	UIStrings.LockTextSize(btn, UIStrings.TextSize.Caption)

	local btnPad = Instance.new("UIPadding")
	btnPad.PaddingLeft     = UDim.new(0, 10)
	btnPad.PaddingRight    = UDim.new(0, 4)
	btnPad.Parent          = btn

	btn.MouseEnter:Connect(function()
		if AdminConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = TAB_COLORS.HoverBackground
		})
		tabHoverTweens[def.Name] = t
		t:Play()
	end)

	btn.MouseLeave:Connect(function()
		if AdminConfig.State.currentTab == def.Name then return end
		if tabHoverTweens[def.Name] then tabHoverTweens[def.Name]:Cancel() end
		local t = TweenService:Create(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = TAB_COLORS.InactiveBackground
		})
		tabHoverTweens[def.Name] = t
		t:Play()
	end)

	return btn, btnFrame
end

local function createTabPage(def)
	local page = Instance.new("Frame")
	page.Name                   = def.Name .. "Page"
	page.Size                   = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel        = 0
	page.Active                 = true
	page.Visible                = false
	page.Parent                 = contentContainer
	return page
end

for _, def in ipairs(tabDefinitions) do
	local btn, btnFrame = createTabButton(def)
	local page          = createTabPage(def)
	tabButtons[def.Name] = btn
	tabPages[def.Name]   = page
	table.insert(tabNames, def.Name)
end

local function switchTab(tabName)
	SoundSystem.PlayClick()
	AdminConfig.State.currentTab = tabName

	for name, page in pairs(tabPages) do
		page.Visible = (name == tabName)
	end

	for name, btn in pairs(tabButtons) do
		local gradient = tabGradients[name]
		local frame    = tabFrames[name]

		if tabHoverTweens[name] then
			tabHoverTweens[name]:Cancel()
			tabHoverTweens[name] = nil
		end

		if name == tabName then
			if gradient then
				gradient.Color = ThemeModule.Gradients.Primary
				gradient.Enabled = true
				ThemeModule.GradientSystem.Register(gradient, 1)
			end
			if frame then frame.BackgroundColor3 = TAB_COLORS.ActiveBackground end
			btn.TextColor3 = TAB_COLORS.ActiveText
			btn.Font       = Enum.Font.GothamBold
		else
			if gradient then
				gradient.Color = ThemeModule.Gradients.Primary
				gradient.Enabled = false
				ThemeModule.GradientSystem.Unregister(gradient)
			end
			if frame then frame.BackgroundColor3 = TAB_COLORS.InactiveBackground end
			btn.TextColor3 = TAB_COLORS.InactiveText
			btn.Font       = Enum.Font.GothamMedium
		end
	end

	local activeFrame = tabFrames[tabName]
	if activeFrame and tabContainer and tabContainer:IsA("ScrollingFrame") then
		local frameY = activeFrame.AbsolutePosition.Y - tabContainer.AbsolutePosition.Y + tabContainer.CanvasPosition.Y
		local containerH = tabContainer.AbsoluteSize.Y
		if frameY < tabContainer.CanvasPosition.Y or frameY + activeFrame.AbsoluteSize.Y > tabContainer.CanvasPosition.Y + containerH then
			TweenService:Create(tabContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CanvasPosition = Vector2.new(0, math.max(0, frameY - 8))
			}):Play()
		end
	end

	AdminConfig.Events.OnTabChanged:Fire(tabName)
end

for tabName, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

local function updateAllTabGradients()
	for _, grad in pairs(tabGradients) do
		if grad and grad.Parent then
			grad.Color = ThemeModule.Gradients.Primary
		end
	end
	if mainStrokeGradient and mainStrokeGradient.Parent then
		mainStrokeGradient.Color = ThemeModule.Gradients.Primary
	end
	if titleGradient and titleGradient.Parent then
		titleGradient.Color = ThemeModule.Gradients.Primary
	end
end

if ThemeModule.OnThemeChanged then
	ThemeModule.OnThemeChanged.Event:Connect(function()
		updateAllTabGradients()
	end)
end

local MenuConfig = nil
pcall(function()
	MenuConfig = require(Modules:WaitForChild("MenuConfig", 5))
end)
if MenuConfig and MenuConfig.Events and MenuConfig.Events.OnColorChanged then
	MenuConfig.Events.OnColorChanged.Event:Connect(function()
		updateAllTabGradients()
	end)
end

player:GetAttributeChangedSignal("CurrentTheme"):Connect(function()
	local theme = player:GetAttribute("CurrentTheme")
	if theme and ThemeModule and ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset(theme)
	end
	updateAllTabGradients()
end)

task.spawn(function()
	local initialTheme = player:GetAttribute("CurrentTheme")
	if initialTheme and ThemeModule and ThemeModule.ApplyPreset then
		ThemeModule.ApplyPreset(initialTheme)
	end
	updateAllTabGradients()
end)

local function showNotification(message, messageType)
	local title    = "Panel Admin"
	local duration = Config.Notification.Duration or 3
	if messageType == "success" then
		NotifModule.Success(title, message, duration)
	elseif messageType == "error" then
		NotifModule.Error(title, message, duration)
	elseif messageType == "warning" then
		NotifModule.Warning(title, message, duration)
	elseif messageType == "info" then
		NotifModule.Info(title, message, duration)
	else
		NotifModule.Notify({ Type = "Notification", Title = title, Text = message, Duration = duration })
	end
end

local function calculateDragBoundaries()
	local currentScale = getCurrentScale()
	if not currentScale or currentScale <= 0 then
		currentScale = 1
	end

	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local halfX = viewportSize.X * 0.5
	local halfY = viewportSize.Y * 0.5

	local minX = (DRAG_PADDING - halfX) / currentScale + PANEL_WIDTH / 2
	local maxX = (halfX - DRAG_PADDING) / currentScale - PANEL_WIDTH / 2
	local minY = (DRAG_PADDING - halfY) / currentScale + PANEL_HEIGHT / 2
	local maxY = (halfY - DRAG_PADDING) / currentScale - PANEL_HEIGHT / 2

	if minX > maxX then
		minX = 0
		maxX = 0
	end

	if minY > maxY then
		minY = 0
		maxY = 0
	end

	return minX, maxX, minY, maxY
end

local function clampPanelPosition()
	local pos = mainPanel.Position
	local minX, maxX, minY, maxY = calculateDragBoundaries()
	local cx = if minX <= maxX then math.clamp(pos.X.Offset, minX, maxX) else 0
	local cy = if minY <= maxY then math.clamp(pos.Y.Offset, minY, maxY) else 0
	if cx ~= pos.X.Offset or cy ~= pos.Y.Offset then
		mainPanel.Position = UDim2.new(0.5, cx, 0.5, cy)
	end
end

local function resetPanelPosition()
	local offsetX, offsetY = getDefaultPanelOffset()
	mainPanel.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if panelContainer.Visible then
		task.defer(clampPanelPosition)
	end
end)

local panelVisible   = false
local adminIcon      = nil
local hasAdminAccess = false

local panelController = PanelAnimationController.new(mainPanel, {
	Mode = "CanvasGroup",
	Container = panelContainer,
	UIScale = panelUIScale,
	Stroke = mainStroke,
	OpenDuration = ANIMATION_CONFIG.OpenDuration,
	CloseDuration = ANIMATION_CONFIG.CloseDuration,
	OpenEasingStyle = ANIMATION_CONFIG.OpenEaseStyle,
	OpenEasingDirection = ANIMATION_CONFIG.OpenEaseDirection,
	CloseEasingStyle = ANIMATION_CONFIG.CloseEaseStyle,
	CloseEasingDirection = ANIMATION_CONFIG.CloseEaseDirection,
	ScaleStart = ANIMATION_CONFIG.ScaleStart,
	ScaleEnd = ANIMATION_CONFIG.ScaleEnd,
	SlideOffsetY = ANIMATION_CONFIG.SlideOffsetY,
	GetResetPosition = function()
		local offsetX, offsetY = getDefaultPanelOffset()
		return UDim2.new(0.5, offsetX, 0.5, offsetY)
	end,
})

panelController.OnStateChanged.Event:Connect(function(newState)
	if newState == PanelAnimationController.State.Opening or newState == PanelAnimationController.State.Open then
		panelVisible = true
		AdminConfig.State.isMenuOpen = true
		AdminConfig.Events.OnMenuToggled:Fire(true)
	elseif newState == PanelAnimationController.State.Closed then
		panelVisible = false
		AdminConfig.State.isMenuOpen = false
		AdminConfig.Events.OnMenuToggled:Fire(false)
	end
end)

local function openPanel()
	if not hasAdminAccess then return end
	panelController:Open()
end

local function closePanel()
	panelController:Close()
end

local function togglePanel()
	if not hasAdminAccess then return end
	SoundSystem.PlayClick()
	panelController:Toggle()
end

local function forceClosePanel()
	panelController:ForceClose()
end

AdminConfig.OpenPanel          = openPanel
AdminConfig.ClosePanel         = closePanel
AdminConfig.TogglePanel        = togglePanel
AdminConfig.ForceClosePanel    = forceClosePanel
AdminConfig.SwitchTab          = switchTab
AdminConfig.ShowNotification   = showNotification
AdminConfig.ResetPanelPosition = resetPanelPosition
AdminConfig.ClampPanelPosition = clampPanelPosition

AdminConfig.GUI.ScreenGui        = gui
AdminConfig.GUI.MainPanel        = mainPanel
AdminConfig.GUI.PanelContainer   = panelContainer
AdminConfig.GUI.Header           = header
AdminConfig.GUI.TabContainer     = tabContainer
AdminConfig.GUI.ContentContainer = contentContainer
AdminConfig.GUI.CloseButton      = closeButton
AdminConfig.GUI.TabButtons       = tabButtons
AdminConfig.GUI.TabFrames        = tabFrames
AdminConfig.GUI.TabPages         = tabPages
AdminConfig.GUI.TabNames         = tabNames
AdminConfig.GUI.UIScale          = uiScale
AdminConfig.GUI.PanelUIScale     = panelUIScale
AdminConfig.GUI.GUIScaler        = guiScaler

AdminConfig.GUI.RoleGivePage    = tabPages["RoleGive"]
AdminConfig.GUI.BroadcastPage   = tabPages["Broadcast"]
AdminConfig.GUI.CustomTitlePage = tabPages["CustomTitle"]
AdminConfig.GUI.ManageTitlePage = tabPages["ManageTitle"]
AdminConfig.GUI.LogsPage        = tabPages["Logs"]
AdminConfig.GUI.PlayersPage     = tabPages["Players"]
AdminConfig.GUI.SettingsPage    = tabPages["Settings"]

AdminConfig.GUI.RoleGiveTab    = tabButtons["RoleGive"]
AdminConfig.GUI.BroadcastTab   = tabButtons["Broadcast"]
AdminConfig.GUI.CustomTitleTab = tabButtons["CustomTitle"]
AdminConfig.GUI.ManageTitleTab = tabButtons["ManageTitle"]
AdminConfig.GUI.LogsTab        = tabButtons["Logs"]
AdminConfig.GUI.PlayersTab     = tabButtons["Players"]
AdminConfig.GUI.SettingsTab    = tabButtons["Settings"]

local dragging  = false
local dragInput = nil
local dragStart = nil
local startPos  = nil

local function updateDrag(input)
	local delta        = input.Position - dragStart
	local currentScale = getCurrentScale()
	if not currentScale or currentScale <= 0 then
		currentScale = 1
	end
	local adjusted     = delta / currentScale
	local minX, maxX, minY, maxY = calculateDragBoundaries()
	local targetX = startPos.X.Offset + adjusted.X
	local targetY = startPos.Y.Offset + adjusted.Y
	local cx = if minX <= maxX then math.clamp(targetX, minX, maxX) else 0
	local cy = if minY <= maxY then math.clamp(targetY, minY, maxY) else 0
	mainPanel.Position = UDim2.new(0.5, cx, 0.5, cy)
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local cp = closeButton.AbsolutePosition
		local cs = closeButton.AbsoluteSize
		if input.Position.X >= cp.X and input.Position.X <= cp.X + cs.X and
			input.Position.Y >= cp.Y and input.Position.Y <= cp.Y + cs.Y then return end
		dragging  = true
		dragStart = input.Position
		startPos  = mainPanel.Position
		CameraLockSystem.Lock()
		ContextActionService:BindActionAtPriority("BlockCameraMovement", function() return Enum.ContextActionResult.Sink end,
		false, Enum.ContextActionPriority.High.Value + 2000, Enum.UserInputType.MouseMovement, Enum.UserInputType.Touch)
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				CameraLockSystem.Unlock()
				ContextActionService:UnbindAction("BlockCameraMovement")
			end
		end)
	end
end)

header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then updateDrag(input) end
end)

UserInputService.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
		dragging = false
		CameraLockSystem.Unlock()
		ContextActionService:UnbindAction("BlockCameraMovement")
	end
end)

local function hasAllowedRole(role)
	return ALLOWED_ROLES[role] == true
end

local function checkAdminAccess()
	local roleValue = player:FindFirstChild("Role")
	if roleValue and hasAllowedRole(roleValue.Value) then
		hasAdminAccess = true

		if not adminIcon then
			local existingIcon = Icon.getIcon("AdminPanelIcon")
			if existingIcon then existingIcon:destroy() end

			adminIcon = Icon.new()
			adminIcon:setName("AdminPanelIcon")
			adminIcon:setImage("rbxassetid://135964688013914")
			adminIcon:setCaption("Panel Admin")
			adminIcon:setRight()
			adminIcon:setOrder(4)

			panelController:BindTopbarIcon(adminIcon)
			adminIcon.selected:Connect(function()   SoundSystem.PlayClick() end)
			adminIcon.deselected:Connect(function() SoundSystem.PlayClick() end)

			AdminConfig.GUI.AdminIcon = adminIcon
		end

		adminIcon:setEnabled(true)
		return true
	else
		hasAdminAccess = false

		if panelVisible then
			forceClosePanel()
			if adminIcon then adminIcon:deselect() end
		end

		if adminIcon then
			adminIcon:destroy()
			adminIcon = nil
			AdminConfig.GUI.AdminIcon = nil
		end

		return false
	end
end

closeButton.MouseButton1Click:Connect(function()
	SoundSystem.PlayClick()
	closePanel()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not hasAdminAccess then return end
	if input.KeyCode == Config.ToggleKey then
		togglePanel()
	end
end)

local placeholders = {
	{ page = "Logs",     text = "📋 Logs\n\nKonten akan ditambahkan nanti" },
	{ page = "Players",  text = "👥 Players\n\nKonten akan ditambahkan nanti" },
	{ page = "Settings", text = "⚙️ Settings\n\nKonten akan ditambahkan nanti" },
}

for _, p in ipairs(placeholders) do
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = p.text
	lbl.TextColor3             = ThemeModule.Colors.TextGray
	lbl.TextSize               = 14
	lbl.Font                   = Enum.Font.GothamMedium
	lbl.Parent                 = tabPages[p.page]
	UIStrings.LockTextSize(lbl, 14)
end

task.spawn(function()
	local roleValue = player:WaitForChild("Role", 15)
	if roleValue then
		checkAdminAccess()
		roleValue:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1)
			checkAdminAccess()
		end)
	else
		hasAdminAccess = false
		if adminIcon then adminIcon:destroy(); adminIcon = nil end
	end
end)

player.ChildAdded:Connect(function(child)
	if child.Name == "Role" and child:IsA("StringValue") then
		task.wait(0.1)
		checkAdminAccess()
		child:GetPropertyChangedSignal("Value"):Connect(function()
			task.wait(0.1)
			checkAdminAccess()
		end)
	end
end)

player.ChildRemoved:Connect(function(child)
	if child.Name == "Role" then
		hasAdminAccess = false
		if panelVisible then forceClosePanel() end
		if adminIcon then
			adminIcon:destroy()
			adminIcon = nil
			AdminConfig.GUI.AdminIcon = nil
		end
	end
end)

gui.Destroying:Connect(function()
	guiScaler:Destroy()
	ThemeModule.GradientSystem.Unregister(mainStrokeGradient)
	ThemeModule.GradientSystem.Unregister(titleGradient)
	for _, gradient in pairs(tabGradients) do ThemeModule.GradientSystem.Unregister(gradient) end
	for _, tween in pairs(tabHoverTweens) do if tween then tween:Cancel() end end
	if panelController then panelController:Destroy(); panelController = nil end
	if adminIcon then adminIcon:destroy(); adminIcon = nil end
end)

switchTab("RoleGive")
AdminConfig.MarkGUIReady()

print("✅ [AdminClient] Berhasil dimuat!")
